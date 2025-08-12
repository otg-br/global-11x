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

#include "server.h"

#include "game.h"

#include "iomarket.h"
#include "bestiary.h"
#include "charm.h"
#include "imbuements.h"
#include "prey.h"
#include "store.h"

#include "configmanager.h"
#include "scriptmanager.h"
#include "rsa.h"
#include "protocolcheck.h"
#include "protocolspectator.h"
#include "protocolold.h"
#include "protocollogin.h"
#include "protocolstatus.h"
#include "databasemanager.h"
#include "scheduler.h"
#include "databasetasks.h"
#include "script.h"
// TODO: #include "stdarg.h"

#include <iomanip>
#include <fmt/core.h>
#include <fmt/color.h>
#include <algorithm>
#include <cctype>
#include <fstream>
#if __has_include("gitmetadata.h")
#include "gitmetadata.h"
#endif

DatabaseTasks g_databaseTasks;
Dispatcher g_dispatcher;
Scheduler g_scheduler;

Game g_game;
ConfigManager g_config;
Monsters g_monsters;
Vocations g_vocations;
extern Scripts* g_scripts;
RSA g_RSA;
Prey g_prey;
Store g_store;
Imbuements g_imbuements;
Bestiaries g_bestiaries;
Charms g_charms;

std::mutex g_loaderLock;
std::condition_variable g_loaderSignal;
std::unique_lock<std::mutex> g_loaderUniqueLock(g_loaderLock);

std::string getHorizontalLine()
{
    std::ostringstream s;
    s << std::setw(80) << std::setfill('-') << "" << std::endl << std::setfill(' ');
    return s.str();
}

void startupErrorMessage(const std::string& errorStr)
{
    console::print(CONSOLEMESSAGE_TYPE_ERROR, "> ERROR: " + errorStr);
    g_loaderSignal.notify_all();
}

void printServerVersion()
{
	std::ostringstream startupMsg;
	std::string hrLine = getHorizontalLine();
	startupMsg << hrLine;

#if defined(GIT_RETRIEVED_STATE) && GIT_RETRIEVED_STATE
	startupMsg << STATUS_SERVER_NAME << " - Version " << GIT_DESCRIBE << std::endl;
	startupMsg << "Git SHA1 " << GIT_SHORT_SHA1 << " dated " << GIT_COMMIT_DATE_ISO8601 << std::endl;
	#if GIT_IS_DIRTY
	//startupMsg << "*** DIRTY - NOT OFFICIAL RELEASE ***" << std::endl;
	#endif
#else
	startupMsg << console::setColor(console::header, fmt::format("- {:s} - Version {:s}", STATUS_SERVER_NAME, STATUS_SERVER_VERSION)) << std::endl;
#endif
	startupMsg << std::endl;

	startupMsg << console::setColor(console::header, fmt::format("- Compiled with {:s}", BOOST_COMPILER)) << std::endl;

#if defined(__amd64__) || defined(_M_X64)
	std::string platform = "x64";
#elif defined(__i386__) || defined(_M_IX86) || defined(_X86_)
	std::string platform = "x86";
#elif defined(__arm__)
	std::string platform = "ARM";
#else
	std::string platform = "other";
#endif

	startupMsg << console::setColor(console::header, fmt::format("- Compiled on {:s} {:s} for platform {:s}", __DATE__, __TIME__, platform)) << std::endl;

#if defined(LUAJIT_VERSION)
	startupMsg << console::setColor(console::header, fmt::format("- Linked with {:s} for Lua support", LUAJIT_VERSION)) << std::endl;
#else
	startupMsg << console::setColor(console::header, fmt::format("- Linked with {:s} for Lua support", LUA_RELEASE)) << std::endl;
#endif

    startupMsg << hrLine;
    startupMsg << "- " << "A server developed by " << console::setColor(console::developers, "Johncore, Mark Samman and Mateuskl (Mateus Roberto)") << std::endl;
    startupMsg << "- " << "Engine Credits for: " << console::setColor(console::developers, "TFS Team, Erick Nunes, Leo Pereira, Marson Schneider, LukST, worthdavi, OTX Team, OTG Team") << std::endl;
    startupMsg << "- " << "Based on TFS 1.4 (Protocol 1100), heavily modified by " << console::setColor(console::error, "Mateus Roberto") << std::endl;
    startupMsg << "- " << "Visit our community: " << console::setColor(console::community, "https://github.com/Mateuzkl") << " and " << console::setColor(console::community, "https://github.com/otg-br") << std::endl;
    startupMsg << hrLine;
    std::cout << startupMsg.str() << std::flush;

}

