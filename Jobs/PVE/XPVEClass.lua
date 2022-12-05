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
	self.class_menu         = nil
	
	self.pre_pulling        = false
	self.pre_pull_done      = false

	-- Rotations
	self.current_rotation    = 0
	self.last_rotation       = 0
	self.last_burst_rotation = nil
	self.rotations           = {}
	self.skip_step           = false

	-- Target Information
	self.target             = nil
	self.last_target_time   = 0

	-- Actions Table
	self.actions                   = {}
	
	-- Action Variables
	self.last_action         = 0
	self.action_before_last  = 0

	-- Loads Log
	self.log = LoadModule("XScriptsT", "\\Utilities\\Log")

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

	        if self.skip_step then
	        	self.skip_step = false
	        	return
	        end

	        for i, rotation in ipairs(self.rotations) do
	        	if rotation.using then
	        		rotation.step = rotation.step + 1
	        		--print("Changing " .. rotation.name .. " Step to " .. tostring(rotation.step))
	        		switch(rotation.step, rotation.switch)
	        	end

	        end
		end
    end)
end

function XPVEClass:AddRotation(
	rotation_name, rotation_actions, auto_continue)
	
	local index = #self.rotations + 1

	table.insert(
		self.rotations,
		{ 
			name    = rotation_name,
			step    = 1,
			index   = index,
			using   = false,
			switch  = self:GetSwitchTable(rotation_actions, auto_continue),
			can_use = function ()
				return self.class_menu["ROTATIONS"][rotation_name].bool
			end,
			equals = function(rotation) 
				return rotation.index == index 
			end
		}
	)
end

function XPVEClass:GetSwitchTable(actions, auto_continue)
	
	local switch_table = {}
	local max          = #actions

	for i = 1, #actions do
		local action_name  = actions[i]
		local action       = self.actions[action_name]

		if action then

			local rotation_index = #self.rotations + 1

			local execute_func = self:GetExecuteFunc(
				action, i, max, rotation_index, auto_continue
			)

			switch_table[i] = execute_func

		end

	end

	return switch_table

end

function XPVEClass:GetExecuteFunc(action, step, max, rotation_index, auto_continue)
	local target = action.canTargetEnemy and self.target or nil

	return function()

		if player.isCasting then return end

		if step == 1 then
			self.last_rotation    = self.current_rotation
			self.current_rotation = rotation_index
		end

		if action:canUse(self.target) then			
			action:use(self.target)
			self.log:print(
				"Using " .. ((target == nil and action.name) 
				or (action.name .. " on " .. target.name))
			)
			self.log:print( self.rotations[rotation_index].name .. " Step " .. tostring(step))

			if step == max then

				self.rotations[rotation_index].using = false
				self.rotations[rotation_index].step  = 1
				
				print("Finished " .. self.rotations[rotation_index].name .. " Phase")

				self.skip_step        = true
				self.current_rotation = 0
			end
		elseif player.classLevel < action.level and auto_continue then
			self.rotations[rotation_index].step  = self.rotations[rotation_index].step  + 1
		end
	end
end

function XPVEClass:Load(main_module)
	self.menu        = main_module.menu

	self.menu["ACTIONS"][self.class_category]:subMenu(self.class_name, self.class_name_short)

	self.class_menu = self.menu["ACTIONS"][self.class_category][self.class_name_short]

	if #self.rotations > 0 then
		self.class_menu:subMenu("Rotations", "ROTATIONS")

		for i, rotation in ipairs(self.rotations) do
			self.class_menu["ROTATIONS"]:checkbox("Use " .. rotation.name, rotation.name, true)
		end

	end
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