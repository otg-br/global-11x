local config = {
	timeAndExhaust = 1000*10*60 
	-- 10 minutos de exhaust
}

-- condition:setOutfit(lookTypeEx, lookType, lookHead, lookBody, lookLegs, lookFeet[, lookAddons[, lookMount]])

local function getOutfitColors(playerid)
	local player = Player(playerid)
	local outfitColors = 
	{
		lookType = 0,
		lookTypeEx = 0,
		lookAddons = 0,
		lookLegs = 0,
		lookMount = 0,
		lookHead = 0,
		lookBody = 0,
		lookFeet = 0
		
	}
	if player then
		outfitColors.lookHead = player:getOutfit().lookHead
		outfitColors.lookBody = player:getOutfit().lookBody
		outfitColors.lookLegs = player:getOutfit().lookLegs
		outfitColors.lookFeet = player:getOutfit().lookFeet
	end
	return outfitColors
end

function onSay(player, words, param)
	local guild = player:getGuild()
	if not guild then
		player:sendCancelMessage("You must be member of a guild to use this command.")
	else
		if player:getGuildLevel() ~= 3 then
			player:sendCancelMessage("Only guild leaders are allowed to use this command.")
		else
			if player:getStorageValue("outfitChange") > os.stime() then
				player:sendCancelMessage("You are exhausted.")
			else
				local outfitColors = getOutfitColors(player:getId())
				if outfitColors then
					for _, p in pairs(guild:getMembersOnline()) do
						if p then
							outfitColors.lookType = p:getOutfit().lookType
							outfitColors.lookTypeEx = p:getOutfit().lookTypeEx
							outfitColors.lookAddons = p:getOutfit().lookAddons
							outfitColors.lookMount = p:getOutfit().lookMount
							p:setOutfit(outfitColors)
							p:getPosition():sendMagicEffect(CONST_ME_BATS)
							guild:broadcastMessage("Guild leader has changed everyone's outfit.")
							player:setStorageValue("outfitChange", os.stime() + config.timeAndExhaust)
						end
					end
				end
			end
		end
	end
	return false
end
