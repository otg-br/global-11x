local config = {
	centerRoom = Position(32912, 31599, 14),
	bossPosition = Position(32912, 31599, 14),
	newPosition = Position(32911, 31603, 14)
}

local function clearTenebris()
	local spectators = Game.getSpectators(config.centerRoom, false, false, 15, 15, 15, 15)
	for i = 1, #spectators do
		local spectator = spectators[i]
		if spectator:isPlayer() then
			spectator:teleportTo(Position(32902, 31629, 14))
			spectator:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
			spectator:say('Time out! You were teleported out by strange forces.', TALKTYPE_MONSTER_SAY)
		elseif spectator:isMonster() then
			spectator:remove()
		end
	end
end

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if item.itemid == 9825 then
		if player:getPosition() ~= Position(32902, 31623, 14) then
			return true
		end
	end
	if item.itemid == 9825 then
		local playersTable = {}
		if doCheckBossRoom(player:getId(), "Lady Tenebris", Position(32902, 31589, 14), Position(32924, 31610, 14)) then
			for d = 1, 6 do
				Game.createMonster('shadow tentacle', Position(math.random(32909, 32914), math.random(31596, 31601), 14), true, true)
			end
			Game.createMonster("lady tenebris", config.bossPosition, true, true)
			for y = 31623, 31627 do
				local playerTile = Tile(Position(32902, y, 14)):getTopCreature()
				if playerTile and playerTile:isPlayer() then
					playerTile:getPosition():sendMagicEffect(CONST_ME_POFF)
					playerTile:teleportTo(config.newPosition)
					playerTile:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
					playerTile:setStorageValue(Storage.ForgottenKnowledge.LadyTenebrisTimer, os.stime() + 20 * 60 * 60)
					table.insert(playersTable, playerTile:getId())
				end
			end
			addEvent(kickPlayersAfterTime, 30*60*1000, playersTable, Position(32902, 31589, 14), Position(32924, 31610, 14), Position(32919, 31639, 14))
			item:transform(9826)
		end
	elseif item.itemid == 9826 then
		item:transform(9825)
	end
	return true
end