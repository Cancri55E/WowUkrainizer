local _, ns = ...;

local internal = {}
ns.FontStringExtensions = internal

function internal.UpdateFontString(fontString, value)
    if (not fontString) then return end

    local r, g, b = fontString:GetTextColor()
    fontString:SetText(value)
    fontString:SetTextColor(r, g, b)
end
