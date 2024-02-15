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

#include <boost/range/adaptor/reversed.hpp>
#include "iologindata.h"
#include "configmanager.h"
#include "game.h"
#include "prey.h"
#include "scheduler.h"

extern ConfigManager g_config;
extern Game g_game;
extern Prey g_prey;

bool IOLoginData::loadAccountStoreHistory(uint32_t accountId)
{
	std::vector<StoreHistory> history;
	g_game.getAccountHistory(accountId, history);
	if (!history.empty()) {
		return true;
	}

	// carregar pela db
	std::ostringstream query;
	query << "SELECT `time`, `mode`, `amount`, `coinMode`, `description`, `cust` FROM `store_history` WHERE `accountid` = " << accountId;
	DBResult_ptr result = Database::getInstance().storeQuery(query.str());
	if (result) {
		do {
			history.emplace_back(
				result->getNumber<uint32_t>("time"),
				static_cast<uint8_t>(result->getNumber<uint32_t>("mode")),
				result->getNumber<uint32_t>("amount"),
				static_cast<uint8_t>(result->getNumber<uint32_t>("coinMode")),
				result->getString("description"),
				result->getNumber<int32_t>("cust")
			);
			history.shrink_to_fit();

		} while (result->next());
	}

	g_game.loadAccountStoreHistory(accountId, history);
	return true;
}

Account IOLoginData::loadAccount(uint32_t accno)
{
	Account account;

	Database& db = Database::getInstance();

	std::ostringstream query;
	query << "SELECT `id`, `coins`, `tournamentBalance`, `proxy_id`, `name`, `password`, `type`, `premdays`, `vip_time`, `lastday` FROM `accounts` WHERE `id` = " << accno;
	DBResult_ptr result = db.storeQuery(query.str());
	if (!result) {
		return account;
	}

	account.id = result->getNumber<uint32_t>("id");
	account.name = result->getString("name");
	account.accountType = static_cast<AccountType_t>(result->getNumber<int32_t>("type"));
	account.premiumDays = result->getNumber<uint16_t>("premdays");
	account.viptime = result->getNumber<uint32_t>("vip_time");
	account.lastDay = result->getNumber<time_t>("lastday");
	account.coinBalance = result->getNumber<uint32_t>("coins");
	account.tournamentCoinBalance = result->getNumber<uint32_t>("tournamentBalance");
	account.proxyId = result->getNumber<uint16_t>("proxy_id");
	return account;
}

bool IOLoginData::saveAccount(const Account& acc)
{
	std::ostringstream query;
	query << "UPDATE `accounts` SET `premdays` = " << acc.premiumDays << ", `vip_time` = " << acc.viptime << ", `lastday` = " << acc.lastDay << " WHERE `id` = " << acc.id;
	return Database::getInstance().executeQuery(query.str());
}

std::string decodeSecret(const std::string& secret)
{
	// simple base32 decoding
	std::string key;
	key.reserve(10);

	uint32_t buffer = 0, left = 0;
	for (const auto& ch : secret) {
		buffer <<= 5;
		if (ch >= 'A' && ch <= 'Z') {
			buffer |= (ch & 0x1F) - 1;
		} else if (ch >= '2' && ch <= '7') {
			buffer |= ch - 24;
		} else {
			// if a key is broken, return empty and the comparison
			// will always be false since the token must not be empty
			return {};
		}

		left += 5;
		if (left >= 8) {
			left -= 8;
			key.push_back(static_cast<char>(buffer >> left));
		}
	}

	return key;
}

bool IOLoginData::loginserverAuthentication(const std::string& name, const std::string& password, Account& account)
{
	Database& db = Database::getInstance();

	std::ostringstream query;
	query << "SELECT `id`, `name`, `email`, `password`, `secret`, `type`, `proxy_id`, `premdays`, `vip_time`, `lastday` FROM `accounts` WHERE `name` = " << db.escapeString(name);
	DBResult_ptr result = db.storeQuery(query.str());
	if (!result) {
		return false;
	}

	if (transformToSHA1(password) != result->getString("password")) {
		return false;
	}

	account.id = result->getNumber<uint32_t>("id");
	account.name = result->getString("name");
	account.key = decodeSecret(result->getString("secret"));
	account.accountType = static_cast<AccountType_t>(result->getNumber<int32_t>("type"));
	account.premiumDays = result->getNumber<uint16_t>("premdays");
	account.viptime = result->getNumber<uint32_t>("vip_time");
	account.lastDay = result->getNumber<time_t>("lastday");
	account.proxyId = result->getNumber<uint16_t>("proxy_id");

	query.str(std::string());
	query << "SELECT `name`, `deletion` FROM `players` WHERE `account_id` = " << account.id;
	result = db.storeQuery(query.str());
	if (result) {
		do {
			if (result->getNumber<uint64_t>("deletion") == 0) {
				account.characters.push_back(result->getString("name"));
			}
		} while (result->next());
		std::sort(account.characters.begin(), account.characters.end());
	}
	return true;
}

bool IOLoginData::loginserverAuthenticationEmail(const std::string& name, const std::string& password, Account& account)
{
	Database& db = Database::getInstance();

	std::ostringstream query;
	query << "SELECT `id`, `name`, `email`, `password`, `secret`, `type`, `premdays`, `vip_time`, `lastday` FROM `accounts` WHERE `email` = " << db.escapeString(name);
	DBResult_ptr result = db.storeQuery(query.str());
	if (!result) {
		return false;
	}

	if (transformToSHA1(password) != result->getString("password")) {
		return false;
	}

	account.id = result->getNumber<uint32_t>("id");
	account.name = result->getString("name");
	account.key = decodeSecret(result->getString("secret"));
	account.accountType = static_cast<AccountType_t>(result->getNumber<int32_t>("type"));
	account.premiumDays = result->getNumber<uint16_t>("premdays");
	account.viptime = result->getNumber<uint32_t>("vip_time");
	account.lastDay = result->getNumber<time_t>("lastday");

	query.str(std::string());
	query << "SELECT `name`, `deletion` FROM `players` WHERE `account_id` = " << account.id;
	result = db.storeQuery(query.str());
	if (result) {
		do {
			if (result->getNumber<uint64_t>("deletion") == 0) {
				account.characters.push_back(result->getString("name"));
			}
		} while (result->next());
		std::sort(account.characters.begin(), account.characters.end());
	}
	return true;
}

uint32_t IOLoginData::gameworldAuthentication(const std::string& accountName, const std::string& password, std::string& characterName, std::string& token, uint32_t tokenTime)
{
	Database& db = Database::getInstance();

	std::ostringstream query;
	query << "SELECT `id`, `email`, `password`, `secret` FROM `accounts` WHERE `name` = " << db.escapeString(accountName);
	DBResult_ptr result = db.storeQuery(query.str());
	if (!result) {
		return 0;
	}

	std::string secret = decodeSecret(result->getString("secret"));
	if (!secret.empty()) {
		if (token.empty()) {
			return 0;
		}

		bool tokenValid = token == generateToken(secret, tokenTime) || token == generateToken(secret, tokenTime - 1) || token == generateToken(secret, tokenTime + 1);
		if (!tokenValid) {
			return 0;
		}
	}

	if (transformToSHA1(password) != result->getString("password")) {
		return 0;
	}

	uint32_t accountId = result->getNumber<uint32_t>("id");

	query.str(std::string());
	query << "SELECT `account_id`, `name`, `deletion` FROM `players` WHERE `name` = " << db.escapeString(characterName);
	result = db.storeQuery(query.str());
	if (!result) {
		return 0;
	}

	if (result->getNumber<uint32_t>("account_id") != accountId || result->getNumber<uint64_t>("deletion") != 0) {
		return 0;
	}
	characterName = result->getString("name");
	return accountId;
}

uint32_t IOLoginData::gameworldAuthenticationEmail(const std::string& accountName, const std::string& password, std::string& characterName, std::string& token, uint32_t tokenTime)
{
	Database& db = Database::getInstance();

	std::ostringstream query;
	query << "SELECT `id`, `name`, `password`, `secret` FROM `accounts` WHERE `email` = " << db.escapeString(accountName);
	DBResult_ptr result = db.storeQuery(query.str());
	if (!result) {
		return 0;
	}

	std::string secret = decodeSecret(result->getString("secret"));
	if (!secret.empty()) {
		if (token.empty()) {
			return 0;
		}

		bool tokenValid = token == generateToken(secret, tokenTime) || token == generateToken(secret, tokenTime - 1) || token == generateToken(secret, tokenTime + 1);
		if (!tokenValid) {
			return 0;
		}
	}

	if (transformToSHA1(password) != result->getString("password")) {
		return 0;
	}

	uint32_t accountId = result->getNumber<uint32_t>("id");

	query.str(std::string());
	query << "SELECT `account_id`, `name`, `deletion` FROM `players` WHERE `name` = " << db.escapeString(characterName);
	result = db.storeQuery(query.str());
	if (!result) {
		return 0;
	}

	if (result->getNumber<uint32_t>("account_id") != accountId || result->getNumber<uint64_t>("deletion") != 0) {
		return 0;
	}
	characterName = result->getString("name");
	return accountId;
}

