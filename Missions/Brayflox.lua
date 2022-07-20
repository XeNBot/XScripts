local Brayflox = Class("Brayflox")

function Brayflox:initialize()
	
	-- Runstop Headgate Key
	self.headgate_key = 2000521

end

function Brayflox:Tick(main)
	local currentMapId = AgentModule.currentMapId
	local nodes        = main.grid[tostring(currentMapId)].nodes
	local waypoints    = nodes.waypoints
	local goal         = waypoints[#waypoints].pos

	if self:Interactables(main) then return end

	local range = player.isMelee and 20 or 25
	
	if ObjectManager.BattleEnemiesAroundObject(player, 15, function(obj) return main.b_filter[target.name] ~= true end) > 0 then

		if TaskManager:IsBusy() then TaskManager:Stop() end

		main:HandleMobs(range)
	elseif not TaskManager:IsBusy() then
		if player.pos:dist(goal) > 3 then

			if not main.route.finished then
				main.route:builda(nodes, goal)
			else
				TaskManager:WalkToWaypoint(main.route.waypoints[main.route.index], function(waypoint) main:OnWalkToWayPoint(waypoint) end)
			end
		else
			main:Exit()
		end
	end
end

function Brayflox:Interactables(main)

	local pathfinder = ObjectManager.EventNpcObject(function(obj) return obj.name == "Goblin Pathfinder" and main:InteractFilter(obj) end)
	if pathfinder.valid and InventoryManager.GetItemCount(self.headgate_key) < 1 then
		player:rotateTo(pathfinder.pos)
		TaskManager:Interact(pathfinder)
		return true
	end	

	local headgate = ObjectManager.EventObject(function(obj) return obj.name == "Runstop Headgate" and main:InteractFilter(obj) end)
	if headgate.valid then
		player:rotateTo(headgate.pos)
		TaskManager:Interact(headgate)
		return true
	end

	local gutgate = ObjectManager.EventObject(function(obj) return obj.name == "Longstop Gutgate" and main:InteractFilter(obj) end)
	if gutgate.valid then
		player:rotateTo(gutgate.pos)
		TaskManager:Interact(gutgate)
		return true
	end
	
	return false
end


return Brayflox:new()