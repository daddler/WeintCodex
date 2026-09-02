-- Kopflose Pruefung des QE-Live-Wegs (modules/qelive.lua + data/qelive.lua).
--
-- Diese Datei SCHREIBT ein fremdes Format, und das ist die Sorte Fehler,
-- die nirgends auffaellt: QE Live nimmt einen falsch gebauten Text an,
-- zeigt eine Ausruestung, und nur wer nachzaehlt, sieht, dass drei Teile
-- fehlen. Es gibt keine Fehlermeldung, an der man das erkennen koennte —
-- dieselbe Fehlerklasse wie die laufende Nummer des Umschmieders und die
-- Feldnummern in core/wowsims_link.py drueben.
--
-- Geprueft wird deshalb gegen QE LIVES EIGENE REGEL und nicht gegen
-- unsere Annahme darueber:
--
--   * ab Zeile neun beginnen die Gegenstaende (`for (var i = 8; ...)` in
--     ClassicImportEngine.js). Eine Kopfzeile ZU WENIG, und der erste
--     faellt weg — das wird hier vorgefuehrt statt behauptet.
--   * `bonus_id`, `gem_id` und `enchant_id` werden DORT vor `id` geprueft,
--     weil die Suche nach "id=" sie sonst mitschluckt.
--   * das erste Feld einer Zeile wird uebersprungen (in SimC steht dort
--     der Slotname). Eine Gegenstandsnummer darf da nicht stehen.
--
-- Dazu die Gewichte: sie werden mit derselben Rechnung skaliert wie eine
-- eingefuegte Sim-Ausgabe, und eine als Luecke gefuehrte Zahl darf NICHT
-- in den Vorschlag geraten (dort gilt weiter das Spec-Profil).
--
--   lua5.1 .github/tests/qelive_test.lua .

local ROOT = ...

local fails = 0
local function Check(name, ok, detail)
    print(string.format("%-60s %s", name, ok and "ok" or ("ABWEICHUNG  " .. (detail or ""))))
    if not ok then fails = fails + 1 end
end

--== Attrappen ==============================================================

_G.WeintCodex = { Version = "9.9.9.9" }
_G.WeintCodex.ColorText = function(_, text) return text end

dofile(ROOT .. "/modules/statweights.lua")   -- liefert SW.Normalize / SW.Offer
dofile(ROOT .. "/data/spec_profiles.lua")
dofile(ROOT .. "/data/qelive.lua")
dofile(ROOT .. "/modules/qelive.lua")

local QE = WeintCodex.QELive
local SW = WeintCodex.StatWeights

--== Der Importtext ========================================================

local CHAR = {
    class = "PRIEST", name = "Njiah", level = 90,
    race = "NightElf", realm = "Ook Ook", region = "eu",
    spec = "PRIEST_HOLY",
}

local ITEMS = {
    { slot = "head",     id = 86881, enchant = 4207, gems = { 76694, 76700 }, upgrade = 2 },
    { slot = "neck",     id = 86923 },
    { slot = "hands",    id = 85341, enchant = 4432, gems = { 76700 }, upgrade = 0 },
    -- Zufallssuffix: im Item-Link steht er negativ, in QE Lives eigener
    -- Tabelle positiv.
    { slot = "wrist",    id = 63494, suffix = -138 },
    { slot = "off_hand", id = 86991, upgrade = 4 },
}

