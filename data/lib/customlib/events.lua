CHANNEL_EVENTS = 12

function Game.openEventChannel(event, channelId)
	if not channelId then
		channelId = CHANNEL_EVENTS
	end
	for _, player in pairs(Game.getPlayers()) do
		player:openChannel(channelId)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("O evento %s comeou.", event))
	end
	return true
end

function Game.sendEventMessage(mensagem, canal)
	if not canal then
		canal = CHANNEL_EVENTS
	end
    for _, pid in pairs(Game.getPlayers()) do
        Player(pid):sendChannelMessage("", mensagem, TALKTYPE_CHANNEL_O, canal) 
    end
	return true
end
