local DutySupportActivity = Class("DutySupportActivity")

function DutySupportActivity:initialize()
	-- interactables
	self.interactables       = LoadModule("XScripts", "/Enums/Interactables")
	-- Map Ids
	self.maps                   = {}
	-- Current MapId
	self.map_id                 = 0
	-- Started
	-- Death Watch
	self.died                   = false

	-- Is Trial
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
	self.battle_fov             = 30
		-- FoV for event objects
	self.event_fov              = 50
		-- FoV for treasure objects
	self.treasure_fov           = 99
		-- FoV for event npc objects
	self.event_npc_fov          = 99
		-- FoV for LoS of Ranged Champions
	self.los_fov                = 15

	-- Callbacks
	self.exit_callback          = nil
	self.performed_exit         = false

	Callbacks:Add(CALLBACK_PLAYER_TICK, function() self:Ticker() end)
	Callbacks:Add(CALLBACK_PLAYER_DRAW, function() self:Drawer() end)

end

function DutySupportActivity:ExitCallback() end

function DutySupportActivity:Ticker()
	self.map_id = AgentManager.GetAgent("Map").currentMapId
	if self:IsIn() and self:CanTick() then
		if not self.started then
			self.started        = true
			self.performed_exit = false
		end
		self:BeforeTick()
		self:MainTick()
		self:Tick()
	elseif self.started and not self.performed_exit and not self:IsIn() then
		self:ExitCallback()
		self.started        = false
		self.performed_exit = true
	end
end

