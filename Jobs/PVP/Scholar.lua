local Scholar = Class("Scholar")

function Scholar:initialize()

	self.actions = {

		broil     = Action(1, 29231),
		bio       = Action(1, 29233),
		mummy     = Action(1, 29235),

		adloq     = Action(1, 29232),
		tactics   = Action(1, 29234),
		expedient = Action(1, 29236),
		seraph    = Action(1, 29237)


	}

	self.menu = nil
	self.useTactics = false
	self.lastBioTarget = nil

	-- Tracks whenever we use bio to spread with tactics
	Callbacks:Add(CALLBACK_ACTION_REQUESTED, function(actionType, actionId, targetId, result)
		if actionType == 1 and result == 1 then
			self.useTactics = (actionId == 29233 and true) or false
		end
	end)
	
end

function Scholar:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["HEALER"]:subMenu("Scholar", "SCH")
		self.menu["ACTIONS"]["HEALER"]["SCH"]:checkbox("Use Broil IV",           "BROIL", true)
		self.menu["ACTIONS"]["HEALER"]["SCH"]:checkbox("Use Biolysis",           "BIO", true)
		self.menu["ACTIONS"]["HEALER"]["SCH"]:checkbox("Use Mummification",      "MUMMY", true)
		self.menu["ACTIONS"]["HEALER"]["SCH"]:checkbox("Use Adloquium",          "ADLOQ", true)
		self.menu["ACTIONS"]["HEALER"]["SCH"]:checkbox("Use Deployment Tactics", "TACTICS", true)
		self.menu["ACTIONS"]["HEALER"]["SCH"]:checkbox("Use Expedient ",         "EXPEDIENT", true)
		self.menu["ACTIONS"]["HEALER"]["SCH"]:checkbox("Use Summon Seraph",      "SERAPH", true)
		

end

function Scholar:AutoHeal()
	
	for i, ally in ipairs(ObjectManager.GetAllyPlayers(function (ally) return ally.missingHealth > 500 and ally.health > 0 end)) do
		if ally.pos:dist(player.pos) < 29 and self.actions.adloq:canUse(ally.id) then
			self.actions.adloq:use(ally.id)
			return true
		end
	end

	return false
end

function Scholar:Tick(getTarget)

	local menu    = self.menu["ACTIONS"]["HEALER"]["SCH"]

	if self:AutoHeal() then return end

	if menu["SERAPH"].bool and self.actions.seraph:canUse() then
		for i, ally in ipairs(ObjectManager.GetAllyPlayers()) do
			if ObjectManager.EnemiesAroundObject(ally, 10) > 2 then
				self.actions.seraph:use(ally.pos)
				return
			end
		end

	end

	if menu["TACTICS"].bool and self.useTactics and self.actions.tactics:canUse() then		
		if self.lastBioTarget ~= nil and ObjectManager.EnemiesAroundObject(self.lastBioTarget, 15) > 0 then
			self.actions.tactics:use(self.lastBioTarget.id)
			return
		end
	end

	local target = getTarget(25)

	if target.valid then
		if menu["MUMMY"].bool and target.pos:dist(player.pos) <= 7.5 and self.actions.mummy:canUse(target.id) then
			self.actions.mummy:use(target.id)
		elseif menu["EXPEDIENT"].bool and self.actions.expedient:canUse() then
			self.actions.expedient:use()
		elseif menu["BIO"].bool and self.actions.bio:canUse(target.id) then
			self.actions.bio:use(target.id)
			self.lastBioTarget = target
		elseif menu["BROIL"].bool and self.actions.broil:canUse(target.id) then
			self.actions.broil:use(target.id)
		end

	end

end

return Scholar:new()