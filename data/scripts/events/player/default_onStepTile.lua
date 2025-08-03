local event = Event()
event.onStepTile = function(self, fromPosition, toPosition)
	-- Exercise weapons
	local playerId = self:getId()
	if onExerciseTraining[playerId] then
		LeaveTraining(playerId)
		self:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You can't move while you train, the training has stopped.")
		return true
	end
	return true
end

event:register() 