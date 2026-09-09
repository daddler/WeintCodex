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
-- DER OFFENE SIM-LAUF (seit 3.1.2.0)
--------------------------------------------------
-- Was ein Spieler erwartet: bereitstellen, simmen, zurueckkommen — und
-- das Addon fragt, ob es das Ergebnis holen soll.
--
-- WAS DAS ADDON DABEI NICHT KANN, UND ZWAR PRINZIPIELL: nachsehen, ob
-- etwas in der Warteschlange liegt. WoW liest seine SavedVariables beim
-- Laden EINMAL, und die Live-Datei der Companion ist eine Lua-Datei, die
-- beim Laden ausgefuehrt wird. Beides beantwortet die Frage "liegt da
-- was?" erst NACH einem Neuladen — und dann ist sie schon beantwortet.
-- Ein Addon kann keine Datei lesen und kein Netz benutzen.
--
-- ALSO IST DIE FRAGE EINE ERWARTUNG, KEINE BEOBACHTUNG, und sie ist
-- genau so formuliert. Der Spieler hat "Bereitstellen" gedrueckt; das
-- ist die Ankuendigung, gleich zu simmen. Diese Ankuendigung wird
-- gemerkt und ueberlebt das Neuladen, das direkt darauf folgt.
--
-- KEIN MODALER DIALOG. Wer zurueckkommt, steht vielleicht schon im
-- Kampf. Ein Fenster, das sich in den Weg stellt fuer etwas, das man
-- selbst angestossen hat, ist uebergriffig — ein Kasten am Rand ist eine
-- Auskunft. Er kommt erst nach AWAIT_DELAY (vorher simmt man noch), er
-- verschwindet von selbst, sobald etwas ankommt, und er verfaellt nach
-- AWAIT_MAX: danach war es kein Sim-Lauf mehr, sondern ein Reload von
-- vorgestern.
--------------------------------------------------

local AWAIT_DELAY = 150          -- 2,5 Minuten: vorher ist niemand fertig
local AWAIT_MAX   = 2 * 60 * 60  -- danach war es kein Sim-Lauf mehr

local function AwaitStore()
    WeintCodex.SavedData = WeintCodex.SavedData or {}
    local sd = WeintCodex.SavedData
    sd.simexport = sd.simexport or {}
    return sd.simexport
end

-- Wie lange der Lauf schon offen ist, oder nil, wenn keiner offen ist.
function SE.AwaitingFor()
    local at = tonumber(AwaitStore().awaitingAt)
    if not at or at <= 0 then return nil end

    local age = (time and time() or 0) - at
    if age < 0 or age > AWAIT_MAX then return nil end

    return age
end

function SE.NoteProvided()
    AwaitStore().awaitingAt = time and time() or 0
end

--------------------------------------------------
-- DER HANDSHAKE (seit 3.2.0.0)
--------------------------------------------------
-- Bis 3.1.2.0 war "es ist etwas angekommen" die ganze Antwort. Sie
-- reicht fuer den Normalfall und ist im einen Fall, auf den es ankommt,
-- schlicht falsch:
--
--   Bereitstellen -> simmen -> ein Teil wechseln -> nochmal
--   bereitstellen -> und dann das Ergebnis des ERSTEN Laufs einfuegen.
--
-- Das kommt an, sieht vollstaendig aus und gehoert zu einer Ausruestung
-- von vorhin. Von aussen ist es von einem richtigen Ergebnis nicht zu
-- unterscheiden - genau die Sorte Fehler, die keine Fehlermeldung
-- erzeugt.
--
-- WORAN ES SICH ERKENNEN LAESST, OHNE EINEN ZWEITEN KANAL: der
-- Zeitstempel der Ausruestung, MIT der gesimmt wurde. Ihn hat der
-- WowSimsExporter in DIESEM Spiel geschrieben, er steht also in
-- derselben Uhr wie `awaitingAt`. Die Companion reicht ihn als
-- `startedAt` durch (Abschnitt 8 des Strings, Feld `startedAt` der
-- Nachricht).
--
-- ES BLEIBT EINE ERWARTUNG UND KEINE BEOBACHTUNG. Ein Addon kann keine
-- Datei lesen und kein Netz benutzen; es weiss nur, was es selbst
-- gemerkt hat. Deshalb wird hier nichts abgewiesen - es wird gesagt.
--------------------------------------------------

