local XEvade = Class("XEvade")

function XEvade:initialize()

	-- Global Variables
	_G.EvadeOn = true
	_G.Evading = false

	-- Script Variables
	self.current_actions = {}
	self.current_objects = {}
	self.evade_pos       = nil
	self.evade_source    = nil
	
	-- Action Types
	CIRCLE_TARGET = 2
	CONE_SOURCE   = 3
	LINE_AOE      = 4
	CIRCLE_SOURCE = 5
	CONE_BEHIND   = 13
	OBJ_COLLISION = 20
	
	self.evade_objects = {
		[28731] = { name = "Typhoon", cast_type = OBJ_COLLISION, width = 2.5, effect_range = 0, duration = 10 }
	}
		
	self.obj_filter = function(obj) return self:ObjectFilter(obj) end	

	self:initializeMenu()

	Callbacks:Add(CALLBACK_PLAYER_DRAW,   function() self:Draw() end)
	Callbacks:Add(CALLBACK_PLAYER_TICK,   function() self:Tick() end)

	print("Loaded XEvade")

end

function XEvade:initializeMenu()
	
	self.menu = Menu("XEvade")
		self.menu:subMenu("Evade Actions", "ACTIONS")
			self.menu["ACTIONS"]:checkbox("Evade Circles",     "EVADE_CIRCLES",    true)
			self.menu["ACTIONS"]:checkbox("Evade Rectangles ", "EVADE_RECTANGLES", true)
			self.menu["ACTIONS"]:checkbox("Evade Cones ",      "EVADE_CONES",      true)
		self.menu:subMenu("Draws", "DRAWS")
			self.menu["DRAWS"]:checkbox("Draw Evade Status", "EVADE_STATUS", true)
			self.menu["DRAWS"]:sliderF("Text Size", "EVADE_STATUS_SIZE", 0.5, 5, 20, 10)
		
		self.menu:checkbox("Enable XEvade", "ENABLED", true)
		self.menu:hotkey("Enable / Disable Key", "ENABLE_KEY", 77)
		self.menu:hotkey("Force Stop Key", "STOP_KEY", 76)

end

function XEvade:Tick()

	_G.EvadeOn = self.menu["ENABLED"].bool

	if self.menu["STOP_KEY"].keyDown and _G.Evading then
		self.evade_pos    = nil
		self.evade_source = nil
		_G.Evading        = false
		TaskManager:Stop()
	end

	for hash, info in pairs(self.current_actions) do
		
		local time_check =
				info.action.castType == OBJ_COLLISION and
				os.clock() - info.time_recorded > info.action.duration or
				info.action.castType ~= OBJ_COLLISION and 
				os.clock() - info.time_recorded > info.time_remaining and not info.source.isCasting

		if time_check then
			print("Removing Action : " .. info.action.name)
			self.current_actions[info.hash] = nil
			table.remove(self.current_actions, hash)
		else
			if info.action.castType == LINE_AOE then
				info.draw_obj = self:DrawLineAction(info)
			elseif info.action.castType == CONE_SOURCE then
				info.draw_obj = self:DrawConeAction(info)
			end

			if info.draw_obj ~= nil then	
				if not _G.Evading and info.action.effectRange < 100 and info.draw_obj:is_point_inside(player.pos) then
					if TaskManager:IsBusy() then
						TaskManager:Stop()
					end
					self:DodgeAction(info)
				end
			end
		end
	end

	if _G.Evading and self.evade_pos ~= nil then
		if not self.evade_source.isCasting then
			self.evade_pos    = nil
			self.evade_source = nil
			_G.Evading        = false		
		end		
	end

	for i, s in ipairs(ObjectManager.Battle(self.obj_filter)) do
		
		local id          = s.castInfo.actionId
		local action      = Action(id)
		local h           = tonumber(tostring(s.id) .. tostring(id))
		local info        = self:GetActionInfo(action, s)

		if self:ValidCastType(action) and not self.current_actions[info.hash] then			
			
			local info    = self:GetActionInfo(action, s)		
			info.draw_obj = self:GetDrawObject(info)

			if not self.current_actions[info.hash] then
				print("Found Evade Action : " .. action.name)

				self.current_actions[info.hash] = info

			end
		end
	end	

end

