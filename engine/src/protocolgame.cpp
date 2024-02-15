/**
 * The Forgotten Server - a free and open-source MMORPG server emulator
 * Copyright (C) 2019 Mark Samman <mark.samman@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#include "otpch.h"

#include "protocolgame.h"

#include "outputmessage.h"

#include "player.h"
#include "databasetasks.h"
#include "configmanager.h"
#include "actions.h"
#include "game.h"
#include "iologindata.h"
#include "iomarket.h"
#include "waitlist.h"
#include "ban.h"
#include "scheduler.h"
#include "modules.h"
#include "weapons.h"
#include "imbuements.h"
#include "bestiary.h"
#include "charm.h"
#include "store.h"

extern Game g_game;
extern ConfigManager g_config;
extern Actions actions;
extern CreatureEvents* g_creatureEvents;
extern Vocations g_vocations;
extern Chat* g_chat;
extern Modules* g_modules;
extern Imbuements g_imbuements;
extern Bestiaries g_bestiaries;
extern Charms g_charms;
extern Monsters g_monsters;
extern Prey g_prey;
extern Store g_store;

ProtocolGame::LiveCastsMap ProtocolGame::liveCasts;

void ProtocolGame::release()
{
	//dispatcher thread
	stopLiveCast();
	if (player && player->client == shared_from_this()) {
		player->client.reset();
		player->decrementReferenceCounter();
		player = nullptr;
	}

	OutputMessagePool::getInstance().removeProtocolFromAutosend(shared_from_this());
	Protocol::release();
}

void ProtocolGame::login(const std::string& name, uint32_t accountId, OperatingSystem_t operatingSystem)
{
	//dispatcher thread
	Player* foundPlayer = g_game.getPlayerByName(name);
	if (!foundPlayer || g_config.getBoolean(ConfigManager::ALLOW_CLONES)) {
		player = new Player(getThis());
		player->setName(name);

		//player->setID();
		if (!IOLoginData::preloadPlayer(player, name)) {
			disconnectClient("Your character could not be loaded.");
			return;
		}

		player->incrementReferenceCounter();
		player->setID();

		if (IOBan::isPlayerNamelocked(player->getGUID())) {
			disconnectClient("Your character has been namelocked.");
			return;
		}

		if (g_game.getGameState() == GAME_STATE_CLOSING && !player->hasFlag(PlayerFlag_CanAlwaysLogin)) {
			disconnectClient("The game is just going down.\nPlease try again later.");
			return;
		}

		if (g_game.getGameState() == GAME_STATE_CLOSED && !player->hasFlag(PlayerFlag_CanAlwaysLogin)) {
			disconnectClient("Server is currently closed.\nPlease try again later.");
			return;
		}

		if (g_config.getBoolean(ConfigManager::MAINTENANCE) && !player->hasFlag(PlayerFlag_CanAlwaysLogin)) {
			if (!g_game.hasFreePass(player->getGUID())){
				disconnectClient("Server is currently closed.\nPlease try again later.");
				return;
			}
		}

		if (g_config.getBoolean(ConfigManager::ONE_PLAYER_ON_ACCOUNT) && player->getAccountType() < ACCOUNT_TYPE_GAMEMASTER && g_game.getPlayerByAccount(player->getAccount())) {
			disconnectClient("You may only login with one character\nof your account at the same time.");
			return;
		}

		if (!player->hasFlag(PlayerFlag_CannotBeBanned)) {
			BanInfo banInfo;
			if (IOBan::isAccountBanned(accountId, banInfo)) {
				if (banInfo.reason.empty()) {
					banInfo.reason = "(none)";
				}

				std::ostringstream ss;
				if (banInfo.expiresAt > 0) {
					ss << "Your account has been banned until " << formatDateShort(banInfo.expiresAt) << " by " << banInfo.bannedBy << ".\n\nReason specified:\n" << banInfo.reason;
				} else {
					ss << "Your account has been permanently banned by " << banInfo.bannedBy << ".\n\nReason specified:\n" << banInfo.reason;
				}
				disconnectClient(ss.str());
				return;
			}
		}

		WaitingList& waitingList = WaitingList::getInstance();
		if (!waitingList.clientLogin(player)) {
			uint32_t currentSlot = waitingList.getClientSlot(player);
			uint32_t retryTime = WaitingList::getTime(currentSlot);
			std::ostringstream ss;

			ss << "Too many players online.\nYou are at place "
			   << currentSlot << " on the waiting list.";

			auto output = OutputMessagePool::getOutputMessage();
			output->addByte(0x16);
			output->addString(ss.str());
			output->addByte(retryTime);
			send(output);
			disconnect();
			return;
		}

		if (!IOLoginData::loadPlayerById(player, player->getGUID())) {
			disconnectClient("Your character could not be loaded.");
			return;
		}

		player->setOperatingSystem(operatingSystem);

		if (!g_game.placeCreature(player, player->getLoginPosition())) {
			if (!g_game.placeCreature(player, player->getTemplePosition(), false, true)) {
				disconnectClient("Temple position is wrong. Contact the administrator.");
				return;
			}
		}

		if (operatingSystem >= CLIENTOS_OTCLIENT_LINUX) {
			player->registerCreatureEvent("ExtendedOpcode");
		}

		player->lastIP = player->getIP();
		player->lastLoginSaved = std::max<time_t>(OS_TIME(nullptr), player->lastLoginSaved + 1);
		acceptPackets = true;
	} else {
		if (eventConnect != 0 || !g_config.getBoolean(ConfigManager::REPLACE_KICK_ON_LOGIN)) {
			//Already trying to connect
			disconnectClient("You are already logged in.");
			return;
		}

		if (foundPlayer->client) {
			foundPlayer->disconnect();
			foundPlayer->isConnecting = true;

			eventConnect = g_scheduler.addEvent(createSchedulerTask(1000, std::bind(&ProtocolGame::connect, getThis(), foundPlayer->getID(), operatingSystem)));
		} else {
			connect(foundPlayer->getID(), operatingSystem);
		}
	}
	OutputMessagePool::getInstance().addProtocolToAutosend(shared_from_this());
}

void ProtocolGame::connect(uint32_t playerId, OperatingSystem_t operatingSystem)
{
	eventConnect = 0;

	Player* foundPlayer = g_game.getPlayerByID(playerId);
	if (!foundPlayer || foundPlayer->client) {
		disconnectClient("You are already logged in.");
		return;
	}

	if (isConnectionExpired()) {
		//ProtocolGame::release() has been called at this point and the Connection object
		//no longer exists, so we return to prevent leakage of the Player.
		return;
	}

	player = foundPlayer;
	player->incrementReferenceCounter();

	g_chat->removeUserFromAllChannels(*player);
	player->clearModalWindows();
	player->setOperatingSystem(operatingSystem);
	player->isConnecting = false;

	player->client = getThis();
	sendAddCreature(player, player->getPosition(), 0, false);
	player->lastIP = player->getIP();
	player->lastLoginSaved = std::max<time_t>(OS_TIME(nullptr), player->lastLoginSaved + 1);
	acceptPackets = true;
}

void ProtocolGame::logout(bool displayEffect, bool forced)
{
	//dispatcher thread
	if (!player) {
		return;
	}

	if (!player->isRemoved()) {
		if (!forced) {
			if (!player->isAccessPlayer()) {
				if (player->getTile()->hasFlag(TILESTATE_NOLOGOUT)) {
					player->sendCancelMessage(RETURNVALUE_YOUCANNOTLOGOUTHERE);
					return;
				}

				if (!player->getTile()->hasFlag(TILESTATE_PROTECTIONZONE) && player->hasCondition(CONDITION_INFIGHT)) {
					player->sendCancelMessage(RETURNVALUE_YOUMAYNOTLOGOUTDURINGAFIGHT);
					return;
				}
			}

			//scripting event - onLogout
			if (!g_creatureEvents->playerLogout(player)) {
				//Let the script handle the error message
				return;
			}
		}

		if (displayEffect && player->getHealth() > 0) {
			g_game.addMagicEffect(player->getPosition(), CONST_ME_POFF);
		}
	}

	stopLiveCast();
	disconnect();

	g_game.removeCreature(player);
}

bool ProtocolGame::startLiveCast(const std::string& password /*= ""*/)
{
	auto connection = getConnection();
	if (!g_config.getBoolean(ConfigManager::ENABLE_LIVE_CASTING) || isLiveCaster() || !player || player->isRemoved() || !connection || liveCasts.size() >= getMaxLiveCastCount()) {
		return false;
	}

	{
		std::lock_guard<decltype(liveCastLock)> lock {liveCastLock};
		//DO NOT do any send operations here
		liveCastName = player->getName();
		liveCastPassword = password;
		isCaster.store(true, std::memory_order_relaxed);
	}

	liveCasts.insert(std::make_pair(player, getThis()));

	registerLiveCast();
	//Send a "dummy" channel
	sendChannel(CHANNEL_CAST, LIVE_CAST_CHAT_NAME, nullptr, nullptr);
	return true;
}

bool ProtocolGame::stopLiveCast()
{
	//dispatcher
	if (!isLiveCaster()) {
		return false;
	}

	CastSpectatorVec spectators;

	{
		std::lock_guard<decltype(liveCastLock)> lock {liveCastLock};
		//DO NOT do any send operations here
		std::swap(this->spectators, spectators);
		isCaster.store(false, std::memory_order_relaxed);
	}

	liveCasts.erase(player);
	for (auto& spectator : spectators) {
		spectator->onLiveCastStop();
	}
	unregisterLiveCast();

	return true;
}

void ProtocolGame::clearLiveCastInfo()
{
	static std::once_flag flag;
	std::call_once(flag, []() {
			assert(g_game.getGameState() == GAME_STATE_INIT);
			std::ostringstream query;
			query << "TRUNCATE TABLE `live_casts`;";
			g_databaseTasks.addTask(query.str());
		});
}

void ProtocolGame::registerLiveCast()
{
	std::ostringstream query;
	query << "INSERT into `live_casts` (`player_id`, `cast_name`, `password`, `version`) VALUES (" << player->getGUID() << ", '"
		<< getLiveCastName() << "', " << isPasswordProtected() << ", " << player->getProtocolVersion() << ");";
	g_databaseTasks.addTask(query.str());
}

void ProtocolGame::unregisterLiveCast()
{
	std::ostringstream query;
	query << "DELETE FROM `live_casts` WHERE `player_id`=" << player->getGUID() << ";";
	g_databaseTasks.addTask(query.str());
}

void ProtocolGame::updateLiveCastInfo()
{
	std::ostringstream query;
	query << "UPDATE `live_casts` SET `cast_name`='" << getLiveCastName() << "', `password`="
		<< isPasswordProtected() << ", `spectators`=" << getSpectatorCount()
		<< ", `version` = " << player->getProtocolVersion() << " WHERE `player_id`=" << player->getGUID() << ";";
	g_databaseTasks.addTask(query.str());
}

void ProtocolGame::addSpectator(ProtocolSpectator_ptr spectatorClient)
{
	std::lock_guard<decltype(liveCastLock)> lock(liveCastLock);
	//DO NOT do any send operations here
	spectators.emplace_back(spectatorClient);
	updateLiveCastInfo();
}

void ProtocolGame::removeSpectator(ProtocolSpectator_ptr spectatorClient)
{
	std::lock_guard<decltype(liveCastLock)> lock(liveCastLock);
	//DO NOT do any send operations here
	auto it = std::find(spectators.begin(), spectators.end(), spectatorClient);
	if (it != spectators.end()) {
		spectators.erase(it);
		updateLiveCastInfo();
	}
}

void ProtocolGame::onRecvFirstMessage(NetworkMessage& msg)
{
	if (g_game.getGameState() == GAME_STATE_SHUTDOWN) {
		disconnect();
		return;
	}

	OperatingSystem_t operatingSystem = static_cast<OperatingSystem_t>(msg.get<uint16_t>());
	version = msg.get<uint16_t>();
	if (version >= 1111) {
		setChecksumMethod(CHECKSUM_METHOD_SEQUENCE);
	} else if (version >= 830) {
		setChecksumMethod(CHECKSUM_METHOD_ADLER32);
	}

	clientVersion = msg.get<uint32_t>();

	msg.skipBytes(3); // U8 client type, U16 dat revision


	if (clientVersion >= 1240) {
		// In version 12.40.10030 we have 13 extra bytes
		if (msg.getLength() - msg.getBufferPosition() == 141) {
			msg.skipBytes(13);
		}
	}

	if (!Protocol::RSA_decrypt(msg)) {
		disconnect();
		return;
	}

	uint32_t key[4];
	key[0] = msg.get<uint32_t>();
	key[1] = msg.get<uint32_t>();
	key[2] = msg.get<uint32_t>();
	key[3] = msg.get<uint32_t>();
	enableXTEAEncryption();
	setXTEAKey(key);

	if (operatingSystem >= CLIENTOS_OTCLIENT_LINUX) {
		disconnectClient("Only official client is allowed!");
		return;
	}

	msg.skipBytes(1); // gamemaster flag

	std::string sessionKey = msg.getString();
	
	auto sessionArgs = explodeString(sessionKey, "\n", 4);
	sessionArgs = explodeString(sessionKey, "\n", 4);
	if (sessionArgs.size() != 4) {
		disconnectClient("Malformed token packet.");
		return;
	}

	std::string& accountName = sessionArgs[0];
	std::string& password = sessionArgs[1];
	std::string& token = sessionArgs[2];
	uint32_t tokenTime = 0;
	try {
		tokenTime = std::stoul(sessionArgs[3]);
	} catch (const std::invalid_argument&) {
		disconnectClient("Malformed token packet.");
		return;
	} catch (const std::out_of_range&) {
		disconnectClient("Token time is too long.");
		return;
	}

	std::string characterName = msg.getString();

	uint32_t timeStamp = msg.get<uint32_t>();
	uint8_t randNumber = msg.getByte();
	if (challengeTimestamp != timeStamp || challengeRandom != randNumber) {
		disconnect();
		return;
	}

	if (version < g_config.getNumber(ConfigManager::VERSION_MIN) || version > g_config.getNumber(ConfigManager::VERSION_MAX)) {
		std::ostringstream ss;
		ss << "Only clients with protocol " << g_config.getString(ConfigManager::VERSION_STR) << " allowed!";
		disconnectClient(ss.str());
		return;
	}

	if (g_game.getGameState() == GAME_STATE_STARTUP) {
		disconnectClient("Gameworld is starting up. Please wait.");
		return;
	}

	if (g_game.getGameState() == GAME_STATE_MAINTAIN) {
		disconnectClient("Gameworld is under maintenance. Please re-connect in a while.");
		return;
	}

	BanInfo banInfo;
	if (IOBan::isIpBanned(getIP(), banInfo)) {
		if (banInfo.reason.empty()) {
			banInfo.reason = "(none)";
		}

		std::ostringstream ss;
		ss << "Your IP has been banned until " << formatDateShort(banInfo.expiresAt) << " by " << banInfo.bannedBy << ".\n\nReason specified:\n" << banInfo.reason;
		disconnectClient(ss.str());
		return;
	}

	uint32_t accountId = IOLoginData::gameworldAuthentication(accountName, password, characterName, token, tokenTime);
	if (accountId == 0) {
		accountId = IOLoginData::gameworldAuthenticationEmail(accountName, password, characterName, token, tokenTime);
		if (accountId == 0) {
			disconnectClient("Account name or password is not correct.");
			return;
		}
	}

	g_dispatcher.addTask(createTask(std::bind(&ProtocolGame::login, getThis(), characterName, accountId, operatingSystem)));
}

void ProtocolGame::disconnectClient(const std::string& message) const
{
	auto output = OutputMessagePool::getOutputMessage();
	output->addByte(0x14);
	output->addString(message);
	send(output);
	disconnect();
}

void ProtocolGame::writeToOutputBuffer(const NetworkMessage& msg, bool broadcast /*= true*/)
{
	if (!broadcast && isLiveCaster()) {
		//We're casting and we need to send a packet that's not supposed to be broadcast so we need a new messasge.
		//This shouldn't impact performance by a huge amount as most packets can be broadcast.
		auto out = OutputMessagePool::getOutputMessage();
		out->append(msg);
		send(std::move(out));
	} else {
		auto out = getOutputBuffer(msg.getLength());
		if (isLiveCaster()) {
			out->setBroadcastMsg(true);
		}
		out->append(msg);
	}
}

