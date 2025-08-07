function Player:onBrowseField(position)
 if hasEvent.onBrowseField then
		return Event.onBrowseField(self, position)
    end
	return true
end

function Player:onLook(thing, position, distance)
 local description = ""
	if hasEvent.onLook then
		description = Event.onLook(self, thing, position, distance, description)
	end
	self:sendTextMessage(MESSAGE_INFO_DESCR, description)
end

function Player:onLookInBattleList(creature, distance)
  if hasEvent.onLookInBattleList then
		description = Event.onLookInBattleList(self, creature, distance, description)
	end
	self:sendTextMessage(MESSAGE_INFO_DESCR, description)
end

function Player:onLookInTrade(partner, item, distance)
    local description = "You see " .. item:getDescription(distance)
if hasEvent.onLookInTrade then
		description = Event.onLookInTrade(self, partner, item, distance, description)
	end
	self:sendTextMessage(MESSAGE_INFO_DESCR, description)
end

function Player:onLookInShop(itemType, count, description)
    local description = "You see " .. description
if hasEvent.onLookInShop then
		description = Event.onLookInShop(self, itemType, count, description)
	end
	self:sendTextMessage(MESSAGE_INFO_DESCR, description)
end

function Player:onMoveItem(item, count, fromPosition, toPosition, fromCylinder, toCylinder)
    if hasEvent.onMoveItem then
        return Event.onMoveItem(self, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
    end
    return true
end

function Player:onStepTile(fromPosition, toPosition)
    if hasEvent.onStepTile then
        return Event.onStepTile(self, fromPosition, toPosition)
    end
    return true
end

function Player:onReportRuleViolation(targetName, reportType, reportReason, comment, translation)
 if hasEvent.onReportRuleViolation then
		Event.onReportRuleViolation(self, targetName, reportType, reportReason, comment, translation)
    end
    return true
end

function Player:onReportBug(message, position, category)
 if hasEvent.onReportBug then
		return Event.onReportBug(self, message, position, category)
    end
    return true
end

function Player:onTurn(direction)
   if hasEvent.onTurn then
		return Event.onTurn(self, direction)
    end
    
    if self:getGroup():getId() >= 5 and self:getDirection() == direction then
        local nextPosition = self:getPosition()
        nextPosition:getNextPosition(direction)
        self:teleportTo(nextPosition, true)
    end

    return true
end

function Player:onTradeRequest(target, item)
  if hasEvent.onTradeRequest then
		return Event.onTradeRequest(self, target, item)
    end
    
    self:closeImbuementWindow(target)
    if isInArray(exercise_ids, item.itemid) then
        return false
    end

    return true
end

function Player:onTradeAccept(target, item, targetItem)
 if hasEvent.onTradeAccept then
		return Event.onTradeAccept(self, target, item, targetItem)
    end
    
    self:closeImbuementWindow(target)
    return true
end

function Player:onTradeCompleted(target, item, targetItem, isSuccess)
	if hasEvent.onTradeCompleted then
		Event.onTradeCompleted(self, target, item, targetItem, isSuccess)
    end
end

function Player:onGainExperience(source, exp, rawExp, sendText)
	return hasEvent.onGainExperience and Event.onGainExperience(self, source, exp, rawExp, sendText) or exp
end

function Player:onLoseExperience(exp)
    local onLoseExperience = EventCallback.onLoseExperience
	return hasEvent.onLoseExperience and Event.onLoseExperience(self, exp) or exp
end

function Player:onGainSkillTries(skill, tries)
    if APPLY_SKILL_MULTIPLIER == false then
     return hasEvent.onGainSkillTries and Event.onGainSkillTries(self, skill, tries) or tries
    end

    if skill == SKILL_MAGLEVEL then
        tries = tries * configManager.getNumber(configKeys.RATE_MAGIC)
    return hasEvent.onGainSkillTries and Event.onGainSkillTries(self, skill, tries) or tries
    end
    tries = tries * configManager.getNumber(configKeys.RATE_SKILL)
 return hasEvent.onGainSkillTries and Event.onGainSkillTries(self, skill, tries) or tries
end

function Player:onRemoveCount(item)
	self:sendWaste(item:getId())
end

function Player:onRequestQuestLog()
	self:sendQuestLog()
end

function Player:onRequestQuestLine(questId)
	self:sendQuestLine(questId)
end

function Player:onStorageUpdate(key, value, oldValue, currentFrameTime)
	self:updateStorage(key, value, oldValue, currentFrameTime)
end

function Player:canBeAppliedImbuement(imbuement, item)
	if hasEvent.canBeAppliedImbuement and not Event.canBeAppliedImbuement(self, imbuement, item) then
		return false
	end
	return true
end

function Player:onApplyImbuement(imbuement, item, slot, protectionCharm)
	if hasEvent.onApplyImbuement and not Event.onApplyImbuement(self, imbuement, item, slot, protectionCharm) then
		return false
	end
	return true
end

function Player:clearImbuement(item, slot)
	if hasEvent.clearImbuement and not Event.clearImbuement(self, item, slot) then
		return false
	end
	return true
end

function Player:onCombat(target, item, primaryDamage, primaryType, secondaryDamage, secondaryType)
	if hasEvent.onCombat then
		return Event.onCombat(self, target, item, primaryDamage, primaryType, secondaryDamage, secondaryType)
	end
end

