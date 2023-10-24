local transformid = {
	[30735] = 30737,
}

-- Gambiarra pra não ter que mudar o actionid, remover depois.
local hiddenFeathers = {
	{position = Position(33526, 32256, 7)},
	{position = Position(33494, 32318, 7)},
	{position = Position(33459, 32293, 7)},
	{position = Position(33470, 32251, 7)},
	{position = Position(33464, 32230, 7)},
	{position = Position(33499, 32193, 7)},
	{position = Position(33550, 32222, 7)},
	{position = Position(33589, 32196, 7)},
}

function onUse(player, item)
	if not player then
		return true
	end
	
	-- Gambiarra pra não ter que mudar o actionid, remover depois.
	for _, k in pairs(hiddenFeathers) do
		if item:getPosition() == k.position then
			return true
		end
	end

	local positionItem = item:getPosition()

	if item:getActionId() == 57300 then -- Warzone VI
		local spectators = Game.getSpectators(positionItem, false, true, 5, 5, 5, 5)
		for _, spectator in pairs(spectators) do
			if spectator:isPlayer() then
				local jogador = spectator
				if jogador:getStorageValue(Storage.DangerousDepths.Acessos.LavaPumpWarzoneVI) < 1 then
					jogador:setStorageValue(Storage.DangerousDepths.Acessos.LavaPumpWarzoneVI, 1)
				end
			end
		end
		player:say("With the pump destroyed, the lava stream has been stopped. Zone VI is acessible now!", TALKTYPE_MONSTER_SAY, false, false, positionItem)
		item:transform(transformid[item:getId()])
		addEvent(function()
			if item then
				item:transform(30735)
			end
		end, 10 * 60 * 1000) -- 10 minutos para o item voltar ao normal.
	end
	if item:getActionId() == 57302 then -- Warzone V
		local spectators = Game.getSpectators(positionItem, false, true, 5, 5, 5, 5)
		for _, spectator in pairs(spectators) do
			if spectator:isPlayer() then
				local jogador = spectator
				if jogador:getStorageValue(Storage.DangerousDepths.Acessos.LavaPumpWarzoneV) < 1 then
					jogador:setStorageValue(Storage.DangerousDepths.Acessos.LavaPumpWarzoneV, 1)
				end
			end
		end
		player:say("With the pump destroyed, the lava stream has been stopped. Zone V is acessible now!", TALKTYPE_MONSTER_SAY, false, false, positionItem)
		item:transform(transformid[item:getId()])
		addEvent(function()
			if item then
				item:transform(30735)
			end
		end, 10 * 60 * 1000) -- 10 minutos para o item voltar ao normal.
	end
	if item:getActionId() == 57301 then -- Warzone IV
		local spectators = Game.getSpectators(positionItem, false, true, 5, 5, 5, 5)
		for _, spectator in pairs(spectators) do
			if spectator:isPlayer() then
				local jogador = spectator
				if jogador:getStorageValue(Storage.DangerousDepths.Acessos.LavaPumpWarzoneIV) < 1 then
					jogador:setStorageValue(Storage.DangerousDepths.Acessos.LavaPumpWarzoneIV, 1)
				end
			end
		end
		player:say("With the pump destroyed, the lava stream has been stopped. Zone IV is acessible now!", TALKTYPE_MONSTER_SAY, false, false, positionItem)
		item:transform(transformid[item:getId()])
		addEvent(function()
			if item then
				item:transform(30735)
			end
		end, 10 * 60 * 1000) -- 10 minutos para o item voltar ao normal.
	end
	return true
end
