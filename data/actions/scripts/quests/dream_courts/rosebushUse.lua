local earthPosition = Position(32014, 32035, 13)
local Rosebush = Storage.DreamCourts.TheSevenKeys.Rosebush
local keysCount = Storage.DreamCourts.TheSevenKeys.Count 

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not player then
		return true
	end
	local tPos = target:getPosition()
	if tPos == earthPosition then
		if player:getStorageValue(Rosebush) <= 1 then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You plant the rosebush into the fresh soil. The green portal glows brighter. Perhaps you may pass it now.")
			player:setStorageValue(Rosebush, 2)
			if player:getStorageValue(keysCount) < 0 then
				player:setStorageValue(keysCount, 0)
			end
			player:setStorageValue(keysCount, player:getStorageValue(keysCount) + 1)
			tPos:sendMagicEffect(CONST_ME_SMALLPLANTS)
		else
			return false
		end
	else
		return false
	end
	return true
end