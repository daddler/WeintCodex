--------------------------------------------------
-- WeintCodex :: Simmen — die Ausruestung bereitstellen (seit 2.9.0.0)
--------------------------------------------------
-- Seit 2.8.0.0 kommt eine Sim-Gewichtung ohne Abtippen ins Spiel: die
-- Companion nimmt die Ausgabe von wowsims entgegen und stellt sie zu. Der
-- Weg DAVOR blieb Handarbeit — die eigene Ausruestung musste im Sim Stueck
-- fuer Stueck nachgestellt werden. Wer das einmal gemacht hat, simmt nicht
-- jede Woche erneut, und eine Gewichtung, die zur Ausruestung von vor vier
-- Wochen gehoert, ist schlechter als ihr Ruf.
--
-- Diese Seite schliesst die Luecke, und zwar an der einzigen Stelle, an der
-- das Spiel dafuer ueberhaupt gebraucht wird.
--
-- WARUM ES DIESE SEITE BRAUCHT, OBWOHL SIE FAST NICHTS TUT.
--
-- Den Export schreibt der WowSimsExporter — das Addon, das wowsims selbst
-- dafuer nennt. Er legt ihn in seine SavedVariables, und dort liest ihn die
-- Companion. Dazwischen steht genau eine Tatsache: WOW SCHREIBT SEINE
-- SAVEDVARIABLES NUR BEIM NEULADEN UND BEIM AUSLOGGEN. Was gerade angelegt
-- ist, steht also noch nirgends, wo ein zweites Programm es sehen koennte.
--
-- Ein Neuladen kann nur der Spieler ausloesen, und er muss wissen, WARUM er
-- es tut. Genau das ist die Seite: sie sagt, was der Desktop gerade sieht,
-- ob das noch stimmt, und macht das Neuladen zu einem Knopf statt zu einem
-- Wissen, das man haben muss.
--
-- SIE LIEST EIN FREMDES ADDON — UND ZWAR NUR DAS DATUM.
--
-- In modules/statweights.lua steht "kein fremdes Addon", und das gilt dort
-- weiter: das ZERLEGEN einer fremden Ausgabe findet hier nicht statt. Was
-- diese Datei aus `WSEDB` liest, sind Name und Zeitstempel des letzten
-- Exports — nicht sein Inhalt. Den liest die Companion, und zwar aus
-- derselben Datei; eine Kopie durch WeintCodex hindurch waere eine zweite
-- Fassung derselben Daten, die genau dann veraltet, wenn sie gebraucht
-- wird. Geschrieben wird in fremde Daten nie.
--
-- DER ZEITSTEMPEL BEIM ANMELDEN IST DIE EIGENTLICHE AUSKUNFT.
--
-- Beim Login ist das, was im Speicher steht, genau das, was auf der
-- Festplatte steht — es kommt ja von dort. Aendert sich die Ausruestung
-- danach, schreibt der Exporter einen neueren Stand in den Speicher, und
-- die Festplatte bleibt zurueck. Der Vergleich der beiden Zeitstempel ist
-- damit die Antwort auf die einzige Frage, die diese Seite hat: sieht die
-- Companion, was ich gerade anhabe?
--
-- Ohne diesen Vergleich waere "bereitgestellt" eine Behauptung ueber etwas,
-- das man nicht sieht — dieselbe Linie wie `stars == 0` und `readiness()
-- is None` drueben.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.SimExport = {}

local SE = WeintCodex.SimExport
local C  = WeintCodex.Colors
local F  = WeintCodex.Fonts

local SetSolidBg = WeintCodex.SetSolidBg
local DrawBorder = WeintCodex.DrawBorder

local PAD_X  = 16
local HEAD_H = 78   -- dieselbe Kopfhoehe wie die uebrigen Charakter-Seiten

local ADDON = "WowSimsExporter"

local CURSE = "https://www.curseforge.com/wow/addons/wowsimsexporter"

local pageFrame

-- Der Stand, den die Festplatte hat: beim Anmelden gemerkt, weil er in
-- diesem Moment nachweislich derselbe ist wie der im Speicher.
local diskStamp = nil

