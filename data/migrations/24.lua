function onUpdateDatabase()
	print("Uptade migrations to 25 (Critical)")
	db.query("ALTER TABLE `players` ADD `critical` INT(20) DEFAULT '0'")
	return true
end
