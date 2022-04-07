-- Creates new local class named XGatherer
local XGatherer = Class("XGatherer")

-- First function called when class is initialized
function XGatherer:initialize()
	
	print("XGatherer Loaded!")

	self.status = {

		running         = false,
		gatherQueue     = {},
		goalWaypoint    = nil,
		currentWaypoint = nil,
		lastWaypoint    = Vector3(0,0,0)

	}

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
	-- Closes windows that could interrupt cursor selector
	self:agentCheck()

	if TaskManager:IsBusy() or not self.status.running then return end

	if #self.status.gatherQueue == 0 then
		self:buildGatherQueue()
		return
	end	
	
	local closestNode = self:getClosestGatheringNode()

	if closestNode == nil or closestNode.pos:dist(player.pos) >  3.5 then

		if self.status.goalWaypoint == nil then
			self.status.goalWaypoint = self:getClosestNodeWithWaypoint()
			if self.status.goalWaypoint ~= nil then
				print("Set new goal waypoint : ", self.status.goalWaypoint)
			end
			return
		end
		if self.status.currentWaypoint == nil then
			self.status.currentWaypoint = self:getNextWaypoint(self.status.goalWaypoint)
			if self.status.currentWaypoint ~= nil then
				--print("Set new current waypoint : ", self.status.currentWaypoint)
			end
			return
		end
		print("Starting Walk to Waypoint Task ", self.status.currentWaypoint, self.status.lastWaypoint, self.status.lastWaypoint == self.status.currentWaypoint)
		TaskManager:WalkToWaypoint(self.status.currentWaypoint, player, function (waypoint)
			print("Finished Walking to waypoint [".. os.date( "!%a %b %d, %H:%M", os.time() - 7 * 60 * 60 ) .. "]", waypoint)
			self.status.lastWaypoint = self.status.currentWaypoint
			self.status.currentWaypoint = nil
		end)

	elseif closestNode ~= nil and closestNode.pos:dist(player.pos) < 3.5 then

		self.status.currentWaypoint = nil
		player:rotateTo(closestNode.pos)

		local gatheringAddon = AddonManager:getGatheringAddon()
		if gatheringAddon ~= nil then
			self.status.goalWaypoint = nil
			if not gatheringAddon:isGathering() then				
				local itemToGather = self:getNextQueueItem()
				local selectedName = gatheringAddon:getSelectedItemName()

				if not string.find(selectedName, itemToGather.name) then
					TaskManager:SelectGatherItem(itemToGather.name)
					return
				end
				print("Gathering : " .. selectedName)
				TaskManager:GatherItem(function ()
					self:updateGatherQueue()
				end)
			end
		else

			if TargetSystem.targetObjID ~= closestNode.id then
				TargetSystem:setTarget(closestNode)
			end
			Keyboard.SendKey(96)
			
		end
	end
end

function XGatherer:draw()
	
	if self.menu["DRAW_GATHERABLE_NODES"].bool then
		self:drawGatherableNodes()
	end

	if self.menu["DRAW_POSSIBLE_NODES"].bool then
		self:drawPossibleNodes()
	end	

	if self.menu["DRAW_WAYPOINTS"].bool then
		local currentMapId = tostring(AgentModule.currentMapId)
		local currentRegionId = self:getMapRegion(currentMapId)
		local jobString = tostring(player.classJob)

		if self.grid[currentRegionId] ~= nil and self.grid[currentRegionId].maps[currentMapId] ~= nil and self.grid[currentRegionId].maps[currentMapId][jobString] ~= nil then
			for i, waypoint in ipairs(self.grid[currentRegionId].maps[currentMapId][jobString].jobWaypoints) do
				Graphics.DrawCircle3D(waypoint, 20, 1, Colors.Green)
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

function XGatherer:updateGatherQueue()
	for i, item in ipairs(self.status.gatherQueue) do
		
		local currentItemCount = InventoryManager:GetItemCount(item.id)
		if currentItemCount >= item.finishValue then
			print("Finished collecting " .. item.amountToGather .. " " .. item.name .. "(s)")
			table.remove(self.status.gatherQueue, i)
		end
	end
end

function XGatherer:getNextQueueItem()
	
	for i, item in ipairs(self.status.gatherQueue) do
		return item
	end

end

