local event = Event()
event.onGainSkillTries = function(self, skill, tries)

	if APPLY_SKILL_MULTIPLIER == false then
		return tries
	end

	if skill == SKILL_MAGLEVEL then
		return tries * configManager.getNumber(configKeys.RATE_MAGIC)
	end
	
	return tries * configManager.getNumber(configKeys.RATE_SKILL)
end

event:register(1)