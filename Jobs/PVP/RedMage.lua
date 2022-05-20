local RedMage = Class("RedMage")

function RedMage:initialize()

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

function RedMage:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["RANGE_DPS_M"]:subMenu("RedMage", "RDM")
		self.menu["ACTIONS"]["RANGE_DPS_M"]["RDM"]:checkbox("Use Verstone",          "VERSTONE",   true)	
		self.menu["ACTIONS"]["RANGE_DPS_M"]["RDM"]:checkbox("Use Enchanted Riposte", "RIPOSTE",    true)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["RDM"]:checkbox("Use Resolution ",       "RESOLUTION", true)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["RDM"]:checkbox("Use Magic Barrier",     "BARRIER", true)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["RDM"]:slider("Min Allies Barrier",      "BARRIERMIN", 1, 1, 5, 2)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["RDM"]:checkbox("Use Magic Frazzle",     "FRAZZLE", true)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["RDM"]:slider("Min Enemies for Frazzle", "FRAZZLEMIN", 1, 1, 5, 2)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["RDM"]:checkbox("Use Corps-a-corps",     "CORPS", true)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["RDM"]:checkbox("Use Displacement",      "DISPLACEMENT", true)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["RDM"]:checkbox("Use Southern Cross",    "CROSS", true)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["RDM"]:slider("Min Enemies for Cross",   "CROSSMIN", 1, 1, 5, 3)
		

end

function RedMage:HandleAOE(menu, isWhite, log)
	
	if isWhite then
		if menu["BARRIER"].bool and self.actions.barrier:canUse() and ObjectManager.AlliesAroundObject(player, 15) >= menu["BARRIERMIN"].int then
			self.actions.barrier:use()
			log:print("using Barrier")
			return true
		end
	else
		if menu["FRAZZLE"].bool and self.actions.barrier:canUse() and ObjectManager.EnemiesAroundObject(player, 15) >= menu["FRAZZLEMIN"].int then
			self.actions.barrier:use()
			log:print("using Barrier")
			return true
		end
	end
	return false
end

function RedMage:Tick(getTarget, log)

	local menu    = self.menu["ACTIONS"]["RANGE_DPS_M"]["RDM"]
	local isWhite =  player:hasStatus(3245)

	if self:HandleAOE(menu, isWhite, log) then return end

	if menu["CROSS"].bool and self.actions.cross:canUse() and ObjectManager.EnemiesAroundObject(player, 15) >= menu["CROSSMIN"].int then
		self.actions.cross:use()
		return
	end
	
	local target       = getTarget(25)
	local close_target = getTarget(5)

	
	local verholy = player:hasStatus(3233)

	if close_target.valid and close_target.pos:dist(player.pos) <= 5 then
		if menu["DISPLACEMENT"].bool and verholy and self.actions.displacement:canUse(close_target.id) then
			self.actions.displacement:use(close_target.id)
			log:print("Using Displacement on " .. close_target.name)
			return
		elseif menu["RIPOSTE"].bool and self.actions.riposte:canUse(close_target.id) then
			self.actions.riposte:use(close_target.id)
			log:print("Using Riposte on " .. close_target.name)
			return
		end
	end

	if target.valid then
		if menu["VERSTONE"].bool and player:hasStatus(1393) and self.actions.verstone:canUse(target.id) then
			self.actions.verstone:use(target.id)
			if isWhite then
				log:print("Using Veraero III on " .. target.name)
			else
				log:print("Using Verthunder III on " .. target.name)
			end
		elseif menu["RIPOSTE"].bool and verholy and self.actions.riposte:canUse(target.id) then
			self.actions.riposte:use(target.id)
			log:print("Using Verholy on " .. target.name)
		elseif menu["CORPS"] and target.pos:dist(player.pos) > 6 and self.actions.corps:canUse(target.id) and self.actions.riposte:canUse(target.id) then
			self.actions.corps:use(target.id)
			log:print("Using Corps-a-corps on " .. target.name)
		elseif menu["RESOLUTION"].bool and self.actions.resolution:canUse(target.id) then
			self.actions.resolution:use(target.id)
			log:print("Using Resolution on " .. target.name)
		elseif menu["VERSTONE"].bool and self.actions.verstone:canUse(target.id) then
			self.actions.verstone:use(target.id)
			if isWhite then
				log:print("Using Verstone on " .. target.name)
			else
				log:print("Using Verfire  on " .. target.name)
			end
		end
	end

end

return RedMage:new()