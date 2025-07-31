function onUpdateDatabase()
	Game.sendConsoleMessage("> Updating database to version 1 (account names)", CONSOLEMESSAGE_TYPE_STARTUP)
	db.query("ALTER TABLE `accounts` ADD `name` VARCHAR(32) NOT NULL AFTER `id`")
	db.query("UPDATE `accounts` SET `name` = `id`")
	db.query("ALTER TABLE `accounts` ADD UNIQUE (`name`)")
	return true
end

