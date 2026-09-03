WeintCodex = WeintCodex or {}
WeintCodex.Companion = {}

----------------------------------------------------------
-- Nachrichtentypen
----------------------------------------------------------

local STATE_MESSAGES = {

    materials = true,
    character = true,
    calendar  = true,
    academy   = true,

    -- Wer ist gerade angemeldet? Immer nur der letzte Stand.
    character_report = true,

    -- Ausruestungsstand des angemeldeten Charakters. Ebenfalls nur der
    -- letzte Stand: die Companion sammelt die Twinks ueber die Zeit
    -- auf ihrer Seite ein, hier liegt immer nur der aktuelle.
    character_sheet = true,

    -- Welche WeakAuras dieses Addon kennt. Eine Liste, kein Ereignis -
    -- es zaehlt nur, was gerade drin ist.
    weakaura_catalog = true,

}

-- Ausgangsseitige Freigaben: welche Nachrichtenart welche Rolle braucht.
-- "character" (der Bot braucht den echten WoW-Namen fuer Kalender-Invites),
-- "academy" (eigener Lernfortschritt) und "dummy_practice_session" (eigene
-- Uebungsdaten am Trainingsdummy, siehe modules/rotationtrainer.lua) sind
-- absichtlich nicht gelistet.
local FEATURE_BY_MESSAGE = {

    loot      = "loot.report",
    materials = "materials.scan",

}

-- Gebundene Community-ID oder nil. Wird an jede ausgehende Nachricht
-- gestempelt, damit die Desktop-Seite Verkehr einer anderen Community
-- verwerfen kann (siehe core/access.lua).
local function BoundCommunityId()

    if not (WeintCodex.Access and WeintCodex.Access.Community) then return nil end

    local community = WeintCodex.Access.Community()
    if not community then return nil end

    return WeintCodex.Access.NormalizeId(community.id)

end

----------------------------------------------------------
-- Initialisierung
----------------------------------------------------------

local function Initialize()

WeintCompanionDB = WeintCompanionDB or {}

WeintCompanionDB.version =
WeintCompanionDB.version or 1

WeintCompanionDB.lastId =
WeintCompanionDB.lastId or 0

WeintCompanionDB.queue =
WeintCompanionDB.queue or {}

end

----------------------------------------------------------
-- Nachricht senden
----------------------------------------------------------

function WeintCodex.Companion.Send(
    messageType,
    payload
)

Initialize()

------------------------------------------------------
-- Freigabe pruefen
------------------------------------------------------
-- Ein Client ohne die passende Rolle soll nichts Gildeninternes
-- hinausschicken - z. B. keine Gildenbank einer fremden Gilde und
-- keine Loot-Meldungen in unseren Discord. Still, weil "loot" pro
-- Drop feuert; die Begruendung steht in der jeweiligen Oberflaeche.
------------------------------------------------------

local requiredFeature = FEATURE_BY_MESSAGE[messageType]

if requiredFeature and WeintCodex.Access
    and not WeintCodex.Access.Can(requiredFeature) then
    return nil
end

local community = BoundCommunityId()

------------------------------------------------------
-- Zustandsnachrichten ersetzen
------------------------------------------------------

if STATE_MESSAGES[messageType] then

    for _, message in ipairs(
        WeintCompanionDB.queue
    ) do

    if message.type == messageType then

        message.created = time()
        message.version = 1
        message.payload = payload

        -- Auch hier mitfuehren: trifft das Zugriffsprofil zwischen
        -- zwei Sends ein, behielte eine bereits eingereihte
        -- Nachricht sonst eine fehlende oder veraltete ID.
        message.community = community

        print(
            "|cff00ff00WeintCompanion|r: "
            .. messageType ..
            " aktualisiert."
        )

        return message.id

        end

        end

        end

        ------------------------------------------------------
        -- Neue Nachricht
        ------------------------------------------------------

        WeintCompanionDB.lastId =
        WeintCompanionDB.lastId + 1

        local message = {

            id = WeintCompanionDB.lastId,

            version = 1,

            type = messageType,

            created = time(),

            payload = payload,

            community = community,

        }

        table.insert(
            WeintCompanionDB.queue,
            message
        )

        print(
            "|cff00ff00WeintCompanion|r: "
            .. messageType ..
            " zur Warteschlange hinzugefügt."
        )

        return message.id

        end

        ----------------------------------------------------------
        -- Warteschlange
        ----------------------------------------------------------

        function WeintCodex.Companion.GetQueue()

        Initialize()

        return WeintCompanionDB.queue

        end

        ----------------------------------------------------------
        -- Anzahl
        ----------------------------------------------------------

        function WeintCodex.Companion.GetQueueSize()

        Initialize()

        return #WeintCompanionDB.queue

        end

        ----------------------------------------------------------
        -- Nachricht löschen
        ----------------------------------------------------------

        function WeintCodex.Companion.Remove(id)

        Initialize()

        for index, message in ipairs(
            WeintCompanionDB.queue
        ) do

        if message.id == id then

            table.remove(
                WeintCompanionDB.queue,
                index
            )

            return true

            end

            end

            return false

            end

            ----------------------------------------------------------
            -- Warteschlange leeren
            ----------------------------------------------------------

            function WeintCodex.Companion.Clear()

            Initialize()

            wipe(
                WeintCompanionDB.queue
            )

            end

----------------------------------------------------------
-- Inbox (Bot -> Companion -> Addon)
----------------------------------------------------------
-- Gegenrichtung zur obigen Warteschlange: Hier schreibt die
-- Companion-App Nachrichten hinein (z. B. den Raid-Roster-Export,
-- den ein per Discord-Login verknüpfter Raidlead automatisch vom Bot
-- abgerufen hat). ProcessInbox() wird beim Addon-Login aufgerufen
-- (siehe core/main.lua) und reicht jede Nachricht an den bereits
-- bestehenden Import-Parser weiter - identisch zum manuellen
-- Copy-Paste über /wc import, nur automatisch ausgelöst.
----------------------------------------------------------

local function InitializeInbox()

WeintCompanionInboxDB = WeintCompanionInboxDB or {}

WeintCompanionInboxDB.queue =
WeintCompanionInboxDB.queue or {}

end

----------------------------------------------------------
-- Welche Companion-Version schreibt hier?
----------------------------------------------------------
-- WeintCompanion 1.7.0 schreibt companionVersion bei jedem
-- Schreibvorgang in WeintCompanionInboxDB. Wir brauchen die Angabe
-- fuer genau eine Entscheidung: ob wir "character_report" senden
-- duerfen. Eine aeltere Companion kennt den Typ nicht, wuerde ihn an
-- den Bot schicken, dort scheitern, die Nachricht liegen lassen und
-- alle fuenf Sekunden einen Fehler ins Log schreiben.
--
-- Fehlt die Marke, gilt "zu alt" - der Normalfall vor 1.7.0.
--
-- `patch` ist optional und kam mit "character_sheet" dazu: die
-- Nachricht gibt es erst ab Companion 2.0.1, und 2.0.0 war bereits
-- draussen. Ohne die dritte Stelle waere "mindestens 2.0" wahr fuer
-- eine Companion, die den Typ noch nicht kennt - also genau der
-- Fehler, gegen den diese Funktion ueberhaupt existiert.
----------------------------------------------------------

