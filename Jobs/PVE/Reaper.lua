local Reaper = Class("Reaper")

function Reaper:initialize()

	self.actions = {

		slice         = Action(1, 24373),
		waxingslice   = Action(1, 24374),
		infernalslice = Action(1, 24375),
		spinscythe    = Action(1, 24376),
		nightscythe   = Action(1, 24377),
		shadowofdeath = Action(1, 24378),
		whorlofdeath  = Action(1, 24379),
		soulslice     = Action(1, 24380),
		soulsythe     = Action(1, 24381),
		gibbet        = Action(1, 24382),
		gallows       = Action(1, 24383),
		plentiful     = Action(1, 24385),
		harpe         = Action(1, 24386),
		soulsow       = Action(1, 24387),
		unveiled      = Action(1, 24389),
		gluttony      = Action(1, 24393),
		enshroud      = Action(1, 24394),
		voidreaping   = Action(1, 24395),
		crossreaping  = Action(1, 24396),
        grimreaping   = Action(1, 24397),
        communio      = Action(1, 24398),
		lemuresslice  = Action(1, 24399),
		lemuresscythe = Action(1, 24400),

		arcanecircle  = Action(1, 24405),

	}

	self.menu = nil
	self.lastAction = 0

end

function Reaper:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["MELEE_DPS"]:subMenu("Reaper", "RPR")
		self.menu["ACTIONS"]["MELEE_DPS"]["RPR"]:checkbox("Use Harpe", "HARPE", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["RPR"]:checkbox("Use AoE Rotations", "AOE", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["RPR"]:slider("Min Enemies for AoE", "AOE_MIN", 1, 1, 3, 2)
	
	Callbacks:Add(CALLBACK_ACTION_REQUESTED, function(actionType, actionId, targetId, result)

		if result == 1 and actionType == 1 then			
			self.lastAction = actionId
		end

	end)

end

function Reaper:Tick(log)

	local target = TargetManager.Target
	local menu   = self.menu["ACTIONS"]["MELEE_DPS"]["RPR"]

	if not target.valid or target.kind ~= 2 or target.subKind ~= 5 then return end

	if self.menu["PREPULL_KEY"].keyDown then
		return self:Prepull(log, target)
	end

	local aoe = menu["AOE"].bool and ObjectManager.BattleEnemiesAroundObject(target, 5) >= (menu["AOE_MIN"].int - 1)

	if self:Weave(log, target) then return end

	if not player:hasStatus(2594) and self.actions.soulsow:canUse() then
		log:print("Using Soulsow")
		self.actions.soulsow:use()
	elseif not aoe and self.actions.shadowofdeath:canUse(target) and not target:hasStatus(2586) then
		log:print("Using Shadow of Death on " .. target.name)
		self.actions.shadowofdeath:use(target)
	elseif aoe and self.actions.whorlofdeath:canUse(target) and not target:hasStatus(2586) then
		log:print("Using Whorl of Death on " .. target.name)
		self.actions.whorlofdeath:use(target)
	elseif not aoe and self.actions.soulslice:canUse(target) then
		log:print("Using Soul Slice on " .. target.name)
		self.actions.soulslice:use(target)
	elseif aoe and self.actions.soulsythe:canUse() then
		log:print("Using Soul Sythe on " .. target.name)
		self.actions.soulsythe:use()
	elseif self.actions.plentiful:canUse(target) then
		log:print("Using Plentiful Harvest on " .. target.name)
		self.actions.plentiful:use(target)
	elseif not aoe and self.actions.voidreaping:canUse(target) then
		log:print("Using Void Reaping on " .. target.name)
		self.actions.voidreaping:use(target)
	elseif aoe and self.actions.grimreaping:canUse() then
		log:print("Using Grim Reaping on")
		self.actions.grimreaping:use(target)
	elseif self.actions.communio:canUse(target) then
		log:print("Using Communio on " .. target.name)
		self.actions.communio:use(target)
	elseif self.lastAction ~= self.actions.gibbet.id and self.actions.gibbet:canUse(target) then
		log:print("Using Gibbet on " .. target.name)
		self.actions.gibbet:use(target)
	elseif self.actions.gallows:canUse(target) then
		log:print("Using Gallows on " .. target.name)
		self.actions.gallows:use(target)
	elseif self.actions.unveiled:canUse(target) then
		log:print("Using Blood Stalk on " .. target.name)
		self.actions.unveiled:use(target)
	elseif not aoe and self.actions.slice:canUse(target) then
		log:print("Using Slice on " .. target.name)
		self.actions.slice:use(target)
	elseif aoe and self.actions.spinscythe:canUse() then
		log:print("Using Spinning Scythe")
		self.actions.spinscythe:use()
	end

end

function Reaper:Prepull(log, target)
	
	if self.actions.harpe:canUse(target) then
		log:print("Using Harpe on " .. target.name)
		self.actions.harpe:use(target)
	end

end


function Reaper:Weave(log, target)
	if self.lastAction == self.actions.slice.id and self.actions.waxingslice:canUse(target) then
		log:print("Using Waxing Slice on " .. target.name)
		self.actions.waxingslice:use(target)
		return true
	elseif self.lastAction == self.actions.waxingslice.id and self.actions.infernalslice:canUse(target) then
		log:print("Using Infernal Slice on " .. target.name)
		self.actions.infernalslice:use(target)
		return true
	elseif self.lastAction == self.actions.spinscythe.id and self.actions.nightscythe:canUse() then
		log:print("Using Nightmare Scythe")
		self.actions.nightscythe:use()
		return true
	elseif (self.lastAction == self.actions.shadowofdeath.id or self.lastAction == self.actions.whorlofdeath.id) 
	 and self.actions.arcanecircle:canUse() then
		log:print("Using Arcane Circle")
		self.actions.arcanecircle:use()
		return true
	elseif self.lastAction == self.actions.plentiful.id and self.actions.enshroud:canUse() then
		log:print("Using Enshroud")
		self.actions.enshroud:use()
		return true
	elseif (self.lastAction == self.actions.voidreaping.id or self.lastAction == self.actions.grimreaping.id)
	 and self.actions.crossreaping:canUse(target) then
		log:print("Using Cross Reaping on " .. target.name)
		self.actions.crossreaping:use(target)
		return true
	elseif self.lastAction == self.actions.crossreaping.id and self.actions.lemuresslice:canUse(target) then
		log:print("Using Lemure's Slice on " .. target.name)
		self.actions.lemuresslice:use(target)
	elseif self.lastAction == self.actions.communio.id and self.actions.gluttony:canUse() then
		log:print("Using Gluttony")
		self.actions.gluttony:use()
	elseif self.lastAction == self.actions.gallows.id and self.actions.unveiled:canUse(target) then
		log:print("Using Unveiled Gibbet on " .. target.name)
		self.actions.unveiled:use(target)
	end

	return false
end


return Reaper:new()