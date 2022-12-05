local Sage = Class("Sage")

function Sage:initialize()

	self.actions = {	
		
		dosis      = Action(1, 24283),
		diagnosis  = Action(1, 24284),
		phlegma    = Action(1, 24289),
		eukrasia   = Action(1, 24290),
		ekdosis    = Action(1, 24293),
		
		dosisii    = Action(1, 24306),
		phlegmaii  = Action(1, 24307),
		ekdosisii  = Action(1, 24308),
		dosisiii   = Action(1, 24312),
		phlegmaiii = Action(1, 24313),
		ekdosisiii = Action(1, 24314),


	}
	
	self.healing_bonus = function ()
		return player.classLevel >= 40 and 30 or
		player.classLevel >= 20 and 10 or 0
	end

	self.healing_actions = {

		diagnosis  = Action(1, 24284),
		prognosis  = Action(1, 24286),

	}

	self.healing_actions.diagnosis.potency = 400
	self.healing_actions.diagnosis.bonus   = self.healing_bonus

	self.healing_actions.prognosis.potency = 300
	self.healing_actions.prognosis.bonus   = self.healing_bonus
	self.healing_actions.prognosis.aoe     = true
	self.healing_actions.prognosis.radius  = 15

	self.menu = nil
	self.log  = nil


	self.lastAction = 0
	self.actionBeforeLast = 0
	self.lastActionCount  = 1
	self.hasEkBuff = false
	


	self.healing_manager =  LoadModule("XScripts", "/Utilities/HealingManager")

	Callbacks:Add(CALLBACK_ACTION_REQUESTED, function(actionType, actionId, targetId, result)

		if result == 1 and actionType == 1 then
			if actionId == self.lastAction then
				self.lastActionCount = self.lastActionCount + 1
			else
				self.lastActionCount = 1
			end
			self.actionBeforeLast = self.lastAction
			self.lastAction = actionId

			if self.hasEkBuff then
				self:SetLastEKAction(actionId)
				self.hasEkBuff = false
			end
		end

	end)

end


function Sage:Load(menu, log)
	
	self.log  = log
	self.menu = menu

	self.menu["ACTIONS"]["HEALER"]:subMenu("Sage", "SGE")

	self.healing_manager:Load(self.menu["ACTIONS"]["HEALER"]["SGE"])

	self.healing_manager:AddActionTable(self.healing_actions)
end

function Sage:Tick()

	-- Priority Healing
	if self.healing_manager:HealWatch() then return end

	local target = TargetManager.Target
	
	if not target.valid or target.kind ~= 2 or target.subKind ~= 5 or target.yalmX > 25 then return end

	if not self.hasEkBuff then
		self.hasEkBuff = player:hasStatus(2606)
	end

	self:Combo(target)
	
end

function Sage:Combo(target)

	if self:Weave(target) then return end

	if self:CanUseDosis(target) then
		self:UseDosis(target)
	end

end

function Sage:Weave(target)
	
	if self.lastAction == self.actions.eukrasia.id and self:CanUseEKDosis(target) then
	    self:UseEKDosis(target)
	    return true
	elseif self:LastActionIs("dosis") then
		if self:ActionBeforeLastIs("ekdosis") and self:CanUseDosis(target) then
			self:UseDosis(target)
			return true
		elseif self:ActionBeforeLastIs("dosis") and self:CanUsePhlegma(target) then
			self:UsePhlegma(target)
			return true
		elseif self.actions.eukrasia:canUse() then
			self.log:print("Using Eukrasia")
			self.actions.eukrasia:use()
			return true
		end
	elseif self:LastActionIs("ekdosis") and self:CanUseDosis(target) then
		self:UseDosis(target)
		return true
	elseif self:LastActionIs("phlegma") then
		if self.lastActionCount == 1 and self:CanUsePhlegma(target) then
			self:UsePhlegma(target)
			return true
		elseif self:CanUseDosis(target) then
			self:UseDosis(target)
			return true
		end	
	end

	return false

end

function Sage:CanUseDosis(target)
	if player.classLevel >= 82 then
		return self.actions.dosisiii:canUse(target)
	elseif player.classLevel >= 72 then
		return self.actions.dosisii:canUse(target)	
	else
		return self.actions.dosis:canUse(target)
	end
