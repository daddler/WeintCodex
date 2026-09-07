-- Kopflose Pruefung der Sockelempfehlung (modules/charakter.lua, PlanItem).
--
-- WARUM ES DIESEN LAUF GIBT: die Sockelbewertung ist die am haeufigsten
-- gemeldete Rechnung dieses Addons, und sie ist sechsmal ausgeliefert worden,
-- ohne zu stimmen (1.3.3.3, 2.0.0.3, 2.0.1.1, 2.3.0.1, 2.5.0.0 und der Fall
-- unten). Sie liest nichts als das Spec-Profil, die Sockelfarben und den
-- Spielraum - im Spiel faellt sie dagegen erst auf, wenn jemand seine Sockel
-- von Hand nachrechnet.
--
-- DER GEMELDETE FALL (Wildheitsdruide, 09/2026). Drei Sockel, nachgerechnet
-- mit Wowhead und einem eigenen Sim; in allen dreien stand die richtige
-- Antwort in seiner EIGENEN Profilliste, und in allen dreien hat das Gewicht
-- sie ueberstimmt:
--
--   Sockel   Empfehlung des Addons        richtig (Wowhead + Sim)
--   rot      Versierter Aragonit          Feingeschliffener Rubellit
--   gelb     Frakturierter Goldberyll     Toedlicher Aragonit
--   blau     Dioptas des Mentors          Glitzernder Kunzit
--
-- Zwei Ursachen, und beide sind hier festgenagelt:
--   * Meisterschaft wog 90 von 100 Beweglichkeit. Ab der HAELFTE des
--     Primaergewichts ist jeder Stein ohne Primaerwert stark als jeder mit
--     (160 Primaer gegen 320 Sekundaer, Hybrid 80 + 160).
--   * Die kuratierte Liste war gar keine Rangfolge: BestCandidate nahm das
--     Maximum ueber alle Kandidaten, die Liste grenzte nur die Menge ein.
--
--   lua5.1 .github/tests/gem_plan_test.lua .

local ROOT = ...

--== Ein Client, so weit ihn diese Rechnung braucht ==========================

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
function UnitName()     return "Testchar" end
function UnitClass()    return "Druide", "DRUID", 11 end
function UnitLevel()    return 90 end
function GetRealmName() return "Ook Ook" end
function GetTime()      return 0 end
C_Timer = { After = function() end }

-- DIE STEINFARBE KOMMT VOM CLIENT, nicht aus data/gems.lua (GemColor liest
-- seit 2.5.0.0 zuerst die Unterklasse). Hier wird sie deshalb genauso
-- geliefert: Gegenstandsklasse 3, Unterklasse = Farbe.
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

WeintCodex = { SavedData = {}, Fonts = {}, Colors = {} }

dofile(ROOT .. "/data/enchants.lua")
dofile(ROOT .. "/data/gems.lua")
dofile(ROOT .. "/data/gem_stats.lua")
dofile(ROOT .. "/data/spec_profiles.lua")
dofile(ROOT .. "/modules/stat_match.lua")
dofile(ROOT .. "/modules/charakter.lua")

local CH = WeintCodex.Charakter

local fails = 0
local function Check(name, ok, detail)
    print(string.format("%-62s %s", name, ok and "ok" or ("ABWEICHUNG  " .. tostring(detail or ""))))
    if not ok then fails = fails + 1 end
end

local function Name(id)
    local gem = id and WeintCodex_Gems[id]
    return gem and gem.name or tostring(id)
end

-- Ein Gegenstand mit EINEM Sockel und einem Sockelbonus, wie ihn jedes
-- Ausruestungsteil aus dem Schlachtzug traegt.
local function PlanOne(specKey, socketColor, bonus, headroom)
    local profile = WeintCodex_SpecProfiles[specKey]
    local ctx = {
        pool     = CH.GemPool(profile, specKey),
        headroom = headroom or {},
        allowJC  = false,
    }
    local plan = CH.PlanItem({ { color = socketColor } },
                             bonus, bonus and "Sockelbonus", profile, ctx)
    return plan.gems[1], plan
end

local AGI_BONUS = { stat = "agility", value = 120 }

