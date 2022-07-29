local StoneVigil = Class("StoneVigil")

function StoneVigil:Tick(main)

	local currentMapId = AgentModule.currentMapId	
	local nodes        = main.grid[tostring(currentMapId)].nodes
	local waypoints    = nodes.waypoints
	local goal         = waypoints[#waypoints].pos

	if self:Interactables(main) then return end

	local range = player.isMelee and 20 or 25
	
	if ObjectManager.BattleEnemiesAroundObject(player, 20,  function(obj) return main.b_filter[obj.name] ~= true and obj.isTargetable end) > 0 then

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

function StoneVigil:Interactables(main)

	local gate = ObjectManager.EventObject(function(obj) return obj.name == "Strongroom Gate" and main:InteractFilter(obj) end)
	if gate.valid then
		player:rotateTo(gate.pos)
		TaskManager:Interact(gate)
		return true
	end	
	
	return false
end

return StoneVigil:new()