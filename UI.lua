local ADDON_NAME, KN = ...

local ZIPPED_WIDTH = 46
local ZIPPED_HEIGHT = 30

local ACTION_STYLE = {
    interrupt = { label = "KICK",   r = 0.93, g = 0.25, b = 0.25 },
    stop      = { label = "STOP",   r = 0.95, g = 0.58, b = 0.18 },
    dispel    = { label = "DISPEL", r = 0.30, g = 0.72, b = 1.00 },
    purge     = { label = "PURGE",  r = 0.68, g = 0.42, b = 1.00 },
    watch     = { label = "WATCH",  r = 0.25, g = 0.80, b = 0.58 },
}

local PRIORITY_LABEL = {
    [3] = "Essential",
    [2] = "Important",
    [1] = "Optional",
}

local function setFont(fontString, size, flags)
    local font = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    fontString:SetFont(font, size, flags or "")
end

local function setTextColor(fontString, r, g, b, a)
    fontString:SetTextColor(r, g, b, a or 1)
end

local function getEntryLocationKind(entry, record)
    if record and record.type == "raid" then
        return "boss"
    end

    local where = entry and entry.where
    if not where or where == "" then
        return nil
    end

    local hasBoss = where:find("B%d") ~= nil
    local hasTrash = where:find("T%d") ~= nil

    if hasBoss and hasTrash then
        return "mixed"
    elseif hasBoss then
        return "boss"
    elseif hasTrash then
        return "trash"
    end

    return nil
end

local function getLocationLabel(entry, record)
    if record and record.type == "raid" then
        return "Boss encounter"
    end

    local where = entry and entry.where
    if not where or where == "" then
        return nil
    end

    local bossNumber = where:match("B(%d+)")
    local trashNumber = where:match("T(%d+)")

    if bossNumber and trashNumber then
        if bossNumber == trashNumber then
            return "Trash + Boss " .. bossNumber
        end
        return "Trash " .. trashNumber .. " + Boss " .. bossNumber
    elseif bossNumber then
        return "Boss " .. bossNumber
    elseif trashNumber then
        return "Trash section " .. trashNumber
    end

    return where
end

local function isBossEntry(entry, record)
    local kind = getEntryLocationKind(entry, record)
    return kind == "boss" or kind == "mixed"
end

local function isMustStopEntry(entry)
    return entry and entry.mustStop and true or false
end

local function getMustStopColor()
    local color = KN.db and KN.db.mustStopColor or nil
    return (color and color.r) or 1.00, (color and color.g) or 0.22, (color and color.b) or 0.14
end

local function isLearnedEntry(entry)
    return KN.IsEntryLearned and KN:IsEntryLearned(entry) or false
end

local function getLearnedAlpha()
    return math.max(0.12, math.min(1.0, (KN.db and KN.db.learnedOpacity) or 0.38))
end

local function getModeSettings()
    local mini = KN:IsMiniMode()
    if mini then
        return true,
            KN.db.miniWidth or 300,
            KN.db.miniFontSize or 12,
            KN.db.miniOpacity or 0.82,
            KN.db.miniRowGap or 1
    end

    return false,
        KN.db.fullWidth or 470,
        KN.db.fullFontSize or 13,
        KN.db.fullOpacity or 0.88,
        KN.db.fullRowGap or 6
end

