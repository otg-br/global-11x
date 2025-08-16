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
#include <csignal>

#include "signals.h"
#include "tasks.h"
#include "game.h"
#include "actions.h"
#include "configmanager.h"
#include "spells.h"
#include "talkaction.h"
#include "movement.h"
#include "weapons.h"
#include "raids.h"
#include "quests.h"
#include "mounts.h"
#include "globalevent.h"
#include "monster.h"
#include "events.h"
#include "modules.h"
#include "imbuements.h"

extern Dispatcher g_dispatcher;
extern Stats g_stats;

extern ConfigManager g_config;
extern Actions* g_actions;
extern Monsters g_monsters;
extern TalkActions* g_talkActions;
extern MoveEvents* g_moveEvents;
extern Spells* g_spells;
extern Weapons* g_weapons;
extern Game g_game;
extern CreatureEvents* g_creatureEvents;
extern GlobalEvents* g_globalEvents;
extern Events* g_events;
extern Chat* g_chat;
extern LuaEnvironment g_luaEnvironment;
extern Modules* g_modules;

using ErrorCode = boost::system::error_code;

Signals::Signals(boost::asio::io_context& service) :
	set(service)
{
	set.add(SIGINT);
	set.add(SIGTERM);
#ifndef _WIN32
	set.add(SIGUSR1);
	set.add(SIGHUP);
#endif

	asyncWait();
}

void Signals::asyncWait()
{
	set.async_wait([this] (ErrorCode err, int signal) {
		if (err) {
			std::cerr << "Signal handling error: "  << err.message() << std::endl;
			return;
		}
		dispatchSignalHandler(signal);
		asyncWait();
	});
}

void Signals::dispatchSignalHandler(int signal)
{
	switch(signal) {
		case SIGINT: //Shuts the server down
			g_dispatcher.addTask(createTask(sigintHandler));
			break;
		case SIGTERM: //Shuts the server down
			g_dispatcher.addTask(createTask(sigtermHandler));
			break;
#ifndef _WIN32
		case SIGHUP: //Reload config/data
			g_dispatcher.addTask(createTask(sighupHandler));
			break;
		case SIGUSR1: //Saves game state
			g_dispatcher.addTask(createTask(sigusr1Handler));
			break;
#endif
		default:
			break;
	}
}

void Signals::sigtermHandler()
{
	//Dispatcher thread
	console::print(CONSOLEMESSAGE_TYPE_INFO, "SIGTERM received, shutting game server down...");
	g_game.setGameState(GAME_STATE_SHUTDOWN);
#ifdef STATS_ENABLED
	g_stats.stop();
#endif
}

void Signals::sigusr1Handler()
{
	//Dispatcher thread
	console::print(CONSOLEMESSAGE_TYPE_INFO, "SIGUSR1 received, saving the game state...");
	g_game.saveGameState();
}

void Signals::sighupHandler()
{
	//Dispatcher thread
	console::print(CONSOLEMESSAGE_TYPE_INFO, "SIGHUP received, reloading config files...");

	g_actions->reload();
	console::print(CONSOLEMESSAGE_TYPE_INFO, "Reloaded actions.");

	g_config.reload();
	console::print(CONSOLEMESSAGE_TYPE_INFO, "Reloaded config.");

	g_creatureEvents->reload();
	console::print(CONSOLEMESSAGE_TYPE_INFO, "Reloaded creature scripts.");

	g_moveEvents->reload();
	console::print(CONSOLEMESSAGE_TYPE_INFO, "Reloaded movements.");

	Npcs::reload();
	console::print(CONSOLEMESSAGE_TYPE_INFO, "Reloaded npcs.");

	g_game.raids.reload();
	g_game.raids.startup();
	console::print(CONSOLEMESSAGE_TYPE_INFO, "Reloaded raids.");

	g_spells->reload();
	console::print(CONSOLEMESSAGE_TYPE_INFO, "Reloaded monsters.");

	g_monsters.reload();
	console::print(CONSOLEMESSAGE_TYPE_INFO, "Reloaded spells.");

	g_talkActions->reload();
	console::print(CONSOLEMESSAGE_TYPE_INFO, "Reloaded talk actions.");

	Item::items.reload();
	console::print(CONSOLEMESSAGE_TYPE_INFO, "Reloaded items.");

	g_weapons->reload();
	g_weapons->loadDefaults();
	console::print(CONSOLEMESSAGE_TYPE_INFO, "Reloaded weapons.");

	g_game.quests.reload();
	console::print(CONSOLEMESSAGE_TYPE_INFO, "Reloaded quests.");

	g_game.mounts.reload();
	console::print(CONSOLEMESSAGE_TYPE_INFO, "Reloaded mounts.");

	g_globalEvents->reload();
	console::print(CONSOLEMESSAGE_TYPE_INFO, "Reloaded globalevents.");

	g_events->load();
	console::print(CONSOLEMESSAGE_TYPE_INFO, "Reloaded events.");

	g_chat->load();
	console::print(CONSOLEMESSAGE_TYPE_INFO, "Reloaded chatchannels.");

	g_luaEnvironment.loadFile("data/global.lua");
	console::print(CONSOLEMESSAGE_TYPE_INFO, "Reloaded global.lua.");

	g_modules->reload();
	console::print(CONSOLEMESSAGE_TYPE_INFO, "Reloaded modules.");

	lua_gc(g_luaEnvironment.getLuaState(), LUA_GCCOLLECT, 0);
}

void Signals::sigintHandler()
{
	//Dispatcher thread
	console::print(CONSOLEMESSAGE_TYPE_INFO, "SIGINT received, shutting game server down...");
	g_game.setGameState(GAME_STATE_SHUTDOWN);
#ifdef STATS_ENABLED
	g_stats.stop();
#endif
}
