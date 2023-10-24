-- addLoot
function onSay(player, word, param)
	if player:getClient().version >= 1150 then
		player:sendTextMessage(MESSAGE_INFO_DESCR, string.format("This command is only for client 10."))
		return false
	end

	local itemType = ItemType(param)
	if itemType:getId() == 0 then
		player:sendTextMessage(MESSAGE_INFO_DESCR, string.format("Item with name '%s' does not exist.", param))
		return false
	end

	local inArray = isInArray(player:getAutolootList(), itemType:getId())
	player:manageAutoloot(itemType:getId())
	player:sendTextMessage(MESSAGE_INFO_DESCR, string.format("You have %s '%s' to your loot list.", (not inArray and 'added' or 'removed '), itemType:getName()))
	return false
end
