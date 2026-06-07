---@type string, table
local addonName, addon = ...

local Callouts = {}
addon.Callouts = Callouts

-- Trigger a callout for a spell
function Callouts:TriggerCallout(unit, spell, isEnemy)
    if not unit or not spell then return end
    
    local db = addon.PvPC.db.global
    
    -- Get unit name for callout
    local unitName = self:GetUnitName(unit)
    if not unitName then
        unitName = unit -- Fallback to unit ID
    end
    
    -- Build callout message
    local message = self:BuildCalloutMessage(unitName, spell, isEnemy)
    
    -- Output text callout
    if db.useTextCallouts then
        self:OutputTextCallout(message, db.outputChannel)
    end
    
    -- Output audio callout
    if db.useAudioCallouts and addon.AudioCallouts then
        addon.AudioCallouts:TriggerCallout(unit, spell, isEnemy)
    end
end

-- Build the callout message
function Callouts:BuildCalloutMessage(unitName, spell, isEnemy)
    local prefix = isEnemy and "[ENEMY]" or "[ALLY]"
    
    -- Format: [ENEMY] PlayerName used Metamorphosis!
    return string.format("%s %s used %s!", prefix, unitName, spell.name)
end

-- Output text callout to chat
function Callouts:OutputTextCallout(message, channel)
    if not message then return end
    
    channel = channel or "SELF"
    
    if channel == "SELF" then
        -- Print to chat frame
        if addon.PvPC then
            addon.PvPC:Print(message)
        else
            print(message)
        end
    elseif channel == "SAY" then
        SendChatMessage(message, "SAY")
    elseif channel == "PARTY" then
        if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
            SendChatMessage(message, "INSTANCE_CHAT")
        elseif IsInRaid() then
            SendChatMessage(message, "RAID")
        elseif IsInGroup() then
            SendChatMessage(message, "PARTY")
        else
            -- Not in a group, print to self
            if addon.PvPC then
                addon.PvPC:Print(message)
            end
        end
    elseif channel == "RAID" then
        if IsInRaid() then
            SendChatMessage(message, "RAID")
        elseif IsInGroup() then
            SendChatMessage(message, "PARTY")
        else
            -- Not in a group, print to self
            if addon.PvPC then
                addon.PvPC:Print(message)
            end
        end
    elseif channel == "YELL" then
        SendChatMessage(message, "YELL")
    end
end

-- Output audio callout (placeholder for future TTS or sound files)
function Callouts:OutputAudioCallout(spell)
    -- Future: Play sound file or use TTS
    -- For now, just play a generic sound
    PlaySound(SOUNDKIT.RAID_WARNING)
end

-- Get unit name
function Callouts:GetUnitName(unit)
    if not unit then return nil end
    
    -- Try to get the unit's name
    if UnitExists and UnitExists(unit) then
        local name = UnitName(unit)
        if name and name ~= "" then
            -- Remove server name if present
            name = name:match("^([^%-]+)") or name
            return name
        end
    end
    
    -- Fallback for arena units
    if unit:match("^arena(%d)$") then
        local num = unit:match("^arena(%d)$")
        return "Arena " .. num
    end
    
    return nil
end

-- Test callout
function Callouts:TestCallout()
    local testSpell = {
        id = 191427,
        name = "Metamorphosis",
        type = "offensive",
        priority = "HIGH",
        cd = 120
    }

    self:TriggerCallout("arena1", testSpell, true)
end

