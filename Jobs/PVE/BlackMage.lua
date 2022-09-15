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
		thunderiv       = Action(1, 7420),

		transpose       = Action(1, 149),
		manaward        = Action(1, 157),
		manafront       = Action(1, 158),

		leylines        = Action(1, 3573),
		sharpcast       = Action(1, 3574),

		triplecast      = Action(1, 7421),
		foul            = Action(1, 7422),
		swiftcast       = Action(1, 7561),

		despair         = Action(1, 16505),
		xenoglossy      = Action(1, 16507),

		amplifier       = Action(1, 25796),
		paradox         = Action(1, 25797),
	}

	self.buffs = {
		swiftcast  = 167,
		sharpcast  = 867,
        triplecast = 1211;
	}

	self.menu = nil
	self.lastAction       = 0
	self.actionBeforeLast = 0
	self.lastElement = {
		name  = "",
		count = 0

	}

	Callbacks:Add(CALLBACK_ACTION_REQUESTED, function(actionType, actionId, targetId, result)

		if result == 1 and actionType == 1 then
			self.actionBeforeLast = self.lastAction
			self.lastAction       = actionId

			if self:LastActionIs("thunder") then
				self:SetLastElement("thunder")
			elseif self:LastActionIs("blizzard") then
				self:SetLastElement("blizzard")
			elseif self:LastActionIs("fire") then
				self:SetLastElement("fire")
			end
		end

	end)



end

function BlackMage:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["RANGE_DPS_M"]:subMenu("BlackMage", "BLM")
		self.menu["ACTIONS"]["RANGE_DPS_M"]["BLM"]:checkbox("Use AoE Skills on multiple targets", "AOE", true)		
		self.menu["ACTIONS"]["RANGE_DPS_M"]["BLM"]:slider("Min Enemies for AoE", "AOE_MIN", 1, 1, 5, 2)

end

function BlackMage:Tick(log)

	local menu   = self.menu["ACTIONS"]["RANGE_DPS_M"]["BLM"]
	local target = TargetManager.Target

	if not target.valid or target.kind ~= 2 or target.subKind ~= 5 or target.pos:dist(player.pos) > 25 then return end


	local aoe = menu["AOE"].bool and ObjectManager.BattleEnemiesAroundObject(target, 5) >= ( menu["AOE_MIN"].int - 1 )

	if player.manaPercent < 70 and player.classLevel < 72 and self.actions.manafront:canUse() then
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

	-- Rotation
	if player.classLevel >= 90 and player.gauge.paradoxActive and player.gauge.isUmbralIce and self.actions.paradox:canUse(target) then
		log:print("Using Paradox on " .. target.name)
		self.actions.paradox:use(target)
	elseif player.gauge.polyglotStacks > 0 then
		if aoe or player.classLevel < 80 then
			if self.actions.foul:canUse(target) then
				log:print("Using Foul on " .. target.name)
				self.actions.foul:use(target)
			end
		else
			if self.actions.xenoglossy:canUse(target) then
				log:print("Using Xenoglossy on " .. target.name)
				self.actions.xenoglossy:use(target)
			end
		end
	elseif not self:HasThunder(target) and self:CanUseThunder(target, aoe) then
		self:UseThunder(target, log, aoe)
	elseif self:CanUseFire(target, aoe) and player.mana > self:FireCost(target, aoe) then
		self:UseFire(target, log, aoe)
	elseif self:CanUseBlizzard(target, aoe) and not self.actions.manafront:canUse() then
		self:UseBlizzard(target, log, aoe)
	end	

end

