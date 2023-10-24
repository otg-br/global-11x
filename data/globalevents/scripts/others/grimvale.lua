
local config = {
    fromPosition = Position(33415, 31522, 11), 
    toPosition = Position(33445, 31554, 11)
}


local function loadMap(name)
	Game.loadMap('data/world/worldchanges/feroxa/'..name..'.otbm')
end

local spawnByDay = true
local spawnDay = 14
local currentDay = os.sdate("%d")
local entrancePosition = Position(33457, 31529, 11)
local middlePosition = Position(33419, 31539, 10)

local function removeItems(fromPosition, toPosition)
	for x = fromPosition.x, toPosition.x do
		for y = fromPosition.y, toPosition.y do
			for z = fromPosition.z, toPosition.z do
				local tile = Tile(Position(x, y, z))
				if not tile then
					break
				end
				local items = tile:getItems()
				if items then
					for i = 1, #items do
						items[i]:remove()
					end
				end
				local ground = tile:getGround()
				if ground then
					ground:remove()
				end
			end
		end
	end
end

local function waitStage1()
	addEvent(function()
		Game.broadcastMessage('Half of the current full moon is visible now, there are still a lot of clouds in front of it', MESSAGE_EVENT_ADVANCE)
		removeItems(config.fromPosition, config.toPosition)
		loadMap('middle')
	end, 15*60*1000)
end

local function waitStage2()
	addEvent(function()
		Game.broadcastMessage('The full moon is completely exposed: Feroxa awaits!', MESSAGE_EVENT_ADVANCE)
		removeItems(config.fromPosition, config.toPosition)
		loadMap('final')
		addEvent(function()
			local teleport = Tile(entrancePosition):getItemById(1387)
			if teleport then
				teleport:remove(1)
			end
			local spectators = Game.getSpectators(middlePosition, false, true, 10, 10, 10, 10)
			for _, player in pairs(spectators) do
				if player then
					player:teleportTo(Position(33420, 31539, 10))
				end
			end
			local c = Game.getPlayers()[1]
			if c then
				c:say('You are the contenders. This is your only chance to break the Curse of the Full Moon. Make it count!', TALKTYPE_MONSTER_SAY, false, false, Position(33420, 31539, 10))
			end
			local feroxa = Game.createMonster('Feroxa', Position(33389, 31539, 11))
		end, 1*60*1000)
	end, 30*60*1000)
end

function onThink(interval, lastExecution)
	if FEROXA_ACTIVATED then
		return true
	end
	if spawnByDay then
		if not FEROXA_ACTIVATED then
			if spawnDay == tonumber(currentDay) then
				if os.stime() >= FEROXA_TIME then				
					FEROXA_ACTIVATED = true
					Game.broadcastMessage('Grimvale drowns in werecreatures as the full moon reaches its apex and ancient evil returns.', MESSAGE_EVENT_ADVANCE)
					local teleport = Game.createItem(1387, 1, entrancePosition)
					if teleport then 
						teleport:setDestination(Position(33426, 31538, 11)) 
						waitStage1()
						waitStage2()
					end
				end
			end
		end
	end
	return true
end
