local XPVP = Class("XPVP")

function XPVP:initMenu()
	
	self.menu = Menu("XPVP")
		self.menu:label("XPVP Version 1.0") self.menu:separator() self.menu:space()
		
		self.menu:subMenu("Target Settings", "TARGET")
			self.menu["TARGET"]:checkbox("Get Target Auto", "AUTO", true)
			self.menu["TARGET"]:checkbox("Don't Attack Guard", "GUARD_CHECK", true)
			self.menu["TARGET"]:combobox("Mode", "MODE", {"Lowest Health", "Closest"})
		
		self.menu:subMenu("Action Settings", "ACTIONS")

			self.menu["ACTIONS"]:subMenu("Common", "COMMON")
				self.menu["ACTIONS"]["COMMON"]:checkbox("Use Purify",     "PURIFY", true)
				self.menu["ACTIONS"]["COMMON"]:checkbox("Use Recuperate", "RECUPERATE", true)
				self.menu["ACTIONS"]["COMMON"]:checkbox("Use Guard",      "GUARD", true)
				self.menu["ACTIONS"]["COMMON"]:checkbox("Use Sprint",     "SPRINT", true)


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


			self.menu["ACTIONS"]:subMenu("Machinist", "MCH")
				self.menu["ACTIONS"]["MCH"]:checkbox("Use Blast Charge",      "BLAST", true)
				self.menu["ACTIONS"]["MCH"]:checkbox("Use Scattergun",        "SCATTER", true)
				self.menu["ACTIONS"]["MCH"]:checkbox("Use Chain Saw",         "CHAINSAW", true)
				self.menu["ACTIONS"]["MCH"]:checkbox("Use Wild Fire",         "WILDFIRE", true)
				self.menu["ACTIONS"]["MCH"]:checkbox("Use Marksman Spite",    "SPITE", true)

			self.menu["ACTIONS"]:subMenu("Samurai", "SAM")
				self.menu["ACTIONS"]["SAM"]:checkbox("Use Kasha Combo",         "KASHA", true)
				self.menu["ACTIONS"]["SAM"]:checkbox("Use Ogi Namiriki",        "OGI",  true)
				self.menu["ACTIONS"]["SAM"]:checkbox("Use Soten",               "SOTEN", true)
				self.menu["ACTIONS"]["SAM"]:checkbox("Use Chiten",              "CHITEN", true)
				self.menu["ACTIONS"]["SAM"]:checkbox("Use Mineuchi",            "MINEUCHI", true)
				self.menu["ACTIONS"]["SAM"]:checkbox("Use Meikyo Shisui",       "MEI", true)
				self.menu["ACTIONS"]["SAM"]:checkbox("Only Use Shisui When CC", "MEI_CC", true)
				self.menu["ACTIONS"]["SAM"]:checkbox("Use Zantetsuken",         "ZANTET", true)

			self.menu["ACTIONS"]:subMenu("Reaper", "RPR")
				self.menu["ACTIONS"]["RPR"]:checkbox("Use Infernal Slice Combo", "INFERNAL", true)
				self.menu["ACTIONS"]["RPR"]:checkbox("Use Soul Slice",           "SOUL",  true)
				self.menu["ACTIONS"]["RPR"]:checkbox("Use Plentyful Harvest",    "HARVEST", true)
				self.menu["ACTIONS"]["RPR"]:number("Min Soul Sacrifice Stacks",  "HARVEST_MIN", 6)
				self.menu["ACTIONS"]["RPR"]:checkbox("Use Grim Swathe",          "GRIM", true)
				self.menu["ACTIONS"]["RPR"]:checkbox("Use Death Warrant",        "DEATH", true)
				self.menu["ACTIONS"]["RPR"]:checkbox("Hell's Ingress",           "HELL", true)
				self.menu["ACTIONS"]["RPR"]:checkbox("Arcane Crest",             "ARCANE", true)
				self.menu["ACTIONS"]["RPR"]:checkbox("Use Tenebrae Lemurum",     "TENEBRAE", true)

		
		self.menu:subMenu("Extra Settings", "EXTRA")
			self.menu["EXTRA"]:checkbox("Practice Combo Dummies", "PRACTICE", true)

	self.menu:space() self.menu:space() self.menu:space()	
	
	self.menu:combobox("Combo Mode", "COMBO_MODE", {"Always On", "On Hotkey"}, 0)

	self.menu:space() self.menu:space()

	self.menu:hotkey("ComboKey", "COMBO_KEY", 88)

end

