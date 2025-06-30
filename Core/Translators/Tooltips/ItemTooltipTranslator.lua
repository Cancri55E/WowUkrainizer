--- @class WowUkrainizerInternals
local ns = select(2, ...);

local _G = _G
local NullOrEmpty = ns.StringUtil.NullOrEmpty
local UpdateTextWithTranslation = ns.FontStringUtil.UpdateTextWithTranslation
local GetItemTranslation = ns.DbContext.Items.GetItemTranslation
local GetTranslatedItemAttribute = ns.DbContext.Items.GetTranslatedItemAttribute
local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString
local GetTranslatedClass = ns.DbContext.Player.GetTranslatedClass

---@class ItemTooltipTranslator : BaseTooltipTranslator
local translator = setmetatable({ tooltipDataType = Enum.TooltipDataType.Item }, { __index = ns.BaseTooltipTranslator })

local TOOLTIP_CATEGORY_ATTRIBUTES = "Attributes"
local TOOLTIP_CATEGORY_ITEM_LEVEL = "Item Level"
local TOOLTIP_CATEGORY_ARMOR = "Armor"
local TOOLTIP_CATEGORY_DESCRIPTION = "Description"
local TOOLTIP_CATEGORY_DURABILITY = "Durability"
local TOOLTIP_CATEGORY_MADE_BY = "Made By"
local TOOLTIP_CATEGORY_DPS = "DPS"
local TOOLTIP_CATEGORY_WEAPON_DAMAGE = "Weapon Damage"
local TOOLTIP_CATEGORY_WEAPON_SPEED = "Weapon Speed"
local TOOLTIP_CATEGORY_PROFESSION_CRAFTING_QUALITY = "Profession Crafting Quality"
local TOOLTIP_CATEGORY_EQUIP_SLOT = "Equip Slot"
local TOOLTIP_CATEGORY_RESTRICTED_LEVEL = "Restricted Level"
local TOOLTIP_CATEGORY_ITEM_BINDING = "Item Binding"
local TOOLTIP_CATEGORY_EQUIPMENT_SETS = "Equipment Sets"
local TOOLTIP_CATEGORY_UNCLASSIFIED = "Unclassified"
local TOOLTIP_CATEGORY_UPGRADE_LEVEL = "Upgrade Level"
local TOOLTIP_CATEGORY_CLASSES = "Classes"
local TOOLTIP_CATEGORY_COOLDOWN_REMAINING = "Cooldown remaining"
local TOOLTIP_CATEGORY_ITEM_PET_KNOWN = "Collected"

