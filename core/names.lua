--------------------------------------------------
-- WeintCodex :: Charakternamen
--------------------------------------------------
-- Ein Charaktername erreicht das Addon aus drei Richtungen, und jede
-- schreibt ihn anders:
--
--   * der Client selbst  -> UnitName("player"), IMMER ohne Realm
--   * WarcraftLogs (ueber Bot und Companion) -> nackt bei eigenem
--     Realm, "Name-Realm" bei realmfremden Spielern
--   * die Companion-Auswahl -> die Schreibweise des Berichts
--
-- Bis 1.3.2.3 wurde roh mit == verglichen. Das ging genau so lange
-- gut, wie alle drei zufaellig gleich schrieben - und schlug sonst
-- lautlos fehl: der Filter "Nur ich" fand nichts und zeigte
-- stattdessen den ganzen Raid, die Academy hielt einen fremden
-- Charakter fuer den eigenen. Diese Datei ist die eine Stelle, an
-- der diese Frage beantwortet wird.
--
-- Drei Entscheidungen stehen hier, die keine Geschmacksfragen sind:
--
-- 1. Der Realm wird von Leerzeichen befreit. GetRealmName() liefert
--    "Die Aldor", WarcraftLogs schreibt "DieAldor". Dieselbe
--    Bereinigung macht modules/companion.lua beim Melden der Twinks
--    schon lange.
--
-- 2. Verglichen wird ohne Gross-/Kleinschreibung ueber strlower
--    (WoWs locale-bewusste Fassung, Rueckfall auf string.lower).
--    Umlaute normalisiert Lua 5.1 nicht - dafuer sorgt die Companion,
--    indem sie den gemeldeten Namen unveraendert durchreicht.
--
-- 3. EIN FEHLENDER REALM IST EIN PLATZHALTER, KEIN WIDERSPRUCH.
--    Equal("Aldrin", "Aldrin-Everlook") ist wahr. Anders ginge es
--    nicht: der Client kennt nur den nackten Namen, WarcraftLogs
--    qualifiziert nur realmfremde Zeilen. Der Preis ist, dass zwei
--    gleichnamige Spieler von verschiedenen Realms in einem Raid
--    zusammenfallen - selten, waehrend die strenge Variante den
--    Normalfall bricht.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.Names = {}

local lower = strlower or string.lower

-- "Name-Realm" -> "Name", "Realm". Ohne Bindestrich bleibt der Realm
-- leer. Getrennt wird am ERSTEN Bindestrich: Realmnamen duerfen
-- welche enthalten ("Kirin-Tor"), Charakternamen nicht.
function WeintCodex.Names.Split(value)

    if type(value) ~= "string" or value == "" then
        return "", ""
    end

    local base, realm = value:match("^([^%-]+)%-(.+)$")

    if not base then
        return (value:gsub("%s+$", "")), ""
    end

    return base, (realm:gsub("%s+", ""))

end

-- Vergleichsform der Basis (ohne Realm, klein). Nur fuer Vergleiche
-- und Tabellenschluessel gedacht - angezeigt wird nie diese Fassung,
-- sondern immer die Schreibweise der jeweiligen Quelle.
function WeintCodex.Names.Normalize(value)

    local base = WeintCodex.Names.Split(value)

    return lower(base)

end

-- Sind das derselbe Charakter? Siehe Regel 3 oben: der Realm zaehlt
-- nur mit, wenn ihn BEIDE Seiten mitbringen.
function WeintCodex.Names.Equal(a, b)

    local baseA, realmA = WeintCodex.Names.Split(a)
    local baseB, realmB = WeintCodex.Names.Split(b)

    if baseA == "" or baseB == "" then
        return false
    end

    if lower(baseA) ~= lower(baseB) then
        return false
    end

    if realmA ~= "" and realmB ~= "" then
        return lower(realmA) == lower(realmB)
    end

    return true

end

-- Der eingeloggte Charakter: Basis, Realm, "Name-Realm".
function WeintCodex.Names.Me()

    local base  = UnitName("player") or ""
    local realm = (GetRealmName() or ""):gsub("%s+", "")

    if base == "" then
        return "", realm, ""
    end

    if realm == "" then
        return base, "", base
    end

    return base, realm, base .. "-" .. realm

end

-- Den passenden Eintrag einer Liste finden und IN DEREN Schreibweise
-- zurueckgeben. Wer einen Namen weiterreicht, soll die Schreibweise
-- der Quelle behalten, nicht die des Suchbegriffs - sonst findet die
-- naechste Suche in derselben Quelle nichts mehr.
function WeintCodex.Names.Match(candidate, list)

    if type(list) ~= "table" then return nil end

    for _, entry in ipairs(list) do
        if WeintCodex.Names.Equal(entry, candidate) then
            return entry
        end
    end

    return nil

end
