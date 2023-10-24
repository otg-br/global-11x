-- talkactions
local talkaction = TalkAction("!war")

function talkaction.onSay(player, word, param)
	local guild = player:getGuild()
	if not guild then
		player:sendCancelMessage("You are not a member of a guild.")
		return false
	end

	if not player:canDeclareWar() then
		player:sendCancelMessage("You need to be the leader of your guild.")
		return false
	end

	param = param:lower()
	local split = param:splitTrimmed(",")
	local rivalName = split[2] or ''

	local rival = Guild(rivalName)
	if not rival then
		player:sendCancelMessage(string.format("Guild with the name '%s' was not found.", rivalName))
		return false
	end

	if guild:getId() == rival:getId() then
		player:sendCancelMessage(string.format("Its not possible."))
		return false
	end

	local rivalMember = false
	for _, target in pairs(rival:getMembersOnline()) do
		rivalMember = target
		break
	end
	if not rivalMember then
		player:sendCancelMessage(string.format("There are no members of the %s online.", rival:getName()))
		return false
	end

	-- Duas pessoas nao podem usar o comando ao mesmo tempo, por causa da query
	if Game.getStorageValue(GlobalStorage.WarDelay1) >= os.stime() then
		player:sendCancelMessage(string.format("You are exhausted"))
		return false
	end

	if player:getStorageValue(Storage.WarDelay1) >= os.stime() then
		player:sendCancelMessage(string.format("You are exhausted"))
		return false
	end
	player:setStorageValue(Storage.WarDelay1, os.stime() + 10)
	Game.setStorageValue(GlobalStorage.WarDelay1, os.stime() + 3)

	local status = -1
	local warid = -1
	local guild1 = 0
	local guild2 = 0

	local resultId = db.storeQuery("SELECT `status`, `id`, `guild1`, `guild2` FROM `guild_wars` WHERE ((`guild1` = " .. guild:getId() .. " AND `guild2` = " .. rival:getId() .. ") OR (`guild1` = " .. rival:getId() .. " AND `guild2` = " .. guild:getId() .. ")) AND `ended` = 0")
	if resultId ~= false then
		status = result.getNumber(resultId, "status")
		warid = result.getNumber(resultId, "id")
		guild1 = result.getNumber(resultId, "guild1")
		guild2 = result.getNumber(resultId, "guild2")
	end
	result.free(resultId)

	if split[1] == "invite" then
		if (status == 1) then
			player:sendCancelMessage(string.format("You are already at war."))
			return false
		elseif status == 0 then
			player:sendCancelMessage("Pending acceptation")
			return false
		end
		local limit = tonumber(split[3])
		if not limit or limit < 1 or limit > 10000 then
			player:sendCancelMessage("Inconsistent frags limit. [1 - 10000]")
			return false
		end
		local queryText = string.format("INSERT INTO `guild_wars` (`guild1`, `guild2`, `name1`, `name2`, `status`, `started`, `ended`, `frags_limit`) VALUES (%d, %d, %s, %s, %d, %d, %d, %d)",
			guild:getId(),
			rival:getId(),
			db.escapeString(guild:getName()),
			db.escapeString(rival:getName()),
			0, -- status
			os.stime(), -- started
			0, -- ended
			limit) -- frag
		db.asyncQuery(queryText)
		Game.broadcastMessage(string.format("'%s' invited '%s' to a war with maximum limit of '%d' frags.", guild:getName(), rival:getName(), limit))
		for _, target in pairs(rival:getMembersOnline()) do
			if target:getGuildLevel() >= 3 then
				target:sendTextMessage(MESSAGE_STATUS_WARNING, string.format("Use the '!war accept, %s' command to accept the war or '!war reject, %s' to decline.", guild:getName(), guild:getName()))
			end
		end

	elseif split[1] == "accept" then
		if status ~= 0 or warid == -1 then
			player:sendCancelMessage("Sorry, is not possible")
			return false
		end
		if guild2 ~= guild:getId() then
			player:sendCancelMessage("It is not your guild that accepts the war request.")
			return false
		end

		local queryText = string.format("UPDATE `guild_wars` SET `status` = 1, `started` = %d WHERE `id` = %d", os.stime(), warid)
		db.asyncQuery(queryText)
		Game.broadcastMessage(string.format("'%s' accepted '%s' war request", guild:getName(), rival:getName()))
		guild:broadcastMessage("Please relog to update war status.")
		rival:broadcastMessage("Please relog to update war status.")

	elseif split[1] == "cancel" then
		if status ~= 0 or warid == -1 then
			player:sendCancelMessage("Sorry, is not possible")
			return false
		end
		if guild1 ~= guild:getId() then
			player:sendCancelMessage("It is not your guild that cancel the war request.")
			return false
		end

		local queryText = string.format("UPDATE `guild_wars` SET `status` = 3, `ended` = %d WHERE `id` = %d", os.stime(), warid)
		db.asyncQuery(queryText)
		Game.broadcastMessage(string.format("'%s' cancel war request", guild:getName()))

	elseif split[1] == "reject" then
		if status ~= 0 or warid == -1 then
			player:sendCancelMessage("Sorry, is not possible")
			return false
		end
		if guild2 ~= guild:getId() then
			player:sendCancelMessage("It is not your guild that cancel the war request.")
			return false
		end

		local queryText = string.format("UPDATE `guild_wars` SET `status` = 2, `ended` = %d WHERE `id` = %d", os.stime(), warid)
		db.asyncQuery(queryText)
		Game.broadcastMessage(string.format("'%s' reject '%s' war request", guild:getName(), rival:getName()))
	end
	return false
end

talkaction:separator(" ")
talkaction:register()
