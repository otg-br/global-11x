function onSay(player, words, param)
	if not player:getGroup():getAccess() then
		return true
	end
	
	if player:getGroup():getId() < 4 then return true end

	player:teleportTo(player:getTown():getTemplePosition())
	return false
end
