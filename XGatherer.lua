-- Creates new local class named XGatherer
local XGatherer = Class("XGatherer")

-- First function called when class is initialized
function XGatherer:initialize()

	self.actions = {

		teleport = Action(1,  5),
		sprint   = Action(5,  4),
		mount    = Action(13, 1),

	}

	self.status = {

		running         = false,
		goalWaypoint    = nil,
		last_teleport   = os.clock(),
		gathering       = false,
		last_item       = nil,
		last_mount      = os.clock()
	}

	-- walking route
	self.route  = Route()
	-- gathering queues
	self.queues = {}
	-- Our grid is our map with waypoints
	self.grid   = LoadModule("XScripts", "/Waypoints/Grid")
	-- Log Module
	self.log    = LoadModule("XScripts", "/Utilities/Log")
	self.log.delay = false
	-- active queue
	self.activeQueue = nil
	-- Initializes menu
	self:initializeMenu()

	
	-- Adds our tick function into the game's tick
	Callbacks:Add(CALLBACK_PLAYER_DRAW, function () self:draw() end)
	-- Adds our draw function into the game's draw
	Callbacks:Add(CALLBACK_PLAYER_TICK, function () self:tick() end)
	
	self.log:print("XGatherer Loaded!")

end

function XGatherer:OnWalkToWayPoint(waypoint)

	self.log:print("Finished Walking to waypoint " .. tostring(waypoint.pos))

	local mapId    = tostring(AgentModule.currentMapId)
	local regionId = self:getMapRegion(mapId)

	local closestNode = self:getClosestNodeWaypoint(mapId, regionId, self.activeQueue.nodeId)

	if closestNode ~= nil and self.status.goalWaypoint ~= nil and closestNode.pos ~= self.status.goalWaypoint.pos then
		self.log:print("Found a better goal node! changing routes")
		self.status.goalWaypoint = closestNode
		self.route = Route()
	else
		self.route.index = self.route.index + 1


		if self.route.index > #self.route.waypoints then
			self.route = Route()
		end

	end

end


function XGatherer:tick()
	if TaskManager:IsBusy() or not self.status.running then return end

	if self.status.gathering and AddonManager:getGatheringAddon() == nil then
		self:updateQueue()
		self.status.gathering = false
	end

	local mapId    = tostring(AgentModule.currentMapId)
	local regionId = self:getMapRegion(mapId)

	if self.activeQueue == nil and #self.queues > 0 then
		self.activeQueue = self.queues[1]
		return
	elseif self.activeQueue	 ~= nil then
		if self.activeQueue.mapId ~= mapId and os.clock() - self.status.last_teleport > 8 then

			self.log:print("Teleporting from " .. tostring(mapId) .. " to " .. tostring(self.activeQueue.mapId))
			if self.actions.teleport:canUse() then
				player:teleportTo(self.activeQueue.teleId)
				self.status.last_teleport = os.clock()
			end
			return
		end
	end
	if self.activeQueue == nil or (self.activeQueue.mapId ~= mapId) then return end

	local closestNode         = self:getClosestGatheringNode(self.activeQueue.nodeId)
	local closestWaypointNode = self:getClosestNodeWaypoint(mapId, regionId, self.activeQueue.nodeId)

	if closestWaypointNode == nil then
		if not self.route.finished then
			if self.status.goalWaypoint	== nil then
				print("Node might be too far setting startPos as goal!")
				self.status.goalWaypoint = self.activeQueue.startPos
			else
				local mapWaypoints = self.grid[regionId].maps[mapId].mapWaypoints
				self.route:builda(mapWaypoints, self.status.goalWaypoint.pos)
			end
		else
			self:GoToRoute()
		end
		return
	elseif closestNode.pos:dist(player.pos) >  4 then
		if not self.route.finished then
			if self.status.goalWaypoint == nil and closestWaypointNode ~= nil then
					self.status.goalWaypoint = closestWaypointNode
			elseif self.status.goalWaypoint	 ~= nil then				
				local nodeWaypoints = self.grid[regionId].maps[mapId].mapWaypoints
				self.route:builda(nodeWaypoints, self.status.goalWaypoint.pos)
			end		
		else
			self:GoToRoute()
		end
	elseif closestNode ~= nil and closestNode.pos:dist(player.pos) < 4 then

		player:rotateTo(closestNode.pos)

		local gatheringAddon = AddonManager:getGatheringAddon()
		if gatheringAddon ~= nil then
			self.status.goalWaypoint = nil

			if not gatheringAddon:isGathering() then				
				local selectedName = gatheringAddon:getSelectedItemName()
				local itemToGather = self:getNextQueueItem()

				if itemToGather == nil then return end

				if not string.find(selectedName, itemToGather.name) then
					TaskManager:SelectGatherItem(itemToGather.name)
					return
				end			
				self.log:print("Gathering : " .. selectedName)
				TaskManager:GatherItem()
			end
		else
			self.status.gathering = true
			player:rotateCameraTo(closestNode.pos)
			TaskManager:Interact(closestNode)
		end

	end

