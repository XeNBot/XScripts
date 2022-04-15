-- Creates new local class named XGatherer
local XGatherer = Class("XGatherer")

-- First function called when class is initialized
function XGatherer:initialize()
	
	print("XGatherer Loaded!")

	self.status = {

		running         = false,
		goalWaypoint    = nil,
		goalObj         = nil,
		currentWaypoint = nil,

		nodeSkills      = false

	}

	self.gatherQueues = {}

	-- Our grid is our map with waypoints
	self:loadGrid()
	-- Initializes menu
	self:initializeMenu()
	
	-- Adds our tick function into the game's tick
	Callbacks:Add(CALLBACK_PLAYER_DRAW, function () self:draw() end)
	-- Adds our draw function into the game's draw
	Callbacks:Add(CALLBACK_PLAYER_TICK, function () self:tick() end)
	
end

function XGatherer:tick()
	if TaskManager:IsBusy() or not self.status.running then return end

	-- Closes windows that could interrupt cursor selector
	self:agentCheck()

	if self.menu["ACTION_SETTINGS"]["USE_SNEAK"].bool then
		--self:checkSneak()
	end

	local closestNode = self:getClosestGatheringNode()

	if closestNode == nil or closestNode.pos:dist(player.pos) >  3.5 then
		self.status.nodeSkills = false

		if self.status.goalWaypoint == nil or self.status.goalObj == nil then
			self.status.goalWaypoint, self.status.goalObj = self:getClosestNodeWithWaypoint()
			if self.status.goalWaypoint ~= nil and self.status.goalObj ~= nil then
				print("Set new goal waypoint : ", self.status.goalWaypoint)
			end
			return
		end
		if self.gatherQueues[self.status.goalObj.npcId] == nil or #self.gatherQueues[self.status.goalObj.npcId] == 0  then
			self:buildGatherQueue(self.status.goalObj.npcId)
			return
		end	
		if self.status.currentWaypoint == nil then
			self.status.currentWaypoint = self:getNextWaypoint(self.status.goalWaypoint)
			if self.status.currentWaypoint ~= nil then
				print("Set new current waypoint : ", self.status.currentWaypoint)
			end
			return
		end

		if self.menu["ACTION_SETTINGS"]["USE_SPRINT"].bool and ActionManager.CanUseAction(5, 4, player.id) then
			ActionManager.UseAction(5, 4, player.id)
		end
		TaskManager:WalkToWaypoint(self.status.currentWaypoint, player, function (waypoint)
			print("Finished Walking to waypoint [".. os.date( "!%a %b %d, %H:%M", os.time() - 7 * 60 * 60 ) .. "]", waypoint)
			self.status.currentWaypoint = nil
		end)

	elseif closestNode ~= nil and closestNode.pos:dist(player.pos) < 3.5 then
		local npcId = closestNode.npcId
		self.status.currentWaypoint = nil
		player:rotateTo(closestNode.pos)

		local gatheringAddon = AddonManager:getGatheringAddon()
		if gatheringAddon ~= nil then
			self.status.goalWaypoint = nil

			if not gatheringAddon:isGathering() then				
				local itemToGather = self:getNextQueueItem(npcId)
				local selectedName = gatheringAddon:getSelectedItemName()

				if itemToGather == nil then return end

				if not string.find(selectedName, itemToGather.name) then
					TaskManager:SelectGatherItem(itemToGather.name)
					return
				end
				if not self.status.nodeSkills then
					self:useNodeSkills(closestNode)
				end
				print("Gathering : " .. selectedName)
				TaskManager:GatherItem(function ()
					self:updateGatherQueue(npcId)
				end)
			end
		else
			if TargetManager.TargetObjId ~= closestNode.id then
				TargetManager.SetTarget(closestNode)
			end
			Keyboard.SendKey(96)
		end
	end
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
		local currentMapId = tostring(AgentModule.currentMapId)
		local currentRegionId = self:getMapRegion(currentMapId)

		if self.grid[currentRegionId] ~= nil and self.grid[currentRegionId].maps[currentMapId] ~= nil and self.grid[currentRegionId].maps[currentMapId] ~= nil then
			for i, waypoint in ipairs(self.grid[currentRegionId].maps[currentMapId].mapWaypoints) do
				if waypoint:dist(player.pos) < maxDrawDistance then
					Graphics.DrawCircle3D(waypoint, 20, 1, Colors.Green)
				end
			end
		end
	end

	if self.status.goalWaypoint ~= nil then
		Graphics.DrawCircle3D(self.status.goalWaypoint, 100, 1, Colors.Red)
	end
end

function XGatherer:agentCheck()
	-- Closes agents that possibly can interrupt target selection
	local uselessAgentIds = { Agents.ChatLog, Agents.Inventory, Agents.ScenarioTree, 
		Agents.RecommendList, Agents.PlayGuide, Agents.QuestRedoHud, Agents.QuestRedo, Agents.GatheringNote
	}
	-- Loops our Agents Table
	for i, agentId in ipairs(uselessAgentIds) do
		-- Checks if the Agent is Active
		if AgentModule:isAgentActive(agentId) then
			-- Closes the Agent
			AgentModule:closeAgent(agentId)
		end
	end
end

function XGatherer:useNodeSkills(nodeObj)

	if self.menu["ACTION_SETTINGS"]["USE_SHARP_VISION"].bool and player.GP > 50 then
		ActionManager.UseAction(1, 235, nodeObj.id)
	end

	if self.menu["ACTION_SETTINGS"]["USE_SHARP_VISION2"].bool and player.GP > 100 then
		ActionManager.UseAction(1, 237, nodeObj.id)
	end

	self.status.nodeSkills = true
end

function XGatherer:checkSneak()
	local hasSneak = false

	for i, status in ipairs(player.status) do
		if status.id == 16 then
			hasSneak = true
			break
		end
	end
	local actionId = player.classJob == 17 and 304 or 303
	if not hasSneak and ActionManager.CanUseAction(1, actionId, TARGET_INVALID_ID) then
		ActionManager.UseAction(1, actionId, player.id)
	end
