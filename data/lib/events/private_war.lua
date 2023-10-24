PRIVATEWAR_TIME = { 30, 60, 90, 120, 150, 180 }
PRIVATEWAR_MAXPLAYERS = { 0, 10, 15, 20, 25, 30, 35, 40, 45, 50, 60 }
PRIVATEWAR_MAXFRAGS = { 0, 10, 20, 30, 50, 100, 150, 200 }
PRIVATEWAR_YES_NO = {"Yes", "No"}

PRIVATEWAR_CITIES = {
	[1] = "Liberty bay",
	[2] = "Edron",
	[3] = "Yalahar",
	[4] = "Darashia",
	[5] = "Liberty Bay (barco)",
	[6] = "Carlin",
}

if not PRIVATEWAR_BATTLEFIELD then
	-- city => guilds, time
	PRIVATEWAR_BATTLEFIELD = {}
end

if not PRIVATEWAR_BATTLEFIELD_TEMP then
	-- city => guilds, time
	PRIVATEWAR_BATTLEFIELD_TEMP = {}
end

if not GAME_ADDEVENTS then
	GAME_ADDEVENTS = {}
end

PRIVATEWAR_CITIESPOSITIONS = {
	-- Ordenar pelo ID do privatewar_cities{}
	-- A tabela dentro é para cada floor da cidade
	[1] = { 
		[1] = {
			from = {x = 30575, y = 32364, z = 7},
			to = {x = 30819, y = 32569, z = 7},
		},
	}, -- Liberty Bay
	
	[2] = {
		[1] = {
			from = {x = 30869, y = 32312, z = 7},
			to = {x = 31017, y = 32483, z = 7},
		},
	}, -- Edron	
	[3] = {
		[1] = {
			from = {x = 30880, y = 32499, z = 7},
			to = {x = 31042, y = 32639, z = 7},
		},
	}, -- Yalahar	
	[4] = {
		[1] = {
			from = {x = 31117, y = 32102, z = 7},
			to = {x = 31497, y = 32419, z = 7},
		},
	}, -- Darashia
	[5] = {
		[1] = {
			from = {x = 30699, y = 32734, z = 6},
			to = {x = 30749, y = 32777, z = 6},
		},
	}, -- Libarty Bay (barco)
	[6] = {
		[1] = {
			from = {x = 30873, y = 32697, z = 7},
			to = {x = 31017, y = 32828, z = 7},
		},
	}, -- Carlin
}

PRIVATEWAR_TELEPORT = {
	[1] = { 
		guildA = {from = {x = 30776, y = 32392, z = 7}, to = {x = 30783, y = 32398, z = 7}},
		guildB = {from = {x = 30722, y = 32550, z = 7}, to = {x = 30729, y = 32557, z = 7}},
	}, -- Liberty Bay
	[2] = { 
		guildA = {from = {x = 30908, y = 32319, z = 7}, to = {x = 30928, y = 32324, z = 7}},
		guildB = {from = {x = 30974, y = 32435, z = 7}, to = {x = 30989, y = 32452, z = 7}},
	}, -- Edron
	[3] = { 
		guildA = {from = {x = 30934, y = 32612, z = 7}, to = {x = 30953, y = 32621, z = 7}},
		guildB = {from = {x = 30952, y = 32531, z = 7}, to = {x = 30960, y = 32538, z = 7}},
	}, -- Yalahar
	[4] = { 
		guildA = {from = {x = 31437, y = 32122, z = 7}, to = {x = 31448, y = 32139, z = 7}},
		guildB = {from = {x = 31407, y = 32310, z = 7}, to = {x = 31417, y = 32321, z = 7}},
	}, -- Darashia
	[5] = { 
		guildA = {from = {x = 30711, y = 32754, z = 6}, to = {x = 30718, y = 32765, z = 6}},
		guildB = {from = {x = 30725, y = 32760, z = 6}, to = {x = 30730, y = 32770, z = 6}},
	}, -- Liberty Bay (barco)
	[6] = { 
		guildA = {from = {x = 30964, y = 32793, z = 7}, to = {x = 30974, y = 32809, z = 7}},
		guildB = {from = {x = 30942, y = 32722, z = 7}, to = {x = 30951, y = 32728, z = 7}},
	}, -- Carlin
}


-- Guild functions
function Guild.broadcastMessage(self, message, mType)
	local messageType = mType or MESSAGE_STATUS_WARNING
	local text = string.format("Guild broadcast:\n%s", message)
	print("//" .. self:getName() .. " guild: " .. message .."//")
	for _, player in pairs(self:getMembersOnline()) do
		player:sendTextMessage(messageType,  text)
	end

	return true
end

function Guild.inPrivateWar(self)
	for i = 1, #PRIVATEWAR_CITIES do
		local arena = PRIVATEWAR_BATTLEFIELD[i]
		if arena then
			if arena.attacker == self:getId() or arena.defense == self:getId() then
				return true
			end
		end
	end
	return false
end

function Guild.getRival(self)
	if not self:inPrivateWar() then return 0 end

	for i = 1, #PRIVATEWAR_CITIES do
		local arena = PRIVATEWAR_BATTLEFIELD[i]
		if arena then
			if arena.attacker == self:getId() then
				return arena.defense
			elseif arena.defense == self:getId() then
				return arena.attacker
			end
		end
	end

	return 0
end

