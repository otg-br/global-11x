/**
 * The Forgotten Server - a free and open-source MMORPG server emulator
 * Copyright (C) 2015  Mark Samman <mark.samman@gmail.com>
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
#include <boost/range/adaptor/reversed.hpp>
#include "protocolgamebase.h"
#include "game.h"
#include "iologindata.h"
#include "tile.h"
#include "outputmessage.h"
#include "configmanager.h"
#include "spells.h"
#include "store.h"

extern Game g_game;
extern ConfigManager g_config;
extern Spells* g_spells;
extern Monsters g_monsters;
extern Prey g_prey;
extern Store g_store;

void ProtocolGameBase::AddItem(NetworkMessage& msg, uint16_t id, uint8_t count)
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
	}

	if (it.isAnimation) {
		msg.addByte(0xFE); // random phase (0xFF for async)
	}
}

void ProtocolGameBase::AddItem(NetworkMessage& msg, const Item* item)
{
	const ItemType& it = Item::items[item->getID()];
	msg.add<uint16_t>(it.clientId);
	// 	if (version >= 1185 && g_config.getBoolean(ConfigManager::PROTO_BUFF)) {
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
	}

	if (it.isAnimation) {
		msg.addByte(0xFE); // random phase (0xFF for async)
	}
}

void ProtocolGameBase::onConnect()
{
	auto output = OutputMessagePool::getOutputMessage();
	static std::random_device rd;
	static std::ranlux24 generator(rd());
	static std::uniform_int_distribution<uint16_t> randNumber(0x00, 0xFF);

	// Skip checksum
	output->skipBytes(sizeof(uint32_t));

	// Packet length & type
	output->add<uint16_t>(0x0006);
	output->addByte(0x1F);

	// Add timestamp & random number
	challengeTimestamp = static_cast<uint32_t>(OS_TIME(nullptr));
	output->add<uint32_t>(challengeTimestamp);

	challengeRandom = randNumber(generator);
	output->addByte(challengeRandom);

	// Go back and write checksum
	output->skipBytes(-12);
	// To support 11.10-, not have problems with 11.11+
	output->add<uint32_t>(adlerChecksum(output->getOutputBuffer() + sizeof(uint32_t), 8));

	send(std::move(output));
}

void ProtocolGameBase::AddOutfit(NetworkMessage& msg, const Outfit_t& outfit, bool addMount/* = true*/)
{
	msg.add<uint16_t>(outfit.lookType);

	if (outfit.lookType != 0) {
		msg.addByte(outfit.lookHead);
		msg.addByte(outfit.lookBody);
		msg.addByte(outfit.lookLegs);
		msg.addByte(outfit.lookFeet);
		msg.addByte(outfit.lookAddons);
	} else {
		msg.addItemId(outfit.lookTypeEx);
	}

	if (addMount) {
		msg.add<uint16_t>(outfit.lookMount);
	}
}

void ProtocolGameBase::checkCreatureAsKnown(uint32_t id, bool& known, uint32_t& removedKnown)
{
	auto result = knownCreatureSet.insert(id);
	if (!result.second) {
		known = true;
		return;
	}

	known = false;

	if (knownCreatureSet.size() > 1300) {
		// Look for a creature to remove
		for (auto it = knownCreatureSet.begin(), end = knownCreatureSet.end(); it != end; ++it) {
			Creature* creature = g_game.getCreatureByID(*it);
			if (!canSee(creature)) {
				removedKnown = *it;
				knownCreatureSet.erase(it);
				return;
			}
		}

		// Bad situation. Let's just remove anyone.
		auto it = knownCreatureSet.begin();
		if (*it == id) {
			++it;
		}

		removedKnown = *it;
		knownCreatureSet.erase(it);
	} else {
		removedKnown = 0;
	}
}

void ProtocolGameBase::sendLootContainers()
{
	if (version < 1150) {
		return;
	}
	NetworkMessage msg;
	msg.addByte(0xC0);
	msg.addByte(player->quickLootFallbackToMainContainer ? 1 : 0);
	std::map<ObjectCategory_t, Container*> quickLoot;
	for (auto it : player->quickLootContainers) {
		if (it.second && !it.second->isRemoved()) {
			quickLoot[it.first] = it.second;
		}
	}
	msg.addByte(quickLoot.size());
	for (auto it : quickLoot) {
		msg.addByte(it.first);
		msg.add<uint16_t>(it.second->getClientID());
	}

	writeToOutputBuffer(msg);
}

void ProtocolGameBase::AddCreature(NetworkMessage& msg, const Creature* creature, bool known, uint32_t remove)
{
	CreatureType_t creatureType = creature->getType();

	const Player* otherPlayer = creature->getPlayer();

	if (known) {
		msg.add<uint16_t>(0x62);
		msg.add<uint32_t>(creature->getID());
	} else {
		msg.add<uint16_t>(0x61);
		msg.add<uint32_t>(remove);
		msg.add<uint32_t>(creature->getID());
		msg.addByte(creatureType);

		if (player->getProtocolVersion() >= 1120) {
			if (creatureType == CREATURETYPE_SUMMONPLAYER) {
				const Creature* master = creature->getMaster();
				if (master) {
					msg.add<uint32_t>(master->getID());
				}
			}
		}

		msg.addString(creature->getName());
	}

	if (creature->isHealthHidden()) {
		msg.addByte(0x00);
	} else {
		msg.addByte(std::ceil((static_cast<double>(creature->getHealth()) / std::max<int32_t>(creature->getMaxHealth(), 1)) * 100));
	}

	msg.addByte(creature->getDirection());

	if (!creature->isInGhostMode() && !creature->isInvisible()) {
		const Outfit_t& outfit = creature->getCurrentOutfit();
		AddOutfit(msg, outfit);
		if (outfit.lookMount != 0) {
			msg.addByte(outfit.lookMountHead);
			msg.addByte(outfit.lookMountBody);
			msg.addByte(outfit.lookMountLegs);
			msg.addByte(outfit.lookMountFeet);
		}
	} else {
		static Outfit_t outfit;
		AddOutfit(msg, outfit);
	}

	LightInfo lightInfo = creature->getCreatureLight();
	msg.addByte(player->isAccessPlayer() ? 0xFF : lightInfo.level);
	msg.addByte(lightInfo.color);

	msg.add<uint16_t>(creature->getStepSpeed() / 2);

	if (player->getProtocolVersion() >= 1240) {
		msg.addByte(0); // Icons
	}
	msg.addByte(player->getSkullClient(creature));
	msg.addByte(player->getPartyShield(otherPlayer));

	if (!known) {
		msg.addByte(player->getGuildEmblem(otherPlayer));
	}

	if (player->getProtocolVersion() >= 1120) {
		if (creatureType == CREATURETYPE_MONSTER) {
			const Creature* master = creature->getMaster();
			if (master) {
				const Player* masterPlayer = master->getPlayer();
				if (masterPlayer) {
					creatureType = CREATURETYPE_SUMMONPLAYER;
				}
			}
		}
	}

	msg.addByte(creatureType); // Type (for summons)

	if (player->getProtocolVersion() >= 1120) {
		if (creatureType == CREATURETYPE_SUMMONPLAYER) {
			const Creature* master = creature->getMaster();
			if (master) {
				msg.add<uint32_t>(master->getID());
			}
		}
	}

	if(version >= 1215 && otherPlayer) {
		msg.addByte(0x01); // unknow
		msg.addByte(0x00); // unknow
	}

	if(version < 1215 || !otherPlayer) {
		msg.addByte(creature->getSpeechBubble());
	}

	msg.addByte(0xFF); // MARK_UNMARKED
	if (version >= 1110) {
		const Monster* monster = creature->getMonster();
		msg.addByte(((version < 1220 || monster) ? 0x00 : 0x05)); // inspection type
	}

	if (version < 1185) {
		if (otherPlayer) {
			msg.add<uint16_t>(otherPlayer->getHelpers());
		} else {
			msg.add<uint16_t>(0x00);
		}
	}

	msg.addByte(player->canWalkthroughEx(creature) ? 0x00 : 0x01);
}