bool caseInsensitiveEqual(const std::string& a, const std::string& b)
{
	if (a.size() != b.size()) {
		return false;
	}
	return std::equal(a.begin(), a.end(), b.begin(),
		[](char a, char b) { return std::tolower(a) == std::tolower(b); });
}

void mainLoader(int, char*[], ServiceManager* services);

void badAllocationHandler()
{
	// Use functions that only use stack allocation
	puts("Allocation failed, server out of memory.\nDecrease the size of your map or compile in 64 bits mode.\n");
	getchar();
	exit(-1);
}

int main(int argc, char* argv[])
{
	// Setup bad allocation handler
	std::set_new_handler(badAllocationHandler);

	ServiceManager serviceManager;

	g_dispatcher.start();
	g_scheduler.start();

	g_dispatcher.addTask(createTask(std::bind(mainLoader, argc, argv, &serviceManager)));

	g_loaderSignal.wait(g_loaderUniqueLock);

	if (serviceManager.is_running()) {
		console::printResultText(fmt::format("{} Server Online!", g_config.getString(ConfigManager::SERVER_NAME)));
		console::print(CONSOLEMESSAGE_TYPE_STARTUP, "");
		serviceManager.run();
	} else {
		console::print(CONSOLEMESSAGE_TYPE_ERROR, ">> No services running. The server is NOT online.");
		g_scheduler.shutdown();
		g_databaseTasks.shutdown();
		g_dispatcher.shutdown();
	}

	g_scheduler.join();
	g_databaseTasks.join();
	g_dispatcher.join();
	console::print(CONSOLEMESSAGE_TYPE_INFO, ">> Saving player items.");
	return 0;
}

