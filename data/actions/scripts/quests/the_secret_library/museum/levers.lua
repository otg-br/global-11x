local boneLever = Position(33204, 32069, 8)
local middleLever = Position(33251, 32039, 8)
local thirdLever = Position(33218, 32096, 10)

local transform = {
	[10029] = 10030,
	[10030] = 10029
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if player:getStorageValue(Storage.secretLibrary.MoTA.leverPermission) ~= 1 then
		if item:getPosition() == boneLever then
			if player:getStorageValue(Storage.secretLibrary.MoTA.Questline) == 3 then
				player:say('You don\'t know what to do.', TALKTYPE_MONSTER_SAY)
				player:setStorageValue(Storage.secretLibrary.MoTA.Questline, 4)
			elseif player:getStorageValue(Storage.secretLibrary.MoTA.Questline) == 5 then
				if player:getStorageValue('museumTimer') > os.stime() then
					player:say('back, back, up, right, left', TALKTYPE_MONSTER_SAY)
					player:setStorageValue(Storage.secretLibrary.MoTA.leverPermission, 1)
				else
					player:say('You\'re too late.', TALKTYPE_MONSTER_SAY)
					return true
				end
			end
		elseif item:getPosition() == middleLever then
			if item.itemid == 10029 then
				if player:getStorageValue(Storage.secretLibrary.MoTA.Questline) == 5 and player:getStorageValue('museumTimer') < os.stime() then
					player:say('As you turn the lever you can heart it ticking. Maybe you should hurry up!', TALKTYPE_MONSTER_SAY)
					player:setStorageValue('museumTimer', os.stime() + 2*60)
					item:transform(item.itemid + 1)
				end
			end
		end
	end
	if item:getPosition() == thirdLever and player:getStorageValue(Storage.secretLibrary.MoTA.finalBasin) ~= 1 then
		if player:getStorageValue('takenRod') < os.stime() then
			player:addItem(33211, 1)
			player:setStorageValue('takenRod', os.stime() + 2*60)
		else
			return true
		end
	end
	if item.itemid == 10029 or item.itemid == 10030 then
		item:transform(transform[item:getId()])
	end
	return true
end



