local config = {
	centerRoom = Position(32799, 32832, 14),
	bossPosition = Position(32799, 32827, 14),
	newPosition = Position(32800, 32831, 14)
}

local monsters = {
	{cosmic = 'cosmic energy prism a', pos = Position(32801, 32827, 14)},
	{cosmic = 'cosmic energy prism b', pos = Position(32798, 32827, 14)},
	{cosmic = 'cosmic energy prism c', pos = Position(32803, 32826, 14)},
	{cosmic = 'cosmic energy prism d', pos = Position(32796, 32826, 14)}
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if item.itemid == 9825 then
		if player:getPosition() ~= Position(32759, 32868, 14) then
			item:transform(9826)
			return true
		end
	end
	if item.itemid == 9825 then
		local playersTable = {}
		if doCheckBossRoom(player:getId(), "Lloyd", Position(32785, 32814, 14), Position(32812, 32838, 14)) then
			for n = 1, #monsters do
				Game.createMonster(monsters[n].cosmic, monsters[n].pos, true, true)
			end
			Game.createMonster("lloyd", config.bossPosition, true, true)
			for y = 32868, 32872 do
				local playerTile = Tile(Position(32759, y, 14)):getTopCreature()
				if playerTile and playerTile:isPlayer() then
					playerTile:getPosition():sendMagicEffect(CONST_ME_POFF)
					playerTile:teleportTo(config.newPosition)
					playerTile:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
					playerTile:setStorageValue(Storage.ForgottenKnowledge.LloydTimer, os.stime() + 20 * 60 * 60)
					table.insert(playersTable, playerTile:getId())
				end
			end
			addEvent(kickPlayersAfterTime, 30*60*1000, playersTable, Position(32785, 32814, 14), Position(32812, 32838, 14), Position(32815, 32873, 13))
			item:transform(9826)
		end
	elseif item.itemid == 9826 then
		item:transform(9825)
	end
	return true
end
