if not Battlefield_x2 then
	Battlefield_x2 = {
		open = false,
		
		idChannelEvent = 12,
		
		wall = {
			id = 22578,

			top = Position(31551, 32895, 4), 
			bottom = Position(31551, 32899, 4)
		},

		bordasArena = {
			fromPosition = Position(31516, 32883, 6),
			toPosition = Position(31586, 32908, 6)
		},
		
		itensBloqueados = {
			[1] = {id = 2197}, -- ssa,
			[2] = {id = 2164}, -- might ring
		},

		rewardsTimeLimit = {
			-- {itemid, quantity}
			{id = 15515, quantidade = 5},
			{id = 7369, quantidade = 1, ehTrofeu = true},
		},
		
		rewardDefault = {
			-- {itemid, quantity}
			{id = 15515, quantidade = 10},
			{id = 7369, quantidade = 1, ehTrofeu = true},
			
		},

		expReward = 20000, -- 200K * players alive = exp

		minLevel = 50, -- min level
		blockMC = false, -- turn into true if you want to block MC users
		playerCount = 0, -- don't change!!
		minPlayers = 8, -- min quatity/2
		maxPlayers = 50, -- max quantity/2


		teams = {
			[1] = {
				name = 'Alliance',

				outfit = {
					lookType =  152, 
					lookAddons = 3, 
					lookHead = 90, 
					lookBody = 90, 
					lookLegs = 90, 
					lookFeet = 90,
				},

				position = Position(31535, 32903, 6),  -- Posi��o do time 

				players = {}, 
				kills = 0,
				size = 0,
				vidaExtra = 0,
			},
			[2] = {
				name = 'Horde',

				outfit = {
					lookType = 152,
					lookAddons = 3,
					lookHead = 94,
					lookLegs = 94,
					lookBody = 94,
					lookFeet = 94,
				},

				position = Position(31566, 32903, 6),
				
				players = {}, 
				kills = 0,
				size = 0,
				vidaExtra = 0,
			},				
		}
	}

	function Battlefield_x2:Open()
		if self.playerCount >= self.minPlayers then
			if self.open then 
				return false -- O evento j� estava aberto, ent�o n�o inicia
			end
			for y = self.wall.top.y, self.wall.bottom.y do
				local tile = Tile({x = self.wall.top.x, y = y, z = self.wall.top.z})
				if tile then
					local wall = tile:getItemById(self.wall.id)
					if wall then
						wall:remove()
					end
				end
			end 		
			self.open = true
			Game.openEventChannel("Battlefield")
			broadcastMessage("A guerra come�ou! Boa sorte a todos, e que ven�a o melhor! :)")
			if self.teams[1].size > self.teams[2].size then
				Game.sendEventMessage(string.format("Por haver mais jogadores dentro da equipe %s, a equipe %s ir� ganhar uma vida extra.", self.teams[1].name, self.teams[2].name))
				self.teams[2].vidaExtra = 1
			elseif self.teams[1].size < self.teams[2].size then
				Game.sendEventMessage(string.format("Por haver mais jogadores dentro da equipe %s, a equipe %s ir� ganhar uma vida extra.", self.teams[2].name, self.teams[1].name))
				self.teams[1].vidaExtra = 1
			else
				Game.sendEventMessage("O jogo est� equilibrado! Nenhuma equipe ir� precisar de vida extra! :).")
			end
			local fromPos = self.bordasArena.fromPosition
			local toPos = self.bordasArena.toPosition
			for x = fromPos.x, toPos.x do
				for y = fromPos.y, toPos.y do
					for z = fromPos.z, toPos.z do
						local tile = Tile(Position(x, y, z))
						if tile then
							local c = tile:getTopCreature()
							if c and c:isPlayer() then
								c:teleportTo(Position(c:getPosition().x, c:getPosition().y, c:getPosition().z - 1))
							end
						end
					end
				end
			end
			return true -- Evento come�ou
		else	
			broadcastMessage("A guerra n�o aconteceu por n�o haver a quantidade necess�ria de jogadores... :(")	
			for _, team in ipairs(self.teams) do
				for name, info in pairs(team.players) do
					local player = Player(name)
					if player then
						self:cancelEvent(player)
					end
				end
			end	
			for i = 1, #self.teams do
				self.teams[i].players = {}
				self.teams[i].size = 0
				self.teams[i].kills = 0
				self.teams[i].vidaExtra = 0
			end
			return false -- Evento n�o come�ou
		end
	end

	function Battlefield_x2:cancelEvent(player)
		local info = self:findPlayer(player)
		if not info then -- Se n�o encontrou jogador l� dentro
			return false 
		end
		player:unregisterEvent("Battlefield_HealthChange_x2")
		player:unregisterEvent("Battlefield_PrepareDeath_x2")
		player:unregisterEvent("Battlefield_ManaChange_x2")
		player:unregisterEvent("Battlefield_Logout_x2")
		
		-- Teleportar para o templo e zerar os times
		player:teleportTo(player:getTown():getTemplePosition())
		self.teams[info.team].size = self.teams[info.team].size - 1
		self.teams[info.team].players[info.name] = nil
		
		player:setStorageValue(STORAGE_BATTLEFIELD, - 1)
		
		-- Encher HP/Mana e conditions
		player:addHealth(player:getMaxHealth())
		player:addMana(player:getMaxMana())
		player:removeCondition(CONDITION_INFIGHT)
		player:removeCondition(CONDITION_OUTFIT)
		return true
	end

	function Battlefield_x2:Close(winner)
		if not self.open then -- O evento n�o estava aberto, ent�o n�o tem o que fechar
			return false 
		end
		
		self.open = false
		local tempoLimite = false
		local expNova
		
		-- Recriando a barreira
		for y = self.wall.top.y, self.wall.bottom.y do
			Game.createItem(self.wall.id, 1, Position(self.wall.top.x, y, self.wall.top.z))
		end

		if not winner then
			if self.teams[1].kills > self.teams[2].kills then
				winner = 1
			elseif self.teams[1].kills < self.teams[2].kills then
				winner = 2
			end
			tempoLimite = true
		end
		
		local recompensa = {}
		if not tempoLimite then
			recompensa = self.rewardDefault
		else
			recompensa = self.rewardsTimeLimit
		end

		if winner then
			expNova = (self.expReward)*self.teams[winner].size
			if not tempoLimite then
				broadcastMessage(string.format("[Battlefield] A equipe %s ganhou o evento Battlefield derrotando todo o time inimigo!", self.teams[winner].name))
			else
				broadcastMessage(string.format("[Battlefield] A equipe %s ganhou o evento Battlefield por possuir mais jogadores ao final do tempo!", self.teams[winner].name))
			end
		else
			broadcastMessage("[Battlefield] Houve um empate e ningu�m ganhou a recompensa.")
		end
		

		-- Entregando as recompensas
		for _, team in ipairs(self.teams) do
			for name, info in pairs(team.players) do
				local player = Player(name)
				if player then
					self:cancelEvent(player)
					if _ == winner then
						for k, item in ipairs(recompensa) do
							local reward
							if item.ehTrofeu == true then
								local data = os.sdate("%d/%m/%Y")
								reward = player:addItem(item.id, item.quantidade)
								if reward then
									reward:setAttribute(ITEM_ATTRIBUTE_DESCRIPTION, "Evento Battlefield - " .. data .. " - " .. player:getName() .. " - " .. team.name .. ".")
								end
							else
								reward = player:addItem(item.id, item.quantidade)
							end
						end
					end
					if not tempoLimite then
						player:addExperience(expNova, true)
					end
				end
			end
		end	
		return true
	end

	function Battlefield_x2:findPlayer(player)
		local name = player:getName()
		return self.teams[1].players[name] or self.teams[2].players[name]
	end
	
	function Battlefield_x2:onJoin(player)
		local Alliance = 
			createConditionObject(CONDITION_OUTFIT)
			setConditionParam(Alliance, CONDITION_PARAM_TICKS, - 1)
			addOutfitCondition(Alliance, {lookType = self.teams[1].outfit.lookType, lookAddons = self.teams[1].outfit.lookAddons,
			lookHead = self.teams[1].outfit.lookHead, lookBody = self.teams[1].outfit.lookBody, lookLegs = self.teams[1].outfit.lookLegs,
			lookFeet = self.teams[1].outfit.lookFeet})
			
		local Horde = createConditionObject(CONDITION_OUTFIT)
			setConditionParam(Horde, CONDITION_PARAM_TICKS, - 1)
			addOutfitCondition(Horde, {lookType = self.teams[2].outfit.lookType, lookAddons = self.teams[2].outfit.lookAddons,
			lookHead = self.teams[2].outfit.lookHead, lookBody = self.teams[2].outfit.lookBody, lookLegs = self.teams[2].outfit.lookLegs,
			lookFeet = self.teams[2].outfit.lookFeet})
		
		local block = false
		
		for _, item in pairs(self.itensBloqueados) do
			local id = item.id
			if player:getItemCount(id) >= 1 then
				player:sendCancelMessage('Desculpe, n�o � permitido entrar com ' .. ItemType(id):getName() .. ' no evento Battlefield.')
				block = true
			end
		end
		if self.playerCount >= self.maxPlayers then
			player:sendCancelMessage('Desculpe, j� existem ' .. self.maxPlayers .. ' jogadores dentro do evento Battlefield.')
			block = true
		end
		if player:getLevel() < self.minLevel then
			player:sendCancelMessage('Voc� n�o possui level suficiente. Volte quando estiver level ' .. self.minLevel .. '.')
			block = true
		end
		if self.blockMC then
    		for i = 1, #self.teams do
    		    for j = 1, #self.teams[i].players do
    		        local nextPlayer = Player(self.teams[i].players[j].name)
    		        if nextPlayer and player:getIp() == nextPlayer:getIp() then
    		            player:sendCancelMessage('Seu IP � id�ntico ao do jogador '..nextPlayer:getName()..', que j� est� dentro do evento.')
					    block = true
					end
                end	
		    end
	    end
		if not block then		
			local team
			if self.teams[1].size == self.teams[2].size then
				team = math.random(1, 2)
			elseif self.teams[1].size > self.teams[2].size then
				team = 2
			else
				team = 1
			end
				
			if team == 1 then
				doAddCondition(player, Alliance)
				player:teleportTo(self.teams[team].position)
			else
				doAddCondition(player, Horde)
				player:teleportTo(self.teams[team].position)
			end
			
			player:setStorageValue(STORAGE_BATTLEFIELD, 1)
				
			local info = {name = player:getName(), team = team}
			self.teams[team].size = self.teams[team].size + 1
			self.teams[team].players[player:getName()] = info
			self.playerCount = self.playerCount + 1

			player:openChannel(self.idChannelEvent)
			Game.sendEventMessage(string.format("%s entrou na batalha pela equipe %s!", info.name, self.teams[team].name))
			Game.sendEventMessage(string.format("Jogadores na equipe %s: %s || Jogadores na equipe %s: %s", self.teams[1].name, self.teams[1].size, self.teams[2].name, self.teams[2].size))
			
			player:registerEvent("Battlefield_PrepareDeath_x2")
			player:registerEvent("Battlefield_HealthChange_x2")
			player:registerEvent("Battlefield_ManaChange_x2")
			player:registerEvent("Battlefield_Logout_x2")
			return true -- Entrou no evento!
		end
	end

	function Battlefield_x2:onLeave(player)
		local info = self:findPlayer(player)
		if not info then -- Se n�o encontrou jogador l� dentro
			return false 
		end
		
		player:unregisterEvent("Battlefield_HealthChange_x2")
		player:unregisterEvent("Battlefield_PrepareDeath_x2")
		player:unregisterEvent("Battlefield_ManaChange_x2")
		player:unregisterEvent("Battlefield_Logout_x2")
		player:setStorageValue(STORAGE_BATTLEFIELD, - 1)

		player:teleportTo(player:getTown():getTemplePosition())
		self.teams[info.team].size = self.teams[info.team].size - 1
		self.teams[info.team].players[info.name] = nil
		
		-- Enchendo HP e MANA (importante)
		player:addHealth(player:getMaxHealth())
		player:addMana(player:getMaxMana())
		
		player:removeCondition(CONDITION_INFIGHT)
		player:removeCondition(CONDITION_OUTFIT)

		if self.teams[info.team].size == 0 then
			self:Close(info.team == 1 and 2 or 1)			
		end
		
		return true
	end

	function Battlefield_x2:onDeath(player, killer)
		local info = self:findPlayer(player)
		if not info then 
			return false 
		end
		if killer and killer.getName then
			local killerInfo = self:findPlayer(killer)
			if killerInfo and killerInfo.team ~= info.team then
				local killerTeam = self.teams[killerInfo.team]
				killerTeam.kills = killerTeam.kills + 1
				if self.teams[info.team].vidaExtra == 1 then
					Game.sendEventMessage(string.format("%s foi morto por %s no evento Battlefield! Devido ao seu time possuir uma vida extra, o jogador foi movido ao in?cio da arena.", player:getName(), killer:getName()))
				else
					Game.sendEventMessage(string.format("%s foi morto por %s no evento Battlefield!", player:getName(), killer:getName()))
				end
			end
		end
		if self.teams[info.team].vidaExtra == 1 then
			player:teleportTo(self.teams[info.team].position)
			player:addHealth(player:getMaxHealth())
			player:addMana(player:getMaxMana())
			self.teams[info.team].vidaExtra = 0
		else
			self:onLeave(player)
		end
		return true
	end
end
