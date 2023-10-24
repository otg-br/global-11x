-- <action uniqueid="6000" script="quests/tinderBoxQuest.lua"/>

local config = {
	storage = 12450,
	hours = 20,
	item_id = 22728,
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if player:getStorageValue(config.storage) >= os.stime() then
		player:sendCancelMessage("The pile of bones is empty.")
		return true
	end
	player:addItem(config.item_id, 1)
	player:setStorageValue(config.storage, os.stime() + config.hours * 60 * 60)
	return true
end
