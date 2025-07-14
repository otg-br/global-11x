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

#include "pugicast.h"
#include "decay.h"

#include "actions.h"
#include "bed.h"
#include "bestiary.h"
#include "charm.h"
#include "configmanager.h"
#include "creature.h"
#include "creatureevent.h"
#include "databasetasks.h"
#include "events.h"
#include "game.h"
#include "globalevent.h"
#include "iologindata.h"
#include "iomarket.h"
#include "items.h"
#include "monster.h"
#include "movement.h"
#include "scheduler.h"
#include "server.h"
#include "spells.h"
#include "talkaction.h"
#include "weapons.h"
#include "script.h"
#include "modules.h"
#include "imbuements.h"
#include "store.h"

extern ConfigManager g_config;
extern Actions* g_actions;
extern Chat* g_chat;
extern Charms g_charms;
extern TalkActions* g_talkActions;
extern Spells* g_spells;
extern Vocations g_vocations;
extern GlobalEvents* g_globalEvents;
extern CreatureEvents* g_creatureEvents;
extern Events* g_events;
extern Monsters g_monsters;
extern MoveEvents* g_moveEvents;
extern Weapons* g_weapons;
extern Scripts* g_scripts;
extern Modules* g_modules;
extern Imbuements g_imbuements;
extern Bestiaries g_bestiaries;
extern Store g_store;

Game::Game()
{
	offlineTrainingWindow.choices.emplace_back("Sword Fighting and Shielding", SKILL_SWORD);
	offlineTrainingWindow.choices.emplace_back("Axe Fighting and Shielding", SKILL_AXE);
	offlineTrainingWindow.choices.emplace_back("Club Fighting and Shielding", SKILL_CLUB);
	offlineTrainingWindow.choices.emplace_back("Distance Fighting and Shielding", SKILL_DISTANCE);
	offlineTrainingWindow.choices.emplace_back("Magic Level and Shielding", SKILL_MAGLEVEL);
	offlineTrainingWindow.buttons.emplace_back("Okay", 1);
	offlineTrainingWindow.buttons.emplace_back("Cancel", 0);
	offlineTrainingWindow.defaultEnterButton = 1;
	offlineTrainingWindow.defaultEscapeButton = 0;
	offlineTrainingWindow.priority = true;
}

Game::~Game()
{
	for (const auto& it : guilds) {
		delete it.second;
	}
}

void Game::start(ServiceManager* manager)
{
	serviceManager = manager;

	time_t now = time(0);
	const tm* tms = localtime(&now);
	int minutes = tms->tm_min;
	lightHour = (minutes * 1440) / 60;

	g_scheduler.addEvent(createSchedulerTask(EVENT_LIGHTINTERVAL, std::bind(&Game::checkLight, this)));
	g_scheduler.addEvent(createSchedulerTask(EVENT_CREATURE_THINK_INTERVAL, std::bind(&Game::checkCreatures, this, 0)));
	g_scheduler.addEvent(createSchedulerTask(EVENT_IMBUEMENTINTERVAL, std::bind(&Game::checkImbuements, this)));

}

GameState_t Game::getGameState() const
{
	return gameState;
}

void Game::setWorldType(WorldType_t type)
{
	worldType = type;
}

void Game::setGameState(GameState_t newState)
{
	if (gameState == GAME_STATE_SHUTDOWN) {
		return; //this cannot be stopped
	}

	if (gameState == newState) {
		return;
	}

	gameState = newState;
	switch (newState) {
		case GAME_STATE_INIT: {
			// carregando o valor dos itens no market
			loadItemsPrice();
			loadFreePass();

			loadPlayerSell();

			loadExperienceStages();
			loadSkillStages();
			loadMagicLevelStages();

			loadBoostMonster();
			groups.load();
			g_chat->load();
			uint64_t starttime = OTSYS_TIME(true);
			map.spawns.startup();
			std::cout << "> Loaded spawns in " << (OTSYS_TIME(true) - starttime) / (1000.) << " seconds." << std::endl;
			raids.loadFromXml();
			raids.startup();

			if(!g_config.getBoolean(ConfigManager::QUEST_LUA))
				quests.loadFromXml();

			mounts.loadFromXml();

			loadMotdNum();
			loadPlayersRecord();
			g_globalEvents->startup();
			break;
		}

		case GAME_STATE_SHUTDOWN: {
			g_globalEvents->execute(GLOBALEVENT_SHUTDOWN);

			//kick all players that are still online
			auto it = players.begin();
			while (it != players.end()) {
				it->second->kickPlayer(true);
				it = players.begin();
			}

			saveServeMessage();

			saveMotdNum();
			saveGameState();

			g_dispatcher.addTask(
				createTask(std::bind(&Game::shutdown, this)));

			g_scheduler.stop();
			g_databaseTasks.stop();
			g_dispatcher.stop();
			break;
		}

		case GAME_STATE_CLOSED: {
			/* kick all players without the CanAlwaysLogin flag */
			auto it = players.begin();
			while (it != players.end()) {
				if (!it->second->hasFlag(PlayerFlag_CanAlwaysLogin)) {
					it->second->kickPlayer(true);
					it = players.begin();
				} else {
					++it;
				}
			}

			saveGameState();
			break;
		}

		default:
			break;
	}
}

void Game::saveGameState(bool crash /*= false*/)
{
	if (gameState == GAME_STATE_NORMAL) {
		setGameState(GAME_STATE_MAINTAIN);
	}

	std::cout << "Saving server..." << " " << formatDate(OS_TIME(nullptr)) << std::endl;

	for (const auto& it : players) {
		if (crash) {
			// // caso precise
			// it.second->loginPosition = it.second->getTown()->getTemplePosition();
			std::cout << it.second->getName() << " Position: " << it.second->getPosition().getX() << ", " << it.second->getPosition().getY() << ", " << it.second->getPosition().getZ() << std::endl;
			it.second->loginPosition = it.second->getPosition();
		} else {
			it.second->loginPosition = it.second->getPosition();
		}

		IOLoginData::savePlayer(it.second);
	}

	Map::save();

	g_databaseTasks.flush();

	if (gameState == GAME_STATE_MAINTAIN) {
		setGameState(GAME_STATE_NORMAL);
	}
}

bool Game::loadMainMap(const std::string& filename)
{
	Monster::despawnRange = g_config.getNumber(ConfigManager::DEFAULT_DESPAWNRANGE);
	Monster::despawnRadius = g_config.getNumber(ConfigManager::DEFAULT_DESPAWNRADIUS);
	return map.loadMap("data/world/" + filename + ".otbm", true, Position());
}

void Game::loadMap(const std::string& path, const Position& relativePosition)
{
	map.loadMap(path, false, relativePosition);
}

bool Game::loadCustomSpawnFile(const std::string& fileName)
{
	return map.spawns.loadCustomSpawnXml(fileName);
}

Cylinder* Game::internalGetCylinder(Player* player, const Position& pos) const
{
	if (pos.x != 0xFFFF) {
		return map.getTile(pos);
	}

	//container
	if (pos.y & 0x40) {
		uint8_t from_cid = pos.y & 0x0F;
		return player->getContainerByID(from_cid);
	}

	//inventory
	return player;
}

Thing* Game::internalGetThing(Player* player, const Position& pos, int32_t index, uint32_t spriteId, stackPosType_t type) const
{
	if (pos.x != 0xFFFF) {
		Tile* tile = map.getTile(pos);
		if (!tile) {
			return nullptr;
		}

		Thing* thing;
		switch (type) {
			case STACKPOS_LOOK: {
				return tile->getTopVisibleThing(player);
			}

			case STACKPOS_MOVE: {
				Item* item = tile->getTopDownItem();
				if (item && item->isMoveable()) {
					thing = item;
				} else {
					thing = tile->getTopVisibleCreature(player);
				}
				break;
			}

			case STACKPOS_USEITEM: {
				thing = tile->getUseItem(index);
				break;
			}

			case STACKPOS_TOPDOWN_ITEM: {
				thing = tile->getTopDownItem();
				break;
			}

			case STACKPOS_USETARGET: {
				thing = tile->getTopVisibleCreature(player);
				if (!thing) {
					thing = tile->getUseItem(index);
				}
				break;
			}


			case STACKPOS_FIND_THING: {
				thing = tile->getUseItem(index);
				if (!thing) {
					thing = tile->getDoorItem();
				}

				if (!thing) {
					thing = tile->getTopDownItem();
				}

				break;
			}

			default: {
				thing = nullptr;
				break;
			}
		}

		if (player && tile->hasFlag(TILESTATE_SUPPORTS_HANGABLE)) {
			//do extra checks here if the thing is accessable
			if (thing && thing->getItem()) {
				if (tile->hasProperty(CONST_PROP_ISVERTICAL)) {
					if (player->getPosition().x + 1 == tile->getPosition().x) {
						thing = nullptr;
					}
				} else { // horizontal
					if (player->getPosition().y + 1 == tile->getPosition().y) {
						thing = nullptr;
					}
				}
			}
		}
		return thing;
	}

	//container
	if (pos.y & 0x40) {
		uint8_t fromCid = pos.y & 0x0F;

		Container* parentContainer = player->getContainerByID(fromCid);
		if (!parentContainer) {
			return nullptr;
		}

		if (parentContainer->getID() == ITEM_BROWSEFIELD) {
			Tile* tile = parentContainer->getTile();
			if (tile && tile->hasFlag(TILESTATE_SUPPORTS_HANGABLE)) {
				if (tile->hasProperty(CONST_PROP_ISVERTICAL)) {
					if (player->getPosition().x + 1 == tile->getPosition().x) {
						return nullptr;
					}
				} else { // horizontal
					if (player->getPosition().y + 1 == tile->getPosition().y) {
						return nullptr;
					}
				}
			}
		}

		uint8_t slot = pos.z;
		return parentContainer->getItemByIndex(player->getContainerIndex(fromCid) + slot);
	} else if (pos.y == 0 && pos.z == 0) {
		const ItemType& it = Item::items.getItemIdByClientId(spriteId);
		if (it.id == 0) {
			return nullptr;
		}

		int32_t subType;
		if (it.isFluidContainer() && index < static_cast<int32_t>(sizeof(reverseFluidMap) / sizeof(uint8_t))) {
			subType = reverseFluidMap[index];
		} else {
			subType = -1;
		}

		return findItemOfType(player, it.id, true, subType);
	}

	//inventory
	slots_t slot = static_cast<slots_t>(pos.y);
	return player->getInventoryItem(slot);
}

void Game::internalGetPosition(Item* item, Position& pos, uint8_t& stackpos)
{
	pos.x = 0;
	pos.y = 0;
	pos.z = 0;
	stackpos = 0;

	Cylinder* topParent = item->getTopParent();
	if (topParent) {
		if (Player* player = dynamic_cast<Player*>(topParent)) {
			pos.x = 0xFFFF;

			Container* container = dynamic_cast<Container*>(item->getParent());
			if (container) {
				pos.y = static_cast<uint16_t>(0x40) | static_cast<uint16_t>(player->getContainerID(container));
				pos.z = container->getThingIndex(item);
				stackpos = pos.z;
			} else {
				pos.y = player->getThingIndex(item);
				stackpos = pos.y;
			}
		} else if (Tile* tile = topParent->getTile()) {
			pos = tile->getPosition();
			stackpos = tile->getThingIndex(item);
		}
	}
}

Creature* Game::getCreatureByID(uint32_t id)
{
	if (id <= Player::maxPlayerAutoID) {
		return getPlayerByID(id);
	} else if (id <= Monster::monsterAutoID) {
		return getMonsterByID(id);
	} else if (id <= Npc::npcAutoID) {
		return getNpcByID(id);
	}
	return nullptr;
}

Creature* Game::getCreatureByCombatID(uint32_t id)
{
	if (id <= Player::maxPlayerAutoID) {
		return getPlayerByCombatID(id);
	} else if (id <= Monster::monsterAutoID) {
		return getMonsterByID(id);
	} else if (id <= Npc::npcAutoID) {
		return getNpcByID(id);
	}
	return nullptr;
}

Monster* Game::getMonsterByID(uint32_t id)
{
	if (id == 0) {
		return nullptr;
	}

	auto it = monsters.find(id);
	if (it == monsters.end()) {
		return nullptr;
	}
	return it->second;
}

Npc* Game::getNpcByID(uint32_t id)
{
	if (id == 0) {
		return nullptr;
	}

	auto it = npcs.find(id);
	if (it == npcs.end()) {
		return nullptr;
	}
	return it->second;
}

Player* Game::getPlayerByID(uint32_t id)
{
	if (id == 0) {
		return nullptr;
	}

	auto it = players.find(id);
	if (it == players.end()) {
		return nullptr;
	}
	return it->second;
}

Player* Game::getPlayerByCombatID(uint32_t id)
{
	if (id == 0) {
		return nullptr;
	}

	auto it = playersCombat.find(id);
	if (it == playersCombat.end()) {
		return nullptr;
	}
	return it->second;
}

Creature* Game::getCreatureByName(const std::string& s)
{
	if (s.empty()) {
		return nullptr;
	}

	const std::string& lowerCaseName = asLowerCaseString(s);

	auto m_it = mappedPlayerNames.find(lowerCaseName);
	if (m_it != mappedPlayerNames.end()) {
		return m_it->second;
	}

	for (const auto& it : npcs) {
		if (lowerCaseName == asLowerCaseString(it.second->getName())) {
			return it.second;
		}
	}

	for (const auto& it : monsters) {
		if (lowerCaseName == asLowerCaseString(it.second->getName())) {
			return it.second;
		}
	}
	return nullptr;
}

Npc* Game::getNpcByName(const std::string& s)
{
	if (s.empty()) {
		return nullptr;
	}

	const char* npcName = s.c_str();
	for (const auto& it : npcs) {
		if (strcasecmp(npcName, it.second->getName().c_str()) == 0) {
			return it.second;
		}
	}
	return nullptr;
}

Player* Game::getPlayerByName(const std::string& s)
{
	if (s.empty()) {
		return nullptr;
	}

	auto it = mappedPlayerNames.find(asLowerCaseString(s));
	if (it == mappedPlayerNames.end()) {
		return nullptr;
	}
	return it->second;
}

Player* Game::getPlayerByGUID(const uint32_t& guid)
{
	if (guid == 0) {
		return nullptr;
	}

	auto it = mappedPlayerGuids.find(guid);
	if (it == mappedPlayerGuids.end()) {
		return nullptr;
	}

	return it->second;
}

ReturnValue Game::getPlayerByNameWildcard(const std::string& s, Player*& player)
{
	size_t strlen = s.length();
	if (strlen == 0 || strlen > 30) {
		return RETURNVALUE_PLAYERWITHTHISNAMEISNOTONLINE;
	}

	if (s.back() == '~') {
		const std::string& query = asLowerCaseString(s.substr(0, strlen - 1));
		std::string result;
		ReturnValue ret = wildcardTree.findOne(query, result);
		if (ret != RETURNVALUE_NOERROR) {
			return ret;
		}

		player = getPlayerByName(result);
	} else {
		player = getPlayerByName(s);
	}

	if (!player) {
		return RETURNVALUE_PLAYERWITHTHISNAMEISNOTONLINE;
	}

	return RETURNVALUE_NOERROR;
}

Player* Game::getPlayerByAccount(uint32_t acc)
{
	for (const auto& it : players) {
		if (it.second->getAccount() == acc) {
			return it.second;
		}
	}
	return nullptr;
}

bool Game::internalPlaceCreature(Creature* creature, const Position& pos, bool extendedPos /*=false*/, bool forced /*= false*/)
{
	if (creature->getParent() != nullptr) {
		return false;
	}

	if (!map.placeCreature(pos, creature, extendedPos, forced)) {
		return false;
	}

	creature->incrementReferenceCounter();
	creature->setID();
	creature->addList();
	return true;
}

bool Game::placeCreature(Creature* creature, const Position& pos, bool extendedPos /*=false*/, bool forced /*= false*/, Creature* master)
{
	if (!internalPlaceCreature(creature, pos, extendedPos, forced)) {
		return false;
	}

	if (master) {
		creature->setMaster(master);
	}

	SpectatorHashSet spectators;
	map.getSpectators(spectators, creature->getPosition(), true);
	for (Creature* spectator : spectators) {
		if (Player* tmpPlayer = spectator->getPlayer()) {
			tmpPlayer->sendCreatureAppear(creature, creature->getPosition(), true);
		}
	}

	for (Creature* spectator : spectators) {
		spectator->onCreatureAppear(creature, true);
	}

	creature->getParent()->postAddNotification(creature, nullptr, 0);

	addCreatureCheck(creature);
	creature->onPlacedCreature();
	return true;
}

bool Game::removeCreature(Creature* creature, bool isLogout/* = true*/)
{
	if (creature->isRemoved()) {
		return false;
	}

	Tile* tile = creature->getTile();

	std::vector<int32_t> oldStackPosVector;

	SpectatorHashSet spectators;
	map.getSpectators(spectators, tile->getPosition(), true);
	for (Creature* spectator : spectators) {
		if (Player* player = spectator->getPlayer()) {
			oldStackPosVector.push_back(player->canSeeCreature(creature) ? tile->getStackposOfCreature(player, creature) : -1);
		}
	}

	tile->removeCreature(creature);

	const Position& tilePosition = tile->getPosition();

	//send to client
	size_t i = 0;
	for (Creature* spectator : spectators) {
		if (Player* player = spectator->getPlayer()) {
			player->sendRemoveTileThing(tilePosition, oldStackPosVector[i++]);
		}
	}

	//event method
	for (Creature* spectator : spectators) {
		spectator->onRemoveCreature(creature, isLogout);
	}

	creature->getParent()->postRemoveNotification(creature, nullptr, 0);

	creature->removeList();
	creature->setRemoved();
	ReleaseCreature(creature);

	removeCreatureCheck(creature);

	for (Creature* summon : creature->summons) {
		summon->setSkillLoss(false);
		removeCreature(summon);
	}
	return true;
}

void Game::playerMoveThing(uint32_t playerId, const Position& fromPos,
						   uint16_t spriteId, uint8_t fromStackPos, const Position& toPos, uint8_t count)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	if (player->hasCondition(CONDITION_EXHAUST, 1)) {
		player->sendTextMessage(MESSAGE_STATUS_SMALL, "You can't move item very fast.");
		return;
	}

	uint8_t fromIndex = 0;
	if (fromPos.x == 0xFFFF) {
		if (fromPos.y & 0x40) {
			fromIndex = fromPos.z;
		} else {
			fromIndex = static_cast<uint8_t>(fromPos.y);
		}
	} else {
		fromIndex = fromStackPos;
	}

	Thing* thing = internalGetThing(player, fromPos, fromIndex, 0, STACKPOS_MOVE);
	if (!thing) {
		player->sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
		return;
	}

	if (Creature* movingCreature = thing->getCreature()) {
		Tile* tile = map.getTile(toPos);
		if (!tile) {
			player->sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
			return;
		}

		if (Position::areInRange<1, 1, 0>(movingCreature->getPosition(), player->getPosition())) {
			SchedulerTask* task = createSchedulerTask(MOVE_CREATURE_INTERVAL,
								  std::bind(&Game::playerMoveCreatureByID, this, player->getID(),
											  movingCreature->getID(), movingCreature->getPosition(), tile->getPosition()));
			player->setNextActionPushTask(task);
		} else {
			playerMoveCreature(player, movingCreature, movingCreature->getPosition(), tile);
		}
	} else if (thing->getItem()) {
		Cylinder* toCylinder = internalGetCylinder(player, toPos);
		if (!toCylinder) {
			player->sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
			return;
		}

		playerMoveItem(player, fromPos, spriteId, fromStackPos, toPos, count, thing->getItem(), toCylinder);
	}
	if (Condition* moveItem = Condition::createCondition(CONDITIONID_DEFAULT, CONDITION_EXHAUST, 50, 0, false, 1)) {
		player->addCondition(moveItem);
	}
}

void Game::playerMoveCreatureByID(uint32_t playerId, uint32_t movingCreatureId, const Position& movingCreatureOrigPos, const Position& toPos)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	Creature* movingCreature = getCreatureByID(movingCreatureId);
	if (!movingCreature) {
		return;
	}

	Tile* toTile = map.getTile(toPos);
	if (!toTile) {
		player->sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
		return;
	}

	playerMoveCreature(player, movingCreature, movingCreatureOrigPos, toTile);
}

void Game::playerMoveCreature(Player* player, Creature* movingCreature, const Position& movingCreatureOrigPos, Tile* toTile)
{
	if (!player->canDoAction()) {
		uint32_t delay = player->getNextActionTime();
		SchedulerTask* task = createSchedulerTask(delay, std::bind(&Game::playerMoveCreatureByID,
			this, player->getID(), movingCreature->getID(), movingCreatureOrigPos, toTile->getPosition()));

		player->setNextActionPushTask(task);
		return;
	}

	player->setNextActionTask(nullptr);

	if (!Position::areInRange<1, 1, 0>(movingCreatureOrigPos, player->getPosition())) {
		//need to walk to the creature first before moving it
		std::forward_list<Direction> listDir;
		if (player->getPathTo(movingCreatureOrigPos, listDir, 0, 1, true, true)) {
			g_dispatcher.addTask(createTask(std::bind(&Game::playerAutoWalk,
											this, player->getID(), listDir)));

			SchedulerTask* task = createSchedulerTask(RANGE_MOVE_CREATURE_INTERVAL, std::bind(&Game::playerMoveCreatureByID, this,
				player->getID(), movingCreature->getID(), movingCreatureOrigPos, toTile->getPosition()));

			player->pushEvent(true);
			// g_scheduler.addEvent(task);

			player->setNextActionPushTask(task);
		} else {
			player->sendCancelMessage(RETURNVALUE_THEREISNOWAY);
		}
		return;
	}

	player->pushEvent(false);
	const Monster* monster = movingCreature->getMonster();
	bool isPet = false;
	if (monster) {
		isPet = monster->isPet();
	}

	if (!isPet && ((!movingCreature->isPushable() && !player->hasFlag(PlayerFlag_CanPushAllCreatures)) ||
				(movingCreature->isInGhostMode() && !player->isAccessPlayer()))) {
		player->sendCancelMessage(RETURNVALUE_NOTMOVEABLE);
		return;
	}

	//check throw distance
	const Position& movingCreaturePos = movingCreature->getPosition();
	const Position& toPos = toTile->getPosition();
	if ((Position::getDistanceX(movingCreaturePos, toPos) > movingCreature->getThrowRange()) || (Position::getDistanceY(movingCreaturePos, toPos) > movingCreature->getThrowRange()) || (Position::getDistanceZ(movingCreaturePos, toPos) * 4 > movingCreature->getThrowRange())) {
		player->sendCancelMessage(RETURNVALUE_DESTINATIONOUTOFREACH);
		return;
	}

	if (player != movingCreature) {
		if (toTile->hasFlag(TILESTATE_BLOCKPATH)) {
			player->sendCancelMessage(RETURNVALUE_NOTENOUGHROOM);
			return;
		} else if ((movingCreature->getZone() == ZONE_PROTECTION && !toTile->hasFlag(TILESTATE_PROTECTIONZONE)) || (movingCreature->getZone() == ZONE_NOPVP && !toTile->hasFlag(TILESTATE_NOPVPZONE))) {
			player->sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
			return;
		} else {
			if (CreatureVector* tileCreatures = toTile->getCreatures()) {
				for (Creature* tileCreature : *tileCreatures) {
					if (!tileCreature->isInGhostMode()) {
						player->sendCancelMessage(RETURNVALUE_NOTENOUGHROOM);
						return;
					}
				}
			}

			Npc* movingNpc = movingCreature->getNpc();
			if (movingNpc && !Spawns::isInZone(movingNpc->getMasterPos(), movingNpc->getMasterRadius(), toPos)) {
				player->sendCancelMessage(RETURNVALUE_NOTENOUGHROOM);
				return;
			}
		}

		movingCreature->setLastPosition(movingCreature->getPosition());
	}

	if (!g_events->eventPlayerOnMoveCreature(player, movingCreature, movingCreaturePos, toPos)) {
		return;
	}

	ReturnValue ret = internalMoveCreature(*movingCreature, *toTile);
	if (ret != RETURNVALUE_NOERROR) {
		player->sendCancelMessage(ret);
	}
	player->setLastPosition(player->getPosition());
}

ReturnValue Game::internalMoveCreature(Creature* creature, Direction direction, uint32_t flags /*= 0*/)
{
	creature->setLastPosition(creature->getPosition());
	const Position& currentPos = creature->getPosition();
	Position destPos = getNextPosition(direction, currentPos);
	Player* player = creature->getPlayer();

	bool diagonalMovement = (direction & DIRECTION_DIAGONAL_MASK) != 0;
	if (player && !diagonalMovement) {
		//try go up
		if (currentPos.z != 8 && creature->getTile()->hasHeight(3)) {
			Tile* tmpTile = map.getTile(currentPos.x, currentPos.y, currentPos.getZ() - 1);
			if (tmpTile == nullptr || (tmpTile->getGround() == nullptr && !tmpTile->hasFlag(TILESTATE_BLOCKSOLID))) {
				tmpTile = map.getTile(destPos.x, destPos.y, destPos.getZ() - 1);
				if (tmpTile && tmpTile->getGround() && !tmpTile->hasFlag(TILESTATE_BLOCKSOLID)) {
					flags |= FLAG_IGNOREBLOCKITEM | FLAG_IGNOREBLOCKCREATURE;

					if (!tmpTile->hasFlag(TILESTATE_FLOORCHANGE)) {
						player->setDirection(direction);
						destPos.z--;
					}
				}
			}
		}

		//try go down
		if (currentPos.z != 7 && currentPos.z == destPos.z) {
			Tile* tmpTile = map.getTile(destPos.x, destPos.y, destPos.z);
			if (tmpTile == nullptr || (tmpTile->getGround() == nullptr && !tmpTile->hasFlag(TILESTATE_BLOCKSOLID))) {
				tmpTile = map.getTile(destPos.x, destPos.y, destPos.z + 1);
				if (tmpTile && tmpTile->hasHeight(3)) {
					flags |= FLAG_IGNOREBLOCKITEM | FLAG_IGNOREBLOCKCREATURE;
					player->setDirection(direction);
					destPos.z++;
				}
			}
		}
	}

	Tile* toTile = map.getTile(destPos);
	if (!toTile) {
		return RETURNVALUE_NOTPOSSIBLE;
	}
	return internalMoveCreature(*creature, *toTile, flags);
}

ReturnValue Game::internalMoveCreature(Creature& creature, Tile& toTile, uint32_t flags /*= 0*/)
{
	//check if we can move the creature to the destination
	ReturnValue ret = toTile.queryAdd(0, creature, 1, flags);
	if (ret != RETURNVALUE_NOERROR) {
		return ret;
	}

	map.moveCreature(creature, toTile);
	if (creature.getParent() != &toTile) {
		return RETURNVALUE_NOERROR;
	}

	int32_t index = 0;
	Item* toItem = nullptr;
	Tile* subCylinder = nullptr;
	Tile* toCylinder = &toTile;
	Tile* fromCylinder = nullptr;
	uint32_t n = 0;

	while ((subCylinder = toCylinder->queryDestination(index, creature, &toItem, flags)) != toCylinder) {
		map.moveCreature(creature, *subCylinder);

		if (creature.getParent() != subCylinder) {
			//could happen if a script move the creature
			fromCylinder = nullptr;
			break;
		}

		fromCylinder = toCylinder;
		toCylinder = subCylinder;
		flags = 0;

		//to prevent infinite loop
		if (++n >= MAP_MAX_LAYERS) {
			break;
		}
	}

	if (fromCylinder) {
		const Position& fromPosition = fromCylinder->getPosition();
		const Position& toPosition = toCylinder->getPosition();
		if (fromPosition.z != toPosition.z && (fromPosition.x != toPosition.x || fromPosition.y != toPosition.y)) {
			Direction dir = getDirectionTo(fromPosition, toPosition);
			if ((dir & DIRECTION_DIAGONAL_MASK) == 0) {
				internalCreatureTurn(&creature, dir);
			}
		}
	}

	return RETURNVALUE_NOERROR;
}

void Game::playerMoveItemByPlayerID(uint32_t playerId, const Position& fromPos, uint16_t spriteId, uint8_t fromStackPos, const Position& toPos, uint8_t count)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}
	playerMoveItem(player, fromPos, spriteId, fromStackPos, toPos, count, nullptr, nullptr);
}

void Game::playerMoveItem(Player* player, const Position& fromPos,
						  uint16_t spriteId, uint8_t fromStackPos, const Position& toPos, uint8_t count, Item* item, Cylinder* toCylinder)
{
	if (!player->canDoAction()) {
		uint32_t delay = player->getNextActionTime();
		SchedulerTask* task = createSchedulerTask(delay, std::bind(&Game::playerMoveItemByPlayerID, this,
							  player->getID(), fromPos, spriteId, fromStackPos, toPos, count));
		player->setNextActionTask(task);
		return;
	}

	player->setNextActionTask(nullptr);

	if (item == nullptr) {
		uint8_t fromIndex = 0;
		if (fromPos.x == 0xFFFF) {
			if (fromPos.y & 0x40) {
				fromIndex = fromPos.z;
			} else {
				fromIndex = static_cast<uint8_t>(fromPos.y);
			}
		} else {
			fromIndex = fromStackPos;
		}

		Thing* thing = internalGetThing(player, fromPos, fromIndex, 0, STACKPOS_MOVE);
		if (!thing || !thing->getItem()) {
			player->sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
			return;
		}

		item = thing->getItem();
	}

	if (item->getClientID() != spriteId) {
		player->sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
		return;
	}

	Cylinder* fromCylinder = internalGetCylinder(player, fromPos);
	if (fromCylinder == nullptr) {
		player->sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
		return;
	}

	if (toCylinder == nullptr) {
		toCylinder = internalGetCylinder(player, toPos);
		if (toCylinder == nullptr) {
			player->sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
			return;
		}
	}

	if (!item->isPushable() || item->hasAttribute(ITEM_ATTRIBUTE_UNIQUEID)) {
		player->sendCancelMessage(RETURNVALUE_NOTMOVEABLE);
		return;
	}

	const Position& playerPos = player->getPosition();
	const Position& mapFromPos = fromCylinder->getTile()->getPosition();
	if (playerPos.z != mapFromPos.z) {
		player->sendCancelMessage(playerPos.z > mapFromPos.z ? RETURNVALUE_FIRSTGOUPSTAIRS : RETURNVALUE_FIRSTGODOWNSTAIRS);
		return;
	}

	if (!Position::areInRange<1, 1>(playerPos, mapFromPos)) {
		//need to walk to the item first before using it
		std::forward_list<Direction> listDir;
		if (player->getPathTo(item->getPosition(), listDir, 0, 1, true, true)) {
			g_dispatcher.addTask(createTask(std::bind(&Game::playerAutoWalk,
											this, player->getID(), listDir)));

			SchedulerTask* task = createSchedulerTask(RANGE_MOVE_ITEM_INTERVAL, std::bind(&Game::playerMoveItemByPlayerID, this,
								  player->getID(), fromPos, spriteId, fromStackPos, toPos, count));
			player->setNextWalkActionTask(task);
		} else {
			player->sendCancelMessage(RETURNVALUE_THEREISNOWAY);
		}
		return;
	}

	const Tile* toCylinderTile = toCylinder->getTile();
	const Position& mapToPos = toCylinderTile->getPosition();

	//hangable item specific code
	if (item->isHangable() && toCylinderTile->hasFlag(TILESTATE_SUPPORTS_HANGABLE)) {
		//destination supports hangable objects so need to move there first
		bool vertical = toCylinderTile->hasProperty(CONST_PROP_ISVERTICAL);
		if (vertical) {
			if (playerPos.x + 1 == mapToPos.x) {
				player->sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
				return;
			}
		} else { // horizontal
			if (playerPos.y + 1 == mapToPos.y) {
				player->sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
				return;
			}
		}

		if (!Position::areInRange<1, 1, 0>(playerPos, mapToPos)) {
			Position walkPos = mapToPos;
			if (vertical) {
				walkPos.x++;
			} else {
				walkPos.y++;
			}

			Position itemPos = fromPos;
			uint8_t itemStackPos = fromStackPos;

			if (fromPos.x != 0xFFFF && Position::areInRange<1, 1>(mapFromPos, playerPos)
					&& !Position::areInRange<1, 1, 0>(mapFromPos, walkPos)) {
				//need to pickup the item first
				Item* moveItem = nullptr;

				ReturnValue ret = internalMoveItem(fromCylinder, player, INDEX_WHEREEVER, item, count, &moveItem);
				if (ret != RETURNVALUE_NOERROR) {
					player->sendCancelMessage(ret);
					return;
				}

				//changing the position since its now in the inventory of the player
				internalGetPosition(moveItem, itemPos, itemStackPos);
			}

			std::forward_list<Direction> listDir;
			if (player->getPathTo(walkPos, listDir, 0, 0, true, true)) {
				g_dispatcher.addTask(createTask(std::bind(&Game::playerAutoWalk,
												this, player->getID(), listDir)));

				SchedulerTask* task = createSchedulerTask(RANGE_MOVE_ITEM_INTERVAL, std::bind(&Game::playerMoveItemByPlayerID, this,
									  player->getID(), itemPos, spriteId, itemStackPos, toPos, count));
				player->setNextWalkActionTask(task);
			} else {
				player->sendCancelMessage(RETURNVALUE_THEREISNOWAY);
			}
			return;
		}
	}

	if ((Position::getDistanceX(playerPos, mapToPos) > item->getThrowRange()) ||
			(Position::getDistanceY(playerPos, mapToPos) > item->getThrowRange()) ||
			(Position::getDistanceZ(mapFromPos, mapToPos) * 4 > item->getThrowRange())) {
		// player->sendCancelMessage(RETURNVALUE_DESTINATIONOUTOFREACH);
		return;
	}

	if (!canThrowObjectTo(mapFromPos, mapToPos)) {
		player->sendCancelMessage(RETURNVALUE_CANNOTTHROW);
		return;
	}

	if (!g_events->eventPlayerOnMoveItem(player, item, count, fromPos, toPos, fromCylinder, toCylinder)) {
		return;
	}

	uint8_t toIndex = 0;
	if (toPos.x == 0xFFFF) {
		if (toPos.y & 0x40) {
			toIndex = toPos.z;
		} else {
			toIndex = static_cast<uint8_t>(toPos.y);
		}
	}

	ReturnValue ret = internalMoveItem(fromCylinder, toCylinder, toIndex, item, count, nullptr, 0, player);
	if (ret != RETURNVALUE_NOERROR) {
		player->sendCancelMessage(ret);
	} else {
		// cancelando o push
		player->cancelPush();

		g_events->eventPlayerOnItemMoved(player, item, count, fromPos, toPos, fromCylinder, toCylinder);
	}
}