local function Say(text)
    print(WeintCodex.ColorText("gold", "[WeintCodex]") .. " " .. text)
end

--------------------------------------------------
-- Was der Exporter zuletzt geschrieben hat
--------------------------------------------------

-- Alle Profile, nicht nur das voreingestellte: AceDB legt die Vorgabe unter
-- "Default" ab, aber wer sich je ein eigenes Profil angelegt hat, hat
-- mehrere — und dann waere ausgerechnet die Vorgabe die veraltete.
local function Newest()
    local db = _G.WSEDB

    if type(db) ~= "table" or type(db.profiles) ~= "table" then
        return nil
    end

    local best

    for _, profile in pairs(db.profiles) do
        if type(profile) == "table" and type(profile.savedCharacters) == "table" then
            for _, entry in ipairs(profile.savedCharacters) do
                if type(entry) == "table" and type(entry.data) == "string"
                   and entry.data ~= "" then
                    local stamp = tonumber(entry.timestamp) or 0
                    if not best or stamp > best.stamp then
                        best = { name = entry.name or "?", stamp = stamp }
                    end
                end
            end
        end
    end

    return best
end

local function Loaded()
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded(ADDON) and true or false
    end
    return _G.IsAddOnLoaded and IsAddOnLoaded(ADDON) and true or false
end

-- Installiert, aber vielleicht abgeschaltet. Der Unterschied traegt: das
-- eine verlangt einen Download, das andere einen Haken im Addon-Fenster.
local function Installed()
    local info = C_AddOns and C_AddOns.GetAddOnInfo
    if info then
        local name = info(ADDON)
        return name ~= nil
    end
    return _G.GetAddOnInfo and select(1, GetAddOnInfo(ADDON)) ~= nil
end

--------------------------------------------------
-- Der Zustand, aus dem die Seite ihre Saetze baut
--------------------------------------------------
--
-- Vier Faelle, und drei davon verlangen etwas voellig anderes: kein Addon,
-- Addon aus, nie exportiert, exportiert aber nicht auf der Festplatte. Ein
-- gemeinsamer Satz waere fuer drei von ihnen falsch.
--------------------------------------------------

SE.NO_ADDON = "no_addon"
SE.DISABLED = "disabled"
SE.NO_EXPORT = "no_export"
SE.STALE = "stale"
SE.READY = "ready"

function SE.State()
    if not Installed() then
        return { status = SE.NO_ADDON }
    end

    if not Loaded() then
        return { status = SE.DISABLED }
    end

    local entry = Newest()

    if not entry then
        return { status = SE.NO_EXPORT }
    end

    -- Der Speicher ist neuer als das, was beim Anmelden dastand: seitdem hat
    -- sich etwas geaendert, und die Festplatte weiss noch nichts davon.
    local onDisk = (diskStamp ~= nil) and entry.stamp <= diskStamp

    return {
        status = onDisk and SE.READY or SE.STALE,
        entry  = entry,
        disk   = diskStamp,
    }
end

--------------------------------------------------
-- Bereitstellen
--------------------------------------------------
--
-- Der Exporter schreibt von selbst, sobald sich Ausruestung, Talente oder
-- Glyphen aendern. Trotzdem wird hier angestupst, und zwar ueber SEINEN
-- eigenen Weg (`OnCharacterChanged`) statt ueber einen nachgebauten: was
-- ein Export ist, entscheidet er.
--
-- DER STUPS DARF SCHEITERN, DAS NEULADEN NICHT.
--
-- Er haengt an einer Funktion eines fremden Addons; aendert die sich, ist
-- das kein Grund, den Knopf tot zu stellen — der eigentliche Zweck ist das
-- Neuladen, und der automatische Export deckt den Normalfall ohnehin ab.
-- Deshalb `pcall`, und deshalb wird HINTERHER nachgesehen, ob sich der
-- Zeitstempel bewegt hat: eine Rueckmeldung ueber das Ergebnis, nicht ueber
-- den Versuch (dieselbe Lehre wie beim Signalton in modules/gearalert.lua).
--------------------------------------------------

