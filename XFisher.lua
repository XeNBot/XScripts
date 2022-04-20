-- Creates new local XFisher class
local XFisher = Class("XFisher")

-- Class constructor
function XFisher:initialize()
	
	self.running = false
	self.fishesCaught = 0

	self.menu = Menu("XFisher")

	self.menu:label("Walk to fishing spot and press start")
	self.menu:space()
	self.menu:button("Start", "BTN_START", function()
		if self.running then
			self.menu["BTN_START"].str = "Start"
			self.running = false
		else
			self.menu["BTN_START"].str = "Stop"
			self.running = true
		end
	end)

	
	Callbacks:Add(CALLBACK_FISH_BITE, function()
		-- Uses Hook whenever a fish bites
		ActionManager.UseAction(1, 296, TARGET_INVALID_ID)
		Keyboard.SendKey(96)
	end)

	Callbacks:Add(CALLBACK_FISH_CATCH, function(fishId)
		-- Prints the fish id of any fishes we catch
		self.fishesCaught = self.fishesCaught + 1
		print("New Fish Cought:", fishId, "Fishes Caught So Far: ", self.fishesCaught)
		ActionManager.UseAction(1, 299, TARGET_INVALID_ID) -- Quits and restarts
	end)

	Callbacks:Add(CALLBACK_PLAYER_TICK, function() self:Tick() end)

	print("Loaded XFisher")
end

function XFisher:Tick()
	if player.isCasting or not self.running then return end -- prevents actions while casting or not running
	-- Checks if we're fishing
	if not player.isFishing then
		-- Check if we can use the fish action (if we're in a fishing area) and if we're not already casting
		if ActionManager.CanUseAction(1, 289, TARGET_INVALID_ID) then
			-- uses action
			ActionManager.UseAction(1, 289, TARGET_INVALID_ID)
		end
	else
		-- we're fishing
		if player.fishingStatus == FISHING_WAITING then 
			if ActionManager.CanUseAction(1, 289, TARGET_INVALID_ID) then
				ActionManager.UseAction(1, 289, TARGET_INVALID_ID) -- Quits and restarts
			end
		end
	end
end

XFisher:new()