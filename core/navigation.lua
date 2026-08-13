--------------------------------------------------
-- WeintCodex :: Navigation (Tab System)
--------------------------------------------------

WeintCodex.Navigation = {}

local C = WeintCodex.Colors
local activeTab = nil

-- Navigationsspalte (Entwurf 1a): ausgeschriebene Eintraege in drei Gruppen
-- statt der frueheren 64-px-Icon-Rail. id, vorgerendertes Icon (Vektorpfade
-- kann WoW zur Laufzeit nicht zeichnen, siehe media/icons/) und Beschriftung.
--
-- feature: benötigte Freigabe aus dem Zugriffsprofil (core/access.lua). Nur
-- Tabs, deren gesamter Inhalt gildenintern ist, tragen eine - die übrigen
-- gaten innerhalb der Seite, damit ihr neutraler Teil offen bleibt.
--
-- "uebersicht" und "academy" sind mit 2.0 dazugekommen: die Startseite ist im
-- Entwurf ein eigener Navigationspunkt, und die Academy haengt nicht mehr in
-- der Charakter-Unternavigation, sondern steht gleichberechtigt daneben.
--
-- `label` ist die Beschriftung in der Spalte UND der Kopf des Sperr-Tooltips;
-- die Reihenfolge dieser Tabelle ist die Reihenfolge der Spalte.
local ICON_PATH = "Interface\\AddOns\\WeintCodex\\media\\icons\\"
local tabs = {
    { id = "uebersicht", icon = ICON_PATH .. "nav_uebersicht", label = "Übersicht",
      group = "Raid" },
    { id = "bossguides", icon = ICON_PATH .. "nav_bossguides", label = "Bossguides" },
    { id = "raids",      icon = ICON_PATH .. "nav_raids",      label = "Raids",
      feature = "raids.view" },
    { id = "calendar",   icon = ICON_PATH .. "nav_calendar",   label = "Kalender",
      feature = "calendar.view" },
    { id = "weinttv",    icon = ICON_PATH .. "nav_weinttv",    label = "WeintTV" },

    { id = "charakter",  icon = ICON_PATH .. "nav_charakter",  label = "Charakter",
      group = "Charakter" },
    { id = "academy",    icon = ICON_PATH .. "nav_academy",    label = "Academy" },

    { id = "materials",  icon = ICON_PATH .. "nav_materials",  label = "Materialien",
      group = "Gilde", feature = "materials.view" },
    { id = "weakauras",  icon = ICON_PATH .. "nav_weakauras",  label = "WeakAuras" },
    { id = "import",     icon = ICON_PATH .. "nav_import",     label = "Import" },
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

local tabButtons = {}

local NAV_ITEM_H   = 40
local NAV_ITEM_GAP = 2
local NAV_PAD      = 12
local NAV_GROUP_H  = 24   -- Gruppenlabel inkl. 4 px Abstand darunter
local NAV_GROUP_TOP= 16   -- Luft ueber einer neuen Gruppe (ausser der ersten)
local NAV_GLYPH    = 18

-- Icon- und Textfarbe an EINER Stelle: aktiv > gesperrt > Hover > Ruhe. Ohne
-- diesen gemeinsamen Weg würde jedes der drei Skripte (SetTabActive, OnEnter,
-- OnLeave) die Sperr-Abdunklung beim nächsten Ereignis überschreiben.
local function TintIcon(btn, isActive, isHover)
    local iconCol, textCol
    if btn._locked then
        iconCol = isActive and C.textDim or C.textGhost
        textCol = iconCol
    elseif isActive then
        iconCol, textCol = C.accent, C.textBright
    elseif isHover then
        iconCol, textCol = C.textMuted, C.textNormal
    else
        iconCol, textCol = C.textDim, C.textMuted
    end
    btn._icon:SetVertexColor(iconCol[1], iconCol[2], iconCol[3])
    btn._label:SetTextColor(textCol[1], textCol[2], textCol[3])
end

local function SetTabActive(btn, isActive)
    if isActive then
        btn._bg:SetColorTexture(C.surface3[1], C.surface3[2], C.surface3[3], 1.0)
        btn._bar:Show()
        btn._label:SetFont(WeintCodex.Fonts.sansMedium, 13, "")
        for _, t in pairs(btn._corners or {}) do t:Show() end
    else
        btn._bg:SetColorTexture(0, 0, 0, 0)
        btn._bar:Hide()
        btn._label:SetFont(WeintCodex.Fonts.sans, 13, "")
        for _, t in pairs(btn._corners or {}) do t:Hide() end
    end
    TintIcon(btn, isActive, false)
end

-- Aufbau der Spalte: Gruppenlabels und Eintraege laufen auf einem
-- gemeinsamen y-Zaehler, damit eine neue Gruppe die folgenden Eintraege
-- automatisch nach unten schiebt.
do
    local rail = WeintCodex.NavColumn
    local y = -NAV_PAD

    for _, tabDef in ipairs(tabs) do
        if tabDef.group then
            local lbl = WeintCodex.Eyebrow(rail, tabDef.group, { color = "textFaint", size = 10 })
            lbl:SetPoint("TOPLEFT", rail, "TOPLEFT", NAV_PAD + 11, y - NAV_GROUP_TOP + 4)
            y = y - NAV_GROUP_TOP - NAV_GROUP_H
        end

        local btn = CreateFrame("Button", nil, rail)
        btn:SetHeight(NAV_ITEM_H)
        btn:SetPoint("TOPLEFT",  rail, "TOPLEFT",  NAV_PAD, y)
        btn:SetPoint("TOPRIGHT", rail, "TOPRIGHT", -NAV_PAD, y)
        y = y - NAV_ITEM_H - NAV_ITEM_GAP

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(btn)
        bg:SetColorTexture(0, 0, 0, 0)
        btn._bg = bg
        WeintCodex.CutCorners(btn, 10, "bgPanel")
        for _, t in pairs(btn._corners or {}) do t:Hide() end

        -- Aktiv-Indikator: 3x22 Bernsteinbalken am linken Rand der Spalte
        local bar = btn:CreateTexture(nil, "OVERLAY")
        bar:SetSize(3, 22)
        bar:SetPoint("LEFT", btn, "LEFT", -NAV_PAD, 0)
        bar:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1.0)
        bar:Hide()
        btn._bar = bar

        local icon = btn:CreateTexture(nil, "OVERLAY")
        icon:SetSize(NAV_GLYPH, NAV_GLYPH)
        icon:SetPoint("LEFT", btn, "LEFT", 11, 0)
        icon:SetTexture(tabDef.icon)
        btn._icon = icon

        -- Der Entwurf schreibt die Eintraege aus - ohne diesen SetText blieb
        -- die Spalte eine reine Icon-Reihe, also genau die 1.x-Rail, die 2.0
        -- abloesen sollte.
        local label = btn:CreateFontString(nil, "OVERLAY")
        label:SetFont(WeintCodex.Fonts.sans, 13, "")
        label:SetPoint("LEFT", icon, "RIGHT", 10, 0)
        -- Rechte Kante freihalten: dort sitzen Zahl bzw. Statuspunkt.
        label:SetPoint("RIGHT", btn, "RIGHT", -28, 0)
        label:SetJustifyH("LEFT")
        label:SetWordWrap(false)
        label:SetText(tabDef.label)
        btn._label = label

        -- Rechter Rand: entweder eine Zahl (Bossanzahl, Warteschlange) oder
        -- ein Statuspunkt. Beides wird von ShowHome() aus echtem Zustand
        -- gesetzt, siehe SetTabBadge/SetTabCount.
        local count = btn:CreateFontString(nil, "OVERLAY")
        count:SetFont(WeintCodex.Fonts.mono, 10, "")
        count:SetPoint("RIGHT", btn, "RIGHT", -10, 0)
        count:SetTextColor(C.textFaint[1], C.textFaint[2], C.textFaint[3])
        count:Hide()
        btn._count = count

        local dot = WeintCodex.StatusDot(btn, "accent", 7)
        dot:SetPoint("RIGHT", btn, "RIGHT", -10, 0)
        dot:Hide()
        btn._dot = dot

        btn:SetScript("OnEnter", function(self)
            if activeTab ~= tabDef.id then
                self._bg:SetColorTexture(1, 1, 1, 0.04)
                TintIcon(self, false, true)
            end
            if self._locked and WeintCodex.Access then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(tabDef.label)
                GameTooltip:AddLine(WeintCodex.Access.Reason(tabDef.feature),
                    C.textFaint[1], C.textFaint[2], C.textFaint[3], true)
                GameTooltip:Show()
            end
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

        SetTabActive(btn, false)

        tabButtons[tabDef.id] = btn
        table.insert(tabButtons, btn)

        if tabDef.feature then
            tabFeature[tabDef.id] = tabDef.feature
        end
    end
end

--------------------------------------------------
-- Konto-Zeile am Fuss der Spalte
--------------------------------------------------
-- Zeigt den eingeloggten Charakter und den Zustand der Companion-Bruecke.
-- "Verbunden" heisst hier: es liegt eine Inbox-Lieferung vor. Die Inbox wird
-- nur beim Login gelesen - das ist also der Stand der letzten Lieferung, nie
-- eine Live-Verbindung.
--------------------------------------------------

do
    local rail = WeintCodex.NavColumn
    local foot = CreateFrame("Frame", nil, rail)
    foot:SetHeight(44)
    foot:SetPoint("BOTTOMLEFT",  rail, "BOTTOMLEFT",  NAV_PAD, NAV_PAD)
    foot:SetPoint("BOTTOMRIGHT", rail, "BOTTOMRIGHT", -NAV_PAD, NAV_PAD)

    local av = CreateFrame("Frame", nil, foot)
    av:SetSize(28, 28)
    av:SetPoint("LEFT", foot, "LEFT", 0, 0)
    local avTex = av:CreateTexture(nil, "ARTWORK")
    avTex:SetAllPoints(av)
    WeintCodex.ApplyVerticalGradient(avTex, "brandA", "brandB")
    WeintCodex.CutCorners(av, 14, "bgPanel")

    local initial = av:CreateFontString(nil, "OVERLAY")
    initial:SetFont(WeintCodex.Fonts.monoBold, 12, "")
    initial:SetPoint("CENTER", av, "CENTER", 0, 0)
    initial:SetTextColor(1, 1, 1, 1)

    local name = foot:CreateFontString(nil, "OVERLAY")
    name:SetFont(WeintCodex.Fonts.sans, 12, "")
    name:SetPoint("TOPLEFT", av, "TOPRIGHT", 10, -1)
    name:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])

    local state = WeintCodex.Eyebrow(foot, "", { color = "successBright", size = 9 })
    state:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -2)

    function WeintCodex.Navigation.RefreshAccount()
        local who = UnitName("player") or "?"
        initial:SetText(WeintCodex.Upper(WeintCodex.Utf8Sub(who, 1, 1)))
        name:SetText(who)

        local inbox = _G.WeintCompanionInboxDB
        local ver = inbox and inbox.companionVersion
        if ver then
            state:SetText(WeintCodex.Spaced(WeintCodex.Upper("Companion " .. tostring(ver))))
            state:SetTextColor(C.successBright[1], C.successBright[2], C.successBright[3])
        else
            state:SetText(WeintCodex.Spaced("KEINE LIEFERUNG"))
            state:SetTextColor(C.textFaint[1], C.textFaint[2], C.textFaint[3])
        end
    end