function XGatherer:buildGatherQueue()
	self.status.gatherQueue = {}

	print("Building new Item Gather Queue")

	local currentMapId = tostring(AgentModule.currentMapId)
	local currentRegionId = self:getMapRegion(currentMapId)
	local jobString = tostring(player.classJob)

	if self.grid[currentRegionId].maps[currentMapId][jobString] == nil then
		print("Unsuported Job for this map!", jobString, currentMapId)
	end

	for menuIndex, itemInfo in ipairs(self.grid[currentRegionId].maps[currentMapId][jobString].jobItems) do

		local menuValue = self.menu[tostring(currentRegionId)][currentMapId][jobString][menuIndex].int

		if menuValue > 0 then

			local itemCopy  = itemInfo
			local itemCount = InventoryManager:GetItemCount(itemInfo.id)

			print("Adding " .. menuValue .. " " .. itemInfo.name .. "(s), Currently Have " .. itemCount)

			itemCopy.initialAmount  = itemCount
			itemCopy.amountToGather = menuValue
			itemCopy.finishValue    = itemCount + menuValue

			table.insert(self.status.gatherQueue, itemCopy)		
		end
	end
end

function XGatherer:drawGatherableNodes()
	local nodes = self:getNodes()

	for i, node in ipairs(nodes) do
		if node.isTargetable then
			Graphics.DrawCircle3D(node.pos, 20, 1, Colors.Yellow)
		end
	end

end

function XGatherer:drawPossibleNodes()
	local nodes = self:getNodes()

	for i, node in ipairs(nodes) do
		if not node.isTargetable then
			Graphics.DrawCircle3D(node.pos, 20, 1, Colors.Red)
		end
	end

end

function XGatherer:getNodes()
	local nodes = {}

	for i, obj in ipairs(ObjectManager:ObjectList()) do
		if obj.kind == OBJ_TYPE_GATHERING then
			table.insert(nodes, obj)
		end
	end

	return nodes

end

function XGatherer:getClosestGatheringNode()
	local closestNode = nil

	for i, obj in pairs(ObjectManager:ObjectList()) do
		if obj.kind == OBJ_TYPE_GATHERING and obj.isTargetable then
			if closestNode == nil or obj.pos:dist(player.pos) < closestNode.pos:dist(player.pos) then
				closestNode = obj
			end
		end
	end

	return closestNode
end

function XGatherer:getClosestNodeWithWaypoint()
	
	local objectWaypoint  = nil
	local currentMapId    = tostring(AgentModule.currentMapId)
	local currentRegionId = self:getMapRegion(currentMapId)
	
	for i, obj in ipairs(ObjectManager:ObjectList()) do

		if obj.kind == OBJ_TYPE_GATHERING and obj.isTargetable then

			for i , waypoint in ipairs(self.grid[currentRegionId].maps[currentMapId][tostring(player.classJob)].jobWaypoints) do

				local distanceToPlayer = waypoint:dist(player.pos)
				if (waypoint:dist(obj.pos) < 4) then
					print("Distance to Player", distanceToPlayer)
					if objectWaypoint == nil or (objectWaypoint:dist(player.pos) > distanceToPlayer) then
						objectWaypoint = waypoint
					end
				end

			end

		end
	end
	return objectWaypoint

end

