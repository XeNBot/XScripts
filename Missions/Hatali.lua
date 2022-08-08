local Hatali = Class("Hatali")

function Hatali:initialize()

	-- main module
	self.main = nil
	self.safeWalk = false
end

function Hatali:Tick(main)
	
	if self.main == nil then
		self.main = main
	end

	local currentMapId = AgentModule.currentMapId	
	local nodes        = main.grid[tostring(currentMapId)].nodes
	local waypoints    = nodes.waypoints
	local goal         = self:GetGoal(waypoints)
	local managerBusy  = TaskManager:IsBusy()

	if self:Interactables() then return end
	

	if ObjectManager.BattleEnemiesAroundObject(player, 15) > 0 then
		if managerBusy and not self.safeWalk then TaskManager:Stop() end
		local range = player.isMelee and 20 or 25

		self:HandleMobs(range, managerBusy)
	else
		if not managerBusy then
			if player.pos:dist(goal) > 3 then

				if not main.route.finished then
					main.route:builda(nodes, goal)
				else
					TaskManager:WalkToWaypoint(main.route.waypoints[main.route.index], function(waypoint) main:OnWalkToWayPoint(waypoint) end)
				end
			else
				self:Interactables()
			end
		end
	end
end

function Hatali:HandleMobs(range, busy)
	local target = TargetManager.Target
	
	self:Sprites(range)

	if not target.valid or target.kind ~= 2 or target.subKind ~= 5 then

		local objects = ObjectManager.Battle( function(target) 
			return target.isTargetable and not target.isDead and target.pos:dist(player.pos) < range 
		end )

		for i, obj in ipairs(objects) do
			Keyboard.SendKey(38)
			TargetManager.SetTarget(obj)
			break
		end
	else
		if target.name == "Thunderclap Guivre" then
			local waypoint = Waypoint(self.main.grid["46"].dps_safe[1])
			if waypoint.pos:dist(player.pos) > 3 then
				if not self.safeWalk then
					self.safeWalk = true
				end
				TaskManager:WalkToWaypoint(waypoint, function() self.safeWalk = false end)
			end
		end

		player:rotateTo(target.pos)
	end	
end

function Hatali:Sprites(range)
	
	local sprite = ObjectManager.BattleObject( function(obj) return string.find(obj.name, "Sprite") and obj.isTargetable and not obj.isDead and obj.pos:dist(player.pos) < range end )
	if sprite.valid then
		player:rotateTo(sprite.pos)
		TargetManager.SetTarget(sprite)
	end

end

function Hatali:GetGoal(waypoints)	
	return waypoints[#waypoints].pos
end

function Hatali:Interactables()

	local aetherial = ObjectManager.EventObject(function(obj) return obj.name == "Aetherial Flow" and self.main:InteractFilter(obj) end)
	if aetherial.valid then
		player:rotateTo(aetherial.pos)
		TaskManager:Interact(aetherial, function() self:OnInteract() end)
		return true
	end	

	local chain = ObjectManager.EventObject(function(obj) return obj.name == "Chain Winch" and self.main:InteractFilter(obj) end)
	if chain.valid then
		player:rotateTo(chain.pos)
		TaskManager:Interact(chain)
		return true
	end

	local door  = ObjectManager.EventObject(function(obj) return obj.name == "Ludus Door" and self.main:InteractFilter(obj) end)
	if door.valid then
		player:rotateTo(door.pos)
		TaskManager:Interact(door)
		return true
	end

	local exit = ObjectManager.EventObject(function(obj) return obj.name == "Exit" and self.main:InteractFilter(obj) end)
	if exit.valid then
		TaskManager:Interact(exit, function() self.main:OnExitSquadron() end)
		return true
	end	

	return false
end

function Hatali:OnInteract()
	
	self.main.route = Route()

end

return Hatali:new()