ReturnValue Game::internalMoveItem(Cylinder* fromCylinder, Cylinder* toCylinder, int32_t index,
								   Item* item, uint32_t count, Item** _moveItem, uint32_t flags /*= 0*/, Creature* actor/* = nullptr*/, Item* tradeItem/* = nullptr*/)
{
	Tile* fromTile = fromCylinder->getTile();
	if (fromTile) {
		auto it = browseFields.find(fromTile);
		if (it != browseFields.end() && it->second == fromCylinder) {
			fromCylinder = fromTile;
		}
	}

	Item* toItem = nullptr;

	Cylinder* subCylinder;
	int floorN = 0;

	while ((subCylinder = toCylinder->queryDestination(index, *item, &toItem, flags)) != toCylinder) {
		toCylinder = subCylinder;
		flags = 0;

		//to prevent infinite loop
		if (++floorN >= MAP_MAX_LAYERS) {
			break;
		}
	}

	//destination is the same as the source?
	if (item == toItem) {
		return RETURNVALUE_NOERROR; //silently ignore move
	}

	//check if we can add this item
	ReturnValue ret = toCylinder->queryAdd(index, *item, count, flags, actor);
	if (ret == RETURNVALUE_NEEDEXCHANGE) {
		//check if we can add it to source cylinder
		ret = fromCylinder->queryAdd(fromCylinder->getThingIndex(item), *toItem, toItem->getItemCount(), 0);
		if (ret == RETURNVALUE_NOERROR) {
			//check how much we can move
			uint32_t maxExchangeQueryCount = 0;
			ReturnValue retExchangeMaxCount = fromCylinder->queryMaxCount(INDEX_WHEREEVER, *toItem, toItem->getItemCount(), maxExchangeQueryCount, 0);

			if (retExchangeMaxCount != RETURNVALUE_NOERROR && maxExchangeQueryCount == 0) {
				return retExchangeMaxCount;
			}

			if (toCylinder->queryRemove(*toItem, toItem->getItemCount(), flags) == RETURNVALUE_NOERROR) {
				int32_t oldToItemIndex = toCylinder->getThingIndex(toItem);
				toCylinder->removeThing(toItem, toItem->getItemCount());
				fromCylinder->addThing(toItem);

				if (oldToItemIndex != -1) {
					toCylinder->postRemoveNotification(toItem, fromCylinder, oldToItemIndex);
				}

				int32_t newToItemIndex = fromCylinder->getThingIndex(toItem);
				if (newToItemIndex != -1) {
					fromCylinder->postAddNotification(toItem, toCylinder, newToItemIndex);
				}

				ret = toCylinder->queryAdd(index, *item, count, flags);
				toItem = nullptr;
			}
		}
	}

	if (ret != RETURNVALUE_NOERROR) {
		return ret;
	}

	//check how much we can move
	uint32_t maxQueryCount = 0;
	ReturnValue retMaxCount = toCylinder->queryMaxCount(index, *item, count, maxQueryCount, flags);
	if (retMaxCount != RETURNVALUE_NOERROR && maxQueryCount == 0) {
		return retMaxCount;
	}

	uint32_t m;
	if (item->isStackable()) {
		m = std::min<uint32_t>(count, maxQueryCount);
		if (m == 255) {
			m = item->getItemCount();
		}
	} else {
		m = maxQueryCount;
	}

	Item* moveItem = item;
	bool itemDecays = item->canDecay();
	//check if we can remove this item
	ret = fromCylinder->queryRemove(*item, m, flags);
	if (ret != RETURNVALUE_NOERROR) {
		return ret;
	}

	if (tradeItem) {
		if (toCylinder->getItem() == tradeItem) {
			return RETURNVALUE_NOTENOUGHROOM;
		}

		Cylinder* tmpCylinder = toCylinder->getParent();
		while (tmpCylinder) {
			if (tmpCylinder->getItem() == tradeItem) {
				return RETURNVALUE_NOTENOUGHROOM;
			}

			tmpCylinder = tmpCylinder->getParent();
		}
	}

	//remove the item
	int32_t itemIndex = fromCylinder->getThingIndex(item);
	Item* updateItem = nullptr;
	fromCylinder->removeThing(item, m);

	//update item(s)
	if (item->isStackable()) {
		uint32_t n;
		uint32_t duration;
		if (item->equals(toItem)) {
			duration = std::min<uint32_t>(item->getDuration(), toItem->getDuration());
			n = std::min<uint32_t>(100 - toItem->getItemCount(), m);
			toCylinder->updateThing(toItem, toItem->getID(), toItem->getItemCount() + n);
			if (static_cast<uint32_t>(toItem->getDuration()) > duration){ //punishing the duppers with the minimum time
				toItem->setDuration(duration);
			}
			updateItem = toItem;
		} else {
			n = 0;
		}

		int32_t newCount = m - n;
		if (newCount > 0) {
			moveItem = item->clone();
			moveItem->setItemCount(newCount);
		} else {
			moveItem = nullptr;
		}

		if (item->isRemoved()) {
			item->stopDecaying();
			ReleaseItem(item);
		}
	}

	//add item
	if (moveItem /*m - n > 0*/) {
		toCylinder->addThing(index, moveItem);
		if (itemDecays && moveItem->getDecaying() != DECAYING_TRUE) {
			moveItem->startDecaying();
		}
	}

	if (itemIndex != -1) {
		fromCylinder->postRemoveNotification(item, toCylinder, itemIndex);
	}

	if (moveItem) {
		int32_t moveItemIndex = toCylinder->getThingIndex(moveItem);
		if (moveItemIndex != -1) {
			toCylinder->postAddNotification(moveItem, fromCylinder, moveItemIndex);
		}
		moveItem->startDecaying();
	}

	if (updateItem) {
		int32_t updateItemIndex = toCylinder->getThingIndex(updateItem);
		if (updateItemIndex != -1) {
			toCylinder->postAddNotification(updateItem, fromCylinder, updateItemIndex);
		}
		updateItem->startDecaying();
	}

	if (_moveItem) {
		if (moveItem) {
			*_moveItem = moveItem;
		} else {
			*_moveItem = item;
		}
	}
    
	Item* quiver = toCylinder->getItem();
  if (quiver && quiver->getWeaponType() == WEAPON_QUIVER && quiver->getHoldingPlayer() && quiver->getHoldingPlayer()->getThing(CONST_SLOT_RIGHT) == quiver) {
    quiver->getHoldingPlayer()->sendInventoryItem(CONST_SLOT_RIGHT, quiver);
  }
  else {
    quiver = fromCylinder->getItem();
    if (quiver && quiver->getWeaponType() == WEAPON_QUIVER && quiver->getHoldingPlayer() && quiver->getHoldingPlayer()->getThing(CONST_SLOT_RIGHT) == quiver) {
      quiver->getHoldingPlayer()->sendInventoryItem(CONST_SLOT_RIGHT, quiver);
    }
  }
  
	//we could not move all, inform the player
	if (item->isStackable() && maxQueryCount < count) {
		return retMaxCount;
	}

	return ret;
}

ReturnValue Game::internalAddItem(Cylinder* toCylinder, Item* item, int32_t index /*= INDEX_WHEREEVER*/,
								  uint32_t flags/* = 0*/, bool test/* = false*/)
{
	uint32_t remainderCount = 0;
	return internalAddItem(toCylinder, item, index, flags, test, remainderCount);
}

ReturnValue Game::internalAddItem(Cylinder* toCylinder, Item* item, int32_t index,
								  uint32_t flags, bool test, uint32_t& remainderCount)
{
	if (toCylinder == nullptr || item == nullptr) {
		return RETURNVALUE_NOTPOSSIBLE;
	}

	Cylinder* destCylinder = toCylinder;
	Item* toItem = nullptr;
	toCylinder = toCylinder->queryDestination(index, *item, &toItem, flags);

	//check if we can add this item
	ReturnValue ret = toCylinder->queryAdd(index, *item, item->getItemCount(), flags);
	if (ret != RETURNVALUE_NOERROR) {
		return ret;
	}

	/*
	Check if we can move add the whole amount, we do this by checking against the original cylinder,
	since the queryDestination can return a cylinder that might only hold a part of the full amount.
	*/
	uint32_t maxQueryCount = 0;
	ret = destCylinder->queryMaxCount(INDEX_WHEREEVER, *item, item->getItemCount(), maxQueryCount, flags);

	if (ret != RETURNVALUE_NOERROR && toCylinder->getItem() && toCylinder->getItem()->getID() != ITEM_REWARD_CONTAINER) {
		return ret;
	}

	if (test) {
		return RETURNVALUE_NOERROR;
	}

	if (item->isStackable() && item->equals(toItem)) {
		uint32_t m = std::min<uint32_t>(item->getItemCount(), maxQueryCount);
		uint32_t n = std::min<uint32_t>(100 - toItem->getItemCount(), m);

		toCylinder->updateThing(toItem, toItem->getID(), toItem->getItemCount() + n);

		int32_t count = m - n;
		if (count > 0) {
			if (item->getItemCount() != count) {
				Item* remainderItem = item->clone();
				remainderItem->setItemCount(count);
				if (internalAddItem(destCylinder, remainderItem, INDEX_WHEREEVER, flags, false) != RETURNVALUE_NOERROR) {
					ReleaseItem(remainderItem);
					remainderCount = count;
				}
			} else {
				toCylinder->addThing(index, item);

				int32_t itemIndex = toCylinder->getThingIndex(item);
				if (itemIndex != -1) {
					toCylinder->postAddNotification(item, nullptr, itemIndex);
				}
			}
		} else {
			//fully merged with toItem, item will be destroyed
			item->onRemoved();
			ReleaseItem(item);

			int32_t itemIndex = toCylinder->getThingIndex(toItem);
			if (itemIndex != -1) {
				toCylinder->postAddNotification(toItem, nullptr, itemIndex);
			}
		}
	} else {
		Tile* tile = dynamic_cast<Tile*>(toCylinder);
		if (tile) {
			// std::cout << "Tile " << std::endl;
		}
		Player* player = dynamic_cast<Player*>(toCylinder);
		if (player && index <= 0) {
			// std::cout << "Player " << std::endl;
			return RETURNVALUE_NOTENOUGHROOM;
		}
		Container* container = dynamic_cast<Container*>(toCylinder);
		if (container) {
			// std::cout << "Container " << std::endl;
		}
		// std::cout << index << std::endl;
		toCylinder->addThing(index, item);

		int32_t itemIndex = toCylinder->getThingIndex(item);
		if (itemIndex != -1 && item != nullptr) {
			toCylinder->postAddNotification(item, nullptr, itemIndex);
		}
	}
	
	Item* quiver = toCylinder->getItem();
    if (quiver && quiver->getWeaponType() == WEAPON_QUIVER && quiver->getHoldingPlayer() && quiver->getHoldingPlayer()->getThing(CONST_SLOT_RIGHT) == quiver) {
      quiver->getHoldingPlayer()->sendInventoryItem(CONST_SLOT_RIGHT, quiver);
    }

	return RETURNVALUE_NOERROR;
}

ReturnValue Game::internalRemoveItem(Item* item, int32_t count /*= -1*/, bool test /*= false*/, uint32_t flags /*= 0*/)
{
	Cylinder* cylinder = item->getParent();
	if (cylinder == nullptr) {
		return RETURNVALUE_NOTPOSSIBLE;
	}

	Tile* fromTile = cylinder->getTile();
	if (fromTile) {
		auto it = browseFields.find(fromTile);
		if (it != browseFields.end() && it->second == cylinder) {
			cylinder = fromTile;
		}
	}

	if (count == -1) {
		count = item->getItemCount();
	}

	//check if we can remove this item
	ReturnValue ret = cylinder->queryRemove(*item, count, flags | FLAG_IGNORENOTMOVEABLE);
	if (ret != RETURNVALUE_NOERROR) {
		return ret;
	}

	if (!item->canRemove()) {
		return RETURNVALUE_NOTPOSSIBLE;
	}

	if (!test) {
		int32_t index = cylinder->getThingIndex(item);

		//remove the item
		cylinder->removeThing(item, count);

		if (item->isRemoved()) {
			item->onRemoved();
			item->stopDecaying();
			if (item->canDecay()) {
				toDecayItems.remove(item);
			}
			ReleaseItem(item);
		}

		cylinder->postRemoveNotification(item, nullptr, index);
	}
	Item* quiver = cylinder->getItem();
    if (quiver && quiver->getWeaponType() == WEAPON_QUIVER && quiver->getHoldingPlayer() && quiver->getHoldingPlayer()->getThing(CONST_SLOT_RIGHT) == quiver) {
      quiver->getHoldingPlayer()->sendInventoryItem(CONST_SLOT_RIGHT, quiver);
    }

	return RETURNVALUE_NOERROR;
}

ReturnValue Game::internalPlayerAddItem(Player* player, Item* item, bool dropOnMap /*= true*/, slots_t slot /*= CONST_SLOT_WHEREEVER*/)
{
	uint32_t remainderCount = 0;
	ReturnValue ret = internalAddItem(player, item, static_cast<int32_t>(slot), 0, false, remainderCount);
	if (remainderCount != 0) {
		Item* remainderItem = Item::CreateItem(item->getID(), remainderCount);
		ReturnValue remaindRet = internalAddItem(player->getTile(), remainderItem, INDEX_WHEREEVER, FLAG_NOLIMIT);
		if (remaindRet != RETURNVALUE_NOERROR) {
			ReleaseItem(remainderItem);
		}
	}

	if (ret != RETURNVALUE_NOERROR && dropOnMap) {
		ret = internalAddItem(player->getTile(), item, INDEX_WHEREEVER, FLAG_NOLIMIT);
	}

	return ret;
}

Item* Game::findItemOfType(Cylinder* cylinder, uint16_t itemId,
						   bool depthSearch /*= true*/, int32_t subType /*= -1*/) const
{
	if (cylinder == nullptr) {
		return nullptr;
	}

	std::vector<Container*> containers;
	for (size_t i = cylinder->getFirstIndex(), j = cylinder->getLastIndex(); i < j; ++i) {
		Thing* thing = cylinder->getThing(i);
		if (!thing) {
			continue;
		}

		Item* item = thing->getItem();
		if (!item) {
			continue;
		}

		if (item->getID() == itemId && (subType == -1 || subType == item->getSubType())) {
			return item;
		}

		if (depthSearch) {
			Container* container = item->getContainer();
			if (container) {
				containers.push_back(container);
			}
		}
	}

	size_t i = 0;
	while (i < containers.size()) {
		Container* container = containers[i++];
		for (Item* item : container->getItemList()) {
			if (item->getID() == itemId && (subType == -1 || subType == item->getSubType())) {
				return item;
			}

			Container* subContainer = item->getContainer();
			if (subContainer) {
				containers.push_back(subContainer);
			}
		}
	}
	return nullptr;
}

bool Game::removeMoney(Cylinder* cylinder, uint64_t money, uint32_t flags /*= 0*/, bool useBalance /*= false*/)
{
	if (cylinder == nullptr) {
		return false;
	}

	if (money == 0) {
		return true;
	}

	std::vector<Container*> containers;

	std::multimap<uint32_t, Item*> moneyMap;
	uint64_t moneyCount = 0;

	for (size_t i = cylinder->getFirstIndex(), j = cylinder->getLastIndex(); i < j; ++i) {
		Thing* thing = cylinder->getThing(i);
		if (!thing) {
			continue;
		}

		Item* item = thing->getItem();
		if (!item) {
			continue;
		}

		Container* container = item->getContainer();
		if (container) {
			containers.push_back(container);
		} else {
			const uint32_t worth = item->getWorth();
			if (worth != 0) {
				moneyCount += worth;
				moneyMap.emplace(worth, item);
			}
		}
	}

	size_t i = 0;
	while (i < containers.size()) {
		Container* container = containers[i++];
		for (Item* item : container->getItemList()) {
			Container* tmpContainer = item->getContainer();
			if (tmpContainer) {
				containers.push_back(tmpContainer);
			} else {
				const uint32_t worth = item->getWorth();
				if (worth != 0) {
					moneyCount += worth;
					moneyMap.emplace(worth, item);
				}
			}
		}
	}

	Player* player = useBalance ? dynamic_cast<Player*>(cylinder) : nullptr;
	uint64_t balance = 0;
	if (useBalance && player) {
		balance = player->getBankBalance();
	}

	if (moneyCount + balance < money) {
		return false;
	}

	for (const auto& moneyEntry : moneyMap) {
		Item* item = moneyEntry.second;
		if (moneyEntry.first < money) {
			internalRemoveItem(item);
			money -= moneyEntry.first;
		} else if (moneyEntry.first > money) {
			const uint32_t worth = moneyEntry.first / item->getItemCount();
			const uint32_t removeCount = std::ceil(money / static_cast<double>(worth));

			addMoney(cylinder, (worth * removeCount) - money, flags);
			internalRemoveItem(item, removeCount);
			break;
		} else {
			internalRemoveItem(item);
			break;
		}
	}

	if (useBalance && player && player->getBankBalance() >= money) {
		player->setBankBalance(player->getBankBalance() - money);
	}
		
	return true;
}

void Game::addMoney(Cylinder* cylinder, uint64_t money, uint32_t flags /*= 0*/)
{
	if (money == 0) {
		return;
	}

	uint32_t crystalCoins = money / 10000;
	money -= crystalCoins * 10000;
	while (crystalCoins > 0) {
		const uint16_t count = std::min<uint32_t>(100, crystalCoins);

		Item* remaindItem = Item::CreateItem(ITEM_CRYSTAL_COIN, count);

		ReturnValue ret = internalAddItem(cylinder, remaindItem, INDEX_WHEREEVER, flags);
		if (ret != RETURNVALUE_NOERROR) {
			internalAddItem(cylinder->getTile(), remaindItem, INDEX_WHEREEVER, FLAG_NOLIMIT);
		}

		crystalCoins -= count;
	}

	uint16_t platinumCoins = money / 100;
	if (platinumCoins != 0) {
		Item* remaindItem = Item::CreateItem(ITEM_PLATINUM_COIN, platinumCoins);

		ReturnValue ret = internalAddItem(cylinder, remaindItem, INDEX_WHEREEVER, flags);
		if (ret != RETURNVALUE_NOERROR) {
			internalAddItem(cylinder->getTile(), remaindItem, INDEX_WHEREEVER, FLAG_NOLIMIT);
		}

		money -= platinumCoins * 100;
	}

	if (money != 0) {
		Item* remaindItem = Item::CreateItem(ITEM_GOLD_COIN, money);

		ReturnValue ret = internalAddItem(cylinder, remaindItem, INDEX_WHEREEVER, flags);
		if (ret != RETURNVALUE_NOERROR) {
			internalAddItem(cylinder->getTile(), remaindItem, INDEX_WHEREEVER, FLAG_NOLIMIT);
		}
	}
}

Item* Game::transformItem(Item* item, uint16_t newId, int32_t newCount /*= -1*/)
{
	if (item->getID() == newId && (newCount == -1 || (newCount == item->getSubType() && newCount != 0))) { //chargeless item placed on map = infinite
		return item;
	}

	Cylinder* cylinder = item->getParent();
	if (cylinder == nullptr) {
		return nullptr;
	}

	Tile* fromTile = cylinder->getTile();
	if (fromTile) {
		auto it = browseFields.find(fromTile);
		if (it != browseFields.end() && it->second == cylinder) {
			cylinder = fromTile;
		}
	}

	int32_t itemIndex = cylinder->getThingIndex(item);
	if (itemIndex == -1) {
		return item;
	}

	if (!item->canTransform()) {
		return item;
	}

	const ItemType& newType = Item::items[newId];
	if (newType.id == 0) {
		return item;
	}

	const ItemType& curType = Item::items[item->getID()];
	if (curType.alwaysOnTop != newType.alwaysOnTop) {
		//This only occurs when you transform items on tiles from a downItem to a topItem (or vice versa)
		//Remove the old, and add the new
		cylinder->removeThing(item, item->getItemCount());
		cylinder->postRemoveNotification(item, cylinder, itemIndex);

		item->setID(newId);
		if (newCount != -1) {
			item->setSubType(newCount);
		}
		cylinder->addThing(item);

		Cylinder* newParent = item->getParent();
		if (newParent == nullptr) {
			item->stopDecaying();
			ReleaseItem(item);
			return nullptr;
		}

		newParent->postAddNotification(item, cylinder, newParent->getThingIndex(item));
		item->startDecaying();
		return item;
	}

	if (curType.type == newType.type) {
		//Both items has the same type so we can safely change id/subtype
		if (newCount == 0 && (item->isStackable() || item->hasAttribute(ITEM_ATTRIBUTE_CHARGES))) {
			if (item->isStackable()) {
				internalRemoveItem(item);
				return nullptr;
			} else {
				int32_t newItemId = newId;
				if (curType.id == newType.id) {
					newItemId = curType.decayTo;
				}

				if (newItemId <= 0) {
					internalRemoveItem(item);
					return nullptr;
				} else if (newItemId != newId) {
					//Replacing the the old item with the new while maintaining the old position
					Item* newItem = Item::CreateItem(newItemId, 1);
					if (newItem == nullptr) {
						return nullptr;
					}

					cylinder->replaceThing(itemIndex, newItem);
					cylinder->postAddNotification(newItem, cylinder, itemIndex);

					item->setParent(nullptr);
					cylinder->postRemoveNotification(item, cylinder, itemIndex);
					item->stopDecaying();
					ReleaseItem(item);
					newItem->startDecaying();
					return newItem;
				} else {
					return transformItem(item, newItemId);
				}
			}
		} else {
			uint32_t currentDuration = item->getDuration();

			cylinder->postRemoveNotification(item, cylinder, itemIndex);
			uint16_t itemId = item->getID();
			int32_t count = item->getSubType();

			if (curType.id != newType.id) {
				if (newType.group != curType.group) {
					item->setDefaultSubtype();
				}

				itemId = newId;
			}

			if (newCount != -1 && newType.hasSubType()) {
				count = newCount;
			}

			cylinder->updateThing(item, itemId, count);
			if (currentDuration) {
				item->setDuration(currentDuration);
			}
			cylinder->postAddNotification(item, cylinder, itemIndex);
			item->startDecaying();
			Item* quiver = cylinder->getItem();
            if (quiver && quiver->getWeaponType() == WEAPON_QUIVER && quiver->getHoldingPlayer() && quiver->getHoldingPlayer()->getThing(CONST_SLOT_RIGHT) == quiver) {
              quiver->getHoldingPlayer()->sendInventoryItem(CONST_SLOT_RIGHT, quiver);
            }

			return item;
		}
	}

	//Replacing the the old item with the new while maintaining the old position
	Item* newItem;
	if (newCount == -1) {
		newItem = Item::CreateItem(newId);
	} else {
		newItem = Item::CreateItem(newId, newCount);
	}

	if (newItem == nullptr) {
		return nullptr;
	}

	cylinder->replaceThing(itemIndex, newItem);
	cylinder->postAddNotification(newItem, cylinder, itemIndex);

	item->setParent(nullptr);
	cylinder->postRemoveNotification(item, cylinder, itemIndex);
	item->stopDecaying();
	ReleaseItem(item);
	
	Item* quiver = cylinder->getItem();
    if (quiver && quiver->getWeaponType() == WEAPON_QUIVER && quiver->getHoldingPlayer() && quiver->getHoldingPlayer()->getThing(CONST_SLOT_RIGHT) == quiver) {
      quiver->getHoldingPlayer()->sendInventoryItem(CONST_SLOT_RIGHT, quiver);
    }

	newItem->startDecaying();

	return newItem;
}

ReturnValue Game::internalTeleport(Thing* thing, const Position& newPos, bool pushMove/* = true*/, uint32_t flags /*= 0*/)
{
	if (newPos == thing->getPosition()) {
		return RETURNVALUE_NOERROR;
	} else if (thing->isRemoved()) {
		return RETURNVALUE_NOTPOSSIBLE;
	}

	Tile* toTile = map.getTile(newPos);
	if (!toTile) {
		return RETURNVALUE_NOTPOSSIBLE;
	}

	if (Creature* creature = thing->getCreature()) {
		ReturnValue ret = toTile->queryAdd(0, *creature, 1, FLAG_NOLIMIT);
		if (ret != RETURNVALUE_NOERROR) {
			return ret;
		}

		map.moveCreature(*creature, *toTile, !pushMove);
		return RETURNVALUE_NOERROR;
	} else if (Item* item = thing->getItem()) {
		return internalMoveItem(item->getParent(), toTile, INDEX_WHEREEVER, item, item->getItemCount(), nullptr, flags);
	}
	return RETURNVALUE_NOTPOSSIBLE;
}

void Game::internalQuickLootCorpse(Player* player, Container* corpse)
{
	std::vector<Item*> itemList;
	bool ignoreListItems = (player->getProtocolVersion() >= 1150 ? player->quickLootFilter == QUICKLOOTFILTER_SKIPPEDLOOT : false);

	bool missedAnyGold = false;
	bool missedAnyItem = false;

	for (ContainerIterator it = corpse->iterator(); it.hasNext(); it.advance()) {
		Item* item = *it;
		bool listed = player->isQuickLootListedItem(item);
		if ((listed && ignoreListItems) || (!listed && !ignoreListItems)) {
			if (item->getWorth() != 0) {
				missedAnyGold = true;
			} else {
				missedAnyItem = true;
			}
			continue;
		}

		itemList.push_back(item);
	}

	bool shouldNotifyCapacity = false;
	ObjectCategory_t shouldNotifyNotEnoughRoom = OBJECTCATEGORY_NONE;

	uint32_t totalLootedGold = 0;
	uint32_t totalLootedItems = 0;
	for (Item* item : itemList) {
		uint32_t worth = item->getWorth();
		uint16_t baseCount = item->getItemCount();
		ObjectCategory_t category = getObjectCategory(item);

		ReturnValue ret = internalQuickLootItem(player, item, category);
		if (ret == RETURNVALUE_NOTENOUGHCAPACITY) {
			shouldNotifyCapacity = true;
		} else if (ret == RETURNVALUE_NOTENOUGHROOM) {
			shouldNotifyNotEnoughRoom = category;
		}

		bool success = ret == RETURNVALUE_NOERROR;
		if (worth != 0) {
			missedAnyGold = missedAnyGold || !success;
			if (success) {
				player->sendLootStats(item);
				totalLootedGold += worth;
			} else {
				// item is not completely moved
				totalLootedGold += worth - item->getWorth();
			}
		} else {
			missedAnyItem = missedAnyItem || !success;
			if (success || item->getItemCount() != baseCount) {
				totalLootedItems++;
				player->sendLootStats(item);
			}
		}
	}

	std::stringstream ss;
	if (totalLootedGold != 0 || missedAnyGold || totalLootedItems != 0 || missedAnyItem) {
		bool lootedAllGold = totalLootedGold != 0 && !missedAnyGold;
		bool lootedAllItems = totalLootedItems != 0 && !missedAnyItem;
		if (lootedAllGold) {
			if (totalLootedItems != 0 || missedAnyItem) {
				ss << "You looted the complete " << totalLootedGold << " gold";

				if (lootedAllItems) {
					ss << " and all dropped items";
				} else if (totalLootedItems != 0) {
					ss << ", but you only looted some of the items";
				} else if (missedAnyItem) {
					ss << " but none of the dropped items";
				}
			} else {
				ss << "You looted " << totalLootedGold << " gold";
			}
		} else if (lootedAllItems) {
			if (totalLootedItems == 1) {
				ss << "You looted 1 item";
			} else if (totalLootedGold != 0 || missedAnyGold) {
				ss << "You looted all of the dropped items";
			} else {
				ss << "You looted all items";
			}

			if (totalLootedGold != 0) {
				ss << ", but you only looted " << totalLootedGold << " of the dropped gold";
			} else if (missedAnyGold) {
				ss << " but none of the dropped gold";
			}
		} else if (totalLootedGold != 0) {
			ss << "You only looted " << totalLootedGold << " of the dropped gold";
			if (totalLootedItems != 0) {
				ss << " and some of the dropped items";
			} else if (missedAnyItem) {
				ss << " but none of the dropped items";
			}
		} else if (totalLootedItems != 0) {
			ss << "You looted some of the dropped items";
			if (missedAnyGold) {
				ss << " but none of the dropped gold";
			}
		} else if (missedAnyGold) {
			ss << "You looted none of the dropped gold";
			if (missedAnyItem) {
				ss << " and none of the items";
			}
		} else if (missedAnyItem) {
			ss << "You looted none of the dropped items";
		}
	} else {
		ss << "No loot";
	}

	ss << ".";
	player->sendTextMessage(MESSAGE_LOOT, ss.str());

	if (shouldNotifyCapacity) {
		ss.str(std::string());
		ss << "Attention! The loot you are trying to pick up is too heavy for you to carry.";
	} else if (shouldNotifyNotEnoughRoom != OBJECTCATEGORY_NONE) {
		ss.str(std::string());
		ss << "Attention! The container for " << getObjectCategoryName(shouldNotifyNotEnoughRoom) << " is full.";
	} else {
		return;
	}

	if (player->lastQuickLootNotification + 15000 < OTSYS_TIME()) {
		player->sendTextMessage(MESSAGE_STATUS_WARNING, ss.str());
	} else {
		player->sendTextMessage(MESSAGE_EVENT_DEFAULT, ss.str());
	}

	player->lastQuickLootNotification = OTSYS_TIME();
}

ReturnValue Game::internalQuickLootItem(Player* player, Item* item, ObjectCategory_t category /* = OBJECTCATEGORY_DEFAULT*/)
{
	bool fallbackConsumed = false;
	uint16_t baseId = 0;

	Container* lootContainer = player->getLootContainer(category);
	if (!lootContainer) {
		if (player->quickLootFallbackToMainContainer || player->getProtocolVersion() < 1150) {
			Item* fallbackItem = player->getInventoryItem(CONST_SLOT_BACKPACK);
			lootContainer = fallbackItem ? fallbackItem->getContainer() : nullptr;
			fallbackConsumed = true;
		} else {
			return RETURNVALUE_NOTPOSSIBLE;
		}
	} else {
		baseId = lootContainer->getID();
	}

	if (!lootContainer) {
		return RETURNVALUE_NOTPOSSIBLE;
	}

	Container* lastSubContainer = nullptr;
	uint32_t remainderCount = item->getItemCount();
	ContainerIterator it = lootContainer->iterator();

	ReturnValue ret;
	do {
		Item* moveItem = nullptr;
		ret = internalMoveItem(item->getParent(), lootContainer, INDEX_WHEREEVER, item, item->getItemCount(), &moveItem, 0, player);
		if (moveItem) {
			remainderCount -= moveItem->getItemCount();
		}

		if (ret != RETURNVALUE_CONTAINERNOTENOUGHROOM) {
			break;
		}

		// search for a sub container
		bool obtainedNewContainer = false;
		while (it.hasNext()) {
			Item* cur = *it;
			Container* subContainer = cur ? cur->getContainer() : nullptr;
			it.advance();

			if (subContainer && (fallbackConsumed || baseId == 0 || subContainer->getID() == baseId)) {
				lastSubContainer = subContainer;
				lootContainer = subContainer;
				obtainedNewContainer = true;
				break;
			}
		}

		// a hack to fix last empty sub-container
		if (!obtainedNewContainer && lastSubContainer && lastSubContainer->size() > 0) {
			Item* cur = lastSubContainer->getItemByIndex(lastSubContainer->size() - 1);
			Container* subContainer = cur ? cur->getContainer() : nullptr;
			if (subContainer && (fallbackConsumed || baseId == 0 || subContainer->getID() == baseId)) {
				lootContainer = subContainer;
				obtainedNewContainer = true;
			}

			lastSubContainer = nullptr;
		}

		// consumed all sub-container & there is simply no more containers to iterate over.
		// check if fallback should be used and if not, then break
		bool quickFallback = (player->getProtocolVersion() >= 1150 ? player->quickLootFallbackToMainContainer : true);
		bool noFallback = fallbackConsumed || !quickFallback;
		if (noFallback && (!lootContainer || !obtainedNewContainer)) {
			break;
		} else if (!lootContainer || !obtainedNewContainer) {
			Item* fallbackItem = player->getInventoryItem(CONST_SLOT_BACKPACK);
			if (!fallbackItem || !fallbackItem->getContainer()) {
				break;
			}

			lootContainer = fallbackItem->getContainer();
			it = lootContainer->iterator();

			fallbackConsumed = true;
		}
	} while (remainderCount != 0);
	return ret;
}

ObjectCategory_t Game::getObjectCategory(const Item* item)
{
	ObjectCategory_t category = OBJECTCATEGORY_DEFAULT;

	const ItemType& it = Item::items[item->getID()];
	if (item->getWorth() != 0) {
		category = OBJECTCATEGORY_GOLD;
	} else if (it.weaponType != WEAPON_NONE) {
		switch (it.weaponType) {
			case WEAPON_SWORD:
				category = OBJECTCATEGORY_SWORDS;
				break;
			case WEAPON_CLUB:
				category = OBJECTCATEGORY_CLUBS;
				break;
			case WEAPON_AXE:
				category = OBJECTCATEGORY_AXES;
				break;
			case WEAPON_SHIELD:
				category = OBJECTCATEGORY_SHIELDS;
				break;
			case WEAPON_DISTANCE:
				category = OBJECTCATEGORY_DISTANCEWEAPONS;
				break;
			case WEAPON_WAND:
				category = OBJECTCATEGORY_WANDS;
				break;
			case WEAPON_AMMO:
				category = OBJECTCATEGORY_AMMO;
				break;
			default:
				break;
		}
	} else if (it.slotPosition != SLOTP_HAND) { // if it's a weapon/shield should have been parsed earlier
		if ((it.slotPosition & SLOTP_HEAD) != 0) {
			category = OBJECTCATEGORY_HELMETS;
		} else if ((it.slotPosition & SLOTP_NECKLACE) != 0) {
			category = OBJECTCATEGORY_NECKLACES;
		} else if ((it.slotPosition & SLOTP_BACKPACK) != 0) {
			category = OBJECTCATEGORY_CONTAINERS;
		} else if ((it.slotPosition & SLOTP_ARMOR) != 0) {
			category = OBJECTCATEGORY_ARMORS;
		} else if ((it.slotPosition & SLOTP_LEGS) != 0) {
			category = OBJECTCATEGORY_LEGS;
		} else if ((it.slotPosition & SLOTP_FEET) != 0) {
			category = OBJECTCATEGORY_BOOTS;
		} else if ((it.slotPosition & SLOTP_RING) != 0) {
			category = OBJECTCATEGORY_RINGS;
		}
	} else if (it.type == ITEM_TYPE_RUNE) {
		category = OBJECTCATEGORY_RUNES;
	} else if (it.type == ITEM_TYPE_CREATUREPRODUCT) {
		category = OBJECTCATEGORY_CREATUREPRODUCTS;
	} else if (it.type == ITEM_TYPE_FOOD) {
		category = OBJECTCATEGORY_FOOD;
	} else if (it.type == ITEM_TYPE_VALUABLE) {
		category = OBJECTCATEGORY_VALUABLES;
	} else if (it.type == ITEM_TYPE_POTION) {
		category = OBJECTCATEGORY_POTIONS;
	} else {
		category = OBJECTCATEGORY_OTHERS;
	}

	return category;
}

