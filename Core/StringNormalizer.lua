--- @class WowUkrainizerInternals
local ns = select(2, ...);

local Uft8Upper = ns.StringUtil.Uft8Upper
local ReplaceWholeWordNocase = ns.StringUtil.ReplaceWholeWordNocase

local ExtractNumericValues = ns.StringUtil.ExtractNumericValues
local InsertNumericValues = ns.StringUtil.InsertNumericValues
local DeclensionWord = ns.StringUtil.DeclensionWord

local GetTranslatedClass = ns.DbContext.Player.GetTranslatedClass
local GetTranslatedRace = ns.DbContext.Player.GetTranslatedRace
local GetTranslatedShortRace = ns.DbContext.Player.GetTranslatedShortRace
local GetShortRace = ns.DbContext.Player.GetShortRace

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

--- TODO
--- @param text string The input text.
--- @return string[] @TODO
function internal.EncodeWithBlizzardPlaceholders(text)
    local function generateReplacementCombinations(originalText, replacements)
        local results = {}
        local resultsSet = {}

        local function addUniqueResult(newText)
            if not resultsSet[newText] then
                resultsSet[newText] = true
                table.insert(results, newText)
            end
        end

        local fullReplacementText = originalText
        for _, replacement in ipairs(replacements) do
            fullReplacementText = ReplaceWholeWordNocase(fullReplacementText, replacement.word, replacement.placeholder, replacement.ignoreCase)
        end

        if fullReplacementText == originalText then
            return { originalText }
        end

        addUniqueResult(fullReplacementText)

        for i, replacement in ipairs(replacements) do
            local replacedText = ReplaceWholeWordNocase(originalText, replacement.word, replacement.placeholder, replacement.ignoreCase)

            if replacedText ~= originalText then
                addUniqueResult(replacedText)

                local subReplacements = {}
                for j = i + 1, #replacements do
                    table.insert(subReplacements, replacements[j])
                end

                local subResults = generateReplacementCombinations(replacedText, subReplacements)
                for _, subResult in ipairs(subResults) do
                    addUniqueResult(subResult)
                end
            end
        end

        addUniqueResult(originalText)
        return results
    end

    local replacements = {
        { word = ns.PlayerInfo.Name,               placeholder = "$n",  ignoreCase = false },
        { word = ns.PlayerInfo.Race,               placeholder = "$r",  ignoreCase = true },
        { word = GetShortRace(ns.PlayerInfo.Race), placeholder = "$rs", ignoreCase = true },
        { word = ns.PlayerInfo.Class,              placeholder = "$c",  ignoreCase = true }
    }

    return generateReplacementCombinations(text, replacements)
end

--- TODO
--- @param text string The input text.
--- @return string? @TODO
function internal.DecodeBlizzardPlaceholders(text)
    local function getCaseLetterIndex(caseLetter)
        local case = 1
        if caseLetter and caseLetter ~= "" then
            if (caseLetter == 'н' or caseLetter == 'Н') then
                case = 1
            elseif (caseLetter == 'р' or caseLetter == 'Р') then
                case = 2
            elseif (caseLetter == 'д' or caseLetter == 'Д') then
                case = 3
            elseif (caseLetter == 'з' or caseLetter == 'З') then
                case = 4
            elseif (caseLetter == 'о' or caseLetter == 'О') then
                case = 5
            elseif (caseLetter == 'м' or caseLetter == 'М') then
                case = 6
            elseif (caseLetter == 'к' or caseLetter == 'К') then
                case = 7
            end
        end
        return case
    end

    if text == nil or text == "" then return text end

    local playerData = ns.PlayerInfo

    text = string.gsub(text, "%$[nN]", function(_)
        return playerData.Name
    end)

    text = string.gsub(text, "%$[pP]", function(_)
        return playerData.Name
    end)

    text = string.gsub(text, "%$[rR]:?([^\128-\191]?[\128-\191]?)", function(marker, caseLetter)
        local translatedStr = GetTranslatedRace(playerData.Race, getCaseLetterIndex(caseLetter), playerData.Gender)
        if (marker == "$R") then return Uft8Upper(translatedStr) end
        return translatedStr
    end)

    text = string.gsub(text, "%$[rsRS]:?([^\128-\191]?[\128-\191]?)", function(marker, caseLetter)
        local translatedStr = GetTranslatedShortRace(playerData.Race, getCaseLetterIndex(caseLetter), playerData.Gender)
        if (marker == "$RS") then return Uft8Upper(translatedStr) end
        return translatedStr
    end)

    text = string.gsub(text, "(%$[cC]):?([^\128-\191]?[\128-\191]?)", function(marker, caseLetter)
        local translatedStr = GetTranslatedClass(playerData.Class, getCaseLetterIndex(caseLetter), playerData.Gender)
        if (marker == "$C") then return Uft8Upper(translatedStr) end
        return translatedStr
    end)

    text = string.gsub(text, "{sex|(.-)|(.-)}", function(male, female)
        if (playerData.Gender == 3) then
            return female
        else
            return male
        end
    end)

    return text
end
