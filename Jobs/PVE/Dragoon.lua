local Dragoon = Class("Dragoon")

function Dragoon:initialize()

	self.actions = {		

		truetrust      = Action(1, 75),
		vorpalthrust   = Action(1, 78),
		fullthrust     = Action(1, 84),
		lancecharge    = Action(1, 85),
		disembowel     = Action(1, 87),
		chaosthrust    = Action(1, 88),
		spineshatter   = Action(1, 95),
		dragonfire     = Action(1, 96),

		fangclaw       = Action(1, 3554),
		geirskogul     = Action(1, 3555),
		wheelthrust    = Action(1, 3556),
		litany         = Action(1, 3557),

		dragonsight    = Action(1, 7398),
		miragedive     = Action(1, 7399),
		nastrond       = Action(1, 7400),
		truenorth      = Action(1, 7546),

		highjump       = Action(1, 16478),
		stardiver      = Action(1, 16480),

		heavensthrust  = Action(1, 25771),
		chaoticspring  = Action(1, 25772),
		wyrmwindthrust = Action(1, 25773),
		
	}
	

	self.menu         = nil
	self.lastAction       = 0
	self.actionBeforeLast = 0
	self.actionSwitch     = nil
	
		
	Callbacks:Add(CALLBACK_ACTION_EFFECT, function(source, pos, actionId, targetId)

		if source == player and actionId ~= 7 then
			self.actionBeforeLast = self.lastAction
			self.lastAction       = actionId
		end

	end)

	self:SetActionSwitch()

end

function Dragoon:Load(mainMenu, log)
	
	self.menu = mainMenu
	self.log  = log

	self.menu["ACTIONS"]["MELEE_DPS"]:subMenu("Dragoon", "DRG")
end

function Dragoon:Tick()

	local menu       = self.menu["ACTIONS"]["MELEE_DPS"]["DRG"]
	local target     = TargetManager.Target	

	if not target.valid or target.kind ~= 2 or target.subKind ~= 5 or target.yalmX > 3 then return end

	
	switch(self.lastAction, self.actionSwitch)	

	self:Combo(target, menu)
	
end

function Dragoon:Combo(target, menu)

	if self.actions.highjump:canUse(target) then 
		self.log:print("Using High Jump on " .. target.name)
		self.actions.highjump:use(target)
	elseif self.actions.spineshatter:canUse(target) then 
		self.log:print("Using Spineshatter Dive on " .. target.name)
		self.actions.spineshatter:use(target)
	elseif self.actions.geirskogul:canUse(target) then 
		self.log:print("Using Geirskogul on " .. target.name)
		self.actions.geirskogul:use(target)
	elseif self.actions.dragonfire:canUse(target) then 
		self.log:print("Using Dragonfire Dive on " .. target.name)
		self.actions.dragonfire:use(target)
	elseif self.actions.nastrond:canUse(target) then 
		self.log:print("Using Nastrond on " .. target.name)
		self.actions.nastrond:use(target)
	elseif self.actions.stardiver:canUse(target) then 
		self.log:print("Using Stardiver on " .. target.name)
		self.actions.stardiver:use(target)
	elseif self.actions.wyrmwindthrust:canUse(target) then 
		self.log:print("Using Wyrmwind Thrust on " .. target.name)
		self.actions.wyrmwindthrust:use(target)
	elseif player:hasStatus(1863) and self.actions.truetrust:canUse(target) then
		self.log:print("Using Raiden Trust on " .. target.name)
		self.actions.truetrust:use(target)
	elseif self.actions.truetrust:canUse(target) then 
		self.log:print("Using True Trust on " .. target.name)
		self.actions.truetrust:use(target)
	end

end

