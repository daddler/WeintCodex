-- Kopflose Pruefung der Bereitstellung fuer den Sim (modules/simexport.lua).
--
-- Die Seite tut fast nichts — und genau das ist der Grund, warum ihre
-- Auskunft stimmen muss: sie behauptet, ob ein zweites Programm den
-- aktuellen Stand sieht. Das kann man im Spiel nicht nachsehen. Steht
-- "aktuell", wo "veraltet" richtig waere, oeffnet die Companion den Sim mit
-- der Ausruestung von gestern, und niemand merkt es.
--
-- Geprueft werden deshalb die vier Zustaende, die zu vier verschiedenen
-- Handlungen fuehren (kein Addon, abgeschaltet, nichts gemeldet, veraltet),
-- die Suche nach dem neuesten Eintrag ueber alle Profile hinweg, und der
-- Stups: er haengt an einer Funktion eines FREMDEN Addons und darf deshalb
-- scheitern, ohne etwas mitzureissen — gemeldet wird das Ergebnis (hat sich
-- der Zeitstempel bewegt?) und nicht der Versuch.
--
--   lua5.1 .github/tests/simexport_test.lua .

local ROOT = ...

local fails = 0
local function Check(name, ok, detail)
    print(string.format("%-56s %s", name, ok and "ok" or ("ABWEICHUNG  " .. (detail or ""))))
    if not ok then fails = fails + 1 end
end

--== Attrappen ==============================================================
--
-- Alles, was sonst der Client beantwortet. Die Anmeldung wird als Skript
-- festgehalten, damit der Test sie selbst ausloesen kann - genau dort merkt
-- sich die Datei den Stand der Festplatte.

local loginHandler

local function Stub()
    return setmetatable({}, { __index = function() return function() end end })
end

_G.CreateFrame = function()
    local frame = {}
    function frame:RegisterEvent() end
    function frame:SetScript(_, fn) loginHandler = fn end
    function frame:SetPoint() end
    function frame:SetHeight() end
    function frame:Show() end
    function frame:Hide() end
    function frame:IsShown() return false end
    function frame:GetChildren() return end
    function frame:SetAllPoints() end
    function frame:CreateFontString() return Stub() end
    function frame:CreateTexture() return Stub() end
    return frame
end

_G.InCombatLockdown = function() return false end
_G.UnitName = function() return "Njiah" end
_G.GetRealmName = function() return "Ook Ook" end

local NOW = 1787000000
_G.time = function() return NOW end
_G.date = function(fmt, stamp) return "DATUM" end

local addonLoaded, addonExists = true, true

_G.C_AddOns = {
    IsAddOnLoaded = function() return addonLoaded end,
    GetAddOnInfo = function(name) return addonExists and name or nil end,
}

WeintCodex = {
    Colors = setmetatable({}, { __index = function() return { 1, 1, 1, 1 } end }),
    Fonts  = { sans = "s", sansSemi = "ss", mono = "m" },
    SetSolidBg = function() end,
    DrawBorder = function() end,
    ColorText = function(_, text) return text end,
}

dofile(ROOT .. "/modules/simexport.lua")

local SE = WeintCodex.SimExport

local function Login()
    if loginHandler then loginHandler() end
end

local function Saved(profiles)
    _G.WSEDB = profiles and { profiles = profiles } or nil
end

--== Vier Gruende, vier Antworten ===========================================

do
    addonExists, addonLoaded = false, false
    Saved(nil)
    Check("Ohne Addon ist das Addon der Grund", SE.State().status == SE.NO_ADDON)

    addonExists, addonLoaded = true, false
    Check("Installiert, aber abgeschaltet, ist ein eigener Fall",
        SE.State().status == SE.DISABLED)

    addonLoaded = true
    Saved({ Default = { savedCharacters = {} } })
    Check("Geladen, aber nichts gemeldet", SE.State().status == SE.NO_EXPORT)

    Saved(nil)
    Check("Ohne WSEDB ebenso", SE.State().status == SE.NO_EXPORT)
