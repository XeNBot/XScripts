-- Creates new local class named XGatherer
local XGatherer = Class("XGatherer")

-- First function called when class is initialized
function XGatherer:initialize()

	self.actions = {

		teleport     = Action(1,  5),
		sprint       = Action(5,  4),
		mount        = Action(13, 1),

		-- BTN
		harvestii    = Action(1, 224),
		twelvebounty = Action(1, 282),
		bountifulii  = Action(1, 273),

		-- MIN
		yieldii      = Action(1, 4073),
		kingyieldii  = Action(1, 241),


		-- Items 
		cordial      = Action(2, 6141),
		hicordial    = Action(2, 12669),
		wcordial     = Action(2, 16911),

	}

	self.status = {

		running         = false,
		goalWaypoint    = nil,
		last_teleport   = 0,
		gathering       = false,
		last_item       = nil,
		last_mount      = 0
	}

	-- walking route
	self.route  = Route()
	-- gathering queues
	self.queues = {}
	-- Our grid is our map with waypoints
	self.grid   = LoadModule("XScripts", "/Waypoints/GatheringGrid")
	-- Log Module
	self.log    = LoadModule("XScripts", "/Utilities/Log")
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

	local agentMap = AgentManager.GetAgent("Map")
	if agentMap ~= nil then
		local mapId    = tostring(agentMap.currentMapId)
		local regionId = self:getMapRegion(mapId)

		local closestNode = self:getClosestNodeWaypoint(mapId, regionId, self.activeQueue.dataIds)

		if closestNode ~= nil and self.status.goalWaypoint ~= nil and closestNode.pos ~= self.status.goalWaypoint.pos then
			self.log:print("Found a better goal node! changing routes")
			self.status.goalWaypoint = closestNode
			self.route = Route()
		else
			self.route.index = self.route.index + 1		
		end
	end
end


function XGatherer:tick()
	if TaskManager:IsBusy() or 
		not self.status.running or
		 (os.clock() - self.status.last_mount < 2) or
		 (os.clock() - self.status.last_teleport < 10)
	then return end

	local gatheringAddon = AddonManager.GetAddon("Gathering")
	local agentMap       = AgentManager.GetAgent("Map")

	self:updateQueue(gatheringAddon)

	if gatheringAddon ~= nil then
		return self:gatherNextItem(gatheringAddon)
	end
	
	local mapId    = 0
	local regionId = 0

	if agentMap ~= nil then
		mapId    = tostring(agentMap.currentMapId)
		regionId = self:getMapRegion(mapId)
	end

	if self.activeQueue == nil and #self.queues > 0 then
		self.activeQueue = self.queues[1]
		return
	elseif self.activeQueue	 ~= nil then
		if os.clock() - self.status.last_teleport < 10 then return end
		if self.activeQueue.multimap ~= nil and tostring(self.activeQueue.multimap) ~= tostring(mapId) and not self.activeQueue.multidone and mapId ~= tostring(self.activeQueue.mapId) then

			self.log:print("Teleporting from " .. tostring(mapId) .. " to " .. tostring(self.activeQueue.multimap))
			
			if self.actions.teleport:canUse() then
				player:teleportTo(self.activeQueue.teleId)
				self.status.last_teleport  = os.clock()
				self.activeQueue.multidone = true
			end

		elseif self.activeQueue.multimap == nil and self.activeQueue.mapId ~= mapId then

			self.log:print("Teleporting from " .. tostring(mapId) .. " to " .. tostring(self.activeQueue.mapId))
			if self.actions.teleport:canUse() then
				if self.activeQueue.customTele ~= nil then
					player:teleportTo(self.activeQueue.customTele)
				else
					player:teleportTo(self.activeQueue.teleId)
				end
				self.status.last_teleport = os.clock()
			end
		end
	end

	if self.activeQueue == nil or (self.activeQueue.multimap == nil and self.activeQueue.mapId ~= mapId) then return end

	-- Job Check
	if (string.find(self.activeQueue.nodeName, "Tree") or string.find(self.activeQueue.nodeName, "Lush")) and player.classJob ~= 17 then
		self:setJob(17)
		return
	elseif (string.find(self.activeQueue.nodeName, "Mineral") or string.find(self.activeQueue.nodeName, "Rocky")) and player.classJob ~= 16 then
		self:setJob(16)
		return
	end

	local closestNode         = self:getClosestGatheringNode(self.activeQueue.dataIds)
	local closestWaypointNode = self:getClosestNodeWaypoint(mapId, regionId, self.activeQueue.dataIds)

	if closestNode ~= nil and closestNode.pos:dist(player.pos) < 4 then
		
		player:rotateTo(closestNode.pos)
		player:rotateCameraTo(closestNode.pos)
		self:useCordials()
		TaskManager:Interact(closestNode)
	
	elseif closestWaypointNode == nil then
		if not self.route.finished then
			if self.status.goalWaypoint	== nil then
				self.log:print("Node might be too far setting startPos as goal!")
				if self.activeQueue.multimap ~= nil then
					self.status.goalWaypoint = self.activeQueue.multipoint
				elseif self.activeQueue.startPos2 ~= nil and self.activeQueue.startPos.pos:dist(player.pos) < 5 then
					self.status.goalWaypoint = self.activeQueue.startPos2
				else		
					self.status.goalWaypoint = self.activeQueue.startPos
				end
			else
				local mapWaypoints = self.grid[regionId].maps[mapId].mapWaypoints
				self.route:builda(mapWaypoints, self.status.goalWaypoint.pos)
			end
		else
			self:GoToRoute()
		end
	elseif closestNode ~= nil and closestNode.pos:dist(player.pos) >  4 then
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
	end