AccountType_t IOLoginData::getAccountType(uint32_t accountId)
{
	Database& db = Database::getInstance();

	std::ostringstream query;
	query << "SELECT `type` FROM `accounts` WHERE `id` = " << accountId;
	DBResult_ptr result = db.storeQuery(query.str());
	if (!result) {
		return ACCOUNT_TYPE_NORMAL;
	}
	return static_cast<AccountType_t>(result->getNumber<uint16_t>("type"));
}

void IOLoginData::setAccountType(uint32_t accountId, AccountType_t accountType)
{
	Database& db = Database::getInstance();

	std::ostringstream query;
	query << "UPDATE `accounts` SET `type` = " << static_cast<uint16_t>(accountType) << " WHERE `id` = " << accountId;
	db.executeQuery(query.str());
}

void IOLoginData::updateOnlineStatus(uint32_t guid, bool login)
{
	if (g_config.getBoolean(ConfigManager::ALLOW_CLONES)) {
		return;
	}

	Database& db = Database::getInstance();

	std::ostringstream query;
	if (login) {
		query << "INSERT INTO `players_online` VALUES (" << guid << ')';
	} else {
		query << "DELETE FROM `players_online` WHERE `player_id` = " << guid;
	}

	db.executeQuery(query.str());
}

bool IOLoginData::preloadPlayer(Player* player, const std::string& name)
{
	Database& db = Database::getInstance();

	std::ostringstream query;
	query << "SELECT `id`, `account_id`, `group_id`, `deletion`, (SELECT `type` FROM `accounts` WHERE `accounts`.`id` = `account_id`) AS `account_type`, (SELECT `coins` FROM `accounts` WHERE `accounts`.`id` = `account_id`) AS `coinbalance`, (SELECT `tournamentBalance` FROM `accounts` WHERE `accounts`.`id` = `account_id`) AS `tournamentBalance`";
	if (!g_config.getBoolean(ConfigManager::FREE_PREMIUM)) {
		query << ", (SELECT `premdays` FROM `accounts` WHERE `accounts`.`id` = `account_id`) AS `premium_days`";
	}
	query << ", (SELECT `vip_time` FROM `accounts` WHERE `accounts`.`id` = `account_id`) AS `vip_time`";
	query << " FROM `players` WHERE `name` = " << db.escapeString(name);
	DBResult_ptr result = db.storeQuery(query.str());
	if (!result) {
		return false;
	}

	if (result->getNumber<uint64_t>("deletion") != 0) {
		return false;
	}

	player->setGUID(result->getNumber<uint32_t>("id"));
	Group* group = g_game.groups.getGroup(result->getNumber<uint16_t>("group_id"));
	if (!group) {
		std::cout << "[Error - IOLoginData::preloadPlayer] " << player->name << " has Group ID " << result->getNumber<uint16_t>("group_id") << " which doesn't exist." << std::endl;
		return false;
	}
	player->setGroup(group);
	player->accountNumber = result->getNumber<uint32_t>("account_id");
	player->accountType = static_cast<AccountType_t>(result->getNumber<uint16_t>("account_type"));
	player->coinBalance = result->getNumber<uint32_t>("coinbalance");
	player->tournamentCoinBalance = result->getNumber<uint32_t>("tournamentBalance");
	if (!g_config.getBoolean(ConfigManager::FREE_PREMIUM)) {
		player->premiumDays = result->getNumber<uint16_t>("premium_days");
	} else {
		player->premiumDays = std::numeric_limits<uint16_t>::max();
	}
	player->viptime = result->getNumber<uint32_t>("vip_time");
	query.str(std::string());
	query << "SELECT `guild_id`, `rank_id`, `nick` FROM `guild_membership` WHERE `player_id` = " << player->getGUID();
	if ((result = db.storeQuery(query.str()))) {
		uint32_t guildId = result->getNumber<uint32_t>("guild_id");
		uint32_t playerRankId = result->getNumber<uint32_t>("rank_id");
		player->guildNick = result->getString("nick");

		Guild* guild = g_game.getGuild(guildId);
		if (!guild) {
			guild = IOGuild::loadGuild(guildId);
			if (guild) {
				g_game.addGuild(guild);
			} else {
				std::cout << "[Warning - IOLoginData::loadPlayer] " << player->name << " has Guild ID " << guildId << " which doesn't exist" << std::endl;
			}
		}

		if (guild) {
			player->guild = guild;
			GuildRank_ptr rank = guild->getRankById(playerRankId);
			if (!rank) {
				query.str(std::string());
				query << "SELECT `id`, `name`, `level` FROM `guild_ranks` WHERE `id` = " << playerRankId;

				if ((result = db.storeQuery(query.str()))) {
					guild->addRank(result->getNumber<uint32_t>("id"), result->getString("name"), result->getNumber<uint16_t>("level"));
				}

				rank = guild->getRankById(playerRankId);
				if (!rank) {
					player->guild = nullptr;
				}
			}

			player->guildRank = rank;

			IOGuild::getWarList(guildId, player->guildWarVector);

			query.str(std::string());
			query << "SELECT COUNT(*) AS `members` FROM `guild_membership` WHERE `guild_id` = " << guildId;
			if ((result = db.storeQuery(query.str()))) {
				guild->setMemberCount(result->getNumber<uint32_t>("members"));
			}
		}
	}

	return true;
}

bool IOLoginData::loadPlayerById(Player* player, uint32_t id)
{
	Database& db = Database::getInstance();

	std::ostringstream query;
	query << "SELECT `id`, `name`, `account_id`, `group_id`, `sex`, `vocation`, `experience`, `level`, `maglevel`, `health`, `healthmax`, `blessings1`, `blessings2`, `blessings3`, `blessings4`, `blessings5`, `blessings6`, `blessings7`, `blessings8`, `mana`, `manamax`, `manaspent`, `soul`, `lookbody`, `lookfeet`, `lookmount`, `lookhead`, `looklegs`, `looktype`, `lookaddons`, `posx`, `posy`, `posz`, `cap`, `lastlogin`, `lastlogout`, `lastip`, `conditions`, `skulltime`, `skull`, `town_id`, `balance`, `bonusrerollcount`, `offlinetraining_time`, `offlinetraining_skill`, `stamina`, `skill_fist`, `skill_fist_tries`, `skill_club`, `skill_club_tries`, `skill_sword`, `skill_sword_tries`, `skill_axe`, `skill_axe_tries`, `skill_dist`, `skill_dist_tries`, `skill_shielding`, `skill_shielding_tries`, `skill_fishing`, `skill_fishing_tries`, `skill_critical_hit_chance`, `skill_critical_hit_chance_tries`, `skill_critical_hit_damage`, `skill_critical_hit_damage_tries`, `skill_life_leech_chance`, `skill_life_leech_chance_tries`, `skill_life_leech_amount`, `skill_life_leech_amount_tries`, `skill_mana_leech_chance`, `skill_mana_leech_chance_tries`, `skill_mana_leech_amount`,  `skill_mana_leech_amount_tries`, `xpboost_value`, `xpboost_stamina`, `instantrewardtokens`, `critical`, `charmpoints`, `direction`, `quick_loot_fallback`, `charmExpansion`, `bestiarykills`, `bestiaryTracker`, `charms`, `autoloot`, `lastday` FROM `players` WHERE `id` = " << id;
	return loadPlayer(player, db.storeQuery(query.str()));
}

bool IOLoginData::loadPlayerByName(Player* player, const std::string& name)
{
	Database& db = Database::getInstance();
	
	std::ostringstream query;
	query << "SELECT `id`, `name`, `account_id`, `group_id`, `sex`, `vocation`, `experience`, `level`, `maglevel`, `health`, `healthmax`, `blessings1`, `blessings2`, `blessings3`, `blessings4`, `blessings5`, `blessings6`, `blessings7`, `blessings8`, `mana`, `manamax`, `manaspent`, `soul`, `lookbody`, `lookfeet`, `lookmount`, `lookhead`, `looklegs`, `looktype`, `lookaddons`, `posx`, `posy`, `posz`, `cap`, `lastlogin`, `lastlogout`, `lastip`, `conditions`, `skulltime`, `skull`, `town_id`, `balance`, `bonusrerollcount`, `offlinetraining_time`, `offlinetraining_skill`, `stamina`, `skill_fist`, `skill_fist_tries`, `skill_club`, `skill_club_tries`, `skill_sword`, `skill_sword_tries`, `skill_axe`, `skill_axe_tries`, `skill_dist`, `skill_dist_tries`, `skill_shielding`, `skill_shielding_tries`, `skill_fishing`, `skill_fishing_tries`, `skill_critical_hit_chance`, `skill_critical_hit_chance_tries`, `skill_critical_hit_damage`, `skill_critical_hit_damage_tries`, `skill_life_leech_chance`, `skill_life_leech_chance_tries`, `skill_life_leech_amount`, `skill_life_leech_amount_tries`, `skill_mana_leech_chance`, `skill_mana_leech_chance_tries`, `skill_mana_leech_amount`, `skill_mana_leech_amount_tries`, `xpboost_stamina`, `xpboost_value`,  `instantrewardtokens`, `critical`, `charmpoints`, `direction`, `quick_loot_fallback`, `charmExpansion`, `bestiarykills`, `bestiaryTracker`, `charms`, `autoloot`, `lastday` FROM `players` WHERE `name` = " << db.escapeString(name);
	return loadPlayer(player, db.storeQuery(query.str()));
}

