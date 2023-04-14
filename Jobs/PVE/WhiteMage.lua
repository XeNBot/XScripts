local XPVEClass  = LoadModule("XScripts", "\\Jobs\\PVE\\XPVEClass")
local WhiteMage  = Class("WhiteMage", XPVEClass)

function WhiteMage:initialize()

	XPVEClass.initialize(self)

	self:SetClassIds({6, 24})
	self:LoadWidget("White Mage XPVE")
	self:LoadWidgetCombo()

	self.class_range          = 25
	self.healing_manager      = LoadModule("XScripts", "/Utilities/HealingManager")
    
	self.class_widget["COMBO_SETTINGS"]:checkbox("Use Precense of Mind", "PRECENCE", true)
	
	self.actions = {

		stone    = Action(1, 119),
		stoneii  = Action(1, 127),
		stoneiii = Action(1, 3568),
		stoneiv  = Action(1, 7431),

		aero     = Action(1, 121),
		aeroii   = Action(1, 132),

		holy     = Action(1, 139),
		holyiii  = Action(1, 25860),

		presence = Action(1, 136),

		raise = Action(1, 125),
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
	self.healing_manager:AddReviveAction(self.actions.raise)
end

function WhiteMage:Tick()

	XPVEClass.Tick(self)

	if self.healing_manager:Tick() then return end

	local target = self.get_target()

	if not target.valid or target.kind ~= 2 or target.subKind ~= 5 or target.yalmX > 25 or target.ally then return end

	local aoe = ObjectManager.BattleEnemiesAroundObject(target, 8) > 1

	if self.class_widget["COMBO_SETTINGS"]["PRECENCE"].bool and self.actions.presence:canUse() then
		ActionManager.UseAction(1, 136, 3758096384)
	end

	if player.classLevel >= 72 then
		self:HighCombo(target, aoe)
	else
		self:LowCombo(target, aoe)
	end
	
end

function WhiteMage:LowCombo(target, aoe)

	if not self:HasAero(target) and self:CanUseAero(target) then
		self:UseAero(target)
	end

	if aoe and self:CanUseHoly(target) then
		self:UseHoly(target)
	elseif self:CanUseStone(target) then
		self:UseStone(target)
	end
end


function WhiteMage:HighCombo(target, aoe)

	if self:Weave(target) then return end
end

function WhiteMage:Weave(target)

	return false

end


function WhiteMage:CanUseHoly(target)
	return
		player.classLevel >= 82 and self.actions.holyiii.recastTime == 0 or
		player.classLevel >= 45 and self.actions.holy.recastTime == 0
end

function WhiteMage:UseHoly(target)

	if player.classLevel >= 82 and self.actions.holyiii.recastTime == 0 then
		self.log:print("Using Holy III on " .. target.name)
		self.actions.holyiii:use(target)
	elseif self.actions.holy.recastTime == 0 then
		self.log:print("Using Holy on " .. target.name)
		self.actions.holy:use(target)
	end

end

function WhiteMage:CanUseStone(target)
	return
		player.classLevel >= 64 and self.actions.stoneiv:canUse(target) or
		player.classLevel >= 54 and self.actions.stoneiii:canUse(target) or
		player.classLevel >= 18 and self.actions.stoneii:canUse(target) or
		self.actions.stone:canUse(target)
end

function WhiteMage:UseStone(target)

	if player.classLevel >= 64 and self.actions.stoneiv:canUse(target) then
		self.log:print("Using Stone IV on " .. target.name)
		self.actions.stoneiv:use(target)
	elseif player.classLevel >= 54 and self.actions.stoneiii:canUse(target) then
		self.log:print("Using Stone III on " .. target.name)
		self.actions.stoneiii:use(target)
	elseif player.classLevel >= 18 and self.actions.stoneii:canUse(target) then
		self.log:print("Using Stone II on " .. target.name)
		self.actions.stoneii:use(target)
	elseif self.actions.stone:canUse(target) then
		self.log:print("Using Stone on " .. target.name)
		self.actions.stone:use(target)
	end

end

function WhiteMage:HasAero(target)
	return target:hasStatus(143) or target:hasStatus(144)
end

function WhiteMage:CanUseAero(target)
	return
		player.classLevel >= 46 and self.actions.aeroii:canUse(target) or
		self.actions.aero:canUse(target)
end

function WhiteMage:UseAero(target)

	if player.classLevel >= 46 and self.actions.aeroii:canUse(target) then
		self.log:print("Using Aero II on " .. target.name)
		self.actions.aeroii:use(target)
	elseif self.actions.aero:canUse(target) then
		self.log:print("Using Aero on " .. target.name)
		self.actions.aero:use(target)
	end

end

return WhiteMage:new()