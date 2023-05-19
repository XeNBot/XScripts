local Mission  = LoadModule("XScripts", "/Missions/Mission")

local TotoRak  = Class("TotoRak", Mission)

function TotoRak:initialize()

    Mission.initialize(self)

    self.destination = Vector3(237.77,-38.91,-144.02)

end

return TotoRak:new()