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
    TANK   = { r = C.blue[1],  g = C.blue[2],  b = C.blue[3],  label = WeintCodex.Icon("Interface\\Icons\\Ability_Warrior_DefensiveStance", 14) .. "  Tank"   },
    HEALER = { r = C.green[1], g = C.green[2], b = C.green[3], label = WeintCodex.Icon("Interface\\Icons\\Spell_Holy_Renew", 14) .. "  Heiler" },
    DPS    = { r = C.red[1],   g = C.red[2],   b = C.red[3],   label = WeintCodex.Icon("Interface\\Icons\\Ability_DualWield", 14) .. "  DPS"   },
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

local dayLabels = { wednesday = "Mittwoch", thursday = "Donnerstag" }

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
-- Spalten-Layout
--------------------------------------------------

local ROW_PAD = 20
local COL_NAME_X, COL_NAME_W = 20, 220
local COL_CLASS_X            = 250
local COL_ROLE_X             = 400
local COL_NOTE_X             = 520

--------------------------------------------------
-- Frame erstellen
--------------------------------------------------

local reloadBtn, clearBtn = nil, nil

local function CreateRaidFrame()
    if raidFrame then return raidFrame end

    local cp = WeintCodex.ContentPanel
    local f  = CreateFrame("Frame", nil, cp)
    f:SetAllPoints(cp)

    --------------------------------------------------
    -- Titelleisten-Aktionen (Singleton, ueberlebt Tages-Wechsel)
    --------------------------------------------------

    reloadBtn = WeintCodex.CreateCard(WeintCodex.TitleBarActions, { width = 190, height = 30, buttonStyle = true })
    reloadBtn:SetPoint("TOPRIGHT", WeintCodex.TitleBarActions, "TOPRIGHT", -110, -11)
    local reloadLbl = reloadBtn:CreateFontString(nil, "OVERLAY")
    reloadLbl:SetAllPoints(reloadBtn)
    reloadLbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    reloadLbl:SetJustifyH("CENTER")
    reloadLbl:SetText(WeintCodex.Icon("Interface\\Icons\\INV_Misc_PocketWatch_01", 14) .. "  Anmeldungen abrufen")
    reloadLbl:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
    reloadBtn:SetScript("OnEnter", function(self)
        self:SetSurface("surface3")
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(
            "Läd die von Companion zuletzt geschriebenen Daten neu " ..
            "(macht einen /reload). Companion muss zuvor gelaufen und " ..
            "mit Discord verbunden gewesen sein.",
            nil, nil, nil, nil, true
        )
        GameTooltip:Show()
    end)
    reloadBtn:SetScript("OnLeave", function(self)
        self:SetSurface("surface2")
        GameTooltip:Hide()
    end)
    reloadBtn:SetScript("OnClick", function() ReloadUI() end)

    clearBtn = WeintCodex.CreateCard(WeintCodex.TitleBarActions, { width = 96, height = 30, buttonStyle = true })
    clearBtn:SetPoint("TOPRIGHT", WeintCodex.TitleBarActions, "TOPRIGHT", 0, -11)
    local clearLbl = clearBtn:CreateFontString(nil, "OVERLAY")
    clearLbl:SetAllPoints(clearBtn)
    clearLbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    clearLbl:SetJustifyH("CENTER")
    clearLbl:SetText("Löschen")
    clearLbl:SetTextColor(C.danger[1], C.danger[2], C.danger[3])
    clearBtn:SetScript("OnEnter", function(self) self:SetSurface("surface3") end)
    clearBtn:SetScript("OnLeave", function(self) self:SetSurface("surface2") end)
    clearBtn:SetScript("OnClick", function()
        if not WeintCodex.SavedData then return end
        WeintCodex.SavedData.raidWednesday = nil
        WeintCodex.SavedData.raidThursday  = nil
        print(WeintCodex.ColorText("textFaint", "[WeintCodex]") .. " Raiddaten gelöscht.")
        if raidFrame and raidFrame:IsShown() then
            WeintCodex.Raids.Show()
        end
    end)

    --------------------------------------------------
    -- Summary-Leiste
    --------------------------------------------------

    local summary = CreateFrame("Frame", nil, f)
    summary:SetHeight(70)
    summary:SetPoint("TOPLEFT",  f, "TOPLEFT",  0, 0)
    summary:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)

    local summaryDiv = summary:CreateTexture(nil, "OVERLAY")
    summaryDiv:SetHeight(1)
    summaryDiv:SetPoint("BOTTOMLEFT",  summary, "BOTTOMLEFT",  0, 0)
    summaryDiv:SetPoint("BOTTOMRIGHT", summary, "BOTTOMRIGHT", 0, 0)
    summaryDiv:SetColorTexture(C.border[1], C.border[2], C.border[3], C.border[4])

    local eyebrow = summary:CreateFontString(nil, "OVERLAY")
    eyebrow:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    eyebrow:SetPoint("TOPLEFT", summary, "TOPLEFT", ROW_PAD, -14)
    eyebrow:SetText(WeintCodex.ColorText("textFaint", "RAIDANMELDUNGEN"))

    local titleStr = summary:CreateFontString(nil, "OVERLAY")
    titleStr:SetFont("Fonts\\MORPHEUS.TTF", 19, "")
    titleStr:SetPoint("TOPLEFT", eyebrow, "BOTTOMLEFT", 0, -6)
    titleStr:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
    f.Title = titleStr

    local dateStr = summary:CreateFontString(nil, "OVERLAY")
    dateStr:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    dateStr:SetPoint("TOPLEFT", titleStr, "BOTTOMLEFT", 2, -4)
    f.DateStr = dateStr

    -- Stat-Quartett rechts: TANKS / HEILER / DPS / GESAMT
    local statDefs = {
        { key = "tank",  label = "TANKS",  color = "blue" },
        { key = "heal",  label = "HEILER", color = "green" },
        { key = "dps",   label = "DPS",    color = "red" },
        { key = "total", label = "GESAMT", color = "textBright" },
    }
    local statStrs = {}
    local sx = -ROW_PAD
    for i = #statDefs, 1, -1 do
        local def = statDefs[i]
        local box = CreateFrame("Frame", nil, summary)
        box:SetSize(64, 40)
        box:SetPoint("TOPRIGHT", summary, "TOPRIGHT", sx, -14)

        local lbl = box:CreateFontString(nil, "OVERLAY")
        lbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        lbl:SetPoint("TOPRIGHT", box, "TOPRIGHT", 0, 0)
        lbl:SetJustifyH("RIGHT")
        lbl:SetText(WeintCodex.ColorText("textFaint", def.label))

        local val = box:CreateFontString(nil, "OVERLAY")
        val:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
        val:SetPoint("TOPRIGHT", lbl, "BOTTOMRIGHT", 0, -4)
        val:SetJustifyH("RIGHT")
        local col = C[def.color] or C.textBright
        val:SetTextColor(col[1], col[2], col[3])
        statStrs[def.key] = val

        sx = sx - 74
    end
    f.StatStrs = statStrs

    --------------------------------------------------
    -- Tabellenkopf
    --------------------------------------------------

    local colBar = CreateFrame("Frame", nil, f)
    colBar:SetHeight(26)
    colBar:SetPoint("TOPLEFT",  summary, "BOTTOMLEFT",  0, 0)
    colBar:SetPoint("TOPRIGHT", summary, "BOTTOMRIGHT", 0, 0)

    local colDiv = colBar:CreateTexture(nil, "OVERLAY")
    colDiv:SetHeight(1)
    colDiv:SetPoint("BOTTOMLEFT",  colBar, "BOTTOMLEFT",  0, 0)
    colDiv:SetPoint("BOTTOMRIGHT", colBar, "BOTTOMRIGHT", 0, 0)
    colDiv:SetColorTexture(C.border[1], C.border[2], C.border[3], C.border[4])

    local function ColLbl(text, x)
        local l = colBar:CreateFontString(nil, "OVERLAY")
        l:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        l:SetPoint("LEFT", colBar, "LEFT", x, 0)
        l:SetText(WeintCodex.ColorText("textFaint", text))
    end
    ColLbl("SPIELER", COL_NAME_X)
    ColLbl("KLASSE",  COL_CLASS_X)
    ColLbl("ROLLE",   COL_ROLE_X)
    ColLbl("NOTIZ",   COL_NOTE_X)

    --------------------------------------------------
    -- Scroll-Bereich
    --------------------------------------------------

    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     colBar, "BOTTOMLEFT",  0, 0)
    scroll:SetPoint("BOTTOMRIGHT", f,      "BOTTOMRIGHT", -26, 0)

    local scrollChild = CreateFrame("Frame", nil, scroll)
    scrollChild:SetWidth(760)
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

