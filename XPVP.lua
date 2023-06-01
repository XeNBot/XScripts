local XPVP = Class("XPVP")

function XPVP:initialize()
	-- Loads Menu Module
	self.menu        = LoadModule("XScripts", "\\Menus\\XPVPMenu")
	-- Log Module
	self.log         = LoadModule("XScripts", "\\Utilities\\Log")
	-- Loads Class Job Modules
	-- Healers
	self.scholar     = LoadModule("XScripts", "\\Jobs\\PVP\\Scholar")
	self.astrologian = LoadModule("XScripts", "\\Jobs\\PVP\\Astrologian")
	self.sage        = LoadModule("XScripts", "\\Jobs\\PVP\\Sage")
	-- Tanks
	self.warrior     = LoadModule("XScripts", "\\Jobs\\PVP\\Warrior")
	self.paladin     = LoadModule("XScripts", "\\Jobs\\PVP\\Paladin")
	self.darkknight  = LoadModule("XScripts", "\\Jobs\\PVP\\DarkKnight")
	self.gunbreaker  = LoadModule("XScripts", "\\Jobs\\PVP\\Gunbreaker")
	-- Melee DPS
	self.monk        = LoadModule("XScripts", "\\Jobs\\PVP\\Monk")
	self.dragoon     = LoadModule("XScripts", "\\Jobs\\PVP\\Dragoon")
	self.ninja       = LoadModule("XScripts", "\\Jobs\\PVP\\Ninja")
	self.samurai     = LoadModule("XScripts", "\\Jobs\\PVP\\Samurai")
	self.reaper      = LoadModule("XScripts", "\\Jobs\\PVP\\Reaper")
	-- Ranged Physical DPS
	self.machinist   = LoadModule("XScripts", "\\Jobs\\PVP\\Machinist")
	self.dancer      = LoadModule("XScripts", "\\Jobs\\PVP\\Dancer")
	self.bard        = LoadModule("XScripts", "\\Jobs\\PVP\\Bard")
	-- Ranged Magic DPS
	self.blackmage   = LoadModule("XScripts", "\\Jobs\\PVP\\BlackMage")
	self.summoner    = LoadModule("XScripts", "\\Jobs\\PVP\\Summoner")
	self.redmage     = LoadModule("XScripts", "\\Jobs\\PVP\\RedMage")
	-- Common Actions
	self.common      = LoadModule("XScripts", "\\Jobs\\PVP\\Common") 

	-- Temp Loading for new classes
	self.bard:SetMainModule(self)
	self.reaper:SetMainModule(self)

	-- Loads the menus of each Job
	-- Healers
	self.scholar:Load(self.menu)
	self.astrologian:Load(self.menu)
	self.sage:Load(self.menu)
	-- Tanks
	self.warrior:Load(self.menu)
	self.paladin:Load(self.menu)
	self.darkknight:Load(self.menu)
	self.gunbreaker:Load(self.menu)
	-- Melee DPS
	self.monk:Load(self.menu)
	self.dragoon:Load(self.menu)
	self.ninja:Load(self.menu)
	self.samurai:Load(self.menu)

	-- Ranged Physical DPS
	self.dancer:Load(self.menu)
	self.machinist:Load(self.menu)
	-- Ranged Magic DPS
	self.blackmage:Load(self.menu)
	self.summoner:Load(self.menu)
	self.redmage:Load(self.menu)
	-- Common Actions
	self.common:Load(self.menu)

	self.lockTarget       = nil

	self.lastGuard        = 0
	self.last_auto_target = 0

	self.getTarget    = function (dist) return self:GetTarget(dist) end
	self.targetFilter = function (target) return self:TargetFilter(target) end

	Callbacks:Add(CALLBACK_PLAYER_TICK, function() self:Tick() end)

	Callbacks:Add(CALLBACK_ACTION_REQUESTED, function(actionType, actionId, targetId, result)
		if result == 1 and actionId == 29054 then
			self.lastGuard = os.clock()
		end

	end)

	self.shot   = Action(1, 8)
	self.attack = Action(1, 7)

	self.log:print("XPVP Loaded!")

end

