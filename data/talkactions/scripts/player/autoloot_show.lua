-- addLoot
function onSay(player, word, param)
	if player:getClient().version >= 1150 then
		player:sendTextMessage(MESSAGE_INFO_DESCR, string.format("This command is only for client 10."))
		return false
	end

	local text = "AutoLoot List:\n"
	local list = player:getAutolootList()
	for _, id in pairs(list) do
		text = text .. "- " .. ItemType(id):getName() .. "\n"
	end

	player:popupFYI(text)
	return false
end