do
    local text, problem, written = QE.BuildExport(CHAR, ITEMS)

    Check("Text entsteht", text ~= nil, tostring(problem))
    Check("Alle Gegenstaende geschrieben", written == #ITEMS, tostring(written))

    local lines = {}
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do lines[#lines + 1] = line end

    Check("Genau acht Kopfzeilen",
        QE.HEADER_LINES == 8 and #lines == 8 + #ITEMS,
        ("%d Zeilen"):format(#lines))

    -- QE Live beginnt bei Index 8, also mit der NEUNTEN Zeile. Steht dort
    -- noch Kopf, ist der erste Gegenstand weg.
    Check("Die neunte Zeile ist der erste Gegenstand",
        lines[9] ~= nil and lines[9]:find("id=86881", 1, true) ~= nil,
        tostring(lines[9]))

    -- Keine Kopfzeile darf "id=" tragen: sie stuende sonst zwar vor Zeile
    -- neun und waere harmlos — aber nur, solange die Zahl acht stimmt.
    local headerCarriesId = false
    for i = 1, 8 do
        if lines[i]:find("id=", 1, true) then headerCarriesId = true end
    end
    Check("Keine Kopfzeile sieht aus wie ein Gegenstand", not headerCarriesId)

    -- Das erste Feld wird drueben uebersprungen. Eine Nummer darf da nicht
    -- stehen, sonst faellt sie lautlos unter den Tisch.
    local firstField = lines[9]:match("^([^,]*)")
    Check("Das erste Feld traegt keine Nummer",
        firstField == "head=", tostring(firstField))
end

--== Und mit QE Lives eigener Regel zurueckgelesen ==========================

do
    local text = QE.BuildExport(CHAR, ITEMS)
    local back = QE.ReadBack(text)

    Check("Ebenso viele Gegenstaende zurueck", #back == #ITEMS,
        tostring(#back))

    local byId = {}
    for _, item in ipairs(back) do byId[item.id] = item end

    Check("Kopf: Nummer, Verzauberung, zwei Steine, Aufwertung",
        byId[86881] and byId[86881].enchant == 4207
        and #byId[86881].gems == 2
        and byId[86881].gems[1] == 76694 and byId[86881].gems[2] == 76700
        and byId[86881].upgrade == 2)

    -- Genau hier greift die Reihenfolge von QE Live: `gem_id=` und
    -- `enchant_id=` enthalten beide "id=". Wuerde die Zeile falsch
    -- zerlegt, stuende eine Steinnummer als Gegenstandsnummer da.
    Check("Eine Steinnummer wird nicht zur Gegenstandsnummer",
        byId[76694] == nil and byId[76700] == nil)
    Check("Eine Verzauberungsnummer auch nicht", byId[4207] == nil)

    Check("Ohne Zusatz bleibt die nackte Nummer",
        byId[86923] and byId[86923].enchant == nil
        and #byId[86923].gems == 0 and byId[86923].upgrade == nil)

    Check("Der Zufallssuffix kommt positiv an",
        byId[63494] and byId[63494].suffix == 138,
        tostring(byId[63494] and byId[63494].suffix))

    Check("Aufwertung 4 bleibt 4",
        byId[86991] and byId[86991].upgrade == 4)

    -- Eine Aufwertung von 0 ist keine Aufwertung und gehoert nicht in den
    -- Text: `upgradeLevel=0` waere drueben dasselbe, hier aber Ballast,
    -- der aussieht, als haette jemand etwas gemessen.
    Check("Aufwertung 0 steht gar nicht erst da",
        byId[85341] and byId[85341].upgrade == nil)
end

--== Warum die acht tragend ist =============================================
--
-- Vorgefuehrt statt behauptet: mit einer Kopfzeile zu viel faellt der
-- erste Gegenstand aus der Liste, und zwar ohne jede Fehlermeldung.

do
    local text = QE.BuildExport(CHAR, ITEMS)

    -- Eine Kopfzeile ZU WENIG ist der Fall, der Schaden anrichtet: QE
    -- Live faengt fest bei Zeile neun an, dort stuende dann schon der
    -- erste Gegenstand — und er faellt weg, ohne dass irgendetwas davon
    -- zu sehen waere.
    local short = text:gsub("^[^\n]*\n", "", 1)
    Check("Eine Kopfzeile zu wenig verschluckt einen Gegenstand",
        #QE.ReadBack(short) == #ITEMS - 1,
        tostring(#QE.ReadBack(short)))

    -- Eine zu viel ist dagegen harmlos: nach hinten geschoben landet
    -- eine Kopfzeile auf Platz neun, und die traegt keine Nummer. Das
    -- steht hier, damit niemand den Waechter fuer strenger haelt, als
    -- er ist — geschuetzt ist genau eine der beiden Richtungen.
    local long = "# eine Zeile zu viel\n" .. text
    Check("Eine Kopfzeile zu viel bleibt folgenlos",
        #QE.ReadBack(long) == #ITEMS)

    -- Und deshalb muss BuildExport selbst zaehlen, statt sich auf den
    -- Textbaustein zu verlassen.
    local guard = QE.HEADER_LINES
    QE.HEADER_LINES = 9
    local blocked, problem = QE.BuildExport(CHAR, ITEMS)
    QE.HEADER_LINES = guard
    Check("Stimmt die Zahl nicht, geht gar kein Text hinaus",
        blocked == nil and problem ~= nil, tostring(problem))
end

--== Und derselbe Weg mit dem Client davor ==================================
--
-- QE.Collect() und QE.Export() sind die Stelle, die im Spiel laeuft, und
-- damit die einzige, die von aussen ueberhaupt nicht zu sehen ist. Ein
-- Slot ohne Grunddaten wird dabei GEMELDET und nicht uebergangen: ein
-- Text, in dem drei Teile fehlen, sieht drueben aus wie ein Charakter
-- ohne diese Teile — und das waere eine Aussage ueber unseren
-- Item-Zwischenspeicher statt ueber die Ausruestung.

do
    -- Ein kleiner, angelegter Satz. Der Ring traegt zwei Steine, der
    -- Umhang ist noch nicht geladen (der Client kennt seine Qualitaet
    -- nicht), der Rest ist unauffaellig.
    local EQUIPPED = {
        [1]  = "|Hitem:86881:4207:76694:76700:0:0:0:0:90:0:445|h[Kopf]|h",
        [11] = "|Hitem:87001:0:76700:76694:0:0:0:0:90:0:0|h[Ring]|h",
        [15] = "|Hitem:86991:4416:0:0:0:0:0:0:90:0:0|h[Umhang]|h",
    }

    _G.GetInventoryItemLink = function(_, slot) return EQUIPPED[slot] end

    -- Der Umhang hat keine Qualitaet: so meldet der Client einen
    -- Gegenstand, dessen Grunddaten noch nicht da sind.
    _G.GetItemInfo = function(link)
        if link == EQUIPPED[15] then return nil end
        return "Name", link, 4
    end

    _G.UnitName  = function() return "Njiah", "OokOok" end
    _G.UnitClass = function() return "Priester", "PRIEST" end
    _G.UnitRace  = function() return "Nachtelf", "NightElf" end
    _G.UnitLevel = function() return 90 end
    _G.GetRealmName = function() return "Ook Ook" end
    _G.GetCVar   = function() return "eu" end

    WeintCodex.Charakter = {
        EquipSlots = {
            { id = 1,  name = "Kopf" },
            { id = 11, name = "Finger 1" },
            { id = 15, name = "Umhang" },
        },
        GetProfileKey = function() return "PRIEST_HOLY" end,
    }

    WeintCodex.ReforgeEngine = {
        LinkParts = function(link)
            local data = link:match("|Hitem:([^|]+)")
            local parts, i = {}, 0
            for piece in (data .. ":"):gmatch("([^:]*):") do
                i = i + 1
                parts[i] = tonumber(piece)
            end
            return parts
        end,
        UpgradeLevel = function(_, id) return id == 86881 and 2 or 0 end,
    }

    local items, missing = QE.Collect()

    Check("Alle angelegten Slots gelesen", #items == 3, tostring(#items))
    Check("Der ungeladene Gegenstand wird gemeldet",
        #missing == 1 and missing[1] == "Umhang",
        tostring(missing[1]))

    local kopf = items[1]
    Check("Verzauberung aus dem Link", kopf.enchant == 4207)
    Check("Beide Steine aus dem Link",
        #kopf.gems == 2 and kopf.gems[1] == 76694 and kopf.gems[2] == 76700)
    Check("Aufwertungsstufe aus dem Umschmiede-Modul", kopf.upgrade == 2)

    -- Ein Ring ohne Verzauberung: das Feld steht im Link auf 0 und darf
    -- nicht als Verzauberung 0 im Text landen.
    local ring = items[2]
    Check("Keine Verzauberung bleibt keine", ring.enchant == 0)

    local text, gaps, written = QE.Export()

    Check("Der Text entsteht", text ~= nil, tostring(gaps))
    Check("Drei Gegenstaende geschrieben", written == 3, tostring(written))
    Check("Die Luecke reist mit",
        type(gaps) == "table" and #gaps == 1)

    -- Die Gegenprobe von QE.Export laeuft mit QE Lives eigener Regel.
    Check("Und ebenso viele kommen zurueck",
        #QE.ReadBack(text) == 3)

    Check("Die Klasse steht im Kopf",
        text:find('priest="Njiah"', 1, true) ~= nil)

    -- enchant = 0 darf nicht als `enchant_id=0` dastehen: drueben ist das
    -- eine Verzauberungsnummer, hier war es die Abwesenheit einer.
    Check("Verzauberung 0 steht nicht im Text",
        text:find("enchant_id=0", 1, true) == nil)
end

--== Die Gewichte ==========================================================

do
    local entry = QE.Entry("DRUID_RESTORATION")
    Check("Der Restodruide ist gefuehrt", entry ~= nil)

    local weights, gaps = QE.ScaleWeights(entry)

    -- Skaliert wird auf "groesstes Gewicht = 100", und bei jedem
    -- MoP-Heiler ist das die Intelligenz.
    Check("Intelligenz steht auf 100", weights.intellect == 100,
        tostring(weights.intellect))

    -- Die Verhaeltnisse bleiben: drueben spirit 1.022 gegen mastery 0.89,
    -- also muss Willenskraft ueber Meisterschaft liegen.
    Check("Willenskraft ueber Meisterschaft",
        weights.spirit > weights.mastery,
        ("%s / %s"):format(tostring(weights.spirit), tostring(weights.mastery)))
    Check("Meisterschaft ueber Krit",
        weights.mastery > weights.crit)
    Check("Keine Luecke beim Druiden", gaps == nil or #gaps == 0)

    -- Was QE Live nicht fuehrt, kommt auch nicht in unsere Skala: es gibt
    -- bei uns kein Feld dafuer, und eine erfundene Zahl waere von einer
    -- gemessenen nicht zu unterscheiden.
    Check("Zauberkraft faellt weg", weights.spellpower == nil)
    Check("mp5 faellt weg", weights.mp5 == nil)
end

do
    -- Beide Priester fuehren drueben Tempo mit 0. Eine 0 hiesse bei uns
    -- "egal", und der Umschmiede-Planer schmiedete das Tempo restlos weg
    -- — bei einer Spec, fuer die wir selbst eine Tempo-Treppe fuehren.
    local entry = QE.Entry("PRIEST_HOLY")
    local weights, gaps = QE.ScaleWeights(entry)

    Check("Tempo ist als Luecke gefuehrt",
        gaps and gaps[1] == "haste", tostring(gaps and gaps[1]))
    Check("… und steht deshalb NICHT im Vorschlag",
        weights.haste == nil, tostring(weights.haste))
    Check("… waehrend der Rest ankommt",
        weights.intellect == 100 and weights.spirit and weights.mastery)
end

--== Der Vorschlag =========================================================

do
    WeintCodex.SavedData = {}

    local pending = QE.OfferWeights("PALADIN_HOLY")
    Check("Der Vorschlag liegt bereit", pending ~= nil)
    Check("… und nennt seine Herkunft",
        pending and pending.source == "qelive")
    Check("… und hat nichts gespeichert",
        WeintCodex.SavedData.customWeights == nil)

    -- Uebernommen oder verworfen: beides heisst erledigt, und danach steht
    -- er nicht wieder da.
    SW.Resolve("PALADIN_HOLY")
    Check("Nach dem Erledigen kommt er nicht wieder",
        QE.OfferWeights("PALADIN_HOLY") == nil)
end

do
    WeintCodex.SavedData = {}

    -- EIN ZUGESTELLTER SIM-VORSCHLAG GEWINNT. Er ist zu diesem Charakter
    -- gerechnet; QE Lives Zahlen gelten fuer die Spec und fuer jeden
    -- gleich. Die schwaechere Auskunft darf die staerkere nicht
    -- verdraengen.
    SW.Offer({
        id = "sim-1", spec = "PALADIN_HOLY",
        weights = { intellect = 100, crit = 90 },
        source = "sim",
    })

    Check("Ein anliegender Sim-Vorschlag wird nicht ueberschrieben",
        QE.OfferWeights("PALADIN_HOLY") == nil)
    Check("… und bleibt unveraendert liegen",
        SW.Pending("PALADIN_HOLY").source == "sim")
end

do
    WeintCodex.SavedData = {}
    Check("Eine Spec ohne QE-Eintrag bekommt keinen Vorschlag",
        QE.OfferWeights("WARRIOR_ARMS") == nil)
    Check("… und auch keinen bei leerem Schluessel",
        QE.OfferWeights("") == nil)
end

--== Die Datendatei ========================================================
--
-- Dieselbe Haltung wie bei WeintCodex_ValidateGemWeights(): Funde sind
-- Datenfragen fuer einen Menschen. Der Testlauf haelt sie fest, damit sie
-- beim naechsten Abschreiben nicht durchrutschen.

do
    local seen = 0

    for key, entry in pairs(WeintCodex_QELive.specs) do
        seen = seen + 1
        local profile = WeintCodex_SpecProfiles[key]

        Check("Profil vorhanden: " .. key, profile ~= nil)
        Check("… und ein Heiler: " .. key,
            profile ~= nil and profile.role == "HEALER",
            tostring(profile and profile.role))
        Check("… mit Intelligenz-Gewicht: " .. key,
            (entry.weights.intellect or 0) > 0)

        -- Eine als Luecke gefuehrte Zahl darf nicht doch dastehen: dann
        -- waere sie drueben nachgetragen worden und wir hielten eine
        -- Auskunft zurueck, die es gibt.
        for _, gap in ipairs(entry.gaps or {}) do
            Check("… Luecke traegt keine Zahl: " .. key .. "/" .. gap,
                entry.weights[gap] == nil)
        end
    end

    -- QE Live fuehrt genau die sechs MoP-Heiler.
    Check("Sechs Spezialisierungen", seen == 6, tostring(seen))

    -- Der Waechter des Addons muss zu denselben Zahlen kommen.
    local said = {}
    local realPrint = print
    _G.print = function(line) said[#said + 1] = line end
    WeintCodex_ValidateQELiveData()
    _G.print = realPrint
    Check("Der Login-Waechter findet nichts zu melden", #said == 0,
        table.concat(said, " | "))
end

print(fails == 0 and "\nAlles bestanden." or ("\n" .. fails .. " Abweichung(en)."))
os.exit(fails == 0 and 0 or 1)
