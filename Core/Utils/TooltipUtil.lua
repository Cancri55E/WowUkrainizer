--- @class WowUkrainizerInternals
local ns = select(2, ...);

local SetText = ns.FontStringUtil.SetText

--- Utility module providing ....
---@class TooltipUtil
local internal = {}
ns.TooltipUtil = internal

function internal:OnUpdateTooltip(tooltip, expectedOwner, getTranstatedStringFunc, ignoreRightText, ignoreLeftText)
    local currentTooltipOwner = tooltip:GetOwner()
    if (currentTooltipOwner and currentTooltipOwner ~= expectedOwner) then return end

    for i = 1, tooltip:NumLines() do
        local tooltipName = tooltip:GetName()
        if (not ignoreLeftText) then
            local tooltipLeftLine = _G[tooltipName .. "TextLeft" .. i]
            SetText(tooltipLeftLine, getTranstatedStringFunc(tooltipLeftLine:GetText()))
        end

        if (not ignoreRightText) then
            local tooltipRightLine = _G[tooltipName .. "TextRight" .. i]
            SetText(tooltipRightLine, getTranstatedStringFunc(tooltipRightLine:GetText()))
        end
    end

    tooltip:Show()
end

function internal:OnUpdateGameTooltip(expectedOwner, getTranstatedStringFunc, ignoreRightText, ignoreLeftText)
    self:OnUpdateTooltip(GameTooltip, expectedOwner, getTranstatedStringFunc, ignoreRightText, ignoreLeftText)
end
