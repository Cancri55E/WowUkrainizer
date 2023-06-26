local _, ns = ...;

--local _G = _G

local sharedMedia = LibStub("LibSharedMedia-3.0")

local settingsProvider = class("SettingsProvider");
ns.SettingsProvider = settingsProvider

local defaultOptions = {
    -- Font
    UserFontName = "Arsenal Regular",
    FontScaleInPercent = 1.1,
    TooltipHeaderFontScaleInPercent = 1.15,
    TooltipFontScaleInPercent = 1.1,
    UseDefaultFonts = false,
    -- General
    TranslateClassTalentsFrame = true,
    TranslateSpellbookFrame = true,
    TranslateNameplatesAndUnitFrames = true,
    SpellNameLangInSpellbook = "ua",
    HighlightSpellNameInDescription = true,
    TranslateUnitTooltips = true,
    TranslateSpellTooltips = true,
    TooltipSpellLangInName = "both",
    TooltipSpellLangInDescription = "ua"
}

function settingsProvider:Load()
    WowUkrainizer_Options = WowUkrainizer_Options or {}

    local def = self.GetDefaultOptions()

    -- Font settings
    WowUkrainizer_Options.UserFontName = WowUkrainizer_Options.UserFontName or def.UserFontName

    WowUkrainizer_Options.FontScaleInPercent =
        WowUkrainizer_Options.FontScaleInPercent or def.FontScaleInPercent

    WowUkrainizer_Options.TooltipHeaderFontScaleInPercent =
        WowUkrainizer_Options.TooltipHeaderFontScaleInPercent or def.TooltipHeaderFontScaleInPercent

    WowUkrainizer_Options.TooltipFontScaleInPercent =
        WowUkrainizer_Options.TooltipFontScaleInPercent or def.TooltipFontScaleInPercent

    if (WowUkrainizer_Options.UseDefaultFonts == nil) then
        WowUkrainizer_Options.UseDefaultFonts = def.UseDefaultFonts
    end

    -- General settings
    if (WowUkrainizer_Options.TranslateClassTalentsFrame == nil) then
        WowUkrainizer_Options.TranslateClassTalentsFrame = def.TranslateClassTalentsFrame
    end

    if (WowUkrainizer_Options.TranslateSpellbookFrame == nil) then
        WowUkrainizer_Options.TranslateSpellbookFrame = def.TranslateSpellbookFrame
    end

    if (WowUkrainizer_Options.TranslateNameplatesAndUnitFrames == nil) then
        WowUkrainizer_Options.TranslateNameplatesAndUnitFrames = def.TranslateNameplatesAndUnitFrames
    end

    WowUkrainizer_Options.SpellNameLangInSpellbook =
        WowUkrainizer_Options.SpellNameLangInSpellbook or def.SpellNameLangInSpellbook

    if (WowUkrainizer_Options.TranslateSpellTooltips == nil) then
        WowUkrainizer_Options.TranslateSpellTooltips = def.TranslateSpellTooltips
    end

    if (WowUkrainizer_Options.TranslateUnitTooltips == nil) then
        WowUkrainizer_Options.TranslateUnitTooltips = def.TranslateUnitTooltips
    end

    if (WowUkrainizer_Options.HighlightSpellNameInDescription == nil) then
        WowUkrainizer_Options.HighlightSpellNameInDescription = def.HighlightSpellNameInDescription
    end

    WowUkrainizer_Options.TooltipSpellLangInName =
        WowUkrainizer_Options.TooltipSpellLangInName or def.TooltipSpellLangInName

    WowUkrainizer_Options.TooltipSpellLangInDescription =
        WowUkrainizer_Options.TooltipSpellLangInDescription or def.TooltipSpellLangInDescription
end

