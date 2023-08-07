local DutySupport = LoadModule("XScripts", "/Activities/DutySupportActivity")

local TotoRak = Class("TotoRak", DutySupport)

function TotoRak:initialize()

	DutySupport.initialize(self)

	self.type  = 0
	self.name  = "Thousand Maws of Toto-Rak"
	self.level = 24
	self.tab_index  = 1
	self.duty_index = 5
	-- Field of Views
	self.battle_fov   = 30
	self.event_fov    = 50
	self.treasure_fov = 99
	self.los_fov      = 15
	-- Objects
	self.event_objects = { 
	}

	self:SetMaps({[9] = Vector3(237.77,-38.91,-144.02),})

end

function TotoRak:Tick()
end

return TotoRak:new()