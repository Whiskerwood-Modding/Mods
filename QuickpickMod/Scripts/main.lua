local UEHelpers = require("UEHelpers")

---@type table<string, any>
local gridActorDefsCache = nil

---@param actor AActor
---@return string|nil
local function getActorClassName(actor)
    if not actor or not actor:IsValid() then
        return nil
    end
    
    local actorClass = actor:GetClass()
    if not actorClass or not actorClass:IsValid() then
        return nil
    end
    
    return actorClass:GetFullName()
end

---@param actorClassName string
---@return string|nil
local function findRowKeyByActorClass(actorClassName)
    if not gridActorDefsCache then
        print("[QuickPickMod] GridActor definitions cache not loaded")
        return nil
    end
    
    print(string.format("[QuickPickMod] Searching for actor class: %s", actorClassName))
    
    for rowKey, rowData in pairs(gridActorDefsCache) do
        if rowData and rowData.GridActor then
            local gridActorClass = rowData.GridActor
            if gridActorClass and gridActorClass:IsValid() then
                local gridActorClassName = gridActorClass:GetFullName()
                print(string.format("[QuickPickMod] Checking row '%s' with GridActor class: %s", rowKey, gridActorClassName))

                local actorClassPattern = "([%w_]+)_C"
                local actorMatch = string.match(actorClassName, actorClassPattern)
                local gridActorMatch = string.match(gridActorClassName, actorClassPattern)
                
                if actorMatch and gridActorMatch then
                    print(string.format("[QuickPickMod] Comparing actor class '%s' with grid actor '%s'", actorMatch, gridActorMatch))
                    if actorMatch == gridActorMatch then
                        print(string.format("[QuickPickMod] Found matching row: %s", rowKey))
                        return rowKey
                    end
                end
            else
                print(string.format("[QuickPickMod] Row '%s' has invalid GridActor class", rowKey))
            end
        end
    end
    
    print("[QuickPickMod] No matching row found for actor class")
    return nil
end

---@return boolean
local function loadGridActorDefs()
    local gridActorDefsTable = StaticFindObject("/Game/Data/GridactorDefs_Sync.GridactorDefs_Sync")
    
    if gridActorDefsTable and gridActorDefsTable:IsValid() then
        print("[QuickPickMod] Found GridactorDefs_Sync DataTable, loading rows...")
        
        gridActorDefsCache = {}
        
        gridActorDefsTable:ForEachRow(function(rowName, rowData)
            if rowData then
                gridActorDefsCache[rowName] = rowData
                print(string.format("[QuickPickMod] Loaded row: %s", rowName))
            end
        end)
        
        print("[QuickPickMod] Successfully loaded GridActor definitions!")
        return true
    else
        return false
    end
end

local function onFKeyPressed()
    print("[QuickPickMod] F key pressed - starting quickpick process")
    
    -- Step 1: Find BP_SelectTool_C
    local selectTool = FindFirstOf("BP_SelectTool_C")
    if not selectTool or not selectTool:IsValid() then
        print("[QuickPickMod] BP_SelectTool_C not found or invalid")
        return
    end
    
    print("[QuickPickMod] Found BP_SelectTool_C")
    
    -- Step 2: Get the currently highlighted actor
    local highlightedActor = selectTool.m_currentlyHighlightedActor
    if not highlightedActor or not highlightedActor:IsValid() then
        print("[QuickPickMod] No currently highlighted actor found")
        return
    end
    
    print("[QuickPickMod] Found highlighted actor")
    
    -- Step 3: Get actor class name
    local actorClassName = getActorClassName(highlightedActor)
    if not actorClassName then
        print("[QuickPickMod] Could not get actor class name")
        return
    end
    
    print(string.format("[QuickPickMod] Actor class name: %s", actorClassName))
    
    -- Step 4: Find matching row key in GridActor definitions
    local paramString = findRowKeyByActorClass(actorClassName)
    if not paramString then
        print("[QuickPickMod] Could not find matching row in GridActor definitions")
        return
    end
    
    print(string.format("[QuickPickMod] Found matching paramString: %s", paramString))
    
    -- Step 5: Find player controller
    local playerController = FindFirstOf("BP_PlayerController_Play_C")
    if not playerController or not playerController:IsValid() then
        print("[QuickPickMod] BP_PlayerController_Play_C not found or invalid")
        return
    end
    
    print("[QuickPickMod] Found BP_PlayerController_Play_C")
    
    -- Step 6: Get the world to spawn actors in
    local world = UEHelpers.GetWorld()
    if not world or not world:IsValid() then
        print("[QuickPickMod] Could not get valid world")
        return
    end
    
    print("[QuickPickMod] Got world reference")
    
    -- -- Step 7: Find or spawn BP_PropTool_C
    -- local propTool = FindFirstOf("BP_PropTool_C")
    -- if not propTool or not propTool:IsValid() then
    --     print("[QuickPickMod] No existing PropTool found, attempting to spawn one...")
        
    --     -- Get the PropTool class
    --     local propToolClass = StaticFindObject("/Game/Code/PlayerTools/BP_PropTool.BP_PropTool_C")
    --     if not propToolClass or not propToolClass:IsValid() then
    --         print("[QuickPickMod] Could not find BP_PropTool_C class")
    --         return
    --     end
        
    --     print("[QuickPickMod] Found BP_PropTool_C class, spawning...")
        
    --     -- Spawn the PropTool actor
    --     local spawnParams = {}
    --     propTool = world:SpawnActor(propToolClass, {X = 0, Y = 0, Z = 0}, {Pitch = 0, Yaw = 0, Roll = 0}, spawnParams)
        
    --     if not propTool or not propTool:IsValid() then
    --         print("[QuickPickMod] Failed to spawn PropTool actor")
    --         return
    --     end
        
    --     print("[QuickPickMod] Successfully spawned PropTool actor")
    -- else
    --     print("[QuickPickMod] Found existing PropTool actor")
    -- end
    
    -- Step 8: Wait a frame then select the building
    LoopAsync(100, function()
        print("[QuickPickMod] Attempting to select building...")
        
        local hudAction = {
            action = "SelectBuilding",
            paramString = paramString,
            paramName = "",
            paramInt = 0,
            paramFloat = 0.0,
            paramGrid = {X = 0, Y = 0, Z = 0},
            paramBool = false,
            paramVector = {X = 0.0, Y = 0.0, Z = 0.0}
        }
        
        print(string.format("[QuickPickMod] Calling HandleHudAction with paramString: %s", paramString))
        -- playerController:HandleHudAction(hudAction)
        print("[QuickPickMod] Successfully executed quickpick!")
        
        return true -- Stop the loop after one execution
    end)
end

local function startMod()
    print("[QuickPickMod] Starting mod - loading GridActor definitions...")
    
    if loadGridActorDefs() then
        print("[QuickPickMod] GridActor definitions loaded, setting up F key binding...")
    else
        print("[QuickPickMod] GridActor definitions not found yet, will retry every 1 second...")
        
        local searchTimer
        searchTimer = LoopAsync(1000, function()
            if loadGridActorDefs() then
                searchTimer:Stop()
                print("[QuickPickMod] Timer stopped - GridActor definitions loaded!")
            else
                print("[QuickPickMod] Still searching for GridActor definitions...")
            end
        end)
    end
    
    -- Register F key binding
    RegisterKeyBind(Key.F, function()
        onFKeyPressed()
    end)
    
    print("[QuickPickMod] F key binding registered - press F to quickpick highlighted building!")
end

startMod()