local Mission  = LoadModule("XScripts", "/Missions/Mission")

local Snowcloak = Class("Snowcloak", Mission)

function Snowcloak:initialize()

    Mission.initialize(self)

	self.battle_fov    =  50

    self.event_objects = {
		-- Door to Silence
		[2004203] = true,
		-- Door to Oblivion
		[2004224] = true,
		-- Tiny Key
		[2004225] = true,
		-- Finger of the Apostate
		[2004226] = true,
	}

	self.destination  = Vector3(17.41,40.06,66.91)
end

return Snowcloak:new()