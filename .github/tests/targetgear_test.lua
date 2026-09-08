-- Kopflose Pruefung der Zielausruestung aus dem Sim
-- (modules/targetgear.lua plus ihr Eingriff in PlanItem).
--
-- WARUM ES DIESEN LAUF GIBT. Die Steinempfehlung ist die am haeufigsten
-- gemeldete Rechnung dieses Addons, und der Grund dafuer ist strukturell:
-- sie war eine ZWEITE Optimierung neben der des Sims. Seit 3.0.2 gilt der
-- Zielzustand aus wowsims, wo es einen gibt - und damit haengt alles an
-- zwei Fragen, die im Spiel niemand nachpruefen kann:
--
--   1. Landet der Stein im RICHTIGEN Sockel? Die Reihenfolge ist die
--      ganze Aussage; ein verschobener Stein sieht aus wie eine
--      Empfehlung und ist keine.
--   2. Wird das RICHTIGE Teil erkannt? Ring 1 und Ring 2 koennen
--      dasselbe Teil sein, und ein Ziel gilt nur fuer die Ausruestung,
--      mit der gesimmt wurde.
--
-- Beides faellt im Spiel erst auf, wenn jemand seine Sockel von Hand
-- nachrechnet - genau wie der Fall, wegen dem es gem_plan_test.lua gibt.
--
--   lua5.1 .github/tests/targetgear_test.lua .

local ROOT = ...

--== Ein Client, so weit ihn diese Rechnung braucht =========================

function CreateFrame(kind, name)
    local f = {}
    function f:SetOwner() end
    function f:ClearLines() end
    function f:SetInventoryItem() end
    function f:SetHyperlink() end
    function f:SetItemByID() end
    function f:NumLines() return 0 end
    function f:RegisterEvent() end
    function f:UnregisterEvent() end
    function f:SetScript() end
    function f:Hide() end
    function f:Show() end
    function f:SetPoint() end
    function f:SetSize() end
    if name then
        _G[name] = f
        for i = 1, 40 do
            _G[name .. "TextLeft" .. i] = { GetText = function() return nil end,
                                            GetTextColor = function() return 1, 1, 1 end }
        end
    end
    return f
end

GameTooltip = { SetOwner = function() end }
UIParent    = {}
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

function GetLocale()    return "deDE" end
function UnitName()     return "Testchar", nil end
function UnitClass()    return "Druide", "DRUID", 11 end
function UnitLevel()    return 90 end
function GetRealmName() return "Ook Ook" end
function GetTime()      return 0 end
C_Timer = { After = function() end }

local SUBCLASS = { rot = 0, blau = 1, gelb = 2, lila = 3,
                   ["grün"] = 4, orange = 5, meta = 6, prismatic = 8 }

function GetItemInfo(id)
    local gem = WeintCodex_Gems and WeintCodex_Gems[id]
    if gem then
        return gem.name, "item:" .. tostring(id), 3, 90, 90, "", "", 1, "",
               "", 0, 3, SUBCLASS[gem.color]
    end
    return "Testgegenstand", "item:1", 4, 567, 90, "", "", 1, "INVTYPE_WEAPON"
end
function GetItemInfoInstant(id) return id, "", 3, "" end
function GetItemStats() return {} end
function GetInventoryItemLink() return nil end

WeintCodex = { SavedData = {}, Fonts = {}, Colors = {} }

dofile(ROOT .. "/core/names.lua")
dofile(ROOT .. "/data/enchants.lua")
dofile(ROOT .. "/data/gems.lua")
dofile(ROOT .. "/data/gem_stats.lua")
dofile(ROOT .. "/data/spec_profiles.lua")
dofile(ROOT .. "/data/reforge.lua")
dofile(ROOT .. "/modules/stat_match.lua")
dofile(ROOT .. "/modules/targetgear.lua")
dofile(ROOT .. "/modules/charakter.lua")

local TG = WeintCodex.TargetGear
local CH = WeintCodex.Charakter
local R  = WeintCodex_Reforge

local fails = 0
local function Check(name, ok, detail)
    print(string.format("%-68s %s", name,
        ok and "ok" or ("ABWEICHUNG  " .. tostring(detail or ""))))
    if not ok then fails = fails + 1 end
end

local function Name(id)
    local gem = id and WeintCodex_Gems[id]
    return gem and gem.name or tostring(id)
end

local function Reset()
    WeintCodex.SavedData = {}
end