end

-- Zahl am rechten Rand eines Navigationseintrags (z.B. "14" bei Bossguides).
function WeintCodex.Navigation.SetTabCount(tabId, value, tone)
    local btn = tabButtons[tabId]
    if not btn or not btn._count then return end
    if value == nil then
        btn._count:Hide()
        return
    end
    local col = C[tone or "textFaint"] or C.textFaint
    btn._count:SetTextColor(col[1], col[2], col[3])
    btn._count:SetText(WeintCodex.Spaced(tostring(value)))
    btn._count:Show()
end

-- Zeigt/versteckt den Benachrichtigungspunkt eines Tabs anhand echten Zustands
-- (z.B. Materialengpass, offene Sync-Warteschlange) - siehe ShowHome().
-- `tone` faerbt den Punkt (Entwurf: rot = Handlungsbedarf, bernstein = Hinweis).
-- Punkt und Zahl teilen sich denselben Platz rechts, deshalb blendet der Punkt
-- eine gesetzte Zahl aus statt sich mit ihr zu ueberlagern.
function WeintCodex.Navigation.SetTabBadge(tabId, on, tone)
    local btn = tabButtons[tabId]
    if not btn or not btn._dot then return end
    if on then
        local col = C[tone or "accent"] or C.accent
        btn._dot:SetColorTexture(col[1], col[2], col[3], 1.0)
        btn._dot:Show()
        if btn._count then btn._count:Hide() end
    else
        btn._dot:Hide()
    end
end

-- Sperrt einen Tab optisch, ohne ihn aus der Leiste zu nehmen. Verstecken
-- wäre teurer und schlechter: die Buttons entstehen zur Ladezeit mit
-- festen Positionen (siehe Schleife oben), ein Filtern müsste sie zur
-- Laufzeit neu verankern und Map wie Array von tabButtons synchron halten.
-- Der gesperrte Tab bleibt außerdem absichtlich klickbar - der Spieler soll
-- draufklicken und lesen können, warum (siehe ShowAccessLock).
-- In der ausgeschriebenen Spalte traegt der gesperrte Zustand sich selbst:
-- TintIcon dunkelt Symbol UND Beschriftung ab. Das fruehere Plaettchen unten
-- links entfaellt damit - es war die Kruecke der reinen Icon-Rail, in der
-- ausser dem Symbol nichts da war, was den Zustand zeigen konnte.
function WeintCodex.Navigation.SetTabLocked(tabId, on)
    local btn = tabButtons[tabId]
    if not btn then return end

    btn._locked = on and true or nil
    TintIcon(btn, activeTab == tabId, false)
