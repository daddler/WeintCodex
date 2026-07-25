--------------------------------------------------
-- WeintCodex :: Encounter Tracking
--
-- Eigenstaendiges, lose gekoppeltes Modul: kennt den Kill-/Wipe-Zustand
-- von Encountern, ohne irgendetwas ueber Bossguide-UI zu wissen. Zwei
-- Datenquellen, kombiniert:
--
--   a) Blizzard-Lockout-API (GetSavedInstanceInfo/-EncounterInfo) - liefert
--      beim Betreten/Login den echten Kill-Status, auch fuer Kills, die
--      VOR dieser Session passiert sind. Liefert KEINE Wipe-Zahl.
--   b) Eigenes ENCOUNTER_END-Tracking - liefert echte, selbst gezaehlte
--      Wipes, aber nur ab dem Zeitpunkt, an dem das Addon waehrend eines
--      Encounters lief (keine rueckwirkenden Daten).
--
-- Alle WoW-API-Aufrufe sind defensiv (pcall + Typ-Check), da hier keine
-- Live-WoW-Instanz zum Verifizieren von Signatur/Verhalten existiert -
-- im Zweifel wird der Status einfach nicht gesetzt (bleibt "Offen"),
-- niemals geraten oder das Addon zum Absturz gebracht.
--------------------------------------------------

WeintCodex.EncounterTracking = {}

local unpack = unpack or table.unpack

-- --------------------------------------------------
-- SavedVariables-Zugriff
-- --------------------------------------------------

local function GetInstanceStore(instanceName)
    local sd = WeintCodex.SavedData
    if not sd then return nil end
    sd.encounterProgress = sd.encounterProgress or {}
    sd.encounterProgress[instanceName] = sd.encounterProgress[instanceName] or { resetStamp = 0, bosses = {} }
    return sd.encounterProgress[instanceName]
end

-- --------------------------------------------------
-- Woechentlicher Reset
--
-- Primaerquelle ist die Restlaufzeit der Blizzard-Lockout-Instanz
-- (store.resetExpiry, gesetzt in RefreshFromLockout) - die ist exakt und
-- unabhaengig von Region/Zeitzone. Nur solange noch nie ein Lockout
-- gesehen wurde, greift die grobe Wochentags-Heuristik darunter.
-- --------------------------------------------------

local RESET_WEEKDAY = 3   -- os.date("%w"): 0=So, 1=Mo, 2=Di, 3=Mi (EU-Reset Mittwoch)
local RESET_HOUR     = 8   -- lokale Serverzeit, grob

local function CurrentResetStamp()
    local ok, stamp = pcall(function()
        local now = time()
        local d = date("*t", now)
        local daysSinceReset = (d.wday - 1 - RESET_WEEKDAY) % 7
        local resetDay = now - daysSinceReset * 86400
        local rd = date("*t", resetDay)
        rd.hour, rd.min, rd.sec = RESET_HOUR, 0, 0
        local resetStamp = time(rd)
        if resetStamp > now then
            resetStamp = resetStamp - 7 * 86400
        end
        return resetStamp
    end)
    if ok and type(stamp) == "number" then
        return stamp
    end
    return 0
end

local function EnsureFreshReset(store)
    -- Exakter Ablaufzeitpunkt aus dem Lockout bekannt: nur dann leeren,
    -- wenn er wirklich vorbei ist. Verhindert, dass die Heuristik unten
    -- frische Kills mitten in der Woche wegwirft (EnsureFreshReset laeuft
    -- auch im Lesepfad GetStatus).
    if type(store.resetExpiry) == "number" and store.resetExpiry > 0 then
        if time() >= store.resetExpiry then
            store.resetExpiry = nil
            store.resetStamp  = CurrentResetStamp()
            store.bosses      = {}
        end
        return
    end

    local current = CurrentResetStamp()
    if current > 0 and current ~= store.resetStamp then
        store.resetStamp = current
        store.bosses = {}
    end
end

-- --------------------------------------------------
-- a) Blizzard-Lockout-API: Kill-Status beim Betreten/Login uebernehmen
-- --------------------------------------------------

-- WICHTIG: alle Rueckgabewerte durchreichen. GetSavedInstanceInfo liefert
-- numEncounters erst an Position 11 - eine auf 8 Werte gekuerzte Variante
-- macht den kompletten Lockout-Import wirkungslos (Fortschritt bleibt 0%).
-- Feste Obergrenze statt "#res", damit nil-Loecher in der Rueckgabeliste
-- (z.B. difficultyName = nil) nicht vorzeitig abschneiden.
local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local res = { pcall(fn, ...) }
    if not res[1] then return nil end
    return unpack(res, 2, 16)
end

local function After(seconds, fn)
    if C_Timer and C_Timer.After then
        if pcall(C_Timer.After, seconds, fn) then return end
    end
    fn()
end

