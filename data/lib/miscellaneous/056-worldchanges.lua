-- example: 
-- nightmareIsle = false

Worldchanges = {
	[1] = {status = false, name = "Nightmare Isles"},
	[2] = {status = false, name = "Hive Outpost"},
	[3] = {status = false, name = "Fury Gates"}
}

local boardInfo = {
	itemId = 21570,
	position = Position(32208, 32296, 6)
}

-- Set the descripition on worldboard
local function setBoards()
	local str = "Active worldchanges:\n"
	for i = 1, #Worldchanges do
		if Worldchanges[i].status then
			str = str .. Worldchanges[i].name.."\n"
		end
	end
	local board = Tile(boardInfo.position):getItemById(boardInfo.itemId)
	if board then
		board:setAttribute(ITEM_ATTRIBUTE_DESCRIPTION, str)
	end
end

-- Used on another scripts
function setWorldChangeActive(name)
	for i = 1, #Worldchanges do
		if (Worldchanges[i].name):lower() == name:lower() then
			Worldchanges[i].status = true
		end
	end
	setBoards()
end