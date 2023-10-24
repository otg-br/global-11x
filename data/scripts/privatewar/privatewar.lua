-- CreatureEvent
local login = CreatureEvent("RegisterFunction_privatewar")
local kill = CreatureEvent("Kill_privatewar")
local modalWindowEvent = CreatureEvent("ModalWindow_privatewar")

function login.onLogin(player)
	if player:inArenaWar() then
		player:teleportTo(player:getTown():getTemplePosition(), true)
	end

	if player:getGuild() then
		player:registerEvent("Kill_privatewar")
	end

	player:setPrivateWar(false)
	return true
end

function kill.onKill(player, target)
	if not player:inArenaWar() then
		player:setPrivateWar(false)
		return true
	end
	local playerTarget = Player(target)
	if not playerTarget then
		return true
	end
	if not player:isRivalWar(target:getId()) then
		return true
	end

	playerTarget:setPrivateWar(false)

	local guild = player:getGuild()

	if not guild then return true end

	local city = guild:getCityWar()
	if city == 0 then return true end

	local frag = PRIVATEWAR_BATTLEFIELD[city].frags[guild:getId()]
	local maxfrag = PRIVATEWAR_BATTLEFIELD[city].maxfrag
	PRIVATEWAR_BATTLEFIELD[city].frags[guild:getId()] = frag + 1
	if maxfrag ~= 0 and frag >= maxfrag then
		if Game.getAddEventValue(city) > 0 then
			-- a guerra é encerrada
			stopEvent(Game.getAddEventValue(city))
			Game.setAddEventValue(city, -1)

			-- chama o stopWar
			Game.stopWar(city, 1)
		end
	end
	return true
end

local function getPassModal(modalWindowId)
	local pass = 0
	for id, modalid in pairs(Modal.WarPrivate) do
		if modalid == modalWindowId then
			pass = id
			break
		end
	end

	return pass
end

function modalWindowEvent.onModalWindow(player, modalWindowId, buttonId, choiceId)
	player:unregisterEvent("ModalWindow_privatewar")
	local pass = getPassModal(modalWindowId)
	local guild = player:getGuild()
	if not guild then
		return true
	end

	if buttonId == 100 then
		if pass ~= PRIVATEWAR_ENDID then
			guild:cleanTempData()
		end
		return true
	end

	if buttonId == 102 then
		if pass == PRIVATEWAR_ENDID then
			if Guild(guild:getTempRival()) then
				Game.broadcastMessage(string.format("The '%s' guild declined the '%s' guild war request.", guild:getName(), Guild(guild:getTempRival()):getName()))
			end
			guild:cleanTempData()
		else
			player:makeOtherWarDialog(pass - 1)
		end
		return true
	end

	if pass == PRIVATEWAR_CONFIRMID then
		-- envia para o rival online
		local rival = Guild(guild:getTempRival())
		if not rival then
			guild:cleanTempData()
			return true
		end
		local members = rival:getMembersOnline()
		local leader = false
		for _, member in pairs(members) do
			if member:getGuildLevel() >= 3 then
				leader = true
				member:sendTextMessage(MESSAGE_STATUS_WARNING, string.format("The guild '%s' invited your guild to a private war. Use the \"!privatewar reply\" command to answer the request.", guild:getName()))
				break
			end
		end

		if not leader then
			player:sendCancelMessage(string.format("There are no rival guild leaders online."))
			guild:cleanTempData()
			return false
		end

		Game.broadcastMessage(string.format("The guild '%s' invited the guild '%s' to a private war.", guild:getName(), rival:getName()))
		return true
	elseif pass == PRIVATEWAR_ENDID then
		-- envia para o rival online
		local rival = Guild(guild:getTempRival())
		if not rival then
			guild:cleanTempData()
			return true
		end

		-- confirma a guerra
		local started = Game.startWar(rival:getId(), guild:getId(), guild:getTempWar())
		if started then
			guild:broadcastMessage("Use '!privatewar go' to go to the arena.")
			rival:broadcastMessage("Use '!privatewar go' to go to the arena.")
			Game.broadcastMessage(string.format("Private war '%s'vs'%s' has started.", guild:getName(), rival:getName()))
		else
			guild:cleanTempData()
		end
		return true
	end

	player:makeOtherWarDialog(pass + 1)
	if pass == 1 then
		guild:setTempCity(choiceId)
	elseif pass == 2 then
		guild:setTempTime(choiceId)
	elseif pass == 3 then
		guild:setTempMaxPlayer(choiceId)
	elseif pass == 4 then
		guild:setTempMaxFrags(choiceId)
	elseif pass == 5 then
		guild:setTempBlockRunes(choiceId)
	elseif pass == 6 then
		guild:setTempAllowUE(choiceId)
	elseif pass == 7 then
		guild:setTempAllowNewPotions(choiceId)
	elseif pass == 8 then
		guild:setTempAllowNewSummons(choiceId)
	elseif pass == 9 then
		guild:setTempAllowArrow(choiceId)
	elseif pass == 10 then
		guild:setTempAllowWave(choiceId)
	elseif pass == 11 then
		guild:setTempAllowStrongWave(choiceId)
	elseif pass == 12 then
		guild:setTempAllowBeam(choiceId)
	end
	return true
end

login:type("login")
login:register()

kill:type("kill")
kill:register()

modalWindowEvent:type("modalwindow")
modalWindowEvent:register()
-- End CreatureEvent

