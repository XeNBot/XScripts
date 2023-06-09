local MathUtils   = Class("MathUtils")

function MathUtils:GetLineActionPolygon(source, width, lenght)

    local pos = source.pos
	local w   = width
	local l   = lenght
	local a   = source.angle
	local r   = source.rotation

	local start_point       = Vector3(pos.x - (w * math.cos(r)), pos.y, pos.z + (w * math.sin(r)))
	local start_point2      = Vector3(pos.x + (w * math.cos(r)), pos.y, pos.z - (w * math.sin(r)))
	local direction_point   = Vector3(start_point.x  - (l * math.cos(a)), start_point.y,  start_point.z +  (l * math.sin(a)))
	local direction_point2  = Vector3(start_point2.x - (l * math.cos(a)), start_point2.y, start_point2.z + (l * math.sin(a)))

	local poly = Polygon({ start_point, start_point2, direction_point2, direction_point })

	return poly
end

function MathUtils:GetStraightLinePos(source, lenght)
	local pos =  source.pos
	local a   =  player.angle
	local l   =  lenght
	local direction_point   = Vector3(pos.x  - (l * math.cos(a)), pos.y,  pos.z +  (l * math.sin(a)))
	
	return direction_point
end

return MathUtils:new()