local Mission  = LoadModule("XScripts", "/Missions/Mission")

local StoneVigil = Class("StoneVigil", Mission)

function StoneVigil:initialize()

	Mission.initialize(self)

	self.battle_fov   = 40
	self.treasure_fov = 50

	self:SetMaps({[37] = true})

	self.destination = Vector3(45.75,4,-79.94)
	self.defeated_koshchei = false

	self.dragon_filter = function (obj)
		local wall_pos = Vector3(0.51,0,-103.19)

		return self.defeated_koshchei and wall_pos:dist(obj.pos) < 5

	end

	self:AddBattleFilter(1466, self.dragon_filter)

end

function StoneVigil:Tick()

	Mission.Tick(self)

	local target = TargetManager.Target

	if target.valid and not self.defeated_koshchei and target.npcId == 1678 and ( target.isDead or target.health == 0) then
		self.defeated_koshchei = true
		self.destination = Vector3(0.14,0.04,-246.18)
	end

end

function StoneVigil:ExitCallback()

	self.defeated_koshchei = false
	self.destination       = Vector3(45.75,4,-79.94)

end

return StoneVigil:new()