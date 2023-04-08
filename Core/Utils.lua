local _, ns = ...;

do
    if (ns.Utils) then return end

    local utils = {}
    ns.Utils = utils

    function utils.GenerateUuid()
        local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
        return string.gsub(template, '[xy]', function(c)
            local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
            return string.format('%x', v)
        end)
    end

    function utils.GetStringHash(text)
        local counter = 1
        local len = string.len(text)
        for i = 1, len, 3 do
            counter = math.fmod(counter * 8161, 4294967279) + -- 2^32 - 17: Prime!
                (string.byte(text, i) * 16776193) +
                ((string.byte(text, i + 1) or (len - i + 256)) * 8372226) +
                ((string.byte(text, i + 2) or (len - i + 256)) * 3932164)
        end
        return math.fmod(counter, 4294967291) -- 2^32 - 5: Prime (and different from the prime in the loop)
    end

    function utils.UpdateFont(fontString, newFontFile)
        local fontFile, height, flags = fontString:GetFont()
        if (fontFile == newFontFile) then return end
        fontString:SetFont(newFontFile, height, flags)
    end
end
