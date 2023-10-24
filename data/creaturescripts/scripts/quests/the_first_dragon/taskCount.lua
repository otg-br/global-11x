function onKill(creature, target)
	if not creature or not creature:isPlayer() then
		return true
	end
	if not target or not target:isMonster() then
		return true
	end
	local cName = target:getName():lower()
	local stgValue = creature:getStorageValue(Storage.TheFirstDragon.dragonTaskCount)
	if creature:getStorageValue(Storage.TheFirstDragon.tamorilTasksPower) >= 0 then	
		if(isInArray({'dragon'}, cName) and stgValue < 200)then
			creature:setStorageValue(Storage.TheFirstDragon.dragonTaskCount, stgValue + 1)
		end
		if stgValue >= 200 and creature:getStorageValue(Storage.TheFirstDragon.tamorilTasksPower) < 1 then
			creature:setStorageValue(Storage.TheFirstDragon.tamorilTasksPower, 1)
		end
	end
	return true
end