void ProtocolGameBase::AddPlayerStats(NetworkMessage& msg)
{
	msg.addByte(0xA0);

	msg.add<uint16_t>(std::min<int32_t>(player->getHealth(), std::numeric_limits<uint16_t>::max()));
	msg.add<uint16_t>(std::min<int32_t>(player->getMaxHealth(), std::numeric_limits<uint16_t>::max()));

	msg.add<uint32_t>(player->getFreeCapacity());
	if (version < 1150) {
		msg.add<uint32_t>(player->getCapacity());
	}

	msg.add<uint64_t>(player->getExperience());

	msg.add<uint16_t>(player->getLevel());
	msg.addByte(player->getLevelPercent());

	msg.add<uint16_t>(player->getBaseXpGain()); // base xp gain rate
	if (version < 1150) {
		msg.add<uint16_t>(player->getVoucherXpBoost()); // xp voucher
	}
	msg.add<uint16_t>(player->getGrindingXpBoost()); // low level bonus
	msg.add<uint16_t>(player->getStoreXpBoost()); // xp boost
	msg.add<uint16_t>(player->getStaminaXpBoost()); // stamina multiplier (100 = 1.0x)

	msg.add<uint16_t>(std::min<int32_t>(player->getMana(), std::numeric_limits<uint16_t>::max()));
	msg.add<uint16_t>(std::min<int32_t>(player->getMaxMana(), std::numeric_limits<uint16_t>::max()));

	if (version < 1200) {
		msg.addByte(std::min<uint32_t>(player->getMagicLevel(), std::numeric_limits<uint8_t>::max()));
		msg.addByte(std::min<uint32_t>(player->getBaseMagicLevel(), std::numeric_limits<uint8_t>::max()));
		msg.addByte(player->getMagicLevelPercent());
	}

	msg.addByte(player->getSoul());

	msg.add<uint16_t>(player->getStaminaMinutes());

	msg.add<uint16_t>(player->getBaseSpeed() / 2);

	Condition* condition = player->getCondition(CONDITION_REGENERATION, CONDITIONID_DEFAULT, 0);
	msg.add<uint16_t>(condition ? condition->getTicks() / 1000 : 0x00);

	msg.add<uint16_t>(player->getOfflineTrainingTime() / 60 / 1000);

	msg.add<uint16_t>(player->getExpBoostStamina()); // xp boost time (seconds)

	StoreOffer* offer = g_store.getStoreOfferByName("XP Boost +50%");
	if (offer == nullptr) {
		msg.addByte(0);
	} else {
		std::string message = offer->getDisabledReason(player);
		msg.addByte(message.empty());
	}
	if (version >= 1260) {
		msg.add<uint16_t>(0);  // remaining mana shield
		msg.add<uint16_t>(0);  // total mana shield
	}
}

void ProtocolGameBase::AddPlayerSkills(NetworkMessage& msg)
{
	msg.addByte(0xA1);

	if (version >= 1200) {
		msg.add<uint16_t>(player->getMagicLevel());
		msg.add<uint16_t>(player->getBaseMagicLevel());
		msg.add<uint16_t>(player->getBaseMagicLevel());
		msg.add<uint16_t>(player->getMagicLevelPercent() * 100);
	}

	for (uint8_t i = SKILL_FIRST; i <= SKILL_FISHING; ++i) {
		msg.add<uint16_t>(std::min<int32_t>(player->getSkillLevel(i), std::numeric_limits<uint16_t>::max()));
		msg.add<uint16_t>(player->getBaseSkill(i));
		if (version >= 1200) {
			msg.add<uint16_t>(player->getBaseSkill(i));
			msg.add<uint16_t>(player->getSkillPercent(i) * 100);
		} else {
			msg.addByte(player->getSkillPercent(i));
		}
	}

	for (uint8_t i = SKILL_CRITICAL_HIT_CHANCE; i <= SKILL_LAST; ++i) {
		msg.add<uint16_t>(std::min<int32_t>(player->getSkillLevel(i), std::numeric_limits<uint16_t>::max()));
		msg.add<uint16_t>(player->getBaseSkill(i));
	}

	if (version >= 1150) { // used for imbuement (Feather)
		msg.add<uint32_t>(player->getCapacity()); // total capacity
		msg.add<uint32_t>(player->getCapacity() - player->getVarCapacity()); // base total capacity
	}
}

void ProtocolGameBase::AddWorldLight(NetworkMessage& msg, LightInfo lightInfo)
{
	msg.addByte(0x82);
	msg.addByte((player->isAccessPlayer() ? 0xFF : lightInfo.level));
	msg.addByte(lightInfo.color);
}

void ProtocolGameBase::AddCreatureLight(NetworkMessage& msg, const Creature* creature)
{
	LightInfo lightInfo = creature->getCreatureLight();

	msg.addByte(0x8D);
	msg.add<uint32_t>(creature->getID());
	msg.addByte((player->isAccessPlayer() ? 0xFF : lightInfo.level));
	msg.addByte(lightInfo.color);
}

bool ProtocolGameBase::canSee(const Creature* c) const
{
	if (!c || !player || c->isRemoved()) {
		return false;
	}

	if (!player->canSeeCreature(c)) {
		return false;
	}

	return canSee(c->getPosition());
}

bool ProtocolGameBase::canSee(const Position& pos) const
{
	return canSee(pos.x, pos.y, pos.z);
}

bool ProtocolGameBase::canSee(int32_t x, int32_t y, int32_t z) const
{
	if (!player) {
		return false;
	}

	const Position& myPos = player->getPosition();
	if (myPos.z <= 7) {
		//we are on ground level or above (7 -> 0)
		//view is from 7 -> 0
		if (z > 7) {
			return false;
		}
	} else if (myPos.z >= 8) {
		//we are underground (8 -> 15)
		//view is +/- 2 from the floor we stand on
		if (std::abs(myPos.getZ() - z) > 2) {
			return false;
		}
	}

	//negative offset means that the action taken place is on a lower floor than ourself
	int32_t offsetz = myPos.getZ() - z;
	if ((x >= myPos.getX() - 8 + offsetz) && (x <= myPos.getX() + 9 + offsetz) &&
			(y >= myPos.getY() - 6 + offsetz) && (y <= myPos.getY() + 7 + offsetz)) {
		return true;
	}
	return false;
}

