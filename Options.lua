---@type string, table
local addonName, addon = ...

local Options = {}
addon.Options = Options

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

-- Build options table
function Options:GetOptionsTable()
    local options = {
        type = "group",
        name = "PvP Callouts",
        args = {
            header = {
                type = "description",
                name = "Announces important PvP cooldowns being used in arena.",
                fontSize = "medium",
                order = 1,
            },
            
            enabled = {
                type = "toggle",
                name = "Enable PvP Callouts",
                desc = "Enable or disable the addon",
                get = function() return addon.PvPC.db.global.enabled end,
                set = function(_, value)
                    addon.PvPC.db.global.enabled = value
                    if value then
                        addon.PvPC:Enable()
                    else
                        addon.PvPC:Disable()
                    end
                end,
                order = 2,
                width = "full",
            },
            
            spacer1 = {
                type = "description",
                name = " ",
                order = 3,
            },
            
            -- Tracking options
            trackingHeader = {
                type = "header",
                name = "Tracking Options",
                order = 10,
            },
            
            enableEnemyCallouts = {
                type = "toggle",
                name = "Track Enemy Cooldowns",
                desc = "Call out when enemies use cooldowns",
                get = function() return addon.PvPC.db.global.enableEnemyCallouts end,
                set = function(_, value) addon.PvPC.db.global.enableEnemyCallouts = value end,
                order = 11,
            },
            
            enableAllyCallouts = {
                type = "toggle",
                name = "Track Ally Cooldowns",
                desc = "Call out when allies use cooldowns",
                get = function() return addon.PvPC.db.global.enableAllyCallouts end,
                set = function(_, value) addon.PvPC.db.global.enableAllyCallouts = value end,
                order = 12,
            },
            
            onlyInArena = {
                type = "toggle",
                name = "Only in Arena",
                desc = "Only track cooldowns while in arena",
                get = function() return addon.PvPC.db.global.onlyInArena end,
                set = function(_, value)
                    addon.PvPC.db.global.onlyInArena = value
                    if addon.AlertsModule then
                        addon.AlertsModule:RefreshTrackingState()
                    end
                end,
                order = 13,
            },
            
            spacer2 = {
                type = "description",
                name = " ",
                order = 19,
            },
            
            -- Spell type filters
            spellTypesHeader = {
                type = "header",
                name = "Spell Types to Call Out",
                order = 20,
            },
            
            calloutOffensive = {
                type = "toggle",
                name = "Offensive Cooldowns",
                desc = "Call out offensive cooldowns (e.g., Metamorphosis, Combustion)",
                get = function() return addon.PvPC.db.global.calloutOffensive end,
                set = function(_, value) addon.PvPC.db.global.calloutOffensive = value end,
                order = 21,
            },
            
            calloutDefensive = {
                type = "toggle",
                name = "Defensive Cooldowns",
                desc = "Call out defensive cooldowns (e.g., Evasion, Shield Wall)",
                get = function() return addon.PvPC.db.global.calloutDefensive end,
                set = function(_, value) addon.PvPC.db.global.calloutDefensive = value end,
                order = 22,
            },
            
            calloutExternal = {
                type = "toggle",
                name = "External Cooldowns",
                desc = "Call out external cooldowns (e.g., Blessing of Protection, Pain Suppression)",
                get = function() return addon.PvPC.db.global.calloutExternal end,
                set = function(_, value) addon.PvPC.db.global.calloutExternal = value end,
                order = 23,
            },
            
            calloutCC = {
                type = "toggle",
                name = "CC Cooldowns",
                desc = "Call out crowd control cooldowns (e.g., Leg Sweep)",
                get = function() return addon.PvPC.db.global.calloutCC end,
                set = function(_, value) addon.PvPC.db.global.calloutCC = value end,
                order = 24,
            },
            
            spacer3 = {
                type = "description",
                name = " ",
                order = 29,
            },
            
            -- Output options
            outputHeader = {
                type = "header",
                name = "Output Options",
                order = 30,
            },
            
            useTextCallouts = {
                type = "toggle",
                name = "Text Callouts",
                desc = "Enable text callouts",
                get = function() return addon.PvPC.db.global.useTextCallouts end,
                set = function(_, value) addon.PvPC.db.global.useTextCallouts = value end,
                order = 31,
            },

            outputChannel = {
                type = "select",
                name = "Output Channel",
                desc = "Where to send callout messages",
                values = {
                    SELF = "Self (Chat Frame)",
                    SAY = "Say",
                    PARTY = "Party/Raid",
                    RAID = "Raid",
                    YELL = "Yell",
                },
                get = function() return addon.PvPC.db.global.outputChannel end,
                set = function(_, value) addon.PvPC.db.global.outputChannel = value end,
                order = 32,
                disabled = function() return not addon.PvPC.db.global.useTextCallouts end,
            },

            useTTS = {
                type = "toggle",
                name = "Text-to-Speech Callouts",
                desc = "Enable TTS to announce spell names",
                get = function() return addon.PvPC.db.global.useTTS end,
                set = function(_, value) addon.PvPC.db.global.useTTS = value end,
                order = 33,
            },

            ttsVolume = {
                type = "range",
                name = "TTS Volume",
                desc = "Volume for text-to-speech callouts (100 = normal, 150 = +50%, 200 = +100%, 300 = +200%)",
                min = 0,
                max = 300,
                step = 10,
                get = function() return addon.PvPC.db.global.ttsVolume end,
                set = function(_, value)
                    addon.PvPC.db.global.ttsVolume = value
                    if addon.AlertsModule then
                        addon.AlertsModule:UpdateTTSSettings()
                    end
                end,
                order = 34,
                disabled = function() return not addon.PvPC.db.global.useTTS end,
            },

            ttsRate = {
                type = "range",
                name = "TTS Speed",
                desc = "Speech rate for text-to-speech callouts (0.5 = slow, 1.0 = normal, 3.0 = very fast)",
                min = 0.5,
                max = 3.0,
                step = 0.1,
                get = function() return addon.PvPC.db.global.ttsRate end,
                set = function(_, value)
                    addon.PvPC.db.global.ttsRate = value
                    if addon.AlertsModule then
                        addon.AlertsModule:UpdateTTSSettings()
                    end
                end,
                order = 35,
                disabled = function() return not addon.PvPC.db.global.useTTS end,
            },

            testTTSButton = {
                type = "execute",
                name = "Test TTS",
                desc = "Test text-to-speech (says 'Combustion')",
                func = function()
                    local voiceID = C_TTSSettings.GetVoiceOptionID(0)
                    local volume = addon.PvPC.db.global.ttsVolume or 100
                    local rate = addon.PvPC.db.global.ttsRate or 1
                    pcall(function()
                        C_VoiceChat.SpeakText(voiceID, "Combustion", rate, volume, true)
                    end)
                end,
                order = 36,
                disabled = function() return not addon.PvPC.db.global.useTTS end,
            },



            spacer4 = {
                type = "description",
                name = " ",
                order = 39,
            },

            -- Test button
            testHeader = {
                type = "header",
                name = "Testing",
                order = 40,
            },

            testButton = {
                type = "execute",
                name = "Test Callout",
                desc = "Trigger a test callout",
                func = function()
                    if addon.Callouts then
                        addon.Callouts:TestCallout()
                    end
                end,
                order = 41,
            },

            spacer5 = {
                type = "description",
                name = " ",
                order = 49,
            },

            -- Profile management
            profileHeader = {
                type = "header",
                name = "Profile Management",
                order = 45,
            },

            exportButton = {
                type = "execute",
                name = "Export Profile",
                desc = "Export your current settings to a string",
                func = function()
                    if addon.ProfileManager then
                        local exportString = addon.ProfileManager:ExportProfile()
                        self:ShowExportDialog(exportString)
                    end
                end,
                order = 46,
                width = 1.0,
            },

            importButton = {
                type = "execute",
                name = "Import Profile",
                desc = "Import settings from a string",
                func = function()
                    self:ShowImportDialog()
                end,
                order = 47,
                width = 1.0,
            },

            resetButton = {
                type = "execute",
                name = "Reset to Defaults",
                desc = "Reset all settings to default values",
                confirm = true,
                confirmText = "Are you sure you want to reset all settings to defaults?",
                func = function()
                    if addon.ProfileManager then
                        addon.ProfileManager:ResetToDefaults()
                        addon.PvPC:Print("Settings reset to defaults")
                    end
                end,
                order = 48,
                width = 1.0,
            },

            spacer5b = {
                type = "description",
                name = " ",
                order = 49.5,
            },

            -- Per-spell options
            spellsHeader = {
                type = "header",
                name = "Individual Spell Settings",
                order = 50,
            },

            spellsDesc = {
                type = "description",
                name = "Enable or disable callouts for specific spells. Disabled spells will not trigger callouts even if their type is enabled above.",
                order = 51,
            },

            spellsList = {
                type = "group",
                name = "Spell List",
                inline = true,
                order = 52,
                args = self:BuildSpellListOptions(),
            },
        }
    }

    return options
