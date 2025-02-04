local event = Event()
event.onDisband = function(self, player)
	-- Empty
	return true
end

event:register()