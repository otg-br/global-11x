function Player.allowMovement(self, allow)
	return self:setStorageValue(STORAGE.blockMovementStorage, allow and -1 or 1)
end

function Player.checkGnomeRank(self)
	local points = self:getStorageValue(Storage.BigfootBurden.Rank)
	local questProgress = self:getStorageValue(Storage.BigfootBurden.QuestLine)
	if points >= 30 and points < 120 then
		if questProgress <= 25 then
			self:setStorageValue(Storage.BigfootBurden.QuestLine, 26)
			self:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
			self:addAchievement('Gnome Little Helper')
		end
	elseif points >= 120 and points < 480 then
		if questProgress <= 26 then
			self:setStorageValue(Storage.BigfootBurden.QuestLine, 27)
			self:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
			self:addAchievement('Gnome Little Helper')
			self:addAchievement('Gnome Friend')
		end
	elseif points >= 480 and points < 1440 then
		if questProgress <= 27 then
			self:setStorageValue(Storage.BigfootBurden.QuestLine, 28)
			self:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
			self:addAchievement('Gnome Little Helper')
			self:addAchievement('Gnome Friend')
			self:addAchievement('Gnomelike')
		end
	elseif points >= 1440 then
		if questProgress <= 29 then
			self:setStorageValue(Storage.BigfootBurden.QuestLine, 30)
			self:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
			self:addAchievement('Gnome Little Helper')
			self:addAchievement('Gnome Friend')
			self:addAchievement('Gnomelike')
			self:addAchievement('Honorary Gnome')
		end
	end
	return true
end

function Player.setExhaustion(self, value, time)
    return self:setStorageValue(value, time + os.stime())
end

function Player.getExhaustion(self, value)
    local storage = self:getStorageValue(value)
    if storage <= 0 then
        return 0
    end
    return storage - os.stime()
end

function Player.addFamePoint(self)
    local points = self:getStorageValue(SPIKE_FAME_POINTS)
    local current = math.max(0, points)
    self:setStorageValue(SPIKE_FAME_POINTS, current + 1)
    self:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "You have received a fame point.")
end

function Player.getFamePoints(self)
    local points = self:getStorageValue(SPIKE_FAME_POINTS)
    return math.max(0, points)
end

function Player.removeFamePoints(self, amount)
    local points = self:getStorageValue(SPIKE_FAME_POINTS)
    local current = math.max(0, points)
    self:setStorageValue(SPIKE_FAME_POINTS, current - amount)
end

function Player.depositMoney(self, amount)
	if not self:removeMoney(amount) then
		return false
	end

	self:setBankBalance(self:getBankBalance() + amount)
	return true
end

local foodCondition = Condition(CONDITION_REGENERATION, CONDITIONID_DEFAULT)

function Player.feed(self, food)
	local condition = self:getCondition(CONDITION_REGENERATION, CONDITIONID_DEFAULT)
	if condition then
		condition:setTicks(condition:getTicks() + (food * 1000))
	else
		local vocation = self:getVocation()
		if not vocation then
			return nil
		end

		local managain = vocation:getManaGainAmount()
		local healthgain = vocation:getHealthGainAmount()

		-- begin guild level system	
		local g = self:getGuild()
		local hasManaBuff = false
		local hasHealthBuff = false
		if g then
			local rewards = {}
			rewards = getReward(self:getId())
			for i = 1, #rewards do
				if rewards[i].type == GUILD_LEVEL_BONUS_MANA then
					hasManaBuff = rewards[i].quantity
				end
				if rewards[i].type == GUILD_LEVEL_BONUS_HEALTH then
					hasHealthBuff = rewards[i].quantity
				end
			end
			if hasManaBuff then
				managain = managain + (managain*hasManaBuff)
			end
			if hasHealthBuff then
				healthgain = healthgain + (managain*hasHealthBuff)
			end
		end		
		foodCondition:setTicks(food * 1000)
		foodCondition:setParameter(CONDITION_PARAM_HEALTHGAIN, healthgain)
		foodCondition:setParameter(CONDITION_PARAM_HEALTHTICKS, vocation:getHealthGainTicks() * 1000)
		foodCondition:setParameter(CONDITION_PARAM_MANAGAIN, managain)
		foodCondition:setParameter(CONDITION_PARAM_MANATICKS, vocation:getManaGainTicks() * 1000)

		self:addCondition(foodCondition)
	end
	return true
