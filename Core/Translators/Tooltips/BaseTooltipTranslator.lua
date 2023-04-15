local _, ns = ...;

local UpdateFontString = ns.FontStringExtensions.UpdateFontString

local translator = class("BaseTooltipTranslator", ns.Translators.BaseTranslator)
ns.Translators.BaseTooltipTranslator = translator

function translator:initialize(tooltipDataType)
    ns.Translators.BaseTranslator.initialize(self)
    self.fontStringIndexLookup = {}
    TooltipDataProcessor.AddTooltipPostCall(tooltipDataType,
        function(tooltip, tooltipData) self:TooltipCallback(tooltip, tooltipData) end)
end

function translator:_clearFontStringIndexLookup()
    self.fontStringIndexLookup = {}
end

function translator:_addFontStringToIndexLookup(index, obj)
    if (not index or not obj) then return end
    self.fontStringIndexLookup[index] = obj
end

function translator:_getFontStringFromIndexLookup(index)
    if (not index) then return end
    return self.fontStringIndexLookup[index]
end

-- Parse the tooltip and tooltip data; to be overridden by custom logic in subclasses
function translator:ParseTooltip(tooltip, tooltipData)
end

-- Translate the tooltip info; to be overridden by custom logic in subclasses
function translator:TranslateTooltipInfo(tooltipInfo)
end

function translator:TooltipCallback(tooltip, tooltipData)
    if (not self:IsEnabled()) then return end

    self:_clearFontStringIndexLookup()

    local tooltipInfo = self:ParseTooltip(tooltip, tooltipData)
    if (not tooltipInfo) then return end

    local translatedTooltipLines = self:TranslateTooltipInfo(tooltipInfo)
    if (not translatedTooltipLines) then return end

    for _, line in ipairs(translatedTooltipLines) do
        local tooltipFontString = self:_getFontStringFromIndexLookup(line.index)
        if (tooltipFontString) then
            UpdateFontString(tooltipFontString, line.value)
        end
    end
end
