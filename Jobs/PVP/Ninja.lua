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

function Ninja:Execute(log)

	local list = AgentModule.currentMapId == 51 and ObjectManager.Battle() or ObjectManager.GetEnemyPlayers()

	for i, object in ipairs(list) do
		if object.pos:dist(player.pos) < 20 and object.healthPercent < 50 and not object:hasStatus(3054) and self.actions.seiton:canUse(object) then
			log:print("Using Seiton on " .. object.name)
		 	self.actions.seiton:use(object)		 	
		 end
	end
end


function Ninja:Tick(getTarget, log)

	local menu    = self.menu["ACTIONS"]["MELEE_DPS"]["NIN"]
	local actions = self.actions

	self:Execute(log)

	local farTarget = getTarget(20)


	if farTarget.valid and farTarget.pos:dist(player.pos) > 6 then
		if player:hasStatus(1317) then
			self:ThreeMudra(farTarget, log)
		elseif menu["FUMA"] and actions.fuma:canUse(farTarget) then
			actions.fuma:use(farTarget)
			return
		elseif menu["SHUKUCHI"].bool and actions.shukuchi:canUse() then
			actions.shukuchi:use(farTarget.pos)
			log:print("Using Shukuchi on " .. farTarget.name)
		end
	end

	local target = getTarget(5)

	if target.valid then
		if player:hasStatus(1317) then
			self:ThreeMudra(target, log)
		elseif menu["BUNSHIN"].bool and actions.bunshin:canUse(target) then
			actions.bunshin:use(target)
			log:print("Using Bunshin on " .. target.name)
		elseif menu["FUMA"].bool and not self.lastShuriken and actions.fuma:canUse(target) then
			actions.fuma:use(target)
			log:print("Using Fuma on " .. target.name)
		elseif menu["MUG"].bool and actions.mug:canUse(target) then
			actions.mug:use(target)
			log:print("Using Mug on " .. target.name)
		elseif menu["MUDRA"].bool and actions.mudra:canUse() then
			actions.mudra:use()
			log:print("Using Mudra")
		elseif menu["AEOLIAN"].bool and actions.aeolian:canUse(target) then
			actions.aeolian:use(target)
			log:print("Using Aeolian Slah on " .. target.name)
		elseif menu["AEOLIAN"].bool and actions.gust:canUse(target) then
			log:print("Using Gust on " .. target.name)
			actions.gust:use(target)
		elseif menu["AEOLIAN"].bool and actions.spinning:canUse(target) then
			actions.spinning:use(target)
			log:print("Using Spinning on " .. target.name)
		end

	end

end

function Ninja:ThreeMudra(target, log)
	
	if player.missingHealth > 14000 and self.actions.mudra:canUse() then
		self.actions.mudra:use()
	elseif ObjectManager.EnemiesAroundObject(target, 5) > 0 and self.actions.mug:canUse(target) then
		self.actions.mug:use(target)
	elseif target.pos:dist(player.pos) > 5 then	
		if self.actions.fuma:canUse(target) then
			self.actions.fuma:use(target)
		end
	elseif target.pos:dist(player.pos) < 5 then
		if self.actions.shukuchi:canUse() then
			log:print("Using Shukuchi")
			self.actions.shukuchi:use()
		elseif self.actions.bunshin:canUse() then
			log:print("Using Bushing")
			self.actions.bunshin:use()
		elseif self.actions.fuma:canUse(target) then
			self.actions.fuma:use(target)
			log:print("Using Fuma on " .. target.name)
		end
	end

end

return Ninja:new()