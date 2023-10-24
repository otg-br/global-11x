function onSay(player, words, param)
    --TODO: verifications here, exhaust maybe
    if player:getVocation():getId() == 0 and not player:getGroup():getAccess() then
        player:sendCancelMessage("You must reach mainland first.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end
    player:sendRewardWindow()
    return false
end
