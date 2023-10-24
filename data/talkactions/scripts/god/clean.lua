function onSay(player, words, param)
	if not player:getGroup():getAccess() then
		return true
	end

	if player:getGroup():getId() < 6 then
		return true
	end

	local itemCount = cleanMap()
	if itemCount > 0 then
		player:sendTextMessage(MESSAGE_STATUS_WARNING, "Cleaned " .. itemCount .. " item" .. (itemCount > 1 and "s" or "") .. " from the map.")
	end
	return false
end
