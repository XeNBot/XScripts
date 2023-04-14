local MeleeDPS = Class("MeleeDPS")

function MeleeDPS:initialize()

    self.actions = {

        second_wind = Action(1, 7541),
        bloodbath   = Action(1, 7542),
        true_north  = Action(1, 7546),
        arms_length = Action(1, 7548),
        feint       = Action(1, 7549),
        leg_sweep   = Action(1, 7863),
    }

end

function MeleeDPS:load(menu)

    self.menu = menu

    self.menu:subMenu("MeleeDPS Settings", "ROLE_SETTINGS")
    self.menu["ROLE_SETTINGS"]:setIcon("XScripts", "\\Resources\\Icons\\Roles\\DPSRole.png")

    for i, action in pairs(self.actions) do
        self.menu["ROLE_SETTINGS"]:subMenu( action.name .. " Settings", string.upper(i))
        self.menu["ROLE_SETTINGS"][string.upper(i)]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\" .. i .. ".png")
        self.menu["ROLE_SETTINGS"][string.upper(i)]:checkbox("Use " .. action.name, "USE", false)
    end

        self.menu["ROLE_SETTINGS"]["SECOND_WIND"]:checkbox("Prevent Overheal", "NO_OVERHEAL", true)
        self.menu["ROLE_SETTINGS"]["SECOND_WIND"]:slider("Minimum Health Percentage", "MIN_HEALTH", 1, 0, 100, 20)

        self.menu["ROLE_SETTINGS"]["LEG_SWEEP"]:checkbox("Use to stop target casts", "STOP_CASTS", true)

        self.menu["ROLE_SETTINGS"]["BLOODBATH"]:slider("Minimum Health Percentage", "MIN_HEALTH", 1, 0, 100, 50)

end


function MeleeDPS:Tick()
    return self:SecondWind() or self:LegSweep() or self:Bloodbath()
end

function MeleeDPS:SecondWind()

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

function MeleeDPS:LegSweep()

    local menu = self.menu["ROLE_SETTINGS"]["LEG_SWEEP"]

    if menu["USE"].bool and TargetManager.Target.valid then
        local target = TargetManager.Target
        if menu["STOP_CASTS"].bool and target.isCasting and self.actions.leg_sweep:canUse(target) then
            self.actions.leg_sweep:use(target)
            return true
        end

    end

    return false
end

function MeleeDPS:Bloodbath()

    local menu = self.menu["ROLE_SETTINGS"]["BLOODBATH"]

    if menu["USE"].bool then
        if self.actions.bloodbath:canUse() and player.healthPercent <= menu["MIN_HEALTH"].int then
            self.actions.bloodbath:use()
            return true
        end
    end

    return false
end

return MeleeDPS:new()