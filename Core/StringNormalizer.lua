--- @class WowUkrainizerInternals
local ns = select(2, ...);

local ExtractNumericValues = ns.StringUtil.ExtractNumericValues
local InsertNumericValues = ns.StringUtil.InsertNumericValues
local DeclensionWord = ns.StringUtil.DeclensionWord
local Uft8Upper = ns.StringUtil.Uft8Upper

--- Utility class providing string normalization functions for addon.
--- @class StringNormalizer
local internal = {}
ns.StringNormalizer = internal

--- Normalize a string and extract numeric values.
--- @param text string? The input text.
--- @return string? normalizedText @The normalized text.
--- @return table extractedNumerics @The extracted numeric values.
function internal.NormalizeStringAndExtractNumerics(text)
    if text == nil or text == "" then
        return text, {}
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

    local unclosedColors = {}
    text = string.gsub(text,
        "(%|[cC][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])",
        function(color)
            table.insert(unclosedColors, color)
            return string.format("color:%s", string.char(#unclosedColors + 64))
        end)

    local numbers = {}
    text, numbers = ExtractNumericValues(text)

    for i = 1, #icons do
        text = text:gsub(string.format("{icon:%s}", string.char(i + 64)), "|T" .. icons[i] .. "|t")
    end

    for i = 1, #colors do
        text = text:gsub(string.format("{color:%s", string.char(i + 64)), "{" .. colors[i])
    end

    for i = 1, #unclosedColors do
        text = text:gsub(string.format("color:%s", string.char(i + 64)), unclosedColors[i])
    end

    return text, numbers
end

--- Reconstruct a string with numeric values.
--- @param str string The input string.
--- @param numbers table The numeric values.
--- @return string @The reconstructed string.
function internal.ReconstructStringWithNumerics(str, numbers)
    local result = InsertNumericValues(str, numbers)
    result = result:gsub("(%d+)( *){(declension)|([^}|]+)|([^}|]+)|([^}|]+)}",
        function(numberString, space, _, nominativ, genetiv, plural)
            local number = tonumber(numberString)
            if (number) then
                return number .. space .. DeclensionWord(number, nominativ, genetiv, plural)
            end
        end)
    result = result:gsub("{(%x+)|([^}]+)}", "|c%1%2|r")
    return result
end

--- Normalize a personalized string by replacing player name with a placeholder.
--- @param text string The input text.
--- @return string @The normalized text.
function internal.NormalizePersonalizedString(text)
    local playerName = ns.PlayerInfo.Name
    if (playerName) then
        text = string.gsub(text, playerName, function()
            return "$n"
        end)
    end
    local playerRace = ns.PlayerInfo.Race
    if (playerRace) then
        text = string.gsub(text, playerRace, function()
            if (string.match(string.sub(playerRace, 1, 1), "%u")) then
                return "$R"
            else
                return "$r"
            end
        end)
    end
    return text
end

--- Reconstruct a personalized string by replacing the placeholder with the player name.
--- @param text string The input text.
--- @return string @The reconstructed text.
function internal.ReconstructPersonalizedString(text)
    local playerName = ns.PlayerInfo.Name
    if (playerName) then
        text = string.gsub(text, "$n", function()
            return playerName
        end)
    end

    return text
end

-- function repository._normalizeQuestString(text)
--     if text == nil or text == "" then return text end

--     local playerData = ns.PlayerInfo

--     text = string.gsub(text, "%$[nN]", function(_)
--         return playerData.Name
--     end)

--     text = string.gsub(text, "%$[pP]", function(_)
--         return playerData.Name
--     end)

--     text = string.gsub(text, "%$[rR]", function(marker) -- TODO: case like class
--         if (marker == "$R") then return Uft8Upper(playerData.Race) end
--         return playerData.Race
--     end)

--     text = string.gsub(text, "(%$[cC]):([^\128-\191][\128-\191])", function(marker, caseLetter)
--         local case = 1
--         if (caseLetter == 'н' or caseLetter == 'Н') then
--             case = 1
--         elseif (caseLetter == 'р' or caseLetter == 'Р') then
--             case = 2
--         elseif (caseLetter == 'д' or caseLetter == 'Д') then
--             case = 3
--         elseif (caseLetter == 'з' or caseLetter == 'З') then
--             case = 4
--         elseif (caseLetter == 'о' or caseLetter == 'О') then
--             case = 5
--         elseif (caseLetter == 'м' or caseLetter == 'М') then
--             case = 6
--         elseif (caseLetter == 'к' or caseLetter == 'К') then
--             case = 7
--         end

--         local classStr = dbContext.Player.GetTranslatedClass(playerData.Class, case, playerData.Gender)

--         if (marker == "$C") then return Uft8Upper(classStr) end
--         return classStr
--     end)

--     text = string.gsub(text, "%$[cC]", function(marker)
--         local classStr = dbContext.Player.GetTranslatedClass(playerData.Class, 1, playerData.Gender)

--         if (marker == "$C") then return Uft8Upper(classStr) end
--         return classStr
--     end)

--     text = string.gsub(text, "{sex|(.-)|(.-)}", function(male, female)
--         if (playerData.Gender == 3) then
--             return female
--         else
--             return male
--         end
--     end)

--     return text
-- end
