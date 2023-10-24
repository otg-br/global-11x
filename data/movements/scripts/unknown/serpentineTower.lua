local config = {
	[5630] = {destination = Position(33145, 32863, 7), effect = CONST_ME_MAGIC_GREEN},
	[5631] = {destination = Position(33147, 32864, 7), effect = CONST_ME_MAGIC_GREEN}
}

function onStepIn(creature, item, position, fromPosition)
	if not creature:isPlayer() then return true end
	local k = config[item.actionid]
	if k then
		creature:teleportTo(k.destination)
		creature:getPosition():sendMagicEffect(k.effect)
	end
	return true
end