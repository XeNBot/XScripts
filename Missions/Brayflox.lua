local Mission  = LoadModule("XScripts", "/Missions/Mission")

local Brayflox = Class("Brayflox", Mission)

function Brayflox:initialize()

	Mission.initialize(self)

	-- Runstop Headgate Key
	self.headgate_key = 2000521
	self.opened_gate  = false

	self:AddExitCallback(function () self.opened_gate = false end)

end

function Brayflox:CustomInteract()

	local pathfinder = ObjectManager.EventNpcObject(function(obj) return obj.name == "Goblin Pathfinder" and self.mainModule.callbacks.InteractFilter(obj) end)
	if pathfinder.valid and not self.opened_gate and InventoryManager.GetItemCount(self.headgate_key) < 1 then
		player:rotateTo(pathfinder.pos)
		TaskManager:Interact(pathfinder)
		return true
	end

	local gate = ObjectManager.EventObject(function(obj) return self.mainModule.interactables.gates[obj.npcId] ~= nil and self.mainModule.callbacks.InteractFilter(obj) end)
	if gate.valid then
		player:rotateTo(gate.pos)
		TaskManager:Interact(gate, function() self.opened_gate = true end)
		return true
	end
		
	return false
end


return Brayflox:new()