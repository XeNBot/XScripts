local Ninja = Class("Ninja")

function Ninja:initialize()

	self.actions = {

		-- Aeolian Edge Combo
		spinning  = Action(1, 29500),
		gust      = Action(1, 29501),
		aeolian   = Action(1, 29502),


		fuma      = Action(1, 29505),
		mug       = Action(1, 29509),
		mudra     = Action(1, 29507),
		bunshin   = Action(1, 29511),
		shukuchi  = Action(1, 29513),
		seiton    = Action(1, 29515),
	}

	self.menu = nil
	self.lastShuriken = false

	-- Tracks whenever we use shuriken for weaving
	Callbacks:Add(CALLBACK_ACTION_REQUESTED, function(actionType, actionId, targetId, result)
		if actionType == 1 and result == 1 then
			self.lastShuriken = (actionId == 29505 and true) or false
		end
	end)

end

function Ninja:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["MELEE_DPS"]:subMenu("Ninja", "NIN")
		self.menu["ACTIONS"]["MELEE_DPS"]["NIN"]:checkbox("Use Aeolian Edge Combo",    "AEOLIAN", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["NIN"]:checkbox("Use Fuma Shuriken",         "FUMA", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["NIN"]:checkbox("Use Mug",                   "MUG", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["NIN"]:checkbox("Use Three Mudra",           "MUDRA", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["NIN"]:checkbox("Use Bunshin",               "BUNSHIN", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["NIN"]:checkbox("Use Shukuchi",              "SHUKUCHI", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["NIN"]:checkbox("Use Seiton",                "SEITON", true)
end

function Ninja:Execute()
	for i, object in ipairs(ObjectManager.GetEnemyPlayers()) do
		if object.pos:dist(player.pos) < 19.5 and (object.health <= (object.maxHealth / 2)) and
		 object.health > 0 and not object:hasStatus(3054) and self.actions.seiton:canUse(object.id) then
		 	self.actions.seiton:use(object.id)
		 	return true
		end
	end
	return false
end


function Ninja:Tick(getTarget)

	local menu    = self.menu["ACTIONS"]["MELEE_DPS"]["NIN"]
	local actions = self.actions

	if self:Execute() then return end

	local farTarget = getTarget(20)

	if farTarget.valid and farTarget.pos:dist(player.pos) > 6 then
		if player:hasStatus(1317) then
			self:ThreeMudra(farTarget)
		elseif menu["FUMA"] and actions.fuma:canUse(farTarget.id) then
			actions.fuma:use(farTarget.id)
			return
		elseif menu["SHUKUCHI"].bool and actions.shukuchi:canUse() then
			actions.shukuchi:use(farTarget.pos)
			return
		end
	end

	local target = getTarget(5)

	if target.valid then
		if player:hasStatus(1317) then
			self:ThreeMudra(target)
		elseif menu["BUNSHIN"].bool and actions.bunshin:canUse(target.id) then
			actions.bunshin:use(target.id)
		elseif menu["FUMA"].bool and not self.lastShuriken and actions.fuma:canUse(farTarget.id) then
			actions.fuma:use(target.id)
		elseif menu["MUG"].bool and actions.mug:canUse(target.id) then
			actions.mug:use(target.id)
		elseif menu["MUDRA"].bool and actions.mudra:canUse() then
			actions.mudra:use()
		elseif menu["AEOLIAN"].bool and actions.aeolian:canUse(target.id) then
			actions.aeolian:use(target.id)
		elseif menu["AEOLIAN"].bool and actions.gust:canUse(target.id) then
			actions.gust:use(target.id)
		elseif menu["AEOLIAN"].bool and actions.spinning:canUse(target.id) then
			actions.spinning:use(target.id)
		end

	end

end

function Ninja:ThreeMudra(target)
	
	if (player.maxHealth - player.health) > 14000 and self.actions.mudra:canUse() then
		self.actions.mudra:use()
	elseif ObjectManager.EnemiesAroundObject(target, 5) > 0 and self.actions.mug:canUse(target.id) then
		self.actions.mug:use(target.id)
	elseif target.pos:dist(player.pos) > 5 then	
		if self.actions.fuma:canUse(target.id) then
			self.actions.fuma:use(target.id)
		end
	elseif target.pos:dist(player.pos) < 5 then
		if self.actions.shukuchi:canUse() then
			self.actions.shukuchi:use()
		elseif self.actions.bunshin:canUse() then
			self.actions.bunshin:use()
		elseif self.actions.fuma:canUse(target.id) then
			self.actions.fuma:use(target.id)
		end
	end

end

return Ninja:new()