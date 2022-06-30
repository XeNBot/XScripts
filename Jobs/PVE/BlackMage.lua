local BlackMage = Class("BlackMage")

function BlackMage:initialize()

	self.actions = {
		
		blizzard    = Action(1, 142),
		blizzardii  = Action(1, 25793),
		blizzardiii = Action(1, 154),		
		blizzardiv  = Action(1, 3576),

		fire        = Action(1, 141),
		fireii      = Action(1, 147),
		fireiii     = Action(1, 152),
		fireiv      = Action(1, 3577),

		thunder     = Action(1, 144),
		thunderii   = Action(1, 7447),

		transpose   = Action(1, 149),
		manaward    = Action(1, 157),
		manafront   = Action(1, 158),
	}

	self.menu = nil
	self.lastAction = 0

	Callbacks:Add(CALLBACK_ACTION_REQUESTED, function(actionType, actionId, targetId, result)

		if result == 1 and actionType == 1 then
			self.lastAction = actionId
		end

	end)

end

function BlackMage:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["RANGE_DPS_M"]:subMenu("BlackMage", "BLM")
end

function BlackMage:Tick(log)

	--[[print("Umbral Stacks", player.gauge.umbralStacks)
	print("Umbral Hearts", player.gauge.umbralHearts)
	print("Astral Stacks", player.gauge.astralStacks)
	print("Element Timer", player.gauge.elementTimer)
	print("Enochian Timer", player.gauge.enochianTimer)
	print("Polyglot Stacks", player.gauge.polyglotStacks)
	print("Paradox Active", player.gauge.paradoxActive)
	print("Enochian Active", player.gauge.enochianActive)]]--

	local menu   = self.menu["ACTIONS"]["RANGE_DPS_M"]["BLM"]
	local target = TargetManager.Target

	if not target.valid or target.kind ~= 2 or target.pos:dist(player.pos) > 25 then return end

	local aoe = ObjectManager.BattleEnemiesAroundObject(target, 5) > 0

	if player.manaPercent < 70 and self.actions.manafront:canUse() then
		log:print("Using Manafront")
		self.actions.manafront:use()
	elseif player.healthPercent < 70 and self.actions.manaward:canUse() then
		log:print("Using Manaward")
		self.actions.manaward:use()
	end

	self:Combo(target, menu, log)
	self:LowCombo(target, menu, log, aoe)


end

function BlackMage:Combo(target, menu, log)
	-- Rotation
	if self.actions.blizzardiii:canUse(target) then
		log:print("Using Blizzard III on " .. target.name)
		self.actions.blizzardiii:use(target)
	elseif self.actions.blizzardiv:canUse(target) then
		log:print("Using Blizzard IV on " .. target.name)
		self.actions.blizzardiv:use(target)
	end

end

function BlackMage:LowCombo(target, menu, log, aoe)

	if player.mana < 3000 and self.actions.transpose:canUse() and player.gauge.astralStacks < 3 then
		log:print("Transposing into Ice!")
		self.actions.transpose:use()
	elseif player.gauge.astralStacks > 3 and player.manaPercent > 70 and self.actions.transpose:canUse() then
		log:print("Transposing into Fire!")
		self.actions.transpose:use()
	end

	if aoe then
		if self.actions.thunderii:canUse(target) and not self:HasThunder(target) and self.lastAction ~= self.actions.thunderii.id then
			log:print("Using Thunder II on " .. target.name)
			self.actions.thunderii:use(target)
		elseif self.actions.fireii:canUse(target) and player.gauge.astralStacks < 200 then
			log:print("Using Fire II on " .. target.name)
			self.actions.fireii:use(target)
		elseif self.actions.blizzardii:canUse(target) and player.gauge.astralStacks > 3 then
			log:print("Using Blizzard II on " .. target.name)
			self.actions.blizzardii:use(target)
		end

	else
		if self.actions.thunder:canUse(target) and not self:HasThunder(target) and self.lastAction ~= self.actions.thunder.id then
			log:print("Using Thunder on " .. target.name)
			self.actions.thunder:use(target)
		elseif self.actions.fire:canUse(target) and player.gauge.astralStacks < 3 then
			log:print("Using Fire on " .. target.name)
			self.actions.fire:use(target)
		elseif self.actions.blizzard:canUse(target) and player.gauge.astralStacks > 3 then
			log:print("Using Blizzard on " .. target.name)
			self.actions.blizzard:use(target)
		end
	end
end

function BlackMage:HasThunder(target)
	return target:hasStatus(161) or target:hasStatus(162) or target:hasStatus(163) or target:hasStatus(1210)
end

return BlackMage:new()