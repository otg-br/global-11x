-- local config = {
	-- ['Monday'] = 'minotaur',
	-- ['Tuesday'] = 'wrath',
	-- ['Friday'] = 'wrath',
	-- ['Thursday'] = 'wrath',
	-- ['Wednesday'] = 'golem',
	-- ['Saturday'] = 'minotaur', 
	-- ['Sunday'] = 'wrath' 
-- } 

local config = {
	['Monday'] = 'wrath',
	['Tuesday'] = 'wrath',
	['Friday'] = 'wrath',
	['Thursday'] = 'wrath',
	['Wednesday'] = 'wrath',
	['Saturday'] = 'wrath', 
	['Sunday'] = 'wrath' 
} 
 
local spawnByDay = true

function onStartup()
	local str = ""
	if spawnByDay then
		str = '>> [Catacombs] loaded map '.. config[os.sdate("%A")] ..'.'
		Game.loadMap('data/world/worldchanges/catacombs/' .. config[os.sdate("%A")] ..'.otbm')
		addEvent(function()
			Game.loadSpawnFile('data/world/worldchanges/catacombs/' .. config[os.sdate("%A")] ..'-spawn.xml')
			str = str .. " (with respawn)"		
		end, 2*1000)
		Game.sendConsoleMessage(str, CONSOLEMESSAGE_TYPE_STARTUP)
	else
		 Game.sendConsoleMessage('>> Catacombs: not today', CONSOLEMESSAGE_TYPE_STARTUP)
	end
	return true
end