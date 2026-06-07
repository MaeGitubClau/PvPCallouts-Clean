local addonName, addon = ...

local frame = CreateFrame("Frame")
local db
local spellDB
local trackingActive = false
local previousAuras = {}
local trackedGUIDs = {}
local recentCallouts = {}
local optionsFrame
local optionControls
local refreshingOptions = false

local DEFAULTS = {
    version = "3.0.2-clean",
    enabled = true,
    onlyInArena = true,
    enemies = true,
    allies = false,
    tts = true,
    text = true,
    output = "self",
    volume = 100,
    rate = 1.0,
    types = {
        offensive = true,
        defensive = true,
        external = true,
        cc = true,
    },
}

local TRACKED_UNITS = {
    "arena1", "arena2", "arena3", "arena4", "arena5",
    "player", "party1", "party2", "party3", "party4",
}

local AURA_FILTERS = { "HELPFUL", "HARMFUL" }
local CALLOUT_THROTTLE_SECONDS = 2.5
local COMBAT_LOG_EVENTS = {
    SPELL_CAST_SUCCESS = true,
    SPELL_AURA_APPLIED = true,
    SPELL_AURA_REFRESH = true,
}

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99PvPCallouts|r: " .. tostring(message))
end

local function CopyDefaults(defaults, target)
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then
                target[key] = {}
            end
            CopyDefaults(value, target[key])
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

local function Trim(value)
    return (tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function IsArena()
    local _, instanceType = IsInInstance()
    return instanceType == "arena"
end

local function IsTrackingAllowed()
    if not db or not db.enabled then
        return false
    end

    return not db.onlyInArena or IsArena()
end

local function IsUnitAllowed(unit)
    if not unit or not UnitExists(unit) then
        return false
    end

    if UnitIsUnit(unit, "player") then
        return db.allies
    end

    if UnitIsEnemy("player", unit) then
        return db.enemies
    end

    if UnitInParty(unit) or UnitInRaid(unit) then
        return db.allies
    end

    return false
end

local function RefreshTrackedGUIDs()
    trackedGUIDs = {}

    for _, unit in ipairs(TRACKED_UNITS) do
        if IsUnitAllowed(unit) then
            local guid = UnitGUID(unit)
            if guid then
                trackedGUIDs[guid] = unit
            end
        end
    end
end

local function IsSpellAllowed(spell)
    if type(spell) ~= "table" then
        return false
    end

    local spellType = spell.type
    if spellType and db.types and db.types[spellType] ~= nil then
        return db.types[spellType]
    end

    return true
end

local function SafeGetAura(unit, index, filter)
    if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then
        return nil
    end

    local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, filter)
    if ok and type(aura) == "table" then
        return aura
    end

    return nil
end

local function GetSpellID(aura)
    if type(aura) ~= "table" then
        return nil
    end

    return tonumber(aura.spellId)
end

local function GetAuraKey(unit, aura, spellID)
    local auraInstanceID = type(aura) == "table" and tonumber(aura.auraInstanceID)
    if auraInstanceID then
        return unit .. ":" .. auraInstanceID .. ":" .. spellID
    end

    return unit .. ":" .. spellID
end

local function Speak(text)
    if not db.tts or not C_VoiceChat or not C_VoiceChat.SpeakText then
        return
    end

    local voiceID = 0
    if C_TTSSettings and C_TTSSettings.GetVoiceOptionID then
        local ok, value = pcall(C_TTSSettings.GetVoiceOptionID, 0)
        if ok and value then
            voiceID = value
        end
    end

    pcall(C_VoiceChat.SpeakText, voiceID, tostring(text), tonumber(db.rate) or 1.0, tonumber(db.volume) or 100, true)
end

local function TextCallout(message)
    if not db.text then
        return
    end

    if db.output == "self" then
        Print(message)
        return
    end

    local channel = string.upper(tostring(db.output or "self"))
    if channel == "SAY" or channel == "PARTY" or channel == "RAID" or channel == "YELL" then
        pcall(SendChatMessage, message, channel)
    else
        Print(message)
    end
