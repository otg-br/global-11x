local config = {
	timeAndExhaust = 10
}

function onSay(player, words, param)
	local guildMembers = {}
	local guild = player:getGuild()
	if not guild then
		player:sendCancelMessage("You must be member of a guild to use this command.")
	else
		if player:getGuildLevel() < 2 then
			player:sendCancelMessage("Only guild leaders or vice-leaders are allowed to use this command.")
		else
			if param == "" then
				player:sendCancelMessage("You must specify a player to send target.")
			else			
				local target = Player(param)
				if target then
					if player:getStorageValue("sendSquare") > os.stime() then
						player:sendCancelMessage("You are exhausted.")
					else
						for _, p in pairs(guild:getMembersOnline()) do
							table.insert(guildMembers, p)
						end
						target:sendSquare(180, config.timeAndExhaust, guildMembers)
						player:setStorageValue("sendSquare", os.stime() + config.timeAndExhaust)
					end
				else
					player:sendCancelMessage("Player " .. param .. " doesn't exist or is not online.")
				end
			end
		end
	end
	return false
end
