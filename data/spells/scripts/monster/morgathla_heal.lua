function onCastSpell(creature, var)
	local cHealth = creature:getHealth()*100/creature:getMaxHealth()
	if creature:getStorageValue("canHeal") ~= 1 and cHealth <= 95 then
		local r = math.random(1888, 2888)
		creature:addHealth(r)
		local msg = math.random(1, 3)
		if msg == 1 then
			creature:say("THE SPAWN CHAINS MORE POWER INTO ITS BODY", TALKTYPE_MONSTER_SAY)
		end
	end
end
