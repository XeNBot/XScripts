local Dragoon = Class("Dragoon")

function Dragoon:initialize()

	self.actions = {

		raiden      = Action(1, 29486),
		fang        = Action(1, 29487),
		wheeling    = Action(1, 29488),

		chaotic     = Action(1, 29490),
		geirs       = Action(1, 29491),

		highjump    = Action(1, 29493),
		elusivejump = Action(1, 29494),
		roar        = Action(1, 29496),
		skyhigh     = Action(1, 29497)
	}

	self.LBFilter = function (target) return self:ExecuteFilter(target) end

	self.menu = nil

end

function Dragoon:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["MELEE_DPS"]:subMenu("Dragoon", "DRG")
		self.menu["ACTIONS"]["MELEE_DPS"]["DRG"]:checkbox("Use Wheeling Thrust Combo", "WHEELING", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["DRG"]:checkbox("Use Chaotic Spring",        "CHAOTIC", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["DRG"]:checkbox("Use Geirskogul",            "GEIRS", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["DRG"]:checkbox("Use High Jump",             "HIGHJUMP", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["DRG"]:checkbox("Use Elusive Jump",          "ELUSIVEJUMP", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["DRG"]:checkbox("Use Horrid Roar",           "ROAR", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["DRG"]:number("Min Enemies for Roar",        "ROARNUM", 3)
		self.menu["ACTIONS"]["MELEE_DPS"]["DRG"]:checkbox("Use Sky High To Execute",   "SKYHIGH", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["DRG"]:number("Min Enemies To Execute",      "SKYHIGHNUM", 2)

end


function Dragoon:ExecuteFilter(target)
	if target.pos:dist(player.pos) <= 10 and target.health > 5000 and target.health < 20000  then
		return true
	end
	return false
end

function Dragoon:Execute(actions, menu)
	if actions.skyhigh:canUse() or player:hasStatus(1342) then

		local executeCount = 0

		for i, object in ipairs(ObjectManager.GetEnemyPlayers(self.LBFilter)) do
			executeCount = executeCount + 1
		end
		
		if executeCount >= menu["SKYHIGHNUM"].int then
			actions.skyhigh:use()
			return true
		end
	end

	return false
end

function Dragoon:Tick(getTarget)

	local menu    = self.menu["ACTIONS"]["MELEE_DPS"]["DRG"]
	local actions = self.actions

	if menu["SKYHIGH"].bool and self:Execute(actions, menu) then return end

	local target    = getTarget(6)
	local farTarget = getTarget(15)

	if target == nil and farTarget == nil  then return end
	
	if farTarget ~= nil and farTarget.valid and farTarget.pos:dist(player.pos) > 5.5 then
		
		TargetManager.SetTarget(farTarget)
		
		if menu["GEIRS"].bool and actions.geirs:canUse(target.id) then
			actions.geirs:use(target.id)		
		elseif menu["ELUSIVEJUMP"].bool and actions.elusivejump:canUse(farTarget.id) then
			actions.elusivejump:use(farTarget.id)
		elseif menu["HIGHJUMP"].bool and actions.highjump:canUse(farTarget.id) then
		    actions.highjump:use(farTarget.id)
		end

	elseif target ~= nil and target.valid then
		
		TargetManager.SetTarget(target)

		if menu["ROAR"].bool and ObjectManager.EnemiesAroundObject(player, 10) >= menu["ROARNUM"].int and actions.roar:canUse() then
			actions.roar:use()
		elseif menu["GEIRS"].bool and actions.geirs:canUse(target.id) then
			actions.geirs:use(target.id)
		elseif menu["CHAOTIC"].bool and actions.chaotic:canUse(target.id) and (player.maxHealth - player.health) > 8000 then
			actions.chaotic:use(target.id)
		elseif menu["WHEELING"].bool and actions.wheeling:canUse(target.id) then
			actions.wheeling:use(target.id)
		elseif actions.fang:canUse(target.id) then
			actions.fang:use(target.id)
		elseif actions.raiden:canUse(target.id) then
			actions.raiden:use(target.id)
		end
	end
end

return Dragoon:new()