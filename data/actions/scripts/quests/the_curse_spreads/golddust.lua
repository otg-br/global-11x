function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if target.itemid == 9909 and player:getStorageValue(50731) == 2 and player:getStorageValue(Storage.CurseSpreads.roteiroquest) == 5 then
		item:getPosition():sendMagicEffect(CONST_ME_HEARTS)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "With the aid of the alchemical devices you add gold dust to distilatte. You can add the shadow bite berries now.")
		item:remove(1)
		player:setStorageValue(50731, 3)
	else
		return false
	end
	return true
end