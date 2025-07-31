function onUpdateDatabase()
	Game.sendConsoleMessage("> Updating database to version 31 (live casting support)", CONSOLEMESSAGE_TYPE_STARTUP) 
	db.query("ALTER TABLE `players_online` ADD COLUMN `cast_on` tinyint(1) default '0' NOT NULL, ADD COLUMN `cast_password` varchar(40) default NULL, ADD COLUMN `cast_spectators` int(5) default '0' NOT NULL;")
	return true
end