--== 1) Der gemeldete Fall ==================================================

do
    local red   = PlanOne("DRUID_FERAL", "rot",  AGI_BONUS)
    local yel   = PlanOne("DRUID_FERAL", "gelb", AGI_BONUS)
    local blue  = PlanOne("DRUID_FERAL", "blau", AGI_BONUS)

    Check("Wildheit / roter Sockel: Feingeschliffener Rubellit",
          red == 76692, Name(red))
    Check("Wildheit / gelber Sockel: ein Aragonit mit Beweglichkeit",
          yel == 76670 or yel == 76658, Name(yel))
    Check("Wildheit / blauer Sockel: Glitzernder Kunzit",
          blue == 76680, Name(blue))
end

--== 2) Warum es schiefging: das Verhaeltnis Sekundaer zu Primaer ===========
-- 160 Primaerwert gegen 320 Sekundaerwert - liegt das Sekundaergewicht ueber
-- der Haelfte, kann KEIN Stein mit Primaerwert je gewinnen. Das ist keine
-- Meinung, sondern die Rechnung selbst, und sie wird hier vorgefuehrt.
do
    local profile = WeintCodex_SpecProfiles.DRUID_FERAL
    local w = profile.statWeights
    local worst, worstName = 0, nil
    for _, stat in ipairs({ "crit", "haste", "mastery" }) do
        if (w[stat] or 0) > worst then worst, worstName = w[stat], stat end
    end
    Check("Wildheit: kein ungecappter Sekundaerwert ueber der halben Beweglichkeit",
          worst <= w.agility * 0.5,
          string.format("%s = %d von %d", tostring(worstName), worst, w.agility))
end

--== 3) Die kuratierte Liste ist eine Rangfolge =============================
-- Der Kopf von data/spec_profiles.lua sagt "REIHENFOLGE IST RANGFOLGE" und
-- "id1 ist, was auf einen leeren Sockel dieser Farbe gehoert". Bis 2.9.2.0
-- war das nicht umgesetzt: entschieden hat immer das Maximum. Geprueft wird
-- deshalb an einem Profil, dessen Gewichte der eigenen Liste widersprechen -
-- die Liste muss trotzdem gewinnen.
do
    local profile = WeintCodex_SpecProfiles.DRUID_FERAL
    local keepGelb = profile.bestGems.gelb
    local keepW    = profile.statWeights.mastery
    profile.bestGems.gelb   = { 76697, 76700 }   -- Krit vorn, Meisterschaft dahinter
    profile.statWeights.mastery = 95             -- ... und das Gewicht sagt das Gegenteil

    local pick = PlanOne("DRUID_FERAL", "gelb", AGI_BONUS)
    Check("Liste schlaegt Gewicht: gelb[1] gewinnt trotz hoeherem Gewicht",
          pick == 76697, Name(pick))

    profile.bestGems.gelb = keepGelb
    profile.statWeights.mastery = keepW
end

--== 4) ... aber nur, solange sie ueberhaupt etwas bringt ===================
-- Dieselbe Zurueckhaltung wie bei den Verzauberungen (PreferredEnchantId):
-- umgereiht wird NUR, wenn der erste Eintrag komplett ins Leere laeuft. Am
-- Trefferkap ist der Glitzernde Kunzit noch 80 Beweglichkeit wert und bleibt
-- deshalb stehen; ein Stein, dessen GANZE Wertung im gecappten Wert liegt,
-- muss dagegen weichen.
do
    local profile = WeintCodex_SpecProfiles.DRUID_FERAL
    local keep = profile.bestGems.blau
    profile.bestGems.blau = { 76636, 76680 }     -- reiner Trefferstein vorn

    local open   = PlanOne("DRUID_FERAL", "blau", AGI_BONUS, { hit = 5000 })
    local capped = PlanOne("DRUID_FERAL", "blau", AGI_BONUS, { hit = 0 })

    Check("Unter dem Kap traegt der Trefferstein die Liste an",
          open == 76636, Name(open))
    Check("Am Kap weicht er - er brachte nur noch Treffer",
          capped == 76680, Name(capped))

    profile.bestGems.blau = keep
end

