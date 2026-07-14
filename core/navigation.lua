--------------------------------------------------
-- WeintCodex :: Navigation (Tab System)
--------------------------------------------------

WeintCodex.Navigation = {}

local C = WeintCodex.Colors
local activeTab = nil

local tabs = {
    { id = "charakter",  label = "|TInterface\\Icons\\Achievement_Character_Human_Male:14|t Charakter" },
    { id = "bossguides", label = "|TInterface\\Icons\\Achievement_Boss_LichKing:14|t Bossguides" },
    { id = "raids",      label = "|TInterface\\Icons\\Ability_Warrior_BattleShout:14|t Raids" },
    { id = "materials",  label = "|TInterface\\Icons\\INV_Crate_01:14|t Materialien" },
    { id = "calendar",   label = "|TInterface\\Icons\\INV_Misc_PocketWatch_01:14|t Kalender" },
    { id = "weakauras",  label = "|TInterface\\Icons\\Spell_Holy_MagicalSentry:14|t WeakAuras" },
    { id = "import",     label = "|TInterface\\Icons\\INV_Misc_Note_01:14|t Import" },
}

local tabButtons = {}
local offsetX    = 10

local function SetTabActive(btn, isActive)
    if isActive then
        btn._bg:SetColorTexture(C.purple[1], C.purple[2], C.purple[3], 0.22)
        btn._underline:SetColorTexture(C.purple[1], C.purple[2], C.purple[3], 1.0)
        btn._label:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
    else
        btn._bg:SetColorTexture(0, 0, 0, 0)
        btn._underline:SetColorTexture(0, 0, 0, 0)
        btn._label:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
    end
end

for _, tabDef in ipairs(tabs) do
    local btn = CreateFrame("Button", nil, WeintCodex.TabBar)

    btn:SetSize(100, 40)
    btn:SetPoint("TOPLEFT", WeintCodex.TabBar, "TOPLEFT", 0, 0)

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(btn)
    bg:SetColorTexture(0, 0, 0, 0)
    btn._bg = bg

    local underline = btn:CreateTexture(nil, "OVERLAY")
    underline:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
    underline:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
    underline:SetHeight(2)
    underline:SetColorTexture(0, 0, 0, 0)
    btn._underline = underline

    local lbl = btn:CreateFontString(nil, "OVERLAY")
    lbl:SetAllPoints(btn)
    lbl:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    lbl:SetText(tabDef.label)
    lbl:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
    btn._label = lbl

    -- Benachrichtigungspunkt (standardmaessig versteckt, siehe SetTabBadge)
    local dot = btn:CreateTexture(nil, "OVERLAY")
    dot:SetSize(6, 6)
    dot:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -8, -6)
    dot:SetColorTexture(C.accentDot[1], C.accentDot[2], C.accentDot[3], 1.0)
    dot:Hide()
    btn._dot = dot

    btn:SetScript("OnEnter", function(self)
        if activeTab ~= tabDef.id then
            self._bg:SetColorTexture(C.purple[1], C.purple[2], C.purple[3], 0.10)
            self._label:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
        end
    end)
    btn:SetScript("OnLeave", function(self)
        if activeTab ~= tabDef.id then
            self._bg:SetColorTexture(0, 0, 0, 0)
            self._label:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
        end
    end)
    btn:SetScript("OnClick", function(self)
        if activeTab == tabDef.id then return end
        for _, b in ipairs(tabButtons) do SetTabActive(b, false) end
        SetTabActive(self, true)
        activeTab = tabDef.id
        WeintCodex.Navigation.SwitchTo(tabDef.id)
    end)

    tabButtons[tabDef.id] = btn
    table.insert(tabButtons, btn)
end

-- Zeigt/versteckt den Benachrichtigungspunkt eines Tabs anhand echten Zustands
-- (z.B. Materialengpass, offene Sync-Warteschlange) - siehe ShowHome().
function WeintCodex.Navigation.SetTabBadge(tabId, on)
    local btn = tabButtons[tabId]
    if not btn or not btn._dot then return end
    if on then btn._dot:Show() else btn._dot:Hide() end
end

local function UpdateTabLayout()

local tabWidth =
(WeintCodex.TabBar:GetWidth() - 20) / #tabs

local x = 10

