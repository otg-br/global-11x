function onUse(player, item, fromPosition, itemEx, toPosition)
	if player:getStorageValue(Storage.secretLibrary.SmallIslands.boatStages) == 2 then
		player:setStorageValue(Storage.secretLibrary.SmallIslands.boatStages, 3)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 'The telescope provides a perfect view over the endless ocean - no land in sight')
	end
	return true
end