function Guild.getTeleportPosition(self)
	if not self:inPrivateWar() then return false end

	for i = 1, #PRIVATEWAR_CITIES do
		local arena = PRIVATEWAR_BATTLEFIELD[i]
		if arena then
			local tp = PRIVATEWAR_TELEPORT[i]
			if arena.attacker == self:getId() then
				local tile = Tile(Position(0,0,0))
				repeat
					tile = Tile(Position(math.random(tp.guildA.from.x, tp.guildA.to.x), math.random(tp.guildA.from.y, tp.guildA.to.y), tp.guildA.to.z ))
				until tile and tile:getPosition():isWalkable()

				return tile:getPosition()
			elseif arena.defense == self:getId() then
				local tile = Tile(Position(0,0,0))
				repeat
					tile = Tile(Position(math.random(tp.guildB.from.x, tp.guildB.to.x), math.random(tp.guildB.from.y, tp.guildB.to.y), tp.guildB.to.z ))
				until tile and tile:getPosition():isWalkable()

				return tile:getPosition()
			end
		end
	end

	return false
end

function Guild.getCityWar(self)
	if not self:inPrivateWar() then
		return 0
	end

	for i = 1, #PRIVATEWAR_CITIES do
		local arena = PRIVATEWAR_BATTLEFIELD[i]
		if arena then
			if arena.attacker == self:getId() or arena.defense == self:getId() then
				return i
			end
		end
	end

	return 0
end

GUILD_CONVITE_NONE = 0
GUILD_CONVITE_ATTACKER = 1
GUILD_CONVITE_DEFENSER = 2

function Guild.getConviteState(self)
	for mandante, info in pairs(PRIVATEWAR_BATTLEFIELD_TEMP) do
		if mandante == self:getId() then
			return GUILD_CONVITE_ATTACKER
		elseif info.defenser == self:getId() then
			return GUILD_CONVITE_DEFENSER
		end
	end	

	return GUILD_CONVITE_NONE
end

-- temporario/modal
function Guild.startTempData(self)
	PRIVATEWAR_BATTLEFIELD_TEMP[self:getId()] = {}
end
function Guild.cleanTempData(self)
	PRIVATEWAR_BATTLEFIELD_TEMP[self:getId()] = nil
	PRIVATEWAR_BATTLEFIELD_TEMP[self:getTempRival()] = nil
end

function Guild.setTempRival(self, rivalid)
	local id = self:getId()
	if not PRIVATEWAR_BATTLEFIELD_TEMP[id] and not PRIVATEWAR_BATTLEFIELD_TEMP[rivalid] then
		PRIVATEWAR_BATTLEFIELD_TEMP[id] = {}
	elseif PRIVATEWAR_BATTLEFIELD_TEMP[rivalid] then
		PRIVATEWAR_BATTLEFIELD_TEMP[rivalid].defenser = id
		return
	end

	PRIVATEWAR_BATTLEFIELD_TEMP[id].defenser = rivalid
end
function Guild.getTempRival(self)
	local id = self:getId()
	if PRIVATEWAR_BATTLEFIELD_TEMP[id] then
		return PRIVATEWAR_BATTLEFIELD_TEMP[id].defenser
	end

	for guildid, info in pairs(PRIVATEWAR_BATTLEFIELD_TEMP) do
		if info.defenser == id then
			return guildid
		end
	end

	return 0
end

function Guild.getTempWar(self)
	local id = self:getId()
	if PRIVATEWAR_BATTLEFIELD_TEMP[id] then
		return PRIVATEWAR_BATTLEFIELD_TEMP[id]
	end

	for guildid, info in pairs(PRIVATEWAR_BATTLEFIELD_TEMP) do
		if info.defenser == id then
			return PRIVATEWAR_BATTLEFIELD_TEMP[guildid]
		end
	end

	return false
end

function Guild.getTempCity(self)
	local id = self:getId()
	if PRIVATEWAR_BATTLEFIELD_TEMP[id] then
		return PRIVATEWAR_BATTLEFIELD_TEMP[id].city
	end

	for guildid, info in pairs(PRIVATEWAR_BATTLEFIELD_TEMP) do
		if info.defenser == id then
			return info.city
		end
	end

	return 0
end
function Guild.setTempCity(self, city)
	local id = self:getId()
	if PRIVATEWAR_BATTLEFIELD_TEMP[id] then
		PRIVATEWAR_BATTLEFIELD_TEMP[id].city = city
		return true
	end
	for guildid, info in pairs(PRIVATEWAR_BATTLEFIELD_TEMP) do
		if info.defenser == id then
			PRIVATEWAR_BATTLEFIELD_TEMP[guildid].city = city
			return true
		end
	end
	return false
end

function Guild.getTempTime(self)
	local id = self:getId()
	if PRIVATEWAR_BATTLEFIELD_TEMP[id] then
		return PRIVATEWAR_BATTLEFIELD_TEMP[id].time
	end

	for guildid, info in pairs(PRIVATEWAR_BATTLEFIELD_TEMP) do
		if info.defenser == id then
			return info.time
		end
	end

	return 0
end
function Guild.setTempTime(self, time)
	local id = self:getId()
	if PRIVATEWAR_BATTLEFIELD_TEMP[id] then
		PRIVATEWAR_BATTLEFIELD_TEMP[id].time = time
		return true
	end
	for guildid, info in pairs(PRIVATEWAR_BATTLEFIELD_TEMP) do
		if info.defenser == id then
			PRIVATEWAR_BATTLEFIELD_TEMP[guildid].time = time
			return true
		end
	end
	return false