for _, btn in ipairs(tabButtons) do
    btn:SetWidth(tabWidth)
    btn:ClearAllPoints()
    btn:SetPoint(
        "TOPLEFT",
        WeintCodex.TabBar,
        "TOPLEFT",
        x,
        0
    )

    x = x + tabWidth
    end
    end

    WeintCodex.TabBar:SetScript(
        "OnSizeChanged",
        UpdateTabLayout
    )

    UpdateTabLayout()
--------------------------------------------------
-- Sidebar builder
--------------------------------------------------

local sidebarItems  = {}
local sidebarGroups = {}

function WeintCodex.Navigation.ClearSidebar()
    for _, item in ipairs(sidebarItems) do item:Hide() end
    for _, grp  in ipairs(sidebarGroups) do grp:Hide()  end
    wipe(sidebarItems)
    wipe(sidebarGroups)
    WeintCodex.SidebarHeader:SetText("|cff4B4060— NAVIGATION —|r")
end

-- Build flat list of items
function WeintCodex.Navigation.BuildSidebar(sectionTitle, items)
    WeintCodex.Navigation.ClearSidebar()
    WeintCodex.SidebarHeader:SetText("|cff8B5CF6" .. (sectionTitle or "") .. "|r")

    local sidebar  = WeintCodex.Sidebar
    local offsetY  = -34

    for _, itemDef in ipairs(items) do
        local isGroup = itemDef.isGroup

        if isGroup then
            local lbl = sidebar:CreateFontString(nil, "OVERLAY")
            lbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
            lbl:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 10, offsetY)
            lbl:SetText("|cff5B4880" .. (itemDef.label or "") .. "|r")
            lbl:SetWidth(192)
            table.insert(sidebarGroups, lbl)
            offsetY = offsetY - 18
        else
            local indent = itemDef.indent and 20 or 5

            local btn = CreateFrame("Button", nil, sidebar)
            btn:SetHeight(28)
            -- Rechts relativ zur Sidebar verankert statt fester Breite, damit
            -- eingerueckte Eintraege (indent=20) nicht ueber den rechten Rand
            -- der Sidebar hinaus in das Hauptfeld hineinragen.
            btn:SetPoint("TOPLEFT",  sidebar, "TOPLEFT",  indent, offsetY)
            btn:SetPoint("TOPRIGHT", sidebar, "TOPRIGHT", -5,     offsetY)

            local bg = btn:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(btn)
            bg:SetColorTexture(0, 0, 0, 0)
            btn._bg = bg

            local accent = btn:CreateTexture(nil, "OVERLAY")
            accent:SetSize(3, 28)
            accent:SetPoint("LEFT", btn, "LEFT", 0, 0)
            accent:SetColorTexture(C.purple[1], C.purple[2], C.purple[3], 0.0)
            btn._accent = accent

            local iconOffsetX = 12

            if itemDef.portrait then
                local iconBox = btn:CreateTexture(nil, "OVERLAY")
                iconBox:SetSize(20, 20)
                iconBox:SetPoint("LEFT", btn, "LEFT", 8, 0)
                iconBox:SetTexture("Interface\\AddOns\\WeintCodex\\" .. itemDef.portrait)
                iconOffsetX = 34
            elseif itemDef.iconColor then
                local iconBox = btn:CreateTexture(nil, "OVERLAY")
                iconBox:SetSize(16, 16)
                iconBox:SetPoint("LEFT", btn, "LEFT", 12, 0)
                iconBox:SetColorTexture(
                    itemDef.iconColor[1],
                    itemDef.iconColor[2],
                    itemDef.iconColor[3],
                    0.85
                )
                iconOffsetX = 34
            end

            local lbl = btn:CreateFontString(nil, "OVERLAY")
            lbl:SetPoint("LEFT",  btn, "LEFT",  iconOffsetX, 0)
            lbl:SetPoint("RIGHT", btn, "RIGHT", -8, 0)
            lbl:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
            lbl:SetText(itemDef.label or "")
            lbl:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
            lbl:SetJustifyH("LEFT")
            btn._label = lbl

            local function SetActive(self, on)
                if on then
                    self._bg:SetColorTexture(C.purple[1], C.purple[2], C.purple[3], 0.20)
                    self._accent:SetColorTexture(C.purple[1], C.purple[2], C.purple[3], 1.0)
                    self._label:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
                else
                    self._bg:SetColorTexture(0, 0, 0, 0)
                    self._accent:SetColorTexture(C.purple[1], C.purple[2], C.purple[3], 0.0)
                    self._label:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
                end
            end
            btn.SetActive = SetActive

            btn:SetScript("OnEnter", function(self)
                if not self._isActive then
                    self._bg:SetColorTexture(C.purple[1], C.purple[2], C.purple[3], 0.10)
                end
            end)
            btn:SetScript("OnLeave", function(self)
                if not self._isActive then
                    self._bg:SetColorTexture(0, 0, 0, 0)
                end
            end)
            btn:SetScript("OnClick", function(self)
                for _, s in ipairs(sidebarItems) do
                    s._isActive = false
                    s:SetActive(false)
                end
                self._isActive = true
                self:SetActive(true)
                if itemDef.onClick then itemDef.onClick() end
            end)

            table.insert(sidebarItems, btn)
            offsetY = offsetY - 30
        end
    end
