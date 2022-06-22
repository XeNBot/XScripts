local Warrior = Class("Warrior")

function Warrior:initialize()

	self.actions = {

		heavyswing   = Action(1, 29074),
		maim         = Action(1, 29075),
		stormpath    = Action(1, 29076),

		fellcleave   = Action(1, 29078),
		onslaught    = Action(1, 29079),
		orogeny      = Action(1, 29080),
		blota        = Action(1, 29081),
		whetting     = Action(1, 29082),
		primalscream = Action(1, 29083),
		primalrend   = Action(1, 29084),

		
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
		self.menu["ACTIONS"]["TANK"]["WAR"]:slider("Min Enemies for Bloodwhetting", "BLOODMIN", 1, 1, 3, 2)
		self.menu["ACTIONS"]["TANK"]["WAR"]:checkbox("Use Primal Scream",           "PRIMAL", true)
		self.menu["ACTIONS"]["TANK"]["WAR"]:slider("Min Enemies for Primal Scream", "PRIMALMIN", 1, 1, 3, 2)
		self.menu["ACTIONS"]["TANK"]["WAR"]:slider("Min Allies for Primal Scream",  "PRIMALMINA", 1, 1, 3, 2)
		

end

function Warrior:Tick(log)
	
	local menu    = self.menu["ACTIONS"]["TANK"]["WAR"]
	
	if menu["PRIMAL"].bool and self.actions.primalscream.ready then

		local enemiesPass = ObjectManager.EnemiesAroundObject(player, 12) >= menu["PRIMALMIN"].int
		local alliesPass  = ObjectManager.AlliesAroundObject(player, 12) >= menu["PRIMALMINA"].int

		if enemiesPass and alliesPass then
			log:print("Using Primal Scream")
			self.actions.primalscream:use()
		end
	end

	if self.actions.fellcleave.ready then
		log:print("Using Fell Cleave on " .. self.actions.fellcleave.target.name)
		self.actions.fellcleave:use()
	elseif menu["SLAUGHT"].bool and self.actions.onslaught.ready and self.actions.onslaught.target.pos:dist(player.pos) > 5 then
		log:print("Using Onslaught on " .. self.actions.onslaught.target.name)
		self.actions.onslaught:use()
	elseif menu["BLOTA"].bool and self.actions.blota.ready and self.actions.blota.target.pos:dist(player.pos) > 5 then
		log:print("Using Blota on " .. self.actions.blota.target.name)
		self.actions.blota:use()
	elseif menu["REND"].bool and self.actions.primalrend.ready and ObjectManager.EnemiesAroundObject(self.actions.primalrend.target, 5) >= menu["RENDMIN"].int then
		log:print("Using Primal Rend on " .. self.actions.primalrend.target.name)
		self.actions.primalrend:use()
	elseif menu["BLOOD"].bool and self.actions.whetting.ready and ObjectManager.EnemiesAroundObject(self.actions.whetting.target, 5) >= menu["BLOODMIN"].int then
		if not player:hasStatus(3030) then
			log:print("Using Blood Whetting on " .. self.actions.whetting.target.name)
		else
			log:print("Using Chaotic Cyclone on " .. self.actions.whetting.target.name)
		end
		self.actions.whetting:use()
	elseif menu["OROGENY"].bool and self.actions.orogeny.ready and ObjectManager.EnemiesAroundObject(self.actions.orogeny.target, 5) >= menu["OROGENYMIN"].int then
		log:print("Using Orogeny on " .. self.actions.orogeny.target.name)
		self.actions.orogeny:use()
	elseif menu["STORM"].bool and self.actions.stormpath.ready then
		log:print("Using Storm's Path on " .. self.actions.stormpath.target.name)
		self.actions.stormpath:use()
	elseif menu["STORM"].bool and self.actions.maim.ready then
		log:print("Using Maim on " .. self.actions.maim.target.name)
		self.actions.maim:use()
	elseif menu["STORM"].bool and self.actions.heavyswing.ready then
		log:print("Using Heavy Swing on " .. self.actions.heavyswing.target.name)
		self.actions.heavyswing:use()
	end

end

return Warrior:new()