function onSay(player, word, param)
	if player:getGroup():getId() < 6 then
		return true
	end
	
	local split = param:split(",")
	
	if split[2] == nil then
		player:sendCancelMessage("You must specify a mount ID.")
		return false
	elseif not tonumber(split[2]) then
		player:sendCancelMessage("The ID must be a number.")
		return false
	end
	
	local target = Player(split[1])
	if target == nil then
		player:sendCancelMessage("A player with that name is not online.")
		return false
	end
	if target:hasMount(split[2]) then
		player:sendCancelMessage("The player already have this mount.")
	else
		target:addMount(split[2])
		player:sendCancelMessage("Mount with ID: ".. split[2] .." added to player " .. target:getName())
	end
	return false
end