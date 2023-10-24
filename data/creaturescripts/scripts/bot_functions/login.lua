function onLogin(player)
	if player:getStorageValue(AUTOHEAL_STORAGE_PERCENTAGE_HEALTH) ~= -1 and
	player:getStorageValue(AUTOHEAL_STORAGE_SAY) ~= -1 then
		player:registerEvent("AutoHeal")
	end
	return true
end
