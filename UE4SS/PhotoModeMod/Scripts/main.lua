local UEHelpers = require("UEHelpers")

-- Register P key to toggle BP_PlayHud and CondensedWhiskerSummary visibility
RegisterKeyBind(Key.P, function()
    print("[OrbitalCameraTweaks] P key pressed - toggling HUD visibility...")
    
    local playHud = FindFirstOf("BP_PlayHud_C")
    local whiskerSummary = FindFirstOf("CondensedWhiskerSummary_C")
    local shouldHide = false
    
    -- Check current state based on PlayHud visibility
    if playHud and playHud:IsValid() then
        local currentVisibility = playHud:GetVisibility()
        shouldHide = (currentVisibility == 0) -- If currently visible, we should hide
        print(string.format("[OrbitalCameraTweaks] Current HUD visibility: %s", tostring(currentVisibility)))
    end
    
    -- Toggle BP_PlayHud visibility
    if playHud and playHud:IsValid() then
        print("[OrbitalCameraTweaks] Found BP_PlayHud!")
        
        if playHud.SetVisibility then
            if shouldHide then
                playHud:SetVisibility(2) -- ESlateVisibility::Hidden = 2
                print("[OrbitalCameraTweaks] BP_PlayHud hidden")
            else
                -- When making visible, force it to back and then bring to front to fix z-order
                playHud:SetVisibility(0) -- ESlateVisibility::Visible = 0
                if playHud.RemoveFromParent and playHud.AddToViewport then
                    ExecuteWithDelay(50, function() -- Small delay to ensure proper ordering
                        if playHud and playHud:IsValid() then
                            playHud:RemoveFromParent()
                            playHud:AddToViewport(0) -- Z-order 0 (front)
                            print("[OrbitalCameraTweaks] BP_PlayHud re-added to viewport with proper z-order")
                        end
                    end)
                end
                print("[OrbitalCameraTweaks] BP_PlayHud visible")
            end
        elseif playHud.SetActorHiddenInGame then
            -- Fallback for actor-based visibility
            playHud:SetActorHiddenInGame(shouldHide)
            print(string.format("[OrbitalCameraTweaks] BP_PlayHud visibility toggled (hidden: %s)", tostring(shouldHide)))
        else
            print("[OrbitalCameraTweaks] No visibility method found on BP_PlayHud")
        end
    else
        print("[OrbitalCameraTweaks] BP_PlayHud not found")
    end
    
    -- Toggle CondensedWhiskerSummary visibility
    if whiskerSummary and whiskerSummary:IsValid() then
        print("[OrbitalCameraTweaks] Found CondensedWhiskerSummary!")
        
        if whiskerSummary.SetVisibility then
            if shouldHide then
                whiskerSummary:SetVisibility(2) -- ESlateVisibility::Hidden = 2
                print("[OrbitalCameraTweaks] CondensedWhiskerSummary hidden")
            else
                -- When making visible, fix z-order similar to PlayHud
                whiskerSummary:SetVisibility(0) -- ESlateVisibility::Visible = 0
                if whiskerSummary.RemoveFromParent and whiskerSummary.AddToViewport then
                    ExecuteWithDelay(100, function() -- Slightly later delay to ensure it's after PlayHud
                        if whiskerSummary and whiskerSummary:IsValid() then
                            whiskerSummary:RemoveFromParent()
                            whiskerSummary:AddToViewport(1) -- Z-order 1 (behind PlayHud)
                            print("[OrbitalCameraTweaks] CondensedWhiskerSummary re-added to viewport with proper z-order")
                        end
                    end)
                end
                print("[OrbitalCameraTweaks] CondensedWhiskerSummary visible")
            end
        elseif whiskerSummary.SetActorHiddenInGame then
            -- Fallback for actor-based visibility
            whiskerSummary:SetActorHiddenInGame(shouldHide)
            print(string.format("[OrbitalCameraTweaks] CondensedWhiskerSummary visibility toggled (hidden: %s)", tostring(shouldHide)))
        else
            print("[OrbitalCameraTweaks] No visibility method found on CondensedWhiskerSummary")
        end
    else
        print("[OrbitalCameraTweaks] CondensedWhiskerSummary not found")
    end
end)