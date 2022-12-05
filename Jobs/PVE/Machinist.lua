local Machinist = Class("Machinist")

function Machinist:initialize()

	self.actions = {

		splitshot   = Action(1, 2866),
		slugshot    = Action(1, 2868),
		hotshot     = Action(1, 2872),
		cleanshot   = Action(1, 2873),
		gauss       = Action(1, 2874),
		reassemble  = Action(1, 2876),
		hypercharge = Action(1, 17209),
		heatblast   = Action(1, 7410),
		wildfire    = Action(1, 2878),
		ricochet    = Action(1, 2890),
		heatedsplit = Action(1, 7411),
		drill       = Action(1, 16498),
		heatedslug  = Action(1, 7412),
		heatedclean = Action(1, 7413),
		barrel      = Action(1, 7414),
		airanchor   = Action(1, 16500),
		automaton   = Action(1, 16501),
		chainsaw    = Action(1, 25788),

		
		-- Role
		secondwind = Action(1, 7541),
		headgrace  = Action(1, 7551),
		footgrace  = Action(1, 7553),
		leggrace   = Action(1, 7554),
		peloton    = Action(1, 7557),
	}

	self.lastAction      = 0
	self.lastWeaveAction = 0
	self.lastComboAction = 0

	Callbacks:Add(CALLBACK_ACTION_REQUESTED, function(actionType, actionId, targetId, result)

		if result == 1 and actionType == 1 then
			self.lastAction = actionId
		end

	end)
end

function Machinist:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["RANGE_DPS_P"]:subMenu("Machinist", "MCH")
		self.menu["ACTIONS"]["RANGE_DPS_P"]["MCH"]:checkbox("Auto Pick Rotation", "AUTO_ROTATION", true)
		self.menu["ACTIONS"]["RANGE_DPS_P"]["MCH"]:combobox("Rotations", "ROTATIONS", {"Lvl 40", "Lvl 90"})
		
end



function Machinist:Tick()

	local menu        = self.menu["ACTIONS"]["RANGE_DPS_P"]["MCH"]
	local actions     = self.actions

	local target = TargetManager.Target

	if not target.valid or target.kind ~= 2 or target.subKind ~= 5 or target.pos:dist(player.pos) >= 25 then return end

	if player.healthPercent < 20 and self.actions.secondwind:canUse() then
		self.actions.secondwind:use()
	end

	self:MaxCombo(target)	

end

function Machinist:MaxCombo(target)
	
	if self:HandleWeave(target) then return end

	-- Opener
		-- Reassemble
	if self.actions.reassemble:canUse() then
		self.actions.reassemble:use()
		-- Air Anchor
	elseif self.actions.airanchor:canUse(target) and self.lastAction == self.actions.reassemble.id and 
		self.lastComboAction ~= self.actions.heatedclean.id then
	    self.actions.airanchor:use(target)
		-- Drill
	elseif self.actions.drill:canUse(target) and self.lastAction == self.actions.ricochet.id and player.gauge.heat < 50 then
	    self.actions.drill:use(target)
		-- Heated Split Shot
	elseif self.actions.heatedsplit:canUse(target) and self.lastAction == self.actions.barrel.id then
	    self.actions.heatedsplit:use(target)
	    self.lastComboAction = self.actions.heatedsplit.id
		-- Heated Slug Shot
	elseif self.actions.heatedslug:canUse(target) and self.lastAction == self.actions.heatedsplit.id then
	    self.actions.heatedslug:use(target)
	    self.lastComboAction = self.actions.heatedslug.id
		-- Heated Clean Shot
	elseif self.actions.heatedclean:canUse(target) and self.lastComboAction == self.actions.heatedslug.id then
	    self.actions.heatedclean:use(target)
	    self.lastComboAction = self.actions.heatedclean.id
		-- Chain Saw
	elseif self.actions.chainsaw:canUse(target) and self.lastAction == self.actions.wildfire.id then
	    self.actions.chainsaw:use(target)
	    self.lastComboAction = self.actions.chainsaw.id
	end


	-- Low Level Combo

	if player.gauge.overHeatTime == 0 and self.actions.hypercharge:canUse() then
		self.actions.hypercharge:use()
	elseif self.actions.heatblast:canUse(target) then
		self.actions.heatblast:use(target)	
	elseif self.actions.gauss:canUse(target) and self.lastAction ~= self.actions.gauss.id then
		self.actions.gauss:use(target)
	elseif self.actions.reassemble:canUse() then
		self.actions.reassemble:use()
	elseif self.actions.hotshot:canUse(target) then
		self.actions.hotshot:use(target)
	elseif self.lastAction == self.actions.slugshot.id and self.actions.cleanshot:canUse(target) then
		self.actions.cleanshot:use(target)
	elseif self.lastAction == self.actions.splitshot.id and self.actions.slugshot:canUse(target) then
		self.actions.slugshot:use(target)
	elseif self.actions.splitshot:canUse(target) and not self.comboReady then
		self.actions.splitshot:use(target)
	end


end

function Machinist:HandleWeave(target)
	
	-- Can We Overheat?
	if player.gauge.heat >= 50 and player.gauge.battery >= 50 and self.actions.automaton:canUse() then
		self.actions.automaton:use()
		return true
	elseif player.gauge.heat >= 50 and self.actions.hypercharge:canUse() then
		self.actions.hypercharge:use()
		return true
	end

	-- Not Overheated
	if player.gauge.overHeatTime == 0 then

		if self.actions.gauss:canUse(target) and (self.lastAction == self.actions.airanchor.id or self.lastAction == self.actions.heatedslug.id) then
			self.actions.gauss:use(target)
			return true
		elseif self.actions.ricochet:canUse(target) and self.lastAction == self.actions.gauss.id then
			self.actions.ricochet:use(target)
			return true
		elseif self.actions.barrel:canUse() and self.lastAction == self.actions.drill.id then
			self.actions.barrel:use()
			return true
		elseif self.actions.wildfire:canUse(target) and self.lastAction == self.actions.reassemble.id and
		 self.lastComboAction == self.actions.heatedclean.id then
			self.actions.wildfire:use(target)
			return true
		end
	else

		if self.actions.heatblast:canUse(target) and self.lastAction ~= self.actions.heatblast.id then
			self.actions.heatblast:use(target)
			return true
		elseif self.actions.ricochet:canUse(target) and self.lastAction == self.actions.heatblast.id 
			and self.lastWeaveAction ~= self.actions.ricochet.id then
			self.actions.ricochet:use(target)
			self.lastWeaveAction = self.actions.ricochet.id
			return true
		elseif self.actions.gauss:canUse(target) and self.lastAction == self.actions.heatblast.id 
			and self.lastWeaveAction ~= self.actions.gauss.id then
			self.actions.gauss:use(target)
			self.lastWeaveAction = self.actions.gauss.id
			return true
		end

	end

	return false

end

return Machinist:new()