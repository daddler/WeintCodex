--------------------------------------------------
-- WeintCodex :: WeintTV (Tiefenanalyse)
--
-- Zeigt die zuletzt von WeintCompanion gelieferte Auswertung eines
-- Pulls. BEWUSST KEIN Live-Dashboard: WoW liest SavedVariables nur
-- beim Login/Reload ein (siehe ProcessInbox in modules/companion.lua),
-- eine laufende Auswertung kann das Addon also gar nicht sehen. Was
-- hier steht, ist immer der Stand der letzten Lieferung — deshalb
-- nennt die Kopfzeile den Zeitpunkt und weist auf /reload hin.
--
-- Das Modul rechnet NICHTS. Alle Bewertungen (vermeidbar/unvermeidbar,
-- Laufwege in Metern, Cooldown-Effizienz) entstehen in der Companion;
-- hier werden nur Zeilen gezeichnet. Damit koennen Desktop und Addon
-- nicht auseinanderlaufen.
--
-- Datenschema: siehe Kopfkommentar von modules/companion.lua
-- (Nachrichtentyp "weinttv_report").
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.WeintTV = {}

local C          = WeintCodex.Colors
local SetSolidBg = WeintCodex.SetSolidBg
local DrawBorder = WeintCodex.DrawBorder

local Amount  = WeintCodex.FormatAmount
local Clock   = WeintCodex.FormatClock
local Percent = WeintCodex.FormatPercent

local tvFrame     = nil
local activeView  = nil
local onlyMine    = true
local filterBtn, filterLbl = nil, nil

--------------------------------------------------
-- Datenzugriff
--------------------------------------------------

local function Report()
    return WeintCodex.SavedData and WeintCodex.SavedData.weinttv or nil
end

local function Rows(list)
    return type(list) == "table" and list or {}
end

--------------------------------------------------
-- Wer ist "ich"?
--------------------------------------------------
-- Bis 1.3.2.3 galt schlicht report.me — der Charakter, den jemand in
-- der Companion ausgewaehlt hat. Das war falsch herum: der Bericht
-- ist RAIDWEIT, alle Zeilen aller Raider stehen drin, und der
-- einzige Wert daran, der ueberhaupt spielerbezogen ist, ist dieses
-- eine Feld. Wer auf einem Twink einloggte oder wessen Auswahl auf
-- dem Desktop verrutscht war, bekam damit einen fremden Charakter als
-- "Mein Charakter" praesentiert.
--
-- Jetzt gewinnt der EINGELOGGTE Charakter, sofern er ueberhaupt im
-- Bericht vorkommt — die Frage laesst sich hier vollstaendig
-- beantworten, ohne die Companion zu fragen. Nur wenn er nicht
-- vorkommt (anderer Raid, anderer Charakter), bleibt report.me, und
-- dann sagt IdentityNotice das auch.
--------------------------------------------------

-- Reihenfolge ist egal, aber die Liste muss vollstaendig sein: fehlt
-- ein Abschnitt, wird ein Spieler, der nur dort auftaucht, nicht
-- gefunden.
local ROW_LISTS = {
    { "damageTaken", "actor" },
    { "uptimes",     "actor" },
    { "activity",    "actor" },
    { "movement",    "actor" },
    { "cooldowns",   "actor" },
    { "support",     "actor" },
    { "mechanics",   "actor" },
    { "consumables", "actor" },
}

-- Ergebnis je Berichtstabelle merken. Der Durchlauf ist billig, aber
-- er liefe sonst bei jedem Seitenaufbau und jedem Umschalten erneut.
--
-- Der Startwert ist ABSICHTLICH kein nil: ohne Bericht waere sonst
-- schon der allererste Aufruf ein vermeintlicher Treffer (nil == nil)
-- und lieferte eine nie berechnete Antwort zurueck.
local NO_REPORT = {}
local resolvedFor, resolvedName, resolvedSource = NO_REPORT, nil, nil

-- -> name, source ("player" | "payload" | "none")
local function ResolveMe(report)

    if resolvedFor == report then
        return resolvedName, resolvedSource
    end

    local me = WeintCodex.Names.Me()
    local name, source = nil, "none"

    if report and me ~= "" then

        for _, spec in ipairs(ROW_LISTS) do

            for _, row in ipairs(Rows(report[spec[1]])) do

                if WeintCodex.Names.Equal(row[spec[2]], me) then
                    -- Die Schreibweise des Berichts behalten, nicht
                    -- die des Clients: alle weiteren Vergleiche
                    -- laufen gegen dieselben Zeilen.
                    name, source = row[spec[2]], "player"
                    break
                end

            end

            if name then break end

        end

    end

    if not name and report and report.me and report.me ~= "" then
        name, source = report.me, "payload"
    end

    if not name and me ~= "" then
        name, source = me, "none"
    end

    resolvedFor, resolvedName, resolvedSource = report, name, source
    return name, source

