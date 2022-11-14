local Mission  = LoadModule("XScripts", "/Missions/Mission")

local Brayflox = Class("Brayflox", Mission)

function Brayflox:initialize()

	self.event_objects = {
		[2001462] = true,
		[2001466] = true,
	}

	Mission.initialize(self)

	-- Runstop Headgate Key
	self.goblin_pathfinder = 1004346
	self.headgate_key = 2000521
	self.opened_gate  = false

	self:AddExitCallback(function () self.opened_gate = false end)

end

function Brayflox:CustomInteract()

	local pathfinder = ObjectManager.EventNpcObject(function(obj) return obj.dataId == self.goblin_pathfinder and self.mainModule.callbacks.InteractFilter(obj) end)
	if pathfinder.valid and not self.opened_gate and InventoryManager.GetItemCount(self.headgate_key) < 1 then
		player:rotateTo(pathfinder.pos)
		TaskManager:Interact(pathfinder)
		return true
	end

	local event_object = ObjectManager.EventObject(function (obj)
		return self.event_objects[obj.dataId] == true and self.mainModule.callbacks.InteractFilter(obj)
	end)

	if event_object.valid then
		player:rotateTo(event_object.pos)
		TaskManager:Interact(event_object)
		return true
	end	

	return false
end


return Brayflox:new()