void ProtocolGame::parsePacket(NetworkMessage& msg)
{

	if (!acceptPackets || g_game.getGameState() == GAME_STATE_SHUTDOWN || msg.getLength() <= 0) {
		return;
	}

	uint8_t recvbyte = msg.getByte();

	//a dead player can not perform actions
	if (!player || player->isRemoved() || player->getHealth() <= 0) {
		auto this_ptr = getThis();
		g_dispatcher.addTask(createTask([this_ptr]() {
			this_ptr->stopLiveCast();
		}));
		if (recvbyte == 0x0F) {
			// g_dispatcher.addTask(createTask(std::bind(&ProtocolGame::onRecvFirstMessage, getThis(), msg)));
			disconnect();
			return;
		}

		if (recvbyte != 0x14) {
			return;
		}
	}

	g_dispatcher.addTask(createTask(std::bind(&Modules::executeOnRecvbyte, g_modules, player, msg, recvbyte)));

	switch (recvbyte) {
		case 0x14: g_dispatcher.addTask(createTask(std::bind(&ProtocolGame::logout, getThis(), true, false))); break;
		case 0x1D: addGameTask(&Game::playerReceivePingBack, player->getID()); break;
		case 0x1E: addGameTask(&Game::playerReceivePing, player->getID()); break;
		case 0x2A: parseBestiaryTracker(msg); break;
		case 0x32: parseExtendedOpcode(msg); break; //otclient extended opcode
		case 0x64: parseAutoWalk(msg); break;
		case 0x65: addGameTask(&Game::playerMove, player->getID(), DIRECTION_NORTH); break;
		case 0x66: addGameTask(&Game::playerMove, player->getID(), DIRECTION_EAST); break;
		case 0x67: addGameTask(&Game::playerMove, player->getID(), DIRECTION_SOUTH); break;
		case 0x68: addGameTask(&Game::playerMove, player->getID(), DIRECTION_WEST); break;
		case 0x69: addGameTask(&Game::playerStopAutoWalk, player->getID()); break;
		case 0x6A: addGameTask(&Game::playerMove, player->getID(), DIRECTION_NORTHEAST); break;
		case 0x6B: addGameTask(&Game::playerMove, player->getID(), DIRECTION_SOUTHEAST); break;
		case 0x6C: addGameTask(&Game::playerMove, player->getID(), DIRECTION_SOUTHWEST); break;
		case 0x6D: addGameTask(&Game::playerMove, player->getID(), DIRECTION_NORTHWEST); break;
		case 0x6F: addGameTaskTimed(DISPATCHER_TASK_EXPIRATION, &Game::playerTurn, player->getID(), DIRECTION_NORTH); break;
		case 0x70: addGameTaskTimed(DISPATCHER_TASK_EXPIRATION, &Game::playerTurn, player->getID(), DIRECTION_EAST); break;
		case 0x71: addGameTaskTimed(DISPATCHER_TASK_EXPIRATION, &Game::playerTurn, player->getID(), DIRECTION_SOUTH); break;
		case 0x72: addGameTaskTimed(DISPATCHER_TASK_EXPIRATION, &Game::playerTurn, player->getID(), DIRECTION_WEST); break;
		case 0x77: parseEquipObject(msg); break;
		case 0x78: parseThrow(msg); break;
		case 0x79: parseLookInShop(msg); break;
		case 0x7A: parsePlayerPurchase(msg); break;
		case 0x7B: parsePlayerSale(msg); break;
		case 0x7C: addGameTask(&Game::playerCloseShop, player->getID()); break;
		case 0x7D: parseRequestTrade(msg); break;
		case 0x7E: parseLookInTrade(msg); break;
		case 0x7F: addGameTask(&Game::playerAcceptTrade, player->getID()); break;
		case 0x80: addGameTask(&Game::playerCloseTrade, player->getID()); break;
		case 0x82: parseUseItem(msg); break;
		case 0x83: parseUseItemEx(msg); break;
		case 0x84: parseUseWithCreature(msg); break;
		case 0x85: parseRotateItem(msg); break;
		case 0x87: parseCloseContainer(msg); break;
		case 0x88: parseUpArrowContainer(msg); break;
		case 0x89: parseTextWindow(msg); break;
		case 0x8A: parseHouseWindow(msg); break;
		case 0x8B: parseWrapableItem(msg); break;
		case 0x8C: parseLookAt(msg); break;
		case 0x8D: parseLookInBattleList(msg); break;
		case 0x8E: /* join aggression */ break;
		case 0x8F: parseQuickLoot(msg); break;
		case 0x90: parseLootContainer(msg); break;
		case 0x91: parseQuickLootBlackWhitelist(msg); break;
		case 0x92: parseResquestLockItems(); break;
		case 0x96: parseSay(msg); break;
		case 0x97: addGameTask(&Game::playerRequestChannels, player->getID()); break;
		case 0x98: parseOpenChannel(msg); break;
		case 0x99: parseCloseChannel(msg); break;
		case 0x9A: parseOpenPrivateChannel(msg); break;
		case 0x9E: addGameTask(&Game::playerCloseNpcChannel, player->getID()); break;
		case 0xA0: parseFightModes(msg); break;
		case 0xA1: parseAttack(msg); break;
		case 0xA2: parseFollow(msg); break;
		case 0xA3: parseInviteToParty(msg); break;
		case 0xA4: parseJoinParty(msg); break;
		case 0xA5: parseRevokePartyInvite(msg); break;
		case 0xA6: parsePassPartyLeadership(msg); break;
		case 0xA7: addGameTask(&Game::playerLeaveParty, player->getID()); break;
		case 0xA8: parseEnableSharedPartyExperience(msg); break;
		case 0xAA: addGameTask(&Game::playerCreatePrivateChannel, player->getID()); break;
		case 0xAB: parseChannelInvite(msg); break;
		case 0xAC: parseChannelExclude(msg); break;
		case 0xB1: parseHighscores(msg); break;
		case 0xBE: addGameTask(&Game::playerCancelAttackAndFollow, player->getID()); break;
		case 0xC7: parseTournamentLeaderboard(msg); break;
		case 0xC9: /* update tile */ break;
		case 0xCA: parseUpdateContainer(msg); break;
		case 0xCB: parseBrowseField(msg); break;
		case 0xCC: parseSeekInContainer(msg); break;
		case 0xCD: parseInspectionObject(msg); break;
		case 0xD2: addGameTask(&Game::playerRequestOutfit, player->getID()); break;
		case 0xD3: parseSetOutfit(msg); break;
		case 0xD4: parseToggleMount(msg); break;
		case 0xD5: parseApplyImbuemente(msg); break;
		case 0xD6: parseClearingImbuement(msg); break;
		case 0xD7: parseCloseImbuingWindow(msg); break;
		case 0xDC: parseAddVip(msg); break;
		case 0xDD: parseRemoveVip(msg); break;
		case 0xDE: parseEditVip(msg); break;
		case 0xE1: parseRequestBestiaryData(); break;
		case 0xE2: parseRequestBestiaryOverview(msg); break;
		case 0xE3: parseRequestBestiaryMonsterData(msg); break;
		case 0xE4: parseRequestUnlockCharm(msg); break;
		case 0xE5: parseCyclopediaCharacterInfo(msg); break;
		case 0xE6: parseBugReport(msg); break;
		case 0xE7: parseThankYou(msg); break;
		case 0xE8: (version < 1180 ? parseDebugAssert(msg) : parseSendDescription(msg)); break;
		case 0xEA: parseRequestCharmData(); break;
		case 0xEE: parseNPCSay(msg); break;
		case 0xEF: parseTransferCoins(msg); break;
		case 0xF0: addGameTaskTimed(DISPATCHER_TASK_EXPIRATION, &Game::playerShowQuestLog, player->getID()); break;
		case 0xF1: parseQuestLine(msg); break;
		case 0xF2: parseRuleViolationReport(msg); break;
		case 0xF3: /* get object info */ break;
		case 0xF4: parseMarketLeave(); break;
		case 0xF5: parseMarketBrowse(msg); break;
		case 0xF6: parseMarketCreateOffer(msg); break;
		case 0xF7: parseMarketCancelOffer(msg); break;
		case 0xF8: parseMarketAcceptOffer(msg); break;
		case 0xF9: parseModalWindowAnswer(msg); break;
		case 0xFA: parseOpenStore(); break;
		case 0xFB: parseRequestStoreOffers(msg); break;
		case 0xFC: parseBuyStoreOffer(msg); break;
		case 0xFD: parseOpenTransactionHistory(msg); break;
		case 0xFE: parseRequestTransactionHistory(msg); break;
		case 0xED: parseRequestResourceData(msg); break;
		case 0xEB: parsePreyAction(msg); break;

		// ignorar
		case 0x1c: /* */ break;

		//case 0x77 Equip Hotkey.
		//case 0xDF, 0xE0, 0xE1, 0xFB, 0xFC, 0xFD, 0xFE Premium Shop.
		//case 0xe2 request bestiary monster.

		default:
			if(g_config.getBoolean(ConfigManager::SHOW_PACKETS) || recvbyte == 0x90) {
				NetworkMessage decompressBuffer = msg;
				std::cout << "Player: " << player->getName() << " sent an unknown packet header: 0x" << std::hex << static_cast<uint16_t>(recvbyte) << std::dec << "!" << std::endl;
				std::ostringstream ss;
				ss << "{";
				for (int i = 0; i < decompressBuffer.getLength(); i++) {
					ss << "0x" << std::hex << static_cast<uint16_t>(decompressBuffer.getByte()) << ", ";
				}
				ss << "};";
				std::cout << "Full message: " << ss.str() << std::endl;
			}
			break;
	}

	if (msg.isOverrun()) {
		std::cout << "Player: " << player->getName() << " disconnected: msg over run! 0x" << std::hex << static_cast<uint16_t>(recvbyte) << std::dec << "!" << std::endl;
		disconnect();
	}
}

// Parse methods
void ProtocolGame::parseChannelInvite(NetworkMessage& msg)
{
	const std::string name = msg.getString();
	addGameTask(&Game::playerChannelInvite, player->getID(), name);
}

void ProtocolGame::parseChannelExclude(NetworkMessage& msg)
{
	const std::string name = msg.getString();
	addGameTask(&Game::playerChannelExclude, player->getID(), name);
}

void ProtocolGame::parseOpenChannel(NetworkMessage& msg)
{
	uint16_t channelId = msg.get<uint16_t>();
	addGameTask(&Game::playerOpenChannel, player->getID(), channelId);
}

void ProtocolGame::parseCloseChannel(NetworkMessage& msg)
{
	uint16_t channelId = msg.get<uint16_t>();
	addGameTask(&Game::playerCloseChannel, player->getID(), channelId);
}

void ProtocolGame::parseOpenPrivateChannel(NetworkMessage& msg)
{
	const std::string receiver = msg.getString();
	addGameTask(&Game::playerOpenPrivateChannel, player->getID(), receiver);
}

void ProtocolGame::parseAutoWalk(NetworkMessage& msg)
{
	uint8_t numdirs = msg.getByte();
	if (numdirs == 0 || (msg.getBufferPosition() + numdirs) != (msg.getLength() + 8)) {
		return;
	}

	msg.skipBytes(numdirs);

	std::forward_list<Direction> path;
	for (uint8_t i = 0; i < numdirs; ++i) {
		uint8_t rawdir = msg.getPreviousByte();
		switch (rawdir) {
			case 1: path.push_front(DIRECTION_EAST); break;
			case 2: path.push_front(DIRECTION_NORTHEAST); break;
			case 3: path.push_front(DIRECTION_NORTH); break;
			case 4: path.push_front(DIRECTION_NORTHWEST); break;
			case 5: path.push_front(DIRECTION_WEST); break;
			case 6: path.push_front(DIRECTION_SOUTHWEST); break;
			case 7: path.push_front(DIRECTION_SOUTH); break;
			case 8: path.push_front(DIRECTION_SOUTHEAST); break;
			default: break;
		}
	}

	if (path.empty()) {
		return;
	}

	addGameTask(&Game::playerAutoWalk, player->getID(), path);
}

void ProtocolGame::parseSetOutfit(NetworkMessage& msg)
{
	uint8_t outfitType = 0;
	if (version >= 1220) {//Maybe some versions before? but I don't have executable to check
		outfitType = msg.getByte();
	}
	Outfit_t newOutfit;
	newOutfit.lookType = msg.get<uint16_t>();
	newOutfit.lookHead = std::min<uint8_t>(132, msg.getByte());
	newOutfit.lookBody = std::min<uint8_t>(132, msg.getByte());
	newOutfit.lookLegs = std::min<uint8_t>(132, msg.getByte());
	newOutfit.lookFeet = std::min<uint8_t>(132, msg.getByte());
	newOutfit.lookAddons = msg.getByte();
	if (outfitType == 0) {
		newOutfit.lookMount = msg.get<uint16_t>();
		newOutfit.lookMountHead = std::min<uint8_t>(132, msg.getByte());
		newOutfit.lookMountBody = std::min<uint8_t>(132, msg.getByte());
		newOutfit.lookMountLegs = std::min<uint8_t>(132, msg.getByte());
		newOutfit.lookMountFeet = std::min<uint8_t>(132, msg.getByte());
		newOutfit.lookFamiliarsType = msg.get<uint16_t>();
	} else if (outfitType == 1) {
		//This value probably has something to do with try outfit variable inside outfit window dialog
		//if try outfit is set to 2 it expects uint32_t value after mounted and disable mounts from outfit window dialog
		newOutfit.lookMount = 0;
		msg.get<uint32_t>();
	}
	addGameTask(&Game::playerChangeOutfit, player->getID(), newOutfit);
}

void ProtocolGame::parseToggleMount(NetworkMessage& msg)
{
	bool mount = msg.getByte() != 0;
	addGameTask(&Game::playerToggleMount, player->getID(), mount);
}

void ProtocolGame::parseApplyImbuemente(NetworkMessage& msg)
{
	uint8_t slot = msg.getByte();
	uint32_t imbuementId = msg.get<uint32_t>();
	bool protectionCharm = msg.getByte() != 0x00;
	addGameTask(&Game::playerApplyImbuement, player->getID(), imbuementId, slot, protectionCharm);
}

void ProtocolGame::parseClearingImbuement(NetworkMessage& msg)
{
	uint8_t slot = msg.getByte();
	addGameTask(&Game::playerClearingImbuement, player->getID(), slot);
}

void ProtocolGame::parseCloseImbuingWindow(NetworkMessage&)
{
	addGameTask(&Game::playerCloseImbuingWindow, player->getID());
}

void ProtocolGame::parseUseItem(NetworkMessage& msg)
{
	Position pos = msg.getPosition();
	uint16_t spriteId = msg.get<uint16_t>();
	uint8_t stackpos = msg.getByte();
	uint8_t index = msg.getByte();
	addGameTaskTimed(DISPATCHER_TASK_EXPIRATION, &Game::playerUseItem, player->getID(), pos, stackpos, index, spriteId);
}

void ProtocolGame::parseUseItemEx(NetworkMessage& msg)
{
	Position fromPos = msg.getPosition();
	uint16_t fromSpriteId = msg.get<uint16_t>();
	uint8_t fromStackPos = msg.getByte();
	Position toPos = msg.getPosition();
	uint16_t toSpriteId = msg.get<uint16_t>();
	uint8_t toStackPos = msg.getByte();
	addGameTaskTimed(DISPATCHER_TASK_EXPIRATION, &Game::playerUseItemEx, player->getID(), fromPos, fromStackPos, fromSpriteId, toPos, toStackPos, toSpriteId);
}

void ProtocolGame::parseUseWithCreature(NetworkMessage& msg)
{
	Position fromPos = msg.getPosition();
	uint16_t spriteId = msg.get<uint16_t>();
	uint8_t fromStackPos = msg.getByte();
	uint32_t creatureId = msg.get<uint32_t>();
	addGameTaskTimed(DISPATCHER_TASK_EXPIRATION, &Game::playerUseWithCreature, player->getID(), fromPos, fromStackPos, creatureId, spriteId);
}

void ProtocolGame::parseCloseContainer(NetworkMessage& msg)
{
	uint8_t cid = msg.getByte();
	addGameTask(&Game::playerCloseContainer, player->getID(), cid);
}

void ProtocolGame::parseUpArrowContainer(NetworkMessage& msg)
{
	uint8_t cid = msg.getByte();
	addGameTask(&Game::playerMoveUpContainer, player->getID(), cid);
}

void ProtocolGame::parseUpdateContainer(NetworkMessage& msg)
{
	uint8_t cid = msg.getByte();
	addGameTask(&Game::playerUpdateContainer, player->getID(), cid);
}

void ProtocolGame::parseThrow(NetworkMessage& msg)
{
	Position fromPos = msg.getPosition();
	uint16_t spriteId = msg.get<uint16_t>();
	uint8_t fromStackpos = msg.getByte();
	Position toPos = msg.getPosition();
	uint8_t count = msg.getByte();

	if (toPos != fromPos) {
		addGameTaskTimed(DISPATCHER_TASK_EXPIRATION, &Game::playerMoveThing, player->getID(), fromPos, spriteId, fromStackpos, toPos, count);
	}
}

void ProtocolGame::parseLookAt(NetworkMessage& msg)
{
	Position pos = msg.getPosition();
	msg.skipBytes(2); // spriteId
	uint8_t stackpos = msg.getByte();
	addGameTaskTimed(DISPATCHER_TASK_EXPIRATION, &Game::playerLookAt, player->getID(), pos, stackpos);
}

void ProtocolGame::parseLookInBattleList(NetworkMessage& msg)
{
	uint32_t creatureId = msg.get<uint32_t>();
	addGameTaskTimed(DISPATCHER_TASK_EXPIRATION, &Game::playerLookInBattleList, player->getID(), creatureId);
}

void ProtocolGame::parseQuickLoot(NetworkMessage& msg)
{
	Position pos = msg.getPosition();
	uint16_t spriteId = msg.get<uint16_t>();
	uint8_t stackpos = msg.getByte();
	addGameTask(&Game::playerQuickLoot, player->getID(), pos, spriteId, stackpos, nullptr);
}

void ProtocolGame::parseLootContainer(NetworkMessage& msg)
{
	uint8_t action = msg.getByte();
	if (action == 0) {
		ObjectCategory_t category = (ObjectCategory_t)msg.getByte();
		Position pos = msg.getPosition();
		uint16_t spriteId = msg.get<uint16_t>();
		uint8_t stackpos = msg.getByte();
		addGameTask(&Game::playerSetLootContainer, player->getID(), category, pos, spriteId, stackpos);
	} else if (action == 1) {
		ObjectCategory_t category = (ObjectCategory_t)msg.getByte();
		addGameTask(&Game::playerClearLootContainer, player->getID(), category);
	} else if (action == 3) {
		bool useMainAsFallback = msg.getByte() == 1;
		addGameTask(&Game::playerSetQuickLootFallback, player->getID(), useMainAsFallback);
	}

//	sendLootContainers();
}

void ProtocolGame::parseQuickLootBlackWhitelist(NetworkMessage& msg)
{
	QuickLootFilter_t filter = (QuickLootFilter_t)msg.getByte();
	std::vector<uint16_t> listedItems;

	uint16_t size = msg.get<uint16_t>();
	listedItems.reserve(size);

	for (int i = 0; i < size; i++) {
		listedItems.push_back(msg.get<uint16_t>());
	}

	addGameTask(&Game::playerQuickLootBlackWhitelist, player->getID(), filter, listedItems);
}

void ProtocolGame::parseResquestLockItems()
{
	addGameTask(&Game::playerRequestLockFind, player->getID());
}

void ProtocolGame::parseSay(NetworkMessage& msg)
{
	std::string receiver;
	uint16_t channelId;

	SpeakClasses type = static_cast<SpeakClasses>(msg.getByte());
	switch (type) {
		case TALKTYPE_PRIVATE_TO:
		case TALKTYPE_PRIVATE_RED_TO:
			receiver = msg.getString();
			channelId = 0;
			break;

		case TALKTYPE_CHANNEL_Y:
		case TALKTYPE_CHANNEL_R1:
			channelId = msg.get<uint16_t>();
			break;

		default:
			channelId = 0;
			break;
	}

	const std::string text = msg.getString();
	if (text.length() > 255) {
		return;
	}

	addGameTask(&Game::playerSay, player->getID(), channelId, type, receiver, text);
}

void ProtocolGame::parseFightModes(NetworkMessage& msg)
{
	uint8_t rawFightMode = msg.getByte(); // 1 - offensive, 2 - balanced, 3 - defensive
	uint8_t rawChaseMode = msg.getByte(); // 0 - stand while fightning, 1 - chase opponent
	uint8_t rawSecureMode = msg.getByte(); // 0 - can't attack unmarked, 1 - can attack unmarked
	// uint8_t rawPvpMode = msg.getByte(); // pvp mode introduced in 10.0

	fightMode_t fightMode;
	if (rawFightMode == 1) {
		fightMode = FIGHTMODE_ATTACK;
	} else if (rawFightMode == 2) {
		fightMode = FIGHTMODE_BALANCED;
	} else {
		fightMode = FIGHTMODE_DEFENSE;
	}

	addGameTask(&Game::playerSetFightModes, player->getID(), fightMode, rawChaseMode != 0, rawSecureMode != 0);
}

void ProtocolGame::parseAttack(NetworkMessage& msg)
{
	uint32_t creatureId = msg.get<uint32_t>();
	// msg.get<uint32_t>(); creatureId (same as above)
	addGameTask(&Game::playerSetAttackedCreature, player->getID(), creatureId);
}

void ProtocolGame::parseFollow(NetworkMessage& msg)
{
	uint32_t creatureId = msg.get<uint32_t>();
	// msg.get<uint32_t>(); creatureId (same as above)
	addGameTask(&Game::playerFollowCreature, player->getID(), creatureId);
}

void ProtocolGame::parseTextWindow(NetworkMessage& msg)
{
	uint32_t windowTextId = msg.get<uint32_t>();
	const std::string newText = msg.getString();
	addGameTask(&Game::playerWriteItem, player->getID(), windowTextId, newText);
}

void ProtocolGame::parseEquipObject(NetworkMessage& msg)
{
	uint16_t spriteId = msg.get<uint16_t>();
	// msg.get<uint8_t>();

	addGameTaskTimed(DISPATCHER_TASK_EXPIRATION, &Game::playerEquipItem, player->getID(), spriteId);
}

void ProtocolGame::parseHouseWindow(NetworkMessage& msg)
{
	uint8_t doorId = msg.getByte();
	uint32_t id = msg.get<uint32_t>();
	const std::string text = msg.getString();
	addGameTask(&Game::playerUpdateHouseWindow, player->getID(), doorId, id, text);
}

void ProtocolGame::parseLookInShop(NetworkMessage& msg)
{
	uint16_t id = msg.get<uint16_t>();
	uint8_t count = msg.getByte();
	addGameTaskTimed(DISPATCHER_TASK_EXPIRATION, &Game::playerLookInShop, player->getID(), id, count);
}

void ProtocolGame::parsePlayerPurchase(NetworkMessage& msg)
{
	uint16_t id = msg.get<uint16_t>();
	uint8_t count = msg.getByte();
	uint8_t amount = msg.getByte();
	bool ignoreCap = msg.getByte() != 0;
	bool inBackpacks = msg.getByte() != 0;
	addGameTaskTimed(DISPATCHER_TASK_EXPIRATION, &Game::playerPurchaseItem, player->getID(), id, count, amount, ignoreCap, inBackpacks);
}

void ProtocolGame::parsePlayerSale(NetworkMessage& msg)
{
	uint16_t id = msg.get<uint16_t>();
	uint8_t count = msg.getByte();
	uint8_t amount = msg.getByte();
	bool ignoreEquipped = msg.getByte() != 0;
	addGameTaskTimed(DISPATCHER_TASK_EXPIRATION, &Game::playerSellItem, player->getID(), id, count, amount, ignoreEquipped);
}

void ProtocolGame::parseRequestTrade(NetworkMessage& msg)
{
	Position pos = msg.getPosition();
	uint16_t spriteId = msg.get<uint16_t>();
	uint8_t stackpos = msg.getByte();
	uint32_t playerId = msg.get<uint32_t>();
	addGameTask(&Game::playerRequestTrade, player->getID(), pos, stackpos, playerId, spriteId);
}

void ProtocolGame::parseLookInTrade(NetworkMessage& msg)
{
	bool counterOffer = (msg.getByte() == 0x01);
	uint8_t index = msg.getByte();
	addGameTaskTimed(DISPATCHER_TASK_EXPIRATION, &Game::playerLookInTrade, player->getID(), counterOffer, index);
}

void ProtocolGame::parseAddVip(NetworkMessage& msg)
{
	const std::string name = msg.getString();
	addGameTask(&Game::playerRequestAddVip, player->getID(), name);
}

void ProtocolGame::parseRemoveVip(NetworkMessage& msg)
{
	uint32_t guid = msg.get<uint32_t>();
	addGameTask(&Game::playerRequestRemoveVip, player->getID(), guid);
}

