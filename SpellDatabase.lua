---@type string, table
local addonName, addon = ...

local SpellDB = {}
addon.SpellDB = SpellDB

-- Callout priority levels
-- HIGH = Always call out (major offensive CDs, major defensives)
-- MEDIUM = Call out if enabled (externals, CC)
-- LOW = Optional callouts

-- Spell database organized by specID
-- Each entry: { id = spellID, cd = cooldown_seconds, name = "...", type = "...", priority = "..." }
-- Types: "offensive", "defensive", "external", "cc"
-- Priority: "HIGH", "MEDIUM", "LOW"

SpellDB.SPELLS = {
    -- ==================== DEATH KNIGHT ====================
    [250] = { -- Blood
        { id = 55233, cd = 90, name = "Vampiric Blood", type = "offensive", priority = "MEDIUM" },
        { id = 49028, cd = 90, name = "Dancing Rune Weapon", type = "defensive", priority = "HIGH" },
        { id = 48792, cd = 120, name = "Icebound Fortitude", type = "defensive", priority = "MEDIUM" },
        { id = 48707, cd = 60, name = "Anti-Magic Shell", type = "defensive", priority = "MEDIUM" },
        { id = 49039, cd = 120, name = "Lichborne", type = "defensive", priority = "MEDIUM" },
    },
    [251] = { -- Frost
        { id = 279302, cd = 90, name = "Frostwyrm's Fury", type = "offensive", priority = "HIGH" },
        { id = 51271, cd = 45, name = "Pillar of Frost", type = "offensive", priority = "HIGH" },
        { id = 48792, cd = 120, name = "Icebound Fortitude", type = "defensive", priority = "MEDIUM" },
        { id = 48707, cd = 60, name = "Anti-Magic Shell", type = "defensive", priority = "MEDIUM" },
        { id = 51052, cd = 240, name = "Anti-Magic Zone", type = "defensive", priority = "MEDIUM" },
        { id = 49039, cd = 120, name = "Lichborne", type = "defensive", priority = "MEDIUM" },
    },
    [252] = { -- Unholy
        { id = 42650, cd = 90, name = "Army of the Dead", type = "offensive", priority = "HIGH" },
        { id = 275699, cd = 90, name = "Apocalypse", type = "offensive", priority = "HIGH" },
        { id = 48792, cd = 120, name = "Icebound Fortitude", type = "defensive", priority = "MEDIUM" },
        { id = 48707, cd = 60, name = "Anti-Magic Shell", type = "defensive", priority = "MEDIUM" },
        { id = 49039, cd = 120, name = "Lichborne", type = "defensive", priority = "MEDIUM" },
    },
    
    -- ==================== DEMON HUNTER ====================
    [577] = { -- Havoc
        { id = 191427, cd = 120, name = "Metamorphosis", type = "offensive", priority = "HIGH" },
        { id = 198589, cd = 60, name = "Blur", type = "defensive", priority = "HIGH" },
        { id = 196718, cd = 180, name = "Darkness", type = "defensive", priority = "MEDIUM" },
    },
    [581] = { -- Vengeance
        { id = 187827, cd = 120, name = "Metamorphosis", type = "offensive", priority = "HIGH" },
        { id = 204021, cd = 48, name = "Fiery Brand", type = "defensive", priority = "MEDIUM" },
        { id = 196718, cd = 180, name = "Darkness", type = "defensive", priority = "MEDIUM" },
    },
    
    -- ==================== DRUID ====================
    [102] = { -- Balance
        { id = 102560, cd = 120, name = "Incarnation: Chosen of Elune", type = "offensive", priority = "HIGH" },
        { id = 377362, cd = 90, name = "Precognition", type = "defensive", priority = "HIGH" },
        { id = 22812, cd = 34, name = "Barkskin", type = "defensive", priority = "MEDIUM" },
    },
    [103] = { -- Feral
        { id = 102543, cd = 90, name = "Incarnation: Avatar of Ashamane", type = "offensive", priority = "HIGH" },
        { id = 377362, cd = 90, name = "Precognition", type = "defensive", priority = "HIGH" },
        { id = 61336, cd = 180, name = "Survival Instincts", type = "defensive", priority = "HIGH" },
    },
    [104] = { -- Guardian
        { id = 102558, cd = 120, name = "Incarnation: Guardian of Ursoc", type = "offensive", priority = "HIGH" },
        { id = 377362, cd = 90, name = "Precognition", type = "defensive", priority = "HIGH" },
        { id = 61336, cd = 136, name = "Survival Instincts", type = "defensive", priority = "HIGH" },
    },
    [105] = { -- Restoration
        { id = 740, cd = 180, name = "Tranquility", type = "offensive", priority = "HIGH" },
        { id = 377362, cd = 90, name = "Precognition", type = "defensive", priority = "HIGH" },
        { id = 102342, cd = 72, name = "Ironbark", type = "external", priority = "MEDIUM" },
        { id = 391528, cd = 60, name = "Convoke the Spirits", type = "offensive", priority = "HIGH" },
    },
    
    -- ==================== EVOKER ====================
    [1467] = { -- Devastation
        { id = 375087, cd = 120, name = "Dragonrage", type = "offensive", priority = "HIGH" },
        { id = 377362, cd = 90, name = "Precognition", type = "defensive", priority = "HIGH" },
        { id = 363916, cd = 90, name = "Obsidian Scales", type = "defensive", priority = "MEDIUM" },
    },
    [1468] = { -- Preservation
        { id = 363534, cd = 120, name = "Rewind", type = "offensive", priority = "HIGH" },
        { id = 377362, cd = 90, name = "Precognition", type = "defensive", priority = "HIGH" },
        { id = 370537, cd = 90, name = "Stasis", type = "offensive", priority = "MEDIUM" },
    },
    [1473] = { -- Augmentation
        { id = 403631, cd = 120, name = "Breath of Eons", type = "offensive", priority = "HIGH" },
        { id = 377362, cd = 90, name = "Precognition", type = "defensive", priority = "HIGH" },
        { id = 363916, cd = 90, name = "Obsidian Scales", type = "defensive", priority = "MEDIUM" },
    },
    
    -- ==================== HUNTER ====================
    [253] = { -- Beast Mastery
        { id = 1250646, cd = 60, name = "Takedown", type = "offensive", priority = "HIGH" },
        { id = 186265, cd = 120, name = "Aspect of the Turtle", type = "defensive", priority = "HIGH" },
    },
    [254] = { -- Marksmanship
        { id = 288613, cd = 120, name = "Trueshot", type = "offensive", priority = "HIGH" },
        { id = 186265, cd = 120, name = "Aspect of the Turtle", type = "defensive", priority = "HIGH" },
    },
    [255] = { -- Survival
        { id = 186265, cd = 120, name = "Aspect of the Turtle", type = "defensive", priority = "HIGH" },
        { id = 264735, cd = 90, name = "Survival of the Fittest", type = "defensive", priority = "MEDIUM" },
    },
    
    -- ==================== MAGE ====================
    [62] = { -- Arcane
        { id = 365350, cd = 90, name = "Arcane Surge", type = "offensive", priority = "HIGH" },
        { id = 377362, cd = 90, name = "Precognition", type = "defensive", priority = "HIGH" },
        { id = 414658, cd = 150, name = "Ice Cold", type = "defensive", priority = "HIGH" },
        { id = 45438, cd = 240, name = "Ice Block", type = "defensive", priority = "HIGH" },
        { id = 342247, cd = 50, name = "Alter Time", type = "defensive", priority = "MEDIUM" },
        { id = 55342, cd = 120, name = "Mirror Image", type = "defensive", priority = "MEDIUM" },
    },
    [63] = { -- Fire
        { id = 190319, cd = 60, name = "Combustion", type = "offensive", priority = "HIGH" },
        { id = 377362, cd = 90, name = "Precognition", type = "defensive", priority = "HIGH" },
        { id = 414658, cd = 150, name = "Ice Cold", type = "defensive", priority = "HIGH" },
        { id = 45438, cd = 240, name = "Ice Block", type = "defensive", priority = "HIGH" },
        { id = 342247, cd = 50, name = "Alter Time", type = "defensive", priority = "MEDIUM" },
        { id = 55342, cd = 120, name = "Mirror Image", type = "defensive", priority = "MEDIUM" },
    },
    [64] = { -- Frost
        { id = 12472, cd = 120, name = "Icy Veins", type = "offensive", priority = "HIGH" },
        { id = 235219, cd = 300, name = "Cold Snap", type = "defensive", priority = "HIGH" },
        { id = 377362, cd = 90, name = "Precognition", type = "defensive", priority = "HIGH" },
        { id = 414658, cd = 150, name = "Ice Cold", type = "defensive", priority = "HIGH" },
        { id = 45438, cd = 240, name = "Ice Block", type = "defensive", priority = "HIGH" },
        { id = 342247, cd = 50, name = "Alter Time", type = "defensive", priority = "MEDIUM" },
        { id = 55342, cd = 120, name = "Mirror Image", type = "defensive", priority = "MEDIUM" },
    },
    
    -- ==================== MONK ====================
    [268] = { -- Brewmaster
        { id = 115203, cd = 120, name = "Fortifying Brew", type = "defensive", priority = "MEDIUM" },
        { id = 377362, cd = 90, name = "Precognition", type = "defensive", priority = "HIGH" },
        { id = 119381, cd = 55, name = "Leg Sweep", type = "cc", priority = "MEDIUM" },
        { id = 122278, cd = 120, name = "Dampen Harm", type = "defensive", priority = "MEDIUM" },
    },
    [270] = { -- Mistweaver
        { id = 115310, cd = 150, name = "Revival", type = "offensive", priority = "HIGH" },
        { id = 443028, cd = 90, name = "Celestial", type = "offensive", priority = "HIGH" },
        { id = 377362, cd = 90, name = "Precognition", type = "defensive", priority = "HIGH" },
        { id = 116849, cd = 75, name = "Life Cocoon", type = "external", priority = "MEDIUM" },
        { id = 122278, cd = 120, name = "Dampen Harm", type = "defensive", priority = "MEDIUM" },
    },
    [269] = { -- Windwalker
        { id = 123904, cd = 90, name = "Xuen", type = "offensive", priority = "HIGH" },
        { id = 443028, cd = 90, name = "Celestial", type = "offensive", priority = "HIGH" },
        { id = 377362, cd = 90, name = "Precognition", type = "defensive", priority = "HIGH" },
        { id = 137639, cd = 90, name = "Storm, Earth, and Fire", type = "offensive", priority = "HIGH" },
        { id = 122470, cd = 90, name = "Touch of Karma", type = "defensive", priority = "HIGH" },
        { id = 122278, cd = 120, name = "Dampen Harm", type = "defensive", priority = "MEDIUM" },
    },

    -- ==================== PALADIN ====================
    [65] = { -- Holy
        { id = 31884, cd = 120, name = "Avenging Wrath", type = "offensive", priority = "HIGH" },
        { id = 377362, cd = 90, name = "Precognition", type = "defensive", priority = "HIGH" },
        { id = 642, cd = 210, name = "Divine Shield", type = "defensive", priority = "HIGH" },
        { id = 498, cd = 60, name = "Divine Protection", type = "defensive", priority = "MEDIUM" },
        { id = 1022, cd = 300, name = "Blessing of Protection", type = "external", priority = "MEDIUM" },
        { id = 6940, cd = 90, name = "Blessing of Sacrifice", type = "external", priority = "MEDIUM" },
        { id = 633, cd = 290, name = "Lay on Hands", type = "external", priority = "HIGH" },
    },
    [66] = { -- Protection
        { id = 86659, cd = 180, name = "Guardian of Ancient Kings", type = "defensive", priority = "HIGH" },
        { id = 377362, cd = 90, name = "Precognition", type = "defensive", priority = "HIGH" },
        { id = 642, cd = 210, name = "Divine Shield", type = "defensive", priority = "HIGH" },
        { id = 498, cd = 60, name = "Divine Protection", type = "defensive", priority = "MEDIUM" },
        { id = 31850, cd = 60, name = "Ardent Defender", type = "defensive", priority = "MEDIUM" },
    },
    [70] = { -- Retribution
        { id = 31884, cd = 120, name = "Avenging Wrath", type = "offensive", priority = "HIGH" },
        { id = 377362, cd = 90, name = "Precognition", type = "defensive", priority = "HIGH" },
        { id = 642, cd = 210, name = "Divine Shield", type = "defensive", priority = "HIGH" },
        { id = 498, cd = 60, name = "Divine Protection", type = "defensive", priority = "MEDIUM" },
        { id = 1022, cd = 300, name = "Blessing of Protection", type = "external", priority = "MEDIUM" },
        { id = 6940, cd = 60, name = "Blessing of Sacrifice", type = "external", priority = "MEDIUM" },
    },

    -- ==================== PRIEST ====================
    [256] = { -- Discipline
        { id = 62618, cd = 180, name = "Power Word: Barrier", type = "defensive", priority = "HIGH" },
        { id = 377362, cd = 90, name = "Precognition", type = "defensive", priority = "HIGH" },
        { id = 33206, cd = 180, name = "Pain Suppression", type = "external", priority = "HIGH" },
        { id = 47536, cd = 90, name = "Rapture", type = "offensive", priority = "MEDIUM" },
        { id = 19236, cd = 90, name = "Desperate Prayer", type = "defensive", priority = "MEDIUM" },
    },
    [257] = { -- Holy
        { id = 64843, cd = 180, name = "Divine Hymn", type = "offensive", priority = "HIGH" },
        { id = 377362, cd = 90, name = "Precognition", type = "defensive", priority = "HIGH" },
        { id = 47788, cd = 180, name = "Guardian Spirit", type = "external", priority = "HIGH" },
        { id = 19236, cd = 90, name = "Desperate Prayer", type = "defensive", priority = "MEDIUM" },
    },
    [258] = { -- Shadow
        { id = 228260, cd = 90, name = "Void Eruption", type = "offensive", priority = "HIGH" },
        { id = 199824, cd = 45, name = "Psyfiend", type = "offensive", priority = "MEDIUM" },
        { id = 377362, cd = 90, name = "Precognition", type = "defensive", priority = "HIGH" },
        { id = 15286, cd = 120, name = "Vampiric Embrace", type = "defensive", priority = "MEDIUM" },
        { id = 47585, cd = 120, name = "Dispersion", type = "defensive", priority = "HIGH" },
        { id = 19236, cd = 90, name = "Desperate Prayer", type = "defensive", priority = "MEDIUM" },
    },

    -- ==================== ROGUE ====================
    [259] = { -- Assassination
        { id = 360194, cd = 120, name = "Deathmark", type = "offensive", priority = "HIGH" },
        { id = 5277, cd = 120, name = "Evasion", type = "defensive", priority = "HIGH" },
        { id = 31224, cd = 120, name = "Cloak of Shadows", type = "defensive", priority = "HIGH" },
        { id = 1856, cd = 120, name = "Vanish", type = "defensive", priority = "HIGH" },
    },
    [260] = { -- Outlaw
        { id = 13750, cd = 180, name = "Adrenaline Rush", type = "offensive", priority = "HIGH" },
        { id = 5277, cd = 120, name = "Evasion", type = "defensive", priority = "HIGH" },
        { id = 31224, cd = 120, name = "Cloak of Shadows", type = "defensive", priority = "HIGH" },
        { id = 1856, cd = 120, name = "Vanish", type = "defensive", priority = "HIGH" },
    },
    [261] = { -- Subtlety
        { id = 121471, cd = 90, name = "Shadow Blades", type = "offensive", priority = "HIGH" },
        { id = 212283, cd = 25, name = "Symbols of Death", type = "offensive", priority = "MEDIUM" },
        { id = 5277, cd = 120, name = "Evasion", type = "defensive", priority = "HIGH" },
        { id = 31224, cd = 120, name = "Cloak of Shadows", type = "defensive", priority = "HIGH" },
        { id = 1856, cd = 120, name = "Vanish", type = "defensive", priority = "HIGH" },
    },

    -- ==================== SHAMAN ====================
    [262] = { -- Elemental
        { id = 114050, cd = 120, name = "Ascendance", type = "offensive", priority = "HIGH" },
        { id = 191634, cd = 60, name = "Stormkeeper", type = "offensive", priority = "MEDIUM" },
        { id = 198067, cd = 150, name = "Fire Elemental", type = "offensive", priority = "MEDIUM" },
        { id = 377362, cd = 90, name = "Precognition", type = "defensive", priority = "HIGH" },
        { id = 108271, cd = 90, name = "Astral Shift", type = "defensive", priority = "MEDIUM" },
    },
    [263] = { -- Enhancement
        { id = 114051, cd = 120, name = "Ascendance", type = "offensive", priority = "HIGH" },
        { id = 51533, cd = 120, name = "Feral Spirit", type = "offensive", priority = "HIGH" },
        { id = 377362, cd = 90, name = "Precognition", type = "defensive", priority = "HIGH" },
        { id = 108271, cd = 90, name = "Astral Shift", type = "defensive", priority = "MEDIUM" },
    },
    [264] = { -- Restoration
        { id = 114052, cd = 120, name = "Ascendance", type = "offensive", priority = "HIGH" },
        { id = 98008, cd = 180, name = "Spirit Link Totem", type = "defensive", priority = "HIGH" },
        { id = 108280, cd = 180, name = "Healing Tide Totem", type = "offensive", priority = "MEDIUM" },
        { id = 377362, cd = 90, name = "Precognition", type = "defensive", priority = "HIGH" },
        { id = 108271, cd = 90, name = "Astral Shift", type = "defensive", priority = "MEDIUM" },
    },

    -- ==================== WARLOCK ====================
    [265] = { -- Affliction
        { id = 205180, cd = 120, name = "Summon Darkglare", type = "offensive", priority = "HIGH" },
        { id = 386997, cd = 60, name = "Soul Rot", type = "offensive", priority = "HIGH" },
        { id = 205179, cd = 45, name = "Phantom Singularity", type = "offensive", priority = "MEDIUM" },
        { id = 113860, cd = 120, name = "Dark Soul: Misery", type = "offensive", priority = "HIGH" },
        { id = 377362, cd = 90, name = "Precognition", type = "defensive", priority = "HIGH" },
        { id = 104773, cd = 180, name = "Unending Resolve", type = "defensive", priority = "MEDIUM" },
        { id = 108416, cd = 60, name = "Dark Pact", type = "defensive", priority = "MEDIUM" },
        { id = 212295, cd = 45, name = "Nether Ward", type = "defensive", priority = "HIGH" },
    },
    [266] = { -- Demonology
        { id = 265187, cd = 90, name = "Summon Demonic Tyrant", type = "offensive", priority = "HIGH" },
        { id = 267171, cd = 60, name = "Demonic Strength", type = "offensive", priority = "MEDIUM" },
        { id = 111898, cd = 120, name = "Grimoire: Felguard", type = "offensive", priority = "MEDIUM" },
        { id = 113858, cd = 120, name = "Dark Soul: Instability", type = "offensive", priority = "HIGH" },
        { id = 377362, cd = 90, name = "Precognition", type = "defensive", priority = "HIGH" },
        { id = 104773, cd = 180, name = "Unending Resolve", type = "defensive", priority = "MEDIUM" },
        { id = 108416, cd = 60, name = "Dark Pact", type = "defensive", priority = "MEDIUM" },
        { id = 212295, cd = 45, name = "Nether Ward", type = "defensive", priority = "HIGH" },
    },
    [267] = { -- Destruction
        { id = 1122, cd = 180, name = "Summon Infernal", type = "offensive", priority = "HIGH" },
        { id = 152108, cd = 30, name = "Cataclysm", type = "offensive", priority = "MEDIUM" },
        { id = 113861, cd = 120, name = "Dark Soul: Instability", type = "offensive", priority = "HIGH" },
        { id = 377362, cd = 90, name = "Precognition", type = "defensive", priority = "HIGH" },
        { id = 104773, cd = 180, name = "Unending Resolve", type = "defensive", priority = "MEDIUM" },
        { id = 108416, cd = 60, name = "Dark Pact", type = "defensive", priority = "MEDIUM" },
        { id = 212295, cd = 45, name = "Nether Ward", type = "defensive", priority = "HIGH" },
    },

    -- ==================== WARRIOR ====================
    [71] = { -- Arms
        { id = 107574, cd = 90, name = "Avatar", type = "offensive", priority = "HIGH" },
        { id = 227847, cd = 90, name = "Bladestorm", type = "offensive", priority = "HIGH" },
        { id = 118038, cd = 100, name = "Die by the Sword", type = "defensive", priority = "HIGH" },
        { id = 97462, cd = 180, name = "Rallying Cry", type = "defensive", priority = "MEDIUM" },
    },
    [72] = { -- Fury
        { id = 1719, cd = 90, name = "Recklessness", type = "offensive", priority = "HIGH" },
        { id = 184364, cd = 100, name = "Enraged Regeneration", type = "defensive", priority = "MEDIUM" },
        { id = 97462, cd = 180, name = "Rallying Cry", type = "defensive", priority = "MEDIUM" },
    },
    [73] = { -- Protection
        { id = 107574, cd = 90, name = "Avatar", type = "offensive", priority = "HIGH" },
        { id = 871, cd = 100, name = "Shield Wall", type = "defensive", priority = "HIGH" },
        { id = 12975, cd = 180, name = "Last Stand", type = "defensive", priority = "HIGH" },
        { id = 97462, cd = 180, name = "Rallying Cry", type = "defensive", priority = "MEDIUM" },
    },
}