end
--------------------------------------------------
-- Unternavigation der Seite
--------------------------------------------------
-- Bis 1.3.3.3 war das eine zweite Fensterspalte (Sidebar, 240 px). Der
-- Entwurf kennt sie nicht mehr: "Die heutige Sidebar-Unternavigation jeder
-- Seite wird zur Reiterleiste unter dem Titel."
--
-- BuildSidebar(sectionTitle, items) bleibt als API bestehen - sieben Module
-- rufen sie auf - und entscheidet nun selbst, wie sie sich zeigt:
--
--   * Reiterleiste (Segmented Control) fuer kurze, flache Listen. Das ist der
--     Regelfall und genau das, was der Entwurf auf Charakter, Raids,
--     Materialien und WeintTV zeigt.
--   * Listenspalte links im Inhalt, sobald Eintraege ein Portraet, eine
--     Statuszeile oder Gruppen tragen. Vierzehn Bosse mit Bild und
--     "erledigt/offen" sind keine Reiter - das waere die eine Stelle, an der
--     die Uebersetzung des Entwurfs kippt, weil er Bossguides nicht zeigt.
--
-- Beides sitzt IN der Seite, nicht im Fensterrahmen. Die Shell bleibt damit
-- auf allen Seiten gleich, was der eigentliche Punkt der Aenderung war.
--------------------------------------------------

local sidebarItems  = {}
local sidebarGroups = {}
local subNavStrip   = nil   -- Reiterleiste
local subNavColumn  = nil   -- Listenspalte

local SUBNAV_COL_W  = 232
local SUBNAV_TOP_H  = 54    -- Reiterleiste 38 + 16 Abstand

local function EnsureSubNavColumn()
    if subNavColumn then return subNavColumn end
    local col = CreateFrame("Frame", nil, WeintCodex.ContentHost)
    col:SetWidth(SUBNAV_COL_W)
    col:SetPoint("TOPLEFT",    WeintCodex.ContentHost, "TOPLEFT",    0, 0)
    col:SetPoint("BOTTOMLEFT", WeintCodex.ContentHost, "BOTTOMLEFT", 0, 0)
    local div = col:CreateTexture(nil, "OVERLAY")
    div:SetPoint("TOPRIGHT",    col, "TOPRIGHT",    0, 0)
    div:SetPoint("BOTTOMRIGHT", col, "BOTTOMRIGHT", 0, 0)
    div:SetWidth(1)
    div:SetColorTexture(C.border[1], C.border[2], C.border[3], 1.0)
    subNavColumn = col
    return col
end

function WeintCodex.Navigation.ClearSidebar()
    for _, item in ipairs(sidebarItems) do item:Hide() end
    for _, grp  in ipairs(sidebarGroups) do grp:Hide()  end
    wipe(sidebarItems)
    wipe(sidebarGroups)
    if subNavStrip then subNavStrip:Hide() end
    if subNavColumn then subNavColumn:Hide() end
    WeintCodex.SetSubNavWidth(0)
    WeintCodex.SetSubNavTop(0)
end

-- Entscheidet die Darstellungsform. Sobald ein Eintrag mehr ist als eine
-- Beschriftung, wird aus der Leiste eine Liste.
local function NeedsColumn(items)
    local count = 0
    for _, it in ipairs(items) do
        if it.isGroup or it.portrait or it.status or it.indent then return true end
        count = count + 1
    end
    return count > 7
end

--------------------------------------------------
-- Darstellung 1: Reiterleiste
--------------------------------------------------

local function BuildStrip(items)
    local segItems = {}
    for i, it in ipairs(items) do
        segItems[i] = { text = it.label or "", dot = it.dot, key = i }
    end

    local strip = WeintCodex.CreateSegmentedControl(WeintCodex.ContentHost, {
        items = segItems,
        backdrop = "bgDark",
        onSelect = function(_, index)
            local def = items[index]
            if def and def.onClick then def.onClick() end
        end,
    })
    strip:SetPoint("TOPLEFT", WeintCodex.ContentHost, "TOPLEFT",
        WeintCodex.Metrics.PAD_X, -WeintCodex.Metrics.PAD_Y)

    subNavStrip = strip
    WeintCodex.SetSubNavTop(WeintCodex.Metrics.PAD_Y + SUBNAV_TOP_H)

    -- Die Reiter selbst dienen als "sidebarItems", damit ActivateFirst und
    -- UpdateSidebarStatus unveraendert weiterfunktionieren.
    for i, seg in ipairs(strip._segments or {}) do
        seg.SetActive = function() end
        sidebarItems[i] = seg
    end
end

--------------------------------------------------
-- Darstellung 2: Listenspalte
--------------------------------------------------

