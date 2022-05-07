local Summoner = Class("Summoner")

function Summoner:initialize()

	self.actions = {

		ruin       = Action(1, 29664),
		cyclone    = Action(1, 29667),
		stream     = Action(1, 29669),
		aegis      = Action(1, 29670),
		buster     = Action(1, 29671),
		fester     = Action(1, 29672),
		
		bahamut    = Action(1, 29673),
		phoenix    = Action(1, 29678),
	}

	self.menu = nil

end

function Summoner:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["RANGE_DPS_M"]:subMenu("Summoner", "SMN")
		self.menu["ACTIONS"]["RANGE_DPS_M"]["SMN"]:checkbox("Use Ruin III",        "RUIN",      true)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["SMN"]:checkbox("Use Crimson Cyclone", "CYCLONE",   true)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["SMN"]:checkbox("Use Slipstream",      "STREAM",    true)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["SMN"]:number("Min Slipstream Enemies","STREAMMIN", 2)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["SMN"]:checkbox("Use Radiant Aegis",   "AEGIS",     true)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["SMN"]:checkbox("Use Mountain Buster", "BUSTER",    true)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["SMN"]:checkbox("Use Fester",          "FESTER",    true)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["SMN"]:checkbox("Use Bahamut",         "BAHAMUT",   true)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["SMN"]:checkbox("Use Phoenix",         "PHOENIX",   true)
		

end



function Summoner:Execute()
	return false
end

function Summoner:Tick(getTarget)

	local menu = self.menu["ACTIONS"]["RANGE_DPS_M"]["SMN"]
	
	local target = getTarget(25)

	if target.valid then
		if menu["STREAM"].bool and self.actions.stream:canUse(target.id) and ObjectManager.EnemiesAroundObject(target, 10) >= menu["STREAM"].int then
			self.actions.stream:use(target.id)
		if menu["RUIN"].bool and self.actions.ruin:canUse(target.id) then
			self.actions.ruin:use(target.id)
		end
	end

end

return Summoner:new()