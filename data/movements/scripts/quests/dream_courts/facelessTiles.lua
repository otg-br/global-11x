local storage = GlobalStorage.DreamCourts.BurriedCatedral.facelessTiles

local function setActionId(itemid, position, aid)
	local item = Tile(position):getItemById(itemid)
	if item and item:getActionId() ~= aid then
		item:setActionId(aid)
	end
end

local function isnotImmortal()
	local spectators = Game.getSpectators(Position(33617, 32563, 13), false, false, 10, 10, 10, 10)
	for _, c in pairs(spectators) do
		if c:isMonster() then
			if c:getName():lower() == "faceless bane" then
				c:unregisterEvent("facelessHealth")
			end
		end
	end
end

function onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end
	local isImmortal = Game.getStorageValue(storage) -- Caso seja 5, ele está imortal
	if isImmortal == 5 then
		Game.setStorageValue(storage, 0)
		creature:getPosition():sendMagicEffect(CONST_ME_HOLYAREA)
		isnotImmortal()
	elseif isImmortal < 0 then
		Game.setStorageValue(storage, 0)
	elseif isImmortal >= 0 and isImmortal < 5 then
		Game.setStorageValue(storage, isImmortal + 1)
		creature:getPosition():sendMagicEffect(CONST_ME_YELLOWENERGY)
		item:setActionId(0)
		addEvent(setActionId, (10*1000), item.itemid, position, 23108)
	end
	
	return true
end