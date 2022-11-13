local Mission  = LoadModule("XScripts", "/Missions/Mission")

local Snowcloak = Class("Snowcloak", Mission)

function Snowcloak:initialize()

    Mission.initialize(self)

    self.event_objects = {
    -- Door to Silence
    [2004203] = true,
    [2004224] = true,


}
end

function Snowcloak:CustomInteract()

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

return Snowcloak:new()