//tile
void ProtocolGameBase::RemoveTileThing(NetworkMessage& msg, const Position& pos, uint32_t stackpos)
{
	if (stackpos >= 10) {
		return;
	}

	msg.addByte(0x6C);
	msg.addPosition(pos);
	msg.addByte(stackpos);
}

void ProtocolGameBase::sendUpdateTile(const Tile* tile, const Position& pos)
{
	if (!canSee(pos)) {
		return;
	}

	NetworkMessage msg;
	msg.addByte(0x69);
	msg.addPosition(pos);

	if (tile) {
		GetTileDescription(tile, msg);
		msg.addByte(0x00);
		msg.addByte(0xFF);
	} else {
		msg.addByte(0x01);
		msg.addByte(0xFF);
	}

	writeToOutputBuffer(msg);
}

void ProtocolGameBase::GetTileDescription(const Tile* tile, NetworkMessage& msg)
{
	if (version < 1200) {
		msg.add<uint16_t>(0x00); //environmental effects
	}

	int32_t count;
	Item* ground = tile->getGround();
	if (ground) {
		AddItem(msg, ground);
		count = 1;
	} else {
		count = 0;
	}

	const TileItemVector* items = tile->getItemList();
	if (items) {
		for (auto it = items->getBeginTopItem(), end = items->getEndTopItem(); it != end; ++it) {
			AddItem(msg, *it);

			count++;
			if (count == 9 && tile->getPosition() == player->getPosition()) {
				break;
			}
			else if (count == 10) {
				return;
			}

		}
	}

	const CreatureVector* creatures = tile->getCreatures();
	if (creatures) {
		bool playerAdded = false;
		for (const Creature* creature : boost::adaptors::reverse(*creatures)) {
			if (!player->canSeeCreature(creature)) {
				continue;
			}


			if (tile->getPosition() == player->getPosition() && count == 9 && !playerAdded) {
				creature = player;
			}


			if (creature->getID() == player->getID()) {
				playerAdded = true;
			}
			bool known;
			uint32_t removedKnown;
			checkCreatureAsKnown(creature->getID(), known, removedKnown);
			AddCreature(msg, creature, known, removedKnown);
			if (++count == 10) {
				return;
			}
		}
	}

	if (items) {
		for (auto it = items->getBeginDownItem(), end = items->getEndDownItem(); it != end; ++it) {
			AddItem(msg, *it);

			if (++count == 10) {
				return;
			}
		}
	}
}

void ProtocolGameBase::GetMapDescription(int32_t x, int32_t y, int32_t z, int32_t width, int32_t height, NetworkMessage& msg)
{
	int32_t skip = -1;
	int32_t startz, endz, zstep;

	if (z > 7) {
		startz = z - 2;
		endz = std::min<int32_t>(MAP_MAX_LAYERS - 1, z + 2);
		zstep = 1;
	} else {
		startz = 7;
		endz = 0;
		zstep = -1;
	}

	for (int32_t nz = startz; nz != endz + zstep; nz += zstep) {
		GetFloorDescription(msg, x, y, nz, width, height, z - nz, skip);
	}

	if (skip >= 0) {
		msg.addByte(skip);
		msg.addByte(0xFF);
	}
}

void ProtocolGameBase::GetFloorDescription(NetworkMessage& msg, int32_t x, int32_t y, int32_t z, int32_t width, int32_t height, int32_t offset, int32_t& skip)
{
	for (int32_t nx = 0; nx < width; nx++) {
		for (int32_t ny = 0; ny < height; ny++) {
			Tile* tile = g_game.map.getTile(x + nx + offset, y + ny + offset, z);
			if (tile) {
				if (skip >= 0) {
					msg.addByte(skip);
					msg.addByte(0xFF);
				}

				skip = 0;
				GetTileDescription(tile, msg);
			} else if (skip == 0xFE) {
				msg.addByte(0xFF);
				msg.addByte(0xFF);
				skip = -1;
			} else {
				++skip;
			}
		}
	}
}

void ProtocolGameBase::sendContainer(uint8_t cid, const Container* container, bool hasParent, uint16_t firstIndex)
{
	NetworkMessage msg;
	msg.addByte(0x6E);

	msg.addByte(cid);

	if (container->getID() == ITEM_BROWSEFIELD) {
		AddItem(msg, ITEM_BAG, 1);
		msg.addString("Browse Field");
	} else {
		AddItem(msg, container);
		msg.addString(container->getName());
	}

	msg.addByte(container->capacity());

	msg.addByte(hasParent ? 0x01 : 0x00);

	if(version >= 1220)
		msg.addByte(container->isLocker() ? 0x01 : 0x00); // inbox

	bool isUnlocked = container->isUnlocked();
	const ItemType& itemType = Item::items[container->getID()];
	if (itemType.corpseType != RACE_NONE) {
		isUnlocked = false;
	}

	msg.addByte(isUnlocked ? 0x01 : 0x00); // Drag and drop
	msg.addByte(container->hasPagination() ? 0x01 : 0x00); // Pagination

	uint32_t containerSize = container->size();
	msg.add<uint16_t>(containerSize);
	msg.add<uint16_t>(firstIndex);

	uint32_t maxItemsToSend;

	if (container->hasPagination() && firstIndex > 0) {
		maxItemsToSend = std::min<uint32_t>(container->capacity(), containerSize - firstIndex);
	} else {
		maxItemsToSend = container->capacity();
	}

	if (firstIndex >= containerSize) {
		msg.addByte(0x00);
	} else {
		msg.addByte(std::min<uint32_t>(maxItemsToSend, containerSize));

		uint32_t i = 0;
		const ItemDeque& itemList = container->getItemList();
		for (ItemDeque::const_iterator it = itemList.begin() + firstIndex, end = itemList.end(); i < maxItemsToSend && it != end; ++it, ++i) {
			AddItem(msg, *it);
		}
	}
	writeToOutputBuffer(msg);
}

void ProtocolGameBase::sendChannel(uint16_t channelId, const std::string& channelName, const UsersMap* channelUsers, const InvitedMap* invitedUsers)
{
	NetworkMessage msg;
	msg.addByte(0xAC);

	msg.add<uint16_t>(channelId);
	msg.addString(channelName);

	if (channelUsers) {
		msg.add<uint16_t>(channelUsers->size());
		for (const auto& it : *channelUsers) {
			msg.addString(it.second->getName());
		}
	} else {
		msg.add<uint16_t>(0x00);
	}

	if (invitedUsers) {
		msg.add<uint16_t>(invitedUsers->size());
		for (const auto& it : *invitedUsers) {
			msg.addString(it.second->getName());
		}
	} else {
		msg.add<uint16_t>(0x00);
	}
	writeToOutputBuffer(msg);
}

