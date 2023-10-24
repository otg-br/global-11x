function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if target.uid == 3015 and player:getStorageValue(Storage.ExplorerSociety.TheSpectralStone) == 53 and player:getStorageValue(Storage.ExplorerSociety.Mission13) == 3 and player:getStorageValue(Storage.ExplorerSociety.SpectralStone) == 1 then -- mission taken from Angus
		player:setStorageValue(Storage.ExplorerSociety.TheSpectralStone, 54)
		player:setStorageValue(Storage.ExplorerSociety.Mission13, 4)
		toPosition:sendMagicEffect(CONST_ME_MAGIC_BLUE)
	elseif target.uid == 3016 and player:getStorageValue(Storage.ExplorerSociety.TheSpectralStone) == 54 and player:getStorageValue(Storage.ExplorerSociety.Mission13) == 4 and player:getStorageValue(Storage.ExplorerSociety.SpectralStone) == 1 then -- mission taken from Angus
		player:setStorageValue(Storage.ExplorerSociety.TheSpectralStone, 55)
		player:setStorageValue(Storage.ExplorerSociety.Mission13, 5)
		player:removeItem(4851, 1)
		toPosition:sendMagicEffect(CONST_ME_MAGIC_BLUE)
	elseif target.uid == 3016 and player:getStorageValue(Storage.ExplorerSociety.TheSpectralStone) == 53 and player:getStorageValue(Storage.ExplorerSociety.Mission13) == 3 and player:getStorageValue(Storage.ExplorerSociety.SpectralStone) == 2 then -- mission taken from Mortimer
		player:setStorageValue(Storage.ExplorerSociety.TheSpectralStone, 54)
		player:setStorageValue(Storage.ExplorerSociety.Mission13, 4)
		toPosition:sendMagicEffect(CONST_ME_MAGIC_BLUE)
	elseif target.uid == 3015 and player:getStorageValue(Storage.ExplorerSociety.TheSpectralStone) == 54 and player:getStorageValue(Storage.ExplorerSociety.Mission13) == 4  and player:getStorageValue(Storage.ExplorerSociety.SpectralStone) == 2 then -- mission taken from Mortimer
		player:setStorageValue(Storage.ExplorerSociety.TheSpectralStone, 55)
		player:setStorageValue(Storage.ExplorerSociety.Mission13, 5)
		player:removeItem(4851, 1)
		toPosition:sendMagicEffect(CONST_ME_MAGIC_BLUE)
	end
	return true
end
