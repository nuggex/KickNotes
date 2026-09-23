local ADDON_NAME, KN = ...

KN.name = ADDON_NAME
KN.version = "0.3.0"
KN.content = KN.content or {}
KN.contentByName = KN.contentByName or {}
KN.currentContent = nil
KN.currentEncounter = nil
KN.initialized = false

local DEFAULTS = {
    enabled = true,
    showOnEnter = true,
    showOnEncounterStart = true,
    showDungeons = true,
    showRaids = true,
    enableOlderContent = false,
    showInterrupts = true,
    showStops = true,
    showDispels = true,
    showPurges = true,
    showWatch = true,
    hideUnavailable = false,
    highlightBosses = true,
    bossColor = { r = 1.00, g = 0.76, b = 0.24 },
    highlightMustStop = true,
    mustStopColor = { r = 1.00, g = 0.22, b = 0.14 },
    minimumPriority = 2, -- 3 = Essential, 2 = Essential + Important, 1 = Everything
    autoZipSeconds = 0,
    startZipped = false,
    scale = 1.0,
    compact = false,
    locked = false,
    fullOpacity = 0.88,
    miniOpacity = 0.82,
    fullFontSize = 13,
    miniFontSize = 12,
    fullWidth = 470,
    miniWidth = 300,
    fullRowGap = 6,
    miniRowGap = 1,
    maxWindowHeight = 620,
    previewRecordID = "midnight-s2-altar-of-fangs",
    contentEnabled = {},
    learningEnabled = true,
    learnedMode = "dim", -- dim, hide, show
    learnedOpacity = 0.38,
    learnedMechanics = {},
}

local CHAR_DEFAULTS = {
    mini = false,
    zipped = false,
    point = {
        point = "CENTER",
        relativePoint = "CENTER",
        x = 380,
        y = 80,
    },
}

local ACTION_SETTING = {
    interrupt = "showInterrupts",
    stop = "showStops",
    dispel = "showDispels",
    purge = "showPurges",
    watch = "showWatch",
}

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, child in pairs(value) do
        copy[key] = deepCopy(child)
    end
    return copy
end

local function mergeDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if target[key] == nil then
            target[key] = deepCopy(value)
        elseif type(value) == "table" and type(target[key]) == "table" then
            mergeDefaults(target[key], value)
        end
    end
end

local function migrateLegacySettings(accountDB, charDB)
    -- 0.1.x stored window-mode and position globally. Preserve the user's
    -- existing setup on the first 0.2.x load, then keep those bits per character.
    if accountDB.fullOpacity == nil and accountDB.opacity ~= nil then
        accountDB.fullOpacity = accountDB.opacity
    end
    if accountDB.miniOpacity == nil and accountDB.opacity ~= nil then
        accountDB.miniOpacity = accountDB.opacity
    end
    if accountDB.fullFontSize == nil and accountDB.fontSize ~= nil then
        accountDB.fullFontSize = accountDB.fontSize
    end
    if accountDB.miniFontSize == nil and accountDB.fontSize ~= nil then
        accountDB.miniFontSize = math.max(10, accountDB.fontSize - 1)
    end
    if accountDB.fullWidth == nil and accountDB.width ~= nil then
        accountDB.fullWidth = accountDB.width
    end
    if charDB.mini == nil and accountDB.mini ~= nil then
        charDB.mini = accountDB.mini and true or false
    end
    if charDB.zipped == nil and accountDB.zipped ~= nil then
        charDB.zipped = accountDB.zipped and true or false
    end
    if charDB.point == nil and type(accountDB.point) == "table" then
        charDB.point = deepCopy(accountDB.point)
    end
end

local function normalizeName(value)
    if not value then
        return nil
    end

    value = tostring(value):lower()
    value = value:gsub("[’‘]", "'")
    value = value:gsub("%s+", " ")
    value = value:gsub("^%s+", "")
    value = value:gsub("%s+$", "")
    return value
end

KN.NormalizeName = normalizeName

local function mechanicSlug(value)
    value = normalizeName(value or "mechanic") or "mechanic"
    value = value:gsub("[^%w]+", "-")
    value = value:gsub("^-+", "")
    value = value:gsub("-+$", "")
    return value ~= "" and value or "mechanic"
end

