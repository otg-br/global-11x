local combat = Combat()
combat:setParameter(COMBAT_PARAM_DISTANCEEFFECT, CONST_ANI_EARTH)
combat:setParameter(COMBAT_PARAM_CREATEITEM, ITEM_WILDGROWTH)

function onCastSpell(creature, var, isHotkey)
	local isInZombie = Zombie:findPlayer(creature)
	if isInZombie then
		creature:sendCancelMessage("You cannot use this rune inside the zombie event.")
		return false
	end
	return combat:execute(creature, var)
end
