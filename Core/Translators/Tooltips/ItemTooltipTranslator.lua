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
    { pattern = "^%+(%d+)-(%d+)%s(.*)$",              func = HandleAttributes },
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
            if (not result[TOOLTIP_CATEGORY_UNCLASSIFIED]) then result[TOOLTIP_CATEGORY_UNCLASSIFIED] = {} end
            table.insert(result[TOOLTIP_CATEGORY_UNCLASSIFIED], { value = text, index = index, right = isRightText })
        end
    end

    -- DevTool:AddData(tooltipData, "ParseTooltip")

    self._postCallLineCount = tonumber(tooltip:NumLines())

    local tooltipLine = {}
    for i = 1, tooltip:NumLines() do
        -- local leftText = _G["GameTooltipTextLeft" .. i]
        -- if (leftText) then
        --     local currentIndex = #tooltipLine + 1;
        --     tooltipLine[currentIndex] = leftText:GetText() or ''
        --     self:AddFontStringToIndexLookup(currentIndex, leftText)
        -- end

        -- local rightText = _G["GameTooltipTextRight" .. i]
        -- if (rightText) then
        --     local currentIndex = #tooltipLine + 1;
        --     tooltipLine[currentIndex] = rightText:GetText() or ''
        --     self:AddFontStringToIndexLookup(currentIndex, rightText)
        -- end
    end

    local result = {}
    for i = 1, #tooltipLine, 1 do
        local tooltipLine = tooltipLine[i]
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
    DevTool:AddData(tooltipInfo, "tooltipInfo")

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
                    index = attribute.index,
                    value = ("+%d %s"):format(attribute.value, GetTranslatedItemAttribute(attribute.name))
                })
            else
                table.insert(translatedTooltipLines, {
                    index = attribute.index,
                    value = ("+%d-%d %s"):format(attribute.min, attribute.max, GetTranslatedItemAttribute(attribute.name))
                })
            end
        end
    end

    if (tooltipInfo[TOOLTIP_CATEGORY_ITEM_LEVEL]) then

    end

    if (tooltipInfo[TOOLTIP_CATEGORY_ARMOR]) then
        local armor = tooltipInfo[TOOLTIP_CATEGORY_ARMOR][1]
        table.insert(translatedTooltipLines, {
            index = armor.index,
            value = ("%d Броні"):format(armor.value)
        })
    end

    if (tooltipInfo[TOOLTIP_CATEGORY_DESCRIPTION]) then
        local description = tooltipInfo[TOOLTIP_CATEGORY_DESCRIPTION][1]
        table.insert(translatedTooltipLines, {
            index = description.index,
            value = "\"" .. GetTranslatedItemDescription(description.text) .. "\"" -- TODO: Add Color
        })
    end

    if (tooltipInfo[TOOLTIP_CATEGORY_DURABILITY]) then

    end

    if (tooltipInfo[TOOLTIP_CATEGORY_MADE_BY]) then

    end

    if (tooltipInfo[TOOLTIP_CATEGORY_DPS]) then

    end

    if (tooltipInfo[TOOLTIP_CATEGORY_WEAPON_DAMAGE]) then

    end

    if (tooltipInfo[TOOLTIP_CATEGORY_WEAPON_SPEED]) then

    end

    if (tooltipInfo[TOOLTIP_CATEGORY_PROFESSION_CRAFTING_QUALITY]) then

    end

    if (tooltipInfo[TOOLTIP_CATEGORY_EQUIP_SLOT]) then
        -- GetTranslatedGlobalString
    end

    if (tooltipInfo[TOOLTIP_CATEGORY_RESTRICTED_LEVEL]) then

    end

    if (tooltipInfo[TOOLTIP_CATEGORY_ITEM_BINDING]) then

    end

    if (tooltipInfo[TOOLTIP_CATEGORY_UNCLASSIFIED]) then

    end

    DevTool:AddData(translatedTooltipLines, "translatedTooltipLines")

    return translatedTooltipLines
end

function translator:IsEnabled()
    return ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_ITEM_TOOLTIPS_OPTION)
end

ns.TranslationsManager:AddTranslator(translator)