Item* searchForItem(Container* container, uint16_t itemId)
{
	for (ContainerIterator it = container->iterator(); it.hasNext(); it.advance()) {
		if ((*it)->getID() == itemId) {
			return *it;
		}
	}

	return nullptr;
}

slots_t getSlotType(const ItemType& it)
{
	slots_t slot = CONST_SLOT_RIGHT;
	if (it.weaponType != WeaponType_t::WEAPON_SHIELD) {
		int32_t slotPosition = it.slotPosition;

		if (slotPosition & SLOTP_HEAD) {
			slot = CONST_SLOT_HEAD;
		} else if (slotPosition & SLOTP_NECKLACE) {
			slot = CONST_SLOT_NECKLACE;
		} else if (slotPosition & SLOTP_ARMOR) {
			slot = CONST_SLOT_ARMOR;
		} else if (slotPosition & SLOTP_LEGS) {
			slot = CONST_SLOT_LEGS;
		} else if (slotPosition & SLOTP_FEET) {
			slot = CONST_SLOT_FEET ;
		} else if (slotPosition & SLOTP_RING) {
			slot = CONST_SLOT_RING;
		} else if (slotPosition & SLOTP_AMMO) {
			slot = CONST_SLOT_AMMO;
		} else if (slotPosition & SLOTP_TWO_HAND || slotPosition & SLOTP_LEFT) {
			slot = CONST_SLOT_LEFT;
		}
	}

	return slot;
}

//Implementation of player invoked events
void Game::playerEquipItem(uint32_t playerId, uint16_t spriteId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	if (player->isMoveExhausted()) {
		player->sendCancelMessage("You can't equip very fast.");
		return;
	}

	Item* item = player->getInventoryItem(CONST_SLOT_BACKPACK);
	if (!item) {
		player->sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
		return;
	}

	Container* backpack = item->getContainer();
	if (!backpack) {
		player->sendCancelMessage(RETURNVALUE_CONTAINERNOTENOUGHROOM);
		return;
	}

	const ItemType& it = Item::items.getItemIdByClientId(spriteId);
	slots_t slot = getSlotType(it);

	Item* slotItem = player->getInventoryItem(slot);
	Item* equipItem = searchForItem(backpack, it.id);
	ReturnValue ret = RETURNVALUE_NOTPOSSIBLE;
	if (slotItem && slotItem->getID() == it.id && (!it.stackable || slotItem->getItemCount() == 100 || !equipItem)) {
		if (backpack->capacity() - backpack->size() <= 0) {
			player->sendCancelMessage(RETURNVALUE_CONTAINERNOTENOUGHROOM);
			return;
		}

		ret = internalMoveItem(slotItem->getParent(), player, CONST_SLOT_WHEREEVER, slotItem, slotItem->getItemCount(), nullptr);
	} else if (equipItem) {
		if (slotItem) {
			int32_t index = player->getThingIndex(slotItem);
			player->postRemoveNotification(slotItem, player, index);
		}

		ret = internalMoveItem(equipItem->getParent(), player, slot, equipItem, equipItem->getItemCount(), nullptr);
	}

	player->setMoveExhaust(300);
	if (ret != RETURNVALUE_NOERROR) {
		player->sendCancelMessage(ret);
	}
}

void Game::playerMove(uint32_t playerId, Direction direction)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	player->resetIdleTime();
	player->setNextWalkActionTask(nullptr);

	if (player->hasCondition(CONDITION_PARALYZE) && direction >= DIRECTION_SOUTHWEST) {
		player->setWalkExhaust(player->getStepDuration());
	}

	player->startAutoWalk(std::forward_list<Direction> { direction });
}

bool Game::playerBroadcastMessage(Player* player, const std::string& text) const
{
	if (!player->hasFlag(PlayerFlag_CanBroadcast)) {
		return false;
	}

	std::cout << "> " << player->getName() << " broadcasted: \"" << text << "\"." << std::endl;

	for (const auto& it : players) {
		it.second->sendPrivateMessage(player, TALKTYPE_BROADCAST, text);
	}

	return true;
}

void Game::playerCreatePrivateChannel(uint32_t playerId)
{
	Player* player = getPlayerByID(playerId);
	if (!player || !player->isPremium()) {
		return;
	}

	ChatChannel* channel = g_chat->createChannel(*player, CHANNEL_PRIVATE);
	if (!channel || !channel->addUser(*player)) {
		return;
	}

	player->sendCreatePrivateChannel(channel->getId(), channel->getName());
}

void Game::playerChannelInvite(uint32_t playerId, const std::string& name)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	PrivateChatChannel* channel = g_chat->getPrivateChannel(*player);
	if (!channel) {
		return;
	}

	Player* invitePlayer = getPlayerByName(name);
	if (!invitePlayer) {
		return;
	}

	if (player == invitePlayer) {
		return;
	}

	channel->invitePlayer(*player, *invitePlayer);
}

void Game::playerChannelExclude(uint32_t playerId, const std::string& name)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	PrivateChatChannel* channel = g_chat->getPrivateChannel(*player);
	if (!channel) {
		return;
	}

	Player* excludePlayer = getPlayerByName(name);
	if (!excludePlayer) {
		return;
	}

	if (player == excludePlayer) {
		return;
	}

	channel->excludePlayer(*player, *excludePlayer);
}

void Game::playerRequestChannels(uint32_t playerId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	player->sendChannelsDialog();
}

void Game::playerOpenChannel(uint32_t playerId, uint16_t channelId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	ChatChannel* channel = g_chat->addUserToChannel(*player, channelId);
	if (!channel) {
		return;
	}

	const InvitedMap* invitedUsers = channel->getInvitedUsers();
	const UsersMap* users;
	if (!channel->isPublicChannel()) {
		users = &channel->getUsers();
	} else {
		users = nullptr;
	}

	player->sendChannel(channel->getId(), channel->getName(), users, invitedUsers);
}

void Game::playerCloseChannel(uint32_t playerId, uint16_t channelId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	g_chat->removeUserFromChannel(*player, channelId);
}

void Game::playerOpenPrivateChannel(uint32_t playerId, std::string& receiver)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	if (!IOLoginData::formatPlayerName(receiver)) {
		player->sendCancelMessage("A player with this name does not exist.");
		return;
	}

	if (player->getName() == receiver) {
		player->sendCancelMessage("You cannot set up a private message channel with yourself.");
		return;
	}

	player->sendOpenPrivateChannel(receiver);
}

void Game::playerCloseNpcChannel(uint32_t playerId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	SpectatorHashSet spectators;
	map.getSpectators(spectators, player->getPosition());
	for (Creature* spectator : spectators) {
		if (Npc* npc = spectator->getNpc()) {
			npc->onPlayerCloseChannel(player);
		}
	}
}

void Game::playerReceivePing(uint32_t playerId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	player->receivePing();
}

void Game::playerReceivePingBack(uint32_t playerId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	player->sendPingBack();
}

void Game::playerAutoWalk(uint32_t playerId, const std::forward_list<Direction>& listDir)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	player->resetIdleTime();
	player->setNextWalkTask(nullptr);
	player->startAutoWalk(listDir);
}

void Game::playerStopAutoWalk(uint32_t playerId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	player->stopWalk();
}

void Game::playerUseItemEx(uint32_t playerId, const Position& fromPos, uint8_t fromStackPos, uint16_t fromSpriteId,
						   const Position& toPos, uint8_t toStackPos, uint16_t toSpriteId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	bool isHotkey = (fromPos.x == 0xFFFF && fromPos.y == 0 && fromPos.z == 0);
	if (isHotkey && !g_config.getBoolean(ConfigManager::AIMBOT_HOTKEY_ENABLED)) {
		return;
	}

	Thing* thing = internalGetThing(player, fromPos, fromStackPos, fromSpriteId, STACKPOS_USEITEM);
	if (!thing) {
		player->sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
		return;
	}

	Item* item = thing->getItem();
	if (!item || !item->isUseable() || item->getClientID() != fromSpriteId) {
		player->sendCancelMessage(RETURNVALUE_CANNOTUSETHISOBJECT);
		return;
	}

	Position walkToPos = fromPos;
	ReturnValue ret = g_actions->canUse(player, fromPos);
	if (ret == RETURNVALUE_NOERROR) {
		ret = g_actions->canUse(player, toPos, item);
		if (ret == RETURNVALUE_TOOFARAWAY) {
			walkToPos = toPos;
		}
	}

	const ItemType& it = Item::items[item->getID()];
	if (it.isRune() || it.type == ITEM_TYPE_POTION) {
		if (player->walkExhausted()) {
			player->sendCancelMessage(RETURNVALUE_YOUAREEXHAUSTED);
			return;
		}
	}
	if (ret != RETURNVALUE_NOERROR) {
		if (ret == RETURNVALUE_TOOFARAWAY) {
			Position itemPos = fromPos;
			uint8_t itemStackPos = fromStackPos;

			if (fromPos.x != 0xFFFF && toPos.x != 0xFFFF && Position::areInRange<1, 1, 0>(fromPos, player->getPosition()) &&
					!Position::areInRange<1, 1, 0>(fromPos, toPos)) {
				Item* moveItem = nullptr;

				ret = internalMoveItem(item->getParent(), player, INDEX_WHEREEVER, item, item->getItemCount(), &moveItem);
				if (ret != RETURNVALUE_NOERROR) {
					player->sendCancelMessage(ret);
					return;
				}

				//changing the position since its now in the inventory of the player
				internalGetPosition(moveItem, itemPos, itemStackPos);
			}

			std::forward_list<Direction> listDir;
			if (player->getPathTo(walkToPos, listDir, 0, 1, true, true)) {
				g_dispatcher.addTask(createTask(std::bind(&Game::playerAutoWalk, this, player->getID(), listDir)));

				SchedulerTask* task = createSchedulerTask(RANGE_USE_ITEM_EX_INTERVAL, std::bind(&Game::playerUseItemEx, this,
									  playerId, itemPos, itemStackPos, fromSpriteId, toPos, toStackPos, toSpriteId));
				if (it.isRune() || it.type == ITEM_TYPE_POTION) {
					player->setNextPotionActionTask(task);
				} else {
					player->setNextWalkActionTask(task);
				}
			} else {
				player->sendCancelMessage(RETURNVALUE_THEREISNOWAY);
			}
			return;
		}

		player->sendCancelMessage(ret);
		return;
	}

	bool canDoAction = player->canDoAction();
	if (it.isRune() || it.type == ITEM_TYPE_POTION) {
		canDoAction = player->canDoPotionAction();
	}

	if (!canDoAction) {
		uint32_t delay = player->getNextActionTime();
		if (it.isRune() || it.type == ITEM_TYPE_POTION) {
			delay = player->getNextPotionActionTime();
		}
		SchedulerTask* task = createSchedulerTask(delay, std::bind(&Game::playerUseItemEx, this,
							  playerId, fromPos, fromStackPos, fromSpriteId, toPos, toStackPos, toSpriteId));
		if (it.isRune() || it.type == ITEM_TYPE_POTION) {
			player->setNextPotionActionTask(task);
		} else {
			player->setNextActionTask(task);
		}
		return;
	}

	player->resetIdleTime();
	if (it.isRune() || it.type == ITEM_TYPE_POTION) {
		player->setNextPotionActionTask(nullptr);
	} else {
		player->setNextActionTask(nullptr);
	}

	g_actions->useItemEx(player, fromPos, toPos, toStackPos, item, isHotkey);
}

void Game::playerUseItem(uint32_t playerId, const Position& pos, uint8_t stackPos,
						 uint8_t index, uint16_t spriteId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	bool isHotkey = (pos.x == 0xFFFF && pos.y == 0 && pos.z == 0);
	if (isHotkey && !g_config.getBoolean(ConfigManager::AIMBOT_HOTKEY_ENABLED)) {
		return;
	}

	Thing* thing = internalGetThing(player, pos, stackPos, spriteId, STACKPOS_FIND_THING);
	if (!thing) {
		player->sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
		return;
	}

	Item* item = thing->getItem();
	if (!item || item->isUseable() || item->getClientID() != spriteId) {
		player->sendCancelMessage(RETURNVALUE_CANNOTUSETHISOBJECT);
		return;
	}

	const ItemType& it = Item::items[item->getID()];
	if (it.isRune() || it.type == ITEM_TYPE_POTION) {
		if (player->walkExhausted()) {
			player->sendCancelMessage(RETURNVALUE_YOUAREEXHAUSTED);
			return;
		}
	}
	ReturnValue ret = g_actions->canUse(player, pos);
	if (ret != RETURNVALUE_NOERROR) {
		if (ret == RETURNVALUE_TOOFARAWAY) {
			std::forward_list<Direction> listDir;
			if (player->getPathTo(pos, listDir, 0, 1, true, true)) {
				g_dispatcher.addTask(createTask(std::bind(&Game::playerAutoWalk,
												this, player->getID(), listDir)));

				SchedulerTask* task = createSchedulerTask(RANGE_USE_ITEM_INTERVAL, std::bind(&Game::playerUseItem, this,
									  playerId, pos, stackPos, index, spriteId));
				if (it.isRune() || it.type == ITEM_TYPE_POTION) {
					player->setNextPotionActionTask(task);
				} else {
					player->setNextWalkActionTask(task);
				}
				return;
			}

			ret = RETURNVALUE_THEREISNOWAY;
		}

		player->sendCancelMessage(ret);
		return;
	}

	bool canDoAction = player->canDoAction();
	if (it.isRune() || it.type == ITEM_TYPE_POTION) {
		canDoAction = player->canDoPotionAction();
	}

	if (!canDoAction) {
		uint32_t delay = player->getNextActionTime();
		if (it.isRune() || it.type == ITEM_TYPE_POTION) {
			delay = player->getNextPotionActionTime();
		}
		SchedulerTask* task = createSchedulerTask(delay, std::bind(&Game::playerUseItem, this,
							  playerId, pos, stackPos, index, spriteId));
		if (it.isRune() || it.type == ITEM_TYPE_POTION) {
			player->setNextPotionActionTask(task);
		} else {
			player->setNextActionTask(task);
		}
		return;
	}

	player->resetIdleTime();
	player->setNextActionTask(nullptr);

	g_actions->useItem(player, pos, index, item, isHotkey);
}

void Game::playerUseWithCreature(uint32_t playerId, const Position& fromPos, uint8_t fromStackPos, uint32_t creatureId, uint16_t spriteId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	Creature* creature = getCreatureByID(creatureId);
	if (!creature) {
		return;
	}

	if (!Position::areInRange<7, 5, 0>(creature->getPosition(), player->getPosition())) {
		return;
	}

	bool isHotkey = (fromPos.x == 0xFFFF && fromPos.y == 0 && fromPos.z == 0);
	if (!g_config.getBoolean(ConfigManager::AIMBOT_HOTKEY_ENABLED)) {
		if (creature->getPlayer() || isHotkey) {
			player->sendCancelMessage(RETURNVALUE_DIRECTPLAYERSHOOT);
			return;
		}
	}

	Thing* thing = internalGetThing(player, fromPos, fromStackPos, spriteId, STACKPOS_USEITEM);
	if (!thing) {
		player->sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
		return;
	}

	Item* item = thing->getItem();
	if (!item || !item->isUseable() || item->getClientID() != spriteId) {
		player->sendCancelMessage(RETURNVALUE_CANNOTUSETHISOBJECT);
		return;
	}

	const ItemType& it = Item::items[item->getID()];
	if (it.isRune() || it.type == ITEM_TYPE_POTION) {
		if (player->walkExhausted()) {
			player->sendCancelMessage(RETURNVALUE_YOUAREEXHAUSTED);
			return;
		}
	}
	Position toPos = creature->getPosition();
	Position walkToPos = fromPos;
	ReturnValue ret = g_actions->canUse(player, fromPos);
	if (ret == RETURNVALUE_NOERROR) {
		ret = g_actions->canUse(player, toPos, item);
		if (ret == RETURNVALUE_TOOFARAWAY) {
			walkToPos = toPos;
		}
	}

	if (ret != RETURNVALUE_NOERROR) {
		if (ret == RETURNVALUE_TOOFARAWAY) {
			Position itemPos = fromPos;
			uint8_t itemStackPos = fromStackPos;

			if (fromPos.x != 0xFFFF && Position::areInRange<1, 1, 0>(fromPos, player->getPosition()) && !Position::areInRange<1, 1, 0>(fromPos, toPos)) {
				Item* moveItem = nullptr;
				ret = internalMoveItem(item->getParent(), player, INDEX_WHEREEVER, item, item->getItemCount(), &moveItem);
				if (ret != RETURNVALUE_NOERROR) {
					player->sendCancelMessage(ret);
					return;
				}

				//changing the position since its now in the inventory of the player
				internalGetPosition(moveItem, itemPos, itemStackPos);
			}

			std::forward_list<Direction> listDir;
			if (player->getPathTo(walkToPos, listDir, 0, 1, true, true)) {
				g_dispatcher.addTask(createTask(std::bind(&Game::playerAutoWalk,
												this, player->getID(), listDir)));

				SchedulerTask* task = createSchedulerTask(RANGE_USE_WITH_CREATURE_INTERVAL, std::bind(&Game::playerUseWithCreature, this,
									  playerId, itemPos, itemStackPos, creatureId, spriteId));
				if (it.isRune() || it.type == ITEM_TYPE_POTION) {
					player->setNextPotionActionTask(task);
				} else {
					player->setNextWalkActionTask(task);
				}
			} else {
				player->sendCancelMessage(RETURNVALUE_THEREISNOWAY);
			}
			return;
		}

		player->sendCancelMessage(ret);
		return;
	}

	bool canDoAction = player->canDoAction();
	if (it.isRune() || it.type == ITEM_TYPE_POTION) {
		canDoAction = player->canDoPotionAction();
	}

	if (!canDoAction) {
		uint32_t delay = player->getNextActionTime();
		if (it.isRune() || it.type == ITEM_TYPE_POTION) {
			delay = player->getNextPotionActionTime();
		}
		SchedulerTask* task = createSchedulerTask(delay, std::bind(&Game::playerUseWithCreature, this,
							  playerId, fromPos, fromStackPos, creatureId, spriteId));

		if (it.isRune() || it.type == ITEM_TYPE_POTION) {
			player->setNextPotionActionTask(task);
		} else {
			player->setNextActionTask(task);
		}
		return;
	}

	player->resetIdleTime();
	if (it.isRune() || it.type == ITEM_TYPE_POTION) {
		player->setNextPotionActionTask(nullptr);
	} else {
		player->setNextActionTask(nullptr);
	}

	g_actions->useItemEx(player, fromPos, creature->getPosition(), creature->getParent()->getThingIndex(creature), item, isHotkey, creature);
}

void Game::playerCloseContainer(uint32_t playerId, uint8_t cid)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	player->closeContainer(cid);
	player->sendCloseContainer(cid);
}

void Game::playerMoveUpContainer(uint32_t playerId, uint8_t cid)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	Container* container = player->getContainerByID(cid);
	if (!container) {
		return;
	}

	Container* parentContainer = dynamic_cast<Container*>(container->getRealParent());
	if (!parentContainer) {
		Tile* tile = container->getTile();
		if (!tile) {
			return;
		}

		auto it = browseFields.find(tile);
		if (it == browseFields.end()) {
			parentContainer = new Container(tile);
			parentContainer->incrementReferenceCounter();
			browseFields[tile] = parentContainer;
			g_scheduler.addEvent(createSchedulerTask(30000, std::bind(&Game::decreaseBrowseFieldRef, this, tile->getPosition())));
		} else {
			parentContainer = it->second;
		}
	}

	if (parentContainer->hasPagination() && parentContainer->hasParent()) {
		uint16_t indexContainer = std::floor(parentContainer->getThingIndex(container) / parentContainer->capacity()) * parentContainer->capacity();
		player->addContainer(cid, parentContainer);

		player->setContainerIndex(cid, indexContainer);
		player->sendContainer(cid, parentContainer, parentContainer->hasParent(), indexContainer);
	} else {
		player->addContainer(cid, parentContainer);
		player->sendContainer(cid, parentContainer, parentContainer->hasParent(), player->getContainerIndex(cid));
	}
}

void Game::playerUpdateContainer(uint32_t playerId, uint8_t cid)
{
	Player* player = getPlayerByGUID(playerId);
	if (!player) {
		return;
	}

	Container* container = player->getContainerByID(cid);
	if (!container) {
		return;
	}

	player->sendContainer(cid, container, container->hasParent(), player->getContainerIndex(cid));
}

void Game::playerRotateItem(uint32_t playerId, const Position& pos, uint8_t stackPos, const uint16_t spriteId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	Thing* thing = internalGetThing(player, pos, stackPos, 0, STACKPOS_TOPDOWN_ITEM);
	if (!thing) {
		return;
	}

	Item* item = thing->getItem();
	if (!item || item->getClientID() != spriteId || !item->isRotatable() || item->hasAttribute(ITEM_ATTRIBUTE_UNIQUEID)) {
		player->sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
		return;
	}

	if (pos.x != 0xFFFF && !Position::areInRange<1, 1, 0>(pos, player->getPosition())) {
		std::forward_list<Direction> listDir;
		if (player->getPathTo(pos, listDir, 0, 1, true, true)) {
			g_dispatcher.addTask(createTask(std::bind(&Game::playerAutoWalk,
											this, player->getID(), listDir)));

			SchedulerTask* task = createSchedulerTask(RANGE_ROTATE_ITEM_INTERVAL, std::bind(&Game::playerRotateItem, this,
								  playerId, pos, stackPos, spriteId));
			player->setNextWalkActionTask(task);
		} else {
			player->sendCancelMessage(RETURNVALUE_THEREISNOWAY);
		}
		return;
	}

	uint16_t newId = Item::items[item->getID()].rotateTo;
	if (newId != 0) {
		transformItem(item, newId);
	}
}

void Game::playerWrapableItem(uint32_t playerId, const Position& pos, uint8_t stackPos, const uint16_t spriteId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	House* house = map.houses.getHouseByPlayerId(player->getGUID());
	if (!house) {
		player->sendCancelMessage("You don't own a house, you need own a house to use this.");
		return;
	}

	Thing* thing = internalGetThing(player, pos, stackPos, 0, STACKPOS_TOPDOWN_ITEM);
	if (!thing) {
		return;
	}

	Item* item = thing->getItem();
	bool isWrapable = (item ? (item->isWrapable() || item->getID() == TRANSFORM_BOX_ID) : false);
	if (item && isWrapable && item->hasAttribute(ITEM_ATTRIBUTE_ACTIONID)) {
		uint16_t newId = item->getID() == TRANSFORM_BOX_ID ? item->getIntAttr(ITEM_ATTRIBUTE_ACTIONID) : Item::items[item->getID()].wrapableTo;;
		item->setIntAttr(ITEM_ATTRIBUTE_WRAPID, newId);
		item->removeAttribute(ITEM_ATTRIBUTE_ACTIONID);

		SchedulerTask* task = createSchedulerTask(400, std::bind(&Game::playerWrapableItem, this,
			playerId, pos, stackPos, spriteId));
		player->setNextWalkActionTask(task);
		return;
	}

	if (!item || item->getClientID() != spriteId || !isWrapable || item->hasAttribute(ITEM_ATTRIBUTE_UNIQUEID)) {
		player->sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
		return;
	}

	if (item->getPosition().x == 0xFFFF || pos.x == 0xFFFF) {
		player->sendCancelMessage("You may construct this only inside a house.");
		return;		
	}

	Tile* tile = map.getTile(pos);
	if (!tile->hasFlag(TILESTATE_PROTECTIONZONE)) {
		player->sendCancelMessage("You may construct this only inside a house.");
		return;
	}

	HouseTile* houseTile = dynamic_cast<HouseTile*>(tile);
	if (!houseTile || houseTile->getHouse()->getOwner() != player->getGUID()) {
		player->sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
		return;
	}

	if (pos.x != 0xFFFF && !Position::areInRange<1, 1, 0>(pos, player->getPosition())) {
		std::forward_list<Direction> listDir;
		if (player->getPathTo(pos, listDir, 0, 1, true, true)) {
			g_dispatcher.addTask(createTask(std::bind(&Game::playerAutoWalk,
				this, player->getID(), listDir)));

			SchedulerTask* task = createSchedulerTask(400, std::bind(&Game::playerWrapableItem, this,
				playerId, pos, stackPos, spriteId));
			player->setNextWalkActionTask(task);
		} else {
			player->sendCancelMessage(RETURNVALUE_THEREISNOWAY);
		}
		return;
	}

	// It is not possible to unwrap containers with one or more items inside.
	const Container* container = item->getContainer();
	if(container && container->getItemHoldingCount() > 0){
		player->sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
		return;
	}

	uint16_t itemId = item->getID();
	uint16_t newWrapId = Item::items[itemId].wrapableTo;
	std::string itemName = item->getName();

	if (itemId == TRANSFORM_BOX_ID) {
		if ((item->getIntAttr(ITEM_ATTRIBUTE_WRAPID) != 0)) {
			uint16_t hiddenCharges = item->getDate();
			uint16_t boxActionId = item->getIntAttr(ITEM_ATTRIBUTE_WRAPID);
			transformItem(item, boxActionId); // transforms the item
			item->setSpecialDescription("Wrap it in your own house to create a <" + itemName + ">.");
			addMagicEffect(item->getPosition(), CONST_ME_POFF);
			if (hiddenCharges > 0 && isCaskItem(boxActionId)) {
				item->setSubType(hiddenCharges);
				item->setDate(hiddenCharges);
			}

			startDecay(item);
			return;
		}		
	} else {
		if (newWrapId != 0) {
			uint16_t hiddenCharges = 0;
			if (isCaskItem(item->getID())) {
				hiddenCharges = item->getDate();
			}

			transformItem(item, newWrapId)->setIntAttr(ITEM_ATTRIBUTE_WRAPID, itemId);
			item->setSpecialDescription("Unwrap it in your own house to create a <" + itemName + ">.");
			if (hiddenCharges > 0) { //saving the cask charges
				item->setDate(hiddenCharges);
				item->setSubType(hiddenCharges);
			}
			addMagicEffect(item->getPosition(), CONST_ME_POFF);
			startDecay(item);
			return;
		} else if (item->getIntAttr(ITEM_ATTRIBUTE_WRAPID) != 0) {
			uint16_t hiddenCharges = item->getDate();
			uint16_t boxActionId = item->getIntAttr(ITEM_ATTRIBUTE_WRAPID);
			transformItem(item, boxActionId); // transforms the item
			item->setSpecialDescription("Wrap it in your own house to create a <" + itemName + ">.");
			addMagicEffect(item->getPosition(), CONST_ME_POFF);
			if (hiddenCharges > 0 && isCaskItem(boxActionId)) {
				item->setSubType(hiddenCharges);
				item->setDate(hiddenCharges);
			}
			startDecay(item);
			return;
		}
	}

}

void Game::playerWriteItem(uint32_t playerId, uint32_t windowTextId, const std::string& text)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	uint16_t maxTextLength = 0;
	uint32_t internalWindowTextId = 0;

	Item* writeItem = player->getWriteItem(internalWindowTextId, maxTextLength);
	if (text.length() > maxTextLength || windowTextId != internalWindowTextId) {
		return;
	}

	if (!writeItem || writeItem->isRemoved()) {
		player->sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
		return;
	}

	Cylinder* topParent = writeItem->getTopParent();

	Player* owner = dynamic_cast<Player*>(topParent);
	if (owner && owner != player) {
		player->sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
		return;
	}

	if (!Position::areInRange<1, 1, 0>(writeItem->getPosition(), player->getPosition())) {
		player->sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
		return;
	}

	for (auto creatureEvent : player->getCreatureEvents(CREATURE_EVENT_TEXTEDIT)) {
		if (!creatureEvent->executeTextEdit(player, writeItem, text)) {
			player->setWriteItem(nullptr);
			return;
		}
	}

	if (!text.empty()) {
		if (writeItem->getText() != text) {
			writeItem->setText(text);
			writeItem->setWriter(player->getName());
			writeItem->setDate(OS_TIME(nullptr));
		}
	} else {
		writeItem->resetText();
		writeItem->resetWriter();
		writeItem->resetDate();
	}

	uint16_t newId = Item::items[writeItem->getID()].writeOnceItemId;
	if (newId != 0) {
		transformItem(writeItem, newId);
	}

	player->setWriteItem(nullptr);
}

void Game::playerOpenStore(uint32_t playerId, bool openStore, StoreOffers* offers)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	// atualizando os coins
	player->updateCoinBalance();

	if (openStore) {
		player->openStore();
	} else if (offers == nullptr && player->getProtocolVersion() >= 1150) {
		player->sendStoreHome();
	} else if (offers != nullptr) {
		player->sendShowStoreOffers(offers);
	}

	return;
}

