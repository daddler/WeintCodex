-- Kopflose Pruefung der Verzauberungserkennung (modules/charakter.lua).
--
-- WARUM ES DIESEN LAUF GIBT: dieselbe Fehlerklasse ist dreimal ausgeliefert
-- worden, und sie nahm jedes Mal denselben Ausgang - eine WERTZEILE DES
-- GEGENSTANDS stand im Charakterfenster als Verzauberung da, samt der Marke
-- "(ID ... abweichend)" an einem korrekt verzauberten Teil:
--
--   2.0.0.3  "+1.201 Meisterschaft" auf Handschuhen (Zeilen unlesbar, die
--            obere gewann)
--   2.0.1.0  "+894 Meisterschaft" auf Handgelenken (Rangfolge: der
--            Gegenstandswert traf den Namen einer Verzauberung)
--   2.9.0.1  "+554 Meisterschaft" auf einer Waffe mit "Windweise" (die
--            Namenszeile hing an unserer eigenen Uebersetzung)
--
-- Die Erkennung liest nichts als Tooltiptext. Sie ist damit genau die Sorte
-- Rechnung, die ohne Spiel pruefbar sein muss - im Spiel faellt sie erst
-- auf, wenn jemand ein Bild seines Charakterfensters schickt.
--
--   lua5.1 .github/tests/enchant_scan_test.lua .

local ROOT = ...

--== Ein Client, so weit ihn diese Rechnung braucht ==========================
-- Tooltipzeilen kommen aus `lines`: { text, gruen }. Mehr fragt die
-- Erkennung den Client nicht - genau deshalb ist sie hier pruefbar.

local currentLines = {}

local function MakeFontString()
    local fs = { text = nil, r = 1, g = 1, b = 1 }
    function fs:GetText() return self.text end
    function fs:GetTextColor() return self.r, self.g, self.b end
    return fs
end

local tooltipStrings = {}

local function LoadTooltip(name)
    for i, entry in ipairs(currentLines) do
        local fs = tooltipStrings[name] and tooltipStrings[name][i]
        if fs then
            fs.text = entry[1]
            if entry[2] then fs.r, fs.g, fs.b = 0, 1, 0
            else               fs.r, fs.g, fs.b = 1, 1, 1 end
        end
    end
    for i = #currentLines + 1, 40 do
        local fs = tooltipStrings[name] and tooltipStrings[name][i]
        if fs then fs.text = nil end
    end
end

function CreateFrame(kind, name, _parent, _template)
    local f = {}
    function f:SetOwner() end
    function f:ClearLines() end
    function f:SetInventoryItem() LoadTooltip(name) end
    function f:SetHyperlink()     LoadTooltip(name) end
    function f:SetItemByID()      LoadTooltip(name) end
    function f:NumLines()         return #currentLines end
    function f:RegisterEvent() end
    function f:UnregisterEvent() end
    function f:SetScript() end
    function f:Hide() end
    function f:Show() end
    function f:SetPoint() end
    function f:SetSize() end
    if name then
        _G[name] = f
        tooltipStrings[name] = {}
        for i = 1, 40 do
            local fs = MakeFontString()
            tooltipStrings[name][i] = fs
            _G[name .. "TextLeft" .. i] = fs
        end
    end
    return f
end

-- Alles, was beim Laden der beiden Dateien am Client haengt.
GameTooltip        = { SetOwner = function() end }
UIParent           = {}
ITEM_MOD_STRENGTH_SHORT       = "Stärke"
ITEM_MOD_STAMINA_SHORT        = "Ausdauer"
ITEM_MOD_AGILITY_SHORT        = "Beweglichkeit"
ITEM_MOD_INTELLECT_SHORT      = "Intelligenz"
ITEM_MOD_SPIRIT_SHORT         = "Willenskraft"
ITEM_MOD_HIT_RATING           = "Trefferwertung"
ITEM_MOD_CRIT_RATING          = "kritische Trefferwertung"
ITEM_MOD_HASTE_RATING         = "Tempowertung"
ITEM_MOD_MASTERY_RATING_SHORT = "Meisterschaft"
ITEM_MOD_EXPERTISE_RATING     = "Waffenkunde"
ITEM_MOD_DODGE_RATING         = "Ausweichwertung"
ITEM_MOD_PARRY_RATING         = "Parierwertung"
ITEM_REFORGED                 = "Umgeschmiedet"
ENCHANTED_TOOLTIP_LINE        = "Verzaubert: %s"
ITEM_SPELL_TRIGGER_ONUSE      = "Benutzen: %s"
ITEM_SPELL_TRIGGER_ONEQUIP    = "Ausgerüstet: %s"
ITEM_SOCKET_BONUS             = "Sockelbonus: %s"
RESISTANCE0_NAME              = "Rüstung"
EMPTY_SOCKET_RED              = "Roter Sockel"
EMPTY_SOCKET_YELLOW           = "Gelber Sockel"
EMPTY_SOCKET_BLUE             = "Blauer Sockel"
EMPTY_SOCKET_META             = "Metasockel"
EMPTY_SOCKET_PRISMATIC        = "Prismatischer Sockel"

