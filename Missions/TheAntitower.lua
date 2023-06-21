local Mission  = LoadModule("XScripts", "/Missions/Mission")

local TheAntitower = Class("TheAntitower", Mission)

function TheAntitower:initialize()

	Mission.initialize(self)

	self.battle_fov      = 30
	
	self:SetMaps({[277] = true, [278] = true, [279] = true})

	self.platflorms = {
		{
			poly = Polygon({
				Vector3(-314.71,220,127.54),
				Vector3(-321.45,220,131.17),
				Vector3(-324.09,220.21,139.95),
				Vector3(-319.7,219.99,175.7),
				Vector3(-308.5,219.99,177.94),
				Vector3(-305.81,220.21,140.77),
				Vector3(-307.51,220,135.01),
			}),

			dest = Vector3(-314.86,220,133.85)
		},
		{
			poly = Polygon({
				Vector3(-324.35,254.99,76.18),
				Vector3(-312.94,255,70.82),
				Vector3(-341.13,255,8.32),
				Vector3(-346.26,255,-2.78),
				Vector3(-355.15,255,-4.81),
				Vector3(-359.17,255,4.14),
				Vector3(-353.35,255,15.54)
			}),

			dest = Vector3(-352.29,255,1.78)
		},
		{
			poly = Polygon({
				Vector3(-372.47,289.99,-54.81),
				Vector3(-357.56,290,-54.49),
				Vector3(-357.51,290,-121.42),
				Vector3(-357.53,290,-131.97),
				Vector3(-364.79,290,-139.46),
				Vector3(-372.41,290,-132.37),
				Vector3(-372.5,290,-121.41)
			}),

			dest = Vector3(-364.73,290,-134.16)
		}
		

	}


	self.destination     = Vector3(-364.91,325,-280.32)	
end

function TheAntitower:Draw()
	for i, platform in ipairs(self.platflorms) do
		platform.poly:draw_debug(Colors.Blue)
	end

end

function TheAntitower:BeforeTick()
	if self.map_id == 277 then
		self.destination = Vector3(-364.91,325,-280.32)

		for i, platform in ipairs(self.platflorms) do
			if platform.poly:is_point_inside(player.pos) then
				self.destination = platform.dest
			end
		end

	elseif self.map_id == 278 then
		self.destination = Vector3(218.08,-22.1,137.23)
	elseif self.map_id == 279 then
		self.destination = Vector3(231.86,-9.46,-182.32)
	end	
end

return TheAntitower:new()