end

function XGatherer:updateGatherQueue(npcId)
	
	for i, item in ipairs(self.gatherQueues[npcId]) do
		local currentItemCount = InventoryManager.GetItemCount(item.id)
		if currentItemCount >= item.finishValue then
			print("Finished collecting " .. item.amountToGather .. " " .. item.name .. "(s)")
			table.remove(self.gatherQueues[npcId], i)
		end
	end

	if #self.gatherQueues[npcId] == 0 then
		self.gatherQueues[npcId] = nil
	end

end

function XGatherer:getNextQueueItem(npcId)
	
	if self.gatherQueues[npcId] == nil then
		self:buildGatherQueue(npcId)
		return
	end

	for i, item in ipairs(self.gatherQueues[npcId]) do
		return item
	end

end

function XGatherer:buildGatherQueue(npcId)
	self.gatherQueues[npcId] = {}

	print("Building new Item Gather Queue")

	local currentMapId = tostring(AgentModule.currentMapId)
	local currentRegionId = self:getMapRegion(currentMapId)

	if self.grid[currentRegionId] == nil or self.grid[currentRegionId].maps[currentMapId] == nil or self.grid[currentRegionId].maps[currentMapId].nodes[tostring(npcId)] == nil then
		print("Unsuported Gathering Node", npcId, mapId)
		return
	end

	for i, itemInfo in ipairs(self.grid[currentRegionId].maps[currentMapId].nodes[tostring(npcId)].nodeItems) do

		local menuValue = self.menu[currentRegionId][currentMapId][npcId][itemInfo.name].int

		if menuValue > 0 then

			local itemCopy  = itemInfo
			local itemCount = InventoryManager.GetItemCount(itemInfo.id)

			print("Adding " .. menuValue .. " " .. itemInfo.name .. "(s), Currently Have " .. itemCount)

			itemCopy.initialAmount  = itemCount
			itemCopy.amountToGather = menuValue
			itemCopy.finishValue    = itemCount + menuValue

			table.insert(self.gatherQueues[npcId], itemCopy)		
		end
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

function XGatherer:getClosestGatheringNode()
	local closestNode = nil

	for i, obj in pairs(ObjectManager.Gathering) do
		if obj.isTargetable then
			if closestNode == nil or obj.pos:dist(player.pos) < closestNode.pos:dist(player.pos) then
				closestNode = obj
			end
		end
	end

	return closestNode
end

function XGatherer:getClosestNodeWithWaypoint()
	
	local objectGoal      = nil
	local objectWaypoint  = Vector3(1000,1000,1000)
	local currentMapId    = tostring(AgentModule.currentMapId)
	local currentRegionId = self:getMapRegion(currentMapId)
	
	for i, obj in ipairs(ObjectManager.Gathering) do

		if obj.isTargetable then

			for i , waypoint in ipairs(self.grid[currentRegionId].maps[currentMapId].mapWaypoints) do

				local distanceToPlayer = waypoint:dist(player.pos)
				if (waypoint:dist(obj.pos) < 4) then
					if (objectWaypoint:dist(player.pos) > distanceToPlayer) then
						objectWaypoint = waypoint
						objectGoal     = obj
					end
				end

			end

		end
	end
	return objectWaypoint, objectGoal

end

