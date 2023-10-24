function onSay(cid, words, param)
	local player = Player(cid)
	
	if not player:getGroup():getAccess() then
		return true
	end

	if player:getGroup():getId() < 6 then
		return true
	end

	local target = Player(param)
	if target == nil then
		player:sendCancelMessage("A player with that name is not online.")
		return false
	end

	if target:getAccountType() < ACCOUNT_TYPE_TUTOR then
		broadcastMessage("Congratz! The player " .. target:getName() .. " has been promoted to Tutor. (:", MESSAGE_EVENT_ADVANCE)
		target:setAccountType(ACCOUNT_TYPE_TUTOR)
	else
		player:sendCancelMessage("This player is already a tutor.")
		return false
	end
	return false
end

