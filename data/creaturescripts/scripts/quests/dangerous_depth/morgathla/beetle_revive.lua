local morgathla = {
	[1] = {fromPos = Position(33703, 32362, 15), toPos = Position(33733, 32382, 15), storage = GlobalStorage.DangerousDepths.Morgathla.firstRoom, count = 30,
	bossPosition = Position(33724, 32372, 15), stage = 1},
	[2] = {fromPos = Position(33711, 32328, 15), toPos = Position(33738, 32359, 15), storage = GlobalStorage.DangerousDepths.Morgathla.secondRoom, count = 30,
	bossPosition = Position(33729, 32339, 15), stage = 2},
	[3] = {fromPos = Position(33741, 32340, 15), toPos = Position(33766, 32365, 15), storage = GlobalStorage.DangerousDepths.Morgathla.thirdRoom, count = 30,
	bossPosition = Position(33760, 32359, 15), stage = 3},
	[4] = {fromPos = Position(33764, 32326, 15), toPos = Position(33784, 32352, 15), storage = GlobalStorage.DangerousDepths.Morgathla.fourthRoom, count = 30,
	bossPosition = Position(33771, 32329, 15), stage = 4},
}

local reward = {
	Position(33783, 32317, 15),
	Position(33768, 32317, 15),
	Position(33756, 32328, 15),
}

function onDeath(creature, corpse, lasthitkiller, mostdamagekiller, lasthitunjustified, mostdamageunjustified)
	local cName = creature:getName()
	local cPos = creature:getPosition()
	local corpsePos = corpse:getPosition()
	local corpseId = corpse:getId()
	if cName:lower() == "hungry brood" then
		creature:say("The death of his brood enrages the giant scarab!", TALKTYPE_MONSTER_SAY)
		addEvent(function()
			local newCorpse = Tile(corpsePos):getItemById(corpseId)
			if newCorpse then
				newCorpse:setActionId(57371)
			end
		end, 1*1000)
	elseif cName:lower() == "ancient spawn of morgathla" then
		local teleport = Game.createItem(1387, 1, Position(33772, 32326, 15))
		if teleport then
			local r = math.random(1, #reward)
			teleport:setDestination(reward[r])
			addEvent(function(position, id)
				local item = Tile(position):getItemById(id)
				if item then
					item:remove(1)
				end
			end, 3*60*1000, teleport:getPosition(), teleport:getId())	
		end
	end
	return true
end

function onKill(player, creature)
	local cName = creature:getName()
	local cPos = creature:getPosition()
	if cName:lower() == 'burrowing beetle' then
		for _, k in pairs(morgathla) do
			if cPos:isInRange(k.fromPos, k.toPos) then
				if Game.getStorageValue(k.storage) < k.count then
					if Game.getStorageValue(k.storage) < 0 then
						Game.setStorageValue(k.storage, 1)
					end
					Game.setStorageValue(k.storage, Game.getStorageValue(k.storage)+1)
					if Game.getStorageValue(k.storage) == k.count then
						local monster = Game.createMonster("ancient spawn of morgathla", k.bossPosition)
						if monster then
							monster:setStorageValue("canHeal", 0)
							monster:registerEvent('morgathlaThink')
							Game.setStorageValue("morgathlaStage", k.stage)
						end
					end
				end
			end
		end
	end
end