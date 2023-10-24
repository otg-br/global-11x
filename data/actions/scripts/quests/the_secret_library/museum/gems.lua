local basins = {
	[1] = {position = Position(33219, 32100, 9), item = 32456, storage = Storage.secretLibrary.MoTA.yellowGem},
	[2] = {position = Position(33260, 32084, 9), item = 32455, storage = Storage.secretLibrary.MoTA.greenGem},
	[3] = {position = Position(33318, 32090, 9), item = 32457, storage = Storage.secretLibrary.MoTA.redGem},
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	for _, p in pairs(basins) do
		if p.item == item.itemid then
			if player:getStorageValue(p.storage) < 1 then
				target:getPosition():sendMagicEffect(CONST_ME_SOUND_PURPLE)
				player:setStorageValue(p.storage, 1)
				item:remove(1)
			end
		end
	end
	return true
end



