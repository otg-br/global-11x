if not analyzerHeal then
	analyzerHeal = {}
end

if not analyzerDamage then
	analyzerDamage = {}
end

if not analyzerExp then
	analyzerExp = {}
end

if not analyzerLoot then
	analyzerLoot = {}
end

if not analyzerWaste then
	analyzerWaste = {}
end

local function updateinfotable(tb, pos)
	if not pos then
		pos=2
	end
	local time = os.stime()-(1*60*60)
	for i, pid in pairs(tb) do
		if pid[pos] < time then
			table.remove(tb, i)
		end
	end

	return tb
end

function Player:addHealTicks(amount)
	if not analyzerHeal[self:getId()] then
		analyzerHeal[self:getId()] = {}
	end
  	local count = #analyzerHeal[self:getId()]
  	analyzerHeal[self:getId()][count + 1] = {amount, os.stime()}
	analyzerHeal[self:getId()] = updateinfotable(analyzerHeal[self:getId()])
	return true
end
function Player:addDamageTicks(amount)
	if not analyzerDamage[self:getId()] then
		analyzerDamage[self:getId()] = {}
	end

	local validAmount = tonumber(amount) or 0
	if validAmount <= 0 then
		return true
	end

  	local count = #analyzerDamage[self:getId()]
  	analyzerDamage[self:getId()][count + 1] = {math.abs(validAmount), os.stime()}
	analyzerDamage[self:getId()] = updateinfotable(analyzerDamage[self:getId()])
	return true
end

function Player:addExpTicks(amount)
	if not analyzerExp[self:getId()] then
		analyzerExp[self:getId()] = {}
	end

	local validAmount = tonumber(amount) or 0
	if validAmount <= 0 then
		return true
	end

  	local count = #analyzerExp[self:getId()]
  	analyzerExp[self:getId()][count + 1] = {math.abs(validAmount), os.stime()}
	analyzerExp[self:getId()] = updateinfotable(analyzerExp[self:getId()])
	return true
end

function Player:addWastTicks(itemid)
	if not analyzerWaste[self:getId()] then
		analyzerWaste[self:getId()] = {}
	end
  	local count = #analyzerWaste[self:getId()]
  	analyzerWaste[self:getId()][count + 1] = {itemid, os.stime()}
	analyzerWaste[self:getId()] = updateinfotable(analyzerWaste[self:getId()])
	return true
end

function Player:addLootTicks(itemid, amount)
	if not analyzerLoot[self:getId()] then
		analyzerLoot[self:getId()] = {}
	end
  	local count = #analyzerLoot[self:getId()]
  	analyzerLoot[self:getId()][count + 1] = {itemid, amount, os.stime()}
	analyzerLoot[self:getId()] = updateinfotable(analyzerLoot[self:getId()], 3)
	return true
end

function Player:getHealTicks()
	if not analyzerHeal[self:getId()] then
		analyzerHeal[self:getId()] = {}
	end

	return analyzerHeal[self:getId()]
end

function Player:getDamageTicks()
	if not analyzerDamage[self:getId()] then
		analyzerDamage[self:getId()] = {}
	end

	return analyzerDamage[self:getId()]
end
function Player:getExpTicks()
	if not analyzerExp[self:getId()] then
		analyzerExp[self:getId()] = {}
	end

	return analyzerExp[self:getId()]
end

function Player:getWasteTicks()
	if not analyzerWaste[self:getId()] then
		analyzerWaste[self:getId()] = {}
	end

	return analyzerWaste[self:getId()]
end

function Player:getLootTicks()
	if not analyzerLoot[self:getId()] then
		analyzerLoot[self:getId()] = {}
	end

	return analyzerLoot[self:getId()]
end

function Player:logoutEvent()
	analyzerWaste[self:getId()] = nil
	analyzerDamage[self:getId()] = nil
	analyzerHeal[self:getId()] = nil
	analyzerLoot[self:getId()] = nil
	analyzerExp[self:getId()] = nil
end
local options = {
	[1] = "Heal Impact",
	[2] = "Damage Impact",
	[3] = "Waste",
	[4] = "Loot Stats",
	[5] = "Experience",

}
function Player.makeBasicAnalyserModal(self)
	local title = "-- Analyser Modal --"
	local description = "Please choose an option and click [Ok]"
	local window = ModalWindow(Modal.analyserMain, title, description)
	self:registerEvent("AnalyserWindow")
	for i, p in pairs(options) do
		window:addChoice(i, p)
	end

	window:addButton(10, 'Ok')
	window:setDefaultEnterButton(10)

	window:addButton(11,'Close')
	window:setDefaultEscapeButton(11)

	window:sendToPlayer(self)
end
