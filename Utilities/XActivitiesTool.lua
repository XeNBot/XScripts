local XATools   = Class("XATools")

function XATools:initialize()

    self.menu = nil

end

function XATools:Load(menu)

    self.menu   = menu
    self.widget = Menu("XActivities Tools", true)
    
    self.widget.width   = 500
    self.widget.visible = false

    self.menu:separator()
    self.menu:button("Open XActivities Tools", "OPEN_TOOLS", function ()
        self.widget.visible = true
    end)
    
    self.widget:label("Map ID : 0", "MAP_ID")
    self.widget:label("Player POS : Vector3(1,2,3)", "PLAYER_POS") self.widget:sameline() self.widget:button("Copy", "COPY_POS", function ()
        if player ~= nil then
            self:ToClipboard(tostring(player.pos))
        end
    end)

    self.widget:separator()
    self.widget:checkbox("Only show targetable objects", "TARGETABLE_OBJS", false)
    self.widget:subMenu("Battle Objects", "BATTLE_OBJECTS")
    self.widget:subMenu("Event Objects", "EVENT_OBJECTS")
    self.widget:subMenu("Event Npc Objects", "EVENT_NPC_OBJECTS")
    self:AddUpdateButton()

    self.obj_filter = function (obj)
        if self.widget["TARGETABLE_OBJS"].bool and not obj.isTargetable then
            return false
        end

        return obj.id ~= 0 and obj.dataId ~= 0 and obj.name ~= "" 
    end    
end

function XATools:Tick()

    self.widget["MAP_ID"].str = "Map ID : " .. tostring(AgentManager.GetAgent("Map").currentMapId)
    self.widget["PLAYER_POS"].str = "Player POS : " .. tostring(player.pos)

end

function XATools:UpdateAllLists()

    self.widget["UPDATE_ALL_LISTS"]:remove()

    self:UpdateObjectList("Battle Objects", ObjectManager.Battle(self.obj_filter))
    self:UpdateObjectList("Event Objects", ObjectManager.EventObjects(self.obj_filter))
    self:UpdateObjectList("Event Npc Objects", ObjectManager.EventNpcObjects(self.obj_filter))
    self:AddUpdateButton()

end

function XATools:UpdateObjectList(name, list)
    
    local id = string.upper(name)
    id = id:gsub(" ", "_")

    self.widget[id]:remove()
    self.widget:subMenu(name, id)

    table.sort(list, function (a, b)
        return a.name < b.name
    end)

    for i, obj in ipairs(list) do

        local obj_hash = string.upper(obj.name) .. "_" .. tostring(obj.id)

        self.widget[id]:subMenu(obj.name, obj_hash)
        self:AddObjectCopyLabel(id, obj_hash, "Object ID", tostring(obj.id))
        self:AddObjectCopyLabel(id, obj_hash, "Data ID", tostring(obj.dataId))
        self:AddObjectCopyLabel(id, obj_hash, "Position", tostring(obj.pos))
        self:AddObjectLabel(id, obj_hash, "Distance", tostring(player.pos:dist(obj.pos)))

    end

end

function XATools:AddObjectLabel(id, obj_hash, str, value)
    self.widget[id][obj_hash]:label(str .. ": " .. value)
    self.widget[id][obj_hash]:sameline()
end

function XATools:AddObjectCopyLabel(id, obj_hash, str, value)
    self.widget[id][obj_hash]:label(str .. ": " .. value)
    self.widget[id][obj_hash]:sameline()
    self.widget[id][obj_hash]:button("COPY", "COPY_" .. obj_hash, function ()
        self:ToClipboard(tostring(value))
    end )
end

function XATools:ToClipboard(str)
    print("Copied : \"" .. str .. "\" to clipboard")
    Keyboard.SetClipboard(str)
end

function XATools:AddUpdateButton()
    self.widget:button("Update All Lists", "UPDATE_ALL_LISTS", function ()
        self:UpdateAllLists()
    end)
end

return XATools:new()
