function Party.broadcastPartyLoot(self, corpse, mname, bonusPrey, hasCharm)
	local leader = self:getLeader()
	local text = corpse
	local textchannel = corpse
	if type(corpse) ~= "string" then
		text = corpse:getLoot(mname, leader:getClient().version, bonusPrey, hasCharm)
		textchannel = corpse:getLoot(mname, 1000, bonusPrey, hasCharm)
	end

	leader:sendTextMessage(MESSAGE_LOOT, text)
	leader:sendChannelMessage("", textchannel, TALKTYPE_CHANNEL_O, 10)

	local membersList = self:getMembers()
	for i = 1, #membersList do
		local player = membersList[i]
		if player then
			local text = corpse
			local textchannel = corpse
			if type(corpse) ~= "string" then
				text = corpse:getLoot(mname, player:getClient().version, bonusPrey, hasCharm)
				textchannel = corpse:getLoot(mname, 1000, bonusPrey, hasCharm)
			end
			player:sendTextMessage(MESSAGE_LOOT, text)
			player:sendChannelMessage("", textchannel, TALKTYPE_CHANNEL_O, 10)
		end
	end
end

function Party.broadcastPartyLootTracker(self, monster, corpse)
	self:getLeader():sendKillTracker(monster, corpse)
	local membersList = self:getMembers()
	for i = 1, #membersList do
		local player = membersList[i]
		if player then
			player:sendKillTracker(monster, corpse)
		end
	end
end

-- Party (12.30)
CONST_PARTY_BASICINFO = 0
CONST_PARTY_MANA = 11
CONST_PARTY_UNKNOW = 12

function Party.broadcastUpdateInfo(self, type, playerid)
	if true then
		return true
	end
	self:getLeader():updateMemberPartyInfo(type, playerid)
	local membersList = self:getMembers()
	for i = 1, #membersList do
		local player = membersList[i]
		if player then
			player:updateMemberPartyInfo(type, playerid)
		end
	end
end

function Party.broadcastInfo(self, update)
	if true then
		return true
	end
	self:getLeader():updateParty(update)
	local membersList = self:getMembers()
	for i = 1, #membersList do
		local player = membersList[i]
		if player then
			player:updateParty(update)
		end
	end
end

if not partyHuntTracker then
	partyHuntTracker = {}
end

function Party.getInfo(self)
	return partyHuntTracker[self:getId()] or {}
end

