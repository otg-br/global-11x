local options = {
	[1] = "Rashid",
	[2] = "Yasir",
	[3] = "Blue Djinns",
	[4] = "Green Djinns",
	[5] = "Esrik",
	[6] = "[VIP] Premium Plaza"
}

function onStepIn(player, item, position, fromPosition)
	if not player:isPlayer() then
		return false
	end	
	if player then
		player:registerEvent("modalWindow_sellingNPCs")
		
		local title = "Wich NPC do you want to visit?"
		local message = "Choose the NPC that you want to visit and you will be teleported!"

		local window = ModalWindow(Modal.sellingNPCs, title, message)

		window:addButton(100, "Okay")
		window:addButton(101, "Close")
		
		for i = 1, #options do
			window:addChoice(i, options[i])
		end

		window:setDefaultEnterButton(100)
		window:setDefaultEscapeButton(101)

		player:teleportTo(fromPosition, true)
		player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		
		window:sendToPlayer(player)
		player:say("Select the option to teleport then *click* on \"okay\"!!", TALKTYPE_MONSTER_SAY)
	end
	return true
end