--== Ein paar echte Steine aus data/gems.lua ================================
-- Bewusst echte IDs: die Farbpruefung (`GemMatchesSocket`) liest die
-- Unterklasse ueber GetItemInfo, und die kommt oben aus derselben Tabelle.

local ROT   = 76692   -- Feingeschliffener Rubellit (Beweglichkeit)
local GELB  = 76670   -- Aragonit (Beweglichkeit + Krit)
local BLAU  = 76680   -- Glitzernder Kunzit (Beweglichkeit + Treffer)
local META  = 76884   -- ein Meta-Stein
local KRIT  = 76697   -- reiner Kritstein (gelb)

--== Ein Plan-Kontext, wie ScanCharacter ihn baut ===========================

local function Plan(sockets, itemRef, bonus, headroom)
    local profile = WeintCodex_SpecProfiles.DRUID_FERAL
    local ctx = {
        pool     = CH.GemPool(profile, "DRUID_FERAL"),
        headroom = headroom or {},
        allowJC  = false,
    }
    return CH.PlanItem(sockets, bonus, bonus and "Sockelbonus" or nil,
                       profile, ctx, itemRef)
end

local function Sockets(...)
    local out = {}
    for i, color in ipairs({ ... }) do
        out[i] = { color = color, index = i }
    end
    return out
end

local function Ziel(items, opts)
    opts = opts or {}
    Reset()
    local ok, why = TG.Accept({
        id        = opts.id or "abc123",
        spec      = opts.spec or "DRUID_FERAL",
        character = opts.character or "",
        source    = "wowsims_json",
        created   = 1,
        items     = items,
    })
    return ok, why
end

--==========================================================================
-- 1) SOCKELREIHENFOLGE - die Aussage steht in der POSITION
--==========================================================================

do
    Ziel({ { slot = 5, itemId = 86918, gems = { ROT, BLAU, GELB } } })

    local plan = Plan(Sockets("rot", "gelb", "blau"),
                      { specKey = "DRUID_FERAL", slotId = 5, itemId = 86918 })

    Check("drei Sockel: jeder bekommt GENAU seinen Zielstein",
          plan.gems[1] == ROT and plan.gems[2] == BLAU and plan.gems[3] == GELB,
          Name(plan.gems[1]) .. " / " .. Name(plan.gems[2])
          .. " / " .. Name(plan.gems[3]))

    Check("die Quelle steht an jeder Zeile",
          plan.listed[1] == "sim" and plan.listed[3] == "sim",
          tostring(plan.listed[1]))

    Check("die Begruendung nennt den Sim",
          plan.why[1] and plan.why[1]:find("Sim-Ergebnis", 1, true) ~= nil,
          tostring(plan.why[1]))
end

--==========================================================================
-- 2) DIESELBE STEIN-ID MEHRFACH - kein Zusammenfassen, kein Verrutschen
--==========================================================================

do
    Ziel({ { slot = 5, itemId = 86918, gems = { ROT, ROT, ROT } } })

    local plan = Plan(Sockets("rot", "gelb", "blau"),
                      { specKey = "DRUID_FERAL", slotId = 5, itemId = 86918 })

    Check("dreimal derselbe Stein bleibt dreimal derselbe Stein",
          plan.gems[1] == ROT and plan.gems[2] == ROT and plan.gems[3] == ROT,
          table.concat({ tostring(plan.gems[1]), tostring(plan.gems[2]),
                         tostring(plan.gems[3]) }, "/"))
end

--==========================================================================
-- 3) META-SOCKEL - der Sim entscheidet auch dort, wo wir sonst nicht rechnen
--==========================================================================
-- Ohne Ziel bleibt der Meta-Sockel bei `bestGems.meta[1]`; DAS ist der
-- Rueckfall. Mit Ziel gilt das Ziel, sonst waere der eine Sockel, ueber den
-- der Sim am meisten weiss (Proc-Effekte!), der einzige ohne seine Aussage.

do
    Ziel({ { slot = 1, itemId = 86920, gems = { META, ROT } } })

    local plan = Plan(Sockets("meta", "rot"),
                      { specKey = "DRUID_FERAL", slotId = 1, itemId = 86920 })

    Check("Meta-Sockel folgt dem Ziel",
          plan.gems[1] == META, Name(plan.gems[1]))
    Check("und der farbige daneben ebenfalls",
          plan.gems[2] == ROT, Name(plan.gems[2]))
end

