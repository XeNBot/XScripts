local DutySupport = LoadModule("XScripts", "/Activities/DutySupportActivity")

local Deepcroft = Class("Deepcroft", DutySupport)

function Deepcroft:initialize()

	DutySupport.initialize(self)

	self.type  = 0
	self.name  = "The Tam-Tara Deepcroft"
	self.level = 16
	self.tab_index  = 1
	self.duty_index = 2
	-- Field of Views
	self.battle_fov   = 30
	self.event_fov    = 50
	self.treasure_fov = 99
	self.los_fov      = 15
	-- Objects
	self.event_objects = {
		[2000057] = true,
		[2000061] = true,
		[2000062] = true,
		[2000063] = true,
		[2000067] = true,
	}

	self:SetMaps({[8] = Vector3(-43.31,14.04,-17.03),})

	self.filter_2000060 = function(obj)
		local door = ObjectManager.EventObject(function (obj)
			 return obj.isTargetable and obj.dataId == 2000060
		end)

		if door.valid then
			if door.pos:dist(obj.pos) < 45 then
				return false
			end
		end

		return true
	end

	self:AddBattleFilter(137, self.filter_2000060)
	self:AddBattleFilter(1345, self.filter_2000060)
	self:AddEventFilter(2000063, self.filter_2000060)
	self:AddEventFilter(2000067, self.filter_2000060)
end

function Deepcroft:Tick()
	if self.map_id == 8 then
		if self.destination == Vector3(-178.53,14,-5.1) and InventoryManager.GetItemCount(2000244) == 0 then 
			self.event_objects[2000060] = nil
		else
			self.destination = Vector3(-43.31,14.04,-17.03)
			self.event_objects[2000060] = true
		end
	end
end

return Deepcroft:new()