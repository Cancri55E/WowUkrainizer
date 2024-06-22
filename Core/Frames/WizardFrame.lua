--- @type string, WowUkrainizerInternals
local _, ns = ...;

local sharedMedia = LibStub("LibSharedMedia-3.0")
local dropdownLib = LibStub:GetLibrary("LibUIDropDownMenu-4.0", true)

local function createDropdownList(name, parentFrame, data)
    -- Create a frame for the dropdown
    local frame = dropdownLib:Create_UIDropDownMenu(name, parentFrame)
    -- Function to initialize the dropdown
    local function InitializeDropDown(_, level)
        if (data.items) then
            for itemKey, item in pairs(data.items) do
                local info = dropdownLib:UIDropDownMenu_CreateInfo()
                info.text = item
                info.value = itemKey
                info.checked = nil
                info.arg1 = data.selectedItemChangedCallback
                info.func = function(button, selectedItemChangedCallback)
                    dropdownLib:UIDropDownMenu_SetSelectedValue(frame, button.value)
                    if (selectedItemChangedCallback) then
                        selectedItemChangedCallback(button.value)
                    end
                end
                dropdownLib:UIDropDownMenu_AddButton(info, level)
            end
        end
    end

    dropdownLib:UIDropDownMenu_SetWidth(frame, data.width);
    dropdownLib:UIDropDownMenu_Initialize(frame, InitializeDropDown)
    dropdownLib:UIDropDownMenu_SetSelectedValue(frame, data.selectedValue)

    frame:SetScript("OnMouseDown", function(button)
        if button == "LeftButton" then
            dropdownLib:ToggleDropDownMenu(1, nil, frame, parentFrame, 0, -2, "MENU")
        end
    end)

    function frame:Enable()
        self.Button:Enable()
        self.Text:SetTextColor(WOW_UKRAINIZER_WHITE_COLOR.r, WOW_UKRAINIZER_WHITE_COLOR.g,
            WOW_UKRAINIZER_WHITE_COLOR.b)
    end

    function frame:Disable()
        self.Button:Disable()
        self.Text:SetTextColor(WOW_UKRAINIZER_DISABLED_COLOR.r, WOW_UKRAINIZER_DISABLED_COLOR.g,
            WOW_UKRAINIZER_DISABLED_COLOR.b)
    end

    return frame
end

-- WowUkrainizerFontSettingsFrameMixin
do
    WowUkrainizerFontSettingsFrameMixin = CreateFromMixins(CallbackRegistryMixin);

    function WowUkrainizerFontSettingsFrameMixin:OnLoad()
        CallbackRegistryMixin.OnLoad(self);

        local events = MinimalSliderWithSteppersMixin.Event
        self.cbrHandles = EventUtil.CreateCallbackHandleContainer();
        self.cbrHandles:RegisterCallback(self.Slider, events.OnValueChanged, self.OnSliderValueChanged, self);
    end

    function WowUkrainizerFontSettingsFrameMixin:SetupSetting(settingData)
        self.initInProgress = true;

        self.fontNameOption = settingData.fontNameOption
        self.fontScaleOption = settingData.fontScaleOption
        self.defaultExampleTextSize = settingData.defaultExampleTextSize

        self.Title:SetText(settingData.title);
        self.Label:SetText(settingData.label);

        self.Slider:SetWidth(settingData.sliderDisplayInfo.width);

        if settingData.sliderDisplayInfo.minText then
            self.Slider.MinText:SetText(settingData.sliderDisplayInfo.minText);
            self.Slider.MinText:Show();
        else
            self.Slider.MinText:Hide();
        end

        if settingData.sliderDisplayInfo.maxText then
            self.Slider.MaxText:SetText(settingData.sliderDisplayInfo.maxText);
            self.Slider.MaxText:Show();
        else
            self.Slider.MaxText:Hide();
        end

        local stepSize = settingData.sliderDisplayInfo.stepSize or 1;
        local steps = (settingData.sliderDisplayInfo.maxValue - settingData.sliderDisplayInfo.minValue) / stepSize;
        local currentValue = ns.SettingsProvider.GetOption(settingData.fontScaleOption) * 100
        self.formatters = {};
        self.formatters[MinimalSliderWithSteppersMixin.Label.Right] = CreateMinimalSliderFormatter(
            MinimalSliderWithSteppersMixin.Label.Right);

        self.Slider:Init(currentValue, settingData.sliderDisplayInfo.minValue, settingData.sliderDisplayInfo.maxValue,
            steps, self.formatters);


        self.FontNameSelector = createDropdownList("FontNameSelector", self, {
            items = settingData.fonts,
            width = 150,
            selectedValue = ns.CommonUtil.FindKeyByValue(
                settingData.fonts, ns.SettingsProvider.GetOption(settingData.fontNameOption)),
            selectedItemChangedCallback = function(selectedItem)
                ns.SettingsProvider.SetOption(self.fontNameOption, settingData.fonts[selectedItem])
                self:UpdateExampleText()
            end
        })
        self.FontNameSelector:SetPoint("LEFT", self.Title, "RIGHT", -20, -4)

        self:UpdateExampleText()

        self.initInProgress = false;
    end

    function WowUkrainizerFontSettingsFrameMixin:OnSliderValueChanged(value)
        if not self.initInProgress then
            ns.SettingsProvider.SetOption(self.fontScaleOption, value / 100)
            self:UpdateExampleText()
        end
    end

    function WowUkrainizerFontSettingsFrameMixin:UpdateExampleText()
        local _, _, flags = self.ExampleText:GetFont()
        local font = sharedMedia:Fetch('font', ns.SettingsProvider.GetOption(self.fontNameOption))
        local size = self.defaultExampleTextSize * ns.SettingsProvider.GetOption(self.fontScaleOption)
        self.ExampleText:SetFont(font, size, flags)
    end