function GetItemInfo(id)         return "Testgegenstand", "item:1", 4, 567, 90, "", "", 1, "INVTYPE_WEAPON" end
function GetItemInfoInstant(id)  return 1, "", 4, "INVTYPE_WEAPON" end
function GetItemStats()          return {} end
function GetLocale()             return "deDE" end
function UnitName()              return "Testchar" end
function UnitClass()             return "Mönch", "MONK", 10 end
function UnitLevel()             return 90 end
function GetRealmName()          return "Ook Ook" end
function GetTime()               return 0 end
function C_Timer_After()         end
C_Timer = { After = function() end }

WeintCodex = { SavedData = {}, Fonts = {}, Colors = {} }

dofile(ROOT .. "/data/enchants.lua")
dofile(ROOT .. "/data/gems.lua")
dofile(ROOT .. "/data/gem_stats.lua")
dofile(ROOT .. "/data/spec_profiles.lua")
dofile(ROOT .. "/modules/stat_match.lua")
dofile(ROOT .. "/modules/charakter.lua")

local CH = WeintCodex.Charakter

local fails = 0
local function Check(name, ok, detail)
    print(string.format("%-56s %s", name, ok and "ok" or ("ABWEICHUNG  " .. tostring(detail or ""))))
    if not ok then fails = fails + 1 end
end

local function Resolve(lines, enchId, enchSlot)
    currentLines = lines
    CH.ClearCache()
    return CH.ResolveEnchant(16, enchId, "|Hitem:87172::::::::90:::::|h[Xifeng]|h", enchSlot)
end

--== Der gemeldete Fall =====================================================
-- Xifeng, Langschwert des titanischen Waechters, verzaubert mit Windweise.
-- Jede Wertzeile des Gegenstands ist gruen, und "+554 Meisterschaft" liegt
-- unter MAX_ENCHANT_VALUE - sie sieht also aus wie eine Verzauberung.
-- Was sie ausschliesst, ist unser eigener Eintrag: Verzauberung 4441 hat
-- keine Werte, also kann keine Wertzeile sie sein.
local XIFENG = {
    { "Xifeng, Langschwert des titanischen Wächters" },
    { "Gegenstandsstufe 567" },
    { "Aufwertungsgrad: 2/2" },
    { "Seelengebunden" },
    { "Einhändig" },
    { "Umgeschmiedet" },
    { "11.687 - 21.706 Schaden" },
    { "+936 Stärke",                                   true },
    { "+1.524 Ausdauer",                               true },
    { "+413 Trefferwert",                              true },
    { "+274 Tempo (Umgeschmiedet aus Trefferwert)",    true },
    { "+554 Meisterschaft",                            true },
    { "Windweise",                                     true },
    { "+320 Tempo",                                    true },
    { "Sockelbonus: +60 Stärke",                       true },
    { "Haltbarkeit 84 / 110" },
    { "Benötigt Stufe 90" },
}

do
    local res = Resolve(XIFENG, 4441, "Waffe")
    Check("Waffe mit Windweise: die Namenszeile gewinnt",
          res and res.name == "Windweise", res and res.name)
    Check("... und wird nicht als Widerspruch gemeldet",
          res and not res.mismatch and not res.unknownName,
          res and (res.mismatch and "mismatch" or "unknownName"))
    Check("... eine Proc-Verzauberung traegt keine Werte",
          res and res.stats == nil, res and "stats gesetzt")
    Check("... und die ID bleibt stehen",
          res and res.id == 4441, res and res.id)
end

