function onSay(player, word, param)
	if not isInArray({SKULL_BLACK, SKULL_RED}, player:getSkull() ) then
		player:sendCancelMessage("You don't have a skull.")
		return false
	end
	local fragtime = player:getSkullTime()
	if fragtime <= 0 then
		player:sendCancelMessage("Your frag has already run out.")
		return false
	end

	player:sendCancelMessage(string.format("Your skull will last until %s.", os.date("%d.%m.%Y", os.time()+(fragtime/1000))))
	return false
end