end

-- Activate first sidebar item automatically
function WeintCodex.Navigation.ActivateFirst()
    if sidebarItems[1] then
        sidebarItems[1]:Click()
    end
end

--------------------------------------------------
-- Content Panel cleaner
--------------------------------------------------

local function ClearContentPanel()
    local cp = WeintCodex.ContentPanel
    if not cp then
        print("WeintCodex: ContentPanel fehlt")
        return
    end
    for _, child in pairs({cp:GetChildren()}) do
        child:Hide()
    end
end

--------------------------------------------------
-- Tab switching
--------------------------------------------------

function WeintCodex.Navigation.SwitchTo(tabId)
    WeintCodex.Navigation.ClearSidebar()
    ClearContentPanel()

    if tabId == "charakter" then
        if WeintCodex.Charakter and WeintCodex.Charakter.Show then
            WeintCodex.Charakter.Show()
        end
    elseif tabId == "bossguides" then
        if WeintCodex.BossGuides and WeintCodex.BossGuides.Show then
            WeintCodex.BossGuides.Show()
        end
    elseif tabId == "raids" then
        if WeintCodex.Raids and WeintCodex.Raids.Show then
            WeintCodex.Raids.Show()
        end
    elseif tabId == "materials" then
        if WeintCodex.Materials and WeintCodex.Materials.Show then
            WeintCodex.Materials.Show()
        end
    elseif tabId == "calendar" then
        if WeintCodex.Calendar and WeintCodex.Calendar.Show then
            WeintCodex.Calendar.Show()
        end
    elseif tabId == "weakauras" then
        if WeintCodex.WeakAuras and WeintCodex.WeakAuras.Show then
            WeintCodex.WeakAuras.Show()
        end
    elseif tabId == "import" then
        if WeintCodex.Sync and WeintCodex.Sync.ShowImportDialog then
            WeintCodex.Sync.ShowImportDialog()
        end
    end
end

--------------------------------------------------
-- Placeholder
--------------------------------------------------

local placeholderFrame = nil

function WeintCodex.Navigation.ShowPlaceholder(title, msg)
    ClearContentPanel()
    if not placeholderFrame then
        local pf = CreateFrame("Frame", nil, WeintCodex.ContentPanel)
        pf:SetAllPoints(WeintCodex.ContentPanel)

        local t = pf:CreateFontString(nil, "OVERLAY")
        t:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
        t:SetPoint("CENTER", pf, "CENTER", 0, 30)
        t:SetTextColor(C.purple[1], C.purple[2], C.purple[3])
        pf._title = t

        local sub = pf:CreateFontString(nil, "OVERLAY")
        sub:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        sub:SetPoint("TOP", t, "BOTTOM", 0, -12)
        sub:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
        sub:SetWidth(600)
        sub:SetJustifyH("CENTER")
        pf._sub = sub

        placeholderFrame = pf
    end
    placeholderFrame._title:SetText(title or "")
    placeholderFrame._sub:SetText(msg or "")
    placeholderFrame:Show()
end

--------------------------------------------------
-- Home Dashboard
--------------------------------------------------

local homeFrame = nil

-- Datums-Hilfe (gleiches Format wie modules/calendar.lua ParseDate())
local function ParseYMD(dateStr)
    if not dateStr or dateStr == "" then return nil end
    local y, m, d = dateStr:match("(%d%d%d%d)-(%d%d)-(%d%d)")
    if y then return tonumber(y), tonumber(m), tonumber(d) end
    d, m, y = dateStr:match("(%d%d?)%.(%d%d?)%.(%d%d%d%d)")
    if d then return tonumber(y), tonumber(m), tonumber(d) end
    return nil
end

