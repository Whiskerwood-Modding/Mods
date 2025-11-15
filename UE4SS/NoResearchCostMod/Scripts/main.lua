local function findAndModifyTechUnlocks()
    local techUnlocksTable = StaticFindObject("/Game/Data/AssetLookups/TechUnlocksV2.TechUnlocksV2")
    
    if techUnlocksTable and techUnlocksTable:IsValid() then
        print("[NoResearchCostMod] Found TechUnlocksV2 DataTable, modifying rows...")
        
        techUnlocksTable:ForEachRow(function(rowName, rowData)
            if rowData then
                print(string.format("[NoResearchCostMod] Processing row: %s", rowName))
                
                rowData.unlockedByDefault = true
                
                print(string.format("[NoResearchCostMod] Set unlockedByDefault=true for row: %s", rowName))
            end
        end)
        
        print("[NoResearchCostMod] Successfully modified all tech unlocks!")
        return true
    else
        return false
    end
end

local function startMod()
    print("[NoResearchCostMod] Starting mod - looking for TechUnlocksV2 DataTable...")
    
    if findAndModifyTechUnlocks() then
        return 
    end
    
    print("[NoResearchCostMod] TechUnlocksV2 not found yet, will retry every 0.5 seconds...")
    
    local searchTimer
    searchTimer = LoopAsync(500, function()
        if findAndModifyTechUnlocks() then
            searchTimer:Stop()
            print("[NoResearchCostMod] Timer stopped - mod setup complete!")
        else
            print("[NoResearchCostMod] Still searching for TechUnlocksV2...")
        end
    end)
end

startMod()