local XPVEClass  = LoadModule("XScripts", "\\Jobs\\PVE\\XPVEClass")
local Gunbreaker = Class("Gunbreaker", XPVEClass)

function Gunbreaker:initialize()

	XPVEClass.initialize(self)

	self.class_range = 3

    self:SetClassIds({37})
    self:LoadWidget("Gunbreaker XPVE")

	self.class_widget:subMenu("Gunbreaker Actions", "GUNBREAKER")
		self.class_widget["GUNBREAKER"]:setIcon("XScripts", "\\Resources\\Icons\\Classes\\Gunbreaker.png")

		self.class_widget["GUNBREAKER"]:subMenu("No Mercy Settings", "NO_MERCY")
			self.class_widget["GUNBREAKER"]["NO_MERCY"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\no_mercy.png")
			self.class_widget["GUNBREAKER"]["NO_MERCY"]:checkbox("Use No Mercy", "USE", true)
			self.class_widget["GUNBREAKER"]["NO_MERCY"]:checkbox("Only Use at Max Cartridges", "USE_MAX", true)

		self.class_widget["GUNBREAKER"]:subMenu("Bloodfest Settings", "BLOODFEST")
			self.class_widget["GUNBREAKER"]["BLOODFEST"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\bloodfest.png")
			self.class_widget["GUNBREAKER"]["BLOODFEST"]:checkbox("Use Bloodfest", "USE", true)
			self.class_widget["GUNBREAKER"]["BLOODFEST"]:slider("Max Cartridges", "MAX_CARTS", 0, 0, 3, 0)

		self.class_widget["GUNBREAKER"]:checkbox("Use Royal Guard", "ROYAL_GUARD", true)
			self.class_widget["GUNBREAKER"]["ROYAL_GUARD"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\royal_guard.png")



	self:LoadRoleMenu()
	self:LoadWidgetCombo()

		self.class_widget["COMBO_SETTINGS"]:checkbox("Prevent Cart Overstacking", "OVER_STACK", true)
		self.class_widget["COMBO_SETTINGS"]:separator()

	self:LoadWidgetAoE()

	self.last_gcd = 0

	self.actions = {
		keen_edge       = Action(1, 16137),
		no_mercy        = Action(1, 16138),
		brutal_shell    = Action(1, 16139),
		camouflage      = Action(1, 16140),
		demon_slice     = Action(1, 16141),
		royal_guard     = Action(1, 16142),
		lightning_shot  = Action(1, 16143),
		danger_zone     = Action(1, 16144),
		solid_barrel    = Action(1, 16145),
		gnashing_fang   = Action(1, 16146),
		savage_claw     = Action(1, 16147),
		nebula          = Action(1, 16148),
		demon_slaughter = Action(1, 16149),
		wicked_talon    = Action(1, 16150),
		aurora          = Action(1, 16151),
		superbolider    = Action(1, 16152),
		sonic_break     = Action(1, 16153),
		rough_divide    = Action(1, 16154),

		burst_strike    = Action(1, 16162),
		bloodfest       = Action(1, 16164),
		blasting_zone   = Action(1, 16165),

		double_down     = Action(1, 25760)
	}

end

function XPVEClass:ActionEffect(source, pos, action_id, target_id)

	if source.id == player.id then
		if action_id == self.actions.gnashing_fang.id then
			self.last_gcd = 1
		elseif action_id == self.actions.savage_claw.id then
			self.last_gcd = 2
		elseif action_id == self.actions.danger_zone.id or action_id == self.actions.blasting_zone.id then
			self.last_gcd = 3
		elseif action_id == self.actions.wicked_talon.id then
			self.last_gcd = 0
		end
	end

end

function Gunbreaker:Tick()
	local target = self.get_target()
	local ammo   = player.gauge.ammo

	if self:ShouldRoyalGuard() then
		self:Use("royal_guard")
	end
	if self:ShouldBloodfest(ammo) then
		self:Use("bloodfest")
	end
	if self:ValidTarget(target) then
		if self:HasNoMercy() and self:HandleMercyGCDS(target) then
			return
		elseif self:IsNoMercyEnabled(ammo) then
			self:Use("no_mercy")
		end
		if ammo > 0 then
			self:HandleAmmo(target, ammo)
		end
		if self.aoe then
			self:DemonSlaughterCombo(target)
		else
			self:SolidBarrelCombo(target)
		end
	end

end

function Gunbreaker:SolidBarrelCombo(target)

	if self:ComboActionIs("brutal_shell") and self:CanUse("solid_barrel", target) then
		self:Use("solid_barrel", target)
	elseif self:ComboActionIs("keen_edge") and self:CanUse("brutal_shell", target) then
		self:Use("brutal_shell", target)
	elseif self:CanUse("keen_edge", target) then
		self:Use("keen_edge", target)
	end

end

function Gunbreaker:DemonSlaughterCombo(target)

	if self:ComboActionIs("demon_slice") and self:CanUse("demon_slaughter", target) then
		self:Use("demon_slaughter", target)
	elseif self:ComboActionIs("demon_slice") and self:CanUse("demon_slice", target) then
		self:Use("demon_slice", target)
	end
end

function Gunbreaker:HandleAmmo(target, ammo)
	if not self.class_widget["GUNBREAKER"]["NO_MERCY"]["USE_MAX"].bool then
		self:HandleMercyGCDS(target)
	elseif not self:HasNoMercy() and ammo == self:GetMaxCarts() and self.actions.no_mercy.timerElapsed < 30 then
		self:HandleMercyGCDS(target)
	end

	if not self:HasNoMercy() and ammo == self:GetMaxCarts() and self.actions.no_mercy.timerElapsed < 55 and self:CanUse("burst_strike", target) then
		self:Use("burst_strike", target)
	end
end

function Gunbreaker:HandleMercyGCDS(target)

	if  self:CanUse("gnashing_fang", target) and self.last_gcd == 0 then
		self:Use("gnashing_fang", target)
		return true
	elseif self:CanUse("double_down") then
		self:Use("double_down")
		return true
	elseif self:CanUse("sonic_break", target) then
		self:Use("sonic_break", target)
		return true
	elseif self:CanUse("savage_claw", target) then
		self:Use("savage_claw", target)
		return true
	elseif self.last_gcd == 2 then
		if self:CanUse("blasting_zone", target) then
			self:Use("blasting_zone", target)
			return true
		elseif self:CanUse("danger_zone", target)  then
			self:Use("danger_zone", target)
			return true
		end
	elseif self:CanUse("wicked_talon", target) then
		self:Use("wicked_talon", target)
		return true
	elseif self:CanUse("burst_strike", target) then
		self:Use("burst_strike", target)
		return true
	end

	return false
end

function Gunbreaker:HasNoMercy()
	return player:hasStatus(1831)
end

function Gunbreaker:IsNoMercyEnabled(ammo)

	if self.class_widget["GUNBREAKER"]["NO_MERCY"]["USE_MAX"].bool and ammo < self:GetMaxCarts() then
		return false
	end
	return self.class_widget["GUNBREAKER"]["NO_MERCY"]["USE"].bool and self:CanUse("no_mercy")
end

function Gunbreaker:ShouldRoyalGuard()
	return self.class_widget["GUNBREAKER"]["ROYAL_GUARD"].bool and not player:hasStatus(1833)
			and self:CanUse("royal_guard")
end

function Gunbreaker:ShouldBloodfest(ammo)
	return self.class_widget["GUNBREAKER"]["BLOODFEST"]["USE"].bool and self:CanUse("bloodfest")
		and ammo <= self.class_widget["GUNBREAKER"]["BLOODFEST"]["MAX_CARTS"].int
end

function Gunbreaker:GetMaxCarts()
	return player.classLevel == 90 and 3 or player.classLevel > 30 and 2 or 0
end

return Gunbreaker:new()