-- Wieviel frueher der Export sein darf als das Bereitstellen.
--
-- SE.Provide() stupst den Exporter an und merkt sich ERST DANACH die
-- Zeit; der Zeitstempel liegt also ein bis zwei Sekunden davor. Wer
-- ohne den Knopf auskommt (der Exporter schreibt von selbst, sobald
-- sich etwas aendert), liegt weiter davor. Zwei Minuten sind
-- grosszuegig genug dafuer und immer noch weit von "ein Lauf von
-- vorgestern" entfernt.
local AWAIT_SLACK = 120

-- Gehoert ein Ergebnis mit diesem Startzeitpunkt zu dem Lauf, auf den
-- gewartet wird?
--
-- Rueckgabe:
--   true   ja - es ist mindestens so neu wie das Bereitstellen
--   false  nein - es wurde mit einer aelteren Ausruestung gesimmt
--   nil    keine Aussage (kein offener Lauf, oder kein Zeitstempel
--          dabei). NIL IST NICHT FALSE: eine aeltere Companion schickt
--          gar keinen, und daraus "gehoert nicht dazu" zu machen waere
--          eine Warnung ueber etwas, das niemand geprueft hat.
function SE.MatchesOpenRun(startedAt)
    local at = tonumber(AwaitStore().awaitingAt)
    if not at or at <= 0 then return nil end

    startedAt = tonumber(startedAt) or 0
    if startedAt <= 0 then return nil end

    return startedAt >= (at - AWAIT_SLACK)
end

-- Der zuletzt angekommene Lauf, fuer die Diagnose und fuer `/wc ziel`.
function SE.LastRun()
    local run = AwaitStore().lastRun
    if type(run) ~= "table" then return nil end
    return run
end

-- Es ist etwas angekommen. Gerufen von modules/companion.lua, wenn eine
-- Gewichtung oder ein Zielzustand zugestellt wurde, und vom Import-Weg
-- ueber die Zwischenablage.
--
-- `info` ist freiwillig: { run = "SIM-...", startedAt = n,
-- kind = "weights"|"target" }. Ohne sie verhaelt sich der Aufruf genau
-- wie vor 3.2.0.0 - das ist die Vertraeglichkeit mit jeder aelteren
-- Companion und mit einem von Hand getippten String.
--
-- Rueckgabe: derselbe Wert wie SE.MatchesOpenRun (true/false/nil).
function SE.NoteArrival(info)
    local store = AwaitStore()

    local run, startedAt, kind

    if type(info) == "table" then
        run       = tostring(info.run or "")
        startedAt = tonumber(info.startedAt) or 0
        kind      = tostring(info.kind or "")
    end

    local passt = SE.MatchesOpenRun(startedAt)

    -- WAS ANKOMMT, WIRD FESTGEHALTEN - auch das, was nicht passt.
    -- `/wc ziel` und `/wc simmen pruefen` beantworten damit die erste
    -- Frage jeder Rueckmeldung: aus welchem Lauf stammt das hier?
    if run and run ~= "" then
        local last = store.lastRun
        if type(last) ~= "table" or last.id ~= run then
            last = { id = run, startedAt = startedAt }
        end
        last.at = time and time() or 0
        if kind == "weights" then last.weights = true end
        if kind == "target"  then last.target  = true end
        store.lastRun = last
    end

    -- EIN ERGEBNIS AUS EINEM AELTEREN LAUF BEENDET DAS WARTEN NICHT.
    -- Der Lauf, den der Spieler bereitgestellt hat, ist weiter offen -
    -- und er soll erfahren, warum das hier nicht der war. Alles andere
    -- hiesse, den Kasten wegzuraeumen und den Irrtum stehenzulassen.
    if passt == false then
        return false
    end

    store.awaitingAt = nil
    if SE.HideAwaitPanel then SE.HideAwaitPanel() end

    return passt
end

