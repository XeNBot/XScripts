local XPVPClass   = LoadModule("XScripts", "\\Jobs\\PVP\\XPVPClass")
local Bard  = Class("Bard", XPVPClass)

function Bard:initialize()

	XPVPClass.initialize(self)

	self:SetClassId(23)
	self:LoadMenu("Bard XPVP")
	self:Menu()

	self.actions = {

		powerful_shot    = Action(1, 29391),
		apex_arrow       = Action(1, 29393),
		blast_arrow      = Action(1, 29394),
		silent_nocturne  = Action(1, 29395),
		empyreal_arrow   = Action(1, 29398),
		repelling_shot   = Action(1, 29399),
		final_fantasia   = Action(1, 29401)
	}

end

function Bard:Menu()
	self.class_menu:subMenu("Powerful Shot", "POWERFUL_SHOT")
		self.class_menu["POWERFUL_SHOT"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Powerful_Shot.png")
		self.class_menu["POWERFUL_SHOT"]:checkbox("Use",     "USE", true)
	self.class_menu:subMenu("Apex Arrow", "APEX_ARROW")
		self.class_menu["APEX_ARROW"]:setIcon("XScriptsT", "\\Resources\\Icons\\Actions\\PvP\\Apex_Arrow.png")
		self.class_menu["APEX_ARROW"]:checkbox("Use",        "USE", true)
	self.class_menu:subMenu("Silent Nocturne", "SILENT_NOCTURNE")
		self.class_menu["SILENT_NOCTURNE"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Silent_Nocturne.png")
		self.class_menu["SILENT_NOCTURNE"]:checkbox("Use",   "USE", true)
	self.class_menu:subMenu("Empyreal Arrow", "EMPYREAL_ARROW")
		self.class_menu["EMPYREAL_ARROW"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Empyreal_Arrow.png")
		self.class_menu["EMPYREAL_ARROW"]:checkbox("Use",    "USE",   true)
		self.class_menu["EMPYREAL_ARROW"]:slider("Minimum Stacks", "MIN_STACKS", 1, 1, 3, 2)
	self.class_menu:subMenu("Repelling Shot", "REPELLING_SHOT")
		self.class_menu["REPELLING_SHOT"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Repelling_Shot.png")
		self.class_menu["REPELLING_SHOT"]:checkbox("Use",     "USE", true)
		self.class_menu["REPELLING_SHOT"]:number("Min Range", "MIN_RANGE",  6)
	self.class_menu:subMenu("Final Fantasia", "FINAL_FANTASIA")
		self.class_menu["FINAL_FANTASIA"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\PvP\\Final_Fantasia.png")
		self.class_menu["FINAL_FANTASIA"]:checkbox("Use",     "USE", true)
		self.class_menu["FINAL_FANTASIA"]:slider("Min Allies", "MIN_ALLIES", 1, 1, 3, 2)

end



function Bard:Tick()

	local target = self:GetTarget(25)

	if target.valid and not target.ally then
 
		if self.class_menu["FINAL_FANTASIA"]["USE"] and self:CanUse("final_fantasia") then
			local allies = ObjectManager.Players(
				function (obj) return not obj.dead and obj.ally and obj.pos:dist(player.pos) < 30 
			end)

			if #allies >= self.class_menu["FINAL_FANTASIA"]["MIN_ALLIES"].int then
				self:Use("final_fantasia")
				return
			end
		end
		if self:Weave(target) then return end

		if self.class_menu["REPELLING_SHOT"]["USE"].bool and self:CanUse("repelling_shot", target)
			and target.pos:dist(player.pos) <= self.class_menu["REPELLING_SHOT"]["MIN_RANGE"].int then
			self:Use("repelling_shot", target)
		end

		if self:CanUse("blast_arrow", target) then
			self:Use("blast_arrow", target)
		elseif self.class_menu["EMPYREAL_ARROW"]["USE"].bool and self:CanUse("empyreal_arrow", target) then
			self:Use("empyreal_arrow", target)
		elseif self.class_menu["SILENT_NOCTURNE"]["USE"].bool and self:CanUse("silent_nocturne", target) then
			self:Use("silent_nocturne", target)
		elseif self.class_menu["EMPYREAL_ARROW"]["USE"].bool and self:CanUse("apex_arrow", target) then
			self:Use("apex_arrow", target)
		elseif self.class_menu["POWERFUL_SHOT"]["USE"].bool and self:CanUse("powerful_shot", target) then
			self:Use("powerful_shot", target)
		end

	end
end

function Bard:Weave(target)

	if self.last_action ~= self.actions.silent_nocturne.id and self:CanUse("powerful_shot", target) then
		self:Use("powerful_shot", target)
		return true
	elseif self.last_action ~= self.actions.apex_arrow.id and self:CanUse("apex_arrow", target)	 then
		self:Use("apex_arrow", target)
		return true
	end

	return false
end

return Bard:new()