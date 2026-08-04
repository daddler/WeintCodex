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

local function AcademyStore()

    WeintCodex.SavedData = WeintCodex.SavedData or {}

    local store = WeintCodex.SavedData.academy or {}
    store.completed = store.completed or {}
    store.excluded  = store.excluded  or {}

    WeintCodex.SavedData.academy = store
    return store

end

WeintCodex.Companion.AcademyStore = AcademyStore

-- Fortschritt-Listen des uebergebenen Charakters (immer eine Tabelle).
function WeintCodex.Companion.AcademyProgress(character)

    local store = AcademyStore()
    character = character or UnitName("player") or "?"

    store.completed[character] = store.completed[character] or {}
    store.excluded[character]  = store.excluded[character]  or {}

    return store.completed[character], store.excluded[character]

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
--                    actor   = { name, class, spec, role },
--                    ratings = { { category, stars, detail, metric, at }, ... },
--                    plan    = { "<lessonId>", ... },
--                    results = { ["<lessonId>"] = { status, at,
--                                  checks = { { status, detail }, ... } } },
--                    completed = { "<lessonId>", ... },
--                    excluded  = { "<lessonId>", ... },
--                    gap = "" | "no_raid" | "no_pull" | "sums_only" }
--
-- weinttv_report   { capturedAt, source, pull, duration, bossHealth, kill,
--                    hasAnalysis, gap, me,
--                    encounter   = { name, instance, difficulty, size },
--                    damageTaken, uptimes, activity, movement, cooldowns,
--                    support, mechanics, consumables, warnings }
--                  (Zeilenschemata siehe modules/weinttv.lua)
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

INBOX_HANDLERS.academy_catalog = function(payload)

    if type(payload) ~= "table" then return end

    local store = AcademyStore()
    store.catalog = payload

end

INBOX_HANDLERS.academy_state = function(payload)

    if type(payload) ~= "table" then return end

    local store = AcademyStore()
    store.state = payload

    -- Fortschritt vom Desktop uebernehmen. Die Companion ist beim Login
    -- die juengere Quelle: sie hat die Auswertung gerade erst erzeugt,
    -- waehrend die Addon-Seite seit dem letzten Ausloggen unveraendert
    -- ist. Ingame gesetzte Haken gehen ueber die Ausgangs-Warteschlange
    -- zurueck (siehe SendAcademyProgress).
    local character = payload.character
    if character then
        if payload.completed then
            store.completed[character] = IdSet(payload.completed)
        end
        if payload.excluded then
            store.excluded[character] = IdSet(payload.excluded)
        end
    end

end

INBOX_HANDLERS.weinttv_report = function(payload)

    if type(payload) ~= "table" then return end

    WeintCodex.SavedData = WeintCodex.SavedData or {}
    WeintCodex.SavedData.weinttv = payload

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

function WeintCodex.Companion.ProcessInbox()

InitializeInbox()

if #WeintCompanionInboxDB.queue == 0 then
    return
end

------------------------------------------------------
-- 1. Durchgang: nur Zugriffsprofile
------------------------------------------------------
-- Muss vor allem anderen laufen. Sonst wuerde beim erstmaligen
-- Verknuepfen genau der Schwung Daten noch durchrutschen, den das
-- gelieferte Profil eigentlich sperrt. Mehrere Profile werden in
-- Warteschlangen-Reihenfolge angewandt, das letzte gewinnt.
------------------------------------------------------

for _, message in ipairs(WeintCompanionInboxDB.queue) do

    if message.type == "access_profile" and message.payload ~= nil then
        Dispatch(message)
    end

end

------------------------------------------------------
-- 2. Durchgang: alles andere, mit Herkunftspruefung
------------------------------------------------------

local rejected = 0

for _, message in ipairs(WeintCompanionInboxDB.queue) do

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

-- Auch verworfene Nachrichten verlassen die Warteschlange. Sie liegen
-- zu lassen hiesse dieselbe Warnung bei jedem Login - und schlimmer:
-- nach einem legitimen /wc access reset wuerden wochenalte Roster der
-- vorherigen Community ploetzlich angenommen. Gezaehlt werden sie in
-- SavedData.access.rejections, das reicht fuer den Supportfall.
wipe(WeintCompanionInboxDB.queue)

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
