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
-- Der Bot kennt den echten WoW-Namen einer Anmeldung nur, wenn der
-- Spieler die Companion verknüpft UND seine Twinkverwaltung gepflegt
-- hat - oder wenn die Raidleitung ihn von Hand zugeordnet hat
-- (/weintcharakter setzen, bzw. die Seite "Charakterzuordnung" der
-- Companion). Für alle anderen schickt er den Discord-Anzeigenamen
-- und sagt das im sechsten Feld der Anmeldezeile (siehe
-- ParseRaidImport in modules/sync.lua).
--
-- Bleibt genau EIN Weg, das im Spiel nachzutragen: die manuelle
-- Korrektur über das Stift-Symbol. Sie steht in
-- SavedData.rosterNameOverrides und überlebt jeden weiteren Sync.
--
-- Was hier bis 2.2.0.0 zusätzlich stand und seit 2.3.0.0 fehlt, ist
-- eine automatische Selbst-Erkennung: passte die Klasse des gerade
-- eingeloggten Charakters zu genau einer unaufgelösten Zeile, trug
-- das Addon dort ungefragt UnitName("player") ein - dauerhaft und
-- kontoweit. Das war eine Vermutung mit den Rechten einer Angabe,
-- und sie ging aus zwei Gründen regelmäßig daneben:
--
--   * Der eine Krieger, der sich noch nicht zugeordnet hat, ist
--     nicht deshalb man selbst, weil man gerade auf einem Krieger
--     spielt. Über mehrere Twinks hinweg sammelten sich so mehrere
--     eigene Charaktere im Roster - an den Plätzen echter Spieler.
--   * Der Eintrag galt danach als aufgelöst. Der Kalender-Einlauf
--     lud also den eigenen Twink ein und den echten Spieler nicht,
--     ohne dass irgendwo etwas fehlte.
--
-- Eine sichtbar offene Zuordnung ist besser als eine falsche, die
-- wie eine richtige aussieht - dieselbe Linie, an der auch
-- IsResolved(), die Kalender-Vorschau und der Einladungslauf
-- entlanglaufen. Geraten wird hier deshalb nicht mehr.
--------------------------------------------------

--------------------------------------------------
-- Manuelle Korrekturen: Ablage
--------------------------------------------------
-- Seit 2.3.0.0 ist ein Eintrag eine Tabelle ({ name = ..., at = ... })
-- statt einer blanken Zeichenkette. Der Unterschied ist nicht
-- kosmetisch: bis dahin schrieb die Selbst-Erkennung in denselben
-- Topf wie das Stift-Symbol, und hinterher war nicht mehr zu
-- erkennen, welcher Eintrag eine Angabe des Nutzers war und welcher
-- eine Vermutung des Addons. Genau deshalb sind die Alt-Einträge
-- nicht zu retten: MigrateOverrides() legt sie vollständig beiseite
-- (SavedData.rosterNameOverridesLegacy, nichts geht verloren) und
-- sagt es einmal im Chat. Wer eine davon wirklich gesetzt hat, trägt
-- sie in zehn Sekunden erneut ein; die falschen kämen sonst nie
-- wieder weg.
--------------------------------------------------

local function OverrideStore()
    WeintCodex.SavedData = WeintCodex.SavedData or {}
    WeintCodex.SavedData.rosterNameOverrides =
        WeintCodex.SavedData.rosterNameOverrides or {}
    return WeintCodex.SavedData.rosterNameOverrides
end

local function MigrateOverrides()
    local sd = WeintCodex.SavedData
    if not sd or sd.rosterOverridesMigrated then return end

    local store  = OverrideStore()
    local moved  = {}
    local count  = 0

    for key, value in pairs(store) do
        if type(value) ~= "table" then
            moved[key] = value
            count = count + 1
        end
    end

    if count > 0 then
        sd.rosterNameOverridesLegacy = moved
        for key in pairs(moved) do
            store[key] = nil
        end
        print(WeintCodex.ColorText("warning", "[WeintCodex]") .. " "
            .. count .. " gespeicherte Namenskorrektur(en) wurden "
            .. "zurückgesetzt. Bis 2.2.0.0 hat das Addon dort auch "
            .. "selbst geraten, welcher Anmeldung dein gerade "
            .. "eingeloggter Charakter gehört - und lag dabei oft "
            .. "daneben. Korrekturen bitte über das Stift-Symbol in "
            .. "der Anmeldeliste erneut setzen.")
    end

    sd.rosterOverridesMigrated = true
