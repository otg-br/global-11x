function onSay(cid, words, param)
	local player = Player(cid)
	if not player:getGroup():getAccess() then
		return true
	end

	if player:getGroup():getId() < 6 then
		return true
	end

	local names = ''
	local amount = 0
	for _, c in pairs(Game.getPlayers()) do
		if c and not c:hasPing() then
			if names ~= '' then
				names = names .. ', ' .. c:getName()
			else
				names = c:getName()
			end
			amount = amount + 1
		end
	end
	player:sendTextMessage(MESSAGE_INFO_DESCR, 'Amount of spoofs online: ' .. amount .. '\n' .. names)
	return false
end
