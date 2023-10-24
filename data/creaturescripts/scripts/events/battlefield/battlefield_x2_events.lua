function onLogout(player)
	local info = Battlefield_x2:findPlayer(player)
	if info then
		Battlefield_x2:onLeave(player)
	end
	return true
end

function onPrepareDeath(player, killer)
	local info = Battlefield_x2:findPlayer(player)
	if info then
		Battlefield_x2:onDeath(player, killer)
	end
	return false
end

function onHealthChange(player, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
	if not attacker then
		return primaryDamage, primaryType, secondaryDamage, secondaryType
	end
	local thisInfo = Battlefield_x2:findPlayer(player)
	local otherInfo = Battlefield_x2:findPlayer(attacker)
	if thisInfo and otherInfo and thisInfo.team == otherInfo.team then
		if primaryType ~= COMBAT_HEALING then
			return COMBAT_NONE, 0, COMBAT_NONE, 0
		end
	end
	return primaryDamage, primaryType, secondaryDamage, secondaryType
end


function onManaChange(player, attacker, manaChange, origin)
	if not attacker then
		return manaChange
	end
	local thisInfo = Battlefield_x2:findPlayer(player)
	local otherInfo = Battlefield_x2:findPlayer(attacker)
	if thisInfo and otherInfo and thisInfo.team == otherInfo.team then
		return 0
	end
	return manaChange
end