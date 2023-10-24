function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    if player:getStorageValue(Storage.ExplorerSociety.TheIslandofDragons) == 57 and player:getStorageValue(Storage.ExplorerSociety.Mission15) == 1 then
        player:setStorageValue(Storage.ExplorerSociety.TheIslandofDragons, 58)
		player:setStorageValue(Storage.ExplorerSociety.Mission15, 2)
        player:addItem(7314, 1)
        toPosition:sendMagicEffect(CONST_ME_MAGIC_BLUE)
    end
    return true
end
