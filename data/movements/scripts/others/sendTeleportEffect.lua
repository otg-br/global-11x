function onStepIn(creature, item, position, fromPosition)
	if not creature:isPlayer() then return true end
	if (creature:getCondition(CONDITION_DROWN)) then
		creature:removeCondition(CONDITION_DROWN)
	end
	creature:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
	return true
end