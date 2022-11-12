local Mission  = LoadModule("XScripts", "/Missions/Mission")

local BowlOfEmbers = Class("BowlOfEmbers", Mission)

function BowlOfEmbers:CustomTarget(range)
	
	local Infernal_nail = ObjectManager.BattleObject( function(obj) return (obj.npcId == 1186) and obj.isTargetable and not obj.isDead and obj.pos:dist(player.pos) < range end )
	if Infernal_nail.valid then
		TargetManager.SetTarget(Infernal_nail)
		return true
	end

	return false
end

return BowlOfEmbers:new()