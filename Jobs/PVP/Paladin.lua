local Paladin = Class("Paladin")

function Paladin:initialize()

	self.actions = {

		fastblade = Action(1, 29058),
		riotblade = Action(1, 29059),
		royal     = Action(1, 29060),
		atonement = Action(1, 29061),
		bash      = Action(1, 29064),
		intervene = Action(1, 29065),
		sheltron  = Action(1, 29067),
		phalanx   = Action(1, 29069),
		confiteor = Action(1, 29070),
		
	}

	self.menu = nil
	self.limitBreaking = false

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

function Paladin:Tick(log)
	
	local menu = self.menu["ACTIONS"]["TANK"]["PLD"]

	if menu["PHALANX"].bool then
		self:Phalanx(menu, log)
	end

	if menu["SHELTRON"].bool and self.actions.sheltron:canUse() and player.missingHealth >= 1200 and ObjectManager.EnemiesAroundObject(player, 5) > 0 then
		log:print("Using Holy Sheltron")
		self.actions.sheltron:use()
	elseif menu["CONFITEOR"].bool and self.actions.confiteor.ready and ObjectManager.EnemiesAroundObject(self.actions.confiteor.target, 5) >= menu["CONFITEORMIN"].int then
		log:print("Using Confiteor on " .. self.actions.confiteor.target.name)
		self.actions.confiteor:use()
	elseif self.actions.atonement.ready then
		log:print("Using Atonement on " .. self.actions.atonement.target.name)
		self.actions.atonement:use()
	elseif menu["BASH"].bool and self.actions.bash.ready then
		log:print("Using Bash on " .. self.actions.bash.target.name)
		self.actions.bash:use()
	elseif menu["INTERVENE"].bool and self.actions.intervene.ready then
		log:print("Using Intervene on " .. self.actions.intervene.target.name)
		self.actions.intervene:use()
	elseif menu["ROYAL"].bool and self.actions.riotblade.ready then
		log:print("Using Riot Blade on " .. self.actions.riotblade.target.name)
		self.actions.riotblade:use()
	elseif menu["ROYAL"].bool and self.actions.fastblade.ready then
		log:print("Using Fast Blade on " .. self.actions.fastblade.target.name)
		self.actions.fastblade:use()
	end
end

function Paladin:Phalanx(menu, log)

	if not self.actions.phalanx.ready then

		if self.limitBreaking then
			self.limitBreaking = false
		end
		return
	end

	if not self.limitBreaking then

		local enemiesAround = ObjectManager.EnemiesAroundObject(player, 15)
		local alliesAround  = ObjectManager.EnemiesAroundObject(player, 15)

		if enemiesAround >= menu["PHALANXMIN"].int and alliesAround >= menu["PHALANXMINA"].int then
			log:print("Using Phalanx")
			self.actions.phalanx:use()
		end
	else
		log:print("Using Phalanx on " .. self.actions.phalanx.target.name)
		self.actions.phalanx:use()
	end	
	

end

return Paladin:new()