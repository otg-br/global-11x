local deeplings = {
	-- Tanjis, Obujos & Jaul
	[{"Monday", "Wednesday", "Saturday"}] = {teleportPosition = Position(33646, 31263, 11), toPosition = Position(33646, 31243, 11)}, 
	[{"Sunday", "Tuesday"}] = {teleportPosition = Position(33438, 31248, 11), toPosition = Position(33419, 31255, 11)},
	[{"Thursday", "Friday"}] = {teleportPosition = Position(33558, 31282, 11), toPosition = Position(33543, 31264, 11)}
}

function onStartup()
	for day, tab in pairs(deeplings) do
		for i = 1, #day do
			if day[i] == os.sdate("%A") then
				local teleport = Game.createItem(1387, 1, tab.teleportPosition)
				if teleport then
					teleport:setDestination(tab.toPosition)
				end
				return true
			end
		end
	end
end