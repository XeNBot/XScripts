local Common = Class("Common")

function Common:initialize()

	self.actions = {
		
		guard      = Action(1, 29054),
		recuperate = Action(1, 29711),
		purify     = Action(1, 29056),
		sprint     = Action(1, 29057),

		-- Samurai
		mei         = Action(1, 29536),		
		-- Reaper
		arcane      = Action(1, 29552)
	}

	self.purify_statusIds = {

		-- Stun 
		1343,
		-- Heavy
		1344,
		-- Bind
		1345,
		-- Sleep
		1348, 1363,
		-- Half-Sleep
		3022,
		-- Deep Freeze
		487, 1150, 1254, 1731, 1758, 2252, 2658, 3219
	}

	self.menu = nil

end

function Common:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["COMMON"]:checkbox("Use Purify",     "PURIFY", true)
	self.menu["ACTIONS"]["COMMON"]:checkbox("Use Recuperate", "RECUPERATE", true)
	self.menu["ACTIONS"]["COMMON"]:checkbox("Use Guard",      "GUARD", true)
	self.menu["ACTIONS"]["COMMON"]:checkbox("Use Sprint",     "SPRINT", true)


end

function Common:ShouldPurify()
	for i, statusId in ipairs(self.purify_statusIds) do
		if player:hasStatus(statusId) then
			if player.classJob == 34 and self.menu["ACTIONS"]["MELEE_DPS"]["SAM"]["MEI"].bool and self.actions.mei:canUse() then
				self.actions.mei:use()
				return false
			end
			return true
		end
	end

end

function Common:Tick()
	
	local actions = self.actions
	local menu    = self.menu["ACTIONS"]["COMMON"]

	if menu["SPRINT"].bool and ObjectManager.EnemiesAroundObject(player, 30) == 0 and not player:hasStatus(1342) and actions.sprint:canUse() then
		actions.sprint:use()
		return true
	elseif menu["PURIFY"].bool and self:ShouldPurify() and actions.purify:canUse() then
		actions.purify:use()
		return true
	elseif player.classJob == 39 and self.menu["ACTIONS"]["MELEE_DPS"]["RPR"]["ARCANE"].bool and (player.maxHealth - player.health) > 18000 and 
		self.actions.arcane:canUse() then
		self.actions.arcane:use()
		return true
	elseif menu["RECUPERATE"].bool and (player.maxHealth - player.health) > 15000 and actions.recuperate:canUse() then
		actions.recuperate:use()
		return true
	elseif not player:hasStatus(3039) and menu["GUARD"].bool and player.health < 20000 and ObjectManager.EnemiesAroundObject(player, 10) > 1 and actions.guard:canUse() then
		actions.guard:use()
		return true
	end

	return false
end

return Common:new()