local function UpdateInspector(raidData)
    local total = raidData and raidData.players and #raidData.players or 0
    WeintCodex.Navigation.SetInspector({
        { type = "header", text = "Gilden-Puls" },
        { type = "rows", rows = {
            { label = "Tag",          value = dayLabels[activeDay] or "—" },
            { label = "Stand",        value = (raidData and raidData.date) or "—" },
            { label = "Anmeldungen",  value = total .. " / 25", valueColor = (total > 0) and "success" or "textDim" },
        }},
        { type = "divider" },
        { type = "header", text = "Namenskorrektur" },
        { type = "card", lines = {
            "Stimmt ein Charaktername nicht (Discord- statt WoW-Name)?",
            "Notiz-Symbol in der jeweiligen Zeile anklicken und korrigieren.",
        }},
        { type = "divider" },
        { type = "button", label = "Import-Format anzeigen", onClick = function()
            WeintCodex.ShowExportDialog(
                "Raid-Import-Format",
                "WCIMPORT:RAIDWED:DATUM:Name1|TANK|WARRIOR|,Name2|HEALER|PALADIN|,...\n" ..
                "WCIMPORT:RAIDTHU:DATUM:Name1|TANK|WARRIOR|,Name2|HEALER|PALADIN|,..."
            )
        end },
    })
