function onUpdateDatabase()
	Game.sendConsoleMessage("Uptade migrations to 25 (Critical)", CONSOLEMESSAGE_TYPE_STARTUP)
	db.query("ALTER TABLE `players` ADD `critical` INT(20) DEFAULT '0'")
	return true
end