end

-- WowUkrainizerBasePageMixin
do
    WowUkrainizerBasePageMixin = { UISettingDescriptions = {}, UIFontStringTexts = {} }

    function WowUkrainizerBasePageMixin:OnLoad()
        if (self.UISettingElements) then
            for _, settingButton in ipairs(self.UISettingElements) do
                settingButton.Text:SetText(self.UISettingDescriptions[settingButton:GetID()]);

                if type(settingButton.SetChecked) == "function" then
                    local optionName = settingButton:GetAttribute("optionName")
                    if (optionName) then
                        local checked = ns.SettingsProvider.GetOption(_G[optionName])
                        if (checked ~= nil) then
                            settingButton:SetChecked(checked)
                            self:OnCheckButtonChecked(settingButton, checked)
                        end
                    end
                end
            end
        end

        if (self.UIFontStrings) then
            for _, fontString in ipairs(self.UIFontStrings) do
                if (fontString.parentName) then
                    local topOffset = fontString.topOffset or 0
                    fontString:SetPoint("TOPLEFT", self[fontString.parentName], "BOTTOMLEFT", fontString.leftOffset, topOffset)
                    fontString:SetPoint("TOPRIGHT", -12, -12)
                end

                fontString:SetText(self.UIFontStringTexts[fontString.id]);
            end
        end
    end

    function WowUkrainizerBasePageMixin:OnCheckButtonChecked(checkButton, checked)
    end

    function WowUkrainizerBasePageMixin:CanBack()
        return true
    end

    function WowUkrainizerBasePageMixin:CanNext()
        return true
    end

    function WowUkrainizerBasePageMixin:EnableFontString(fontString, userColor)
        local color = userColor or WOW_UKRAINIZER_WHITE_COLOR
        fontString:SetTextColor(color.r, color.g, color.b)
    end

    function WowUkrainizerBasePageMixin:DisableFontString(fontString, userColor)
        local color = userColor or WOW_UKRAINIZER_DISABLED_COLOR
        fontString:SetTextColor(color.r, color.g, color.b)
    end
end

