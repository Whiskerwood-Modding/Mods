local UEHelpers = require("UEHelpers")

---@type APawn_Play
local playPawn = nil

local function findPlayPawn()
    local pawn = FindFirstOf("BP_Pawn_Play_C")
    if pawn and pawn:IsValid() then
        print("[OrbitalCameraTweaks] Found BP_Pawn_Play_C!")
        return pawn
    else
        print("[OrbitalCameraTweaks] BP_Pawn_Play_C not found")
        return nil
    end
end

local function applyMoreFlexibleCameraSettings(pawn)
    if not pawn or not pawn:IsValid() then
        print("[OrbitalCameraTweaks] Invalid pawn provided")
        return false
    end
    
    -- Check if m_config exists
    if not pawn.m_config then
        print("[OrbitalCameraTweaks] m_config not found on pawn")
        return false
    end
    
    local config = pawn.m_config
    
    -- Store original values for logging and speed boost system
    local originalLowestTilt = config.lowestTilt
    local originalHighestTilt = config.highestTilt
    local originalMinCamDist = config.minCamDist
    local originalMaxCamDist = config.maxCamDist
    local originalPanSpeed = config.panSpeed
    local originalZoomSpeed = config.zoomSpeed
    local originalRotLerpSpeed = config.rotLerpSpeed
    
    -- Store the original pan speed for the speed boost system
    basePanSpeed = originalPanSpeed
    
    print(string.format("[OrbitalCameraTweaks] Original camera settings:"))
    print(string.format("  lowestTilt: %.2f", originalLowestTilt))
    print(string.format("  highestTilt: %.2f", originalHighestTilt))
    print(string.format("  minCamDist: %.2f", originalMinCamDist))
    print(string.format("  maxCamDist: %.2f", originalMaxCamDist))
    -- print(string.format("  panSpeed: %.2f", originalPanSpeed))
    -- print(string.format("  zoomSpeed: %.2f", originalZoomSpeed))
    -- print(string.format("  rotLerpSpeed: %.2f", originalRotLerpSpeed))
    
    -- Apply more flexible camera settings
    config.lowestTilt = 85.0          -- Allow looking straight down (default was -30.00)
    config.highestTilt = -85.0       -- Allow looking more upward (default was -80.00)
    config.minCamDist = 50.0         -- Allow getting much closer (default was 500.00)
    config.maxCamDist = 50000.0      -- Allow zooming out further (default was 34000.00)
    -- config.panSpeed = 750.0          -- Increase pan speed (default was 550.00)
    -- config.zoomSpeed = 0.15          -- Increase zoom speed (default was 0.10)
    -- config.rotLerpSpeed = 10.0       -- Make rotation more responsive (default was 7.00)
    -- config.orbitMult = 1.2           -- Increase orbit sensitivity 
    -- config.tiltMult = 1.2            -- Increase tilt sensitivity 
    -- config.maxZoomVelocity = 1000.0  -- Set max zoom velocity 
    -- config.boundsLimitDist = 5000.0  -- Set camera movement bounds 
    
    print(string.format("[OrbitalCameraTweaks] Applied new camera settings:"))
    print(string.format("  lowestTilt: %.2f (was %.2f)", config.lowestTilt, originalLowestTilt))
    print(string.format("  highestTilt: %.2f (was %.2f)", config.highestTilt, originalHighestTilt))
    print(string.format("  minCamDist: %.2f (was %.2f)", config.minCamDist, originalMinCamDist))
    print(string.format("  maxCamDist: %.2f (was %.2f)", config.maxCamDist, originalMaxCamDist))
    -- print(string.format("  panSpeed: %.2f (was %.2f)", config.panSpeed, originalPanSpeed))
    -- print(string.format("  zoomSpeed: %.2f (was %.2f)", config.zoomSpeed, originalZoomSpeed))
    -- print(string.format("  rotLerpSpeed: %.2f (was %.2f)", config.rotLerpSpeed, originalRotLerpSpeed))
    
    return true
