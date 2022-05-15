local Knight = Class("Knight")

function Knight:initialize()

	self.actions = {

		--- Soul Eater Combo
		slash    = Action(1, 29085),
		syphon   = Action(1, 29086),
		soul     = Action(1, 29087),

		quietus  = Action(1, 29737),
		shadow   = Action(1, 29091),
		plunge   = Action(1, 29092),
		night    = Action(1, 29093),
		earth    = Action(1, 29094),

		eventide = Action(1, 29097)
		
	}

	self.menu = nil

end

function Knight:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["TANK"]:subMenu("Dark Knight", "DRK")
		self.menu["ACTIONS"]["TANK"]["DRK"]:checkbox("Use Soul Eater Combo",   "SOUL", true)
		self.menu["ACTIONS"]["TANK"]["DRK"]:checkbox("Use Quietus",            "QUIET", true)
		self.menu["ACTIONS"]["TANK"]["DRK"]:number("Min Enemies for Quietus",  "QUIETMIN", 2)
		self.menu["ACTIONS"]["TANK"]["DRK"]:checkbox("Use Shadowbringer",      "SHADOW", true)
		self.menu["ACTIONS"]["TANK"]["DRK"]:checkbox("Use Plunge",             "PLUNGE", true)
		self.menu["ACTIONS"]["TANK"]["DRK"]:checkbox("Use The Blackest Night", "NIGHT", true)
		self.menu["ACTIONS"]["TANK"]["DRK"]:checkbox("Use Salted Earth",       "EARTH", true)
		self.menu["ACTIONS"]["TANK"]["DRK"]:number("Min Enemies for Salted",   "EARTHMIN", 3)
		self.menu["ACTIONS"]["TANK"]["DRK"]:checkbox("Use Event Tide",         "EVENTTIDE", true)

		
end

function Knight:Tick(getTarget, log)

	local menu = self.menu["ACTIONS"]["TANK"]["DRK"]

	if self.actions.eventide:canUse() and ObjectManager.EnemiesAroundObject(player, 10) >= 3 then
		self.actions.eventide:use()
		log:print("Using Event Tide")
		return
	elseif menu["EARTH"].bool and ObjectManager.EnemiesAroundObject(player, 10) >= menu["EARTHMIN"].int and self.actions.earth:canUse() then
		log:print("Using Salted Earth")
		self.actions.earth:use()
		return
	elseif menu["QUIET"].bool and ObjectManager.EnemiesAroundObject(player, 5) >= menu["QUIETMIN"].int and self.actions.quietus:canUse() then		
		self.actions.quietus:use()
		log:print("Using Quietus")
		return
	end

	local farTarget = getTarget(19.5)

	if farTarget.valid and menu["PLUNGE"].bool and self.actions.plunge:canUse(farTarget.id) then
		self.actions.plunge:use(farTarget.id)
		log:print("Using Plunge On " .. farTarget.name)
		return
	end

	local target = getTarget(5)

	if target ~= nil and target.valid then
		if menu["SOUL"].bool and self.actions.night:canUse() then
			self.actions.night:use()
			log:print("Using Blackest Night On " .. target.name)
		elseif menu["SOUL"].bool and self.actions.shadow:canUse(target.id) and player.health > 30000 and player.mana > 5000 then
			self.actions.shadow:use(target.id)
		elseif menu["SOUL"].bool and self.actions.soul:canUse(target.id) then
			self.actions.soul:use(target.id)
		elseif menu["SOUL"].bool and self.actions.syphon:canUse(target.id) then
			self.actions.syphon:use(target.id)
		elseif menu["SOUL"].bool and self.actions.slash:canUse(target.id) then
			self.actions.slash:use(target.id)
		end
	end
	
end

return Knight:new()