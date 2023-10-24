function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if item.actionid == 50724 and player:getStorageValue(Storage.CurseSpreads.roteiroquest) == 3 and player:getStorageValue(50724) == -1 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found a piece of parchment.")
		player:setStorageValue(50724, 1)
		player:addItem(30606, 1)
	elseif item.actionid == 50725 and player:getStorageValue(Storage.CurseSpreads.roteiroquest) == 3 and player:getStorageValue(50725) == -1 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found a piece of parchment.")
		player:setStorageValue(50725, 1)
		player:addItem(30678, 1)
	elseif item.actionid == 50726 and player:getStorageValue(Storage.CurseSpreads.roteiroquest) == 3 and player:getStorageValue(50726) == -1 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found a piece of parchment.")
		player:setStorageValue(50726, 1)
		player:addItem(30607, 1)
	elseif item.actionid == 50727 and player:getStorageValue(Storage.CurseSpreads.roteiroquest) == 3 and player:getStorageValue(50727) == -1 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found hastily scribbled note.")
		player:setStorageValue(50727, 1)
		player:addItem(30605, 1)
	else 
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "This is empty.")
	end
	return true
end