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

#include <bitset>

#include "bed.h"
#include "chat.h"
#include "combat.h"
#include "configmanager.h"
#include "creatureevent.h"
#include "events.h"
#include "game.h"
#include "iologindata.h"
#include "monster.h"
#include "movement.h"
#include "scheduler.h"
#include "weapons.h"
#include "tools.h"

extern ConfigManager g_config;
extern Game g_game;
extern Chat* g_chat;
extern Vocations g_vocations;
extern MoveEvents* g_moveEvents;
extern Weapons* g_weapons;
extern CreatureEvents* g_creatureEvents;
extern Events* g_events;
extern Imbuements g_imbuements;
extern Prey g_prey;

MuteCountMap Player::muteCountMap;

uint32_t Player::playerCombatAutoID = 0x10000000;
uint32_t Player::playerAutoID = 0x10010000;
uint32_t Player::maxPlayerAutoID = 0x60000000;

Player::Player(ProtocolGame_ptr p) :
	Creature(), preyData(PREY_SLOTCOUNT), lastPing(OTSYS_TIME()), lastPong(lastPing), inbox(new Inbox(ITEM_INBOX)), client(std::move(p))
{
	inbox->incrementReferenceCounter();
}

Player::~Player()
{
	for (Item* item : inventory) {
		if (item) {
			item->setParent(nullptr);
			item->decrementReferenceCounter();
		}
	}

	for (const auto& it : depotLockerMap) {
		it.second->removeInbox(inbox);
		it.second->decrementReferenceCounter();
	}

	for (const auto& it : rewardMap) {
		it.second->decrementReferenceCounter();
	}

	for (const auto& it : quickLootContainers) {
		it.second->decrementReferenceCounter();
	}

	inbox->decrementReferenceCounter();

	setWriteItem(nullptr);
	setEditHouse(nullptr);
	logged = false;
}

bool Player::setVocation(uint16_t vocId)
{
	Vocation* voc = g_vocations.getVocation(vocId);
	if (!voc) {
		return false;
	}

	vocation = voc;

	Condition* condition = getCondition(CONDITION_REGENERATION, CONDITIONID_DEFAULT);
	if (condition) {
		condition->setParam(CONDITION_PARAM_HEALTHGAIN, vocation->getHealthGainAmount());
		condition->setParam(CONDITION_PARAM_HEALTHTICKS, vocation->getHealthGainTicks() * 1000);
		condition->setParam(CONDITION_PARAM_MANAGAIN, vocation->getManaGainAmount());
		condition->setParam(CONDITION_PARAM_MANATICKS, vocation->getManaGainTicks() * 1000);
	}
	return true;
}

bool Player::isPushable() const
{
	if (hasFlag(PlayerFlag_CannotBePushed)) {
		return false;
	}
	return Creature::isPushable();
}

std::string Player::getDescription(int32_t lookDistance) const
{
	std::ostringstream s;

	if (lookDistance == -1) {
		s << "yourself.";

		if (group->access) {
			s << " You are " << group->name << '.';
		} else if (vocation->getId() != VOCATION_NONE) {
			s << " You are " << vocation->getVocDescription() << '.';
		} else {
			s << " You have no vocation.";
		}
	} else {
		s << name;
		if (!group->access) {
			s << " (Level " << level << ')';
		}
		s << '.';

		if (sex == PLAYERSEX_FEMALE) {
			s << " She";
		} else {
			s << " He";
		}

		if (group->access) {
			s << " is " << group->name << '.';
		} else if (vocation->getId() != VOCATION_NONE) {
			s << " is " << vocation->getVocDescription() << '.';
		} else {
			s << " has no vocation.";
		}
	}

	if (party) {
		if (lookDistance == -1) {
			s << " Your party has ";
		} else if (sex == PLAYERSEX_FEMALE) {
			s << " She is in a party with ";
		} else {
			s << " He is in a party with ";
		}

		size_t memberCount = party->getMemberCount() + 1;
		if (memberCount == 1) {
			s << "1 member and ";
		} else {
			s << memberCount << " members and ";
		}

		size_t invitationCount = party->getInvitationCount();
		if (invitationCount == 1) {
			s << "1 pending invitation.";
		} else {
			s << invitationCount << " pending invitations.";
		}
	}

	if (guild && guildRank) {
		size_t memberCount = guild->getMemberCount();
		if (memberCount >= 1000) {
			s << "";
			return s.str();
		}

		if (lookDistance == -1) {
			s << " You are ";
		} else if (sex == PLAYERSEX_FEMALE) {
			s << " She is ";
		} else {
			s << " He is ";
		}

		s << guildRank->name << " of the " << guild->getName() << " [Level " << guild->getLevel() << "]";
		if (!guildNick.empty()) {
			s << " (" << guildNick << ')';
		}

		if (memberCount == 1) {
			s << ", which has 1 member, " << guild->getMembersOnline().size() << " of them online.";
		} else {
			s << ", which has " << memberCount << " members, " << guild->getMembersOnline().size() << " of them online.";
		}
	}

	return s.str();
}

Item* Player::getInventoryItem(slots_t slot) const
{
	if (slot < CONST_SLOT_FIRST || slot > CONST_SLOT_LAST) {
		return nullptr;
	}
	return inventory[slot];
}

void Player::addConditionSuppressions(uint32_t conditions)
{
	conditionSuppressions |= conditions;
}

void Player::removeConditionSuppressions(uint32_t conditions)
{
	conditionSuppressions &= ~conditions;
}

Item* Player::getWeapon(slots_t slot, bool ignoreAmmo) const
{
	Item* item = inventory[slot];
	if (!item) {
		return nullptr;
	}

	WeaponType_t weaponType = item->getWeaponType();
	if (weaponType == WEAPON_NONE || weaponType == WEAPON_SHIELD || weaponType == WEAPON_AMMO) {
		return nullptr;
	}

	if (!ignoreAmmo && weaponType == WEAPON_DISTANCE) {
		const ItemType& it = Item::items[item->getID()];
      if (it.ammoType != AMMO_NONE) {
      Item* quiver = inventory[CONST_SLOT_RIGHT];
      if (!quiver || quiver->getWeaponType() != WEAPON_QUIVER)
        return nullptr;
      Container* container = quiver->getContainer();
      if (!container)
        return nullptr;
      bool found = false;
      for (Item* ammoItem : container->getItemList()) {
        if (ammoItem->getAmmoType() == it.ammoType) {
          item = ammoItem;
          found = true;
          break;
        }
      }
      if (!found)
        return nullptr;
      }
    }

	return item;
}

Item* Player::getWeapon(bool ignoreAmmo/* = false*/) const
{
	Item* item = getWeapon(CONST_SLOT_LEFT, ignoreAmmo);
	if (item) {
		return item;
	}

	item = getWeapon(CONST_SLOT_RIGHT, ignoreAmmo);
	if (item) {
		return item;
	}
	return nullptr;
}

WeaponType_t Player::getWeaponType() const
{
	Item* item = getWeapon();
	if (!item) {
		return WEAPON_NONE;
	}
	return item->getWeaponType();
}

int32_t Player::getWeaponSkill(const Item* item) const
{
	if (!item) {
		return getSkillLevel(SKILL_FIST);
	}

	int32_t attackSkill;

	WeaponType_t weaponType = item->getWeaponType();
	switch (weaponType) {
		case WEAPON_SWORD: {
			attackSkill = getSkillLevel(SKILL_SWORD);
			break;
		}

		case WEAPON_CLUB: {
			attackSkill = getSkillLevel(SKILL_CLUB);
			break;
		}

		case WEAPON_AXE: {
			attackSkill = getSkillLevel(SKILL_AXE);
			break;
		}

		case WEAPON_DISTANCE: {
			attackSkill = getSkillLevel(SKILL_DISTANCE);
			break;
		}

		default: {
			attackSkill = 0;
			break;
		}
	}
	return attackSkill;
}

int32_t Player::getArmor() const
{
	int32_t armor = 0;

	static const slots_t armorSlots[] = {CONST_SLOT_HEAD, CONST_SLOT_NECKLACE, CONST_SLOT_ARMOR, CONST_SLOT_LEGS, CONST_SLOT_FEET, CONST_SLOT_RING};
	for (slots_t slot : armorSlots) {
		Item* inventoryItem = inventory[slot];
		if (inventoryItem) {
			armor += inventoryItem->getArmor();
		}
	}
	return static_cast<int32_t>(armor * vocation->armorMultiplier);
}

void Player::getShieldAndWeapon(const Item*& shield, const Item*& weapon) const
{
	shield = nullptr;
	weapon = nullptr;

	for (uint32_t slot = CONST_SLOT_RIGHT; slot <= CONST_SLOT_LEFT; slot++) {
		Item* item = inventory[slot];
		if (!item) {
			continue;
		}

		switch (item->getWeaponType()) {
			case WEAPON_NONE:
				break;

			case WEAPON_SHIELD: {
				if (!shield || (shield && item->getDefense() > shield->getDefense())) {
					shield = item;
				}
				break;
			}

			default: { // weapons that are not shields
				weapon = item;
				break;
			}
		}
	}
}

int32_t Player::getDefense() const
{
	int32_t defenseSkill = getSkillLevel(SKILL_FIST);
	int32_t defenseValue = 7;
	const Item* weapon;
	const Item* shield;
	try {
		getShieldAndWeapon(shield, weapon);
	}
	catch (const std::exception&) {
		std::cout << "Got exception" << std::endl;
	}

	if (weapon) {
		defenseValue = weapon->getDefense() + weapon->getExtraDefense();
		defenseSkill = getWeaponSkill(weapon);
	}

	if (shield) {
		defenseValue = weapon != nullptr ? shield->getDefense() + weapon->getExtraDefense() : shield->getDefense();
		defenseSkill = getSkillLevel(SKILL_SHIELD);
	}

	if (defenseSkill == 0) {
		switch (fightMode) {
			case FIGHTMODE_ATTACK:
			case FIGHTMODE_BALANCED:
				return 1;

			case FIGHTMODE_DEFENSE:
				return 2;
		}
	}

	return (defenseSkill / 4. + 2.23) * defenseValue * 0.15 * getDefenseFactor() * vocation->defenseMultiplier;
}

float Player::getAttackFactor() const
{
	switch (fightMode) {
		case FIGHTMODE_ATTACK: return 1.0f;
		case FIGHTMODE_BALANCED: return 1.2f;
		case FIGHTMODE_DEFENSE: return 2.0f;
		default: return 1.0f;
	}
}

float Player::getDefenseFactor() const
{
	switch (fightMode) {
		case FIGHTMODE_ATTACK: return (OTSYS_TIME() - lastAttack) < getAttackSpeed() ? 0.5f : 1.0f;
		case FIGHTMODE_BALANCED: return (OTSYS_TIME() - lastAttack) < getAttackSpeed() ? 0.75f : 1.0f;
		case FIGHTMODE_DEFENSE: return 1.0f;
		default: return 1.0f;
	}
}

uint16_t Player::getClientIcons() const
{
	uint16_t icons = 0;
	for (Condition* condition : conditions) {
		if (!isSuppress(condition->getType())) {
			icons |= condition->getIcons();
		}
	}

	if (pzLocked) {
		icons |= ICON_REDSWORDS;
	}

	if (tile->hasFlag(TILESTATE_PROTECTIONZONE)) {
		icons |= ICON_PIGEON;

		// Don't show ICON_SWORDS if player is in protection zone.
		if (hasBitSet(ICON_SWORDS, icons)) {
			icons &= ~ICON_SWORDS;
		}
	}

	// Game client debugs with 10 or more icons
	// so let's prevent that from happening.
	std::bitset<20> icon_bitset(static_cast<uint64_t>(icons));
	for (size_t pos = 0, bits_set = icon_bitset.count(); bits_set >= 10; ++pos) {
		if (icon_bitset[pos]) {
			icon_bitset.reset(pos);
			--bits_set;
		}
	}
	return icon_bitset.to_ulong();
}

void Player::updateInventoryWeight()
{
	if (hasFlag(PlayerFlag_HasInfiniteCapacity)) {
		return;
	}

	inventoryWeight = 0;
	for (int i = CONST_SLOT_FIRST; i <= CONST_SLOT_LAST; ++i) {
		const Item* item = inventory[i];
		if (item) {
			inventoryWeight += item->getWeight();
		}
	}
}

void Player::addSkillAdvance(skills_t skill, uint64_t count)
{
	uint64_t currReqTries = vocation->getReqSkillTries(skill, skills[skill].level);
	uint64_t nextReqTries = vocation->getReqSkillTries(skill, skills[skill].level + 1);
	if (currReqTries >= nextReqTries) {
		//player has reached max skill
		return;
	}

	g_events->eventPlayerOnGainSkillTries(this, skill, count);
	if (count == 0) {
		return;
	}

	bool sendUpdateSkills = false;
	while ((skills[skill].tries + count) >= nextReqTries) {
		count -= nextReqTries - skills[skill].tries;
		skills[skill].level++;
		skills[skill].tries = 0;
		skills[skill].percent = 0;

		std::ostringstream ss;
		ss << "You advanced to " << getSkillName(skill) << " level " << skills[skill].level << '.';
		sendTextMessage(MESSAGE_EVENT_ADVANCE, ss.str());

		g_creatureEvents->playerAdvance(this, skill, (skills[skill].level - 1), skills[skill].level);

		sendUpdateSkills = true;
		currReqTries = nextReqTries;
		nextReqTries = vocation->getReqSkillTries(skill, skills[skill].level + 1);
		if (currReqTries >= nextReqTries) {
			count = 0;
			break;
		}
	}

	if (skill == SKILL_LEVEL) {
		updateRerollPrice();
	}

	skills[skill].tries += count;

	uint32_t newPercent;
	if (nextReqTries > currReqTries) {
		newPercent = Player::getPercentLevel(skills[skill].tries, nextReqTries);
	} else {
		newPercent = 0;
	}

	if (skills[skill].percent != newPercent) {
		skills[skill].percent = newPercent;
		sendUpdateSkills = true;
	}

	if (sendUpdateSkills) {
		sendStats();
		sendSkills();
	}
}

void Player::setVarStats(stats_t stat, int32_t modifier)
{
	varStats[stat] += modifier;

	switch (stat) {
		case STAT_MAXHITPOINTS: {
			if (getHealth() > getMaxHealth()) {
				Creature::changeHealth(getMaxHealth() - getHealth());
			} else {
				g_game.addCreatureHealth(this);
			}
			break;
		}

		case STAT_MAXMANAPOINTS: {
			if (getMana() > getMaxMana()) {
				Creature::changeMana(getMaxMana() - getMana());
			}
			break;
		}

		default: {
			break;
		}
	}
}

int32_t Player::getDefaultStats(stats_t stat) const
{
	switch (stat) {
		case STAT_MAXHITPOINTS: return healthMax;
		case STAT_MAXMANAPOINTS: return manaMax;
		case STAT_MAGICPOINTS: return getBaseMagicLevel();
		default: return 0;
	}
}

void Player::addContainer(uint8_t cid, Container* container)
{
	if (cid > 0xF) {
		return;
	}

	if (container->getID() == ITEM_BROWSEFIELD) {
		container->incrementReferenceCounter();
	}

	auto it = openContainers.find(cid);
	if (it != openContainers.end()) {
		OpenContainer& openContainer = it->second;
		Container* oldContainer = openContainer.container;
		if (oldContainer->getID() == ITEM_BROWSEFIELD) {
			oldContainer->decrementReferenceCounter();
		}

		openContainer.container = container;
		openContainer.index = 0;
	} else {
		OpenContainer openContainer;
		openContainer.container = container;
		openContainer.index = 0;
		openContainers[cid] = openContainer;
	}
}

void Player::closeContainer(uint8_t cid)
{
	auto it = openContainers.find(cid);
	if (it == openContainers.end()) {
		return;
	}

	OpenContainer openContainer = it->second;
	Container* container = openContainer.container;
	openContainers.erase(it);

	if (container && container->getID() == ITEM_BROWSEFIELD) {
		container->decrementReferenceCounter();
	}
}

void Player::setContainerIndex(uint8_t cid, uint16_t index)
{
	auto it = openContainers.find(cid);
	if (it == openContainers.end()) {
		return;
	}
	it->second.index = index;
}

Container* Player::getContainerByID(uint8_t cid)
{
	auto it = openContainers.find(cid);
	if (it == openContainers.end()) {
		return nullptr;
	}
	return it->second.container;
}

int8_t Player::getContainerID(const Container* container) const
{
	for (const auto& it : openContainers) {
		if (it.second.container == container) {
			return it.first;
		}
	}
	return -1;
}

uint16_t Player::getContainerIndex(uint8_t cid) const
{
	auto it = openContainers.find(cid);
	if (it == openContainers.end()) {
		return 0;
	}
	return it->second.index;
}

bool Player::canOpenCorpse(uint32_t ownerId) const
{
	return getID() == ownerId || (party && party->canOpenCorpse(ownerId));
}

uint16_t Player::getLookCorpse() const
{
	if (sex == PLAYERSEX_FEMALE) {
		return ITEM_FEMALE_CORPSE;
	} else {
		return ITEM_MALE_CORPSE;
	}
}

void Player::addStorageValue(const uint32_t key, const int32_t value, const bool isLogin/* = false*/)
{
	if (IS_IN_KEYRANGE(key, RESERVED_RANGE)) {
		if (IS_IN_KEYRANGE(key, OUTFITS_RANGE)) {
			outfits.emplace_back(
				value >> 16,
				value & 0xFF
			);
			return;
		} else if (IS_IN_KEYRANGE(key, MOUNTS_RANGE)) {
			// do nothing
		} else {
			std::cout << "Warning: unknown reserved key: " << key << " player: " << getName() << std::endl;
			return;
		}
	}

	if (value != -1) {
		storageMap[key] = value;

		if (!isLogin) {
			int32_t oldValue;
			getStorageValue(key, oldValue);

			auto currentFrameTime = g_dispatcher.getDispatcherCycle();
			g_events->eventOnStorageUpdate(this, key, value, oldValue, currentFrameTime);
		}
	} else {
		storageMap.erase(key);
	}
}

bool Player::getStorageValue(const uint32_t key, int32_t& value) const
{
	auto it = storageMap.find(key);
	if (it == storageMap.end()) {
		value = -1;
		return false;
	}

	value = it->second;
	return true;
}

bool Player::canSee(const Position& pos) const
{
	if (!client) {
		return false;
	}
	return client->canSee(pos);
}

bool Player::canSeeCreature(const Creature* creature) const
{
	if (creature == this) {
		return true;
	}

	if (creature->isInGhostMode() && !group->access) {
		return false;
	}

	if (!creature->getPlayer() && !canSeeInvisibility() && creature->isInvisible()) {
		return false;
	}
	return true;
}

bool Player::canWalkthrough(const Creature* creature) const
{
	if (group->access || creature->isInGhostMode()) {
		return true;
	}

	const Monster* monster = creature->getMonster();
	const Npc* npc = creature->getNpc();
	if (monster) {
		if (!monster->isPet()) {
			return false;
		}

		const Tile* creatureTile = monster->getTile();
		return creatureTile && (creatureTile->hasFlag(TILESTATE_NOPVPZONE) || creatureTile->hasFlag(TILESTATE_PROTECTIONZONE));
	}

	const Player* player = creature->getPlayer();
	if (player) {
		const Tile* playerTile = player->getTile();
		if (!playerTile || (!playerTile->hasFlag(TILESTATE_NOPVPZONE) && !playerTile->hasFlag(TILESTATE_PROTECTIONZONE) && player->getLevel() > static_cast<uint32_t>(g_config.getNumber(ConfigManager::PROTECTION_LEVEL)))) {
			return false;
		}

		const Item* playerTileGround = playerTile->getGround();
		if (!playerTileGround || !playerTileGround->hasWalkStack()) {
			return false;
		}

		Player* thisPlayer = const_cast<Player*>(this);
		if ((OTSYS_TIME() - lastWalkthroughAttempt) > 2000) {
			thisPlayer->setLastWalkthroughAttempt(OTSYS_TIME());
			return false;
		}

		if (creature->getPosition() != lastWalkthroughPosition) {
			thisPlayer->setLastWalkthroughPosition(creature->getPosition());
			return false;
		}

		thisPlayer->setLastWalkthroughPosition(creature->getPosition());
		return true;
		
		} else if (npc) { 
		const Tile* tile = npc->getTile();
		const HouseTile* houseTile = dynamic_cast<const HouseTile*>(tile);
		return (houseTile != nullptr);
	}

	return false;
}

bool Player::canWalkthroughEx(const Creature* creature) const
{
	if (group->access) {
		return true;
	}

	const Monster* monster = creature->getMonster();
	if (monster) {
		if (!monster->isPet()) {
			return false;
		}
		const Tile* creatureTile = monster->getTile();
		return creatureTile && (creatureTile->hasFlag(TILESTATE_NOPVPZONE) || creatureTile->hasFlag(TILESTATE_PROTECTIONZONE));
	}

	const Player* player = creature->getPlayer();
	const Npc* npc = creature->getNpc();
	if (player) {
		const Tile* playerTile = player->getTile();
		return playerTile && (playerTile->hasFlag(TILESTATE_NOPVPZONE) || playerTile->hasFlag(TILESTATE_PROTECTIONZONE) || player->getLevel() <= static_cast<uint32_t>(g_config.getNumber(ConfigManager::PROTECTION_LEVEL)) || g_game.getWorldType() == WORLD_TYPE_NO_PVP);
	} else if (npc) { 
		const Tile* tile = npc->getTile();
		const HouseTile* houseTile = dynamic_cast<const HouseTile*>(tile);
		return (houseTile != nullptr);
	} else {		
		return false;
	}

}

void Player::onReceiveMail() const
{
	if (isNearDepotBox()) {
		sendTextMessage(MESSAGE_EVENT_ADVANCE, "New mail has arrived.");
	}
}

Container* Player::setLootContainer(ObjectCategory_t category, Container* container, bool loading /* = false*/)
{
	Container* previousContainer = nullptr;
	auto it = quickLootContainers.find(category);
	if (it != quickLootContainers.end() && !loading) {
		previousContainer = (*it).second;
		uint32_t flags = previousContainer->getIntAttr(ITEM_ATTRIBUTE_QUICKLOOTCONTAINER);
		flags &= ~(1 << category);
		if (flags == 0) {
			previousContainer->removeAttribute(ITEM_ATTRIBUTE_QUICKLOOTCONTAINER);
		} else {
			previousContainer->setIntAttr(ITEM_ATTRIBUTE_QUICKLOOTCONTAINER, flags);
		}

		previousContainer->decrementReferenceCounter();
		quickLootContainers.erase(it);
	}

	if (container) {
		previousContainer = container;
		quickLootContainers[category] = container;

		container->incrementReferenceCounter();
		if (!loading) {
			uint32_t flags = container->getIntAttr(ITEM_ATTRIBUTE_QUICKLOOTCONTAINER);
			container->setIntAttr(ITEM_ATTRIBUTE_QUICKLOOTCONTAINER, flags | static_cast<uint32_t>(1 << category));
		}
	}

	return previousContainer;
}

