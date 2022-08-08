local Ninja = Class("Ninja")

function Ninja:initialize()

	self.actions = {		

		spinning      = Action(1, 2240),
        slash         = Action(1, 2242),
        hide          = Action(1, 2245),

        mug           = Action(1, 2248),		
		aeolian       = Action(1, 2255),

		ten           = Action(1, 2259),
		chi           = Action(1, 2261),
		jin           = Action(1, 2263),

		kassatsu      = Action(1, 2264),

		-- Ninjutsu
		raiton        = Action(1, 2267),
		hyoton        = Action(1, 2268),
		huton         = Action(1, 2269),
		doton         = Action(1, 2270),
		suiton        = Action(1, 2271),

		dream         = Action(1, 3566),

		bhavacakra    = Action(1, 7402),
		tenchijin     = Action(1, 7403),

		meisui        = Action(1, 16489),
		hyosho        = Action(1, 16492);
		bunshin       = Action(1, 16493),

		kamaitachi    = Action(1, 25774),
		forkedraiju   = Action(1, 25777),
        fleetingraiju = Action(1, 25778),

	}
	self.ninjutsus = {
		[2267]  = true,
		[2268]  = true,
		[2269]  = true,
		[2270]  = true,
		[2271]  = true,
		[16492] = true,
	}

	self.menu         = nil
	self.lastAction   = 0
	self.lastNinjutsu = 0

	self.usingHuton   = false
	self.usingDoton   = false
	self.usingSuiton  = false
	self.usingRaiton  = false
	self.raitonMode   = 0
	self.usingHyosho  = false
	self.hyoshoMode   = 0

	self.prepull = {
		doton      = false,
		performing = false
	}
		
	Callbacks:Add(CALLBACK_ACTION_REQUESTED, function(actionType, actionId, targetId, result)

		if result == 1 and actionType == 1 then
			if self.usingSuiton and actionId == self.actions.suiton.id then
				self.usingSuiton = false
				self.prepull.performing = false
				self.prepull.doton = false
			elseif self.usingHyosho and actionId == self.actions.hyosho.id then
				self.usingHyosho = false
				self.hyoshoMode  = 0
			elseif self.usingRaiton and actionId == self.actions.raiton.id then
				self.usingRaiton = false
			end
			if self.ninjutsus[actionId] ~= nil then
				self.lastNinjutsu = actionId
			end
			self.lastAction = actionId
		end

	end)

end

function Ninja:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["MELEE_DPS"]:subMenu("Ninja", "NIN")
end

function Ninja:Tick(log)

	local menu       = self.menu["ACTIONS"]["MELEE_DPS"]["NIN"]
	local target     = TargetManager.Target	
	local ninki      = player.gauge.ninki
	local hutonTimer = player.gauge.hutonTimer


	if self.menu["PREPULL_KEY"].keyDown then
		if not self.prepull.performing  then
			self.prepull.performing = true
		end
	end

	if self.usingHuton then
		if hutonTimer > 0 then
			self.usingHuton = false
		else
			return self:UseHuton(log)
		end
	elseif self.usingDoton then
		if player:hasStatus(501) then
			self.usingDoton = false
			if self.prepull.performing then
				self.prepull.doton = true
			end
		else
			return self:UseDoton(log)
		end
	end

	if self.prepull.performing then
		self:StandardPrePull(target, menu, log, hutonTimer)
	elseif target.valid then
		self:Combo(target, menu, log, hutonTimer, ninki)
	end
end

function Ninja:StandardPrePull(target, menu, log, hutonTimer)	
	
	if self.usingSuiton then
		return self:UseSuiton(log, target, true)
	end

	if hutonTimer == 0 and self:CanUseNinjutsu() then
		self.usingHuton = true
		log:print("Preparing to use Huton")
	elseif hutonTimer > 0 then
		if hutonTimer < 57500 and self:CanUseNinjutsu() and not player:hasStatus(501) and not self.prepull.doton then
			self.usingDoton = true
			log:print("Preparing to use Doton")
		elseif self.prepull.doton and not player:hasStatus(614) and self.actions.hide:canUse() then
			self.actions.hide:use()
			log:print("Using Hide")
		elseif player:hasStatus(614) and self:CanUseNinjutsu() and hutonTimer < 56000 then
			self.usingSuiton = true
			log:print("Preparing to use Suiton")
		end
	end

end

