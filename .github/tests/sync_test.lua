-- Kopflose Pruefung von modules/sync.lua - insbesondere des
-- WCIMPORT-Wegs ueber die EditBox auf *Import*.
--
-- WARUM ES DIESEN LAUF GIBT. Ein Spieler meldete, ein von WeintCompanion
-- nachweislich korrekt erzeugter TG-Transferstring werde beim Einfuegen
-- auf der Import-Seite mit "kein einziger Ausruestungsplatz" abgewiesen,
-- obwohl TG.ParseTransfer denselben String isoliert (per
-- targetgear_test.lua) einwandfrei liest. Ein DEBUG-Log im Spiel klaerte
-- die Ursache: das Spiel verdoppelt beim Einfuegen von Text in eine
-- EditBox (Strg+V ebenso wie Tippen) jedes woertliche "|" zu "||" - die
-- eingebaute Schreibweise fuer EIN Pipe-Zeichen, damit ein einzelnes "|"
-- nicht als Beginn eines Farbcodes gelesen wird. Jede Zeile des
-- WCIMPORT-Formats trennt ihre Felder mit "|"; ohne Gegenmassnahme kommt
-- bei TG.ParseTransfer() ein Payload an, in dem jeder Feldtrenner
-- doppelt steht und jedes zweite Feld leer ausfaellt (belegt: 9 statt 5
-- Teile je Zeile, ItemID durchweg nil).
--
-- WeintCodex.Sync.UndoEditBoxPipeEscape() macht genau das rueckgaengig,
-- und zwar NUR am EditBox-Eingang - die automatische Zustellung ueber
-- die SavedVariables-Bruecke (companion.lua, raid_import -> QuickImport)
-- durchlaeuft diese Funktion bewusst nicht, weil ihr Payload nie durch
-- eine EditBox lief und ein dort absichtlich leeres Feld ("||") sonst
-- faelschlich mit dem Feld daneben verschmolzen wuerde.
--
--   lua5.1 .github/tests/sync_test.lua .

local ROOT = ...

--== Ein Client, so weit ihn diese Rechnung braucht =========================
-- (dieselbe Ausstattung wie targetgear_test.lua - TG.Accept braucht sie)

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
function UnitName()     return "Njiah", nil end
function UnitClass()    return "Todesritter", "DEATHKNIGHT", 6 end
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
function WeintCodex.Icon(path, size) return "" end

dofile(ROOT .. "/core/names.lua")
dofile(ROOT .. "/data/enchants.lua")
dofile(ROOT .. "/data/gems.lua")
dofile(ROOT .. "/data/gem_stats.lua")
dofile(ROOT .. "/data/spec_profiles.lua")
dofile(ROOT .. "/data/reforge.lua")
dofile(ROOT .. "/modules/stat_match.lua")
dofile(ROOT .. "/modules/targetgear.lua")
dofile(ROOT .. "/modules/charakter.lua")
dofile(ROOT .. "/modules/sync.lua")

local TG   = WeintCodex.TargetGear
local Sync = WeintCodex.Sync

local fails = 0
local function Check(name, ok, detail)
    print(string.format("%-68s %s", name,
        ok and "ok" or ("ABWEICHUNG  " .. tostring(detail or ""))))
    if not ok then fails = fails + 1 end
end

--==========================================================================
-- 1) UndoEditBoxPipeEscape() fuer sich - die Umkehrfunktion allein
--==========================================================================

do
    Check("ein einzelnes Pipe-Paar wird zu einem Pipe",
          Sync.UndoEditBoxPipeEscape("a||b") == "a|b")

    Check("ein absichtlich leeres Feld (verdoppelt: vier Pipes) bleibt EIN Trenner-Paar",
          Sync.UndoEditBoxPipeEscape("2||103916||||136||0") == "2|103916||136|0",
          Sync.UndoEditBoxPipeEscape("2||103916||||136||0"))

    Check("ein String ohne jedes Pipe bleibt unveraendert",
          Sync.UndoEditBoxPipeEscape("keine Pipes hier") == "keine Pipes hier")

    Check("Nicht-Strings gehen unveraendert durch",
          Sync.UndoEditBoxPipeEscape(nil) == nil)
end

--==========================================================================
-- 2) REGRESSION: der reale Bugreport, Zeichen fuer Zeichen so verdoppelt,
--    wie es die EditBox im Spiel nachweislich tut (DEBUG-Log bestaetigt:
--    9 statt 5 Teile je Zeile, ItemID durchweg nil, Payload-Laenge 493
--    statt 433 - exakt +1 Zeichen je der 60 echten Pipes im Original).
--==========================================================================