end

function Guild.getTempMaxPlayer(self)
	local id = self:getId()
	if PRIVATEWAR_BATTLEFIELD_TEMP[id] then
		return PRIVATEWAR_BATTLEFIELD_TEMP[id].maxplayer
	end

	for guildid, info in pairs(PRIVATEWAR_BATTLEFIELD_TEMP) do
		if info.defenser == id then
			return info.maxplayer
		end
	end

	return 0
end
function Guild.setTempMaxPlayer(self, maxplayer)
	local id = self:getId()
	if PRIVATEWAR_BATTLEFIELD_TEMP[id] then
		PRIVATEWAR_BATTLEFIELD_TEMP[id].maxplayer = maxplayer
		return true
	end
	for guildid, info in pairs(PRIVATEWAR_BATTLEFIELD_TEMP) do
		if info.defenser == id then
			PRIVATEWAR_BATTLEFIELD_TEMP[guildid].maxplayer = maxplayer
			return true
		end
	end
	return false
end

function Guild.getTempMaxFrags(self)
	local id = self:getId()
	if PRIVATEWAR_BATTLEFIELD_TEMP[id] then
		return PRIVATEWAR_BATTLEFIELD_TEMP[id].maxfrag
	end

	for guildid, info in pairs(PRIVATEWAR_BATTLEFIELD_TEMP) do
		if info.defenser == id then
			return info.maxfrag
		end
	end

	return 0
end
function Guild.setTempMaxFrags(self, maxfrag)
	local id = self:getId()
	if PRIVATEWAR_BATTLEFIELD_TEMP[id] then
		PRIVATEWAR_BATTLEFIELD_TEMP[id].maxfrag = maxfrag
		return true
	end
	for guildid, info in pairs(PRIVATEWAR_BATTLEFIELD_TEMP) do
		if info.defenser == id then
			PRIVATEWAR_BATTLEFIELD_TEMP[guildid].maxfrag = maxfrag
			return true
		end
	end
	return false
end

function Guild.getTempBlockRunes(self)
	local id = self:getId()
	if PRIVATEWAR_BATTLEFIELD_TEMP[id] then
		return PRIVATEWAR_BATTLEFIELD_TEMP[id].rune
	end

	for guildid, info in pairs(PRIVATEWAR_BATTLEFIELD_TEMP) do
		if info.defenser == id then
			return info.rune
		end
	end

	return false
end
function Guild.setTempBlockRunes(self, runevalue)
	local transform = {
		[1] = true,
		[2] = false,
	}
	local t = transform[runevalue]
	if not t then
		t = false
	end
	local id = self:getId()
	if PRIVATEWAR_BATTLEFIELD_TEMP[id] then
		PRIVATEWAR_BATTLEFIELD_TEMP[id].rune = t
		return true
	end
	for guildid, info in pairs(PRIVATEWAR_BATTLEFIELD_TEMP) do
		if info.defenser == id then
			PRIVATEWAR_BATTLEFIELD_TEMP[guildid].rune = t
			return true
		end
	end
	return false
end

function Guild.getTempAllowUE(self)
	local id = self:getId()
	if PRIVATEWAR_BATTLEFIELD_TEMP[id] then
		return PRIVATEWAR_BATTLEFIELD_TEMP[id].ue
	end

	for guildid, info in pairs(PRIVATEWAR_BATTLEFIELD_TEMP) do
		if info.defenser == id then
			return info.ue
		end
	end

	return true
end
function Guild.setTempAllowUE(self, uevalue)
	local transform = {
		[1] = true,
		[2] = false,
	}
	local t = transform[uevalue]
	if not t then
		t = false
	end
	local id = self:getId()
	if PRIVATEWAR_BATTLEFIELD_TEMP[id] then
		PRIVATEWAR_BATTLEFIELD_TEMP[id].ue = t
		return true
	end
	for guildid, info in pairs(PRIVATEWAR_BATTLEFIELD_TEMP) do
		if info.defenser == id then
			PRIVATEWAR_BATTLEFIELD_TEMP[guildid].ue = t
			return true
		end
	end
	return false
end

function Guild.getTempAllowNewPotions(self)
	local id = self:getId()
	if PRIVATEWAR_BATTLEFIELD_TEMP[id] then
		return PRIVATEWAR_BATTLEFIELD_TEMP[id].potions
	end

	for guildid, info in pairs(PRIVATEWAR_BATTLEFIELD_TEMP) do
		if info.defenser == id then
			return info.potions
		end
	end

	return true
end
function Guild.setTempAllowNewPotions(self, potionsvalue)
	local transform = {
		[1] = true,
		[2] = false,
	}
	local t = transform[potionsvalue]
	if not t then
		t = false
	end
	local id = self:getId()
	if PRIVATEWAR_BATTLEFIELD_TEMP[id] then
		PRIVATEWAR_BATTLEFIELD_TEMP[id].potions = t
		return true
	end
	for guildid, info in pairs(PRIVATEWAR_BATTLEFIELD_TEMP) do
		if info.defenser == id then
			PRIVATEWAR_BATTLEFIELD_TEMP[guildid].potions = t
			return true
		end
	end
	return false