end

function WeintCodex.Raids.SetOverride(originalName, newName)
    if not originalName or originalName == "" then return end
    local store = OverrideStore()
    if not newName or newName == "" then
        store[originalName] = nil
    else
        store[originalName] = { name = newName, at = time() }
    end
end

function WeintCodex.Raids.GetOverride(originalName)
    if not originalName then return nil end
    local entry = OverrideStore()[originalName]
    if type(entry) == "table" then return entry.name end
    return nil
end

--------------------------------------------------
-- Steht in dieser Zeile ein echter Charaktername?
--
-- Der Bot sagt es im sechsten Feld der Anmeldezeile (siehe
-- ParseRaidImport in modules/sync.lua): "discord" heisst, dass er
-- keinen Charakter kennt und den Discord-Anzeigenamen geschickt hat.
-- Der existiert ingame nicht - eine Einladung dorthin geht ins Leere,
-- und genau das war bisher nicht erkennbar.
--
-- Zwei Faelle gelten trotzdem als aufgeloest:
--   * eine manuelle Korrektur ueber das Stift-Symbol (dann steht in
--     p.name der von Hand gesetzte Charaktername),
--   * eine fehlende Angabe (aelterer Bot). Sonst waere nach einem
--     Addon-Update ploetzlich das ganze Roster "unbekannt".
--------------------------------------------------

function WeintCodex.Raids.IsResolved(p)
    if not p then return true end
    if p.source ~= "discord" then return true end
    return p.originalName ~= nil and p.name ~= p.originalName
end

--------------------------------------------------
-- Wie alt ist dieser Stand?
--------------------------------------------------
-- Die Seite zeigte bis 2.2.0.0 nur das RAIDDATUM - also den Tag, an
-- dem der Raid stattfindet. Das beantwortet nicht die Frage, die man
-- vor einer Anmeldeliste hat: ob das noch die Anmeldungen von jetzt
-- sind. Ein zwei Wochen alter Stand fuer den kommenden Mittwoch sieht
-- ohne diese Angabe exakt aus wie ein frischer.
--
-- `importedAt` setzt ProcessImport in modules/sync.lua bei jedem
-- Einarbeiten. Fehlt es (Stand aus einer aelteren Version), wird das
-- gesagt und nicht geraten.
--------------------------------------------------

function WeintCodex.Raids.Freshness(data)
    local stamp = data and tonumber(data.importedAt)

    if not stamp or stamp <= 0 then
        return "Stand unbekannt", "textDim"
    end

    local age  = time() - stamp
    local when = date("%d.%m. %H:%M", stamp)
    local label

    if age < 3600 then
        label = "vor " .. math.max(1, math.floor(age / 60)) .. " Min."
    elseif age < 86400 then
        local h = math.floor(age / 3600)
        label = "vor " .. h .. (h == 1 and " Stunde" or " Stunden")
    else
        local d = math.floor(age / 86400)
        label = "vor " .. d .. (d == 1 and " Tag" or " Tagen")
    end

    local tone
    if age < 86400 then
        tone = "success"
    elseif age < 7 * 86400 then
        tone = "warning"
    else
        tone = "danger"
    end

    return "Zugestellt " .. when .. " \194\183 " .. label, tone
end

function WeintCodex.Raids.CountUnresolved(data)
    if not data or not data.players then return 0 end

    local count = 0

    for _, p in ipairs(data.players) do
        if not WeintCodex.Raids.IsResolved(p) then
            count = count + 1
        end
    end

    return count
end