-- Der Satz zu einer Ankunft - oder "", wenn es nichts zu sagen gibt.
--
-- KEIN SATZ IST DER NORMALFALL. Wer bereitstellt, simmt und einfuegt,
-- hat nichts falsch gemacht und braucht keine Bestaetigung dafuer, dass
-- das Erwartete eingetroffen ist. Gesagt wird nur der Fall, der sonst
-- unbemerkt bliebe.
function SE.ArrivalNote(passt, startedAt)
    if passt ~= false then return "" end

    local at = tonumber(AwaitStore().awaitingAt)

    return "Achtung: dieses Ergebnis wurde mit einer aelteren Ausruestung"
        .. " gesimmt (" .. SE.Ago(startedAt) .. " gemeldet)."
        .. (at and (" Der Lauf, den du " .. SE.Ago(at)
                    .. " bereitgestellt hast, ist noch offen.") or "")
        .. " Was noch passt, gilt trotzdem - Platz fuer Platz."
end

--------------------------------------------------
-- DIE ANKUNFTS-ZUSAMMENFASSUNG (seit 3.2.0.1)
--------------------------------------------------
-- "Jetzt neu laden" im Kasten unten loest das Neuladen aus - und
-- DANACH sah der Spieler bisher nur eine Chatzeile. Fuer den manuellen
-- Import gibt es dafuer ein Fenster (TG.ShowConfirm); fuer den Weg
-- ueber die Addon-Bruecke, den genau dieser Knopf nimmt, bisher keins.
--
-- GEZEIGT WIRD NUR, WENN VOR DIESEM LOGIN EIN LAUF OFFEN WAR - sonst
-- ploppte bei JEDEM Login mit wartenden Nachrichten ein Fenster auf,
-- auch fuer eine Gewichtung von vor drei Tagen, die man laengst kennt.
-- Genau deshalb wird das hier VOR modules/companion.lua's
-- ProcessQueue() festgehalten: NoteArrival() loescht `awaitingAt`
-- sofort, und danach liesse sich "war gerade ein Lauf offen" nicht
-- mehr beantworten.
--
-- WAS GEZEIGT WIRD, IST DIE ROHE AUSKUNFT DER INBOX-HANDLER, NICHT
-- DAS URTEIL DES HANDSHAKES. Auch ein Ergebnis aus einem aelteren Lauf
-- (SE.MatchesOpenRun() == false) wird zusammengefasst - die
-- Chatwarnung daneben sagt bereits, dass es nicht das erwartete war;
-- diese Zusammenfassung sagt, WAS es stattdessen war. Verschweigen
-- waere hier die falsche Zurueckhaltung.
--------------------------------------------------

local pendingArrival = nil

-- Aufgerufen EINMAL von modules/companion.lua, bevor die Nachrichten
-- dieses Logins verarbeitet werden.
function SE.BeginArrival()
    pendingArrival = (SE.AwaitingFor() ~= nil) and {} or nil
end

-- Von INBOX_HANDLERS.stat_weights aufgerufen, mit dem frischesten
-- Eintrag dieser Zustellung (oder nil, wenn keiner frisch war). Ohne
-- offenen Lauf (siehe BeginArrival) ein stilles Nichts.
function SE.NoteArrivedWeights(entry)
    if pendingArrival then pendingArrival.weights = entry end
end

function SE.NoteArrivedTarget(entry)
    if pendingArrival then pendingArrival.target = entry end
end

-- Aufgerufen EINMAL, nachdem alle Nachrichten dieses Logins verarbeitet
-- sind. Zeigt die Zusammenfassung nur, wenn tatsaechlich etwas dabei
-- war - ein offener Lauf, bei dem am Ende doch nichts (oder nur ein
-- Raid-Import) ankam, bekommt kein leeres Fenster.
function SE.EndArrival()
    local arrival = pendingArrival
    pendingArrival = nil

    if not arrival then return end
    if not (arrival.weights or arrival.target) then return end

    local TG = WeintCodex.TargetGear
    if TG and TG.ShowArrival then
        TG.ShowArrival(arrival)
    end
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
    -- Fuer Heiler gibt es nichts bereitzustellen: ihr Text entsteht im
    -- Spiel und geht ueber die Zwischenablage. Ein Neuladen waere hier
    -- ein Schritt, der nichts bewirkt — und einer, den man erst nach dem
    -- Ladebildschirm als sinnlos erkennt.
    local QE = WeintCodex.QELive
    local profileKey = WeintCodex.Charakter
        and WeintCodex.Charakter.GetProfileKey
        and WeintCodex.Charakter.GetProfileKey()

    if QE and QE.Entry and QE.Entry(profileKey) then
        Say("Als Heiler geht die Ausrüstung über die Zwischenablage zu "
            .. "QE Live — dafür ist kein Neuladen nötig.")
        if WeintCodex.Navigation and WeintCodex.Navigation.GoToTab then
            WeintCodex.Navigation.GoToTab("charakter")
        end
        SE.ShowPage()
        return
    end

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

    -- Vor dem Neuladen gemerkt: SavedVariables werden beim Reload
    -- geschrieben, danach ist es zu spaet.
    SE.NoteProvided()

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

