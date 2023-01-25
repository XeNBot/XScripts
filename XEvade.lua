local XEvade = Class("XEvade")
local _VERSION = 1.1

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
	
	self.menu = Menu("XEvade " .. tostring(_VERSION))
		self.menu:subMenu("Actions", "ACTIONS")
			self.menu["ACTIONS"]:checkbox("Evade Circles",     "EVADE_CIRCLES",    true)
			self.menu["ACTIONS"]:checkbox("Evade Rectangles ", "EVADE_RECTANGLES", true)
			self.menu["ACTIONS"]:checkbox("Evade Cones ",      "EVADE_CONES",      true)
		self.menu:subMenu("Draws", "DRAWS")
			self.menu["DRAWS"]:checkbox("Draw Evade Status", "EVADE_STATUS", true)
			self.menu["DRAWS"]:sliderF("Text Size", "EVADE_STATUS_SIZE", 0.5, 5, 20, 10)
		
		self.menu:subMenu("Settings", "SETTINGS")
			self.menu["SETTINGS"]:slider("Dodge Precision", "PRECISION", 1, 2, 100, 10)
			self.menu["SETTINGS"]:sliderF("Extra Hitbox", "EXTRA_HITBOX", 0.5, 0, 10, 1)

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
		elseif info.draw_obj ~= nil then	
			if _G.EvadeOn and not _G.Evading and info.action.effectRange < 100 and info.draw_obj:is_point_inside(player.pos) then
				if TaskManager:IsBusy() then
					TaskManager:Stop()
				end
				self:DodgeAction(info)
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

		if self:ValidCastType(action) then			
			
			local info    = self:GetActionInfo(action, s)		
			info.draw_obj = self:GetDrawObject(info)

			if not self.current_actions[info.hash] then
				print("Found Evade Action : " .. action.name .. " / " .. action.castType)

				self.current_actions[info.hash] = info

			else
				self.current_actions[info.hash].draw_obj = info.draw_obj
			end
		end
	end	

end

function XEvade:Draw()
	
	for hash, info in pairs(self.current_actions) do
		if info.draw_obj ~= nil then					
			info.draw_obj:draw(Colors.Blue)					
		end
	end

	if _G.Evading and self.evade_pos ~= nil and self.evade_source.isCasting then
		Graphics.DrawLine3D(self.evade_pos, player.pos, Colors.Yellow)
		Graphics.DrawText3D(self.evade_pos, "SAFE SPOT", 10, Colors.Yellow)
		Graphics.DrawCircle3D(self.evade_pos, 3, 1, Colors.Blue)
	end

	if self.menu["DRAWS"]["EVADE_STATUS"].bool then
		local text  = (_G.EvadeOn and "ON") or "OFF"
		local color = (_G.EvadeOn and Colors.Yellow or Colors.Red)
		
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
		return self:GetDrawCircleObj(info)
	elseif info.action.castType == LINE_AOE or info.action.castType == OBJ_COLLISION then
		return self:GetDrawLineObject(info)
	elseif info.action.castType == CONE_SOURCE or info.action.castType == CONE_BEHIND then
		return self:GetDrawConeObject(info)
	end
end

function XEvade:GetDrawCircleObj(info)

	local circle   = Circle()	

	if not info.action.targetArea then
		circle.center = info.source.pos
		circle.radius  = info.action.effectRange + info.source.radius	
	else
		circle.center = info.cast_info.castLocation
		circle.radius  = info.action.effectRange
	end
	
	return circle:polygon(100)
end

function XEvade:GetDrawConeObject(info)
	
	local p          = info.source.pos
	local radius     = info.action.effectRange + info.source.radius
	local multiplier,
		  angle      = self:GetConeMA(info.action)

	local a          = info.source.angle - angle
	local point      = math.pi * 2 / 100	
	

	local poly_points = {}

	table.insert(poly_points, p)

	for angle = 0, math.pi / multiplier , point do

		local s_pos = 
			Vector3(
				p.x - (radius * math.cos(angle + a)),
				p.y,
				p.z + (radius * math.sin(angle + a))
			)
		
		table.insert(poly_points, s_pos)		
	end

	return Polygon(poly_points)
end

function XEvade:GetDrawLineObject(info)
	
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

	local best_pos  = nil
	local best_dist = 10000

	local draw_obj    = info.draw_obj
	local safe_points = 
		draw_obj:get_safe_points(
			player.pos, 
			self.menu["SETTINGS"]["PRECISION"].int, 
			self.menu["SETTINGS"]["EXTRA_HITBOX"].float
		)

	if #safe_points > 0 then
		for i, p in ipairs(safe_points) do
			local dist = player.pos:dist(p)
			if not draw_obj:is_point_inside(p) and dist < best_dist then
				best_pos  = p
				best_dist = dist
			end
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

function XEvade:GetConeMA(action)
	
	if action.degrees == 180 then
		return 1, 1.5
	elseif action.degrees == 120 then
		return 1.5, 1.05
	elseif action.degrees == 90 then
		return 2, 0.75
	elseif action.degrees == 60 then
		return 3, 0.5				
	end

	return 2, 0.75


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