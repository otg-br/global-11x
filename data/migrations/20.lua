function onUpdateDatabase()
	Game.sendConsoleMessage("> Updating database to version 20 (authenticator token support)", CONSOLEMESSAGE_TYPE_STARTUP)
	db.query("ALTER TABLE `accounts` ADD COLUMN `secret` CHAR(16) NULL AFTER `password`")
	return true
end

