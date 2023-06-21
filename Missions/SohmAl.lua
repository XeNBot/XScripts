local Mission  = LoadModule("XScripts", "/Missions/Mission")

local SohmAl = Class("SohmAl", Mission)

function SohmAl:initialize()

	Mission.initialize(self)

	self.battle_fov     = 30
	self:SetMaps({[227] = true, [228] = true, [229] = true})
	self.destination    = Vector3(-90.63, 19.27, 123.76)

	self.wings_filter = function (obj)
        local wing = ObjectManager.EventObject(function (obj)
            return obj.isTargetable and 
				(obj.dataId == 4388 or obj.dataId == 4389)
        end)

        if wing.valid then
           return false
        end

        return true
    end
    -- Doesn't target Tioman if wings are out
    self:AddBattleFilter(3734,  self.wings_filter)

end


function SohmAl:BeforeTick()
	if self.map_id == 227 then
		self.destination = Vector3(-90.63, 19.27, 123.76)
	elseif self.map_id == 228 then
		self.destination = Vector3(197.03, 140.89, -142.33)
	elseif self.map_id == 229 then
		self.destination = Vector3(-102.05,348.16,-396.21)
	end
end

return SohmAl:new()