local redItems = {
	2655, 2485, 2494, 8867, 8881, 8892, 25190, 2487, 8819, 2486, 11356, 2653
}

function onHealthChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
	if not attacker or not creature then
		return primaryDamage, primaryType, secondaryDamage, secondaryType
	end
	if attacker:isPlayer() then
		if creature:getName():lower() == 'the diamond blossom' then
			local slot = attacker:getSlotItem(CONST_SLOT_ARMOR)
			if slot then
				for i = 1, #redItems do
					if slot.itemid == redItems[i] then
						return primaryDamage, primaryType, secondaryDamage, secondaryType
					end
				end			
			end
		elseif creature:getName():lower() == 'the blazing rose' then
			local slot = attacker:getSlotItem(CONST_SLOT_RIGHT)
			if slot and slot.itemid == 33046 then
				return primaryDamage, primaryType, secondaryDamage, secondaryType
			end
		elseif creature:getName():lower() == 'the lily of night' then
			if attacker:getStorageValue('fragrance') > os.stime() then
				return primaryDamage, primaryType, secondaryDamage, secondaryType
			end
		end
	end
	primaryDamage = 0
	secondaryDamage = 0	
	return primaryDamage, primaryType, secondaryDamage, secondaryType
end