-- talkactions
local talk = TalkAction("!privatewar")

function talk.onSay(player, word, param)
	local guild = player:getGuild()
	if not guild then
		player:sendCancelMessage("You are not a member of a guild.")
		return false
	end

	param = param:lower()
	local commands = "!privatewar [invite|cancel|reply|cancel war|go|help]"
	local split = param:splitTrimmed(",")
	if split[1] == "invite" then
		if not player:canDeclareWar() then
			player:sendCancelMessage("You need to be the leader of your guild.")
			return false
		end
		if player:getStorageValue(Storage.WarDelay) >= os.stime() then
			player:sendCancelMessage("You are exhausted.")
			return false
		end
		local StorageGlobal = Game.getStorageValue(GlobalStorage.WarDelay) or -1
		if StorageGlobal >= os.stime() then
			player:sendCancelMessage("You are exhausted.")
			return false
		end

		-- evitar varias queries ao mesmo tempo no servidor
		Game.setStorageValue(GlobalStorage.WarDelay, os.stime() + 3)
		-- delay do jogador
		player:setStorageValue(Storage.WarDelay, os.stime() + 10)

		local rivalName = split[2]
		if rivalName == "" or rivalName == " " then
			player:sendCancelMessage("Command requires parameters.")
			return false
		end
		local guildid = 0
		local queryId = db.storeQuery("SELECT `id` FROM `guilds` WHERE `name` = ".. db.escapeString(rivalName) .. ";")
		if queryId ~= false then
			guildid = result.getNumber(queryId,"id")
		end
		result.free(queryId)

		local rival = Guild(guildid)
		if not rival then
			player:sendCancelMessage(string.format("Guild with the name '%s' was not found.", rivalName))
			return false
		end

		if guildid == guild:getId() then
			player:sendCancelMessage(string.format("Is not possible"))
			return false
		end
		local inwar = false
		local warQuery = db.storeQuery("SELECT * FROM `guild_wars` WHERE ((`guild1` = " .. guild:getId() .. " AND `guild2` = " .. rival:getId() .. ") OR (`guild1` = " .. rival:getId() .. " AND `guild2` = " .. guild:getId() .. ")) AND `ended` = 0 AND `status` = 1")
		if warQuery ~= false then
			inwar = true
		end
		result.free(warQuery)

		if not inwar then
			player:sendCancelMessage("The guilds are not in the war system (shields).")
			return false
		end

		if guild:getTempRival() > 0 then
			player:sendCancelMessage(string.format("Your guild is already riding a war. Accept or decline before starting a new one."))
			return false		
		end
		if rival:getTempRival() > 0 then
			player:sendCancelMessage(string.format("The rival guild is already mounting a war. Wait for her to answer the old invitation."))
			return false		
		end

		if rival:getConviteState() ~= GUILD_CONVITE_NONE then
			player:sendCancelMessage(string.format("The '%s' guild already has an active invitation.", rivalName))
			return false
		end
		if guild:getConviteState() ~= GUILD_CONVITE_NONE then
			player:sendCancelMessage(string.format("Your guild already has an active invitation."))
			return false
		end

		local members = rival:getMembersOnline()
		local leader = false
		for _, member in pairs(members) do
			if member:getGuildLevel() >= 3 then
				leader = true
				break
			end
		end

		if not leader then
			player:sendCancelMessage(string.format("There are no rival guild leaders online."))
			return false
		end

		-- evitar bugs
		guild:startTempData()
		-- setando o valor temporario para o modal
		guild:setTempRival(rival:getId())
		player:makeOtherWarDialog(1)
	elseif split[1] == "go" then
		-- teleportar para a arena
		local result = player:teleportToWar()
		if not result then
			player:sendCancelMessage("Sorry, not possible")
		end
	elseif split[1] == "reply" then
		if not player:canDeclareWar() then
			player:sendCancelMessage("You need to be the leader of your guild.")
			return false
		end
		if guild:getConviteState() ~= GUILD_CONVITE_DEFENSER then
			player:sendCancelMessage(string.format("Your guild is the attacker or there is no invitation."))
			return false
		end

		player:makeOtherWarDialog(PRIVATEWAR_ENDID)

	elseif split[1] == "cancel" then
		if not player:canDeclareWar() then
			player:sendCancelMessage("You need to be the leader of your guild.")
			return false
		end
		-- limpar o convite
		if guild:getTempRival() > 0 then
			guild:cleanTempData()
			player:sendCancelMessage(string.format("War successfully canceled."))
			return false
		end

		player:sendCancelMessage(string.format("Your guild is not in pre war."))
	elseif split[1] == "cancel war" then
		if not player:canDeclareWar() then
			player:sendCancelMessage("You need to be the leader of your guild.")
			return false
		end

		if not player:canCancelWar() then
			player:sendCancelMessage("The war cannot be canceled.")
			return false
		end

		PRIVATEWAR_BATTLEFIELD[guild:getCityWar()] = nil
		player:sendCancelMessage(string.format("War successfully canceled."))
	elseif split[1] == "help" or split[1] == "" then
		player:sendTextMessage(MESSAGE_STATUS_WARNING, "Params: "..commands)
	elseif split[1] == "rules" then
		player:sendWarRules()
	else
		player:sendTextMessage(MESSAGE_STATUS_WARNING, "Params: "..commands)
	end
	return false
end

talk:separator(" ")
talk:register()
-- End Talkactions
