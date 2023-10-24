local function placeFruits(position, fruit, nofruit)
	local item = Tile(position):getItemById(nofruit)
	if item then
		item:transform(fruit)
	end
end

local fruitId = 34488

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not player then
		return true
	end
	local r = math.random(2, 4)
	player:addItem(fruitId, r)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found some "..ItemType(fruitId):getName().."s.")
	item:transform(34463)
	item:getPosition():sendMagicEffect(CONST_ME_MAGIC_RED)
	addEvent(placeFruits, 1*60*60*1000, item:getPosition(), 34462, 34463)
	return true
end