--------------------------------------------------
-- DER HEILER-ZWEIG DERSELBEN SEITE (seit 2.9.1.0)
--------------------------------------------------
--
-- Gesimmt wird nicht ueberall dasselbe. Fuer Schadensausteiler ist die
-- Adresse wowsims.com/mop, fuer Heiler questionablyepic.com/live — und
-- das ist keine Vorliebe, sondern das Werkzeug, mit dem Heiler ihre
-- Ausruestung planen.
--
-- EINE SEITE, ZWEI WEGE — UND SIE SEHEN NICHT GLEICH AUS.
--
-- Der wowsims-Zweig darueber dreht sich um das Neuladen: dort liest die
-- COMPANION eine Datei, und WoW schreibt sie erst beim Neuladen. Hier
-- entsteht der Text im Spiel und geht ueber die Zwischenablage — also
-- gibt es nichts bereitzustellen und nichts neu zu laden. Beides in
-- einen gemeinsamen Ablauf zu pressen hiesse, dem Heiler einen Schritt
-- abzuverlangen, den es fuer ihn nicht gibt.
--
-- WELCHE SEITE ES WIRD, ENTSCHEIDET DIE DATENLAGE.
--
-- Gefragt wird `QE.Entry(profileKey)` und nicht "ist das ein Heiler":
-- massgeblich ist, ob QE Live diese Spezialisierung ueberhaupt fuehrt.
-- Eine Spec ohne Eintrag bekommt den bisherigen Weg statt einer Seite,
-- die auf ein Werkzeug zeigt, das ihr nichts zu sagen hat.
--------------------------------------------------

