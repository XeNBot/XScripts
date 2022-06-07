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
	self.seq  = nil

end

function Machinist:Load(mainMenu, seq)
	
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

	if #list == 0 then return false end

	for i, object in ipairs(list) do
		if object.valid and object.health > 15000 and object.health < 35000 and not object:hasStatus(3054) and spite:canUse(object) then
			log:print("Using Spite on " .. object.name)
			spite:use(object)
			return true
		end
	end
	return false
end

function Machinist:Tick(log)

	local menu        = self.menu["ACTIONS"]["RANGE_DPS_P"]["MCH"]
	local actions     = self.actions

	if menu["SPITE"].bool and self:Execute(log) then return end

	if menu["SCATTER"].bool and actions.scatter.ready then
		log:print("Using Scattergun on " .. actions.scatter.target.name)
		actions.scatter:use()
	elseif menu["BISHOP"].bool and actions.bishop.ready and ObjectManager.EnemiesAroundObject(actions.bishop.target, 5) > 0 then
		log:print("Using Bishop Autoturret on " .. actions.bishop.target.name)
		actions.bishop:use(actions.bishop.target.pos)
	elseif menu["WILDFIRE"].bool and actions.wildfire.ready then
		log:print("Using Wildfire on " .. actions.wildfire.target.name)
		actions.wildfire:use()
	elseif menu["CHAINSAW"].bool and actions.chainsaw.ready then
		if not player:hasStatus(3158) and actions.analysis:canUse() then
			log:print("Using Analysis")
			actions.analysis:use()
		elseif player:hasStatus(3151) then
			log:print("Using Bioblast on " .. actions.chainsaw.target.name)
			actions.chainsaw:use()
		else
			log:print("Using Chainsaw on " .. actions.chainsaw.target.name)
			actions.chainsaw:use()
		end
	elseif menu["BLAST"].bool and actions.blast.ready then
		log:print("Using Blast on " .. actions.blast.target.name)
		actions.blast:use()
	end
end

return Machinist:new()