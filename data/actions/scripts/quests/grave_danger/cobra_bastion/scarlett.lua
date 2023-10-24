local info = {
	bossName = "Scarlett Etzel",
	middle = Position(33395, 32662, 6),
	fromPos = Position(33385, 32638, 6),
	toPos = Position(33406, 32660, 6),
	exitPos = Position(33395, 32670, 6),
	timer = Storage.GraveDanger.CobraBastion.ScarlettTimer,
	armorId = 36196,
	armorPos = Position(33398, 32640, 6)
}

local transformTo = {
	[36188] = 36189,
	[36189] = 36190,
	[36190] = 36191,
	[36191] = 36188
}

--[[
	Explicando a storage do monstro:
		1 - start
]]

local function createArmor(id, amount, pos)
	local armor = Game.createItem(id, amount, pos)
	if armor then armor:setActionId(4962) end 
end

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local playersTable = {}
	if item.actionid == 4961 then
		if doCheckBossRoom(player:getId(), info.bossName, info.fromPos, info.toPos) then
			for x = info.middle.x - 1, info.middle.x + 1 do
				for y = info.middle.y - 1, info.middle.y + 1 do
					local sqm = Tile(Position(x, y, 6))
					if sqm and sqm:getGround():getId() == 20293 then
						local player_ = sqm:getTopCreature()
						if player_ and player_:isPlayer() then
							if player_:getStorageValue(info.timer) > os.stime() then
								player_:getPosition():sendMagicEffect(CONST_ME_POFF)
								player_:sendCancelMessage('You are still exhausted from your last battle.')
								return true
							end
							table.insert(playersTable, player_:getId())
						end
					end
				end
			end
			for _, p in pairs(playersTable) do
				local nPlayer = Player(p)
				if nPlayer then
					nPlayer:teleportTo(Position(33395, 32656, 6))
					nPlayer:setStorageValue(info.timer, os.stime() + 20*60*60)
				end
			end
			local scarlett = Game.createMonster("Scarlett Etzel", Position(33396, 32640, 6))
			if scarlett then
				scarlett:registerEvent('scarlettThink')
				scarlett:registerEvent('scarlettHealth')
				scarlett:setStorageValue(Storage.GraveDanger.CobraBastion.Questline, 1)
			end
			SCARLETT_MAY_TRANSFORM = 0
			addEvent(kickPlayersAfterTime, 30*60*1000, playersTable, info.fromPos, info.toPos, info.exitPos)
		end
	elseif item.actionid == 4962 then
		if isInArray(transformTo, item.itemid) then
			local pilar = transformTo[item.itemid]
			if pilar then
				item:transform(pilar)
				item:getPosition():sendMagicEffect(CONST_ME_POFF)
			end
		elseif item.itemid == info.armorId then
			item:getPosition():sendMagicEffect(CONST_ME_THUNDER)
			item:remove(1)
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You hold the old chestplate of Galthein in front of you. It does not fit and far too old to withstand any attack.")
			addEvent(createArmor, 20*1000, info.armorId, 1, info.armorPos)
			SCARLETT_MAY_TRANSFORM = 1
			addEvent(function()
				SCARLETT_MAY_TRANSFORM = 0
			end, 6*1000)
		end
	end
	return true
end
