function onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return
	end
	player:teleportTo(Position(33395, 32670, 6))
	return true
end