end

function Guild.getTempAllowWave(self)
	local id = self:getId()
	if PRIVATEWAR_BATTLEFIELD_TEMP[id] then
		return PRIVATEWAR_BATTLEFIELD_TEMP[id].wave
	end

	for guildid, info in pairs(PRIVATEWAR_BATTLEFIELD_TEMP) do
		if info.defenser == id then
			return info.wave
		end
	end

	return true
end
function Guild.setTempAllowWave(self, wavevalue)
	local transform = {
		[1] = true,
		[2] = false,
	}
	local t = transform[wavevalue]
	if not t then
		t = false
	end
	local id = self:getId()
	if PRIVATEWAR_BATTLEFIELD_TEMP[id] then
		PRIVATEWAR_BATTLEFIELD_TEMP[id].wave = t
		return true
	end
	for guildid, info in pairs(PRIVATEWAR_BATTLEFIELD_TEMP) do
		if info.defenser == id then
			PRIVATEWAR_BATTLEFIELD_TEMP[guildid].wave = t
			return true
		end
	end
	return false
end
function Guild.getTempAllowStrongWave(self)
	local id = self:getId()
	if PRIVATEWAR_BATTLEFIELD_TEMP[id] then
		return PRIVATEWAR_BATTLEFIELD_TEMP[id].strongwave
	end

	for guildid, info in pairs(PRIVATEWAR_BATTLEFIELD_TEMP) do
		if info.defenser == id then
			return info.strongwave
		end
	end

	return true
end
function Guild.setTempAllowStrongWave(self, wavevalue)
	local transform = {
		[1] = true,
		[2] = false,
	}
	local t = transform[wavevalue]
	if not t then
		t = false
	end
	local id = self:getId()
	if PRIVATEWAR_BATTLEFIELD_TEMP[id] then
		PRIVATEWAR_BATTLEFIELD_TEMP[id].strongwave = t
		return true
	end
	for guildid, info in pairs(PRIVATEWAR_BATTLEFIELD_TEMP) do
		if info.defenser == id then
			PRIVATEWAR_BATTLEFIELD_TEMP[guildid].strongwave = t
			return true
		end
	end
	return false
end

function Guild.getTempAllowBeam(self)
	local id = self:getId()
	if PRIVATEWAR_BATTLEFIELD_TEMP[id] then
		return PRIVATEWAR_BATTLEFIELD_TEMP[id].beam
	end

	for guildid, info in pairs(PRIVATEWAR_BATTLEFIELD_TEMP) do
		if info.defenser == id then
			return info.beam
		end
	end

	return true
end
function Guild.setTempAllowBeam(self, wavevalue)
	local transform = {
		[1] = true,
		[2] = false,
	}
	local t = transform[wavevalue]
	if not t then
		t = false
	end
	local id = self:getId()
	if PRIVATEWAR_BATTLEFIELD_TEMP[id] then
		PRIVATEWAR_BATTLEFIELD_TEMP[id].beam = t
		return true
	end
	for guildid, info in pairs(PRIVATEWAR_BATTLEFIELD_TEMP) do
		if info.defenser == id then
			PRIVATEWAR_BATTLEFIELD_TEMP[guildid].beam = t
			return true
		end
	end
	return false
end

function Guild.getTempAllowArrow(self)
	local id = self:getId()
	if PRIVATEWAR_BATTLEFIELD_TEMP[id] then
		return PRIVATEWAR_BATTLEFIELD_TEMP[id].arrows
	end

	for guildid, info in pairs(PRIVATEWAR_BATTLEFIELD_TEMP) do
		if info.defenser == id then
			return info.arrows
		end
	end

	return true
end
function Guild.setTempAllowArrow(self, arrowvalue)
	local transform = {
		[1] = true,
		[2] = false,
	}
	local t = transform[arrowvalue]
	if not t then
		t = false
	end
	local id = self:getId()
	if PRIVATEWAR_BATTLEFIELD_TEMP[id] then
		PRIVATEWAR_BATTLEFIELD_TEMP[id].arrows = t
		return true
	end
	for guildid, info in pairs(PRIVATEWAR_BATTLEFIELD_TEMP) do
		if info.defenser == id then
			PRIVATEWAR_BATTLEFIELD_TEMP[guildid].arrows = t
			return true
		end
	end
	return false
end

function Guild.getTempAllowNewSummons(self)
	local id = self:getId()
	if PRIVATEWAR_BATTLEFIELD_TEMP[id] then
		return PRIVATEWAR_BATTLEFIELD_TEMP[id].summons
	end

	for guildid, info in pairs(PRIVATEWAR_BATTLEFIELD_TEMP) do
		if info.defenser == id then
			return info.summons
		end
	end

	return true
end
function Guild.setTempAllowNewSummons(self, summonvalue)
	local transform = {
		[1] = true,
		[2] = false,
	}
	local t = transform[summonvalue]
	if not t then
		t = false
	end
	local id = self:getId()
	if PRIVATEWAR_BATTLEFIELD_TEMP[id] then
		PRIVATEWAR_BATTLEFIELD_TEMP[id].summons = t
		return true
	end
	for guildid, info in pairs(PRIVATEWAR_BATTLEFIELD_TEMP) do
		if info.defenser == id then
			PRIVATEWAR_BATTLEFIELD_TEMP[guildid].summons = t
			return true
		end
	end
	return false
