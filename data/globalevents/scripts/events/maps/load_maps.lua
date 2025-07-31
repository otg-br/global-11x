local config = {
	[1] = {event = "Battlefield", map = "battlefield_x2"},
	[2] = {event = "Battlefield 2.0", map = "battlefield_x4"},
	[3] = {event = "Last Man Standing", map = "lastman"},
	[4] = {event = "Zombie", map = "zombie"},
}

function onStartup()
	
	for i = 1, #config do
		Game.loadMap('data/world/worldchanges/additionals/' .. config[i].map ..'.otbm')
		Game.sendConsoleMessage('>> ['..config[i].event..'] Map ' .. config[i].map .. ' loaded.', CONSOLEMESSAGE_TYPE_STARTUP)
	end
	return true
end