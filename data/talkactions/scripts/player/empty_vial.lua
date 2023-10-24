local segundos = 10 

function onSay(player, words, param)
	if param == "on" then
		if player:getExhaustion(Storage.emptyVials.exhaust) <= 0 then
			if player:getStorageValue(Storage.emptyVials.emptyVial) == 1 then
			player:sendCancelMessage("This function is already enabled.")
			else
		    player:setStorageValue(Storage.emptyVials.emptyVial, 1)
		    player:setExhaustion(Storage.emptyVials.exhaust, segundos)
			player:sendCancelMessage("You have enabled the flask remover feature.")
			end
		else
		player:sendCancelMessage("You're exausted. Wait " .. player:getExhaustion(Storage.emptyVials.exhaust) .. " seconds.")
		end
	elseif param == "off" then
		if player:getExhaustion(Storage.emptyVials.exhaust) <= 0 then
			if player:getStorageValue(Storage.emptyVials.emptyVial) == 0 then
			player:sendCancelMessage("This function is already disabled.")
			else
		    player:setStorageValue(Storage.emptyVials.emptyVial, 0)
		    player:setExhaustion(Storage.emptyVials.exhaust, segundos)
			player:sendCancelMessage("You have disabled the flask remover  feature.")
			end
		else
		player:sendCancelMessage("You're exausted. Wait " .. player:getExhaustion(Storage.emptyVials.exhaust) .. " seconds.")
		end
	elseif param == "" then
	player:sendCancelMessage("Error: this command requires a parameter. Try 'on' or 'off'.")
	end
	
	return false
end
