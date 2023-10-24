SELLCHARLEVEL = 150


if not playerSeeOffers then playerSeeOffers = {} end
if not playerBuyCharOffers then playerBuyCharOffers = {} end
if not playerSellCharOffers then playerSellCharOffers = {} end


function Player:getCurrentOffer()
	if not playerSeeOffers[self:getGuid()] then
		playerSeeOffers[self:getGuid()] = {}
	end

	return playerSeeOffers[self:getGuid()]
end
function Player:cleanOfferAction()
	playerSeeOffers[self:getGuid()] = {}
	playerBuyCharOffers[self:getGuid()] = {}
	playerSellCharOffers[self:getGuid()] = {}
end

function Player:getBuyCharacter()
	return playerBuyCharOffers[self:getGuid()] or 0
end
function Player:setBuyCharacter(guid)
	playerBuyCharOffers[self:getGuid()] = guid
end
function Player:getSellCharacter()
	return playerSellCharOffers[self:getGuid()] or {guid = 0, coin = 0, name = ''}
end
function Player:setSellCharacter(guid, coin, name)
	playerSellCharOffers[self:getGuid()] = {guid = guid, coin = coin, name = name}
end

function Player:makeSellPlayerModal(offers)
	self:registerEvent("ModalWindow_Offers")
	local modalWindow = ModalWindow(2400, "Player Offers", "Select one char\nYour coin balance: ".. self:getCoinsBalance())

	playerSeeOffers[self:getGuid()] = {}
	local id = 0
	for _, pid in pairs(offers) do
		id = id + 1
		playerSeeOffers[self:getGuid()][id] = pid
		modalWindow:addChoice(id, pid.name .. ": " .. pid.coin .. " coins")
	end

	modalWindow:addButton(101, "Select")
	modalWindow:addButton(100, "Cancel")

	modalWindow:setDefaultEnterButton(101)
	modalWindow:setDefaultEscapeButton(100)
	modalWindow:sendToPlayer(self)

end

function Player:makeSellPlayerModalDescription(description)
	self:registerEvent("ModalWindow_Offers")
	local modalWindow = ModalWindow(2402, "Player Offers", description)

	modalWindow:addButton(101, "Buy")
	modalWindow:addButton(100, "Cancel")

	modalWindow:setDefaultEnterButton(101)
	modalWindow:setDefaultEscapeButton(100)
	modalWindow:sendToPlayer(self)

end

function getPlayersByAccount(accountid)
	local resultId = db.storeQuery("SELECT `id`, `name`, `level`, `vocation`, `skill_fist`, `skill_club`, `skill_sword`, `skill_axe`, `skill_dist`, `skill_shielding`, `skill_fishing`, `maglevel` FROM `players` WHERE `account_id` = " .. accountid)
	local players = {}
	if resultId ~= false then
		repeat 
			local tplayer = {}
			tplayer.account = accountid
			tplayer.guid = result.getNumber(resultId, "id")
			tplayer.name = result.getString(resultId, "name")
			tplayer.level = result.getNumber(resultId, "level")
			tplayer.vocation = result.getString(resultId, "vocation")
			tplayer.skills = {
				fist = result.getNumber(resultId, "skill_fist"),
				club = result.getNumber(resultId, "skill_club"),
				sword = result.getNumber(resultId, "skill_sword"),
				axe = result.getNumber(resultId, "skill_axe"),
				distance = result.getNumber(resultId, "skill_dist"),
				shield = result.getNumber(resultId, "skill_shielding"),
				fishing = result.getNumber(resultId, "skill_fishing"),
				ml = result.getNumber(resultId, "maglevel"),
			}
			table.insert(players, tplayer)
		until not result.next(resultId)
	end
	result.free(resultId)

	return players
end

function Player:showAccountOffer()
	local players = getPlayersByAccount(self:getAccountId())
	self:registerEvent("ModalWindow_Offers")
	local modalWindow = ModalWindow(2401, "Your Players", "Select one char")

	playerSeeOffers[self:getGuid()] = {}
	local id = 0
	for _, pid in pairs(players) do
		playerSeeOffers[self:getGuid()][id + 1] = pid
		modalWindow:addChoice(id + 1, pid.name)
	end

	modalWindow:addButton(101, "Select")
	modalWindow:addButton(100, "Cancel")

	modalWindow:setDefaultEnterButton(101)
	modalWindow:setDefaultEscapeButton(100)
	modalWindow:sendToPlayer(self)
end

