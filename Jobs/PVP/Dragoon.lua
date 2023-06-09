local XPVPClass   = LoadModule("XScripts", "\\Jobs\\PVP\\XPVPClass")
local Dragoon     = Class("Dragoon", XPVPClass)

function Dragoon:initialize()

	XPVPClass.initialize(self)

	self:SetClassId(22)
	self:LoadMenu("Draggon XPVP")
	self:Menu()

	self.math_utils = LoadModule("XScripts", "\\Utilities\\MathUtils")

	self.actions = {

		raiden_thrust     = Action(1, 29486),
		fang_claw         = Action(1, 29487),
		wheeling_thrust   = Action(1, 29488),

		chaotic_spring    = Action(1, 29490),
		geirskogul        = Action(1, 29491),

		high_jump         = Action(1, 29493),
		elusive_jump      = Action(1, 29494),
		horrid_roar       = Action(1, 29496),
		sky_high          = Action(1, 29497),
		
		purify            = Action(1, 29056),
	}
end

function Dragoon:Menu()

	self.class_menu:subMenu("Wheeling Thrust", "WHEELING_THRUST")
		self.class_menu["WHEELING_THRUST"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Wheeling_Thrust.png")
		self.class_menu["WHEELING_THRUST"]:checkbox("Use", "USE", true)
	self.class_menu:subMenu("Chaotic Spring", "CHAOTIC_SPRING")
		self.class_menu["CHAOTIC_SPRING"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Chaotic_Spring.png")
		self.class_menu["CHAOTIC_SPRING"]:checkbox("Use", "USE", true)
		self.class_menu["CHAOTIC_SPRING"]:slider("Minimum Health Percent", "MIN_HEALTH", 1, 1, 100, 80)
	self.class_menu:subMenu("Geirskogul", "GEIRSKOGUL")
		self.class_menu["GEIRSKOGUL"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Geirskogul.png")
		self.class_menu["GEIRSKOGUL"]:checkbox("Use", "USE", true)
		self.class_menu["GEIRSKOGUL"]:slider("Minimum Enemies", "MIN_ENEMIES", 1, 1, 5, 2)
	self.class_menu:subMenu("Nastrond", "NASTROND")
		self.class_menu["NASTROND"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Nastrond.png")
		self.class_menu["NASTROND"]:checkbox("Use", "USE", true)
		self.class_menu["NASTROND"]:checkbox("Only if enemy life < 50% ", "PERCENTAGE", true)
		self.class_menu["NASTROND"]:checkbox("Force if time is running out", "FORCE", true)
		self.class_menu["NASTROND"]:slider("Min Buff Time before Forcing", "MIN_TIMER", 1, 1, 10, 5)
	self.class_menu:subMenu("High Jump", "HIGH_JUMP")
		self.class_menu["HIGH_JUMP"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\High_Jump.png")
		self.class_menu["HIGH_JUMP"]:checkbox("Use", "USE", true)
		self.class_menu["HIGH_JUMP"]:slider("Don't Jump if #Enemies >= ", "MIN_ENEMIES", 1, 1, 5, 3)
	self.class_menu:subMenu("Elusive Jump", "ELUSIVE_JUMP")
		self.class_menu["ELUSIVE_JUMP"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Elusive_Jump.png")
		self.class_menu["ELUSIVE_JUMP"]:checkbox("Use", "USE", true)
		self.class_menu["ELUSIVE_JUMP"]:checkbox("Use to remove Bind / Heavy", "DEBUFFS", true)
		self.class_menu["ELUSIVE_JUMP"]:checkbox("Use to get back to safety",  "SAFETY",  true)
		self.class_menu["ELUSIVE_JUMP"]:slider("Min Enemies ", "MIN_ENEMIES", 1, 1, 5, 3)
		self.class_menu["ELUSIVE_JUMP"]:checkbox("Check for walls before use", "WALLS",   true)
		self.class_menu["ELUSIVE_JUMP"]:slider("Max Wall Distance ", "WALL_DIST", 1, 1, 15, 10)
	self.class_menu:subMenu("Horrid Roar", "HORRID_ROAR")
		self.class_menu["HORRID_ROAR"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Horrid_Roar.png")
		self.class_menu["HORRID_ROAR"]:checkbox("Use", "USE", true)
		self.class_menu["HORRID_ROAR"]:slider("Min Enemies ", "MIN_ENEMIES", 1, 1, 5, 2)
	self.class_menu:subMenu("Sky High", "SKY_HIGH")
		self.class_menu["SKY_HIGH"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Sky_High.png")
		self.class_menu["SKY_HIGH"]:checkbox("Use", "USE", true)
		self.class_menu["SKY_HIGH"]:slider("Min Executions ", "MIN_ENEMIES", 1, 1, 5, 2)

end

function Dragoon:Execute()
	if self:CanUse("sky_high") or player:hasStatus(1342) then

		local executeCount = 0

		for i, object in ipairs(ObjectManager.GetEnemyPlayers(function(target) return
				not target.isDead and target.pos:dist(player.pos) <= 10 and target.health > 5000 and target.health < 20000
			end)) do
			executeCount = executeCount + 1
		end
		
		if executeCount >= self.class_menu["SKY_HIGH"]["MIN_ENEMIES"].int then
			self:Use("sky_high")
			return true
		end
	end

	return false
end

function Dragoon:Tick()

	if self.class_menu["SKY_HIGH"]["USE"].bool and self:Execute() then return end

	if self.class_menu["ELUSIVE_JUMP"]["USE"].bool and self:CanUse("elusive_jump") then
		
		if self.class_menu["ELUSIVE_JUMP"]["DEBUFFS"].bool and not self:CanUse("purify") then
			if player:hasStatus(1344) or player:hasStatus(1345) and self:CanElusiveJump() then
				self:Use("elusive_jump")
			elseif ObjectManager.EnemiesAroundObject(player, 10) >=  self.class_menu["ELUSIVE_JUMP"]["MIN_ENEMIES"].int then
				self:Use("elusive_jump")
			end
		end

	end

	local far_target   = self:GetTarget(20)

	if far_target.valid and not far_target.ally then
		-- Firstminds' Focus
		if player:hasStatus(3178) then
			self:Use("elusive_jump", far_target)
		elseif self.class_menu["HIGH_JUMP"]["USE"].bool then
			local enemies_around_jump = ObjectManager.EnemiesAroundObject(far_target, 5)
			if self:CanUse("high_jump", far_target) and enemies_around_jump < self.class_menu["HIGH_JUMP"]["MIN_ENEMIES"].int then
				self:Use("high_jump", far_target)
			end
		end
	end

	local geirs_target = self:GetTarget(15)

	if geirs_target.valid and not geirs_target.ally then
		if self.class_menu["GEIRSKOGUL"]["USE"].bool and self:CanUse("geirskogul", geirs_target) then
		
			local dragon_buff = player:getStatus(3177)

			if not dragon_buff.valid then
				local geirs_poly      = self.math_utils:GetLineActionPolygon(player, 3.75, 15)
				local enemies_in_poly = ObjectManager.GetEnemyPlayers(function (enemy)
					return not enemy.IsDead and geirs_poly:is_point_inside(enemy.pos)
				end)
				if #enemies_in_poly >= self.class_menu["GEIRSKOGUL"]["MIN_ENEMIES"].int then
					self:Use("geirskogul", geirs_target)
					return
				end
			else
				if self.class_menu["NASTROND"]["USE"].bool then
				
					if self.class_menu["NASTROND"]["PERCENTAGE"].bool then
						if geirs_target.healthPercent < 50 then
							self:Use("geirskogul", geirs_target)
						end
					end
					if self.class_menu["NASTROND"]["FORCE"].bool then
						if dragon_buff.remainingTime <= self.class_menu["NASTROND"]["MIN_TIMER"].int then
							self:Use("geirskogul", geirs_target)
						end
					end
				end
			end

		end
	end

	if self:CanUse("horrid_roar") and self.class_menu["HORRID_ROAR"]["USE"].bool then
		if ObjectManager.EnemiesAroundObject(player, 10) >= self.class_menu["HORRID_ROAR"]["MIN_ENEMIES"].int then
			self:Use("horrid_roar")
		end
	end

	local target = self:GetTarget(5)

	if target.valid and not target.ally then

		if self:CanUse("chaotic_spring", target) and self.class_menu["CHAOTIC_SPRING"]["USE"].bool and
		 player.healthPercent <= self.class_menu["CHAOTIC_SPRING"]["MIN_HEALTH"].int then
			self:Use("chaotic_spring", target)
		elseif self.class_menu["WHEELING_THRUST"]["USE"].bool then
			if self:CanUse("wheeling_thrust", target) then
				self:Use("wheeling_thrust", target)
			elseif self:CanUse("fang_claw", target) then
				self:Use("fang_claw", target)
			elseif self:CanUse("raiden_thrust", target) then
				self:Use("raiden_thrust", target)
			end
		end
	end
end

function Dragoon:CanElusiveJump()

	if self.class_menu["ELUSIVE_JUMP"]["WALLS"].bool then
		local behind_pos = self.math_utils:GetStraightLinePos(player, -15)
		local cast = Navigation.Raycast(player.pos, behind_pos)

		if (cast == Vector3.Zero) then
			return true
		end

		return cast:dist(player.pos) <= self.class_menu["ELUSIVE_JUMP"]["WALL_DIST"].int
	end

	return true
end

return Dragoon:new()