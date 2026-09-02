--------------------------------------------------
-- WeintCodex :: QE Live — was jene Seite ueber MoP-Heiler sagt
--------------------------------------------------
-- Gesimmt wird fuer Schadensausteiler auf wowsims.com/mop. Fuer Heiler
-- ist die Adresse eine andere: questionablyepic.com/live, kurz QE Live.
-- Dessen "Classic" ist derzeit Mists of Pandaria, und alle sechs
-- MoP-Heiler sind dort vertreten — mehr als das, es ist das Werkzeug,
-- mit dem Heiler ihre Ausruestung tatsaechlich planen.
--
-- WAS DIESE DATEI TRAEGT, UND WAS AUSDRUECKLICH NICHT.
--
-- QE Live gibt KEINE charakterbezogene Gewichtung heraus. Das ist der
-- entscheidende Unterschied zu wowsims und der Grund, warum es hier
-- keinen Rueckweg gibt, der einem Sim-Ergebnis entspraeche: sein Top
-- Gear rechnet mit einem vollstaendigen Heilmodell und antwortet mit
-- einem Ausruestungssatz, nicht mit Zahlen je Wert.
--
-- Was es je Spezialisierung fuehrt, sind VORGABEGEWICHTE — dieselben
-- fuer jeden Spieler, aus dem Quelltext jener Seite. In QE Live selbst
-- speisen sie den Schmuckvergleich und den Schnellvergleich; das
-- Top-Gear-Ergebnis speisen sie nicht. Sie sind damit eine gute
-- Auskunft ueber die Spec und keine ueber DEINEN Charakter, und genau
-- so werden sie hier auch angeboten: als Vorschlag, den man ansieht,
-- nicht als Einstellung, die von selbst gilt.
--
-- DIE ROHZAHLEN STEHEN HIER, DIE SKALIERUNG PASSIERT IM CODE.
--
-- Aufgeschrieben ist, was drueben steht — Intelligenz um 1,2, alles
-- andere darunter. Auf unsere Skala ("groesstes Gewicht = 100") bringt
-- sie modules/qelive.lua, mit derselben Rechnung, die auch eine
-- eingefuegte Sim-Ausgabe durchlaeuft (SW.Normalize). Vorgerechnete
-- Zahlen liessen sich gegen die Quelle nicht mehr pruefen, und
-- abgeschrieben wird hier ohnehin schon genug.
--
-- EINE NULL IST HIER KEINE AUSSAGE, SONDERN EINE LUECKE.
--
-- Zwei Eintraege fuehren Tempo mit 0 (beide Priester; beim
-- Disziplin-Priester steht drueben sogar ein "TODO" daneben). Ein
-- Heiler, fuer den Tempo wertlos waere, gibt es in MoP nicht — und
-- unsere eigene Tempo-Treppe in data/breakpoints.lua fuehrt den
-- Heilig-Priester ausdruecklich. Eine 0 hiesse bei uns "egal", und der
-- Umschmiede-Planer schmiedete das Tempo restlos weg.
--
-- Solche Werte werden deshalb NICHT uebernommen (`gaps`): das Feld
-- behaelt den Wert des Spec-Profils, und die Seite sagt, dass QE Live
-- dafuer keine Zahl fuehrt. Dieselbe Linie wie ueberall sonst — was
-- nicht uebernommen wurde, wird gesagt, und eine geratene Zahl waere
-- von einer gemessenen nicht zu unterscheiden.
--
-- WAS ES BEI UNS NICHT GIBT, FAELLT WEG.
--
-- QE fuehrt ausserdem `spellpower`, `mp5`, `hps` und die Wirkung des
-- kritischen Multiplikators. Zauberkraft haengt in MoP an der
-- Intelligenz, mp5 steht auf keinem Ausruestungsteil dieser Erweiterung,
-- und die uebrigen beiden sind Eigenschaften des Kampfes und keine
-- Werte, die ein Stein oder eine Umschmiedung bewegt. Sie stehen der
-- Vollstaendigkeit halber unter `extra` und speisen nichts.
--
-- STAND UND HERKUNFT.
--
-- Quelle: github.com/Voulk/QuestionablyEpic, `defaultStatWeights` und
-- `autoReforgeOrder` je Spec unter
-- src/General/Modules/Player/ClassDefaults/Classic/. Abgeschrieben im
-- September 2026. Aendert sich drueben etwas, aendert es sich hier
-- nicht von selbst — dieselbe Handpflege wie bei data/enchants.lua,
-- und derselbe Grund, warum `/wc qe pruefen` jede Zahl ausdruckt.
--------------------------------------------------

