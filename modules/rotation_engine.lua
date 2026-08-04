--------------------------------------------------
-- WeintCodex :: Rotations-Engine
--
-- Die Auswertungshälfte des Rotationshelfers: liest den Spielzustand,
-- prüft die Regeln aus data/rotations.lua dagegen und liefert eine
-- fertig sortierte Liste zurück. modules/rotationtrainer.lua zeichnet
-- diese Liste nur noch - hier steckt jede Entscheidung.
--
-- Bewusst eine eigenständige Engine im Addon, nicht über die Companion
-- berechnet: die Companion hat keine Live-Combatlog-Auswertung und die
-- Inbox wird ohnehin nur bei Login/Reload gelesen (siehe
-- modules/companion.lua). Für eine Anzeige, die sich beim Zaubern
-- bewegt, gibt es keinen anderen Weg.
--
--------------------------------------------------
-- WAS DIE ENGINE LIEFERT
--------------------------------------------------
--
--   local plan = WeintCodex.RotationEngine.Evaluate(specKey)
--
--   plan.entries  = alle Regeln, bereits in Anzeigereihenfolge
--   plan.ranked   = nur die gerade wirkbaren, in Prioritätsreihenfolge
--   plan.extras   = Cooldowns / Fähigkeiten ohne GCD
--   plan.snapshot = der Spielzustand, gegen den geprüft wurde
--
-- Jeder Eintrag trägt:
--   rule, index, state, bucket, remaining, charges, reason
--
-- state ist einer von:
--   "ready"     Bedingung erfüllt, Zauber verfügbar  -> kann gedrückt werden
--   "resource"  Bedingung erfüllt, Ressource fehlt
--   "waiting"   Bedingung erfüllt, Zauber auf Abklingzeit
--   "blocked"   Bedingung nicht erfüllt
--   "unknown"   Zauber nicht erlernt / dem Client unbekannt
--
-- Genau diese Reihenfolge ist auch die Sortierung. Deshalb rutscht eine
-- Fähigkeit, die man gerade gedrückt hat, von selbst nach unten: sie
-- ist im selben Moment auf Abklingzeit (mindestens für den GCD) und
-- landet damit in einem tieferen Topf. Die nächste steigt auf.
--
--------------------------------------------------
-- BEWERTUNG
--------------------------------------------------
--
-- Die Sitzungsauswertung hängt ebenfalls hier (Session.*), weil sie
-- dieselben Momentaufnahmen braucht wie die Anzeige. Sie bewertet
-- rangbasiert statt richtig/falsch:
--
--   Rang 1 gedrückt        -> 1.00
--   Rang 2                 -> 0.65
--   Rang 3                 -> 0.35
--   Rang 4+                -> 0.15
--   nicht wirkbar          -> 0.00
--
-- Nicht bewertet wird, was nicht zur Rotation gehört: Tränke, Zauber
-- fremder Fähigkeiten, Extras (Cooldowns, Fähigkeiten ohne GCD). Und
-- wenn gerade nichts wirkbar war, zählt der Zauber gar nicht - in einer
-- Ressourcenpause ist jede Taste gleich gut.
--
-- Die Gesamtnote ist gewichtet: Priorität 60 %, Auslastung des GCD
-- 20 %, Laufzeit der überwachten Dots/Buffs 20 %. Hat eine Spec nichts
-- zu überwachen, gehen die 20 % an die Priorität.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.RotationEngine = {}

local RE = WeintCodex.RotationEngine

--------------------------------------------------
-- Ressourcen
--
-- SPELL_POWER_* existiert in MoP Classic als globale Konstante; die
-- Indizes daneben sind der Rückfallweg, falls eine davon fehlt.
--------------------------------------------------

local POWER_TYPES = {
    MANA           = { global = "SPELL_POWER_MANA",           index = 0,  label = "Mana" },
    RAGE           = { global = "SPELL_POWER_RAGE",           index = 1,  label = "Wut" },
    FOCUS          = { global = "SPELL_POWER_FOCUS",          index = 2,  label = "Fokus" },
    ENERGY         = { global = "SPELL_POWER_ENERGY",         index = 3,  label = "Energie" },
    RUNIC_POWER    = { global = "SPELL_POWER_RUNIC_POWER",    index = 6,  label = "Runenmacht" },
    SOUL_SHARDS    = { global = "SPELL_POWER_SOUL_SHARDS",    index = 7,  label = "Seelensplitter" },
    HOLY_POWER     = { global = "SPELL_POWER_HOLY_POWER",     index = 9,  label = "Heilige Kraft" },
    CHI            = { global = "SPELL_POWER_CHI",            index = 12, label = "Chi" },
    SHADOW_ORBS    = { global = "SPELL_POWER_SHADOW_ORBS",    index = 13, label = "Schattenkugeln" },
    BURNING_EMBERS = { global = "SPELL_POWER_BURNING_EMBERS", index = 14, label = "Glut" },
    DEMONIC_FURY   = { global = "SPELL_POWER_DEMONIC_FURY",   index = 15, label = "Dämonische Wut" },
}

RE.PowerTypes = POWER_TYPES

