function onSay(player, words, param)
	-- XP Info Command
	local message = "=== XP BOOST INFO ===\n"
	local totalMultiplier = 1.0
	local hasAnyBoost = false
	
	-- VIP Bonus
	if player:getVipDays() > os.stime() then
		message = message .. "VIP Bonus: +10% (Active)\n"
		totalMultiplier = totalMultiplier * 1.10
		hasAnyBoost = true
	else
		message = message .. "VIP Bonus: Not Active\n"
	end
	
	-- Store XP Boost
	local expBoostTime = player:getExpBoostStamina()
	if player:getStoreXpBoost() > 0 and expBoostTime > 0 then
		local hours = math.floor(expBoostTime / 3600)
		local minutes = math.floor((expBoostTime % 3600) / 60)
		message = message .. string.format("Store XP Boost: +50%% (Active - %dh %dm left)\n", hours, minutes)
		totalMultiplier = totalMultiplier + 0.5
		hasAnyBoost = true
	else
		message = message .. "Store XP Boost: Not Active\n"
	end
	
	-- Grinding Boost
	if player:getGrindingXpBoost() > 0 then
		message = message .. "Grinding Boost: +50% (Active)\n"
		totalMultiplier = totalMultiplier + 0.5
		hasAnyBoost = true
	else
		message = message .. "Grinding Boost: Not Active\n"
	end
	
	-- Stamina System
	local staminaMinutes = player:getStamina()
	local isPremium = configManager.getBoolean(configKeys.FREE_PREMIUM) or player:isPremium()
	
	if configManager.getBoolean(configKeys.STAMINA_SYSTEM) then
		if staminaMinutes > 2400 and isPremium then
			message = message .. "Stamina Bonus: +50% (>40h Premium)\n"
			totalMultiplier = totalMultiplier * 1.5
			hasAnyBoost = true
		elseif staminaMinutes <= 840 then
			message = message .. "Stamina Penalty: -50% (<=14h)\n"
			totalMultiplier = totalMultiplier * 0.5
		else
			message = message .. "Stamina: Normal (100%)\n"
		end
		message = message .. "Current Stamina: " .. math.floor(staminaMinutes / 60) .. "h " .. (staminaMinutes % 60) .. "m\n"
	else
		message = message .. "Stamina System: Disabled\n"
	end
	
	-- Experience Stage
	local expStage = Game.getExperienceStage(player:getLevel())
	message = message .. "Experience Stage: " .. expStage .. "x (Level " .. player:getLevel() .. ")\n"
	totalMultiplier = totalMultiplier * expStage
	
	-- Total Multiplier
	message = message .. "\n=== TOTAL MULTIPLIER ===\n"
	message = message .. "Total XP Multiplier: " .. string.format("%.2f", totalMultiplier) .. "x\n"
	message = message .. "(" .. string.format("%.0f", (totalMultiplier - 1) * 100) .. "% bonus)\n"
	
	-- Example calculation
	message = message .. "\n=== EXAMPLE ===\n"
	message = message .. "Demon (6000 base XP):\n"
	message = message .. "You would gain: " .. math.floor(6000 * totalMultiplier) .. " XP\n"
	
	if not hasAnyBoost then
		message = message .. "\nNo active XP boosts!"
	end
	
	player:showTextDialog(2160, message)
	return false
end