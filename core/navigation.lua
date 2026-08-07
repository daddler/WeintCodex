--------------------------------------------------
-- WeintCodex :: Navigation (Tab System)
--------------------------------------------------

WeintCodex.Navigation = {}

local C = WeintCodex.Colors
local activeTab = nil

-- Icon-Rail Definition: id, flaches Linien-Icon (eigene Textur statt echtem
-- Blizzard-Icon, siehe media/icons/ - Vektorpfade kann WoW zur Laufzeit nicht
-- rendern, deshalb werden die Icons einmalig vorgerendert) und Tooltip-Beschriftung.
--
-- feature: benötigte Freigabe aus dem Zugriffsprofil (core/access.lua). Nur
-- Tabs, deren gesamter Inhalt gildenintern ist, tragen eine - die übrigen
-- gaten innerhalb der Seite, damit ihr neutraler Teil offen bleibt.
local ICON_PATH = "Interface\\AddOns\\WeintCodex\\media\\icons\\"
local tabs = {
    { id = "charakter",  icon = ICON_PATH .. "nav_charakter",  tooltip = "Charakter" },
    { id = "bossguides", icon = ICON_PATH .. "nav_bossguides", tooltip = "Bossguides" },
    { id = "raids",      icon = ICON_PATH .. "nav_raids",      tooltip = "Raids",
      feature = "raids.view" },
    { id = "materials",  icon = ICON_PATH .. "nav_materials",  tooltip = "Materialien",
      feature = "materials.view" },
    { id = "calendar",   icon = ICON_PATH .. "nav_calendar",   tooltip = "Kalender",
      feature = "calendar.view" },
    { id = "weakauras",  icon = ICON_PATH .. "nav_weakauras",  tooltip = "WeakAuras" },
    { id = "weinttv",    icon = ICON_PATH .. "nav_weinttv",    tooltip = "WeintTV" },
    { id = "import",     icon = ICON_PATH .. "nav_import",     tooltip = "Import" },
}

-- tabId -> Feature, einzige Quelle bleibt die tabs-Tabelle oben.
local tabFeature = {}

function WeintCodex.Navigation.GetTabFeatures()
    return tabFeature
end

-- Kurzform mit Fallback: ohne geladenes Access-Modul ist alles erlaubt.
local function Can(featureKey)
    if not (WeintCodex.Access and WeintCodex.Access.Can) then return true end
    return WeintCodex.Access.Can(featureKey)
end

local function Locked(tabId)
    local feature = tabFeature[tabId]
    return feature ~= nil and not Can(feature)
end

local RAIL_ICON_GLYPH = 20

local tabButtons = {}

local RAIL_ICON_SIZE  = 44
local RAIL_ICON_GAP   = 6
local RAIL_ICON_START = -64 -- unterhalb des Marken-Badges (siehe core/ui.lua)

-- Icon-Farbe an EINER Stelle: aktiv > gesperrt > Hover > Ruhe. Ohne diesen
-- gemeinsamen Weg würde jedes der drei Skripte (SetTabActive, OnEnter,
-- OnLeave) die Sperr-Abdunklung beim nächsten Ereignis überschreiben.
local function TintIcon(btn, isActive, isHover)
    local col
    if btn._locked then
        col = isActive and C.textDim or C.textGhost
    elseif isActive then
        col = C.textBright
    elseif isHover then
        col = C.textMuted
    else
        col = C.textDim
    end
    btn._icon:SetVertexColor(col[1], col[2], col[3])
end

local function SetTabActive(btn, isActive)
    if isActive then
        btn._bg:SetColorTexture(C.surface3[1], C.surface3[2], C.surface3[3], 1.0)
        btn._bar:SetColorTexture(C.purple[1], C.purple[2], C.purple[3], 1.0)
    else
        btn._bg:SetColorTexture(0, 0, 0, 0)
        btn._bar:SetColorTexture(0, 0, 0, 0)
    end
    TintIcon(btn, isActive, false)
end

for i, tabDef in ipairs(tabs) do
    local btn = CreateFrame("Button", nil, WeintCodex.IconRail)
    btn:SetSize(RAIL_ICON_SIZE, RAIL_ICON_SIZE)
    btn:SetPoint("TOP", WeintCodex.IconRail, "TOP", 0, RAIL_ICON_START - (i - 1) * (RAIL_ICON_SIZE + RAIL_ICON_GAP))

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(btn)
    bg:SetColorTexture(0, 0, 0, 0)
    btn._bg = bg

    -- Aktiv-Indikator: schlanker Akzentbalken am linken Rand des Icons
    local bar = btn:CreateTexture(nil, "OVERLAY")
    bar:SetWidth(2)
    bar:SetPoint("TOPLEFT",    btn, "TOPLEFT",    -1,  4)
    bar:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", -1, -4)
    bar:SetColorTexture(0, 0, 0, 0)
    btn._bar = bar

    local icon = btn:CreateTexture(nil, "OVERLAY")
    icon:SetSize(RAIL_ICON_GLYPH, RAIL_ICON_GLYPH)
    icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
    icon:SetTexture(tabDef.icon)
    icon:SetVertexColor(C.textDim[1], C.textDim[2], C.textDim[3])
    btn._icon = icon

    -- Benachrichtigungspunkt (standardmaessig versteckt, siehe SetTabBadge)
    local dot = btn:CreateTexture(nil, "OVERLAY")
    dot:SetSize(6, 6)
    dot:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -2, -2)
    dot:SetColorTexture(C.accentDot[1], C.accentDot[2], C.accentDot[3], 1.0)
    dot:Hide()
    btn._dot = dot

    btn:SetScript("OnEnter", function(self)
        if activeTab ~= tabDef.id then
            self._bg:SetColorTexture(C.surface2[1], C.surface2[2], C.surface2[3], 0.80)
            TintIcon(self, false, true)
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(tabDef.tooltip)
        if self._locked and WeintCodex.Access then
            GameTooltip:AddLine(WeintCodex.Access.Reason(tabDef.feature),
                C.textFaint[1], C.textFaint[2], C.textFaint[3], true)
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
        if activeTab ~= tabDef.id then
            self._bg:SetColorTexture(0, 0, 0, 0)
            TintIcon(self, false, false)
        end
        GameTooltip:Hide()
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

    if tabDef.feature then
        tabFeature[tabDef.id] = tabDef.feature
    end
end

-- Zeigt/versteckt den Benachrichtigungspunkt eines Tabs anhand echten Zustands
-- (z.B. Materialengpass, offene Sync-Warteschlange) - siehe ShowHome().
function WeintCodex.Navigation.SetTabBadge(tabId, on)
    local btn = tabButtons[tabId]
    if not btn or not btn._dot then return end
    if on then btn._dot:Show() else btn._dot:Hide() end
end

-- Sperrt einen Tab optisch, ohne ihn aus der Leiste zu nehmen. Verstecken
-- wäre teurer und schlechter: die Buttons entstehen zur Ladezeit mit
-- festen Positionen (siehe Schleife oben), ein Filtern müsste sie zur
-- Laufzeit neu verankern und Map wie Array von tabButtons synchron halten.
-- Der gesperrte Tab bleibt außerdem absichtlich klickbar - der Spieler soll
-- draufklicken und lesen können, warum (siehe ShowAccessLock).
function WeintCodex.Navigation.SetTabLocked(tabId, on)
    local btn = tabButtons[tabId]
    if not btn then return end

    btn._locked = on and true or nil

    if not btn._lock then
        -- Kleines Plättchen unten links, spiegelbildlich zum
        -- Benachrichtigungspunkt oben rechts (siehe SetTabBadge).
        local lock = btn:CreateTexture(nil, "OVERLAY")
        lock:SetSize(5, 5)
        lock:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 3, 3)
        lock:SetColorTexture(C.textFaint[1], C.textFaint[2], C.textFaint[3], 1.0)
        lock:Hide()
        btn._lock = lock
    end

    if on then btn._lock:Show() else btn._lock:Hide() end

    TintIcon(btn, activeTab == tabId, false)
end

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
    WeintCodex.SidebarHeader:SetText(WeintCodex.ColorText("textFaint", "NAVIGATION"))
end