local function PowerIndex(powerType)
    local def = POWER_TYPES[powerType or ""]
    if not def then return nil end
    local global = _G[def.global]
    if type(global) == "number" then return global end
    return def.index
end

local function PowerLabel(powerType)
    local def = POWER_TYPES[powerType or ""]
    return def and def.label or "Ressource"
end

--------------------------------------------------
-- Runen (Todesritter)
--
-- Rune 4 ist die Todesrune und springt für jede andere Sorte ein -
-- deshalb wird sie erst am Ende gegen die offenen Fehlbeträge gerechnet.
--------------------------------------------------

local RUNE_BLOOD, RUNE_UNHOLY, RUNE_FROST, RUNE_DEATH = 1, 2, 3, 4

local function ReadRunes(now)
    if not GetRuneCooldown or not GetRuneType then return nil end

    local counts = { blood = 0, unholy = 0, frost = 0, death = 0 }

    for slot = 1, 6 do
        local start, duration, ready = GetRuneCooldown(slot)
        local isReady = ready
        if isReady == nil then
            isReady = (not start) or (not duration) or duration == 0
                or (start + duration - now) <= 0
        end
        if isReady then
            local runeType = GetRuneType(slot)
            if runeType == RUNE_BLOOD      then counts.blood  = counts.blood  + 1
            elseif runeType == RUNE_UNHOLY then counts.unholy = counts.unholy + 1
            elseif runeType == RUNE_FROST  then counts.frost  = counts.frost  + 1
            elseif runeType == RUNE_DEATH  then counts.death  = counts.death  + 1 end
        end
    end

    return counts
end

local function RunesSatisfied(need, counts)
    if not counts then return true end   -- keine Runen-API: nie blockieren

    local deficit = 0
    for _, sort in ipairs({ "blood", "unholy", "frost" }) do
        local required = need[sort]
        if required and required > 0 then
            local have = counts[sort] or 0
            if have < required then deficit = deficit + (required - have) end
        end
    end

    return deficit <= (counts.death or 0), deficit
end

local RUNE_LABELS = { blood = "Blutrune", unholy = "Unheilige Rune", frost = "Frostrune" }

--------------------------------------------------
-- Auren
--
-- Gelesen wird der Tupel von UnitAura in der Reihenfolge des
-- MoP-Clients (Interface 50504): name, rank, icon, count, dispelType,
-- duration, expirationTime. Verglichen wird über den Namen, nicht über
-- die Position der Spell-ID - der Name ist zwischen Client-Versionen
-- stabil, die Tupelbreite nicht. Gleiche Doktrin wie data/bis.lua und
-- gems.lua: zur Laufzeit über die Spiel-API auflösen.
--------------------------------------------------

local NO_EXPIRY = 999   -- Aura ohne Ablaufzeit (dauerhaft) - nie "läuft aus"

local function ScanAuras(unit, filter, into, now)
    for key in pairs(into) do into[key] = nil end
    if not UnitExists(unit) then return into end

    for i = 1, 40 do
        local name, _, _, count, _, _, expirationTime = UnitAura(unit, i, filter)
        if not name then break end

        local remaining = NO_EXPIRY
        if type(expirationTime) == "number" and expirationTime > 0 then
            remaining = expirationTime - now
            if remaining < 0 then remaining = 0 end
        end

        into[name] = { count = (type(count) == "number" and count > 0) and count or 1,
                       remaining = remaining }
    end

    return into
end

-- Name einer Spell-ID mit kleinem Zwischenspeicher: die Auswertung
-- läuft zehnmal pro Sekunde über jede Regel, GetSpellInfo muss dabei
-- nicht jedes Mal neu gefragt werden.
local nameCache = {}

local function SpellName(spellId)
    local cached = nameCache[spellId]
    if cached ~= nil then
        if cached == false then return nil end
        return cached
    end
    local name = GetSpellInfo(spellId)
    nameCache[spellId] = name or false
    return name
end

RE.SpellName = SpellName

local function AuraInfo(cache, spellId)
    local name = SpellName(spellId)
    if not name then return nil end
    return cache[name], name
end

--------------------------------------------------
-- Globale Abklingzeit
--
-- Zauber-ID 61304 ist der GCD; GetSpellCooldown darauf ist der
-- verlässlichste Weg, den laufenden GCD zu erfragen. Falls der Client
-- dazu nichts liefert, wird er aus dem letzten beobachteten Zauber
-- geschätzt (Zauberhast, mindestens eine Sekunde).
--------------------------------------------------

local GCD_SPELL_ID = 61304

local lastCastAt, lastCastGcd = 0, 0
local recentCasts = {}

local function EstimatedGcd()
    local haste = UnitSpellHaste and UnitSpellHaste("player") or 0
    local gcd = 1.5 / (1 + (haste or 0) / 100)
    if gcd < 1.0 then gcd = 1.0 end
    return gcd
end

local function GcdRemaining(now)
    local start, duration = GetSpellCooldown(GCD_SPELL_ID)
    if start and duration and duration > 0 then
        local remaining = start + duration - now
        if remaining > 0 then return remaining, duration end
    end

    if lastCastAt > 0 then
        local remaining = lastCastAt + lastCastGcd - now
        if remaining > 0 then return remaining, lastCastGcd end
    end

    return 0, 0
