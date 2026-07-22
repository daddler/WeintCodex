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
-- Item-Qualitaet pruefen (mit kurzem Retry, falls die Item-Info direkt
-- nach dem Loot noch nicht im Client-Cache steht)
--------------------------------------------------

local function ReportIfEpic(playerName, itemLink, quantity, attempt)
    attempt = attempt or 1

    local ok, _, _, quality = pcall(GetItemInfo, itemLink)

    if ok and type(quality) == "number" then

        if quality >= MIN_QUALITY then
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
