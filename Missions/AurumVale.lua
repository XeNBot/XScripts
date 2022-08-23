local Mission  = LoadModule("XScripts", "/Missions/Mission")

local AurumVale = Class("AurumVale", Mission)

function AurumVale:initialize()

	Mission.initialize(self)

	self.goldLung = 302

	self.fruits = {

		[2000778] = true,
		[2002647] = true,
		[2002648] = true,
		[2002649] = true,
		[2002650] = true,
		[2002651] = true,
		[2002652] = true,
		[2002653] = true,
		[2002654] = true,
		[2002655] = true,
		[2002656] = true,
		[2002657] = true,
		[2002658] = true,
		[2002659] = true,
		[2002660] = true,
		[2002661] = true,
		[2002662] = true,
		[2002663] = true,
	}
	
end

function AurumVale:Tick()
	
	local goldLungs = player:getStatus(self.goldLung)

	if goldLungs.valid and goldLungs.count >= 2 then
		print("bruh we gotta grab a fruit")
	end


	Mission.Tick(self)

end

return AurumVale:new()