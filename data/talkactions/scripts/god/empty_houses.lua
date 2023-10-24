function onSay(player, words, param)
    if not player:getGroup():getAccess() then
        return true
    end

    if player:getGroup():getId() < 6 then
        return true
    end

    for _, house in ipairs(Game.getHouses()) do
        if house:getOwnerGuid() == 0 then
            --
        else
            house:setOwnerGuid(0)
            house:setAccessList(256, "")
            house:setAccessList(257, "")
            house:setAccessList(1, "")
        end
    end

    print("Items moved to depot.")

    return false
end
