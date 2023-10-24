local options = {
    [1] = "Heal Impact",
    [2] = "Damage Impact",
    [3] = "Waste",
    [4] = "Loot Stats",
    [5] = "Experience",

}

function onModalWindow(player, modalWindowId, buttonId, choiceId)
	player:unregisterEvent("AnalyserWindow")
	if modalWindowId < Modal.analyserMain or modalWindowId > Modal.analyser5 then
		return true
	end

	if buttonId == 11 then
		return true
	end

	if Modal.analyserMain ~= modalWindowId and buttonId == 10 then
		player:makeBasicAnalyserModal()
		return true
	end

	if not options[choiceId] then return true end

	local title = '-- Analyser '.. options[choiceId] ..' Modal --'
	local desc = 'Press [BACK] to return to the main menu.\n\n\n'
	local choicesoptions = {}
	local choiceType = 1

	local function addChoice(key, value)
		local update = false
		for i, k in pairs(choicesoptions) do
			if k.key == key then
				k.count = value + k.count
				update = true
			end
		end
		if not update then
			choicesoptions[#choicesoptions + 1] = {key = key, count = value}
		end
	end

	local base = Modal.analyserMain + choiceId
	if choiceId == 1 then -- heal
		local amount = 0
		local inf = player:getHealTicks()
		local count = #inf
		for i, p in pairs(inf) do
			amount = amount + p[1]
		end

		desc = string.format("%sHeal media: %d\nHeal amount: %d", desc, math.max(0, amount/count), amount)
	elseif choiceId == 2 then -- Damage
		local amount = 0
		local inf = player:getDamageTicks()
		local count = #inf
		for i, p in pairs(inf) do
			amount = amount + p[1]
		end

		desc = string.format("%sDamage media: %d\nDamage amount: %d", desc, math.max(0, amount/count), amount)
	elseif choiceId == 3 then -- Waste
		local inf = player:getWasteTicks()
		for i, p in pairs(inf) do
			addChoice(p[1], 1)
		end
		local tmpDesc = "Waste static:\n"
		desc = string.format("%s%s", desc, tmpDesc)
	elseif choiceId == 4 then -- loot
		choiceType = 2
		local inf = player:getLootTicks()
		for i, p in pairs(inf) do
			addChoice(p[1], p[2])
		end
		local tmpDesc = "Loot stats:\n"
		desc = string.format("%s%s", desc, tmpDesc)
	elseif choiceId == 5 then -- Experience
		local amount = 0
		local inf = player:getExpTicks()
		local count = #inf
		for i, p in pairs(inf) do
			amount = amount + p[1]
		end
		local t = 0
		if inf[1] then
			t = inf[1][2]
		end
		local t2 = 0
		if inf[#inf] then
			t2 = inf[#inf][2]
		end
		local segs = os.sdate("%H:%M:%S", t2 - t)
		local tmm = count
		if count > 0 then
			tmm = amount/(t2 - t)
		end
		desc = string.format("%sExperience per seconds**: %d\n%s Hunting time\nExperience amount: %d", desc, math.max(0, tmm), segs, amount)

	else
		return true
	end
	player:registerEvent("AnalyserWindow")
	local window = ModalWindow(base, title, desc)

	if #choicesoptions > 0 then
		local last = 0
		for _, info in pairs(choicesoptions) do
			last = last + 1
			window:addChoice(last, string.format("%s %dx", ItemType(info.key):getName(), info.count))
		end
	end

	window:addButton(10, 'Back')
	window:setDefaultEnterButton(10)

	window:addButton(11,'Close')
	window:setDefaultEscapeButton(11)

	window:sendToPlayer(player)
	return true
end