function XPVP:initialize()
	
	self:initMenu()	

	self.none = -536870912


	self.actions = {

		common = {

			guard      = Action(1, 29054),
			recuperate = Action(1, 29711),
			purify     = Action(1, 29056),
			sprint     = Action(1, 29057)
		},

		samurai = {

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
			spite      = Action(1, 29415),
		},

		reaper = {
			
			-- Infernal Slice Combo
			slice    = Action(1, 29538),
			waxing   = Action(1, 29539),
			infernal = Action(1, 29540),
			gibbet   = Action(1, 29541),
			gallows  = Action(1, 29542),
			void     = Action(1, 29543),
			cross    = Action(1, 29544),

			soul     = Action(1, 29566),
			harvest  = Action(1, 29546),
			grim     = Action(1, 29547),
			death    = Action(1, 29549),
			hell     = Action(1, 29550),
			arcane   = Action(1, 29552),
			tenebrae = Action(1, 29553),





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

	self.targetFilter    = function (target) return self:TargetFilter(target) end
	self.dragoonEXFilter = function (target) return self:DragoonExecuteFilter(target) end

	Callbacks:Add(CALLBACK_PLAYER_TICK, function() self:Tick() end)

	print("Loaded XPVP!")

end

function XPVP:Tick()
	-- PVP Maps
	if AgentModule.currentMapId ~= 759 and AgentModule.currentMapId ~= 51 and AgentModule.currentMapId ~= 760 and AgentModule.currentMapId ~= 761 then return end
	-- Guard
	if player:hasStatus(3054) then return end

	if self:CommonActions() then return end

	if (self.menu["COMBO_MODE"].int == 0 and not self.menu["COMBO_KEY"].keyDown)  or self.menu["COMBO_KEY"].keyDown then
		if player.classJob == 34 then
			self:SamuraiCombo()			
		elseif player.classJob == 22 then
			self:DragoonCombo()
		elseif player.classJob == 31 then
			self:MachinistCombo()
		elseif player.classJob == 39 then
			self:ReaperCombo()
		end
	end
end

function XPVP:TargetFilter(target)
	if self.menu["TARGET"]["GUARD_CHECK"].bool then
		return not target:hasStatus(3054)
	end
	return true
end

function XPVP:GetTarget(range)
	if AgentModule.currentMapId == 51 then
		return TargetManager.Target
	end

	local target = nil

	if self.menu["TARGET"]["MODE"].int == 0 then
		return ObjectManager.GetLowestHealthEnemy(range, self.targetFilter)
	else
		return ObjectManager.GetClosestEnemy(self.targetFilter)

	end

	return target
end

function XPVP:CommonActions()
	local actions = self.actions.common
	local menu    = self.menu["ACTIONS"]["COMMON"]

	if menu["SPRINT"].bool and self:EnemiesAround(player, 30) == 0 and not player:hasStatus(1342) and actions.sprint:canUse(self.none) then
		actions.sprint:use(self.none)
		return true
	elseif menu["PURIFY"].bool and self:ShouldPurify() and actions.purify:canUse(self.none) then
		actions.purify:use(self.none)
		return true
	elseif player.classJob == 39 and self.menu["ACTIONS"]["RPR"]["ARCANE"].bool and (player.maxHealth - player.health) > 18000 and 
		self.actions.reaper.arcane:canUse(self.none) then
		self.actions.reaper.arcane:use(self.none)
		return true
	elseif menu["RECUPERATE"].bool and (player.maxHealth - player.health) > 15000 and actions.recuperate:canUse(self.none) then
		actions.recuperate:use(self.none)
		return true
	elseif menu["GUARD"].bool and player.health < 20000 and self:EnemiesAround(player, 10) > 1 and actions.guard:canUse(self.none) then
		actions.guard:use(self.none)
		return true
	end

	return false

end

function XPVP:ShouldPurify()
	for i, statusId in ipairs(self.purify_statusIds) do
		if player:hasStatus(statusId) then
			if player.classJob == 34 and self.menu["ACTIONS"]["SAM"]["MEI"].bool and self.actions.samurai.mei:canUse(self.none) then
				self.actions.samurai.mei:use(self.none)
				return false
			end
			return true
		end
	end

end

function XPVP:ReaperEnshrouded(target, status, actions)
	-- Communio
	if (status.remainingTime <= 1.5 or status.count == 1) and actions.tenebrae:canUse(target.id) then
		actions.tenebrae:use(target.id)
	-- Lemure's Slice
	elseif actions.grim:canUse(target.id) then
		actions.grim:use(target.id)
	-- Void Reaping
	elseif actions.void:canUse(target.id) then
		actions.void:use(target.id)
	-- Cross Reaping
	elseif actions.cross:canUse(target.id) then
		actions.cross:use(target.id)
	elseif actions.death:canUse(target.id) then
		actions.death:use(target.id)
	end
end

function XPVP:ReaperCombo()
	local menu    = self.menu["ACTIONS"]["RPR"]
	local actions = self.actions.reaper

	local farTarget = self:GetTarget(14)

	if farTarget ~= nil and farTarget.valid and farTarget.pos:dist(player.pos) > 9 and menu["HELL"].bool and actions.hell:canUse(farTarget.id) and not player:hasStatus(2860) then
		player:rotateTo(farTarget.pos)
		actions.hell:use(farTarget.id)
		return
	end

	local target = self:GetTarget(5)

	if target ~= nil and target.valid then

		local enshrouded     = player:getStatus(2863)
		local soul_sacrifice = player:getStatus(3204)

		if enshrouded.valid then 
			self:ReaperEnshrouded(target, enshrouded, actions)
		elseif menu["TENEBRAE"].bool and actions.tenebrae:canUse(self.none) then
			actions.tenebrae:use(self.none)
		elseif menu["DEATH"].bool and actions.death:canUse(target.id) then
			actions.death:use(target.id)
		elseif menu["HARVEST"].bool and actions.harvest:canUse(target.id) and soul_sacrifice.valid and soul_sacrifice.count >= menu["HARVEST_MIN"].int then
			actions.harvest:use(target.id)
		elseif menu["SOUL"].bool and actions.soul:canUse(target.id) and (not soul_sacrifice.valid or (soul_sacrifice.count < 8)) then
			actions.soul:use(target.id)
		elseif menu["GRIM"].bool and actions.grim:canUse(target.id) then
			actions.grim:use(target.id)
		elseif menu["INFERNAL"].bool and actions.gibbet:canUse(target.id) then
			actions.gibbet:use(target.id)
		elseif menu["INFERNAL"].bool and actions.gallows:canUse(target.id) then
			actions.gallows:use(target.id)
		elseif menu["INFERNAL"].bool and actions.infernal:canUse(target.id) then
			actions.infernal:use(target.id)
		elseif menu["INFERNAL"].bool and actions.waxing:canUse(target.id) then
			actions.waxing:use(target.id)
		elseif menu["INFERNAL"].bool and actions.slice:canUse(target.id) then
			actions.slice:use(target.id)
		end
	end

end

function XPVP:MachinistCombo()
	local menu = self.menu["ACTIONS"]["MCH"]

	if menu["SPITE"].bool and self:MachinistExecute() then return end

	local target = self:GetTarget(24)


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
	for i, object in ipairs(ObjectManager.GetEnemyPlayers()) do

		if object.health > 15000 and object.health < 35000 and spite:canUse(object.id) then
			spite:use(object.id)
			return true
		end
	end
	return false
end

function XPVP:DragoonCombo()
	local menu    = self.menu["ACTIONS"]["DRG"]
	local actions = self.actions.dragoon

	if menu["SKYHIGH"].bool and self:DragoonExecute(actions) then return end

	local target    = self:GetTarget(6)
	local farTarget = self:GetTarget(15)

	if target == nil and farTarget == nil  then return end
	
	if farTarget ~= nil and farTarget.valid and farTarget.pos:dist(player.pos) > 5.5 then
		
		TargetManager.SetTarget(farTarget)
		
		if menu["ELUSIVEJUMP"].bool and actions.elusivejump:canUse(farTarget.id) then
			actions.elusivejump:use(farTarget.id)
		elseif menu["HIGHJUMP"].bool and actions.highjump:canUse(farTarget.id) then
		    actions.highjump:use(farTarget.id)
		end

	elseif target ~= nil and target.valid then
		
		TargetManager.SetTarget(target)

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

function XPVP:DragoonExecuteFilter(target)
	if target.pos:dist(player.pos) <= 10 and target.health > 5000 and target.health < 20000  then
		return true
	end
	return false
end

function XPVP:DragoonExecute(actions)

	if actions.skyhigh:canUse(self.none) or player:hasStatus(1342) then

		local executeCount = 0

		for i, object in ipairs(ObjectManager.GetEnemyPlayers(self.dragoonEXFilter)) do
			executeCount = executeCount + 1
		end
		
		if executeCount >= self.menu["ACTIONS"]["DRG"]["SKYHIGHNUM"].int then
			actions.skyhigh:use(self.none)
			return true
		end
	end

	return false
end

function XPVP:SamuraiExecute()
	local zantetsuken = self.actions.samurai.zantetsuken

	for i, object in ipairs(ObjectManager.GetEnemyPlayers()) do
		local damage = 24000
		-- extra kuzushi damage
		if object:hasStatus(3202) then damage = damage + object.maxHealth end

		if object.health > 10000 and object.health < damage and zantetsuken:canUse(object.id) then
			zantetsuken:use(object.id)
			return true
		end
	end
	return false
end

function XPVP:SamuraiCombo()
	
	local menu    = self.menu["ACTIONS"]["SAM"]
	local actions = self.actions.samurai
	
	-- Chiten
	if menu["CHITEN"].bool and self:EnemiesAround(player, 8) > 0 and not player:hasStatus(1240) and actions.chiten:canUse(self.none) then
		actions.chiten:use(self.none)
	end

	if menu["ZANTET"].bool and self:SamuraiExecute() then return end

	local farTarget = self:GetTarget(20)

	if farTarget ~= nil and farTarget.valid and farTarget.pos:dist(player.pos) > 5.5 and not player:hasStatus(3201) then
		
		TargetManager.SetTarget(farTarget)
		
		if menu["SOTEN"].bool and actions.soten:canUse(farTarget.id) then
			actions.soten:use(farTarget.id)
			return
		end
	end

	local target = self:GetTarget(5)

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

function XPVP:EnemiesAround(obj, dist)
	local count = 0

	for i, battle_obj in ipairs(ObjectManager.GetEnemyPlayers()) do

		if battle_obj.pos:dist(obj.pos) < dist then
			count = count + 1
		end

	end

	return count
end

XPVP:new()