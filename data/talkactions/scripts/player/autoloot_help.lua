-- addLoot
function onSay(player, word, param)
	if player:getClient().version >= 1150 then
		player:sendTextMessage(MESSAGE_INFO_DESCR, string.format("This command is only for client 10."))
		return false
	end

	local text = "Autoloot Commands:\n!bp - manage loot backpack\n!add itemName - ADD or Remove Item to list\n!show - Show your item list"
	player:popupFYI(text)
	return false
end