-- WowUkrainizerInstallerWelcomePageMixin
do
    local WOW_UKRAINIZER_WELCOME_PAGE_TITLE_TEXT = "Ласкаво просимо до майстра налаштування WowUkrainizer!"
    local WOW_UKRAINIZER_WELCOME_PAGE_DESCRIPTION_TEXT =
    [[Дякуємо, що обрали наш аддон для занурення у захопливий світ Azeroth. За допомогою цього майстра налаштувань ви зможете легко адаптувати аддон під себе.

Ви маєте можливість вибрати, які саме частини гри будуть перекладені: текстові діалоги, завдання, інтерфейс чи весь контент разом. Крім цього, є можливість налаштувати візуальне оформлення аддону.

Якщо ви хочете почати грати негайно, просто скористайтеся кнопкою "Залишити налаштування за замовченням", і наш аддон автоматично підбере оптимальні параметри.

Зробіть свій ігровий досвід ще приємнішим і зручнішим з українізатором.

Приємної гри!]]
    local WOW_UKRAINIZER_WELCOME_PAGE_LEAVE_DEFAULT_BUTTON_TEXT = "Залишити налаштування за замовченням"

    WowUkrainizerInstallerWelcomePageMixin = CreateFromMixins(WowUkrainizerBasePageMixin);

    function WowUkrainizerInstallerWelcomePageMixin:OnLoad()
        self.Title:SetText(WOW_UKRAINIZER_WELCOME_PAGE_TITLE_TEXT)
        self.Description:SetText(WOW_UKRAINIZER_WELCOME_PAGE_DESCRIPTION_TEXT)
        self.Description:SetJustifyV("TOP");
        self.Description:SetJustifyH("LEFT");

        self.LeaveDefaultButton.Text:SetText(WOW_UKRAINIZER_WELCOME_PAGE_LEAVE_DEFAULT_BUTTON_TEXT)
        self.LeaveDefaultButton.Background:SetColorTexture(WOW_UKRAINIZER_GREEN_COLOR.r, WOW_UKRAINIZER_GREEN_COLOR.g,
            WOW_UKRAINIZER_GREEN_COLOR.b, 1)
    end

    function WowUkrainizerInstallerWelcomePageMixin:CanBack()
        return false
    end
end

-- WowUkrainizerModuleSettingsPageMixin
do
    WowUkrainizerModuleSettingsPageMixin = CreateFromMixins(WowUkrainizerBasePageMixin);
    WowUkrainizerModuleSettingsPageMixin.UISettingDescriptions = {
        [1] = "Перекладати вікно \"Спеціалізація та таланти\"",
        [2] = "Перекладати вікно \"Книга здібностей та професії\"",
        [3] = "Перекладати шильдики (nameplates) та фрейми неігрових персонажів",
        [4] = "Перекладати назви ігрових локацій",
        [5] = "Перекладати субтитри в відеороликах",
        [6] = "Перекласти діалоги неігрових персонажів",
        [7] = "Перекладати завдання",
        [8] = "Не використовувати машинний переклад при перекладі завдань",
    }

    WowUkrainizerModuleSettingsPageMixin.UIFontStringTexts = {
        [1] = "Інтерфейс користувача",
        [2] = "Є повна сумісність з такими додатками як Plater та ElvUI.",
        [3] = "Переклад буде застосовано до вспливаючого тексту під час переходу між локаціями, а також до тексту на карті та мінікарті.",
        [4] = "Субтитри та діалоги",
        [5] = "Додає переклад для субтитрів у пререндерованих відеороликах гри (не плутати з кат-сценами).",
        [6] = "Додає переклад діалогів неігрових персонажів. Перекладений текст буде відображатися у вікні чату, а також в 'бульбашках' " ..
            "над головою персонажа, a також в кат-сценах. |n|nУВАГА! Через обмеження які ввела компанія Blizzard в ігровому клієнту " ..
            "переклад діалогів всередині групового контенту (підземелля, рейди та ін.) можливий переклад лише в чаті гри. Текст в бульбашках залишатиметься англійським.",
        [7] = "Завдання",
        [8] = "Додає переклад ігрових завдань і пов'язанних з ними елементів гри. Будуть перекладені не лише тексти самих завдань, " ..
            "а вікна які відповідають за їх відображення, позначки завдань на мапі світу та міні мапі, а також буде перекладений список " ..
            "завдань, що відстежуються.|n|nДля того, щоб перемикатися між оригінальним текстом завдання і перекладом у вікні з описом буде спеціальна кнопка. " ..
            "Також поруч буде окрема кнопка яка дозволить вам скопіювати посилання на wowhead з описом завдання.",
        [9] = "Гра World of Warcraft має тисячі завдань та мільйони слів котрі необхідно перекласти. Силами фанатів це може зайняти роки, щоб перекласти все. " ..
            "Тому було вирішено додати машинний переклад за допомогою ШІ, щоб пришвидшити переклад завдань і ті хто погано розуміють англійську вже зараз " ..
            "могли насолоджуватися грою.|n|nПріоритет перекладу від ШІ завжди нижче ніж перекладу який зробила людина, тому додаток автоматично буде використовувати " ..
            "переклад який зробила людина якщо він є у наявності.|n|nУ вікні з текстом завдання поруч з кнопкою перемикання перекладу буде відображена " ..
            "спеціальна іконка (голова робота) якщо ви бачите повний або частковий машинний переклад.",
    }

    function WowUkrainizerModuleSettingsPageMixin:OnCheckButtonChecked(checkButton, checked)
        if (checkButton == self.TranslateQuestAndObjectivesFrame) then
            if (checked) then
                self.DisableMTForQuests:EnableHook()
                self:EnableFontString(self.DisableMTForQuestsDescription, WOW_UKRAINIZER_SECONDARY_TEXT_COLOR)
            else
                self.DisableMTForQuests:DisableHook()
                self:DisableFontString(self.DisableMTForQuestsDescription)
            end
        end
    end
