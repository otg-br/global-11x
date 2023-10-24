local steps = {
	[1] = {
		title = "Bestiary",
		desc = "Choose a category",
		id = Modal.Cyclopedia.Bestiary[1]
	},
	[2] = {
		title = "Bestiary",
		desc = "Choose a monster",
		id = Modal.Cyclopedia.Bestiary[2]
	},
	[3] = {
		title = "Bestiary",
		desc = "Monster name: %s\nKills: %d/%d\n\nCharm point: %s",
		id = Modal.Cyclopedia.Bestiary[3]
	}
}

if not playerOptionBest then
	playerOptionBest = {}
end

function Player.sendBestiaryWindow(self, step, option)
	local modal = steps[step]
	if not modal then
		return true
	end
	if step == 3 then
		return
	end

	local title = string.format("%s", modal.title)
	local desc = string.format("%s", modal.desc)
	self:registerEvent("ModalWindow_cyclopedia")
	local modalWindow = ModalWindow(modal.id, title, desc)

	if step == 1 then
		for id, name in pairs(Game.getBestiaries()) do
			modalWindow:addChoice(id, name)
		end
		playerOptionBest[self:getId()] = {}

	elseif step == 2 then
		if not option or type(option) ~= "string" then
			return false
		end
		local bestiary = Bestiary(option)
		if not bestiary then
			return false
		end

		local races = bestiary:getRaces()
		local id = 0
		for i, race in pairs(races) do
			local monster = MonsterType(race[1])
			if monster then
				id = id + 1
				modalWindow:addChoice(id, monster:getName())
			end
		end
	end

	modalWindow:addButton(101, "Select")
	modalWindow:addButton(100, "Close")

	modalWindow:setDefaultEnterButton(101)
	modalWindow:setDefaultEscapeButton(100)
	modalWindow:sendToPlayer(self)
end

function Player.sendBestiaryMonster(self, monsterid)
	local modal = steps[3]
	if not modal then
		return true
	end
	local monster = MonsterType(monsterid)
	if not monster then
		return false
	end

	local bestiary = Bestiary(monsterid)
	if not bestiary then
		return false
	end
	local entry = bestiary:getRaceByID(monsterid)
	if not entry then
		return false
	end

	local difficulty = bestiary:getDifficulty(entry.difficulty, entry.rare)
	if not difficulty then
		return false
	end

	playerOptionBest[self:getId()] = monsterid
	local title = string.format("%s", modal.title)
	local charmpoints = string.format("%d%s", difficulty.charm, self:getBestiaryKill(monsterid) >= difficulty.final and " (gained)" or "")
	local desc = string.format(modal.desc, monster:getName(), self:getBestiaryKill(monsterid), difficulty.final, charmpoints)
	if self:getBestiaryKill(monsterid) >= difficulty.final then
		local charmName = "none"
		if self:getMonsterCharm(monsterid) > -1 then
			for _, charm in pairs(Game.getCharms()) do
				if charm.id == self:getMonsterCharm(monsterid) then
					charmName = charm.name
				end
			end
		end
		desc = string.format("%s\n\nCurrent charm: %s", desc, charmName)
	end

	self:registerEvent("ModalWindow_cyclopedia")
	local modalWindow = ModalWindow(modal.id, title, desc)

	modalWindow:addButton(100, "Close")
	modalWindow:addButton(101, "Ok")
	if self:getBestiaryKill(monsterid) >= difficulty.final then
		modalWindow:addButton(102, "Charm")
	end

	modalWindow:setDefaultEnterButton(101)
	modalWindow:setDefaultEscapeButton(100)
	modalWindow:sendToPlayer(self)
end

function Player.sendCharmCreature(self, monsterid)
	local monster = MonsterType(monsterid)
	if not monster then
		return false
	end

	local bestiary = Bestiary(monsterid)
	if not bestiary then
		return false
	end
	local entry = bestiary:getRaceByID(monsterid)
	if not entry then
		return false
	end

	local difficulty = bestiary:getDifficulty(entry.difficulty, entry.rare)
	if not difficulty then
		return false
	end

	if self:getBestiaryKill(monsterid) < difficulty.final then
		return false
	end

	local count = 0
	for _, charm in pairs(Game.getCharms()) do
		if self:isUnlockedCharm(charm.id) and self:getCurrentCreature(charm.id) == 0 then
			count = count + 1
		end
	end
	if count == 0 then
		player:popupFYI("You dont have charm")
		return true
	end

	self:registerEvent("ModalWindow_cyclopedia")
	local modalWindow = ModalWindow(Modal.Cyclopedia.Bestiary[4], "Charm", "Select charm")

	for _, charm in pairs(Game.getCharms()) do
		if self:isUnlockedCharm(charm.id) and self:getCurrentCreature(charm.id) == 0 then
			modalWindow:addChoice(charm.id, charm.name)
		end
	end

	modalWindow:addButton(100, "Close")
	modalWindow:addButton(101, "Ok")

	modalWindow:setDefaultEnterButton(101)
	modalWindow:setDefaultEscapeButton(100)
	modalWindow:sendToPlayer(self)

end

function isBestiaryModal(id)
	for i=1,#Modal.Cyclopedia.Bestiary do
		if Modal.Cyclopedia.Bestiary[i] == id then
			return true
		end
	end

	return false
end