end

local function RefreshRaidDisplay(raidData)
    local f  = CreateRaidFrame()
    local sc = f.ScrollChild

    for _, row in ipairs(activePlayerRows) do row:Hide() end
    wipe(activePlayerRows)

    f.Title:SetText(dayLabels[activeDay] or "Raidanmeldungen")
    WeintCodex.SetBreadcrumb("Raids", dayLabels[activeDay] or "—")
    UpdateInspector(raidData)

    if not raidData or not raidData.players or #raidData.players == 0 then
        local noData = sc:CreateFontString(nil, "OVERLAY")
        noData:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        noData:SetPoint("TOPLEFT", sc, "TOPLEFT", ROW_PAD, -20)
        noData:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
        noData:SetJustifyH("LEFT")
        noData:SetWidth(700)
        noData:SetText(WeintCodex.ColorText("textFaint",
            "Keine Raidanmeldungen vorhanden. Importiere Daten über den ") ..
            WeintCodex.ColorText("purple", "Import") ..
            WeintCodex.ColorText("textFaint", "-Tab."))
        noData:SetSpacing(3)
        sc:SetHeight(120)

        f.StatStrs.tank:SetText("—")
        f.StatStrs.heal:SetText("—")
        f.StatStrs.dps:SetText("—")
        f.StatStrs.total:SetText("—")
        f.DateStr:SetText("")
        table.insert(activePlayerRows, noData)
        return
    end

    f.DateStr:SetText(WeintCodex.ColorText("textFaint", raidData.date or ""))

    local tanks, healers, dps = {}, {}, {}
    for _, p in ipairs(raidData.players) do
        if     p.role == "TANK"   then tanks[#tanks+1]     = p
        elseif p.role == "HEALER" then healers[#healers+1] = p
        else                            dps[#dps+1]         = p end
    end

    local total = #raidData.players
    f.StatStrs.tank:SetText(tostring(#tanks))
    f.StatStrs.heal:SetText(tostring(#healers))
    f.StatStrs.dps:SetText(tostring(#dps))
    f.StatStrs.total:SetText(total .. "/25")

    local offsetY = -2

    local function DrawSection(players, sectionLabel, colorName)
        if #players == 0 then return end

        local sHdr = sc:CreateFontString(nil, "OVERLAY")
        sHdr:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        sHdr:SetPoint("TOPLEFT", sc, "TOPLEFT", ROW_PAD, offsetY - 6)
        sHdr:SetText(WeintCodex.ColorText(colorName, string.upper(sectionLabel) .. " · " .. #players))
        table.insert(activePlayerRows, sHdr)
        offsetY = offsetY - 22

        for _, p in ipairs(players) do
            local row = CreateFrame("Frame", nil, sc)
            row:SetHeight(28)
            row:SetPoint("TOPLEFT",  sc, "TOPLEFT",  0, offsetY)
            row:SetPoint("TOPRIGHT", sc, "TOPRIGHT", 0, offsetY)

            local rowDiv = row:CreateTexture(nil, "OVERLAY")
            rowDiv:SetHeight(1)
            rowDiv:SetPoint("BOTTOMLEFT",  row, "BOTTOMLEFT",  0, 0)
            rowDiv:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
            rowDiv:SetColorTexture(C.border[1], C.border[2], C.border[3], 0.60)

            local rc = roleColors[p.role] or roleColors.DPS
            local strip = row:CreateTexture(nil, "OVERLAY")
            strip:SetSize(2, 28)
            strip:SetPoint("LEFT", row, "LEFT", 0, 0)
            strip:SetColorTexture(rc.r, rc.g, rc.b, 0.80)

            local ccol = classColors[p.class] or "|cffdddddd"
            local nameLbl = row:CreateFontString(nil, "OVERLAY")
            nameLbl:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
            nameLbl:SetPoint("LEFT", row, "LEFT", COL_NAME_X, 0)
            nameLbl:SetWidth(COL_NAME_W)
            nameLbl:SetJustifyH("LEFT")
            nameLbl:SetText(ccol .. (p.name or "?") .. "|r")

            local cIcon = WeintCodex.ClassIcon(p.class, 14)
            local classLbl = row:CreateFontString(nil, "OVERLAY")
            classLbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
            classLbl:SetPoint("LEFT", row, "LEFT", COL_CLASS_X, 0)
            classLbl:SetText(WeintCodex.ColorText("textFaint", cIcon .. " " .. (p.class or "")))
            classLbl:SetWidth(140)

            local roleLbl = row:CreateFontString(nil, "OVERLAY")
            roleLbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
            roleLbl:SetPoint("LEFT", row, "LEFT", COL_ROLE_X, 0)
            roleLbl:SetText(WeintCodex.ColorText(colorName, rc.label or p.role))
            roleLbl:SetWidth(110)

            if p.note and p.note ~= "" then
                local noteLbl = row:CreateFontString(nil, "OVERLAY")
                noteLbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
                noteLbl:SetPoint("LEFT", row, "LEFT", COL_NOTE_X, 0)
                noteLbl:SetPoint("RIGHT", row, "RIGHT", -30, 0)
                noteLbl:SetJustifyH("LEFT")
                noteLbl:SetText(WeintCodex.ColorText("textFaint", p.note))
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
        offsetY = offsetY - 8
    end

    DrawSection(tanks,   "Tanks",  "blue")
    DrawSection(healers, "Heiler", "green")
    DrawSection(dps,     "DPS",    "red")

    sc:SetHeight(math.abs(offsetY) + 20)
end

--------------------------------------------------
-- Modul anzeigen
--------------------------------------------------

function WeintCodex.Raids.Show()
    local cp = WeintCodex.ContentPanel
    for _, child in pairs({cp:GetChildren()}) do child:Hide() end

    local f = CreateRaidFrame()
    f:Show()
    reloadBtn:Show()
    clearBtn:Show()

    local sidebarItems = {
        {
            label = "Mittwoch",
            onClick = function()
                activeDay = "wednesday"
                RefreshRaidDisplay(WeintCodex.SavedData and WeintCodex.SavedData.raidWednesday)
            end,
        },
        {
            label = "Donnerstag",
            onClick = function()
                activeDay = "thursday"
                RefreshRaidDisplay(WeintCodex.SavedData and WeintCodex.SavedData.raidThursday)
            end,
        },
    }

    WeintCodex.Navigation.BuildSidebar("Raids", sidebarItems)

    activeDay = "wednesday"
    RefreshRaidDisplay(WeintCodex.SavedData and WeintCodex.SavedData.raidWednesday)
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
