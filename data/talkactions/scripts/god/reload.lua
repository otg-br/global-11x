if not table.contains then
	function table.contains(tab, value)
		for _, v in pairs(tab) do
			if v == value then
				return true
			end
		end
		return false
	end
end

local reloadTypes = {
	["all"] = RELOAD_TYPE_ALL,

	["global"] = RELOAD_TYPE_GLOBAL,
	["action"] = RELOAD_TYPE_ACTIONS,
	["actions"] = RELOAD_TYPE_ACTIONS,

	["bestiary"] = RELOAD_TYPE_BESTIARY,

	["chat"] = RELOAD_TYPE_CHAT,
	["channel"] = RELOAD_TYPE_CHAT,
	["chatchannels"] = RELOAD_TYPE_CHAT,

	["config"] = RELOAD_TYPE_CONFIG,
	["configuration"] = RELOAD_TYPE_CONFIG,

	["creaturescript"] = RELOAD_TYPE_CREATURESCRIPTS,
	["creaturescripts"] = RELOAD_TYPE_CREATURESCRIPTS,

	["events"] = RELOAD_TYPE_EVENTS,

	["globalevent"] = RELOAD_TYPE_GLOBALEVENTS,
	["globalevents"] = RELOAD_TYPE_GLOBALEVENTS,

	["items"] = RELOAD_TYPE_ITEMS,
	["modules"] = RELOAD_TYPE_MODULES,

	["monster"] = RELOAD_TYPE_MONSTERS,
	["monsters"] = RELOAD_TYPE_MONSTERS,

	["mount"] = RELOAD_TYPE_MOUNTS,
	["mounts"] = RELOAD_TYPE_MOUNTS,

	["move"] = RELOAD_TYPE_MOVEMENTS,
	["movement"] = RELOAD_TYPE_MOVEMENTS,
	["movements"] = RELOAD_TYPE_MOVEMENTS,

	["npc"] = RELOAD_TYPE_NPCS,
	["npcs"] = RELOAD_TYPE_NPCS,

	["quest"] = RELOAD_TYPE_QUESTS,
	["quests"] = RELOAD_TYPE_QUESTS,

	["raid"] = RELOAD_TYPE_RAIDS,
	["raids"] = RELOAD_TYPE_RAIDS,

	["spell"] = RELOAD_TYPE_SPELLS,
	["spells"] =  RELOAD_TYPE_SPELLS,

	["talk"] = RELOAD_TYPE_TALKACTIONS,
	["talkaction"] = RELOAD_TYPE_TALKACTIONS,
	["talkactions"] = RELOAD_TYPE_TALKACTIONS,

	["weapon"] = RELOAD_TYPE_WEAPONS,
	["weapons"] = RELOAD_TYPE_WEAPONS,

	["imbuements"] = RELOAD_TYPE_IMBUEMENTS,

	["scripts"] = RELOAD_TYPE_SCRIPTS,
	["libs"] = RELOAD_TYPE_GLOBAL,

	["store"] = RELOAD_TYPE_STORE,

	["free pass"] = RELOAD_TYPE_FREE_PASS,
}

function onSay(player, words, param)
	if not player:getGroup():getAccess() then
		return true
	end

	if player:getGroup():getId() < 6 then
		return true
	end

	saveServer()

	local reloads = Game.getStorageValue("reload") or 0
	if reloads >= 10 then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
			"Por medidas de segurança, só é permitido 10 reloads no server até que fique arrumado")
		return false
	end

	logCommand(player, words, param)

	if param:lower() == "autoset" then
		Game.reload(RELOAD_TYPE_GLOBAL)
		Game.loadAutomation(true)
		print(string.format("Reloaded %s and global.lua.", param:lower()))
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
			string.format("Reloaded %s and global.lua.", param:lower()))
		return false
	end

	local reloadType = reloadTypes[param:lower()]
	if not reloadType then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Reload type not found.")
		return false
	end

	-- Optional: If you want to prevent certain reloads for safety:
	-- if reloadType == RELOAD_TYPE_CREATURESCRIPTS then
	-- 	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
	-- 		"Por medidas de segurança, esse reload está desativado até que fique arrumado")
	-- 	return false
	-- end

	--Game.setStorageValue("reload", reloads + 1)

	-- If we only want to reset quest storage for RELOAD_TYPE_QUESTS:
	if reloadType == RELOAD_TYPE_QUESTS then
		Game.setStorageValue(RELOAD_TYPE_QUESTS, 0)
	else
		-- Clear any leftover event data if reloading scripts or everything:
		if table.contains({RELOAD_TYPE_SCRIPTS, RELOAD_TYPE_ALL}, reloadType) then
			Event:clear() 
		end

		Game.reload(reloadType)

		if reloadType == RELOAD_TYPE_GLOBAL then
			Game.reload(RELOAD_TYPE_SCRIPTS)
		end
	end

	print(string.format("Reloaded %s.", param:lower()))
	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, string.format("Reloaded %s.", param:lower()))
	return false
end
