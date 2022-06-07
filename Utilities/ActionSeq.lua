local ActionSeq = Class("ActionSeq")

function ActionSeq:initialize(targetFilter)
	
	self.seqs   = {}
	self.filter = targetFilter

end

function ActionSeq:Add(action, req)
	
	table.insert(self.seqs, { a = action, r = req, t = nil })

end

function ActionSeq:Execute()
	
	for i, s in ipairs(self.seqs)	do
		
		if s.r() then

			local target = self:GetTarget(s.a)

			if target ~= nil then
				s.a:use(target)
			end
		end

	end

end

function ActionSeq:GetTarget(action)
	-- PVP Training Map
	if AgentModule.currentMapId == 51 then
		return TargetManager.Target
	end

	return ObjectManager.GetLowestHealthEnemy(action.range, function(target) return self.targetFilter(action, target) end)

end

return ActionSeq