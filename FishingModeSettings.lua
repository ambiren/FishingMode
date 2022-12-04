FishingModeKeyBindingButtonTemplateMixin = {}

function FishingModeKeyBindingButtonTemplateMixin:UpdateBindingState(initializer)
    for index, button in ipairs(self.Buttons) do
        BindingButtonTemplate_SetupBindingButton(FishingMode:GetBinding(initializer.data.action, index), button)
    end
end

function FishingModeKeyBindingButtonTemplateMixin:ProcessInput(button, index, initializer, input)
    local key = FishingMode:ConvertInputToKey(input)
    if key then
        FishingMode:SetBinding(initializer.data.action, index, key)
    end

    initializer.selectedIndex = nil
    self:StopInputListener(button)
    self:UpdateBindingState(initializer)
end

function FishingModeKeyBindingButtonTemplateMixin:StartInputListener(button, index, initializer)
    local function OnInput(input)
        self:ProcessInput(button, index, initializer, input)
    end

    FishingModeInputBlocker:Show()
    FishingModeInputBlocker:SetFrameStrata("DIALOG")

    button:SetSelected(true)
    button:SetParent(FishingModeInputBlocker)

    FishingModeInputBlocker:SetScript("OnKeyDown", function(_, key) OnInput(key) end)
    FishingModeInputBlocker:SetScript("OnGamePadButtonDown", function(_, key) OnInput(key) end)
    FishingModeInputBlocker:SetScript("OnClick", function(_, _) end)
    FishingModeInputBlocker:SetScript("OnMouseWheel", function(_, delta)
        OnInput(delta > 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN")
    end)

	SettingsPanel:SetOutputText(SETTINGS_BIND_KEY_TO_COMMAND_OR_CANCEL:format(initializer.data.bindingName, GetBindingText("ESCAPE")))
end

function FishingModeKeyBindingButtonTemplateMixin:StopInputListener(button)
    FishingModeInputBlocker:Hide()

    button:SetSelected(false)
    button:SetParent(self)

    FishingModeInputBlocker:SetScript("OnKeyDown", nil)
    FishingModeInputBlocker:SetScript("OnGamePadButtonDown", nil)
    FishingModeInputBlocker:SetScript("OnClick", nil)
    FishingModeInputBlocker:SetScript("OnMouseWheel", nil)

    SettingsTooltip:Hide();
    SettingsPanel:ClearOutputText();
end

function FishingModeKeyBindingButtonTemplateMixin:Init(initializer)
    local action = initializer.data.action
    local bindingName = initializer.data.bindingName

    local labelIndent = 37
    self.Label:SetPoint("LEFT", labelIndent, 0)
    self.Label:SetText(bindingName)

    local function InitializeKeyBindingButtonTooltip(index)
        local key = FishingMode:GetBinding(action, index)
        if key then
            Settings.InitTooltip(KEY_BINDING_NAME_AND_KEY:format(bindingName, GetBindingText(key)), KEY_BINDING_TOOLTIP)
        end
    end

    for index, button in ipairs(self.Buttons) do
        button:SetScript("OnClick", function(button, buttonName, down)
            if buttonName == "LeftButton" then
                local oldSelected = initializer.selectedIndex == index;

                if not oldSelected then
                    initializer.selectedIndex = index;
                    self:StartInputListener(button, index, initializer)
                end
            elseif buttonName == "RightButton" then
                FishingMode:SetBinding(action, index, nil)
                initializer.selectedIndex = nil
                self:StopInputListener(button)
                self:UpdateBindingState(initializer)
            else
                self:ProcessInput(button, index, initializer, buttonName)
            end
        end)

        button:SetTooltipFunc(GenerateClosure(InitializeKeyBindingButtonTooltip, index));
        button:SetCustomTooltipAnchoring(button, "ANCHOR_RIGHT", 0, 0);
    end

    self:UpdateBindingState(initializer)
end

function FishingMode:RegisterSettings()
    local category, layout = Settings.RegisterVerticalLayoutCategory("Fishing Mode");
    category.ID = "FishingMode"

    local db = self.db.profile

    do
        local variable = "FishingMode.minimap.hide"
        local name = "Show Minimap Icon"
        local tooltip = "Show the Fishing Mode icon on the edge of the minimap"
        local defaultValue = not db.minimap.hide

        local setting = Settings.RegisterAddOnSetting(category, name, variable, type(defaultValue), defaultValue)
        Settings.SetOnValueChangedCallback(variable, function(event)
            self:SetIconVisible(setting:GetValue())
        end)
        Settings.CreateCheckBox(category, setting, tooltip)
    end

    do
        local variable = "FishingMode.minimap.lock"
        local name = "Lock Minimap Icon"
        local tooltip = "Prevent minimap icon from being moved around"
        local defaultValue = db.minimap.lock

        local setting = Settings.RegisterAddOnSetting(category, name, variable, type(defaultValue), defaultValue)
        Settings.SetOnValueChangedCallback(variable, function(event)
            self:SetIconLocked(setting:GetValue())
        end)
        Settings.CreateCheckBox(category, setting, tooltip)
    end

    do
        local action = "CAST_LINE"
        local name = "Cast Fishing Line"

        local bindingInitializer = Settings.CreateElementInitializer("FishingModeKeyBindingButtonTemplate", { action = action, bindingName = name })
        layout:AddInitializer(bindingInitializer)
    end

    do
        local action = "INTERACT"
        local name = "Interact With Target"

        local bindingInitializer = Settings.CreateElementInitializer("FishingModeKeyBindingButtonTemplate", { action = action, bindingName = name })
        layout:AddInitializer(bindingInitializer)
    end

    do
        local variable = "FishingMode.swapEquipmentSet"
        local name = "Auto-Equip Gear"
        local tooltip = "Automatically equip a set with the name \"Fishing\" and will swap back when exiting fishing mode"
        local defaultValue = db.swapEquipmentSet

        local setting = Settings.RegisterAddOnSetting(category, name, variable, type(defaultValue), defaultValue)
        Settings.SetOnValueChangedCallback(variable, function(event)
            self:SetSwapEquipmentSet(setting:GetValue())
        end)
        Settings.CreateCheckBox(category, setting, tooltip)
    end

    Settings.RegisterAddOnCategory(category)
end
