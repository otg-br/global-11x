function onUpdateDatabase()
	print("Update migrations to 35 >> player autoloot")
	db:query("ALTER TABLE players ADD autoloot blob")
	return true
end
