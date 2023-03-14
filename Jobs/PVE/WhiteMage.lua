local XPVEClass  = LoadModule("XScripts", "\\Jobs\\PVE\\XPVEClass")
local WhiteMage  = Class("WhiteMage", XPVEClass)

function WhiteMage:initialize()

	XPVEClass.initialize(self)

	self.class_range          = 25
	self.healing_manager      = LoadModule("XScripts", "/Utilities/HealingManager")

    self.class_widget         = Menu("White Mage XPVE" , true)
	self.class_widget.width   = 300
	self.class_widget.visible = player.classJob == 6 or player.classJob == 24
	

	self.actions = {
	}

	self.healing_actions = {

		cure     = Action(1, 120),
		cureii   = Action(1, 135),

		--medica   = Action(1, 124),
		--medicaii = Action(1, 124),

	}
	
	self.healing_bonus = function ()
		return player.classLevel >= 40 and 30 or
		player.classLevel >= 20 and 10 or 0
	end
	
	self.healing_actions.cure.potency     = 450
	self.healing_actions.cure.bonus       = self.healing_bonus
	self.healing_actions.cure.condition   = function () return not player:hasStatus(155) end

	self.healing_actions.cureii.potency   = 700
	self.healing_actions.cureii.bonus     = self.healing_bonus
	self.healing_actions.cureii.condition = function () return player:hasStatus(155) end

	self.healing_manager:Load(self.class_widget)

	self.healing_manager:AddActionTable(self.healing_actions)
end

function WhiteMage:Tick()

	XPVEClass.Tick(self)

	if self.healing_manager:HealWatch() then return end

	local target = self.get_target()
	
end

return WhiteMage:new()