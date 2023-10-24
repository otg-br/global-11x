function onStepIn(creature, item, position, fromPosition)
	if not creature:isPlayer() then	return true end
	if item.actionid == 4502 then
		if not TheLastMan:onJoin(creature) then
			creature:teleportTo(fromPosition)
			creature:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		end
	elseif item.actionid == 4503 then
		creature:teleportTo(fromPosition)
		creature:sendCancelMessage("Você não pode andar em pisos que já explodiram.")
	end
	return true
end