Container* Player::getLootContainer(ObjectCategory_t category) const
{
	if (category != OBJECTCATEGORY_DEFAULT && !isPremium()) {
		category = OBJECTCATEGORY_DEFAULT;
	}

	auto it = quickLootContainers.find(category);
	if (it != quickLootContainers.end()) {
		return (*it).second;
	}

	if (category != OBJECTCATEGORY_DEFAULT) {
		// firstly, fallback to default
		return getLootContainer(OBJECTCATEGORY_DEFAULT);
	}

	return nullptr;
}

void Player::checkLootContainers(const Item* item)
{
	const Container* container = item->getContainer();
	if (!container) {
		return;
	}

	bool shouldSend = false;

	auto it = quickLootContainers.begin();
	while (it != quickLootContainers.end()) {
		Container* lootContainer = (*it).second;

		bool remove = false;
		if (item->getHoldingPlayer() != this && (item == lootContainer || container->isHoldingItem(lootContainer))) {
			remove = true;
		}

		if (remove) {
			shouldSend = true;
			it = quickLootContainers.erase(it);
			lootContainer->decrementReferenceCounter();
			lootContainer->removeAttribute(ITEM_ATTRIBUTE_QUICKLOOTCONTAINER);
		} else {
			++it;
		}
	}

	if (shouldSend) {
		sendLootContainers();
	}
}


bool Player::isNearDepotBox() const
{
	const Position& pos = getPosition();
	for (int32_t cx = -1; cx <= 1; ++cx) {
		for (int32_t cy = -1; cy <= 1; ++cy) {
			Tile* tile = g_game.map.getTile(pos.x + cx, pos.y + cy, pos.z);
			if (!tile) {
				continue;
			}

			if (tile->hasFlag(TILESTATE_DEPOT)) {
				return true;
			}
		}
	}
	return false;
}

DepotChest* Player::getDepotBox()
{
	DepotChest* depotBoxs = new DepotChest(ITEM_DEPOT);
	depotBoxs->incrementReferenceCounter();
	depotBoxs->setMaxDepotItems(getMaxDepotItems()); //check each depotID, if depot limit is 1000, so all depots have 17k items max, causes crash?? I think not
	for (int32_t index = 1; index <= g_config.getNumber(ConfigManager::DEPOT_BOXES); ++index) {
		depotBoxs->internalAddThing(getDepotChest((g_config.getNumber(ConfigManager::DEPOT_BOXES) + 1) - index, true));
	}
	return depotBoxs;
}

DepotChest* Player::getDepotChest(uint32_t depotId, bool autoCreate)
{
	auto it = depotChests.find(depotId);
	if (it != depotChests.end()) {
		return it->second;
	}

	if (!autoCreate) {
		return nullptr;
	}

	DepotChest* depotChest;

	if (depotId > 0 && depotId < 18) {
		depotChest = new DepotChest(ITEM_DEPOT_NULL + depotId);
	} else if (depotId == 18) {
		depotChest = new DepotChest(ITEM_DEPOT_XVIII);
	} else {
		depotChest = new DepotChest(ITEM_DEPOT);
	}

	depotChest->incrementReferenceCounter();
	//depotChest->setMaxDepotItems(getMaxDepotItems()); why ?? my depot commit don't have this code, is possible add more items in depot with this
	depotChests[depotId] = depotChest;
	return depotChest;
}

DepotLocker* Player::getDepotLocker(uint32_t depotId)
{
	auto it = depotLockerMap.find(depotId);
	if (it != depotLockerMap.end()) {
		inbox->setParent(it->second);
		for (uint8_t i = g_config.getNumber(ConfigManager::DEPOT_BOXES); i > 0; i--) {
			if (DepotChest* depotBox = getDepotChest(i, false)) {
				depotBox->setParent(it->second->getItemByIndex(0)->getContainer());
 			}
		}
		return it->second;
	}

	DepotLocker* depotLocker = new DepotLocker(ITEM_LOCKER1);
	depotLocker->setDepotId(depotId);
	depotLocker->internalAddThing(Item::CreateItem(ITEM_MARKET));
	depotLocker->internalAddThing(inbox);
	Container* depotChest = Item::CreateItemAsContainer(ITEM_DEPOT, g_config.getNumber(ConfigManager::DEPOT_BOXES));
	for (uint8_t i = g_config.getNumber(ConfigManager::DEPOT_BOXES); i > 0; i--) {
		DepotChest* depotBox = getDepotChest(i, true);
		depotChest->internalAddThing(depotBox);
		depotBox->setParent(depotChest);
	}
	depotLocker->internalAddThing(Item::CreateItem(ITEM_SUPPLY_STASH));
	depotLocker->internalAddThing(depotChest);
	depotLockerMap[depotId] = depotLocker;
	return depotLocker;
}

RewardChest* Player::getRewardChest()
{
	if (rewardChest != nullptr) {
		return rewardChest;
	}

	rewardChest = new RewardChest(ITEM_REWARD_CHEST);
	return rewardChest;
}

Reward* Player::getReward(uint32_t rewardId, bool autoCreate)
{
	auto it = rewardMap.find(rewardId);
	if (it != rewardMap.end()) {
		return it->second;
	}

	if (!autoCreate) {
		return nullptr;
	}

	uint32_t timestamp = static_cast<uint32_t>(OS_TIME(nullptr));
	if (rewardId > (timestamp + 24*3600)) {
		return nullptr;
	}

	Reward* reward = new Reward();
	reward->incrementReferenceCounter();
	reward->setIntAttr(ITEM_ATTRIBUTE_DATE, rewardId);
	rewardMap[rewardId] = reward;

	g_game.internalAddItem(getRewardChest(), reward, INDEX_WHEREEVER, FLAG_NOLIMIT);

	return reward;
}

void Player::removeReward(uint32_t rewardId) {
	rewardMap.erase(rewardId);
}

void Player::getRewardList(std::vector<uint32_t>& rewards) {
	rewards.reserve(rewardMap.size());
	for (auto& it : rewardMap) {
		rewards.push_back(it.first);
	}
}

void Player::sendCancelMessage(ReturnValue message) const
{
	sendCancelMessage(getReturnMessage(message));
}

void Player::sendStats()
{
	if (client) {
		client->sendStats();
		lastStatsTrainingTime = getOfflineTrainingTime() / 60 / 1000;
	}
}

bool Player::hasLostConnection()
{
	int64_t timeNow = OTSYS_TIME();

	bool hasLostConnection = false;
	if ((timeNow - lastPing) >= 5000) {
		if (!client) {
			hasLostConnection = true;
		}
	}
	int64_t noPongTime = timeNow - lastPong;
	return (hasLostConnection || noPongTime >= 7000);
}

void Player::sendPing()
{
	int64_t timeNow = OTSYS_TIME();

	bool hasLostConnection = false;
	if ((timeNow - lastPing) >= 5000) {
		lastPing = timeNow;
		if (client) {
			client->sendPing();
		} else {
			hasLostConnection = true;
		}
	}

	int64_t noPongTime = timeNow - lastPong;
	if ((hasLostConnection || noPongTime >= 7000) && attackedCreature && attackedCreature->getPlayer()) {
		setAttackedCreature(nullptr);
	}

	if (noPongTime >= 60000 && canLogout()) {
		if (g_creatureEvents->playerLogout(this)) {
			if (client) {
				client->logout(true, true);
			} else {
				g_game.removeCreature(this, true);
			}
		}
	}
}

Item* Player::getWriteItem(uint32_t& windowTextId, uint16_t& maxWriteLen)
{
	windowTextId = this->windowTextId;
	maxWriteLen = this->maxWriteLen;
	return writeItem;
}

void Player::inImbuing(Item* item)
{
	if (imbuing) {
		imbuing->decrementReferenceCounter();
	}

	if (item) {
		imbuing = item;
		imbuing->incrementReferenceCounter();
	} else {
		imbuing = nullptr;
	}
}

void Player::setWriteItem(Item* item, uint16_t maxWriteLen /*= 0*/)
{
	windowTextId++;

	if (writeItem) {
		writeItem->decrementReferenceCounter();
	}

	if (item) {
		writeItem = item;
		this->maxWriteLen = maxWriteLen;
		writeItem->incrementReferenceCounter();
	} else {
		writeItem = nullptr;
		this->maxWriteLen = 0;
	}
}

House* Player::getEditHouse(uint32_t& windowTextId, uint32_t& listId)
{
	windowTextId = this->windowTextId;
	listId = this->editListId;
	return editHouse;
}

void Player::setEditHouse(House* house, uint32_t listId /*= 0*/)
{
	windowTextId++;
	editHouse = house;
	editListId = listId;
}

void Player::sendHouseWindow(House* house, uint32_t listId) const
{
	if (!client) {
		return;
	}

	std::string text;
	if (house->getAccessList(listId, text)) {
		client->sendHouseWindow(windowTextId, text);
	}
}

//container
void Player::sendAddContainerItem(const Container* container, const Item* item)
{
	if (!client) {
		return;
	}

	for (const auto& it : openContainers) {
		const OpenContainer& openContainer = it.second;
		if (openContainer.container != container) {
			continue;
		}

		uint16_t slot = openContainer.index;
		if (container->getID() == ITEM_BROWSEFIELD) {
			uint16_t containerSize = container->size() - 1;
			uint16_t pageEnd = openContainer.index + container->capacity() - 1;
			if (containerSize > pageEnd) {
				slot = pageEnd;
				item = container->getItemByIndex(pageEnd);
			} else {
				slot = containerSize;
			}
		} else if (openContainer.index >= container->capacity()) {
			item = container->getItemByIndex(openContainer.index - 1);
		}
		client->sendAddContainerItem(it.first, slot, item);
	}
}

void Player::sendUpdateContainerItem(const Container* container, uint16_t slot, const Item* newItem)
{
	if (!client) {
		return;
	}

	for (const auto& it : openContainers) {
		const OpenContainer& openContainer = it.second;
		if (openContainer.container != container) {
			continue;
		}

		if (slot < openContainer.index) {
			continue;
		}

		uint16_t pageEnd = openContainer.index + container->capacity();
		if (slot >= pageEnd) {
			continue;
		}

		client->sendUpdateContainerItem(it.first, slot, newItem);
	}
}

void Player::sendRemoveContainerItem(const Container* container, uint16_t slot)
{
	if (!client) {
		return;
	}

	for (auto& it : openContainers) {
		OpenContainer& openContainer = it.second;
		if (openContainer.container != container) {
			continue;
		}

		uint16_t& firstIndex = openContainer.index;
		if (firstIndex > 0 && firstIndex >= container->size() - 1) {
			firstIndex -= container->capacity();
			sendContainer(it.first, container, false, firstIndex);
		}

		client->sendRemoveContainerItem(it.first, std::max<uint16_t>(slot, firstIndex), container->getItemByIndex(container->capacity() + firstIndex));
	}
}

void Player::onUpdateTileItem(const Tile* tile, const Position& pos, const Item* oldItem,
							  const ItemType& oldType, const Item* newItem, const ItemType& newType)
{
	Creature::onUpdateTileItem(tile, pos, oldItem, oldType, newItem, newType);

	if (oldItem != newItem) {
		onRemoveTileItem(tile, pos, oldType, oldItem);
	}

	if (tradeState != TRADE_TRANSFER) {
		if (tradeItem && oldItem == tradeItem) {
			g_game.internalCloseTrade(this);
		}
	}
}

void Player::onRemoveTileItem(const Tile* tile, const Position& pos, const ItemType& iType,
							  const Item* item)
{
	Creature::onRemoveTileItem(tile, pos, iType, item);

	if (tradeState != TRADE_TRANSFER) {
		checkTradeState(item);

		if (tradeItem) {
			const Container* container = item->getContainer();
			if (container && container->isHoldingItem(tradeItem)) {
				g_game.internalCloseTrade(this);
			}
		}
	}

	checkLootContainers(item);
}

void Player::onCreatureAppear(Creature* creature, bool isLogin)
{
	Creature::onCreatureAppear(creature, isLogin);
    
	if (g_game.isExpertPvpEnabled()) {
		g_game.updateSpectatorsPvp(this);
		g_game.updateSpectatorsPvp(creature);
	}

	if (isLogin && creature == this) {
		sendInventoryClientIds();
		for (int32_t slot = CONST_SLOT_FIRST; slot <= CONST_SLOT_LAST; ++slot) {
			Item* item = inventory[slot];
			if (item) {
				g_moveEvents->onPlayerEquip(this, item, static_cast<slots_t>(slot), false);
			}
		}


		for (Condition* condition : storedConditionList) {
			addCondition(condition);
		}
		storedConditionList.clear();

		BedItem* bed = g_game.getBedBySleeper(guid);
		if (bed) {
			bed->wakeUp(this);
		}

		std::cout << name << " has logged in." << std::endl;

		if (guild) {
			guild->addMember(this);
		}

		const Position& pos = getPosition();
		Tile* playerTile = g_game.map.getTile(pos);
		if (playerTile && playerTile->hasFlag(TILESTATE_PROTECTIONZONE) && isMounted()) {
			toggleMount(!isMounted());
		}

		int32_t offlineTime;
		if (getLastLogout() != 0) {
			// Not counting more than 21 days to prevent overflow when multiplying with 1000 (for milliseconds).
			offlineTime = std::min<int32_t>(OS_TIME(nullptr) - getLastLogout(), 86400 * 21);
		} else {
			offlineTime = 0;
		}

		for (Condition* condition : getMuteConditions()) {
			condition->setTicks(condition->getTicks() - (offlineTime * 1000));
			if (condition->getTicks() <= 0) {
				removeCondition(condition);
			}
		}

		g_game.checkPlayersRecord();
		IOLoginData::updateOnlineStatus(guid, true);
		if (!logged){
			sendLootContainers();
			logged = true;
		}
	}
}

void Player::onAttackedCreatureDisappear(bool isLogout)
{
	sendCancelTarget();

	if (!isLogout) {
		sendTextMessage(MESSAGE_STATUS_SMALL, "Target lost.");
	}
}

void Player::onFollowCreatureDisappear(bool isLogout)
{
	sendCancelTarget();

	if (!isLogout) {
		sendTextMessage(MESSAGE_STATUS_SMALL, "Target lost.");
	}
}

void Player::onChangeZone(ZoneType_t zone)
{
	if (zone == ZONE_PROTECTION) {
		if (attackedCreature && !hasFlag(PlayerFlag_IgnoreProtectionZone)) {
			setAttackedCreature(nullptr);
			onAttackedCreatureDisappear(false);
		}

		if (!group->access && isMounted()) {
			dismount();
			g_game.internalCreatureChangeOutfit(this, defaultOutfit);
			wasMounted = true;
		}
	} else {
		if (wasMounted) {
			toggleMount(true);
			wasMounted = false;
		}
	}

	g_game.updateCreatureWalkthrough(this);
	sendIcons();
}

void Player::onAttackedCreatureChangeZone(ZoneType_t zone)
{
	if (zone == ZONE_PROTECTION) {
		if (!hasFlag(PlayerFlag_IgnoreProtectionZone)) {
			setAttackedCreature(nullptr);
			onAttackedCreatureDisappear(false);
		}
	} else if (zone == ZONE_NOPVP) {
		if (attackedCreature->getPlayer()) {
			if (!hasFlag(PlayerFlag_IgnoreProtectionZone)) {
				setAttackedCreature(nullptr);
				onAttackedCreatureDisappear(false);
			}
		}
	} else if (zone == ZONE_NORMAL) {
		//attackedCreature can leave a pvp zone if not pzlocked
		if (g_game.getWorldType() == WORLD_TYPE_NO_PVP) {
			if (attackedCreature->getPlayer()) {
				setAttackedCreature(nullptr);
				onAttackedCreatureDisappear(false);
			}
		}
	}
}

void Player::onRemoveCreature(Creature* creature, bool isLogout)
{
	Creature::onRemoveCreature(creature, isLogout);

	if (creature == this) {
		if (isLogout) {
			loginPosition = getPosition();
		}

		lastLogout = OS_TIME(nullptr);

		if (eventWalk != 0) {
			setFollowCreature(nullptr);
		}

		if (tradePartner) {
			g_game.internalCloseTrade(this);
		}

		closeShopWindow();

		clearPartyInvitations();

		if (party) {
			party->leaveParty(this);
		}

		g_chat->removeUserFromAllChannels(*this);

		std::cout << getName() << " has logged out." << std::endl;

		if (guild) {
			guild->removeMember(this);
		}

		IOLoginData::updateOnlineStatus(guid, false);

		bool saved = false;
		for (uint32_t tries = 0; tries < 3; ++tries) {
			if (IOLoginData::savePlayer(this)) {
				saved = true;
				break;
			}
		}

		if (!saved) {
			std::cout << "Error while saving player: " << getName() << std::endl;
		}
	}
}

void Player::openShopWindow(Npc* npc, const std::list<ShopInfo>& shop)
{
	shopItemList = shop;
	sendShop(npc);
	sendSaleItemList();
}

bool Player::closeShopWindow(bool sendCloseShopWindow /*= true*/)
{
	//unreference callbacks
	int32_t onBuy;
	int32_t onSell;

	Npc* npc = getShopOwner(onBuy, onSell);
	if (!npc) {
		shopItemList.clear();
		return false;
	}

	setShopOwner(nullptr, -1, -1);
	npc->onPlayerEndTrade(this, onBuy, onSell);

	if (sendCloseShopWindow) {
		sendCloseShop();
	}

	shopItemList.clear();
	return true;
}

void Player::onWalk(Direction& dir)
{
	Creature::onWalk(dir);
	setNextActionTask(nullptr);
	setNextAction(OTSYS_TIME() + getStepDuration(dir));
}

void Player::onCreatureMove(Creature* creature, const Tile* newTile, const Position& newPos,
							const Tile* oldTile, const Position& oldPos, bool teleport)
{
	Creature::onCreatureMove(creature, newTile, newPos, oldTile, oldPos, teleport);

	if (hasFollowPath && (creature == followCreature || (creature == this && followCreature))) {
		isUpdatingPath = false;
		g_dispatcher.addTask(createTask(std::bind(&Game::updateCreatureWalk, &g_game, getID())));
	}

	if (creature != this) {
		return;
	}

	if (tradeState != TRADE_TRANSFER) {
		//check if we should close trade
		if (tradeItem && !Position::areInRange<1, 1, 0>(tradeItem->getPosition(), getPosition())) {
			g_game.internalCloseTrade(this);
		}

		if (tradePartner && !Position::areInRange<2, 2, 0>(tradePartner->getPosition(), getPosition())) {
			g_game.internalCloseTrade(this);
		}
	}

	// close modal windows
	if (!modalWindows.empty()) {
		// TODO: This shouldn't be hardcoded
		for (uint32_t modalWindowId : modalWindows) {
			if (modalWindowId == std::numeric_limits<uint32_t>::max()) {
				sendTextMessage(MESSAGE_EVENT_ADVANCE, "Offline training aborted.");
				break;
			}
		}
		modalWindows.clear();
	}

	// leave market
	if (inMarket) {
		inMarket = false;
	}

	if (party) {
		party->updateSharedExperience();
	}

	if (teleport || oldPos.z != newPos.z) {
		int32_t ticks = g_config.getNumber(ConfigManager::STAIRHOP_DELAY);
		if (ticks > 0) {
			if (Condition* condition = Condition::createCondition(CONDITIONID_DEFAULT, CONDITION_PACIFIED, ticks, 0)) {
				addCondition(condition);
			}
		}
	}
}

//container
void Player::onAddContainerItem(const Item* item)
{
	checkTradeState(item);
}

void Player::onUpdateContainerItem(const Container* container, const Item* oldItem, const Item* newItem)
{
	if (oldItem != newItem) {
		onRemoveContainerItem(container, oldItem);
	}

	if (tradeState != TRADE_TRANSFER) {
		checkTradeState(oldItem);
	}
}

void Player::onRemoveContainerItem(const Container* container, const Item* item)
{
	if (tradeState != TRADE_TRANSFER) {
		checkTradeState(item);

		if (tradeItem) {
			if (tradeItem->getParent() != container && container->isHoldingItem(tradeItem)) {
				g_game.internalCloseTrade(this);
			}
		}
	}

	checkLootContainers(item);
}

void Player::onCloseContainer(const Container* container)
{
	if (!client) {
		return;
	}

	for (const auto& it : openContainers) {
		if (it.second.container == container) {
			client->sendCloseContainer(it.first);
		}
	}
}

void Player::onSendContainer(const Container* container)
{
	if (!client) {
		return;
	}

	bool hasParent = container->hasParent();
	for (const auto& it : openContainers) {
		const OpenContainer& openContainer = it.second;
		if (openContainer.container == container) {
			client->sendContainer(it.first, container, hasParent, openContainer.index);
		}
	}
}

//inventory
void Player::onUpdateInventoryItem(Item* oldItem, Item* newItem)
{
	if (oldItem != newItem) {
		onRemoveInventoryItem(oldItem);
	}

	if (tradeState != TRADE_TRANSFER) {
		checkTradeState(oldItem);
	}
}

void Player::onRemoveInventoryItem(Item* item)
{
	if (tradeState != TRADE_TRANSFER) {
		checkTradeState(item);

		if (tradeItem) {
			const Container* container = item->getContainer();
			if (container && container->isHoldingItem(tradeItem)) {
				g_game.internalCloseTrade(this);
			}
		}
	}

	checkLootContainers(item);
}

void Player::checkTradeState(const Item* item)
{
	if (!tradeItem || tradeState == TRADE_TRANSFER) {
		return;
	}

	if (tradeItem == item) {
		g_game.internalCloseTrade(this);
	} else {
		const Container* container = dynamic_cast<const Container*>(item->getParent());
		while (container) {
			if (container == tradeItem) {
				g_game.internalCloseTrade(this);
				break;
			}

			container = dynamic_cast<const Container*>(container->getParent());
		}
	}
}

void Player::setNextWalkActionTask(SchedulerTask* task)
{
	if (walkTaskEvent != 0) {
		g_scheduler.stopEvent(walkTaskEvent);
		walkTaskEvent = 0;
	}

	delete walkTask;
	walkTask = task;
}

void Player::setNextWalkTask(SchedulerTask* task)
{
	if (nextStepEvent != 0) {
		g_scheduler.stopEvent(nextStepEvent);
		nextStepEvent = 0;
	}

	if (task) {
		nextStepEvent = g_scheduler.addEvent(task);
		resetIdleTime();
	}
}

