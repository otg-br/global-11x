function onLogin(cid)
    local player = Player(cid)
    if player:getLevel() <= ADVENTURERS_BLESSING_LEVEL then
    	for i = WISDOM_OF_SOLITUDE, EMBRACE_OF_TIBIA do
    		if not player:hasBlessing(i) then
    			player:addBlessing(i, 1)
    		end
    	end
    	player:sendTextMessage(MESSAGE_EVENT_ADVANCE,'You received adventurers blessings for you to be level less than ' .. ADVENTURERS_BLESSING_LEVEL .. '!')
        player:getPosition():sendMagicEffect(CONST_ME_HOLYDAMAGE)
    end
    return true
end
