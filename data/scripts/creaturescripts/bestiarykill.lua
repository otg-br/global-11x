local login = CreatureEvent("RegisterFunction")
local bestKill = CreatureEvent("bestKill")

function login.onLogin(player)
	-- Events
	player:registerEvent("bestKill")
	return true
end


local function addBestiaryPoints(monster)
	local raceid = monster:getType():raceId()
	if monster:getMaster() then
		return false
	end
	if not monster:getType() or raceid <= 0 then return true end

	local bestiary = Bestiary(raceid)
	local difficulty = false
	if bestiary then
		local entry = bestiary:getRaceByID(raceid)
		if entry then
			difficulty = bestiary:getDifficulty(entry.difficulty, entry.rare)
			if not difficulty then
				return true
			end
		end
	end

	local players = {}
	for pid, p in pairs(monster:getDamageMap()) do
		local player = Player(pid)

		if player and not isInArray(players, player:getId()) then
			players[#players + 1] = player:getId()
		end
	end

	for _, pid in pairs(players) do
		local player = Player(pid)
		local sendUnlock = false
		local sendCharm = false
		local unlockedId = 1
		if player then
			local kills = math.max(0, player:getBestiaryKill(raceid)) + 1
			if difficulty then
				if kills == 1 then
					sendUnlock = true
					unlockedId = 1
					player:sendTextMessage(MESSAGE_EVENT_DEFAULT, string.format("You have unlocked '%s' info.", monster:getType():getName()))
				elseif difficulty.first == kills or difficulty.second == kills then
					local diff = 3
					if (difficulty.first == kills) then
						diff = 2
						sendUnlock = true
					end
					player:sendTextMessage(MESSAGE_EVENT_DEFAULT, string.format("You have unlocked '%s' info.", monster:getType():getName()))
				elseif difficulty.final >= kills then
					if difficulty.final == kills then
						unlockedId = 4
						sendUnlock = true
						if not player:gainedCharmPoints(raceid) then
							local points = player:getCharmPoints() + difficulty.charm
							player:setCharmPoints(points)
							sendCharm = true
						end
						player:sendTextMessage(MESSAGE_EVENT_DEFAULT, string.format("You have unlocked '%s' info and and you got %d points.", monster:getType():getName(), difficulty.charm))
					end
				end
			end
			player:addBestiaryKill(raceid, 1, sendCharm)

			if sendUnlock then
				player:sendUnlockMonsterInfor(raceid, unlockedId)
				player:sendUnlockMonster(raceid)
			end
			if player:monsterInTracker(raceid) then
				player:sendBestiaryTracker()
			end

		end
	end

end

function bestKill.onKill(creature, target)
	local monster = Monster(target)
	if not monster then return true end

	addBestiaryPoints(monster)
	return true
end

login:type("login")
login:register()

bestKill:type("kill")
bestKill:register()