local function HandleAttributes(data, index)
    if (#data == 3) then
        return { TOOLTIP_CATEGORY_ATTRIBUTES }, { min = data[1], max = data[2], name = data[3], index = index }
    else
        return { TOOLTIP_CATEGORY_ATTRIBUTES }, { value = data[1], name = data[2], index = index }
    end
end

local function HandleItemLevel(data, index)
    return { TOOLTIP_CATEGORY_ITEM_LEVEL }, { value = data[1], index = index }
end

local function HandleArmor(data, index)
    return { TOOLTIP_CATEGORY_ARMOR }, { value = data[1], index = index }
end

local function HandleDescription(data, index)
    return { TOOLTIP_CATEGORY_DESCRIPTION }, { value = data[1], index = index }
end

local function HandleDurability(data, index)
    return { TOOLTIP_CATEGORY_DURABILITY }, { min = data[1], max = data[2], index = index }
end

local function HandleMadeBy(data, index)
    return { TOOLTIP_CATEGORY_MADE_BY }, { value = data[1], index = index }
end

local function HandleDps(data, index)
    return { TOOLTIP_CATEGORY_DPS }, { value = data[1], index = index }
end

local function HandleWeaponDamage(data, index)
    return { TOOLTIP_CATEGORY_WEAPON_DAMAGE }, { min = data[1], max = data[2], index = index }
end

local function HandleWeaponSpeed(data, index)
    return { TOOLTIP_CATEGORY_WEAPON_SPEED }, { value = data[1], index = index, right = true }
end

local function HandleEquipmentSets(data, index)
    return { TOOLTIP_CATEGORY_EQUIPMENT_SETS }, { value = data[1], index = index }
end

local function HandleUpgradeLevel(data, index)
    if (#data == 5) then
        return { TOOLTIP_CATEGORY_UPGRADE_LEVEL }, { min = data[4], max = data[5], name = data[3], prefix = data[2], color = data[1], index = index }
    elseif (#data == 3) then
        return { TOOLTIP_CATEGORY_UPGRADE_LEVEL }, { min = data[2], max = data[3], name = data[1], index = index }
    else
        return { TOOLTIP_CATEGORY_UPGRADE_LEVEL }, { min = data[1], max = data[2], index = index }
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
    return { TOOLTIP_CATEGORY_CLASSES }, { value = table.concat(splitClasses(data[1]), ", "), index = index }
end

local function HandleCollected(data, index)
    return { TOOLTIP_CATEGORY_ITEM_PET_KNOWN }, { min = data[1], max = data[2], index = index }
end

local function HandleCooldownRemaining(data, index)
    return { TOOLTIP_CATEGORY_COOLDOWN_REMAINING }, { value = data[1], index = index }
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
        pattern = ITEM_PET_KNOWN:gsub("%(", "%%("):gsub("%)", "%%)"):gsub("%%d", "(%%d)"),
        func = HandleCollected
    },
}

local compareItemPatterns = {
    {
        pattern = "^|c(........)([-+][%d,.]*)%s*|r%s*(.*)$",
        func = function(data, tooltipLine)
            if (data[3] == STAT_STURDINESS) then
                tooltipLine:SetText("|c" .. data[1] .. data[2] .. "|r " .. GetTranslatedGlobalString(data[3]))
            else
                tooltipLine:SetText("|c" .. data[1] .. data[2] .. "|r " .. GetTranslatedItemAttribute(data[3]))
            end
        end
    },
    {
        pattern = "^" .. ITEM_DELTA_DUAL_WIELD_COMPARISON_MAINHAND_DESCRIPTION
            :gsub("%(", "%%("):gsub("%)", "%%)"):gsub("%-", "%%-"):gsub("|c%%s%%s|r", "|c(%%x%%x%%x%%x%%x%%x%%x%%x)(.*)|r") .. "$",
        func = function(data, tooltipLine)
            tooltipLine:SetText(GetTranslatedGlobalString(ITEM_DELTA_DUAL_WIELD_COMPARISON_MAINHAND_DESCRIPTION):format(data[1], data[2]))
        end
    },
    {
        pattern = "^" .. ITEM_DELTA_DUAL_WIELD_COMPARISON_OFFHAND_DESCRIPTION
            :gsub("%(", "%%("):gsub("%)", "%%)"):gsub("%-", "%%-"):gsub("|c%%s%%s|r", "|c(%%x%%x%%x%%x%%x%%x%%x%%x)(.*)|r") .. "$",
        func = function(data, tooltipLine)
            tooltipLine:SetText(GetTranslatedGlobalString(ITEM_DELTA_DUAL_WIELD_COMPARISON_OFFHAND_DESCRIPTION):format(data[1], data[2]))
        end
    },
    {
        pattern = "^" .. ITEM_COMPARISON_SWAP_ITEM_MAINHAND_DESCRIPTION:gsub("%%s", "(.*)") .. "$",
        func = function(data, tooltipLine)
            tooltipLine:SetText(GetTranslatedGlobalString(ITEM_COMPARISON_SWAP_ITEM_MAINHAND_DESCRIPTION):format(data[1]))
        end
    },
    {
        pattern = "^" .. ITEM_COMPARISON_SWAP_ITEM_OFFHAND_DESCRIPTION:gsub("%%s", "(.*)") .. "$",
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
            if (not result[TOOLTIP_CATEGORY_UNCLASSIFIED]) then result[TOOLTIP_CATEGORY_UNCLASSIFIED] = {} end
            table.insert(result[TOOLTIP_CATEGORY_UNCLASSIFIED], { value = text, index = index, right = isRightText })
        end
    end

    self._postCallLineCount = tonumber(tooltip:NumLines())
    local tooltipName = tooltip:GetName()

    for i = 1, tooltip:NumLines() do
        self:AddFontStringToIndexLookup(i * 2 - 1, _G[tooltipName .. "TextLeft" .. i])
        self:AddFontStringToIndexLookup(i * 2, _G[tooltipName .. "TextRight" .. i])
    end

    local tooltipLines = tooltipData.lines

    local result = {}
    result.ID = tonumber(tooltipData.id)

    for i = 1, #tooltipLines, 1 do
        local tooltipLine = tooltipLines[i]
        if (tooltipLine.type == Enum.TooltipDataLineType.Blank or tooltipLine.type == Enum.TooltipDataLineType.SellPrice) then
            -- ignore
        elseif (tooltipLine.type == Enum.TooltipDataLineType.ItemName) then
            result.Name = { value = tooltipLine.leftText, index = tooltipLine.lineIndex }
        elseif (tooltipLine.type == Enum.TooltipDataLineType.ItemBinding) then
            result[TOOLTIP_CATEGORY_ITEM_BINDING] = { value = tooltipLine.leftText, index = tooltipLine.lineIndex }
        elseif (tooltipLine.type == Enum.TooltipDataLineType.ProfessionCraftingQuality) then
            result[TOOLTIP_CATEGORY_PROFESSION_CRAFTING_QUALITY] = {
                value = string.match(tooltipLine.leftText, "^Quality: (.*)$"),
                index = tooltipLine.lineIndex
            }
        elseif (tooltipLine.type == Enum.TooltipDataLineType.RestrictedLevel) then
            result[TOOLTIP_CATEGORY_RESTRICTED_LEVEL] = { value = string.match(tooltipLine.leftText, "^Requires Level (%d+)$"), index = tooltipLine.lineIndex }
        elseif (tooltipLine.type == Enum.TooltipDataLineType.EquipSlot) then
            result[TOOLTIP_CATEGORY_EQUIP_SLOT] = { slot = tooltipLine.leftText, armorType = tooltipLine.rightText, index = tooltipLine.lineIndex }
        else
            if (not NullOrEmpty(tooltipLine.leftText)) then
                saveUndefinedLineTypeText(result, tooltipLine.leftText, tooltipLine.lineIndex, false)
            end
            if (not NullOrEmpty(tooltipLine.rightText)) then
                saveUndefinedLineTypeText(result, tooltipLine.rightText, tooltipLine.lineIndex, true)
            end
        end
    end
    return result
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

    if (tooltipInfo[TOOLTIP_CATEGORY_DESCRIPTION]) then
        local description = tooltipInfo[TOOLTIP_CATEGORY_DESCRIPTION][1]
        if (itemTranslation and itemTranslation.Description) then
            table.insert(translatedTooltipLines, {
                index = getTooltipIndex(description.index),
                value = "\"" .. itemTranslation.Description .. "\""
            })
        end
    end

    if (tooltipInfo[TOOLTIP_CATEGORY_ITEM_LEVEL]) then
        local itemLevel = tooltipInfo[TOOLTIP_CATEGORY_ITEM_LEVEL][1]
        table.insert(translatedTooltipLines, {
            index = getTooltipIndex(itemLevel.index),
            value = GetTranslatedGlobalString(ITEM_LEVEL):format(itemLevel.value)
        })
    end

    if (tooltipInfo[TOOLTIP_CATEGORY_CLASSES]) then
        local itemLevel = tooltipInfo[TOOLTIP_CATEGORY_CLASSES][1]
        table.insert(translatedTooltipLines, {
            index = getTooltipIndex(itemLevel.index),
            value = GetTranslatedGlobalString(ITEM_CLASSES_ALLOWED):format(itemLevel.value)
        })
    end

    if (tooltipInfo[TOOLTIP_CATEGORY_DURABILITY]) then
        local durability = tooltipInfo[TOOLTIP_CATEGORY_DURABILITY][1]
        table.insert(translatedTooltipLines, {
            index = getTooltipIndex(durability.index),
            value = GetTranslatedGlobalString(DURABILITY_TEMPLATE):format(durability.min, durability.max)
        })
    end

    if (tooltipInfo[TOOLTIP_CATEGORY_MADE_BY]) then
        local madeBy = tooltipInfo[TOOLTIP_CATEGORY_MADE_BY][1]
        table.insert(translatedTooltipLines, {
            index = getTooltipIndex(madeBy.index),
            value = GetTranslatedGlobalString(ITEM_CREATED_BY, true):format(madeBy.value)
        })
    end

    if (tooltipInfo[TOOLTIP_CATEGORY_EQUIPMENT_SETS]) then
        local equipmentSets = tooltipInfo[TOOLTIP_CATEGORY_EQUIPMENT_SETS][1]
        table.insert(translatedTooltipLines, {
            index = getTooltipIndex(equipmentSets.index),
            value = GetTranslatedGlobalString(EQUIPMENT_SETS, true):format(equipmentSets.value)
        })
    end

    if (tooltipInfo[TOOLTIP_CATEGORY_PROFESSION_CRAFTING_QUALITY]) then
        local professionCraftingQuality = tooltipInfo[TOOLTIP_CATEGORY_PROFESSION_CRAFTING_QUALITY]
        -- may be present in the data but not have an index because it is not displayed in the tooltip (for example, for reagents of new professions (> 10.0) in the profession window)
        if (professionCraftingQuality.index) then
            table.insert(translatedTooltipLines, {
                index = getTooltipIndex(professionCraftingQuality.index),
                value = GetTranslatedGlobalString(PROFESSIONS_CRAFTING_QUALITY):format(professionCraftingQuality.value)
            })
        end
    end

    if (tooltipInfo[TOOLTIP_CATEGORY_RESTRICTED_LEVEL]) then
        local restrictedLevel = tooltipInfo[TOOLTIP_CATEGORY_RESTRICTED_LEVEL]
        table.insert(translatedTooltipLines, {
            index = getTooltipIndex(restrictedLevel.index),
            value = GetTranslatedGlobalString(ITEM_MIN_LEVEL):format(restrictedLevel.value)
        })
    end

    if (tooltipInfo[TOOLTIP_CATEGORY_ITEM_BINDING]) then
        local itemBinding = tooltipInfo[TOOLTIP_CATEGORY_ITEM_BINDING]
        table.insert(translatedTooltipLines, {
            index = getTooltipIndex(itemBinding.index),
            value = GetTranslatedGlobalString(itemBinding.value)
        })
    end

    if (tooltipInfo[TOOLTIP_CATEGORY_UPGRADE_LEVEL]) then
        local upgradeLevel = tooltipInfo[TOOLTIP_CATEGORY_UPGRADE_LEVEL][1]

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

    if (tooltipInfo[TOOLTIP_CATEGORY_ITEM_PET_KNOWN]) then
        local collected = tooltipInfo[TOOLTIP_CATEGORY_ITEM_PET_KNOWN][1]
        table.insert(translatedTooltipLines, {
            index = getTooltipIndex(collected.index),
            value = GetTranslatedGlobalString(ITEM_PET_KNOWN):format(collected.min, collected.max)
        })
    end

    if (tooltipInfo[TOOLTIP_CATEGORY_UNCLASSIFIED]) then
        for _, unclassified in ipairs(tooltipInfo[TOOLTIP_CATEGORY_UNCLASSIFIED]) do
            table.insert(translatedTooltipLines, {
                index = getTooltipIndex(unclassified.index, unclassified.right),
                value = GetTranslatedGlobalString(unclassified.value)
            })
        end
    end

    if (tooltipInfo[TOOLTIP_CATEGORY_COOLDOWN_REMAINING]) then
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

        local cooldownRemaining = tooltipInfo[TOOLTIP_CATEGORY_COOLDOWN_REMAINING][1]
        table.insert(translatedTooltipLines, {
            index = getTooltipIndex(cooldownRemaining.index),
            value = GetTranslatedGlobalString(COOLDOWN_REMAINING) .. " " .. translateTime(cooldownRemaining.value)
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
        if (tooltipInfo[TOOLTIP_CATEGORY_ATTRIBUTES]) then
            for _, attribute in ipairs(tooltipInfo[TOOLTIP_CATEGORY_ATTRIBUTES]) do
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

        if (tooltipInfo[TOOLTIP_CATEGORY_ARMOR]) then
            local armor = tooltipInfo[TOOLTIP_CATEGORY_ARMOR][1]
            table.insert(translatedTooltipLines, {
                index = getTooltipIndex(armor.index),
                value = GetTranslatedGlobalString(ARMOR_TEMPLATE):format(armor.value)
            })
        end

        if (tooltipInfo[TOOLTIP_CATEGORY_EQUIP_SLOT]) then
            local equipSlot = tooltipInfo[TOOLTIP_CATEGORY_EQUIP_SLOT]

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

        if (tooltipInfo[TOOLTIP_CATEGORY_DPS]) then
            local dps = tooltipInfo[TOOLTIP_CATEGORY_DPS][1]
            table.insert(translatedTooltipLines, {
                index = getTooltipIndex(dps.index),
                value = GetTranslatedGlobalString(DPS_TEMPLATE):format(dps.value)
            })
        end

        if (tooltipInfo[TOOLTIP_CATEGORY_WEAPON_DAMAGE]) then
            local damage = tooltipInfo[TOOLTIP_CATEGORY_WEAPON_DAMAGE][1]
            table.insert(translatedTooltipLines, {
                index = getTooltipIndex(damage.index),
                value = GetTranslatedGlobalString(DAMAGE_TEMPLATE):format(damage.min, damage.max)
            })
        end

        if (tooltipInfo[TOOLTIP_CATEGORY_WEAPON_SPEED]) then
            local speed = tooltipInfo[TOOLTIP_CATEGORY_WEAPON_SPEED][1]
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
    local function translateTooltipLineText(tooltipLine)
        for _, patternInfo in ipairs(compareItemPatterns) do
            local matches = { string.match(tooltipLine:GetText(), patternInfo.pattern) }
            if #matches > 0 then
                patternInfo.func(matches, tooltipLine)
                return
            end
        end

        UpdateTextWithTranslation(tooltipLine, GetTranslatedGlobalString)
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

        if (primaryTooltip:NumLines() > self._postCallLineCount + 2) then
            local tooltipName = primaryTooltip:GetName()
            for i = self._postCallLineCount + 2, primaryTooltip:NumLines() do
                local lineLeft = _G[tooltipName .. "TextLeft" .. i]
                if (lineLeft) then
                    translateTooltipLineText(lineLeft)
                end
            end
        end

        if (secondaryTooltip:IsShown() and secondaryTooltip:NumLines() > self._postCallLineCount + 2) then
            local tooltipName = secondaryTooltip:GetName()
            for i = self._postCallLineCount + 2, secondaryTooltip:NumLines() do
                local lineLeft = _G[tooltipName .. "TextLeft" .. i]
                if (lineLeft) then
                    translateTooltipLineText(lineLeft)
                end
            end
        end

        primaryTooltip:Show()
    end)
end

ns.TranslationsManager:AddTranslator(translator)
