local ADDON_NAME, KN = ...

local PAGE_MARGIN = 18
local RIGHT_MARGIN = 24

local function addControl(panel, control)
    panel._controls = panel._controls or {}
    panel._controls[#panel._controls + 1] = control
end

local function refreshControls(panel)
    for _, control in ipairs(panel._controls or {}) do
        if control.refresh then
            control.refresh()
        end
    end
end

local function makePage(panel, key)
    local page = CreateFrame("Frame", nil, panel)
    page:SetPoint("TOPLEFT", 0, -82)
    page:SetPoint("BOTTOMRIGHT", 0, 0)
    page:Hide()

    local scroll = CreateFrame("ScrollFrame", nil, page, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 4, -2)
    scroll:SetPoint("BOTTOMRIGHT", -30, 4)
    scroll:EnableMouseWheel(true)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(560, 600)
    scroll:SetScrollChild(content)

    scroll:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll() or 0
        local maximum = self:GetVerticalScrollRange() or 0
        self:SetVerticalScroll(math.max(0, math.min(maximum, current - delta * 42)))
    end)

    local function updateWidth()
        local width = scroll:GetWidth() or 0
        if width > 0 then
            content:SetWidth(math.max(300, width - 8))
        end
    end
    scroll:SetScript("OnSizeChanged", updateWidth)
    page:SetScript("OnShow", function()
        updateWidth()
        refreshControls(panel)
    end)

    panel.pages[key] = { frame = page, scroll = scroll, content = content }
    return panel.pages[key]
end

local function makeHeader(parent, text, y)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    label:SetPoint("TOPLEFT", PAGE_MARGIN, y)
    label:SetText(text)
    return y - 30
end

local function makeText(parent, text, y, height)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", PAGE_MARGIN, y)
    label:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -RIGHT_MARGIN, y)
    label:SetJustifyH("LEFT")
    label:SetJustifyV("TOP")
    label:SetWordWrap(true)
    if label.SetNonSpaceWrap then
        label:SetNonSpaceWrap(true)
    end
    label:SetText(text)
    return y - (height or 46)
end

local function makeCheck(panel, parent, name, labelText, y, getter, setter)
    local check = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    check:SetSize(26, 26)
    check:SetPoint("TOPLEFT", PAGE_MARGIN, y)

    if check.Text then
        check.Text:SetText("")
        check.Text:Hide()
    end

    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("TOPLEFT", check, "TOPRIGHT", 4, -3)
    label:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -RIGHT_MARGIN, -3)
    label:SetJustifyH("LEFT")
    label:SetJustifyV("TOP")
    label:SetWordWrap(true)
    if label.SetNonSpaceWrap then
        label:SetNonSpaceWrap(true)
    end
    label:SetText(labelText)
    check.Label = label

    check:SetScript("OnClick", function(self)
        setter(self:GetChecked() and true or false)
        if KN.ApplyFrameSettings then
            KN:ApplyFrameSettings(false)
        end
    end)
    check.refresh = function()
        check:SetChecked(getter() and true or false)
    end
    check.refresh()
    addControl(panel, check)
    return y - 48
end

