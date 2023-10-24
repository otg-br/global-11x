local timer = 6 -- hours
local function spawnAgain(name, position)
	local monster = Game.createMonster(name, position, true, true)
	if monster then
		broadcastMessage(name .. " has been spawned!", MESSAGE_EVENT_ADVANCE)
	end
	return true
end

function onCreatureDisappear(self, creature)
	if self == creature then
		if self:getType():isRewardBoss() then
			self:setReward(true)
		end
		broadcastMessage(self:getName() .. " has been defeated! Next spawn in six (6) hours.", MESSAGE_EVENT_ADVANCE)
		addEvent(spawnAgain, timer * 60 * 60 * 1000, self:getName(), self:getPosition())
		return true
	end
end