end


-- Player functions
function Player.canDeclareWar(self)
	return self:getGuild() and self:getGuildLevel() >= 3
end

function Player.isRivalWar(self, targetid)
	local target = Player(targetid)
	if not target then return false end

	local guild, targetguild = self:getGuild(), target:getGuild()
	if not guild or not targetguild then return false end

	return guild:getRival() == targetguild:getId()
end

function Player.canCancelWar(self)
	local guild = self:getGuild()
	if not guild then return false end
	local city = guild:getCityWar()
	if city == 0 then return false end

	return PRIVATEWAR_BATTLEFIELD[city].endtime == 0
end

function Player.teleportToWar(self)
	local guild = self:getGuild()
	if not guild then return false end

	local city = guild:getCityWar()
	if city > 0 then
		local time = PRIVATEWAR_BATTLEFIELD[city].endtime
		-- nao pode entrar faltando 10 segundos
		if PRIVATEWAR_BATTLEFIELD[city].started and (time - os.stime()) < 10 then
			return false
		end

		local players = 0
		
		for _, pid in pairs(guild:getMembersOnline()) do
			if pid:inArenaWar() then
				players = players+1
			end
		end
		
		if PRIVATEWAR_BATTLEFIELD[city].maxplayer > 0 and players >= PRIVATEWAR_BATTLEFIELD[city].maxplayer then
			return false
		end
		
		local rival = Guild(guild:getRival())
		if not rival then
			return false
		end
		if not PRIVATEWAR_BATTLEFIELD[city].started then
			PRIVATEWAR_BATTLEFIELD[city].started = true
			PRIVATEWAR_BATTLEFIELD[city].endtime = (PRIVATEWAR_BATTLEFIELD[city].time * 60) + os.stime()
			Game.broadcastMessage(string.format("The war between '%s vs %s' has begun. The war will have a maximum duration until %s%s.", guild:getName(), rival:getName(), os.sdate("%d.%m.%Y %H:%M", PRIVATEWAR_BATTLEFIELD[city].endtime), PRIVATEWAR_BATTLEFIELD[city].maxplayer == 0 and '' or ' or until you reach the maximum limit of frags.'))
		end
		
		if (self:getCondition(CONDITION_INFIGHT, CONDITIONID_DEFAULT) or self:isPzLocked()) 
			and not (Tile(self:getPosition()):hasFlag(TILESTATE_PROTECTIONZONE)) then
			self:sendCancelMessage("You can't use this when you're in a fight.")
			return true
		end
		
		self:teleportTo(guild:getTeleportPosition(), true)
		self:setPrivateWar(true)
		return true
	end

	return false
end

local function isRangeWar(pos, fromPosition, toPosition)
    return (pos.x >= fromPosition.x and pos.y >= fromPosition.y and pos.z >= fromPosition.z
        and pos.x <= toPosition.x and pos.y <= toPosition.y and pos.z <= toPosition.z)
end

function Player.inArenaWar(self)
	for i = 1, #PRIVATEWAR_CITIESPOSITIONS do
		local city = PRIVATEWAR_CITIESPOSITIONS[i]
		for y = 1, #city do
			local rposition = city[y]
			local formPosition = Position(rposition.from)
			local toPosition = Position(rposition.to)
			if isRangeWar(self:getPosition(), rposition.from, rposition.to) then
				return true
			end
		end
	end
	for i = 1, #PRIVATEWAR_TELEPORT do
		local city = PRIVATEWAR_TELEPORT[i]
		if city then
			if isRangeWar(self:getPosition(), city.guildA.from, city.guildA.to) or isRangeWar(self:getPosition(), city.guildB.from, city.guildB.to) then
				return true
			end
		end
	end
	return false
end

CONST_WAR_RUNE = 0
CONST_WAR_UE = 1
CONST_WAR_POTIONS = 2
CONST_WAR_SUMMON = 3
CONST_WAR_ARROW = 4
CONST_WAR_WAVE = 5
CONST_WAR_STRONG_WAVE = 6
CONST_WAR_BEAM = 7

function Player.isWarAllowed(self, action)
	local guild = self:getGuild()
	if not guild then
		return true
	end

	if not self:inArenaWar() then
		return true
	end

	if guild:getCityWar() == 0 then
		return true
	end

	local warTable = PRIVATEWAR_BATTLEFIELD[guild:getCityWar()]
	if not warTable then
		return true
	end

	if action == CONST_WAR_RUNE then
		-- block rune
		if warTable.rune then
			return false
		end
	elseif action == CONST_WAR_UE then
		-- Allow
		if not warTable.ue then
			return false
		end
	elseif action == CONST_WAR_POTIONS then
		-- Allow
		if not warTable.potions then
			return false
		end
	elseif action == CONST_WAR_SUMMON then
		-- Allow
		if not warTable.summons then
			return false
		end
	elseif action == CONST_WAR_ARROW then
		-- Allow
		if not warTable.arrows then
			return false
		end
	elseif action == CONST_WAR_WAVE then
		-- Allow
		if not warTable.wave then
			return false
		end
	elseif action == CONST_WAR_STRONG_WAVE then
		-- Allow
		if not warTable.strongwave then
			return false
		end
	elseif action == CONST_WAR_BEAM then
		-- Allow
		if not warTable.beam then
			return false
		end
	end

	return true
end