-- Der Schlachtzugsbrowser zaehlt nicht zum Gilden-Fortschritt: LFR-Kills
-- wuerden die Prozentanzeige aufblaehen. Nur ausschliessen, wenn LFR
-- POSITIV erkannt wird - unbekannte Schwierigkeitsgrade lieber mitzaehlen.
local LFR_DIFFICULTY_IDS = { [7] = true, [17] = true }
local LFR_NAME_HINTS     = { "schlachtzugsbrowser", "schlachtzugssuche", "raid finder", "lfr" }

local function IsLFR(difficultyID, difficultyName)
    if type(difficultyID) == "number" and LFR_DIFFICULTY_IDS[difficultyID] then
        return true
    end
    if type(difficultyName) == "string" then
        local lower = difficultyName:lower()
        for _, hint in ipairs(LFR_NAME_HINTS) do
            if lower:find(hint, 1, true) then return true end
        end
    end
    return false
end

-- Ein Charakter kann pro Woche mehrere Lockouts derselben Instanz haben
-- (10/25 Normal, Heroisch, Flex). Wir laufen ueber ALLE passenden und
-- vereinigen die Kills - "diese Woche gelegt" ist unabhaengig davon, in
-- welcher ID der Boss lag.
-- nameFragment: Namensteil, an dem wir die Instanz erkennen (robuster als
-- ein exakter String-Vergleich gegen Lokalisierungsvarianten).
local function ForEachSavedInstance(nameFragment, fn)
    local numSaved = SafeCall(GetNumSavedInstances)
    if type(numSaved) ~= "number" then return end

    for i = 1, numSaved do
        local name, _, reset, difficultyID, locked, extended, _, isRaid, _, difficultyName, numEncounters =
            SafeCall(GetSavedInstanceInfo, i)
        if type(name) == "string" and name:find(nameFragment, 1, true)
            and (locked or extended) and isRaid
            and not IsLFR(difficultyID, difficultyName) then
            fn(i, numEncounters, reset)
        end
    end
end

-- Fallback, falls numEncounters fehlt: hochzaehlen, bis die API keinen
-- Bossnamen mehr liefert (harte Obergrenze als Endlosschleifen-Schutz).
local MAX_ENCOUNTER_PROBE = 32

-- Fragt die Lockout-API fuer die angegebene Instanz ab und uebernimmt
-- den Kill-Status positionsbasiert (Encounter-Index 1..N = bossOrder-
-- Index 1..N, die SoO-Encounter-Reihenfolge ist offiziell fix).
-- Rueckgabe: true, wenn sich dabei etwas geaendert hat.
function WeintCodex.EncounterTracking.RefreshFromLockout(instanceName, nameFragment)
    local store = GetInstanceStore(instanceName)
    if not store then return false end
    EnsureFreshReset(store)

    local now      = time()
    local changed  = false
    local expiry   = nil

    ForEachSavedInstance(nameFragment, function(savedIndex, numEncounters, reset)
        if type(reset) == "number" and reset > 0 then
            local ends = now + reset
            if not expiry or ends > expiry then expiry = ends end
        end

        local limit = (type(numEncounters) == "number" and numEncounters > 0)
                      and numEncounters or MAX_ENCOUNTER_PROBE

        for encIndex = 1, limit do
            local bossName, _, isKilled = SafeCall(GetSavedInstanceEncounterInfo, savedIndex, encIndex)
            if type(bossName) ~= "string" or bossName == "" then break end
            if isKilled then
                local entry = store.bosses[encIndex] or {}
                if not entry.cleared then changed = true end
                entry.cleared   = true
                entry.clearedAt = entry.clearedAt or now
                store.bosses[encIndex] = entry
            end
        end
    end)

    if expiry and expiry ~= store.resetExpiry then
        store.resetExpiry = expiry
    end

    return changed
end

-- --------------------------------------------------
-- Registrierte Instanzen + Aenderungs-Hook
--
-- Die Module, die Fortschritt anzeigen (aktuell modules/bossguides.lua),
-- melden ihre Instanz hier einmalig an. Dadurch laeuft der Lockout-Import
-- auch dann, wenn das WeintCodex-Fenster gar nicht offen war - frueher
-- hing er am aktiven Bossguide und passierte nach einem Login nie.
-- --------------------------------------------------

local registeredInstances = {}

function WeintCodex.EncounterTracking.RegisterInstance(instanceName, nameFragment)
    if type(instanceName) ~= "string" or type(nameFragment) ~= "string" then return end
    for _, inst in ipairs(registeredInstances) do
        if inst.instanceName == instanceName then return end
    end
    registeredInstances[#registeredInstances + 1] = {
        instanceName = instanceName,
        nameFragment = nameFragment,
    }
end

-- Wird nach jeder Aenderung aufgerufen (von der UI gesetzt, optional).
WeintCodex.EncounterTracking.onChanged = nil

local function NotifyChanged(instanceName)
    local cb = WeintCodex.EncounterTracking.onChanged
    if type(cb) == "function" then
        pcall(cb, instanceName)
    end
end