-- Build a lookup table by spell name for taint-safe lookups
-- This is called once when the addon loads
function SpellDB:BuildLookupTable()
    self.SPELL_LOOKUP_BY_NAME = {}
    self.SPELL_LOOKUP_BY_ID = {}

    for specID, spells in pairs(self.SPELLS) do
        for _, spell in ipairs(spells) do
            -- Use spell name as the key (names are not tainted)
            local spellName = spell.name
            if spellName then
                if not self.SPELL_LOOKUP_BY_NAME[spellName] then
                    self.SPELL_LOOKUP_BY_NAME[spellName] = {}
                end
                table.insert(self.SPELL_LOOKUP_BY_NAME[spellName], {
                    spell = spell,
                    specID = specID
                })
            end

            if spell.id then
                self.SPELL_LOOKUP_BY_ID[spell.id] = spell
            end
        end
    end
end

function SpellDB:GetSpellByID(spellID)
    local okNumber, cleanSpellID = pcall(tonumber, spellID)
    if not okNumber or not cleanSpellID then
        return nil
    end

    if not self.SPELL_LOOKUP_BY_ID then
        local okBuild = pcall(function()
            self:BuildLookupTable()
        end)
        if not okBuild then
            return nil
        end
    end

    local okLookup, spell = pcall(function()
        return self.SPELL_LOOKUP_BY_ID[cleanSpellID]
    end)
    if okLookup then
        return spell
    end

    return nil
