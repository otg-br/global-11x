local event = Event()
event.onJoin = function(self, player, skill, tries)
	if not player then
		return false
	end

	local party = player:getParty()
	if party then
		party:broadcastUpdateInfo(CONST_PARTY_BASICINFO, player:getId())
		party:broadcastUpdateInfo(CONST_PARTY_MANA, player:getId())
		party:broadcastUpdateInfo(CONST_PARTY_UNKNOW, player:getId())
		party:broadcastInfo(true)
	end

	return true
end
event:register()