bool IOLoginData::loadPlayer(Player* player, DBResult_ptr result)
{
	if (!result) {
		return false;
	}

	Database& db = Database::getInstance();

	uint32_t accno = result->getNumber<uint32_t>("account_id");
	Account acc = loadAccount(accno);

	player->setGUID(result->getNumber<uint32_t>("id"));
	player->name = result->getString("name");
	player->accountNumber = accno;

	player->accountType = acc.accountType;
	player->proxyId = acc.proxyId;
	player->coinBalance = acc.coinBalance;
	player->tournamentCoinBalance = acc.tournamentCoinBalance;

	std::cout << "Loading " << player->getName() << "..." << std::endl;

	if (g_config.getBoolean(ConfigManager::FREE_PREMIUM)) {
		player->premiumDays = std::numeric_limits<uint16_t>::max();
	} else {
		player->premiumDays = acc.premiumDays;
	}

	player->viptime = acc.viptime;
	player->coinBalance = IOAccount::getCoinBalance(player->getAccount());
	player->tournamentCoinBalance = IOAccount::getCoinBalance(player->getAccount(), COIN_TYPE_TOURNAMENT);
	
	Group* group = g_game.groups.getGroup(result->getNumber<uint16_t>("group_id"));
	if (!group) {
		std::cout << "[Error - IOLoginData::loadPlayer] " << player->name << " has Group ID " << result->getNumber<uint16_t>("group_id") << " which doesn't exist" << std::endl;
		return false;
	}
	player->setGroup(group);

	player->bankBalance = result->getNumber<uint64_t>("balance");

	player->quickLootFallbackToMainContainer = result->getNumber<bool>("quick_loot_fallback");
	player->charmExpansion = result->getNumber<bool>("charmExpansion");

	player->setSex(static_cast<PlayerSex_t>(result->getNumber<uint16_t>("sex")));
	player->level = std::max<uint32_t>(1, result->getNumber<uint32_t>("level"));

	uint64_t experience = result->getNumber<uint64_t>("experience");

	uint64_t currExpCount = Player::getExpForLevel(player->level);
	uint64_t nextExpCount = Player::getExpForLevel(player->level + 1);
	if (experience < currExpCount || experience > nextExpCount) {
		experience = currExpCount;
	}

	player->experience = experience;

	player->charmPoints = result->getNumber<uint32_t>("charmpoints");

	if (currExpCount < nextExpCount) {
		player->levelPercent = Player::getPercentLevel(player->experience - currExpCount, nextExpCount - currExpCount);
	} else {
		player->levelPercent = 0;
	}

	player->soul = result->getNumber<uint16_t>("soul");
	player->capacity = result->getNumber<uint32_t>("cap") * 100;
	for (int i = 1; i <= 8; i++) {
		std::ostringstream ss;
		ss << "blessings" << i;
		player->addBlessing(i, result->getNumber<uint16_t>(ss.str()));
	}

	unsigned long conditionsSize;
	const char* conditions = result->getStream("conditions", conditionsSize);
	PropStream propStream;
	propStream.init(conditions, conditionsSize);

	Condition* condition = Condition::createCondition(propStream);
	while (condition) {
		if (condition->unserialize(propStream)) {
			player->storedConditionList.push_front(condition);
		} else {
			delete condition;
		}
		condition = Condition::createCondition(propStream);
	}

	//load bestiary map
	unsigned long attrSize;
	const char* attr = result->getStream("bestiarykills", attrSize);
	propStream.init(attr, attrSize);

	size_t bestiary_sizes;
	if (propStream.read<size_t>(bestiary_sizes)) {
		//player->bestiaryKills.reserve(bestiary_sizes);

		uint16_t race_id;
		int32_t kill_value;
		int8_t gained_value;
		while (propStream.read<uint16_t>(race_id) && propStream.read<int32_t>(kill_value) && propStream.read<int8_t>(gained_value)) {
			player->addBestiaryKill(race_id, kill_value, gained_value == 0x01);
		}
	}

	//load bestiary tracker
	attr = result->getStream("bestiaryTracker", attrSize);
	propStream.init(attr, attrSize);

	size_t bestiaryTracker_sizes;
	if (propStream.read<size_t>(bestiaryTracker_sizes)) {
		player->bestiaryTracker.reserve(bestiaryTracker_sizes);
		uint16_t race_id_value;
		while (propStream.read<uint16_t>(race_id_value)) {
			player->manageMonsterTracker(race_id_value);
		}
	}

	//load charms map
	attr = result->getStream("charms", attrSize);
	propStream.init(attr, attrSize);

	size_t charm_sizes;
	if (propStream.read<size_t>(charm_sizes)) {
		player->charmMap.reserve(charm_sizes);
		uint8_t charm_id;
		uint16_t race_id_value;
		while (propStream.read<uint8_t>(charm_id) && propStream.read<uint16_t>(race_id_value)) {
			player->charmMap[charm_id] = race_id_value;
		}
	}

	//load autoloot map
	attr = result->getStream("autoloot", attrSize);
	propStream.init(attr, attrSize);

	size_t autoloot_sizes;
	if (propStream.read<size_t>(autoloot_sizes)) {
		uint16_t itemid_value;
		while (propStream.read<uint16_t>(itemid_value)) {
			player->setAutolootItem(itemid_value, true);
		}
	}

	if (!player->setVocation(result->getNumber<uint16_t>("vocation"))) {
		std::cout << "[Error - IOLoginData::loadPlayer] " << player->name << " has Vocation ID " << result->getNumber<uint16_t>("vocation") << " which doesn't exist" << std::endl;
		return false;
	}

	player->mana = result->getNumber<uint32_t>("mana");
	player->manaMax = result->getNumber<uint32_t>("manamax");
	player->magLevel = result->getNumber<uint32_t>("maglevel");

	uint64_t nextManaCount = player->vocation->getReqMana(player->magLevel + 1);
	uint64_t manaSpent = result->getNumber<uint64_t>("manaspent");
	if (manaSpent > nextManaCount) {
		manaSpent = 0;
	}

	player->manaSpent = manaSpent;
	player->magLevelPercent = Player::getPercentLevel(player->manaSpent, nextManaCount);

	player->health = result->getNumber<int32_t>("health");
	player->healthMax = result->getNumber<int32_t>("healthmax");

	player->defaultOutfit.lookType = result->getNumber<uint16_t>("looktype");
	player->defaultOutfit.lookHead = result->getNumber<uint16_t>("lookhead");
	player->defaultOutfit.lookBody = result->getNumber<uint16_t>("lookbody");
	player->defaultOutfit.lookLegs = result->getNumber<uint16_t>("looklegs");
	player->defaultOutfit.lookFeet = result->getNumber<uint16_t>("lookfeet");
	player->defaultOutfit.lookMount = result->getNumber<uint16_t>("lookmount");
	player->defaultOutfit.lookAddons = result->getNumber<uint16_t>("lookaddons");
	player->defaultOutfit.lookMountHead = result->getNumber<uint16_t>("lookmounthead");
	player->defaultOutfit.lookMountBody = result->getNumber<uint16_t>("lookmountbody");
	player->defaultOutfit.lookMountLegs = result->getNumber<uint16_t>("lookmountlegs");
	player->defaultOutfit.lookMountFeet = result->getNumber<uint16_t>("lookmountfeet");
	player->defaultOutfit.lookFamiliarsType = result->getNumber<uint16_t>("lookfamiliarstype");
	player->currentOutfit = player->defaultOutfit;
	player->direction = static_cast<Direction> (result->getNumber<uint16_t>("direction"));
	player->setBonusRerollCount(result->getNumber<int64_t>("bonusrerollcount"));

	player->critical = result->getNumber<uint64_t>("critical");

	if (g_game.getWorldType() != WORLD_TYPE_PVP_ENFORCED) {
		const time_t skullSeconds = result->getNumber<time_t>("skulltime") - OS_TIME(nullptr);
		if (skullSeconds > 0) {
			//ensure that we round up the number of ticks
			player->skullTicks = (skullSeconds + 2);

			uint16_t skull = result->getNumber<uint16_t>("skull");
			if (skull == SKULL_RED) {
				player->skull = SKULL_RED;
			} else if (skull == SKULL_BLACK) {
				player->skull = SKULL_BLACK;
			}
		}
	}

	player->loginPosition.x = result->getNumber<uint16_t>("posx");
	player->loginPosition.y = result->getNumber<uint16_t>("posy");
	player->loginPosition.z = result->getNumber<uint16_t>("posz");

	player->lastLoginSaved = result->getNumber<time_t>("lastlogin");
	player->lastLogout = result->getNumber<time_t>("lastlogout");

	player->lastday = result->getNumber<time_t>("lastday");
	player->updateSkullTicks();

	player->offlineTrainingTime = result->getNumber<int32_t>("offlinetraining_time") * 1000;
	player->offlineTrainingSkill = result->getNumber<int32_t>("offlinetraining_skill");

	Town* town = g_game.map.towns.getTown(result->getNumber<uint32_t>("town_id"));
	if (!town) {
		std::cout << "[Error - IOLoginData::loadPlayer] " << player->name << " has Town ID " << result->getNumber<uint32_t>("town_id") << " which doesn't exist" << std::endl;
		return false;
	}

	player->town = town;

	const Position& loginPos = player->loginPosition;
	if (loginPos.x == 0 && loginPos.y == 0 && loginPos.z == 0) {
		player->loginPosition = player->getTemplePosition();
	}

	player->staminaMinutes = result->getNumber<uint16_t>("stamina");

	player->setStoreXpBoost(result->getNumber<uint16_t>("xpboost_value"));
	player->setExpBoostStamina(result->getNumber<uint16_t>("xpboost_stamina"));

	player->setInstantRewardTokens(result->getNumber<uint64_t>("instantrewardtokens"));

	static const std::string skillNames[] = {"skill_fist", "skill_club", "skill_sword", "skill_axe", "skill_dist", "skill_shielding", "skill_fishing", "skill_critical_hit_chance", "skill_critical_hit_damage", "skill_life_leech_chance", "skill_life_leech_amount", "skill_mana_leech_chance", "skill_mana_leech_amount"};
	static const std::string skillNameTries[] = {"skill_fist_tries", "skill_club_tries", "skill_sword_tries", "skill_axe_tries", "skill_dist_tries", "skill_shielding_tries", "skill_fishing_tries", "skill_critical_hit_chance_tries", "skill_critical_hit_damage_tries", "skill_life_leech_chance_tries", "skill_life_leech_amount_tries", "skill_mana_leech_chance_tries", "skill_mana_leech_amount_tries"};
	static constexpr size_t size = sizeof(skillNames) / sizeof(std::string);
	for (uint8_t i = 0; i < size; ++i) {
		uint16_t skillLevel = result->getNumber<uint16_t>(skillNames[i]);
		uint64_t skillTries = result->getNumber<uint64_t>(skillNameTries[i]);
		uint64_t nextSkillTries = player->vocation->getReqSkillTries(i, skillLevel + 1);
		if (skillTries > nextSkillTries) {
			skillTries = 0;
		}

		player->skills[i].level = skillLevel;
		player->skills[i].tries = skillTries;
		player->skills[i].percent = Player::getPercentLevel(skillTries, nextSkillTries);
	}

	std::ostringstream query;
	query << "SELECT `player_id`, `name` FROM `player_spells` WHERE `player_id` = " << player->getGUID();
	if ((result = db.storeQuery(query.str()))) {
		do {
			player->learnedInstantSpellList.emplace_front(result->getString("name"));
		} while (result->next());
	}

	query.str(std::string());
	query << "SELECT `player_id`, `time`, `target`, `unavenged` FROM `player_kills` WHERE `player_id` = " << player->getGUID();
	if ((result = db.storeQuery(query.str()))) {
		do {
			time_t killTime = result->getNumber<time_t>("time");
			if ((OS_TIME(nullptr) - killTime) <= g_config.getNumber(ConfigManager::FRAG_TIME)) {
				player->unjustifiedKills.emplace_back(result->getNumber<uint32_t>("target"), killTime, result->getNumber<bool>("unavenged"));
			}
		} while (result->next());
	}

	//load inventory items
	ItemMap itemMap;
	query.str(std::string());
	query << "SELECT `pid`, `sid`, `itemtype`, `count`, `attributes` FROM `player_items` WHERE `player_id` = " << player->getGUID() << " ORDER BY `sid` DESC";
	std::vector<std::pair<uint8_t, Container*>> openContainersList;

	if ((result = db.storeQuery(query.str()))) {
		loadItems(itemMap, result);

		for (ItemMap::const_reverse_iterator it = itemMap.rbegin(), end = itemMap.rend(); it != end; ++it) {
			const std::pair<Item*, int32_t>& pair = it->second;
			Item* item = pair.first;
			int32_t pid = pair.second;
			if (pid >= 1 && pid <= 11) {
				player->internalAddThing(pid, item);
			} else {
				ItemMap::const_iterator it2 = itemMap.find(pid);
				if (it2 == itemMap.end()) {
					continue;
				}

				Container* container = it2->second.first->getContainer();
				if (container) {
					container->internalAddThing(item);
				}
			}

			// arrumando bug do wrap
			bool isWrapable = item->isWrapable() || item->getID() == TRANSFORM_BOX_ID;
			if (item->hasAttribute(ITEM_ATTRIBUTE_ACTIONID) && isWrapable) {
				uint16_t newId = item->getID() == TRANSFORM_BOX_ID ? item->getIntAttr(ITEM_ATTRIBUTE_ACTIONID) : Item::items[item->getID()].wrapableTo;;
				item->setIntAttr(ITEM_ATTRIBUTE_WRAPID, newId);
				item->removeAttribute(ITEM_ATTRIBUTE_ACTIONID);
			}

			Container* itemContainer = item->getContainer();
			if (itemContainer) {
				uint8_t cid = item->getIntAttr(ITEM_ATTRIBUTE_OPENED);
				if (cid > 0) {
					openContainersList.emplace_back(std::make_pair(cid, itemContainer));
				}
				if (item->hasAttribute(ITEM_ATTRIBUTE_QUICKLOOTCONTAINER)) {
					uint32_t flags = item->getIntAttr(ITEM_ATTRIBUTE_QUICKLOOTCONTAINER);
					for (uint8_t category = OBJECTCATEGORY_FIRST; category <= OBJECTCATEGORY_LAST; category++) {
						if (hasBitSet(1 << category, flags)) {
							player->setLootContainer((ObjectCategory_t)category, itemContainer, true);
						}
					}
				}
			}

		}
	}

	std::sort(openContainersList.begin(), openContainersList.end(), [](const std::pair<uint8_t, Container*> &left, const std::pair<uint8_t, Container*> &right) {
		return left.first < right.first;
	});

	for (auto& it : openContainersList) {
		player->addContainer(it.first - 1, it.second);
		g_scheduler.addEvent(createSchedulerTask(((it.first) * 50), std::bind(&Game::playerUpdateContainer, &g_game, player->getGUID(), it.first - 1)));
	}

	// Store Inbox
	if (!player->inventory[CONST_SLOT_STORE_INBOX]) {
		player->internalAddThing(CONST_SLOT_STORE_INBOX, Item::CreateItem(ITEM_STORE_INBOX));
	}

	//load depot items
	itemMap.clear();

	query.str(std::string());
	query << "SELECT `pid`, `sid`, `itemtype`, `count`, `attributes` FROM `player_depotitems` WHERE `player_id` = " << player->getGUID() << " ORDER BY `sid` DESC LIMIT 2000";
	if ((result = db.storeQuery(query.str()))) {
		loadItems(itemMap, result);

		for (ItemMap::const_reverse_iterator it = itemMap.rbegin(), end = itemMap.rend(); it != end; ++it) {
			const std::pair<Item*, int32_t>& pair = it->second;
			Item* item = pair.first;

			int32_t pid = pair.second;
			if (pid >= 0 && pid < 100) {
				DepotChest* depotChest = player->getDepotChest(pid, true);
				if (depotChest) {
					depotChest->internalAddThing(item);
				}
			} else {
				ItemMap::const_iterator it2 = itemMap.find(pid);
				if (it2 == itemMap.end()) {
					continue;
				}

				Container* container = it2->second.first->getContainer();
				if (container) {
					container->internalAddThing(item);
				}
			}

			// arrumando bug do wrap
			bool isWrapable = item->isWrapable() || item->getID() == TRANSFORM_BOX_ID;
			if (item->hasAttribute(ITEM_ATTRIBUTE_ACTIONID) && isWrapable) {
				uint16_t newId = item->getID() == TRANSFORM_BOX_ID ? item->getIntAttr(ITEM_ATTRIBUTE_ACTIONID) : Item::items[item->getID()].wrapableTo;;
				item->setIntAttr(ITEM_ATTRIBUTE_WRAPID, newId);
				item->removeAttribute(ITEM_ATTRIBUTE_ACTIONID);
			}
		}
	}

	//load inbox items
	itemMap.clear();

	query.str(std::string());
	query << "SELECT `pid`, `sid`, `itemtype`, `count`, `attributes` FROM `player_inboxitems` WHERE `player_id` = " << player->getGUID() << " ORDER BY `sid` DESC LIMIT 500";
	if ((result = db.storeQuery(query.str()))) {
		loadItems(itemMap, result);

		for (ItemMap::const_reverse_iterator it = itemMap.rbegin(), end = itemMap.rend(); it != end; ++it) {
			const std::pair<Item*, int32_t>& pair = it->second;
			Item* item = pair.first;
			int32_t pid = pair.second;

			if (pid >= 0 && pid < 100) {
				player->getInbox()->internalAddThing(item);
			} else {
				ItemMap::const_iterator it2 = itemMap.find(pid);

				if (it2 == itemMap.end()) {
					continue;
				}

				Container* container = it2->second.first->getContainer();
				if (container) {
					container->internalAddThing(item);
				}
			}
			// arrumando bug do wrap
			bool isWrapable = item->isWrapable() || item->getID() == TRANSFORM_BOX_ID;
			if (item->hasAttribute(ITEM_ATTRIBUTE_ACTIONID) && isWrapable) {
				uint16_t newId = item->getID() == TRANSFORM_BOX_ID ? item->getIntAttr(ITEM_ATTRIBUTE_ACTIONID) : Item::items[item->getID()].wrapableTo;;
				item->setIntAttr(ITEM_ATTRIBUTE_WRAPID, newId);
				item->removeAttribute(ITEM_ATTRIBUTE_ACTIONID);
			}
		}
	}

	//load reward chest items
	itemMap.clear();
	query.str(std::string());
	query << "SELECT `pid`, `sid`, `itemtype`, `count`, `attributes` FROM `player_rewards` WHERE `player_id` = " << player->getGUID() << " ORDER BY `sid` DESC LIMIT 1000";
    if ((result = db.storeQuery(query.str()))) {
		loadItems(itemMap, result);

		//first loop handles the reward containers to retrieve its date attribute
		//for (ItemMap::iterator it = itemMap.begin(), end = itemMap.end(); it != end; ++it) {
		for (auto& it : itemMap) {
			const std::pair<Item*, int32_t>& pair = it.second;
			Item* item = pair.first;

			int32_t pid = pair.second;
			if (pid >= 0 && pid < 100) {
				Reward* reward = player->getReward(item->getIntAttr(ITEM_ATTRIBUTE_DATE), true);
				if (reward) {
					it.second = std::pair<Item*, int32_t>(reward->getItem(), pid); //update the map with the special reward container
				}
			} else {
				break;
			}
		}

		//second loop (this time a reverse one) to insert the items in the correct order
		//for (ItemMap::const_reverse_iterator it = itemMap.rbegin(), end = itemMap.rend(); it != end; ++it) {
		for (const auto& it : boost::adaptors::reverse(itemMap)) {
			const std::pair<Item*, int32_t>& pair = it.second;
			Item* item = pair.first;

			int32_t pid = pair.second;
			if (pid >= 0 && pid < 100) {
				break;
			}

			ItemMap::const_iterator it2 = itemMap.find(pid);
			if (it2 == itemMap.end()) {
				continue;
			}

			Container* container = it2->second.first->getContainer();
			if (container) {
				container->internalAddThing(item);
			}
			// arrumando bug do wrap
			bool isWrapable = item->isWrapable() || item->getID() == TRANSFORM_BOX_ID;
			if (item->hasAttribute(ITEM_ATTRIBUTE_ACTIONID) && isWrapable) {
				uint16_t newId = item->getID() == TRANSFORM_BOX_ID ? item->getIntAttr(ITEM_ATTRIBUTE_ACTIONID) : Item::items[item->getID()].wrapableTo;;
				item->setIntAttr(ITEM_ATTRIBUTE_WRAPID, newId);
				item->removeAttribute(ITEM_ATTRIBUTE_ACTIONID);
			}
		}
	}

	//load storage map
	query.str(std::string());
	query << "SELECT `key`, `value` FROM `player_storage` WHERE `player_id` = " << player->getGUID();
	if ((result = db.storeQuery(query.str()))) {
		do {
			player->addStorageValue(result->getNumber<uint32_t>("key"), result->getNumber<int32_t>("value"), true);
		} while (result->next());
	}

	//load account storage map
	query.str(std::string());
	query << "SELECT `key`, `value` FROM `accounts_storage` WHERE `account_id` = " << player->getAccount();
	if ((result = db.storeQuery(query.str()))) {
		do {
			player->addAccountStorageValue(result->getNumber<uint32_t>("key"), result->getNumber<int32_t>("value"));
		} while (result->next());
	}

	//load vip
	query.str(std::string());
	query << "SELECT `player_id` FROM `account_viplist` WHERE `account_id` = " << player->getAccount();
	if ((result = db.storeQuery(query.str()))) {
		do {
			player->addVIPInternal(result->getNumber<uint32_t>("player_id"));
		} while (result->next());
	}

	//load preydata
	query.str(std::string());
	query << "SELECT `data` FROM `player_preydata` WHERE `player_id` = " << player->getGUID();
	if ((result = db.storeQuery(query.str()))) {
		std::vector<PreyData> preyData(3);
		loadPreyData(preyData, result);
		player->setPreyData(std::move(preyData));
	} else {
		player->generatePreyData();
	}

	//send resource
	player->sendResourceData(RESOURCETYPE_BANK_GOLD, player->getBankBalance());
	player->sendResourceData(RESOURCETYPE_INVENTORY_GOLD, player->getMoney());
	player->sendResourceData(RESOURCETYPE_PREY_BONUS_REROLLS, player->getBonusRerollCount());

	player->updateBaseSpeed();
	player->updateInventoryWeight();
	player->updateItemsLight(true);

	// load account history
	loadAccountStoreHistory(player->getAccount());

	return true;
}

