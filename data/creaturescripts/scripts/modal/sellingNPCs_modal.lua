local daysRashid = {
  [1] = {x = 32328, y = 31782, z = 6}, --Sunday // Domingo
  [2] = {x = 32207, y = 31155, z = 7}, --Monday // Lunes
  [3] = {x = 32300, y = 32837, z = 7}, --Tuesday // Martes
  [4] = {x = 32577, y = 32753, z = 7}, --Wednesday // Miercoles
  [5] = {x = 33066, y = 32879, z = 6}, --Thursday // Jueves
  [6] = {x = 33235, y = 32483, z = 7}, --Friday // Viernes
  [7] = {x = 33166, y = 31810, z = 6} --Saturday // Sabado	  
}

local options = {
	[1] = "Rashid",
	[2] = "Yasir",
	[3] = "Blue Djinns",
	[4] = "Green Djinns",
	[5] = "Esrik",
	[6] = "[VIP] Premium Plaza"
}

function onModalWindow(player, modalWindowId, buttonId, choiceId)		
	if modalWindowId == Modal.sellingNPCs then
		if buttonId == 101 then
			return true
		elseif buttonId == 100 then				
			if choiceId == 1 then
				local day = os.sdate("*t").wday
				for i = 1, #daysRashid do
					if daysRashid[day] then
						player:teleportTo(daysRashid[day])
						player:sendCancelMessage("You were teleported to Rashid.")
					end
				end
			elseif choiceId == 2 then
				local ankrahmun = false
				local carlin = false
				local liberty = false

				local positionAnkrahmun = Position(33102, 32884, 6)
				local checagemAnkrahmun = Game.getSpectators(positionAnkrahmun, false, false, 10, 10, 10, 10)
				for _, spectator in pairs(checagemAnkrahmun) do
				 	if spectator:getName() == "Yasir" then
				 		ankrahmun = true
				 	end
				end

				local positionCarlin = Position(32400, 31815, 6)
				local checagemCarlin = Game.getSpectators(positionCarlin, false, false, 10, 10, 10, 10)
				for _, spectator in pairs(checagemCarlin) do
					if spectator:getName() == "Yasir" then
						carlin = true
					end
				end

				local positionLiberty = Position(32314, 32895, 6)
				local checagemLiberty = Game.getSpectators(positionLiberty, false, false, 10, 10, 10, 10)
				for _, spectator in pairs(checagemLiberty) do
					if spectator:getName() == "Yasir" then
						liberty = true
					end
				end

				if liberty == true then
					player:teleportTo(positionLiberty)
				elseif carlin == true then
					player:teleportTo(positionCarlin)
				elseif ankrahmun == true then
					player:teleportTo(positionAnkrahmun)
				else
					player:sendCancelMessage("Yasir is not here today.")
					return true
				end
				player:sendCancelMessage("You were teleported to Yasir.")
			elseif choiceId == 3 then
				player:teleportTo(Position(33102, 32533, 6))
				player:sendCancelMessage("You were teleported to the djinn's tower.")
			elseif choiceId == 4 then
				player:teleportTo(Position(33047, 32621, 6))
				player:sendCancelMessage("You were teleported to the djinn's tower.")
			elseif choiceId == 5 then
				player:teleportTo(Position(33036, 31536, 10))
				player:sendCancelMessage("You were teleported to Esrik.")
			elseif choiceId == 6 then
				if player:getVipDays() > os.stime() then
					player:teleportTo(Position(31330, 32613, 7))
					player:sendCancelMessage("You were teleported to premium plaza.")
				else
					player:sendCancelMessage("You must be VIP.")
					return true
				end
			end
		end
		player:unregisterEvent("modalWindow_sellingNPCs")
		player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		return true
	end
	
end