void Game::playerBuyStoreOffer(uint32_t playerId, const StoreOffer& offer, std::string& param)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	StoreOffer* thisOffer = const_cast<StoreOffer*>(&offer);
	if (!thisOffer || thisOffer == nullptr) {
		player->sendStoreError(STORE_ERROR_NETWORK, "The offer is fake, please report it!");
		return;
	}


	OfferTypes_t offerType = thisOffer->getOfferType();
	if (!g_store.isValidType( offerType )) {
		player->sendStoreError(STORE_ERROR_INFORMATION, "This offer is unavailable.");
		return;
	}

	if (!player->canRemoveCoins(thisOffer->getPrice(player)) ) {
		player->sendStoreError(STORE_ERROR_PURCHASE, "You don't have coins.");
		return;
	}

	player->updateCoinBalance();
	std::string message = thisOffer->getDisabledReason(player);
	if (!message.empty()) {
		player->sendStoreError(STORE_ERROR_PURCHASE, message);
		return;
	}

	if (player->isPzLocked()) {
		player->sendStoreError(STORE_ERROR_PURCHASE, "You can't buy this offer in pz locked!");
		return;
	}

	bool successfully = false;

	Tile* playerTile = player->getTile();

	int32_t offerPrice = thisOffer->getPrice(player) * -1;
	std::stringstream returnmessage;
	if (offerType == OFFER_TYPE_NAMECHANGE) {
		std::ostringstream query;
		std::string newName = param;
		trimString(newName);

		Database& db = Database::getInstance();
		query << "SELECT `id` FROM `players` WHERE `name`=" << db.escapeString(newName);
		if (db.storeQuery(query.str())) { //name already in use
			returnmessage << "This name is already in use.";
			player->sendStoreError(STORE_ERROR_PURCHASE, returnmessage.str());
			return;
		} else {
			query.str("");
			toLowerCaseString(newName);

			std::string responseMessage;
			NameEval_t nameValidation = validateName(newName);

			switch (nameValidation) {
				case INVALID_LENGTH:
					responseMessage = "Your new name must be more than 3 and less than 14 characters long.";
					break;
				case INVALID_TOKEN_LENGTH:
					responseMessage = "Every words of your new name must be at least 2 characters long.";
					break;
				case INVALID_FORBIDDEN:
					responseMessage = "You're using forbidden words in your new name.";
					break;
				case INVALID_CHARACTER:
					responseMessage = "Your new name contains invalid characters.";
					break;
				case INVALID:
					responseMessage = "Your new name is invalid.";
					break;
				case VALID:
					responseMessage = "You have successfully changed you name, you must relog to see changes.";
					break;
			}

			if (nameValidation != VALID) { //invalid name typed
				player->sendStoreError(STORE_ERROR_PURCHASE, responseMessage);
				return;
			} else { //valid name so far

				//check if it's an NPC or Monster name.
				if (g_monsters.getMonsterType(newName)) {
					responseMessage = "Your new name cannot be a monster's name.";
					player->sendStoreError(STORE_ERROR_PURCHASE, responseMessage);
					return;
				} else if (getNpcByName(newName)) {
					responseMessage = "Your new name cannot be an NPC's name.";
					player->sendStoreError(STORE_ERROR_PURCHASE, responseMessage);
					return;
				} else {
					capitalizeWords(newName);

					query << "UPDATE `players` SET `name` = " << db.escapeString(newName) << " WHERE `id` = "
						  << player->getGUID();
					if (db.executeQuery(query.str())) {
						returnmessage << "You have successfully changed you name, you must relog to see the changes.";
						successfully = true;
					} else {
						returnmessage << "An error ocurred processing your request, no changes were made.";
						player->sendStoreError(STORE_ERROR_PURCHASE, returnmessage.str());
						return;
					}
				}
			}
		}
	} else if (offerType == OFFER_TYPE_ITEM || offerType == OFFER_TYPE_TRAINING || offerType == OFFER_TYPE_POUCH || offerType == OFFER_TYPE_HOUSE || offerType == OFFER_TYPE_STACKABLE) {
		// Criando o itemType para usar dps
		const ItemType& itemType = Item::items[thisOffer->getItemType()];
		uint16_t itemId = itemType.id;

		if (itemId == 0) {
			player->sendStoreError(STORE_ERROR_NETWORK, "There was an error with the offer, report to Gamemaster.");
			return;
		}

		bool isKeg = (itemId >= ITEM_KEG_START && itemId <= ITEM_KEG_END);

		bool isCaskItem = ((itemId >= ITEM_HEALTH_CASK_START && itemId <= ITEM_HEALTH_CASK_END) ||
							(itemId >= ITEM_MANA_CASK_START && itemId <= ITEM_MANA_CASK_END) ||
							(itemId >= ITEM_SPIRIT_CASK_START && itemId <= ITEM_SPIRIT_CASK_END));
		uint64_t weight = static_cast<uint64_t>(itemType.weight) * std::max<int32_t>(1, (isKeg ? 1 : thisOffer->getCount()));
		if (isCaskItem) {
			const ItemType& itemType2 = Item::items[TRANSFORM_BOX_ID];
			weight = static_cast<uint64_t>(itemType2.weight); 
		}
		if (player->getFreeCapacity() < weight) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "Please make sure you have free capacity to hold this item.");
			return;
		}

		Thing* thing = player->getThing(CONST_SLOT_STORE_INBOX);
		if (!thing) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "Please make sure you have free slots in your store inbox.");
			return;
		}
		Item* inboxItem = thing->getItem();
		if (!inboxItem) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "Please make sure you have free slots in your store inbox.");
			return;
		}

		Container* inbox = inboxItem->getContainer();
		if (!inbox || (inbox->capacity() - inbox->size() <= 0) ) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "Please make sure you have free slots in your store inbox.");
			return;
		}

		int32_t itemCount = thisOffer->getCount();
		int32_t pendingCount = thisOffer->getCount();

		bool isHouseOffer = (offerType == OFFER_TYPE_HOUSE);
		bool isTraining = (offerType == OFFER_TYPE_TRAINING);

		std::vector<Item*> itemList;
		int32_t rcreateitem = ((isKeg || isHouseOffer || isTraining) ? 1 : 100);
		while (pendingCount > 0) {
			uint16_t n = static_cast<uint16_t>(std::min<int32_t>(pendingCount, rcreateitem));
			Item* tmpItem = Item::CreateItem((isHouseOffer ? TRANSFORM_BOX_ID : itemId), n);
			if (!tmpItem) {
				break;
			}

			// Setando o valor do jogador no item
			tmpItem->setOwner(player->getGUID());

			uint32_t removecount = n;
			if (isKeg) {
				int32_t pack;
				if (pendingCount > 500)
					pack = 500;
				else
					pack = pendingCount;

				tmpItem->setCharges(pack);
				tmpItem->setDate(pack);
				removecount = pack;
			} else if (isTraining) {
				int32_t pack = thisOffer->getCharges();
				tmpItem->setIntAttr(ITEM_ATTRIBUTE_CHARGES, pack);

				removecount = pack;				
			} else if (isHouseOffer) {
				std::ostringstream packagename;
				packagename << "You bought this item in the Store.\nUnwrap it in your own house to create a <" << itemType.name << ">.";
				tmpItem->setStrAttr(ITEM_ATTRIBUTE_DESCRIPTION, packagename.str());
				tmpItem->setIntAttr(ITEM_ATTRIBUTE_WRAPID, itemId);

				if (isCaskItem) {
					tmpItem->setCharges(itemCount);
					tmpItem->setDate(itemCount);
					removecount = pendingCount + 1;
				}
			}

			if (thisOffer->getActionID() > 0 ) {
				tmpItem->setActionId(thisOffer->getActionID());
				if (tmpItem->getID() == 16101) {
					uint32_t vipdays = thisOffer->getActionID() - 7097;
					std::ostringstream scrollstr;
					scrollstr << "Using this scroll will add " << vipdays << " days of vip time to your account once.";
					tmpItem->setStrAttr(ITEM_ATTRIBUTE_DESCRIPTION, scrollstr.str());
				}
			}
			pendingCount -= removecount;
			itemList.push_back(tmpItem);
		}

		if (itemList.empty()) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "There was an error in your purchase, report to ADM");
			return;
		}

		if (itemCount > 100 && !isHouseOffer) {
			Item* parcel = Item::CreateItem(2596, 1);
			if (!parcel) {
				player->sendStoreError(STORE_ERROR_PURCHASE, "Please make sure you have free slots in your store inbox.");
				return;
			}

			std::ostringstream packagename;
			packagename << itemCount << "x " << thisOffer->getName() << " package.";
			parcel->setStrAttr(ITEM_ATTRIBUTE_NAME, packagename.str());

			for (Item* item : itemList) {
				if (g_game.internalAddItem(parcel->getContainer(), item) != RETURNVALUE_NOERROR) {
					parcel->getContainer()->internalAddThing(item);
				}
			}

			if (g_game.internalAddItem(inbox, parcel) != RETURNVALUE_NOERROR) {
				inbox->internalAddThing(parcel);
			}
		} else {
			for (Item* item : itemList) {
				if (g_game.internalAddItem(inbox, item) != RETURNVALUE_NOERROR) {
					inbox->internalAddThing(item);
				}
			}
		}

		successfully = true;
		returnmessage << "You have purchased " << thisOffer->getName() << " for " << thisOffer->getPrice(player) <<" coins";
	} else if (offerType == OFFER_TYPE_MULTI_ITEMS) {
		std::map<uint16_t, uint16_t> itemMap = thisOffer->getItems();

		if (itemMap.empty()) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "There was an error in your purchase, report to ADM");
			return;
		}

		std::vector<Item*> itemList;
		Thing* thing = player->getThing(CONST_SLOT_STORE_INBOX);
		if (!thing) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "Please make sure you have free slots in your store inbox.");
			return;
		}
		Item* inboxItem = thing->getItem();
		if (!inboxItem) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "Please make sure you have free slots in your store inbox.");
			return;
		}

		Container* inbox = inboxItem->getContainer();
		if (!inbox || (inbox->capacity() - inbox->size() <= 0) ) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "Please make sure you have free slots in your store inbox.");
			return;
		}

		uint32_t capacity = 0;
		for (const auto& it : itemMap) {
			int32_t pendingCount = it.second;
			while (pendingCount > 0) {
				const ItemType& itemType = Item::items[it.first];
				uint16_t n = static_cast<uint16_t>(std::min<int32_t>((itemType.stackable ? pendingCount : 1), 100));
				Item* tmpItem = Item::CreateItem(it.first, n);
				if (!tmpItem) {
					break;
				}

				if (thisOffer->getActionID() > 0 ) {
					tmpItem->setActionId(thisOffer->getActionID());
				}

				// Setando o valor do jogador no item
				tmpItem->setOwner(player->getGUID());
				uint32_t removecount = n;
				pendingCount -= removecount;
				capacity += static_cast<uint64_t>(itemType.weight) * std::max<int32_t>(1, n);

				itemList.push_back(tmpItem);
			}
		}	

		if (player->getFreeCapacity() < capacity) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "Please make sure you have free capacity to hold this item.");
			return;
		}

		if (itemList.empty()) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "There was an error in your purchase, report to ADM");
			return;
		}

		Item* parcel = Item::CreateItem(2596, 1);
		if (!parcel) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "Please make sure you have free slots in your store inbox.");
			return;
		}

		std::ostringstream packagename;
		packagename << "1x " << thisOffer->getName() << " package.";
		parcel->setStrAttr(ITEM_ATTRIBUTE_NAME, packagename.str());

		for (Item* item : itemList) {
			if (g_game.internalAddItem(parcel->getContainer(), item) != RETURNVALUE_NOERROR) {
				parcel->getContainer()->internalAddThing(item);
			}
		}

		if (g_game.internalAddItem(inbox, parcel) != RETURNVALUE_NOERROR) {
			inbox->internalAddThing(parcel);
		}

		successfully = true;
		returnmessage << "You have purchased " << thisOffer->getName() << " for " << thisOffer->getPrice(player) <<" coins";
	} else if (offerType == OFFER_TYPE_INSTANT_REWARD_ACCESS) {
		player->setInstantRewardTokens(player->getInstantRewardTokens() + thisOffer->getCount());
		player->sendResourceData(RESOURCETYPE_REWARD, player->getInstantRewardTokens());
		successfully = true;
		returnmessage << "You have purchased " << thisOffer->getName() << " for " << thisOffer->getPrice(player) <<" coins";
	} else if (offerType == OFFER_TYPE_BLESSINGS) {
		if (thisOffer->getBlessid() < 1 || thisOffer->getBlessid() > 8) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "This purchase is impossible. Report to ADM [ERRBID" + std::to_string(thisOffer->getBlessid()) +"]");
			return;
		}

		player->addBlessing(thisOffer->getBlessid(), thisOffer->getCount());
		player->sendBlessStatus();

		successfully = true;
		returnmessage << "You have purchased " << thisOffer->getName() << " for " << thisOffer->getPrice(player) <<" coins";
	} else if (offerType == OFFER_TYPE_ALLBLESSINGS) {

		uint8_t count = 0;
		uint8_t limitBless = 0;
		uint8_t minBless = (g_game.getWorldType() == WORLD_TYPE_RETRO_OPEN_PVP ? BLESS_PVE_FIRST : BLESS_FIRST);
		uint8_t maxBless = BLESS_LAST;
		for (int i = minBless; i <= maxBless; ++i) {
			limitBless++;
			if (player->hasBlessing(i)) {
				count++;
			}
		}

		if (count >= limitBless) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "You already have all blessings.");
			return;
		}

		for (int i = minBless; i <= maxBless; ++i)
		{
			player->addBlessing(i, thisOffer->getCount());
		}

		player->sendBlessStatus();
		successfully = true;
		returnmessage << "You have purchased " << std::to_string(thisOffer->getCount()) << "x " << thisOffer->getName() << " for " << thisOffer->getPrice(player) <<" coins";
	} else if (offerType == OFFER_TYPE_PREMIUM) {
		if (player->premiumEndsAt != std::numeric_limits<time_t>::max()) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "You have reached the maximum premium limit");
			return;
		}

		time_t now = time(nullptr);
		time_t addTime = thisOffer->getCount(true) * 86400;
		time_t endTime = std::min<time_t>(now + static_cast<time_t>(0xFFFE) * 86400, player->premiumEndsAt + addTime);
		player->premiumEndsAt = endTime;
		IOLoginData::setPremiumEndsAt(player->getAccount(), endTime);
		successfully = true;
		returnmessage << "You have purchased " << thisOffer->getName() << " for " << thisOffer->getPrice(player) <<" coins";
	} else if (offerType == OFFER_TYPE_VIP) {
		if (player->viptime == std::numeric_limits<uint32_t>::max()) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "You have reached the maximum vip limit");
			return;
		}

		uint32_t days = (thisOffer->getCount(true) * 86400);
		uint32_t addDays = OS_TIME(nullptr);
		if (player->viptime > addDays) {
			addDays = player->viptime + days;
		} else {
			addDays += days;
		}

		player->setVipDays(addDays);
		IOLoginData::setVipDays(player->getAccount(), addDays);

		successfully = true;
		returnmessage << "You have purchased " << thisOffer->getName() << " for " << thisOffer->getPrice(player) <<" coins";
	} else if (offerType == OFFER_TYPE_OUTFIT || offerType == OFFER_TYPE_OUTFIT_ADDON) {
		uint8_t addons = thisOffer->getAddon();
		uint16_t lookType = (player->getSex() == PLAYERSEX_FEMALE ? thisOffer->getOutfitFemale() : thisOffer->getOutfitMale());

		if ((addons == 1 || addons == 2) && !player->canWear(lookType, 0)) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "You must own the outfit before you can buy its addon.");
			return;
		}

		if (player->canWear(lookType, addons)) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "You already own this outfit.");
			return;
		}

		// tstando o bug do tfs
		if (addons == 3) {
			player->addOutfit(thisOffer->getOutfitMale(), 0);
			player->addOutfit(thisOffer->getOutfitFemale(), 0);
			player->addOutfit(thisOffer->getOutfitMale(), 1);
			player->addOutfit(thisOffer->getOutfitFemale(), 1);
			player->addOutfit(thisOffer->getOutfitMale(), 2);
			player->addOutfit(thisOffer->getOutfitFemale(), 2);
		} else {
			player->addOutfit(thisOffer->getOutfitMale(), addons);
			player->addOutfit(thisOffer->getOutfitFemale(), addons);
		}

		// checando o sistema do davi
		Guild* guild = player->getGuild();
		if (guild && (guild->getPoints() + 10000) < 1500000) {
			guild->setPoints((guild->getPoints() + 10000));
			std::ostringstream broadcastedMessage;
			broadcastedMessage << "The player " << player->getName() << " just bought an outfit on the store and earned 10000 points for your guild!";
			std::cout << "//" << guild->getName() << " guild: " << broadcastedMessage.str() << "//" << std::endl;
			const auto& members = guild->getMembersOnline();
			for (Player* tmpplayer : members) {
				tmpplayer->sendTextMessage(MESSAGE_EVENT_ADVANCE, broadcastedMessage.str());
			}
		}

		successfully = true;
		returnmessage << "You've successfully bought the "<< thisOffer->getName() << ".";
	} else if (offerType == OFFER_TYPE_MOUNT) {
		Mount* mount = thisOffer->getMount();
		if (!mount || mount == nullptr) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "This purchase is impossible. Report to ADM [ERRMID" + std::to_string(thisOffer->getId()) +"]");
			return;
		}

		if (player->hasMount(mount)) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "You arealdy own this mount.");
			return;
		}

		if (!player->tameMount( mount->id )) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "An error ocurred processing your purchase. Try again later.");
			return;
		}

		// checando o sistema do davi
		Guild* guild = player->getGuild();
		if (guild && (guild->getPoints() + 10000) < 1500000) {
			guild->setPoints((guild->getPoints() + 10000));
			std::ostringstream broadcastedMessage;
			broadcastedMessage << "The player " << player->getName() << " just bought an mount on the store and earned 10000 points for your guild!";
			std::cout << "//" << guild->getName() << " guild: " << broadcastedMessage.str() << "//" << std::endl;
			const auto& members = guild->getMembersOnline();
			for (Player* tmpplayer : members) {
				tmpplayer->sendTextMessage(MESSAGE_EVENT_ADVANCE, broadcastedMessage.str());
			}
		}
		returnmessage << "You've successfully bought the " << mount->name <<" Mount.";
		successfully = true;
	} else if (offerType == OFFER_TYPE_SEXCHANGE) {
		Outfit_t outfit = player->getCurrentOutfit();
		if (player->getSex() == PLAYERSEX_FEMALE) {
			player->setSex(PLAYERSEX_MALE);
			outfit.lookType = 128;
			outfit.lookAddons = 0;
			player->setCurrentOutfit(outfit);
		} else {
			player->setSex(PLAYERSEX_MALE);
			outfit.lookType = 136;
			outfit.lookAddons = 0;
			player->setCurrentOutfit(outfit);
		}

		returnmessage << "You have purchased " << thisOffer->getName() << " for " << thisOffer->getPrice(player) <<" coins";
		successfully = true;

	} else if (offerType == OFFER_TYPE_EXPBOOST) {
		uint16_t currentExpBoostTime = player->getExpBoostStamina();

		player->setStoreXpBoost(50);
		player->setExpBoostStamina(currentExpBoostTime + 3600);

		int32_t value1;
		player->getStorageValue(51052, value1);
		if (value1 == -1) {
			value1 = 1;
			player->addStorageValue(51052, 1);
		}

		// update
		player->getStorageValue(51052, value1);

		returnmessage << "You have purchased " << thisOffer->getName() << " for " << thisOffer->getPrice(player) <<" coins";

		player->addStorageValue(51052, value1 + 1);
		player->addStorageValue(51053, OS_TIME(nullptr)); // last bought
		player->sendStats();
		successfully = true;

	} else if (offerType == OFFER_TYPE_PREYSLOT) {
		if (player->isUnlockedPrey(2) != STATE_LOCKED) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "You already have 3 slots released.");
			return;
		}

		player->changePreyDataState(2, STATE_SELECTION);
		successfully = true;

	} else if (offerType == OFFER_TYPE_PREYBONUS) {
		int64_t count = std::max<int64_t>(player->getBonusRerollCount(), 0) + thisOffer->getCount();
		player->setBonusRerollCount(count);

		successfully = true;

	} else if (offerType == OFFER_TYPE_TEMPLE) {
		if (player->hasCondition(CONDITION_INFIGHT)) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "You can't use temple teleport in fight!");
			return;
		}
		const Position& position = player->getTemplePosition();
		const Position oldPosition = player->getPosition();
		if (internalTeleport(player, position, false) != RETURNVALUE_NOERROR) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "You can't use temple teleport in fight!");
			return;
		}

		if (oldPosition.x == position.x) {
			if (oldPosition.y < position.y) {
				internalCreatureTurn(player, DIRECTION_SOUTH);
			} else {
				internalCreatureTurn(player, DIRECTION_NORTH);
			}
		} else if (oldPosition.x > position.x) {
			internalCreatureTurn(player, DIRECTION_WEST);
		} else if (oldPosition.x < position.x) {
			internalCreatureTurn(player, DIRECTION_EAST);
		}


		addMagicEffect(position, CONST_ME_TELEPORT);
		player->sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have been teleported to your hometown.");
		successfully = true;

	} else if (offerType == OFFER_TYPE_PROMOTION) {
		player->sendStoreError(STORE_ERROR_PURCHASE, "This offer has disable.");
		return;
	} else if (offerType == OFFER_TYPE_CHARM_EXPANSION) {
		if (player->hasCharmExpansion()) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "You have charm expansion");
			return;
		}

		player->setCharmExpansion(true);
		returnmessage << "You've successfully bought the " << thisOffer->getName() <<".";
		successfully = true;
	} else if (offerType == OFFER_TYPE_CHARM_POINTS) {
		player->setCharmPoints( player->getCharmPoints() + thisOffer->getCount());
		successfully = true;
	} else if (offerType == OFFER_TYPE_BLESS_RUNE) {
		player->addStorageValue(PSTRG_BLESS_RUNA, OS_TIME(nullptr) + (24 * 60 * 60));
		successfully = true;
	} else if (offerType == OFFER_TYPE_FRAG_REMOVE) {
		if (playerTile && !playerTile->hasFlag(TILESTATE_PROTECTIONZONE)) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "You can't use this offer in fight!");
			return;
		}
		if (player->hasCondition(CONDITION_INFIGHT)) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "You can't use this offer in fight!");
			return;
		}

		if (player->unjustifiedKills.empty()) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "You have no frag to remove.");
			return;
		}

		successfully = player->removeFrags(1);
	} else if (offerType == OFFER_TYPE_SKULL_REMOVE) {
		if (playerTile && !playerTile->hasFlag(TILESTATE_PROTECTIONZONE)) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "You can't use this offer in fight!");
			return;
		}
		if (player->hasCondition(CONDITION_INFIGHT)) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "You can't use this offer in fight!");
			return;
		}

		if (player->getSkull() != thisOffer->getSkull()) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "This offer is disabled for you!");
			return;			
		}

		player->removeFrags();
		player->setSkull(SKULL_NONE);

		successfully = true;
	} else if (offerType == OFFER_TYPE_RECOVERYKEY) {
		std::ostringstream newkey;
		newkey << generateRK(4) << "-" << generateRK(4) << "-" << generateRK(4) << "-" << generateRK(4);

		Item* letter = Item::CreateItem(2597, 1);
		if (!letter) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "Please make sure you have free slots in your store inbox.");
			return;
		}

		std::ostringstream text;
		text << "Recovery key succesfully renewed!\n\nYour new recovery key is: " << newkey.str() << "\nSave this in a safe place.";
		letter->setStrAttr(ITEM_ATTRIBUTE_TEXT, text.str());

		Thing* thing = player->getThing(CONST_SLOT_STORE_INBOX);
		if (!thing) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "Please make sure you have free slots in your store inbox.");
			return;
		}
		Item* inboxItem = thing->getItem();
		if (!inboxItem) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "Please make sure you have free slots in your store inbox.");
			return;
		}

		Container* inbox = inboxItem->getContainer();
		if (!inbox || (inbox->capacity() - inbox->size() <= 0) ) {
			player->sendStoreError(STORE_ERROR_PURCHASE, "Please make sure you have free slots in your store inbox.");
			return;
		}

		if (g_game.internalAddItem(inbox, letter) != RETURNVALUE_NOERROR) {
			inbox->internalAddThing(letter);
		}

		std::ostringstream query;
		query << "UPDATE accounts SET `key` = " << Database::getInstance().escapeString(newkey.str()) << " WHERE `id` = " << player->getAccount();
		Database::getInstance().executeQuery(query.str());

		uint32_t newtime = OS_TIME(nullptr) + (7*24*60*60);
		player->addAccountStorageValue(1, newtime);
		successfully = true;
	}

	if (successfully) {
		IOAccount::removeCoins(player->getAccount(), offerPrice*-1, thisOffer->getCoinType());
		player->setTibiaCoins(IOAccount::getCoinBalance(player->getAccount(), thisOffer->getCoinType()), thisOffer->getCoinType());
		if (returnmessage.str().empty()) {
			returnmessage << "You have purchased " << thisOffer->getName() << " for " << offerPrice*-1 <<" coins";
		}

		player->updateCoinBalance();

		player->sendStorePurchaseSuccessful(returnmessage.str(), IOAccount::getCoinBalance(player->getAccount()) );
		IOAccount::registerTransaction(player->getAccount(), OS_TIME(nullptr), static_cast<uint8_t>(HISTORY_TYPE_NONE), thisOffer->getCount(true), static_cast<uint8_t>(thisOffer->getCoinType()), std::move(thisOffer->getName()), offerPrice);
	} else {
		player->sendStoreError(STORE_ERROR_PURCHASE, "Something went wrong with your purchase.");
	}

	return;
}

void Game::playerStoreTransactionHistory(uint32_t playerId, uint32_t pages, uint8_t entryPages)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	uint32_t accountId = player->getAccount();
	std::vector<StoreHistory> filter;
	uint32_t totalEntries = static_cast<uint32_t>(storeHistory[accountId].size());
	uint32_t getPages = totalEntries / entryPages;

	uint32_t totalPages = getPages + ((totalEntries / entryPages > 0 ? 1 : 0));
	auto begin = storeHistory[accountId].begin() + (pages > 1 ? entryPages * (pages - 1) : 0);
	uint8_t count = 0;
	for (auto currentHistory = begin, end = storeHistory[accountId].end(); currentHistory != end; ++currentHistory) {
		if (count == entryPages) {
			break;
		}
		count++;
		filter.emplace_back(*currentHistory);
	}
	if (filter.empty()) {
		player->sendStoreError(STORE_ERROR_HISTORY, "You don't have any entries yet.");
		return;
	}

	player->sendStoreHistory(totalPages, pages, filter);

}

void Game::queueSendStoreAlertToUser(uint32_t playerId, std::string message, StoreErrors_t storeErrorCode)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	player->sendStoreError(storeErrorCode, message);
}

void Game::playerBrowseField(uint32_t playerId, const Position& pos)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	const Position& playerPos = player->getPosition();
	if (playerPos.z != pos.z) {
		player->sendCancelMessage(playerPos.z > pos.z ? RETURNVALUE_FIRSTGOUPSTAIRS : RETURNVALUE_FIRSTGODOWNSTAIRS);
		return;
	}

	if (!Position::areInRange<1, 1>(playerPos, pos)) {
		std::forward_list<Direction> listDir;
		if (player->getPathTo(pos, listDir, 0, 1, true, true)) {
			g_dispatcher.addTask(createTask(std::bind(&Game::playerAutoWalk,
											this, player->getID(), listDir)));
			SchedulerTask* task = createSchedulerTask(400, std::bind(
									  &Game::playerBrowseField, this, playerId, pos
								  ));
			player->setNextWalkActionTask(task);
		} else {
			player->sendCancelMessage(RETURNVALUE_THEREISNOWAY);
		}
		return;
	}

	Tile* tile = map.getTile(pos);
	if (!tile) {
		return;
	}

	if (!g_events->eventPlayerOnBrowseField(player, pos)) {
		return;
	}

	Container* container;

	auto it = browseFields.find(tile);
	if (it == browseFields.end()) {
		container = new Container(tile);
		container->incrementReferenceCounter();
		browseFields[tile] = container;
		g_scheduler.addEvent(createSchedulerTask(30000, std::bind(&Game::decreaseBrowseFieldRef, this, tile->getPosition())));
	} else {
		container = it->second;
	}

	uint8_t dummyContainerId = 0xF - ((pos.x % 3) * 3 + (pos.y % 3));
	Container* openContainer = player->getContainerByID(dummyContainerId);
	if (openContainer) {
		player->onCloseContainer(openContainer);
		player->closeContainer(dummyContainerId);
	} else {
		player->addContainer(dummyContainerId, container);
		player->sendContainer(dummyContainerId, container, false, 0);
	}
}

void Game::playerSeekInContainer(uint32_t playerId, uint8_t containerId, uint16_t index)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	Container* container = player->getContainerByID(containerId);
	if (!container || !container->hasPagination()) {
		return;
	}

	if ((index % container->capacity()) != 0 || index >= container->size()) {
		return;
	}

	player->setContainerIndex(containerId, index);
	player->sendContainer(containerId, container, container->hasParent(), index);
}

void Game::playerUpdateHouseWindow(uint32_t playerId, uint8_t listId, uint32_t windowTextId, const std::string& text)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	uint32_t internalWindowTextId;
	uint32_t internalListId;

	House* house = player->getEditHouse(internalWindowTextId, internalListId);
	if (house && house->canEditAccessList(internalListId, player) && internalWindowTextId == windowTextId && listId == 0) {
		house->setAccessList(internalListId, text);
	}

	player->setEditHouse(nullptr);
}

void Game::playerRequestTrade(uint32_t playerId, const Position& pos, uint8_t stackPos,
							  uint32_t tradePlayerId, uint16_t spriteId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	Player* tradePartner = getPlayerByID(tradePlayerId);
	if (!tradePartner || tradePartner == player) {
		player->sendTextMessage(MESSAGE_INFO_DESCR, "Sorry, not possible.");
		return;
	}

	if (player->hasCondition(CONDITION_EXHAUST, 1)) {
		player->sendTextMessage(MESSAGE_STATUS_SMALL, "You can't trade very fast.");
		return;
	}

	if (Condition* conditiontrade = Condition::createCondition(CONDITIONID_DEFAULT, CONDITION_EXHAUST, 300, 0, false, 8)) {
		player->addCondition(conditiontrade);
	}

	if (!Position::areInRange<2, 2, 0>(tradePartner->getPosition(), player->getPosition())) {
		std::ostringstream ss;
		ss << tradePartner->getName() << " tells you to move closer.";
		player->sendTextMessage(MESSAGE_INFO_DESCR, ss.str());
		return;
	}

	if (!canThrowObjectTo(tradePartner->getPosition(), player->getPosition())) {
		player->sendCancelMessage(RETURNVALUE_CREATUREISNOTREACHABLE);
		return;
	}

	if (pos.y <= 11) {
		player->sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
		return;
	}

	Thing* tradeThing = internalGetThing(player, pos, stackPos, 0, STACKPOS_TOPDOWN_ITEM);
	if (!tradeThing) {
		player->sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
		return;
	}

	Item* tradeItem = tradeThing->getItem();
	if (tradeItem->getClientID() != spriteId || !tradeItem->isPickupable() || tradeItem->hasAttribute(ITEM_ATTRIBUTE_UNIQUEID)) {
		player->sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
		return;
	}

	const Position& playerPosition = player->getPosition();
	const Position& tradeItemPosition = tradeItem->getPosition();
	if (playerPosition.z != tradeItemPosition.z) {
		player->sendCancelMessage(playerPosition.z > tradeItemPosition.z ? RETURNVALUE_FIRSTGOUPSTAIRS : RETURNVALUE_FIRSTGODOWNSTAIRS);
		return;
	}

	if (!Position::areInRange<1, 1>(tradeItemPosition, playerPosition)) {
		std::forward_list<Direction> listDir;
		if (player->getPathTo(pos, listDir, 0, 1, true, true)) {
			g_dispatcher.addTask(createTask(std::bind(&Game::playerAutoWalk,
											this, player->getID(), listDir)));

			SchedulerTask* task = createSchedulerTask(RANGE_REQUEST_TRADE_INTERVAL, std::bind(&Game::playerRequestTrade, this,
								  playerId, pos, stackPos, tradePlayerId, spriteId));
			player->setNextWalkActionTask(task);
		} else {
			player->sendCancelMessage(RETURNVALUE_THEREISNOWAY);
		}
		return;
	}

	Container* tradeItemContainer = tradeItem->getContainer();
	if (tradeItemContainer) {
		for (const auto& it : tradeItems) {
			Item* item = it.first;
			if (tradeItem == item) {
				player->sendTextMessage(MESSAGE_INFO_DESCR, "This item is already being traded.");
				return;
			}
			if (player->imbuingItem() != nullptr) {
				player->sendTextMessage(MESSAGE_INFO_DESCR, "This item is already being traded.");
				return;
			}

			if (tradeItemContainer->isHoldingItem(item)) {
				player->sendTextMessage(MESSAGE_INFO_DESCR, "This item is already being traded.");
				return;
			}

			Container* container = item->getContainer();
			if (container && container->isHoldingItem(tradeItem)) {
				player->sendTextMessage(MESSAGE_INFO_DESCR, "This item is already being traded.");
				return;
			}
		}
	} else {
		for (const auto& it : tradeItems) {
			Item* item = it.first;
			if (tradeItem == item) {
				player->sendTextMessage(MESSAGE_INFO_DESCR, "This item is already being traded.");
				return;
			}

			if (player->imbuingItem() != nullptr) {
				player->sendTextMessage(MESSAGE_INFO_DESCR, "This item is already being traded.");
				return;
			}

			Container* container = item->getContainer();
			if (container && container->isHoldingItem(tradeItem)) {
				player->sendTextMessage(MESSAGE_INFO_DESCR, "This item is already being traded.");
				return;
			}
		}
	}

	Container* tradeContainer = tradeItem->getContainer();
	if (tradeContainer && tradeContainer->getItemHoldingCount() + 1 > 100) {
		player->sendTextMessage(MESSAGE_INFO_DESCR, "You can not trade more than 100 items.");
		return;
	}

	if (!g_events->eventPlayerOnTradeRequest(player, tradePartner, tradeItem)) {
		return;
	}

	internalStartTrade(player, tradePartner, tradeItem);
}

bool Game::internalStartTrade(Player* player, Player* tradePartner, Item* tradeItem)
{
	if (player->tradeState != TRADE_NONE && !(player->tradeState == TRADE_ACKNOWLEDGE && player->tradePartner == tradePartner)) {
		player->sendCancelMessage(RETURNVALUE_YOUAREALREADYTRADING);
		return false;
	} else if (tradePartner->tradeState != TRADE_NONE && tradePartner->tradePartner != player) {
		player->sendCancelMessage(RETURNVALUE_THISPLAYERISALREADYTRADING);
		return false;
	}

	if (player->imbuingItem() != nullptr) {
		player->sendTextMessage(MESSAGE_INFO_DESCR, "This item is already being traded.");
		return false;
	}
	if (tradePartner->imbuingItem() != nullptr) {
		tradePartner->sendTextMessage(MESSAGE_INFO_DESCR, "This item is already being traded.");
		return false;
	}

	player->tradePartner = tradePartner;
	player->tradeItem = tradeItem;
	player->tradeState = TRADE_INITIATED;
	tradeItem->incrementReferenceCounter();
	tradeItems[tradeItem] = player->getID();

	player->sendTradeItemRequest(player->getName(), tradeItem, true);

	if (tradePartner->tradeState == TRADE_NONE) {
		std::ostringstream ss;
		ss << player->getName() << " wants to trade with you.";
		tradePartner->sendTextMessage(MESSAGE_EVENT_ADVANCE, ss.str());
		tradePartner->tradeState = TRADE_ACKNOWLEDGE;
		tradePartner->tradePartner = player;
	} else {
		Item* counterOfferItem = tradePartner->tradeItem;
		player->sendTradeItemRequest(tradePartner->getName(), counterOfferItem, false);
		tradePartner->sendTradeItemRequest(player->getName(), tradeItem, false);
	}

	return true;
}

void Game::playerAcceptTrade(uint32_t playerId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	if (!(player->getTradeState() == TRADE_ACKNOWLEDGE || player->getTradeState() == TRADE_INITIATED)) {
		return;
	}

	Player* tradePartner = player->tradePartner;
	if (!tradePartner) {
		return;
	}

	if (!canThrowObjectTo(tradePartner->getPosition(), player->getPosition())) {
		player->sendCancelMessage(RETURNVALUE_CREATUREISNOTREACHABLE);
		return;
	}

	if (player->imbuingItem() != nullptr) {
		player->sendTextMessage(MESSAGE_INFO_DESCR, "This item is already being traded.");
		return;
	}
	if (tradePartner->imbuingItem() != nullptr) {
		tradePartner->sendTextMessage(MESSAGE_INFO_DESCR, "This item is already being traded.");
		return;
	}

	player->setTradeState(TRADE_ACCEPT);

	if (tradePartner->getTradeState() == TRADE_ACCEPT) {
		Item* tradeItem1 = player->tradeItem;
		Item* tradeItem2 = tradePartner->tradeItem;

		if (!g_events->eventPlayerOnTradeAccept(player, tradePartner, tradeItem1, tradeItem2)) {
			internalCloseTrade(player);
			return;
		}

		player->setTradeState(TRADE_TRANSFER);
		tradePartner->setTradeState(TRADE_TRANSFER);

		auto it = tradeItems.find(tradeItem1);
		if (it != tradeItems.end()) {
			ReleaseItem(it->first);
			tradeItems.erase(it);
		}

		it = tradeItems.find(tradeItem2);
		if (it != tradeItems.end()) {
			ReleaseItem(it->first);
			tradeItems.erase(it);
		}

		bool isSuccess = false;

		ReturnValue ret1 = internalAddItem(tradePartner, tradeItem1, INDEX_WHEREEVER, 0, true);
		ReturnValue ret2 = internalAddItem(player, tradeItem2, INDEX_WHEREEVER, 0, true);
		if (ret1 == RETURNVALUE_NOERROR && ret2 == RETURNVALUE_NOERROR) {
			ret1 = internalRemoveItem(tradeItem1, tradeItem1->getItemCount(), true);
			ret2 = internalRemoveItem(tradeItem2, tradeItem2->getItemCount(), true);
			if (ret1 == RETURNVALUE_NOERROR && ret2 == RETURNVALUE_NOERROR) {
				Cylinder* cylinder1 = tradeItem1->getParent();
				Cylinder* cylinder2 = tradeItem2->getParent();

				uint32_t count1 = tradeItem1->getItemCount();
				uint32_t count2 = tradeItem2->getItemCount();

				ret1 = internalMoveItem(cylinder1, tradePartner, INDEX_WHEREEVER, tradeItem1, count1, nullptr, FLAG_IGNOREAUTOSTACK, nullptr, tradeItem2);
				if (ret1 == RETURNVALUE_NOERROR) {
					internalMoveItem(cylinder2, player, INDEX_WHEREEVER, tradeItem2, count2, nullptr, FLAG_IGNOREAUTOSTACK);

					tradeItem1->onTradeEvent(ON_TRADE_TRANSFER, tradePartner);
					tradeItem2->onTradeEvent(ON_TRADE_TRANSFER, player);

					isSuccess = true;
				}
			}
		}

		if (!isSuccess) {
			std::string errorDescription;

			if (tradePartner->tradeItem) {
				errorDescription = getTradeErrorDescription(ret1, tradeItem1);
				tradePartner->sendTextMessage(MESSAGE_EVENT_ADVANCE, errorDescription);
				tradePartner->tradeItem->onTradeEvent(ON_TRADE_CANCEL, tradePartner);
			}

			if (player->tradeItem) {
				errorDescription = getTradeErrorDescription(ret2, tradeItem2);
				player->sendTextMessage(MESSAGE_EVENT_ADVANCE, errorDescription);
				player->tradeItem->onTradeEvent(ON_TRADE_CANCEL, player);
			}
		}

		player->setTradeState(TRADE_NONE);
		player->tradeItem = nullptr;
		player->tradePartner = nullptr;
		player->sendTradeClose();

		tradePartner->setTradeState(TRADE_NONE);
		tradePartner->tradeItem = nullptr;
		tradePartner->tradePartner = nullptr;
		tradePartner->sendTradeClose();

		// saving players
		IOLoginData::savePlayer(player);
		IOLoginData::savePlayer(tradePartner);

	}
}

