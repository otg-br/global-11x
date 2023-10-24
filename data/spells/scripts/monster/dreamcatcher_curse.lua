local function placeMask(position, wmask, nmask)
	local item = Tile(position):getItemById(nmask)
	if item then
		item:transform(wmask)
	end
end

local maskId = 33769

local function resetArea()
	local infectedCount = 0
	local playerCount = 0
	local spectators = Game.getSpectators(Position(32206, 32045, 15), false, true, 14, 14, 14, 14)
	for _, p in pairs(spectators) do
		local player = Player(p:getId())
		if player then
			playerCount = playerCount + 1
			if player:getStorageValue(Storage.DreamCourts.DreamScar.lastBossCurse) >= 1 then
				infectedCount = infectedCount + 1
			end
		end
	end
	print("player count: "..playerCount.."     infected count: ".. infectedCount)
	if playerCount == infectedCount then
		return true
	else
		return false
	end
end

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not player then
		return true
	end
	if item.itemid == 33767 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You can rip off a dream catcher!")
		item:transform(33768)
		local newItem = Game.createItem(maskId, 1, Position(item:getPosition().x, item:getPosition().y+1, item:getPosition().z))
		if newItem then
			newItem:getPosition():sendMagicEffect(CONST_ME_BLOCKHIT)
		end
		addEvent(placeMask, 10*1000, item:getPosition(), 33767, 33768)
	elseif item.itemid == 33769 then
		if player:getStorageValue(Storage.DreamCourts.DreamScar.lastBossCurse) < 1 then
			if (target ~= player) and target:isPlayer() then
				if target:getStorageValue('nightmareCurse') >= 1 then
					target:setStorageValue('nightmareCurse', 0)
					target:removeCondition(CONDITION_OUTFIT)
					target:unregisterEvent('nightmareCurse')
					target:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have a feeling of dread.")
					player:setStorageValue('nightmareCurse', 1)
					player:registerEvent('nightmareCurse')
					player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You take the dreamcurse on yourself!")
					item:remove(1)
					local j = resetArea()
					if j then
						Game.setStorageValue(GlobalStorage.DreamCourts.DreamScar.lastBossCurse, 0)
					end
				else
					return true
				end
			else
				return true
			end
		else
			return true
		end
	end
	return true
end