function XGatherer:getNextWaypoint(goalWaypoint)
	
	local currentMapId       = tostring(AgentModule.currentMapId)
	local currentRegionId    = self:getMapRegion(currentMapId)
	local distanceToWaypoint = player.pos:dist(goalWaypoint)
	local nextWaypoint       = Vector3(0,0,0)

	for i , waypoint in ipairs(self.grid[currentRegionId].maps[currentMapId].mapWaypoints) do

		if waypoint:dist(player.pos) > 0.5 then
			local distanceFromGoal   = waypoint:dist(goalWaypoint)
			local distanceFromPlayer = waypoint:dist(player.pos)		
			if (distanceToWaypoint > distanceFromGoal and nextWaypoint:dist(player.pos) > distanceFromPlayer) then

				nextWaypoint = waypoint

			end
		end
	end

	print("Current Distance: ", distanceToWaypoint, "New Distance: ", nextWaypoint:dist(goalWaypoint), nextWaypoint:dist(player.pos))

	return nextWaypoint

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
			self.menu["ACTION_SETTINGS"]:checkbox("Use Sneak", "USE_SNEAK", true)
			self.menu["ACTION_SETTINGS"]:separator()
			self.menu["ACTION_SETTINGS"]:label("Gathering Actions")
			self.menu["ACTION_SETTINGS"]:separator()
			self.menu["ACTION_SETTINGS"]:checkbox("Use Sharp Vision", "USE_SHARP_VISION", false)
			self.menu["ACTION_SETTINGS"]:checkbox("Use Sharp Vision II", "USE_SHARP_VISION2", false)


	self.menu:space() self.menu:space() self.menu:space()
	self.menu:button("Start", "BTN_START", function()
		if self.status.running then
			self.menu["BTN_START"].str = "Start"
			self.status.running = false
		else
			self.menu["BTN_START"].str = "Stop"
			self.status.running = true
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

function XGatherer:loadGrid()

	self.grid = {
		{
			regionName = "The Black Shroud",
			
			maps = {
				
				["4"] = {

					mapName  = "Central Shroud",
					
					nodes = {
						["1"] = {
							nodeName = "Lv35 Mineral Deposit",

							nodeItems = {
								{ name = "Wind Shard", defaultQuantity = 100, id = 4 },
								{ name = "Raw Peridot", defaultQuantity = 100, id = 5136 },
								{ name = "Raw Amethyst", defaultQuantity = 100, id = 5138 },
								{ name = "Granite", defaultQuantity = 100, id = 7008 },
							},
						},						
						["3"] = {

							nodeName = "Lv15 Mature Tree",

							nodeItems = {
								{ name = "Gridanian Chestnut", defaultQuantity = 100, id = 4805 },
								{ name = "Wind Shard", defaultQuantity = 100, id = 4 },
								{ name = "Elm Log", defaultQuantity = 100, id = 5385 },
							},

						},						
						["4"] = {

							nodeName = "Lv15 Lush Vegetation Patch",

							nodeItems = {
								{ name = "Buffalo Beans", defaultQuantity = 100, id = 4818 },
								{ name = "Wind Shard", defaultQuantity = 100, id = 4 },
								{ name = "Marjoram", defaultQuantity = 100, id = 4832 },
								{ name = "Humus", defaultQuantity = 100, id = 5514 },
								{ name = "Tree Toad", defaultQuantity = 100, id = 5051 }
							},

						}
					},

					mapWaypoints = {
						Vector3(-16.6887,-3,27.2289),
						Vector3(4.73689,-1.22114,36.2502),
						Vector3(-15.4894,-3.00096,37.2054),
						Vector3(-12.6854,-3,14.0215),
						Vector3(-1.70537,-8.00335,-12.0277),
						Vector3(-5.98343,-6.9661,-55.0241),
						Vector3(-16.6158,-6.88147,-70.9894),
						Vector3(-10.4496,-5.60134,-88.3773),
						Vector3(-30.8823,-6.11863,-87.2859),
						Vector3(-75.567,-3.87637,-80.1803),
						Vector3(-91.0564,-2.89308,-82.0212),
						Vector3(-89.6712,-1.76873,-87.0375),
						Vector3(-115.605,-2.50439,-32.3855),
						Vector3(-81.979,-3.22244,-80.7243),
						Vector3(-21.6378,-5.37363,-87.114),
						Vector3(-37.1007,-5.41776,-54.5532),
						Vector3(-34.5933,-6.88147,-72.3675),
						Vector3(-25.8089,-6.52608,-59.4815),
						Vector3(2.95393,-6.81194,-60.5138),
						Vector3(-2.57213,-7.29584,-35.8432),
						Vector3(-36.099,-6.79986,-63.4136),
						Vector3(-47.8752,-6.61326,-76.1423),
						Vector3(-12.4752,-6.4517,-53.7404),
						Vector3(-39.3177,-6.88147,-81.3484),
						Vector3(-68.7614,-3.75931,-83.9658),
						Vector3(-59.1219,-5.35091,-80.1859),
						Vector3(-97.0738,-4.55579,-66.7342),
						Vector3(-103.136,-4.38256,-53.6122),
						Vector3(-110.224,-3.32055,-41.0514),
						Vector3(-6.1,-7.88,1.46),
						Vector3(-5.4,-1.16,36.15),
						Vector3(5.94,-7.09,-31.21),
						Vector3(19.35,-6.1,-45.75),
						Vector3(-68.78,-5.8,-72.93),
						Vector3(-64.53,-5.99,-58.66),
						Vector3(-72.25,-5.67,-54.76),
						Vector3(-96.01,-4.23,-42.75),
						Vector3(-120.9,-2.65,-74.47),
						Vector3(-130.72,-0.83,-83.32),
						Vector3(-115.56,-2.13,-87.81),
						Vector3(-106.86,1.77,-121.29),
						Vector3(-108.98,0.31,-109.17),
						Vector3(-93.26,1.82,-118.35),
						Vector3(-97.56,2.29,-127.76),
						Vector3(-104.78,3.06,-130.57),
						Vector3(-99.9,1.39,-117.39),
						Vector3(-116.76,3.08,-126.8),
						Vector3(-125.3,5.02,-133.19),
						Vector3(-129.34,8.82,-145.16),
						Vector3(-152.87,3.98,-132.45),
						Vector3(-130.35,1.43,-116.74),
						Vector3(-114.68,8.26,-152.1),
						Vector3(-118.44,9.27,-173.07),
						Vector3(-110.36,7.4,-166.63),
						Vector3(-115.4,-0.61,-101.82),
						Vector3(-130.05,-0.31,-99.73),
						Vector3(-131.23,-0.52,-91.96),
						Vector3(-182.16,2.49,-91.31),
						Vector3(-177.31,1.92,-69.41),
						Vector3(-164.93,1.07,-54.16),
						Vector3(-165.37,1.06,-67.16),
						Vector3(-167.1,1.86,-83.68),
						Vector3(-169.98,1.91,-95.51),
						Vector3(-150.02,0.73,-77.33),
						Vector3(-135.86,-1.02,-74.39),
						Vector3(-386.16,50.85,24.5),
						Vector3(-370.62,51.31,19.69),
						Vector3(-379.13,50.84,18.23),
						Vector3(-370.89,51.57,8.96),
						Vector3(-394.35,50.31,24.47),
						Vector3(-396.12,54.05,32.56),
						Vector3(-388.52,53.25,45.98),
						Vector3(-387.62,52.07,56.07),
						Vector3(-375.97,54.22,66.91),
						Vector3(-373.64,57.85,78.01),
						Vector3(-365.82,58.3,72.51),
						Vector3(-361.22,58.37,67.63),
						Vector3(-356.17,60.59,72.01),
						Vector3(-347.52,62.14,71.1),
						Vector3(-343.8,61.87,65.82),
						Vector3(-346.39,60.56,60.29),
						Vector3(-356.16,57.48,55.06),
						Vector3(-355.03,56.38,40.39),
						Vector3(-355.15,56.37,29.11),
						Vector3(-362.06,54.68,5.31),
						Vector3(-365.96,54.79,13.75),
						Vector3(-359.38,55.42,20.59),
						Vector3(-338.51,62.16,63.85),
						Vector3(-373.57,51.24,14.43)
					}
					
				},
				["5"] = {
					mapName = "East Shroud",

					nodes = {

						["3"] = {
							nodeName = "Lv50 Mature Tree",
							
							nodeItems = {
								{ name = "Rosewood Branch", defaultQuantity = 100, id = 5414 },
								{ name = "Wind Shard", defaultQuantity = 100, id = 4 },
								{ name = "Rosewood Log", defaultQuantity = 100, id = 5393 },
							}

						},

						["4"] = {
							nodeName = "Lv20 Lush Vegetation Patch",
							
							nodeItems = {
								{ name = "Belladonna", defaultQuantity = 100, id = 5541 },
								{ name = "Wind Shard", defaultQuantity = 100, id = 4 },
								{ name = "Galago Mint", defaultQuantity = 100, id = 4834 },
								{ name = "Gil Bun", defaultQuantity = 100, id = 4796 },
								{ name = "Shroud Seedling", defaultQuantity = 100, id = 7030 }
							}

						}
					},

					mapWaypoints = {

						Vector3(-174.529,-7.97952,272.548),
						Vector3(-160.27,-8.10511,282.34),
						Vector3(-169.916,-6.53702,296.371),
						Vector3(-156.251,-5.13943,309.184),
						Vector3(-157.805,-3.08209,330.393),
						Vector3(-148.364,-0.723705,339.883),
						Vector3(-171.635,-2.9965,336.67),
						Vector3(-133.641,0.0904046,344.322),
						Vector3(-121.128,0.932216,347.433),
						Vector3(-103.064,1.36422,349.636),
						Vector3(-125.108,-4.83611,326.835),
						Vector3(-107.186,-5.14278,324.868),
						Vector3(-97.068,-6.21194,306.673),
						Vector3(-91.7247,-7.14922,301.311),
						Vector3(-99.2274,-6.71584,300.533),
						Vector3(-85.5589,-5.99495,319.43),
						Vector3(-168.455,4.54924,368.172),
						Vector3(-155.545,6.08432,379.786),
						Vector3(-162.784,8.03821,389.022),
						Vector3(-178.304,9.36637,381.767),
						Vector3(-167.411,6.67239,379.093),
						Vector3(-87.4066,1.42312,361.469),
						Vector3(-73.1339,-2.44966,346.526),
						Vector3(-58.4943,-0.284143,347.953),
						Vector3(-44.808,-2.13198,331.263),
						Vector3(-38.9304,-6.63426,305.135),
						Vector3(-70.7441,-7.84636,308.05),
						Vector3(-145.088,-7.10473,291.433),
						Vector3(-132.014,-5.47597,302.965),
						Vector3(-204.21,3.32,122.38),
						Vector3(-231.05,2.28,126.66),
						Vector3(-257.79,3.52,129.55),
						Vector3(-260.65,3.94,119.62),
						Vector3(-287.6,6.07,116.67),
						Vector3(-296.6,6.04,126.44),
						Vector3(-288.63,5.97,125.49),
						Vector3(-314.91,7.23,113.96),
						Vector3(-202.43,9.3,69.28),
						Vector3(-207.95,10.39,58.55),
						Vector3(-221.96,7.4,69.23),
						Vector3(-253.08,11.79,23.95),
						Vector3(-257.85,9.73,51.52),
						Vector3(-282.05,8.29,63.25),
						Vector3(-253.77,8.06,62.25),
						Vector3(-277.13,6.3,73.33),
						Vector3(-299.22,9.37,68.14),
						Vector3(-304.56,8.28,91.48),
						Vector3(-264.51,7.96,67.27),
						Vector3(-269.6,6.96,85.58),
						Vector3(-287.56,7.54,95.72),
						Vector3(-211.12,6.88,81.12),


					}				
				},
				["6"] = {
					mapName = "South Shroud",

					nodes = {
						["1"] = {
							
							nodeName = "Lv25 Mineral Deposit",

							nodeItems = {
								{ name = "Effervescent Water", defaultQuantity = 100, id = 5491 },
								{ name = "Ice Shard", defaultQuantity = 100, id = 3 },
								{ name = "Silver Ore", defaultQuantity = 100, id = 5113 },
							}

						},

						["3"] = {

							nodeName = "Lv30 Mature Tree",

							nodeItems = {
								{ name = "Chocobo Feather", defaultQuantity = 100, id = 5359 },
								{ name = "Alligator Pear", defaultQuantity = 100, id = 4813 },
								{ name = "Ice Shard", defaultQuantity = 100, id = 3 }

							}
						}

					},	

					mapWaypoints = {

						Vector3(254.589,14.9053,-87.0009),
						Vector3(241.406,14.0427,-95.9801),
						Vector3(225.774,11.2773,-83.0584),
						Vector3(225.865,12.0301,-99.5415),
						Vector3(227.887,15.7883,-110.835),
						Vector3(209.963,12.5745,-102.059),
						Vector3(265.722,15.3727,-95.0763),
						Vector3(286.884,15.7897,-92.8858),
						Vector3(279.295,15.6693,-112.365),
						Vector3(297.041,17.0166,-121.273),
						Vector3(219.973,18.9867,-132.186),
						Vector3(212.985,20.3622,-142.469),
						Vector3(197.291,20.1379,-143.505),
						Vector3(187.53,18.8468,-143.561),
						Vector3(184.894,17.7364,-133.539),
						Vector3(235.52,13.6106,-103.921),
						Vector3(236.79,18.3539,-143.028),
						Vector3(248.676,14.0857,-150.879),
						Vector3(278.663,12.3207,-145.117),
						Vector3(286.713,13.5742,-142.746),
						Vector3(266.987,8.50481,-156.08),
						Vector3(274.718,8.90849,-162.788),
						Vector3(278.354,16.2601,-128.104),
						Vector3(256.052,14.8154,-132.398),
						Vector3(278.714,8.26699,-198.519),
						Vector3(293.114,9.42402,-195.218),
						Vector3(299.865,10.0477,-197.938),
						Vector3(313.22,11.4307,-200.758),
						Vector3(305.508,11.367,-184.257),
						Vector3(322.116,13.7229,-192.923),
						Vector3(328.754,16.2786,-188.641),
						Vector3(329.228,17.087,-182.487),
						Vector3(319.908,13.9929,-177.291),
						Vector3(313.687,12.3494,-186.055),
						Vector3(313.836,14.9031,-163.252),
						Vector3(268.665,15.6866,-106.093),
						Vector3(197.607,13.4458,-111.479),
						Vector3(181.48,14.1995,-114.795),
						Vector3(168.868,14.5512,-116.156),
						Vector3(173.556,15.3227,-120.767),
						Vector3(175.39,17.1483,-127.022),
						Vector3(169.936,17.3409,-138.506),
						Vector3(154.891,16.9294,-117.785),
						Vector3(156.96,18.4213,-124.415),
						Vector3(-265.11,12.34,-117.83),
						Vector3(-258.28,9.24,-106.62),
						Vector3(-239.76,7.64,-104.6),
						Vector3(-244.21,6.88,-97.92),
						Vector3(-249.28,7.89,-104.18),
						Vector3(-276.23,12.05,-126.42),
						Vector3(-275.72,11.35,-118.06),
						Vector3(-272.76,14.14,-96.22),
						Vector3(-290.77,14.45,-91.39),
						Vector3(-301.18,15.36,-88.94),
						Vector3(-297.78,15.58,-83.4),
						Vector3(-287.99,13.97,-106.51),
						Vector3(-312.4,16.96,-123.83),
						Vector3(-276.28,18.36,-62.62),
						Vector3(-272.61,17.02,-62.96),
						Vector3(-229.34,5.55,-97.31),
						Vector3(-308.32,16.05,-113.69),
						Vector3(-299.97,15.05,-117.09),
						Vector3(-275.54,16.91,-76.4),
						Vector3(-284.99,17.41,-73.75),
						Vector3(-275.29,11.79,-138.1),
						Vector3(-280.13,11.63,-134.07),
						Vector3(-223.97,5.72,-92.98)



					}
				},
				["7"] = {

					mapName = "North Shroud",

					nodes = {
						["3"] = {
							nodeName = "Lv10 Mature Tree",
							
							nodeItems = {
								{ name = "Ash Branch", defaultQuantity = 100, id = 5402 },
								{ name = "Earth Shard", defaultQuantity = 100, id = 5 },
								{ name = "Ash Log", defaultQuantity = 100, id = 5383 },
								{ name = "Tinolqa Mistletoe", defaultQuantity = 100, id = 5534 },
							}
						},
						["4"] = {
							nodeName = "Lv30 Lush Vegetation Patch",
							
							nodeItems = {
								{ name = "Moor Leech", defaultQuantity = 100, id = 5559 },
								{ name = "Wizard Eggplant", defaultQuantity = 100, id = 4788 },
								{ name = "Jade Peas", defaultQuantity = 100, id = 4822 },
								{ name = "Earth Shard", defaultQuantity = 100, id = 5 },
								{ name = "Midland Cabbage", defaultQuantity = 100, id = 4789 },
							}
						}
					},

					mapWaypoints = {

						Vector3(52.2235,-39.2342,252.249),
						Vector3(50.2039,-36.5376,266.841),
						Vector3(64.3654,-38.2229,256.646),
						Vector3(67.0492,-37.1675,276.604),
						Vector3(68.1694,-38.2753,238.248),
						Vector3(61.6304,-33.48,219.311),
						Vector3(56.4054,-31.4496,215.953),
						Vector3(48.001,-32.5387,216.011),
						Vector3(76.8883,-34.5943,223.454),
						Vector3(89.2538,-35.0575,241.495),
						Vector3(97.3484,-34.6355,230.22),
						Vector3(109.389,-31.5083,221.616),
						Vector3(118.678,-28.4141,233.37),
						Vector3(136.459,-28.9242,224.361),
						Vector3(151.625,-26.1698,223.969),
						Vector3(144.668,-26.9557,229.27),
						Vector3(158.712,-25.4478,219.698),
						Vector3(152.43,-27.4562,214.296),
						Vector3(61.7238,-38.4478,264.842),
						Vector3(68.5322,-38.0662,245.556),
						Vector3(58.0799,-39.8143,242.086),
						Vector3(67.4097,-36.5812,226.895),
						Vector3(79.83,-36.7571,236.349),
						Vector3(279.29,-26,171.76),
						Vector3(286.13,-25.63,176.45),
						Vector3(272.07,-26.95,171.47),
						Vector3(308.08,-10.58,132.11),
						Vector3(318.48,-8.75,129.52),
						Vector3(329.87,-7.39,144.98),
						Vector3(344.09,-3.92,153.91),
						Vector3(334.9,-7.57,156.54),
						Vector3(355.84,-1.68,160),
						Vector3(354.57,-3.01,166.86),
						Vector3(358.02,-1.22,181.36),
						Vector3(356.4,-0.55,185.65),
						Vector3(348.35,-1.02,187.55),
						Vector3(340.62,-1.65,189.79),
						Vector3(335.8,-2.59,190.68),
						Vector3(363.64,-1.05,175.53),
						Vector3(373.51,-0.05,177.44),
						Vector3(368.78,1.33,186.3),
						Vector3(364.92,1.12,187.54),
						Vector3(356.71,1.52,190.04),
						Vector3(378.51,0.6,180.19),
						Vector3(378.09,2.74,192.1),
						Vector3(324.8,-12.35,163.08),
						Vector3(309.33,-19.31,172.54),
						Vector3(289.82,-25.46,163.2),
						Vector3(317.52,-9.31,141.86),
						Vector3(322.82,-9.79,151.46),
						Vector3(329.17,-9.38,154.68),
						Vector3(299.89,-22.35,166.57),
						Vector3(312.37,-10.11,137.16),
						Vector3(318.92,-8.86,135.54),
						Vector3(318.42,-16.23,171.79),
						Vector3(385.42,1.18,194.48),
						Vector3(397.66,-2.58,208.16),
						Vector3(405.55,-3.52,216.37)

					}

				}
			}
		},

		{
			regionName = "Thanalan",

			maps = {
				["20"] = {
					mapName = "Western Thanalan",					
					
					nodes = {
						["1"] = {
							nodeName = "Lv15 Mineral Deposit",

							nodeItems = {

								{ name = "Iron Ore", defaultQuantity = 100, id = 5111 },								
								{ name = "Water Shard", defaultQuantity = 100, id = 7 },
							}
						},
						["2"] = {
							nodeName = "Lv15 Rocky Outcrop",

							nodeItems = {

								{ name = "Iron Sand", defaultQuantity = 100, id = 5269 },
								{ name = "Cinnabar", defaultQuantity = 100, id = 5519 },
								{ name = "Copper Sand", defaultQuantity = 100, id = 5268 },
								{ name = "Water Shard", defaultQuantity = 100, id = 7 },
							}
						},
						["4"] = {
							nodeName = "Lv15 Lush Vegetation Patch",

							nodeItems = {

								{ name = "Rye", defaultQuantity = 100, id = 4823 },
								{ name = "Moko Grass", defaultQuantity = 100, id = 5341 },
								{ name = "Water Shard", defaultQuantity = 100, id = 7 },
								{ name = "Coerthan Carrot", defaultQuantity = 100, id = 4778 },
								{ name = "Grass Viper", defaultQuantity = 100, id = 5560 }
							}
						},
					},

					mapWaypoints = {

						
						Vector3(97.08,52.61,-139.71),
						Vector3(88.09,51.95,-143.09),
						Vector3(108.34,54.48,-131.33),
						Vector3(94.38,50.16,-159.43),
						Vector3(110.77,49.13,-167.73),
						Vector3(135.34,49.79,-156.18),
						Vector3(151.28,50,-175.29),
						Vector3(149.24,50.41,-180.01),
						Vector3(146.73,52.17,-201.67),
						Vector3(135.64,50.62,-205.98),
						Vector3(193.09,51.7,-157),
						Vector3(199.41,52.61,-158.64),
						Vector3(206.21,55.68,-185.09),
						Vector3(216.34,53.98,-144.33),
						Vector3(206.09,52.4,-134.74),
						Vector3(179.85,50.23,-132.84),
						Vector3(175.18,49.63,-129.2),
						Vector3(176.68,49.89,-123.77),
						Vector3(169.06,49.97,-112.87),
						Vector3(179.6,50.91,-104.4),
						Vector3(149.92,50.71,-94.88),
						Vector3(138.92,51.95,-81.71),
						Vector3(122.11,55.04,-68.26),
						Vector3(101.75,57.15,-115.34),
						Vector3(87.48,57.57,-114.56),
						Vector3(83.52,58.65,-108.73),
						Vector3(77.37,60.59,-100.23),
						Vector3(77.88,55.68,-85.11),
						Vector3(93.78,52.39,-86.02),
						Vector3(104.84,51.19,-91.38),
						Vector3(102.73,56.34,-100.74),
						Vector3(66.04,59.41,-76.21),
						Vector3(62.85,60.29,-68.73),
						Vector3(65.44,59.12,-60.6),
						Vector3(67.81,57.98,-50.88),
						Vector3(69.18,58.15,-41.96),
						Vector3(59.07,62.77,-42.91),
						Vector3(59.86,62.29,-35.9),
						Vector3(109.69,52.07,-144.98),
						Vector3(124.26,51.86,-143.5),
						Vector3(126.14,54.01,-129.93),
						Vector3(132.94,49.41,-166.75),
						Vector3(160.21,49.41,-148.69),
						Vector3(148.55,49.65,-124.45),
						Vector3(100.89,51.3,-147.57),
						Vector3(264.08,62.31,-169.23),
						Vector3(270.64,61.93,-169.14),
						Vector3(271.56,62.29,-182.18),
						Vector3(262.95,62.94,-200.94),
						Vector3(268.44,62.49,-211.58),
						Vector3(262.51,63.62,-218.61),
						Vector3(258.14,64.38,-217.26),
						Vector3(277.87,62.83,-226.49),
						Vector3(283.72,62.99,-238.79),
						Vector3(276.17,64.38,-245.62),
						Vector3(287.71,63.39,-249.99),
						Vector3(292.44,63.09,-254.05),
						Vector3(308.9,62.66,-257.81),
						Vector3(323.63,64.09,-263.97),
						Vector3(331.1,63.51,-256.8),
						Vector3(324.88,64.22,-250.11),
						Vector3(333.29,64.08,-242.37),
						Vector3(316.37,62.72,-233.55),
						Vector3(317.18,62.78,-219.87),
						Vector3(331.43,63.22,-214.79),
						Vector3(325.96,62.91,-208.26),
						Vector3(320.37,63.27,-191.58),
						Vector3(304.34,62.23,-199.71),
						Vector3(317.34,63.81,-180.95),
						Vector3(322.17,64.06,-182.74),
						Vector3(72.78,45,-214.73),
						Vector3(88.2,48.51,-196.76),
						Vector3(99.86,49.84,-182.6),
						Vector3(180.96,49.91,-147.42),
						Vector3(164.87,49.41,-137.21),
						Vector3(197.75,51.37,-143.75)

					}
				},
				["21"] = {
					
					mapName = "Central Thanalan",					
					
					nodes = {
						["1"] = {
							nodeName = "Lv5 Mineral Deposit",

							nodeItems = {

								{ name = "Muddy Water", defaultQuantity = 100, id = 5488 },
								{ name = "Copper Ore", defaultQuantity = 100, id = 5106 },
								{ name = "Wind Shard", defaultQuantity = 100, id = 4 },
								{ name = "Lightning Shard", defaultQuantity = 100, id = 6 }
							}
						},
						["3"] = {

							nodeName = "Lv20 Mature Tree",

							nodeItems = {
								{ name = "Lightning Shard", defaultQuantity = 100, id = 6 },
								{ name = "Nopales", defaultQuantity = 100, id = 4786 }
							}	
						}						
					},

					mapWaypoints = {
						
						Vector3(-117.271,-1.91228,169.746),
						Vector3(-133.483,1.10021,177.087),
						Vector3(-110.893,-3.84194,165.913),
						Vector3(-98.2975,-5.3973,159.397),
						Vector3(-148.83,3.67652,192.604),
						Vector3(-157.702,4.92522,198.662),
						Vector3(-130.284,2.99166,203.381),
						Vector3(-103.634,-2.44384,186.489),
						Vector3(-96.8099,1.49647,211.422),
						Vector3(-92.5753,4.08989,226.453),
						Vector3(-101.097,4.23974,225.378),
						Vector3(-97.2347,4.64138,231.117),
						Vector3(-108.491,6.72035,250.893),
						Vector3(-107.697,6.83544,258.863),
						Vector3(-113.63,7.30696,261.671),
						Vector3(-130.886,5.08043,244.733),
						Vector3(-130.434,3.96443,224.739),
						Vector3(-114.132,3.5265,220.89),
						Vector3(-114.632,2.32757,211.396),
						Vector3(-20.76,-5.79,-93.48),
						Vector3(-29.61,-6.23,-105.24),
						Vector3(-20.49,-4.82,-102.09),
						Vector3(-25.63,-4.42,-112.71),
						Vector3(-17.95,-2.67,-111.9),
						Vector3(-35.44,-7.62,-97.67),
						Vector3(-53.49,-7.11,-95.34),
						Vector3(-58.92,-7.98,-87.7),
						Vector3(-64.12,-10.09,-76.63),
						Vector3(-51.72,-9.85,-75.89),
						Vector3(-42.6,-10.57,-73.5),
						Vector3(-39.09,-9.45,-83.44),
						Vector3(-40.51,-10.03,-57.74),
						Vector3(-34.17,-8.15,-53.33),
						Vector3(-43.55,-10.38,-46.14),
						Vector3(-53.69,-12.92,-44.86),
						Vector3(-46.52,-9.62,-30.78),
						Vector3(17.08,-0.69,223.25),
						Vector3(0.71,-5,205.65),
						Vector3(51.16,1.43,216.28),
						Vector3(71.35,1.53,281.9)

					}
				},
				["22"] = {

					mapName = "Eastern Thanalan",

					nodes = {

						["1"] = {
							nodeName = "Lv30 Mineral Deposit",

							nodeItems = {
								{ name = "Saltpeter", defaultQuantity = 100, id = 5521 },
								{ name = "Fire Shard", defaultQuantity = 100, id = 2 },
								{ name = "Wyvern Obsidian", defaultQuantity = 100, id = 5125 },
							}
						}

					},

					mapWaypoints = {

						Vector3(257.93,6.43,-245.37),
						Vector3(265.39,7.3,-237.42),
						Vector3(251.32,5.23,-241.29),
						Vector3(245.41,5.76,-249.75),
						Vector3(232.86,2.78,-239.48),
						Vector3(220.51,4.69,-220.23),
						Vector3(210.71,5.04,-219),
						Vector3(206.34,4.48,-211.67),
						Vector3(206.6,3.97,-204.21),
						Vector3(226.41,3.85,-251.77),
						Vector3(216.31,6.04,-250.49),
						Vector3(212.02,6.94,-257.61),
						Vector3(219.93,5.53,-267.14),
						Vector3(213.03,7.32,-270.71),
						Vector3(269.15,9.26,-245.62)

					}

				},
				["23"] = {
					mapName  = "Southern Thanalan",
					
					nodes = {
						["4"] = {
						
							nodeName = "Lv35 Lush Vegetation Patch",

							nodeItems = {
								{ name = "Desert Saffron", defaultQuantity = 100, id = 4843 },
								{ name = "Laurel", defaultQuantity = 100, id = 4839 },
								{ name = "Bloodgrass", defaultQuantity = 100, id = 7011 },
								{ name = "Lightning Shard", defaultQuantity = 100, id = 6 },
								{ name = "Aloe", defaultQuantity = 100, id = 4790 }
							}
						}
					},

					mapWaypoints = {
						Vector3(-86.5022,8.09322,-620.744),
						Vector3(-76.3554,6.13624,-627.707),
						Vector3(-66.0359,6.41729,-648.91),
						Vector3(-72.8209,8.72181,-658.237),
						Vector3(-101.691,11.8205,-616.996),
						Vector3(-120.103,17.5687,-622.614),
						Vector3(-55.1425,5.88439,-669.718),
						Vector3(-57.3743,7.90273,-686.907),
						Vector3(-24.2977,3.21032,-675.933),
						Vector3(-18.12,4.04073,-679.677),
						Vector3(-36.7151,4.07368,-602.626),
						Vector3(-23.0753,4.21764,-656.176),
						Vector3(-26.9148,4.8497,-645.474),
						Vector3(-30.7653,4.52042,-634.738),
						Vector3(-44.4325,2.3549,-632.523),
						Vector3(-61.9411,4.43898,-596.147),
						Vector3(-71.8757,4.85511,-608.911),

					}
				}
			}
		},
		{
			regionName = "Coerthas",
			
			maps = {
				["53"] = {
					mapName  = "Coerthas Central Highlands",
					
					nodes = {
						["1"] = {
							
							nodeName = "Lv40 Mineral Deposit",

							nodeItems = {
								{ name = "Ice Shard", defaultQuantity = 100, id = 3 },
								{ name = "Jade", defaultQuantity = 100, id = 5168 },
								{ name = "Raw Zircon", defaultQuantity = 100, id = 5141 },
							}

						},
						["3"] = {
							
							nodeName = "Lv45 Mature Tree",

							nodeItems = {
								{ name = "Mirror Apple", defaultQuantity = 100, id = 6146 },
								{ name = "Ice Shard", defaultQuantity = 100, id = 3 },
								{ name = "Mistletoe", defaultQuantity = 100, id = 5536 }				
							}
						},
					},
					mapWaypoints = {
						-- Lv45 Mature Tree
						Vector3(105.172,288.111,-227.162),
						Vector3(84.9109,288.309,-220.932),
						Vector3(103.174,286.586,-205.508),
						Vector3(48.5011,293.115,-226.101),
						Vector3(31.6205,294.682,-208.645),
						Vector3(11.8327,299.905,-215.87),
						Vector3(43.677,293.264,-161.011),
						Vector3(35.3614,299.491,-142.885),
						Vector3(81.7157,289.51,-159.216),
						Vector3(108.275,293.898,-146.752),
						Vector3(117.826,291.818,-159.732),
						Vector3(99.3585,289.973,-158.807),
						Vector3(107.079,287.572,-178.471),
						Vector3(40.9885,301.368,-135.411),
						Vector3(48.9036,305.499,-122.249),
						Vector3(47.1081,299.564,-137.749),
						Vector3(56.5035,292.117,-155.167),
						-- Lv 40 Mineral Deposit
						Vector3(145.16,284.67,-78.89),
						Vector3(136.9,286.19,-80.73),
						Vector3(135.83,288.91,-89.33),
						Vector3(143.34,292.08,-92.81),
						Vector3(125.68,288.89,-81.79),
						Vector3(111.16,293.32,-80.32),
						Vector3(101,297.61,-79.35),
						Vector3(104.48,297.33,-91.39),
						Vector3(113.26,295.36,-93.29),
						Vector3(119.73,296.56,-104.49),
						Vector3(127.03,297.55,-115.86),
						Vector3(138.58,297.18,-119.86),
						Vector3(146.37,294.61,-113.32),
						Vector3(146.28,296.4,-120.99),
						Vector3(156.53,293.69,-110.9),
						Vector3(156.82,293.77,-100.49),
						Vector3(166.92,286.14,-86.36),
						Vector3(140.93,279.93,-57.89),
						Vector3(134.48,283.76,-69.2),
						Vector3(114.47,289.39,-61.31),
						Vector3(121.45,288.05,-72.25),
						Vector3(154.62,278.37,-56.54),
						Vector3(166.84,279.72,-62.71),
						Vector3(180.5,282.51,-73.05),
						Vector3(151.18,275.62,-41.08),
						Vector3(144.59,275.06,-28.51),
						Vector3(152.35,274.62,-33.35),
						Vector3(177.48,286.53,-88.58),
						Vector3(156.5,285.17,-82.24),
						Vector3(146.28,292.67,-96.53)

					}
				}
			}
		},
		{
			regionName = "La Noscea",
			
			maps = {
				["15"] = {
					mapName = "Middle La Noscea",

					nodes = {

						["2"] = {
							nodeName = "Lv20 Rocky Outcrop",

							nodeItems = {
								{ name = "Grade 1 Carbonized Matter", defaultQuantity = 100, id = 5599 },
								{ name = "Fire Shard", defaultQuantity = 100, id = 2 },
							}
						}
					},
					mapWaypoints = {
						Vector3(-220.25,31.41,-585.1),
						Vector3(-221.06,31.77,-603.24),
						Vector3(-244.74,34.17,-619.25),
						Vector3(-244.05,33.52,-612.43),
						Vector3(-254.22,35.38,-612.16),
						Vector3(-256.5,33.11,-593.63),
						Vector3(-255.4,29.86,-568.47),
						Vector3(-266.22,28.77,-560.07),
						Vector3(-305.67,24.68,-536.68),
						Vector3(-309.78,28.73,-561.14),
						Vector3(-324.97,26.23,-548.51),
						Vector3(-336.15,28.01,-546.65),
						Vector3(-344.09,30.54,-546.33),
						Vector3(-257.97,26.24,-547.14),
						Vector3(-325.44,35.3,-590.89),
						Vector3(-333.57,37.69,-602.69),
						Vector3(-326.52,39.73,-607.52),
						Vector3(-310.28,31.91,-577.28),
						Vector3(-293.32,31.91,-571.61)
					}
				},
				["17"] = {
					mapName  = "Eastern La Noscea",
					
					nodes = {
						["3"] = {
							
							nodeName = "Lv40 Mature Tree",

							nodeItems = {
								{ name = "Iron Acorn", defaultQuantity = 100, id = 4807 },
								{ name = "Almonds", defaultQuantity = 100, id = 4842 },
								{ name = "Nutmeg", defaultQuantity = 100, id = 4844 },
								{ name = "Water Shard", defaultQuantity = 100, id = 7 },
								{ name = "Mahogany Log", defaultQuantity = 100, id = 5391 }
							}
						},
					},
					mapWaypoints = {

						Vector3(-18.31,70.39,-3.87),
						Vector3(-9,70.46,11.23),
						Vector3(-2.65,68.74,25.54),
						Vector3(8.87,65.24,45.38),
						Vector3(21.54,59.36,73.29),
						Vector3(20.8,54.16,101.22),
						Vector3(13.88,50.7,126.67),
						Vector3(7.37,47.54,148.89),
						Vector3(-8.32,43.7,171.28),
						Vector3(-45,40.9,207.14),
						Vector3(-22.39,41.26,188.68),
						Vector3(-65.72,40.77,201.03)
					}
				}
			}
		}
	}
end

XGatherer:new()