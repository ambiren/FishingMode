FishingModeFrameMixin = {}

function FishingModeFrameMixin:OnLoad()
    self:RegisterEvent("ADDONS_UNLOADING")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
end

function FishingModeFrameMixin:OnEvent(event, ...)
    if event == "ADDONS_UNLOADING" then
        FishingMode:TeardownFishingModeState()
    elseif event == "PLAYER_REGEN_DISABLED" and self:IsShown() then
        self.wasAutoHidden = true
        self:Hide()
    elseif event == "PLAYER_REGEN_ENABLED" and self.wasAutoHidden then
        self.wasAutoHidden = false
        self:Show()
    end
end

function FishingModeFrameMixin:OnShow()
    FishingMode:SetupFishingModeState()
    self:UpdateText()
end

function FishingModeFrameMixin:OnHide()
    FishingMode:TeardownFishingModeState()
end

local function GetBindingText(action)
    local key1 = FishingMode:GetBinding(action, 1)
    local key2 = FishingMode:GetBinding(action, 2)

    if key1 and key2 then
        return key1 .. " / " .. key2
    else
        return key1 or key2 or "<No Key Bound>"
    end
end

local FISHING_MODE_ACTIVE_MESSAGE = "FISHING MODE ENABLED\n%s = Cast Line\n%s = Interact"

function FishingModeFrameMixin:UpdateText()
    self.Text:SetText(FISHING_MODE_ACTIVE_MESSAGE:format(GetBindingText("CAST_LINE"), GetBindingText("INTERACT")))
end
