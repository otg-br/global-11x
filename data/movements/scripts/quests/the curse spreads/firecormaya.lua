function onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end
	if player:getStorageValue(50734) >= 1 then
		player:teleportTo(Position(33405, 32018, 9))
	else
		player:teleportTo(Position(33397, 32025, 9))
		player:sendCancelMessage("You need to prove yourself worthy to enter this portal.")
	end
	return true
end