function WeintCodex.EncounterTracking.RefreshAll()
    for _, inst in ipairs(registeredInstances) do
        if WeintCodex.EncounterTracking.RefreshFromLockout(inst.instanceName, inst.nameFragment) then
            NotifyChanged(inst.instanceName)
        end
    end
end

-- GetSavedInstanceInfo liefert erst brauchbare Daten, wenn der Server die
-- Raid-Info geschickt hat. Anstossen und in UPDATE_INSTANCE_INFO erneut
-- importieren.
local function RequestLockoutUpdate()
    SafeCall(RequestRaidInfo)
end

-- --------------------------------------------------
-- b) Live-Tracking ueber ENCOUNTER_END
-- --------------------------------------------------

-- Der aktuell in der Bossguide-UI angezeigte Boss dient als einziger
-- Kontext fuer die WIPE-Zuordnung (siehe SetActiveContext) - wir
-- versuchen NICHT, encounterID gegen unsere eigene Boss-Liste zu
-- matchen, da wir das hier nicht verifizieren koennen. Lieber ein
-- Wipe nicht zaehlen als ihn dem falschen Boss zuzuschreiben.
-- Kills brauchen diesen Kontext nicht: die holt der Lockout-Import.
local activeContext = nil -- { instanceName, nameFragment, bossIndex, bossName }

function WeintCodex.EncounterTracking.SetActiveContext(instanceName, nameFragment, bossIndex, bossName)
    activeContext = {
        instanceName = instanceName,
        nameFragment = nameFragment,
        bossIndex    = bossIndex,
        bossName     = bossName,
    }
end

local trackerFrame = CreateFrame("Frame")

local function TryRegisterEvent(frame, eventName)
    local ok = pcall(frame.RegisterEvent, frame, eventName)
    return ok
end

TryRegisterEvent(trackerFrame, "PLAYER_ENTERING_WORLD")
TryRegisterEvent(trackerFrame, "UPDATE_INSTANCE_INFO")
TryRegisterEvent(trackerFrame, "ENCOUNTER_END")

trackerFrame:SetScript("OnEvent", function(_, event, ...)
    -- Vararg vor dem pcall in Locals kopieren: "..." ist innerhalb der
    -- pcall-Closure unten nicht mehr gueltig (eigener Funktionskontext,
    -- kein eigener Vararg).
    local _, encounterName, _, _, success = ...

    local ok = pcall(function()
        if event == "PLAYER_ENTERING_WORLD" then
            WeintCodex.EncounterTracking.RefreshAll()
            RequestLockoutUpdate()

        elseif event == "UPDATE_INSTANCE_INFO" then
            WeintCodex.EncounterTracking.RefreshAll()

        elseif event == "ENCOUNTER_END" then
            -- success kommt je nach Client als 1 oder als true - beides
            -- ist ein Kill. (Frueher wurde true als Wipe gezaehlt.)
            local killed = (success == 1) or (success == true)

            if activeContext
                and type(encounterName) == "string"
                and encounterName == activeContext.bossName then

                local store = GetInstanceStore(activeContext.instanceName)
                if store then
                    EnsureFreshReset(store)
                    local entry = store.bosses[activeContext.bossIndex] or {}
                    if killed then
                        entry.cleared   = true
                        entry.clearedAt = time()
                    else
                        entry.wipes = (entry.wipes or 0) + 1
                    end
                    store.bosses[activeContext.bossIndex] = entry
                    NotifyChanged(activeContext.instanceName)
                end
            end

            -- Unabhaengig von der Wipe-Zuordnung: den Kill ueber die
            -- Lockout-API nachziehen (funktioniert auch ohne offene UI und
            -- ohne exakten Namensabgleich). Der Server braucht kurz, bis
            -- die Instanz-Info aktualisiert ist.
            if killed then
                RequestLockoutUpdate()
                After(3, function()
                    pcall(RequestLockoutUpdate)
                    pcall(WeintCodex.EncounterTracking.RefreshAll)
                end)
            end
        end
    end)
    if not ok then
        -- Tracking ist ein Komfort-Feature, niemals das restliche Addon
        -- mitreissen, wenn hier etwas Unerwartetes passiert.
    end
end)

-- --------------------------------------------------
-- Oeffentliche Abfrage
-- --------------------------------------------------

-- Gibt { cleared, wipes, clearedAt } fuer instanceName/bossIndex zurueck.
-- Fehlt jegliche Information, ist cleared=false und wipes=0 (neutraler
-- "Offen"-Zustand, nie geraten).
function WeintCodex.EncounterTracking.GetStatus(instanceName, bossIndex)
    local store = GetInstanceStore(instanceName)
    if not store then
        return { cleared = false, wipes = 0, clearedAt = nil }
    end
    EnsureFreshReset(store)

    local entry = store.bosses[bossIndex]
    if not entry then
        return { cleared = false, wipes = 0, clearedAt = nil }
    end

    return {
        cleared   = entry.cleared == true,
        wipes     = entry.wipes or 0,
        clearedAt = entry.clearedAt,
    }
end
