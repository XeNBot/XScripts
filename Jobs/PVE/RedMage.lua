local RedMage = Class("RedMage")

function RedMage:initialize()

	self.actions = {

		verthunder    = Action(1, 7505),
		veraero       = Action(1, 7507),

		swiftcast     = Action(1, 7561),

		verthunderii  = Action(1, 16524),
		veraeroii     = Action(1, 16525),

		verthunderiii = Action(1, 25855),
		veraeroiii    = Action(1, 25856),

	}
	
	self.menu = nil
	self.log  = nil
	self.lastAction       = 0
	self.actionBeforeLast = 0

	Callbacks:Add(CALLBACK_ACTION_REQUESTED, function(actionType, actionId, targetId, result)		
		if result == 1 and actionType == 1 then			
			
			self.actionBeforeLast = self.lastAction
			self.lastAction = actionId

		end

	end)

end

function RedMage:Load(mainMenu, log)
	
	self.menu = mainMenu
	self.log  = log

	self.menu["ACTIONS"]["RANGE_DPS_M"]:subMenu("RedMage", "RDM")

end

function RedMage:Tick()

	local target = TargetManager.Target

	if not target.valid or target.kind ~= 2 or target.subKind ~= 5 or target.yalmX > 25 then return end

	self:Combo(target)

end

function RedMage:Combo(target)
	
	if self:Weave(target) then return end

	if self:CanUseVerthunder(target) then
		self:UseVerthunder(target)
	end

end

function RedMage:Weave(target)

	if self:LastActionIs("verthunder") and self:CanUseVeraero(target) then
		self:UseVeraero(target)
		return true
	elseif self:LastActionIs("veraero") and self.actions.swiftcast:canUse() then
	    self.actions.swiftcast:use()
	    return true
	end

	return false	
end

function RedMage:LastActionIs(name)
	
	if name == "verthunder" then
		return 
			self.lastAction == self.actions.verthunderiii.id or
			self.lastAction == self.actions.verthunderii.id or
			self.lastAction == self.actions.verthunder.id

	elseif name == "veraero" then
		return 
			self.lastAction == self.actions.veraeroiii.id or
			self.lastAction == self.actions.veraeroii.id or
			self.lastAction == self.actions.veraero.id
	end

end

function RedMage:CanUseVerthunder(target)
	return 
		player.classLevel >= 82 and self.actions.verthunderiii:canUse(target) or
		player.classLevel >= 18 and self.actions.verthunderii:canUse(target) or
		self.actions.verthunder:canUse(target)
end

function RedMage:UseVerthunder(target)
	
	if player.classLevel >= 82 and self.actions.verthunderiii:canUse(target) then
		self.log:print("Using Verthunder III on " .. target.name)
		self.actions.verthunderiii:use(target)
	elseif player.classLevel >= 18 and self.actions.verthunderii:canUse(target) then
		self.log:print("Using Verthunder II on " .. target.name)
		self.actions.verthunderii:use(target)
	elseif self.actions.verthunder:canUse(target) then
		self.log:print("Using Verthunder on " .. target.name)
		self.actions.verthunder:use(target)
	end
end

function RedMage:CanUseVeraero(target)
	return 
		player.classLevel >= 82 and self.actions.veraeroiii:canUse(target) or
		player.classLevel >= 22 and self.actions.veraeroii:canUse(target) or
		self.actions.veraero:canUse(target)
end

function RedMage:UseVeraero(target)
	
	if player.classLevel >= 82 and self.actions.veraeroiii:canUse(target) then
		self.log:print("Using Veraero III on " .. target.name)
		self.actions.veraeroiii:use(target)
	elseif player.classLevel >= 22 and self.actions.veraeroii:canUse(target) then
		self.log:print("Using Veraero II on " .. target.name)
		self.actions.veraeroii:use(target)
	elseif self.actions.veraero:canUse(target) then
		self.log:print("Using Veraero on " .. target.name)
		self.actions.veraero:use(target)
	end
end

return RedMage:new()