local function rowTooltip(row)
    local entry = row._entry
    if not entry then
        return
    end

    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetText(entry.spell or entry.title or "Reminder", 1, 1, 1)

    local location = getLocationLabel(entry, row._record)
    if location then
        if isBossEntry(entry, row._record) then
            GameTooltip:AddLine(location, 1.00, 0.76, 0.24)
        else
            GameTooltip:AddLine(location, 0.72, 0.82, 0.94)
        end
        if location:find("Boss") then
            GameTooltip:AddLine("Boss numbers follow the order of boss encounters in the dungeon.", 0.58, 0.64, 0.72, true)
        elseif location:find("Trash") then
            GameTooltip:AddLine("Trash section numbers follow the route through the dungeon between bosses.", 0.58, 0.64, 0.72, true)
        end
    end

    if entry.mob then
        GameTooltip:AddLine("Source: " .. entry.mob, 0.72, 0.82, 0.94)
    end

    if isMustStopEntry(entry) then
        local cr, cg, cb = getMustStopColor()
        GameTooltip:AddLine("MUST STOP", cr, cg, cb)
        GameTooltip:AddLine("Extremely high-priority stop. Missing it can cause deaths, severe group damage, or major pull failure; it is not a promise that every single miss is a literal guaranteed wipe.", 0.95, 0.82, 0.74, true)
    end

    local priority = entry.priority or 2
    GameTooltip:AddLine("Priority: " .. (PRIORITY_LABEL[priority] or "Important"),
        priority >= 3 and 1.00 or 0.78,
        priority >= 3 and 0.45 or 0.82,
        priority >= 3 and 0.30 or 0.90)

    if entry.dispelType then
        GameTooltip:AddLine("Dispel type: " .. entry.dispelType:sub(1, 1):upper() .. entry.dispelType:sub(2), 0.65, 0.82, 1.0)
    end
    if entry.note then
        GameTooltip:AddLine(entry.note, 0.90, 0.90, 0.90, true)
    end
    if row._toolName then
        GameTooltip:AddLine("Your tool: " .. row._toolName, 0.54, 0.91, 0.66)
    elseif row._available == false and entry.action ~= "watch" then
        if entry.action == "dispel" then
            GameTooltip:AddLine("Your current spec has no matching friendly dispel. Another player must handle the dispel; a personal immunity or self-cleanse may still work if this specific mechanic allows it.", 0.72, 0.72, 0.76, true)
        elseif entry.action == "purge" then
            GameTooltip:AddLine("Your current spec has no matching offensive dispel/purge. Treat this as a group job.", 0.72, 0.72, 0.76, true)
        else
            GameTooltip:AddLine("Your current spec has no matching tool in KickNotes for this mechanic. Treat this as a group job.", 0.72, 0.72, 0.76, true)
        end
    elseif row._available == nil and entry.action == "dispel" then
        GameTooltip:AddLine("Dispel type not yet verified for class matching.", 0.95, 0.72, 0.30, true)
    end

    GameTooltip:AddLine(" ")
    if KN.db and KN.db.learningEnabled then
        if isLearnedEntry(entry) then
            GameTooltip:AddLine("✓ Learned", 0.42, 0.86, 0.58)
            GameTooltip:AddLine("Right-click to mark this as learning again.", 0.78, 0.82, 0.88, true)
        else
            GameTooltip:AddLine("Learning", 0.72, 0.82, 0.94)
            GameTooltip:AddLine("Right-click to mark this mechanic as learned.", 0.78, 0.82, 0.88, true)
        end
    else
        GameTooltip:AddLine("Learning is disabled in KickNotes settings.", 0.62, 0.66, 0.72, true)
    end

    GameTooltip:Show()
end

