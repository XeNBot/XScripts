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
	self.reaper:Load(self.menu)
	-- Ranged Physical DPS
	self.dancer:Load(self.menu)
	self.machinist:Load(self.menu)
	self.bard:Load(self.menu)
	-- Ranged Magic DPS
	self.blackmage:Load(self.menu)
	self.summoner:Load(self.menu)
	self.redmage:Load(self.menu)
	-- Common Actions
	self.common:Load(self.menu)

	self.lockTarget   = nil

	self.getTarget    = function (dist) return self:GetTarget(dist) end
	self.targetFilter = function (target) return self:TargetFilter(target) end

	Callbacks:Add(CALLBACK_PLAYER_TICK, function() self:Tick() end)

	self.log:print("XPVP Loaded!")

end

function XPVP:Tick()
	-- PVP Maps
	if not Game.InPvPArea and not Game.InPvPInstance and AgentModule.currentMapId ~= 51 then return end
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
		elseif player.classJob == 23 then
			self.bard:Tick(self.getTarget, self.log)
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
		elseif player.classJob == 39 then
			self.reaper:Tick(self.getTarget, self.log)
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
	if self.menu["TARGET"]["GUARD_CHECK"].bool then
		return not target:hasStatus(3054)
	end
	return true
end

function XPVP:GetTarget(range)
	-- PVP Training Map
	if AgentModule.currentMapId == 51 or not self.menu["TARGET"]["AUTO"].bool then
		return TargetManager.Target
	end

	local target = nil

	if self.menu["TARGET"]["LOCK"].bool and self.lockTarget ~= nil then
		return self.lockTarget
	end

	if self.menu["TARGET"]["MODE"].int == 0 then
		return ObjectManager.GetLowestHealthEnemy(range, self.targetFilter)
	else
		return ObjectManager.GetClosestEnemy(self.targetFilter)

	end

	return target
end

XPVP:new()