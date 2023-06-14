local XPVPClass   = LoadModule("XScripts", "\\Jobs\\PVP\\XPVPClass")
local BlackMage  = Class("BlackMage", XPVPClass)

function BlackMage:initialize()

	XPVPClass.initialize(self)

	self:SetClassId(25)
	self:LoadMenu("Black Mage XPVP")
	self:Menu()

	self.combo_mode        = "FIRE"
	self.last_combo_change = os.clock()

	self.actions = {

		fire            = Action(1, 29649),
		blizzard        = Action(1, 29653),
		burst           = Action(1, 29657),
		night_wing      = Action(1, 29659),
		manipulation    = Action(1, 29660),
		superflare      = Action(1, 29661),
		soul_resonance  = Action(1, 29662),
		paradox         = Action(1, 29663),
	}

end

function BlackMage:Menu()
	
	self.class_menu:subMenu("Burst", "BURST")
		self.class_menu["BURST"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Burst.png")
		self.class_menu["BURST"]:checkbox("Use",     "USE", true)
		self.class_menu["BURST"]:slider("Min Enemies", "MIN_ENEMIES", 1, 1, 5, 2)

	self.class_menu:subMenu("Paradox", "PARADOX")
		self.class_menu["PARADOX"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Paradox.png")
		self.class_menu["PARADOX"]:checkbox("Use",     "USE", true)
		self.class_menu["PARADOX"]:checkbox("Only at 1 stack", "STACK_CHECK", true)

	self.class_menu:subMenu("Night Wing", "NIGHT_WING")
		self.class_menu["NIGHT_WING"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Night_Wing.png")
		self.class_menu["NIGHT_WING"]:checkbox("Use",     "USE", true)
		self.class_menu["NIGHT_WING"]:slider("Min Enemies To Sleep", "MIN_ENEMIES", 1, 1, 5, 3)

	self.class_menu:subMenu("Manipulation", "MANIPULATION")
		self.class_menu["MANIPULATION"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Aetherial_Manipulation.png")
		self.class_menu["MANIPULATION"]:checkbox("Use to jump to safety",  "SAFETY", true)
		self.class_menu["MANIPULATION"]:slider("Min Enemies To Jump", "MIN_ENEMIES", 1, 1, 5, 2)
		self.class_menu["MANIPULATION"]:slider("Safety Range", "SAFETY_RANGE", 1, 1, 25, 10)
		self.class_menu["MANIPULATION"]:slider("Min Jump Range", "JUMP_RANGE", 1, 1, 25, 10)

	self.class_menu:subMenu("Superflare", "SUPERFLARE")
		self.class_menu["SUPERFLARE"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Superflare.png")
		self.class_menu["SUPERFLARE"]:checkbox("Use",  "USE", true)
		self.class_menu["SUPERFLARE"]:slider("Min Astral Warmth Stacks", "ASTRAL_MIN", 1, 1, 3, 3)
		self.class_menu["SUPERFLARE"]:slider("Min Umbral Freeze Stacks", "UMBRAL_MIN", 1, 1, 3, 3)

	self.class_menu:subMenu("Soul Resonance", "SOUL_RESONANCE")
		self.class_menu["SOUL_RESONANCE"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Soul_Resonance.png")
		self.class_menu["SOUL_RESONANCE"]:checkbox("Use",  "USE", true)
		self.class_menu["SOUL_RESONANCE"]:checkbox("Don't use at max superflare stacks",  "SUPERFLARE_CHECK", true)


	self.class_menu:subMenu("Foul", "FOUL")
		self.class_menu["FOUL"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Foul.png")
		self.class_menu["FOUL"]:checkbox("Use",  "USE", true)
		self.class_menu["FOUL"]:checkbox("Smart Use",  "SMART_USE", true)

	self.class_menu:subMenu("Draw Options", "DRAW_OPTIONS")
		self.class_menu["DRAW_OPTIONS"]:setIcon("XScripts", "\\Resources\\Icons\\Misc\\Draws.png")
		self.class_menu["DRAW_OPTIONS"]:checkbox("Draw Combo Mode", "DRAW_MODE", true)
		self.class_menu["DRAW_OPTIONS"]:slider("Combo Mode X Pos", "DRAW_X", 1, 1, 1920, 30)
		self.class_menu["DRAW_OPTIONS"]:slider("Combo Mode Y Pos", "DRAW_Y", 1, 1, 1080, 400)
		self.class_menu["DRAW_OPTIONS"]:separator()
		self.class_menu["DRAW_OPTIONS"]:checkbox("Draw Safety Range", "DRAW_SAFETY", true)
	self.class_menu:hotkey("Change Mode ", "COMBO_MODE", 84)

end

function BlackMage:Tick()

	-- Checks for combo rotations
	self:RotateCombo()
	-- Checks if we need to jump
	self:AetherialManipulation()

	if self.class_menu["SOUL_RESONANCE"]["USE"].bool then
		self:SoulResonance()
	end

	if self.class_menu["BURST"]["USE"].bool then
		self:Burst()
	end

	if self.class_menu["SUPERFLARE"]["USE"].bool then
		self:Superflare()
	end

	if self.class_menu["NIGHT_WING"]["USE"].bool then
		self:NightWing()
	end

	local target = self:GetTarget(25)
	if target.valid and not target.ally then
		local astral_warmth = target:getStatus(3216)
		local umbral_freeze = target:getStatus(3217)

		if self.class_menu["PARADOX"]["USE"].bool then
			self:Paradox(target, astral_warmth, umbral_freeze)
		end
		self:FireIce(target)
	end
end

function BlackMage:Draw()

	if self.class_menu["DRAW_OPTIONS"]["DRAW_SAFETY"].bool then

		local min_enemies  = self.class_menu["MANIPULATION"]["MIN_ENEMIES"].int
		local safety_range = self.class_menu["MANIPULATION"]["SAFETY_RANGE"].int
		local color = ObjectManager.EnemiesAroundObject(player, safety_range) < min_enemies and Colors.Green or Colors.Red

		Graphics.DrawCircle3D(player.pos, 20, safety_range, color)

	end

	if self.class_menu["DRAW_OPTIONS"]["DRAW_MODE"].bool then

		local color = self.combo_mode == "FIRE" and Colors.Red or Colors.Blue

		Graphics.DrawText2D(
			self.class_menu["DRAW_OPTIONS"]["DRAW_X"].int,
			self.class_menu["DRAW_OPTIONS"]["DRAW_Y"].int,
			"BLACK MAGE COMBO MODE: ", 15, Colors.Yellow
		)
		Graphics.DrawText2D(
			self.class_menu["DRAW_OPTIONS"]["DRAW_X"].int + 200,
			self.class_menu["DRAW_OPTIONS"]["DRAW_Y"].int,
			self.combo_mode, 15, color
		)
	end
end

function BlackMage:SoulResonance()

	local soul_buff = player:getStatus(3222)
	local poly_buff = player:getStatus(3169)

	if not soul_buff.valid then

		if not self:CanUse("soul_resonance") then
			return
		end

		if self.class_menu["SOUL_RESONANCE"]["SUPERFLARE_CHECK"].bool and self:SuperflareCap() then
			return
		end

		if ObjectManager.EnemiesAroundObject(player, 25) > 1 then
			self:Use("soul_resonance")
		end

	else
		
		local target = self:GetTarget(25)
		
		if poly_buff.valid then

			if self.class_menu["FOUL"]["SMART_USE"].bool then
				
				if target.valid and not target.ally and target.missingHealth >= 16000 then
					self:Use("soul_resonance", target)
				else
					local enemy          = nil
					local enemies_around = 0

					for i, e in ipairs(ObjectManager.GetEnemyPlayers(function (e)
						return not e.isDead and Navigation.Raycast(player.pos, e.pos) == Vector3.Zero
					end)) do
						local count =  ObjectManager.EnemiesAroundObject(e, 5)
						if count > enemies_around then
							enemy          = e
							enemies_around = count
						end
					end

					if enemy ~= nil then
						self:Use("soul_resonance", enemy)
					end
				end
			else
				if target.valid and not target.ally then
					self:Use("soul_resonance", target)
				end
			end
		end

		if target.valid and not target.ally then
			self:FireIce(target)
		end

	end

end

function BlackMage:SuperflareCap()

	return self.actions.superflare.timerElapsed == 0 or self.actions.superflare.timerElapsed > 20

end

function BlackMage:Superflare()

	if not self:CanUse("superflare") then return end

	local min_warmth = self.class_menu["SUPERFLARE"]["ASTRAL_MIN"].int
	local min_freeze = self.class_menu["SUPERFLARE"]["UMBRAL_MIN"].int

	local enemies =  ObjectManager.GetEnemyPlayers(function (enemy)
		
		if not enemy.isDead and enemy.pos:dist(player.pos) <= 30 then

			local astral_warmth = enemy:getStatus(3216)
			local umbral_freeze = enemy:getStatus(3217)
			
			return ((astral_warmth.valid and astral_warmth.count >= min_warmth) or
				   (umbral_freeze.valid and umbral_freeze.count >= min_freeze))

		end
		
		return false

	end)

	if #enemies > 0 then
		self:Use("superflare")
	end

end

function BlackMage:AetherialManipulation()

	if self.class_menu["MANIPULATION"]["SAFETY"].bool then

		local min_enemies    = self.class_menu["MANIPULATION"]["MIN_ENEMIES"].int
		local safety_range   = self.class_menu["MANIPULATION"]["SAFETY_RANGE"].int
		local jump_range     = self.class_menu["MANIPULATION"]["JUMP_RANGE"].int
		local enemies_around = ObjectManager.EnemiesAroundObject(player, safety_range)

		if enemies_around >= min_enemies then

			local safe_allies = ObjectManager.GetAllyPlayers(function (ally)
				return self:CanUse("manipulation", ally) and ObjectManager.EnemiesAroundObject(ally, safety_range) < enemies_around
				 and ally.pos:dist(player.pos) > jump_range and Navigation.Raycast(player.pos, ally.pos) == Vector3.Zero
			end)

			if #safe_allies > 0 then
				self:Use("manipulation", safe_allies[1])
			end

		end
	end

end

function BlackMage:Burst()

	if ObjectManager.EnemiesAroundObject(player, 5) >= self.class_menu["BURST"]["MIN_ENEMIES"].int then
		self:Use("burst")
	end
end

function BlackMage:Paradox(target, astral_warmth, umbral_freeze)

	if self.class_menu["PARADOX"]["STACK_CHECK"].bool then
		-- if enemy doesn't have any stacks
		if not astral_warmth.valid and not umbral_freeze.valid then
			return
		end
		-- if they have more than 1 stack
		if (astral_warmth.valid and astral_warmth.count > 1) or
		   (umbral_freeze.valid and umbral_freeze.count > 1) then
			return
		end
	end

	if self:CanUse("paradox", target) then
		self:Use("paradox", target)
	end
end

function BlackMage:NightWing()

	local min_count = self.class_menu["NIGHT_WING"]["MIN_ENEMIES"].int - 1
	local enemies   = ObjectManager.GetEnemyPlayers(function (enemy)
		return self:CanUse("night_wing", enemy) and ObjectManager.EnemiesAroundObject(enemy, 5) >= min_count
	end)

	if #enemies > 0 then
		self:Use("night_wing", enemies[1])
	end

end

function BlackMage:FireIce(target)
	if self.combo_mode == "FIRE" and self:CanUse("fire", target) then
		self:Use("fire", target)
	elseif self.combo_mode == "ICE" and self:CanUse("blizzard", target) then
		self:Use("blizzard", target)
	end
end

function BlackMage:RotateCombo()

	if os.clock() - self.last_combo_change < 0.5 then return end

	if self.class_menu["COMBO_MODE"].keyDown then
		self.combo_mode = self.combo_mode == "FIRE" and "ICE" or "FIRE"
		self.last_combo_change = os.clock()
	end
end


return BlackMage:new()