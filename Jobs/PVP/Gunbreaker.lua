local Gunbreaker = Class("Gunbreaker")

function Gunbreaker:initialize()

	self.actions = {

		-- Solid Barrell Combo
		keen       = Action(1, 29098),
		brutal     = Action(1, 29099),
		solid      = Action(1, 29100),
		burst      = Action(1, 29101),

		fang       = Action(1, 29102),
		double     = Action(1, 29105),
		continue   = Action(1, 29106),
		rough      = Action(1, 29123),
		draw       = Action(1, 29124),
		cast       = Action(1, 29125),

		relentless = Action(1, 29130)
	}

	self.menu = nil

end

function Gunbreaker:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["TANK"]:subMenu("Gunbreaker", "GNB")
		self.menu["ACTIONS"]["TANK"]["GNB"]:checkbox("Use Solid Barrell Combo",   "SOLID", true)
		self.menu["ACTIONS"]["TANK"]["GNB"]:checkbox("Use Continuation",          "CONTINUE", true)
		self.menu["ACTIONS"]["TANK"]["GNB"]:checkbox("Use Draw and Junction",     "DRAW", true)
		self.menu["ACTIONS"]["TANK"]["GNB"]:checkbox("Use Junctioned Cast",       "CAST", true)
		self.menu["ACTIONS"]["TANK"]["GNB"]:checkbox("Use Double Down",           "DOUBLE", true)
		self.menu["ACTIONS"]["TANK"]["GNB"]:checkbox("Use Rough Divine",          "ROUGH", true)
		self.menu["ACTIONS"]["TANK"]["GNB"]:number("Min Enemies for Double Down", "DOUBLE_MIN", 2)
		self.menu["ACTIONS"]["TANK"]["GNB"]:checkbox("Use Gnashing Fang",         "FANG", true)
		self.menu["ACTIONS"]["TANK"]["GNB"]:checkbox("Use Relentless Rush",       "RELENTLESS", true)
		self.menu["ACTIONS"]["TANK"]["GNB"]:number("Min Enemies for Relentless",  "RELENTLESS_MIN", 2)

end

function Gunbreaker:Rush(actions, menu, log)
	if player:hasStatus(3052) then
	 return true 
	elseif actions.relentless:canUse() and ObjectManager.EnemiesAroundObject(player, 5) >= menu["RELENTLESS_MIN"].int then
		actions.relentless:use()
		log:print("Using Relentless Rush")
		return true
	end

	return false
end


function Gunbreaker:Tick(getTarget, log)
	
	local menu    = self.menu["ACTIONS"]["TANK"]["GNB"]
	local actions = self.actions

	if self:Rush(actions, menu, log) then return end

	local farTarget = getTarget(20)

	if menu["ROUGH"].bool and farTarget.valid and farTarget.pos:dist(player.pos) > 6 and actions.rough:canUse(farTarget.id) then
		actions.rough:use(farTarget.id)
		log:print("Using Scattergun on " .. farTarget.name)
		return
	end

	local target = getTarget(5)

	if target.valid then

		if menu["DOUBLE"].bool and actions.double:canUse() and ObjectManager.EnemiesAroundObject(player, 5) >= menu["DOUBLE_MIN"].int then
			actions.double:use()
			log:print("Using Double Down")
		elseif menu["CONTINUE"].bool and actions.continue:canUse(target.id) then
			actions.continue:use(target.id)
			log:print("Using Continue on " .. target.name)
		elseif menu["SOLID"].bool and actions.burst:canUse(target.id) then
		    actions.burst:use(target.id)
		    log:print("Using Solid Barrell on " .. target.name)
		elseif menu["DRAW"].bool and actions.draw:canUse(target.id) then
		    actions.draw:use(target.id)
		    log:print("Using Draw and Junction on " .. target.name)
		elseif menu["CAST"].bool and actions.cast:canUse(target.id) then
		    actions.cast:use(target.id)
		    log:print("Using Junctioned Cast on " .. target.name)
		elseif menu["FANG"].bool and actions.fang:canUse(target.id) then
			actions.fang:use(target.id)
			log:print("Using Fang on " .. target.name)
		elseif menu["SOLID"].bool and actions.keen:canUse(target.id) then
			actions.keen:use(target.id)
			log:print("Using Keen on " .. target.name)
		elseif menu["SOLID"].bool and actions.brutal:canUse(target.id) then
			log:print("Using Brutal Shell on " .. target.name)
			actions.brutal:use(target.id)
		elseif menu["SOLID"].bool and actions.solid:canUse(target.id) then
			actions.solid:use(target.id)
			log:print("Using Solid Barrell on " .. target.name)
		end

	end
end

return Gunbreaker:new()