-- Build flat list of items
function WeintCodex.Navigation.BuildSidebar(sectionTitle, items)
    WeintCodex.Navigation.ClearSidebar()
    WeintCodex.SidebarHeader:SetText(WeintCodex.ColorText("purple", string.upper(sectionTitle or "")))

    local sidebar  = WeintCodex.Sidebar
    local offsetY  = -46

    for _, itemDef in ipairs(items) do
        local isGroup = itemDef.isGroup

        if isGroup then
            local lbl = sidebar:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(WeintCodex.Fonts.mono, 10, "")
            lbl:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 18, offsetY)
            lbl:SetText(WeintCodex.ColorText("textGhost", itemDef.label or ""))
            lbl:SetWidth(204)
            table.insert(sidebarGroups, lbl)
            offsetY = offsetY - 18
        else
            local indent   = itemDef.indent and 32 or 16
            local hasStatus = itemDef.status ~= nil
            local itemH    = hasStatus and 40 or 28

            local btn = CreateFrame("Button", nil, sidebar)
            btn:SetHeight(itemH)
            -- Rechts relativ zur Sidebar verankert statt fester Breite, damit
            -- eingerueckte Eintraege nicht ueber den rechten Rand der Sidebar
            -- hinaus in das Hauptfeld hineinragen.
            btn:SetPoint("TOPLEFT",  sidebar, "TOPLEFT",  indent, offsetY)
            btn:SetPoint("TOPRIGHT", sidebar, "TOPRIGHT", -12,    offsetY)

            local bg = btn:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(btn)
            bg:SetColorTexture(0, 0, 0, 0)
            btn._bg = bg

            -- Dauerhafter Akzentstreifen (z.B. End-Boss-Kennzeichnung),
            -- unabhaengig vom Aktiv-/Hover-Zustand sichtbar - siehe
            -- BaselineAccent()/SetActive() weiter unten.
            local accentColor = itemDef.accentColor and C[itemDef.accentColor]

            local accent = btn:CreateTexture(nil, "OVERLAY")
            accent:SetSize(3, itemH)
            accent:SetPoint("LEFT", btn, "LEFT", 0, 0)
            btn._accent = accent

            local function BaselineAccent()
                if accentColor then
                    accent:SetColorTexture(accentColor[1], accentColor[2], accentColor[3], 0.6)
                else
                    accent:SetColorTexture(C.purple[1], C.purple[2], C.purple[3], 0.0)
                end
            end
            BaselineAccent()

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
            lbl:SetPoint("RIGHT", btn, "RIGHT", -8, 0)
            lbl:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
            lbl:SetText(itemDef.label or "")
            lbl:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
            lbl:SetJustifyH("LEFT")
            btn._label = lbl

            local statusLbl
            if hasStatus then
                -- Zweizeilig: Name oben, Status-Subline darunter. Rechter
                -- Rand um 20px statt 8px eingerueckt, damit der Progress-
                -- Punkt (nur beim aktiven Eintrag sichtbar) nicht mit
                -- langen Namen/Statustexten kollidiert.
                lbl:ClearAllPoints()
                lbl:SetPoint("TOPLEFT", btn, "TOPLEFT", iconOffsetX, -8)
                lbl:SetPoint("RIGHT", btn, "RIGHT", -20, 0)

                statusLbl = btn:CreateFontString(nil, "OVERLAY")
                statusLbl:SetPoint("TOPLEFT", lbl, "BOTTOMLEFT", 0, -4)
                statusLbl:SetPoint("RIGHT", btn, "RIGHT", -20, 0)
                statusLbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
                statusLbl:SetJustifyH("LEFT")
                local sc = C[itemDef.status.color or "textFaint"] or C.textFaint
                statusLbl:SetTextColor(sc[1], sc[2], sc[3])
                statusLbl:SetText(itemDef.status.text or "")
                btn._statusLbl = statusLbl
            else
                lbl:SetPoint("LEFT", btn, "LEFT", iconOffsetX, 0)
            end

            local dot
            if hasStatus then
                dot = btn:CreateTexture(nil, "OVERLAY")
                dot:SetSize(6, 6)
                dot:SetPoint("RIGHT", btn, "RIGHT", -8, 0)
                dot:SetColorTexture(C.accentDot[1], C.accentDot[2], C.accentDot[3], 1.0)
                dot:Hide()
                btn._dot = dot
            end

            local function SetActive(self, on)
                if on then
                    self._bg:SetColorTexture(C.purple[1], C.purple[2], C.purple[3], 0.20)
                    self._accent:SetColorTexture(C.purple[1], C.purple[2], C.purple[3], 1.0)
                    self._label:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
                    if self._dot then self._dot:Show() end
                else
                    self._bg:SetColorTexture(0, 0, 0, 0)
                    BaselineAccent()
                    self._label:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
                    if self._dot then self._dot:Hide() end
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
            offsetY = offsetY - (hasStatus and 42 or 30)
        end
    end
end

-- Aktualisiert nur die Status-Subline eines bereits gebauten Eintrags
-- (z.B. Boss-Kill waehrend des Raids), ohne die Sidebar neu aufzubauen -
-- der aktuell angeklickte Eintrag bleibt dadurch markiert.
-- index bezieht sich auf die Reihenfolge der Nicht-Gruppen-Eintraege.
function WeintCodex.Navigation.UpdateSidebarStatus(index, status)
    local btn = sidebarItems[index]
    if not (btn and btn._statusLbl and status) then return end
    local sc = C[status.color or "textFaint"] or C.textFaint
    btn._statusLbl:SetTextColor(sc[1], sc[2], sc[3])
    btn._statusLbl:SetText(status.text or "")
end

-- Activate first sidebar item automatically
function WeintCodex.Navigation.ActivateFirst()
    if sidebarItems[1] then
        sidebarItems[1]:Click()
    end
end

--------------------------------------------------
-- Inspector (rechte Kontext-Spalte)
--
-- Generisches Baukasten-System, damit jedes Modul seinen eigenen
-- Kontext-Inhalt deklarativ beschreiben kann, ohne Layout-Code zu
-- duplizieren. Block-Typen: header, rows, list, checklist, card, notes,
-- button, divider, spacer.
--------------------------------------------------

local inspectorWidgets   = {}
local INSPECTOR_PAD      = 20
local INSPECTOR_CONTENT_W = WeintCodex.Inspector:GetWidth() - INSPECTOR_PAD * 2

function WeintCodex.Navigation.ClearInspector()
    for _, w in ipairs(inspectorWidgets) do w:Hide() end
    wipe(inspectorWidgets)
end

-- Verbirgt frei belegte Aktions-Buttons in der Titelleiste (z.B. "Companion",
-- Rollen-Umschalter). Module parenten ihre eigenen Buttons einmalig an
-- WeintCodex.TitleBarActions und rufen diese Funktion beim Tab-Wechsel auf.
function WeintCodex.Navigation.ClearTitleActions()
    for _, child in ipairs({ WeintCodex.TitleBarActions:GetChildren() }) do
        child:Hide()
    end
end

local function InspectorHeader(parent, y, text)
    local h = parent:CreateFontString(nil, "OVERLAY")
    h:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    h:SetPoint("TOPLEFT",  parent, "TOPLEFT",  INSPECTOR_PAD, y)
    h:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -INSPECTOR_PAD, y)
    h:SetJustifyH("LEFT")
    h:SetText(WeintCodex.ColorText("textFaint", string.upper(text or "")))
    table.insert(inspectorWidgets, h)
    return y - 18
end

local function InspectorDivider(parent, y)
    local d = parent:CreateTexture(nil, "OVERLAY")
    d:SetHeight(1)
    d:SetPoint("TOPLEFT",  parent, "TOPLEFT",  INSPECTOR_PAD, y)
    d:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -INSPECTOR_PAD, y)
    d:SetColorTexture(C.border[1], C.border[2], C.border[3], C.border[4])
    table.insert(inspectorWidgets, d)
    return y - 14
end

