local XAQueue   = Class("XAQueue")

function XAQueue:initialize()
   
    self.menu = nil

    self.activities = {}

    self.current_activity = nil

end

function XAQueue:Load(menu)

    self.menu   = menu
    self.widget = Menu("XActivities Queue", true)

    self.widget.width   = 500
    self.widget.visible = false

    self.widget:table("Activity Queue", "QUEUE_TABLE")
	self.widget["QUEUE_TABLE"]:column("Activity Name", "ACTIVITY_NAME")
	self.widget["QUEUE_TABLE"]:column("Activity Type", "ACTIVITY_TYPE")
	self.widget["QUEUE_TABLE"]:column("Remove",    "ACTIVITY_REMOVE")

	self.widget["QUEUE_TABLE"]["ACTIVITY_NAME"].width   = 200
	self.widget["QUEUE_TABLE"]["ACTIVITY_TYPE"].width   = 90
	self.widget["QUEUE_TABLE"]["ACTIVITY_REMOVE"].width = 50

    self.menu:separator()
    self.menu:button("Open XActivities Queue", "OPEN_QUEUE", function ()
        self.widget.visible = true
    end)

end

function XAQueue:GetNextActivity()

    if self.current_activity ~= nil then
        return self.current_activity
    end

    if #self.activities > 0 then
        return self.activities[1]
    end

    return nil

end

function XAQueue:AddActivity(activity)

    table.insert(self.activities, activity)

    if self.current_activity == nil then
        self.current_activity = activity
    end

    self.widget["QUEUE_TABLE"]["ACTIVITY_NAME"]:row(activity.module.name, activity.id)
    self.widget["QUEUE_TABLE"]["ACTIVITY_TYPE"]:row(self:GetActivityTypeStr(activity), activity.id)
    self.widget["QUEUE_TABLE"]["ACTIVITY_REMOVE"]:row("X", activity.id, function ()
        self.widget["QUEUE_TABLE"]:remove_row(activity.id)
        self:RemoveActivity(activity)
    end)

end

function XAQueue:RemoveActivity(activity)

    self.widget["QUEUE_TABLE"]:remove_row(activity.id)

    for i, a in ipairs(self.activities) do
        if a.id == activity.id then
            table.remove(self.activities, i)
        end
    end

    if self.current_activity.id == activity.id then
        self.current_activity = nil
    end

end

function XAQueue:GetActivityTypeStr(activity)
    if activity.type == 0 then
        return "DUTY_SUPPORT"
    end
end

return XAQueue:new()