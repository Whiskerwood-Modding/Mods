math.randomseed(os.time())

local function calculateNewCost(rowName, originalCost, researchTier)
    -- Research tier costs - make them progressively more expensive the higher the tier
    if string.match(rowName, "unlock%.researchTier%d+") then
        local tier = tonumber(string.match(rowName, "unlock%.researchTier(%d+)"))
        if tier then
            -- Each tier is 20% less expensive than the previous
            -- Tier 1: 80% of original, Tier 2: 60% of original, Tier 3: 40% of original, etc.
            local multiplier = 1.0 - (tier * 0.2) -- Tier 1 = 0.8, Tier 2 = 0.6, Tier 3 = 0.4, etc.
            local newCost = math.floor(originalCost * multiplier)
            return math.max(newCost, 1) -- Never go below 1
        end
    end
    
    return originalCost
end

local function checkIfModAlreadyRan(techUnlocksTable)
    local chimesUnlock = nil
    
    techUnlocksTable:ForEachRow(function(rowName, rowData)
        if rowName == "unlock.chimes" then
            chimesUnlock = rowData
            return
        end
    end)
    
    if chimesUnlock and chimesUnlock.unlockedByDefault then
        print("[DynamicResearchMod] Mod already applied (chimes is unlocked by default) - skipping to prevent double application")
        return true
    end
    
    return false
end

local function findAndModifyTechUnlocks()
    local techUnlocksTable = StaticFindObject("/Game/Data/AssetLookups/TechUnlocksV2.TechUnlocksV2")
    
    if techUnlocksTable and techUnlocksTable:IsValid() then
        print("[DynamicResearchMod] Found TechUnlocksV2 DataTable...")
        
        -- Check if mod has already been applied
        if checkIfModAlreadyRan(techUnlocksTable) then
            return true
        end
        
        print("[DynamicResearchMod] Applying research cost rebalancing...")
        
        techUnlocksTable:ForEachRow(function(rowName, rowData)
            if rowName == "unlock.chimes" then
                rowData.unlockedByDefault = true
                print("[DynamicResearchMod] Set chimes as unlocked by default (mod marker)")
            end
        end)
        
        techUnlocksTable:ForEachRow(function(rowName, rowData)
            if rowData and rowData.researchable then
                local originalCost = rowData.scienceCost
                local newCost = calculateNewCost(rowName, originalCost, rowData.researchTier)
                
                if newCost == 0 then
                    -- If cost would be 0, unlock by default instead
                    rowData.unlockedByDefault = true
                    print(string.format("[DynamicResearchMod] UNLOCKED: %s (was %d science)", rowName, originalCost))
                elseif newCost ~= originalCost then
                    rowData.scienceCost = newCost
                    print(string.format("[DynamicResearchMod] %s: %d → %d science", rowName, originalCost, newCost))
                end
            end
        end)
        
        print(string.format("[DynamicResearchMod] Rebalancing complete! Modified %d costs, unlocked %d items by default!", modifiedCount, unlockedCount))
        return true
    else
        return false
    end
end

local function startMod()
    print("[DynamicResearchMod] Starting mod - looking for TechUnlocksV2 DataTable...")
    
    if findAndModifyTechUnlocks() then
        return 
    end
    
    print("[DynamicResearchMod] TechUnlocksV2 not found yet, will retry every 0.5 seconds...")
    
    local searchTimer
    searchTimer = LoopAsync(500, function()
        if findAndModifyTechUnlocks() then
            searchTimer:Stop()
            print("[DynamicResearchMod] Timer stopped - mod setup complete!")
        else
            print("[DynamicResearchMod] Still searching for TechUnlocksV2...")
        end
    end)
end

startMod()