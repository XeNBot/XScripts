local Mission  = LoadModule("XScripts", "/Missions/Mission")

local Sastasha = Class("Sastasha", Mission)

function Sastasha:initialize()
	
	Mission.initialize(self)

	self.event_objects = {
		-- Coral Formations
		[2000213] = true,
		[2000214] = true,
		[2000215] = true,
		-- Inconspicuous Switch
		[2000216] = true,
		-- Captain's Quaters Door
		[2000227] = true,
		-- Waverider Gate
		[2000231] = true,
		-- Captain's Quaters Door Key
		[2000250] = true,
		-- Waverider Gate Key
		[2000250] = true,


	}
end

function Sastasha:CustomInteract()

	if ObjectManager.BattleEnemiesAroundObject(player, 15) > 0 then return false end

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

return Sastasha:new()