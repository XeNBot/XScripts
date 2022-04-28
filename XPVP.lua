local XPVP = Class("XPVP")

function XPVP:initialize()
	
	self.menu = Menu("XPVP")
		self.menu:label("XPVP Version 1.0") self.menu:separator() self.menu:space()
		self.menu:subMenu("Actions", "ACTIONS")
			
			self.menu["ACTIONS"]:subMenu("Common", "COMMON")
				self.menu["ACTIONS"]["COMMON"]:checkbox("Use Purify",     "PURIFY", true)
				self.menu["ACTIONS"]["COMMON"]:checkbox("Use Recuperate", "RECUPERATE", true)
				self.menu["ACTIONS"]["COMMON"]:checkbox("Use Guard",      "GUARD", true)

			self.menu["ACTIONS"]:space()

			self.menu["ACTIONS"]:subMenu("Dragoon", "DRG")
				self.menu["ACTIONS"]["DRG"]:checkbox("Use Wheeling Thrust Combo", "WHEELING", true)
				self.menu["ACTIONS"]["DRG"]:checkbox("Use Chaotic Spring",        "CHAOTIC", true)
				self.menu["ACTIONS"]["DRG"]:checkbox("Use Geirskogul",            "GEIRS", true)
				self.menu["ACTIONS"]["DRG"]:checkbox("Use High Jump",             "HIGHJUMP", true)
				self.menu["ACTIONS"]["DRG"]:checkbox("Use Elusive Jump",          "ELUSIVEJUMP", true)
				self.menu["ACTIONS"]["DRG"]:checkbox("Use Horrid Roar",           "ROAR", true)
				self.menu["ACTIONS"]["DRG"]:number("Min Enemies for Roar",        "ROARNUM", 3)
				self.menu["ACTIONS"]["DRG"]:checkbox("Use Sky High To Execute",   "SKYHIGH", true)
				self.menu["ACTIONS"]["DRG"]:number("Min Enemies To Execute",      "SKYHIGHNUM", 2)

			self.menu["ACTIONS"]:space()

			self.menu["ACTIONS"]:subMenu("Machinist", "MCH")
				self.menu["ACTIONS"]["MCH"]:checkbox("Use Blast Charge",      "BLAST", true)
				self.menu["ACTIONS"]["MCH"]:checkbox("Use Scattergun",        "SCATTER", true)
				self.menu["ACTIONS"]["MCH"]:checkbox("Use Chain Saw",         "CHAINSAW", true)
				self.menu["ACTIONS"]["MCH"]:checkbox("Use Wild Fire",         "WILDFIRE", true)
				self.menu["ACTIONS"]["MCH"]:checkbox("Use Marksman Spite",    "SPITE", true)
				

	self.menu:space() self.menu:space() self.menu:space()	
	
	self.menu:comboBox("Combo Mode", "COMBO_MODE", {"Always On", "On Hotkey"}, 0)

	self.menu:space() self.menu:space()

	self.menu:label("ComboKey is X")

	self.none = -536870912


	self.actions = {

		common = {

			guard      = Action(1, 29054),
			recuperate = Action(1, 29711),
			purify     = Action(1, 29056)
		},

		samurai = {

			--- Kasha Combo
			yukikaze  = Action(1, 29523),
			gekko     = Action(1, 29524),
			kasha     = Action(1, 29525),

			soten     = Action(1, 29532),

			ogi       = Action(1, 29530),
			mei       = Action(1, 29536)

		},

		dragoon = {

			-- Wheeling Trust
			raiden      = Action(1, 29486),
			fang        = Action(1, 29487),
			wheeling    = Action(1, 29488),

			chaotic     = Action(1, 29490),
			geirs       = Action(1, 29491),

			highjump    = Action(1, 29493),
			elusivejump = Action(1, 29494),
			roar        = Action(1, 29496),
			skyhigh     = Action(1, 29497)

		},

		machinist = {
			blast      = Action(1, 29402),
			scatter    = Action(1, 29404),
			chainsaw   = Action(1, 29405),
			wildfire   = Action(1, 29409),
			bishop     = Action(1, 29412),
			analysis   = Action(1, 29414),
			spite      = Action(1, 29415)
		}

	}

	self.purify_statusIds = {

		-- Stun 
		1343,
		-- Heavy
		1344,
		-- Bind
		1345,
		-- Sleep
		1348, 1363,
		-- Half-Sleep
		3022,
		-- Deep Freeze
		487, 1150, 1254, 1731, 1758, 2252, 2658, 3219
	}


	Callbacks:Add(CALLBACK_ACTION_REQUESTED, function(type, id, targetId, result)
		--print("Used Action: ", type, id, targetId)		
	end)

	Callbacks:Add(CALLBACK_PLAYER_TICK, function() self:Tick() end)

end

function XPVP:Tick()
	if player:hasStatus(3054) then return end

	self:CommonActions()

	if (self.menu["COMBO_MODE"].int == 0 and not Keyboard.IsKeyDown(88))  or Keyboard.IsKeyDown(88) then
		if player.classJob == 34 then
			self:SamuraiCombo()			
		elseif player.classJob == 22 then
			self:DragoonCombo()
		elseif player.classJob == 31 then
			self:MachinistCombo()
		end
	end
end

