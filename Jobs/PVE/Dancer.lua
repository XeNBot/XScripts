local XPVEClass = LoadModule("XScripts", "\\Jobs\\PVE\\XPVEClass")
local Dancer    = Class("Dancer", XPVEClass)

function Dancer:initialize()

	XPVEClass.initialize(self)

	self:SetClassIds({38})
	self:LoadWidget("Dancer XPVE")
	self:LoadRoleMenu()
	self:LoadWidgetCombo()
	self:LoadWidgetAoE()
			
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
end

function Dancer:ActionEffect(source, pos, action_id, target_id)

	if source.id == player.id then
		if action_id == self.actions.cascade.id then
			self.last_dance_combo = 1
		elseif action_id == self.actions.fountain.id then
			self.last_dance_combo  = 2
		end
	end

end

function Dancer:Tick()

	XPVEClass.Tick(self)

	local target = self.get_target()
	if not self:ValidTarget(target) then return end

	if self.has_standard_step() or self.has_technical_step() then
		return switch(player.gauge.currentStep, self.step_switch)
	end

	if self:CanUse("standard_step") then
		self:Use("standard_step")
	elseif self:CanUse("technical_step") then
		self:Use("technical_step")
	elseif not self.has_devilment() and self:CanUse("devilment") then
		self:Use("devilment")
	end
	if self.has_silken_symmetry() then
		return self:HandleSilkenSymmetry(target)
	end
	if self.has_silken_flow() then
		return self:HandleSilkenFlow(target)
	end
	if self:CanUse("starfall_dance", target) then
		self:Use("starfall_dance", target)
	end
	if self:CanUse("flourish") then
		self:Use("flourish")
	end
	if self:CanUseFanDance(target) then
		self:UseFanDance(target)
	end
	if self:CanUse("tillana") then
		self:Use("tillana")
	end
	if self:CanUse("fan_dance_iv", target) then
		self:Use("fan_dance_iv", target)
	end
	if self.last_dance_combo == 1 and self:CanUse("fountain", target) then
		self:Use("fountain", target)
	elseif self:CanUse("cascade", target) then
		self:Use("cascade", target)
	end
end

function Dancer:HandleSilkenFlow(target)
	if self.aoe and target.pos:dist(player.pos) < 5 then
		if self:CanUse("bloodshower", target) then
			self:Use("bloodshower", target)
		end
	elseif self.actions.fountainfall:canUse(target) then
		self:Use("fountainfall", target)
	end
end

function Dancer:HandleSilkenSymmetry(target)
	if self.aoe and target.pos:dist(player.pos) < 5 and self:CanUse("rising_windmill", target) then
		self:Use("rising_windmill", target)
	elseif self:CanUse("reverse_cascade", target) then
		self:Use("reverse_cascade", target)
	end
end

function Dancer:UseFanDance(target)

	if player.classLevel >= 66 then
		self:Use("fan_dance_iii", target)
	elseif self.aoe and target.pos:dist(player.pos) < 5 and player.classLevel >= 50 then
		self:Use("fan_dance_ii", target)
	elseif player.classLevel >= 30 then
		self:Use("fan_dance", target)
	end

end

function Dancer:CanUseFanDance(target)

	if player.classLevel >= 66 then
		return self:CanUse("fan_dance_iii", target)
	elseif self.aoe and target.pos:dist(player.pos) < 5 and player.classLevel >= 50 then
		return self:CanUse("fan_dance_ii", target)
	elseif player.classLevel >= 30 then
		return self:CanUse("fan_dance", target)
	end

	return false
end

function Dancer:SetStepSwitch()

	self.step_switch =
	{
		[0] = function()
			-- Standard Finish
			if self.has_standard_step() and self:CanUse("standard_finish") then
				self:Use("standard_finish")
			elseif self.has_technical_step() and self:CanUse("technical_finish") then
				self:CanUse("technical_finish")
			end
		end,
		[1] = function()
			if self:CanUse("emboite") then
				self:Use("emboite")
			end
		end,
		[2] = function()
			if self:CanUse("entrechat") then
				self:Use("entrechat")
			end
		end,
		[3] = function()
			if self:CanUse("jete") then
				self:Use("jete")
			end
		end,
		[4] = function()
			if self:CanUse("pirouette") then
				self:Use("pirouette")
			end
		end,
	}

end

return Dancer:new()