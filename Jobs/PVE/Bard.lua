local XPVEClass  = LoadModule("XScripts", "\\Jobs\\PVE\\XPVEClass")
local Bard      = Class("Bard", XPVEClass)

function Bard:initialize()

	XPVEClass.initialize(self)

	self.class_range = 25

    self:SetClassIds({5, 23})
    self:LoadWidget("Bard XPVE")

	self:LoadRoleMenu()
	self:LoadWidgetCombo()
	
	self.class_widget["COMBO_SETTINGS"]:checkbox("Use Barrage", "BARRAGE", true)
	self.class_widget["COMBO_SETTINGS"]:separator()
	
	self:LoadWidgetAoE()

	self.actions = {

		heavyshot     = Action(1, 97),
		straightshot  = Action(1, 98),
		venomousbite  = Action(1, 100),
		ragingstrikes = Action(1, 101),
		quicknock     = Action(1, 106),
		barrage       = Action(1, 107),
		bloodletter   = Action(1, 110),
		windbite      = Action(1, 113),
		ballad        = Action(1, 114),
		rain_of_death = Action(1, 117),

		minuet        = Action(1, 3559),

		secondwind    = Action(1, 7541),
		headgrace     = Action(1, 7551),
		footgrace     = Action(1, 7553),
		leggrace      = Action(1, 7554),
		peloton       = Action(1, 7557),

	}
	

end

function Bard:Tick()

	XPVEClass.Tick(self)

	local target = self.get_target()

	if self:ValidTarget(target) then
		if self:Weave(target) then return end

		if self:CanUse("barrage") and self.class_widget["COMBO_SETTINGS"]["BARRAGE"].bool then
			self:Use("barrage")
		elseif self:CanUse("minuet", target) then
			self:Use("minuet", target)
		elseif player:hasStatus(865) and player.gauge.repertoire == 3 and self:CanUse("minuet", target) then
			self.log:print("Using Perfect Pitch on " .. target.name)
			self.actions.minuet:use(target)
		elseif self:CanUse("ragingstrikes") then
			self:Use("ragingstrikes")
		elseif self:CanUse("ballad", target) then
			self:Use("ballad", target)
		elseif not target:hasStatus(124) and self:CanUse("venomousbite", target) then
			self:Use("venomousbite", target)
		elseif self.aoe and self:CanUse("quicknock", target) then
			self:Use("quicknock", target)
		elseif self:CanUse("leggrace", target) then
			self:Use("leggrace", target)
		elseif self:CanUse("footgrace", target) then
			self:Use("footgrace", target)
		elseif self:CanUse("straightshot", target) then
			self:Use("straightshot", target)
		elseif self:CanUse("heavyshot", target) then
			self:Use("heavyshot", target)
		end

	end

end

function Bard:Weave(target)
	if target:hasStatus(124) and not target:hasStatus(129) and self:CanUse("windbite", target) then
		self:Use("windbite", target)
		return true
	elseif self.aoe and not self:LastActionIs("rain_of_death") and self:CanUse("straightshot" , target) and self:CanUse("rain_of_death", target) then
		self:Use("rain_of_death", target)
		return true
	elseif not self:LastActionIs("bloodletter") and self:CanUse("straightshot" , target) and self:CanUse("bloodletter", target) then
		self:Use("bloodletter", target)
		return true
	end
	return false

end

return Bard:new()