local function InspectorRows(parent, y, rows)
    for _, row in ipairs(rows) do
        local lbl = parent:CreateFontString(nil, "OVERLAY")
        lbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", INSPECTOR_PAD, y)
        lbl:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
        lbl:SetText(row.label or "")
        table.insert(inspectorWidgets, lbl)

        local val = parent:CreateFontString(nil, "OVERLAY")
        val:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        val:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -INSPECTOR_PAD, y)
        val:SetJustifyH("RIGHT")
        local vc = C[row.valueColor or "textNormal"] or C.textNormal
        val:SetTextColor(vc[1], vc[2], vc[3])
        val:SetText(row.value or "")
        table.insert(inspectorWidgets, val)

        y = y - 20
    end
    return y - 4
end

local function InspectorListCard(parent, y, item)
    local card = CreateFrame("Frame", nil, parent)
    card:SetHeight(item.progress and 40 or 30)
    card:SetPoint("TOPLEFT",  parent, "TOPLEFT",  INSPECTOR_PAD, y)
    card:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -INSPECTOR_PAD, y)
    WeintCodex.SetSolidBg(card, C.bgCard[1], C.bgCard[2], C.bgCard[3], 1.0)
    WeintCodex.DrawSlimBorder(card, "hairline")

    local lbl = card:CreateFontString(nil, "OVERLAY")
    lbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    lbl:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -7)
    lbl:SetPoint("RIGHT", card, "RIGHT", -70, 0)
    lbl:SetJustifyH("LEFT")
    local lc = C[item.labelColor or "textNormal"] or C.textNormal
    lbl:SetTextColor(lc[1], lc[2], lc[3])
    lbl:SetText(item.label or "")

    local val = card:CreateFontString(nil, "OVERLAY")
    val:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    val:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -7)
    val:SetJustifyH("RIGHT")
    local vc = C[item.valueColor or "textDim"] or C.textDim
    val:SetTextColor(vc[1], vc[2], vc[3])
    val:SetText(item.value or "")

    if item.progress then
        local barW = INSPECTOR_CONTENT_W - 20
        local track = card:CreateTexture(nil, "OVERLAY")
        track:SetHeight(3)
        track:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 10, 8)
        track:SetSize(barW, 3)
        track:SetColorTexture(C.surface3[1], C.surface3[2], C.surface3[3], 1.0)

        local fillCol = C[item.progressColor or "purple"] or C.purple
        local pct  = math.max(0, math.min(1, item.progress))
        local fill = card:CreateTexture(nil, "OVERLAY")
        fill:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 10, 8)
        fill:SetSize(math.max(1, barW * pct), 3)
        fill:SetColorTexture(fillCol[1], fillCol[2], fillCol[3], 1.0)
    end

    table.insert(inspectorWidgets, card)
    return y - card:GetHeight() - 6
end

-- Wie InspectorListCard, aber mit einer dekorativen Haekchen-Box links (fuer
-- kuratierte Kurzfassungs-Punkte, kein interaktives Checkbox-Widget noetig).
local function InspectorChecklistItem(parent, y, item)
    local card = CreateFrame("Frame", nil, parent)
    card:SetHeight(38)
    card:SetPoint("TOPLEFT",  parent, "TOPLEFT",  INSPECTOR_PAD, y)
    card:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -INSPECTOR_PAD, y)
    WeintCodex.SetSolidBg(card, C.bgCard[1], C.bgCard[2], C.bgCard[3], 1.0)
    WeintCodex.DrawSlimBorder(card, "hairline")

    -- Dekorative "erledigt/kuratiert"-Markierung: bewusst eine schlichte
    -- gefuellte Flaeche statt eines echten Blizzard-Icons (z.B. Readycheck-
    -- Haekchen), damit hier keine Verwechslung mit einem aktiven Raid-
    -- Readycheck entsteht - es ist rein dekorativ, kein Widget-Zustand.
    local box = CreateFrame("Frame", nil, card)
    box:SetSize(18, 18)
    box:SetPoint("LEFT", card, "LEFT", 10, 0)
    WeintCodex.SetSolidBg(box, C.surface2[1], C.surface2[2], C.surface2[3], 1.0)
    WeintCodex.DrawSlimBorder(box, "hairline")

    local check = box:CreateTexture(nil, "OVERLAY")
    check:SetSize(10, 10)
    check:SetPoint("CENTER", box, "CENTER", 0, 0)
    check:SetColorTexture(C.green[1], C.green[2], C.green[3], 0.70)

    local lbl = card:CreateFontString(nil, "OVERLAY")
    lbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    lbl:SetPoint("LEFT",  box, "RIGHT", 10, 0)
    lbl:SetPoint("RIGHT", card, "RIGHT", -10, 0)
    lbl:SetJustifyH("LEFT")
    local lc = C[item.labelColor or "textNormal"] or C.textNormal
    lbl:SetTextColor(lc[1], lc[2], lc[3])
    lbl:SetText(item.label or "")

    table.insert(inspectorWidgets, card)
    return y - card:GetHeight() - 6
end

local function InspectorCard(parent, y, opts)
    local lineCount = opts.lines and #opts.lines or 0
    local h = 20 + lineCount * 15
    if opts.title    then h = h + 18 end
    if opts.subtitle then h = h + 14 end

    local card = CreateFrame("Frame", nil, parent)
    card:SetHeight(h)
    card:SetPoint("TOPLEFT",  parent, "TOPLEFT",  INSPECTOR_PAD, y)
    card:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -INSPECTOR_PAD, y)
    WeintCodex.SetSolidBg(card, C.bgCard[1], C.bgCard[2], C.bgCard[3], 1.0)
    WeintCodex.DrawSlimBorder(card, "hairline")

    local yy = -10
    if opts.title then
        local t = card:CreateFontString(nil, "OVERLAY")
        t:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        t:SetPoint("TOPLEFT", card, "TOPLEFT", 10, yy)
        t:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
        t:SetText(opts.title)
        yy = yy - 18
    end
    if opts.subtitle then
        local s = card:CreateFontString(nil, "OVERLAY")
        s:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        s:SetPoint("TOPLEFT", card, "TOPLEFT", 10, yy)
        s:SetTextColor(C.textFaint[1], C.textFaint[2], C.textFaint[3])
        s:SetText(opts.subtitle)
        yy = yy - 14
    end
    for _, line in ipairs(opts.lines or {}) do
        local l = card:CreateFontString(nil, "OVERLAY")
        l:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        l:SetPoint("TOPLEFT",  card, "TOPLEFT",  10, yy)
        l:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, yy)
        l:SetJustifyH("LEFT")
        l:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
        l:SetText(line)
        yy = yy - 15
    end

    table.insert(inspectorWidgets, card)
    return y - h - 6
end

local function InspectorButton(parent, y, opts)
    local isPrimary = (opts.style == "primary")
    local btn = WeintCodex.CreateCard(parent, {
        width = INSPECTOR_CONTENT_W, height = 32, buttonStyle = true,
        surface = isPrimary and "surface3" or "surface2",
    })
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", INSPECTOR_PAD, y)
    if isPrimary then
        WeintCodex.DrawSlimBorder(btn, "purple", 0.9, 1)
    end

    local lbl = btn:CreateFontString(nil, "OVERLAY")
    lbl:SetAllPoints(btn)
    lbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    lbl:SetJustifyH("CENTER")
    lbl:SetJustifyV("MIDDLE")
    lbl:SetText(opts.label or "")
    local lc = isPrimary and C.textBright or C.textNormal
    lbl:SetTextColor(lc[1], lc[2], lc[3])

    if opts.onClick then btn:SetScript("OnClick", opts.onClick) end
    btn:SetScript("OnEnter", function(self) self:SetSurface("surface3") end)
    btn:SetScript("OnLeave", function(self) self:SetSurface(isPrimary and "surface3" or "surface2") end)

    table.insert(inspectorWidgets, btn)
    return y - 32 - 8
end

