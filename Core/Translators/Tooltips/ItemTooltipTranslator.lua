--- @class WowUkrainizerInternals
local ns = select(2, ...);

local _G = _G
local NullOrEmpty = ns.StringUtil.NullOrEmpty
local CreatePatternFromFormatString = ns.StringUtil.CreatePatternFromFormatString
local UpdateTextWithTranslation = ns.FontStringUtil.UpdateTextWithTranslation
local GetItemTranslation = ns.DbContext.Items.GetItemTranslation
local GetTranslatedItemAttribute = ns.DbContext.Items.GetTranslatedItemAttribute
local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString
local GetTranslatedClass = ns.DbContext.Player.GetTranslatedClass

---@class ItemTooltipTranslator : BaseTooltipTranslator
local translator = setmetatable({ tooltipDataType = Enum.TooltipDataType.Item }, { __index = ns.BaseTooltipTranslator })

local CATEGORY = {
    ATTRIBUTES = "Attributes",
    ITEM_LEVEL = "Item Level",
    ARMOR = "Armor",
    DESCRIPTION = "Description",
    DURABILITY = "Durability",
    MADE_BY = "Made By",
    DPS = "DPS",
    WEAPON_DAMAGE = "Weapon Damage",
    WEAPON_SPEED = "Weapon Speed",
    PROFESSION_CRAFTING_QUALITY = "Profession Crafting Quality",
    EQUIP_SLOT = "Equip Slot",
    RESTRICTED_LEVEL = "Restricted Level",
    ITEM_BINDING = "Item Binding",
    EQUIPMENT_SETS = "Equipment Sets",
    UNCLASSIFIED = "Unclassified",
    UPGRADE_LEVEL = "Upgrade Level",
    CLASSES = "Classes",
    COOLDOWN_REMAINING = "Cooldown remaining",
    ITEM_PET_KNOWN = "Collected",
    HEIRLOOM_UPGRADE = "Heirloom Upgrade Level",
}

-- A factory to create simple data handlers
local function CreateSimpleHandler(category, fieldNames, right)
    return function(data, index)
        local result = { index = index }
        if (right) then result["right"] = true end
        for i, name in ipairs(fieldNames) do
            result[name] = data[i]
        end
        return { category }, result
    end
end

local HandleItemLevel = CreateSimpleHandler(CATEGORY.ITEM_LEVEL, { "value" })
local HandleArmor = CreateSimpleHandler(CATEGORY.ARMOR, { "value" })
local HandleDescription = CreateSimpleHandler(CATEGORY.DESCRIPTION, { "value" })
local HandleDurability = CreateSimpleHandler(CATEGORY.DURABILITY, { "min", "max" })
local HandleMadeBy = CreateSimpleHandler(CATEGORY.MADE_BY, { "value" })
local HandleDps = CreateSimpleHandler(CATEGORY.DPS, { "value" })
local HandleWeaponDamage = CreateSimpleHandler(CATEGORY.WEAPON_DAMAGE, { "min", "max" })
local HandleWeaponSpeed = CreateSimpleHandler(CATEGORY.WEAPON_SPEED, { "value" }, true)
local HandleEquipmentSets = CreateSimpleHandler(CATEGORY.WEAPON_SPEED, { "value" })
local HandleCollected = CreateSimpleHandler(CATEGORY.ITEM_PET_KNOWN, { "min", "max" })
local HandleCooldownRemaining = CreateSimpleHandler(CATEGORY.COOLDOWN_REMAINING, { "value" })
local HandleHeilroomUpgrade = CreateSimpleHandler(CATEGORY.HEIRLOOM_UPGRADE, { "min", "max" })

