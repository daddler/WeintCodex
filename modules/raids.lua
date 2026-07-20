--------------------------------------------------
-- WeintCodex :: Raids Module
-- Mittwoch & Donnerstag mit Discord-Bot-Anmeldungen
--------------------------------------------------

WeintCodex.Raids = {}

local C         = WeintCodex.Colors
local raidFrame = nil
local activeDay = "wednesday"

--------------------------------------------------
-- Rollenfarben / Klassen
--------------------------------------------------

local roleColors = {
    TANK   = { r = 0.40, g = 0.80, b = 1.00, label = WeintCodex.Icon("Interface\\Icons\\Ability_Warrior_DefensiveStance", 14) .. "  Tank"   },
    HEALER = { r = 0.13, g = 0.77, b = 0.37, label = WeintCodex.Icon("Interface\\Icons\\Spell_Holy_Renew", 14) .. "  Heiler" },
    DPS    = { r = 1.00, g = 0.49, b = 0.27, label = WeintCodex.Icon("Interface\\Icons\\Ability_DualWield", 14) .. "  DPS"   },
}

local classColors = {
    WARRIOR    = "|cffc79c6e",
    PALADIN    = "|cfff58cba",
    HUNTER     = "|cffabd473",
    ROGUE      = "|cfffff569",
    PRIEST     = "|cffffffff",
    DEATHKNIGHT= "|cffc41f3b",
    SHAMAN     = "|cff0070de",
    MAGE       = "|cff69ccf0",
    WARLOCK    = "|cff9482c9",
    MONK       = "|cff00ff96",
    DRUID      = "|cffff7d0a",
}

--------------------------------------------------
-- Namensauflösung (Discord-Name -> WoW-Charaktername)
--------------------------------------------------
-- Der Bot versucht bereits serverseitig (companion_characters), den
-- Discord-Anzeigenamen einer Anmeldung durch den passenden Charakter
-- zu ersetzen. Das klappt nur, wenn der Spieler Discord verknüpft UND
-- gemeldet hat. Als Ergänzung dazu:
--   1. Manuelle Korrektur (Stift-Symbol je Zeile) - überschreibt jeden
--      Eintrag dauerhaft, überlebt auch erneute Syncs.
--   2. Automatische Selbst-Erkennung beim Login: passt die Klasse des
--      eingeloggten Charakters zu GENAU EINEM noch unaufgelösten
--      Eintrag im Roster, wird automatisch der eigene Name eingesetzt.
--      Bei mehreren möglichen Kandidaten (z. B. zwei Krieger angemeldet)
--      bleibt der Eintrag unangetastet - dann hilft nur die manuelle
--      Korrektur.
--------------------------------------------------

local function IsKnownOtherCharacter(name, myName)
    if not IsInGuild() then return false end

    local num = GetNumGuildMembers() or 0

    for i = 1, num do
        local gname = GetGuildRosterInfo(i)
        if gname then
            local shortName = gname:match("([^%-]+)") or gname
            if shortName:lower() == name:lower()
               and shortName:lower() ~= (myName or ""):lower()
            then
                return true
            end
        end
    end

    return false
end

function WeintCodex.Raids.ResolveNames(data)
    if not data or not data.players then return end

    WeintCodex.SavedData = WeintCodex.SavedData or {}
    WeintCodex.SavedData.rosterNameOverrides =
        WeintCodex.SavedData.rosterNameOverrides or {}

    local overrides = WeintCodex.SavedData.rosterNameOverrides

    -- Original-Namen sichern (einmalig) + gespeicherte manuelle
    -- Korrekturen anwenden
    for _, p in ipairs(data.players) do
        p.originalName = p.originalName or p.name
        if overrides[p.originalName] then
            p.name = overrides[p.originalName]
        end
    end

    -- Automatische Selbst-Erkennung
    local myName = UnitName("player")
    local _, myClass = UnitClass("player")

    if not myName or not myClass then return end

    local candidates = {}

    for _, p in ipairs(data.players) do
        if p.class == myClass
           and p.name == p.originalName
           and p.name ~= myName
           and not IsKnownOtherCharacter(p.name, myName)
        then
            table.insert(candidates, p)
        end
    end

    if #candidates == 1 then
        local p = candidates[1]
        overrides[p.originalName] = myName
        p.name = myName
    end
