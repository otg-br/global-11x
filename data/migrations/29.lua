function onUpdateDatabase()
    db.query("ALTER TABLE `players` ADD `instantrewardtokens` int(11) UNSIGNED NOT NULL DEFAULT '0'")
    db.query([[
		CREATE TABLE IF NOT EXISTS daily_reward_history (
			`id` INT NOT NULL PRIMARY KEY auto_increment,
			`streak` smallint(2) not null default 0,
			`event` varchar(255),
			`time` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
			`instant` tinyint unsigned NOT NULL DEFAULT 0 ,
			`player_id` INT NOT NULL,

			FOREIGN KEY(`player_id`) REFERENCES `players`(`id`)
				ON DELETE CASCADE
		)
	]])
    return true
end
