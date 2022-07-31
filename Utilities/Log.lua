local Log = Class("Log")

function Log:initialize()
	
	self.lastPrint = os.clock()
	self.lastmsg   = nil

	self.delay = true

end

function Log:print(str)

	local currentTime = os.clock()

	if self.delay then
		if (currentTime - self.lastPrint > 2) or self.lastmsg ~= str then
			print("[".. os.date( "!%a %b %d, %H:%M", os.time() - 7 * 60 * 60 ) .. "] : " .. str)
			self.lastPrint = os.clock()
			self.lastmsg = str
		end
	else
		print("[".. os.date( "!%a %b %d, %H:%M", os.time() - 7 * 60 * 60 ) .. "] : " .. str)
	end

end

return Log:new()