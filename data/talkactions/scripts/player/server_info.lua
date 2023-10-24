local melee = {
	[1] = {name = "Sword", skill = SKILL_SWORD},
	[2] = {name = "Axe", skill = SKILL_AXE},
	[3] = {name = "Club", skill = SKILL_CLUB},
	[4] = {name = "Distance", skill = SKILL_DISTANCE}
}

function onSay(player, words, param)
	local string_ = ""
	for _, s in pairs(melee) do
		string_ = string_ .. s.name .. " -> " .. Game.getSkillStage(player:getSkillLevel(s.skill)) .. " | "
	end
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Server Info:"
					.. "\nExp rate: " .. Game.getExperienceStage(player:getLevel())
					.. "\nSkill rate: " .. string_
					.. "\nMagic rate: " .. Game.getMagicLevelStage(player:getMagicLevel())
					.. "\nLoot rate: " .. configManager.getNumber(configKeys.RATE_LOOT))
	return false
end
