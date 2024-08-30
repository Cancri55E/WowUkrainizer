--- @class WowUkrainizerInternals
local ns = select(2, ...);

local GetTranslatedUnitName = ns.DbContext.Units.GetTranslatedUnitName
local GetTranslatedQuestTitle = ns.DbContext.Quests.GetTranslatedQuestTitle
local GetTranslatedQuestObjective = ns.DbContext.Quests.GetTranslatedQuestObjective
local GetTranslatedZoneText = ns.DbContext.ZoneTexts.GetTranslatedZoneText
local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString

local SetFontStringText = ns.FontStringUtil.SetText
local GetTranslatedPvpText = ns.ZoneFrameUtil.GetTranslatedPvpText

local MinimapTooltipCache = {}

---@class MinimapFrameTranslator : BaseTranslator
local translator = setmetatable({}, { __index = ns.BaseTranslator })

function translator:IsEnabled()
    return true
end

local function copyTable(originalTable)
    local newTable = {}
    for key, value in pairs(originalTable) do
        if type(value) == "table" then
            newTable[key] = copyTable(value)
        else
            newTable[key] = value
        end
    end
    return newTable
end

local function OnMinimapMouseoverTooltipPostCall(tooltip, tooltipData)
    local function processMinimapTooltip(tooltipLine)
        local result = {}
        local objectives = {}
        local substrings = {}

        for substring in tooltipLine:gmatch("[^\n]+") do
            table.insert(substrings, substring)
        end

        for i = #substrings, 1, -1 do
            local substring = substrings[i]
            if (string.sub(substring, 1, 1) == '-') then
                substring = string.sub(substring, 3)
                if string.sub(substring, -2) == '|r' then
                    substring = string.sub(substring, 1, -3)
                end
                table.insert(objectives, substring)
            elseif (#objectives > 0) then
                local color = nil
                local title = string.gsub(substring,
                    "(.-)%|[cC]([0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])",
                    function(t, c)
                        color = c
                        return t
                    end)
                table.insert(result,
                    { type = 'QUEST', title = title, objectives = copyTable(objectives), obejctiveColor = color })
                objectives = {}
            else
                local title = substring
                local icon = nil
                local color = nil
                title = string.gsub(title, "(%|T.-%|t)", function(i)
                    icon = i
                    return ''
                end)
                title = string.gsub(title,
                    "%|[cC]([0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])(.-)%|[rR]",
                    function(c, t)
                        color = c
                        return t
                    end)
                table.insert(result, { type = 'NPC_OR_OBJECT', title = title, icon = icon, color = color })
            end
        end
        return result
    end

    if (tooltipData) then
        if (#tooltipData.lines > 0) then
            local text = tooltip.TextLeft1:GetText()
            if (not text) then return end

            local hash = ns.StringUtil.GetHash(text)
            if (not MinimapTooltipCache[hash]) then
                local tooltipRows = processMinimapTooltip(text)

                local questTitleToQuestIdCache = nil
                if (tooltipRows) then
                    for i = 1, #tooltipRows, 1 do
                        local data = tooltipRows[i]
                        if (data.type == 'QUEST') then
                            if (not questTitleToQuestIdCache) then
                                questTitleToQuestIdCache = {}
                                for j = 1, C_QuestLog.GetNumQuestLogEntries() do
                                    local questID = C_QuestLog.GetQuestIDForLogIndex(j);
                                    if (questID and questID > 0) then
                                        local questTitle = C_QuestLog.GetTitleForQuestID(questID)
                                        if (questTitle) then questTitleToQuestIdCache[questTitle] = questID end
                                    end
                                end
                            end
                            local questID = questTitleToQuestIdCache[data.title]
                            if (questID) then
                                local translatedTitle = GetTranslatedQuestTitle(questID)
                                if (translatedTitle) then
                                    data.title = translatedTitle
                                end

                                for j = #data.objectives, 1, -1 do
                                    local objective = data.objectives[j]
                                    local translatedObjective = GetTranslatedQuestObjective(questID, objective)
                                    if (translatedObjective) then
                                        data.objectives[j] = translatedObjective
                                    end
                                end
                            end
                        elseif (data.type == 'NPC_OR_OBJECT') then
                            local translatedTitle = GetTranslatedUnitName(data.title)
                            if (translatedTitle == data.title) then
                                -- TODO: Object Name
                            end
                            data.title = translatedTitle
                        end
                    end

                    local translatedTooltip = ''
                    for i = #tooltipRows, 1, -1 do
                        local data = tooltipRows[i]
                        if (data.icon) then
                            translatedTooltip = translatedTooltip .. data.icon
                        end
                        if (data.color) then
                            translatedTooltip = translatedTooltip .. "|c" .. data.color .. data.title .. "|r"
                        else
                            translatedTooltip = translatedTooltip .. data.title
                        end
                        if (data.objectives) then
                            if (data.obejctiveColor) then
                                translatedTooltip = translatedTooltip .. "|c" .. data.obejctiveColor
                            end
                            for j = #data.objectives, 1, -1 do
                                local objective = data.objectives[j]
                                translatedTooltip = translatedTooltip .. "\n- " .. objective
                            end
                            translatedTooltip = translatedTooltip .. "|r"
                        end
                        translatedTooltip = translatedTooltip .. "\n"
                    end

                    MinimapTooltipCache[hash] = translatedTooltip
                end
            end

            _G["GameTooltipTextLeft1"]:SetText(MinimapTooltipCache[hash])
            GameTooltip:Show()
        end
    end
end

local function OnMinimapUpdate()
    SetFontStringText(MinimapZoneText, GetTranslatedZoneText(GetMinimapZoneText()))
end

local function OnMinimapSetTooltip(pvpType, factionName, worldMap)
    local translatedPvpText = GetTranslatedPvpText(pvpType, factionName)
    local zoneName = GetZoneText();
    local subzoneName = GetSubZoneText();

    local i = 1
    _G["GameTooltipTextLeft" .. i]:SetText(GetTranslatedZoneText(_G["GameTooltipTextLeft" .. i]:GetText()))

    if (subzoneName ~= zoneName) then
        i = i + 1
        if (_G["GameTooltipTextLeft" .. i]) then
            _G["GameTooltipTextLeft" .. i]:SetText(GetTranslatedZoneText(_G["GameTooltipTextLeft" .. i]:GetText()))
        end
    end

    if (translatedPvpText) then
        i = i + 1
        if (_G["GameTooltipTextLeft" .. i]) then
            _G["GameTooltipTextLeft" .. i]:SetText(translatedPvpText)
        end
    end

    if (worldMap) then
        i = i + 1
        if (_G["GameTooltipTextLeft" .. i]) then
            _G["GameTooltipTextLeft" .. i]:SetText(MicroButtonTooltipText(GetTranslatedGlobalString(WORLDMAP_BUTTON), "TOGGLEWORLDMAP"))
        end
    end
end

local function OnZoneTextButtonEnter()
    local pvpType, _, factionName = C_PvP.GetZonePVPInfo();
    OnMinimapSetTooltip(pvpType, factionName, true)
end

function translator:Init()
    if (WOW_UKRAINIZER_TRANSLATE_ZONE_TEXTS_OPTION) then
        hooksecurefunc("Minimap_Update", OnMinimapUpdate)
        hooksecurefunc("Minimap_SetTooltip", OnMinimapSetTooltip)

        MinimapCluster.ZoneTextButton:HookScript("OnEnter", OnZoneTextButtonEnter)

        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.MinimapMouseover, OnMinimapMouseoverTooltipPostCall)
    end
end

ns.TranslationsManager:AddTranslator(translator)
