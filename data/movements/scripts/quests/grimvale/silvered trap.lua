function onStepIn(creature, item, position, fromPosition)
	local monster = creature:getMonster()
	if not monster then
		return true
	end
	if monster:getName():lower() ~= 'feroxa' then
		return true
	end
	if FEROXA_STAGE == 2 then
		creature:addHealth(-1000)
		item:remove(1)
		position:sendMagicEffect(CONST_ME_BLOCKHIT)
	end
	return true
end
