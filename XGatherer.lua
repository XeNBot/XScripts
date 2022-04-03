-- Creates new local class named XGatherer
local XGatherer = Class("XGatherer")

-- First function called when class is initialized
function XGatherer:initialize()
	
	print("XGatherer Loaded!")

	self.status = {

		running         = false,
		gatherQueue     = {},
		goalWaypoint    = nil,
		currentWaypoint = nil

	}

	self:loadGrid()
	self:initializeMenu()
	
	Callbacks:Add(CALLBACK_PLAYER_DRAW, function () self:draw() end)
	Callbacks:Add(CALLBACK_PLAYER_TICK, function () self:tick() end)

end

function XGatherer:tick()
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
				print("Set new current waypoint : ", self.status.currentWaypoint)
			end
			return
		end
		print("Starting Walk to Waypoint Task ", self.status.currentWaypoint)
		TaskManager:WalkToWaypoint(self.status.currentWaypoint, player, function ()
			print("Finished Walking to waypoint [".. os.date( "!%a %b %d, %H:%M", os.time() - 7 * 60 * 60 ) .. "]")
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
		
		for i, waypoint in ipairs(self.grid[currentMapId].mapWaypoints) do
			Graphics.DrawCircle3D(waypoint, 20, 1, Colors.Green)
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

	for menuIndex, itemInfo in ipairs(self.grid[currentMapId].mapItems) do

		local menuValue = self.menu[currentMapId][menuIndex].int

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
	local closestObj = nil
	local objectWaypoint = nil

	local currentMapId = tostring(AgentModule.currentMapId)
	for i, obj in ipairs(ObjectManager:ObjectList()) do

		if obj.kind == OBJ_TYPE_GATHERING and obj.isTargetable then

			for i , waypoint in pairs(self.grid[currentMapId].mapWaypoints) do

				if (waypoint:dist(obj.pos) < 3.5) then
					if closestObj == nil or (closestObj ~= nil and obj.pos:dist(player.pos) < closestObj.pos:dist(player.pos)) then
						closestObj = obj
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
	local distanceToWaypoint = player.pos:dist(goalWaypoint)
	local nextWaypoint       = nil

	for i , waypoint in pairs(self.grid[currentMapId].mapWaypoints) do
		if waypoint:dist(player.pos) <= 20 and waypoint:dist(player.pos) > 2 then

			local distanceFromGoal   = waypoint:dist(goalWaypoint)
			local distanceFromPlayer = waypoint:dist(player.pos)

			if distanceFromPlayer < distanceToWaypoint and distanceFromGoal < distanceToWaypoint then				
				nextWaypoint = waypoint
			end

		end
	end

	if nextWaypoint == nil then
		return goalWaypoint
	end

	return nextWaypoint

end

function XGatherer:initializeMenu()
	
	self.menu = Menu("XGatherer")

	self.menu:label("~=[ Supported Maps ]=~") self.menu:separator() self.menu:space()

	for mapId, mapInfo in pairs(self.grid) do
		--print(mapId, mapInfo.mapName)	
		self.menu:subMenu("" .. mapInfo.mapName .. "", mapId)
		if #mapInfo.mapItems > 0 then
			self.menu[mapId]:label("Gatherable Items:")
			self.menu[mapId]:space()
			for i, itemInfo in ipairs(mapInfo.mapItems) do
				self.menu[mapId]:number(itemInfo.name, tostring(i), 100)
				self.menu[mapId]:space()
			end
		end
		self.menu[mapId]:space()
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

function XGatherer:loadGrid()

	self.grid = {
		-- Central Shroud, Bentbranch Meadows
		["4"] = {
			mapName  = "Central Shroud",
			mapItems = {
				{ name = "Gridanian Chestnut", defaultQuantity = 100, id = 4805 },
				{ name = "Wind Shard", defaultQuantity = 100, id = 4 },
				{ name = "Elm Log", defaultQuantity = 100, id = 5385 },
			},
			mapWaypoints = {
				-- Bentbranch Meadows
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
		},		
		["23"] = {
			mapName  = "Southern Thanalan",
			mapItems = {
				{ name = "Desert Saffron", defaultQuantity = 100, id = 4843 },
				{ name = "Laurel", defaultQuantity = 100, id = 4839 },
				{ name = "Bloodgrass", defaultQuantity = 100, id = 7011 },
				{ name = "Lightning Shard", defaultQuantity = 100, id = 6 },
				{ name = "Aloe", defaultQuantity = 100, id = 4790 }
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
				Vector3(-71.8757,4.85511,-608.911)
			}
		},
		["53"] = {
			mapName  = "Coerthas Central Highlands",
			mapItems = {
				{ name = "Mirror Apple", defaultQuantity = 100, id = 6146 },
				{ name = "Ice Shard", defaultQuantity = 100, id = 3 },
				{ name = "Mistletoe", defaultQuantity = 100, id = 5536 }				
			},
			mapWaypoints = {

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

end

XGatherer:new()