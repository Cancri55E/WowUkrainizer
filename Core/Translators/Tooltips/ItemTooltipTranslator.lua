--- @class WowUkrainizerInternals
local ns = select(2, ...);

local NullOrEmpty = ns.StringUtil.NullOrEmpty
local GetTranslatedItemName = ns.DbContext.Items.GetTranslatedItemName
local GetTranslatedItemDescription = ns.DbContext.Items.GetTranslatedItemDescription
local GetTranslatedItemAttribute = ns.DbContext.Items.GetTranslatedItemAttribute
local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString

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
local TOOLTIP_CATEGORY_SELL_PRICE = "Sell Price"
local TOOLTIP_CATEGORY_UNCLASSIFIED = "Unclassified"

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
}

function translator:ParseTooltip(tooltip, tooltipData)
    local function saveUndefinedLineTypeText(result, text, index, isRightText)
        local function parseUndefinedLineTypeText(text, index)
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

        local categories, leftTextData = parseUndefinedLineTypeText(text, index)
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

    for i = 1, tooltip:NumLines() do
        self:AddFontStringToIndexLookup(i * 2 - 1, _G["GameTooltipTextLeft" .. i])
        self:AddFontStringToIndexLookup(i * 2, _G["GameTooltipTextRight" .. i])
    end

    local tooltipLines = tooltipData.lines

    local result = {}
    for i = 1, #tooltipLines, 1 do
        local tooltipLine = tooltipLines[i]
        if (tooltipLine.type == Enum.TooltipDataLineType.Blank) then
            -- ignore
        elseif (tooltipLine.type == Enum.TooltipDataLineType.ItemName) then
            result.Name = tooltipLine.leftText
        elseif (tooltipLine.type == Enum.TooltipDataLineType.ItemBinding) then
            result[TOOLTIP_CATEGORY_ITEM_BINDING] = { value = tooltipLine.leftText, index = i }
        elseif (tooltipLine.type == Enum.TooltipDataLineType.ProfessionCraftingQuality) then
            result[TOOLTIP_CATEGORY_PROFESSION_CRAFTING_QUALITY] = { value = string.match(tooltipLine.leftText, "^Quality: (.*)$"), index = i }
        elseif (tooltipLine.type == Enum.TooltipDataLineType.RestrictedLevel) then
            result[TOOLTIP_CATEGORY_RESTRICTED_LEVEL] = { value = string.match(tooltipLine.leftText, "^Requires Level (%d+)$"), index = i }
        elseif (tooltipLine.type == Enum.TooltipDataLineType.EquipSlot) then
            result[TOOLTIP_CATEGORY_EQUIP_SLOT] = { slot = tooltipLine.leftText, armorType = tooltipLine.rightText, index = i }
        elseif (tooltipLine.type == Enum.TooltipDataLineType.SellPrice) then
            -- ignore
        else
            if (not NullOrEmpty(tooltipLine.leftText)) then
                saveUndefinedLineTypeText(result, tooltipLine.leftText, i, false)
            end
            if (not NullOrEmpty(tooltipLine.rightText)) then
                saveUndefinedLineTypeText(result, tooltipLine.rightText, i, true)
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

    local translatedTooltipLines = {}

    table.insert(translatedTooltipLines, {
        index = 1,
        value = GetTranslatedItemName(tooltipInfo.Name)
    })

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

    if (tooltipInfo[TOOLTIP_CATEGORY_ITEM_LEVEL]) then
        local itemLevel = tooltipInfo[TOOLTIP_CATEGORY_ITEM_LEVEL][1]
        table.insert(translatedTooltipLines, {
            index = getTooltipIndex(itemLevel.index),
            value = GetTranslatedGlobalString(ITEM_LEVEL):format(itemLevel.value)
        })
    end

    if (tooltipInfo[TOOLTIP_CATEGORY_ARMOR]) then
        local armor = tooltipInfo[TOOLTIP_CATEGORY_ARMOR][1]
        table.insert(translatedTooltipLines, {
            index = getTooltipIndex(armor.index),
            value = GetTranslatedGlobalString(ARMOR_TEMPLATE):format(armor.value)
        })
    end

    if (tooltipInfo[TOOLTIP_CATEGORY_DESCRIPTION]) then
        local description = tooltipInfo[TOOLTIP_CATEGORY_DESCRIPTION][1]
        table.insert(translatedTooltipLines, {
            index = getTooltipIndex(description.index),
            value = "\"" .. GetTranslatedItemDescription(description.value) .. "\""
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

    if (tooltipInfo[TOOLTIP_CATEGORY_PROFESSION_CRAFTING_QUALITY]) then
        local professionCraftingQuality = tooltipInfo[TOOLTIP_CATEGORY_PROFESSION_CRAFTING_QUALITY]
        table.insert(translatedTooltipLines, {
            index = getTooltipIndex(professionCraftingQuality.index),
            value = GetTranslatedGlobalString(PROFESSIONS_CRAFTING_QUALITY):format(professionCraftingQuality.value)
        })
    end

    if (tooltipInfo[TOOLTIP_CATEGORY_EQUIP_SLOT]) then
        local equipSlot = tooltipInfo[TOOLTIP_CATEGORY_EQUIP_SLOT]

        local slot
        if (equipSlot.slot == INVTYPE_CLOAK) then
            slot = 'Спина' -- HOOK: Fix after GlobalString refactoring
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

    if (tooltipInfo[TOOLTIP_CATEGORY_UNCLASSIFIED]) then
        for _, unclassified in ipairs(tooltipInfo[TOOLTIP_CATEGORY_UNCLASSIFIED]) do
            table.insert(translatedTooltipLines, {
                index = getTooltipIndex(unclassified.index, unclassified.right),
                value = GetTranslatedGlobalString(unclassified.value)
            })
        end
    end

    return translatedTooltipLines
end

function translator:IsEnabled()
    return ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_ITEM_TOOLTIPS_OPTION)
end

ns.TranslationsManager:AddTranslator(translator)