std::string Game::getTradeErrorDescription(ReturnValue ret, Item* item)
{
	if (item) {
		if (ret == RETURNVALUE_NOTENOUGHCAPACITY) {
			std::ostringstream ss;
			ss << "You do not have enough capacity to carry";

			if (item->isStackable() && item->getItemCount() > 1) {
				ss << " these objects.";
			} else {
				ss << " this object.";
			}

			ss << std::endl << ' ' << item->getWeightDescription();
			return ss.str();
		} else if (ret == RETURNVALUE_NOTENOUGHROOM || ret == RETURNVALUE_CONTAINERNOTENOUGHROOM) {
			std::ostringstream ss;
			ss << "You do not have enough room to carry";

			if (item->isStackable() && item->getItemCount() > 1) {
				ss << " these objects.";
			} else {
				ss << " this object.";
			}

			return ss.str();
		}
	}
	return "Trade could not be completed.";
}

void Game::playerLookInTrade(uint32_t playerId, bool lookAtCounterOffer, uint8_t index)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	Player* tradePartner = player->tradePartner;
	if (!tradePartner) {
		return;
	}

	Item* tradeItem;
	if (lookAtCounterOffer) {
		tradeItem = tradePartner->getTradeItem();
	} else {
		tradeItem = player->getTradeItem();
	}

	if (!tradeItem) {
		return;
	}

	const Position& playerPosition = player->getPosition();
	const Position& tradeItemPosition = tradeItem->getPosition();

	int32_t lookDistance = std::max<int32_t>(Position::getDistanceX(playerPosition, tradeItemPosition),
											 Position::getDistanceY(playerPosition, tradeItemPosition));
	if (index == 0) {
		g_events->eventPlayerOnLookInTrade(player, tradePartner, tradeItem, lookDistance);
		return;
	}

	Container* tradeContainer = tradeItem->getContainer();
	if (!tradeContainer) {
		return;
	}

	std::vector<const Container*> containers {tradeContainer};
	size_t i = 0;
	while (i < containers.size()) {
		const Container* container = containers[i++];
		for (Item* item : container->getItemList()) {
			Container* tmpContainer = item->getContainer();
			if (tmpContainer) {
				containers.push_back(tmpContainer);
			}

			if (--index == 0) {
				g_events->eventPlayerOnLookInTrade(player, tradePartner, item, lookDistance);
				return;
			}
		}
	}
}

void Game::playerCloseTrade(uint32_t playerId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	internalCloseTrade(player);
}

void Game::internalCloseTrade(Player* player)
{
	Player* tradePartner = player->tradePartner;
	if ((tradePartner && tradePartner->getTradeState() == TRADE_TRANSFER) || player->getTradeState() == TRADE_TRANSFER) {
		return;
	}

	if (player->getTradeItem()) {
		auto it = tradeItems.find(player->getTradeItem());
		if (it != tradeItems.end()) {
			ReleaseItem(it->first);
			tradeItems.erase(it);
		}

		player->tradeItem->onTradeEvent(ON_TRADE_CANCEL, player);
		player->tradeItem = nullptr;
	}

	player->setTradeState(TRADE_NONE);
	player->tradePartner = nullptr;

	player->sendTextMessage(MESSAGE_STATUS_SMALL, "Trade cancelled.");
	player->sendTradeClose();

	if (tradePartner) {
		if (tradePartner->getTradeItem()) {
			auto it = tradeItems.find(tradePartner->getTradeItem());
			if (it != tradeItems.end()) {
				ReleaseItem(it->first);
				tradeItems.erase(it);
			}

			tradePartner->tradeItem->onTradeEvent(ON_TRADE_CANCEL, tradePartner);
			tradePartner->tradeItem = nullptr;
		}

		tradePartner->setTradeState(TRADE_NONE);
		tradePartner->tradePartner = nullptr;

		tradePartner->sendTextMessage(MESSAGE_STATUS_SMALL, "Trade cancelled.");
		tradePartner->sendTradeClose();
	}
}

void Game::playerPurchaseItem(uint32_t playerId, uint16_t spriteId, uint8_t count, uint8_t amount,
							  bool ignoreCap/* = false*/, bool inBackpacks/* = false*/)
{
	if (amount == 0 || amount > 100) {
		return;
	}

	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	int32_t onBuy, onSell;

	Npc* merchant = player->getShopOwner(onBuy, onSell);
	if (!merchant) {
		return;
	}

	const ItemType& it = Item::items.getItemIdByClientId(spriteId);
	if (it.id == 0) {
		return;
	}

	uint8_t subType;
	if (it.isSplash() || it.isFluidContainer()) {
		subType = clientFluidToServer(count);
	} else {
		subType = count;
	}

	if (!player->hasShopItemForSale(it.id, subType)) {
		return;
	}

	merchant->onPlayerTrade(player, onBuy, it.id, subType, amount, ignoreCap, inBackpacks);
}

void Game::playerSellItem(uint32_t playerId, uint16_t spriteId, uint8_t count, uint8_t amount, bool ignoreEquipped)
{
	if (amount == 0 || amount > 100) {
		return;
	}

	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	int32_t onBuy, onSell;

	Npc* merchant = player->getShopOwner(onBuy, onSell);
	if (!merchant) {
		return;
	}

	const ItemType& it = Item::items.getItemIdByClientId(spriteId);
	if (it.id == 0) {
		return;
	}

	uint8_t subType;
	if (it.isSplash() || it.isFluidContainer()) {
		subType = clientFluidToServer(count);
	} else {
		subType = count;
	}

	merchant->onPlayerTrade(player, onSell, it.id, subType, amount, ignoreEquipped);
}

void Game::playerCloseShop(uint32_t playerId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	player->closeShopWindow();
}

void Game::playerLookInShop(uint32_t playerId, uint16_t spriteId, uint8_t count)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	int32_t onBuy, onSell;

	Npc* merchant = player->getShopOwner(onBuy, onSell);
	if (!merchant) {
		return;
	}

	const ItemType& it = Item::items.getItemIdByClientId(spriteId);
	if (it.id == 0) {
		return;
	}

	int32_t subType;
	if (it.isFluidContainer() || it.isSplash()) {
		subType = clientFluidToServer(count);
	} else {
		subType = count;
	}

	if (!player->hasShopItemForSale(it.id, subType)) {
		return;
	}

	if (!g_events->eventPlayerOnLookInShop(player, &it, subType)) {
		return;
	}

	std::ostringstream ss;
	ss << "You see " << Item::getDescription(it, 1, nullptr, subType);
	player->sendTextMessage(MESSAGE_INFO_DESCR, ss.str());
}

void Game::playerLookAt(uint32_t playerId, const Position& pos, uint8_t stackPos)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	if (player->hasCondition(CONDITION_EXHAUST, 1)) {
		player->sendTextMessage(MESSAGE_STATUS_SMALL, "You can't look very fast.");
		return;
	}

	if (Condition* conditionlook = Condition::createCondition(CONDITIONID_DEFAULT, CONDITION_EXHAUST, 100, 0, false, 7)) {
		player->addCondition(conditionlook);
	}

	Thing* thing = internalGetThing(player, pos, stackPos, 0, STACKPOS_LOOK);
	if (!thing) {
		player->sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
		return;
	}

	Position thingPos = thing->getPosition();
	if (!player->canSee(thingPos)) {
		player->sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
		return;
	}

	Position playerPos = player->getPosition();

	int32_t lookDistance;
	if (thing != player) {
		lookDistance = std::max<int32_t>(Position::getDistanceX(playerPos, thingPos), Position::getDistanceY(playerPos, thingPos));
		if (playerPos.z != thingPos.z) {
			lookDistance += 15;
		}
	} else {
		lookDistance = -1;
	}

	if(Condition* conditionlook = Condition::createCondition(CONDITIONID_DEFAULT, CONDITION_EXHAUST, 1000, 0, false, 1)) {
		player->addCondition(conditionlook);
	}

	g_events->eventPlayerOnLook(player, pos, thing, stackPos, lookDistance);
}

void Game::playerLookInBattleList(uint32_t playerId, uint32_t creatureId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	if (player->hasCondition(CONDITION_EXHAUST, 1)) {
		player->sendTextMessage(MESSAGE_STATUS_SMALL, "You can't look very fast.");
		return;
	}

	if (Condition* conditionlook = Condition::createCondition(CONDITIONID_DEFAULT, CONDITION_EXHAUST, 100, 0, false, 7)) {
		player->addCondition(conditionlook);
	}

	Creature* creature = getCreatureByID(creatureId);
	if (!creature) {
		return;
	}

	if (!player->canSeeCreature(creature)) {
		return;
	}

	const Position& creaturePos = creature->getPosition();
	if (!player->canSee(creaturePos)) {
		return;
	}

	int32_t lookDistance;
	if (creature != player) {
		const Position& playerPos = player->getPosition();
		lookDistance = std::max<int32_t>(Position::getDistanceX(playerPos, creaturePos), Position::getDistanceY(playerPos, creaturePos));
		if (playerPos.z != creaturePos.z) {
			lookDistance += 15;
		}
	} else {
		lookDistance = -1;
	}

	g_events->eventPlayerOnLookInBattleList(player, creature, lookDistance);
}

void Game::playerQuickLoot(uint32_t playerId, const Position& pos, uint16_t spriteId, uint8_t stackPos, Item* defaultItem)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	if (!player->canDoAction()) {
		uint32_t delay = player->getNextActionTime();
		SchedulerTask* task = createSchedulerTask(delay, std::bind(&Game::playerQuickLoot,
																   this, player->getID(), pos, spriteId, stackPos, defaultItem));
		player->setNextActionTask(task);
		return;
	}

	if (pos.x != 0xffff) {
		if (!Position::areInRange<1, 1, 0>(pos, player->getPosition())) {
			//need to walk to the corpse first before looting it
			std::forward_list<Direction> listDir;
			if (player->getPathTo(pos, listDir, 0, 1, true, true)) {
				g_dispatcher.addTask(createTask(std::bind(&Game::playerAutoWalk, this, player->getID(), listDir)));
				SchedulerTask* task = createSchedulerTask(0, std::bind(&Game::playerQuickLoot,
																	   this, player->getID(), pos, spriteId, stackPos, defaultItem));
				player->setNextWalkActionTask(task);
			} else {
				player->sendCancelMessage(RETURNVALUE_THEREISNOWAY);
			}

			return;
		}
	} else if (!player->isPremium()) {
		player->sendCancelMessage("You must be premium.");
		return;
	}

	player->setNextActionTask(nullptr);

	Item* item = nullptr;
	if (!defaultItem) {
		Thing* thing = internalGetThing(player, pos, stackPos, spriteId, STACKPOS_FIND_THING);
		if (!thing) {
			player->sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
			return;
		}

		item = thing->getItem();
	} else {
		item = defaultItem;
	}

	if (!item || !item->getParent()) {
		player->sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
		return;
	}

	Container* corpse = nullptr;
	if (pos.x == 0xffff) {
		corpse = item->getParent()->getContainer();
	} else {
		corpse = item->getContainer();
	}

	if (!corpse || corpse->hasAttribute(ITEM_ATTRIBUTE_UNIQUEID) || corpse->hasAttribute(ITEM_ATTRIBUTE_ACTIONID)) {
		player->sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
		return;
	}

	if (!corpse->isRewardCorpse()) {
		uint32_t corpseOwner = corpse->getCorpseOwner();
		if (corpseOwner != 0 && !player->canOpenCorpse(corpseOwner)) {
			player->sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
			return;
		}
	}

	if (pos.x == 0xffff) {
		uint32_t worth = item->getWorth();
		ObjectCategory_t category = getObjectCategory(item);
		ReturnValue ret = internalQuickLootItem(player, item, category);

		std::stringstream ss;
		if (ret == RETURNVALUE_NOTENOUGHCAPACITY) {
			ss << "Attention! The loot you are trying to pick up is too heavy for you to carry.";
		} else if (ret == RETURNVALUE_NOTENOUGHROOM) {
			ss << "Attention! The container for " << getObjectCategoryName(category) << " is full.";
		} else {
			if (ret == RETURNVALUE_NOERROR) {
				player->sendLootStats(item);
				ss << "You looted ";
			} else {
				ss << "You could not loot ";
			}

			if (worth != 0) {
				ss << worth << " gold.";
			} else {
				ss << "1 item.";
			}

			player->sendTextMessage(MESSAGE_LOOT, ss.str());
			return;
		}

		if (player->lastQuickLootNotification + 15000 < OTSYS_TIME()) {
			player->sendTextMessage(MESSAGE_STATUS_WARNING, ss.str());
		} else {
			player->sendTextMessage(MESSAGE_EVENT_DEFAULT, ss.str());
		}

		player->lastQuickLootNotification = OTSYS_TIME();
	} else {
		if (corpse->isRewardCorpse()) {
			g_actions->useItem(player, pos, 0, corpse, false);
		} else {
			internalQuickLootCorpse(player, corpse);
		}
	}

	return;
}

void Game::playerSetLootContainer(uint32_t playerId, ObjectCategory_t category, const Position& pos, uint16_t spriteId, uint8_t stackPos)
{
	Player* player = getPlayerByID(playerId);
	if (!player || pos.x != 0xffff) {
		return;
	}

	Thing* thing = internalGetThing(player, pos, stackPos, spriteId, STACKPOS_USEITEM);
	if (!thing) {
		player->sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
		return;
	}

	Container* container = thing->getContainer();
	if (!container) {
		player->sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
		return;
	}

	if (container->getHoldingPlayer() != player) {
		player->sendCancelMessage("You must be holding the container to set it as a loot container.");
		return;
	}

	Container* previousContainer = player->setLootContainer(category, container);
	player->sendLootContainers();

	Cylinder* parent = container->getParent();
	if (parent) {
		parent->updateThing(container, container->getID(), container->getItemCount());
	}

	if (previousContainer != nullptr) {
		parent = previousContainer->getParent();
		if (parent) {
			parent->updateThing(previousContainer, previousContainer->getID(), previousContainer->getItemCount());
		}
	}
}

void Game::playerClearLootContainer(uint32_t playerId, ObjectCategory_t category)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	Container* previousContainer = player->setLootContainer(category, nullptr);
	player->sendLootContainers();

	if (previousContainer != nullptr) {
		Cylinder* parent = previousContainer->getParent();
		if (parent) {
			parent->updateThing(previousContainer, previousContainer->getID(), previousContainer->getItemCount());
		}
	}
}

void Game::playerSetQuickLootFallback(uint32_t playerId, bool fallback)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	player->quickLootFallbackToMainContainer = fallback;
}

void Game::playerQuickLootBlackWhitelist(uint32_t playerId, QuickLootFilter_t filter, std::vector<uint16_t> clientIds)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	player->quickLootFilter = filter;
	player->quickLootListClientIds = clientIds;
}

void Game::playerRequestLockFind(uint32_t playerId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	std::map<uint16_t, uint16_t> itemMap;
	uint16_t count = 0;
	DepotLocker* depotLocker = player->getDepotLocker(player->getLastDepotId());
	if (!depotLocker) {
		return;
	}

	for (Item* locker : depotLocker->getItemList()) {
		Container* c = locker->getContainer();
		if (c && c->empty()) {
			continue;
		}

		if (c) {
			for (ContainerIterator it = c->iterator(); it.hasNext(); it.advance()) {
				auto itt = itemMap.find((*it)->getID());
				if (itt == itemMap.end()) {
					itemMap[(*it)->getID()] = Item::countByType((*it), -1);
					count++;
				} else {
					itemMap[(*it)->getID()] += Item::countByType((*it), -1);
				}
			}
		}
	}

	player->sendLockerItems(itemMap, count);
	return;
}

void Game::playerCancelAttackAndFollow(uint32_t playerId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	playerSetAttackedCreature(playerId, 0);
	playerFollowCreature(playerId, 0);
	player->stopWalk();
}

void Game::playerSetAttackedCreature(uint32_t playerId, uint32_t creatureId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	if (player->getAttackedCreature() && creatureId == 0) {
		player->setAttackedCreature(nullptr);
		player->sendCancelTarget();
		return;
	}

	Creature* attackCreature = getCreatureByID(creatureId);
	if (!attackCreature) {
		player->setAttackedCreature(nullptr);
		player->sendCancelTarget();
		return;
	}

	Npc* attackedNpc = attackCreature->getNpc();
	if(attackedNpc) {
		SpectatorHashSet spectators;
		spectators.insert(attackedNpc);
		map.getSpectators(spectators, player->getPosition(), true, true);

		internalCreatureSay(player, TALKTYPE_SAY, "Hi", false, &spectators);
		spectators.clear();
		spectators.insert(attackedNpc);
		if (attackedNpc->getSpeechBubble() == SPEECHBUBBLE_TRADE )
			internalCreatureSay(player, TALKTYPE_PRIVATE_PN, "Trade", false, &spectators);
		else
			internalCreatureSay(player, TALKTYPE_PRIVATE_PN, "Sail", false, &spectators);

		player->setAttackedCreature(nullptr);
		player->sendCancelTarget();
		return;
	}


	ReturnValue ret = Combat::canTargetCreature(player, attackCreature);
	if (ret != RETURNVALUE_NOERROR) {
		player->sendCancelMessage(ret);
		player->sendCancelTarget();
		player->setAttackedCreature(nullptr);
		return;
	}

	player->setAttackedCreature(attackCreature);
	g_dispatcher.addTask(createTask(std::bind(&Game::updateCreatureWalk, this, player->getID())));
}

void Game::playerNPCSay(uint32_t playerId, uint32_t creatureId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	Creature* creature = getCreatureByID(creatureId);
	if (!creature) {
		return;
	}

	Npc* creatureNpc = creature->getNpc();
	if(creatureNpc) {
		SpectatorHashSet spectators;
		spectators.insert(creatureNpc);
		map.getSpectators(spectators, player->getPosition(), true, true);

		internalCreatureSay(player, TALKTYPE_SAY, "Hi", false, &spectators);
		spectators.clear();
		spectators.insert(creatureNpc);
		if (creatureNpc->getSpeechBubble() == SPEECHBUBBLE_TRADE )
			internalCreatureSay(player, TALKTYPE_PRIVATE_PN, "Trade", false, &spectators);
		else
			internalCreatureSay(player, TALKTYPE_PRIVATE_PN, "Sail", false, &spectators);

		return;
	}
}

void Game::playerFollowCreature(uint32_t playerId, uint32_t creatureId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	player->setAttackedCreature(nullptr);
	g_dispatcher.addTask(createTask(std::bind(&Game::updateCreatureWalk, this, player->getID())));
	player->setFollowCreature(getCreatureByID(creatureId));
}

void Game::playerSetFightModes(uint32_t playerId, fightMode_t fightMode, bool chaseMode, bool secureMode)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	player->setFightMode(fightMode);
	player->setChaseMode(chaseMode);
	player->setSecureMode(secureMode);
}

void Game::playerRequestAddVip(uint32_t playerId, const std::string& name)
{
	if (name.length() > 25) {
		return;
	}

	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	Player* vipPlayer = getPlayerByName(name);
	if (!vipPlayer) {
		uint32_t guid;
		bool specialVip;
		std::string formattedName = name;
		if (!IOLoginData::getGuidByNameEx(guid, specialVip, formattedName)) {
			player->sendTextMessage(MESSAGE_STATUS_SMALL, "A player with this name does not exist.");
			return;
		}

		if (specialVip && !player->hasFlag(PlayerFlag_SpecialVIP)) {
			player->sendTextMessage(MESSAGE_STATUS_SMALL, "You can not add this player.");
			return;
		}

		player->addVIP(guid, formattedName, VIPSTATUS_OFFLINE);
	} else {
		if (vipPlayer->hasFlag(PlayerFlag_SpecialVIP) && !player->hasFlag(PlayerFlag_SpecialVIP)) {
			player->sendTextMessage(MESSAGE_STATUS_SMALL, "You can not add this player.");
			return;
		}

		if (!vipPlayer->isInGhostMode() || player->isAccessPlayer()) {
			player->addVIP(vipPlayer->getGUID(), vipPlayer->getName(), VIPSTATUS_ONLINE);
		} else {
			player->addVIP(vipPlayer->getGUID(), vipPlayer->getName(), VIPSTATUS_OFFLINE);
		}
	}
}

void Game::playerRequestRemoveVip(uint32_t playerId, uint32_t guid)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	player->removeVIP(guid);
}

void Game::playerRequestEditVip(uint32_t playerId, uint32_t guid, const std::string& description, uint32_t icon, bool notify)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	player->editVIP(guid, description, icon, notify);
}

void Game::playerApplyImbuement(uint32_t playerId, uint32_t imbuementid, uint8_t slot, bool protectionCharm)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	if (!player->inImbuing()) {
		return;	
	}

	Imbuement* imbuement = g_imbuements.getImbuement(imbuementid);
	if(!imbuement) {
		return;
	}

	Item* item = player->imbuing;
	if(item == nullptr) {
		return;
	}
	
	if (item->getTopParent() != player || item->getParent() == player) {
        return;
    }

	g_events->eventPlayerOnApplyImbuement(player, imbuement, item, slot, protectionCharm);
}

void Game::playerClearingImbuement(uint32_t playerid, uint8_t slot)
{
	Player* player = getPlayerByID(playerid);
	if (!player) {
		return;
	}

	if (!player->inImbuing()) {
		return;	
	}

	Item* item = player->imbuing;
	if(item == nullptr) {
		return;
	}

	g_events->eventPlayerClearImbuement(player, item, slot);
	return;
}

void Game::playerCloseImbuingWindow(uint32_t playerid)
{
	Player* player = getPlayerByID(playerid);
	if (!player) {
		return;
	}

	player->inImbuing(nullptr);
	return;
}

void Game::playerTurn(uint32_t playerId, Direction dir)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	if (!g_events->eventPlayerOnTurn(player, dir)) {
		return;
	}

	player->resetIdleTime();
	internalCreatureTurn(player, dir);
}

void Game::playerRequestOutfit(uint32_t playerId)
{
	if (!g_config.getBoolean(ConfigManager::ALLOW_CHANGEOUTFIT)) {
		return;
	}

	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	player->sendOutfitWindow();
}

void Game::playerToggleMount(uint32_t playerId, bool mount)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	player->toggleMount(mount);
}

void Game::playerChangeOutfit(uint32_t playerId, Outfit_t outfit)
{
	if (!g_config.getBoolean(ConfigManager::ALLOW_CHANGEOUTFIT)) {
		return;
	}

	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	if (player->hasCondition(CONDITION_EXHAUST, 1)) {
		player->sendTextMessage(MESSAGE_STATUS_SMALL, "You can't change outfit very fast.");
		return;
	}

	if (Condition* conditionoutfit = Condition::createCondition(CONDITIONID_DEFAULT, CONDITION_EXHAUST, 100, 0, false, 7)) {
		player->addCondition(conditionoutfit);
	}

	const Outfit* playerOutfit = Outfits::getInstance().getOutfitByLookType(player->getSex(), outfit.lookType);
	if (!playerOutfit) {
		outfit.lookMount = 0;
	}

	if (outfit.lookMount != 0) {
		Mount* mount = mounts.getMountByClientID(outfit.lookMount);
		if (!mount) {
			return;
		}

		if (!player->hasMount(mount)) {
			return;
		}

		if (player->isMounted()) {
			Mount* prevMount = mounts.getMountByID(player->getCurrentMount());
			if (prevMount) {
				changeSpeed(player, mount->speed - prevMount->speed);
			}

			player->setCurrentMount(mount->id);
		} else {
			player->setCurrentMount(mount->id);
			outfit.lookMount = 0;
		}
	} else if (player->isMounted()) {
		player->dismount();
	}

	if (player->canWear(outfit.lookType, outfit.lookAddons)) {
		player->defaultOutfit = outfit;

		if (player->hasCondition(CONDITION_OUTFIT)) {
			return;
		}

		internalCreatureChangeOutfit(player, outfit);
	}
}

void Game::playerShowQuestLog(uint32_t playerId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	if(!g_config.getBoolean(ConfigManager::QUEST_LUA))
		player->sendQuestLog();
	else
		g_events->eventPlayerOnRequestQuestLog(player);
}

void Game::playerShowQuestLine(uint32_t playerId, uint16_t questId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	if(!g_config.getBoolean(ConfigManager::QUEST_LUA))
	{
		Quest* quest = quests.getQuestByID(questId);
		if (!quest) {
			return;
		}

		player->sendQuestLine(quest);
	} else {
		g_events->eventPlayerOnRequestQuestLine(player, questId);
	}
}

void Game::playerSay(uint32_t playerId, uint16_t channelId, SpeakClasses type,
					 const std::string& receiver, const std::string& text)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	player->resetIdleTime();

	if (playerSaySpell(player, type, text)) {
		return;
	}

	uint32_t muteTime = player->isMuted();
	if (muteTime > 0) {
		std::ostringstream ss;
		ss << "You are still muted for " << muteTime << " seconds.";
		player->sendTextMessage(MESSAGE_STATUS_SMALL, ss.str());
		return;
	}


	if (!text.empty() && text.front() == '/' && player->isAccessPlayer()) {
		return;
	}

	std::string newText = text;
	std::string words = g_config.getString(ConfigManager::BLOCK_WORD);
	if (!words.empty()) {
		StringVector bw = explodeString(words, ";");
		for (const std::string& block_word : bw) {
			if (newText.find(block_word) != std::string::npos) {
				replaceString(newText, block_word, "bobba");
			}
		}
	}

	if (type != TALKTYPE_PRIVATE_PN) {
		player->removeMessageBuffer();
	}

	if (channelId == CHANNEL_CAST) {
		player->sendChannelMessage(player->getName(), newText, TALKTYPE_CHANNEL_R1, channelId);
	}

	switch (type) {
		case TALKTYPE_SAY:
			internalCreatureSay(player, TALKTYPE_SAY, newText, false);
			break;

		case TALKTYPE_WHISPER:
			playerWhisper(player, newText);
			break;

		case TALKTYPE_YELL:
			playerYell(player, newText);
			break;

		case TALKTYPE_PRIVATE_TO:
		case TALKTYPE_PRIVATE_RED_TO:
			playerSpeakTo(player, type, receiver, newText);
			break;

		case TALKTYPE_CHANNEL_O:
		case TALKTYPE_CHANNEL_Y:
		case TALKTYPE_CHANNEL_R1:
			g_chat->talkToChannel(*player, type, newText, channelId);
			break;

		case TALKTYPE_PRIVATE_PN:
			playerSpeakToNpc(player, newText);
			break;

		case TALKTYPE_BROADCAST:
			playerBroadcastMessage(player, newText);
			break;

		default:
			break;
	}
}

bool Game::playerSaySpell(Player* player, SpeakClasses type, const std::string& text)
{

	if (player->walkExhausted()) {
		return true;
	}

	std::string words = text;
	TalkActionResult_t result = g_talkActions->playerSaySpell(player, type, words);
	if (result == TALKACTION_BREAK) {
		return true;
	}

	result = g_spells->playerSaySpell(player, words);
	if (result == TALKACTION_BREAK) {
		// cancelando o push
		player->cancelPush();

		if (!g_config.getBoolean(ConfigManager::EMOTE_SPELLS)) {
			return internalCreatureSay(player, TALKTYPE_SAY, words, false);
		} else {
			return internalCreatureSay(player, TALKTYPE_MONSTER_SAY, words, false);
		}

	} else if (result == TALKACTION_FAILED) {
		return true;
	}

	return false;
}

bool Game::playerCalledSpell(Player* player, const std::string& text)
{
	std::string words = text;
	TalkActionResult_t result = g_spells->playerSaySpell(player, words, false);
	return result == TALKACTION_BREAK; 
}

void Game::playerWhisper(Player* player, const std::string& text)
{
	SpectatorHashSet spectators;
	map.getSpectators(spectators, player->getPosition(), false, false,
				  Map::maxClientViewportX, Map::maxClientViewportX,
				  Map::maxClientViewportY, Map::maxClientViewportY);

	//send to client
	for (Creature* spectator : spectators) {
		if (Player* spectatorPlayer = spectator->getPlayer()) {
			if (!Position::areInRange<1, 1>(player->getPosition(), spectatorPlayer->getPosition())) {
				spectatorPlayer->sendCreatureSay(player, TALKTYPE_WHISPER, "pspsps");
			} else {
				spectatorPlayer->sendCreatureSay(player, TALKTYPE_WHISPER, text);
			}
		}
	}

	//event method
	for (Creature* spectator : spectators) {
		spectator->onCreatureSay(player, TALKTYPE_WHISPER, text);
	}
}

bool Game::playerYell(Player* player, const std::string& text)
{
	if (player->hasCondition(CONDITION_YELLTICKS)) {
		player->sendCancelMessage(RETURNVALUE_YOUAREEXHAUSTED);
		return false;
	}

	uint32_t minimumLevel = g_config.getNumber(ConfigManager::YELL_MINIMUM_LEVEL);
	if (player->getLevel() < minimumLevel) {
		std::ostringstream ss;
		ss << "You may not yell unless you have reached level " << minimumLevel;
		if (g_config.getBoolean(ConfigManager::YELL_ALLOW_PREMIUM)) {
			if (player->isPremium()) {
				internalCreatureSay(player, TALKTYPE_YELL, asUpperCaseString(text), false);
				return true;
			} else {
				ss << " or have a premium account";
			}
		}
		ss << ".";
		player->sendTextMessage(MESSAGE_STATUS_SMALL, ss.str());
		return false;
	}

	if (player->getAccountType() < ACCOUNT_TYPE_GAMEMASTER) {
		Condition* condition = Condition::createCondition(CONDITIONID_DEFAULT, CONDITION_YELLTICKS, 30000, 0);
		player->addCondition(condition);
	}

	internalCreatureSay(player, TALKTYPE_YELL, asUpperCaseString(text), false);
	return true;
}

bool Game::playerSpeakTo(Player* player, SpeakClasses type, const std::string& receiver,
						 const std::string& text)
{
	Player* toPlayer = getPlayerByName(receiver);
	if (!toPlayer) {
		player->sendTextMessage(MESSAGE_STATUS_SMALL, "A player with this name is not online.");
		return false;
	}

	if (type == TALKTYPE_PRIVATE_RED_TO && (player->hasFlag(PlayerFlag_CanTalkRedPrivate) || player->getAccountType() >= ACCOUNT_TYPE_GAMEMASTER)) {
		type = TALKTYPE_PRIVATE_RED_FROM;
	} else {
		type = TALKTYPE_PRIVATE_FROM;
	}

	toPlayer->sendPrivateMessage(player, type, text);
	toPlayer->onCreatureSay(player, type, text);

	if (toPlayer->isInGhostMode() && !player->isAccessPlayer()) {
		player->sendTextMessage(MESSAGE_STATUS_SMALL, "A player with this name is not online.");
	} else {
		std::ostringstream ss;
		ss << "Message sent to " << toPlayer->getName() << '.';
		player->sendTextMessage(MESSAGE_STATUS_SMALL, ss.str());
	}
	return true;
}

void Game::playerSpeakToNpc(Player* player, const std::string& text)
{
	SpectatorHashSet spectators;
	map.getSpectators(spectators, player->getPosition());
	if (player->hasCondition(CONDITION_EXHAUST, 1)) {
		player->sendTextMessage(MESSAGE_STATUS_SMALL, "You can't speak very fast.");
		return;
	}

	if (Condition* conditionnpc = Condition::createCondition(CONDITIONID_DEFAULT, CONDITION_EXHAUST, 100, 0, false, 2)) {
		player->addCondition(conditionnpc);
	}

	for (Creature* spectator : spectators) {
		if (spectator->getNpc()) {
			spectator->onCreatureSay(player, TALKTYPE_PRIVATE_PN, text);
		}
	}
}

//--
bool Game::canThrowObjectTo(const Position& fromPos, const Position& toPos, bool checkLineOfSight /*= true*/,
							int32_t rangex /*= Map::maxClientViewportX*/, int32_t rangey /*= Map::maxClientViewportY*/) const
{
	return map.canThrowObjectTo(fromPos, toPos, checkLineOfSight, rangex, rangey);
}

bool Game::isSightClear(const Position& fromPos, const Position& toPos, bool floorCheck) const
{
	return map.isSightClear(fromPos, toPos, floorCheck);
}

bool Game::internalCreatureTurn(Creature* creature, Direction dir)
{
	if (creature->getDirection() == dir) {
		return false;
	}

	if (Player* player = creature->getPlayer()) {
		player->cancelPush();
	}
	creature->setDirection(dir);

	//send to client
	SpectatorHashSet spectators;
	map.getSpectators(spectators, creature->getPosition(), true, true);
	for (Creature* spectator : spectators) {
		spectator->getPlayer()->sendCreatureTurn(creature);
	}
	return true;
}

