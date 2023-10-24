local chests = {
	[4910] = {storage = Storage.secretLibrary.Asuras.strandHair, reward = 33042},
	[4911] = {storage = Storage.secretLibrary.Asuras.skeletonNotes, reward = 33063,
	message = "You have discovered a skeleton. It seems to hold an old letter and its skull is missing."},
	[4912] = {storage = Storage.secretLibrary.Asuras.eyeKey, reward = 33034},
	[4913] = {storage = Storage.secretLibrary.Asuras.scribbledNotes, reward = 33061},
	[4914] = {storage = Storage.secretLibrary.Asuras.lotusKey, reward = 33033},
	[4915] = {storage = Storage.secretLibrary.Asuras.peacockBallad, reward = 33212},
	[4916] = {storage = Storage.secretLibrary.Asuras.blackSkull, reward = 33041},
	[4917] = {storage = Storage.secretLibrary.Asuras.ebonyPiece, reward = 33043},
	[4918] = {storage = Storage.secretLibrary.Asuras.silverChimes, reward = 33046,
	message = "You see silver chimes dangling on the dragon statue in this room."}
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local chest = chests[item.uid]
	if not chests[item.uid] then
		return true
	end
	if player:getStorageValue(chest.storage) ~= 1 then
		player:addItem(chest.reward, 1)
		player:setStorageValue(chest.storage, 1)
		if not chest.message then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 'You have found a ' .. ItemType(chest.reward):getName():lower() .. '.')
		else
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, chest.message)
		end
	else
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 'It is empty.')
	end
	return true
end