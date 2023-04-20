local _, ns = ...;

local _G = _G

local translator = class("SpecializationFrameTranslator", ns.Translators.BaseFrameTranslator)
ns.Translators.SpecializationFrameTranslator = translator

function translator:TranslationMap()
    self.original = {
        ["WAR_MODE_CALL_TO_ARMS"] = _G["WAR_MODE_CALL_TO_ARMS"],
        ["WAR_MODE_BONUS_INCENTIVE_TOOLTIP"] = _G["WAR_MODE_BONUS_INCENTIVE_TOOLTIP"],
        ["PVP_LABEL_WAR_MODE"] = _G["PVP_LABEL_WAR_MODE"],
        ["PVP_WAR_MODE_DESCRIPTION_FORMAT"] = _G["PVP_WAR_MODE_DESCRIPTION_FORMAT"],
        ["PVP_WAR_MODE_ENABLED"] = _G["PVP_WAR_MODE_ENABLED"],
    }

    self.translations = {
        ["WAR_MODE_CALL_TO_ARMS"] = "Режим війни: заклик до зброї",
        ["WAR_MODE_BONUS_INCENTIVE_TOOLTIP"] = "Бонус режиму війни збільшено на %2$d%%.",
        ["PVP_LABEL_WAR_MODE"] = "Режим війни",
        ["PVP_WAR_MODE_DESCRIPTION_FORMAT"] = "Перейдіть у режим війни та активуйте світове PvP, збільшивши нагороди за квести та досвід на %1$d%%, а також увімкнувши PvP-таланти у відкритому світі.",
        ["PVP_WAR_MODE_ENABLED"] = "Увімкнено",
    }

    self.translationMap = {
        constants = {
            [1] = "WAR_MODE_CALL_TO_ARMS",
            [2] = "WAR_MODE_BONUS_INCENTIVE_TOOLTIP",
            [3] = "PVP_LABEL_WAR_MODE",
            [4] = "PVP_WAR_MODE_DESCRIPTION_FORMAT",
            [5] = "PVP_WAR_MODE_ENABLED",
        },
        fontStrings = {

        }
    }
end
