---@type string, table
local addonName, addon = ...

-- Create the main addon object using Ace3
local PvPC = LibStub("AceAddon-3.0"):NewAddon("PvPCallouts", "AceEvent-3.0", "AceConsole-3.0")
_G.PvPCallouts = PvPC

-- Store addon table for other files
addon.PvPC = PvPC

-- Default settings
local defaults = {
    global = {
        enabled = true,
        enableEnemyCallouts = true,
        enableAllyCallouts = false,
        
        -- Callout types
        calloutOffensive = true,
        calloutDefensive = true,
        calloutExternal = true,
        calloutCC = true,
        
        -- Output settings
        useTextCallouts = true,
        useTTS = true, -- Text-to-Speech callouts
        outputChannel = "SAY", -- SAY, PARTY, RAID, SELF

        -- TTS settings
        ttsVolume = 100, -- Volume for TTS (0-300, 100 = normal)
        ttsRate = 1, -- Speech rate for TTS (0.5-2.0, default 1.0)

        -- Filters
        onlyInArena = true,

        -- Per-spell overrides (spellID = enabled)
        spellOverrides = {},
    }
}

function PvPC:OnInitialize()
    -- Initialize database
    self.db = LibStub("AceDB-3.0"):New("PvPCalloutsDB", defaults, true)

    -- Register slash commands
    self:RegisterChatCommand("pvpcallouts", "SlashCommand")
    self:RegisterChatCommand("pvpc", "SlashCommand")

    -- Initialize the alerts module early to register events
    if addon.AlertsModule then
        addon.AlertsModule:Initialize()
    end
end

function PvPC:OnEnable()
    -- Enable the alerts module
    if addon.AlertsModule then
        addon.AlertsModule:Enable()
    end
end

function PvPC:OnDisable()
    -- Disable the alerts module
    if addon.AlertsModule then
        addon.AlertsModule:Disable()
    end
end

function PvPC:SlashCommand(input)
    input = (input or ""):trim()
    local command, value = input:match("^(%S*)%s*(.-)$")
    command = (command or ""):lower()

    if command == "" or command == "options" or command == "config" then
        if addon.Options then
            addon.Options:Open()
        else
            self:Print("Options are not loaded yet.")
        end
    elseif command == "help" then
        self:Print("Commands: /pvpc, /pvpc options, /pvpc enable, /pvpc disable, /pvpc volume 0-300, /pvpc rate 0.5-3, /pvpc arena on/off, /pvpc test")
    elseif command == "enable" then
        self.db.global.enabled = true
        self:Enable()
        if addon.AlertsModule then
            addon.AlertsModule:RefreshTrackingState()
        end
        self:Print("PvP Callouts enabled")
    elseif command == "disable" then
        self.db.global.enabled = false
        self:Disable()
        self:Print("PvP Callouts disabled")
    elseif command == "volume" or command == "vol" then
        local volume = tonumber(value)
        if volume then
            volume = math.max(0, math.min(300, volume))
            self.db.global.ttsVolume = volume
            if addon.AlertsModule then
                addon.AlertsModule:UpdateTTSSettings()
            end
            self:Print("TTS volume set to " .. volume .. "%")
        else
            self:Print("Usage: /pvpc volume 0-300")
        end
    elseif command == "rate" then
        local rate = tonumber(value)
        if rate then
            rate = math.max(0.5, math.min(3, rate))
            self.db.global.ttsRate = rate
            if addon.AlertsModule then
                addon.AlertsModule:UpdateTTSSettings()
            end
            self:Print("TTS rate set to " .. rate)
        else
            self:Print("Usage: /pvpc rate 0.5-3")
        end
    elseif command == "arena" then
        value = (value or ""):lower()
        if value == "on" or value == "true" or value == "1" then
            self.db.global.onlyInArena = true
            self:Print("Only in Arena enabled")
        elseif value == "off" or value == "false" or value == "0" then
            self.db.global.onlyInArena = false
            self:Print("Only in Arena disabled")
        else
            self:Print("Usage: /pvpc arena on/off")
            return
        end
        if addon.AlertsModule then
            addon.AlertsModule:RefreshTrackingState()
        end
    elseif command == "test" then
        -- Test callout
        if addon.Callouts then
            addon.Callouts:TestCallout()
        end
    else
        self:Print("Unknown command. Try /pvpc help")
    end
end

-- Helper function to check if we're in arena
function PvPC:IsInArena()
    local _, instanceType = IsInInstance()
    return instanceType == "arena"
end

-- Helper function to check if callouts should be active
function PvPC:ShouldCallout()
    if not self.db.global.enabled then
        return false
    end
    
    if self.db.global.onlyInArena and not self:IsInArena() then
        return false
    end
    
    return true
end
