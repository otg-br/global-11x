local firstRoom = {
	Tiles = {
		Position(33708, 32370, 15),
		Position(33713, 32371, 15),
		Position(33713, 32378, 15),
		Position(33716, 32365, 15),
		Position(33720, 32370, 15),
		Position(33720, 32377, 15),
		Position(33724, 32374, 15),
		Position(33724, 32368, 15),
		Position(33728, 32368, 15),
		Position(33727, 32376, 15),
	},
	centerPosition = Position(33718, 32374, 15)
}

local secondRoom = {
	Tiles = {
		Position(33729, 32350, 15),
		Position(33720, 32351, 15),
		Position(33722, 32345, 15),
		Position(33730, 32342, 15),
		Position(33718, 32338, 15),
		Position(33729, 32335, 15),
	},
	Canions = {
		Position(33725, 32339, 15),
		Position(33723, 32349, 15)
	},
	centerPosition = Position(33724, 32345, 15)
}

local thirdRoom = {
	Tiles = {
		Position(33753, 32346, 15),
		Position(33749, 32352, 15),
		Position(33754, 32358, 15),
		Position(33759, 32354, 15),
	},
	Canions = {
		Position(33751, 32348, 15),
		Position(33758, 32356, 15),
	},
	centerPosition = Position(33753, 32352, 15)
}

local fourthRoom = {
	Tiles = {
		Position(33766, 32337, 15),
		Position(33773, 32339, 15),
		Position(33778, 32335, 15),
		Position(33772, 32329, 15)
	},
	Canions = {
		Position(33772, 32331, 15),
		Position(33774, 32343, 15)
	},
	centerPosition = Position(33773, 32336, 15)
}

local function explode(position)
	local ativado = 31723
	local desativado = 31724
	local item = Tile(position):getItemById(desativado)
	if item then
		item:transform(ativado)
		addEvent(function(position, ativado, desativado)
			local fromPos = Position(position.x - 4, position.y - 4, position.z)
			local toPos = Position(position.x + 4, position.y + 4, position.z)
			for x = fromPos.x, toPos.x do
				for y = fromPos.y, toPos.y do
					local newPos = Position(x, y, 15)
					newPos:sendMagicEffect(CONST_ME_YELLOWSMOKE)
					local c = Tile(newPos):getTopCreature()
					if c and (c:isPlayer() or c:getMaster()) then
						doTargetCombatHealth(0, c, COMBAT_EARTHDAMAGE, -1040, -2430, CONST_ME_YELLOWSMOKE)
					end
				end
			end
			local on = Tile(position):getItemById(ativado)
			if on then
				on:transform(desativado)
			end
		end, 2*1000, position, ativado, desativado)
	end
end

local default = 32410
local glowing = 32412

local function revert(position)
	local crystal = Tile(position):getItemById(glowing)
	if crystal then
		crystal:transform(default)
	end
end

local function glow(position)
	local crystal = Tile(position):getItemById(default)
	if crystal then
		crystal:transform(glowing)
		addEvent(revert, 15*1000, position)
	end
end

function onThink(interval)
	-- Morgathla's first room
	local first = Game.getSpectators(firstRoom.centerPosition, false, true, 12, 12, 12, 12)
	if #first >= 1 then
		local r = math.random(1, #firstRoom.Tiles)
		glow(firstRoom.Tiles[r])
	end
	-- Morgathla's second room
	local second = Game.getSpectators(secondRoom.centerPosition, false, true, 12, 12, 12, 12)
	if #second >= 1 then
		local r = math.random(1, #secondRoom.Tiles)
		glow(secondRoom.Tiles[r])
		if secondRoom.Canions then
			local j = math.random(1, #secondRoom.Canions)
			explode(secondRoom.Canions[j])
		end
	end
	-- Morgathla's third room
	local third = Game.getSpectators(thirdRoom.centerPosition, false, true, 12, 12, 12, 12)
	if #third >= 1 then
		local r = math.random(1, #thirdRoom.Tiles)
		glow(thirdRoom.Tiles[r])
		if thirdRoom.Canions then
			local j = math.random(1, #thirdRoom.Canions)
			explode(thirdRoom.Canions[j])
		end
	end
	-- Morgathla's fourth room
	local fourth = Game.getSpectators(fourthRoom.centerPosition, false, true, 12, 12, 12, 12)
	if #fourth >= 1 then
		local r = math.random(1, #fourthRoom.Tiles)
		glow(fourthRoom.Tiles[r])
		if fourthRoom.Canions then
			local j = math.random(1, #fourthRoom.Canions)
			explode(fourthRoom.Canions[j])
		end
	end
	return true
end