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
		Game.sendConsoleMessage('>> [dream courts] loaded: ' .. config[os.sdate("%A")], CONSOLEMESSAGE_TYPE_STARTUP)
		Game.loadMap('data/world/worldchanges/dream_courts_bosses/' .. config[os.sdate("%A")] ..'.otbm')
	else
		 Game.sendConsoleMessage('>> dream courts boss: not boss today', CONSOLEMESSAGE_TYPE_STARTUP)
	end
	return true
end

function onTime()
	if spawnByDay then
		Game.sendConsoleMessage('>> [dream courts] loaded: ' .. config[os.sdate("%A")], CONSOLEMESSAGE_TYPE_STARTUP)
		Game.loadMap('data/world/worldchanges/dream_courts_bosses/' .. config[os.sdate("%A")] ..'.otbm')
	else
		 Game.sendConsoleMessage('>> dream courts boss: not boss today', CONSOLEMESSAGE_TYPE_STARTUP)
	end
	return true
end