end

function Player.getBlessings(self)
	local blessings = 0
	for i = WISDOM_OF_SOLITUDE, EMBRACE_OF_TIBIA do
		if self:hasBlessing(i) then
			blessings = blessings + 1
		end
	end
	return blessings
end

function Player.getClosestFreePosition(self, position, extended)
	if self:getAccountType() >= ACCOUNT_TYPE_GOD then
		return position
	end
	return Creature.getClosestFreePosition(self, position, extended)
end

function Player.getCookiesDelivered(self)
	local storage, amount = {
		STORAGE.WHATAFOOLISHQUEST.COOKIEDELIVERY.SIMONTHEBEGGAR, STORAGE.WHATAFOOLISHQUEST.COOKIEDELIVERY.MARKWIN, STORAGE.WHATAFOOLISHQUEST.COOKIEDELIVERY.ARIELLA,
		STORAGE.WHATAFOOLISHQUEST.COOKIEDELIVERY.HAIRYCLES, STORAGE.WHATAFOOLISHQUEST.COOKIEDELIVERY.DJINN, STORAGE.WHATAFOOLISHQUEST.COOKIEDELIVERY.AVARTAR,
		STORAGE.WHATAFOOLISHQUEST.COOKIEDELIVERY.ORCKING, STORAGE.WHATAFOOLISHQUEST.COOKIEDELIVERY.LORBAS, STORAGE.WHATAFOOLISHQUEST.COOKIEDELIVERY.WYDA,
		STORAGE.WHATAFOOLISHQUEST.COOKIEDELIVERY.HJAERN
	}, 0
	for i = 1, #storage do
		if self:getStorageValue(storage[i]) == 1 then
			amount = amount + 1
		end
	end
	return amount
end

function Player.getDepotItems(self, depotId)
	return self:getDepotChest(depotId, true):getItemHoldingCount()
end

function Player.getLossPercent(self)
	local lossPercent = {
		[0] = 100,
		[1] = 70,
		[2] = 45,
		[3] = 25,
		[4] = 10,
		[5] = 0
	}

	return lossPercent[self:getBlessings()]
end

function Player.getPremiumTime(self)
	return math.max(0, self:getPremiumEndsAt() - os.time())
end

function Player.setPremiumTime(self, seconds)
	self:setPremiumEndsAt(os.time() + seconds)
	return true
end

function Player.addPremiumTime(self, seconds)
	self:setPremiumTime(self:getPremiumTime() + seconds)
	return true
end

function Player.removePremiumTime(self, seconds)
	local currentTime = self:getPremiumTime()
	if currentTime < seconds then
		return false
	end

	self:setPremiumTime(currentTime - seconds)
	return true
end

function Player.getPremiumDays(self)
	return math.floor(self:getPremiumTime() / 86400)
end

function Player.addPremiumDays(self, days)
	return self:addPremiumTime(days * 86400)
end

function Player.removePremiumDays(self, days)
	return self:removePremiumTime(days * 86400)
end

function Player.hasAllowMovement(self)
	return self:getStorageValue(STORAGE.blockMovementStorage) ~= 1
end

function Player.hasRookgaardShield(self)
	-- Wooden Shield, Studded Shield, Brass Shield, Plate Shield, Copper Shield
	return self:getItemCount(2512) > 0
			or self:getItemCount(2526) > 0
			or self:getItemCount(2511) > 0
			or self:getItemCount(2510) > 0
			or self:getItemCount(2530) > 0
end

function Player.isDruid(self)
	return isInArray({2, 6}, self:getVocation():getId())
end

function Player.isKnight(self)
	return isInArray({4, 8}, self:getVocation():getId())
end

function Player.isPaladin(self)
	return isInArray({3, 7}, self:getVocation():getId())
end

