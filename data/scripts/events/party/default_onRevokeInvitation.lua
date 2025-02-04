local event = Event()
event.onRevokeInvitation = function(self, player)
	-- Empty
	return true
end

event:register()