end

--------------------------------------------------
-- Manuelle Namenskorrektur (Stift-Symbol je Zeile)
--------------------------------------------------

StaticPopupDialogs["WEINTCODEX_EDIT_ROSTER_NAME"] = {
    text = "Charaktername für '%s' eingeben:\n|cff888888(Crossrealm: Name-Realm, z. B. Njiah-OokOok)|r",
    button1 = "Speichern",
    button2 = "Abbrechen",
    hasEditBox = true,
    maxLetters = 48,
    OnShow = function(self, data)
        if data and data.originalName then
            self.editBox:SetText(data.currentName or data.originalName)
            self.editBox:HighlightText()
        end
    end,
    OnAccept = function(self, data)
        local newName = self.editBox:GetText():match("^%s*(.-)%s*$")
        if newName ~= "" and data and data.originalName then
            WeintCodex.SavedData = WeintCodex.SavedData or {}
            WeintCodex.SavedData.rosterNameOverrides =
                WeintCodex.SavedData.rosterNameOverrides or {}
            WeintCodex.SavedData.rosterNameOverrides[data.originalName] = newName
            if data.refresh then data.refresh() end
        end
    end,
    EditBoxOnEnterPressed = function(self)
        self:GetParent().button1:Click()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

--------------------------------------------------
-- Helpers
--------------------------------------------------

local function SetSolidBg(f, r, g, b, a)
    local t = f:CreateTexture(nil, "BACKGROUND")
    t:SetAllPoints(f)
    t:SetColorTexture(r, g, b, a or 1)
    return t
end

local function DrawBorder(f, r, g, b, a, thick)
    thick = thick or 1
    local W, H = f:GetWidth(), f:GetHeight()
    local function T(pt, rpt, w, h)
        local t = f:CreateTexture(nil, "OVERLAY")
        t:SetColorTexture(r, g, b, a)
        t:SetPoint(pt, f, rpt, 0, 0)
        t:SetSize(w, h)
    end
    T("TOPLEFT",    "TOPLEFT",    W,     thick)
    T("BOTTOMLEFT", "BOTTOMLEFT", W,     thick)
    T("TOPLEFT",    "TOPLEFT",    thick, H)
    T("TOPRIGHT",   "TOPRIGHT",   thick, H)
end

--------------------------------------------------
-- Frame erstellen
--------------------------------------------------

local function CreateRaidFrame()
    if raidFrame then return raidFrame end

    local cp = WeintCodex.ContentPanel
    local f  = CreateFrame("Frame", nil, cp)
    f:SetAllPoints(cp)

    -- Header area (fixed)
    local header = CreateFrame("Frame", nil, f)
    header:SetHeight(90)
    header:SetPoint("TOPLEFT",  f, "TOPLEFT",  0, 0)
    header:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    SetSolidBg(header, C.bgMid[1], C.bgMid[2], C.bgMid[3], 0.55)

    -- Titel
    local titleStr = header:CreateFontString(nil, "OVERLAY")
    titleStr:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
    titleStr:SetPoint("TOPLEFT", header, "TOPLEFT", 20, -14)
    titleStr:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    titleStr:SetText("Raidanmeldungen")
    f.Title = titleStr

    -- Datum + Status
    local dateStr = header:CreateFontString(nil, "OVERLAY")
    dateStr:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    dateStr:SetPoint("BOTTOMLEFT", titleStr, "BOTTOMRIGHT", 10, 2)
    dateStr:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
    dateStr:SetText("")
    f.DateStr = dateStr

    -- Zusammenfassung (Tank/Heiler/DPS/Gesamt)
    local summaryFrame = CreateFrame("Frame", nil, header)
    summaryFrame:SetHeight(34)
    summaryFrame:SetPoint("BOTTOMLEFT",  header, "BOTTOMLEFT",  16,  8)
    summaryFrame:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -16, 8)

    -- 4 stat cards
    local statDefs = {
        { key = "tank",  label = WeintCodex.Icon("Interface\\Icons\\Ability_Warrior_DefensiveStance", 14) .. "  Tanks",  col = {0.40, 0.80, 1.00} },
        { key = "heal",  label = WeintCodex.Icon("Interface\\Icons\\Spell_Holy_Renew", 14) .. "  Heiler", col = {0.13, 0.77, 0.37} },
        { key = "dps",   label = WeintCodex.Icon("Interface\\Icons\\Ability_DualWield", 14) .. "  DPS",   col = {1.00, 0.49, 0.27} },
        { key = "total", label = "Gesamt",     col = {0.65, 0.60, 0.80} },
    }

    local statLabels = {}
    for i, sd in ipairs(statDefs) do
        local card = CreateFrame("Frame", nil, summaryFrame)
        card:SetSize(118, 30)
        card:SetPoint("LEFT", summaryFrame, "LEFT", (i - 1) * 130, 0)
        SetSolidBg(card, C.bgCard[1], C.bgCard[2], C.bgCard[3], 0.80)
        DrawBorder(card, sd.col[1], sd.col[2], sd.col[3], 0.40, 1)

        local lbl = card:CreateFontString(nil, "OVERLAY")
        lbl:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        lbl:SetAllPoints(card)
        lbl:SetJustifyH("CENTER")
        lbl:SetTextColor(sd.col[1] * 0.85, sd.col[2] * 0.85, sd.col[3] * 0.85)
        lbl:SetText(sd.label .. ": —")
        statLabels[sd.key] = lbl
    end
    f.StatLabels = statLabels

    -- Neue Discord-Anmeldungen mid-Session abholen: SavedVariables
    -- werden vom Client nur bei Login/Reload von der Festplatte
    -- gelesen - schreibt Companion waehrend der laufenden Session neue
    -- Daten in die Datei, sieht das laufende Spiel das erst nach einem
    -- /reload. Ein direktes "Abrufen" ohne Reload ist daher technisch
    -- nicht moeglich.
    local reloadButton = CreateFrame("Button", nil, header)
    reloadButton:SetSize(230, 26)
    reloadButton:SetPoint(
        "TOPRIGHT",
        header,
        "TOPRIGHT",
        -170,
        -14
    )

    SetSolidBg(
        reloadButton,
        C.purpleDim[1],
        C.purpleDim[2],
        C.purpleDim[3],
        0.80
    )

    DrawBorder(
        reloadButton,
        C.purple[1],
        C.purple[2],
        C.purple[3],
        1.0,
        1
    )

    local reloadLabel = reloadButton:CreateFontString(nil, "OVERLAY")
    reloadLabel:SetAllPoints(reloadButton)
    reloadLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    reloadLabel:SetText(WeintCodex.Icon("Interface\\Icons\\INV_Misc_PocketWatch_01", 14) .. "  Discord-Anmeldungen abrufen")
    reloadLabel:SetTextColor(1, 1, 1)

    reloadButton:SetScript("OnEnter", function(self)
        SetSolidBg(self, C.purple[1] * 0.90, C.purple[2] * 0.90, C.purple[3] * 0.90, 0.90)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(
            "Läd die von Companion zuletzt geschriebenen Daten neu " ..
            "(macht einen /reload). Companion muss zuvor gelaufen und " ..
            "mit Discord verbunden gewesen sein.",
            nil, nil, nil, nil, true
        )
        GameTooltip:Show()
    end)
    reloadButton:SetScript("OnLeave", function(self)
        SetSolidBg(self, C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.80)
        GameTooltip:Hide()
    end)
    reloadButton:SetScript("OnClick", function()
        ReloadUI()
    end)

    local clearButton = CreateFrame("Button", nil, header)
    clearButton:SetSize(140, 26)
    clearButton:SetPoint(
        "TOPRIGHT",
        header,
        "TOPRIGHT",
        -20,
        -14
    )

    SetSolidBg(
        clearButton,
        C.purpleDim[1],
        C.purpleDim[2],
        C.purpleDim[3],
        0.80
    )

    DrawBorder(
        clearButton,
        C.purple[1],
        C.purple[2],
        C.purple[3],
        1.0,
        1
    )

    local clearLabel = clearButton:CreateFontString(
        nil,
        "OVERLAY"
    )

    clearLabel:SetAllPoints(clearButton)
    clearLabel:SetFont(
        "Fonts\\FRIZQT__.TTF",
        11,
        "OUTLINE"
    )

    clearLabel:SetText("Raiddaten löschen")
    clearLabel:SetTextColor(1, 1, 1)

    clearButton:SetScript("OnEnter", function(self)

    SetSolidBg(
        self,
        C.purple[1] * 0.90,
        C.purple[2] * 0.90,
        C.purple[3] * 0.90,
        0.90
    )

    end)

    clearButton:SetScript("OnLeave", function(self)

    SetSolidBg(
        self,
        C.purpleDim[1],
        C.purpleDim[2],
        C.purpleDim[3],
        0.80
    )

    end)

    clearButton:SetScript("OnClick", function()

    if not WeintCodex.SavedData then
        return
        end

        WeintCodex.SavedData.raidWednesday = nil
        WeintCodex.SavedData.raidThursday = nil

        print(
            "|cff6B6259[WeintCodex]|r Raiddaten gelöscht."
        )

        end)

    local headerDiv = header:CreateTexture(nil, "OVERLAY")
    headerDiv:SetHeight(1)
    headerDiv:SetPoint("BOTTOMLEFT",  header, "BOTTOMLEFT",  0, 0)
    headerDiv:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)
    headerDiv:SetColorTexture(C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.50)

    -- Column headers
    local colBar = CreateFrame("Frame", nil, f)
    colBar:SetHeight(24)
    colBar:SetPoint("TOPLEFT",  header, "BOTTOMLEFT",  0, 0)
    colBar:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, 0)
    SetSolidBg(colBar, C.bgMid[1], C.bgMid[2], C.bgMid[3], 0.40)

    local function ColHeader(text, x)
        local lbl = colBar:CreateFontString(nil, "OVERLAY")
        lbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        lbl:SetPoint("LEFT", colBar, "LEFT", x, 0)
        lbl:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
        lbl:SetText(text)
    end
    ColHeader("Spieler",   12)
    ColHeader("Klasse",   220)
    ColHeader("Rolle",    380)
    ColHeader("Notiz",    500)

    local colDiv = colBar:CreateTexture(nil, "OVERLAY")
    colDiv:SetHeight(1)
    colDiv:SetPoint("BOTTOMLEFT",  colBar, "BOTTOMLEFT",  0, 0)
    colDiv:SetPoint("BOTTOMRIGHT", colBar, "BOTTOMRIGHT", 0, 0)
    colDiv:SetColorTexture(C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.30)

    -- Scroll frame (player list)
    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     colBar, "BOTTOMLEFT",  0,   0)
    scroll:SetPoint("BOTTOMRIGHT", f,      "BOTTOMRIGHT", -4,  4)

    local scrollChild = CreateFrame("Frame", nil, scroll)
    scrollChild:SetWidth(860)
    scrollChild:SetHeight(1)
    scroll:SetScrollChild(scrollChild)
    f.ScrollChild = scrollChild

    raidFrame = f
    return f