local function HealerPage(frame, profileKey, entry)
    local QE = WeintCodex.QELive

    WeintCodex.PageHead(frame, {
        eyebrow = "Charakter",
        title   = "Simmen",
        sub     = "Ausrüstung an QE Live — dem Werkzeug für Heiler.",
        titleSize = 20, subSize = 10,
        x = PAD_X, y = 14, height = HEAD_H - 14,
    })

    local y = -HEAD_H

    y = Paragraph(frame, y, 11, C.textNormal,
        "Für Heiler rechnet " .. WeintCodex.ColorText("textNormal",
            "questionablyepic.com/live") .. " — WeintCodex rechnet das "
        .. "nicht nach und die Companion auch nicht. Was hier passiert, "
        .. "ist der Weg dorthin:")

    y = Paragraph(frame, y, 10, C.textDim,
        WeintCodex.ColorText("gold", "1.") .. " Den Text unten markieren "
        .. "und mit Strg+C kopieren.\n"
        .. WeintCodex.ColorText("gold", "2.") .. " Auf QE Live einen "
        .. "Charakter deiner Spezialisierung anlegen und den Text dort "
        .. "unter Import einfügen.\n"
        .. WeintCodex.ColorText("gold", "3.") .. " Top Gear laufen lassen "
        .. "— das Ergebnis steht dort. Zurück ins Spiel kommt es nicht: "
        .. "QE Live gibt keine Wertegewichte heraus.")

    --------------------------------------------------
    -- Der Stand
    --
    -- Vier Faelle, und sie verlangen Verschiedenes: nichts angelegt,
    -- Grunddaten fehlen noch, alles gelesen, Text nicht baubar. Ein
    -- gemeinsamer Satz waere fuer drei von ihnen falsch (dieselbe
    -- Ueberlegung wie im wowsims-Zweig darueber).
    --------------------------------------------------

    local text, missing, written = QE.Export()

    local box = CreateFrame("Frame", nil, frame)
    box:SetPoint("TOPLEFT",  frame, "TOPLEFT",  PAD_X, y)
    box:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD_X, y)
    box:SetHeight(56)

    local ok   = text ~= nil and (type(missing) ~= "table" or #missing == 0)
    local tone = ok and C.green or C.gold

    SetSolidBg(box, tone[1], tone[2], tone[3], 0.10)
    DrawBorder(box, tone[1], tone[2], tone[3], 0.45, 1)

    local head = Text(box, 12, true)
    head:SetPoint("TOPLEFT", box, "TOPLEFT", 12, -10)
    head:SetTextColor(unpack(ok and C.green or C.goldBright))

    local body = Text(box, 10)
    body:SetPoint("TOPLEFT",  box, "TOPLEFT",  12, -30)
    body:SetPoint("TOPRIGHT", box, "TOPRIGHT", -12, -30)
    body:SetSpacing(2)
    body:SetTextColor(unpack(C.textDim))

    if not text then
        head:SetText("Der Text lässt sich gerade nicht bauen")
        -- `missing` traegt hier den Grund: QE.Export gibt im Fehlerfall
        -- nil samt Begruendung zurueck.
        body:SetText(tostring(missing or "Unbekannter Grund.")
            .. " Über /wc qe prüfen steht jede Zwischenzahl im Chat.")
    elseif #missing > 0 then
        head:SetText("Ein paar Gegenstände fehlen noch")
        body:SetText(("%d von %d gelesen. Für %s hat der Client die "
            .. "Grunddaten noch nicht — kurz warten und die Seite erneut "
            .. "öffnen."):format(written, written + #missing,
                table.concat(missing, ", ")))
    else
        head:SetText(("%d Gegenstände gelesen"):format(written))
        body:SetText(("Für %s. Steine, Verzauberungen und "
            .. "Aufwertungsstufen sind dabei."):format(
                tostring(entry.label or profileKey)))
    end

    y = y - 66

    --------------------------------------------------
    -- Das Kopierfeld
    --
    -- Es ist beschreibbar, weil sich aus einem gesperrten Feld in WoW
    -- nichts kopieren laesst; was hineingetippt wird, wird sofort
    -- zurueckgesetzt. Ein Feld, das den Text unter den Fingern des
    -- Nutzers verliert, sieht aus wie ein Fehler.
    --------------------------------------------------

    if text then
        local FIELD_H = 132

        local scroll = CreateFrame("ScrollFrame", nil, frame)
        scroll:SetPoint("TOPLEFT",  frame, "TOPLEFT",  PAD_X, y)
        scroll:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD_X, y)
        scroll:SetHeight(FIELD_H)

        SetSolidBg(scroll, C.surface2[1], C.surface2[2], C.surface2[3], 0.95)
        DrawBorder(scroll, C.borderStrong[1], C.borderStrong[2],
            C.borderStrong[3], 1.0, 1)

        local edit = CreateFrame("EditBox", nil, scroll)
        edit:SetMultiLine(true)
        edit:SetAutoFocus(false)
        edit:SetFont(F.mono or F.sans, 10, "")
        edit:SetWidth(1)   -- wird unten an den Rahmen angepasst
        edit:SetTextInsets(8, 8, 6, 6)
        edit:SetText(text)
        edit:SetCursorPosition(0)
        edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        edit:SetScript("OnTextChanged", function(self, byUser)
            if byUser and self:GetText() ~= text then
                self:SetText(text)
                self:HighlightText()
            end
        end)

        scroll:SetScrollChild(edit)
        scroll:EnableMouseWheel(true)
        scroll:SetScript("OnMouseWheel", function(self, delta)
            local range = self:GetVerticalScrollRange() or 0
            if range <= 0 then return end
            local target = (self:GetVerticalScroll() or 0) - (delta * 24)
            if target < 0 then target = 0 elseif target > range then target = range end
            self:SetVerticalScroll(target)
        end)

        -- Die Breite kommt erst, wenn der Rahmen sie kennt: er haengt an
        -- beiden Kanten, und eine zur Bauzeit gemessene Zahl waere die,
        -- die der Detailbereich gleich wieder verschiebt.
        scroll:SetScript("OnSizeChanged", function(self, width)
            if width and width > 20 then edit:SetWidth(width - 16) end
        end)
        local width = scroll:GetWidth()
        if width and width > 20 then edit:SetWidth(width - 16) end

        y = y - FIELD_H - 10

        local mark = WeintCodex.CreateButton(frame, {
            text = "Text markieren",
            kind = "primary",
            height = 32,
            tooltip = "Markiert den ganzen Text — danach Strg+C. "
                .. "Auch über /wc qe.",
            onClick = function()
                edit:SetFocus()
                edit:HighlightText()
            end,
        })
        mark:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD_X, y)

        y = y - 42
    end

    --------------------------------------------------
    -- Was QE Live NICHT zurueckgibt
    --
    -- Der Satz muss dastehen. Wer von den Schadensausteilern kommt,
    -- erwartet nach dem Sim eine Gewichtung im Spiel — und sucht sonst
    -- eine Funktion, die es nicht gibt.
    --------------------------------------------------

    y = Paragraph(frame, y, 9, C.textFaint,
        "QE Live gibt keine Wertegewichte zu deinem Charakter heraus — "
        .. "sein Top Gear antwortet mit einem Ausrüstungssatz. Was es je "
        .. "Spezialisierung an Gewichten führt, liegt unter "
        .. WeintCodex.ColorText("textDim", "Priorisierung")
        .. " als Vorschlag bereit."
        .. (entry.beta and " Diese Spezialisierung führt QE Live selbst "
            .. "noch als Beta." or ""))
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

    -- Die Weiche. Fuehrt QE Live diese Spezialisierung, ist der Weg ein
    -- anderer — siehe der Kommentar ueber HealerPage.
    local QE = WeintCodex.QELive
    local profileKey = WeintCodex.Charakter
        and WeintCodex.Charakter.GetProfileKey
        and WeintCodex.Charakter.GetProfileKey()
    local healer = QE and QE.Entry and QE.Entry(profileKey)

    if healer then
        HealerPage(pageFrame, profileKey, healer)
        pageFrame:Show()
        return
    end

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
        .. "Ausrüstung. Dort erst auf das Zahnrad neben "
        .. WeintCodex.ColorText("textNormal", "Suggest Reforges") .. " und "
        .. WeintCodex.ColorText("textNormal", "Include gems") .. " anhaken —"
        .. " ohne den Haken rechnet der Sim nur die Umschmiedungen und lässt"
        .. " deine Steine so, wie sie sind. Dann Suggest Reforges.\n"
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

    -- Ein offener Lauf faerbt den Kasten nicht um; er bekommt eine
    -- eigene Zeile darunter. Der Kasten beantwortet "sieht die Companion
    -- meine Ausruestung", der Lauf "kommt da noch was zurueck" - zwei
    -- Fragen, und die zweite ist keine Stoerung der ersten.
    local awaitingAge = SE.AwaitingFor()

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

    if awaitingAge then
        y = Paragraph(pageFrame, y, 10, C.gold,
            "Ein Sim-Lauf ist offen: du hast "
            .. SE.Ago(tonumber(AwaitStore().awaitingAt))
            .. " bereitgestellt. Was du in WeintCompanion uebernommen hast, "
            .. "kommt beim naechsten Neuladen an — oder sofort, wenn du den "
            .. "String dort kopierst und hier unter Import einfuegst.")
        y = y - 6
    end

    -- WAS ZULETZT ANKAM. Ohne diese Zeile ist "der Sim-Lauf ist offen"
    -- die einzige Auskunft der Seite ueber den Rueckweg - und sie steht
    -- auch dann da, wenn laengst etwas eingetroffen ist, das nur nicht
    -- zu diesem Lauf gehoerte.
    local last = SE.LastRun()

    if last and (last.id or "") ~= "" then
        y = Paragraph(pageFrame, y, 9, C.textDim,
            "Zuletzt angekommen: " .. last.id .. " · "
            .. ((last.weights and last.target)
                and "Gewichtung und Zielausruestung"
                or (last.target and "nur die Zielausruestung"
                    or "nur die Gewichtung"))
            .. " · " .. SE.Ago(last.at))
        y = y - 6
    end

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
-- Der Kasten, der nach dem Sim-Lauf fragt
--------------------------------------------------
-- Drei Ausgaenge, weil es drei Lagen gibt, und keine davon ist die
-- Vorgabe fuer alle:
--
--   Neu laden       die Companion hat zugestellt, das Spiel muss es nur
--                   noch lesen. Der bequeme Weg, wenn man nicht gerade
--                   im Raid steht.
--   String einfuegen  die Zwischenablage haelt das Ergebnis. Wirkt
--                   sofort, ohne Ladebildschirm — der einzige Weg, der
--                   mitten in einer Gruppe geht.
--   Spaeter         nichts davon. Der Lauf gilt als erledigt und wird
--                   nicht erneut angeboten; ein Kasten, der wiederkommt,
--                   ist eine Aufforderung und keine Auskunft.

