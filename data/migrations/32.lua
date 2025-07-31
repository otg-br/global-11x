﻿function onUpdateDatabase()
	Game.sendConsoleMessage("> Updating database to version 33 (Adding prey system)", CONSOLEMESSAGE_TYPE_STARTUP)
	db.query("CREATE TABLE IF NOT EXISTS `player_preydata` (`player_id` int(11) NOT NULL, `data` blob NOT NULL, PRIMARY KEY (`player_id`), FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE);")
	db.query("ALTER TABLE `players` ADD `bonusrerollcount` BIGINT(20) NULL DEFAULT '0' AFTER `balance`;")
	return true
end

