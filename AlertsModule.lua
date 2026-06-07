---@type string, table
local addonName, addon = ...

-- Alerts module for detecting and announcing important PvP abilities
local AlertsModule = {}
addon.AlertsModule = AlertsModule

---@type table<number, boolean>
local previousImportantAuras = {}
---@type table<number, boolean>
local previousDefensiveAuras = {}

---@type Watcher[]
local watchers = {}
local trackingFrame

-- Cached TTS settings
local cachedVoiceID
local cachedTTSVolume = 100
local cachedTTSRate = 1

-- Check if a spell is enabled in the menu
local function IsSpellEnabled(spellID)
    if not spellID then
        return true -- No spell ID, default to enabled
    end

    -- Check if spellID is a secret value (Midnight 12.0+)
    local isSecret = false
    if issecretvalue then
        local okSecret, secretValue = pcall(issecretvalue, spellID)
        isSecret = okSecret and secretValue
    end
    if isSecret then
        return true -- Can't check secret values, default to enabled
    end

    local okNumber, cleanSpellID = pcall(tonumber, spellID)
    if not okNumber or not cleanSpellID then
        return true
    end

    if not addon.PvPC or not addon.PvPC.db or not addon.PvPC.db.global then
        return true -- Default to enabled if DB not ready
    end

    local override = addon.PvPC.db.global.spellOverrides[cleanSpellID]
    if override == nil then
        return true -- Default enabled if not set
    end
    return override
end

-- Announce spell name using Text-to-Speech
local function AnnounceTTS(spellName, spellID)
    if not spellName then
        return
    end

    -- Check if this specific spell is enabled in the menu
    if spellID and not IsSpellEnabled(spellID) then
        return
    end

    -- Check if TTS is enabled
    if not addon.PvPC or not addon.PvPC.db.global.useTTS then
        return
    end

    -- Use C_VoiceChat.SpeakText to announce the spell name
    pcall(function()
        C_VoiceChat.SpeakText(cachedVoiceID, spellName, cachedTTSRate, cachedTTSVolume, true)
    end)
end

-- Main callback when aura data changes
local function OnAuraDataChanged()
    if not addon.PvPC or not addon.PvPC:ShouldCallout() then
        return
    end
    
    local db = addon.PvPC.db.global
    local currentImportantAuras = {}
    local currentDefensiveAuras = {}
    
    for _, watcher in ipairs(watchers) do
        local unit = watcher:GetUnit()
        
        -- Check if unit exists
        if unit and UnitExists(unit) then
            -- Determine if enemy or ally
            local isEnemy = UnitIsEnemy("player", unit)
            
            -- Check settings
            if (isEnemy and db.enableEnemyCallouts) or (not isEnemy and db.enableAllyCallouts) then
                -- Get important auras (offensive cooldowns)
                if db.calloutOffensive then
                    local importantData = watcher:GetImportantState()
                    for _, data in ipairs(importantData) do
                        if data.AuraInstanceID then
                            -- Check if this is a NEW aura
                            if not previousImportantAuras[data.AuraInstanceID] then
                                AnnounceTTS(data.SpellName, data.SpellId)
                            end
                            currentImportantAuras[data.AuraInstanceID] = true
                        end
                    end
                end

                -- Get defensive auras
                if db.calloutDefensive or db.calloutExternal then
                    local defensivesData = watcher:GetDefensiveState()
                    for _, data in ipairs(defensivesData) do
                        if data.AuraInstanceID then
                            -- Check if this is a NEW aura
                            if not previousDefensiveAuras[data.AuraInstanceID] then
                                AnnounceTTS(data.SpellName, data.SpellId)
                            end
                            currentDefensiveAuras[data.AuraInstanceID] = true
                        end
                    end
                end
            end
        end
    end
    
    -- Update previous aura tracking
    previousImportantAuras = currentImportantAuras
    previousDefensiveAuras = currentDefensiveAuras
end

-- Initialize the module
function AlertsModule:Initialize()
    print("[PvPCallouts] AlertsModule initializing...")

    -- Initialize TTS voice (use default voice)
    cachedVoiceID = C_TTSSettings.GetVoiceOptionID(0)
    cachedTTSVolume = addon.PvPC.db.global.ttsVolume or 100
    cachedTTSRate = addon.PvPC.db.global.ttsRate or 1

    -- Create watchers for arena opponents (enemies)
    for i = 1, 3 do
        local unit = "arena" .. i
        local watcher = addon.UnitAuraWatcher:New(unit, nil, {Important = true, Defensive = true}, true)
        watcher:RegisterCallback(OnAuraDataChanged)
        table.insert(watchers, watcher)
    end
    
    -- Create watchers for player and party (allies)
    local playerWatcher = addon.UnitAuraWatcher:New("player", nil, {Important = true, Defensive = true}, true)
    playerWatcher:RegisterCallback(OnAuraDataChanged)
    table.insert(watchers, playerWatcher)
    
    for i = 1, 4 do
        local unit = "party" .. i
        local watcher = addon.UnitAuraWatcher:New(unit, nil, {Important = true, Defensive = true}, true)
        watcher:RegisterCallback(OnAuraDataChanged)
        table.insert(watchers, watcher)
    end

    trackingFrame = CreateFrame("Frame")
    trackingFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    trackingFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    trackingFrame:SetScript("OnEvent", function()
        AlertsModule:RefreshTrackingState()
    end)

    self:RefreshTrackingState()
    
    print("[PvPCallouts] AlertsModule initialized with " .. #watchers .. " watchers")
end

function AlertsModule:RefreshTrackingState()
    if not addon.PvPC or not addon.PvPC.db then
        return
    end

    local shouldTrack = addon.PvPC:ShouldCallout()
    if shouldTrack then
        for _, watcher in ipairs(watchers) do
            if not watcher:IsEnabled() then
                watcher:Enable()
                watcher:ForceFullUpdate()
            end
        end
    else
        previousImportantAuras = {}
        previousDefensiveAuras = {}
        for _, watcher in ipairs(watchers) do
            watcher:Disable()
            watcher:ClearState(false)
        end
    end
end

-- Enable the module
function AlertsModule:Enable()
    print("[PvPCallouts] AlertsModule enabled")
    self:RefreshTrackingState()
end

-- Disable the module
function AlertsModule:Disable()
    print("[PvPCallouts] AlertsModule disabled")
    for _, watcher in ipairs(watchers) do
        watcher:Disable()
    end
end

-- Clear state (e.g., when entering arena)
function AlertsModule:ClearState()
    previousImportantAuras = {}
    previousDefensiveAuras = {}
    for _, watcher in ipairs(watchers) do
        watcher:ClearState(true)
    end
end

-- Update TTS settings (called when settings change)
function AlertsModule:UpdateTTSSettings()
    cachedTTSVolume = addon.PvPC.db.global.ttsVolume or 100
    cachedTTSRate = addon.PvPC.db.global.ttsRate or 1
end
