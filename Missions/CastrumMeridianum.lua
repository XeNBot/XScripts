local Mission  = LoadModule("XScripts", "/Missions/Mission")

local CastrumMeridianum = Class("CastrumMeridianum", Mission)

function CastrumMeridianum:initialize()

    Mission.initialize(self)

    self.event_objects = {
    -- Disposal Chute
    [2000597] = true,


}
end

function CastrumMeridianum:CustomInteract()

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

return CastrumMeridianum:new()