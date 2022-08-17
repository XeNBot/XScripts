--[[Callbacks:Add(CALLBACK_ACTION_REQUESTED, function(actionType, actionId, targetId, result)
	  -- prints information about the action that was requested
		print("Action used of type " .. actionType ..
	      " with the id of " .. actionId .. " and the target was " .. targetId ..
	      " the result was " .. result)
end)]]--

local HealingManager = Class("HealingManager")

function HealingManager:initialize()
	
	self.heal_actions = {}


	--------------------------------------------------------------------
	-- Callbacks
	Callbacks:Add(CALLBACK_PLAYER_TICK, function() self:Tick() end)
	--------------------------------------------------------------------	
end

function HealingManager:Tick()


end

function HealingManager:AddAction(_action, _potency, _condition)
	
	table.insert(self.heal_actions, 
		{ info = _action, potency = _potency, condition = _condition, class = player.classJob })

end

HealingManager:new()