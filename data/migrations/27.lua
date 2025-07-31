function onUpdateDatabase()
	Game.sendConsoleMessage("> Updating database to version 27 (Fix bonus reroll)", CONSOLEMESSAGE_TYPE_STARTUP)
	db.query("ALTER TABLE `players` DROP COLUMN `bonus_reroll`")
	db.query("ALTER TABLE `players` ADD COLUMN `bonus_reroll` int(11) NOT NULL DEFAULT '0'")
	return true
end