end

-- WowUkrainizerFontSettingsPageMixin
do
    WowUkrainizerFontSettingsPageMixin = CreateFromMixins(WowUkrainizerBasePageMixin);
    WowUkrainizerFontSettingsPageMixin.UISettingDescriptions = {
        [1] = "Не змінювати шрифти",
        [2] = "Стандартні адаптовані шрифти",
        [3] = "Налаштувати власні шрифти",
    }

    function WowUkrainizerFontSettingsPageMixin:OnLoad()
        WowUkrainizerBasePageMixin.OnLoad(self)

        local sortedFonts = {}
        local fonts = sharedMedia:HashTable("font")
        if (fonts) then
            for k, _ in pairs(fonts) do
                sortedFonts[#sortedFonts + 1] = k
            end
            table.sort(sortedFonts, function(a, b) return string.upper(a) < string.upper(b) end)
        end

        local sliderDisplayInfo = {
            width = 180,
            stepSize = 5,
            minValue = 50,
            maxValue = 300
        }

        self.FontScaleInPercentSlider:SetupSetting({
            title = "Основний",
            label = "Масштаб (%)",
            sliderDisplayInfo = sliderDisplayInfo,
            fonts = sortedFonts,
            fontNameOption = WOW_UKRAINIZER_MAIN_FONT_NAME_OPTION,
            fontScaleOption = WOW_UKRAINIZER_MAIN_FONT_SCALE_IN_PERCENT_OPTION,
            defaultExampleTextSize = 13,
        })

        self.TitleFontScaleInPercentSlider:SetupSetting({
            title = "Заголовки",
            label = "Масштаб (%)",
            sliderDisplayInfo = sliderDisplayInfo,
            fonts = sortedFonts,
            fontNameOption = WOW_UKRAINIZER_TITLE_FONT_NAME_OPTION,
            fontScaleOption = WOW_UKRAINIZER_TITLE_FONT_SCALE_IN_PERCENT_OPTION,
            defaultExampleTextSize = 14,
        })

        self.TooltipFontScaleInPercentSlider:SetupSetting({
            title = "Спливаючи підказки",
            label = "Масштаб (%)",
            sliderDisplayInfo = sliderDisplayInfo,
            fonts = sortedFonts,
            fontNameOption = WOW_UKRAINIZER_TOOLTIP_FONT_NAME_OPTION,
            fontScaleOption = WOW_UKRAINIZER_TOOLTIP_FONT_SCALE_IN_PERCENT_OPTION,
            defaultExampleTextSize = 12,
        })

        self.UseDefaultFonts.BehaveAsRadioButton = true
        self.UseAdaptedBlizzardFonts.BehaveAsRadioButton = true
        self.UseCustomFonts.BehaveAsRadioButton = true
    end

    function WowUkrainizerFontSettingsPageMixin:OnCheckButtonChecked(checkButton, checked)
        if (not checked) then return end

        if (checkButton == self.UseDefaultFonts) then
            self.FontScaleInPercentSlider:Hide()
            self.TitleFontScaleInPercentSlider:Hide()
            self.TooltipFontScaleInPercentSlider:Hide()

            self.UseAdaptedBlizzardFonts:SetChecked(false)
            self.UseAdaptedBlizzardFonts:SetOption(false)
            self.UseCustomFonts:SetChecked(false)
            self.UseCustomFonts:SetOption(false)
        elseif (checkButton == self.UseAdaptedBlizzardFonts) then
            self.FontScaleInPercentSlider:Hide()
            self.TitleFontScaleInPercentSlider:Hide()
            self.TooltipFontScaleInPercentSlider:Hide()

            self.UseDefaultFonts:SetChecked(false)
            self.UseDefaultFonts:SetOption(false)
            self.UseCustomFonts:SetChecked(false)
            self.UseCustomFonts:SetOption(false)
        elseif (checkButton == self.UseCustomFonts) then
            self.FontScaleInPercentSlider:Show()
            self.TitleFontScaleInPercentSlider:Show()
            self.TooltipFontScaleInPercentSlider:Show()

            self.UseDefaultFonts:SetChecked(false)
            self.UseDefaultFonts:SetOption(false)
            self.UseAdaptedBlizzardFonts:SetChecked(false)
            self.UseAdaptedBlizzardFonts:SetOption(false)
        end
    end
end

-- WowUkrainizerTooltipSettingsPageMixin
do
    WowUkrainizerTooltipSettingsPageMixin = CreateFromMixins(WowUkrainizerBasePageMixin);
    WowUkrainizerTooltipSettingsPageMixin.UISettingDescriptions = {
        [1] = "Перекладати підказки до неігрових персонажів",
        [2] = "Перекладати підказки до заклять, здібностей та талантів",
        [3] = "Підсвічувати голубим кольором назви заклять, здібностей та талантів в описі",
    }

    function WowUkrainizerTooltipSettingsPageMixin:OnLoad()
        self.SpellNameLanguageSelector = createDropdownList("SpellNameLanguageSelector", self, {
            items = {
                ["both"] = "Обидві (спочатку англійська)",
                ["ua"]   = "Українська",
                ["en"]   = "Англійська",
            },
            width = 190,
            selectedValue = ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TOOLTIP_SPELL_LANG_IN_NAME_OPTION),
            selectedItemChangedCallback = function(selectedItem)
                ns.SettingsProvider.SetOption(WOW_UKRAINIZER_TOOLTIP_SPELL_LANG_IN_NAME_OPTION, selectedItem)
            end
        })
        self.SpellNameLanguageSelector:SetPoint("LEFT", self.SpellNameLanguageTitle, "RIGHT", 8, -4)

        self.SpellDescriptionLanguageSelector = createDropdownList("SpellDescriptionLanguageSelector", self, {
            items = {
                ["ua"] = "Українська",
                ["en"] = "Англійська",
            },
            width = 190,
            selectedValue = ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TOOLTIP_SPELL_LANG_IN_DESCRIPTION_OPTION),
            selectedItemChangedCallback = function(selectedItem)
                ns.SettingsProvider.SetOption(WOW_UKRAINIZER_TOOLTIP_SPELL_LANG_IN_DESCRIPTION_OPTION, selectedItem)
            end
        })
        self.SpellDescriptionLanguageSelector:SetPoint("LEFT", self.SpellDescriptionLanguageTitle, "RIGHT", 13, -3)

        WowUkrainizerBasePageMixin.OnLoad(self)
    end

    function WowUkrainizerTooltipSettingsPageMixin:OnCheckButtonChecked(checkButton, checked)
        if (checkButton ~= self.TranslateSpellTooltips) then return end

        if (checked) then
            self.HighlightSpellNameInDescriptionButton:EnableHook()
            self.SpellNameLanguageSelector:Enable()
            self.SpellDescriptionLanguageSelector:Enable()

            self:EnableFontString(self.SpellNameLanguageTitle)
            self:EnableFontString(self.SpellDescriptionLanguageTitle)
        else
            self.HighlightSpellNameInDescriptionButton:DisableHook()
            self.SpellNameLanguageSelector:Disable()
            self.SpellDescriptionLanguageSelector:Disable()

            self:DisableFontString(self.SpellNameLanguageTitle)
            self:DisableFontString(self.SpellDescriptionLanguageTitle)
        end
    end