--== 5) Ohne Sockelbonus gibt es nichts zu matchen ==========================
-- Dann stellt die Liste ihre Frage gar nicht, und es zaehlt wieder der
-- staerkste Stein (IGNORE). Fuer die Wildheit ist das derselbe Rubellit -
-- der Punkt ist, dass der Weg dorthin ein anderer ist.
do
    local pick = PlanOne("DRUID_FERAL", "gelb", nil)
    Check("Gelber Sockel ohne Bonus: der staerkste Stein, Farbe egal",
          pick == 76692, Name(pick))
end

--== 6) Die Begruendung sagt, woher die Empfehlung kommt ====================
do
    local _, plan = PlanOne("DRUID_FERAL", "rot", AGI_BONUS)
    local why = plan.why and plan.why[1] or ""
    Check("Die Zeile nennt die Profilliste als Quelle",
          why:find("Spec%-Profil") ~= nil, why)
end

--== 7) Der Topf haengt nicht an der Reihenfolge von pairs ==================
-- Zwei gleich gute Steine sind nicht derselbe Stein; die Wahl zwischen ihnen
-- darf nicht davon abhaengen, wie Lua seine Tabelle gerade sortiert hat.
do
    local profile = WeintCodex_SpecProfiles.DRUID_FERAL
    local first = table.concat(CH.GemPool(profile, "DRUID_FERAL_probe1"), ",")
    local again = table.concat(CH.GemPool(profile, "DRUID_FERAL_probe2"), ",")
    Check("GemPool liefert eine feste Reihenfolge", first == again, first)
    Check("... und beginnt mit der roten Liste",
          first:find("^76692,") ~= nil, first)
end

--== 8) Handschuhe: Meisterschaft, nicht Waffenkunde ========================
-- Bis 2.9.2.0 stand unter "Haende" NUR die Ueberragende Waffenkunde - ein
-- korrekt verzauberter Handschuh wurde damit als Mangel gemeldet.
do
    local list = WeintCodex_SpecProfiles.DRUID_FERAL.bestEnchants["Hände"]
    Check("Wildheit / Handschuhe: Meisterschaft steht vorn",
          list[1] == 4430, tostring(list[1]))
    Check("... die Waffenkunde bleibt vertretbar",
          list[2] == 4431, tostring(list[2]))
end

--== 9) Der gemeldete Meuchelschurke (09/2026) ==============================
-- "Frakturierter Goldberyll in gelbe Sockel kommt bei Wowhead gar nicht vor.
-- Versierter Aragonit ist die richtige Wahl." Der Sim hatte recht. Die
-- Ursache lag NICHT im Gewicht - seit 2.9.3.0 entscheidet die kuratierte
-- Liste, und in der stand der reine Meisterschaftsstein vorn.
do
    local yel = PlanOne("ROGUE_ASSASSINATION", "gelb", AGI_BONUS)
    Check("Meuchelschurke / gelber Sockel: Versierter Aragonit",
          yel == 76670, Name(yel))

    -- Die Gegenprobe: ohne Sockelbonus gibt es nichts zu halten, dann
    -- gewinnt wieder der reine Beweglichkeitsstein (das ist prismatic).
    local free = PlanOne("ROGUE_ASSASSINATION", "gelb", nil)
    Check("... ohne Sockelbonus dagegen der Feingeschliffene Rubellit",
          free == 76692, Name(free))
end

