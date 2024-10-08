FishingMode = LibStub("AceAddon-3.0"):NewAddon("FishingMode")
FishingMode.VERSION = "@project-version@"

local DBIcon = LibStub("LibDBIcon-1.0")
local LDB = LibStub("LibDataBroker-1.1")
local AceDB = LibStub("AceDB-3.0")

BINDING_HEADER_FISHING_MODE = "Fishing Mode"
BINDING_NAME_FISHING_MODE_TOGGLE = "Start/Stop Fishing"
BINDING_NAME_FISHING_MODE_ON = "Start Fishing"
BINDING_NAME_FISHING_MODE_OFF = "Stop Fishing"

FishingMode.callbacks = LibStub("CallbackHandler-1.0"):New(FishingMode)

FishingMode.ICON_NORMAL = "Interface\\AddOns\\FishingMode\\media\\fish_hook"
FishingMode.ICON_ACTIVE = "Interface\\AddOns\\FishingMode\\media\\fish_hook_green"
FishingMode.ICON_PAUSED = "Interface\\AddOns\\FishingMode\\media\\fish_hook_orange"

FishingMode.DESIRED_SETTINGS = {
    SoftTargetEnemy = "0",
    SoftTargetFriend = "0",
    SoftTargetInteract = "3",
    SoftTargetInteractArc = "2",
    SoftTargetInteractRange = "20",
    SoftTargetIconInteract = "1",
    SoftTargetIconGameObject = "1",
    autoLootDefault = "1",
}

FishingMode.defaults = {
    profile = {
        minimap = {
            hide = false,
            lock = false,
        },
        bindings = {
            CAST_LINE = {
                [1] = "1",
                [2] = "",
            },
            INTERACT = {
                [1] = "2",
                [2] = "",
            },
        },
        swapEquipmentSet = false,
        overlayVisible = true,
        overlayPosition = {
            x = 0,
            y = 0,
            scale = 1,
        },
        pauseWhenMounted = true,
        removeCosmeticBuff = false,
        volumeOverrideEnabled = false,
        volumeOverrides = {
            Master = {
                isOverridden = false,
                level = 1.0,
            },
            Ambience = {
                isOverridden = true,
                level = 0.0,
            },
            Dialog = {
                isOverridden = false,
                level = 1.0,
            },
            Music = {
                isOverridden = true,
                level = 0.0,
            },
            SFX = {
                isOverridden = true,
                level = 1.0,
            },
        },
        macros = {}
    },
}

for macroIndex = 1, 5 do
    FishingMode.defaults.profile.bindings[("MACRO%d"):format(macroIndex)] = {
        [1] = "",
        [2] = "",
    }
    FishingMode.defaults.profile.macros[macroIndex] = ""
end

function FishingMode_OnAddonCompartmentClick(addonName, button)
    FishingMode:OnIconClick(button)
end

function FishingMode_OnAddonCompartmentEnter(...)
    GameTooltip:SetOwner(AddonCompartmentFrame, "ANCHOR_TOPRIGHT")
    FishingMode:PopulateTooltip(GameTooltip)
    GameTooltip:Show()
end

function FishingMode_OnAddonCompartmentLeave(...)
    GameTooltip:Hide()
end

function FishingMode:PopulateTooltip(tt)
    tt:SetText("Fishing Mode")
    tt:AddLine(("|cFFC2C2C2%s|r"):format(self.VERSION))
    tt:AddLine(" ")
    tt:AddLine("|cFFCFCFCFLeft-click|r: Toggle Fishing Mode")
    tt:AddLine("|cFFCFCFCFRight-click|r: Open Settings")
    tt:AddLine("|cFFCFCFCFShift-Right-click|r: Move/Resize Overlay")
end

function FishingMode:OnIconClick(button)
    if button == "LeftButton" then
        if FishingMode:IsActive() then
            FishingMode:Stop()
        else
            FishingMode:Start()
        end
    else
        if IsShiftKeyDown() then
            FishingModeEditModeFrame:Show()
        else
            Settings.OpenToCategory("FishingMode")
        end
    end
end