local function CompanionAtLeast(major, minor, patch)

    InitializeInbox()

    -- Die Live-Bruecke (data/companion_live.lua) traegt dieselbe Marke
    -- und ist der verlaesslichere Zeuge: sie steht in einer Datei, die
    -- WoW nur liest. Die Inbox daneben kann ein /reload ueberschrieben
    -- haben, bevor das Addon sie je gesehen hat - dann stuende dort die
    -- Version vom letzten Login statt der laufenden.
    local version

    if type(WeintCodex_CompanionLive) == "table"
        and type(WeintCodex_CompanionLive.companionVersion) == "string"
        and WeintCodex_CompanionLive.companionVersion ~= "" then

        version = WeintCodex_CompanionLive.companionVersion

    else

        version = WeintCompanionInboxDB.companionVersion

    end

    if type(version) ~= "string" then return false end

    local gotMajor, gotMinor = version:match("^v?(%d+)%.(%d+)")
    if not gotMajor then return false end

    gotMajor, gotMinor = tonumber(gotMajor), tonumber(gotMinor)

    if gotMajor ~= major then return gotMajor > major end
    if gotMinor ~= minor then return gotMinor > minor end

    if not patch then return true end

    -- Eine fehlende dritte Stelle ist eine Null ("2.0" = "2.0.0") und
    -- nicht "unbekannt": so schreibt core/version.py drueben es auch.
    local gotPatch = tonumber(version:match("^v?%d+%.%d+%.(%d+)") or 0) or 0

    return gotPatch >= patch

end

----------------------------------------------------------
-- Ablage der Companion-Auswertungen
----------------------------------------------------------
-- Die Nutzlasten landen in WeintCodex.SavedData und bleiben dort
-- liegen. Die Inbox wird beim Login geleert, die Anzeige soll aber
-- auch dann noch etwas zeigen, wenn die Companion gerade nichts
-- Neues geliefert hat.
--
-- Fortschritt (completed/excluded) wird pro Charakter gefuehrt,
-- genau wie in der Companion. Gespeichert werden AUSSCHLUESSE, nicht
-- Einschluesse: eine neu gelieferte Lektion ist damit automatisch
-- aktiv, ohne Migration.
----------------------------------------------------------

