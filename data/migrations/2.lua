function onUpdateDatabase()
	Game.sendConsoleMessage("> Updating database to version 3 (bank balance)", CONSOLEMESSAGE_TYPE_STARTUP)
	db.query("ALTER TABLE `players` ADD `balance` BIGINT UNSIGNED NOT NULL DEFAULT 0")
	return true
end