void IOLoginData::readPreyList(std::vector<std::string>& preyList, PropStream& propStream)
{
	uint8_t preyListSize;
	if (propStream.read<uint8_t>(preyListSize) && preyListSize > 0) {
		for (uint8_t i = 0; i < preyListSize; i++) {
			std::string preyName;
			if (propStream.readString(preyName)) {
				preyList.emplace_back(std::move(preyName));
			}
		}
	}
}

void IOLoginData::loadPreyData(std::vector<PreyData>& preyData, DBResult_ptr result)
{
	/*
	{
		PREYSLOTID
			LASTFREEREROLLTIME
			STATEID
				-> (0x00 locked)     : PREYLIST SIZE: 0x00
				-> (0x01 inactive)   : PREYLIST SIZE: 0x00
				-> (0x02 active)     : STRING PREYNAME, TIMELEFT, BONUSTYPE, BONUSVALUE, BONUSGRADE, PREYLIST SIZE: Variable, PREYLIST
				-> (0x03 selection)  : PREYLIST SIZE: Variable, PREYLIST
				-> (0X04 selectionc) : BONUSTYPE, BONUSVALUE, BONUSGRADE, PREYLIST SIZE: Variable, PREYLIST
	} x 3
	*/

	unsigned long dataSize;
	const char* data = result->getStream("data", dataSize);

	PropStream propStream;
	propStream.init(data, dataSize);

	PreyState stateId = STATE_LOCKED;
	uint64_t lastReroll = 0;
	uint8_t preySlotId;

	for (int blocks = 0; blocks < PREY_SLOTCOUNT; blocks++) {
		if (propStream.read<uint8_t>(preySlotId) && preySlotId < PREY_SLOTCOUNT) {
			PreyData& currentPrey = preyData[preySlotId];

			if (!propStream.read<uint64_t>(lastReroll)) {
				continue;
			}

			if (propStream.read<PreyState>(stateId)) {

				std::string preyMonster;
				uint16_t timeLeft = 0;
				BonusType bonusType = BONUS_NONE;
				uint16_t bonusValue = 0;
				uint8_t bonusGrade = 0;

				if (stateId == STATE_ACTIVE) {
					if (!propStream.readString(preyMonster)) {
						continue;
					} else if (!propStream.read<uint16_t>(timeLeft)) {
						continue;
					} else if (!propStream.read<BonusType>(bonusType)) {
						continue;
					} else if (!propStream.read<uint16_t>(bonusValue)) {
						continue;
					} else if (!propStream.read<uint8_t>(bonusGrade)) {
						continue;
					}
				} else if (stateId == STATE_SELECTION_CHANGE_MONSTER) {
					if (!propStream.read<BonusType>(bonusType)) {
						continue;
					} else if (!propStream.read<uint16_t>(bonusValue)) {
						continue;
					} else if (!propStream.read<uint8_t>(bonusGrade)) {
						continue;
					}
				}

				currentPrey.state = stateId;
				currentPrey.preyMonster = preyMonster;
				currentPrey.timeLeft = timeLeft;
				currentPrey.bonusType = bonusType;
				currentPrey.bonusGrade = bonusGrade;
				currentPrey.bonusValue = bonusValue;
				currentPrey.lastReroll = lastReroll;
				readPreyList(currentPrey.preyList, propStream);
			}
		}
	}
}

