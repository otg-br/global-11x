local containers  = {
	-- uid do container, posição do container, storage, valor da storage, recompensa
	[1] = {uniqueid = 23102, cPosition = Position(32736, 32282, 8), storage = Storage.DreamCourts.HauntedHouse.skeletonContainer, value = 1, reward = 33803, defaultItem = true},
	[2] = {uniqueid = 23103, cPosition = Position(33693, 32185, 8), storage = Storage.DreamCourts.Main.courtChest, value = 1, reward = 34639, defaultItem = true},
	[3] = {uniqueid = 23104, cPosition = Position(33711, 32108, 4), storage = Storage.DreamCourts.Main.courtChest, value = 1, reward = 34639, defaultItem = true},
	[4] = {uniqueid = 23105, cPosition = Position(33578, 32527, 14), storage = Storage.DreamCourts.BurriedCatedral.fishingRod, value = 1, reward = 34881, defaultItem = true},	
	[5] = {uniqueid = 23106, cPosition = Position(33599, 32533, 14), storage = Storage.DreamCourts.BurriedCatedral.barrelWord, value = 1, defaultItem = false, text = "The inside of this barrel's lid has a word written onto it: 'O'kteth'."},
	[6] = {uniqueid = 23107, cPosition = Position(33618, 32518, 14), storage = Storage.DreamCourts.BurriedCatedral.estatueWord, value = 1, defaultItem = false, text = "This statue has a word written on her hand: 'N'ogalu'."},
	[7] = {uniqueid = 23108, cPosition = Position(33638, 32507, 14), storage = Storage.DreamCourts.BurriedCatedral.bedWord, value = 1, defaultItem = false, text = "This end of the bed has a stack of notes hidden under it. There is only one word on all of them: 'T'sough'."},	
	[8] = {uniqueid = 23109, cPosition = Position(33703, 32185, 5), storage = Storage.DreamCourts.TheSevenKeys.Rosebush, value = 1, reward = 34486, defaultItem = true},
	[9] = {uniqueid = 23110, cPosition = Position(33663, 32192, 7), storage = Storage.DreamCourts.TheSevenKeys.Mushroom, value = 1, reward = 34502, defaultItem = true},
	[10] = {uniqueid = 23111, cPosition = Position(33671, 32203, 7), storage = Storage.DreamCourts.TheSevenKeys.Book, value = 1, reward = 34484, defaultItem = true},	
	[11] = {uniqueid = 23112, cPosition = Position(33683, 32125, 6), storage = Storage.DreamCourts.TheSevenKeys.OrcSkull, value = 1, reward = 34482, defaultItem = true},
	[12] = {uniqueid = 23113, cPosition = Position(31996, 31981, 13), storage = Storage.DreamCourts.TheSevenKeys.Recipe, value = 1, reward = 34640, defaultItem = true},
	[13] = {uniqueid = 23114, cPosition = Position(32017, 31981, 14), storage = Storage.DreamCourts.TheSevenKeys.MinotaurSkull, value = 1, reward = 34481, defaultItem = true},
	[14] = {uniqueid = 23115, cPosition = Position(32054, 31936, 13), storage = Storage.DreamCourts.TheSevenKeys.trollSkull, value = 1, reward = 34483, defaultItem = true},		
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local iPos = item:getPosition()
	for _, k in pairs(containers) do
		if iPos == k.cPosition and item:getUniqueId() == k.uniqueid then
			if player:getStorageValue(k.storage) < k.value then
				if k.defaultItem then
					player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found a " .. ItemType(k.reward):getName() ..".")
					player:addItem(k.reward, 1)
				else
					player:sendTextMessage(MESSAGE_EVENT_ADVANCE, k.text)
					if player:getStorageValue(Storage.DreamCourts.BurriedCatedral.wordCount) < 0 then
						player:setStorageValue(Storage.DreamCourts.BurriedCatedral.wordCount, 0)
					end
					player:setStorageValue(Storage.DreamCourts.BurriedCatedral.wordCount, player:getStorageValue(Storage.DreamCourts.BurriedCatedral.wordCount) + 1)
					if player:getStorageValue(Storage.DreamCourts.BurriedCatedral.wordCount) == 4 then
						player:addAchievement("Tied the Knot")
					end
				end
				player:setStorageValue(k.storage, k.value)
			else
				if k.defaultItem then
					player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "It is empty.")
				end
			end	
		end
	end
	return true
end



