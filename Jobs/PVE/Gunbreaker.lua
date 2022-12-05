local XPVEClass  = LoadModule("XScripts", "/Jobs/PVE/XPVEClass")

local Gunbreaker = Class("Gunbreaker", XPVEClass)

function Gunbreaker:initialize()

	XPVEClass.initialize(self)

	self.class_name        = "Gunbreaker"
	self.class_name_short  = "GNB"
	self.class_category    = "TANK"

	self.actions = {

	}

end

function Gunbreaker:Tick()
		
end

return Gunbreaker:new()