function onModalWindow(player, modalWindowId, buttonId, choiceId) 
    player:unregisterEvent("ModalWindow_autoloot")

    if buttonId == 255 then
        return false
    end

    if not choiceId or buttonId ~= 101 then
    	return false
    end


    if Modal.autoloot == modalWindowId then
        PLAYER_ACTION_MODAL[player:getId()] = choiceId
        player:sendAutoLootContainer()
        return true
    end

    local container = player:getContainers()[choiceId]
    if not container or container:getId() == 26052 then
        player:setLootContainer(PLAYER_ACTION_MODAL[player:getId()])
        return true
    end

    player:setLootContainer(PLAYER_ACTION_MODAL[player:getId()], container)
    player:sendAutoloot()
    return true
end