bool Game::internalCreatureSay(Creature* creature, SpeakClasses type, const std::string& text,
							   bool ghostMode, SpectatorHashSet* spectatorsPtr/* = nullptr*/, const Position* pos/* = nullptr*/)
{
	if (text.empty()) {
		return false;
	}

	if (!pos) {
		pos = &creature->getPosition();
	}

	SpectatorHashSet spectators;

	bool isSpectatorsPtrInvalid = (!spectatorsPtr || spectatorsPtr->empty());
	if (isSpectatorsPtrInvalid) {
        // This somewhat complex construct ensures that the cached SpectatorVec
        // is used if available and if it can be used, else a local vector is
        // used (hopefully the compiler will optimize away the construction of
        // the temporary when it's not used).

		if (type != TALKTYPE_YELL && type != TALKTYPE_MONSTER_YELL) {
			map.getSpectators(spectators, *pos, false, false, Map::maxClientViewportX, Map::maxClientViewportX, Map::maxClientViewportY, Map::maxClientViewportY);
		} else {
			map.getSpectators(spectators, *pos, true, false, 18, 18, 14, 14);
		}
	}

	//send to client
	for (Creature* spectator : ((isSpectatorsPtrInvalid) ? spectators : *spectatorsPtr)) {
		if (Player* tmpPlayer = spectator->getPlayer()) {
			if (!ghostMode || tmpPlayer->canSeeCreature(creature)) {
				tmpPlayer->sendCreatureSay(creature, type, text, pos);
			}
		}
	}

	//event method
	for (Creature* spectator : ((isSpectatorsPtrInvalid) ? spectators : *spectatorsPtr)) {
		spectator->onCreatureSay(creature, type, text);
		if (creature != spectator) {
			g_events->eventCreatureOnHear(spectator, creature, text, type);
		}
	}
	return true;
}

void Game::checkCreatureWalk(uint32_t creatureId)
{
	Creature* creature = getCreatureByID(creatureId);
	if (creature && creature->getHealth() > 0) {
		creature->onCreatureWalk();
		cleanup();
	}
}

void Game::updateCreatureWalk(uint32_t creatureId)
{
	Creature* creature = getCreatureByID(creatureId);
	if (creature && creature->getHealth() > 0) {
		creature->goToFollowCreature();
	}
}

void Game::checkCreatureAttack(uint32_t creatureId)
{
	Creature* creature = getCreatureByID(creatureId);
	if (creature && creature->getHealth() > 0) {
		creature->onAttacking(0);
	}
}

void Game::addCreatureCheck(Creature* creature)
{
	creature->creatureCheck = true;

	if (creature->inCheckCreaturesVector) {
		// already in a vector
		return;
	}

	creature->inCheckCreaturesVector = true;
	checkCreatureLists[uniform_random(0, EVENT_CREATURECOUNT - 1)].push_back(creature);
	creature->incrementReferenceCounter();
}

void Game::removeCreatureCheck(Creature* creature)
{
	if (creature->inCheckCreaturesVector) {
		creature->creatureCheck = false;
	}
}

void Game::checkCreatures(size_t index)
{
	g_scheduler.addEvent(createSchedulerTask(EVENT_CHECK_CREATURE_INTERVAL, std::bind(&Game::checkCreatures, this, (index + 1) % EVENT_CREATURECOUNT)));

	auto& checkCreatureList = checkCreatureLists[index];
	auto it = checkCreatureList.begin(), end = checkCreatureList.end();
	while (it != end) {
		Creature* creature = *it;

		if (creature->creatureCheck) {
			if (creature->getHealth() > 0) {
				creature->onThink(EVENT_CREATURE_THINK_INTERVAL);
				creature->onAttacking(EVENT_CREATURE_THINK_INTERVAL);
				creature->executeConditions(EVENT_CREATURE_THINK_INTERVAL);
			} else {
				creature->onDeath();
			}
			++it;
		} else {
			creature->inCheckCreaturesVector = false;
			it = checkCreatureList.erase(it);
			ReleaseCreature(creature);
		}
	}

	cleanup();
}

void Game::changeSpeed(Creature* creature, int32_t varSpeedDelta)
{
	int32_t varSpeed = creature->getSpeed() - creature->getBaseSpeed();
	varSpeed += varSpeedDelta;

	creature->setSpeed(varSpeed);

	//send to clients
	SpectatorHashSet spectators;
	map.getSpectators(spectators, creature->getPosition(), false, true);
	for (Creature* spectator : spectators) {
		spectator->getPlayer()->sendChangeSpeed(creature, creature->getStepSpeed());
	}
}

void Game::internalCreatureChangeOutfit(Creature* creature, const Outfit_t& outfit)
{
	if (!g_events->eventCreatureOnChangeOutfit(creature, outfit)) {
		return;
	}

	creature->setCurrentOutfit(outfit);

	if (creature->isInvisible()) {
		return;
	}

	//send to clients
	SpectatorHashSet spectators;
	map.getSpectators(spectators, creature->getPosition(), true, true);
	for (Creature* spectator : spectators) {
		spectator->getPlayer()->sendCreatureChangeOutfit(creature, outfit);
	}
}

void Game::internalCreatureChangeVisible(Creature* creature, bool visible)
{
	//send to clients
	SpectatorHashSet spectators;
	map.getSpectators(spectators, creature->getPosition(), true, true);
	for (Creature* spectator : spectators) {
		spectator->getPlayer()->sendCreatureChangeVisible(creature, visible);
	}
}

void Game::changeLight(const Creature* creature)
{
	//send to clients
	SpectatorHashSet spectators;
	map.getSpectators(spectators, creature->getPosition(), true, true);
	for (Creature* spectator : spectators) {
		spectator->getPlayer()->sendCreatureLight(creature);
	}
}

bool Game::combatBlockHit(CombatDamage& damage, Creature* attacker, Creature* target, bool checkDefense, bool checkArmor, bool field)
{
	if (damage.primary.type == COMBAT_NONE && damage.secondary.type == COMBAT_NONE) {
		return true;
	}

	if (target->getPlayer() && target->isInGhostMode()) {
		return true;
	}

	if (damage.primary.value > 0) {
		return false;
	}

	static const auto sendBlockEffect = [this](BlockType_t blockType, CombatType_t combatType, const Position& targetPos) {
		if (blockType == BLOCK_DEFENSE) {
			addMagicEffect(targetPos, CONST_ME_POFF);
		} else if (blockType == BLOCK_ARMOR) {
			addMagicEffect(targetPos, CONST_ME_BLOCKHIT);
		} else if (blockType == BLOCK_IMMUNITY) {
			uint8_t hitEffect = 0;
			switch (combatType) {
				case COMBAT_UNDEFINEDDAMAGE: {
					return;
				}
				case COMBAT_ENERGYDAMAGE:
				case COMBAT_FIREDAMAGE:
				case COMBAT_PHYSICALDAMAGE:
				case COMBAT_ICEDAMAGE:
				case COMBAT_DEATHDAMAGE: {
					hitEffect = CONST_ME_BLOCKHIT;
					break;
				}
				case COMBAT_EARTHDAMAGE: {
					hitEffect = CONST_ME_GREEN_RINGS;
					break;
				}
				case COMBAT_HOLYDAMAGE: {
					hitEffect = CONST_ME_HOLYDAMAGE;
					break;
				}
				default: {
					hitEffect = CONST_ME_POFF;
					break;
				}
			}
			addMagicEffect(targetPos, hitEffect);
		}
	};

	BlockType_t primaryBlockType, secondaryBlockType;
	if (damage.primary.type != COMBAT_NONE) {
		damage.primary.value = -damage.primary.value;
		primaryBlockType = target->blockHit(attacker, damage.primary.type, damage.primary.value, checkDefense, checkArmor, field);

		damage.primary.value = -damage.primary.value;
		sendBlockEffect(primaryBlockType, damage.primary.type, target->getPosition());
	} else {
		primaryBlockType = BLOCK_NONE;
	}

	if (damage.secondary.type != COMBAT_NONE) {
		damage.secondary.value = -damage.secondary.value;
		secondaryBlockType = target->blockHit(attacker, damage.secondary.type, damage.secondary.value, false, false, field);

		damage.secondary.value = -damage.secondary.value;
		sendBlockEffect(secondaryBlockType, damage.secondary.type, target->getPosition());
	} else {
		secondaryBlockType = BLOCK_NONE;
	}
	return (primaryBlockType != BLOCK_NONE) && (secondaryBlockType != BLOCK_NONE);
}

void Game::combatGetTypeInfo(CombatType_t combatType, Creature* target, TextColor_t& color, uint8_t& effect)
{
	switch (combatType) {
		case COMBAT_PHYSICALDAMAGE: {
			Item* splash = nullptr;
			switch (target->getRace()) {
				case RACE_VENOM:
					color = TEXTCOLOR_LIGHTGREEN;
					effect = CONST_ME_HITBYPOISON;
					splash = Item::CreateItem(ITEM_SMALLSPLASH, FLUID_GREEN);
					break;
				case RACE_BLOOD:
					color = TEXTCOLOR_RED;
					effect = CONST_ME_DRAWBLOOD;
					if (const Tile* tile = target->getTile()) {
						if (!tile->hasFlag(TILESTATE_PROTECTIONZONE)) {
							splash = Item::CreateItem(ITEM_SMALLSPLASH, FLUID_BLOOD);
						}
					}
					break;
				case RACE_UNDEAD:
					color = TEXTCOLOR_LIGHTGREY;
					effect = CONST_ME_HITAREA;
					break;
				case RACE_FIRE:
					color = TEXTCOLOR_ORANGE;
					effect = CONST_ME_DRAWBLOOD;
					break;
				case RACE_ENERGY:
					color = TEXTCOLOR_PURPLE;
					effect = CONST_ME_ENERGYHIT;
					break;
				default:
					color = TEXTCOLOR_NONE;
					effect = CONST_ME_NONE;
					break;
			}

			if (splash) {
				internalAddItem(target->getTile(), splash, INDEX_WHEREEVER, FLAG_NOLIMIT);
				splash->startDecaying();
			}

			break;
		}

		case COMBAT_ENERGYDAMAGE: {
			color = TEXTCOLOR_PURPLE;
			effect = CONST_ME_ENERGYHIT;
			break;
		}

		case COMBAT_EARTHDAMAGE: {
			color = TEXTCOLOR_LIGHTGREEN;
			effect = CONST_ME_GREEN_RINGS;
			break;
		}

		case COMBAT_DROWNDAMAGE: {
			color = TEXTCOLOR_LIGHTBLUE;
			effect = CONST_ME_LOSEENERGY;
			break;
		}
		case COMBAT_FIREDAMAGE: {
			color = TEXTCOLOR_ORANGE;
			effect = CONST_ME_HITBYFIRE;
			break;
		}
		case COMBAT_ICEDAMAGE: {
			color = TEXTCOLOR_SKYBLUE;
			effect = CONST_ME_ICEATTACK;
			break;
		}
		case COMBAT_HOLYDAMAGE: {
			color = TEXTCOLOR_YELLOW;
			effect = CONST_ME_HOLYDAMAGE;
			break;
		}
		case COMBAT_DEATHDAMAGE: {
			color = TEXTCOLOR_DARKRED;
			effect = CONST_ME_SMALLCLOUDS;
			break;
		}
		case COMBAT_LIFEDRAIN: {
			color = TEXTCOLOR_RED;
			effect = CONST_ME_MAGIC_RED;
			break;
		}
		default: {
			color = TEXTCOLOR_NONE;
			effect = CONST_ME_NONE;
			break;
		}
	}
}

void Game::combatGetEffect(CombatType_t combatType, Creature* target, uint8_t& effect)
{
	switch (combatType) {
		case COMBAT_PHYSICALDAMAGE: {
			switch (target->getRace()) {
				case RACE_VENOM:
					effect = CONST_ME_HITBYPOISON;
					break;
				case RACE_BLOOD:
					effect = CONST_ME_DRAWBLOOD;
					break;
				case RACE_UNDEAD:
					effect = CONST_ME_HITAREA;
					break;
				case RACE_FIRE:
					effect = CONST_ME_DRAWBLOOD;
					break;
				case RACE_ENERGY:
					effect = CONST_ME_ENERGYHIT;
					break;
				default:
					effect = CONST_ME_NONE;
					break;
			}

			break;
		}

		case COMBAT_ENERGYDAMAGE: {
			effect = CONST_ME_ENERGYHIT;
			break;
		}

		case COMBAT_EARTHDAMAGE: {
			effect = CONST_ME_GREEN_RINGS;
			break;
		}

		case COMBAT_DROWNDAMAGE: {
			effect = CONST_ME_LOSEENERGY;
			break;
		}
		case COMBAT_FIREDAMAGE: {
			effect = CONST_ME_HITBYFIRE;
			break;
		}
		case COMBAT_ICEDAMAGE: {
			effect = CONST_ME_ICEATTACK;
			break;
		}
		case COMBAT_HOLYDAMAGE: {
			effect = CONST_ME_HOLYDAMAGE;
			break;
		}
		case COMBAT_DEATHDAMAGE: {
			effect = CONST_ME_SMALLCLOUDS;
			break;
		}
		case COMBAT_LIFEDRAIN: {
			effect = CONST_ME_MAGIC_RED;
			break;
		}
		default: {
			effect = CONST_ME_NONE;
			break;
		}
	}
}

bool Game::combatChangeHealth(Creature* attacker, Creature* target, CombatDamage& damage, bool isEvent)
{
	const Position& targetPos = target->getPosition();
	if (damage.primary.value > 0) {
		if (target->getHealth() <= 0) {
			return false;
		}
		Player* attackerPlayer;
		if (attacker) {
			attackerPlayer = attacker->getPlayer();
		} else {
			attackerPlayer = nullptr;
		}

		Player* targetPlayer = target->getPlayer();
		if (attackerPlayer && targetPlayer && attackerPlayer->getSkull() == SKULL_BLACK && attackerPlayer->getSkullClient(targetPlayer) == SKULL_NONE) {
			return false;
		}

		if (damage.origin != ORIGIN_NONE && damage.origin != ORIGIN_CHARM) {
			const auto& events = target->getCreatureEvents(CREATURE_EVENT_HEALTHCHANGE);
			if (!events.empty()) {
				for (CreatureEvent* creatureEvent : events) {
					creatureEvent->executeHealthChange(target, attacker, damage);
				}
				damage.origin = ORIGIN_NONE;
				return combatChangeHealth(attacker, target, damage);
			}
		}

		int32_t realHealthChange = target->getHealth();
		target->gainHealth(attacker, damage.primary.value);
		realHealthChange = target->getHealth() - realHealthChange;

		if (realHealthChange > 0 && !target->isInGhostMode()) {
			std::stringstream ss;

			ss << realHealthChange << (realHealthChange != 1 ? " hitpoints." : " hitpoint.");
			std::string damageString = ss.str();

			std::string spectatorMessage;

			TextMessage message;
			message.position = targetPos;
			message.primary.value = realHealthChange;
			message.primary.color = TEXTCOLOR_MAYARED;

			SpectatorHashSet spectators;
			map.getSpectators(spectators, targetPos, false, true);
			for (Creature* spectator : spectators) {
				Player* tmpPlayer = spectator->getPlayer();
				if (tmpPlayer == attackerPlayer && attackerPlayer != targetPlayer) {
					ss.str({});
					ss << "You heal " << target->getNameDescription() << " for " << damageString;
					message.type = MESSAGE_HEALED;
					message.text = ss.str();
				} else if (tmpPlayer == targetPlayer) {
					ss.str({});
					if (!attacker) {
						ss << "You were healed";
					} else if (targetPlayer == attackerPlayer) {
						ss << "You heal yourself";
					} else {
						ss << "You were healed by " << attacker->getNameDescription();
					}
					ss << " for " << damageString;
					message.type = MESSAGE_HEALED;
					message.text = ss.str();
				} else {
					if (spectatorMessage.empty()) {
						ss.str({});
						if (!attacker) {
							ss << ucfirst(target->getNameDescription()) << " was healed";
						} else {
							ss << ucfirst(attacker->getNameDescription()) << " healed ";
							if (attacker == target) {
								ss << (targetPlayer ? (targetPlayer->getSex() == PLAYERSEX_FEMALE ? "herself" : "himself") : "itself");
							} else {
								ss << target->getNameDescription();
							}
						}
						ss << " for " << damageString;
						spectatorMessage = ss.str();
					}
					message.type = MESSAGE_HEALED_OTHERS;
					message.text = spectatorMessage;
				}
				tmpPlayer->sendTextMessage(message);
			}
		}
	} else {
		if (!target->isAttackable()) {
			if (!target->isInGhostMode()) {
				addMagicEffect(targetPos, CONST_ME_POFF);
			}
			return true;
		}

		Player* attackerPlayer;
		if (attacker) {
			attackerPlayer = attacker->getPlayer();
		} else {
			attackerPlayer = nullptr;
		}

		Player* targetPlayer = target->getPlayer();
		if (attackerPlayer && targetPlayer && attackerPlayer->getSkull() == SKULL_BLACK && attackerPlayer->getSkullClient(targetPlayer) == SKULL_NONE) {
			return false;
		}

		damage.primary.value = std::abs(damage.primary.value);
		damage.secondary.value = std::abs(damage.secondary.value);

		TextMessage message;
		message.position = targetPos;

		if (!isEvent) {
			g_events->eventCreatureOnDrainHealth(target, attacker, damage.primary.type, damage.primary.value, damage.secondary.type, damage.secondary.value, message.primary.color, message.secondary.color);
		}

		// // imbuement
		// if (attackerPlayer) {
			
		// }

		int32_t healthChange = damage.primary.value + damage.secondary.value;
		if (healthChange == 0) {
			return true;
		}

		SpectatorHashSet spectators;
		map.getSpectators(spectators, targetPos, true, true);

		if (target->hasCondition(CONDITION_MANASHIELD) && damage.primary.type != COMBAT_UNDEFINEDDAMAGE) {
			int32_t manaDamage = std::min<int32_t>(target->getMana(), healthChange);
			if (manaDamage != 0) {
				if (damage.origin != ORIGIN_NONE) {
					const auto& events = target->getCreatureEvents(CREATURE_EVENT_MANACHANGE);
					if (!events.empty()) {
						for (CreatureEvent* creatureEvent : events) {
							creatureEvent->executeManaChange(target, attacker, damage);
						}

						healthChange = damage.primary.value + damage.secondary.value;
						if (healthChange == 0) {
							return true;
						}
						manaDamage = std::min<int32_t>(target->getMana(), healthChange);
					}
				}

				target->drainMana(attacker, manaDamage);

				addMagicEffect(spectators, targetPos, CONST_ME_LOSEENERGY);

				std::stringstream ss;

				std::string damageString = std::to_string(manaDamage);

				std::string spectatorMessage;

				message.primary.value = manaDamage;
				message.primary.color = TEXTCOLOR_BLUE;

				for (Creature* spectator : spectators) {
					Player* tmpPlayer = spectator->getPlayer();
					if (!tmpPlayer || tmpPlayer->getPosition().z != targetPos.z) {
						continue;
					}

					if (tmpPlayer == attackerPlayer && attackerPlayer != targetPlayer) {
						ss.str({});
						ss << ucfirst(target->getNameDescription()) << " loses " << damageString + " mana due to your attack.";
						message.type = MESSAGE_DAMAGE_DEALT;
						message.text = ss.str();
					} else if (tmpPlayer == targetPlayer) {
						ss.str({});
						ss << "You lose " << damageString << " mana";
						if (!attacker) {
							ss << '.';
						} else if (targetPlayer == attackerPlayer) {
							ss << " due to your own attack.";
						} else {
							ss << " due to an attack by " << attacker->getNameDescription() << '.';
							if (tmpPlayer->hasActivePreyBonus(BONUS_DAMAGE_REDUCTION, attacker)) {
								ss << " (active prey bonus)";
							}
						}
						message.type = MESSAGE_DAMAGE_RECEIVED;
						message.text = ss.str();
					} else {
						if (spectatorMessage.empty()) {
							ss.str({});
							ss << ucfirst(target->getNameDescription()) << " loses " << damageString + " mana";
							if (attacker) {
								ss << " due to ";
								if (attacker == target) {
									ss << (targetPlayer ? (targetPlayer->getSex() == PLAYERSEX_FEMALE ? "her own attack" : "his own attack") : "its own attack");
								} else {
									ss << "an attack by " << attacker->getNameDescription();
								}
							}
							ss << '.';
							spectatorMessage = ss.str();
						}
						message.type = MESSAGE_DAMAGE_OTHERS;
						message.text = spectatorMessage;
					}
					tmpPlayer->sendTextMessage(message);
				}

				damage.primary.value -= manaDamage;
				if (damage.primary.value < 0) {
					damage.secondary.value = std::max<int32_t>(0, damage.secondary.value + damage.primary.value);
					damage.primary.value = 0;
				}
			}
		}

		int32_t realDamage = damage.primary.value + damage.secondary.value;
		if (realDamage == 0) {
			return true;
		}

		if (damage.origin != ORIGIN_NONE && damage.origin != ORIGIN_CHARM) {
			const auto& events = target->getCreatureEvents(CREATURE_EVENT_HEALTHCHANGE);
			if (!events.empty()) {
				for (CreatureEvent* creatureEvent : events) {
					creatureEvent->executeHealthChange(target, attacker, damage);
				}
				damage.origin = ORIGIN_NONE;
				return combatChangeHealth(attacker, target, damage);
			}
		}

		int32_t targetHealth = target->getHealth();
		if (damage.primary.value >= targetHealth) {
			damage.primary.value = targetHealth;
			damage.secondary.value = 0;
		} else if (damage.secondary.value) {
			damage.secondary.value = std::min<int32_t>(damage.secondary.value, targetHealth - damage.primary.value);
		}

		realDamage = damage.primary.value + damage.secondary.value;
		if (realDamage == 0) {
			return true;
		} else if (realDamage >= targetHealth) {
			for (CreatureEvent* creatureEvent : target->getCreatureEvents(CREATURE_EVENT_PREPAREDEATH)) {
				if (!creatureEvent->executeOnPrepareDeath(target, attacker)) {
					return false;
				}
			}
		}

		Monster* targetMonster = target->getMonster();
		target->drainHealth(attacker, realDamage);
		if (realDamage > 0 && targetMonster) {
			if (targetMonster->israndomStepping()) {
				targetMonster->setIgnoreFieldDamage(true);
				targetMonster->updateMapCache();
			}
		}

		if (damage.critical) {
			if(attackerPlayer && attackerPlayer->doCritical(realDamage)) {
				std::ostringstream critmessage;
				critmessage << "NEW CRITICAL HIT!!";
				attackerPlayer->sendTextMessage(MESSAGE_EVENT_ADVANCE, critmessage.str());
			}
		}

		if (spectators.empty()) {
			map.getSpectators(spectators, targetPos, true, true);
		}

		addCreatureHealth(spectators, target);

		message.primary.value = damage.primary.value;
		message.secondary.value = damage.secondary.value;

		uint8_t hitEffect;
		if (message.primary.value) {
			combatGetTypeInfo(damage.primary.type, target, message.primary.color, hitEffect);
			if (hitEffect != CONST_ME_NONE) {
				addMagicEffect(spectators, targetPos, hitEffect);
			}
		}

		if (message.secondary.value) {
			combatGetTypeInfo(damage.secondary.type, target, message.secondary.color, hitEffect);
			if (hitEffect != CONST_ME_NONE) {
				addMagicEffect(spectators, targetPos, hitEffect);
			}
		}

		if (message.primary.color != TEXTCOLOR_NONE || message.secondary.color != TEXTCOLOR_NONE) {
			std::stringstream ss;

			ss << realDamage << (realDamage != 1 ? " hitpoints" : " hitpoint");
			std::string damageString = ss.str();

			std::string spectatorMessage;

			for (Creature* spectator : spectators) {
				Player* tmpPlayer = spectator->getPlayer();
				if (!tmpPlayer || tmpPlayer->getPosition().z != targetPos.z) {
					continue;
				}

				if (tmpPlayer == attackerPlayer && attackerPlayer != targetPlayer) {
					ss.str({});
					ss << ucfirst(target->getNameDescription()) << " loses " << damageString << " due to your attack.";
					bool hasParent = false;
					if (tmpPlayer->hasActivePreyBonus(BONUS_DAMAGE_BOOST, target)) {
						hasParent = true;
						ss << " (active prey bonus";
					}
					if (damage.origin == ORIGIN_CHARM && targetMonster) {
						int8_t charmid = tmpPlayer->getMonsterCharm(targetMonster->getRaceId());
						if (charmid > -1) {
							Charm* charm = g_charms.getCharm(charmid);
							if (charm) {
								if (!hasParent) {
									hasParent = true;
									ss << " (";
								} else {
									ss << " and ";
								}

								ss << "active charm '" << charm->getName() << '\'';
							}
						}
					}
					if (hasParent) {
						ss << ")";
					}
					message.type = MESSAGE_DAMAGE_DEALT;
					message.text = ss.str();
				} else if (tmpPlayer == targetPlayer) {
					ss.str({});
					ss << "You lose " << damageString;
					if (!attacker) {
						ss << '.';
					} else if (targetPlayer == attackerPlayer) {
						ss << " due to your own attack.";
					} else {
						ss << " due to an attack by " << attacker->getNameDescription() << '.';
						bool hasParent = false;
						if (targetPlayer && targetPlayer->hasActivePreyBonus(BONUS_DAMAGE_REDUCTION, attacker)) {
							ss << " (active prey bonus";
							hasParent = true;
						}
						Monster* attackerMonster = attacker ? attacker->getMonster() : nullptr;
						if (damage.origin == ORIGIN_CHARM && attackerMonster) {
							int8_t charmid = tmpPlayer->getMonsterCharm(attackerMonster->getRaceId());
							if (charmid > -1) {
								Charm* charm = g_charms.getCharm(charmid);
								if (charm) {
									if (!hasParent) {
										hasParent = true;
										ss << " (";
									} else {
										ss << " and ";
									}

									ss << "active charm '" << charm->getName() << '\'';
								}
							}
						}
						if (hasParent) {
							ss << ")";
						}
					}
					message.type = MESSAGE_DAMAGE_RECEIVED;
					message.text = ss.str();
				} else {
					message.type = MESSAGE_DAMAGE_OTHERS;

					if (spectatorMessage.empty()) {
						ss.str({});
						ss << ucfirst(target->getNameDescription()) << " loses " << damageString;
						if (attacker) {
							ss << " due to ";
							if (attacker == target) {
								if (targetPlayer) {
									ss << (targetPlayer->getSex() == PLAYERSEX_FEMALE ? "her own attack" : "his own attack");
								} else {
									ss << "its own attack";
								}
							} else {
								ss << "an attack by " << attacker->getNameDescription();
							}
						}
						ss << '.';
						spectatorMessage = ss.str();
					}

					message.text = spectatorMessage;
				}
				tmpPlayer->sendTextMessage(message);
			}
		}
	}

	// // criando o corpo da criatura
	// if (target && target->getHealth() <= 0) {
	// 	target->onDeath();
	// }

	return true;
}

bool Game::combatChangeMana(Creature* attacker, Creature* target, CombatDamage& damage)
{
	const Position& targetPos = target->getPosition();
	int32_t manaChange = damage.primary.value + damage.secondary.value;
	if (manaChange > 0) {
		Player* attackerPlayer;
		if (attacker) {
			attackerPlayer = attacker->getPlayer();
		} else {
			attackerPlayer = nullptr;
		}

		Player* targetPlayer = target->getPlayer();
		if (attackerPlayer && targetPlayer && attackerPlayer->getSkull() == SKULL_BLACK && attackerPlayer->getSkullClient(targetPlayer) == SKULL_NONE) {
			return false;
		}

		if (damage.origin != ORIGIN_NONE) {
			const auto& events = target->getCreatureEvents(CREATURE_EVENT_MANACHANGE);
			if (!events.empty()) {
				for (CreatureEvent* creatureEvent : events) {
					creatureEvent->executeManaChange(target, attacker, damage);
				}
				damage.origin = ORIGIN_NONE;
				return combatChangeMana(attacker, target, damage);
			}
		}

		int32_t realManaChange = target->getMana();
		target->changeMana(manaChange);
		realManaChange = target->getMana() - realManaChange;

		if (realManaChange > 0 && !target->isInGhostMode()) {
			std::string damageString = std::to_string(realManaChange) + " mana.";

			std::string spectatorMessage;
			if (!attacker) {
				spectatorMessage += ucfirst(target->getNameDescription());
				spectatorMessage += " was restored for " + damageString;
			} else {
				spectatorMessage += ucfirst(attacker->getNameDescription());
				spectatorMessage += " restored ";
				if (attacker == target) {
					spectatorMessage += (targetPlayer ? (targetPlayer->getSex() == PLAYERSEX_FEMALE ? "herself" : "himself") : "itself");
				} else {
					spectatorMessage += target->getNameDescription();
				}
				spectatorMessage += " for " + damageString;
			}

			TextMessage message;
			message.position = targetPos;
			message.primary.value = realManaChange;
			message.primary.color = TEXTCOLOR_MAYABLUE;

			SpectatorHashSet spectators;
			map.getSpectators(spectators, targetPos, false, true);
			for (Creature* spectator : spectators) {
				Player* tmpPlayer = spectator->getPlayer();
				if (tmpPlayer == attackerPlayer && attackerPlayer != targetPlayer) {
					message.type = MESSAGE_HEALED;
					message.text = "You restored " + target->getNameDescription() + " for " + damageString;
				} else if (tmpPlayer == targetPlayer) {
					message.type = MESSAGE_HEALED;
					if (!attacker) {
						message.text = "You were restored for " + damageString;
					} else if (targetPlayer == attackerPlayer) {
						message.text = "You restore yourself for " + damageString;
					} else {
						message.text = "You were restored by " + attacker->getNameDescription() + " for " + damageString;
					}
				} else {
					message.type = MESSAGE_HEALED_OTHERS;
					message.text = spectatorMessage;
				}
				tmpPlayer->sendTextMessage(message);
			}
		}
	} else {
		if (!target->isAttackable()) {
			if (!target->isInGhostMode()) {
				addMagicEffect(targetPos, CONST_ME_POFF);
			}
			return false;
		}

		Player* attackerPlayer;
		if (attacker) {
			attackerPlayer = attacker->getPlayer();
		} else {
			attackerPlayer = nullptr;
		}

		Player* targetPlayer = target->getPlayer();
		if (attackerPlayer && targetPlayer && attackerPlayer->getSkull() == SKULL_BLACK && attackerPlayer->getSkullClient(targetPlayer) == SKULL_NONE) {
			return false;
		}

		int32_t manaLoss = std::min<int32_t>(target->getMana(), -manaChange);
		BlockType_t blockType = target->blockHit(attacker, COMBAT_MANADRAIN, manaLoss);
		if (blockType != BLOCK_NONE) {
			addMagicEffect(targetPos, CONST_ME_POFF);
			return false;
		}

		if (manaLoss <= 0) {
			return true;
		}

		if (damage.origin != ORIGIN_NONE) {
			const auto& events = target->getCreatureEvents(CREATURE_EVENT_MANACHANGE);
			if (!events.empty()) {
				for (CreatureEvent* creatureEvent : events) {
					creatureEvent->executeManaChange(target, attacker, damage);
				}
				damage.origin = ORIGIN_NONE;
				return combatChangeMana(attacker, target, damage);
			}
		}

		target->drainMana(attacker, manaLoss);

		std::stringstream ss;

		std::string damageString = std::to_string(manaLoss);

		std::string spectatorMessage;

		TextMessage message;
		message.position = targetPos;
		message.primary.value = manaLoss;
		message.primary.color = TEXTCOLOR_BLUE;

		SpectatorHashSet spectators;
		map.getSpectators(spectators, targetPos, false, true);
		for (Creature* spectator : spectators) {
			Player* tmpPlayer = spectator->getPlayer();
			if (tmpPlayer == attackerPlayer && attackerPlayer != targetPlayer) {
				ss.str({});
				ss << ucfirst(target->getNameDescription()) << " loses " << damageString << " mana due to your attack.";
				message.type = MESSAGE_DAMAGE_DEALT;
				message.text = ss.str();
			} else if (tmpPlayer == targetPlayer) {
				ss.str({});
				ss << "You lose " << damageString << " mana";
				if (!attacker) {
					ss << '.';
				} else if (targetPlayer == attackerPlayer) {
					ss << " due to your own attack.";
				} else {
					ss << " mana due to an attack by " << attacker->getNameDescription() << '.';
					if (tmpPlayer->hasActivePreyBonus(BONUS_DAMAGE_REDUCTION, attacker)) {
						ss << " (active prey bonus)";
					}
				}
				message.type = MESSAGE_DAMAGE_RECEIVED;
				message.text = ss.str();
			} else {
				if (spectatorMessage.empty()) {
					ss.str({});
					ss << ucfirst(target->getNameDescription()) << " loses " << damageString << " mana";
					if (attacker) {
						ss << " due to ";
						if (attacker == target) {
							ss << (targetPlayer ? (targetPlayer->getSex() == PLAYERSEX_FEMALE ? "her own attack" : "his own attack") : "its own attack");
						} else {
							ss << "an attack by " << attacker->getNameDescription();
						}
					}
					ss << '.';
					spectatorMessage = ss.str();
				}
				message.type = MESSAGE_DAMAGE_OTHERS;
				message.text = spectatorMessage;
			}
			tmpPlayer->sendTextMessage(message);
		}
	}

	return true;
}

void Game::addCreatureHealth(const Creature* target)
{
	SpectatorHashSet spectators;
	map.getSpectators(spectators, target->getPosition(), true, true);
	addCreatureHealth(spectators, target);
}

void Game::addCreatureHealth(const SpectatorHashSet& spectators, const Creature* target)
{
	for (Creature* spectator : spectators) {
		if (Player* tmpPlayer = spectator->getPlayer()) {
			tmpPlayer->sendCreatureHealth(target);
		}
	}
}

void Game::addMagicEffect(const Position& pos, uint8_t effect)
{
	SpectatorHashSet spectators;
	map.getSpectators(spectators, pos, true, true);
	addMagicEffect(spectators, pos, effect);
}

void Game::addMagicEffect(const SpectatorHashSet& spectators, const Position& pos, uint8_t effect)
{
	for (Creature* spectator : spectators) {
		if (Player* tmpPlayer = spectator->getPlayer()) {
			tmpPlayer->sendMagicEffect(pos, effect);
		}
	}
}

void Game::addDistanceEffect(const Position& fromPos, const Position& toPos, uint8_t effect)
{
	SpectatorHashSet spectators;
	map.getSpectators(spectators, fromPos, false, true);
	map.getSpectators(spectators, toPos, false, true);

	addDistanceEffect(spectators, fromPos, toPos, effect);
}

void Game::addDistanceEffect(const SpectatorHashSet& spectators, const Position& fromPos, const Position& toPos, uint8_t effect)
{
	for (Creature* spectator : spectators) {
		if (Player* tmpPlayer = spectator->getPlayer()) {
			tmpPlayer->sendDistanceShoot(fromPos, toPos, effect);
		}
	}
}