void mainLoader(int argc, char* argv[], ServiceManager* services)
{
	uint64_t starttime = OTSYS_TIME(true);
	//dispatcher thread
	g_game.setGameState(GAME_STATE_STARTUP);

	srand(static_cast<unsigned int>(OTSYS_TIME(true)));
#ifdef _WIN32
	SetConsoleTitle(STATUS_SERVER_NAME);
#endif
	// SERVER STARTUP
	printServerVersion();

	// Loading config.lua ...
	const std::string& configFile = g_config.getString(ConfigManager::CONFIG_FILE);
	const std::string& distFile = configFile + ".dist";
	console::print(CONSOLEMESSAGE_TYPE_STARTUP, "Loading " + configFile + " ... ", false);

	// Load config.lua or generate one from config.lua.dist file
	std::ifstream c_test(("./" + configFile).c_str());

	if (!c_test.is_open()) {
		std::ifstream config_lua_dist(("./" + distFile).c_str());
		console::printResult(CONSOLE_LOADING_PENDING);
		console::print(CONSOLEMESSAGE_TYPE_INFO, "Copying " + distFile + " to " + configFile + " ... ", false);

		if (config_lua_dist.is_open()) {
			std::ofstream config_lua(configFile.c_str());
			config_lua << config_lua_dist.rdbuf();
			config_lua.close();
			config_lua_dist.close();
			console::printResult(CONSOLE_LOADING_OK);
		} else {
			console::printResult(CONSOLE_LOADING_ERROR);
			console::reportFileError("", distFile);
			return;
		}
	}

	// TODO: dirty for now; Use stdarg;
	if (argc > 1) {
		std::string param = { argv[1] };
		if (param == "-c") {
			g_config.setConfigFileLua(argv[2]);
		}
	}

	// Config.lua existence confirmed, load it
	if (!g_config.load()) {
		console::reportFileError("", configFile);
		return;
	}

	console::printResult(CONSOLE_LOADING_OK);

#ifdef _WIN32
	const std::string& defaultPriority = g_config.getString(ConfigManager::DEFAULT_PRIORITY);
	if (caseInsensitiveEqual(defaultPriority, "high")) {
		SetPriorityClass(GetCurrentProcess(), HIGH_PRIORITY_CLASS);
	} else if (caseInsensitiveEqual(defaultPriority, "above-normal")) {
		SetPriorityClass(GetCurrentProcess(), ABOVE_NORMAL_PRIORITY_CLASS);
	}
#endif

	//set RSA key
	g_RSA.loadPEM("key.pem");

	// Connect to the database
	console::print(CONSOLEMESSAGE_TYPE_STARTUP, "Establishing database connection...", false);

	if (!Database::getInstance().connect()) {
		startupErrorMessage(
			"Failed to connect to the database.\n"
			"Possible causes:\n"
			"- The MySQL server is not running.\n"
			"- The username or password in your config.lua is incorrect.\n"
			"- The user does not have the necessary privileges or is blocked.\n"
			"- The MySQL server is not accepting connections from 'localhost'.\n"
			"\nTroubleshooting steps:\n"
			"1. Make sure the MySQL service is running (e.g., 'systemctl status mysql' or 'service mysql status').\n"
			"2. Check your config.lua for correct database credentials (username, password, host, port).\n"
			"3. Try connecting manually using the same credentials: mysql -u <user> -p -h <host>\n"
			"4. If you recently changed your MySQL password, update it in config.lua.\n"
			"5. Check MySQL user privileges.\n"
			"\nThe server is NOT online until this issue is resolved."
		);
		return;
	}

	console::printResultText("MySQL " + std::string(Database::getClientVersion()));
	// run database manager
	console::print(CONSOLEMESSAGE_TYPE_STARTUP, "Running database manager", false);

	if (!DatabaseManager::isDatabaseSetup()) {
		startupErrorMessage("The database you have specified in config lua file is empty, please import the schema.sql to your database.");
		return;
	}
	g_databaseTasks.start();

	DatabaseManager::updateDatabase();

	if (g_config.getBoolean(ConfigManager::OPTIMIZE_DATABASE)) {
		console::print(CONSOLEMESSAGE_TYPE_STARTUP, "Optimizing database tables ...", false);
		DatabaseManager::optimizeTables();
		console::printResult(CONSOLE_LOADING_OK);
	}

	//load vocations
	console::print(CONSOLEMESSAGE_TYPE_STARTUP, "Loading vocations ...", false);
	if (!g_vocations.loadFromXml()) {
		startupErrorMessage("Unable to load vocations!");
		return;
	}

	// load item data
	console::print(CONSOLEMESSAGE_TYPE_STARTUP, "Loading items ...", false);
	if (Item::items.loadFromOtb("data/items/items.otb") != ERROR_NONE) {
		startupErrorMessage("Unable to load items (OTB)!");
		return;
	}

	if (!Item::items.loadFromXml()) {
		startupErrorMessage("Unable to load items (XML)!");
		return;
	}

	// if (g_config.getBoolean(ConfigManager::PROTO_BUFF)) {
	// 	if (!Item::items.loadFromProtobuf("appearances.dat")) {
	// 		startupErrorMessage("Unable to load appearances.dat!");
	// 		return;
	// 	}
	// }

	// load lua scripts
	console::print(CONSOLEMESSAGE_TYPE_STARTUP, "Loading script systems ...", false);
#if defined(LUAJIT_VERSION)
	console::printResultText(LUAJIT_VERSION);
#else
	console::printResultText(LUA_RELEASE);
#endif

	if (!ScriptingManager::getInstance().loadScriptSystems()) {
		startupErrorMessage("Failed to load script systems");
		return;
	}

	console::print(CONSOLEMESSAGE_TYPE_STARTUP, "Loading bestiary ...", false);
	if (!g_bestiaries.loadFromXml()) {
		startupErrorMessage("Unable to load Bestiaries!");
		return;
	}
	console::printResult(CONSOLE_LOADING_OK);

	console::print(CONSOLEMESSAGE_TYPE_STARTUP, "Loading lua scripts ...", false);
	if (!g_scripts->loadScripts("scripts", false, false)) {
		startupErrorMessage("Failed to load lua scripts");
		return;
	}
	console::printResult(CONSOLE_LOADING_OK);

	// Load lua monsters
	console::print(CONSOLEMESSAGE_TYPE_STARTUP, "Loading monsters (xml + lua) ... ", false);
	if (!g_monsters.loadFromXml()) {
		startupErrorMessage("Unable to load monsters!");
		return;
	}

	if (!g_scripts->loadScripts("monster", false, false)) {
		startupErrorMessage("Failed to load lua monsters");
		return;
	}
	console::printResultText("monsters: " + std::to_string(g_monsters.monsters.size()));

	// Load quests
	console::print(CONSOLEMESSAGE_TYPE_STARTUP, "Loading quests ...", false);
	if (g_config.getBoolean(ConfigManager::QUEST_LUA)) {
		console::printResult(CONSOLE_LOADING_OK);
	} else {
		console::printResult(CONSOLE_LOADING_OK);
		console::printResultText("Quest system disabled");
	}

	// Load outfits
	console::print(CONSOLEMESSAGE_TYPE_STARTUP, "Loading outfits ...", false);
	if (!Outfits::getInstance().loadFromXml()) {
		startupErrorMessage("Unable to load outfits!");
		return;
	}

	console::print(CONSOLEMESSAGE_TYPE_STARTUP, "Loading imbuements ...", false);
	if (!g_imbuements.loadFromXml()) {
		console::printResult(CONSOLE_LOADING_ERROR);
		startupErrorMessage("Unable to load imbuements!");
		return;
	}
	console::printResult(CONSOLE_LOADING_OK);

	console::print(CONSOLEMESSAGE_TYPE_STARTUP, "Loading charms ...", false);
	if (!g_charms.loadFromXml()) {
		console::printResult(CONSOLE_LOADING_ERROR);
		startupErrorMessage("Unable to load Charms!");
		return;
	}
	console::printResult(CONSOLE_LOADING_OK);

	console::print(CONSOLEMESSAGE_TYPE_STARTUP, "Loading Store ...", false);
	if (!g_store.loadFromXml()) {
		console::printResult(CONSOLE_LOADING_ERROR);
		startupErrorMessage("Unable to load store!");
		return;
	}
	console::printResult(CONSOLE_LOADING_OK);

	console::print(CONSOLEMESSAGE_TYPE_STARTUP, "Loading prey data ...", false);
	if (!g_prey.loadFromXml()) {
		console::printResult(CONSOLE_LOADING_ERROR);
		startupErrorMessage("Unable to load prey data!");
		return;
	}
	console::printResult(CONSOLE_LOADING_OK);

	// Check world type
	console::print(CONSOLEMESSAGE_TYPE_STARTUP, "Checking world type ...", false);
	std::string worldType = asLowerCaseString(g_config.getString(ConfigManager::WORLD_TYPE));
	if (worldType == "pvp") {
		g_game.setWorldType(WORLD_TYPE_PVP);
	} else if (worldType == "no-pvp") {
		g_game.setWorldType(WORLD_TYPE_NO_PVP);
	} else if (worldType == "pvp-enforced") {
		g_game.setWorldType(WORLD_TYPE_PVP_ENFORCED);
	} else if (worldType == "retro-pvp") {
		g_game.setWorldType(WORLD_TYPE_RETRO_OPEN_PVP);
	} else {
		console::printResult(CONSOLE_LOADING_ERROR);
		startupErrorMessage(fmt::format("Unknown world type: {}, valid world types are: pvp, no-pvp, pvp-enforced and retro-pvp.", g_config.getString(ConfigManager::WORLD_TYPE)));
		return;
	}

	console::printResultText(asUpperCaseString(worldType));

	// load map
	console::print(CONSOLEMESSAGE_TYPE_STARTUP, "Loading world map...");

	const std::string& worldName = g_config.getString(ConfigManager::MAP_NAME);
	console::printWorldInfo("Filename", worldName + ".otbm");

	if (!g_game.loadMainMap(worldName)) {
		startupErrorMessage("Failed to load map");
		return;
	}

	console::print(CONSOLEMESSAGE_TYPE_STARTUP, "Loading guilds ...", false);
	if (g_game.loadGuilds()) {
		console::printResultText("All guilds have been loaded.");
	} else {
		console::printResultText("No guild to load.");
	}

	console::printWorldInfo("Towns", std::to_string(g_game.map.towns.getTowns().size()));
	console::printWorldInfo("Houses", std::to_string(g_game.map.houses.getHouses().size()));
	console::print(CONSOLEMESSAGE_TYPE_STARTUP, "");
	console::printWorldInfo("Monsters", std::to_string(g_game.map.spawns.getMonsterCount()));
	console::printWorldInfo("NPCs", std::to_string(g_game.map.spawns.getNpcCount()));
	console::printWorldInfo("Spawns", std::to_string(g_game.map.spawns.size()));

	// bind service ports
	g_game.setGameState(GAME_STATE_INIT);

	console::print(CONSOLEMESSAGE_TYPE_STARTUP, "");

	uint16_t loginPort = static_cast<uint16_t>(g_config.getNumber(ConfigManager::LOGIN_PORT));
	uint16_t gamePort = static_cast<uint16_t>(g_config.getNumber(ConfigManager::GAME_PORT));
	uint16_t statusPort = static_cast<uint16_t>(g_config.getNumber(ConfigManager::STATUS_PORT));
	uint16_t liveCastPort = static_cast<uint16_t>(g_config.getNumber(ConfigManager::LIVE_CAST_PORT));

	// Game client protocols
	services->add<ProtocolGame>(gamePort);
	services->add<ProtocolLogin>(loginPort);

	// OT protocols
	services->add<ProtocolStatus>(statusPort);

	// Legacy login protocol
	services->add<ProtocolOld>(loginPort);

	// Live Cast protocol
	if (g_config.getBoolean(ConfigManager::ENABLE_LIVE_CASTING)) {
		services->add<ProtocolSpectator>(liveCastPort);
	}

	console::printLoginPorts(loginPort, gamePort, statusPort);

	// Show start time
	auto now = std::chrono::system_clock::now();
	auto time_t = std::chrono::system_clock::to_time_t(now);
	std::tm tm = *std::localtime(&time_t);
	console::printResultText(fmt::format("Start time: {:02d}.{:02d}.{:04d} - {:02d}:{:02d}:{:02d}", 
		tm.tm_mday, tm.tm_mon + 1, tm.tm_year + 1900, 
		tm.tm_hour, tm.tm_min, tm.tm_sec), console::Color::purple);

	RentPeriod_t rentPeriod;
	std::string strRentPeriod = asLowerCaseString(g_config.getString(ConfigManager::HOUSE_RENT_PERIOD));

	if (strRentPeriod == "yearly") {
		rentPeriod = RENTPERIOD_YEARLY;
	} else if (strRentPeriod == "weekly") {
		rentPeriod = RENTPERIOD_WEEKLY;
	} else if (strRentPeriod == "monthly") {
		rentPeriod = RENTPERIOD_MONTHLY;
	} else if (strRentPeriod == "daily") {
		rentPeriod = RENTPERIOD_DAILY;
	} else {
		rentPeriod = RENTPERIOD_NEVER;
	}

	g_game.map.houses.payHouses(rentPeriod);

	IOMarket::checkExpiredOffers();
	IOMarket::getInstance().updateStatistics();

	// Removed the warning about root user execution

	g_game.start(services);
	g_game.setGameState(GAME_STATE_NORMAL);
	g_loaderSignal.notify_all();

	console::printResultText(fmt::format("Server started in {:.3f} seconds.", (OTSYS_TIME(true) - starttime) / (1000.)), console::Color::purple);
}

