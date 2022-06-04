local Log = Class("Log")

function Log:initialize()
	self.lastPrint = os.clock()

	self.delay = true

end

function Log:print(string)

	local currentTime = os.clock()

	if self.delay then
		if currentTime - self.lastPrint > 2 then
			print("[".. os.date( "!%a %b %d, %H:%M", os.time() - 7 * 60 * 60 ) .. "] : " .. string)
			self.lastPrint = os.clock()
		end
	else
		print("[".. os.date( "!%a %b %d, %H:%M", os.time() - 7 * 60 * 60 ) .. "] : " .. string)
	end

end

return Log:new()