function SE.Nudge()
    local before = Newest()

    local lib = _G.LibStub
    local addon = lib and lib("AceAddon-3.0", true)
    addon = addon and addon:GetAddon(ADDON, true)

    if addon and addon.OnCharacterChanged then
        pcall(addon.OnCharacterChanged, addon, "WEINTCODEX")
    end

    local after = Newest()

    if not after then
        return false
    end

    if not before then
        return true
    end

    return after.stamp > before.stamp
end

function SE.Provide()
    if InCombatLockdown() then
        Say("Im Kampf wird nicht neu geladen. Danach noch einmal.")
        return
    end

    local state = SE.State()

    if state.status == SE.NO_ADDON or state.status == SE.DISABLED then
        Say("Dafür wird der WowSimsExporter gebraucht: " .. CURSE)
        return
    end

    SE.Nudge()

    if SE.ShowPage and pageFrame and pageFrame:IsShown() then
        SE.ShowPage()
    end

    -- Derselbe Dialog wie bei der Companion-Synchronisation, und aus
    -- demselben Grund: es ist derselbe Vorgang. Ein zweites Neuladen-Fenster
    -- mit eigener Beschriftung waere eine zweite Erklaerung fuer eine Sache.
    if WeintCodex.Dialog and WeintCodex.Dialog.Show then
        WeintCodex.Dialog.Show(
[[Deine Ausrüstung ist vorbereitet.

World of Warcraft schreibt seine Daten erst beim
Neuladen auf die Festplatte — danach kann die
Companion den Sim mit deiner Ausrüstung öffnen.

Du kannst dich stattdessen auch einfach ausloggen.]])
    else
        ReloadUI()
    end
end

--------------------------------------------------
-- Die Seite
--------------------------------------------------

local function ClearContent()
    local cp = WeintCodex.ContentPanel
    if not cp then return end
    for _, child in pairs({ cp:GetChildren() }) do child:Hide() end
end

local function Text(parent, size, semi)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(semi and F.sansSemi or F.sans, size, "")
    fs:SetJustifyH("LEFT")
    return fs
end

-- Eine Zeile Fliesstext ueber die ganze Breite, die ihre Hoehe selbst
-- meldet. Eine geschaetzte Hoehe faellt genau dann auf, wenn der Text am
-- laengsten ist — und dann liegt der naechste Block darueber (dieselbe
-- Regel wie bei InspectorCard in core/navigation.lua).
local function Paragraph(parent, y, size, color, text)
    local fs = Text(parent, size)
    fs:SetPoint("TOPLEFT",  parent, "TOPLEFT",  PAD_X, y)
    fs:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PAD_X, y)
    fs:SetSpacing(3)
    fs:SetTextColor(unpack(color))
    fs:SetText(text)
    return y - fs:GetStringHeight() - 10
end

-- Auch von /wc simmen pruefen benutzt, und deshalb an SE haengend: das
-- Alter ist die eigentliche Auskunft dieser Seite (WoW schreibt nur beim
-- Neuladen und beim Ausloggen), und was sie sagt, wird geprueft.
function SE.Ago(stamp)
    if not stamp or stamp <= 0 then
        return "ohne Datum"
    end

    local age = time() - stamp

    if age < 0 then
        return date("%d.%m.%Y %H:%M", stamp)
    elseif age < 120 then
        return "gerade eben"
    elseif age < 3600 then
        return ("vor %d Minuten"):format(math.floor(age / 60))
    elseif age < 86400 then
        local hours = math.floor(age / 3600)
        return hours == 1 and "vor einer Stunde" or ("vor %d Stunden"):format(hours)
    end

    local days = math.floor(age / 86400)
    return days == 1 and "gestern" or ("vor %d Tagen"):format(days)
end

