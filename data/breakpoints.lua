--------------------------------------------------
-- WeintCodex :: Tempo-Schwellen (Breakpoints)
-- Mists of Pandaria Classic
--
-- WOZU DIESE DATEI DA IST
--
-- Bis 2.6.1.1 kannte das Addon genau zwei Grenzen: Trefferwertung und
-- Waffenkunde. Beide sind Decken — darueber ist jeder weitere Punkt
-- nachweislich wertlos, und `headroom` in modules/charakter.lua rechnet
-- genau damit. Tempo hat so eine Decke nicht, aber es hat eine Treppe:
-- ein periodischer Effekt gewinnt einen Tick, sobald genug Tempo da ist,
-- und zwischen zwei Stufen aendert sich an der Tickzahl nichts.
--
-- Gemeldet wurde die Folge davon: "es wird immer noch ein Tempostein
-- vorgeschlagen, obwohl man am Cap ist". Das Addon konnte das gar nicht
-- wissen — Tempo war fuer den Planer ein Wert ohne Obergrenze.
--
-- DIE STUFEN WERDEN GERECHNET, NICHT ABGESCHRIEBEN
--
-- In MoP kuerzt Tempo den Tickabstand, nicht die Laufzeit; die Tickzahl
-- ist deshalb
--
--     Ticks = round(Laufzeit * (1 + Tempo) / Grundabstand)
--
-- und damit steht die Stufe fuer den N-ten Tick fest:
--
--     Tempo >= (N - 0,5) * Grundabstand / Laufzeit - 1
--
-- Hier stehen deshalb NUR Laufzeit und Grundabstand je Effekt — zwei
-- Zahlen, die jeder im Spiel am Zauberbuch nachsehen kann. Die Prozente
-- rechnet WeintCodex_BreakpointLadder() daraus aus. Eine Tabelle
-- abgeschriebener Wertungszahlen ("3.043 Tempo") waere das Gegenteil:
-- sie gilt nur fuer eine Stufe, eine Buffkombination und einen Guide,
-- und niemand koennte ihr ansehen, ob sie noch stimmt. Dieselbe
-- Ueberlegung wie bei den Verzauberungs-IDs in data/enchants.lua, nur
-- mit besserem Ausgang: hier ist die Herkunft nachrechenbar.
--
-- WER HIER STEHT, TRIFFT DAMIT EINE AUSSAGE
--
-- Ein Eintrag in dieser Datei heisst: fuer diese Spec ist Tempo ein
-- SCHWELLENWERT. Ist die naechste Stufe ausser Reichweite, ist weiteres
-- Tempo nichts mehr wert und gehoert umgeschmiedet — das ist fuer eine
-- DoT-/HoT-Spec der Rat jedes Guides, und genau das rechnet
-- modules/charakter.lua dann auch (Spielraum 0, wie am Trefferkap).
--
-- Fuer eine Spec, deren Tempo vor allem Zauberzeit und Ressourcen
-- bringt, waere dieselbe Aussage falsch. Solche Specs stehen deshalb
-- NICHT hier, und fuer sie aendert sich nichts. Eine fehlende Spec ist
-- kein Versaeumnis, sondern die ehrlichere Auskunft — dieselbe Regel wie
-- bei den Rotationslisten der Tankspecs.
--
-- WAS DAS ADDON NICHT ENTSCHEIDET
--
-- Ob eine Stufe erreichbar ist, haengt an Ausruestung, Umschmieden und
-- Raidbuffs. Das rechnet modules/charakter.lua live aus (Umschmiede-
-- Reserve + freie Sockel) und legt das Ziel danach fest; wem das nicht
-- passt, der setzt es auf der Seite "Werteverteilung & Caps" selbst.
-- Ein hier hineingeschriebenes Wunschziel waere geraten — der
-- Charakterbogen des Spielers ist die bessere Quelle.
--
-- ZAHLEN, DIE NOCH ZU BESTAETIGEN SIND
--
-- `verify = true` heisst: Laufzeit/Abstand stammen aus der Datenlage zu
-- MoP 5.4 und sind am Client dieser Installation nicht geprueft. Der
-- Eintrag wird trotzdem benutzt (wie in data/enchants.lua), und
-- /wc tempo druckt zu jeder Stufe ihre Herleitung aus, damit ein
-- falscher Wert auffaellt und nicht stillschweigend Empfehlungen
-- traegt.
--------------------------------------------------