do
    local original = "WCIMPORT:TG:DEATHKNIGHT_BLOOD:bf8435f694a1:1788872681:Njiah:wowsims_json:"
        .. "1|99190|95344-76695|0|0,"
        .. "2|103916||136|0,"
        .. "3|103748|76673-76673|136|4803,"
        .. "15|102250|76695|156|4424,"
        .. "5|99188|76695-76695-76690|157|4419,"
        .. "9|103742|76695|161|4415,"
        .. "10|99189|76695-76690-76695|157|4433,"
        .. "6|103933|76695-76673-76695|0|0,"
        .. "7|99039|76673-76683|121|4823,"
        .. "8|103744|76695|140|4426,"
        .. "11|103894|76690|125|0,"
        .. "12|105285|76673|136|0,"
        .. "13|102306||0|0,"
        .. "14|102296||0|0,"
        .. "16|103869|76683|143|3368"

    -- Exakt das, was die EditBox laut DEBUG-Log tatsaechlich liefert:
    -- jedes woertliche "|" verdoppelt.
    local asEditBoxDeliversIt = original:gsub("|", "||")

    Check("die Simulation trifft die gemeldete Payload-Laenge (433 -> 493)",
          #(asEditBoxDeliversIt:match("^WCIMPORT:[^:]+:(.+)$")) == 493,
          tostring(#(asEditBoxDeliversIt:match("^WCIMPORT:[^:]+:(.+)$"))))

    -- OHNE Korrektur: derselbe Fehler wie im Bugreport.
    local rawPayload = asEditBoxDeliversIt:match("^WCIMPORT:[^:]+:(.+)$")
    local brokenEntry, brokenProblem = TG.ParseTransfer(rawPayload)
    Check("OHNE UndoEditBoxPipeEscape wird der verdoppelte String abgewiesen",
          brokenEntry == nil
          and brokenProblem
          and brokenProblem:find("Ausruestungsplatz", 1, true) ~= nil,
          tostring(brokenProblem))

    -- MIT Korrektur, genau wie im OnClick-Handler von ShowImportDialog:
    -- raw = editBox:GetText(); raw = UndoEditBoxPipeEscape(raw)
    local fixedRaw = Sync.UndoEditBoxPipeEscape(asEditBoxDeliversIt)
    Check("nach UndoEditBoxPipeEscape ist der String wieder das Original",
          fixedRaw == original, fixedRaw)

    -- Und der volle Weg ueber QuickImport (= ProcessImport), wie ihn
    -- ein Spieler ueber den Importieren-Knopf tatsaechlich nimmt.
    -- QuickImport() gibt nichts zurueck (druckt nur ins Chatfenster,
    -- wie modules/sync.lua es schon vor diesem Fix tat) - der Beleg ist
    -- deshalb TG.SetFor() danach, nicht ein Rueckgabewert.
    TG.SetEnabled(true)
    Sync.QuickImport(fixedRaw)

    -- TG.SetFor() liefert den von TG.CleanEntry() bereits GEZAEHLTEN
    -- Stand zurueck; entry.items ist dabei nach SLOTNUMMER indiziert
    -- (nicht fortlaufend - Slot 4 fehlt in diesem String), weshalb die
    -- Zaehlung ueber entry.count/.gemCount/.reforgeCount laeuft und
    -- nicht ueber #entry.items (auf einer luecken­haften Tabelle ist der
    -- #-Operator nicht aussagekraeftig).
    local entry = TG.SetFor("DEATHKNIGHT_BLOOD")
    Check("der reale Bugreport-String wird nach der Korrektur angenommen",
          entry ~= nil)
    Check("15 Ausruestungsteile stehen danach fuer die Spec bereit",
          entry and entry.count == 15, tostring(entry and entry.count))
    Check("21 Sockelsteine insgesamt", entry and entry.gemCount == 21,
          tostring(entry and entry.gemCount))
    Check("11 Umschmiedungen insgesamt", entry and entry.reforgeCount == 11,
          tostring(entry and entry.reforgeCount))

    if entry then
        local first = entry.items[1]
        Check("Slot 1 (itemId 99190, Gems 95344/76695) landet richtig",
              first and first.itemId == 99190 and #first.gems == 2
              and first.gems[1] == 95344 and first.gems[2] == 76695,
              first and first.itemId)
    end
end

--==========================================================================
-- 3) Ein absichtlich leeres Feld darf NICHT verschluckt werden, wenn der
--    String NICHT durch eine EditBox lief (SavedVariables-Bruecke).
--==========================================================================

do
    -- companion.lua ruft bei raid_import QuickImport() DIREKT auf, ohne
    -- UndoEditBoxPipeEscape dazwischen - das muss so bleiben, sonst
    -- verschmilzt ein dort absichtlich leeres Feld mit dem Feld daneben.
    local text = "WCIMPORT:TG:DRUID_FERAL:abc123:1700000000:Njiah:wowsims_json:"
        .. "5|86918||140|4420"          -- absichtlich KEINE Steine
    TG.SetEnabled(true)
    Sync.QuickImport(text)
    local entry = TG.SetFor("DRUID_FERAL")
    Check("ein ungeschuetzter String mit absichtlich leerem Feld wird trotzdem richtig gelesen",
          entry ~= nil)
    Check("und das leere Feld bleibt 'kein Stein', nicht 'verschmolzen'",
          entry and entry.items[5] and #entry.items[5].gems == 0
          and entry.items[5].reforge == 140,
          entry and entry.items[5] and (#entry.items[5].gems .. "/" .. entry.items[5].reforge))
end

print("")
if fails == 0 then
    print("Alles ok.")
    os.exit(0)
else
    print(fails .. " Abweichung(en).")
    os.exit(1)
end