bool argumentsHandler(const StringVector& args)
{
	for (const auto& arg : args) {
		if (arg == "--help") {
			std::clog << "Usage:\n"
			"\n"
			"\t--config=$1\t\tAlternate configuration file path.\n"
			"\t--ip=$1\t\t\tIP address of the server.\n"
			"\t\t\t\tShould be equal to the global IP.\n"
			"\t--login-port=$1\tPort for login server to listen on.\n"
			"\t--game-port=$1\tPort for game server to listen on.\n"
			"\t--status-port=$1\tPort for status server to listen on.\n";
			return false;
		} else if (arg == "--version") {
			printServerVersion();
			return false;
		}

		StringVector tmp = explodeString(arg, "=");

		if (tmp[0] == "--config")
			g_config.setString(ConfigManager::CONFIG_FILE, tmp[1]);
		else if (tmp[0] == "--ip")
			g_config.setString(ConfigManager::IP, tmp[1]);
		else if (tmp[0] == "--login-port")
			g_config.setNumber(ConfigManager::LOGIN_PORT, std::stoi(tmp[1]));
		else if (tmp[0] == "--game-port")
			g_config.setNumber(ConfigManager::GAME_PORT, std::stoi(tmp[1]));
		else if (tmp[0] == "--status-port")
			g_config.setNumber(ConfigManager::STATUS_PORT, std::stoi(tmp[1]));
	}

	return true;
}