end

-- Build per-spell options
function Options:BuildSpellListOptions()
    local spellArgs = {}

    if not addon.SpellDB or not addon.SpellDB.SPELLS then
        return spellArgs
    end

    -- Map spec IDs to class names
    local specToClass = {
        -- Death Knight
        [250] = "Death Knight", [251] = "Death Knight", [252] = "Death Knight",
        -- Demon Hunter
        [577] = "Demon Hunter", [581] = "Demon Hunter",
        -- Druid
        [102] = "Druid", [103] = "Druid", [104] = "Druid", [105] = "Druid",
        -- Evoker
        [1467] = "Evoker", [1468] = "Evoker", [1473] = "Evoker",
        -- Hunter
        [253] = "Hunter", [254] = "Hunter", [255] = "Hunter",
        -- Mage
        [62] = "Mage", [63] = "Mage", [64] = "Mage",
        -- Monk
        [268] = "Monk", [269] = "Monk", [270] = "Monk",
        -- Paladin
        [65] = "Paladin", [66] = "Paladin", [70] = "Paladin",
        -- Priest
        [256] = "Priest", [257] = "Priest", [258] = "Priest",
        -- Rogue
        [259] = "Rogue", [260] = "Rogue", [261] = "Rogue",
        -- Shaman
        [262] = "Shaman", [263] = "Shaman", [264] = "Shaman",
        -- Warlock
        [265] = "Warlock", [266] = "Warlock", [267] = "Warlock",
        -- Warrior
        [71] = "Warrior", [72] = "Warrior", [73] = "Warrior",
    }

    -- Collect spells by class
    local spellsByClass = {}
    local classSpellsSeen = {} -- Track spells per class to avoid duplicates within the same class

    for specID, spells in pairs(addon.SpellDB.SPELLS) do
        local className = specToClass[specID] or "Unknown"

        if not spellsByClass[className] then
            spellsByClass[className] = {}
            classSpellsSeen[className] = {}
        end

        for _, spell in ipairs(spells) do
            -- Only prevent duplicates within the same class, not across all classes
            if not classSpellsSeen[className][spell.id] then
                classSpellsSeen[className][spell.id] = true
                table.insert(spellsByClass[className], spell)
            end
        end
    end

    -- Class order for display
    local classOrder = {
        "Death Knight", "Demon Hunter", "Druid", "Evoker", "Hunter", "Mage",
        "Monk", "Paladin", "Priest", "Rogue", "Shaman", "Warlock", "Warrior"
    }

    local orderCounter = 1

    -- Create options grouped by class
    for _, className in ipairs(classOrder) do
        local classSpells = spellsByClass[className]
        if classSpells then
            -- Add class header
            local headerKey = "header_" .. className:gsub(" ", "")
            spellArgs[headerKey] = {
                type = "header",
                name = className,
                order = orderCounter,
            }
            orderCounter = orderCounter + 1

            -- Sort spells by name within class
            table.sort(classSpells, function(a, b)
                return a.name < b.name
            end)

            -- Add spells for this class
            for _, spell in ipairs(classSpells) do
                -- Skip if spell.id is secret (shouldn't happen with hardcoded IDs, but be safe)
                if not spell.id or (issecretvalue and issecretvalue(spell.id)) then
                    -- Skip this spell
                else
                    local key = "spell_" .. spell.id
                    spellArgs[key] = {
                        type = "toggle",
                        name = spell.name,
                        desc = string.format("%s (%ds CD) - %s", spell.name, spell.cd, spell.type:upper()),
                        get = function()
                            local override = addon.PvPC.db.global.spellOverrides[spell.id]
                            if override == nil then
                                return true -- Default enabled
                            end
                            return override
                        end,
                        set = function(_, value)
                            addon.PvPC.db.global.spellOverrides[spell.id] = value
                        end,
                        order = orderCounter,
                    }
                    orderCounter = orderCounter + 1
                end
            end

            -- Add spacer after each class
            local spacerKey = "spacer_" .. className:gsub(" ", "")
            spellArgs[spacerKey] = {
                type = "description",
                name = " ",
                order = orderCounter,
            }
            orderCounter = orderCounter + 1
        end
    end

    return spellArgs
end

-- Register options
function Options:Register()
    AceConfig:RegisterOptionsTable("PvPCallouts", self:GetOptionsTable())
    self.optionsFrame, self.optionsCategoryID = AceConfigDialog:AddToBlizOptions("PvPCallouts", "PvPCallouts")
end

-- Open options
function Options:Open()
    -- Open Blizzard interface options to our panel
    if Settings and Settings.OpenToCategory then
        local category = self.optionsCategoryID or self.optionsFrame
        local ok = pcall(Settings.OpenToCategory, category)
        if not ok and self.optionsFrame and self.optionsFrame.name then
            pcall(Settings.OpenToCategory, self.optionsFrame.name)
        end
    elseif InterfaceOptionsFrame_OpenToCategory then
        pcall(InterfaceOptionsFrame_OpenToCategory, self.optionsFrame)
        pcall(InterfaceOptionsFrame_OpenToCategory, self.optionsFrame) -- Call twice for proper focus
    end
end

function PvPCallouts_OpenOptions()
    Options:Open()
end

function PvPCallouts_OnAddonCompartmentEnter(button)
    if GameTooltip and button then
        GameTooltip:SetOwner(button, "ANCHOR_LEFT")
        GameTooltip:SetText("PvPCallouts")
        GameTooltip:AddLine("Open options", 1, 1, 1)
        GameTooltip:Show()
    end
end

function PvPCallouts_OnAddonCompartmentLeave()
    if GameTooltip then
        GameTooltip:Hide()
    end
end

-- Show export dialog
function Options:ShowExportDialog(exportString)
    local AceGUI = LibStub("AceGUI-3.0")

    -- Create frame
    local frame = AceGUI:Create("Frame")
    frame:SetTitle("Export Profile")
    frame:SetStatusText("Copy the string below")
    frame:SetLayout("Fill")
    frame:SetWidth(500)
    frame:SetHeight(300)

    -- Create multiline editbox
    local editbox = AceGUI:Create("MultiLineEditBox")
    editbox:SetLabel("Profile String:")
    editbox:SetText(exportString)
    editbox:SetFullWidth(true)
    editbox:SetFullHeight(true)
    editbox:DisableButton(true)
    editbox:SetFocus()
    editbox.editBox:HighlightText()

    frame:AddChild(editbox)

    -- Close callback
    frame:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
    end)