function XPVP:Tick()
	if (os.clock() - self.lastGuard < 4.5) then return end

	Game.ActionDirectionCheck = self.menu["ACTIONS"]["DIRECTION_CHECK"].bool

	if (os.clock() - self.last_auto_target) > 1 and self.menu["AUTO_TARGET_KEY"].keyDown then
		if self.menu["TARGET"]["AUTO"].bool then
			self.menu["TARGET"]["AUTO"].bool = false
		else
			self.menu["TARGET"]["AUTO"].bool = true
		end
		self.last_auto_target = os.clock()
	end

	-- PVP Maps
	local mapId = 0

	local agentMap = AgentManager.GetAgent("Map")

	if agentMap ~= nil then
		mapId = agentMap.currentMapId
	end

	if not Game.InPvPArea and not Game.InPvPInstance and mapId ~= 51 then return end
	-- Guard
	if player:hasStatus(3054) then return end
	-- Invisible
	if player:hasStatus(895) then return end
	
	-- Common Actions
	if self.common:Tick(self.log) then return end

	if Keyboard.IsKeyDown(9) and self.menu["TARGET"]["LOCK"].bool then
		self:SetTabTarget()
	end

	

	if self.lockTarget ~= nil and not TargetManager.Target.valid or (TargetManager.Target.valid and TargetManager.Target.isDead) then
		self.lockTarget = nil

	end

	-- Target Mode
	TargetManager.TargetMode = self.menu["TARGET"]["MODE"].int

	if (self.menu["COMBO_MODE"].int == 0 and not self.menu["COMBO_KEY"].keyDown)  or (self.menu["COMBO_MODE"].int ~= 0 and self.menu["COMBO_KEY"].keyDown) or self.menu["JUMP_KEY"].keyDown then
		if player.classJob == 19 then
			self.paladin:Tick(self.log)
		elseif player.classJob == 20 then
			self.monk:Tick(self.getTarget, self.log)
		elseif player.classJob == 21 then
			self.warrior:Tick(self.log)
		elseif player.classJob == 22 then
			self.dragoon:Tick(self.getTarget, self.log)
		elseif player.classJob == 25 then
			self.blackmage:Tick(self.getTarget, self.log)
		elseif player.classJob == 27 then
			self.summoner:Tick(self.getTarget, self.log)
		elseif player.classJob == 28 then
			self.scholar:Tick(self.getTarget, self.log)
		elseif player.classJob == 30 then
			self.ninja:Tick(self.getTarget, self.log)
		elseif player.classJob == 31 then
			self.machinist:Tick(self.log)
		elseif player.classJob == 32 then
			self.darkknight:Tick(self.getTarget, self.log)
		elseif player.classJob == 33 then
			self.astrologian:Tick(self.getTarget, self.log)
		elseif player.classJob == 34 then
			self.samurai:Tick(self.getTarget, self.log)
		elseif player.classJob == 35 then
			self.redmage:Tick(self.getTarget, self.log)
		elseif player.classJob == 37 then
			self.gunbreaker:Tick(self.getTarget, self.log)
		elseif player.classJob == 38 then
			self.dancer:Tick(self.getTarget, self.log)
		elseif player.classJob == 40 then
			self.sage:Tick(self.getTarget, self.log)
		end
	end
end

function XPVP:SetTabTarget()
	
	if TargetManager.Target.valid and self.lockTarget ~= TargetManager.Target then
		self.lockTarget = TargetManager.Target
		self.log:print("Locking to Target: " .. TargetManager.Target.name)		
	end
end


function XPVP:TargetFilter(target)

	local dist_pass = self:CanAttack(target)

	if self.menu["TARGET"]["GUARD_CHECK"].bool then
		return not target:hasStatus(3054) and dist_pass
	end

	return not target.ally and dist_pass
end

function XPVP:CanAttack(target)
	return self.attack:canUse(target) or self.shot:canUse(target)
end

function XPVP:GetTarget(range)
	-- PVP Training Map

	local mapId = 0

	local agentMap = AgentManager.GetAgent("Map")

	if agentMap ~= nil then
		mapId = agentMap.currentMapId
	end

	if mapId == 51 or not self.menu["TARGET"]["AUTO"].bool then
		local target = TargetManager.Target
		if target.valid then
			return target
		end

		return nil

	end

	local target = nil

	if self.menu["TARGET"]["LOCK"].bool and self.lockTarget ~= nil and not self.lockTarget:hasStatus(3054) then
		--print("Returning Lock Target!")
		return self.lockTarget
	end

	if self.menu["TARGET"]["MODE"].int == 0 then
		local target = ObjectManager.GetLowestHealthEnemy(range, self.targetFilter)

		if target.valid then
			--print("Returning target : " .. target.name)
		end

		return target
	else
		--print("Returning Closest Enemy!")
		return ObjectManager.GetClosestEnemy(self.targetFilter)

	end

	return target
end

XPVP:new()