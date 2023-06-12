local XPVPClass   = LoadModule("XScripts", "\\Jobs\\PVP\\XPVPClass")
local Monk  = Class("Monk", XPVPClass)


function Monk:initialize()

	XPVPClass.initialize(self)

	self:SetClassId(20)
	self:LoadMenu("Monk XPVP")
	self:Menu()

	self.math_utils = LoadModule("XScripts", "\\Utilities\\MathUtils")

	self.actions = {

		-- Phantom Rush Combo
		bootshine       = Action(1, 29472),
		true_strike     = Action(1, 29473),
		snap_punch      = Action(1, 29474),
		dragon_kick     = Action(1, 29475),
		twin_snakes     = Action(1, 29476),
		demolish        = Action(1, 29477),
		phantom_rush    = Action(1, 29478),

		sided_star      = Action(1, 29479),
		enlightement    = Action(1, 29480),
		rising_phoenix  = Action(1, 29481),
		riddle_of_earth = Action(1, 29482),
		earths_reply    = Action(1, 29483),
		thunderclap     = Action(1, 29484),
		meteodrive      = Action(1, 29485),
	}

end

function Monk:Menu()

	self.class_menu:subMenu("Phantom Rush", "PHANTOM_RUSH")
		self.class_menu["PHANTOM_RUSH"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Phantom_Rush.png")
		self.class_menu["PHANTOM_RUSH"]:checkbox("Use", "USE", true)

	self.class_menu:subMenu("Six-sided Star", "SIX_SIDED_STAR")
		self.class_menu["SIX_SIDED_STAR"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Six-sided_Star.png")
		self.class_menu["SIX_SIDED_STAR"]:checkbox("Use", "USE", true)
		self.class_menu["SIX_SIDED_STAR"]:checkbox("Dont use on stunned enemies", "STUNNED", true)

	self.class_menu:subMenu("Enlightenment", "ENLIGHTENMENT")
		self.class_menu["ENLIGHTENMENT"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Enlightenment.png")
		self.class_menu["ENLIGHTENMENT"]:checkbox("Use", "USE", true)
		self.class_menu["ENLIGHTENMENT"]:slider("Minimum Enemies", "MIN_ENEMIES", 1, 1, 5, 2)

	self.class_menu:subMenu("Rising Phoenix", "RISING_PHOENIX")
		self.class_menu["RISING_PHOENIX"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Rising_Phoenix.png")
		self.class_menu["RISING_PHOENIX"]:checkbox("Use", "USE", true)
		self.class_menu["RISING_PHOENIX"]:checkbox("Don't overcap Fire Reasonance", "OVERCAP", true)
		self.class_menu["RISING_PHOENIX"]:slider("Minimum Enemies", "MIN_ENEMIES", 1, 1, 5, 2)

	self.class_menu:subMenu("Riddle of Earth", "RIDDLE_OF_EARTH")
		self.class_menu["RIDDLE_OF_EARTH"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Riddle_of_Earth.png")
		self.class_menu["RIDDLE_OF_EARTH"]:checkbox("Use", "USE", true)
		self.class_menu["RIDDLE_OF_EARTH"]:slider("Minimum Enemies", "MIN_ENEMIES", 1, 1, 5, 2)
		self.class_menu["RIDDLE_OF_EARTH"]:checkbox("Auto Use if Attacked", "AUTO", true)

	self.class_menu:subMenu("Earth's Reply", "EARTHS_REPLY")
		self.class_menu["EARTHS_REPLY"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Earths_Reply.png")
		self.class_menu["EARTHS_REPLY"]:sliderF("Min Buff Timer before Using", "REUSE_TIME", 0, 0.5, 10, 1.0)
		self.class_menu["EARTHS_REPLY"]:checkbox("Use", "USE", true)

	self.class_menu:subMenu("Thunderclap", "THUNDERCLAP")
		self.class_menu["THUNDERCLAP"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Thunderclap.png")
		self.class_menu["THUNDERCLAP"]:checkbox("Use", "USE", true)
		self.class_menu["THUNDERCLAP"]:checkbox("Use only outside of melee range", "RANGE_CHECK", true)
		self.class_menu["THUNDERCLAP"]:checkbox("Don't overcap wind resonance buff", "OVERCAP", true)
		self.class_menu["THUNDERCLAP"]:slider("Min Enemy Range", "MIN_RANGE", 1, 1, 20, 8)
		self.class_menu["THUNDERCLAP"]:slider("Don't jump into X enemies", "MAX_ENEMIES", 1, 1, 5, 3)

	self.class_menu:subMenu("Meteodrive", "METEODRIVE")
		self.class_menu["METEODRIVE"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Meteodrive.png")
		self.class_menu["METEODRIVE"]:checkbox("Use", "USE", true)
end

function Monk:ActionEffect(source, pos, action_id, target_id)
	if source.id ~= player.id and not source.ally and target_id == player.id then
		if self.class_menu["RIDDLE_OF_EARTH"]["AUTO"].bool and self:CanUse("riddle_of_earth") then
			self:Use("riddle_of_earth")
		end
	end
end

function Monk:Tick()

	if self.class_menu["THUNDERCLAP"]["USE"].bool then
		self:Thunderclap()
	end

	if self.class_menu["METEODRIVE"]["USE"].bool then
		self:Meteodrive()
	end	

	local earth_resonance = player:getStatus(3171)

	if self.class_menu["RIDDLE_OF_EARTH"]["USE"].bool and not earth_resonance.valid then
		self:RiddleofEarth()
	end

	if self.class_menu["EARTHS_REPLY"]["USE"].bool and earth_resonance.valid then
		self:EarthsReply(earth_resonance)
	end

	if self.class_menu["ENLIGHTENMENT"]["USE"].bool then
		self:Enlightment()
	end

	if self.class_menu["RISING_PHOENIX"]["USE"].bool then
		self:RisingPhoenix()
	end

	local combo_target = self:GetTarget(5)

	if combo_target.valid and not combo_target.ally then
		if self.class_menu["SIX_SIDED_STAR"]["USE"].bool then
			self:SixSidedStar(combo_target)
		end
		if self.class_menu["PHANTOM_RUSH"]["USE"].bool then
			self:PhantomRushCombo(combo_target)
		end
	end

end

function Monk:Meteodrive()
	
	local filter = function (obj)
		return self:CanUse("meteodrive", obj)
	end

	local list = AgentManager.GetAgent("Map").currentMapId == 51 and ObjectManager.Battle(filter) or ObjectManager.GetEnemyPlayers(filter)

	for i, object in ipairs(list) do
		local damage = 12000
		-- Extra Damage if enemy doesn't have guard
		if not object:hasStatus(3054) then
			damage = damage + 12000
		end
		-- Extra Damage from pressure point
		if object:hasStatus(3172) then
			damage = damage + 8000
		end

		if object.health < damage then
			self:Use("meteodrive", object)
		end

	end
	
end

function Monk:Thunderclap()
	local wind_resonance = player:getStatus(2007)
	-- Overcap check
	if self.class_menu["THUNDERCLAP"]["OVERCAP"].bool  and wind_resonance.valid and wind_resonance.remainingTime > 5 then
		return
	end
	
	local possible_enemies = ObjectManager.GetEnemyPlayers(function (enemy)
		return self:CanUse("thunderclap", enemy)
	end)

	if #possible_enemies > 0 then
		
		table.sort(possible_enemies, function (t1, t2)
			return t1.health > t2.health
		end)

		for i, target in ipairs(possible_enemies) do
			local dist = target.pos:dist(player.pos)
			-- melee check
			if self.class_menu["THUNDERCLAP"]["RANGE_CHECK"].bool and dist < 5 then
				return
			end
			-- min range check
			if self.class_menu["THUNDERCLAP"]["MIN_RANGE"].int > dist then
				return
			end
			-- max enemies check
			local enemies_count = ObjectManager.EnemiesAroundObject(target, 5)
			if enemies_count >= self.class_menu["THUNDERCLAP"]["MAX_ENEMIES"].int then
				return
			end
			self:Use("thunderclap", target)
		end

	end
end

function Monk:EarthsReply(resonance_buff)
	if resonance_buff.remainingTime <= self.class_menu["EARTHS_REPLY"]["REUSE_TIME"].int and self:CanUse("earths_reply") then
		self:Use("earths_reply")
	end
end

function Monk:RiddleofEarth()
	if self:CanUse("riddle_of_earth") and ObjectManager.EnemiesAroundObject(player, 15) >=
		self.class_menu["RIDDLE_OF_EARTH"]["MIN_ENEMIES"].int then
		self:Use("riddle_of_earth")
	end
end

function Monk:RisingPhoenix()
	-- Buff overcap check
	if self.class_menu["RISING_PHOENIX"]["OVERCAP"].bool and player:hasStatus(3170) then
		return
	end

	if self:CanUse("rising_phoenix") and ObjectManager.EnemiesAroundObject(player, 5) >=
		self.class_menu["RISING_PHOENIX"]["MIN_ENEMIES"].int then
		self:Use("rising_phoenix")
	end
end

function Monk:Enlightment()

	local enlight_poly      = self.math_utils:GetLineActionPolygon(player, 2, 10)
	local enemies_in_poly = ObjectManager.GetEnemyPlayers(function (enemy)
		return not enemy.IsDead and enlight_poly:is_point_inside(enemy.pos)
	end)
	if #enemies_in_poly >= self.class_menu["ENLIGHTENMENT"]["MIN_ENEMIES"].int then

		local target = nil

		for i, enemy in ipairs(enemies_in_poly) do
			if target == nil or enemy.health < target.health and not enemy.isDead then
				target = enemy
			end
		end
		if target ~= nil and self:CanUse("enlightement", target) then	
			self:Use("enlightement", target)
		end
	end

end

function Monk:SixSidedStar(target)

	-- Checks for stuns
	if self.class_menu["SIX_SIDED_STAR"]["STUNNED"].bool and target:hasStatus(1343) then
		return
	end

	if self:CanUse("sided_star", target) then
		self:Use("sided_star", target)
	end

end

function Monk:PhantomRushCombo(target)

	if self:CanUse("phantom_rush", target) then
		self:Use("phantom_rush", target)
	elseif self:CanUse("demolish", target) then
		self:Use("demolish", target)
	elseif self:CanUse("twin_snakes", target) then
		self:Use("twin_snakes", target)
	elseif self:CanUse("dragon_kick", target) then
		self:Use("dragon_kick", target)
	elseif self:CanUse("snap_punch", target) then
		self:Use("snap_punch", target)
	elseif self:CanUse("true_strike", target) then
		self:Use("true_strike", target)
	elseif self:CanUse("bootshine", target) then
		self:Use("bootshine", target)
	end

end

return Monk:new()