end

local function MyName(report)
    local name = ResolveMe(report)
    return name
end

-- Wenn der Bericht fuer jemand anderen ausgewertet wurde, muss das
-- dastehen. Es stillschweigend hinzunehmen war der eigentliche
-- Fehler: die Seite behauptete "Mein Charakter" ueber fremde Zahlen.
local function IdentityNotice(report)

    local name, source = ResolveMe(report)

    if source ~= "payload" then return nil end

    local me = WeintCodex.Names.Me()
    if me == "" or WeintCodex.Names.Equal(name, me) then return nil end

    return "Dieser Bericht wurde fuer " .. tostring(name)
        .. " ausgewertet — angemeldet bist du als " .. me
        .. ". \"Nur ich\" zeigt deshalb " .. tostring(name)
        .. ". Waehle in WeintCompanion deinen Charakter aus; die neue "
        .. "Auswertung erscheint nach /reload."

end

-- Darf dieser Client Zeilen des ganzen Raids sehen? Ohne geladenes
-- Access-Modul (oder ohne Zugriffsprofil) ja, wie bisher.
local function RaidAllowed()
    if not (WeintCodex.Access and WeintCodex.Access.Can) then return true end
    return WeintCodex.Access.Can("weinttv.raid")
end

-- Zeilen auf den eigenen Charakter eindampfen. Der Filter greift normalerweise
-- nur, wenn dabei ueberhaupt etwas uebrig bleibt — sonst saehe der Nutzer eine
-- leere Tabelle und wuesste nicht, ob Daten fehlen oder der Filter zu scharf
-- ist.
--
-- ACHTUNG: Bei erzwungenem Filter (fehlende Freigabe fuer den ganzen Raid)
-- darf dieser Rueckfall NICHT greifen. Er wuerde sonst genau dann alle
-- Raidzeilen ausliefern, wenn der eigene Name in einem Abschnitt nicht
-- vorkommt — z. B. bei Mechanikfehlern, die man selbst nicht gemacht hat.
--
-- Rueckgabe: rows, filtered, fellBack
--
-- fellBack sagt, dass der Rueckfall oben gegriffen hat. Ohne diesen
-- dritten Wert war er unsichtbar — die Tabelle zeigte den ganzen
-- Raid, waehrend der Umschalter "Nur ich" anzeigte, und niemand
-- konnte unterscheiden, ob es keine eigenen Zeilen gibt oder ob der
-- Name nicht passte. Genau daran ist die falsche Identitaet bisher
-- nicht aufgefallen.
--
local function ApplyFilter(rows, report, nameField)
    local forced = not RaidAllowed()

    if not onlyMine and not forced then return rows, false, false end

    local me = MyName(report)
    if not me then
        if forced then return {}, true, false end
        return rows, false, true
    end

    local kept = {}
    for _, row in ipairs(rows) do
        if WeintCodex.Names.Equal(row[nameField or "actor"], me) then
            kept[#kept + 1] = row
        end
    end

    if #kept == 0 then
        if forced then return {}, true, false end
        return rows, false, true
    end

    return kept, true, false
end

--------------------------------------------------
-- Erklaertexte fuer fehlende Tiefenanalyse
-- Spiegelt analysis_gap() der Companion; die Ursache wird dort
-- berechnet und im Feld "gap" mitgeliefert.
--------------------------------------------------

local GAP_TEXT = {
    no_raid   = "Es lag kein Raid vor, als die Companion zuletzt ausgewertet hat.",
    no_pull   = "Es wurde noch kein Pull ausgewertet — der Kampf hat nicht begonnen.",
    sums_only = "Die Datenquelle liefert nur Summen. Fuer die Tiefenanalyse fehlen "
             .. "die Einzelereignisse (Treffer, Wirkungsdauern, Einsatzzeitpunkte).",
}

local function GapText(report)
    if not report then
        return "Noch keine Auswertung vorhanden. WeintCompanion muss laufen und "
            .. "einen Raid ausgewertet haben; danach erscheinen die Daten hier "
            .. "beim naechsten Login oder nach /reload."
    end
    if report.hasAnalysis and (report.gap or "") == "" then return nil end
    return GAP_TEXT[report.gap or ""]
        or "Fuer diesen Pull liegt keine Tiefenanalyse vor."
end

--------------------------------------------------
-- Bausteine
--------------------------------------------------

local function ClearContent()
    local cp = WeintCodex.ContentPanel
    if not cp then return end
    for _, child in pairs({ cp:GetChildren() }) do child:Hide() end
end

local function Text(parent, size, x, y, width, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    -- Groesse kommt vom Aufrufer; ab 14 die halbfette Schnitt-Variante,
    -- wie im Entwurf (Kartentitel halbfett, Fliesstext normal).
    fs:SetFont(size >= 14 and WeintCodex.Fonts.sansSemi or WeintCodex.Fonts.sans, size, "")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    if width then fs:SetWidth(width) end
    fs:SetJustifyH(justify or "LEFT")
    return fs
end

-- Kopfzeile: welcher Pull, welche Quelle, wie alt. Gibt die verbrauchte
-- Hoehe zurueck (negativ), damit die Tabelle darunter andocken kann.
local function DrawHeader(frame, titleText, report)
    WeintCodex.SetBreadcrumb("WeintTV", titleText)

    local head = WeintCodex.PageHead(frame, {
        eyebrow = "WeintTV",
        title = titleText, titleSize = 20,
        sub = "", subSize = 10,
        x = 16, y = 14, height = 78,
    })

    local sub = head.Sub
    if report then
        local enc   = report.encounter or {}
        local parts = {}
        if enc.name       then parts[#parts + 1] = enc.name end
        if enc.difficulty then parts[#parts + 1] = enc.difficulty end
        if report.pull    then parts[#parts + 1] = "Pull " .. tostring(report.pull) end
        if report.duration then parts[#parts + 1] = Clock(report.duration) end
        if report.bossHealth then
            parts[#parts + 1] = report.kill and "Kill"
                or ("Boss bei " .. Percent(report.bossHealth, 1))
        end
        sub:SetText(WeintCodex.ColorText("textMuted", table.concat(parts, "  ·  ")))
    else
        sub:SetText(WeintCodex.ColorText("textDim", "Keine Auswertung geladen"))
    end

    local meta = head:CreateFontString(nil, "OVERLAY")
    meta:SetFont(WeintCodex.Fonts.sans, 9, "")
    meta:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -4)
    meta:SetJustifyH("LEFT")
    if report then
        local stamp = report.capturedAt
            and date("%d.%m.%Y %H:%M", report.capturedAt) or "unbekannt"
        meta:SetText(WeintCodex.ColorText("textFaint",
            "Quelle: " .. tostring(report.source or "—")
            .. "   ·   Stand: " .. stamp
            .. "   ·   Neue Auswertungen erscheinen nach /reload"))
    else
        meta:SetText("")
    end

    return -(14 + head.Height)
end

-- Hinweiskarte statt leerer Tabelle.
local function DrawNotice(frame, y, message)
    local card = WeintCodex.CreateCard(frame, {
        width = frame:GetWidth() - 32, height = 74, surface = "surface1",
        style = "border", borderColor = "hairline",
    })
    card:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, y)

    local fs = card:CreateFontString(nil, "OVERLAY")
    fs:SetFont(WeintCodex.Fonts.sans, 11, "")
    fs:SetPoint("TOPLEFT", card, "TOPLEFT", 14, -14)
    fs:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -14, 12)
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("TOP")
    fs:SetText(WeintCodex.ColorText("textMuted", message))

    return y - 86
end

--------------------------------------------------
-- Tabelle
-- columns: { { title, width, align = "LEFT"|"RIGHT" }, ... }
-- rows:    { { cells = { { text, color }, ... }, level }, ... }
--------------------------------------------------

local ROW_H = 34

local function DrawTable(frame, y, columns, rows, emptyText)
    local headerY = y - 6

    local x = 24
    for _, col in ipairs(columns) do
        local h = WeintCodex.Eyebrow(frame, col.title, { size = 10, justify = col.align })
        h:SetPoint("TOPLEFT", frame, "TOPLEFT", x, headerY)
        if col.width then h:SetWidth(col.width) end
        x = x + col.width + 10
    end

    local divider = frame:CreateTexture(nil, "OVERLAY")
    divider:SetPoint("TOPLEFT",  frame, "TOPLEFT",  16, headerY - 14)
    divider:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, headerY - 14)
    divider:SetHeight(1)
    divider:SetColorTexture(C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1.0)

    if #rows == 0 then
        local fs = Text(frame, 11, 24, headerY - 34, frame:GetWidth() - 48)
        fs:SetText(WeintCodex.ColorText("textDim", emptyText or "Keine Eintraege."))
        return
    end

    local sf, inner = WeintCodex.CreateScrollArea(frame, 14, headerY - 18, 20, 400)
    sf:ClearAllPoints()
    sf:SetPoint("TOPLEFT",     frame, "TOPLEFT",     14, headerY - 18)
    sf:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -26, 24)
    inner:SetWidth(sf:GetWidth() - 22)

    local yOff = 0
    for _, row in ipairs(rows) do
        local rf = CreateFrame("Frame", nil, inner)
        rf:SetSize(inner:GetWidth() - 4, ROW_H)
        rf:SetPoint("TOPLEFT", inner, "TOPLEFT", 2, yOff)
        -- Der Entwurf setzt Tabellenzeilen ohne Flaeche und ohne Rahmen:
        -- nur eine Haarlinie darunter. Der frueher links angesetzte
        -- Farbstreifen wird zum Statuspunkt - dieselbe Form wie ueberall
        -- sonst, wo ein Zustand an einer Zeile haengt.
        WeintCodex.RowLine(rf, -(ROW_H - 1))

        local cx = 10
        if row.level then
            local dot = WeintCodex.StatusDot(rf, row.level, 7)
            dot:SetPoint("LEFT", rf, "LEFT", 6, 0)
            cx = 22
        end
        for i, col in ipairs(columns) do
            local cell = row.cells[i]
            local fs = rf:CreateFontString(nil, "OVERLAY")
            fs:SetFont(WeintCodex.Fonts.sans, 13, "")
            fs:SetPoint("LEFT", rf, "LEFT", cx, 0)
            fs:SetWidth(col.width)
            fs:SetJustifyH(col.align or "LEFT")
            fs:SetWordWrap(false)
            fs:SetText(cell and cell[1] or "")
            local tint = C[(cell and cell[2]) or "textNormal"] or C.textNormal
            fs:SetTextColor(tint[1], tint[2], tint[3])
            cx = cx + col.width + 10
        end

        yOff = yOff - ROW_H
    end

    inner:SetHeight(math.abs(yOff) + 10)
end

--------------------------------------------------
-- Inspector: eigene Kennzahlen + Erklaertext
--------------------------------------------------

local function BuildInspector(report, extraRows)
    local blocks = {}

    blocks[#blocks + 1] = { type = "header", text = "Mein Charakter" }

    local me, source = ResolveMe(report)
    local rows = { { label = "Charakter", value = me or "—" } }

    -- Woher der Name stammt, gehoert dazu: "Mein Charakter" ueber
    -- einer fremden Auswertung war genau die stille Luege, die diese
    -- Ueberarbeitung beseitigt.
    if source == "payload" then
        rows[#rows + 1] = { label = "Quelle", value = "Auswahl in der Companion",
            valueColor = "warning" }
    elseif source == "player" then
        rows[#rows + 1] = { label = "Quelle", value = "angemeldeter Charakter" }
    end

    for _, row in ipairs(extraRows or {}) do rows[#rows + 1] = row end
    blocks[#blocks + 1] = { type = "rows", rows = rows }

    local gap = GapText(report)
    if gap then
        blocks[#blocks + 1] = { type = "divider" }
        blocks[#blocks + 1] = { type = "header", text = "Warum fehlt hier etwas?" }
        blocks[#blocks + 1] = { type = "card", lines = { gap } }
    end

    WeintCodex.Navigation.SetInspector(blocks)
end

-- Kennzahlen des eigenen Charakters fuer den Inspector zusammensuchen.
local function MyMetrics(report)
    if not report then return {} end

    local me   = MyName(report)
    local rows = {}

    for _, entry in ipairs(Rows(report.damageTaken)) do
        if WeintCodex.Names.Equal(entry.actor, me) then
            rows[#rows + 1] = { label = "Schaden erhalten", value = Amount(entry.total) }
            local share = (entry.total or 0) > 0
                and ((entry.avoidable or 0) / entry.total * 100) or 0
            rows[#rows + 1] = { label = "davon vermeidbar",
                value = Percent(share),
                valueColor = share >= 10 and "danger" or "textNormal" }
        end
    end

    for _, entry in ipairs(Rows(report.activity)) do
        if WeintCodex.Names.Equal(entry.actor, me) then
            rows[#rows + 1] = { label = "Aktivzeit", value = Percent(entry.activePercent) }
            rows[#rows + 1] = { label = "Aktionen/min",
                value = (string.format("%.1f", entry.apm or 0):gsub("%.", ",")) }
        end
    end

    for _, entry in ipairs(Rows(report.movement)) do
        if WeintCodex.Names.Equal(entry.actor, me) then
            rows[#rows + 1] = { label = "Laufweg",
                value = Amount(entry.meters) .. " m"
                    .. (entry.estimated and " (geschaetzt)" or "") }
        end
    end

    return rows
end

--------------------------------------------------
-- Seiten
--------------------------------------------------

local function Page(titleText, viewId, build)
    activeView = viewId

    ClearContent()
    if tvFrame then tvFrame:Hide() end

    local cp = WeintCodex.ContentPanel
    if not cp then return end

    tvFrame = CreateFrame("Frame", nil, cp)
    tvFrame:SetAllPoints(cp)
    tvFrame:Show()

    local report = Report()
    local y = DrawHeader(tvFrame, titleText, report)

    -- Vor allem anderen: gehoert dieser Bericht ueberhaupt zu mir?
    -- Steht das nicht ganz oben, liest es niemand — und die Seite
    -- behauptet weiter "Mein Charakter" ueber fremde Zahlen.
    local identity = IdentityNotice(report)
    if identity then
        y = DrawNotice(tvFrame, y, identity)
    end

    local gap = GapText(report)
    if gap and not (report and report.hasAnalysis) then
        DrawNotice(tvFrame, y, gap)
        BuildInspector(report, MyMetrics(report))
        return
    end

    build(tvFrame, y, report)
    BuildInspector(report, MyMetrics(report))
end

-- Zeigt an, ob der Filter tatsaechlich gegriffen hat — und wenn
-- nicht, warum trotzdem der ganze Raid dasteht.
local function FilterNote(filtered, fellBack, report)
    if fellBack then
        local me = MyName(report) or "dich"
        return "Fuer " .. tostring(me) .. " gibt es in diesem Abschnitt "
            .. "keine Zeilen — gezeigt wird der ganze Raid."
    end

    if not filtered then return nil end

    if not RaidAllowed() then
        return "Auswertungen des ganzen Raids sind fuer deinen Rang nicht "
            .. "freigegeben — angezeigt werden nur deine eigenen Zeilen."
    end

    return "Gefiltert auf den eingeloggten Charakter — Umschalter oben rechts."
end

local ShowDamageTaken, ShowAvoidable, ShowUptimes,
      ShowActivity, ShowCooldowns, ShowSupport

function ShowDamageTaken()
    Page("Erhaltener Schaden", "damage", function(frame, y, report)
        local rows, filtered, fellBack = ApplyFilter(Rows(report and report.damageTaken), report)

        local table_ = {}
        for _, e in ipairs(rows) do
            local share = (e.total or 0) > 0 and ((e.avoidable or 0) / e.total * 100) or 0
            table_[#table_ + 1] = {
                -- Nach dem Zahlenwert sortieren, nicht nach dem formatierten
                -- Text — "950" waere sonst groesser als "12,3k".
                sortKey = e.total or 0,
                level = share >= 10 and "danger" or (share > 0 and "gold" or "green"),
                cells = {
                    { e.actor or "—" },
                    { Amount(e.total) },
                    { Amount(e.avoidable), share >= 10 and "danger" or "textNormal" },
                    { Percent(share) },
                    { tostring(e.hits or 0) },
                },
            }
        end
        table.sort(table_, function(a, b) return a.sortKey > b.sortKey end)

        local note = FilterNote(filtered, fellBack, report)
        if note then y = DrawNotice(frame, y, note) end

        DrawTable(frame, y, {
            { title = "Spieler",    width = 150 },
            { title = "Gesamt",     width = 100, align = "RIGHT" },
            { title = "Vermeidbar", width = 100, align = "RIGHT" },
            { title = "Anteil",     width = 80,  align = "RIGHT" },
            { title = "Treffer",    width = 70,  align = "RIGHT" },
        }, table_, "Keine Schadensdaten in dieser Auswertung.")
    end)
end

function ShowAvoidable()
    Page("Vermeidbarer Schaden", "avoidable", function(frame, y, report)
        local entries, filtered, fellBack = ApplyFilter(Rows(report and report.damageTaken), report)

        -- Faehigkeiten aus allen Spielerzeilen flach ziehen und nur die
        -- behalten, die die Companion als vermeidbar eingestuft hat.
        -- "unknown" bleibt bewusst draussen: eine nicht klassifizierte
        -- Faehigkeit als Fehler zu zeigen waere geraten, nicht gemessen.
        local flat = {}
        for _, entry in ipairs(entries) do
            for _, ab in ipairs(Rows(entry.abilities)) do
                if ab.verdict == "avoidable" then
                    flat[#flat + 1] = {
                        actor  = entry.actor,
                        ability = ab.ability,
                        amount = ab.amount or 0,
                        hits   = ab.hits or 0,
                        note   = ab.note,
                    }
                end
            end
        end
        table.sort(flat, function(a, b) return a.amount > b.amount end)

        local table_ = {}
        for _, e in ipairs(flat) do
            table_[#table_ + 1] = {
                level = "danger",
                cells = {
                    { e.ability or "—" },
                    { e.actor or "—" },
                    { Amount(e.amount), "danger" },
                    { tostring(e.hits) },
                    { e.note or "—", "textMuted" },
                },
            }
        end

        local note = FilterNote(filtered, fellBack, report)
        if note then y = DrawNotice(frame, y, note) end

        DrawTable(frame, y, {
            { title = "Faehigkeit", width = 170 },
            { title = "Spieler",    width = 120 },
            { title = "Schaden",    width = 90, align = "RIGHT" },
            { title = "Treffer",    width = 60, align = "RIGHT" },
            { title = "Was tun",    width = 260 },
        }, table_, "Kein vermeidbarer Schaden — sauber gespielt.")
    end)
end

function ShowUptimes()
    Page("Wirkungsdauern", "uptimes", function(frame, y, report)
        local rows, filtered, fellBack = ApplyFilter(Rows(report and report.uptimes), report)

        local table_ = {}
        for _, e in ipairs(rows) do
            local up   = e.uptime or 0
            local goal = e.expected or 0
            local ok   = goal <= 0 or up >= goal
            table_[#table_ + 1] = {
                level = goal <= 0 and "textDim" or (ok and "green" or "gold"),
                cells = {
                    { e.ability or "—" },
                    { e.actor or "—" },
                    { (e.kind == "hot") and "HoT" or "DoT", "textMuted" },
                    { Percent(up), ok and "textNormal" or "warning" },
                    { goal > 0 and Percent(goal) or "—", "textDim" },
                    { tostring(e.applications or 0), "textMuted" },
                },
            }
        end

        local note = FilterNote(filtered, fellBack, report)
        if note then y = DrawNotice(frame, y, note) end

        DrawTable(frame, y, {
            { title = "Faehigkeit",  width = 190 },
            { title = "Spieler",     width = 130 },
            { title = "Art",         width = 50 },
            { title = "Uptime",      width = 80, align = "RIGHT" },
            { title = "Ziel",        width = 70, align = "RIGHT" },
            { title = "Aufgelegt",   width = 80, align = "RIGHT" },
        }, table_, "Keine Wirkungsdauern in dieser Auswertung.")
    end)
end

function ShowActivity()
    Page("Aktivzeit & Laufwege", "activity", function(frame, y, report)
        local acts, filtered, fellBack = ApplyFilter(Rows(report and report.activity), report)

        -- Laufwege nach Spieler nachschlagen; beide Bloecke koennen
        -- unabhaengig voneinander fehlen.
        local moveBy = {}
        for _, m in ipairs(Rows(report and report.movement)) do
            if m.actor then moveBy[m.actor] = m end
        end

        local table_ = {}
        for _, e in ipairs(acts) do
            local m   = moveBy[e.actor]
            local gap = e.longestGap or 0
            table_[#table_ + 1] = {
                level = (e.activePercent or 0) >= 95 and "green" or "gold",
                cells = {
                    { e.actor or "—" },
                    { Percent(e.activePercent) },
                    { (string.format("%.1f", e.apm or 0):gsub("%.", ",")) },
                    -- Erst ab 3 s ist eine Pause aussagekraeftig (dieselbe
                    -- Schwelle wie in der Companion).
                    { gap >= 3 and string.format("%d s", gap + 0.5) or "—",
                      gap >= 3 and "warning" or "textDim" },
                    { m and (Amount(m.meters) .. " m") or "—",
                      m and "textNormal" or "textDim" },
                },
            }
        end

        local note = FilterNote(filtered, fellBack, report)
        if note then y = DrawNotice(frame, y, note) end

        DrawTable(frame, y, {
            { title = "Spieler",        width = 150 },
            { title = "Aktivzeit",      width = 90,  align = "RIGHT" },
            { title = "Aktionen/min",   width = 100, align = "RIGHT" },
            { title = "Laengste Pause", width = 110, align = "RIGHT" },
            { title = "Laufweg",        width = 110, align = "RIGHT" },
        }, table_, "Keine Aktivzeitdaten in dieser Auswertung.")
    end)
end

function ShowCooldowns()
    Page("Cooldown-Nutzung", "cooldowns", function(frame, y, report)
        local rows, filtered, fellBack = ApplyFilter(Rows(report and report.cooldowns), report)

        local table_ = {}
        for _, e in ipairs(rows) do
            local uses     = e.uses or 0
            local possible = e.possible or 0
            local eff      = e.efficiency or (possible > 0 and uses / possible or 0)

            local times = {}
            for _, t in ipairs(Rows(e.castTimes)) do times[#times + 1] = Clock(t) end

            table_[#table_ + 1] = {
                sortKey = eff,
                level   = uses == 0 and "danger" or (eff >= 0.85 and "green" or "gold"),
                cells   = {
                    { e.ability or "—" },
                    { e.actor or "—" },
                    { uses .. " / " .. possible, uses == 0 and "danger" or "textNormal" },
                    { tostring(e.inBurst or 0), "textMuted" },
                    { #times > 0 and table.concat(times, ", ") or "nicht genutzt",
                      #times > 0 and "textMuted" or "danger" },
                },
            }
        end
        -- Schlechteste Ausnutzung zuerst: danach wird gesucht.
        table.sort(table_, function(a, b) return a.sortKey < b.sortKey end)

        local note = FilterNote(filtered, fellBack, report)
        if note then y = DrawNotice(frame, y, note) end

        DrawTable(frame, y, {
            { title = "Faehigkeit",   width = 170 },
            { title = "Spieler",      width = 120 },
            { title = "Einsaetze",    width = 90,  align = "RIGHT" },
            { title = "Im Heldentum", width = 100, align = "RIGHT" },
            { title = "Zeitpunkte",   width = 220 },
        }, table_, "Keine Cooldown-Daten in dieser Auswertung.")
    end)
end

function ShowSupport()
    Page("Unterbrechungen & Mechaniken", "support", function(frame, y, report)
        local supports = ApplyFilter(Rows(report and report.support), report)
        local mechs, filtered, fellBack = ApplyFilter(Rows(report and report.mechanics), report)

        local table_ = {}

        for _, e in ipairs(supports) do
            table_[#table_ + 1] = {
                sortKey = e.at or 0,
                level   = "green",
                cells   = {
                    { (e.kind == "dispel") and "Dispel" or "Unterbrechung", "success" },
                    { e.actor or "—" },
                    { e.ability or "—", "textMuted" },
                    { e.target or "—", "textMuted" },
                    { (e.at or -1) >= 0 and Clock(e.at) or "—", "textDim" },
                },
            }
        end

        for _, e in ipairs(mechs) do
            local level = e.severity == "error" and "danger"
                or (e.severity == "info" and "blue" or "gold")
            table_[#table_ + 1] = {
                sortKey = (e.at or -1) >= 0 and e.at or 0,
                level   = level,
                cells   = {
                    { "Mechanik", level },
                    { e.actor or "—" },
                    { e.mechanic or "—", "textMuted" },
                    { (e.count or 1) > 1 and ((e.count) .. "×") or "—", "textMuted" },
                    -- at == -1 heisst "kein Zeitpunkt bekannt" (Companion-
                    -- Konvention), nicht "Sekunde 0".
                    { (e.at or -1) >= 0 and Clock(e.at) or "—", "textDim" },
                },
            }
        end

        table.sort(table_, function(a, b) return a.sortKey < b.sortKey end)

        local note = FilterNote(filtered, fellBack, report)
        if note then y = DrawNotice(frame, y, note) end

        DrawTable(frame, y, {
            { title = "Art",        width = 130 },
            { title = "Spieler",    width = 130 },
            { title = "Faehigkeit", width = 220 },
            { title = "Ziel/Anzahl", width = 130 },
            { title = "Zeitpunkt",  width = 90, align = "RIGHT" },
        }, table_, "Keine Unterbrechungen oder Mechanikfehler erfasst.")
    end)
end

-- Direkteinstieg von aussen (globale Suche, Deep-Links, Tests) - dasselbe
-- Muster wie WeintCodex.Charakter.ShowEnchants.
WeintCodex.WeintTV.ShowDamageTaken = ShowDamageTaken
WeintCodex.WeintTV.ShowAvoidable   = ShowAvoidable
WeintCodex.WeintTV.ShowUptimes     = ShowUptimes
WeintCodex.WeintTV.ShowActivity    = ShowActivity
WeintCodex.WeintTV.ShowCooldowns   = ShowCooldowns
WeintCodex.WeintTV.ShowSupport     = ShowSupport

--------------------------------------------------
-- Filter-Umschalter in der Titelleiste
-- Singleton wie der Aktualisieren-Button in modules/charakter.lua;
-- ClearTitleActions blendet ihn beim Tabwechsel aus.
--------------------------------------------------

local VIEWS = {
    damage    = function() ShowDamageTaken() end,
    avoidable = function() ShowAvoidable()   end,
    uptimes   = function() ShowUptimes()     end,
    activity  = function() ShowActivity()    end,
    cooldowns = function() ShowCooldowns()   end,
    support   = function() ShowSupport()     end,
}

local function UpdateFilterLabel()
    if not filterLbl then return end

    filterLbl:SetText(onlyMine and "Nur ich" or "Ganzer Raid")

    -- Ohne Freigabe ist der Umschalter zwar da, aber sichtbar wirkungslos:
    -- so ist erkennbar, dass es die Ansicht gibt, und der Tooltip erklaert,
    -- warum sie fehlt.
    local col = RaidAllowed() and C.textNormal or C.textFaint
    filterLbl:SetTextColor(col[1], col[2], col[3])
end

local function MakeFilterButton()
    if not filterBtn then
        filterBtn = WeintCodex.CreateCard(WeintCodex.TitleBarActions,
            { width = 106, height = 30, buttonStyle = true })
        filterBtn:SetPoint("TOPRIGHT", WeintCodex.TitleBarActions, "TOPRIGHT", 0, -11)

        filterLbl = filterBtn:CreateFontString(nil, "OVERLAY")
        filterLbl:SetAllPoints(filterBtn)
        filterLbl:SetFont(WeintCodex.Fonts.sans, 11, "")
        filterLbl:SetJustifyH("CENTER")
        filterLbl:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])

        filterBtn:SetScript("OnEnter", function(self)
            if RaidAllowed() then self:SetSurface("surface3") end
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
            GameTooltip:SetText(onlyMine and "Nur ich" or "Ganzer Raid")
            if not RaidAllowed() then
                GameTooltip:AddLine(WeintCodex.Access.Reason("weinttv.raid"),
                    C.textFaint[1], C.textFaint[2], C.textFaint[3], true)
            end
            GameTooltip:Show()
        end)
        filterBtn:SetScript("OnLeave", function(self)
            self:SetSurface("surface2")
            GameTooltip:Hide()
        end)
        filterBtn:SetScript("OnClick", function()
            if not RaidAllowed() then return end
            onlyMine = not onlyMine
            UpdateFilterLabel()
            local rebuild = activeView and VIEWS[activeView]
            if rebuild then rebuild() end
        end)
    end

    -- Fehlt die Freigabe, bleibt die Ansicht bei den eigenen Zeilen - auch
    -- wenn vorher in derselben Sitzung umgeschaltet wurde.
    if not RaidAllowed() then onlyMine = true end

    UpdateFilterLabel()
    filterBtn:Show()
    return filterBtn
end

--------------------------------------------------
-- Einstieg (core/navigation.lua ruft Show auf)
--------------------------------------------------

function WeintCodex.WeintTV.Show()
    MakeFilterButton()

    -- Flach und ohne Gruppen: der Entwurf zeigt die sechs Seiten als
    -- Reiterleiste unter dem Titel. Die frueheren Zwischenueberschriften
    -- (— SCHADEN — / — SPIELWEISE — / — RAID —) waren Gliederung fuer eine
    -- hohe, schmale Spalte; in einer Leiste haben sie keine Entsprechung und
    -- wuerden sie ausserdem in die Listendarstellung zwingen.
    WeintCodex.Navigation.BuildSidebar("WeintTV", {
        { label = "Erhaltener Schaden",    onClick = ShowDamageTaken },
        { label = "Vermeidbarer Schaden",  onClick = ShowAvoidable   },
        { label = "Wirkungsdauern",        onClick = ShowUptimes     },
        { label = "Aktivzeit",             onClick = ShowActivity    },
        { label = "Cooldowns",             onClick = ShowCooldowns   },
        { label = "Unterbrechungen",       onClick = ShowSupport     },
    })

    WeintCodex.Navigation.ActivateFirst()
end