function settingsProvider:Build()
    local function addVerticalMargin(order)
        return {
            type = "description",
            name = " ",
            fontSize = "medium",
            order = order,
            width = 3.6
        }
    end

    ns.Options = {
        type = "group",
        name = "WowUkrainizer",
        args = {
            General = {
                order = 1,
                type = "group",
                name = "Налаштування",
                childGroups = "tab",
                args = {
                    Commands = {
                        order = 1,
                        type = "group",
                        name = " ",
                        inline = true,
                        args = {
                            SettingsWarning = {
                                type = "description",
                                name =
                                [[Увага!
Зміни в налаштуваннях будуть застосовані тільки після перезавантаження інтерфейсу або виконання команди /reload.
Будь ласка, зверніть увагу, що без цього кроку нові налаштування не вступлять в силу.

]],
                                fontSize = "small",
                                order = 1,
                                width = "full"
                            },
                            ResetInterface = {
                                order = 3,
                                name = "Перезавантажити",
                                type = "execute",
                                func = function() ReloadUI() end,
                            },
                            ResetFonts = {
                                order = 4,
                                name = "За замовчуванням",
                                desc =
                                [[Ця кнопка скидає всі налаштування до стандартних значень, встановлених розробниками аддона.

Після натискання всі ваші поточні налаштування будуть втрачені, і будуть встановлені значення за замовчуванням.]],
                                type = "execute",
                                func = function()
                                    StaticPopup_Show("WOW_UKRAINIZAER_RESET_SETTINGS");
                                end,
                            },
                        }
                    },
                    GeneralSettings = {
                        name = "Загальні налаштування",
                        type = "group",
                        order = 1,
                        width = "double",
                        args = {
                            TranslateClassTalentsFrame = {
                                type = "toggle",
                                name = "Перекладати вікно \"Спеціалізація та таланти\"",
                                order = 3,
                                width = 3.6,
                                get = function(_) return WowUkrainizer_Options.TranslateClassTalentsFrame end,
                                set = function(_, value) WowUkrainizer_Options.TranslateClassTalentsFrame = value end,
                            },
                            TranslateSpellbookFrame = {
                                type = "toggle",
                                name = "Перекладати вікно \"Книга здібностей та професії\"",
                                order = 4,
                                width = 3.6,
                                get = function(_) return WowUkrainizer_Options.TranslateSpellbookFrame end,
                                set = function(_, value) WowUkrainizer_Options.TranslateSpellbookFrame = value end,
                            },

                            -- Spell Name in spellbook
                            SpellNameLangInSpellbook_Desc = {
                                type = "description",
                                name = "Якою мовою виводити назви здібностей",
                                fontSize = "medium",
                                order = 9,
                                width = 2.15
                            },
                            SpellNameLangInSpellbook = {
                                type = "select",
                                name = "",
                                width = 1.3,
                                order = 10,
                                values = {
                                    ["en"] = "Англійська",
                                    ["ua"] = "Українська",
                                },
                                get = function(_) return WowUkrainizer_Options.SpellNameLangInSpellbook end,
                                set = function(_, value) WowUkrainizer_Options.SpellNameLangInSpellbook = value end,
                                disabled = function()
                                    return not WowUkrainizer_Options.TranslateSpellbookFrame
                                end,
                            },

                            TranslateNameplatesAndUnitFrames = {
                                type = "toggle",
                                name = "Перекладати Nameplates та Unit Frames",
                                desc = "Крім стандартних Nameplates, наш аддон також сумісний з Plater та ElvUI.",
                                order = 11,
                                width = 3.6,
                                get = function(_) return WowUkrainizer_Options.TranslateNameplatesAndUnitFrames end,
                                set = function(_, value) WowUkrainizer_Options.TranslateNameplatesAndUnitFrames = value end,
                            },

                            VerticalMargin = addVerticalMargin(12),
                            TooltipsHeader = {
                                type = "header",
                                name = "Екрані підказки",
                                order = 13
                            },

                            TranslateUnitTooltips = {
                                type = "toggle",
                                name = "Перекладати підказки НІП",
                                order = 15,
                                width = 3.6,
                                get = function(_) return WowUkrainizer_Options.TranslateUnitTooltips end,
                                set = function(_, value) WowUkrainizer_Options.TranslateUnitTooltips = value end,
                            },
                            TranslateSpellTooltips = {
                                type = "toggle",
                                name = "Перекладати підказки здібностей та талантів",
                                order = 16,
                                width = 3.6,
                                get = function(_) return WowUkrainizer_Options.TranslateSpellTooltips end,
                                set = function(_, value) WowUkrainizer_Options.TranslateSpellTooltips = value end,
                            },

                            -- Spell Name
                            TooltipSpellLangInName_Desc = {
                                type = "description",
                                name = "Мова якою виводяться назви талантів та здібностей",
                                fontSize = "medium",
                                order = 19,
                                width = 2.15
                            },
                            TooltipSpellLangInName = {
                                type = "select",
                                name = "",
                                width = 1.3,
                                order = 20,
                                values = {
                                    ["en"] = "Англійська",
                                    ["ua"] = "Українська",
                                    ["both"] = "Обидві (спочатку англійська)",
                                },
                                get = function(_) return WowUkrainizer_Options.TooltipSpellLangInName end,
                                set = function(_, value) WowUkrainizer_Options.TooltipSpellLangInName = value end,
                                disabled = function()
                                    return not WowUkrainizer_Options.TranslateSpellTooltips
                                end,
                            },

                            -- Spell Description
                            TooltipSpellLangInDescription_Desc = {
                                type = "description",
                                name = "Мова якою виводиться опис талантів та здібностей",
                                fontSize = "medium",
                                order = 23,
                                width = 2.15
                            },
                            TooltipSpellLangInDescription = {
                                type = "select",
                                name = "",
                                width = 1.3,
                                order = 24,
                                values = {
                                    ["en"] = "Англійська",
                                    ["ua"] = "Українська",
                                },
                                get = function(_) return WowUkrainizer_Options.TooltipSpellLangInDescription end,
                                set = function(_, value) WowUkrainizer_Options.TooltipSpellLangInDescription = value end,
                                disabled = function()
                                    return not WowUkrainizer_Options.TranslateSpellTooltips
                                end,
                            },

                            HighlightSpellNameInDescription = {
                                type = "toggle",
                                name = "Виділяти голубим кольором назви здібностей (талантів) в описі",
                                order = 27,
                                width = 3.45,
                                get = function(_) return WowUkrainizer_Options.HighlightSpellNameInDescription end,
                                set = function(_, value) WowUkrainizer_Options.HighlightSpellNameInDescription = value end,
                                disabled = function()
                                    return not WowUkrainizer_Options.TranslateSpellTooltips
                                end,
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
                                desc =
                                [[Якщо ви вже використовуєте будь-яку глобальну модифікацію, яка замінює шрифт, наприклад ElvUI, рекомендується встановити цю позначку, щоб уникнути можливих конфліктів.

Всі налаштування шрифтів слід проводити безпосередньо через глобальну модифікацію.

Це допоможе забезпечити стабільність та сумісність між різними аддонами.]],
                                order = 1,
                                width = "double",
                                get = function(_) return WowUkrainizer_Options.UseDefaultFonts end,
                                set = function(_, value) WowUkrainizer_Options.UseDefaultFonts = value end,
                            },
                            HorizaontalMargin1 = {
                                type = "description",
                                name = " ",
                                fontSize = "large",
                                order = 2,
                                width = "half"
                            },
                            UserFontHeader = {
                                type = "header",
                                name = "",
                                order = 4
                            },
                            UserFontWarning = {
                                type = "description",
                                name =
                                [[Перевірте що вибраний вами шрифт підтримує кирилицю. Інакше це призведе візуальних багів з відображенням тексту.
Ви можете використати аддон LibSharedMedia-3.0 для додавання нових шрифтів.
                                ]],
                                order = 5,
                                width = "full"
                            },
                            UserFont = {
                                type = "select",
                                name = "Доступні шрифти",
                                width = "double",
                                order = 7,
                                values = sharedMedia:HashTable("font"),
                                dialogControl = "LSM30_Font",
                                get = function(_) return WowUkrainizer_Options.UserFontName end,
                                set = function(_, value) WowUkrainizer_Options.UserFontName = value end,
                                disabled = function()
                                    return WowUkrainizer_Options.UseDefaultFonts
                                end,
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
                                width = "double",
                                get = function(_) return WowUkrainizer_Options.FontScaleInPercent end,
                                set = function(_, value) WowUkrainizer_Options.FontScaleInPercent = value end,
                                disabled = function()
                                    return WowUkrainizer_Options.UseDefaultFonts
                                end,
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
                                width = "double",
                                get = function(_)
                                    return WowUkrainizer_Options
                                        .TooltipHeaderFontScaleInPercent
                                end,
                                set = function(_, value)
                                    WowUkrainizer_Options.TooltipHeaderFontScaleInPercent =
                                        value
                                end,
                                disabled = function()
                                    return WowUkrainizer_Options.UseDefaultFonts
                                end,
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
                                width = "double",
                                get = function(_) return WowUkrainizer_Options.TooltipFontScaleInPercent end,
                                set = function(_, value)
                                    WowUkrainizer_Options.TooltipFontScaleInPercent =
                                        value
                                end,
                                disabled = function()
                                    return WowUkrainizer_Options.UseDefaultFonts
                                end,
                            },
                        }
                    },
                }
            }
        }
    }
