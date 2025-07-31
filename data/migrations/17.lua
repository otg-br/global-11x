function onUpdateDatabase()
	Game.sendConsoleMessage("> Updating database to version 18 (optimize account password field)", CONSOLEMESSAGE_TYPE_STARTUP)
	db.query("DELETE FROM `server_config` WHERE `config` = 'encryption'")
	db.query("ALTER TABLE `accounts` CHANGE `password` `password` CHAR(40) NOT NULL")
	return true
end