end

-- WowUkrainizerFinishPageMixin
do
    local WOW_UKRAINIZER_FINISH_PAGE_COMPLETE_BUTTON_TEXT = "Застосувати налаштування"
    local WOW_UKRAINIZER_FINISH_PAGE_DESCRIPTION_TEXT =
    [[Друзі, дякую за те, що обрали грати українською і вірите в наш проєкт.

Хочу висловити вам мою щиру подяку за невтомну роботу та підтримку в процесі перекладу та тестування додатка. Це лише перший крок в українізації одного із найпопулярніших ігрових світів.

Продовжуйте грати українською, дивитися українських контент-мейкерів та підтримувати нашу спільну мету. Разом до перемоги!]]

    local WOW_UKRAINIZER_FINISH_PAGE_TRANSLATORS_TEXT =
        "KuprumLight, " ..
        "Roman Yanyshyn, " ..
        "Glafira, " ..
        "kasatushi, " ..
        "Olena Gorbenko, " ..
        "Kabandis, " ..
        "Lutera1234, " ..
        "FinniV, " ..
        "Kiborg Kozak, " ..
        "Viktor Krech, " ..
        "Mark Tsemma, " ..
        "Алексей Коваль, " ..
        "SinRoot, " ..
        "Serhii Feelenko, " ..
        "Semerkhet, " ..
        "Mykyta Barmin, " ..
        "Валерій Бондаренко, " ..
        "Shannar de Kassal, " ..
        "Dourmain-Kazzak, " ..
        "Володар смерті, " ..
        "Dmytro Boryshpolets, " ..
        "NichnaVoitelka, " ..
        "Unbrkbl Opt1mist, " ..
        "Elanka, " ..
        "Vadym Ivaniuk, " ..
        "Shelby333, " ..
        "Nazar Kulchytskyi, " ..
        "Rolik33, " ..
        "Belinardo, " ..
        "Сергей Райдер, " ..
        "Artem Panchenko, " ..
        "RomenSkyJR, " ..
        "Дмитро Горєнков, " ..
        "Asturiel, " ..
        "Женя Браславська, " ..
        "Лігво Друїда, " ..
        "losthost, " ..
        "Bokshchanin, " ..
        "lanpae, " ..
        "Volodymyr Taras, " ..
        "Олексій Сьомін, " ..
        "Ксенія Никонова, " ..
        "Primarch, " ..
        "Mykyta Vlasov, " ..
        "Natalie Dexter, " ..
        "Дима Сердюк, " ..
        "Maxym Palamarchuk, " ..
        "Archenok "

    WowUkrainizerFinishPageMixin = CreateFromMixins(WowUkrainizerBasePageMixin);

    function WowUkrainizerFinishPageMixin:OnLoad()
        WowUkrainizerBasePageMixin.OnLoad(self)

        local contributorTitleWidth = 80
        local linkTitleWidth = 105

        self.Title:SetText(WOW_UKRAINIZER_FINISH_PAGE_DESCRIPTION_TEXT)

        self.ContributorsHeader.Header:SetText("Причетні")
        self.Author:SetInfo("Розробник:", "Cancri", contributorTitleWidth)
        self.Proofreaders:SetInfo("Редактор:", "KuprumLight, Kasatushi, Nimfiel", contributorTitleWidth)
        self.Translators:SetInfo("Перекладачі:", WOW_UKRAINIZER_FINISH_PAGE_TRANSLATORS_TEXT, contributorTitleWidth)
        self.Developments:SetInfo("Виправлення:", "Лігво Друїда (molaf)", contributorTitleWidth)

        self.LinksHeader.Header:SetText("Ресурси та Посилання")
        self.UkrainianWoWCommunity:SetValue("Ukrainian WoW Community", "https://bit.ly/ua_wow", linkTitleWidth)
        self.NichnaVoitelka:SetValue("Нічна Воїтелька", "https://discord.gg/VGfWeWTX24", linkTitleWidth)
        self.Rolik:SetValue("Rolik33", "https://www.twitch.tv/rolik33", linkTitleWidth)
        self.UnbrkblOpt1mist:SetValue("Unbrkbl Opt1mist", "https://www.youtube.com/@unbrkblopt1mist", linkTitleWidth)

        if (self.CompleteButton) then
            self.CompleteButton.Text:SetText(WOW_UKRAINIZER_FINISH_PAGE_COMPLETE_BUTTON_TEXT)
            self.CompleteButton.Background:SetColorTexture(WOW_UKRAINIZER_GREEN_COLOR.r, WOW_UKRAINIZER_GREEN_COLOR.g,
                WOW_UKRAINIZER_GREEN_COLOR.b, 1)
        end
        self:SetBestSize()
    end

    function WowUkrainizerFinishPageMixin:CanNext()
        return false
    end

    function WowUkrainizerFinishPageMixin:SetBestSize(preferredWidth)
        if (preferredWidth) then
            self:SetWidth(preferredWidth)
        else
            preferredWidth = self:GetWidth()
        end

        self.ContributorsHeader:SetWidth(preferredWidth - 40)
        self.LinksHeader:SetWidth(preferredWidth - 40)

        self.Translators.Info:SetWidth(preferredWidth - 130)
        self.Developments:ClearAllPoints();
        self.Developments:SetPoint("TOPLEFT", self.Translators, "BOTTOMLEFT", 0,
            (self.Translators.Info:GetHeight() - 14) * -1);
    end
