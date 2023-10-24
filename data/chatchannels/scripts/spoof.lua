function canJoin(player)
	return player:getAccountType() >= ACCOUNT_TYPE_GOD
end

function onSpeak(player, type, message)
	return false
end
