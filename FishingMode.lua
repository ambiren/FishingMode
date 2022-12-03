FishingMode = LibStub("AceAddon-3.0"):NewAddon("FishingMode")

local DBIcon = LibStub("LibDBIcon-1.0")
local LDB = LibStub("LibDataBroker-1.1")
local AceDB = LibStub("AceDB-3.0")

BINDING_HEADER_FISHING_MODE = "Fishing Mode"
BINDING_NAME_FISHING_MODE_TOGGLE = "Start/Stop Fishing"

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
		swapSet = false,
	},
}

function FishingMode:OnInitialize()
	self.db = AceDB:New("FishingModeDB", defaults)

	self.isEnabled = false

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
		FishingMode:RestoreGearSet()
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
function FishingMode:CreateBackupGearSet()
	local setId = C_EquipmentSet.GetEquipmentSetID(FISHING_MODE_EQUIPMENT_SET_NAME)

	-- We only want to create a backup if we don't already have one
	-- If a backup exists it's because we couldn't swap when we existed fishing mode
	if not setId then
		C_EquipmentSet.CreateEquipmentSet(FISHING_MODE_EQUIPMENT_SET_NAME)
	end
end

function FishingMode:RestoreGearSet()
	local setId = C_EquipmentSet.GetEquipmentSetID(FISHING_MODE_EQUIPMENT_SET_NAME)
	if setId then
		C_EquipmentSet.UseEquipmentSet(setId)
		C_EquipmentSet.DeleteEquipmentSet(setId)
		return true
	else
		return false
	end
end

function FishingMode:SetupFishingModeState()
	if self.isEnabled then
		return
	end

	self.isEnabled = true

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

	if self.db.profile.swapSet and not InCombatLockdown() then
		local setId = C_EquipmentSet.GetEquipmentSetID("Fishing")
		if setId then
			self:CreateBackupGearSet()
			C_EquipmentSet.UseEquipmentSet(setId)
			self.didSwapSet = true
		else
			UIErrorsFrame:AddMessage("Fishing Mode: Cannot swap gear, no set named Fishing", 1.0, 0.1, 0.1, 1.0)
			self.didSwapSet = false
		end
	end 
end

function FishingMode:TeardownFishingModeState()
	if not self.isEnabled then
		return
	end

	self.isEnabled = false

	for name, value in pairs(self.originalSettings) do
		SetCVar(name, value)
	end

	ClearOverrideBindings(FishingModeFrame)

	if self.db.profile.swapSet and self.didSwapSet then
		if not self:RestoreGearSet() then
			UIErrorsFrame:AddMessage("Fishing Mode: Failed to equip original gear", 1.0, 0.1, 0.1, 1.0)
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