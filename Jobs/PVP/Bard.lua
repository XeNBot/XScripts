local Bard = Class("Bard")

function Bard:initialize()

	self.actions = {

		powershot  = Action(1, 29391),
		apexarrow  = Action(1, 29393),
		blastarrow = Action(1, 29394),
		nocturne   = Action(1, 29395),
		empyreal   = Action(1, 29398),
		repelshot  = Action(1, 29399),
	}

	self.menu       = nil
	self.lastAction = 0

	Callbacks:Add(CALLBACK_ACTION_REQUESTED, function(actionType, actionId, targetId, result)

		if result == 1 and actionType == 1 then
			self.lastAction = actionId
		end

	end)

end

function Bard:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["RANGE_DPS_P"]:subMenu("Bard", "BRD")
		self.menu["ACTIONS"]["RANGE_DPS_P"]["BRD"]:checkbox("Use Powerful Shot",       "POWER_SHOT", true)
		self.menu["ACTIONS"]["RANGE_DPS_P"]["BRD"]:checkbox("Use Apex Arrow",          "APEX_ARROW", true)
		self.menu["ACTIONS"]["RANGE_DPS_P"]["BRD"]:checkbox("Use Silent Nocturne",     "NOCTURNE", true)
		self.menu["ACTIONS"]["RANGE_DPS_P"]["BRD"]:checkbox("Use Empyreal Arrow",      "EMPYREAL", true)
		self.menu["ACTIONS"]["RANGE_DPS_P"]["BRD"]:slider("Minimum Empyreal Stacks",   "EMPYREAL_MIN", 1, 1, 3, 2)
		self.menu["ACTIONS"]["RANGE_DPS_P"]["BRD"]:checkbox("Use Repelling Shot",      "REPEL_SHOT", true)
		self.menu["ACTIONS"]["RANGE_DPS_P"]["BRD"]:number("Min Range for Repelling",   "REPEL_MIN", 6)
end



function Bard:Tick(getTarget, log)

	local menu        = self.menu["ACTIONS"]["RANGE_DPS_P"]["BRD"]
	local target      = getTarget(25)

	if target.valid then
		if self:Weave(target, log) then 
			return
		elseif self.actions.blastarrow:canUse(target) then 
			log:print("Using Blast Arrow on " .. target.name)
			self.actions.blastarrow:use(target)
		elseif menu["EMPYREAL"].bool and self.actions.empyreal:canUse(target) then
			log:print("Using Empyreal Arrow on " .. target.name)
			self.actions.empyreal:use(target)
		elseif menu["REPEL_SHOT"].bool and self.actions.repelshot:canUse(target) and target.pos:dist(player.pos) <= menu["REPEL_MIN"].int then
			log:print("Using Repel Shot on " .. target.name)
			self.actions.repelshot:use(target)
		elseif menu["NOCTURNE"].bool and self.actions.nocturne:canUse(target) then
			log:print("Using Silent Nocturne on " .. target.name)
			self.actions.nocturne:use(target)
		elseif menu["APEX_ARROW"].bool and self.actions.apexarrow:canUse(target) then
			log:print("Using Apex Arrow on " .. target.name)
			self.actions.apexarrow:use(target)
		elseif menu["POWER_SHOT"].bool and self.actions.powershot:canUse(target) then
			log:print("Using Power Shot on " .. target.name)
			self.actions.powershot:use(target)
		end
	end

end

function Bard:Weave(target, log)

	if self.lastAction ~= self.actions.nocturne.id and self.actions.powershot:canUse(target) then
		log:print("Using Pitch Perfect on " .. target.name)
		self.actions.powershot:use(target)
		return true
	elseif self.lastAction ~= self.actions.apexarrow.id and self.actions.apexarrow:canUse(target) then
		log:print("Using Blast Arrow on " .. target.name)
		self.actions.apexarrow:use(target)
		return true
	end

	return false
end

return Bard:new()