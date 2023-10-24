function Monster:onDropLoot(corpse)
	if configManager.getNumber(configKeys.RATE_LOOT) == 0 then
		return
	end

	local mType = self:getType()
	if mType:isRewardBoss() then
		corpse:registerReward()
		return
	end
	
	local player = Player(corpse:getCorpseOwner())
	local percent = 1.5
	if self:isBoosted() then
		percent = percent + 0.5
	end
	
	local bonusPrey = 0
	local hasCharm = false
	-- Guild Level System
	if player then
		local random = (player:getPreyBonusLoot(mType) >= math.random(100))
		if player:getPreyBonusLoot(mType) > 0 and random then
			bonusPrey = player:getPreyBonusLoot(mType)
			percent = (bonusPrey/100) + percent
		end


		if player:getClient().version >= 1200 then
			percent = percent + 0.05
		end
		local g = player:getGuild()
		if g then
			local rewards = {}
			local number = false
			rewards = getReward(player:getId())
			for i = 1, #rewards do
				if rewards[i].type == GUILD_LEVEL_BONUS_LOOT then
					number = rewards[i].quantity
				end
			end
			if number then
				percent = percent + number
			end
		end

		-- charm
		local currentCharm = player:getMonsterCharm(mType:raceId())
		if currentCharm == 14 then
			percent = percent * 1.10
			hasCharm = true
		end

		if player:getVipDays() > os.stime() then
			percent = percent * 1.05
		end

	end

	if not player or player:getStamina() > 840 then
		local monsterLoot = mType:getLoot()
		for i = 1, #monsterLoot do
			corpse:createLootItem(monsterLoot[i], percent, self:isRaid())
		end

		if player then
			local party = player:getParty()
			if party then
				party:broadcastPartyLoot(corpse, mType:getNameDescription(), bonusPrey, hasCharm)
				party:broadcastPartyLootTracker(self, corpse)
			else
				player:sendTextMessage(MESSAGE_LOOT, corpse:getLoot(mType:getNameDescription(), player:getClient().version, bonusPrey, hasCharm))
				player:sendKillTracker(self, corpse)
				player:sendChannelMessage("", corpse:getLoot(mType:getNameDescription(), 900, bonusPrey, hasCharm), TALKTYPE_CHANNEL_O, 10)
			end
		end
	else
		local text = ("Loot of %s: nothing (due to low stamina)"):format(mType:getNameDescription())
		local party = player:getParty()
		if party then
			party:broadcastPartyLoot(text)
		else
			player:sendTextMessage(MESSAGE_LOOT, text)
			player:sendChannelMessage("", text, TALKTYPE_CHANNEL_O, 10)
		end
	end

end

function Monster:onSpawn(position, startup, artificial)
	if not self:getType():canSpawn(position) then
		return false
	end

	if self:getType():isRewardBoss() then
		self:setReward(true)
	end

	if not startup then
		local spec = Game.getSpectators(position, false, false)
		for _, pid in pairs(spec) do
			local monster = Monster(pid)
			if monster and not monster:getType():canSpawn(position) then
				monster:remove()
			end
		end
		if self:getName():lower() == 'iron servant replica' then
			local chance = math.random(100)
			if Game.getStorageValue(GlobalStorage.ForgottenKnowledge.MechanismDiamond) >= 1 and Game.getStorageValue(GlobalStorage.ForgottenKnowledge.MechanismGolden) >= 1 then
				if chance > 30 then
					local chance2 = math.random(2)
					if chance2 == 1 then
						Game.createMonster('diamond servant replica', self:getPosition(), false, true)
					elseif chance2 == 2 then
						Game.createMonster('golden servant replica', self:getPosition(), false, true)
					end
					return false
				end
				return true
			end
			if Game.getStorageValue(GlobalStorage.ForgottenKnowledge.MechanismDiamond) >= 1 then
				if chance > 30 then
					Game.createMonster('diamond servant replica', self:getPosition(), false, true)
					return false
				end
			end
			if Game.getStorageValue(GlobalStorage.ForgottenKnowledge.MechanismGolden) >= 1 then
				if chance > 30 then
					Game.createMonster('golden servant replica', self:getPosition(), false, true)
					return false
				end
			end
		end
	end

	return true
end
