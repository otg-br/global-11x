function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if target.itemid == 4993 and player:getStorageValue(Storage.ExplorerSociety.TheButterflyHunt) == 8  and player:getStorageValue(Storage.ExplorerSociety.Mission03) == 1 then
		player:setStorageValue(Storage.ExplorerSociety.TheButterflyHunt, 9)
		player:setStorageValue(Storage.ExplorerSociety.Mission03, 2)
		toPosition:sendMagicEffect(CONST_ME_MAGIC_BLUE)
		item:transform(4866)
		target:remove()
	elseif target.itemid == 4994 and player:getStorageValue(Storage.ExplorerSociety.TheButterflyHunt) == 11 and player:getStorageValue(Storage.ExplorerSociety.Mission03) == 4 then
		player:setStorageValue(Storage.ExplorerSociety.TheButterflyHunt, 12)
		player:setStorageValue(Storage.ExplorerSociety.Mission03, 5)
		toPosition:sendMagicEffect(CONST_ME_MAGIC_BLUE)
		item:transform(4867)
		target:remove()
	elseif target.itemid == 4992 and player:getStorageValue(Storage.ExplorerSociety.TheButterflyHunt) == 14 and player:getStorageValue(Storage.ExplorerSociety.Mission03) == 8 then
		player:setStorageValue(Storage.ExplorerSociety.TheButterflyHunt, 15)
		player:setStorageValue(Storage.ExplorerSociety.Mission03, 9)
		toPosition:sendMagicEffect(CONST_ME_MAGIC_BLUE)
		item:transform(4868)
		target:remove()
	end
	return true
end
