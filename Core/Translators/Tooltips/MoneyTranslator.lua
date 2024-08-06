--- @class WowUkrainizerInternals
local ns = select(2, ...);

local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString

---@class MoneyTranslator : BaseTranslator
local translator = setmetatable({}, { __index = ns.BaseTranslator })

function translator:IsEnabled()
    return true
end

function translator:Init()
    hooksecurefunc("MoneyFrame_Update", function(frameName, money, forceShow)
        local frame;
        if (type(frameName) == "table") then
            frame = frameName;
        else
            frame = _G[frameName];
        end

        if (not frame) then return end

        local prefixText = frame.PrefixText and frame.PrefixText:GetText()
        if (prefixText) then
            frame.PrefixText:SetText(prefixText:gsub(SELL_PRICE, GetTranslatedGlobalString(SELL_PRICE)));
        end

        local suffixText = frame.SuffixText and frame.SuffixText:GetText()
        if (suffixText) then
            frame.SuffixText:SetText(suffixText:gsub(SELL_PRICE, GetTranslatedGlobalString(SELL_PRICE)));
        end
    end)
end

ns.TranslationsManager:AddTranslator(translator)
