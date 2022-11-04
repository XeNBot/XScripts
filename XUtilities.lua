-- Creates class XUtilities
local XUtilities = Class("XUtilities")

-- Function Called when class initializes
function XUtilities:initialize()

	self.last_mount = os.clock()
	self.current_mount_id = 0

	self.last_fly = os.clock()

	-- Loads Log
	self.log = LoadModule("XScripts", "\\Utilities\\Log")

	-- Creates our Menu
	self.menu = Menu("XUtilities")
	-- Adds a label
	self.menu:label("~=[ Main Utilities ]=~")
	-- Adds separator
	self.menu:separator()
	-- Adds checkbox with default value of true
	self.menu:checkbox("Auto Accept Quests", "AUTO_ACCEPT", true)
	self.menu:checkbox("Auto Accept Duty Finder", "DUTY_FINDER", true)
	self.menu:checkbox("Auto Skip Talk", "AUTO_TALK", false)
	self.menu:label("~=[ Mount Untilities ]=~")
	self.menu:number("Desired Mount", "MOUNT_ID", 216)
	self.menu:hotkey("Mount / UnMount", "MOUNT_KEY", {0x10, 0x31})
	self.menu:checkbox("Auto Fly When Mounted", "AUTO_FLY", false) self.menu:space()
	self.menu:hotkey("Set Flying", "FLYING_KEY", {0x10, 0x32})
	
	-- Adds the function Utilities:Tick() to the player tick callback table
	Callbacks:Add(CALLBACK_PLAYER_TICK, function() self:Tick() end)
end

function XUtilities:Tick()
	if self.menu["MOUNT_KEY"].keyDown and (os.clock() - self.last_mount) > 1 then
		if self.current_mount_id == 0 then
			self.current_mount_id = self.menu["MOUNT_ID"].int
			self.log:print("Setting Mount ID " .. tostring(self.current_mount_id))
			Game.SetMount(self.current_mount_id)
			if self.menu["AUTO_FLY"].bool then
				Game.SetFlying(true)
			end
		else 
			self.log:print("Getting off Mount!")
			self.current_mount_id = 0
			Game.SetMount(0)
		end
		self.last_mount = os.clock()
	end

	if self.menu["FLYING_KEY"].keyDown and (os.clock() - self.last_fly) > 1 then
		self.log:print("Setting Flying!")
		Game.SetFlying(true)
		self.last_fly = os.clock()
	end

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

	if self.menu["DUTY_FINDER"].bool then
		local dutyFinder = AddonManager.GetAddon("ContentsFinder")
		if dutyFinder ~= nil then
			dutyFinder:Commence()
		end
	end
	
end

-- initializes the class
XUtilities:new()