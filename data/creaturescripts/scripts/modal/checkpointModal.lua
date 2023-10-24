local lastUpdate = "29/08/2019\nMade by @worthdavi"

-- positions é uma storage
local positions = {
	[1] = {position = 'Position 1', storage = 62170},
	[2] = {position = 'Position 2', storage = 62171},
	[3] = {position = 'Position 3', storage = 62172},
	[4] = {position = 'Position 4', storage = 62173},
	[5] = {position = 'Position 5', storage = 62174},
}

--[[
	modal main: 7000
	modal checkpoints: 7001
	modal info: 7002
]]

function onModalWindow(player, modalWindowId, buttonId, choiceId)

	if modalWindowId == 7000 and buttonId == 100 and choiceId == 1 then
		player:unregisterEvent("checkpointModal")
		local title = "-- Choose a position --"
		local desc = "Choose the position that you want to save"
		local window = ModalWindow(7001, title, desc)
		for i = 1, #positions do
			local text = positions[i].position
			if player:getStorageValue(positions[i].storage) < 1 then
				text = text .. " (disponible)"
			end
			window:addChoice(i, text)
		end
		window:addButton(110, 'Next')
		window:setDefaultEnterButton(110)
		window:addButton(111, 'Back')
		window:setDefaultEscapeButton(111)
		window:sendToPlayer(player)
		return true
	-- elseif modalWindowId == Modal.autoHealHealthOptions and buttonId == 110 and choiceId == 1 then
	-- 	player:unregisterEvent("autoHeal_modal")
	-- 	local title = "Healing Spells"
	-- 	local desc = "Choose a spell to heal yourself"
	-- 	local window = ModalWindow(Modal.autoHealSpellList, title, desc)
	-- 	if isInArray({1, 5}, vNumber) then
	-- 		for w, spell in pairs(spellTable.Sorcerer) do
	-- 			window:addChoice(spell.id, w)
	-- 		end
	-- 	elseif isInArray({2, 6}, vNumber) then
	-- 		for w, spell in pairs(spellTable.Druid) do
	-- 			window:addChoice(spell.id, w)
	-- 		end
	-- 	elseif isInArray({3, 7}, vNumber) then
	-- 		for w, spell in pairs(spellTable.Knight) do
	-- 			window:addChoice(spell.id, w)
	-- 		end
	-- 	elseif isInArray({4, 8}, vNumber) then
	-- 		for w, spell in pairs(spellTable.Paladin) do
	-- 			window:addChoice(spell.id, w)
	-- 		end
	-- 	else
	-- 		player:sendCancelMessage('You don\'t have any healing spell.')
	-- 		return true
	-- 	end
	-- 	choiceCount = window:getChoiceCount()
	-- 	window:addButton(110, 'Next')
	-- 	window:setDefaultEnterButton(110)
	-- 	window:addButton(111, 'Back')
	-- 	window:setDefaultEscapeButton(111)
	-- 	window:sendToPlayer(player)
	-- 	return true
	-- elseif modalWindowId == Modal.autoHealSpellList and buttonId == 110 then
		
	end
	return true
end