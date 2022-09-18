local BlackMage = Class("BlackMage")

function BlackMage:initialize()

	self.actions = {
		
		blizzard        = Action(1, 142),
		blizzardii      = Action(1, 25793),
		highblizzardii  = Action(1, 25795),
		blizzardiii     = Action(1, 154),		
		blizzardiv      = Action(1, 3576),

		freeze          = Action(1, 159),
		flare           = Action(1, 162),


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
		manafont       = Action(1, 158),

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

	Callbacks:Add(CALLBACK_ACTION_EFFECT, function(sourceObj, pos, actionId, targetId)
      if sourceObj == player and actionId ~= 7 and actionId ~= 8 then
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

	--if player.manaPercent < 70 and player.classLevel < 72 and self.actions.manafont:canUse() then
		--log:print("Using manafont")
		--self.actions.manafont:use()
	if player.healthPercent < 70 and self.actions.manaward:canUse() then
		log:print("Using Manaward")
		self.actions.manaward:use()
	end
	
	

	self:Combo(target, menu, log, aoe)
end

function BlackMage:Combo(target, menu, log, aoe)

	if player.gauge.isAstralFire and player.gauge.elementTimer >= 2500 and player.gauge.elementTimer <= 6000 and self.actions.paradox:canUse(target) then
		log:print("Using Paradox to extend Astral Fire on " .. target.name)
		self.actions.paradox:use(target)
	elseif player.gauge.isAstralFire and player.gauge.elementTimer >= 3500 and player.gauge.elementTimer <= 6000 and self.actions.fireiii:canUse(target) and player:hasStatus(165) then
		log:print("Using Firestarter to extend Astral Fire on " .. target.name)
		self.actions.fireiii:use(target)	
	elseif player.gauge.isAstralFire and player.gauge.elementTimer >= 3500 and player.gauge.elementTimer <= 6000 and self.actions.fireiii:canUse(target) and player.mana >= 4800 then
		log:print("Using Fire III to extend Astral Fire on " .. target.name)
		self.actions.fireiii:use(target)
	elseif self.lastAction == self.actions.paradox.id and self.actions.blizzardiv:canUse(target) then
		log:print("Using Blizzard IV on " .. target.name)
		--print("TRYING TO USE BLIZZARD")
		self.actions.blizzardiv:use(target)
		return true
	--A check to make sure it uses Fire after Manafont... sometimes still using Blizzard 3 without it.
	elseif self.lastAction == self.actions.manafont.id then
		self:UseFire(target, log, aoe)
		return true
	elseif self:Weave(target, log, aoe) then 
		return
	elseif self.lastAction == self.actions.blizzardiii.id and self.actions.paradox:canUse(target) then
		log:print("Using Paradox on " .. target.name)
		self.actions.paradox:use(target)
	elseif player.gauge.polyglotStacks > 0 then
		if aoe or player.classLevel < 80 then
			if self.actions.foul:canUse(target) then
				log:print("Using Foul on " .. target.name)
				self.actions.foul:use(target)
			end
		end
	elseif not player:hasStatus(867) and self.actions.sharpcast:canUse() then
        log.print("Using Sharpcast")
		self.actions.sharpcast:use()
	end

	if player.mana < self:FireCost(target, aoe) then
		if player.gauge.isAstralFire then
			if self:CanUseManaBuster(target, aoe) then
				self:UseManaBuster(target, aoe, log)
			elseif self:CanUseBlizzard(target, aoe) and player.mana < 3000 then
				self:UseBlizzard(target, log, aoe)
			end
		elseif self:CanUseBlizzard(target, aoe) then
			self:UseBlizzard(target, log, aoe)
		end
	elseif self:CanUseFire(target, aoe) then
		self:UseFire(target, log, aoe)
	end	
end

function BlackMage:Weave(target, log, aoe)
	if (self.lastAction == self.actions.highblizzardii.id or self.lastAction == self.actions.blizzardii.id) and self.actions.freeze:canUse(target) then
		self.actions.freeze:use(target)
		log:print("Using Freeze on " .. target.name)
		return true
	--elseif self.lastAction == self.actions.xenoglossy.id and self.actions.paradox:canUse(target) then
		--log:print("Using Paradox on " .. target.name)
		--log:print("11-0")		
		--self.actions.paradox:use(target)	
		--return true
	-- Tries to keep Thunder up on target. Maybe a way to read how much time is left on Thunder dot?
	elseif not self:HasThunder(target) and self:CanUseThunder(target, aoe) and (player.gauge.isAstralFire or player.gauge.isUmbralIce) then
			self:UseThunder(target, log, aoe)
			return true
	--Overcap feature. If its at 2 Poly stacks, should cast Xenoglossy to get rid of them
	elseif player.gauge.polyglotStacks > 1 then
		if self.actions.xenoglossy:canUse(target) then
			log:print("Using Xenoglossy to not overcap on " .. target.name)
			self.actions.xenoglossy:use(target)
		end
	--Opener Thunder (Only casts with Sharpcast up, no Thundercloud)
	elseif player:hasStatus(867) and not player:hasStatus(164) and self:CanUseThunder(target, aoe) and not self:HasThunder(target) then
		self:UseThunder(target, log, aoe)
		return true
	elseif self.lastAction == self.actions.freeze.id and self.actions.thunderiv:canUse(target) then
		log:print("Using Thunder IV on "..target.name )
		self.actions.thunderiv:use(target)
		return true
	elseif self.lastAction == self.actions.manafont.id and player.mana >= self:FireCost(target, log) and self:CanUseFire(target, aoe) then
		self:UseFire(target, log, aoe)
		return true
    elseif self.lastAction == self.actions.fireiii.id and not self:HasThunder(target) and self:CanUseThunder(target, aoe) then
        self:UseThunder(target, log, aoe)
        return true
	elseif self:LastActionIs("thunder") and player.gauge.isAstralFire and self.actions.triplecast:canUse() and player.classLevel >= 66 and not player:hasStatus(1211) then
		log:print("Using Triple Cast")
		--log:print("1-1")	
		self.actions.triplecast:use()
		return true
	elseif self.lastAction == self.actions.triplecast.id then
		if self.lastElement.name == "thunder" and self:CanUseFire(target, aoe) then
			self:UseFire(target, log, aoe)
			--log:print("2-0")
			return true
		elseif self.lastElement.name == "fire" and self:CanUseManaBuster(target, aoe) and player.mana < self:FireCost(target, aoe) then
			self:UseManaBuster(target, aoe, log)
			--log:print("6-0")			
		end
	elseif self.lastAction == self.actions.leylines.id and self:CanUseFire(target, aoe) then
		self:UseFire(target, log, aoe)
		--log:print("4-0")
		return true	
	elseif self.lastAction == self.actions.blizzardiv.id and self.actions.xenoglossy:canUse(target) then
		log:print("Using Xenoglossy on " .. target.name)
		--log:print("10-0")		
		self.actions.xenoglossy:use(target)
		return true
	elseif self.lastAction == self.actions.despair.id then
		if self.actions.manafont:canUse()  then
			log:print("Using Manafont")
			self.actions.manafont:use()
			--log:print("MANAFONT USED")
			return true
		--elseif self.actions.blizzardiii:canUse(target) and player.mana < 800 and not self.lastAction == self.actions.manafont.id then
		    --log:print("Using Blizzard III on " .. target.name)
		    --self.actions.blizzardiii:use(target)
		    --print("CASTING BLIZZARD 3 ANYWAYS")
		    --return true
		end
	elseif self.lastElement.name == "fire" and not player.gauge.isUmbralIce then
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
			if self.actions.swiftcast:canUse() and not player:hasStatus(167) then
				log:print("Using Swift Cast")
				log:print("4-1")
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
			elseif self:CanUseManaBuster(target, aoe) and player.mana < self:FireCost(target, aoe) then
				self:UseManaBuster(target, aoe, log)
				--log:print("8-0")
				return 	true
			end
		end	
	end

	return false
end

function BlackMage:UseManaBuster(target, aoe, log)
	
	if aoe and self.actions.flare:canUse(target) then
		self.actions.flare:use(target)
		log:print("Using Flare on " .. target.name)
	elseif self.actions.despair:canUse(target) then
		self.actions.despair:use(target)
		log:print("Using Despair on " .. target.name)
	end
end

function BlackMage:CanUseManaBuster(target, aoe)
	if aoe then
		return self.actions.flare:canUse(target)
	else
		return self.actions.despair:canUse(target)
	end

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