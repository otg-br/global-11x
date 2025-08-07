local resetStorage = TalkAction("/resetStorage")
function resetStorage.onSay(player, words, param)
	if not player:getGroup():getAccess() then
		return true
	end

	if player:getAccountType() < ACCOUNT_TYPE_GOD then
		return false
	end

	local split = param:splitTrimmed(",")
	local target = Player(split[1])

	if not target then
		player:sendCancelMessage("Player not found.")
		return false
	end

	local resetType = split[2]
	if not resetType then
		player:sendCancelMessage("Usage: /resetStorage playerName, resetType")
		player:sendCancelMessage("Available types: StoreBoostXp, StoreBoostXpDB, All")
		return false
	end

	resetType = resetType:lower():trim()

	if resetType == "storeboostxp" then
		-- Reset Store XP Boost
		target:setStorageValue(51052, -1)  -- ExpBoost counter
		target:setStorageValue(51053, -1)  -- Last bought timestamp
		target:setExpBoostStamina(0)       -- XP Boost time
		target:setStoreXpBoost(0)          -- XP Boost value
		
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, 
			string.format("Store XP Boost reset for %s:", target:getName()))
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, 
			"- Storage 51052 (counter) = -1")
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, 
			"- Storage 51053 (timestamp) = -1")
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, 
			"- ExpBoostStamina = 0")
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, 
			"- StoreXpBoost = 0")
		
		target:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your Store XP Boost has been reset by a Game Master.")
		target:sendStats()

	elseif resetType == "storeboostxpdb" then
		-- Reset Store XP Boost including database fields
		target:setStorageValue(51052, -1)  -- ExpBoost counter
		target:setStorageValue(51053, -1)  -- Last bought timestamp
		target:setExpBoostStamina(0)       -- XP Boost time (database field)
		target:setStoreXpBoost(0)          -- XP Boost value (database field)
		
		-- Force save to database
		target:save()
		
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, 
			string.format("Store XP Boost + Database reset for %s:", target:getName()))
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, 
			"- Storage 51052 (counter) = -1")
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, 
			"- Storage 51053 (timestamp) = -1")
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, 
			"- ExpBoostStamina = 0 (saved to DB)")
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, 
			"- StoreXpBoost = 0 (saved to DB)")
		
		target:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your Store XP Boost has been completely reset by a Game Master.")
		target:sendStats()

	elseif resetType == "all" then
		-- Reset all XP related storages and boosts
		target:setStorageValue(51052, -1)  -- ExpBoost counter
		target:setStorageValue(51053, -1)  -- Last bought timestamp
		target:setExpBoostStamina(0)       -- XP Boost time (database field)
		target:setStoreXpBoost(0)          -- XP Boost value (database field)
		target:setGrindingXpBoost(0)       -- Grinding boost
		
		-- Force save to database
		target:save()
		
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, 
			string.format("All XP boosts reset for %s:", target:getName()))
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, 
			"- Store XP Boost: RESET (saved to DB)")
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, 
			"- Grinding Boost: RESET")
		
		target:sendTextMessage(MESSAGE_EVENT_ADVANCE, "All your XP boosts have been reset by a Game Master.")
		target:sendStats()

	else
		player:sendCancelMessage("Invalid reset type. Available: StoreBoostXp, StoreBoostXpDB, All")
		return false
	end

	return false
end
resetStorage:separator(" ")
resetStorage:register()