function FishingMode:OnInitialize()
    self.db = AceDB:New("FishingModeDB", self.defaults)

    self.isActive = false
    self.didPauseForCombat = false
    self.didPauseForMount = false
    self.pauseCount = 0

    self.dataObject = LDB:NewDataObject("FishingMode", {
        type = "launcher",
        icon = self.ICON_NORMAL,
        OnClick = function(clickedFrame, button)
            self:OnIconClick(button)
        end,
        OnTooltipShow = function(tt) self:PopulateTooltip(tt) end,
    })
    DBIcon:Register("FishingMode", self.dataObject, self.db.profile.minimap)

    self.frame = CreateFrame("Frame")
    self.frame:Hide()

    self.frame:RegisterEvent("ADDONS_UNLOADING")
    self.frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.frame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")

    self.frame:SetScript("OnEvent", function(_, event, ...)
        if event == "ADDONS_UNLOADING" then
            self:Stop()
        elseif event == "PLAYER_REGEN_DISABLED" and self:IsActiveOrPaused() then
            self:Pause()
            self.didPauseForCombat = true
        elseif event == "PLAYER_REGEN_ENABLED" and self.didPauseForCombat then
            self:Start(true)
        elseif event == "PLAYER_MOUNT_DISPLAY_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
            self:HandleMountStateChange()
        end
    end)

    self.frame.buttons = {}
    for macroIndex = 1, 5 do
        local button = CreateFrame("Button", ("FishingModeMacroButton%d"):format(macroIndex), self.frame, "SecureActionButtonTemplate")
        button:SetAttribute("type", "macro")
        button:SetAttribute("macrotext", self.db.profile.macros[macroIndex])
        self.frame.buttons[macroIndex] = button
    end

    FishingModeOverlayFrame.Text:SetShown(self.db.profile.overlayVisible)
    self:LoadOverlayPosition()

    self:RegisterSettings()
end

function FishingMode:HandleMountStateChange()
    if self.db.profile.pauseWhenMounted and self:IsActiveOrPaused() then
        if not self.didPauseForMount and IsMounted() then
            self:Pause()
            self.didPauseForMount = true
        elseif self.didPauseForMount and not IsMounted() then
            self:Start(true)
        end
    end
end

function FishingMode:OnEnable()
    -- Fishing mode is never active upon login. If we didn't swap the set back before logging out, restore it as soon as possible
    -- TODO: Handle the case where the player logs into a combat lockdown
    if not InCombatLockdown() then
        FishingMode:RestoreEquipmentSet()
    end
end

function FishingMode:SetBinding(action, index, value)
    -- Have to save null bindings as empty string since saving nil messes up AceDB's merging of saved settings and defaults
    self.db.profile.bindings[action][index] = value or ""
    self.callbacks:Fire("FISHING_MODE_BINDING_CHANGED", action, index, value)

    -- If the binding duplicates another binding, delete that binding
    if value then
        for a, actions in pairs(self.db.profile.bindings) do
            for i, binding in ipairs(actions) do
                if binding == value and (a ~= action or i ~= index) then
                    actions[i] = ""
                    self.callbacks:Fire("FISHING_MODE_BINDING_CHANGED", a, i, nil)
                end
            end
        end
    end

    if FishingModeOverlayFrame:IsShown() then
        FishingModeOverlayFrame:UpdateText()
    end
end

function FishingMode:GetBinding(action, index)
    local value = self.db.profile.bindings[action][index]
    if value == "" then
        return nil
    else
        return value
    end
end

local FISHING_MODE_EQUIPMENT_SET_NAME = "Fishing Mode Backup"
function FishingMode:CreateBackupEquipmentSet()
    local setId = C_EquipmentSet.GetEquipmentSetID(FISHING_MODE_EQUIPMENT_SET_NAME)

    -- We only want to create a backup if we don't already have one
    -- If a backup exists it's because we couldn't swap when we existed fishing mode
    if not setId then
        C_EquipmentSet.CreateEquipmentSet(FISHING_MODE_EQUIPMENT_SET_NAME)
    end
end