end

--== Aktuell oder veraltet ==================================================
--
-- Der eine Vergleich, um den es hier geht. Beim Anmelden ist der Speicher
-- das, was auf der Festplatte steht; alles Spaetere ist neuer.

do
    Saved({ Default = { savedCharacters = {
        { name = "Njiah-Ook Ook", timestamp = 100, data = "{}" },
    } } })
    Login()

    Check("Direkt nach dem Anmelden ist der Stand aktuell",
        SE.State().status == SE.READY)

    Saved({ Default = { savedCharacters = {
        { name = "Njiah-Ook Ook", timestamp = 500, data = "{}" },
    } } })

    Check("Ein neuerer Export im Speicher heisst veraltet auf der Platte",
        SE.State().status == SE.STALE)
end

do
    -- Ein Export, den es beim Anmelden noch gar nicht gab, ist per
    -- Definition noch nicht auf der Festplatte.
    Saved({ Default = { savedCharacters = {} } })
    Login()
    Saved({ Default = { savedCharacters = {
        { name = "Njiah-Ook Ook", timestamp = 42, data = "{}" },
    } } })

    Check("Der erste Export nach dem Anmelden ist veraltet",
        SE.State().status == SE.STALE)
end

--== Der neueste Eintrag ====================================================

do
    Saved({
        Default = { savedCharacters = {
            { name = "Alt",  timestamp = 100, data = "{}" },
            { name = "Neu",  timestamp = 900, data = "{}" },
        } },
        Zweit = { savedCharacters = {
            { name = "Mitte", timestamp = 400, data = "{}" },
        } },
    })
    Login()

    Check("Der neueste Eintrag gewinnt, ueber alle Profile hinweg",
        SE.State().entry.name == "Neu", SE.State().entry.name)
end

do
    -- AceDB legt die Vorgabe unter "Default" ab. Wer sich ein eigenes
    -- Profil angelegt hat, hat mehrere - und dann waere ausgerechnet die
    -- Vorgabe die veraltete.
    Saved({
        Default = { savedCharacters = {
            { name = "Vorgabe", timestamp = 100, data = "{}" },
        } },
        Eigenes = { savedCharacters = {
            { name = "Eigenes", timestamp = 800, data = "{}" },
        } },
    })
    Login()

    Check("Ein eigenes Profil wird nicht uebersehen",
        SE.State().entry.name == "Eigenes", SE.State().entry.name)
end

do
    -- Ein Eintrag ohne Nutzlast ist keiner: er sagt nur, dass das Addon
    -- einmal da war.
    Saved({ Default = { savedCharacters = {
        { name = "Leer", timestamp = 900 },
        { name = "Echt", timestamp = 100, data = "{}" },
    } } })
    Login()

    Check("Ein Eintrag ohne Daten zaehlt nicht",
        SE.State().entry.name == "Echt", SE.State().entry.name)
end

do
    -- Eine kaputte Ablage darf die Seite nicht mitreissen.
    _G.WSEDB = { profiles = "unsinn" }
    Check("Eine unerwartete Ablage ist kein Absturz",
        SE.State().status == SE.NO_EXPORT)

    _G.WSEDB = { profiles = { Default = 7 } }
    Check("Ein Profil, das keine Tabelle ist, ebenso",
        SE.State().status == SE.NO_EXPORT)
end

--== Der Stups ==============================================================
--
-- Er ruft eine Funktion eines fremden Addons. Aendert die sich, ist das kein
-- Grund, den Knopf tot zu stellen - gemeldet wird, ob sich der Zeitstempel
-- BEWEGT hat, nicht ob der Aufruf durchkam.