end

-- Wird vom Trainer bei jedem eigenen Zauber gerufen. Zwei Aufgaben:
-- den GCD-Rückfallweg füttern und die eben gedrückte Fähigkeit für die
-- Dauer des GCD als "gerade gewirkt" merken. Letzteres ist der Grund,
-- warum die Zeile sofort nach unten wandert und nicht erst, wenn der
-- Server die Abklingzeit zurückmeldet.
function RE.NoteCast(spellId)
    local now = GetTime()
    lastCastAt  = now
    lastCastGcd = EstimatedGcd()
    if spellId then recentCasts[spellId] = now end
end

function RE.ResetCastMemory()
    lastCastAt, lastCastGcd = 0, 0
    for key in pairs(recentCasts) do recentCasts[key] = nil end
end

--------------------------------------------------
-- Verfügbarkeit eines Zaubers
--------------------------------------------------

local function IsKnown(spellId)
    if IsPlayerSpell and IsPlayerSpell(spellId) then return true end
    if IsSpellKnown  and IsSpellKnown(spellId)  then return true end
    if not IsPlayerSpell and not IsSpellKnown   then return true end
    return false
end

-- Manche Fähigkeiten tragen je Spec eine eigene Spell-ID (Seelen-
-- schnitter, Verstümmeln). Eine Regel darf deshalb Ausweich-IDs
-- mitbringen; genommen wird die erste, die der Charakter kennt. Ohne
-- das wäre die Zeile für die halbe Klasse dauerhaft tot, und man würde
-- es erst im Spiel merken.
local function ResolveSpell(rule)
    if not rule.alt then return rule.spell end
    if IsKnown(rule.spell) then return rule.spell end
    for _, alternative in ipairs(rule.alt) do
        if IsKnown(alternative) then return alternative end
    end
    return rule.spell
end

local function RuleUsesSpell(rule, spellId)
    if rule.spell == spellId then return true end
    for _, alternative in ipairs(rule.alt or {}) do
        if alternative == spellId then return true end
    end
    return false
end

-- Liefert state, remaining, charges. "ready" heißt: beim Ablauf des
-- laufenden GCD drückbar - alles andere wäre für eine Anzeige, die auf
-- die nächste Taste hinweist, eine Sekunde zu spät.
local function SpellAvailability(spellId, snap)
    if not SpellName(spellId) then return "unknown", 0, nil end
    if not IsKnown(spellId)   then return "unknown", 0, nil end

    local charges
    if GetSpellCharges then
        local current, max = GetSpellCharges(spellId)
        if current and max and max > 1 then
            charges = current
            if current >= 1 then return "ready", 0, charges end
        end
    end

    local remaining = 0
    local start, duration = GetSpellCooldown(spellId)
    if start and duration and duration > 0 then
        remaining = start + duration - snap.now
        if remaining < 0 then remaining = 0 end
    end

    -- Alles, was innerhalb des laufenden GCD zurückkommt, gilt als
    -- bereit; sonst wäre die Liste nach jedem Tastendruck 1,5 Sekunden
    -- lang leer.
    local tolerance = snap.gcdRemaining
    if tolerance < 0.15 then tolerance = 0.15 end

    -- Eben selbst gedrückt: für die Dauer des GCD nach unten.
    local castAt = recentCasts[spellId]
    if castAt then
        local lock = castAt + snap.gcdDuration - snap.now
        if lock > 0.05 then
            if lock > remaining then remaining = lock end
            return "waiting", remaining, charges
        end
        recentCasts[spellId] = nil
    end

    if remaining <= tolerance then return "ready", 0, charges end
    return "waiting", remaining, charges
end

--------------------------------------------------
-- Momentaufnahme des Spielzustands
--
-- Einmal pro Auswertung gebaut statt einmal pro Bedingung: eine Spec
-- hat bis zu sieben Regeln, und jede Aurenprüfung liest sonst erneut
-- 40 Aurenplätze.
--------------------------------------------------

local snapshot = {
    playerAuras = {},
    targetAuras = {},
    power = {},
}

local function BuildSnapshot()
    local now = GetTime()
    local snap = snapshot

    snap.now = now
    snap.gcdRemaining, snap.gcdDuration = GcdRemaining(now)
    if snap.gcdDuration <= 0 then snap.gcdDuration = EstimatedGcd() end

    ScanAuras("player", "HELPFUL",        snap.playerAuras, now)
    ScanAuras("target", "HARMFUL|PLAYER", snap.targetAuras, now)

    snap.hasTarget = UnitExists("target") and not UnitIsDead("target")

    snap.targetHealth = nil
    if snap.hasTarget then
        local maxHealth = UnitHealthMax("target")
        if maxHealth and maxHealth > 0 then
            snap.targetHealth = UnitHealth("target") / maxHealth * 100
        end
    end

    for key in pairs(snap.power) do snap.power[key] = nil end
    snap.combo = GetComboPoints and GetComboPoints("player", "target") or 0
    snap.runes = ReadRunes(now)

    snap.casting = (UnitCastingInfo and UnitCastingInfo("player"))
        or (UnitChannelInfo and UnitChannelInfo("player")) or nil

    return snap
