local XPVEClass = LoadModule("XScripts", "\\Jobs\\PVE\\XPVEClass")
local Dancer    = Class("Dancer", XPVEClass)

function Dancer:initialize()

	XPVEClass.initialize(self)

	self.class_name           = "Dancer"
	self.class_name_short     = "DNC"
	self.class_category       = "RANGE_DPS_P"
	self.class_range          = 25

	self.actions = {
		
		cascade          = Action(1, 15989),
		fountain         = Action(1, 15990),
		reverse_cascade  = Action(1, 15991),
		fountainfall     = Action(1, 15992),
		rising_windmill  = Action(1, 15995),
		bloodshower      = Action(1, 15996),
		standard_step    = Action(1, 15997),
		technical_step   = Action(1, 15998),
		emboite          = Action(1, 15999),
		entrechat        = Action(1, 16000),
		jete             = Action(1, 16001),
		pirouette        = Action(1, 16002),
		standard_finish  = Action(1, 16003),
		technical_finish = Action(1, 16004),
		saber_dance      = Action(1, 16005),
		fan_dance        = Action(1, 16007),
		fan_dance_ii     = Action(1, 16008),
		fan_dance_iii    = Action(1, 16009),

		devilment        = Action(1, 16011),
		flourish         = Action(1, 16013),

		tillana          = Action(1, 25790),
		fan_dance_iv     = Action(1, 25791),
		starfall_dance   = Action(1, 25792),
	}

	self.last_dance_combo = 2

	-- helper functions
	self.has_standard_step    = function() return player:hasStatus(1818) end
	self.has_technical_step   = function() return player:hasStatus(1819) end
	self.has_devilment        = function() return player:hasStatus(1825) end
	self.has_silken_symmetry  = function() return player:hasStatus(2693) end
	self.has_silken_flow      = function() return player:hasStatus(2694) end

	self:SetStepSwitch()

	Callbacks:Add(CALLBACK_ACTION_EFFECT, function(source, pos, action_id, target_id)
		if source.id == player.id then
	  		if action_id == self.actions.cascade.id then
	  			self.last_dance_combo = 1
	  		elseif action_id == self.actions.fountain.id then
	  			self.last_dance_combo  = 2
	  		end
		end  
	end)
end

function Dancer:Tick()

	XPVEClass.Tick(self)

	local target = self.get_target()
	if not self:ValidTarget(target) then return end

	local aoe = ObjectManager.BattleEnemiesAroundObject(target, 5, function(o) return o.isTargetable end) >= 2	

	if self.has_standard_step() or self.has_technical_step() then
		return switch(player.gauge.currentStep, self.step_switch)
	end

	if self.actions.standard_step:canUse() then
		self.log:print("Using Standard Step")
		self.actions.standard_step:use()
	elseif self.actions.technical_step:canUse() then
		self.log:print("Using Technical Step")
		self.actions.technical_step:use()
	elseif not self.has_devilment() and self.actions.devilment:canUse() then
		self.log:print("Using Devilent")
		self.actions.devilment:use()
	end
	if self.has_silken_symmetry() then
		return self:HandleSilkenSymmetry(target, aoe)
	end
	if self.has_silken_flow() then
		return self:HandleSilkenFlow(target, aoe)
	end
	if self.actions.starfall_dance:canUse(target) then
		self.log:print("Using Starfalll Dance on : " .. target.name)
		self.actions.starfall_dance:use(target)
	end
	if self.actions.flourish:canUse() then
		self.log:print("Using Flourish")
		self.actions.flourish:use()
	end
	if self:CanUseFanDance(target, aoe) then
		self:UseFanDance(target, aoe)
	end
	if self.actions.tillana:canUse() then
		self.log:print("Using Tillana")
		self.actions.tillana:use()
	end
	if self.actions.fan_dance_iv:canUse(target) then
		self.log:print("Using Fan Dance IV on : " .. target.name)
		self.actions.fan_dance_iv:use(target)
	end

	if self.last_dance_combo == 1 and self.actions.fountain:canUse(target) then
		self.log:print("Using Fountain on : " .. target.name)
		self.actions.fountain:use(target)
	elseif self.actions.cascade:canUse(target) then
		self.log:print("Using Cascade on : " .. target.name)
		self.actions.cascade:use(target)
	end
end

function Dancer:HandleSilkenFlow(target, aoe)
	if aoe and target.pos:dist(player.pos) < 5 then
		if self.actions.bloodshower:canUse(target) then
			self.log:print("Using Bloodshower on : " .. target.name)
			self.actions.bloodshower:use(target)
		end
	elseif self.actions.fountainfall:canUse(target) then
		self.log:print("Using Fountainfall on : " .. target.name)
		self.actions.fountainfall:use(target)
	end
end

function Dancer:HandleSilkenSymmetry(target, aoe)
	if aoe and target.pos:dist(player.pos) < 5 then
		if self.actions.rising_windmill:canUse(target) then
			self.log:print("Using Rising Windmill on : " .. target.name)
			self.actions.rising_windmill:use(target)
		end
	elseif self.actions.reverse_cascade:canUse(target) then
		self.log:print("Using Reverse Cascade on : " .. target.name)
		self.actions.reverse_cascade:use(target)
	end
end

function Dancer:UseFanDance(target, aoe)

	if player.classLevel >= 66 then
		self.log:print("Using Fan Dance III")
		self.actions.fan_dance_iii:use(target)
	elseif aoe and target.pos:dist(player.pos) < 5 and player.classLevel >= 50 then
		self.log:print("Using Fan Dance II")
		self.actions.fan_dance_ii:use(target)
	elseif player.classLevel >= 30 then
		self.log:print("Using Fan Dance")
		self.actions.fan_dance:use(target)
	end

end

function Dancer:CanUseFanDance(target)

	if player.classLevel >= 66 then
		return self.actions.fan_dance_iii:canUse(target)
	elseif aoe and target.pos:dist(player.pos) < 5 and player.classLevel >= 50 then
		return self.actions.fan_dance_ii:canUse(target)
	elseif player.classLevel >= 30 then
		return self.actions.fan_dance:canUse(target)
	end

	return false
end

function Dancer:SetStepSwitch()

	self.step_switch =
	{
		[0] = function()
			-- Standard Finish
			if self.has_standard_step() then
				if self.actions.standard_finish:canUse() then
					self.log:print("Using Standard Finish")
					self.actions.standard_finish:use()
				end
			elseif self.has_technical_step() then
				if self.actions.technical_finish:canUse() then
					self.log:print("Using Technical Finish")
					self.actions.technical_finish:use()
				end
			end
		end,
		[1] = function()
			if self.actions.emboite:canUse() then
				self.log:print("Using Emboite")
				self.actions.emboite:use()
			end
		end,
		[2] = function()
			if self.actions.entrechat:canUse() then
				self.log:print("Using Entrechat")
				self.actions.entrechat:use()
			end
		end,
		[3] = function()
			if self.actions.jete:canUse() then
				self.log:print("Using Jete")
				self.actions.jete:use()
			end
		end,
		[4] = function()
			if self.actions.pirouette:canUse() then
				self.log:print("Using Pirouette")
				self.actions.pirouette:use()
			end
		end,
	}

end

return Dancer:new()