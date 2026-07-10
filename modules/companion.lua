WeintCodex = WeintCodex or {}
WeintCodex.Companion = {}

----------------------------------------------------------
-- Nachrichtentypen
----------------------------------------------------------

local STATE_MESSAGES = {

    materials = true,
    character = true,
    calendar = true,

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

function WeintCodex.Companion.ProcessInbox()

InitializeInbox()

if #WeintCompanionInboxDB.queue == 0 then
    return
end

for _, message in ipairs(WeintCompanionInboxDB.queue) do

    if message.type == "raid_import" and message.payload then

        if WeintCodex.Sync and WeintCodex.Sync.QuickImport then
            WeintCodex.Sync.QuickImport(message.payload)
        end

    end

end

wipe(WeintCompanionInboxDB.queue)

end
