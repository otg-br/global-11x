local function roomIsOccupied(centerPosition, rangeX, rangeY)
	local spectators = Game.getSpectators(centerPosition, false, true, rangeX, rangeX, rangeY, rangeY)
	if #spectators ~= 0 then
		return true
	end

	return false
end

function clearBossRoom(playerId, bossId, centerPosition, rangeX, rangeY, exitPosition)
	local spectators, spectator = Game.getSpectators(centerPosition, false, false, rangeX, rangeX, rangeY, rangeY)
	for i = 1, #spectators do
		spectator = spectators[i]
		if spectator:isPlayer() and spectator.uid == playerId then
			spectator:teleportTo(exitPosition)
			exitPosition:sendMagicEffect(CONST_ME_TELEPORT)
		end

		if spectator:isMonster() and spectator.uid == bossId then
			spectator:remove()
		end
	end
end

--[[
blackvixen = AID 50739, {x = 33442, y = 32051, z = 9}
shadowpelt = AID 50740, 
sharpclaw = AID 50741,
darkfang = AID 50742,
bloodback = AID 50743, 
]]

local bosses = {
	[50739] = {bossName = 'black vixen', storage = 50739, playerPosition = Position(33447, 32040, 9), bossPosition = Position(33448, 32028, 9), centerPosition = Position(33450, 32034, 9), rangeX = 6, rangeY = 7, flamePosition = Position(33454, 32027, 9)},
	[50740] = {bossName = 'shadowpelt', storage = 50740, playerPosition = Position(33396, 32112, 9), bossPosition = Position(33377, 32114, 9), centerPosition = Position(33386, 32113, 9), rangeX = 11, rangeY = 5, flamePosition = Position(33374, 32114, 9)},
	[50741] = {bossName = 'sharpclaw', storage = 50741, playerPosition = Position(33121, 31996, 9), bossPosition = Position(33120, 32005, 9), centerPosition = Position(33120, 32001, 9), rangeX = 7, rangeY = 6, flamePosition = Position(33118, 32007, 9)},
	[50742] = {bossName = 'darkfang', storage = 50742, playerPosition = Position(33055, 31889, 9), bossPosition = Position(33067, 31888, 9), centerPosition = Position(33060, 31889, 9), rangeX = 8, rangeY = 7, flamePosition = Position(33068, 31889, 9)},
	[50743] = {bossName = 'bloodback', storage = 50743, playerPosition = Position(33180, 32012, 8), bossPosition = Position(33190, 32015, 8), centerPosition = Position(33183, 32014, 8), rangeX = 8, rangeY = 5, flamePosition = Position(33192, 32015, 8)}
}

function onStepIn(creature, item, position, fromPosition)

	--Se nao for player passando no tp
	local player = creature:getPlayer()
	if not player then
		return true
	end
	
	if player:getStorageValue(Storage.CurseSpreads.roteiroquest) <= 14 then
		player:sendTextMessage(MESSAGE_STATUS_SMALL, "You're not ready for this mission.")
		player:teleportTo(fromPosition)
		return true
	end
	
	local boss = bosses[item.uid] or bosses[item:getActionId()]
	if not boss then
		return true
	end

	
	local specs, spec = Game.getSpectators(boss.centerPosition, false, false, boss.rangeX, boss.rangeX, boss.rangeY, boss.rangeY)
	
	for i = 1, #specs do
		spec = specs[i]
		if spec:isPlayer() then
			player:sendTextMessage(MESSAGE_STATUS_SMALL, "A player is already inside the quest room.")
			player:teleportTo(fromPosition)
			return true
		end

		spec:remove()
	end

	if player:getStorageValue(boss.storage) <= os.stime() then
		player:setStorageValue(boss.storage, os.stime() + 20 * 60 * 60)
		player:teleportTo(boss.playerPosition)
		boss.playerPosition:sendMagicEffect(CONST_ME_TELEPORT)
	else
		player:sendTextMessage(MESSAGE_STATUS_SMALL, "You can kill the monster once a day.")
		player:teleportTo(fromPosition)
		return true
	end
	
	local monster = Game.createMonster(boss.bossName, boss.bossPosition)
	if not monster then
		return true
	end

	addEvent(clearBossRoom, 60 * 10 * 1000, player.uid, monster.uid, boss.centerPosition, boss.rangeX, boss.rangeY, fromPosition)
	player:say('You have ten minutes to kill and loot this boss. Otherwise you will lose that chance and will be kicked out.', TALKTYPE_MONSTER_SAY)
	return true
end