local function BuildColumn(sectionTitle, items)
    local col = EnsureSubNavColumn()
    col:Show()
    WeintCodex.SetSubNavWidth(SUBNAV_COL_W)

    local pad = 16
    local title = WeintCodex.Eyebrow(col, sectionTitle or "", { color = "textFaint" })
    title:SetPoint("TOPLEFT", col, "TOPLEFT", pad + 11, -WeintCodex.Metrics.PAD_Y)
    table.insert(sidebarGroups, title)

    local offsetY = -WeintCodex.Metrics.PAD_Y - 26

    for _, itemDef in ipairs(items) do
        if itemDef.isGroup then
            local lbl = WeintCodex.Eyebrow(col, itemDef.label or "", { color = "textGhost" })
            lbl:SetPoint("TOPLEFT", col, "TOPLEFT", pad + 11, offsetY - 8)
            table.insert(sidebarGroups, lbl)
            offsetY = offsetY - 26
        else
            local hasStatus = itemDef.status ~= nil
            local itemH = hasStatus and 44 or 36

            local btn = CreateFrame("Button", nil, col)
            btn:SetHeight(itemH)
            btn:SetPoint("TOPLEFT",  col, "TOPLEFT",  pad, offsetY)
            btn:SetPoint("TOPRIGHT", col, "TOPRIGHT", -pad, offsetY)

            local bg = btn:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(btn)
            bg:SetColorTexture(0, 0, 0, 0)
            btn._bg = bg
            WeintCodex.CutCorners(btn, 10, "bgDark")
            for _, t in pairs(btn._corners or {}) do t:Hide() end

            -- Dauerhafter Akzentstreifen (z.B. End-Boss), unabhaengig vom
            -- Aktiv-/Hover-Zustand sichtbar.
            local accentColor = itemDef.accentColor and C[itemDef.accentColor]
            local accent = btn:CreateTexture(nil, "OVERLAY")
            accent:SetSize(3, 22)
            accent:SetPoint("LEFT", btn, "LEFT", -pad, 0)
            btn._accent = accent

            local function BaselineAccent()
                if accentColor then
                    accent:SetColorTexture(accentColor[1], accentColor[2], accentColor[3], 0.60)
                    accent:Show()
                else
                    accent:Hide()
                end
            end
            BaselineAccent()

            local textX = 12

            if itemDef.portrait then
                local box = btn:CreateTexture(nil, "ARTWORK")
                box:SetSize(28, 28)
                box:SetPoint("LEFT", btn, "LEFT", 10, 0)
                box:SetTexture(itemDef.portrait)
                box:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                btn._portrait = box
                textX = 46
            end

            local label = btn:CreateFontString(nil, "OVERLAY")
            label:SetFont(WeintCodex.Fonts.sans, 13, "")
            label:SetJustifyH("LEFT")
            label:SetText(itemDef.label or "")
            label:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
            if hasStatus then
                label:SetPoint("TOPLEFT", btn, "TOPLEFT", textX, -6)
            else
                label:SetPoint("LEFT", btn, "LEFT", textX, 0)
            end
            label:SetPoint("RIGHT", btn, "RIGHT", -12, 0)
            btn._label = label

            if hasStatus then
                local st = btn:CreateFontString(nil, "OVERLAY")
                st:SetFont(WeintCodex.Fonts.mono, 9, "")
                st:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -3)
                local sc = C[itemDef.status.color or "textFaint"] or C.textFaint
                st:SetTextColor(sc[1], sc[2], sc[3])
                st:SetText(WeintCodex.Spaced(WeintCodex.Upper(itemDef.status.text or "")))
                btn._statusLbl = st
            end

            local function SetActive(self, on)
                self._isActive = on
                if on then
                    self._bg:SetColorTexture(C.surface3[1], C.surface3[2], C.surface3[3], 1.0)
                    self._label:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
                    self._label:SetFont(WeintCodex.Fonts.sansMedium, 13, "")
                    self._accent:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1.0)
                    self._accent:Show()
                    for _, t in pairs(self._corners or {}) do t:Show() end
                else
                    self._bg:SetColorTexture(0, 0, 0, 0)
                    self._label:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
                    self._label:SetFont(WeintCodex.Fonts.sans, 13, "")
                    BaselineAccent()
                    for _, t in pairs(self._corners or {}) do t:Hide() end
                end
            end
            btn.SetActive = SetActive

            btn:SetScript("OnEnter", function(self)
                if not self._isActive then
                    self._bg:SetColorTexture(1, 1, 1, 0.04)
                    self._label:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
                end
            end)
            btn:SetScript("OnLeave", function(self)
                if not self._isActive then
                    self._bg:SetColorTexture(0, 0, 0, 0)
                    self._label:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
                end
            end)
            btn:SetScript("OnClick", function(self)
                for _, s in ipairs(sidebarItems) do s:SetActive(false) end
                self:SetActive(true)
                if itemDef.onClick then itemDef.onClick() end
            end)

            table.insert(sidebarItems, btn)
            offsetY = offsetY - itemH - 2
        end
    end
end

function WeintCodex.Navigation.BuildSidebar(sectionTitle, items)
    WeintCodex.Navigation.ClearSidebar()
    items = items or {}
    if NeedsColumn(items) then
        BuildColumn(sectionTitle, items)
    else
        BuildStrip(items)
    end
end

-- Aktualisiert nur die Status-Subline eines bereits gebauten Eintrags
-- (z.B. Boss-Kill waehrend des Raids), ohne die Unternavigation neu
-- aufzubauen - der aktuell angeklickte Eintrag bleibt dadurch markiert.
-- index bezieht sich auf die Reihenfolge der Nicht-Gruppen-Eintraege.
function WeintCodex.Navigation.UpdateSidebarStatus(index, status)
    local btn = sidebarItems[index]
    if not (btn and btn._statusLbl and status) then return end
    local sc = C[status.color or "textFaint"] or C.textFaint
    btn._statusLbl:SetTextColor(sc[1], sc[2], sc[3])
    btn._statusLbl:SetText(WeintCodex.Spaced(WeintCodex.Upper(status.text or "")))
