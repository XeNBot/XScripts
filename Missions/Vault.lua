local Mission  = LoadModule("XScripts", "/Missions/Mission")

local Vault = Class("Vault", Mission)

function Vault:CustomTarget(range)
	
	local Holy_Flame = ObjectManager.BattleObject( function(obj) return (obj.npcId == 4400) and obj.isTargetable and not obj.isDead and obj.pos:dist(player.pos) < range end )
	if Holy_Flame.valid then
		TargetManager.SetTarget(Holy_Flame)
		return true
	end

	return false
end

return Vault:new()