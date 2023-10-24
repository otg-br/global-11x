local function removePortal(itemId, position)
	local item = Tile(position):getItemById(itemId)
	if item then
		item:remove(1)
	end
end

local function createPortal(itemId, position, actionId)
	local item = Game.createItem(itemId, 1, position)
	if item then
		item:setActionId(actionId)
	end
	addEvent(removePortal, 1*60*1000, itemId, position)
end

function onKill(creature, target, item)
	if not creature or not creature:isPlayer() then
		return true
	end
	if not target or not target:isMonster() then
		return true
	end
	local cName = target:getName():lower()
	if(isInArray({'cult enforcer', 'cult believer', 'cult scholar'}, cName)) then
		local corpsePosition = target:getPosition()
		local rand = math.random(1,2)
		if rand == 1 then
			createPortal(26140, corpsePosition, 5580)
		end
		if rand == 2 then
			createPortal(26138, corpsePosition, 5580)
		end
	end

	return true
end
