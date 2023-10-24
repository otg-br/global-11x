local npcs = {
	[1] = "Norf",
	[2] = "Humphrey",
	[3] = "Edala",
	[4] = "Eremo",
	[5] = "Kawill",
}

local templos = {
	1, 2, 3, 4
}

 local blesses = {2, 3, 4, 5, 6, 7, 8}

local function blessCust(lvl)
	if lvl <= 30 then
		return 10000
	elseif lvl > 30 and lvl < 120 then
		return 5 * (2000 + 200 * (lvl - 30))
	end

	return 100000
end

function onSay(player, words, param)
	if player:getLevel() <= ADVENTURERS_BLESSING_LEVEL  then
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		player:sendCancelMessage('You have already got the Adventurer\'s Blessing.')
		return false
	end
	
	local hasBless = false
	for i = 1, #blesses do
		if player:hasBlessing(blesses[i]) then
			hasBless = true
			break
		end
	end

	if hasBless then
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		player:sendCancelMessage('You have already got one or more blessings!')
	else
		if player:removeMoneyNpc(blessCust(player:getLevel())) then
			for i = 1, #blesses do
				player:addBlessing(blesses[i], 1)
			end
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 'You have been blessed by the gods!')
		else
			player:sendCancelMessage("You need ".. blessCust(player:getLevel()) .." gold coins to get blessed!")
		end
	end
	return false
end
