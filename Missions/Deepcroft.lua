local Mission  = LoadModule("XScripts", "/Missions/Mission")

local Deepcroft  = Class("Deepcroft", Mission)

function Deepcroft:initialize()

    Mission.initialize(self)

    self.battle_fov = 20;

    self.priority_event_objects = {
        -- Sealed Barrier
        [2000060] = true,
    }

    self.event_objects = {
        -- Cultist Rosary
        [2000057] = true,
        -- Cultist Orbs
        [2000061] = true,
        [2000062] = true,
        [2000063] = true,
        [2000067] = true,
    }

    self.items = {
        cultist_rosary = { id =  2000244, pos = Vector3(-178.58,14,-5.32) }
    }

    self.changed_destination = false

    self.destination = Vector3(-43.31,14.04,-17.03)
    
    self.sealed_barrier_filter = function (obj)
        local sealed_barrier = ObjectManager.EventObject(function (obj)
            return obj.isTargetable and obj.dataId == 2000060
        end)

        if sealed_barrier.valid then
           if sealed_barrier.pos:dist(obj.pos) < self.event_fov then
                return false
           end
        end

        return true
    end

    self:AddBattleFilter(137,  self.sealed_barrier_filter)
    self:AddBattleFilter(1345, self.sealed_barrier_filter)

    self:AddEventFilter(2000063, self.sealed_barrier_filter)
    self:AddEventFilter(2000067, self.sealed_barrier_filter)
end

function Deepcroft:Tick()

    Mission.Tick(self)

   if not self.changed_destination and InventoryManager.GetItemCount(2000244) == 0 then
        self.destination = self.items.cultist_rosary.pos
        self.priority_event_objects[2000060] = nil
    else
        self.destination = Vector3(-43.31,14.04,-17.03)
        self.changed_destination    = true
        self.priority_event_objects[2000060] = true
    end

end

function Deepcroft:ExitCallback()

    self.destination         = self.items.cultist_rosary.pos
    self.changed_destination = false

end

return Deepcroft:new()