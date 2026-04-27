--- @class WowUkrainizerInternals
local ns = select(2, ...);

--- Unified accessor for reading and writing tooltip line FontStrings.
--- Works with any named tooltip frame (GameTooltip, ElvUI_SpellBookTooltip, ShoppingTooltip1, etc.).
---@class TooltipLineAccessor
local accessor = {}
ns.TooltipLineAccessor = accessor

--- Get the left FontString widget for a given tooltip line number.
---@param tooltip GameTooltip
---@param lineNum number 1-based line number
---@return FontString|nil
function accessor.GetLeftFontString(tooltip, lineNum)
    local name = tooltip:GetName()
    if not name then return nil end
    return _G[name .. "TextLeft" .. lineNum]
end

--- Get the right FontString widget for a given tooltip line number.
---@param tooltip GameTooltip
---@param lineNum number 1-based line number
---@return FontString|nil
function accessor.GetRightFontString(tooltip, lineNum)
    local name = tooltip:GetName()
    if not name then return nil end
    return _G[name .. "TextRight" .. lineNum]
end

--- Safely read text from a tooltip line's left FontString.
---@param tooltip GameTooltip
---@param lineNum number
---@return string|nil text The text, or nil if not available or secret
---@return boolean isSecret True if text exists but is a secret value (12.0 combat restriction)
function accessor.GetLeftText(tooltip, lineNum)
    local fs = accessor.GetLeftFontString(tooltip, lineNum)
    if not fs then return nil, false end
    local text = fs:GetText()
    if text == nil then return nil, false end
    if issecretvalue(text) then return nil, true end
    return text, false
end

--- Safely read text from a tooltip line's right FontString.
---@param tooltip GameTooltip
---@param lineNum number
---@return string|nil text The text, or nil if not available or secret
---@return boolean isSecret True if text exists but is a secret value (12.0 combat restriction)
function accessor.GetRightText(tooltip, lineNum)
    local fs = accessor.GetRightFontString(tooltip, lineNum)
    if not fs then return nil, false end
    local text = fs:GetText()
    if text == nil then return nil, false end
    if issecretvalue(text) then return nil, true end
    return text, false
end

--- Set text on a tooltip line's left FontString, preserving text color.
---@param tooltip GameTooltip
---@param lineNum number
---@param value string
function accessor.SetLeftText(tooltip, lineNum, value)
    local fs = accessor.GetLeftFontString(tooltip, lineNum)
    if not fs then return end
    local r, g, b = fs:GetTextColor()
    fs:SetText(value)
    fs:SetTextColor(r, g, b)
end

--- Set text on a tooltip line's right FontString, preserving text color.
---@param tooltip GameTooltip
---@param lineNum number
---@param value string
function accessor.SetRightText(tooltip, lineNum, value)
    local fs = accessor.GetRightFontString(tooltip, lineNum)
    if not fs then return end
    local r, g, b = fs:GetTextColor()
    fs:SetText(value)
    fs:SetTextColor(r, g, b)
end

--- Safely iterate and translate all lines of a tooltip using a translation function.
--- Secret lines are skipped per-line — translateFunc is never called with a secret value,
--- so it is safe to perform hash lookups, comparisons, and other operations inside it.
--- Replaces the core loop of TooltipUtil:OnUpdateTooltip.
---@param tooltip GameTooltip
---@param translateFunc fun(text: string): string
---@param startLine number|nil Starting line (default 1)
---@param endLine number|nil Ending line (default tooltip:NumLines())
---@param ignoreLeft boolean|nil Skip left text lines
---@param ignoreRight boolean|nil Skip right text lines
function accessor.TranslateLines(tooltip, translateFunc, startLine, endLine, ignoreLeft, ignoreRight)
    local start = startLine or 1
    local stop = endLine or tooltip:NumLines()
    for i = start, stop do
        if not ignoreLeft then
            local text, isSecret = accessor.GetLeftText(tooltip, i)
            if text and not isSecret then
                accessor.SetLeftText(tooltip, i, translateFunc(text))
            end
        end
        if not ignoreRight then
            local text, isSecret = accessor.GetRightText(tooltip, i)
            if text and not isSecret then
                accessor.SetRightText(tooltip, i, translateFunc(text))
            end
        end
    end
end