end

function Sage:UseDosis(target)
	if player.classLevel >= 82 and self.actions.dosisiii:canUse(target) then
		self.log:print("Using Dosis III on " .. target.name )
		self.actions.dosisiii:use(target)
	elseif player.classLevel >= 72 and self.actions.dosisii:canUse(target) then
		self.log:print("Using Dosis II on " .. target.name )
		self.actions.dosisii:use(target)
	elseif self.actions.dosis:canUse(target) then
		self.log:print("Using Dosis on " .. target.name )
		self.actions.dosis:use(target)
	end
end

function Sage:CanUseEKDosis(target)
	if player.classLevel >= 82 then
		return self.actions.ekdosisiii:canUse(target)
	elseif player.classLevel >= 72 then
		return self.actions.ekdosisii:canUse(target)	
	else
		return self.actions.ekdosis:canUse(target)
	end
end

function Sage:UseEKDosis(target)
	if player.classLevel >= 82 and self.actions.ekdosisiii:canUse(target) then
		self.log:print("Using Eukrasian Dosis III on " .. target.name )
		self.actions.ekdosisiii:use(target)
	elseif player.classLevel >= 72 and self.actions.ekdosisii:canUse(target) then
		self.log:print("Using Eukrasian Dosis II on " .. target.name )
		self.actions.ekdosisii:use(target)
	elseif self.actions.ekdosis:canUse(target) then
		self.log:print("Using Eukrasian Dosis on " .. target.name )
		self.actions.ekdosis:use(target)
	end
end

function Sage:CanUsePhlegma(target)
	if player.classLevel >= 82 then
		return self.actions.phlegmaiii:canUse(target)
	elseif player.classLevel >= 72 then
		return self.actions.phlegmaii:canUse(target)	
	else
		return self.actions.phlegma:canUse(target)
	end
end

function Sage:UsePhlegma(target)
	if player.classLevel >= 82 and self.actions.phlegmaiii:canUse(target) then
		self.log:print("Using Phlegma III on " .. target.name )
		self.actions.phlegmaiii:use(target)
	elseif player.classLevel >= 72 and self.actions.phlegmaii:canUse(target) then
		self.log:print("Using Phlegma II on " .. target.name )
		self.actions.phlegmaii:use(target)
	elseif self.actions.phlegma:canUse(target) then
		self.log:print("Using Phlegma on " .. target.name )
		self.actions.phlegma:use(target)
	end
end

function Sage:LastActionIs(name)
	if name == "dosis" then
		return
			self.lastAction == self.actions.dosisiii.id or
			self.lastAction == self.actions.dosisii.id or
			self.lastAction == self.actions.dosis.id
	elseif name == "ekdosis" then
		return
			self.lastAction == self.actions.ekdosisiii.id or
			self.lastAction == self.actions.ekdosisii.id or
			self.lastAction == self.actions.ekdosis.id
	elseif name == "phlegma" then
		return
			self.lastAction == self.actions.phlegmaiii.id or
			self.lastAction == self.actions.phlegmaii.id or
			self.lastAction == self.actions.phlegma.id
	end
end

function Sage:ActionBeforeLastIs(name)
	if name == "dosis" then
		return
			self.actionBeforeLast == self.actions.dosisiii.id or
			self.actionBeforeLast == self.actions.dosisii.id or
			self.actionBeforeLast == self.actions.dosis.id
	elseif name == "ekdosis" then
		return
			self.actionBeforeLast == self.actions.ekdosisiii.id or
			self.actionBeforeLast == self.actions.ekdosisii.id or
			self.actionBeforeLast == self.actions.ekdosis.id
	elseif name == "phlegma" then
		return
			self.actionBeforeLast == self.actions.phlegmaiii.id or
			self.actionBeforeLast == self.actions.phlegmaii.id or
			self.actionBeforeLast == self.actions.phlegma.id
	end
end


function Sage:SetLastEKAction(actionId)
	if actionId == self.actions.dosis then
		self.lastAction = self.actions.ekdosis
	elseif actionId == self.actions.dosisii then
		self.lastAction = self.actions.ekdosisii
	elseif actionId == self.actions.dosisiii then
		self.lastAction = self.actions.ekdosisiii
	end
end

return Sage:new()