function Player.isMage(self)
	return isInArray({1, 2, 5, 6}, self:getVocation():getId())
end

function Player.isSorcerer(self)
	return isInArray({1, 5}, self:getVocation():getId())
end

function Player.isPremium(self)
	return self:getPremiumTime() > 0 or configManager.getBoolean(configKeys.FREE_PREMIUM)
end

function Player.isPromoted(self)
	local vocation = self:getVocation()
	local promotedVocation = vocation:getPromotion()
	promotedVocation = promotedVocation and promotedVocation:getId() or 0

	return promotedVocation == 0 and vocation:getId() ~= promotedVocation
end

function Player.isUsingOtClient(self)
	return self:getClient().os >= CLIENTOS_OTCLIENT_LINUX
end

function Player.sendCancelMessage(self, message)
	if type(message) == "number" then
		message = Game.getReturnMessage(message)
	end
	return self:sendTextMessage(MESSAGE_STATUS_SMALL, message)
end

function Player.sendExtendedOpcode(self, opcode, buffer)
	if not self:isUsingOtClient() then
		return false
	end

	local networkMessage = NetworkMessage()
 	networkMessage:addByte(0x32)
 	networkMessage:addByte(opcode)
 	networkMessage:addString(buffer)
	networkMessage:sendToPlayer(self, false)
 	networkMessage:delete()
	return true
end

function Player.transferMoneyTo(self, target, amount)
	local balance = self:getBankBalance()
	if amount > balance then
		return false
	end

	local targetPlayer = Player(target)
	if targetPlayer then
		targetPlayer:setBankBalance(targetPlayer:getBankBalance() + amount)
	else
		if not playerExists(target) then
			return false
		end
		db.query("UPDATE `players` SET `balance` = `balance` + '" .. amount .. "' WHERE `name` = " .. db.escapeString(target))
	end

	self:setBankBalance(self:getBankBalance() - amount)
	return true
end

function Player.withdrawMoney(self, amount)
	local balance = self:getBankBalance()
	if amount > balance or not self:addMoney(amount) then
		return false
	end

	self:setBankBalance(balance - amount)
	return true
end

APPLY_SKILL_MULTIPLIER = true
local addSkillTriesFunc = Player.addSkillTries
function Player.addSkillTries(...)
	APPLY_SKILL_MULTIPLIER = false
	local ret = addSkillTriesFunc(...)
	APPLY_SKILL_MULTIPLIER = true
	return ret
end

local addManaSpentFunc = Player.addManaSpent
function Player.addManaSpent(...)
	APPLY_SKILL_MULTIPLIER = false
	local ret = addManaSpentFunc(...)
	APPLY_SKILL_MULTIPLIER = true
	return ret
end

--jlcvp - impact analyser
function Player.sendHealingImpact(self, healAmmount)
	if self:getClient().version <= 1100 then
		self:addHealTicks(healAmmount)
		return
	end

	local msg = NetworkMessage()
	msg:addByte(0xCC) -- DEC: 204
	msg:addByte(0) -- 0 = healing / 1 = damage (boolean)
	msg:addU32(healAmmount) -- unsigned int
	msg:sendToPlayer(self)

	if self:getParty() then
		self:getParty():broadcastUpdateInfo(type, playerid)
	end

end

function Player.sendDamageImpact(self, damage)
	if self:getClient().version <= 1100 then
		self:addDamageTicks(damage)
		return
	end

	local msg = NetworkMessage()
	msg:addByte(0xCC) -- DEC: 204
	msg:addByte(1) -- 0 = healing / 1 = damage (boolean)
	msg:addU32(damage) -- unsigned int
	msg:sendToPlayer(self)
end

 -- Loot Analyser
function Player.sendLootStats(self, item)
	if self:getClient().version <= 1100 then
		self:addLootTicks(item:getId(), item:getCount())
		return
	end

	local msg = NetworkMessage()
	msg:addByte(0xCF) -- loot analyser bit
	msg:addItem(item, self) -- item userdata
	msg:addString(getItemName(item:getId()))
	msg:sendToPlayer(self)

	self:partyTracker(2, item:getCount() * ItemType(item:getId()):getBuyValue() )
