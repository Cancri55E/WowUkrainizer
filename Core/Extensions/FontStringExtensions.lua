--- @class WowUkrainizerInternals
local ns = select(2, ...);

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

--- This function updates the text of a given UI font string element using a provided translation function.
--- It takes a font string object and a translation function as parameters, then sets the font string's
--- text to the translated version of its current text.
--- @param fontStringObject FontString @The UI font string object to be updated
--- @param translationFunc function @The function used for translation
function internal.UpdateTextWithTranslation(fontStringObject, translationFunc)
    fontStringObject:SetText(translationFunc(fontStringObject:GetText()))
end