function Ninja:Combo(target, menu, log, hutonTimer, ninki)

	-- Ninjutsus
	if self.usingSuiton then
		return self:UseSuiton(log, target, false)
	elseif self.usingHyosho then
		return self:UseHyosho(log, target)
	elseif self.usingRaiton then
		return self:UseRaiton(log, target)
	elseif player:hasStatus(1186) then
		return self:TenChiJin(log, target)
	end

	-- Action Weaving Check
	if self:Weave(log, target, ninki) then return end

	if hutonTimer == 0 and self:CanUseNinjutsu() then
		self.usingHuton = true
		log:print("Preparing to use Huton")
	elseif self.actions.kassatsu:canUse(target) then
		self.actions.kassatsu:use(target)
		log:print("Using Kassatsu on " .. target.name)
	elseif self.actions.mug:canUse(target) then
		self.actions.mug:use(target)
		log:print("Using Mug on " .. target.name)
	elseif self.actions.bunshin:canUse(target) then
		self.actions.bunshin:use(target)
		log:print("Using Bunshin on " .. target.name)
	elseif self.actions.kamaitachi:canUse(target) then
		self.actions.kamaitachi:use(target)
		log:print("Using Phantom Kamaitachi on " .. target.name)
	elseif self.actions.dream:canUse(target) then
		self.actions.dream:use(target)
		log:print("Using Dream Within a Dream on " .. target.name)
	elseif self:CanUseHyosho() and player:hasStatus(497) and self.lastNinjutsu ~= self.actions.hyosho.id then
		self.usingHyosho = true
		log:print("Preparing to use Hyosho Ranryu")
	elseif self:CanUseRaiton() and self.lastNinjutsu == self.actions.hyosho.id then
		self.usingRaiton = true
		log:print("Preparing to use Raiton for Combo")
	elseif self.actions.meisui:canUse() then
		self.actions.meisui:use()
		log:print("Using Meisui")
	elseif self.actions.fleetingraiju:canUse(target) then
		self.actions.fleetingraiju:use(target)
		log:print("Using Fleeting Raiju on " .. target.name)
	elseif player.classLevel < 90 and self.actions.bhavacakra:canUse(target) then
		self.actions.bhavacakra:use(target)
		log:print("Using Bhavacakra on " .. target.name)
	elseif self.actions.spinning:canUse(target) then
		self.actions.spinning:use(target)
		log:print("Using Spinning Edge on " .. target.name)
	end

end

function Ninja:TenChiJin(log, target)
	if self.lastAction == self.actions.tenchijin.id and self.actions.ten:canUse(target) then
		log:print("Using Fuma Shuriken on " .. target.name)
		self.actions.ten:use(target)
	elseif self.lastAction == self.actions.ten.id and self.actions.chi:canUse(target) then
		log:print("Using Raiton on " .. target.name)
		self.actions.chi:use(target)
	elseif self.lastAction == self.actions.chi.id and self.actions.jin:canUse(target) then
		log:print("Using Suiton " .. target.name)
		self.actions.jin:use(target)
	end
end

function Ninja:Weave(log, target, ninki)
	
	if self.lastAction == self.actions.spinning.id and self.actions.slash:canUse(target) then
		log:print("Using Gust Slash on " .. target.name)
		self.actions.slash:use(target)
		return true
	elseif self.lastAction == self.actions.kassatsu.id and self.actions.spinning:canUse(target) then
		log:print("Using Spinning Edge on " .. target.name)
		self.actions.spinning:use(target)
		return true
	elseif self.lastAction == self.actions.bunshin.id and self.actions.aeolian:canUse(target) then
		log:print("Using Aeolian Edge on " .. target.name)
		self.actions.aeolian:use(target)
		return true
	elseif self.lastAction == self.actions.raiton.id and not player:hasStatus(1186) and self.actions.tenchijin:canUse() then
		log:print("Using Ten Chi Jin")
		self.actions.tenchijin:use()
		return true
	elseif self.lastAction == self.actions.forkedraiju.id and ninki >= 50 and self.actions.bhavacakra:canUse(target) then
		log:print("Using Bhavacakra")
		self.actions.bhavacakra:use(target)
		return true
	elseif self.lastAction == self.actions.bhavacakra.id and ninki < 50 and self:CanUseRaiton() then
		log:print("Preparing to Use Raiton for Combo End")
		self.usingRaiton = true
		return true
	end

	return false
end


function Ninja:CanUseNinjutsu()
	return self.actions.ten:canUse() and self.actions.chi:canUse() and self.actions.jin:canUse()
end

function Ninja:CanUseRaiton()
	return self.actions.chi:canUse() and (self.actions.jin:canUse() or self.actions.ten:canUse())
end