-- Schluessel einer Tabelle als Liste - Names.Match braucht eine, um
-- den Charakter unabhaengig von Realmzusatz und Schreibweise zu
-- finden.
local function KeysOf(tbl)
    local keys = {}
    for key in pairs(tbl or {}) do keys[#keys + 1] = key end
    return keys
end

local function AcademyStore()

    WeintCodex.SavedData = WeintCodex.SavedData or {}

    local store = WeintCodex.SavedData.academy or {}
    store.completed = store.completed or {}
    store.excluded  = store.excluded  or {}

    --------------------------------------------------
    -- Auswertungen liegen JE CHARAKTER
    --------------------------------------------------
    -- Bis 1.3.2.3 gab es genau einen Platz fuer Bewertung und
    -- Katalog - kontoweit, fuer alle Charaktere zusammen. Wer auf
    -- einem Twink einloggte, bekam die Bewertung seines Mains
    -- vorgesetzt, mitsamt dessen Namen, Klasse und Trainingsplan. Es
    -- gab keine Stelle, an der das haette auffallen koennen: die
    -- Seite las den Namen aus derselben Nutzlast, die sie anzeigte.
    --
    -- Migration passiert hier und nicht an den Aufrufstellen, damit
    -- jeder Einstiegspunkt sie mitbekommt. Der alte Platz wird
    -- danach entfernt; die Companion liest SavedData.academy nie,
    -- das ist also gefahrlos.
    --------------------------------------------------

    if store.state and not store.states then

        local key = store.state.character

        -- "-" ist der Wert, den eine aeltere Companion schickte, wenn
        -- sie den gewaehlten Spieler im Pull nicht fand. Als
        -- Charaktername ist er unbrauchbar.
        if key == nil or key == "" or key == "-" then
            key = (WeintCodex.Names and WeintCodex.Names.Me()) or UnitName("player")
        end

        if key and key ~= "" then
            store.states   = { [key] = store.state }
            store.catalogs = { [key] = store.catalog }
            store.lastCharacter = key
        end

        store.state, store.catalog = nil, nil

    end

    store.states   = store.states   or {}
    store.catalogs = store.catalogs or {}

    WeintCodex.SavedData.academy = store
    return store

end

WeintCodex.Companion.AcademyStore = AcademyStore

-- Auswertung und Katalog des uebergebenen Charakters. Beide duerfen
-- nil sein - "fuer diesen Charakter liegt nichts vor" ist ein
-- gueltiger Zustand und wird in modules/academy.lua als solcher
-- benannt, statt ersatzweise eine fremde Auswertung zu zeigen.
function WeintCodex.Companion.AcademyStateFor(character)
    local store = AcademyStore()
    local key = WeintCodex.Names.Match(character, KeysOf(store.states))
    return key and store.states[key] or nil
end

function WeintCodex.Companion.AcademyCatalogFor(character)
    local store = AcademyStore()
    local key = WeintCodex.Names.Match(character, KeysOf(store.catalogs))
    return key and store.catalogs[key] or nil
end

-- Fuer wen hat die Companion zuletzt ausgewertet? Das beantwortet die
-- Frage, die der Nutzer vor einer leeren Academy hat: liegt es an der
-- Verbindung oder an der Auswahl auf dem Desktop?
function WeintCodex.Companion.AcademyDeliveredCharacter()
    return AcademyStore().lastCharacter
end

-- Fortschritt-Listen des uebergebenen Charakters (immer eine Tabelle).
function WeintCodex.Companion.AcademyProgress(character)

    local store = AcademyStore()
    character = character or UnitName("player") or "?"

    -- Auf eine bereits vorhandene Schreibweise abbilden. Ohne das
    -- liegen die Haken unter "Aldrin-DieAldor" (so schreibt der
    -- Bericht) und werden unter "Aldrin" (so schreibt der Client)
    -- gesucht - der Fortschritt sieht dann verloren aus.
    character = WeintCodex.Names.Match(character, KeysOf(store.completed))
        or WeintCodex.Names.Match(character, KeysOf(store.excluded))
        or character

    store.completed[character] = store.completed[character] or {}
    store.excluded[character]  = store.excluded[character]  or {}

    return store.completed[character], store.excluded[character]

end

-- Die Uebungsserie am Trainingsdummy fuer eine Spezialisierung.
--
-- Gerechnet wird sie drueben (core/academy_dummy_sync.py) - aus den
-- Sitzungen, die dieses Addon selbst meldet. Sie kommt fertig zurueck,
-- Satz inklusive: welche Sitzung eine Serie fortsetzt, entscheidet die
-- Stelle, die am dritten Tag auch die Lektion abhakt, und eine zweite
-- Rechnung hier stuende irgendwann auf einer anderen Zahl.
--
-- Geschluesselt ist sie ueber den Profilschluessel des Addons
-- ("WARRIOR_ARMS"): welche Spezialisierung gerade gespielt wird, weiss
-- nur der Client - und er weiss es genauer als eine Zustellung vom
-- letzten Login.
--
-- nil heisst "dazu liegt nichts vor" und wird als solches benannt,
-- nicht als "noch nie geuebt".
function WeintCodex.Companion.AcademyPracticeFor(character, specKey)

    if not specKey or specKey == "" then return nil end

    local state = WeintCodex.Companion.AcademyStateFor(
        character or (WeintCodex.Names and WeintCodex.Names.Me()) or "")

    for _, entry in ipairs(state and state.practice or {}) do
        if entry.specKey == specKey then return entry end
    end

    return nil

end

----------------------------------------------------------
-- Inbox (Bot/Companion -> Addon): Nachrichtentypen
----------------------------------------------------------
-- raid_import      payload = WCIMPORT-String (siehe modules/sync.lua)
--
-- Die folgenden vier erwarten eine TABELLE als payload, keinen String:
--
-- access_profile   { community = { id = "<Discord-Guild-ID>", name },
--                    identity  = { discordId, discordName },
--                    tier, tierLabel, roles = {...},
--                    features  = { ["raids.view"] = true, ... },
--                    issuedAt, expiresAt, companionVersion, notice }
--                  Das vollstaendige Schema und die Bindungsregeln stehen im
--                  Kopf von core/access.lua. Diese Nachricht bindet das Addon
--                  an eine Community und steuert alle Freigaben.
--
-- academy_catalog  { categories = { { id, label, hint }, ... },
--                    lessons    = { { id, title, category, summary,
--                                     steps = {...}, class, spec,
--                                     encounter, roles = {...} }, ... } }
--
-- academy_state    { character, encounter, pull, source, capturedAt,
--                    hasActor,
--                    actor   = { name, class, spec, role },
--                    ratings = { { category, stars, detail, metric, at }, ... },
--                    plan    = { "<lessonId>", ... },
--                    results = { ["<lessonId>"] = { status, at,
--                                  checks = { { status, detail }, ... } } },
--                    completed = { "<lessonId>", ... },
--                    excluded  = { "<lessonId>", ... },
--                    gap = "" | "no_raid" | "no_pull" | "sums_only",
--                    gapText   = "<Satz>",
--                    note      = "<Satz zum Profil>",
--                    planNote  = "<warum der Plan so sortiert ist>",
--                    progress  = { pulls, text, points = {...},
--                                  first, last, direction,
--                                  area = { category, label,
--                                           points = {...}, text } },
--                    practice  = { { specKey, lessonId, streak, target,
--                                    missing, alive, practicedToday,
--                                    done, lastDate, text }, ... } }
--
--                  Die letzten fuenf Felder gibt es seit WeintCompanion
--                  2.8.0 und sie sind additiv: eine aeltere Companion
--                  schickt sie nicht, und dann sagt die Seite dazu
--                  nichts, statt etwas zu behaupten.
--
--                  KEINES davon wird hier nachgerechnet. Die Kurve, die
--                  Begruendung des Plans, der Grund fuer eine leere
--                  Auswertung und die Uebungsserie am Trainingsdummy
--                  entstehen alle drueben - eine zweite Fassung
--                  derselben Aussage liefe irgendwann anders aus, und
--                  dann widerspraechen sich Spiel und Desktop.
--
-- weinttv_report   { capturedAt, source, pull, duration, bossHealth, kill,
--                    hasAnalysis, gap, me,
--                    encounter   = { name, instance, difficulty, size },
--                    damageTaken, uptimes, activity, movement, cooldowns,
--                    support, mechanics, consumables, warnings }
--                  (Zeilenschemata siehe modules/weinttv.lua)
--
-- stat_weights    { version = 1,
--                    sets = { { id, spec, weights = { crit = 58, ... },
--                               character, realm, source, created }, ... } }
--                  Wertegewichte aus einem Sim, vom Schreibtisch geschickt
--                  (WeintCompanion 2.5.0). Es ist ein VORSCHLAG und keine
--                  Einstellung: er fuellt die Felder auf *Priorisierung*
--                  und wird erst auf Klick wirksam. Zugestellt wird immer
--                  die ganze Liste, also verschwindet eine geloeschte
--                  Gewichtung dadurch, dass sie fehlt. Die Grenzen aus dem
--                  Sim sind bewusst NICHT dabei - sie gelten fuer jeden
--                  gleich und stehen in data/spec_profiles.lua.
--
-- Zwei Konventionen aus der Companion gelten hier genauso:
--   stars == 0  heisst "keine Daten", nicht "schlecht"
--   at    == -1 heisst "kein Zeitpunkt bekannt"
--
-- Jede Nachricht darf zusaetzlich ein message.community (Zeichenkette) auf
-- der Huelle tragen. Weicht es von der Bindung ab, wird die Nachricht
-- verworfen statt eingearbeitet - fuer access_profile wird das Feld
-- ignoriert, dort ist die Nutzlast maßgeblich.
--
-- Ausgehend traegt jede Nachricht in WeintCompanionDB.queue umgekehrt ein
-- community-Feld mit der gebundenen ID.
----------------------------------------------------------

-- Liste von Lektions-IDs in eine Nachschlagetabelle drehen.
local function IdSet(list)

    local set = {}

    if type(list) == "table" then
        for _, id in ipairs(list) do
            if type(id) == "string" then set[id] = true end
        end
    end

    return set

end

local INBOX_HANDLERS = {}

INBOX_HANDLERS.access_profile = function(payload)

    if type(payload) ~= "table" then return end

    if WeintCodex.Access and WeintCodex.Access.ApplyProfile then
        WeintCodex.Access.ApplyProfile(payload)
    end

end

INBOX_HANDLERS.raid_import = function(payload)

    if type(payload) ~= "string" then return end

    if WeintCodex.Sync and WeintCodex.Sync.QuickImport then
        WeintCodex.Sync.QuickImport(payload)
    end

end

--
-- Der Katalog traegt selbst KEINEN Charakter - ihm eins zu geben
-- waere ein neuer versionsuebergreifender Vertrag ohne Gegenwert.
-- Stattdessen wird er zwischengelegt und von der unmittelbar
-- folgenden academy_state-Nachricht uebernommen.
--
-- ACHTUNG, unsichtbare Kopplung: das traegt nur, weil
-- core/addon_analysis_sync.py der Companion Katalog VOR Zustand in
-- einer geordneten Liste veroeffentlicht und AddonInbox die
-- Reihenfolge innerhalb eines Kanals erhaelt. Wer dort die
-- Reihenfolge aendert, landet hier bei Katalogen ohne Besitzer.
--
INBOX_HANDLERS.academy_catalog = function(payload)

    if type(payload) ~= "table" then return end

    local store = AcademyStore()
    store.pendingCatalog = payload

end

INBOX_HANDLERS.academy_state = function(payload)

    if type(payload) ~= "table" then return end

    local store = AcademyStore()

    -- "-" schickte eine aeltere Companion, wenn sie den gewaehlten
    -- Spieler im Pull nicht fand. Unbeschriftet heisst: gehoert dem,
    -- der gerade spielt - eine alte Companion kennt ohnehin nur einen
    -- Charakter.
    local key = payload.character
    if key == nil or key == "" or key == "-" then
        key = WeintCodex.Names.Me()
    end

    if key == "" then
        store.pendingCatalog = nil
        return
    end

    -- Unter der Schreibweise ablegen, die schon da ist - sonst
    -- entstuenden "Aldrin" und "Aldrin-DieAldor" als zwei Charaktere.
    key = WeintCodex.Names.Match(key, KeysOf(store.states)) or key

    store.states[key] = payload

    if store.pendingCatalog then
        store.catalogs[key] = store.pendingCatalog
        store.pendingCatalog = nil
    end

    store.lastCharacter = key

    -- Fortschritt vom Desktop uebernehmen. Die Companion ist beim Login
    -- die juengere Quelle: sie hat die Auswertung gerade erst erzeugt,
    -- waehrend die Addon-Seite seit dem letzten Ausloggen unveraendert
    -- ist. Ingame gesetzte Haken gehen ueber die Ausgangs-Warteschlange
    -- zurueck (siehe SendAcademyProgress).
    --
    -- Derselbe aufgeloeste Schluessel wie oben: frueher stand hier
    -- payload.character roh, sodass der Fortschritt unter einem
    -- anderen Namen landete als die Bewertung und die Haken beim
    -- naechsten Login verschwunden schienen.
    if payload.completed then
        store.completed[key] = IdSet(payload.completed)
    end
    if payload.excluded then
        store.excluded[key] = IdSet(payload.excluded)
    end

end

-- Gelieferte Auswertungen verwerfen, ohne den eigenen Lernfortschritt
-- anzutasten. Genutzt von /wc access reset (core/access.lua): die
-- Bewertungen stammen aus den Raids der alten Community und muessen
-- gehen, die selbst gesetzten Haken sind eigene Daten und bleiben.
function WeintCodex.Companion.ResetDeliveredAnalysis()

    local store = AcademyStore()

    store.states         = {}
    store.catalogs       = {}
    store.lastCharacter  = nil
    store.pendingCatalog = nil
    store.state, store.catalog = nil, nil

end

INBOX_HANDLERS.weinttv_report = function(payload)

    if type(payload) ~= "table" then return end

    WeintCodex.SavedData = WeintCodex.SavedData or {}
    WeintCodex.SavedData.weinttv = payload

end

--
-- WeakAuras, in der Companion eingetragen
--
-- Die Nachricht traegt die GANZE Bibliothek, nicht einzelne Auren.
-- Das ist der Unterschied, an dem es haengt: eine Aura, die in der
-- Companion geloescht wurde, ist hier sonst nicht loeschbar - eine
-- Einzelnachricht kann "es gibt mich nicht mehr" nicht ausdruecken,
-- und die Inbox wird bei jedem Login geleert. Die Companion fuehrt
-- die Liste, das Addon uebernimmt sie.
--
-- Nutzlast (siehe docs/weakaura-bridge.md drueben):
--
--   { version = 1, updatedAt = <unix>, auras = { {
--       id, name, category, description, version, author,
--       icon, class, string, updatedAt
--   }, ... } }
--
-- Geprueft wird hier nur das Grobe. Welche Zeile brauchbar ist,
-- entscheidet modules/weakauras.lua beim Zusammenfuehren - dort
-- steht auch, was passiert, wenn eine ID schon vergeben ist.
--
INBOX_HANDLERS.weakaura_library = function(payload)

    if type(payload) ~= "table" then return end

    if type(payload.auras) ~= "table" then return end

    WeintCodex.SavedData = WeintCodex.SavedData or {}
    WeintCodex.SavedData.weakAuraLibrary = payload

    if WeintCodex.WeakAuras and WeintCodex.WeakAuras.Refresh then
        WeintCodex.WeakAuras.Refresh()
    end

end

--
-- Die Gewichtungen aus einem Sim. Sie werden HINGELEGT, nicht angewendet
-- - siehe der lange Kommentar bei SW.Offer in modules/statweights.lua.
-- Der ganze Vorgang haengt am Gedaechtnis dort: dieselbe Liste kommt bei
-- jedem Login erneut, und ohne das stuende ein gestern uebernommener
-- Vorschlag heute wieder da.
--
INBOX_HANDLERS.stat_weights = function(payload)

    if type(payload) ~= "table" then return end
    if type(payload.sets) ~= "table" then return end

    local SW = WeintCodex.StatWeights
    if not (SW and SW.Offer) then return end

    -- Was hier nicht mehr steht, gibt es nicht mehr: die Companion
    -- schickt immer alles, eine Einzelnachricht koennte "es gibt mich
    -- nicht mehr" gar nicht ausdruecken. Erledigte Vorschlaege bleiben
    -- erledigt (SW.Offer sieht in `seen` nach), offene, die nicht mehr
    -- geliefert werden, verschwinden.
    local store = SW.Store()
    local delivered = {}

    local fresh = 0

    for _, entry in ipairs(payload.sets) do
        local ok, _, clean = SW.Offer(entry)
        if clean then delivered[clean.spec] = true end
        if ok then fresh = fresh + 1 end
    end

    for spec in pairs(store.pending) do
        if not delivered[spec] then store.pending[spec] = nil end
    end

    if fresh > 0 then
        -- Gesagt wird es genau einmal und mit dem Weg dorthin: ein
        -- Vorschlag, den niemand findet, ist keiner. Der Text steht
        -- absichtlich nicht in statweights.lua - die Datei zerlegt und
        -- rechnet, sie redet nicht.
        print(WeintCodex.ColorText("gold", "[WeintCodex]")
            .. " Aus der Companion " .. (fresh == 1
                and "liegt eine Sim-Gewichtung"
                or  ("liegen " .. fresh .. " Sim-Gewichtungen"))
            .. " bereit. |cff4A4A52Charakter -> Priorisierung|r"
            .. " – dort ansehen und uebernehmen.")
    end

end

local function Dispatch(message)

    local handler = INBOX_HANDLERS[message.type]

    -- Eine fehlerhafte Nachricht darf die restliche Warteschlange
    -- nicht mitreissen: sonst bliebe z.B. der Raid-Import liegen,
    -- weil die Auswertung davor ein Feld anders benannt hat.
    local ok, err = pcall(handler, message.payload)
    if not ok then
        print(WeintCodex.ColorText("danger", "[WeintCodex]")
            .. " Companion-Nachricht \"" .. tostring(message.type)
            .. "\" konnte nicht verarbeitet werden: " .. tostring(err))
    end

end

----------------------------------------------------------
-- Zwei Quellen, eine Warteschlange
----------------------------------------------------------
-- WeintCompanionInboxDB ist eine SavedVariable, und das ist genau
-- ihr Problem: WoW schreibt SavedVariables bei /reload und beim
-- Abmelden aus dem Arbeitsspeicher zurueck und liest sie erst
-- danach wieder ein. Was die Companion waehrend der laufenden
-- Sitzung hineingeschrieben hat, wird von diesem Rueckschreiben
-- geloescht, bevor das Addon es sehen kann. Ein /reload konnte
-- deshalb nie neue Daten holen - und weil die Companion sich merkt,
-- was sie zuletzt zugestellt hat, kam ein unveraenderter Roster
-- danach auch kein zweites Mal.
--
-- Die Live-Bruecke (data/companion_live.lua, von der Companion
-- geschrieben) hat das Problem nicht: WoW fuehrt Addon-Dateien bei
-- jedem /reload neu aus und schreibt sie nie zurueck.
--
-- Beide Quellen tragen dieselben Nachrichtentypen. Liegt eine
-- Live-Zustellung vor, gilt sie - sie ist per Konstruktion der
-- juengere Stand, die Inbox daneben hoechstens gleich alt. Fehlt
-- sie (aeltere Companion, Addon frisch entpackt), bleibt es beim
-- bisherigen Weg.
--
-- Das Addon kann die Live-Datei nicht leeren - es schreibt keine
-- Dateien. Deshalb merkt es sich den Stand, den es zuletzt
-- eingearbeitet hat, und laesst eine unveraenderte Zustellung beim
-- naechsten /reload still liegen. Sonst meldete jeder Reload
-- denselben Import erneut im Chat.
----------------------------------------------------------

local function LiveDelivery()

    local live = WeintCodex_CompanionLive

    if type(live) ~= "table" then return nil end
    if type(live.queue) ~= "table" then return nil end
    if #live.queue == 0 then return nil end

    return live

end

function WeintCodex.Companion.LiveInfo()

    local live = LiveDelivery()

    if not live then return nil end

    return {
        writtenAt = tonumber(live.writtenAt) or 0,
        version   = live.companionVersion,
        count     = #live.queue,
    }

end

-- Nach einem "Loeschen" der Raiddaten soll dieselbe Zustellung beim
-- naechsten /reload wieder eingearbeitet werden - sonst waere sie
-- unerreichbar, bis die Companion von sich aus etwas Neues schickt.
function WeintCodex.Companion.ForgetLiveStamp()

    WeintCodex.SavedData = WeintCodex.SavedData or {}
    WeintCodex.SavedData.companionLive =
        WeintCodex.SavedData.companionLive or {}
    WeintCodex.SavedData.companionLive.lastStamp = nil

end

----------------------------------------------------------
-- Eine Warteschlange einarbeiten
----------------------------------------------------------

local function ProcessQueue(queue)

------------------------------------------------------
-- 1. Durchgang: nur Zugriffsprofile
------------------------------------------------------
-- Muss vor allem anderen laufen. Sonst wuerde beim erstmaligen
-- Verknuepfen genau der Schwung Daten noch durchrutschen, den das
-- gelieferte Profil eigentlich sperrt. Mehrere Profile werden in
-- Warteschlangen-Reihenfolge angewandt, das letzte gewinnt.
------------------------------------------------------

for _, message in ipairs(queue) do

    if message.type == "access_profile" and message.payload ~= nil then
        Dispatch(message)
    end

end

------------------------------------------------------
-- 2. Durchgang: alles andere, mit Herkunftspruefung
------------------------------------------------------

local rejected = 0

for _, message in ipairs(queue) do

    if message.type ~= "access_profile"
        and INBOX_HANDLERS[message.type]
        and message.payload ~= nil then

        if WeintCodex.Access and WeintCodex.Access.IsForeign(message.community) then

            rejected = rejected + 1
            WeintCodex.Access.NoteRejection(message.community)

        else

            Dispatch(message)

        end

    end

end

-- Eine gesammelte Warnung, nicht eine pro Nachricht.
if rejected > 0 then
    print(WeintCodex.ColorText("warning", "[WeintCodex]") .. " "
        .. string.format(WeintCodex.Access.MSG_FOREIGN_INBOX,
            rejected, WeintCodex.Access.CommunityName()))
end

end

function WeintCodex.Companion.ProcessInbox()

InitializeInbox()

WeintCodex.SavedData = WeintCodex.SavedData or {}
WeintCodex.SavedData.companionLive =
    WeintCodex.SavedData.companionLive or {}

local marker = WeintCodex.SavedData.companionLive
local live   = LiveDelivery()

------------------------------------------------------
-- Was ist einzuarbeiten?
------------------------------------------------------
-- Beide Quellen tragen dieselbe Zustellung; die Companion schreibt
-- sie aus derselben Liste. Trotzdem wird hier nicht die eine gegen
-- die andere ausgespielt, sondern zusammengefuehrt: die Live-Datei
-- kann fehlschlagen (Addon-Ordner verschoben, Rechte), waehrend die
-- Inbox geschrieben wurde. Die Inbox dann ungelesen zu leeren, weil
-- "die Live-Datei ist ja da", wuerde genau in diesem Fall eine
-- Zustellung wegwerfen.
--
-- Doppelt gemeldet wird deshalb trotzdem nichts: eine Nachricht mit
-- gleicher Zeichenketten-Nutzlast, die schon aus der Live-Zustellung
-- kam, wird uebersprungen. Nur die tragen eine Chatmeldung
-- (raid_import); die Tabellen-Nutzlasten schreiben still einen
-- Zustand und duerfen ruhig zweimal laufen - dann gewinnt die Inbox,
-- weil sie zuletzt laeuft, und das ist die sichere Richtung.
------------------------------------------------------

local queue = {}
local seen  = {}

if live then

    local stamp = tonumber(live.writtenAt) or 0
    local isNew = (stamp == 0) or (stamp ~= marker.lastStamp)

    for _, message in ipairs(live.queue) do

        if type(message.payload) == "string" then
            seen[tostring(message.type) .. "\1"
                .. tostring(message.community) .. "\1"
                .. message.payload] = true
        end

        -- Ein unveraenderter Stand wird nicht erneut eingearbeitet.
        -- Das Addon kann die Datei nicht leeren, sie liegt also bei
        -- jedem /reload wieder da - ohne diese Marke meldete jeder
        -- Reload denselben Import erneut.
        if isNew then
            queue[#queue + 1] = message
        end

    end

    if isNew then
        marker.lastStamp   = stamp
        marker.lastCount   = #live.queue
        marker.lastVersion = live.companionVersion
    end

end

for _, message in ipairs(WeintCompanionInboxDB.queue) do

    local fingerprint

    if type(message.payload) == "string" then
        fingerprint = tostring(message.type) .. "\1"
            .. tostring(message.community) .. "\1"
            .. message.payload
    end

    if not (fingerprint and seen[fingerprint]) then
        queue[#queue + 1] = message
    end

end

-- Die Inbox wird in jedem Fall geleert. Sie liegt zu lassen hiesse
-- dieselbe Warnung bei jedem Login - und schlimmer: nach einem
-- legitimen /wc access reset wuerden wochenalte Roster der
-- vorherigen Community ploetzlich angenommen.
wipe(WeintCompanionInboxDB.queue)

if #queue == 0 then
    return
end

ProcessQueue(queue)

end

----------------------------------------------------------
-- Academy-Fortschritt zurueck an die Companion
----------------------------------------------------------
-- Zustandsnachricht (siehe STATE_MESSAGES): es zaehlt immer nur der
-- letzte Stand, aeltere Eintraege werden ersetzt statt angehaengt.
--
-- Format (bewusst derselbe Stil wie die uebrigen Nutzlasten - eine
-- flache Zeichenkette, damit der SyncManager unveraendert bleibt):
--
--   <Charakter>|<erledigt,...>|<ausgeblendet,...>;<Charakter2>|...
--
-- Lektions-IDs sind ASCII-Bezeichner ohne Komma/Pipe/Semikolon, das
-- Format ist damit eindeutig. Leere Listen bleiben leere Felder.
----------------------------------------------------------

local function JoinIds(set)

    local ids = {}

    for id in pairs(set or {}) do
        if set[id] then ids[#ids + 1] = id end
    end

    table.sort(ids)
    return table.concat(ids, ",")

end

function WeintCodex.Companion.SendAcademyProgress()

    local store = AcademyStore()
    local characters = {}

    for character in pairs(store.completed) do characters[character] = true end
    for character in pairs(store.excluded)  do characters[character] = true end

    local names = {}
    for character in pairs(characters) do names[#names + 1] = character end
    table.sort(names)

    local parts = {}

    -- Auch Charaktere mit leeren Listen melden: die Companion ersetzt
    -- ihre Listen durch die hier gemeldeten. Wuerde ein leergeraeumter
    -- Charakter weggelassen, bliebe der alte Stand auf dem Desktop
    -- stehen und das Abwaehlen des letzten Hakens waere folgenlos.
    for _, character in ipairs(names) do
        parts[#parts + 1] = character
            .. "|" .. JoinIds(store.completed[character])
            .. "|" .. JoinIds(store.excluded[character])
    end

    if #parts == 0 then
        return
    end

    return WeintCodex.Companion.Send("academy", table.concat(parts, ";"))

end

----------------------------------------------------------
-- Rotationstrainer-Sitzung (Addon -> Companion)
----------------------------------------------------------
-- Eine abgeschlossene Übungssitzung am Trainingsdummy (siehe
-- modules/rotationtrainer.lua). Bewusst EIN Event pro Sitzung statt
-- eines STATE_MESSAGES-Eintrags: die Companion führt daraus eine
-- Tage-Serie (core/academy_dummy_sync.py) und muss deshalb jede
-- einzelne Sitzung sehen, nicht nur die letzte.
--
-- Format (Zeichenkette, keine Tabelle - Outbound-Nachrichten sind bei
-- der Companion nur als String parsbar):
--
--   <Charakter>|<specKey>|<Datum YYYYMMDD>|<durationSec>|<hits>|
--   <compliantHits>|<compliancePercent>
--
-- Das Format ist absichtlich unveraendert geblieben, obwohl der
-- Rotationshelfer inzwischen deutlich mehr misst (Auslastung, Laufzeit
-- der Dots, Note): die Companion rechnet ihre Tage-Serie positionsweise
-- aus diesen sieben Feldern. compliancePercent traegt jetzt die
-- gewichtete Gesamtnote statt der reinen Trefferquote - dieselbe
-- Bedeutung ("wie gut war die Sitzung"), nur auf einer ehrlicheren
-- Zahl. Die feineren Werte stehen im Addon unter
-- SavedData.rotationTrainer.sessions.
--
-- specKey ist der interne Profilschlüssel aus data/spec_profiles.lua
-- (z.B. "WARRIOR_ARMS") - die Companion übersetzt ihn über eine eigene
-- Tabelle in ihre Lektions-ID, siehe core/academy_dummy_sync.py.
----------------------------------------------------------

function WeintCodex.Companion.SendDummyPracticeSession(session)
    if type(session) ~= "table" or not session.specKey then return end

    local payload = table.concat({
        UnitName("player") or "?",
        session.specKey,
        session.date or date("%Y%m%d"),
        math.floor(session.duration or 0),
        session.hits or 0,
        session.compliant or 0,
        math.floor(session.compliance or 0),
    }, "|")

    return WeintCodex.Companion.Send("dummy_practice_session", payload)
end

----------------------------------------------------------
-- Charakter-Meldung (Companion -> Bot, für Kalender-Invites)
----------------------------------------------------------
-- Meldet den aktuell eingeloggten Charakter automatisch in
-- WeintCodex.SavedData.twinks (dieselbe kontoweite Twink-Liste wie in
-- der Twinkverwaltung) und schickt anschließend alle als "eigen"
-- markierten Charaktere über die Companion-Warteschlange an den Bot.
-- Der Bot gleicht sie beim Raid-Export gegen die bei der Anmeldung
-- gewählte Klasse ab, um den echten WoW-Namen statt des Discord-
-- Anzeigenamens für den Kalendereintrag zu finden.
----------------------------------------------------------

function WeintCodex.Companion.ReportCharacter()

    WeintCodex.SavedData = WeintCodex.SavedData or {}
    WeintCodex.SavedData.twinks = WeintCodex.SavedData.twinks or {}

    local twinks = WeintCodex.SavedData.twinks

    local playerName = UnitName("player")
    local _, classFileName = UnitClass("player")
    local level = UnitLevel("player")
    local realm = (GetRealmName() or ""):gsub("%s+", "")

    if playerName then

        twinks[playerName] = twinks[playerName] or {}
        twinks[playerName].class = classFileName or twinks[playerName].class
        twinks[playerName].level = tostring(level or twinks[playerName].level or 0)
        twinks[playerName].realm = realm ~= "" and realm or twinks[playerName].realm
        twinks[playerName].selected = true

    end

    local parts = {}

    -- Crossrealm-Raids (z. B. Everlook/Ook Ook): der Bot braucht den
    -- Realm jedes gemeldeten Charakters, damit der Kalender-Invite den
    -- richtigen Realm statt immer nur den des einladenden Spielers
    -- verwendet.
    for name, data in pairs(twinks) do

        if data.selected and data.class then
            table.insert(parts, name .. "|" .. data.class .. "|" .. (data.realm or ""))
        end

    end

    if #parts == 0 then
        return
    end

    table.sort(parts)

    WeintCodex.Companion.Send(
        "character",
        table.concat(parts, ",")
    )

end

----------------------------------------------------------
-- Wer spielt gerade? (Addon -> Companion, bleibt lokal)
----------------------------------------------------------
-- Bis WeintCodex 1.3.2.3 erfuhr die Companion NIE, welcher Charakter
-- ingame angemeldet ist. Sie musste die Frage "wer bin ich" aus einer
-- WarcraftLogs-Namensliste raten - im Zweifel wurde der alphabetisch
-- erste Raider genommen. Genau daher stammte der Fehler, dass in der
-- Academy und in WeintTV ein voellig fremder Charakter stand.
--
-- Bewusst ein EIGENER Nachrichtentyp und keine Erweiterung von
-- "character": jene Nachricht laeuft ueber den CharacterSyncClient
-- weiter an den Discord-Bot, alles daran Angehaengte waere damit ein
-- Bot-Vertrag. "character_report" wird von der Companion lokal
-- verarbeitet (core/character_report_sync.py) und verlaesst den
-- Rechner nie - dasselbe Muster wie "dummy_practice_session".
--
-- Format (flache Zeichenkette; Ausgangsnachrichten kann
-- addon/sync_reader.py der Companion nur als String lesen):
--
--   <Name>|<Realm>|<classFile>|<Level>|<specKey>
--
-- specKey darf leer bleiben - die Spezialisierung steht bei
-- PLAYER_LOGIN noch nicht verlaesslich fest. Die Companion nimmt
-- zwei bis fuenf Felder und ignoriert weitere, das Format kann also
-- wachsen, ohne die alte Gegenseite zu brechen.
----------------------------------------------------------

function WeintCodex.Companion.ReportLoggedInCharacter()

    -- Eine zu alte Companion kennt den Typ nicht und wuerde ihn an
    -- den Bot zu senden versuchen: das scheitert, die Nachricht
    -- bliebe liegen und erzeugte im Sync-Takt Fehlermeldungen.
    if not CompanionAtLeast(1, 7) then
        return
    end

    local name, realm = WeintCodex.Names.Me()
    if name == "" then return end

    local _, classFile = UnitClass("player")
    local level = UnitLevel("player")

    -- Derselbe Profilschluessel wie ueberall sonst (siehe
    -- data/spec_profiles.lua). Er darf leer bleiben: bei PLAYER_LOGIN
    -- ist die Spezialisierung noch nicht verlaesslich abfragbar, und
    -- die Companion braucht sie fuer die Charakterauswahl nicht.
    local specKey = ""
    if WeintCodex.Charakter and WeintCodex.Charakter.GetProfileKey then
        specKey = WeintCodex.Charakter.GetProfileKey() or ""
    end

    return WeintCodex.Companion.Send(
        "character_report",
        table.concat({
            name,
            realm or "",
            classFile or "",
            tostring(level or 0),
            specKey,
        }, "|")
    )

end

----------------------------------------------------------
-- Ausruestungsstand (Addon -> Companion, bleibt lokal)
----------------------------------------------------------
-- Die Companion-Seiten "Meine Charaktere" und "Vorbereitung" waren bis
-- 2.0.0 leer, und das war ehrlich: ueber Ausruestung wusste die App
-- schlicht nichts. Die Twinkliste ("character") traegt Name, Klasse und
-- Realm und wandert an den Bot; Gegenstandsstufe, Verzauberungen,
-- Sockel und offene BiS-Plaetze kamen nirgends vor. Ein Ring bei 0 %
-- haette eine Messung behauptet, die es nicht gab - deshalb stand dort
-- ein Leerzustand statt einer Null.
--
-- Diese Nachricht liefert die fehlende Messung. Sie bleibt wie
-- "character_report" und "dummy_practice_session" auf dem Rechner des
-- Spielers und geht den Bot nichts an: es ist die eigene Ausruestung,
-- kein Gildenwissen. Bewusst ein eigener Typ und keine Erweiterung von
-- "character" - jene Nachricht ist ein Bot-Vertrag.
--
-- Format (flache Zeichenkette; Ausgangsnachrichten kann
-- addon/sync_reader.py der Companion nur zeilenweise als String lesen,
-- verschachtelte Tabellen gibt es nur in der Gegenrichtung):
--
--   <KOPF> ~ <ZAEHLER> ~ <BIS> ~ <SLOTS> ~ <MAENGEL>
--
--   Abschnitte mit "~", Datensaetze mit ";", Felder mit "|".
--
--   KOPF     Name|Realm|classFile|Level|specKey|specName|
--            IlvlAngelegt|IlvlGesamt|Punkte|Note|Vollstaendigkeit|
--            Qualitaet|Zeitstempel
--   ZAEHLER  je ein Satz "ench" und "gem":
--            Art|optimal|ok|falsch|ueberCap|fehlt|gesamt
--   BIS      Satz 1: getragen|Variante|offen|gesamt
--            Satz 2: Namen der offenen Plaetze, mit "|" getrennt
--            (leerer Abschnitt = fuer diese Spec ist keine Liste
--            gepflegt; das ist etwas anderes als "nichts offen")
--   SLOTS    slotId|Slotname|Itemname|Ilvl|Verzauberung|Sockel
--            Status je: optimal|ok|wrong|overcap|missing|-
--            ("-" heisst: dieser Platz kennt so etwas nicht)
--   MAENGEL  prio|status|Text
--
-- Die Companion nimmt fehlende Abschnitte und fehlende Felder hin und
-- ignoriert zusaetzliche (siehe core/character_sheet_sync.py) - das
-- Format darf also wachsen, ohne eine aeltere Gegenseite zu brechen.
----------------------------------------------------------

-- Trennzeichen duerfen im Inhalt nicht vorkommen. Itemnamen kommen aus
-- dem Client und koennen theoretisch alles enthalten; ausserdem
-- schreibt sync_reader.py die Nutzlast in einen Lua-String zurueck, in
-- dem ein Backslash nicht entwertet wird.
local function CleanField(text)

    text = tostring(text or "")

    text = text:gsub("[|;~\"\\\r\n]", " ")

    return (text:gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1"))

end

-- Reihenfolge "wie schlimm". Ein Item mit drei Sockeln bekommt den
-- schlechtesten seiner Steine als Slotstatus: die Vorbereitungsansicht
-- fragt, wo noch etwas zu tun ist, und ein leerer Sockel neben zwei
-- perfekten ist genau das.
local STATUS_SEVERITY = {
    missing = 0,
    wrong   = 1,
    overcap = 2,
    ok      = 3,
    optimal = 4,
}

local function WorseStatus(current, candidate)

    if not candidate then return current end
    if not current then return candidate end

    local a = STATUS_SEVERITY[current]   or 99
    local b = STATUS_SEVERITY[candidate] or 99

    if b < a then return candidate end

    return current

end

-- Gegenstandsstufe eines angelegten Teils. GetDetailedItemLevelInfo
-- kennt die Aufwertungsstufen und gibt es nicht in jedem Classic-Build
-- - deshalb ueber pcall, mit dem Grundwert aus GetItemInfo als
-- Rueckfall (gleiches Muster wie GetInventoryItemID in modules/bis.lua).
local function SlotItemLevel(link)

    if not link then return 0 end

    if GetDetailedItemLevelInfo then
        local ok, level = pcall(GetDetailedItemLevelInfo, link)
        if ok and type(level) == "number" and level > 0 then
            return level
        end
    end

    local _, _, _, itemLevel = GetItemInfo(link)

    return itemLevel or 0

end

local function BuildCharacterSheet()

    if not (WeintCodex.Charakter and WeintCodex.Charakter.Scan) then
        return nil
    end

    local name, realm = WeintCodex.Names.Me()
    if name == "" then return nil end

    -- Ohne das liefert der Scan die Bewertung von vorhin, wenn sich
    -- seit dem letzten Aufruf Ausruestung, Spec oder Beruf geaendert
    -- haben - und genau dann wird er hier gerufen.
    if WeintCodex.Charakter.ClearCache then
        WeintCodex.Charakter.ClearCache()
    end

    local ok, scan = pcall(WeintCodex.Charakter.Scan)

    if not ok or type(scan) ~= "table" then
        return nil
    end

    local _, classFile = UnitClass("player")

    local equippedIlvl, overallIlvl = 0, 0

    if GetAverageItemLevel then
        local gotOk, overall, equipped = pcall(GetAverageItemLevel)
        if gotOk then
            overallIlvl  = tonumber(overall) or 0
            equippedIlvl = tonumber(equipped) or overallIlvl
        end
    end

    local score = scan.score or {}

    ------------------------------------------------------
    -- Kopf
    ------------------------------------------------------

    local head = table.concat({
        CleanField(name),
        CleanField(realm or ""),
        CleanField(classFile or ""),
        tostring(UnitLevel("player") or 0),
        CleanField(scan.profileKey or ""),
        CleanField(scan.specDisplay or ""),
        string.format("%.1f", equippedIlvl),
        string.format("%.1f", overallIlvl),
        tostring(score.total or 0),
        CleanField(score.grade or ""),
        tostring(score.completeness or 0),
        tostring(score.quality or 0),
        tostring(time()),
    }, "|")

    ------------------------------------------------------
    -- Zaehler
    ------------------------------------------------------

    local function CountRecord(kind, counts)

        counts = counts or {}

        return table.concat({
            kind,
            tostring(counts.optimal or 0),
            tostring(counts.ok or 0),
            tostring(counts.wrong or 0),
            tostring(counts.overcap or 0),
            tostring(counts.missing or 0),
            tostring(counts.total or 0),
        }, "|")

    end

    local countsSection = table.concat({
        CountRecord("ench", scan.enchants and scan.enchants.counts),
        CountRecord("gem",  scan.gems and scan.gems.counts),
    }, ";")

    ------------------------------------------------------
    -- BiS
    ------------------------------------------------------
    -- Leer, wenn fuer die Spec keine Liste gepflegt ist. Ein "0 offen"
    -- waere dort eine Behauptung ueber Vollstaendigkeit, die niemand
    -- geprueft hat - dieselbe Trennung von Befund und Datenluecke wie
    -- ueberall sonst in diesem Projekt.

    local bisSection = ""

    if WeintCodex.BiS and WeintCodex.BiS.GetSummary then

        local summary, hasData = WeintCodex.BiS.GetSummary(scan.profileKey)

        if hasData then

            local openSlots = {}

            for _, slot in ipairs(summary.openSlots or {}) do
                openSlots[#openSlots + 1] = CleanField(slot)
            end

            bisSection = table.concat({
                table.concat({
                    tostring(summary.have or 0),
                    tostring(summary.variant or 0),
                    tostring(summary.open or 0),
                    tostring(summary.total or 0),
                }, "|"),
                table.concat(openSlots, "|"),
            }, ";")

        end

    end

    ------------------------------------------------------
    -- Slots
    ------------------------------------------------------

    local enchBySlot = {}

    for _, row in ipairs((scan.enchants and scan.enchants.rows) or {}) do
        if row.slotId then enchBySlot[row.slotId] = row.status end
    end

    local gemBySlot = {}

    for _, row in ipairs((scan.gems and scan.gems.rows) or {}) do
        if row.slotId then
            gemBySlot[row.slotId] = WorseStatus(gemBySlot[row.slotId], row.status)
        end
    end

    local slotRecords = {}

    for _, slotDef in ipairs(WeintCodex.Charakter.EquipSlots or {}) do

        local link = GetInventoryItemLink("player", slotDef.id)

        local itemName = ""

        if link then
            itemName = link:match("|h%[(.-)%]|h") or ""
        end

        slotRecords[#slotRecords + 1] = table.concat({
            tostring(slotDef.id),
            CleanField(slotDef.name),
            CleanField(itemName),
            -- Ein leerer Platz meldet 0 und nicht etwa gar nichts: die
            -- Companion soll "hier haengt nichts" zeigen koennen,
            -- statt den Slot stillschweigend auszulassen.
            string.format("%.0f", link and SlotItemLevel(link) or 0),
            enchBySlot[slotDef.id] or "-",
            gemBySlot[slotDef.id] or "-",
        }, "|")

    end

    ------------------------------------------------------
    -- Maengel
    ------------------------------------------------------

    local issueRecords = {}

    for _, issue in ipairs(scan.issues or {}) do

        issueRecords[#issueRecords + 1] = table.concat({
            tostring(issue.prio or 9),
            CleanField(issue.status or ""),
            CleanField(issue.text or ""),
        }, "|")

    end

    return table.concat({
        head,
        countsSection,
        bisSection,
        table.concat(slotRecords, ";"),
        table.concat(issueRecords, ";"),
    }, "~")

end

-- Zuletzt gesendete Nutzlast. Der Scan laeuft bei jedem
-- Ausruestungswechsel, die Nachricht aber nur, wenn sich am Ergebnis
-- etwas geaendert hat - sonst schriebe jeder Ringtausch dieselbe
-- Zeichenkette erneut in die SavedVariables.
local lastSheet = nil

function WeintCodex.Companion.ReportCharacterSheet()

    -- Erst Companion 2.0.1 kennt den Typ. Eine aeltere wuerde ihn in
    -- ihren generischen Zweig geben, an den Bot POSTen, scheitern, die
    -- Nachricht liegen lassen und im Sync-Takt Fehler protokollieren.
    if not CompanionAtLeast(2, 0, 1) then
        return
    end

    local sheet = BuildCharacterSheet()

    if not sheet or sheet == lastSheet then
        return
    end

    lastSheet = sheet

    return WeintCodex.Companion.Send("character_sheet", sheet)

end

----------------------------------------------------------
-- Welche WeakAuras kennt dieses Addon? (bleibt lokal)
----------------------------------------------------------
-- Die Companion kann das nicht selbst herausfinden. Die
-- mitgelieferten Auren stecken als Lua-Tabellen in data/weakauras/
-- im Addon-Ordner; sie dort herauszuparsen waere ein zweiter, stiller
-- Vertrag ueber ein Dateiformat, das sich mit jedem Release aendern
-- darf. Ohne diese Meldung koennte ihre Seite deshalb nur die Auren
-- auflisten, die sie selbst angelegt hat - und "eine vorhandene
-- aktualisieren" waere genau auf diese beschraenkt gewesen.
--
-- Der Importstring ist bewusst NICHT dabei. Er ist bei einem
-- Klassenpaket ein Vielfaches der uebrigen Nutzlast, und zum
-- Auflisten und Ersetzen braucht ihn niemand: wer eine Aura
-- aktualisiert, bringt die neue Zeichenkette ohnehin mit.
--
-- Wie "character_report", "character_sheet" und
-- "dummy_practice_session" bleibt die Nachricht auf dem Rechner des
-- Spielers - der Bot hat mit ihr nichts zu tun.
--
-- Format (flache Zeichenkette; Ausgangsnachrichten kann
-- addon/sync_reader.py der Companion nur als String lesen):
--
--   <id>|<name>|<category>|<version>|<origin>;<id>|...
--
--   origin ist "addon" (mitgeliefert) oder "companion" (von der
--   Companion zugestellt und hier uebernommen). Die Companion nimmt
--   fehlende Felder hin und ignoriert zusaetzliche - das Format darf
--   also wachsen.
----------------------------------------------------------

-- Nur senden, wenn sich etwas geaendert hat. Der Katalog ist ueber
-- eine Spielsitzung hinweg konstant, solange niemand etwas
-- installiert; ihn im Sync-Takt erneut in die SavedVariables zu
-- schreiben waere reine Schreiblast.
local lastCatalog = nil

function WeintCodex.Companion.ReportWeakAuraCatalog()

    -- Erst Companion 2.1.0 kennt den Typ. Eine aeltere gaebe ihn in
    -- ihren generischen Zweig, POSTete ihn an den Bot, scheiterte,
    -- liesse die Nachricht liegen und protokollierte im Sync-Takt
    -- einen Fehler - dieselbe Falle wie bei "character_report".
    if not CompanionAtLeast(2, 1) then
        return
    end

    if not (WeintCodex.WeakAuras and WeintCodex.WeakAuras.Catalog) then
        return
    end

    local records = {}

    for _, entry in ipairs(WeintCodex.WeakAuras.Catalog()) do

        records[#records + 1] = table.concat({
            CleanField(entry.id),
            CleanField(entry.name),
            CleanField(entry.category),
            CleanField(entry.version),
            CleanField(entry.origin),
        }, "|")

    end

    if #records == 0 then
        return
    end

    local payload = table.concat(records, ";")

    if payload == lastCatalog then
        return
    end

    lastCatalog = payload

    return WeintCodex.Companion.Send("weakaura_catalog", payload)

end

----------------------------------------------------------
-- Wann gemeldet wird
----------------------------------------------------------
-- Nicht bei PLAYER_LOGIN: dort ist weder die Spezialisierung
-- verlaesslich abfragbar noch sind die Item-Daten im Client-Cache, und
-- ein Scan zu diesem Zeitpunkt meldete eine halb leere Ausruestung als
-- Befund. PLAYER_ENTERING_WORLD plus eine kurze Wartezeit ist der
-- Zeitpunkt, zu dem auch die Charakterseite des Addons brauchbare
-- Werte liefert.
--
-- Danach bei jedem Ausruestungs- oder Spec-Wechsel, entprellt: ein
-- kompletter Scan liest je Item den Tooltip, und beim Umsockeln
-- feuert PLAYER_EQUIPMENT_CHANGED mehrfach hintereinander.
----------------------------------------------------------

local sheetWatcher = CreateFrame("Frame")

sheetWatcher._pending = false

local function ScheduleCharacterSheet(delay)

    if sheetWatcher._pending then return end

    if not (C_Timer and C_Timer.After) then
        WeintCodex.Companion.ReportCharacterSheet()
        return
    end

    sheetWatcher._pending = true

    C_Timer.After(delay or 3, function()
        sheetWatcher._pending = false
        pcall(WeintCodex.Companion.ReportCharacterSheet)
    end)

end

WeintCodex.Companion.ScheduleCharacterSheet = ScheduleCharacterSheet

sheetWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
sheetWatcher:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
sheetWatcher:RegisterEvent("SKILL_LINES_CHANGED")

-- Wie in modules/bis.lua ueber pcall: welche der Spec-Events ein
-- Classic-Build kennt, schwankt.
pcall(sheetWatcher.RegisterEvent, sheetWatcher, "PLAYER_SPECIALIZATION_CHANGED")
pcall(sheetWatcher.RegisterEvent, sheetWatcher, "ACTIVE_TALENT_GROUP_CHANGED")

sheetWatcher:SetScript("OnEvent", function(_, event)

    -- Beim ersten Betreten der Welt braucht der Client laenger, bis
    -- Item-Infos im Cache stehen.
    ScheduleCharacterSheet(event == "PLAYER_ENTERING_WORLD" and 8 or 3)

end)
