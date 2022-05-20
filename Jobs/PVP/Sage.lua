local Sage = Class("Sage")

function Sage:initialize()

	self.actions = {

		dosis     = Action(1, 29256),
		phlegma   = Action(1, 29259),
		toxikon   = Action(1, 29262),
		kardia    = Action(1, 29264),
		pneuma    = Action(1, 29260),
		eukrasia  = Action(1, 29258),
		mesotes   = Action(1, 29266),


	}

	self.menu = nil	
end

function Sage:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["HEALER"]:subMenu("Sage", "SGE")
		self.menu["ACTIONS"]["HEALER"]["SGE"]:checkbox("Use Dosis III",         "DOSIS", true)	
		self.menu["ACTIONS"]["HEALER"]["SGE"]:checkbox("Use Phlegma III",       "PHLEGMA", true)
		self.menu["ACTIONS"]["HEALER"]["SGE"]:checkbox("Use Pneuma",            "PNEUMA", true)
		self.menu["ACTIONS"]["HEALER"]["SGE"]:checkbox("Use Eukrasia",          "EUKRASIA", true)
		self.menu["ACTIONS"]["HEALER"]["SGE"]:slider("Min Enemies for Phlegma", "PHLEGMAMIN", 1, 1, 5, 1)
		self.menu["ACTIONS"]["HEALER"]["SGE"]:checkbox("Use Toxikon",           "TOXIKON", true)
		self.menu["ACTIONS"]["HEALER"]["SGE"]:slider("Min Enemies for Toxikon", "TOXIKONMIN", 1, 1, 5, 2)
		self.menu["ACTIONS"]["HEALER"]["SGE"]:checkbox("Use Kardia",            "KARDIA", true)
		self.menu["ACTIONS"]["HEALER"]["SGE"]:checkbox("Use Mesotes",           "MESOTES", true)
		self.menu["ACTIONS"]["HEALER"]["SGE"]:slider("Min Enemies for Mesotes", "MESOTESMIN", 1, 1, 5, 3)
end

function Sage:AutoHeal(log)
	
	for i, ally in ipairs(ObjectManager.GetAllyPlayers(function (ally)
			local healPotency = (ally.healthPercent < 50 and 8000) or 4000
	 		return ally.missingHealth > healPotency and ally.health > 0 
	 	end)) do
		if ally.pos:dist(player.pos) < 29 and self.actions.benefic:canUse(ally.id) then
			self.actions.benefic:use(ally.id)
			log:print("Using Aspected Benefic to Heal " .. ally.name)
			return true
		end
	end

	return false
end

function Sage:Mesotes(log, menu)

	local list = AgentModule.currentMapId == 51 and ObjectManager.Battle() or ObjectManager.GetEnemyPlayers()

	for i, object in ipairs(list) do

		if ObjectManager.EnemiesAroundObject(object, 5) >= menu["MESOTESMIN"].int then
			self.actions.mesotes:use(object.pos)
			log:print("Using Mesotes on " .. object.name)
			return true
		end
	end
	return false
	
end

function Sage:Tick(getTarget, log)

	local menu = self.menu["ACTIONS"]["HEALER"]["SGE"]	

	if self.actions.mesotes:canUse() and menu["MESOTES"].bool and self:Mesotes(log, menu) then return end

	local target      = getTarget(25)
	local closeTarget = getTarget(5)

	if menu["KARDIA"].bool and self.actions.kardia:canUse() and not player:hasStatus(2872) then
		self.actions.kardia:use()
		log:print("Using Kardia")
		return
	end

	if closeTarget.valid and self.actions.phlegma:canUse(closeTarget.id) and menu["PHLEGMA"].bool and ObjectManager.EnemiesAroundObject(closeTarget, 5) >= menu["PHLEGMAMIN"].int then
		self.actions.phlegma:use(closeTarget.id)
		log:print("Using Phlegma on " .. closeTarget.name)
	elseif target.valid then		
		if  self.actions.toxikon:canUse(target.id) and ObjectManager.EnemiesAroundObject(target, 5) >= menu["TOXIKONMIN"].int  and menu["TOXIKON"].bool then
			self.actions.toxikon:use(target.id)
			log:print("Using Toxikon on " .. target.name)	
		elseif self.actions.pneuma:canUse(target.id) and menu["PNEUMA"].bool then
			self.actions.pneuma:use(target.id)
			log:print("Using Pneuma on " .. target.name)	
		elseif self.actions.eukrasia:canUse() and menu["EUKRASIA"].bool and not player:hasStatus(3107) then
			self.actions.eukrasia:use()
			log:print("Using Ekrasia")		
		elseif  self.actions.dosis:canUse(target.id) and menu["DOSIS"].bool then
			self.actions.dosis:use(target.id)
			log:print("Using Dosis III on " .. target.name)		
		end
	end

end

return Sage:new()