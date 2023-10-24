local TELEPORT_POSITION = Position(32153, 32296, 7)
local TELEPORT_ACTIONID = 4500
local TELEPORT_ITEMID = 1387

local config = {
	semana_mes = "semana",
    days = {1, 2, 3, 4, 5, 6, 7}, -- Cada n?mero representa um dia da semana. Ex.: 2 = segunda-feira
}

local function warnEvent(i, minutes)
	Game.broadcastMessage("[Battlefield] The event will begin in ".. minutes .. " minutes! The portal is located in the event room (you may access it by the temple).")
	if i > 1 then
		addEvent(warnEvent, 2 * 60 * 1000, i - 1, minutes - 2)
	end
end

local function removeTeleport()
local teleport = Tile(TELEPORT_POSITION):getItemById(TELEPORT_ITEMID)
	if teleport then
		teleport:remove()
	else
		error("Não havia teleport.")
	end	
end

local function openBattlefield()
	Battlefield_x2:Open()
end

local function closeBattlefield()
	Battlefield_x2:Close()
end

function onTime(interval)
local time = os.sdate("*t")
	if (config.semana_mes == "semana" and isInArray(config.days,time.wday)) or (config.semana_mes == "mes" and isInArray(config.days,time.day)) or config.semana_mes == "" then
		Game.broadcastMessage("[Battlefield] The event will begin in 10 minutes! The portal is located in the event room (you may access it by the temple).")
		local teleport = Game.createItem(TELEPORT_ITEMID, 1, TELEPORT_POSITION)	
		if teleport then
			teleport:setActionId(TELEPORT_ACTIONID)
		else
			error("ERROR AO CRIAR TELEPORT")
		end 
		addEvent(warnEvent, 2 * 60 * 1000, 4, 8) 
		addEvent(removeTeleport,10 * 60 * 1000) 
		addEvent(openBattlefield, 10 * 60 * 1000) 
		addEvent(closeBattlefield, (30 + 10) * 60 * 1000)
	end
	return true
end