void Player::setNextActionTask(SchedulerTask* task)
{
	if (actionTaskEvent != 0) {
		g_scheduler.stopEvent(actionTaskEvent);
		actionTaskEvent = 0;
	}

	if (!inEventMovePush)
		cancelPush();

	if (task) {
		actionTaskEvent = g_scheduler.addEvent(task);
		//resetIdleTime();
	}
}

void Player::setNextActionPushTask(SchedulerTask* task)
{
	if (actionTaskEventPush != 0) {
		g_scheduler.stopEvent(actionTaskEventPush);
		actionTaskEventPush = 0;
	}

	if (task) {
		actionTaskEventPush = g_scheduler.addEvent(task);
	}
}

void Player::cancelPush()
{
	if (actionTaskEventPush !=  0) {
		g_scheduler.stopEvent(actionTaskEventPush);
		actionTaskEventPush = 0;
		inEventMovePush = false;
	}	
}

void Player::setNextPotionActionTask(SchedulerTask* task)
{
	if (actionPotionTaskEvent != 0) {
		g_scheduler.stopEvent(actionPotionTaskEvent);
		actionPotionTaskEvent = 0;
	}

	cancelPush();

	if (task) {
		actionPotionTaskEvent = g_scheduler.addEvent(task);
		//resetIdleTime();
	}
}

uint32_t Player::getNextActionTime() const
{
	return std::max<int64_t>(SCHEDULER_MINTICKS, nextAction - OTSYS_TIME());
}

uint32_t Player::getNextPotionActionTime() const
{
	return std::max<int64_t>(SCHEDULER_MINTICKS, nextPotionAction - OTSYS_TIME());
}

void Player::onThink(uint32_t interval)
{
	Creature::onThink(interval);

	sendPing();

	if (deathTime > 0) {
		deathTime -= interval;
		if (deathTime <= 0) {
			kickPlayer(true);
		}
	}

	MessageBufferTicks += interval;
	if (MessageBufferTicks >= 1500) {
		MessageBufferTicks = 0;
		addMessageBuffer();
	}

	int32_t ninterval = static_cast<int32_t>(interval);
	Player* thisPlayer = const_cast<Player*>(this);
	if (thisPlayer->getProtectionCombatStatus() == COMBAT_STATUS_IN_CHECK) {
		if (!thisPlayer->hasLostConnection()) {
			thisPlayer->updateProtectionCombatStatus(COMBAT_STATUS_NONE);
			thisPlayer->updateProtectionCombat(-getProtectionCombat());
		} else {
			thisPlayer->updateProtectionCombat(-ninterval);
			if (thisPlayer->getProtectionCombat() <= 0) {
				thisPlayer->updateProtectionCombatStatus(COMBAT_STATUS_CHECKED);
				int32_t timelogout = 30000;
				// mages
				if (vocation->getId() == 1 || vocation->getId() == 2 ||  vocation->getId() == 5  ||  vocation->getId() == 6 ) {
					timelogout = 10000;
				// paladins
				} else if (vocation->getId() == 3 || vocation->getId() == 7) {
					timelogout = 20000;
				}
				thisPlayer->updateProtectionCombat(timelogout);
			}
		}
	// checando para deslogar
	} else if (thisPlayer->getProtectionCombatStatus() == COMBAT_STATUS_CHECKED) {
		if (!thisPlayer->hasLostConnection()) {
			thisPlayer->updateProtectionCombatStatus(COMBAT_STATUS_NONE);
			thisPlayer->updateProtectionCombat(-getProtectionCombat());
		} else {
			thisPlayer->updateProtectionCombat(-ninterval);
			if (getProtectionCombat() <= 0) {
				thisPlayer->updateProtectionCombatStatus(COMBAT_STATUS_NONE);
				// deslogando
				kickPlayer(true);
			}
		}
	} else if (!thisPlayer->hasLostConnection() && thisPlayer->getProtectionCombatStatus() != COMBAT_STATUS_NONE) {
		thisPlayer->updateProtectionCombatStatus(COMBAT_STATUS_NONE);
		thisPlayer->updateProtectionCombat(-getProtectionCombat());
	}

 	int32_t exerciseDummy;
 	getStorageValue(37, exerciseDummy);

 	if (exerciseDummy != 1) {
		if (!getTile()->hasFlag(TILESTATE_NOLOGOUT) && !isAccessPlayer()) {
			idleTime += interval;
			const int32_t kickAfterMinutes = g_config.getNumber(ConfigManager::KICK_AFTER_MINUTES);
			if (idleTime > (kickAfterMinutes * 60000) + 60000) {
				kickPlayer(true);
			} else if (client && idleTime == 60000 * kickAfterMinutes) {
				std::ostringstream ss;
				ss << "You have been idle for " << kickAfterMinutes << " minutes. You will be disconnected in one minute if you are still idle then.";
				client->sendTextMessage(TextMessage(MESSAGE_STATUS_WARNING, ss.str()));
			}
		}
 	}

	if (g_game.getWorldType() != WORLD_TYPE_PVP_ENFORCED) {
		checkSkullTicks(interval);
	}

	if (getZone() == ZONE_PROTECTION) {
		lastTimeStamina += interval / 1000;
		if (lastTimeStamina >= 120) {
			lastTimeStamina = 0;
			staminaMinutes = std::min<uint16_t>(2520, staminaMinutes + 1);
		}
	} else if (lastTimeStamina > 0) {
		lastTimeStamina = 0;
	}

	addOfflineTrainingTime(interval);
	if (lastStatsTrainingTime != getOfflineTrainingTime() / 60 / 1000) {
		sendStats();
	}
	
	if (g_game.isExpertPvpEnabled()) {
		g_game.updateSpectatorsPvp(const_cast<Player*>(this));
	}
}

uint32_t Player::isMuted() const
{
	if (hasFlag(PlayerFlag_CannotBeMuted)) {
		return 0;
	}

	int32_t muteTicks = 0;
	for (Condition* condition : conditions) {
		if (condition->getType() == CONDITION_MUTED && condition->getTicks() > muteTicks) {
			muteTicks = condition->getTicks();
		}
	}
	return static_cast<uint32_t>(muteTicks) / 1000;
}

void Player::addMessageBuffer()
{
	if (MessageBufferCount > 0 && g_config.getNumber(ConfigManager::MAX_MESSAGEBUFFER) != 0 && !hasFlag(PlayerFlag_CannotBeMuted)) {
		--MessageBufferCount;
	}
}

void Player::removeMessageBuffer()
{
	if (hasFlag(PlayerFlag_CannotBeMuted)) {
		return;
	}

	const int32_t maxMessageBuffer = g_config.getNumber(ConfigManager::MAX_MESSAGEBUFFER);
	if (maxMessageBuffer != 0 && MessageBufferCount <= maxMessageBuffer + 1) {
		if (++MessageBufferCount > maxMessageBuffer) {
			uint32_t muteCount = 1;
			auto it = muteCountMap.find(guid);
			if (it != muteCountMap.end()) {
				muteCount = it->second;
			}

			uint32_t muteTime = 5 * muteCount * muteCount;
			muteCountMap[guid] = muteCount + 1;
			Condition* condition = Condition::createCondition(CONDITIONID_DEFAULT, CONDITION_MUTED, muteTime * 1000, 0);
			addCondition(condition);

			std::ostringstream ss;
			ss << "You are muted for " << muteTime << " seconds.";
			sendTextMessage(MESSAGE_STATUS_SMALL, ss.str());
		}
	}
}

void Player::drainHealth(Creature* attacker, int32_t damage)
{
	Creature::drainHealth(attacker, damage);
	sendStats();
}

void Player::drainMana(Creature* attacker, int32_t manaLoss)
{
	Creature::drainMana(attacker, manaLoss);
	sendStats();
}

void Player::addManaSpent(uint64_t amount)
{
	if (hasFlag(PlayerFlag_NotGainMana)) {
		return;
	}

	uint64_t currReqMana = vocation->getReqMana(magLevel);
	uint64_t nextReqMana = vocation->getReqMana(magLevel + 1);
	if (currReqMana >= nextReqMana) {
		//player has reached max magic level
		return;
	}

	g_events->eventPlayerOnGainSkillTries(this, SKILL_MAGLEVEL, amount);
	if (amount == 0) {
		return;
	}

	bool sendUpdateStats = false;
	while ((manaSpent + amount) >= nextReqMana) {
		amount -= nextReqMana - manaSpent;

		magLevel++;
		manaSpent = 0;

		std::ostringstream ss;
		ss << "You advanced to magic level " << magLevel << '.';
		sendTextMessage(MESSAGE_EVENT_ADVANCE, ss.str());

		g_creatureEvents->playerAdvance(this, SKILL_MAGLEVEL, magLevel - 1, magLevel);

		sendUpdateStats = true;
		currReqMana = nextReqMana;
		nextReqMana = vocation->getReqMana(magLevel + 1);
		if (currReqMana >= nextReqMana) {
			return;
		}
	}

	manaSpent += amount;

	uint8_t oldPercent = magLevelPercent;
	if (nextReqMana > currReqMana) {
		magLevelPercent = Player::getPercentLevel(manaSpent, nextReqMana);
	} else {
		magLevelPercent = 0;
	}

	if (oldPercent != magLevelPercent) {
		sendUpdateStats = true;
	}

	if (sendUpdateStats) {
		sendStats();
		sendSkills();
	}
}

void Player::addExperience(Creature* source, uint64_t exp, bool sendText/* = false*/)
{
	uint64_t currLevelExp = Player::getExpForLevel(level);
	uint64_t nextLevelExp = Player::getExpForLevel(level + 1);
	uint64_t rawExp = exp;
	if (currLevelExp >= nextLevelExp) {
		//player has reached max level
		levelPercent = 0;
		sendStats();
		return;
	}

	g_events->eventPlayerOnGainExperience(this, source, exp, rawExp);
	if (exp == 0) {
		return;
	}

	experience += exp;

	if (sendText) {
		std::string expString = std::to_string(exp) + (exp != 1 ? " experience points" : " experience point");
		bool hasparenteses = false;
		if (hasActivePreyBonus(BONUS_XP_BONUS, source)) {
			hasparenteses = true;
			expString += " (active prey bonus";
		}

		if (isVip()) {
			if (!hasparenteses) {
				hasparenteses = true;
				expString += " (VIP Boost Active";
			} else {
				expString += " and VIP Boost";
			}
		}

		if (hasparenteses) {
			expString += ")";
		}
		expString += ".";

		TextMessage message(MESSAGE_EXPERIENCE, "You gained " + expString);
		message.position = position;
		message.primary.value = exp;
		message.primary.color = TEXTCOLOR_WHITE_EXP;
		sendTextMessage(message);

		SpectatorHashSet spectators;
		g_game.map.getSpectators(spectators, position, false, true);
		spectators.erase(this);
		if (!spectators.empty()) {
			message.type = MESSAGE_EXPERIENCE_OTHERS;
			message.text = getName() + " gained " + expString;
			for (Creature* spectator : spectators) {
				spectator->getPlayer()->sendTextMessage(message);
			}
		}
	}

	uint32_t prevLevel = level;
	while (experience >= nextLevelExp) {
		++level;
		healthMax += vocation->getHPGain();
		health += vocation->getHPGain();
		manaMax += vocation->getManaGain();
		mana += vocation->getManaGain();
		capacity += vocation->getCapGain();

		currLevelExp = nextLevelExp;
		nextLevelExp = Player::getExpForLevel(level + 1);
		if (currLevelExp >= nextLevelExp) {
			//player has reached max level
			break;
		}
	}

	if (prevLevel != level) {
		health = getMaxHealth();
		mana = getMaxMana();

		updateBaseSpeed();
		setBaseSpeed(getBaseSpeed());
		//setBaseXpGain(g_game.getExperienceStage(level)*100);
		g_game.changeSpeed(this, 0);
		g_game.addCreatureHealth(this);

		if (party) {
			party->updateSharedExperience();
		}

		g_creatureEvents->playerAdvance(this, SKILL_LEVEL, prevLevel, level);

		std::ostringstream ss;
		ss << "You advanced from Level " << prevLevel << " to Level " << level << '.';
		sendTextMessage(MESSAGE_EVENT_ADVANCE, ss.str());
	}

	if (nextLevelExp > currLevelExp) {
		levelPercent = Player::getPercentLevel(experience - currLevelExp, nextLevelExp - currLevelExp);
	} else {
		levelPercent = 0;
	}
	sendStats();
}

void Player::removeExperience(uint64_t exp, bool sendText/* = false*/)
{
	if (experience == 0 || exp == 0) {
		return;
	}

	g_events->eventPlayerOnLoseExperience(this, exp);
	if (exp == 0) {
		return;
	}

	uint64_t lostExp = experience;
	experience = std::max<int64_t>(0, experience - exp);

	if (sendText) {
		lostExp -= experience;

		std::string expString = std::to_string(lostExp) + (lostExp != 1 ? " experience points." : " experience point.");

		TextMessage message(MESSAGE_EXPERIENCE, "You lost " + expString);
		message.position = position;
		message.primary.value = lostExp;
		message.primary.color = TEXTCOLOR_RED;
		sendTextMessage(message);

		SpectatorHashSet spectators;
		g_game.map.getSpectators(spectators, position, false, true);
		spectators.erase(this);
		if (!spectators.empty()) {
			message.type = MESSAGE_EXPERIENCE_OTHERS;
			message.text = getName() + " lost " + expString;
			for (Creature* spectator : spectators) {
				spectator->getPlayer()->sendTextMessage(message);
			}
		}
	}

	uint32_t oldLevel = level;
	uint64_t currLevelExp = Player::getExpForLevel(level);

	while (level > 1 && experience < currLevelExp) {
		--level;
		healthMax = std::max<int32_t>(0, healthMax - vocation->getHPGain());
		manaMax = std::max<int32_t>(0, manaMax - vocation->getManaGain());
		capacity = std::max<int32_t>(0, capacity - vocation->getCapGain());
		currLevelExp = Player::getExpForLevel(level);
	}

	if (oldLevel != level) {
		health = getMaxHealth();
		mana = getMaxMana();

		updateBaseSpeed();
		setBaseSpeed(getBaseSpeed());

		g_game.changeSpeed(this, 0);
		g_game.addCreatureHealth(this);

		if (party) {
			party->updateSharedExperience();
		}

		std::ostringstream ss;
		ss << "You were downgraded from Level " << oldLevel << " to Level " << level << '.';
		sendTextMessage(MESSAGE_EVENT_ADVANCE, ss.str());
	}

	uint64_t nextLevelExp = Player::getExpForLevel(level + 1);
	if (nextLevelExp > currLevelExp) {
		levelPercent = Player::getPercentLevel(experience - currLevelExp, nextLevelExp - currLevelExp);
	} else {
		levelPercent = 0;
	}
	sendStats();
}

uint8_t Player::getPercentLevel(uint64_t count, uint64_t nextLevelCount)
{
	if (nextLevelCount == 0) {
		return 0;
	}

	uint8_t result = (count * 100) / nextLevelCount;
	if (result > 100) {
		return 0;
	}
	return result;
}

void Player::onBlockHit()
{
	if (shieldBlockCount > 0) {
		--shieldBlockCount;

		if (hasShield()) {
			addSkillAdvance(SKILL_SHIELD, 1);
		}
	}
}

void Player::onAttackedCreatureBlockHit(BlockType_t blockType)
{
	lastAttackBlockType = blockType;

	switch (blockType) {
		case BLOCK_NONE: {
			addAttackSkillPoint = true;
			bloodHitCount = 30;
			shieldBlockCount = 30;
			break;
		}

		case BLOCK_DEFENSE:
		case BLOCK_ARMOR: {
			//need to draw blood every 30 hits
			if (bloodHitCount > 0) {
				addAttackSkillPoint = true;
				--bloodHitCount;
			} else {
				addAttackSkillPoint = false;
			}
			break;
		}

		default: {
			addAttackSkillPoint = false;
			break;
		}
	}
}

bool Player::hasShield() const
{
	Item* item = inventory[CONST_SLOT_LEFT];
	if (item && item->getWeaponType() == WEAPON_SHIELD) {
		return true;
	}

	item = inventory[CONST_SLOT_RIGHT];
	if (item && item->getWeaponType() == WEAPON_SHIELD) {
		return true;
	}
	return false;
}

BlockType_t Player::blockHit(Creature* attacker, CombatType_t combatType, int32_t& damage,
							 bool checkDefense /* = false*/, bool checkArmor /* = false*/, bool field /* = false*/)
{
	BlockType_t blockType = Creature::blockHit(attacker, combatType, damage, checkDefense, checkArmor, field);

	if (!g_game.isExpertPvpEnabled() && attacker) {
		sendCreatureSquare(attacker, SQ_COLOR_BLACK);
	}

	if (blockType != BLOCK_NONE) {
		return blockType;
	}

	if (damage > 0) {
		for (int32_t slot = CONST_SLOT_FIRST; slot <= CONST_SLOT_LAST; ++slot) {
			if (!isItemAbilityEnabled(static_cast<slots_t>(slot))) {
				continue;
			}

			Item* item = inventory[slot];
			if (!item) {
				continue;
			}

			const ItemType& it = Item::items[item->getID()];
			if (it.abilities) {
				const int16_t& absorbPercent = it.abilities->absorbPercent[combatTypeToIndex(combatType)];
				if (absorbPercent != 0) {
					damage -= std::round(damage * (absorbPercent / 100.));

					uint16_t charges = item->getCharges();
					if (charges != 0) {
						g_game.transformItem(item, item->getID(), charges - 1);
					}
				}

				if (field) {
					const int16_t& fieldAbsorbPercent = it.abilities->fieldAbsorbPercent[combatTypeToIndex(combatType)];
					if (fieldAbsorbPercent != 0) {
						damage -= std::round(damage * (fieldAbsorbPercent / 100.));

						uint16_t charges = item->getCharges();
						if (charges != 0) {
							g_game.transformItem(item, item->getID(), charges - 1);
						}
					}
				}
				if (attacker) {
					const int16_t& reflectPercent = it.abilities->reflectPercent[combatTypeToIndex(combatType)];
					if (reflectPercent != 0) {
						CombatParams params;
						params.combatType = combatType;
						params.impactEffect = CONST_ME_MAGIC_BLUE;

						CombatDamage reflectDamage;
						reflectDamage.origin = ORIGIN_SPELL;
						reflectDamage.primary.type = combatType;
						reflectDamage.primary.value = std::round(-damage * (reflectPercent / 100.));

						Combat::doTargetCombat(this, attacker, reflectDamage, params);
					}
				}
			}

			uint8_t slots = Item::items[item->getID()].imbuingSlots;
			for (uint8_t i = 0; i < slots; i++) {
				uint32_t info = item->getImbuement(i);
				if (info >> 8) {
					Imbuement* ib = g_imbuements.getImbuement(info & 0xFF);
					const int16_t& absorbPercent2 = ib->absorbPercent[combatTypeToIndex(combatType)];

					if (absorbPercent2 != 0) {
						damage -= std::ceil(damage * (absorbPercent2 / 100.));
					}
				}
			}
		}

		if (damage <= 0) {
			damage = 0;
			blockType = BLOCK_ARMOR;
		}
	}
	return blockType;
}

uint32_t Player::getIP() const
{
	if (client) {
		return client->getIP();
	}

	return 0;
}

