function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if target.itemid == 9909 and player:getStorageValue(50731) == -1 and player:getStorageValue(Storage.CurseSpreads.roteiroquest) == 5 then
		item:getPosition():sendMagicEffect(CONST_ME_HEARTS)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "With the aid of the alchemical devices you create a distillate of the crimson nightshade. You can add the silver dust now.")
		item:remove(1)
		player:setStorageValue(50731, 1)
	else
		return false
	end
	return true
end