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
                    GeneralSettings = {
                        name = "Загальні налаштування",
                        type = "group",
                        order = 1,
                        width = "double",
                        args = {
                            UIHeader = {
                                type = "header",
                                name = "Інтерфейс користувача",
                                order = 1
                            },
                            VerticalMargin_1 = {
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
                            VerticalMargin_2 = {
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
                                name = "Вікно \"Книга здібностей та професії\"",
                                order = 6,
                                width = "full",
                            },

                            VerticalMargin_3 = {
                                type = "description",
                                name = " ",
                                order = 7,
                                width = "full"
                            },
                            -- Spell Name in spellbook
                            HorizaontalMargin_1 = {
                                type = "description",
                                name = " ",
                                fontSize = "medium",
                                order = 8,
                                width = 0.2
                            },
                            SpellNameLangInSpellbook_Desc = {
                                type = "description",
                                name = "Якою мовою виводити назви здібностей",
                                fontSize = "medium",
                                order = 9,
                                width = 2
                            },
                            SpellNameLangInSpellbook = {
                                type = "select",
                                name = "",
                                width = 1,
                                order = 10,
                                values = {
                                    ["en"] = "Англійська",
                                    ["ua"] = "Українська",
                                },
                            },
                            SpellNameLangInSpellbook_End = {
                                type = "description",
                                name = " ",
                                fontSize = "medium",
                                order = 11,
                                width = 0.4
                            },
                            VerticalMargin3 = {
                                type = "description",
                                name = " ",
                                order = 12,
                                width = "full",
                            },
                            TooltipsHeader = {
                                type = "header",
                                name = "Екрані підказки",
                                order = 13
                            },
                            VerticalMargin4 = {
                                type = "description",
                                name = " ",
                                order = 14
                            },
                            TranslateUnitTooltips = {
                                type = "toggle",
                                name = "Перекладати підказки НІП",
                                order = 15,
                                width = "full",
                            },
                            TranslateSpellTooltips = {
                                type = "toggle",
                                name = "Перекладати підказки здібностей та талантів",
                                order = 16,
                                width = "full",
                            },
                            VerticalMargin5 = {
                                type = "description",
                                name = " ",
                                order = 17,
                                width = "full"
                            },
                            -- Spell Name
                            HorizaontalMargin1 = {
                                type = "description",
                                name = " ",
                                fontSize = "medium",
                                order = 18,
                                width = 0.2
                            },
                            TooltipSpellName_Desc = {
                                type = "description",
                                name = "Якою мовою виводити назви талантів та здібностей",
                                fontSize = "medium",
                                order = 19,
                                width = 2
                            },
                            TooltipSpellName = {
                                type = "select",
                                name = "",
                                width = 1,
                                order = 20,
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
                                order = 21,
                                width = 0.4
                            },
                            -- Spell Description
                            HorizontalMargin2 = {
                                type = "description",
                                name = " ",
                                fontSize = "medium",
                                order = 22,
                                width = 0.2
                            },
                            TooltipSpellDescription_Desc = {
                                type = "description",
                                name = "Якою мовою виводити опис талантів та здібностей",
                                fontSize = "medium",
                                order = 23,
                                width = 2
                            },
                            TooltipSpellDescription = {
                                type = "select",
                                name = "",
                                width = 1,
                                order = 24,
                                values = {
                                    ["en"] = "Англійська",
                                    ["ua"] = "Українська",
                                },
                            },
                            TooltipSpellDescription_End = {
                                type = "description",
                                name = " ",
                                fontSize = "medium",
                                order = 25,
                                width = 0.4
                            },
                            HorizaontalMargin0 = {
                                type = "description",
                                name = " ",
                                fontSize = "medium",
                                order = 26,
                                width = 0.2
                            },
                            HighlightSpellNameInDescription = {
                                type = "toggle",
                                name = "Виділяти голубим кольором назви здібностей (талантів) в описі",
                                order = 27,
                                width = 3.4,
                            },
                        }
                    },
                    FontSettings = {
                        name = "Налаштувати шрифти",
                        type = "group",
                        order = 1,
                        width = "double",
                        args = {
                            UseDefaultFonts = {
                                type = "toggle",
                                name = "Використовувати стандартні шрифти",
                                order = 1,
                                width = "double",
                            },
                            HorizaontalMargin1 = {
                                type = "description",
                                name = " ",
                                fontSize = "large",
                                order = 2,
                                width = "half"
                            },
                            ResetFonts = {
                                order = 3,
                                name = "За замовченням",
                                type = "execute",
                            },
                            UserFontHeader = {
                                type = "header",
                                name = "",
                                order = 4
                            },
                            UserFontWarning = {
                                type = "description",
                                name =
                                "Увага! Перевірте що вибраний вами шрифт підтримує кирилицю. Інакше це призведе візуальних багів з відображенням тексту.",
                                order = 5,
                                width = "full"
                            },
                            VerticalMargin1 = {
                                type = "description",
                                name = " ",
                                order = 6
                            },
                            UserFont = {
                                type = "select",
                                name = "Доступні шрифти",
                                width = "double",
                                order = 7,
                                values = sharedMedia:HashTable("font"),
                                dialogControl = "LSM30_Font",
                            },
                            VerticalMargin2 = {
                                type = "description",
                                name = " ",
                                order = 8
                            },
                            FontScaleHeader = {
                                type = "header",
                                name = "Розмір шрифту (%)",
                                order = 9
                            },
                            FontScaleDescription = {
                                type = "description",
                                name = "Загальний",
                                order = 10,
                                width = "1",
                                fontSize = "medium"
                            },
                            FontScale = {
                                type = "range",
                                name = "",
                                order = 11,
                                min = 0.5,
                                max = 3,
                                bigStep = 0.01,
                                width = "double"
                            },
                            TooltipHeaderFontScaleDescription = {
                                type = "description",
                                name = "Заголовок екранних підказок",
                                order = 12,
                                width = "1",
                                fontSize = "medium"
                            },
                            TooltipHeaderFontScale = {
                                type = "range",
                                name = "",
                                order = 13,
                                min = 0.5,
                                max = 3,
                                bigStep = 0.01,
                                width = "double"
                            },
                            TooltipFontScaleDescription = {
                                type = "description",
                                name = "Текст екранних підказок",
                                order = 14,
                                width = "1",
                                fontSize = "medium"
                            },
                            TooltipFontScale = {
                                type = "range",
                                name = "",
                                order = 15,
                                min = 0.5,
                                max = 3,
                                bigStep = 0.01,
                                width = "double"
                            },
                            VerticalMargin3 = {
                                type = "description",
                                name = " ",
                                fontSize = "large",
                                order = 16
                            },
                            VerticalMargin4 = {
                                type = "description",
                                name = " ",
                                fontSize = "large",
                                order = 17
                            },
                            VerticalMargin5 = {
                                type = "description",
                                name = " ",
                                fontSize = "large",
                                order = 18
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