--------------------------------------------------
-- Notizfeld
--
-- Eigener Scrollbereich, wahlweise einspaltig (viel Platz pro Zeile, fuer
-- laengeren Fliesstext) oder zweispaltig (schneller Ueberblick, zwei
-- getrennte Felder nebeneinander). Welche der beiden Ansichten die
-- richtige ist, haengt allein am Inhalt - deshalb entscheidet das der
-- Nutzer ueber den Umschalter in der Kopfzeile und nicht das Addon.
-- Wird das Feld zum ersten Mal zu voll, fragt eine einmalige Einblendung
-- im Feld selbst nach; danach bleibt nur der Umschalter.
--
-- Statt der klobigen UIPanelScrollFrameTemplate-Leiste (26px) zeichnet das
-- Feld eine 8px schmale Bildlaufanzeige. Bei zwei Spalten waeren von den
-- 139px Spaltenbreite sonst kaum 110px Text uebrig geblieben.
--
-- opts:
--   title         Ueberschrift; das Feld zeichnet seine Kopfzeile selbst
--   height        Gesamthoehe des Blocks (inkl. Kopf- und Fusszeile)
--   placeholder   Hinweis im leeren Feld, String oder { Spalte1, Spalte2 }
--   columns       true = Zweispalten-Umschalter anbieten
--   get(col) / set(col, text)       Spalteninhalt, col ist immer 1 oder 2
--   getLayout() / setLayout(mode)   "single" | "columns"
--   mergeColumns()                  vor dem Wechsel auf "single" aufgerufen
--   shouldAsk() / markAsked()       einmalige Rueckfrage bei Ueberlauf
--------------------------------------------------

local NOTES_HEAD_H  = 22   -- Kopfzeile mit Titel + Umschalter
local NOTES_FOOT_H  = 15   -- Fusszeile mit Zeichenzahl + Modus
local NOTES_INSET   = 7    -- Innenabstand der Textflaeche
local NOTES_BAR_W   = 8    -- Platz fuer die schmale Bildlaufanzeige
local NOTES_COL_GAP = 12   -- Spaltenabstand inkl. Trennlinie
local NOTES_WHEEL   = 32   -- Scrollweite pro Mausrad-Raste

-- Vier umfaerbbare Rahmentexturen. DrawSlimBorder haelt keine Referenzen,
-- der Fokusrahmen braucht aber genau das.
local function NotesBorder(frame)
    local edges = {}
    for i = 1, 4 do
        edges[i] = frame:CreateTexture(nil, "OVERLAY")
    end
    edges[1]:SetPoint("TOPLEFT");     edges[1]:SetPoint("TOPRIGHT");    edges[1]:SetHeight(1)
    edges[2]:SetPoint("BOTTOMLEFT");  edges[2]:SetPoint("BOTTOMRIGHT"); edges[2]:SetHeight(1)
    edges[3]:SetPoint("TOPLEFT");     edges[3]:SetPoint("BOTTOMLEFT");  edges[3]:SetWidth(1)
    edges[4]:SetPoint("TOPRIGHT");    edges[4]:SetPoint("BOTTOMRIGHT"); edges[4]:SetWidth(1)

    return function(colorName, alpha)
        local col = C[colorName] or C.hairline
        for i = 1, 4 do
            edges[i]:SetColorTexture(col[1], col[2], col[3], alpha or col[4] or 1.0)
        end
    end
end

-- Segment des Umschalters, gleiches Muster wie der Rollen-Umschalter in
-- modules/bossguides.lua - nur kleiner, weil es in die Kopfzeile passt.
local function NotesSegment(parent, label, width)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width, 16)
    b._bg = WeintCodex.SetSolidBg(b, C.surface1[1], C.surface1[2], C.surface1[3], 1.0)

    local l = b:CreateFontString(nil, "OVERLAY")
    l:SetAllPoints(b)
    l:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    l:SetJustifyH("CENTER")
    l:SetText(label)
    b._label = l

    b.SetActive = function(self, on)
        self._active = on
        if on then
            self._bg:SetColorTexture(C.purpleDeep[1], C.purpleDeep[2], C.purpleDeep[3], 1.0)
            self._label:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
        else
            self._bg:SetColorTexture(C.surface1[1], C.surface1[2], C.surface1[3], 1.0)
            self._label:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
        end
    end

    b:SetScript("OnEnter", function(self)
        if not self._active then
            self._bg:SetColorTexture(C.surface3[1], C.surface3[2], C.surface3[3], 1.0)
            self._label:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
        end
    end)
    b:SetScript("OnLeave", function(self) self:SetActive(self._active) end)

    b:SetActive(false)
    return b
end

local function NotesPromptButton(parent, label, width)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width, 18)
    b._bg = WeintCodex.SetSolidBg(b, C.surface2[1], C.surface2[2], C.surface2[3], 1.0)
    WeintCodex.DrawSlimBorder(b, "purpleDim", 0.8, 1)

    local l = b:CreateFontString(nil, "OVERLAY")
    l:SetAllPoints(b)
    l:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    l:SetJustifyH("CENTER")
    l:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
    l:SetText(label)

    b:SetScript("OnEnter", function(self)
        self._bg:SetColorTexture(C.purpleDeep[1], C.purpleDeep[2], C.purpleDeep[3], 1.0)
        l:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
    end)
    b:SetScript("OnLeave", function(self)
        self._bg:SetColorTexture(C.surface2[1], C.surface2[2], C.surface2[3], 1.0)
        l:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
    end)
    return b
end

local function NotesTextLength(text)
    if not text or text == "" then return 0 end
    -- Umlaute sind in UTF-8 zwei Bytes - # wuerde sie doppelt zaehlen.
    if strlenutf8 then return strlenutf8(text) end
    return #text
end

