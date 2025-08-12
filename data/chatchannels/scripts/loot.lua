function canJoin(player)
	return player:getClient().version == 1100
end

function onSpeak()
	return false
end
