function onUse(player, item, position, target, targetPosition)
	local days = 30  -- Fixed 30 days VIP
    
    item:remove(1)
    player:addVipDays(days)
    
    player:sendTextMessage(MESSAGE_INFO_DESCR, string.format("You won %d days VIP, now you have %d days VIP.", days, math.max(0, math.ceil((player:getVipDays() - os.time()) / 86400))))
    
    return true
end