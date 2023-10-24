function onSay(player, word, param)
	if player:getGroup():getId() < 6 then
		return true
	end
	
	if player:getGroup():getId() < 6 then
		return true
	end

	local p = param:split(",")
	local target = Player(p[1])
	if not target then
		player:sendCancelMessage("Jogador com nome ".. p[1] .. ' não existe ou não está online')
		return false
	end

	local action = p[2]
	if not action then
		player:sendCancelMessage("Ação requer um parametro.")
		return false
	end

	local amount = tonumber(p[3])
	if not amount then
		player:sendCancelMessage("Ação requer um valor.")
		return false
	end

	if action:lower() == "add" then
		target:addCoinsBalance(amount, true)
	elseif action:lower() == "rem" then
		if not target:removeCoinsBalance(amount) then
			player:sendCancelMessage("Nao foi possivel remover coin do Jogador, saldo atual dele: ".. target:getCoinsBalance())
		end
	end

	return false
end