local loots = {
	[OBJECTCATEGORY_ARMORS] = "Armor",
	[OBJECTCATEGORY_NECKLACES] = "Amulet",
	[OBJECTCATEGORY_BOOTS] = "Boots",
	[OBJECTCATEGORY_CONTAINERS] = "Containers",
	[OBJECTCATEGORY_DECORATION] = "Decorations",
	[OBJECTCATEGORY_FOOD] = "Food",
	[OBJECTCATEGORY_HELMETS] = "Helmet",
	[OBJECTCATEGORY_LEGS] = "Legs",
	[OBJECTCATEGORY_OTHERS] = "Others",
	[OBJECTCATEGORY_POTIONS] = "Potions",
	[OBJECTCATEGORY_RINGS] = "Rings",
	[OBJECTCATEGORY_RUNES] = "Runes",
	[OBJECTCATEGORY_SHIELDS] = "Shields",
	[OBJECTCATEGORY_TOOLS] = "Tools",
	[OBJECTCATEGORY_VALUABLES] = "Valuables",
	[OBJECTCATEGORY_AMMO] = "Ammo",
	[OBJECTCATEGORY_AXES] = "Axes",
	[OBJECTCATEGORY_CLUBS] = "Clubs",
	[OBJECTCATEGORY_DISTANCEWEAPONS] = "Distance Weapons",
	[OBJECTCATEGORY_SWORDS] = "Swords",
	[OBJECTCATEGORY_WANDS] = "Wands",
	[OBJECTCATEGORY_CREATUREPRODUCTS] = "Creature Products",
	[OBJECTCATEGORY_GOLD] = "Golds",
	[OBJECTCATEGORY_DEFAULT] = "Default",
}

PLAYER_ACTION_MODAL = {}

function Player.sendAutoloot(self)
	local id = Modal.autoloot
	local title = "Autoloot"
	local desc = "Loot list"
	self:registerEvent("ModalWindow_autoloot")
	local modalWindow = ModalWindow(id, title, desc)

	for i = 0, 32 do
		if loots[i] then
			modalWindow:addChoice(i, string.format("%s", loots[i]))
		end
	end

	modalWindow:addButton(101, "Select")
	modalWindow:addButton(100, "Close")

	modalWindow:setDefaultEnterButton(101)
	modalWindow:setDefaultEscapeButton(100)
	modalWindow:sendToPlayer(self)
end

local function isEqualContainer(c1, c2)
	if not c1 or not c2 then
		return false
	end

	return c1 == c2
end

function Player.sendAutoLootContainer(self)
	if not PLAYER_ACTION_MODAL[self:getId()] then
		PLAYER_ACTION_MODAL[self:getId()] = OBJECTCATEGORY_DEFAULT
	end

	local id = Modal.autolootContainer
	local title = "Autoloot"
	local desc = "Container list - " .. loots[PLAYER_ACTION_MODAL[self:getId()]] or 'none'
	self:registerEvent("ModalWindow_autoloot")
	local modalWindow = ModalWindow(id, title, desc)

	local c1 = self:getLootContainer(loots[PLAYER_ACTION_MODAL[self:getId()]])
	local count = 0
	for id, container in pairs(self:getContainers()) do
		if count >= 32 then
			break;
		end
		if container:getId() ~= 26052 and (container:getId() ~= 2596) then
			count = count + 1
			modalWindow:addChoice(id, string.format("%d- %s%s", id, container:getName(), (isEqualContainer(c1, container) and " [CURRENT]" or '')) )
		end
	end

	modalWindow:addButton(101, "Select")
	modalWindow:addButton(100, "Close")

	modalWindow:setDefaultEnterButton(101)
	modalWindow:setDefaultEscapeButton(100)
	modalWindow:sendToPlayer(self)
end