void ProtocolGameBase::sendMagicEffect(const Position& pos, uint8_t type)
{
	if (!canSee(pos)) {
		return;
	}

	NetworkMessage msg;
	msg.addByte(0x83);
	msg.addPosition(pos);
	if(version < 1220) {
		msg.addByte(type);
	} else {
		msg.addByte(0x83);
		msg.addByte(0x1);
		msg.addByte(0x00); // distance -- formula improvisada: https://pastebin.com/EVy6TYWs
		msg.addByte(MAGIC_EFFECTS_CREATE_EFFECT); // type
		msg.addByte(type); // effect
		msg.addByte(MAGIC_EFFECTS_END_LOOP); // hasImpactEffect?

	}

	writeToOutputBuffer(msg);
}

void ProtocolGameBase::sendAddCreature(const Creature* creature, const Position& pos, int32_t stackpos, bool isLogin)
{
	if (!canSee(pos)) {
		return;
	}

	if (creature != player) {
		if (stackpos >= 10) {
			return;
		}

		NetworkMessage msg;
		msg.addByte(0x6A);
		msg.addPosition(pos);
		msg.addByte(stackpos);

		bool known;
		uint32_t removedKnown;
		checkCreatureAsKnown(creature->getID(), known, removedKnown);
		AddCreature(msg, creature, known, removedKnown);
		writeToOutputBuffer(msg);

		if (isLogin) {
			//sendMagicEffect(pos, CONST_ME_TELEPORT);
		}

		return;
	}

	NetworkMessage msg;
	msg.addByte(0x17);

	msg.add<uint32_t>(player->getID());
	msg.add<uint16_t>(0x32); // beat duration (50)

	msg.addDouble(Creature::speedA, 3);
	msg.addDouble(Creature::speedB, 3);
	msg.addDouble(Creature::speedC, 3);

	// can report bugs?
	if (player->getAccountType() >= ACCOUNT_TYPE_NORMAL) {
		msg.addByte(0x01);
	} else {
		msg.addByte(0x00);
	}

	msg.addByte(0x00); // can change pvp framing option
	msg.addByte(0x00); // expert mode button enabled

	msg.addString(g_config.getString(ConfigManager::STORE_IMAGES_URL));
	msg.add<uint16_t>(static_cast<uint16_t>(g_config.getNumber(ConfigManager::STORE_COINS_PACKET_SIZE)));

	if (version >= 1150 || shouldAddExivaRestrictions) {
		msg.addByte(0x00); // exiva button enabled
	}

	if (version >= 1215) {
		msg.addByte(0x00); // tournament button enabled
	}

	writeToOutputBuffer(msg);

	sendPendingStateEntered();
	sendEnterWorld();

	if (version >= 1220) {
		msg.addByte(0xe4);
		msg.addByte(0x7);
		msg.addByte(0x1);
		msg.addByte(0x5);
		msg.addByte(0x4);
		msg.add<uint16_t>(266);
		msg.addString("a health potion");
		msg.add<uint32_t>(270);
		msg.add<uint16_t>(268);
		msg.addString("a mana potion");
		msg.add<uint32_t>(270);
		msg.add<uint16_t>(237);
		msg.addString("a strong mana potion");
		msg.add<uint32_t>(290);
		msg.add<uint16_t>(238);
		msg.addString("a great mana potion");
		msg.add<uint32_t>(310);
		msg.addByte(0x1);
		msg.addByte(10);
		msg.addByte(0x5);
		msg.add<uint16_t>(266);
		msg.addString("a health potion");
		msg.add<uint32_t>(270);
		msg.add<uint16_t>(268);
		msg.addString("a mana potion");
		msg.add<uint32_t>(270);
		msg.add<uint16_t>(237);
		msg.addString("a strong mana potion");
		msg.add<uint32_t>(290);
		msg.add<uint16_t>(238);
		msg.addString("a great mana potion");
		msg.add<uint32_t>(310);
		msg.add<uint16_t>(23373);
		msg.addString("an ultimate mana potion");
		msg.add<uint32_t>(310);
		msg.addByte(0x1);
		msg.addByte(0x5);
		msg.addByte(0x4);
		msg.add<uint16_t>(266);
		msg.addString("a health potion");
		msg.add<uint32_t>(270);
		msg.add<uint16_t>(268);
		msg.addString("a mana potion");
		msg.add<uint32_t>(270);
		msg.add<uint16_t>(237);
		msg.addString("a strong mana potion");
		msg.add<uint32_t>(290);
		msg.add<uint16_t>(238);
		msg.addString("a great mana potion");
		msg.add<uint32_t>(310);
		msg.addByte(0x1);
		msg.addByte(10);
		msg.addByte(0x5);
		msg.add<uint16_t>(266);
		msg.addString("a health potion");
		msg.add<uint32_t>(270);
		msg.add<uint16_t>(268);
		msg.addString("a mana potion");
		msg.add<uint32_t>(270);
		msg.add<uint16_t>(237);
		msg.addString("a strong mana potion");
		msg.add<uint32_t>(290);
		msg.add<uint16_t>(238);
		msg.addString("a great mana potion");
		msg.add<uint32_t>(310);
		msg.add<uint16_t>(23373);
		msg.addString("an ultimate mana potion");
		msg.add<uint32_t>(310);
		msg.addByte(0x2);
		msg.addByte(0x1);
		msg.addByte(0x2);
		msg.addByte(0x1);
		msg.addByte(0x2);
		msg.addByte(0x1);
		msg.addByte(0x2);
		msg.addByte(0x2);
		msg.addByte(0x1);
		msg.addByte(10);
		msg.addByte(0x4);
		msg.add<uint16_t>(266);
		msg.addString("a health potion");
		msg.add<uint32_t>(270);
		msg.add<uint16_t>(268);
		msg.addString("a mana potion");
		msg.add<uint32_t>(270);
		msg.add<uint16_t>(237);
		msg.addString("a strong mana potion");
		msg.add<uint32_t>(290);
		msg.add<uint16_t>(238);
		msg.addString("a great mana potion");
		msg.add<uint32_t>(310);
		msg.addByte(0x1);
		msg.addByte(0x14);
		msg.addByte(0x5);
		msg.add<uint16_t>(266);
		msg.addString("a health potion");
		msg.add<uint32_t>(270);
		msg.add<uint16_t>(268);
		msg.addString("a mana potion");
		msg.add<uint32_t>(270);
		msg.add<uint16_t>(237);
		msg.addString("a strong mana potion");
		msg.add<uint32_t>(290);
		msg.add<uint16_t>(238);
		msg.addString("a great mana potion");
		msg.add<uint32_t>(310);
		msg.add<uint16_t>(23373);
		msg.addString("an ultimate mana potion");
		msg.add<uint32_t>(310);
		msg.addByte(0x2);
		msg.addByte(0x1);
		msg.addByte(0x1);
		msg.add<uint16_t>(25719);
		msg.addString("temporary gold converter");
		msg.addByte(0x1);
		msg.addByte(0x2);
		msg.addByte(0x2);
		msg.addByte(0x1);
		msg.add<uint16_t>(25719);
		msg.addString("temporary gold converter");
		msg.addByte(0x1);
		msg.addByte(0x1);
		msg.add<uint16_t>(25718);
		msg.addString("temple teleport scroll");
		msg.addByte(0x1);
		msg.addByte(0x1);
		msg.addByte(0x1);
		msg.addByte(0x6);
		msg.add<uint16_t>(28540);
		msg.addString("a training sword");
		msg.add<uint32_t>(1000);
		msg.add<uint16_t>(28541);
		msg.addString("a training axe");
		msg.add<uint32_t>(1000);
		msg.add<uint16_t>(28542);
		msg.addString("a training club");
		msg.add<uint32_t>(1000);
		msg.add<uint16_t>(28543);
		msg.addString("a training bow");
		msg.add<uint32_t>(1000);
		msg.add<uint16_t>(28544);
		msg.addString("a training rod");
		msg.add<uint32_t>(1000);
		msg.add<uint16_t>(28545);
		msg.addString("a training wand");
		msg.add<uint32_t>(1000);
		msg.addByte(0x1);
		msg.addByte(0x2);
		msg.addByte(0x6);
		msg.add<uint16_t>(28540);
		msg.addString("a training sword");
		msg.add<uint32_t>(1000);
		msg.add<uint16_t>(28541);
		msg.addString("a training axe");
		msg.add<uint32_t>(1000);
		msg.add<uint16_t>(28542);
		msg.addString("a training club");
		msg.add<uint32_t>(1000);
		msg.add<uint16_t>(28543);
		msg.addString("a training bow");
		msg.add<uint32_t>(1000);
		msg.add<uint16_t>(28544);
		msg.addString("a training rod");
		msg.add<uint32_t>(1000);
		msg.add<uint16_t>(28545);
		msg.addString("a training wand");
		msg.add<uint32_t>(1000);
		msg.addByte(0x2);
		msg.addByte(0x1);
		msg.addByte(0x3);
		msg.add<uint16_t>(10);
		msg.addByte(0x2);
		msg.addByte(0x1);
		msg.addByte(0x3);
		msg.add<uint16_t>(30);
		msg.addByte(0x6);
		msg.addString("Allow Hit Point Regeneration");
		msg.addByte(0x2);
		msg.addString("Allow Mana Regeneration");
		msg.addByte(0x3);
		msg.addString("Stamina Regeneration");
		msg.addByte(0x4);
		msg.addString("Double Hit Point Regeneration");
		msg.addByte(0x5);
		msg.addString("Double Mana Regeneration");
		msg.addByte(0x6);
		msg.addString("Soul Point Regeneration");
		msg.addByte(0x7);
		msg.addByte(0x3);


		msg.addByte(0xb);
		msg.addString("4584b06c-28cc-4e81-bd75-83cb62685485");

	}

	sendMapDescription(pos);

	loggedIn = true;

	if (isLogin) {
		//sendMagicEffect(pos, CONST_ME_TELEPORT);
	}

	for (int i = CONST_SLOT_FIRST; i <= CONST_SLOT_LAST; ++i) {
		sendInventoryItem(static_cast<slots_t>(i), player->getInventoryItem(static_cast<slots_t>(i)));
	}

	sendStats();
	sendSkills();
	sendBlessStatus();
	sendPremiumTrigger();
	sendStoreHighlight();
	if (version >= 1200) {
		sendItemsPrice();
		player->sendMapManage(9);
	}

	//gameworld light-settings
	sendWorldLight(g_game.getWorldLightInfo());
	sendTibiaTime(g_game.getLightHour());

	//player light level
	sendCreatureLight(creature);

	const std::forward_list<VIPEntry>& vipEntries = IOLoginData::getVIPEntries(player->getAccount());

	if (player->isAccessPlayer()) {
		for (const VIPEntry& entry : vipEntries) {
			VipStatus_t vipStatus;

			Player* vipPlayer = g_game.getPlayerByGUID(entry.guid);
			if (!vipPlayer) {
				vipStatus = VIPSTATUS_OFFLINE;
			} else {
				vipStatus = VIPSTATUS_ONLINE;
			}

			sendVIP(entry.guid, entry.name, entry.description, entry.icon, entry.notify, vipStatus);
		}
	} else {
		for (const VIPEntry& entry : vipEntries) {
			VipStatus_t vipStatus;

			Player* vipPlayer = g_game.getPlayerByGUID(entry.guid);
			if (!vipPlayer || vipPlayer->isInGhostMode()) {
				vipStatus = VIPSTATUS_OFFLINE;
			} else {
				vipStatus = VIPSTATUS_ONLINE;
			}

			sendVIP(entry.guid, entry.name, entry.description, entry.icon, entry.notify, vipStatus);
		}
	}

	sendBasicData();
	for (uint8_t preySlotId = 0; preySlotId < PREY_SLOTCOUNT; preySlotId++) {
		sendPreyData(preySlotId);
	}
	player->updateRerollPrice();

	if (player->getProtocolVersion() >= 1130) {
		player->sendClientCheck();
		player->sendGameNews();
	}

	player->sendIcons();
}

