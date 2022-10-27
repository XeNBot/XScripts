local Mission = Class("Mission")

function Mission:initialize()

	-- XSquadron Module
	self.mainModule     = nil
	-- deathWatch 
	self.died           = false

	self.exit_callbacks = {}
end

--[[ Virtual Functions for Child Objects ]]--		
-- Custom Object Interaction
function Mission:CustomInteract() return false end
-- Custom Targetting
function Mission:CustomTarget(range) return false end


function Mission:SetMainModule(mod)
	
	self.mainModule = mod

end

function Mission:AddExitCallback(callback)
	if callback ~= nil and type(callback) == "function" then
		table.insert(self.exit_callbacks, callback)
	end
end

function Mission:Tick() 

	self:DeathWatch()

	local currentMapId = AgentManager.GetAgent("Map").currentMapId
	local nodes        = self.mainModule.grid[tostring(currentMapId)].nodes
	local waypoints    = nodes.waypoints
	local goal         = waypoints[#waypoints].pos

	if self:CustomInteract() then return end

	local range      = player.isMelee and 20 or 25

	local mobsAround = ObjectManager.BattleEnemiesAroundObject(player, 15,
		 function(obj)
		 	return self.mainModule.b_filter[obj.npcId] ~= true 
		 end)
	if mobsAround > 0 then

		if TaskManager:IsBusy() then TaskManager:Stop() end

		Mission.HandleMobs(self, range)
	elseif not TaskManager:IsBusy() then
		if player.pos:dist(goal) > 3 then

			if not self.mainModule.route.finished then
				self.mainModule.route:builda(nodes, goal)
			else
				TaskManager:WalkToWaypoint(self.mainModule.route.waypoints[self.mainModule.route.index], function(waypoint) self.mainModule.callbacks.WalkToWaypoint(waypoint) end)
			end
		else
			self:Exit()
		end
	end

end

function Mission:HandleMobs(range)
	
	if self:CustomTarget(range) then return end

	local target = TargetManager.Target
	if not target.valid or target.kind ~= 2 or target.subKind ~= 5 then

		local objects = ObjectManager.Battle( function(target) 
			return self.mainModule.b_filter[target.npcId] ~= true and target.isTargetable and not target.isDead and target.pos:dist(player.pos) < range 
		end)

		for i, obj in ipairs(objects) do
			self.mainModule.log:print("Set new Target: " .. obj.name)
			Keyboard.SendKey(38)
			TargetManager.SetTarget(obj)
			break
		end

	else
		player:rotateTo(target.pos)
	end
end

function Mission:DeathWatch()
	if player.isDead or player.health == 0 and not self.died then
		self.died = true
		TaskManager:Stop()
	elseif self.died and player.health > 0 then
		TaskManager:Stop()
		self.died = false
		self.mainModule.route = Route()
		self.mainModule.stats.times_died = self.mainModule.stats.times_died + 1
		self.mainModule.log:print("Oh noes we died! reviving....")
		self.mainModule.widget["TIMES_DIED"].str = "Times We've Died: " .. tostring(self.mainModule.stats.times_died)
	end
end

function Mission:Exit()
	local exit = ObjectManager.EventObject( function(obj)
		return self.mainModule.interactables.exits[obj.npcId] ~= nil and self.mainModule.callbacks.InteractFilter(obj) 
	end)
	if exit.valid then
		TaskManager:Interact(exit, self.mainModule.callbacks.ExitSquadron)
		self.mainModule.lastExit = os.clock()

		for i, callback in ipairs(self.exit_callbacks) do
			callback()
		end

	end
end

return Mission