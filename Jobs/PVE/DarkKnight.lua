local DarkKnight = Class("Dark Knight")

--adds a new callback whenever a action is successfully executed
Callbacks:Add(CALLBACK_ACTION_USED, function(actionType, actionId, targetId)
    -- prints information about the action that was used
    print("Action used of type " .. actionType .. " with the id of "
    .. actionId .. " and the target was " .. targetId)
  end)

function DarkKnight:initialize()

	self.actions = {
        
        hardslash      = Action(1, 3617),
        unleash        = Action(1, 3621),
        syphonstrike   = Action(1, 3623),
        unmend         = Action(1, 3624),
        bloodweapon    = Action(1, 3625),
        grit           = Action(1, 3629),
        souleater      = Action(1, 3632),
        shadowwall     = Action(1, 3636),

        rampart        = Action(1, 7531),
		provoke        = Action(1, 7533),
		reprisal       = Action(1, 7535),
		interject      = Action(1, 7538),
		lowblow        = Action(1, 7540),

        edgeofdarkness = Action(1, 16467),

	}

	self.menu             = nil
	self.lastAction       = 0
    self.lastRotation     = 0
    self.actionBeforeLast = 0
    self.combo            = false

	Callbacks:Add(CALLBACK_ACTION_EFFECT, function(source, pos, actionId, targetId)
        if source.id == player.id and actionId ~= 7 then
            self.actionBeforeLast = self.lastAction
            self.lastAction       = actionId
        end

    end)

end

function DarkKnight:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["TANK"]:subMenu("Dark Knight", "DRK")
end

function DarkKnight:Tick(log)

    local menu    = self.menu["ACTIONS"]["TANK"]["DRK"]

	local target = TargetManager.Target

    if not target.valid or target.kind ~= 2 or target.subKind ~= 5 or target.pos:dist(player.pos) > 3 then return end

    --[[self:ProvokeCheck(log)

	    if not target.valid or target.kind ~= 2 or target.subKind ~= 5 or target.pos:dist(player.pos) > 20 then return end

    if ObjectManager.EnemiesAroundObject(player, 5) > 2 or player.healthPercent < 60 then
        if self.actions.reprisal:canUse() and not player:hasStatus(1191) then
         self.actions.reprisal:use()
        elseif self.actions.rampart:canUse() and not player:hasStatus(1193) then
            self.actions.rampart:use()
        end
    end--]]
    if player.classLevel > 35 and (player.missingMana == 0 or self.combo)  then
        self:Combo(target, menu, log)
    else 
        self:Level35Combo(target, menu, log)
    end
end

function DarkKnight:Level35Combo(target, menu, log)
    if not player:hasStatus(743) and self.actions.grit:canUse() then 
        self.actions.grit:use()
    elseif self.actions.reprisal:canUse() then 
        self.actions.reprisal:use()
    elseif self.lastAction == self.actions.syphonstrike.id and self.actions.souleater:canUse(target) then
        self.actions.souleater:use(target)
    elseif self.lastAction == self.actions.hardslash.id and self.actions.syphonstrike:canUse(target) then
         self.actions.syphonstrike:use(target)
    elseif self.lastAction == self.actions.unmend.id and self.actions.hardslash:canUse(target) then
		self.actions.hardslash:use(target)
    elseif self.actions.unmend:canUse(target) then
        self.actions.unmend:use(target)
    end 
end

function DarkKnight:Combo(target, menu, log)
    if not player:hasStatus(743) and self.actions.grit:canUse() then
        self.actions.grit:use()
    elseif self.actions.reprisal:canUse() and not self.combo then
        self.actions.reprisal:use()
    elseif self.actions.shadowwall:canUse() and not self.combo then
        self.actions.shadowwall:use()
    elseif self.actionBeforeLast == self.actions.edgeofdarkness.id and self.lastAction == self.actions.souleater.id and self.actions.edgeofdarkness:canUse(target) then
        self.actions.edgeofdarkness:use(target)
        print("use EOD 5th")
        if self.combo then
            self.combo = false
        end
    elseif self.actionBeforeLast == self.actions.syphonstrike.id and self.lastAction == self.actions.edgeofdarkness.id and self.actions.souleater:canUse(target) then
        self.actions.souleater:use(target)
        print("use soul eater 2nd")
    elseif self.actionBeforeLast == self.actions.edgeofdarkness.id and self.lastAction == self.actions.syphonstrike.id and self.actions.edgeofdarkness:canUse(target) then
        self.actions.edgeofdarkness:use(target)
        print("use EOD 4th")
    elseif self.actionBeforeLast == self.actions.hardslash.id and self.lastAction == self.actions.edgeofdarkness.id and self.actions.syphonstrike:canUse(target) then
        self.actions.syphonstrike:use(target)
        print("use Syphone strike 2nd")
    elseif self.combo and self.lastAction == self.actions.hardslash.id and self.actions.edgeofdarkness:canUse(target) then
        self.actions.edgeofdarkness:use(target) 
        print("use EOD 1st and 3rd")   
    elseif self.lastAction == self.actions.edgeofdarkness.id and self.actions.hardslash:canUse(target) then
        self.actions.hardslash:use(target)
        print("use hardslash 2nd")
    elseif self.combo and self.lastAction == self.actions.souleater.id and self.actions.edgeofdarkness:canUse(target) then
        self.actions.edgeofdarkness:use(target)
        print("use EOD 2nd")
    elseif self.lastAction == self.actions.syphonstrike.id and self.actions.souleater:canUse(target) then
        self.actions.souleater:use(target)
        print("use Soul eater 1st")
    elseif self.lastAction == self.actions.bloodweapon.id and self.actions.syphonstrike:canUse(target) then
        self.actions.syphonstrike:use(target)
        print("use syphon strike 1st")
    elseif self.lastAction == self.actions.edgeofdarkness.id and self.actions.bloodweapon:canUse() then 
        self.actions.bloodweapon:use()
        print("use BW")
    elseif self.actions.hardslash:canUse(target) then
        self.actions.hardslash:use(target)
        print("use hardslash 1st")
        if self.actions.bloodweapon:canUse() then 
            self.combo = true
        end
    end
end

return DarkKnight:new()