--[[
#### System made by @worthdavi
#### based on an old system from Auraot
--]]

-- guild:getPoints()
-- guild:setPoints(amount)
-- guild:getLevel()
-- guild:setLevel(amount)

-- BONUS
GUILD_LEVEL_BONUS_EXP = 1
GUILD_LEVEL_BONUS_LOOT = 2
GUILD_LEVEL_BONUS_HEALTH = 3
GUILD_LEVEL_BONUS_MANA = 4
GUILD_LEVEL_BONUS_ELEMENTAL = 5

-- OBTAINING POINTS
-- GUILD_LEVEL_POINTS_MONSTER = 1
-- GUILD_LEVEL_POINTS_BOSS = 2

CONFIG_GUILD_LEVEL = {
	quantityToLevel = 1500000, -- points to next level
	maxLevel = 10, -- guild level limit	
	minLevelToGetPoints = 150,
	rewards = {-- level, type of the reward and bonus quantity
		[1] = {level = 1, type = nil, quantity = nil},
		[2] = {level = 2, type = GUILD_LEVEL_BONUS_EXP, quantity = 0.03},   		-- 3% XP
		[3] = {level = 3, type = GUILD_LEVEL_BONUS_EXP, quantity = 0.06},			-- 6% XP
		[4] = {level = 4, type = GUILD_LEVEL_BONUS_LOOT, quantity = 0.05},			-- 5% LOOT
		[5] = {level = 5, type = GUILD_LEVEL_BONUS_LOOT, quantity = 0.10},			-- 10% LOOT
		[6] = {level = 6, type = GUILD_LEVEL_BONUS_HEALTH, quantity = 0.50},		-- 50% HEALTH GAIN	
		[7] = {level = 7, type = GUILD_LEVEL_BONUS_MANA, quantity = 0.30},			-- 30% MANA GAIN
		[8] = {level = 8, type = GUILD_LEVEL_BONUS_EXP, quantity = 0.10},			-- 10% XP
		[9] = {level = 9, type = GUILD_LEVEL_BONUS_LOOT, quantity = 0.15},			-- 15% LOOT
		[10] = {level = 10, type = GUILD_LEVEL_BONUS_ELEMENTAL, quantity = 0.03}	-- 3% ELEMENTAL RESISTANCE
	}
}

CONFIG_GUILD_MONSTERS = {
	minMonsterExp = 500,
	type = {
		["monster"] = {pts = 3},
		["boss"] = {pts = 500},
	},
	buyingMount = {pts = 10000, msg = "The player %s just bought a mount on the store and earned %d points for your guild!"},
	buyingOutfit = {pts = 10000, msg = "The player %s just bought an outfit on the store and earned %d points for your guild!"},
	killingPlayer = {level = 150, pts = 250, msg = "The player %s killed someone above level 150 and earned %d points for your guild!"}
}

function Guild.getGuildLevel(self)
	return self:getLevel() 
end

function Guild.getGuildPoints(self)
	return self:getPoints() 
end

function getReward(cid)
	local player = Player(cid)
	local rewardTable = {}
	if player then
		local g = player:getGuild()
		if g then
			for i = 1, #CONFIG_GUILD_LEVEL.rewards do
				if g:getGuildLevel() >= CONFIG_GUILD_LEVEL.rewards[i].level then
					rewardTable[i] = CONFIG_GUILD_LEVEL.rewards[i]
				end
			end
			return rewardTable
		else
			return true
		end
	end
end

function Guild.setGuildLevel(self, amount)
	local old = self:getGuildLevel()
	local g_name = self:getName()		
	if amount > CONFIG_GUILD_LEVEL.maxLevel then
		return error(">> The level must be under "..CONFIG_GUILD_LEVEL.maxLevel..".")
	elseif amount < 1 then
		return error(">> The level must be higher or equals than 1.")
	else
		self:setLevel(amount)	
		local new = self:getGuildLevel()
		Game.sendConsoleMessage("Level from guild "..g_name.." changed from ["..old.."] to ["..new.."].", CONSOLEMESSAGE_TYPE_INFO)
	end
	return true
end

function Guild.setGuildPoints(self, amount)	
	local g_name = self:getName()		
	if amount > CONFIG_GUILD_LEVEL.quantityToLevel then
		amount = CONFIG_GUILD_LEVEL.quantityToLevel
	elseif amount < 0 then
		return error(">> The value must be higher than 0.")
	end	
	self:setPoints(amount)
	return true
end

function mustLevelUp(gid)
	local guild = Guild(gid)
	if guild then
		if guild:getGuildPoints() >= CONFIG_GUILD_LEVEL.quantityToLevel then
			guild:setGuildLevel(guild:getGuildLevel() + 1)
			guild:setGuildPoints(0)
			broadcastMessage('[Guild System]\n The guild '..guild:getName()..' just levelled up to level '..guild:getGuildLevel()..'!\n Congratulations!')
		end
	else
		error(">> Cannot find a guild with this id.")
	end
end

function sendKillingPoints(cid, type)
	local creature = Creature(cid)
	local p_block = {}
	for _, k in pairs(CONFIG_GUILD_MONSTERS.type) do
		if _ == type then
			for creatureid, damage in pairs(creature:getDamageMap()) do
				local p = Creature(creatureid)
				if p and (p:isPlayer() and p:getGuild()) then
					local guild = Guild(p:getGuild():getId())
					if guild then
						if not isInArray(p_block, guild:getId()) then
							guild:setGuildPoints(guild:getGuildPoints() + k.pts)
							if guild:getGuildLevel() < CONFIG_GUILD_LEVEL.maxLevel then
								mustLevelUp(guild:getId()) -- check if the guild will level up or not
							end
							table.insert(p_block, guild:getId()) 
							-- add the guild into a table to block if someone from the same guild give damage on the same monster
						end
					end
				end
			end
		end
	end
	return true
end