void Player::death(Creature* lastHitCreature)
{
	loginPosition = town->getTemplePosition();

	if (skillLoss) {
		uint8_t unfairFightReduction = 100;
		int playerDmg = 0;
		int othersDmg = 0;
		uint32_t sumLevels = 0;
		// 5*60000
		uint32_t inFightTicks = 5 * (g_config.getNumber(ConfigManager::PZ_LOCKED));
		for (const auto& it : damageMap) {
			CountBlock_t cb = it.second;
			if ((OTSYS_TIME() - cb.ticks) <= inFightTicks) {
				Player* damageDealer = g_game.getPlayerByID(it.first);
				if (damageDealer) {
					playerDmg += cb.total;
					sumLevels += damageDealer->getLevel();
				} else{
					othersDmg += cb.total;
				}
			}
		}

		bool pvpDeath = false;
		bool deathPlayer = false;
		if (playerDmg > 0 || othersDmg > 0) {
			pvpDeath = (g_game.getWorldType() != WORLD_TYPE_RETRO_OPEN_PVP && (Player::lastHitIsPlayer(lastHitCreature) || playerDmg / (playerDmg + static_cast<double>(othersDmg)) >= 0.05));
			deathPlayer = (Player::lastHitIsPlayer(lastHitCreature) || playerDmg / (playerDmg + static_cast<double>(othersDmg)) >= 0.05);
		}

		if (pvpDeath && sumLevels > level) {
			double reduce = level / static_cast<double>(sumLevels);
			unfairFightReduction = std::max<uint8_t>(20, std::floor((reduce * 100) + 0.5));
		}


		//Magic level loss
		uint64_t sumMana = 0;
		uint64_t lostMana = 0;

		//sum up all the mana
		for (uint32_t i = 1; i <= magLevel; ++i) {
			sumMana += vocation->getReqMana(i);
		}

		sumMana += manaSpent;

		double percentCharm = 1.0;
		if (lastHitCreature) {
			Monster* tmpMonster = lastHitCreature->getMonster();
			if (tmpMonster && tmpMonster->getRaceId() > 0 && getCurrentCreature(12) == tmpMonster->getRaceId()) {
				percentCharm = 0.7;
			}
		}

		if (g_game.getWorldType() == WORLD_TYPE_RETRO_OPEN_PVP && getSkull() == SKULL_WHITE) {
			setSkull(SKULL_NONE);
		}

		double deathLossPercent = getLostPercent() * (unfairFightReduction / 100.) * percentCharm;

		lostMana = static_cast<uint64_t>(sumMana * deathLossPercent);

		while (lostMana > manaSpent && magLevel > 0) {
			lostMana -= manaSpent;
			manaSpent = vocation->getReqMana(magLevel);
			magLevel--;
		}

		manaSpent -= lostMana;

		uint64_t nextReqMana = vocation->getReqMana(magLevel + 1);
		if (nextReqMana > vocation->getReqMana(magLevel)) {
			magLevelPercent = Player::getPercentLevel(manaSpent, nextReqMana);
		} else {
			magLevelPercent = 0;
		}

		//Skill loss
		for (uint8_t i = SKILL_FIRST; i <= SKILL_LAST; ++i) { //for each skill
			uint64_t sumSkillTries = 0;
			for (uint16_t c = 11; c <= skills[i].level; ++c) { //sum up all required tries for all skill levels
				sumSkillTries += vocation->getReqSkillTries(i, c);
			}

			sumSkillTries += skills[i].tries;

			uint32_t lostSkillTries = static_cast<uint32_t>(sumSkillTries * deathLossPercent);
			while (lostSkillTries > skills[i].tries) {
				lostSkillTries -= skills[i].tries;

				if (skills[i].level <= 10) {
					skills[i].level = 10;
					skills[i].tries = 0;
					lostSkillTries = 0;
					break;
				}

				skills[i].tries = vocation->getReqSkillTries(i, skills[i].level);
				skills[i].level--;
			}

			skills[i].tries = std::max<int32_t>(0, skills[i].tries - lostSkillTries);
			skills[i].percent = Player::getPercentLevel(skills[i].tries, vocation->getReqSkillTries(i, skills[i].level));
		}

		//Level loss
		uint64_t expLoss = static_cast<uint64_t>(experience * deathLossPercent);
		// fazer o calculo de 1 level aqui
		if (deathPlayer) {
			uint64_t expLevel = Player::getExpForLevel(level - 1);
			expLoss = experience - expLevel;
		}

		g_events->eventPlayerOnLoseExperience(this, expLoss);

		if (expLoss != 0) {
			uint32_t oldLevel = level;

			if (vocation->getId() == VOCATION_NONE || level > 7) {
				experience -= expLoss;
			}

			while (level > 1 && experience < Player::getExpForLevel(level)) {
				--level;
				healthMax = std::max<int32_t>(0, healthMax - vocation->getHPGain());
				manaMax = std::max<int32_t>(0, manaMax - vocation->getManaGain());
				capacity = std::max<int32_t>(0, capacity - vocation->getCapGain());
			}

			if (oldLevel != level) {
				std::ostringstream ss;
				ss << "You were downgraded from Level " << oldLevel << " to Level " << level << '.';
				sendTextMessage(MESSAGE_EVENT_ADVANCE, ss.str());
			}

			uint64_t currLevelExp = Player::getExpForLevel(level);
			uint64_t nextLevelExp = Player::getExpForLevel(level + 1);
			if (nextLevelExp > currLevelExp) {
				levelPercent = Player::getPercentLevel(experience - currLevelExp, nextLevelExp - currLevelExp);
			} else {
				levelPercent = 0;
			}
		}

		if (pvpDeath && hasBlessing(TWIST_OF_FATE)) {
			removeBlessing(TWIST_OF_FATE, 1);
		} else {
			for (int i = BLESS_PVE_FIRST; i <= BLESS_LAST; i++) {
				if (hasBlessing(i))
					removeBlessing(i, 1);
			}
		}

		sendStats();
		sendSkills();
		sendBlessStatus();
		sendReLoginWindow(unfairFightReduction);


		auto it = conditions.begin(), end = conditions.end();
		while (it != end) {
			Condition* condition = *it;
			if (condition->isPersistent()) {
				it = conditions.erase(it);

				condition->endCondition(this);
				onEndCondition(condition->getType());
				delete condition;
			} else {
				++it;
			}
		}

		if (getSkull() == SKULL_BLACK) {
			health = 40;
			mana = 0;
		} else {
			health = healthMax;
			mana = manaMax;
		}


	} else {
		setSkillLoss(true);

		auto it = conditions.begin(), end = conditions.end();
		while (it != end) {
			Condition* condition = *it;
			if (condition->isPersistent()) {
				it = conditions.erase(it);

				condition->endCondition(this);
				onEndCondition(condition->getType());
				delete condition;
			} else {
				++it;
			}
		}

		health = healthMax;
		g_game.internalTeleport(this, getTemplePosition(), true);
		g_game.addCreatureHealth(this);
		onThink(EVENT_CREATURE_THINK_INTERVAL);
		onIdleStatus();
		sendStats();
	}
}

bool Player::dropCorpse(Creature* lastHitCreature, Creature* mostDamageCreature, bool lastHitUnjustified, bool mostDamageUnjustified)
{
	if (getZone() != ZONE_PVP || !Player::lastHitIsPlayer(lastHitCreature)) {
		return Creature::dropCorpse(lastHitCreature, mostDamageCreature, lastHitUnjustified, mostDamageUnjustified);
	}

	setDropLoot(true);
	return false;
}

Item* Player::getCorpse(Creature* lastHitCreature, Creature* mostDamageCreature)
{
	Item* corpse = Creature::getCorpse(lastHitCreature, mostDamageCreature);
	if (corpse && corpse->getContainer()) {
		std::ostringstream ss;
		if (lastHitCreature) {
			ss << "You recognize " << getNameDescription() << ". " << (getSex() == PLAYERSEX_FEMALE ? "She" : "He") << " was killed by " << lastHitCreature->getNameDescription();
			if (mostDamageCreature && mostDamageCreature != lastHitCreature) {
				ss << " and " << mostDamageCreature->getNameDescription();
			}
			ss << '.';
		} else {
			ss << "You recognize " << getNameDescription() << '.';
		}

		corpse->setSpecialDescription(ss.str());
	}
	return corpse;
}

void Player::addInFightTicks(bool pzlock /*= false*/)
{
	if (hasFlag(PlayerFlag_NotGainInFight)) {
		return;
	}

	if (pzlock) {
		pzLocked = true;
		sendIcons();
	}

	Condition* condition = Condition::createCondition(CONDITIONID_DEFAULT, CONDITION_INFIGHT, g_config.getNumber(ConfigManager::PZ_LOCKED), 0);
	addCondition(condition);
}

void Player::removeList()
{
	g_game.removePlayer(this);

	for (const auto& it : g_game.getPlayers()) {
		it.second->notifyStatusChange(this, VIPSTATUS_OFFLINE);
	}
}

void Player::addList()
{
	for (const auto& it : g_game.getPlayers()) {
		it.second->notifyStatusChange(this, VIPSTATUS_ONLINE);
	}

	g_game.addPlayer(this);
}

void Player::kickPlayer(bool displayEffect)
{
	g_creatureEvents->playerLogout(this);
	if (client) {
		client->logout(displayEffect, true);
	} else {
		g_game.removeCreature(this);
	}
}

void Player::notifyStatusChange(Player* loginPlayer, VipStatus_t status)
{
	if (!client) {
		return;
	}

	auto it = VIPList.find(loginPlayer->guid);
	if (it == VIPList.end()) {
		return;
	}

	client->sendUpdatedVIPStatus(loginPlayer->guid, status);

	if (status == VIPSTATUS_ONLINE) {
		client->sendTextMessage(TextMessage(MESSAGE_STATUS_SMALL, loginPlayer->getName() + " has logged in."));
	} else if (status == VIPSTATUS_OFFLINE) {
		client->sendTextMessage(TextMessage(MESSAGE_STATUS_SMALL, loginPlayer->getName() + " has logged out."));
	}
}

bool Player::removeVIP(uint32_t vipGuid)
{
	if (VIPList.erase(vipGuid) == 0) {
		return false;
	}

	IOLoginData::removeVIPEntry(accountNumber, vipGuid);
	return true;
}

bool Player::addVIP(uint32_t vipGuid, const std::string& vipName, VipStatus_t status)
{
	if (VIPList.size() >= getMaxVIPEntries() || VIPList.size() == 200) { // max number of buddies is 200 in 9.53
		sendTextMessage(MESSAGE_STATUS_SMALL, "You cannot add more buddies.");
		return false;
	}

	auto result = VIPList.insert(vipGuid);
	if (!result.second) {
		sendTextMessage(MESSAGE_STATUS_SMALL, "This player is already in your list.");
		return false;
	}

	IOLoginData::addVIPEntry(accountNumber, vipGuid, "", 0, false);
	if (client) {
		client->sendVIP(vipGuid, vipName, "", 0, false, status);
	}
	return true;
}

bool Player::addVIPInternal(uint32_t vipGuid)
{
	if (VIPList.size() >= getMaxVIPEntries() || VIPList.size() == 200) { // max number of buddies is 200 in 9.53
		return false;
	}

	return VIPList.insert(vipGuid).second;
}

bool Player::editVIP(uint32_t vipGuid, const std::string& description, uint32_t icon, bool notify)
{
	auto it = VIPList.find(vipGuid);
	if (it == VIPList.end()) {
		return false; // player is not in VIP
	}

	IOLoginData::editVIPEntry(accountNumber, vipGuid, description, icon, notify);
	return true;
}

//close container and its child containers
void Player::autoCloseContainers(const Container* container)
{
	std::vector<uint32_t> closeList;
	for (const auto& it : openContainers) {
		Container* tmpContainer = it.second.container;
		while (tmpContainer) {
			if (tmpContainer->isRemoved() || tmpContainer == container) {
				closeList.push_back(it.first);
				break;
			}

			tmpContainer = dynamic_cast<Container*>(tmpContainer->getParent());
		}
	}

	for (uint32_t containerId : closeList) {
		closeContainer(containerId);
		if (client) {
			client->sendCloseContainer(containerId);
		}
	}
}

bool Player::hasCapacity(const Item* item, uint32_t count) const
{
	if (hasFlag(PlayerFlag_CannotPickupItem)) {
		return false;
	}

	if (hasFlag(PlayerFlag_HasInfiniteCapacity) || item->getTopParent() == this) {
		return true;
	}

	uint32_t itemWeight = item->getContainer() != nullptr ? item->getWeight() : item->getBaseWeight();
	if (item->isStackable()) {
		itemWeight *= count;
	}
	return itemWeight <= getFreeCapacity();
}

ReturnValue Player::queryAdd(int32_t index, const Thing& thing, uint32_t count, uint32_t flags, Creature*) const
{
	const Item* item = thing.getItem();
	if (item == nullptr) {
		return RETURNVALUE_NOTPOSSIBLE;
	}

	bool childIsOwner = hasBitSet(FLAG_CHILDISOWNER, flags);
	if (childIsOwner) {
		//a child container is querying the player, just check if enough capacity
		bool skipLimit = hasBitSet(FLAG_NOLIMIT, flags);
		if (skipLimit || hasCapacity(item, count)) {
			return RETURNVALUE_NOERROR;
		}
		return RETURNVALUE_NOTENOUGHCAPACITY;
	}

	if (!item->isPickupable()) {
		return RETURNVALUE_CANNOTPICKUP;
	}

	ReturnValue ret = RETURNVALUE_NOERROR;

	const int32_t& slotPosition = item->getSlotPosition();
	if ((slotPosition & SLOTP_HEAD) || (slotPosition & SLOTP_NECKLACE) ||
			(slotPosition & SLOTP_BACKPACK) || (slotPosition & SLOTP_ARMOR) ||
			(slotPosition & SLOTP_LEGS) || (slotPosition & SLOTP_FEET) ||
			(slotPosition & SLOTP_RING)) {
		ret = RETURNVALUE_CANNOTBEDRESSED;
	} else if (slotPosition & SLOTP_TWO_HAND) {
		ret = RETURNVALUE_PUTTHISOBJECTINBOTHHANDS;
	} else if ((slotPosition & SLOTP_RIGHT) || (slotPosition & SLOTP_LEFT)) {
		if (!g_config.getBoolean(ConfigManager::CLASSIC_EQUIPMENT_SLOTS)) {
			ret = RETURNVALUE_CANNOTBEDRESSED;
		} else {
			ret = RETURNVALUE_PUTTHISOBJECTINYOURHAND;
		}
	}

	switch (index) {
		case CONST_SLOT_HEAD: {
			if (slotPosition & SLOTP_HEAD) {
				ret = RETURNVALUE_NOERROR;
			}
			break;
		}

		case CONST_SLOT_NECKLACE: {
			if (slotPosition & SLOTP_NECKLACE) {
				ret = RETURNVALUE_NOERROR;
			}
			break;
		}

		case CONST_SLOT_BACKPACK: {
			if (slotPosition & SLOTP_BACKPACK) {
				ret = RETURNVALUE_NOERROR;
			}
			break;
		}

		case CONST_SLOT_ARMOR: {
			if (slotPosition & SLOTP_ARMOR) {
				ret = RETURNVALUE_NOERROR;
			}
			break;
		}

		case CONST_SLOT_RIGHT: {
			if (slotPosition & SLOTP_RIGHT) {
				if (!g_config.getBoolean(ConfigManager::CLASSIC_EQUIPMENT_SLOTS)) {
					if (item->getWeaponType() != WEAPON_SHIELD && item->getWeaponType() != WEAPON_QUIVER) {
                    ret = RETURNVALUE_CANNOTBEDRESSED;
          }
          else {
            const Item* leftItem = inventory[CONST_SLOT_LEFT];
            if (leftItem) {
              if ((leftItem->getSlotPosition() | slotPosition) & SLOTP_TWO_HAND) {
                if (item->getWeaponType() == WEAPON_QUIVER && leftItem->getWeaponType() == WEAPON_DISTANCE)
                  ret = RETURNVALUE_NOERROR;
                else
                  ret = RETURNVALUE_BOTHHANDSNEEDTOBEFREE;
              }
              else {
                ret = RETURNVALUE_NOERROR;
              }
            }
            else {
              ret = RETURNVALUE_NOERROR;
            }
          }

				} else if (slotPosition & SLOTP_TWO_HAND) {
					if (inventory[CONST_SLOT_LEFT] && inventory[CONST_SLOT_LEFT] != item) {
						ret = RETURNVALUE_BOTHHANDSNEEDTOBEFREE;
					} else {
						ret = RETURNVALUE_NOERROR;
					}
				} else if (inventory[CONST_SLOT_LEFT]) {
					const Item* leftItem = inventory[CONST_SLOT_LEFT];
					WeaponType_t type = item->getWeaponType(), leftType = leftItem->getWeaponType();

					if (leftItem->getSlotPosition() & SLOTP_TWO_HAND) {
						ret = RETURNVALUE_DROPTWOHANDEDITEM;
					} else if (item == leftItem && count == item->getItemCount()) {
						ret = RETURNVALUE_NOERROR;
					} else if (leftType == WEAPON_SHIELD && type == WEAPON_SHIELD) {
						ret = RETURNVALUE_CANONLYUSEONESHIELD;
					} else if (leftType == WEAPON_NONE || type == WEAPON_NONE ||
							   leftType == WEAPON_SHIELD || leftType == WEAPON_AMMO
							   || type == WEAPON_SHIELD || type == WEAPON_AMMO) {
						ret = RETURNVALUE_NOERROR;
					} else {
						ret = RETURNVALUE_CANONLYUSEONEWEAPON;
					}
				} else {
					ret = RETURNVALUE_NOERROR;
				}
			}
			break;
		}

		case CONST_SLOT_LEFT: {
			if (slotPosition & SLOTP_LEFT) {
				if (!g_config.getBoolean(ConfigManager::CLASSIC_EQUIPMENT_SLOTS)) {
					WeaponType_t type = item->getWeaponType();
					if (type == WEAPON_NONE || type == WEAPON_SHIELD || type == WEAPON_AMMO) {
						ret = RETURNVALUE_CANNOTBEDRESSED;
					} else if (inventory[CONST_SLOT_RIGHT] && (slotPosition & SLOTP_TWO_HAND)) {
						if (type == WEAPON_DISTANCE && inventory[CONST_SLOT_RIGHT]->getWeaponType() == WEAPON_QUIVER) {
							ret = RETURNVALUE_NOERROR;
						}
						else {
							ret = RETURNVALUE_BOTHHANDSNEEDTOBEFREE;
						}
					} else {
						ret = RETURNVALUE_NOERROR;
					}
				} else if (slotPosition & SLOTP_TWO_HAND) {
					if (inventory[CONST_SLOT_RIGHT] && inventory[CONST_SLOT_RIGHT] != item) {
						ret = RETURNVALUE_BOTHHANDSNEEDTOBEFREE;
					} else {
						ret = RETURNVALUE_NOERROR;
					}
				} else if (inventory[CONST_SLOT_RIGHT]) {
					const Item* rightItem = inventory[CONST_SLOT_RIGHT];
					WeaponType_t type = item->getWeaponType(), rightType = rightItem->getWeaponType();

					if (rightItem->getSlotPosition() & SLOTP_TWO_HAND) {
						ret = RETURNVALUE_DROPTWOHANDEDITEM;
					} else if (item == rightItem && count == item->getItemCount()) {
						ret = RETURNVALUE_NOERROR;
					} else if (rightType == WEAPON_SHIELD && type == WEAPON_SHIELD) {
						ret = RETURNVALUE_CANONLYUSEONESHIELD;
					} else if (rightType == WEAPON_NONE || type == WEAPON_NONE ||
							   rightType == WEAPON_SHIELD || rightType == WEAPON_AMMO
							   || type == WEAPON_SHIELD || type == WEAPON_AMMO) {
						ret = RETURNVALUE_NOERROR;
					} else {
						ret = RETURNVALUE_CANONLYUSEONEWEAPON;
					}
				} else {
					ret = RETURNVALUE_NOERROR;
				}
			}
			break;
		}

		case CONST_SLOT_LEGS: {
			if (slotPosition & SLOTP_LEGS) {
				ret = RETURNVALUE_NOERROR;
			}
			break;
		}

		case CONST_SLOT_FEET: {
			if (slotPosition & SLOTP_FEET) {
				ret = RETURNVALUE_NOERROR;
			}
			break;
		}

		case CONST_SLOT_RING: {
			if (slotPosition & SLOTP_RING) {
				ret = RETURNVALUE_NOERROR;
			}
			break;
		}

		case CONST_SLOT_AMMO: {
			if ((slotPosition & SLOTP_AMMO) || g_config.getBoolean(ConfigManager::CLASSIC_EQUIPMENT_SLOTS)) {
				ret = RETURNVALUE_NOERROR;
			}
			break;
		}

		case CONST_SLOT_WHEREEVER:
		case -1:
			ret = RETURNVALUE_NOTENOUGHROOM;
			break;

		default:
			ret = RETURNVALUE_NOTPOSSIBLE;
			break;
	}

	if (ret != RETURNVALUE_NOERROR && ret != RETURNVALUE_NOTENOUGHROOM) {
		return ret;
	}

	//check if enough capacity
	if (!hasCapacity(item, count)) {
		return RETURNVALUE_NOTENOUGHCAPACITY;
	}

	ret = g_moveEvents->onPlayerEquip(const_cast<Player*>(this), const_cast<Item*>(item), static_cast<slots_t>(index), true);
	if (ret != RETURNVALUE_NOERROR) {
		return ret;
	}

	//need an exchange with source? (destination item is swapped with currently moved item)
	const Item* inventoryItem = getInventoryItem(static_cast<slots_t>(index));
	if (inventoryItem && (!inventoryItem->isStackable() || inventoryItem->getID() != item->getID())) {
		const Cylinder* cylinder = item->getTopParent();
		if (cylinder && (dynamic_cast<const DepotChest*>(cylinder) || dynamic_cast<const Player*>(cylinder))) {
			return RETURNVALUE_NEEDEXCHANGE;
		}

		return RETURNVALUE_NOTENOUGHROOM;
	}

	return ret;
}

ReturnValue Player::queryMaxCount(int32_t index, const Thing& thing, uint32_t count, uint32_t& maxQueryCount,
		uint32_t flags) const
{
	const Item* item = thing.getItem();
	if (item == nullptr) {
		maxQueryCount = 0;
		return RETURNVALUE_NOTPOSSIBLE;
	}

	if (index == INDEX_WHEREEVER) {
		uint32_t n = 0;
		for (int32_t slotIndex = CONST_SLOT_FIRST; slotIndex <= CONST_SLOT_LAST; ++slotIndex) {
			Item* inventoryItem = inventory[slotIndex];
			if (inventoryItem) {
				if (Container* subContainer = inventoryItem->getContainer()) {
					uint32_t queryCount = 0;
					subContainer->queryMaxCount(INDEX_WHEREEVER, *item, item->getItemCount(), queryCount, flags);
					n += queryCount;

					//iterate through all items, including sub-containers (deep search)
					for (ContainerIterator it = subContainer->iterator(); it.hasNext(); it.advance()) {
						if (Container* tmpContainer = (*it)->getContainer()) {
							queryCount = 0;
							tmpContainer->queryMaxCount(INDEX_WHEREEVER, *item, item->getItemCount(), queryCount, flags);
							n += queryCount;
						}
					}
				} else if (inventoryItem->isStackable() && item->equals(inventoryItem) && inventoryItem->getItemCount() < 100) {
					uint32_t remainder = (100 - inventoryItem->getItemCount());

					if (queryAdd(slotIndex, *item, remainder, flags) == RETURNVALUE_NOERROR) {
						n += remainder;
					}
				}
			} else if (queryAdd(slotIndex, *item, item->getItemCount(), flags) == RETURNVALUE_NOERROR) { //empty slot
				if (item->isStackable()) {
					n += 100;
				} else {
					++n;
				}
			}
		}

		maxQueryCount = n;
	} else {
		const Item* destItem = nullptr;

		const Thing* destThing = getThing(index);
		if (destThing) {
			destItem = destThing->getItem();
		}

		if (destItem) {
			if (destItem->isStackable() && item->equals(destItem) && destItem->getItemCount() < 100) {
				maxQueryCount = 100 - destItem->getItemCount();
			} else {
				maxQueryCount = 0;
			}
		} else if (queryAdd(index, *item, count, flags) == RETURNVALUE_NOERROR) { //empty slot
			if (item->isStackable()) {
				maxQueryCount = 100;
			} else {
				maxQueryCount = 1;
			}

			return RETURNVALUE_NOERROR;
		}
	}

	if (maxQueryCount < count) {
		return RETURNVALUE_NOTENOUGHROOM;
	} else {
		return RETURNVALUE_NOERROR;
	}
}

ReturnValue Player::queryRemove(const Thing& thing, uint32_t count, uint32_t flags) const
{
	int32_t index = getThingIndex(&thing);
	if (index == -1) {
		return RETURNVALUE_NOTPOSSIBLE;
	}

	const Item* item = thing.getItem();
	if (item == nullptr) {
		return RETURNVALUE_NOTPOSSIBLE;
	}

	if (count == 0 || (item->isStackable() && count > item->getItemCount())) {
		return RETURNVALUE_NOTPOSSIBLE;
	}

	if (!item->isMoveable() && !hasBitSet(FLAG_IGNORENOTMOVEABLE, flags)) {
		return RETURNVALUE_NOTMOVEABLE;
	}

	return RETURNVALUE_NOERROR;
}