void ProtocolGame::parseEditVip(NetworkMessage& msg)
{
	uint32_t guid = msg.get<uint32_t>();
	const std::string description = msg.getString();
	uint32_t icon = std::min<uint32_t>(10, msg.get<uint32_t>()); // 10 is max icon in 9.63
	bool notify = msg.getByte() != 0;
	addGameTask(&Game::playerRequestEditVip, player->getID(), guid, description, icon, notify);
}

void ProtocolGame::parseRotateItem(NetworkMessage& msg)
{
	Position pos = msg.getPosition();
	uint16_t spriteId = msg.get<uint16_t>();
	uint8_t stackpos = msg.getByte();
	addGameTaskTimed(DISPATCHER_TASK_EXPIRATION, &Game::playerRotateItem, player->getID(), pos, stackpos, spriteId);
}

void ProtocolGame::parseWrapableItem(NetworkMessage& msg)
{
	Position pos = msg.getPosition();
	uint16_t spriteId = msg.get<uint16_t>();
	uint8_t stackpos = msg.getByte();
	addGameTaskTimed(DISPATCHER_TASK_EXPIRATION, &Game::playerWrapableItem, player->getID(), pos, stackpos, spriteId);
}

void ProtocolGame::parseCyclopediaCharacterInfo(NetworkMessage& msg) {
	uint32_t characterID;
	CyclopediaCharacterInfoType_t characterInfoType;
	characterID = msg.get<uint32_t>();
	characterInfoType = static_cast<CyclopediaCharacterInfoType_t>(msg.getByte());
	uint16_t entriesPerPage = 0, page = 0;
	if (characterInfoType == CYCLOPEDIA_CHARACTERINFO_RECENTDEATHS || characterInfoType == CYCLOPEDIA_CHARACTERINFO_RECENTPVPKILLS) {
		entriesPerPage = std::min<uint16_t>(30, std::max<uint16_t>(5, msg.get<uint16_t>()));
		page = std::max<uint16_t>(1, msg.get<uint16_t>());
	}
	if (characterID == 0) {
		characterID = player->getGUID();
	}
	g_game.playerCyclopediaCharacterInfo(player, characterID, characterInfoType, entriesPerPage, page);
}

void ProtocolGame::parseHighscores(NetworkMessage& msg)
{
	HighscoreType_t type = static_cast<HighscoreType_t>(msg.getByte());
	uint8_t category = msg.getByte();
	uint32_t vocation = msg.get<uint32_t>();
	uint16_t page = 1;
	const std::string worldName = msg.getString();
#if CLIENT_VERSION >= 1260
	msg.getByte();//Game World Category
	msg.getByte();//BattlEye World Type
#endif
	if (type == HIGHSCORE_GETENTRIES) {
		page = std::max<uint16_t>(1, msg.get<uint16_t>());
	}
	uint8_t entriesPerPage = std::min<uint8_t>(30, std::max<uint8_t>(5, msg.getByte()));
	g_game.playerHighscores(player, type, category, vocation, worldName, page, entriesPerPage);
}

