local Mission  = LoadModule("XScripts", "/Missions/Mission")

local Brayflox = Class("Brayflox", Mission)

function Brayflox:initialize()

	Mission.initialize(self)

	self.battle_fov    = 23

	self.event_npc_objects = {
		[1004346] = true
	}

	self.event_objects = {
		[2001462] = true,
		[2001466] = true,
	}

	self.found_key   = false
	self.opened_door = false

	-- Runstop Headgate Key
	self.headgate_key = 2000521

	self.destination = Vector3(-11.08,35.5,-233.82)

	self:AddEventFilter(2001462, function () return self.found_key and not self.opened_door end)
	self:AddEventNpcFilter(1004346, function () return not self.found_key and not self.opened_door end)
end

function Brayflox:Tick()

	Mission.Tick(self)

	if not self.found_key and InventoryManager.GetItemCount(self.headgate_key) > 0 then
		self.found_key = true
	end
	if self.found_key and InventoryManager.GetItemCount(self.headgate_key) == 0 then
		self.opened_door = true
	end
end

function Brayflox:ExitCallback()

	self.found_key   = false
	self.opened_door = false
	self.destination = Vector3(-11.08,35.5,-233.82)
end


return Brayflox:new()