local function DateKey(y, m, d)
    return y * 10000 + m * 100 + d
end

-- Naechster bevorstehender Raidtermin (Mittwoch/Donnerstag), oder Fallback-Text
local function GetNextRaidLabel()
    local sd = WeintCodex.SavedData
    local today = date("*t")
    local todayKey = DateKey(today.year, today.month, today.day)

    local candidates = {}
    local function Consider(raidData, dayName)
        if not raidData or not raidData.date then return end
        local y, m, d = ParseYMD(raidData.date)
        if not y then return end
        local key = DateKey(y, m, d)
        if key >= todayKey then
            table.insert(candidates, { key = key, dayName = dayName, data = raidData })
        end
    end
    Consider(sd and sd.raidWednesday, "Mittwoch")
    Consider(sd and sd.raidThursday,  "Donnerstag")

    if #candidates == 0 then
        return WeintCodex.ColorText("textDim", "Keine Anmeldung")
    end

    table.sort(candidates, function(a, b) return a.key < b.key end)
    local n = candidates[1]
    return n.dayName .. " · " .. n.data.date
end

local function GetSignupCount()
    local sd = WeintCodex.SavedData
    local total = 0
    if sd and sd.raidWednesday and sd.raidWednesday.players then
        total = total + #sd.raidWednesday.players
    end
    if sd and sd.raidThursday and sd.raidThursday.players then
        total = total + #sd.raidThursday.players
    end
    return total
end

-- Anzahl Materialien unter 30% des Sollbestands (gleicher Schwellwert wie
-- modules/materials.lua); zweiter Rueckgabewert = false wenn noch nie importiert.
local function GetMaterialShortageCount()
    local sd      = WeintCodex.SavedData
    local matData = sd and sd.materialData
    if not matData or not matData.items or #matData.items == 0 then
        return 0, false
    end
    local shortages = 0
    for _, item in ipairs(matData.items) do
        local amount = tonumber(item.count)  or 0
        local target = tonumber(item.target) or 0
        if target > 0 and (amount / target) < 0.30 then
            shortages = shortages + 1
        end
    end
    return shortages, true
end

local function GetQueueCount()
    if WeintCodex.Companion and WeintCodex.Companion.GetQueueSize then
        return WeintCodex.Companion.GetQueueSize()
    end
    return 0
end

-- Aktiviert einen Tab so, als haette der Nutzer direkt darauf geklickt
-- (Tab-Leiste + Sidebar ziehen korrekt mit).
local function GoToTab(tabId)
    local btn = tabButtons[tabId]
    if btn then btn:Click() end
end

-- Modul-Kacheln des Dashboards (gleiche Icons wie die Tab-Leiste oben)
local dashboardTiles = {
    { id = "charakter",  icon = "Interface\\Icons\\Achievement_Character_Human_Male", title = "Charakter",   desc = "Enchants, Stats & Twink-Verwaltung" },
    { id = "bossguides", icon = "Interface\\Icons\\Achievement_Boss_LichKing",        title = "Bossguides",  desc = "Rollen-Tipps für alle Bosse" },
    { id = "raids",      icon = "Interface\\Icons\\Ability_Warrior_BattleShout",      title = "Raids",       desc = "Anmeldungen Mittwoch & Donnerstag" },
    { id = "materials",  icon = "Interface\\Icons\\INV_Crate_01",                     title = "Materialien", desc = "Gildenbank-Übersicht" },
    { id = "calendar",   icon = "Interface\\Icons\\INV_Misc_PocketWatch_01",          title = "Kalender",    desc = "Termine & Ingame-Einladungen" },
    { id = "weakauras",  icon = "Interface\\Icons\\Spell_Holy_MagicalSentry",         title = "WeakAuras",   desc = "1-Klick-Import nach Kategorie" },
    { id = "import",     icon = "Interface\\Icons\\INV_Misc_Note_01",                 title = "Import",      desc = "Daten vom Discord-Bot importieren" },
}

