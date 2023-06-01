local XPVPClass   = LoadModule("XScripts", "\\Jobs\\PVP\\XPVPClass")
local Reaper  = Class("Reaper", XPVPClass)

function Reaper:initialize()

	XPVPClass.initialize(self)

	self:SetClassId(39)
	self:LoadMenu("Reaper XPVP")
	self:Menu()

	self.actions = {

		-- Infernal Slice Combo
		slice             = Action(1, 29538),
		waxing_slice      = Action(1, 29539),
		infernal_slice    = Action(1, 29540),
		gibbet            = Action(1, 29541),
		gallows           = Action(1, 29542),
		void_reaping      = Action(1, 29543),
		cross_reaping     = Action(1, 29544),

		soul_slice        = Action(1, 29566),
		plentiful_harvest = Action(1, 29546),
		grim_swathe       = Action(1, 29547),
		death_warrant     = Action(1, 29549),
		hells_ingress     = Action(1, 29550),
		arcane            = Action(1, 29552),
		tenebrae_lemurum  = Action(1, 29553),
	}

end

function Reaper:Menu()
	self.class_menu:subMenu("Infernal Slice Combo", "INFERNAL_SLICE")
		self.class_menu["INFERNAL_SLICE"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Infernal_Slice.png")
		self.class_menu["INFERNAL_SLICE"]:checkbox("Use", "USE", true)

	self.class_menu:subMenu("Soul Slice", "SOUL_SLICE")
		self.class_menu["SOUL_SLICE"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Soul_Slice.png")
		self.class_menu["SOUL_SLICE"]:checkbox("Use", "USE", true)

	self.class_menu:subMenu("Plentiful Harvest", "PLENTIFUL_HARVEST")
		self.class_menu["PLENTIFUL_HARVEST"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Plentiful_Harvest.png")
		self.class_menu["PLENTIFUL_HARVEST"]:checkbox("Use", "USE", true)
		self.class_menu["PLENTIFUL_HARVEST"]:slider("Min Soul Sacrifice Stacks", "MIN_STACKS", 1, 1, 6, 6)

	self.class_menu:subMenu("Grim Swathe", "GRIM_SWATHE")
		self.class_menu["GRIM_SWATHE"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Grim_Swathe.png")
		self.class_menu["GRIM_SWATHE"]:checkbox("Use", "USE", true)

	self.class_menu:subMenu("Death Warrant", "DEATH_WARRANT")
		self.class_menu["DEATH_WARRANT"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Death_Warrant.png")
		self.class_menu["DEATH_WARRANT"]:checkbox("Use", "USE", true)

	self.class_menu:subMenu("Hell's Ingress", "HELLS_INGRESS")
		self.class_menu["HELLS_INGRESS"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Hells_Ingress.png")
		self.class_menu["HELLS_INGRESS"]:checkbox("Use", "USE", true)

	self.class_menu:subMenu("Arcane Crest", "ARCANE_CREST")
		self.class_menu["ARCANE_CREST"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Arcane_Crest.png")
		self.class_menu["ARCANE_CREST"]:checkbox("Use", "USE", true)

	self.class_menu:subMenu("Tenebrae Lemurum", "TENEBRAE_LEMURUM")
		self.class_menu["TENEBRAE_LEMURUM"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Tenebrae_Lemurum.png")
		self.class_menu["TENEBRAE_LEMURUM"]:checkbox("Use", "USE", true)

end

function Reaper:Enshrouded(target, status)
	-- Communio
	if (status.remainingTime <= 2 or status.count == 1) and self:CanUse("tenebrae_lemurum", target) then
		self:Use("tenebrae_lemurum", target)
	-- Lemure's Slice
	elseif self:CanUse("grim_swathe", target) then
		self:Use("grim_swathe", target)
	-- Void Reaping
	elseif self:CanUse("void_reaping", target) then
		self:Use("void_reaping")
	-- Cross Reaping
	elseif self:CanUse("cross_reaping") then
		self:Use("cross_reaping")
	elseif self:CanUse("death_warrant", target) then
		self:Use("death_warrant", target)
	end
end

function Reaper:Tick()
	
	if self.class_menu["HELLS_INGRESS"]["USE"].bool then
		local far_target = self:GetTarget(14)

		if far_target ~= nil and far_target.valid and far_target.pos:dist(player.pos) > 9 and self:CanUse("hells_ingress") and not player:hasStatus(2860) then
			self:Use("hells_ingress", far_target) return
		end
	end

	local target = self:GetTarget(5)

	if target ~= nil and target.valid then
		local enshrouded     = player:getStatus(2863)
		local soul_sacrifice = player:getStatus(3204)

		if enshrouded.valid then 
			self:Enshrouded(target, enshrouded)
		elseif self.class_menu["TENEBRAE_LEMURUM"]["USE"].bool and self:CanUse("tenebrae_lemurum") then
			self:Use("tenebrae_lemurum")
		elseif self.class_menu["DEATH_WARRANT"]["USE"].bool and self:CanUse("death_warrant", target) then
			self:Use("death_warrant", target)
		elseif self.class_menu["PLENTIFUL_HARVEST"]["USE"].bool and self:CanUse("plentiful_harvest", target)
			and soul_sacrifice.valid and soul_sacrifice.count >= self.class_menu["PLENTIFUL_HARVEST"]["MIN_STACKS"].int then
			self:Use("plentiful_harvest", target)
		elseif self.class_menu["SOUL_SLICE"]["USE"].bool and self:CanUse("soul_slice", target) and (not soul_sacrifice.valid or (soul_sacrifice.count < 8)) then
			self:Use("soul_slice", target)
		elseif self.class_menu["GRIM_SWATHE"]["USE"].bool and self:CanUse("grim_swathe") then
			self:Use("grim_swathe", target)
		elseif self.class_menu["INFERNAL_SLICE"]["USE"].bool and self:CanUse("gibbet", target) then
			self:Use("gibbet", target)
		elseif self.class_menu["INFERNAL_SLICE"]["USE"].bool and self:CanUse("gallows", target) then
			self:Use("gallows", target)
		elseif self.class_menu["INFERNAL_SLICE"]["USE"].bool and self:CanUse("infernal_slice", target) then
			self:Use("infernal_slice", target)
		elseif self.class_menu["INFERNAL_SLICE"]["USE"].bool and self:CanUse("waxing_slice", target) then
			self:Use("waxing_slice", target)
		elseif self.class_menu["INFERNAL_SLICE"]["USE"].bool and self:CanUse("slice", target) then
			self:Use("slice", target)
		end
	end
	
end

return Reaper:new()