local Samurai = Class("Samurai")

function Samurai:initialize()

	self.actions = {
		hakaze     = Action(1, 7477),
		yukikaze   = Action(1, 7480),
		gekko      = Action(1, 7481),
		kasha      = Action(1, 7482),
		setsugekka = Action(1, 7487),
		higanbana  = Action(1, 7489),
		shinten    = Action(1, 7490),
		meikyo     = Action(1, 7499),

		midare     = Action(1, 7867),

		senei      = Action(1, 16481),
		ikishoten  = Action(1, 16482),
		tsubame    = Action(1, 16483),
		kaeshi     = Action(1, 16486),

	}

	self.menu             = nil
	self.log              = nil
	self.lastAction       = 0
	self.actionBeforeLast = 0
	self.actionSwitch     = nil


end

function Samurai:Load(mainMenu, log)
	
	self.menu = mainMenu
	self.log  = log

	self.menu["ACTIONS"]["MELEE_DPS"]:subMenu("Samurai", "SAM")
		--self.menu["ACTIONS"]["MELEE_DPS"]["SAM"]:checkbox("Use AoE Rotations", "AOE", true)
		--self.menu["ACTIONS"]["MELEE_DPS"]["SAM"]:slider("Min Enemies for AoE", "AOE_MIN", 1, 1, 3, 2)
	
	Callbacks:Add(CALLBACK_ACTION_EFFECT, function(source, pos, actionId, targetId)

		if source == player and actionId ~= 7 then
			self.actionBeforeLast = self.lastAction
			self.lastAction       = actionId
		end

	end)


	self:SetActionSwitch()
end

function Samurai:Tick()

	local target = TargetManager.Target
	local menu   = self.menu["ACTIONS"]["MELEE_DPS"]["SAM"]

	if not target.valid or target.kind ~= 2 or target.subKind ~= 5 or target.yalmX > 3 then return end

	local mei = player:getStatus(1233)

	switch(self.lastAction, self.actionSwitch)

	if self.actions.meikyo:canUse() then
		self.log:print("Using Meikyo Shisui")
		self.actions.meikyo:use()
	elseif self.actions.senei:canUse(target) then
		self.log:print("Using Hissatsu: Senei on " .. target.name )
	    self.actions.senei:use(target)
	elseif self.actions.shinten:canUse(target) then
		self.log:print("Using Hissatsu: Shinten on " .. target.name)
		self.actions.shinten:use(TargetManager.Target)
	elseif self.actions.gekko:canUse(target) then
		self.log:print("Using Gekko on " .. target.name)
		self.actions.gekko:use(target)
	end

end

function Samurai:SetActionSwitch()
	
	self.actionSwitch = { 
        [0] = function()
        	if self.actions.meikyo:canUse() then
				self.log:print("Using Meikyo Shisui")
				self.actions.meikyo:use()
				--self.log:print("1-0")
			end
		end,
		[self.actions.yukikaze.id] = function()
			if self.actions.midare:canUse(TargetManager.Target) then
				self.log:print("Using Midare Setsugekka on " .. TargetManager.Target.name )
				--self.log:print("4-0")
				self.actions.midare:use(TargetManager.Target)
			end
		end,		
		[self.actions.gekko.id] = function()
			if self.actionBeforeLast == self.actions.kaeshi.id and self.actions.shinten:canUse(TargetManager.Target) then
				self.log:print("Using Hissatsu: Shinten on " .. TargetManager.Target.name)
				--self.log:print("6-1")
				self.actions.shinten:use(TargetManager.Target)
			elseif self.actions.kasha:canUse(TargetManager.Target) then
				self.log:print("Using Kasha on " .. TargetManager.Target.name )
				--self.log:print("2-0")
				self.actions.kasha:use(TargetManager.Target)
			end
		end,
		[self.actions.kasha.id] = function()
			if self.actions.ikishoten:canUse() then
				self.log:print("Using Ikishoten")
				--self.log:print("2-1")
				self.actions.ikishoten:use()
			end
		end,
		[self.actions.setsugekka.id] = function()
			if self.actions.senei:canUse(TargetManager.Target) then
				self.log:print("Using Hissatsu: Senei on " .. TargetManager.Target.name )
				self.actions.senei:use(TargetManager.Target)
			end
		end,
		[self.actions.higanbana.id] = function()
			if self.actions.shinten:canUse(TargetManager.Target) then
				self.log:print("Using Hissatsu: Shinten on " .. TargetManager.Target.name)
				self.actions.shinten:use(TargetManager.Target)
			end
		end,
		[self.actions.shinten.id] = function()
			self.log:print("Shinten Switch")
			if self.actions.higanbana:canUse(TargetManager.Target) then
				self.log:print("Using Higanbana on " .. TargetManager.Target.name )
				--self.log:print("7-0")
				self.actions.higanbana:use(TargetManager.Target)
			end
		end,
		[self.actions.meikyo.id] = function()
			if self.actions.gekko:canUse(TargetManager.Target) then
				self.log:print("Using Gekko on " .. TargetManager.Target.name )
				--self.log:print("2-0")
				self.actions.gekko:use(TargetManager.Target)
			end
		end,
		[self.actions.midare.id] = function()
			if self.actions.senei:canUse(TargetManager.Target) then
				self.log:print("Using Hissatsu: Senei on " .. TargetManager.Target.name )
				--self.log:print("4-1")
				self.actions.senei:use(TargetManager.Target)
			end
		end,
		[self.actions.senei.id] = function()
			if self.actions.kaeshi:canUse(TargetManager.Target) then
				self.log:print("Using Kaeshi: Setsugekka on " .. TargetManager.Target.name)
				--self.log:print("5-0")
				self.actions.kaeshi:use(TargetManager.Target)
			end
		end,
		[self.actions.ikishoten.id] = function()
			if self.actions.yukikaze:canUse(TargetManager.Target) then
				self.log:print("Using Yukikaze on " .. TargetManager.Target.name)
				--self.log:print("3-0")
				self.actions.yukikaze:use(TargetManager.Target)
			end
		end,
		[self.actions.kaeshi.id] = function()
			if self.actions.meikyo:canUse() then
				self.log:print("Using Meikyo Shisui")
				--self.log:print("5-1")
				self.actions.meikyo:use()
			elseif self.actions.gekko:canUse(TargetManager.Target) then
				self.log:print("Using Gekko on " .. TargetManager.Target.name)
				--self.log:print("6-0")
				self.actions.gekko:use(TargetManager.Target)
			end
		end,		
	}
end


return Samurai:new()