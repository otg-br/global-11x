local function doCheckHouses()

    local dias = 5
    local tempo = os.stime() - (dias * 24 * 60 * 60)
    local registros = db.storeQuery("SELECT `houses`.`owner`, `houses`.`id` FROM `houses`,`players` WHERE `houses`.`owner` != 0 AND `houses`.`owner` = `players`.`id` AND `players`.`lastlogin` <= " .. tempo .. ";")

    if registros ~= false then

        local count = 0

        Game.sendConsoleMessage('house leave code', CONSOLEMESSAGE_TYPE_INFO)

        repeat
            count = count + 1

            local owner = result.getNumber(registros, "owner")
            local houseId = result.getNumber(registros, "id")
            local house = House(houseId)

            if house and (owner > 0) then
                Game.sendConsoleMessage(house:getName(), CONSOLEMESSAGE_TYPE_INFO)
                house:setOwnerGuid(0)
            end

        until not result.next(registros)

        Game.sendConsoleMessage('house leave house count:' .. count, CONSOLEMESSAGE_TYPE_INFO)

        result.free(registros)
    end
end

function onStartup()
    addEvent(doCheckHouses, 60 * 1000)

    return true
end
