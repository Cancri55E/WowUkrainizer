--- @type string, WowUkrainizerInternals
local _, ns = ...;

---Utility module for manipulating FontString objects.
---@class FontStringUtil
local internal = {}
ns.FontStringUtil = internal

--- Set text of a font string and maintain its original text color.
---@param fontString FontString @The font string to set text for.
---@param value string @The text value to set.
function internal.SetText(fontString, value)
    if (not fontString) then return end

    local r, g, b = fontString:GetTextColor()

    fontString:SetText(value)
    fontString:SetTextColor(r, g, b)
end
