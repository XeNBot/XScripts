local Mission  = LoadModule("XScripts", "/Missions/Mission")
local TheNavel = Class("TheNavel", Mission)

function TheNavel:initialize()

	Mission.initialize(self)
    
	self.battle_fov    = 50
    self.is_trial      = true

    self:SetMaps({[33] = true})

	self.destination   = Vector3(0.47,-0.01,-8.4)
    
    self.heart_filter = function (obj)
        local titans_heart = ObjectManager.EventObject(function (obj)
            return obj.isTargetable and obj.dataId == 1507
        end)

        if titans_heart.valid then
           return false
        end

        return true
    end

    -- Focus Heart
    self:AddBattleFilter(246,  self.heart_filter)

end

return TheNavel:new()