--== 10) Hybrid oder reiner Stein - JE SPEC, nicht ueber einen Kamm =========
-- Die Rechnung steht im Kopf von data/spec_profiles.lua: in einem gelben
-- Sockel loesen der reine Goldberyll UND der orange Aragonit den Sockelbonus
-- aus, uebrig bleibt 160 Sekundaer gegen 80 Primaer. Wer gewinnt, haengt an
-- der Spec - und es geht nachweislich in beide Richtungen.
--
-- WARUM DAS HIER FESTGENAGELT IST: beim Fehlerbericht oben lag es nahe, alle
-- 26 Profile mit einem reinen Stein in `gelb` in einem Zug umzustellen. Fuer
-- die vier unteren Zeilen waere das falsch gewesen. Diese Tabelle ist die
-- Erinnerung daran, dass die naheliegende Verallgemeinerung geprueft wurde
-- und durchgefallen ist; sie bricht, sobald jemand sie doch noch zieht.
--
-- Belegt an den Raidlogs (Anteil der Spieler, die den Stein tragen).
do
    local EXPECT = {
        -- Spec                    Stein in einem gelben Sockel mit Bonus
        { "ROGUE_ASSASSINATION",   76670, "Versierter Aragonit 89 %" },
        { "ROGUE_SUBTLETY",        76666, "Gewandter Aragonit 97 %" },
        { "HUNTER_SURVIVAL",       76658, "Toedlicher Aragonit 87 %" },
        { "HUNTER_MARKSMANSHIP",   76658, "Toedlicher Aragonit 67 %" },
        { "HUNTER_BEASTMASTERY",   76666, "Gewandter Aragonit 77 %" },
        { "DRUID_FERAL",           76670, "seit 2.9.3.0" },
        -- ... und die Gegenrichtung: hier ist der REINE Stein richtig.
        { "ROGUE_COMBAT",          76699, "reiner Tempostein 90 %" },
        { "WARRIOR_ARMS",          76697, "reiner Kritstein 90 %" },
        { "WARRIOR_FURY",          76697, "reiner Kritstein" },
        { "PALADIN_RETRIBUTION",   76699, "reiner Tempostein 93 %" },
        { "PRIEST_SHADOW",         76699, "reiner Tempostein 83 %" },
    }
    for _, row in ipairs(EXPECT) do
        local specKey, want, why = row[1], row[2], row[3]
        local pick = PlanOne(specKey, "gelb", AGI_BONUS)
        Check("gelb / " .. specKey .. ": " .. Name(want),
              pick == want, Name(pick) .. "  (erwartet: " .. why .. ")")
    end
end