local function InspectorNotes(parent, y, opts)
    local h            = opts.height or 100
    local allowColumns = (opts.columns == true) or (opts.columns == 2)
    local headH        = (opts.title or allowColumns) and NOTES_HEAD_H or 0

    local holder = CreateFrame("Frame", nil, parent)
    holder:SetHeight(h)
    holder:SetPoint("TOPLEFT",  parent, "TOPLEFT",  INSPECTOR_PAD, y)
    holder:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -INSPECTOR_PAD, y)
    table.insert(inspectorWidgets, holder)

    local mode = (opts.getLayout and opts.getLayout()) or "single"
    if mode ~= "columns" or not allowColumns then mode = "single" end

    -- Einspaltig darf nie eine gefuellte, aber unsichtbare zweite Spalte
    -- zurueckbleiben - etwa aus einer Version, in der zweispaltig die
    -- einzige Ansicht war. mergeColumns ist ohne Inhalt ein No-Op.
    if mode == "single" and opts.mergeColumns then opts.mergeColumns() end

    local function Placeholder(index)
        local p = opts.placeholder
        if type(p) == "table" then return p[index] or "" end
        return (index == 1) and (p or "") or ""
    end

    -- ------------------------------------------------
    -- Kopfzeile: Titel links, Umschalter rechts
    -- ------------------------------------------------

    local segSingle, segColumns
    if headH > 0 then
        if opts.title then
            local t = holder:CreateFontString(nil, "OVERLAY")
            t:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
            t:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, -3)
            t:SetJustifyH("LEFT")
            t:SetText(WeintCodex.ColorText("textFaint", string.upper(opts.title)))
        end
        if allowColumns then
            segColumns = NotesSegment(holder, "2 SPALTEN", 62)
            segColumns:SetPoint("TOPRIGHT", holder, "TOPRIGHT", 0, -1)
            segSingle = NotesSegment(holder, "1 SPALTE", 56)
            segSingle:SetPoint("TOPRIGHT", segColumns, "TOPLEFT", -3, 0)
        end
    end

    -- ------------------------------------------------
    -- Textflaeche
    -- ------------------------------------------------

    local card = CreateFrame("Frame", nil, holder)
    card:SetPoint("TOPLEFT",     holder, "TOPLEFT",     0, -headH)
    card:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 0, NOTES_FOOT_H)
    card._bg = WeintCodex.SetSolidBg(card, C.headerBg[1], C.headerBg[2], C.headerBg[3], 0.95)
    card:EnableMouse(true)

    local SetBorderTint = NotesBorder(card)
    SetBorderTint("hairline", 1)

    local colDivider = card:CreateTexture(nil, "ARTWORK")
    colDivider:SetWidth(1)
    colDivider:SetColorTexture(C.border[1], C.border[2], C.border[3], 1.0)
    colDivider:Hide()

    local footLeft = holder:CreateFontString(nil, "OVERLAY")
    footLeft:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    footLeft:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 1, 1)
    footLeft:SetJustifyH("LEFT")

    local footRight = holder:CreateFontString(nil, "OVERLAY")
    footRight:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    footRight:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", -1, 1)
    footRight:SetJustifyH("RIGHT")

    local cardH  = h - headH - NOTES_FOOT_H
    local textH  = cardH - NOTES_INSET * 2
    local ready  = false
    local prompt
    local columns = {}

    local function UpdateBar(c)
        local range = c.scroll:GetVerticalScrollRange() or 0
        if range <= 1 then
            c.track:Hide()
            c.thumb:Hide()
            return
        end
        local viewH  = c.scroll:GetHeight()
        local thumbH = math.max(14, viewH * viewH / (viewH + range))
        local frac   = math.min(1, math.max(0, (c.scroll:GetVerticalScroll() or 0) / range))
        c.thumb:SetHeight(thumbH)
        c.thumb:ClearAllPoints()
        c.thumb:SetPoint("TOP", c.track, "TOP", 0, -frac * (viewH - thumbH))
        c.track:Show()
        c.thumb:Show()
    end

    local function RefreshFooter()
        if not ready then return end
        local total = 0
        for i = 1, (mode == "columns") and 2 or 1 do
            total = total + NotesTextLength(columns[i].box:GetText())
        end
        if total == 0 then
            footLeft:SetText(WeintCodex.ColorText("textGhost", "Leer - ins Feld klicken"))
        else
            footLeft:SetText(WeintCodex.ColorText("textGhost", total .. " Zeichen"))
        end
        footRight:SetText(WeintCodex.ColorText("textGhost",
            (mode == "columns") and "2 Spalten" or "1 Spalte"))
    end

    -- Einmalige Rueckfrage, sobald der Text das sichtbare Feld zum ersten
    -- Mal ueberlaeuft. Bewusst kein Popup: eine Einblendung im Feld selbst
    -- unterbricht das Tippen nicht.
    local function MaybeAsk()
        if not (prompt and allowColumns) or mode ~= "single" then return end
        if not (opts.shouldAsk and opts.shouldAsk()) then return end
        if (columns[1].scroll:GetVerticalScrollRange() or 0) <= 4 then return end
        prompt:Show()
    end

    local function BuildColumn(index)
        local c = {}

        c.scroll = CreateFrame("ScrollFrame", nil, card)
        c.scroll:EnableMouseWheel(true)

        c.box = CreateFrame("EditBox", nil, c.scroll)
        local box = c.box
        box:SetMultiLine(true)
        box:SetMaxLetters(0)
        box:SetAutoFocus(false)
        box:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        box:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
        box:SetTextInsets(0, 0, 0, 0)
        box:SetHeight(textH)
        c.scroll:SetScrollChild(box)

        c.track = card:CreateTexture(nil, "ARTWORK")
        c.track:SetWidth(2)
        c.track:SetColorTexture(C.border[1], C.border[2], C.border[3], 1.0)
        c.track:Hide()

        c.thumb = card:CreateTexture(nil, "OVERLAY")
        c.thumb:SetWidth(2)
        c.thumb:SetColorTexture(C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 1.0)
        c.thumb:Hide()

        c.hint = card:CreateFontString(nil, "ARTWORK")
        c.hint:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        c.hint:SetTextColor(C.textGhost[1], C.textGhost[2], C.textGhost[3])
        c.hint:SetJustifyH("LEFT")
        c.hint:SetJustifyV("TOP")
        c.hint:SetText(Placeholder(index))

        local function RefreshHint()
            if (box:GetText() or "") == "" and not box:HasFocus() then
                c.hint:Show()
            else
                c.hint:Hide()
            end
        end
        c.RefreshHint = RefreshHint

        box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        -- ClearInspector versteckt die Widgets nur. Ein verstecktes Feld,
        -- das den Tastaturfokus behaelt, wuerde die Bewegungstasten
        -- schlucken - deshalb hier zwingend loslassen.
        box:SetScript("OnHide", function(self) self:ClearFocus() end)
        box:SetScript("OnTextChanged", function(self, userInput)
            if ScrollingEdit_OnTextChanged then
                ScrollingEdit_OnTextChanged(self, c.scroll)
            else
                c.scroll:UpdateScrollChildRect()
            end
            if not c.suppress and opts.set then opts.set(index, self:GetText()) end
            RefreshHint()
            UpdateBar(c)
            RefreshFooter()
            if userInput then MaybeAsk() end
        end)
        box:SetScript("OnCursorChanged", function(self, x, cy, cw, ch)
            if ScrollingEdit_OnCursorChanged then
                ScrollingEdit_OnCursorChanged(self, x, cy, cw, ch)
            end
        end)
        -- Haelt den Cursor beim Tippen im sichtbaren Bereich. Der Scrollframe
        -- muss explizit mit, self:GetParent() ist nicht in jedem Client der
        -- Rueckfallweg.
        box:SetScript("OnUpdate", function(self, elapsed)
            if ScrollingEdit_OnUpdate then
                ScrollingEdit_OnUpdate(self, elapsed, c.scroll)
            end
        end)
        box:SetScript("OnEditFocusGained", function()
            SetBorderTint("purple", 0.9)
            card._bg:SetColorTexture(C.surface1[1], C.surface1[2], C.surface1[3], 1.0)
            RefreshHint()
        end)
        box:SetScript("OnEditFocusLost", function()
            SetBorderTint("hairline", 1)
            card._bg:SetColorTexture(C.headerBg[1], C.headerBg[2], C.headerBg[3], 0.95)
            RefreshHint()
        end)

        c.scroll:SetScript("OnMouseWheel", function(self, delta)
            local range = self:GetVerticalScrollRange() or 0
            local v = (self:GetVerticalScroll() or 0) - delta * NOTES_WHEEL
            if v < 0 then v = 0 elseif v > range then v = range end
            self:SetVerticalScroll(v)
        end)
        c.scroll:SetScript("OnVerticalScroll",     function() UpdateBar(c) end)
        c.scroll:SetScript("OnScrollRangeChanged", function() UpdateBar(c) end)

        c.suppress = true
        box:SetText((opts.get and opts.get(index)) or "")
        c.suppress = false
        RefreshHint()

        return c
    end

    local function Layout()
        local innerW = INSPECTOR_CONTENT_W - NOTES_INSET * 2
        local two    = (mode == "columns")
        local colW   = two and math.floor((innerW - NOTES_COL_GAP) / 2) or innerW
        local textW  = colW - NOTES_BAR_W

        for i = 1, 2 do
            local c = columns[i]
            if two or i == 1 then
                local leftX = NOTES_INSET + ((i == 2) and (colW + NOTES_COL_GAP) or 0)

                c.scroll:ClearAllPoints()
                c.scroll:SetPoint("TOPLEFT", card, "TOPLEFT", leftX, -NOTES_INSET)
                c.scroll:SetSize(textW, textH)
                c.box:SetWidth(textW)

                c.track:ClearAllPoints()
                c.track:SetPoint("TOPLEFT", card, "TOPLEFT", leftX + textW + 3, -NOTES_INSET)
                c.track:SetHeight(textH)

                c.hint:ClearAllPoints()
                c.hint:SetPoint("TOPLEFT", card, "TOPLEFT", leftX, -NOTES_INSET)
                c.hint:SetWidth(textW)

                c.scroll:Show()
                c.RefreshHint()
                UpdateBar(c)
            else
                c.box:ClearFocus()
                c.scroll:Hide()
                c.track:Hide()
                c.thumb:Hide()
                c.hint:Hide()
            end
        end

        if two then
            colDivider:ClearAllPoints()
            colDivider:SetPoint("TOPLEFT", card, "TOPLEFT",
                NOTES_INSET + colW + math.floor(NOTES_COL_GAP / 2), -NOTES_INSET)
            colDivider:SetHeight(textH)
            colDivider:Show()
        else
            colDivider:Hide()
        end

        if segSingle  then segSingle:SetActive(not two)  end
        if segColumns then segColumns:SetActive(two)     end
    end

    -- Wechsel auf eine Spalte darf nichts unsichtbar machen: mergeColumns
    -- haengt Spalte 2 an Spalte 1 an, statt sie im SavedData liegen zu
    -- lassen, wo sie niemand mehr sieht.
    local function SetMode(newMode, remember)
        if newMode == mode then return end
        if newMode == "single" and opts.mergeColumns then opts.mergeColumns() end

        mode = newMode
        if remember and opts.setLayout then opts.setLayout(mode) end

        for i = 1, 2 do
            local c = columns[i]
            c.suppress = true
            c.box:SetText((opts.get and opts.get(i)) or "")
            c.suppress = false
            c.scroll:SetVerticalScroll(0)
        end

        Layout()
        RefreshFooter()
    end

    columns[1] = BuildColumn(1)
    columns[2] = BuildColumn(2)

    -- Klick auf die freie Flaeche unter dem Text setzt den Cursor - ohne
    -- das muss man exakt die Textzeile treffen.
    card:SetScript("OnMouseDown", function(self)
        local target = columns[1]
        if mode == "columns" then
            local cursorX = GetCursorPosition() / self:GetEffectiveScale()
            if cursorX > (self:GetLeft() + self:GetWidth() / 2) then
                target = columns[2]
            end
        end
        target.box:SetFocus()
    end)

    if allowColumns then
        prompt = CreateFrame("Frame", nil, card)
        prompt:SetPoint("BOTTOMLEFT",  card, "BOTTOMLEFT",   1, 1)
        prompt:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -1, 1)
        prompt:SetHeight(46)
        prompt:SetFrameLevel(card:GetFrameLevel() + 5)
        prompt:EnableMouse(true)
        WeintCodex.SetSolidBg(prompt, C.surface3[1], C.surface3[2], C.surface3[3], 0.97)

        local topEdge = prompt:CreateTexture(nil, "OVERLAY")
        topEdge:SetPoint("TOPLEFT")
        topEdge:SetPoint("TOPRIGHT")
        topEdge:SetHeight(1)
        topEdge:SetColorTexture(C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.85)

        local q = prompt:CreateFontString(nil, "OVERLAY")
        q:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        q:SetPoint("TOPLEFT",  prompt, "TOPLEFT",   8, -7)
        q:SetPoint("TOPRIGHT", prompt, "TOPRIGHT", -8, -7)
        q:SetJustifyH("LEFT")
        q:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
        q:SetText("Viel Text. Lieber zwei Spalten nebeneinander?")

        local bColumns = NotesPromptButton(prompt, "2 Spalten", 74)
        bColumns:SetPoint("BOTTOMRIGHT", prompt, "BOTTOMRIGHT", -8, 6)

        local bScroll = NotesPromptButton(prompt, "Scrollen", 74)
        bScroll:SetPoint("BOTTOMRIGHT", bColumns, "BOTTOMLEFT", -6, 0)

        bColumns:SetScript("OnClick", function()
            if opts.markAsked then opts.markAsked() end
            prompt:Hide()
            SetMode("columns", true)
        end)
        bScroll:SetScript("OnClick", function()
            if opts.markAsked then opts.markAsked() end
            prompt:Hide()
        end)
        prompt:Hide()
    end

    if segSingle then
        -- Wer den Umschalter benutzt, kennt ihn - die Rueckfrage waere ab
        -- da nur noch im Weg.
        segSingle:SetScript("OnClick", function()
            if opts.markAsked then opts.markAsked() end
            if prompt then prompt:Hide() end
            SetMode("single", true)
        end)
        segColumns:SetScript("OnClick", function()
            if opts.markAsked then opts.markAsked() end
            if prompt then prompt:Hide() end
            SetMode("columns", true)
        end)
    end

    ready = true
    Layout()
    RefreshFooter()

    return y - h - 6
