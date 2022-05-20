local Paladin = Class("Paladin")

function Paladin:initialize()

	self.actions = {

		
		
	}

	self.menu = nil

end

function Paladin:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["TANK"]:subMenu("Paladin", "PLD")
		self.menu["ACTIONS"]["TANK"]["PLD"]:checkbox("Use Royal Authority Combo",   "ROYAL", true)
		self.menu["ACTIONS"]["TANK"]["PLD"]:checkbox("Use Confiteor",               "CONFITEOR", true)
		self.menu["ACTIONS"]["TANK"]["PLD"]:slider("Min Enemies for Confiteor",     "CONFITEORMIN", 1, 1, 3, 2)
		self.menu["ACTIONS"]["TANK"]["PLD"]:checkbox("Use Shield Bash",             "BASH", true)
		self.menu["ACTIONS"]["TANK"]["PLD"]:checkbox("Use Intervene",               "INTERVENE", true)
		self.menu["ACTIONS"]["TANK"]["PLD"]:checkbox("Use Guardian",                "GUARDIAN", true)
		self.menu["ACTIONS"]["TANK"]["PLD"]:checkbox("Use Holy Sheltron",           "SHELTRON", true)
		self.menu["ACTIONS"]["TANK"]["PLD"]:checkbox("Use Phalanx",                 "PHALANX", true)
		self.menu["ACTIONS"]["TANK"]["PLD"]:slider("Min Allies for Phalanx",        "PHALANXMINA", 1, 1, 3, 2)
		self.menu["ACTIONS"]["TANK"]["PLD"]:slider("Min Enemies for Phalanx",       "PHALANXMIN", 1, 1, 3, 2)
		

end

function Paladin:Tick(getTarget, log)
	
	local menu    = self.menu["ACTIONS"]["TANK"]["PLD"]
	local actions = self.actions


end

return Paladin:new()