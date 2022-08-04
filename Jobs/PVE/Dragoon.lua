local Dragoon = Class("Dragoon")

function Dragoon:initialize()

	self.actions = {		

		truetrust     = Action(1, 75),
		lancecharge   = Action(1, 85),
		disembowel    = Action(1, 87),

		litany        = Action(1, 3557),

		dragonsight   = Action(1, 7398),

		chaoticspring = Action(1, 25772),
		
	}
	

	self.menu         = nil
	self.lastAction   = 0
	self.started      = false
		
	Callbacks:Add(CALLBACK_ACTION_REQUESTED, function(actionType, actionId, targetId, result)

		if result == 1 and actionType == 1 then

			self.lastAction = actionId
		end

	end)

end

function Dragoon:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["MELEE_DPS"]:subMenu("Dragoon", "DRG")
end

function Dragoon:Tick(log)

	local menu       = self.menu["ACTIONS"]["MELEE_DPS"]["DRG"]
	local target     = TargetManager.Target	

	if not target.valid or target.kind ~= 2 or target.subKind ~= 5 or target.pos:dist(player.pos) > 3 then return end

	self:Combo(target, menu, log)
end

function Dragoon:Combo(target, menu, log)
	
	if self:Weave(target, menu, log) then return end

	if not self.started then

		if self.actions.truetrust:canUse(target) then
			log:print("Using True Trust on " .. target.name)
			self.actions.truetrust:use(target)
		end
	else
		if self.actions.chaoticspring:canUse(target) then
			log:print("Using Chaotic Spring on " .. target.name)
			self.actions.chaoticspring:use(target)
		end
	end

end

function Dragoon:Weave(target, menu, log)

	if self.lastAction == self.actions.truetrust.id and self.actions.disembowel:canUse(target) then
			log:print("Using Disembowel on " .. target.name)
			self.actions.disembowel:use(target)
	elseif self.lastAction == self.actions.disembowel.id and self.actions.lancecharge:canUse() then
		log:print("Using Lance Charge")
		self.actions.lancecharge:use()
		return true
	elseif self.lastAction == self.actions.lancecharge.id and self.actions.dragonsight:canUse() then
		log:print("Using Dragon Sight")
		self.actions.dragonsight:use()
		return true
	elseif self.lastAction == self.actions.chaoticspring.id and self.actions.litany:canUse() then
		log:print("Using Battle Litany")
		self.actions.litany:use()
		return true
	end

	return false
end

return Dragoon:new()