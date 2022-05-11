local Astrologian = Class("Astrologian")

function Astrologian:initialize()

	self.actions = {

		malefic   = Action(1, 29242),
		benefic   = Action(1, 29243),
		mummy     = Action(1, 29235),

		adloq     = Action(1, 29232),
		tactics   = Action(1, 29234),
		expedient = Action(1, 29236),
		seraph    = Action(1, 29237)


	}

	self.menu = nil
	
	
end

function Astrologian:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["HEALER"]:subMenu("Astrologian", "AST")
		self.menu["ACTIONS"]["HEALER"]["AST"]:checkbox("Use Fall Malefic",     "MALEFIC", true)
		self.menu["ACTIONS"]["HEALER"]["AST"]:checkbox("Use Aspected Benefic", "BENEFIC", true)
		self.menu["ACTIONS"]["HEALER"]["AST"]:checkbox("Use Macrocosmos",      "COSMOS", true)
		self.menu["ACTIONS"]["HEALER"]["AST"]:checkbox("Min Enemies Cosmos",   "COSMOSMIN", 2)
		self.menu["ACTIONS"]["HEALER"]["AST"]:checkbox("Min Allies Cosmos",    "COSMOSMINA", 2)
		
end

function Astrologian:AutoHeal()
	
	for i, ally in ipairs(ObjectManager.GetAllyPlayers(function (ally)
			local healPotency = (ally.healthPercent < 50 and 8000) or 4000
	 		return ally.missingHealth > healPotency and ally.health > 0 
	 	end)) do
		if ally.pos:dist(player.pos) < 29 and self.actions.benefic:canUse(ally.id) then
			self.actions.benefic:use(ally.id)
			return true
		end
	end

	return false
end

function Astrologian:Tick(getTarget)

	local menu    = self.menu["ACTIONS"]["HEALER"]["AST"]

	if menu["BENEFIC"].bool and self:AutoHeal() then return end
	
	if menu["COSMOS"].bool and self.actions.cosmos:canUse() and 
		ObjectManager.EnemiesAroundObject(player, 20) >= menu["COMOSMIN"].int and ObjectManager.AlliesAroundObject(player, 20) >= menu["COMOSMINA"].int then
		self.actions.comos:use()
	end

	local target = getTarget(25)

	if target.valid then

		if menu["MALEFIC"].bool and self.actions.malefic:canUse(target.id) then
			self.actions.malefic:use(target.id)		
		end

	end

end

return Astrologian:new()