function KN:CreateMainFrame()
    if self.frame then
        return
    end

    local frame = CreateFrame("Frame", "KickNotesMainFrame", UIParent, "BackdropTemplate")
    frame:SetSize(self.db.fullWidth or 470, 360)
    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.025, 0.035, 0.06, self.db.fullOpacity or 0.88)
    frame:SetBackdropBorderColor(0.22, 0.56, 0.88, 0.92)

    frame:SetScript("OnDragStart", function(f)
        if not KN.db.locked then
            f:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        local point, _, relativePoint, x, y = f:GetPoint(1)
        KN.charDb.point = {
            point = point,
            relativePoint = relativePoint,
            x = x,
            y = y,
        }
    end)

    local accent = frame:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT")
    accent:SetPoint("TOPRIGHT")
    accent:SetHeight(3)
    accent:SetColorTexture(0.22, 0.62, 1.0, 1)
    frame.accent = accent

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetJustifyH("LEFT")
    title:SetJustifyV("TOP")
    title:SetWordWrap(false)
    setTextColor(title, 0.94, 0.97, 1.0)
    frame.title = title

    local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    subtitle:SetJustifyH("LEFT")
    subtitle:SetJustifyV("TOP")
    subtitle:SetWordWrap(true)
    setTextColor(subtitle, 0.58, 0.68, 0.80)
    frame.subtitle = subtitle

    local progress = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    progress:SetJustifyH("RIGHT")
    progress:SetJustifyV("TOP")
    progress:SetWordWrap(false)
    setFont(progress, 9, "OUTLINE")
    setTextColor(progress, 0.52, 0.82, 0.62)
    progress:Hide()
    frame.progress = progress

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.close = close

    local options = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    options:SetText("Options")
    options:SetScript("OnClick", function()
        KN:OpenSettings()
    end)
    frame.options = options

    local modeToggle = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    modeToggle:SetText("Mini")
    modeToggle:SetScript("OnClick", function()
        KN:ToggleMiniMode()
    end)
    modeToggle:SetScript("OnEnter", function(button)
        GameTooltip:SetOwner(button, "ANCHOR_TOP")
        if KN:IsMiniMode() then
            GameTooltip:SetText("Switch to Full view")
            GameTooltip:AddLine("Show the larger reminder layout with mob, location and explanatory details.", 0.85, 0.85, 0.85, true)
        else
            GameTooltip:SetText("Switch to Mini view")
            GameTooltip:AddLine("Use the compact reminder layout while keeping full details available on hover.", 0.85, 0.85, 0.85, true)
        end
        GameTooltip:Show()
    end)
    modeToggle:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame.modeToggle = modeToggle

    local collapse = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    collapse:SetText("-")
    collapse:SetScript("OnClick", function()
        KN:ToggleZip()
    end)
    collapse:SetScript("OnEnter", function(button)
        GameTooltip:SetOwner(button, "ANCHOR_TOP")
        if KN:IsZipped() then
            GameTooltip:SetText("Restore KickNotes")
            GameTooltip:AddLine("Click to restore the reminder window.", 0.85, 0.85, 0.85, true)
        else
            GameTooltip:SetText("Zip KickNotes")
            GameTooltip:AddLine("Collapse the reminder to a small KN button without hiding it completely.", 0.85, 0.85, 0.85, true)
        end
        GameTooltip:Show()
    end)
    collapse:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame.collapse = collapse

    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(0.18, 0.26, 0.36, 0.8)
    divider:SetHeight(1)
    frame.divider = divider

    local footer = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    footer:SetJustifyH("LEFT")
    setFont(footer, 10)
    setTextColor(footer, 0.46, 0.54, 0.64)
    footer:SetText("Static reminders only. No combat-log cast detection.")
    frame.footer = footer

    local scrollHint = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    scrollHint:SetJustifyH("RIGHT")
    setFont(scrollHint, 9)
    setTextColor(scrollHint, 0.50, 0.62, 0.74)
    scrollHint:SetText("mouse wheel")
    scrollHint:Hide()
    frame.scrollHint = scrollHint

    local scroll = CreateFrame("ScrollFrame", nil, frame)
    scroll:EnableMouseWheel(true)
    frame.scroll = scroll

    local scrollChild = CreateFrame("Frame", nil, scroll)
    scrollChild:SetSize(1, 1)
    scroll:SetScrollChild(scrollChild)
    frame.scrollChild = scrollChild

    scroll:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll() or 0
        local maximum = self:GetVerticalScrollRange() or 0
        local nextValue = math.max(0, math.min(maximum, current - (delta * 34)))
        self:SetVerticalScroll(nextValue)
    end)

    frame.rows = {}
    frame:Hide()
    self.frame = frame
    self:ApplyFrameSettings(true)
end

function KN:AcquireRow(index)
    local row = self.frame.rows[index]
    if row then
        row:Show()
        return row
    end

    row = CreateFrame("Frame", nil, self.frame.scrollChild, "BackdropTemplate")
    row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    row:EnableMouse(true)
    row:SetScript("OnEnter", rowTooltip)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row:SetScript("OnMouseUp", function(clickedRow, button)
        if button == "RightButton" and clickedRow._entry and KN.db and KN.db.learningEnabled then
            KN:ToggleEntryLearned(clickedRow._entry)
            GameTooltip:Hide()
        end
    end)

    local badge = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    badge:SetJustifyH("CENTER")
    badge:SetJustifyV("MIDDLE")
    row.badge = badge

    local spell = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    spell:SetJustifyH("LEFT")
    spell:SetJustifyV("TOP")
    spell:SetWordWrap(true)
    row.spell = spell

    local critical = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    critical:SetJustifyH("LEFT")
    critical:SetJustifyV("TOP")
    critical:SetWordWrap(false)
    critical:Hide()
    row.critical = critical

    local criticalAccent = row:CreateTexture(nil, "ARTWORK")
    criticalAccent:SetWidth(3)
    criticalAccent:SetPoint("TOPLEFT", 0, 0)
    criticalAccent:SetPoint("BOTTOMLEFT", 0, 0)
    criticalAccent:Hide()
    row.criticalAccent = criticalAccent

    local detail = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    detail:SetJustifyH("LEFT")
    detail:SetJustifyV("TOP")
    detail:SetWordWrap(true)
    row.detail = detail

    local tool = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tool:SetJustifyH("RIGHT")
    tool:SetJustifyV("TOP")
    tool:SetWordWrap(true)
    row.tool = tool

    self.frame.rows[index] = row
    return row
