---@type string, table
local addonName, addon = ...

-- PvP Callouts Aura Tracker
-- Monitors unit auras for important PvP abilities
-- Original implementation for PvP Callouts addon

local AURA_SCAN_LIMIT = 40

---@class PvPAuraTracker
local AuraTracker = {}
addon.UnitAuraWatcher = AuraTracker

-- Execute all registered callbacks for a watcher
local function TriggerCallbacks(watcher)
	local callbackList = watcher.data.callbacks
	if not callbackList or #callbackList == 0 then
		return
	end
	
	for i = 1, #callbackList do
		callbackList[i](watcher)
	end
end

-- Event handler for watcher frames
local function HandleFrameEvent(frame, event, ...)
	local watcher = frame.watcherInstance
	if watcher then
		watcher:ProcessEvent(event, ...)
	end
end

-- Watcher object methods
local WatcherMethods = {}
WatcherMethods.__index = WatcherMethods

function WatcherMethods:GetUnit()
	return self.data.unitID
end

function WatcherMethods:RegisterCallback(callbackFunc)
	if callbackFunc then
		table.insert(self.data.callbacks, callbackFunc)
	end
end

function WatcherMethods:IsEnabled()
	return self.data.active
end

function WatcherMethods:Enable()
	if self.data.active then return end
	
	if not self.eventFrame then return end
	
	self.data.active = true
end

function WatcherMethods:Disable()
	if not self.data.active then return end
	
	self.data.active = false
end

function WatcherMethods:ClearState(shouldNotify)
	self.data.ccAuras = {}
	self.data.importantAuras = {}
	self.data.defensiveAuras = {}
	
	if shouldNotify then
		TriggerCallbacks(self)
	end
end

function WatcherMethods:ForceFullUpdate()
	self:ProcessEvent("UNIT_AURA", self.data.unitID, { isFullUpdate = true })
end

function WatcherMethods:Dispose()
	if self.eventFrame then
		self.eventFrame.watcherInstance = nil
	end
	self.eventFrame = nil
	self.data.callbacks = {}
	self:ClearState(false)
end

function WatcherMethods:GetCcState()
	return self.data.ccAuras
end

function WatcherMethods:GetImportantState()
	return self.data.importantAuras
end

function WatcherMethods:GetDefensiveState()
	return self.data.defensiveAuras
end

-- Scan auras on a unit with a basic Blizzard filter. Avoid classified filters
-- such as BIG_DEFENSIVE/IMPORTANT because Retail can expose restricted aura
-- tables through those paths and cause taint hard-errors.
local function ScanUnitAuras(unitID, filterString, processingFunc)
	for index = 1, AURA_SCAN_LIMIT do
		local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unitID, index, filterString)
		if not ok then break end
		if not aura then break end

		pcall(processingFunc, aura)
	end
end

local function SafeField(tableValue, fieldName)
	if type(tableValue) ~= "table" then
		return nil
	end

	local ok, value = pcall(function()
		return tableValue[fieldName]
	end)
	if ok then
		return value
	end

	return nil
end

local function SafeNumber(value, fallback)
	local isSecret = false
	if issecretvalue then
		local okSecret, secretValue = pcall(issecretvalue, value)
		isSecret = okSecret and secretValue
	end

	if value == nil or isSecret then
		return fallback
	end

	local ok, numericValue = pcall(tonumber, value)
	if ok and numericValue then
		return numericValue
	end

	return fallback
end

local function BuildAuraInfo(unitID, aura, spellInfo)
	local duration = SafeNumber(SafeField(aura, "duration"), 0)
	local expirationTime = SafeNumber(SafeField(aura, "expirationTime"), 0)
	local startTime = 0
	if duration > 0 and expirationTime > 0 then
		startTime = expirationTime - duration
	end

	return {
		SpellId = spellInfo.id,
		SpellName = spellInfo.name,
		SpellIcon = nil,
		StartTime = startTime,
		TotalDuration = duration,
		DispelColor = nil,
		AuraInstanceID = SafeNumber(SafeField(aura, "auraInstanceID"), nil) or (unitID .. ":" .. spellInfo.id),
	}
end

