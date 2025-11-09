local UEHelpers = require("UEHelpers")

local VerboseLogging = true

local function Log(Message)
    if not VerboseLogging then return end
    print(string.format("[FasterTimeControlMod] %s", Message))
end

Log("Initializing FasterTimeControlMod...")

---@type UArcoWidgetBase|nil
local CustomSpeedButton = nil
---@type UArcoWidgetBase|nil
local TimeControlButtonsWidget = nil
---@type UTexture2D|nil
local FastForwardIcon = nil

local function LoadFastForwardIcon()
    if FastForwardIcon and FastForwardIcon:IsValid() then
        return FastForwardIcon
    end
    
    local IconPath = "/Game/Assets/Icons/icons8-fast-forward-100.icons8-fast-forward-100"
    FastForwardIcon = StaticFindObject(IconPath)
    if FastForwardIcon and FastForwardIcon:IsValid() then
        Log("Successfully loaded fast forward icon from: " .. IconPath)
        return FastForwardIcon
    end
    
    Log("Failed to load fast forward icon from any path")
    return nil
end

---@param TimeControlWidget UArcoWidgetBase
---@return UArcoWidgetBase|nil
local function CloneExistingTimeButton(TimeControlWidget)
    if not TimeControlWidget or not TimeControlWidget:IsValid() then
        Log("Invalid TimeControlButtons widget")
        return nil
    end
    
    -- Find an existing button to clone (let's use btn_speed4)
    ---@type UArcoWidgetBase
    local SourceButton = TimeControlWidget.btn_speed4
    if not SourceButton or not SourceButton:IsValid() then
        Log("Could not find btn_speed4 to clone")
        return nil
    end
    
    Log("Cloning from btn_speed4:")
    Log("- Source button class: " .. tostring(SourceButton:GetClass():GetFullName()))
    Log("- Source button path: " .. tostring(SourceButton:GetFullName()))
    
    -- Try to duplicate/clone the widget
    ---@type UArcoWidgetBase|nil
    local ClonedButton = nil
    local Success = pcall(function()
        -- Method 1: Try DuplicateObject if available
        if SourceButton.DuplicateObject then
            ClonedButton = SourceButton:DuplicateObject()
            Log("Used DuplicateObject method")
        -- Method 2: Try CreateWidget with the same class
        elseif SourceButton.GetClass then
            local ButtonClass = SourceButton:GetClass()
            ---@type APlayerController_Play
            local PlayerController = UEHelpers.GetPlayerController()
            local WidgetBlueprintLibrary = StaticFindObject("/Script/UMG.Default__WidgetBlueprintLibrary")
            
            if WidgetBlueprintLibrary and PlayerController then
                ClonedButton = WidgetBlueprintLibrary:Create(TimeControlWidget, ButtonClass, PlayerController)
                Log("Used CreateWidget with existing button class")
            end
        end
    end)
    
    if not Success or not ClonedButton or not ClonedButton:IsValid() then
        Log("Failed to clone button, trying alternative approach...")
        
        -- Method 3: Create from scratch but copy properties
        local TimeButtonClass = SourceButton:GetClass()
        ---@type APlayerController_Play
        local PlayerController = UEHelpers.GetPlayerController()
        local WidgetBlueprintLibrary = StaticFindObject("/Script/UMG.Default__WidgetBlueprintLibrary")
        
        if WidgetBlueprintLibrary and PlayerController and TimeButtonClass then
            ClonedButton = WidgetBlueprintLibrary:Create(TimeControlWidget, TimeButtonClass, PlayerController)
            Log("Created new button from source button class")
        end
    end
    
    if not ClonedButton or not ClonedButton:IsValid() then
        Log("All cloning methods failed")
        return nil
    end
    
    Log("Successfully cloned button:")
    Log("- Cloned button class: " .. tostring(ClonedButton:GetClass():GetFullName()))
    Log("- Cloned button path: " .. tostring(ClonedButton:GetFullName()))
    Log("- Cloned button valid: " .. tostring(ClonedButton:IsValid()))
    
    return ClonedButton
end

local function AddCustomSpeedButton(TimeControlWidget)
    if not TimeControlWidget or not TimeControlWidget:IsValid() then
        Log("Invalid TimeControlButtons widget")
        return false
    end
    
    -- Clone an existing button instead of creating from scratch
    CustomSpeedButton = CloneExistingTimeButton(TimeControlWidget)
    if not CustomSpeedButton then
        Log("Failed to clone existing time button")
        return false
    end
    
    Log("Created button details:")
    Log("- Button valid: " .. tostring(CustomSpeedButton:IsValid()))
    Log("- Button class: " .. tostring(CustomSpeedButton:GetClass():GetFullName()))
    Log("- Button full object path: " .. tostring(CustomSpeedButton:GetFullName()))
    Log("- Button visibility: " .. tostring(CustomSpeedButton:GetVisibility()))
    
    Log("Looking for parent panel of btn_speed4...")
    ---@type UHorizontalBox
    local ParentPanel = TimeControlWidget.btn_speed4:GetParent()
    if not ParentPanel or not ParentPanel:IsValid() then
        Log("Could not find parent panel for buttons")
        return false
    end
    
    Log("Found parent panel:")
    Log("- Panel valid: " .. tostring(ParentPanel:IsValid()))
    Log("- Panel class: " .. tostring(ParentPanel:GetClass():GetFullName()))
    Log("- Panel child count before: " .. tostring(ParentPanel:GetChildrenCount()))
    
    -- Add the cloned button to the HorizontalBox using AddChildToHorizontalBox
    Log("Adding cloned button to HorizontalBox...")
    local Success = pcall(function()
        ---@type UHorizontalBoxSlot
        local Slot = ParentPanel:AddChildToHorizontalBox(CustomSpeedButton)
        if Slot then
            Log("Created new slot in HorizontalBox")
            
            -- Copy slot properties from btn_speed4's slot
            ---@type UHorizontalBoxSlot
            local SourceSlot = TimeControlWidget.btn_speed4.Slot
            if SourceSlot then
                Log("Copying slot properties from btn_speed4")
                pcall(function()
                    if Slot.SetHorizontalAlignment and SourceSlot.HorizontalAlignment ~= nil then
                        Slot:SetHorizontalAlignment(SourceSlot.HorizontalAlignment)
                    end
                    if Slot.SetVerticalAlignment and SourceSlot.VerticalAlignment ~= nil then
                        Slot:SetVerticalAlignment(SourceSlot.VerticalAlignment)
                    end
                    if Slot.SetPadding and SourceSlot.Padding then
                        Slot:SetPadding(SourceSlot.Padding)
                    end
                    if Slot.SetSize and SourceSlot.Size then
                        Slot:SetSize(SourceSlot.Size)
                    end
                end)
            end
        else
            Log("Failed to create slot in HorizontalBox")
            return false
        end
    end)
    
    if not Success then
        Log("Failed to add button to HorizontalBox")
        return false
    end
    
    Log("After adding button:")
    Log("- Panel child count after: " .. tostring(ParentPanel:GetChildrenCount()))
    Log("- Button visibility: " .. tostring(CustomSpeedButton:GetVisibility()))
    Log("- Button render opacity: " .. tostring(CustomSpeedButton:GetRenderOpacity()))
    
    Log("Setting button visibility and properties...")
    pcall(function()
        CustomSpeedButton:SetVisibility(0) -- ESlateVisibility::Visible
        CustomSpeedButton:SetRenderOpacity(1.0)
        if CustomSpeedButton.SetIsEnabled then
            CustomSpeedButton:SetIsEnabled(true)
        end
    end)
    Log("Button visibility after setting: " .. tostring(CustomSpeedButton:GetVisibility()))
    
    Log("Setting up button event listening...")
    pcall(function()
        TimeControlWidget:ListenToWidgetActions(CustomSpeedButton)
    end)
    
    Log("Final button state:")
    Log("- Button is in widget tree: " .. tostring(CustomSpeedButton:IsInViewport()))
    Log("- Button slot index: " .. tostring(ParentPanel:GetChildIndex(CustomSpeedButton)))
    Log("- Final button object path: " .. tostring(CustomSpeedButton:GetFullName()))
    Log("- Parent panel object path: " .. tostring(ParentPanel:GetFullName()))
    Log("- TimeControlWidget object path: " .. tostring(TimeControlWidget:GetFullName()))
    
    return true
end

local function HandleCustomButtonClick(ButtonWidget)
    if not ButtonWidget or ButtonWidget ~= CustomSpeedButton then
        return
    end
    
    Log("5x speed button clicked")
    
    ---@type APlayerController_Play
    local PlayerController = UEHelpers.GetPlayerController()
    if not PlayerController or not PlayerController:IsValid() then
        Log("Could not find player controller")
        return
    end
    
    local Success = pcall(function()
        if PlayerController.SetGameplaySpeed then
            PlayerController:SetGameplaySpeed(5)
            Log("Successfully set gameplay speed to 5x")
        else
            Log("SetGameplaySpeed method not found on PlayerController")
        end
    end)
    
    if not Success then
        Log("Failed to set gameplay speed to 5x")
    end
end

local function UpdateButtonStates(TimeControlWidget, gameplaySpeed, paused)
    if not TimeControlWidget or not CustomSpeedButton then
        return
    end
    
    local isCustomSelected = (not paused) and (gameplaySpeed == 5)
    
    pcall(function()
        if CustomSpeedButton.SetSelected then
            CustomSpeedButton:SetSelected(isCustomSelected)
        end
    end)
end

local function FindTimeControlButtonsWidget()
    Log("Searching for existing TimeControlButtons widget...")
    
    local TimeControlWidgets = FindAllOf("TimeControlButtons_C")
    if TimeControlWidgets then
        for i, widget in pairs(TimeControlWidgets) do
            if widget and widget:IsValid() then
                Log("Found TimeControlButtons widget " .. widget:GetFullName())
                return widget
            end
        end
    end
    
    Log("Could not find TimeControlButtons widget")
    return nil
end

local World = UEHelpers.GetWorld()
if World and World:IsValid() then
    local LevelName = World:GetFName():ToString()
    Log("Current level: " .. LevelName)
    
    if LevelName == "ArcoPlay" then
        Log("ArcoPlay level detected, setting up mod")
        
        ExecuteInGameThread(function()
            local timeControlWidget = FindTimeControlButtonsWidget()
            if timeControlWidget then
                TimeControlButtonsWidget = timeControlWidget
                AddCustomSpeedButton(timeControlWidget)
            else
                Log("TimeControlButtons widget not found yet, will try again later")
            end
        end)
        
        -- RegisterHook("/Game/UI/TimeControlButtons.TimeControlButtons_C:SetData", function(self, gameplaySpeed, paused)
        --     if CustomSpeedButton then
        --         UpdateButtonStates(self, gameplaySpeed, paused)
        --     end
        -- end)
        
        -- RegisterHook("/Script/ProjectArco.ArcoWidgetBase:HudAction", function(self, action)
        --     if self == CustomSpeedButton then
        --         HandleCustomButtonClick(self)
        --     end
        -- end)
        
        Log("Mod setup complete!")
    else
        Log("Not in ArcoPlay level, mod will not activate")
    end
else
    Log("World not available, mod will not activate")
end

Log("FasterTimeControlMod initialization complete!")