local function assignEntryIDs(record)
    local function assignList(entries, scope)
        local seen = {}
        for index, entry in ipairs(entries or {}) do
            if not entry._knID then
                local parts = {
                    entry.action or "watch",
                    entry.spell or entry.title or "mechanic",
                    entry.mob or "",
                    entry.where or "",
                }
                local base = record.id .. ":" .. scope .. ":" .. mechanicSlug(table.concat(parts, "-"))
                local count = (seen[base] or 0) + 1
                seen[base] = count
                entry._knID = count > 1 and (base .. "-" .. count) or base
            end
            entry._knIndex = index
        end
    end

    assignList(record.entries, "main")
    for encounterKey, entries in pairs(record.encounters or {}) do
        assignList(entries, "encounter-" .. mechanicSlug(encounterKey))
    end
end

function KN:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff78bfffKickNotes:|r " .. tostring(message))
end

function KN:RegisterContent(record)
    assert(type(record) == "table", "KickNotes content must be a table")
    assert(record.id, "KickNotes content record requires id")
    assert(record.name, "KickNotes content record requires name")
    assert(record.type == "dungeon" or record.type == "raid", "KickNotes content type must be dungeon or raid")

    assignEntryIDs(record)

    self.content[record.id] = record
    self.contentByName[normalizeName(record.name)] = record

    if record.aliases then
        for _, alias in ipairs(record.aliases) do
            self.contentByName[normalizeName(alias)] = record
        end
    end
end

function KN:IsContentEnabled(record)
    if not record then
        return false
    end

    if record.currentSeason == false and not self.db.enableOlderContent then
        return false
    end

    local explicit = self.db.contentEnabled[record.id]
    if explicit ~= nil then
        return explicit
    end

    return record.currentSeason ~= false
end

function KN:SetContentEnabled(id, enabled)
    self.db.contentEnabled[id] = enabled and true or false
end

function KN:FindContentByName(name, contentType)
    local normalized = normalizeName(name)
    if not normalized then
        return nil
    end

    local direct = self.contentByName[normalized]
    if direct and (not contentType or direct.type == contentType) then
        return direct
    end

    for _, record in pairs(self.content) do
        if (not contentType or record.type == contentType) and record.matchNames then
            for _, matchName in ipairs(record.matchNames) do
                if normalizeName(matchName) == normalized then
                    return record
                end
            end
        end
    end

    return nil
end

