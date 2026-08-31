-- Kopflose Pruefung des Sim-Gewichte-Imports (modules/statweights.lua).
--
-- Das Zerlegen einer fremden Zeichenkette ist genau die Sorte Rechnung, die
-- man ausserhalb des Spiels pruefen koennen muss: ein Muster, das ein Feld
-- verschluckt, faellt im Spiel erst auf, wenn jemand mit einer Gewichtung
-- rechnet, die zur Haelfte fehlt.
--
-- Geprueft werden BEIDE Lesewege:
--
--   1. der Paarleser, gegen mehrere Gestalten desselben Inhalts - kopierte
--      Tabelle, JSON-Zeile, getippte Liste. Ein Import, der nur eine davon
--      versteht, geht kaputt, sobald die Quelle ihre Ausgabe umstellt.
--   2. die Ausgabe von wowsims.com/mop, gegen eine ECHTE Ausgabe und nicht
--      gegen ein nachgebautes Beispiel - dort stehen keine Wertnamen,
--      sondern nur Zahlen, und welcher Wert gemeint ist, sagt allein die
--      Position. Ein nachgebautes Beispiel bestaetigte nur die eigene
--      Annahme ueber diese Reihenfolge.
--
--   lua5.1 .github/tests/statweights_test.lua .

local ROOT = ...

WeintCodex = {}
dofile(ROOT .. "/modules/statweights.lua")
local SW = WeintCodex.StatWeights

local fails = 0
local function Check(name, ok, detail)
    print(string.format("%-48s %s", name, ok and "ok" or ("ABWEICHUNG  " .. (detail or ""))))
    if not ok then fails = fails + 1 end
end