end

local function Power(snap, powerType)
    local key = powerType or "DEFAULT"
    local cached = snap.power[key]
    if cached then return cached end

    local index = PowerIndex(powerType)
    local value = index and UnitPower("player", index) or UnitPower("player")
    snap.power[key] = value or 0
    return snap.power[key]
end

--------------------------------------------------
-- Bedingungen
--
-- Jede Prüfung liefert erfüllt + einen kurzen deutschen Text. Der Text
-- ist kein Beiwerk: er steht in der Zeile und beantwortet die einzige
-- Frage, die man vor der Liste hat - warum steht das gerade nicht oben.
--------------------------------------------------

local function Seconds(value)
    if value >= NO_EXPIRY then return "dauerhaft" end
    if value >= 10 then return string.format("%.0fs", value) end
    return string.format("%.1fs", value)
end

local function NormalizeAura(value)
    if type(value) == "number" then return { id = value } end
    return value or {}
end

local Checks = {}

Checks.hpBelow = function(value, snap)
    if not snap.targetHealth then return false, "kein Ziel" end
    if snap.targetHealth <= value then
        return true, string.format("Ziel bei %.0f %%", snap.targetHealth)
    end
    return false, string.format("Ziel über %d %%", value)
end

Checks.hpAbove = function(value, snap)
    if not snap.targetHealth then return false, "kein Ziel" end
    if snap.targetHealth > value then
        return true, string.format("Ziel bei %.0f %%", snap.targetHealth)
    end
    return false, string.format("Ziel unter %d %%", value)
end

local function CheckAuraPresent(spec, snap, cache)
    local want = NormalizeAura(spec)
    local aura, name = AuraInfo(cache, want.id)
    name = name or ("Aura " .. tostring(want.id))

    if not aura then return false, name .. " fehlt" end

    if want.stacks and aura.count < want.stacks then
        return false, string.format("%s %d/%d", name, aura.count, want.stacks)
    end
    if want.remainingBelow and aura.remaining >= want.remainingBelow then
        return false, string.format("%s %s", name, Seconds(aura.remaining))
    end
    if want.remainingAbove and aura.remaining <= want.remainingAbove then
        return false, string.format("%s nur noch %s", name, Seconds(aura.remaining))
    end

    if want.stacks then
        return true, string.format("%s %d", name, aura.count)
    end
    return true, string.format("%s (%s)", name, Seconds(aura.remaining))
end

local function CheckAuraMissing(spec, snap, cache, verb)
    local want = NormalizeAura(spec)
    local aura, name = AuraInfo(cache, want.id)
    name = name or ("Aura " .. tostring(want.id))

    if not aura then return true, name .. " fehlt" end

    if want.remainingBelow and aura.remaining < want.remainingBelow then
        return true, string.format("%s läuft aus (%s)", name, Seconds(aura.remaining))
    end

    return false, string.format("%s %s %s", name, verb, Seconds(aura.remaining))
end

Checks.buff     = function(value, snap) return CheckAuraPresent(value, snap, snap.playerAuras) end
Checks.debuff   = function(value, snap) return CheckAuraPresent(value, snap, snap.targetAuras) end
Checks.noBuff   = function(value, snap) return CheckAuraMissing(value, snap, snap.playerAuras, "läuft noch") end
Checks.noDebuff = function(value, snap) return CheckAuraMissing(value, snap, snap.targetAuras, "steht noch") end

Checks.power = function(value, snap, rule, spec)
    local powerType = value.type or (spec and spec.resource)
    local label = PowerLabel(powerType)
    local current = Power(snap, powerType)

    if value.atLeast and current < value.atLeast then
        return false, string.format("%s %d/%d", label, current, value.atLeast)
    end
    if value.atMost and current > value.atMost then
        return false, string.format("%s %d, erst ab %d", label, current, value.atMost)
    end

    return true, string.format("%s %d", label, current)
end

Checks.combo = function(value, snap)
    local current = snap.combo or 0
    if value.atLeast and current < value.atLeast then
        return false, string.format("%d/%d Kombopunkte", current, value.atLeast)
    end
    if value.atMost and current > value.atMost then
        return false, string.format("%d Kombopunkte, zu viele", current)
    end
    return true, string.format("%d Kombopunkte", current)
end

Checks.runes = function(value, snap)
    local ok = RunesSatisfied(value, snap.runes)
    if ok then return true, "Runen bereit" end

    for _, sort in ipairs({ "unholy", "frost", "blood" }) do
        if value[sort] and (snap.runes[sort] or 0) < value[sort] then
            return false, "keine " .. RUNE_LABELS[sort]
        end
    end
    return false, "keine passende Rune"
end

Checks.spellReady = function(value, snap)
    local state = SpellAvailability(value, snap)
    local name = SpellName(value) or "Zauber"
    if state == "ready" then return true, name .. " bereit" end
    return false, name .. " nicht bereit"
end

