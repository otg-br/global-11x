function Party:onJoin(player)
	self:broadcastUpdateInfo(CONST_PARTY_BASICINFO, player:getId())
	self:broadcastUpdateInfo(CONST_PARTY_MANA, player:getId())
	self:broadcastUpdateInfo(CONST_PARTY_UNKNOW, player:getId())
	self:broadcastInfo(true)

	return true
end

function Party:onLeave(player)
	return true
end

function Party:onDisband()
	return true
end

local config = {
	{amount = 2, multiplier = 1.3},
	{amount = 3, multiplier = 1.6},
	{amount = 4, multiplier = 2}
}

function Party:onShareExperience(exp)
	local sharedExperienceMultiplier = 1.2 -- 20% if the same vocation
	local vocationsIds = {}
	local vocationId = self:getLeader():getVocation():getBase():getId()
	if vocationId ~= VOCATION_NONE then
		table.insert(vocationsIds, vocationId)
	end
	for _, member in ipairs(self:getMembers()) do
		vocationId = member:getVocation():getBase():getId()
		if not table.contains(vocationsIds, vocationId) and vocationId ~= VOCATION_NONE then
			table.insert(vocationsIds, vocationId)
		end
	end	
	local size = #vocationsIds
	for _, info in pairs(config) do
		if size == info.amount then
			sharedExperienceMultiplier = info.multiplier
		end
	end	
	exp = (exp * sharedExperienceMultiplier) / (#self:getMembers() + 1)
	return exp
end
