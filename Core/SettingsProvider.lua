local addonName, ns = ...;

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
    -- UI
    TranslateClassTalentsFrame = true,
    TranslateSpellbookFrame = true,
    TranslateQuestAndObjectivesFrame = true,
    TranslateNameplatesAndUnitFrames = true,
    SpellNameLangInSpellbook = "ua",
    -- Tooltips
    HighlightSpellNameInDescription = true,
    TranslateUnitTooltips = true,
    TranslateSpellTooltips = true,
    TooltipSpellLangInName = "both",
    TooltipSpellLangInDescription = "ua",
    -- Gameplay
    TranslateMovieSubtitles = true,

    TranslateNpcDialogs = true,
    NpcDialogTextLang = "ua",
    NpcDialogVoiceOverLang = "ua",

    TranslateCinematics = true,
    CinematicTextLang = "ua",
    CinematicVoiceOverLang = "ua",
}

function settingsProvider:Load()
    WowUkrainizer_Options = WowUkrainizer_Options or {}

    local def = self.GetDefaultOptions()

    -- Font settings
    WowUkrainizer_Options.UserFontName =
        WowUkrainizer_Options.UserFontName or def.UserFontName

    WowUkrainizer_Options.FontScaleInPercent =
        WowUkrainizer_Options.FontScaleInPercent or def.FontScaleInPercent

    WowUkrainizer_Options.TooltipHeaderFontScaleInPercent =
        WowUkrainizer_Options.TooltipHeaderFontScaleInPercent or def.TooltipHeaderFontScaleInPercent

    WowUkrainizer_Options.TooltipFontScaleInPercent =
        WowUkrainizer_Options.TooltipFontScaleInPercent or def.TooltipFontScaleInPercent

    WowUkrainizer_Options.UseDefaultFonts =
        WowUkrainizer_Options.UseDefaultFonts or def.UseDefaultFonts

    -- General settings
    WowUkrainizer_Options.TranslateClassTalentsFrame =
        WowUkrainizer_Options.TranslateClassTalentsFrame or def.TranslateClassTalentsFrame

    WowUkrainizer_Options.TranslateSpellbookFrame =
        WowUkrainizer_Options.TranslateSpellbookFrame or def.TranslateSpellbookFrame

    WowUkrainizer_Options.TranslateNameplatesAndUnitFrames =
        WowUkrainizer_Options.TranslateNameplatesAndUnitFrames or def.TranslateNameplatesAndUnitFrames

    if (WowUkrainizer_Options.TranslateQuestAndObjectivesFrame == nil) then
        WowUkrainizer_Options.TranslateQuestAndObjectivesFrame = def.TranslateQuestAndObjectivesFrame
    end

    WowUkrainizer_Options.SpellNameLangInSpellbook =
        WowUkrainizer_Options.SpellNameLangInSpellbook or def.SpellNameLangInSpellbook

    WowUkrainizer_Options.TranslateSpellTooltips =
        WowUkrainizer_Options.TranslateSpellTooltips or def.TranslateSpellTooltips

    WowUkrainizer_Options.TranslateUnitTooltips =
        WowUkrainizer_Options.TranslateUnitTooltips or def.TranslateUnitTooltips

    WowUkrainizer_Options.HighlightSpellNameInDescription =
        WowUkrainizer_Options.HighlightSpellNameInDescription or def.HighlightSpellNameInDescription

    WowUkrainizer_Options.TooltipSpellLangInName =
        WowUkrainizer_Options.TooltipSpellLangInName or def.TooltipSpellLangInName

    WowUkrainizer_Options.TooltipSpellLangInDescription =
        WowUkrainizer_Options.TooltipSpellLangInDescription or def.TooltipSpellLangInDescription

    WowUkrainizer_Options.TranslateMovieSubtitles =
        WowUkrainizer_Options.TranslateMovieSubtitles or def.TranslateMovieSubtitles

    WowUkrainizer_Options.TranslateNpcDialogs =
        WowUkrainizer_Options.TranslateNpcDialogs or def.TranslateNpcDialogs

    WowUkrainizer_Options.NpcDialogTextLang =
        WowUkrainizer_Options.NpcDialogTextLang or def.NpcDialogTextLang

    WowUkrainizer_Options.NpcDialogVoiceOverLang =
        WowUkrainizer_Options.NpcDialogVoiceOverLang or def.NpcDialogVoiceOverLang

    WowUkrainizer_Options.TranslateCinematics =
        WowUkrainizer_Options.TranslateCinematics or def.TranslateCinematics

    WowUkrainizer_Options.CinematicTextLang =
        WowUkrainizer_Options.CinematicTextLang or def.CinematicTextLang

    WowUkrainizer_Options.CinematicVoiceOverLang =
        WowUkrainizer_Options.CinematicVoiceOverLang or def.CinematicVoiceOverLang
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

    local function createIncrementor()
        local x = 0
        return function()
            x = x + 1
            return x
        end
    end

    local releaseDate = tonumber(C_AddOns.GetAddOnMetadata(addonName, "X-ReleaseDate")) or 0
    local version = C_AddOns.GetAddOnMetadata(addonName, "Version")
    if string.match(version, "-[%w%d][%w%d][%w%d][%w%d][%w%d][%w%d][%w%d][%w%d]$") then
        version = "[alpha] " .. version
    elseif string.match(version, "-alpha$") then
        version = "[alpha] " .. string.gsub(version, "-alpha$", "")
    end

    local setContributorsPageOrder = createIncrementor()
    local setFontSettingsArgsOrder = createIncrementor()
    local setGeneralSettingsArgsOrder = createIncrementor()

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
                    Version = {
                        type = "description",
                        name = "Версія: " .. version .. " (" .. date("%d.%m.%y %H:%M:%S", releaseDate) .. ")",
                        fontSize = "small",
                        order = 1,
                        width = "full"
                    },
                    Commands = {
                        order = 2,
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
                                order = 2,
                                name = "Перезавантажити",
                                type = "execute",
                                func = function() ReloadUI() end,
                            },
                            ResetFonts = {
                                order = 3,
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
                        order = 3,
                        width = "double",
                        args = {
                            TranslateClassTalentsFrame = {
                                type = "toggle",
                                name = "Перекладати вікно \"Спеціалізація та таланти\"",
                                order = setGeneralSettingsArgsOrder(),
                                width = 3.6,
                                get = function(_) return WowUkrainizer_Options.TranslateClassTalentsFrame end,
                                set = function(_, value) WowUkrainizer_Options.TranslateClassTalentsFrame = value end,
                            },
                            TranslateSpellbookFrame = {
                                type = "toggle",
                                name = "Перекладати вікно \"Книга здібностей та професії\"",
                                order = setGeneralSettingsArgsOrder(),
                                width = 3.6,
                                get = function(_) return WowUkrainizer_Options.TranslateSpellbookFrame end,
                                set = function(_, value) WowUkrainizer_Options.TranslateSpellbookFrame = value end,
                            },

                            -- Spell Name in spellbook
                            SpellNameLangInSpellbook_Desc = {
                                type = "description",
                                name = "        Мова для назви здібності",
                                fontSize = "medium",
                                order = setGeneralSettingsArgsOrder(),
                                width = 2.15
                            },
                            SpellNameLangInSpellbook = {
                                type = "select",
                                name = "",
                                width = 1.3,
                                order = setGeneralSettingsArgsOrder(),
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

                            TranslateQuestAndObjectivesFrame = {
                                type = "toggle",
                                name = "Перекладати завдання",
                                desc = "",
                                order = setGeneralSettingsArgsOrder(),
                                width = 3.6,
                                get = function(_) return WowUkrainizer_Options.TranslateQuestAndObjectivesFrame end,
                                set = function(_, value) WowUkrainizer_Options.TranslateQuestAndObjectivesFrame = value end,
                            },

                            TranslateNameplatesAndUnitFrames = {
                                type = "toggle",
                                name = "Перекладати Nameplates та Unit Frames",
                                desc = "Крім стандартних Nameplates, наш аддон також сумісний з Plater та ElvUI.",
                                order = setGeneralSettingsArgsOrder(),
                                width = 3.6,
                                get = function(_) return WowUkrainizer_Options.TranslateNameplatesAndUnitFrames end,
                                set = function(_, value) WowUkrainizer_Options.TranslateNameplatesAndUnitFrames = value end,
                            },


                            GameplayVerticalMargin = addVerticalMargin(setGeneralSettingsArgsOrder()),
                            GameplayHeader = {
                                type = "header",
                                name = "Ігролад",
                                order = setGeneralSettingsArgsOrder()
                            },

                            TranslateMovieSubtitles = {
                                type = "toggle",
                                name = "Перекладати субтитри в відеороликах",
                                desc = "Відображає українські субтитри в відеороликах (pre-rendered)",
                                order = setGeneralSettingsArgsOrder(),
                                width = 3.6,
                                get = function(_) return WowUkrainizer_Options.TranslateMovieSubtitles end,
                                set = function(_, value) WowUkrainizer_Options.TranslateMovieSubtitles = value end,
                            },

                            TranslateNpcMessages = {
                                type = "toggle",
                                name = "Перекладати внутрішньоігрові діалоги",
                                desc = "Налаштувати мову тексту та аудіо для внутрішньоігрових "
                                    .. "діалогів (в чаті, в \"балакучій голові\" та в \"бульбашках\" над головами НІП)",
                                order = setGeneralSettingsArgsOrder(),
                                width = 3.6,
                                get = function(_) return WowUkrainizer_Options.TranslateNpcMessages end,
                                set = function(_, value) WowUkrainizer_Options.TranslateNpcMessages = value end,
                            },
                            NpcDialogTextLang_Desc = {
                                type = "description",
                                name = "        Мова субтитрів",
                                fontSize = "medium",
                                order = setGeneralSettingsArgsOrder(),
                                width = 2.15,
                            },
                            NpcDialogTextLang = {
                                type = "select",
                                name = "",
                                width = 1.3,
                                order = setGeneralSettingsArgsOrder(),
                                values = {
                                    ["en"] = "Англійська",
                                    ["ua"] = "Українська",
                                },
                                get = function(_) return WowUkrainizer_Options.NpcDialogTextLang end,
                                set = function(_, value) WowUkrainizer_Options.NpcDialogTextLang = value end,
                                disabled = function()
                                    return not WowUkrainizer_Options.TranslateNpcMessages
                                end,
                            },
                            NpcDialogVoiceOverLang_Desc = {
                                type = "description",
                                name = "        Мова озвучування",
                                fontSize = "medium",
                                order = setGeneralSettingsArgsOrder(),
                                width = 2.15
                            },
                            NpcDialogVoiceOverLang = {
                                type = "select",
                                name = "",
                                width = 1.3,
                                order = setGeneralSettingsArgsOrder(),
                                values = {
                                    ["en"] = "Англійська",
                                    ["ua"] = "Українська",
                                },
                                get = function(_) return WowUkrainizer_Options.NpcDialogVoiceOverLang end,
                                set = function(_, value) WowUkrainizer_Options.NpcDialogVoiceOverLang = value end,
                                disabled = function()
                                    return not WowUkrainizer_Options.TranslateNpcMessages
                                end,
                            },

                            TranslateCinematics = {
                                type = "toggle",
                                name = "Перекладати внутрішньоігрові кат-сцени",
                                desc = "Налаштувати мову тексту та аудіо для внутрішньоігрових "
                                    .. "кат-сцен які зроблені за допомогою ігрового рушія",
                                order = setGeneralSettingsArgsOrder(),
                                width = 3.6,
                                get = function(_) return WowUkrainizer_Options.TranslateCinematics end,
                                set = function(_, value) WowUkrainizer_Options.TranslateCinematics = value end,
                            },
                            CinematicTextLang_Desc = {
                                type = "description",
                                name = "        Мова субтитрів",
                                fontSize = "medium",
                                order = setGeneralSettingsArgsOrder(),
                                width = 2.15
                            },
                            CinematicTextLang = {
                                type = "select",
                                name = "",
                                width = 1.3,
                                order = setGeneralSettingsArgsOrder(),
                                values = {
                                    ["en"] = "Англійська",
                                    ["ua"] = "Українська",
                                },
                                get = function(_) return WowUkrainizer_Options.CinematicTextLang end,
                                set = function(_, value) WowUkrainizer_Options.CinematicTextLang = value end,
                                disabled = function()
                                    return not WowUkrainizer_Options.TranslateCinematics
                                end,
                            },
                            CinematicVoiceOverLang_Desc = {
                                type = "description",
                                name = "        Мова озвучування",
                                fontSize = "medium",
                                order = setGeneralSettingsArgsOrder(),
                                width = 2.15
                            },
                            CinematicVoiceOverLang = {
                                type = "select",
                                name = "",
                                width = 1.3,
                                order = setGeneralSettingsArgsOrder(),
                                values = {
                                    ["en"] = "Англійська",
                                    ["ua"] = "Українська",
                                },
                                get = function(_) return WowUkrainizer_Options.CinematicVoiceOverLang end,
                                set = function(_, value) WowUkrainizer_Options.CinematicVoiceOverLang = value end,
                                disabled = function()
                                    return not WowUkrainizer_Options.TranslateCinematics
                                end,
                            },


                            VerticalMargin = addVerticalMargin(setGeneralSettingsArgsOrder()),
                            TooltipsHeader = {
                                type = "header",
                                name = "Екрані підказки",
                                order = setGeneralSettingsArgsOrder()
                            },

                            TranslateUnitTooltips = {
                                type = "toggle",
                                name = "Перекладати підказки НІП",
                                order = setGeneralSettingsArgsOrder(),
                                width = 3.6,
                                get = function(_) return WowUkrainizer_Options.TranslateUnitTooltips end,
                                set = function(_, value) WowUkrainizer_Options.TranslateUnitTooltips = value end,
                            },
                            TranslateSpellTooltips = {
                                type = "toggle",
                                name = "Перекладати підказки здібностей та талантів",
                                order = setGeneralSettingsArgsOrder(),
                                width = 3.6,
                                get = function(_) return WowUkrainizer_Options.TranslateSpellTooltips end,
                                set = function(_, value) WowUkrainizer_Options.TranslateSpellTooltips = value end,
                            },

                            HighlightSpellNameInDescriptionOffset = {
                                type = "description",
                                name = " ",
                                fontSize = "medium",
                                order = setGeneralSettingsArgsOrder(),
                                width = 0.14
                            },

                            HighlightSpellNameInDescription = {
                                type = "toggle",
                                name = "Виділяти блакитним кольором назви здібностей та талантів в описі",
                                order = setGeneralSettingsArgsOrder(),
                                width = 3.3,
                                get = function(_) return WowUkrainizer_Options.HighlightSpellNameInDescription end,
                                set = function(_, value) WowUkrainizer_Options.HighlightSpellNameInDescription = value end,
                                disabled = function()
                                    return not WowUkrainizer_Options.TranslateSpellTooltips
                                end,
                            },

                            -- Spell Name
                            TooltipSpellLangInName_Desc = {
                                type = "description",
                                name = "        Мова для назви талантів та здібностей",
                                fontSize = "medium",
                                order = setGeneralSettingsArgsOrder(),
                                width = 2.15
                            },
                            TooltipSpellLangInName = {
                                type = "select",
                                name = "",
                                width = 1.3,
                                order = setGeneralSettingsArgsOrder(),
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
                                name = "        Мова для опису талантів та здібностей",
                                fontSize = "medium",
                                order = setGeneralSettingsArgsOrder(),
                                width = 2.15
                            },
                            TooltipSpellLangInDescription = {
                                type = "select",
                                name = "",
                                width = 1.3,
                                order = setGeneralSettingsArgsOrder(),
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
                        }
                    },
                    FontSettings = {
                        name = "Налаштувати шрифти",
                        type = "group",
                        order = 4,
                        width = "double",
                        args = {
                            UseDefaultFonts = {
                                type = "toggle",
                                name = "Використовувати стандартні шрифти",
                                desc =
                                [[Якщо ви вже використовуєте будь-яку глобальну модифікацію, яка замінює шрифт, наприклад ElvUI, рекомендується встановити цю позначку, щоб уникнути можливих конфліктів.

Всі налаштування шрифтів слід проводити безпосередньо через глобальну модифікацію.

Це допоможе забезпечити стабільність та сумісність між різними аддонами.]],
                                order = setFontSettingsArgsOrder(),
                                width = "double",
                                get = function(_) return WowUkrainizer_Options.UseDefaultFonts end,
                                set = function(_, value) WowUkrainizer_Options.UseDefaultFonts = value end,
                            },
                            HorizaontalMargin1 = {
                                type = "description",
                                name = " ",
                                fontSize = "large",
                                order = setFontSettingsArgsOrder(),
                                width = "half"
                            },
                            UserFontHeader = {
                                type = "header",
                                name = "",
                                order = setFontSettingsArgsOrder()
                            },
                            UserFontWarning = {
                                type = "description",
                                name =
                                [[Перевірте що вибраний вами шрифт підтримує кирилицю. Інакше це призведе візуальних багів з відображенням тексту.
Ви можете використати аддон LibSharedMedia-3.0 для додавання нових шрифтів.
                                ]],
                                order = setFontSettingsArgsOrder(),
                                width = "full"
                            },
                            UserFont = {
                                type = "select",
                                name = "Доступні шрифти",
                                width = "double",
                                order = setFontSettingsArgsOrder(),
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
                                order = setFontSettingsArgsOrder()
                            },
                            FontScaleHeader = {
                                type = "header",
                                name = "Розмір шрифту (%)",
                                order = setFontSettingsArgsOrder()
                            },
                            FontScaleDescription = {
                                type = "description",
                                name = "Загальний",
                                order = setFontSettingsArgsOrder(),
                                width = "1",
                                fontSize = "medium"
                            },
                            FontScale = {
                                type = "range",
                                name = "",
                                order = setFontSettingsArgsOrder(),
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
                                order = setFontSettingsArgsOrder(),
                                width = "1",
                                fontSize = "medium"
                            },
                            TooltipHeaderFontScale = {
                                type = "range",
                                name = "",
                                order = setFontSettingsArgsOrder(),
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
                                order = setFontSettingsArgsOrder(),
                                width = "1",
                                fontSize = "medium"
                            },
                            TooltipFontScale = {
                                type = "range",
                                name = "",
                                order = setFontSettingsArgsOrder(),
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
            },
            Contributors = {
                order = 2,
                type = "group",
                name = "Причетні",
                args = {
                    DedicationText = {
                        order = setContributorsPageOrder(),
                        type = "description",
                        name = [[
Українчики,

Хочу висловити вам мою щиру подяку за невтомну роботу та підтримку в процесі перекладу та тестування аддона. Це лише перший крок в українізації одного із найпопулярніших ігрових світів.

Закликаю вас грати українською, дивитися українських контент-мейкерів та продовжувати підтримувати нашу спільну мету. Всі посилання на потрібні ресурси ви знайдете нижче.

Разом до перемоги!]],
                        fontSize = "small"
                    },
                    SPC00 = {
                        type = "description",
                        name = " ",
                        order = setContributorsPageOrder(),
                    },
                    SPC01 = {
                        type = "description",
                        name = " ",
                        order = setContributorsPageOrder(),
                    },
                    ContributorsHeader = {
                        order = setContributorsPageOrder(),
                        type = "header",
                        name = "Причетні",
                        dialogControl = "SFX-Header-II",
                    },
                    Proofreaders = {
                        type = "input",
                        name = "Редактори",
                        get = function() return "Semerkhet\n" end,
                        order = setContributorsPageOrder(),
                        disabled = true,
                        dialogControl = "SFX-Info",
                    },
                    SPC0 = {
                        type = "description",
                        name = " ",
                        order = setContributorsPageOrder(),
                    },
                    Translators = {
                        type = "input",
                        name = "Перекладачі",
                        get = function()
                            return
                                "KuprumLight, Mark Tsemma, Glafira, Алексей Коваль, Serhii Feelenko, " ..
                                "Semerkhet, senpusha, Валерий Бондаренко, NichnaVoitelka, Unbrkbl Opt1mist, Shelby333, " ..
                                "Nazar Kulchytskyi, Dmytro Borishpolets, RomenSkyJR, Дмитро Горєнков, " ..
                                "Женя Браславська, Elanka, Asturiel, Лігво Друїда, Volodymyr Taras, Олексій Сьомін, " ..
                                "Ксенія Никонова, Primarch, rchenok, Артем Белякін, Roma Rybai, Andrew Kucherov, " ..
                                "Toris_McDessert"
                        end,
                        order = setContributorsPageOrder(),
                        disabled = true,
                        dialogControl = "SFX-Info",
                    },
                    SPC1 = {
                        type = "description",
                        name = " ",
                        order = setContributorsPageOrder(),
                    },
                    Bugfix = {
                        type = "input",
                        name = "Технічна поміч",
                        get = function() return "Лігво Друїда (molaf)\n\n" end,
                        order = setContributorsPageOrder(),
                        disabled = false,
                        dialogControl = "SFX-Info",
                    },
                    SPC2 = {
                        type = "description",
                        name = " ",
                        order = setContributorsPageOrder(),
                    },
                    SPC4 = {
                        type = "description",
                        name = " ",
                        order = setContributorsPageOrder(),
                    },
                    Media = {
                        order = setContributorsPageOrder(),
                        type = "header",
                        name = "Ресурси та Посилання",
                        dialogControl = "SFX-Header-II",
                    },
                    SPC6 = {
                        type = "description",
                        name = " ",
                        order = setContributorsPageOrder(),
                    },
                    Discords1 = {
                        type = "input",
                        name = "Ukrainian Community",
                        get = function() return "https://bit.ly/ua_wow" end,
                        order = setContributorsPageOrder(),
                        disabled = false,
                        dialogControl = "SFX-Info-URL",
                    },
                    SPC7 = {
                        type = "description",
                        name = " ",
                        order = setContributorsPageOrder(),
                    },
                    Discords2 = {
                        type = "input",
                        name = "Нічна Воїтелька",
                        get = function() return "https://discord.gg/VGfWeWTX24" end,
                        order = setContributorsPageOrder(),
                        disabled = false,
                        dialogControl = "SFX-Info-URL",
                    },
                    SPC8 = {
                        type = "description",
                        name = " ",
                        order = setContributorsPageOrder(),
                    },
                    Twitch1 = {
                        type = "input",
                        name = "Rolik33",
                        get = function() return "https://www.twitch.tv/rolik33" end,
                        order = setContributorsPageOrder(),
                        disabled = false,
                        dialogControl = "SFX-Info-URL",
                    },
                    SPC9 = {
                        type = "description",
                        name = " ",
                        order = setContributorsPageOrder(),
                    },
                    Youtube1 = {
                        type = "input",
                        name = "Unbrkbl Opt1mist",
                        get = function() return "https://www.youtube.com/user/xcryjedicryx" end,
                        order = setContributorsPageOrder(),
                        disabled = false,
                        dialogControl = "SFX-Info-URL",
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

function settingsProvider.GetQuestTitleFontFile()
    return [[Interface\AddOns\WowUkrainizer\assets\Classic_UA_Morpheus.ttf]]
end

function settingsProvider.GetQuestFontFile()
    return [[Interface\AddOns\WowUkrainizer\assets\Classic_UA_FRIZQT.ttf]]
end

function settingsProvider.GetDefaultFontFile()
    return [[Interface\AddOns\WowUkrainizer\assets\Arsenal_Regular.ttf]]
end

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
    return {
        translateClassTalentsFrame = WowUkrainizer_Options.TranslateClassTalentsFrame,
        translateSpellbookFrame = WowUkrainizer_Options.TranslateSpellbookFrame,
        TranslateQuestAndObjectivesFrame = WowUkrainizer_Options.TranslateQuestAndObjectivesFrame,
        translateNameplatesAndUnitFrames = WowUkrainizer_Options.TranslateNameplatesAndUnitFrames,
        translateSpellTooltips = WowUkrainizer_Options.TranslateSpellTooltips,
        translateUnitTooltips = WowUkrainizer_Options.TranslateUnitTooltips,
        translateMovieSubtitles = WowUkrainizer_Options.TranslateMovieSubtitles,
        TranslateNpcDialogs = WowUkrainizer_Options.TranslateNpcDialogs,
        TranslateCinematics = WowUkrainizer_Options.TranslateCinematics,
    }
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

function settingsProvider.IsNeedTranslateDialogText()
    return WowUkrainizer_Options.TranslateNpcMessages and WowUkrainizer_Options.NpcDialogTextLang == "ua"
end

function settingsProvider.IsNeedTranslateDialogVoiceOver()
    return WowUkrainizer_Options.TranslateNpcMessages and WowUkrainizer_Options.NpcDialogVoiceOverLang == "ua"
end

function settingsProvider.IsNeedTranslateCinematicText()
    return WowUkrainizer_Options.TranslateCinematics and WowUkrainizer_Options.CinematicTextLang == "ua"
end

function settingsProvider.IsNeedTranslateCinematicVoiceOver()
    return WowUkrainizer_Options.TranslateCinematics and WowUkrainizer_Options.CinematicVoiceOverLang == "ua"
end
