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
--
-- DER FORTSCHRITT GEHOERT DEM CHARAKTER, NICHT DEM KONTO. Ein
-- Schlachtzugs-Lockout ist in MoP an den einzelnen Charakter gebunden:
-- der Main hat Immerseus gelegt, der Twink steht am Mittwoch trotzdem
-- vor einem vollen Raid. Bis 2.3.1.0 lag alles kontoweit unter
-- SavedData.encounterProgress[instanz] - jeder Twink sah damit den
-- Fortschritt des zuletzt gespielten Charakters, und der Lockout-Import
-- konnte das nicht heilen: er setzt Kills, aber er nimmt keine zurueck
-- (RefreshFromLockout kennt nur "isKilled -> cleared = true", weil ein
-- fehlender Lockout-Eintrag genauso gut "Server hat die Raid-Info noch
-- nicht geschickt" heissen kann).
--
-- Ablage deshalb:
--   SavedData.encounterProgress.characters["Name-Realm"][instanz]
--
-- Die alten kontoweiten Zweige liegen direkt unter encounterProgress und
-- sind daran erkennbar, dass ihr Wert selbst ein Instanzspeicher ist
-- (bosses/resetStamp). Sie werden einmalig auf den gerade eingeloggten
-- Charakter gehoben und dann entfernt - "cleared" holt sich jeder andere
-- Charakter binnen Sekunden aus der Lockout-API zurueck, die selbst
-- gezaehlten Wipes und der beste Versuch dagegen sind nirgends sonst
-- gespeichert und waeren beim Wegwerfen endgueltig weg.
-- --------------------------------------------------

local characterKey = nil

-- "Name-Realm" des eingeloggten Charakters. Leer heisst: der Client kennt
-- den Namen noch nicht (vor PLAYER_LOGIN) - dann wird nichts angelegt und
-- nichts gelesen, statt einen namenlosen Topf zu fuellen, den spaeter
-- niemand mehr zuordnen kann.
local function CharacterKey()
    if characterKey then return characterKey end
    if not (WeintCodex.Names and WeintCodex.Names.Me) then return nil end
    local ok, _, _, full = pcall(WeintCodex.Names.Me)
    if not ok or type(full) ~= "string" or full == "" then return nil end
    characterKey = full
    return characterKey
end

-- Ein Zweig unterhalb von encounterProgress, der noch aus der kontoweiten
-- Zeit stammt. Absichtlich am Inhalt erkannt und nicht an einer Merkerzahl:
-- so bleibt die Migration auch dann richtig, wenn eine alte und eine neue
-- Addonversion sich abwechseln.
local function LooksLikeInstanceStore(value)
    return type(value) == "table"
       and (type(value.bosses) == "table" or type(value.resetStamp) == "number")
end

local function GetCharacterProgress()
    local sd = WeintCodex.SavedData
    if not sd then return nil end

    local key = CharacterKey()
    if not key then return nil end

    sd.encounterProgress = sd.encounterProgress or {}
    local root = sd.encounterProgress

    root.characters = root.characters or {}
    root.characters[key] = root.characters[key] or {}
    local mine = root.characters[key]

    for name, value in pairs(root) do
        if name ~= "characters" and LooksLikeInstanceStore(value) then
            -- Nicht ueberschreiben: hat dieser Charakter die Instanz schon
            -- selbst gefuehrt, ist sein eigener Stand der genauere.
            if mine[name] == nil then mine[name] = value end
            root[name] = nil
        end
    end

    return mine
end

local function GetInstanceStore(instanceName)
    local progress = GetCharacterProgress()
    if not progress then return nil end
    progress[instanceName] = progress[instanceName] or { resetStamp = 0, bosses = {} }
    -- bestTries liegt bewusst NEBEN bosses: EnsureFreshReset leert nur
    -- store.bosses, der beste Versuch soll den Wochenreset ueberleben.
    -- Lazy angelegt, damit alte SavedVariables ohne den Zweig migrieren.
    progress[instanceName].bestTries = progress[instanceName].bestTries or {}
    return progress[instanceName]
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
TryRegisterEvent(trackerFrame, "ENCOUNTER_START")
TryRegisterEvent(trackerFrame, "ENCOUNTER_END")

-- --------------------------------------------------
-- c) Best Try: niedrigste Boss-Rest-HP eines Versuchs
--
-- Waehrend eines Encounters werden die Boss-Units gedrosselt abgetastet
-- und das Minimum gemerkt. Beim Wipe landet dieses Minimum als "bester
-- Versuch" in store.bestTries. Bewusst ein gedrosselter OnUpdate statt
-- C_Timer.NewTicker/UNIT_HEALTH_FREQUENT: keine API-Abhaengigkeit, die
-- hier nicht gegen einen echten Client verifiziert werden kann.
-- --------------------------------------------------

local BOSS_UNITS       = { "boss1", "boss2", "boss3", "boss4", "boss5" }
local SAMPLE_INTERVAL  = 0.5   -- Sekunden zwischen zwei Messungen
local BOSSLESS_TIMEOUT = 20    -- so lange ohne Bossunit -> Tracking beenden

