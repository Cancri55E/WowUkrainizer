local _, ns = ...;

local utf8sub, utf8len = string.utf8sub, string.utf8len

local StartsWith = ns.StringExtensions.StartsWith
local GetUnitNameOrDefault = ns.DbContext.Units.GetUnitNameOrDefault
local GetUnitSubnameOrDefault = ns.DbContext.Units.GetUnitSubnameOrDefault

local eventHandler = ns.EventHandler:new()

local translator = class("NameplateAndUnitFrameTranslator", ns.Translators.BaseTranslator)
ns.Translators.NameplateAndUnitFrameTranslator = translator

local function unitNameWrap(self, unitNameFunc)
    return function(unitName)
        local enText = unitNameFunc(unitName)
        if (not self:IsEnabled()) then return enText end
        return GetUnitNameOrDefault(enText)
    end
end

local function nameTagWrap(self, nameFunc)
    return function(u, r)
        local enText = nameFunc(u, r)
        if (not self:IsEnabled()) then return enText end
        return GetUnitNameOrDefault(enText)
    end
end

local function nameLastTagHook(elvUI)
    return function(unit)
        local name = elvUI.TagFunctions.UnitName(unit)
        if name and strfind(name, '%s') then
            name = strmatch(name, '([%S]+)$')
        end
        return name
    end
end

local function nameFormatTagHook(elvUI, length)
    return function(unit)
        local name = elvUI.TagFunctions.UnitName(unit)
        if name then
            return elvUI:ShortenString(name, length)
        end
    end
end

local function nameAbbrevTagHook(elvUI)
    return function(unit)
        local name = elvUI.TagFunctions.UnitName(unit)
        if name and strfind(name, '%s') then
            name = elvUI.TagFunctions.Abbrev(name)
        end
        return name
    end
end

local function nameWithHealthTagHook(elvUI, tags)
    return function(unit, _, args)
        local name = elvUI.TagFunctions.UnitName(unit)
        if not name then return '' end

        local min, max, bco, fco = UnitHealth(unit), UnitHealthMax(unit), strsplit(':', args or '')
        local to = ceil(utf8len(name) * (min / max))

        local fill = elvUI.TagFunctions.NameHealthColor(tags, fco, unit, '|cFFff3333')
        local base = elvUI.TagFunctions.NameHealthColor(tags, bco, unit, '|cFFffffff')

        return to > 0 and (base .. utf8sub(name, 0, to) .. fill .. utf8sub(name, to + 1, -1)) or fill .. name
    end
end

local function nameStatusFormatTagHook(elvUI, elvUI_Data, length)
    return function(unit)
        local status = UnitIsDead(unit) and elvUI_Data["Dead"] or UnitIsGhost(unit) and elvUI_Data["Ghost"]
            or not UnitIsConnected(unit) and elvUI_Data["Offline"]
        local name = elvUI.TagFunctions.UnitName(unit)
        if status then
            return status
        elseif name then
            return elvUI:ShortenString(name, length)
        end
    end
end

local function targetTagHook(elvUI)
    return function(unit)
        local targetName = elvUI.TagFunctions.UnitName(unit .. 'target')
        if targetName then
            return targetName
        end
    end
end

local function nameAbbrevFormatTagHook(elvUI, length)
    return function(unit)
        local name = elvUI.TagFunctions.UnitName(unit)
        if name and strfind(name, '%s') then
            name = elvUI.TagFunctions.Abbrev(name)
        end

        if name then
            return elvUI:ShortenString(name, length)
        end
    end
end

local function targetFormatTagHook(elvUI, length)
    return function(unit)
        local targetName = UnitName(unit .. 'target')
        if targetName then
            return elvUI:ShortenString(targetName, length)
        end
    end
end

