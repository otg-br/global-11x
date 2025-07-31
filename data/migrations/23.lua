﻿function onUpdateDatabase()
	Game.sendConsoleMessage("> Updating database to version 23 (New Skill Attributes)", CONSOLEMESSAGE_TYPE_STARTUP)
	db.query("ALTER TABLE `players` ADD COLUMN `skill_critical_hit_chance` int(10) unsigned NOT NULL DEFAULT 0")
	db.query("ALTER TABLE `players` ADD COLUMN `skill_critical_hit_chance_tries` bigint(20) unsigned NOT NULL DEFAULT 0")
	db.query("ALTER TABLE `players` ADD COLUMN `skill_critical_hit_damage` int(10) unsigned NOT NULL DEFAULT 0")
	db.query("ALTER TABLE `players` ADD COLUMN `skill_critical_hit_damage_tries` bigint(20) unsigned NOT NULL DEFAULT 0")
	db.query("ALTER TABLE `players` ADD COLUMN `skill_life_leech_chance` int(10) unsigned NOT NULL DEFAULT 0")
	db.query("ALTER TABLE `players` ADD COLUMN `skill_life_leech_chance_tries` bigint(20) unsigned NOT NULL DEFAULT 0")
	db.query("ALTER TABLE `players` ADD COLUMN `skill_life_leech_amount` int(10) unsigned NOT NULL DEFAULT 0")
	db.query("ALTER TABLE `players` ADD COLUMN `skill_life_leech_amount_tries` bigint(20) unsigned NOT NULL DEFAULT 0")
	db.query("ALTER TABLE `players` ADD COLUMN `skill_mana_leech_chance` int(10) unsigned NOT NULL DEFAULT 0")
	db.query("ALTER TABLE `players` ADD COLUMN `skill_mana_leech_chance_tries` bigint(20) unsigned NOT NULL DEFAULT 0")
	db.query("ALTER TABLE `players` ADD COLUMN `skill_mana_leech_amount` int(10) unsigned NOT NULL DEFAULT 0")
	db.query("ALTER TABLE `players` ADD COLUMN `skill_mana_leech_amount_tries` bigint(20) unsigned NOT NULL DEFAULT 0")
	return true
end

