

local soulCondition = Condition(CONDITION_SOUL, CONDITIONID_DEFAULT)
soulCondition:setTicks(4 * 60 * 1000)
soulCondition:setParameter(CONDITION_PARAM_SOULGAIN, 1)

local function useStamina(player)
	local staminaMinutes = player:getStamina()
	if staminaMinutes == 0 then
		return
	end

	local playerId = player:getId()
	if not nextUseStaminaTime[playerId] then
		nextUseStaminaTime[playerId] = 0
	end

	local currentTime = os.time()
	local timePassed = currentTime - nextUseStaminaTime[playerId]
	if timePassed <= 0 then
		return
	end

	if timePassed > 60 then
		if staminaMinutes > 2 then
			staminaMinutes = staminaMinutes - 2
		else
			staminaMinutes = 0
		end
		nextUseStaminaTime[playerId] = currentTime + 120
	else
		staminaMinutes = staminaMinutes - 1
		nextUseStaminaTime[playerId] = currentTime + 60
	end
	player:setStamina(staminaMinutes)
end

local function useStaminaXp(player)
	local staminaMinutes = player:getExpBoostStamina() / 60
	if staminaMinutes == 0 then
		return
	end

	local playerId = player:getId()
	local currentTime = os.stime()
	
	if not nextUseXpStamina[playerId] then
		nextUseXpStamina[playerId] = currentTime
		return
	end
	
	local timePassed = currentTime - nextUseXpStamina[playerId]
	if timePassed <= 0 then
		return
	end

	if timePassed > 60 then
		if staminaMinutes > 2 then
			staminaMinutes = staminaMinutes - 2
		else
			staminaMinutes = 0
		end
		nextUseXpStamina[playerId] = currentTime + 120
	else
		staminaMinutes = staminaMinutes - 1
		nextUseXpStamina[playerId] = currentTime + 60
	end
	player:setExpBoostStamina(staminaMinutes * 60)
end

local function sharedExpParty(player, exp)
	local party = player:getParty()
	if not party then
		return exp
	end

	if not party:isSharedExperienceActive() then
		return exp
	end

	if not party:isSharedExperienceEnabled() then
		return exp
	end

	local config = {
		{amount = 2, multiplier = 1.3},
		{amount = 3, multiplier = 1.6},
		{amount = 4, multiplier = 2}
	}

	local sharedExperienceMultiplier = 1.2 -- 20% if the same vocation
	local vocationsIds = {}
	local vocationId = party:getLeader():getVocation():getBase():getId()
	if vocationId ~= VOCATION_NONE then
		table.insert(vocationsIds, vocationId)
	end
	for _, member in ipairs(party:getMembers()) do
		vocationId = member:getVocation():getBase():getId()
		if not table.contains(vocationsIds, vocationId) and vocationId ~= VOCATION_NONE then
			table.insert(vocationsIds, vocationId)
		end
	end	
	local size = #vocationsIds
	for _, info in pairs(config) do
		if size == info.amount then
			sharedExperienceMultiplier = info.multiplier
		end
	end	

	local finalExp = (exp * sharedExperienceMultiplier) / (#party:getMembers() + 1)
	return finalExp
end

local event = Event()
event.onGainExperience = function(self, source, exp, rawExp, sendText)
	if not source or source:isPlayer() then
		if self:getClient().version <= 1100 then
			self:addExpTicks(exp)
		end
		return exp
	end
	
	-- Boost Creature
	local extraXp = 0
	local initialExp = exp
	for _, boosted in ipairs(boostCreature) do
		if source:getName():lower() == boosted.name then
			local extraPercent = boosted.exp
			extraXp = exp * extraPercent / 100
			self:sendTextMessage(MESSAGE_STATUS_DEFAULT, string.format("[Boosted Creature] You gained %d extra experience from a %s.", extraXp, boosted.category))
			break
		end
	end
	exp = exp + extraXp
	
	-- Guild Level System
	if self:getGuild() then
		local rewards = getReward(self:getId()) or {}
		for i = 1, #rewards do
			if rewards[i].type == GUILD_LEVEL_BONUS_EXP then
				exp = exp + (exp * rewards[i].quantity)
				break
			end
		end
	end
	
	-- Soul Regeneration
	local vocation = self:getVocation()
	if self:getSoul() < vocation:getMaxSoul() and exp >= self:getLevel() then
		soulCondition:setParameter(CONDITION_PARAM_SOULTICKS, vocation:getSoulGainTicks() * 1000)
		self:addCondition(soulCondition)
	end
	
	-- Experience Stage Multiplier
	exp = Game.getExperienceStage(self:getLevel()) * exp
	exp = sharedExpParty(self, exp)
	
	-- Store Bonus and Multipliers
	self:updateExpState()
	useStaminaXp(self)
	local grindingBoost = (self:getGrindingXpBoost() > 0) and (exp * 0.5) or 0
	local xpBoost = (self:getStoreXpBoost() > 0) and (exp * 0.5) or 0
	
	-- Stamina System
	local staminaMultiplier = 1
	local isPremium = configManager.getBoolean(configKeys.FREE_PREMIUM) or self:isPremium()
	local staminaMinutes = self:getStamina()
	
	if configManager.getBoolean(configKeys.STAMINA_SYSTEM) then
		useStamina(self)
		if staminaMinutes > 2400 and isPremium then
			staminaMultiplier = 1.5
		elseif staminaMinutes <= 840 then
			staminaMultiplier = 0.5
		end
	end
	
	-- VIP Bonus
	local multiplier = (self:getVipDays() > os.stime()) and 1.10 or 1
	
	-- VIP Message
	if self:getVipDays() > os.stime() then
		self:sendTextMessage(MESSAGE_STATUS_DEFAULT, "[VIP] +10% experience bonus active!")
	end
	
	-- Store XP Boost Message
	if self:getStoreXpBoost() > 0 then
		self:sendTextMessage(MESSAGE_STATUS_DEFAULT, "[Store Boost] +50% experience bonus active!")
	end
	
	-- Final Calculation
	exp = multiplier * exp
	exp = exp + grindingBoost
	exp = exp + xpBoost
	exp = exp * staminaMultiplier
	
	if self:getClient().version <= 1100 then
		self:addExpTicks(exp)
	end
	
	return exp
end
event:register()