end

-- Speed boost system for when Shift is held
local basePanSpeed = 550.0  -- Store the base pan speed
local speedBoostMultiplier = 3.0  -- 3x speed when holding Shift
local isShiftSpeedActive = false

local function updateCameraSpeed()
    if not playPawn or not playPawn:IsValid() or not playPawn.m_config then
        return
    end
    
    local config = playPawn.m_config
    local targetSpeed = basePanSpeed
    
    -- Get the player controller to check input state
    local playerController = UEHelpers.GetPlayerController()
    if not playerController or not playerController:IsValid() then
        return
    end
    
    -- Create FKey objects for shift keys
    local leftShiftKey = {}
    leftShiftKey.KeyName = FName("LeftShift")
    local rightShiftKey = {}
    rightShiftKey.KeyName = FName("RightShift")
    
    -- Check if Shift is currently pressed using the proper UE4SS API with FKey
    local isShiftPressed = playerController:IsInputKeyDown(leftShiftKey) or playerController:IsInputKeyDown(rightShiftKey)
    
    if isShiftPressed then
        targetSpeed = basePanSpeed * speedBoostMultiplier
        if not isShiftSpeedActive then
            isShiftSpeedActive = true
            print(string.format("[OrbitalCameraTweaks] Speed boost activated! Pan speed: %.1fx", speedBoostMultiplier))
        end
    else
        if isShiftSpeedActive then
            isShiftSpeedActive = false
            print("[OrbitalCameraTweaks] Speed boost deactivated")
        end
    end
    
    -- Only update if speed actually changed to avoid spam
    if math.abs(config.panSpeed - targetSpeed) > 0.1 then
        config.panSpeed = targetSpeed
    end
end

local function startSpeedBoostMonitoring()
    -- Start a timer to continuously monitor Shift key state
    LoopAsync(50, function() -- Check every 50ms for responsive feel
        updateCameraSpeed()
    end)
    print("[OrbitalCameraTweaks] Speed boost monitoring started (Hold Shift for 2x camera speed)")
end

local function startMod()
    print("[OrbitalCameraTweaks] Starting Orbital Camera Tweaks Mod...")
    
    -- Try to find the pawn immediately
    playPawn = findPlayPawn()
    
    if playPawn then
        if applyMoreFlexibleCameraSettings(playPawn) then
            print("[OrbitalCameraTweaks] Successfully applied camera tweaks!")
            startSpeedBoostMonitoring()
        else
            print("[OrbitalCameraTweaks] Failed to apply camera tweaks")
        end
    else
        print("[OrbitalCameraTweaks] Play pawn not found immediately, setting up timer to check periodically...")
        
        -- Set up a timer to keep checking for the pawn
        local searchTimer
        searchTimer = LoopAsync(1000, function()
            playPawn = findPlayPawn()
            if playPawn then
                if applyMoreFlexibleCameraSettings(playPawn) then
                    print("[OrbitalCameraTweaks] Successfully applied camera tweaks!")
                    startSpeedBoostMonitoring()
                    searchTimer:Stop()
                    print("[OrbitalCameraTweaks] Timer stopped - camera tweaks applied!")
                else
                    print("[OrbitalCameraTweaks] Failed to apply camera tweaks, will keep trying...")
                end
            else
                print("[OrbitalCameraTweaks] Still searching for BP_Pawn_Play_C...")
            end
        end)
    end
end

-- Register a key binding to reapply tweaks if needed (useful for testing)
RegisterKeyBind(Key.F9, function()
    print("[OrbitalCameraTweaks] F9 pressed - reapplying camera tweaks...")
    playPawn = findPlayPawn()
    if playPawn then
        applyMoreFlexibleCameraSettings(playPawn)
    else
        print("[OrbitalCameraTweaks] Play pawn not found")
    end
end)

startMod()