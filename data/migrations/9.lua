function onUpdateDatabase()
	Game.sendConsoleMessage("> Updating database to version 10 (stamina)", CONSOLEMESSAGE_TYPE_STARTUP)
	db.query("ALTER TABLE `players` ADD `stamina` SMALLINT UNSIGNED NOT NULL DEFAULT 2520")
	return true
end

