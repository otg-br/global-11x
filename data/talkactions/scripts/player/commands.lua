function onSay(player, word, param)
	local comandos = "Commands:\n"..
	"\n!outfit\n!target"..
	"\n!serverinfo\n!online\n!uptime\n!flask on/off"

	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, comandos)
	return false
end
