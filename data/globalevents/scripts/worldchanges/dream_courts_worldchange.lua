local config = {
	['Monday'] = 'Alptramun',
	['Tuesday'] = 'Izcandar_the_Banished',
	['Friday'] = 'Malofur_Mangrinder',
	['Thursday'] = 'Maxxenius',
	['Wednesday'] = 'Malofur_Mangrinder',
	['Saturday'] = 'Plagueroot', 
	['Sunday'] = 'Maxxenius' 
} 

 
local spawnByDay = true

function onStartup()
	if spawnByDay then
		print('>> [dream courts] loaded: ' .. config[os.sdate("%A")])
		Game.loadMap('data/world/worldchanges/dream_courts_bosses/' .. config[os.sdate("%A")] ..'.otbm')
	else
		 print('>> dream courts boss: not boss today')
	end
	return true
end

function onTime()
	if spawnByDay then
		print('>> [dream courts] loaded: ' .. config[os.sdate("%A")])
		Game.loadMap('data/world/worldchanges/dream_courts_bosses/' .. config[os.sdate("%A")] ..'.otbm')
	else
		 print('>> dream courts boss: not boss today')
	end
	return true
end