end

--------------------------------------------------
-- Item-Liste mit eigenem Scrollbereich
--
-- Der Inspector selbst kann nicht scrollen: SetInspector setzt alle
-- Bloecke absolut untereinander, was unten rausfaellt ist weg. Eine
-- Liste unbekannter Laenge braucht deshalb ihren eigenen Scrollbereich.
--
-- opts:
--   height       Zahl, oder "fill" = Restplatz bis zum unteren Rand
--   reserveBelow Pixel, die "fill" fuer nachfolgende Bloecke freilaesst
--   minHeight    Untergrenze fuer "fill" (Default 100)
--   empty        Text, wenn items leer ist
--   items        { { id, sublabel, state = "have"|"variant"|"open" }, ... }
--
-- Der Anzeigename kommt aus GetItemInfo, nicht vom Aufrufer - damit er
-- zur Client-Sprache passt (gleiche Doktrin wie WeintCodex_GetGemName).
--------------------------------------------------

local ITEM_ROW_H     = 30
local ITEM_SCROLLBAR = 26

-- Statusmarker rechts in der Zeile. Bewusst dieselben Texturen wie das
-- Status-System der Charakterseite, damit "erledigt" ueberall gleich
-- aussieht. "open" bekommt einen gedimmten Punkt statt eines roten
-- Kreuzes - ein fehlendes BiS-Item ist kein Fehler.
local ITEM_STATE = {
    have    = { icon = "Interface\\RaidFrame\\ReadyCheck-Ready",       size = 16, alpha = 1.00 },
    variant = { icon = "Interface\\DialogFrame\\UI-Dialog-Icon-Alert", size = 16, alpha = 1.00 },
    open    = { icon = "Interface\\Buttons\\UI-MinusButton-UP",        size = 12, alpha = 0.35 },
}

-- Zeilen, deren Item beim Rendern noch nicht im Client-Cache lag.
-- itemID -> Liste von Zeilen, die nachgezogen werden muessen.
local pendingItemRows = {}

local function ApplyItemDisplay(row)
    local itemId = row._itemID
    if not itemId then return true end

    local name, link, quality, _, _, _, _, _, _, texture = GetItemInfo(itemId)

    if not texture and GetItemIcon then
        texture = GetItemIcon(itemId)
    end
    row._icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")

    if name then
        row._link = link
        row._name:SetText(name)

        local r, g, b = C.textNormal[1], C.textNormal[2], C.textNormal[3]
        if quality and GetItemQualityColor then
            local qr, qg, qb = GetItemQualityColor(quality)
            if qr then r, g, b = qr, qg, qb end
        end
        row._name:SetTextColor(r, g, b)
        return true
    end

    -- Noch nicht im Cache: Platzhalter zeigen, Nachziehen abwarten
    row._name:SetText("Item #" .. itemId)
    row._name:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
    return false
end

local itemInfoWatcher = CreateFrame("Frame")
itemInfoWatcher:RegisterEvent("GET_ITEM_INFO_RECEIVED")
itemInfoWatcher:SetScript("OnEvent", function(_, _, itemId)
    local rows = itemId and pendingItemRows[itemId]
    if not rows then return end

    pendingItemRows[itemId] = nil
    for _, row in ipairs(rows) do
        -- Zeilen aus einem inzwischen ersetzten Inspector einfach
        -- ueberspringen (ClearInspector versteckt sie nur).
        if row._itemID == itemId and row:IsShown() then
            ApplyItemDisplay(row)
        end
    end
end)