function XEvade:Draw()
	
	for hash, info in pairs(self.current_actions) do
		if info.draw_obj ~= nil then					
			info.draw_obj:draw(Colors.Yellow)					
		end
	end

	if _G.Evading and self.evade_pos ~= nil and self.evade_source.isCasting then
		Graphics.DrawLine3D(self.evade_pos, player.pos, Colors.Yellow)
		Graphics.DrawText3D(self.evade_pos, "SAFE SPOT", 10, RGBA(255, 248, 159, 255))
		Graphics.DrawCircle3D(self.evade_pos, 3, 1, Colors.Yellow)
	end

	if self.menu["DRAWS"]["EVADE_STATUS"].bool then
		local text  = (_G.EvadeOn and "ON") or "OFF"
		local color = (_G.EvadeOn and RGBA(75, 239, 37, 255) or RGBA(175, 184, 4, 255))
		
		Graphics.DrawCircle3D(player.pos, 1, 1, Colors.Yellow)
		Graphics.DrawText3D(player.pos, "XEvade Status : " .. text, self.menu["DRAWS"]["EVADE_STATUS_SIZE"].float, color)
	end
end

function XEvade:DodgeAction(info)
	
	local dodge_pos = self:CalculateDodgePos(info)

	if dodge_pos == nil then return end
	
	_G.Evading        = true

	self.evade_pos    = dodge_pos
	self.evade_source = info.source	

	TaskManager:Walk(dodge_pos, function(pos) self:OnEvade() end, true)
end

function XEvade:GetDrawObject(info)
	if info.action.castType == CIRCLE_TARGET or info.action.castType == CIRCLE_SOURCE then
		return self:DrawCircleAction(info)
	elseif info.action.castType == LINE_AOE or info.action.castType == OBJ_COLLISION then
		return self:DrawLineAction(info)
	elseif info.action.castType == CONE_SOURCE or info.action.castType == CONE_BEHIND then
		return self:DrawConeAction(info)
	end
end

function XEvade:DrawCircleAction(info)

	local circle   = Circle()	
		
	if info.action.castType == CIRCLE_SOURCE then
		circle.center = info.source.pos
		circle.radius = info.action.effectRange + info.source.radius
	elseif info.action.castType == CIRCLE_TARGET then
		circle.radius = info.action.effectRange
		circle.center = info.cast_info.castLocation
	end
	
	return circle	
end

function XEvade:DrawConeAction(info)

	local p        = info.source.pos
	local a        = info.source.angle
	local l, w     = self:GetConeLW(info.action)

	local behind_source    = Vector3(p.x  + ((info.source.radius)  * math.cos(a)), p.y,  p.z - ((info.source.radius) * math.sin(a)))
	local front_source_end = Vector3(p.x  - ((info.source.radius   * l)  * math.cos(a)), p.y,  p.z + ((info.source.radius * l) * math.sin(a)))

	local front_source_end_left     = Vector3(front_source_end.x  + (w * math.cos(info.source.rotation)), front_source_end.y, front_source_end.z - (w * math.sin(info.source.rotation)))
	local front_source_end_right    = Vector3(front_source_end.x  - (w * math.cos(info.source.rotation)), front_source_end.y, front_source_end.z + (w * math.sin(info.source.rotation)))

	local poly = Polygon({ p, front_source_end_left, front_source_end_right})

	return poly
end

function XEvade:DrawLineAction(info)
	
	local source = ObjectManager.GetById(info.source.id)
	
	if source.valid then
		local pos = source.pos
		local w   = info.action.castType == OBJ_COLLISION and info.action.width 
					or info.action.modifier / 2
		local l   = info.action.castType == OBJ_COLLISION and ( info.source.pos:dist(player.pos) + 5 )
					or info.action.effectRange + source.radius
		local a   = source.angle
		local r   = source.rotation

		local start_point       = Vector3(pos.x - (w * math.cos(r)), pos.y, pos.z + (w * math.sin(r)))
		local start_point2      = Vector3(pos.x + (w * math.cos(r)), pos.y, pos.z - (w * math.sin(r)))
		local direction_point   = Vector3(start_point.x  - (l * math.cos(a)), start_point.y,  start_point.z +  (l * math.sin(a)))
		local direction_point2  = Vector3(start_point2.x - (l * math.cos(a)), start_point2.y, start_point2.z + (l * math.sin(a)))	

		local poly = Polygon({ start_point, start_point2, direction_point2, direction_point })

		return poly
	end

	return nil
end

function XEvade:CalculateDodgePos(info)

	if info.action.castType == LINE_AOE or info.action.castType == OBJ_COLLISION then
		if self.menu["ACTIONS"]["EVADE_RECTANGLES"].bool then
			return self:CalculateBestLineAOEPos(info)
		end
	elseif info.action.castType == CIRCLE_TARGET or info.action.castType == CIRCLE_SOURCE then
		if self.menu["ACTIONS"]["EVADE_CIRCLES"].bool then
			return self:CalculateBestCirclePos(info)
		end
	elseif info.action.castType == CONE_SOURCE or info.action.castType == CONE_BEHIND then
		if self.menu["ACTIONS"]["EVADE_CONES"].bool then
			return self:CalculateBestConePos(info)
		end
	end

	return nil
