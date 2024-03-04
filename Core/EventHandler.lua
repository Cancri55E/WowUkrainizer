--- @class WowUkrainizerInternals
local ns = select(2, ...);

--- Factory for creating event handler objects.
---@class EventHandlerFactory
local factory = {}
ns.EventHandlerFactory = factory

--- Creates a new event handler object for handling events and managing event callbacks.
---@return EventHandler @A new instance of the EventHandler class.
function factory.CreateEventHandler()
    --- Object for handling events and managing event callbacks.
    ---@class EventHandler
    local eventHandler = {}

    eventHandler._eventCallbacks = {}
    eventHandler._eventFrame = CreateFrame("Frame")

    --- Register a callback function for one or more events.
    ---@param callback function @The callback function to register.
    ---@vararg string @One or more event names.
    function eventHandler:Register(callback, ...)
        assert(type(callback) == "function")
        local events = { ... }
        for _, event in ipairs(events) do
            if not self._eventCallbacks[event] then
                self._eventCallbacks[event] = {}
                eventHandler._eventFrame:RegisterEvent(event)
            end
            table.insert(self._eventCallbacks[event], callback)
        end
    end

    --- Unregister a callback function for one or more events.
    ---@param callback function @The callback function to unregister.
    ---@vararg string @One or more event names.
    function eventHandler:Unregister(callback, ...)
        assert(type(callback) == "function")
        local events = { ... }
        for _, event in ipairs(events) do
            local callbacks = self._eventCallbacks[event]
            if callbacks then
                for i = #callbacks, 1, -1 do
                    if callbacks[i] == callback then
                        table.remove(callbacks, i)
                    end
                end
                if not callbacks[1] then
                    self._eventCallbacks[event] = nil
                    eventHandler._eventFrame:UnregisterEvent(event)
                end
            end
        end
    end

    --- Unregister all callbacks for all events.
    function eventHandler:UnregisterAll()
        for event, _ in pairs(self._eventCallbacks) do
            eventHandler._eventFrame:UnregisterEvent(event)
            self._eventCallbacks[event] = nil
        end
    end

    --- Handle an event and invoke registered callbacks.
    ---@param event string @The event name.
    ---@vararg any @Event arguments.
    function eventHandler:OnEvent(event, ...)
        local callbacks = self._eventCallbacks[event]
        if callbacks then
            for i = 1, #callbacks do
                callbacks[i](event, ...)
            end
        end
    end

    eventHandler._eventFrame:SetScript("OnEvent", function(_, event, ...)
        eventHandler:OnEvent(event, ...)
    end)

    return eventHandler
end
