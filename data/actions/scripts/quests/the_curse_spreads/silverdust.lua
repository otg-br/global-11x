function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if target.itemid == 9909 and player:getStorageValue(50731) == 1 and player:getStorageValue(Storage.CurseSpreads.roteiroquest) == 5 then
		item:getPosition():sendMagicEffect(CONST_ME_HEARTS)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "With the aid of the alchemical devices you add silver dust to distilatte. You can add the gold dust now.")
		item:remove(1)
		player:setStorageValue(50731, 2)
	else
		return false
	end
	return true
end	