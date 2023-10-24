local chests = {
	[4920] = {storage = Storage.secretLibrary.SmallIslands.Parchment, reward = 33166, amount = 1},
	[4921] = {storage = Storage.secretLibrary.SmallIslands.Sapphire, reward = 7759, amount = 2},
	[4922] = {storage = Storage.secretLibrary.SmallIslands.Fishing, reward = 2580, amount = 1},
	[4923] = {storage = Storage.secretLibrary.SmallIslands.Shovel, reward = 2554, amount = 1},
	[4925] = {storage = Storage.secretLibrary.SmallIslands.Hawser, reward = 33209, amount = 1},
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local chest = chests[item.uid]
	if not chests[item.uid] then
		return true
	end
	local article = 'a'
	if player:getStorageValue(chest.storage) ~= 1 then
		player:addItem(chest.reward, chest.amount)
		player:setStorageValue(chest.storage, 1)
		if chest.amount > 1 then
			article = '' ..chest.amount
		end
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format('You have found %s %s.', article, ItemType(chest.reward):getName():lower()))
	else
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 'It is empty.')
	end
	return true
end