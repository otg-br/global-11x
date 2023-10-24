--workingfunction
function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if target.itemid == 9909 and player:getStorageValue(50731) == 3 and player:getStorageValue(Storage.CurseSpreads.roteiroquest) == 5 then
		item:getPosition():sendMagicEffect(CONST_ME_HEARTS)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "With the aid of the alchemical devices you add shadow bite berries to the distillate. The cure is complete!")
		item:remove(1)
		player:addItem(30696, 1)
		player:setStorageValue(50731, -1)
		player:setStorageValue(Storage.CurseSpreads.roteiroquest, 6)
	else
		return false
	end
	return true
end