void ProtocolGame::sendHighscoresNoData()
{
	NetworkMessage msg;
	msg.addByte(0xB1);
	msg.addByte(0x01); // No data available
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendHighscores(const std::vector<HighscoreCharacter>& characters, uint8_t categoryId, uint32_t vocationId, uint16_t page, uint16_t pages)
{
	NetworkMessage msg;
	msg.addByte(0xB1);
	msg.addByte(0x00); // No data available

	msg.addByte(1); // Worlds
	msg.addString(g_config.getString(ConfigManager::SERVER_NAME)); // First World
	msg.addString(g_config.getString(ConfigManager::SERVER_NAME)); // Selected World

#if CLIENT_VERSION >= 1260
	msg.addByte(0xFF);//Game World Category: 0xFF(-1) - Selected World
	msg.addByte(0xFF);//BattlEye World Type
#endif

	auto vocationPosition = msg.getBufferPosition();
	uint8_t vocations = 1;

	msg.skipBytes(1); // Vocation Count
	msg.add<uint32_t>(0xFFFFFFFF); // All Vocations - hardcoded
	msg.addString("(all)"); // All Vocations - hardcoded

	uint32_t selectedVocation = 0xFFFFFFFF;
	const auto& vocationsMap = g_vocations.getVocations();
	for (const auto& it : vocationsMap) {
		const Vocation& vocation = it.second;
		if (vocation.getFromVocation() == static_cast<uint32_t>(vocation.getId())) {
			msg.add<uint32_t>(vocation.getFromVocation()); // Vocation Id
			msg.addString(vocation.getVocName()); // Vocation Name
			++vocations;
			if (vocation.getFromVocation() == vocationId) {
				selectedVocation = vocationId;
			}
		}
	}
	msg.add<uint32_t>(selectedVocation); // Selected Vocation

	HighscoreCategory highscoreCategories[] =
	{
		{"Experience Points", HIGHSCORE_CATEGORY_EXPERIENCE},
		{"Fist Fighting", HIGHSCORE_CATEGORY_FIST_FIGHTING},
		{"Club Fighting", HIGHSCORE_CATEGORY_CLUB_FIGHTING},
		{"Sword Fighting", HIGHSCORE_CATEGORY_SWORD_FIGHTING},
		{"Axe Fighting", HIGHSCORE_CATEGORY_AXE_FIGHTING},
		{"Distance Fighting", HIGHSCORE_CATEGORY_DISTANCE_FIGHTING},
		{"Shielding", HIGHSCORE_CATEGORY_SHIELDING},
		{"Fishing", HIGHSCORE_CATEGORY_FISHING},
		{"Magic Level", HIGHSCORE_CATEGORY_MAGIC_LEVEL}
	};

	uint8_t selectedCategory = 0;
	msg.addByte(sizeof(highscoreCategories) / sizeof(HighscoreCategory)); // Category Count
	for (HighscoreCategory& category : highscoreCategories) {
		msg.addByte(category.id); // Category Id
		msg.addString(category.name); // Category Name
		if (category.id == categoryId) {
			selectedCategory = categoryId;
		}
	}
	msg.addByte(selectedCategory); // Selected Category

	msg.add<uint16_t>(page); // Current page
	msg.add<uint16_t>(pages); // Pages

	msg.addByte(characters.size()); // Character Count
	for (const HighscoreCharacter& character : characters) {
		msg.add<uint32_t>(character.rank); // Rank
		msg.addString(character.name); // Character Name
		msg.addString(""); // Probably Character Title(not visible in window)
		msg.addByte(character.vocation); // Vocation Id
		msg.addString(g_config.getString(ConfigManager::SERVER_NAME)); // World
		msg.add<uint16_t>(character.level); // Level
		msg.addByte((player->getGUID() == character.id)); // Player Indicator Boolean
		msg.add<uint64_t>(character.points); // Points
	}

	msg.addByte(0xFF); // ??
	msg.addByte(0); // ??
	msg.addByte(1); // ??
	msg.add<uint32_t>(time(nullptr)); // Last Update

	msg.setBufferPosition(vocationPosition);
	msg.addByte(vocations);
	writeToOutputBuffer(msg);
}

void ProtocolGame::parseTournamentLeaderboard(NetworkMessage& msg) {
	uint8_t ledaerboardType = msg.getByte();
	if (ledaerboardType == 0) {
		const std::string worldName = msg.getString();
		uint16_t currentPage = msg.get<uint16_t>();
		(void)worldName;
		(void)currentPage;
	}
	else if (ledaerboardType == 1) {
		const std::string worldName = msg.getString();
		const std::string characterName = msg.getString();
		(void)worldName;
		(void)characterName;
	}
	uint8_t elementsPerPage = msg.getByte();
	(void)elementsPerPage;

	addGameTask(&Game::playerTournamentLeaderboard, player->getID(), ledaerboardType);
}

void ProtocolGame::parseRuleViolationReport(NetworkMessage &msg)
{
	uint8_t reportType = msg.getByte();
	uint8_t reportReason = msg.getByte();
	const std::string& targetName = msg.getString();
	const std::string& comment = msg.getString();
	std::string translation;
	if (reportType == REPORT_TYPE_NAME) {
		translation = msg.getString();
	} else if (reportType == REPORT_TYPE_STATEMENT) {
		translation = msg.getString();
		msg.get<uint32_t>(); // statement id, used to get whatever player have said, we don't log that.  
	}

	addGameTask(&Game::playerReportRuleViolationReport, player->getID(), targetName, reportType, reportReason, comment, translation);
}

void ProtocolGame::parseRequestBestiaryData()
{
	addGameTask(&Game::playerBestiaryGroups, player->getID());
}

void ProtocolGame::parseRequestBestiaryOverview(NetworkMessage& msg)
{
	uint8_t type = msg.getByte();
	if (type == 0x00) {
		std::string raceName = msg.getString();
		player->sendBestiaryOverview(raceName);
	} else if (type == 0x01) {
		std::vector<uint16_t> monsters;
		uint16_t size = msg.get<uint16_t>();
		for(uint16_t i = 0; i < size; i++) {
			monsters.emplace_back(msg.get<uint16_t>());
		}
		player->sendBestiaryOverview(monsters);
	}
}

void ProtocolGame::parseRequestBestiaryMonsterData(NetworkMessage& msg)
{
	player->sendCharmData();
	uint16_t monsterId = msg.get<uint16_t>();
	addGameTask(&Game::playerBestiaryMonsterData, player->getID(), monsterId);
}

void ProtocolGame::parseRequestUnlockCharm(NetworkMessage& msg)
{
	uint8_t charmid = msg.getByte();
	uint8_t action = msg.getByte();
	uint16_t raceid = 0;
	if (action == 0x00) {
		// 
	} else if (action == 0x01) {
		raceid = msg.get<uint16_t>();
	} else if (action == 0x02) {
		// remove
	}

	addGameTask(&Game::playerUnlockCharm, player->getID(), charmid, action, raceid);
}

void ProtocolGame::parseRequestCharmData()
{
	addGameTask(&Game::playerCharmData, player->getID());
}

void ProtocolGame::parseNPCSay(NetworkMessage& msg)
{
	uint32_t creatureId = msg.get<uint32_t>();
	addGameTask(&Game::playerNPCSay, player->getID(), creatureId);
}

void ProtocolGame::parseThankYou(NetworkMessage& msg)
{
	uint32_t a_statementId = msg.get<uint32_t>();

	addGameTask(&Game::playerSendThankYou, player->getID(), a_statementId);
}

void ProtocolGame::parseBugReport(NetworkMessage& msg)
{
	uint8_t category = msg.getByte();
	std::string message = msg.getString();

	Position position;
	if (category == BUG_CATEGORY_MAP) {
		position = msg.getPosition();
	}

	addGameTask(&Game::playerReportBug, player->getID(), message, position, category);
}

void ProtocolGame::parseDebugAssert(NetworkMessage& msg)
{
	if (version >= 1200) {
		return;
	}

	if (debugAssertSent) {
		return;
	}

	debugAssertSent = true;

	std::string assertLine = msg.getString();
	std::string date = msg.getString();
	std::string description = msg.getString();
	std::string comment = msg.getString();
	addGameTask(&Game::playerDebugAssert, player->getID(), assertLine, date, description, comment);
}

void ProtocolGame::parseInviteToParty(NetworkMessage& msg)
{
	uint32_t targetId = msg.get<uint32_t>();
	addGameTask(&Game::playerInviteToParty, player->getID(), targetId);
}

void ProtocolGame::parseJoinParty(NetworkMessage& msg)
{
	uint32_t targetId = msg.get<uint32_t>();
	addGameTask(&Game::playerJoinParty, player->getID(), targetId);
}

void ProtocolGame::parseRevokePartyInvite(NetworkMessage& msg)
{
	uint32_t targetId = msg.get<uint32_t>();
	addGameTask(&Game::playerRevokePartyInvitation, player->getID(), targetId);
}

void ProtocolGame::parsePassPartyLeadership(NetworkMessage& msg)
{
	uint32_t targetId = msg.get<uint32_t>();
	addGameTask(&Game::playerPassPartyLeadership, player->getID(), targetId);
}

void ProtocolGame::parseEnableSharedPartyExperience(NetworkMessage& msg)
{
	bool sharedExpActive = msg.getByte() == 1;
	addGameTask(&Game::playerEnableSharedPartyExperience, player->getID(), sharedExpActive);
}

void ProtocolGame::parseQuestLine(NetworkMessage& msg)
{
	uint16_t questId = msg.get<uint16_t>();
	addGameTask(&Game::playerShowQuestLine, player->getID(), questId);
}

void ProtocolGame::parseMarketLeave()
{
	addGameTask(&Game::playerLeaveMarket, player->getID());
}

void ProtocolGame::parseMarketBrowse(NetworkMessage& msg)
{
	uint16_t browseId = msg.get<uint16_t>();

	if (browseId == MARKETREQUEST_OWN_OFFERS) {
		addGameTask(&Game::playerBrowseMarketOwnOffers, player->getID());
	} else if (browseId == MARKETREQUEST_OWN_HISTORY) {
		addGameTask(&Game::playerBrowseMarketOwnHistory, player->getID());
	} else {
		addGameTask(&Game::playerBrowseMarket, player->getID(), browseId);
	}
}

void ProtocolGame::parseTransferCoins(NetworkMessage& msg) {
	std::string recipient = msg.getString();
	uint16_t amount = msg.get<uint16_t>();

	addGameTask(&Game::playerTransferCoins, player->getID(), recipient, amount);
}

void ProtocolGame::parseMarketCreateOffer(NetworkMessage& msg)
{
	uint8_t type = msg.getByte();
	uint16_t spriteId = msg.get<uint16_t>();
	uint16_t amount = msg.get<uint16_t>();
	uint32_t price = msg.get<uint32_t>();
	bool anonymous = (msg.getByte() != 0);
	if (amount > 0 && price > 0) {
		addGameTask(&Game::playerCreateMarketOffer, player->getID(), type, spriteId, amount, price, anonymous);
	}
}

void ProtocolGame::parseMarketCancelOffer(NetworkMessage& msg)
{
	uint32_t timestamp = msg.get<uint32_t>();
	uint16_t counter = msg.get<uint16_t>();
	if (counter > 0) {
		addGameTask(&Game::playerCancelMarketOffer, player->getID(), timestamp, counter);
	}

	updateCoinBalance();
}

void ProtocolGame::parseMarketAcceptOffer(NetworkMessage& msg)
{
	uint32_t timestamp = msg.get<uint32_t>();
	uint16_t counter = msg.get<uint16_t>();
	uint16_t amount = msg.get<uint16_t>();
	if (amount > 0 && counter > 0) {
		addGameTask(&Game::playerAcceptMarketOffer, player->getID(), timestamp, counter, amount);
	}

	updateCoinBalance();
}

void ProtocolGame::parseModalWindowAnswer(NetworkMessage& msg)
{
	uint32_t id = msg.get<uint32_t>();
	uint8_t button = msg.getByte();
	uint8_t choice = msg.getByte();
	addGameTask(&Game::playerAnswerModalWindow, player->getID(), id, button, choice);
}

void ProtocolGame::parseOpenStore()
{
	addGameTask(&Game::playerOpenStore, player->getID(), true, nullptr);
}

void ProtocolGame::parseRequestStoreOffers(NetworkMessage& msg)
{
	uint8_t actionType = msg.getByte();
	if (actionType == 0 && version >= 1150) {
		player->sendStoreHome();
		return;		
	}

	StoreOffers* offers = nullptr;
	if (version <= 1100 ) {
		std::string categoryName = msg.getString();
		offers = g_store.getOfferByName(categoryName);
	} else if (actionType == 0) {
		offers = g_store.getOfferByName(g_config.getString(ConfigManager::DEFAULT_OFFER));
	} else if (actionType == 2) {
		std::string categoryName = msg.getString();
		offers = g_store.getOfferByName(categoryName);
	} else if (actionType == 4) {
		uint32_t id = msg.get<uint32_t>();
		offers = g_store.getOffersByOfferId(id);
	} else {
		// std::cout << "teste 3" << std::endl;
		// std::string categoryName = msg.getString();
		// offers = g_store.getOfferByName(categoryName);
	}

	if (offers != nullptr) {
		addGameTask(&Game::playerOpenStore, player->getID(), false, offers);
	} else if (version >= 1150) {
		addGameTask(&Game::playerOpenStore, player->getID(), false, nullptr);
	}
}

void ProtocolGame::parseBuyStoreOffer(NetworkMessage& msg)
{
	uint32_t id = msg.get<uint32_t>();
	OfferBuyTypes_t productType = static_cast<OfferBuyTypes_t>(msg.getByte());
	std::string param;

	StoreOffer* offer = g_store.getOfferById(id);
	if (offer == nullptr) {
		return;
	}

	if (offer->getOfferType() == OFFER_TYPE_NAMECHANGE && productType != OFFER_BUY_TYPE_NAMECHANGE) {
		requestPurchaseData(id, OFFER_BUY_TYPE_NAMECHANGE);
		return;
	}

	if (offer->getOfferType() == OFFER_TYPE_NAMECHANGE) {
		param = msg.getString();
	}

	addGameTask(&Game::playerBuyStoreOffer, player->getID(), *offer, std::move(param));
}

void ProtocolGame::parseSendDescription(NetworkMessage& msg)
{
	uint32_t offerId = msg.get<uint32_t>();
	StoreOffer* storeOffer = g_store.getOfferById(offerId);
	if (storeOffer == nullptr) {
		return;
	}
	player->sendOfferDescription(offerId, storeOffer->getDescription(player));
}

void ProtocolGame::parseOpenTransactionHistory(NetworkMessage& msg)
{
	uint8_t entryPages = msg.getByte();
	player->setEntriesPerPage(entryPages);
	addGameTask(&Game::playerStoreTransactionHistory, player->getID(), 1, entryPages);
}
void ProtocolGame::parseRequestTransactionHistory(NetworkMessage& msg)
{
	uint32_t pages = msg.get<uint32_t>();
	addGameTask(&Game::playerStoreTransactionHistory, player->getID(), pages + 1, player->getEntriesPerPage());
}

void ProtocolGame::parseBrowseField(NetworkMessage& msg)
{
	const Position& pos = msg.getPosition();
	addGameTask(&Game::playerBrowseField, player->getID(), pos);
}

void ProtocolGame::parseSeekInContainer(NetworkMessage& msg)
{
	uint8_t containerId = msg.getByte();
	uint16_t index = msg.get<uint16_t>();
	addGameTask(&Game::playerSeekInContainer, player->getID(), containerId, index);
}

// Prey System
void ProtocolGame::parseRequestResourceData(NetworkMessage& msg) 
{
	ResourceType_t resourceType = static_cast<ResourceType_t>(msg.getByte());
	addGameTask(&Game::playerRequestResourceData, player->getID(), resourceType);
}

void ProtocolGame::parsePreyAction(NetworkMessage& msg)
{
	uint8_t preySlotId = msg.getByte();
	PreyAction_t preyAction = static_cast<PreyAction_t>(msg.getByte());
	uint8_t monsterIndex = 0;
	uint16_t raceId = 0;
	if (preyAction == PREY_ACTION_MONSTERSELECTION) {
		monsterIndex = msg.getByte();
	} else if (preyAction == NEW_BONUS_SELECTIONWILDCARD) {
		raceId = msg.get<uint16_t>();
	}

	addGameTask(&Game::playerPreyAction, player->getID(), preySlotId, preyAction, monsterIndex, raceId);
}

void ProtocolGame::sendResourceData(ResourceType_t resourceType, int64_t amount) 
{
	NetworkMessage msg;
	msg.addByte(0xEE);
	msg.addByte(resourceType);
	msg.add<int64_t>(amount);
	writeToOutputBuffer(msg);
}

void ProtocolGame::parseInspectionObject(NetworkMessage& msg) {
	uint8_t inspectionType = msg.getByte();
	if (inspectionType == INSPECT_NORMALOBJECT) {
		Position pos = msg.getPosition();
		g_game.playerInspectItem(player, pos);
	}
	else if (inspectionType == INSPECT_NPCTRADE || inspectionType == INSPECT_CYCLOPEDIA) {
		uint16_t itemId = msg.get<uint16_t>();
		uint16_t itemCount = msg.getByte();
		g_game.playerInspectItem(player, itemId, itemCount, (inspectionType == INSPECT_CYCLOPEDIA));
	}
}

void ProtocolGame::sendItemInspection(uint16_t itemId, uint8_t itemCount, const Item* item, bool cyclopedia) {
	NetworkMessage msg;
	msg.addByte(0x76);
	msg.addByte(0x00);
	msg.addByte(cyclopedia ? 0x01 : 0x00);
	msg.addByte(0x01);

	const ItemType& it = Item::items.getItemIdByClientId(itemId);

	if (item) {
		msg.addString(item->getName());
		AddItem(msg, item);
	}
	else {
		msg.addString(it.name);
		AddItem(msg, it.id, itemCount);
	}
	msg.addByte(0);

	auto descriptions = Item::getDescriptions(it, item);
	msg.addByte(descriptions.size());
	for (const auto& description : descriptions) {
		msg.addString(description.first);
		msg.addString(description.second);
	}
	writeToOutputBuffer(msg);
}

// Send methods
void ProtocolGame::sendOpenPrivateChannel(const std::string& receiver)
{
	NetworkMessage msg;
	msg.addByte(0xAD);
	msg.addString(receiver);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendChannelEvent(uint16_t channelId, const std::string& playerName, ChannelEvent_t channelEvent)
{
	NetworkMessage msg;
	msg.addByte(0xF3);
	msg.add<uint16_t>(channelId);
	msg.addString(playerName);
	msg.addByte(channelEvent);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendCreatureOutfit(const Creature* creature, const Outfit_t& outfit)
{
	if (!canSee(creature)) {
		return;
	}

	NetworkMessage msg;
	msg.addByte(0x8E);
	msg.add<uint32_t>(creature->getID());
	AddOutfit(msg, outfit);
	if (outfit.lookMount != 0) {
		msg.addByte(outfit.lookMountHead);
		msg.addByte(outfit.lookMountBody);
		msg.addByte(outfit.lookMountLegs);
		msg.addByte(outfit.lookMountFeet);
	}
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendCreatureWalkthrough(const Creature* creature, bool walkthrough)
{
	if (!canSee(creature)) {
		return;
	}

	NetworkMessage msg;
	msg.addByte(0x92);
	msg.add<uint32_t>(creature->getID());
	msg.addByte(walkthrough ? 0x00 : 0x01);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendCreatureShield(const Creature* creature)
{
	if (!canSee(creature)) {
		return;
	}

	NetworkMessage msg;
	msg.addByte(0x91);
	msg.add<uint32_t>(creature->getID());
	msg.addByte(player->getPartyShield(creature->getPlayer()));
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendCreatureSkull(const Creature* creature)
{
	if (!g_game.isWorldTypeSkull()) {
		return;
	}

	if (!canSee(creature)) {
		return;
	}

	NetworkMessage msg;
	msg.addByte(0x90);
	msg.add<uint32_t>(creature->getID());
	msg.addByte(player->getSkullClient(creature));
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendCreatureType(const Creature* creature, uint8_t creatureType)
{
	NetworkMessage msg;
	msg.addByte(0x95);
	msg.add<uint32_t>(creature->getID());
	if (version >= 1120) {
		if (creatureType == CREATURETYPE_SUMMON_OTHERS) {
			creatureType = CREATURETYPE_SUMMON_OWN;
		}
		msg.addByte(creatureType);
		if (creatureType == CREATURETYPE_SUMMON_OWN) {
			const Creature* master = creature->getMaster();
			if (master) {
				msg.add<uint32_t>(master->getID());
			} else {
				msg.add<uint32_t>(0);
			}
		}
	} else {
		msg.addByte(creatureType);
	}
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendCreatureHelpers(uint32_t creatureId, uint16_t helpers)
{
	if (version >= 1185) {
		return;
	}

	NetworkMessage msg;
	msg.addByte(0x94);
	msg.add<uint32_t>(creatureId);
	msg.add<uint16_t>(helpers);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendCreatureSquare(const Creature* creature, SquareColor_t color, uint8_t length)
{
	if (!canSee(creature)) {
		return;
	}

	NetworkMessage msg;
	msg.addByte(0x93);
	msg.add<uint32_t>(creature->getID());
	msg.addByte(length);
	msg.addByte(color);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendTutorial(uint8_t tutorialId)
{
	NetworkMessage msg;
	msg.addByte(0xDC);
	msg.addByte(tutorialId);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendAddMarker(const Position& pos, uint8_t markType, const std::string& desc)
{
	NetworkMessage msg;
	msg.addByte(0xDD);
	if (version >= 1200)
		msg.addByte(0);

	msg.addPosition(pos);
	msg.addByte(markType);
	msg.addString(desc);

	writeToOutputBuffer(msg);
}

void ProtocolGame::sendMapManage(uint8_t action)
{
	NetworkMessage msg;
	msg.addByte(0xDD);

	if (action == 9) {	
		msg.addByte(action);
	
		msg.add<uint64_t>(10000000);
		msg.addByte(20);
	
		msg.add<uint16_t>(4);
		msg.addByte(0);
		msg.add<uint64_t>(8188);
	
		msg.add<uint16_t>(27);
		msg.addByte(0);
		msg.add<uint64_t>(14100);
	
		msg.add<uint16_t>(16);
		msg.addByte(0);
		msg.add<uint64_t>(5001);
	
		msg.add<uint16_t>(0x5);
		msg.addByte(0);
		msg.add<uint64_t>(623);
	
		msg.add<uint16_t>(20);
		msg.addByte(0);
		msg.add<uint64_t>(10011);
	
		msg.add<uint16_t>(0x9);
		msg.addByte(0);
		msg.add<uint64_t>(6);
	
		msg.add<uint16_t>(0x3);
		msg.addByte(0);
		msg.add<uint64_t>(2456);
	
		msg.add<uint16_t>(22);
		msg.addByte(0);
		msg.add<uint64_t>(257900);
	
		msg.add<uint16_t>(11);
		msg.addByte(0);
		msg.add<uint64_t>(20708);
	
		msg.add<uint16_t>(19);
		msg.addByte(0);
		msg.add<uint64_t>(85808);
	
		msg.add<uint16_t>(17);
		msg.addByte(0);
		msg.add<uint64_t>(112008);
	
		msg.add<uint16_t>(0x7);
		msg.addByte(0);
		msg.add<uint64_t>(112712);
	
		msg.add<uint16_t>(23);
		msg.addByte(0);
		msg.add<uint64_t>(6680);
	
		msg.add<uint16_t>(0x1);
		msg.addByte(0);
		msg.add<uint64_t>(14);
	
		msg.add<uint16_t>(24);
		msg.addByte(0);
		msg.add<uint64_t>(430027);
	
		msg.add<uint16_t>(0x2);
		msg.addByte(0);
		msg.add<uint64_t>(180);
	
		msg.add<uint16_t>(25);
		msg.addByte(0);
		msg.add<uint64_t>(11662);
	
		msg.add<uint16_t>(355);
		msg.addByte(0);
		msg.add<uint64_t>(0);
	
		msg.add<uint16_t>(14);
		msg.addByte(0);
		msg.add<uint64_t>(192);
	
		msg.add<uint16_t>(0x8);
		msg.addByte(0);
		msg.add<uint64_t>(271101);
	} else {
		return;
	}
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendCyclopediaCharacterNoData(CyclopediaCharacterInfoType_t characterInfoType, uint8_t errorCode)
{
	NetworkMessage msg;
	msg.addByte(0xDA);
	msg.addByte(static_cast<uint8_t>(characterInfoType));
	msg.addByte(errorCode);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendCyclopediaCharacterBaseInformation() {
	NetworkMessage msg;
	msg.addByte(0xDA);
	msg.addByte(CYCLOPEDIA_CHARACTERINFO_BASEINFORMATION);
	msg.addByte(0x00);
	msg.addString(player->getName());
	msg.addString(player->getVocation()->getVocName());
	msg.add<uint16_t>(player->getLevel());
	AddOutfit(msg, player->getDefaultOutfit(), false);

	msg.addByte(0x00);  // hide stamina
	msg.addByte(0x00);  // enable store summary & character titles
	msg.addString("");  // character title
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendCyclopediaCharacterGeneralStats() {
	NetworkMessage msg;
	msg.addByte(0xDA);
	msg.addByte(CYCLOPEDIA_CHARACTERINFO_GENERALSTATS);
	msg.addByte(0x00);
	msg.add<uint64_t>(player->getExperience());
	msg.add<uint16_t>(player->getLevel());
	msg.addByte(player->getLevelPercent());
	// BaseXPGainRate
	msg.add<uint16_t>(100);
	// TournamentXPFactor
	msg.add<int32_t>(0);
	// LowLevelBonus
	msg.add<uint16_t>(0);
	// XPBoost
	msg.add<uint16_t>(0);
	// StaminaMultiplier(100=x1.0)
	msg.add<uint16_t>(100);
	// xpBoostRemainingTime
	msg.add<uint16_t>(0);
	// canBuyXpBoost
	msg.addByte(0x00);
	msg.add<uint16_t>(std::min<int32_t>(player->getHealth(), std::numeric_limits<uint16_t>::max()));
	msg.add<uint16_t>(std::min<int32_t>(player->getMaxHealth(), std::numeric_limits<uint16_t>::max()));
	msg.add<uint16_t>(std::min<int32_t>(player->getMana(), std::numeric_limits<uint16_t>::max()));
	msg.add<uint16_t>(std::min<int32_t>(player->getMaxMana(), std::numeric_limits<uint16_t>::max()));
	msg.addByte(player->getSoul());
	msg.add<uint16_t>(player->getStaminaMinutes());

	Condition* condition = player->getCondition(CONDITION_REGENERATION);
	msg.add<uint16_t>(condition ? condition->getTicks() / 1000 : 0x00);
	msg.add<uint16_t>(player->getOfflineTrainingTime() / 60 / 1000);
	msg.add<uint16_t>(player->getSpeed() / 2);
	msg.add<uint16_t>(player->getBaseSpeed() / 2);
	msg.add<uint32_t>(player->getCapacity());
	msg.add<uint32_t>(player->getCapacity());
	msg.add<uint32_t>(player->getFreeCapacity());
	msg.addByte(8);
	msg.addByte(1);
	msg.add<uint16_t>(player->getMagicLevel());
	msg.add<uint16_t>(player->getBaseMagicLevel());
	// loyalty bonus
	msg.add<uint16_t>(player->getBaseMagicLevel());
	msg.add<uint16_t>(player->getMagicLevelPercent() * 100);
	for (uint8_t i = SKILL_FIRST; i < SKILL_CRITICAL_HIT_CHANCE; ++i) {
		// check if all clients have the same hardcoded skill ids
		static const uint8_t HardcodedSkillIds[] = { 11, 9, 8, 10, 7, 6, 13 };
		msg.addByte(HardcodedSkillIds[i]);
		msg.add<uint16_t>(std::min<int32_t>(player->getSkillLevel(i), std::numeric_limits<uint16_t>::max()));
		msg.add<uint16_t>(player->getBaseSkill(i));
		// loyalty bonus
		msg.add<uint16_t>(player->getBaseSkill(i));
		msg.add<uint16_t>(player->getSkillPercent(i) * 100);
	}
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendCyclopediaCharacterCombatStats() {
	NetworkMessage msg;
	msg.addByte(0xDA);
	msg.addByte(CYCLOPEDIA_CHARACTERINFO_COMBATSTATS);
	msg.addByte(0x00);
	for (uint8_t i = SKILL_CRITICAL_HIT_CHANCE; i <= SKILL_LAST; ++i) {
		msg.add<uint16_t>(std::min<int32_t>(player->getSkillLevel(i), std::numeric_limits<uint16_t>::max()));
		msg.add<uint16_t>(0);
	}
	uint8_t haveBlesses = 0;
	uint8_t blessings = 8;
	for (uint8_t i = 1; i < blessings; ++i) {
		if (player->hasBlessing(i)) {
			++haveBlesses;
		}
	}
	msg.addByte(haveBlesses);
	msg.addByte(blessings);
	const Item* weapon = player->getWeapon();
	if (weapon) {
		const ItemType& it = Item::items[weapon->getID()];
		if (it.weaponType == WEAPON_WAND) {
			msg.add<uint16_t>(it.maxHitChance);
			msg.addByte(getCipbiaElement(it.combatType));
			msg.addByte(0);
			msg.addByte(CIPBIA_ELEMENTAL_UNDEFINED);
		}
		else if (it.weaponType == WEAPON_DISTANCE || it.weaponType == WEAPON_AMMO) {
			int32_t attackValue = weapon->getAttack();
			if (it.weaponType == WEAPON_AMMO) {
				const Item* weaponItem = player->getWeapon(true);
				if (weaponItem) {
					attackValue += weaponItem->getAttack();
				}
			}

			int32_t attackSkill = player->getSkillLevel(SKILL_DISTANCE);
			float attackFactor = player->getAttackFactor();
			int32_t maxDamage = static_cast<int32_t>(Weapons::getMaxWeaponDamage(player->getLevel(), attackSkill, attackValue, attackFactor, true) * player->getVocation()->distDamageMultiplier);
			if (it.abilities && it.abilities->elementType != COMBAT_NONE) {
				maxDamage += static_cast<int32_t>(Weapons::getMaxWeaponDamage(player->getLevel(), attackSkill, attackValue - weapon->getAttack() + it.abilities->elementDamage, attackFactor, true) * player->getVocation()->distDamageMultiplier);
			}
			msg.add<uint16_t>(maxDamage >> 1);
			msg.addByte(CIPBIA_ELEMENTAL_PHYSICAL);
			if (it.abilities && it.abilities->elementType != COMBAT_NONE) {
				msg.addByte(static_cast<uint32_t>(it.abilities->elementDamage) * 100 / attackValue);
				msg.addByte(getCipbiaElement(it.abilities->elementType));
			}
			else {
				msg.addByte(0);
				msg.addByte(CIPBIA_ELEMENTAL_UNDEFINED);
			}
		}
		else {
			int32_t attackValue = std::max<int32_t>(0, weapon->getAttack());
			int32_t attackSkill = player->getWeaponSkill(weapon);
			float attackFactor = player->getAttackFactor();
			int32_t maxDamage = static_cast<int32_t>(Weapons::getMaxWeaponDamage(player->getLevel(), attackSkill, attackValue, attackFactor, true) * player->getVocation()->meleeDamageMultiplier);
			if (it.abilities && it.abilities->elementType != COMBAT_NONE) {
				maxDamage += static_cast<int32_t>(Weapons::getMaxWeaponDamage(player->getLevel(), attackSkill, it.abilities->elementDamage, attackFactor, true) * player->getVocation()->meleeDamageMultiplier);
			}
			msg.add<uint16_t>(maxDamage >> 1);
			msg.addByte(CIPBIA_ELEMENTAL_PHYSICAL);
			if (it.abilities && it.abilities->elementType != COMBAT_NONE) {
				msg.addByte(static_cast<uint32_t>(it.abilities->elementDamage) * 100 / attackValue);
				msg.addByte(getCipbiaElement(it.abilities->elementType));
			}
			else {
				msg.addByte(0);
				msg.addByte(CIPBIA_ELEMENTAL_UNDEFINED);
			}
		}
	}
	else {
		float attackFactor = player->getAttackFactor();
		int32_t attackSkill = player->getSkillLevel(SKILL_FIST);
		int32_t attackValue = 7;

		int32_t maxDamage = Weapons::getMaxWeaponDamage(player->getLevel(), attackSkill, attackValue, attackFactor, true);
		msg.add<uint16_t>(maxDamage >> 1);
		msg.addByte(CIPBIA_ELEMENTAL_PHYSICAL);
		msg.addByte(0);
		msg.addByte(CIPBIA_ELEMENTAL_UNDEFINED);
	}
	msg.add<uint16_t>(player->getArmor());
	msg.add<uint16_t>(player->getDefense());

	uint8_t combats = 0;
	auto startCombats = msg.getBufferPosition();
	msg.skipBytes(1);

	alignas(16) int16_t absorbs[COMBAT_COUNT] = {};
	for (int32_t slot = CONST_SLOT_FIRST; slot <= CONST_SLOT_LAST; ++slot) {
		if (!player->isItemAbilityEnabled(static_cast<slots_t>(slot))) {
			continue;
		}

		Item* item = player->getInventoryItem(static_cast<slots_t>(slot));
		if (!item) {
			continue;
		}

		const ItemType& it = Item::items[item->getID()];
		if (!it.abilities) {
			continue;
		}

		if (COMBAT_COUNT == 12) {
			absorbs[0] += it.abilities->absorbPercent[0]; absorbs[1] += it.abilities->absorbPercent[1];
			absorbs[2] += it.abilities->absorbPercent[2]; absorbs[3] += it.abilities->absorbPercent[3];
			absorbs[4] += it.abilities->absorbPercent[4]; absorbs[5] += it.abilities->absorbPercent[5];
			absorbs[6] += it.abilities->absorbPercent[6]; absorbs[7] += it.abilities->absorbPercent[7];
			absorbs[8] += it.abilities->absorbPercent[8]; absorbs[9] += it.abilities->absorbPercent[9];
			absorbs[10] += it.abilities->absorbPercent[10]; absorbs[11] += it.abilities->absorbPercent[11];
		}
		else {
			for (size_t i = 0; i < COMBAT_COUNT; ++i) {
				absorbs[i] += it.abilities->absorbPercent[i];
			}
		}
	}

	static const Cipbia_Elementals_t cipbiaCombats[] = { CIPBIA_ELEMENTAL_PHYSICAL, CIPBIA_ELEMENTAL_ENERGY, CIPBIA_ELEMENTAL_EARTH, CIPBIA_ELEMENTAL_FIRE, CIPBIA_ELEMENTAL_UNDEFINED,
		CIPBIA_ELEMENTAL_LIFEDRAIN, CIPBIA_ELEMENTAL_UNDEFINED, CIPBIA_ELEMENTAL_HEALING, CIPBIA_ELEMENTAL_DROWN, CIPBIA_ELEMENTAL_ICE, CIPBIA_ELEMENTAL_HOLY, CIPBIA_ELEMENTAL_DEATH };
	for (size_t i = 0; i < COMBAT_COUNT; ++i) {
		if (absorbs[i] != 0) {
			msg.addByte(cipbiaCombats[i]);
			msg.addByte(std::max<int16_t>(-100, std::min<int16_t>(100, absorbs[i])));
			++combats;
		}
	}

	msg.setBufferPosition(startCombats);
	msg.addByte(combats);

	writeToOutputBuffer(msg);
}

void ProtocolGame::sendCyclopediaCharacterRecentDeaths(uint16_t page, uint16_t pages, const std::vector<RecentDeathEntry>& entries) {
	NetworkMessage msg;
	msg.addByte(0xDA);
	msg.addByte(CYCLOPEDIA_CHARACTERINFO_RECENTDEATHS);
	msg.addByte(0x00);
	msg.add<uint16_t>(page);
	msg.add<uint16_t>(pages);
	msg.add<uint16_t>(entries.size());
	for (const RecentDeathEntry& entry : entries) {
		msg.add<uint32_t>(entry.timestamp);
		msg.addString(entry.cause);
	}
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendCyclopediaCharacterRecentPvPKills(uint16_t page, uint16_t pages, const std::vector<RecentPvPKillEntry>& entries) {
	NetworkMessage msg;
	msg.addByte(0xDA);
	msg.addByte(CYCLOPEDIA_CHARACTERINFO_RECENTPVPKILLS);
	msg.addByte(0x00);
	msg.add<uint16_t>(page);
	msg.add<uint16_t>(pages);
	msg.add<uint16_t>(entries.size());
	for (const RecentPvPKillEntry& entry : entries) {
		msg.add<uint32_t>(entry.timestamp);
		msg.addString(entry.description);
		msg.addByte(entry.status);
	}
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendCyclopediaCharacterAchievements() {
	NetworkMessage msg;
	msg.addByte(0xDA);
	msg.addByte(CYCLOPEDIA_CHARACTERINFO_ACHIEVEMENTS);
	msg.addByte(0x00);
	msg.add<uint16_t>(0);
	msg.add<uint16_t>(0);
	msg.add<uint16_t>(0);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendCyclopediaCharacterItemSummary() {
	NetworkMessage msg;
	msg.addByte(0xDA);
	msg.addByte(CYCLOPEDIA_CHARACTERINFO_ITEMSUMMARY);
	msg.addByte(0x00);
	msg.add<uint16_t>(0);
	msg.add<uint16_t>(0);
	msg.add<uint16_t>(0);
	msg.add<uint16_t>(0);
	msg.add<uint16_t>(0);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendCyclopediaCharacterOutfitsMounts() {
	NetworkMessage msg;
	msg.addByte(0xDA);
	msg.addByte(CYCLOPEDIA_CHARACTERINFO_OUTFITSMOUNTS);
	msg.addByte(0x00);
	Outfit_t currentOutfit = player->getDefaultOutfit();

	uint16_t outfitSize = 0;
	auto startOutfits = msg.getBufferPosition();
	msg.skipBytes(2);

	const auto& outfits = Outfits::getInstance().getOutfits(player->getSex());
	for (const Outfit& outfit : outfits) {
		uint8_t addons;
		if (!player->getOutfitAddons(outfit, addons)) {
			continue;
		}
		const std::string from = outfit.from;
		++outfitSize;

		msg.add<uint16_t>(outfit.lookType);
		msg.addString(outfit.name);
		msg.addByte(addons);
		if (from == "store")
			msg.addByte(CYCLOPEDIA_CHARACTERINFO_OUTFITTYPE_STORE);
		else if (from == "quest")
			msg.addByte(CYCLOPEDIA_CHARACTERINFO_OUTFITTYPE_QUEST);
		else
			msg.addByte(CYCLOPEDIA_CHARACTERINFO_OUTFITTYPE_NONE);
		if (outfit.lookType == currentOutfit.lookType) {
			msg.add<uint32_t>(1000);
		}
		else {
			msg.add<uint32_t>(0);
		}
	}
	if (outfitSize > 0) {
		msg.addByte(currentOutfit.lookHead);
		msg.addByte(currentOutfit.lookBody);
		msg.addByte(currentOutfit.lookLegs);
		msg.addByte(currentOutfit.lookFeet);
	}

	uint16_t mountSize = 0;
	auto startMounts = msg.getBufferPosition();
	msg.skipBytes(2);
	for (const Mount& mount : g_game.mounts.getMounts()) {
		const std::string type = mount.type;
		if (player->hasMount(&mount)) {
			++mountSize;

			msg.add<uint16_t>(mount.clientId);
			msg.addString(mount.name);
			if (type == "store")
				msg.addByte(CYCLOPEDIA_CHARACTERINFO_OUTFITTYPE_STORE);
			else if (type == "quest")
				msg.addByte(CYCLOPEDIA_CHARACTERINFO_OUTFITTYPE_QUEST);
			else
				msg.addByte(CYCLOPEDIA_CHARACTERINFO_OUTFITTYPE_NONE);
			msg.add<uint32_t>(1000);
		}
	}
	if (mountSize > 0) {
		msg.addByte(currentOutfit.lookMountHead);
		msg.addByte(currentOutfit.lookMountBody);
		msg.addByte(currentOutfit.lookMountLegs);
		msg.addByte(currentOutfit.lookMountFeet);
	}

	uint16_t familiarsSize = 0;
	auto startFamiliars = msg.getBufferPosition();
	msg.skipBytes(2);
	const auto& familiars = Familiars::getInstance().getFamiliars(player->getVocationId());
	for (const Familiar& familiar : familiars) {
		const std::string type = familiar.type;
		if (!player->getFamiliar(familiar)) {
			continue;
		}
		++familiarsSize;
		msg.add<uint16_t>(familiar.lookType);
		msg.addString(familiar.name);
		if (type == "quest")
			msg.addByte(CYCLOPEDIA_CHARACTERINFO_OUTFITTYPE_QUEST);
		else
			msg.addByte(CYCLOPEDIA_CHARACTERINFO_OUTFITTYPE_NONE);
		msg.add<uint32_t>(0);
	}

	msg.setBufferPosition(startOutfits);
	msg.add<uint16_t>(outfitSize);
	msg.setBufferPosition(startMounts);
	msg.add<uint16_t>(mountSize);
	msg.setBufferPosition(startFamiliars);
	msg.add<uint16_t>(familiarsSize);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendCyclopediaCharacterStoreSummary() {
	NetworkMessage msg;
	msg.addByte(0xDA);
	msg.addByte(CYCLOPEDIA_CHARACTERINFO_STORESUMMARY);
	msg.addByte(0x00);
	msg.add<uint32_t>(0);
	msg.add<uint32_t>(0);
	msg.addByte(0x00);
	msg.addByte(0x00);
	msg.addByte(0x00);
	msg.addByte(0x00);
	msg.addByte(0x00);
	msg.addByte(0x00);
	msg.addByte(0x00);
	msg.addByte(0x00);
	msg.add<uint16_t>(0);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendCyclopediaCharacterInspection() {
	NetworkMessage msg;
	msg.addByte(0xDA);
	msg.addByte(CYCLOPEDIA_CHARACTERINFO_INSPECTION);
	msg.addByte(0x00);
	uint8_t inventoryItems = 0;
	auto startInventory = msg.getBufferPosition();
	msg.skipBytes(1);
	for (std::underlying_type<slots_t>::type slot = CONST_SLOT_FIRST; slot <= CONST_SLOT_LAST; slot++) {
		Item* inventoryItem = player->getInventoryItem(static_cast<slots_t>(slot));
		if (inventoryItem) {
			++inventoryItems;

			msg.addByte(slot);
			msg.addString(inventoryItem->getName());
			AddItem(msg, inventoryItem);
			msg.addByte(0);

			auto descriptions = Item::getDescriptions(Item::items[inventoryItem->getID()], inventoryItem);
			msg.addByte(descriptions.size());
			for (const auto& description : descriptions) {
				msg.addString(description.first);
				msg.addString(description.second);
			}
		}
	}
	msg.addString(player->getName());
	AddOutfit(msg, player->getDefaultOutfit(), false);

	msg.addByte(3);
	msg.addString("Level");
	msg.addString(std::to_string(player->getLevel()));
	msg.addString("Vocation");
	msg.addString(player->getVocation()->getVocName());
	msg.addString("Outfit");

	const Outfit* outfit = Outfits::getInstance().getOutfitByLookType(player->getSex(),
		player->getDefaultOutfit().lookType);
	if (outfit) {
		msg.addString(outfit->name);
	}
	else {
		msg.addString("unknown");
	}
	msg.setBufferPosition(startInventory);
	msg.addByte(inventoryItems);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendCyclopediaCharacterBadges() {
	NetworkMessage msg;
	msg.addByte(0xDA);
	msg.addByte(CYCLOPEDIA_CHARACTERINFO_BADGES);
	msg.addByte(0x00);
	// enable badges
	msg.addByte(0x00);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendCyclopediaCharacterTitles() {
	NetworkMessage msg;
	msg.addByte(0xDA);
	msg.addByte(CYCLOPEDIA_CHARACTERINFO_TITLES);
	msg.addByte(0x00);
	msg.addByte(0x00);
	msg.addByte(0x00);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendTournamentLeaderboard() {
	NetworkMessage msg;
	msg.addByte(0xC5);
	msg.addByte(0);
	msg.addByte(0x01);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendReLoginWindow(uint8_t unfairFightReduction)
{
	NetworkMessage msg;
	msg.addByte(0x28);
	msg.addByte(0x00);
	msg.addByte(unfairFightReduction);
	if (version >= 1120) {
		msg.addByte(0x00); // use death redemption (boolean)
	}
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendTextMessage(const TextMessage& message)
{
	NetworkMessage msg;
	msg.addByte(0xB4);
	msg.addByte(message.type);
	switch (message.type) {
		case MESSAGE_DAMAGE_DEALT:
		case MESSAGE_DAMAGE_RECEIVED:
		case MESSAGE_DAMAGE_OTHERS: {
			msg.addPosition(message.position);
			msg.add<uint32_t>(message.primary.value);
			msg.addByte(message.primary.color);
			msg.add<uint32_t>(message.secondary.value);
			msg.addByte(message.secondary.color);
			break;
		}
		case MESSAGE_HEALED:
		case MESSAGE_HEALED_OTHERS:
		case MESSAGE_EXPERIENCE:
		case MESSAGE_EXPERIENCE_OTHERS: {
			msg.addPosition(message.position);
			msg.add<uint32_t>(message.primary.value);
			msg.addByte(message.primary.color);
			break;
		}
		case MESSAGE_GUILD:
		case MESSAGE_PARTY_MANAGEMENT:
		case MESSAGE_PARTY:
			msg.add<uint16_t>(message.channelId);
			break;
		default: {
			break;
		}
	}
	msg.addString(message.text);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendClosePrivate(uint16_t channelId)
{
	NetworkMessage msg;
	msg.addByte(0xB3);
	msg.add<uint16_t>(channelId);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendCreatePrivateChannel(uint16_t channelId, const std::string& channelName)
{
	NetworkMessage msg;
	msg.addByte(0xB2);
	msg.add<uint16_t>(channelId);
	msg.addString(channelName);
	msg.add<uint16_t>(0x01);
	msg.addString(player->getName());
	msg.add<uint16_t>(0x00);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendChannelsDialog()
{
	NetworkMessage msg;
	msg.addByte(0xAB);

	const ChannelList& list = g_chat->getChannelList(*player);
	msg.addByte(list.size());
	for (ChatChannel* channel : list) {
		msg.add<uint16_t>(channel->getId());
		msg.addString(channel->getName());
	}

	writeToOutputBuffer(msg);
}

void ProtocolGame::sendIcons(uint16_t icons)
{
	NetworkMessage msg;
	msg.addByte(0xA2);
	if (version >= 1140) { // TODO: verify compatibility of the new icon range ( 16-31 )
		msg.add<uint32_t>(icons);
	} else {
		msg.add<uint16_t>(icons);
	}

	writeToOutputBuffer(msg);
}

void ProtocolGame::sendChannelMessage(const std::string& author, const std::string& text, SpeakClasses type, uint16_t channel)
{
	NetworkMessage msg;
	msg.addByte(0xAA);
	msg.add<uint32_t>(0x00);
	msg.addString(author);
	msg.add<uint16_t>(0x00);
	msg.addByte(type);
	msg.add<uint16_t>(channel);
	msg.addString(text);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendUnjustifiedPoints(const uint8_t& dayProgress, const uint8_t& dayLeft, const uint8_t& weekProgress, const uint8_t& weekLeft, const uint8_t& monthProgress, const uint8_t& monthLeft, const uint8_t& skullDuration)
{
	NetworkMessage msg;
	msg.addByte(0xB7);
	msg.addByte(dayProgress);
	msg.addByte(dayLeft);
	msg.addByte(weekProgress);
	msg.addByte(weekLeft);
	msg.addByte(monthProgress);
	msg.addByte(monthLeft);
	msg.addByte(skullDuration);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendShop(Npc* npc, const ShopInfoList& itemList)
{
	NetworkMessage msg;
	msg.addByte(0x7A);
	msg.addString(npc->getName());
	// moeda de troca?
	if (version >= 1220)
		msg.addItemId(ITEM_GOLD_COIN);
		msg.addString(std::string()); // ??

	uint16_t itemsToSend = std::min<size_t>(itemList.size(), std::numeric_limits<uint16_t>::max());
	msg.add<uint16_t>(itemsToSend);

	uint16_t i = 0;
	for (auto it = itemList.begin(); i < itemsToSend; ++it, ++i) {
		AddShopItem(msg, *it);
	}

	writeToOutputBuffer(msg);
}

void ProtocolGame::sendRestingAreaIcon(bool activate/*=false*/, bool activeResting/*=false*/) {
	NetworkMessage msg;
	msg.addByte(0xA9);

	uint8_t b1=0, b2=0;
	std::ostringstream ss;
	ss << "";
	if(activate) {
		b1=1;
		ss << "Within ";

		if(activeResting){
			b2 =1;
			ss << "Active ";
		}
		else{
			b2 = 0;
		}
		ss << "Resting Area";
	}

	msg.addByte(b1);
	msg.addByte(b2);
	msg.addString(ss.str());
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendCloseShop()
{
	NetworkMessage msg;
	msg.addByte(0x7C);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendClientCheck()
{
	NetworkMessage msg;
	msg.addByte(0x63);
	msg.add<uint32_t>(1);
	msg.addByte(1);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendGameNews()
{
	NetworkMessage msg;
	msg.addByte(0x98);
	msg.add<uint32_t>(1); // unknown
	msg.addByte(1); //(0 = open | 1 = highlight)
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendResourceBalance(uint64_t money, uint64_t bank)
{
	NetworkMessage msg;
	msg.addByte(0xEE);
	msg.addByte(0x00);
	msg.add<uint64_t>(bank);
	msg.addByte(0xEE);
	msg.addByte(0x01);
	msg.add<uint64_t>(money);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendSaleItemList(const std::vector<ShopInfo>& shop, const std::map<uint32_t, uint32_t>& inventoryMap)
{
	//Since we already have full inventory map we shouldn't call getMoney here - it is simply wasting cpu power
	uint64_t playerMoney = 0;
	auto it = inventoryMap.find(ITEM_CRYSTAL_COIN);
	if (it != inventoryMap.end()) {
		playerMoney += static_cast<uint64_t>(it->second) * 10000;
	}
	it = inventoryMap.find(ITEM_PLATINUM_COIN);
	if (it != inventoryMap.end()) {
		playerMoney += static_cast<uint64_t>(it->second) * 100;
	}
	it = inventoryMap.find(ITEM_GOLD_COIN);
	if (it != inventoryMap.end()) {
		playerMoney += static_cast<uint64_t>(it->second);
	}
	NetworkMessage msg;
	msg.addByte(0xEE);
	msg.addByte(0x00);
	msg.add<uint64_t>(player->getBankBalance());
	msg.addByte(0xEE);
	msg.addByte(0x01);
	msg.add<uint64_t>(playerMoney);
	msg.addByte(0x7B);
	msg.add<uint64_t>(playerMoney);

	uint8_t itemsToSend = 0;
	auto msgPosition = msg.getBufferPosition();
	msg.skipBytes(1);

	for (const ShopInfo& shopInfo : shop) {
		if (shopInfo.sellPrice == 0) {
			continue;
		}

		uint32_t index = static_cast<uint32_t>(shopInfo.itemId);
		if (Item::items[shopInfo.itemId].isFluidContainer()) {
			index |= (static_cast<uint32_t>(shopInfo.subType) << 16);
		}

		it = inventoryMap.find(index);
		if (it != inventoryMap.end()) {
			msg.addItemId(shopInfo.itemId);
			msg.addByte(std::min<uint32_t>(it->second, std::numeric_limits<uint8_t>::max()));
			if (++itemsToSend >= 0xFF) {
				break;
			}
		}
	}
	msg.setBufferPosition(msgPosition);
	msg.addByte(itemsToSend);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendMarketEnter(uint32_t depotId)
{
	NetworkMessage msg;
	msg.addByte(0xF6);

	msg.addByte(std::min<uint32_t>(IOMarket::getPlayerOfferCount(player->getGUID()), std::numeric_limits<uint8_t>::max()));

	DepotLocker* depotLocker = player->getDepotLocker(depotId);
	if (!depotLocker) {
		msg.add<uint16_t>(0x00);
		writeToOutputBuffer(msg);
		return;
	}

	player->setInMarket(true);

	std::map<uint16_t, uint32_t> depotItems;
	std::forward_list<Container*> containerList{depotLocker};

	do {
		Container* container = containerList.front();
		containerList.pop_front();

		for (Item* item : container->getItemList()) {
			Container* c = item->getContainer();
			if (c && !c->empty()) {
				containerList.push_front(c);
				continue;
			}

			const ItemType& itemType = Item::items[item->getID()];
			if (itemType.wareId == 0) {
				continue;
			}

			if (c && (!itemType.isContainer() || c->capacity() != itemType.maxItems)) {
				continue;
			}

			if (!item->hasMarketAttributes()) {
				continue;
			}

			depotItems[itemType.wareId] += Item::countByType(item, -1);
		}
	} while (!containerList.empty());

	uint16_t itemsToSend = std::min<size_t>(depotItems.size(), std::numeric_limits<uint16_t>::max());
	msg.add<uint16_t>(itemsToSend);

	uint16_t i = 0;
	for (std::map<uint16_t, uint32_t>::const_iterator it = depotItems.begin(); i < itemsToSend; ++it, ++i) {
		msg.add<uint16_t>(it->first);
		msg.add<uint16_t>(std::min<uint32_t>(0xFFFF, it->second));
	}

	writeToOutputBuffer(msg);

	updateCoinBalance();
	sendResourceBalance(player->getMoney(), player->getBankBalance());
}

void ProtocolGame::sendMarketLeave()
{
	NetworkMessage msg;
	msg.addByte(0xF7);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendMarketBrowseItem(uint16_t itemId, const MarketOfferList& buyOffers, const MarketOfferList& sellOffers)
{
	NetworkMessage msg;

	msg.addByte(0xF9);
	msg.addItemId(itemId);

	msg.add<uint32_t>(buyOffers.size());
	for (const MarketOffer& offer : buyOffers) {
		msg.add<uint32_t>(offer.timestamp);
		msg.add<uint16_t>(offer.counter);
		msg.add<uint16_t>(offer.amount);
		msg.add<uint32_t>(offer.price);
		msg.addString(offer.playerName);
	}

	msg.add<uint32_t>(sellOffers.size());
	for (const MarketOffer& offer : sellOffers) {
		msg.add<uint32_t>(offer.timestamp);
		msg.add<uint16_t>(offer.counter);
		msg.add<uint16_t>(offer.amount);
		msg.add<uint32_t>(offer.price);
		msg.addString(offer.playerName);
	}

	updateCoinBalance();
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendMarketAcceptOffer(const MarketOfferEx& offer)
{
	NetworkMessage msg;
	msg.addByte(0xF9);
	msg.addItemId(offer.itemId);

	if (offer.type == MARKETACTION_BUY) {
		msg.add<uint32_t>(0x01);
		msg.add<uint32_t>(offer.timestamp);
		msg.add<uint16_t>(offer.counter);
		msg.add<uint16_t>(offer.amount);
		msg.add<uint32_t>(offer.price);
		msg.addString(offer.playerName);
		msg.add<uint32_t>(0x00);
	} else {
		msg.add<uint32_t>(0x00);
		msg.add<uint32_t>(0x01);
		msg.add<uint32_t>(offer.timestamp);
		msg.add<uint16_t>(offer.counter);
		msg.add<uint16_t>(offer.amount);
		msg.add<uint32_t>(offer.price);
		msg.addString(offer.playerName);
	}

	writeToOutputBuffer(msg);
}

void ProtocolGame::sendMarketBrowseOwnOffers(const MarketOfferList& buyOffers, const MarketOfferList& sellOffers)
{
	NetworkMessage msg;
	msg.addByte(0xF9);
	msg.add<uint16_t>(MARKETREQUEST_OWN_OFFERS);

	msg.add<uint32_t>(buyOffers.size());
	for (const MarketOffer& offer : buyOffers) {
		msg.add<uint32_t>(offer.timestamp);
		msg.add<uint16_t>(offer.counter);
		msg.addItemId(offer.itemId);
		msg.add<uint16_t>(offer.amount);
		msg.add<uint32_t>(offer.price);
	}

	msg.add<uint32_t>(sellOffers.size());
	for (const MarketOffer& offer : sellOffers) {
		msg.add<uint32_t>(offer.timestamp);
		msg.add<uint16_t>(offer.counter);
		msg.addItemId(offer.itemId);
		msg.add<uint16_t>(offer.amount);
		msg.add<uint32_t>(offer.price);
	}

	writeToOutputBuffer(msg);
}

void ProtocolGame::sendMarketCancelOffer(const MarketOfferEx& offer)
{
	NetworkMessage msg;
	msg.addByte(0xF9);
	msg.add<uint16_t>(MARKETREQUEST_OWN_OFFERS);

	if (offer.type == MARKETACTION_BUY) {
		msg.add<uint32_t>(0x01);
		msg.add<uint32_t>(offer.timestamp);
		msg.add<uint16_t>(offer.counter);
		msg.addItemId(offer.itemId);
		msg.add<uint16_t>(offer.amount);
		msg.add<uint32_t>(offer.price);
		msg.add<uint32_t>(0x00);
	} else {
		msg.add<uint32_t>(0x00);
		msg.add<uint32_t>(0x01);
		msg.add<uint32_t>(offer.timestamp);
		msg.add<uint16_t>(offer.counter);
		msg.addItemId(offer.itemId);
		msg.add<uint16_t>(offer.amount);
		msg.add<uint32_t>(offer.price);
	}

	writeToOutputBuffer(msg);
}

void ProtocolGame::sendMarketBrowseOwnHistory(const HistoryMarketOfferList& buyOffers, const HistoryMarketOfferList& sellOffers)
{
	uint32_t i = 0;
	std::map<uint32_t, uint16_t> counterMap;
	uint32_t buyOffersToSend = std::min<uint32_t>(buyOffers.size(), 810 + std::max<int32_t>(0, 810 - sellOffers.size()));
	uint32_t sellOffersToSend = std::min<uint32_t>(sellOffers.size(), 810 + std::max<int32_t>(0, 810 - buyOffers.size()));

	NetworkMessage msg;
	msg.addByte(0xF9);
	msg.add<uint16_t>(MARKETREQUEST_OWN_HISTORY);

	msg.add<uint32_t>(buyOffersToSend);
	for (auto it = buyOffers.begin(); i < buyOffersToSend; ++it, ++i) {
		msg.add<uint32_t>(it->timestamp);
		msg.add<uint16_t>(counterMap[it->timestamp]++);
		msg.addItemId(it->itemId);
		msg.add<uint16_t>(it->amount);
		msg.add<uint32_t>(it->price);
		msg.addByte(it->state);
	}

	counterMap.clear();
	i = 0;

	msg.add<uint32_t>(sellOffersToSend);
	for (auto it = sellOffers.begin(); i < sellOffersToSend; ++it, ++i) {
		msg.add<uint32_t>(it->timestamp);
		msg.add<uint16_t>(counterMap[it->timestamp]++);
		msg.addItemId(it->itemId);
		msg.add<uint16_t>(it->amount);
		msg.add<uint32_t>(it->price);
		msg.addByte(it->state);
	}

	writeToOutputBuffer(msg);
}

void ProtocolGame::sendMarketDetail(uint16_t itemId)
{
	NetworkMessage msg;
	msg.addByte(0xF8);
	msg.addItemId(itemId);

	const ItemType& it = Item::items[itemId];
	if (it.armor != 0) {
		msg.addString(std::to_string(it.armor));
	} else {
		msg.add<uint16_t>(0x00);
	}

	if (it.attack != 0) {
		// TODO: chance to hit, range
		// example:
		// "attack +x, chance to hit +y%, z fields"
		if (it.abilities && it.abilities->elementType != COMBAT_NONE && it.abilities->elementDamage != 0) {
			std::ostringstream ss;
			ss << it.attack << " physical +" << it.abilities->elementDamage << ' ' << getCombatName(it.abilities->elementType);
			msg.addString(ss.str());
		} else {
			msg.addString(std::to_string(it.attack));
		}
	} else {
		msg.add<uint16_t>(0x00);
	}

	if (it.isContainer()) {
		msg.addString(std::to_string(it.maxItems));
	} else {
		msg.add<uint16_t>(0x00);
	}

	if (it.defense != 0) {
		if (it.extraDefense != 0) {
			std::ostringstream ss;
			ss << it.defense << ' ' << std::showpos << it.extraDefense << std::noshowpos;
			msg.addString(ss.str());
		} else {
			msg.addString(std::to_string(it.defense));
		}
	} else {
		msg.add<uint16_t>(0x00);
	}

	if (!it.description.empty()) {
		const std::string& descr = it.description;
		if (descr.back() == '.') {
			msg.addString(std::string(descr, 0, descr.length() - 1));
		} else {
			msg.addString(descr);
		}
	} else {
		msg.add<uint16_t>(0x00);
	}

	if (it.decayTime != 0) {
		std::ostringstream ss;
		ss << it.decayTime << " seconds";
		msg.addString(ss.str());
	} else {
		msg.add<uint16_t>(0x00);
	}

	if (it.abilities) {
		std::ostringstream ss;
		bool separator = false;

		for (size_t i = 0; i < COMBAT_COUNT; ++i) {
			if (it.abilities->absorbPercent[i] == 0) {
				continue;
			}

			if (separator) {
				ss << ", ";
			} else {
				separator = true;
			}

			ss << getCombatName(indexToCombatType(i)) << ' ' << std::showpos << it.abilities->absorbPercent[i] << std::noshowpos << '%';
		}

		msg.addString(ss.str());
	} else {
		msg.add<uint16_t>(0x00);
	}

	if (it.minReqLevel != 0) {
		msg.addString(std::to_string(it.minReqLevel));
	} else {
		msg.add<uint16_t>(0x00);
	}

	if (it.minReqMagicLevel != 0) {
		msg.addString(std::to_string(it.minReqMagicLevel));
	} else {
		msg.add<uint16_t>(0x00);
	}

	msg.addString(it.vocationString);

	msg.addString(it.runeSpellName);

	if (it.abilities) {
		std::ostringstream ss;
		bool separator = false;

		for (uint8_t i = SKILL_FIRST; i <= SKILL_FISHING; i++) {
			if (!it.abilities->skills[i]) {
				continue;
			}

			if (separator) {
				ss << ", ";
			} else {
				separator = true;
			}

			ss << getSkillName(i) << ' ' << std::showpos << it.abilities->skills[i] << std::noshowpos;
		}

		for (uint8_t i = SKILL_CRITICAL_HIT_CHANCE; i <= SKILL_LAST; i++) {
			if (!it.abilities->skills[i]) {
				continue;
			}

			if (separator) {
				ss << ", ";
			}
			else {
				separator = true;
			}

			ss << getSkillName(i) << ' ' << std::showpos << it.abilities->skills[i] << std::noshowpos << '%';
		}

		if (it.abilities->stats[STAT_MAGICPOINTS] != 0) {
			if (separator) {
				ss << ", ";
			} else {
				separator = true;
			}

			ss << "magic level " << std::showpos << it.abilities->stats[STAT_MAGICPOINTS] << std::noshowpos;
		}

		if (it.abilities->speed != 0) {
			if (separator) {
				ss << ", ";
			}

			ss << "speed " << std::showpos << (it.abilities->speed >> 1) << std::noshowpos;
		}

		msg.addString(ss.str());
	} else {
		msg.add<uint16_t>(0x00);
	}

	if (it.charges != 0) {
		msg.addString(std::to_string(it.charges));
	} else {
		msg.add<uint16_t>(0x00);
	}

	std::string weaponName = getWeaponName(it.weaponType);

	if (it.slotPosition & SLOTP_TWO_HAND) {
		if (!weaponName.empty()) {
			weaponName += ", two-handed";
		} else {
			weaponName = "two-handed";
		}
	}

	msg.addString(weaponName);

	if (it.weight != 0) {
		std::ostringstream ss;
		if (it.weight < 10) {
			ss << "0.0" << it.weight;
		} else if (it.weight < 100) {
			ss << "0." << it.weight;
		} else {
			std::string weightString = std::to_string(it.weight);
			weightString.insert(weightString.end() - 2, '.');
			ss << weightString;
		}
		ss << " oz";
		msg.addString(ss.str());
	} else {
		msg.add<uint16_t>(0x00);
	}

	if (version > 1099) {
		uint8_t slot = Item::items[itemId].imbuingSlots;
		if(slot > 0) {
			msg.addString(std::to_string(slot));
		} else {
			msg.add<uint16_t>(0x00);
		}
	}

	MarketStatistics* statistics = IOMarket::getInstance().getPurchaseStatistics(itemId);
	if (statistics) {
		msg.addByte(0x01);
		msg.add<uint32_t>(statistics->numTransactions);
		msg.add<uint32_t>(std::min<uint64_t>(std::numeric_limits<uint32_t>::max(), statistics->totalPrice));
		msg.add<uint32_t>(statistics->highestPrice);
		msg.add<uint32_t>(statistics->lowestPrice);
	} else {
		msg.addByte(0x00);
	}

	statistics = IOMarket::getInstance().getSaleStatistics(itemId);
	if (statistics) {
		msg.addByte(0x01);
		msg.add<uint32_t>(statistics->numTransactions);
		msg.add<uint32_t>(std::min<uint64_t>(std::numeric_limits<uint32_t>::max(), statistics->totalPrice));
		msg.add<uint32_t>(statistics->highestPrice);
		msg.add<uint32_t>(statistics->lowestPrice);
	} else {
		msg.addByte(0x00);
	}

	writeToOutputBuffer(msg);
}

void ProtocolGame::sendItemDetail(uint16_t itemCID)
{
	NetworkMessage msg;
	msg.addByte(0x76);

	const ItemType& it = Item::items.getItemIdByClientId(itemCID);
	msg.addByte(0x00); // ??
	if(version >= 1220) {
		msg.addByte(0x01);
	}

	msg.addByte(0x01); // name
	msg.addString(it.name);

	msg.add<uint16_t>(itemCID);
	if (it.stackable || it.isFluidContainer()) {
		msg.addByte(0x01);
	} else if (it.isContainer()) {
		msg.addByte(0x00);
	}
	if (it.isAnimation) {
		msg.addByte(0xFE);
	}
	msg.addByte(0x00);

	uint8_t count = 1;
	bool hasCombat = false;
	bool hasSkill = false;
	if (!it.isRune()) {
		if (it.armor != 0) {
			count++;
		}
		if (it.attack != 0) {
			count++;
		}	
		if (it.defense != 0) {
			count++;
		}

		if (it.abilities) {
			for (uint8_t i = SKILL_FIRST; i <= SKILL_FISHING; i++) {
				if (!it.abilities->skills[i]) {
					continue;
				}

				if (hasSkill) {
					break;
				}
				hasSkill = true;
				count++;
			}

			for (uint8_t i = SKILL_CRITICAL_HIT_CHANCE; i <= SKILL_LAST; i++) {
				if (!it.abilities->skills[i]) {
					continue;
				}

				if (hasSkill) {
					break;
				}
				hasSkill = true;
				count++;
			}

			if (it.abilities->stats[STAT_MAGICPOINTS] != 0) {
				if (!hasSkill) {
					hasSkill = true;
					count++;
				}
			}

			if (it.abilities->speed != 0) {
				if (!hasSkill) {
					hasSkill = true;
					count++;
				}
			}
		}

		if (it.abilities) {
			for (size_t i = 0; i < COMBAT_COUNT; ++i) {
				if (it.abilities->absorbPercent[i] == 0) {
					continue;
				}

				if (hasCombat) {
					break;
				}
				hasCombat = true;
				count++;

			}
		}

		if(it.imbuingSlots > 0) {
			count++;
		}
		if (!it.description.empty()) {
			count++;
		}
	} else {
		count = 0x05;
	}

	if(!it.vocationString.empty()) {
		count++;
	}

	msg.addByte(count);
	if (!it.isRune()) {
		if (it.armor != 0) {
			msg.addString("Armor");
			msg.addString(std::to_string(it.armor));
		}
		if (it.attack != 0) {
			msg.addString("Attack");
			msg.addString(std::to_string(it.attack));
		}	
		if (it.defense != 0) {
			msg.addString("Defense");
			if (it.extraDefense != 0) {
				std::ostringstream ss;
				ss << it.defense << ' ' << std::showpos << it.extraDefense << std::noshowpos;
				msg.addString(ss.str());
			} else {
				msg.addString(std::to_string(it.defense));
			}
			
		}
		if (it.abilities && hasSkill) {
			std::ostringstream ss;
			bool separator = false;
			for (uint8_t i = SKILL_FIRST; i <= SKILL_FISHING; i++) {
				if (!it.abilities->skills[i]) {
					continue;
				}

				if (separator) {
					ss << ", ";
				} else {
					separator = true;
				}

				ss << getSkillName(i) << ' ' << std::showpos << it.abilities->skills[i] << std::noshowpos;
			}

			for (uint8_t i = SKILL_CRITICAL_HIT_CHANCE; i <= SKILL_LAST; i++) {
				if (!it.abilities->skills[i]) {
					continue;
				}

				if (separator) {
					ss << ", ";
				} else {
					separator = true;
				}

				ss << getSkillName(i) << ' ' << std::showpos << it.abilities->skills[i] << std::noshowpos << '%';
			}

			if (it.abilities->stats[STAT_MAGICPOINTS] != 0) {
				if (separator) {
					ss << ", ";
				}
				separator = true;
				ss << "magic level " << std::showpos << it.abilities->stats[STAT_MAGICPOINTS] << std::noshowpos;
			}

			if (it.abilities->speed != 0) {
				if (separator) {
					ss << ", ";
				}
				ss << "speed " << std::showpos << (it.abilities->speed >> 1) << std::noshowpos;
			}
			msg.addString("Skills");
			msg.addString(ss.str());
		}

		if (it.abilities && hasCombat) {
			std::ostringstream ss;
			bool separator = false;
			for (size_t i = 0; i < COMBAT_COUNT; ++i) {
				if (it.abilities->absorbPercent[i] == 0) {
					continue;
				}
				if (separator) {
					ss << ", ";
				} else {
					separator = true;
				}
				ss << getCombatName(indexToCombatType(i)) << ' ' << std::showpos << it.abilities->absorbPercent[i] << std::noshowpos << '%';
			}
			msg.addString("Protection");
			msg.addString(ss.str());
		}

		if(it.imbuingSlots > 0) {
			msg.addString("Imbuement slots");
			msg.addString(std::to_string(it.imbuingSlots));
		}

		if(!it.vocationString.empty()) {
			msg.addString("Professions");
			msg.addString(it.vocationString);
		}

		if (!it.description.empty()) {
			msg.addString("Description");
			const std::string& descr = it.description;
			if (descr.back() == '.') {
				msg.addString(std::string(descr, 0, descr.length() - 1));
			} else {
				msg.addString(descr);
			}
		}
	} else {
		msg.addString("Spell");
		if(it.runeSpellName.empty()) {
			msg.add<uint16_t>(0x00);
		} else {
			msg.addString(it.runeSpellName);
		}

		msg.addString("Required Level");
		msg.addString(std::to_string(it.runeLevel));

		msg.addString("Required Magic Level");
		msg.addString(std::to_string(it.runeMagLevel));

		if(!it.vocationString.empty()) {
			msg.addString("Professions");
			msg.addString(it.vocationString);
		}
	}

	msg.addString(it.stackable ? "Total Weight" : "Weight");
	if (it.weight != 0) {
		std::ostringstream ss;
		if (it.weight < 10) {
			ss << "0.0" << it.weight;
		} else if (it.weight < 100) {
			ss << "0." << it.weight;
		} else {
			std::string weightString = std::to_string(it.weight);
			weightString.insert(weightString.end() - 2, '.');
			ss << weightString;
		}
		ss << " oz";
		msg.addString(ss.str());
	} else {
		msg.addString("0.00 oz");
	}

	if (it.isRune()){
		msg.addString("Tradeable");
		msg.addString("Yes");
	}

	writeToOutputBuffer(msg);
}

void ProtocolGame::sendCoinBalance() {
	NetworkMessage msg;
	msg.addByte(0xF2); // updating balance
	msg.addByte(0x01);

	msg.addByte(0xDF); // coins balance
	msg.addByte(0x01);

	msg.add<uint32_t>(player->getCoinBalance(COIN_TYPE_DEFAULT)); //total coins
	msg.add<uint32_t>(player->getCoinBalance(COIN_TYPE_TRANSFERABLE)); //transferable coins
	if (version >= 1251)
		msg.add<uint32_t>(player->getCoinBalance(COIN_TYPE_RESERVED)); // Reserved Auction Coins
	if (version >= 1220)
		msg.add<uint32_t>(player->getCoinBalance(COIN_TYPE_TOURNAMENT)); //transferable coins

	writeToOutputBuffer(msg);
}

void ProtocolGame::updateCoinBalance() {
	NetworkMessage msg;
	msg.addByte(0xF2);
	msg.addByte(0x00);

	writeToOutputBuffer(msg);

	g_dispatcher.addTask(
		createTask(std::bind([](uint32_t playerId) {
			Player* player = g_game.getPlayerByID(playerId);
			if (player != nullptr) {
				auto coinBalance = IOAccount::getCoinBalance(player->getAccount());
				auto tournamentCoinBalance = IOAccount::getCoinBalance(player->getAccount(), COIN_TYPE_TOURNAMENT);
				player->coinBalance = coinBalance;
				player->tournamentCoinBalance = tournamentCoinBalance;

				player->sendCoinBalance();
			}
	}, player->getID()))
	);
}

void ProtocolGame::sendQuestTracker()
{
	NetworkMessage msg;
	msg.addByte(0xD0); // byte quest tracker
	msg.addByte(1); // send quests of quest log ??
	msg.add<uint16_t>(1); // unknown
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendQuestLog()
{
	NetworkMessage msg;
	msg.addByte(0xF0);
	msg.add<uint16_t>(g_game.quests.getQuestsCount(player));

	for (const Quest& quest : g_game.quests.getQuests()) {
		if (quest.isStarted(player)) {
			msg.add<uint16_t>(quest.getID());
			msg.addString(quest.getName());
			msg.addByte(quest.isCompleted(player));
		}
	}

	writeToOutputBuffer(msg);
}

void ProtocolGame::sendQuestLine(const Quest* quest)
{
	NetworkMessage msg;
	msg.addByte(0xF1);
	msg.add<uint16_t>(quest->getID());
	msg.addByte(quest->getMissionsCount(player));

	for (const Mission& mission : quest->getMissions()) {
		if (mission.isStarted(player)) {
			if (player->getProtocolVersion() >= 1120){
				msg.add<uint16_t>(0x00); // missionID (TODO, this is used for quest tracker)
			}
			msg.addString(mission.getName(player));
			msg.addString(mission.getDescription(player));
		}
	}

	if (version > 1100) {
		sendQuestTracker();
	}

	writeToOutputBuffer(msg);
}

void ProtocolGame::sendTradeItemRequest(const std::string& traderName, const Item* item, bool ack)
{
	NetworkMessage msg;

	if (ack) {
		msg.addByte(0x7D);
	} else {
		msg.addByte(0x7E);
	}

	msg.addString(traderName);

	if (const Container* tradeContainer = item->getContainer()) {
		std::list<const Container*> listContainer {tradeContainer};
		std::list<const Item*> itemList {tradeContainer};
		while (!listContainer.empty()) {
			const Container* container = listContainer.front();
			listContainer.pop_front();

			for (Item* containerItem : container->getItemList()) {
				Container* tmpContainer = containerItem->getContainer();
				if (tmpContainer) {
					listContainer.push_back(tmpContainer);
				}
				itemList.push_back(containerItem);
			}
		}

		msg.addByte(itemList.size());
		for (const Item* listItem : itemList) {
			AddItem(msg, listItem);
		}
	} else {
		msg.addByte(0x01);
		AddItem(msg, item);
	}
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendCloseTrade()
{
	NetworkMessage msg;
	msg.addByte(0x7F);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendCloseContainer(uint8_t cid)
{
	NetworkMessage msg;
	msg.addByte(0x6F);
	msg.addByte(cid);

	if (version >= 1220) {
		msg.addByte(0x9A);
	}

	writeToOutputBuffer(msg);
}

void ProtocolGame::sendCreatureTurn(const Creature* creature, uint32_t stackPos)
{
	if (!canSee(creature)) {
		return;
	}

	NetworkMessage msg;
	msg.addByte(0x6B);
	msg.addPosition(creature->getPosition());
	msg.addByte(stackPos);
	msg.add<uint16_t>(0x63);
	msg.add<uint32_t>(creature->getID());
	msg.addByte(creature->getDirection());
	msg.addByte(player->canWalkthroughEx(creature) ? 0x00 : 0x01);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendCreatureSay(const Creature* creature, SpeakClasses type, const std::string& text, const Position* pos/* = nullptr*/)
{
	NetworkMessage msg;
	msg.addByte(0xAA);
	static uint32_t statementId = 0;
	msg.add<uint32_t>(++statementId);

	std::string name = "";
	bool isPlayer = false;
	uint32_t creatureId = 0;
	if (creature != nullptr) {
		name = creature->getName();
		creatureId = creature->getID();
		if (const Player* p = creature->getPlayer()) {
			creatureId = p->getGUID();
			isPlayer = true;
		}
	}

	msg.addString(creature->getName());
	if (version >= 1251) {
		msg.addByte(0x00); // Show (Traded)
	}

	//Add level only for players
	if (const Player* speaker = creature->getPlayer()) {
		msg.add<uint16_t>(speaker->getLevel());
	} else {
		msg.add<uint16_t>(0x00);
	}

	msg.addByte(type);
	if (pos) {
		msg.addPosition(*pos);
	} else {
		msg.addPosition(creature->getPosition());
	}

	msg.addString(text);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendToChannel(const Creature* creature, SpeakClasses type, const std::string& text, uint16_t channelId)
{
	NetworkMessage msg;
	msg.addByte(0xAA);
	static uint32_t statementId = 0;
	msg.add<uint32_t>(++statementId);

	std::string name = "";
	bool isPlayer = false;
	uint32_t creatureId = 0;
	if (creature) {
		name = creature->getName();
		creatureId = creature->getID();
		if (const Player* p = creature->getPlayer()) {
			creatureId = p->getGUID();
			isPlayer = true;
		}
	}

	if (!creature) {
		msg.add<uint32_t>(0x00);
		if (version >= 1251) {
    			if (statementId != 0) {
       			 	msg.addByte(0x00); // Show (Traded)
 	   		}
		}
	} else if (type == TALKTYPE_CHANNEL_R2) {
		msg.add<uint32_t>(0x00);
		if (version >= 1251) {
   	 		if (statementId != 0) {
  	 		     	msg.addByte(0x00); // Show (Traded)
 		   	}
		}
		type = TALKTYPE_CHANNEL_R1;
	} else {
		msg.addString(creature->getName());
		if (version >= 1251) {
  	  		if (statementId != 0) {
  	   		   	msg.addByte(0x00); // Show (Traded)
 		   	}
		}
		//Add level only for players
		if (const Player* speaker = creature->getPlayer()) {
			msg.add<uint16_t>(speaker->getLevel());
		} else {
			msg.add<uint16_t>(0x00);
		}
	}

	msg.addByte(type);
	msg.add<uint16_t>(channelId);
	msg.addString(text);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendPrivateMessage(const Player* speaker, SpeakClasses type, const std::string& text)
{
	NetworkMessage msg;
	msg.addByte(0xAA);
	static uint32_t statementId = 0;
	msg.add<uint32_t>(++statementId);
	std::string name = "";
	uint32_t creatureId = 0;
	bool isPlayer = false;
	if (speaker) {
		name = speaker->getName();
		if (version >= 1251) {
 	   		if (statementId != 0) {
 			       	msg.addByte(0x00); // Show (Traded)
 		   	}
		}
		creatureId = speaker->getGUID();
		isPlayer = true;
	}

	if (speaker) {
		msg.addString(speaker->getName());
		msg.add<uint16_t>(speaker->getLevel());
	} else {
		msg.add<uint32_t>(0x00);
		if (version >= 1251) {
	    		if (statementId != 0) {
		        	msg.addByte(0x00); // Show (Traded)
 		   	}
		}
	}
	msg.addByte(type);
	msg.addString(text);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendCancelTarget()
{
	NetworkMessage msg;
	msg.addByte(0xA3);
	msg.add<uint32_t>(0x00);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendChangeSpeed(const Creature* creature, uint32_t speed)
{
	NetworkMessage msg;
	msg.addByte(0x8F);
	msg.add<uint32_t>(creature->getID());
	msg.add<uint16_t>(creature->getBaseSpeed() / 2);
	msg.add<uint16_t>(speed / 2);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendDistanceShoot(const Position& from, const Position& to, uint8_t type)
{
	NetworkMessage msg;
	if(version >= 1220) {
		msg.addByte(0x83);
		msg.addPosition(to);

		msg.addByte(0x01);
		msg.addByte(0);
		msg.addByte(MAGIC_EFFECTS_CREATE_DISTANCEEFFECT_REVERSED); // type 4-5 [to => from/from => to]
		msg.addByte(type); // effect
		msg.add<int8_t>(from.x - to.x); // x
		msg.add<int8_t>(from.y - to.y);// y
		msg.addByte(MAGIC_EFFECTS_END_LOOP ); // has impactEffect?


	} else {
		msg.addByte(0x85);
		msg.addPosition(from);
		msg.addPosition(to);
		msg.addByte(type);		
	}

	writeToOutputBuffer(msg);
}

void ProtocolGame::sendCreatureHealth(const Creature* creature)
{
	NetworkMessage msg;
	msg.addByte(0x8C);
	msg.add<uint32_t>(creature->getID());

	if (creature->isHealthHidden()) {
		msg.addByte(0x00);
	} else {
		msg.addByte(std::ceil((static_cast<double>(creature->getHealth()) / std::max<int32_t>(creature->getMaxHealth(), 1)) * 100));
	}
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendFYIBox(const std::string& message)
{
	NetworkMessage msg;
	msg.addByte(0x15);
	msg.addString(message);
	writeToOutputBuffer(msg);
}

//tile
void ProtocolGame::sendAddTileItem(const Position& pos, uint32_t stackpos, const Item* item)
{
	if (!canSee(pos)) {
		return;
	}

	NetworkMessage msg;
	msg.addByte(0x6A);
	msg.addPosition(pos);
	msg.addByte(stackpos);
	AddItem(msg, item);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendUpdateTileItem(const Position& pos, uint32_t stackpos, const Item* item)
{
	if (!canSee(pos)) {
		return;
	}

	NetworkMessage msg;
	msg.addByte(0x6B);
	msg.addPosition(pos);
	msg.addByte(stackpos);
	AddItem(msg, item);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendRemoveTileThing(const Position& pos, uint32_t stackpos)
{
	if (!canSee(pos)) {
		return;
	}

	NetworkMessage msg;
	RemoveTileThing(msg, pos, stackpos);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendFightModes()
{
	NetworkMessage msg;
	msg.addByte(0xA7);
	msg.addByte(player->fightMode);
	msg.addByte(player->chaseMode);
	msg.addByte(player->secureMode);
	msg.addByte(PVP_MODE_DOVE);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendMoveCreature(const Creature* creature, const Position& newPos, int32_t newStackPos, const Position& oldPos, int32_t oldStackPos, bool teleport)
{
	if (creature == player) {
		if (oldStackPos >= 10) {
			sendMapDescription(newPos);
		} else if (teleport) {
			NetworkMessage msg;
			RemoveTileThing(msg, oldPos, oldStackPos);
			writeToOutputBuffer(msg);
			sendMapDescription(newPos);
		} else {
			NetworkMessage msg;
			if (oldPos.z == 7 && newPos.z >= 8) {
				RemoveTileThing(msg, oldPos, oldStackPos);
			} else {
				msg.addByte(0x6D);
				msg.addPosition(oldPos);
				msg.addByte(oldStackPos);
				msg.addPosition(newPos);
			}

			if (newPos.z > oldPos.z) {
				MoveDownCreature(msg, creature, newPos, oldPos);
			} else if (newPos.z < oldPos.z) {
				MoveUpCreature(msg, creature, newPos, oldPos);
			}

			if (oldPos.y > newPos.y) { // north, for old x
				msg.addByte(0x65);
				GetMapDescription(oldPos.x - 8, newPos.y - 6, newPos.z, 18, 1, msg);
			} else if (oldPos.y < newPos.y) { // south, for old x
				msg.addByte(0x67);
				GetMapDescription(oldPos.x - 8, newPos.y + 7, newPos.z, 18, 1, msg);
			}

			if (oldPos.x < newPos.x) { // east, [with new y]
				msg.addByte(0x66);
				GetMapDescription(newPos.x + 9, newPos.y - 6, newPos.z, 1, 14, msg);
			} else if (oldPos.x > newPos.x) { // west, [with new y]
				msg.addByte(0x68);
				GetMapDescription(newPos.x - 8, newPos.y - 6, newPos.z, 1, 14, msg);
			}
			writeToOutputBuffer(msg);
		}
  	} else if (canSee(oldPos) && canSee(newPos)) {
		if (teleport || (oldPos.z == 7 && newPos.z >= 8) || oldStackPos >= 10) {
			sendRemoveTileThing(oldPos, oldStackPos);
			sendAddCreature(creature, newPos, newStackPos, false);
		} else {
			NetworkMessage msg;
			msg.addByte(0x6D);
			msg.addPosition(oldPos);
			msg.addByte(oldStackPos);
  	    		msg.addPosition(newPos);
			writeToOutputBuffer(msg);
		}
	} else if (canSee(oldPos)) {
		sendRemoveTileThing(oldPos, oldStackPos);
  	} else if (canSee(newPos)) {
		sendAddCreature(creature, newPos, newStackPos, false);
	}
}

void ProtocolGame::sendAddContainerItem(uint8_t cid, uint16_t slot, const Item* item)
{
	NetworkMessage msg;
	msg.addByte(0x70);
	msg.addByte(cid);
	msg.add<uint16_t>(slot);
	AddItem(msg, item);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendUpdateContainerItem(uint8_t cid, uint16_t slot, const Item* item)
{
	NetworkMessage msg;
	msg.addByte(0x71);
	msg.addByte(cid);
	msg.add<uint16_t>(slot);
	AddItem(msg, item);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendRemoveContainerItem(uint8_t cid, uint16_t slot, const Item* lastItem)
{
	NetworkMessage msg;
	msg.addByte(0x72);
	msg.addByte(cid);
	msg.add<uint16_t>(slot);
	if (lastItem) {
		AddItem(msg, lastItem);
	} else {
		msg.add<uint16_t>(0x00);
	}
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendTextWindow(uint32_t windowTextId, Item* item, uint16_t maxlen, bool canWrite)
{
	NetworkMessage msg;
	msg.addByte(0x96);
	msg.add<uint32_t>(windowTextId);
	AddItem(msg, item);

	if (canWrite) {
		msg.add<uint16_t>(maxlen);
		msg.addString(item->getText());
	} else {
		const std::string& text = item->getText();
		msg.add<uint16_t>(text.size());
		msg.addString(text);
	}

	const std::string& writer = item->getWriter();
	if (!writer.empty()) {
		msg.addString(writer);
	} else {
		msg.add<uint16_t>(0x00);
	}


	if (version >= 1251) {
		msg.addByte(0x00); // Show (Traded)
	}

	time_t writtenDate = item->getDate();
	if (writtenDate != 0) {
		msg.addString(formatDateShort(writtenDate));
	} else {
		msg.add<uint16_t>(0x00);
	}

	writeToOutputBuffer(msg);
}

void ProtocolGame::sendTextWindow(uint32_t windowTextId, uint32_t itemId, const std::string& text)
{
	NetworkMessage msg;
	msg.addByte(0x96);
	msg.add<uint32_t>(windowTextId);
	AddItem(msg, itemId, 1);
	msg.add<uint16_t>(text.size());
	msg.addString(text);
	msg.add<uint16_t>(0x00);
	if (version >= 1251) {
		msg.addByte(0x00); // Show (Traded)
	}
	msg.add<uint16_t>(0x00);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendHouseWindow(uint32_t windowTextId, const std::string& text)
{
	NetworkMessage msg;
	msg.addByte(0x97);
	msg.addByte(0x00);
	msg.add<uint32_t>(windowTextId);
	msg.addString(text);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendOutfitWindow()
{
	NetworkMessage msg;
	msg.addByte(0xC8);

	bool mounted = false;
	Outfit_t currentOutfit = player->getDefaultOutfit();
	Mount* currentMount = g_game.mounts.getMountByID(player->getCurrentMount());
	if (currentMount) {
		if (version >= 1220) {
			mounted = (currentOutfit.lookMount == currentMount->clientId);
			currentOutfit.lookMount = currentMount->clientId;
		} else {
			currentOutfit.lookMount = currentMount->clientId;
		}
	}

	AddOutfit(msg, currentOutfit);

	msg.addByte(currentOutfit.lookMountHead);
	msg.addByte(currentOutfit.lookMountBody);
	msg.addByte(currentOutfit.lookMountLegs);
	msg.addByte(currentOutfit.lookMountFeet);
	msg.add<uint16_t>(currentOutfit.lookFamiliarsType);

	std::vector<ProtocolOutfit> protocolOutfits;
	if (player->group->id >= 5) {
		static const std::string gamemasterOutfitName = "Game Master";
		protocolOutfits.emplace_back(gamemasterOutfitName, 75, 0);

		static const std::string gmCustomerSupport = "Customer Support";
		protocolOutfits.emplace_back(gmCustomerSupport, 266, 0);

		static const std::string communityManager = "Community Manager";
		protocolOutfits.emplace_back(communityManager, 302, 0);
	}

	const auto& outfits = Outfits::getInstance().getOutfits(player->getSex());
	protocolOutfits.reserve(outfits.size());
	for (const Outfit& outfit : outfits) {
		uint8_t addons;
		if (!player->getOutfitAddons(outfit, addons)) {
			continue;
		}

		protocolOutfits.emplace_back(outfit.name, outfit.lookType, addons);
		if (protocolOutfits.size() == 150 && version < 1185) { // Game client doesn't allow more than 150 outfits
			break;
		}
	}

	if (version >= 1185) {
		msg.add<uint16_t>(protocolOutfits.size());
	} else {
		msg.addByte(protocolOutfits.size());
	}

	for (const ProtocolOutfit& outfit : protocolOutfits) {
		msg.add<uint16_t>(outfit.lookType);
		msg.addString(outfit.name);
		msg.addByte(outfit.addons);

		if (version >= 1185) {
			msg.addByte(0x00);
		}
	}

	std::vector<const Mount*> protocolMounts;
	const auto& mounts = g_game.mounts.getMounts();
	protocolMounts.reserve(mounts.size());
	for (const Mount& mount : mounts) {
		if (player->hasMount(&mount)) {
			protocolMounts.push_back(&mount);
		}
	}

	if (version >= 1185) {
		msg.add<uint16_t>(protocolMounts.size());
		} else {
		msg.addByte(mounts.size());
	}

	for (const Mount* mount : protocolMounts) {
		msg.add<uint16_t>(mount->clientId);
		msg.addString(mount->name);

		if (version >= 1185) {
			msg.addByte(0x00);
		}
		/* store exemple:  replace /\ to \/
			if (version >= 1185 && player->hasMount(mount)) {
				msg.addByte(0x00);
			} else { // in store:
				msg.addByte(0x1);
				msg.add<uint32_t>(id in store);
			}
		*/
	}

	std::vector<ProtocolFamiliars> protocolFamiliars;
	const auto& familiars = Familiars::getInstance().getFamiliars(player->getVocationId());
	protocolFamiliars.reserve(familiars.size());
	for (const Familiar& familiar : familiars) {
		if (!player->getFamiliar(familiar)) {
			continue;
		}
		protocolFamiliars.emplace_back(familiar.name, familiar.lookType);
	}

	msg.add<uint16_t>(protocolFamiliars.size());
	for (const ProtocolFamiliars& familiar : protocolFamiliars) {
		msg.add<uint16_t>(familiar.lookType);
		msg.addString(familiar.name);
		msg.addByte(0x00);
	}

	if (version >= 1185) {
		msg.addByte(0x00);
		msg.addByte((player->isMounted() ? 0x01 : 0x00));
	}

	writeToOutputBuffer(msg);
}

void ProtocolGame::sendUpdatedVIPStatus(uint32_t guid, VipStatus_t newStatus)
{
	NetworkMessage msg;
	msg.addByte(0xD3);
	msg.add<uint32_t>(guid);
	msg.addByte(newStatus);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendSpellCooldown(uint8_t spellId, uint32_t time)
{
	NetworkMessage msg;
	msg.addByte(0xA4);
	if (player->getProtocolVersion() < 1120 && spellId >= 170) {
		spellId = 150;
	}
	msg.addByte(spellId);
	msg.add<uint32_t>(time);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendSpellGroupCooldown(SpellGroup_t groupId, uint32_t time)
{
	NetworkMessage msg;
	msg.addByte(0xA5);
	msg.addByte(groupId);
	msg.add<uint32_t>(time);
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendModalWindow(const ModalWindow& modalWindow)
{
	NetworkMessage msg;
	msg.addByte(0xFA);

	msg.add<uint32_t>(modalWindow.id);
	msg.addString(modalWindow.title);
	msg.addString(modalWindow.message);

	msg.addByte(modalWindow.buttons.size());
	for (const auto& it : modalWindow.buttons) {
		msg.addString(it.first);
		msg.addByte(it.second);
	}

	msg.addByte(modalWindow.choices.size());
	for (const auto& it : modalWindow.choices) {
		msg.addString(it.first);
		msg.addByte(it.second);
	}

	msg.addByte(modalWindow.defaultEscapeButton);
	msg.addByte(modalWindow.defaultEnterButton);
	msg.addByte(modalWindow.priority ? 0x01 : 0x00);

	writeToOutputBuffer(msg);
}

void ProtocolGame::addImbuementInfo(NetworkMessage& msg, uint32_t imbuid)
{
	Imbuement* imbuement = g_imbuements.getImbuement(imbuid);
	BaseImbue* base = g_imbuements.getBaseByID(imbuement->getBaseID());
	Category* category = g_imbuements.getCategoryByID(imbuement->getCategory());

	msg.add<uint32_t>(imbuid);
	msg.addString(base->name + " " + imbuement->getName());
	msg.addString(imbuement->getDescription());
	msg.addString(category->name + imbuement->getSubGroup());

	msg.add<uint16_t>(imbuement->getIconID());
	msg.add<uint32_t>(base->duration);

	msg.addByte(imbuement->isPremium() ? 0x01 : 0x00);

	const auto& items = imbuement->getItems();
	msg.addByte(items.size());

	for (const auto& itm : items) {
		const ItemType& it = Item::items[itm.first];
		msg.addItemId(itm.first);
		msg.addString(it.name);
		msg.add<uint16_t>(itm.second);
	}

	msg.add<uint32_t>(base->price);
	msg.addByte(base->percent);
	msg.add<uint32_t>(base->protection);
}

void ProtocolGame::sendImbuementWindow(Item* item)
{
	if (!item || item->isRemoved()) {
		return;
	}
	const ItemType& it = Item::items[item->getID()];
	uint8_t slot = it.imbuingSlots;
	bool itemHasImbue = false;
	for (uint8_t i = 0; i < slot; i++) {
		uint32_t info = item->getImbuement(i);
		if (info >> 8) {
			itemHasImbue = true;
			break;
		}
	}

	std::vector<Imbuement*> imbuements = g_imbuements.getImbuements(player, item);
	if (!itemHasImbue && imbuements.empty()) {
		player->sendTextMessage(MESSAGE_EVENT_ADVANCE, "You cannot imbue this item.");
		return;
	}
	// Seting imbuing item
	player->inImbuing(item);

	NetworkMessage msg;
	msg.addByte(0xEB);
	msg.addItemId(item->getID());
	msg.addByte(slot);

	for (uint8_t i = 0; i < slot; i++) {
		uint32_t info = item->getImbuement(i);
		if (info >> 8) {
			msg.addByte(0x01);

			addImbuementInfo(msg, (info & 0xFF));
			msg.add<uint32_t>(info >> 8);
			msg.add<uint32_t>(g_imbuements.getBaseByID(g_imbuements.getImbuement((info & 0xFF))->getBaseID())->removecust);
		} else {
			msg.addByte(0x00);
		}
	}

	std::unordered_map<uint16_t, uint16_t> needItems;
	msg.add<uint16_t>(imbuements.size());
	for (Imbuement* ib : imbuements) {
		addImbuementInfo(msg, ib->getId());

		const auto& items = ib->getItems();
		for (const auto& itm : items) {
			if (!needItems.count(itm.first)) {
				needItems[itm.first] = player->getItemTypeCount(itm.first);
			}
		}

	}

	msg.add<uint32_t>(needItems.size());
	for (const auto& itm : needItems) {
		msg.addItemId(itm.first);
		msg.add<uint16_t>(itm.second);
	}

	if (player->getProtocolVersion() >= 1100) {
		sendResourceBalance(player->getMoney(), player->getBankBalance());
	}

	writeToOutputBuffer(msg);
}

void ProtocolGame::AddItem(NetworkMessage& msg, uint16_t id, uint8_t count)
{
	const ItemType& it = Item::items[id];
	msg.add<uint16_t>(it.clientId);

	// if (version >= 1185 && g_config.getBoolean(ConfigManager::PROTO_BUFF)) {
	// 	auto it2 = Item::items.appearancesMap.find(it.clientId);
	// 	if (it2 != Item::items.appearancesMap.end()) {
	// 		if (it2->second.cumulative) {
	// 			msg.addByte(count);
	// 		} else if (it2->second.liquidcontainer || it2->second.liquidpool) {
	// 			msg.addByte(fluidMap[count & 7]);
	// 		} else if (it2->second.isContainer) {
	// 			msg.addByte(0x00);
	// 		}

	// 		if (it2->second.isAnimation) {
	// 			msg.addByte(0xFE);
	// 		}

	// 	}
	// 	return;
	// }

	if (version < 1200) {
		msg.addByte(0xFF); // MARK_UNMARKED
	}

	if (it.stackable) {
		msg.addByte(count);
	} else if (it.isSplash() || it.isFluidContainer()) {
		msg.addByte(fluidMap[count & 7]);
	} else if (version >= 1150 && it.isContainer()) {
		msg.addByte(0x00);
		msg.addByte(0x00);
	}
}

void ProtocolGame::AddItem(NetworkMessage& msg, const Item* item)
{
	const ItemType& it = Item::items[item->getID()];
	msg.add<uint16_t>(it.clientId);

	// if (version >= 1185 && g_config.getBoolean(ConfigManager::PROTO_BUFF)) {
	// 	auto it2 = Item::items.appearancesMap.find(it.clientId);
	// 	if (it2 != Item::items.appearancesMap.end()) {
	// 		if (it2->second.cumulative) {
	// 			msg.addByte(count);
	// 		} else if (it2->second.liquidcontainer || it2->second.liquidpool) {
	// 			msg.addByte(fluidMap[count & 7]);
	// 		} else if (it2->second.isContainer) {
	// 			const Container* container = item->getContainer();
	// 			if (container && container->getHoldingPlayer() == player) {
	// 				uint32_t lootFlags = 0;
	// 				for (auto itt : player->quickLootContainers) {
	// 					if (itt.second == container) {
	// 						lootFlags |= 1 << itt.first;
	// 					}
	// 				}

	// 				if (lootFlags != 0) {
	// 					msg.addByte(0x01);
	// 					msg.add<uint32_t>(lootFlags);
	// 				} else {
	// 					msg.addByte(0x00);
	// 				}
	// 			} else {
	// 				msg.addByte(0x00);
	// 			}
	// 		}

	// 		if (it2->second.isAnimation) {
	// 			msg.addByte(0xFE);
	// 		}

	// 	}
	// 	return;
	// }


	if (version < 1200) {
		msg.addByte(0xFF); // MARK_UNMARKED
	}

	if (it.stackable) {
		msg.addByte(std::min<uint16_t>(0xFF, item->getItemCount()));
	} else if (it.isSplash() || it.isFluidContainer()) {
		msg.addByte(fluidMap[item->getFluidType() & 7]);
	} else if (version >= 1150 && it.isContainer()) {
		const Container* container = item->getContainer();
		if (container && container->getHoldingPlayer() == player) {
			uint32_t lootFlags = 0;
			for (auto itt : player->quickLootContainers) {
				if (itt.second == container) {
					lootFlags |= 1 << itt.first;
				}
			}

			if (lootFlags != 0) {
				msg.addByte(0x01);
				msg.add<uint32_t>(lootFlags);
			} else {
				msg.addByte(0x00);
			}
		} else {
			msg.addByte(0x00);
		}
		// Quiver ammo count
		msg.addByte(0x00);
	}
}

void ProtocolGame::MoveUpCreature(NetworkMessage& msg, const Creature* creature, const Position& newPos, const Position& oldPos)
{
	if (creature != player) {
		return;
	}

	//floor change up
	msg.addByte(0xBE);

	//going to surface
	if (newPos.z == 7) {
		int32_t skip = -1;
		GetFloorDescription(msg, oldPos.x - 8, oldPos.y - 6, 5, 18, 14, 3, skip); //(floor 7 and 6 already set)
		GetFloorDescription(msg, oldPos.x - 8, oldPos.y - 6, 4, 18, 14, 4, skip);
		GetFloorDescription(msg, oldPos.x - 8, oldPos.y - 6, 3, 18, 14, 5, skip);
		GetFloorDescription(msg, oldPos.x - 8, oldPos.y - 6, 2, 18, 14, 6, skip);
		GetFloorDescription(msg, oldPos.x - 8, oldPos.y - 6, 1, 18, 14, 7, skip);
		GetFloorDescription(msg, oldPos.x - 8, oldPos.y - 6, 0, 18, 14, 8, skip);

		if (skip >= 0) {
			msg.addByte(skip);
			msg.addByte(0xFF);
		}
	}
	//underground, going one floor up (still underground)
	else if (newPos.z > 7) {
		int32_t skip = -1;
		GetFloorDescription(msg, oldPos.x - 8, oldPos.y - 6, oldPos.getZ() - 3, 18, 14, 3, skip);

		if (skip >= 0) {
			msg.addByte(skip);
			msg.addByte(0xFF);
		}
	}

	//moving up a floor up makes us out of sync
	//west
	msg.addByte(0x68);
	GetMapDescription(oldPos.x - 8, oldPos.y - 5, newPos.z, 1, 14, msg);

	//north
	msg.addByte(0x65);
	GetMapDescription(oldPos.x - 8, oldPos.y - 6, newPos.z, 18, 1, msg);
}

void ProtocolGame::MoveDownCreature(NetworkMessage& msg, const Creature* creature, const Position& newPos, const Position& oldPos)
{
	if (creature != player) {
		return;
	}

	//floor change down
	msg.addByte(0xBF);

	//going from surface to underground
	if (newPos.z == 8) {
		int32_t skip = -1;

		GetFloorDescription(msg, oldPos.x - 8, oldPos.y - 6, newPos.z, 18, 14, -1, skip);
		GetFloorDescription(msg, oldPos.x - 8, oldPos.y - 6, newPos.z + 1, 18, 14, -2, skip);
		GetFloorDescription(msg, oldPos.x - 8, oldPos.y - 6, newPos.z + 2, 18, 14, -3, skip);

		if (skip >= 0) {
			msg.addByte(skip);
			msg.addByte(0xFF);
		}
	}
	//going further down
	else if (newPos.z > oldPos.z && newPos.z > 8 && newPos.z < 14) {
		int32_t skip = -1;
		GetFloorDescription(msg, oldPos.x - 8, oldPos.y - 6, newPos.z + 2, 18, 14, -3, skip);

		if (skip >= 0) {
			msg.addByte(skip);
			msg.addByte(0xFF);
		}
	}

	//moving down a floor makes us out of sync
	//east
	msg.addByte(0x66);
	GetMapDescription(oldPos.x + 9, oldPos.y - 7, newPos.z, 1, 14, msg);

	//south
	msg.addByte(0x67);
	GetMapDescription(oldPos.x - 8, oldPos.y + 7, newPos.z, 18, 1, msg);
}

void ProtocolGame::AddShopItem(NetworkMessage& msg, const ShopInfo& item)
{
	const ItemType& it = Item::items[item.itemId];
	msg.add<uint16_t>(it.clientId);

	if (it.isSplash() || it.isFluidContainer()) {
		msg.addByte(serverFluidToClient(item.subType));
	} else {
		msg.addByte(0x00);
	}

	msg.addString(item.realName);
	msg.add<uint32_t>(it.weight);
	msg.add<uint32_t>(item.buyPrice == 4294967295 ? 0 : item.buyPrice);
	msg.add<uint32_t>(item.sellPrice == 4294967295 ? 0 : item.sellPrice);
}

void ProtocolGame::parseBestiaryTracker(NetworkMessage& msg)
{
	uint16_t raceid = msg.get<uint16_t>();
	msg.get<uint8_t>();

	addGameTask(&Game::parsePlayerBestiaryTracker, player->getID(), raceid);
}

void ProtocolGame::parseExtendedOpcode(NetworkMessage& msg)
{
	uint8_t opcode = msg.getByte();
	const std::string& buffer = msg.getString();

	// process additional opcodes via lua script event
	addGameTask(&Game::parsePlayerExtendedOpcode, player->getID(), opcode, buffer);
}

void ProtocolGame::sendBestiaryGroups()
{
	NetworkMessage msg;
	msg.addByte(0xD5);
	msg.add<uint16_t>(g_bestiaries.bestiary.size());
	for (auto best : g_bestiaries.bestiary) {
		msg.addString(best.second.getName());
		msg.add<uint16_t>(best.second.getRaces().size()); // amount
		msg.add<uint16_t>(best.second.getRaces().size()); // know
	}
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendBestiaryOverview(std::string raceName)
{
	Bestiary* race = g_bestiaries.getBestiaryByName(raceName);
	if (!race) {
		std::cout << "nao achei " << raceName << std::endl;
		return;
	}

	NetworkMessage msg;
	msg.addByte(0xD6);
	msg.addString(race->getName()); // race name
	msg.add<uint16_t>(race->getRaces().size()); // monster count
	for (auto raceEnt : race->getRaces()) {
		msg.add<uint16_t>(raceEnt.id); // monster name
		uint8_t currentLevel = 0x00;

		RaceEntry* raceEntry = race->getRaceByID(raceEnt.id);
		if (raceEntry) {
			Difficulty* difficulty = g_bestiaries.getDifficulty(raceEntry->difficulty, raceEntry->rare);
			if (difficulty) {
				int32_t killCounter = player->getBestiaryKills(raceEnt.id);
				if (player->isAccessPlayer() || killCounter >= difficulty->final) {
					currentLevel = 0x04;
				} else if (killCounter < difficulty->first) {
					currentLevel = 0x01;
				} else if (killCounter < difficulty->second) {
					currentLevel = 0x02;
				} else if (killCounter < difficulty->final) {
					currentLevel = 0x03;
				}
			}
		}
		msg.add<uint16_t>(currentLevel);
	}
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendBestiaryOverview(std::vector<uint16_t> monsters)
{
	if(monsters.empty()) {
		return;
	}

	std::vector<uint16_t> showMonsters;
	for (auto it = monsters.begin(), end = monsters.end(); it != end; ++it) {
		Bestiary* race = g_bestiaries.getBestiaryByRaceID(*it);
		if(!race) {
			continue;
		}

		RaceEntry* raceEntry = race->getRaceByID(*it);
		if (!raceEntry) {
			continue;
		}
		Difficulty* difficulty = g_bestiaries.getDifficulty(raceEntry->difficulty, raceEntry->rare);
		if (!difficulty) {
			continue;
		}

		showMonsters.emplace_back(*it);
	}

	NetworkMessage msg;
	msg.addByte(0xD6);
	msg.addString("Result");
	msg.add<uint16_t>(showMonsters.size()); // monster count
	for (auto it = showMonsters.begin(), end = showMonsters.end(); it != end; ++it) {
		msg.add<uint16_t>(*it); // monster name
		uint8_t currentLevel = 0x00;

		Bestiary* race = g_bestiaries.getBestiaryByRaceID(*it);
		if (!race) {
			continue;
		}
		RaceEntry* raceEntry = race->getRaceByID(*it);
		if (raceEntry) {
			Difficulty* difficulty = g_bestiaries.getDifficulty(raceEntry->difficulty, raceEntry->rare);
			if (difficulty) {
				int32_t killCounter = player->getBestiaryKills(*it);
				if (player->isAccessPlayer() || killCounter >= difficulty->final) {
					currentLevel = 0x04;
				} else if (killCounter < difficulty->first) {
					currentLevel = 0x01;
				} else if (killCounter < difficulty->second) {
					currentLevel = 0x02;
				} else if (killCounter < difficulty->final) {
					currentLevel = 0x03;
				}
			}
		}
		msg.add<uint16_t>(currentLevel);
	}
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendBestiaryMonsterData(uint16_t monsterId)
{
	Bestiary* race = g_bestiaries.getBestiaryByRaceID(monsterId);
	if (!race) {
		std::cout << "break race: " << monsterId << std::endl;
		return;
	}

	MonsterType* monsterType = race->getMonsterByRace(monsterId);
	if (!monsterType) {
		std::cout << "break monsterType: " << monsterId << std::endl;
		return;
	}

	RaceEntry* raceEntry = race->getRaceByID(monsterId);
	if (!raceEntry) {
		std::cout << "break raceEntry" << std::endl;
		return;
	}

	Difficulty* difficulty = g_bestiaries.getDifficulty(raceEntry->difficulty, raceEntry->rare);
	if (!difficulty) {
		std::cout << "break difficulty " << raceEntry->difficulty << " " << raceEntry->rare << std::endl;
		return;
	}

	NetworkMessage msg;
	msg.addByte(0xD7);
	msg.add<uint16_t>(monsterId);
	msg.addString(race->getName());

	int32_t killCounter = player->getBestiaryKills(monsterId);

	uint8_t currentLevel = 0x00;
	if (player->isAccessPlayer() || killCounter >= difficulty->final) {
		currentLevel = 0x04;
		if (player->isAccessPlayer())
			killCounter = difficulty->final;

	} else if (killCounter < difficulty->first) {
		currentLevel = 0x01;
	} else if (killCounter < difficulty->second) {
		currentLevel = 0x02;
	} else if (killCounter < difficulty->final) {
		currentLevel = 0x03;
	}

	msg.addByte(currentLevel);

	msg.add<uint32_t>(killCounter);
	msg.add<uint16_t>(difficulty->first);
	msg.add<uint16_t>(difficulty->second);
	msg.add<uint16_t>(difficulty->final);

	msg.addByte(raceEntry->difficulty);
	msg.addByte(raceEntry->ocorrence - 1);

	// getting monster loot -- duplicate items
	std::map<uint16_t, int32_t> lootMap;
	for (const auto& lootBlock : monsterType->info.lootItems) {
		auto it = lootMap.find(lootBlock.id);
		if (it == lootMap.end()) {
			lootMap[lootBlock.id] = lootBlock.chance;
		}
	}	

	msg.addByte(lootMap.size());

	for (const auto& lootItem : lootMap) {
		// common
		uint8_t difficult = 0x00;
		int32_t chance = lootItem.second;

		if (chance < 200) {
			// very-rare
			difficult = 0x04;
		} else if (chance < 1000) {
			// semi-rare
			difficult = 0x03;
		} else if (chance < 5000) {
			// rare
			difficult = 0x02;
		} else if (chance < 30000) {
			// uncommon
			difficult = 0x01;
		}

		if (killCounter < 1) {
			msg.add<uint16_t>(0x00);
			msg.addByte(0x0);
			msg.addByte(difficult);
		} else {
			const ItemType& itemType = Item::items[lootItem.first];
			msg.addItemId(lootItem.first);
			msg.addByte(difficult);
			msg.addByte(0x0); // 0 = normal loot   /  1 = special event loot
			msg.addString(itemType.name);
			msg.addByte((itemType.stackable ? 0x1 : 0x0));
		}
	}

	if (currentLevel > 1) {
		msg.add<uint16_t>(difficulty->charm);
		uint8_t attackMode = 0x00;
		if (monsterType->info.isPassive) {
			attackMode = 0x02;
		} else if (monsterType->info.targetDistance) {
			attackMode = 0x01;
		}

		msg.addByte(attackMode);
		msg.addByte(0x02); // flag for cast spells
		msg.add<uint32_t>(monsterType->info.healthMax);
		msg.add<uint32_t>(monsterType->info.experience);
		msg.add<uint16_t>( static_cast<uint16_t>(monsterType->info.baseSpeed / g_config.getDouble(ConfigManager::RATE_MONSTER_SPEED)) );
		msg.add<uint16_t>(monsterType->info.armor);
	}

	if (currentLevel > 2) {
		std::map<CombatType_t, uint8_t> defaultcombatmap;
		defaultcombatmap[COMBAT_PHYSICALDAMAGE] = 100;
		defaultcombatmap[COMBAT_FIREDAMAGE] = 100;
		defaultcombatmap[COMBAT_EARTHDAMAGE] = 100;
		defaultcombatmap[COMBAT_ENERGYDAMAGE] = 100;
		defaultcombatmap[COMBAT_ICEDAMAGE] = 100;
		defaultcombatmap[COMBAT_HOLYDAMAGE] = 100;
		defaultcombatmap[COMBAT_DEATHDAMAGE] = 100;
		defaultcombatmap[COMBAT_HEALING] = 100;

		for (const auto& elementEntry : monsterType->info.elementMap) {
			auto it = defaultcombatmap.find(elementEntry.first);
			if (it == defaultcombatmap.end()) {
				continue;
			}
			
			defaultcombatmap[elementEntry.first] = elementEntry.second + 100;
		}
	
		msg.addByte(defaultcombatmap.size());
		uint8_t i = 0;
		for (const auto& elementEntry : defaultcombatmap) {
			msg.addByte(i);
			msg.add<uint16_t>(elementEntry.second);
			i++;
		}

		bool emptyLocation = raceEntry->location.empty();
		msg.add<uint16_t>(emptyLocation ? 0x00 : 0x01); // enable or disable description
		if(!emptyLocation)
			msg.addString(raceEntry->location); // enable or disable description
	}

	if (currentLevel > 3) {
		player->setLastBestiaryMonster(monsterId);
		// charm things
		int8_t charmid = player->getMonsterCharm(monsterId);
		if (charmid > -1) {
			msg.addByte(0x01);
			msg.addByte(charmid);
			msg.add<uint32_t>(player->getCharmPrice());
		} else {
			msg.addByte(0x00);
			msg.addByte(0x01);
		}
	}

	writeToOutputBuffer(msg);
}

void ProtocolGame::sendCharmData()
{

	NetworkMessage msg;
	msg.addByte(0xD8);
	msg.add<uint32_t>(player->getCharmPoints());
	msg.addByte(g_charms.charms.size());
	bool hasUnlock = true;
	for (auto charm : g_charms.charms) {
		msg.addByte(charm.second.getId());
		msg.addString(charm.second.getName());
		msg.addString(charm.second.getDescription());
		msg.addByte(charm.second.getType());
		msg.add<uint16_t>(charm.second.getPrice());
		// msg.addByte(0x01);
		msg.addByte(player->isUnlockedCharm(charm.second.getId()) ? 0x01 : 0x00 );
		if (player->isUnlockedCharm(charm.second.getId()) && !hasUnlock) {
			hasUnlock = true;
		}
		msg.addByte(player->getCurrentCreature(charm.second.getId()) == 0 ? 0x00 : 0x01);
		if (player->getCurrentCreature(charm.second.getId()) > 0) {
			msg.add<uint16_t>(player->getCurrentCreature(charm.second.getId()));
			msg.add<uint32_t>(player->getCharmPrice());
		}
	}

	msg.addByte(0x04); // ??
	std::vector<uint16_t> showMonsters;
	for (const auto& it : player->bestiaryKills) {
		Bestiary* race = g_bestiaries.getBestiaryByRaceID(it.first);
		if (race) {
			RaceEntry* raceEntry = race->getRaceByID(it.first);
			if (raceEntry) {
				Difficulty* difficulty = g_bestiaries.getDifficulty(raceEntry->difficulty, raceEntry->rare);
				const BestiaryPoints& bestiaryPoints = it.second;

				if (difficulty && bestiaryPoints.kills >= difficulty->final && std::find(showMonsters.begin(), showMonsters.end(), bestiaryPoints.kills) == showMonsters.end()) {
					uint16_t monsterid = static_cast<uint16_t>(it.first);
					int charm = player->getMonsterCharm(monsterid);
					if (charm == -1) {
						showMonsters.emplace_back(it.first);
					}
				}
			}
		}

	}

	msg.add<uint16_t>(showMonsters.size());
	if (!showMonsters.empty()) {
		for (auto it = showMonsters.begin(), end = showMonsters.end(); it != end; ++it) {
			msg.add<uint16_t>(*it);
		}
	}
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendPlayerMana(const Player* target)
{
	if (version < 1230) {
		return;
	}

	NetworkMessage msg;
	msg.addByte(0x8B);
	msg.add<uint32_t>(target->getID());
	msg.addByte(11);
	msg.addByte(std::ceil((static_cast<double>(target->getMana()) / std::max<int32_t>(target->getMaxMana(), 1)) * 100));
	writeToOutputBuffer(msg);
}

void ProtocolGame::sendBestiaryTracker()
{
	if (version < 1230) {
		return;
	}

	NetworkMessage msg;
	msg.addByte(0xB9);
	msg.addByte(player->bestiaryTracker.size());
	if (!player->bestiaryTracker.empty()) {
		for (const auto& raceid : player->bestiaryTracker) {
			Bestiary* race = g_bestiaries.getBestiaryByRaceID(raceid);
			if (!race) {
				std::cout << "break race: " << raceid << std::endl;
				return;
			}

			MonsterType* monsterType = race->getMonsterByRace(raceid);
			if (!monsterType) {
				std::cout << "break monsterType: " << raceid << std::endl;
				return;
			}

			RaceEntry* raceEntry = race->getRaceByID(raceid);
			if (!raceEntry) {
				std::cout << "break raceEntry" << std::endl;
				return;
			}

			Difficulty* difficulty = g_bestiaries.getDifficulty(raceEntry->difficulty, raceEntry->rare);
			if (!difficulty) {
				std::cout << "break difficulty " << raceEntry->difficulty << " " << raceEntry->rare << std::endl;
				return;
			}


			msg.add<uint16_t>(raceid);
			msg.add<uint32_t>(player->getBestiaryKills(raceid));
			msg.add<uint16_t>(difficulty->first);
			msg.add<uint16_t>(difficulty->second);
			msg.add<uint16_t>(difficulty->final);
			msg.addByte(0x0);
		}

	}
	writeToOutputBuffer(msg);
}

void ProtocolGame::requestPurchaseData(uint32_t offerId, uint8_t offerType)
{
	NetworkMessage msg;
	msg.addByte(0xE1);
	msg.add<uint32_t>(offerId);
	msg.addByte(offerType);

	writeToOutputBuffer(msg);
}

void ProtocolGame::sendStoreHistory(uint32_t totalPages, uint32_t pages, std::vector<StoreHistory> filter)
{
	NetworkMessage msg;
	msg.addByte(0xFD);
	msg.add<uint32_t>(totalPages > 0 ? pages - 1 : 0x0); //-- current page
	msg.add<uint32_t>(totalPages > 0 ? totalPages : 0x0); //-- total page
	msg.addByte(filter.size());

	for (auto currentHistory = filter.begin(), end = filter.end(); currentHistory != end; ++currentHistory) {
		if (version >= 1220)
			msg.add<uint32_t>(0);

		msg.add<uint32_t>((*currentHistory).time);
		msg.addByte((*currentHistory).mode);
		msg.add<int32_t>((*currentHistory).cust);
		if (version >= 1200)
    		msg.addByte((*currentHistory).coinMode); //0 = transferable tibia coin, 1 = normal tibia coin

		msg.addString((*currentHistory).description);
		if (version >= 1220)
			msg.addByte(0); //-- details
	}

	writeToOutputBuffer(msg);
}

void ProtocolGame::sendLockerItems(std::map<uint16_t, uint16_t> itemMap, uint16_t count)
{
	NetworkMessage msg;
	msg.addByte(0x94);

	msg.add<uint16_t>(count);
	for (const auto& it : itemMap) {
		msg.addItemId(it.first);
		msg.add<uint16_t>(it.second);
	}

	writeToOutputBuffer(msg);
}