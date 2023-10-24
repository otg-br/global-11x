function onSay(player, word, param)
	local str = "Siga-nos em nossos canais da Twitch e ganhe coins por isso!" ..
	" Basta dar follow nos canais a seguir e enviar um sussuro informando o nome do personagem."..
	"\ntwitch.tv/worthdavi\ntwitch.tv/LukSrT"

	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, str)
	return false
end
