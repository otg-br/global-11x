function canJoin(player)
	return true -- Permite que todos os jogadores entrem no canal
end

function onJoin(player)
	-- Mensagem de boas-vindas quando o jogador entra no canal
	player:sendChannelMessage("", "Welcome to the Loot Channel! Here you will see all your autoloot activities.", TALKTYPE_CHANNEL_Y, 10)
	return true
end

function onLeave(player)
	-- Mensagem quando o jogador sai do canal
	return true
end

function onSpeak(player, type, message)
	-- Permite que jogadores falem no canal (opcional)
	return true
end