end

function XEvade:CalculateBestLineAOEPos(info)
	
	local best_pos      = nil
	local best_pos_dist = 10000
	local dodge_table   = {}

	local p        = player.pos
	local dist     = info.source.yalmX >= 4 and info.source.yalmX or 2.5
	local w        = (info.action.modifier / 2) + ( player.radius + 2)

	local foward   = Vector3(p.x  - ((dist * 2)  * math.cos(player.angle)), p.y,  p.z +  ((dist * 2) * math.sin(player.angle)))
	local back     = Vector3(p.x  + ((info.action.effectRange - dist) * math.cos(player.angle)), p.y,  p.z -  ((info.action.effectRange + dist) * math.sin(player.angle)))
	local left     = Vector3(p.x  + (w * math.cos(player.rotation)), p.y, p.z - (w * math.sin(player.rotation)))
	local right    = Vector3(p.x  - (w * math.cos(player.rotation)), p.y, p.z + (w * math.sin(player.rotation)))

	table.insert(dodge_table, foward)
	table.insert(dodge_table, back)
	table.insert(dodge_table, left)
	table.insert(dodge_table, right)

	for i, pos in ipairs(dodge_table) do
		local dist = pos:dist(player.pos)
		if not info.draw_obj:is_point_inside(pos) and dist < best_pos_dist then
			best_pos      = pos
			best_pos_dist = dist
		end
	end

	return best_pos

end

function XEvade:CalculateBestConePos(info)
	
	local best_pos      = nil
	local best_pos_dist = 10000
	local dodge_table   = {}

	local p        = info.source.pos
	local a        = info.source.angle
	local l,w        = self:GetConeLW(info.action)

	l = l + player.radius + 1

	local behind_source    = Vector3(p.x  + ((info.source.radius)  * math.cos(a)), p.y,  p.z - ((info.source.radius) * math.sin(a)))
	local front_source_end = Vector3(p.x  - ((info.source.radius   * l)  * math.cos(a)), p.y,  p.z + ((info.source.radius * l) * math.sin(a)))	

	table.insert(dodge_table, behind_source)
	table.insert(dodge_table, front_source_end)

	for i, pos in ipairs(dodge_table) do
		local dist = pos:dist(player.pos)
		if dist < best_pos_dist then
			best_pos      = pos
			best_pos_dist = dist
		end
	end

	return best_pos

end

function XEvade:CalculateBestCirclePos(info)

	local best_pos      = nil
	local best_pos_dist = 10000
	local dodge_table   = {}

	local radius = info.action.effectRange
	local s = (info.action.castType == CIRCLE_TARGET and ObjectManager.GetById(info.source.targetId)) or info.source

	if s.valid then
		table.insert(dodge_table, Vector3(s.pos.x - radius - 3, s.pos.y, s.pos.z))
		table.insert(dodge_table, Vector3(s.pos.x + radius + 3, s.pos.y, s.pos.z))
		table.insert(dodge_table, Vector3(s.pos.x, s.pos.y, s.pos.z - radius - 3))
		table.insert(dodge_table, Vector3(s.pos.x, s.pos.y, s.pos.z + radius + 3))
	end

	for i, pos in ipairs(dodge_table) do
		local dist = pos:dist(player.pos)
		if not info.draw_obj:is_point_inside(pos) and dist < best_pos_dist then
			best_pos      = pos
			best_pos_dist = dist
		end
	end

	return best_pos
end

function XEvade:OnEvade()
	
	_G.Evading = false

	self.evade_pos    = nil
	self.evade_source = nil
end

function XEvade:ObjectFilter(obj)
	
	return obj.pos:dist(player.pos) <= 30 and obj.castInfo.isCasting

end

function XEvade:GetConeLW(action)
	if action.aspect == 1 then
		return 4, 8
	elseif action.aspect == 3 then
		return 3.5, 8
	elseif action.aspect == 5 then
		return 3, 11
	end

	return 1, 1


end

function XEvade:GetActionInfo(action, source)

	return 
	{
		action           = action,
		draw_obj         = nil,
		source           = source,
		cast_info        = source.castInfo,
		time_remaining   = source.castInfo.totalCastTime - source.castInfo.currentCastTime,
		time_recorded    = os.clock(),
		hash             = tonumber(tostring(source.id) .. tostring(action.id))
	}

end

function XEvade:ValidCastType(action)

	return 
		action.castType == 2  or
		action.castType == 3  or
		action.castType == 4  or
		action.castType == 5  or
		action.castType == 13 or
		action.castType == 20

end

return XEvade:new()