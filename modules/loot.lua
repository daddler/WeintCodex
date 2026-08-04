--------------------------------------------------
-- WeintCodex :: Loot-Erfassung
--
-- Erfasst Item-Zuteilungen aus CHAT_MSG_LOOT (Wuerfelvergabe UND
-- Meisterlooter-Zuteilung erzeugen dieselbe Meldung) und meldet sie ueber
-- die Companion-Warteschlange an den Discord-Bot (#loot).
--
-- Funktioniert OHNE Addon bei Mitspielern: CHAT_MSG_LOOT wird vom Server
-- an die gesamte Gruppe/den Raid gesendet, nicht nur an den Empfaenger -
-- es reicht, dass der Companion-Nutzer selbst im Raid ist.
--
-- Das Logging ist bewusst eng eingegrenzt (siehe IsTrackingActive): nur
-- innerhalb einer Raidinstanz, nur in einer echten Raidgruppe und nur bei
-- aktivem Meisterlooter. Dungeons, Szenarien, Worldbosse, Questbelohnungen
-- und Solo-Loot gehen den Bot nichts an - dort wird nichts gemeldet.
--
-- Nur Gegenstaende ab episch (Qualitaet 4) werden gemeldet, sonst wuerde
-- jeder Trash-Drop den #loot-Kanal fluten.
--
-- Alle GlobalStrings werden in Lua-Patterns uebersetzt, damit die
-- Erkennung unabhaengig von der Client-Sprache funktioniert, ohne harte
-- deutsche Strings zu pflegen.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.Loot = {}

local MIN_QUALITY = 4 -- Episch

--------------------------------------------------
-- GlobalString -> Lua-Pattern
--------------------------------------------------

local function EscapeMagic(str)
    return (str:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1"))
end

local function BuildPattern(globalString)
    if type(globalString) ~= "string" then return nil end

    local escaped = EscapeMagic(globalString)
    escaped = escaped:gsub("%%%%s", "(.-)")
    escaped = escaped:gsub("%%%%d", "(%%d+)")

    return "^" .. escaped .. "$"
end

-- Reihenfolge wichtig: die "_MULTIPLE"-Varianten (mit "xN") muessen vor
-- der jeweils einfachen Variante geprueft werden - sonst wuerde das
-- nicht-gierige ".-" der einfachen Variante die Mengenangabe faelschlich
-- mit in den Item-Link hineinziehen.
local PATTERNS = {
    { global = "LOOT_ITEM_SELF_MULTIPLE", self = true  },
    { global = "LOOT_ITEM_SELF",          self = true  },
    { global = "LOOT_ITEM_MULTIPLE",      self = false },
    { global = "LOOT_ITEM",               self = false },
}

for _, entry in ipairs(PATTERNS) do
    entry.pattern = BuildPattern(_G[entry.global])
end

--------------------------------------------------
-- Gueltigkeitspruefung: Loot-Logging nur im Raid-Kontext
--
-- Alle vier Bedingungen muessen gleichzeitig erfuellt sein:
--   1. Die eigene Discord-Rolle gibt das Melden frei (siehe core/access.lua) -
--      ein Extern-Raider soll nicht den Loot aus den Raids seiner eigenen
--      Gilde in unseren Discord melden
--   2. Spieler ist in einer Raidgruppe (nicht Solo, nicht 5er-Party)
--   3. Spieler steht in einer Raidinstanz (instanceType == "raid") -
--      damit fallen Dungeons ("party"), Szenarien ("scenario"),
--      Schlachtfelder ("pvp"/"arena") und Worldbosse (gar keine
--      Instanz) automatisch raus
--   4. Die Gruppe nutzt den Meisterlooter - nur dann wird Loot ueberhaupt
--      manuell vergeben und ist damit protokollierenswert
--------------------------------------------------

local function GetLootMethodSafe()
    if type(GetLootMethod) ~= "function" then return nil end

    local ok, method = pcall(GetLootMethod)
    if not ok then return nil end

    return method
end

function WeintCodex.Loot.IsTrackingActive()
    -- Bewusst hier und nicht in Report(): diese Funktion wird sowohl im
    -- direkten CHAT_MSG_LOOT-Pfad geprueft als auch im verzoegerten
    -- Nachpruefen von ReportIfEpic. Ein mitten in der Sitzung eintreffendes
    -- Zugriffsprofil kann so von keinem laufenden Retry ueberholt werden.
    if WeintCodex.Access and not WeintCodex.Access.Can("loot.report") then
        return false
    end

    if type(IsInRaid) ~= "function" or not IsInRaid() then return false end

    if type(IsInInstance) ~= "function" then return false end

    local inInstance, instanceType = IsInInstance()
    if not inInstance or instanceType ~= "raid" then return false end

    if GetLootMethodSafe() ~= "master" then return false end

    return true
end

--------------------------------------------------
-- Item-Qualitaet pruefen (mit kurzem Retry, falls die Item-Info direkt
-- nach dem Loot noch nicht im Client-Cache steht)
--------------------------------------------------

local function ReportIfEpic(playerName, itemLink, quantity, attempt)
    attempt = attempt or 1

    local ok, _, _, quality = pcall(GetItemInfo, itemLink)

    if ok and type(quality) == "number" then

        -- Erneute Pruefung: zwischen Loot-Meldung und aufgeloester Item-Info
        -- koennen bis zu drei Sekunden liegen (Retry unten), in denen der
        -- Spieler die Instanz verlassen oder der Raidleiter die Lootregel
        -- umgestellt haben kann.
        if quality >= MIN_QUALITY and WeintCodex.Loot.IsTrackingActive() then
            WeintCodex.Loot.Report(playerName, itemLink, quantity)
        end

        return
    end

    if attempt < 3 then
        C_Timer.After(1, function()
            ReportIfEpic(playerName, itemLink, quantity, attempt + 1)
        end)
    end
end

--------------------------------------------------
-- Nachricht an Companion melden
--------------------------------------------------

function WeintCodex.Loot.Report(playerName, itemLink, quantity)
    if not WeintCodex.Companion or not WeintCodex.Companion.Send then return end
    if type(playerName) ~= "string" or type(itemLink) ~= "string" then return end

    local payload = table.concat({
        "WCEXPORT:LOOT",
        playerName,
        tostring(quantity or 1),
        itemLink,
    }, ":")

    WeintCodex.Companion.Send("loot", payload)
end

--------------------------------------------------
-- CHAT_MSG_LOOT abonnieren
--------------------------------------------------

local lootFrame = CreateFrame("Frame")

local function TryRegisterEvent(frame, eventName)
    local ok = pcall(frame.RegisterEvent, frame, eventName)
    return ok
end

TryRegisterEvent(lootFrame, "CHAT_MSG_LOOT")

lootFrame:SetScript("OnEvent", function(_, event, message)
    if type(message) ~= "string" then return end

    -- Vor dem teuren Pattern-Matching: gilt hier ueberhaupt geloggt zu
    -- werden? (Raidgruppe + Raidinstanz + Meisterlooter)
    if not WeintCodex.Loot.IsTrackingActive() then return end

    for _, entry in ipairs(PATTERNS) do

        if entry.pattern then

            if entry.self then

                local itemLink, quantity = message:match(entry.pattern)

                if itemLink then
                    ReportIfEpic(UnitName("player"), itemLink, tonumber(quantity) or 1)
                    return
                end

            else

                local playerName, itemLink, quantity = message:match(entry.pattern)

                if playerName then
                    ReportIfEpic(playerName, itemLink, tonumber(quantity) or 1)
                    return
                end

            end

        end

    end
end)
