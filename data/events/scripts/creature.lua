__picif = {}
function Creature:onChangeOutfit(outfit)
	if hasEvent.onChangeMount then
		if not Event.onChangeMount(self, outfit.lookMount) then
			return false
		end
	end
	if hasEvent.onChangeOutfit then
		return Event.onChangeOutfit(self, outfit)
	else
		return true
	end
end

function Creature:onAreaCombat(tile, isAggressive)
	if hasEvent.onAreaCombat then
		return Event.onAreaCombat(self, tile, isAggressive)
	else
		return RETURNVALUE_NOERROR
	end
end

local damageElementalCharm = {
	[0] = COMBAT_PHYSICALDAMAGE,
	[1] = COMBAT_FIREDAMAGE,
	[2] = COMBAT_EARTHDAMAGE,
	[3] = COMBAT_ICEDAMAGE,
	[4] = COMBAT_ENERGYDAMAGE,
	[5] = COMBAT_DEATHDAMAGE,
}

local function isFirstHit(creatureId, playerId)
	local monster = Monster(creatureId)
	if not monster then return false end
	local player = Player(playerId)
	if not player then return false end

	for attackerid, info in pairs(monster:getDamageMap()) do
		if attackerid == playerId then
			return false
		end
	end

	return true
end

-- Increase Stamina when Attacking Trainer
local staminaBonus = {
	target = 'Training Monk',
	period = 120000, -- time on miliseconds
	bonus = 1, -- gain stamina
	events = {}
}

local function addStamina(name)
	local player = Player(name)
	if not player then
		staminaBonus.events[name] = nil
	else
		local target = player:getTarget()
		if not target or target:getName() ~= staminaBonus.target then
			staminaBonus.events[name] = nil
		else
			player:setStamina(player:getStamina() + staminaBonus.bonus)
			staminaBonus.events[name] = addEvent(addStamina, staminaBonus.period, name)
		end
	end
end

function Creature:onTargetCombat(target)
  if hasEvent.onTargetCombat then
		return Event.onTargetCombat(self, target)
    end

    if target and target:isDead() then
        if self and self:isMonster() then
            self:setTarget(nil)
            self:setFollowCreature(nil)
            self:searchTarget()
        end
        return RETURNVALUE_YOUMAYNOTATTACKTHISPLAYER
    end

    if not self then
        return true
    end

    if self:isMonster() and self:getType():isPet() and target:isPlayer() and Game.getWorldType() ~= WORLD_TYPE_RETRO_OPEN_PVP then
        return RETURNVALUE_YOUMAYNOTATTACKTHISCREATURE
    end

    if not __picif[target.uid] then
        if target:isMonster() then
            target:registerEvent("RewardSystemSlogan")
            __picif[target.uid] = {}
        end
    end

    if target:isPlayer() then
        if self:isMonster() then
            local protectionStorage = target:getStorageValue(Storage.combatProtectionStorage)
            if protectionStorage >= os.stime() then
                return RETURNVALUE_YOUMAYNOTATTACKTHISPLAYER
            end
        end
    end

    if (target:isMonster() and self:isPlayer() and target:getType():isPet() and target:getMaster() == self) or 
       (self:isMonster() and target:isPlayer() and self:getType():isPet() and self:getMaster() == target) then
        return RETURNVALUE_YOUMAYNOTATTACKTHISCREATURE
    end

    if PARTY_PROTECTION ~= 0 and Game.getWorldType() ~= WORLD_TYPE_RETRO_OPEN_PVP then
        if self:isPlayer() and target:isPlayer() then
            local party = self:getParty()
            if party then
                local targetParty = target:getParty()
                if targetParty and targetParty == party then
                    return RETURNVALUE_YOUMAYNOTATTACKTHISPLAYER
                end
            end
        end
    end

    local party, selfPlayer
    if self then
        if self:isPlayer() then
            party = self:getParty()
            selfPlayer = self:getPlayer()
        elseif self:isMonster() and self:getMaster() and self:getMaster():isPlayer() then
            party = self:getMaster():getParty()
            selfPlayer = self:getMaster():getPlayer()
        end
    end

    local targetParty, targetPlayer
    if target then
        if target:isPlayer() then
            targetParty = target:getParty()
            targetPlayer = target:getPlayer()
        elseif target:isMonster() and target:getMaster() and target:getMaster():isPlayer() then
            targetParty = target:getMaster():getParty()
            targetPlayer = target:getMaster():getPlayer()
        end
    end

    if party and targetParty and targetParty == party and Game.getWorldType() ~= WORLD_TYPE_RETRO_OPEN_PVP then
        if selfPlayer:hasSecureMode() or targetPlayer:hasSecureMode() then
            return RETURNVALUE_YOUMAYNOTATTACKTHISPLAYER
        end
    end

    if ADVANCED_SECURE_MODE ~= 0 then
        if self:isPlayer() and target:isPlayer() then
            if self:hasSecureMode() then
                -- return RETURNVALUE_YOUMAYNOTATTACKTHISPLAYER
            end
        end
    end

    if self:isPlayer() then
        if target and target:getName() == staminaBonus.target then
            local name = self:getName()
            if not staminaBonus.events[name] then
                staminaBonus.events[name] = addEvent(addStamina, staminaBonus.period, name)
            end
        end
    end

    if target and target:isMonster() and self:isPlayer() then
        if target:getType() and target:getType():raceId() > 0 then
            local atualCharm = self:getMonsterCharm(target:getType():raceId())
            if atualCharm > -1 and damageElementalCharm[atualCharm] and isFirstHit(target:getId(), self:getId()) then
                addEvent(function(playerid, targetid)
                    local t = Monster(targetid)
                    if not t then return true end
                    doTargetCombatHealth(playerid, t, damageElementalCharm[atualCharm], -(t:getHealth() * 0.05) / 2, -(t:getMaxHealth() * 0.05) / 2, CONST_ME_POFF, ORIGIN_CHARM)
                end, 200, self:getId(), target:getId())
            end

            if not self:inEffectLowBlow() then
                if self:getCurrentCreature(15) == target:getType():raceId() then
                    self:setEffectLowBlow(true)
                end
            elseif self:getCurrentCreature(15) ~= target:getType():raceId() then
                self:setEffectLowBlow(false)
            end
        end
    end

    return RETURNVALUE_NOERROR
end

function Creature:onDrainHealth(attacker, typePrimary, damagePrimary, typeSecondary, damageSecondary, colorPrimary, colorSecondary)
	if not self then
		return typePrimary, damagePrimary, typeSecondary, damageSecondary, colorPrimary, colorSecondary
	end

	local secondsToGetHealing, currentTime = 2, os.stime()
	if attacker and attacker:isPlayer() then
		if typePrimary ~= COMBAT_HEALING then
			local k = attacker:getId()
			if damageImpact[k] == nil then
				damageImpact[k] = damageImpact[k] or {0, currentTime }
			end
			local damage = math.abs(damagePrimary + damageSecondary)
			if damage > self:getHealth() then
				damage = self:getHealth()
			end

			damageImpact[k][1] = damageImpact[k][1] + damage

			if currentTime - damageImpact[k][2] > secondsToGetHealing then
				sendImpactToClient(k, TYPE_DAMAGE)
			end		
		end
	end

	if not attacker then
		return typePrimary, damagePrimary, typeSecondary, damageSecondary, colorPrimary, colorSecondary
	end

	return typePrimary, damagePrimary, typeSecondary, damageSecondary, colorPrimary, colorSecondary
end

function Creature:onHear(speaker, words, type)
	if hasEvent.onHear then
		Event.onHear(self, speaker, words, type)
	end
end
