local XActivities = Class("XActivities")

-- Activity Types
ACTIVITY_DUTY_SUPPORT       = 0

function XActivities:initialize()

    -- XActivity Vars
    self.duty_supports    = {}
    self.current_activity = nil

    self.menu = Menu("XActivities")

    self.menu:subMenu("Duty Support", "DUTY_SUPPORT")
        self:LoadDutySupportMenu()

    Callbacks:Add(CALLBACK_PLAYER_TICK, function () self:Tick() end)
end

function XActivities:Tick()
    if self.current_activity ~= nil then        
        if self.current_activity.type == ACTIVITY_DUTY_SUPPORT then
            self:HandleDutySupportActivity()
        end
    end
end

function XActivities:CanTick()
	if self.current_activity ~= nil then
		return true
	end
end

function XActivities:HandleDutySupportActivity()

	if not self.current_activity:IsIn() and not TaskManager:IsBusy() then
		TaskManager:EnterDutySupport(
			self.current_activity.tab_index,
			self.current_activity.duty_index
		)
	end

end

function XActivities:LoadDutySupportMenu()

    local ds_list = GetFileList("/Scripts/XScripts/Activities/DutySupport/")

    for i, duty in ipairs(ds_list) do

		if duty.find(duty, ".lua") then

			local duty_module = LoadModule("XScripts", "/Activities/DutySupport/" .. duty)
			local duty_id     = string.upper(duty_module.name)

			self.duty_supports[duty_id] = duty_module

			table.insert(self.duty_supports, duty_module)

			self.menu["DUTY_SUPPORT"]:separator()
			self.menu["DUTY_SUPPORT"]:label(duty_module.name .. " (Level: " .. tostring(duty_module.level) .. ")", duty_id)
			self.menu["DUTY_SUPPORT"]:sameline()
			self.menu["DUTY_SUPPORT"]:button("Start", "START_" .. duty_id, function ()
				if self.current_activity == nil then
					self.current_activity = self.duty_supports[duty_id]
					self.menu["DUTY_SUPPORT"]["START_" .. duty_id].str = "Stop"
				else
					self.current_activity = nil
					self.menu["DUTY_SUPPORT"]["START_" .. duty_id].str = "Start"
				end
			end)
			self.menu["DUTY_SUPPORT"]:separator()
		end
    end

end

_G.XACTIVITIES = XActivities:new()