end

-- Supply Analyser
function Player.sendWaste(self, item)
	if self:getClient().version <= 1100 then
		self:addWastTicks(item)
		return
	end

    local msg = NetworkMessage()
    msg:addByte(0xCE) -- waste bit
    msg:addItemId(item) -- itemId
    msg:sendToPlayer(self)
    msg:delete()

    self:partyTracker(3, ItemType(item):getBuyValue() )

end

function Player.sendUnlockMonster(self, monsterid)
	if self:getClient().version < 1180 then
		return
	end

    local msg = NetworkMessage()
	msg:addByte(0xD9)
	msg:addU16(monsterid)
    msg:sendToPlayer(self)
end
function Player.sendUnlockMonsterInfor(self, monsterid, diff)
	if self:getClient().version < 1180 then
		return
	end

    local msg = NetworkMessage()
	msg:addByte(0xDD)
	msg:addByte(0x08)
	msg:addU16(monsterid)
	msg:addByte(diff)
    msg:sendToPlayer(self)
end

TYPE_HEALING = 1
TYPE_DAMAGE = 2
function sendImpactToClient(self, impactType)
	local player = Player(self)
	if player ~= nil then
		if impactType == TYPE_HEALING then
			if healingImpact[player:getId()][1] ~= 0 then
				player:sendHealingImpact(healingImpact[player:getId()][1])
				player:partyTracker(1, healingImpact[player:getId()][1])
				healingImpact[self] = nil
			end
		else
			if damageImpact[player:getId()][1] ~= 0 then
				player:sendDamageImpact(damageImpact[player:getId()][1])
				player:partyTracker(0, damageImpact[player:getId()][1])
				damageImpact[player:getId()] = nil
			end
		end
	end
end

function Player.sendKillTracker(self, monster, container)
	if self:getClient().version <= 1100 then
		return
	end

	local isCorpseEmpty = container:getEmptySlots() == container:getSize()
	local msg = NetworkMessage()
	local outfit = monster:getOutfit()
	msg:addByte(0xD1)
	msg:addString(monster:getName())
	msg:addU16(outfit.lookType ~= 0 and outfit.lookType or 21)
	msg:addByte(outfit.lookType ~= 0 and outfit.lookHead or 0x00)
	msg:addByte(outfit.lookType ~= 0 and outfit.lookBody or 0x00)
	msg:addByte(outfit.lookType ~= 0 and outfit.lookLegs or 0x00)
	msg:addByte(outfit.lookType ~= 0 and outfit.lookFeet or 0x00)
	msg:addByte(outfit.lookType ~= 0 and outfit.lookAddons or 0x00)
	msg:addByte(isCorpseEmpty and 0 or container:getSize())
	if (not isCorpseEmpty) then
		for i = container:getSize() - 1, 0, -1 do
            local containerItem = container:getItem(i)
            if containerItem then
				msg:addItem(containerItem , self)
			end
		end
	end
	msg:sendToPlayer(self)
end

function Player:updateMemberPartyInfo(type, playerid)
	if self:getClient().version < 1230 then
		return
	end
	local player = Player(playerid)
	if player then return end

	local msg = NetworkMessage()
	msg:addByte(0x8B)
	msg:addByte(playerid)
	msg:addByte(type)
	if type == CONST_PARTY_BASICINFO then
		msg:addCreature(player, self)
	elseif type == CONST_PARTY_UNKNOW then
		msg:addByte(0x1)
	elseif type == CONST_PARTY_MANA then
		msg:addByte(math.ceil((player:getMana() / math.max(player:getMaxMana(), 1)) * 100))
	else
		msg:delete()
		return
	end
	msg:sendToPlayer(self)
	msg:delete()
end