-- Ueber dieser Grenze wird keine Stufe mehr erzeugt. 100 % Tempo ist in
-- MoP mit Ausruestung nicht erreichbar; hoehere Stufen waeren Zeilen
-- ohne Leser.
local MAX_LADDER_PCT = 100

WeintCodex_Breakpoints = {

    --------------------------------------------------
    -- PRIESTER
    --------------------------------------------------

    PRIEST_SHADOW = {
        stat = "haste", typ = "spell",
        note = "Schatten lebt von den Ticks seiner beiden DoTs — zwischen"
            .. " zwei Stufen bringt Tempo nur Gedankenschinden-Ticks,"
            .. " deshalb ist die erreichbare Stufe das Ziel.",
        effects = {
            { spellId = 589,   name = "Schattenwort: Pein", duration = 18, tick = 3, verify = true },
            { spellId = 34914, name = "Vampirberührung",    duration = 15, tick = 3, verify = true },
        },
    },

    PRIEST_HOLY = {
        stat = "haste", typ = "spell",
        note = "Erneuerung ist der einzige Zauber, dessen Tickzahl an"
            .. " Tempo haengt; darueber hinaus zaehlt Willenskraft.",
        effects = {
            { spellId = 139, name = "Erneuerung", duration = 12, tick = 3, verify = true },
        },
    },

    --------------------------------------------------
    -- HEXENMEISTER
    --------------------------------------------------

    WARLOCK_AFFLICTION = {
        stat = "haste", typ = "spell",
        note = "Gebrechen ist die Schwellen-Spec schlechthin: drei DoTs,"
            .. " und der Schaden steckt fast vollstaendig in ihren Ticks.",
        effects = {
            { spellId = 172,   name = "Verderbnis",            duration = 18, tick = 2, verify = true },
            { spellId = 980,   name = "Pein",                  duration = 24, tick = 2, verify = true },
            { spellId = 30108, name = "Instabiles Gebrechen",  duration = 14, tick = 2, verify = true },
        },
    },

    WARLOCK_DESTRUCTION = {
        stat = "haste", typ = "spell",
        note = "Feuerbrand traegt die Glutsteine — ein Tick mehr ist eine"
            .. " Glut mehr, dazwischen aendert Tempo daran nichts.",
        effects = {
            { spellId = 348, name = "Feuerbrand", duration = 15, tick = 3, verify = true },
        },
    },

    --------------------------------------------------
    -- DRUIDE
    --------------------------------------------------

    DRUID_BALANCE = {
        stat = "haste", typ = "spell",
        note = "Mondfeuer und Sonnenfeuer haben dieselbe Laufzeit und"
            .. " denselben Abstand, also auch dieselbe Treppe.",
        effects = {
            { spellId = 8921, name = "Mondfeuer",   duration = 14, tick = 2, verify = true },
            { spellId = 93402, name = "Sonnenfeuer", duration = 14, tick = 2, verify = true },
        },
    },

    DRUID_RESTORATION = {
        stat = "haste", typ = "spell",
        note = "Verjuengung ist der Grundstock jeder Heilung dieser Spec;"
            .. " Wildwuchs liegt so dicht, dass beide Treppen zaehlen.",
        effects = {
            { spellId = 774,   name = "Verjüngung", duration = 12, tick = 3, verify = true },
            { spellId = 48438, name = "Wildwuchs",  duration = 7,  tick = 1, verify = true },
        },
    },

    --------------------------------------------------
    -- MÖNCH
    --------------------------------------------------

    MONK_MISTWEAVER = {
        stat = "haste", typ = "spell",
        note = "Erneuernder Nebel traegt die Verbreitung; ein Tick mehr"
            .. " ist mehr Zeit fuer den Sprung.",
        effects = {
            { spellId = 115151, name = "Erneuernder Nebel", duration = 18, tick = 3, verify = true },
        },
    },

    --------------------------------------------------
    -- SCHAMANE
    --------------------------------------------------

    SHAMAN_RESTORATION = {
        stat = "haste", typ = "spell",
        note = "Springflut ist der HoT, dessen Tickzahl an Tempo haengt.",
        effects = {
            { spellId = 61295, name = "Springflut", duration = 18, tick = 3, verify = true },
        },
    },
}