do
    Saved({ Default = { savedCharacters = {
        { name = "Njiah", timestamp = 100, data = "{}" },
    } } })

    local exporter = {}
    function exporter:OnCharacterChanged()
        _G.WSEDB.profiles.Default.savedCharacters[1].timestamp = 700
    end

    _G.LibStub = function()
        return { GetAddon = function() return exporter end }
    end

    Check("Ein wirksamer Stups wird als wirksam gemeldet", SE.Nudge() == true)
end

do
    Saved({ Default = { savedCharacters = {
        { name = "Njiah", timestamp = 100, data = "{}" },
    } } })

    local exporter = {}
    function exporter:OnCharacterChanged()
        error("das fremde Addon hat sich geaendert")
    end

    _G.LibStub = function()
        return { GetAddon = function() return exporter end }
    end

    Check("Ein Fehler im fremden Addon reisst nichts mit",
        SE.Nudge() == false)
    Check("… und der Eintrag bleibt unangetastet",
        SE.State().entry.timestamp == nil
        or _G.WSEDB.profiles.Default.savedCharacters[1].timestamp == 100)
end

do
    Saved({ Default = { savedCharacters = {
        { name = "Njiah", timestamp = 100, data = "{}" },
    } } })

    _G.LibStub = nil

    Check("Ohne LibStub wird nichts behauptet", SE.Nudge() == false)
end

--== Der Handshake: gehoert das hier zu MEINEM Lauf? ========================
--
-- Bis 3.1.2.0 war "es ist etwas angekommen" die ganze Antwort. Sie reicht
-- fuer den Normalfall und ist in genau dem Fall falsch, auf den es ankommt:
--
--   bereitstellen -> simmen -> ein Teil wechseln -> nochmal bereitstellen
--   -> und dann das Ergebnis des ERSTEN Laufs einfuegen.
--
-- Das kommt an, sieht vollstaendig aus und gehoert zu einer Ausruestung von
-- vorhin. Von aussen ist es von einem richtigen Ergebnis nicht zu
-- unterscheiden - es gibt keine Fehlermeldung, an der man es erkennen
-- koennte. Dieselbe Fehlerklasse wie die laufende Nummer des Umschmieders
-- und die Feldnummern in core/wowsims_link.py drueben.

do
    WeintCodex.SavedData = {}

    Check("Ohne offenen Lauf wird nichts behauptet",
        SE.MatchesOpenRun(NOW) == nil)

    SE.NoteProvided()

    -- NIL IST NICHT FALSE. Eine aeltere Companion schickt gar keinen
    -- Zeitstempel; daraus "gehoert nicht dazu" zu machen waere eine
    -- Warnung ueber etwas, das niemand geprueft hat.
    Check("Ohne Zeitstempel wird nichts behauptet",
        SE.MatchesOpenRun(0) == nil)

    Check("Ein Export von jetzt gehoert zum offenen Lauf",
        SE.MatchesOpenRun(NOW) == true)

    -- Der Stups laeuft VOR NoteProvided; der Zeitstempel liegt also ein
    -- bis zwei Sekunden davor. Ohne diesen Spielraum meldete der
    -- Normalfall einen Irrtum.
    Check("Ein Export von kurz davor auch",
        SE.MatchesOpenRun(NOW - 60) == true)

    Check("Ein Export von vorgestern nicht",
        SE.MatchesOpenRun(NOW - 3 * 86400) == false)
end

do
    WeintCodex.SavedData = {}
    SE.NoteProvided()

    local passt = SE.NoteArrival({
        run = "SIM-20260909-7F4A", startedAt = NOW, kind = "weights",
    })

    Check("Der erwartete Lauf beendet das Warten", passt == true)
    Check("...und der Kasten hat nichts mehr zu fragen",
        SE.AwaitingFor() == nil)

    local last = SE.LastRun()
    Check("Was ankam, wird festgehalten",
        last ~= nil and last.id == "SIM-20260909-7F4A")
    Check("...samt der Frage, welche Haelfte",
        last.weights == true and last.target == nil)

    -- Die zweite Haelfte desselben Laufs ergaenzt den Eintrag, statt
    -- einen zweiten daneben zu legen.
    SE.NoteArrival({
        run = "SIM-20260909-7F4A", startedAt = NOW, kind = "target",
    })

    last = SE.LastRun()
    Check("Beide Haelften stehen unter EINEM Lauf",
        last.weights == true and last.target == true)
    Check("...und es bleibt derselbe Lauf",
        last.id == "SIM-20260909-7F4A")