end

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
    -- Ohne Bloecke gibt es keinen Detailbereich: der Inhalt bekommt die
    -- volle Breite zurueck. Frueher blieb die Spalte als leere Flaeche stehen.
    WeintCodex.SetDetailShown(false)
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
    h:SetFont(WeintCodex.Fonts.sans, 9, "")
    h:SetPoint("TOPLEFT",  parent, "TOPLEFT",  INSPECTOR_PAD, y)
    h:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -INSPECTOR_PAD, y)
    h:SetJustifyH("LEFT")
    h:SetText(WeintCodex.ColorText("textFaint", WeintCodex.Upper(text or "")))
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
        lbl:SetFont(WeintCodex.Fonts.sans, 11, "")
        lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", INSPECTOR_PAD, y)
        lbl:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
        lbl:SetText(row.label or "")
        table.insert(inspectorWidgets, lbl)

        local val = parent:CreateFontString(nil, "OVERLAY")
        val:SetFont(WeintCodex.Fonts.sans, 11, "")
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
    lbl:SetFont(WeintCodex.Fonts.sans, 11, "")
    lbl:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -7)
    lbl:SetPoint("RIGHT", card, "RIGHT", -70, 0)
    lbl:SetJustifyH("LEFT")
    local lc = C[item.labelColor or "textNormal"] or C.textNormal
    lbl:SetTextColor(lc[1], lc[2], lc[3])
    lbl:SetText(item.label or "")

    local val = card:CreateFontString(nil, "OVERLAY")
    val:SetFont(WeintCodex.Fonts.sans, 10, "")
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
    lbl:SetFont(WeintCodex.Fonts.sans, 11, "")
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
        t:SetFont(WeintCodex.Fonts.sans, 12, "")
        t:SetPoint("TOPLEFT", card, "TOPLEFT", 10, yy)
        t:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
        t:SetText(opts.title)
        yy = yy - 18
    end
    if opts.subtitle then
        local s = card:CreateFontString(nil, "OVERLAY")
        s:SetFont(WeintCodex.Fonts.sans, 9, "")
        s:SetPoint("TOPLEFT", card, "TOPLEFT", 10, yy)
        s:SetTextColor(C.textFaint[1], C.textFaint[2], C.textFaint[3])
        s:SetText(opts.subtitle)
        yy = yy - 14
    end
    for _, line in ipairs(opts.lines or {}) do
        local l = card:CreateFontString(nil, "OVERLAY")
        l:SetFont(WeintCodex.Fonts.sans, 10, "")
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
    lbl:SetFont(WeintCodex.Fonts.sans, 11, "")
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
    l:SetFont(WeintCodex.Fonts.sans, 9, "")
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
    l:SetFont(WeintCodex.Fonts.sans, 10, "")
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
            t:SetFont(WeintCodex.Fonts.sans, 9, "")
            t:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, -3)
            t:SetJustifyH("LEFT")
            t:SetText(WeintCodex.ColorText("textFaint", WeintCodex.Upper(opts.title)))
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
    footLeft:SetFont(WeintCodex.Fonts.sans, 9, "")
    footLeft:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 1, 1)
    footLeft:SetJustifyH("LEFT")

    local footRight = holder:CreateFontString(nil, "OVERLAY")
    footRight:SetFont(WeintCodex.Fonts.sans, 9, "")
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
        box:SetFont(WeintCodex.Fonts.sans, 11, "")
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
        c.thumb:SetColorTexture(C.textFaint[1], C.textFaint[2], C.textFaint[3], 0.65)
        c.thumb:Hide()

        c.hint = card:CreateFontString(nil, "ARTWORK")
        c.hint:SetFont(WeintCodex.Fonts.sans, 10, "")
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
        q:SetFont(WeintCodex.Fonts.sans, 10, "")
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
    name:SetFont(WeintCodex.Fonts.sans, 11, "")
    name:SetPoint("TOPLEFT",  row, "TOPLEFT",  30, nameTop)
    name:SetPoint("TOPRIGHT", row, "TOPRIGHT", -(state.size + 12), nameTop)
    name:SetJustifyH("LEFT")
    name:SetWordWrap(false)
    row._name = name

    if hasSub then
        local sub = row:CreateFontString(nil, "OVERLAY")
        sub:SetFont(WeintCodex.Fonts.sans, 9, "")
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
        empty:SetFont(WeintCodex.Fonts.sans, 11, "")
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
    if not blocks or #blocks == 0 then return end

    -- Der Detailbereich ist keine eigene Fensterspalte mehr, sondern die
    -- rechte Spalte der Seite (372 px, Entwurf: Raster "1fr 372px"). Er
    -- erscheint nur, wenn es wirklich etwas zu zeigen gibt - ContentPanel
    -- schrumpft dann automatisch, die Module merken davon nichts.
    WeintCodex.SetDetailShown(true)

    local parent = WeintCodex.Inspector
    local y = 0

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

    if tabId == "uebersicht" then
        -- Die Startseite ist mit 2.0 ein eigener Navigationspunkt. ShowHome
        -- raeumt selbst auf, deshalb genuegt der direkte Aufruf.
        if WeintCodex.ShowHome then WeintCodex.ShowHome() end
    elseif tabId == "academy" then
        -- Bis 1.3.3.3 haing die Academy in der Charakter-Unternavigation. Sie
        -- steht jetzt gleichberechtigt in der Spalte; ihre drei Ansichten
        -- (Uebersicht/Trainingsplan/Katalog) sind die Reiterleiste der Seite.
        if WeintCodex.Academy and WeintCodex.Academy.ShowOverview then
            if WeintCodex.Charakter and WeintCodex.Charakter.LeaveView then
                WeintCodex.Charakter.LeaveView()
            end
            WeintCodex.Navigation.BuildSidebar("Academy", {
                { label = "Übersicht",    onClick = function() WeintCodex.Academy.ShowOverview() end },
                { label = "Trainingsplan", onClick = function() WeintCodex.Academy.ShowPlan()    end },
                { label = "Katalog",       onClick = function() WeintCodex.Academy.ShowCatalog() end },
            })
            WeintCodex.Navigation.ActivateFirst()
        end
    elseif tabId == "charakter" then
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
        t:SetFont(WeintCodex.Fonts.sansSemi, 20, "")
        t:SetPoint("CENTER", pf, "CENTER", 0, 30)
        t:SetTextColor(C.purple[1], C.purple[2], C.purple[3])
        pf._title = t

        local sub = pf:CreateFontString(nil, "OVERLAY")
        sub:SetFont(WeintCodex.Fonts.sans, 12, "")
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
        title:SetFont(WeintCodex.Fonts.sansBold, 22, "")
        title:SetPoint("TOPLEFT", card, "TOPLEFT", 16, -14)
        title:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
        lf._title = title

        local reason = card:CreateFontString(nil, "OVERLAY")
        reason:SetFont(WeintCodex.Fonts.sans, 12, "")
        reason:SetPoint("TOPLEFT",  title, "BOTTOMLEFT", 0, -10)
        reason:SetPoint("RIGHT",    card,  "RIGHT",     -16, 0)
        reason:SetJustifyH("LEFT")
        reason:SetSpacing(3)
        reason:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
        lf._reason = reason

        local hint = card:CreateFontString(nil, "OVERLAY")
        hint:SetFont(WeintCodex.Fonts.sans, 11, "")
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
-- Daten der Startseite
--------------------------------------------------

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

-- Die acht Modulkacheln der v1-Startseite sind mit 2.0 entfallen: die
-- Navigationsspalte schreibt dieselben Bereiche aus, eine zweite Liste
-- derselben Namen war das "Menue statt Antwort", das der Entwurf abloest.
--------------------------------------------------
-- Startseite (Entwurf 1a: "Was ist jetzt zu tun?")
--------------------------------------------------
-- Die Startseite beantwortet den Abend, nicht das Menue. Aufbau von oben nach
-- unten: eine Handlungskarte zum naechsten Raid, darunter drei Spalten mit
-- dem, was offen ist (eigene Ausruestung, geplante Bosse, Gildenbank), unten
-- eine Systemzeile zum Zustand der Companion-Bruecke.
--
-- Die frueheren acht Modulkacheln sind entfallen: die Navigationsspalte
-- schreibt die Bereiche seit 2.0 aus, eine zweite Liste derselben Namen war
-- genau das "Menue statt Antwort", das der Entwurf abloest. Erreichbar bleibt
-- alles ueber die Spalte links.
--------------------------------------------------

local homeFrame = nil

-- Bricht Text in der Karte nicht mittig ab, sondern kuerzt sauber.
-- Kuerzt in ZEICHEN, nicht in Bytes: ein byteweiser Schnitt trennt einen
-- Umlaut oder Gedankenstrich in der Mitte auf, und der Client zeichnet den
-- Rest als leeres Kaestchen ("... 15.0% <>…" auf der Startseite).
local function Ellipsis(text, maxChars)
    return WeintCodex.Truncate(text, maxChars)
end