local awaitPanel = nil

-- DIE HOEHE STEHT ERST FEST, WENN DER TEXT DRIN IST (seit 3.2.0.2).
--
-- Der Kasten hatte eine FESTE Hoehe (168 px). Der einzige veraenderliche
-- Teil ist der Absatz (`_sub`) - er traegt zwei Saetze und bricht bei
-- 268 px Breite auf mehrere Zeilen um. Reichte die feste Hoehe nicht,
-- rutschten die drei Knoepfe darunter (jeder am unteren Rand des
-- vorigen verankert) unter die sichtbare Kante der gezeichneten
-- Flaeche - sie waren weiterhin da und klickbar, sahen aber aus, als
-- haetten sie das Fenster verlassen. Gemeldet als Screenshot: "Jetzt
-- neu laden" stand noch im Kasten, "Ich habe den String" und "Später"
-- schon ausserhalb.
--
-- Dieselbe Lehre wie bei den Zeilen im Bestaetigungsfenster
-- (TG.ShowConfirm/ConfirmRow): eine Hoehe, die VOR dem Text feststeht,
-- ist eine Vermutung. AWAIT_HEAD/AWAIT_TAIL sind der Platz vor bzw.
-- nach diesem einen Absatz - fest, weil "WeintCodex" und "Dein
-- Sim-Ergebnis" feste Zeichenketten sind und die drei Knopfhoehen
-- (28/26/22) explizit gesetzt sind. Grosszuegig gerundet: lieber ein
-- paar Pixel Luft am unteren Rand als abgeschnittene Knoepfe.
local AWAIT_HEAD = 62   -- Rand, "WeintCodex", Abstand, Titel, Abstand bis zum Absatz
local AWAIT_TAIL = 118  -- Abstand + drei Knoepfe (28+26+22) + ihre Abstaende + unterer Rand

