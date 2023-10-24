function onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return
	end
	player:teleportTo(Position(item:getPosition().x, item:getPosition().y, item:getPosition().z + 1))
	player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
end