function Dragoon:SetActionSwitch()
	
	self.actionSwitch = { 
		[self.actions.truetrust.id] = function()
	       	if not player:hasStatus(2720) and self.actions.disembowel:canUse(TargetManager.Target) then
        	    self.log:print("Using Disembowel on " .. TargetManager.Target.name)
				self.actions.disembowel:use(TargetManager.Target)
        	elseif self.actions.vorpalthrust:canUse(TargetManager.Target) then
        		self.log:print("Using Vorpal Trust on " .. TargetManager.Target.name)
				self.actions.vorpalthrust:use(TargetManager.Target)
			end
		end,
		[self.actions.vorpalthrust.id] = function()
	       	if player.classLevel >= 86 and self.actions.heavensthrust:canUse(TargetManager.Target.name) then
        		self.log:print("Using Heaven's Thrust on " .. TargetManager.Target.name)
				self.actions.heavensthrust:use(TargetManager.Target)
        	elseif self.actions.fullthrust:canUse(TargetManager.Target) then
        	    self.log:print("Using Full Thrust on " .. TargetManager.Target.name)
				self.actions.fullthrust:use(TargetManager.Target)        	
			end
		end,
		[self.actions.fullthrust.id] = function()
        	if self.actions.fangclaw:canUse(TargetManager.Target) then
        		if self.actions.truenorth:canUse() then
        			self.log:print("Using True North")
        			self.actions.truenorth:use()
        		end
        	    self.log:print("Using Fang and Claw on " .. TargetManager.Target.name)
				self.actions.fangclaw:use(TargetManager.Target)        	
			end
		end,
		[self.actions.disembowel.id] = function()
        	if player.classLevel >= 86 and self.actions.chaoticspring:canUse(TargetManager.Target.name) then
        		if self.actions.truenorth:canUse() then
        			self.log:print("Using True North")
        			self.actions.truenorth:use()
        		end
        		self.log:print("Using Chaotic Spring on " .. TargetManager.Target.name)
				self.actions.chaoticspring:use(TargetManager.Target)
        	elseif self.actions.chaosthrust:canUse(TargetManager.Target) then
        	    self.log:print("Using Chaos Thrust on " .. TargetManager.Target.name)
				self.actions.chaosthrust:use(TargetManager.Target)        	
			end
		end,
		[self.actions.chaosthrust.id] = function()
        	if self.actions.wheelthrust:canUse(TargetManager.Target) then
        	    self.log:print("Using Wheeling Thrust on " .. TargetManager.Target.name)
				self.actions.wheelthrust:use(TargetManager.Target)        	
			end
		end,
		[self.actions.fangclaw.id] = function()
        	if self.actions.wheelthrust:canUse(TargetManager.Target) and not player:hasStatus(1863) then
        	    self.log:print("Using Wheeling Thrust on " .. TargetManager.Target.name)
				self.actions.wheelthrust:use(TargetManager.Target)        	
			end
		end,
		[self.actions.wheelthrust.id] = function()
        	if (self.actionBeforeLast == self.actions.chaoticspring.id or self.actionBeforeLast == self.actions.chaosthrust.id) and
        		self.actions.fangclaw:canUse(TargetManager.Target.name) then
        		if self.actions.truenorth:canUse() then
        			self.log:print("Using True North")
        			self.actions.truenorth:use()
        		end
        	    self.log:print("Using Fang And Claw on " .. TargetManager.Target.name)
				self.actions.fangclaw:use(TargetManager.Target)        	
			end
		end,
		[self.actions.heavensthrust.id] = function()
        	if self.actions.fangclaw:canUse(TargetManager.Target) then
        		if self.actions.truenorth:canUse() then
        			self.log:print("Using True North")
        			self.actions.truenorth:use()
        		end
        	    self.log:print("Using Fang and Claw on " .. TargetManager.Target.name)
				self.actions.fangclaw:use(TargetManager.Target)        	
			end
		end,
		[self.actions.chaoticspring.id] = function()
        	if self.actions.wheelthrust:canUse(TargetManager.Target) then
        	    self.log:print("Using Wheeling Thrust on " .. TargetManager.Target.name)
				self.actions.wheelhrust:use(TargetManager.Target)        	
			end
		end,
	}
end

return Dragoon:new()