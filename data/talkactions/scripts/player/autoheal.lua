local AutoHealingSystem = {
	Developer = "Davi (worthdavi)",
	Version = "0.1",
	LastUpdate = "0/0/0 - 00:0 (AM)"
}

AUTOHEAL_STORAGE_PERCENTAGE_HEALTH = 182730
AUTOHEAL_STORAGE_SAY = 182731
AUTOHEAL_STORAGE_PERCENTAGE_MANA = 182732
AUTOHEAL_STORAGE_ITEM_MANA = 182733

local options = {
	[1] = "Health",
	[2] = "Mana",
	[3] = "About"
}

function onSay(player, words, param)
	 player:registerEvent("ModalWindow_autoHeal")
	
	local title = "-- Auto Heal --"
	local message = "Choose an option below:"
	
	local window = ModalWindow(Modal.autoHealOptions, title, message)
	
	for i = 1, #options do
		window:addChoice(i, options[i])
	end
	
	window:addButton(100, 'Next')
	window:setDefaultEnterButton(100)
	window:addButton(101, 'Close')
	window:setDefaultEscapeButton(101)
	
	window:sendToPlayer(player)
end
