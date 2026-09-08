-- Kopflose Pruefung der beiden Orte, an denen die Steinempfehlung
-- gebraucht wird: das Auktionshaus (modules/shoppinglist.lua) und das
-- Sockelfenster (modules/socketing.lua).
--
-- WARUM ES DIESEN LAUF GIBT. Beide Dateien rechnen NICHTS - sie lesen
-- das Ergebnis von WeintCodex.Charakter.Scan(). Genau deshalb faellt es
-- dort nicht auf, wenn sie das Falsche lesen: die Liste bleibt einfach
-- leer, das Fenster sagt einfach nichts, und beides sieht aus wie "es
-- gibt nichts zu tun".
--
-- Zwei Faelle stehen hier fest:
--
--   1. WAS DER SIM TAUSCHEN WILL, GEHOERT AUF DIE EINKAUFSLISTE.
--      Ein Stein mit dem Urteil "ok" ist sonst eine Abwaegung und kein
--      Mangel - fuer die eigene Wertung stimmt das. Nennt der Sim einen
--      anderen Stein, ist nichts mehr abzuwaegen. Ohne diese Ausnahme
--      steht ein Zielzustand im Fenster, den man nirgends einkaufen
--      kann.
--   2. AM SOCKELFENSTER ZAEHLT DIE POSITION.
--      Ein verschobener Stein sieht aus wie eine Empfehlung und ist
--      keine - dieselbe Regel wie im Ziel selbst.
--
--   lua5.1 .github/tests/socketing_test.lua .

local ROOT = ...

--== Ein Client, so weit ihn diese Rechnung braucht =========================

function CreateFrame(kind, name)
    local f = {}
    local scripts = {}
    function f:SetOwner() end
    function f:RegisterEvent() end
    function f:UnregisterEvent() end
    function f:SetScript(which, fn) scripts[which] = fn end
    function f:GetScript(which) return scripts[which] end
    function f:Hide() self._shown = false end
    function f:Show() self._shown = true end
    function f:IsShown() return self._shown and true or false end
    function f:SetPoint() end
    function f:SetSize() end
    function f:SetWidth() end
    function f:SetHeight() end
    function f:EnableMouse() end
    function f:SetFrameStrata() end
    function f:GetFrameStrata() return "HIGH" end
    function f:SetToplevel() end
    function f:CreateTexture()
        return { SetTexture = function() end, SetSize = function() end,
                 SetPoint = function() end, SetColorTexture = function() end,
                 SetVertexColor = function() end, SetAllPoints = function() end }
    end
    function f:CreateFontString()
        return { SetFont = function() end, SetPoint = function() end,
                 SetText = function() end, SetTextColor = function() end,
                 SetWidth = function() end, SetJustifyH = function() end,
                 GetStringHeight = function() return 12 end,
                 Show = function() end, Hide = function() end }
    end
    if name then _G[name] = f end
    return f
end

UIParent    = {}
GameTooltip = { SetOwner = function() end, SetItemByID = function() end,
                Show = function() end, Hide = function() end }

function GetLocale()    return "deDE" end
function UnitName()     return "Testchar", nil end
function UnitClass()    return "Druide", "DRUID", 11 end
function UnitLevel()    return 90 end
function GetRealmName() return "Ook Ook" end
function GetTime()      return 0 end
C_Timer = { After = function() end }

function GetItemInfo(id)
    return "Teststein " .. tostring(id), "item:" .. tostring(id), 3, 90, 90,
           "", "", 1, "", "Interface\\Icons\\INV_Misc_Gem_01"
end
function GetItemInfoInstant(id) return id, "", 3, "" end

WeintCodex = { SavedData = {}, Fonts = {}, Colors = {} }

-- Die Oberflaechenbausteine, so weit die beiden Dateien sie anfassen.
-- Gebaut wird in diesem Lauf nichts - geprueft werden die Rechnungen
-- davor, und die brauchen kein Fenster.
WeintCodex.Colors = setmetatable({}, { __index = function() return { 1, 1, 1, 1 } end })
WeintCodex.Fonts  = setmetatable({}, { __index = function() return "font" end })
function WeintCodex.CreateSurface() return CreateFrame("Frame") end
function WeintCodex.Eyebrow(parent) return parent:CreateFontString() end
function WeintCodex.Label(parent)   return parent:CreateFontString() end
function WeintCodex.CreateButton(parent) return CreateFrame("Button") end
function WeintCodex.CreateScrollArea(parent)
    return CreateFrame("ScrollFrame"), CreateFrame("Frame")
