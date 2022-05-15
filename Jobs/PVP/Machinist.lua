local Machinist = Class("Machinist")

function Machinist:initialize()

	self.actions = {

		blast      = Action(1, 29402),
		scatter    = Action(1, 29404),
		chainsaw   = Action(1, 29405),
		wildfire   = Action(1, 29409),
		bishop     = Action(1, 29412),
		analysis   = Action(1, 29414),
		spite      = Action(1, 29415),
	}

	self.menu = nil

end

function Machinist:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["RANGE_DPS_P"]:subMenu("Machinist", "MCH")
		self.menu["ACTIONS"]["RANGE_DPS_P"]["MCH"]:checkbox("Use Blast Charge",      "BLAST", true)
		self.menu["ACTIONS"]["RANGE_DPS_P"]["MCH"]:checkbox("Use Scattergun",        "SCATTER", true)
		self.menu["ACTIONS"]["RANGE_DPS_P"]["MCH"]:checkbox("Use Chain Saw",         "CHAINSAW", true)
		self.menu["ACTIONS"]["RANGE_DPS_P"]["MCH"]:checkbox("Use Wild Fire",         "WILDFIRE", true)
		self.menu["ACTIONS"]["RANGE_DPS_P"]["MCH"]:checkbox("Use Bishop Autoturret", "BISHOP", true)
		self.menu["ACTIONS"]["RANGE_DPS_P"]["MCH"]:checkbox("Use Marksman Spite",    "SPITE", true)
end



function Machinist:Execute(log)
	local spite = self.actions.spite

	local list = AgentModule.currentMapId == 51 and ObjectManager.Battle() or ObjectManager.GetEnemyPlayers()

	for i, object in ipairs(list) do

		if object.health > 15000 and object.health < 35000 and not object:hasStatus(3054) and spite:canUse(object.id) then
			spite:use(object.id)
			log:print("Using Spite on " .. object.name)
			return true
		end
	end
	return false
end

function Machinist:Tick(getTarget, log)

	local menu        = self.menu["ACTIONS"]["RANGE_DPS_P"]["MCH"]
	local actions     = self.actions

	if menu["SPITE"].bool and self:Execute(log) then return end

	local target       = getTarget(24)
	local closerTarget = getTarget(12)


	if not target.valid then return end

	TargetManager.SetTarget(target)

	local targetDistance = target.pos:dist(player.pos)

	if menu["SCATTER"].bool and targetDistance < 12 and actions.scatter:canUse(target.id) then
		actions.scatter:use(target.id)
		log:print("Using Scattergun on " .. target.name)
	elseif menu["BISHOP"].bool and actions.bishop:canUse() and ObjectManager.EnemiesAroundObject(target, 5) > 0 then
		actions.bishop:use(target.pos)
		log:print("Using Bishop Autoturret")
	elseif menu["WILDFIRE"].bool and actions.wildfire:canUse(target.id) then
		actions.wildfire:use(target.id)
		log:print("Using Wildfire on " .. target.name)
	elseif menu["CHAINSAW"].bool and actions.chainsaw:canUse(target.id) then
		if not player:hasStatus(3158) and actions.analysis:canUse() then
			log:print("Using Analysis")
			actions.analysis:use()
		elseif player:hasStatus(3151) and closerTarget.valid then
			actions.chainsaw:use(closerTarget.id)
			log:print("Using Bioblast on " .. closerTarget.name)
		elseif not player:hasStatus(3151) then
			actions.chainsaw:use(target.id)
			log:print("Using Chainsaw on " .. target.name)
		end
	elseif menu["BLAST"].bool and actions.blast:canUse(target.id) then
		actions.blast:use(target.id)
		log:print("Using Blast on " .. target.name)
	end
end

return Machinist:new()