end

function XGatherer:GoToRoute()
	local currentWaypoint = self.route.waypoints[self.route.index]

	if currentWaypoint == nil then self.route = Route()  return end

	if self.menu["ACTION_SETTINGS"]["USE_MOUNT"].bool and self.status.goalWaypoint.pos:dist(player.pos) >= self.menu["ACTION_SETTINGS"]["MOUNT_DISTANCE"].int
	and not player.isMounted and self.actions.mount:canUse() then
		self.log:print("Using Mount!")
		self.actions.mount:use()
		self.status.last_mount = os.clock()
		self.log:print("Using Mount!")
	elseif self.menu["ACTION_SETTINGS"]["USE_SPRINT"].bool and not player.isMounted and self.actions.sprint.recastTime == 0 then
		self.log:print("Using Sprint!")
		self.actions.sprint:use()
	elseif (currentWaypoint.flying and player.isMounted) or not currentWaypoint.flying then
		TaskManager:WalkToWaypoint(self.route.waypoints[self.route.index], function(waypoint) self:OnWalkToWayPoint(waypoint) end)
	end
	
end

function XGatherer:getClosestNodeWaypoint(mapId, regionId, dataIds)

	local node         = nil
	local nodeDistance = 10000



	for i, obj in ipairs(ObjectManager.Gathering) do


		if obj.isTargetable and dataIds[obj.dataId] ~= nil then
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

function XGatherer:getClosestGatheringNode(dataIds)
	local closestNode = nil
	local distance    = 10000

	for i, obj in pairs(ObjectManager.Gathering) do
		if obj.isTargetable and dataIds[obj.dataId] ~= nil then
			if obj.pos:dist(player.pos) < distance then
				closestNode = obj
				distance = obj.pos:dist(player.pos)
			end
		end
	end

	return closestNode
end


function XGatherer:draw()
	local maxDrawDistance = self.menu["DRAW_SETTINGS"]["MAX_DRAW_DISTANCE"].int

	if self.menu["DRAW_SETTINGS"]["DRAW_GATHERABLE_NODES"].bool then
		self:drawGatherableNodes(maxDrawDistance)
	end

	if self.menu["DRAW_SETTINGS"]["DRAW_POSSIBLE_NODES"].bool then
		self:drawPossibleNodes(maxDrawDistance)
	end	

	if self.menu["DRAW_SETTINGS"]["DRAW_WAYPOINTS"].bool then

		local agentMap = AgentManager.GetAgent("Map")

		if agentMap == nil then return end

		local currentMapId = tostring(AgentManager.GetAgent("Map").currentMapId)
		local currentRegionId = self:getMapRegion(currentMapId)


		if self.grid[currentRegionId] ~= nil and self.grid[currentRegionId].maps[currentMapId] ~= nil and self.grid[currentRegionId].maps[currentMapId] ~= nil then				

			if self.grid[currentRegionId].maps[currentMapId].mapWaypoints ~= nil then
				for i, waypoint in ipairs(self.grid[currentRegionId].maps[currentMapId].mapWaypoints.waypoints) do
					if waypoint.pos:dist(player.pos) < maxDrawDistance then
						Graphics.DrawCircle3D(waypoint.pos, 20, 1, Colors.Green)

						if self.menu["DRAW_SETTINGS"]["DEBUG_INFO"].bool then

							Graphics.DrawText3D(waypoint.pos, "[" ..tostring(math.floor(player.pos:dist(waypoint.pos)) / 100).."]("..tostring(i)..")", 20, RGBA(255, 248, 159, 255))

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

		if self.menu["DRAW_SETTINGS"]["DRAW_ROUTE"].bool then
			local last_waypoint = nil
			if #self.route.waypoints > 1 then

				for i, waypoint in ipairs(self.route.waypoints) do

					if last_waypoint ~= nil and waypoint ~= nil and i >= self.route.index then
						Graphics.DrawLine3D(last_waypoint.pos, waypoint.pos, Colors.Blue)
					end
					last_waypoint = waypoint
				end

			end
		end
	end	
