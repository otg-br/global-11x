local mutes = {
	["help"] = {id = 7},
	["advertising"] = {id = 5},
	["worldchat"] = {id = 3},
	["english"] = {id = 4}
}

STORAGE_MUTED_ON_CHANNELS = 456110

function onSay(cid, words, param)
	local player = Player(cid)	
	
	if player:getAccountType() < ACCOUNT_TYPE_TUTOR then
		return false
	end
	
	local storage = STORAGE_MUTED_ON_CHANNELS

	if words == "/mute" then
		local mute = param:split(",")

		if mute[1] == nil or mute[1] == " " then
			player:sendCancelMessage("Invalid player specified.")
			return false
		end

		if mute[2] == nil or mute[2] == " " then
			player:sendCancelMessage("Invalid channel specified.")
			return false	
		end
		
		if mute[3] == nil or mute[3] == " " then
			player:sendCancelMessage("Invalid time specified.")
			return false
		end
		
		local target = Player(mute[1])
		local channel = mutes[mute[2]:lower()]
		if not channel then return player:sendCancelMessage('Unknown channel!!') end
		storage = storage + channel.id
		local time = tonumber(mute[3])		
		
		local condition = Condition(CONDITION_CHANNELMUTEDTICKS, CONDITIONID_DEFAULT)
		condition:setParameter(CONDITION_PARAM_SUBID, channel.id)
		condition:setParameter(CONDITION_PARAM_TICKS, time*60*1000)
		
		if target == nil then
			player:sendCancelMessage("A player with that name is not online.")
			return false
		end

		if target:getAccountType() >= ACCOUNT_TYPE_TUTOR then
			player:sendCancelMessage("Only player can be mutated")
			return false
		end	

		target:addCondition(condition)
		sendChannelMessage(channel.id, TALKTYPE_CHANNEL_R1, target:getName() .. " has been muted for ".. time .." minutes. Reason: using ".. mute[2]:lower() .." inappropriately.")
		target:setStorageValue(storage, os.stime() + time * 60)		
		return false
	end

	if words == "/unmute" then
		
		local mute = param:split(",")

		if mute[1] == nil or mute[1] == " " then
			player:sendCancelMessage("Invalid player specified.")
			return false
		end

		if mute[2] == nil or mute[2] == " " then
			player:sendCancelMessage("Invalid channel specified.")
			return false
		end
		
		local target = Player(mute[1])
		local channel = mutes[mute[2]:lower()]
		if not channel then return player:sendCancelMessage('Unknown channel!!') end
		storage = storage + channel.id		

		if player:getAccountType() < ACCOUNT_TYPE_TUTOR then
			return false
		end

		if target == nil then
			player:sendCancelMessage("A player with that name is not online.")
			return false
		end

		if target:getAccountType() >= ACCOUNT_TYPE_TUTOR then
			return false
		end

		if target:getStorageValue(storage) > 0 then
			target:removeCondition(CONDITION_CHANNELMUTEDTICKS, CONDITIONID_DEFAULT, channel.id)
			sendChannelMessage(channel.id, TALKTYPE_CHANNEL_R1, target:getName() .. " has been unmuted by " .. player:getName() .. ".")
			target:setStorageValue(storage, -1)
		else
			player:sendCancelMessage("A player " .. target:getName() .. " is not muted.")
		end
	end

	return false
end
