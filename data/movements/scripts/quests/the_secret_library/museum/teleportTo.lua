local teleports = {
	[1] = {fromPos = Position(33246, 32107, 8), toPos = Position(33246, 32096, 8),
		storage = Storage.secretLibrary.MoTA.Questline, nivel = 2, nextValue = 3},
	[2] = {fromPos = Position(33246, 32098, 8), toPos = Position(33246, 32109, 8),
		storage = Storage.secretLibrary.MoTA.Questline, nivel = 2},
}

local lastroom_enter = Position(33344, 32117, 10)
local lastroom_exit = Position(33365, 32147, 10)

local function sendFire(position)
	for x = position.x - 1, position.x + 1 do 
		local newPos = Position(x, position.y, position.z)
		newPos:sendMagicEffect(CONST_ME_FIREATTACK)
	end
end

function onStepIn(creature, item, position, fromPosition)
	if not creature:isPlayer() then
		return false
	end
	local player = Player(creature:getId())
	if item.actionid == 4905 then
		for _, p in pairs(teleports) do
			if (position == p.fromPos) then
				if player:getStorageValue(p.storage) >= p.nivel then
					player:teleportTo(p.toPos)
					sendFire(p.toPos)
					if p.nextValue and player:getStorageValue(p.storage) < p.nextValue then
						player:setStorageValue(p.storage, p.nextValue)
					end
				else
					player:teleportTo(fromPosition, true)
				end	
			end
		end
	elseif item.actionid == 4906 then
		local hasPermission = false
		if player:getStorageValue(Storage.secretLibrary.MoTA.yellowGem) >= 1 and player:getStorageValue(Storage.secretLibrary.MoTA.greenGem) >= 1
		and player:getStorageValue(Storage.secretLibrary.MoTA.redGem) >= 1 then
			hasPermission = true
		end
		if not hasPermission then
			player:teleportTo(Position(33226, 32084, 9))
		end
	elseif item.actionid == 4907 then
		if position == lastroom_enter then
			player:teleportTo(Position(33363, 32146, 10))
		elseif position == lastroom_exit and player:getStorageValue('trialTimer') < os.stime() then
			player:teleportTo(Position(33336, 32117, 10))
		-- Trial
		else
			if player:getStorageValue(Storage.secretLibrary.MoTA.Questline) < 6 then
				player:setStorageValue('trialTimer', os.stime() + 3*60)
				player:setStorageValue(Storage.secretLibrary.MoTA.Questline, 6)
				player:say('rkawdmawfjawkjnfjkawnkjnawkdjawkfmalkwmflkmawkfnzxc', TALKTYPE_MONSTER_SAY)
			end
		end
	end
	return true
end