function FishingMode:RestoreEquipmentSet()
    local setId = C_EquipmentSet.GetEquipmentSetID(FISHING_MODE_EQUIPMENT_SET_NAME)
    if setId then
        if C_EquipmentSet.UseEquipmentSet(setId) then
            C_EquipmentSet.DeleteEquipmentSet(setId)
            return true
        else
            return false
        end
    else
        return false
    end
end

local TEMPLATE_IGNORED_SLOTS = {
    INVSLOT_AMMO,
    INVSLOT_BACK,
    INVSLOT_BODY,
    INVSLOT_CHEST,
    INVSLOT_FEET,
    INVSLOT_FINGER1,
    INVSLOT_FINGER2,
    INVSLOT_HAND,
    INVSLOT_LEGS,
    INVSLOT_MAINHAND,
    INVSLOT_NECK,
    INVSLOT_RANGED,
    INVSLOT_SHOULDER,
    INVSLOT_TABARD,
    INVSLOT_TRINKET1,
    INVSLOT_TRINKET2,
    INVSLOT_WAIST,
    INVSLOT_WRIST,
    INVSLOT_MAINHAND,
    INVSLOT_OFFHAND,
}

local TEMPLATE_TRACKED_SLOTS = {
    INVSLOT_HEAD,
}

function FishingMode:CreateTemplateEquipmentSet()
    C_EquipmentSet.CreateEquipmentSet("Fishing",  "inv_fishingpole_01")
    local setId = C_EquipmentSet.GetEquipmentSetID("Fishing")

    for _, slot in ipairs(TEMPLATE_IGNORED_SLOTS) do
        C_EquipmentSet.IgnoreSlotForSave(slot)
    end

    for _, slot in ipairs(TEMPLATE_TRACKED_SLOTS) do
        C_EquipmentSet.UnignoreSlotForSave(slot)
    end

    C_EquipmentSet.SaveEquipmentSet(setId)
end

function FishingMode:OnIconVisibleChanged()
    if self.db.profile.minimap.hide then
        DBIcon:Hide("FishingMode")
    else
        DBIcon:Show("FishingMode")
    end
end

function FishingMode:OnIconLockedChanged()
    if self.db.profile.minimap.lock then
        DBIcon:Lock("FishingMode")
    else
        DBIcon:Unlock("FishingMode")
    end
end

function FishingMode:OnOverlayVisibleChanged()
    FishingModeOverlayFrame.Text:SetShown(self.db.profile.overlayVisible)
end

function FishingMode:MoveOverlayToPosition(position)
    FishingModeOverlayFrame:ClearAllPoints()
    FishingModeOverlayFrame:SetPoint("CENTER", UIParent, "CENTER", position.x / position.scale, position.y / position.scale)
    FishingModeOverlayFrame:SetScale(position.scale)
end

function FishingMode:MoveOverlayToDefaultPosition()
    self:MoveOverlayToPosition(defaults.profile.overlayPosition)
end

function FishingMode:LoadOverlayPosition()
    self:MoveOverlayToPosition(self.db.profile.overlayPosition)
end

function FishingMode:SaveCurrentOverlayPosition()
    local scale = FishingModeOverlayFrame:GetScale()

	local left = FishingModeOverlayFrame:GetLeft() * scale
    local top = FishingModeOverlayFrame:GetTop() * scale
    local right = FishingModeOverlayFrame:GetRight() * scale
    local bottom = FishingModeOverlayFrame:GetBottom() * scale

    local x = (left + right) / 2 - UIParent:GetWidth() / 2
    local y = (bottom + top) / 2 - UIParent:GetHeight() / 2

    self.db.profile.overlayPosition.x = x
    self.db.profile.overlayPosition.y = y
    self.db.profile.overlayPosition.scale = scale
end

function FishingMode:ConvertInputToKey(input)
    local currentAction = GetBindingFromClick(input)
    if currentAction == "SCREENSHOT" then
        RunBinding("SCREENSHOT")
        return nil;
    end

    if input == "ESCAPE" and currentAction == "TOGGLEGAMEMENU" then
        return nil;
    end

    local key = GetConvertedKeyOrButton(input);
    if IsKeyPressIgnoredForBinding(key) then
        return nil;
    end

    return key
