local function sendSquare(cid, color, sec, n, send)
    local creature = Creature(cid)
    if not creature then
        return false
    end
    if n <= sec then
        local pos = creature:getPosition()
        local msg = NetworkMessage()
        msg:addByte(0x93)
        msg:addU32(cid)
        msg:addByte(0x01)
        msg:addByte(color)
        for i = 1, #send do
            if pos:getDistance(send[i]:getPosition()) <= 7 then
                msg:sendToPlayer(send[i])
            end
        end
        addEvent(sendSquare, 1000, cid, color, sec, n + 1, send)
    end
end

function Creature:sendSquare(color, sec, canSee, n)
    --// Creature:sendSquare(color, sec[, canSee])
    local pos = self:getPosition()

    --// Create a send table if canSee is an argument (otherwise uses spectators)
    local specs = Game.getSpectators(pos, false, true, 0, 8, 0, 6)
    local send = {}
    if canSee then
        if type(canSee) == 'table' then
            for i = 1, #specs do
                if isInArray(canSee, specs[i]:getName()) then
                    send[#send+1] = specs[i]
                end
            end
        else
            return print('Error [Creature:sendSquare] invalid argument type for canSee')
        end
    end
    send = (next(send) and send) or specs
    sendSquare(self:getId(), color, sec, (n and n+1) or 0, send)
    return true
end

function Creature.getClosestFreePosition(self, position, maxRadius, mustBeReachable)
	maxRadius = maxRadius or 1

	-- backward compatability (extended)
	if maxRadius == true then
		maxRadius = 2
	end

	local checkPosition = Position(position)
	for radius = 0, maxRadius do
		checkPosition.x = checkPosition.x - math.min(1, radius)
		checkPosition.y = checkPosition.y + math.min(1, radius)

		local total = math.max(1, radius * 8)
		for i = 1, total do
			if radius > 0 then
				local direction = math.floor((i - 1) / (radius * 2))
				checkPosition:getNextPosition(direction)
			end

			local tile = Tile(checkPosition)
			if tile:getCreatureCount() == 0 and not tile:hasProperty(CONST_PROP_IMMOVABLEBLOCKSOLID) and
				(not mustBeReachable or self:getPathTo(checkPosition)) then
				return checkPosition
			end
		end
	end
	return Position()
end


function Creature.getMonster(self)
	return self:isMonster() and self or nil
end

function Creature.getPlayer(self)
	return self:isPlayer() and self or nil
end

function Creature.isItem(self)
	return false
end

function Creature.isMonster(self)
	return false
end

function Creature.isNpc(self)
	return false
end

function Creature.isPlayer(self)
	return false
end

function Creature.isTile(self)
	return false
end

function Creature:setMonsterOutfit(monster, time)
	local monsterType = MonsterType(monster)
	if not monsterType then
		return false
	end

	if self:isPlayer() and not (self:hasFlag(PlayerFlag_CanIllusionAll) or monsterType:isIllusionable()) then
		return false
	end

	local condition = Condition(CONDITION_OUTFIT)
	condition:setOutfit(monsterType:getOutfit())
	condition:setTicks(time)
	self:addCondition(condition)

	return true
end

function Creature:setItemOutfit(item, time)
	local itemType = ItemType(item)
	if not itemType then
		return false
	end

	local condition = Condition(CONDITION_OUTFIT)
	condition:setOutfit({
		lookTypeEx = itemType:getId()
	})
	condition:setTicks(time)
	self:addCondition(condition)

	return true
end

local function smallFixSummon(cid, mid)
	local m = Monster(cid)
	local p = Player(cid)
	if not p or not  m then
		return
	end
	local last = m:getPosition()
	m:teleportTo(p:getPosition(), false)
	m:teleportTo(last, false)
end

function Creature:addSummon(monster)
	local summon = Monster(monster)
	if not summon then
		return false
	end

	summon:setTarget(nil)
	summon:setFollowCreature(nil)
	summon:setDropLoot(false)
	summon:setSkillLoss(false)
	summon:setMaster(self)
	addEvent(smallFixSummon, 200, summon:getId(), self:getId())
	return true
end

function Creature:removeSummon(monster)
	local summon = Monster(monster)
	if not summon or summon:getMaster() ~= self then
		return false
	end

	summon:setTarget(nil)
	summon:setFollowCreature(nil)
	summon:setDropLoot(false)
	summon:setSkillLoss(false)
	summon:setMaster(nil)

	return true
end

function Creature:addDamageCondition(target, type, list, damage, period, rounds)
	if damage <= 0 or not target or target:isImmune(type) then
		return false
	end

	local condition = Condition(type)
	condition:setParameter(CONDITION_PARAM_OWNER, self:getCombatId())
	condition:setParameter(CONDITION_PARAM_DELAYED, true)

	if list == DAMAGELIST_EXPONENTIAL_DAMAGE then
		local exponent, value = -10, 0
		while value < damage do
			value = math.floor(10 * math.pow(1.2, exponent) + 0.5)
			condition:addDamage(1, period or 4000, -value)

			if value >= damage then
				local permille = math.random(10, 1200) / 1000
				condition:addDamage(1, period or 4000, -math.max(1, math.floor(value * permille + 0.5)))
			else
				exponent = exponent + 1
			end
		end
	elseif list == DAMAGELIST_LOGARITHMIC_DAMAGE then
		local n, value = 0, damage
		while value > 0 do
			value = math.floor(damage * math.pow(2.718281828459, -0.05 * n) + 0.5)
			if value ~= 0 then
				condition:addDamage(1, period or 4000, -value)
				n = n + 1
			end
		end
	elseif list == DAMAGELIST_VARYING_PERIOD then
		for _ = 1, rounds do
			condition:addDamage(1, math.random(period[1], period[2]) * 1000, -damage)
		end
	elseif list == DAMAGELIST_CONSTANT_PERIOD then
		condition:addDamage(rounds, period * 1000, -damage)
	end

	target:addCondition(condition)
	return true
end