end

function XGatherer:buildGatherQueue(regionId, mapId, nodeId)
	

	self.log:print("Building new Item Gather Queue for " .. self.menu[regionId][mapId][nodeId].str .. "")
	
	local multipoint = (self.grid[regionId].maps[mapId].nodes[nodeId].multimap ~= nil and self.grid[regionId].maps[mapId].nodes[nodeId].multimap) or nil
	
	local queue = {

		items      = {},
		mapId      = mapId,
		teleId     = self.grid[regionId].maps[mapId].telePoint,
		customTele = self.grid[regionId].maps[mapId].nodes[nodeId].customTele,
		regionId   = regionId,
		nodeId     = nodeId,
		index      = #self.queues + 1,
		nodeName   = self.menu[regionId][mapId][nodeId].str,
		startPos   = Waypoint(self.grid[regionId].maps[mapId].nodes[nodeId].startPos),
		startPos2  = self.grid[regionId].maps[mapId].nodes[nodeId].startPos2 ~= nil and Waypoint(self.grid[regionId].maps[mapId].nodes[nodeId].startPos2),
		multimap   = multipoint,
		multidone  = false,
		multipoint = (multipoint ~= nil and Waypoint(self.grid[regionId].maps[tostring(multipoint)].nodes[nodeId].startPos)) or nil,
		dataIds    = self.grid[regionId].maps[mapId].nodes[nodeId].dataIds,

	}	

	for i, itemInfo in ipairs(self.grid[regionId].maps[mapId].nodes[nodeId].nodeItems) do

		local menuValue = self.menu[regionId][mapId][nodeId][itemInfo.name].int

		if menuValue > 0 then

			local itemCopy  = itemInfo
			local itemCount = InventoryManager.GetItemCount(itemInfo.id)
			self.log:print("Adding " .. menuValue .. " " .. itemInfo.name .. "(s), Currently Have " .. itemCount)

			itemCopy.initialAmount  = itemCount
			itemCopy.amountToGather = menuValue
			itemCopy.finishValue    = itemCount + menuValue

			table.insert(queue.items, itemCopy)

			--[[self.item_widget:label(itemInfo.name, "NAME_" .. itemInfo.name)
			self.item_widget:label(" Amount : " .. tostring(menuValue), "AMOUNT_" .. itemInfo.name)
			self.item_widget:button("Remove", "REMOVE_ITEM_" .. itemInfo.name , function()
				
				table.remove(queue.items, #queue.items)
				self.item_widget["AMOUNT_" .. itemInfo.name]:remove()
				self.item_widget["NAME_" .. itemInfo.name]:remove()
				self.item_widget["SEPARATOR_" .. itemInfo.name]:remove()
				self.item_widget["REMOVE_ITEM_" .. itemInfo.name]:remove()

				print("Item Queue Size " .. tostring(#queue.items))
			end)
			self.item_widget:label("----------------", "SEPARATOR_" .. itemInfo.name)]]--
		end
	end

	if #queue.items > 0 then
		table.insert(self.queues, queue)
		if self.menu["AUTO_START"].bool and not self.status.running then
			self.log:print("Auto Starting Queue!")
			self.menu["BTN_START"].str = "Stop"
			self.status.running = true
			self.route = Route()
		end
	else
		self.log:print("Tried adding Queue with no items!")
	end

end


function XGatherer:updateQueue(gatheringAddon)

	if self.activeQueue ~= nil then

		if #self.activeQueue.items == 0 then
			self.log:print("Finished Current Gatheringg Queue")
			for i, q in ipairs(self.queues) do
				if q.index == self.activeQueue.index then
					table.remove(self.queues, i)
					self.activeQueue = nil
					break
				end
			end
		end
	end

	if #self.queues == 0 then
		self.activeQueue = nil
		if gatheringAddon == nil then
			self.log:print("Finished All Gathering Queues, Stopping Bot after node!")
			self.menu["BTN_START"].str = "Start"
			self.status.running   = false
		end
	end

end


function XGatherer:getNextQueueItem()
	
	if self.activeQueue ~= nil then

		for i, item in ipairs(self.activeQueue.items) do

			if InventoryManager.GetItemCount(item.id) > item.finishValue then
				table.remove(self.activeQueue.items, i)
				self.log:print("Finished Gathering " .. item.amountToGather .. "(s) " .. item.name)			
			else
				self.status.last_item = item
				return item
			end
		end	
	elseif self.status.last_item ~= nil then
		return self.status.last_item
	end
end

function XGatherer:gatherNextItem(gatheringAddon)
	
	if self.route.finished then self.route = Route() end

	self.status.goalWaypoint = nil

	self:useNodeActions()

	if not gatheringAddon:isGathering() then				
		local itemToGather = self:getNextQueueItem()

		if itemToGather == nil then return end

		self.log:print("Gathering Item: " .. itemToGather.name .. ", Need to gather " .. tostring((itemToGather.finishValue - InventoryManager.GetItemCount(itemToGather.id))) .. " more")
		TaskManager:GatherItem(itemToGather.id)
	end
end

function XGatherer:useNodeActions()

	if self.activeQueue ~= nil then

		local itemMenu = self.menu[self.activeQueue.regionId][self.activeQueue.mapId][self.activeQueue.nodeId]

		if itemMenu["ACTIONS"].bool then
			if itemMenu["GATHER_MODE"].int == 0 then
				if player.classJob == 17 then
					if self.actions.harvestii:canUse() and not player:hasStatus(219) then
						self.log:print("Using Blessed Harvest II")
						self.actions.harvestii:use()
					end
				else
					if self.actions.kingyieldii:canUse() and not player:hasStatus(219) then
						self.log:print("Using Kings Yield II")
						self.actions.kingyieldii:use()
					end
				end			
			else

				if player.classJob == 17 then
					if self.actions.twelvebounty:canUse() and not player:hasStatus(825) then
						self.log:print("Using The Twelve Bounty")
						self.actions.twelvebounty:use()
					end
					if self.actions.bountifulii:canUse() and not player:hasStatus(1286) then
						self.log:print("Using Bountiful Harvest II")
						self.actions.bountifulii:use()
					end
				else

					if self.actions.twelvebounty:canUse() and not player:hasStatus(825) then
						self.log:print("Using The Twelve Bounty")
						self.actions.twelvebounty:use()
					end
					if self.actions.yieldii:canUse() and not player:hasStatus(1286) then
						self.log:print("Using Bountiful Yield II")
						self.actions.yieldii:use()
					end

				end			
			end
		end

	end
	
end


function XGatherer:useCordials()
	if self.menu["CORDIAL"].bool then
		if self.actions.wcordial:canUse() and player.missingGP >= 150 then
			self.log:print("Using Watered Cordial")
			self.actions.wcordial:use()
		elseif  self.actions.cordial:canUse() and player.missingGP >= 300 then
			self.log:print("Using Cordial")
		    self.actions.cordial:use()
		elseif self.actions.hicordial:canUse() and player.missingGP >= 400 then
			self.log:print("Using Hi Cordial")
			self.actions.hicordial:use()
		end
	end
end

function XGatherer:setJob(job)

	if player.classJob == job then return end

	local iconId = job + 62800

	-- Loops through all 18 HotBars
	for hotbar = 0, 17 do
		-- Loops through all 16 slots in hotbar
		for slotId = 0, 15 do
			local slot = HotBarManager[hotbar].slot[slotId]
			if slot.icon == iconId then
				slot:execute()
			end
		end
	end
end

function XGatherer:drawGatherableNodes(maxDistance)
	local nodes = ObjectManager.Gathering

	for i, node in ipairs(nodes) do
		if node.isTargetable and node.pos:dist(player.pos) < maxDistance then
			Graphics.DrawCircle3D(node.pos, 20, 1, Colors.Yellow)

			if self.menu["DRAW_SETTINGS"]["DEBUG_INFO"].bool then
				Graphics.DrawText3D(node.pos, "Id: [" .. tostring(node.npcId) .. "]" .. " Dist: [" ..tostring(math.floor(player.pos:dist(node.pos)  * 10) / 10).."] Data: [" .. tostring(node.dataId) .. "]", 20, RGBA(255, 248, 159, 255))
			end
		end
	end

end

function XGatherer:drawPossibleNodes(maxDistance)
	local nodes = ObjectManager.Gathering

	for i, node in ipairs(nodes) do
		if not node.isTargetable and node.pos:dist(player.pos) < maxDistance then
			Graphics.DrawCircle3D(node.pos, 20, 1, Colors.Red)
			if self.menu["DRAW_SETTINGS"]["DEBUG_INFO"].bool then
				Graphics.DrawText3D(node.pos, "Id: [" .. tostring(node.npcId) .. "]" .. " Dist: [" ..tostring(math.floor(player.pos:dist(node.pos)  * 10) / 10).."] Data: [" .. tostring(node.dataId) .. "]", 20, RGBA(255, 248, 159, 255))
			end
		end
	end

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
				for nodeId, nodeInfo in ipairs(self.grid[regionId].maps[mapId].nodes) do

					self.menu[regionId][mapId]:subMenu(nodeInfo.nodeName, nodeId)

					for i, itemInfo in ipairs(nodeInfo.nodeItems) do
						self.menu[regionId][mapId][nodeId]:number(itemInfo.name, itemInfo.name, 100)
					end
					
					self.menu[regionId][mapId][nodeId]:checkbox("Use Actions", "ACTIONS", true)

					self.menu[regionId][mapId][nodeId]:combobox("Gather Mode", "GATHER_MODE", {"Normal", "Shards / Crystals"}, 0)

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
			self.menu["DRAW_SETTINGS"]:checkbox("Draw Routes", "DRAW_ROUTE", true) 
			self.menu["DRAW_SETTINGS"]:checkbox("Draw Waypoints", "DRAW_WAYPOINTS", false) 
			self.menu["DRAW_SETTINGS"]:checkbox("Draw Gatherable Nodes", "DRAW_GATHERABLE_NODES", false)
			self.menu["DRAW_SETTINGS"]:checkbox("Draw Possible Nodes", "DRAW_POSSIBLE_NODES", false)
			self.menu["DRAW_SETTINGS"]:checkbox("Draw Debug Info", "DEBUG_INFO", false)
			self.menu["DRAW_SETTINGS"]:number("Max Draw Distance", "MAX_DRAW_DISTANCE", 50)

	self.menu:space()
		self.menu:subMenu("Action Settings", "ACTION_SETTINGS")
			self.menu["ACTION_SETTINGS"]:checkbox("Use Sprint", "USE_SPRINT", true)
			self.menu["ACTION_SETTINGS"]:checkbox("Use Mount", "USE_MOUNT", true)
			self.menu["ACTION_SETTINGS"]:number("Min Distance for Mount", "MOUNT_DISTANCE", 20)
			self.menu["ACTION_SETTINGS"]:separator()
			

	self.menu:space() self.menu:space() self.menu:space()
	self.menu:checkbox("Use Cordials", "CORDIAL", true)
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

	--self.item_widget = Menu("XGatherer Item Queue", true)

end

function XGatherer:getMapRegion(mapId)
	
	if mapId == "4" or mapId == "5" or mapId == "6" or mapId == "7" then
		return 1
	elseif mapId == "20" or mapId == "21" or mapId == "22" or mapId == "23" or mapId == "24" then
		return 2
	elseif mapId == "53" then 
		return 3
	elseif mapId == "15" or mapId == "17" then 
		return 4
	elseif mapId == "493" or mapId == "491" then 
		return 5
	elseif mapId == "215" then
		return 6
	elseif mapId == "213" or mapId == "257" then
		return 7
	else
		return 0
	end
end


XGatherer:new()