void ProtocolGameBase::sendStats()
{
	NetworkMessage msg;
	AddPlayerStats(msg);
	writeToOutputBuffer(msg);
}

void ProtocolGameBase::sendBasicData()
{
	NetworkMessage msg;
	msg.addByte(0x9F);
	if (player->isPremium()) {
		msg.addByte(1);
		msg.add<uint32_t>(OS_TIME(nullptr) + (player->premiumDays * 86400));
	} else {
		msg.addByte(0);
		msg.add<uint32_t>(0);
	}
	msg.addByte(player->getVocation()->getClientId());

	// Prey window
	if (player->getVocation()->getId() == 0) {
		msg.addByte(0);
	} else {
		msg.addByte(1); // has reached Main (allow player to open Prey window)
	}

	std::list<uint16_t> spellsList = g_spells->getSpellsByVocation(player->getVocationId());
	msg.add<uint16_t>(spellsList.size());
	for (uint8_t sid : spellsList) {
		msg.addByte(sid);
	}
	msg.addByte(0);  // bool - determine whether magic shield is active or not
	writeToOutputBuffer(msg);
}

void ProtocolGameBase::sendBlessStatus()
{
	NetworkMessage msg;
	uint8_t blessCount = 0;
	uint8_t maxBlessings = (version > 1100) ? 8 : 6;
	for (int i = 1; i <= maxBlessings; i++) {
		if (player->hasBlessing(i)) {
			blessCount++;
		}
	}

	msg.addByte(0x9C);
	if (version >= 1120) {
		uint16_t blessFlag = 0;
		for (int i = 1; i < maxBlessings; i++){
			if (player->hasBlessing(i))
				blessFlag += (1 << (i));
		}
		msg.add<uint16_t>(blessFlag);
	} else {
		msg.add<uint16_t>(blessCount > 0);
	}

	if (version >= 1120) {
		uint8_t buttonColor = 1;
		if (blessCount >= 7) {
			buttonColor = 3;
		} else if (blessCount >= 5) {
			buttonColor = 2;
		}
		msg.addByte(buttonColor); // 1 = Disabled | 2 = normal | 3 = green
	}

	writeToOutputBuffer(msg);
}

