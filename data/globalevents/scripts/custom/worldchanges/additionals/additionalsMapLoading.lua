local additionals = {
    { description = "trainers", file = "data/world/worldchanges/additionals/trainers_eventRoom.otbm", enabled = true}
}

function onStartup()
    Game.sendConsoleMessage("> loading additional maps", CONSOLEMESSAGE_TYPE_STARTUP)
    for _, additional in ipairs(additionals) do 
        if additional.enabled then
            Game.loadMap(additional.file)
            Game.sendConsoleMessage("> loaded " .. additional.description, CONSOLEMESSAGE_TYPE_STARTUP)
        end
    end

    return true
end
