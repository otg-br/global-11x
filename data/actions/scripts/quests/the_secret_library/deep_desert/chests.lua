local chests = {
	[1] = {position = Position(32970, 32314, 9), storage = Storage.secretLibrary.Darashia.firstChest, reward = 33080,
	questlog = true},
	[2] = {position = Position(32980, 32308, 9), storage = Storage.secretLibrary.Darashia.secondChest, reward = 33078,
	questlog = true},
	[3] = {position = Position(32955, 32282, 10), storage = Storage.secretLibrary.Darashia.thirdChest, reward = 33079,
	questlog = false},
	[4] = {position = Position(32983, 32289, 10), storage = Storage.secretLibrary.Darashia.fourthChest, reward = 33077,
	questlog = false},
	[5] = {position = Position(32944, 32309, 8), storage = Storage.secretLibrary.Darashia.fifthChest, reward = 33297,
	questlog = true}
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	for _, k in pairs(chests) do
		if toPosition == k.position then
			if player:getStorageValue(k.storage) ~= 1 then			
				if k.questlog then
					player:setStorageValue(Storage.secretLibrary.Darashia.Questline, player:getStorageValue(Storage.secretLibrary.Darashia.Questline)+1)
				end
				player:addItem(k.reward, 1)
				player:setStorageValue(k.storage, 1)
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 'You have found a ' .. ItemType(k.reward):getName():lower() .. '.')
			else
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 'It is empty.')
			end
		end
	end
	return true
end