function WeintCodex.ShowHome()
    ClearContentPanel()
    WeintCodex.Navigation.ClearSidebar()
    WeintCodex.Navigation.ClearTitleActions()
    WeintCodex.Navigation.ClearInspector()
    WeintCodex.SetBreadcrumb("Übersicht")
    if WeintCodex.Navigation.RefreshAccount then
        WeintCodex.Navigation.RefreshAccount()
    end

    local PAD_X = WeintCodex.Metrics.PAD_X
    local PAD_Y = WeintCodex.Metrics.PAD_Y
    local GAP   = WeintCodex.Metrics.GAP

    if homeFrame then homeFrame:Hide() end
    homeFrame = CreateFrame("Frame", nil, WeintCodex.ContentPanel)
    homeFrame:SetAllPoints(WeintCodex.ContentPanel)
    local root = homeFrame

    --------------------------------------------------
    -- Kopf
    --------------------------------------------------

    local today = date("*t")
    local WEEKDAYS = { "Sonntag", "Montag", "Dienstag", "Mittwoch",
                       "Donnerstag", "Freitag", "Samstag" }
    local MONTHS = { "Januar", "Februar", "März", "April", "Mai", "Juni", "Juli",
                     "August", "September", "Oktober", "November", "Dezember" }

    local eyebrow = WeintCodex.Eyebrow(root,
        string.format("%s, %d. %s", WEEKDAYS[today.wday] or "", today.day,
                      MONTHS[today.month] or ""))
    eyebrow:SetPoint("TOPLEFT", root, "TOPLEFT", PAD_X, -PAD_Y)

    -- Ueberschrift benennt den Handlungsbedarf, nicht den Bereich.
    local scan
    if WeintCodex.Charakter and WeintCodex.Charakter.Scan then
        local ok, result = pcall(WeintCodex.Charakter.Scan)
        if ok then scan = result end
    end
    local openIssues = 0
    for _, iss in ipairs((scan and scan.issues) or {}) do
        if iss.status == "missing" or iss.status == "empty" or iss.status == "wrong" then
            openIssues = openIssues + 1
        end
    end

    local shortages, matKnown, matLocked = GetMaterialShortageCount()
    local headline
    if openIssues > 0 then
        headline = openIssues == 1 and "Eine Sache ist noch offen"
                                   or (openIssues .. " Dinge sind noch offen")
    elseif shortages > 0 and not matLocked then
        headline = "Ausrüstung sitzt – die Gildenbank nicht"
    else
        headline = "Alles bereit"
    end

    local title = WeintCodex.PageTitle(root, headline)
    title:SetPoint("TOPLEFT", eyebrow, "BOTTOMLEFT", 0, -6)

    --------------------------------------------------
    -- Handlungskarte: naechster Raid
    --------------------------------------------------

    local action = WeintCodex.CreateSurface(root, {
        height = 116, tone = "accent", radius = 14, backdrop = "bgDark",
    })
    action:SetPoint("TOPLEFT",  root, "TOPLEFT",  PAD_X, -(PAD_Y + 72))
    action:SetPoint("TOPRIGHT", root, "TOPRIGHT", -PAD_X, -(PAD_Y + 72))

    local aEyebrow = WeintCodex.Eyebrow(action, "Nächster Raid",
        { color = "accentBright", size = 11 })
    aEyebrow:SetPoint("TOPLEFT", action, "TOPLEFT", 20, -16)

    local raidLabel = GetNextRaidLabel()
    local aTitle = action:CreateFontString(nil, "OVERLAY")
    aTitle:SetFont(WeintCodex.Fonts.sansSemi, 17, "")
    aTitle:SetPoint("TOPLEFT", aEyebrow, "BOTTOMLEFT", 0, -8)
    aTitle:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
    aTitle:SetText(raidLabel)

    local signups = GetSignupCount()
    local aSub = WeintCodex.Label(action,
        signups and "Anmeldungen liegen vor – Raidliste im Bereich Raids"
                or "Keine Anmeldeliste vorhanden",
        { color = "textMuted", size = 13 })
    aSub:SetPoint("TOPLEFT", aTitle, "BOTTOMLEFT", 0, -6)

    -- Rechte Seite: Kennzahl + Schaltflaeche
    local aBtn = WeintCodex.CreateButton(action, {
        text = "Raids öffnen", kind = "primary", backdrop = "accentCardTop",
        onClick = function() GoToTab("raids") end,
    })
    aBtn:SetPoint("RIGHT", action, "RIGHT", -20, 0)

    if signups then
        local nCap = action:CreateFontString(nil, "OVERLAY")
        nCap:SetFont(WeintCodex.Fonts.monoBold, 26, "")
        nCap:SetPoint("RIGHT", aBtn, "LEFT", -24, 6)
        nCap:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
        nCap:SetText(tostring(signups))

        local nLbl = WeintCodex.Eyebrow(action, "Angemeldet", { size = 10 })
        nLbl:SetPoint("TOPRIGHT", nCap, "BOTTOMRIGHT", 0, -4)
    end

    --------------------------------------------------
    -- Drei Spalten
    --------------------------------------------------

    local COL_TOP = PAD_Y + 72 + 116 + GAP
    local BOTTOM  = PAD_Y + 48 + GAP   -- Platz fuer die Systemzeile

    -- Die drei Spalten teilen sich die Breite. WoW kennt keine Rasterspalten,
    -- deshalb sitzt jede in einem unsichtbaren Traeger, dessen Breite bei
    -- jeder Groessenaenderung des Rasters neu gerechnet wird - das Fenster ist
    -- in der Groesse veraenderbar, feste Breiten waeren nach dem ersten Ziehen
    -- am Griff falsch.
    local grid = CreateFrame("Frame", nil, root)
    grid:SetPoint("TOPLEFT",     root, "TOPLEFT",      PAD_X, -COL_TOP)
    grid:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -PAD_X,  BOTTOM)

    local function Column(index)
        local holder = CreateFrame("Frame", nil, grid)
        holder:SetPoint("TOP",    grid, "TOP",    0, 0)
        holder:SetPoint("BOTTOM", grid, "BOTTOM", 0, 0)
        holder:SetPoint("LEFT",  grid, "LEFT", 0, 0)
        holder:SetPoint("RIGHT", grid, "LEFT", 0, 0)
        -- Breite/Position relativ ueber ein OnSizeChanged, weil die Breite des
        -- Rasters erst nach dem Layout feststeht.
        local function place()
            local w = grid:GetWidth() or 0
            if w <= 0 then return end
            local colW = (w - 2 * GAP) / 3
            holder:ClearAllPoints()
            holder:SetPoint("TOPLEFT", grid, "TOPLEFT", (index - 1) * (colW + GAP), 0)
            holder:SetSize(colW, grid:GetHeight() or 1)
        end
        grid:HookScript("OnSizeChanged", place)
        place()

        local card = WeintCodex.CreateSurface(holder, {
            tone = "plain", radius = 14, backdrop = "bgDark",
        })
        card:SetAllPoints(holder)
        return card
    end

    local function CardHeader(card, titleText, chipText, chipTone)
        local t = card:CreateFontString(nil, "OVERLAY")
        t:SetFont(WeintCodex.Fonts.sansSemi, 14, "")
        t:SetPoint("TOPLEFT", card, "TOPLEFT", 20, -16)
        t:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
        t:SetText(titleText)
        if chipText then
            -- Fuellung im Grundton, Beschriftung in der hellen Variante -
            -- aber nur, wenn es sie gibt. "textMuted" hat keine, und ein
            -- nicht existierender Name faerbt still auf Normaltext zurueck.
            local tone = chipTone or "textMuted"
            local bright = C[tone .. "Bright"] and (tone .. "Bright") or tone
            local chip = WeintCodex.Chip(card, {
                text = chipText, tone = tone, textColor = bright,
                backdrop = "cardTop", height = 22, size = 9,
            })
            chip:SetPoint("TOPRIGHT", card, "TOPRIGHT", -16, -14)
        end
        return t
    end

    -- Zeile mit Punkt links, Text, Kennwert rechts
    local function StateRow(parent, y, dotTone, text, value, valueTone)
        local row = CreateFrame("Frame", nil, parent)
        row:SetHeight(34)
        row:SetPoint("TOPLEFT",  parent, "TOPLEFT",  20, y)
        row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -16, y)

        local dot = WeintCodex.StatusDot(row, dotTone, 7)
        dot:SetPoint("LEFT", row, "LEFT", 0, 0)

        local val
        if value then
            val = row:CreateFontString(nil, "OVERLAY")
            val:SetFont(WeintCodex.Fonts.monoBold, 10, "")
            val:SetPoint("RIGHT", row, "RIGHT", 0, 0)
            local vc = C[valueTone or "textMuted"] or C.textMuted
            val:SetTextColor(vc[1], vc[2], vc[3])
            val:SetText(WeintCodex.Spaced(WeintCodex.Upper(value)))
        end

        local lbl = row:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(WeintCodex.Fonts.sans, 13, "")
        lbl:SetPoint("LEFT", dot, "RIGHT", 10, 0)
        lbl:SetPoint("RIGHT", val or row, val and "LEFT" or "RIGHT", val and -8 or 0, 0)
        lbl:SetJustifyH("LEFT")
        lbl:SetWordWrap(false)
        lbl:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
        lbl:SetText(text)

        WeintCodex.RowLine(row, -33)
        return y - 36
    end

    --------------------------------------------------
    -- Spalte 1: Deine Vorbereitung
    --------------------------------------------------

    local prep = Column(1)
    CardHeader(prep, "Deine Vorbereitung",
        openIssues > 0 and (openIssues .. " offen") or "bereit",
        openIssues > 0 and "danger" or "success")

    local specLine = WeintCodex.Eyebrow(prep,
        (scan and scan.specDisplay) or "Keine Spezialisierung erkannt",
        { size = 10 })
    specLine:SetPoint("TOPLEFT", prep, "TOPLEFT", 20, -44)

    local y = -66
    local shown = 0
    for _, iss in ipairs((scan and scan.issues) or {}) do
        if shown >= 4 then break end
        local tone, tag
        if iss.status == "missing" then tone, tag = "danger", "fehlt"
        elseif iss.status == "empty" then tone, tag = "danger", "leer"
        elseif iss.status == "wrong" then tone, tag = "violet", "falsch"
        else tone, tag = "warning", "prüfen" end
        y = StateRow(prep, y, tone, Ellipsis(iss.text, 42), tag,
                     tone == "violet" and "violetBright" or (tone .. "Bright"))
        shown = shown + 1
    end
    if shown == 0 then
        y = StateRow(prep, y, "success", "Verzauberungen und Sockel vollständig",
                     "ok", "successBright")
    end

    local prepBtn = WeintCodex.CreateButton(prep, {
        text = "Charakter prüfen", kind = "secondary", backdrop = "cardBottom",
        onClick = function() GoToTab("charakter") end,
    })
    prepBtn:SetPoint("BOTTOMLEFT",  prep, "BOTTOMLEFT",  20, 16)
    prepBtn:SetPoint("BOTTOMRIGHT", prep, "BOTTOMRIGHT", -20, 16)

    --------------------------------------------------
    -- Spalte 2: Heute geplant
    --------------------------------------------------

    local bosses = Column(2)

    -- Der Fortschritt kommt aus modules/bossguides.lua, weil dort die
    -- Bossreihenfolge und der Instanzname liegen. Frueher las diese Stelle
    -- SavedData.encounterProgress selbst - und zwar falsch: der Zweig ist
    -- positionsbasiert (bosses[<Index>] mit dem Feld `cleared`), gelesen wurde
    -- aber ueber pairs() nach einem Feld `killed`, das es nicht gibt. Damit war
    -- die Zahl links immer 0, die Zahl rechts die Menge der beruehrten Bosse
    -- ("0/8") statt der Bossanzahl der Instanz, und die Zeilen darunter trugen
    -- Encounter-Indizes als Namen.
    local prog = WeintCodex.BossGuides and WeintCodex.BossGuides.GetProgress
                 and WeintCodex.BossGuides.GetProgress()
    local totalCount = (prog and prog.total) or 0
    local downCount  = (prog and prog.cleared) or 0
    local openBosses = (prog and prog.open) or {}
    local allDown    = totalCount > 0 and downCount >= totalCount

    CardHeader(bosses, "Heute geplant",
        totalCount > 0 and (downCount .. "/" .. totalCount .. " gelegt") or nil,
        allDown and "success" or (downCount > 0 and "warning" or "textMuted"))

    -- Bezugsrahmen ist die laufende Raid-ID, nicht der Kalendertag: der
    -- Lockout laeuft bis zum Mittwochs-Reset, "heute geplant" ist genau das,
    -- was davon noch offen ist.
    local noteLine = WeintCodex.Eyebrow(bosses,
        Ellipsis(prog and prog.instance or "Kein Raid hinterlegt", 24),
        { size = 10 })
    noteLine:SetPoint("TOPLEFT", bosses, "TOPLEFT", 20, -44)

    y = -66
    for i = 1, math.min(3, #openBosses) do
        y = StateRow(bosses, y, "warning", Ellipsis(openBosses[i], 34), "offen", "accentBright")
    end
    if #openBosses == 0 then
        y = StateRow(bosses, y,
            allDown and "success" or nil,
            allDown and "Alle Bosse dieser ID liegen" or "Noch keine Bossdaten",
            nil)
    elseif #openBosses > 3 then
        y = StateRow(bosses, y, nil,
            "und " .. (#openBosses - 3) .. " weitere", nil)
    end

    local bossBtn = WeintCodex.CreateButton(bosses, {
        text = "Bossguide öffnen", kind = "secondary", backdrop = "cardBottom",
        onClick = function() GoToTab("bossguides") end,
    })
    bossBtn:SetPoint("BOTTOMLEFT",  bosses, "BOTTOMLEFT",  20, 16)
    bossBtn:SetPoint("BOTTOMRIGHT", bosses, "BOTTOMRIGHT", -20, 16)

    --------------------------------------------------
    -- Spalte 3: Gildenbank
    --------------------------------------------------

    local bank = Column(3)
    CardHeader(bank, "Gildenbank",
        matLocked and "gesperrt"
            or (shortages > 0 and (shortages .. " engpässe") or (matKnown and "im soll" or "kein scan")),
        matLocked and "textMuted" or (shortages > 0 and "danger" or "success"))

    local matData = WeintCodex.SavedData and WeintCodex.SavedData.materialData
    local scanLine = WeintCodex.Eyebrow(bank,
        matLocked and "Keine Freigabe"
            or (matData and matData.scanned and ("Scan " .. tostring(matData.scanned))
                or "Noch kein Scan"),
        { size = 10 })
    scanLine:SetPoint("TOPLEFT", bank, "TOPLEFT", 20, -44)

    y = -70
    if matLocked then
        StateRow(bank, y, nil, "Materialien sind für dich gesperrt", nil)
    elseif not matKnown then
        StateRow(bank, y, nil, "Noch nichts importiert", nil)
    else
        -- Die drei knappsten Posten mit Fortschrittsbalken, wie im Entwurf.
        local worst = {}
        for _, item in ipairs((matData and matData.items) or {}) do
            local amount = tonumber(item.count)  or 0
            local target = tonumber(item.target) or 0
            if target > 0 then
                worst[#worst + 1] = { name = item.name, amount = amount,
                                      target = target, pct = amount / target }
            end
        end
        table.sort(worst, function(a, b) return a.pct < b.pct end)

        for i = 1, math.min(3, #worst) do
            local it = worst[i]
            local tone = it.pct < 0.30 and "red" or (it.pct < 0.70 and "gold" or "green")
            local textTone = it.pct < 0.30 and "dangerBright"
                or (it.pct < 0.70 and "accentBright" or "successBright")

            local nameLbl = WeintCodex.Label(bank, Ellipsis(it.name, 26),
                { color = "textNormal", size = 13 })
            nameLbl:SetPoint("TOPLEFT", bank, "TOPLEFT", 20, y)

            local valLbl = bank:CreateFontString(nil, "OVERLAY")
            valLbl:SetFont(WeintCodex.Fonts.monoBold, 10, "")
            valLbl:SetPoint("TOPRIGHT", bank, "TOPRIGHT", -20, y - 1)
            local vc = C[textTone]
            valLbl:SetTextColor(vc[1], vc[2], vc[3])
            valLbl:SetText(it.amount .. "/" .. it.target)

            local meter = WeintCodex.CreateMeter(bank, { height = 6, tone = tone })
            meter:SetPoint("TOPLEFT",  bank, "TOPLEFT",  20, y - 20)
            meter:SetPoint("TOPRIGHT", bank, "TOPRIGHT", -20, y - 20)
            -- Breite steht erst nach dem Layout fest; der Balken zieht nach.
            meter:HookScript("OnSizeChanged", function(self)
                self:SetValue(math.min(1, it.pct))
            end)
            meter:SetValue(math.min(1, it.pct))

            y = y - 46
        end
    end

    local bankBtn = WeintCodex.CreateButton(bank, {
        text = "Materialien ansehen", kind = "secondary", backdrop = "cardBottom",
        onClick = function() GoToTab("materials") end,
    })
    bankBtn:SetPoint("BOTTOMLEFT",  bank, "BOTTOMLEFT",  20, 16)
    bankBtn:SetPoint("BOTTOMRIGHT", bank, "BOTTOMRIGHT", -20, 16)

    --------------------------------------------------
    -- Systemzeile
    --------------------------------------------------

    local sysRow = WeintCodex.CreateSurface(root, {
        height = 48, tone = "flat", surface = "bgMid", radius = 10, backdrop = "bgDark",
    })
    sysRow:SetPoint("BOTTOMLEFT",  root, "BOTTOMLEFT",  PAD_X, PAD_Y)
    sysRow:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -PAD_X, PAD_Y)

    local inbox = _G.WeintCompanionInboxDB
    local queueCount = GetQueueCount()

    local sysDot = WeintCodex.StatusDot(sysRow, inbox and "green" or nil, 7)
    sysDot:SetPoint("LEFT", sysRow, "LEFT", 16, 0)

    local parts = {}
    if inbox and inbox.companionVersion then
        parts[#parts + 1] = "Companion " .. tostring(inbox.companionVersion)
    else
        parts[#parts + 1] = "Keine Companion-Lieferung"
    end
    if queueCount > 0 then
        parts[#parts + 1] = queueCount .. (queueCount == 1 and " Nachricht" or " Nachrichten")
            .. " in der Warteschlange"
    end
    -- Die Inbox wird nur beim Login gelesen. Das steht hier, weil die Zeile
    -- sonst wie eine Live-Verbindung aussieht - sie ist der Stand der
    -- letzten Lieferung.
    parts[#parts + 1] = "Stand der letzten Lieferung"

    local sysLbl = WeintCodex.Label(sysRow, table.concat(parts, " · "),
        { color = "textMuted", size = 13 })
    sysLbl:SetPoint("LEFT", sysDot, "RIGHT", 12, 0)

    local importBtn = WeintCodex.CreateButton(sysRow, {
        text = "Jetzt importieren", kind = "secondary", backdrop = "bgMid",
        onClick = function()
            if WeintCodex.Sync and WeintCodex.Sync.ShowImportDialog then
                WeintCodex.Sync.ShowImportDialog()
            end
        end,
    })
    importBtn:SetPoint("RIGHT", sysRow, "RIGHT", -12, 0)

    --------------------------------------------------
    -- Navigationsspalte mit echtem Zustand versehen
    --------------------------------------------------

    WeintCodex.Navigation.SetTabBadge("charakter", openIssues > 0, "red")
    WeintCodex.Navigation.SetTabBadge("materials", (not matLocked) and shortages > 0, "red")
    WeintCodex.Navigation.SetTabBadge("import",    queueCount > 0, "accent")
    if totalCount > 0 then
        WeintCodex.Navigation.SetTabCount("bossguides", totalCount)
    end

    homeFrame:Show()
end

function WeintCodex.ResetToHome()
    -- Seit 2.0.0.0 ist die Uebersicht ein eigener Navigationspunkt. Ohne das
    -- Zuruecksetzen bliebe der zuletzt besuchte Eintrag markiert, waehrend
    -- rechts die Startseite steht - und ein Klick auf "Uebersicht" wuerde
    -- nichts tun, weil activeTab noch auf dem alten Eintrag stuende.
    for _, b in ipairs(tabButtons) do SetTabActive(b, false) end
    local home = tabButtons["uebersicht"]
    if home then SetTabActive(home, true) end
    activeTab = "uebersicht"

    WeintCodex.ShowHome()
end