local function CreateItemRow(parent, item, width, offsetY)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(width, ITEM_ROW_H)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, offsetY)
    row._itemID = item.id

    local bg = WeintCodex.SetSolidBg(row, C.bgCard[1], C.bgCard[2], C.bgCard[3], 1.0)
    WeintCodex.DrawSlimBorder(row, "hairline")
    row._bg = bg

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("LEFT", row, "LEFT", 5, 0)
    row._icon = icon

    local state  = ITEM_STATE[item.state] or ITEM_STATE.open
    local marker = row:CreateTexture(nil, "OVERLAY")
    marker:SetSize(state.size, state.size)
    marker:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    marker:SetTexture(state.icon)
    marker:SetAlpha(state.alpha)

    local hasSub  = item.sublabel and item.sublabel ~= ""
    local nameTop = hasSub and -5 or -9

    local name = row:CreateFontString(nil, "OVERLAY")
    name:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    name:SetPoint("TOPLEFT",  row, "TOPLEFT",  30, nameTop)
    name:SetPoint("TOPRIGHT", row, "TOPRIGHT", -(state.size + 12), nameTop)
    name:SetJustifyH("LEFT")
    name:SetWordWrap(false)
    row._name = name

    if hasSub then
        local sub = row:CreateFontString(nil, "OVERLAY")
        sub:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        sub:SetPoint("TOPLEFT",  row, "TOPLEFT",  30, -18)
        sub:SetPoint("TOPRIGHT", row, "TOPRIGHT", -(state.size + 12), -18)
        sub:SetJustifyH("LEFT")
        sub:SetWordWrap(false)
        sub:SetTextColor(C.textFaint[1], C.textFaint[2], C.textFaint[3])
        sub:SetText(item.sublabel)
    end

    if not ApplyItemDisplay(row) then
        pendingItemRows[item.id] = pendingItemRows[item.id] or {}
        table.insert(pendingItemRows[item.id], row)
    end

    row:SetScript("OnEnter", function(self)
        if self._bg then
            self._bg:SetColorTexture(C.surface2[1], C.surface2[2], C.surface2[3], 1.0)
        end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        -- SetItemByID gibt es nicht in jedem Client - SetHyperlink schon.
        local ok = pcall(GameTooltip.SetItemByID, GameTooltip, self._itemID)
        if not ok then
            GameTooltip:SetHyperlink("item:" .. self._itemID)
        end
        GameTooltip:Show()
    end)

    row:SetScript("OnLeave", function(self)
        if self._bg then
            self._bg:SetColorTexture(C.bgCard[1], C.bgCard[2], C.bgCard[3], 1.0)
        end
        GameTooltip:Hide()
    end)

    -- Shift-Klick verlinkt ins Chatfenster, Strg-Klick oeffnet die
    -- Anprobe - HandleModifiedItemClick kennt beide Faelle.
    row:SetScript("OnClick", function(self)
        if self._link and HandleModifiedItemClick then
            HandleModifiedItemClick(self._link)
        end
    end)

    return row
end

local function InspectorItemList(parent, y, opts)
    local h

    if opts.height == "fill" then
        local reserve = opts.reserveBelow or 0
        h = parent:GetHeight() + y - reserve - 20
        h = math.max(opts.minHeight or 100, h)
    else
        h = opts.height or 160
    end

    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(h)
    container:SetPoint("TOPLEFT",  parent, "TOPLEFT",  INSPECTOR_PAD, y)
    container:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -INSPECTOR_PAD, y)
    table.insert(inspectorWidgets, container)

    local items = opts.items or {}

    if #items == 0 then
        local empty = container:CreateFontString(nil, "OVERLAY")
        empty:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        empty:SetPoint("TOPLEFT",  container, "TOPLEFT",  0, -2)
        empty:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, -2)
        empty:SetJustifyH("LEFT")
        empty:SetTextColor(C.textFaint[1], C.textFaint[2], C.textFaint[3])
        empty:SetText(opts.empty or "Keine Einträge.")

        -- Ohne Inhalt nur so viel Platz belegen, wie der Hinweis braucht.
        local emptyH = math.max(empty:GetStringHeight(), 14)
        container:SetHeight(emptyH)
        return y - emptyH - 6
    end

    local scroll = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     container, "TOPLEFT",     0, 0)
    scroll:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -ITEM_SCROLLBAR, 0)

    local rowW  = INSPECTOR_CONTENT_W - ITEM_SCROLLBAR
    local inner = CreateFrame("Frame", nil, scroll)
    inner:SetSize(rowW, #items * ITEM_ROW_H)
    scroll:SetScrollChild(inner)

    local rowY = 0
    for _, item in ipairs(items) do
        CreateItemRow(inner, item, rowW, rowY)
        rowY = rowY - ITEM_ROW_H
    end

    return y - h - 6
end

-- blocks: Liste von { type = "header"|"rows"|"list"|"checklist"|"card"|"notes"|"button"|"itemlist"|"divider"|"spacer", ... }
function WeintCodex.Navigation.SetInspector(blocks)
    WeintCodex.Navigation.ClearInspector()
    local parent = WeintCodex.Inspector
    local y = -22

    for _, block in ipairs(blocks or {}) do
        if block.type == "header" then
            y = InspectorHeader(parent, y, block.text)
        elseif block.type == "rows" then
            y = InspectorRows(parent, y, block.rows or {})
        elseif block.type == "list" then
            if block.title then y = InspectorHeader(parent, y, block.title) end
            for _, item in ipairs(block.items or {}) do
                y = InspectorListCard(parent, y, item)
            end
        elseif block.type == "checklist" then
            if block.title then y = InspectorHeader(parent, y, block.title) end
            for _, item in ipairs(block.items or {}) do
                y = InspectorChecklistItem(parent, y, item)
            end
        elseif block.type == "card" then
            y = InspectorCard(parent, y, block)
        elseif block.type == "notes" then
            y = InspectorNotes(parent, y, block)
        elseif block.type == "itemlist" then
            y = InspectorItemList(parent, y, block)
        elseif block.type == "button" then
            y = InspectorButton(parent, y, block)
        elseif block.type == "divider" then
            y = InspectorDivider(parent, y)
        elseif block.type == "spacer" then
            y = y - (block.height or 12)
        end
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
    WeintCodex.Navigation.ClearInspector()
    WeintCodex.Navigation.ClearTitleActions()
    ClearContentPanel()

    -- Einziger Kontrollpunkt für gesperrte Bereiche. Deckt Rail-Klicks,
    -- GoToTab (Dashboard-Kacheln und Statistik-Karten) sowie core/search.lua
    -- mit ab, weil alle drei hier hereinlaufen.
    -- Bewusst NICHT abgedeckt: /wc import (core/main.lua) und der
    -- Import-Button im Dashboard rufen Sync.ShowImportDialog() direkt auf.
    -- Das ist unschädlich - der Import-Tab ist nie gesperrt, der Gate für
    -- die Daten selbst sitzt in ProcessImport (modules/sync.lua).
    local needed = tabFeature[tabId]
    if needed and not Can(needed) then
        WeintCodex.Navigation.ShowAccessLock(tabId, needed)
        return
    end

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
    elseif tabId == "weinttv" then
        if WeintCodex.WeintTV and WeintCodex.WeintTV.Show then
            WeintCodex.WeintTV.Show()
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
-- Sperrseite (Zugriffsprofil)
--------------------------------------------------
-- Eigener Frame statt ShowPlaceholder: hier stehen drei Textblöcke und eine
-- Hinweiskarte, nicht nur Titel und Untertitel. Aufbau bewusst wie
-- modules/academy.lua:DrawNotice, damit gesperrte und "noch keine Daten"-
-- Zustände gleich aussehen.
--------------------------------------------------

local AREA_LABEL = {
    raids     = "Raids",
    materials = "Materialien",
    calendar  = "Kalender",
}

local lockFrame = nil

function WeintCodex.Navigation.ShowAccessLock(tabId, featureKey)
    ClearContentPanel()

    local Access = WeintCodex.Access

    if not lockFrame then
        local lf = CreateFrame("Frame", nil, WeintCodex.ContentPanel)
        lf:SetAllPoints(WeintCodex.ContentPanel)

        local card = WeintCodex.CreateCard(lf, { height = 132,
            surface = "surface1", style = "border", borderColor = "hairline" })
        card:SetPoint("TOPLEFT",  lf, "TOPLEFT",   24, -32)
        card:SetPoint("TOPRIGHT", lf, "TOPRIGHT", -24, -32)

        local title = card:CreateFontString(nil, "OVERLAY")
        title:SetFont("Fonts\\MORPHEUS.TTF", 17, "")
        title:SetPoint("TOPLEFT", card, "TOPLEFT", 16, -14)
        title:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
        lf._title = title

        local reason = card:CreateFontString(nil, "OVERLAY")
        reason:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        reason:SetPoint("TOPLEFT",  title, "BOTTOMLEFT", 0, -10)
        reason:SetPoint("RIGHT",    card,  "RIGHT",     -16, 0)
        reason:SetJustifyH("LEFT")
        reason:SetSpacing(3)
        reason:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
        lf._reason = reason

        local hint = card:CreateFontString(nil, "OVERLAY")
        hint:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        hint:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 16, 12)
        hint:SetPoint("RIGHT",      card, "RIGHT",     -16, 0)
        hint:SetJustifyH("LEFT")
        lf._hint = hint

        lockFrame = lf
    end

    local profile = Access and Access.Profile()

    lockFrame._title:SetText((Access and Access.LOCK_TITLE) or "Bereich gesperrt")
    lockFrame._reason:SetText(Access and Access.Reason(featureKey) or "")

    local notice = profile and profile.notice
    if notice and notice ~= "" then
        lockFrame._hint:SetText(WeintCodex.ColorText("textDim", notice))
    else
        lockFrame._hint:SetText(WeintCodex.ColorText("textFaint",
            "Dein Zugriffsprofil zeigt dir /wc access."))
    end

    WeintCodex.SetBreadcrumb(AREA_LABEL[tabId] or tabId, "Gesperrt")

    local blocks = {
        { type = "header", text = "Zugriff" },
        { type = "rows", rows = {
            { label = "Rang",      value = Access and Access.TierLabel() or "—",
              valueColor = Access and Access.TierColor() or "textFaint" },
            { label = "Community", value = Access and Access.CommunityName() or "—" },
            { label = "Bereich",   value = AREA_LABEL[tabId] or tabId,
              valueColor = "textFaint" },
        }},
        { type = "divider" },
        { type = "header", text = "Warum sehe ich das nicht?" },
        { type = "card", lines = (Access and Access.LOCK_CARD) or {} },
    }

    WeintCodex.Navigation.SetInspector(blocks)

    lockFrame:Show()
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

