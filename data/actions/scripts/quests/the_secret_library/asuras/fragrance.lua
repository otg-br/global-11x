function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 'Hmmmm, what an infatuating fragrance!')
	player:setStorageValue('fragrance', os.stime() + 10*60)
	item:remove(1)
	return true
end