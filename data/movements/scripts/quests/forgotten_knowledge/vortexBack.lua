function onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return
	end
	player:teleportTo(Position(31986, 32846, 14))
	player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
end
