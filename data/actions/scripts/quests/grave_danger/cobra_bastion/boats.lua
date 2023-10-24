local config = {
	[4978] = {teleportTo = Position(33385, 32627, 7), msg = "You bested the treacherous waters around this secluded island and are free to explore it shores and everything beyond.",
	questlineStorage = Storage.GraveDanger.CobraBastion.Questline, value = 1},
	[3591] = {teleportTo = Position(33313, 32647, 6)},
	minLevel = 250
}
function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local object = config[item.itemid]
	if not object then return true end
	if player:getLevel() < config.minLevel then 
		player:sendCancelMessage("You do not have enough level.")
		return true 
	end
	if object.questlineStorage and player:getStorageValue(object.questlineStorage) < object.value then
		player:setStorageValue(object.questlineStorage, object.value)
		if player:getStorageValue(Storage.GraveDanger.Questline) < 1 then
			player:setStorageValue(Storage.GraveDanger.Questline, 1)
		end
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, object.msg)
	end
	player:teleportTo(object.teleportTo)
	return true
end
