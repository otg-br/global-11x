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

#ifndef FS_CONFIGMANAGER_H_6BDD23BD0B8344F4B7C40E8BE6AF6F39
#define FS_CONFIGMANAGER_H_6BDD23BD0B8344F4B7C40E8BE6AF6F39

#include <string>
#include <unordered_map>
#include <map>

class ConfigManager
{
	public:
		ConfigManager();
		~ConfigManager() = default;
		struct ProxyInfo {
			std::string ip;
			uint16_t port;
			std::string name;

			ProxyInfo() : ip(""), port(0), name("") {}
			ProxyInfo(const std::string& ip, uint16_t port, const std::string& name) : ip(ip), port(port), name(name) {}
		};

		enum boolean_config_t {
			ALLOW_CHANGEOUTFIT,
			ONE_PLAYER_ON_ACCOUNT,
			AIMBOT_HOTKEY_ENABLED,
			REMOVE_RUNE_CHARGES,
			EXPERIENCE_FROM_PLAYERS,
			FREE_PREMIUM,
			REPLACE_KICK_ON_LOGIN,
			ALLOW_CLONES,
			BIND_ONLY_GLOBAL_ADDRESS,
			OPTIMIZE_DATABASE,
			MARKET_PREMIUM,
			EMOTE_SPELLS,
			STAMINA_SYSTEM,
			WARN_UNSAFE_SCRIPTS,
			CONVERT_UNSAFE_SCRIPTS,
			CLASSIC_EQUIPMENT_SLOTS,
			CLASSIC_ATTACK_SPEED,
			SCRIPTS_CONSOLE_LOGS,
			ALLOW_BLOCK_SPAWN,
			REMOVE_WEAPON_AMMO,
			REMOVE_WEAPON_CHARGES,
			REMOVE_POTION_CHARGES,
			STOREMODULES,
			QUEST_LUA,
			EXPERT_PVP,
			SHOW_PACKETS,
			ENABLE_LIVE_CASTING,
			PROTO_BUFF,
			MAINTENANCE,
			FORCE_MONSTERTYPE_LOAD,
			YELL_ALLOW_PREMIUM,
			BLESS_RUNE,
			ANTI_MULTI_CLIENT_ENABLED,
			ALLOW_MOUNT_IN_PZ,

			LAST_BOOLEAN_CONFIG /* this must be the last one */
		};

		enum string_config_t {
			CONFIG_FILE,
			MAP_NAME,
			HOUSE_RENT_PERIOD,
			SERVER_NAME,
			OWNER_NAME,
			OWNER_EMAIL,
			URL,
			LOCATION,
			IP,
			MOTD,
			WORLD_TYPE,
			MYSQL_HOST,
			MYSQL_USER,
			MYSQL_PASS,
			MYSQL_DB,
			MYSQL_SOCK,
			DEFAULT_PRIORITY,
			MAP_AUTHOR,
			STORE_IMAGES_URL,
			VERSION_STR,
			DEFAULT_OFFER,
			PROXY_LIST,
			BLOCK_WORD,
			MONSTER_URL,
			ITEM_URL,

			LAST_STRING_CONFIG /* this must be the last one */
		};

		enum integer_config_t {
			SQL_PORT,
			MAX_PLAYERS,
			PZ_LOCKED,
			DEFAULT_DESPAWNRANGE,
			DEFAULT_DESPAWNRADIUS,
			RATE_EXPERIENCE,
			RATE_SKILL,
			RATE_LOOT,
			RATE_MAGIC,
			RATE_SPAWN,
			HOUSE_PRICE,
			MAX_MESSAGEBUFFER,
			ACTIONS_DELAY_INTERVAL,
			EX_ACTIONS_DELAY_INTERVAL,
			KICK_AFTER_MINUTES,
			PROTECTION_LEVEL,
			DEATH_LOSE_PERCENT,
			STATUSQUERY_TIMEOUT,
			FRAG_TIME,
			WHITE_SKULL_TIME,
			GAME_PORT,
			LOGIN_PORT,
			STATUS_PORT,
			CHECK_PORT,
			STAIRHOP_DELAY,
			MAX_CONTAINER,
			MAX_ITEM,
			MARKET_OFFER_DURATION,
			CHECK_EXPIRED_MARKET_OFFERS_EACH_MINUTES,
			MAX_MARKET_OFFERS_AT_A_TIME_PER_PLAYER,
			EXP_FROM_PLAYERS_LEVEL_RANGE,
			MAX_PACKETS_PER_SECOND,
			STORE_COINS_PACKET_SIZE,
			VERSION_MIN,
			VERSION_MAX,
			FREE_DEPOT_LIMIT,
			PREMIUM_DEPOT_LIMIT,
			DEPOT_BOXES,
			AUTOLOOT_MODE, //Autoloot
			VIP_AUTOLOOT_LIMIT,
			FREE_AUTOLOOT_LIMIT,
			DAY_KILLS_TO_RED,
			WEEK_KILLS_TO_RED,
			MONTH_KILLS_TO_RED,
			RED_SKULL_DURATION,
			BLACK_SKULL_DURATION,
			ORANGE_SKULL_DURATION,
			NETWORK_ATTACK_THRESHOLD,
			LIVE_CAST_PORT,
			SERVER_SAVE_NOTIFY_DURATION,
			YELL_MINIMUM_LEVEL,
			TIME_GMT,
			ANTI_MULTI_CLIENT_LIMIT,
			PVP_PROTECTION_LEVEL,
			MAX_ALLOWED_ON_A_DUMMY,
			RATE_EXERCISE_TRAINING_SPEED,
			STATS_DUMP_INTERVAL,
			STATS_SLOW_LOG_TIME,
			STATS_VERY_SLOW_LOG_TIME,

			LAST_INTEGER_CONFIG /* this must be the last one */
		};

		enum floating_config_t {
			RATE_MONSTER_HEALTH,
			RATE_MONSTER_ATTACK,
			RATE_MONSTER_DEFENSE,
			RATE_HEALTH_REGEN,
			RATE_HEALTH_REGEN_SPEED,
			RATE_MANA_REGEN,
			RATE_MANA_REGEN_SPEED,
			RATE_SOUL_REGEN,
			RATE_SOUL_REGEN_SPEED,
			RATE_ATTACK_SPEED,

			LAST_FLOATING_CONFIG
		};

		enum doubling_config_t {
			RATE_MONSTER_SPEED,
			SPAWN_SPEED,

			LAST_DOUBLING_CONFIG
		};

		bool load();
		bool reload();

		const std::string& getString(string_config_t what) const;
		int32_t getNumber(integer_config_t what) const;
		bool getBoolean(boolean_config_t what) const;
		float getFloat(floating_config_t what) const;
		double getDouble(doubling_config_t what) const;
		std::pair<bool, const ConfigManager::ProxyInfo&> getProxyInfo(uint16_t proxyId);

		void setString(string_config_t what, const std::string& value);
		void setNumber(integer_config_t what, int32_t value);

		std::string const& setConfigFileLua(const std::string& what) {
			configFileLua = { what };
			return configFileLua;
		};
		std::string const& getConfigFileLua() const {
			return configFileLua;
		};

	private:
		std::string configFileLua = { "config.lua" };
		std::string string[LAST_STRING_CONFIG] = {};
		int32_t integer[LAST_INTEGER_CONFIG] = {};
		bool boolean[LAST_BOOLEAN_CONFIG] = {};
		float floating[LAST_FLOATING_CONFIG] = {};
		double doubling[LAST_DOUBLING_CONFIG] = {};
		std::map<uint16_t, ProxyInfo> proxyList;

		bool loaded = false;
};

#endif
