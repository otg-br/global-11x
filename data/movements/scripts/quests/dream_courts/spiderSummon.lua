local storage = Storage.DreamCourts.UnsafeRelease.Questline
local spiderName = "Lucifuga Aranea"

local function setActionId(itemid, position, aid)
	local item = Tile(position):getItemById(itemid)
	if item and item:getActionId() ~= aid then
		item:setActionId(aid)
	end
end

function onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end	
	if player:getStorageValue(Storage.DreamCourts.UnsafeRelease.hasBait) == 1 then
		local r = math.random(1, 10)
		Game.createMonster(spiderName, position)
		item:setActionId(0)
		addEvent(setActionId, r*(1000*60), item.itemid, position, 23120)
	end
	return true
end