function onSay(player, words, param)
	if not player:getGroup():getAccess() then
		return true
	end
	
	if player:getGroup():getId() < 4 then return true end

	local id = tonumber(param) or param
	local town = Town(id)
	if town == nil then
		player:sendCancelMessage("Town not found.")
		return false
	end

	player:teleportTo(town:getTemplePosition())
	return false
end
