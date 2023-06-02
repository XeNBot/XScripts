local Mission = Class("Mission")

function Mission:initialize()
	-- Main Module	
	self.main_module            = nil

	-- Death Watch
	self.died                   = false

	-- Is Trial Mission
	self.is_trial               = false

	-- Objects
	self.event_objects          = {}
	self.event_npc_objects      = {}
	self.priority_event_objects = {}

	-- filters
	self.event_filters          = {}
	self.event_npc_filters      = {}
	self.battle_filters         = {}

	-- Current Navigation
	self.current_nav            = nil
	self.nav_type               = 0

	NAV_TYPE_NONE               = 0
	NAV_TYPE_DESTINATION        = 1
	NAV_TYPE_MOB                = 2
	NAV_TYPE_EVENT              = 3

	-- Field of View
		-- FoV for battle monsters
	self.battle_fov             = 10
		-- FoV for event objects
	self.event_fov              = 45
		-- FoV for treasure objects
	self.treasure_fov           = 30
		-- FoV for event npc objects
	self.event_npc_fov          = 99
		-- FoV for LoS of Ranged Champions
	self.los_fov                = 15

	-- Mission Goal
	self.destination           = nil
	self.map_id                = 0

	-- Callbacks
	self.exit_callback        = nil

end

function Mission:ExitCallback() end

function Mission:SetMainModule(mod)

	self.main_module = mod

end



function Mission:Tick()

	if self:HandleInteractions() then return end

	self:DeathWatch()

	self.map_id = AgentManager.GetAgent("Map").currentMapId

	local priority_event_objects = ObjectManager.EventObjects(function (obj)
		return obj.pos:dist(player.pos) < self.event_fov and obj.isTargetable and self.priority_event_objects[obj.dataId] ~= nil
	end)
	local mob_objects = ObjectManager.Battle(function(obj)
		local data_id = obj.dataId
		if Navigation.Raycast(player.pos, obj.pos) ~= Vector3.Zero then
			return false
		end
		if self.battle_filters[data_id] ~= nil and not self.battle_filters[data_id](obj) then
			return false
		end
		return not obj.ally and obj.isTargetable and not obj.isDead and obj.pos:dist(player.pos) < self.battle_fov
	end)
	local event_objects = ObjectManager.EventObjects(function (obj)
		if self.main_module.interactables.exits[obj.npcId] ~= nil then
			return true
		end
		local data_id = obj.dataId
		if self.event_filters[data_id] ~= nil and not self.event_filters[data_id](obj) then
			return false
		end
		return obj.pos:dist(player.pos) < self.event_fov and obj.isTargetable and (
			self.event_objects[obj.dataId] ~= nil or
			self.main_module.interactables.shortcuts[obj.npcId] ~= nil or
			self.main_module.interactables.gates[obj.npcId] ~= nil or
			self.main_module.interactables.doors[obj.npcId] ~= nil)
	end)
	local treasure_objects  = ObjectManager.TreasureObjects(function(obj) return InventoryManager.HasInventorySpace and obj.isTargetable and obj.pos:dist(player.pos) < self.treasure_fov end)
	local event_npc_objects = ObjectManager.EventNpcObjects(function(obj)
		local data_id = obj.dataId
		if self.event_npc_filters[data_id] ~= nil and not self.event_npc_filters[data_id](obj) then
			return false
		end
		return obj.isTargetable and obj.pos:dist(player.pos) < self.event_npc_fov
	end)

	if #priority_event_objects > 0 then
		--print("Handling Mobs")
		return self:HandleObjects(priority_event_objects)
	end
	if #mob_objects > 0 then
		--print("Handling Mobs")
		return self:HandleMobs(mob_objects)
	end
	if #treasure_objects > 0 then
		--print("Handling Treasures")
		return self:HandleObjects(treasure_objects)
	end
	if #event_npc_objects > 0 then
		--print("Handling Objects")
		return self:HandleObjects(event_npc_objects)
	end
	if #event_objects > 0 then
		--print("Handling Objects")
		return self:HandleObjects(event_objects)
	end
	if not TaskManager:IsBusy() and self.destination ~= nil and not self:ValidTarget(TargetManager.Target) then
		if player.pos:dist(self.destination) > 3 then
			self:StartNav(self.destination, NAV_TYPE_DESTINATION)
		else
			self:Exit()
		end
	end
end

function Mission:HandleMobs(objects)

	local closest_obj = self:ClosestObject(objects)

	if not closest_obj.valid then return end

	local closest_dist = closest_obj.pos:dist(player.pos)


	if not player.isMelee then

		if closest_dist <= 15 then
			if TaskManager:IsBusy() then
				self:ResetNav()
			end
			TargetManager.Target = closest_obj
		else
			if TaskManager:IsBusy() then
				if self.nav_type ~= NAV_TYPE_MOB then
					print("Changing Navigation to Mob")
					self:ResetNav()
				end
				local target = TargetManager.Target
				if target.valid and target.pos:dist(player.pos) > ( closest_dist + 2 ) then
					self:ResetNav()
				end
			else
				print("Navigating to closest obj : " .. closest_obj.name)
				self:StartNav(closest_obj.pos, NAV_TYPE_MOB)
				TargetManager.Target = closest_obj
			end
		end
	else
		if closest_dist > 3.5 then
			if TaskManager:IsBusy() then
				if self.nav_type ~= NAV_TYPE_MOB or TargetManager.Target.id ~= closest_obj.id then
					print("Changing Navigation to Mob")
					self:ResetNav()
				end
				local target = TargetManager.Target
				if target.valid and target.pos:dist(player.pos) > ( closest_dist + 2 ) then
					self:ResetNav()
				end
			else
				if TaskManager:IsBusy() then
					self:ResetNav()
				end
				print("Navigating to closest obj : " .. closest_obj.name)
				self:StartNav(closest_obj.pos, NAV_TYPE_MOB)
				TargetManager.Target = closest_obj
			end
		else
			if TaskManager:IsBusy() then
				self:ResetNav()
			end
			if not self:ValidTarget(TargetManager.Target) or TargetManager.Target.id ~= closest_obj.id then
				self.main_module.log:print("Set new Target: " .. closest_obj.name)
				TargetManager.Target = closest_obj
			end
		end
	end

