local Bard = Class("Bard")

function Bard:initialize()

	self.actions = {
		
		heavyshot     = Action(1, 97),
		straightshot  = Action(1, 98),
		venomousbite  = Action(1, 100),
		ragingstrikes = Action(1, 101),
		quicknock     = Action(1, 106),
		bloodletter   = Action(1, 110),
		ballad        = Action(1, 114),

		minuet        = Action(1, 3559),

		secondwind    = Action(1, 7541),
		headgrace     = Action(1, 7551),
		footgrace     = Action(1, 7553),
		leggrace      = Action(1, 7554),
		peloton       = Action(1, 7557),

	}

	self.menu = nil
	self.lastAction = 0

	Callbacks:Add(CALLBACK_ACTION_REQUESTED, function(actionType, actionId, targetId, result)

		if result == 1 and actionType == 1 then
			self.lastAction = actionId
		end

	end)

end

function Bard:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["RANGE_DPS_M"]:subMenu("Bard", "BRD")
	self.menu["ACTIONS"]["RANGE_DPS_M"]["BRD"]:checkbox("Use AoE Skills on multiple targets", "AOE", true)
end

function Bard:Tick(log)
	local menu   = self.menu["ACTIONS"]["RANGE_DPS_M"]["BRD"]
	local target = TargetManager.Target	
	
	if player.healthPercent < 30 and self.actions.secondwind:canUse() then
		self.actions.secondwind:use()
	end

	if not target.valid or target.kind ~= 2 or target.pos:dist(player.pos) > 25 then return end

	if target.castInfo.isInterruptible and self.actions.headgrace:canUse(target) then
		self.actions.headgrace:use(target)
	end

	local aoe = menu["AOE"].bool and ObjectManager.BattleEnemiesAroundObject(target, 6) > 0 and target.pos:dist(player.pos) < 12

	self:Combo(target, menu, log, aoe)
end

function Bard:Combo(target, menu, log, aoe)
	
	if self:Weave(target, menu, log) then return end

	if self.actions.minuet:canUse(target) then
		log:print("Using The Wanderer's Minuet on " .. target.name)
		self.actions.minuet:use(target)
	elseif player:hasStatus(865) and player.gauge.repertoire == 3 and self.actions.minuet:canUse(target) then
		log:print("Using Perfect Pitch on " .. target.name)
		self.actions.minuet:use(target)
	elseif self.actions.ragingstrikes:canUse() then
		log:print("Using Raging Strikes")
		self.actions.ragingstrikes:use()
	elseif self.actions.ballad:canUse(target) then
		log:print("Using Mage's Ballad on " .. target.name)
		self.actions.ballad:use(target)
	elseif not target:hasStatus(124) and self.actions.venomousbite:canUse(target) then
		log:print("Using Venomous Bite on " .. target.name)
		self.actions.venomousbite:use(target)
	elseif aoe and self.actions.quicknock:canUse(target) then
		log:print("Using Quick Knock on " .. target.name)
		self.actions.quicknock:use(target)
	elseif self.actions.leggrace:canUse(target) then
		log:print("Using Leg Grace on " .. target.name)
		self.actions.leggrace:use(target)
	elseif self.actions.footgrace:canUse(target) then
		log:print("Using Foot Grace on " .. target.name)
		self.actions.footgrace:use(target)
	elseif self.actions.straightshot:canUse(target) then
		log:print("Using Straight Shot on " .. target.name)
		self.actions.straightshot:use(target)
	elseif self.actions.heavyshot:canUse(target) then
		log:print("Using Heavy Shot on " .. target.name)
		self.actions.heavyshot:use(target)
	end

end

function Bard:Weave(target, menu, log)
	
	if self.lastAction ~= self.actions.bloodletter.id and not self.actions.straightshot:canUse(trarget) and self.actions.bloodletter:canUse(target) then
		log:print("Using Bloodletter on " .. target.name)
		self.actions.bloodletter:use(target)
		return true
	end

	return false
end


return Bard:new()