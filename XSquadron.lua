local XSquadron = Class("XSquadron")

function XSquadron:initialize()

	--[[ ==== Grid === ]]--
	self.grid          = LoadModule("XScripts", "/Waypoints/SquadronGrid")
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
	}
	-- Actions
	self.actions = {
		limitBreak = Action(19, 4)
	}

	-- Stats
	self.stats = {
		missions_started  = 0,
		missions_finished = 0,
		times_died        = 0
	}

	-- town maps
	self.towns = {
		-- new grinadia
		[2] = true,
	}

	self.started = false
	self.route   = Route()
	
	self.lastExit     = 0
	self.lastEnter    = 0
	self.lastShortcut = 0
	
	-- Expert Delivery
	self.delivered    = false
	self.delivering   = false
	self.deliverRoute = Route()

	self:SetupMissions()
	self:SetupCallbacks()
	self:InitializeMenu()	

	Callbacks:Add(CALLBACK_PLAYER_TICK, self.callbacks.Tick)
	Callbacks:Add(CALLBACK_PLAYER_DRAW, self.callbacks.Draw)
end

function XSquadron:Tick()

	if not self.started or ((os.clock() - self.lastShortcut) < 5) or ((os.clock() - self.lastEnter) < 6) or
	((os.clock() - self.lastExit) < 5) or _G.Evading then return end
	
	if self.currentMission == nil then
		return switch(self.menu["MISSION_ID"].int, self.currentMissionMenuSwitch)
	end


	if self:Interactables() then return end


	local currentMapId = AgentManager.GetAgent("Map").currentMapId

	
	if currentMapId == 308 then
		if Game.CompanySeals >= self.currentMission.cost and not self.delivering then
			self:HandleLobby(currentMapId)
		else
			if self.delivered then
				self.log:print("Don't have enough seals after delivering stoping....")
				self:ToggleStartBtn()
			elseif not self.delivering then
				self.log:print("Need more seals for mission, trying Expert Delivery")
				self.delivering = true
				TaskManager:WalkToWaypoint(self.grid[tostring(currentMapId)].exit)

			end
		end
	else

		if self:InTown() then
			self:HandleTown(currentMapId)
		else
			self.currentMission.module:Tick(self)				
		end
	end
end

function XSquadron:SetupMissions()

	--[[ ==== Mission Variables === ]]--
	self.currentMission           = nil
	self.currentMissionMenuSwitch = nil
	
	self.missions = {
		hatali     = {
			name      = "Hatali",
			cost      = 1000,
			module    = LoadModule("XScripts", "/Missions/Hatali"),
			mapId     = 46,
			menuIndex = 0,
		},
		torok      = {
			name      = "Torok-Rak",
			cost      = 1200,
			module    = LoadModule("XScripts", "/Missions/TotoRak"),
			mapId     = 9,
			menuIndex = 1,
		},
		brayflox    = {
			name      = "Brayflox's Longstop",
			cost      = 1600,
			module    = LoadModule("XScripts", "/Missions/Brayflox"),
			mapId     = 45,
			menuIndex = 2,
		},
		stonevigil = {
			name      = "Stone Vigil",
			cost      = 2000,
			module    = LoadModule("XScripts", "/Missions/StoneVigil"),
			mapId     = 37,
			menuIndex = 3,
		},
		aurumvale = {
			name      = "The Aurum Vale",
			cost      = 2400,
			module    = LoadModule("XScripts", "/Missions/AurumVale"),
			mapId     = 38,
			menuIndex = 5,
		},
		wanderer = {
			name      = "The Wanderer's Palace",				
			cost      = 2500,
			module    = LoadModule("XScripts", "/Missions/WanderersPalace"),
			mapId     = 32,
			menuIndex = 6,
		}
	}

	for mission, info in pairs(self.missions) do
		info.module:SetMainModule(self)
	end


	self.currentMissionMenuSwitch = {
		[0] = function ()
			self.currentMission = self.missions.hatali
		end,
		[1] = function()
			self.currentMission = self.missions.torok
		end,
		[2] = function()
			self.currentMission = self.missions.brayflox
		end,
		[3] = function()
			self.currentMission = self.missions.stonevigil
		end,
		[4] = function()
			self.currentMission = self.missions.aurumvale
		end,
		[5] = function()
			self.currentMission = self.missions.wanderer
		end
	}	

