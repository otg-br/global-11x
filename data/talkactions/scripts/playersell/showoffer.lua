function onSay(player, word, param)
	if param:lower() == "show" then
		local offers = Game.getPlayersSell()

		if not offers or #offers < 1 then
			player:sendCancelMessage("There are no characters for sale.")
			return false
		end

		player:makeSellPlayerModal(offers)
	elseif param:lower() == "create" then
		if player:getLevel() < SELLCHARLEVEL then
			player:sendCancelMessage("Minimum level for sale is ".. SELLCHARLEVEL ..".")
			return false
		end

		player:showAccountOffer()
	elseif param:lower() == "my offer" then
		local offers = getOffersByAccountId(player:getAccountId())
		if #offers == 0 then
			player:sendCancelMessage("You have no characters for sale.")
			return false
		end

		player:makeMyCharOffers()

	else
		player:sendTextMessage(MESSAGE_STATUS_WARNING, "Possible parameters: [show], [create] and [my offer]")
	end
	return false
end