function DutySupportActivity:Drawer()
	if self:IsIn() and self.current_nav ~= nil then
		local last_pos = nil
		local end_pos  = self.current_nav.waypoints[#self.current_nav.waypoints]

		for i, pos in ipairs(self.current_nav.waypoints) do
			if i ~= 1 then
				Graphics.DrawCircle3D(pos, 4, 0.25, Colors.Blue)
			end
			if last_pos ~= nil then
				Graphics.DrawLine3D(last_pos, pos, Colors.Yellow)
			end
			last_pos = pos
		end
		if last_pos ~= nil and self.end_pos ~= Vector3.Zero then
			Graphics.DrawLine3D(last_pos, end_pos, Colors.Yellow)
		end

		self:Draw()
	end
end

function DutySupportActivity:Draw() end
function DutySupportActivity:Tick() end
function DutySupportActivity:BeforeTick() end

function DutySupportActivity:MainTick()
	if self:HandleInteractions() then return end
	
	self:DeathWatch()

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
		if self.interactables.exits[obj.npcId] ~= nil and obj.isTargetable then
			return true
		end
		local data_id = obj.dataId
		if self.event_filters[data_id] ~= nil and not self.event_filters[data_id](obj) then
			return false
		end
		return obj.pos:dist(player.pos) < self.event_fov and obj.isTargetable and (
			self.event_objects[obj.dataId] ~= nil or
			self.interactables.shortcuts[obj.npcId] ~= nil or
			self.interactables.gates[obj.npcId] ~= nil or
			self.interactables.doors[obj.npcId] ~= nil)
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
	if self.destination == nil then
		self.destination = self.maps[self.map_id]
	end

	if not TaskManager:IsBusy() and self.destination ~= nil and not self:ValidTarget(TargetManager.Target) then
		if player.pos:dist(self.destination) > 3 then
			self:StartNav(self.destination, NAV_TYPE_DESTINATION)
		else
			self:Exit()
		end
	end
end

function DutySupportActivity:HandleMobs(objects)

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
				print("Set new Target: " .. closest_obj.name)
				TargetManager.Target = closest_obj
			end
		end
	end

end

function DutySupportActivity:HandleObjects(objects)

	local closest_object = self:ClosestObject(objects)
	if closest_object ~= nil and closest_object.valid then
		local closest_dist  = closest_object.pos:dist(player.pos)
		if closest_object.pos:dist(player.pos) > 3.5 then
			if TaskManager:IsBusy() then
				if (self.nav_type == NAV_TYPE_EVENT and TargetManager.Target.valid and TargetManager.Target.id ~= closest_object.id) or
				   self.nav_type == NAV_TYPE_DESTINATION or self.nav_type == NAV_TYPE_NONE then
					self:ResetNav()
				end
				local target = TargetManager.Target
				if target.valid and target.pos:dist(player.pos) > ( closest_dist + 2 ) then
					self:ResetNav()
				end
			elseif not TaskManager:IsBusy() then
				print("Navigating to closest obj : " .. closest_object.name)
				self:StartNav(closest_object.pos, NAV_TYPE_EVENT)
				TargetManager.Target = closest_object
			end
		else
			player:rotateTo(closest_object.pos)
			TaskManager:Interact(closest_object)
		end
	end

end

function DutySupportActivity:SetMaps(maps_tbl)

	for i, map in pairs(maps_tbl) do
		self.maps[i] = map;
	end

end

function DutySupportActivity:CanTick()
	return _G.XACTIVITIES ~= nil and _G.XACTIVITIES:CanTick()
end

function DutySupportActivity:IsIn()
	return self.maps[self.map_id] ~= nil
end

function DutySupportActivity:SetExitCallback(func)
	self.exit_callback = func
end

function DutySupportActivity:AddBattleFilter(id, func)
	self.battle_filters[id] = func
end

function DutySupportActivity:AddEventFilter(id, func)
	self.event_filters[id] = func
end

function DutySupportActivity:AddEventNpcFilter(id, func)
	self.event_npc_filters[id] = func
end

function DutySupportActivity:StartNav(pos, nav_type)
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

function DutySupportActivity:ResetNav()
	TaskManager:Stop()
	self.current_nav = nil
	self.nav_type    = NAV_TYPE_NONE
	TargetManager.SetTarget()
	Keyboard.SendKey(38)
end

function DutySupportActivity:HandleInteractions()
	local treasure = ObjectManager.TreasureObject(function(obj) return
		InventoryManager.HasInventorySpace and obj.pos:dist(player.pos) < 3.5 and obj.isTargetable end)
	if treasure.valid then
		player:rotateTo(treasure.pos)
		TaskManager:Interact(treasure)
		return true
	end
	local shortcut = ObjectManager.EventObject(function(obj) return self.interactables.shortcuts[obj.npcId] ~= nil and obj.pos:dist(player.pos) < 3.5 and obj.isTargetable end)
	if shortcut.valid then
		player:rotateTo(shortcut.pos)
		return true
	end

	local gate = ObjectManager.EventObject(function(obj) return self.interactables.gates[obj.npcId] ~= nil and obj.pos:dist(player.pos) < 3.5 and obj.isTargetable end)
	if gate.valid then
		player:rotateTo(gate.pos)
		TaskManager:Interact(gate)
		return true
	end

	local door = ObjectManager.EventObject(function(obj) return self.interactables.doors[obj.npcId] ~= nil and obj.pos:dist(player.pos) < 3.5 and obj.isTargetable end)
	if door.valid then
		player:rotateTo(door.pos)
		TaskManager:Interact(door)
		return true
	end

	return false
end

function DutySupportActivity:Exit()
	local exit = ObjectManager.EventObject( function(obj)
		return self.interactables.exits[obj.npcId] ~= nil and obj.pos:dist(player.pos) < 3.5 and obj.isTargetable end)
	if exit.valid then
		TaskManager:Interact(exit)
	end
end

function DutySupportActivity:ValidTarget(target)
	return target.valid and target.kind == 2 and target.subKind == 5 and target.isTargetable and not target.ally
end

function DutySupportActivity:ClosestObject(obj_list)
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

function DutySupportActivity:DeathWatch()
	if player.isDead or player.health == 0 and not self.died then
		self.died = true
		TaskManager:Stop()
	elseif self.died and player.health > 0 then
		TaskManager:Stop()
		self.died = false
	end
end


return DutySupportActivity