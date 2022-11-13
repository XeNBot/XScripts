local XDutyRunner = Class("XDutyRunner")

function XDutyRunner:initialize()

	--[[ ==== Script Variables ==== ]]--
	self.started         = false
	self.current_mission = nil

	-- Timers
	self.last_enter_duty = 0
	self.last_shortcut   = 0
	self.last_exit       = 0
	
	-- Route
	self.route           = Route()

	-- Stats
	self.stats = {
		missions_started  = 0,
		missions_finished = 0,
		times_died        = 0
	}

	--[[ ==== Grid ==== ]]--
	self.grid          = LoadModule("XScripts", "/Waypoints/DutyGrid")
	--[[ ==== Interactables === ]]--
	self.interactables = LoadModule("XScripts", "/Enums/Interactables")
	--[[ ==== Log === ]]--
	self.log           = LoadModule("XScripts", "/Utilities/Log")
	--[[ ==== BattleNPC Filter === ]]--
	self.b_filter = {
		[108]   = true,
		[1298]  = true,
		[1299]  = true,
		[1300]  = true,
		[10484] = true,
		[1486] = true,
	}
	--[[ ==== Missions Table ==== ]]--
	self.missions = {		
		{
			
			name          = "Sastasha",
			tab_index     = 0,
			mission_index = 1,
			module        = LoadModule("XScripts", "/Missions/Sastasha"),
			map_id        = 31,
			level         = 15,
		},
		{

			name          = "The Bowl of Embers",
			tab_index     = 0,
			mission_index = 4,
			module        = LoadModule("XScripts", "/Missions/BowlOfEmbers"),
			map_id        = 35,
			level         = 20,
		},
		{
			name          = "Thousand Maws of Toto-Rak",
			tab_index     = 0,
			mission_index = 5,
			module        = LoadModule("XScripts", "/Missions/TotoRak"),
			map_id        = 9,
			level         = 24,
		},
		{
			
			name          = "Brayflox's Longstop",
			tab_index     = 0,
			mission_index = 7,
			module        = LoadModule("XScripts", "/Missions/Brayflox"),
			map_id        = 45,
			level         = 32,
		},
		{

			name          = "Castrum Meridianum",
			tab_index     = 0,
			mission_index = 11,
			module        = LoadModule("XScripts", "/Missions/CastrumMeridianum"),
			map_id        = 47,
			level         = 50,
		},
		{

			name          = "Snowcloak",
			tab_index     = 0,
			mission_index = 14,
			module        = LoadModule("XScripts", "/Missions/Snowcloak"),
			map_id        = 174,
			level         = 50,
		},
	}

	for i, mission in ipairs(self.missions) do
		if mission.module ~= nil then 
			mission.module:SetMainModule(self)
		else 
			print("Failed initialization of " ..mission.name)
		end
	end
	
	-- Sets up required callbacks
	self:setupCallbacks()
	-- Initializes Menu
	self:initializeMenu()

	Callbacks:Add(CALLBACK_PLAYER_TICK, self.callbacks.Tick)
	Callbacks:Add(CALLBACK_PLAYER_DRAW, self.callbacks.Draw)

end

function XDutyRunner:Tick()

	local map_id = AgentManager.GetAgent("Map").currentMapId

	if self:CanNotTick(map_id) then return end
	
	if self.current_mission == nil then
		self.current_mission = self.menu["AUTO_PICK"].bool and self:BestDuty() or self.missions[self.menu["MISSION_ID"].int + 1]
	end

	if self.current_mission == nil then return end
	
	
	if map_id ~= self.current_mission.map_id then
		
		TaskManager:EnterDutySupport(
			self.current_mission.tab_index, 
			self.current_mission.mission_index,
			self.callbacks.EnterDutySupport)
	else
		if self:HandleInteractions() then return end
		self.current_mission.module:Tick()
	end

end

function XDutyRunner:CanNotTick(map_id)
	return 

		not self.started or
		player.classLevel < 15 or 
		(os.clock() - self.last_enter_duty) < 8 or
		(os.clock() - self.last_shortcut) < 8 or
		(os.clock() - self.last_exit) < 8 or
		self.grid[tostring(map_id)] == nil and TaskManager:IsBusy()
end

function XDutyRunner:BestDuty()
	
	local highest_level = 0



	if player.classLevel < 24 then
		return self.missions[1]
	elseif player.classLevel < 32 then
		return self.missions[2]
	else
		return self.missions[3]
	end

end

function XDutyRunner:Draw()
	local maxDrawDistance = self.menu["DRAW_SETTINGS"]["MAX_DRAW_DISTANCE"].int

	if self.menu["DRAW_SETTINGS"]["DRAW_WAYPOINTS"].bool then
		self:DrawNodes(maxDrawDistance)
	end	
end