function WeintCodex.ShowHome()
    ClearContentPanel()
    WeintCodex.Navigation.ClearSidebar()
    for _, b in ipairs(tabButtons) do SetTabActive(b, false) end
    activeTab = nil

    if not homeFrame then
        local hf = CreateFrame("Frame", nil, WeintCodex.ContentPanel)
        hf:SetAllPoints(WeintCodex.ContentPanel)

        ------------------------------------------------
        -- A. Kompakte Hero-Leiste
        ------------------------------------------------
        local hero = CreateFrame("Frame", nil, hf)
        hero:SetHeight(72)
        hero:SetPoint("TOPLEFT",  hf, "TOPLEFT",  0, 0)
        hero:SetPoint("TOPRIGHT", hf, "TOPRIGHT", 0, 0)

        local wordmark = hero:CreateFontString(nil, "OVERLAY")
        wordmark:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
        wordmark:SetPoint("TOPLEFT", hero, "TOPLEFT", 20, -14)
        wordmark:SetText(WeintCodex.ColorText("logoPurple", "Weint") .. WeintCodex.ColorText("logoGreen", "Codex"))

        local sub = hero:CreateFontString(nil, "OVERLAY")
        sub:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        sub:SetPoint("TOPLEFT", wordmark, "BOTTOMLEFT", 0, -4)
        sub:SetText(WeintCodex.ColorText("textDim", "Raid Guide & Intelligence System"))

        local heroDiv = hero:CreateTexture(nil, "OVERLAY")
        heroDiv:SetHeight(1)
        heroDiv:SetPoint("BOTTOMLEFT",  hero, "BOTTOMLEFT",  20, 0)
        heroDiv:SetPoint("BOTTOMRIGHT", hero, "BOTTOMRIGHT", -20, 0)
        heroDiv:SetColorTexture(C.hairline[1], C.hairline[2], C.hairline[3], C.hairline[4])

        local importBtn = WeintCodex.CreateCard(hero, { width = 110, height = 28, buttonStyle = true })
        importBtn:SetPoint("TOPRIGHT", hero, "TOPRIGHT", -20, -14)
        local importLbl = importBtn:CreateFontString(nil, "OVERLAY")
        importLbl:SetAllPoints(importBtn)
        importLbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        importLbl:SetJustifyH("CENTER")
        importLbl:SetText("Import")
        importLbl:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
        importBtn:SetScript("OnClick", function()
            if WeintCodex.Sync and WeintCodex.Sync.ShowImportDialog then
                WeintCodex.Sync.ShowImportDialog()
            end
        end)
        importBtn:SetScript("OnEnter", function(self) self:SetSurface("surface3") end)
        importBtn:SetScript("OnLeave", function(self) self:SetSurface("surface2") end)

        local calBtn = WeintCodex.CreateCard(hero, { width = 140, height = 28, buttonStyle = true })
        calBtn:SetPoint("TOPRIGHT", importBtn, "TOPLEFT", -10, 0)
        local calLbl = calBtn:CreateFontString(nil, "OVERLAY")
        calLbl:SetAllPoints(calBtn)
        calLbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        calLbl:SetJustifyH("CENTER")
        calLbl:SetText("Kalender öffnen")
        calLbl:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
        calBtn:SetScript("OnClick", function() GoToTab("calendar") end)
        calBtn:SetScript("OnEnter", function(self) self:SetSurface("surface3") end)
        calBtn:SetScript("OnLeave", function(self) self:SetSurface("surface2") end)

        ------------------------------------------------
        -- B. Statistik-Reihe
        ------------------------------------------------
        local statRow = CreateFrame("Frame", nil, hf)
        statRow:SetHeight(70)
        statRow:SetPoint("TOPLEFT",  hero, "BOTTOMLEFT",  20, -18)
        statRow:SetPoint("TOPRIGHT", hero, "BOTTOMRIGHT", -20, -18)

        local STAT_W, STAT_GAP = 190, 14
        local statDefs = {
            { key = "raid",      label = "Nächster Raid",      tabId = "raids" },
            { key = "signups",   label = "Anmeldungen",         tabId = "raids" },
            { key = "materials", label = "Materialien",         tabId = "materials" },
            { key = "queue",     label = "Sync-Warteschlange",  tabId = "import" },
        }

        local statCards = {}
        for i, def in ipairs(statDefs) do
            local card = WeintCodex.CreateCard(statRow, { width = STAT_W, height = 70, buttonStyle = true })
            card:SetPoint("TOPLEFT", statRow, "TOPLEFT", (i - 1) * (STAT_W + STAT_GAP), 0)

            local lbl = card:CreateFontString(nil, "OVERLAY")
            lbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
            lbl:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -10)
            lbl:SetText(WeintCodex.ColorText("textDim", def.label))

            local val = card:CreateFontString(nil, "OVERLAY")
            val:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
            val:SetPoint("TOPLEFT",  lbl, "BOTTOMLEFT", 0, -8)
            val:SetPoint("RIGHT",    card, "RIGHT", -12, 0)
            val:SetJustifyH("LEFT")
            val:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])

            card:SetScript("OnClick", function() GoToTab(def.tabId) end)
            card:SetScript("OnEnter", function(self) self:SetSurface("surface3") end)
            card:SetScript("OnLeave", function(self) self:SetSurface("surface2") end)

            card._valueStr = val
            statCards[def.key] = card
        end

        ------------------------------------------------
        -- C. Modul-Kachel-Raster
        ------------------------------------------------
        local gridLabel = hf:CreateFontString(nil, "OVERLAY")
        gridLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        gridLabel:SetPoint("TOPLEFT", statRow, "BOTTOMLEFT", 0, -22)
        gridLabel:SetText(WeintCodex.ColorText("textDim", "— BEREICHE —"))

        local grid = CreateFrame("Frame", nil, hf)
        grid:SetPoint("TOPLEFT",  gridLabel, "BOTTOMLEFT",  0, -10)
        grid:SetPoint("TOPRIGHT", statRow,   "BOTTOMRIGHT", 0, -32)

        local TILE_W, TILE_H, TILE_GAP, COLUMNS = 260, 84, 16, 3

        for i, tile in ipairs(dashboardTiles) do
            local col = (i - 1) % COLUMNS
            local row = math.floor((i - 1) / COLUMNS)

            local card = WeintCodex.CreateCard(grid, { width = TILE_W, height = TILE_H, buttonStyle = true })
            card:SetPoint("TOPLEFT", grid, "TOPLEFT", col * (TILE_W + TILE_GAP), -row * (TILE_H + TILE_GAP))

            local icon = card:CreateFontString(nil, "OVERLAY")
            icon:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
            icon:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -12)
            icon:SetText(WeintCodex.Icon(tile.icon, 22))

            local title = card:CreateFontString(nil, "OVERLAY")
            title:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
            title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -2)
            title:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
            title:SetText(tile.title)

            local desc = card:CreateFontString(nil, "OVERLAY")
            desc:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
            desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
            desc:SetPoint("RIGHT", card, "RIGHT", -12, 0)
            desc:SetJustifyH("LEFT")
            desc:SetText(WeintCodex.ColorText("textDim", tile.desc))

            card:SetScript("OnClick", function() GoToTab(tile.id) end)
            card:SetScript("OnEnter", function(self) self:SetSurface("surface3") end)
            card:SetScript("OnLeave", function(self) self:SetSurface("surface2") end)
        end

        ------------------------------------------------
        -- D. Footer-Hinweis
        ------------------------------------------------
        local hint = hf:CreateFontString(nil, "OVERLAY")
        hint:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        hint:SetPoint("BOTTOM", hf, "BOTTOM", 0, 10)
        hint:SetText(WeintCodex.ColorText("textDim", "/wc  •  /wc import"))

        hf._statCards = statCards

        homeFrame = hf
    end

    -- Dynamische Werte bei JEDEM Aufruf neu berechnen, nicht nur beim
    -- ersten Bau der Struktur - siehe Kommentar oben an homeFrame.
    local matShortage, hasMatScan = GetMaterialShortageCount()
    local queueCount = GetQueueCount()

    homeFrame._statCards.raid._valueStr:SetText(GetNextRaidLabel())
    homeFrame._statCards.signups._valueStr:SetText(tostring(GetSignupCount()))

    if not hasMatScan then
        homeFrame._statCards.materials._valueStr:SetText(WeintCodex.ColorText("textDim", "Kein Scan"))
    elseif matShortage > 0 then
        homeFrame._statCards.materials._valueStr:SetText(WeintCodex.ColorText("danger", matShortage .. " Engpässe"))
    else
        homeFrame._statCards.materials._valueStr:SetText(WeintCodex.ColorText("success", "Alles im Soll"))
    end

    homeFrame._statCards.queue._valueStr:SetText(
        queueCount > 0
            and WeintCodex.ColorText("warning", queueCount .. " ausstehend")
            or  WeintCodex.ColorText("textDim", "Keine")
    )

    WeintCodex.Navigation.SetTabBadge("materials", hasMatScan and matShortage > 0)
    WeintCodex.Navigation.SetTabBadge("import", queueCount > 0)

    homeFrame:Show()
end

function WeintCodex.ResetToHome()
    WeintCodex.ShowHome()
end
