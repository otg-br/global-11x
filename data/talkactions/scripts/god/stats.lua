function onSay(player, words, param)
    if not player:getGroup():getAccess() then
        return false
    end

    if words == "/stats" then
        local message = "=== SERVER STATISTICS ===\n"
        message = message .. "Players Online: " .. Game.getPlayerCount() .. "\n"
        message = message .. "Uptime: " .. getWorldUpTime() .. " seconds\n"
        message = message .. "\n=== PERFORMANCE STATS ===\n"
        message = message .. "Stats are being logged to data/logs/stats/ directory\n"
        message = message .. "Check the following files for detailed statistics:\n"
        message = message .. "- dispatcher.log (Task execution stats)\n"
        message = message .. "- lua.log (Lua script performance)\n"
        message = message .. "- sql.log (Database query performance)\n"
        message = message .. "- special.log (Special operations)\n"
        message = message .. "- *_slow.log (Operations taking >10ms)\n"
        message = message .. "- *_very_slow.log (Operations taking >50ms)\n"
        player:showTextDialog(2160, message)
    end
    
    return false
end