-- Game functions
function Game.startWar(attackerId, defenseId, data)
	local attacker = Guild(attackerId)
	local defense = Guild(defenseId)
	if not attacker or not defense then
		return
	end

	-- checa se a arena ja está sendo usada/Comecou a guerra
	if PRIVATEWAR_BATTLEFIELD[data.city] and PRIVATEWAR_BATTLEFIELD[data.city].endtime == 0 then
		return false
	end
	-- checa se a arena ja está sendo usada/Esta em guerra
	if PRIVATEWAR_BATTLEFIELD[data.city] and PRIVATEWAR_BATTLEFIELD[data.city].started and PRIVATEWAR_BATTLEFIELD[data.city].endtime >= os.stime() then
		return false
	end

	-- checa se as guildas já estão em guerra
	if attacker:inPrivateWar() or defense:inPrivateWar() then
		return false
	end

	-- monta a estrutura da guerra - servirá para manusear a war durante o periodo
	PRIVATEWAR_BATTLEFIELD[attacker:getTempCity()] = {
		attacker = attacker:getId(),
		defense = defense:getId(),
		-- time = 5,
		time = attacker:getTempTime(),
		started = false, -- é iniciado quando um jogador entra na arena
		endtime = 0, -- 0 = arena esta esperando chegar algum jogador
		frags = {
			[attacker:getId()] = 0,
			[defense:getId()] = 0,
		},
		maxfrag = attacker:getTempMaxFrags(),
		maxplayer = attacker:getTempMaxPlayer(),
		rune = attacker:getTempBlockRunes(),
		ue = attacker:getTempAllowUE(),
		potions = attacker:getTempAllowNewPotions(),
		summons = attacker:getTempAllowNewSummons(),
		arrows = attacker:getTempAllowArrow(),
		wave = attacker:getTempAllowWave(),
		strongwave = attacker:getTempAllowStrongWave(),
		beam = attacker:getTempAllowBeam(),
	}

	attacker:cleanTempData()
	attacker:setPrivateWarRival(defense:getId())
	defense:setPrivateWarRival(attacker:getId())

	-- checa a cada 10 segundos
	local eventid = addEvent(Game.checkWar, 10*1000, attacker:getId(), defense:getId(), data.city)
	Game.setAddEventValue(data.city, eventid)
	return true
end

function Game.checkWar(attackerId, defenseId, city)
	if Game.getAddEventValue(city) < 0 then
		return true
	end
	local attacker = Guild(attackerId)
	local defense = Guild(defenseId)
	if not attacker or not defense then
		addEvent(Game.stopWar, 1000, city, 0)
		return
	end

	local maxfrag = PRIVATEWAR_BATTLEFIELD[city].maxfrag
	if maxfrag > 0 and (PRIVATEWAR_BATTLEFIELD[city].frags[attackerId] >= maxfrag or PRIVATEWAR_BATTLEFIELD[city].frags[defenseId] >= maxfrag) then
		addEvent(Game.stopWar, 1000, city, 1)
		return		
	end

	if PRIVATEWAR_BATTLEFIELD[city].started then
		if PRIVATEWAR_BATTLEFIELD[city].endtime < os.stime() then
			addEvent(Game.stopWar, 1000, city, 2)
			return true
		end
	end

	local eventid = addEvent(Game.checkWar, 10*1000, attackerId, defenseId, city)
	Game.setAddEventValue(city, eventid)
end

function Game.stopWar(city, reason)
	local attackerId = PRIVATEWAR_BATTLEFIELD[city].attacker
	local defenseId = PRIVATEWAR_BATTLEFIELD[city].defense
	local attacker = Guild(attackerId)
	local defense = Guild(defenseId)
	if not attacker or not defense then
		return false
	end
	local fragGuild1 = PRIVATEWAR_BATTLEFIELD[city].frags[attackerId]
	local fragGuild2 = PRIVATEWAR_BATTLEFIELD[city].frags[defenseId]
	local text = ""
	if reason == 1 then
		reason = "Frag Limit"
	elseif reason == 2 then
		reason = "Time Limit"
	else
		reason = "unknow reason"
	end
	local winner = attacker:getName()
	local winnerFrag = fragGuild1
	local loser = defense:getName()
	local loserFrag = fragGuild2
	if fragGuild1 < fragGuild2 then
		winner = defense:getName()
		loser = attacker:getName()
		winnerFrag = fragGuild2
		loserFrag = fragGuild1
	end
	text = string.format("The guild '%s' won the guild '%s' with %dx%d frags. [%s]", winner, loser, winnerFrag, loserFrag, reason)
	if fragGuild1 == fragGuild2 then
		text = string.format("The war between '%s vs %s' ended in a draw. %dx%d frags.", winner, loser, winnerFrag, loserFrag)
	end

	Game.broadcastMessage(text)
	for _, member in pairs(attacker:getMembersOnline()) do
		if member:inArenaWar() then
			member:teleportTo(member:getTown():getTemplePosition(), true)
			member:setPrivateWar(false)
		end
	end
	for _, member in pairs(defense:getMembersOnline()) do
		if member:inArenaWar() then
			member:teleportTo(member:getTown():getTemplePosition(), true)
			member:setPrivateWar(false)
		end
	end

	attacker:setPrivateWarRival(0)
	defense:setPrivateWarRival(0)

	PRIVATEWAR_BATTLEFIELD[city] = nil
	return true
