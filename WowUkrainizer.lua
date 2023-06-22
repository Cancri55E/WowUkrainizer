local addonName, ns = ...;

local libDropDown = LibStub('LibUIDropDownMenu-4.0')
local sharedMedia = LibStub("LibSharedMedia-3.0")

local _G = _G
local SetFont = ns.FontStringExtensions.SetFont

local defaultFontName = [[Interface\AddOns\WowUkrainizer\assets\Arsenal_Regular.ttf]]

local eventHandler = ns.EventHandler:new()

local unitTooltipTranslator, spellTooltipTranslator, spellbookFrameTranslator, classTalentFrameTranslator
local nameplateAndUnitFrameTranslator

local initialized = false

local function initializeOptions()
    _G.WowUkrainizer_Options = _G.WowUkrainizer_Options or {}
    _G.WowUkrainizer_Options.CustomFontFile = _G.WowUkrainizer_Options.CustomFontFile or defaultFontName
    if (_G.WowUkrainizer_Options.UseCustomFonts == nil) then
        _G.WowUkrainizer_Options.UseCustomFonts = true
    end
end

local function buildOptions()
    local options = {
        type = "group",
        name = "WowUkrainizer",
        args = {
            General = {
                order = 1,
                type = "group",
                name = "Загальні налаштування",
                childGroups = "tab",
                args = {
                    Sorting1 = {
                        name = "Загальні налаштування",
                        type = "group",
                        order = 1.1,
                        width = "double",
                        args = {
                            UIHeader = {
                                type = "header",
                                name = "Інтерфейс користувача",
                                order = 1
                            },
                            VerticalMargin1 = {
                                type = "description",
                                name = " ",
                                order = 2
                            },
                            UIHeaderDescription = {
                                type = "description",
                                name =
                                "Тут ви можете налаштувати, які частини інтерфейсу користувача будуть перекладені на українську мову. За замовчення інтерфейсу користувача перекладається повністью.",
                                fontSize = "small",
                                order = 3,
                                width = "full"
                            },
                            VerticalMargin2 = {
                                type = "description",
                                name = " ",
                                order = 4
                            },
                            TranslateClassTalentsFrame = {
                                type = "toggle",
                                name = "Вікно \"Спеціалізація та таланти\"",
                                order = 5,
                                width = "full",
                            },
                            SpellbookFrame = {
                                type = "toggle",
                                name = "Вікно \"Книга здібностей\"",
                                order = 6,
                                width = 1.2,
                            },
                            -- TranslateSpellNameInSpellbookHorizaontalMargin = {
                            --     type = "description",
                            --     name = " ",
                            --     fontSize = "small",
                            --     order = 7,
                            --     width = 40
                            -- },
                            TranslateSpellNameInSpellbook = {
                                type = "toggle",
                                name = "Перекладати назви здібностей",
                                order = 8,
                                width = 2,
                            },
                            VerticalMargin3 = {
                                type = "description",
                                name = " ",
                                order = 9,
                                width = "full",
                            },
                            TooltipsHeader = {
                                type = "header",
                                name = "Екрані підказки",
                                order = 10
                            },
                            VerticalMargin4 = {
                                type = "description",
                                name = " ",
                                order = 11
                            },
                            TranslateUnitTooltips = {
                                type = "toggle",
                                name = "Перекладати підказки НІП",
                                order = 12,
                                width = "full",
                            },
                            TranslateSpellTooltips = {
                                type = "toggle",
                                name = "Перекладати підказки здібностей та талантів",
                                order = 13,
                                width = "full",
                            },
                            VerticalMargin5 = {
                                type = "description",
                                name = " ",
                                order = 14,
                                width = "full"
                            },
                            HorizaontalMargin0 = {
                                type = "description",
                                name = " ",
                                fontSize = "medium",
                                order = 14.1,
                                width = 0.2
                            },
                            HighlightSpellNameInDescription = {
                                type = "toggle",
                                name = "Виділяти голубим кольором назви здібностей (талантів) в описі",
                                order = 14.2,
                                width = 3.4,
                            },
                            -- Spell Name
                            HorizaontalMargin1 = {
                                type = "description",
                                name = " ",
                                fontSize = "medium",
                                order = 15,
                                width = 0.2
                            },
                            TooltipSpellName_Desc = {
                                type = "description",
                                name = "Якою мовою виводити назви талантів та здібностей",
                                fontSize = "medium",
                                order = 16,
                                width = 2
                            },
                            TooltipSpellName = {
                                type = "select",
                                name = "",
                                width = 1,
                                order = 17,
                                values = {
                                    ["en"] = "Англійська",
                                    ["ua"] = "Українська",
                                    ["both"] = "Обидві",
                                },
                            },
                            TooltipSpellName_End = {
                                type = "description",
                                name = " ",
                                fontSize = "medium",
                                order = 18,
                                width = 0.4
                            },
                            -- Spell Description
                            HorizontalMargin2 = {
                                type = "description",
                                name = " ",
                                fontSize = "medium",
                                order = 19,
                                width = 0.2
                            },
                            TooltipSpellDescription_Desc = {
                                type = "description",
                                name = "Якою мовою виводити опис талантів та здібностей",
                                fontSize = "medium",
                                order = 20,
                                width = 2
                            },
                            TooltipSpellDescription = {
                                type = "select",
                                name = "",
                                width = 1,
                                order = 21,
                                values = {
                                    ["en"] = "Англійська",
                                    ["ua"] = "Українська",
                                },
                            },
                        }
                    },
                    FontSettings = {
                        name = "Налаштувати шрифти",
                        type = "group",
                        order = 1.1,
                        width = "double",
                        args = {
                            UseDefaultFonts = {
                                type = "toggle",
                                name = "Використовувати стандартні шрифти",
                                order = 1.11,
                                width = "double",
                            },
                            HorizaontalMargin1 = {
                                type = "description",
                                name = " ",
                                fontSize = "large",
                                order = 1.111,
                                width = "half"
                            },
                            ResetFonts = {
                                order = 1.112,
                                name = "За замовченням",
                                type = "execute",
                            },
                            UserFontHeader = {
                                type = "header",
                                name = "",
                                order = 1.113
                            },
                            UserFontWarning = {
                                type = "description",
                                name =
                                "Увага! Перевірте що вибраний вами шрифт підтримує кирилицю. Інакше це призведе візуальних багів з відображенням тексту.",
                                order = 1.12,
                                width = "full"
                            },
                            VerticalMargin1 = {
                                type = "description",
                                name = " ",
                                order = 1.131
                            },
                            UserFont = {
                                type = "select",
                                name = "Доступні шрифти",
                                width = "double",
                                order = 1.132,
                                values = {
                                    ["ignore"] = "Ignore",
                                    ["group"] = "Group",
                                    ["interleave"] = "Interleave",
                                },
                            },
                            VerticalMargin2 = {
                                type = "description",
                                name = " ",
                                order = 1.133
                            },
                            FontScaleHeader = {
                                type = "header",
                                name = "Розмір шрифту (%)",
                                order = 1.14
                            },
                            FontScaleDescription = {
                                type = "description",
                                name = "Загальний",
                                order = 1.151,
                                width = "1",
                                fontSize = "medium"
                            },
                            FontScale = {
                                type = "range",
                                name = "",
                                order = 1.152,
                                min = 0.5,
                                max = 3,
                                bigStep = 0.01,
                                width = "double"
                            },
                            TooltipHeaderFontScaleDescription = {
                                type = "description",
                                name = "Заголовок екранних підказок",
                                order = 1.161,
                                width = "1",
                                fontSize = "medium"
                            },
                            TooltipHeaderFontScale = {
                                type = "range",
                                name = "",
                                order = 1.162,
                                min = 0.5,
                                max = 3,
                                bigStep = 0.01,
                                width = "double"
                            },
                            TooltipFontScaleDescription = {
                                type = "description",
                                name = "Текст екранних підказок",
                                order = 1.171,
                                width = "1",
                                fontSize = "medium"
                            },
                            TooltipFontScale = {
                                type = "range",
                                name = "",
                                order = 1.172,
                                min = 0.5,
                                max = 3,
                                bigStep = 0.01,
                                width = "double"
                            },
                            VerticalMargin3 = {
                                type = "description",
                                name = " ",
                                fontSize = "large",
                                order = 1.81
                            },
                            VerticalMargin4 = {
                                type = "description",
                                name = " ",
                                fontSize = "large",
                                order = 1.82
                            },
                            VerticalMargin5 = {
                                type = "description",
                                name = " ",
                                fontSize = "large",
                                order = 1.83
                            },
                        }
                    },
                }
            }
        }
    }

    ns.Options = options
