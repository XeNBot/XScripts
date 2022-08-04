local XSquadron = Class("XSquadron")

function XSquadron:initialize()

	-- grid
	self.grid       = LoadModule("XScripts", "/Waypoints/SquadronGrid")
	-- missions
	self.hatali     = LoadModule("XScripts", "/Missions/Hatali")
	self.toto       = LoadModule("XScripts", "/Missions/TotoRak")
	self.brayflox   = LoadModule("XScripts", "/Missions/Brayflox")
	self.stonevigil = LoadModule("XScripts", "/Missions/StoneVigil")

	self.missions = { "Hatali", "Torok-Rak", "Brayflox's Longstop", "Stone Vigil" }


	-- Log Module
	self.log    = LoadModule("XScriptsT", "/Utilities/Log")
	self.log.delay = false

	-- Battle Name Filter
	self.b_filter = {

		["Brayflox Alltalks"] = true,
		["Goblin Pathfinder"] = true,
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

	-- Company Seals Cost		
	self.seal_cost = {1000, 1200, 1600, 2000}

	self.started = false
	self.route   = Route()
	self.died    = false
	
	self.lastExit     = 0
	self.lastEnter    = 0
	self.lastShortcut = 0
	
	-- Expert Delivery
	self.delivered    = false
	self.delivering   = false
	self.deliverRoute = Route()

	self:InitializeMenu()

	Callbacks:Add(CALLBACK_PLAYER_TICK, function () self:Tick() end)
	Callbacks:Add(CALLBACK_PLAYER_DRAW, function () self:Draw() end)
end

function XSquadron:Tick()
	self:DeathWatch()

	if not self.started or ((os.clock() - self.lastShortcut) < 5) or ((os.clock() - self.lastEnter) < 6) then return end
	
	if self:Interactables() then return end

	local currentMapId = AgentModule.currentMapId

	if currentMapId == 308 then
		if Game.CompanySeals >= self.seal_cost[self.menu["MISSION_ID"].int + 1] and not self.delivering then
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
			self:HandleMission(currentMapId)					
		end
	end
end

function XSquadron:OnEnterSquadron()
	self.stats.missions_started = self.stats.missions_started + 1
	self.menu["MISSIONS_ENTERED"].str = "Missions Entered: " .. tostring(self.stats.missions_started)
	self.log:print("Entered Mission: " .. self.missions[self.menu["MISSION_ID"].int + 1])
	self.delivered  = false
	self.delivering = false
	self.deliverRoute = Route()
	self.route = Route()
end

function XSquadron:OnExitSquadron()
	self.stats.missions_finished = self.stats.missions_finished + 1
	self.menu["MISSIONS_FINISHED"].str = "Missions Finished: " .. tostring(self.stats.missions_finished)
	self.log:print("Finished Mission: " .. self.missions[self.menu["MISSION_ID"].int + 1])
	self.route = Route()
	self.delivering = true	
end

function XSquadron:OnShortCut()
	self.lastShortcut = os.clock()
	self.log:print("Using Shortcut")
	self.route = Route()
end

function XSquadron:InteractFilter(obj)
	return obj.pos:dist(player.pos) < 5 and obj.isTargetable
end

function XSquadron:OnExpertDelivery()
	self.delivering   = false
	self.delivered    = true
	self.deliverRoute = Route()
	self.log:print("Finished Delivering all items! now we have " .. tostring(Game.CompanySeals) .. " Company Seals")
end

function XSquadron:HandleLobby(mapId)
	local sergeant = ObjectManager.EventNpcObject(function(obj) return string.find(obj.name, "Sergeant") end)

	if sergeant.valid and not TaskManager:IsBusy() then
		player:rotateTo(sergeant.pos)
		player:rotateCameraTo(sergeant.pos)
		TaskManager:EnterSquadron(sergeant, self.menu["MISSION_ID"].int, function () self:OnEnterSquadron() end)
		self.lastEnter = os.clock()
	end
end

function XSquadron:Interactables()
	
	if self.delivering then
		local exit = ObjectManager.EventObject(function(obj) return string.find(obj.name, "Exit") and obj.pos:dist(player.pos) < 3 and obj.isTargetable end)
		if exit.valid and not TaskManager:IsBusy() then
			player:rotateTo(exit.pos)
			player:rotateCameraTo(exit.pos)
			TaskManager:Interact(exit)
			return true
		end
	end

	if self:InTown() then
		if self.delivering then
			local officer = ObjectManager.EventNpcObject(function(obj) return string.find(obj.name, "Personnel Officer") and obj.pos:dist(player.pos) < 4 and obj.isTargetable end)
			if officer.valid and not TaskManager:IsBusy() then
				player:rotateCameraTo(officer.pos)
				player:rotateTo(officer.pos)
				TaskManager:ExpertDelivery(officer, function() self:OnExpertDelivery() end)
				return true
			end
		else
			local entrance = ObjectManager.EventObject(function(obj) return string.find(obj.name, "Entrance") and obj.pos:dist(player.pos) < 5 and obj.isTargetable end)
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
	local shortcut = ObjectManager.EventObject(function(obj) return obj.name == "Shortcut" and obj.pos:dist(player.pos) < 3 and obj.isTargetable end)
	if shortcut.valid then
		player:rotateTo(shortcut.pos)
		TaskManager:Interact(shortcut, function() self:OnShortCut() end)
	end	

	return false
end

function XSquadron:HandleTown(mapId)

	local map = self.grid[tostring(mapId)]

	if Game.CompanySeals < self.seal_cost[self.menu["MISSION_ID"].int + 1] then
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
		TaskManager:WalkToWaypoint(self.deliverRoute.waypoints[self.deliverRoute.index], function(waypoint) self:OnWalkToWayPoint(waypoint) end)
	end
end


function XSquadron:HandleMission(mapId)
	if mapId == 9 then
		self.toto:Tick(self)
	elseif mapId == 37 then
		self.stonevigil:Tick(self)
	elseif mapId == 45 then
		self.brayflox:Tick(self)
	elseif 46 then
		self.hatali:Tick(self)
	end
end


function XSquadron:Exit()
	
	if ((os.clock() - self.lastExit) < 5) then return end

	local exit = ObjectManager.EventObject(function(obj) return obj.name == "Exit" end)

	if exit.valid then
		TaskManager:Interact(exit, function() self:OnExitSquadron() end)
		self.lastExit = os.clock()
	end

end

function XSquadron:OnWalkToWayPoint(waypoint)

	if not self:InTown() then
		if (self.route.index < #self.route.waypoints) then
			self.route.index = self.route.index + 1
		end
	else
		if (self.deliverRoute.index < #self.deliverRoute.waypoints) then
			self.deliverRoute.index = self.deliverRoute.index + 1
		end
	end

end

function XSquadron:DeathWatch()
	if player.isDead or player.health == 0 and not self.died then
		self.died = true
		TaskManager:Stop()
	elseif self.died and player.health > 0 then
		TaskManager:Stop()
		self.died = false
		self.route = Route()
		self.stats.times_died = self.stats.times_died + 1
		self.log:print("Oh noes we died! reviving....")
		self.menu["TIMES_DIED"].str = "Times We've Died: " .. tostring(self.stats.times_died)
	end
end

function XSquadron:HandleMobs(range)

	local target = TargetManager.Target

	if not target.valid or target.kind ~= 2 or target.subKind ~= 5 then

		local objects = ObjectManager.Battle( function(target) 
			return self.b_filter[target.name] ~= true and target.isTargetable and not target.isDead and target.pos:dist(player.pos) < range 
		end )

		for i, obj in ipairs(objects) do
			self.log:print("Set new Target: " .. obj.name)
			Keyboard.SendKey(38)
			TargetManager.SetTarget(obj)
			break
		end

	else
		player:rotateTo(target.pos)
	end
	
end

function XSquadron:Draw()
	
	local maxDrawDistance = self.menu["DRAW_SETTINGS"]["MAX_DRAW_DISTANCE"].int

	if self.menu["DRAW_SETTINGS"]["DRAW_WAYPOINTS"].bool then
		self:DrawNodes(maxDrawDistance)
	end	
end

function XSquadron:DrawNodes(maxDistance)

	local currentMapId = tostring(AgentModule.currentMapId)

	if self.grid[currentMapId] ~= nil and self.grid[currentMapId].nodes ~= nil then
		for i, waypoint in ipairs(self.grid[currentMapId].nodes.waypoints) do
			if waypoint.pos:dist(player.pos) < maxDistance then
				Graphics.DrawCircle3D(waypoint.pos, 20, 1, Colors.Green)
				if self.menu["DRAW_SETTINGS"]["DEBUG_INFO"].bool then
					Graphics.DrawText3D(waypoint.pos, "[" ..tostring(player.pos:dist(waypoint.pos)).."]("..tostring(i)..")", 10)
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
	return self.towns[AgentModule.currentMapId] == true
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

	self.menu:combobox("Mission Selector", "MISSION_ID", self.missions, 0)

	self.menu:checkbox("Deliver Collectables", "EXPERT_DELIVERY", true) 
	self.menu:checkbox("Auto Pick Best Mission", "AUTO_PICK", true)

	self.menu:label("~=[ Other Settings ]=~") self.menu:space() self.menu:separator()
		self.menu:subMenu("Draw Settings", "DRAW_SETTINGS")
			self.menu["DRAW_SETTINGS"]:checkbox("Draw Waypoints", "DRAW_WAYPOINTS", false) 
			self.menu["DRAW_SETTINGS"]:number("Max Draw Distance", "MAX_DRAW_DISTANCE", 50)
			self.menu["DRAW_SETTINGS"]:checkbox("Draw Debug Info", "DEBUG_INFO", false)

	self.menu:label("~=[ Information ]=~") self.menu:separator() self.menu:space()
	self.menu:label("Missions Entered: 0",  "MISSIONS_ENTERED") 
	self.menu:label("Missions Finished: 0", "MISSIONS_FINISHED")
	self.menu:label("Times We've Died: 0",  "TIMES_DIED")


	self.menu:space() self.menu:space()

	self.menu:button("Start", "BTN_START", function() self:ToggleStartBtn() end)
end

return XSquadron:new()