end

function XGatherer:CalculateGoal()
	
end

function XGatherer:GoToRoute()

	local currentWaypoint = self.route.waypoints[self.route.index]

	if currentWaypoint == nil then return end
	
	if currentWaypoint.flying and not player.isMounted and self.actions.mount:canUse() then
		self.actions.mount:use()
	elseif self.menu["ACTION_SETTINGS"]["USE_SPRINT"].bool and self.actions.sprint:canUse() then
		self.actions.sprint:use()
	elseif (currentWaypoint.flying and player.isMounted) or not currentWaypoint.flying then
		TaskManager:WalkToWaypoint(self.route.waypoints[self.route.index], function(waypoint) self:OnWalkToWayPoint(waypoint) end)
	end
	
end

function XGatherer:getClosestNodeWithId(nodeId)

	local closestNode = nil
	local distance    = 10000

	for i, obj in pairs(ObjectManager.Gathering) do
		if obj.isTargetable then
			if obj.pos:dist(player.pos) < distance and obj.npcId == nodeId then
				closestNode = obj
				distance = obj.pos:dist(player.pos)
			end
		end
	end

	return closestNode
	
end

function XGatherer:getClosestNodeWaypoint(mapId, regionId, nodeId)

	local node         = nil
	local nodeDistance = 10000

	for i, obj in ipairs(ObjectManager.Gathering) do

		if obj.isTargetable and obj.npcId == tonumber(nodeId) then
			for i , waypoint in ipairs(self.grid[regionId].maps[mapId].mapWaypoints.waypoints) do

				local distanceToPlayer = waypoint.pos:dist(player.pos)

				if waypoint.pos:dist(obj.pos) < 4 and distanceToPlayer < nodeDistance then
						node         = waypoint
						nodeDistance = distanceToPlayer
				end

			end

		end
	end
	return node

end

function XGatherer:draw()
	
	local maxDrawDistance = self.menu["DRAW_SETTINGS"]["MAX_DRAW_DISTANCE"].int

	local last_waypoint = nil

	if #self.route.waypoints > 1 then

		for i, waypoint in ipairs(self.route.waypoints) do
			if last_waypoint ~= nil then
				Graphics.DrawLine3D(last_waypoint.pos, waypoint.pos, Colors.Green)
			end
			last_waypoint = waypoint
		end

	end


	if self.menu["DRAW_SETTINGS"]["DRAW_GATHERABLE_NODES"].bool then
		self:drawGatherableNodes(maxDrawDistance)
	end

	if self.menu["DRAW_SETTINGS"]["DRAW_POSSIBLE_NODES"].bool then
		self:drawPossibleNodes(maxDrawDistance)
	end	

	if self.menu["DRAW_SETTINGS"]["DRAW_WAYPOINTS"].bool then
		local currentMapId = tostring(AgentModule.currentMapId)
		local currentRegionId = self:getMapRegion(currentMapId)


		if self.grid[currentRegionId] ~= nil and self.grid[currentRegionId].maps[currentMapId] ~= nil and self.grid[currentRegionId].maps[currentMapId] ~= nil then				

			if self.grid[currentRegionId].maps[currentMapId].mapWaypoints ~= nil then
				for i, waypoint in ipairs(self.grid[currentRegionId].maps[currentMapId].mapWaypoints.waypoints) do
					if waypoint.pos:dist(player.pos) < maxDrawDistance then
						Graphics.DrawCircle3D(waypoint.pos, 20, 1, Colors.Green)
					end
				end
			end
		end
		local last_waypoint = nil
		if #self.route.waypoints > 1 then

			for i, waypoint in ipairs(self.route.waypoints) do

				if last_waypoint ~= nil and i >= self.route.index then
					Graphics.DrawLine3D(last_waypoint.pos, waypoint.pos, Colors.Blue)
				end
				last_waypoint = waypoint
			end

		end
	end

	if self.status.goalWaypoint ~= nil then
		Graphics.DrawCircle3D(self.status.goalWaypoint.pos, 100, 1, Colors.Red)
	end
