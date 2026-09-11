-- Kopflose Pruefung der Schwellen aus core/optin.lua.
--
-- WARUM ES DIESEN LAUF GIBT: bis 3.3.0.1 waren "erst ab Stufe 90" und
-- "erst ab dieser Gegenstandsstufe" nur ein Vorbehalt gegen die FRAGE nach
-- der Hilfe, nicht gegen die Hilfe selbst. Weil eine unbeantwortete Frage
-- hier "ja" heisst, kam dabei das Gegenteil heraus: auf jedem Twink, der
-- unter den Schwellen blieb und deshalb nie gefragt wurde, verlangte der
-- Ausruestungs-Alarm Verzauberungen fuer Ausruestung, die am Abend wieder
-- weg ist. Gemeldet wurde genau das.
--
-- Im Spiel ist die Regel nicht nachzupruefen: "es kommt keine Meldung"
-- sieht bei einem abgewaehlten Charakter, einem zu niedrigen Charakter und
-- einer Ausruestung ohne Luecke voellig gleich aus. Also hier.
--
--   lua5.1 .github/tests/optin_test.lua .

local ROOT = ...

--== Ein Client, so weit ihn diese Datei braucht ==========================
WeintCodex = {
    Colors = setmetatable({}, { __index = function() return {0,0,0,1} end }),
    Fonts  = setmetatable({}, { __index = function() return "f" end }),
    SetSolidBg   = function() end,
    DrawBorder   = function() end,
    Spaced       = function(t) return t end,
    ColorText    = function(_, t) return t end,
    CreateButton = function()
        return setmetatable({}, { __index = function() return function() end end })
    end,
}

CreateFrame = function()
    return setmetatable({}, { __index = function() return function() end end })
end

UIParent = {}

-- Der Client antwortet, was der jeweilige Fall vorgibt. `nil` heisst hier
-- "diese Funktion kennt der Client gar nicht" - das ist ein anderer Fall
-- als "der Wert steht noch nicht fest" und muss auch anders ausgehen.
local clientLevel, clientIlvl

UnitName  = function() return "Prueffigur" end
UnitLevel = function() return clientLevel end
GetAverageItemLevel = function() return clientIlvl, clientIlvl end

assert(loadfile(ROOT .. "/core/optin.lua"))()

local OI = WeintCodex.OptIn

local fails = 0
local function Check(name, ok, detail)
    print(string.format("%-62s %s", name,
        ok and "ok" or ("ABWEICHUNG  " .. tostring(detail or ""))))
    if not ok then fails = fails + 1 end
end

-- Ein Fall: Stufe, Gegenstandsstufe, gespeicherte Antwort, Schwelle.
local function Setup(level, ilvl, answer, minIlvl)
    clientLevel, clientIlvl = level, ilvl
    WeintCodex.SavedData = { optIn = { minIlvl = minIlvl or 520, chars = {} } }
    if answer ~= nil then WeintCodex.SavedData.optIn.chars["Prueffigur"] = answer end
end

--== Die Schwellen ========================================================

Setup(85, 540)
local ok, why = OI.Scope()
Check("Stufe 85: kein Bereich, Grund ist die Stufe", ok == false and why == "level", why)
Check("Stufe 85: nichts von sich aus", OI.Active() == false)

Setup(90, 480)
ok, why = OI.Scope()
Check("Stufe 90, Gegenstandsstufe 480: Grund ist die Gegenstandsstufe",
      ok == false and why == "ilvl", why)
Check("Stufe 90, Gegenstandsstufe 480: nichts von sich aus", OI.Active() == false)

Setup(90, 540)
Check("Stufe 90, Gegenstandsstufe 540: Bereich", OI.Scope() == true)
Check("Stufe 90, Gegenstandsstufe 540: Hilfe kommt", OI.Active() == true)

-- Die Schwelle ist eingestellt und keine Konstante: wer sie hochzieht,
-- schaltet damit dieselbe Ausruestung ab.
Setup(90, 540, nil, 560)
Check("Eingestellte Schwelle 560 schlaegt Gegenstandsstufe 540",
      OI.Active() == false, select(2, OI.Scope()))

