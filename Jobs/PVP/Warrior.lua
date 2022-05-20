local Warrior = Class("Warrior")

function Warrior:initialize()

	self.actions = {

		
		
	}

	self.menu = nil

end

function Warrior:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["TANK"]:subMenu("Warrior", "WAR")
		self.menu["ACTIONS"]["TANK"]["WAR"]:checkbox("Use Storm's Path Combo",      "STORM", true)
		self.menu["ACTIONS"]["TANK"]["WAR"]:checkbox("Primal Rend",                 "REND", true)
		self.menu["ACTIONS"]["TANK"]["WAR"]:slider("Min Enemies for Rend",          "RENDMIN", 1, 1, 3, 2)
		self.menu["ACTIONS"]["TANK"]["WAR"]:checkbox("Use Onslaught",               "SLAUGHT", true)
		self.menu["ACTIONS"]["TANK"]["WAR"]:checkbox("Use Orogeny",                 "OROGENY", true)
		self.menu["ACTIONS"]["TANK"]["WAR"]:slider("Min Enemies for Orogeny",       "OROGENYMIN", 1, 1, 3, 2)
		self.menu["ACTIONS"]["TANK"]["WAR"]:checkbox("Use Blota",                   "BLOTA", true)
		self.menu["ACTIONS"]["TANK"]["WAR"]:checkbox("Use Bloodwhetting",           "BLOOD", true)
		self.menu["ACTIONS"]["TANK"]["WAR"]:checkbox("Use Primal Scream",           "PRIMAL", true)
		self.menu["ACTIONS"]["TANK"]["WAR"]:slider("Min Enemies for Primal",        "PRIMALMIN", 1, 1, 3, 2)
		

end

function Warrior:Tick(getTarget, log)
	
	local menu    = self.menu["ACTIONS"]["TANK"]["WAR"]
	local actions = self.actions


end

return Warrior:new()