function WeintCodex.Raids.ResolveNames(data)
    if not data or not data.players then return end

    MigrateOverrides()

    -- Original-Namen sichern (einmalig) + gespeicherte manuelle
    -- Korrekturen anwenden. Mehr passiert hier nicht: was der Bot
    -- nicht weiss und niemand von Hand nachgetragen hat, bleibt
    -- sichtbar offen.
    for _, p in ipairs(data.players) do
        p.originalName = p.originalName or p.name
        local override = WeintCodex.Raids.GetOverride(p.originalName)
        if override then
            p.name = override
        end
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
            local eb = self.EditBox or self.editBox  -- MoP Classic: "EditBox" (Großschreibung)
            if eb then
                eb:SetText(data.currentName or data.originalName)
                eb:HighlightText()
            end
        end
    end,
    OnAccept = function(self, data)
        local eb = self.EditBox or self.editBox
        local newName = eb and eb:GetText():match("^%s*(.-)%s*$") or ""
        if newName ~= "" and data and data.originalName then
            WeintCodex.Raids.SetOverride(data.originalName, newName)
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

-- Anmeldeliste bearbeiten (Namenskorrektur, Loeschen) ist Sache der
-- Raidleitung - siehe core/access.lua.
local function MayEdit()
    if not (WeintCodex.Access and WeintCodex.Access.Can) then return true end
    return WeintCodex.Access.Can("raids.edit")
