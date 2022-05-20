local BlackMage = Class("BlackMage")

function BlackMage:initialize()

	self.actions = {

		verstone     = Action(1, 29683),
		riposte      = Action(1, 29689),
		resolution   = Action(1, 29695),
		barrier      = Action(1, 29697),
		corps        = Action(1, 29699),
		displacement = Action(1, 29700),
		cross        = Action(1, 29704),
	}

	self.menu = nil

end

function BlackMage:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["RANGE_DPS_M"]:subMenu("BlackMage", "BLM")
		self.menu["ACTIONS"]["RANGE_DPS_M"]["BLM"]:checkbox("Use Fire",                  "FIRE",   true)	
		self.menu["ACTIONS"]["RANGE_DPS_M"]["BLM"]:checkbox("Use Blizzard",              "RIPOSTE",    true)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["BLM"]:checkbox("Use Burst",                 "BURST", true)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["BLM"]:slider("Min Enemies for Burst",       "BURSTMIN", 1, 1, 5, 2)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["BLM"]:checkbox("Use Paradox",               "PARADOX", true)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["BLM"]:checkbox("Use Night Wing",            "WING", true)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["BLM"]:slider("Min Enemies for Night Wing",  "WINGMIN", 1, 1, 5, 2)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["BLM"]:checkbox("Use Atherial Manipulation", "MANIPULATION", true)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["BLM"]:checkbox("Use Superflare",            "FLARE", true)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["BLM"]:slider("Min Stacks  for flare",       "FLAREMINS", 1, 1, 3, 3)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["BLM"]:slider("Min Enemies for flare",       "FLOREMIN", 1, 1, 3, 2)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["BLM"]:checkbox("Use Soul Resonance",        "SOUL", true)

		

end

function BlackMage:Tick(getTarget, log)

	local menu    = self.menu["ACTIONS"]["RANGE_DPS_M"]["BLM"]
	
	local target       = getTarget(25)

	if target.valid then

	end


end

return BlackMage:new()