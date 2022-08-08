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
	self.lastJumpChange = 0

end

function Dancer:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["RANGE_DPS_P"]:subMenu("Dancer", "DNC")
		self.menu["ACTIONS"]["RANGE_DPS_P"]["DNC"]:checkbox("Use Fountain Combo",    "FOUNTAIN",  true)
		self.menu["ACTIONS"]["RANGE_DPS_P"]["DNC"]:checkbox("Use Starfall Dance",    "STARFALL",  true)
		self.menu["ACTIONS"]["RANGE_DPS_P"]["DNC"]:checkbox("Use Honing Dance",      "HONING",    true)
		self.menu["ACTIONS"]["RANGE_DPS_P"]["DNC"]:number("Min Enemies for Honing",  "HONINGMIN", 2)
		self.menu["ACTIONS"]["RANGE_DPS_P"]["DNC"]:checkbox("Use Fan Dance",         "FAN",        true)
		self.menu["ACTIONS"]["RANGE_DPS_P"]["DNC"]:checkbox("Use Curing Waltz",      "WALTZ",      true)
		self.menu["ACTIONS"]["RANGE_DPS_P"]["DNC"]:checkbox("Use En Avant",          "AVANT",      true)
		self.menu["ACTIONS"]["RANGE_DPS_P"]["DNC"]:number("Minimum Target Range",    "AVANTRANGE", 25)
		self.menu["ACTIONS"]["RANGE_DPS_P"]["DNC"]:checkbox("Use Contradance",       "CONTRA",     true)
		self.menu["ACTIONS"]["RANGE_DPS_P"]["DNC"]:number("Min Enemies for Contra",  "CONTRAMIN",  3)
		self.menu["ACTIONS"]["RANGE_DPS_P"]["DNC"]:slider("Max Enemy Range",         "CONTRARANGE", 1, 1, 15, 9)

end


function Dancer:HandleJumpToggle(log, menu)
	
	if self.menu["JUMP_KEY"].keyDown and (os.clock() - self.lastJumpChange) > 1 then
		local menuName = "AVANT"

		if menu[menuName].bool then 
			menu[menuName].bool = false
		else
			menu[menuName].bool = true
		end
		log:print("Changed Jump Toggle to " .. tostring(menu[menuName].bool))
		self.lastJumpChange = os.clock()
		return true
	end

	return false
end

function Dancer:Tick(getTarget, log)

	local menu  = self.menu["ACTIONS"]["RANGE_DPS_P"]["DNC"]

	if self:HandleJumpToggle(log, menu) then return end

	if menu["CONTRA"].bool and self.actions.contra:canUse() and ObjectManager.EnemiesAroundObject(player, menu["CONTRARANGE"].int) >= menu["CONTRAMIN"].int then
		self.actions.contra:use()
		log:print("Using Contradance")
	elseif menu["WALTZ"].bool and self.actions.waltz:canUse() and player.missingHealth > 8000 and ObjectManager.AlliesAroundObject(player, 5) > 0 then
		self.actions.waltz:use()
		log:print("Using Curing Waltz")
	elseif menu["HONING"].bool and self.actions.honing:canUse() and ObjectManager.EnemiesAroundObject(player, 5) >= menu["HONINGMIN"].int then
		self.actions.honing:use()
		log:print("Using Honing Dance")
	end

	local farTarget = getTarget(menu["AVANTRANGE"].int)

	if farTarget.valid then
		if  menu["STARFALL"].bool and self.actions.starfall:canUse(farTarget) then
			self.actions.starfall:use(farTarget)
			log:print("Using Starfall Dance on " .. farTarget.name)
		elseif menu["AVANT"].bool and farTarget.yalmX > 15 and self.actions.avant:canUse() then
			player:rotateTo(farTarget.pos)
			self.actions.avant:use()
			log:print("Using En Avant on " .. farTarget.name)
		end
	end

	local target = getTarget(15)

	if target.valid then
		if menu["FAN"].bool and self.actions.fan:canUse(target) then
			self.actions.fan:use(target)
			log:print("Using Fan Dance on " .. target.name)
		elseif menu["FOUNTAIN"].bool and self.actions.fountain:canUse(target) then
			self.actions.fountain:use(target)
			log:print("Using Fountain on " .. target.name)
		elseif menu["FOUNTAIN"].bool and self.actions.cascade:canUse(target) then
			self.actions.cascade:use(target)
			log:print("Using Cascade on " .. target.name)
		end
	end

end

return Dancer:new()