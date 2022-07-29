-- Creates class XUtilities
local XUtilities = Class("XUtilities")

-- Function Called when class initializes
function XUtilities:initialize()

	-- Creates our Menu
	self.menu = Menu("XUtilities")
	-- Adds a label
	self.menu:label("~=[ Main Utilities ]=~")
	-- Adds separator
	self.menu:separator()
	-- Adds checkbox with default value of true
	self.menu:checkbox("Auto Accept Quests", "AUTO_ACCEPT", true)
	self.menu:checkbox("Auto Skip Talk", "AUTO_TALK", false)

	-- Adds the function Utilities:Tick() to the player tick callback table
	Callbacks:Add(CALLBACK_PLAYER_TICK, function() self:Tick() end)
end

function XUtilities:Tick()

	if self.menu["AUTO_ACCEPT"].bool then
		local acceptAddon = AddonManager.GetAddon("JournalAccept")
		if acceptAddon ~= nil then
			acceptAddon:Accept()
		end
	end
	
	if self.menu["AUTO_TALK"].bool then
		local talkAddon = AddonManager.GetAddon("Talk")
		if talkAddon ~= nil then
			talkAddon:Continue()
		end
	end
	
end

-- initializes the class
XUtilities:new()