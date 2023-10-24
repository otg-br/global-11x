local transform = {
	[10029] = 10030,
	[10030] = 10029
}

local leverInfo = {
	[1] = {bossName = "Faceless Bane", bossPosition = Position(33617, 32561, 13), leverPosition = Position(33637, 32562, 13),
	pushPosition = Position(33638, 32562, 13), leverFromPos = Position(33638, 32562, 13), leverToPos = Position(33642, 32562, 13),
	storageTimer = Storage.DreamCourts.BurriedCatedral.facelessTimer, roomFromPosition = Position(33606, 32552, 13),
	roomToPosition = Position(33631, 32572, 13), teleportTo = Position(33617, 32567, 13), typePush = "x", exitPosition = Position(33619, 32522, 15),
	globalTimer = GlobalStorage.DreamCourts.BurriedCatedral.facelessTimer},
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not player then
		return true
	end
	local playersTable = {}
	local iPos = item:getPosition()
	local pPos = player:getPosition()
	if item.itemid == 10029 then
		for i = 1, #leverInfo do
			if iPos == leverInfo[i].leverPosition then
				local leverTable = leverInfo[i]
				if pPos == leverTable.pushPosition then
					if doCheckBossRoom(player:getId(), leverTable.bossName, leverTable.roomFromPosition, leverTable.roomToPosition) then
						if leverTable.typePush == "x" then
							for i = leverTable.leverFromPos.x, leverTable.leverToPos.x do
								local newPos = Position(i, leverTable.leverFromPos.y, leverTable.leverFromPos.z)
								local creature = Tile(newPos):getTopCreature()
								if creature and creature:isPlayer() then
									creature:teleportTo(leverTable.teleportTo)
									creature:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
									creature:setStorageValue(leverInfo.storageTimer, os.stime() + 20*60*60)
									table.insert(playersTable, creature:getId())	
								end
							end
						elseif leverTable.typePush == "y" then
							for i = leverTable.leverFromPos.y, leverTable.leverToPos.y do
								local newPos = Position(leverTable.leverFromPos.x, i, leverTable.leverFromPos.z)
								local creature = Tile(newPos):getTopCreature()
								if creature and creature:isPlayer() then
									creature:teleportTo(leverTable.teleportTo)
									creature:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
									creature:setStorageValue(leverInfo.storageTimer, os.stime() + 20*60*60)	
									table.insert(playersTable, creature:getId())	
								end
							end					
						end
						local monster = Game.createMonster(leverTable.bossName, leverTable.bossPosition, true, true)
						if monster then
							if leverTable.bossName:lower() == "faceless bane" then
								monster:registerEvent("facelessThink")
								Game.setStorageValue(GlobalStorage.DreamCourts.BurriedCatedral.facelessTiles, 0)
							-- elseif leverTable.bossName == "[nextboss]" then 	
							end
							monster:registerEvent("dreamCourtsDeath")
							-- Caso o monstro seja de um tipo especifico, lembrar de sempre registrar este evento!
						end
						addEvent(kickPlayersAfterTime, 30*60*1000, playersTable, leverTable.roomFromPosition, leverTable.roomToPosition, leverTable.exitPosition)
					end
				end
			end
		end
	end
	item:transform(transform[item.itemid])	
	return true
end
