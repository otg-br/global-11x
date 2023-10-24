if not Zombie then
	Zombie = {
		eventName = "Zombie",
		monsterName= "Event Zombie",
		open = false,		
		channel_id = 12,			
		positionsArena = {
			fromPosition = Position(31763, 31473, 7),
			toPosition = Position(31858, 31548, 7)
		},
		itensBloqueados = {
			[1] = {id = 2197}, -- ssa,
			[2] = {id = 2164} -- might ring
		},
		reward = {
			-- {itemid, quantity}
			{id = 15515, quantidade = 10}
		},
		reward_hasMount = {
			{id = 15515, quantidade = 25}
		},
		rewardMount = 666, -- mount id
		
		timeSpawn = 30, -- seconds to next spawn
		timeToStart = 60, -- seconds to start event after confirmation
		blockMC = false,
		minLevel = 0,	
		minPlayers = 2, 
		maxPlayers = 30,
		players = {},
		zombies = 0,
	}
	
	function Zombie:checkSQM()
		local r_x = math.random(self.positionsArena.fromPosition.x, self.positionsArena.toPosition.x)
		local r_y = math.random(self.positionsArena.fromPosition.y, self.positionsArena.toPosition.y)	
		local r_z = math.random(self.positionsArena.fromPosition.z, self.positionsArena.toPosition.z)
		local position = Position(r_x, r_y, r_z)
		if Tile(position):hasFlag(TILESTATE_BLOCKPATH) or Tile(position):hasFlag(TILESTATE_BLOCKSOLID) then
			return self:checkSQM()
		else
			return position						
		end			
	end
	
	function Zombie:spawnZombie(isPlayer, pid)
		if self.open then 
			if not isPlayer then
				local position = self:checkSQM()
				if position then				
					Game.createMonster(self.monsterName, position)
					self.zombies = self.zombies + 1
					Game.sendEventMessage(string.format("One more zombie has appeared! Zombies inside the event: %d", self.zombies))
					addEvent(function()
						self:spawnZombie(false, false)
					end, self.timeSpawn*1000)
				end
			else
				local p = Player(pid)
				if p then
					local position = p:getPosition()
					Game.createMonster(self.monsterName, position)
					self.zombies = self.zombies + 1
					Game.sendEventMessage(string.format("The player %s turned into a zombie! Zombies inside the event: %d", p:getName(), self.zombies))
				end
			end
		else
			return false
		end
	end

	function Zombie:Open()
		if #self.players >= self.minPlayers then
			if self.open then 
				return false
			end
			self.open = true		
			broadcastMessage("["..self.eventName.."]\nThe event has just started!")
			Game.openEventChannel(self.eventName)
			Game.sendEventMessage(string.format("The first zombie will spawn in %d seconds!", self.timeToStart))
			addEvent(function()
				self:spawnZombie(false, false)
			end, self.timeSpawn*1000)
			return true 
		else	
			broadcastMessage("["..self.eventName.."]\nThe event couldn't start because there wasn't enough players.")	
			for i = 1, #self.players do
				local pid = self.players[i]
				if pid then
					self:onLeave(pid, true)
				end
			end
			self.players = {}
			self.zombies = 0
			return false
		end
	end
	
	function Zombie:Close()
		if not self.open then
			return false 
		end
		self.open = false
		local function returnWinner()
			for i = 1, #self.players do
				local pid = self.players[i]
				local name = getCreatureName(pid) or pid
				if pid and #self.players == 1 then
					table.remove(self.players, i)
					print(">> ["..self.eventName.."] Finalizado com sucesso. Vencedor: " .. name)
					return pid
				end
			end
		end
		local player = Player(returnWinner())				
		if player then
			broadcastMessage(string.format("["..self.eventName.."]\nPlayer %s survived until the end and won the event!", player:getName()))
		else
			broadcastMessage("["..self.eventName.."] - Error\nNobody won the event.")
		end
		if player:hasMount(self.rewardMount) then
			for i = 1, #self.reward_hasMount do
				local item = player:addItem(self.reward_hasMount[i].id, self.reward_hasMount[i].quantidade)
			end
		else
			player:addMount(self.rewardMount)
			for i = 1, #self.reward do
				local item = player:addItem(self.reward[i].id, self.reward[i].quantidade)
			end
		end
		player:teleportTo(player:getTown():getTemplePosition())
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "["..self.eventName.."]\nYou won the event!")
		return true
	end
	
	function Zombie:findPlayer(player)
		for i = 1, #self.players do
			if self.players[i] == player:getId() then 
				return true 
			end
		end
		return false
	end

	function Zombie:onJoin(player)		
		local block = false
		if self.blockMC then
			for i = 1, #self.players do
				local p = Player(self.players[i]:getId())
				if p and p:getIp() == player:getIp() then
					player:sendCancelMessage('Seu IP é idêntico ao do jogador '..p:getName()..', que já está dentro do evento.')
					block = true
				end
			end				
		end
		for i = 1, #self.itensBloqueados do
			if player:getItemCount(self.itensBloqueados[i].id) >= 1 then
				player:sendCancelMessage('You cannot enter the event with '..ItemType(self.itensBloqueados[i].id):getName()..'.')
				block = true
			end
		end
		if #self.players >= self.maxPlayers then
			player:sendCancelMessage('Desculpe, já existem ' .. self.maxPlayers .. ' jogadores dentro do evento.')
			block = true
		end
		if player:getLevel() < self.minLevel then
			player:sendCancelMessage('Você não possui level suficiente. Volte quando estiver level ' .. self.minLevel .. '.')
			block = true
		end	
		if not block then
			local position = self:checkSQM()
			if position then
				player:teleportTo(position)
				player:getPosition():sendMagicEffect(CONST_ME_MORTAREA)
				player:openChannel(self.channel_id)
				player:registerEvent('zombieDeath')
				player:registerEvent('zombieLogout')		
				player:say("Maybe it wasn't a good idea.", TALKTYPE_MONSTER_SAY)
				table.insert(self.players, player:getId())
				Game.sendEventMessage(string.format("%s has entered the event! Players inside the event: %d", player:getName(), #self.players))			
			end
			return true
		end
	end

	function Zombie:onLeave(pid, isCanceling)
		local player = Player(pid)
		if not isCanceling then
			for i = 1, #self.players do
				if self.players[i] == pid then
					table.remove(self.players, i)
				end
			end
			if #self.players == 1 then
				self:Close()
			else
				self:spawnZombie(true, pid)
			end
		end
		player:teleportTo(player:getTown():getTemplePosition())
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "["..self.eventName.."]\nYou were removed from the event.")
		player:unregisterEvent('zombieDeath')
		player:unregisterEvent('zombieLogout')
		return true
	end
end