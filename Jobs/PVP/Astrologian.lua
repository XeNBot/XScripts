local Astrologian = Class("Astrologian")

function Astrologian:initialize()

	self.actions = {

		malefic   = Action(1, 29242),
		benefic   = Action(1, 29243),
		cosmos    = Action(1, 29253),
		gravity   = Action(1, 29244),
		double    = Action(1, 29245),
		draw      = Action(1, 29249),
		river     = Action(1, 29255)
	}

	self.menu = nil
	self.last_spell_id = 0;

	Callbacks:Add(CALLBACK_ACTION_REQUESTED, function(actionType, actionId, targetId, result)
		if result == 1 and actionType == 1 then
			self.last_spell_id = actionId
		end
	end)	
end

function Astrologian:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["HEALER"]:subMenu("Astrologian", "AST")
		self.menu["ACTIONS"]["HEALER"]["AST"]:checkbox("Use Fall Malefic",      "MALEFIC", true)
		self.menu["ACTIONS"]["HEALER"]["AST"]:checkbox("Use Aspected Benefic",  "BENEFIC", true)
		self.menu["ACTIONS"]["HEALER"]["AST"]:checkbox("Use Gravity II",        "GRAVITY", true)
		self.menu["ACTIONS"]["HEALER"]["AST"]:slider("Min Enemies for Gravity", "GRAVITYMIN", 1, 1, 5, 2)
		self.menu["ACTIONS"]["HEALER"]["AST"]:checkbox("Use Double Cast",       "DOUBLE", true)
		self.menu["ACTIONS"]["HEALER"]["AST"]:checkbox("Use Double Draw",       "DRAW",   true)
		self.menu["ACTIONS"]["HEALER"]["AST"]:slider("Min Allies for Draw",     "DRAWMIN", 1, 1, 5, 2)
		self.menu["ACTIONS"]["HEALER"]["AST"]:checkbox("Use Macrocosmos",       "COSMOS", true)
		self.menu["ACTIONS"]["HEALER"]["AST"]:slider("Min Enemies Cosmos",      "COSMOSMIN", 1, 1, 5, 2)
		self.menu["ACTIONS"]["HEALER"]["AST"]:slider("Min Allies Cosmos",       "COSMOSMINA", 1, 1, 5, 2)
		self.menu["ACTIONS"]["HEALER"]["AST"]:checkbox("Use Celestial River",   "RIVER", true)
		self.menu["ACTIONS"]["HEALER"]["AST"]:slider("Min Enemies River",       "RIVERMIN", 1, 1, 5, 2)
		self.menu["ACTIONS"]["HEALER"]["AST"]:slider("Min Allies River",        "RIVERMINA", 1, 1, 5, 2)

		
end

function Astrologian:AutoHeal(log)
	
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

function Astrologian:Tick(getTarget, log)

	local menu = self.menu["ACTIONS"]["HEALER"]["AST"]

	if menu["BENEFIC"].bool and self:AutoHeal(log) then return end

	if menu["RIVER"].bool and self.actions.river:canUse() and 
		ObjectManager.EnemiesAroundObject(player, 15) >= menu["RIVERMIN"].int and ObjectManager.AlliesAroundObject(player, 15) >= menu["RIVERMINA"].int then
		self.actions.cosmos:use()
		log:print("Using Celestial River")
		return
	end

	if menu["COSMOS"].bool and self.actions.cosmos:canUse() and 
		ObjectManager.EnemiesAroundObject(player, 20) >= menu["COSMOSMIN"].int and ObjectManager.AlliesAroundObject(player, 20) >= menu["COSMOSMINA"].int then
		self.actions.cosmos:use()
		log:print("Using Macrocosmos")
		return
	end

	if self.actions.draw:canUse() and menu["DRAW"].bool and ObjectManager.AlliesAroundObject(player, 20) >= menu["DRAWMIN"].int then
		self.actions.draw:use()
		return
	end

	local target = getTarget(25)

	if target.valid then		
		if menu["GRAVITY"].bool and menu["GRAVITYMIN"].int >= ObjectManager.EnemiesAroundObject(target, 5) and self.actions.gravity:canUse(target.id) then
			self.actions.gravity:use(target.id)
			log:print("Using Gravity II on " .. target.name)
		elseif menu["DOUBLE"].bool and self.actions.double:canUse(target.id) and self.last_spell_id == self.actions.gravity.id then
			self.actions.double:use(target.id)		
			log:print("Using Double Cast on " .. target.name)
		elseif menu["DOUBLE"].bool and self.actions.double:canUse(target.id) and self.last_spell_id == self.actions.malefic.id then
			self.actions.double:use(target.id)		
			log:print("Using Double Cast on " .. target.name)
		elseif menu["MALEFIC"].bool and self.actions.malefic:canUse(target.id) then
			self.actions.malefic:use(target.id)		
			log:print("Using Fall Malefic on " .. target.name)
		end
	end

end

return Astrologian:new()