function BlackMage:Weave(target, log, aoe)
	if self:LastActionIs("thunder") and self.actions.triplecast:canUse() and player.classLevel >= 66 and not player:hasStatus(1211) then
		log:print("Using Triple Cast")
		--log:print("1-1")
		self.actions.triplecast:use()
	elseif self.lastAction == self.actions.triplecast.id then
		if self.lastElement.name == "thunder" and self:CanUseFire(target, aoe) then
			self:UseFire(target, log, aoe)
			--log:print("2-0")
			return true
		elseif self.lastElement.name == "fire" and self.actions.despair:canUse(target) then
			log:print("Using Despair on " .. target.name)
			--log:print("6-0")
			self.actions.despair:use(target)
		end
	elseif self.lastAction == self.actions.leylines.id and self:CanUseFire(target, aoe) then
		self:UseFire(target, log, aoe)
		--log:print("4-0")
		return true	
	elseif self.lastAction == self.actions.blizzardiii.id and self.actions.xenoglossy:canUse(target) then
		log:print("Using Xenoglossy on " .. target.name)
		--log:print("10-0")		
		self.actions.xenoglossy:use(target)
	elseif self.lastAction == self.actions.xenoglossy.id and self.actions.paradox:canUse(target) then
		log:print("Using Paradox on " .. target.name)
		--log:print("11-0")		
		self.actions.paradox:use(target)	
	elseif self.lastAction == self.actions.despair.id then
		if self.actionBeforeLast == self.actions.triplecast.id and self.actions.manafront:canUse()  then
			log:print("Using Manafont")
			--log:print("6-1")
			self.actions.manafront:use()
			return true
		elseif self.actionBeforeLast == self.actions.sharpcast.id and self.actions.blizzardiii:canUse(target) then
		    log:print("Using Blizzard III on " .. target.name)
		    self.actions.blizzardiii:use(target)
		    --print("9-0")
		    return true
		end
	elseif self.lastAction == self.actions.paradox.id and self.actions.blizzardiv:canUse(target) then
		log:print("Using Blizzard IV on " .. target.name)
		--print("12-0")
		self.actions.blizzardiv:use(target)
		return true
	elseif self.lastElement.name == "fire" then
		--log:print("Element Count: " .. self.lastElement.count)
		if self.lastElement.count == 1 then
			if self:CanUseFire(target, aoe) then
				self:UseFire(target, log, aoe)
				--log:print("3-0")
				return true
			end
		elseif self.lastElement.count == 2 then
		    if self.actions.amplifier:canUse()  then
				log:print("Using Amplifier")
				--log:print("3-1")
				self.actions.amplifier:use()
				return true
			end
			if self.actions.leylines:canUse() then
				log:print("Using Ley Lines")
				--log:print("3-2")
				self.actions.leylines:use()
				return true
			end
		elseif self.lastElement.count == 3 then
			if self.actions.swiftcast:canUse() and not player:hasStatus(167) and not player:hasStatus(1211) then
				log:print("Using Swift Cast")
				--log:print("4-1")
				self.actions.swiftcast:use()
				return true
			elseif self:CanUseFire(target, aoe) then
				self:UseFire(target, log, aoe)
				--log:print("5-0")
				return true
			end
		elseif  self.lastElement.count == 4 and  self.actions.triplecast:canUse() and player.classLevel >= 66 and not player:hasStatus(1211) then
			log:print("Using Triple Cast")
			--log:print("5-1")
			self.actions.triplecast:use()
			return true
		elseif  self.lastElement.count == 5 then
			if self.actions.sharpcast:canUse() and not player:hasStatus(867) then
				log:print("Using Sharp Cast")
				--log:print("7-1")
				self.actions.sharpcast:use()
				return true
			elseif self.actions.despair:canUse(target) then
				log:print("Using Despair on " .. target.name)
				--log:print("8-0")
				self.actions.despair:use(target)
				return true
			end
		end	
	end

	return false
end

function BlackMage:SetLastElement(elementName)
	
	if self.lastElement.name == elementName then
		self.lastElement.count = self.lastElement.count + 1
	else
		self.lastElement.count = 1	
	end

	self.lastElement.name = elementName

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
			self.lastAction == self.actions.thunderiii.id or
			self.lastAction == self.actions.thunderiv.id
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