end

-- Helper function to lookup spell by unit and spellID
function SpellDB:LookupSpell(unit, spellID)
    if not spellID or not unit then
        print("[SpellDB DEBUG] No spellID or unit")
        return nil
    end

    local specID = self:GetSpecIDForUnit(unit)
    print(string.format("[SpellDB DEBUG] Unit: %s, SpecID: %s, SpellID: %s", unit, tostring(specID), tostring(spellID)))
    if not specID then return nil end

    -- Look up the spell directly by ID in our database
    -- Don't use spell names from API as they can be tainted in combat
    local spells = self.SPELLS[specID]
    if not spells then
        print(string.format("[SpellDB DEBUG] No spells found for specID: %d", specID))
        return nil
    end

    -- Find the spell by ID
    -- Use tonumber() to ensure we're comparing clean numbers
    local cleanSpellID = tonumber(spellID)
    if not cleanSpellID then
        print("[SpellDB DEBUG] Could not convert spellID to number")
        return nil
    end

    for _, spell in ipairs(spells) do
        if spell.id == cleanSpellID then
            print(string.format("[SpellDB DEBUG] Found spell: %s (ID: %d, Type: %s)", spell.name, spell.id, spell.type))
            return spell
        end
    end

    print(string.format("[SpellDB DEBUG] Spell ID %d not found in database for spec %d", cleanSpellID, specID))
    return nil
