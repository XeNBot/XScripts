local XSquadron = Class("XSquadron")

function XSquadron:initialize()

	-- grid
	self.grid     = LoadModule("XScripts", "/Waypoints/SquadronGrid")
	-- missions
	self.hatali   = LoadModule("XScripts", "/Missions/Hatali")
	self.toto     = LoadModule("XScripts", "/Missions/TotoRak")
	self.brayflox = LoadModule("XScripts", "/Missions/Brayflox")

	-- Battle Name Filter
	self.b_filter = {

		["Brayflox Alltalks"] = true,
		["Comet Chaser"]      = true,
		["Goblin Pathfinder"] = true,
	}

	self.actions = {
		limitBreak = Action(19, 4)
	}

	self.stats = {
		missions_started  = 0,
		missions_finished = 0,
		times_died        = 0
	}

	self.started = false
	self.route   = Route()
	self.died    = false
	self.lastShortcut = 0

	self:InitializeMenu()

	Callbacks:Add(CALLBACK_PLAYER_TICK, function () self:Tick() end)
	Callbacks:Add(CALLBACK_PLAYER_DRAW, function () self:Draw() end)

end

function XSquadron:Tick()
	if not self.started or ((os.clock() - self.lastShortcut) < 5) then return end
	
	self:DeathWatch()

	if self:Interactables() then return end

	local currentMapId = AgentModule.currentMapId

	if currentMapId == 308 then
		self:HandleLobby()
	else
		self:HandleMission(currentMapId)					
	end
end

function XSquadron:OnEnterSquadron()	
	self.stats.missions_started = self.stats.missions_started + 1
	self.menu["MISSIONS_ENTERED"].str = "Missions Entered: " .. tostring(self.stats.missions_started)
	self.route = Route()
end

function XSquadron:OnExitSquadron()
	self.stats.squadrons_finished = self.stats.missions_finished + 1
	self.menu["MISSIONS_FINISHED"].str = "Missions Finished: " .. tostring(self.stats.missions_finished)
	self.route = Route()
end

function XSquadron:OnShortCut()
	self.lastShortcut = os.clock()
	self.route = Route()
end

function XSquadron:InteractFilter(obj)
	return obj.pos:dist(player.pos) < 5 and obj.isTargetable
end

function XSquadron:HandleLobby()
	local sergeant = ObjectManager.EventNpcObject(function(obj) return string.find(obj.name, "Sergeant") end)

	if sergeant.valid and not TaskManager:IsBusy() then
		TaskManager:EnterSquadron(sergeant, self.menu["MISSION_ID"].int, function () self:OnEnterSquadron() end)
	end
end

function XSquadron:Interactables()
	
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

function XSquadron:HandleMission(mapId)
	if mapId == 9 then
		self.toto:Tick(self)
	elseif mapId == 45 then
		self.brayflox:Tick(self)
	elseif 46 then
		self.hatali:Tick(self)
	end
end


function XSquadron:Exit()
	
	local exit = ObjectManager.EventObject(function(obj) return obj.name == "Exit" end)

	if exit.valid then
		TaskManager:Interact(exit, function() self:OnExitSquadron() end)
	end

end

function XSquadron:OnWalkToWayPoint(waypoint)

	if (self.route.index < #self.route.waypoints) then
		self.route.index = self.route.index + 1
	end

end

function XSquadron:DeathWatch()
	if player.isDead and not self.died then
		self.died = true
	elseif self.died and player.health > 0 then
		TaskManager:Stop()
		self.died = false
		self.route = Route()
		self.stats.times_died = self.stats.times_died + 1
		self.menu["TIMES_DIED"].str = "Times We've Died: " .. tostring(self.stats.times_died)
	end
end

function XSquadron:HandleMobs(range)

	local target = TargetManager.Target

	if not target.valid or target.kind ~= 2 or target.subKind ~= 5 then

		local objects = ObjectManager.Battle( function(target) 
			return target.name ~= "Goblin Pathfinder" and target.name ~= "Brayflox Alltalks" and target.name ~= "Comet Chaser" and target.isTargetable and not target.isDead and target.pos:dist(player.pos) < range 
		end )

		for i, obj in ipairs(objects) do
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

function XSquadron:InitializeMenu()
	
	self.menu = Menu("XSquadron")

	self.menu:label("~=[ XSquadron Ver 1.0 ]=~") self.menu:separator() self.menu:space()

	self.menu:combobox("Mission Selector", "MISSION_ID",
	 	{
			"Hatali",
			"Torok-Rak",
			"Brayflox's Longstop"
		}, 0)

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

	self.menu:button("Start", "BTN_START", function()
		if not self.started then
			self.menu["BTN_START"].str = "Stop"
			self.started = true
		else
			self.menu["BTN_START"].str = "Start"
			self.started = false
		end
	end)
end

return XSquadron:new()