local config = {
	[1] = {name = "nightmare isles", folderName = "nightmare_isles", mapName = {"river_near_Drefia", "northernmost_coast", "Ankhramun_tar_pits"},
	chance = 100, hasSpawn = true},
	[2] = {name = "hive outpost", folderName = "hive_outpost", mapName = {"hive_outpost"},
	chance = 33, hasSpawn = true},
	[3] = {name = "fury gates", folderName = "fury_gates", mapName = {"kazordoon", "venore", "darashia",
	"thais", "porthope", "libertybay", "ankrahmun", "edron", "abdendriel", "carlin"},
	chance = 100, hasSpawn = true}
}

function onStartup()
	for i = 1, #config do
		local r = math.random(1, 100)
		local r_
		local map
		local str = ""
		if r <= config[i].chance then
			if #config[i].mapName > 1 then
				r_ = math.random(1, #config[i].mapName)
				map = 'data/world/worldchanges/'..config[i].folderName..'/'..config[i].mapName[r_]
			else
				map = 'data/world/worldchanges/'..config[i].folderName..'/'..config[i].mapName[1]
			end
			Game.loadMap(map..'.otbm')
			str = '>> ['..config[i].folderName..'] loaded map from '..map..'.'
			if config[i].hasSpawn then
				addEvent(function()
					Game.loadSpawnFile(map..'-spawn.xml')
					str = str .. " (with respawn)"
					Game.sendConsoleMessage(str, CONSOLEMESSAGE_TYPE_STARTUP)
				end, 2*1000)
			else
				Game.sendConsoleMessage(str, CONSOLEMESSAGE_TYPE_STARTUP)
			end
			setWorldChangeActive(config[i].name)	
		else
			Game.sendConsoleMessage('>> ['..config[i].name..'] not today.', CONSOLEMESSAGE_TYPE_STARTUP)
		end
	end
	return true
end