end

function Game.getAddEventValue(key)
	return GAME_ADDEVENTS[key] and GAME_ADDEVENTS[key] or -1
end

function Game.setAddEventValue(key, eventid)
	GAME_ADDEVENTS[key] = eventid
	return true
end

-- Modals to leader
function Player.makeCityWarDialog(self)
	local guild = self:getGuild()
	if not guild then
		return true
	end

	local show = {}
	for i = 1, #PRIVATEWAR_CITIES do
		if not PRIVATEWAR_BATTLEFIELD[i] then
			show[i] = PRIVATEWAR_CITIES[i]
		end
	end

	local desc = "Choose the city for the battle."
	if #show == 0 then
		desc = desc .. " There are no cities available."
	end
	local title = string.format("Private War: %s", Guild(guild:getTempRival()):getName() )
	self:registerEvent("ModalWindow_privatewar")
	local modalWindow = ModalWindow(Modal.WarPrivate[1], title, desc)
	if #show > 0 then
		for i = 1, #show do
			local name = show[i]
			if name then
				modalWindow:addChoice(i, name)
			end
		end
	end
	modalWindow:addButton(100, "Close")
	modalWindow:addButton(101, "Continue")

	modalWindow:setDefaultEnterButton(101)
	modalWindow:setDefaultEscapeButton(100)

	modalWindow:sendToPlayer(self)

end

MAKE_WAR_MODAL = {
	[2] = {
		desc = "Choose the battle time.",
		choiceButton = "%s minutes",
		table = PRIVATEWAR_TIME,
	},
	[3] = {
		desc = "Choose the limit of players in the arena.",
		choiceButton = "%s players",
		table = PRIVATEWAR_MAXPLAYERS,
	},
	[4] = {
		desc = "Choose the limit of frags.",
		choiceButton = "%s frags",
		table = PRIVATEWAR_MAXFRAGS,
	},
	[5] = {
		desc = "Block Wave Runes (Yes = only the sudden death rune will work)",
		choiceButton = "%s",
		table = PRIVATEWAR_YES_NO,
	},
	[6] = {
		desc = "Allow UE",
		choiceButton = "%s",
		table = PRIVATEWAR_YES_NO,
	},
	[7] = {
		desc = "Allow new potions",
		choiceButton = "%s",
		table = PRIVATEWAR_YES_NO,
	},
	[8] = {
		desc = "Allow new summons",
		choiceButton = "%s",
		table = PRIVATEWAR_YES_NO,
	},
	[9] = {
		desc = "Allow arrows in areas.",
		choiceButton = "%s",
		table = PRIVATEWAR_YES_NO,
	},
	[10] = {
		desc = "Allow Wave Spells (exevo vis hur ...)",
		choiceButton = "%s",
		table = PRIVATEWAR_YES_NO,
	},
	[11] = {
		desc = "Allow Strong Wave Spells (exevo gran frigo hur ...)",
		choiceButton = "%s",
		table = PRIVATEWAR_YES_NO,
	},
	[12] = {
		desc = "Allow Beam Spells (exevo vis lux ...)",
		choiceButton = "%s",
		table = PRIVATEWAR_YES_NO,
		endOption = true
	},
}

PRIVATEWAR_CONFIRMID = 13
PRIVATEWAR_ENDID = PRIVATEWAR_CONFIRMID + 1

function Player.makeEndWarDialog(self)
	local guild = self:getGuild()
	if not guild then
		return true
	end

	local desc = "Confirm the information:"
	local frags = guild:getTempMaxFrags() == 0 and "unlimited" or tostring(guild:getTempMaxFrags())
	desc = string.format("%s\n- The war will take place in '%s', lasting %d minutes or when it reaches the '%s' frags limit.", desc, PRIVATEWAR_CITIES[guild:getTempCity()], guild:getTempTime(), frags)
	local players = guild:getTempMaxPlayer() == 0 and 'unlimited' or tostring(guild:getTempMaxPlayer())
	desc = string.format("%s\n- A maximum of %s players in the arena will be allowed.", desc, players)
	local function convertBoleanToString(value)
		return value == true and 'Yes' or 'No'
	end
	desc = string.format("%s\n\n- Block Runes: %s\n\n- Allow UE: %s\n\n- Allow new potions: %s\n\n- Allow new summons: %s\n\n- Allow arrow in area: %s\n\n- Allow Wave: %s\n\n- Allow strong Wave: %s\n\n- Allow beam spell (exevo gran vis lux...): %s",
	 desc,
	 convertBoleanToString(guild:getTempBlockRunes()),
	 convertBoleanToString(guild:getTempAllowUE()),
	 convertBoleanToString(guild:getTempAllowNewPotions()),
	 convertBoleanToString(guild:getTempAllowNewSummons()),
	 convertBoleanToString(guild:getTempAllowArrow()),
	 convertBoleanToString(guild:getTempAllowWave()),
	 convertBoleanToString(guild:getTempAllowStrongWave()),
	 convertBoleanToString(guild:getTempAllowBeam())
	 )

	local title = string.format("Private War: %s", Guild(guild:getTempRival()):getName() )
	self:registerEvent("ModalWindow_privatewar")
	local modalWindow = ModalWindow(Modal.WarPrivate[PRIVATEWAR_CONFIRMID], title, desc)

	modalWindow:addButton(100, "Cancel")
	modalWindow:addButton(101, "Confirm")
	modalWindow:addButton(102, "Back")

	modalWindow:setDefaultEnterButton(101)
	modalWindow:setDefaultEscapeButton(100)

	modalWindow:sendToPlayer(self)

