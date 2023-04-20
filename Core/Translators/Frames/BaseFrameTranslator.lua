local _, ns = ...;

local _G = _G

local translator = class("BaseFrameTranslator", ns.Translators.BaseTranslator)
ns.Translators.BaseFrameTranslator = translator

local function fillOriginalTable(self)
    if (not self.original) then return end
    for _, value in ipairs(self.translationMap.constants) do
        self.original[value] = _G[value]
    end
end

local function enableTranslation(self)
    for _, value in ipairs(self.translationMap.constants) do
        _G[value] = self.translations[value]
    end
end

local function disableTranslation(self)
    if (not self.original) then return end
    for _, value in ipairs(self.translationMap.constants) do
        _G[value] = self.original[value]
    end
end

function translator:initialize()
    self.original = {}
    self.translations = {}
    self:TranslationMap()
    fillOriginalTable(self)

    self:TranslationEnabled(true)
end

function translator:TranslationMap()
end

function translator:TranslationEnabled(value)
    if (value) then enableTranslation(self) else disableTranslation(self) end
end