function SE.ShowPage()
    local cp = WeintCodex.ContentPanel
    if not cp then return end

    -- Diese Seite gehoert zu Charakter, wird aber nicht von
    -- modules/charakter.lua gezeichnet. Ohne diesen Aufruf legte dessen
    -- Ausruestungs-Watcher die zuletzt gezeigte Charakterseite darueber
    -- (dieselbe Kopplung wie bei modules/reforge.lua und modules/academy.lua).
    if WeintCodex.Charakter and WeintCodex.Charakter.LeaveView then
        WeintCodex.Charakter.LeaveView()
    end

    ClearContent()

    if pageFrame then pageFrame:Hide(); pageFrame = nil end

    if WeintCodex.SetBreadcrumb then
        WeintCodex.SetBreadcrumb("Charakter", "Simmen")
    end

    pageFrame = CreateFrame("Frame", nil, cp)
    pageFrame:SetAllPoints(cp)

    local state = SE.State()

    WeintCodex.PageHead(pageFrame, {
        eyebrow = "Charakter",
        title   = "Simmen",
        sub     = "Ausrüstung an wowsims, Gewichtung zurück.",
        titleSize = 20, subSize = 10,
        x = PAD_X, y = 14, height = HEAD_H - 14,
    })

    local y = -HEAD_H

    --------------------------------------------------
    -- Was hier passiert
    --
    -- Drei Schritte, und der wichtigste Satz ist, dass zwei davon gar
    -- nicht hier stattfinden. Wer nicht weiss, dass die Companion den
    -- Rest uebernimmt, sucht auf dieser Seite nach einem Sim.
    --------------------------------------------------

    y = Paragraph(pageFrame, y, 11, C.textNormal,
        "Gesimmt wird auf wowsims.com — WeintCodex simmt nicht selbst, "
        .. "und die Companion auch nicht. Was hier passiert, ist der Weg "
        .. "dorthin und zurück:")

    y = Paragraph(pageFrame, y, 10, C.textDim,
        WeintCodex.ColorText("gold", "1.") .. " Hier bereitstellen — "
        .. "einmal neu laden, damit dein Stand auf der Festplatte steht.\n"
        .. WeintCodex.ColorText("gold", "2.") .. " In der Companion unter "
        .. "Simmen den Knopf drücken: der Sim öffnet sich mit deiner "
        .. "Ausrüstung, dort genügt Suggest Reforges.\n"
        .. WeintCodex.ColorText("gold", "3.") .. " Das Ergebnis in die "
        .. "Companion einfügen — die Gewichtung landet auf "
        .. WeintCodex.ColorText("textNormal", "Priorisierung") .. ".")

    --------------------------------------------------
    -- Der Stand
    --------------------------------------------------

    local box = CreateFrame("Frame", nil, pageFrame)
    box:SetPoint("TOPLEFT",  pageFrame, "TOPLEFT",  PAD_X, y)
    box:SetPoint("TOPRIGHT", pageFrame, "TOPRIGHT", -PAD_X, y)
    box:SetHeight(72)

    local ready = state.status == SE.READY
    local tone  = ready and C.green or C.gold

    SetSolidBg(box, tone[1], tone[2], tone[3], 0.10)
    DrawBorder(box, tone[1], tone[2], tone[3], 0.45, 1)

    local head = Text(box, 12, true)
    head:SetPoint("TOPLEFT", box, "TOPLEFT", 12, -10)
    head:SetTextColor(unpack(ready and C.green or C.goldBright))

    local body = Text(box, 10)
    body:SetPoint("TOPLEFT",  box, "TOPLEFT",  12, -30)
    body:SetPoint("TOPRIGHT", box, "TOPRIGHT", -12, -30)
    body:SetSpacing(2)
    body:SetTextColor(unpack(C.textDim))

    if state.status == SE.NO_ADDON then
        head:SetText("Der WowSimsExporter fehlt")
        body:SetText("Er ist das Addon, das wowsims selbst dafür nennt, und "
            .. "er schreibt den Export, den die Companion liest.\n" .. CURSE)

    elseif state.status == SE.DISABLED then
        head:SetText("Der WowSimsExporter ist abgeschaltet")
        body:SetText("Im Addon-Fenster des Spiels einschalten und neu laden — "
            .. "installiert ist er.")

    elseif state.status == SE.NO_EXPORT then
        head:SetText("Noch nichts gemeldet")
        body:SetText("Der Exporter schreibt beim ersten Wechsel von "
            .. "Ausrüstung, Talenten oder Glyphen — oder gleich jetzt über "
            .. "den Knopf darunter. Gesimmt wird ab Stufe 90.")

    elseif state.status == SE.STALE then
        head:SetText("Bereit zum Neuladen")
        body:SetText(("%s · %s im Spiel gemeldet. Auf der Festplatte steht "
            .. "noch der Stand von vorhin — die Companion sieht ihn erst "
            .. "nach dem Neuladen."):format(
                state.entry.name or "?", SE.Ago(state.entry.stamp)))

    else
        head:SetText("Die Companion sieht deinen aktuellen Stand")
        body:SetText(("%s · %s gemeldet. Solange du nichts umziehst, ist "
            .. "nichts zu tun."):format(
                state.entry.name or "?", SE.Ago(state.entry.stamp)))
    end

    y = y - 82

    --------------------------------------------------
    -- Der Knopf
    --
    -- Er steht auch dann da, wenn der Stand schon aktuell ist: ein Knopf,
    -- der je nach Zustand verschwindet, laesst sich weder erklaeren noch
    -- suchen (dieselbe Regel wie "lock, don't hide" in core/access.lua).
    --------------------------------------------------

    local button = WeintCodex.CreateButton(pageFrame, {
        text = "Bereitstellen und neu laden",
        kind = "primary",
        height = 36,
        tooltip = "Schreibt deinen jetzigen Stand für die Companion heraus. "
            .. "World of Warcraft speichert erst beim Neuladen oder Ausloggen "
            .. "— darum der Neustart der Oberfläche. Auch über /wc simmen.",
        onClick = function() SE.Provide() end,
    })
    button:SetPoint("TOPLEFT", pageFrame, "TOPLEFT", PAD_X, y)

    if state.status == SE.NO_ADDON or state.status == SE.DISABLED then
        button:Disable()
        if button.SetAlpha then button:SetAlpha(0.45) end
    end

    y = y - 46

    y = Paragraph(pageFrame, y, 9, C.textFaint,
        "Wenn du dich ohnehin gleich ausloggst, brauchst du den Knopf nicht "
        .. "— beim Ausloggen schreibt das Spiel dasselbe heraus.")

    pageFrame:Show()
