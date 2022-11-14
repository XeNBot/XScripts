local Mission  = LoadModule("XScripts", "/Missions/Mission")

local StoneVigil = Class("StoneVigil", Mission)

function StoneVigil:initialize()
	Mission.initialize(self)

	self.bosses = {
		-- Koshchei
		[1678] = true
	}


end

return StoneVigil:new()