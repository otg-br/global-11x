-- Miscellaneous library
dofile('data/lib/miscellaneous/miscellaneous.lua')

-- Core API functions implemented in Lua
dofile('data/lib/core/core.lua')

-- Compatibility library for our old Lua API
dofile('data/lib/compat/compat.lua')

dofile('data/lib/rewardboss.lua')

dofile('data/lib/guild.lua')

dofile('data/lib/modalwindow.lua')

dofile('data/lib/lionrock.lua')

-- dofile('data/lib/dailyRewardLib.lua')

dofile('data/lib/customlib/custom.lua')
dofile('data/lib/customlib/holy-functions.lua')
dofile('data/lib/customlib/guildLevel.lua')
dofile('data/lib/customlib/events.lua')

-- events
dofile('data/lib/events/battlefield_x4.lua')
dofile('data/lib/events/battlefield_x2.lua')
dofile('data/lib/events/lastman.lua')
dofile('data/lib/events/zombie.lua')
dofile('data/lib/events/castle.lua')
dofile('data/lib/events/private_war.lua')

-- Debugging helper function for Lua developers
dofile('data/lib/debugging/dump.lua')

-- Autoloot
dofile('data/lib/autoloot.lua')
