--- @type string, WowUkrainizerInternals
local _, ns = ...;

--- Utility module providing string manipulation functions for various purposes.
---@class StringUtil
local internal = {}
ns.StringUtil = internal

--- Trim leading and trailing whitespaces from a string.
---@param str string @The input string.
---@return string @The trimmed string.
function internal.Trim(str)
    return str:match("^%s*(.-)%s*$")
end

--- Get a hash value for a string.
---@param str string @The input string.
---@return number @The hash value.
function internal.GetHash(str)
    if (str == nil or type(str) ~= "string" or str == "") then
        return -1
    end

    str = internal.Trim(str) -- Trim the input string

    str = str:gsub("%s+", "_"):gsub("[\n\r’`.,]", ""):lower()

    local counter = 1
    local len = string.len(str)
    for i = 1, len, 3 do
        counter = math.fmod(counter * 8161, 4294967279) + -- 2^32 - 17: Prime!
            (string.byte(str, i) * 16776193) +
            ((string.byte(str, i + 1) or (len - i + 256)) * 8372226) +
            ((string.byte(str, i + 2) or (len - i + 256)) * 3932164)
    end
    return math.fmod(counter, 4294967291) -- 2^32 - 5: Prime (and different from the prime in the loop)
end

--- Check if a string ends with a specified suffix.
---@param str string @The input string.
---@param suffix string @The suffix to check.
---@return boolean @True if the string ends with the specified suffix, false otherwise.
function internal.EndsWith(str, suffix)
    if (not str) then return false end
    if #str < #suffix then
        return false
    else
        str = str:lower()
        suffix = suffix:lower()
        return str:sub(- #suffix) == suffix
    end
end

--- Check if a string starts with a specified prefix.
---@param str string @The input string.
---@param prefix string @The prefix to check.
---@return boolean @True if the string starts with the specified prefix, false otherwise.
function internal.StartsWith(str, prefix)
    if (not str) then return false end
    if #str < #prefix then
        return false
    else
        str = str:lower()
        prefix = prefix:lower()
        return str:sub(1, #prefix) == prefix
    end
end

--- Split a string into a table of substrings using a delimiter.
---@param input string @The input string.
---@param delimiter string @The delimiter to use for splitting.
---@return table @Table of substrings.
function internal.Split(input, delimiter)
    local items = {}
    local pattern = "([^" .. delimiter .. "]+)"
    for item in input:gmatch(pattern) do
        table.insert(items, item)
    end
    return items
end

--- Compare two strings for equality with optional case-insensitivity.
---@param str1 string @The first string.
---@param str2 string @The second string.
---@param ignoreCase boolean @True to ignore case, false otherwise.
---@return boolean @True if the strings are equal, false otherwise.
function internal.StringsAreEqual(str1, str2, ignoreCase)
    if str1 ~= nil and str2 ~= nil then
        if ignoreCase then
            str1 = string.lower(str1)
            str2 = string.lower(str2)
        end
        return str1 == str2
    end
    return false
end

--- Choose the correct word form based on a numeric value.
---@param number number @The numeric value.
---@param singular string @The singular form.
---@param plural string @The plural form.
---@param genitivePlural string @The genitive plural form.
---@return string @The chosen word form.
function internal.DeclensionWord(number, singular, plural, genitivePlural)
    local lastDigit = number % 10
    local lastTwoDigits = number % 100

    if lastDigit == 1 and lastTwoDigits ~= 11 then
        return singular
    elseif (lastDigit >= 2 and lastDigit <= 4) and not (lastTwoDigits >= 12 and lastTwoDigits <= 14) then
        return plural
    else
        return genitivePlural
    end
end

--- Extract numeric values from a string and replace them with placeholders.
---@param str string @The input string.
---@return string @The modified string.
---@return table @Table of extracted numeric values.
function internal.ExtractNumericValues(str)
    local numbers = {}
    str = str:gsub("(%d[%d,]*%.?%d*)", function(num)
        if (num:sub(-1) == ",") then
            table.insert(numbers, num:sub(1, -2))
            return string.format("{%d},", #numbers)
        elseif (num:sub(-1) == ".") then
            table.insert(numbers, num:sub(1, -2))
            return string.format("{%d}.", #numbers)
        else
            table.insert(numbers, num)
            return string.format("{%d}", #numbers)
        end
    end)

    return str, numbers
end

--- Replace numeric placeholders in a string with corresponding values.
---@param str string @The input string.
---@param numericValues table @Table of numeric values.
---@return string @The modified string.
function internal.InsertNumericValues(str, numericValues)
    local result = str:gsub("{(%d+)}", function(index)
        return numericValues[tonumber(index)]
    end)
    return result
end
