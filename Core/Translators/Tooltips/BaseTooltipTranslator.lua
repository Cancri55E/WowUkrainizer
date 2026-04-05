--- @class WowUkrainizerInternals
local ns = select(2, ...);

local TLA = ns.TooltipLineAccessor

---@class BaseTooltipTranslator : BaseTranslator
---@field tooltipDataType Enum.TooltipDataType
local translator = setmetatable({}, { __index = ns.BaseTranslator })
ns.BaseTooltipTranslator = translator

function translator:Init()
    TooltipDataProcessor.AddTooltipPostCall(self.tooltipDataType, function(tooltip, tooltipData)
        self:TooltipCallback(tooltip, tooltipData)
    end)
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
    if issecrettable(tooltipData) then return end

    local tooltipInfo = self:ParseTooltip(tooltip, tooltipData)
    if (not tooltipInfo) then return end

    local translatedTooltipLines = self:TranslateTooltipInfo(tooltipInfo)
    if (not translatedTooltipLines) then return end

    for _, entry in ipairs(translatedTooltipLines) do
        if entry.right then
            TLA.SetRightText(tooltip, entry.line, entry.value)
        else
            TLA.SetLeftText(tooltip, entry.line, entry.value)
        end
    end
end