end

function settingsProvider:Reset()
    WowUkrainizer_Options = self.GetDefaultOptions()
    ReloadUI()
end

function settingsProvider.GetDefaultFontFile() return [[Interface\AddOns\WowUkrainizer\assets\Arsenal_Regular.ttf]] end

function settingsProvider.GetDefaultOptions() return defaultOptions end

function settingsProvider.GetFontSettings()
    local fontName = settingsProvider.GetDefaultFontFile()
    for key, value in pairs(sharedMedia:HashTable("font")) do
        if (key == WowUkrainizer_Options.UserFontName) then fontName = value end
    end

    local fontScale = WowUkrainizer_Options.FontScaleInPercent
    local tooltipHeaderFontScale = WowUkrainizer_Options.TooltipHeaderFontScaleInPercent
    local tooltipFontScale = WowUkrainizer_Options.TooltipFontScaleInPercent

    return WowUkrainizer_Options.UseDefaultFonts, fontName, fontScale, tooltipHeaderFontScale, tooltipFontScale
end

function settingsProvider.GetTranslatorsState()
    return WowUkrainizer_Options.TranslateClassTalentsFrame, WowUkrainizer_Options.TranslateSpellbookFrame,
        WowUkrainizer_Options.TranslateNameplatesAndUnitFrames, WowUkrainizer_Options.TranslateSpellTooltips,
        WowUkrainizer_Options.TranslateUnitTooltips
end

function settingsProvider.IsNeedTranslateSpellNameInSpellbook()
    return WowUkrainizer_Options.SpellNameLangInSpellbook == "ua"
end

function settingsProvider.IsNeedTranslateSpellDescriptionInTooltip()
    return WowUkrainizer_Options.TooltipSpellLangInDescription == "ua"
end

function settingsProvider.IsNeedHighlightSpellNameInDescription()
    return WowUkrainizer_Options.HighlightSpellNameInDescription == true
end

function settingsProvider.GetTooltipSpellLangInName()
    return WowUkrainizer_Options.TooltipSpellLangInName
end