end

local function AnnounceName(unitName, spell)
    local name = unitName or "Enemy"
    local spellName = spell.name or ("spell " .. tostring(spell.id))
    local message = string.format("%s used %s", name, spellName)

    TextCallout(message)
    Speak(spellName)
end

local function Announce(unit, spell)
    local unitName = UnitName(unit) or unit
    AnnounceName(unitName, spell)
end

local function IsCalloutThrottled(key)
    local now = GetTime()
    local previous = recentCallouts[key]
    if previous and now - previous < CALLOUT_THROTTLE_SECONDS then
        return true
    end

    recentCallouts[key] = now
    return false
end

local function HandleCombatLog()
    if not trackingActive or not CombatLogGetCurrentEventInfo then
        return
    end

    local ok, _, subevent, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID = pcall(CombatLogGetCurrentEventInfo)
    if not ok or not COMBAT_LOG_EVENTS[subevent] then
        return
    end

    spellID = tonumber(spellID)
    local spell = spellID and spellDB and spellDB:GetSpellByID(spellID)
    if not spell or not IsSpellAllowed(spell) then
        return
    end

    local guid = sourceGUID
    local unit = trackedGUIDs[guid]
    local name = sourceName

    if not unit and destGUID then
        guid = destGUID
        unit = trackedGUIDs[guid]
        name = destName
    end

    if not unit then
        return
    end

    local key = tostring(guid) .. ":" .. tostring(spellID)
    if IsCalloutThrottled(key) then
        return
    end

    AnnounceName(name or UnitName(unit), spell)
end

local function ScanUnit(unit, currentAuras, suppress)
    if not IsUnitAllowed(unit) then
        return
    end

    for _, filter in ipairs(AURA_FILTERS) do
        for index = 1, 40 do
            local aura = SafeGetAura(unit, index, filter)
            if not aura then
                break
            end

            local spellID = GetSpellID(aura)
            local spell = spellID and spellDB and spellDB:GetSpellByID(spellID)
            if spell and IsSpellAllowed(spell) then
                local key = GetAuraKey(unit, aura, spellID)
                currentAuras[key] = true
                if not suppress and not previousAuras[key] then
                    Announce(unit, spell)
                end
            end
        end
    end
end

local function ScanAll(suppress)
    if not trackingActive then
        return
    end

    RefreshTrackedGUIDs()

    local currentAuras = {}
    for _, unit in ipairs(TRACKED_UNITS) do
        ScanUnit(unit, currentAuras, suppress)
    end
    previousAuras = currentAuras
end

local function StopTracking()
    frame:UnregisterEvent("UNIT_AURA")
    frame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    trackingActive = false
    previousAuras = {}
    trackedGUIDs = {}
    recentCallouts = {}
end

local function StartTracking()
    StopTracking()

    if not IsTrackingAllowed() then
        return
    end

    for _, unit in ipairs(TRACKED_UNITS) do
        frame:RegisterUnitEvent("UNIT_AURA", unit)
    end

    frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    trackingActive = true
    RefreshTrackedGUIDs()
    ScanAll(true)
end

local function RefreshTracking()
    if IsTrackingAllowed() then
        StartTracking()
    else
        StopTracking()
    end
end

local function Status()
    Print("version=" .. tostring(db.version)
        .. ", enabled=" .. tostring(db.enabled)
        .. ", arenaOnly=" .. tostring(db.onlyInArena)
        .. ", tracking=" .. tostring(trackingActive)
        .. ", enemies=" .. tostring(db.enemies)
        .. ", allies=" .. tostring(db.allies)
        .. ", text=" .. tostring(db.text)
        .. ", tts=" .. tostring(db.tts)
        .. ", volume=" .. tostring(db.volume)
        .. ", rate=" .. tostring(db.rate))
end

local function SetOnOff(field, value)
    if value == "on" or value == "1" or value == "true" then
        db[field] = true
    elseif value == "off" or value == "0" or value == "false" then
        db[field] = false
    else
        return false
    end

    RefreshTracking()
    return true
