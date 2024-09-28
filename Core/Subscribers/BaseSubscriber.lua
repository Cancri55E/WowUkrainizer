--- @class WowUkrainizerInternals
local ns = select(2, ...)

local subscriber = {}
subscriber.__index = subscriber

---@class BaseSubscriber
ns.BaseSubscriber = subscriber

function subscriber:GetInstance()
    if not self._instance then
        self._instance = setmetatable({
            subscriptions = {}
        }, self)

        self._instance:InitializeSubscriber()
    end
    return self._instance
end

function subscriber:Subscribe(ownerRegion, callbackFunc)
    if (self._instance ~= self) then
        error("WowUkrainizer: Помилка! функція 'Subscribe' має викликатися через екземпляр синглтона!")
        return
    end

    if not self.subscriptions[ownerRegion] then
        self.subscriptions[ownerRegion] = callbackFunc
    end
end

function subscriber:InitializeSubscriber()
    error("WowUkrainizer: Помилка! функція 'InitializeSubscriber' має бути реалізована у дочерньому класі!")
end
