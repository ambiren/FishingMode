local LAB = LibStub("LibActionButton-1.0")
local EditMode = LibStub("EditModeExpanded-1.0")

local ActionButtonMixin = {}
function ActionButtonMixin:GetHotkey()
    local barBindings = FishingMode.db.profile.bindings.actionBars[self.barIndex]
    local bindings = barBindings[self.buttonIndex]
    local key = bindings[1] or bindings[2]
    if not key then
        return ""
    end

    local libkb = LibStub("LibKeyBound-1.0", true)
    if libkb then
        return libkb:ToShortKey(key)
    else
        return GetBindingText(key, "KEY_", true)
    end
end

local function EditModeRegisterPaddable(frame)
    local systemID = getSystemID(frame)
    
    if not framesDialogs[systemID] then framesDialogs[systemID] = {} end
    if framesDialogsKeys[systemID] and framesDialogsKeys[systemID][Enum.EditModeUnitFrameSetting.FrameSize] then return end
    if not framesDialogsKeys[systemID] then framesDialogsKeys[systemID] = {} end
    framesDialogsKeys[systemID][Enum.EditModeUnitFrameSetting.FrameSize] = true
    table.insert(framesDialogs[systemID],
		{
			setting = Enum.EditModeUnitFrameSetting.FrameSize,
			name = HUD_EDIT_MODE_SETTING_UNIT_FRAME_FRAME_SIZE,
			type = Enum.EditModeSettingDisplayType.Slider,
			minValue = 10,
			maxValue = 200,
			stepSize = 5,
			ConvertValue = ConvertValueDefault,
			formatter = showAsPercentage,
		})
end

local function CreateActionButton(parentFrame, barIndex, buttonIndex)
    local name = "FishingModeActionBar" .. tostring(barIndex) .. "Button" .. tostring(buttonIndex)
    local btn = Mixin(LAB:CreateButton(1, name, parentFrame, { showGrid = true }), ActionButtonMixin)
    btn.barIndex = barIndex
    btn.buttonIndex = buttonIndex
    return btn
end

FishingMode.ActionBars = {
    [1] = {},
    [2] = {},
}

function FishingMode:InitialzeActionBars()
    local PADDING = 3

    for barIndex, actionBar in ipairs(FishingMode.ActionBars) do
        actionBar.BarFrame = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
        actionBar.BarFrame:SetSize(12 * (45 + PADDING) - PADDING, 48)
        actionBar.BarFrame:SetPoint("CENTER", UIParent, 0, barIndex * 48)
        actionBar.Buttons = {}
        for buttonIndex = 1,12 do
            local btn = CreateActionButton(actionBar.BarFrame, barIndex, buttonIndex)
            actionBar.Buttons[buttonIndex] = btn
            if buttonIndex == 1 then
                btn:SetPoint("LEFT", actionBar.BarFrame)
            else
                btn:SetPoint("LEFT", actionBar.Buttons[buttonIndex - 1], "RIGHT", PADDING, 0)
            end
            btn:Show()
        end

        actionBar.BarFrame:Show()

        local editModeData = self.db.profile.editModeData.actionBars[barIndex]
        EditMode:RegisterFrame(actionBar.BarFrame, "Fishing Bar " .. tostring(barIndex), editModeData)
        EditMode:RegisterHideable(actionBar.BarFrame)
    end
end