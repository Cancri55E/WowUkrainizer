--- @class WowUkrainizerInternals
local ns = select(2, ...);

local SetText = ns.FontStringUtil.SetText

---@class BaseTooltipTranslator : BaseTranslator
---@field tooltipDataType Enum.TooltipDataType
local translator = setmetatable({
    fontStringIndexLookup = {}
}, { __index = ns.BaseTranslator })
ns.BaseTooltipTranslator = translator

function translator:Init()
    TooltipDataProcessor.AddTooltipPostCall(self.tooltipDataType, function(tooltip, tooltipData)
        self:TooltipCallback(tooltip, tooltipData)
    end)
end

function translator:AddFontStringToIndexLookup(index, obj)
    if (not index or not obj) then return end
    self.fontStringIndexLookup[index] = obj
end

---@private
function translator:_getFontStringFromIndexLookup(index)
    if (not index) then return end
    return self.fontStringIndexLookup[index]
end

--- Parse the tooltip and tooltip data; to be overridden by custom logic in subclasses
---@protected
function translator:ParseTooltip(tooltip, tooltipData)
end

--- Translate the tooltip info; to be overridden by custom logic in subclasses
---@protected
function translator:TranslateTooltipInfo(tooltipInfo)
end

---@protected
function translator:TooltipCallback(tooltip, tooltipData)
    self.fontStringIndexLookup = {}

    local tooltipInfo = self:ParseTooltip(tooltip, tooltipData)
    if (not tooltipInfo) then return end

    local translatedTooltipLines = self:TranslateTooltipInfo(tooltipInfo)
    if (not translatedTooltipLines) then return end

    for _, line in ipairs(translatedTooltipLines) do
        local tooltipFontString = self:_getFontStringFromIndexLookup(line.index)
        if (tooltipFontString) then
            SetText(tooltipFontString, line.value)
        end
    end
end
