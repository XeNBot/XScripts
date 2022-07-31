local Samurai = Class("Samurai")

function Samurai:initialize()

	self.actions = {
		hakaze     = Action(1, 7477),
		yukikaze   = Action(1, 7480),
		gekko      = Action(1, 7481),
		kasha      = Action(1, 7482),
		setsugekka = Action(1, 7487),
		meikyo     = Action(1, 7499),

		midare     = Action(1, 7867),

		senei      = Action(1, 16481),
		ikishoten  = Action(1, 16482),
		tsubame    = Action(1, 16483),

	}

	self.menu = nil
	self.lastAction = 0

end

function Samurai:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["MELEE_DPS"]:subMenu("Samurai", "SAM")
		--self.menu["ACTIONS"]["MELEE_DPS"]["SAM"]:checkbox("Use AoE Rotations", "AOE", true)
		--self.menu["ACTIONS"]["MELEE_DPS"]["SAM"]:slider("Min Enemies for AoE", "AOE_MIN", 1, 1, 3, 2)
	
	Callbacks:Add(CALLBACK_ACTION_REQUESTED, function(actionType, actionId, targetId, result)

		if result == 1 and actionType == 1 then			
			self.lastAction = actionId
		end

	end)

end

function Samurai:Tick(log)

	local target = TargetManager.Target
	local menu   = self.menu["ACTIONS"]["MELEE_DPS"]["SAM"]

	if not target.valid or target.kind ~= 2 or target.subKind ~= 5 or target.pos:dist(player.pos) > 3 then return end

	local mei = player:getStatus(1233)

	if self:Weave(log, target, mei) then return end

	if mei.valid then return self:Meikyo(log, target, mei) end
	
	if self.actions.meikyo:canUse() then
		log:print("Using Meikyo Shisui")
		self.actions.meikyo:use()
	elseif self.actions.midare:canUse(target) then
		log:print("Using Midare Setsugekka on " .. target.name)
		self.actions.midare:use(target)
	elseif self.actions.tsubame:canUse(target) then
		log:print("Using Kaeshi: Setsugekka on " .. target.name)
		self.actions.tsubame:use(target)
	elseif self.actions.hakaze:canUse(target) then
		log:print("Using Hakaze on " .. target.name)
		self.actions.hakaze:use(target)
	end
end

function Samurai:Meikyo(log, target, mei)
	
	if not player:hasStatus(1298) and self.actions.gekko:canUse(target) then
		log:print("Using Gekko on " .. target.name)
		self.actions.gekko:use(target)
	elseif not player:hasStatus(1299) and self.actions.kasha:canUse(target) then
		log:print("Using Kasha on " .. target.name)
		self.actions.kasha:use(target)
	elseif self.actions.yukikaze:canUse(target) then
	    log:print("Using Yukikaze on " .. target.name)
		self.actions.yukikaze:use(target)
	end

end


function Samurai:Weave(log, target, mei)
	if self.lastAction == self.actions.kasha.id and self.actions.ikishoten:canUse() then
		log:print("Using Ikishoten")
		self.actions.ikishoten:use()
		return true	
	elseif self.lastAction == self.actions.midare.id and self.actions.senei:canUse(target) then 
		log:print("Using Hissatsu: Senei on " .. target.name )
		self.actions.senei:use(target)
	elseif self.lastAction == self.actions.hakaze.id and self.actions.yukikaze:canUse(target) then 
		log:print("Using Yukikaze on " .. target.name)
		self.actions.yukikaze:use(target)
	end

	return false
end


return Samurai:new()