local serverstartup = GlobalEvent("serverstartup")

function serverstartup.onStartup()
	-- Hireling System
	HirelingsInit()
end

serverstartup:register()