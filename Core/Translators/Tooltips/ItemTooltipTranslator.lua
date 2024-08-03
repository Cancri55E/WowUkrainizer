--- @class WowUkrainizerInternals
local ns = select(2, ...);

local NullOrEmpty = ns.StringUtil.NullOrEmpty
local GetTranslatedItemName = ns.DbContext.Items.GetTranslatedItemName
local GetTranslatedItemDescription = ns.DbContext.Items.GetTranslatedItemDescription
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

local function HandleAttributes(data, index)
    return { TOOLTIP_CATEGORY_ATTRIBUTES }, { value = data[1], name = data[2], index = index }
end

local function HandleItemLevel(data, index)
    return { TOOLTIP_CATEGORY_ITEM_LEVEL }, { value = data[1], index = index }
end

local function HandleArmor(data, index)
    return { TOOLTIP_CATEGORY_ARMOR }, { value = data[1], index = index }
end

local function HandleDescription(data, index)
    return { TOOLTIP_CATEGORY_DESCRIPTION }, { text = data[1], index = index }
end

local function HandleDurability(data, index)
    return { TOOLTIP_CATEGORY_DURABILITY }, { min = data[1], max = data[2], index = index }
end

local function HandleMadeBy(data, index)
    return { TOOLTIP_CATEGORY_MADE_BY }, { name = data[1], index = index }
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

local patterns = {
    { pattern = "^%+(%d+)%s(.*)$",                    func = HandleAttributes },
    { pattern = "^(%d+)%sArmor$",                     func = HandleArmor },
    { pattern = '^"(.*)"$',                           func = HandleDescription },
    { pattern = '^Durability (%d+) / (%d+)$',         func = HandleDurability },
    { pattern = '^|cff00ff00<Made by (.*)>|r$',       func = HandleMadeBy },
    { pattern = '^%((.*) damage per second%)$',       func = HandleDps },
    { pattern = '^([%d,]+)%s*-%s*([%d,]+)%s*Damage$', func = HandleWeaponDamage },
    { pattern = '^Speed ([%d,.]+)$',                  func = HandleWeaponSpeed },
    { pattern = '^Item Level (%d+)$',                 func = HandleItemLevel },
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
            result[text] = { unclassified = true, index = index, right = isRightText }
        end
    end

    DevTool:AddData(tooltipData, "ParseTooltip")

    for i = 1, tooltip:NumLines() do
        self:AddFontStringToIndexLookup(i, _G["GameTooltipTextLeft" .. i])
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
            result[TOOLTIP_CATEGORY_ITEM_BINDING] = { text = tooltipLine.leftText, index = i }
        elseif (tooltipLine.type == Enum.TooltipDataLineType.ProfessionCraftingQuality) then
            result[TOOLTIP_CATEGORY_PROFESSION_CRAFTING_QUALITY] = { text = string.match(tooltipLine.leftText, "^Quality: (.*)$"), index = i }
        elseif (tooltipLine.type == Enum.TooltipDataLineType.RestrictedLevel) then
            result[TOOLTIP_CATEGORY_RESTRICTED_LEVEL] = { text = string.match(tooltipLine.leftText, "^Requires Level (%d+)$"), index = i }
        elseif (tooltipLine.type == Enum.TooltipDataLineType.EquipSlot) then
            result[TOOLTIP_CATEGORY_EQUIP_SLOT] = { slot = tooltipLine.leftText, armorType = tooltipLine.rightText, index = i }
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
    DevTool:AddData(tooltipInfo, "TranslateTooltipInfo")

    if (not tooltipInfo.Name) then return end

    local translatedTooltipLines = {}

    table.insert(translatedTooltipLines, {
        index = 1,
        value = GetTranslatedItemName(tooltipInfo.name)
    })

    if (tooltipInfo[TOOLTIP_CATEGORY_ATTRIBUTES]) then

    end
    -- local TOOLTIP_CATEGORY_ATTRIBUTES = "Attributes"
    -- local TOOLTIP_CATEGORY_ITEM_LEVEL = "Item Level"
    -- local TOOLTIP_CATEGORY_ARMOR = "Armor"
    -- local TOOLTIP_CATEGORY_DESCRIPTION = "Description"
    -- local TOOLTIP_CATEGORY_DURABILITY = "Durability"
    -- local TOOLTIP_CATEGORY_MADE_BY = "Made By"
    -- local TOOLTIP_CATEGORY_DPS = "DPS"
    -- local TOOLTIP_CATEGORY_WEAPON_DAMAGE = "Weapon Damage"
    -- local TOOLTIP_CATEGORY_WEAPON_SPEED = "Weapon Speed"
    -- local TOOLTIP_CATEGORY_PROFESSION_CRAFTING_QUALITY = "Profession Crafting Quality"
    -- local TOOLTIP_CATEGORY_EQUIP_SLOT = "Equip Slot"
    -- local TOOLTIP_CATEGORY_RESTRICTED_LEVEL = "Restricted Level"
    -- local TOOLTIP_CATEGORY_ITEM_BINDING = "Item Binding"

    return translatedTooltipLines
end

function translator:IsEnabled()
    return ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_ITEM_TOOLTIPS_OPTION)
end

ns.TranslationsManager:AddTranslator(translator)