Cylinder* Player::queryDestination(int32_t& index, const Thing& thing, Item** destItem,
		uint32_t& flags)
{
	if (index == 0 /*drop to capacity window*/ || index == INDEX_WHEREEVER) {
		*destItem = nullptr;

		const Item* item = thing.getItem();
		if (item == nullptr) {
			return this;
		}

		bool autoStack = !((flags & FLAG_IGNOREAUTOSTACK) == FLAG_IGNOREAUTOSTACK);
		bool isStackable = item->isStackable();

		std::vector<Container*> containers;

		for (uint32_t slotIndex = CONST_SLOT_FIRST; slotIndex <= CONST_SLOT_AMMO; ++slotIndex) {
			Item* inventoryItem = inventory[slotIndex];
			if (inventoryItem) {
				if (inventoryItem == tradeItem) {
					continue;
				}

				if (inventoryItem == item) {
					continue;
				}

				if (autoStack && isStackable) {
					//try find an already existing item to stack with
					if (queryAdd(slotIndex, *item, item->getItemCount(), 0) == RETURNVALUE_NOERROR) {
						if (inventoryItem->equals(item) && inventoryItem->getItemCount() < 100) {
							index = slotIndex;
							*destItem = inventoryItem;
							return this;
						}
					}

					if (Container* subContainer = inventoryItem->getContainer()) {
						containers.push_back(subContainer);
					}
				} else if (Container* subContainer = inventoryItem->getContainer()) {
					containers.push_back(subContainer);
				}
			} else if (queryAdd(slotIndex, *item, item->getItemCount(), flags) == RETURNVALUE_NOERROR) { //empty slot
				index = slotIndex;
				*destItem = nullptr;
				return this;
			}
		}

		size_t i = 0;
		while (i < containers.size()) {
			Container* tmpContainer = containers[i++];
			if (!autoStack || !isStackable) {
				//we need to find first empty container as fast as we can for non-stackable items
				uint32_t n = tmpContainer->capacity() - tmpContainer->size();
				while (n) {
					if (tmpContainer->queryAdd(tmpContainer->capacity() - n, *item, item->getItemCount(), flags) == RETURNVALUE_NOERROR) {
						index = tmpContainer->capacity() - n;
						*destItem = nullptr;
						return tmpContainer;
					}

					n--;
				}

				for (Item* tmpContainerItem : tmpContainer->getItemList()) {
					if (Container* subContainer = tmpContainerItem->getContainer()) {
						containers.push_back(subContainer);
					}
				}

				continue;
			}

			uint32_t n = 0;

			for (Item* tmpItem : tmpContainer->getItemList()) {
				if (tmpItem == tradeItem) {
					continue;
				}

				if (tmpItem == item) {
					continue;
				}

				//try find an already existing item to stack with
				if (tmpItem->equals(item) && tmpItem->getItemCount() < 100) {
					index = n;
					*destItem = tmpItem;
					return tmpContainer;
				}

				if (Container* subContainer = tmpItem->getContainer()) {
					containers.push_back(subContainer);
				}

				n++;
			}

			if (n < tmpContainer->capacity() && tmpContainer->queryAdd(n, *item, item->getItemCount(), flags) == RETURNVALUE_NOERROR) {
				index = n;
				*destItem = nullptr;
				return tmpContainer;
			}
		}

		return this;
	}

	Thing* destThing = getThing(index);
	if (destThing) {
		*destItem = destThing->getItem();
	}

	Cylinder* subCylinder = dynamic_cast<Cylinder*>(destThing);
	if (subCylinder) {
		index = INDEX_WHEREEVER;
		*destItem = nullptr;
		return subCylinder;
	} else {
		return this;
	}
}

void Player::addThing(int32_t index, Thing* thing)
{
	if (index < CONST_SLOT_FIRST || index > CONST_SLOT_LAST) {
		return /*RETURNVALUE_NOTPOSSIBLE*/;
	}

	Item* item = thing->getItem();
	if (!item) {
		return /*RETURNVALUE_NOTPOSSIBLE*/;
	}

	item->setParent(this);
	inventory[index] = item;

	//send to client
	sendInventoryItem(static_cast<slots_t>(index), item);
}

void Player::updateThing(Thing* thing, uint16_t itemId, uint32_t count)
{
	int32_t index = getThingIndex(thing);
	if (index == -1) {
		return /*RETURNVALUE_NOTPOSSIBLE*/;
	}

	Item* item = thing->getItem();
	if (!item) {
		return /*RETURNVALUE_NOTPOSSIBLE*/;
	}

	item->setID(itemId);
	item->setSubType(count);

	//send to client
	sendInventoryItem(static_cast<slots_t>(index), item);

	//event methods
	onUpdateInventoryItem(item, item);
}

void Player::replaceThing(uint32_t index, Thing* thing)
{
	if (index > CONST_SLOT_LAST) {
		return /*RETURNVALUE_NOTPOSSIBLE*/;
	}

	Item* oldItem = getInventoryItem(static_cast<slots_t>(index));
	if (!oldItem) {
		return /*RETURNVALUE_NOTPOSSIBLE*/;
	}

	Item* item = thing->getItem();
	if (!item) {
		return /*RETURNVALUE_NOTPOSSIBLE*/;
	}

	//send to client
	sendInventoryItem(static_cast<slots_t>(index), item);

	//event methods
	onUpdateInventoryItem(oldItem, item);

	item->setParent(this);

	inventory[index] = item;
}

void Player::removeThing(Thing* thing, uint32_t count)
{
	Item* item = thing->getItem();
	if (!item) {
		return /*RETURNVALUE_NOTPOSSIBLE*/;
	}

	int32_t index = getThingIndex(thing);
	if (index == -1) {
		return /*RETURNVALUE_NOTPOSSIBLE*/;
	}

	if (item->isStackable()) {
		if (count == item->getItemCount()) {
			//send change to client
			sendInventoryItem(static_cast<slots_t>(index), nullptr);

			//event methods
			onRemoveInventoryItem(item);

			item->setParent(nullptr);
			inventory[index] = nullptr;
		} else {
			uint8_t newCount = static_cast<uint8_t>(std::max<int32_t>(0, item->getItemCount() - count));
			item->setItemCount(newCount);

			//send change to client
			sendInventoryItem(static_cast<slots_t>(index), item);

			//event methods
			onUpdateInventoryItem(item, item);
		}
	} else {
		//send change to client
		sendInventoryItem(static_cast<slots_t>(index), nullptr);

		//event methods
		onRemoveInventoryItem(item);

		item->setParent(nullptr);
		inventory[index] = nullptr;
	}
}

int32_t Player::getThingIndex(const Thing* thing) const
{
	for (int i = CONST_SLOT_FIRST; i <= CONST_SLOT_LAST; ++i) {
		if (inventory[i] == thing) {
			return i;
		}
	}
	return -1;
}

size_t Player::getFirstIndex() const
{
	return CONST_SLOT_FIRST;
}

size_t Player::getLastIndex() const
{
	return CONST_SLOT_LAST + 1;
}

uint32_t Player::getItemTypeCount(uint16_t itemId, int32_t subType /*= -1*/) const
{
	uint32_t count = 0;
	for (int32_t i = CONST_SLOT_FIRST; i <= CONST_SLOT_LAST; i++) {
		Item* item = inventory[i];
		if (!item) {
			continue;
		}

		if (item->getID() == itemId) {
			count += Item::countByType(item, subType);
		}

		if (Container* container = item->getContainer()) {
			for (ContainerIterator it = container->iterator(); it.hasNext(); it.advance()) {
				if ((*it)->getID() == itemId) {
					count += Item::countByType(*it, subType);
				}
			}
		}
	}
	return count;
}

bool Player::removeItemOfType(uint16_t itemId, uint32_t amount, int32_t subType, bool ignoreEquipped/* = false*/) const
{
	if (amount == 0) {
		return true;
	}

	std::vector<Item*> itemList;

	uint32_t count = 0;
	for (int32_t i = CONST_SLOT_FIRST; i <= CONST_SLOT_LAST; i++) {
		Item* item = inventory[i];
		if (!item) {
			continue;
		}

		if (!ignoreEquipped && item->getID() == itemId) {
			uint32_t itemCount = Item::countByType(item, subType);
			if (itemCount == 0) {
				continue;
			}

			itemList.push_back(item);

			count += itemCount;
			if (count >= amount) {
				g_game.internalRemoveItems(std::move(itemList), amount, Item::items[itemId].stackable);
				return true;
			}
		} else if (Container* container = item->getContainer()) {
			for (ContainerIterator it = container->iterator(); it.hasNext(); it.advance()) {
				Item* containerItem = *it;
				if (containerItem->getID() == itemId) {
					uint32_t itemCount = Item::countByType(containerItem, subType);
					if (itemCount == 0) {
						continue;
					}

					itemList.push_back(containerItem);

					count += itemCount;
					if (count >= amount) {
						g_game.internalRemoveItems(std::move(itemList), amount, Item::items[itemId].stackable);
						return true;
					}
				}
			}
		}
	}
	return false;
}

std::map<uint32_t, uint32_t>& Player::getAllItemTypeCount(std::map<uint32_t, uint32_t>& countMap) const
{
	for (int32_t i = CONST_SLOT_FIRST; i <= CONST_SLOT_LAST; i++) {
		Item* item = inventory[i];
		if (!item) {
			continue;
		}

		countMap[item->getID()] += Item::countByType(item, -1);

		if (Container* container = item->getContainer()) {
			for (ContainerIterator it = container->iterator(); it.hasNext(); it.advance()) {
				countMap[(*it)->getID()] += Item::countByType(*it, -1);
			}
		}
	}
	return countMap;
}

Item* Player::getItemByClientId(uint16_t clientId) const
{
	for (int32_t i = CONST_SLOT_FIRST; i <= CONST_SLOT_LAST; i++) {
		Item* item = inventory[i];
		if (!item) {
			continue;
		}

		if (item->getClientID() == clientId) {
			return item;
		}

		if (Container* container = item->getContainer()) {
			for (ContainerIterator it = container->iterator(); it.hasNext(); it.advance()) {
				if ((*it)->getClientID() == clientId) {
					return (*it);
				}
			}
		}
	}
	return nullptr;
}

std::map<uint16_t, uint16_t> Player::getInventoryClientIds() const
{
	std::map<uint16_t, uint16_t> itemMap;
	for (int32_t i = CONST_SLOT_FIRST; i <= CONST_SLOT_LAST; i++) {
		Item* item = inventory[i];
		if (!item) {
			continue;
		}

		auto rootSearch = itemMap.find(item->getClientID());
		if (rootSearch != itemMap.end()) {
			itemMap[item->getClientID()] = itemMap[item->getClientID()] + Item::countByType(item, -1);
		} else {
			itemMap.emplace(item->getClientID(), Item::countByType(item, -1));
		}

		const ItemType& itemType = Item::items[item->getID()];
		if (itemType.transformEquipTo) {
			itemMap.emplace(Item::items[itemType.transformEquipTo].clientId, 0);
		}

		if (itemType.transformDeEquipTo) {
			itemMap.emplace(Item::items[itemType.transformDeEquipTo].clientId, 0);
		}

		if (Container* container = item->getContainer()) {
			for (ContainerIterator it = container->iterator(); it.hasNext(); it.advance()) {
				auto containerSearch = itemMap.find((*it)->getClientID());
				if (containerSearch != itemMap.end()) {
					itemMap[(*it)->getClientID()] = itemMap[(*it)->getClientID()] + Item::countByType(*it, -1);
				} else {
					itemMap.emplace((*it)->getClientID(), Item::countByType(*it, -1));
				}

				const ItemType& itItemType = Item::items[(*it)->getID()];
				if (itItemType.transformEquipTo) {
					itemMap.emplace(Item::items[itItemType.transformEquipTo].clientId, 0);
				}

				if (itItemType.transformDeEquipTo) {
					itemMap.emplace(Item::items[itItemType.transformDeEquipTo].clientId, 0);
				}
			}
		}
	}
	return itemMap;
}

Thing* Player::getThing(size_t index) const
{
	if (index >= CONST_SLOT_FIRST && index <= CONST_SLOT_LAST) {
		return inventory[index];
	}
	return nullptr;
}

void Player::postAddNotification(Thing* thing, const Cylinder* oldParent, int32_t index, cylinderlink_t link /*= LINK_OWNER*/)
{
	if (link == LINK_OWNER) {
		//calling movement scripts
		g_moveEvents->onPlayerEquip(this, thing->getItem(), static_cast<slots_t>(index), false);
	}

	bool requireListUpdate = true;

	if (link == LINK_OWNER || link == LINK_TOPPARENT) {
		const Item* i = (oldParent ? oldParent->getItem() : nullptr);

		// Check if we owned the old container too, so we don't need to do anything,
		// as the list was updated in postRemoveNotification
		assert(i ? i->getContainer() != nullptr : true);

		if (i) {
		// 	requireListUpdate = i->getContainer()->getHoldingPlayer() != this;
		// } else {
		// 	requireListUpdate = oldParent != this;
		}

		updateInventoryWeight();
		updateItemsLight();
		sendInventoryClientIds();
		sendStats();
	}

	if (const Item* item = thing->getItem()) {
		if (const Container* container = item->getContainer()) {
			onSendContainer(container);
		}

		if (client && shopOwner && requireListUpdate) {
			updateSaleShopList(item);
		}
	} else if (const Creature* creature = thing->getCreature()) {
		if (creature == this) {
			//check containers
			std::vector<Container*> containers;

			for (const auto& it : openContainers) {
				Container* container = it.second.container;
				if (!Position::areInRange<1, 1, 0>(container->getPosition(), getPosition())) {
					containers.push_back(container);
				}
			}

			for (const Container* container : containers) {
				autoCloseContainers(container);
			}
		}
	}
}

void Player::postRemoveNotification(Thing* thing, const Cylinder* newParent, int32_t index, cylinderlink_t link /*= LINK_OWNER*/)
{
	if (link == LINK_OWNER) {
		//calling movement scripts
		g_moveEvents->onPlayerDeEquip(this, thing->getItem(), static_cast<slots_t>(index));
	}

	bool requireListUpdate = true;

	if (link == LINK_OWNER || link == LINK_TOPPARENT) {
		const Item* i = (newParent ? newParent->getItem() : nullptr);

		// Check if we owned the old container too, so we don't need to do anything,
		// as the list was updated in postRemoveNotification
		assert(i ? i->getContainer() != nullptr : true);

		if (i) {
		// 	requireListUpdate = i->getContainer()->getHoldingPlayer() != this;
		// } else {
		// 	requireListUpdate = newParent != this;
		}

		updateInventoryWeight();
		updateItemsLight();
		sendInventoryClientIds();
		sendStats();
	}

	if (const Item* item = thing->getItem()) {
		if (const Container* container = item->getContainer()) {
			checkLootContainers(container);

			if (container->isRemoved() || !Position::areInRange<1, 1, 0>(getPosition(), container->getPosition())) {
				autoCloseContainers(container);
			} else if (container->getTopParent() == this) {
				onSendContainer(container);
			} else if (const Container* topContainer = dynamic_cast<const Container*>(container->getTopParent())) {
				if (const DepotChest* depotChest = dynamic_cast<const DepotChest*>(topContainer)) {
					bool isOwner = false;

					for (const auto& it : depotChests) {
						if (it.second == depotChest) {
							isOwner = true;
							onSendContainer(container);
						}
					}

					if (!isOwner) {
						autoCloseContainers(container);
					}
					
					} else if (const Inbox* inboxContainer = dynamic_cast<const Inbox*>(topContainer)) {
					if (inboxContainer == inbox) {
						onSendContainer(container);
					} else {
						autoCloseContainers(container);
					}
					
				} else {
					onSendContainer(container);
				}
			} else {
				autoCloseContainers(container);
			}
		}

		if (shopOwner && requireListUpdate) {
			updateSaleShopList(item);
		}
	}
}

bool Player::updateSaleShopList(const Item* item)
{
	uint16_t itemId = item->getID();
	if (itemId != ITEM_GOLD_COIN && itemId != ITEM_PLATINUM_COIN && itemId != ITEM_CRYSTAL_COIN) {
		auto it = std::find_if(shopItemList.begin(), shopItemList.end(), [itemId](const ShopInfo& shopInfo) { return shopInfo.itemId == itemId && shopInfo.sellPrice != 0; });
		if (it == shopItemList.end()) {
			const Container* container = item->getContainer();
			if (!container) {
				return false;
			}

			const auto& items = container->getItemList();
			return std::any_of(items.begin(), items.end(), [this](const Item* containerItem) {
				return updateSaleShopList(containerItem);
			});
		}
	}

	if (updatingSaleItemList) {
		return true;
	}
	g_dispatcher.addTask(createTask(std::bind(&Game::playerSendSaleItemList, &g_game, getID())));

	updatingSaleItemList = true;
	return true;
}


bool Player::hasShopItemForSale(uint32_t itemId, uint8_t subType) const
{
	const ItemType& itemType = Item::items[itemId];
	return std::any_of(shopItemList.begin(), shopItemList.end(), [&](const ShopInfo& shopInfo) {
		return shopInfo.itemId == itemId && shopInfo.buyPrice != 0 && (!itemType.isFluidContainer() || shopInfo.subType == subType);
	});
}

void Player::internalAddThing(Thing* thing)
{
	internalAddThing(0, thing);
}

void Player::internalAddThing(uint32_t index, Thing* thing)
{
	Item* item = thing->getItem();
	if (!item) {
		return;
	}

	//index == 0 means we should equip this item at the most appropiate slot (no action required here)
	if (index > 0 && index < 12) {
		if (inventory[index]) {
			return;
		}

		inventory[index] = item;
		item->setParent(this);
	}
}

bool Player::setFollowCreature(Creature* creature)
{
	if (!Creature::setFollowCreature(creature)) {
		setFollowCreature(nullptr);
		setAttackedCreature(nullptr);

		sendCancelMessage(RETURNVALUE_THEREISNOWAY);
		sendCancelTarget();
		stopWalk();
		return false;
	}
	return true;
}

bool Player::setAttackedCreature(Creature* creature)
{
	if (!Creature::setAttackedCreature(creature)) {
		sendCancelTarget();
		return false;
	}

	if (chaseMode && creature) {
		if (followCreature != creature) {
			//chase opponent
			setFollowCreature(creature);
		}
	} else if (followCreature) {
		setFollowCreature(nullptr);
	}

	if (creature) {
		g_dispatcher.addTask(createTask(std::bind(&Game::checkCreatureAttack, &g_game, getID())));
	}
	return true;
}

void Player::goToFollowCreature()
{
	if (!walkTask) {
		if ((OTSYS_TIME() - lastFailedFollow) < 2000) {
			return;
		}

		Creature::goToFollowCreature();

		if (followCreature && !hasFollowPath) {
			lastFailedFollow = OTSYS_TIME();
		}
	}
}

void Player::getPathSearchParams(const Creature* creature, FindPathParams& fpp) const
{
	Creature::getPathSearchParams(creature, fpp);
	fpp.fullPathSearch = true;
}

void Player::doAttacking(uint32_t)
{
	if (lastAttack == 0) {
		lastAttack = OTSYS_TIME() - getAttackSpeed() - 1;
	}

	if (hasCondition(CONDITION_PACIFIED)) {
		return;
	}

	if ((OTSYS_TIME() - lastAttack) >= getAttackSpeed()) {
		bool result = false;

		Item* tool = getWeapon();
		const Weapon* weapon = g_weapons->getWeapon(tool);
		uint32_t delay = getAttackSpeed();
		bool classicSpeed = g_config.getBoolean(ConfigManager::CLASSIC_ATTACK_SPEED);

		if (weapon) {
			if (!weapon->interruptSwing()) {
				result = weapon->useWeapon(this, tool, attackedCreature);
			} else if (!classicSpeed && !canDoAction()) {
				delay = getNextActionTime();
			} else {
				result = weapon->useWeapon(this, tool, attackedCreature);
			}
		} else {
			result = Weapon::useFist(this, attackedCreature);
		}

		SchedulerTask* task = createSchedulerTask(std::max<uint32_t>(SCHEDULER_MINTICKS, delay), std::bind(&Game::checkCreatureAttack, &g_game, getID()));
		if (!classicSpeed) {
			setNextActionTask(task);
		} else {
			g_scheduler.addEvent(task);
		}

		if (result) {
			lastAttack = OTSYS_TIME();
		}
	}
}

uint64_t Player::getGainedExperience(Creature* attacker) const
{
	if (g_config.getBoolean(ConfigManager::EXPERIENCE_FROM_PLAYERS)) {
		Player* attackerPlayer = attacker->getPlayer();
		if (attackerPlayer && attackerPlayer != this && skillLoss && std::abs(static_cast<int32_t>(attackerPlayer->getLevel() - level)) <= g_config.getNumber(ConfigManager::EXP_FROM_PLAYERS_LEVEL_RANGE)) {
			return std::max<uint64_t>(0, std::floor(getLostExperience() * getDamageRatio(attacker) * 0.75));
		}
	}
	return 0;
}

void Player::onFollowCreature(const Creature* creature)
{
	if (!creature) {
		stopWalk();
	}
}

void Player::setChaseMode(bool mode)
{
	bool prevChaseMode = chaseMode;
	chaseMode = mode;

	if (prevChaseMode != chaseMode) {
		if (chaseMode) {
			if (!followCreature && attackedCreature) {
				//chase opponent
				setFollowCreature(attackedCreature);
			}
		} else if (attackedCreature) {
			setFollowCreature(nullptr);
			cancelNextWalk = true;
		}
	}
}

void Player::onWalkAborted()
{
	setNextWalkActionTask(nullptr);
	sendCancelWalk();
}

void Player::onWalkComplete()
{
	if (walkTask) {
		walkTaskEvent = g_scheduler.addEvent(walkTask);
		walkTask = nullptr;
	}
}

void Player::stopWalk()
{
	cancelNextWalk = true;
}

LightInfo Player::getCreatureLight() const
{
	if (internalLight.level > itemsLight.level) {
		return internalLight;
	}
	return itemsLight;
}

void Player::updateItemsLight(bool internal /*=false*/)
{
	LightInfo maxLight;

	for (int32_t i = CONST_SLOT_FIRST; i <= CONST_SLOT_LAST; ++i) {
		Item* item = inventory[i];
		if (item) {
			LightInfo curLight = item->getLightInfo();

			if (curLight.level > maxLight.level) {
				maxLight = std::move(curLight);
			}
		}
	}

	if (itemsLight.level != maxLight.level || itemsLight.color != maxLight.color) {
		itemsLight = maxLight;

		if (!internal) {
			g_game.changeLight(this);
		}
	}
}

void Player::onAddCondition(ConditionType_t type)
{
	Creature::onAddCondition(type);

	if (type == CONDITION_OUTFIT && isMounted()) {
		dismount();
	}

	sendIcons();
}