function Ninja:CanUseHyosho()
	return self.actions.jin:canUse() and (self.actions.chi:canUse() or self.actions.ten:canUse())
end

function Ninja:UseHyosho(log, target)

	if self.lastAction == self.actions.jin.id and self.actions.hyosho:canUse(target) then
		self.actions.hyosho:use(target)
		log:print("Using Hyosho Ranryu on " .. target.name)
	end
	if self.hyoshoMode == 0 then
		if self.actions.chi:canUse() and self.actions.jin:canUse() then
			self.hyoshoMode = 1
		elseif self.actions.ten:canUse() and self.actions.jin:canUse() then
			self.hyoshoMode = 2
		end
	elseif self.hyoshoMode == 1 then
		if self.lastAction == self.actions.chi.id and self.actions.jin:canUse() then
			self.actions.jin:use()
			log:print("Using Jin")
		elseif self.actions.chi:canUse() then
			log:print("Using Chi")
			self.actions.chi:use()
		end
	elseif self.hyoshoMode == 2 then
		if self.lastAction == self.actions.ten.id and self.actions.jin:canUse() then
			self.actions.jin:use()
			log:print("Using Jin")
		elseif self.actions.ten:canUse() then
			log:print("Using Ten")
			self.actions.ten:use()
		end
	end	
end

function Ninja:UseRaiton(log, target)
	
	if self.lastAction == self.actions.chi.id and self.actions.raiton:canUse(target) then
		self.actions.raiton:use(target)
		log:print("Using Raiton on " .. target.name)
	end
	if self.raitonMode == 0 then
		if self.actions.chi:canUse() and self.actions.ten:canUse() then
			self.raitonMode = 1
		elseif self.actions.chi:canUse() and self.actions.jin:canUse() then
			self.raitonMode = 2
		end
	elseif self.raitonMode == 1 then
		if self.lastAction == self.actions.ten.id and self.actions.chi:canUse() then
			self.actions.chi:use()
			log:print("Using Chi")
		elseif self.actions.ten:canUse() then
			log:print("Using Ten")
			self.actions.ten:use()
		end
	elseif self.raitonMode == 2 then
		if self.lastAction == self.actions.jin.id and self.actions.chi:canUse() then
			self.actions.chi:use()
			log:print("Using Chi")
		elseif self.actions.jin:canUse() then
			log:print("Using Jin")
			self.actions.jin:use()
		end
	end	
end

function Ninja:UseHuton(log)
	if self.lastAction == self.actions.ten.id and self.actions.huton:canUse() then
		self.actions.huton:use()
		log:print("Using Huton")
	elseif self.lastAction == self.actions.chi.id and self.actions.ten:canUse() then
		self.actions.ten:use()
		log:print("Using Ten")
	elseif self.lastAction == self.actions.jin.id and self.actions.chi:canUse() then
		self.actions.chi:use()
		log:print("Using Chi")
	elseif self.actions.jin:canUse() then
		log:print("Using Jin")
		self.actions.jin:use()
	end
end

function Ninja:UseDoton(log)
	if self.lastAction == self.actions.chi.id and self.actions.doton:canUse() then
		self.actions.doton:use()
		log:print("Using Doton")
	elseif self.lastAction == self.actions.jin.id and self.actions.chi:canUse() then
		self.actions.chi:use()
		log:print("Using Chi")
	elseif self.lastAction == self.actions.ten.id and self.actions.jin:canUse() then
		self.actions.jin:use()
		log:print("Using Jin")
	elseif self.actions.ten:canUse() then
		log:print("Using Ten")
		self.actions.ten:use()
	end
end

function Ninja:UseSuiton(log, target, prepull)

	if prepull then
		if target.valid and self.lastAction == self.actions.jin.id and self.actions.suiton:canUse(target) and player.gauge.hutonTimer < 51000 then
			self.actions.suiton:use(target)
			log:print("Using Suiton")	
		end
	else
		if self.lastAction == self.actions.jin.id and self.actions.suiton:canUse(target) then
			self.actions.suiton:use(target)
			log:print("Using Suiton")	
		end
	end

	if prepull and self.lastAction == self.actions.jin.id then return end
	
	if self.lastAction == self.actions.chi.id and self.actions.jin:canUse() then
		self.actions.jin:use()
		log:print("Using Jin")
	elseif self.lastAction == self.actions.ten.id and self.actions.chi:canUse() then
		self.actions.chi:use()
		log:print("Using Chi")
	elseif self.actions.ten:canUse() then
		log:print("Using Ten")
		self.actions.ten:use()
	end
end

return Ninja:new()