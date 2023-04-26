local XPVEClass = Class("XPVEClass")

function XPVEClass:initialize()

	-- Main Module
	self.main_module        = nil

	-- PVE Variables
	self.class_name          = "PvE Class"
	self.class_name_short    = "PVE"
	self.class_category      = "PVE_CLASS"
	self.class_range         = 3

	-- Class Information Variables
	self.role_module         = nil
	self.class_ids           = {}

	self.is_melee_dps        = false
	self.is_ranged_dps       = false
	self.is_tank             = false


	self.menu                = nil
	self.class_menu          = nil
	self.class_widget        = nil

	-- AoE Widget Variables
	self.aoe_min             = 0
	self.aoe_on              = false
	self.loaded_aoe          = false
	self.aoe                 = false


	self.pre_pulling         = false
	self.pre_pull_done       = false

	-- Rotations
	self.current_rotation    = 0
	self.last_rotation       = 0
	self.last_burst_rotation = nil
	self.rotations           = {}
	self.skip_step           = false

	-- Target Information
	self.target              = nil
	self.last_target_time    = 0

	-- Actions Table
	self.actions             = {}

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

	-- Extra Callbacks
	self.EXTRA_ACTION_EFFECT = nil


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
	        		switch(rotation.step, rotation.switch)
	        	end
	        end
		end

		self:ActionEffect(source, pos, action_id, target_id)
    end)

	Callbacks:Add(CALLBACK_PLAYER_TICK, function() self:Ticker() end)
end

function XPVEClass:ActionEffect(source, pos, action_id, target_id) end

function XPVEClass:SetClassIds(tbl)

	for i, c in ipairs(tbl) do
		self.class_ids[c] = true
		if Game.IsMeleeDPS(c) then
			self.is_melee_dps = true
		elseif Game.IsRangedDPS(c) then
			self.is_ranged_dps = true
		elseif Game.IsTank(c) then
			self.is_tank = true
		end
	end

end

function XPVEClass:LoadWidget(name)

	self.class_widget         = Menu(name , true)
	self.class_widget.width   = 250
	self.class_widget.visible = player ~= nil and self.class_ids[player.classJob] ~= nil

end

function XPVEClass:LoadWidgetCombo()

	self.class_widget:subMenu("Combo Settings", "COMBO_SETTINGS")
	self.class_widget["COMBO_SETTINGS"]:setIcon("XScriptsT", "\\Resources\\Icons\\Misc\\Stance.png")

end

function XPVEClass:LoadWidgetAoE()

	self.class_widget["COMBO_SETTINGS"]:checkbox("Use AoE Rotations", "AOE", true)
	self.class_widget["COMBO_SETTINGS"]:slider("Min Enemies for AoE", "AOE_MIN", 1, 1, 5, 2)

end

function XPVEClass:LoadRoleMenu()

	if self.is_melee_dps then
		self.role_module = LoadModule("XScriptsT", "\\Jobs\\PVE\\Roles\\MeleeDPS")
    	self.role_module:load(self.class_widget)
	elseif self.is_ranged_dps then
		self.role_module = LoadModule("XScriptsT", "\\Jobs\\PVE\\Roles\\RangedDPS")
    	self.role_module:load(self.class_widget)
	elseif self.is_tank then
		self.role_module = LoadModule("XScriptsT", "\\Jobs\\PVE\\Roles\\Tank")
    	self.role_module:load(self.class_widget)
	end

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

	for i = 1, max do
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

		if target ~= nil and action:canUse(target) then
			action:use(target)
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
		elseif player.classLevel < action.level then
			self.rotations[rotation_index].step  = self.rotations[rotation_index].step  + 1
		end
	end
end

function XPVEClass:Load(main_module)
	self.menu        = main_module.menu

	if self.class_name ~= "PvE Class" then

		self.menu["ACTIONS"][self.class_category]:subMenu(self.class_name, self.class_name_short)

		self.class_menu = self.menu["ACTIONS"][self.class_category][self.class_name_short]

		if #self.rotations > 0 then
			self.class_menu:subMenu("Rotations", "ROTATIONS")

			for i, rotation in ipairs(self.rotations) do
				self.class_menu["ROTATIONS"]:checkbox("Use " .. rotation.name, rotation.name, true)
			end

		end

	end
end


function XPVEClass:Tick()


	if self:ValidTarget() then
		self.target = TargetManager.Target
		self.last_target_time = os.clock()

		if self.loaded_aoe then
			self.aoe_min     = self.class_widget["COMBO_SETTINGS"]["AOE_MIN"].int
			self.aoe_on      = self.class_widget["COMBO_SETTINGS"]["AOE"].bool
			self.aoe         = self.aoe_on and ObjectManager.BattleEnemiesAroundObject(self.target, 5) >= ( self.aoe_min - 1 )
		end
	end

end

function XPVEClass:Ticker()
	if self:IsCurrentClass() then
		if _G.XPVE ~= nil then
			if XPVE.current_class == nil or not _G.XPVE.current_class:IsCurrentClass() then
				_G.XPVE.current_class = self
				if self.class_widget ~= nil then
					self.class_widget.visible = true
				end
			end
		end
		if self.role_module ~= nil then
			self.role_module:Tick()
		end
		self:Tick()
	elseif self.class_widget ~= nil and self.class_widget.visible then
		self.class_widget.visible = false
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
	return target.valid and not target.ally and target.kind == 2 and target.subKind == 5 and target.yalmX < dist and not target.isDead and target.isTargetable
end

function XPVEClass:IsCurrentClass()
	return self.class_ids[player.classJob] ~= nil
end

function XPVEClass:CanUse(action, target)
	if target == nil then
		return self.actions[action]:canUse()
	end
	return self.actions[action]:canUse(target)
end

function XPVEClass:Use(action, target)

	if target == nil then
		self.actions[action]:use()
		self.log:print("Using " .. self.actions[action].name)
	else
		self.actions[action]:use(target)
		self.log:print("Using " .. self.actions[action].name .. " on " .. target.name)
	end

end

function XPVEClass:LastActionIs(action)
	return self.last_action == self.actions[action].id
end

function XPVEClass:ComboActionIs(action)
	return ActionManager.ComboId == self.actions[action].id
end

return XPVEClass