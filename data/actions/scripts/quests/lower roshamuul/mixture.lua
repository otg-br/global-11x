local buckets = {
    [22387] = 22388,
    [22388] = 22387
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    if (target == nil) or not target:isItem() then
        return false
    end

    if target:getId() == buckets[item:getId()] then
        item:transform(2005, 0)
        target:transform(22503)
    end
	
	if item:getId() == 22388 and target:getPosition() == Position(33201, 31763, 1) then
		player:teleportTo(Position(33356, 31309, 4), true)
		player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Once more you mix the chalk with a drop of your blood and a bit of water and renew the symbol on the floor...")
		item:transform(2005, 0)
    end
	
    return true
end