local function Show(t)
    if not t then return "nil" end
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end
    table.sort(keys)
    local out = {}
    for _, k in ipairs(keys) do out[#out + 1] = k .. "=" .. t[k] end
    return table.concat(out, " ")
end

local function Weights(text)
    local raw = SW.Parse(text)
    return (SW.Normalize(raw))
end

--== Dieselben Zahlen in vier Gestalten =====================================
-- Beweglichkeit 1.00, Treffer 0.88, Krit 0.68 - egal wie geschrieben.
do
    local want = "agility=100 crit=68 hit=88"

    local forms = {
        ["Ausgabezeichenkette"] =
            '( X: v1: "WW Monk": Agility=1.00, HitRating=0.88, CritRating=0.68 )',
        ["blosse Paarliste"] =
            "Agility=1.00, HitRating=0.88, CritRating=0.68",
        ["kopierte Tabelle"] =
            "Agility\t1.00\nHit Rating\t0.88\nCrit Rating\t0.68",
        ["JSON-Zeile"] =
            '{ "Agility": 1.00, "HitRating": 0.88, "CritRating": 0.68 }',
        ["deutsch getippt"] =
            "Beweglichkeit 1,0\nTrefferwertung 0.88\nKritische Trefferwertung 0.68",
    }

    for label, text in pairs(forms) do
        local w = Weights(text)
        Check("Gelesen: " .. label, Show(w) == want, Show(w))
    end
end

--== Das deutsche Dezimalkomma =============================================
do
    -- "Krit 0,68" darf nicht als "Krit 0" gelesen werden - der Wert fiele
    -- still auf null, und genau das faellt niemandem auf.
    local w = Weights("Beweglichkeit 1,00\nKrit 0,68\nTempo 0,75")
    Check("Komma als Nachkommastelle",
        w and w.agility == 100 and w.crit == 68 and w.haste == 75, Show(w))

    -- Dieselben Zahlen in Tausenderschreibweise. Weil nach dem Lesen auf
    -- "groesstes Gewicht = 100" skaliert wird, muss dabei DASSELBE
    -- herauskommen - egal, ob das Komma als Nachkommastelle oder als
    -- Tausendertrennzeichen gelesen wurde. Entscheidend ist nur, dass die
    -- Lesart innerhalb eines Textes einheitlich ist.
    local t = Weights("Strength 3,400\nCritRating 1,870")
    Check("Komma ohne Punkte im Text",
        t and t.strength == 100 and t.crit == 55, Show(t))

    -- Und mit Punktschreibweise daneben wird das Komma zum Tausender.
    local e = Weights("Strength 3,400\nCritRating 1,870\nHasteRating 1700.0")
    Check("Komma neben Punktschreibweise",
        e and e.strength == 100 and e.crit == 55 and e.haste == 50, Show(e))

    -- Und ein Komma zwischen zwei Paaren trennt weiterhin.
    local c = Weights("Agility=1,CritRating=0.5")
    Check("Komma trennt weiterhin zwei Paare",
        c and c.agility == 100 and c.crit == 50, Show(c))
end

--== Der Maszstab ===========================================================
do
    -- Sims geben Bruchteile heraus, andere Quellen grosse Zahlen. Beides
    -- landet auf derselben Skala, und die Verhaeltnisse bleiben.
    local a = Weights("Strength=1, CritRating=0.55, HasteRating=0.5")
    local b = Weights("Strength=3400, CritRating=1870, HasteRating=1700")
    Check("Bruchteile und grosse Zahlen ergeben dasselbe",
        Show(a) == Show(b) and a and a.strength == 100 and a.crit == 55,
        Show(a) .. "  /  " .. Show(b))
end

--== Fremde Schluessel ======================================================
do
    -- Eine Sim-Ausgabe traegt Dinge wie Dps oder MetaSocketEffect. Sie
    -- duerfen die Skalierung nicht verzerren - und sie muessen gemeldet
    -- werden, sonst haelt man das Ergebnis fuer vollstaendig.
    local raw, _, ignored = SW.Parse(
        "Agility=1, CritRating=0.5, Dps=980, MetaSocketEffect=41")
    local w = SW.Normalize(raw)
    Check("Dps verzerrt die Skala nicht",
        w and w.agility == 100 and w.crit == 50 and w.dps == nil, Show(w))

    local named = table.concat(ignored or {}, ",")
    Check("Unbekannte Namen werden gemeldet",
        named:find("Dps", 1, true) and named:find("MetaSocketEffect", 1, true),
        named)
end

--== Ein Wert, zwei Namen ===================================================
do
    local w = Weights("Intellect=1, SpellHitRating=0.9, HitRating=0.6")
    -- Es ist EIN Wert, nicht zwei: addiert werden darf hier nichts.
    Check("Zwei Namen fuer Treffer werden nicht addiert", w and w.hit == 90, Show(w))
end

--== Zweiwortnamen ==========================================================
do
    -- "Crit Rating" muss als EIN Name gelesen werden. Wird nur das letzte
    -- Wort genommen, trifft "Rating" nie zu und der Wert faellt weg.
    local w = Weights("Agility 1  Crit Rating 0.5  Haste Rating 0.25")
    Check("Zweiwortnamen werden zusammengezogen",
        w and w.agility == 100 and w.crit == 50 and w.haste == 25, Show(w))
end

--== Negative Gewichte ======================================================
do
    local raw = SW.Parse("Agility=1, Strength=-1, CritRating=0.5")
    local w, negatives = SW.Normalize(raw)
    -- Unsere Skala kennt "egal", nicht "meiden" - das wird gesagt, nicht
    -- stillschweigend gemacht.
    Check("Negatives wird 0 und gemeldet",
        w and w.strength == nil and w.agility == 100
          and negatives and #negatives == 1 and negatives[1] == "strength",
        Show(w))
end

--== Was nicht gelesen werden kann, sagt es =================================
do
    local a = SW.Parse("")
    local b = SW.Parse("völliger Unsinn ohne eine einzige Zahl")
    Check("Leer und Unsinn werden abgelehnt", a == nil and b == nil)

    -- Eine Liste, in der alles 0 ist, ergibt keine Gewichtung - statt einer
    -- stillen leeren.
    Check("Alles 0 ergibt keine Gewichtung",
        SW.Normalize(SW.Parse("Agility=0, CritRating=0")) == nil)

    -- Und eine Zahl ohne Namen davor erfindet keinen Wert.
    Check("Blosse Zahlen erfinden nichts", SW.Parse("1 2 3 4") == nil)
end

--== Die Ausgabe von wowsims.com/mop ========================================
-- Der zweite Leseweg. Er ist als einziger an EIN fremdes Format gebunden,
-- weil in dieser Ausgabe keine Wertnamen stehen: die Gewichte liegen als
-- blosse Zahlenreihe da, und welcher Wert gemeint ist, sagt allein die
-- Position. Genau deshalb wird er hier gegen eine ECHTE Ausgabe geprueft
-- und nicht gegen ein nachgebautes Beispiel - ein nachgebautes bestaetigt
-- nur die eigene Annahme.
--
-- Die folgende Zeichenkette ist unveraendert die, die der Sim nach
-- "Suggest Reforges" fuer einen Blut-Todesritter ausgibt.
local SIM = [==[
{"apiVersion":3,"settings":{"iterations":25000,"phase":5,"showDamageMetrics":true,"showThreatMetrics":true,"showHealingMetrics":true,"showQuickSwap":true,"language":"en","faction":"Alliance","filters":{"armorTypes":["ArmorTypePlate"],"oneHandedWeapons":true,"twoHandedWeapons":true}},"raidBuffs":{"trueshotAura":true,"serpentsSwiftness":true,"elementalOath":true,"leaderOfThePack":true,"blessingOfMight":true,"blessingOfKings":true,"powerWordFortitude":true,"bloodlust":true,"stormlashTotemCount":4,"skullBannerCount":2},"debuffs":{"weakenedBlows":true,"physicalVulnerability":true,"weakenedArmor":true,"curseOfElements":true},"tanks":[{"type":"Player"}],"partyBuffs":{},"player":{"name":"Player","race":"RaceBloodElf","class":"ClassDeathKnight","equipment":{"items":[{"id":86920,"gems":[76895,76639],"reforging":161,"upgradeStep":"UpgradeStepTwo"},{"id":90509,"reforging":125,"upgradeStep":"UpgradeStepTwo"},{"id":89921,"enchant":4805,"gems":[76653],"upgradeStep":"UpgradeStepTwo"},{"id":87159,"enchant":4422,"reforging":125,"upgradeStep":"UpgradeStepTwo"},{"id":86918,"enchant":4420,"gems":[76653,76653],"reforging":140,"upgradeStep":"UpgradeStepTwo"},{"id":90506,"enchant":4411,"gems":[76639],"reforging":164,"upgradeStep":"UpgradeStepTwo"},{"id":89946,"enchant":4431,"gems":[76639,76639],"reforging":161,"upgradeStep":"UpgradeStepTwo","tinker":4898},{"id":89919,"gems":[76653,76639,76639],"reforging":143,"upgradeStep":"UpgradeStepTwo","tinker":4223},{"id":89928,"enchant":4824,"gems":[76690,76639],"reforging":122,"upgradeStep":"UpgradeStepTwo"},{"id":90507,"enchant":4429,"gems":[76653],"reforging":140,"upgradeStep":"UpgradeStepTwo"},{"id":86946,"upgradeStep":"UpgradeStepTwo"},{"id":87158,"reforging":143,"upgradeStep":"UpgradeStepTwo"},{"id":87172,"upgradeStep":"UpgradeStepTwo"},{"id":86046,"upgradeStep":"UpgradeStepTwo"},{"id":87176,"enchant":3368,"gems":[89881,76639],"reforging":143,"upgradeStep":"UpgradeStepTwo"},{}]},"consumables":{"potId":76090,"flaskId":76087,"foodId":74656,"conjuredId":5512},"bonusStats":{"apiVersion":3,"stats":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"pseudoStats":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]},"buffs":{"devotionAuraCount":2,"painSuppressionCount":1,"vigilanceCount":2,"rallyingCryCount":2},"bloodDeathKnight":{"options":{"classOptions":{}}},"talentsString":"231111","glyphs":{"major1":104047,"major2":104048,"major3":43536,"minor1":104101,"minor2":43550,"minor3":43672},"profession1":"Engineering","profession2":"Blacksmithing","cooldowns":{"hpPercentForDefensives":0.3},"reactionTimeMs":750,"inFrontOfTarget":true,"distanceFromTarget":5,"healingModel":{"hps":100000,"cadenceSeconds":0.4,"cadenceVariation":2.1,"absorbFrac":0.107,"burstWindow":6}},"encounter":{"apiVersion":3,"duration":620,"durationVariation":16,"executeProportion20":0.2,"executeProportion25":0.25,"executeProportion35":0.35,"executeProportion45":0.45,"executeProportion90":0.9,"targets":[{"id":60999,"name":"Sha of Fear 25 H","level":93,"mobType":"MobTypeElemental","stats":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,24835,0,1632111860,0,0],"minBaseDamage":620921,"damageSpread":0.6195,"swingSpeed":2.5}]},"epWeightsStats":{"apiVersion":3,"stats":[1,0,1.02,0,0,1.77,0.85,0.89,1.5,0.97,0.99,0.98,0.23,0,0,0,0,0.57,0.57,0,0,0],"pseudoStats":[1.94,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]},"epRatios":[0,1,1,1,0,0],"reforgeSettings":{"useSoftCapBreakpoints":true,"includeTimeout":true,"statCaps":{"apiVersion":3,"stats":[0,0,0,0,0,0,0,0,5100,0,0,0,0,0,0,0,0,0,0,0,0,0],"pseudoStats":[0,0,0,0,0,0,0,0,0,0,0,0,7.5,0,0,0]},"breakpointLimits":{"apiVersion":3,"stats":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"pseudoStats":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]}}}
]==]

