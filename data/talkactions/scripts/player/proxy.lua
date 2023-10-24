function Player:sendProxyModalWindow()
	local proxyList = configManager.getString(configKeys.PROXY_LIST)
	if #proxyList > 0 then
		local proxies = proxyList:split(";")
		local window = ModalWindow {
			title = "Select a proxy",
			message = "Please select a proxy, keep in mind that" ..
			"\nthe proxy will only start working once you" ..
			"\nlogout and type your account details again."
		}
		local accountId = self:getAccountId()
		local playerId = self:getId()

		local noProxyChoice = window:addChoice("No Proxy Server")
		noProxyChoice.proxyId = 0
		noProxyChoice.proxyName = "No server"

		for i = 1, #proxies do
			local proxyInfo = proxies[i]:split(",")
			local choice = window:addChoice(proxyInfo[4] .. " Proxy Server")
			choice.proxyId = proxyInfo[1]
			choice.proxyName = proxyInfo[4]
		end

		window:addButton("Select",
			function(button, choice)
				db.query("UPDATE `accounts` SET `proxy_id` = " .. choice.proxyId .. " WHERE `id` = " .. accountId)
				local player = Player(playerId)
				if player then
					player:sendTextMessage(MESSAGE_INFO_DESCR, choice.proxyName .. " Proxy Server selected. Logout and type your account details again to start using it!")
				end
			end)

		window:addButton("Cancel")
		window:setDefaultEscapeButton('Cancel')
		window:setDefaultEnterButton('Select')
		window:sendToPlayer(self)
	end
end

function onSay(player, words, param)
	return player:sendProxyModalWindow()
end
