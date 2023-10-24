local skullPosition = Position(33348, 32117, 10)
function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if target:getPosition() == skullPosition and player:getStorageValue(Storage.secretLibrary.MoTA.skullSample) ~= 1 then
		item:remove(1)
		player:setStorageValue(Storage.secretLibrary.MoTA.skullSample, 1)
	end
	return true
end