end

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
    reloadLbl:SetFont(WeintCodex.Fonts.sans, 11, "")
    reloadLbl:SetJustifyH("CENTER")
    reloadLbl:SetText(WeintCodex.Icon("Interface\\Icons\\INV_Misc_PocketWatch_01", 14) .. "  Anmeldungen abrufen")
    reloadLbl:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
    reloadBtn:SetScript("OnEnter", function(self)
        self:SetSurface("surface3")
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Anmeldungen abrufen")
        GameTooltip:AddLine(
            "Macht ein /reload und arbeitet die zuletzt von der " ..
            "Companion zugestellten Anmeldungen ein. Die Companion " ..
            "muss dafür laufen und mit Discord verbunden sein.",
            1, 1, 1, true)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(
            "Bis 2.2.0.0 konnte das gar nicht funktionieren: WoW " ..
            "schreibt seine gespeicherten Variablen beim /reload " ..
            "zuerst zurück und liest sie erst danach - die Zustellung " ..
            "der Companion war damit schon gelöscht, bevor das Addon " ..
            "sie sehen konnte. Seit 2.3.0.0 liegt sie in einer Datei " ..
            "im Addon-Ordner, die WoW nur liest.",
            0.6, 0.6, 0.6, true)
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
    clearLbl:SetFont(WeintCodex.Fonts.sans, 11, "")
    clearLbl:SetJustifyH("CENTER")
    clearLbl:SetText("Löschen")
    clearLbl:SetTextColor(C.danger[1], C.danger[2], C.danger[3])
    clearBtn:SetScript("OnEnter", function(self) self:SetSurface("surface3") end)
    clearBtn:SetScript("OnLeave", function(self) self:SetSurface("surface2") end)
    clearBtn:SetScript("OnClick", function()
        if not WeintCodex.SavedData then return end
        WeintCodex.SavedData.raidWednesday = nil
        WeintCodex.SavedData.raidThursday  = nil

        -- Das Addon merkt sich, welchen Stand der Live-Bruecke es
        -- zuletzt eingearbeitet hat, und ueberspringt einen
        -- unveraenderten beim naechsten /reload. Nach einem Loeschen
        -- waere die zugestellte Anmeldeliste damit unerreichbar, bis
        -- die Companion von sich aus etwas Neues schickt.
        if WeintCodex.Companion and WeintCodex.Companion.ForgetLiveStamp then
            WeintCodex.Companion.ForgetLiveStamp()
        end

        print(WeintCodex.ColorText("textFaint", "[WeintCodex]")
            .. " Raiddaten gelöscht. Ein /reload holt die zuletzt "
            .. "zugestellten Anmeldungen wieder herein.")
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

    -- Kennzahlen rechts im Kopf: TANKS / HEILER / DPS / GESAMT, in Mono wie
    -- im Entwurf. Die hellen Tonvarianten, weil die Grundfarben als Flaechen
    -- gedacht sind und als Text auf Schwarz zu dunkel geraten.
    local head = WeintCodex.PageHead(summary, {
        eyebrow = "Raidanmeldungen",
        title = "", titleSize = 22,
        sub = "",
        x = ROW_PAD, y = 14, height = 56,
        stats = {
            { key = "tank",  label = "Tanks",  tone = "infoBright" },
            { key = "heal",  label = "Heiler", tone = "successBright" },
            { key = "dps",   label = "DPS",    tone = "dangerBright" },
            { key = "total", label = "Gesamt", tone = "textNormal" },
        },
    })
    f.Title    = head.Title
    f.DateStr  = head.Sub
    f.StatStrs = head.Stats

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
        l:SetFont(WeintCodex.Fonts.sans, 9, "")
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
    local open  = WeintCodex.Raids.CountUnresolved(raidData)

    local freshText, freshTone = "—", "textDim"

    if raidData then
        freshText, freshTone = WeintCodex.Raids.Freshness(raidData)
        -- Die Inspector-Zeile ist schmal; dort reicht der Abstand.
        freshText = freshText:match("\194\183%s*(.+)$") or freshText
    end
    WeintCodex.Navigation.SetInspector({
        { type = "header", text = "Gilden-Puls" },
        { type = "rows", rows = {
            { label = "Tag",          value = dayLabels[activeDay] or "—" },
            { label = "Raidtermin",   value = (raidData and raidData.date) or "—" },
            { label = "Zugestellt",   value = freshText, valueColor = freshTone },
            { label = "Anmeldungen",  value = total .. " / 25", valueColor = (total > 0) and "success" or "textDim" },
            { label = "Ohne Zuordnung", value = tostring(open),
              valueColor = (open > 0) and "warning" or "textDim" },
        }},
        { type = "divider" },
        { type = "header", text = "Namenskorrektur" },
        { type = "card", lines = MayEdit()
            and {
                "Zeilen mit Fragezeichen tragen den Discord-Namen -",
                "ingame gibt es den nicht, sie werden nicht eingeladen.",
                "",
                "Notiz-Symbol in der Zeile anklicken und korrigieren.",
                "Dauerhaft für alle: in Discord /weintcharakter setzen.",
                "",
                "Das Addon rät hier nichts mehr: bis 2.2.0.0 trug es",
                "beim Login ungefragt den gerade eingeloggten Charakter",
                "in eine passende offene Zeile ein - und damit eigene",
                "Twinks an die Plätze echter Spieler.",
            }
            or {
                WeintCodex.Access.Reason("raids.edit"),
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
        noData:SetFont(WeintCodex.Fonts.sans, 12, "")
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

    local freshness, tone = WeintCodex.Raids.Freshness(raidData)

    f.DateStr:SetText(
        WeintCodex.ColorText("textFaint", raidData.date or "")
        .. "   " .. WeintCodex.ColorText(tone, freshness))

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

        -- Abschnittskopf wie im Entwurf: Statuspunkt in der Rollenfarbe,
        -- daneben "Tanks · 4" in gesperrter Mono-Versalie.
        local sRow = CreateFrame("Frame", nil, sc)
        sRow:SetHeight(20)
        sRow:SetPoint("TOPLEFT",  sc, "TOPLEFT",  ROW_PAD, offsetY - 6)
        sRow:SetPoint("TOPRIGHT", sc, "TOPRIGHT", -ROW_PAD, offsetY - 6)

        local sDot = WeintCodex.StatusDot(sRow, colorName, 7)
        sDot:SetPoint("LEFT", sRow, "LEFT", 0, 0)

        local sHdr = WeintCodex.Eyebrow(sRow, sectionLabel .. " \194\183 " .. #players,
            { color = colorName .. "Bright", size = 10 })
        sHdr:SetPoint("LEFT", sDot, "RIGHT", 8, 0)

        table.insert(activePlayerRows, sRow)
        offsetY = offsetY - 26

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

            -- Zeilen, fuer die der Bot keinen Charakternamen kennt,
            -- tragen den Discord-Anzeigenamen. Der wird bewusst
            -- angezeigt (er ist der einzige Anhaltspunkt, wer gemeint
            -- ist), aber nicht in Klassenfarbe und mit Warnzeichen -
            -- sonst sieht ein Platzhalter aus wie ein Charakter, und
            -- der Kalender-Invite scheitert erst am leeren Kalender.
            local resolved = WeintCodex.Raids.IsResolved(p)

            local ccol = classColors[p.class] or "|cffdddddd"
            local nameLbl = row:CreateFontString(nil, "OVERLAY")
            nameLbl:SetFont(WeintCodex.Fonts.sans, 12, "")
            nameLbl:SetPoint("LEFT", row, "LEFT", COL_NAME_X, 0)
            nameLbl:SetWidth(COL_NAME_W)
            nameLbl:SetJustifyH("LEFT")

            if resolved then
                nameLbl:SetText(ccol .. (p.name or "?") .. "|r")
            else
                nameLbl:SetText(
                    WeintCodex.Icon("Interface\\Icons\\INV_Misc_QuestionMark", 12)
                    .. " " .. WeintCodex.ColorText("textDim", p.name or "?"))
            end

            local cIcon = WeintCodex.ClassIcon(p.class, 14)
            local classLbl = row:CreateFontString(nil, "OVERLAY")
            classLbl:SetFont(WeintCodex.Fonts.sans, 11, "")
            classLbl:SetPoint("LEFT", row, "LEFT", COL_CLASS_X, 0)
            classLbl:SetText(WeintCodex.ColorText("textFaint", cIcon .. " " .. (p.class or "")))
            classLbl:SetWidth(140)

            local roleLbl = row:CreateFontString(nil, "OVERLAY")
            roleLbl:SetFont(WeintCodex.Fonts.sans, 11, "")
            roleLbl:SetPoint("LEFT", row, "LEFT", COL_ROLE_X, 0)
            roleLbl:SetText(WeintCodex.ColorText(colorName, rc.label or p.role))
            roleLbl:SetWidth(110)

            local noteText = p.note

            if not resolved then
                noteText = "Discord-Name \194\183 kein Charakter"
            end

            if noteText and noteText ~= "" then
                local noteLbl = row:CreateFontString(nil, "OVERLAY")
                noteLbl:SetFont(WeintCodex.Fonts.sans, 11, "")
                noteLbl:SetPoint("LEFT", row, "LEFT", COL_NOTE_X, 0)
                noteLbl:SetPoint("RIGHT", row, "RIGHT", -30, 0)
                noteLbl:SetJustifyH("LEFT")
                noteLbl:SetText(WeintCodex.ColorText(
                    resolved and "textFaint" or "warning", noteText))
            end

            -- Namen manuell korrigieren (falls Bot/Auto-Erkennung den
            -- Discord-Namen nicht auflösen konnten). Nur mit der passenden
            -- Rolle - die Zuordnung ist Sache der Raidleitung.
            local editBtn = CreateFrame("Button", nil, row)
            editBtn:SetShown(MayEdit())
            editBtn:SetSize(20, 20)
            editBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)

            local editIcon = editBtn:CreateFontString(nil, "OVERLAY")
            editIcon:SetFont(WeintCodex.Fonts.sans, 12, "")
            editIcon:SetAllPoints(editBtn)
            editIcon:SetText(WeintCodex.Icon("Interface\\Icons\\INV_Misc_Note_01", 14))

            editBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_LEFT")
                GameTooltip:SetText("Charaktername korrigieren")
                if not resolved then
                    GameTooltip:AddLine(
                        "Der Bot kennt zu diesem Discord-Account keinen",
                        1, 1, 1)
                    GameTooltip:AddLine(
                        "Charakter. Trage ihn hier ein - oder dauerhaft",
                        1, 1, 1)
                    GameTooltip:AddLine(
                        "in Discord mit /weintcharakter setzen.", 1, 1, 1)
                end
                GameTooltip:Show()
            end)
            editBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

            editBtn:SetScript("OnClick", function()
                StaticPopup_Show("WEINTCODEX_EDIT_ROSTER_NAME", p.originalName, nil, {
                    originalName = p.originalName,
                    currentName  = p.name,
                    refresh = function()
                        -- Override auf p.name anwenden, bevor neu gerendert wird
                        WeintCodex.Raids.ResolveNames(raidData)
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
    clearBtn:SetShown(MayEdit())

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