do
    local raw, problem, ignored, info = SW.Parse(SIM)
    Check("Sim-Ausgabe wird ueberhaupt gelesen", raw ~= nil, problem)
    Check("… und als Sim-Ausgabe erkannt", info and info.source == "sim")

    -- Die Positionen, an denen ein Irrtum unbemerkt bliebe. Belegt ist die
    -- Zuordnung an der Klasse (Todesritter: Staerke ja, Beweglichkeit und
    -- Intelligenz nein) und an der Grenze weiter unten.
    Check("Staerke steht auf Platz 0",   raw and raw.strength == 1, tostring(raw and raw.strength))
    Check("Beweglichkeit bleibt 0",      raw and raw.agility == nil)
    Check("Ausdauer steht auf Platz 2",  raw and raw.stamina == 1.02, tostring(raw and raw.stamina))
    Check("Treffer steht auf Platz 5",   raw and raw.hit == 1.77, tostring(raw and raw.hit))
    Check("Krit steht auf Platz 6",      raw and raw.crit == 0.85, tostring(raw and raw.crit))
    Check("Tempo steht auf Platz 7",     raw and raw.haste == 0.89, tostring(raw and raw.haste))
    Check("Waffenkunde steht auf Platz 8", raw and raw.expertise == 1.5, tostring(raw and raw.expertise))
    Check("Ausweichen steht auf Platz 9", raw and raw.dodge == 0.97, tostring(raw and raw.dodge))
    Check("Parieren steht auf Platz 10", raw and raw.parry == 0.99, tostring(raw and raw.parry))
    Check("Meisterschaft steht auf Platz 11", raw and raw.mastery == 0.98, tostring(raw and raw.mastery))

    local w = SW.Normalize(raw)
    Check("Skaliert auf groesstes Gewicht = 100",
        w and w.hit == 100 and w.strength == 56 and w.expertise == 85, Show(w))

    -- Angriffskraft, Ruestung und Waffenschaden gewichtet der Sim mit,
    -- WeintCodex kennt sie nicht. Sie duerfen weder mitgerechnet noch
    -- verschwiegen werden.
    local named = table.concat(ignored or {}, ", ")
    Check("Nicht uebernommene Werte werden gemeldet",
        named:find("Angriffskraft", 1, true)
        and named:find("Rüstung", 1, true)
        and named:find("Waffenschaden", 1, true), named)

    -- Die Klasse ist die einzige Auskunft, an der auffaellt, dass jemand
    -- die Ausgabe eines fremden Charakters eingefuegt hat.
    Check("Die Klasse wird gelesen", info and info.class == "DEATHKNIGHT",
        tostring(info and info.class))
