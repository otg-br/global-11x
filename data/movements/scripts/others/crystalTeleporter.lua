local positions = {
	Gnomehub = Position(32624, 31870, 11)
}

function onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end
	if position == positions.Gnomehub then
		if player:getLevel() < 100 then
			player:sendCancelMessage("You must be level 100+ to enter in Gnomehub.")
			player:teleportTo(fromPosition)
		end
	end
	return true
end
