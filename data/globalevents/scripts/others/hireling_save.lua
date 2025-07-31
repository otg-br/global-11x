function onShutdown()
    Game.sendConsoleMessage('>> Saving Hirelings', CONSOLEMESSAGE_TYPE_STARTUP)
    SaveHirelings()
    return true
end
