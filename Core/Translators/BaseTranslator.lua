local _, ns = ...;

ns.Translators = {}

local translator = class("BaseTranslator")
ns.Translators.BaseTranslator = translator

function translator:initialize()
    self.enabled = false
end

function translator:SetEnabled(enabled)
    self.enabled = enabled
end

function translator:IsEnabled()
    return self.enabled
end
