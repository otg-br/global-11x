function onUpdateDatabase()
	Game.sendConsoleMessage("> Updating database to version 7 (offline training)", CONSOLEMESSAGE_TYPE_STARTUP)
	db.query("ALTER TABLE `players` ADD `offlinetraining_time` SMALLINT UNSIGNED NOT NULL DEFAULT 43200")
	db.query("ALTER TABLE `players` ADD `offlinetraining_skill` INT NOT NULL DEFAULT -1")
	return true
end