--==========================================================================
-- 4) LUECKE IM ZIEL - nur DIESER Sockel faellt zurueck, nicht das Teil
--==========================================================================
-- Eine 0 im Ziel heisst "keine Aussage" und ausdruecklich nicht "soll leer
-- bleiben": sie entsteht auch dann, wenn im Sim schlicht nichts eingestellt
-- war. Eine Empfehlung "nimm deinen Stein wieder heraus" waere der teure
-- Irrtum in der falschen Richtung.

do
    Ziel({ { slot = 5, itemId = 86918, gems = { ROT, 0 } } })

    local plan = Plan(Sockets("rot", "gelb"),
                      { specKey = "DRUID_FERAL", slotId = 5, itemId = 86918 })

    Check("der genannte Sockel folgt dem Ziel",
          plan.gems[1] == ROT and plan.listed[1] == "sim", Name(plan.gems[1]))

    Check("die Luecke bekommt eine eigene Empfehlung statt gar keiner",
          plan.gems[2] ~= nil, "leer geblieben")

    Check("und die sagt, dass sie NICHT aus dem Sim stammt",
          plan.listed[2] ~= "sim", tostring(plan.listed[2]))
end

--==========================================================================
-- 5) DAS ZIEL KENNT WENIGER SOCKEL ALS DAS TEIL (Guertelschnalle)
--==========================================================================

do
    Ziel({ { slot = 6, itemId = 89919, gems = { ROT, GELB } } })

    -- Der Guertel hat nach dem Simmen eine Schnalle bekommen: drei Sockel
    -- am Teil, zwei im Ziel.
    local plan = Plan(Sockets("rot", "gelb", "prismatic"),
                      { specKey = "DRUID_FERAL", slotId = 6, itemId = 89919 })

    Check("die genannten Sockel folgen dem Ziel",
          plan.gems[1] == ROT and plan.gems[2] == GELB,
          Name(plan.gems[1]) .. "/" .. Name(plan.gems[2]))

    Check("der Zusatzsockel wird selbst geplant, nicht uebersprungen",
          plan.gems[3] ~= nil and plan.listed[3] ~= "sim",
          tostring(plan.gems[3]) .. " / " .. tostring(plan.listed[3]))

    Check("und der Grund steht fest, statt zu verschwinden",
          plan.targetGaps and plan.targetGaps[3] ~= nil,
          tostring(plan.targetGaps and plan.targetGaps[3]))
end

--==========================================================================
-- 6) VERALTETES ZIEL - anderes Teil im Platz, also gilt es nicht
--==========================================================================

do
    Ziel({ { slot = 5, itemId = 86918, gems = { ROT, ROT } } })

    local plan = Plan(Sockets("rot", "gelb"),
                      { specKey = "DRUID_FERAL", slotId = 5, itemId = 99999 })

    Check("ein anderes Teil im Platz laesst das Ziel nicht gelten",
          plan.listed[1] ~= "sim" and plan.listed[2] ~= "sim",
          tostring(plan.listed[1]))

    Check("gerechnet wird trotzdem - es gibt eine Empfehlung",
          plan.gems[1] ~= nil, "keine Empfehlung")

    local _, why = TG.GemFor("DRUID_FERAL", 5, 99999, 1)
    Check("und der Grund ist nachlesbar (veraltet, nicht 'kein Ziel')",
          why and why:find("angelegt ist", 1, true) ~= nil, tostring(why))
end

--==========================================================================
-- 7) RING 1 / RING 2, SCHMUCK 1 / SCHMUCK 2, HAUPT- / NEBENHAND
--==========================================================================
-- Zwei GLEICHE Gegenstaende an zwei Plaetzen: zugeordnet wird ueber den
-- Platz. Ueber die Gegenstandsnummer allein waere hier nicht zu
-- unterscheiden, welcher Ring welche Steine bekommt.

do
    Ziel({
        { slot = 11, itemId = 86946, gems = { ROT } },
        { slot = 12, itemId = 86946, gems = { BLAU } },
        { slot = 13, itemId = 87172, gems = {} },
        { slot = 14, itemId = 86046, gems = {} },
        { slot = 16, itemId = 87176, gems = { GELB } },
        { slot = 17, itemId = 87176, gems = { KRIT } },
    })

    local ring1 = Plan(Sockets("rot"),
        { specKey = "DRUID_FERAL", slotId = 11, itemId = 86946 })
    local ring2 = Plan(Sockets("rot"),
        { specKey = "DRUID_FERAL", slotId = 12, itemId = 86946 })

    Check("Ring 1 und Ring 2 (gleiche Item-ID) bekommen verschiedene Steine",
          ring1.gems[1] == ROT and ring2.gems[1] == BLAU,
          Name(ring1.gems[1]) .. " / " .. Name(ring2.gems[1]))

    local mh = Plan(Sockets("gelb"),
        { specKey = "DRUID_FERAL", slotId = 16, itemId = 87176 })
    local oh = Plan(Sockets("gelb"),
        { specKey = "DRUID_FERAL", slotId = 17, itemId = 87176 })

    Check("Haupthand und Nebenhand ebenso",
          mh.gems[1] == GELB and oh.gems[1] == KRIT,
          Name(mh.gems[1]) .. " / " .. Name(oh.gems[1]))

    Check("Schmuck 1 und Schmuck 2 bleiben zwei Eintraege",
          TG.ItemFor("DRUID_FERAL", 13, 87172) ~= nil
          and TG.ItemFor("DRUID_FERAL", 14, 86046) ~= nil)
