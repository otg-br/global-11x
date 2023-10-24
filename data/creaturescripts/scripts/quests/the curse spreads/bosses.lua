function onKill(creature, target)
	local targetMonster = target:getMonster()
	if not targetMonster then
		return true
	end

	local player = creature:getPlayer()
	if targetMonster:getName():lower() == 'black vixen' then
		creature:setStorageValue(50745, 1)
		return true
	elseif targetMonster:getName():lower() == 'shadowpelt' then
		creature:setStorageValue(50746, 1)
		return true
	elseif targetMonster:getName():lower() == 'sharpclaw' then
		creature:setStorageValue(50747, 1)
		return true
	elseif targetMonster:getName():lower() == 'darkfang' then
		creature:setStorageValue(50748, 1)
		return true
	elseif targetMonster:getName():lower() == 'bloodback' then
		creature:setStorageValue(50749, 1)
		return true
	end
	return true
end