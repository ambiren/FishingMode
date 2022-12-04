FishingMode = LibStub("AceAddon-3.0"):NewAddon("FishingMode")

local DBIcon = LibStub("LibDBIcon-1.0")
local LDB = LibStub("LibDataBroker-1.1")
local AceDB = LibStub("AceDB-3.0")

BINDING_HEADER_FISHING_MODE = "Fishing Mode"
BINDING_NAME_FISHING_MODE_TOGGLE = "Start/Stop Fishing"
BINDING_NAME_FISHING_MODE_ON = "Start Fishing"
BINDING_NAME_FISHING_MODE_OFF = "Stop Fishing"

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

local defaults = {
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
            }
        },
        swapEquipmentSet = false,
    },
}

function FishingMode:OnInitialize()
    self.db = AceDB:New("FishingModeDB", defaults)

    self.isSetup = false

    local dataObject = LDB:NewDataObject("FishingMode", {
        type = "launcher",
        icon = "Interface\\Icons\\inv_fishingpole_01",
        OnClick = function(clickedFrame, button)
            if button == "LeftButton" then
                if FishingModeFrame:IsShown() then
                    FishingModeFrame:Hide()
                else
                    FishingModeFrame:Show()
                end
            else
                Settings.OpenToCategory("FishingMode")
            end
        end,
        OnTooltipShow = function(tt)
            tt:SetText("Fishing Mode")
            tt:AddLine("|cFFCFCFCFLeft-click|r: Toggle Fishing Mode")
            tt:AddLine("|cFFCFCFCFRight-click|r: Open Settings")
        end,
    })
    
    DBIcon:Register("FishingMode", dataObject, self.db.profile.minimap)

    FishingMode:RegisterSettings()
end

function FishingMode:OnEnable()
    -- Fishing mode is never active upon login. If we didn't swap the set back before logging out, restore it as soon as possible
    -- TODO: Handle the case where the player logs into a combat lockdown
    if not InCombatLockdown() then
        FishingMode:RestoreEquipmentSet()
    end
end

function FishingMode:SetBinding(action, index, value)
    -- Have to save the bindings as empty string since saving nil messes up AceDB's merging of saved settings and defaults
    self.db.profile.bindings[action][index] = value or ""

    if FishingModeFrame:IsShown() then
        FishingModeFrame:UpdateText()
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
        C_EquipmentSet.UseEquipmentSet(setId)
        C_EquipmentSet.DeleteEquipmentSet(setId)
        return true
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


function FishingMode:SetupFishingModeState()
    if self.isSetup then
        return
    end

    self.isSetup = true

    self.originalSettings = {}
    for name, value in pairs(self.DESIRED_SETTINGS) do
        self.originalSettings[name] = GetCVar(name)
        SetCVar(name, value)
    end
    
    local function SetOverrideBindingFromConfig(name, action)
        for i = 1, 2 do
            local key = self:GetBinding(name, i)
            if key then
                SetOverrideBinding(FishingModeFrame, false, key, action)
            end
        end
    end

    SetOverrideBindingFromConfig("CAST_LINE", "SPELL Fishing")
    SetOverrideBindingFromConfig("INTERACT", "INTERACTTARGET")

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
end

function FishingMode:TeardownFishingModeState()
    if not self.isSetup then
        return
    end

    self.isSetup = false

    for name, value in pairs(self.originalSettings) do
        SetCVar(name, value)
    end

    ClearOverrideBindings(FishingModeFrame)

    if self.db.profile.swapEquipmentSet and self.didSwapEquipmentSet then
        if not self:RestoreEquipmentSet() then
            self:DisplayError("Fishing Mode: Failed to equip original items.")
        end
    end
end

function FishingMode:SetIconVisible(visible)
    self.db.profile.minimap.hide = not visible
    if visible then
        DBIcon:Show("FishingMode")
    else
        DBIcon:Hide("FishingMode")
    end
end

function FishingMode:SetIconLocked(locked)
    self.db.profile.minimap.lock = locked
    if locked then
        DBIcon:Lock("FishingMode")
    else
        DBIcon:Unlock("FishingMode")
    end
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

function FishingMode:SetSwapEquipmentSet(enabled)
    self.db.profile.swapEquipmentSet = enabled

    if enabled then
        local setId = C_EquipmentSet.GetEquipmentSetID("Fishing")
        if not setId then
            StaticPopup_Show("FISHING_MODE_DIALOG_CREATE_SET")
        end
    end
end

function FishingMode:DisplayError(message)
    UIErrorsFrame:AddMessage(message, 1.0, 0.1, 0.1, 1.0)
end

function FishingMode:IsActive()
    return FishingModeFrame:IsShown()
end

function FishingMode:Start()
    if self:IsActive() then
        return
    end
    
    if InCombatLockdown() then
        self:DisplayError("Can't start fishing mode during combat lockdown.")
    else 
        FishingModeFrame:Show()
    end
end

function FishingMode:Stop()
    if not self:IsActive() then
        return
    end

    if InCombatLockdown() then
        self:DisplayError("Can't stop fishing mode during combat lockdown.")
    else 
        FishingModeFrame:Hide()
    end
end
