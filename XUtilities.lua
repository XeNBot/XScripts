-- Creates class XUtilities
local XUtilities = Class("XUtilities")

-- Function Called when class initializes
function XUtilities:initialize()

	self.last_mount = os.clock()
	self.current_mount_id = 0

	self.last_zoom  = 0

	self.last_fly   = os.clock()
	self.manual_fly = false

	self.last_jump  = os.clock()
	self.jump_count = 0

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
	self.menu:sliderF("Max Zoom Distance", "MAX_ZOOM", 0.5, 20, 100, 20)
	self.menu:label("~=[ Mount Untilities ]=~")
	self.menu:number("Desired Mount", "MOUNT_ID", 216)
	self.menu:hotkey("Mount / UnMount", "MOUNT_KEY", {0x10, 0x31})
	self.menu:checkbox("Auto Fly When Mounted", "AUTO_FLY", false) self.menu:space()
	self.menu:hotkey("Set Flying", "FLYING_KEY", {0x10, 0x32})
	
	-- Adds the function Utilities:Tick() to the player tick callback table
	Callbacks:Add(CALLBACK_PLAYER_TICK, function() self:Tick() end)	
	Callbacks:Add(CALLBACK_ACTION_REQUESTED, function(actionType, actionId, targetId, result)
		if actionType == 13 and result == 1 and not player.isMounted then
			print("Mounted Manually! Mount ID : " ..tostring(actionId))
			if self.menu["AUTO_FLY"].bool then
				self.manual_fly = true
			end
		end
	end)
end

function XUtilities:Tick()
	local max_zoom = self.menu["MAX_ZOOM"].float
	if self.last_zoom ~= max_zoom then
		Game.SetMaxZoom(max_zoom)
		self.last_zoom = max_zoom
	end

	if player.isMounted and self.menu["AUTO_FLY"].bool then

		if Keyboard.IsKeyDown(32) then
			if self.jump_count == 0 then
				self.last_jump  = os.clock()
				self.jump_count = 1
			elseif self.jump_count == 1 and (os.clock() - self.last_jump) > 0.5 then
				Game.SetFlying(true)
				self.jump_count = 0
			end
		end

		if self.manual_fly and player.isMounted then
			Game.SetFlying(true)
			self.manual_fly = false
		end

	end

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