function Player.partyTracker(self, type, value)
	local party = self:getParty()
	if not party then return true end

	local needupdate = false
	if not partyHuntTracker[party:getId()] then
		partyHuntTracker[party:getId()] = {}
		needupdate = true
	end
	if not partyHuntTracker[party:getId()][self:getId()] then
		partyHuntTracker[party:getId()][self:getId()] = {damage = 0, loot = 0, healing = 0, waste = 0}
		needupdate = true
	end

	if type == 0 then
		partyHuntTracker[party:getId()][self:getId()].damage = partyHuntTracker[party:getId()][self:getId()].damage + value
	elseif type == 1 then
		partyHuntTracker[party:getId()][self:getId()].healing = partyHuntTracker[party:getId()][self:getId()].healing + value
	elseif type == 2 then
		partyHuntTracker[party:getId()][self:getId()].loot = partyHuntTracker[party:getId()][self:getId()].loot + value
	elseif type == 3 then
		partyHuntTracker[party:getId()][self:getId()].waste = partyHuntTracker[party:getId()][self:getId()].waste + value
	end

	party:broadcastInfo(needupdate)
end

function Player.updateParty(self, update)
	if true then
		return true
	end
	local party = self:getParty()
	if not party then return true end
	if self:getClient().version < 1230 then
		return
	end
	local leader = party:getLeader()

	local msg = NetworkMessage()
	msg:addByte(0x2b)
	msg:addU32(party:getStartTime())
	msg:addU32(leader:getId())
	msg:addByte(0x01)

	local info = party:getInfo()
	msg:addByte(table.realcount(info))
	if table.realcount(info) > 0 then
		for playerid, pid in pairs(info) do
			msg:addU32(playerid)
			local p, inpt = Player(playerid), 1
			if not p or not p:getParty() then
				inpt = 0
			end
			if p and p:getParty() and p:getParty():getId() ~= party:getId() then
				inpt = 0
			end
			msg:addByte(inpt) -- in party
			msg:addU64(pid.loot)
			msg:addU64(pid.waste)
			msg:addU64(pid.damage)
			msg:addU64(pid.healing)
		end
	end

	msg:addByte(update and 1 or 0)
	if update then
		msg:addByte(table.realcount(info))
		if table.realcount(info) > 0 then
			for playerid, pid in pairs(info) do
				msg:addU32(playerid)
				local p, name = Player(playerid), "Unknow"
				if p then name = p:getName() end
				msg:addString(name)
			end
		end
	end
	msg:sendToPlayer(self)
	msg:delete()
end

function Player:onManageLocker(item, tobackpack)
	if self:getClient().version < 1200 then
		return
	end

	local msg = NetworkMessage()
	msg:addByte(0x72)
	msg:addByte(tobackpack and 0x01 or 0x00)
	msg:addU16(0x00)
	msg:addU16(0x00)
	msg:addByte(0x70)
	msg:addByte(tobackpack and 0x0 or 0x01)
	msg:addU16(0x00)
	msg:addItem(item, self)
	msg:sendToPlayer(self)
end

function Player.updateExpState(self)
	local useGrinding = true
	local isPremium = configManager.getBoolean(configKeys.FREE_PREMIUM) and true or self:isPremium()
	if Game.getStorageValue(GlobalStorage.XpDisplayMode) > 0 then
		-- displayRate = 1
		displayRate = Game.getExperienceStage(self:getLevel())
	else
		displayRate = 1
	end
	-- display stamina
	local staminaMinutes = self:getStamina()
	if staminaMinutes > 2400 and isPremium then
		self:setStaminaXpBoost(150)
	elseif staminaMinutes <= 2400 and staminaMinutes > 840 or (staminaMinutes > 2400 and not isPremium) then
		self:setStaminaXpBoost(100)
	else
		self:setStaminaXpBoost(50)
	end

	local storeBoost = self:getExpBoostStamina()

	self:setStoreXpBoost( (storeBoost > 0 and (50*displayRate) or 0) )

	if (storeBoost <= 0 and self:getStoreXpBoost() > 0) then
		self:setStoreXpBoost(0) -- Reset Store boost to 0 if boost stamina has ran out
	end

	if self:getLevel() < 50 and useGrinding then
		self:setGrindingXpBoost(150)
	else
		self:setGrindingXpBoost(0)
	end

	self:setBaseXpGain(displayRate*100)
	return true
end