--== 11) Ein Aragonit gehoert auch in die Farbliste, nicht nur nach orange ==
-- In fast allen Faellen stand der richtige Stein bereits unter `orange` im
-- selben Profil - er war nur nirgends die erste Antwort auf einen gelben
-- Sockel, und `orange` beantwortet diese Frage nicht (es gibt keine orangen
-- Sockel). Wer eine Spec umstellt, muss die Farbliste anfassen.
do
    local bad = {}
    for _, specKey in ipairs({ "ROGUE_ASSASSINATION", "ROGUE_SUBTLETY",
                               "HUNTER_BEASTMASTERY", "HUNTER_MARKSMANSHIP",
                               "HUNTER_SURVIVAL", "DRUID_FERAL" }) do
        local gelb = WeintCodex_SpecProfiles[specKey].bestGems.gelb
        local st   = gelb and WeintCodex_GemStats[gelb[1]]
        if not (st and (st.agility or 0) > 0) then
            bad[#bad + 1] = specKey .. "=" .. Name(gelb and gelb[1])
        end
    end
    Check("gelb[1] dieser Specs traegt Beweglichkeit",
          #bad == 0, table.concat(bad, " "))
end

--== 12) Keine Regression bei den anderen Specs =============================
-- Jede Spec, jede Sockelfarbe, mit und ohne Bonus: es muss ueberhaupt eine
-- Empfehlung herauskommen, und sie muss den Sockel bedienen koennen.
do
    local bad = {}
    for specKey, profile in pairs(WeintCodex_SpecProfiles) do
        if profile.bestGems and profile.statWeights then
            for _, color in ipairs({ "rot", "gelb", "blau" }) do
                for _, bonus in ipairs({ AGI_BONUS, false }) do
                    local pick = PlanOne(specKey, color, bonus or nil)
                    if not pick then
                        bad[#bad + 1] = specKey .. "/" .. color
                    end
                end
            end
        end
    end
    Check("Alle Specs liefern fuer jede Sockelfarbe eine Empfehlung",
          #bad == 0, table.concat(bad, " "))
end

--== 13) DER PLAN IST EIN FIXPUNKT ==========================================
-- DER GEMELDETE FALL (09/2026): "Wenn man das, was WeintCodex vorschlaegt,
-- durchzieht, ist beim naechsten Scan wieder ein anderer Vorschlag."
--
-- Die Ursache war eine Rueckkopplung und keine Ungenauigkeit: der Spielraum
-- kam aus der Kampfwertung des Clients - und die ENTHAELT die angelegten
-- Steine. Geplant wurden die Sockel aber, als waeren sie leer. Damit dreht
-- sich ein Kreis, und jede Runde davon kostet Steine:
--
--   leere Sockel   5,0 % / Kap 7,5 %  -> Spielraum 850 -> Treffersteine
--   umgesetzt      7,8 % / Kap 7,5 %  -> Spielraum   0 -> andere Steine
--   umgesetzt      5,0 % / Kap 7,5 %  -> Spielraum 850 -> Treffersteine
--
-- Geprueft wird deshalb VERHALTEN und nicht eine Punktzahl: planen, den Plan
-- wie das Spiel anwenden (Steine einsetzen, Kampfwertung nachziehen), neu
-- planen - und dabei muss dasselbe herauskommen. Dieselbe Bauform wie die
-- Fixpunkt-Probe des Umschmiede-Planers seit 2.7.5.0.
do
    local specKey = "DRUID_FERAL"
    local profile = WeintCodex_SpecProfiles[specKey]
    local PER_PCT = 340          -- Wertung je Prozentpunkt auf Stufe 90
    local CAP_PCT = 7.5          -- Trefferkap
    local BASE_PCT = 5.0         -- ohne Steine: 2,5 % darunter
    local SOCKETS  = 4
    local BONUS    = { stat = "agility", value = 120 }

    -- Damit der Spielraum die Empfehlung ueberhaupt traegt, muss ein
    -- Trefferstein die Liste anfuehren (dieselbe Vorbereitung wie in 4).
    local keep = profile.bestGems.blau
    profile.bestGems.blau = { 76636, 76680 }   -- 320 Treffer, dann 80 Bewegl. + 160 Treffer

    -- Der Client, so weit diese Rechnung ihn braucht. Entscheidend ist die
    -- eine Zeile: die Kampfwertung enthaelt, was in den Sockeln steckt.
    local function CapStatesFor(gemHit)
        local current = BASE_PCT + gemHit / PER_PCT
        local over    = current - CAP_PCT
        return { {
            stat        = "hit", typ = "melee", capPct = CAP_PCT,
            current     = current, overPct = over,
            overRating  = (over > 0) and over * PER_PCT or 0,
            underRating = (over < 0) and -over * PER_PCT or 0,
            perPct      = PER_PCT, label = "Trefferwertung (Nahkampf)",
        } }
    end

    -- Wie das Spiel: die vier Sockel tragen, was zuletzt geplant wurde, und
    -- der Sockelbonus liegt an, weil alle Steine blau sind.
    local function Scanned(equipped)
        local out = {}
        for _, gemId in ipairs(equipped) do
            out[#out + 1] = { known = true, bonus = BONUS, bonusActive = true,
                              sockets = { { color = "blau", gemId = gemId or nil } } }
        end
        return out
    end

    local function PlanRound(equipped)
        local socketRating = CH.EquippedSocketRating(Scanned(equipped))
        local headroom = CH.PlanningHeadroom(CapStatesFor(socketRating.hit or 0),
                                             {}, nil, socketRating)
        local ctx = { pool = CH.GemPool(profile, specKey),
                      headroom = headroom, allowJC = false }
        local room1 = headroom.hit
        local out = {}
        for i = 1, SOCKETS do
            -- Der Spielraum wird ueber die Sockel VERBRAUCHT - deshalb
            -- derselbe ctx fuer alle vier, so wie ScanCharacter es tut.
            local plan = CH.PlanItem({ { color = "blau" } }, BONUS, "Sockelbonus",
                                     profile, ctx)
            out[i] = plan.gems[1]
        end
        return out, room1, socketRating
    end

    local function Show(list)
        local t = {}
        for i = 1, SOCKETS do t[i] = Name(list[i]) end
        return table.concat(t, ", ")
    end

    -- Runde 1: alle vier Sockel leer.
    local first, room1 = PlanRound({ false, false, false, false })
    Check("Unter dem Trefferkap traegt der Spielraum die Empfehlung",
          (room1 or 0) > 800 and first[1] == 76636,
          string.format("Spielraum %.0f, %s", room1 or 0, Show(first)))

    -- Der Spieler zieht den Vorschlag durch.
    local second, room2, rating = PlanRound(first)
    Check("Die angelegten Steine werden im Spielraum mitgezaehlt",
          (rating.hit or 0) > 300, tostring(rating.hit))
    Check("Nach dem Umsetzen steht derselbe Spielraum da",
          math.abs((room1 or 0) - (room2 or 0)) < 1,
          string.format("%.0f -> %.0f", room1 or 0, room2 or 0))
    local same = true
    for i = 1, SOCKETS do if first[i] ~= second[i] then same = false end end
    Check("Nach dem Umsetzen steht derselbe Vorschlag da",
          same, Show(first) .. "  ->  " .. Show(second))

    -- Und er bleibt stehen: eine dritte Runde aendert nichts mehr.
    local third = PlanRound(second)
    local stable = true
    for i = 1, SOCKETS do if second[i] ~= third[i] then stable = false end end
    Check("... und auch in der Runde danach", stable,
          Show(second) .. "  ->  " .. Show(third))

    -- DIE GEGENPROBE. Ohne den Abzug der angelegten Steine - also so, wie es
    -- bis 2.9.3.1 gerechnet wurde - verschwindet der Spielraum, und die
    -- naechste Runde raet zu etwas anderem. Faellt diese Zeile weg, misst
    -- der Lauf darueber nichts mehr.
    local function OldRoom(equipped)
        local socketRating = CH.EquippedSocketRating(Scanned(equipped))
        local cs = CapStatesFor(socketRating.hit or 0)[1]
        return math.max(0, cs.underRating or 0)
    end
    local leer, gesetzt = OldRoom({ false, false, false, false }), OldRoom(first)
    Check("Gegenprobe: die alte Rechnung liess den Spielraum verschwinden",
          leer > 800 and gesetzt < 1,
          string.format("leer %.0f -> gesetzt %.0f", leer, gesetzt))

    profile.bestGems.blau = keep
end

--== 14) DER WUNSCHWERT MUSS GENUG VORSPRUNG HABEN =========================
-- Er rueckt einen Wert an die erste Stelle der Gewichtung — bedienbar im
-- Umschmieder-Fenster und auf "Priorisierung", wirksam ueberall (es ist
-- dieselbe Gewichtung, die auch Steine und Verzauberungen lesen).
--
-- EIN PUNKT VORSPRUNG SIEHT NACH EINER ENTSCHEIDUNG AUS UND BEWIRKT NICHTS.
-- Der Umschmiede-Planer nimmt eine Umschmiedung nur an, wenn sie ueber
-- seiner Lohnschwelle liegt (WORTH_RATING = 10, festgenagelt in
-- .github/tests/reforge_engine_test.lua). Genau diesen Fehler hatte die
-- eigene Priorisierung schon einmal: sie stand da und tat nichts.
do
    local WORTH = 10    -- RE.WORTH_RATING, siehe reforge_engine_test.lua
    local base = { agility = 100, crit = 90, haste = 70, mastery = 55,
                   hit = 100, expertise = 100 }
    local fav = CH.FavorWeights(base, "mastery")

    Check("Wunschwert steht vorn",
          fav ~= nil and fav.mastery == 100 and fav.mastery >= (fav.crit or 0) * 1.2,
          fav and (tostring(fav.mastery) .. " gegen " .. tostring(fav.crit)) or "nil")

    -- Die Rangfolge darunter bleibt: was halb so viel wog, wiegt danach
    -- immer noch etwa halb so viel. Sonst waere der Wunschwert kein
    -- Vorrang, sondern eine neue Gewichtung.
    Check("... die Rangfolge darunter bleibt",
          fav and fav.crit > fav.haste and fav.haste > 0,
          fav and string.format("Krit %d, Tempo %d", fav.crit, fav.haste) or "nil")

    -- Primaerwerte werden nicht angefasst: sie lassen sich nicht
    -- umschmieden, und in einem Sockel entscheiden sie die Steinwahl mit.
    Check("Primaerwerte bleiben unangetastet",
          fav and fav.agility == 100, fav and tostring(fav.agility) or "nil")

    -- Ein Wert, den die Spec mit 0 fuehrt, wird NICHT nach vorn gerueckt:
    -- das waere eine Aussage ueber das Spiel, die dieses Addon nicht trifft.
    Check("Ein ungewichteter Wert wird abgelehnt",
          CH.FavorWeights(base, "parry") == nil, "nicht abgelehnt")

    -- DIE GEGENPROBE AN DER LOHNSCHWELLE, im unguenstigsten Fall: ein Teil,
    -- das nur 200 Wertung im staerksten Wert traegt. Bringt die Umschmiedung
    -- weniger als WORTH mal Spitzengewicht, nimmt Stufe 3 des Planers sie
    -- wieder zurueck — und der Wunschwert waere unsichtbar.
    local gain = 200 * ((fav and fav.mastery or 0) - (fav and fav.crit or 0))
    local bar  = WORTH * (fav and fav.mastery or 0)
    Check("... und liegt ueber der Lohnschwelle",
          gain > bar, string.format("%d gegen %d", gain, bar))

    -- Und die Gegenprobe zur Gegenprobe: mit einem Punkt Vorsprung waere es
    -- genau nicht so. Faellt diese Zeile weg, misst die Zeile darueber
    -- nichts mehr.
    local thin = { crit = 90, mastery = 89, haste = 70 }
    Check("Gegenprobe: ein Punkt Vorsprung reicht nicht",
          200 * (thin.mastery - thin.crit) <= WORTH * thin.mastery,
          "ein Punkt haette gereicht")
end

--== 8) DAS SCHLANGENAUGEN-KONTINGENT ========================================
--
-- GEMELDETER FALL (Magier, 08/2026): "ich habe zwei berufsspezifische Steine
-- angelegt aber mir wird empfohlen noch zwei anzulegen, geht aber nicht sind
-- nur zwei moeglich". Auf dem Bildschirm standen DREI Schlangenaugen im Plan
-- (Kopf ein roter Sockel, Schultern zwei) - eines mehr, als MoP zulaesst.
--
-- Ursache: `ctx.allowJC` stand fuer den ganzen GEGENSTAND fest und wurde
-- erst danach nachgezogen. Ein Teil mit zwei Sockeln konnte damit zwei
-- Schlangenaugen bekommen, auch wenn nur noch eines uebrig war; `ctx.jcLeft`
-- lief ins Minus, ohne dass es irgendwo auffiel.
--
-- Geprueft wird deshalb VERHALTEN und keine Punktzahl: mehrere Gegenstaende
-- nacheinander mit demselben Kontext planen und die Schlangenaugen im
-- Ergebnis zaehlen. Mit der alten Rechnung faellt dieser Block durch.
do
    local specKey = "MAGE_ARCANE"
    local profile = WeintCodex_SpecProfiles[specKey]

    -- Ein Profil, das ueberhaupt ein Schlangenauge fuehrt - sonst prueft
    -- dieser Block nichts. Gesucht wird eines, nicht angenommen.
    local function ProfileWithJc()
        for key, prof in pairs(WeintCodex_SpecProfiles) do
            for _, list in pairs(prof.bestGems or {}) do
                if type(list) == "table" then
                    for _, id in ipairs(list) do
                        local gem = WeintCodex_Gems[id]
                        if gem and gem.jcOnly then return key, prof end
                    end
                end
            end
        end
    end

    local jcKey, jcProfile = ProfileWithJc()
    Check("Es gibt ein Spec-Profil mit Schlangenauge (sonst prueft das hier nichts)",
          jcProfile ~= nil, "keines gefunden")

    if jcProfile then
        specKey, profile = jcKey, jcProfile

        local LIMIT = 2
        local ctx = {
            pool     = CH.GemPool(profile, specKey),
            headroom = {},
            allowJC  = true,
            jcLimit  = LIMIT,
            jcLeft   = LIMIT,
            jcUsed   = 0,
        }

        -- Die Ausruestung des gemeldeten Falls: ein Teil mit einem Sockel,
        -- danach eines mit zwei. Genau in dieser Reihenfolge lief das
        -- Kontingent ueber.
        local items = {
            { { color = "rot" } },
            { { color = "rot" }, { color = "rot" } },
            { { color = "rot" }, { color = "rot" }, { color = "rot" } },
        }

        local total = 0
        for _, sockets in ipairs(items) do
            local plan = CH.PlanItem(sockets, nil, nil, profile, ctx)
            for _, id in ipairs(plan.gems or {}) do
                local gem = id and WeintCodex_Gems[id]
                if gem and gem.jcOnly then total = total + 1 end
            end
        end

        Check("Nie mehr Schlangenaugen im Plan, als der Beruf erlaubt",
              total <= LIMIT, string.format("%d von %d", total, LIMIT))

        -- Und das Kontingent selbst bleibt eine Zahl, die man lesen kann.
        Check("Das Kontingent laeuft nicht ins Minus",
              (ctx.jcLeft or 0) >= 0, tostring(ctx.jcLeft))

        Check("Verbraucht und Rest ergeben zusammen die Grenze",
              (ctx.jcUsed or 0) + (ctx.jcLeft or 0) == LIMIT,
              string.format("%d + %d", ctx.jcUsed or 0, ctx.jcLeft or 0))

        -- Ohne den Beruf taucht ueberhaupt keines auf - das war schon vorher
        -- so und darf beim Umbau nicht verloren gehen.
        local plain = {
            pool = CH.GemPool(profile, specKey), headroom = {},
            allowJC = false, jcLimit = 0, jcLeft = 0, jcUsed = 0,
        }
        local none = 0
        for _, sockets in ipairs(items) do
            local plan = CH.PlanItem(sockets, nil, nil, profile, plain)
            for _, id in ipairs(plan.gems or {}) do
                local gem = id and WeintCodex_Gems[id]
                if gem and gem.jcOnly then none = none + 1 end
            end
        end
        Check("Ohne Juwelenschleifen wird keines vorgeschlagen",
              none == 0, tostring(none))

        -- UND DIE ANDERE HAELFTE DESSELBEN FEHLERS.
        --
        -- In allen 64 Profileintraegen steht das Schlangenauge an ZWEITER
        -- Stelle seiner Farbliste. Seit 2.9.3.0 ist die Liste eine
        -- Rangfolge, also gewann immer der erste Eintrag - und damit bekam
        -- kein Juwelier mehr ein einziges Schlangenauge vorgeschlagen.
        -- Lautlos: eine Empfehlung, die fehlt, sieht aus wie eine, die es
        -- nicht gibt. Ohne diese Zeile misst der Block darueber nichts
        -- ("nie mehr als zwei" ist mit null trivial erfuellt).
        local fresh = {
            pool = CH.GemPool(profile, specKey), headroom = {},
            allowJC = true, jcLimit = LIMIT, jcLeft = LIMIT, jcUsed = 0,
        }
        local used = 0
        for _, sockets in ipairs(items) do
            local plan = CH.PlanItem(sockets, nil, nil, profile, fresh)
            for _, id in ipairs(plan.gems or {}) do
                local gem = id and WeintCodex_Gems[id]
                if gem and gem.jcOnly then used = used + 1 end
            end
        end
        Check("Mit Juwelenschleifen wird das Kontingent auch ausgeschoepft",
              used == LIMIT, string.format("%d von %d", used, LIMIT))

        -- Und die Begruendung nennt die Zahl. "Begrenzte Zahl" nennt keinen
        -- naechsten Schritt; "1 von 2" beantwortet von selbst, warum an der
        -- naechsten Zeile keines mehr steht.
        local ctxN = {
            pool = CH.GemPool(profile, specKey), headroom = {},
            allowJC = true, jcLimit = LIMIT, jcLeft = LIMIT, jcUsed = 0,
        }
        local first = CH.PlanItem({ { color = "rot" } }, nil, nil, profile, ctxN)
        local why = (first.why or {})[1] or ""
        Check("Die Begruendung nennt die laufende Nummer",
              why:find("1 von " .. LIMIT, 1, true) ~= nil, why)
    end
end

print("")
if fails == 0 then
    print("Alle Pruefungen bestanden.")
else
    print(fails .. " Abweichung(en).")
    os.exit(1)
end
