--------------------------------------------------
-- WeintCodex :: Ausrüstungs-Alarm
--
-- Grosse Einblendung in Bildschirmmitte, wenn ein frisch angelegtes
-- Teil weder verzaubert noch versockelt ist - und dieselbe Meldung als
-- Erinnerung, sobald man einen Ruhebereich betritt. Der Ruhebereich ist
-- dabei kein beliebiger Auslöser: dort steht der Verzauberer, dort ist
-- die Bank, dort kann man das auch tatsächlich erledigen. Im Raid davor
-- zu stehen bringt niemandem etwas.
--
-- ZWEI DINGE, DIE DIESE DATEI BEWUSST NICHT TUT
--
-- 1. Sie bewertet nicht. Gemeldet wird ausschliesslich "Verzauberung
--    fehlt" und "Sockel leer" - dieselbe Zurückhaltung wie im
--    Gruppencheck (modules/groupcheck.lua) und aus demselben Grund:
--    beides ist unstrittig, "nicht ideal" wäre eine Meinung. Eine
--    bildschirmfüllende Meldung über eine Meinung schaltet man nach
--    dem dritten Mal ab, und danach sieht man auch die echten
--    Mängel nicht mehr. Ob eine Verzauberung zur Spec passt, sagt
--    weiterhin nur die Charakterseite, wo man sie in Ruhe liest.
--
-- 2. Sie führt keine eigene Prüfung. Was offen ist, beantwortet
--    WeintCodex.Charakter.Scan() - dieselbe Liste der Slots, dieselbe
--    Auflösung des Verzauberungs-Topfes (inklusive "Ringe nur mit
--    Verzauberkunst") und dieselbe Sockelerkennung wie die
--    Charakterseite. Gelesen wird daraus aber nur `enchId == nil`
--    bzw. `socket.gemId == nil`, nicht der bewertete `status`: der
--    ist "neutral", wenn für den Slot keine Empfehlung existiert, und
--    ein fehlender Stein bleibt ein fehlender Stein, auch wenn das
--    Spec-Profil zu diesem Sockel nichts zu sagen hat.
--
-- WANN NICHTS KOMMT (jeder Punkt ist ein vermiedener Fehlalarm)
--
--  * Vor dem Login-Fenster. Weder Spec noch Item-Cache sind bei
--    PLAYER_LOGIN verlässlich; ein Scan zu diesem Zeitpunkt meldet
--    halb geladene Ausrüstung als Befund. Gewartet wird wie in
--    modules/companion.lua auf PLAYER_ENTERING_WORLD plus Vorlauf.
--  * Solange der Client die Basisdaten des Gegenstands nicht hat.
--    Dann steht die Prüfung an, statt zu raten - GET_ITEM_INFO_RECEIVED
--    gibt es hier nicht, also wird schlicht ein paar Sekunden später
--    noch einmal nachgesehen (RETRY_DELAY, RETRY_MAX).
--  * Unterhalb von Selten (blau). Wer ein Twinkset zusammensucht,
--    wechselt im Zehnminutentakt Gegenstände, die niemand verzaubert.
--    Ein grünes Teil zu melden wäre formal richtig und praktisch nur
--    Lärm - siehe MIN_QUALITY.
--  * Im Kampf. Die Meldung wartet auf PLAYER_REGEN_ENABLED, statt
--    sich über die Bossleiste zu legen.
--
-- Abschalten: /wc alarm aus. Der Hinweis steht in der Meldung selbst;
-- eine Einblendung, die man nicht loswird, ohne die Dokumentation zu
-- lesen, ist eine Zumutung.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.GearAlert = {}

local GA = WeintCodex.GearAlert

local C          = WeintCodex.Colors
local SetSolidBg = WeintCodex.SetSolidBg
local DrawBorder = WeintCodex.DrawBorder
local F          = WeintCodex.Fonts
local Upper      = WeintCodex.Upper
local Truncate   = WeintCodex.Truncate

--------------------------------------------------
-- Konstanten
--------------------------------------------------

-- Ab welcher Gegenstandsqualität überhaupt gemeldet wird. 3 = Selten
-- (blau). Alles darunter ist in MoP Übergangsware: der Weg von 85 auf
-- 90 besteht aus Grün, und wer dabei verzaubert, wirft das Material
-- weg. Blau ist die erste Stufe, bei der sich die Frage stellt.
local MIN_QUALITY = 3

-- Ein vollständiger Scan liest je Gegenstand den Tooltip, und beim
-- Umsockeln feuert PLAYER_EQUIPMENT_CHANGED mehrfach hintereinander -
-- dieselbe Überlegung wie beim Ausrüstungsbericht der Companion.
local EQUIP_DEBOUNCE = 2.5

-- Vorlauf nach dem Betreten der Welt, bis der Item-Cache warm ist.
local ENTER_WORLD_DELAY = 10

-- Noch nicht gecachte Gegenstände: kurz warten, ein paar Mal.
local RETRY_DELAY = 3
local RETRY_MAX   = 3

-- Wie oft die Erinnerung im Ruhebereich höchstens kommt. Wer zwischen
-- Bank, Auktionshaus und Verzauberer hin und her läuft, löst
-- PLAYER_UPDATE_RESTING mehrfach aus; ohne diese Sperre wäre die
-- Erinnerung nach zehn Minuten in der Hauptstadt eine Belästigung.
local REST_COOLDOWN = 900

local WIDTH   = 470
local PAD     = 16
local ICON_SZ = 44
local ROW_H   = 17
local MAX_ROWS = 6

-- Einblenden, halten, ausblenden.
local FADE_IN  = 0.22
local FADE_OUT = 0.55
local SLIDE    = 14

--------------------------------------------------
-- Einstellungen
--------------------------------------------------

local DEFAULTS = {
    enabled      = true,
    sound        = true,
    restReminder = true,
    duration     = 9,
}

-- SavedData steht erst ab ADDON_LOADED bereit; deshalb bei jedem
-- Zugriff neu nachsehen, statt die Tabelle in einer Dateilokalen
-- festzuhalten (siehe core/access.lua für dieselbe Regel).
local function Store()
    WeintCodex.SavedData = WeintCodex.SavedData or {}
    local s = WeintCodex.SavedData.gearAlert
    if not s then
        s = {}
        WeintCodex.SavedData.gearAlert = s
    end
    for key, value in pairs(DEFAULTS) do
        if s[key] == nil then s[key] = value end
    end
    return s
end

--------------------------------------------------
-- Was ist offen?
--------------------------------------------------

-- Ergebnis je Slot: nehmen, überspringen oder warten. "Warten" ist der
-- Grund, warum diese Funktion drei Werte kennt und nicht zwei: ein
-- Gegenstand, dessen Basisdaten noch nicht da sind, hat keine
-- Qualität - ihn deshalb zu überspringen hiesse, eine Aussage über
-- unseren Cache als Aussage über die Rüstung auszugeben.
local TAKE, SKIP, WAIT = 1, 2, 3

local function SlotVerdict(link)
    if not link then return SKIP end
    local name, _, quality = GetItemInfo(link)
    if not name or quality == nil then return WAIT end
    if quality < MIN_QUALITY then return SKIP end
    return TAKE
end

-- Rückgabe: entries (nach Slot sortiert), pending (mindestens ein
-- Gegenstand war noch nicht im Cache).
local function Collect()
    if not (WeintCodex.Charakter and WeintCodex.Charakter.Scan) then
        return nil, false
    end

    -- Der Scan liest gecachte Tooltip-Ergebnisse; nach einem
    -- Ausrüstungswechsel wären das die von vorhin.
    if WeintCodex.Charakter.ClearCache then
        WeintCodex.Charakter.ClearCache()
    end

    local ok, scan = pcall(WeintCodex.Charakter.Scan)
    if not ok or type(scan) ~= "table" then return nil, false end

    local bySlot, entries, pending = {}, {}, false
    local verdicts, links = {}, {}

    local function Verdict(slotId)
        local v = verdicts[slotId]
        if v then return v end
        links[slotId] = GetInventoryItemLink("player", slotId)
        v = SlotVerdict(links[slotId])
        verdicts[slotId] = v
        return v
    end

    local function Entry(slotId, slotName)
        local e = bySlot[slotId]
        if e then return e end
        e = {
            slotId   = slotId,
            slotName = slotName,
            link     = links[slotId],
            enchant  = false,
            sockets  = 0,
        }
        bySlot[slotId] = e
        entries[#entries + 1] = e
        return e
    end

    for _, row in ipairs(scan.enchants and scan.enchants.rows or {}) do
        if not row.enchId then
            local v = Verdict(row.slotId)
            if v == WAIT then
                pending = true
            elseif v == TAKE then
                Entry(row.slotId, row.slotName).enchant = true
            end
        end
    end

    for _, row in ipairs(scan.gems and scan.gems.rows or {}) do
        local socket = row.socket
        -- socketsKnown == false heisst: der Client kannte die Basisdaten
        -- des Gegenstands nicht, die eingebauten Sockel sind damit
        -- unbekannt. Übrig bliebe nur die geratene Gürtelschnalle.
        if socket and not socket.gemId and row.socketsKnown ~= false then
            local v = Verdict(row.slotId)
            if v == WAIT then
                pending = true
            elseif v == TAKE then
                local e = Entry(row.slotId, row.slotName)
                e.sockets = e.sockets + 1
                if socket.buckle then e.buckle = true end
            end
        end
    end

    -- EQUIP_SLOTS läuft nach Slot-ID aufsteigend; danach sortiert steht
    -- die Liste in derselben Reihenfolge wie auf der Charakterseite.
    table.sort(entries, function(a, b) return a.slotId < b.slotId end)

    return entries, pending
end

GA.Collect = Collect

--------------------------------------------------
-- Texte
--------------------------------------------------

local function EntryFinding(e)
    local parts = {}
    if e.enchant then parts[#parts + 1] = "Verzauberung fehlt" end
    if e.sockets > 0 then
        if e.sockets == 1 then
            parts[#parts + 1] = e.buckle
                and "Gürtelschnalle fehlt oder Sockel leer"
                or  "1 Sockel leer"
        else
            parts[#parts + 1] = e.sockets .. " Sockel leer"
        end
    end
    return table.concat(parts, " · ")
end

local function ItemNameOf(e)
    return e.link and e.link:match("|h%[(.-)%]|h") or nil
end

-- Überschrift und Unterzeile der Einblendung. Ein einzelnes Teil nennt
-- den Befund gross und den Gegenstand darunter; mehrere nennen die Zahl,
-- weil "VERZAUBERUNG FEHLT" über einer Liste aus fünf Zeilen die falsche
-- Aussage wäre.
local function Headline(entries, reason)
    if #entries == 1 then
        local e = entries[1]
        local title
        if e.enchant and e.sockets > 0 then
            title = "Verzauberung und Sockel fehlen"
        elseif e.enchant then
            title = "Verzauberung fehlt"
        elseif e.sockets == 1 and e.buckle then
            title = "Gürtelschnalle fehlt"
        else
            title = "Sockel noch leer"
        end

        local item = ItemNameOf(e)
        local sub = item
            and (Truncate(item, 42) .. "  ·  " .. e.slotName)
            or  e.slotName
        return title, sub
    end

    local title = (reason == "rest")
        and (#entries .. " Teile brauchen noch etwas")
        or  (#entries .. " angelegte Teile sind offen")

    local ench, sock = 0, 0
    for _, e in ipairs(entries) do
        if e.enchant then ench = ench + 1 end
        sock = sock + e.sockets
    end

    local bits = {}
    if ench > 0 then
        bits[#bits + 1] = (ench == 1) and "1 Verzauberung fehlt"
                                      or  (ench .. " Verzauberungen fehlen")
    end
    if sock > 0 then
        bits[#bits + 1] = (sock == 1) and "1 Sockel ist leer"
                                      or  (sock .. " Sockel sind leer")
    end

    return title, table.concat(bits, "  ·  ")
end

--------------------------------------------------
-- Ton
--------------------------------------------------

local function PlayAlertSound()
    if not Store().sound then return end

    -- Welche der beiden Aufrufformen ein Classic-Build annimmt,
    -- schwankt (Datei-Pfad bzw. Kit-Name) - wie bei den Spec-Events in
    -- modules/companion.lua deshalb der Reihe nach über pcall.
    if type(PlaySoundFile) == "function" then
        local ok, played = pcall(PlaySoundFile,
            "Sound\\Interface\\RaidWarning.wav", "Master")
        if ok and played ~= false then return end
    end
    if type(PlaySound) == "function" then
        pcall(PlaySound, "RaidWarning")
    end
end

--------------------------------------------------
-- Einblendung
--------------------------------------------------

local frame, icon, eyebrow, headline, subline, hint
local rowLabels = {}
local anim = { state = nil, elapsed = 0, hold = 0 }
local moveMode = false

local function SavePosition()
    if not frame then return end
    local point, _, _, x, y = frame:GetPoint()
    if not point then return end
    Store().pos = { point = point, x = x, y = y }
end

local function RestorePosition()
    local pos = Store().pos
    frame:ClearAllPoints()
    if pos and pos.point then
        frame:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
    else
        frame:SetPoint("TOP", UIParent, "TOP", 0, -170)
    end
end

local function NewText(font, size, color, justify)
    local fs = frame:CreateFontString(nil, "OVERLAY")
    fs:SetFont(font, size, "")
    fs:SetTextColor(C[color][1], C[color][2], C[color][3])
    fs:SetJustifyH(justify or "LEFT")
    return fs
end

local function OpenCharakterPage(entries)
    local nav = WeintCodex.Navigation
    if not (WeintCodex.MainFrame and nav) then return end
    WeintCodex.MainFrame:Show()

    -- Erst den Bereich betreten, dann die Unterseite - dieselbe
    -- Reihenfolge wie in core/search.lua. Ueber GoToTab statt SwitchTo,
    -- damit die Navigationsspalte den Eintrag auch markiert (siehe die
    -- Begruendung an GoToTab in core/navigation.lua).
    if nav.GoToTab then
        nav.GoToTab("charakter")
    elseif nav.SwitchTo then
        nav.SwitchTo("charakter")
    end

    -- Auf die Seite, die zum Befund gehört: wer nur leere Sockel hat,
    -- will nicht auf der Verzauberungsseite landen.
    local anyEnchant = false
    for _, e in ipairs(entries or {}) do
        if e.enchant then anyEnchant = true; break end
    end

    local CH = WeintCodex.Charakter
    if not CH then return end
    if not anyEnchant and CH.ShowGems then
        CH.ShowGems()
    elseif CH.ShowEnchants then
        CH.ShowEnchants()
    end
end

local function Build()
    if frame then return end

    frame = CreateFrame("Button", "WeintCodexGearAlert", UIParent)
    frame:SetSize(WIDTH, 120)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    frame:RegisterForDrag("LeftButton")
    frame:Hide()

    -- Bewusst ohne CutCorners: hinter dieser Fläche liegt die Spielwelt,
    -- und die Eckmasken brauchen die Farbe des Untergrunds. Aus demselben
    -- Grund bleibt auch das Hauptfenster eckig (siehe core/ui.lua).
    SetSolidBg(frame, C.bgDark[1], C.bgDark[2], C.bgDark[3], 0.95)
    DrawBorder(frame, C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1.0, 1)

    -- Bernsteinfarbene Oberkante: die Hausform der Karte, hier zwei
    -- Pixel stark, weil das hier ein Befund ist und keine Seite.
    local accent = frame:CreateTexture(nil, "OVERLAY")
    accent:SetHeight(2)
    accent:SetPoint("TOPLEFT",  frame, "TOPLEFT",  0, 0)
    accent:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    accent:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1.0)

    -- Weicher Schimmer darunter, damit die Fläche über hellem Gelände
    -- nicht als grauer Kasten liest.
    local glow = frame:CreateTexture(nil, "ARTWORK")
    glow:SetHeight(46)
    glow:SetPoint("TOPLEFT",  frame, "TOPLEFT",  1, -2)
    glow:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -2)
    WeintCodex.ApplyVerticalGradient(glow,
        { C.accent[1], C.accent[2], C.accent[3], 0.14 },
        { C.accent[1], C.accent[2], C.accent[3], 0.00 })

    icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ICON_SZ, ICON_SZ)
    icon:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -PAD - 4)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    eyebrow  = NewText(F.mono,     10, "textDim")
    headline = NewText(F.sansBold, 20, "accentBright")
    subline  = NewText(F.sans,     12, "textMuted")
    hint     = NewText(F.sans,      9, "textFaint")

    frame:SetScript("OnDragStart", function(self)
        if not moveMode then return end
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition()
    end)

    frame:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            GA.Hide()
            return
        end
        if moveMode then
            moveMode = false
            GA.Hide()
            print(WeintCodex.ColorText("gold", "[WeintCodex]")
                .. " Position des Ausrüstungs-Alarms gespeichert.")
            return
        end
        local entries = self._entries
        GA.Hide()
        OpenCharakterPage(entries)
    end)

    frame:SetScript("OnUpdate", function(self, elapsed)
        if not anim.state then return end
        anim.elapsed = anim.elapsed + elapsed

        if anim.state == "in" then
            local t = math.min(1, anim.elapsed / FADE_IN)
            self:SetAlpha(t)
            -- ClearAllPoints ist Pflicht: SetPoint ergaenzt, es ersetzt
            -- nicht, und ein Frame mit 20 Ankern pro Sekunde steht am
            -- Ende irgendwo.
            self:ClearAllPoints()
            self:SetPoint(anim.point, UIParent, anim.point,
                anim.x, anim.y - SLIDE * (1 - t))
            if t >= 1 then
                anim.state, anim.elapsed = "hold", 0
            end

        elseif anim.state == "hold" then
            if anim.hold > 0 and anim.elapsed >= anim.hold then
                anim.state, anim.elapsed = "out", 0
            end

        elseif anim.state == "out" then
            local t = math.min(1, anim.elapsed / FADE_OUT)
            self:SetAlpha(1 - t)
            if t >= 1 then
                anim.state = nil
                self:Hide()
            end
        end
    end)

    RestorePosition()
end

-- Gemessene Zeilenhoehe statt geschaetzter. Die Textfelder sind links
-- UND rechts verankert, brechen also um, sobald eine Ueberschrift breiter
-- ist als die Flaeche - mit festen Abstaenden laege der Rest darunter
-- ineinander. Dieselbe Reihenfolge wie in core/onboarding.lua: erst den
-- Text setzen, dann messen, dann die Hoehe stellen.
local function TextHeight(fs, minimum)
    local ok, h = pcall(fs.GetStringHeight, fs)
    if not ok or type(h) ~= "number" or h <= 0 then return minimum end
    return math.max(minimum, math.ceil(h))
end

local function RowLabel(index)
    local fs = rowLabels[index]
    if fs then return fs end
    fs = NewText(F.sans, 11, "textNormal")
    rowLabels[index] = fs
    return fs
end

-- Zeichnet Inhalt und stellt die Höhe darauf ein. Reihenfolge trägt:
-- erst die Texte setzen, dann die Fensterhöhe - dieselbe Abfolge wie in
-- core/onboarding.lua, aus demselben Grund.
local function Layout(entries, reason)
    local single = (#entries == 1)
    local left   = PAD

    if single and entries[1].link then
        local tex = GetItemIcon and GetItemIcon(entries[1].link)
        if tex then
            icon:SetTexture(tex)
            icon:Show()
            left = PAD + ICON_SZ + 12
        else
            icon:Hide()
        end
    else
        icon:Hide()
    end

    local function Place(fs, y)
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT",  frame, "TOPLEFT",  left, -y)
        fs:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -y)
    end

    local y = PAD

    eyebrow:SetText(WeintCodex.Spaced(Upper(
        reason == "rest" and "Erinnerung · Ruhebereich" or "Ausrüstung")))
    Place(eyebrow, y)
    y = y + 15

    local title, sub = Headline(entries, reason)
    headline:SetText(Upper(title))
    Place(headline, y)
    y = y + TextHeight(headline, 24) + 2

    if sub and sub ~= "" then
        subline:SetText(sub)
        subline:Show()
        Place(subline, y)
        y = y + TextHeight(subline, 15) + 3
    else
        subline:Hide()
    end

    -- Die Einzelmeldung sagt den Befund schon in der Überschrift; die
    -- Liste darunter gibt es nur, wenn mehrere Teile offen sind.
    local shown = 0
    if not single then
        y = y + 4
        local limit = math.min(#entries, MAX_ROWS)
        for i = 1, limit do
            local e = entries[i]
            local fs = RowLabel(i)
            fs:SetText(WeintCodex.ColorText("textBright", e.slotName)
                .. "   " .. WeintCodex.ColorText("textMuted", EntryFinding(e)))
            fs:Show()
            fs:ClearAllPoints()
            fs:SetPoint("TOPLEFT",  frame, "TOPLEFT",  left, -y)
            fs:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -y)
            y = y + TextHeight(fs, ROW_H)
            shown = i
        end

        if #entries > limit then
            local fs = RowLabel(limit + 1)
            fs:SetText(WeintCodex.ColorText("textDim",
                "… und " .. (#entries - limit) .. " weitere"))
            fs:Show()
            fs:ClearAllPoints()
            fs:SetPoint("TOPLEFT",  frame, "TOPLEFT",  left, -y)
            fs:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -y)
            y = y + TextHeight(fs, ROW_H)
            shown = limit + 1
        end
    end

    for i = shown + 1, #rowLabels do rowLabels[i]:Hide() end

    -- Das Symbol darf die Fläche nicht überragen, auch nicht bei einer
    -- Einzelmeldung ohne Unterzeile.
    if icon:IsShown() then
        y = math.max(y, PAD + 4 + ICON_SZ)
    end

    y = y + 8
    hint:SetText(moveMode
        and "Ziehen zum Verschieben · Klick speichert die Position"
        or  "Linksklick öffnet die Charakterseite · Rechtsklick schliesst · |cffD4A24A/wc alarm aus|r")
    hint:ClearAllPoints()
    hint:SetPoint("TOPLEFT",  frame, "TOPLEFT",  PAD, -y)
    hint:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -y)
    y = y + TextHeight(hint, 12) + PAD

    frame:SetHeight(y)
end

--------------------------------------------------
-- Anzeigen / Verstecken
--------------------------------------------------

function GA.Hide()
    if not frame then return end
    anim.state = nil
    frame:Hide()
    frame:SetAlpha(1)
    RestorePosition()
end

-- Diese Funktion zeichnet nur. Ob ueberhaupt eingeblendet werden darf
-- (Kampf, abgeschaltet, nichts offen), entscheidet RunCheck weiter
-- unten - sonst laege dieselbe Frage an zwei Stellen.
function GA.Show(entries, reason, holdSeconds)
    if not entries or #entries == 0 then return end

    Build()
    frame._entries = entries

    Layout(entries, reason)
    RestorePosition()

    local point, _, _, x, y = frame:GetPoint()
    anim.point, anim.x, anim.y = point, x, y
    anim.state, anim.elapsed = "in", 0
    anim.hold = holdSeconds or Store().duration or DEFAULTS.duration

    frame:SetAlpha(0)
    frame:Show()

    PlayAlertSound()
end

--------------------------------------------------
-- Prüflauf
--------------------------------------------------

local pendingSlots = {}   -- Slots, die seit dem letzten Lauf gewechselt haben
local scanScheduled = false
local retries = 0

-- Erst nach dem Vorlauf wird überhaupt zugehört. Beim Anmelden und nach
-- jedem Ladebildschirm feuert PLAYER_EQUIPMENT_CHANGED für angelegte
-- Gegenstände, ohne dass jemand etwas angelegt hätte - ohne diese
-- Sperre begrüsste das Addon einen mit einer Liste aller offenen Slots,
-- und zwar bei jedem Zonenwechsel.
local ready = false

local function After(delay, fn)
    if C_Timer and C_Timer.After then
        C_Timer.After(delay, fn)
    else
        fn()
    end
end

-- Was im Kampf angefallen ist, wird nicht gezeigt, sondern vorgemerkt -
-- und nach dem Kampf neu geprueft statt aus dem Gedaechtnis gezeichnet.
-- Zwischen Pull und Ende kann sich die Ausruestung geaendert haben, und
-- eine Meldung ueber einen Zustand von vor vier Minuten ist keine.
local queued = nil

-- reason: "equip" (nur die gewechselten Slots) | "rest" | "manual"
local function RunCheck(reason, slotFilter)
    if not Store().enabled and reason ~= "manual" then return end

    if reason ~= "manual" and UnitAffectingCombat("player") then
        queued = { reason = reason, filter = slotFilter }
        return
    end

    -- Ein echter Befund verschiebt nichts; der Ziehmodus gehoert allein
    -- zu "/wc alarm bewegen".
    moveMode = false

    local entries, pending = Collect()
    if not entries then return end

    if slotFilter then
        local filtered = {}
        for _, e in ipairs(entries) do
            if slotFilter[e.slotId] then filtered[#filtered + 1] = e end
        end
        entries = filtered
    end

    -- Noch nicht gecachte Gegenstände: später noch einmal nachsehen,
    -- statt jetzt eine Aussage über den eigenen Cache zu treffen.
    -- Nachgefasst wird nur, solange NICHTS gefunden wurde - sonst käme
    -- die Meldung ein zweites Mal, sobald der Rest nachgeladen ist.
    if #entries == 0 and pending and retries < RETRY_MAX then
        retries = retries + 1
        After(RETRY_DELAY, function() RunCheck(reason, slotFilter) end)
        return
    end

    if #entries == 0 then
        if reason == "manual" then
            print(WeintCodex.ColorText("gold", "[WeintCodex]")
                .. " Ausrüstungs-Alarm: nichts offen"
                .. (pending and " (einige Gegenstände sind noch nicht geladen)." or "."))
        end
        return
    end

    GA.Show(entries, reason)
end

GA.RunCheck = RunCheck

--------------------------------------------------
-- Auslöser
--------------------------------------------------

local watcher = CreateFrame("Frame")

local function ScheduleEquipCheck()
    if scanScheduled then return end
    scanScheduled = true
    After(EQUIP_DEBOUNCE, function()
        scanScheduled = false
        local slots = pendingSlots
        pendingSlots = {}
        retries = 0
        if not next(slots) then return end
        RunCheck("equip", slots)
    end)
end

-- Erinnerung im Ruhebereich. Der Zeitstempel liegt in den SavedData und
-- nicht in einer Laufzeitvariablen: GetTime() beginnt nach jedem
-- /reload von vorn, und dann käme die Erinnerung genau dann wieder,
-- wenn man das Addon gerade neu geladen hat.
local function RestReminder()
    local s = Store()
    if not (s.enabled and s.restReminder) then return end
    if not IsResting() then return end

    local inInstance = IsInInstance and IsInInstance()
    if inInstance then return end

    local now = time()
    if s.lastRest and (now - s.lastRest) < REST_COOLDOWN then return end
    s.lastRest = now

    retries = 0
    RunCheck("rest", nil)
end

local wasResting = nil

watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
watcher:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
watcher:RegisterEvent("PLAYER_UPDATE_RESTING")
watcher:RegisterEvent("PLAYER_REGEN_ENABLED")

watcher:SetScript("OnEvent", function(_, event, arg1)

    if event == "PLAYER_EQUIPMENT_CHANGED" then
        if not (ready and Store().enabled) then return end
        if arg1 then pendingSlots[arg1] = true end
        ScheduleEquipCheck()
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        -- Erst wenn der Item-Cache warm ist. Bis dahin ist jede Aussage
        -- über fehlende Verzauberungen eine über unseren Ladezustand.
        ready = false
        pendingSlots = {}
        After(ENTER_WORLD_DELAY, function()
            ready = true
            pendingSlots = {}
            wasResting = IsResting() and true or false
            if wasResting then RestReminder() end
        end)
        return
    end

    if event == "PLAYER_UPDATE_RESTING" then
        local resting = IsResting() and true or false
        -- Nur beim Betreten. Das Ereignis feuert in beide Richtungen,
        -- und beim Verlassen ist die Erinnerung sinnlos - dort gibt es
        -- weder Bank noch Verzauberer.
        if resting and wasResting == false then
            After(2, RestReminder)
        end
        wasResting = resting
        return
    end

    if event == "PLAYER_REGEN_ENABLED" and queued then
        local q = queued
        queued = nil
        After(1, function()
            retries = 0
            RunCheck(q.reason, q.filter)
        end)
        return
    end
end)

--------------------------------------------------
-- Befehle (/wc alarm ...)
--------------------------------------------------

local function Say(text)
    print(WeintCodex.ColorText("gold", "[WeintCodex]") .. " " .. text)
end

function GA.PrintStatus()
    local s = Store()
    Say("Ausrüstungs-Alarm: "
        .. (s.enabled and WeintCodex.ColorText("green", "an")
                       or WeintCodex.ColorText("textDim", "aus"))
        .. "  ·  Ton: " .. (s.sound and "an" or "aus")
        .. "  ·  Erinnerung im Ruhebereich: " .. (s.restReminder and "an" or "aus")
        .. "  ·  Anzeigedauer: " .. tostring(s.duration) .. " s")
    Say("|cffaaaaaa/wc alarm an|aus · ton · ruhe · dauer <sek> · test · bewegen · jetzt|r")
end

-- Beispielmeldung mit den eigenen Daten, sonst mit erfundenen. Sie
-- bleibt stehen, bis man klickt, und lässt sich dabei verschieben -
-- eine Meldung, die nach neun Sekunden weg ist, kann man nicht
-- positionieren.
function GA.ShowMover()
    local entries = Collect()
    if not entries or #entries == 0 then
        entries = {
            { slotId = 9,  slotName = "Handgelenke", enchant = true,  sockets = 0 },
            { slotId = 10, slotName = "Hände",       enchant = false, sockets = 1 },
        }
    end
    moveMode = true
    GA.Show(entries, "manual", 0)
end

function GA.Command(rest)
    local s = Store()

    if rest == "an" or rest == "ein" or rest == "on" then
        s.enabled = true
        GA.PrintStatus()

    elseif rest == "aus" or rest == "off" then
        s.enabled = false
        GA.Hide()
        GA.PrintStatus()

    elseif rest == "ton" or rest == "sound" then
        s.sound = not s.sound
        GA.PrintStatus()

    elseif rest == "ruhe" or rest == "ruhebereich" then
        s.restReminder = not s.restReminder
        GA.PrintStatus()

    elseif rest == "test" then
        local entries = Collect()
        if not entries or #entries == 0 then
            entries = {
                { slotId = 9, slotName = "Handgelenke", enchant = true, sockets = 0 },
            }
        end
        moveMode = false
        GA.Show(entries, "manual")

    elseif rest == "bewegen" or rest == "position" then
        GA.ShowMover()

    elseif rest == "zuruecksetzen" or rest == "zurücksetzen" then
        s.pos = nil
        if frame then RestorePosition() end
        Say("Position des Ausrüstungs-Alarms zurückgesetzt.")

    elseif rest == "jetzt" or rest == "pruefen" or rest == "prüfen" then
        retries = 0
        RunCheck("manual", nil)

    else
        local seconds = rest and rest:match("^dauer%s+(%d+)$")
        if seconds then
            s.duration = math.max(3, math.min(60, tonumber(seconds)))
            Say("Anzeigedauer: " .. s.duration .. " Sekunden.")
        else
            GA.PrintStatus()
        end
    end
end
