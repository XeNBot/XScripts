local Mission  = LoadModule("XScripts", "/Missions/Mission")
local Hatali   = Class("Hatali", Mission)

function Hatali:initialize()
	self.safeWalk = false
end

function Hatali:CustomTarget(range)
	
	local sprite = ObjectManager.BattleObject( function(obj) return (obj.npcId == 116 or obj.npcId == 117) and obj.isTargetable and not obj.isDead and obj.pos:dist(player.pos) < range end )
	if sprite.valid then
		player:rotateTo(sprite.pos)
		TargetManager.SetTarget(sprite)
		return true
	end

	return false
end

function Hatali:CustomInteract()
	local aetherial = ObjectManager.EventObject(function(obj) return (obj.npcId == 2001647 or obj.npcId == 2001619) and self.mainModule.callbacks.InteractFilter(obj) end)
	if aetherial.valid then
		player:rotateTo(aetherial.pos)
		TaskManager:Interact(aetherial, function() self:OnInteract() end)
		return true
	end	

	local chain = ObjectManager.EventObject(function(obj) return obj.npcId >= 2001624 and obj.npcId <= 2001628 and self.mainModule.callbacks.InteractFilter(obj) end)
	if chain.valid then
		player:rotateTo(chain.pos)
		TaskManager:Interact(chain)
		return true
	end
	
	return false
end

function Hatali:OnInteract()
	
	self.main.route = Route()

end

return Hatali:new()