function KN:GetCurrentSeasonRecords(contentType)
    local records = {}

    for _, record in pairs(self.content) do
        if record.currentSeason and (not contentType or record.type == contentType) then
            records[#records + 1] = record
        end
    end

    table.sort(records, function(a, b)
        return normalizeName(a.name) < normalizeName(b.name)
    end)

    return records
end

function KN:FindContentByQuery(query)
    local normalized = normalizeName(query)
    if not normalized or normalized == "" then
        return nil, {}
    end

    local exact = self:FindContentByName(normalized)
    if exact and exact.currentSeason then
        return exact, { exact }
    end

    local matches = {}
    local seen = {}
    for _, record in ipairs(self:GetCurrentSeasonRecords()) do
        local candidates = { record.name, record.id }
        for _, alias in ipairs(record.aliases or {}) do
            candidates[#candidates + 1] = alias
        end

        for _, candidate in ipairs(candidates) do
            local candidateName = normalizeName(candidate)
            if candidateName and candidateName:find(normalized, 1, true) then
                if not seen[record.id] then
                    matches[#matches + 1] = record
                    seen[record.id] = true
                end
                break
            end
        end
    end

    if #matches == 1 then
        return matches[1], matches
    end
    return nil, matches
end

function KN:PrintTestTargets()
    self:Print("Current-season test targets:")

    local dungeons = self:GetCurrentSeasonRecords("dungeon")
    if #dungeons > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffd100Dungeons:|r")
        for _, record in ipairs(dungeons) do
            DEFAULT_CHAT_FRAME:AddMessage("    " .. record.name)
        end
    end

    local raids = self:GetCurrentSeasonRecords("raid")
    if #raids > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffd100Raids:|r")
        for _, record in ipairs(raids) do
            DEFAULT_CHAT_FRAME:AddMessage("    " .. record.name)
        end
    end
end

function KN:ShowTestRecord(record)
    if not record then
        return
    end

    if self.charDb then
        self.charDb.zipped = false
    end
    if self.db then
        self.db.previewRecordID = record.id
    end
    self:ShowContent(record, "preview")
    self:Print("Testing " .. record.name .. " as your current " .. self:GetPlayerSpecLabel() .. ".")
end

function KN:CycleTestRecord(direction)
    local records = self:GetCurrentSeasonRecords("dungeon")
    if #records == 0 then
        self:Print("No current-season dungeons are registered.")
        return
    end

    local currentIndex = nil
    if self.currentContent then
        for index, record in ipairs(records) do
            if record.id == self.currentContent.id then
                currentIndex = index
                break
            end
        end
    end

    if not currentIndex then
        currentIndex = direction < 0 and 1 or 0
    end

    local nextIndex = ((currentIndex - 1 + direction) % #records) + 1
    self:ShowTestRecord(records[nextIndex])
end

function KN:IsMiniMode()
    return self.charDb and self.charDb.mini and true or false
end

function KN:IsZipped()
    return self.charDb and self.charDb.zipped and true or false
end

function KN:GetWindowPoint()
    return (self.charDb and self.charDb.point) or CHAR_DEFAULTS.point
end

function KN:GetPreviewRecords()
    local records = self:GetCurrentSeasonRecords()
    return records
end

function KN:GetPreviewRecord()
    local id = self.db and self.db.previewRecordID
    local record = id and self.content[id]
    if record and record.currentSeason then
        return record
    end
    local records = self:GetPreviewRecords()
    return records[1]
end

function KN:ScheduleAutoZip(record, reason)
    self.autoZipGeneration = (self.autoZipGeneration or 0) + 1
    local generation = self.autoZipGeneration
    local seconds = tonumber(self.db.autoZipSeconds) or 0

    if reason ~= "enter" or seconds <= 0 or self.db.startZipped or self:IsZipped() then
        return
    end

    C_Timer.After(seconds, function()
        if not KN.initialized or generation ~= KN.autoZipGeneration then
            return
        end
        if KN.currentContent and record and KN.currentContent.id == record.id and KN.frame and KN.frame:IsShown() and not KN:IsZipped() then
            KN:SetZipped(true)
        end
    end)
end

function KN:GetActiveChallengeDungeonName()
    if not C_ChallengeMode or not C_ChallengeMode.GetActiveChallengeMapID then
        return nil
    end

    local ok, mapID = pcall(C_ChallengeMode.GetActiveChallengeMapID)
    if not ok or not mapID or mapID <= 0 then
        return nil
    end

    if C_ChallengeMode.GetMapUIInfo then
        local success, name = pcall(C_ChallengeMode.GetMapUIInfo, mapID)
        if success and name and name ~= "" then
            return name
        end
    end

    return nil
end

function KN:GetCurrentContext()
    local instanceName, instanceType = GetInstanceInfo()

    if instanceType == "party" then
        local challengeName = self:GetActiveChallengeDungeonName()
        local record = self:FindContentByName(challengeName or instanceName, "dungeon")
        return record, challengeName or instanceName, instanceType
    end

    if instanceType == "raid" then
        local record = self:FindContentByName(instanceName, "raid")
        return record, instanceName, instanceType
    end

    return nil, instanceName, instanceType
end

function KN:GetEntryID(entry)
    return entry and (entry.id or entry._knID) or nil
end

function KN:IsEntryLearned(entry)
    if not self.db or not self.db.learningEnabled then
        return false
    end
    local id = self:GetEntryID(entry)
    return id and self.db.learnedMechanics and self.db.learnedMechanics[id] and true or false
end

function KN:SetEntryLearned(entry, learned, silent)
    if not self.db or not entry then
        return
    end

    self.db.learnedMechanics = self.db.learnedMechanics or {}
    local id = self:GetEntryID(entry)
    if not id then
        return
    end

    if learned then
        self.db.learnedMechanics[id] = true
    else
        self.db.learnedMechanics[id] = nil
    end

    if not silent then
        local name = entry.spell or entry.title or "Mechanic"
        self:Print(name .. (learned and " marked as learned." or " marked as learning again."))
    end

    if self.frame and self.frame:IsShown() and self.currentContent and self.RefreshDisplay then
        self:RefreshDisplay(self.currentContent, self.currentEncounter, "learning")
    end
end

function KN:ToggleEntryLearned(entry)
    self:SetEntryLearned(entry, not self:IsEntryLearned(entry))
end

function KN:ResetLearnedMechanics(record)
    if not self.db then
        return 0
    end
    self.db.learnedMechanics = self.db.learnedMechanics or {}

    local removed = 0
    if not record then
        for _ in pairs(self.db.learnedMechanics) do
            removed = removed + 1
        end
        wipe(self.db.learnedMechanics)
    else
        local prefix = record.id .. ":"
        for id in pairs(self.db.learnedMechanics) do
            if id:sub(1, #prefix) == prefix then
                self.db.learnedMechanics[id] = nil
                removed = removed + 1
            end
        end
    end

    if self.frame and self.frame:IsShown() and self.currentContent and self.RefreshDisplay then
        self:RefreshDisplay(self.currentContent, self.currentEncounter, "learning-reset")
    end
    return removed
end

function KN:GetLearnedCount(record)
    local count = 0
    local prefix = record and (record.id .. ":") or nil
    for id, learned in pairs((self.db and self.db.learnedMechanics) or {}) do
        if learned and (not prefix or id:sub(1, #prefix) == prefix) then
            count = count + 1
        end
    end
    return count
end

function KN:GetPlayerSpecLabel()
    local _, className = UnitClass("player")
    local specName

    local specIndex = GetSpecialization and GetSpecialization()
    if specIndex and GetSpecializationInfo then
        local _, name = GetSpecializationInfo(specIndex)
        specName = name
    end

    if specName and className then
        return specName .. " " .. className
    end
    return className or "Unknown class"
end

function KN:IsEntryEligible(entry)
    local setting = ACTION_SETTING[entry.action]
    if setting and not self.db[setting] then
        return false
    end

    if (entry.priority or 2) < (self.db.minimumPriority or 2) then
        return false
    end

    if self.db.hideUnavailable and self.GetToolForEntry then
        local _, available = self:GetToolForEntry(entry)
        if available == false then
            return false
        end
    end

    return true
end

function KN:IsEntryVisible(entry)
    if not self:IsEntryEligible(entry) then
        return false
    end

    if self.db.learningEnabled and self.db.learnedMode == "hide" and self:IsEntryLearned(entry) then
        return false
    end

    return true
end

function KN:GetLearningStats(record, encounterName)
    if not record then
        return 0, 0, 0
    end

    local source
    if encounterName and record.encounters then
        source = record.encounters[normalizeName(encounterName)]
    end
    if not source then
        source = record.entries
    end

    local learned, remaining, total = 0, 0, 0
    for _, entry in ipairs(source or {}) do
        if self:IsEntryEligible(entry) then
            total = total + 1
            if self:IsEntryLearned(entry) then
                learned = learned + 1
            else
                remaining = remaining + 1
            end
        end
    end
    return learned, remaining, total
end

function KN:GetVisibleEntries(record, encounterName)
    if not record then
        return {}
    end

    local source
    if encounterName and record.encounters then
        source = record.encounters[normalizeName(encounterName)]
    end

    if not source then
        source = record.entries
    end

    local visible = {}
    for _, entry in ipairs(source or {}) do
        if self:IsEntryVisible(entry) then
            visible[#visible + 1] = entry
        end
    end

    table.sort(visible, function(a, b)
        local pa = a.priority or 2
        local pb = b.priority or 2
        if pa ~= pb then
            return pa > pb
        end
        return (a.spell or a.title or "") < (b.spell or b.title or "")
    end)

    return visible
end

function KN:ShowContent(record, reason, encounterName)
    if not self.db.enabled or not record or not self:IsContentEnabled(record) then
        return
    end

    if record.type == "dungeon" and not self.db.showDungeons then
        return
    end
    if record.type == "raid" and not self.db.showRaids then
        return
    end

    self.currentContent = record
    self.currentEncounter = encounterName

    if self.RefreshDisplay then
        self:RefreshDisplay(record, encounterName, reason)
    end

    self:ScheduleAutoZip(record, reason)
end

function KN:RefreshContext(forceShow)
    if not self.initialized then
        return
    end
    if not self.db.enabled then
        self.autoZipGeneration = (self.autoZipGeneration or 0) + 1
        if self.frame and self.frame:IsShown() then
            self.frame:Hide()
        end
        return
    end

    local record = self:GetCurrentContext()
    if not record or not self:IsContentEnabled(record) then
        self.currentContent = nil
        self.currentEncounter = nil
        self.autoZipGeneration = (self.autoZipGeneration or 0) + 1
        if self.frame and self.frame:IsShown() then
            self.frame:Hide()
        end
        return
    end

    local changed = not self.currentContent or self.currentContent.id ~= record.id
    self.currentContent = record
    self.currentEncounter = nil

    if changed and self.charDb then
        -- A new dungeon/raid gets a fresh presentation state. Manual zipping
        -- remains sticky only while you are inside that same instance.
        self.charDb.zipped = self.db.startZipped and true or false
    end

    if forceShow or (changed and self.db.showOnEnter) then
        self:ShowContent(record, changed and "enter" or "refresh")
    end
end

function KN:OpenSettings()
    if Settings and Settings.OpenToCategory and self.settingsCategory then
        Settings.OpenToCategory(self.settingsCategory:GetID())
        return
    end

    self:Print("Settings panel is registered under Options > AddOns > KickNotes.")
end

function KN:ResetPosition()
    if self.charDb then
        self.charDb.point = deepCopy(CHAR_DEFAULTS.point)
    end
    if self.ApplyFrameSettings then
        self:ApplyFrameSettings(true)
    end
end

function KN:PrintCommands()
    self:Print("Commands:")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/kn show|r - Show the current reminder window")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/kn hide|r - Hide the reminder window")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/kn toggle|r - Toggle the reminder window")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/kn zip|r - Collapse the window to a small KN button")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/kn unzip|r - Restore a zipped window")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/kn mini|r - Toggle Mini mode")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/kn full|r - Turn Mini mode off")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/kn options|r - Open addon settings")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/kn test <name>|r - Preview a dungeon or raid using your current character")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/kn test next|r - Preview the next dungeon alphabetically")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/kn test prev|r - Preview the previous dungeon alphabetically")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/kn test list|r - List available current-season test targets")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/kn learning|r - Show learning status")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/kn learning dim|hide|show|r - Set learned-row behavior")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/kn reset|r - Reset the reminder window position")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/kn help|r - Show this command list")
