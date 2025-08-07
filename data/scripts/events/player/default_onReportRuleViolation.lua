local function hasPendingReport(name, targetName, reportType)
	-- Create directory if it doesn't exist
	os.execute("mkdir data\\reports\\players 2>nul")
	
	local filePath = string.format("data/reports/players/%s-%s-%d.txt", name, targetName, reportType)
	local f = io.open(filePath, "r")
	if f then
		io.close(f)
		return true
	end
	return false
end

local event = Event()
event.onReportRuleViolation = function(self, targetName, reportType, reportReason, comment, translation)
	local name = self:getName()
	if hasPendingReport(name, targetName, reportType) then
		self:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your report is being processed.")
		return
	end

	-- Ensure directory exists before creating file
	os.execute("mkdir data\\reports\\players 2>nul")
	
	local filePath = string.format("data/reports/players/%s-%s-%d.txt", name, targetName, reportType)
	local file = io.open(filePath, "a")
	if not file then
		self:sendTextMessage(MESSAGE_EVENT_ADVANCE, "There was an error when processing your report, please contact a gamemaster.")
		return
	end

	io.output(file)
	io.write("------------------------------\n")
	io.write("Reported by: " .. name .. "\n")
	io.write("Target: " .. targetName .. "\n")
	io.write("Type: " .. reportType .. "\n")
	io.write("Reason: " .. reportReason .. "\n")
	io.write("Comment: " .. comment .. "\n")
	if reportType ~= REPORT_TYPE_BOT then
		io.write("Translation: " .. translation .. "\n")
	end
	io.write("------------------------------\n")
	io.close(file)
	self:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("Thank you for reporting %s. Your report will be processed by %s team as soon as possible.", targetName, configManager.getString(configKeys.SERVER_NAME)))
end
event:register()