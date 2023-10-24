CASTLE_INFO = {
	STORAGE = 696969, -- Storage to count points
	CONDITIONS = {
		[1] = {HEALTH = 99, AMOUNT = 1},
		[2] = {HEALTH = 50, AMOUNT = 2},
		[3] = {HEALTH = 30, AMOUNT = 3}
	},
	THRONE_POSITION = Position(31369, 32657, 7),
	REWARD = {id = 15515, qnt = 15}
}

if not Castle then
	Castle = {
		open = false,		
		channel_id = 12,
		
		positionsArena = {
			fromPosition = Position(31355, 32645, 7),
			toPosition = Position(31383, 32669, 7)
		},		
		gatesArena = {
			[1] = Position(31336, 32683, 7),
			[2] = Position(31336, 32682, 7)
		},
		vortexArena = {
			[1] = Position(31337, 32682, 7),
			[2] = Position(31337, 32683, 7)
		},
		
		-- Info
		vortexToPosition = {
			-- Estrategy teleports
			[1] = Position(31358, 32667, 7), -- Left corner
			[2] = Position(31380, 32648, 7) -- Right corner
		},
		
		closedId = 5735,
		castleHouseId = 2500,-- id da house
			
		-- Config
		blockMC = true,
		minLevel = 0,
		warnInterval = 2 -- minutes between announce the top 1
	}
	
	-- Pegando o player id de quem está em primeiro
	function Castle:getTop(isTheLast)
		local maior = 0
		local winner = 0
		for _, player in pairs(Game.getPlayers()) do
			if isTheLast then
				player:unregisterEvent('Castle')
			end
			if player:getStorageValue(CASTLE_INFO.STORAGE) > maior then
				maior = player:getStorageValue(CASTLE_INFO.STORAGE)
				winner = player:getId()
			end
		end
		return winner
	end
	
	-- Avisando quem está em primeiro
	function Castle:warnRanks()
		if not self.open then
			return false
		end
		addEvent(function()
			local pid = self:getTop()
			local player = Player(pid)
			if player then
				Game.sendEventMessage(string.format('The player %s is winning the castle with %d points! Hurry up!', player:getName(), player:getStorageValue(CASTLE_INFO.STORAGE)))
			else
				Game.sendEventMessage(string.format('No one got any points yet! Hurry up!'))
			end
			return self:warnRanks()
		end, self.warnInterval*60*1000)
	end
	
	-- Abrindo evento!!
	function Castle:Open()
		if self.open then 
			return false
		end
		self.open = true		
		broadcastMessage("[Castle]\nThe event has just started!")
		Game.openEventChannel("Castle")
		self:warnRanks()
		for i = 1, #self.gatesArena do
			local closed = Tile(self.gatesArena[i]):getItemById(self.closedId)
			if closed then
				closed:transform(self.closedId - 1)
			end
		end
		for i = 1, #self.vortexArena do
			local teleport = Tile(self.vortexArena[i]):getItemById(1387)
			if not teleport then
				local item = Game.createItem(1387, 1, self.vortexArena[i])
				if item then
					item:setDestination(self.vortexToPosition[i])
				end
			end
		end				
		return true 
	end

	-- Final do evento!!!
	function Castle:Close()
		if not self.open then
			return false 
		end		
		self.open = false		
		local pid = self:getTop(true)
		local winner = Player(pid)
		if winner then
			broadcastMessage(string.format("[Castle]\nThe event has ended!\nThe winner was: %s, with %d points!", winner:getName(), winner:getStorageValue(CASTLE_INFO.STORAGE)))
			setHouseOwner(self.castleHouseId, 0)
			setHouseOwner(self.castleHouseId, winner:getGuid())
			winner:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Congratulations!\nNow you are the new owner of the castle!")
			winner:addItem(CASTLE_INFO.REWARD.id, CASTLE_INFO.REWARD.qnt)
			local guild = winner:getGuild()
			if guild then
				guild:broadcastMessage("Your guild has won the castle event!", MESSAGE_EVENT_ADVANCE)
				local house = House(self.castleHouseId)
				if house then
					local memberList = guild:getMembersGuid()
					local inviteList = ""
					if memberList then
						for i = 1, #memberList do
							inviteList = inviteList .. memberList[i] .. "\n"
						end
						house:setAccessList(GUEST_LIST, inviteList)
					end	
				end
			end
		else
			broadcastMessage(string.format("[Castle]\nThe event has ended!\nNo one won the event. :("))
			setHouseOwner(self.castleHouseId, 0)
		end
		for i = 1, #self.gatesArena do
			local closed = Tile(self.gatesArena[i]):getItemById(self.closedId-1)
			if closed then
				closed:transform(self.closedId)
			end
		end
		for i = 1, #self.vortexArena do
			local teleport = Tile(self.vortexArena[i]):getItemById(1387)
			if teleport then
				teleport:remove()
			end
		end	
		return true
	end
	
	function Castle:onStepIn(creature)
		if not self.open then
			return false
		end
		creature:registerEvent('Castle')
		return true
	end
	
	function Castle:onStepOut(creature)
		creature:unregisterEvent('Castle')
		return true
	end
end