function onLogout(player)
	local isInEvent = Zombie:findPlayer(player)
	if isInEvent then
		Zombie:onLeave(player:getId(), false)
	end
	return true
end

function onPrepareDeath(player, killer)
	local isInEvent = Zombie:findPlayer(player)
	if isInEvent then
		Zombie:onLeave(player:getId(), false)
	end
	return false
end