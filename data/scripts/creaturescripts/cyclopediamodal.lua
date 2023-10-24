local modalWindowEvent = CreatureEvent("ModalWindow_cyclopedia")

local function getPassModal(modalWindowId)
	local pass = 0
	for id, modalid in pairs(Modal.Cyclopedia.Bestiary) do
		if modalid == modalWindowId then
			pass = id
			break
		end
	end
	for id, modalid in pairs(Modal.Cyclopedia.Charm) do
		if modalid == modalWindowId then
			pass = id
			break
		end
	end

	return pass
end

function modalWindowEvent.onModalWindow(player, modalWindowId, buttonId, choiceId)
	player:unregisterEvent("ModalWindow_cyclopedia")
	if buttonId == 100 then
		return true
	end

	local pass = getPassModal(modalWindowId)
	if isBestiaryModal(modalWindowId) then
		if buttonId == 101 then
			if pass == 1 then
				local option = false
				for id, name in pairs(Game.getBestiaries()) do
					if id == choiceId then
						option = name
					end
				end
				if option then
					playerOptionBest[player:getId()] = option
					player:sendBestiaryWindow(2, option)
				end
			elseif pass == 2 then
				if not playerOptionBest[player:getId()] then
					return true
				end

				local bestiary = Bestiary(playerOptionBest[player:getId()])
				if not bestiary then
					return false
				end

				local races = bestiary:getRaces()
				local id = 0
				for i, race in pairs(races) do
					local monster = MonsterType(race[1])
					if monster then
						id = id + 1
						if id == choiceId then
							playerOptionBest[player:getId()] = monster:getRaceId()
							player:sendBestiaryMonster(monster:getRaceId())
							break
						end
					end
				end
			end
		elseif buttonId == 102 then
			if pass == 3 then
				player:sendCharmCreature(playerOptionBest[player:getId()])
			end
		end
	elseif isCharmModal(modalWindowId) then
		if buttonId == 101 then
			if pass == 1 then
				player:sendCharmInfo(choiceId)
			end
		end
	end
	return true
end

modalWindowEvent:type("modalwindow")
modalWindowEvent:register()


-- talkactions
local bestiarytalk = TalkAction("!bestiary")

function bestiarytalk.onSay(player, word, param)
	if true then
		return true
	end
	if param == "" or not param then
		player:sendBestiaryWindow(1)
		return false
	end
	local monster = MonsterType(param)
	if not monster then
		player:sendCancelMessage("Monster not found")
		return false
	end

	player:sendBestiaryMonster(monster:getRaceId())

	return false
end

bestiarytalk:separator(" ")
bestiarytalk:register()

local charmtalk = TalkAction("!charm")

function charmtalk.onSay(player, word, param)
	if true then
		return true
	end
	if param == "" or not param then
		player:sendCharmWindow(1)
		return false
	end

	return false
end

charmtalk:separator(" ")
charmtalk:register()
-- End Talkactions