local function makeColorPicker(panel, parent, labelText, y, getter, setter)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("TOPLEFT", PAGE_MARGIN + 36, y)
    label:SetText(labelText)

    local swatch = CreateFrame("Button", nil, parent, "BackdropTemplate")
    swatch:SetSize(30, 20)
    swatch:SetPoint("LEFT", label, "RIGHT", 12, 0)
    swatch:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    swatch:SetBackdropBorderColor(0.65, 0.65, 0.65, 1)

    local function refresh()
        local color = getter() or { r = 1.00, g = 0.76, b = 0.24 }
        swatch:SetBackdropColor(color.r or 1.00, color.g or 0.76, color.b or 0.24, 1)
    end

    local function applyColor(r, g, b)
        setter({ r = r, g = g, b = b })
        refresh()
        if KN.ApplyFrameSettings then
            KN:ApplyFrameSettings(false)
        end
    end

    swatch:SetScript("OnClick", function()
        local current = getter() or { r = 1.00, g = 0.76, b = 0.24 }
        local previous = { r = current.r, g = current.g, b = current.b }

        if ColorPickerFrame.SetupColorPickerAndShow then
            ColorPickerFrame:SetupColorPickerAndShow({
                r = current.r,
                g = current.g,
                b = current.b,
                hasOpacity = false,
                swatchFunc = function()
                    local r, g, b = ColorPickerFrame:GetColorRGB()
                    applyColor(r, g, b)
                end,
                cancelFunc = function()
                    applyColor(previous.r, previous.g, previous.b)
                end,
            })
        else
            ColorPickerFrame:SetColorRGB(current.r, current.g, current.b)
            ColorPickerFrame.hasOpacity = false
            ColorPickerFrame.func = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                applyColor(r, g, b)
            end
            ColorPickerFrame.cancelFunc = function()
                applyColor(previous.r, previous.g, previous.b)
            end
            ColorPickerFrame:Show()
        end
    end)

    swatch:SetScript("OnEnter", function(button)
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetText("Boss mechanic spell color")
        GameTooltip:AddLine("Boss rows also show a B marker in Mini mode and a plain-language Boss label in Full mode.", 0.85, 0.85, 0.85, true)
        GameTooltip:Show()
    end)
    swatch:SetScript("OnLeave", function() GameTooltip:Hide() end)
    swatch.refresh = refresh
    refresh()
    addControl(panel, swatch)
    return y - 38
end

local function makeSlider(panel, parent, name, labelText, y, minValue, maxValue, step, getter, setter, formatter)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", PAGE_MARGIN, y)
    slider:SetWidth(260)
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)

    _G[name .. "Text"]:SetText(labelText)
    _G[name .. "Low"]:SetText(tostring(minValue))
    _G[name .. "High"]:SetText(tostring(maxValue))

    local valueText = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    valueText:SetPoint("LEFT", slider, "RIGHT", 14, 0)

    local updating = false
    slider:SetScript("OnValueChanged", function(_, value)
        if updating then return end
        setter(value)
        valueText:SetText(formatter and formatter(value) or tostring(value))
        if KN.ApplyFrameSettings then
            KN:ApplyFrameSettings(false)
        end
    end)

    slider.refresh = function()
        local value = getter()
        updating = true
        slider:SetValue(value)
        updating = false
        valueText:SetText(formatter and formatter(value) or tostring(value))
    end
    slider.refresh()
    addControl(panel, slider)
    return y - 70
end