bool IOLoginData::savePreyData(const Player* player)
{
	Database& db = Database::getInstance();

	PropWriteStream propWriteStream;
	player->serializePreyData(propWriteStream);

	size_t dataSize;
	const char* data = propWriteStream.getStream(dataSize);

	std::ostringstream ss;
	DBInsert preyQuery("INSERT INTO `player_preydata` (`player_id`, `data`) VALUES ");

	ss << player->getGUID() << ',' << db.escapeBlob(data, dataSize);
	preyQuery.addRow(ss);
	return preyQuery.execute();
}

bool IOLoginData::saveItems(const Player* player, const ItemBlockList& itemList, DBInsert& query_insert, PropWriteStream& propWriteStream)
{
	Database& db = Database::getInstance();

	std::ostringstream ss;

	using ContainerBlock = std::pair<Container*, int32_t>;
	std::list<ContainerBlock> queue;

	int32_t runningId = 100;

	const auto& openContainers = player->getOpenContainers();
	for (const auto& it : itemList) {
		int32_t pid = it.first;
		Item* item = it.second;
		++runningId;

		if (Container* container = item->getContainer()) {
			if (container->getIntAttr(ITEM_ATTRIBUTE_OPENED) > 0) {
				container->setIntAttr(ITEM_ATTRIBUTE_OPENED, 0);
			}

			if (!openContainers.empty()) {
				for (const auto& its : openContainers) {
					auto openContainer = its.second;
					auto opcontainer = openContainer.container;

					if (opcontainer == container) {
						container->setIntAttr(ITEM_ATTRIBUTE_OPENED, ((int)its.first) + 1);
						break;
					}
				}
			}

			queue.emplace_back(container, runningId);
		}

		propWriteStream.clear();
		item->serializeAttr(propWriteStream);

		size_t attributesSize;
		const char* attributes = propWriteStream.getStream(attributesSize);

		ss << player->getGUID() << ',' << pid << ',' << runningId << ',' << item->getID() << ',' << item->getSubType() << ',' << db.escapeBlob(attributes, attributesSize);
		if (!query_insert.addRow(ss)) {
			return false;
		}

	}

	while (!queue.empty()) {
		const ContainerBlock& cb = queue.front();
		Container* container = cb.first;
		int32_t parentId = cb.second;
		queue.pop_front();

		for (Item* item : container->getItemList()) {
			++runningId;

			Container* subContainer = item->getContainer();
			if (subContainer) {
				queue.emplace_back(subContainer, runningId);
				if (subContainer->getIntAttr(ITEM_ATTRIBUTE_OPENED) > 0) {
					subContainer->setIntAttr(ITEM_ATTRIBUTE_OPENED, 0);
				}

				if (!openContainers.empty()) {
					for (const auto& it : openContainers) {
						auto openContainer = it.second;
						auto opcontainer = openContainer.container;

						if (opcontainer == subContainer) {
							subContainer->setIntAttr(ITEM_ATTRIBUTE_OPENED, ((int)it.first) + 1);
							break;
						}
					}
				}
			}

			propWriteStream.clear();
			item->serializeAttr(propWriteStream);

			size_t attributesSize;
			const char* attributes = propWriteStream.getStream(attributesSize);

			ss << player->getGUID() << ',' << parentId << ',' << runningId << ',' << item->getID() << ',' << item->getSubType() << ',' << db.escapeBlob(attributes, attributesSize);
			if (!query_insert.addRow(ss)) {
				return false;
			}
		}
	}
	return query_insert.execute();
}