end

--== Die Grenzen aus der Sim-Ausgabe ========================================
do
    local _, _, _, info = SW.Parse(SIM)
    local byStat = {}
    for _, cap in ipairs((info and info.caps) or {}) do byStat[cap.stat] = cap end

    -- Waffenkunde steht dort als WERTUNG, die Trefferchance als PROZENT.
    -- Beides bleibt so stehen; umgerechnet wird erst beim Vergleich.
    Check("Waffenkunde-Grenze als Wertung",
        byStat.expertise and byStat.expertise.rating == 5100
            and byStat.expertise.pct == nil,
        tostring(byStat.expertise and byStat.expertise.rating))
    Check("Treffer-Grenze als Prozent",
        byStat.hit and byStat.hit.pct == 7.5 and byStat.hit.rating == nil,
        tostring(byStat.hit and byStat.hit.pct))

    -- 5100 Wertung sind auf Stufe 90 genau 15 % - und 15 % steht im
    -- Spec-Profil des Blut-Todesritters. Das ist die Gegenprobe auf die
    -- ganze Positionstabelle: laege Platz 8 woanders, kaeme hier Unsinn
    -- heraus.
    Check("5100 Wertung sind 15 Prozent",
        math.abs(SW.CapPercent(byStat.expertise) - 15) < 0.001,
        tostring(SW.CapPercent(byStat.expertise)))
    -- Und mit der Umrechnung, die der Client meldet, wird gerechnet statt
    -- mit der Zahl fuer Stufe 90.
    Check("Die Umrechnung des Clients gewinnt",
        math.abs(SW.CapPercent(byStat.expertise, 300) - 17) < 0.001,
        tostring(SW.CapPercent(byStat.expertise, 300)))
    Check("Eine Prozentgrenze wird nicht umgerechnet",
        SW.CapPercent(byStat.hit, 300) == 7.5)
