local XActivity         = LoadModule("XScripts", "/Activities/XActivity")
local GatheringActivity = Class("GatheringActivity", XActivity)

function GatheringActivity:initialize()

    XActivity.initialize(self)

    self.type           = 1
    self.items          = {}
    
    self.start_counts   = {}
    self.started_counts = false

    self.actions = {
        teleport = Action(1, 5)
    }
 
    self.last_teleport  = 0
    self.last_interact  = 0

    Callbacks:Add(CALLBACK_PLAYER_DRAW, function () self:Drawer() end)
    
end

function GatheringActivity:Tick()
    if self.running and self:CanTick() then

        if #self.items == 0 then
            print("finished gathering all items")
            return
        end

        if not self.started_counts then
            
            for i, item in ipairs(self.items) do
                local item_count = InventoryManager.GetItemCount(item.id)
                self.start_counts[item.id] = item_count
            end

            self.started_counts = true
        end

        local next_item   = self.items[1]
        local item_count  = InventoryManager.GetItemCount(next_item.id)
        local start_count = self.start_counts[next_item.id]
        local loot_count  = next_item.amount

        if next_item.job ~= player.classJob then
            print("trying to change jobs make sure to have icon in any hotbar!")
            return self:SetJob(next_item.job)
        end
       
        local gathering_addon = AddonManager.GetAddon("Gathering")
        if gathering_addon ~= nil then
            print("1")
            return TaskManager:GatherItem(next_item.id)
        end
        
        if (item_count - start_count >= loot_count) then
            table.remove(self.items, 1)
            return
        else
            local map_id = AgentManager.GetAgent("Map").currentMapId
            if map_id ~= next_item.map and self.actions.teleport:canUse() and not player.isCasting then
                player:teleportTo(next_item.aetheryte)
                self.last_teleport = os.clock()
            elseif map_id == next_item.map then
                self:HandleMap(next_item)
            end

        end

    end
end

function GatheringActivity:CanTick()

    return ((os.clock() - self.last_teleport) > 4) and
           ((os.clock() - self.last_interact) > 2)

end

function GatheringActivity:HandleMap(next_item)
    local nearby_nodes = ObjectManager.Gathering(function (obj) return obj.isTargetable end)
    local found_item   = false
    local item_node    = nil
    local node_dist    = 3333
    print("4")
    for i, node in ipairs(nearby_nodes) do
        local dist = node.pos:dist(player.pos)
        if node.gatheringType ~= 3 and dist < node_dist then
            for i, item in ipairs(node.gatheringItems) do
                if item.id == next_item.id then
                    found_item = true
                    item_node  = node
                    node_dist  = dist
                end
            end
        end

    end

    if not found_item and not TaskManager:IsBusy() then
        if next_item.start:dist(player.pos) > 5 then
            self:StartNav(next_item.start, NAV_TYPE_DESTINATION, false)
        else
            print("Couldn't find any items here fam")
        end
    else
        if item_node ~= nil then
            if node_dist > 3.5 and not TaskManager:IsBusy() then
                print("6")
                self:StartNav(item_node.pos, NAV_TYPE_GATHER, false)
            elseif node_dist < 3.5 then
                if TaskManager:IsBusy() and self.nav_type == NAV_TYPE_GATHER then
                    self:ResetNav()
                end
                print("7")
                TaskManager:Interact(item_node)
                self.last_interact = os.clock()
            end
        end
    end
end

function GatheringActivity:Drawer()
	if self.current_nav ~= nil then
		local last_pos = nil
		local end_pos  = self.current_nav.waypoints[#self.current_nav.waypoints]

		for i, pos in ipairs(self.current_nav.waypoints) do
			if i ~= 1 then
				Graphics.DrawCircle3D(pos, 4, 0.25, Colors.Blue)
			end
			if last_pos ~= nil then
				Graphics.DrawLine3D(last_pos, pos, Colors.Yellow)
			end
			last_pos = pos
		end
		if last_pos ~= nil and self.end_pos ~= Vector3.Zero then
			Graphics.DrawLine3D(last_pos, end_pos, Colors.Yellow)
		end

	end
end

return GatheringActivity