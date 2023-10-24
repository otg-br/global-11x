local doors = {
	[1] = {key = 33033, position = Position(32813, 32813, 9)},
	[2] = {key = 33034, position = Position(32864, 32810, 9)}
}

local locked = 26541
local opened = 26545

local function revert(position)
	local lockedDoor = Tile(position):getItemById(opened)
	if lockedDoor then
		lockedDoor:transform(locked)
	end
end

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	for _, k in pairs(doors) do
		if item.itemid == k.key then
			if toPosition == k.position and target.itemid == locked then
				target:transform(opened)
				addEvent(revert, 10*1000, target:getPosition())
			end
		end
	end
	return true
end