local options = {
	[1] = "My house",
	[2] = "Any city",
}

-- id das cidades
local cities = {1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12, 13, 14, 15, 20, 21, 23, 27}

local function sendModal(pid)
	local p = Player(pid)
	if not p then return true end
	p:registerEvent("modalWindow_teleportScroll")
	local title = "Choose an option below"
	local message = "Choose a city then you will be teleported there. :)"
	local window = ModalWindow(Modal.teleportScrollCities, title, message)
	window:addButton(100, "Okay")
	window:addButton(101, "Close")	
	for _, k in pairs(cities) do
		local town = Town(k)
		if town then
			window:addChoice(k, town:getName())
		end
	end
	window:setDefaultEnterButton(100)
	window:setDefaultEscapeButton(101)	
	window:sendToPlayer(p)
	return true
end

function onModalWindow(player, modalWindowId, buttonId, choiceId)
	player:unregisterEvent("modalWindow_teleportScroll")

	if modalWindowId == Modal.teleportScroll then
		if buttonId == 101 then
			return true
		elseif buttonId == 100 then		
			if choiceId == 1 then
				if player:getStorageValue(TEMPLE_TELEPORT_SCROLL) > os.stime() then
					player:sendCancelMessage("You are exhausted")
					return true
				end
				if not player:getHouse() then
					player:sendCancelMessage("You don't own a house.")
					return true
				else
					player:teleportTo(player:getHouse():getExitPosition())
					player:sendCancelMessage("You were teleported to your own house.")
				end
			elseif choiceId == 2 then
				sendModal(player:getId())
			end
		end
	elseif modalWindowId == Modal.teleportScrollCities then
		if buttonId == 101 then
			return true
		elseif buttonId == 100 then
			if choiceId then
				if player:getStorageValue(TEMPLE_TELEPORT_SCROLL) > os.stime() then
					player:sendCancelMessage("You are exhausted")
					return true
				end
				local destination = Town(choiceId)
				if not destination then return true end
				player:teleportTo(destination:getTemplePosition())
				player:sendCancelMessage("You were teleported to " .. destination:getName())
				player:setStorageValue(TEMPLE_TELEPORT_SCROLL, os.stime() + 5*60)
			end
		end
	end
end



