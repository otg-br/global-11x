function onCastSpell(cid, var)
	local hasCasted = Game.getStorageValue(GlobalStorage.DreamCourts.DreamScar.lastBossCurse)
	if hasCasted == 0 then
		local players = Game.getSpectators(cid:getPosition(), false, true, 14, 14, 14, 14)
		local randomNumber = math.random(1, #players)
		for _, k in pairs(players) do
			local player = Player(k)
			if player then
				player:setStorageValue(Storage.DreamCourts.DreamScar.lastBossCurse, - 1) 
				-- Storage que checa se o jogador já esteve com o curse
			end
		end
		local newPlayer = Player(players[randomNumber]:getId())		
		newPlayer:registerEvent('nightmareCurse')
		newPlayer:setStorageValue('nightmareCurse', 1)
		newPlayer:setStorageValue(Storage.DreamCourts.DreamScar.lastBossCurse, 1)
		newPlayer:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The beast laid a terrible curse on you!")
		Game.setStorageValue(GlobalStorage.DreamCourts.DreamScar.lastBossCurse, 1)
	end
end
