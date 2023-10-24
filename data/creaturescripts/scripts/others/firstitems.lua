local config = {
	--club, coat
	items = {{2398, 1}, {2461, 1}, {2467, 1}, {2649, 1}},
	--container rope, shovel, red apple
	container = {{2120, 1}, {2554, 1}, {2674, 2}}

}

local function confirmAddItem(playerid)
	local player = Player(playerid)
	if not player then return end

	local targetVocation = config
	if not targetVocation then
		return true
	end

	if player:getLastLoginSaved() ~= 0 then
		return true
	end

	if (player:getSlotItem(CONST_SLOT_LEFT)) then
		return true
	end

	for i = 1, #targetVocation.items do
		player:addItem(targetVocation.items[i][1], targetVocation.items[i][2])
	end

	local backpack = player:getVocation():getId() == 0 and player:addItem(1987) or player:addItem(1988)
	if not backpack then
		return true
	end

	for i = 1, #targetVocation.container do
		backpack:addItem(targetVocation.container[i][1], targetVocation.container[i][2])
	end

	return true
end

function onLogin(player)

	addEvent(confirmAddItem, 2000, player:getGuid())

	return true
end
