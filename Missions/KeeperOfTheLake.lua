local Mission  = LoadModule("XScripts", "/Missions/Mission")

local KeeperOfTheLake = Class("KeeperOfTheLake", Mission)

function KeeperOfTheLake:initialize()

    Mission.initialize(self)

    self.event_objects = {
        -- Imperial Identification Card
        [2004844] = true,
        [2004975] = true,
        -- Magitek Terminal
        [2004829] = true,
        [2004834] = true,
}
end

function KeeperOfTheLake:CustomInteract()

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

function KeeperOfTheLake:CustomTarget(range)
	
	local Cohort_Vangaurd = ObjectManager.BattleObject( function(obj) return (obj.npcId == 3357) and obj.isTargetable and not obj.isDead and obj.pos:dist(player.pos) < range end )
	if Cohort_Vangaurd.valid then
		TargetManager.SetTarget(Cohort_Vangaurd)
		return true
	end

    local Mirage_Dragon = ObjectManager.BattleObject( function(obj) return (obj.npcId == 3375) and obj.isTargetable and not obj.isDead and obj.pos:dist(player.pos) < range end )
	if Mirage_Dragon.valid then
		TargetManager.SetTarget(Mirage_Dragon)
		return true
	end

	return false
end

return KeeperOfTheLake:new()