Setup(90, 540, nil, 400)
Check("Eingestellte Schwelle 400 laesst Gegenstandsstufe 540 durch",
      OI.Active() == true)

-- Hoechststufe ist die untere Grenze, nicht die einzige erlaubte Stufe.
Setup(91, 540)
Check("Stufe ueber 90 bleibt im Bereich", OI.Active() == true)

--== Die Antwort ==========================================================

Setup(90, 540, false)
Check("Nein bleibt Nein, auch im Bereich", OI.Active() == false)
Check("Nein steht auch in der Antwort", OI.Answer() == false)

Setup(85, 540, true)
Check("Ja ueberstimmt die Schwelle nicht", OI.Active() == false)
-- Der Schalter auf der Einstellungsseite zeigt die ANTWORT. Stuende dort
-- die Lage, waere er auf jedem Twink aus, ohne dass jemand ihn
-- ausgeschaltet hat - und wer ihn dann anschaltet, schaltet nichts.
Check("Der Schalter zeigt trotzdem Ja", OI.Answer() == true)

Setup(85, 540)
Check("Ohne Antwort steht der Schalter auf Ja", OI.Answer() == true)

--== Was der Client (noch) nicht sagt =====================================

-- Eine 0 ist der Ladezustand, kein Messwert: solange sie dasteht, kommt
-- nichts. Der Ausruestungs-Alarm sieht ueber seinen Zeitgeber wieder nach.
Setup(90, 0)
ok, why = OI.Scope()
Check("Gegenstandsstufe 0 heisst warten, nicht melden",
      ok == false and why == "pending", why)

Setup(0, 540)
ok, why = OI.Scope()
Check("Stufe 0 heisst warten, nicht melden", ok == false and why == "pending", why)

-- Kennt der Client die Auskunft ueberhaupt nicht, entfaellt die Schwelle -
-- ein Addon stillzulegen, weil eine Funktion fehlt, waere die teurere
-- Fehlentscheidung.
Setup(90, 540)
local savedIlvlFn = GetAverageItemLevel
GetAverageItemLevel = nil
Check("Ohne GetAverageItemLevel entfaellt nur die Gegenstandsstufe",
      OI.Active() == true)
GetAverageItemLevel = savedIlvlFn

Setup(85, 540)
local savedLevelFn = UnitLevel
UnitLevel = nil
Check("Ohne UnitLevel entfaellt nur die Stufe", OI.Active() == true)
UnitLevel = savedLevelFn

Setup(85, 540)
UnitLevel, GetAverageItemLevel = nil, nil
Check("Ohne beide Auskuenfte verhaelt es sich wie vor den Schwellen",
      OI.Active() == true)
UnitLevel, GetAverageItemLevel = savedLevelFn, savedIlvlFn

--== Was dabei dasteht ====================================================
-- Der Satz ist die einzige Stelle, an der von aussen zu sehen ist, warum
-- gerade nichts kommt - er steht in den Einstellungen, in "/wc alarm" und
-- in der Frage selbst.

Setup(85, 540)
local text = OI.ScopeText()
Check("Der Satz nennt die Stufe", type(text) == "string"
      and text:find("85", 1, true) ~= nil and text:find("90", 1, true) ~= nil, text)

Setup(90, 480)
text = OI.ScopeText()
Check("Der Satz nennt die Gegenstandsstufe", text:find("480", 1, true) ~= nil
      and text:find("520", 1, true) ~= nil, text)

Setup(90, 540)
text = OI.ScopeText()
Check("Im Bereich nennt der Satz beide Zahlen",
      text:find("90", 1, true) ~= nil and text:find("540", 1, true) ~= nil, text)

Check("Die Stufenschwelle ist abfragbar", OI.MinLevel() == 90, OI.MinLevel())

print("")
if fails == 0 then
    print("Alles bestanden.")
else
    print(fails .. " Abweichung(en).")
end
os.exit(fails == 0 and 0 or 1)
