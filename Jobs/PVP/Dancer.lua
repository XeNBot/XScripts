local Dancer = Class("Dancer")

function Dancer:initialize()

	self.actions = {

		cascade    = Action(1, 29416),
		fountain   = Action(1, 29417),

		fan        = Action(1, 29428),
		starfall   = Action(1, 29421),
		honing     = Action(1, 29422),
		waltz      = Action(1, 29429),
		avant      = Action(1, 29430),
		contra     = Action(1, 29432),
	}

	self.menu = nil

end

function Dancer:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["RANGE_DPS_P"]:subMenu("Dancer", "DNC")
		self.menu["ACTIONS"]["RANGE_DPS_P"]["DNC"]:checkbox("Use Fountain Combo",    "FOUNTAIN",  true)
		self.menu["ACTIONS"]["RANGE_DPS_P"]["DNC"]:checkbox("Use Starfall Dance",    "STARFALL",  true)
		self.menu["ACTIONS"]["RANGE_DPS_P"]["DNC"]:checkbox("Use Honing Dance",      "HONING",    true)
		self.menu["ACTIONS"]["RANGE_DPS_P"]["DNC"]:number("Min Enemies for Honing",  "HONINGMIN", 2)
		self.menu["ACTIONS"]["RANGE_DPS_P"]["DNC"]:checkbox("Use Fan Dance",         "FAN",       true)
		self.menu["ACTIONS"]["RANGE_DPS_P"]["DNC"]:checkbox("Use Curing Waltz",      "WALTZ",     true)
		self.menu["ACTIONS"]["RANGE_DPS_P"]["DNC"]:checkbox("Use En Avant",          "AVANT",     true)
		self.menu["ACTIONS"]["RANGE_DPS_P"]["DNC"]:checkbox("Use Contradance",       "CONTRA",    true)
		self.menu["ACTIONS"]["RANGE_DPS_P"]["DNC"]:number("Min Enemies for Contra",  "CONTRAMIN", 3)

end



function Dancer:Tick(getTarget)

	local menu = self.menu["ACTIONS"]["RANGE_DPS_P"]["DNC"]

	if menu["CONTRA"].bool and self.actions.contra:canUse() and ObjectManager.EnemiesAroundObject(player, 15) >= menu["CONTRAMIN"].int then
		self.actions.contra:use()
		return
	elseif menu["WALTZ"].bool and self.actions.waltz:canUse() and player.missingHealth > 8000 and ObjectManager.AlliesAroundObject(player, 5) > 0 then
		self.actions.waltz:use()
		return
	elseif menu["HONING"].bool and self.actions.honing:canUse() and ObjectManager.EnemiesAroundObject(player, 5) >= menu["HONINGMIN"].int then
		self.actions.honing:use()
		return
	end

	local farTarget = getTarget(25)

	if farTarget.valid then
		if  menu["STARFALL"].bool and self.actions.starfall:canUse(farTarget.id) then
			self.actions.starfall:use(farTarget.id)
			return
		elseif menu["AVANT"].bool and farTarget.pos:dist(player.pos) > 15 and self.actions.avant:canUse() then
			player:rotateTo(farTarget.pos)
			self.actions.avant:use()
			return
		end
	end

	local target = getTarget(15)

	if target.valid then
		if menu["FAN"].bool and self.actions.fan:canUse(target.id) then
			self.actions.fan:use(target.id)
		elseif menu["FOUNTAIN"].bool and self.actions.fountain:canUse(target.id) then
			self.actions.fountain:use(target.id)
		elseif menu["FOUNTAIN"].bool and self.actions.cascade:canUse(target.id) then
			self.actions.cascade:use(target.id)
		end
	end

end

return Dancer:new()