function Player:exectuteBuyChar(guid)
	local char = Game.getPlayerSellById(guid)
	if not char then
		self:popupFYI("This offer does not exist.")
		self:cleanOfferAction()
		return false
	end

	if char.account == self:getAccountId() then
		self:popupFYI("You cannot buy your own character.")
		self:cleanOfferAction()
		return false
	end

	local currentCoin = self:getCoinsBalance()
	if currentCoin - char.coin < 0 then
		self:popupFYI("You do not have enough money.")
		self:cleanOfferAction()
		return false
	end

	local player = Player(char.guid)
	if player then
		player:sendTextMessage(MESSAGE_STATUS_WARNING, "Is someone trying to buy your character, please log out.")
		self:sendTextMessage(MESSAGE_STATUS_WARNING, "The player is online, please try again later.")
		self:cleanOfferAction()
		return false
	end


	if self:removeCoinsBalance(char.coin) then
		local query1 = string.format("INSERT INTO `sell_players_history`(`player_id`, `accountold`, `accountnew`, `create`, `createip`, `buytime`, `buyip`, `coin`) VALUES (%d,%d,%d,%d,%d,%d,%d,%d)",
				char.guid,
				char.account,
				self:getAccountId(),
				char.create,
				char.createip,
				os.stime(),
				self:getIp(),
				char.coin
			)
		local query2 = string.format("UPDATE `players` SET `account_id` = %d WHERE `id` = %d;", self:getAccountId(), char.guid)
		local query3 = string.format("UPDATE `accounts` SET `coins` = `coins` + %d WHERE `id` = %d;", char.coin, char.account)
		local query4 = string.format("DELETE FROM `sell_players` WHERE `player_id` = %d", char.guid)
		db:query(query1)
		db:query(query2)
		db:query(query3)
		db:query(query4)
		Game.cleanPlayerSell(char.guid)
		return true
	end

	return false
end

function Player:makeConfirmCharSell()
	local info = self:getSellCharacter()
	if info.guid == 0 then
		self:popupFYI("You have no offer.")
		return true
	end
	self:registerEvent("ModalWindow_Offers")
	local modalWindow = ModalWindow(2403, "Player Offers", "Do you want to sell your character '" .. info.name .. "' for ".. info.coin .." coins?")

	modalWindow:addButton(101, "Yes")
	modalWindow:addButton(100, "No")

	modalWindow:setDefaultEnterButton(101)
	modalWindow:setDefaultEscapeButton(100)
	modalWindow:sendToPlayer(self)
end

function Player:canSellChar()
	local info = self:getSellCharacter()
	if info.guid == 0 then
		self:popupFYI("You have no offer.")
		return false
	end

	if info.coin <= 0 or info.coin >= 99999 then
		self:popupFYI("This offer is not possible.")
		return false
	end

	local players = getPlayersByAccount(self:getAccountId())
	local player = false
	for i, pid in pairs(players) do
		if pid.guid == info.guid then
			player = pid
			break
		end
	end

	if player.level < SELLCHARLEVEL then
		self:popupFYI("Minimum level for sale is ".. SELLCHARLEVEL ..".")
		return false
	end

	return Game.insertPlayerSell(info.guid, self:getAccountId(), os.stime(), self:getIp(), info.coin, info.name, player.vocation, player.skills, player.level, true)
end

function getOffersByAccountId(accountid)
	local players = {}
	local offers = Game.getPlayersSell()
	for _, pid in pairs(offers) do
		if pid.account == accountid then
			table.insert(players, pid)
		end
	end

	return players
end

function Player:makeMyCharOffers()
	local offers = getOffersByAccountId(self:getAccountId())
	if #offers == 0 then
		self:sendCancelMessage("You have no characters for sale.")
		return false
	end

	self:registerEvent("ModalWindow_Offers")
	local modalWindow = ModalWindow(2404, "Your Players", "Select one char")

	playerSeeOffers[self:getGuid()] = {}
	local id = 0
	for _, pid in pairs(offers) do
		playerSeeOffers[self:getGuid()][id + 1] = pid
		modalWindow:addChoice(id + 1, pid.name)
	end

	modalWindow:addButton(101, "Select")
	modalWindow:addButton(100, "Cancel")

	modalWindow:setDefaultEnterButton(101)
	modalWindow:setDefaultEscapeButton(100)
	modalWindow:sendToPlayer(self)
end

function Player:makeCancelChar(description)

	self:registerEvent("ModalWindow_Offers")
	local modalWindow = ModalWindow(2405, "Your Offers", description)

	modalWindow:addButton(101, "Remove")
	modalWindow:addButton(100, "Cancel")

	modalWindow:setDefaultEnterButton(101)
	modalWindow:setDefaultEscapeButton(100)
	modalWindow:sendToPlayer(self)
end

function Player:cancelCharOffer()
	local player = Game.getPlayerSellById(self:getBuyCharacter())
	if not player then
		self:popupFYI("This offer does not exist.")
		self:cleanOfferAction()
		return false
	end

	if player.account ~= self:getAccountId() then
		self:popupFYI("This character is not yours.")
		return false
	end

	local query = string.format("DELETE FROM `sell_players` WHERE `player_id` = %d", player.guid)
	db:query(query)
	Game.cleanPlayerSell(player.guid)
	self:cleanOfferAction()

	return true
end
