function onModalWindow(player, modalWindowId, buttonId, choiceId) 
	player:unregisterEvent("ModalWindow_Offers")
	if buttonId ~= 101 then
		player:cleanOfferAction()
		if buttonId == 100 and modalWindowId == 2403 then
			player:sendTextMessage(MESSAGE_STATUS_WARNING, "Offer canceled successfully.")
		end
		return true
	end

	if modalWindowId == 2400 then
		local offer = player:getCurrentOffer()[choiceId]
		if not offer then
			player:cleanOfferAction()
			return true
		end

		local skills = string.format("\n-Fist: %d\n-Club: %d\n-Sword: %d\n-Axe: %d\n-Distance: %d\n-Shield: %d\n-Fishing: %d\n-ML: %d",
				offer.skills.fist,
				offer.skills.club,
				offer.skills.sword,
				offer.skills.axe,
				offer.skills.distance,
				offer.skills.shield,
				offer.skills.fishing,
				offer.skills.ml
			)
		local description = string.format("Character: '%s'\nLevel: %d\nVocation: %s\nSkill: %s\n\nCurrent value: %d coins", offer.name, offer.level, Vocation(offer.vocation):getName(), skills, offer.coin)
		player:makeSellPlayerModalDescription(description)
		player:setBuyCharacter(offer.guid)


	elseif modalWindowId == 2401 then
		-- create char offer
		local info = player:getCurrentOffer()[choiceId]
		if info.account ~= player:getAccountId() then
			player:sendTextMessage(MESSAGE_STATUS_WARNING, "This character does not belong to you.")
			return true
		end

		player:setSellCharacter(info.guid, 0, info.name)
		player:registerEvent("Text_Offers")
		local item = Game.createItem(2597, 1)
		item:setActionId(2401)
		player:showTextDialog(item, "Enter a character value:\n", true)

	elseif modalWindowId == 2402 then
		player:registerEvent("Text_Offers")
		local item = Game.createItem(2597, 1)
		item:setActionId(2402)
		player:showTextDialog(item, "Input your password:\n", true)

	elseif modalWindowId == 2403 then
		player:registerEvent("Text_Offers")
		local item = Game.createItem(2597, 1)
		item:setActionId(2403)
		player:showTextDialog(item, "Input your password:\n", true)

	elseif modalWindowId == 2404 then
		local offer = player:getCurrentOffer()[choiceId]
		if not offer then
			player:cleanOfferAction()
			return true
		end

		local description = string.format("Character: '%s'\nCurrent value: %d coins\nCreate Time: %s\n\nIP: %s", offer.name, offer.coin, os.sdate("%d.%m.%Y - %X", offer.create), Game.convertIpToString(offer.createip))
		player:makeCancelChar(description)
		player:setBuyCharacter(offer.guid)

	elseif modalWindowId == 2405 then
		player:registerEvent("Text_Offers")
		local item = Game.createItem(2597, 1)
		item:setActionId(2405)
		player:showTextDialog(item, "Input your password:\n", true)
	end

	return true
end

function onTextEdit(player, item, text)
	player:unregisterEvent("Text_Offers")
	if not isInArray({2401, 2402, 2403, 2405}, item:getActionId()) then
		error("Nor arry")
		return true
	end

	local value = ""
	local __ = 0
	for line in text:gmatch("([^\n]*)\n?") do
		__ = __ + 1
		if __ == 2 then
			value = line
			break
		end
	end

	-- etapa para verificar senha
	if string.find(text, "Input your password:") then
		local isValid = Game.isValidPassword(player:getAccountId(), value)
		if not isValid then
			player:popupFYI("Your password is wrong.")
		elseif item:getActionId() == 2402 then
			local canBuy = player:exectuteBuyChar(player:getBuyCharacter())
			if canBuy then
				player:popupFYI("You have successfully purchased a character.")
			end
		elseif item:getActionId() == 2403 then
			local canSell = player:canSellChar()
			if canSell then
				player:popupFYI("Your offer was successfully created.")
			else
				player:sendCancelMessage("Sorry, not possible.")
				player:cleanOfferAction()
			end
		elseif item:getActionId() == 2405 then
			local canCancel = player:cancelCharOffer()
			if canCancel then
				player:popupFYI("Your offer was successfully canceled.")
			end

		end

	-- etapa para checar o preço
	elseif string.find(text, "Enter a character value:") then
		if not tonumber(value) or tonumber(value) <= 0 or tonumber(value) >= 99999 then
			player:popupFYI("Enter a valid value.")
			return true
		end
		local info = player:getSellCharacter()
		if info.guid == 0 then
			player:popupFYI("You have no offer.")
			return true
		end

		player:setSellCharacter(info.guid, tonumber(value), info.name)
		player:makeConfirmCharSell()

	-- etapa ao tentar burlar o sistema
	else 
		player:sendCancelMessage("Sorry, not possible.")
	end
	

	return true
end
