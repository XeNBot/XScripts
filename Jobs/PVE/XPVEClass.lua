local XPVEClass = Class("XPVEClass")

function XPVEClass:initialize()

	-- Main Module
	self.main_module        = nil

	-- PVE Variables
	self.class_name         = "PvE Class"
	self.class_name_short   = "PVE"
	self.class_category     = "PVE_CLASS"
	self.class_range        = 3
	self.menu               = nil
	
	self.using_opener       = false
	self.using_combo        = false
	self.using_cd_phase     = false
	self.using_odd_burst    = false

	-- Target Information
	self.target             = nil
	self.last_target_time   = 0

	-- Actions Table
	self.actions                   = {}
	self.action_switch             = {}
	self.use_action_switch         = false

	-- Opener Variables
	self.pre_pulling               = false
	self.pre_pull_done             = false
	self.opener_step               = 1
	self.opener_switch             = {}
	self.opener_done               = false
	self.use_opener_switch         = false

	-- Cooldown Phase Variables
	self.cd_phase            = false
	self.cd_phase_done       = false
	self.cd_phase_step       = 1
	self.cd_phase_switch     = {}
	self.use_cd_phase_switch = false

	-- Odd Burst Variables
	self.odd_burst_phase      = false
	self.odd_burst_done       = false
	self.odd_burst_step       = 1
	self.odd_burst_switch     = {}
	self.use_odd_burst_switch = false


	-- Action Variables
	self.last_action         = 0
	self.action_before_last  = 0

	-- Loads Log
	self.log = LoadModule("XScripts", "\\Utilities\\Log")

	-- Functions Quick Calls
	-- Objects Around
	self.objects_around = function (target, range) return ObjectManager.BattleEnemiesAroundObject(target, range) end
	-- TargetManager.Target
	self.get_target = function() return TargetManager.Target end


	Callbacks:Add(CALLBACK_ACTION_EFFECT, function(source, pos, action_id, target_id)
		if source.id == player.id and action_id ~= 7 and action_id ~= 8 then
			self.action_before_last = self.last_action
	        self.last_action        = action_id

	        if self.use_action_switch then
	        	switch(action_id, self.action_switch)
	        end

	        if self.using_opener and self.use_opener_switch then
	        	self.opener_step = self.opener_step + 1
	        	--print("Changing Step to : " .. tostring(self.opener_step))
	        	switch(self.opener_step, self.opener_switch)
	        elseif self.using_cd_phase and self.use_cd_phase_switch then
	        	self.cd_phase_step = self.cd_phase_step + 1
	        	--print("Changing CD Phase Step to : " .. tostring(self.cd_phase_step))
	        	switch(self.cd_phase_step, self.cd_phase_switch)
	        elseif self.using_odd_burst and self.use_odd_burst_switch then
	        	self.odd_burst_step = self.odd_burst_step + 1
	        	--print("Changing CD Phase Step to : " .. tostring(self.cd_phase_step))
	        	switch(self.odd_burst_step, self.odd_burst_switch)
	        end	        

		end
    end)
end

function XPVEClass:SetOpener(tbl)

	local opener_size  = #tbl
	self.opener_switch = {}

	for i = 1, #tbl do

		local action_name  = tbl[i]
		local action       = self.actions[action_name]

		if action then

			local execute_func = self:GetOpenerExecFunc(self.actions[action_name], i)

			self.opener_switch[i] = execute_func
		else
			print("Error Adding Action to Opener!")
		end
	end

end

function XPVEClass:SetCooldownPhase(tbl)

	local max = #tbl
	
	self.cd_phase_switch = {}	

	for i = 1, max do

		local action_name  = tbl[i]
		local action       = self.actions[action_name]

		if action then

			local execute_func = self:GetCooldownPhaseExecFunc(self.actions[action_name], i, max)

			self.cd_phase_switch[i] = execute_func


		else
			print("Error Adding Action to CD Phase!")
		end
	end

end

function XPVEClass:SetOddBurst(tbl)

	local max = #tbl
	
	self.odd_burst_switch = {}	

	for i = 1, max do

		local action_name  = tbl[i]
		local action       = self.actions[action_name]

		if action then

			local execute_func = self:GetOddBurstPhaseExecFunc(self.actions[action_name], i, max)

			self.odd_burst_switch[i] = execute_func


		else
			print("Error Adding Action to Odd Burst Phase!")
		end
	end

end

function XPVEClass:GetOddBurstPhaseExecFunc(action, step, max)

	local target = action.canTargetEnemy and self.target or nil

	return function()
		if action:canUse(self.target) then			
			action:use(self.target)
			self.log:print(
				"Using " .. ((target == nil and action.name) 
				or (action.name .. " on " .. target.name))
			)
			self.log:print("Odd Burst Step " .. tostring(step))

			if step == max then
				self.using_odd_burst = false
				self.odd_burst_step  = 1
				self.odd_burst_done  = true

				print("Finished Odd Burst Phase")
			end
		end
	end
end

function XPVEClass:GetCooldownPhaseExecFunc(action, step, max)

	local target = action.canTargetEnemy and self.target or nil

	return function()
		if action:canUse(self.target) then			
			action:use(self.target)
			self.log:print(
				"Using " .. ((target == nil and action.name) 
				or (action.name .. " on " .. target.name))
			)
			self.log:print("CD Phase Step " .. tostring(step))

			if step == max then
				self.using_cd_phase = false
				self.cd_phase_step  = 1
				self.cd_phase_done  = true

				print("Finished CD Phase")
			end
		end
	end
end

function XPVEClass:GetOpenerExecFunc(action, step, max)

	local target = action.canTargetEnemy and self.target or nil

	return function()
		if action:canUse(self.target) then			
			action:use(self.target)
			self.log:print(
				"Using " .. ((target == nil and action.name) 
				or (action.name .. " on " .. target.name))
			)
			self.log:print("Opener Step " .. tostring(step))

			if step == max then
				self.using_opener = false
				self.opener_step  = 1
				self.opener_done  = true
			end
		end
	end
end

function XPVEClass:Load(main_module)
	self.menu        = main_module.menu

	self.menu["ACTIONS"][self.class_category]:subMenu(self.class_name, self.class_name_short)
end

function XPVEClass:Tick()

	if self:ValidTarget() then
		self.target = TargetManager.Target
		self.last_target_time = os.clock()
	end
	
end

function XPVEClass:AddActionTable(tbl)

	for name, info in pairs(tbl) do
		if self.actions[name] == nil then
			self.actions[name] = info
		end
	end

end

function XPVEClass:ValidTarget(target, dist)
	-- If no target is given uses Target Manager's target
	if target == nil then
		target = self.get_target()
	end
	-- If no distance is given uses default class range
	if dist == nil then
		dist = self.class_range
	end

	return  target.valid and target.kind == 2 and target.subKind == 5 and target.yalmX < dist
end

return XPVEClass