function XGatherer:getNextWaypoint(goalWaypoint)
	
	local currentMapId       = tostring(AgentModule.currentMapId)
	local currentRegionId    = self:getMapRegion(currentMapId)
	local distanceToWaypoint = player.pos:dist(goalWaypoint)
	local nextWaypoint       = nil

	for i , waypoint in ipairs(self.grid[currentRegionId].maps[currentMapId][tostring(player.classJob)].jobWaypoints) do

		if waypoint ~= self.status.lastWaypoint and waypoint:dist(player.pos) > 0.5 then
			local distanceFromGoal   = waypoint:dist(goalWaypoint)
			local distanceFromPlayer = waypoint:dist(player.pos)		
			if nextWaypoint == nil or (distanceToWaypoint > distanceFromGoal and nextWaypoint:dist(player.pos) > distanceFromPlayer) then

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
			-- Checks if map supports miner
			if mapInfo["16"] ~= nil then
				-- Creates Miner Item submenu
				self.menu[regionId][mapId]:subMenu("Miner Items", "16")
				-- Adds miner items from grid to submenu
				for i, itemInfo in ipairs(mapInfo["16"].jobItems) do
					self.menu[regionId][mapId]["16"]:number(itemInfo.name, tostring(i), 100)
					self.menu[regionId][mapId]["16"]:space()
				end
				self.menu[regionId][mapId]:space()
			end

			-- Checks if map supports botanist
			if mapInfo["17"] ~= nil then
				-- Creates Botanist Items SubMenu
				self.menu[regionId][mapId]:subMenu("Botanist Items", "17")
				-- Adds botanist items from grid to submenu
				for i, itemInfo in ipairs(mapInfo["17"].jobItems) do
					self.menu[regionId][mapId]["17"]:number(itemInfo.name, tostring(i), 100)
					self.menu[regionId][mapId]["17"]:space()
				end

			end

			self.menu[regionId]:space()
		end

		self.menu:space()
	end

	self.menu:separator() self.menu:space()
	self.menu:label("~=[ Other Settings ]=~") self.menu:space() self.menu:separator() self.menu:space() self.menu:space()
	self.menu:checkbox("Draw Waypoints", "DRAW_WAYPOINTS", false) 
	self.menu:checkbox("Draw Gatherable Nodes", "DRAW_GATHERABLE_NODES", false)
	self.menu:checkbox("Draw Possible Nodes", "DRAW_POSSIBLE_NODES", false)
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
	elseif mapId == "21" or mapId == "23" then
		return 2
	elseif mapId == "53" then 
		return 3
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

					["17"] =  {
						jobItems = {
							{ name = "Gridanian Chestnut", defaultQuantity = 100, id = 4805 },
							{ name = "Wind Shard", defaultQuantity = 100, id = 4 },
							{ name = "Elm Log", defaultQuantity = 100, id = 5385 },
						},
						jobWaypoints = {
							-- Bentbranch Meadows
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
							Vector3(-110.224,-3.32055,-41.0514)
						}
					}
				},
				["5"] = {
					mapName = "East Shroud",

					["17"] =  {
						jobItems = {
							{ name = "Belladonna", defaultQuantity = 100, id = 152 },
							{ name = "Wind Shard", defaultQuantity = 100, id = 4 },
							{ name = "Galago Mint", defaultQuantity = 100, id = 4834 },
							{ name = "Gil Bun", defaultQuantity = 100, id = 4796 },
							{ name = "Shroud Seedling", defaultQuantity = 100, id = 7030 }
						},
						jobWaypoints = {
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
							Vector3(-132.014,-5.47597,302.965)

						}
					}
				},
				["6"] = {
					mapName = "South Shroud",

					["17"] = {

						jobItems = {
							{ name = "Chocobo Feather", defaultQuantity = 100, id = 153 },
							{ name = "Alligator Pear", defaultQuantity = 100, id = 5359 },
							{ name = "Ice Shard", defaultQuantity = 100, id = 3 }
						},

						jobWaypoints = {

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
							Vector3(235.52,13.6106,-103.921)

						}

					}
				},
				["7"] = {

					mapName = "North Shroud",

					["17"] = {

						jobItems = {
							{ name = "Moor Leech", defaultQuantity = 100, id = 154 },
							{ name = "Wizard Eggplant", defaultQuantity = 100, id = 5559 },
							{ name = "Jade Peas", defaultQuantity = 100, id = 4788 },
							{ name = "Earth Shard", defaultQuantity = 100, id = 5 },
							{ name = "Midland Cabbage", defaultQuantity = 100, id = 4789 },
						},

						jobWaypoints = {

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
							Vector3(79.83,-36.7571,236.349)

						}

					}

				}
			}
		},
		{
			regionName = "Thanalan",
			maps = {
				["21"] = {
					
					mapName = "Central Thanalan",
					
					["16"] = {
						jobItems = {
							{ name = "Muddy Water", defaultQuantity = 100, id = 5488 },
							{ name = "Copper Ore", defaultQuantity = 100, id = 5106 },
							{ name = "Wind Shard", defaultQuantity = 100, id = 4 },
							{ name = "Lightning Shard", defaultQuantity = 100, id = 6 }
						},
						jobWaypoints = {
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
							Vector3(-114.632,2.32757,211.396)
						}
					},
					["17"] = {
						jobItems = {
							{ name = "Lightning Shard", defaultQuantity = 100, id = 6 },
							{ name = "Nopales", defaultQuantity = 100, id = 4786 }
						},
						jobWaypoints = {

						}				
					}
				},
				["23"] = {
					mapName  = "Southern Thanalan",
					["17"] = {
						jobItems = {
							{ name = "Desert Saffron", defaultQuantity = 100, id = 4843 },
							{ name = "Laurel", defaultQuantity = 100, id = 4839 },
							{ name = "Bloodgrass", defaultQuantity = 100, id = 7011 },
							{ name = "Lightning Shard", defaultQuantity = 100, id = 6 },
							{ name = "Aloe", defaultQuantity = 100, id = 4790 }
						},

						jobWaypoints = {
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
							Vector3(-71.8757,4.85511,-608.911)
						}
					}
				}
			}
		},
		{
			regionName = "Coerthas",
			maps = {
				["53"] = {
					mapName  = "Coerthas Central Highlands",
					["17"] = {
						jobItems = {
							{ name = "Mirror Apple", defaultQuantity = 100, id = 6146 },
							{ name = "Ice Shard", defaultQuantity = 100, id = 3 },
							{ name = "Mistletoe", defaultQuantity = 100, id = 5536 }				
						},
						jobWaypoints = {

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
							Vector3(56.5035,292.117,-155.167)
						}
					}
				}
			}
		}		
		
	}

end

XGatherer:new()