end

--------------------------------------------------
-- Daten anzeigen
--------------------------------------------------

local activePlayerRows = {}

local function RefreshRaidDisplay(raidData)
    local f  = CreateRaidFrame()
    local sc = f.ScrollChild

    for _, row in ipairs(activePlayerRows) do row:Hide() end
    for _, child in pairs({sc:GetChildren()}) do child:Hide() end
    for _, child in pairs({sc:GetRegions()}) do child:Hide() end
    wipe(activePlayerRows)

    if not raidData or not raidData.players or #raidData.players == 0 then
        local noData = sc:CreateFontString(nil, "OVERLAY")
        noData:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
        noData:SetPoint("TOPLEFT", sc, "TOPLEFT", 16, -20)
        noData:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
        noData:SetText(
            "Keine Raidanmeldungen vorhanden.\n\n" ..
            "Importiere Daten über den |cffC8763AImport|r-Tab:\n\n" ..
            "|cff6B6259WCIMPORT:RAIDWED:DATUM:Name1|TANK|WARRIOR|,Name2|HEALER|PALADIN|,...|r\n" ..
            "|cff6B6259WCIMPORT:RAIDTHU:DATUM:Name1|TANK|WARRIOR|,Name2|HEALER|PALADIN|,...|r"
        )
        noData:SetSpacing(3)
        sc:SetHeight(120)

        -- Reset stat cards
        local sl = f.StatLabels
        sl.tank:SetText(WeintCodex.Icon("Interface\\Icons\\Ability_Warrior_DefensiveStance", 14) .. "  Tanks: —")
        sl.heal:SetText(WeintCodex.Icon("Interface\\Icons\\Spell_Holy_Renew", 14) .. "  Heiler: —")
        sl.dps:SetText(WeintCodex.Icon("Interface\\Icons\\Ability_DualWield", 14) .. "  DPS: —")
        sl.total:SetText("Gesamt: —")
        f.DateStr:SetText("")
        table.insert(activePlayerRows, noData)
        return
    end

    f.DateStr:SetText("|cff6B6259" .. (raidData.date or "") .. "|r")

    local tanks, healers, dps = {}, {}, {}
    for _, p in ipairs(raidData.players) do
        if     p.role == "TANK"   then tanks[#tanks+1]   = p
        elseif p.role == "HEALER" then healers[#healers+1] = p
        else                           dps[#dps+1]       = p end
    end

    local total = #raidData.players
    local sl    = f.StatLabels
    sl.tank:SetText(WeintCodex.Icon("Interface\\Icons\\Ability_Warrior_DefensiveStance", 14) .. "  Tanks: "  .. #tanks)
    sl.heal:SetText(WeintCodex.Icon("Interface\\Icons\\Spell_Holy_Renew", 14) .. "  Heiler: " .. #healers)
    sl.dps:SetText(WeintCodex.Icon("Interface\\Icons\\Ability_DualWield", 14) .. "  DPS: "    .. #dps)
    sl.total:SetText("Gesamt: " .. total .. "/25")

    local offsetY = -4
    local altRow  = false

    local function DrawSection(players, sectionLabel, sectionColor)
        if #players == 0 then return end

        -- Section label
        local sHdr = sc:CreateFontString(nil, "OVERLAY")
        sHdr:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        sHdr:SetPoint("TOPLEFT", sc, "TOPLEFT", 8, offsetY)
        sHdr:SetText(sectionColor .. "— " .. sectionLabel .. " (" .. #players .. ") —|r")
        table.insert(activePlayerRows, sHdr)
        offsetY = offsetY - 20

        for _, p in ipairs(players) do
            local row = CreateFrame("Frame", nil, sc)
            row:SetHeight(28)
            row:SetPoint("TOPLEFT",  sc, "TOPLEFT",  0, offsetY)
            row:SetPoint("TOPRIGHT", sc, "TOPRIGHT", -6, offsetY)

            local rowBg = row:CreateTexture(nil, "BACKGROUND")
            rowBg:SetAllPoints(row)
            if altRow then
                rowBg:SetColorTexture(C.bgCard[1], C.bgCard[2], C.bgCard[3], 0.50)
            else
                rowBg:SetColorTexture(0, 0, 0, 0)
            end
            altRow = not altRow

            -- Role color strip
            local rc = roleColors[p.role] or roleColors.DPS
            local strip = row:CreateTexture(nil, "OVERLAY")
            strip:SetSize(2, 28)
            strip:SetPoint("LEFT", row, "LEFT", 0, 0)
            strip:SetColorTexture(rc.r, rc.g, rc.b, 0.80)

            -- Player name
            local ccol   = classColors[p.class] or "|cffdddddd"
            local nameLbl = row:CreateFontString(nil, "OVERLAY")
            nameLbl:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
            nameLbl:SetPoint("LEFT", row, "LEFT", 10, 0)
            nameLbl:SetText(ccol .. (p.name or "?") .. "|r")
            nameLbl:SetWidth(200)

            -- Class
            local cIcon = WeintCodex.ClassIcon(p.class, 14)
            local classLbl = row:CreateFontString(nil, "OVERLAY")
            classLbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
            classLbl:SetPoint("LEFT", row, "LEFT", 220, 0)
            classLbl:SetText("|cff6B6259" .. cIcon .. " " .. (p.class or "") .. "|r")
            classLbl:SetWidth(140)

            -- Role
            local roleLbl = row:CreateFontString(nil, "OVERLAY")
            roleLbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
            roleLbl:SetPoint("LEFT", row, "LEFT", 380, 0)
            roleLbl:SetText(sectionColor .. (rc.label or p.role) .. "|r")
            roleLbl:SetWidth(110)

            -- Note
            if p.note and p.note ~= "" then
                local noteLbl = row:CreateFontString(nil, "OVERLAY")
                noteLbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
                noteLbl:SetPoint("LEFT", row, "LEFT", 500, 0)
                noteLbl:SetText("|cff6B6259" .. p.note .. "|r")
                noteLbl:SetWidth(320)
            end

            -- Namen manuell korrigieren (falls Bot/Auto-Erkennung den
            -- Discord-Namen nicht auflösen konnten)
            local editBtn = CreateFrame("Button", nil, row)
            editBtn:SetSize(20, 20)
            editBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)

            local editIcon = editBtn:CreateFontString(nil, "OVERLAY")
            editIcon:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
            editIcon:SetAllPoints(editBtn)
            editIcon:SetText(WeintCodex.Icon("Interface\\Icons\\INV_Misc_Note_01", 14))

            editBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_LEFT")
                GameTooltip:SetText("Charaktername korrigieren")
                GameTooltip:Show()
            end)
            editBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

            editBtn:SetScript("OnClick", function()
                StaticPopup_Show("WEINTCODEX_EDIT_ROSTER_NAME", p.originalName, nil, {
                    originalName = p.originalName,
                    currentName  = p.name,
                    refresh = function()
                        RefreshRaidDisplay(raidData)
                    end,
                })
            end)

            table.insert(activePlayerRows, row)
            offsetY = offsetY - 28
        end
        offsetY = offsetY - 6
    end

    DrawSection(tanks,   "Tanks",  "|cff66ccff")
    DrawSection(healers, "Heiler", "|cff66ff88")
    DrawSection(dps,     "DPS",    "|cffff8855")

    sc:SetHeight(math.abs(offsetY) + 24)
end

--------------------------------------------------
-- Modul anzeigen
--------------------------------------------------

function WeintCodex.Raids.Show()
    local cp = WeintCodex.ContentPanel
    for _, child in pairs({cp:GetChildren()}) do child:Hide() end

    local f = CreateRaidFrame()
    f:Show()

    local sidebarItems = {
        {
            label = "Mittwoch",
            onClick = function()
                activeDay = "wednesday"
                local data = WeintCodex.SavedData and WeintCodex.SavedData.raidWednesday
                f.Title:SetText("|cff" .. "D4A850Raidanmeldungen|r  |cff6B6259Mittwoch|r")
                RefreshRaidDisplay(data)
            end,
        },
        {
            label = "Donnerstag",
            onClick = function()
                activeDay = "thursday"
                local data = WeintCodex.SavedData and WeintCodex.SavedData.raidThursday
                f.Title:SetText("|cffD4A850Raidanmeldungen|r  |cff6B6259Donnerstag|r")
                RefreshRaidDisplay(data)
            end,
        },
    }

    WeintCodex.Navigation.BuildSidebar("Raids", sidebarItems)

    -- Default: Mittwoch
    local initData = WeintCodex.SavedData and WeintCodex.SavedData.raidWednesday
    f.Title:SetText("|cffD4A850Raidanmeldungen|r  |cff6B6259Mittwoch|r")
    RefreshRaidDisplay(initData)
end

-- Called by sync.lua after import
function WeintCodex.Raids.RefreshDay(day, data)
    if raidFrame and raidFrame:IsShown() and activeDay == day then
        RefreshRaidDisplay(data)
    end
end

-- Legacy compatibility
function WeintCodex.Raids.Refresh(data)
    WeintCodex.Raids.RefreshDay("wednesday", data)
end