end

function KN:HandleSlash(message)
    local commandLine = normalizeName(message or "") or ""
    local command, args = commandLine:match("^(%S+)%s*(.-)%s*$")
    command = command or ""
    args = args or ""

    if command == "" or command == "help" or command == "?" then
        self:PrintCommands()
        return
    end

    if command == "show" then
        local record = self.currentContent or select(1, self:GetCurrentContext())
        if record then
            self:ShowContent(record, "slash", self.currentEncounter)
        else
            local records = self:GetCurrentSeasonRecords("dungeon")
            if #records > 0 then
                self:ShowContent(records[1], "preview")
            end
        end
        return
    end

    if command == "hide" then
        if self.frame then
            self.frame:Hide()
        end
        return
    end

    if command == "toggle" then
        if self.frame and self.frame:IsShown() then
            self.frame:Hide()
        else
            self:HandleSlash("show")
        end
        return
    end

    if command == "zip" then
        if self.SetZipped then
            self:SetZipped(true)
        end
        return
    end

    if command == "unzip" then
        if self.SetZipped then
            self:SetZipped(false)
        end
        return
    end

    if command == "mini" then
        if self.ToggleMiniMode then
            self:ToggleMiniMode()
        end
        self:Print("Mini mode " .. (self:IsMiniMode() and "enabled." or "disabled."))
        return
    end

    if command == "full" then
        if self.SetMiniMode then
            self:SetMiniMode(false)
        end
        self:Print("Full reminder view enabled.")
        return
    end

    if command == "config" or command == "options" or command == "settings" then
        self:OpenSettings()
        return
    end

    if command == "learning" or command == "learned" then
        local mode = normalizeName(args) or ""
        if mode == "dim" or mode == "hide" or mode == "show" then
            self.db.learnedMode = mode
            self.db.learningEnabled = true
            self:Print("Learned mechanics mode: " .. mode .. ".")
            if self.frame and self.frame:IsShown() and self.currentContent then
                self:RefreshDisplay(self.currentContent, self.currentEncounter, "learning-mode")
            end
        elseif mode == "on" then
            self.db.learningEnabled = true
            self:Print("Learning enabled.")
        elseif mode == "off" then
            self.db.learningEnabled = false
            self:Print("Learning disabled.")
            if self.frame and self.frame:IsShown() and self.currentContent then
                self:RefreshDisplay(self.currentContent, self.currentEncounter, "learning-mode")
            end
        else
            self:Print("Learning is " .. (self.db.learningEnabled and "enabled" or "disabled") .. "; learned rows: " .. tostring(self.db.learnedMode or "dim") .. "; learned mechanics: " .. tostring(self:GetLearnedCount()) .. ".")
            DEFAULT_CHAT_FRAME:AddMessage("  |cffffffffRight-click any mechanic row|r to mark it learned or learning again.")
        end
        return
    end

    if command == "reset" then
        self:ResetPosition()
        self:Print("Window position reset.")
        return
    end

    if command == "test" then
        if args == "" then
            local records = self:GetCurrentSeasonRecords("dungeon")
            if #records > 0 then
                self:ShowTestRecord(records[1])
                self:Print("Use /kn test <name>, /kn test next, /kn test prev or /kn test list.")
            end
            return
        end

        if args == "list" then
            self:PrintTestTargets()
            return
        end

        if args == "next" then
            self:CycleTestRecord(1)
            return
        end

        if args == "prev" or args == "previous" then
            self:CycleTestRecord(-1)
            return
        end

        local record, matches = self:FindContentByQuery(args)
        if record then
            self:ShowTestRecord(record)
            return
        end

        if #matches > 1 then
            self:Print("That test name matches more than one entry:")
            for _, match in ipairs(matches) do
                DEFAULT_CHAT_FRAME:AddMessage("  " .. match.name)
            end
            return
        end

        self:Print("No current-season dungeon or raid matched '" .. args .. "'.")
        self:Print("Use /kn test list to see available names.")
        return
    end

    self:Print("Unknown command: " .. command)
    self:PrintCommands()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("CHALLENGE_MODE_START")
eventFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
eventFrame:RegisterEvent("ENCOUNTER_START")
eventFrame:RegisterEvent("ENCOUNTER_END")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon ~= ADDON_NAME then
            return
        end

        KickNotesDB = KickNotesDB or {}
        KickNotesCharDB = KickNotesCharDB or {}
        migrateLegacySettings(KickNotesDB, KickNotesCharDB)
        mergeDefaults(KickNotesDB, DEFAULTS)
        mergeDefaults(KickNotesCharDB, CHAR_DEFAULTS)
        KN.db = KickNotesDB
        KN.charDb = KickNotesCharDB
        KN.initialized = true

        if KN.CreateMainFrame then
            KN:CreateMainFrame()
        end
        if KN.RegisterSettings then
            KN:RegisterSettings()
        end

        SLASH_KICKNOTES1 = "/kicknotes"
        SLASH_KICKNOTES2 = "/kn"
        SlashCmdList.KICKNOTES = function(msg)
            KN:HandleSlash(msg)
        end

        C_Timer.After(1, function()
            KN:RefreshContext(false)
        end)
        return
    end

    if not KN.initialized then
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(0.8, function()
            KN:RefreshContext(false)
        end)
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        -- PLAYER_ENTERING_WORLD normally covers instance transitions, but this
        -- catches portal/area transitions where the world event can be delayed.
        C_Timer.After(0.3, function()
            KN:RefreshContext(false)
        end)
    elseif event == "CHALLENGE_MODE_START" then
        C_Timer.After(0.5, function()
            KN:RefreshContext(true)
        end)
    elseif event == "CHALLENGE_MODE_COMPLETED" then
        KN.currentEncounter = nil
    elseif event == "ENCOUNTER_START" then
        local _, encounterName = ...
        local record = KN.currentContent or select(1, KN:GetCurrentContext())
        if record and record.type == "raid" and KN.db.showOnEncounterStart then
            local key = normalizeName(encounterName)
            if record.encounters and record.encounters[key] then
                KN:ShowContent(record, "encounter", encounterName)
            end
        end
    elseif event == "ENCOUNTER_END" then
        KN.currentEncounter = nil
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        if KN.frame and KN.frame:IsShown() and KN.currentContent then
            KN:ShowContent(KN.currentContent, "spec-change", KN.currentEncounter)
        end
    end
end)