void Player::onAddCombatCondition(ConditionType_t type)
{
	switch (type) {
		case CONDITION_POISON:
			sendTextMessage(MESSAGE_STATUS_DEFAULT, "You are poisoned.");
			break;

		case CONDITION_DROWN:
			sendTextMessage(MESSAGE_STATUS_DEFAULT, "You are drowning.");
			break;

		case CONDITION_PARALYZE:
			sendTextMessage(MESSAGE_STATUS_DEFAULT, "You are paralyzed.");
			break;

		case CONDITION_DRUNK:
			sendTextMessage(MESSAGE_STATUS_DEFAULT, "You are drunk.");
			break;

		case CONDITION_CURSED:
			sendTextMessage(MESSAGE_STATUS_DEFAULT, "You are cursed.");
			break;

		case CONDITION_FREEZING:
			sendTextMessage(MESSAGE_STATUS_DEFAULT, "You are freezing.");
			break;

		case CONDITION_DAZZLED:
			sendTextMessage(MESSAGE_STATUS_DEFAULT, "You are dazzled.");
			break;

		case CONDITION_BLEEDING:
			sendTextMessage(MESSAGE_STATUS_DEFAULT, "You are bleeding.");
			break;

		default:
			break;
	}
}

void Player::onEndCondition(ConditionType_t type)
{
	Creature::onEndCondition(type);

	if (type == CONDITION_INFIGHT) {
		onIdleStatus();
		pzLocked = false;
		setPvpSituation(false);
		clearAttacked();
		
		if (g_game.isExpertPvpEnabled()) {
			g_game.updateSpectatorsPvp(this);
		}

		if (getSkull() != SKULL_RED && getSkull() != SKULL_BLACK) {
			setSkull(SKULL_NONE);
		}
	}

	sendIcons();
}

void Player::onCombatRemoveCondition(Condition* condition)
{
	//Creature::onCombatRemoveCondition(condition);
	if (condition->getId() > 0) {
		//Means the condition is from an item, id == slot
		if (g_game.getWorldType() == WORLD_TYPE_PVP_ENFORCED) {
			Item* item = getInventoryItem(static_cast<slots_t>(condition->getId()));
			if (item) {
				//25% chance to destroy the item
				if (25 >= uniform_random(1, 100)) {
					g_game.internalRemoveItem(item);
				}
			}
		}
	} else {
		if (!canDoAction()) {
			const uint32_t delay = getNextActionTime();
			const int32_t ticks = delay - (delay % EVENT_CREATURE_THINK_INTERVAL);
			if (ticks < 0) {
				removeCondition(condition);
			} else {
				condition->setTicks(ticks);
			}
		} else {
			removeCondition(condition);
		}
	}
}

void Player::onAttackedCreature(Creature* target, bool addFightTicks /* = true */)
{
	Creature::onAttackedCreature(target);

	if (target->getZone() == ZONE_PVP) {
		return;
	}

	if (target == this) {
		if (addFightTicks) {
			addInFightTicks();
		}
		return;
	}

	if (hasFlag(PlayerFlag_NotGainInFight)) {
		return;
	}

	Player* targetPlayer = target->getPlayer();
	if (targetPlayer) {
		if (!g_game.isExpertPvpEnabled() && (isPartner(targetPlayer) || isGuildMate(targetPlayer))) {
			addInFightTicks();
			return;
		}

		if (!pzLocked && (g_game.getWorldType() == WORLD_TYPE_PVP_ENFORCED || g_game.getWorldType() == WORLD_TYPE_RETRO_OPEN_PVP)) {
			pzLocked = true;
			setPvpSituation(true);
			targetPlayer->setPvpSituation(true);
			sendIcons();
		}

		targetPlayer->addInFightTicks();

		if (getSkull() == SKULL_NONE && getSkullClient(targetPlayer) == SKULL_YELLOW) {
			addAttacked(targetPlayer);
			targetPlayer->sendCreatureSkull(this);
		} else if (!targetPlayer->hasAttacked(this)) {
			if (!pzLocked) {
				pzLocked = true;
				sendIcons();
			}

			if (!Combat::isInPvpZone(this, targetPlayer) && !isInWar(targetPlayer)) {
				addAttacked(targetPlayer);

				if (targetPlayer->getSkull() == SKULL_NONE && getSkull() == SKULL_NONE && !targetPlayer->hasKilled(this) &&
				 (g_game.getWorldType() == WORLD_TYPE_PVP || !isPartner(targetPlayer)) && (getTile() && !getTile()->hasFlag(TILESTATE_PROTECTIONZONE))) {
					setSkull(SKULL_WHITE);
				}

				if (getSkull() == SKULL_NONE) {
					targetPlayer->sendCreatureSkull(this);
				}
			}
		}
	}
	
	if (g_game.isExpertPvpEnabled()) {
		g_game.updateSpectatorsPvp(this);
		g_game.updateSpectatorsPvp(targetPlayer);
	}

	if (addFightTicks) {
		addInFightTicks();
	}
}

void Player::onAttacked()
{
	Creature::onAttacked();

	addInFightTicks();
}

void Player::onIdleStatus()
{
	Creature::onIdleStatus();

	if (party) {
		party->clearPlayerPoints(this);
	}
}

void Player::onPlacedCreature()
{
	//scripting event - onLogin
	if (!g_creatureEvents->playerLogin(this)) {
		kickPlayer(true);
	}

	sendUnjustifiedPoints();
}

void Player::onAttackedCreatureDrainHealth(Creature* target, int32_t points)
{
	Creature::onAttackedCreatureDrainHealth(target, points);

	if (target) {
		if (party && !Combat::isPlayerCombat(target)) {
			Monster* tmpMonster = target->getMonster();
			if (tmpMonster && tmpMonster->isHostile()) {
				//We have fulfilled a requirement for shared experience
				party->updatePlayerTicks(this, points);
			}
		}
	}
}

void Player::onTargetCreatureGainHealth(Creature* target, int32_t points)
{
	if (target && party) {
		Player* tmpPlayer = nullptr;

		if (isPartner(tmpPlayer) && (tmpPlayer != this)) {
			tmpPlayer = target->getPlayer();
		} else if (Creature* targetMaster = target->getMaster()) {
			if (Player* targetMasterPlayer = targetMaster->getPlayer()) {
				tmpPlayer = targetMasterPlayer;
			}
		}

		if (isPartner(tmpPlayer)) {
			party->updatePlayerTicks(this, points);
		}
	}
}

bool Player::onKilledCreature(Creature* target, bool lastHit/* = true*/)
{
	bool unjustified = false;

	if (hasFlag(PlayerFlag_NotGenerateLoot)) {
		target->setDropLoot(false);
	}

	Creature::onKilledCreature(target, lastHit);

	if (Player* targetPlayer = target->getPlayer()) {
		if (targetPlayer && (targetPlayer->getZone() == ZONE_PVP)) {
			targetPlayer->setDropLoot(false);
			targetPlayer->setSkillLoss(false);
		} else if (!hasFlag(PlayerFlag_NotGainInFight) && !isPartner(targetPlayer)) {
			bool canGainUnjust = hasAttacked(targetPlayer);
			if (!canGainUnjust && g_game.getWorldType() == WORLD_TYPE_RETRO_OPEN_PVP) {
				canGainUnjust = lastHit;
			}

			if (!Combat::isInPvpZone(this, targetPlayer) && canGainUnjust && !targetPlayer->hasAttacked(this) && !isGuildMate(targetPlayer) && targetPlayer != this) {
				if (targetPlayer->hasKilled(this) && hasAttacked(targetPlayer)) {
					for (auto& kill : targetPlayer->unjustifiedKills) {
						if (kill.target == getGUID() && kill.unavenged) {
							auto it = attackedSet.find(targetPlayer->guid);
							if (it != attackedSet.end()) {
								kill.unavenged = false;
								attackedSet.erase(it);
								break;
							}
						}
					}
				} else if (targetPlayer->getSkull() == SKULL_NONE && !isInWar(targetPlayer)) {
					unjustified = true;
					addUnjustifiedDead(targetPlayer);
				}

				if (lastHit && hasCondition(CONDITION_INFIGHT)) {
					pzLocked = true;
					Condition* condition = Condition::createCondition(CONDITIONID_DEFAULT, CONDITION_INFIGHT, g_config.getNumber(ConfigManager::WHITE_SKULL_TIME), 0);
					addCondition(condition);
				}
			}
		}
	}

	return unjustified;
}

void Player::gainExperience(uint64_t gainExp, Creature* source)
{
	if (hasFlag(PlayerFlag_NotGainExperience) || gainExp == 0 || staminaMinutes == 0) {
		return;
	}

	applyBonusExperience(gainExp, source);
	addExperience(source, gainExp, true);
}

void Player::onGainExperience(uint64_t gainExp, Creature* target)
{
	if (hasFlag(PlayerFlag_NotGainExperience)) {
		return;
	}

	if (target && !target->getPlayer() && party && party->isSharedExperienceActive() && party->isSharedExperienceEnabled()) {
		party->shareExperience(gainExp, target);
		//We will get a share of the experience through the sharing mechanism
		return;
	}

	Creature::onGainExperience(gainExp, target);
	gainExperience(gainExp, target);
}

void Player::onGainSharedExperience(uint64_t gainExp, Creature* source)
{
	gainExperience(gainExp, source);
}

bool Player::isImmune(CombatType_t type) const
{
	if (hasFlag(PlayerFlag_CannotBeAttacked)) {
		return true;
	}
	return Creature::isImmune(type);
}

bool Player::isImmune(ConditionType_t type) const
{
	if (hasFlag(PlayerFlag_CannotBeAttacked)) {
		return true;
	}
	return Creature::isImmune(type);
}

bool Player::isAttackable() const
{
	return !hasFlag(PlayerFlag_CannotBeAttacked);
}

bool Player::lastHitIsPlayer(Creature* lastHitCreature)
{
	if (!lastHitCreature) {
		return false;
	}

	if (lastHitCreature->getPlayer()) {
		return true;
	}

	Creature* lastHitMaster = lastHitCreature->getMaster();
	return lastHitMaster && lastHitMaster->getPlayer();
}

void Player::changeHealth(int32_t healthChange, bool sendHealthChange/* = true*/)
{
	Creature::changeHealth(healthChange, sendHealthChange);
	sendStats();
}

void Player::changeMana(int32_t manaChange)
{
	if (!hasFlag(PlayerFlag_HasInfiniteMana)) {
		Creature::changeMana(manaChange);
	}

	if (party) {
		party->broadcastPartyMana(this);
	}

	sendStats();
}

void Player::changeSoul(int32_t soulChange)
{
	if (soulChange > 0) {
		soul += std::min<int32_t>(soulChange, vocation->getSoulMax() - soul);
	} else {
		soul = std::max<int32_t>(0, soul + soulChange);
	}

	sendStats();
}

bool Player::canWear(uint32_t lookType, uint8_t addons) const
{
	if (group->access) {
		return true;
	}

	const Outfit* outfit = Outfits::getInstance().getOutfitByLookType(sex, lookType);
	if (!outfit) {
		return false;
	}

	if (outfit->premium && !isPremium()) {
		return false;
	}

	if (outfit->vip && !isVip()) {
		return false;
	}

	int32_t value;
	if (getStorageValue(81723, value)){
		sendTextMessage(MESSAGE_EVENT_ADVANCE, "You cannot change your outfit inside the Battlefield.");
		return false;
	}

	if (outfit->unlocked && addons == 0) {
		return true;
	}

	for (const OutfitEntry& outfitEntry : outfits) {
		if (outfitEntry.lookType != lookType) {
			continue;
		}
		return (outfitEntry.addons & addons) == addons;
	}
	return false;
}

bool Player::canLogout()
{
	if (isConnecting) {
		return false;
	}

	if (getTile()->hasFlag(TILESTATE_NOLOGOUT)) {
		return false;
	}

	if (getTile()->hasFlag(TILESTATE_PROTECTIONZONE)) {
		return true;
	}

	return !isPzLocked() && !hasCondition(CONDITION_INFIGHT);
}

void Player::genReservedStorageRange()
{
	//generate outfits range
	uint32_t base_key = PSTRG_OUTFITS_RANGE_START;
	for (const OutfitEntry& entry : outfits) {
		storageMap[++base_key] = (entry.lookType << 16) | entry.addons;
	}
}

void Player::addOutfit(uint16_t lookType, uint8_t addons)
{
	for (OutfitEntry& outfitEntry : outfits) {
		if (outfitEntry.lookType == lookType) {
			outfitEntry.addons |= addons;
			return;
		}
	}
	outfits.emplace_back(lookType, addons);
}

bool Player::removeOutfit(uint16_t lookType)
{
	for (auto it = outfits.begin(), end = outfits.end(); it != end; ++it) {
		OutfitEntry& entry = *it;
		if (entry.lookType == lookType) {
			outfits.erase(it);
			return true;
		}
	}
	return false;
}

bool Player::removeOutfitAddon(uint16_t lookType, uint8_t addons)
{
	for (OutfitEntry& outfitEntry : outfits) {
		if (outfitEntry.lookType == lookType) {
			outfitEntry.addons &= ~addons;
			return true;
		}
	}
	return false;
}

bool Player::getOutfitAddons(const Outfit& outfit, uint8_t& addons) const
{
	if (group->access) {
		addons = 3;
		return true;
	}

	if (outfit.premium && !isPremium()) {
		return false;
	}

	if (outfit.vip && !isVip()) {
		return false;
	}

	for (const OutfitEntry& outfitEntry : outfits) {
		if (outfitEntry.lookType != outfit.lookType) {
			continue;
		}

		addons = outfitEntry.addons;
		return true;
	}

	if (!outfit.unlocked) {
		return false;
	}

	addons = 0;
	return true;
}

void Player::setSex(PlayerSex_t newSex)
{
	sex = newSex;
}

void Player::setStamina(uint16_t stamina)
{
	uint16_t oldStamina = staminaMinutes;
	staminaMinutes = std::min<uint16_t>(2520, stamina);
	sendStats();
	if (oldStamina - staminaMinutes > 0) {
		decreasePreyTimeLeft(oldStamina - staminaMinutes);
	}
}

Skulls_t Player::getSkull() const
{
	if (hasFlag(PlayerFlag_NotGainInFight)) {
		return SKULL_NONE;
	}
	return skull;
}

Skulls_t Player::getSkullClient(const Creature* creature) const
{
	if (!creature || !g_game.isWorldTypeSkull()) {
		return SKULL_NONE;
	}

	const Player* player = creature->getPlayer();
	if (player && player->getSkull() == SKULL_NONE) {
		if (player == this) {
			for (const auto& kill : unjustifiedKills) {
				if (kill.unavenged && (OS_TIME(nullptr) - kill.time) < g_config.getNumber(ConfigManager::ORANGE_SKULL_DURATION) * 24 * 60 * 60) {
					return SKULL_ORANGE;
				}
			}
		}

		if (isInWar(player)) {
			return SKULL_GREEN;
		}

		if (!player->getGuildWarVector().empty() && guild == player->getGuild()) {
			return SKULL_GREEN;
		}

		if (player->hasKilled(this)) {
			return SKULL_ORANGE;
		}

		if (isPartner(player)) {
			return SKULL_GREEN;
		}

		if (player->hasAttacked(this)) {
			return SKULL_YELLOW;
		}

	}
	return Creature::getSkullClient(creature);
}

bool Player::hasKilled(const Player* player) const
{
	for (const auto& kill : unjustifiedKills) {
		if (kill.target == player->getGUID() && (OS_TIME(nullptr) - kill.time) < g_config.getNumber(ConfigManager::ORANGE_SKULL_DURATION) * 24 * 60 * 60 && kill.unavenged) {
			return true;
		}
	}

	return false;
}

bool Player::hasAttacked(const Player* attacked) const
{
	if (hasFlag(PlayerFlag_NotGainInFight) || !attacked) {
		return false;
	}

	return attackedSet.find(attacked->guid) != attackedSet.end();
}

void Player::addAttacked(const Player* attacked)
{
	if (hasFlag(PlayerFlag_NotGainInFight) || !attacked || attacked == this) {
		return;
	}

	attackedSet.insert(attacked->guid);
}

void Player::removeAttacked(const Player* attacked)
{
	if (!attacked || attacked == this) {
		return;
	}

	auto it = attackedSet.find(attacked->guid);
	if (it != attackedSet.end()) {
		attackedSet.erase(it);
	}
}

void Player::clearAttacked()
{
	attackedSet.clear();
}

void Player::addUnjustifiedDead(const Player* attacked)
{
	if (hasFlag(PlayerFlag_NotGainInFight) || attacked == this || g_game.getWorldType() == WORLD_TYPE_PVP_ENFORCED) {
		return;
	}

	if (isInWar(attacked)) {
		return;
	}

	if (inprivatewar) {
		sendTextMessage(MESSAGE_EVENT_ADVANCE, "Warning! War System is over, please caution!");
		return;
	}

	if (attacked && attacked->getLevel() <= 50) {
		return;
	}

	sendTextMessage(MESSAGE_EVENT_ADVANCE, "Warning! The murder of " + attacked->getName() + " was not justified.");

	unjustifiedKills.emplace_back(attacked->getGUID(), OS_TIME(nullptr), true);

	uint8_t dayKills = 0;
	uint8_t weekKills = 0;
	uint8_t monthKills = 0;

	for (const auto& kill : unjustifiedKills) {
		const auto diff = OS_TIME(nullptr) - kill.time;
		if (diff <= 4 * 60 * 60) {
			dayKills += 1;
		}
		if (diff <= 7 * 24 * 60 * 60) {
			weekKills += 1;
		}
		if (diff <= 30 * 24 * 60 * 60) {
			monthKills += 1;
		}
	}

	if (getSkull() != SKULL_BLACK) {
		if (dayKills >= 2 * g_config.getNumber(ConfigManager::DAY_KILLS_TO_RED) || weekKills >= 2 * g_config.getNumber(ConfigManager::WEEK_KILLS_TO_RED) || monthKills >= 2 * g_config.getNumber(ConfigManager::MONTH_KILLS_TO_RED)) {
			setSkull(SKULL_BLACK);
			lastday = OS_TIME(nullptr);
			//start black skull time
			skullTicks = static_cast<int64_t>(g_config.getNumber(ConfigManager::BLACK_SKULL_DURATION)) * 24 * 60 * 60 * 1000;
		} else if (dayKills >= g_config.getNumber(ConfigManager::DAY_KILLS_TO_RED) || weekKills >= g_config.getNumber(ConfigManager::WEEK_KILLS_TO_RED) || monthKills >= g_config.getNumber(ConfigManager::MONTH_KILLS_TO_RED)) {
			setSkull(SKULL_RED);
			lastday = OS_TIME(nullptr);
			//reset red skull time
			skullTicks = static_cast<int64_t>(g_config.getNumber(ConfigManager::RED_SKULL_DURATION)) * 24 * 60 * 60 * 1000;
		}
	}

	sendUnjustifiedPoints();
}

void Player::checkSkullTicks(int64_t ticks)
{
	int64_t newTicks = skullTicks - ticks;
	if (newTicks < 0) {
		// skullTicks = 0;
	} else {
		// skullTicks = newTicks;
	}

	if ((skull == SKULL_RED || skull == SKULL_BLACK) && skullTicks < 1000 && !hasCondition(CONDITION_INFIGHT)) {
		setSkull(SKULL_NONE);
	}
}

void Player::updateSkullTicks()
{
	time_t timeNow = OS_TIME(nullptr);

	if (skullTicks != 0) {
		if (lastday == 0) {
			lastday = timeNow;
		} else {
			uint32_t days = (timeNow - lastday) / 86400;
			if (days > 0) {
				if ((days * 86400 * 1000) >= skullTicks) {
					skullTicks = 0;
					lastday = 0;
				} else {
					skullTicks -= (days * 86400 * 1000);
					time_t remainder = (timeNow - lastday) % 86400;
					lastday = timeNow - remainder;
				}
			}
		}
	} else if (lastday != 0) {
		lastday = 0;
	}

	if (skullTicks <= 0) {
		setSkull(SKULL_NONE);
	}

}

bool Player::isPromoted() const
{
	uint16_t promotedVocation = g_vocations.getPromotedVocation(vocation->getId());
	return promotedVocation == VOCATION_NONE && vocation->getId() != promotedVocation;
}

double Player::getLostPercent() const
{
	int32_t blessingCount = 0;
	uint8_t maxBlessing = 8;
	for (int i = 1; i <= maxBlessing; i++) {
		if (hasBlessing(i)) {
			blessingCount++;
		}
	}

	int32_t deathLosePercent = g_config.getNumber(ConfigManager::DEATH_LOSE_PERCENT);
	if (deathLosePercent != -1) {
		if (isPromoted()) {
			deathLosePercent -= 3;
		}

		deathLosePercent -= blessingCount;
		return std::max<int32_t>(0, deathLosePercent) / 100.;
	}

	double lossPercent;
	if (level >= 25) {
		double tmpLevel = level + (levelPercent / 100.);
		lossPercent = static_cast<double>((tmpLevel + 50) * 50 * ((tmpLevel * tmpLevel) - (5 * tmpLevel) + 8)) / experience;
	} else {
		lossPercent = 5;
	}

	double percentReduction = 0;
	if (isPromoted()) {
		percentReduction += 30;
	}

	percentReduction += blessingCount * 8;
	return lossPercent * (1 - (percentReduction / 100.)) / 100.;
}

void Player::learnInstantSpell(const std::string& spellName)
{
	if (!hasLearnedInstantSpell(spellName)) {
		learnedInstantSpellList.push_front(spellName);
	}
}

void Player::forgetInstantSpell(const std::string& spellName)
{
	learnedInstantSpellList.remove(spellName);
}

bool Player::hasLearnedInstantSpell(const std::string& spellName) const
{
	if (hasFlag(PlayerFlag_CannotUseSpells)) {
		return false;
	}

	if (hasFlag(PlayerFlag_IgnoreSpellCheck)) {
		return true;
	}

	for (const auto& learnedSpellName : learnedInstantSpellList) {
		if (strcasecmp(learnedSpellName.c_str(), spellName.c_str()) == 0) {
			return true;
		}
	}
	return false;
}

bool Player::isInWar(const Player* player) const
{
	if (!player || !guild) {
		return false;
	}

	const Guild* playerGuild = player->getGuild();
	if (!playerGuild) {
		return false;
	}

	return isInWarList(playerGuild->getId()) && player->isInWarList(guild->getId());
}

bool Player::isInWarList(uint32_t guildId) const
{
	return std::find(guildWarVector.begin(), guildWarVector.end(), guildId) != guildWarVector.end();
}

bool Player::isPremium() const
{
	if (g_config.getBoolean(ConfigManager::FREE_PREMIUM) || hasFlag(PlayerFlag_IsAlwaysPremium)) {
		return true;
	}

	return premiumDays > 0;
}

void Player::setPremiumDays(int32_t v)
{
	premiumDays = v;
	sendBasicData();
}