--------------------------------------------------
-- DIE TREPPE EINER SPEC
--
-- Erzeugt aus Laufzeit/Abstand jeder Stufe ihren Tempo-Prozentsatz. Die
-- Grundtickzahl (Laufzeit / Abstand) ist die Zahl OHNE Tempo; erzeugt
-- werden die Stufen darueber, solange sie unter MAX_LADDER_PCT liegen.
--
-- Rueckgabe: aufsteigend sortierte Liste
--   { pct, ticks, effect, label }
--
-- Zwei Stufen koennen sehr dicht beieinanderliegen (Schatten: 8,33 % und
-- 10,00 %). Zusammengefasst wird nichts — es sind zwei verschiedene
-- Aussagen ueber zwei verschiedene Zauber, und wer sein Ziel setzt, will
-- wissen, welcher gemeint ist.
--------------------------------------------------

function WeintCodex_BreakpointPct(duration, tick, ticks)
    if not (duration and tick and ticks) or duration <= 0 or tick <= 0 then
        return nil
    end
    return ((ticks - 0.5) * tick / duration - 1) * 100
end

local ladderCache = {}

function WeintCodex_BreakpointLadder(specKey)
    if not specKey then return nil end
    local cached = ladderCache[specKey]
    if cached ~= nil then
        return (cached ~= false) and cached or nil
    end

    local def = WeintCodex_Breakpoints and WeintCodex_Breakpoints[specKey]
    if not (def and def.effects) then
        ladderCache[specKey] = false
        return nil
    end

    local rungs = {}
    for _, effect in ipairs(def.effects) do
        local base = effect.duration / effect.tick
        local ticks = math.floor(base + 0.5) + 1
        while true do
            local pct = WeintCodex_BreakpointPct(effect.duration, effect.tick, ticks)
            if not pct or pct > MAX_LADDER_PCT then break end
            if pct > 0 then
                rungs[#rungs + 1] = {
                    pct    = pct,
                    ticks  = ticks,
                    effect = effect,
                    label  = string.format("%s, %d. Tick", effect.name, ticks),
                }
            end
            ticks = ticks + 1
        end
    end

    table.sort(rungs, function(a, b)
        if a.pct == b.pct then return a.label < b.label end
        return a.pct < b.pct
    end)

    ladderCache[specKey] = rungs
    return rungs
end

--------------------------------------------------
-- DATENPRÜFUNG (Login, analog WeintCodex_ValidateSpecData)
--
-- Geprueft wird, was sich hier ueberhaupt pruefen laesst: dass jeder
-- Effekt eine ganze Zahl an Grundticks ergibt (sonst stimmt Laufzeit
-- oder Abstand nicht), dass die Spec ein Profil hat, und dass die Treppe
-- nicht leer ist. Ob 18 Sekunden wirklich 18 Sekunden sind, kann diese
-- Pruefung nicht wissen — dafuer steht `verify` am Eintrag und die
-- Herleitung in /wc tempo.
--------------------------------------------------

function WeintCodex_ValidateBreakpointData()
    local problems = {}

    for specKey, def in pairs(WeintCodex_Breakpoints or {}) do
        if not (WeintCodex_SpecProfiles and WeintCodex_SpecProfiles[specKey]) then
            problems[#problems + 1] = string.format(
                "%s: kein Spec-Profil in spec_profiles.lua", specKey)
        end
        if def.stat ~= "haste" and def.stat ~= "crit" and def.stat ~= "mastery" then
            problems[#problems + 1] = string.format(
                "%s: unbekannter Wert '%s'", specKey, tostring(def.stat))
        end

        for _, effect in ipairs(def.effects or {}) do
            local base = effect.duration and effect.tick
                         and (effect.duration / effect.tick) or nil
            if not base then
                problems[#problems + 1] = string.format(
                    "%s / %s: Laufzeit oder Tickabstand fehlt",
                    specKey, tostring(effect.name))
            elseif math.abs(base - math.floor(base + 0.5)) > 0.001 then
                problems[#problems + 1] = string.format(
                    "%s / %s: %g s / %g s ergibt %.2f Grundticks — keine ganze Zahl",
                    specKey, tostring(effect.name), effect.duration, effect.tick, base)
            end
        end

        local ladder = WeintCodex_BreakpointLadder(specKey)
        if not ladder or #ladder == 0 then
            problems[#problems + 1] = string.format(
                "%s: keine Stufe erzeugt — Eintrag traegt nichts bei", specKey)
        end
    end

    if #problems > 0 then
        print("|cffD4A24A[WeintCodex]|r |cffff5555Tempo-Schwellen: "
            .. #problems .. " Befund(e):|r")
        for _, msg in ipairs(problems) do
            print("  |cffff9900" .. msg .. "|r")
        end
    end
    return problems
end
