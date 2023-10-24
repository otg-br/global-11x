function onThink(creature)
	if not FEROXA_ACTIVATED then
		return true
	end
	local healthPercentage = (creature:getHealth()*100)/creature:getMaxHealth()
	local cPos = creature:getPosition()
	if FEROXA_STAGE == 1 then
		if healthPercentage <= 50 then
			creature:remove()
			local monster = Game.createMonster("Feroxa Werewolf", cPos, true, true)
			if monster then monster:registerEvent('feroxaHealth') end
			FEROXA_STAGE = 2
		end
	elseif FEROXA_STAGE == 2 then
		if healthPercentage <= 80 then
			creature:remove()
			local monster = Game.createMonster("Feroxa", cPos, true, true)
			if monster then monster:registerEvent('feroxaDeath') end
			FEROXA_STAGE = 3
		end
	end
	return true
end

function onHealthChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
	primaryDamage = 0
	secondaryDamage = 0	
	return primaryDamage, primaryType, secondaryDamage, secondaryType
end

function onDeath(creature, corpse, deathList)
	if not FEROXA_ACTIVATED then
		return true
	end
	local feroxas = {
	[1] = 'Feroxa Wolf',
	[2] = 'Feroxa Real'
	}
	local cPos = creature:getPosition()
	if FEROXA_STAGE == 3 then
		Game.createMonster(feroxas[math.random(1, 2)], cPos)
		FEROXA_STAGE = 4
	end
	return true
end