local function healthDeficitPercentNameTagHook(tags, textFormat)
    return function(unit)
        local cur, max = UnitHealth(unit), UnitHealthMax(unit)
        local deficit = max - cur

        if deficit > 0 and cur > 0 then
            return tags.Methods['health:deficit-percent:nostatus'](unit)
        else
            return tags.Methods[format('name:%s', textFormat)](unit)
        end
    end
end

local function translateUIControlWrapper(control)
    if (not control) then return end
    if (not control.GetText or not control.SetText) then return end

    control:SetText(GetUnitNameOrDefault(control:GetText()))
end

function translator:initialize()
    ns.Translators.BaseTranslator.initialize(self)

    hooksecurefunc("CompactUnitFrame_UpdateName", function(control)
        if (not self:IsEnabled()) then return end
        if (not ShouldShowName(control)) then return end

        local unitID = control.displayedUnit

        if (not StartsWith(control.displayedUnit, "nameplate")) then return end

        if (UnitIsPlayer(unitID)) then return end

        local reaction = UnitReaction(unitID, "player")

        local isEnemy = reaction and reaction <= 2

        local inInstance, instanceType = IsInInstance()

        if (inInstance and (instanceType == "raid" or instanceType == "party") and not isEnemy) then return end

        translateUIControlWrapper(control.name)
    end)

    if (_G["Plater"]) then
        hooksecurefunc(_G["Plater"], "UpdateUnitName", function(plateFrame)
            translateUIControlWrapper(plateFrame.CurrentUnitNameString)
        end)

        hooksecurefunc(_G["Plater"], "UpdatePlateText", function(plateFrame)
            if (plateFrame.ActorTitleSpecial:IsVisible()) then
                if (not plateFrame.ActorTitleSpecial.GetText or not plateFrame.ActorTitleSpecial.SetText) then return end
                local titleText = plateFrame.ActorTitleSpecial:GetText():match("<(.-)>")
                plateFrame.ActorTitleSpecial:SetText("<" .. GetUnitSubnameOrDefault(titleText, UnitSex("target")) .. ">")
            end
        end)
    end

    if (_G["ElvUI"]) then
        local elvUI = _G["ElvUI"][1]
        local data = _G["ElvUI"][2]

        if (elvUI.private.nameplates and elvUI.private.nameplates.enable == true) then
            elvUI.TagFunctions.UnitName = unitNameWrap(self, elvUI.TagFunctions.UnitName)

            local uf = _G["ElvUF"]
            if (uf) then
                uf.Tags.Methods["name"] = nameTagWrap(self, uf.Tags.Methods["name"])
                uf.Tags.Methods['name:last'] = nameLastTagHook(elvUI)
                uf.Tags.Methods['name:abbrev'] = nameAbbrevTagHook(elvUI)
                uf.Tags.Methods['name:health'] = nameWithHealthTagHook(elvUI, uf.Tags)
                uf.Tags.Methods['target'] = targetTagHook(elvUI)

                for textFormat, length in pairs({ veryshort = 5, short = 10, medium = 15, long = 20 }) do
                    uf.Tags.Methods[format('target:%s', textFormat)] = targetFormatTagHook(elvUI, length)
                    uf.Tags.Methods[format('name:abbrev:%s', textFormat)] = nameAbbrevFormatTagHook(elvUI, length)
                    uf.Tags.Methods[format('name:%s', textFormat)] = nameFormatTagHook(elvUI, length)
                    uf.Tags.Methods[format('name:%s:status', textFormat)] = nameStatusFormatTagHook(elvUI, data, length)
                    uf.Tags.Methods[format('health:deficit-percent:name-%s', textFormat)] =
                        healthDeficitPercentNameTagHook(uf.Tags, textFormat)
                end
            end
        end
    end

    eventHandler:Register(function()
        if (not self:IsEnabled()) then return end
        translateUIControlWrapper(TargetFrame.name)
    end, "PLAYER_TARGET_CHANGED", "UNIT_NAME_UPDATE", "INSTANCE_ENCOUNTER_ENGAGE_UNIT")
end