end

function Mission:HandleObjects(objects)

	local closest_object = self:ClosestObject(objects)
	if closest_object ~= nil and closest_object.valid then
		local closest_dist  = closest_object.pos:dist(player.pos)
		if closest_object.pos:dist(player.pos) > 3.5 then
			if TaskManager:IsBusy() then
				if (self.nav_type == NAV_TYPE_EVENT and TargetManager.Target.valid and TargetManager.Target.id ~= closest_object.id) or
				   (self.nav_type == NAV_TYPE_DESTINATION or self.nav_type == NAV_TYPE_NONE) then
					self:ResetNav()
				end
				local target = TargetManager.Target
				if target.valid and target.pos:dist(player.pos) > ( closest_dist + 2 ) then
					self:ResetNav()
				end
			elseif not TaskManager:IsBusy() then
				self:StartNav(closest_object.pos, NAV_TYPE_EVENT)
				TargetManager.Target = closest_object
			end
		else
			player:rotateTo(closest_object.pos)
			TaskManager:Interact(closest_object)
		end
	end

end

function Mission:SetExitCallback(func)
	self.exit_callback = func
end

function Mission:AddBattleFilter(id, func)
	self.battle_filters[id] = func
end

function Mission:AddEventFilter(id, func)
	self.event_filters[id] = func
end

function Mission:AddEventNpcFilter(id, func)
	self.event_npc_filters[id] = func
end

function Mission:StartNav(pos, nav_type)
	if self.current_nav == nil then
		self.current_nav = Navigation(player.pos, pos)
	else
		if #self.current_nav.waypoints > 0 then
			self.nav_type = nav_type
			TaskManager:Navigate(self.current_nav, function () self:ResetNav() end)
		else
			print("Bad Navigation Received, Resetting")
			self.current_nav = nil
		end
	end
end

function Mission:ResetNav()
	TaskManager:Stop()
	self.current_nav = nil
	self.nav_type    = NAV_TYPE_NONE
	TargetManager.SetTarget()
	Keyboard.SendKey(38)
end

function Mission:HandleInteractions()
	local treasure = ObjectManager.TreasureObject(function(obj) return
		InventoryManager.HasInventorySpace and obj.pos:dist(player.pos) < 3.5 and obj.isTargetable end)
	if treasure.valid then
		player:rotateTo(treasure.pos)
		TaskManager:Interact(treasure)
		return true
	end
	local shortcut = ObjectManager.EventObject(function(obj) return self.main_module.interactables.shortcuts[obj.npcId] ~= nil and obj.pos:dist(player.pos) < 3.5 and obj.isTargetable end)
	if shortcut.valid then
		player:rotateTo(shortcut.pos)
		TaskManager:Interact(shortcut, self.main_module.callbacks.Shortcut)
		return true
	end

	local gate = ObjectManager.EventObject(function(obj) return self.main_module.interactables.gates[obj.npcId] ~= nil and obj.pos:dist(player.pos) < 3.5 and obj.isTargetable end)
	if gate.valid then
		player:rotateTo(gate.pos)
		TaskManager:Interact(gate)
		return true
	end

	local door = ObjectManager.EventObject(function(obj) return self.main_module.interactables.doors[obj.npcId] ~= nil and obj.pos:dist(player.pos) < 3.5 and obj.isTargetable end)
	if door.valid then
		player:rotateTo(door.pos)
		TaskManager:Interact(door)
		return true
	end

	return false
end

function Mission:Exit()
	local exit = ObjectManager.EventObject( function(obj)
		return self.main_module.interactables.exits[obj.npcId] ~= nil and self.main_module.callbacks.InteractFilter(obj)
	end)
	if exit.valid then
		TaskManager:Interact(exit, function ()
			self:ExitCallback()
			self.main_module.callbacks.ExitMission()
		end)
		self.main_module.last_exit = os.clock()
	end
end

function Mission:ValidTarget(target)
	return target.valid and target.kind == 2 and target.subKind == 5 and target.isTargetable and not target.ally
end

function Mission:ClosestObject(obj_list)
	local closest      = nil
	local closest_dist = 1000

	for i, obj in ipairs(obj_list) do
		local dist = obj.pos:dist(player.pos)
		if dist < closest_dist then
			closest = obj
			closest_dist = dist
		end
	end

	return closest
end

function Mission:DeathWatch()
	if player.isDead or player.health == 0 and not self.died then
		self.died = true
		TaskManager:Stop()
	elseif self.died and player.health > 0 then
		TaskManager:Stop()
		self.died = false
		self.main_module.stats.times_died = self.main_module.stats.times_died + 1
		self.main_module.log:print("Oh noes we died! reviving....")
		self.main_module.widget["TIMES_DIED"].str = "Times We've Died: " .. tostring(self.main_module.stats.times_died)
	end
end


return Mission