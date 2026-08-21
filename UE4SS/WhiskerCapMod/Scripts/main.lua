--[[
    WhiskerCap — automatic whisker (mouse) population cap for Whiskerwood.
    UE4SS Lua mod. See README.md for install and usage.

    The cap is set in-game: Settings -> Mod tab -> "WhiskerCap: max whisker
    population". "Off" disables culling so the population can grow again.
    CONFIG.CAP below is a hard-coded fallback (0 = disabled).
    A cap of 0 / "Off" can never mean "kill everyone".
]]

local UEHelpers = require("UEHelpers")

local CONFIG = {
    -- Hard-coded fallback cap, used only when the dropdown is "Off". 0 = disabled.
    CAP = 0,

    -- How often to check the population, in milliseconds.
    CHECK_INTERVAL_MS = 5000,

    -- Max whiskers removed per check; keeps the decline gentle.
    MAX_KILLS_PER_CHECK = 2,

    -- How culled whiskers die (EAgentDeleteReason): 1 = illness, 2 = wound, 3 = starvation.
    DELETE_REASON = 1,

    -- "flag"  = set the game's own pendingRemoval/removalReason fields (verified working)
    -- "cheat" = select the whisker and call the Arco_KillSelectedWhisker dev cheat (fallback)
    KILL_METHOD = "flag",

    -- Values offered by the Settings -> Mod tab dropdown.
    MOD_OPTION_VALUES = { "Off", "20", "40", "60", "80", "100", "120", "140",
                          "160", "180", "200", "250", "300", "350", "400", "450", "500" },

    -- F6 = spawn 5 test whiskers at the dock, F7 = run a population check now.
    DEBUG_KEYS = true,
}

local MOD_OPTION_ID = "WhiskerCapMax"

local function Log(msg)
    print(string.format("[WhiskerCap] %s\n", msg))
end

-- pcall wrapper that returns nil on failure instead of raising
local function Try(fn, ...)
    local ok, result = pcall(fn, ...)
    if ok then return result end
    return nil
end

local function IsUsable(obj)
    return obj ~= nil and Try(function() return obj:IsValid() end) == true
end

local function GetArcoSystems()
    local sys = FindFirstOf("ArcoSystems")
    if IsUsable(sys) then return sys end
    return nil
end

local function GetModAPI()
    local backbone = FindFirstOf("Backbone")
    if IsUsable(backbone) then
        local api = Try(function() return backbone.ModAPI end)
        if IsUsable(api) then return api end
    end
    local api = FindFirstOf("ModAPI")
    if IsUsable(api) then return api end
    return nil
end

local function GetContext()
    local pc = Try(UEHelpers.GetPlayerController)
    if IsUsable(pc) then return pc end
    return nil
end

-- ---------------------------------------------------------------------------
-- Population
-- ---------------------------------------------------------------------------

local function IsPendingRemoval(agent)
    return Try(function() return agent.m_state.pendingRemoval end) == true
end

local function IsCullable(agent)
    if not IsUsable(agent) then return false end
    if IsPendingRemoval(agent) then return false end
    if Try(function() return agent.m_state.isDummy end) == true then return false end
    if Try(function() return agent.m_state.isBeingManhandled end) == true then return false end
    return true
end

-- Authoritative list: FWorldMeta.Population.agents on AArcoSystems (colony
-- members only). Falls back to FindAllOf if the TMap read fails.
local function GetColonyMice(sys)
    local mice = {}
    local ok = pcall(function()
        sys.m_worldMeta.Population.agents:ForEach(function(_, value)
            local agent = value:get()
            if IsCullable(agent) then
                table.insert(mice, agent)
            end
        end)
    end)
    if not ok then
        mice = {}
        for _, agent in ipairs(FindAllOf("Prototype_Agent") or {}) do
            if IsCullable(agent) then
                table.insert(mice, agent)
            end
        end
    end
    return mice, ok
end

local function HasWorkplace(agent)
    local wp = Try(function() return agent:GetWorkplace() end)
    return IsUsable(wp)
end

-- Unemployed whiskers go first; workers only if the surplus demands it.
local function PickVictims(mice, count)
    local victims = {}
    for _, agent in ipairs(mice) do
        if #victims >= count then return victims end
        if not HasWorkplace(agent) then table.insert(victims, agent) end
    end
    for _, agent in ipairs(mice) do
        if #victims >= count then return victims end
        if HasWorkplace(agent) then table.insert(victims, agent) end
    end
    return victims
end

local function AgentName(agent)
    local name = Try(function() return agent.m_characteristics.agentName:ToString() end)
    if name == nil or name == "" then
        name = Try(function() return agent:GetName() end) or "?"
    end
    return name
end

local function KillViaFlag(agent)
    agent.m_state.pendingRemoval = true
    agent.m_state.removalReason = CONFIG.DELETE_REASON
end

local function KillViaCheat(agent)
    local tool = FindFirstOf("SelectTool")
    local pc = GetContext()
    if not IsUsable(tool) or not IsUsable(pc) then
        error("SelectTool or PlayerController unavailable for cheat kill")
    end
    tool.m_currentlySelectedAgent = agent
    pc:Arco_KillSelectedWhisker()
end

