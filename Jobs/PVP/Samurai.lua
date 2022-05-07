local Samurai = Class("Samurai")

function Samurai:initialize()

	self.actions = {

		--- Kasha Combo
			yukikaze    = Action(1, 29523),
			gekko       = Action(1, 29524),
			kasha       = Action(1, 29525),
			hyosetsu    = Action(1, 29526),
			mangetsu    = Action(1, 29527),
			oka         = Action(1, 29528),



			soten       = Action(1, 29532),
			chiten      = Action(1, 29533),

			mineuchi    = Action(1, 29535),
			ogi         = Action(1, 29530),
			mei         = Action(1, 29536),

			zantetsuken = Action(1, 29537)
	}

	self.menu = nil

end

function Samurai:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["MELEE_DPS"]:subMenu("Samurai", "SAM")
		self.menu["ACTIONS"]["MELEE_DPS"]["SAM"]:checkbox("Use Kasha Combo",         "KASHA", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["SAM"]:checkbox("Use Ogi Namiriki",        "OGI",  true)
		self.menu["ACTIONS"]["MELEE_DPS"]["SAM"]:checkbox("Use Soten",               "SOTEN", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["SAM"]:checkbox("Use Chiten",              "CHITEN", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["SAM"]:checkbox("Use Mineuchi",            "MINEUCHI", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["SAM"]:checkbox("Use Meikyo Shisui",       "MEI", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["SAM"]:checkbox("Only Use Shisui When CC", "MEI_CC", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["SAM"]:checkbox("Use Zantetsuken",         "ZANTET", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["SAM"]:checkbox("Zantetsuken Kuzushi only","ZANTETK", true)

end

function Samurai:Execute(actions, menu)
	local zantetsuken = actions.zantetsuken

	for i, object in ipairs(ObjectManager.GetEnemyPlayers()) do

		if (menu["ZANTETK"].bool and object:hasStatus(3202)) or not  menu["ZANTETK"].bool then

			local damage = 24000
			-- extra kuzushi damage
			if object:hasStatus(3202) then damage = damage + object.maxHealth end

			if object.health > 10000 and object.health < damage and zantetsuken:canUse(object.id) then
				zantetsuken:use(object.id)
				return true
			end
		end
	end
	return false
end

function Samurai:Tick(getTarget)

	local menu    = self.menu["ACTIONS"]["MELEE_DPS"]["SAM"]
	local actions = self.actions
	
	-- Chiten
	if menu["CHITEN"].bool and ObjectManager.EnemiesAroundObject(player, 8) > 0 and not player:hasStatus(1240) and actions.chiten:canUse() then
		actions.chiten:use()
	end

	if menu["ZANTET"].bool and self:Execute(actions, menu) then return end

	local farTarget = getTarget(20)

	if farTarget ~= nil and farTarget.valid and farTarget.pos:dist(player.pos) > 5.5 and not player:hasStatus(3201) then
		
		TargetManager.SetTarget(farTarget)
		
		if menu["SOTEN"].bool and actions.soten:canUse(farTarget.id) then
			actions.soten:use(farTarget.id)
			return
		end
	end

	local target = getTarget(5)

	if target == nil or not target.valid then return end

	if menu["MINEUCHI"].bool and actions.mineuchi:canUse(target.id) then
		actions.mineuchi:use(target.id)
	elseif menu["OGI"].bool and actions.ogi:canUse(target.id) then
		actions.ogi:use(target.id)
	elseif menu["SOTEN"].bool and actions.soten:canUse(target.id) and not player:hasStatus(3201) then
		actions.soten:use(target.id)
	elseif menu["KASHA"].bool and actions.oka:canUse(target.id) then
		actions.oka:use(target.id)
	elseif menu["KASHA"].bool and actions.mangetsu:canUse(target.id) then
		actions.mangetsu:use(target.id)
	elseif menu["KASHA"].bool and actions.hyosetsu:canUse(target.id) then
		actions.hyosetsu:use(target.id)
	elseif menu["KASHA"].bool and actions.kasha:canUse(target.id) then
		actions.kasha:use(target.id)
	elseif menu["KASHA"].bool and actions.gekko:canUse(target.id) then
		actions.gekko:use(target.id)
	elseif menu["KASHA"].bool and actions.yukikaze:canUse(target.id) then
		actions.yukikaze:use(target.id)
	end
end

return Samurai:new()