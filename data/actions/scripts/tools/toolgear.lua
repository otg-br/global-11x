local oldTable = {Position(32005, 32002, 14), Position(32005, 32003, 14), Position(32006, 32002, 14), Position(32006, 32003, 14)}
local foundItems = {
	{id = 34485, qnt = 1},
	{id = 8309, qnt = 4}
}
local storage = Storage.DreamCourts.TheSevenKeys.Lock

local secret_library = {
	crystals = {
		[1] = {storage = Storage.secretLibrary.MoTA.Crystal1, position = Position(33216, 32108, 9)},
		[2] = {storage = Storage.secretLibrary.MoTA.Crystal2, position = Position(33242, 32100, 9)},
		[3] = {storage = Storage.secretLibrary.MoTA.Crystal3, position = Position(33226, 32103, 9)},
		[4] = {storage = Storage.secretLibrary.MoTA.Crystal4, position = Position(33236, 32084, 9)},
		[5] = {storage = Storage.secretLibrary.MoTA.Crystal5, position = Position(33260, 32103, 9)},
		[6] = {storage = Storage.secretLibrary.MoTA.Crystal6, position = Position(33260, 32103, 9)},
		[7] = {storage = Storage.secretLibrary.MoTA.Crystal7, position = Position(33260, 32103, 9)},
		[8] = {storage = Storage.secretLibrary.MoTA.Crystal8, position = Position(33260, 32103, 9)}
	},
	timer = 'tsl_crystaltimer',
	exhaustMessage = 'Digging crystal is exhausting. You\'re still weary from your last prospect.',
	items = {32455,32456,32457}
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local tPos = toPosition
	-- Dream Courts Quest
	for i = 1, #oldTable do
		if tPos == oldTable[i] then
			if player:getStorageValue(storage) < 1 then
				for j = 1, #foundItems do
					player:addItem(foundItems[j].id, foundItems[j].qnt)			
				end
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "This table is made of several old doors. One of them has a noticeable ornate lock. Perhaps you could lever it out with a tool.")
				player:setStorageValue(storage, 1)
			else
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You already removed the old lock.")				
			end
			return true
		end
	end
	-- The Secret Library
	for _, j in pairs(secret_library.crystals) do
		if tPos == j.position then
			if player:getStorageValue(j.storage) < os.stime() then
				local r = math.random(1,3)
				local item_id = secret_library.items[r]
				player:addItem(item_id, 1)
				player:say('You have found a ' .. ItemType(item_id):getName() .. '.', TALKTYPE_MONSTER_SAY)
				player:setStorageValue(j.storage, os.stime() + 2*60)
			else
				player:say(secret_library.exhaustMessage, TALKTYPE_MONSTER_SAY)				
			end
			return true
		end
	end
	return onUseRope(player, item, fromPosition, target, toPosition, isHotkey)
		or onUseShovel(player, item, fromPosition, target, toPosition, isHotkey)
		or onUsePick(player, item, fromPosition, target, toPosition, isHotkey)
		or onUseMachete(player, item, fromPosition, target, toPosition, isHotkey)
		or onUseCrowbar(player, item, fromPosition, target, toPosition, isHotkey)
		or onUseSpoon(player, item, fromPosition, target, toPosition, isHotkey)
		or onUseScythe(player, item, fromPosition, target, toPosition, isHotkey)
		or onUseKitchenKnife(player, item, fromPosition, target, toPosition, isHotkey)
end
