FishingModeKeyBindingButtonTemplateMixin = {}

function FishingModeKeyBindingButtonTemplateMixin:ProcessInput(button, index, initializer, input)
    local key = FishingMode:ConvertInputToKey(input)
    if key then
        FishingMode:SetBinding(initializer.data.action, index, key)
    end

    initializer.selectedIndex = nil
    self:StopInputListener(button)
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

local function MakeBindingSettingName(action, index)
    return "FishingMode." .. action .. "." .. index
end

function FishingModeKeyBindingButtonTemplateMixin:RefreshBindings(action)
    for index, button in ipairs(self.Buttons) do
        local binding = FishingMode:GetBinding(action, index)
        BindingButtonTemplate_SetupBindingButton(binding, button)
        Settings.SetValue(MakeBindingSettingName(action, index), binding or "")
    end
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

    FishingMode.RegisterCallback(self, "FISHING_MODE_BINDING_CHANGED", function(event, a, i, binding)
        if not a then
            self:RefreshBindings(action)
        elseif a == action then
            BindingButtonTemplate_SetupBindingButton(binding, self.Buttons[i])
            Settings.SetValue(MakeBindingSettingName(a, i), binding or "")
        end
    end)

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
            else
                self:ProcessInput(button, index, initializer, buttonName)
            end
        end)

        button:SetTooltipFunc(GenerateClosure(InitializeKeyBindingButtonTooltip, index));
        button:SetCustomTooltipAnchoring(button, "ANCHOR_RIGHT", 0, 0);
    end

    for index, button in ipairs(self.Buttons) do
        BindingButtonTemplate_SetupBindingButton(FishingMode:GetBinding(initializer.data.action, index), button)
    end
end

function FishingMode:RefreshSettings()
    local db = self.db.profile
    Settings.SetValue("FishingMode.minimap.hide", not db.minimap.hide)
    Settings.SetValue("FishingMode.minimap.lock", db.minimap.lock)
    Settings.SetValue("FishingMode.overlayVisible", db.overlayVisible)
    Settings.SetValue("FishingMode.swapEquipmentSet", db.swapEquipmentSet)
    FishingMode.callbacks:Fire("FISHING_MODE_BINDING_CHANGED")
    FishingMode:MoveOverlayToPosition(db.overlayPosition)
end

function FishingMode:RegisterSettings()
    local category, layout = Settings.RegisterVerticalLayoutCategory("Fishing Mode");
    category.ID = "FishingMode"

    local defaults = self.defaults.profile
    local db = self.db.profile

    local function RegisterBindingSetting(name, action, index)
        local variable = MakeBindingSettingName(action, index)
        local setting = Settings.RegisterAddOnSetting(category, name, variable, "string", defaults.bindings[action][index])
        setting:SetValue(FishingMode:GetBinding(action, index) or "")
        Settings.SetOnValueChangedCallback(variable, function(event)
            local val = setting:GetValue()
            if val == "" then
                val = nil
            end
            FishingMode:SetBinding(action, index, val)
        end)
    end

    do
        local variable = "FishingMode.minimap.hide"
        local name = "Show Minimap Icon"
        local tooltip = "Show the Fishing Mode icon on the edge of the minimap"
        local defaultValue = not defaults.minimap.hide
        local initialValue = not db.minimap.hide

        local setting = Settings.RegisterAddOnSetting(category, name, variable, type(defaultValue), defaultValue)
        Settings.SetOnValueChangedCallback(variable, function(event)
            self:SetIconVisible(setting:GetValue())
        end)
        setting:SetValue(initialValue)
        Settings.CreateCheckBox(category, setting, tooltip)
    end

    do
        local variable = "FishingMode.minimap.lock"
        local name = "Lock Minimap Icon"
        local tooltip = "Prevent minimap icon from being moved around"
        local defaultValue = defaults.minimap.lock
        local initialValue = db.minimap.lock

        local setting = Settings.RegisterAddOnSetting(category, name, variable, type(defaultValue), defaultValue)
        Settings.SetOnValueChangedCallback(variable, function(event)
            self:SetIconLocked(setting:GetValue())
        end)
        setting:SetValue(initialValue)
        Settings.CreateCheckBox(category, setting, tooltip)
    end

    do
        local variable = "FishingMode.overlayVisible"
        local name = "Show Overlay"
        local tooltip = "Shows an overlay to indicate when fishing mode is active"
        local defaultValue = defaults.overlayVisible
        local initialValue = db.overlayVisible

        local setting = Settings.RegisterAddOnSetting(category, name, variable, type(defaultValue), defaultValue)
        Settings.SetOnValueChangedCallback(variable, function(event)
            self:SetOverlayVisible(setting:GetValue())
        end)
        setting:SetValue(initialValue)

        local initializer = Settings.CreateControlInitializer("SettingsCheckBoxWithButtonControlTemplate", setting, nil, tooltip);
        initializer.data.buttonText = "Move/Resize Overlay"
        initializer.data.OnButtonClick = function(...)
            SettingsPanel:Hide()
            FishingModeEditModeFrame.openSettingsOnHide = true
            FishingModeEditModeFrame:Show()
        end
        layout:AddInitializer(initializer);
    end

    do
        local action = "CAST_LINE"
        local name = "Cast Fishing Line"

        RegisterBindingSetting(name, action, 1)
        RegisterBindingSetting(name, action, 2)

        local bindingInitializer = Settings.CreateElementInitializer("FishingModeKeyBindingButtonTemplate", { action = action, bindingName = name })
        layout:AddInitializer(bindingInitializer)
    end

    do
        local action = "INTERACT"
        local name = "Interact With Target"

        RegisterBindingSetting(name, action, 1)
        RegisterBindingSetting(name, action, 2)

        local bindingInitializer = Settings.CreateElementInitializer("FishingModeKeyBindingButtonTemplate", { action = action, bindingName = name })
        layout:AddInitializer(bindingInitializer)
    end

    do
        local variable = "FishingMode.swapEquipmentSet"
        local name = "Auto-Equip Gear"
        local tooltip = "Automatically equip a set with the name \"Fishing\" and will swap back when exiting fishing mode. Your rod effect is always active when fishing, so this is generally not needed."
        local defaultValue = defaults.swapEquipmentSet
        local initialValue = db.swapEquipmentSet

        local setting = Settings.RegisterAddOnSetting(category, name, variable, type(defaultValue), defaultValue)
        Settings.SetOnValueChangedCallback(variable, function(event)
            self:SetSwapEquipmentSet(setting:GetValue())
        end)
        setting:SetValue(initialValue)
        Settings.CreateCheckBox(category, setting, tooltip)
    end

    Settings.RegisterAddOnCategory(category)

    local options = {
        type = "group",
        args = {
            profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(FishingMode.db)
        }
    }
    options.args.profiles.inline = true

    LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("Fishing Mode", options)

    FishingMode.db.RegisterCallback(FishingMode, "OnProfileChanged", "RefreshSettings")
    FishingMode.db.RegisterCallback(FishingMode, "OnProfileCopied", "RefreshSettings")
    FishingMode.db.RegisterCallback(FishingMode, "OnProfileReset", "RefreshSettings")

    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Fishing Mode", "Profiles", "FishingMode")
end
