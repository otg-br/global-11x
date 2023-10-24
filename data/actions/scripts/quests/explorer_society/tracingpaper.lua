function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if target.itemid == 1560 and target.uid == 3010 and player:getStorageValue(Storage.ExplorerSociety.TheRuneWritings) == 42 and player:getStorageValue(Storage.ExplorerSociety.Mission10) == 1 then
		player:setStorageValue(Storage.ExplorerSociety.TheRuneWritings, 43)
		player:setStorageValue(Storage.ExplorerSociety.Mission10, 2)
		item:transform(4854)
		toPosition:sendMagicEffect(CONST_ME_MAGIC_BLUE)
	end
	return true
end