end
function WeintCodex.SetSolidBg() end
function WeintCodex.DrawBorder() end
function WeintCodex.Icon() return "" end
function WeintCodex.ColorText(_, text) return text end

function WeintCodex_GetGemName(id) return "Teststein " .. tostring(id) end

dofile(ROOT .. "/modules/shoppinglist.lua")
dofile(ROOT .. "/modules/socketing.lua")

local SL = WeintCodex.ShoppingList
local SO = WeintCodex.Socketing

local fails = 0
local function Check(name, ok, detail)
    print(string.format("%-70s %s", name,
        ok and "ok" or ("ABWEICHUNG  " .. tostring(detail or ""))))
    if not ok then fails = fails + 1 end
end

-- Ein Scan-Ergebnis, wie WeintCodex.Charakter.Scan() es liefert.
local function ScanWith(gemRows)
    return { gems = { rows = gemRows }, enchants = { rows = {} } }
end

local function UseScan(scan)
    WeintCodex.Charakter = { Scan = function() return scan end }
    SO.Invalidate()
end

--==========================================================================
-- 1) DIE EINKAUFSLISTE
--==========================================================================

do
    -- Der gemeldete Fall: der Sim will einen anderen Stein. Das Urteil
    -- dazu ist seit 3.0.3.1 "ok" (und ausdruecklich nicht "optimal") -
    -- ohne die Sim-Ausnahme faende die Liste hier nichts.
    UseScan(ScanWith({
        { slotId = 1, slotName = "Kopf", status = "ok", fromSim = true,
          recId = 76695, socket = { index = 1 } },
    }))
    local items = SL.Build()
    Check("was der Sim tauschen will, steht auf der Einkaufsliste",
          items and #items == 1 and items[1].itemId == 76695,
          items and #items)
    Check("und der Platz steht dabei",
          items and items[1] and items[1].slots[1] == "Kopf",
          items and items[1] and items[1].slots[1])

    -- Steckt der Zielstein schon drin, gibt es nichts zu kaufen.
    UseScan(ScanWith({
        { slotId = 1, slotName = "Kopf", status = "optimal", fromSim = true,
          recId = 76695, socket = { index = 1 } },
    }))
    Check("ein bereits passender Sim-Stein kommt NICHT auf die Liste",
          #(SL.Build() or {}) == 0)

    -- OHNE Sim-Ziel bleibt die alte Regel: "ok" ist eine Abwaegung und
    -- gehoert auf die Sockelseite, nicht auf einen Einkaufszettel.
    UseScan(ScanWith({
        { slotId = 1, slotName = "Kopf", status = "ok",
          recId = 76695, socket = { index = 1 } },
    }))
    Check("ohne Sim-Ziel bleibt 'ok' eine Abwaegung und kein Einkauf",
          #(SL.Build() or {}) == 0)

    -- Ein leerer Sockel war immer schon ein Einkauf.
    UseScan(ScanWith({
        { slotId = 5, slotName = "Brust", status = "missing",
          recId = 76692, socket = { index = 1 } },
    }))
    Check("ein leerer Sockel steht weiterhin auf der Liste",
          #(SL.Build() or {}) == 1)

    -- Ohne Basisdaten wird nichts behauptet - auch nicht aus dem Sim.
    UseScan(ScanWith({
        { slotId = 1, slotName = "Kopf", status = "neutral", fromSim = true,
          recId = 76695, socket = { index = 1 }, socketsKnown = false },
    }))
    Check("ohne geladene Gegenstandsdaten kommt nichts auf die Liste",
          #(SL.Build() or {}) == 0)

    -- Zwei Sockel, derselbe Zielstein: ein Posten, Anzahl zwei. Sonst
    -- kauft man einen und denkt, man sei fertig.
    UseScan(ScanWith({
        { slotId = 1, slotName = "Kopf",  status = "ok", fromSim = true,
          recId = 76695, socket = { index = 1 } },
        { slotId = 5, slotName = "Brust", status = "ok", fromSim = true,
          recId = 76695, socket = { index = 1 } },
    }))
    local zwei = SL.Build()
    Check("zweimal derselbe Stein wird zu einem Posten mit Anzahl 2",
          zwei and #zwei == 1 and zwei[1].count == 2,
          zwei and zwei[1] and zwei[1].count)
end

--==========================================================================
-- 2) DAS SOCKELFENSTER
--==========================================================================

do
    local scan = ScanWith({
        -- Absichtlich in falscher Reihenfolge und mit einem fremden
        -- Platz dazwischen: beides muss die Auswahl aushalten.
        { slotId = 5, slotName = "Brust", status = "ok", fromSim = true,
          recId = 76690, socket = { index = 2 } },
        { slotId = 1, slotName = "Kopf",  status = "optimal",
          recId = 76673, socket = { index = 1 } },
        { slotId = 5, slotName = "Brust", status = "optimal", fromSim = true,
          recId = 76695, socket = { index = 1 } },
    })

    local rows = SO.RowsForSlot(scan, 5)
    Check("nur die Sockel DIESES Platzes", #rows == 2, tostring(#rows))
    Check("und zwar in der Reihenfolge der Sockel, nicht des Scans",
          rows[1].socket.index == 1 and rows[2].socket.index == 2,
          rows[1].socket.index .. "/" .. rows[2].socket.index)

    Check("ein Platz ohne Sockelzeilen ergibt eine leere, gueltige Auskunft",
          #SO.RowsForSlot(scan, 11) == 0)
    Check("und ein fehlender Scan ebenfalls",
          #SO.RowsForSlot(nil, 5) == 0)

    -- Die drei Aussagen einer Zeile.
    local steckt = SO.LineFor(rows[1])
    Check("der bereits passende Sockel ist 'done'",
          steckt and steckt.kind == "done", steckt and steckt.kind)
    Check("und nennt den Sim als Quelle",
          steckt and steckt.note and steckt.note:find("Sim", 1, true) ~= nil,
          steckt and steckt.note)

    local tauschen = SO.LineFor(rows[2])
    Check("der abweichende Sockel ist 'swap' mit Nummer und Namen",
          tauschen and tauschen.kind == "swap" and tauschen.itemId == 76690
          and tauschen.name ~= nil,
          tauschen and tauschen.kind)

    -- KEINE AUSSAGE IST EINE AUSSAGE. Ohne geladene Daten darf hier
    -- nichts stehen, was nach Empfehlung aussieht.
    local unklar = SO.LineFor({ status = "neutral", socketsKnown = false,
                                socket = { index = 1 } })
    Check("ohne geladene Gegenstandsdaten wird nichts behauptet",
          unklar and unklar.kind == "none" and unklar.itemId == nil,
          unklar and unklar.kind)

    local ohne = SO.LineFor({ status = "ok", socket = { index = 1 } })
    Check("ein Sockel ohne Empfehlung ebenfalls nicht",
          ohne and ohne.kind == "none", ohne and ohne.kind)

    Check("und eine Zeile, die es nicht gibt, ergibt nichts",
          SO.LineFor(nil) == nil)

    -- Ohne bestaetigten Platz sagt das Fenster nichts. GetSocketItemInfo
    -- gibt es in diesem Lauf nicht - also darf auch nichts herauskommen.
    Check("ohne Sockelfenster des Clients gibt es keinen bestaetigten Platz",
          SO.VerifiedSlot() == nil)

    -- Der Schalter.
    SO.SetOption("enabled", false)
    Check("die Anzeige laesst sich abschalten", SO.GetOption("enabled") == false)
    SO.SetOption("enabled", true)
    Check("und wieder ein", SO.GetOption("enabled") == true)
end

print("")
if fails == 0 then
    print("Alles ok.")
    os.exit(0)
else
    print(fails .. " Abweichung(en).")
    os.exit(1)
end
