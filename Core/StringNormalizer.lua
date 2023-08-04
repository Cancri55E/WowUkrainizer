local _, ns = ...;

local ExtractNumericValues = ns.StringExtensions.ExtractNumericValues
local InsertNumericValues = ns.StringExtensions.InsertNumericValues
local DeclensionWord = ns.StringExtensions.DeclensionWord

local internal = {}
ns.StringNormalizer = internal

function internal.NormalizeStringAndExtractNumerics(text)
    if text == nil or text == "" then
        return text
    end

    local icons = {}
    text = string.gsub(text, "%|T(.-)%|t", function(match)
        table.insert(icons, match)
        return string.format("{icon:%s}", string.char(#icons + 64))
    end)

    local colors = {}
    text = string.gsub(text,
        "%|[cC]([0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])(.-)%|[rR]",
        function(color, title)
            table.insert(colors, color)
            return string.format("{color:%s|%s}", string.char(#colors + 64), title)
        end)

    local numbers = {}
    text, numbers = ExtractNumericValues(text)

    for i = 1, #icons do
        text = text:gsub(string.format("{icon:%s}", string.char(i + 64)), "|T" .. icons[i] .. "|t")
    end

    for i = 1, #colors do
        text = text:gsub(string.format("{color:%s", string.char(i + 64)), "{" .. colors[i])
    end

    return text, numbers
end

function internal.ReconstructStringWithNumerics(str, numbers)
    local result = InsertNumericValues(str, numbers)

    result = result:gsub("{(%x+)|([^}]+)}", "|c%1%2|r")

    result = result:gsub("(%d+)( *){(declension)|([^|]+)|([^|]+)|([^|]+)}",
        function(numberString, space, _, nominativ, genetiv, plural)
            local number = tonumber(numberString)
            return number .. space .. DeclensionWord(number, nominativ, genetiv, plural)
        end)

    return result
end

function internal.NormalizePersonalizedString(text)
    local playerName = UnitName("player")
    if (playerName) then
        text = string.gsub(text, playerName, function()
            return "{name}"
        end)
    end
    return text
end

function internal.ReconstructPersonalizedString(text)
    local playerName = UnitName("player")
    if (playerName) then
        text = string.gsub(text, "{name}", function()
            return playerName
        end)
    end
    return text
end
