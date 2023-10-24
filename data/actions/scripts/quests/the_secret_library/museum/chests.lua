local chests = {
	[4900] = {storage = Storage.secretLibrary.MoTA.sampleBlood, reward = 32462},
	[4901] = {storage = Storage.secretLibrary.MoTA.bonyRod, reward = 32435},
	[4902] = {storage = Storage.secretLibrary.MoTA.brokenCompass, reward = 29},
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local chest = chests[item.uid]
	if not chests[item.uid] then
		return true
	end
	if player:getStorageValue(chest.storage) ~= 1 then
		player:addItem(chest.reward, 1)
		player:setStorageValue(chest.storage, 1)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 'You have found a ' .. ItemType(chest.reward):getName():lower() .. '.')
	else
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 'It is empty.')
	end
	return true
end