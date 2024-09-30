--- @class WowUkrainizerInternals
local ns = select(2, ...);

local subscriber = setmetatable({}, { __index = ns.BaseSubscriber })
subscriber.__index = subscriber

---@class StaticPopupSubscriber : BaseSubscriber
ns.StaticPopupSubscriber = subscriber

local function StaticPopup_Show_Hook(which, data)
	local info = StaticPopupDialogs[which];
	if (not info) then return nil end

	if (info.OnAccept and info.OnButton1) then return nil end

	if (info.OnCancel and info.OnButton2) then return nil end

	if (UnitIsDeadOrGhost("player") and not info.whileDead) then return nil end

	if (InCinematic() and not info.interruptCinematic) then return nil end

	-- Pick a free dialog to use
	local dialog = StaticPopup_FindVisible(which, data)
	if (not dialog) then
		-- Find a free dialog
		local index = 1;
		if (info.preferredIndex) then
			index = info.preferredIndex;
		end
		for i = index, STATICPOPUP_NUMDIALOGS do
			local frame = StaticPopup_GetDialog(i);
			if (frame and not frame:IsShown()) then
				dialog = frame;
				break;
			end
		end

		--If dialog not found and there's a preferredIndex then try to find an available frame before the preferredIndex
		if (not dialog and info.preferredIndex) then
			for i = 1, info.preferredIndex do
				local frame = _G["StaticPopup" .. i];
				if (not frame:IsShown()) then
					dialog = frame;
					break;
				end
			end
		end
	end

	return dialog
end

function subscriber:InitializeSubscriber()
	hooksecurefunc("StaticPopup_Show", function(which, text_arg1, text_arg2, data, insertedFrame)
		local dialog = StaticPopup_Show_Hook(which, data)
		if (not dialog) then return end

		for subscribedRegion, callbackFunc in pairs(self.subscriptions) do
			if (which == subscribedRegion) then
				callbackFunc(dialog, text_arg1, text_arg2, data, insertedFrame)
			end
		end
	end)
end
