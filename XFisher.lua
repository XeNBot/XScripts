--- Creates new local XFisher class
local XFisher = Class("XFisher")

-- Class constructor
function XFisher:initialize()
	
	self.running = false
	-- counter for fishes caught
	self.fishesCaught = 0

	-- new way of using actions
	self.actions = {

		cast    = Action(1, 289),
		hook    = Action(1, 296),
		mooch   = Action(1, 297),
		chum    = Action(1, 4104),
		thaliak = Action(1, 26804)

	}

	self.menu = Menu("XFisher")

	self.menu:label("Walk to fishing spot and press start")
	self.menu:checkbox("Use Chum", "USE_CHUM", true)
	self.menu:checkbox("Use Mooch", "USE_MOOCH", true)
	self.menu:checkbox("Use Thaliak's Favor", "USE_THALIAK", true)
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

	
	Callbacks:Add(CALLBACK_FISH_BITE, function(marks)
		-- Uses Hook whenever a fish bites
		print("Got a bite with " .. marks .. " mark(s)")
		self.actions.hook:use()
	end)

	Callbacks:Add(CALLBACK_FISH_CATCH, function(fishId)
		-- Prints the fish id of any fishes we catch
		self.fishesCaught = self.fishesCaught + 1
		print("[".. os.date( "!%a %b %d, %H:%M", os.time() - 7 * 60 * 60 ) .. "]: Caught a fish! id : " ..  fishId ..", So far we caught : " ..  self.fishesCaught .. " fishes")
		-- Can Mooch?
		if self.menu["USE_MOOCH"].bool and self.actions.mooch:canUse() then
			print("Using fish with mooch to catch bigger one!")
			self.actions.mooch:use()
		elseif self.menu["USE_CHUM"].bool and self.actions.chum:canUse() then
			self.actions.chum:use()
		else
			self.actions.cast:use()
		end
	end)

	Callbacks:Add(CALLBACK_FISH_FAIL, function()
		print("Oh noes, the fish got away! trying again")
		self.actions.cast:use()
	end)

	Callbacks:Add(CALLBACK_ACTION_USED, function(type, id, targetId)
		-- Chum id
		if id == self.actions.chum.id then
			print("Used Chum, time to fish!")
			self.actions.cast:use()
		end
	end)

	Callbacks:Add(CALLBACK_PLAYER_TICK, function() self:Tick() end)

	print("Loaded XFisher")
end

function XFisher:Tick()
	if not self.running then return end -- prevents actions while casting or not running

	if self.menu["USE_THALIAK"].bool and self.actions.thaliak:canUse() and (player.maxGP - player.GP) > 150 then
		self.actions.thaliak:use()
		return
	end

	-- Checks if we're fishing
	if not player.isFishing then
		-- Checks if we have Chum on
		if self.menu["USE_CHUM"].bool and self.actions.chum:canUse() then
			self.actions.chum:use()
		-- Check if we can use the fish action (if we're in a fishing area) and if we're not already casting
		elseif self.actions.cast:canUse() then
			self.actions.cast:use()
		end	
	end
end

XFisher:new()