end

function XSquadron:SetupCallbacks()
	
	self.callbacks = {

		Tick          = function () return self:Tick() end,
		Draw          = function () return self:Draw() end,
		EnterSquadron = function ()
			self.stats.missions_started        = self.stats.missions_started + 1
			self.widget["MISSIONS_ENTERED"].str  = "Missions Entered: " .. tostring(self.stats.missions_started)			
			self.route                         = Route()
			self.deliverRoute                  = Route()
			self.delivered                     = false
			self.delivering                    = false
			self.log:print("Entered Mission: " .. self.currentMission.name)			
			
		end,
		ExitSquadron = function ()
			self.stats.missions_finished        = self.stats.missions_finished + 1
			self.widget["MISSIONS_FINISHED"].str  = "Missions Finished: " .. tostring(self.stats.missions_finished)
			self.route                          = Route()
			self.deliverRoute                   = Route()
			self.delivering                     = true
			self.log:print("Finished Mission: " .. self.currentMission.name)
		end,
		Shortcut = function ()
			self.route        = Route()
			self.lastShortcut = os.clock()			
			self.log:print("Using Shortcut")
		end,
		ExpertDelivery = function()
			self.delivering   = false
			self.delivered    = true
			self.deliverRoute = Route()
			self.log:print("Finished Delivering all items! now we have " .. tostring(Game.CompanySeals) .. " Company Seals")
		end,
		WalkToWaypoint = function (waypoint)
			if not self:InTown() then
				if (self.route.index < #self.route.waypoints) then
					self.route.index = self.route.index + 1
				end
			else
				if (self.deliverRoute.index < #self.deliverRoute.waypoints) then
					self.deliverRoute.index = self.deliverRoute.index + 1
				end
			end
		end,
		InteractFilter = function(obj) return obj.pos:dist(player.pos) < 5 and obj.isTargetable end

	}

end



function XSquadron:HandleLobby(mapId)
	local sergeant = ObjectManager.EventNpcObject(function(obj) return string.find(obj.name, "Sergeant") end)

	if sergeant.valid and not TaskManager:IsBusy() then
		player:rotateTo(sergeant.pos)
		player:rotateCameraTo(sergeant.pos)
		TaskManager:EnterSquadron(sergeant, self.currentMission.menuIndex, self.callbacks.EnterSquadron)
		self.lastEnter = os.clock()
	end
end

function XSquadron:Interactables()
	
	if self.delivering then
		local exit = ObjectManager.EventObject(function(obj) return self.interactables.exits[obj.npcId] ~= nil and obj.pos:dist(player.pos) < 3 and obj.isTargetable end)
		if exit.valid and not TaskManager:IsBusy() then
			player:rotateTo(exit.pos)
			player:rotateCameraTo(exit.pos)
			TaskManager:Interact(exit)
			return true
		end
	end

	if self:InTown() then
		if self.delivering then
			local officer = ObjectManager.EventNpcObject(function(obj) return obj.dataId == 1002394 and obj.pos:dist(player.pos) < 4 and obj.isTargetable end)
			if officer.valid and not TaskManager:IsBusy() then
				player:rotateCameraTo(officer.pos)
				player:rotateTo(officer.pos)
				TaskManager:ExpertDelivery(officer, self.callbacks.ExpertDelivery)
				return true
			end
		else
			local entrance = ObjectManager.EventObject(function(obj) return self.interactables.entrances[obj.npcId] ~= nil and obj.pos:dist(player.pos) < 5 and obj.isTargetable end)
			if entrance.valid and not TaskManager:IsBusy() then
				player:rotateCameraTo(entrance.pos)
				player:rotateTo(entrance.pos)
				TaskManager:Interact(entrance)
				return true
			end
		end
	end

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

function XSquadron:HandleTown(mapId)

	local map = self.grid[tostring(mapId)]

	if Game.CompanySeals < self.currentMission.cost then
		if not self.delivering and not self.delivered then
			self.log:print("Need more seals for mission, trying Expert Delivery")
			self.delivering = true
		elseif self.delivered then
		    self.log:print("Finished Expert Delivery and still don't have enough Company Seals ... rip")
		    self:ToggleStartBtn()
		    self.delivered = false
		end

	end


	if not self.deliverRoute.finished then
		self.deliverRoute:builda(map.nodes, self.delivering and map.officer or map.entrance)
	else
		TaskManager:WalkToWaypoint(self.deliverRoute.waypoints[self.deliverRoute.index], function(waypoint) self.callbacks.WalkToWaypoint(waypoint) end)
	end
end

function XSquadron:Draw()
	
	local maxDrawDistance = self.menu["DRAW_SETTINGS"]["MAX_DRAW_DISTANCE"].int

	if self.menu["DRAW_SETTINGS"]["DRAW_WAYPOINTS"].bool then
		self:DrawNodes(maxDrawDistance)
	end	
end

function XSquadron:DrawNodes(maxDistance)

	local currentMapId = tostring(AgentManager.GetAgent("Map").currentMapId)
	
	if self.grid[currentMapId] ~= nil and self.grid[currentMapId].nodes ~= nil then

		for i, waypoint in ipairs(self.grid[currentMapId].nodes.waypoints) do
			if waypoint.pos:dist(player.pos) < maxDistance then
				Graphics.DrawCircle3D(waypoint.pos, 20, 1, Colors.Green)
				if self.menu["DRAW_SETTINGS"]["DEBUG_INFO"].bool then
					Graphics.DrawText3D(waypoint.pos, "[" ..tostring(player.pos:dist(waypoint.pos)).."]("..tostring(i)..")", 10, Colors.Green)
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

function XSquadron:InTown()

	return self.towns[AgentManager.GetAgent("Map").currentMapId] == true
end

function XSquadron:ToggleStartBtn()
	
	if not self.started then
		self.menu["BTN_START"].str = "Stop"
		self.started = true
	else
		self.menu["BTN_START"].str = "Start"
		self.started = false
	end

end

function XSquadron:InitializeMenu()
	
	self.menu = Menu("XSquadron")

	self.menu:label("~=[ XSquadron Ver 1.0 ]=~") self.menu:separator() self.menu:space()

	self.menu:combobox("Mission Selector", "MISSION_ID", { "Hatali", "Torok-Rak", "Brayflox's Longstop", "Stone Vigil", "The Aurum Vale", "The Wanderer's Palace" }, 0)

	self.menu:checkbox("Deliver Collectables", "EXPERT_DELIVERY", true) 
	self.menu:checkbox("Auto Pick Best Mission", "AUTO_PICK", true)

	self.menu:label("~=[ Other Settings ]=~") self.menu:space() self.menu:separator()
		self.menu:subMenu("Draw Settings", "DRAW_SETTINGS")
			self.menu["DRAW_SETTINGS"]:checkbox("Draw Waypoints", "DRAW_WAYPOINTS", false) 
			self.menu["DRAW_SETTINGS"]:number("Max Draw Distance", "MAX_DRAW_DISTANCE", 50)
			self.menu["DRAW_SETTINGS"]:checkbox("Draw Debug Info", "DEBUG_INFO", false)


	self.menu:space() self.menu:space()

	self.menu:button("Start", "BTN_START", function() self:ToggleStartBtn() end)
	self.menu:button("Open Info Widget", "INFO_WIDGET", function() self.widget.visible = true end)

	self.widget = Menu("XSquadron Info", true)
	self.widget:label("~=[ Information ]=~") self.menu:separator() self.menu:space()
	self.widget:label("Missions Entered: 0",  "MISSIONS_ENTERED") 
	self.widget:label("Missions Finished: 0", "MISSIONS_FINISHED")
	self.widget:label("Times We've Died: 0",  "TIMES_DIED")
end

return XSquadron:new()