void Player::setTibiaCoins(int32_t v, CoinType_t coinType)
{
	switch (coinType) {
		case COIN_TYPE_DEFAULT:
		case COIN_TYPE_TRANSFERABLE: {
			coinBalance = v;
			break;
		}

		case COIN_TYPE_TOURNAMENT: {
			tournamentCoinBalance = v;
			break;
		}

		default: {
			coinBalance = v;
			break;
		}
	}
}

bool Player::canRemoveCoins(int32_t v, CoinType_t coinType)
{
	if (lastupdatecoin - OTSYS_TIME() < 2000) {
		// a cada 2 segundos atualizar, na diferença que for chamada
		lastupdatecoin = OTSYS_TIME() + 2000;
		if (coinType == COIN_TYPE_DEFAULT || coinType == COIN_TYPE_TRANSFERABLE) {
			coinBalance = IOAccount::getCoinBalance(accountNumber);
		} else if (coinType == COIN_TYPE_TOURNAMENT) {
			tournamentCoinBalance = IOAccount::getCoinBalance(accountNumber, coinType);
		}
	}


	int32_t coins; 
	switch (coinType) {
		case COIN_TYPE_DEFAULT:
		case COIN_TYPE_TRANSFERABLE: {
			coins = coinBalance;
			break;
		}

		case COIN_TYPE_TOURNAMENT: {
			coins = tournamentCoinBalance;
			break;
		}

		default: {
			coins = coinBalance;
			break;
		}
	}

	return (coins - v) >= 0;
}

PartyShields_t Player::getPartyShield(const Player* player) const
{
	if (!player) {
		return SHIELD_NONE;
	}

	if (party) {
		if (party->getLeader() == player) {
			if (party->isSharedExperienceActive()) {
				if (party->isSharedExperienceEnabled()) {
					return SHIELD_YELLOW_SHAREDEXP;
				}

				if (party->canUseSharedExperience(player)) {
					return SHIELD_YELLOW_NOSHAREDEXP;
				}

				return SHIELD_YELLOW_NOSHAREDEXP_BLINK;
			}

			return SHIELD_YELLOW;
		}

		if (player->party == party) {
			if (party->isSharedExperienceActive()) {
				if (party->isSharedExperienceEnabled()) {
					return SHIELD_BLUE_SHAREDEXP;
				}

				if (party->canUseSharedExperience(player)) {
					return SHIELD_BLUE_NOSHAREDEXP;
				}

				return SHIELD_BLUE_NOSHAREDEXP_BLINK;
			}

			return SHIELD_BLUE;
		}

		if (isInviting(player)) {
			return SHIELD_WHITEBLUE;
		}
	}

	if (player->isInviting(this)) {
		return SHIELD_WHITEYELLOW;
	}

	if (player->party) {
		return SHIELD_GRAY;
	}

	return SHIELD_NONE;
}

bool Player::isInviting(const Player* player) const
{
	if (!player || !party || party->getLeader() != this) {
		return false;
	}
	return party->isPlayerInvited(player);
}

bool Player::isPartner(const Player* player) const
{
	if (!player || !party || player == this) {
		return false;
	}
	return party == player->party;
}

bool Player::isGuildMate(const Player* player) const
{
	if (!player || !guild) {
		return false;
	}
	return guild == player->guild;
}

void Player::sendPlayerPartyIcons(Player* player)
{
	sendCreatureShield(player);
	sendCreatureSkull(player);
}

bool Player::addPartyInvitation(Party* party)
{
	auto it = std::find(invitePartyList.begin(), invitePartyList.end(), party);
	if (it != invitePartyList.end()) {
		return false;
	}

	invitePartyList.push_front(party);
	return true;
}

void Player::removePartyInvitation(Party* party)
{
	invitePartyList.remove(party);
}

void Player::clearPartyInvitations()
{
	for (Party* invitingParty : invitePartyList) {
		invitingParty->removeInvite(*this, false);
	}
	invitePartyList.clear();
}

GuildEmblems_t Player::getGuildEmblem(const Player* player) const
{
	if (!player) {
		return GUILDEMBLEM_NONE;
	}

	const Guild* playerGuild = player->getGuild();
	if (!playerGuild) {
		return GUILDEMBLEM_NONE;
	}

	if (player->getGuildWarVector().empty()) {
		if (guild == playerGuild) {
			return GUILDEMBLEM_MEMBER;
		} else {
			return GUILDEMBLEM_OTHER;
		}
	} else if (guild == playerGuild) {
		return GUILDEMBLEM_ALLY;
	} else if (isInWar(player)) {
		return GUILDEMBLEM_ENEMY;
	}

	return GUILDEMBLEM_NEUTRAL;
}

void Player::sendUnjustifiedPoints()
{
	if (client) {
		double dayKills = 0;
		double weekKills = 0;
		double monthKills = 0;

		for (const auto& kill : unjustifiedKills) {
			const auto diff = OS_TIME(nullptr) - kill.time;
			if (diff <= 24 * 60 * 60) {
				dayKills += 1;
			}
			if (diff <= 7 * 24 * 60 * 60) {
				weekKills += 1;
			}
			if (diff <= 30 * 24 * 60 * 60) {
				monthKills += 1;
			}
		}

		bool isRed = getSkull() == SKULL_RED;

		auto dayMax = ((isRed ? 2 : 1) * g_config.getNumber(ConfigManager::DAY_KILLS_TO_RED));
		auto weekMax = ((isRed ? 2 : 1) * g_config.getNumber(ConfigManager::WEEK_KILLS_TO_RED));
		auto monthMax = ((isRed ? 2 : 1) * g_config.getNumber(ConfigManager::MONTH_KILLS_TO_RED));		

		uint8_t dayProgress = std::min(std::round(dayKills / dayMax * 100), 100.0);
		uint8_t weekProgress = std::min(std::round(weekKills / weekMax * 100), 100.0);
		uint8_t monthProgress = std::min(std::round(monthKills / monthMax * 100), 100.0);
		uint8_t skullDuration = 0;
		if (skullTicks != 0) {
			skullDuration = std::floor<uint8_t>(skullTicks / (24 * 60 * 60 * 1000));
		}
		client->sendUnjustifiedPoints(dayProgress, std::max(dayMax - dayKills, 0.0), weekProgress, std::max(weekMax - weekKills, 0.0), monthProgress, std::max(monthMax - monthKills, 0.0), skullDuration);
	}
}

uint8_t Player::getCurrentMount() const
{
	int32_t value;
	if (getStorageValue(PSTRG_MOUNTS_CURRENTMOUNT, value)) {
		return value;
	}
	return 0;
}

void Player::setCurrentMount(uint8_t mount)
{
	addStorageValue(PSTRG_MOUNTS_CURRENTMOUNT, mount);
}

bool Player::toggleMount(bool mount)
{
	if ((OTSYS_TIME() - lastToggleMount) < 3000 && !wasMounted) {
		sendCancelMessage(RETURNVALUE_YOUAREEXHAUSTED);
		return false;
	}

	if (mount) {
		if (isMounted()) {
			return false;
		}

		if (!group->access && tile->hasFlag(TILESTATE_PROTECTIONZONE)) {
			sendCancelMessage(RETURNVALUE_ACTIONNOTPERMITTEDINPROTECTIONZONE);
			return false;
		}

		const Outfit* playerOutfit = Outfits::getInstance().getOutfitByLookType(getSex(), defaultOutfit.lookType);
		if (!playerOutfit) {
			return false;
		}

		uint8_t currentMountId = getCurrentMount();
		if (currentMountId == 0) {
			sendOutfitWindow();
			return false;
		}

		Mount* currentMount = g_game.mounts.getMountByID(currentMountId);
		if (!currentMount) {
			return false;
		}

		if (!hasMount(currentMount)) {
			setCurrentMount(0);
			sendOutfitWindow();
			return false;
		}

		if (currentMount->premium && !isPremium()) {
			sendCancelMessage(RETURNVALUE_YOUNEEDPREMIUMACCOUNT);
			return false;
		}

		if (currentMount->vip && !isVip()) {
			sendCancelMessage(RETURNVALUE_YOUNEEDVIPACCOUNT);
			return false;
		}

		if (hasCondition(CONDITION_OUTFIT)) {
			sendCancelMessage(RETURNVALUE_NOTPOSSIBLE);
			return false;
		}

		defaultOutfit.lookMount = currentMount->clientId;

		if (currentMount->speed != 0) {
			g_game.changeSpeed(this, currentMount->speed);
		}
	} else {
		if (!isMounted()) {
			return false;
		}

		dismount();
	}

	g_game.internalCreatureChangeOutfit(this, defaultOutfit);
	lastToggleMount = OTSYS_TIME();
	return true;
}

bool Player::tameMount(uint8_t mountId)
{
	if (!g_game.mounts.getMountByID(mountId)) {
		return false;
	}

	const uint8_t tmpMountId = mountId - 1;
	const uint32_t key = PSTRG_MOUNTS_RANGE_START + (tmpMountId / 31);

	int32_t value;
	if (getStorageValue(key, value)) {
		value |= (1 << (tmpMountId % 31));
	} else {
		value = (1 << (tmpMountId % 31));
	}

	addStorageValue(key, value);
	return true;
}

bool Player::untameMount(uint8_t mountId)
{
	if (!g_game.mounts.getMountByID(mountId)) {
		return false;
	}

	const uint8_t tmpMountId = mountId - 1;
	const uint32_t key = PSTRG_MOUNTS_RANGE_START + (tmpMountId / 31);

	int32_t value;
	if (!getStorageValue(key, value)) {
		return true;
	}

	value &= ~(1 << (tmpMountId % 31));
	addStorageValue(key, value);

	if (getCurrentMount() == mountId) {
		if (isMounted()) {
			dismount();
			g_game.internalCreatureChangeOutfit(this, defaultOutfit);
		}

		setCurrentMount(0);
	}

	return true;
}

bool Player::hasMount(const Mount* mount) const
{
	if (isAccessPlayer()) {
		return true;
	}

	if (mount->premium && !isPremium()) {
		return false;
	}

	if (mount->vip && !isVip()) {
		return false;
	}

	const uint8_t tmpMountId = mount->id - 1;

	int32_t value;
	if (!getStorageValue(PSTRG_MOUNTS_RANGE_START + (tmpMountId / 31), value)) {
		return false;
	}

	return ((1 << (tmpMountId % 31)) & value) != 0;
}

void Player::dismount()
{
	Mount* mount = g_game.mounts.getMountByID(getCurrentMount());
	if (mount && mount->speed > 0) {
		g_game.changeSpeed(this, -mount->speed);
	}

	defaultOutfit.lookMount = 0;
}

bool Player::addOfflineTrainingTries(skills_t skill, uint64_t tries)
{
	if (tries == 0 || skill == SKILL_LEVEL) {
		return false;
	}

	bool sendUpdate = false;
	uint32_t oldSkillValue, newSkillValue;
	long double oldPercentToNextLevel, newPercentToNextLevel;

	if (skill == SKILL_MAGLEVEL) {
		uint64_t currReqMana = vocation->getReqMana(magLevel);
		uint64_t nextReqMana = vocation->getReqMana(magLevel + 1);

		if (currReqMana >= nextReqMana) {
			return false;
		}

		oldSkillValue = magLevel;
		oldPercentToNextLevel = static_cast<long double>(manaSpent * 100) / nextReqMana;

		g_events->eventPlayerOnGainSkillTries(this, SKILL_MAGLEVEL, tries);
		uint32_t currMagLevel = magLevel;

		while ((manaSpent + tries) >= nextReqMana) {
			tries -= nextReqMana - manaSpent;

			magLevel++;
			manaSpent = 0;

			g_creatureEvents->playerAdvance(this, SKILL_MAGLEVEL, magLevel - 1, magLevel);

			sendUpdate = true;
			currReqMana = nextReqMana;
			nextReqMana = vocation->getReqMana(magLevel + 1);

			if (currReqMana >= nextReqMana) {
				tries = 0;
				break;
			}
		}

		manaSpent += tries;

		if (magLevel != currMagLevel) {
			std::ostringstream ss;
			ss << "You advanced to magic level " << magLevel << '.';
			sendTextMessage(MESSAGE_EVENT_ADVANCE, ss.str());
		}

		uint8_t newPercent;
		if (nextReqMana > currReqMana) {
			newPercent = Player::getPercentLevel(manaSpent, nextReqMana);
			newPercentToNextLevel = static_cast<long double>(manaSpent * 100) / nextReqMana;
		} else {
			newPercent = 0;
			newPercentToNextLevel = 0;
		}

		if (newPercent != magLevelPercent) {
			magLevelPercent = newPercent;
			sendUpdate = true;
		}

		newSkillValue = magLevel;
	} else {
		uint64_t currReqTries = vocation->getReqSkillTries(skill, skills[skill].level);
		uint64_t nextReqTries = vocation->getReqSkillTries(skill, skills[skill].level + 1);
		if (currReqTries >= nextReqTries) {
			return false;
		}

		oldSkillValue = skills[skill].level;
		oldPercentToNextLevel = static_cast<long double>(skills[skill].tries * 100) / nextReqTries;

		g_events->eventPlayerOnGainSkillTries(this, skill, tries);
		uint32_t currSkillLevel = skills[skill].level;

		while ((skills[skill].tries + tries) >= nextReqTries) {
			tries -= nextReqTries - skills[skill].tries;

			skills[skill].level++;
			skills[skill].tries = 0;
			skills[skill].percent = 0;

			g_creatureEvents->playerAdvance(this, skill, (skills[skill].level - 1), skills[skill].level);

			sendUpdate = true;
			currReqTries = nextReqTries;
			nextReqTries = vocation->getReqSkillTries(skill, skills[skill].level + 1);

			if (currReqTries >= nextReqTries) {
				tries = 0;
				break;
			}
		}

		skills[skill].tries += tries;

		if (currSkillLevel != skills[skill].level) {
			std::ostringstream ss;
			ss << "You advanced to " << getSkillName(skill) << " level " << skills[skill].level << '.';
			sendTextMessage(MESSAGE_EVENT_ADVANCE, ss.str());
		}

		uint8_t newPercent;
		if (nextReqTries > currReqTries) {
			newPercent = Player::getPercentLevel(skills[skill].tries, nextReqTries);
			newPercentToNextLevel = static_cast<long double>(skills[skill].tries * 100) / nextReqTries;
		} else {
			newPercent = 0;
			newPercentToNextLevel = 0;
		}

		if (skills[skill].percent != newPercent) {
			skills[skill].percent = newPercent;
			sendUpdate = true;
		}

		newSkillValue = skills[skill].level;
	}

	if (sendUpdate) {
		sendStats();
		sendSkills();
	}

	std::ostringstream ss;
	ss << std::fixed << std::setprecision(2) << "Your " << ucwords(getSkillName(skill)) << " skill changed from level " << oldSkillValue << " (with " << oldPercentToNextLevel << "% progress towards level " << (oldSkillValue + 1) << ") to level " << newSkillValue << " (with " << newPercentToNextLevel << "% progress towards level " << (newSkillValue + 1) << ')';
	sendTextMessage(MESSAGE_EVENT_ADVANCE, ss.str());
	return sendUpdate;
}

bool Player::hasModalWindowOpen(uint32_t modalWindowId) const
{
	return find(modalWindows.begin(), modalWindows.end(), modalWindowId) != modalWindows.end();
}

void Player::onModalWindowHandled(uint32_t modalWindowId)
{
	modalWindows.remove(modalWindowId);
}

void Player::sendModalWindow(const ModalWindow& modalWindow)
{
	if (!client) {
		return;
	}

	modalWindows.push_front(modalWindow.id);
	client->sendModalWindow(modalWindow);
}

void Player::clearModalWindows()
{
	modalWindows.clear();
}

uint16_t Player::getHelpers() const
{
	uint16_t helpers;

	if (guild && party) {
		std::unordered_set<Player*> helperSet;

		const auto& guildMembers = guild->getMembersOnline();
		helperSet.insert(guildMembers.begin(), guildMembers.end());

		const auto& partyMembers = party->getMembers();
		helperSet.insert(partyMembers.begin(), partyMembers.end());

		const auto& partyInvitees = party->getInvitees();
		helperSet.insert(partyInvitees.begin(), partyInvitees.end());

		helperSet.insert(party->getLeader());

		helpers = helperSet.size();
	} else if (guild) {
		helpers = guild->getMembersOnline().size();
	} else if (party) {
		helpers = party->getMemberCount() + party->getInvitationCount() + 1;
	} else {
		helpers = 0;
	}

	return helpers;
}

void Player::sendClosePrivate(uint16_t channelId)
{
	if (channelId == CHANNEL_GUILD || channelId == CHANNEL_PARTY) {
		g_chat->removeUserFromChannel(*this, channelId);
	}

	if (client) {
		client->sendClosePrivate(channelId);
	}
}

uint64_t Player::getMoney() const
{
	std::vector<const Container*> containers;
	uint64_t moneyCount = 0;

	for (int32_t i = CONST_SLOT_FIRST; i <= CONST_SLOT_LAST; ++i) {
		Item* item = inventory[i];
		if (!item) {
			continue;
		}

		const Container* container = item->getContainer();
		if (container) {
			containers.push_back(container);
		} else {
			moneyCount += item->getWorth();
		}
	}

	size_t i = 0;
	while (i < containers.size()) {
		const Container* container = containers[i++];
		for (const Item* item : container->getItemList()) {
			const Container* tmpContainer = item->getContainer();
			if (tmpContainer) {
				containers.push_back(tmpContainer);
			} else {
				moneyCount += item->getWorth();
			}
		}
	}
	return moneyCount;
}

size_t Player::getMaxVIPEntries() const
{
	if (group->maxVipEntries != 0) {
		return group->maxVipEntries;
	} else if (isPremium()) {
		return 100;
	}
	return 20;
}

size_t Player::getMaxDepotItems() const
{
	if (group->maxDepotItems != 0) {
		return group->maxDepotItems;
	} else if (isPremium()) {
		return g_config.getNumber(ConfigManager::PREMIUM_DEPOT_LIMIT);
	}
	return g_config.getNumber(ConfigManager::FREE_DEPOT_LIMIT);
}

std::forward_list<Condition*> Player::getMuteConditions() const
{
	std::forward_list<Condition*> muteConditions;
	for (Condition* condition : conditions) {
		if (condition->getTicks() <= 0) {
			continue;
		}

		ConditionType_t type = condition->getType();
		if (type != CONDITION_MUTED && type != CONDITION_CHANNELMUTEDTICKS && type != CONDITION_YELLTICKS) {
			continue;
		}

		muteConditions.push_front(condition);
	}
	return muteConditions;
}

void Player::setGuild(Guild* guild)
{
	if (guild == this->guild) {
		return;
	}

	Guild* oldGuild = this->guild;

	this->guildNick.clear();
	this->guild = nullptr;
	this->guildRank = nullptr;

	if (guild) {
		GuildRank_ptr rank = guild->getRankByLevel(1);
		if (!rank) {
			return;
		}

		this->guild = guild;
		this->guildRank = rank;
		guild->addMember(this);
	}

	if (oldGuild) {
		oldGuild->removeMember(this);
	}
}

//Custom: Anti bug do market
bool Player::isMarketExhausted() const {
	uint32_t exhaust_time = 3000; // half second 500
	return (OTSYS_TIME() - lastMarketInteraction < exhaust_time);
}

void Player::onEquipImbueItem(Imbuement* imbuement)
{
	// check skills
	bool requestUpdate = false;

	for (int32_t i = SKILL_FIST; i <= SKILL_LAST; ++i) {
		if (imbuement->skills[i]) {
			requestUpdate = true;
			setVarSkill(static_cast<skills_t>(i), imbuement->skills[i]);
		}
	}

	// check magpoint
	for (int32_t s = STAT_FIRST; s <= STAT_LAST; ++s) {
		if (imbuement->stats[s]) {
			requestUpdate = true;
			setVarStats(static_cast<stats_t>(s), imbuement->stats[s]);
		}
	}

	// speed
	if (imbuement->speed != 0) {
		g_game.changeSpeed(this, imbuement->speed);
	}

	// capacity
	if (imbuement->capacity != 0) {
		double capImbue = static_cast<double>(imbuement->capacity)/100;
		varCap = capacity * capImbue;
		requestUpdate = true;
	}

	if (requestUpdate) {
		requestUpdate = false;
		sendStats();
		sendSkills();
	}

	return;
}

void Player::onDeEquipImbueItem(Imbuement* imbuement)
{
	// check skills
	bool requestUpdate = false;

	for (int32_t i = SKILL_FIST; i <= SKILL_LAST; ++i) {
		if (imbuement->skills[i]) {
			requestUpdate = true;
			setVarSkill(static_cast<skills_t>(i), -imbuement->skills[i]);
		}
	}

	// check magpoint
	for (int32_t s = STAT_FIRST; s <= STAT_LAST; ++s) {
		if (imbuement->stats[s]) {
			requestUpdate = true;
			setVarStats(static_cast<stats_t>(s), -imbuement->stats[s]);
		}
	}

	// speed
	if (imbuement->speed != 0) {
		g_game.changeSpeed(this, -imbuement->speed);
	}

	// capacity
	if (imbuement->capacity != 0) {
		varCap = 0;
		requestUpdate = true;
	}

	if (requestUpdate) {
		requestUpdate = false;
		sendStats();
		sendSkills();
	}

	return;
}

StreakBonus_t Player::getStreakDaysBonus()const {
	int32_t value;
	StreakBonus_t bonus;

	getStorageValue(DAILYREWARDSTORAGE_STREAKDAYS,value);

	if(value <= 1)
		bonus = STREAKBONUS_NOBONUS;
	else if(value == 2)
		bonus = STREAKBONUS_HEALTHBONUS;
	else if(value == 3)
		bonus = STREAKBONUS_MANABONUS;
	else if(value == 4)
		bonus = STREAKBONUS_STAMINABONUS;
	else if(value == 5)
		bonus = STREAKBONUS_DOUBLEHEALTHBONUS;
	else if(value == 6)
		bonus = STREAKBONUS_DOUBLEMANABONUS;
	else
		bonus = STREAKBONUS_SOULBONUS;

	return bonus;
}

void Player::sendRestingAreaIcon(uint16_t currentIcons) const {
	if (client && getProtocolVersion() >= 1140) {
		if (hasBitSet(ICON_PIGEON, currentIcons)) {
			bool activeResting = false;

			if (getStreakDaysBonus() > STREAKBONUS_NOBONUS) {
				activeResting = true;
			}
			client->sendRestingAreaIcon(true, activeResting);
		} else {
			client->sendRestingAreaIcon(false); // clear
		}
	}
}

bool Player::doCritical(uint64_t crit)
{
	if (crit > critical) {
		critical = crit;
		return true;
	}

	return false;
}