end

--== Verschiebt der Sim seine Reihenfolge, wird nichts geraten ==============
do
    -- Der Fehler, der sonst niemandem auffiele: jeder Wert bekaeme lautlos
    -- das Gewicht eines anderen, und die Gewichtung saehe vollstaendig aus.
    -- Dieselbe Fehlerklasse wie die laufende Nummer des Umschmieders.
    local short = SIM:gsub('"epWeightsStats":{"apiVersion":3,"stats":%[[^%]]*%]',
        '"epWeightsStats":{"apiVersion":3,"stats":[1,0,1.02,0,0,1.77,0.85]')
    local raw, problem = SW.Parse(short)
    Check("Andere Laenge wird abgelehnt", raw == nil, Show(raw))
    Check("… und sagt, dass die Reihenfolge nicht mehr passt",
        problem and problem:find("Reihenfolge", 1, true) ~= nil, problem)
end

--== Eine Sim-Ausgabe ohne Gewichte =========================================
do
    -- Wer exportiert, ohne rechnen zu lassen, bekommt eine Ausgabe ohne
    -- epWeightsStats. Darauf hilfsweise den Paarleser loszulassen waere die
    -- stille Falschauskunft: der faende in den Schluesselnamen und Zahlen
    -- dieser Zeichenkette durchaus etwas.
    local without = SIM:gsub('"epWeightsStats"', '"epWeightsStatsX"')
    local raw, problem = SW.Parse(without)
    Check("Sim-Ausgabe ohne Gewichte wird abgelehnt", raw == nil, Show(raw))
    Check("… und sagt, was zu tun ist",
        problem and problem:find("Suggest Reforges", 1, true) ~= nil, problem)
end

--== Der Paarleser bleibt der Normalfall ====================================
do
    -- Eine gewoehnliche Paarliste darf nicht in den Sim-Weg geraten.
    local _, _, _, info = SW.Parse("Agility=1, CritRating=0.5")
    Check("Paarliste bleibt beim Paarleser", info and info.source == "pairs",
        tostring(info and info.source))
end