local function BuildAwaitPanel()
    local f = WeintCodex.CreateSurface(UIParent, {
        width = 300, height = AWAIT_HEAD + AWAIT_TAIL, tone = "plain",
        radius = 12, backdrop = "bgDark",
    })
    f:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -24, 180)
    f:SetFrameStrata("HIGH")
    f:Hide()

    local eyebrow = WeintCodex.Eyebrow(f, "WeintCodex")
    eyebrow:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -14)

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont(F.sansBold, 15, "")
    title:SetPoint("TOPLEFT", eyebrow, "BOTTOMLEFT", 0, -4)
    title:SetTextColor(unpack(C.textBright))
    title:SetText("Dein Sim-Ergebnis")

    local sub = WeintCodex.Label(f, "", { color = "textMuted", size = 11 })
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    sub:SetWidth(268)
    sub:SetJustifyH("LEFT")
    f._sub = sub

    local reload = WeintCodex.CreateButton(f, {
        text = "Jetzt neu laden", kind = "primary", width = 268, height = 28,
        tooltip = "Liest, was WeintCompanion zugestellt hat. "
            .. "Im Kampf geht das nicht.",
        onClick = function()
            if InCombatLockdown() then
                Say("Im Kampf wird nicht neu geladen. Danach noch einmal.")
                return
            end
            AwaitStore().awaitingAt = nil
            f:Hide()
            ReloadUI()
        end,
    })
    reload:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -10)

    local paste = WeintCodex.CreateButton(f, {
        text = "Ich habe den String", kind = "secondary", width = 268, height = 26,
        tooltip = "Oeffnet das Importfeld. Ein eingefuegter String wirkt "
            .. "sofort, ohne Neuladen — auch mitten in einer Gruppe.",
        onClick = function()
            AwaitStore().awaitingAt = nil
            f:Hide()
            if WeintCodex.MainFrame then WeintCodex.MainFrame:Show() end
            if WeintCodex.Sync and WeintCodex.Sync.ShowImportDialog then
                WeintCodex.Sync.ShowImportDialog()
            end
        end,
    })
    paste:SetPoint("TOPLEFT", reload, "BOTTOMLEFT", 0, -6)

    local later = WeintCodex.CreateButton(f, {
        text = "Später", kind = "ghost", width = 268, height = 22,
        onClick = function()
            AwaitStore().awaitingAt = nil
            f:Hide()
        end,
    })
    later:SetPoint("TOPLEFT", paste, "BOTTOMLEFT", 0, -6)

    return f
