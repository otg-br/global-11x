local conditions = {
	CONDITION_POISON, CONDITION_BLEEDING, CONDITION_FIRE, CONDITION_ENERGY, CONDITION_CURSED
}

function onCastSpell(creature, var)
	local hasCondition = false
	for i = 1, #conditions do
		if creature:getCondition(conditions[i]) then
			hasCondition = true
		end
	end
	if hasCondition then
		local pos = creature:getPosition()
		pos.y = pos.y - 1
		Game.createMonster('corrupted soul', pos, true, true)
		creature:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
	end		
    return true
end