void ProtocolGameBase::sendStoreHighlight()
{
	NetworkMessage msg;
	msg.addByte(0x19);
	msg.addByte( g_store.hasSaleOffer() ? 1 : 0 );
	msg.addByte( g_store.hasNewOffer() ? 1 : 0 );
	writeToOutputBuffer(msg);
}

void ProtocolGameBase::sendPremiumTrigger()
{
	if (!g_config.getBoolean(ConfigManager::FREE_PREMIUM)) {
		NetworkMessage msg;
		msg.addByte(0x9E);
		msg.addByte(16);
		for (uint16_t i = 0; i <= 15; i++) {
			//PREMIUM_TRIGGER_TRAIN_OFFLINE = false, PREMIUM_TRIGGER_XP_BOOST = false, PREMIUM_TRIGGER_MARKET = false, PREMIUM_TRIGGER_VIP_LIST = false, PREMIUM_TRIGGER_DEPOT_SPACE = false, PREMIUM_TRIGGER_INVITE_PRIVCHAT = false
			msg.addByte(0x01);
		}
		writeToOutputBuffer(msg);
	}
}

// Send preyInfo
void ProtocolGameBase::sendPreyData(uint8_t preySlotId)
{
	if (preySlotId >= PREY_SLOTCOUNT) {
		return;
	}

	NetworkMessage msg;
	PreyData& currentPreyData = player->preyData[preySlotId];
	msg.addByte(0xE8);
	msg.addByte(preySlotId);
	msg.addByte(currentPreyData.state);
	if (currentPreyData.state == STATE_LOCKED) {
		msg.addByte(UNLOCK_STORE);
	} else if (currentPreyData.state == STATE_SELECTION || currentPreyData.state == STATE_SELECTION_CHANGE_MONSTER) {
		if (currentPreyData.state == STATE_SELECTION_CHANGE_MONSTER) {
			msg.addByte(static_cast<uint8_t>(currentPreyData.bonusType));
			msg.add<uint16_t>(currentPreyData.bonusValue);
			msg.addByte(currentPreyData.bonusGrade);
		}
		msg.addByte(currentPreyData.preyList.size());
		for (const std::string& preyName : currentPreyData.preyList) {
			msg.addString(preyName);
			if (MonsterType* mType = g_monsters.getMonsterType(preyName)) {
				msg.add<uint16_t>(mType->info.outfit.lookType == 0 ? 21 : mType->info.outfit.lookType);
				msg.addByte(mType->info.outfit.lookHead);
				msg.addByte(mType->info.outfit.lookBody);
				msg.addByte(mType->info.outfit.lookLegs);
				msg.addByte(mType->info.outfit.lookFeet);
				msg.addByte(mType->info.outfit.lookAddons);
			} else {
				msg.add<uint16_t>(21);
				msg.addByte(0);
				msg.addByte(0);
				msg.addByte(0);
				msg.addByte(0);
				msg.addByte(0);
			}
		}

	} else if (currentPreyData.state == STATE_ACTIVE) {
		msg.addString(currentPreyData.preyMonster);
		if (MonsterType* mType = g_monsters.getMonsterType(currentPreyData.preyMonster)) {
				msg.add<uint16_t>(mType->info.outfit.lookType == 0 ? 21 : mType->info.outfit.lookType);
				msg.addByte(mType->info.outfit.lookHead);
				msg.addByte(mType->info.outfit.lookBody);
				msg.addByte(mType->info.outfit.lookLegs);
				msg.addByte(mType->info.outfit.lookFeet);
				msg.addByte(mType->info.outfit.lookAddons);
		} else {
			msg.add<uint16_t>(0);
			msg.add<uint16_t>(0);
		}

		msg.addByte(static_cast<uint8_t>(currentPreyData.bonusType));
		msg.add<uint16_t>(currentPreyData.bonusValue);
		msg.addByte(currentPreyData.bonusGrade);
		msg.add<uint16_t>(currentPreyData.timeLeft);
	} else if (currentPreyData.state == STATE_SELECTION_WILDCARD) {
		std::vector<uint16_t> v_races = g_prey.getPreyRaces();
		msg.add<uint16_t>(v_races.size());
		for (const auto& race : v_races) {
			msg.add<uint16_t>(race);
		}
	}

	msg.add<uint32_t>(player->getFreeRerollTime(preySlotId));
	if (version >= 1190) {
		msg.addByte(0x00); //preyWildCards
	}

	writeToOutputBuffer(msg);
}

void ProtocolGameBase::sendRerollPrice(uint32_t price)
{
	NetworkMessage msg;
	msg.addByte(0xE9);
	msg.add<uint32_t>(price);
	if (version >= 1190) {
		msg.addByte(0x01); // bomus reroll
		msg.addByte(0x05);
	}

	if (version >= 1230) {
		msg.add<uint32_t>(800);
		msg.add<uint32_t>(800);
		msg.addByte(2);
		msg.addByte(1);
	}

	writeToOutputBuffer(msg);
}

void ProtocolGameBase::sendFreeListRerollAvailability(uint8_t preySlotId, uint16_t time)
{
	NetworkMessage msg;
	msg.addByte(0xE6);
	msg.add<uint8_t>(preySlotId);
	msg.add<uint16_t>(time);

	writeToOutputBuffer(msg);
}

void ProtocolGameBase::sendPreyTimeLeft(uint8_t preySlotId, uint16_t timeLeft)
{
	NetworkMessage msg;
	msg.addByte(0xE7);
	msg.add<uint8_t>(preySlotId);
	msg.add<uint16_t>(timeLeft);

	writeToOutputBuffer(msg);	
}

void ProtocolGameBase::sendMessageDialog(MessageDialog_t type, const std::string& message)
{
	NetworkMessage msg;
	msg.addByte(0xED);
	msg.addByte(type);
	msg.addString(message);

	writeToOutputBuffer(msg);
}

void ProtocolGameBase::sendPendingStateEntered()
{
	NetworkMessage msg;
	msg.addByte(0x0A);
	writeToOutputBuffer(msg);
}

void ProtocolGameBase::sendEnterWorld()
{
	NetworkMessage msg;
	msg.addByte(0x0F);
	writeToOutputBuffer(msg);
}

void ProtocolGameBase::sendInventoryItem(slots_t slot, const Item* item)
{
	NetworkMessage msg;
	if (item) {
		msg.addByte(0x78);
		msg.addByte(slot);
		AddItem(msg, item);
	} else {
		msg.addByte(0x79);
		msg.addByte(slot);
	}
	writeToOutputBuffer(msg);
}