bool IOLoginData::savePlayer(Player* player)
{
	if (player->getHealth() <= 0) {
		player->changeHealth(1);
	}
	Database& db = Database::getInstance();

	std::ostringstream query;
	query << "SELECT `save` FROM `players` WHERE `id` = " << player->getGUID();
	DBResult_ptr result = db.storeQuery(query.str());
	if (!result) {
		std::cout << player->getName() << " 01" << std::endl;
		return false;
	}

	if (result->getNumber<uint16_t>("save") == 0) {
		query.str(std::string());
		query << "UPDATE `players` SET `lastlogin` = " << player->lastLoginSaved << ", `lastip` = " << player->lastIP << " WHERE `id` = " << player->getGUID();
		return db.executeQuery(query.str());
	}

	//First, an UPDATE query to write the player itself
	query.str(std::string());
	query << "UPDATE `players` SET ";
	query << "`level` = " << player->level << ',';
	query << "`group_id` = " << player->group->id << ',';
	query << "`vocation` = " << player->getVocationId() << ',';
	query << "`health` = " << player->health << ',';
	query << "`healthmax` = " << player->healthMax << ',';
	query << "`experience` = " << player->experience << ',';
	query << "`lookbody` = " << static_cast<uint32_t>(player->defaultOutfit.lookBody) << ',';
	query << "`lookfeet` = " << static_cast<uint32_t>(player->defaultOutfit.lookFeet) << ',';
	query << "`lookmount` = " << static_cast<uint32_t>(player->defaultOutfit.lookMount) << ',';
	query << "`lookhead` = " << static_cast<uint32_t>(player->defaultOutfit.lookHead) << ',';
	query << "`looklegs` = " << static_cast<uint32_t>(player->defaultOutfit.lookLegs) << ',';
	query << "`looktype` = " << player->defaultOutfit.lookType << ',';
	query << "`lookaddons` = " << static_cast<uint32_t>(player->defaultOutfit.lookAddons) << ',';
	query << "`lookmountbody` = " << static_cast<uint32_t>(player->defaultOutfit.lookMountBody) << ',';
	query << "`lookmountfeet` = " << static_cast<uint32_t>(player->defaultOutfit.lookMountFeet) << ',';
	query << "`lookmounthead` = " << static_cast<uint32_t>(player->defaultOutfit.lookMountHead) << ',';
	query << "`lookmountlegs` = " << static_cast<uint32_t>(player->defaultOutfit.lookMountLegs) << ',';
	query << "`lookfamiliarstype` = " << player->defaultOutfit.lookFamiliarsType << ',';
	query << "`maglevel` = " << player->magLevel << ',';
	query << "`mana` = " << player->mana << ',';
	query << "`manamax` = " << player->manaMax << ',';
	query << "`manaspent` = " << player->manaSpent << ',';
	query << "`soul` = " << static_cast<uint16_t>(player->soul) << ',';
	query << "`town_id` = " << player->town->getID() << ',';

	const Position& loginPosition = player->getLoginPosition();
	query << "`posx` = " << loginPosition.getX() << ',';
	query << "`posy` = " << loginPosition.getY() << ',';
	query << "`posz` = " << loginPosition.getZ() << ',';

	query << "`cap` = " << (player->capacity / 100) << ',';
	query << "`sex` = " << static_cast<uint16_t>(player->sex) << ',';

	if (player->lastLoginSaved != 0) {
		query << "`lastlogin` = " << player->lastLoginSaved << ',';
	}

	if (player->lastIP != 0) {
		query << "`lastip` = " << player->lastIP << ',';
	}

	//serialize conditions
	PropWriteStream propWriteStream;
	for (Condition* condition : player->conditions) {
		if (condition->isPersistent()) {
			condition->serialize(propWriteStream);
			propWriteStream.write<uint8_t>(CONDITIONATTR_END);
		}
	}

	size_t attributesSize;
	const char* attributes = propWriteStream.getStream(attributesSize);

	query << "`conditions` = " << db.escapeBlob(attributes, attributesSize) << ',';

	// bestiarykills
	propWriteStream.clear();	
	propWriteStream.write<size_t>(player->bestiaryKills.size());
	for (const auto& it : player->bestiaryKills) {
		propWriteStream.write<uint16_t>(it.first);
		const BestiaryPoints& bestiaryPoints = it.second;
		propWriteStream.write<int32_t>(bestiaryPoints.kills);
		propWriteStream.write<int8_t>(bestiaryPoints.gained);
	}

	attributes = propWriteStream.getStream(attributesSize);
	query << "`bestiarykills` = " << db.escapeBlob(attributes, attributesSize) << ',';

	// bestiaryTracker
	propWriteStream.clear();
	propWriteStream.write<size_t>(player->bestiaryTracker.size());
	for (auto it = player->bestiaryTracker.begin(), end = player->bestiaryTracker.end(); it != end; ++it) {
		propWriteStream.write<uint16_t>(*it);
	}

	attributes = propWriteStream.getStream(attributesSize);
	query << "`bestiaryTracker` = " << db.escapeBlob(attributes, attributesSize) << ',';

	// charmMap
	propWriteStream.clear();
	propWriteStream.write<size_t>(player->charmMap.size());
	for (const auto& it : player->charmMap) {
		propWriteStream.write<uint8_t>(it.first);
		propWriteStream.write<uint16_t>(it.second);
	}

	attributes = propWriteStream.getStream(attributesSize);
	query << "`charms` = " << db.escapeBlob(attributes, attributesSize) << ',';

	// autoloot list
	propWriteStream.clear();
	propWriteStream.write<size_t>(player->autoLootItemIds.size());
	for (auto it = player->autoLootItemIds.begin(), end = player->autoLootItemIds.end(); it != end; ++it) {
		propWriteStream.write<uint16_t>(*it);
	}

	attributes = propWriteStream.getStream(attributesSize);
	query << "`autoloot` = " << db.escapeBlob(attributes, attributesSize) << ',';


	if (g_game.getWorldType() != WORLD_TYPE_PVP_ENFORCED) {
		int64_t skullTime = 0;

		if (player->skullTicks > 0) {
			skullTime = OS_TIME(nullptr) + player->skullTicks;
		}

		query << "`skulltime` = " << skullTime << ',';

		Skulls_t skull = SKULL_NONE;
		if (player->skull == SKULL_RED) {
			skull = SKULL_RED;
		} else if (player->skull == SKULL_BLACK) {
			skull = SKULL_BLACK;
		}
		query << "`skull` = " << static_cast<int64_t>(skull) << ',';
	}

	query << "`lastday` = " << player->lastday << ',';
	query << "`lastlogout` = " << player->getLastLogout() << ',';
	query << "`balance` = " << player->bankBalance << ',';
	query << "`bonusrerollcount` = " << player->getBonusRerollCount() << ',';
	query << "`quick_loot_fallback` = " << (player->quickLootFallbackToMainContainer ? 1 : 0) << ',';
	query << "`charmExpansion` = " << (player->charmExpansion ? 1 : 0) << ',';
	query << "`offlinetraining_time` = " << player->getOfflineTrainingTime() / 1000 << ',';
	query << "`offlinetraining_skill` = " << player->getOfflineTrainingSkill() << ',';
	query << "`stamina` = " << player->getStaminaMinutes() << ',';

	query << "`skill_fist` = " << player->skills[SKILL_FIST].level << ',';
	query << "`skill_fist_tries` = " << player->skills[SKILL_FIST].tries << ',';
	query << "`skill_club` = " << player->skills[SKILL_CLUB].level << ',';
	query << "`skill_club_tries` = " << player->skills[SKILL_CLUB].tries << ',';
	query << "`skill_sword` = " << player->skills[SKILL_SWORD].level << ',';
	query << "`skill_sword_tries` = " << player->skills[SKILL_SWORD].tries << ',';
	query << "`skill_axe` = " << player->skills[SKILL_AXE].level << ',';
	query << "`skill_axe_tries` = " << player->skills[SKILL_AXE].tries << ',';
	query << "`skill_dist` = " << player->skills[SKILL_DISTANCE].level << ',';
	query << "`skill_dist_tries` = " << player->skills[SKILL_DISTANCE].tries << ',';
	query << "`skill_shielding` = " << player->skills[SKILL_SHIELD].level << ',';
	query << "`skill_shielding_tries` = " << player->skills[SKILL_SHIELD].tries << ',';
	query << "`skill_fishing` = " << player->skills[SKILL_FISHING].level << ',';
	query << "`skill_fishing_tries` = " << player->skills[SKILL_FISHING].tries << ',';
	query << "`direction` = " << static_cast<uint16_t> (player->getDirection()) << ',';
	query << "`skill_critical_hit_chance` = " << player->skills[SKILL_CRITICAL_HIT_CHANCE].level << ',';
	query << "`skill_critical_hit_chance_tries` = " << player->skills[SKILL_CRITICAL_HIT_CHANCE].tries << ',';
	query << "`skill_critical_hit_damage` = " << player->skills[SKILL_CRITICAL_HIT_DAMAGE].level << ',';
	query << "`skill_critical_hit_damage_tries` = " << player->skills[SKILL_CRITICAL_HIT_DAMAGE].tries << ',';
	query << "`skill_life_leech_chance` = " << player->skills[SKILL_LIFE_LEECH_CHANCE].level << ',';
	query << "`skill_life_leech_chance_tries` = " << player->skills[SKILL_LIFE_LEECH_CHANCE].tries << ',';
	query << "`skill_life_leech_amount` = " << player->skills[SKILL_LIFE_LEECH_AMOUNT].level << ',';
	query << "`skill_life_leech_amount_tries` = " << player->skills[SKILL_LIFE_LEECH_AMOUNT].tries << ',';
	query << "`skill_mana_leech_chance` = " << player->skills[SKILL_MANA_LEECH_CHANCE].level << ',';
	query << "`skill_mana_leech_chance_tries` = " << player->skills[SKILL_MANA_LEECH_CHANCE].tries << ',';
	query << "`skill_mana_leech_amount` = " << player->skills[SKILL_MANA_LEECH_AMOUNT].level << ',';
	query << "`skill_mana_leech_amount_tries` = " << player->skills[SKILL_MANA_LEECH_AMOUNT].tries << ',';
	query << "`xpboost_value` = " << player->getStoreXpBoost() << ',';
	query << "`xpboost_stamina` = " << player->getExpBoostStamina() << ',';
	query << "`instantrewardtokens` = " << player->getInstantRewardTokens()<< ',';
	query << "`critical` = " << player->getCrit() << ',';
	query << "`charmpoints` = " << player->charmPoints << ',';
	query << "`version` = " << player->getProtocolVersion() << ',';

	if (!player->isOffline()) {
		query << "`onlinetime` = `onlinetime` + " << (OS_TIME(nullptr) - player->lastLoginSaved) << ',';
	}
	for (int i = 1; i <= 8; i++) {
		query << "`blessings" << i << "`" << " = " << static_cast<uint32_t>(player->getBlessingCount(i)) << ((i == 8) ? ' ' : ',');
	}
	query << " WHERE `id` = " << player->getGUID();

	DBTransaction transaction;
	if (!transaction.begin()) {
		std::cout << player->getName() << " 02" << std::endl;
		return false;
	}

	if (!db.executeQuery(query.str())) {
		std::cout << player->getName() << " 03" << std::endl;
		return false;
	}

	// learned spells
	query.str(std::string());
	query << "DELETE FROM `player_spells` WHERE `player_id` = " << player->getGUID();
	if (!db.executeQuery(query.str())) {
		std::cout << player->getName() << " 04" << std::endl;
		return false;
	}

	query.str(std::string());

	DBInsert spellsQuery("INSERT INTO `player_spells` (`player_id`, `name` ) VALUES ");
	for (const std::string& spellName : player->learnedInstantSpellList) {
		query << player->getGUID() << ',' << db.escapeString(spellName);
		if (!spellsQuery.addRow(query)) {
			std::cout << player->getName() << " 05" << std::endl;
			return false;
		}
	}

	if (!spellsQuery.execute()) {
		std::cout << player->getName() << " 06" << std::endl;
		return false;
	}

	//player kills
	query.str(std::string());
	query << "DELETE FROM `player_kills` WHERE `player_id` = " << player->getGUID();
	if (!db.executeQuery(query.str())) {
		std::cout << player->getName() << " 07" << std::endl;
		return false;
	}

	query.str(std::string());

	DBInsert killsQuery("INSERT INTO `player_kills` (`player_id`, `target`, `time`, `unavenged`) VALUES");
	for (const auto& kill : player->unjustifiedKills) {
		query << player->getGUID() << ',' << kill.target << ',' << kill.time << ',' << kill.unavenged;
		if (!killsQuery.addRow(query)) {
			std::cout << player->getName() << " 08" << std::endl;
			return false;
		}
	}

	if (!killsQuery.execute()) {
		std::cout << player->getName() << " 08" << std::endl;
		return false;
	}

	//item saving
	query << "DELETE FROM `player_items` WHERE `player_id` = " << player->getGUID();
	if (!db.executeQuery(query.str())) {
		std::cout << player->getName() << " 10" << std::endl;
		return false;
	}

	DBInsert itemsQuery("INSERT INTO `player_items` (`player_id`, `pid`, `sid`, `itemtype`, `count`, `attributes`) VALUES ");

	ItemBlockList itemList;
	for (int32_t slotId = 1; slotId <= 11; ++slotId) {
		Item* item = player->inventory[slotId];
		if (item) {
			itemList.emplace_back(slotId, item);
		}
	}

	if (!saveItems(player, itemList, itemsQuery, propWriteStream)) {
		std::cout << player->getName() << " 11" << std::endl;
		return false;
	}

	if (player->lastDepotId != -1) {
		//save depot items
		query.str(std::string());
		query << "DELETE FROM `player_depotitems` WHERE `player_id` = " << player->getGUID();

		if (!db.executeQuery(query.str())) {
			std::cout << player->getName() << " 12" << std::endl;
			return false;
		}

		DBInsert depotQuery("INSERT INTO `player_depotitems` (`player_id`, `pid`, `sid`, `itemtype`, `count`, `attributes`) VALUES ");
		itemList.clear();

		for (const auto& it : player->depotChests) {
			DepotChest* depotChest = it.second;
			for (Item* item : depotChest->getItemList()) {
				itemList.emplace_back(it.first, item);
			}
		}

		if (!saveItems(player, itemList, depotQuery, propWriteStream)) {
			std::cout << player->getName() << " 13" << std::endl;
			return false;
		}
	}

	//save inbox items
	query.str(std::string());
	query << "DELETE FROM `player_inboxitems` WHERE `player_id` = " << player->getGUID();
	if (!db.executeQuery(query.str())) {
		std::cout << player->getName() << " 15" << std::endl;
		return false;
	}

	DBInsert inboxQuery("INSERT INTO `player_inboxitems` (`player_id`, `pid`, `sid`, `itemtype`, `count`, `attributes`) VALUES ");
	itemList.clear();

	for (Item* item : player->getInbox()->getItemList()) {
		itemList.emplace_back(0, item);
	}

	if (!saveItems(player, itemList, inboxQuery, propWriteStream)) {
		std::cout << player->getName() << " 16" << std::endl;
		return false;
	}

	//save reward items
	query.str(std::string());
	query << "DELETE FROM `player_rewards` WHERE `player_id` = " << player->getGUID();

	if (!db.executeQuery(query.str())) {
		std::cout << player->getName() << " 17" << std::endl;
		return false;
	}

	std::vector<uint32_t> rewardList;
	player->getRewardList(rewardList);

	if (!rewardList.empty()) {
		DBInsert rewardQuery("INSERT INTO `player_rewards` (`player_id`, `pid`, `sid`, `itemtype`, `count`, `attributes`) VALUES ");
		itemList.clear();
	
		int running = 0;
		for (const auto& rewardId : rewardList) {
			Reward* reward = player->getReward(rewardId, false);
			// rewards that are empty or older than 7 days aren't stored
			if (!reward->empty() && (OS_TIME(nullptr) - rewardId <= 60 * 60 * 24 * 7)) {
				itemList.emplace_back(++running, reward);
			}
		}

		if (!saveItems(player, itemList, rewardQuery, propWriteStream)) {
			std::cout << player->getName() << " 18" << std::endl;
			return false;
		}
	}

	query.str(std::string());
	query << "DELETE FROM `player_preydata` WHERE `player_id` = " << player->getGUID();
	if (!db.executeQuery(query.str())) {
		std::cout << player->getName() << " 19" << std::endl;
		return false;
	}

	if (!savePreyData(player)) {
		std::cout << player->getName() << " 20" << std::endl;
		return false;
	}

	query.str(std::string());
	query << "DELETE FROM `player_storage` WHERE `player_id` = " << player->getGUID();
	if (!db.executeQuery(query.str())) {
		std::cout << player->getName() << " 21" << std::endl;
		return false;
	}

	query.str(std::string());

	DBInsert storageQuery("INSERT INTO `player_storage` (`player_id`, `key`, `value`) VALUES ");
	player->genReservedStorageRange();

	for (const auto& it : player->storageMap) {
		query << player->getGUID() << ',' << it.first << ',' << it.second;
		if (!storageQuery.addRow(query)) {
			std::cout << player->getName() << " 22" << std::endl;
			return false;
		}
	}

	if (!storageQuery.execute()) {
		std::cout << player->getName() << " 23" << std::endl;
		return false;
	}

	// account storage
	query.str(std::string());
	query << "DELETE FROM `accounts_storage` WHERE `account_id` = " << player->getAccount();
	if (!db.executeQuery(query.str())) {
		return false;
	}

	query.str(std::string());

	DBInsert AccountStorageQuery("INSERT INTO `accounts_storage` (`account_id`, `key`, `value`) VALUES ");

	for (const auto& it : player->accountStorageMap) {
		query << player->getAccount() << ',' << it.first << ',' << it.second;
		if (!AccountStorageQuery.addRow(query)) {
			return false;
		}
	}

	if (!AccountStorageQuery.execute()) {
		return false;
	}

	//End the transaction
	return transaction.commit();
}

