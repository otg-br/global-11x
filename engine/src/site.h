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

#ifndef FS_SITE_H_4083D3D3A05B4EDE891B31BB720CD06F
#define FS_SITE_H_4083D3D3A05B4EDE891B31BB720CD06F

#include "enums.h"
#include "protocolcheck.h"

class NetworkMessage;
class ProtocolCheck;
class SchedulerTask;

class Site
{
	public:
		explicit Site(ProtocolCheck_ptr p);
		~Site();

		// non-copyable
		Site(const Site&) = delete;
		Site& operator=(const Site&) = delete;

		Site* getSite() {
			return this;
		}
		const Site* getSite() const {
			return this;
		}

		void setID() {
			if (id == 0) {
				id = siteAutoID++;
			}
		}

		void disconnect() {
			if (client) {
				client->disconnect();
			}
		}

		static uint32_t siteAutoID;
	protected:

		uint32_t id = 0;

		ProtocolCheck_ptr client;

		friend class Game;
		friend class LuaScriptInterface;
		friend class ProtocolCheck;
};

#endif
