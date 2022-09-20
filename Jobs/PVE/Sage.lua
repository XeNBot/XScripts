local Sage = Class("Sage")

function Sage:initialize()

	self.actions = {	
		
		diagnosis = Action(1, 24284)

	}

	self.menu = nil
	self.log  = nil


	self.lastAction = 0


	self.healingManager =  LoadModule("XScripts", "/Utilities/HealingManager")

	Callbacks:Add(CALLBACK_ACTION_REQUESTED, function(actionType, actionId, targetId, result)

		if result == 1 and actionType == 1 then
			self.lastAction = actionId
		end

	end)

end

function Sage:Load(menu, log)
	
	self.log  = log
	self.menu = menu

	self.menu["ACTIONS"]["HEALER"]:subMenu("Sage", "SGE")

	self.healingManager:Load(self.menu["ACTIONS"]["HEALER"]["SGE"])

	self.healingManager:AddAction(self.actions.diagnosis, "Diagnosis" , 40, 450, nil, function() return 30 end)
end

function Sage:Tick()
	
end

function Sage:Combo()
	
	
end

function Sage:Weave()
	
	
end


return Sage:new()