Checks.spellOnCooldown = function(value, snap)
    local state = SpellAvailability(value, snap)
    local name = SpellName(value) or "Zauber"
    if state ~= "ready" then return true, name .. " läuft" end
    return false, name .. " ist bereit"
end

-- Feste Reihenfolge: die erste nicht erfüllte Bedingung liefert den
-- Text. Ohne feste Reihenfolge (pairs über die Tabelle) würde in der
-- Zeile bei jedem Durchlauf ein anderer Grund stehen.
local CHECK_ORDER = {
    "hpBelow", "hpAbove",
    "buff", "noBuff", "debuff", "noDebuff",
    "power", "combo", "runes",
    "spellReady", "spellOnCooldown",
}

local EvalWhen

local function EvalAnyOf(branches, snap, rule, spec)
    local firstFail
    for _, branch in ipairs(branches) do
        local met, text = EvalWhen(branch, snap, rule, spec)
        if met then return true, text end
        if not firstFail then firstFail = text end
    end
    return false, firstFail
end

EvalWhen = function(when, snap, rule, spec)
    if not when then return true, nil end

    local firstMetText

    for _, key in ipairs(CHECK_ORDER) do
        local value = when[key]
        if value ~= nil then
            local met, text = Checks[key](value, snap, rule, spec)
            if not met then return false, text end
            if not firstMetText then firstMetText = text end
        end
    end

    if when.anyOf then
        local met, text = EvalAnyOf(when.anyOf, snap, rule, spec)
        if not met then return false, text end
        if not firstMetText then firstMetText = text end
    end

    return true, firstMetText
end

RE.EvalWhen = EvalWhen

--------------------------------------------------
-- Überwachte Auren (für die Laufzeit-Wertung)
--
-- Welche Aura eine Regel mit track = true meint, steht nicht extra in
-- den Daten - sie ergibt sich aus der Bedingung. Eine Regel, die auf
-- "Debuff fehlt" wartet, überwacht genau diesen Debuff.
--------------------------------------------------

local function InferTrackedAura(rule)
    if rule.trackAura then return rule.trackAura end
    local when = rule.when
    if not when then return nil end

    -- Debuffs am Ziel haben Vorrang vor eigenen Buffs: eine Regel wie
    -- "mit Raureif gratis, sonst zum Setzen des Frostfiebers" meint für
    -- die Laufzeitmessung das Frostfieber, nicht den Prozz.
    local function fromBlock(block, wantTarget)
        if not block then return nil end
        if wantTarget then
            if block.noDebuff then return { id = NormalizeAura(block.noDebuff).id, unit = "target" } end
            if block.debuff   then return { id = NormalizeAura(block.debuff).id,   unit = "target" } end
        else
            if block.noBuff   then return { id = NormalizeAura(block.noBuff).id,   unit = "player" } end
            if block.buff     then return { id = NormalizeAura(block.buff).id,     unit = "player" } end
        end
        return nil
    end

    for _, wantTarget in ipairs({ true, false }) do
        local direct = fromBlock(when, wantTarget)
        if direct then return direct end
        for _, branch in ipairs(when.anyOf or {}) do
            local found = fromBlock(branch, wantTarget)
            if found then return found end
        end
    end

    return nil
end

--------------------------------------------------
-- Tastenbelegung
--
-- Best-Effort: die Aktionsleisten werden nach der Spell-ID abgesucht
-- und der Platz auf seine Standardbindung abgebildet. Findet sich
-- nichts, bleibt das Feld leer - dann fehlt in der Zeile eben das
-- Tastenkürzel, mehr nicht.
--------------------------------------------------

local keybinds = {}
local keybindsDirty = true

local function BindingForSlot(slot)
    if slot <= 12 then return "ACTIONBUTTON" .. slot end
    if slot <= 24 then return nil end                               -- Seite 2, ohne eigene Bindung
    if slot <= 36 then return "MULTIACTIONBAR3BUTTON" .. (slot - 24) end
    if slot <= 48 then return "MULTIACTIONBAR4BUTTON" .. (slot - 36) end
    if slot <= 60 then return "MULTIACTIONBAR2BUTTON" .. (slot - 48) end
    if slot <= 72 then return "MULTIACTIONBAR1BUTTON" .. (slot - 60) end
    return nil
end

local KEY_SHORT = {
    ["SHIFT%-"] = "S", ["CTRL%-"] = "C", ["ALT%-"] = "A",
    ["BUTTON"]  = "M", ["NUMPAD"] = "N",
    ["MOUSEWHEELUP"] = "MwU", ["MOUSEWHEELDOWN"] = "MwD",
}

local function ShortenKey(key)
    if not key or key == "" then return nil end
    local short = key
    for pattern, replacement in pairs(KEY_SHORT) do
        short = short:gsub(pattern, replacement)
    end
    if #short > 6 then short = short:sub(1, 6) end
    return short
end

local function SpellIdForSlot(slot)
    local actionType, id, subType = GetActionInfo(slot)
    if not actionType then return nil end

    if actionType == "spell" and type(id) == "number" then
        return id
    end

    if actionType == "macro" and GetMacroSpell then
        local macroSpell = GetMacroSpell(id)
        if type(macroSpell) == "number" then return macroSpell end
        if type(macroSpell) == "string" then
            return select(7, GetSpellInfo(macroSpell))
        end
    end

    return nil
