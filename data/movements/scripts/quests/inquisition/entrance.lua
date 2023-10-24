local throneStorages = {
	Storage.PitsOfInferno.ThroneInfernatil,
	Storage.PitsOfInferno.ThroneTafariel,
	Storage.PitsOfInferno.ThroneVerminor,
	Storage.PitsOfInferno.ThroneApocalypse,
	Storage.PitsOfInferno.ThroneBazir,
	Storage.PitsOfInferno.ThroneAshfalor,
	Storage.PitsOfInferno.ThronePumin
}

local function hasTouchedOneThrone(pid)
	local player = Player(pid)
	if player then
		for i = 1, #throneStorages do
			if player:getStorageValue(throneStorages[i]) == 1 then
				return true
			end
		end
	end
	return false
end

function onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end	
	local mayPass = true
	if not hasTouchedOneThrone(player:getId()) then
		mayPass = false
	elseif  player:getLevel() < 100 then
		mayPass = false
	elseif player:getStorageValue(Storage.TheInquisition.Questline) < 18 then
		mayPass = false
	end	
	if mayPass then	
		local destination = Position(33168, 31683, 15)
		player:teleportTo(destination)
		position:sendMagicEffect(CONST_ME_TELEPORT)
		destination:sendMagicEffect(CONST_ME_TELEPORT)
		return true
	else
		player:teleportTo(fromPosition, true)
	end
end
