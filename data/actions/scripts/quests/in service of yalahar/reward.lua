local rewardTable = {
	[3088] = {id = 9776, count = 1},
	[3089] = {id = 9778, count = 1},
	[3090] = {id = 9777, count = 1}
}


function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local chest = rewardTable[item.uid]
	if not chest then return true end
	local _itemType = ItemType(chest.id)
	local questline = player:getStorageValue(Storage.InServiceofYalahar.Questline)
	if questline == 53 then
		if player:getFreeCapacity() < _itemType:getWeight() then
			player:getPosition():sendMagicEffect(CONST_ME_POFF)
			player:sendCancelMessage(string.format('You have found %s weighing %.2f oz. You have no capacity.', _itemType:getName(), (_itemType:getWeight()/100)))
			return true
		end
		player:setStorageValue(Storage.InServiceofYalahar.Questline, 54)
		player:setStorageValue(Storage.InServiceofYalahar.Mission10, 5)						
		player:addItem(chest.id, chest.count)		
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found a ".. _itemType:getName() ..".")
		player:addOutfitAddon(324, 2)
		player:addOutfitAddon(324, 1)
		player:addOutfitAddon(325, 1)
		player:addOutfitAddon(325, 2)
	else
		player:sendCancelMessage('The chest is empty.')
	end
	return true
end
