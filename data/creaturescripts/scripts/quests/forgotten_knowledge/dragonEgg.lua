local function revertHorror()
	local melting = Tile(Position(32267, 31071, 14)):getTopCreature()
	if melting then
		local diference, pos, monster = 0, 0, false
		local specs, spec = Game.getSpectators(Position(32269, 31091, 14), false, false, 12, 12, 12, 12)
		for i = 1, #specs do
			spec = specs[i]
			if spec:isMonster() and spec:getName():lower() == 'melting frozen horror' then
				health = spec:getHealth()
				pos = spec:getPosition()
				spec:teleportTo(Position(32267, 31071, 14))
				diference = melting:getHealth() - health
				melting:addHealth( - diference)
				melting:teleportTo(pos)
				monster = true
			end
		end
		if not monster then
			if melting then
				melting:remove()
			end
		end
	end
end

local function changeHorror()
	local melting = Tile(Position(32267, 31071, 14)):getTopCreature()
	if melting then
		local pos = 0
		local specs, spec = Game.getSpectators(Position(32269, 31091, 14), false, false, 12, 12, 12, 12)
		for i = 1, #specs do
			spec = specs[i]
			if spec:isMonster() and spec:getName():lower() == 'solid frozen horror' then
				pos = spec:getPosition()
				spec:teleportTo(Position(32267, 31071, 14))
				melting:teleportTo(pos)
			end
		end
		addEvent(revertHorror, 20 * 1000)
	end
end

local function checkHorror()
	local spectators = Game.getSpectators(Position(32268, 31090, 14), false, false, 12, 12, 12, 12)
	for _, m in pairs(spectators) do
		if m and m:isMonster() then
			if m:getName():lower() == "melting frozen horror" then
				return true
			end
		end
	end
	return false
end

function onPrepareDeath(creature, lastHitKiller, mostDamageKiller)
    if not creature:getName():lower() == "dragon egg" and creature:isMonster() then
        return true
	end
	creature:addHealth(1, false)
	return true
end

function onHealthChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
    if creature:getName():lower() == 'dragon egg' then
		local percentageHealth = (creature:getHealth()/creature:getMaxHealth())*100
		local hasHorror = checkHorror()
		if primaryType == COMBAT_HEALING then
			doTargetCombatHealth(0, creature, COMBAT_ICEDAMAGE, -primaryDamage, -primaryDamage, CONST_ME_MAGIC_GREEN)
			return true
		end
		if primaryType ~= COMBAT_FIREDAMAGE then
			primaryType = COMBAT_HEALING
			creature:addHealth(primaryDamage, true)
		end
		if creature and percentageHealth <= 3.0 then
			if not hasHorror then
				creature:say('The egg sends out a fiery eruption!\n Weakening the frozen horror significantly!', TALKTYPE_MONSTER_SAY)
				changeHorror()
				return true
			end
		end
	end
	return primaryDamage, primaryType, secondaryDamage, secondaryType
end
