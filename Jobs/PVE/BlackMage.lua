local BlackMage = Class("BlackMage")

function BlackMage:initialize()

	self.actions = {
		
		blizzard        = Action(1, 142),
		blizzardii      = Action(1, 25793),
		highblizzardii  = Action(1, 25794),
		blizzardiii     = Action(1, 154),		
		blizzardiv      = Action(1, 3576),

		fire            = Action(1, 141),
		fireii          = Action(1, 147),
		highfireii      = Action(1, 25794),
		fireiii         = Action(1, 152),
		fireiv          = Action(1, 3577),

		thunder         = Action(1, 144),
		thunderii       = Action(1, 7447),
		thunderiii      = Action(1, 153),

		transpose       = Action(1, 149),
		manaward        = Action(1, 157),
		manafront       = Action(1, 158),

		leylines        = Action(1, 3573),
		triplecast      = Action(1, 7421),
		swiftcast       = Action(1, 7561),

		amplifier       = Action(1, 25796),
	}

	self.menu = nil
	self.lastAction  = 0
	self.lastThunder = 0

	Callbacks:Add(CALLBACK_ACTION_REQUESTED, function(actionType, actionId, targetId, result)

		if result == 1 and actionType == 1 then
			self.lastAction = actionId

			if self:LastActionIs("thunder") then
				self.lastThunder = os.clock()
			end
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

	self:Combo(target, menu, log, aoe)
end

function BlackMage:Combo(target, menu, log, aoe)

	if self:Weave(target, log, aoe) then return end

	if player.mana < 3000 and self.actions.transpose:canUse() and player.gauge.astralStacks < 253 then
		log:print("Transposing into Ice!")
		self.actions.transpose:use()
		return
	elseif player.gauge.astralStacks >= 253 and player.manaPercent > 70 and self.actions.transpose:canUse() then
		log:print("Transposing into Fire!")
		self.actions.transpose:use()
		return
	end

	-- Rotation
	if not self:HasThunder(target) and self:CanUseThunder(target) and (os.clock() - self.lastThunder) > 2 then
		print(os.clock() - self.lastThunder)
		self:UseThunder(target, log)
	elseif self.actions.triplecast:canUse() then
		log:print("Using Triple Cast")
		self.actions.triplecast:use()
	elseif self:CanUseFire(target, aoe) and player.gauge.astralStacks < 253 then
		self:UseFire(target, log, aoe)
	elseif self:CanUseBlizzard(target, aoe) and player.gauge.astralStacks >= 253 then
		self:UseBlizzard(target, log, aoe)
	end	

end

function BlackMage:Weave(target, log, aoe)
	if self:LastActionIs("thunder") and self.actions.triplecast:canUse() then
		log:print("Using Triple Cast")
		self.actions.triplecast:use()
	elseif self:LastActionIs("fire") then
		if self.actions.amplifier:canUse()  then
			log:print("Using Amplifier")
			self.actions.amplifier:use()
			return true
		elseif self.actions.leylines:canUse() then
			log:print("Using Ley Lines")
			self.actions.leylines:use()
			return true
		elseif self.actions.leylines:canUse() then
			log:print("Using Ley Lines")
			self.actions.leylines:use()
			return true
		elseif self.actions.swiftcast:canUse() then
			log:print("Using Swift Cast")
			self.actions.swiftcast:use()
		elseif self.actions.triplecast:canUse() then
			log:print("Using Triple Cast")
			self.actions.triplecast:use()
		end
	elseif self.lastAction == self.actions.amplifier.id and self.actions and self.actions.leylines:canUse()  then
		log:print("Using Ley Lines")
		self.actions.leylines:use()
		return true
	end
	return false
end

function BlackMage:LastActionIs(stringName)
	if stringName == "fire" then
		return 
			self.lastAction == self.actions.fire.id or
			self.lastAction == self.actions.fireii.id or 
			self.lastAction == self.actions.highfireii.id or
			self.lastAction == self.actions.fireiii.id or
			self.lastAction == self.actions.fireiv.id
	elseif stringName == "thunder" then
		return
			self.lastAction == self.actions.thunder.id or
			self.lastAction == self.actions.thunderii.id or 
			self.lastAction == self.actions.thunderiii.id
	elseif stringName == "blizzard" then
		return 
			self.lastAction == self.actions.blizzard.id or
			self.lastAction == self.actions.blizzardii.id or 
			self.lastAction == self.actions.highblizzardii.id or
			self.lastAction == self.actions.blizzardiii.id or
			self.lastAction == self.actions.blizzardiv.id
	end
	return false
end

function BlackMage:CanUseFire(target, aoe)
	
	if aoe then
		return
			player.classJob < 82 and self.actions.fireii:canUse(target) or self.actions.highfireii:canUse(target)

	else
		return 
			player.classJob < 35 and self.actions.fire:canUse(target) or
			player.classJob < 60 and self.actions.fireiii:canUse(target) or
			self.actions.fireiv:canUse(target)
	end

end

function BlackMage:UseFire(target, log, aoe)

	if aoe then
		if player.classLevel >= 82 and self.actions.highfireii:canUse(target) then
			log:print("Using High Fire II on " .. target.name)
			self.actions.highfireii:use(target)
		elseif self.actions.fireii:canUse(target) then
			log:print("Using Fire II on " .. target.name)
			self.actions.fireii:use(target)
		end
	else
		if self.actions.fireiv:canUse(target) then
			log:print("Using Fire IV on " .. target.name)
			self.actions.fireiv:use(target)
		elseif player.classJob < 60 and self.actions.fireiii:canUse(target) then
			log:print("Using Fire III on " .. target.name)
			self.actions.fireiii:use(target)
		elseif player.classJob < 35 and self.actions.fire:canUse(target) then
			log:print("Using Fire on " .. target.name)
			self.actions.fire:use(target)
		end
	end

end

function BlackMage:CanUseBlizzard(target, aoe)
	
	if aoe then
		return
			player.classJob < 82 and self.actions.blizzardii:canUse(target) or self.actions.highblizzardii:canUse(target)

	else
		return 
			player.classJob < 35 and self.actions.blizzard:canUse(target) or
			player.classJob < 60 and self.actions.blizzardiii:canUse(target) or
			self.actions.blizzardiv:canUse(target)
	end

end

function BlackMage:UseBlizzard(target, log, aoe)
	if aoe then
		if player.classLevel >= 82 and self.actions.highblizzardii:canUse(target) then
			log:print("Using High Blizzard II on " .. target.name)
			self.actions.highblizzardii:use(target)
		elseif self.actions.blizzardii:canUse(target) then
			log:print("Using Blizzard II on " .. target.name)
			self.actions.blizzardii:use(target)
		end
	else
		if self.actions.blizzardiv:canUse(target) then
			log:print("Using Blizzard IV on " .. target.name)
			self.actions.blizzardiv:use(target)
		elseif self.actions.blizzardiii:canUse(target) then
			log:print("Using Blizzard III on " .. target.name)
			self.actions.blizzardiii:use(target)
		elseif self.actions.blizzard:canUse(target) then
			log:print("Using Blizzard on " .. target.name)
			self.actions.blizzard:use(target)
		end
	end
end

function BlackMage:CanUseThunder(target)
	
	return
		player.classJob < 26  and self.actions.thunder:canUse(target) or
		player.classJob < 45  and self.actions.thunderii:canUse(target) or
		player.classJob >= 45 and self.actions.thunderiii:canUse(target)

	
end

function BlackMage:UseThunder(target, log)
	if player.classJob >= 45 and self.actions.thunderiii:canUse(target) then
		log:print("Using Thunder III on " .. target.name)
		self.actions.thunderiii:use(target)
	elseif player.classJob < 45 and self.actions.thunderii:canUse(target) then
		log:print("Using Thunder II on " .. target.name)
		self.actions.thunderii:use(target)
	elseif player.classJob < 26 and self.actions.thunder:canUse(target) then
		log:print("Using Thunder on " .. target.name)
		self.actions.thunder:use(target)
	end
end

function BlackMage:HasThunder(target)
	return target:hasStatus(161) or target:hasStatus(162) or target:hasStatus(163)
end

return BlackMage:new()