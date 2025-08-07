-- Time utility functions
-- Centralized functions for time conversion and formatting

function getHours(seconds)
    return math.floor((seconds / 60) / 60)
end

function getMinutes(seconds)
    return math.floor(seconds / 60)
end

function getSeconds(seconds)
    return seconds % 60
end

function getTime(seconds)
    local hours, minutes = getHours(seconds), getMinutes(seconds)
    if minutes > 59 then
        minutes = minutes - hours * 60
    end

    if minutes < 10 then
        minutes = "0" .. minutes
    end

    return hours .. ":" .. minutes .. "h"
end

function getTimeinWords(secs)
    local hours, minutes, seconds = getHours(secs), getMinutes(secs), getSeconds(secs)
    if minutes > 59 then
        minutes = minutes - hours * 60
    end

    local timeStr = ''

    if hours > 0 then
        timeStr = timeStr .. hours .. ' hours '
    end

    timeStr = timeStr .. minutes .. ' minutes and ' .. seconds .. ' seconds.'

    return timeStr
end