--== Kein fremdes Addon =====================================================
do
    -- Diese Datei darf die gespeicherten Daten keines anderen Addons
    -- anfassen. Geprueft wird strukturell, nicht am Verhalten.
    local f = io.open(ROOT .. "/modules/statweights.lua", "r")
    local text = f:read("*a")
    f:close()
    local hits = {}
    for line in text:gmatch("[^\r\n]+") do
        if not line:match("^%s*%-%-") and line:match("Pawn") then
            hits[#hits + 1] = line
        end
    end
    Check("Kein Zugriff auf ein fremdes Addon", #hits == 0, hits[1])
end

--== Der Uebertragungsstring aus der Companion ==============================
-- Er ist der Weg OHNE /reload. Erzeugt wird er drueben in
-- core/stat_weights.build_transfer(); zerlegt hier. Laufen die beiden
-- auseinander, kommt eine Gewichtung an, die zur Haelfte fehlt - und das
-- sieht von aussen aus wie ein Sim, der nichts geliefert hat.
do
    local text = "WCIMPORT:SW:DEATHKNIGHT_BLOOD:84474e371e1f:1788186037::sim:"
        .. "strength|56,stamina|58,hit|100,expertise|85,crit|48,haste|50,"
        .. "mastery|55,dodge|55,parry|56"

    -- Die Nutzlast steht hinter "WCIMPORT:SW:" - so uebergibt sie
    -- modules/sync.lua.
    local payload = text:match("^WCIMPORT:SW:(.+)$")
    local entry, problem = SW.ParseTransfer(payload)

    Check("Uebertragungsstring wird gelesen", entry ~= nil, problem)
    Check("… mit der Spezialisierung",
        entry and entry.spec == "DEATHKNIGHT_BLOOD", entry and entry.spec)
    Check("… mit der Kennung",
        entry and entry.id == "84474e371e1f", entry and entry.id)
    Check("… und allen neun Gewichten",
        entry and entry.weights.hit == 100 and entry.weights.strength == 56
        and entry.weights.parry == 56, Show(entry and entry.weights))

    -- Ein leeres Charakterfeld darf keinen Abschnitt verschieben: der
    -- Name kommt aus dem Spiel und ist oft gar nicht bekannt.
    Check("Leeres Charakterfeld verschiebt nichts",
        entry and entry.character == "", entry and entry.character)
end

do
    -- Ohne Spezialisierung liesse sich die Gewichtung keinem Profil
    -- zuordnen. Eine zu raten waere die stille Falschauskunft.
    local entry, problem = SW.ParseTransfer(":abc:0::sim:hit|100")
    Check("Ohne Spezialisierung wird abgelehnt", entry == nil)
    Check("… und sagt warum",
        problem and problem:find("Spezialisierung", 1, true) ~= nil, problem)

    local none = SW.ParseTransfer("MAGE_FIRE:abc:0::sim:")
    Check("Ohne ein einziges Gewicht wird abgelehnt", none == nil)
end

--== Ein Vorschlag wird hingelegt, nicht angewendet =========================
-- Der ganze Ablauf haengt am Gedaechtnis: dieselbe Liste kommt bei jedem
-- Login erneut, und ohne `seen` stuende ein gestern uebernommener
-- Vorschlag heute wieder da.
do
    WeintCodex.SavedData = {}

    local entry = {
        id = "abc123", spec = "MAGE_FIRE",
        weights = { intellect = 100, crit = 80 },
        created = 1788186037,
    }

    local ok = SW.Offer(entry)
    Check("Vorschlag liegt bereit", ok == true)
    Check("… und ist unter seiner Spec zu finden",
        SW.Pending("MAGE_FIRE") ~= nil)
    Check("… aber nicht unter einer anderen",
        SW.Pending("MAGE_FROST") == nil)

    -- Er darf die gespeicherte Gewichtung NICHT angefasst haben.
    Check("Nichts wurde gespeichert",
        WeintCodex.SavedData.customWeights == nil)

    SW.Resolve("MAGE_FIRE")
    Check("Nach dem Erledigen liegt nichts mehr an",
        SW.Pending("MAGE_FIRE") == nil)

    local again = SW.Offer(entry)
    Check("Dieselbe Zustellung wird nicht erneut angeboten", again == false)
    Check("… und legt auch nichts hin", SW.Pending("MAGE_FIRE") == nil)

    -- Von Hand eingefuegt wird immer angeboten: wer den String selbst
    -- einsetzt, hat ihn gerade angefasst.
    local forced = SW.Offer(entry, true)
    Check("Von Hand eingefuegt wird trotzdem angeboten", forced == true)

    -- Eine geaenderte Gewichtung ist ein neuer Vorschlag - die Kennung
    -- haengt drueben am Inhalt.
    SW.Resolve("MAGE_FIRE")
    local changed = SW.Offer({
        id = "def456", spec = "MAGE_FIRE",
        weights = { intellect = 100, crit = 90 },
    })
    Check("Eine andere Kennung ist ein neuer Vorschlag", changed == true)
end

do
    WeintCodex.SavedData = {}

    -- Ohne Gewicht ueber null hat ein Vorschlag nichts zu sagen; ohne
    -- Spec liesse er sich nicht zuordnen.
    Check("Vorschlag ohne Gewichte wird abgelehnt",
        SW.Offer({ id = "x", spec = "MAGE_FIRE", weights = {} }) == false)
    Check("Vorschlag ohne Spezialisierung wird abgelehnt",
        SW.Offer({ id = "x", weights = { crit = 50 } }) == false)
end

print(fails == 0 and "\nAlles bestanden." or ("\n" .. fails .. " Abweichung(en)."))
os.exit(fails == 0 and 0 or 1)
