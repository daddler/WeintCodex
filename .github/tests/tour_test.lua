-- Kopflose Pruefung der Einfuehrung (core/onboarding.lua).
--
-- WARUM ES DIESEN LAUF GIBT: die Tour ist zwischen 1.0 und 2.10 lautlos
-- veraltet - fuenf von zwoelf Seiten beschrieben Bereiche, die es so nicht
-- mehr gab, und von der halben Ausruestungsberatung stand kein Wort darin.
-- Auffallen kann das im Spiel nicht: eine Seite, die fehlt, sieht aus wie
-- ein Bereich, den es nicht gibt.
--
--   lua5.1 .github/tests/tour_test.lua .

local ROOT = ...

--== Ein Client, so weit ihn die Schrittliste braucht ======================
WeintCodex = {
    Version    = "3.0.0.0",
    C          = setmetatable({}, { __index = function() return {0,0,0,1} end }),
    Colors     = setmetatable({}, { __index = function() return {0,0,0,1} end }),
    Fonts      = setmetatable({}, { __index = function() return "f" end }),
    SetSolidBg = function() end,
    DrawBorder = function() return {} end,
    ColorText  = function(_, t) return t end,
    Icon       = function(p) return p end,
    CreateButton = function() return {} end,
    Eyebrow      = function() return {} end,
    CutCorners   = function() end,
    CreateScrollArea = function() end,
}
CreateFrame = function()
    return setmetatable({}, { __index = function() return function() end end })
end
wipe = function(t) for k in pairs(t) do t[k] = nil end end

assert(loadfile(ROOT .. "/core/onboarding.lua"))()

-- Die Schrittliste ist dateilokal; sie haengt als Upvalue an
-- BuildVisibleSteps, das wiederum an ShowTour haengt.
local steps
do
    local fn = WeintCodex.Onboarding.ShowTour
    for i = 1, 60 do
        local name, value = debug.getupvalue(fn, i)
        if not name then break end
        if name == "BuildVisibleSteps" then
            for j = 1, 30 do
                local n2, v2 = debug.getupvalue(value, j)
                if not n2 then break end
                if n2 == "TOUR_STEPS" then steps = v2 end
            end
        end
    end
end

local fails = 0
local function Check(name, ok, detail)
    print(string.format("%-58s %s", name,
        ok and "ok" or ("ABWEICHUNG  " .. tostring(detail or ""))))
    if not ok then fails = fails + 1 end
end

Check("Die Schrittliste ist erreichbar", steps ~= nil)
if not steps then print(""); print("1 Abweichung(en)."); os.exit(1) end

--== Vollstaendigkeit ======================================================
Check("Die Tour hat mindestens 20 Seiten", #steps >= 20, tostring(#steps))

local chapters, order = {}, {}
local missing = {}
for i, step in ipairs(steps) do
    if not (step.chapter and step.title and step.body and step.icon) then
        missing[#missing + 1] = tostring(i)
    end
    if step.chapter and not chapters[step.chapter] then
        chapters[step.chapter] = true
        order[#order + 1] = step.chapter
    end
end
Check("Jede Seite hat Kapitel, Titel, Text und Symbol",
      #missing == 0, table.concat(missing, ", "))
Check("Mindestens vier Kapitel", #order >= 4, tostring(#order))

-- Ein Kapitel darf nicht zweimal anfangen: eine Seite, die zwischen zwei
-- Kapitel eines dritten geraet, liest sich in der Kopfzeile wie ein Sprung
-- zurueck - und die Gliederung gibt es genau dafuer.
do
    local seen, breaks = {}, {}
    local last
    for _, step in ipairs(steps) do
        if step.chapter ~= last then
            if seen[step.chapter] then breaks[#breaks + 1] = step.chapter end
            seen[step.chapter] = true
            last = step.chapter
        end
    end
    Check("Die Kapitel stehen zusammen", #breaks == 0, table.concat(breaks, ", "))
end

--== Jeder Navigationspunkt kommt vor =====================================
-- Geprueft gegen die Beschriftungen, die auch im Fenster stehen. Eine neue
-- Seite faellt damit hier auf und nicht erst, wenn jemand sie vermisst.
do
    local text = {}
    for _, step in ipairs(steps) do
        text[#text + 1] = step.title .. " " .. step.body
    end
    text = table.concat(text, " ")

    local AREAS = {
        "Übersicht", "Bossguides", "Raids", "Gruppencheck", "Kalender",
        "WeintTV", "Charakter", "Academy", "Materialien", "WeakAuras",
        "Import", "Einstellungen",
        "Verzauberungen", "Sockel", "Werteverteilung", "Umschmieden",
        "Priorisierung", "Simmen", "Twinks",
        "Ausrüstungs-Alarm", "Einkaufsliste", "Rotationshelfer",
    }
    local absent = {}
    for _, area in ipairs(AREAS) do
        if not text:find(area, 1, true) then absent[#absent + 1] = area end
    end
    Check("Jeder Bereich des Addons kommt vor",
          #absent == 0, table.concat(absent, ", "))
end

--== Die Einstellungen sagen, was ein Schalter kostet ======================
-- Ein Schalter ohne Folgenangabe ist eine Frage ohne Antwort: wer nicht
-- weiss, was er sich abschaltet, laesst im Zweifel alles an oder alles aus,
-- und beides ist geraten. Und dass die Entscheidung umkehrbar ist, ist der
-- wichtigste Teil - er nimmt der Frage das Endgueltige.
do
    local page
    for _, step in ipairs(steps) do
        if step.title:find("Einstellungen", 1, true) then page = step end
    end
    Check("Es gibt eine Seite zu den Einstellungen", page ~= nil)
    if page then
        local body = page.body
        Check("... sie sagt, dass sich alles wieder aendern laesst",
              body:find("jederzeit", 1, true) ~= nil
              or body:find("umlegen", 1, true) ~= nil, "kein Hinweis")
        Check("... und sie beschreibt beide Richtungen",
              body:find("Aus ", 1, true) ~= nil and body:find("an ", 1, true) ~= nil,
              "nur eine Richtung")
    end
end

--== Der Feedback-Aufruf steht drin ========================================
do
    local text = {}
    for _, step in ipairs(steps) do text[#text + 1] = step.body end
    text = table.concat(text, " ")
    Check("Die Tour bittet um Rueckmeldung zu den Sockelsteinen",
          text:find("Sockelsteinen", 1, true) ~= nil
          and text:find("Discord", 1, true) ~= nil, "fehlt")
end

print("")
if fails == 0 then
    print("Alles bestanden.")
else
    print(fails .. " Abweichung(en).")
    os.exit(1)
end
