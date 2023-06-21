local Mission  = LoadModule("XScripts", "/Missions/Mission")

local TheAntitower = Class("TheAntitower", Mission)

function TheAntitower:initialize()

	Mission.initialize(self)

	self.battle_fov      = 30
	
	self:SetMaps({[277] = true, [278] = true, [279] = true})

	self.platflorms = {
		{
			poly = Polygon({
				Vector3(-320.74,220,146.1),
				Vector3(-307.16,220.11,146.11),
				Vector3(-308.5,219.99,177.94),
				Vector3(-319.7,219.99,175.7)
			}),

			dest = Vector3(-314.86,220,133.85)
		},
		{
			poly = Polygon({
				Vector3(-324.35,254.99,76.18),
				Vector3(-312.94,255,70.82),
				Vector3(-341.13,255,8.32),
				Vector3(-353.35,255,15.54)
			}),

			dest = Vector3(-352.29,255,1.78)
		},
		{
			poly = Polygon({
				Vector3(-372.47,289.99,-54.81),
				Vector3(-357.56,290,-54.49),
				Vector3(-357.51,290,-121.42),
				Vector3(-372.5,290,-121.41)
			}),

			dest = Vector3(-364.73,290,-134.16)
		}
		

	}


	self.destination     = Vector3(-364.91,325,-280.32)	
end

function TheAntitower:BeforeTick()
	if self.map_id == 277 then
		self.destination = Vector3(-364.91,325,-280.32)
	elseif self.map_id == 278 then
		self.destination = Vector3(218.08,-22.1,137.23)
	elseif self.map_id == 279 then
		self.destination = Vector3(231.86,-9.46,-182.32)
	end
	for i, platform in ipairs(self.platflorms) do
		if platform.poly:is_point_inside(player.pos) then
			self.destination = platform.dest
		end
	end
end

return TheAntitower:new()