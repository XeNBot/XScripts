local Mission = Class("Mission")

function Mission:initialize()

	-- XSquadron Module
	self.mainModule     = nil
	-- deathWatch 
	self.died           = false
	-- LoS
	self.last_los       = 0
	-- Field of View
	self.fov            = 20
	-- Custom Exit Callbacks
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

	local should_target = os.clock() - self.last_los > 2

	local objects = ObjectManager.Battle(function(target) 
		return 
			self.mainModule.b_filter[target.npcId] ~= true and
			target.isTargetable and not target.isDead and
			target.pos:dist(player.pos) < self.fov and
			ActionManager.ActionInRange(self:GetRangeCheckAction(), target, player)
	end)
	
	if TargetManager.Target.valid and not ActionManager.ActionInRange(self:GetRangeCheckAction(), TargetManager.Target, player) then
		self.last_los = os.clock()
		TargetManager.SetTarget(nil)
	end

	if #objects > 0 and should_target then
		if TaskManager:IsBusy() then TaskManager:Stop() end

		self:HandleMobs(self.fov, objects)
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

function Mission:HandleMobs(range, objects)
	if self:CustomTarget(range) then return end

	local target = TargetManager.Target
	
	if not target.valid or target.kind ~= 2 or target.subKind ~= 5 or not ActionManager.ActionInRange(self:GetRangeCheckAction(), target, player) then

		for i, obj in ipairs(objects) do
			self.mainModule.log:print("Set new Target: " .. obj.name)
			Keyboard.SendKey(38)
			TargetManager.SetTarget(obj)
			break
		end
	end
end

function Mission:GetRangeCheckAction()
	
	if player.classJob == 1 or  player.classJob == 19 then
		return 7533
	elseif player.classJob == 3 or player.classJob == 21 then
		return 7
	elseif player.classJob == 5 or player.classJob == 23 then
		return 8
	elseif player.classJob == 6 or player.classJob == 24 then
		return 119
	elseif player.classJob == 7 or player.classJob == 25 then
		return 142
	elseif player.classJob == 22 then
		return 7
	elseif player.classJob == 26 or player.classJob == 27 then
		return 163
	elseif player.classJob == 29 or player.classJob == 30 then
		return 7
	elseif player.classJob == 31 then
		return 8
	elseif player.classJob == 34 then
		return 7
	elseif player.classJob == 35 then
		return 7503
	elseif player.classJob == 39 then
	    return 7
	elseif player.classJob == 40 then
	    return 24283
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
		self.mainModule.last_exit = os.clock()

		for i, callback in ipairs(self.exit_callbacks) do
			callback()
		end

	end
end

return Mission