function WatcherMethods:RebuildStates()
	local unitID = self.data.unitID
	if not unitID then return end
	if UnitExists and not UnitExists(unitID) then
		self.data.ccAuras = {}
		self.data.importantAuras = {}
		self.data.defensiveAuras = {}
		return
	end

	local filters = self.data.auraFilters
	local trackDefensives = not filters or filters.Defensive
	local trackCC = not filters or filters.CC
	local trackImportant = not filters or filters.Important

	local ccList = {}
	local importantList = {}
	local defensiveList = {}
	local processedAuras = {}

	local function ProcessKnownAura(aura)
		local spellID = SafeNumber(SafeField(aura, "spellId"), nil)
		if not spellID then
			return
		end

		local okSpell, spellInfo = pcall(function()
			return addon.SpellDB and addon.SpellDB:GetSpellByID(spellID)
		end)
		if not okSpell then
			spellInfo = nil
		end
		if not spellInfo then
			return
		end

		local auraKey = SafeNumber(SafeField(aura, "auraInstanceID"), nil) or (unitID .. ":" .. spellInfo.id)
		if processedAuras[auraKey] then
			return
		end

		if spellInfo.type == "offensive" and trackImportant then
			local info = BuildAuraInfo(unitID, aura, spellInfo)
			info.IsImportant = true
			table.insert(importantList, info)
			processedAuras[auraKey] = true
		elseif (spellInfo.type == "defensive" or spellInfo.type == "external") and trackDefensives then
			local info = BuildAuraInfo(unitID, aura, spellInfo)
			info.IsDefensive = true
			table.insert(defensiveList, info)
			processedAuras[auraKey] = true
		elseif spellInfo.type == "cc" and trackCC then
			local info = BuildAuraInfo(unitID, aura, spellInfo)
			info.IsCC = true
			table.insert(ccList, info)
			processedAuras[auraKey] = true
		end
	end

	ScanUnitAuras(unitID, "HELPFUL", ProcessKnownAura)
	ScanUnitAuras(unitID, "HARMFUL", ProcessKnownAura)

	-- Update stored state
	self.data.ccAuras = ccList
	self.data.importantAuras = importantList
	self.data.defensiveAuras = defensiveList
end

function WatcherMethods:ProcessEvent(event, ...)
	if not self.data.active then
		return
	end

	if event == "UNIT_AURA" then
		local unitID = ...
		if unitID and unitID ~= self.data.unitID then
			return
		end
	elseif event == "ARENA_OPPONENT_UPDATE" then
		local unitID = ...
		if unitID ~= self.data.unitID then
			return
		end
	end

	if not self.data.unitID then
		return
	end

	self:RebuildStates()
	TriggerCallbacks(self)
end

-- Create a new aura watcher for a unit
function AuraTracker:New(unitID, extraEvents, auraFilters, startDisabled)
	if not unitID then
		error("PvPAuraTracker requires a valid unit ID")
	end

	local watcher = setmetatable({
		eventFrame = nil,
		data = {
			unitID = unitID,
			extraEvents = extraEvents,
			active = false,
			callbacks = {},
			ccAuras = {},
			importantAuras = {},
			defensiveAuras = {},
			auraFilters = auraFilters,
		},
	}, WatcherMethods)

	-- Create event handling frame
	local frame = CreateFrame("Frame")
	frame.watcherInstance = watcher
	frame:RegisterEvent("UNIT_AURA")
	if extraEvents then
		for _, eventName in ipairs(extraEvents) do
			frame:RegisterEvent(eventName)
		end
	end
	frame:SetScript("OnEvent", HandleFrameEvent)

	watcher.eventFrame = frame
	if not startDisabled then
		watcher:Enable()
		watcher:ForceFullUpdate()
	end

	return watcher
end

---@class AuraTypeFilter
---@field CC boolean?
---@field Important boolean?
---@field Defensive boolean?

---@class AuraInfo
---@field IsImportant? boolean
---@field IsCC? boolean
---@field IsDefensive? boolean
---@field SpellId number?
---@field SpellIcon string?
---@field SpellName string?
---@field TotalDuration number?
---@field StartTime number?
---@field DispelColor table?
---@field AuraInstanceID number?

---@class WatcherState
---@field Unit string
---@field Events string[]?
---@field Enabled boolean
---@field Callbacks (fun(self: Watcher))[]
---@field CcAuraState AuraInfo[]
---@field ImportantAuraState AuraInfo[]
---@field DefensiveState AuraInfo[]
---@field InterestedIn AuraTypeFilter

---@class Watcher
---@field Frame table?
---@field State WatcherState
---@field GetCcState fun(self: Watcher): AuraInfo[]
---@field GetImportantState fun(self: Watcher): AuraInfo[]
---@field GetDefensiveState fun(self: Watcher): AuraInfo[]
---@field RegisterCallback fun(self: Watcher, callback: fun(self: Watcher))
---@field GetUnit fun(self: Watcher): string
---@field IsEnabled fun(self: Watcher): boolean
---@field Enable fun(self: Watcher)
---@field Disable fun(self: Watcher)
---@field ClearState fun(self: Watcher, notify: boolean?)
---@field ForceFullUpdate fun(self: Watcher)
---@field Dispose fun(self: Watcher)
