local Warrior = Class("Warrior")

function Warrior:initialize()

	self.actions = {		
		
		heavyswing = Action(1, 31),
		maim       = Action(1, 37),
		berserk    = Action(1, 38),
		overpower  = Action(1, 41),
		stormpath  = Action(1, 42),
		tomahawk   = Action(1, 46),
		defiance   = Action(1, 48),
		
		rampart    = Action(1, 7531),
		provoke    = Action(1, 7533),
		reprisal   = Action(1, 7535),
		interject  = Action(1, 7538),
		lowblow    = Action(1, 7540),


	}

	self.menu         = nil
	self.lastAction   = 0
	self.lastRotation = 0
	
	Callbacks:Add(CALLBACK_ACTION_REQUESTED, function(actionType, actionId, targetId, result)

		if result == 1 and actionType == 1 then
			self.lastAction = actionId
		end

	end)

end

function Warrior:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["TANK"]:subMenu("Warrior", "WAR")
end

function Warrior:Tick(log)
	
	local menu    = self.menu["ACTIONS"]["TANK"]["WAR"]

	local target = TargetManager.Target

	if not player:hasStatus(91) and self.actions.defiance:canUse() then
		log:print("Using Defiance")
		self.actions.defiance:use()
	end

	if not target.valid or target.kind ~= 2 or target.subKind ~= 5 or target.pos:dist(player.pos) > 20 then return end

	if ObjectManager.EnemiesAroundObject(player, 5) > 2 or player.healthPercent < 60 then
		if self.actions.reprisal:canUse() and not player:hasStatus(1191) then
			self.actions.reprisal:use()
		elseif self.actions.rampart:canUse() and not player:hasStatus(1193) then
			self.actions.rampart:use()
		end
	end	

	self:Rotate(target)

	if self.actions.berserk:canUse() then
		self.actions.berserk:use()
	end

	-- tries to cancel target actions
	if target.isCasting then
		if self.actions.interject:canUse(target) then
			log:print("Using Interject on " .. target.name)
			self.actions.interject:use(target)
		elseif self.actions.lowblow:canUse(target) then
			log:print("Using Low Blow on " .. target.name)
			self.actions.lowblow:use(target)
		end
	end

	self:Combo(target, menu, log)
end

function Warrior:Combo(target, menu, log)
	
		--Tomahawk
	if target.pos:dist(player.pos) > 3 and self.actions.tomahawk:canUse(target) then
		self.actions.tomahawk:use(target)
		-- Storm's Path
	elseif self.lastAction == self.actions.maim.id and self.actions.stormpath:canUse(target) then
		log:print("Using Storm's Path on " .. target.name)
		self.actions.stormpath:use(target)		
		-- Maim
	elseif self.lastAction == self.actions.heavyswing.id and self.actions.maim:canUse(target) then
		log:print("Using Maim on " .. target.name)
		self.actions.maim:use(target)
		-- Overpower
	elseif self.actions.overpower:canUse() and ObjectManager.BattleEnemiesAroundObject(player, 5) > 1 then
		log:print("Using Overpower")
		self.actions.overpower:use()
		-- Heavy Swing	
	elseif self.actions.heavyswing:canUse(target) then
		log:print("Using Heavy Swing on " .. target.name)
		self.actions.heavyswing:use(target)
	end

end

function Warrior:Rotate(obj)
	if os.clock() - self.lastRotation > 1 then
		player:rotateTo(obj.pos)
		self.lastRotation = os.clock()
	end
end

return Warrior:new()