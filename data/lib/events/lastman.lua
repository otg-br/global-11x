if not TheLastMan then
	TheLastMan = {
		open = false,		
		channel_id = 12,			
		positionsArena = {
			fromPosition = Position(31446, 32816, 7),
			toPosition = Position(31475, 32840, 7),
			exitPosition = Position(31460, 32798, 7)
		},
		reward = {
			-- {itemid, quantity}
			{id = 15515, quantidade = 10},
		},
		blockMC = true,
		minLevel = 0,	
		minPlayers = 5, 
		maxPlayers = 30,
		players = {}, 
	}

	function TheLastMan:callExplosion(fromPosition, toPosition, interval)
		if self.open then
			addEvent(function()
				local x = math.random(fromPosition.x, toPosition.x)
				local y = math.random(fromPosition.y, toPosition.y)
				local z = math.random(fromPosition.z, toPosition.z)
				local newPos = Position(x, y, z)
				local item = Tile(newPos):getItemById(406)
				if item then
					item:transform(407)
					item:setActionId(4503)
					newPos:sendMagicEffect(CONST_ME_MORTAREA)
					self:callExplosion(fromPosition, toPosition, interval)
				else
					self:callExplosion(fromPosition, toPosition, 0.1)
					return true
				end
				local c = Tile(newPos):getTopCreature()
				if c and c:isPlayer() then
					self:onLeave(c, false)
				end
			end, interval*1000)
		else
			return false
		end
	end

	function TheLastMan:Open()
		if #self.players >= self.minPlayers then
			if self.open then 
				return false
			end
			local difficultTime
			local difficult = ""
			if #self.players < 5 then
				difficultTime = 0.1
				difficult = "fastest"
			elseif #self.players >= 5 and #self.players < 15 then
				difficultTime = 0.5
				difficult = "fast"
			elseif #self.players >= 15 then
				difficultTime = 1
				difficult = "normal"
			end
			self.open = true		
			broadcastMessage("[The Last Man Standing]\nO evento acabou de come�ar!\nDificuldade: "..difficult.."\nTempo de explos�o: "..difficultTime.." segundos")
			Game.openEventChannel("The Last Man Standing")
			self:callExplosion(self.positionsArena.fromPosition, self.positionsArena.toPosition, difficultTime)
			return true 
		else	
			broadcastMessage("A guerra n�o aconteceu por n�o haver a quantidade necess�ria de jogadores... :(")	
			for i = 1, #self.players do
				local p = Player(self.players[i])
				if p then
					self:onLeave(p, true)
				end
			end
			self.players = {}
			return false
		end
	end

	function TheLastMan:Close()
		if not self.open then
			return false 
		end
		self.open = false
		local function returnWinner()
			for i = 1, #self.players do
				local p = Player(self.players[i])
				if p and #self.players == 1 then
					table.remove(self.players, i)
					Game.sendConsoleMessage(">> [The Last Man Standing] Finalizado com sucesso. Quantidade de jogadores l dentro: " .. #self.players, CONSOLEMESSAGE_TYPE_INFO)
					return p:getId()
				end
			end
		end
		local player = Player(returnWinner())				
		if player then
			broadcastMessage(string.format("[The Last Man Standing] O jogador %s sobreviveu at� o final e ganhou o evento!", player:getName()))
		else
			broadcastMessage("[The Last Man Standing] - Erro Inesperado\nNingu�m ganhou o evento.")
		end
		for i = 1, #self.reward do
			local item = player:addItem(self.reward[i].id, self.reward[i].quantidade)
		end
		player:teleportTo(self.positionsArena.exitPosition)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Voc� ganhou o evento The Last Man Standing.")
		return true
	end

	function TheLastMan:onJoin(player)		
		local block = false
		if self.blockMC then
			for i = 1, #self.players do
				local p = Player(self.players[i])
				if p and p:getIp() == player:getIp() then
					player:sendCancelMessage('Seu IP � id�ntico ao do jogador '..p:getName()..', que j� est� dentro do evento.')
					block = true
				end
			end				
		end
		if #self.players >= self.maxPlayers then
			player:sendCancelMessage('Desculpe, j� existem ' .. self.maxPlayers .. ' jogadores dentro do evento.')
			block = true
		end
		if player:getLevel() < self.minLevel then
			player:sendCancelMessage('Voc� no possui level suficiente. Volte quando estiver level ' .. self.minLevel .. '.')
			block = true
		end	
		if not block then
			local r_x = math.random(self.positionsArena.fromPosition.x, self.positionsArena.toPosition.x)
			local r_y = math.random(self.positionsArena.fromPosition.y, self.positionsArena.toPosition.y)	
			local r_z = math.random(self.positionsArena.fromPosition.z, self.positionsArena.toPosition.z)	
			player:teleportTo(Position(r_x, r_y, r_z))
			table.insert(self.players, player:getId())
			player:openChannel(self.channel_id)
			Game.sendEventMessage(string.format("%s entrou na disputa! Jogadores dentro da arena: %d", player:getName(), #self.players))			
			return true
		end
	end

	function TheLastMan:onLeave(player, isCanceling)
		if not isCanceling then
			for i = 1, #self.players do
				local p = Player(self.players[i])
				if p and p:getName() == player:getName() then
					table.remove(self.players, i)
				end
			end
			Game.sendEventMessage("O jogador "..player:getName().." deu azar e foi pego em uma explos�o.")
			if #self.players == 1 then
				self:Close()
			end
		end
		player:teleportTo(self.positionsArena.exitPosition)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Voc� foi removido do evento.")
		return true
	end
end