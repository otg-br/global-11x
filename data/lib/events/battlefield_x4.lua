local function getLowSize(tb)
	local temp = {}
	for i = 1, #tb do
	  temp[i] = {team = i, size = tb[i].size}
	end
	local real, maxv = {}, 0
	for _, pid in pairs(temp) do
	  if pid.size > maxv then
		maxv = pid.size
	  end
	end
	for i = 1, #temp do
	  if temp[i].size < maxv then
		real[#real + 1] = {team = temp[i].team, size = temp[i].size}
	  end
	end
	table.sort(real, function(a, b) return a.size < b.size end)
	return real
end

if not Battlefield_x4 then
	Battlefield_x4 = {
		open = false,		
		idChannelEvent = 12,
		
		wall = {
			id = 1498, -- mw (not decaying)
			fromPos = Position(31522, 32782, 4), 
			toPos = Position(31528, 32788, 4)
		},
		renew = {},
		bordasArena = {
			fromPosition = Position(31486, 32756, 6),
			toPosition = Position(31561, 32820, 6)
		},		
		itensBloqueados = {
			[1] = {id = 2197}, -- ssa,
			[2] = {id = 2164}, -- might ring
		},
		rewardsTimeLimit = {
			-- {itemid, quantity}
			{id = 2160, quantidade = 5},
			{id = 7369, quantidade = 1, ehTrofeu = true},
		},		
		rewardDefault = {
			-- {itemid, quantity}
			{id = 2160, quantidade = 15},
			{id = 7369, quantidade = 1, ehTrofeu = true},
			{id = 8982, quantidade = 1},
		},	

		expReward = 200000, -- 200K * qnt de jogadores vivos!
		minLevel = 150,
		blockMC = false, -- turn into true if you want to block MC users
		playerCount = 0, -- N�o alterar!!
		minPlayers = 40, -- Quantidade necess�ria para o evento iniciar 10/10/10/10
		maxPlayers = 120, -- Quantidade m�xima de players dentro do evento 30/30/30/30

		teams = {
			[1] = {
				name = 'Fire',
				outfit = {
					lookType =  152, 
					lookAddons = 3, 
					lookHead = 90, 
					lookBody = 90, 
					lookLegs = 90, 
					lookFeet = 90,
				},
				position = Position(31507, 32785, 6),  -- Posi��o do time 

				players = {}, 
				kills = 0,
				size = 0,
				vidaExtra = 0,
			},
			[2] = {
				name = 'Water',
				outfit = {
					lookType = 152,
					lookAddons = 3,
					lookHead = 94,
					lookLegs = 94,
					lookBody = 94,
					lookFeet = 94,
				},
				position = Position(31542, 32785, 6),
				
				players = {}, 
				kills = 0,
				size = 0,
				vidaExtra = 0,
			},
			[3] = {
				name = 'Wind',
				outfit = {
					lookType = 152,
					lookAddons = 3,
					lookHead = 10,
					lookLegs = 32,
					lookBody = 53,
					lookFeet = 7,
				},
				position = Position(31525, 32770, 6),
				
				players = {}, 
				kills = 0,
				size = 0,
				vidaExtra = 0,
			},	
			[4] = {
				name = 'Earth',
				outfit = {
					lookType = 152,
					lookAddons = 3,
					lookHead = 12,
					lookLegs = 32,
					lookBody = 17,
					lookFeet = 98,
				},
				position = Position(31525, 32800, 6),
				
				players = {}, 
				kills = 0,
				size = 0,
				vidaExtra = 0,
			}	
		}
	}

	function Battlefield_x4:Open()
		if self.playerCount >= self.minPlayers then
			if self.open then 
				return false -- O evento j� estava aberto, ent�o n�o inicia
			end
			for x = self.wall.fromPos.x, self.wall.toPos.x do
				for y = self.wall.fromPos.y, self.wall.toPos.y do
					for z = self.wall.fromPos.z, self.wall.toPos.z do
						local newPos = Position(x, y, z)
						local wallToRemove = Tile(newPos):getItemById(self.wall.id)
						if wallToRemove then
							table.insert(newPos, self.renew)
							wallToRemove:remove()
						end
					end
				end
			end
			--
			self.open = true
			Game.sendEventMessage("A guerra come�ou! Boa sorte a todos, e que ven�a o melhor! :)")
			local sameTeams = true
			local n = getLowSize(self.teams)
			for i = 1, #self.teams do
				if self.teams[i].size == n[i].size then
					self.teams[i].vidaExtra = 1
					Game.sendEventMessage(string.format("Por haver menos jogadores dentro da equipe %s, a mesma ir� ganhar uma vida extra.", self.teams[i].name))
					sameTeams = false
				end
			end
			if sameTeams then
				Game.sendEventMessage("O jogo est� equilibrado! Nenhuma equipe ir� precisar de vida extra! :).")
			end
			--
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
			Game.sendEventMessage("A guerra n�o aconteceu por n�o haver a quantidade necess�ria de jogadores... :(")	
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

	function Battlefield_x4:cancelEvent(player)
		local info = self:findPlayer(player)
		if not info then -- Se n�o encontrou jogador l� dentro
			return false 
		end
		player:unregisterEvent("Battlefield_HealthChange_x4")
		player:unregisterEvent("Battlefield_PrepareDeath_x4")
		player:unregisterEvent("Battlefield_ManaChange_x4")
		player:unregisterEvent("Battlefield_Logout_x4")
		
		player:setStorageValue(STORAGE_BATTLEFIELD, - 1)
		
		-- Teleportar para o templo e zerar os times
		player:teleportTo(player:getTown():getTemplePosition())
		self.teams[info.team].size = self.teams[info.team].size - 1
		self.teams[info.team].players[info.name] = nil
		
		-- Encher HP/Mana e conditions
		player:addHealth(player:getMaxHealth())
		player:addMana(player:getMaxMana())
		player:removeCondition(CONDITION_INFIGHT)
		player:removeCondition(CONDITION_OUTFIT)
		return true
	end

	function Battlefield_x4:Close(winner)
		if not self.open then -- O evento n�o estava aberto, ent�o n�o tem o que fechar
			return false 
		end
		
		self.open = false
		local tempoLimite = false
		
		-- Recriando a barreira
		for i = 1, #self.renew do
			Game.createItem(self.wall.id, 1, self.renew[i])
		end

		if not winner then
			local maior = 0
			local winner 
			for i = 1, #self.teams do
				if self.teams[i].kills > maior then
					maior = self.teams[i].kills
					winner = i
				end
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
			if not tempoLimite then
				broadcastMessage(string.format("[Battlefield 2.0] A equipe %s ganhou o evento Battlefield derrotando todo o time inimigo!", self.teams[winner].name))
			else
				broadcastMessage(string.format("[Battlefield 2.0] A equipe %s ganhou o evento Battlefield por possuir mais jogadores ao final do tempo!", self.teams[winner].name))
			end
			local expNova = (self.expReward)*self.teams[winner].size
			for i = 1, #self.teams[winner].players do
				local player = Player(self.teams[winner].players[i].name)
				local goblet
				if player then
					self:cancelEvent(player)
					player:addExperience(expNova, true)
					for _, item in pairs(recompensa) do
						if not item.ehTrofeu then
							player:addItem(item.id, item.quantidade)
						else
							local data = os.sdate("%d/%m/%Y")
							goblet = player:addItem(item.id, item.quantidade)
							if goblet then
								goblet:setAttribute(ITEM_ATTRIBUTE_DESCRIPTION, "Evento Battlefield - " .. data .. " - " .. player:getName() .. " - " .. team.name .. ".")
							end
						end
					end				
				end
			end						
		else
			broadcastMessage("[Battlefield 2.0] Houve um empate e ningu�m ganhou a recompensa.")
			for i = 1, #self.teams do
				for j = 1, #self.teams[i].players do
					local pName = self.teams[i].players[j].name
					local player = Player(pName)
					if player then
						self:cancelEvent(player)
					end
				end
			end
		end
		return true
	end

	function Battlefield_x4:findPlayer(player)
		local name = player:getName()
		return self.teams[1].players[name] or self.teams[2].players[name] or self.teams[3].players[name] or self.teams[4].players[name]
	end
	
	function Battlefield_x4:onJoin(player)
		local FIRE = 
			createConditionObject(CONDITION_OUTFIT)
			setConditionParam(FIRE, CONDITION_PARAM_TICKS, - 1)
			addOutfitCondition(FIRE, {lookType = self.teams[1].outfit.lookType, lookAddons = self.teams[1].outfit.lookAddons,
			lookHead = self.teams[1].outfit.lookHead, lookBody = self.teams[1].outfit.lookBody, lookLegs = self.teams[1].outfit.lookLegs,
			lookFeet = self.teams[1].outfit.lookFeet})
			
		local WATER = createConditionObject(CONDITION_OUTFIT)
			setConditionParam(WATER, CONDITION_PARAM_TICKS, - 1)
			addOutfitCondition(WATER, {lookType = self.teams[2].outfit.lookType, lookAddons = self.teams[2].outfit.lookAddons,
			lookHead = self.teams[2].outfit.lookHead, lookBody = self.teams[2].outfit.lookBody, lookLegs = self.teams[2].outfit.lookLegs,
			lookFeet = self.teams[2].outfit.lookFeet})

		local WIND = createConditionObject(CONDITION_OUTFIT)
			setConditionParam(WIND, CONDITION_PARAM_TICKS, - 1)
			addOutfitCondition(WIND, {lookType = self.teams[3].outfit.lookType, lookAddons = self.teams[3].outfit.lookAddons,
			lookHead = self.teams[3].outfit.lookHead, lookBody = self.teams[3].outfit.lookBody, lookLegs = self.teams[3].outfit.lookLegs,
			lookFeet = self.teams[3].outfit.lookFeet})
	
		local EARTH = createConditionObject(CONDITION_OUTFIT)
			setConditionParam(EARTH, CONDITION_PARAM_TICKS, - 1)
			addOutfitCondition(EARTH, {lookType = self.teams[4].outfit.lookType, lookAddons = self.teams[4].outfit.lookAddons,
			lookHead = self.teams[4].outfit.lookHead, lookBody = self.teams[4].outfit.lookBody, lookLegs = self.teams[4].outfit.lookLegs,
			lookFeet = self.teams[4].outfit.lookFeet})
		
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
			local sizeTable = {self.teams[1].size, self.teams[2].size, self.teams[3].size, self.teams[4].size}
			local min = math.min(unpack(sizeTable))
			local team
			for i = 1, #self.teams do
				if self.teams[i].size == min then
					team = i
					break
				end
			end
			if team == 1 then
				doAddCondition(player, FIRE)
				player:teleportTo(self.teams[team].position)
			elseif team == 2 then
				doAddCondition(player, WATER)
				player:teleportTo(self.teams[team].position)
			elseif team == 3 then
				doAddCondition(player, WIND)
				player:teleportTo(self.teams[team].position)
			elseif team == 4 then
				doAddCondition(player, EARTH)
				player:teleportTo(self.teams[team].position)
			else
				-- ?
			end
				
			local info = {name = player:getName(), team = team}
			self.teams[team].size = self.teams[team].size + 1
			self.teams[team].players[player:getName()] = info
			self.playerCount = self.playerCount + 1
			
			player:setStorageValue(STORAGE_BATTLEFIELD, 1)

			player:openChannel(self.idChannelEvent)
			Game.sendEventMessage(string.format("%s entrou na batalha pela equipe %s!", info.name, self.teams[team].name))
			Game.sendEventMessage(string.format("\nJogadores na equipe %s: %s\nJogadores na equipe %s: %s\nJogadores na equipe %s: %s\nJogadores na equipe %s: %s\n",
			self.teams[1].name, self.teams[1].size, self.teams[2].name, self.teams[2].size, self.teams[3].name, self.teams[3].size, self.teams[4].name, self.teams[4].size))
			
			player:registerEvent("Battlefield_PrepareDeath_x4")
			player:registerEvent("Battlefield_HealthChange_x4")
			player:registerEvent("Battlefield_ManaChange_x4")
			player:registerEvent("Battlefield_Logout_x4")
			return true -- Entrou no evento!
		end
	end

	function Battlefield_x4:onLeave(player)
		local info = self:findPlayer(player)
		if not info then -- Se n�o encontrou jogador l� dentro
			return false 
		end
		
		player:unregisterEvent("Battlefield_HealthChange_x4")
		player:unregisterEvent("Battlefield_PrepareDeath_x4")
		player:unregisterEvent("Battlefield_ManaChange_x4")
		player:unregisterEvent("Battlefield_Logout_x4")	
		
		player:setStorageValue(STORAGE_BATTLEFIELD, - 1)

		player:teleportTo(player:getTown():getTemplePosition())
		self.teams[info.team].size = self.teams[info.team].size - 1
		self.teams[info.team].players[info.name] = nil
		
		-- Enchendo HP e MANA (importante)
		player:addHealth(player:getMaxHealth())
		player:addMana(player:getMaxMana())
		
		player:removeCondition(CONDITION_INFIGHT)
		player:removeCondition(CONDITION_OUTFIT)

		local maxTeams = #self.teams
		local winnerTeam = {}
		if self.teams[info.team].size == 0 then
			Game.sendEventMessage(string.format("N�o h� mais ningu�m na equipe %s!", self.teams[info.team].name))
			for i = 1, #self.teams do
				if self.teams[i].size == 0 then
					maxTeams = maxTeams - 1
				else
					winnerTeam = self.teams[i]
				end
			end
			if maxTeams == 1 then
				self:Close(winnerTeam)
			elseif maxTeams == 0 then
				self:Close(nil)
			end		
		end		
		return true
	end

	function Battlefield_x4:onDeath(player, killer)
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