end

function KN:ApplyFrameSettings(resetPosition)
    if not self.frame then
        return
    end

    local frame = self.frame
    local mini, configuredWidth, _, opacity = getModeSettings()
    local width = self:IsZipped() and ZIPPED_WIDTH or configuredWidth

    frame:SetScale(self.db.scale or 1)
    frame:SetWidth(width)
    frame:SetBackdropColor(0.025, 0.035, 0.06, opacity)

    frame:ClearAllPoints()
    local point = self:GetWindowPoint() or {}
    frame:SetPoint(
        point.point or "CENTER",
        UIParent,
        point.relativePoint or "CENTER",
        point.x or 380,
        point.y or 80
    )

    if frame:IsShown() and self.currentContent then
        self:RefreshDisplay(self.currentContent, self.currentEncounter, "settings")
    elseif resetPosition then
        frame:SetHeight(self:IsZipped() and ZIPPED_HEIGHT or (mini and 180 or 360))
    end
end

function KN:SetMiniMode(value)
    if self.charDb then
        self.charDb.mini = value and true or false
        -- Switching presentation modes should always show the actual window.
        self.charDb.zipped = false
    end

    -- Manual presentation changes cancel an outstanding auto-zip timer.
    self.autoZipGeneration = (self.autoZipGeneration or 0) + 1

    if self.frame and self.currentContent then
        self:RefreshDisplay(self.currentContent, self.currentEncounter, "mode")
    elseif self.frame then
        self:ApplyFrameSettings(false)
    end
end

function KN:ToggleMiniMode()
    self:SetMiniMode(not self:IsMiniMode())
end

function KN:SetZipped(value)
    if self.charDb then
        self.charDb.zipped = value and true or false
    end

    if self.frame and self.currentContent then
        self:RefreshDisplay(self.currentContent, self.currentEncounter, "zip")
    elseif self.frame then
        self:ApplyFrameSettings(false)
    end
end

function KN:ToggleZip()
    -- Manual interaction wins over a pending automatic-collapse timer.
    self.autoZipGeneration = (self.autoZipGeneration or 0) + 1
    self:SetZipped(not self:IsZipped())
end

local function scheduleDeferredLayout(record, encounterName)
    -- WoW can report stale FontString heights in the same frame that widths,
    -- anchors or scale are changed. A one-frame-later layout pass gives the
    -- text engine time to reflow before we size the rows.
    if not C_Timer or not C_Timer.After then
        return
    end

    KN.layoutGeneration = (KN.layoutGeneration or 0) + 1
    local generation = KN.layoutGeneration

    C_Timer.After(0, function()
        if not KN.frame or not KN.frame:IsShown() then
            return
        end
        if generation ~= KN.layoutGeneration then
            return
        end
        if KN.currentContent ~= record or KN:IsZipped() then
            return
        end
        KN:RefreshDisplay(record, encounterName, "deferred-layout")
    end)
end