WeintCodex_QELive = {

    -- Der Stand, auf den sich die Zahlen unten beziehen. Er steht in der
    -- Kennung des Vorschlags: aendert sich hier etwas, ist es ein neuer
    -- Vorschlag und wird erneut angeboten, statt unter dem "erledigt"
    -- von gestern zu verschwinden.
    stand = "2026-09",

    url = "https://questionablyepic.com/live/",

    -- QE Live kennt KEINE Adresse je Spezialisierung. Die Spec haengt
    -- dort am angelegten Charakter und wird im Werkzeug selbst gewaehlt
    -- — anders als bei wowsims, wo jede Spec ihre eigene Seite hat.
    -- Einen Link je Spec zu erfinden, fuehrte auf eine Seite, die es
    -- nicht gibt; deshalb steht hier nur die eine Adresse und die Seite
    -- sagt den Weg dorthin dazu.

    specs = {

        DRUID_RESTORATION = {
            label   = "Restoration Druid",
            weights = { intellect = 1.211, spirit = 1.022, mastery = 0.89,
                        haste = 0.7, crit = 0.683 },
            order   = { "mastery", "spirit", "crit", "haste", "hit" },
            extra   = { spellpower = 1, mp5 = 1.425, hps = 0.275 },
        },

        PALADIN_HOLY = {
            label   = "Holy Paladin",
            weights = { intellect = 1.204, mastery = 1.084, spirit = 0.712,
                        crit = 0.661, haste = 0.527 },
            order   = { "mastery", "crit", "spirit", "haste", "hit" },
            extra   = { spellpower = 1, mp5 = 0.972, hps = 0.293 },
            -- Drueben als "Default (Beta)" gefuehrt.
            beta    = true,
        },

        PRIEST_DISCIPLINE = {
            label   = "Discipline Priest",
            weights = { intellect = 1.28, mastery = 0.924, crit = 0.91,
                        spirit = 0.43 },
            -- Tempo steht drueben auf 0, mit einem "TODO" daneben.
            gaps    = { "haste" },
            order   = { "crit", "mastery", "spirit", "haste", "hit" },
            extra   = { spellpower = 1, mp5 = 0.763, hps = 0.124 },
        },

        PRIEST_HOLY = {
            label   = "Holy Priest",
            weights = { intellect = 1.21, spirit = 0.793, mastery = 0.82,
                        crit = 0.681 },
            -- Tempo steht drueben auf 0 — und diese Spec fuehrt bei uns
            -- eine Tempo-Treppe (data/breakpoints.lua).
            gaps    = { "haste" },
            order   = { "spirit", "crit", "mastery", "haste", "hit" },
            extra   = { spellpower = 1, mp5 = 1.405, hps = 0.227 },
        },

        SHAMAN_RESTORATION = {
            label   = "Restoration Shaman",
            weights = { intellect = 1.269, crit = 0.874, mastery = 0.718,
                        haste = 0.687, spirit = 0.457 },
            order   = { "crit", "haste", "spirit", "mastery", "hit" },
            extra   = { spellpower = 1, mp5 = 0.598, hps = 0.164 },
            beta    = true,
        },

        MONK_MISTWEAVER = {
            label   = "Mistweaver Monk",
            weights = { intellect = 1.245, crit = 0.795, mastery = 0.428,
                        spirit = 0.371, haste = 0.3 },
            order   = { "crit", "mastery", "spirit", "haste", "hit" },
            extra   = { spellpower = 1, mp5 = 0.657, hps = 0.206 },
        },

    },
}

--------------------------------------------------
-- Drift-Waechter
--
-- Dieselbe Bauart wie WeintCodex_ValidateGemWeights(): die Funde sind
-- Datenfragen fuer einen Menschen und nichts, was der Code wegrechnen
-- darf. Gemeldet wird, was von aussen nicht zu sehen waere —
--
--   * ein Profilschluessel, den es in data/spec_profiles.lua gar nicht
--     gibt (dann traegt der Vorschlag ins Leere),
--   * eine Spec, die dort kein Heiler ist (dann stimmt eine der beiden
--     Dateien nicht),
--   * ein Eintrag ohne Intelligenz (sie ist bei jedem MoP-Heiler der
--     Spitzenwert; fehlt sie, verschiebt die Skalierung alles),
--   * eine als Luecke gefuehrte Zahl, die in Wahrheit gesetzt ist —
--     dann ist die Luecke drueben geschlossen worden und der Eintrag
--     hier haelt eine Auskunft zurueck, die es gibt.
--------------------------------------------------

function WeintCodex_ValidateQELiveData()
    local data = WeintCodex_QELive
    if type(data) ~= "table" or type(data.specs) ~= "table" then return end

    local profiles = WeintCodex_SpecProfiles or {}
    local problems = {}

    for key, entry in pairs(data.specs) do
        local profile = profiles[key]

        if not profile then
            problems[#problems + 1] = key .. ": kein Spec-Profil dieses Namens"
        elseif profile.role ~= "HEALER" then
            problems[#problems + 1] = key .. ": ist in data/spec_profiles.lua"
                .. " kein Heiler (" .. tostring(profile.role) .. ")"
        end

        local weights = entry.weights or {}

        if not weights.intellect or weights.intellect <= 0 then
            problems[#problems + 1] = key .. ": ohne Intelligenz-Gewicht"
        end

        for _, gap in ipairs(entry.gaps or {}) do
            if weights[gap] and weights[gap] > 0 then
                problems[#problems + 1] = key .. ": " .. gap
                    .. " ist als Luecke gefuehrt, traegt aber eine Zahl"
            end
        end
    end

    if #problems == 0 then return end

    print("|cffD4A24A[WeintCodex]|r |cffff9900QE-Live-Daten:|r")
    for _, line in ipairs(problems) do
        print("  |cff4A4A52" .. line .. "|r")
    end
end
