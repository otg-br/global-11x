
function onSay(player, word, param)
	if player:getClient().version > 1100 then
		player:sendCancelMessage("Use the client to get this information.")
		return false
	end

	player:makeBasicAnalyserModal()
	return false
end