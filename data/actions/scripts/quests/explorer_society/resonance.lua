function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if target.uid == 3018 then
		if player:getStorageValue(Storage.ExplorerSociety.TheIceMusic) == 60 and player:getStorageValue(Storage.ExplorerSociety.Mission16) == 1 then
			player:setStorageValue(Storage.ExplorerSociety.TheIceMusic, 61)
			player:setStorageValue(Storage.ExplorerSociety.Mission16, 2)
			toPosition:sendMagicEffect(CONST_ME_MAGIC_BLUE)
			item:transform(7315)
		end
	end
	return true
end
