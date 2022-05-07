local Monk = Class("Monk")

function Monk:initialize()

	self.actions = {

		-- Phantom Rush Combo
		bootshine   = Action(1, 29472),
		truestrike  = Action(1, 29473),
		snappunch   = Action(1, 29474),
		dragonkick  = Action(1, 29475),
		twinsnakes  = Action(1, 29476),
		demolish    = Action(1, 29477),
		phantomrush = Action(1, 29478),

		sidedstar   = Action(1, 29479),
		enlight     = Action(1, 29480),
		phoenix     = Action(1, 29481),
		riddle      = Action(1, 29482),
		thunderclap = Action(1, 29484),
		meteodrive  = Action(1, 29485),
	}

	self.menu = nil
	
end

function Monk:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["MELEE_DPS"]:subMenu("Monk", "MNK")
		self.menu["ACTIONS"]["MELEE_DPS"]["MNK"]:checkbox("Use Phanton Rush Combo",    "RUSH", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["MNK"]:checkbox("Use Six-sided Star ",       "STAR", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["MNK"]:checkbox("Use Enlightment",           "ENLIGHTMENT", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["MNK"]:checkbox("Use Rising Phoenix",        "PHOENIX", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["MNK"]:number("Min Enemies For Phoenix",     "PHOENIXNUM", 2)
		self.menu["ACTIONS"]["MELEE_DPS"]["MNK"]:checkbox("Use Riddle of Earth",       "RIDDLE", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["MNK"]:checkbox("Use Thunderclap",           "THUNDER", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["MNK"]:checkbox("Use Meteodrive",            "METEO", true)

end

function Monk:Execute(actions)
	for i, object in ipairs(ObjectManager.GetEnemyPlayers()) do
		local damage = 12000
		-- Extra Damage if enemy doesn't have guard
		if not object:hasStatus(3054) then
			damage = damage + 12000
		end
		-- Extra Damage from pressure point
		if object:hasStatus(3172) then
			damage = damage + 12000
		end
		if object.pos:dist(player.pos) < 20 and object.health > 1000 and object.health < damage and actions.meteodrive:canUse(object.id) then
			actions.meteodrive:use(object.id)
			return true
		end
	end
	return false
end

function Monk:Tick(getTarget)

	local menu    = self.menu["ACTIONS"]["MELEE_DPS"]["MNK"]
	local actions = self.actions

	if menu["METEO"].bool and self:Execute(actions) then return end

	local farTarget = getTarget(20)

	if farTarget.valid and farTarget.pos:dist(player.pos) > 6 and menu["THUNDER"].bool and actions.thunderclap:canUse(farTarget.id) then
		actions.thunderclap:use(farTarget.id)
		return
	end

	local target = getTarget(5)

	if target.valid then
		local riddle = player:getStatus(3171)

		if menu["ENLIGHTMENT"].bool and actions.enlight:canUse(target.id) then
			actions.enlight:use(target.id)
		elseif menu["PHOENIX"].bool and ObjectManager.EnemiesAroundObject(player, 5) >= menu["PHOENIXNUM"].int and actions.phoenix:canUse() then
			actions.phoenix:use()
		elseif menu["RIDDLE"].bool and not riddle.valid and actions.riddle:canUse() then
			actions.riddle:use()
		elseif menu["RIDDLE"].bool and riddle.valid and riddle.remainingTime <= 1.2 then
			actions.riddle:use()
		elseif menu["STAR"].bool and actions.sidedstar:canUse(target.id) then
			actions.sidedstar:use(target.id)
		elseif menu["RUSH"].bool and actions.phantomrush:canUse(target.id) then
			actions.phantomrush:use(target.id)
		elseif menu["RUSH"].bool and actions.demolish:canUse(target.id) then
			actions.demolish:use(target.id)
		elseif menu["RUSH"].bool and actions.twinsnakes:canUse(target.id) then
			actions.twinsnakes:use(target.id)
		elseif menu["RUSH"].bool and actions.dragonkick:canUse(target.id) then
			actions.dragonkick:use(target.id)
		elseif menu["RUSH"].bool and actions.snappunch:canUse(target.id) then
			actions.snappunch:use(target.id)
		elseif menu["RUSH"].bool and actions.truestrike:canUse(target.id) then
			actions.truestrike:use(target.id)
		elseif menu["RUSH"].bool and actions.bootshine:canUse(target.id) then
			actions.bootshine:use(target.id)
		end

	end
end

return Monk:new()