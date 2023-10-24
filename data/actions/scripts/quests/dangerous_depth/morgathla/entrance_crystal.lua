local checkStorage = Storage.DangerousDepths.Bosses.lastAchievement
local positionTeleport = Position(33681, 32383, 15)

function onUse(player, item, fromPosition, toPosition)	
	if not player:isPlayer() then
		return false
	end	
	if player:getStorageValue(checkStorage) == 1 then
		player:teleportTo(positionTeleport)
		player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
	else
		player:sendCancelMessage('Before you use the crystal, you need to kill the Warzone IV, V and VI bosses.')
		return true
	end	
	return true
end
