--- @class WowUkrainizerInternals
local ns = select(2, ...);

local TranslateLines = ns.TooltipLineAccessor.TranslateLines

--- Utility module providing tooltip translation helpers for frame translators.
---@class TooltipUtil
local internal = {}
ns.TooltipUtil = internal

function internal:OnUpdateTooltip(tooltip, expectedOwner, getTranslatedStringFunc, ignoreRightText, ignoreLeftText)
    local currentTooltipOwner = tooltip:GetOwner()
    if (currentTooltipOwner and currentTooltipOwner ~= expectedOwner) then return end

    TranslateLines(tooltip, getTranslatedStringFunc, nil, nil, ignoreLeftText, ignoreRightText)
    tooltip:Show()
end

function internal:OnUpdateGameTooltip(expectedOwner, getTranslatedStringFunc, ignoreRightText, ignoreLeftText)
    self:OnUpdateTooltip(GameTooltip, expectedOwner, getTranslatedStringFunc, ignoreRightText, ignoreLeftText)
end