-- Text für gesperrte Kennzahlen. Bewusst kein "0" oder "Keine": das wäre
-- eine Aussage über die Daten, obwohl der Spieler sie nicht sehen darf.
local LOCKED_VALUE = "Gesperrt"

-- Naechster bevorstehender Raidtermin (Mittwoch/Donnerstag), oder Fallback-Text
local function GetNextRaidLabel()
    if not Can("raids.view") then
        return WeintCodex.ColorText("textFaint", LOCKED_VALUE)
    end

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

-- Gibt nil zurueck, wenn die Anmeldungen gesperrt sind. Eine 0 waere eine
-- Luege ("niemand angemeldet"), obwohl nur die Sicht fehlt.
local function GetSignupCount()
    if not Can("raids.view") then return nil end

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
-- modules/materials.lua); zweiter Rueckgabewert = false wenn noch nie
-- importiert, dritter = true wenn der Bereich gesperrt ist.
local function GetMaterialShortageCount()
    if not Can("materials.view") then return 0, false, true end

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
    { id = "weinttv",    icon = "Interface\\Icons\\INV_Misc_Spyglass_02",             title = "WeintTV",     desc = "Tiefenanalyse des letzten Pulls" },
    { id = "import",     icon = "Interface\\Icons\\INV_Misc_Note_01",                 title = "Import",      desc = "Daten vom Discord-Bot importieren" },
}

function WeintCodex.ShowHome()
    ClearContentPanel()
    WeintCodex.Navigation.ClearSidebar()
    WeintCodex.Navigation.ClearTitleActions()
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
        wordmark:SetFont("Fonts\\MORPHEUS.TTF", 20, "")
        wordmark:SetPoint("TOPLEFT", hero, "TOPLEFT", 20, -14)
        wordmark:SetText(WeintCodex.ColorText("textBright", "WeintCodex"))

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

        -- Kacheln merken: das Raster wird nur einmal gebaut, ShowHome laeuft
        -- aber bei jedem Besuch - der Sperrzustand muss nachziehbar bleiben.
        local tileCards = {}

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
            card._descStr = desc

            card:SetScript("OnClick", function() GoToTab(tile.id) end)
            card:SetScript("OnEnter", function(self)
                if not Locked(tile.id) then self:SetSurface("surface3") end
            end)
            card:SetScript("OnLeave", function(self) self:SetSurface("surface2") end)

            tileCards[tile.id] = card
        end

        hf._tiles = tileCards

        ------------------------------------------------
        -- D. Footer-Hinweis
        ------------------------------------------------
        local hint = hf:CreateFontString(nil, "OVERLAY")
        hint:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        hint:SetPoint("BOTTOM", hf, "BOTTOM", 0, 10)
        hf._hint = hint

        hf._statCards = statCards

        homeFrame = hf
    end

    -- Dynamische Werte bei JEDEM Aufruf neu berechnen, nicht nur beim
    -- ersten Bau der Struktur - siehe Kommentar oben an homeFrame.
    local matShortage, hasMatScan, matLocked = GetMaterialShortageCount()
    local queueCount = GetQueueCount()
    local signups    = GetSignupCount()

    homeFrame._statCards.raid._valueStr:SetText(GetNextRaidLabel())

    homeFrame._statCards.signups._valueStr:SetText(
        signups and tostring(signups)
            or WeintCodex.ColorText("textFaint", LOCKED_VALUE)
    )

    local matValue, matColor
    if matLocked then
        matValue, matColor = LOCKED_VALUE, "textFaint"
    elseif not hasMatScan then
        matValue, matColor = "Kein Scan", "textDim"
    elseif matShortage > 0 then
        matValue, matColor = matShortage .. " Engpässe", "danger"
    else
        matValue, matColor = "Alles im Soll", "success"
    end
    homeFrame._statCards.materials._valueStr:SetText(WeintCodex.ColorText(matColor, matValue))

    homeFrame._statCards.queue._valueStr:SetText(
        queueCount > 0
            and WeintCodex.ColorText("warning", queueCount .. " ausstehend")
            or  WeintCodex.ColorText("textDim", "Keine")
    )

    -- Kein Engpass-Punkt auf einem gesperrten Tab: er verriete, dass es
    -- ueberhaupt eine Zahl gibt.
    WeintCodex.Navigation.SetTabBadge("materials",
        (not matLocked) and hasMatScan and matShortage > 0)
    WeintCodex.Navigation.SetTabBadge("import", queueCount > 0)

    -- Gesperrte Kacheln kennzeichnen (das Raster selbst wird nur einmal gebaut)
    local Access = WeintCodex.Access
    for _, tile in ipairs(dashboardTiles) do
        local card = homeFrame._tiles and homeFrame._tiles[tile.id]
        if card and card._descStr then
            if Locked(tile.id) then
                card._descStr:SetText(WeintCodex.ColorText("textFaint",
                    "Gesperrt · " .. (Access and Access.TierLabel() or "—")))
            else
                card._descStr:SetText(WeintCodex.ColorText("textDim", tile.desc))
            end
        end
    end

    local hasProfile = Access and Access.HasProfile()
    homeFrame._hint:SetText(WeintCodex.ColorText("textDim",
        hasProfile and "/wc  •  /wc import  •  /wc access" or "/wc  •  /wc import"))

    WeintCodex.SetBreadcrumb("Dashboard")

    local pulseRows = {}

    -- Eigener Rang zuerst: erklaert auf einen Blick, warum darunter
    -- vielleicht "Gesperrt" steht (und ist auf Screenshots sichtbar).
    if hasProfile then
        pulseRows[#pulseRows + 1] = { label = "Zugriff",
            value = Access.TierLabel(), valueColor = Access.TierColor() }

        local state = Access.IsStale()
        if state == "grace" or state == "expired" then
            pulseRows[#pulseRows + 1] = { label = "Profil",
                value = state == "grace" and "läuft ab" or "abgelaufen",
                valueColor = "warning" }
        end
    end

    pulseRows[#pulseRows + 1] = { label = "Nächster Raid", value = GetNextRaidLabel() }
    pulseRows[#pulseRows + 1] = { label = "Anmeldungen",
        value = signups and tostring(signups) or LOCKED_VALUE,
        valueColor = (not signups) and "textFaint" or nil }
    pulseRows[#pulseRows + 1] = { label = "Materialien",
        value = matValue, valueColor = matColor }
    pulseRows[#pulseRows + 1] = { label = "Sync-Warteschlange",
        value = queueCount > 0 and (queueCount .. " ausstehend") or "Keine",
        valueColor = queueCount > 0 and "warning" or "textDim" }

    WeintCodex.Navigation.SetInspector({
        { type = "header", text = "Gilden-Puls" },
        { type = "rows", rows = pulseRows },
        { type = "divider" },
        { type = "button", style = "primary", label = "Kalender öffnen", onClick = function() GoToTab("calendar") end },
        { type = "button", label = "Daten importieren", onClick = function() GoToTab("import") end },
    })

    homeFrame:Show()
end

function WeintCodex.ResetToHome()
    WeintCodex.ShowHome()
end