--== Dieselbe Waffe, aber unser Name ist falsch =============================
-- Der eigentliche Fehler von 2.9.0.0 war nicht die falsche Uebersetzung,
-- sondern dass die Erkennung daran hing: stimmte der Name nicht, fiel die
-- echte Zeile aus dem Scan und der Gegenstandswert rueckte nach. Der Name
-- ist das unzuverlaessigste Feld von data/enchants.lua - er darf die
-- Erkennung nicht tragen. Geprueft wird das an einem Eintrag, den wir hier
-- absichtlich falsch schreiben.
do
    local keep = WeintCodex_Enchants[4441].name
    WeintCodex_Enchants[4441].name = "Lied des Windes"
    local res = Resolve(XIFENG, 4441, "Waffe")
    WeintCodex_Enchants[4441].name = keep

    Check("Falscher DB-Name: der Client-Name steht trotzdem da",
          res and res.name == "Windweise", res and res.name)
    Check("... gemeldet wird die Namensluecke, kein Widerspruch",
          res and res.unknownName and not res.mismatch,
          res and (res.mismatch and "mismatch" or "nichts gemeldet"))
end

--== Wertverzauberungen bleiben, wie sie waren ==============================
-- Handgelenke, "+180 Stärke" (4429). Die Wertzeilen des Gegenstands stehen
-- darueber und sind vierstellig bzw. tragen ihre Umschmiede-Herkunft.
do
    local BRACERS = {
        { "Armschienen des Titanenwächters" },
        { "Gegenstandsstufe 553" },
        { "+894 Meisterschaft",                            true },
        { "+1.201 Ausdauer",                               true },
        { "+298 Parieren (Umgeschmiedet aus Waffenkunde)", true },
        { "+180 Stärke",                                   true },
        { "Benötigt Stufe 90" },
    }
    local res = Resolve(BRACERS, 4415, "Handgelenke")
    Check("Handgelenke: die Verzauberungszeile, nicht der Itemwert",
          res and res.stats and res.stats.strength == 180,
          res and res.stats and ("strength=" .. tostring(res.stats.strength)))
    Check("... ohne Widerspruchsmeldung",
          res and not res.mismatch, res and "mismatch")
end

--== Eine Beschriftung des Clients ist keine Verzauberung ====================
-- "Benutzen:"/"Ausgerüstet:" sind gruen und koennen ohne Zahl auskommen.
-- Sie gehoeren dem Gegenstand - und stuenden sonst als Verzauberung da,
-- seit eine Namenszeile nicht mehr in unserer Tabelle stehen muss.
do
    local WITH_USE = {
        { "Xifeng, Langschwert des titanischen Wächters" },
        { "+554 Meisterschaft",                       true },
        { "Ausgerüstet: Erhöht euer Tempo geringfügig.", true },
        { "Benutzen: Schärft die Klinge.",            true },
        { "Windweise",                                true },
    }
    local res = Resolve(WITH_USE, 4441, "Waffe")
    Check("Client-Beschriftungen zaehlen nicht als Verzauberung",
          res and res.name == "Windweise", res and res.name)
end

--== Ohne jede Verzauberungszeile wird nichts erfunden =======================
-- Traegt der Tooltip nur Wertzeilen des Gegenstands, ist der Scan
-- gescheitert. Dann ist der Name aus der Datenbank die ehrlichere Antwort
-- als eine geratene Gegenstandszeile - und die Zeile sagt das auch (?).
do
    local NO_ENCHANT = {
        { "Xifeng, Langschwert des titanischen Wächters" },
        { "+936 Stärke",       true },
        { "+554 Meisterschaft", true },
    }
    local res = Resolve(NO_ENCHANT, 4441, "Waffe")
    Check("Ohne Namenszeile wird kein Itemwert eingesetzt",
          res and res.name == "Windweise" and res.unverified,
          res and res.name)
end

--== Alle sechs Waffenverzauberungen sind Procs =============================
-- Ein Eintrag mit Werten wuerde hier stillschweigend wieder Wertzeilen
-- zulassen. Die Aussage "diese Verzauberung traegt keine Zahlen" ist das,
-- woran die Erkennung haengt.
do
    local ok = true
    local bad
    for _, id in ipairs({ 4441, 4442, 4443, 4444, 4445, 4446 }) do
        local db = WeintCodex_Enchants[id]
        if not db or db.slot ~= "Waffe" or db.stats then ok = false; bad = id end
    end
    Check("Waffenverzauberungen stehen ohne Werte in der Datenbank", ok, bad)
end

print("")
if fails > 0 then
    print(fails .. " Abweichung(en).")
    os.exit(1)
end
print("Alles bestanden.")