end

local function createInterfaceOptions()
    buildOptions()

    local namespace = "WowUkrainizer"
    LibStub("AceConfig-3.0"):RegisterOptionsTable(namespace, ns.Options, { "wu", "wowukrainizer" })

    local configDialog = LibStub("AceConfigDialog-3.0")
    configDialog:AddToBlizOptions(namespace, nil, nil, "General")
end

local function setGameFonts(fontName)
    print(fontName)

    local tooltipFontScale = 1.1
    local tooltipHeaderFontScale = 1.15
    local fontScale = 1.1

    SetFont(SystemFont_Shadow_Med1, fontName, fontScale)
    SetFont(SystemFont_Shadow_Small, fontName, fontScale)
    SetFont(SystemFont_Shadow_Med2, fontName, fontScale)
    SetFont(SystemFont_Shadow_Large2, fontName, fontScale)
    SetFont(Game30Font, fontName, fontScale)

    -- Tooltips
    SetFont(GameTooltipHeader, fontName, tooltipHeaderFontScale)
    SetFont(Tooltip_Med, fontName, tooltipFontScale)
    SetFont(Tooltip_Small, fontName, tooltipFontScale)
end

local function initializeAddon()
    if (initialized) then return end

    sharedMedia:Register("font", "Arsenal Regular", [[Interface\AddOns\WowUkrainizer\assets\Arsenal_Regular.ttf]])
    sharedMedia:Register("font", "Arsenal Bold", [[Interface\AddOns\WowUkrainizer\assets\Arsenal_Bold.ttf]])

    initializeOptions()
    createInterfaceOptions()

    if (_G.WowUkrainizer_Options.UseCustomFonts) then
        setGameFonts(_G.WowUkrainizer_Options.CustomFontFile)
    end

    -- Tooltips
    unitTooltipTranslator = ns.Translators.UnitTooltipTranslator:new(Enum.TooltipDataType.Unit)
    spellTooltipTranslator = ns.Translators.SpellTooltipTranslator:new(Enum.TooltipDataType.Spell)
    -- Frames
    spellbookFrameTranslator = ns.Translators.SpellbookFrameTranslator:new()
    classTalentFrameTranslator = ns.Translators.ClassTalentFrameTranslator:new()
    -- Other
    nameplateAndUnitFrameTranslator = ns.Translators.NameplateAndUnitFrameTranslator:new()
end

local function OnAddOnLoaded(_, name)
    local function OnPlayerLogin()
        -- Tooltips
        unitTooltipTranslator:SetEnabled(true)
        spellTooltipTranslator:SetEnabled(true)
        -- Frames
        spellbookFrameTranslator:SetEnabled(true)
        classTalentFrameTranslator:SetEnabled(true)
        -- Other
        nameplateAndUnitFrameTranslator:SetEnabled(true)
    end

    if (name == addonName) then
        initializeAddon()
        if not IsLoggedIn() then
            eventHandler:Register(OnPlayerLogin, "PLAYER_LOGIN")
        else
            OnPlayerLogin()
        end
    end
end

eventHandler:Register(OnAddOnLoaded, "ADDON_LOADED")