local function HandleAttributes(data, index)
    if (#data == 3) then
        return { CATEGORY.ATTRIBUTES }, { min = data[1], max = data[2], name = data[3], index = index }
    else
        return { CATEGORY.ATTRIBUTES }, { value = data[1], name = data[2], index = index }
    end
end

local function HandleUpgradeLevel(data, index)
    if (#data == 5) then
        return { CATEGORY.UPGRADE_LEVEL }, { min = data[4], max = data[5], name = data[3], prefix = data[2], color = data[1], index = index }
    elseif (#data == 3) then
        return { CATEGORY.UPGRADE_LEVEL }, { min = data[2], max = data[3], name = data[1], index = index }
    else
        return { CATEGORY.UPGRADE_LEVEL }, { min = data[1], max = data[2], index = index }
    end
end

local function HandleClasses(data, index)
    local function splitClasses(names_str)
        local classes = {}
        for class in names_str:gmatch("([^,]+)") do
            class = class:match("^%s*(.-)%s*$")
            table.insert(classes, GetTranslatedClass(class, 1))
        end
        return classes
    end
    return { CATEGORY.CLASSES }, { value = table.concat(splitClasses(data[1]), ", "), index = index }
end

local patterns = {
    { pattern = "^%+([%d,.]+)%s(.*)$",                func = HandleAttributes },
    { pattern = "^%+([%d,.]+)-([%d,.]+)%s(.*)$",      func = HandleAttributes },
    { pattern = "^([%d,.]+)%sArmor$",                 func = HandleArmor },
    { pattern = '^"(.*)"$',                           func = HandleDescription },
    { pattern = '^Durability (%d+) / (%d+)$',         func = HandleDurability },
    { pattern = '^|cff00ff00<Made by (.*)>|r$',       func = HandleMadeBy },
    { pattern = '^%((.*) damage per second%)$',       func = HandleDps },
    { pattern = '^([%d,]+)%s*-%s*([%d,]+)%s*Damage$', func = HandleWeaponDamage },
    { pattern = '^Speed ([%d,.]+)$',                  func = HandleWeaponSpeed },
    { pattern = '^Item Level (%d+)$',                 func = HandleItemLevel },
    { pattern = '^Equipment Sets: (.*)|r$',           func = HandleEquipmentSets },
    { pattern = '^Upgrade Level: (.*) (%d)/(%d)$',    func = HandleUpgradeLevel },
    { pattern = '^Upgrade Level: (%d)/(%d)$',         func = HandleUpgradeLevel },
    {
        pattern = '^|c(........)(.*)%s*|n%s*Upgrade Level: (.*) (%d)/(%d)|r$',
        func = HandleUpgradeLevel
    },
    { pattern = COOLDOWN_REMAINING .. "(.*)", func = HandleCooldownRemaining },
    { pattern = '^Classes:%s*(.+)$',          func = HandleClasses },
    {
        pattern = CreatePatternFromFormatString(ITEM_PET_KNOWN, {
            ["%%d"] = "(%%d+)"
        }),
        func = HandleCollected
    },
    {
        pattern = "^" .. CreatePatternFromFormatString(HEIRLOOM_UPGRADE_TOOLTIP_FORMAT, {
            ["%%d"] = "(%%d+)"
        }) .. "$",
        func = HandleHeilroomUpgrade
    },
}

local compareItemPatterns = {
    {
        pattern = "^|c(%%x%%x%%x%%x%%x%%x%%x%%x)([-+][%d,.]*)%s*|r%s*(.*)$",
        func = function(data, tooltipLine)
            if (data[3] == STAT_STURDINESS) then
                tooltipLine:SetText("|c" .. data[1] .. data[2] .. "|r " .. GetTranslatedGlobalString(STAT_STURDINESS))
            else
                tooltipLine:SetText("|c" .. data[1] .. data[2] .. "|r " .. GetTranslatedItemAttribute(data[3]))
            end
        end
    },
    {
        pattern = "^" .. CreatePatternFromFormatString(ITEM_DELTA_DUAL_WIELD_COMPARISON_MAINHAND_DESCRIPTION, {
            ["|c%%s%%s|r"] = "|c(%%x%%x%%x%%x%%x%%x%%x%%x)(.*)|r"
        }) .. "$",
        func = function(data, tooltipLine)
            tooltipLine:SetText(GetTranslatedGlobalString(ITEM_DELTA_DUAL_WIELD_COMPARISON_MAINHAND_DESCRIPTION):format(data[1], data[2]))
        end
    },
    {
        pattern = "^" .. CreatePatternFromFormatString(ITEM_DELTA_DUAL_WIELD_COMPARISON_OFFHAND_DESCRIPTION, {
            ["|c%%s%%s|r"] = "|c(%%x%%x%%x%%x%%x%%x%%x%%x)(.*)|r"
        }) .. "$",
        func = function(data, tooltipLine)
            tooltipLine:SetText(GetTranslatedGlobalString(ITEM_DELTA_DUAL_WIELD_COMPARISON_OFFHAND_DESCRIPTION):format(data[1], data[2]))
        end
    },
    {
        pattern = "^" .. CreatePatternFromFormatString(ITEM_COMPARISON_SWAP_ITEM_MAINHAND_DESCRIPTION, {
            ["%%s"] = "(.*)"
        }) .. "$",
        func = function(data, tooltipLine)
            tooltipLine:SetText(GetTranslatedGlobalString(ITEM_COMPARISON_SWAP_ITEM_MAINHAND_DESCRIPTION):format(data[1]))
        end
    },
    {
        pattern = "^" .. CreatePatternFromFormatString(ITEM_COMPARISON_SWAP_ITEM_OFFHAND_DESCRIPTION, {
            ["%%s"] = "(.*)"
        }) .. "$",
        func = function(data, tooltipLine)
            tooltipLine:SetText(GetTranslatedGlobalString(ITEM_COMPARISON_SWAP_ITEM_OFFHAND_DESCRIPTION):format(data[1]))
        end
    },
}

function translator:ParseTooltip(tooltip, tooltipData)
    local function parseUndefinedLineTypeText(text, index, isRightText)
        for _, patternInfo in ipairs(patterns) do
            local matches = { string.match(text, patternInfo.pattern) }
            if #matches > 0 then
                local categories, textData = patternInfo.func(matches, index)
                if (isRightText) then
                    textData.right = true
                end
                return categories, textData
            end
        end
    end

    local function saveUndefinedLineTypeText(result, text, index, isRightText)
        local categories, leftTextData = parseUndefinedLineTypeText(text, index, isRightText)
        if (categories) then
            local currentCategory = result
            for _, category in ipairs(categories) do
                if not currentCategory[category] then
                    currentCategory[category] = {}
                end
                currentCategory = currentCategory[category]
            end
            table.insert(currentCategory, leftTextData)
        else
            if (not result[CATEGORY.UNCLASSIFIED]) then result[CATEGORY.UNCLASSIFIED] = {} end
            table.insert(result[CATEGORY.UNCLASSIFIED], { value = text, index = index, right = isRightText })
        end
    end

    self._postCallLineCount = tonumber(tooltip:NumLines())
    local tooltipName = tooltip:GetName()

    for i = 1, tooltip:NumLines() do
        self:AddFontStringToIndexLookup(i * 2 - 1, _G[tooltipName .. "TextLeft" .. i])
        self:AddFontStringToIndexLookup(i * 2, _G[tooltipName .. "TextRight" .. i])
    end

    local tooltipLines = tooltipData.lines

    local tooltipInfo = {}
    tooltipInfo.ID = tonumber(tooltipData.id)

    for i = 1, #tooltipLines, 1 do
        local tooltipLine = tooltipLines[i]
        if (tooltipLine.type == Enum.TooltipDataLineType.Blank or tooltipLine.type == Enum.TooltipDataLineType.SellPrice) then
            -- ignore
        elseif (tooltipLine.type == Enum.TooltipDataLineType.ItemName) then
            tooltipInfo.Name = { value = tooltipLine.leftText, index = tooltipLine.lineIndex }
        elseif (tooltipLine.type == Enum.TooltipDataLineType.ItemBinding) then
            tooltipInfo[CATEGORY.ITEM_BINDING] = { value = tooltipLine.leftText, index = tooltipLine.lineIndex }
        elseif (tooltipLine.type == Enum.TooltipDataLineType.ProfessionCraftingQuality) then
            tooltipInfo[CATEGORY.PROFESSION_CRAFTING_QUALITY] = {
                value = string.match(tooltipLine.leftText, "^Quality: (.*)$"),
                index = tooltipLine.lineIndex
            }
        elseif (tooltipLine.type == Enum.TooltipDataLineType.RestrictedLevel) then
            tooltipInfo[CATEGORY.RESTRICTED_LEVEL] = { value = string.match(tooltipLine.leftText, "^Requires Level (%d+)$"), index = tooltipLine.lineIndex }
        elseif (tooltipLine.type == Enum.TooltipDataLineType.EquipSlot) then
            tooltipInfo[CATEGORY.EQUIP_SLOT] = { slot = tooltipLine.leftText, armorType = tooltipLine.rightText, index = tooltipLine.lineIndex }
        else
            if (not NullOrEmpty(tooltipLine.leftText)) then
                saveUndefinedLineTypeText(tooltipInfo, tooltipLine.leftText, tooltipLine.lineIndex, false)
            end
            if (not NullOrEmpty(tooltipLine.rightText)) then
                saveUndefinedLineTypeText(tooltipInfo, tooltipLine.rightText, tooltipLine.lineIndex, true)
            end
        end
    end
    return tooltipInfo
end

function translator:TranslateTooltipInfo(tooltipInfo)
    local function getTooltipIndex(lineIndex, right)
        local tooltipIndex = lineIndex * 2
        if (not right) then
            tooltipIndex = tooltipIndex - 1
        end
        return tooltipIndex
    end

    if (not tooltipInfo.Name) then return end

    local itemTranslation = GetItemTranslation(tooltipInfo.ID)

    local translatedTooltipLines = {}

    if (tooltipInfo[CATEGORY.DESCRIPTION]) then
        local description = tooltipInfo[CATEGORY.DESCRIPTION][1]
        if (itemTranslation and itemTranslation.Description) then
            table.insert(translatedTooltipLines, {
                index = getTooltipIndex(description.index),
                value = "\"" .. itemTranslation.Description .. "\""
            })
        end
    end

    if (tooltipInfo[CATEGORY.ITEM_LEVEL]) then
        local itemLevel = tooltipInfo[CATEGORY.ITEM_LEVEL][1]
        table.insert(translatedTooltipLines, {
            index = getTooltipIndex(itemLevel.index),
            value = GetTranslatedGlobalString(ITEM_LEVEL):format(itemLevel.value)
        })
    end

    if (tooltipInfo[CATEGORY.CLASSES]) then
        local itemLevel = tooltipInfo[CATEGORY.CLASSES][1]
        table.insert(translatedTooltipLines, {
            index = getTooltipIndex(itemLevel.index),
            value = GetTranslatedGlobalString(ITEM_CLASSES_ALLOWED):format(itemLevel.value)
        })
    end

    if (tooltipInfo[CATEGORY.DURABILITY]) then
        local durability = tooltipInfo[CATEGORY.DURABILITY][1]
        table.insert(translatedTooltipLines, {
            index = getTooltipIndex(durability.index),
            value = GetTranslatedGlobalString(DURABILITY_TEMPLATE):format(durability.min, durability.max)
        })
    end

    if (tooltipInfo[CATEGORY.MADE_BY]) then
        local madeBy = tooltipInfo[CATEGORY.MADE_BY][1]
        table.insert(translatedTooltipLines, {
            index = getTooltipIndex(madeBy.index),
            value = GetTranslatedGlobalString(ITEM_CREATED_BY, true):format(madeBy.value)
        })
    end

    if (tooltipInfo[CATEGORY.EQUIPMENT_SETS]) then
        local equipmentSets = tooltipInfo[CATEGORY.EQUIPMENT_SETS][1]
        table.insert(translatedTooltipLines, {
            index = getTooltipIndex(equipmentSets.index),
            value = GetTranslatedGlobalString(EQUIPMENT_SETS, true):format(equipmentSets.value)
        })
    end

    if (tooltipInfo[CATEGORY.PROFESSION_CRAFTING_QUALITY]) then
        local professionCraftingQuality = tooltipInfo[CATEGORY.PROFESSION_CRAFTING_QUALITY]
        -- may be present in the data but not have an index because it is not displayed in the tooltip (for example, for reagents of new professions (> 10.0) in the profession window)
        if (professionCraftingQuality.index) then
            table.insert(translatedTooltipLines, {
                index = getTooltipIndex(professionCraftingQuality.index),
                value = GetTranslatedGlobalString(PROFESSIONS_CRAFTING_QUALITY):format(professionCraftingQuality.value)
            })
        end
    end

    if (tooltipInfo[CATEGORY.RESTRICTED_LEVEL]) then
        local restrictedLevel = tooltipInfo[CATEGORY.RESTRICTED_LEVEL]
        table.insert(translatedTooltipLines, {
            index = getTooltipIndex(restrictedLevel.index),
            value = GetTranslatedGlobalString(ITEM_MIN_LEVEL):format(restrictedLevel.value)
        })
    end

    if (tooltipInfo[CATEGORY.ITEM_BINDING]) then
        local itemBinding = tooltipInfo[CATEGORY.ITEM_BINDING]
        table.insert(translatedTooltipLines, {
            index = getTooltipIndex(itemBinding.index),
            value = GetTranslatedGlobalString(itemBinding.value)
        })
    end

    if (tooltipInfo[CATEGORY.UPGRADE_LEVEL]) then
        local upgradeLevel = tooltipInfo[CATEGORY.UPGRADE_LEVEL][1]

        if (upgradeLevel.prefix) then
            table.insert(translatedTooltipLines, {
                index = getTooltipIndex(upgradeLevel.index),
                value = ("|c%s%s|n" .. GetTranslatedGlobalString(ITEM_UPGRADE_TOOLTIP_FORMAT_STRING) .. "|r"):format(
                    upgradeLevel.color, GetTranslatedGlobalString(upgradeLevel.prefix), GetTranslatedGlobalString(upgradeLevel.name), upgradeLevel.min,
                    upgradeLevel.max)
            })
        elseif (upgradeLevel.name) then
            table.insert(translatedTooltipLines, {
                index = getTooltipIndex(upgradeLevel.index),
                value = GetTranslatedGlobalString(ITEM_UPGRADE_TOOLTIP_FORMAT_STRING):format(
                    GetTranslatedGlobalString(upgradeLevel.name), upgradeLevel.min, upgradeLevel.max)
            })
        else
            table.insert(translatedTooltipLines, {
                index = getTooltipIndex(upgradeLevel.index),
                value = GetTranslatedGlobalString(ITEM_UPGRADE_TOOLTIP_FORMAT):format(upgradeLevel.min, upgradeLevel.max)
            })
        end
    end

    if (tooltipInfo[CATEGORY.ITEM_PET_KNOWN]) then
        local collected = tooltipInfo[CATEGORY.ITEM_PET_KNOWN][1]
        table.insert(translatedTooltipLines, {
            index = getTooltipIndex(collected.index),
            value = GetTranslatedGlobalString(ITEM_PET_KNOWN):format(collected.min, collected.max)
        })
    end

    if (tooltipInfo[CATEGORY.UNCLASSIFIED]) then
        for _, unclassified in ipairs(tooltipInfo[CATEGORY.UNCLASSIFIED]) do
            table.insert(translatedTooltipLines, {
                index = getTooltipIndex(unclassified.index, unclassified.right),
                value = GetTranslatedGlobalString(unclassified.value)
            })
        end
    end

    if (tooltipInfo[CATEGORY.COOLDOWN_REMAINING]) then
        local function translateTime(timeLeft)
            local numbers = {}
            for number in timeLeft:gmatch("(%d+)") do
                table.insert(numbers, tonumber(number))
            end

            if (#numbers == 6) then
                return numbers[1] .. " год " .. numbers[3] .. " хв " .. numbers[5] .. " сек"
            elseif (#numbers == 4) then
                return numbers[1] .. " хв " .. numbers[3] .. " сек"
            else
                return numbers[1] .. " сек"
            end
        end

        local cooldownRemaining = tooltipInfo[CATEGORY.COOLDOWN_REMAINING][1]
        table.insert(translatedTooltipLines, {
            index = getTooltipIndex(cooldownRemaining.index),
            value = GetTranslatedGlobalString(COOLDOWN_REMAINING) .. " " .. translateTime(cooldownRemaining.value)
        })
    end

    if (tooltipInfo[CATEGORY.HEIRLOOM_UPGRADE]) then
        local collected = tooltipInfo[CATEGORY.HEIRLOOM_UPGRADE][1]
        table.insert(translatedTooltipLines, {
            index = getTooltipIndex(collected.index),
            value = GetTranslatedGlobalString(HEIRLOOM_UPGRADE_TOOLTIP_FORMAT):format(collected.min, collected.max)
        })
    end

    ---@diagnostic disable-next-line: need-check-nil
    if (ns.SettingsProvider.IsNeedToTranslateItemNameInTooltip() and itemTranslation and itemTranslation.Title) then
        local name = tooltipInfo.Name
        table.insert(translatedTooltipLines, {
            index = getTooltipIndex(name.index),
            value = itemTranslation.Title
        })
    end

    ---@diagnostic disable-next-line: need-check-nil
    if (ns.SettingsProvider.IsNeedToTranslateItemAttributesInTooltip()) then
        if (tooltipInfo[CATEGORY.ATTRIBUTES]) then
            for _, attribute in ipairs(tooltipInfo[CATEGORY.ATTRIBUTES]) do
                if (attribute.value) then
                    table.insert(translatedTooltipLines, {
                        index = getTooltipIndex(attribute.index),
                        value = ("+%s %s"):format(attribute.value, GetTranslatedItemAttribute(attribute.name))
                    })
                else
                    table.insert(translatedTooltipLines, {
                        index = getTooltipIndex(attribute.index),
                        value = ("+%s-%s %s"):format(attribute.min, attribute.max, GetTranslatedItemAttribute(attribute.name))
                    })
                end
            end
        end

        if (tooltipInfo[CATEGORY.ARMOR]) then
            local armor = tooltipInfo[CATEGORY.ARMOR][1]
            table.insert(translatedTooltipLines, {
                index = getTooltipIndex(armor.index),
                value = GetTranslatedGlobalString(ARMOR_TEMPLATE):format(armor.value)
            })
        end

        if (tooltipInfo[CATEGORY.EQUIP_SLOT]) then
            local equipSlot = tooltipInfo[CATEGORY.EQUIP_SLOT]

            local slot
            if (equipSlot.slot == INVTYPE_CLOAK) then
                slot = 'Спина' -- HOOK: Override the ambiguous `BACK` string for the equipment slot context.
            else
                slot = GetTranslatedGlobalString(equipSlot.slot)
            end

            table.insert(translatedTooltipLines, {
                index = getTooltipIndex(equipSlot.index),
                value = slot
            })

            table.insert(translatedTooltipLines, {
                index = getTooltipIndex(equipSlot.index, true),
                value = GetTranslatedGlobalString(equipSlot.armorType)
            })
        end

        if (tooltipInfo[CATEGORY.DPS]) then
            local dps = tooltipInfo[CATEGORY.DPS][1]
            table.insert(translatedTooltipLines, {
                index = getTooltipIndex(dps.index),
                value = GetTranslatedGlobalString(DPS_TEMPLATE):format(dps.value)
            })
        end

        if (tooltipInfo[CATEGORY.WEAPON_DAMAGE]) then
            local damage = tooltipInfo[CATEGORY.WEAPON_DAMAGE][1]
            table.insert(translatedTooltipLines, {
                index = getTooltipIndex(damage.index),
                value = GetTranslatedGlobalString(DAMAGE_TEMPLATE):format(damage.min, damage.max)
            })
        end

        if (tooltipInfo[CATEGORY.WEAPON_SPEED]) then
            local speed = tooltipInfo[CATEGORY.WEAPON_SPEED][1]
            table.insert(translatedTooltipLines, {
                index = getTooltipIndex(speed.index, true),
                value = GetTranslatedGlobalString('Speed %s'):format(speed.value)
            })
        end
    end

    return translatedTooltipLines
end

function translator:IsEnabled()
    return ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_ITEM_TOOLTIPS_OPTION)
end

function translator:Init()
    local function translateComparisonLines(tooltip, startLine)
        local tooltipName = tooltip:GetName()
        for i = startLine, tooltip:NumLines() do
            local lineLeft = _G[tooltipName .. "TextLeft" .. i]
            if lineLeft and lineLeft:GetText() then
                for _, patternInfo in ipairs(compareItemPatterns) do
                    local matches = { string.match(lineLeft:GetText(), patternInfo.pattern) }
                    if #matches > 0 then
                        patternInfo.func(matches, lineLeft)
                        return
                    end
                end
                UpdateTextWithTranslation(lineLeft, GetTranslatedGlobalString)
            end
        end
    end

    ns.BaseTooltipTranslator.Init(self)

    hooksecurefunc("GameTooltip_ShowCompareItem", function()
        if (not self._postCallLineCount) then return end

        local tooltip = TooltipComparisonManager.tooltip;
        if (not tooltip) then return end

        local primaryTooltip = tooltip.shoppingTooltips[1];
        local secondaryTooltip = tooltip.shoppingTooltips[2];

        if (primaryTooltip:IsShown() and secondaryTooltip:IsShown()) then
            UpdateTextWithTranslation(_G[secondaryTooltip:GetName() .. "TextLeft1"], GetTranslatedGlobalString)
        end
        UpdateTextWithTranslation(_G[primaryTooltip:GetName() .. "TextLeft1"], GetTranslatedGlobalString)

        local comparisonStartLine = self._postCallLineCount + 2

        if (primaryTooltip:NumLines() > comparisonStartLine) then
            translateComparisonLines(primaryTooltip, comparisonStartLine)
        end

        if (secondaryTooltip:IsShown() and secondaryTooltip:NumLines() > comparisonStartLine) then
            translateComparisonLines(secondaryTooltip, comparisonStartLine)
        end

        primaryTooltip:Show()
    end)
end

ns.TranslationsManager:AddTranslator(translator)
