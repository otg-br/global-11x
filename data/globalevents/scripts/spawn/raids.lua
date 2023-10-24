local raids = {
	-- Weekly
	--Segunda-Feira
	['Monday'] = {
		['15:00'] = {raidName = 'Draptor'},
		['18:00'] = {raidName = 'Crustacea Gigantica Seacrest2'},
		['14:00'] = {raidName = 'Lions'},
	},

	--Terça-Feira
	['Tuesday'] = {
		['15:00'] = {raidName = 'Midnight Panther'},
		['14:00'] = {raidName = 'Lions'},
		['18:00'] = {raidName = 'Citizen'}
	},

	--Quarta-Feira
	['Wednesday'] = {
		['15:00'] = {raidName = 'Draptor'},
		['18:00'] = {raidName = 'Crustacea Gigantica Treasure'},
		['14:00'] = {raidName = 'Lions'},
		['08:00'] = {raidName = 'Dreadmaw'}
	},

	--Quinta-Feira
	['Thursday'] = {
		['15:00'] = {raidName = 'Midnight Panther Three'},
		['14:00'] = {raidName = 'Lions'},
		['08:00'] = {raidName = 'Dreadmaw'},
		['18:00'] = {raidName = 'Citizen'}
	},

	--Sexta-feira
	['Friday'] = {
		['23:00'] = {raidName = 'Undead Cavebear'},
		['14:00'] = {raidName = 'Lions'},
		['08:00'] = {raidName = 'Dreadmaw'}
	},

	--Sábado
	['Saturday'] = {
		['20:00'] = {raidName = 'Draptor'},
		['18:00'] = {raidName = 'Crustacea Gigantica Calassa1'},
		['14:00'] = {raidName = 'Lions'},
		['08:00'] = {raidName = 'Dreadmaw'}
	},

	--Domingo
	['Sunday'] = {
		['23:00'] = {raidName = 'Undead Cavebear'},
		['14:00'] = {raidName = 'Lions'},
		['08:00'] = {raidName = 'Dreadmaw'}
	},

	-- By date (Day/Month)

	['01'] = {
		['21:00'] = {raidName = 'Omrafir'}
	},
	['10'] = {
		['21:00'] = {raidName = 'Gaz'}
	},
	['15'] = {
		['21:00'] = {raidName = 'Ferumbras', availableMonths = {'February', 'April', 'June', 'August', 'October','December'}}
	}
}

function onThink(interval, lastExecution, thinkInterval)
	local day = os.sdate('%A')
	local d = os.sdate("%d")

	local raidDays = {}
	if raids[day] then
		raidDays[#raidDays + 1] = raids[day]
	end
	if raids[d] then
		if d.availableMonths then
			if isInArray(d.availableMonths, day) then
				raidDays[#raidDays + 1] = raids[d]
			end
		else
			raidDays[#raidDays + 1] = raids[d]
		end
	end

	if #raidDays == 0 then
		return true
	end

	for i = 1, #raidDays do
		local settings = raidDays[i][getRealTime()]
		if settings and not settings.alreadyExecuted then
			Game.startRaid(settings.raidName)
			settings.alreadyExecuted = true
		end
	end

	return true
end
