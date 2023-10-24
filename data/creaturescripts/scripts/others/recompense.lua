function onAdvance(cid, skill, oldlevel, newlevel)

	       	if getPlayerLevel(cid) >= 8 and getPlayerStorageValue(cid, 99963) ~= 1 then
						    doPlayerSetBalance(cid, getPlayerBalance(cid) + 10000)
						    setPlayerStorageValue(cid, 99963, 1)
						    doPlayerSendTextMessage(cid, 19, "You have received 10000 gold in your bank for advancing to Level 8.")

		    elseif getPlayerLevel(cid) >= 20 and getPlayerStorageValue(cid, 99964) ~= 1 then
						    doPlayerSetBalance(cid, getPlayerBalance(cid) + 20000)
						    setPlayerStorageValue(cid, 99964, 1)
						    doPlayerSendTextMessage(cid, 19, "You have received 20000 gold in your bank for advancing to Level 20.")

		   elseif getPlayerLevel(cid) >= 50 and getPlayerStorageValue(cid, 99965) ~= 1 then
						    doPlayerSetBalance(cid, getPlayerBalance(cid) + 30000)
						    setPlayerStorageValue(cid, 99965, 1)
						    doPlayerSendTextMessage(cid, 19, "You have received 30000 gold in your bank for advancing to Level 50.")

		     elseif getPlayerLevel(cid) >= 75 and getPlayerStorageValue(cid, 99966) ~= 1 then
						    doPlayerSetBalance(cid, getPlayerBalance(cid) + 50000)
						    setPlayerStorageValue(cid, 99966, 1)
						    doPlayerSendTextMessage(cid, 19, "You have received 50000 gold in your bank for advancing to Level 75.")


			elseif getPlayerLevel(cid) >= 100 and getPlayerStorageValue(cid, 99969) ~= 1 then
						    doPlayerSetBalance(cid, getPlayerBalance(cid) + 100000)
						    setPlayerStorageValue(cid, 99969, 1)
						   doPlayerSendTextMessage(cid, 19, "You have received 100000 gold in your bank for advancing to Level 100.")





						    end
		    return TRUE
end
