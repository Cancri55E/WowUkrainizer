--- @class WowUkrainizerInternals
local ns = select(2, ...);

local ExtractFromText = ns.StringUtil.ExtractFromText
local GetTranslatedZoneText = ns.DbContext.ZoneTexts.GetTranslatedZoneText
local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString

---@class UIErrorsTranslator : BaseTranslator
local translator = setmetatable({}, { __index = ns.BaseTranslator })

function translator:IsEnabled()
    return true
end

local ZoneMessages = {
    [LE_GAME_ERR_ZONE_EXPLORED] = {},
    [LE_GAME_ERR_ZONE_EXPLORED_XP] = {},
    [LE_GAME_ERR_NEWTAXIPATH] = {},
}

local function ProcessZoneMessages(messageType, message)
    if (not ZoneMessages[messageType]) then return end

    if (messageType == LE_GAME_ERR_ZONE_EXPLORED) then
        local zoneName = ExtractFromText(ERR_ZONE_EXPLORED, message)
        local translatedText = string.format(GetTranslatedGlobalString(ERR_ZONE_EXPLORED), GetTranslatedZoneText(zoneName))
        table.insert(ZoneMessages[LE_GAME_ERR_ZONE_EXPLORED], { text = message, translatedText = translatedText })
    elseif (messageType == LE_GAME_ERR_ZONE_EXPLORED_XP) then
        local zoneName, exp = ExtractFromText(ERR_ZONE_EXPLORED_XP, message)
        exp = exp:gsub("[,.]", "")
        local translatedText = string.format(GetTranslatedGlobalString(ERR_ZONE_EXPLORED_XP), GetTranslatedZoneText(zoneName), exp)
        table.insert(ZoneMessages[LE_GAME_ERR_ZONE_EXPLORED_XP], { text = message, translatedText = translatedText })
    elseif (messageType == LE_GAME_ERR_NEWTAXIPATH) then
        table.insert(ZoneMessages[LE_GAME_ERR_NEWTAXIPATH], { text = message, translatedText = GetTranslatedGlobalString(ERR_NEWTAXIPATH) })
    end
end

local function ApplyTranslation(messageCache)
    for messageType, messages in pairs(messageCache) do
        if (UIErrorsFrame:HasMessageByID(messageType)) then
            local fontString = UIErrorsFrame:GetFontStringByID(messageType)
            if (fontString) then
                for i = 1, #messages, 1 do
                    if (messages[i] and fontString:GetText() == messages[i].text) then
                        fontString:SetText(messages[i].translatedText)
                        table.remove(messages, i)
                    end
                end
            end
        end
    end
end

local function OnMessageAdded(_, message, _, _, _, _, messageType)
    if (ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_ZONE_TEXTS_OPTION)) then
        ProcessZoneMessages(messageType, message)
    end
end

local function OnUpdated()
    if (ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_ZONE_TEXTS_OPTION)) then
        ApplyTranslation(ZoneMessages)
    end
end

function translator:Init()
    hooksecurefunc(UIErrorsFrame, "AddMessage", OnMessageAdded)
    UIErrorsFrame:HookScript("OnUpdate", OnUpdated)
    hooksecurefunc(UIErrorsFrame, "SetScript", function(_, _, value)
        if (not value) then UIErrorsFrame:HookScript("OnUpdate", OnUpdated) end
    end)
end

ns.TranslationsManager:AddTranslator(translator)
