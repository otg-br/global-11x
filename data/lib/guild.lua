--[[
guild:registerAction(playerid, amount, type)
type = GUILDBANK_DEPOSIT or GUILDBANK_WITHDRAW
--]]

GUILDBANK_DEPOSIT = 1
GUILDBANK_WITHDRAW = -1

function getGuildIdByName(name)
	local queryStr = string.format("SELECT `id` FROM `guilds` WHERE `name` = %s", db.escapeString(name))
    local resultId = db.storeQuery(queryStr)
	if resultId ~= false then
		local val = result.getNumber(resultId, "id")
		result.free(resultId)
		return val
	end

	return false
end

function Guild.getMembersGuid(self)
	local guildMembers = {}
	local queryStr = string.format("SELECT `players`.`name` AS 'name' FROM `players` INNER JOIN `guild_membership` ON (`players`.`id` = `guild_membership`.`player_id`) WHERE `guild_membership`.`guild_id` = %d;", self:getId())
	local resultId = db.storeQuery(queryStr)
	if resultId ~= false then
		repeat
			local val = result.getString(resultId, "name")
			table.insert(guildMembers, val)
		until not result.next(resultId)
	end
	result.free(resultId)
	return guildMembers
end

function Guild.registerAction(self, pid, amount, type)
    local p = Player(pid)
	local p_id = p:getGuid()
    
    -- The NPCs already check this, but I'll do it just for be sure that the function won't be used wrong
    if not p:getGuild() or (p:getGuild():getId() ~= self:getId()) then
        error('>> This player is not inside the guild.')
        return true
    elseif p:getGuildLevel() < 2 and type == GUILDBANK_WITHDRAW then
        error('>> This player cannot perform this action because his rank is too low.')
        return true
    end
    
    local newAmount = amount*type
    db.query('INSERT INTO `guild_actions_h` (`guild_id`, `player_id`, `value`, `date`, `type`) VALUES ('..self:getId()..','..p_id..','..newAmount..','..os.stime()..', '..type..')')
end

function Guild.transferToGuild(self, pid, amount, _toGuild, info)
	local toGuild = Guild(_toGuild) -- Isso aqui não tá conseguindo criar a guild (corrigir dps, daí o sistema já deve funcionar)
	local player = Player(pid)
	if player then
		if not toGuild then
			info.success = false
			info.message = 'We are sorry to inform you that we could not fulfil your request, because we could not find the recipient guild.'
		else
			local fromBalance = self:getBalance()
			if fromBalance < amount then
				info.success = false
				info.message = 'We are sorry to inform you that we could not fulfill your request, due to a lack of the required sum on your guild account.'
			else
				info.success = true
				info.message = 'We are happy to inform you that your transfer request was successfully carried out.'
				self:setBalance(fromBalance - amount)
				toGuild:setBalance(toGuild:getBalance() + amount)
				db.query('INSERT INTO `guild_transfer_h` (`player_id`, `from_guild_id`, `to_guild_id`, `value`, `date`) VALUES ('..player:getGuid()..', '..self:getId()..','..toGuild:getId()..','..amount..','..os.stime()..')')
			end
		end
		local inbox = player:getInbox()
		local receipt = gb_getReceipt(info)
		inbox:addItemEx(receipt, INDEX_WHEREEVER, FLAG_NOLIMIT)
	end
	return true
end

function gb_getReceipt(info)
	local receiptFormat = 'Date:\n%s\nType:\n%s\nGold Amount:\n%d\nReceipt Owner:\n%s\nRecipient:\n%s\n\n%s'
    local receipt = Game.createItem(2597)
	if receipt then
		if info.success then
			receipt:setAttribute(ITEM_ATTRIBUTE_DESCRIPTION, "This receipt serves as a reference to a successful guild bank transfer.")
		else
			receipt:setAttribute(ITEM_ATTRIBUTE_DESCRIPTION, "This receipt serves as a reference to an unsuccessful guild bank transfer.")
		end
		receipt:setAttribute(ITEM_ATTRIBUTE_WRITER, "Guild Bank System")
		receipt:setAttribute(ITEM_ATTRIBUTE_TEXT, receiptFormat:format(os.sdate('%d. %b %Y - %H:%M:%S'), info.type, info.amount, info.owner, info.recipient, info.message))
	end
    return receipt
end