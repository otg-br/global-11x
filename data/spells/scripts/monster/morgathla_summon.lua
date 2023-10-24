local combat = Combat()
combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_NONE)
local maxsummons = 2

function onCastSpell(creature, var)
	local summoncount = creature:getSummons()
	if #summoncount < maxsummons then
		local mid = Game.createMonster("Hungry Brood", creature:getPosition())
			if not mid then
				return
			end
		mid:setMaster(creature)
		mid:registerEvent("beetleRevive")
	end
	return combat:execute(creature, var)
end
