--
-- Created by IntelliJ IDEA.
-- User: jlcvp + LucasCP
-- Date: 30/08/19
-- Time: 17:09
--

function onHealthChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
	if not creature then
		return primaryDamage, primaryType, secondaryDamage, secondaryType
	end
	if not attacker then
		attacker = creature
	end

	local player = Player(creature:getId())
	local k, secondsToGetHealing, currentTime = attacker:getId(), 2, os.stime()
	if primaryType == COMBAT_HEALING and player then
		if healingImpact[player:getId()] == nil then
			healingImpact[player:getId()] = healingImpact[player:getId()] or {0, currentTime}
		end

		local heal = primaryDamage
		if heal + player:getHealth() > player:getMaxHealth() then
			heal = player:getMaxHealth() - player:getHealth()
		end

		healingImpact[player:getId()][1] = healingImpact[player:getId()][1] + heal

		if currentTime - healingImpact[player:getId()][2] > secondsToGetHealing then
			sendImpactToClient(player:getId(), TYPE_HEALING)
		end
	end

	return primaryDamage, primaryType, secondaryDamage, secondaryType
end
