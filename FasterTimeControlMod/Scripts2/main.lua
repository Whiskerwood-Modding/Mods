local UEHelpers = require("UEHelpers")

local VerboseLogging = true

local function Log(Message)
    if not VerboseLogging then return end
    print(string.format("[FasterTimeControlMod] %s", Message))
end

Log("Initializing FasterTimeControlMod...")

-- Flag to prevent infinite recursion when we set gameplay speed
local isSettingSpeedManually = false
-- Debounce mechanism to prevent repeated calls
local lastTimeDilationSet = 0
local debounceDelay = 200 -- 200ms debounce

-- Function to modify the 4x speed button text to show "5x"
local function ModifySpeed4ButtonText(TimeControlWidget)
    if not TimeControlWidget or not TimeControlWidget:IsValid() then
        Log("Invalid TimeControlButtons widget")
        return
    end
    
    local btn_speed4 = TimeControlWidget.btn_speed4
    if not btn_speed4 or not btn_speed4:IsValid() then
        Log("Could not find btn_speed4")
        return
    end
    
    Log("Modifying btn_speed4 text to show 5x")
    
    -- Try to find and modify the text element
    pcall(function()
        if btn_speed4.CenterText and btn_speed4.CenterText:IsValid() then
            btn_speed4.CenterText:SetText("5")
            Log("Successfully changed CenterText to 5")
        end
        
        if btn_speed4.centerTextString then
            btn_speed4.centerTextString = "5"
            Log("Successfully changed centerTextString to 5")
        end
    end)
end

local World = UEHelpers.GetWorld()
if World and World:IsValid() then
    local LevelName = World:GetFName():ToString()
    Log("Current level: " .. LevelName)
    
    if LevelName == "ArcoPlay" then
        Log("ArcoPlay level detected, setting up mod")
        
        -- Hook the TimeControlButtons construction to modify the 4x button text
        RegisterHook("/Game/UI/TimeControlButtons.TimeControlButtons_C:Construct", function(self)
            Log("TimeControlButtons widget constructed, modifying btn_speed4 text")
            ExecuteInGameThread(function()
                ModifySpeed4ButtonText(self)
            end)
        end)
        
        -- Hook UpdateTime to intercept and modify the time state before it reaches SetData
        RegisterHook("/Game/UI/BP_PlayHud.BP_PlayHud_C:UpdateTime", function(self, timeState)
            Log("BP_PlayHud UpdateTime called " .. tostring(timeState))
            
            -- Try to access the gameplaySpeed field from the struct
            local gameplaySpeed = nil
            local isPaused = nil
            
            pcall(function()
                gameplaySpeed = timeState.gameplaySpeed:get()
                isPaused = timeState.IsPaused:get()
            end)
            
            Log("Extracted gameplaySpeed: " .. tostring(gameplaySpeed) .. ", isPaused: " .. tostring(isPaused))
            
            -- Check if we need to modify the gameplaySpeed from 4 to 5
            if gameplaySpeed == 4 and not isPaused then
                Log("Intercepted UpdateTime with speed 4, modifying to speed 5")
                -- Try to modify the timeState parameter directly
                pcall(function()
                    timeState.gameplaySpeed = 5
                    Log("Modified timeState.gameplaySpeed to 5")
                end)
            end
        end)
        
        Log("Mod setup complete!")
    else
        Log("Not in ArcoPlay level, mod will not activate")
    end
else
    Log("World not available, mod will not activate")
end

Log("FasterTimeControlMod initialization complete!")

