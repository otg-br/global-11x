local login = CreatureEvent("RegisterFunction_charm")
local charmHealthChange = CreatureEvent("charmHealthChange")


function login.onLogin(player)
	-- Events
	player:registerEvent("charmHealthChange")
	return true
end

function charmHealthChange.onHealthChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
	if not attacker or not creature:isPlayer() then
		return primaryDamage, primaryType, secondaryDamage, secondaryType
	end

	local monster = Monster(attacker)
	if not monster or monster:getType():raceId() == 0 then
		return primaryDamage, primaryType, secondaryDamage, secondaryType
	end

	local atualCharm = creature:getMonsterCharm(monster:getType():raceId())
	if math.random(1, 10000) <= 500 then
		if atualCharm == 7 or atualCharm == 8 then
			local damage = math.abs(primaryDamage)
			local dano = primaryType
			if math.abs(primaryDamage) > 0 then
				damage = math.abs(primaryDamage)
			elseif math.abs(secondaryDamage) > 0 then
				damage = math.abs(secondaryDamage)
				dano = secondaryType
			end

			primaryDamage = 0
			secondaryDamage = 0

			if atualCharm == 7 then
				doTargetCombatHealth(creature, attacker, dano, -(damage)/2, -(damage)/2, CONST_ME_POFF, ORIGIN_CHARM)
			else
				creature:sendTextMessage(MESSAGE_DAMAGE_DEALT, "Active charm 'Dodge'")
			end
		elseif atualCharm == 9 then
			local condition = Condition(CONDITION_HASTE)
			condition:setParameter(CONDITION_PARAM_TICKS, 10000)
			condition:setFormula(0.7, -56, 0.7, -56)
			creature:addCondition(condition)
			creature:sendTextMessage(MESSAGE_DAMAGE_DEALT, "Active charm 'Adrenaline Burst'")
		elseif atualCharm == 10 then
			local condition = Condition(CONDITION_PARALYZE)
			condition:setParameter(CONDITION_PARAM_TICKS, 10000)
			condition:setFormula(-0.40, -0.15, -0.55, -0.15)
			monster:addCondition(condition)
			creature:sendTextMessage(MESSAGE_DAMAGE_DEALT, "Active charm 'Numb'")
		elseif atualCharm == 11 then
			local conditions = {CONDITION_FIRE, CONDITION_POISON, CONDITION_ENERGY, CONDITION_PARALYZE, CONDITION_DRUNK, CONDITION_FREEZING}
			local combat = Combat()
			combat:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_MAGIC_BLUE)
			combat:setParameter(COMBAT_PARAM_AGGRESSIVE, 0)
			combat:setParameter(COMBAT_PARAM_DISPEL, conditions[math.random(#conditions)])
			local var = { number = creature:getId(), type = 1}
			combat:execute(creature, var)
			creature:sendTextMessage(MESSAGE_DAMAGE_DEALT, "Active charm 'Cleanse'")
		end
	end
	return primaryDamage, primaryType, secondaryDamage, secondaryType
end

login:type("login")
login:register()

charmHealthChange:type("healthchange")
charmHealthChange:register()
