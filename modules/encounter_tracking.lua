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
--   b) Eigenes ENCOUNTER_START/ENCOUNTER_END-Tracking - liefert echte,
--      selbst gezaehlte Wipes, aber nur ab dem Zeitpunkt, an dem das
--      Addon waehrend eines Encounters lief (keine rueckwirkenden Daten).
--
-- Alle WoW-API-Aufrufe sind defensiv (pcall + Typ-Check), da hier keine
-- Live-WoW-Instanz zum Verifizieren von Signatur/Verhalten existiert -
-- im Zweifel wird der Status einfach nicht gesetzt (bleibt "Offen"),
-- niemals geraten oder das Addon zum Absturz gebracht.
--------------------------------------------------

WeintCodex.EncounterTracking = {}

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
-- Wöchentlicher Reset-Zeitstempel (eigene Berechnung, nicht von einem
-- einzelnen API-Rueckgabefeld abhaengig). Annahme: woechentlicher
-- Reset jeden Dienstag - falls das fuer die jeweilige Region nicht
-- exakt stimmt, verschiebt sich der Wipe-Zaehler-Reset im schlimmsten
-- Fall um ein paar Stunden, nichts Kritisches.
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
    local current = CurrentResetStamp()
    if current > 0 and current ~= store.resetStamp then
        store.resetStamp = current
        store.bosses = {}
    end
end

-- --------------------------------------------------
-- a) Blizzard-Lockout-API: Kill-Status beim Betreten/Login uebernehmen
-- --------------------------------------------------

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d, e, f, g, h = pcall(fn, ...)
    if not ok then return nil end
    return a, b, c, d, e, f, g, h
end

-- instanceMatchers: Namensfragmente, an denen wir eine Lockout-Instanz
-- als "das ist unsere Instanz" erkennen (robuster als exakter String-
-- Vergleich gegen Lokalisierungsvarianten).
local function FindSavedInstanceIndex(nameFragment)
    local numSaved = SafeCall(GetNumSavedInstances)
    if type(numSaved) ~= "number" then return nil end

    for i = 1, numSaved do
        local name, _, _, _, locked, extended, _, isRaid, _, _, numEncounters =
            SafeCall(GetSavedInstanceInfo, i)
        if type(name) == "string" and name:find(nameFragment, 1, true)
            and (locked or extended) and isRaid and type(numEncounters) == "number" then
            return i, numEncounters
        end
    end
    return nil
end

-- Fragt die Lockout-API fuer die angegebene Instanz ab und uebernimmt
-- den Kill-Status positionsbasiert (Encounter-Index 1..N = bossOrder-
-- Index 1..N, die SoO-Encounter-Reihenfolge ist offiziell fix).
function WeintCodex.EncounterTracking.RefreshFromLockout(instanceName, nameFragment)
    local store = GetInstanceStore(instanceName)
    if not store then return end
    EnsureFreshReset(store)

    local savedIndex, numEncounters = FindSavedInstanceIndex(nameFragment)
    if not savedIndex then return end

    for encIndex = 1, numEncounters do
        local _, _, isKilled = SafeCall(GetSavedInstanceEncounterInfo, savedIndex, encIndex)
        if isKilled then
            local entry = store.bosses[encIndex] or {}
            entry.cleared = true
            entry.clearedAt = entry.clearedAt or time()
            store.bosses[encIndex] = entry
        end
    end
end

-- --------------------------------------------------
-- b) Live-Tracking ueber ENCOUNTER_START/ENCOUNTER_END
-- --------------------------------------------------

-- Der aktuell in der Bossguide-UI angezeigte Boss dient als einziger
-- Kontext fuer die Wipe-Zuordnung (siehe SetActiveContext) - wir
-- versuchen NICHT, encounterID gegen unsere eigene Boss-Liste zu
-- matchen, da wir das hier nicht verifizieren koennen. Lieber ein
-- Wipe nicht zaehlen als ihn dem falschen Boss zuzuschreiben.
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
TryRegisterEvent(trackerFrame, "ENCOUNTER_END")

trackerFrame:SetScript("OnEvent", function(_, event, ...)
    -- Vararg vor dem pcall in Locals kopieren: "..." ist innerhalb der
    -- pcall-Closure unten nicht mehr gueltig (eigener Funktionskontext,
    -- kein eigener Vararg).
    local _, encounterName, _, _, success = ...

    local ok = pcall(function()
        if event == "PLAYER_ENTERING_WORLD" then
            if activeContext then
                WeintCodex.EncounterTracking.RefreshFromLockout(
                    activeContext.instanceName, activeContext.nameFragment)
            end
        elseif event == "ENCOUNTER_END" then
            if not activeContext then return end
            if type(encounterName) ~= "string" or encounterName ~= activeContext.bossName then
                -- Unsichere Zuordnung - lieber nicht zaehlen als falsch zaehlen.
                return
            end

            local store = GetInstanceStore(activeContext.instanceName)
            if not store then return end
            EnsureFreshReset(store)

            local entry = store.bosses[activeContext.bossIndex] or {}
            if success == 1 then
                entry.cleared   = true
                entry.clearedAt = time()
            else
                entry.wipes = (entry.wipes or 0) + 1
            end
            store.bosses[activeContext.bossIndex] = entry
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