std::string IOLoginData::getNameByGuid(uint32_t guid)
{
	Database& db = Database::getInstance();

	std::ostringstream query;
	query << "SELECT `name` FROM `players` WHERE `id` = " << guid;
	DBResult_ptr result = db.storeQuery(query.str());
	if (!result) {
		return std::string();
	}
	return result->getString("name");
}

uint32_t IOLoginData::getGuidByName(const std::string& name)
{
	Database& db = Database::getInstance();

	std::ostringstream query;
	query << "SELECT `id` FROM `players` WHERE `name` = " << db.escapeString(name);
	DBResult_ptr result = db.storeQuery(query.str());
	if (!result) {
		return 0;
	}
	return result->getNumber<uint32_t>("id");
}

bool IOLoginData::getGuidByNameEx(uint32_t& guid, bool& specialVip, std::string& name)
{
	
	Database& db = Database::getInstance();

	std::ostringstream query;
	query << "SELECT `name`, `id`, `group_id`, `account_id` FROM `players` WHERE `name` = " << db.escapeString(name);
	DBResult_ptr result = db.storeQuery(query.str());
	if (!result) {
		return false;
	}

	name = result->getString("name");
	guid = result->getNumber<uint32_t>("id");
	Group* group = g_game.groups.getGroup(result->getNumber<uint16_t>("group_id"));

	uint64_t flags;
	if (group) {
		flags = group->flags;
	} else {
		flags = 0;
	}

	specialVip = (flags & PlayerFlag_SpecialVIP) != 0;
	return true;
}