end

local function RebuildKeybinds()
    keybindsDirty = false
    for key in pairs(keybinds) do keybinds[key] = nil end
    if not GetActionInfo or not GetBindingKey then return end

    for slot = 1, 72 do
        local spellId = SpellIdForSlot(slot)
        if spellId and not keybinds[spellId] then
            local binding = BindingForSlot(slot)
            if binding then
                local short = ShortenKey(GetBindingKey(binding))
                if short then keybinds[spellId] = short end
            end
        end
    end
end

function RE.InvalidateKeybinds()
    keybindsDirty = true
end

function RE.Keybind(spellId)
    if keybindsDirty then RebuildKeybinds() end
    return keybinds[spellId]
end

--------------------------------------------------
-- Auswertung
--------------------------------------------------

local STATE_BUCKET = {
    ready    = 1,
    resource = 2,
    waiting  = 3,
    blocked  = 4,
    unknown  = 5,
}

RE.StateBucket = STATE_BUCKET

local plan = { entries = {}, ranked = {}, extras = {} }

local function ResetList(list)
    for i = #list, 1, -1 do list[i] = nil end
end

-- Fehlt nur die Ressource, ist das ein eigener Zustand: die Bedingung
-- stimmt, gedrückt werden kann trotzdem nicht. IsUsableSpell sagt das
-- als zweiten Rückgabewert - genauer als jede eigene Schätzung.
local function ResourceMissing(spellId)
    if not IsUsableSpell then return false end
    local name = SpellName(spellId)
    if not name then return false end
    local _, noPower = IsUsableSpell(name)
    return noPower == true
end

local function SortEntries(a, b)
    if a.bucket ~= b.bucket then return a.bucket < b.bucket end
    if a.bucket == STATE_BUCKET.waiting then
        -- Auf halbe Sekunden gerundet, damit die Reihenfolge nicht bei
        -- jedem Zehntel neu zappelt.
        local ra = math.floor((a.remaining or 0) * 2)
        local rb = math.floor((b.remaining or 0) * 2)
        if ra ~= rb then return ra < rb end
    end
    return a.index < b.index
end

