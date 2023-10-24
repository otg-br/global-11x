local npcs = {
	[1] = Position(32354, 32363, 7),
	[2] = Position(32363, 31688, 7),
	[3] = Position(32697, 31723, 7),
	[4] = Position(33314, 31883, 7),
	[5] = Position(32644, 31983, 12),
}

function onModalWindow(player, modalWindowId, buttonId, choiceId) 
    player:unregisterEvent("ModalWindow_Bless")

    if buttonId == 255 then
        return false
    end

    local teleport = npcs[choiceId]
    if not choiceId or buttonId == 101 then
    	return false
    end

    player:teleportTo(teleport, false)

    return true
end