function XDutyRunner:DrawNodes(maxDistance)

	local currentMapId = tostring(AgentManager.GetAgent("Map").currentMapId)
	if self.grid[currentMapId] ~= nil and self.grid[currentMapId].nodes ~= nil then
		for i, waypoint in ipairs(self.grid[currentMapId].nodes.waypoints) do
			if waypoint.pos:dist(player.pos) < maxDistance then
				Graphics.DrawCircle3D(waypoint.pos, 20, 1, Colors.Green)
				if self.menu["DRAW_SETTINGS"]["DEBUG_INFO"].bool then
					Graphics.DrawText3D(waypoint.pos, "[" ..tostring(math.floor(player.pos:dist(waypoint.pos))).."]("..tostring(i)..")", 11, RGBA(255, 0, 0, 255))
					if waypoint.pos:dist(player.pos) < 5 and #waypoint.links > 0 then
						for i, link in ipairs(waypoint.links) do
							Graphics.DrawLine3D(waypoint.pos, link.pos, Colors.Blue)
						end
					end
				end
			end
		end
	end
end

function XDutyRunner:HandleInteractions()
	
	local treasure = ObjectManager.TreasureObject(function(obj) return obj.pos:dist(player.pos) < 3 and obj.isTargetable end)
	if treasure.valid then
		player:rotateTo(treasure.pos)
		TaskManager:Interact(treasure)	
		return true
	end
	local shortcut = ObjectManager.EventObject(function(obj) return self.interactables.shortcuts[obj.npcId] ~= nil and obj.pos:dist(player.pos) < 3 and obj.isTargetable end)
	if shortcut.valid then
		player:rotateTo(shortcut.pos)
		TaskManager:Interact(shortcut, self.callbacks.Shortcut)
		return true
	end	

	local gate = ObjectManager.EventObject(function(obj) return self.interactables.gates[obj.npcId] ~= nil and obj.pos:dist(player.pos) < 3 and obj.isTargetable end)
	if gate.valid then
		player:rotateTo(gate.pos)
		TaskManager:Interact(gate)
		return true
	end	

	local door = ObjectManager.EventObject(function(obj) return self.interactables.doors[obj.npcId] ~= nil and obj.pos:dist(player.pos) < 3 and obj.isTargetable end)
	if door.valid then
		player:rotateTo(door.pos)
		TaskManager:Interact(door)
		return true
	end	

	return false
end

function XDutyRunner:setupCallbacks()
	
	self.callbacks = {

		Tick          = function () return self:Tick() end,
		Draw          = function () return self:Draw() end,		
		Shortcut = function ()
			self.route         = Route()
			self.last_shortcut = os.clock()			
			self.log:print("Using Shortcut")
		end,
		ToggleStartBtn = function()
			if not self.started then
				self.menu["BTN_START"].str = "Stop"
				self.started = true
			else
				self.menu["BTN_START"].str = "Start"
				if TaskManager:IsBusy() then 
					TaskManager:Stop() 
				end
				self.started = false
			end
		end,
		EnterDutySupport = function()
			self.last_enter_duty                = os.clock()
			self.stats.missions_started         = self.stats.missions_started + 1
			self.widget["MISSIONS_ENTERED"].str = "Missions Entered: " .. tostring(self.stats.missions_started)			
			self.route                          = Route()
			self.log:print("Entered Mission: " .. self.current_mission.name)	
		end,
		WalkToWaypoint = function (waypoint)
			if (self.route.index < #self.route.waypoints) then
				self.route.index = self.route.index + 1
			end			
		end,
		ExitSquadron = function ()
			self.stats.missions_finished          = self.stats.missions_finished + 1
			self.widget["MISSIONS_FINISHED"].str  = "Missions Finished: " .. tostring(self.stats.missions_finished)
			self.route                            = Route()
			self.log:print("Finished Mission: " .. self.currentMission.name)
			self.current_mission                  = nil
		end,
		InteractFilter = function(obj) return obj.pos:dist(player.pos) < 4 and obj.isTargetable end

	}

end

function XDutyRunner:initializeMenu()
	
	self.menu = Menu("XDutyRunner")
	self.menu:label("~=[ XDutyRunner Ver 1.0 ]=~") self.menu:separator() self.menu:space()

	local mission_table = {}

	for i, mission in ipairs(self.missions) do
		table.insert(mission_table, mission.name .. " Lvl " .. tostring(mission.level))
	end

	self.menu:combobox("Mission Selector",       "MISSION_ID", mission_table, 0)
	self.menu:checkbox("Auto Pick Best Mission", "AUTO_PICK", true)

	self.menu:label("~=[ Other Settings ]=~") self.menu:space() self.menu:separator()
		self.menu:subMenu("Draw Settings", "DRAW_SETTINGS")
			self.menu["DRAW_SETTINGS"]:checkbox("Draw Waypoints", "DRAW_WAYPOINTS", false) 
			self.menu["DRAW_SETTINGS"]:number("Max Draw Distance", "MAX_DRAW_DISTANCE", 50)
			self.menu["DRAW_SETTINGS"]:checkbox("Draw Debug Info", "DEBUG_INFO", false)


	self.menu:space() self.menu:space()

	self.menu:button("Start", "BTN_START", self.callbacks.ToggleStartBtn)
	self.menu:button("Open Info Widget", "INFO_WIDGET", function() self.widget.visible = true end)

	self.widget = Menu("XDutyRunner Info", true)
	self.widget:label("~=[ Information ]=~") self.menu:separator() self.menu:space()
	self.widget:label("Missions Entered: 0",  "MISSIONS_ENTERED") 
	self.widget:label("Missions Finished: 0", "MISSIONS_FINISHED")
	self.widget:label("Times We've Died: 0",  "TIMES_DIED")

end

return XDutyRunner:new()