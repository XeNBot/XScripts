local Monk = Class("Monk")

function Monk:initialize()

	self.actions = {	
	}

	self.menu             = nil
	self.log              = nil
	self.lastAction       = 0
	self.actionBeforeLast = 0
	self.actionSwitch     = nil


end

function Monk:Load(mainMenu, log)
	
	self.menu = mainMenu
	self.log  = log

	self.menu["ACTIONS"]["MELEE_DPS"]:subMenu("Monk", "MNK")
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

function Monk:Tick()

	local target = TargetManager.Target
	local menu   = self.menu["ACTIONS"]["MELEE_DPS"]["MNK"]

	if not target.valid or target.kind ~= 2 or target.subKind ~= 5 or target.yalmX > 3 then return end

	local mei = player:getStatus(1233)

	switch(self.lastAction, self.actionSwitch)

	if self.actions.meikyo:canUse() then
	
end

function Monk:SetActionSwitch()
	
	self.actionSwitch = { 
        [0] = function()
        	if true then
        		
        	end
		end				
	}
end


return Monk:new()