--[[
	Description: This file is part of Roulette System (refactored)
	Author: Ly�
	Discord: Ly�#8767
]]


local Slot = require('data/scripts/events/events/magic-roulette/lib/classes/slot')

-- DEBUG: Função para mostrar posições calculadas
local function debugPositions(slotName, centerPos, tilesPerSlot)
	print("=== DEBUG ROULETTE POSITIONS ===")
	print("Slot: " .. slotName)
	print("Center Position: " .. centerPos.x .. ", " .. centerPos.y .. ", " .. centerPos.z)
	print("Tiles per slot: " .. tilesPerSlot)
	
	local half = math.floor(tilesPerSlot / 2)
	local startPos = Position(centerPos.x - half, centerPos.y, centerPos.z)
	local endPos = Position(centerPos.x + half, centerPos.y, centerPos.z)
	
	print("Start Position: " .. startPos.x .. ", " .. startPos.y .. ", " .. startPos.z)
	print("End Position: " .. endPos.x .. ", " .. endPos.y .. ", " .. endPos.z)
	print("All positions where dummies will appear:")
	
	for i = 0, tilesPerSlot - 1 do
		local pos = startPos + Position(i, 0, 0)
		print("  " .. (i + 1) .. ": " .. pos.x .. ", " .. pos.y .. ", " .. pos.z)
	end
	print("================================")
end

return {
	slots = {
		[17320] = Slot {
			needItem = {id = 8978, count = 1},
			tilesPerSlot = 11,
			centerPosition = Position(32957, 32076, 7),

			items = {
				{id = 8870, count = 1, chance = 0.2, rare = true},
				{id = 7730, count = 1, chance = 0.3, rare = true},
				{id = 7892, count = 1, chance = 0.5, rare = true},
				{id = 12640, count = 1, chance = 9},
				{id = 12411, count = 1, chance = 9},
				{id = 12662, count = 1, chance = 9},
				{id = 8981, count = 1, chance = 9},
				{id = 7443, count = 1, chance = 9},
				{id = 8978, count = 1, chance = 9},
				{id = 11401, count = 1, chance = 9},
				{id = 10760, count = 1, chance = 9},
				{id = 12466, count = 1, chance = 9},
				{id = 9693, count = 1, chance = 9},
				{id = 8474, count = 1, chance = 9}
			},
		},

		[17322] = Slot {
			needItem = {id = 8978, count = 1},
			tilesPerSlot = 11,
			centerPosition = Position(120, 360, 5),

			items = {
				{id = 8870, count = 1, chance = 0.02, rare = true},
				{id = 7730, count = 1, chance = 0.03, rare = true},
				{id = 7892, count = 1, chance = 0.05, rare = true},
				{id = 12640, count = 1, chance = 9},
				{id = 12411, count = 1, chance = 9},
				{id = 12662, count = 1, chance = 9},
				{id = 8981, count = 1, chance = 9},
				{id = 7443, count = 1, chance = 9},
				{id = 8978, count = 1, chance = 9},
				{id = 11401, count = 1, chance = 9},
				{id = 10760, count = 1, chance = 9},
				{id = 12466, count = 1, chance = 9},
				{id = 9693, count = 1, chance = 9},
				{id = 8474, count = 1, chance = 9.91}
			},
		},
	}
}

-- DEBUG: Função para mostrar posições (use quando quiser debugar)
-- debugPositions("Slot 1 (Action ID 17320)", Position(121, 426, 7), 11)
-- debugPositions("Slot 2 (Action ID 17322)", Position(120, 360, 5), 11)