end

StaticPopupDialogs["FISHING_MODE_DIALOG_CREATE_SET"] = {
    text = "You currently have no set named Fishing. Do you want to create a template set?",
    button1 = "Create Set",
    button2 = "Don't Create Set",
    OnAccept = function()
        FishingMode:CreateTemplateEquipmentSet()

        -- Allow the current dialog to disappear so the next one is not shifted down
        C_Timer.After(0, function()
            StaticPopup_Show("FISHING_MODE_DIALOG_CREATE_SET_FINISHED")
        end)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

StaticPopupDialogs["FISHING_MODE_DIALOG_CREATE_SET_FINISHED"] = {
    text = "Fishing set created. Change the items through Equipment Manager.",
    button1 = "Okay",
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    enterClicksFirstButton = true,
}

function FishingMode:OnSwapEquipmentSetChanged()
    if self.db.profile.swapEquipmentSet and IsPlayerInWorld() then
        local setId = C_EquipmentSet.GetEquipmentSetID("Fishing")
        if not setId then
            StaticPopup_Show("FISHING_MODE_DIALOG_CREATE_SET")
        end
    end
end

function FishingMode:DisplayError(message)
    UIErrorsFrame:AddMessage(message, RED_FONT_COLOR:GetRGB())
end

function FishingMode:DisplayInfo(message)
    UIErrorsFrame:AddMessage(message, YELLOW_FONT_COLOR:GetRGB())
end

function FishingMode:IsActive()
    return self.isActive
end

function FishingMode:ChangeCVar(name, value)
    if self.originalSettings[name] == nil then
        self.originalSettings[name] = GetCVar(name)
    end

    SetCVar(name, value)
end

local function GetVolumeCVarName(channelName)
    return "Sound_" .. channelName .. "Volume"
end

function FishingMode:OnOverrideGlobalEnabledChanged()
    for k, _ in pairs(self.db.profile.volumeOverrides) do
        self:OnVolumeOverrideSettingChanged(k)
    end
end

function FishingMode:OnVolumeOverrideSettingChanged(channelName)
    local volumeSettingName = GetVolumeCVarName(channelName)
    if self:IsActive() then
        local override = self.db.profile.volumeOverrides[channelName]
        if self.db.profile.volumeOverrideEnabled and override and override.isOverridden then
            self:ChangeCVar(volumeSettingName, override.level)
        end
    elseif self.originalSettings and self.originalSettings[volumeSettingName] ~= nil then
        SetCVar(volumeSettingName, self.originalSettings[volumeSettingName])
        self.originalSettings[volumeSettingName] = nil
    end
end

function FishingMode:IsActiveOrPaused()
    return self:IsActive() or self:IsPaused()
end

function FishingMode:IsPaused()
    return self.didPauseForCombat or self.didPauseForMount
end

function FishingMode:OnPauseWhenMountedChanged()
    if not FishingMode:IsActiveOrPaused() then
        return
    end

    self:HandleMountStateChange()
end

function FishingMode:OnMacroChanged(macroIndex)
    self.frame.buttons[macroIndex]:SetAttribute("macrotext", self.db.profile.macros[macroIndex])
end

local function RemovePlayerBuffByID(spellID)
    for buffIndex = 1, 40 do
        local buffAtIndex = C_UnitAuras.GetBuffDataByIndex("player", buffIndex)
        if buffAtIndex and buffAtIndex.spellId == spellID then
            if UnitAffectingCombat("player") then
                spellFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
            else
                CancelUnitBuff("player", buffIndex)
            end

            return
        end
    end
end

function FishingMode:Start(isResuming)
    if self:IsActive() then
        return
    end

    if InCombatLockdown() then
        self:DisplayError("Can't start fishing mode during combat lockdown.")
        return
    end

    self.isActive = true

    -- Ensure these are always reset when we start fishing mode
    -- Necessary for the case where we've paused, but then the explicit start
    -- keybind is pressed
    self.didPauseForCombat = false
    self.didPauseForMount = false

    self.originalSettings = {}
    for name, value in pairs(self.DESIRED_SETTINGS) do
        self:ChangeCVar(name, value)
    end

    if self.db.profile.volumeOverrideEnabled then
        for k, _ in pairs(self.db.profile.volumeOverrides) do
            self:OnVolumeOverrideSettingChanged(k)
        end
    end

    local function SetOverrideBindingFromConfig(name, action)
        for i = 1, 2 do
            local key = self:GetBinding(name, i)
            if key then
                SetOverrideBinding(self.frame, false, key, action)
            end
        end
    end

    SetOverrideBindingFromConfig("CAST_LINE", "SPELL Fishing")
    SetOverrideBindingFromConfig("INTERACT", "INTERACTTARGET")

    for macroIndex = 1, 5 do
        SetOverrideBindingFromConfig(("MACRO%d"):format(macroIndex), ("CLICK FishingModeMacroButton%d:LeftButton"):format(macroIndex))
    end

    if self.db.profile.swapEquipmentSet and not InCombatLockdown() then
        local setId = C_EquipmentSet.GetEquipmentSetID("Fishing")
        if setId then
            self:CreateBackupEquipmentSet()
            C_EquipmentSet.UseEquipmentSet(setId)
            self.didSwapEquipmentSet = true
        else
            self:DisplayError("Fishing Mode: Cannot change equipment, no set named Fishing.")
            self.didSwapEquipmentSet = false
        end
    end

    self.frame:Show()
    FishingModeOverlayFrame:RefCountedShow()

    self.dataObject.icon = self.ICON_ACTIVE

    if not isResuming then
        self.callbacks:Fire("FISHING_MODE_STARTED")

        -- We might need to pause right away if fishing mode was started while mounted
        -- We still fire the event before this to guarantee to listeners that fishing mode
        -- can't pause when it hasn't been started
        self:HandleMountStateChange()

        if not self.didPauseForMount then
            self:DisplayInfo("Fishing Mode Started")
        end
    else
        self:DisplayInfo("Fishing Mode Resumed")
        self.callbacks:Fire("FISHING_MODE_RESUMED")
    end
end

function FishingMode:RevertState()
    for name, value in pairs(self.originalSettings) do
        SetCVar(name, value)
    end

    table.wipe(self.originalSettings)

    ClearOverrideBindings(self.frame)

    self.frame:Hide()
    FishingModeOverlayFrame:RefCountedHide()

    self.isActive = false
end

function FishingMode:Pause()
    if not self:IsActive() then
        return
    end

    if InCombatLockdown() then
        self:DisplayError("Can't pause fishing mode during combat lockdown.")
        return
    end

    self:RevertState()

    self:DisplayInfo("Fishing Mode Paused")
    self.dataObject.icon = self.ICON_PAUSED
    self.callbacks:Fire("FISHING_MODE_PAUSED")
end

function FishingMode:Stop()
    if not self:IsActiveOrPaused() then
        return
    end

    if InCombatLockdown() then
        self:DisplayError("Can't stop fishing mode during combat lockdown.")
        return
    end

    -- We already reverted state if we've paused, so don't try to do it again
    if not self:IsPaused() then
        self:RevertState()
    end

    -- We don't swap the equipment set back when pausing because it siliently fails when
    -- we attempt to do it during the combat lockdown transition
    if self.db.profile.swapEquipmentSet and self.didSwapEquipmentSet then
        if not self:RestoreEquipmentSet() then
            self:DisplayError("Fishing Mode: Failed to equip original items.")
        end
    end

    if self.db.profile.removeCosmeticBuff then
        RemovePlayerBuffByID(394009)
    end

    self.didPauseForCombat = false
    self.didPauseForMount = false

    self:DisplayInfo("Fishing Mode Stopped")
    self.dataObject.icon = self.ICON_NORMAL
    self.callbacks:Fire("FISHING_MODE_STOPPED")
end

function FishingMode:Toggle()
    if FishingMode:IsActiveOrPaused() then
        FishingMode:Stop()
    else
        FishingMode:Start()
    end
end
