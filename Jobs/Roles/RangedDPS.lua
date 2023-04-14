local RangedDPS = Class("RangedDPS")

function RangedDPS:initialize()

    self.actions = {

        second_wind = Action(1, 7541),
        head_graze  = Action(1, 7551)
    }

end

function RangedDPS:load(menu)

    self.menu = menu

    self.menu:subMenu("RangedDPS Settings", "ROLE_SETTINGS")
    self.menu["ROLE_SETTINGS"]:setIcon("XScripts", "\\Resources\\Icons\\Roles\\DPSRole.png")

    for i, action in pairs(self.actions) do
        self.menu["ROLE_SETTINGS"]:subMenu( action.name .. " Settings", string.upper(i))
        self.menu["ROLE_SETTINGS"][string.upper(i)]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\" .. i .. ".png")
        self.menu["ROLE_SETTINGS"][string.upper(i)]:checkbox("Use " .. action.name, "USE", true)
    end

        self.menu["ROLE_SETTINGS"]["SECOND_WIND"]:checkbox("Prevent Overheal", "NO_OVERHEAL", true)
        self.menu["ROLE_SETTINGS"]["SECOND_WIND"]:slider("Minimum Health Percentage", "MIN_HEALTH", 1, 0, 100, 20)
end


function RangedDPS:Tick()
    return self:SecondWind() or self:HeadGraze()
end

function RangedDPS:SecondWind()

    local menu = self.menu["ROLE_SETTINGS"]["SECOND_WIND"]

    if menu["USE"].bool then
        if self.actions.second_wind:canUse() and player.healthPercent <= menu["MIN_HEALTH"].int then

            if menu["NO_OVERHEAL"].bool and self.actions.second_wind:calcHealing(500) < player.health then
                return false
            end
            self.actions.second_wind:use()
            return true
        end
    end

    return false

end

function RangedDPS:HeadGraze()

    local menu = self.menu["ROLE_SETTINGS"]["HEAD_GRAZE"]

    if menu["USE"].bool and TargetManager.Target.valid then
        local target = TargetManager.Target
        if target.castInfo.isInterruptible and target.isCasting and self.actions.leg_sweep:canUse(target) then
            self.actions.head_graze:use(target)
            return true
        end

    end

    return false
end

return RangedDPS:new()