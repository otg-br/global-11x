function canJoin(player)
	return true
end

function onJoin(player)
	player:sendChannelMessage("", "Welcome to the Auto Loot Channel! Here you will see all your autoloot activities and notifications.", TALKTYPE_CHANNEL_Y, 9)
	return true
end

function onLeave(player)
	return true
end

function onSpeak(player, type, message)
	return true
end