end

-- WowUkrainizerInstallerFrameMixin
do
    WowUkrainizerInstallerFrameMixin = {}

    local function setInstallerPage(installerFrameMixin, pageIndex)
        if (pageIndex < 1 or pageIndex > #installerFrameMixin._pages) then return end

        if (installerFrameMixin._currentPageIndex) then
            installerFrameMixin._pages[installerFrameMixin._currentPageIndex]:Hide()
        end
        installerFrameMixin._currentPageIndex = pageIndex

        local newPage = installerFrameMixin._pages[pageIndex]
        newPage:Show()

        if (newPage:CanBack()) then
            installerFrameMixin.PreviousButton:Show()
        else
            installerFrameMixin.PreviousButton:Hide()
        end

        if (newPage:CanNext()) then
            installerFrameMixin.NextButton:Show()
        else
            installerFrameMixin.NextButton:Hide()
        end
    end

    function WowUkrainizerInstallerFrameMixin:OnLoad()
        local function _initializeButtons()
            self.NextButton.Text:SetText("Далі")
            self.PreviousButton.Text:SetText("Назад")
        end

        _initializeButtons()

        self._pages = {
            [1] = self.SettingsScrollFrame.SettingsScrollChildFrame.WelcomePage,
            [2] = self.SettingsScrollFrame.SettingsScrollChildFrame.ModuleSettingsPage,
            [3] = self.SettingsScrollFrame.SettingsScrollChildFrame.TooltipSettingsPage,
            [4] = self.SettingsScrollFrame.SettingsScrollChildFrame.FontSettingsPage,
            [5] = self.SettingsScrollFrame.SettingsScrollChildFrame.FinishPage
        }

        setInstallerPage(self, 1)
    end

    function WowUkrainizerInstallerFrameMixin:ToggleUI()
        if self:IsVisible() then
            self:Hide()
            setInstallerPage(self, 1)
        else
            self:Show()
        end
    end

    function WowUkrainizerInstallerFrameMixin:NextPage()
        setInstallerPage(self, self._currentPageIndex + 1)
    end

    function WowUkrainizerInstallerFrameMixin:PreviousPage()
        setInstallerPage(self, self._currentPageIndex - 1)
    end

    function WowUkrainizerInstallerFrameMixin:LeaveDefaultSettings()
        ns.SettingsProvider:ResetToDefault()
        setInstallerPage(self, #self._pages)
    end
end
