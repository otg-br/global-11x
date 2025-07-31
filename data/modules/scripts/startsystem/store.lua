function debubBytes(msg)
	
end

	local GameStoreCategories = {
		{name = "Teste1", description = "desv2"},
		{name = "Teste2", description = "desv2"},
		{name = "Teste4", description = "desv2"},
		{name = "Teste31", description = "desv2"},

	}

function openStore(playerId)
	local player = Player(playerId)
	if not player then
		return false
	end

	local msg = NetworkMessage()
	msg:addByte(0xFB)
	if player:getClient().version < 1180 then
		msg:addByte(0x00)
	end

	if (GameStoreCategories) then
		msg:addU16(#GameStoreCategories)
		for k, category in ipairs(GameStoreCategories) do
			msg:addString(category.name)
			if player:getClient().version < 1180 then
				msg:addString(category.description)
			end

			if player:getClient().version >= 1093 then
				msg:addByte(0)
			end

			msg:addByte(1)
			msg:addString(category.name)

			msg:addU16(0) -- maybe parent category?
			-- msg:addString(category.parentCategory)
		end
		msg:sendToPlayer(player)

		sendCoinBalanceUpdating(playerId, true)
	end
end

function sendCoinBalanceUpdating(playerId, updating)
	local player = Player(playerId)
	if not player then
		return false
	end

	local msg = NetworkMessage()
	msg:addByte(0xF2)
	msg:addByte(0x00)
	msg:sendToPlayer(player)

	if updating == true then
		sendUpdateCoinBalance(playerId)
	end
end

function sendUpdateCoinBalance(playerId)
	local player = Player(playerId)
	if not player then
		return false
	end

	local msg = NetworkMessage()
	msg:addByte(0xF2)
	msg:addByte(0x01)

	msg:addByte(0xDF)
	msg:addByte(0x01)

	msg:addU32(100)
	msg:addU32(100)

	msg:sendToPlayer(player)
end

function sendShowStoreOffers(playerId, category)
	category = GameStoreCategories[1]
	local player = Player(playerId)
	if not player then
	return false
	end

	local msg = NetworkMessage()
	local haveSaleOffer = 0
	msg:addByte(GameStore.SendingPackets.S_StoreOffers)

	msg:addString(category.name)
	if player:getClient().version >= 1180 then
		msg:addU32(0)
		if player:getClient().version >= 1185 then
			msg:addU32(0)
		else
			msg:addU16(0)
		end
	end
	msg:addU16(0x01)

	if category.offers then
		for k, offer in ipairs(category.offers) do
			local name = ""
			if offer.type == GameStore.OfferTypes.OFFER_TYPE_ITEM and offer.count then
				name = offer.count .. "x "
			end

			if offer.type == GameStore.OfferTypes.OFFER_TYPE_STACKABLE and offer.count then
				name = offer.count .. "x "
			end

			name = name .. (offer.name or "Something Special")

			local newPrice = nil
			local offerPrice = 0
			if (offer.state == GameStore.States.STATE_SALE) then
				local daySub = offer.validUntil - os.sdate("*t").day
				if (daySub < 0) then
					newPrice = offer.basePrice
				end
			end

			xpBoostPrice = nil
			if offer.type == GameStore.OfferTypes.OFFER_TYPE_EXPBOOST then
				xpBoostPrice = GameStore.ExpBoostValues[player:getStorageValue(51052)]
			end

			if xpBoostPrice then
				offerPrice = xpBoostPrice
			else
				offerPrice = newPrice or offer.price or 0xFFFF
			end

			local disabled, disabledReason = player:canBuyOffer(offer).disabled, player:canBuyOffer(offer).disabledReason
			if player:getClient().version >= 1180 then
				sendOfferDescription(player, offer.id and offer.id or 0xFFFF, offer.description)
				msg:addString(name);
				msg:addByte(0x01);
				msg:addU32(offer.id and offer.id or 0xFFFF);
				msg:addU16(1);
				msg:addU32(offerPrice);

				msg:addByte(0x00);

				msg:addByte(disabled)
				if disabled == 1 and player:getClient().version >= 1093 then
					msg:addByte(0x01);
					msg:addString(disabledReason)
				end

				if (offer.state) then
					if (offer.state == GameStore.States.STATE_SALE) then
						local daySub = offer.validUntil - os.sdate("*t").day
						if (daySub >= 0) then
							msg:addByte(offer.state)
							msg:addU32(os.stime() + daySub * 86400)
							msg:addU32(offer.basePrice)
							haveSaleOffer = 1
						else
							msg:addByte(GameStore.States.STATE_NONE)
						end
					else
						msg:addByte(offer.state)
					end
				else
					msg:addByte(GameStore.States.STATE_NONE)
				end
				msg:addByte(0x00);

				msg:addString(offer.icons[1])

				msg:addU16(0);
				msg:addU16(0x01);
				msg:addU16(0x0182);
				msg:addU16(0);
				msg:addU16(0);
				msg:addByte(0x00);
			else
				msg:addU32(offer.id and offer.id or 0xFFFF) -- offerid
				msg:addString(name)
				msg:addString(offer.description or GameStore.getDefaultDescription(offer.type,offer.count))
				msg:addU32(offerPrice)

				if (offer.state) then
					if (offer.state == GameStore.States.STATE_SALE) then
						local daySub = offer.validUntil - os.sdate("*t").day
						if (daySub >= 0) then
							msg:addByte(offer.state)
							msg:addU32(os.stime() + daySub * 86400)
							msg:addU32(offer.basePrice)
							haveSaleOffer = 1
						else
							msg:addByte(GameStore.States.STATE_NONE)
						end
					else
						msg:addByte(offer.state)
					end
				else
					msg:addByte(GameStore.States.STATE_NONE)
				end

				if table.contains({ CLIENTOS_OTCLIENT_LINUX, CLIENTOS_OTCLIENT_WINDOWS, CLIENTOS_OTCLIENT_MAC }, player:getClient().os) then
					if disabled == 1 then
						msg:addByte(0) -- offer type 0 means disabled
					else
						msg:addByte(offer.type)
					end
				else
					-- supporting the old way
					msg:addByte(disabled)
				end
				if disabled == 1 and player:getClient().version >= 1093 then
					msg:addString(disabledReason)
				end

				msg:addByte(#offer.icons)
				for k, icon in ipairs(offer.icons) do
					msg:addString(icon)
				end

				msg:addU16(0) -- We still don't support SubOffers!
			end
		end
	end

	player:sendButtonIndication(haveSaleOffer, 1)
	msg:sendToPlayer(player)

end

function parseOpenStore(playerId, msg)
	openStore(playerId)

	local serviceType = msg:getByte()
	local category = GameStore.Categories and GameStore.Categories[1] or nil

	local servicesName = {
		[GameStore.ServiceTypes.SERVICE_OUTFITS] = "outfits",
		[GameStore.ServiceTypes.SERVICE_MOUNTS] = "mounts",
		[GameStore.ServiceTypes.SERVICE_BLESSINGS] = "blessings"
	}

	if servicesName[serviceType] then
		category = GameStore.getCategoryByName(servicesName[serviceType])
	end

	if category then
		addPlayerEvent(sendShowStoreOffers, 350, playerId, category)
	end
end

function onRecvbyte(player, msg, byte)
	local recvbyte = byte
	Game.sendConsoleMessage("recv:"..recvbyte, CONSOLEMESSAGE_TYPE_INFO)
	if recvbyte == 0xFB then
		openStore(player:getId())
	end
	return true
end

