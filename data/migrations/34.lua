function onUpdateDatabase()
	Game.sendConsoleMessage("Update migrations to 35 >> player autoloot", CONSOLEMESSAGE_TYPE_STARTUP)
	db:query("ALTER TABLE players ADD autoloot blob")
	return true
end

