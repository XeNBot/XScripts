local Mission  = LoadModule("XScripts", "/Missions/Mission")
local BowlofEmbers = Class("BowlofEmbers", Mission)

function BowlofEmbers:initialize()

	Mission.initialize(self)
    
    self:SetMaps({[35] = true})

	self.battle_fov    = 50
    self.is_trial      = true

    self.infernal_nail_filter = function (obj)
        local infernal_nail = ObjectManager.EventObject(function (obj)
            return obj.isTargetable and obj.dataId == 208
        end)

        if infernal_nail.valid then
           return false
        end

        return true
    end
    -- Doesn't target ifrit if infernal nail is out
    self:AddBattleFilter(207,  self.infernal_nail_filter)

	self.destination   = Vector3(14.28,0,0.1)
    
end

return BowlofEmbers:new()