local Log = Class("Log")

function Log:initialize()
	self.lastPrint = os.clock()
end

function Log:print(string)

	local currentTime = os.clock()

	if currentTime - self.lastPrint > 2 then
		print("[".. os.date( "!%a %b %d, %H:%M", os.time() - 7 * 60 * 60 ) .. "] : " .. string)
		self.lastPrint = os.clock()
	end

end

return Log:new()