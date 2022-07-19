local BlackMage = Class("BlackMage")

function BlackMage:initialize()

	self.actions = {

		fire         = Action(1, 29649),
		blizzard     = Action(1, 29653),
		burst        = Action(1, 29657),
		nightwing    = Action(1, 29659),
		manipulation = Action(1, 29660),
		superflare   = Action(1, 29661),
		soul         = Action(1, 29662),
		paradox      = Action(1, 29663),

	}

	self.lastAction = 0

	Callbacks:Add(CALLBACK_ACTION_REQUESTED, function(actionType, actionId, targetId, result)
		if actionType == 1 and result == 1 then
			self.lastAction = actionId
		end
	end)

	self.menu = nil
end

function BlackMage:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["RANGE_DPS_M"]:subMenu("BlackMage", "BLM")		
		self.menu["ACTIONS"]["RANGE_DPS_M"]["BLM"]:combobox("Combo Priority", "COMBO_MODE", {"Ice", "Fire"}, 0)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["BLM"]:checkbox("Use Paradox",               "PARADOX", true)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["BLM"]:checkbox("Use Burst",                 "BURST", true)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["BLM"]:slider("Min Enemies for Burst",       "BURSTMIN", 1, 1, 5, 2)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["BLM"]:checkbox("Use Night Wing",            "WING", true)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["BLM"]:slider("Min Enemies for Night Wing",  "WINGMIN", 1, 1, 5, 2)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["BLM"]:checkbox("Use Atherial Manipulation", "MANIPULATION", true)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["BLM"]:checkbox("Use Superflare",            "FLARE", true)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["BLM"]:slider("Min Warmth Stacks",           "MINWARMTH", 1, 1, 3, 3)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["BLM"]:slider("Min Freeze Stacks",           "MINFREEZE", 1, 1, 3, 3)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["BLM"]:checkbox("Use Soul Resonance",        "SOUL", true)	

end

function BlackMage:Tick(getTarget, log)

	local menu    = self.menu["ACTIONS"]["RANGE_DPS_M"]["BLM"]
	
	local target = getTarget(25)

	if target.valid then

		local warmth = target:getStatus(3216)
		local freeze = target:getStatus(3217)
		local swift  = player:hasStatus(1325)

		if menu["SOUL"].bool and (self.actions.soul:canUse(target) or self.actions.soul:canUse()) then
			self.actions.soul:use(target)
		end

		if menu["PARADOX"].bool and self.actions.paradox:canUse(target) and (warmth.count == 1  or freeze.count == 1) and not swift then
			self.actions.paradox:use(target)
			log:print("Using Paradox on " .. target.name)
		end

		if menu["WING"].bool and ObjectManager.EnemiesAroundObject(target, 5) >= menu["WINGMIN"].int and self.actions.nightwing:canUse(target) and not swift then
			self.actions.nightwing:use(target)
			log:print("Using Nightwing on " .. target.name)
		end

		if menu["MANIPULATION"] and self.actions.manipulation:canUse() and not swift and freeze.count ~= 1 and warmth.count ~= 1 and self.lastAction ~= 29660 then
			self.actions.manipulation:use()
			log:print("Using Manipulation")
		end

		if menu["BURST"].bool and self.actions.burst:canUse() and ObjectManager.EnemiesAroundObject(player, 5) >= menu["BURSTMIN"].int then
			self.actions.burst:use()
		end

		if menu["FLARE"].bool and self.actions.superflare:canUse() then
			if warmth.count >= menu["MINWARMTH"].int or freeze.count >= menu["MINFREEZE"].int then
				self.actions.superflare:use()
				log:print("Using Superflare on " .. target.name)
			end
		end

		if menu["COMBO_MODE"].int == 0 then
			if self.actions.blizzard:canUse(target) then
				self.actions.blizzard:use(target)
				log:print("Using Blizzard on " .. target.name)
			end

		else
			if self.actions.fire:canUse(target) then
				self.actions.fire:use(target)
				log:print("Using Fire on " .. target.name)
			end
		end

	end	
end

return BlackMage:new()