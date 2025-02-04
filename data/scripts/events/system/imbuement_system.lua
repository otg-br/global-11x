local STORAGE_CAPACITY_IMBUEMENT = 42154

local eventCanBeAppliedImbuement = Event()

eventCanBeAppliedImbuement.canBeAppliedImbuement = function(self, imbuement, item)
	local categories = {}
	local slots = ItemType(item:getId()):getImbuingSlots()
	if slots > 0 then
		for slot = 0, slots - 1 do
			local duration = item:getImbuementDuration(slot)
			if duration > 0 then
				local imbue = item:getImbuement(slot)
				local catid = imbue:getCategory().id
				table.insert(categories, catid)
			end
		end
	end

	if isInArray(categories, imbuement:getCategory().id) then
		return false
	end

	if imbuement:isPremium() and self:getPremiumDays() < 1 then
		return false
	end

	if not self:canImbueItem(imbuement, item) then
		return false
	end

	return true
end

eventCanBeAppliedImbuement:register()

local eventOnApplyImbuement = Event()

eventOnApplyImbuement.onApplyImbuement = function(self, imbuement, item, slot, protectionCharm)
	for _, pid in pairs(imbuement:getItems()) do
		if self:getItemCount(pid.itemid) < pid.count then
			self:sendImbuementResult(MESSAGEDIALOG_IMBUEMENT_ROLL_FAILED, "You don't have all necessary items.")
			return false
		end
	end

	if item:getImbuementDuration(slot) > 0 then
		self:sendImbuementResult(MESSAGEDIALOG_IMBUEMENT_ERROR, "An error occurred, please reopen imbuement window.")
		return false
	end

	local base = imbuement:getBase()
	local price = base.price + (protectionCharm and base.protection or 0)
	if not self:removeMoneyNpc(price) then
		self:sendImbuementResult(MESSAGEDIALOG_IMBUEMENT_ROLL_FAILED, "You don't have enough money " ..price.. " gps.")
		return false
	end

	local chance = protectionCharm and 100 or base.percent
	if math.random(100) > chance then
		for _, pid in pairs(imbuement:getItems()) do
			self:removeItem(pid.itemid, pid.count)
		end

		self:sendImbuementResult(MESSAGEDIALOG_IMBUEMENT_ROLL_FAILED, "Item failed to apply imbuement.")
		return false
	end

	-- Removing items
	for _, pid in pairs(imbuement:getItems()) do
		if not self:removeItem(pid.itemid, pid.count) then
			self:sendImbuementResult(MESSAGEDIALOG_IMBUEMENT_ROLL_FAILED, "You don't have all necessary items.")
			return false
		end
	end

	if not item:addImbuement(slot, imbuement:getId()) then
		self:sendImbuementResult(MESSAGEDIALOG_IMBUEMENT_ROLL_FAILED, "Item failed to apply imbuement.")
		return false
	end

	item:setAttribute(ITEM_ATTRIBUTE_IMBUED, 1)

	-- Update item
	local nitem = Item(item.uid)
	self:sendImbuementPanel(nitem)
	return true
end

eventOnApplyImbuement:register()

local eventClearImbuement = Event()

eventClearImbuement.clearImbuement = function(self, item, slot)
	local slots = ItemType(item:getId()):getImbuingSlots()
	if slots < slot then
		self:sendImbuementResult(MESSAGEDIALOG_CLEARING_CHARM_ERROR, "Sorry, not possible.")
		return false
	end

	if item:getTopParent() ~= self or item:getParent() == self then
		self:sendImbuementResult(MESSAGEDIALOG_CLEARING_CHARM_ERROR, "An error occurred while applying the clearing charm to the item.")
		return false
	end

	-- slot is not used
	local info = item:getImbuementDuration(slot)
	if info == 0 then
		self:sendImbuementResult(MESSAGEDIALOG_CLEARING_CHARM_ERROR, "An error occurred while applying the clearing charm to the item.")
		return false
	end

	local imbuement = item:getImbuement(slot)
	if not self:removeMoneyNpc(imbuement:getBase().removecust) then
		self:sendImbuementResult(MESSAGEDIALOG_CLEARING_CHARM_ERROR, "You don't have enough money " ..imbuement:getBase().removecust.. " gps.")
		return false
	end

	if not item:cleanImbuement(slot) then
		self:sendImbuementResult(MESSAGEDIALOG_CLEARING_CHARM_ERROR, "An error occurred while applying the clearing charm to the item.")
		return false
	end

	-- Update item
	local nitem = Item(item.uid)
	self:sendImbuementResult(MESSAGEDIALOG_CLEARING_CHARM_SUCCESS, "Congratulations! You have successfully applied the clearing charm to your item.")
	self:sendImbuementPanel(nitem)

	return true
end

eventClearImbuement:register()


local onCombat = Event()

onCombat.onCombat = function(player, target, item, primaryDamage, primaryType, secondaryDamage, secondaryType)
	-- Copiar a lógica original da função onCombat aqui, se necessário
	-- Exemplo:
	if target then
		local monster = Monster(target:getId())
		if monster and monster:getType() and monster:getType():raceId() > 0 then
			local atualCharm = player:getMonsterCharm(monster:getType():raceId())
			if atualCharm == 6 and math.random(1, 10000) <= 100 then
				local condition = Condition(CONDITION_PARALYZE)
				condition:setParameter(CONDITION_PARAM_TICKS, 10000)
				condition:setFormula(-0.40, -0.15, -0.55, -0.15)
				target:addCondition(condition)
				player:sendTextMessage(MESSAGE_DAMAGE_DEALT, "Active charm 'Cripple'")
			end
		end
	end

	if not item or not target then
		return primaryDamage, primaryType, secondaryDamage, secondaryType
	end

	if primaryType == COMBAT_HEALING or secondaryType == COMBAT_HEALING then
		return primaryDamage, primaryType, secondaryDamage, secondaryType
	end

	local slots = ItemType(item:getId()):getImbuingSlots()
	if slots > 0 then
		for i = 0, slots - 1 do
			local imbuement = item:getImbuement(i)
			if imbuement then
				local percent = imbuement:getElementDamage()
				if percent and percent > 0 then
					if primaryDamage ~= 0 then
						secondaryDamage = primaryDamage * math.min(percent / 100, 1)
						secondaryType = imbuement:getCombatType()
						primaryDamage = primaryDamage - secondaryDamage
					elseif secondaryDamage ~= 0 then
						primaryDamage = secondaryDamage * math.min(percent / 100, 1)
						primaryType = imbuement:getCombatType()
						secondaryDamage = secondaryDamage - primaryDamage
					end
				end
			end
		end
	end

	return primaryDamage, primaryType, secondaryDamage, secondaryType
end
onCombat:register()