end

function SE.HideAwaitPanel()
    if awaitPanel then awaitPanel:Hide() end
end

function SE.ShowAwaitPanel()
    if not SE.AwaitingFor() then return end
    if not (WeintCodex.CreateSurface and WeintCodex.CreateButton) then return end

    awaitPanel = awaitPanel or BuildAwaitPanel()
    if not awaitPanel then return end

    awaitPanel._sub:SetText(
        "Du hast deine Ausrüstung "
        .. SE.Ago(tonumber(AwaitStore().awaitingAt))
        .. " für den Sim bereitgestellt.\n\n"
        .. "Ist das Ergebnis in WeintCompanion übernommen, liegt es bereit — "
        .. "das Spiel liest es beim nächsten Neuladen.")

    -- Gemessen NACH dem Text und VOR dem Zeigen - siehe AWAIT_HEAD/
    -- AWAIT_TAIL oben. `GetStringHeight()` gibt die tatsaechlich
    -- umgebrochene Hoehe zurueck, nicht die ungebrochene Zeile.
    local textHeight = awaitPanel._sub.GetStringHeight
        and awaitPanel._sub:GetStringHeight() or 0
    awaitPanel:SetHeight(AWAIT_HEAD + textHeight + AWAIT_TAIL)

    awaitPanel:Show()
end

-- Nach dem Bereitstellen folgt sofort ein Neuladen; die Uhr laeuft
-- deshalb ab dem Anmelden. Nachgesehen wird EINMAL, spaet genug, dass
-- ProcessInbox laengst durch ist: kam etwas an, hat NoteArrival den
-- Wartezustand da schon geloescht, und der Kasten bleibt weg.
local function ScheduleAwaitCheck()
    if not SE.AwaitingFor() then return end
    if not (C_Timer and C_Timer.After) then return end

    C_Timer.After(AWAIT_DELAY, function()
        SE.ShowAwaitPanel()
    end)
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
        local age = SE.AwaitingFor()
        Say("  Offener Sim-Lauf: " .. (age
            and (SE.Ago(tonumber(AwaitStore().awaitingAt)) .. " bereitgestellt")
            or "keiner"))

        -- Was zuletzt ankam, und ob es der erwartete Lauf war. Von
        -- aussen sehen "es kam nichts an", "es kam der falsche an" und
        -- "es kam an, aber halb" voellig gleich aus.
        local last = SE.LastRun()
        if last then
            Say(("  Zuletzt angekommen: %s (%s), %s"):format(
                last.id or "?",
                (last.weights and "Gewichtung" or "-")
                    .. (last.target and " + Zielausruestung" or ""),
                SE.Ago(last.at)))
            Say("    Ausruestung dieses Laufs: " .. SE.Ago(last.startedAt))
        else
            Say("  Zuletzt angekommen: nichts mit Lauf-Kennung")
        end
        return
    end

    -- Den Kasten von Hand holen. Ohne diesen Weg liesse sich nur
    -- nachweisen, DASS ein Lauf offen ist, nicht wie die Frage aussieht.
    if rest == "warten" or rest == "frage" then
        if not SE.AwaitingFor() then
            Say("Gerade ist kein Sim-Lauf offen — der Kasten hat nichts zu fragen.")
            return
        end
        SE.ShowAwaitPanel()
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

    ScheduleAwaitCheck()
end)
