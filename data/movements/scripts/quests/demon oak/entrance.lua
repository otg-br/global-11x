function onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end

	if player:getStorageValue(Storage.DemonOak.Done) >= 1 then
		player:teleportTo(DEMON_OAK_KICK_POSITION)
		player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		return true
	end
	
	if player:getLevel() < 120 then
		player:say("LEAVE LITTLE FISH, YOU ARE NOT WORTH IT!", TALKTYPE_MONSTER_YELL, false, player, DEMON_OAK_POSITION)
		player:teleportTo(DEMON_OAK_KICK_POSITION)
		player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		return true
	end

	if player:getStorageValue(Storage.DemonOak.Progress) < 1 then
		if player:getItemCount(10305) < 1 then
			player:teleportTo(DEMON_OAK_KICK_POSITION)
			player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
			player:say("You don\'t have a " .. ItemType(10305):getName() .. ".", TALKTYPE_MONSTER_SAY)
			return true
		else
			player:removeItem(10305, 1)
		end
	end
	
	player:teleportTo(DEMON_OAK_ENTER_POSITION)
	player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
	player:setStorageValue(Storage.DemonOak.Progress, 1)
	player:say("I AWAITED YOU! COME HERE AND GET YOUR REWARD!", TALKTYPE_MONSTER_YELL, false, player, DEMON_OAK_POSITION)
	return true
end
