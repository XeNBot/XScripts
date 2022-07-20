local TotoRak = Class("TotoRak")

function TotoRak:Tick(main)

	local currentMapId = AgentModule.currentMapId	
	local nodes        = main.grid[tostring(currentMapId)].nodes
	local waypoints    = nodes.waypoints
	local goal         = waypoints[#waypoints].pos

	local range = player.isMelee and 20 or 25
	
	if ObjectManager.BattleEnemiesAroundObject(player, 15) > 0 then

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

return TotoRak:new()