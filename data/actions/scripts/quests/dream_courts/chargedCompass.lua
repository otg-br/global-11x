local wardPosition = Position(32769, 32621, 10)
local storage = Storage.DreamCourts.WardStones.porthopeStone
local count = Storage.DreamCourts.WardStones.Count

local function revertStone(position, on, off)
	local activeStone = Tile(position):getItemById(on)
	if activeStone then
		activeStone:transform(off)
	end
end

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not player then
		return true
	end
	local tPos = target:getPosition()
	local isInQuest = player:getStorageValue(Storage.DreamCourts.UnsafeRelease.Questline)
	if tPos == wardPosition then
		if isInQuest == 3 and player:getStorageValue(storage) < 1 then
			player:setStorageValue(count, player:getStorageValue(count) + 1)
			player:setStorageValue(storage, 1)			
			player:say("The energy is transferred to the rune stone. It glows now!", TALKTYPE_MONSTER_SAY)		
			target:getPosition():sendMagicEffect(CONST_ME_THUNDER)
			target:transform(33828)
			item:transform(33784)
			addEvent(revertStone, 1000*30, tPos, 33828, 33827)
		end
	end
	return true
end