end

--==========================================================================
-- 8) UMSCHMIEDEN - vier Faelle, vier Antworten
--==========================================================================

do
    local hit  = R.INDEX.hit
    local crit = R.INDEX.crit
    local mast = R.INDEX.mastery

    local paar = R.PAIRS[R.PAIR_INDEX[mast][hit]]

    Ziel({
        { slot = 5, itemId = 86918, gems = {}, reforge = paar.id },
        { slot = 7, itemId = 89928, gems = {}, reforge = 0 },
    })

    local src, dst = TG.ReforgeFor("DRUID_FERAL", 5, 86918)
    Check("eine Umschmiedung im Ziel kommt als Statpaar zurueck",
          src == mast and dst == hit,
          tostring(src) .. "->" .. tostring(dst))

    local none = TG.ReforgeFor("DRUID_FERAL", 7, 89928)
    Check("KEINE Umschmiedung im Ziel ist eine Aussage (false), keine Luecke",
          none == false, tostring(none))

    local unknown, why = TG.ReforgeFor("DRUID_FERAL", 8, 12345)
    Check("ein Platz ohne Zieleintrag ist eine Luecke (nil) samt Grund",
          unknown == nil and why ~= nil, tostring(unknown))

    -- Ein Umschmiedewert ausserhalb der 56 Paare wird beim Annehmen
    -- verworfen: aus ihm wuerde drueben eine laufende Nummer im
    -- Umschmieder, die es nicht gibt - und die schmiedet etwas anderes,
    -- als auf der Seite steht.
    Ziel({ { slot = 5, itemId = 86918, gems = { ROT }, reforge = 9999 } })
    Check("ein unmoeglicher Umschmiedewert wird verworfen, nicht gereicht",
          TG.ReforgeFor("DRUID_FERAL", 5, 86918) == false)
end

--==========================================================================
-- 9) DER UEBERTRAGUNGSSTRING - hin und zurueck, Reihenfolge inklusive
--==========================================================================

do
    local text = "WCIMPORT:TG:DRUID_FERAL:abc123:1700000000:Testchar:wowsims_json:"
        .. "5|86918|" .. ROT .. "-0-" .. BLAU .. "|140|4420,"
        .. "11|86946||0|0"

    -- Der Umschlag wird von modules/sync.lua abgenommen; hier steht die
    -- Nutzlast, wie sie dort ankommt.
    local payload = text:gsub("^WCIMPORT:TG:", "")

    local entry, problem = TG.ParseTransfer(payload)

    Check("der String laesst sich zerlegen", entry ~= nil, tostring(problem))

    if entry then
        Check("Spezialisierung und Kennung stehen darin",
              entry.spec == "DRUID_FERAL" and entry.id == "abc123",
              entry.spec .. "/" .. entry.id)

        Check("zwei Plaetze", #entry.items == 2, tostring(#entry.items))

        local erst = entry.items[1]
        Check("DIE LEERE STELLE IN DER MITTE BLEIBT STEHEN",
              #erst.gems == 3 and erst.gems[1] == ROT
              and erst.gems[2] == 0 and erst.gems[3] == BLAU,
              table.concat({ tostring(erst.gems[1]), tostring(erst.gems[2]),
                             tostring(erst.gems[3]) }, "-"))

        Check("Umschmiedung und Verzauberung reisen mit",
              erst.reforge == 140 and erst.enchant == 4420,
              tostring(erst.reforge) .. "/" .. tostring(erst.enchant))

        Check("ein Platz ohne Steine ist kein Fehler",
              entry.items[2].slot == 11 and #entry.items[2].gems == 0)
    end
end

--==========================================================================
-- 10) WAS NICHT ANGENOMMEN WIRD
--==========================================================================

do
    Reset()

    local ok1, why1 = TG.Accept({ spec = "", items = { { slot = 1, itemId = 5 } } })
    Check("ohne Spezialisierung wird nichts angenommen", ok1 == false,
          tostring(why1))

    local ok2 = TG.Accept({ spec = "DRUID_FERAL", items = {} })
    Check("ohne einen einzigen Platz ebenfalls nicht", ok2 == false)

    -- EIN ZIEL OHNE STEIN UND OHNE UMSCHMIEDUNG IST KEINE AUSKUNFT: es
    -- saehe im Spiel aus wie "alles ist schon richtig" und brachte jede
    -- Empfehlung zum Schweigen.
    local ok3, why3 = TG.Accept({
        spec = "DRUID_FERAL",
        items = { { slot = 1, itemId = 86920, gems = { 0, 0 }, reforge = 0 } },
    })
    Check("und ein Ziel ohne Stein und ohne Umschmiedung auch nicht",
          ok3 == false, tostring(why3))
end

--==========================================================================
-- 11) DER SCHALTER, UND DER CHARAKTER
--==========================================================================

