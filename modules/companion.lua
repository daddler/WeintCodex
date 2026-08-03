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
-- Die folgenden drei erwarten eine TABELLE als payload, keinen String:
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

function WeintCodex.Companion.ProcessInbox()

InitializeInbox()

if #WeintCompanionInboxDB.queue == 0 then
    return
end

for _, message in ipairs(WeintCompanionInboxDB.queue) do

    local handler = message.type and INBOX_HANDLERS[message.type]

    if handler and message.payload ~= nil then
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

end

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

    for _, character in ipairs(names) do
        local done = JoinIds(store.completed[character])
        local excl = JoinIds(store.excluded[character])
        if done ~= "" or excl ~= "" then
            parts[#parts + 1] = character .. "|" .. done .. "|" .. excl
        end
    end

    if #parts == 0 then
        return
    end

    return WeintCodex.Companion.Send("academy", table.concat(parts, ";"))

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
