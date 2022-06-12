Callbacks:Add(CALLBACK_ACTION_REQUESTED, function(actionType, actionId, targetId, result)
	  -- prints information about the action that was requested
		print("Action used of type " .. actionType ..
	      " with the id of " .. actionId .. " and the target was " .. targetId ..
	      " the result was " .. result)
end)

local XPVE = Class("XPVE")

function XPVE:initialize()

	-- Loads Menu Module
	self.menu        = LoadModule("XScripts", "\\Menus\\XPVEMenu")

	-- classes
	self.machinist   = LoadModule("XScripts", "\\Jobs\\PVE\\Machinist")

	-- class menus
	self.machinist:Load(self.menu)

	-- callbacks
	Callbacks:Add(CALLBACK_PLAYER_TICK, function() self:Tick() end)
	
end

function XPVE:Tick()
	if player.classJob == 31 then
		self.machinist:Tick()
	end
end

XPVE:new()