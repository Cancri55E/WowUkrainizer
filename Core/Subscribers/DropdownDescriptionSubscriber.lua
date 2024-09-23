--- @class WowUkrainizerInternals
local ns = select(2, ...);

local subscriber = setmetatable({}, { __index = ns.BaseSubscriber })
subscriber.__index = subscriber

---@class DropdownDescriptionSubscriber : BaseSubscriber
ns.DropdownDescriptionSubscriber = subscriber

function subscriber:InitializeSubscriber()
    hooksecurefunc(Menu, "PopulateDescription", function(_, ownerRegion, rootDescription)
        for subscribedRegion, callbackFunc in pairs(self.subscriptions) do
            if (ownerRegion == subscribedRegion) then
                callbackFunc(rootDescription)
            end
        end
    end)
end