end

-- Show import dialog
function Options:ShowImportDialog()
    local AceGUI = LibStub("AceGUI-3.0")

    -- Create frame
    local frame = AceGUI:Create("Frame")
    frame:SetTitle("Import Profile")
    frame:SetStatusText("Paste your profile string below")
    frame:SetLayout("Flow")
    frame:SetWidth(500)
    frame:SetHeight(300)

    -- Create multiline editbox
    local editbox = AceGUI:Create("MultiLineEditBox")
    editbox:SetLabel("Profile String:")
    editbox:SetFullWidth(true)
    editbox:SetNumLines(10)
    editbox:SetFocus()

    frame:AddChild(editbox)

    -- Import button
    local importBtn = AceGUI:Create("Button")
    importBtn:SetText("Import")
    importBtn:SetWidth(150)
    importBtn:SetCallback("OnClick", function()
        local importString = editbox:GetText()
        if addon.ProfileManager then
            local success, message = addon.ProfileManager:ImportProfile(importString)
            if success then
                addon.PvPC:Print("|cff00ff00" .. message .. "|r")
                frame:Hide()
            else
                addon.PvPC:Print("|cffff0000Error: " .. message .. "|r")
            end
        end
    end)

    frame:AddChild(importBtn)

    -- Close callback
    frame:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
    end)
end

-- Initialize options on addon load
if addon.PvPC then
    addon.PvPC.RegisterCallback = addon.PvPC.RegisterCallback or function() end

    -- Register after addon is fully loaded
    C_Timer.After(0.5, function()
        Options:Register()
    end)
end