end

do
    WeintCodex.SavedData = {}
    SE.NoteProvided()

    -- DER FALL, WEGEN DEM ES DAS GIBT.
    local passt = SE.NoteArrival({
        run = "SIM-20260901-AAAA", startedAt = NOW - 5 * 86400,
        kind = "target",
    })

    Check("Ein Ergebnis aus einem aelteren Lauf wird erkannt",
        passt == false)

    -- ES BEENDET DAS WARTEN NICHT. Der Lauf, den der Spieler
    -- bereitgestellt hat, ist weiter offen; den Kasten wegzuraeumen und
    -- den Irrtum stehenzulassen waere das Schlechteste von beidem.
    Check("...und beendet das Warten nicht", SE.AwaitingFor() ~= nil)

    -- Festgehalten wird es trotzdem: `/wc ziel` und `/wc simmen pruefen`
    -- beantworten damit die erste Frage jeder Rueckmeldung.
    Check("...wird aber festgehalten",
        SE.LastRun() ~= nil and SE.LastRun().id == "SIM-20260901-AAAA")

    local satz = SE.ArrivalNote(passt, NOW - 5 * 86400)
    Check("Der Grund wird gesagt, nicht verschwiegen",
        satz:find("aelteren Ausruestung", 1, true) ~= nil)
    Check("...samt dem, was noch offen ist",
        satz:find("noch offen", 1, true) ~= nil)

    -- KEIN SATZ IST DER NORMALFALL: wer bereitstellt, simmt und
    -- einfuegt, braucht keine Bestaetigung dafuer, dass das Erwartete
    -- eingetroffen ist.
    Check("Der Normalfall bekommt keinen Satz", SE.ArrivalNote(true, NOW) == "")
    Check("Und eine Nichtaussage auch nicht", SE.ArrivalNote(nil, 0) == "")
end

do
    -- VERTRAEGLICHKEIT: genau wie vor 3.2.0.0, wenn nichts mitkommt.
    -- Eine aeltere Companion schickt keine Kennung, und ein von Hand
    -- getippter String hat auch keine.
    WeintCodex.SavedData = {}
    SE.NoteProvided()

    local passt = SE.NoteArrival()

    Check("Eine Ankunft ohne Angaben beendet das Warten wie bisher",
        passt == nil and SE.AwaitingFor() == nil)
    Check("...und behauptet keinen Lauf", SE.LastRun() == nil)
end

--== Wie alt =================================================================

do
    Check("Ohne Datum wird keine Zeit erfunden", SE.Ago(0) == "ohne Datum")
    Check("Gerade eben", SE.Ago(NOW - 30) == "gerade eben")
    Check("Minuten", SE.Ago(NOW - 600) == "vor 10 Minuten")
    Check("Eine Stunde", SE.Ago(NOW - 3600) == "vor einer Stunde")
    Check("Stunden", SE.Ago(NOW - 4 * 3600) == "vor 4 Stunden")
    Check("Gestern", SE.Ago(NOW - 86400) == "gestern")
    Check("Tage", SE.Ago(NOW - 5 * 86400) == "vor 5 Tagen")

    -- Eine verstellte Uhr darf kein negatives Alter ergeben.
    Check("Eine Meldung aus der Zukunft bekommt ein Datum",
        SE.Ago(NOW + 5000) == "DATUM")
end

print(fails == 0 and "\nAlles bestanden." or ("\n" .. fails .. " Abweichung(en)."))
os.exit(fails == 0 and 0 or 1)
