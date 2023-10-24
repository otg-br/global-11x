function onSay(cid, words, param)
	local player = Player(cid)
	
	if not player:getGroup():getAccess() then
		return true
	end

	if player:getAccountType() < ACCOUNT_TYPE_GOD then
		return false
	end

	local target = Player(param)
	if target == nil then
		player:sendCancelMessage("A player with that name is not online.")
		return false
	end

	target:generatePreyData()
	target:changePreyState(2, 3)
	return false
end

