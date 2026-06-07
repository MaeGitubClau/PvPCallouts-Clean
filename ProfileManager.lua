---@type string, table
local addonName, addon = ...

local ProfileManager = {}
addon.ProfileManager = ProfileManager

local AceSerializer = LibStub("AceSerializer-3.0")

-- Export current settings to a string
function ProfileManager:ExportProfile()
    local db = addon.PvPC.db.global
    
    -- Create export data
    local exportData = {
        version = 1,
        enabled = db.enabled,
        enableEnemyCallouts = db.enableEnemyCallouts,
        enableAllyCallouts = db.enableAllyCallouts,
        calloutOffensive = db.calloutOffensive,
        calloutDefensive = db.calloutDefensive,
        calloutExternal = db.calloutExternal,
        calloutCC = db.calloutCC,
        useTextCallouts = db.useTextCallouts,
        useAudioCallouts = db.useAudioCallouts,
        outputChannel = db.outputChannel,
        onlyInArena = db.onlyInArena,
        ttsVoiceID = db.ttsVoiceID,
        ttsRate = db.ttsRate,
        ttsVolume = db.ttsVolume,
        ttsQueueMode = db.ttsQueueMode,
        ttsShortMessages = db.ttsShortMessages,
        ttsIncludeUnit = db.ttsIncludeUnit,
        spellOverrides = db.spellOverrides,
    }
    
    -- Serialize the data
    local serialized = AceSerializer:Serialize(exportData)
    
    -- Encode to base64-like string (using LibCompress if available, otherwise simple encoding)
    local encoded = self:EncodeString(serialized)
    
    return encoded
end

-- Import settings from a string
function ProfileManager:ImportProfile(importString)
    if not importString or importString == "" then
        return false, "Import string is empty"
    end
    
    -- Decode the string
    local decoded = self:DecodeString(importString)
    if not decoded then
        return false, "Failed to decode import string"
    end
    
    -- Deserialize the data
    local success, data = AceSerializer:Deserialize(decoded)
    if not success then
        return false, "Failed to deserialize data"
    end
    
    -- Validate version
    if not data.version or data.version ~= 1 then
        return false, "Incompatible profile version"
    end
    
    -- Apply the settings
    local db = addon.PvPC.db.global

    db.enabled = data.enabled
    db.enableEnemyCallouts = data.enableEnemyCallouts
    db.enableAllyCallouts = data.enableAllyCallouts
    db.calloutOffensive = data.calloutOffensive
    db.calloutDefensive = data.calloutDefensive
    db.calloutExternal = data.calloutExternal
    db.calloutCC = data.calloutCC
    db.useTextCallouts = data.useTextCallouts
    db.useAudioCallouts = data.useAudioCallouts
    db.outputChannel = data.outputChannel
    db.onlyInArena = data.onlyInArena

    -- TTS settings (with defaults for older profiles)
    db.ttsVoiceID = data.ttsVoiceID or 0
    db.ttsRate = data.ttsRate or 0
    db.ttsVolume = math.max(0, math.min(300, data.ttsVolume or 100))
    db.ttsQueueMode = data.ttsQueueMode ~= nil and data.ttsQueueMode or true
    db.ttsShortMessages = data.ttsShortMessages or false
    db.ttsIncludeUnit = data.ttsIncludeUnit ~= nil and data.ttsIncludeUnit or true
    
    -- Import spell overrides
    if data.spellOverrides then
        for spellID, enabled in pairs(data.spellOverrides) do
            db.spellOverrides[spellID] = enabled
        end
    end
    
    return true, "Profile imported successfully"
end

-- Simple encoding (converts to hex)
function ProfileManager:EncodeString(str)
    local hex = ""
    for i = 1, #str do
        hex = hex .. string.format("%02x", string.byte(str, i))
    end
    return hex
end

-- Simple decoding (converts from hex)
function ProfileManager:DecodeString(hex)
    if not hex or hex == "" then return nil end
    
    -- Remove any whitespace
    hex = hex:gsub("%s+", "")
    
    -- Check if valid hex
    if not hex:match("^[0-9a-fA-F]+$") then
        return nil
    end
    
    -- Check if even length
    if #hex % 2 ~= 0 then
        return nil
    end
    
    local str = ""
    for i = 1, #hex, 2 do
        local byte = tonumber(hex:sub(i, i + 1), 16)
        if not byte then return nil end
        str = str .. string.char(byte)
    end
    
    return str
end

-- Reset to defaults
function ProfileManager:ResetToDefaults()
    local db = addon.PvPC.db.global
    
    db.enabled = true
    db.enableEnemyCallouts = true
    db.enableAllyCallouts = false
    db.calloutOffensive = true
    db.calloutDefensive = true
    db.calloutExternal = true
    db.calloutCC = true
    db.useTextCallouts = true
    db.useAudioCallouts = false
    db.outputChannel = "SAY"
    db.onlyInArena = true
    
    -- Clear spell overrides
    for k in pairs(db.spellOverrides) do
        db.spellOverrides[k] = nil
    end
    
    return true
end