end

--------------------------------------------------
-- Befehl und Anmeldung
--------------------------------------------------

function SE.Command(rest)
    rest = (rest or ""):lower()

    if rest == "jetzt" or rest == "bereit" or rest == "bereitstellen" then
        SE.Provide()
        return
    end

    -- Diagnose, aus demselben Grund wie /wc sockel und /wc tempo: von aussen
    -- sieht "die Companion findet nichts" bei fehlendem Addon, abgeschaltetem
    -- Addon, leerer Liste und veralteter Festplatte voellig gleich aus.
    if rest == "pruefen" or rest == "prüfen" or rest == "check" then
        local state = SE.State()
        Say("Simmen — Zustand: " .. state.status)
        Say("  Addon installiert: " .. tostring(Installed())
            .. ", geladen: " .. tostring(Loaded()))
        if state.entry then
            Say(("  Zuletzt gemeldet: %s (%s, %d)"):format(
                state.entry.name or "?", SE.Ago(state.entry.stamp),
                state.entry.stamp or 0))
        else
            Say("  Zuletzt gemeldet: nichts")
        end
        Say("  Stand beim Anmelden: " .. tostring(diskStamp))
        return
    end

    if WeintCodex.Navigation and WeintCodex.Navigation.GoToTab then
        WeintCodex.Navigation.GoToTab("charakter")
    end
    SE.ShowPage()
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:SetScript("OnEvent", function()
    -- Was jetzt im Speicher steht, kommt von der Festplatte. Genau das ist
    -- der Vergleichspunkt fuer alles, was danach passiert.
    local entry = Newest()
    diskStamp = entry and entry.stamp or 0
end)