function XPVP:GetTarget(range)
	local target = nil

	for i, object in ipairs(ObjectManager.EnemyPlayers) do
		if object.health > 0 and object.pos:dist(player.pos) <= range then
			if target == nil or (target ~= nil and object.health < target.health) then
				target = object
			end
		end		
	end
	return target
end

function XPVP:CommonActions()
	local actions = self.actions.common
	local menu    = self.menu["ACTIONS"]["COMMON"]

	if menu["PURIFY"].bool and actions.purify:canUse(self.none) then
			self:Purify(actions)
	elseif menu["RECUPERATE"].bool and (player.maxHealth - player.health) > 15000 and actions.recuperate:canUse(self.none) then
		actions.recuperate:use(self.none)
	elseif menu["GUARD"].bool and player.health < 20000 and self:EnemiesAround(player, 10) > 1 and actions.guard:canUse(self.none) then
		print("guarding")
		actions.guard:use(self.none)
	end

end

function XPVP:Purify(actions)
	
	for i, statusId in ipairs(self.purify_statusIds) do
		if player:hasStatus(statusId) then
			actions.purify:use(self.none)
		end
	end

end

function XPVP:MachinistCombo()
	local menu = self.menu["ACTIONS"]["MCH"]

	if menu["SPITE"].bool and self:MachinistExecute() then return end

	local target = TargetManager.Target
	--local target = self:GetTarget(24)


	if target == nil or not target.valid then return end

	TargetManager.SetTarget(target)

	local actions        = self.actions.machinist
	local targetDistance = target.pos:dist(player.pos)

	if menu["SCATTER"].bool and targetDistance < 12 and actions.scatter:canUse(target.id) then
		actions.scatter:use(target.id)
	--[[elseif actions.bishop:canUse(self.none) then
		actions.bishop:use(target.pos)]]--
	elseif menu["WILDFIRE"].bool and actions.wildfire:canUse(target.id) then
		actions.wildfire:use(target.id)
	elseif menu["CHAINSAW"].bool and actions.chainsaw:canUse(target.id) then
		if not player:hasStatus(3158) and actions.analysis:canUse(self.none) then
			actions.analysis:use(self.none)
		else
			actions.chainsaw:use(target.id)
		end
	elseif menu["BLAST"].bool and actions.blast:canUse(target.id) then
		actions.blast:use(target.id)
	end
end

function XPVP:MachinistExecute()
	local spite = self.actions.machinist.spite
	for i, object in ipairs(ObjectManager.EnemyPlayers) do

		if object.health > 15000 and object.health < 35000 and spite:canUse(object.id) then
			spite:use(object.id)
			return true
		end
	end
	return false
end

function XPVP:DragoonCombo()
	local menu = self.menu["ACTIONS"]["DRG"]

	if menu["SKYHIGH"].bool and self:DragoonExecute() then return end

	--local target = TargetManager.Target
	local target    = self:GetTarget(6)
	local farTarget = self:GetTarget(15)

	if target == nil and farTarget == nil then return end

	local actions        = self.actions.dragoon

	if farTarget ~= nil and farTarget.pos:dist(player.pos) > 5.5 then
		if menu["ELUSIVEJUMP"].bool and actions.elusivejump:canUse(farTarget.id) then
			actions.elusivejump:use(farTarget.id)
		elseif menu["HIGHJUMP"].bool and actions.highjump:canUse(farTarget.id) then
		    actions.highjump:use(farTarget.id)
		end
	elseif target ~= nil then
		if menu["ROAR"].bool and self:EnemiesAround(player, 10) >= menu["ROARNUM"].int and actions.roar:canUse(self.none) then
			actions.roar:use(self.none)
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

function XPVP:DragoonExecute()	
	local skyhigh = self.actions.dragoon.skyhigh

	if not skyhigh:canUse(self.none) then return false end

	local executeCount = 0

	for i, object in ipairs(ObjectManager.EnemyPlayers) do

		if object.health > 5000 and object.health < 20000 and skyhigh:canUse(object.id) then
			executeCount = executeCount + 1
		end

	end
	
	if executeCount >= self.menu["ACTIONS"]["DRG"]["SKYHIGHNUM"].int then
		print("using skyhigh")
		skyhigh:use(self.none)
		return true
	end

	return false
end

function XPVP:SamuraiCombo()
	
	local actions        = self.actions.samurai
	local targetDistance = target.pos:dist(player.pos)
	
	if actions.soten:canUse(target.id) and targetDistance > 5 then
		actions.soten:use(target.id)
	elseif not player:hasStatus(3203) and actions.mei:canUse(self.none) and targetDistance < 3 then
		actions.mei:use(self.none)
	elseif player:hasStatus(3203) and actions.mei:canUse(target.id) and targetDistance < 3 then
		actions.mei:use(target.id)
	elseif actions.kasha:canUse(target.id) then
		actions.kasha:use(target.id)
	elseif actions.gekko:canUse(target.id) then
		actions.gekko:use(target.id)
	elseif actions.yukikaze:canUse(target.id) then
		actions.yukikaze:use(target.id)
	end

end

function XPVP:EnemiesAround(obj, dist)
	local count = 0

	for i, battle_obj in ipairs(ObjectManager.EnemyPlayers) do

		if battle_obj.pos:dist(obj.pos) < dist then
			count = count + 1
		end

	end

	return count
end

XPVP:new()