end

local function SetCheckboxText(check, label)
    local text = check.Text or (check:GetName() and _G[check:GetName() .. "Text"])
    if text then
        text:SetText(label)
    end
end

local function SetSliderText(slider, label)
    local text = slider.Text or _G[slider:GetName() .. "Text"]
    if text then
        text:SetText(label)
    end
end

local function SetSliderBounds(slider, low, high)
    local lowText = slider.Low or _G[slider:GetName() .. "Low"]
    local highText = slider.High or _G[slider:GetName() .. "High"]
    if lowText then
        lowText:SetText(tostring(low))
    end
    if highText then
        highText:SetText(tostring(high))
    end
end

local function RefreshOptions()
    if not optionsFrame or not optionControls or not db then
        return
    end

    refreshingOptions = true
    optionControls.enabled:SetChecked(db.enabled)
    optionControls.onlyInArena:SetChecked(db.onlyInArena)
    optionControls.enemies:SetChecked(db.enemies)
    optionControls.allies:SetChecked(db.allies)
    optionControls.tts:SetChecked(db.tts)
    optionControls.text:SetChecked(db.text)
    optionControls.offensive:SetChecked(db.types.offensive)
    optionControls.defensive:SetChecked(db.types.defensive)
    optionControls.external:SetChecked(db.types.external)
    optionControls.cc:SetChecked(db.types.cc)
    optionControls.volume:SetValue(db.volume or 100)
    optionControls.rate:SetValue(db.rate or 1)
    optionControls.output:SetText("Output: " .. tostring(db.output or "self"))
    refreshingOptions = false
end

local function CreateCheckbox(parent, name, label, x, y, onChange)
    local check = CreateFrame("CheckButton", addonName .. name, parent, "InterfaceOptionsCheckButtonTemplate")
    check:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    SetCheckboxText(check, label)
    check:SetScript("OnClick", function(self)
        if refreshingOptions then
            return
        end
        onChange(self:GetChecked() and true or false)
        RefreshTracking()
        RefreshOptions()
    end)
    return check
end