-- muted: { [spellId] = true } - vom Spieler stummgeschaltete Regeln,
-- etwa weil ihm das Talent fehlt. Sie bleiben sichtbar, zählen aber
-- weder für die Empfehlung noch für die Bewertung.
function RE.Evaluate(specKey, muted)
    local spec = WeintCodex_GetRotation and WeintCodex_GetRotation(specKey)

    ResetList(plan.entries)
    ResetList(plan.ranked)
    ResetList(plan.extras)
    plan.spec = spec
    plan.specKey = specKey

    if not spec then
        plan.snapshot = nil
        return plan
    end

    local snap = BuildSnapshot()
    plan.snapshot = snap

    for index, rule in ipairs(spec.rules or {}) do
        local spellId = ResolveSpell(rule)
        local state, remaining, charges = SpellAvailability(spellId, snap)
        local reason

        if state == "unknown" then
            reason = "nicht erlernt"
        else
            local met, text = EvalWhen(rule.when, snap, rule, spec)
            reason = text
            if not met then
                state = "blocked"
            elseif state == "ready" and ResourceMissing(spellId) then
                state = "resource"
                reason = "zu wenig " .. PowerLabel(spec.resource)
            end
        end

        local isMuted = muted and muted[spellId] or false
        if isMuted then state = "unknown"; reason = "stummgeschaltet" end

        local entry = {
            rule      = rule,
            index     = index,
            spell     = spellId,
            state     = state,
            bucket    = STATE_BUCKET[state] or 5,
            remaining = remaining or 0,
            charges   = charges,
            reason    = reason,
            muted     = isMuted,
        }

        plan.entries[#plan.entries + 1] = entry
        if state == "ready" then plan.ranked[#plan.ranked + 1] = entry end
    end

    table.sort(plan.entries, SortEntries)
    table.sort(plan.ranked, function(a, b) return a.index < b.index end)

    for index, rule in ipairs(spec.extras or {}) do
        local spellId = ResolveSpell(rule)
        local state, remaining = SpellAvailability(spellId, snap)
        local met, text = true, nil
        if state ~= "unknown" then
            met, text = EvalWhen(rule.when, snap, rule, spec)
        end
        plan.extras[#plan.extras + 1] = {
            rule      = rule,
            index     = index,
            spell     = spellId,
            state     = state,
            ready     = (state == "ready") and met or false,
            remaining = remaining or 0,
            reason    = text,
        }
    end

    return plan
end

-- Die Empfehlung als reine Liste von Spell-IDs, in Prioritätsreihenfolge.
--
-- Evaluate liefert immer dieselbe Tabelle zurück (einmal angelegt, pro
-- Takt neu befüllt - zehnmal pro Sekunde eine frische Tabelle wäre
-- Arbeit für den Garbage Collector, die niemand braucht). Für die
-- Bewertung wird aber der Zustand VOR dem Zauber gebraucht, und der
-- wäre in derselben Tabelle längst überschrieben. Deshalb zieht der
-- Trainer sich pro Takt diese kleine Kopie und hält zwei davon.
function RE.RankList(evaluated, into)
    into = into or {}
    ResetList(into)
    for i, entry in ipairs(evaluated.ranked) do into[i] = entry.spell end
    return into
end

-- Platz einer Fähigkeit in einer Rangliste (1 = jetzt fällig).
function RE.RankOf(ranks, spellId)
    for rank = 1, #ranks do
        if ranks[rank] == spellId then return rank end
    end
    return nil
end

function RE.IsRotationSpell(specKey, spellId)
    local spec = WeintCodex_GetRotation and WeintCodex_GetRotation(specKey)
    if not spec then return false end
    for _, rule in ipairs(spec.rules or {}) do
        if RuleUsesSpell(rule, spellId) then return true end
    end
    return false
end

function RE.IsExtraSpell(specKey, spellId)
    local spec = WeintCodex_GetRotation and WeintCodex_GetRotation(specKey)
    if not spec then return false end
    for _, rule in ipairs(spec.extras or {}) do
        if RuleUsesSpell(rule, spellId) then return true end
    end
    return false
end

--------------------------------------------------
-- Sitzung / Bewertung
--------------------------------------------------

local CREDIT_BY_RANK = { 1.00, 0.65, 0.35 }
local CREDIT_TAIL    = 0.15

local GRADES = {
    { min = 92, grade = "S", label = "Meisterhaft" },
    { min = 84, grade = "A", label = "Sehr gut" },
    { min = 74, grade = "B", label = "Gut" },
    { min = 62, grade = "C", label = "Solide" },
    { min = 48, grade = "D", label = "Ausbaufähig" },
    { min =  0, grade = "E", label = "Übungsbedarf" },
}

local Session = {}
RE.Session = Session

local state = nil

function Session.IsActive() return state ~= nil end

function Session.Start(specKey)
    local spec = WeintCodex_GetRotation and WeintCodex_GetRotation(specKey)

    state = {
        specKey    = specKey,
        startedAt  = GetTime(),
        combatTime = 0,
        busyTime   = 0,
        casts      = 0,      -- gewertete Zauber aus der Rotation
        offList    = 0,      -- alles andere (Tränke, Extras, Fremdzauber)
        credit     = 0,
        perfect    = 0,      -- davon auf Rang 1
        mistakes   = {},     -- ["gewirkt>erwartet"] = { count, cast, expected }
        tracked    = {},     -- [spellId] = { name, unit, seen, samples }
        usage      = {},     -- [spellId] = Anzahl
    }

    for _, rule in ipairs(spec and spec.rules or {}) do
        if rule.track then
            local aura = InferTrackedAura(rule)
            if aura and aura.id then
                state.tracked[aura.id] = {
                    unit = aura.unit, seen = 0, samples = 0,
                    name = SpellName(aura.id) or SpellName(rule.spell),
                }
            end
        end
    end

    return state
end

-- Wird bei jedem Anzeigetakt gerufen. Nur im Kampf, sonst würde das
-- Zielen zwischen zwei Pulls die Auslastung verwässern.
function Session.Sample(evaluated, elapsed, inCombat)
    if not state or not inCombat or not evaluated or not evaluated.snapshot then return end
    local snap = evaluated.snapshot

    state.combatTime = state.combatTime + elapsed

    if snap.gcdRemaining > 0 or snap.casting then
        state.busyTime = state.busyTime + elapsed
    end

    for auraId, track in pairs(state.tracked) do
        local cache = (track.unit == "player") and snap.playerAuras or snap.targetAuras
        -- Ohne Ziel gibt es nichts zu messen: ein toter Dummy zwischen
        -- zwei Versuchen darf die Laufzeit nicht nach unten ziehen.
        if track.unit == "player" or snap.hasTarget then
            track.samples = track.samples + 1
            if AuraInfo(cache, auraId) then track.seen = track.seen + 1 end
        end
    end
end

-- ranks ist die Rangliste unmittelbar VOR dem Zauber, previousRanks
-- die vom Takt davor. Beide zu prüfen fängt den Fall ab, dass sich der
-- Zustand in genau dem Moment geändert hat, in dem die Taste schon
-- gedrückt war - sonst zählt eine richtige Entscheidung als Fehler,
-- nur weil ein Dot zwischen Tastendruck und Server-Antwort ablief.
function Session.NoteCast(spellId, ranks, previousRanks)
    if not state then return nil end

    state.usage[spellId] = (state.usage[spellId] or 0) + 1

    if not RE.IsRotationSpell(state.specKey, spellId) then
        state.offList = state.offList + 1
        return nil
    end

    ranks = ranks or {}
    previousRanks = previousRanks or {}

    local rank = RE.RankOf(ranks, spellId)
    local previousRank = RE.RankOf(previousRanks, spellId)
    if previousRank and (not rank or previousRank < rank) then rank = previousRank end

    local expected = ranks[1] or previousRanks[1]

    -- Gar nichts war wirkbar: in einer Ressourcenpause gibt es keine
    -- falsche Taste, also auch keine Wertung.
    if not expected then
        state.offList = state.offList + 1
        return nil
    end

    local credit = rank and (CREDIT_BY_RANK[rank] or CREDIT_TAIL) or 0

    state.casts  = state.casts + 1
    state.credit = state.credit + credit
    if rank == 1 then state.perfect = state.perfect + 1 end

    if rank ~= 1 then
        local key = spellId .. ">" .. expected
        local entry = state.mistakes[key]
        if not entry then
            entry = { count = 0, cast = spellId, expected = expected }
            state.mistakes[key] = entry
        end
        entry.count = entry.count + 1
    end

    return credit, rank, expected
end

local function GradeFor(score)
    for _, step in ipairs(GRADES) do
        if score >= step.min then return step.grade, step.label end
    end
    return "E", "Übungsbedarf"
end

local function CollectMistakes()
    local list = {}
    for _, entry in pairs(state.mistakes) do
        list[#list + 1] = entry
    end
    table.sort(list, function(a, b)
        if a.count ~= b.count then return a.count > b.count end
        return a.cast < b.cast
    end)
    return list
end

local function CollectTracked()
    local list = {}
    for auraId, track in pairs(state.tracked) do
        if track.samples > 0 then
            list[#list + 1] = {
                id     = auraId,
                name   = track.name or SpellName(auraId) or "?",
                uptime = track.seen / track.samples * 100,
            }
        end
    end
    -- Schwächste zuerst: die Anzeige zeigt nur die ersten beiden, und
    -- interessant ist die Aura, die zu oft ausgelaufen ist.
    table.sort(list, function(a, b)
        if a.uptime ~= b.uptime then return a.uptime < b.uptime end
        return a.id < b.id
    end)
    return list
end

-- Zwischenstand für die Kopfzeile und die Bewertungsseite; dieselbe
-- Rechnung wie Finish, nur ohne die Sitzung zu beenden.
function Session.Score()
    if not state then return nil end

    local priority = state.casts > 0 and (state.credit / state.casts * 100) or 0
    local busy = state.combatTime > 0
        and math.min(1, state.busyTime / state.combatTime) * 100 or 0

    local uptimeSum, uptimeCount = 0, 0
    for _, track in pairs(state.tracked) do
        if track.samples > 0 then
            uptimeSum = uptimeSum + (track.seen / track.samples * 100)
            uptimeCount = uptimeCount + 1
        end
    end
    local uptime = uptimeCount > 0 and (uptimeSum / uptimeCount) or nil

    local total
    if uptime then
        total = priority * 0.6 + busy * 0.2 + uptime * 0.2
    else
        total = priority * 0.8 + busy * 0.2
    end

    return {
        specKey  = state.specKey,
        priority = priority,
        busy     = busy,
        uptime   = uptime,
        total    = total,
        casts    = state.casts,
        perfect  = state.perfect,
        offList  = state.offList,
        duration = state.combatTime,
        apm      = (state.combatTime > 0)
                   and (state.casts + state.offList) / (state.combatTime / 60) or 0,
        mistakes = CollectMistakes(),
        tracked  = CollectTracked(),
    }
end

function Session.Finish()
    if not state then return nil end

    local result = Session.Score()
    result.grade, result.gradeLabel = GradeFor(result.total or 0)

    state = nil
    return result
end

function Session.Abort()
    state = nil
end

RE.GradeFor = GradeFor

--------------------------------------------------
-- Selbstauskunft für "/wc training check"
--
-- Gibt jede Regel der aktuellen Spec mit Spell-ID, Client-Namen und
-- Gelernt-Status aus. Damit lässt sich eine falsche ID in
-- data/rotations.lua zeilengenau melden, ohne raten zu müssen, warum
-- eine Zeile im Fenster leer bleibt.
--------------------------------------------------

function RE.PrintDiagnostics(specKey)
    local spec = WeintCodex_GetRotation and WeintCodex_GetRotation(specKey)

    if not spec then
        print("|cffC8763A[WeintCodex]|r Für " .. tostring(specKey)
            .. " ist keine Rotation hinterlegt.")
        return
    end

    print("|cffC8763A[WeintCodex]|r Rotationsprüfung " .. specKey
        .. " (Ressource: " .. tostring(spec.resource) .. ")")

    local sections = { { "Regel", spec.rules }, { "Extra", spec.extras } }
    for _, section in ipairs(sections) do
        for index, rule in ipairs(section[2] or {}) do
            local spellId = ResolveSpell(rule)
            local name = SpellName(spellId)
            local mark, colour
            if not name then
                mark, colour = "UNBEKANNT", "ffff5555"
            elseif not IsKnown(spellId) then
                mark, colour = "nicht erlernt", "ffc8a03a"
            elseif spellId ~= rule.spell then
                mark, colour = "ok (Ausweich-ID)", "ff4a7c59"
            else
                mark, colour = "ok", "ff4a7c59"
            end
            print(string.format("  %s #%d  %d  %s  |c%s%s|r",
                section[1], index, spellId, name or "?", colour, mark))
        end
    end
end