void Game::startDecay(Item* item)
{
	if (!item) {
		return;
	}

	ItemDecayState_t decayState = item->getDecaying();
	if (decayState == DECAYING_STOPPING || (!item->canDecay() && decayState == DECAYING_TRUE)) {
		stopDecay(item);
		return;
	}

	if (!item->canDecay() || decayState == DECAYING_TRUE) {
		return;
	}

	int32_t duration = item->getIntAttr(ITEM_ATTRIBUTE_DURATION);
	if (duration > 0) {
		g_decay.startDecay(item, duration);
	} else {
		internalDecayItem(item);
	}
}

void Game::stopDecay(Item* item)
{
	if (item->hasAttribute(ITEM_ATTRIBUTE_DECAYSTATE)) {
		if (item->hasAttribute(ITEM_ATTRIBUTE_DURATION_TIMESTAMP)) {
			g_decay.stopDecay(item, item->getIntAttr(ITEM_ATTRIBUTE_DURATION_TIMESTAMP));
			item->removeAttribute(ITEM_ATTRIBUTE_DURATION_TIMESTAMP);
		} else {
			item->removeAttribute(ITEM_ATTRIBUTE_DECAYSTATE);
		}
	}
}

void Game::internalDecayItem(Item* item)
{
	const ItemType& it = Item::items[item->getID()];
	if (it.decayTo != 0) {
		Player* player = item->getHoldingPlayer();
		if (player) {
			bool needUpdateSkills = false;
			for (int32_t i = SKILL_FIRST; i <= SKILL_LAST; ++i) {
				if (it.abilities && it.abilities->skills[i] != 0) {
					needUpdateSkills = true;
					player->setVarSkill(static_cast<skills_t>(i), -it.abilities->skills[i]);
				}
			}

			if (needUpdateSkills) {
				player->sendSkills();
			}

			bool needUpdateStats = false;
			for (int32_t s = STAT_FIRST; s <= STAT_LAST; ++s) {
				if (it.abilities && it.abilities->stats[s] != 0) {
					needUpdateStats = true;
					needUpdateSkills = true;
					player->setVarStats(static_cast<stats_t>(s), -it.abilities->stats[s]);
				}
				if (it.abilities && it.abilities->statsPercent[s] != 0) {
					needUpdateStats = true;
					player->setVarStats(static_cast<stats_t>(s), -static_cast<int32_t>(player->getDefaultStats(static_cast<stats_t>(s)) * ((it.abilities->statsPercent[s] - 100) / 100.f)));
				}
			}

			if (needUpdateStats) {
				player->sendStats();
			}

			if (needUpdateSkills) {
				player->sendSkills();
			}
		}
		transformItem(item, it.decayTo);
	} else {
		ReturnValue ret = internalRemoveItem(item);
		if (ret != RETURNVALUE_NOERROR) {
			std::cout << "[Debug - Game::internalDecayItem] internalDecayItem failed, error code: " << static_cast<uint32_t>(ret) << ", item id: " << item->getID() << std::endl;
		}
	}
}

void Game::checkImbuements()
{
	g_scheduler.addEvent(createSchedulerTask(EVENT_IMBUEMENTINTERVAL, std::bind(&Game::checkImbuements, this)));

	size_t bucket = (lastImbuedBucket + 1) % EVENT_IMBUEMENT_BUCKETS;

	auto it = imbuedItems[bucket].begin(), end = imbuedItems[bucket].end();
	while (it != end) {
		Item* item = *it;
		if (item->isRemoved() || !item->getParent()->getCreature()) {
			ReleaseItem(item);
			it = imbuedItems[bucket].erase(it);
			continue;
		}

		Player* player = item->getHoldingPlayer();
		if (!player) {
			ReleaseItem(item);
			it = imbuedItems[bucket].erase(it);
			continue;
		}

		bool hasImbue = false;
		uint8_t slots = Item::items[item->getID()].imbuingSlots;
		for (uint8_t slot = 0; slot < slots; slot++) {
			uint32_t info = item->getImbuement(slot);
			int32_t id = info & 0xFF;
			if (id == 0) {
				continue;
			}

			int32_t duration = info >> 8;
			int32_t newDuration = std::max(0, (duration - (EVENT_IMBUEMENTINTERVAL * EVENT_IMBUEMENT_BUCKETS) / 690));
			if (newDuration > 0) {
				hasImbue = true;
			}

			Imbuement* imbuement = g_imbuements.getImbuement(id);
			if(!imbuement) {
				continue;
			}

			Category* category = g_imbuements.getCategoryByID(imbuement->getCategory());
			if (category->agressive && !player->hasCondition(CONDITION_INFIGHT)) {
				continue;
			}

			if (duration > 0 && newDuration == 0) {
				item->setImbuement(slot, 0);
				player->onDeEquipImbueItem(imbuement);
			} else {
				item->setImbuement(slot, ((newDuration << 8) | id));
			}
		}

		if (hasImbue) {
			it++;
		} else {
			ReleaseItem(item);
			it = imbuedItems[bucket].erase(it);			
		}

	}

	lastImbuedBucket = bucket;
	cleanup();
}

void Game::checkLight()
{
	g_scheduler.addEvent(createSchedulerTask(EVENT_LIGHTINTERVAL, std::bind(&Game::checkLight, this)));

	lightHour += lightHourDelta;

	if (lightHour > 1440) {
		lightHour -= 1440;
	}

	if (std::abs(lightHour - SUNRISE) < 2 * lightHourDelta) {
		lightState = LIGHT_STATE_SUNRISE;
	} else if (std::abs(lightHour - SUNSET) < 2 * lightHourDelta) {
		lightState = LIGHT_STATE_SUNSET;
	}

	int32_t newLightLevel = lightLevel;
	bool lightChange = false;

	switch (lightState) {
		case LIGHT_STATE_SUNRISE: {
			newLightLevel += (LIGHT_LEVEL_DAY - LIGHT_LEVEL_NIGHT) / 30;
			lightChange = true;
			break;
		}
		case LIGHT_STATE_SUNSET: {
			newLightLevel -= (LIGHT_LEVEL_DAY - LIGHT_LEVEL_NIGHT) / 30;
			lightChange = true;
			break;
		}
		default:
			break;
	}

	if (newLightLevel <= LIGHT_LEVEL_NIGHT) {
		lightLevel = LIGHT_LEVEL_NIGHT;
		lightState = LIGHT_STATE_NIGHT;
	} else if (newLightLevel >= LIGHT_LEVEL_DAY) {
		lightLevel = LIGHT_LEVEL_DAY;
		lightState = LIGHT_STATE_DAY;
	} else {
		lightLevel = newLightLevel;
	}

	if (lightChange) {
		LightInfo lightInfo = getWorldLightInfo();

		for (const auto& it : players) {
			it.second->sendWorldLight(lightInfo);
			it.second->sendTibiaTime(lightHour);
		}
	} else {
		for (const auto& it : players) {
			it.second->sendTibiaTime(lightHour);
		}
	}
}

LightInfo Game::getWorldLightInfo() const
{
	return {lightLevel, 0xD7};
}

bool Game::gameIsDay()
{
	if (lightHour >= ((6 * 60) + 30) && lightHour <= ((17 * 60) + 30))
		isDay = true;

	return isDay;
}

void Game::shutdown()
{
	std::cout << "Shutting down..." << std::flush;

	saveGameState();
	g_scheduler.shutdown();
	g_databaseTasks.shutdown();
	g_dispatcher.shutdown();
	map.spawns.clear();
	raids.clear();

	cleanup();

	if (serviceManager) {
		serviceManager->stop();
	}

	ConnectionManager::getInstance().closeAll();

	std::cout << " done!" << std::endl;
}

void Game::cleanup()
{
	//free memory
	for (auto creature : ToReleaseCreatures) {
		creature->decrementReferenceCounter();
	}
	ToReleaseCreatures.clear();

	for (auto item : ToReleaseItems) {
		item->decrementReferenceCounter();
	}
	ToReleaseItems.clear();

	for (Item* item : toImbuedItems) {
		imbuedItems[lastImbuedBucket].push_back(item);
	}
	toImbuedItems.clear();
}

void Game::ReleaseCreature(Creature* creature)
{
	ToReleaseCreatures.push_back(creature);
}

void Game::ReleaseItem(Item* item)
{
	ToReleaseItems.push_back(item);
}

void Game::broadcastMessage(const std::string& text, MessageClasses type) const
{
	std::cout << "> Broadcasted message: \"" << text << "\"." << std::endl;
	for (const auto& it : players) {
		it.second->sendTextMessage(type, text);
	}
}

void Game::updateCreatureWalkthrough(const Creature* creature)
{
	//send to clients
	SpectatorHashSet spectators;
	map.getSpectators(spectators, creature->getPosition(), true, true);
	for (Creature* spectator : spectators) {
		Player* tmpPlayer = spectator->getPlayer();
		tmpPlayer->sendCreatureWalkthrough(creature, tmpPlayer->canWalkthroughEx(creature));
	}
}

void Game::updateCreatureSkull(const Creature* creature)
{
	if (!isWorldTypeSkull()) {
		return;
	}

	SpectatorHashSet spectators;
	map.getSpectators(spectators, creature->getPosition(), true, true);
	for (Creature* spectator : spectators) {
		spectator->getPlayer()->sendCreatureSkull(creature);
	}
}

void Game::updatePlayerShield(Player* player)
{
	SpectatorHashSet spectators;
	map.getSpectators(spectators, player->getPosition(), true, true);
	for (Creature* spectator : spectators) {
		spectator->getPlayer()->sendCreatureShield(player);
	}
}

void Game::updatePlayerHelpers(const Player& player)
{
	uint32_t creatureId = player.getID();
	uint16_t helpers = player.getHelpers();

	SpectatorHashSet spectators;
	map.getSpectators(spectators, player.getPosition(), true, true);
	for (Creature* spectator : spectators) {
		spectator->getPlayer()->sendCreatureHelpers(creatureId, helpers);
	}
}

void Game::updateCreatureType(Creature* creature)
{
	const Player* masterPlayer = nullptr;

	CreatureType_t creatureType = creature->getType();
	if (creatureType == CREATURETYPE_MONSTER) {
		const Creature* master = creature->getMaster();
		if (master) {
			masterPlayer = master->getPlayer();
			if (masterPlayer) {
				creatureType = CREATURETYPE_SUMMONPLAYER;
			}
		}
		if(creature->isHealthHidden()) {
			creatureType = CREATURETYPE_NPC;
		}
	}

	//send to clients
	SpectatorHashSet spectators;
	map.getSpectators(spectators, creature->getPosition(), true, true);

	for (Creature* spectator : spectators) {
		spectator->getPlayer()->sendCreatureType(creature, creatureType);
	}
}

void Game::loadMotdNum()
{
	Database& db = Database::getInstance();

	DBResult_ptr result = db.storeQuery("SELECT `value` FROM `server_config` WHERE `config` = 'motd_num'");
	if (result) {
		motdNum = result->getNumber<uint32_t>("value");
	} else {
		db.executeQuery("INSERT INTO `server_config` (`config`, `value`) VALUES ('motd_num', '0')");
	}

	result = db.storeQuery("SELECT `value` FROM `server_config` WHERE `config` = 'motd_hash'");
	if (result) {
		motdHash = result->getString("value");
		if (motdHash != transformToSHA1(g_config.getString(ConfigManager::MOTD))) {
			++motdNum;
		}
	} else {
		db.executeQuery("INSERT INTO `server_config` (`config`, `value`) VALUES ('motd_hash', '')");
	}
}

void Game::saveMotdNum() const
{
	Database& db = Database::getInstance();
	std::ostringstream query;
	query << "UPDATE `server_config` SET `value` = '" << motdNum << "' WHERE `config` = 'motd_num'";
	db.executeQuery(query.str());

	query.str(std::string());
	query << "UPDATE `server_config` SET `value` = '" << transformToSHA1(g_config.getString(ConfigManager::MOTD)) << "' WHERE `config` = 'motd_hash'";
	db.executeQuery(query.str());
}

void Game::checkPlayersRecord()
{
	const size_t playersOnline = getPlayersOnline();
	if (playersOnline > playersRecord) {
		uint32_t previousRecord = playersRecord;
		playersRecord = playersOnline;

		for (auto& it : g_globalEvents->getEventMap(GLOBALEVENT_RECORD)) {
			it.second.executeRecord(playersRecord, previousRecord);
		}
		updatePlayersRecord();
	}
}

void Game::updatePlayersRecord() const
{
	Database& db = Database::getInstance();

	std::ostringstream query;
	query << "UPDATE `server_config` SET `value` = '" << playersRecord << "' WHERE `config` = 'players_record'";
	db.executeQuery(query.str());
}

void Game::loadPlayersRecord()
{
	Database& db = Database::getInstance();

	DBResult_ptr result = db.storeQuery("SELECT `value` FROM `server_config` WHERE `config` = 'players_record'");
	if (result) {
		playersRecord = result->getNumber<uint32_t>("value");
	} else {
		db.executeQuery("INSERT INTO `server_config` (`config`, `value`) VALUES ('players_record', '0')");
	}
}

uint64_t Game::getExperienceStage(uint32_t level)
{
	if (!stagesEnabled) {
		return g_config.getNumber(ConfigManager::RATE_EXPERIENCE);
	}

	if (useLastStageLevel && level >= lastStageLevel) {
		return stages[lastStageLevel];
	}

	return stages[level];
}

bool Game::loadExperienceStages()
{
	pugi::xml_document doc;
	pugi::xml_parse_result result = doc.load_file("data/XML/stages.xml");
	if (!result) {
		printXMLError("Error - Game::loadExperienceStages", "data/XML/stages.xml", result);
		return false;
	}

	for (auto stageNode : doc.child("stages").children()) {
		if (strcasecmp(stageNode.name(), "config") == 0) {
			stagesEnabled = stageNode.attribute("enabled").as_bool();
		} else {
			uint32_t minLevel, maxLevel, multiplier;

			pugi::xml_attribute minLevelAttribute = stageNode.attribute("minlevel");
			if (minLevelAttribute) {
				minLevel = pugi::cast<uint32_t>(minLevelAttribute.value());
			} else {
				minLevel = 1;
			}

			pugi::xml_attribute maxLevelAttribute = stageNode.attribute("maxlevel");
			if (maxLevelAttribute) {
				maxLevel = pugi::cast<uint32_t>(maxLevelAttribute.value());
			} else {
				maxLevel = 0;
				lastStageLevel = minLevel;
				useLastStageLevel = true;
			}

			pugi::xml_attribute multiplierAttribute = stageNode.attribute("multiplier");
			if (multiplierAttribute) {
				multiplier = pugi::cast<uint32_t>(multiplierAttribute.value());
			} else {
				multiplier = 1;
			}

			if (useLastStageLevel) {
				stages[lastStageLevel] = multiplier;
			} else {
				for (uint32_t i = minLevel; i <= maxLevel; ++i) {
					stages[i] = multiplier;
				}
			}
		}
	}
	return true;
}

bool Game::loadSkillStages()
{
	pugi::xml_document doc;
	pugi::xml_parse_result result = doc.load_file("data/XML/skillstages.xml");
	if (!result) {
		printXMLError("Error - Game::loadSkillStages", "data/XML/skillstages.xml", result);
		return false;
	}

	for (auto stageNode : doc.child("skillstages").children()) {
		if (strcasecmp(stageNode.name(), "skills") == 0) {
			stagesSkillEnabled = stageNode.attribute("enabled").as_bool();
			for (auto stage1 : stageNode.children()) {	
				uint32_t minLevel, maxLevel, multiplier;

				pugi::xml_attribute minLevelAttribute = stage1.attribute("minskill");
				if (minLevelAttribute) {
					minLevel = pugi::cast<uint32_t>(minLevelAttribute.value());
				}
				else {
					minLevel = 1;
				}

				pugi::xml_attribute maxLevelAttribute = stage1.attribute("maxskill");
				if (maxLevelAttribute) {
					maxLevel = pugi::cast<uint32_t>(maxLevelAttribute.value());
				}
				else {
					maxLevel = 0;
					lastStageSkill = minLevel;
					useLastStageSkill = true;
				}

				pugi::xml_attribute multiplierAttribute = stage1.attribute("multiplier");
				if (multiplierAttribute) {
					multiplier = pugi::cast<uint32_t>(multiplierAttribute.value());
				}
				else {
					multiplier = 1;
				}

				if (useLastStageSkill) {
					stagesSkill[lastStageSkill] = multiplier;
				}
				else {
					for (uint32_t i = minLevel; i <= maxLevel; ++i) {
						stagesSkill[i] = multiplier;
					}
				}
			}
		}
	}
	return true;
}

uint64_t Game::getSkillStage(uint32_t level)
{
	if (!stagesSkillEnabled) {
		return g_config.getNumber(ConfigManager::RATE_SKILL);
	}

	if (useLastStageSkill && level >= lastStageSkill) {
		return stagesSkill[lastStageSkill];
	}

	return stagesSkill[level];
}


bool Game::loadMagicLevelStages()
{
	pugi::xml_document doc;
	pugi::xml_parse_result result = doc.load_file("data/XML/skillstages.xml");
	if (!result) {
		printXMLError("Error - Game::loadMagicLevelStages", "data/XML/skillstages.xml", result);
		return false;
	}

	for (auto stageNode : doc.child("skillstages").children()) {
		if (strcasecmp(stageNode.name(), "magiclevel") == 0) {
			stagesMlEnabled = stageNode.attribute("enabled").as_bool();
			for (auto stage1 : stageNode.children()) {
				uint32_t minLevel, maxLevel, multiplier;

				pugi::xml_attribute minLevelAttribute = stage1.attribute("minmagic");
				if (minLevelAttribute) {
					minLevel = pugi::cast<uint32_t>(minLevelAttribute.value());
				}
				else {
					minLevel = 1;
				}

				pugi::xml_attribute maxLevelAttribute = stage1.attribute("maxmagic");
				if (maxLevelAttribute) {
					maxLevel = pugi::cast<uint32_t>(maxLevelAttribute.value());
				}
				else {
					maxLevel = 0;
					lastStageMl = minLevel;
					useLastStageMl = true;
				}

				pugi::xml_attribute multiplierAttribute = stage1.attribute("multiplier");
				if (multiplierAttribute) {
					multiplier = pugi::cast<uint32_t>(multiplierAttribute.value());
				}
				else {
					multiplier = 1;
				}

				if (useLastStageMl) {
					stagesMl[lastStageMl] = multiplier;
				}
				else {
					for (uint32_t i = minLevel; i <= maxLevel; ++i) {
						stagesMl[i] = multiplier;
					}
				}
			}
		}
	}
	return true;
}

uint64_t Game::getMagicLevelStage(uint32_t level)
{
	if (!stagesMlEnabled) {
		return g_config.getNumber(ConfigManager::RATE_MAGIC);
	}

	if (useLastStageMl && level >= lastStageMl) {
		return stagesMl[lastStageMl];
	}

	return stagesMl[level];
}

void Game::playerInviteToParty(uint32_t playerId, uint32_t invitedId)
{
	//Prevent crafted packets from inviting urself to a party (using OTClient)
	if (playerId == invitedId) {
		return;
	}

	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	Player* invitedPlayer = getPlayerByID(invitedId);
	if (!invitedPlayer || invitedPlayer->isInviting(player)) {
		return;
	}

	std::ostringstream ss;
	if (invitedPlayer->getParty()) {
		ss << invitedPlayer->getName() << " is already in a party.";
		player->sendTextMessage(MESSAGE_INFO_DESCR, ss.str());
		return;
	}

	Party* party = player->getParty();
	if (!party) {
		party = new Party(player);
	} else if (party->getLeader() != player) {
		return;
	}

	party->invitePlayer(*invitedPlayer);
}

void Game::playerJoinParty(uint32_t playerId, uint32_t leaderId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	Player* leader = getPlayerByID(leaderId);
	if (!leader || !leader->isInviting(player)) {
		return;
	}

	Party* party = leader->getParty();
	if (!party || party->getLeader() != leader) {
		return;
	}

	if (player->getParty()) {
		player->sendTextMessage(MESSAGE_INFO_DESCR, "You are already in a party.");
		return;
	}

	party->joinParty(*player);
}

void Game::playerRevokePartyInvitation(uint32_t playerId, uint32_t invitedId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	Party* party = player->getParty();
	if (!party || party->getLeader() != player) {
		return;
	}

	Player* invitedPlayer = getPlayerByID(invitedId);
	if (!invitedPlayer || !player->isInviting(invitedPlayer)) {
		return;
	}

	party->revokeInvitation(*invitedPlayer);
}

void Game::playerPassPartyLeadership(uint32_t playerId, uint32_t newLeaderId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	Party* party = player->getParty();
	if (!party || party->getLeader() != player) {
		return;
	}

	Player* newLeader = getPlayerByID(newLeaderId);
	if (!newLeader || !player->isPartner(newLeader)) {
		return;
	}

	party->passPartyLeadership(newLeader);
}

void Game::playerLeaveParty(uint32_t playerId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	Party* party = player->getParty();
	if (!party || player->hasCondition(CONDITION_INFIGHT)) {
		return;
	}

	party->leaveParty(player);
}

void Game::playerEnableSharedPartyExperience(uint32_t playerId, bool sharedExpActive)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	Party* party = player->getParty();
	Tile* playerTile = player->getTile();
	if (!party || (player->hasCondition(CONDITION_INFIGHT) && playerTile && !playerTile->hasFlag(TILESTATE_PROTECTIONZONE))) {
		return;
	}

	party->setSharedExperience(player, sharedExpActive);
}

void Game::sendGuildMotd(uint32_t playerId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	Guild* guild = player->getGuild();
	if (guild) {
		player->sendChannelMessage("Message of the Day", guild->getMotd(), TALKTYPE_CHANNEL_R1, CHANNEL_GUILD);
	}
}

void Game::kickPlayer(uint32_t playerId, bool displayEffect)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	player->kickPlayer(displayEffect);
}

void Game::playerReportRuleViolationReport(uint32_t playerId, const std::string& targetName, uint8_t reportType, uint8_t reportReason, const std::string& comment, const std::string& translation)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	g_events->eventPlayerOnReportRuleViolation(player, targetName, reportType, reportReason, comment, translation);
}

void Game::playerSendThankYou(uint32_t playerId, uint32_t a_statementId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	ServerMessage* message = getMessageByStatement(a_statementId);
	if (!message || message == nullptr ) {
		return;
	}

	uint32_t speakId = message->guid;
	std::string name = message->name;
	Player* target = getPlayerByGUID(speakId);
	if (target) {
		name = target->getName();
		target->sendTextMessage(MESSAGE_EVENT_ADVANCE, "You received a 'thank you' from " +  player->getName() + '.');
	}

	std::string fileName = "data/logs/thankyou/" + name + ".txt";
	FILE* file = fopen(fileName.c_str(), "a");
	if (file) {
		fprintf(file, "----- %s - Sent by %s (%s) GUID[%d] -----\n", formatDate(OS_TIME(nullptr)).c_str(), player->getName().c_str(), convertIPToString(player->getIP()).c_str(), player->getGUID());
		fprintf(file, "GUID:%d - Chat:%d '%s'\n", message->guid, message->channelId, message->message.c_str());
		fclose(file);
	}
}

void Game::playerReportBug(uint32_t playerId, const std::string& message, const Position& position, uint8_t category)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	g_events->eventPlayerOnReportBug(player, message, position, category);
}

void Game::playerCharmData(uint32_t playerId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	player->sendCharmData();
}

void Game::playerBestiaryGroups(uint32_t playerId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	player->sendBestiaryGroups();
}

void Game::playerBestiaryMonsterData(uint32_t playerId, uint16_t monsterId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	MonsterType* monsterType = g_monsters.getMonsterTypeByRace(monsterId);
	if (!monsterType) {
		std::cout << "[Game::playerBestiaryMonsterData] Monster by id " << monsterId << " not found" << std::endl;
		return;
	}

	player->sendBestiaryMonsterData(monsterId);
}

void Game::playerDebugAssert(uint32_t playerId, const std::string& assertLine, const std::string& date, const std::string& description, const std::string& comment)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	// TODO: move debug assertions to database
	FILE* file = fopen("client_assertions.txt", "a");
	if (file) {
		fprintf(file, "----- %s - %s (%s) -----\n", formatDate(OS_TIME(nullptr)).c_str(), player->getName().c_str(), convertIPToString(player->getIP()).c_str());
		fprintf(file, "%s\n%s\n%s\n%s\n", assertLine.c_str(), date.c_str(), description.c_str(), comment.c_str());
		fclose(file);
	}
}

void Game::playerTransferCoins(uint32_t playerId, const std::string& recipient, uint16_t amount) {
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	if (player->getCoinBalance() < amount) {
		return;
	}

	if (amount % g_config.getNumber(ConfigManager::STORE_COINS_PACKET_SIZE) != 0) {
		return;
	}

	Player *tmpPlayer = getPlayerByName(recipient);
	if (!tmpPlayer) {
		tmpPlayer = new Player(nullptr);
		if (!IOLoginData::loadPlayerByName(tmpPlayer, recipient)) {
			delete tmpPlayer;
			return;
		}
	}

	if (tmpPlayer->getAccount() == player->getAccount()) {
		return;
	}

	std::string description(player->getName() + " transferred to " + recipient);

	IOAccount::addCoins(player->getAccount(), -static_cast<int32_t>(amount));
	player->coinBalance -= amount;
	IOAccount::registerTransaction(player->getAccount(), OS_TIME(nullptr), static_cast<uint8_t>(HISTORY_TYPE_NONE), amount, 0, description, -static_cast<int32_t>(amount));

	IOAccount::addCoins(tmpPlayer->getAccount(), amount);
	IOAccount::registerTransaction(tmpPlayer->getAccount(), OS_TIME(nullptr), static_cast<uint8_t>(HISTORY_TYPE_NONE), amount, 0, description, amount);
	tmpPlayer->coinBalance += amount;

	if (tmpPlayer->isOffline()) {
		IOLoginData::savePlayer(tmpPlayer);
		delete tmpPlayer;
	} else {
		tmpPlayer->sendCoinBalance();
	}

	player->sendCoinBalance();
	return;
}

void Game::playerLeaveMarket(uint32_t playerId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	player->setInMarket(false);
}

void Game::playerBrowseMarket(uint32_t playerId, uint16_t spriteId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	if (!player->isInMarket()) {
		return;
	}

	const ItemType& it = Item::items.getItemIdByClientId(spriteId);
	if (it.id == 0) {
		return;
	}

	if (it.wareId == 0) {
		return;
	}

	const MarketOfferList& buyOffers = IOMarket::getActiveOffers(MARKETACTION_BUY, it.id);
	const MarketOfferList& sellOffers = IOMarket::getActiveOffers(MARKETACTION_SELL, it.id);
	player->sendMarketBrowseItem(it.id, buyOffers, sellOffers);
	player->sendMarketDetail(it.id);
}

void Game::playerBrowseMarketOwnOffers(uint32_t playerId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	if (!player->isInMarket()) {
		return;
	}

	const MarketOfferList& buyOffers = IOMarket::getOwnOffers(MARKETACTION_BUY, player->getGUID());
	const MarketOfferList& sellOffers = IOMarket::getOwnOffers(MARKETACTION_SELL, player->getGUID());
	player->sendMarketBrowseOwnOffers(buyOffers, sellOffers);
}

void Game::playerBrowseMarketOwnHistory(uint32_t playerId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	if (!player->isInMarket()) {
		return;
	}

	const HistoryMarketOfferList& buyOffers = IOMarket::getOwnHistory(MARKETACTION_BUY, player->getGUID());
	const HistoryMarketOfferList& sellOffers = IOMarket::getOwnHistory(MARKETACTION_SELL, player->getGUID());
	player->sendMarketBrowseOwnHistory(buyOffers, sellOffers);
}

void Game::playerCreateMarketOffer(uint32_t playerId, uint8_t type, uint16_t spriteId, uint16_t amount, uint32_t price, bool anonymous)
{
	if (amount == 0 || amount > 64000) {
		return;
	}

	if (price == 0 || price > 999999999) {
		return;
	}

	if (type != MARKETACTION_BUY && type != MARKETACTION_SELL) {
		return;
	}

	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	if (!player->isInMarket()) {
		return;
	}

	//Custom: Anti bug do market
	if (player->isMarketExhausted()) {
		player->sendCancelMessage(RETURNVALUE_YOUAREEXHAUSTED);
		addMagicEffect(player->getPosition(), CONST_ME_POFF);
		return;
	}

	if (g_config.getBoolean(ConfigManager::MARKET_PREMIUM) && !player->isPremium()) {
		player->sendMarketLeave();
		return;
	}

	const ItemType& itt = Item::items.getItemIdByClientId(spriteId);
	if (itt.id == 0 || itt.wareId == 0) {
		return;
	}

	const ItemType& it = Item::items.getItemIdByClientId(itt.wareId);
	if (it.id == 0 || it.wareId == 0) {
		return;
	}

	if (!it.stackable && amount > 2000) {
		return;
	}

	const uint32_t maxOfferCount = g_config.getNumber(ConfigManager::MAX_MARKET_OFFERS_AT_A_TIME_PER_PLAYER);
	if (maxOfferCount != 0 && IOMarket::getPlayerOfferCount(player->getGUID()) >= maxOfferCount) {
		return;
	}

	uint64_t fee = (price / 100.) * amount;
	if (fee < 20) {
		fee = 20;
	} else if (fee > 1000) {
		fee = 1000;
	}

	uint64_t playerTotalMoney = (player->bankBalance + player->getMoney());
	if (type == MARKETACTION_SELL) {
		if (fee > playerTotalMoney) {
			return;
		}

		DepotLocker* depotLocker = player->getDepotLocker(player->getLastDepotId());
		if (!depotLocker) {
			return;
		}

		if (it.id == ITEM_STORECOINS) {
			if (amount > player->getCoinBalance()) {
				return;
			}

			IOAccount::addCoins(player->getAccount(), -static_cast<int32_t>(amount));
		} else {
			std::forward_list<Item*> itemList = getMarketItemList(it.wareId, amount, depotLocker);
			if (itemList.empty()) {
				return;
			}

			if (it.stackable) {
				uint16_t tmpAmount = amount;
				for (Item* item : itemList) {
					uint16_t removeCount = std::min<uint16_t>(tmpAmount, item->getItemCount());
					tmpAmount -= removeCount;
					internalRemoveItem(item, removeCount);

					if (tmpAmount == 0) {
						break;
					}
				}
			} else {
				for (Item* item : itemList) {
					internalRemoveItem(item);
				}
			}
		}

		removeMoney(player, fee, 0, true);
	} else {
		uint64_t totalPrice = static_cast<uint64_t>(price) * amount;
		totalPrice += fee;
		if (totalPrice > playerTotalMoney) {
			return;
		}

		removeMoney(player, totalPrice, 0, true);
	}

	IOMarket::createOffer(player->getGUID(), static_cast<MarketAction_t>(type), it.id, amount, price, anonymous);

	auto ColorItem = itemsPriceMap.find(it.id);
	if (ColorItem == itemsPriceMap.end()) {
		itemsPriceMap[it.id] = price;
		itemsSaleCount++;
	} else if (ColorItem->second < price) {
		itemsPriceMap[it.id] = price;
	}

	player->sendMarketEnter(player->getLastDepotId());
	const MarketOfferList& buyOffers = IOMarket::getActiveOffers(MARKETACTION_BUY, it.id);
	const MarketOfferList& sellOffers = IOMarket::getActiveOffers(MARKETACTION_SELL, it.id);
	player->sendMarketBrowseItem(it.id, buyOffers, sellOffers);
	//Custom: Anti bug do market
	player->updateMarketExhausted();
}

void Game::playerCancelMarketOffer(uint32_t playerId, uint32_t timestamp, uint16_t counter)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	if (!player->isInMarket()) {
		return;
	}

	//Custom: Anti bug do market
	if (player->isMarketExhausted()) {
		player->sendCancelMessage(RETURNVALUE_YOUAREEXHAUSTED);
		addMagicEffect(player->getPosition(), CONST_ME_POFF);
		return;
	}

	MarketOfferEx offer = IOMarket::getOfferByCounter(timestamp, counter);
	if (offer.id == 0 || offer.playerId != player->getGUID()) {
		return;
	}

	if (offer.type == MARKETACTION_BUY) {
		player->bankBalance += static_cast<uint64_t>(offer.price) * offer.amount;
		player->sendMarketEnter(player->getLastDepotId());
	} else {
		const ItemType& it = Item::items[offer.itemId];
		if (it.id == 0) {
			return;
		}

		if (it.id == ITEM_STORECOINS) {
			IOAccount::addCoins(player->getAccount(), offer.amount);
		} else if (it.stackable) {
			uint16_t tmpAmount = offer.amount;
			while (tmpAmount > 0) {
				int32_t stackCount = std::min<int32_t>(100, tmpAmount);
				Item* item = Item::CreateItem(it.id, stackCount);
				if (internalAddItem(player->getInbox(), item, INDEX_WHEREEVER, FLAG_NOLIMIT) != RETURNVALUE_NOERROR) {
					delete item;
					break;
				}

				tmpAmount -= stackCount;
			}
		} else {
			int32_t subType;
			if (it.charges != 0) {
				subType = it.charges;
			} else {
				subType = -1;
			}

			for (uint16_t i = 0; i < offer.amount; ++i) {
				Item* item = Item::CreateItem(it.id, subType);
				if (internalAddItem(player->getInbox(), item, INDEX_WHEREEVER, FLAG_NOLIMIT) != RETURNVALUE_NOERROR) {
					delete item;
					break;
				}
			}
		}
	}

	IOMarket::moveOfferToHistory(offer.id, OFFERSTATE_CANCELLED);
	offer.amount = 0;
	offer.timestamp += 2592000;
	player->sendMarketCancelOffer(offer);
	player->sendMarketEnter(player->getLastDepotId());
	//Custom: Anti bug do market
	player->updateMarketExhausted();

}

