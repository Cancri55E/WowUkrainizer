--- @type string, WowUkrainizerInternals
local _, ns = ...;

ns.Translators = {}

local translator = class("BaseTranslator")
ns.Translators.BaseTranslator = translator

function translator:initialize()
    self.enabled = false
end

function translator:SetEnabled(enabled)
    self.enabled = enabled
    if (enabled) then self:OnEnabled() else self:OnDisabled() end
end

function translator:OnEnabled()
end

function translator:OnDisabled()
end

function translator:IsEnabled()
    return self.enabled
end