bool IOLoginData::formatPlayerName(std::string& name)
{
	Database& db = Database::getInstance();


	std::ostringstream query;
	query << "SELECT `name` FROM `players` WHERE `name` = " << db.escapeString(name);

	DBResult_ptr result = db.storeQuery(query.str());
	if (!result) {
		return false;
	}

	name = result->getString("name");
	return true;
}

void IOLoginData::loadItems(ItemMap& itemMap, DBResult_ptr result)
{
	do {
		uint32_t sid = result->getNumber<uint32_t>("sid");
		uint32_t pid = result->getNumber<uint32_t>("pid");
		uint16_t type = result->getNumber<uint16_t>("itemtype");
		uint16_t count = result->getNumber<uint16_t>("count");

		unsigned long attrSize;
		const char* attr = result->getStream("attributes", attrSize);

		PropStream propStream;
		propStream.init(attr, attrSize);

		Item* item = Item::CreateItem(type, count);
		if (item) {
			if (!item->unserializeAttr(propStream)) {
				std::cout << "WARNING: Serialize error in IOLoginData::loadItems" << std::endl;
			}

			std::pair<Item*, uint32_t> pair(item, pid);
			itemMap[sid] = pair;
		}
	} while (result->next());
}

void IOLoginData::increaseBankBalance(uint32_t guid, uint64_t bankBalance)
{
	Database& db = Database::getInstance();

	std::ostringstream query;
	query << "UPDATE `players` SET `balance` = `balance` + " << bankBalance << " WHERE `id` = " << guid;
	db.executeQuery(query.str());
}

bool IOLoginData::hasBiddedOnHouse(uint32_t guid)
{
	Database& db = Database::getInstance();

	std::ostringstream query;
	query << "SELECT `id` FROM `houses` WHERE `highest_bidder` = " << guid << " LIMIT 1";
	return db.storeQuery(query.str()).get() != nullptr;
}

std::forward_list<VIPEntry> IOLoginData::getVIPEntries(uint32_t accountId)
{
	Database& db = Database::getInstance();

	std::forward_list<VIPEntry> entries;

	std::ostringstream query;
	query << "SELECT `player_id`, (SELECT `name` FROM `players` WHERE `id` = `player_id`) AS `name`, `description`, `icon`, `notify` FROM `account_viplist` WHERE `account_id` = " << accountId;

	DBResult_ptr result = db.storeQuery(query.str());
	if (result) {
		do {
			entries.emplace_front(
				result->getNumber<uint32_t>("player_id"),
				result->getString("name"),
				result->getString("description"),
				result->getNumber<uint32_t>("icon"),
				result->getNumber<uint16_t>("notify") != 0
			);
		} while (result->next());
	}
	return entries;
}

void IOLoginData::addVIPEntry(uint32_t accountId, uint32_t guid, const std::string& description, uint32_t icon, bool notify)
{
	Database& db = Database::getInstance();

	std::ostringstream query;
	query << "INSERT INTO `account_viplist` (`account_id`, `player_id`, `description`, `icon`, `notify`) VALUES (" << accountId << ',' << guid << ',' << db.escapeString(description) << ',' << icon << ',' << notify << ')';
	db.executeQuery(query.str());
}

void IOLoginData::editVIPEntry(uint32_t accountId, uint32_t guid, const std::string& description, uint32_t icon, bool notify)
{
	
	Database& db = Database::getInstance();

	std::ostringstream query;
	query << "UPDATE `account_viplist` SET `description` = " << db.escapeString(description) << ", `icon` = " << icon << ", `notify` = " << notify << " WHERE `account_id` = " << accountId << " AND `player_id` = " << guid;
	db.executeQuery(query.str());
}

void IOLoginData::removeVIPEntry(uint32_t accountId, uint32_t guid)
{
	Database& db = Database::getInstance();

	std::ostringstream query;
	query << "DELETE FROM `account_viplist` WHERE `account_id` = " << accountId << " AND `player_id` = " << guid;
	db.executeQuery(query.str());
}

void IOLoginData::addPremiumDays(uint32_t accountId, int32_t addDays)
{
	Database& db = Database::getInstance();

	std::ostringstream query;
	query << "UPDATE `accounts` SET `premdays` = `premdays` + " << addDays << " WHERE `id` = " << accountId;
	db.executeQuery(query.str());
}

void IOLoginData::removePremiumDays(uint32_t accountId, int32_t removeDays)
{
	Database& db = Database::getInstance();

	std::ostringstream query;
	query << "UPDATE `accounts` SET `premdays` = `premdays` - " << removeDays << " WHERE `id` = " << accountId;
	db.executeQuery(query.str());
}

void IOLoginData::setVipDays(uint32_t accountId, int32_t addDays)
{
	Database& db = Database::getInstance();

	std::ostringstream query;
	query << "UPDATE `accounts` SET `vip_time` = " << addDays << " WHERE `id` = " << accountId;
	db.executeQuery(query.str());
}
