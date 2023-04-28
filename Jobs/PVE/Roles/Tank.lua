local Tank = Class("Tank")

function Tank:initialize()

    self.actions = {

        provoke    = Action(1, 7533),
        interject  = Action(1, 7538),
        low_blow   = Action(1, 7540),
    }

end

function Tank:load(menu)

    self.menu = menu

    self.menu:subMenu("Tank Settings", "ROLE_SETTINGS")
    self.menu["ROLE_SETTINGS"]:setIcon("XScripts", "\\Resources\\Icons\\Roles\\TankRole.png")

    for i, action in pairs(self.actions) do
        self.menu["ROLE_SETTINGS"]:subMenu( action.name .. " Settings", string.upper(i))
        self.menu["ROLE_SETTINGS"][string.upper(i)]:setIcon("XScriptsT", "\\Resources\\Icons\\Actions\\" .. i .. ".png")
        self.menu["ROLE_SETTINGS"][string.upper(i)]:checkbox("Use " .. action.name, "USE", true)
    end
    
end


function Tank:Tick()
    return self:Interject() or self:LowBlow() or self:Provoke()
end

function Tank:Provoke()
    local menu = self.menu["ROLE_SETTINGS"]["PROVOKE"]

    return false
end

function Tank:Interject()

    local menu = self.menu["ROLE_SETTINGS"]["INTERJECT"]

    if menu["USE"].bool and TargetManager.Target.valid then
        local target = TargetManager.Target
        if target.castInfo.isInterruptible and target.isCasting and self.actions.interject:canUse(target) then
            self.actions.interject:use(target)
            return true
        end

    end

    return false
end

function Tank:LowBlow()

    local menu = self.menu["ROLE_SETTINGS"]["LOW_BLOW"]

    if menu["USE"].bool and TargetManager.Target.valid then
        local target = TargetManager.Target
        if target.castInfo.isInterruptible and target.isCasting and self.actions.low_blow:canUse(target) then
            self.actions.low_blow:use(target)
            return true
        end

    end

    return false
end

return Tank:new()