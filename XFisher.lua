--- Creates new local XFisher class
local XFisher = Class("XFisher")

-- Class constructor
function XFisher:initialize()
	
	self.running = false
	-- counter for fishes caught
	self.fishesCaught = 0

	-- new way of using actions
	self.actions = {

		cast     = Action(1, 289),
		hook     = Action(1, 296),
		mooch    = Action(1, 297),
		mooch2   = Action(1, 268),
		chum     = Action(1, 4104),
		thaliak  = Action(1, 26804),
		collect  = Action(1, 4101),
		patience = Action(1, 4102),
		phook    = Action(1, 4103),

	}

	-- Log Module
	self.log       = LoadModule("XScripts", "/Utilities/Log")
	self.log.delay = false
	self.menu = Menu("XFisher")

	self.menu:label("Walk to fishing spot and press start")
	self.menu:separator()
	self.menu:checkbox("Use Chum",     "USE_CHUM", true)
	self.menu:checkbox("Use Mooch",    "USE_MOOCH", true)
	self.menu:checkbox("Use Mooch II", "USE_MOOCH2", true)
	self.menu:checkbox("Use Thaliak's Favor", "USE_THALIAK", true)
	self.menu:checkbox("Use Patience", "USE_PATIENCE", true)
	self.menu:checkbox("Use Powerful Hook", "USE_PHOOK", true)
	self.menu:slider("Min Marks for Powerful Hook", "PHOOK_MIN", 1, 1, 3, 2)

	self.menu:checkbox("Use Collect",  "COLLECT", true)
	self.menu:number("Minimum Collectability", "COLLECT_MIN", 50)

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
		self.log:print("Got a bite with " .. marks .. " mark(s)")

		if self.menu["USE_PHOOK"].bool and marks >= self.menu["PHOOK_MIN"].int and self.actions.phook:canUse() then
			self.log:print("Using Powerful Hookset!")
			self.actions.phook:use()
		else
			self.actions.hook:use()
		end
	end)

	Callbacks:Add(CALLBACK_FISH_CATCH, function(fishId)
		-- Prints the fish id of any fishes we catch
		self.fishesCaught = self.fishesCaught + 1
		self.log:print("Caught a fish! id : " ..  tostring(fishId) ..", So far we caught : " ..  tostring(self.fishesCaught) .. " fishes")
		-- Can Mooch?
		if self.menu["USE_MOOCH2"].bool and self.actions.mooch2:canUse() then
			self.log:print("Using fish with Mooch II to catch bigger one!")
			self.actions.mooch2:use()
		elseif self.menu["USE_MOOCH"].bool and self.actions.mooch:canUse() then
			self.log:print("Using fish with mooch to catch bigger one!")
			self.actions.mooch:use()
		elseif self.menu["USE_PATIENCE"].bool and not player:hasStatus(850) and self.actions.patience:canUse() then
			self.actions.patience:use()
		elseif self.menu["USE_CHUM"].bool and self.actions.chum:canUse() then
			self.actions.chum:use()
		else
			self.actions.cast:use()
		end
	end)

	Callbacks:Add(CALLBACK_FISH_FAIL, function()
		self.log:print("Oh noes, the fish got away! trying again")
		self.actions.cast:use()
	end)

	Callbacks:Add(CALLBACK_ACTION_USED, function(type, id, targetId)
		-- Chum id
		if id == self.actions.chum.id then
			self.log:print("Used Chum, time to fish!")
			self.actions.cast:use()
		end
	end)

	Callbacks:Add(CALLBACK_FISH_CATCH_COLLECTABLE, function(fishId, collectability)
		-- prints fish id & collectability
		
		self.fishesCaught = self.fishesCaught + 1
		self.log:print("Caught new collectable: " .. tostring(fishId) .. ", it has " .. tostring(collectability) .. " collectability")
		self.log:print("So far we caught : " ..  tostring(self.fishesCaught) .. " fishes")
		
		return collectability >= self.menu["COLLECT_MIN"].int		
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

	if self.menu["COLLECT"].bool and not player:hasStatus(805) and self.actions.collect:canUse() then
		self.actions.collect:use()
		return
	end

	-- Checks if we're fishing
	if not player.isFishing then
		-- Checks if we have Chum on
		if self.menu["USE_PATIENCE"].bool and not player:hasStatus(850) and self.actions.patience:canUse() then
			self.actions.patience:use()
		elseif self.menu["USE_CHUM"].bool and self.actions.chum:canUse() then
			self.actions.chum:use()
		-- Check if we can use the fish action (if we're in a fishing area) and if we're not already casting
		elseif self.actions.cast:canUse() then
			self.actions.cast:use()
		end	
	end
end

XFisher:new()