local function CreateSlider(parent, name, label, x, y, low, high, step, onChange)
    local slider = CreateFrame("Slider", addonName .. name, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    slider:SetMinMaxValues(low, high)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetWidth(240)
    SetSliderBounds(slider, low, high)
    SetSliderText(slider, label)
    slider:SetScript("OnValueChanged", function(_, value)
        if refreshingOptions then
            return
        end
        onChange(value)
        SetSliderText(slider, label .. ": " .. tostring(value))
    end)
    return slider
end

local function CycleOutput()
    local outputs = { "self", "say", "party", "raid", "yell" }
    local current = db.output or "self"
    local nextIndex = 1

    for index, output in ipairs(outputs) do
        if output == current then
            nextIndex = index + 1
            break
        end
    end

    if nextIndex > #outputs then
        nextIndex = 1
    end

    db.output = outputs[nextIndex]
    RefreshOptions()
end

local function CreateOptionsFrame()
    optionsFrame = CreateFrame("Frame", addonName .. "OptionsFrame", UIParent, "BasicFrameTemplateWithInset")
    optionsFrame:SetSize(430, 520)
    optionsFrame:SetPoint("CENTER")
    optionsFrame:SetMovable(true)
    optionsFrame:EnableMouse(true)
    optionsFrame:RegisterForDrag("LeftButton")
    optionsFrame:SetScript("OnDragStart", optionsFrame.StartMoving)
    optionsFrame:SetScript("OnDragStop", optionsFrame.StopMovingOrSizing)
    optionsFrame:Hide()

    local title = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 16, -12)
    title:SetText("PvP Callouts")

    local subtitle = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetText("Clean rebuild settings")

    optionControls = {}
    optionControls.enabled = CreateCheckbox(optionsFrame, "EnabledCheck", "Enable callouts", 24, -64, function(value)
        db.enabled = value
    end)
    optionControls.onlyInArena = CreateCheckbox(optionsFrame, "ArenaCheck", "Only run in arena", 24, -96, function(value)
        db.onlyInArena = value
    end)
    optionControls.enemies = CreateCheckbox(optionsFrame, "EnemiesCheck", "Enemy callouts", 24, -128, function(value)
        db.enemies = value
    end)
    optionControls.allies = CreateCheckbox(optionsFrame, "AlliesCheck", "Ally callouts", 24, -160, function(value)
        db.allies = value
    end)
    optionControls.tts = CreateCheckbox(optionsFrame, "TTSCheck", "Text-to-speech", 224, -64, function(value)
        db.tts = value
    end)
    optionControls.text = CreateCheckbox(optionsFrame, "TextCheck", "Text callouts", 224, -96, function(value)
        db.text = value
    end)

    local typeLabel = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    typeLabel:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 24, -206)
    typeLabel:SetText("Spell types")

    optionControls.offensive = CreateCheckbox(optionsFrame, "OffensiveCheck", "Offensive", 24, -230, function(value)
        db.types.offensive = value
    end)
    optionControls.defensive = CreateCheckbox(optionsFrame, "DefensiveCheck", "Defensive", 24, -262, function(value)
        db.types.defensive = value
    end)
    optionControls.external = CreateCheckbox(optionsFrame, "ExternalCheck", "External", 224, -230, function(value)
        db.types.external = value
    end)
    optionControls.cc = CreateCheckbox(optionsFrame, "CCCheck", "Crowd control", 224, -262, function(value)
        db.types.cc = value
    end)

    optionControls.volume = CreateSlider(optionsFrame, "VolumeSlider", "TTS volume", 38, -330, 0, 300, 5, function(value)
        db.volume = math.floor(value + 0.5)
        SetSliderText(optionControls.volume, "TTS volume: " .. tostring(db.volume))
    end)
    optionControls.rate = CreateSlider(optionsFrame, "RateSlider", "TTS speed", 38, -395, 0.5, 3, 0.1, function(value)
        db.rate = math.floor((value * 10) + 0.5) / 10
        SetSliderText(optionControls.rate, "TTS speed: " .. tostring(db.rate))
    end)

    optionControls.output = CreateFrame("Button", nil, optionsFrame, "UIPanelButtonTemplate")
    optionControls.output:SetSize(150, 24)
    optionControls.output:SetPoint("BOTTOMLEFT", optionsFrame, "BOTTOMLEFT", 24, 22)
    optionControls.output:SetScript("OnClick", CycleOutput)

    local test = CreateFrame("Button", nil, optionsFrame, "UIPanelButtonTemplate")
    test:SetSize(90, 24)
    test:SetPoint("LEFT", optionControls.output, "RIGHT", 12, 0)
    test:SetText("Test")
    test:SetScript("OnClick", function()
        TextCallout("PvPCallouts test")
        Speak("PvP Callouts test")
        Print("test sent")
    end)

    local close = CreateFrame("Button", nil, optionsFrame, "UIPanelButtonTemplate")
    close:SetSize(90, 24)
    close:SetPoint("LEFT", test, "RIGHT", 12, 0)
    close:SetText("Close")
    close:SetScript("OnClick", function()
        optionsFrame:Hide()
    end)
end

local function OpenOptions()
    if not optionsFrame then
        CreateOptionsFrame()
    end

    RefreshOptions()
    optionsFrame:Show()
end

local function Help()
    Print("/pvpc options")
    Print("/pvpc status")
    Print("/pvpc enable | disable")
    Print("/pvpc arena on | off")
    Print("/pvpc enemies on | off")
    Print("/pvpc allies on | off")
    Print("/pvpc volume 0-300")
    Print("/pvpc rate 0.5-3")
    Print("/pvpc tts on | off")
    Print("/pvpc text on | off")
    Print("/pvpc output self | say | party | raid | yell")
    Print("/pvpc type offensive|defensive|external|cc on|off")
    Print("/pvpc test")
end