void ProtocolGameBase::sendSkills()
{
	NetworkMessage msg;
	AddPlayerSkills(msg);
	writeToOutputBuffer(msg);
}

void ProtocolGameBase::sendCreatureLight(const Creature* creature)
{
	if (!canSee(creature)) {
		return;
	}

	NetworkMessage msg;
	AddCreatureLight(msg, creature);
	writeToOutputBuffer(msg);
}

void ProtocolGameBase::sendWorldLight(const LightInfo& lightInfo)
{
	NetworkMessage msg;
	AddWorldLight(msg, lightInfo);
	writeToOutputBuffer(msg);
}

void ProtocolGameBase::sendMapDescription(const Position& pos)
{
	NetworkMessage msg;
	msg.addByte(0x64);
	msg.addPosition(player->getPosition());
	GetMapDescription(pos.x - 8, pos.y - 6, pos.z, 18, 14, msg);
	writeToOutputBuffer(msg);
}

void ProtocolGameBase::sendVIP(uint32_t guid, const std::string& name, const std::string& description, uint32_t icon, bool notify, VipStatus_t status)
{
	NetworkMessage msg;
	msg.addByte(0xD2);
	msg.add<uint32_t>(guid);
	msg.addString(name);
	msg.addString(description);
	msg.add<uint32_t>(std::min<uint32_t>(10, icon));
	msg.addByte(notify ? 0x01 : 0x00);
	msg.addByte(status);
	if (version >= 1110) {
		/* vipGroups: This is used for showing VipGroups by ids */
		msg.addByte(0x00);
	}

	writeToOutputBuffer(msg);
}

void ProtocolGameBase::sendCancelWalk()
{
	if (player) {
		NetworkMessage msg;
		msg.addByte(0xB5);
		msg.addByte(player->getDirection());
		writeToOutputBuffer(msg);
	}
}

void ProtocolGameBase::sendPing()
{
	if (player) {
		NetworkMessage msg;
		msg.addByte(0x1D);
		writeToOutputBuffer(msg, false);
	}
}

void ProtocolGameBase::sendPingBack()
{
	NetworkMessage msg;
	msg.addByte(0x1E);
	writeToOutputBuffer(msg, false);
}

void ProtocolGameBase::sendInventoryClientIds()
{
	std::map<uint16_t, uint16_t> items = player->getInventoryClientIds();

	NetworkMessage msg;
	msg.addByte(0xF5);
	msg.add<uint16_t>(items.size() + 11);

	for (uint16_t i = 1; i <= 11; i++) {
		msg.add<uint16_t>(i);
		msg.addByte(0x00);
		msg.add<uint16_t>(0x01);
	}

	for (const auto& it : items) {
		msg.add<uint16_t>(it.first);
		msg.addByte(0x00);
		msg.add<uint16_t>(it.second);
	}
	writeToOutputBuffer(msg);
}

void ProtocolGameBase::sendItemsPrice()
{
	NetworkMessage msg;
	msg.addByte(0xCD);

	msg.add<uint16_t>(g_game.getItemsPriceCount());

	if (g_game.getItemsPriceCount() > 0) {
		std::map<uint16_t, uint32_t> items = g_game.getItemsPrice();
		for (const auto& it : items) {
			msg.addItemId(it.first);
			msg.add<uint32_t>(it.second);
		}
	}

	writeToOutputBuffer(msg);
}

void ProtocolGameBase::sendTibiaTime(int32_t time)
{
	if (version < 1121) {
		return;
	}

	NetworkMessage msg;
	msg.addByte(0xEF);
	msg.addByte(time / 60);
	msg.addByte(time % 60);
	writeToOutputBuffer(msg);
}

void ProtocolGameBase::sendLootStats(Item* item)
{
	if (version <= 1100) {
		return;
	}

	NetworkMessage msg;
	msg.addByte(0xCF);
	AddItem(msg, item);
	msg.addString(item->getName());

	writeToOutputBuffer(msg);
}

void ProtocolGameBase::sendPvpSituations()
{
	NetworkMessage msg;
	msg.addByte(0xB8);
	msg.addByte(0x00);

	writeToOutputBuffer(msg);
}

void ProtocolGameBase::openStore()
{
	NetworkMessage msg;
	msg.addByte(0xFB);
	if (version < 1180) {
		msg.addByte(0x00);
	}

	msg.add<uint16_t>(g_store.getOfferCount());
	// enviando primeiro as categorias sem subcategorias
	std::vector<StoreCategory> categories = g_store.getStoreCategories();
	for (auto it = categories.begin(), end = categories.end(); it != end; ++it) {
		msg.addString((*it).name);
		if (version < 1180) {
			msg.add<uint16_t>(0x00);
		}

		msg.addByte(OFFER_STATE_NONE);

		msg.addByte(1);
		msg.addString((*it).icon);

		msg.add<uint16_t>(0x00);
	}

	std::vector<StoreOffers*> offers = g_store.getStoreOffers();
	for (auto it = offers.begin(), end = offers.end(); it != end; ++it) {
		msg.addString((*it)->getName());
		if (version < 1180) {
			msg.addString((*it)->getDescription());
		}

		msg.addByte((*it)->getOfferState());

		msg.addByte(1);
		msg.addString((*it)->getIcon());

		msg.addString((*it)->getParent());
	}

	writeToOutputBuffer(msg);
	player->updateCoinBalance();

	if (version >= 1150) {
		sendStoreHome();
	} else {
		StoreOffers* showOffer = g_store.getOfferByName(g_config.getString(ConfigManager::DEFAULT_OFFER));
		if (showOffer != nullptr)
			sendShowStoreOffers(showOffer);
	}
}

void ProtocolGameBase::sendShowStoreOffers(StoreOffers* offers)
{
	if (!offers) {
		return;
	}

	if (version <= 1100) {
		sendShowStoreOffers10(offers);
	} else {
		sendShowStoreOffers11(offers);
	}
}

void ProtocolGameBase::sendShowStoreOffers10(StoreOffers* offers)
{
	if (!offers) {
		return;
	}

	NetworkMessage msg;
	msg.addByte(0xFC);
	msg.addString(offers->getName());

	std::vector<StoreOffer*> organized = g_store.getStoreOffer(offers);
	msg.add<uint16_t>(organized.size());

	if (organized.size() > 0) {
		for (auto offer = organized.begin(), end = organized.end(); offer != end; ++offer) {
			std::ostringstream name;
			if ((*offer)->getCount() > 1)
				name << std::to_string((*offer)->getCount()) << "x ";

			name << (*offer)->getName();

			msg.add<uint32_t>((*offer)->getId());
			msg.addString(name.str());
			msg.addString((*offer)->getDescription(player));
			msg.add<uint32_t>((*offer)->getPrice(player));

			if ((*offer)->getOfferState() == OFFER_STATE_SALE) {
				time_t mytime;
				mytime = time(NULL);
				struct tm tm = *localtime(&mytime);
				int32_t daySub = (*offer)->getValidUntil() - tm.tm_mday;
				if (daySub >= 0) {
					msg.addByte((*offer)->getOfferState());
					msg.add<uint32_t>(mytime + daySub * 86400);
					msg.add<uint32_t>((*offer)->getBasePrice());
				} else {
					msg.addByte(OFFER_STATE_NONE);
				} 
			} else {
				msg.addByte((*offer)->getOfferState());
			}

			std::string disabled = (*offer)->getDisabledReason(player);
			msg.addByte(!disabled.empty());
			if (!disabled.empty()) {
				msg.addString(disabled);
			}

			msg.addByte(1); // nao vou dar suporte ao looping
			msg.addString((*offer)->getIcon());

			msg.add<uint16_t>(0x00); // nao damos suporte a subcategorias
		}
	}

	writeToOutputBuffer(msg);
}

