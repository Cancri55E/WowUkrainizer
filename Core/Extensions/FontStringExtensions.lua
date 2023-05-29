local _, ns = ...;

local internal = {}
ns.FontStringExtensions = internal

function internal.SetText(fontString, value)
    if (not fontString) then return end

    local r, g, b = fontString:GetTextColor()
    fontString:SetText(value)
    fontString:SetTextColor(r, g, b)
end

function internal.SetFont(fontString, fontName, scale)
    local _, height, flags = fontString:GetFont()
    fontString:SetFont(fontName, height * scale, flags)
end
