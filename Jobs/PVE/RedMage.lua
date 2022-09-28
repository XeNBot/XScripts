local RedMage = Class("RedMage")

function RedMage:initialize()

	self.actions = {

		verthunder             = Action(1, 7505),
		corps_a_corps          = Action(1, 7506),
		veraero                = Action(1, 7507),
		verfire                = Action(1, 7510),
		verstone	   		   = Action(1, 7511),

		fleche                 = Action(1, 7517),
		acceleration           = Action(1, 7518),
		contre_sixte           = Action(1, 7519),
		embolden  	           = Action(1, 7520),
		manafication           = Action(1, 7521),
		joltii                 = Action(1, 7524),
		enchanted_riposte      = Action(1, 7527),
		enchanted_zwerchhau    = Action(1, 7528),
		enchanted_redoublement = Action(1, 7529),
		swiftcast              = Action(1, 7561),

		verthunderii           = Action(1, 16524),
		veraeroii              = Action(1, 16525),
		engagement             = Action(1, 16527),
		scorch                 = Action(1, 16530),

		verthunderiii          = Action(1, 25855),
		veraeroiii             = Action(1, 25856),
		resolution             = Action(1, 25858),

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

end

function RedMage:Weave(target)

	if self:CanUseVerthunder(target) and self.lastAction == 0 then
		self:UseVerthunder(target)
	
	elseif self:ActionIs(self.lastAction, "verthunder") then
		if self:ActionIs(self.actionBeforeLast, "verthunder") and self.actions.embolden:canUse() then
			self.actions.embolden:use()
			self.log:print("Using embolden ")
			return true
		elseif self:ActionIs(self.actionBeforeLast, "verthunder") and self.actions.enchanted_riposte:canUse(target) then
			self.actions.enchanted_riposte:use(target)
			self.log:print("Using enchanted riposte ")
			return true
		elseif self.actionBeforeLast == self.actions.acceleration.id and self:CanUseVerthunder(target) then
			self:UseVerthunder(target)
			return true
		elseif self:CanUseVeraero(target) and not self:ActionIs(self.actionBeforeLast, "verthunder") then
			self:UseVeraero(target)
			return true
		end

	elseif self:ActionIs(self.lastAction, "enchanted_riposte") and self.actions.fleche:canUse(target) then
			self.actions.fleche:use(target)
			self.log:print("Using fleche ")
			return true

	elseif self:ActionIs(self.lastAction,"veraero") and self.actions.swiftcast:canUse() then
	    self.log:print("Using swifcast")
		self.actions.swiftcast:use()
	    return true

	elseif self:ActionIs(self.lastAction,"swiftcast") and self.actions.acceleration:canUse() then
		self.log:print("Using acceleration")
		self.actions.acceleration:use()
		return true

	elseif self:ActionIs(self.lastAction,"acceleration") and self:CanUseVerthunder(target) then
		self:UseVerthunder(target)
		return true 
	
	elseif self:ActionIs(self.astAction,"embolden") and self.actions.manafication:canUse() then
		self.actions.manafication:use()
		return true

	elseif self:ActionIs(self.lastAction, "manafication") and self.actions.enchanted_riposte:canUse(target) then
		self.actions.enchanted_riposte:use(target)
		return true

	elseif self:ActionIs(self.lastAction, "fleche") and self.actions.enchanted_zwerchhau:canUse(target) then
		self.actions.enchanted_zwerchhau:use(target)
		return true

	
	end

	return false	
end

function RedMage:ActionIs(action, name)

    if name == "verthunder" then
        return 
            action == self.actions.verthunderiii.id or
            action == self.actions.verthunderii.id or
            action == self.actions.verthunder.id

    elseif name == "veraero" then
        return 
            action == self.actions.veraeroiii.id or
            action == self.actions.veraeroii.id or
            action == self.actions.veraero.id

    elseif name == "swiftcast" then
            return
            action == self.actions.swiftcast.id

    elseif name == "acceleration" then
        return
            action == self.actions.acceleration.id

    elseif name == "embolden" then
        return
            action == self.actions.embolden.id

    elseif name == "manafication" then
        return
            action == self.actions.manafication.id

	elseif name == "enchanted_riposte" then
            return
            action == self.actions.enchanted_riposte.id

	elseif name == "fleche" then
            return
            action == self.actions.fleche.id
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