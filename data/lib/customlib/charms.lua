function Player.sendCharmWindow(self)
	local id = Modal.Cyclopedia.Charm[1]
	local title = "Charms"
	local desc = "Charm list"
	self:registerEvent("ModalWindow_cyclopedia")
	local modalWindow = ModalWindow(id, title, desc)

	for _, charm in pairs(Game.getCharms()) do
		if not self:isUnlockedCharm(charm.id) then
			modalWindow:addChoice(charm.id, string.format("%s %s", charm.name, "[Buy]"))
		end
	end

	modalWindow:addButton(101, "Select")
	modalWindow:addButton(100, "Close")

	modalWindow:setDefaultEnterButton(101)
	modalWindow:setDefaultEscapeButton(100)
	modalWindow:sendToPlayer(self)
end

local function getCharm(id)
	for _, charm in pairs(Game.getCharms()) do
		if charm.id == id then
			return charm
		end
	end

	return false
end

function Player.sendCharmInfo(self, charmid)
	local charm = getCharm(charmid)
	if not charm then
		return false
	end
	local selected = "Yes"
	if self:getCurrentCreature(charm.id) > 0 then
		local monster = MonsterType(self:getCurrentCreature(charm.id))
		if monster then
			selected = "[" ..monster:getName().."]"
		end
	end
	local desc = string.format("Charm: %s\n\nUnlocked: %s\n\nPrice: %d\n\nDescription: %s\n\n\n\nYour charm points: %d", charm.name, (self:isUnlockedCharm(charm.id) and selected or "No"),charm.price, charm.description, self:getCharmPoints())
	local id = Modal.Cyclopedia.Charm[2]
	local title = "Charms"
	self:registerEvent("ModalWindow_cyclopedia")
	local modalWindow = ModalWindow(id, title, desc)

	if self:isUnlockedCharm(charm.id) or self:getCharmPoints() >= charm.price then
		modalWindow:addButton(101, (self:isUnlockedCharm(charm.id) and "Ok" or "Buy"))
	end
	modalWindow:addButton(100, "Close")

	modalWindow:setDefaultEnterButton(101)
	modalWindow:setDefaultEscapeButton(100)
	modalWindow:sendToPlayer(self)
end

function isCharmModal(id)
	for i=1,#Modal.Cyclopedia.Charm do
		if Modal.Cyclopedia.Charm[i] == id then
			return true
		end
	end

	return false
end
