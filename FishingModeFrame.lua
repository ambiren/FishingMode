FishingModeOverlayFrameMixin = {
    suppressFishingModeToggle = false,
    refCount = 0,
}

function FishingModeOverlayFrameMixin:OnLoad()
    self:RegisterForDrag("LeftButton")
    self:EnableMouse(false)
end

function FishingModeOverlayFrameMixin:RefCountedShow()
    self.refCount = self.refCount + 1
    if self.refCount == 1 then
        self:Show()
    end
end

function FishingModeOverlayFrameMixin:RefCountedHide()
    self.refCount = self.refCount - 1
    if self.refCount == 0 then
        self:Hide()
    end
end

function FishingModeOverlayFrameMixin:OnShow()
    self:UpdateText()
end

function FishingModeOverlayFrameMixin:OnHide()
    self:StopMovingOrSizing()
end

function FishingModeOverlayFrameMixin:OnDragStart()
    self:StartMoving()
end

function FishingModeOverlayFrameMixin:OnDragStop()
    self:StopMovingOrSizing()
end

function FishingModeOverlayFrameMixin:SaveLayout()
    FishingMode:SaveCurrentOverlayPosition()
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

function FishingModeOverlayFrameMixin:UpdateText()
    self.Text:SetText(FISHING_MODE_ACTIVE_MESSAGE:format(GetBindingText("CAST_LINE"), GetBindingText("INTERACT")))
end

FishingModeEditModeFrameMixin = {}

function FishingModeEditModeFrameMixin:OnLoad()
    self:RegisterForDrag("LeftButton")
    self.CancelButton:SetText(CANCEL);
	self.CancelButton:SetScript("OnClick", function(button, buttonName, down)
        FishingMode:LoadOverlayPosition()
        self:Hide()
	end);

	self.OkayButton:SetText(OKAY);
	self.OkayButton:SetScript("OnClick", function(button, buttonName, down)
        FishingMode:SaveCurrentOverlayPosition()
        self:Hide()
	end);
	
	self.DefaultsButton:SetText(RESET_TO_DEFAULT);
	self.DefaultsButton:SetScript("OnClick", function(button, buttonName, down)
        FishingMode:MoveOverlayToDefaultPosition()
        self.ScaleSlider.Slider:SetValue(FishingModeOverlayFrame:GetScale())
	end);

    self.ScaleSlider.Slider:Init(FishingModeOverlayFrame:GetScale(), 0.1, 2.0, 19, {
        [self.ScaleSlider.Slider.Label.Right] = function(val) return ("%d%%"):format(val * 100) end})
    self.ScaleSlider.Slider.RightText:Show()
    self.ScaleSlider.Label:SetText("Scale")

    self.cbrHandles = EventUtil.CreateCallbackHandleContainer()
	self.cbrHandles:RegisterCallback(self.ScaleSlider.Slider, MinimalSliderWithSteppersMixin.Event.OnValueChanged, self.OnScaleSliderValueChanged, self)
end

function FishingModeEditModeFrameMixin:OnScaleSliderValueChanged(value)
    FishingModeOverlayFrame:SetScale(value)
end

function FishingModeEditModeFrameMixin:OnShow()
    self.ScaleSlider.Slider:SetValue(FishingModeOverlayFrame:GetScale())

    FishingModeOverlayFrame:EnableMouse(true)

    FishingModeOverlayFrame:RefCountedShow()
    FishingModeOverlayFrame.Text:Show()
end

function FishingModeEditModeFrameMixin:OnHide()
    self:StopMovingOrSizing()

    FishingModeOverlayFrame:EnableMouse(false)

    FishingModeOverlayFrame:RefCountedHide()
    FishingModeOverlayFrame.Text:SetShown(FishingMode.db.profile.overlayVisible)
end

function FishingModeEditModeFrameMixin:OnDragStart()
    self:StartMoving()
end

function FishingModeEditModeFrameMixin:OnDragStop()
    self:StopMovingOrSizing()
end