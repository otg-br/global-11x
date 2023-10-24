function onKill(player, target)
	if target:isPlayer() or target:getMaster() then
		return true
	end
	for playerid, damage in pairs(target:getDamageMap()) do
		local p = Player(playerid)
		if p then
			local targetName, startedTasks, taskId = target:getName():lower(), p:getStartedTasks()
			for i = 1, #startedTasks do
				taskId = startedTasks[i]
				if isInArray(tasks[taskId].creatures, targetName) then
					local killAmount = p:getStorageValue(KILLSSTORAGE_BASE + taskId)
					if killAmount < tasks[taskId].killsRequired then
						if (p:getAccountType() >= ACCOUNT_TYPE_GOD) then
							p:setStorageValue(KILLSSTORAGE_BASE + taskId, tasks[taskId].killsRequired)
							return true
						end
						p:setStorageValue(KILLSSTORAGE_BASE + taskId, killAmount + 1)
					end
				end
			end			
		end
	end
	return true
end