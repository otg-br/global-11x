local basin = 1484
local finalBasin = Position(33339, 32117, 10)
function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if item.itemid == 33211 then
		if target.itemid == 32435 then
			item:remove(1)
			player:addItem(33210, 1)
		end
	elseif item.itemid == 33210 then
		if target.itemid == basin then
			item:setAttribute(ITEM_ATTRIBUTE_DURATION, 15*1000)
			player:say('Recharging...', TALKTYPE_MONSTER_SAY)
		else
			if target:getPosition() == finalBasin and player:getStorageValue(Storage.secretLibrary.MoTA.finalBasin) ~= 1 then
				target:getPosition():sendMagicEffect(CONST_ME_DRAWBLOOD)
				player:setStorageValue(Storage.secretLibrary.MoTA.finalBasin, 1)
			end
		end
	end
	return true
end



