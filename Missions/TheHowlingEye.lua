local Mission  = LoadModule("XScripts", "/Missions/Mission")
local TheHowlingEye = Class("TheHowlingEye", Mission)

function TheHowlingEye:initialize()

	Mission.initialize(self)
    
	self.battle_fov    = 99
    self.event_fov     = 99
    self.is_trial      = true

    self:SetMaps({[39] = true})

	self.destination   = Vector3(0.89,-1.87,-6.34)
    
    self.feathers_filter = function (obj)
        local razor_plume = ObjectManager.EventObject(function (obj)
            return obj.isTargetable and obj.dataId == 238
        end)

        if razor_plume.valid then
           return false
        end

        return true
    end

    -- Focus Razor Plumes
    self:AddBattleFilter(239,  self.feathers_filter)

end

return TheHowlingEye:new()