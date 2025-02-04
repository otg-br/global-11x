local event = Event()
event.onJoin = function(self, player, skill, tries)
	if not player then
		return false
	end

	player:broadcastUpdateInfo(CONST_PARTY_BASICINFO, player:getId())
	player:broadcastUpdateInfo(CONST_PARTY_MANA, player:getId())
	player:broadcastUpdateInfo(CONST_PARTY_UNKNOW, player:getId())
	player:broadcastInfo(true)

	return true
end
event:register()
