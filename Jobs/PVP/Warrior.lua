local Warrior = Class("Warrior")

function Warrior:initialize()

	self.actions = {

		heavyswing = Action(1, 29074),
		maim       = Action(1, 29075),
		stormpath  = Action(1, 29076),
		onslaught  = Action(1, 29079),
		orogeny    = Action(1, 29080),
		blota      = Action(1, 29081),
		whetting   = Action(1, 29082),
		primal     = Action(1, 29084),

		
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

function Warrior:Tick(log)
	
	local menu    = self.menu["ACTIONS"]["TANK"]["WAR"]
	local actions = self.actions

	if menu["BLOOD"].bool and actions.whetting.ready then
		log:print("Using Blood Whetting on " .. actions.whetting.target.name)
		actions.whetting:use()
	elseif menu["REND"].bool and actions.primal.ready and ObjectManager.EnemiesAroundObject(actions.primal.target, 5) >= menu["RENDMIN"].int then
		log:print("Using Primal Rend on " .. actions.primal.target.name)
		actions.primal:use()
	elseif menu["BLOTA"].bool and actions.blota.ready then
		log:print("Using Blota on " .. actions.blota.target.name)
		actions.blota:use()
	elseif menu["SLAUGHT"].bool and actions.onslaught.ready then
		log:print("Using Onslaught on " .. actions.onslaught.target.name)
		actions.onslaught:use()		
	elseif menu["OROGENY"].bool and actions.orogeny.ready then
		log:print("Using Orogeny on " .. actions.orogeny.target.name)
		actions.orogeny:use()
	elseif menu["STORM"].bool and actions.stormpath.ready then
		log:print("Using Storm Path Combo on " .. actions.stormpath.target.name)
		actions.stormpath:use()
	end

end

return Warrior:new()