local function SlashCommand(input)
    input = Trim(input)
    local command, rest = input:match("^(%S*)%s*(.-)$")
    command = string.lower(command or "")
    rest = Trim(rest)

    if command == "" or command == "options" or command == "config" or command == "menu" then
        OpenOptions()
    elseif command == "help" then
        Help()
    elseif command == "status" then
        Status()
    elseif command == "enable" then
        db.enabled = true
        RefreshTracking()
        Print("enabled")
    elseif command == "disable" then
        db.enabled = false
        RefreshTracking()
        Print("disabled")
    elseif command == "arena" then
        if SetOnOff("onlyInArena", rest) then
            Print("arena-only is " .. tostring(db.onlyInArena))
        else
            Print("usage: /pvpc arena on|off")
        end
    elseif command == "enemies" then
        if SetOnOff("enemies", rest) then
            Print("enemy callouts are " .. tostring(db.enemies))
        else
            Print("usage: /pvpc enemies on|off")
        end
    elseif command == "allies" then
        if SetOnOff("allies", rest) then
            Print("ally callouts are " .. tostring(db.allies))
        else
            Print("usage: /pvpc allies on|off")
        end
    elseif command == "tts" then
        if SetOnOff("tts", rest) then
            Print("TTS is " .. tostring(db.tts))
        else
            Print("usage: /pvpc tts on|off")
        end
    elseif command == "text" then
        if SetOnOff("text", rest) then
            Print("text callouts are " .. tostring(db.text))
        else
            Print("usage: /pvpc text on|off")
        end
    elseif command == "volume" then
        local value = tonumber(rest)
        if value and value >= 0 and value <= 300 then
            db.volume = value
            Print("TTS volume set to " .. value)
        else
            Print("usage: /pvpc volume 0-300")
        end
    elseif command == "rate" then
        local value = tonumber(rest)
        if value and value >= 0.5 and value <= 3 then
            db.rate = value
            Print("TTS rate set to " .. value)
        else
            Print("usage: /pvpc rate 0.5-3")
        end
    elseif command == "output" then
        rest = string.lower(rest)
        if rest == "self" or rest == "say" or rest == "party" or rest == "raid" or rest == "yell" then
            db.output = rest
            Print("text output set to " .. rest)
        else
            Print("usage: /pvpc output self|say|party|raid|yell")
        end
    elseif command == "type" then
        local spellType, value = rest:match("^(%S+)%s+(%S+)$")
        if spellType and db.types[spellType] ~= nil and (value == "on" or value == "off") then
            db.types[spellType] = value == "on"
            Print(spellType .. " callouts are " .. tostring(db.types[spellType]))
        else
            Print("usage: /pvpc type offensive|defensive|external|cc on|off")
        end
    elseif command == "test" then
        TextCallout("PvPCallouts test")
        Speak("PvP Callouts test")
        Print("test sent")
    else
        Help()
    end
end

local function Initialize()
    PvPCalloutsDB = PvPCalloutsDB or {}
    db = PvPCalloutsDB
    local previousVersion = db.version
    CopyDefaults(DEFAULTS, db)
    if previousVersion ~= DEFAULTS.version then
        db.text = true
        db.version = DEFAULTS.version
    end

    spellDB = addon.SpellDB
    if spellDB and spellDB.BuildLookupTable then
        spellDB:BuildLookupTable()
    end

    SLASH_PVPCALLOUTSCLEAN1 = "/pvpc"
    SLASH_PVPCALLOUTSCLEAN2 = "/pvpcallouts"
    SLASH_PVPCALLOUTSCLEAN3 = "/pvpco"
    SlashCmdList.PVPCALLOUTSCLEAN = SlashCommand

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    frame:RegisterEvent("ARENA_OPPONENT_UPDATE")

    RefreshTracking()
    Print("clean rebuild loaded. Type /pvpc help.")
end

frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            Initialize()
        end
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        RefreshTracking()
    elseif event == "ARENA_OPPONENT_UPDATE" then
        RefreshTrackedGUIDs()
        ScanAll(true)
    elseif event == "UNIT_AURA" then
        ScanAll(false)
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        HandleCombatLog()
    end
end)