end
function Player.makeAcceptWarDialog(self)
	local guild = self:getGuild()
	if not guild then
		return true
	end

	local desc = "Do you accept the war invitation with this information?"
	local frags = guild:getTempMaxFrags() == 0 and "unlimited" or tostring(guild:getTempMaxFrags())
	desc = string.format("%s\n- The war will take place in '%s', lasting %d minutes or when it reaches the '%s' frags limit.", desc, PRIVATEWAR_CITIES[guild:getTempCity()], guild:getTempTime(), frags)
	local players = guild:getTempMaxPlayer() == 0 and 'unlimited' or tostring(guild:getTempMaxPlayer())
	desc = string.format("%s\n- A maximum of %s players in the arena will be allowed.", desc, players)
	local function convertBoleanToString(value)
		return value == true and 'Yes' or 'No'
	end
	desc = string.format("%s\n\n- Block Runes: %s\n\n- Allow UE: %s\n\n- Allow new potions: %s\n\n- Allow new summons: %s\n\n- Allow arrow in area: %s\n\n- Allow Wave: %s\n\n- Allow strong Wave: %s\n\n- Allow beam spell (exevo gran vis lux...): %s",
	 desc,
	 convertBoleanToString(guild:getTempBlockRunes()),
	 convertBoleanToString(guild:getTempAllowUE()),
	 convertBoleanToString(guild:getTempAllowNewPotions()),
	 convertBoleanToString(guild:getTempAllowNewSummons()),
	 convertBoleanToString(guild:getTempAllowArrow()),
	 convertBoleanToString(guild:getTempAllowWave()),
	 convertBoleanToString(guild:getTempAllowStrongWave()),
	 convertBoleanToString(guild:getTempAllowBeam())
	 )

	local title = string.format("Private War: %s", Guild(guild:getTempRival()):getName() )
	self:registerEvent("ModalWindow_privatewar")
	local modalWindow = ModalWindow(Modal.WarPrivate[PRIVATEWAR_ENDID], title, desc)

	modalWindow:addButton(100, "Close")
	modalWindow:addButton(102, "Decline")
	modalWindow:addButton(101, "Accept")

	modalWindow:setDefaultEnterButton(101)
	modalWindow:setDefaultEscapeButton(100)

	modalWindow:sendToPlayer(self)

end

function Player.makeOtherWarDialog(self, pass)
	local modal = MAKE_WAR_MODAL[pass]
	if pass == 1 then
		return self:makeCityWarDialog()
	elseif pass == PRIVATEWAR_CONFIRMID then
		return self:makeEndWarDialog()
	elseif pass == PRIVATEWAR_ENDID then
		return self:makeAcceptWarDialog()
	elseif not modal then
		return true
	end
	local guild = self:getGuild()
	if not guild then
		return true
	end

	self:registerEvent("ModalWindow_privatewar")
	local title = string.format("Private War: %s", Guild(guild:getTempRival()):getName() )
	local modalWindow = ModalWindow(Modal.WarPrivate[pass], title, modal.desc)
	for i = 1, #modal.table do
		local mostrar = modal.table[i] == 0 and "no limit" or tostring(modal.table[i])
		modalWindow:addChoice(type(modal.table[i]) == "string" and i or modal.table[i], string.format(modal.choiceButton, mostrar))
	end

	modalWindow:addButton(100, "Close")
	modalWindow:addButton(101, modal.endOption and "Confirm" or "Continue")
	modalWindow:addButton(102, "Back")

	modalWindow:setDefaultEnterButton(101)
	modalWindow:setDefaultEscapeButton(100)

	modalWindow:sendToPlayer(self)

end

function Player.sendWarRules(self)
	local guild = self:getGuild()
	if not guild then
		return self:popupFYI("You have no guild")
	end

	local warTable = PRIVATEWAR_BATTLEFIELD[guild:getCityWar()]
	if not warTable then
		return self:popupFYI("Your guild is not at war.")
	end

	local desc = "War Rules"
	local frags = warTable.maxfrag == 0 and "unlimited" or tostring(warTable.maxfrag)
	desc = string.format("%s\n- The war will take place in '%s', lasting %d minutes or when it reaches the '%s' frags limit.", desc, PRIVATEWAR_CITIES[guild:getCityWar()], warTable.time, frags)
	local players = warTable.maxplayer == 0 and 'unlimited' or tostring( warTable.maxplayer)
	desc = string.format("%s\n- A maximum of %s players in the arena will be allowed.", desc, players)
	local function convertBoleanToString(value)
		return value == true and 'Yes' or 'No'
	end
	desc = string.format("%s\n\n- Block Runes: %s\n\n- Allow UE: %s\n\n- Allow new potions: %s\n\n- Allow new summons: %s\n\n- Allow arrows in areas: %s",
	 desc,
	 convertBoleanToString( warTable.rune),
	 convertBoleanToString( warTable.ue),
	 convertBoleanToString(warTable.potions),
	 convertBoleanToString(warTable.summons),
	 convertBoleanToString(warTable.arrows)
	 )

	 return self:popupFYI(desc)
end