void Game::playerAcceptMarketOffer(uint32_t playerId, uint32_t timestamp, uint16_t counter, uint16_t amount)
{
	if (amount == 0 || amount > 64000) {
		return;
	}

	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	if (!player->isInMarket()) {
		return;
	}

	//Custom: Anti bug do market
	if (player->isMarketExhausted()) {
		player->sendCancelMessage(RETURNVALUE_YOUAREEXHAUSTED);
		addMagicEffect(player->getPosition(), CONST_ME_POFF);
		return;
	}

	MarketOfferEx offer = IOMarket::getOfferByCounter(timestamp, counter);
	if (offer.id == 0) {
		return;
	}

	if (amount > offer.amount) {
		return;
	}

	const ItemType& it = Item::items[offer.itemId];
	if (it.id == 0) {
		return;
	}

	uint64_t totalPrice = static_cast<uint64_t>(offer.price) * amount;

	if (offer.type == MARKETACTION_BUY) {
		DepotLocker* depotLocker = player->getDepotLocker(player->getLastDepotId());
		if (!depotLocker) {
			return;
		}

		Player* buyerPlayer = getPlayerByGUID(offer.playerId);
		if (!buyerPlayer) {
			buyerPlayer = new Player(nullptr);
			if (!IOLoginData::loadPlayerById(buyerPlayer, offer.playerId)) {
				delete buyerPlayer;
				return;
			}
		}

		if (it.id == ITEM_STORECOINS) {
			if (amount > IOAccount::getCoinBalance(player->getAccount())) {
				return;
			}

			IOAccount::addCoins(player->getAccount(), -static_cast<int32_t>(amount));
			IOAccount::registerTransaction(player->getAccount(), OS_TIME(nullptr), 0, amount, 0, "Sold on Market", -static_cast<int32_t>(amount));

		} else {
			std::forward_list<Item*> itemList = getMarketItemList(it.wareId, amount, depotLocker);
			if (itemList.empty()) {
				return;
			}

			if (it.stackable) {
				uint16_t tmpAmount = amount;
				for (Item* item : itemList) {
					uint16_t removeCount = std::min<uint16_t>(tmpAmount, item->getItemCount());
					tmpAmount -= removeCount;
					internalRemoveItem(item, removeCount);

					if (tmpAmount == 0) {
						break;
					}
				}
			} else {
				for (Item* item : itemList) {
					internalRemoveItem(item);
				}
			}
		}

		player->bankBalance += totalPrice;

		if (it.id == ITEM_STORECOINS) {
			IOAccount::addCoins(buyerPlayer->getAccount(), amount);
			IOAccount::registerTransaction(buyerPlayer->getAccount(), OS_TIME(nullptr), 0, amount, 0, "Purchased on Market", amount);
		} else if (it.stackable) {
			uint16_t tmpAmount = amount;
			while (tmpAmount > 0) {
				uint16_t stackCount = std::min<uint16_t>(100, tmpAmount);
				Item* item = Item::CreateItem(it.id, stackCount);
				if (internalAddItem(buyerPlayer->getInbox(), item, INDEX_WHEREEVER, FLAG_NOLIMIT) != RETURNVALUE_NOERROR) {
					delete item;
					break;
				}

				tmpAmount -= stackCount;
			}
		} else {
			int32_t subType;
			if (it.charges != 0) {
				subType = it.charges;
			} else {
				subType = -1;
			}

			for (uint16_t i = 0; i < amount; ++i) {
				Item* item = Item::CreateItem(it.id, subType);
				if (internalAddItem(buyerPlayer->getInbox(), item, INDEX_WHEREEVER, FLAG_NOLIMIT) != RETURNVALUE_NOERROR) {
					delete item;
					break;
				}
			}
		}

		if (buyerPlayer->isOffline()) {
			IOLoginData::savePlayer(buyerPlayer);
			delete buyerPlayer;
		} else {
			buyerPlayer->onReceiveMail();
		}
	} else {
		if (totalPrice > player->bankBalance) {
			return;
		}

		player->bankBalance -= totalPrice;

		if (it.id == ITEM_STORECOINS) {
			IOAccount::addCoins(player->getAccount(), amount);
			IOAccount::registerTransaction(player->getAccount(), OS_TIME(nullptr), 0, 1, 0, "Purchased on Market", amount);
		} else if (it.stackable) {
			uint16_t tmpAmount = amount;
			while (tmpAmount > 0) {
				uint16_t stackCount = std::min<uint16_t>(100, tmpAmount);
				Item* item = Item::CreateItem(it.id, stackCount);
				if (internalAddItem(player->getInbox(), item, INDEX_WHEREEVER, FLAG_NOLIMIT) != RETURNVALUE_NOERROR) {
					delete item;
					break;
				}

				tmpAmount -= stackCount;
			}
		} else {
			int32_t subType;
			if (it.charges != 0) {
				subType = it.charges;
			} else {
				subType = -1;
			}

			for (uint16_t i = 0; i < amount; ++i) {
				Item* item = Item::CreateItem(it.id, subType);
				if (internalAddItem(player->getInbox(), item, INDEX_WHEREEVER, FLAG_NOLIMIT) != RETURNVALUE_NOERROR) {
					delete item;
					break;
				}
			}
		}

		Player* sellerPlayer = getPlayerByGUID(offer.playerId);
		if (sellerPlayer) {
			sellerPlayer->bankBalance += totalPrice;

			if (it.id == ITEM_STORECOINS) {
				IOAccount::registerTransaction(sellerPlayer->getAccount(), OS_TIME(nullptr), 0, 1, 0, "Sold on Market", -static_cast<int32_t>(amount));

			}
		} else {
			IOLoginData::increaseBankBalance(offer.playerId, totalPrice);

			if (it.id == ITEM_STORECOINS) {
				sellerPlayer = new Player(nullptr);

				if (IOLoginData::loadPlayerById(sellerPlayer, offer.playerId)) {
					IOAccount::registerTransaction(sellerPlayer->getAccount(), OS_TIME(nullptr), 0, 1, 0, "Sold on Market", -static_cast<int32_t>(amount));
				}

				delete sellerPlayer;
			}
		}

		if (it.id != ITEM_STORECOINS) {
			player->onReceiveMail();
		}
	}

	const int32_t marketOfferDuration = 2592000;

	IOMarket::appendHistory(player->getGUID(), (offer.type == MARKETACTION_BUY ? MARKETACTION_SELL : MARKETACTION_BUY), offer.itemId, amount, offer.price, offer.timestamp + marketOfferDuration, OFFERSTATE_ACCEPTEDEX);

	IOMarket::appendHistory(offer.playerId, offer.type, offer.itemId, amount, offer.price, offer.timestamp + marketOfferDuration, OFFERSTATE_ACCEPTED);

	offer.amount -= amount;

	if (offer.amount == 0) {
		IOMarket::deleteOffer(offer.id);
	} else {
		IOMarket::acceptOffer(offer.id, amount);
	}

	player->sendMarketEnter(player->getLastDepotId());
	offer.timestamp += marketOfferDuration;
	player->sendMarketAcceptOffer(offer);
	//Custom: Anti bug do market
	player->updateMarketExhausted();

}

void Game::parsePlayerBestiaryTracker(uint32_t playerId, uint16_t raceId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	player->manageMonsterTracker(raceId);

}

void Game::playerSendSaleItemList(uint32_t playerId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	player->sendSaleItemList();
}

void Game::parsePlayerExtendedOpcode(uint32_t playerId, uint8_t opcode, const std::string& buffer)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	for (CreatureEvent* creatureEvent : player->getCreatureEvents(CREATURE_EVENT_EXTENDED_OPCODE)) {
		creatureEvent->executeExtendedOpcode(player, opcode, buffer);
	}
}

void Game::playerRequestResourceData(uint32_t playerId, ResourceType_t resourceType) {
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	for (uint8_t preySlotId = 0; preySlotId < PREY_SLOTCOUNT; preySlotId++) {
		player->sendFreeListRerollAvailability(preySlotId);
	}

	switch (resourceType) {
		case RESOURCETYPE_BANK_GOLD: player->sendResourceData(RESOURCETYPE_BANK_GOLD, player->getBankBalance()); break;
		case RESOURCETYPE_INVENTORY_GOLD: player->sendResourceData(RESOURCETYPE_INVENTORY_GOLD, player->getMoney()); break;
		case RESOURCETYPE_PREY_BONUS_REROLLS: player->sendResourceData(RESOURCETYPE_PREY_BONUS_REROLLS, player->getBonusRerollCount()); break;
		case RESOURCETYPE_REWARD: player->sendResourceData(RESOURCETYPE_REWARD, player->getInstantRewardTokens()); break;
		default: {
			player->sendResourceData(RESOURCETYPE_BANK_GOLD, player->getBankBalance());
			player->sendResourceData(RESOURCETYPE_INVENTORY_GOLD, player->getMoney());
			player->sendResourceData(RESOURCETYPE_PREY_BONUS_REROLLS, player->getBonusRerollCount());
			player->sendResourceData(RESOURCETYPE_REWARD, player->getInstantRewardTokens());
			break;
		}
}
}

void Game::playerPreyAction(uint32_t playerId, uint8_t preySlotId, PreyAction_t preyAction, uint8_t monsterIndex, uint16_t raceId)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	if (player->isPreyExausted()) {
		player->sendMessageDialog(MESSAGEDIALOG_PREY_ERROR, "You are exhausted.");
		return;
	}

	MonsterType* monsterType = nullptr;
	ReturnValue returnValue = RETURNVALUE_NOERROR;
	switch (preyAction) {
		case PREY_ACTION_LISTREROLL:
			returnValue = player->rerollPreyData(preySlotId);
			break;
		case PREY_ACTION_BONUSREROLL:
			returnValue = player->rerollPreyBonus(preySlotId);
			break;
		case PREY_ACTION_MONSTERSELECTION:
			returnValue = player->changePreyDataState(preySlotId, STATE_ACTIVE, monsterIndex);
			break;
		case NEW_BONUS_WILDCARD:
			returnValue = player->rerollPreyDataWildcard(preySlotId);
			break;
		case NEW_BONUS_SELECTIONWILDCARD:
			monsterType = g_monsters.getMonsterTypeByRace(raceId);
			if (monsterType) {
				returnValue = player->changePreyDataState(preySlotId, STATE_ACTIVE, monsterIndex, monsterType->name);
			} else {
				returnValue = RETURNVALUE_PREYINTERNALERROR;
			}
			break;
		default:
			break;
	}

	player->setPreyExausted(OS_TIME(nullptr) + 1);
	if (returnValue != RETURNVALUE_NOERROR) {
		player->sendMessageDialog(MESSAGEDIALOG_PREY_ERROR, getReturnMessage(returnValue));
	}
}

void Game::playerUnlockCharm(uint32_t playerId, uint8_t charmid, uint8_t action, uint16_t raceid)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	if (player->isUnlockedCharm(charmid) && action == 0) {
		return;
	}

	Charm* charm = g_charms.getCharm(charmid);
	if(!charm) {
		return;
	}

	if (action == 0) {
		uint16_t price = charm->getPrice();
		uint16_t playercharm = player->getCharmPoints();
	
		if (playercharm < price) {
			return;
		}
	
		player->setCharmPoints(playercharm - price);
		player->addCharm(charmid);
	} else if (action == 1) {
		if (player->getMonsterCharm(raceid) != -1) {
			return;
		}

		player->addCharm(charmid, raceid);
	} else if (action == 2) {
		if (player->getMoney() + player->getBankBalance() < (player->getCharmPrice())) {
			return;
		}

		removeMoney(player, (player->getCharmPrice()), 0, true);
		player->removeCharm(charmid);
	}

	if (player->getLastBestiaryMonster() > 0) {
		player->sendBestiaryMonsterData(player->getLastBestiaryMonster());
		player->setLastBestiaryMonster(0);
	}

	player->sendCharmData();
}

std::forward_list<Item*> Game::getMarketItemList(uint16_t wareId, uint16_t sufficientCount, DepotLocker* depotLocker)
{
	std::forward_list<Item*> itemList;
	uint16_t count = 0;

	std::list<Container*> containers {depotLocker};
	do {
		Container* container = containers.front();
		containers.pop_front();

		for (Item* item : container->getItemList()) {
			Container* c = item->getContainer();
			if (c && !c->empty()) {
				containers.push_back(c);
				continue;
			}

			const ItemType& itemType = Item::items[item->getID()];
			if (itemType.wareId != wareId) {
				continue;
			}

			if (c && (!itemType.isContainer() || c->capacity() != itemType.maxItems)) {
				continue;
			}

			if (!item->hasMarketAttributes()) {
				continue;
			}

			itemList.push_front(item);

			count += Item::countByType(item, -1);
			if (count >= sufficientCount) {
				return itemList;
			}
		}
	} while (!containers.empty());
	return std::forward_list<Item*>();
}

void Game::forceAddCondition(uint32_t creatureId, Condition* condition)
{
	Creature* creature = getCreatureByID(creatureId);
	if (!creature) {
		delete condition;
		return;
	}

	creature->addCondition(condition, true);
}

void Game::forceRemoveCondition(uint32_t creatureId, ConditionType_t type)
{
	Creature* creature = getCreatureByID(creatureId);
	if (!creature) {
		return;
	}

	creature->removeCondition(type, true);
}

void Game::sendOfflineTrainingDialog(Player* player)
{
	if (!player) {
		return;
	}

	if (!player->hasModalWindowOpen(offlineTrainingWindow.id)) {
		player->sendModalWindow(offlineTrainingWindow);
	}
}

void Game::playerAnswerModalWindow(uint32_t playerId, uint32_t modalWindowId, uint8_t button, uint8_t choice)
{
	Player* player = getPlayerByID(playerId);
	if (!player) {
		return;
	}

	if (!player->hasModalWindowOpen(modalWindowId)) {
		return;
	}

	player->onModalWindowHandled(modalWindowId);

	// offline training, hardcoded
	if (modalWindowId == std::numeric_limits<uint32_t>::max()) {
		if (button == 1) {
			if (choice == SKILL_SWORD || choice == SKILL_AXE || choice == SKILL_CLUB || choice == SKILL_DISTANCE || choice == SKILL_MAGLEVEL) {
				BedItem* bedItem = player->getBedItem();
				if (bedItem && bedItem->sleep(player)) {
					player->setOfflineTrainingSkill(choice);
					return;
				}
			}
		} else {
			player->sendTextMessage(MESSAGE_EVENT_ADVANCE, "Offline training aborted.");
		}

		player->setBedItem(nullptr);
	} else {
		for (auto creatureEvent : player->getCreatureEvents(CREATURE_EVENT_MODALWINDOW)) {
			creatureEvent->executeModalWindow(player, modalWindowId, button, choice);
		}
	}
}

void Game::addPlayer(Player* player)
{
	const std::string& lowercase_name = asLowerCaseString(player->getName());
	mappedPlayerNames[lowercase_name] = player;
	mappedPlayerGuids[player->getGUID()] = player;
	wildcardTree.insert(lowercase_name);
	players[player->getID()] = player;
	playersCombat[player->getCombatID()] = player;
}

void Game::removePlayer(Player* player)
{
	const std::string& lowercase_name = asLowerCaseString(player->getName());
	mappedPlayerNames.erase(lowercase_name);
	mappedPlayerGuids.erase(player->getGUID());
	wildcardTree.remove(lowercase_name);
	players.erase(player->getID());
	playersCombat.erase(player->getCombatID());
}

void Game::addNpc(Npc* npc)
{
	npcs[npc->getID()] = npc;
}

void Game::removeNpc(Npc* npc)
{
	npcs.erase(npc->getID());
}

void Game::addMonster(Monster* monster)
{
	monsters[monster->getID()] = monster;
}

void Game::removeMonster(Monster* monster)
{
	monsters.erase(monster->getID());
}

Guild* Game::getGuild(uint32_t id) const
{
	auto it = guilds.find(id);
	if (it == guilds.end()) {
		return nullptr;
	}
	return it->second;
}

Guild* Game::getGuildByName(std::string name) const
{
	for (auto it : guilds) {
		if (asLowerCaseString(it.second->getName()) == asLowerCaseString(name)) {
			return it.second;
		}
	}
	return nullptr;
}

void Game::addGuild(Guild* guild)
{
	guilds[guild->getId()] = guild;
}

void Game::removeGuild(uint32_t guildId)
{
	guilds.erase(guildId);
}

void Game::decreaseBrowseFieldRef(const Position& pos)
{
	Tile* tile = map.getTile(pos.x, pos.y, pos.z);
	if (!tile) {
		return;
	}

	auto it = browseFields.find(tile);
	if (it != browseFields.end()) {
		it->second->decrementReferenceCounter();
	}
}

void Game::internalRemoveItems(std::vector<Item*> itemList, uint32_t amount, bool stackable)
{
	if (stackable) {
		for (Item* item : itemList) {
			if (item->getItemCount() > amount) {
				internalRemoveItem(item, amount);
				break;
			} else {
				amount -= item->getItemCount();
				internalRemoveItem(item);
			}
		}
	} else {
		for (Item* item : itemList) {
			internalRemoveItem(item);
		}
	}
}

BedItem* Game::getBedBySleeper(uint32_t guid) const
{
	auto it = bedSleepersMap.find(guid);
	if (it == bedSleepersMap.end()) {
		return nullptr;
	}
	return it->second;
}

void Game::setBedSleeper(BedItem* bed, uint32_t guid)
{
	bedSleepersMap[guid] = bed;
}

void Game::removeBedSleeper(uint32_t guid)
{
	auto it = bedSleepersMap.find(guid);
	if (it != bedSleepersMap.end()) {
		bedSleepersMap.erase(it);
	}
}

Item* Game::getUniqueItem(uint16_t uniqueId)
{
	auto it = uniqueItems.find(uniqueId);
	if (it == uniqueItems.end()) {
		return nullptr;
	}
	return it->second;
}

bool Game::addUniqueItem(uint16_t uniqueId, Item* item)
{
	Item* tempItem = nullptr;
	auto it = uniqueItems.find(uniqueId);
	if (it != uniqueItems.end()) {
		tempItem = it->second;
	}

	auto result = uniqueItems.emplace(uniqueId, item);
	if (!result.second) {
		const Position& pos = item->getPosition();
		const Position& pos2 = tempItem ? tempItem->getPosition() : item->getPosition();
		std::cout << "Duplicate unique id: " << static_cast<uint16_t>(uniqueId) <<
						". Position: (" << pos.getX() <<
									 ", " << pos.getY() <<
									 ", " << pos.getZ() << ") " <<
		 std::endl << "Old Item Position: (" << pos2.getX() <<
									 ", " << pos2.getY() <<
									 ", " << pos2.getZ() << ")" << std::endl;
	}
	return result.second;
}

void Game::removeUniqueItem(uint16_t uniqueId)
{
	auto it = uniqueItems.find(uniqueId);
	if (it != uniqueItems.end()) {
		uniqueItems.erase(it);
	}
}

bool Game::itemidHasMoveevent(uint32_t itemid)
{
	return g_moveEvents->isRegistered(itemid);
}

bool Game::reload(ReloadTypes_t reloadType)
{
	switch (reloadType) {
		case RELOAD_TYPE_ACTIONS: return g_actions->reload();
		case RELOAD_TYPE_BESTIARY: return g_bestiaries.reload();
		case RELOAD_TYPE_CHAT: return g_chat->load();
		case RELOAD_TYPE_CONFIG: return g_config.reload();
		case RELOAD_TYPE_CREATURESCRIPTS: return g_creatureEvents->reload();
		case RELOAD_TYPE_EVENTS: return g_events->load();
		case RELOAD_TYPE_GLOBALEVENTS: return g_globalEvents->reload();
		case RELOAD_TYPE_ITEMS: return Item::items.reload();
		case RELOAD_TYPE_MONSTERS: return g_monsters.reload();
		case RELOAD_TYPE_MODULES: return g_modules->reload();
		case RELOAD_TYPE_MOUNTS: return mounts.reload();
		case RELOAD_TYPE_MOVEMENTS: return g_moveEvents->reload();
		case RELOAD_TYPE_IMBUEMENTS: return g_imbuements.reload();
		case RELOAD_TYPE_STORE: return g_store.reload();
		case RELOAD_TYPE_FREE_PASS: return loadFreePass();
		case RELOAD_TYPE_NPCS: {
			Npcs::reload();
			return true;
		}

		case RELOAD_TYPE_QUESTS: return quests.reload();
		case RELOAD_TYPE_RAIDS: return raids.reload() && raids.startup();

		case RELOAD_TYPE_SPELLS: {
			if (!g_spells->reload()) {
				std::cout << "[Error - Game::reload] Failed to reload spells." << std::endl;
				std::terminate();
			} else if (!g_monsters.reload()) {
				std::cout << "[Error - Game::reload] Failed to reload monsters." << std::endl;
				std::terminate();
			}
			return true;
		}

		case RELOAD_TYPE_TALKACTIONS: return g_talkActions->reload();

		case RELOAD_TYPE_WEAPONS: {
			bool results = g_weapons->reload();
			g_weapons->loadDefaults();
			return results;
		}

		case RELOAD_TYPE_SCRIPTS: {
			// commented out stuff is TODO, once we approach further in revscriptsys
			g_actions->clear(true);
			g_creatureEvents->clear(true);
			g_moveEvents->clear(true);
			g_talkActions->clear(true);
			g_globalEvents->clear(true);
			g_weapons->clear(true);
			g_weapons->loadDefaults();
			g_spells->clear(true);
			g_scripts->loadScripts("scripts", false, true);
			return true;
		}

		default: {

			g_actions->reload();
			g_config.reload();
			g_bestiaries.reload();
			g_creatureEvents->reload();
			g_monsters.reload();
			g_moveEvents->reload();
			g_store.reload();
			Npcs::reload();
			raids.reload() && raids.startup();
			g_talkActions->reload();
			Item::items.reload();
			g_weapons->reload();
			g_weapons->clear(true);
			g_weapons->loadDefaults();
			quests.reload();
			mounts.reload();
			g_globalEvents->reload();
			g_events->load();
			g_chat->load();
			g_actions->clear(true);
			g_creatureEvents->clear(true);
			g_moveEvents->clear(true);
			g_talkActions->clear(true);
			g_globalEvents->clear(true);
			g_spells->clear(true);
			g_scripts->loadScripts("scripts", false, true);
			return true;
		}
	}
}

bool Game::hasEffect(uint8_t effectId) {
	for (uint8_t i = CONST_ME_NONE; i <= CONST_ME_LAST; i++) {
		MagicEffectClasses effect = static_cast<MagicEffectClasses>(i);
		if (effect == effectId) {
			return true;
		}
	}
	return false;
}

bool Game::hasDistanceEffect(uint8_t effectId) {
	for (uint8_t i = CONST_ANI_NONE; i <= CONST_ANI_LAST; i++) {
		ShootType_t effect = static_cast<ShootType_t>(i);
		if (effect == effectId) {
			return true;
		}
	}
	return false;
}

bool Game::isExpertPvpEnabled()
{
    return g_config.getBoolean(ConfigManager::EXPERT_PVP);
}

void Game::updateSpectatorsPvp(Thing* thing)
{
	if (!thing || thing->isRemoved()) {
		return;
	}

	if (Creature* creature = thing->getCreature()) {
		Player* player = creature->getPlayer();
		if (!player) {
			return;
		}

		SpectatorHashSet spectators;
		map.getSpectators(spectators, player->getPosition(), true, true);
		for (auto it : spectators) {
			Player* itPlayer = it->getPlayer();
			if (!itPlayer || itPlayer->isRemoved()) {
				continue;
			}

			SquareColor_t sqColor = SQ_COLOR_NONE;
			if (player->hasPvpActivity(itPlayer)) {
				sqColor = SQ_COLOR_YELLOW;
			} else if (itPlayer->isInPvpSituation()) {
				if (itPlayer == player) {
					sqColor = SQ_COLOR_YELLOW;
				} else if (player->hasPvpActivity(itPlayer, true)) {
					// if this player attacked anyone of players's guild/party
					sqColor = SQ_COLOR_ORANGE;
				} else {
					// meaning that the fight you are not involved.
					sqColor = SQ_COLOR_BROWN;
				}
			} else {
				// player isn't enganged at any pvp situation! ( even if self)
				player->sendCreatureSquare(itPlayer, SQ_COLOR_NONE, 0);
			}

			if (sqColor != SQ_COLOR_NONE) {
				player->sendPvpSquare(itPlayer, sqColor);
			}
		}
	}
}

bool Game::hasLootType(uint8_t lootTypeId) {
	for (uint8_t i = LOOT_ARMOR; i <= LOOT_LAST; i++) {
		LootType_t loottype = static_cast<LootType_t>(i);
		if (loottype == lootTypeId) {
			return true;
		}
	}
	return false;
}

bool Game::loadBoostMonster()
{
	Database& db = Database::getInstance();
	DBResult_ptr resultQuery1 = db.storeQuery("SELECT `value` FROM `server_config` WHERE `config` = 'boost_monster'");
	if (!resultQuery1) {
		db.executeQuery("INSERT INTO `server_config` (`config`, `value`) VALUES ('boost_monster', '1')");
		boostRace = 1;
	} else {
		boostRace = resultQuery1->getNumber<uint16_t>("value");
	}

	DBResult_ptr resultQuery2 = db.storeQuery("SELECT `value` FROM `server_config` WHERE `config` = 'boost_monster_name'");
	if (!resultQuery2) {
		db.executeQuery("INSERT INTO `server_config` (`config`, `value`) VALUES ('boost_monster_name', 'none')");
		boostMonster = "none";
	} else {
		boostMonster = resultQuery2->getString("value");
	}

	DBResult_ptr resultQuery3 = db.storeQuery("SELECT `value` FROM `server_config` WHERE `config` = 'boost_monster_url'");
	if (!resultQuery3) {
		db.executeQuery("INSERT INTO `server_config` (`config`, `value`) VALUES ('boost_monster_url', 'none')");
	}

	return true;
}

void Game::setBoostMonster(std::string monstername, uint16_t monsterid)
{
	Database& db = Database::getInstance();
	std::ostringstream query;
	query << "UPDATE `server_config` SET `value` = '" << monsterid << "' WHERE `config` = 'boost_monster'";
	db.executeQuery(query.str());

	query.str(std::string());
	query << "UPDATE `server_config` SET `value` = " << db.escapeString(monstername) << " WHERE `config` = 'boost_monster_name'";
	db.executeQuery(query.str());

	// seting outfit
	MonsterType* monsterType = g_monsters.getMonsterTypeByRace(monsterid);
	std::ostringstream outfitstr;
	if (monsterType) {
		Outfit_t outfit = monsterType->info.outfit;
		if (outfit.lookType > 0) {
			outfitstr << g_config.getString(ConfigManager::MONSTER_URL);
			outfitstr << "id=" << std::to_string(outfit.lookType);
			if (outfit.lookAddons > 0)
				outfitstr << "&addons=" << std::to_string(outfit.lookAddons);
			if (outfit.lookHead > 0)
				outfitstr << "&head=" << std::to_string(outfit.lookHead);
			if (outfit.lookBody > 0)
				outfitstr << "&body=" << std::to_string(outfit.lookBody);
			if (outfit.lookLegs > 0)
				outfitstr << "&legs=" << std::to_string(outfit.lookLegs);
			if (outfit.lookFeet > 0)
				outfitstr << "&feet=" << std::to_string(outfit.lookFeet);
			if (outfit.lookMount > 0)
				outfitstr << "&mount=" << std::to_string(outfit.lookMount);

		} else {
			outfitstr << g_config.getString(ConfigManager::ITEM_URL) << std::to_string(outfit.lookTypeEx) << ".png";
		}
	} else {
		outfitstr << g_config.getString(ConfigManager::MONSTER_URL) << "id=128&addons=3&head=115&body=107&legs=19&feet=38";
	}

	query.str(std::string());
	query << "UPDATE `server_config` SET `value` = " << db.escapeString(outfitstr.str()) << " WHERE `config` = 'boost_monster_url'";
	db.executeQuery(query.str());

	boostRace = monsterid;
	boostMonster = monstername;
}

bool Game::loadGuilds()
{
	Database& db = Database::getInstance();

	std::ostringstream query;
	query << "SELECT `id` FROM `guilds`;";
	DBResult_ptr result = db.storeQuery(query.str());
	if (!result) {
		return false;
	}

	do {
		uint32_t guildId = result->getNumber<uint32_t>("id");
		Guild* guild = getGuild(guildId);
		if (!guild) {
			guild = IOGuild::loadGuild(guildId);
			addGuild(guild);
		}

	} while (result->next());

	return true;
}

bool Game::loadItemsPrice()
{
	itemsSaleCount = 0;
	std::ostringstream query, query2;
	query << "SELECT DISTINCT `itemtype` FROM `market_offers`;";

	Database& db = Database::getInstance();	
	DBResult_ptr result = db.storeQuery(query.str());
	if (!result) {
		return false;
	}

	do {
		query2.str(std::string());
		uint16_t itemId = result->getNumber<uint16_t>("itemtype");
		query2 << "SELECT `price` FROM `market_offers` WHERE `itemtype` = " << itemId << " ORDER BY `price` DESC LIMIT 1";
		DBResult_ptr resultQuery2 = db.storeQuery(query2.str());
		if (resultQuery2) {
			itemsPriceMap[itemId] = resultQuery2->getNumber<uint32_t>("price");
			itemsSaleCount++;
		}

	} while (result->next());


	return true;
}

bool Game::loadFreePass()
{
	Database& db = Database::getInstance();
	passeLivre.clear();
	std::ostringstream query;
	query << "SELECT `player_id` FROM `free_pass`;";
	DBResult_ptr result = db.storeQuery(query.str());
	if (!result) {
		return false;
	}	

	do {
		uint32_t guid = result->getNumber<uint32_t>("player_id");

		passeLivre.push_back(guid);
	} while (result->next());

	return true;
}

bool Game::loadPlayerSell()
{
	Database& db = Database::getInstance();
	std::ostringstream query;
	query << "SELECT `player_id`, `account`, `create`, `createip`, `coin` FROM `sell_players`;";
	DBResult_ptr result = db.storeQuery(query.str());
	if (!result) {
		return false;
	}	

	do {
		query.str(std::string());
		uint32_t guid = result->getNumber<uint32_t>("player_id");
		uint32_t accid = result->getNumber<uint32_t>("account");
		uint32_t coin = result->getNumber<uint32_t>("coin");
		uint32_t create = result->getNumber<uint32_t>("create");
		uint32_t createip = result->getNumber<uint32_t>("createip");

		query << "SELECT `name`, `level`, `vocation`, `skill_fist`, `skill_club`, `skill_sword`, `skill_axe`, `skill_dist`, `skill_shielding`, `skill_fishing`, `maglevel` FROM `players` WHERE `id` = " << guid << ";";

		DBResult_ptr resultQuery2 = db.storeQuery(query.str());
		if (resultQuery2) {

			std::unordered_map<uint8_t, uint16_t> skills;
			skills[SKILL_FIST] = resultQuery2->getNumber<uint16_t>("skill_fist");
			skills[SKILL_CLUB] = resultQuery2->getNumber<uint16_t>("skill_club");
			skills[SKILL_SWORD] = resultQuery2->getNumber<uint16_t>("skill_sword");
			skills[SKILL_AXE] = resultQuery2->getNumber<uint16_t>("skill_axe");
			skills[SKILL_DISTANCE] = resultQuery2->getNumber<uint16_t>("skill_dist");
			skills[SKILL_SHIELD] = resultQuery2->getNumber<uint16_t>("skill_shielding");
			skills[SKILL_FISHING] = resultQuery2->getNumber<uint16_t>("skill_fishing");
			skills[SKILL_MAGLEVEL] = resultQuery2->getNumber<uint16_t>("maglevel");

			uint16_t vocation = resultQuery2->getNumber<uint16_t>("vocation");
			uint32_t level = resultQuery2->getNumber<uint32_t>("level");
			std::string name = resultQuery2->getString("name");

			insertPlayerSell(guid, accid, create, createip, coin, name, vocation, skills, level, false);
		}

	} while (result->next());

	return true;
}

bool Game::cleanPlayerSell(uint32_t guid)
{
	playerSell.erase(guid);
	return true;
}

bool Game::insertPlayerSell(uint32_t guid, uint32_t account, uint32_t create, uint32_t createip, uint32_t coin, std::string name, uint16_t vocation, std::unordered_map<uint8_t, uint16_t> skills, uint32_t level, bool insert)
{
	Database& db = Database::getInstance();
	bool result = true;
	if (insert) {
		std::ostringstream query;
		query << "INSERT INTO `sell_players` (`player_id`, `account`, `coin`, `create`, `createip`) VALUES (" << guid << ", " << account << ", " << coin << ", " << create << ", " << createip << ")";
		result = db.executeQuery(query.str());
	}

	if (result) {
		playerSell.emplace(std::piecewise_construct,
			std::forward_as_tuple(guid),
			std::forward_as_tuple(guid, account, create, createip, coin, name, vocation, skills, level));
	}

	return result;
}

PlayerSell* Game::getPlayerSellById(uint32_t guid)
{
	auto it = playerSell.find(guid);
	if (it == playerSell.end()) {
		return nullptr;
	}

	return &it->second;
}

bool Game::isValidPassword(uint32_t accountId, std::string password)
{
	Database& db = Database::getInstance();
	std::ostringstream query;
	query << "SELECT `password` FROM `accounts` WHERE `id` = " << accountId;
	DBResult_ptr result = db.storeQuery(query.str());
	if (!result) {
		return false;
	}

	return transformToSHA1(password) == result->getString("password");
}

bool Game::addAccountHistory(uint32_t accountId, StoreHistory history)
{
	storeHistory[accountId].emplace_back(history);

	return true;
}

void Game::loadAccountStoreHistory(uint32_t account, std::vector<StoreHistory> history)
{
	storeHistory[account] = history;
}

bool Game::getAccountHistory(const uint32_t accountId, std::vector<StoreHistory>& history) const
{
	auto it = storeHistory.find(accountId);
	if (it == storeHistory.end()) {
		return false;
	}

	history = it->second;
	return true;
}

void Game::incrementMessageStatement(std::string name, std::string message, uint32_t guid, uint16_t channelId, bool isPlayer /* = false*/)
{
	statementId++;
	if (isPlayer) {
		serverMessages.emplace(std::piecewise_construct,
			std::forward_as_tuple(statementId),
			std::forward_as_tuple(guid, channelId, name, message));
	}
	return;
}

ServerMessage* Game::getMessageByStatement(uint32_t id)
{
	auto it = serverMessages.find(id);
	if (it == serverMessages.end()) {
		return nullptr;
	}

	return &it->second;
}

void Game::saveServeMessage()
{
	std::cout << "Saving logs..." << std::endl;

	std::string data = formatDateShort(OS_TIME(nullptr));
	std::string fileName = "data/logs/servermessages/" + data + ".txt";
	FILE* file = fopen(fileName.c_str(), "a");
	if (file) {
		for (const auto& it : serverMessages) {
			fprintf(file, "[%d] %s [%d %d]: %s \n", it.first, it.second.name.c_str(), it.second.guid, it.second.channelId, it.second.message.c_str());
		}		
		fclose(file);
	}	
}