do
    Ziel({ { slot = 5, itemId = 86918, gems = { ROT } } })

    Check("angeschaltet gilt das Ziel", TG.SetFor("DRUID_FERAL") ~= nil)

    TG.SetEnabled(false)
    local weg, why = TG.SetFor("DRUID_FERAL")
    Check("abgeschaltet gilt es nicht mehr", weg == nil, tostring(why))

    local plan = Plan(Sockets("rot"),
                      { specKey = "DRUID_FERAL", slotId = 5, itemId = 86918 })
    Check("und PlanItem rechnet dann wieder selbst",
          plan.listed[1] ~= "sim", tostring(plan.listed[1]))

    TG.SetEnabled(true)

    -- Ein Ziel fuer einen ANDEREN Charakter gilt nicht: WeintCodex_SavedData
    -- ist kontoweit, und der Zweitcharakter derselben Klasse traegt sonst
    -- die Ausruestungsnummern des Mains.
    Ziel({ { slot = 5, itemId = 86918, gems = { ROT } } },
         { character = "Jemandanders" })

    local fremd, warum = TG.SetFor("DRUID_FERAL")
    Check("ein Ziel fuer einen anderen Charakter gilt nicht",
          fremd == nil and warum ~= nil, tostring(warum))

    Ziel({ { slot = 5, itemId = 86918, gems = { ROT } } },
         { character = "Testchar" })
    Check("das eigene dagegen schon", TG.SetFor("DRUID_FERAL") ~= nil)
end

--==========================================================================
-- 12) DIE TANK-HALTUNG TEILT SICH DAS ZIEL IHRER BASIS-SPEC
--==========================================================================
-- Der Sim kennt keine zwei Haltungen; ein Ziel beschreibt Steine und
-- Umschmiedungen, keine Spielweise.

do
    Ziel({ { slot = 5, itemId = 86918, gems = { ROT } } },
         { spec = "DRUID_GUARDIAN" })

    Check("*_OFFENSIVE findet das Ziel seiner Basis-Spec",
          TG.SetFor("DRUID_GUARDIAN_OFFENSIVE") ~= nil)
end

--==========================================================================
-- 13) DIE GANZE LISTE ERSETZT - was fehlt, gibt es nicht mehr
--==========================================================================

do
    Reset()

    TG.ReplaceAll({
        { spec = "DRUID_FERAL",   items = { { slot = 5, itemId = 1, gems = { ROT } } } },
        { spec = "DRUID_BALANCE", items = { { slot = 5, itemId = 2, gems = { BLAU } } } },
    })

    Check("beide angekommen", TG.Count() == 2, tostring(TG.Count()))

    TG.ReplaceAll({
        { spec = "DRUID_FERAL", items = { { slot = 5, itemId = 1, gems = { GELB } } } },
    })

    Check("die zweite verschwindet, weil sie nicht mehr geliefert wird",
          TG.Count() == 1 and TG.SetFor("DRUID_BALANCE") == nil,
          tostring(TG.Count()))

    local entry = TG.SetFor("DRUID_FERAL")
    Check("und die erste traegt den neuen Stand",
          entry and entry.items[5].gems[1] == GELB,
          entry and Name(entry.items[5].gems[1]))
end

print("")
if fails == 0 then
    print("Alles ok.")
    os.exit(0)
else
    print(fails .. " Abweichung(en).")
    os.exit(1)
end