void Player::addBestiaryKill(uint16_t racedid, int32_t value, bool gained)
{
	if (value != -1) {
		auto it = bestiaryKills.find(racedid);
		if (it == bestiaryKills.end()) {
			BestiaryPoints bestiaryPoints;
			bestiaryPoints.kills = value;
			bestiaryPoints.gained = gained;
			bestiaryKills[racedid] = bestiaryPoints;
		} else {
			BestiaryPoints& bestiaryPoints = it->second;
			bestiaryPoints.kills = bestiaryPoints.kills + value;
			if (gained) {
				bestiaryPoints.gained = gained;
			}
		}

	} else {
		bestiaryKills.erase(racedid);
	}
}

bool Player::getBestiaryKill(uint16_t racedid, int32_t value) const
{
	auto it = bestiaryKills.find(racedid);
	if (it == bestiaryKills.end()) {
		value = -1;
		return false;
	}

	const BestiaryPoints& bestiaryPoints = it->second;
	value = bestiaryPoints.kills;
	return true;
}

int32_t Player::getBestiaryKills(uint16_t racedid)
{
	auto it = bestiaryKills.find(racedid);
	if (it != bestiaryKills.end()) {
		BestiaryPoints& bestiaryPoints = it->second;
		return bestiaryPoints.kills;
	}

	return 0;
}

bool Player::gainedCharmPoints(uint16_t racedid)
{
	auto it = bestiaryKills.find(racedid);
	if (it != bestiaryKills.end()) {
		BestiaryPoints& bestiaryPoints = it->second;
		return bestiaryPoints.gained;
	}

	return false;
}

uint16_t Player::getCurrentCreature(uint8_t charmid)
{
	for (const auto& it : charmMap) {
		if (it.first == charmid) {
			return it.second;
		}
	}

	return 0;
}

void Player::addCharm(uint8_t charmid, uint16_t raceid)
{
	charmMap[charmid] = raceid;
}

void Player::removeCharm(uint8_t charmid, bool remove)
{
	if (remove) { // eraser
		charmMap.erase(charmid);
	} else {
		charmMap[charmid] = 0;
	}
}

int8_t Player::getMonsterCharm(uint16_t racedid)
{
	for (const auto& it : charmMap) {
		if (it.second == racedid) {
			return it.first;
		}
	}

	return -1;
}

void Player::setEffectLowBlow(bool newvalue)
{
	if (newvalue == effectLowBlow) {
		return;
	}

	if (newvalue) {
		setVarSkill(SKILL_CRITICAL_HIT_CHANCE, 3);
	} else {
		setVarSkill(SKILL_CRITICAL_HIT_CHANCE, -3);
	}

	sendSkills();
	effectLowBlow = newvalue;
}

void Player::manageMonsterTracker(uint16_t raceid)
{
	int count = 0;
	for (const auto& race : bestiaryTracker) {
		if (race == raceid) {
			bestiaryTracker.erase(bestiaryTracker.begin() + count);
			sendBestiaryTracker();
			return;
		}
		count++;
	}

	if (bestiaryTracker.size() >= 250) {
		return;
	}

	bestiaryTracker.emplace_back(raceid);

	sendBestiaryTracker();
}

bool Player::monsterInTracker(uint16_t raceid)
{
	for (const auto& race : bestiaryTracker) {
		if (race == raceid) {
			return true;
		}
	}

	return false;
}

void Player::generatePreyData()
{
	for (uint8_t preySlotId = 0; preySlotId < PREY_SLOTCOUNT; preySlotId++) {
		if (preySlotId != 2) {
			changePreyDataState(preySlotId, STATE_SELECTION);
		}
	}
}

ReturnValue Player::changePreyDataState(uint8_t preySlotId, PreyState state, uint8_t monsterIndex, std::string monsterName)
{
	if (preySlotId >= PREY_SLOTCOUNT) {
		return RETURNVALUE_PREYINTERNALERROR;
	}

	PreyData& currentPrey = preyData[preySlotId];

	bool success = false;

	if ((currentPrey.state != STATE_ACTIVE && state == STATE_SELECTION) || ((currentPrey.state == STATE_ACTIVE || currentPrey.state == STATE_SELECTION_CHANGE_MONSTER) && state == STATE_SELECTION_CHANGE_MONSTER)) {
		std::vector<std::string> elim;
		elim.reserve(9 * 3);
		for (uint8_t slotId = 0; slotId < PREY_SLOTCOUNT; slotId++) {
			if (slotId != preySlotId) {
				PreyData& anotherPrey = preyData[slotId];
				elim.insert(elim.end(), anotherPrey.preyList.begin(), anotherPrey.preyList.end());
			}
		}
		std::sort(elim.begin(), elim.end());

		currentPrey.preyList = std::move(selectRandom(g_prey.getPreyNames(), 9, elim));
		success = true;
	} else if (currentPrey.state == STATE_ACTIVE && state == STATE_SELECTION) {
		auto it = std::find(currentPrey.preyList.begin(), currentPrey.preyList.end(), currentPrey.preyMonster);
		if (it != currentPrey.preyList.end()) {
			currentPrey.preyList.erase(it);

			std::vector<std::string> elim;
			elim.reserve(9 * PREY_SLOTCOUNT);
			for (uint8_t slotId = 0; slotId < PREY_SLOTCOUNT; slotId++) {
				PreyData& anotherPrey = preyData[slotId];
				elim.insert(elim.end(), anotherPrey.preyList.begin(), anotherPrey.preyList.end());
			}

			std::sort(elim.begin(), elim.end());
			std::vector<std::string> tmpVector = selectRandom(g_prey.getPreyNames(), 1, elim);
			if (tmpVector.size() > 0) {
				currentPrey.preyList.emplace_back(tmpVector[0]);
				std::sort(currentPrey.preyList.begin(), currentPrey.preyList.end());
			}

			success = true;
		}
	} else if ((currentPrey.state == STATE_SELECTION || currentPrey.state == STATE_SELECTION_CHANGE_MONSTER) && state == STATE_ACTIVE) {
		if (monsterIndex >= 0 && monsterIndex < currentPrey.preyList.size()) {
			std::string monster = currentPrey.preyList[monsterIndex];
			bool jaTemBonus = false;
			for (uint8_t slotId = 0; slotId < PREY_SLOTCOUNT; slotId++) {
				PreyData& anotherPrey = preyData[slotId];
				if (strcasecmp(anotherPrey.preyMonster.c_str(), monster.c_str()) == 0) {
					jaTemBonus = true;
					break;
				}
			}

			if (!jaTemBonus) {
				currentPrey.preyMonster = monster;
				currentPrey.timeLeft = g_prey.getPreyDuration();
	
				if (currentPrey.state == STATE_SELECTION) {
					currentPrey.bonusGrade = uniform_random(1, 10);
					const BonusEntry& bonus = g_prey.getAvailableBonuses()[uniform_random(0, static_cast<int32_t>(g_prey.getAvailableBonuses().size()) - 1)];
					currentPrey.bonusType = bonus.type;
					currentPrey.bonusValue = bonus.initialValue + bonus.step * (currentPrey.bonusGrade - 1);
				}
	
				success = true;
			} else {
				return RETURNVALUE_CHOSENMONSTERISALREADYINUSE;
			}
		} else {
			return RETURNVALUE_PREYINTERNALERROR;
		}
	} else if ((currentPrey.state == STATE_SELECTION_WILDCARD) && state == STATE_ACTIVE) {
		bool contemMonstro = false;
		bool jaTemBonus = false;
		for (const auto& mname : g_prey.getPreyNames()) {
			if (strcasecmp(mname.c_str(), monsterName.c_str()) == 0) {
				contemMonstro = true;
				break;
			}
		}
		for (uint8_t slotId = 0; slotId < PREY_SLOTCOUNT; slotId++) {
			PreyData& anotherPrey = preyData[slotId];
			if (strcasecmp(anotherPrey.preyMonster.c_str(), monsterName.c_str()) == 0) {
				jaTemBonus = true;
				break;
			}
		}
		if (contemMonstro && !jaTemBonus) {
			currentPrey.preyMonster = monsterName;
			currentPrey.timeLeft = g_prey.getPreyDuration();
			if (currentPrey.bonusType == BONUS_NONE) {
				currentPrey.bonusGrade = uniform_random(1, 10);
				const BonusEntry& bonus = g_prey.getAvailableBonuses()[uniform_random(0, static_cast<int32_t>(g_prey.getAvailableBonuses().size()) - 1)];
				currentPrey.bonusType = bonus.type;
				currentPrey.bonusValue = bonus.initialValue + bonus.step * (currentPrey.bonusGrade - 1);
			}
			success = true;
		} else if (jaTemBonus) {
			return RETURNVALUE_CHOSENMONSTERISALREADYINUSE;
		} else {
			return RETURNVALUE_PREYINTERNALERROR;
		}
	} else if (state == STATE_INACTIVE || STATE_LOCKED) {
		currentPrey.preyList.clear();
		success = true;
	} else if (state == STATE_SELECTION_WILDCARD) {
		success = true;
	}

	if (success) {
		currentPrey.state = state;
		sendPreyData(preySlotId);
		return RETURNVALUE_NOERROR;
	}
	return RETURNVALUE_PREYINTERNALERROR;
}

void Player::setPreyData(std::vector<PreyData>&& preyData) 
{
	this->preyData = preyData;
}

void Player::serializePreyData(PropWriteStream& propWriteStream) const
{
	for (uint8_t preySlotId = 0; preySlotId < PREY_SLOTCOUNT; preySlotId++) {
		const PreyData& currentPrey = preyData[preySlotId];
		propWriteStream.write<uint8_t>(preySlotId);
		propWriteStream.write<uint64_t>(currentPrey.lastReroll);
		propWriteStream.write<PreyState>(currentPrey.state);
		if (currentPrey.state == STATE_ACTIVE) {
			propWriteStream.writeString(currentPrey.preyMonster);
			propWriteStream.write<uint16_t>(currentPrey.timeLeft);
			propWriteStream.write<BonusType>(currentPrey.bonusType);
			propWriteStream.write<uint16_t>(currentPrey.bonusValue);
			propWriteStream.write<uint8_t>(currentPrey.bonusGrade);
		} else if (currentPrey.state == STATE_SELECTION_CHANGE_MONSTER) {
			propWriteStream.write<BonusType>(currentPrey.bonusType);
			propWriteStream.write<uint16_t>(currentPrey.bonusValue);
			propWriteStream.write<uint8_t>(currentPrey.bonusGrade);
		}
		propWriteStream.write<uint8_t>(currentPrey.preyList.size());
		for (const std::string& preyName : currentPrey.preyList) {
			propWriteStream.writeString(preyName);
		}
	}
}

void Player::updateRerollPrice() {
	uint32_t price = g_prey.getRerollPricePerLevel() * level;
	sendRerollPrice(price);
}

ReturnValue Player::rerollPreyData(uint8_t preySlotId)
{
	if (preySlotId >= PREY_SLOTCOUNT) {
		return RETURNVALUE_PREYINTERNALERROR;
	}

	PreyData& currentPrey = preyData[preySlotId];
	if (static_cast<int64_t>(OTSYS_TIME() - currentPrey.lastReroll) < static_cast<int64_t>(g_prey.getTimeToFreeReroll() * 60 * 1000)) {
		uint64_t rerollPrice = g_prey.getRerollPricePerLevel() * level;
		if (!g_game.removeMoney(this, rerollPrice, 0, true)) {
			return RETURNVALUE_NOTENOUGHMONEYFORREROLL;
		} else {
			sendResourceData(RESOURCETYPE_BANK_GOLD, getBankBalance());
			sendResourceData(RESOURCETYPE_INVENTORY_GOLD, getMoney());
		}
	} else {
		currentPrey.lastReroll = OTSYS_TIME();
	}

	if (currentPrey.state == STATE_ACTIVE) {
		changePreyDataState(preySlotId, STATE_SELECTION_CHANGE_MONSTER);
		return RETURNVALUE_NOERROR;
	} else if (currentPrey.state == STATE_SELECTION || currentPrey.state == STATE_SELECTION_CHANGE_MONSTER) {
		changePreyDataState(preySlotId, currentPrey.state);
		return RETURNVALUE_NOERROR;
	}

	return RETURNVALUE_PREYINTERNALERROR;
}

ReturnValue Player::rerollPreyDataWildcard(uint8_t preySlotId)
{
	if (preySlotId >= PREY_SLOTCOUNT) {
		return RETURNVALUE_PREYINTERNALERROR;
	}

	uint64_t rerollPrice = 5;
	if (getBonusRerollCount() - rerollPrice < 0) {
		return RETURNVALUE_NOTENOUGHMONEYFORREROLL;
	}

	setBonusRerollCount(getBonusRerollCount() - rerollPrice);
	sendResourceData(RESOURCETYPE_PREY_BONUS_REROLLS, getBonusRerollCount());
	changePreyDataState(preySlotId, STATE_SELECTION_WILDCARD);
	return RETURNVALUE_NOERROR;
}

ReturnValue Player::rerollPreyBonus(uint8_t preySlotId)
{
	if (preySlotId >= PREY_SLOTCOUNT) {
		return RETURNVALUE_PREYINTERNALERROR;
	}

	if (bonusRerollCount <= 0) {
		return RETURNVALUE_NOAVAILABLEBONUSREROLL;
	}

	PreyData& currentPrey = preyData[preySlotId];
	if (currentPrey.state == STATE_ACTIVE || currentPrey.state == STATE_SELECTION_CHANGE_MONSTER) {
		const std::vector<BonusEntry>& availableBonuses = g_prey.getAvailableBonuses();
		std::vector<BonusEntry> possibles = availableBonuses;
		if (currentPrey.bonusGrade == 10) {
			auto it = std::find_if(possibles.begin(), possibles.end(), [&](const BonusEntry& v) { return v.type == currentPrey.bonusType; });
			if (it != possibles.end()) {
				possibles.erase(it);
			}
		} else {
			currentPrey.bonusGrade = uniform_random(currentPrey.bonusGrade + 1, 10);
		}

		const BonusEntry& randomBonus = possibles[uniform_random(0, possibles.size() - 1)];
		currentPrey.bonusType = randomBonus.type;
		currentPrey.bonusValue = randomBonus.initialValue + randomBonus.step * (currentPrey.bonusGrade - 1);
		currentPrey.timeLeft = g_prey.getPreyDuration();

		setBonusRerollCount(bonusRerollCount - 1);
		sendPreyData(preySlotId);
		sendResourceData(RESOURCETYPE_PREY_BONUS_REROLLS, getBonusRerollCount());
		return RETURNVALUE_NOERROR;
	}

	return RETURNVALUE_PREYINTERNALERROR;
}

uint16_t Player::getFreeRerollTime(uint8_t preySlotId)
{
	if (preySlotId >= PREY_SLOTCOUNT) {
		return 0;
	}

	PreyData& currentPrey = preyData[preySlotId];
	int64_t time = (static_cast<int64_t>(currentPrey.lastReroll) - OTSYS_TIME() + g_prey.getTimeToFreeReroll() * 60 * 1000) / 60 / 1000;
	return std::min<int64_t>(std::max<int64_t>(0, time), std::numeric_limits<uint16_t>::max());
}

uint16_t Player::getPreyTimeLeft(uint8_t preySlotId)
{
	if (preySlotId >= PREY_SLOTCOUNT) {
		return 0;
	}

	PreyData& currentPrey = preyData[preySlotId];
	return currentPrey.timeLeft;
}

void Player::decreasePreyTimeLeft(uint16_t amount)
{
	amount = std::abs(amount);
	for (uint8_t preySlotId = 0; preySlotId < PREY_SLOTCOUNT; preySlotId++) {
		PreyData& currentPrey = preyData[preySlotId];
		if (currentPrey.state == STATE_ACTIVE) {
			currentPrey.timeLeft = std::max(0, currentPrey.timeLeft - amount * 60);
			if (currentPrey.timeLeft > 0) {
				sendPreyTimeLeft(preySlotId);
			} else {
				changePreyDataState(preySlotId, STATE_SELECTION);
			}
		}
	}
}

uint16_t Player::getPreyBonusLoot(MonsterType* mType)
{
	if (!mType) {
		return 0;
	}

	for (uint8_t preySlotId = 0; preySlotId < PREY_SLOTCOUNT; preySlotId++) {
		PreyData& currentPrey = preyData[preySlotId];
		if (currentPrey.state == STATE_ACTIVE && currentPrey.bonusType == BONUS_IMPROVED_LOOT && currentPrey.preyMonster == mType->name) {
			return currentPrey.bonusValue;
		}
	}
	return 0;
}

bool Player::applyBonusExperience(uint64_t& gainExp, Creature* source)
{
	if (!source) {
		return false;
	}

	for (uint8_t preySlotId = 0; preySlotId < PREY_SLOTCOUNT; preySlotId++) {
		PreyData& currentPrey = preyData[preySlotId];
		if (currentPrey.state == STATE_ACTIVE && currentPrey.bonusType == BONUS_XP_BONUS && currentPrey.preyMonster == source->getName()) {
			gainExp *= (currentPrey.bonusValue / 100. + 1);
			return true;
		}
	}
	return false;
}

bool Player::applyBonusDamageBoost(CombatDamage& damage, Creature* opponent)
{
	if (!opponent) {
		return false;
	}

	for (uint8_t preySlotId = 0; preySlotId < PREY_SLOTCOUNT; preySlotId++) {
		PreyData& currentPrey = preyData[preySlotId];
		if (currentPrey.state == STATE_ACTIVE && currentPrey.bonusType == BONUS_DAMAGE_BOOST && currentPrey.preyMonster == opponent->getName()) {
			damage.primary.value += (damage.primary.value * currentPrey.bonusValue / 100.);
			damage.secondary.value += (damage.secondary.value * currentPrey.bonusValue / 100.);
			return true;
		}
	}
	return false;
}

bool Player::applyBonusDamageReduction(CombatDamage& damage, Creature* opponent)
{
	if (!opponent) {
		return false;
	}

	for (uint8_t preySlotId = 0; preySlotId < PREY_SLOTCOUNT; preySlotId++) {
		PreyData& currentPrey = preyData[preySlotId];
		if (currentPrey.state == STATE_ACTIVE && currentPrey.bonusType == BONUS_DAMAGE_REDUCTION && currentPrey.preyMonster == opponent->getName()) {
			damage.primary.value -= (damage.primary.value * currentPrey.bonusValue / 100.);
			damage.secondary.value -= (damage.secondary.value * currentPrey.bonusValue / 100.);
			return true;
		}
	}
	return false; 
}

bool Player::hasActivePreyBonus(BonusType type, Creature* source) 
{
	if (!source) {
		return false;
	}

	for (uint8_t preySlotId = 0; preySlotId < PREY_SLOTCOUNT; preySlotId++) {
		PreyData& currentPrey = preyData[preySlotId];
		if (currentPrey.state == STATE_ACTIVE && currentPrey.bonusType == type && currentPrey.preyMonster == source->getName()) {
			return true;
		}
	}
	return false;
}

void Player::setAutolootItem(uint16_t itemId, bool isLogin /* = false */)
{
	if (itemId == 0) {
		autoLootItemIds.clear();
		return;
	}

	int count = 0;
	for (const auto& id : autoLootItemIds) {
		if (id == itemId) {
			autoLootItemIds.erase(autoLootItemIds.begin() + count);
			return;
		}
		count++;
	}

	size_t limit = isVip() ? 20 : 10;
	if (autoLootItemIds.size() >= limit) {
		if (!isLogin)
			sendTextMessage(MESSAGE_STATUS_WARNING, "You have reached the limit of items in the list.");
		return;
	}

	autoLootItemIds.emplace_back(itemId);
}

std::map<uint16_t, Container*> Player::getContainers()
{
	uint16_t count = 0;
	std::map<uint16_t, Container*> contMap;
	for (int32_t i = CONST_SLOT_FIRST; i <= CONST_SLOT_LAST; i++) {
		Item* item = inventory[i];
		if (!item) {
			continue;
		}

		Container* container = item->getContainer();
		if (container) {
			contMap[++count] = container;
			for (ContainerIterator it = container->iterator(); it.hasNext(); it.advance()) {
				if ((*it)->getContainer()) {
					contMap[++count] = (*it)->getContainer();
				}
			}
		}
	}
	return contMap;
}

bool Player::removeFrags(uint8_t count)
{
	if (unjustifiedKills.empty()) {
		return false;
	}

	uint8_t passed = 0;
	std::vector<Kill> v_unjustifiedKills = unjustifiedKills;
	for (const auto& kill : v_unjustifiedKills) {
		if (passed >= count) {
			break;
		}

		if (kill.time > 0) {
			unjustifiedKills.erase(unjustifiedKills.begin() + passed);
			passed++;
		}

	}

	sendUnjustifiedPoints();
	return true;
}

void Player::addAccountStorageValue(const uint32_t key, const int32_t value)
{
	if (value != -1) {
		int32_t oldValue;
		getAccountStorageValue(key, oldValue);
		accountStorageMap[key] = value;
	} else {
		accountStorageMap.erase(key);
	}
}

bool Player::getAccountStorageValue(const uint32_t key, int32_t& value) const
{
	auto it = accountStorageMap.find(key);
	if (it == accountStorageMap.end()) {
		value = -1;
		return false;
	}

	value = it->second;
	return true;
}

bool Player::hasPvpActivity(Player* player, bool guildAndParty/* = false*/) const
{
	if (!g_game.isExpertPvpEnabled() || !player || player == const_cast<Player*>(this)) {
		return false;
	}

	if (hasAttacked(player) || player->hasAttacked(this)) {
		return true;
	}

	if (guildAndParty) {
		if (guild) {
			for (auto it : guild->getMembersOnline()) {
				if (it->hasPvpActivity(player)) {
					return true;
				}
			}
		}

		if (party) {
			for (auto it : party->getMembers()) {
				if (it->hasPvpActivity(player)) {
					return true;
				}
			}
		}
	}

	return false;
}

bool Player::isInPvpSituation()
{
	if (!isPvpSituation) {
		return false;
	}

	if (pzLocked || attackedSet.size() > 0) {
		return true;
	}

	for (auto it : g_game.getPlayers()) {
		Player* itPlayer = it.second;
		if (!itPlayer || itPlayer->isRemoved()) {
			continue;
		}

		if (itPlayer->hasAttacked(this)) {
			return true;
		}
	}
	
	return false;
}

void Player::sendPvpSquare(Creature* target, SquareColor_t squareColor)
{
	sendCreatureSquare(target, squareColor, 2);

	if (squareColor == SQ_COLOR_YELLOW) {
		sendCreatureSquare(this, squareColor, 2); // Only add to self if it's yellow.
	}
}

