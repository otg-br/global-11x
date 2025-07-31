function onUpdateDatabase()
	Game.sendConsoleMessage("> Updating database to version 6 (market bug fix)", CONSOLEMESSAGE_TYPE_STARTUP)
	db.query("DELETE FROM `market_offers` WHERE `amount` = 0")
	return true
end