local function makeCycle(panel, parent, name, labelText, y, choices, getter, setter)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("TOPLEFT", PAGE_MARGIN, y)
    label:SetText(labelText)

    local button = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
    button:SetSize(270, 24)
    button:SetPoint("TOPLEFT", PAGE_MARGIN, y - 22)

    local function findIndex(value)
        for i, choice in ipairs(choices) do
            if choice.value == value then
                return i
            end
        end
        return 1
    end

    button:SetScript("OnClick", function(_, mouseButton)
        local index = findIndex(getter())
        if mouseButton == "RightButton" then
            index = ((index - 2) % #choices) + 1
        else
            index = (index % #choices) + 1
        end
        setter(choices[index].value)
        button:SetText(choices[index].label)
        if KN.ApplyFrameSettings then
            KN:ApplyFrameSettings(false)
        end
    end)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    button.refresh = function()
        local index = findIndex(getter())
        button:SetText(choices[index].label)
    end
    button.refresh()
    addControl(panel, button)
    return y - 58
end

local function makeButton(parent, text, x, y, width, callback)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 130, 24)
    button:SetPoint("TOPLEFT", x, y)
    button:SetText(text)
    button:SetScript("OnClick", callback)
    return button
end

local function finishPage(page, y)
    page.content:SetHeight(math.max(520, math.abs(y) + 50))
end

function KN:RegisterSettings()
    if self.settingsPanel then
        return
    end

    local panel = CreateFrame("Frame")
    panel.name = "KickNotes"
    panel.pages = {}
    panel._controls = {}
    self.settingsPanel = panel

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 18, -16)
    title:SetText("KickNotes " .. (self.version or ""))

    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    subtitle:SetText("Dungeon and raid reminders that teach you what deserves your attention before the pull.")

    local tabNames = {
        { key = "general", label = "General" },
        { key = "appearance", label = "Appearance" },
        { key = "learning", label = "Learning" },
        { key = "content", label = "Content" },
        { key = "preview", label = "Preview / Test" },
    }

    local function showPage(key)
        for pageKey, page in pairs(panel.pages) do
            if pageKey == key then page.frame:Show() else page.frame:Hide() end
        end
        for _, tab in ipairs(panel.tabs or {}) do
            tab:SetEnabled(tab.pageKey ~= key)
        end
        panel.activePage = key
    end

    panel.tabs = {}
    local tabX = 18
    for _, spec in ipairs(tabNames) do
        local pageKey = spec.key
        local tab = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        tab:SetSize(pageKey == "preview" and 110 or 88, 24)
        tab:SetPoint("TOPLEFT", tabX, -52)
        tab:SetText(spec.label)
        tab.pageKey = pageKey
        tab:SetScript("OnClick", function() showPage(pageKey) end)
        panel.tabs[#panel.tabs + 1] = tab
        tabX = tabX + tab:GetWidth() + 6
    end

    local general = makePage(panel, "general")
    local appearance = makePage(panel, "appearance")
    local learning = makePage(panel, "learning")
    local content = makePage(panel, "content")
    local preview = makePage(panel, "preview")

    -- GENERAL
    local y = -14
    y = makeHeader(general.content, "Behavior", y)
    y = makeText(general.content,
        "Current Midnight Season 2 content is enabled by default. KickNotes appears when you enter supported instanced content and disappears when you leave it.", y, 64)
    y = makeCheck(panel, general.content, "KickNotesOptEnabled", "Enable KickNotes", y,
        function() return KN.db.enabled end,
        function(v)
            KN.db.enabled = v
            KN:RefreshContext(v and true or false)
        end)
    y = makeCheck(panel, general.content, "KickNotesOptEnter", "Show when entering a supported dungeon or raid", y,
        function() return KN.db.showOnEnter end,
        function(v) KN.db.showOnEnter = v end)
    y = makeCheck(panel, general.content, "KickNotesOptEncounter", "Show boss-specific raid reminders when an encounter starts", y,
        function() return KN.db.showOnEncounterStart end,
        function(v) KN.db.showOnEncounterStart = v end)
    y = makeCheck(panel, general.content, "KickNotesOptStartZipped", "Start each newly entered dungeon or raid collapsed to the KN button", y,
        function() return KN.db.startZipped end,
        function(v) KN.db.startZipped = v end)

    y = makeCycle(panel, general.content, "KickNotesAutoZipCycle", "Automatically zip the reminder after entering", y, {
        { value = 0,  label = "Never" },
        { value = 10, label = "After 10 seconds" },
        { value = 20, label = "After 20 seconds" },
        { value = 30, label = "After 30 seconds" },
        { value = 60, label = "After 60 seconds" },
    }, function() return KN.db.autoZipSeconds end, function(v) KN.db.autoZipSeconds = v end)

    y = makeHeader(general.content, "List order", y - 2)
    y = makeCycle(panel, general.content, "KickNotesSortCycle", "Sort mechanics by", y, {
        { value = "dungeon",  label = "Dungeon order" },
        { value = "priority", label = "Priority" },
    }, function() return KN.db.sortMode end, function(v) KN.db.sortMode = v end)
    y = makeText(general.content,
        "Dungeon order follows the run naturally (Trash 1, Boss 1, Trash 2, Boss 2...). Priority puts MUST STOP and higher-priority mechanics first regardless of where they appear.", y, 64)

    y = makeHeader(general.content, "Mechanic priority", y - 2)
    y = makeCycle(panel, general.content, "KickNotesPriorityCycle", "Show mechanics", y, {
        { value = 3, label = "Essential only" },
        { value = 2, label = "Essential + Important" },
        { value = 1, label = "Everything (includes Optional)" },
    }, function() return KN.db.minimumPriority end, function(v) KN.db.minimumPriority = v end)
    y = makeText(general.content,
        "Essential means the highest-impact reminders. Important is the normal learning set. Optional is extra detail. The current data pack is intentionally conservative, so most rows are Essential or Important.", y, 78)

    y = makeHeader(general.content, "Mechanic types", y)
    y = makeCheck(panel, general.content, "KickNotesOptInterrupt", "Kicks / interrupts", y,
        function() return KN.db.showInterrupts end, function(v) KN.db.showInterrupts = v end)
    y = makeCheck(panel, general.content, "KickNotesOptStop", "Stops / crowd control", y,
        function() return KN.db.showStops end, function(v) KN.db.showStops = v end)
    y = makeCheck(panel, general.content, "KickNotesOptDispel", "Dispels", y,
        function() return KN.db.showDispels end, function(v) KN.db.showDispels = v end)
    y = makeCheck(panel, general.content, "KickNotesOptPurge", "Purges", y,
        function() return KN.db.showPurges end, function(v) KN.db.showPurges = v end)
    y = makeCheck(panel, general.content, "KickNotesOptWatch", "Raid WATCH reminders", y,
        function() return KN.db.showWatch end, function(v) KN.db.showWatch = v end)
    y = makeCheck(panel, general.content, "KickNotesOptUnavailable", "Hide rows my current spec cannot personally handle", y,
        function() return KN.db.hideUnavailable end, function(v) KN.db.hideUnavailable = v end)
    finishPage(general, y)

    -- APPEARANCE
    y = -14
    y = makeHeader(appearance.content, "Window", y)
    y = makeCheck(panel, appearance.content, "KickNotesOptMini", "Use Mini view on this character", y,
        function() return KN:IsMiniMode() end,
        function(v)
            KN.charDb.mini = v
            KN.charDb.zipped = false
        end)
    y = makeCheck(panel, appearance.content, "KickNotesOptLocked", "Lock reminder window position", y,
        function() return KN.db.locked end, function(v) KN.db.locked = v end)
    y = makeCheck(panel, appearance.content, "KickNotesOptBossHighlight", "Highlight boss mechanics with a different spell color", y,
        function() return KN.db.highlightBosses end, function(v) KN.db.highlightBosses = v end)
    y = makeColorPicker(panel, appearance.content, "Boss spell color", y,
        function() return KN.db.bossColor end, function(v) KN.db.bossColor = v end)
    y = makeCheck(panel, appearance.content, "KickNotesOptMustStopHighlight", "Highlight MUST STOP mechanics", y,
        function() return KN.db.highlightMustStop end, function(v) KN.db.highlightMustStop = v end)
    y = makeColorPicker(panel, appearance.content, "MUST STOP warning color", y,
        function() return KN.db.mustStopColor end, function(v) KN.db.mustStopColor = v end)
    y = makeText(appearance.content,
        "MUST STOP is intentionally rarer than Essential. It marks mechanics where a missed interrupt or stop can cause deaths, severe group damage, or major pull failure.", y, 64)
    y = makeSlider(panel, appearance.content, "KickNotesScaleSlider", "Window scale", y, 0.75, 1.40, 0.05,
        function() return KN.db.scale end, function(v) KN.db.scale = v end,
        function(v) return string.format("%.2fx", v) end)
    y = makeSlider(panel, appearance.content, "KickNotesMaxHeightSlider", "Maximum window height", y, 260, 800, 20,
        function() return KN.db.maxWindowHeight end, function(v) KN.db.maxWindowHeight = math.floor(v + 0.5) end,
        function(v) return string.format("%d px", math.floor(v + 0.5)) end)

    y = makeHeader(appearance.content, "Full view", y - 2)
    y = makeSlider(panel, appearance.content, "KickNotesFullOpacitySlider", "Background opacity", y, 0.20, 1.0, 0.05,
        function() return KN.db.fullOpacity end, function(v) KN.db.fullOpacity = v end,
        function(v) return string.format("%d%%", math.floor(v * 100 + 0.5)) end)
    y = makeSlider(panel, appearance.content, "KickNotesFullWidthSlider", "Window width", y, 380, 700, 10,
        function() return KN.db.fullWidth end, function(v) KN.db.fullWidth = math.floor(v + 0.5) end,
        function(v) return string.format("%d px", math.floor(v + 0.5)) end)
    y = makeSlider(panel, appearance.content, "KickNotesFullFontSlider", "Text size", y, 10, 18, 1,
        function() return KN.db.fullFontSize end, function(v) KN.db.fullFontSize = math.floor(v + 0.5) end,
        function(v) return string.format("%d px", math.floor(v + 0.5)) end)
    y = makeSlider(panel, appearance.content, "KickNotesFullGapSlider", "Row spacing", y, 0, 12, 1,
        function() return KN.db.fullRowGap end, function(v) KN.db.fullRowGap = math.floor(v + 0.5) end,
        function(v) return string.format("%d px", math.floor(v + 0.5)) end)
    y = makeCheck(panel, appearance.content, "KickNotesOptCompact", "Compact Full-view rows by hiding long explanatory notes", y,
        function() return KN.db.compact end, function(v) KN.db.compact = v end)

    y = makeHeader(appearance.content, "Mini view", y - 2)
    y = makeSlider(panel, appearance.content, "KickNotesMiniOpacitySlider", "Background opacity", y, 0.20, 1.0, 0.05,
        function() return KN.db.miniOpacity end, function(v) KN.db.miniOpacity = v end,
        function(v) return string.format("%d%%", math.floor(v * 100 + 0.5)) end)
    y = makeSlider(panel, appearance.content, "KickNotesMiniWidthSlider", "Window width", y, 240, 460, 10,
        function() return KN.db.miniWidth end, function(v) KN.db.miniWidth = math.floor(v + 0.5) end,
        function(v) return string.format("%d px", math.floor(v + 0.5)) end)
    y = makeSlider(panel, appearance.content, "KickNotesMiniFontSlider", "Text size", y, 9, 17, 1,
        function() return KN.db.miniFontSize end, function(v) KN.db.miniFontSize = math.floor(v + 0.5) end,
        function(v) return string.format("%d px", math.floor(v + 0.5)) end)
    y = makeSlider(panel, appearance.content, "KickNotesMiniGapSlider", "Row spacing", y, 0, 8, 1,
        function() return KN.db.miniRowGap end, function(v) KN.db.miniRowGap = math.floor(v + 0.5) end,
        function(v) return string.format("%d px", math.floor(v + 0.5)) end)
    y = makeText(appearance.content,
        "Mini view wraps long spell and ability names instead of clipping them. Boss mechanics get a [B] marker in addition to the configurable boss color.", y, 64)
    makeButton(appearance.content, "Preview current", PAGE_MARGIN, y, 130, function() KN:HandleSlash("show") end)
    makeButton(appearance.content, "Reset position", PAGE_MARGIN + 140, y, 130, function() KN:ResetPosition() end)
    y = y - 42
    finishPage(appearance, y)

    -- LEARNING
    y = -14
    y = makeHeader(learning.content, "Learned mechanics", y)
    y = makeText(learning.content,
        "Right-click any mechanic in the KickNotes window when you feel you know it. Learned state is account-wide, so learning a dungeon on one character carries across to your alts.", y, 78)
    y = makeCheck(panel, learning.content, "KickNotesOptLearningEnabled", "Enable learned-mechanics tracking", y,
        function() return KN.db.learningEnabled end,
        function(v) KN.db.learningEnabled = v end)
    y = makeCycle(panel, learning.content, "KickNotesLearnedModeCycle", "When a mechanic is learned", y, {
        { value = "dim",  label = "Dim it, but keep showing it" },
        { value = "hide", label = "Hide it from reminder lists" },
        { value = "show", label = "Show it normally" },
    }, function() return KN.db.learnedMode end, function(v) KN.db.learnedMode = v end)
    y = makeSlider(panel, learning.content, "KickNotesLearnedOpacitySlider", "Learned-row opacity (Dim mode)", y, 0.15, 0.80, 0.05,
        function() return KN.db.learnedOpacity end, function(v) KN.db.learnedOpacity = v end,
        function(v) return string.format("%d%%", math.floor(v * 100 + 0.5)) end)
    y = makeText(learning.content,
        "A learned mechanic gets a ✓ marker. Hovering any row shows its learning state and the right-click shortcut. MUST STOP and boss information remain attached to the mechanic even after it is learned.", y, 78)

    local learningSummary = learning.content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    learningSummary:SetPoint("TOPLEFT", PAGE_MARGIN, y)
    learningSummary:SetWidth(620)
    learningSummary:SetJustifyH("LEFT")
    learningSummary:SetWordWrap(true)
    learningSummary.refresh = function()
        local totalLearned = KN:GetLearnedCount()
        local record = KN.currentContent or KN:GetPreviewRecord()
        local currentLearned = record and KN:GetLearnedCount(record) or 0
        if record then
            learningSummary:SetText(string.format("Learned: %d total  •  %d in %s", totalLearned, currentLearned, record.name))
        else
            learningSummary:SetText(string.format("Learned: %d total", totalLearned))
        end
    end
    learningSummary.refresh()
    addControl(panel, learningSummary)
    y = y - 38

    if StaticPopupDialogs then
        StaticPopupDialogs.KICKNOTES_RESET_CURRENT_LEARNING = StaticPopupDialogs.KICKNOTES_RESET_CURRENT_LEARNING or {
            text = "Reset learned mechanics for the current KickNotes dungeon or raid?",
            button1 = YES,
            button2 = NO,
            OnAccept = function()
                local record = KN.currentContent or KN:GetPreviewRecord()
                if record then
                    local removed = KN:ResetLearnedMechanics(record)
                    learningSummary.refresh()
                    KN:Print(string.format("Reset %d learned mechanic(s) for %s.", removed, record.name))
                end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopupDialogs.KICKNOTES_RESET_ALL_LEARNING = StaticPopupDialogs.KICKNOTES_RESET_ALL_LEARNING or {
            text = "Reset ALL learned KickNotes mechanics across every dungeon and raid?",
            button1 = YES,
            button2 = NO,
            OnAccept = function()
                local removed = KN:ResetLearnedMechanics()
                learningSummary.refresh()
                KN:Print(string.format("Reset %d learned mechanic(s).", removed))
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end

    makeButton(learning.content, "Reset current content", PAGE_MARGIN, y, 160, function()
        if StaticPopup_Show then
            StaticPopup_Show("KICKNOTES_RESET_CURRENT_LEARNING")
        else
            local record = KN.currentContent or KN:GetPreviewRecord()
            if record then KN:ResetLearnedMechanics(record); learningSummary.refresh() end
        end
    end)
    makeButton(learning.content, "Reset all learned", PAGE_MARGIN + 170, y, 150, function()
        if StaticPopup_Show then
            StaticPopup_Show("KICKNOTES_RESET_ALL_LEARNING")
        else
            KN:ResetLearnedMechanics()
            learningSummary.refresh()
        end
    end)
    y = y - 46
    finishPage(learning, y)

    -- CONTENT
    y = -14
    y = makeHeader(content.content, "Content packs", y)
    y = makeCheck(panel, content.content, "KickNotesOptDungeons", "Enable dungeon reminders", y,
        function() return KN.db.showDungeons end, function(v) KN.db.showDungeons = v end)
    y = makeCheck(panel, content.content, "KickNotesOptRaids", "Enable raid reminders", y,
        function() return KN.db.showRaids end, function(v) KN.db.showRaids = v end)
    y = makeCheck(panel, content.content, "KickNotesOptOld", "Enable older-content data packs when installed", y,
        function() return KN.db.enableOlderContent end, function(v) KN.db.enableOlderContent = v end)
    y = makeText(content.content,
        "Older-content packs are opt-in. This build currently ships the curated Midnight Season 2 pack; future older-season packs can plug into the same content system.", y, 70)

    local dungeonRecords = self:GetCurrentSeasonRecords("dungeon")
    local raidRecords = self:GetCurrentSeasonRecords("raid")

    y = makeHeader(content.content, "Midnight Season 2 dungeons", y)
    for index, record in ipairs(dungeonRecords) do
        local currentRecord = record
        y = makeCheck(panel, content.content, "KickNotesContentDungeon" .. index, currentRecord.name, y,
            function() return KN:IsContentEnabled(currentRecord) end,
            function(v) KN:SetContentEnabled(currentRecord.id, v) end)
    end

    y = makeHeader(content.content, "Midnight Season 2 raids", y - 4)
    for index, record in ipairs(raidRecords) do
        local currentRecord = record
        y = makeCheck(panel, content.content, "KickNotesContentRaid" .. index, currentRecord.name, y,
            function() return KN:IsContentEnabled(currentRecord) end,
            function(v) KN:SetContentEnabled(currentRecord.id, v) end)
    end
    finishPage(content, y)

    -- PREVIEW / TEST
    y = -14
    y = makeHeader(preview.content, "Preview / Test", y)
    y = makeText(preview.content,
        "Preview any current-season dungeon or raid using the abilities your currently logged-in character actually knows. This avoids pretending another spec has tools it may not have talented.", y, 76)

    local previewRecords = self:GetPreviewRecords()
    local previewChoices = {}
    for _, record in ipairs(previewRecords) do
        previewChoices[#previewChoices + 1] = { value = record.id, label = record.name }
    end
    if #previewChoices == 0 then
        previewChoices[1] = { value = "", label = "No content registered" }
    end

    y = makeCycle(panel, preview.content, "KickNotesPreviewCycle", "Preview content (left click next, right click previous)", y,
        previewChoices,
        function() return KN.db.previewRecordID end,
        function(v) KN.db.previewRecordID = v end)

    local classLabel = preview.content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    classLabel:SetPoint("TOPLEFT", PAGE_MARGIN, y)
    classLabel:SetText("Preview as: " .. self:GetPlayerSpecLabel())
    y = y - 34

    makeButton(preview.content, "Show Full", PAGE_MARGIN, y, 120, function()
        local record = KN:GetPreviewRecord()
        if record then
            KN.charDb.mini = false
            KN.charDb.zipped = false
            KN:ShowTestRecord(record)
        end
    end)
    makeButton(preview.content, "Show Mini", PAGE_MARGIN + 130, y, 120, function()
        local record = KN:GetPreviewRecord()
        if record then
            KN.charDb.mini = true
            KN.charDb.zipped = false
            KN:ShowTestRecord(record)
        end
    end)
    makeButton(preview.content, "Zip / Restore", PAGE_MARGIN + 260, y, 120, function()
        KN:ToggleZip()
    end)
    y = y - 48

    y = makeHeader(preview.content, "Slash commands", y)
    y = makeText(preview.content,
        "/kn help shows the complete command list. Useful shortcuts: /kn test <dungeon>, /kn mini, /kn full, /kn zip, /kn learning, /kn learning dim|hide|show, /kn options and /kn reset.", y, 90)
    finishPage(preview, y)

    panel:SetScript("OnShow", function()
        showPage(panel.activePage or "general")
        refreshControls(panel)
    end)
    showPage("general")

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, "KickNotes")
        Settings.RegisterAddOnCategory(category)
        self.settingsCategory = category
    end
end
