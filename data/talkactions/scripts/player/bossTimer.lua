local options = {
	[1] = "Heart of Destruction",
	[2] = "The Secret Library",
	[3] = "Warzone (all)",
	[4] = "Cults of Tibia",
	[5] = "The First Dragon",
	[6] = "Threatened Dreams",
	[7] = "The Dream Courts"
}

function onSay(cid, words, param)
	local player = Player(cid)
	if player then
		player:registerEvent("ModalWindow_bossTimer")
	 
		local title = "-- Choose a quest --"
		local message = "Which quest do you want to see it's bosses?"
	 
		local window = ModalWindow(Modal.bossTimer, title, message)
		
		for i = 1, #options do
			window:addChoice(i, options[i])
		end
		
		window:addButton(100, 'Okay')
		window:setDefaultEnterButton(100)
		window:addButton(101, 'Close')
		window:setDefaultEscapeButton(101)
	 
		window:sendToPlayer(player)
	end
    return false
end