end

-- Helper to count lookup entries
function SpellDB:CountLookupEntries()
    local count = 0
    if self.SPELL_LOOKUP_BY_NAME then
        for _ in pairs(self.SPELL_LOOKUP_BY_NAME) do
            count = count + 1
        end
    end
    return count
end

-- Get spec ID for a unit (arena1-3, party1-4, player)
function SpellDB:GetSpecIDForUnit(unit)
    if not unit then return nil end

    -- Arena units
    local arenaIdx = unit:match("^arena(%d)$")
    if arenaIdx then
        arenaIdx = tonumber(arenaIdx)
        if arenaIdx and GetArenaOpponentSpec then
            local specID = GetArenaOpponentSpec(arenaIdx)
            if specID and specID > 0 then
                return specID
            end
        end
        return nil
    end

    -- Player
    if UnitIsUnit and UnitIsUnit(unit, "player") then
        if GetSpecialization and GetSpecializationInfo then
            local specIndex = GetSpecialization()
            if specIndex then
                local specID = GetSpecializationInfo(specIndex)
                if specID and specID > 0 then
                    return specID
                end
            end
        end
        return nil
    end

    -- Party members - would need inspect system (simplified for now)
    if unit:match("^party%d$") then
        -- For party members, we'd need an inspect system
        -- For now, return nil (can be enhanced later)
        return nil
    end

    return nil
end