local function Kill(agent)
    local name = AgentName(agent)
    local ok, err
    if CONFIG.KILL_METHOD == "cheat" then
        ok, err = pcall(KillViaCheat, agent)
    else
        ok, err = pcall(KillViaFlag, agent)
    end
    if ok then
        Log("culled: " .. name)
    else
        Log(string.format("kill failed for %s: %s", name, tostring(err)))
    end
    return ok
end

-- ---------------------------------------------------------------------------
-- Cap source: mod options dropdown (Settings -> Mod tab)
-- ---------------------------------------------------------------------------

local optionRegistered = false
local optionAttempts = 0
local OPTION_MAX_ATTEMPTS = 24

local function TryRegisterModOption()
    if optionRegistered or optionAttempts >= OPTION_MAX_ATTEMPTS then return end
    local api, ctx = GetModAPI(), GetContext()
    if api == nil or ctx == nil then return end   -- retry next cycle

    optionAttempts = optionAttempts + 1
    local ok, result = pcall(function()
        return api:RegisterModOptions(ctx, MOD_OPTION_ID, "WhiskerCap: max whisker population",
            CONFIG.MOD_OPTION_VALUES, "Off",
            "Surplus whiskers pass away (unemployed first) until the colony is at this size. Off = no culling, population grows normally.")
    end)
    if ok and result == true then
        optionRegistered = true
        Log("mod option registered (Settings -> Mod tab)")
    elseif not ok and (optionAttempts == 1 or optionAttempts == OPTION_MAX_ATTEMPTS) then
        Log(string.format("RegisterModOptions failed (attempt %d/%d): %s",
            optionAttempts, OPTION_MAX_ATTEMPTS, tostring(result)))
    end
end

-- Read regardless of registration state: if the option isn't registered the
-- API returns the fallback ("Off"), which resolves to "unset".
local function ReadOptionCap()
    return Try(function()
        local api, ctx = GetModAPI(), GetContext()
        if api == nil or ctx == nil then return nil end
        local value = api:ReadModOptionValue(ctx, MOD_OPTION_ID, "Off"):ToString()
        return tonumber(value)
    end)
end

-- ---------------------------------------------------------------------------
-- Cap resolution + cull loop
-- ---------------------------------------------------------------------------

local lastCapDesc = nil

local function ResolveCap()
    local cap = ReadOptionCap()
    local desc = "mod option"
    if cap == nil or cap <= 0 then
        cap = CONFIG.CAP
        desc = "CONFIG.CAP"
    end
    if cap == nil or cap <= 0 then
        return 0, "unset"
    end
    return math.floor(cap), desc
end

-- Checks queued while the game is paused (menus etc.) all drain on the same
-- frame when it unpauses; without a debounce that burst bypasses the kill
-- rate limit. Forced checks (F7) skip the debounce.
local lastCheckAt = 0

local function RunCheck(force)
    -- Also runs at the main menu so the option is registered before a colony loads.
    TryRegisterModOption()

    local sys = GetArcoSystems()
    if sys == nil then return end   -- main menu / no colony loaded

    local now = os.time()
    if not force and now - lastCheckAt < math.max(1, math.floor(CONFIG.CHECK_INTERVAL_MS / 1000) - 1) then
        return
    end
    lastCheckAt = now

    local cap, capDesc = ResolveCap()
    local capLabel = cap > 0 and string.format("%d (%s)", cap, capDesc) or "unset"
    if capLabel ~= lastCapDesc then
        Log("active cap: " .. capLabel)
        lastCapDesc = capLabel
    end
    if cap <= 0 then return end

    local mice, viaPopulation = GetColonyMice(sys)
    local surplus = #mice - cap
    if surplus <= 0 then return end

    local toKill = math.min(surplus, CONFIG.MAX_KILLS_PER_CHECK)
    Log(string.format("population %d over cap %d (source: %s, count via %s); culling %d",
        #mice, cap, capDesc, viaPopulation and "Population.agents" or "FindAllOf", toKill))
    for _, victim in ipairs(PickVictims(mice, toKill)) do
        Kill(victim)
    end
end

LoopAsync(CONFIG.CHECK_INTERVAL_MS, function()
    ExecuteInGameThread(function()
        local ok, err = pcall(RunCheck)
        if not ok then Log("check error: " .. tostring(err)) end
    end)
    return false
end)

-- ---------------------------------------------------------------------------
-- Debug keys
-- ---------------------------------------------------------------------------

if CONFIG.DEBUG_KEYS then
    RegisterKeyBind(Key.F6, function()
        ExecuteInGameThread(function()
            local ok, err = pcall(function()
                GetContext():Arco_SpawnAgentsAtDock(5, 0)
                Log("F6: spawned 5 whiskers at dock")
            end)
            if not ok then Log("F6 failed: " .. tostring(err)) end
        end)
    end)
    RegisterKeyBind(Key.F7, function()
        ExecuteInGameThread(function()
            local ok, err = pcall(RunCheck, true)
            if not ok then Log("F7 check error: " .. tostring(err)) end
        end)
    end)
end

Log(string.format("loaded; CONFIG.CAP=%d, interval=%dms, max kills/check=%d, kill method=%s",
    CONFIG.CAP, CONFIG.CHECK_INTERVAL_MS, CONFIG.MAX_KILLS_PER_CHECK, CONFIG.KILL_METHOD))