end

function XGatherer:buildGatherQueue(regionId, mapId, npcId)
	

	self.log:print("Building new Item Gather Queue [" .. npcId .. "]")
	
	local queue = {

		items    = {},
		mapId    = mapId,
		teleId   = self.grid[regionId].maps[mapId].telePoint,
		regionId = regionId,
		nodeId   = npcId,
		index    = #self.queues + 1,
		startPos = Waypoint(self.grid[regionId].maps[mapId].nodes[tostring(npcId)].startPos),

	}	

	for i, itemInfo in ipairs(self.grid[regionId].maps[mapId].nodes[tostring(npcId)].nodeItems) do

		local menuValue = self.menu[regionId][mapId][npcId][itemInfo.name].int

		if menuValue > 0 then

			local itemCopy  = itemInfo
			local itemCount = InventoryManager.GetItemCount(itemInfo.id)
			self.log:print("Adding " .. menuValue .. " " .. itemInfo.name .. "(s), Currently Have " .. itemCount)

			itemCopy.initialAmount  = itemCount
			itemCopy.amountToGather = menuValue
			itemCopy.finishValue    = itemCount + menuValue

			table.insert(queue.items, itemCopy)
		end
	end

	if #queue.items > 0 then
		table.insert(self.queues, queue)
		self.log:print("New Queue Size " ..  tostring(#self.queues))
		if self.menu["AUTO_START"].bool and not self.status.running then
			self.log:print("Auto Starting Queue")
			self.menu["BTN_START"].str = "Stop"
			self.status.running = true
			self.route = Route()
		end
	else
		self.log:print("Tried adding Queue with no items!")
	end

end

function XGatherer:updateQueue()
	
	if #self.activeQueue.items == 0 then
		table.remove(self.queues, self.activeQueue.index)
		self.activeQueue = nil
	end
	
	if #self.queues == 0 then
		self.log:print("Finished All Gathering Queues, Stopping Bot!")
		self.menu["BTN_START"].str = "Start"
		self.status.running   = false
		self.status.last_item = nil
		self.activeQueue = nil
	end

end


function XGatherer:getNextQueueItem()
	
	for i, item in ipairs(self.activeQueue.items) do

		if InventoryManager.GetItemCount(item.id) > item.finishValue then
			table.remove(self.activeQueue.items, i)
			self.log:print("Finished Gathering " .. item.amountToGather .. "(s) " .. item.name)			
		else
			self.status.last_item = item
			return item
		end
	end

	if self.status.last_item ~= nil then
		return self.status.last_item
	end

end

function XGatherer:drawGatherableNodes(maxDistance)
	local nodes = ObjectManager.Gathering

	for i, node in ipairs(nodes) do
		if node.isTargetable and node.pos:dist(player.pos) < maxDistance then
			Graphics.DrawCircle3D(node.pos, 20, 1, Colors.Yellow)
		end
	end

end

function XGatherer:drawPossibleNodes(maxDistance)
	local nodes = ObjectManager.Gathering

	for i, node in ipairs(nodes) do
		if not node.isTargetable and node.pos:dist(player.pos) < maxDistance then
			Graphics.DrawCircle3D(node.pos, 20, 1, Colors.Red)

		end
	end

end

function XGatherer:getClosestGatheringNode(nodeId)
	local closestNode = nil
	local distance    = 10000

	for i, obj in pairs(ObjectManager.Gathering) do
		if obj.isTargetable and obj.npcId == tonumber(nodeId) then
			if obj.pos:dist(player.pos) < distance then
				closestNode = obj
				distance = obj.pos:dist(player.pos)
			end
		end
	end

	return closestNode
end



-- This function builds our menu
function XGatherer:initializeMenu()
	-- Creates new menu
	self.menu = Menu("XGatherer")
	-- Adds label , separator & space
	self.menu:label("~=[ Supported Maps ]=~") self.menu:separator() self.menu:space()
		-- Loops our grid for supported maps
		for regionId, regionInfo in ipairs(self.grid) do
			-- Adds sub menu with region name
			self.menu:subMenu(regionInfo.regionName, tostring(regionId))

			-- loops our maps inside region
			for mapId, mapInfo in pairs(self.grid[regionId].maps) do
				-- Adds submenu with map name
				self.menu[regionId]:subMenu(mapInfo.mapName, mapId)
				for nodeId, nodeInfo in pairs(self.grid[regionId].maps[mapId].nodes) do

					self.menu[regionId][mapId]:subMenu(nodeInfo.nodeName, nodeId)

					for i, itemInfo in ipairs(nodeInfo.nodeItems) do
						self.menu[regionId][mapId][nodeId]:number(itemInfo.name, itemInfo.name, 100)
					end
					
					self.menu[regionId][mapId][nodeId]:button("Add to Queue", "QUEUE", function()
						self:buildGatherQueue(regionId, mapId, nodeId)
					end)

				end

				self.menu[regionId]:space()
			end

			self.menu:space()
		end

	self.menu:separator() self.menu:space()
	self.menu:label("~=[ Other Settings ]=~") self.menu:space() self.menu:separator()
		self.menu:subMenu("Draw Settings", "DRAW_SETTINGS")
			self.menu["DRAW_SETTINGS"]:checkbox("Draw Waypoints", "DRAW_WAYPOINTS", false) 
			self.menu["DRAW_SETTINGS"]:checkbox("Draw Gatherable Nodes", "DRAW_GATHERABLE_NODES", false)
			self.menu["DRAW_SETTINGS"]:checkbox("Draw Possible Nodes", "DRAW_POSSIBLE_NODES", false)
			self.menu["DRAW_SETTINGS"]:number("Max Draw Distance", "MAX_DRAW_DISTANCE", 50)

	self.menu:space()
		self.menu:subMenu("Action Settings", "ACTION_SETTINGS")
			self.menu["ACTION_SETTINGS"]:checkbox("Use Sprint", "USE_SPRINT", true)
			self.menu["ACTION_SETTINGS"]:checkbox("Use Mount", "USE_MOUNT", true)
			self.menu["ACTION_SETTINGS"]:separator()
			self.menu["ACTION_SETTINGS"]:label("Gathering Actions")
			self.menu["ACTION_SETTINGS"]:separator()
			self.menu["ACTION_SETTINGS"]:checkbox("Use Sharp Vision", "USE_SHARP_VISION", false)
			self.menu["ACTION_SETTINGS"]:checkbox("Use Sharp Vision II", "USE_SHARP_VISION2", false)


	self.menu:space() self.menu:space() self.menu:space()
	self.menu:checkbox("Auto Start Queues", "AUTO_START", true)
	self.menu:button("Start", "BTN_START", function()
		if self.status.running then
			self.menu["BTN_START"].str = "Start"
			self.status.running = false
		else
			if #self.queues > 0 then
				self.menu["BTN_START"].str = "Stop"
				self.status.running = true
				self.route = Route()
			else
				print("Tried to start gathering with no items added to queue!")
			end
		end
	end)

end

function XGatherer:getMapRegion(mapId)
	
	if mapId == "4" or mapId == "5" or mapId == "6" or mapId == "7" then
		return 1
	elseif mapId == "20" or mapId == "21" or mapId == "22" or mapId == "23" then
		return 2
	elseif mapId == "53" then 
		return 3
	elseif mapId == "15" or mapId == "17" then 
		return 4
	else
		return 0
	end
end


XGatherer:new()