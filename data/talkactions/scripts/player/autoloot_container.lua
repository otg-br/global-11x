-- addLoot
function onSay(player, word, param)
	if player:getClient().version >= 1150 then
		player:sendTextMessage(MESSAGE_INFO_DESCR, string.format("This command is only for client 10."))
		return false
	end

	player:sendAutoloot()

	return false
end