function KN:RefreshDisplay(record, encounterName, reason)
    if not self.frame then
        self:CreateMainFrame()
    end

    local frame = self.frame
    local entries = self:GetVisibleEntries(record, encounterName)
    local mini, configuredWidth, fontSize, opacity, rowGap = getModeSettings()
    local zipped = self:IsZipped()
    local frameWidth = zipped and ZIPPED_WIDTH or configuredWidth
    local compact = self.db.compact and not mini

    -- Apply scale before measuring wrapped FontStrings. Doing this only after
    -- row sizing can leave the first render using stale wrap measurements.
    frame:SetScale(self.db.scale or 1)
    frame:SetWidth(frameWidth)
    frame.scroll:SetVerticalScroll(0)

    if zipped then
        frame.title:Hide()
        frame.subtitle:Hide()
        frame.progress:Hide()
        frame.close:Hide()
        frame.options:Hide()
        frame.modeToggle:Hide()
        frame.divider:Hide()
        frame.footer:Hide()
        frame.scroll:Hide()
        frame.scrollHint:Hide()
        for _, row in ipairs(frame.rows) do
            row:Hide()
        end

        frame.collapse:Show()
        frame.collapse:ClearAllPoints()
        frame.collapse:SetPoint("CENTER", 0, -1)
        frame.collapse:SetSize(40, 22)
        frame.collapse:SetText("KN")
        frame:SetHeight(ZIPPED_HEIGHT)
        frame:SetScale(self.db.scale or 1)
        frame:SetBackdropColor(0.025, 0.035, 0.06, opacity)
        frame:Show()
        return
    end

    frame.scroll:Show()
    frame.title:Show()
    frame.progress:Show()
    frame.close:Show()
    frame.options:Show()
    frame.modeToggle:Show()
    frame.modeToggle:SetText(mini and "Full" or "Mini")
    frame.divider:Show()
    frame.collapse:Show()
    frame.collapse:SetText("-")

    frame.title:ClearAllPoints()
    frame.subtitle:ClearAllPoints()
    frame.progress:ClearAllPoints()
    frame.divider:ClearAllPoints()
    frame.footer:ClearAllPoints()
    frame.scroll:ClearAllPoints()
    frame.scrollHint:ClearAllPoints()

    local headerHeight
    local footerHeight
    local leftMargin
    local rightMargin

    if mini then
        headerHeight = 40
        footerHeight = 3
        leftMargin = 4
        rightMargin = 4

        frame.title:SetPoint("TOPLEFT", 7, -5)
        frame.title:SetWidth(frameWidth - 136)
        setFont(frame.title, math.max(11, fontSize + 1), "OUTLINE")
        frame.subtitle:Hide()
        frame.progress:SetPoint("TOPLEFT", 7, -23)
        frame.progress:SetPoint("TOPRIGHT", -7, -23)
        frame.progress:SetJustifyH("LEFT")
        setFont(frame.progress, math.max(8, fontSize - 3), "OUTLINE")
        frame.footer:Hide()

        frame.close:SetSize(22, 22)
        frame.close:ClearAllPoints()
        frame.close:SetPoint("TOPRIGHT", 0, -2)
        frame.options:SetSize(34, 16)
        frame.options:SetText("Opt")
        frame.options:ClearAllPoints()
        frame.options:SetPoint("TOPRIGHT", frame.close, "TOPLEFT", 0, -5)
        frame.modeToggle:SetSize(32, 16)
        frame.modeToggle:ClearAllPoints()
        frame.modeToggle:SetPoint("TOPRIGHT", frame.options, "TOPLEFT", -1, 0)
        frame.collapse:SetSize(18, 16)
        frame.collapse:ClearAllPoints()
        frame.collapse:SetPoint("TOPRIGHT", frame.modeToggle, "TOPLEFT", -1, 0)
        frame.divider:SetPoint("TOPLEFT", 4, -37)
        frame.divider:SetPoint("TOPRIGHT", -4, -37)
        frame.scroll:SetPoint("TOPLEFT", leftMargin, -headerHeight)
        frame.scroll:SetPoint("TOPRIGHT", -rightMargin, -headerHeight)
    else
        headerHeight = 61
        footerHeight = 30
        leftMargin = 12
        rightMargin = 12

        frame.title:SetPoint("TOPLEFT", 16, -14)
        frame.title:SetWidth(frameWidth - 204)
        setFont(frame.title, 17, "OUTLINE")
        frame.subtitle:Show()
        frame.footer:Show()

        frame.close:SetSize(32, 32)
        frame.close:ClearAllPoints()
        frame.close:SetPoint("TOPRIGHT", -3, -4)
        frame.options:SetSize(68, 20)
        frame.options:SetText("Options")
        frame.options:ClearAllPoints()
        frame.options:SetPoint("TOPRIGHT", frame.close, "TOPLEFT", -2, -5)
        frame.modeToggle:SetSize(44, 20)
        frame.modeToggle:ClearAllPoints()
        frame.modeToggle:SetPoint("TOPRIGHT", frame.options, "TOPLEFT", -2, 0)
        frame.collapse:SetSize(22, 20)
        frame.collapse:ClearAllPoints()
        frame.collapse:SetPoint("TOPRIGHT", frame.modeToggle, "TOPLEFT", -2, 0)
        frame.subtitle:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -4)
        frame.subtitle:SetWidth(math.max(120, frameWidth - 170))
        setFont(frame.subtitle, 11)
        frame.progress:SetPoint("TOPRIGHT", -15, -37)
        frame.progress:SetWidth(132)
        frame.progress:SetJustifyH("RIGHT")
        setFont(frame.progress, 9, "OUTLINE")
        frame.divider:SetPoint("TOPLEFT", 12, -52)
        frame.divider:SetPoint("TOPRIGHT", -12, -52)
        frame.footer:SetPoint("BOTTOMLEFT", 14, 10)
        frame.footer:SetWidth(math.max(180, frameWidth - 120))
        frame.scrollHint:SetPoint("BOTTOMRIGHT", -14, 10)
        frame.scrollHint:SetWidth(90)
        frame.scroll:SetPoint("TOPLEFT", leftMargin, -headerHeight)
        frame.scroll:SetPoint("TOPRIGHT", -rightMargin, -headerHeight)
    end

    frame.title:SetText(encounterName or record.name)
    local subtitle = record.season or ""
    if record.type == "dungeon" then
        subtitle = subtitle .. "  •  " .. self:GetPlayerSpecLabel()
    elseif encounterName then
        subtitle = record.name .. "  •  " .. subtitle
    end
    frame.subtitle:SetText(subtitle)

    local learnedCount, remainingCount, learningTotal = self:GetLearningStats(record, encounterName)
    if self.db.learningEnabled and learningTotal > 0 then
        if learnedCount > 0 then
            frame.progress:SetText(string.format("%d to learn  •  %d learned", remainingCount, learnedCount))
        else
            frame.progress:SetText(string.format("%d to learn", remainingCount))
        end
        frame.progress:Show()
    else
        frame.progress:SetText("")
        frame.progress:Hide()
    end

    for _, row in ipairs(frame.rows) do
        row:Hide()
        row._entry = nil
        row._record = nil
        row._toolName = nil
        row._available = nil
        row._learned = nil
        row:SetAlpha(1)
        if row.critical then row.critical:Hide() end
        if row.criticalAccent then row.criticalAccent:Hide() end
    end

    local contentWidth = math.max(1, frameWidth - leftMargin - rightMargin)
    frame.scrollChild:SetWidth(contentWidth)
    local cursorY = 0

    if #entries == 0 then
        local row = self:AcquireRow(1)
        local rowHeight = mini and math.max(26, fontSize + 12) or 42
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", frame.scrollChild, "TOPLEFT", 0, -cursorY)
        row:SetPoint("TOPRIGHT", frame.scrollChild, "TOPRIGHT", 0, -cursorY)
        row:SetHeight(rowHeight)
        row:SetBackdropColor(0.05, 0.07, 0.10, opacity)
        row:SetAlpha(1)

        row.badge:SetText("INFO")
        setFont(row.badge, math.max(8, fontSize - 3), "OUTLINE")
        setTextColor(row.badge, 0.55, 0.72, 0.9)
        row.badge:ClearAllPoints()
        row.badge:SetPoint("LEFT", 5, 0)
        row.badge:SetWidth(mini and 36 or 48)

        if self.db.learningEnabled and self.db.learnedMode == "hide" and learningTotal > 0 and remainingCount == 0 and learnedCount > 0 then
            row.spell:SetText("All matching mechanics are marked learned.")
        else
            row.spell:SetText("No reminders match the current filters.")
        end
        row.spell:SetWordWrap(true)
        setFont(row.spell, fontSize)
        setTextColor(row.spell, 0.88, 0.91, 0.96)
        row.spell:ClearAllPoints()
        row.spell:SetPoint("LEFT", mini and 45 or 62, 0)
        row.spell:SetPoint("RIGHT", -8, 0)

        row.detail:SetText("")
        row.detail:Hide()
        row.tool:SetText("")
        cursorY = cursorY + rowHeight
    else
        for index, entry in ipairs(entries) do
            local row = self:AcquireRow(index)
            local style = ACTION_STYLE[entry.action] or ACTION_STYLE.watch
            local boss = isBossEntry(entry, record)
            local mustStop = isMustStopEntry(entry)
            local learned = isLearnedEntry(entry)
            local locationLabel = getLocationLabel(entry, record)

            row._entry = entry
            row._record = record
            row._learned = learned
            if self.db.learningEnabled and self.db.learnedMode == "dim" and learned then
                row:SetAlpha(getLearnedAlpha())
            else
                row:SetAlpha(1)
            end

            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", frame.scrollChild, "TOPLEFT", 0, -cursorY)
            row:SetPoint("TOPRIGHT", frame.scrollChild, "TOPRIGHT", 0, -cursorY)
            if mustStop and self.db.highlightMustStop then
                row:SetBackdropColor(0.13, 0.035, 0.035, opacity)
                local cr, cg, cb = getMustStopColor()
                row.criticalAccent:SetColorTexture(cr, cg, cb, 0.95)
                row.criticalAccent:Show()
            else
                row:SetBackdropColor(0.045, 0.06, 0.09, opacity)
                row.criticalAccent:Hide()
            end

            local badgeWidth = mini and math.max(38, fontSize * 3.1) or 54
            local toolWidth = mini and math.max(68, math.floor(contentWidth * 0.27)) or 108

            row.badge:ClearAllPoints()
            row.badge:SetPoint("LEFT", mini and 3 or 8, 0)
            row.badge:SetWidth(badgeWidth)
            row.badge:SetText(style.label)
            setFont(row.badge, mini and math.max(8, fontSize - 2) or 10, "OUTLINE")
            setTextColor(row.badge, style.r, style.g, style.b)

            local headline = entry.spell or entry.title or "Reminder"
            if mini and boss then
                headline = "[B] " .. headline
            end
            if mini and self.db.learningEnabled and learned then
                headline = "✓ " .. headline
            end

            row.spell:ClearAllPoints()
            row.critical:ClearAllPoints()
            if mustStop and self.db.highlightMustStop then
                local cr, cg, cb = getMustStopColor()
                row.critical:SetText("MUST STOP")
                setFont(row.critical, mini and math.max(9, fontSize - 1) or math.max(10, fontSize - 1), "THICKOUTLINE")
                setTextColor(row.critical, cr, cg, cb)
                row.critical:Show()

                if mini then
                    row.critical:SetPoint("TOPLEFT", badgeWidth + 7, -3)
                    row.critical:SetPoint("TOPRIGHT", -(toolWidth + 8), -3)
                    row.spell:SetPoint("TOPLEFT", row.critical, "BOTTOMLEFT", 0, -1)
                    row.spell:SetPoint("TOPRIGHT", -(toolWidth + 8), -(fontSize + 5))
                else
                    row.spell:SetPoint("TOPLEFT", 72, -7)
                    row.spell:SetPoint("TOPRIGHT", -(toolWidth + 12), -7)
                    row.critical:SetPoint("TOPLEFT", row.spell, "BOTTOMLEFT", 0, -2)
                    row.critical:SetPoint("TOPRIGHT", -(toolWidth + 12), 0)
                end
            else
                row.critical:SetText("")
                row.critical:Hide()
                if mini then
                    row.spell:SetPoint("TOPLEFT", badgeWidth + 7, -4)
                    row.spell:SetPoint("TOPRIGHT", -(toolWidth + 8), -4)
                else
                    row.spell:SetPoint("TOPLEFT", 72, -7)
                    row.spell:SetPoint("TOPRIGHT", -(toolWidth + 12), -7)
                end
            end
            row.spell:SetWordWrap(true)
            row.spell:SetText(headline)
            setFont(row.spell, fontSize, "OUTLINE")
            if self.db.highlightBosses and boss then
                local bossColor = self.db.bossColor or { r = 1.00, g = 0.76, b = 0.24 }
                setTextColor(row.spell, bossColor.r or 1.00, bossColor.g or 0.76, bossColor.b or 0.24)
            else
                setTextColor(row.spell, 0.94, 0.97, 1.0)
            end

            local details = {}
            if not mini and self.db.learningEnabled and learned then
                details[#details + 1] = "|cff6fdb93✓ LEARNED|r"
            end
            if locationLabel then
                details[#details + 1] = locationLabel
            end
            if entry.mob then
                details[#details + 1] = entry.mob
            end
            details[#details + 1] = PRIORITY_LABEL[entry.priority or 2] or "Important"
            if not mini and entry.note and not compact then
                details[#details + 1] = entry.note
            end

            row.detail:ClearAllPoints()
            if mini then
                row.detail:SetText("")
                row.detail:Hide()
            else
                row.detail:Show()
                if mustStop and self.db.highlightMustStop then
                    row.detail:SetPoint("TOPLEFT", row.critical, "BOTTOMLEFT", 0, -3)
                else
                    row.detail:SetPoint("TOPLEFT", row.spell, "BOTTOMLEFT", 0, -3)
                end
                row.detail:SetPoint("RIGHT", -(toolWidth + 12), 0)
                row.detail:SetWordWrap(true)
                row.detail:SetText(table.concat(details, "  •  "))
                setFont(row.detail, math.max(10, fontSize - 2))
                setTextColor(row.detail, 0.60, 0.68, 0.78)
            end

            local toolName, available = self:GetToolForEntry(entry)
            row._toolName = toolName
            row._available = available
            row.tool:ClearAllPoints()
            if mini then
                row.tool:SetPoint("TOPRIGHT", -4, -4)
                row.tool:SetWidth(toolWidth)
                row.tool:SetWordWrap(true)
            else
                row.tool:SetPoint("TOPRIGHT", -10, -8)
                row.tool:SetWidth(toolWidth)
                row.tool:SetWordWrap(true)
            end
            if toolName then
                row.tool:SetText(toolName)
                setTextColor(row.tool, 0.54, 0.91, 0.66)
            elseif available == false and entry.action ~= "watch" then
                row.tool:SetText(mini and "group" or "group job")
                setTextColor(row.tool, 0.58, 0.60, 0.66)
            else
                row.tool:SetText("")
            end
            setFont(row.tool, mini and math.max(8, fontSize - 1) or math.max(9, fontSize - 3))

            local spellHeight = math.max(fontSize + 2, row.spell:GetStringHeight() or 0)
            local toolHeight = math.max(fontSize + 2, row.tool:GetStringHeight() or 0)
            local criticalHeight = 0
            if mustStop and self.db.highlightMustStop and row.critical:IsShown() then
                criticalHeight = math.max(fontSize, row.critical:GetStringHeight() or 0)
            end
            local detailHeight = 0
            if not mini and row.detail:GetText() and row.detail:GetText() ~= "" then
                detailHeight = math.max(10, row.detail:GetStringHeight() or 0)
            end

            local desiredHeight
            if mini then
                -- Critical rows intentionally spend one extra line on MUST STOP.
                local textStack = spellHeight + (criticalHeight > 0 and (criticalHeight + 2) or 0)
                desiredHeight = math.max(fontSize + 10, 8 + textStack, 8 + toolHeight)
            elseif compact then
                desiredHeight = math.max(36, 8 + spellHeight + (criticalHeight > 0 and (2 + criticalHeight) or 0) + (detailHeight > 0 and (2 + detailHeight) or 0) + 7)
            else
                desiredHeight = math.max(48, 8 + spellHeight + (criticalHeight > 0 and (2 + criticalHeight) or 0) + (detailHeight > 0 and (3 + detailHeight) or 0) + 8)
            end

            row:SetHeight(desiredHeight)
            cursorY = cursorY + desiredHeight + rowGap
        end
        if cursorY > 0 then
            cursorY = cursorY - rowGap
        end
    end

    local contentHeight = math.max(1, cursorY)
    frame.scrollChild:SetHeight(contentHeight)

    local maxFrameHeight = math.max(180, self.db.maxWindowHeight or 620)
    local maxViewportHeight = math.max(70, maxFrameHeight - headerHeight - footerHeight)
    local viewportHeight = math.min(contentHeight, maxViewportHeight)
    frame.scroll:SetHeight(viewportHeight)

    local frameHeight = headerHeight + viewportHeight + footerHeight
    frame:SetHeight(math.max(mini and 58 or 132, frameHeight))
    frame:SetScale(self.db.scale or 1)
    frame:SetBackdropColor(0.025, 0.035, 0.06, opacity)

    local scrollable = contentHeight > viewportHeight + 1
    if not mini and scrollable then
        frame.scrollHint:Show()
    else
        frame.scrollHint:Hide()
    end

    frame:Show()

    if reason ~= "deferred-layout" then
        scheduleDeferredLayout(record, encounterName)
    end
end