function BlackMage:ActionBeforeLastActionIs(stringName)
	if stringName == "fire" then
		return 
			self.actionBeforeLast == self.actions.fire.id or
			self.actionBeforeLast == self.actions.fireii.id or 
			self.actionBeforeLast == self.actions.highfireii.id or
			self.actionBeforeLast == self.actions.fireiii.id or
			self.actionBeforeLast == self.actions.fireiv.id
	elseif stringName == "thunder" then
		return
			self.actionBeforeLast == self.actions.thunder.id or
			self.actionBeforeLast == self.actions.thunderii.id or 
			self.actionBeforeLast == self.actions.thunderiii.id or
			self.actionBeforeLast == self.actions.thunderiv.id
	elseif stringName == "blizzard" then
		return 
			self.actionBeforeLast == self.actions.blizzard.id or
			self.actionBeforeLast == self.actions.blizzardii.id or 
			self.actionBeforeLast == self.actions.highblizzardii.id or
			self.actionBeforeLast == self.actions.blizzardiii.id or
			self.actionBeforeLast == self.actions.blizzardiv.id
	end
	return false
end

function BlackMage:FireCost(target, aoe)
	if aoe then
		return
			player.classLevel < 82 and self.actions.fireii.cost or self.actions.highfireii.cost

	else
		return 
			player.classLevel <  35 and self.actions.fire.cost or
			player.classLevel <  60 and self.actions.fireiii.cost or
			player.classLevel >= 60 and self.actions.fireiv:canUse(target) and self.actions.fireiv.cost or self.actions.fireiii.cost
	end
end

function BlackMage:CanUseFire(target, aoe)
	
	if player.mana < self:FireCost(target, aoe) then return false end

	if aoe then
		return
			player.classLevel < 82 and self.actions.fireii:canUse(target) or self.actions.highfireii:canUse(target)

	else
		return 
			player.classLevel <  35 and self.actions.fire:canUse(target) or
			self.actions.fireiv:canUse(target) or self.actions.fireiii:canUse(target)			
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
		elseif self.actions.fireiii:canUse(target) then
			log:print("Using Fire III on " .. target.name)
			self.actions.fireiii:use(target)
		elseif player.classLevel < 35 and self.actions.fire:canUse(target) then
			log:print("Using Fire on " .. target.name)
			self.actions.fire:use(target)
		end
	end

end

function BlackMage:BlizzardCost(target, aoe)
	if aoe then
		return
			player.classLevel < 82 and self.actions.blizzardii.cost or self.actions.blizzardii.cost

	else
		return 
			player.classLevel <  35 and self.actions.blizzard.cost or
			player.classLevel <  60 and self.actions.blizzardiii.cost or
			player.classLevel >= 60 and self.actions.blizzardiv:canUse(target) and self.actions.blizzardiv.cost or self.actions.blizzardiii.cost
	end
end

function BlackMage:CanUseBlizzard(target, aoe)
	
	if aoe then
		return
			player.classLevel < 82 and self.actions.blizzardii:canUse(target) or self.actions.highblizzardii:canUse(target)

	else
		return 
			player.classLevel < 35 and self.actions.blizzard:canUse(target) or
			self.actions.blizzardiv:canUse(target) or self.actions.blizzardiii:canUse(target)			
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

function BlackMage:CanUseThunder(target, aoe)

	if self:LastActionIs("thunder") then return false end
	
	if aoe then
		return 
			player.classLevel < 64 and self.actions.thunderiv:canUse(target) or self.actions.thunderii:canUse(target)
	else

		return
			player.classLevel < 26  and self.actions.thunder:canUse(target) or
			player.classLevel >= 45 and self.actions.thunderiii:canUse(target)
	end

	
end

function BlackMage:UseThunder(target, log, aoe)

	if aoe then
		if player.classLevel >= 64 and self.actions.thunderiv:canUse(target) then
			log:print("Using Thunder IV on " .. target.name)
			self.actions.thunderiv:use(target)
		elseif self.actions.thunderii:canUse(target) then
			log:print("Using Thunder II on " .. target.name)
			self.actions.thunderii:use(target)
		end
	else
		if player.classLevel >= 45 and self.actions.thunderiii:canUse(target) then
			log:print("Using Thunder III on " .. target.name)
			self.actions.thunderiii:use(target)	
		elseif self.actions.thunder:canUse(target) then
			log:print("Using Thunder on " .. target.name)
			self.actions.thunder:use(target)
		end
	end
end

function BlackMage:HasThunder(target)
	return target:hasStatus(161) or target:hasStatus(162) or target:hasStatus(163) or target:hasStatus(1210)
end

return BlackMage:new()