-- Aggregiert ueber ALLE gerade existierenden Boss-Units (Summe Leben /
-- Summe Maximalleben) statt nur boss1 - sonst waeren Rats-Encounter
-- (Rat der Schwarzfaust, Paragons) nicht sinnvoll messbar.
-- Bekannte Ungenauigkeit: taucht mitten im Kampf eine zusaetzliche Unit
-- mit vollem Leben auf, springt der Aggregatwert hoch. Da nur das
-- Minimum des Laufs zaehlt, schmeichelt das dem Ergebnis leicht,
-- verfaelscht es aber nie nach oben.
local function SampleBossHealthPct()
    local cur, max = 0, 0
    for _, unit in ipairs(BOSS_UNITS) do
        if SafeCall(UnitExists, unit) then
            local h  = SafeCall(UnitHealth, unit)
            local hm = SafeCall(UnitHealthMax, unit)
            if type(h) == "number" and type(hm) == "number" and hm > 0 then
                cur = cur + h
                max = max + hm
            end
        end
    end
    if max <= 0 then return nil end   -- keine Bossunit sichtbar: Sample verwerfen
    return (cur / max) * 100
end

local trackRun = nil   -- { best, accum, sinceBoss }

local function StopHealthTracking()
    trackRun = nil
    trackerFrame:SetScript("OnUpdate", nil)
end

local function StartHealthTracking()
    trackRun = { best = nil, accum = 0, sinceBoss = 0 }
    trackerFrame:SetScript("OnUpdate", function(_, elapsed)
        pcall(function()
            local run = trackRun
            if not run then return end

            run.accum = run.accum + elapsed
            if run.accum < SAMPLE_INTERVAL then return end
            run.accum = 0

            local pct = SampleBossHealthPct()
            if pct then
                run.sinceBoss = 0
                if not run.best or pct < run.best then run.best = pct end
            else
                -- Watchdog: falls ENCOUNTER_END nie kommt (Disconnect,
                -- Zonenwechsel), darf die Schleife nicht ewig weiterlaufen.
                run.sinceBoss = run.sinceBoss + SAMPLE_INTERVAL
                if run.sinceBoss >= BOSSLESS_TIMEOUT then
                    StopHealthTracking()
                end
            end
        end)
    end)
end

trackerFrame:SetScript("OnEvent", function(_, event, ...)
    -- Vararg vor dem pcall in Locals kopieren: "..." ist innerhalb der
    -- pcall-Closure unten nicht mehr gueltig (eigener Funktionskontext,
    -- kein eigener Vararg).
    local _, encounterName, _, _, success = ...

    local ok = pcall(function()
        if event == "PLAYER_ENTERING_WORLD" then
            -- Zonenwechsel/Geistheiler: laufendes HP-Tracking beenden,
            -- damit kein State ueber Encounter hinweg leckt.
            StopHealthTracking()
            WeintCodex.EncounterTracking.RefreshAll()
            RequestLockoutUpdate()

        elseif event == "UPDATE_INSTANCE_INFO" then
            WeintCodex.EncounterTracking.RefreshAll()

        elseif event == "ENCOUNTER_START" then
            -- Gleiche Zuordnungsregel wie beim Wipe unten: nur messen,
            -- wenn der Boss auch wirklich der im Bossguide gewaehlte ist.
            StopHealthTracking()
            if activeContext
                and type(encounterName) == "string"
                and encounterName == activeContext.bossName then
                StartHealthTracking()
            end

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
                        -- Bewusst KEIN bestTry bei einem Kill: "Best 0,0%"
                        -- waere als Sidebar-Text sinnlos, und der letzte
                        -- echte Progress-Wert bleibt so ueber den Reset
                        -- hinaus als Kontext erhalten.
                    else
                        entry.wipes = (entry.wipes or 0) + 1

                        local best = trackRun and trackRun.best
                        if type(best) == "number" then
                            store.bestTries = store.bestTries or {}
                            local prev = store.bestTries[activeContext.bossIndex]
                            if type(prev) ~= "number" or best < prev then
                                store.bestTries[activeContext.bossIndex] = best
                            end
                        end
                    end
                    store.bosses[activeContext.bossIndex] = entry
                    NotifyChanged(activeContext.instanceName)
                end
            end

            -- Immer beenden, auch wenn activeContext nicht passte - sonst
            -- laeuft die OnUpdate-Schleife nach dem Kampf weiter.
            StopHealthTracking()

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

-- Gibt { cleared, wipes, clearedAt, bestTry } fuer instanceName/bossIndex
-- zurueck. Fehlt jegliche Information, ist cleared=false, wipes=0 und
-- bestTry=nil (neutraler "Offen"-Zustand, nie geraten).
function WeintCodex.EncounterTracking.GetStatus(instanceName, bossIndex)
    local store = GetInstanceStore(instanceName)
    if not store then
        return { cleared = false, wipes = 0, clearedAt = nil, bestTry = nil }
    end
    EnsureFreshReset(store)

    -- VOR dem entry-Check lesen: nach dem Wochenreset ist store.bosses
    -- leer, der Best Try aus den Vorwochen soll aber weiter angezeigt
    -- werden - genau dafuer liegt er ausserhalb von store.bosses.
    local bestTry = store.bestTries and store.bestTries[bossIndex]

    local entry = store.bosses[bossIndex]
    if not entry then
        return { cleared = false, wipes = 0, clearedAt = nil, bestTry = bestTry }
    end

    return {
        cleared   = entry.cleared == true,
        wipes     = entry.wipes or 0,
        clearedAt = entry.clearedAt,
        bestTry   = bestTry,
    }
end
