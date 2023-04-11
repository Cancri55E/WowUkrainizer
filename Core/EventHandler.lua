local _, ns = ...;

local eventHandler = class("EventHandler");
ns.EventHandler = eventHandler

local eventCallbacks = {}
local eventFrame = CreateFrame("Frame")

function eventHandler:Register(callback, ...)
    assert(type(callback) == "function")
    local events = { ... }
    for _, event in ipairs(events) do
        if not eventCallbacks[event] then
            eventCallbacks[event] = {}
            eventFrame:RegisterEvent(event)
        end
        table.insert(eventCallbacks[event], callback)
    end
end

function eventHandler:Unregister(callback, ...)
    assert(type(callback) == "function")
    local events = { ... }
    for _, event in ipairs(events) do
        local callbacks = eventCallbacks[event]
        if callbacks then
            for i = #callbacks, 1, -1 do
                if callbacks[i] == callback then
                    table.remove(callbacks, i)
                end
            end
            if not callbacks[1] then
                eventCallbacks[event] = nil
                eventFrame:UnregisterEvent(event)
            end
        end
    end
end

function eventHandler:UnregisterAll()
    for event, _ in pairs(eventCallbacks) do
        eventFrame:UnregisterEvent(event)
        eventCallbacks[event] = nil
    end
end

function eventHandler:OnEvent(event, ...)
    local callbacks = eventCallbacks[event]
    if callbacks then
        for i = 1, #callbacks do
            callbacks[i](event, ...)
        end
    end
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    eventHandler:OnEvent(event, ...)
end)
