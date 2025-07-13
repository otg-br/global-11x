function onUse(player, item, position, target, targetPosition)
	local days = item.actionid - 7097
	if days > 0 then
		item:remove(1)
		player:setPremiumEndsAt(player:getPremiumEndsAt() + (days * 86400)) -- Add days to current premium time
		player:sendTextMessage(MESSAGE_INFO_DESCR, string.format("You won %d days VIP, now you have %d days VIP.", days, math.max(0, math.ceil((player:getPremiumEndsAt() - os.stime()) / 86400))))
	end

	return true
end