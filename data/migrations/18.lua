function onUpdateDatabase()
	Game.sendConsoleMessage("> Updating database to version 19 (update on depot chests)", CONSOLEMESSAGE_TYPE_STARTUP)
	db.query("UPDATE `player_depotitems` SET `pid` = 17 WHERE `pid` = 0")
	db.query("UPDATE `player_depotitems` SET `pid` = 17 WHERE `pid` > 17")
	return true
end

