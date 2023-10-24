function onHealthChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
    if creature:getName():lower() == 'lady tenebris' then
		local spectators = Game.getSpectators(creature:getPosition(), false, false, 7, 7, 7, 7)
		for i = 1, #spectators do
			local spectator = spectators[i]
			if spectator:getName():lower() == 'shadow tentacle' then
				return primaryDamage*0.2, primaryType, secondaryDamage, secondaryType
			end
		end
	elseif creature:getName():lower() == 'mounted thorn knight' or creature:getName():lower() == 'the shielded thorn knight' or creature:getName():lower() == 'the enraged thorn knight' then
		local spectators = Game.getSpectators(creature:getPosition(), false, false, 7, 7, 7, 7)
		for i = 1, #spectators do
			local spectator = spectators[i]
			if spectator:getName():lower() == 'possessed tree' then
				return primaryDamage*0.2, primaryType, secondaryDamage, secondaryType
			end
		end
		primaryDamage = primaryDamage * 2
	end
	return primaryDamage, primaryType, secondaryDamage, secondaryType
end