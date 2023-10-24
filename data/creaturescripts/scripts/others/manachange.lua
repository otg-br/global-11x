function onManaChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
	if creature:isPlayer() and creature:getParty() then
		creature:broadcastUpdateInfo(CONST_PARTY_MANA, creature:getId())
	end
	return primaryDamage, primaryType, secondaryDamage, secondaryType
end