void ProtocolGameBase::sendShowStoreOffers11(StoreOffers* offers)
{
	if (offers == nullptr) {
		player->sendStoreHome();
		return;
	}

	NetworkMessage msg;
	msg.addByte(0xFC);
	msg.addString(offers->getName());

	if (version >= 1180) {
		msg.add<uint32_t>(0);
		if (version >= 1185)
			msg.add<uint32_t>(0);
		else
			msg.add<uint16_t>(0);
	}

	uint16_t count = 0;
	std::map<std::string, std::vector<StoreOffer*>> organized = g_store.getStoreOrganizedByName(offers);
	for (const auto& it : organized) {
		if (!it.first.empty())
			count++;
	}

	msg.add<uint16_t>(count);

	if (count > 0) {
		for (const auto& it : organized) {
			msg.addString(it.first);
			msg.addByte(it.second.size());
			addStoreOffer(msg, it.second);
		}
	}

	writeToOutputBuffer(msg);
}

void ProtocolGameBase::sendOfferDescription(uint32_t id, std::string desc)
{
	NetworkMessage msg;
	msg.addByte(0xEA);
	msg.add<uint32_t>(id);
	msg.addString(desc);
	writeToOutputBuffer(msg);
}

void ProtocolGameBase::sendStoreHome()
{
	NetworkMessage msg;
	msg.addByte(0xFC);
	msg.addString("Home");

	msg.add<uint32_t>(0x0);
	msg.addByte(0x0);
	msg.addByte(0x0);
	msg.add<uint16_t>(0x00);

	uint16_t count = 0;
	std::map<std::string, std::vector<StoreOffer*>> organized = g_store.getHomeOffersOrganized();
	for (const auto& it : organized) {
		if (!it.first.empty())
			count++;
	}

	msg.add<uint16_t>(count);
	if (count > 0) {
		for (const auto& it : organized) {
			msg.addString(it.first);
			msg.addByte(it.second.size());
			addStoreOffer(msg, it.second);
		}

	}

	std::vector<std::string> banners =  g_store.getHomeBanners();
	for (auto banner = banners.begin(), end = banners.end(); banner != end; ++banner) {
		msg.addByte(banners.size());
		msg.addString((*banner));
		msg.addByte(banners.size()+1);
		msg.add<uint32_t>(0x0);
		msg.addByte(0x0);
	}

	msg.addByte(banners.size());
	msg.addByte(banners.size()+1);

	writeToOutputBuffer(msg);
}

void ProtocolGameBase::addStoreOffer(NetworkMessage& msg, std::vector<StoreOffer*> it)
{
	std::string lasticon;
	Mount* lastmount = nullptr;
	OfferTypes_t lasttype = OFFER_TYPE_NONE;
	uint32_t lastid = 0;
	uint16_t lastitemid = 0;
	uint16_t lastoutfit = 0;
	for (auto offer = it.begin(), end = it.end(); offer != end; ++offer) {
		lasttype = (*offer)->getOfferType();
		lasticon = (*offer)->getIcon();
		lastitemid = (*offer)->getItemType();
		lastoutfit = (player->getSex() == PLAYERSEX_FEMALE ? (*offer)->getOutfitFemale() : (*offer)->getOutfitMale());
		lastmount = (*offer)->getMount();
		if (lastid == 0)
			lastid = (*offer)->getId();

		msg.add<uint32_t>((*offer)->getId());
		msg.add<uint16_t>((*offer)->getCount());
		msg.add<uint32_t>((*offer)->getPrice(player));
		msg.addByte((*offer)->getCoinType());
	
		std::string disabled = (*offer)->getDisabledReason(player);
		msg.addByte(!disabled.empty());
		if (!disabled.empty()) {
			msg.addByte(0x01);
				msg.addString(disabled);
		}
	
		if ((*offer)->getOfferState() == OFFER_STATE_SALE) {
			time_t mytime;
			mytime = time(NULL);
			struct tm tm = *localtime(&mytime);
			int32_t daySub = (*offer)->getValidUntil() - tm.tm_mday;
			if (daySub >= 0) {
				msg.addByte((*offer)->getOfferState());
				msg.add<uint32_t>(mytime + daySub * 86400);
				msg.add<uint32_t>((*offer)->getBasePrice());
			} else {
				msg.addByte(OFFER_STATE_NONE);
			} 
		} else {
			msg.addByte((*offer)->getOfferState());
		}

	}

	uint8_t oftp = g_store.convertType(lasttype);
	msg.addByte(oftp);
	if (oftp == 0) {
		msg.addString(lasticon);
	} else if (oftp == 1) {
		msg.add<uint16_t>(lastmount->clientId);
	} else if (oftp == 2) {
		msg.add<uint16_t>(lastoutfit);
		msg.addByte(player->getCurrentOutfit().lookHead);
		msg.addByte(player->getCurrentOutfit().lookBody);
		msg.addByte(player->getCurrentOutfit().lookLegs);
		msg.addByte(player->getCurrentOutfit().lookFeet);
	} else if (oftp == 3) {
		msg.addItemId(lastitemid);
	}

	if (version >= 1220)
		msg.addByte(0x00);

	msg.add<uint16_t>(0x00); // category

	msg.add<uint16_t>(298);
	msg.add<uint32_t>(lasttype == OFFER_TYPE_NAMECHANGE ? lastid : 0x00);
	msg.addByte(lasttype == OFFER_TYPE_NAMECHANGE);
	msg.add<uint16_t>(0x00);

}

void ProtocolGameBase::sendStoreError(uint8_t errorType, std::string message)
{
	NetworkMessage msg;
	msg.addByte(0xE0);
	msg.addByte(errorType);
	msg.addString(message);
	writeToOutputBuffer(msg);
}

void ProtocolGameBase::sendStorePurchaseSuccessful(const std::string& message, const uint32_t coinBalance)
{
	NetworkMessage msg;

	msg.addByte(0xFE);
	msg.addByte(0x00);

	msg.addString(message);
	if (version < 1220) {
		msg.add<uint32_t>(coinBalance);
		msg.add<uint32_t>(coinBalance);
	}
	writeToOutputBuffer(msg);
}
