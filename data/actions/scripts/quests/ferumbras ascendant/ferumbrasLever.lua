local crystals = {
	[1] = {crystalPosition = Position(33390, 31468, 14), globalStorage = GlobalStorage.FerumbrasAscendantQuest.Crystals.Crystal1},
	[2] = {crystalPosition = Position(33394, 31468, 14), globalStorage = GlobalStorage.FerumbrasAscendantQuest.Crystals.Crystal2},
	[3] = {crystalPosition = Position(33397, 31471, 14), globalStorage = GlobalStorage.FerumbrasAscendantQuest.Crystals.Crystal3},
	[4] = {crystalPosition = Position(33397, 31475, 14), globalStorage = GlobalStorage.FerumbrasAscendantQuest.Crystals.Crystal4},
	[5] = {crystalPosition = Position(33394, 31478, 14), globalStorage = GlobalStorage.FerumbrasAscendantQuest.Crystals.Crystal5},
	[6] = {crystalPosition = Position(33390, 31478, 14), globalStorage = GlobalStorage.FerumbrasAscendantQuest.Crystals.Crystal6},
	[7] = {crystalPosition = Position(33387, 31475, 14), globalStorage = GlobalStorage.FerumbrasAscendantQuest.Crystals.Crystal7},
	[8] = {crystalPosition = Position(33387, 31471, 14), globalStorage = GlobalStorage.FerumbrasAscendantQuest.Crystals.Crystal8}
}

local config = {
	centerRoom = Position(33392, 31473, 14),
	BossPosition = Position(33392, 31473, 14),
	playerPositions = {
		Position(33269, 31477, 14),
		Position(33269, 31478, 14),
		Position(33269, 31479, 14),
		Position(33269, 31480, 14),
		Position(33269, 31481, 14),
		Position(33270, 31477, 14),
		Position(33270, 31478, 14),
		Position(33270, 31479, 14),
		Position(33270, 31480, 14),
		Position(33270, 31481, 14),
		Position(33271, 31477, 14),
		Position(33271, 31478, 14),
		Position(33271, 31479, 14),
		Position(33271, 31480, 14),
		Position(33271, 31481, 14)
	},
	newPosition = Position(33392, 31479, 14)
}


function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local playersTable = {}
	if item.itemid == 9825 then
		if player:getPosition() ~= Position(33270, 31477, 14) then
			item:transform(9826)
			return true
		end
	end
	if item.itemid == 9825 then
		if doCheckBossRoom(player:getId(), "Ascending Ferumbras", Position(33379, 31460, 14), Position(33405, 31485, 14)) then
			Game.createMonster("Ascending Ferumbras", config.BossPosition, true, true)
			for b = 1,10 do
				local xrand = math.random(-10, 10)
				local yrand = math.random(-10, 10)
				local position = Position(33392 + xrand, 31473 + yrand, 14)
				if Game.createMonster("rift invader", position) then
				end
			end
			for x = 33269, 33271 do
				for y = 31477, 31481 do
					local playerTile = Tile(Position(x, y, 14)):getTopCreature()
					if playerTile and playerTile:isPlayer() then
						playerTile:getPosition():sendMagicEffect(CONST_ME_POFF)
						playerTile:teleportTo(config.newPosition)
						playerTile:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
						playerTile:setStorageValue(Storage.FerumbrasAscension.FerumbrasTimer, os.stime() + 60 * 60 * 20 * 24)
						table.insert(playersTable, playerTile:getId())
					end
				end
			end		
			-- Reloading crystals and storages
			Game.setStorageValue(GlobalStorage.FerumbrasAscendantQuest.Crystals.AllCrystals, 0)
			Game.setStorageValue(GlobalStorage.FerumbrasAscendantQuest.FerumbrasEssence, 0)
			for _, crystal in pairs(crystals) do
				local pos = crystal.crystalPosition
				local stg = crystal.globalStorage
				local sqm = Tile(pos)
				if sqm then
					local item = sqm:getItemById(17586)
					if item then
						item:transform(17580)
					end
				end
				Game.setStorageValue(stg, 0)
			end
			addEvent(kickPlayersAfterTime, 30*60*1000, playersTable, Position(33379, 31460, 14), Position(33405, 31485, 14), Position(33319, 32318, 13))
			item:transform(9826)
		end
	elseif item.itemid == 9826 then
		item:transform(9825)
	end
	return true
end
