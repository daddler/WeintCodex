--------------------------------------------------
-- WeintCodex :: Charakter Module
-- Mists of Pandaria Classic
--
-- Rubriken:
--   Übersicht        – Portrait + Gesamtscore + Handlungsbedarf
--   Verzauberungen   – Alle enchantbaren Slots (vorhanden? optimal?)
--   Sockel           – Alle Sockel inkl. Gürtelschnalle (belegt? optimal? über Cap?)
--   Werteverteilung  – Stat-Summen + Treffer-/Waffenkunde-Caps
--   Twinkverwaltung  – Gilden-Scan & Export
--
-- Bewertungssystem (pro Prüfung 0–100 Punkte):
--   Optimal   100  – vorhanden und für die Spec empfohlen
--   OK         70  – vorhanden, aber nicht ideal (>=65% Statwert der Empfehlung)
--   Über Cap   35  – liefert einen Stat, der bereits über dem Cap liegt
--   Falsch     30  – vorhanden, aber klar falscher Stat (<65%)
--   Fehlt       0  – keine Verzauberung / leerer Sockel
--------------------------------------------------

WeintCodex.Charakter = {}

local C = WeintCodex.Colors

--------------------------------------------------
-- HILFSFUNKTIONEN (UI)
--------------------------------------------------

local function SetSolidBg(f, r, g, b, a)
    if f._wcBg then
        f._wcBg:SetColorTexture(r, g, b, a or 1)
        return f._wcBg
    end
    local t = f:CreateTexture(nil, "BACKGROUND")
    t:SetAllPoints(f)
    t:SetColorTexture(r, g, b, a or 1)
    f._wcBg = t
    return t
end

local function DrawBorder(f, r, g, b, a, thick)
    thick = thick or 1
    local W, H = f:GetWidth(), f:GetHeight()
    local function T(pt, rpt, w, h)
        local t = f:CreateTexture(nil, "OVERLAY")
        t:SetColorTexture(r, g, b, a)
        t:SetPoint(pt, f, rpt, 0, 0)
        t:SetSize(w, h)
    end
    T("TOPLEFT",    "TOPLEFT",    W,     thick)
    T("BOTTOMLEFT", "BOTTOMLEFT", W,     thick)
    T("TOPLEFT",    "TOPLEFT",    thick, H)
    T("TOPRIGHT",   "TOPRIGHT",   thick, H)
end

local function MakeBtn(parent, label, w, h, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(w, h)
    SetSolidBg(btn, C.surface2[1], C.surface2[2], C.surface2[3], 0.92)
    DrawBorder(btn, C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.70, 1)
    local lbl = btn:CreateFontString(nil, "OVERLAY")
    lbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    lbl:SetAllPoints(btn)
    lbl:SetJustifyH("CENTER")
    lbl:SetJustifyV("MIDDLE")
    lbl:SetText(label)
    lbl:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
    btn:SetScript("OnEnter", function(self) SetSolidBg(self, C.surface3[1], C.surface3[2], C.surface3[3], 0.98) end)
    btn:SetScript("OnLeave", function(self) SetSolidBg(self, C.surface2[1], C.surface2[2], C.surface2[3], 0.92) end)
    if onClick then btn:SetScript("OnClick", onClick) end
    return btn, lbl
end

local function CreateScrollArea(parent, x, y, w, h)
    local sf = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    sf:SetSize(w, h)
    sf:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    local inner = CreateFrame("Frame", nil, sf)
    inner:SetSize(w - 20, h)
    sf:SetScrollChild(inner)
    return sf, inner
end

--------------------------------------------------
-- STATUS-DEFINITIONEN (5-Zustands-System)
--------------------------------------------------

local PURPLE = C.violet

local STATUS = {
    optimal = { icon = "Interface\\RaidFrame\\ReadyCheck-Ready",       size = 16, label = "Optimal",  color = C.green },
    ok      = { icon = "Interface\\DialogFrame\\UI-Dialog-Icon-Alert", size = 18, label = "OK",       color = C.gold },
    wrong   = { icon = "Interface\\DialogFrame\\UI-Dialog-Icon-Alert", size = 18, label = "Falsch",   color = C.red,  tint = { 1.0, 0.45, 0.35 } },
    overcap = { icon = "Interface\\DialogFrame\\UI-Dialog-Icon-Alert", size = 18, label = "Über Cap", color = PURPLE, tint = { 0.75, 0.50, 1.0 } },
    missing = { icon = "Interface\\RaidFrame\\ReadyCheck-NotReady",    size = 16, label = "Fehlt",    color = C.red },
    neutral = { icon = "Interface\\Buttons\\UI-MinusButton-UP",        size = 14, label = "—",        color = C.textDim },
}

local STATUS_POINTS = {
    optimal = 100, ok = 70, overcap = 35, wrong = 30, missing = 0,
}

local function AttachStatusIcon(parent, status, xOff, yOff)
    local info = STATUS[status] or STATUS.neutral
    local tex  = parent:CreateTexture(nil, "OVERLAY")
    tex:SetSize(info.size, info.size)
    tex:SetPoint("LEFT", parent, "LEFT", xOff or 8, yOff or 0)
    tex:SetTexture(info.icon)
    if info.tint then tex:SetVertexColor(info.tint[1], info.tint[2], info.tint[3]) end
    return tex
end

local function StatusColorStr(status)
    local col = (STATUS[status] or STATUS.neutral).color
    return string.format("|cff%02x%02x%02x", col[1] * 255, col[2] * 255, col[3] * 255)
end

--------------------------------------------------
-- NAMENSAUFLÖSUNG (Verzauberungen & Steine)
--------------------------------------------------

local scanTip = CreateFrame("GameTooltip", "WeintCodexScanTip", nil, "GameTooltipTemplate")
scanTip:SetOwner(UIParent, "ANCHOR_NONE")

-- WICHTIG: zwei GETRENNTE Caches, nicht eine gemeinsame Tabelle!
-- _enchantDbNameCache cached DB-/Hyperlink-Namen NACH Enchant-ID (für
-- Empfehlungstexte). _enchantTooltipCache cached den LIVE vom Item-Tooltip
-- gelesenen Namen (für angelegte Verzauberungen). Beide teilen sich zufällig
-- denselben Enchant-ID-Namensraum — würden sie denselben Cache nutzen,
-- könnte ein DB-Namenslookup für eine ID X (z.B. beim Auflösen einer
-- Empfehlung) einen späteren Live-Tooltip-Scan für ein ANDERES Item mit
-- derselben ID X unterdrücken (Cache-Hit liefert den ungeprüften DB-Namen,
-- statt den Tooltip zu scannen) — und umgekehrt.
WeintCodex._enchantDbNameCache = WeintCodex._enchantDbNameCache or {}
WeintCodex._enchantTooltipCache = WeintCodex._enchantTooltipCache or {}

-- Manche Items sind beim Scan noch nicht vollständig aus dem Server-Cache
-- geladen (GetItemInfo liefert nil) — der Tooltip zeigt dann nur "Wird
-- abgerufen..." OHNE Verzauberungszeile, der Live-Scan schlägt fehl und wir
-- fallen auf den (evtl. falschen/ungeprüften) DB-Namen zurück. Betroffene
-- Item-IDs werden hier gesammelt; sobald der Client sie nachliefert
-- (GET_ITEM_INFO_RECEIVED, siehe itemInfoWatcher weiter unten), wird die
-- aktive Seite automatisch neu gescannt.
local pendingItemInfoIds = {}

local function GetEnchantDisplayName(enchantId)
    if not enchantId then return nil end
    if WeintCodex._enchantDbNameCache[enchantId] then
        return WeintCodex._enchantDbNameCache[enchantId]
    end
    local db = WeintCodex_Enchants and WeintCodex_Enchants[enchantId]
    if db and db.name then
        WeintCodex._enchantDbNameCache[enchantId] = db.name
        return db.name
    end
    scanTip:ClearLines()
    scanTip:SetHyperlink("enchant:" .. enchantId)
    if scanTip:NumLines() >= 1 then
        local line = _G["WeintCodexScanTipTextLeft1"]
        local name = line and line:GetText()
        if name and name ~= "" then
            WeintCodex._enchantDbNameCache[enchantId] = name
            return name
        end
    end
    return "Unbekannt (ID " .. enchantId .. ")"
end

local function GetGemDisplayName(gemId)
    if not gemId then return nil end
    if WeintCodex_GetGemName then
        return WeintCodex_GetGemName(gemId)
    end
    return "Unbekannter Stein (ID: " .. gemId .. ")"
end

-- Sicherheitsnetz: liefert Name + ID der ersten AUFLÖSBAREN Empfehlung
-- aus der Liste (überspringt IDs, die nur als "Unbekannt (ID …)" bzw.
-- "Unbekannter Stein …" auflösen) und optional solche, die namensgleich
-- zur bereits angelegten sind. Verhindert, dass eine kaputte ID als
-- Empfehlung angezeigt wird, obwohl die richtige schon getragen wird.
local function FirstResolvableName(list, resolver, curName)
    if not list then return nil end
    for _, id in ipairs(list) do
        local n = resolver(id)
        if n and not n:find("Unbekannt", 1, true)
           and not (curName and n:lower() == curName:lower()) then
            return n, id
        end
    end
    return nil
end

--------------------------------------------------
-- Verzauberungsname direkt vom Item-Tooltip lesen.
-- Der Client liefert die offizielle deutsche
-- Lokalisierung ("Verzaubert: <Name>") — damit sind
-- die Namen angelegter Verzauberungen immer korrekt,
-- unabhängig von unserer Datenbank.
--------------------------------------------------

local ENCHANT_LINE_PATTERN
do
    -- ENCHANTED_TOOLTIP_LINE = "Verzaubert: %s" (dt. Client)
    local raw = _G.ENCHANTED_TOOLTIP_LINE or "Verzaubert: %s"
    ENCHANT_LINE_PATTERN = "^" .. raw:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
                                    :gsub("%%%%s", "(.+)")
end

local function GetEquippedEnchantText(slotId, enchantId, link)
    if not enchantId then return nil end
    if WeintCodex._enchantTooltipCache[enchantId] then
        return WeintCodex._enchantTooltipCache[enchantId]
    end
    scanTip:ClearLines()
    scanTip:SetInventoryItem("player", slotId)
    local n = scanTip:NumLines() or 0
    for i = 2, n do
        local line = _G["WeintCodexScanTipTextLeft" .. i]
        local txt = line and line:GetText()
        if txt then
            local name = txt:match(ENCHANT_LINE_PATTERN)
            if name and name ~= "" then
                WeintCodex._enchantTooltipCache[enchantId] = name
                return name
            end
        end
    end

    -- Scan lieferte keine Verzauberungszeile. Wenn die BASIS-Itemdaten
    -- selbst noch nicht im Client-Cache liegen (GetItemInfo == nil), ist
    -- der Tooltip nur unvollständig ("Wird abgerufen...") — das ist die
    -- Ursache, nicht ein falscher/fehlender DB-Eintrag. Für diese Item-ID
    -- auf Nachlieferung warten (GET_ITEM_INFO_RECEIVED, s.u.).
    local itemId = link and tonumber(link:match("item:(%d+):"))
    if itemId and not GetItemInfo(itemId) then
        pendingItemInfoIds[itemId] = true
    end
    return nil
end

local function ClearCharakterCache()
    WeintCodex._enchantDbNameCache = {}
    WeintCodex._enchantTooltipCache = {}
end

--------------------------------------------------
-- AUSRÜSTUNGSSLOTS
-- MoP hat keinen Fernkampf-Slot mehr (Slot 18 entfällt);
-- Zielfernrohre sitzen auf der Waffe in Slot 16.
--------------------------------------------------

local EQUIP_SLOTS = {
    { id = 1,  name = "Kopf" },
    { id = 2,  name = "Hals" },
    { id = 3,  name = "Schultern",   enchSlot = "Schultern" },
    { id = 5,  name = "Brust",       enchSlot = "Brust" },
    { id = 6,  name = "Taille" },
    { id = 7,  name = "Beine",       enchSlot = "Beine" },
    { id = 8,  name = "Füße",        enchSlot = "Füße" },
    { id = 9,  name = "Handgelenke", enchSlot = "Handgelenke" },
    { id = 10, name = "Hände",       enchSlot = "Hände" },
    { id = 11, name = "Finger 1" },
    { id = 12, name = "Finger 2" },
    { id = 13, name = "Schmuck 1" },
    { id = 14, name = "Schmuck 2" },
    { id = 15, name = "Umhang",      enchSlot = "Umhang" },
    { id = 16, name = "Haupthand",   enchSlot = "Waffe" },
    { id = 17, name = "Nebenhand",   enchSlot = "Waffe", nurWaffe = true },
}

-- WICHTIG: Diese Farben bezeichnen den SOCKELPLATZ im Item,
-- nicht die Farbe des eingesetzten Steins! Ein andersfarbiger
-- Stein (z.B. Lila in Blau) kann trotzdem optimal sein.
local SOCKET_COLOR_LABEL = {
    meta      = "Meta-Sockel",
    rot       = "Roter Sockel",
    gelb      = "Gelber Sockel",
    blau      = "Blauer Sockel",
    orange    = "Oranger Sockel",
    lila      = "Lila Sockel",
    ["grün"]  = "Grüner Sockel",
    prismatic = "Prisma-Sockel",
}

local SOCKET_DOT_COLOR = {
    rot       = { 0.90, 0.20, 0.20 },
    gelb      = { 0.95, 0.85, 0.10 },
    blau      = { 0.20, 0.55, 0.95 },
    orange    = { 0.95, 0.55, 0.10 },
    lila      = { 0.65, 0.25, 0.90 },
    ["grün"]  = { 0.20, 0.80, 0.30 },
    meta      = { 0.70, 0.60, 0.90 },
    prismatic = { 0.85, 0.85, 0.85 },
}

--------------------------------------------------
-- SPEC-MAP: Klasse + Index → Profil-Key
--------------------------------------------------

local SPEC_MAP = {
    WARRIOR     = { "ARMS",          "FURY",          "PROTECTION"  },
    PALADIN     = { "HOLY",          "PROTECTION",    "RETRIBUTION" },
    HUNTER      = { "BEASTMASTERY",  "MARKSMANSHIP",  "SURVIVAL"    },
    ROGUE       = { "ASSASSINATION", "COMBAT",        "SUBTLETY"    },
    PRIEST      = { "DISCIPLINE",    "HOLY",          "SHADOW"      },
    DEATHKNIGHT = { "BLOOD",         "FROST",         "UNHOLY"      },
    SHAMAN      = { "ELEMENTAL",     "ENHANCEMENT",   "RESTORATION" },
    MAGE        = { "ARCANE",        "FIRE",          "FROST"       },
    WARLOCK     = { "AFFLICTION",    "DEMONOLOGY",    "DESTRUCTION" },
    MONK        = { "BREWMASTER",    "MISTWEAVER",    "WINDWALKER"  },
    DRUID       = { "BALANCE",       "FERAL",         "GUARDIAN",   "RESTORATION" },
}

local TANK_SPECS = {
    WARRIOR_PROTECTION   = true,
    PALADIN_PROTECTION   = true,
    DEATHKNIGHT_BLOOD    = true,
    MONK_BREWMASTER      = true,
    DRUID_GUARDIAN       = true,
}

--------------------------------------------------
-- TANK-SPIELSTIL ("DEF" | "OFF"), persistent
--------------------------------------------------

local function GetTankStyle(profileKey)
    local sd = WeintCodex.SavedData
    if sd and sd.tankStyle and sd.tankStyle[profileKey] then
        return sd.tankStyle[profileKey]
    end
    return "DEF"
end

local function SetTankStyle(profileKey, style)
    local sd = WeintCodex.SavedData
    if sd then
        sd.tankStyle = sd.tankStyle or {}
        sd.tankStyle[profileKey] = style
    end
end

--------------------------------------------------
-- EIGENE GEWICHTUNG (Priorisierung)
-- Spieler können die Stat-Gewichte pro Spec selbst
-- einstellen (Seite "Priorisierung"). Gespeichert in
-- SavedData.customWeights[effektiverProfilKey].
-- Überschreibt NUR statWeights — Empfehlungslisten
-- und Caps bleiben unverändert.
--------------------------------------------------

local function GetEffectiveProfileKey(profileKey, tankStyle)
    if not profileKey then return nil end
    if tankStyle == "OFF" then return profileKey .. "_OFFENSIVE" end
    return profileKey
end

local function ApplyCustomWeights(profile, profileKey, tankStyle)
    if not profile then return profile end
    local effKey = GetEffectiveProfileKey(profileKey, tankStyle)
    local sd = WeintCodex.SavedData
    local cw = sd and sd.customWeights and effKey and sd.customWeights[effKey]
    if not (cw and cw.enabled and cw.weights) then return profile end

    local p = {}
    for k, v in pairs(profile) do p[k] = v end
    p.statWeights = cw.weights
    p.customWeights = true
    return p
end

--------------------------------------------------
-- SPEC-ANZEIGENAME (lokalisiert über WoW-Client-API)
-- Liefert z.B. "Hexenmeister (Gebrechen)" — für die UI.
-- profileKey bleibt separat der interne Daten-Key.
--------------------------------------------------

local function GetSpecDisplayName(localizedClassName, specIndex)
    if not specIndex or not GetSpecializationInfo then
        return localizedClassName
    end
    local ok, _, specDisplayName = pcall(GetSpecializationInfo, specIndex)
    if ok and specDisplayName then
        return string.format("%s (%s)", localizedClassName, specDisplayName)
    end
    return localizedClassName
end

--------------------------------------------------
-- AKTIVES SPEC-PROFIL ERMITTELN
-- Gibt zurück: profile, profileKey, tankStyle, specDisplay
--------------------------------------------------

local function GetCurrentSpecProfile()
    local localizedClassName, className = UnitClass("player")
    if not className then return nil, nil, nil, nil end

    local specIndex
    if GetSpecialization then
        local ok, idx = pcall(GetSpecialization)
        if ok then specIndex = idx end
    end
    if not specIndex and GetPrimaryTalentTree then
        local ok, idx = pcall(GetPrimaryTalentTree)
        if ok then specIndex = idx end
    end
    if not specIndex then return nil, nil, nil, nil end

    local specs = SPEC_MAP[className]
    local specName = specs and specs[specIndex]
    if not specName then return nil, nil, nil, nil end

    local profileKey = className .. "_" .. specName
    local specDisplay = GetSpecDisplayName(localizedClassName, specIndex)

    if TANK_SPECS[profileKey] then
        local style = GetTankStyle(profileKey)
        if style == "OFF" then
            local offProfile = WeintCodex_SpecProfiles
                and WeintCodex_SpecProfiles[profileKey .. "_OFFENSIVE"]
            if offProfile then
                return ApplyCustomWeights(offProfile, profileKey, "OFF"), profileKey, "OFF", specDisplay
            end
        end
        local defProfile = WeintCodex_SpecProfiles and WeintCodex_SpecProfiles[profileKey]
        return ApplyCustomWeights(defProfile, profileKey, "DEF"), profileKey, "DEF", specDisplay
    end

    local profile = WeintCodex_SpecProfiles and WeintCodex_SpecProfiles[profileKey]
    return ApplyCustomWeights(profile, profileKey, nil), profileKey, nil, specDisplay
end

--------------------------------------------------
-- ITEM-LINK PARSEN: Verzauberung & Edelsteine
-- Format: |Hitem:itemId:ench:gem1:gem2:gem3:gem4:...|h[Name]|h
-- WICHTIG: Leere Felder (::) müssen mitgezählt werden,
-- sonst rutschen Steine in die Enchant-Position!
--------------------------------------------------

local function ParseItemLink(link)
    if not link then return nil, {} end
    local linkData = link:match("|Hitem:([^|]+)|h")
    if not linkData then return nil, {} end

    local parts = {}
    local i = 0
    for p in (linkData .. ":"):gmatch("([^:]*):") do
        i = i + 1
        parts[i] = tonumber(p)
    end

    local enchantId = (parts[2] and parts[2] > 0) and parts[2] or nil

    local gems = {}
    for g = 1, 4 do
        local v = parts[2 + g]
        if v and v > 0 then gems[g] = v end
    end

    return enchantId, gems
end

--------------------------------------------------
-- SOCKEL ERMITTELN (inkl. Zusatzsockel)
--   Basis-Sockel kommen aus den Item-Stats.
--   Steine JENSEITS der Basis-Sockel = Zusatzsockel
--   (Gürtelschnalle / Schmiedekunst).
--   Gürtel ohne Zusatzstein => Schnalle fehlt/leer.
--------------------------------------------------

local GetItemStatsCompat = GetItemStats or (C_Item and C_Item.GetItemStats)

local SOCKET_ORDER = {
    { stat = "EMPTY_SOCKET_META",      color = "meta" },
    { stat = "EMPTY_SOCKET_RED",       color = "rot" },
    { stat = "EMPTY_SOCKET_YELLOW",    color = "gelb" },
    { stat = "EMPTY_SOCKET_BLUE",      color = "blau" },
    { stat = "EMPTY_SOCKET_PRISMATIC", color = "prismatic" },
}

local function ScanItemSockets(link, slotId)
    local sockets = {}
    if not link then return sockets end

    local _, gems = ParseItemLink(link)
    local stats = GetItemStatsCompat and GetItemStatsCompat(link)

    local base = 0
    if stats then
        for _, socketInfo in ipairs(SOCKET_ORDER) do
            local count = stats[socketInfo.stat]
            if count and count > 0 then
                for _ = 1, count do
                    base = base + 1
                    sockets[base] = {
                        color = socketInfo.color,
                        gemId = gems[base],
                        index = base,
                    }
                end
            end
        end
    end

    -- Zusatzsockel: Steine jenseits der Basis-Sockel
    for g = base + 1, 4 do
        if gems[g] then
            sockets[#sockets + 1] = {
                color = "prismatic",
                gemId = gems[g],
                index = g,
                extra = true,
            }
        end
    end

    -- Gürtelschnalle: Gürtel OHNE Zusatzstein => fehlender Sockel
    if slotId == 6 and not gems[base + 1] then
        sockets[#sockets + 1] = {
            color = "prismatic",
            gemId = nil,
            index = base + 1,
            extra = true,
            buckle = true,
        }
    end

    return sockets
end

--------------------------------------------------
-- SOCKELBONUS AUSLESEN (Tooltip-Scan)
--   Der Sockelbonus (z.B. "Sockelbonus: +180 kritische
--   Trefferwertung") steht nicht in GetItemStats, sondern
--   nur im Item-Tooltip. Wir scannen die entsprechende
--   Zeile und parsen Stat + Wert, um später zu entscheiden,
--   ob sich das Farb-Matchen für dieses Item lohnt.
--------------------------------------------------

-- Prefix der Sockelbonus-Zeile (dt. Client: "Sockelbonus: %s")
local SOCKET_BONUS_PREFIX = (_G.ITEM_SOCKET_BONUS or "Sockelbonus: %s")
    :gsub("%%s.*$", ""):gsub("%s+$", "")

-- Deutsche Stat-Bezeichnungen -> interne Keys (identisch zu statWeights).
-- Reihenfolge = Priorität: spezifischere Begriffe zuerst
-- ("kritische Trefferwertung" vor "Trefferwertung").
local STAT_KEYWORDS = {
    { "kritische trefferwertung", "crit" },
    { "tempowertung",             "haste" },
    { "meisterschaftswertung",    "mastery" },
    { "ausweichwertung",          "dodge" },
    { "parierwertung",            "parry" },
    { "trefferwertung",           "hit" },
    { "waffenkunde",              "expertise" },
    { "beweglichkeit",            "agility" },
    { "intelligenz",              "intellect" },
    { "ausdauer",                 "stamina" },
    { "willenskraft",             "spirit" },
    { "stärke",                   "strength" },
}

local function ParseStatText(text)
    if not text then return nil end
    local value = tonumber(text:match("(%d+)"))
    if not value then return nil end
    local lower = text:lower()
    for _, entry in ipairs(STAT_KEYWORDS) do
        if lower:find(entry[1], 1, true) then
            return entry[2], value
        end
    end
    return nil
end

-- Gibt zurück: bonus = { stat=<key>, value=<num> } | nil, sowie den
-- rohen Tooltip-Text der Sockelbonus-Zeile (für die Anzeige).
local function ScanSocketBonus(slotId)
    scanTip:ClearLines()
    scanTip:SetInventoryItem("player", slotId)
    local n = scanTip:NumLines() or 0
    for i = 2, n do
        local line = _G["WeintCodexScanTipTextLeft" .. i]
        local txt = line and line:GetText()
        if txt and txt:find(SOCKET_BONUS_PREFIX, 1, true) then
            local stat, value = ParseStatText(txt)
            local clean = txt:gsub("^%s*" .. SOCKET_BONUS_PREFIX .. "%s*", "")
            if stat and value then
                return { stat = stat, value = value }, clean
            end
            return nil, clean
        end
    end
    return nil
end

--------------------------------------------------
-- WAFFEN-ERKENNUNG (Nebenhand: Schild/Beihand
-- bekommt keine Waffenverzauberung => neutral)
--------------------------------------------------

local function IsWeaponLink(link)
    if not link then return false end
    if GetItemInfoInstant then
        local _, _, _, _, _, classID = GetItemInfoInstant(link)
        if classID then return classID == 2 end
    end
    local classID = select(12, GetItemInfo(link))
    if classID then return classID == 2 end
    local itemType = select(6, GetItemInfo(link))
    return itemType == "Waffe" or itemType == "Weapon"
end

--------------------------------------------------
-- CAP-ENGINE: Trefferwertung / Waffenkunde live
-- Nutzt den Charakterbogen (inkl. Rassen-Boni und
-- Willenskraft-Umwandlung bei Shadow/Ele/Balance).
--------------------------------------------------

local CR_INDEX = { melee = 6, ranged = 7, spell = 8 }
local CR_EXPERTISE_INDEX = 24
local RATING_PER_PCT_FALLBACK = 340  -- Level 90

local CAP_LABEL = {
    melee     = "Trefferwertung (Nahkampf)",
    ranged    = "Trefferwertung (Fernkampf)",
    spell     = "Trefferwertung (Zauber)",
    expertise = "Waffenkunde",
}

local function BuildCapStates(profile)
    local states = {}
    if not profile or not profile.caps then return states end

    for _, cap in ipairs(profile.caps) do
        local idx
        if cap.stat == "expertise" then
            idx = CR_EXPERTISE_INDEX
        else
            idx = CR_INDEX[cap.typ or "melee"] or CR_INDEX.melee
        end

        local rating, bonus, mod = 0, 0, 0
        if GetCombatRating then
            local ok, v = pcall(GetCombatRating, idx)
            if ok and v then rating = v end
        end
        if GetCombatRatingBonus then
            local ok, v = pcall(GetCombatRatingBonus, idx)
            if ok and v then bonus = v end
        end
        if cap.stat == "hit" then
            if cap.typ == "spell" and GetSpellHitModifier then
                local ok, v = pcall(GetSpellHitModifier)
                if ok and v then mod = v end
            elseif cap.typ ~= "spell" and GetHitModifier then
                local ok, v = pcall(GetHitModifier)
                if ok and v then mod = v end
            end
        end

        local current = bonus + mod
        local perPct = RATING_PER_PCT_FALLBACK
        if bonus > 0.05 and rating > 0 then
            perPct = rating / bonus
        end
        local over = current - cap.pct

        states[#states + 1] = {
            stat         = cap.stat,
            typ          = cap.typ,
            capPct       = cap.pct,
            current      = current,
            overPct      = over,
            overRating   = (over > 0) and (over * perPct) or 0,
            underRating  = (over < 0) and (-over * perPct) or 0,
            perPct       = perPct,
            note         = cap.note,
            spiritZaehlt = cap.spiritZaehlt,
            label        = (cap.stat == "expertise") and CAP_LABEL.expertise
                           or (CAP_LABEL[cap.typ or "melee"] or "Trefferwertung"),
            wasted       = {},   -- wird im Overcap-Pass gefüllt
        }
    end

    return states
end

--------------------------------------------------
-- BEWERTUNG: Stein / Verzauberung
--------------------------------------------------

local function ScoreStats(stats, weights)
    if not stats or not weights then return 0 end
    local score = 0
    for stat, value in pairs(stats) do
        score = score + value * (weights[stat] or 0)
    end
    return score
end

local function IsInList(id, list)
    if not id or not list then return false end
    for _, v in ipairs(list) do
        if v == id then return true end
    end
    return false
end

-- Empfehlung für einen Sockel: erster Stein der Liste,
-- der KEINEN bereits übercappten Stat liefert. Sind alle
-- Kandidaten der Sockelfarbe gecappt, weiche auf die
-- prismatische Liste aus (z.B. reiner Primärstat).
--
-- decision (optional): Ergebnis von EvaluateSocketBonus. Lohnt sich
-- das Farb-Matchen für dieses Item NICHT (decision.worthwhile == false),
-- empfehlen wir für farbige Sockel den reinen Primärstein
-- (prismatic), statt einen schwächeren Farb-Stein für einen
-- geringwertigen Sockelbonus zu opfern.
local function PickGemRecommendation(socketColor, profile, overStats, decision)
    if not profile or not profile.bestGems then return nil end

    local list
    if decision and decision.worthwhile == false and socketColor ~= "meta" then
        -- Bonus ignorieren: den kuratierten Universalstein (prismatic)
        -- empfehlen; Fallback auf die Farb-Liste.
        list = profile.bestGems.prismatic or profile.bestGems[socketColor]
    else
        list = profile.bestGems[socketColor] or profile.bestGems.prismatic
    end
    if not list then return nil end

    if overStats then
        local function FirstUncapped(lst)
            for _, id in ipairs(lst) do
                local st = WeintCodex_GemStats and WeintCodex_GemStats[id]
                local blocked = false
                if st then
                    for stat in pairs(overStats) do
                        if st[stat] then blocked = true; break end
                    end
                end
                if not blocked then return id end
            end
            return nil
        end
        local pick = FirstUncapped(list)
        if not pick and profile.bestGems.prismatic then
            pick = FirstUncapped(profile.bestGems.prismatic)
        end
        if pick then return pick end
    end
    return list[1]
end

--------------------------------------------------
-- SOCKELBONUS-ENTSCHEIDUNG (pro Item)
--   Vergleicht zwei Strategien für ein Item:
--     IGNORE: in jedem farbigen Sockel den kuratierten Universalstein
--             (bestGems.prismatic[1], z.B. der reine Haupt-Sekundärstein)
--             -> kein Bonus, dafür überall der stärkste Einzelstein.
--     MATCH:  in jedem farbigen Sockel den besten FARBLICH passenden
--             Stein (bestGems[Farbe][1]) -> aktiviert den Sockelbonus.
--   Anker ist bewusst der kuratierte prismatische Stein (nicht der
--   rechnerisch höchste über alle Listen) — sonst würden Treffer-/
--   Waffenkunde-Steine über ihrem Cap als "beste" empfohlen.
--   Ist der Bonus für die Klasse wertlos (Gewicht ~0, z.B. Ausweichen
--   auf einem reinen DPS-Item), verliert MATCH und wir empfehlen den
--   stärkeren Universalstein — genau das gewünschte Verhalten.
--
--   Rückgabe (Tabelle):
--     bonus       = { stat, value } | nil
--     bonusScore  = gewichteter Wert des Bonus
--     matchCost   = Wertungsverlust durchs Farb-Matchen
--     worthwhile  = bool (Bonus lohnt den Farb-Match)
--     pureId      = empfohlener Universalstein (prismatic[1])
--     pureScore   = dessen gewichtete Wertung (Bewertungs-Anker)
--------------------------------------------------

local function EvaluateSocketBonus(bonus, sockets, profile)
    local decision = { bonus = bonus, worthwhile = true }
    if not profile or not profile.bestGems or not profile.statWeights then
        return decision
    end

    local weights  = profile.statWeights
    local gemStats = WeintCodex_GemStats or {}

    local pureId = profile.bestGems.prismatic and profile.bestGems.prismatic[1]
    decision.pureId = pureId
    if not pureId then return decision end

    local pureScore = ScoreStats(gemStats[pureId], weights)
    decision.pureScore = pureScore

    -- Ohne bekannten Bonus: bisheriges (farbbasiertes) Verhalten.
    if not bonus then return decision end

    local bonusScore = (weights[bonus.stat] or 0) * bonus.value
    decision.bonusScore = bonusScore

    -- Kosten des Matchens: pro FARBIGEM Sockel die Wertungsdifferenz
    -- zwischen dem Universalstein und dem besten farblich passenden
    -- Empfehlungsstein (bestGems[Farbe][1]). Ist der passende Stein
    -- gleich gut oder besser (z.B. roter Primärstein im roten Sockel),
    -- kostet der Sockel 0 -> Matchen ist gratis.
    local matchCost = 0
    for _, socket in ipairs(sockets) do
        local color = socket.color
        if color and color ~= "meta" and color ~= "prismatic" then
            local colorList  = profile.bestGems[color]
            local colorId    = colorList and colorList[1]
            local colorScore = colorId and ScoreStats(gemStats[colorId], weights) or pureScore
            local diff = pureScore - colorScore
            if diff > 0 then matchCost = matchCost + diff end
        end
    end
    decision.matchCost  = matchCost
    decision.worthwhile = bonusScore >= matchCost
    return decision
end

--------------------------------------------------
-- LEGENDÄRE URDIAMANTEN (Wrathion-Questreihe, 5.2)
-- Diese Steine sind IMMER optimal, wenn sie zur
-- Rolle passen — sie sind besser als jeder
-- kaufbare Meta-Stein und dürfen nie als
-- "falsch" markiert werden.
--------------------------------------------------

local LEGENDARY_META = {
    [95346] = { MELEE = true, RANGED = true, TANK = true },  -- Kapazitiver Urdiamant
    [95347] = { CASTER = true },                             -- Finsterer Urdiamant
    [95345] = { HEALER = true },                             -- Mutiger Urdiamant
    [95344] = { TANK = true },                               -- Unbezähmbarer Urdiamant
}

-- Gibt zurück: status, qualityPct (oder nil), unbekannt (bool)
-- decision (optional): Ergebnis von EvaluateSocketBonus. Lohnt sich das
-- Matchen für dieses Item nicht, ist der reine Primärstein (prismatic)
-- das Ziel: ein solcher Off-Color-Stein zählt dann als OPTIMAL (statt
-- fälschlich "falsch"), ein Farb-Stein nur als "ok" (Empfehlung: umsockeln).
local function EvaluateGem(gemId, socketColor, profile, decision)
    if not gemId then return "missing", nil, false end

    local gemData  = WeintCodex_Gems and WeintCodex_Gems[gemId]
    local colorKey = (gemData and gemData.color) or socketColor
    local isMeta   = (colorKey == "meta") or (socketColor == "meta")

    -- Legendärer Meta-Stein: rollengerecht => optimal,
    -- andere Rolle => nur Hinweis (nie "falsch")
    local leg = LEGENDARY_META[gemId]
    if leg then
        if not profile or not profile.role or leg[profile.role] then
            return "optimal", 100, false
        end
        return "ok", nil, false
    end

    -- Sockelbonus lohnt sich für dieses Item nicht: der kuratierte
    -- Universalstein ist das Ziel. Bewertung erfolgt gegen dessen Wertung,
    -- damit ein starker Off-Color-Stein OPTIMAL zählt (statt fälschlich
    -- "falsch") und ein schwächerer Farb-Stein (nur wegen des geringen
    -- Bonus) "ok" wird.
    local ignoreBonus = decision and decision.worthwhile == false and not isMeta
    if ignoreBonus and decision.pureScore and decision.pureScore > 0 then
        local weights = profile and profile.statWeights
        local myStats = WeintCodex_GemStats and WeintCodex_GemStats[gemId]
        if weights and myStats then
            local pct = math.floor((ScoreStats(myStats, weights) / decision.pureScore) * 100 + 0.5)
            if pct >= 90 then return "optimal", pct, false end
            if pct >= 65 then return "ok", pct, false end
            return "wrong", pct, false
        end
        -- Ohne Bewertungsgrundlage: nicht abwerten.
        return "ok", nil, true
    end

    local bestList = profile and profile.bestGems and colorKey
                     and profile.bestGems[colorKey]

    if IsInList(gemId, bestList) then
        return "optimal", 100, false
    end

    local weights = profile and profile.statWeights
    local myStats = WeintCodex_GemStats and WeintCodex_GemStats[gemId]
    if weights and myStats and bestList then
        local myScore = ScoreStats(myStats, weights)
        local best = 0
        for _, bid in ipairs(bestList) do
            local s = ScoreStats(WeintCodex_GemStats[bid], weights)
            if s > best then best = s end
        end
        if best > 0 then
            local pct = math.floor((myScore / best) * 100 + 0.5)
            if pct >= 90 then return "optimal", pct, false end
            if pct >= 65 then return "ok", pct, false end
            -- Meta-Steine nie als "falsch" werten: ihre Proc-Effekte
            -- (z.B. Mana-Ersparnis, Schadensreduktion) stecken nicht
            -- in den reinen Statwerten.
            if isMeta then return "ok", pct, false end
            return "wrong", pct, false
        end
    end

    -- Stein unbekannt oder keine Bewertungsgrundlage
    return "ok", nil, true
end

-- Schulter-Inschriften: Inschriftler tragen die selbst erstellbare
-- "Geheime Inschrift ..." (stärker als die kaufbare "Große Inschrift ...").
-- Deren Enchant-IDs sind nicht hinterlegt — wir erkennen sie über das
-- Schlüsselwort im Tooltip-Namen: gleiche Tierart wie die Empfehlung
-- (z.B. "Ochsenhorn") => optimal.
local INSCRIPTION_KEYWORDS = {
    "tigerzahn", "tigerfang", "kranichschwinge", "ochsenhorn", "tigerklaue",
}

local function EvaluateEnchant(enchId, slotKey, profile, tooltipName)
    local bestList = profile and profile.bestEnchants
                     and profile.bestEnchants[slotKey]
    if not bestList then
        return "neutral", nil
    end
    if not enchId then return "missing", bestList end
    if IsInList(enchId, bestList) then return "optimal", bestList end

    -- Anzeigename der aktuellen Verzauberung: bevorzugt der
    -- offizielle Tooltip-Name, sonst unser DB-Name. Damit wird
    -- nie etwas empfohlen, das (dem Namen nach) schon drauf ist —
    -- auch wenn die ID in unserer Datenbank falsch zugeordnet ist.
    local currentName = tooltipName
    if not currentName then
        local cdb = WeintCodex_Enchants and WeintCodex_Enchants[enchId]
        currentName = cdb and cdb.name
    end

    if currentName then
        local tn = currentName:lower()

        -- Namensgleichheit mit einer Empfehlung => optimal
        for _, bid in ipairs(bestList) do
            local db = WeintCodex_Enchants and WeintCodex_Enchants[bid]
            if db and db.name and tn == db.name:lower() then
                return "optimal", bestList
            end
        end

        -- Inschriftler-Schultern: Schlüsselwort-Abgleich
        if slotKey == "Schultern" then
            for _, kw in ipairs(INSCRIPTION_KEYWORDS) do
                if tn:find(kw, 1, true) then
                    for _, bid in ipairs(bestList) do
                        local db = WeintCodex_Enchants and WeintCodex_Enchants[bid]
                        if db and db.name and db.name:lower():find(kw, 1, true) then
                            return "optimal", bestList
                        end
                    end
                end
            end
        end
    end

    return "ok", bestList
end

--------------------------------------------------
-- SCAN-ENGINE
-- Ein Durchlauf liefert alle Daten für alle Seiten.
--------------------------------------------------

local function ScanCharacter()
    local profile, profileKey, tankStyle, specDisplay = GetCurrentSpecProfile()
    local capStates = BuildCapStates(profile)

    local scan = {
        profile     = profile,
        profileKey  = profileKey,
        tankStyle   = tankStyle,
        specDisplay = specDisplay,
        caps        = capStates,
        enchants    = { rows = {} },
        gems        = { rows = {} },
        issues      = {},
    }

    --------------------------------------------------
    -- 1) Rohdaten sammeln
    --------------------------------------------------

    for _, slotDef in ipairs(EQUIP_SLOTS) do
        local link = GetInventoryItemLink("player", slotDef.id)
        if link then
            local itemName = link:match("|h%[(.-)%]|h")
            local enchId = ParseItemLink(link)

            -- Verzauberung
            if slotDef.enchSlot then
                local skip = slotDef.nurWaffe and not IsWeaponLink(link)
                if not skip then
                    -- Offizieller deutscher Name vom Tooltip (landet im
                    -- Cache und dient dem Namensabgleich bei der Bewertung)
                    local tooltipName = GetEquippedEnchantText(slotDef.id, enchId, link)
                    local status, bestList = EvaluateEnchant(enchId, slotDef.enchSlot, profile, tooltipName)
                    scan.enchants.rows[#scan.enchants.rows + 1] = {
                        slotId    = slotDef.id,
                        slotName  = slotDef.name,
                        enchSlot  = slotDef.enchSlot,
                        itemName  = itemName,
                        enchId    = enchId,
                        status    = status,
                        bestList  = bestList,
                        recId     = bestList and bestList[1] or nil,
                    }
                end
            end

            -- Sockel
            local sockets = ScanItemSockets(link, slotDef.id)
            if #sockets > 0 then
                -- Sockelbonus des Items auslesen und pro Item einmal
                -- entscheiden, ob Farb-Matchen den Bonus wert ist.
                local bonus, bonusText = ScanSocketBonus(slotDef.id)
                local decision = EvaluateSocketBonus(bonus, sockets, profile)
                decision.bonusText = bonusText

                for _, socket in ipairs(sockets) do
                    local status, qualityPct, unknown =
                        EvaluateGem(socket.gemId, socket.color, profile, decision)
                    scan.gems.rows[#scan.gems.rows + 1] = {
                        slotId     = slotDef.id,
                        slotName   = slotDef.name,
                        itemName   = itemName,
                        socket     = socket,
                        gemId      = socket.gemId,
                        status     = status,
                        qualityPct = qualityPct,
                        unknown    = unknown,
                        decision   = decision,
                    }
                end
            end
        end
    end

    --------------------------------------------------
    -- 2) Overcap-Pass: Steine/Verzauberungen markieren,
    --    die einen bereits gecappten Stat liefern und
    --    deren kompletter Wert verschwendet ist.
    --    (z.B. weitere Treffer-Steine trotz 15% Cap)
    --------------------------------------------------

    local overStats = {}
    for _, cs in ipairs(capStates) do
        if cs.overPct > 0.25 then
            overStats[cs.stat] = true

            local budget = cs.overRating
            local cands = {}

            for _, row in ipairs(scan.gems.rows) do
                local st = row.gemId and WeintCodex_GemStats
                           and WeintCodex_GemStats[row.gemId]
                local v = st and st[cs.stat]
                if v and v > 0 and row.status ~= "overcap" then
                    cands[#cands + 1] = { row = row, value = v, art = "Stein" }
                end
            end
            for _, row in ipairs(scan.enchants.rows) do
                local db = row.enchId and WeintCodex_Enchants
                           and WeintCodex_Enchants[row.enchId]
                local v = db and db.stats and db.stats[cs.stat]
                if v and v > 0 and row.status ~= "overcap" then
                    cands[#cands + 1] = { row = row, value = v, art = "Verzauberung" }
                end
            end

            table.sort(cands, function(a, b) return a.value > b.value end)

            -- Nur markieren, wenn der Stein/die Verzauberung KOMPLETT
            -- verschwendet ist (nach Entfernen wäre man immer noch am Cap).
            for _, cand in ipairs(cands) do
                if cand.value <= budget then
                    cand.row.status  = "overcap"
                    cand.row.capStat = cs.stat
                    budget = budget - cand.value
                    cs.wasted[#cs.wasted + 1] = cand
                end
            end
        end
    end

    -- Empfehlungen für Sockel-Reihen setzen (Overcap-bereinigt,
    -- Sockelbonus-Entscheidung berücksichtigt)
    for _, row in ipairs(scan.gems.rows) do
        row.recId = PickGemRecommendation(row.socket.color, profile,
            next(overStats) and overStats or nil, row.decision)
    end

    --------------------------------------------------
    -- 3) Zählen & Score
    --------------------------------------------------

    local function CountRows(rows)
        local c = { optimal = 0, ok = 0, wrong = 0, overcap = 0,
                    missing = 0, neutral = 0, total = 0, points = 0 }
        for _, row in ipairs(rows) do
            c[row.status] = (c[row.status] or 0) + 1
            if row.status ~= "neutral" then
                c.total  = c.total + 1
                c.points = c.points + (STATUS_POINTS[row.status] or 0)
            end
        end
        return c
    end

    scan.enchants.counts = CountRows(scan.enchants.rows)
    scan.gems.counts     = CountRows(scan.gems.rows)

    local eC, gC = scan.enchants.counts, scan.gems.counts
    local total  = eC.total + gC.total
    local filled = total - eC.missing - gC.missing

    local score = {
        total        = 0,
        completeness = 0,
        quality      = 0,
        checks       = total,
        filled       = filled,
    }
    if total > 0 then
        score.total        = math.floor((eC.points + gC.points) / total + 0.5)
        score.completeness = math.floor((filled / total) * 100 + 0.5)
        if filled > 0 then
            score.quality = math.floor((eC.points + gC.points) / filled + 0.5)
            if score.quality > 100 then score.quality = 100 end
        end
    end
    if score.total >= 95 then      score.grade = "S"
    elseif score.total >= 85 then  score.grade = "A"
    elseif score.total >= 70 then  score.grade = "B"
    elseif score.total >= 55 then  score.grade = "C"
    elseif score.total >= 35 then  score.grade = "D"
    else                           score.grade = "F" end
    scan.score = score

    --------------------------------------------------
    -- 4) Handlungsbedarf (priorisierte Problemliste)
    --------------------------------------------------

    local issues = scan.issues

    for _, row in ipairs(scan.enchants.rows) do
        if row.status == "missing" then
            local rec = FirstResolvableName(
                row.bestList or { row.recId }, GetEnchantDisplayName)
            issues[#issues + 1] = { prio = 1, status = "missing",
                text = row.slotName .. ": Verzauberung fehlt"
                    .. (rec and (" — Empfehlung: " .. rec) or "") }
        end
    end

    for _, row in ipairs(scan.gems.rows) do
        if row.status == "missing" then
            local rec = row.recId and GetGemDisplayName(row.recId)
            local was = row.socket.buckle and "Gürtelschnalle fehlt oder Sockel leer"
                        or ((SOCKET_COLOR_LABEL[row.socket.color] or "Sockelplatz")
                            .. " ist leer")
            issues[#issues + 1] = { prio = 1, status = "missing",
                text = row.slotName .. ": " .. was
                    .. (rec and (" — Empfehlung: " .. rec) or "") }
        end
    end

    for _, cs in ipairs(capStates) do
        if cs.overPct > 0.25 and #cs.wasted > 0 then
            local totalWaste = 0
            for _, w in ipairs(cs.wasted) do totalWaste = totalWaste + w.value end
            issues[#issues + 1] = { prio = 2, status = "overcap",
                text = string.format(
                    "%s über dem Cap: %.1f%% / %.1f%% — %d Quelle(n), %d Wertung verschwendet. Umsockeln!",
                    cs.label, cs.current, cs.capPct, #cs.wasted, totalWaste) }
        elseif cs.overPct < -0.3 then
            issues[#issues + 1] = { prio = 2, status = "wrong",
                text = string.format(
                    "%s unter dem Cap: %.1f%% / %.1f%% — es fehlen ca. %d Wertung%s.",
                    cs.label, cs.current, cs.capPct, math.ceil(cs.underRating),
                    cs.spiritZaehlt and " (Willenskraft zählt mit)" or "") }
        end
    end

    for _, row in ipairs(scan.gems.rows) do
        if row.status == "wrong" then
            local rec = row.recId and GetGemDisplayName(row.recId)
            issues[#issues + 1] = { prio = 3, status = "wrong",
                text = row.slotName .. ": Falscher Stein — "
                    .. (GetGemDisplayName(row.gemId) or "?")
                    .. (rec and (" -> " .. rec) or "") }
        end
    end

    for _, row in ipairs(scan.enchants.rows) do
        if row.status == "ok" then
            local rec = row.recId and GetEnchantDisplayName(row.recId)
            issues[#issues + 1] = { prio = 4, status = "ok",
                text = row.slotName .. ": Verzauberung nicht ideal"
                    .. (rec and (" -> " .. rec) or "") }
        end
    end
    for _, row in ipairs(scan.gems.rows) do
        if row.status == "ok" and not row.unknown then
            local rec = row.recId and GetGemDisplayName(row.recId)
            issues[#issues + 1] = { prio = 4, status = "ok",
                text = row.slotName .. ": Stein nicht ideal — "
                    .. (GetGemDisplayName(row.gemId) or "?")
                    .. (rec and (" -> " .. rec) or "") }
        end
    end

    table.sort(issues, function(a, b) return a.prio < b.prio end)

    return scan
end

-- Für andere Module (z.B. Companion-Export) verfügbar machen
WeintCodex.Charakter.Scan = ScanCharacter

--------------------------------------------------
-- /wc vz — DATEN-DUMP FÜR DIE PFLEGE DER DATENBANK
-- Gibt für jedes angelegte Item Verzauberungs-ID +
-- offiziellen Client-Namen sowie alle Stein-IDs aus.
-- Damit lassen sich falsche IDs/Namen in
-- data/enchants.lua zeilengenau korrigieren.
--------------------------------------------------

function WeintCodex.Charakter.DumpEnchants()
    print("|cffC8763A[WeintCodex]|r Ausrüstungs-Dump (Zeilen bitte kopieren und melden):")
    local any = false
    for _, slotDef in ipairs(EQUIP_SLOTS) do
        local link = GetInventoryItemLink("player", slotDef.id)
        if link then
            local enchId, gems = ParseItemLink(link)
            if enchId then
                any = true
                local tt = GetEquippedEnchantText(slotDef.id, enchId, link)
                local db = WeintCodex_Enchants and WeintCodex_Enchants[enchId]
                local marker = ""
                if not tt and db then
                    -- Live-Tooltip-Scan lieferte keinen Namen — der unten
                    -- gezeigte Name stammt UNGEPRÜFT aus der DB und kann
                    -- falsch sein, auch wenn kein "(DB-Name: ...)"-Konflikt
                    -- auftaucht (es gibt ja nichts, womit man vergleichen könnte).
                    marker = "  |cffff9900(Live-Scan fehlgeschlagen — Name aus DB, ungeprüft!)|r"
                elseif not db then
                    marker = "  |cffff9900(fehlt in enchants.lua!)|r"
                elseif tt and db.name and tt:lower() ~= db.name:lower() then
                    marker = "  |cffFFBB22(DB-Name: " .. db.name .. ")|r"
                end
                print(string.format("  %s: VZ-ID %d = %s%s",
                    slotDef.name, enchId, tt or (db and db.name) or "?", marker))
            end
            for g = 1, 4 do
                if gems[g] then
                    any = true
                    print(string.format("  %s: Stein-ID %d = %s",
                        slotDef.name, gems[g], GetGemDisplayName(gems[g]) or "?"))
                end
            end
        end
    end
    if not any then
        print("  |cffaaaaaaKeine Verzauberungen/Steine gefunden.|r")
    end
end

--------------------------------------------------
-- CONTENT-PANEL & SEITENVERWALTUNG
--------------------------------------------------

local contentPanel = nil
local function GetContentPanel()
    contentPanel = contentPanel or WeintCodex.ContentPanel
    return contentPanel
end

local activeCharakterView = nil

-- Vorwärtsdeklaration der Seiten (werden unten definiert)
local ShowUebersicht, ShowEnchants, ShowGems, ShowWerteverteilung,
      ShowPriorisierung, ShowTwinkverwaltung

local function RefreshActiveCharakterView()
    ClearCharakterCache()
    if activeCharakterView == "uebersicht" then
        ShowUebersicht()
    elseif activeCharakterView == "enchants" then
        ShowEnchants()
    elseif activeCharakterView == "gems" then
        ShowGems()
    elseif activeCharakterView == "werte" then
        ShowWerteverteilung()
    end
end

-- Bei Ausrüstungswechsel automatisch neu scannen (entprellt)
local equipWatcher = CreateFrame("Frame")
equipWatcher:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
equipWatcher._pending = false
equipWatcher:SetScript("OnEvent", function(self)
    if not activeCharakterView or self._pending then return end
    if C_Timer and C_Timer.After then
        self._pending = true
        C_Timer.After(0.3, function()
            self._pending = false
            if activeCharakterView then RefreshActiveCharakterView() end
        end)
    else
        RefreshActiveCharakterView()
    end
end)

-- Nachlieferung fehlender Item-Basisdaten (siehe pendingItemInfoIds oben):
-- GET_ITEM_INFO_RECEIVED feuert, sobald der Client Daten zu einer zuvor
-- ungecachten Item-ID nachgeladen hat. Betrifft uns das (Item stand in
-- pendingItemInfoIds), scannen wir die aktive Seite neu — der Live-Tooltip-
-- Scan hat dann alle Daten und liefert den echten Verzauberungsnamen statt
-- des ungeprüften DB-Fallbacks.
local itemInfoWatcher = CreateFrame("Frame")
itemInfoWatcher:RegisterEvent("GET_ITEM_INFO_RECEIVED")
itemInfoWatcher:SetScript("OnEvent", function(self, event, itemId, success)
    if itemId and pendingItemInfoIds[itemId] then
        pendingItemInfoIds[itemId] = nil
        if success and activeCharakterView then RefreshActiveCharakterView() end
    end
end)

-- Singleton-Button in der Titelleiste (bleibt ueber Unterseiten-Wechsel
-- hinweg bestehen, siehe modules/materials.lua CompanionBtn fuer das
-- gleiche Muster). WeintCodex.Navigation.ClearTitleActions() blendet ihn
-- beim Wechsel auf einen anderen Haupt-Tab aus.
-- Alle Titelleisten-Buttons dieses Moduls werden hier vorab deklariert,
-- damit sich MakeRefreshButton und ShowTwinkverwaltung (weiter unten)
-- gegenseitig ein-/ausblenden koennen, ohne separate lokale Schatten-
-- Variablen anzulegen.
local refreshBtn, refreshLbl = nil, nil
local twinkScanBtn, twinkExportBtn = nil, nil

local function MakeRefreshButton(onRefresh)
    if twinkScanBtn   then twinkScanBtn:Hide()   end
    if twinkExportBtn then twinkExportBtn:Hide() end

    if not refreshBtn then
        refreshBtn = WeintCodex.CreateCard(WeintCodex.TitleBarActions, { width = 106, height = 30, buttonStyle = true })
        refreshBtn:SetPoint("TOPRIGHT", WeintCodex.TitleBarActions, "TOPRIGHT", 0, -11)

        refreshLbl = refreshBtn:CreateFontString(nil, "OVERLAY")
        refreshLbl:SetAllPoints(refreshBtn)
        refreshLbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        refreshLbl:SetJustifyH("CENTER")
        refreshLbl:SetText("Aktualisieren")
        refreshLbl:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])

        refreshBtn:SetScript("OnEnter", function(self) self:SetSurface("surface3") end)
        refreshBtn:SetScript("OnLeave", function(self) self:SetSurface("surface2") end)
    end

    refreshBtn:SetScript("OnClick", function()
        ClearCharakterCache()
        if onRefresh then onRefresh() end
    end)
    refreshBtn:Show()
    return refreshBtn
end

--------------------------------------------------
-- GEMEINSAME UI-BAUSTEINE
--------------------------------------------------

-- Bewertungs-Zusammenfassung im Inspector (Vollstaendig/Qualitaet + Status-
-- Verteilung). Wird von allen pruefungsbasierten Unterseiten genutzt.
local function ShowScoreInspector(counts, extraBlocks)
    local blocks = {}

    if counts and counts.total and counts.total > 0 then
        local filled  = counts.total - counts.missing
        local vollPct = math.floor((filled / counts.total) * 100)
        local qualPct = (filled > 0) and math.floor(counts.points / filled + 0.5) or 0
        if qualPct > 100 then qualPct = 100 end

        local legendRows = {}
        local function AddLegend(status, n)
            if n and n > 0 then
                local info = STATUS[status]
                local vc = "textDim"
                if status == "optimal" then vc = "success"
                elseif status == "ok" then vc = "warning"
                elseif status == "overcap" then vc = "violet"
                elseif status == "wrong" or status == "missing" then vc = "danger" end
                legendRows[#legendRows + 1] = { label = info.label, value = tostring(n), valueColor = vc }
            end
        end
        AddLegend("optimal", counts.optimal)
        AddLegend("ok",      counts.ok)
        AddLegend("overcap", counts.overcap)
        AddLegend("wrong",   counts.wrong)
        AddLegend("missing", counts.missing)

        blocks[#blocks + 1] = { type = "header", text = "Bewertung" }
        blocks[#blocks + 1] = { type = "rows", rows = {
            { label = "Vollständig", value = vollPct .. "%", valueColor = (counts.missing > 0) and "danger" or "success" },
            { label = "Qualität",    value = qualPct .. "%", valueColor = "purple" },
        }}
        if #legendRows > 0 then
            blocks[#blocks + 1] = { type = "divider" }
            blocks[#blocks + 1] = { type = "header", text = "Status-Verteilung" }
            blocks[#blocks + 1] = { type = "rows", rows = legendRows }
        end
    end

    if extraBlocks then
        if #blocks > 0 then blocks[#blocks + 1] = { type = "divider" } end
        for _, b in ipairs(extraBlocks) do blocks[#blocks + 1] = b end
    end

    if #blocks == 0 then
        blocks[1] = { type = "header", text = "Bewertung" }
        blocks[2] = { type = "rows", rows = { { label = "Keine Prüfdaten", valueColor = "textFaint" } } }
    end

    WeintCodex.Navigation.SetInspector(blocks)
end

local function DrawPageHeader(frame, titleText, scan, onRefresh)
    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\MORPHEUS.TTF", 17, "")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -14)
    title:SetText("|cffC8763A" .. titleText .. "|r")

    MakeRefreshButton(onRefresh)
    WeintCodex.SetBreadcrumb("Charakter", titleText)

    local specInfo = frame:CreateFontString(nil, "OVERLAY")
    specInfo:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    specInfo:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    if scan.profileKey then
        local styleHint = scan.tankStyle
            and (" |cffC8763A[" .. (scan.tankStyle == "OFF" and "Offensiv" or "Defensiv") .. "]|r")
            or ""
        local customHint = (scan.profile and scan.profile.customWeights)
            and "  |cffFFBB22[eigene Gewichtung aktiv]|r" or ""
        local profWarn = (not scan.profile) and "  |cffff9900(kein Profil hinterlegt!)|r" or ""
        specInfo:SetText("|cff6B6259Spec: " .. (scan.specDisplay or scan.profileKey) .. styleHint .. "|r" .. customHint .. profWarn)
    else
        specInfo:SetText("|cffff9900Spec konnte nicht ermittelt werden — einloggen bzw. Spec wählen!|r")
    end

    return title
end

-- Tank-Spielstil-Umschalter; gibt genutzte Y-Höhe zurück (negativ)
local function DrawTankStyleToggle(parent, profileKey, currentStyle, onSwitch)
    if not profileKey or not TANK_SPECS[profileKey] then return 0 end

    local W = parent:GetWidth() - 32

    local bg = CreateFrame("Frame", nil, parent)
    bg:SetSize(math.max(W, 200), 28)
    bg:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -44)
    SetSolidBg(bg, C.headerBg[1], C.headerBg[2], C.headerBg[3], 0.80)
    DrawBorder(bg, C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.40, 1)

    local info = bg:CreateFontString(nil, "OVERLAY")
    info:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    info:SetPoint("LEFT", bg, "LEFT", 10, 0)
    info:SetText("|cffC8763ATank-Spielstil:|r |cff6B6259bestimmt Empfehlungen & Bewertung|r")

    local function StyleBtn(label, style, xOff)
        local isActive = (currentStyle == style)
        local btn = CreateFrame("Button", nil, bg)
        btn:SetSize(90, 20)
        btn:SetPoint("RIGHT", bg, "RIGHT", xOff, 0)
        local bgCol = isActive and C.purple or C.surface2
        local brCol = isActive and C.purple or C.hairline
        SetSolidBg(btn, bgCol[1], bgCol[2], bgCol[3], isActive and 0.35 or 0.95)
        DrawBorder(btn, brCol[1], brCol[2], brCol[3], 0.85, 1)
        local lbl = btn:CreateFontString(nil, "OVERLAY")
        lbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        lbl:SetAllPoints(btn)
        lbl:SetJustifyH("CENTER")
        lbl:SetJustifyV("MIDDLE")
        lbl:SetText(isActive and ("|cffC8763A" .. label .. "|r") or ("|cff6B6259" .. label .. "|r"))
        btn:SetScript("OnClick", function()
            SetTankStyle(profileKey, style)
            if onSwitch then onSwitch() end
        end)
        return btn
    end

    StyleBtn("Offensiv", "OFF", -4)
    StyleBtn("Defensiv", "DEF", -98)

    return -36
end

--------------------------------------------------
-- SEITE: VERZAUBERUNGEN
--------------------------------------------------

-- Kuerzt Text auf eine Zeile mit "…", damit lange Item-/Slotnamen nicht
-- ueber ihre Spalte hinaus wachsen (WoW FontStrings wuerden sonst
-- standardmaessig auf 2+ Zeilen umbrechen und mit Nachbarzeilen/-spalten
-- kollidieren). fs muss bereits SetWordWrap(false) gesetzt haben.
local function TruncateOneLine(fs, text, maxWidth)
    fs:SetText(text)
    if fs:GetStringWidth() <= maxWidth then
        return text
    end
    while #text > 1 and fs:GetStringWidth() > maxWidth do
        text = text:sub(1, #text - 1)
        fs:SetText(text .. "…")
    end
    return text .. "…"
end

local enchantFrame = nil

function ShowEnchants()
    activeCharakterView = "enchants"
    local cp = GetContentPanel()
    if not cp then return end
    for _, child in pairs({ cp:GetChildren() }) do child:Hide() end

    if enchantFrame then enchantFrame:Hide(); enchantFrame = nil end
    enchantFrame = CreateFrame("Frame", nil, cp)
    enchantFrame:SetAllPoints(cp)
    enchantFrame:Show()

    local scan = ScanCharacter()
    DrawPageHeader(enchantFrame, "Verzauberungen", scan, ShowEnchants)
    local toggleOffset = DrawTankStyleToggle(enchantFrame, scan.profileKey, scan.tankStyle, ShowEnchants)

    -- Spalten-Header
    local headerY = -52 + toggleOffset
    local function MakeHeader(text, x, w)
        local h = enchantFrame:CreateFontString(nil, "OVERLAY")
        h:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        h:SetPoint("TOPLEFT", enchantFrame, "TOPLEFT", x, headerY)
        h:SetWidth(w)
        h:SetJustifyH("LEFT")
        h:SetText("|cff6B6259" .. text .. "|r")
    end
    MakeHeader("STATUS",                 24, 70)
    MakeHeader("SLOT / GEGENSTAND",      94, 140)
    MakeHeader("AKTUELLE VERZAUBERUNG", 240, 230)
    MakeHeader("EMPFEHLUNG",            478, 220)

    local divider = enchantFrame:CreateTexture(nil, "OVERLAY")
    divider:SetPoint("TOPLEFT",  enchantFrame, "TOPLEFT",  16, headerY - 14)
    divider:SetPoint("TOPRIGHT", enchantFrame, "TOPRIGHT", -16, headerY - 14)
    divider:SetHeight(1)
    divider:SetColorTexture(C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.40)

    local sf, inner = CreateScrollArea(enchantFrame, 14, headerY - 18, 20, 400)
    sf:ClearAllPoints()
    sf:SetPoint("TOPLEFT",     enchantFrame, "TOPLEFT",     14, headerY - 18)
    sf:SetPoint("BOTTOMRIGHT", enchantFrame, "BOTTOMRIGHT", -26, 24)
    inner:SetWidth(sf:GetWidth() - 22)

    local yOff = 0

    for _, row in ipairs(scan.enchants.rows) do
        local info = STATUS[row.status] or STATUS.neutral
        local rowH = 40

        local rf = CreateFrame("Frame", nil, inner)
        rf:SetSize(inner:GetWidth() - 4, rowH)
        rf:SetPoint("TOPLEFT", inner, "TOPLEFT", 2, yOff)
        SetSolidBg(rf, C.surface2[1], C.surface2[2], C.surface2[3], 0.68)

        local stripe = rf:CreateTexture(nil, "BORDER")
        stripe:SetSize(3, rowH)
        stripe:SetPoint("LEFT", rf, "LEFT", 0, 0)
        stripe:SetColorTexture(info.color[1], info.color[2], info.color[3], 0.80)

        AttachStatusIcon(rf, row.status, 10, 0)

        local stLbl = rf:CreateFontString(nil, "OVERLAY")
        stLbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        stLbl:SetPoint("LEFT", rf, "LEFT", 30, 0)
        stLbl:SetWidth(60)
        stLbl:SetJustifyH("LEFT")
        stLbl:SetText(StatusColorStr(row.status) .. info.label .. "|r")

        local slotLbl = rf:CreateFontString(nil, "OVERLAY")
        slotLbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        slotLbl:SetPoint("TOPLEFT", rf, "TOPLEFT", 92, -6)
        slotLbl:SetWidth(140)
        slotLbl:SetWordWrap(false)
        slotLbl:SetJustifyH("LEFT")
        slotLbl:SetText(TruncateOneLine(slotLbl, row.slotName, 138))
        slotLbl:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])

        if row.itemName then
            local itemLbl = rf:CreateFontString(nil, "OVERLAY")
            itemLbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
            itemLbl:SetPoint("BOTTOMLEFT", rf, "BOTTOMLEFT", 92, 5)
            itemLbl:SetWordWrap(false)
            itemLbl:SetJustifyH("LEFT")
            -- Einzeilig kuerzen statt umbrechen zu lassen, sonst kollidiert
            -- eine 2. Zeile mit dem Slotnamen darueber (siehe TruncateOneLine).
            local shortName = TruncateOneLine(itemLbl, row.itemName, 138)
            itemLbl:SetText("|cff4A423A" .. shortName .. "|r")
        end

        local curLbl = rf:CreateFontString(nil, "OVERLAY")
        curLbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        curLbl:SetPoint("LEFT", rf, "LEFT", 238, 0)
        curLbl:SetWidth(232)
        curLbl:SetJustifyH("LEFT")
        if row.status == "missing" then
            curLbl:SetText("|cffff5555— Keine Verzauberung! —|r")
        elseif row.status == "neutral" and not row.enchId then
            curLbl:SetText("|cff6B6259— (keine Empfehlung für diese Spec)|r")
        else
            local n = GetEnchantDisplayName(row.enchId) or "—"
            if row.status == "overcap" then
                curLbl:SetText(n .. " |cffcc88ff(Stat über Cap!)|r")
            else
                curLbl:SetText(n)
            end
            curLbl:SetTextColor(info.color[1], info.color[2], info.color[3])
        end

        if row.recId and row.status ~= "optimal" and row.status ~= "neutral" then
            -- Erste auflösbare Empfehlung wählen, die NICHT namensgleich
            -- mit der bereits angelegten Verzauberung ist. Unauflösbare
            -- IDs ("Unbekannt (ID …)") werden übersprungen.
            local curName = row.enchId and GetEnchantDisplayName(row.enchId)
            local recName = FirstResolvableName(
                row.bestList or { row.recId }, GetEnchantDisplayName, curName)
            if recName then
                local recLbl = rf:CreateFontString(nil, "OVERLAY")
                recLbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
                recLbl:SetPoint("LEFT", rf, "LEFT", 476, 0)
                recLbl:SetWidth(220)
                recLbl:SetJustifyH("LEFT")
                recLbl:SetText("|cffC8763A> " .. recName .. "|r")
            end
        end

        yOff = yOff - (rowH + 2)
    end

    if #scan.enchants.rows == 0 then
        local noSlot = inner:CreateFontString(nil, "OVERLAY")
        noSlot:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        noSlot:SetPoint("TOPLEFT", inner, "TOPLEFT", 10, -10)
        noSlot:SetText("|cffaaaaaa Keine Items angelegt (Charakter einloggen!).|r")
    end

    inner:SetHeight(math.max(20, -yOff + 10))
    ShowScoreInspector(scan.enchants.counts)
end

--------------------------------------------------
-- SEITE: SOCKEL & EDELSTEINE
--------------------------------------------------

local gemFrame = nil

function ShowGems()
    activeCharakterView = "gems"
    local cp = GetContentPanel()
    if not cp then return end
    for _, child in pairs({ cp:GetChildren() }) do child:Hide() end

    if gemFrame then gemFrame:Hide(); gemFrame = nil end
    gemFrame = CreateFrame("Frame", nil, cp)
    gemFrame:SetAllPoints(cp)
    gemFrame:Show()

    local scan = ScanCharacter()
    DrawPageHeader(gemFrame, "Sockel & Edelsteine", scan, ShowGems)

    if scan.profile and scan.profile.gemNote then
        local noteBox = gemFrame:CreateFontString(nil, "OVERLAY")
        noteBox:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        noteBox:SetPoint("TOPRIGHT", gemFrame, "TOPRIGHT", -140, -14)
        noteBox:SetWidth(300)
        noteBox:SetJustifyH("RIGHT")
        noteBox:SetText("|cff6B6259" .. scan.profile.gemNote .. "|r")
    end

    local toggleOffset = DrawTankStyleToggle(gemFrame, scan.profileKey, scan.tankStyle, ShowGems)

    local headerY = -52 + toggleOffset
    local function MakeHeader(text, x, w)
        local h = gemFrame:CreateFontString(nil, "OVERLAY")
        h:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        h:SetPoint("TOPLEFT", gemFrame, "TOPLEFT", x, headerY)
        h:SetWidth(w)
        h:SetJustifyH("LEFT")
        h:SetText("|cff6B6259" .. text .. "|r")
    end
    MakeHeader("STATUS",             24, 80)
    MakeHeader("SOCKELPLATZ (FARBE)", 108, 122)
    MakeHeader("EINGESETZTER STEIN", 234, 230)
    MakeHeader("EMPFEHLUNG",         478, 220)

    local divider = gemFrame:CreateTexture(nil, "OVERLAY")
    divider:SetPoint("TOPLEFT",  gemFrame, "TOPLEFT",  16, headerY - 14)
    divider:SetPoint("TOPRIGHT", gemFrame, "TOPRIGHT", -16, headerY - 14)
    divider:SetHeight(1)
    divider:SetColorTexture(C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.40)

    local sf, inner = CreateScrollArea(gemFrame, 14, headerY - 18, 20, 400)
    sf:ClearAllPoints()
    sf:SetPoint("TOPLEFT",     gemFrame, "TOPLEFT",     14, headerY - 18)
    sf:SetPoint("BOTTOMRIGHT", gemFrame, "BOTTOMRIGHT", -26, 24)
    inner:SetWidth(sf:GetWidth() - 22)

    local yOff = 0
    local lastSlotId = nil

    for _, row in ipairs(scan.gems.rows) do
        -- Item-Gruppenkopf
        if row.slotId ~= lastSlotId then
            lastSlotId = row.slotId
            local slotHeader = inner:CreateFontString(nil, "OVERLAY")
            slotHeader:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
            slotHeader:SetPoint("TOPLEFT", inner, "TOPLEFT", 6, yOff - 4)
            slotHeader:SetText("|cffC8763A" .. row.slotName .. "|r"
                .. (row.itemName and ("  |cff4A423A" .. row.itemName .. "|r") or ""))
            yOff = yOff - 20

            -- Sockelbonus + Entscheidung (genutzt / ignoriert)
            local dec = row.decision
            if dec and dec.bonus and dec.bonusText then
                local used = (dec.worthwhile ~= false)
                local verdict = used
                    and "|cff22C55Egenutzt (Farbe matchen)|r"
                    or  "|cffFFBB22ignoriert — reiner Primärstein stärker|r"
                local bonusLine = inner:CreateFontString(nil, "OVERLAY")
                bonusLine:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
                bonusLine:SetPoint("TOPLEFT", inner, "TOPLEFT", 16, yOff - 1)
                bonusLine:SetText("|cff6B6259Sockelbonus: " .. dec.bonusText
                    .. " — " .. verdict)
                yOff = yOff - 15
            end
        end

        local info = STATUS[row.status] or STATUS.neutral
        local rowH = 30

        local rf = CreateFrame("Frame", nil, inner)
        rf:SetSize(inner:GetWidth() - 4, rowH)
        rf:SetPoint("TOPLEFT", inner, "TOPLEFT", 2, yOff)
        SetSolidBg(rf, C.surface2[1], C.surface2[2], C.surface2[3], 0.60)

        local stripe = rf:CreateTexture(nil, "BORDER")
        stripe:SetSize(3, rowH)
        stripe:SetPoint("LEFT", rf, "LEFT", 0, 0)
        stripe:SetColorTexture(info.color[1], info.color[2], info.color[3], 0.80)

        -- Sockelfarbe als Punkt
        local dc = SOCKET_DOT_COLOR[row.socket.color] or { 0.55, 0.55, 0.55 }
        local dot = rf:CreateTexture(nil, "OVERLAY")
        dot:SetSize(10, 10)
        dot:SetPoint("LEFT", rf, "LEFT", 8, 0)
        dot:SetColorTexture(dc[1], dc[2], dc[3], 0.90)

        AttachStatusIcon(rf, row.status, 22, 0)

        local stLbl = rf:CreateFontString(nil, "OVERLAY")
        stLbl:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
        stLbl:SetPoint("LEFT", rf, "LEFT", 42, 0)
        stLbl:SetWidth(62)
        stLbl:SetJustifyH("LEFT")
        stLbl:SetText(StatusColorStr(row.status) .. info.label .. "|r")

        local sockName
        if row.socket.buckle then
            sockName = "Gürtelschnalle"
        elseif row.socket.extra then
            sockName = "Zusatzsockel"
        else
            sockName = (SOCKET_COLOR_LABEL[row.socket.color] or "?") .. " #" .. row.socket.index
        end
        local lbl = rf:CreateFontString(nil, "OVERLAY")
        lbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        lbl:SetPoint("LEFT", rf, "LEFT", 106, 0)
        lbl:SetWidth(120)
        lbl:SetJustifyH("LEFT")
        lbl:SetText(sockName)
        lbl:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])

        local curLbl = rf:CreateFontString(nil, "OVERLAY")
        curLbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        curLbl:SetPoint("LEFT", rf, "LEFT", 232, 0)
        curLbl:SetWidth(232)
        curLbl:SetJustifyH("LEFT")
        if row.status == "missing" then
            curLbl:SetText(row.socket.buckle
                and "|cffff5555— Schnalle fehlt / Sockel leer! —|r"
                or  "|cffff5555— Leerer Sockel! —|r")
        else
            local n = GetGemDisplayName(row.gemId) or "?"
            local suffix = ""
            if row.status == "overcap" then
                suffix = " |cffcc88ff(über Cap!)|r"
            elseif row.qualityPct and row.qualityPct < 100 then
                suffix = " |cff888888(" .. row.qualityPct .. "%)|r"
            elseif row.unknown then
                suffix = " |cff888888(unbekannt)|r"
            end
            curLbl:SetText(n .. suffix)
            curLbl:SetTextColor(info.color[1], info.color[2], info.color[3])
        end

        if row.recId and row.status ~= "optimal" then
            -- Kaputte/unauflösbare Empfehlungs-ID nicht anzeigen und nichts
            -- empfehlen, das namensgleich schon eingesetzt ist.
            local recName = GetGemDisplayName(row.recId)
            local curName = row.gemId and GetGemDisplayName(row.gemId)
            if recName and not recName:find("Unbekannt", 1, true)
               and not (curName and recName:lower() == curName:lower()) then
                local recLbl = rf:CreateFontString(nil, "OVERLAY")
                recLbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
                recLbl:SetPoint("LEFT", rf, "LEFT", 476, 0)
                recLbl:SetWidth(220)
                recLbl:SetJustifyH("LEFT")
                recLbl:SetText("|cffC8763A> " .. recName .. "|r")
            end
        end

        yOff = yOff - (rowH + 2)
    end

    if #scan.gems.rows == 0 then
        local noSlot = inner:CreateFontString(nil, "OVERLAY")
        noSlot:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        noSlot:SetPoint("TOPLEFT", inner, "TOPLEFT", 10, -10)
        noSlot:SetText("|cffaaaaaa Keine Sockel gefunden (Charakter einloggen!).|r")
    end

    inner:SetHeight(math.max(20, -yOff + 10))
    ShowScoreInspector(scan.gems.counts)

    -- Klarstellung: Farbangaben beziehen sich auf den Sockelplatz
    local colorHint = gemFrame:CreateFontString(nil, "OVERLAY")
    colorHint:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    colorHint:SetPoint("BOTTOMLEFT", gemFrame, "BOTTOMLEFT", 16, 20)
    colorHint:SetText("|cff6B6259Farbpunkt & Name = Farbe des SOCKELPLATZES im Item, nicht des Steins. Andersfarbige Steine (z.B. Lila in Blau) können optimal sein.|r")
end

--------------------------------------------------
-- CAP-BALKEN (für Übersicht & Werteverteilung)
-- Gibt genutzte Höhe zurück.
--------------------------------------------------

local function DrawCapBar(parent, x, y, w, cs)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetWidth(w)
    label:SetJustifyH("LEFT")

    local status, statusText
    if cs.overPct > 0.25 then
        status = "overcap"
        local waste = 0
        for _, wEntry in ipairs(cs.wasted) do waste = waste + wEntry.value end
        statusText = (#cs.wasted > 0)
            and string.format("|cffcc88ff%d Wertung verschwendet!|r", waste)
            or  "|cffcc88ffleicht über Cap|r"
    elseif cs.overPct < -0.3 then
        status = "missing"
        statusText = string.format("|cffff5555~%d Wertung fehlt|r", math.ceil(cs.underRating))
    else
        status = "optimal"
        statusText = "|cff22C55Eam Cap|r"
    end

    label:SetText(string.format("%s%s|r  |cffddddff%.1f%% / %.1f%%|r  %s",
        StatusColorStr(status), cs.label, cs.current, cs.capPct, statusText))

    -- Balken
    local barBg = parent:CreateTexture(nil, "ARTWORK")
    barBg:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - 13)
    barBg:SetSize(w, 7)
    barBg:SetColorTexture(C.surface3[1], C.surface3[2], C.surface3[3], 0.90)

    local frac = cs.current / cs.capPct
    if frac > 1 then frac = 1 end
    if frac < 0 then frac = 0 end
    if frac > 0.01 then
        local col = STATUS[status].color
        local bar = parent:CreateTexture(nil, "OVERLAY")
        bar:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - 13)
        bar:SetSize(math.max(2, w * frac), 7)
        bar:SetColorTexture(col[1], col[2], col[3], 0.85)
    end

    return 26
end

--------------------------------------------------
-- Stat-Summen der Ausrüstung (gemeinsam genutzt von Übersicht &
-- Werteverteilung)
--------------------------------------------------

local STAT_LABELS = {
    ["ITEM_MOD_STRENGTH_SHORT"]         = "Stärke",
    ["ITEM_MOD_AGILITY_SHORT"]          = "Beweglichkeit",
    ["ITEM_MOD_INTELLECT_SHORT"]        = "Intelligenz",
    ["ITEM_MOD_STAMINA_SHORT"]          = "Ausdauer",
    ["ITEM_MOD_SPIRIT_SHORT"]           = "Willenskraft",
    ["ITEM_MOD_CRIT_RATING_SHORT"]      = "Kritische Trefferwertung",
    ["ITEM_MOD_HASTE_RATING_SHORT"]     = "Tempowertung",
    ["ITEM_MOD_MASTERY_RATING_SHORT"]   = "Meisterschaft",
    ["ITEM_MOD_HIT_RATING_SHORT"]       = "Trefferwertung",
    ["ITEM_MOD_EXPERTISE_RATING_SHORT"] = "Waffenkundewertung",
    ["ITEM_MOD_DODGE_RATING_SHORT"]     = "Ausweichen",
    ["ITEM_MOD_PARRY_RATING_SHORT"]     = "Parierchance",
    ["RESISTANCE0_NAME"]                = "Rüstung",
}

local STAT_ORDER = {
    "ITEM_MOD_STRENGTH_SHORT",
    "ITEM_MOD_AGILITY_SHORT",
    "ITEM_MOD_INTELLECT_SHORT",
    "ITEM_MOD_STAMINA_SHORT",
    "ITEM_MOD_SPIRIT_SHORT",
    "ITEM_MOD_HIT_RATING_SHORT",
    "ITEM_MOD_EXPERTISE_RATING_SHORT",
    "ITEM_MOD_CRIT_RATING_SHORT",
    "ITEM_MOD_HASTE_RATING_SHORT",
    "ITEM_MOD_MASTERY_RATING_SHORT",
    "ITEM_MOD_DODGE_RATING_SHORT",
    "ITEM_MOD_PARRY_RATING_SHORT",
    "RESISTANCE0_NAME",
}

local function CollectEquippedStats()
    local totals = {}
    for _, slotDef in ipairs(EQUIP_SLOTS) do
        local link = GetInventoryItemLink("player", slotDef.id)
        if link and GetItemStatsCompat then
            local stats = GetItemStatsCompat(link)
            if stats then
                for key, value in pairs(stats) do
                    if type(value) == "number" and value > 0 and STAT_LABELS[key] then
                        totals[key] = (totals[key] or 0) + value
                    end
                end
            end
        end
    end
    return totals
end

--------------------------------------------------
-- SEITE: ÜBERSICHT
--------------------------------------------------

local uebersichtFrame = nil

local UEBERSICHT_W = 560

function ShowUebersicht()
    activeCharakterView = "uebersicht"
    local cp = GetContentPanel()
    if not cp then return end
    for _, child in pairs({ cp:GetChildren() }) do child:Hide() end

    if uebersichtFrame then uebersichtFrame:Hide(); uebersichtFrame = nil end
    uebersichtFrame = CreateFrame("Frame", nil, cp)
    uebersichtFrame:SetAllPoints(cp)

    MakeRefreshButton(ShowUebersicht)
    WeintCodex.SetBreadcrumb("Charakter", "Übersicht")

    local scan  = ScanCharacter()
    local score = scan.score

    local body = CreateFrame("ScrollFrame", nil, uebersichtFrame, "UIPanelScrollFrameTemplate")
    body:SetPoint("TOPLEFT",     uebersichtFrame, "TOPLEFT",     0, 0)
    body:SetPoint("BOTTOMRIGHT", uebersichtFrame, "BOTTOMRIGHT", -26, 4)

    local bc = CreateFrame("Frame", nil, body)
    bc:SetWidth(UEBERSICHT_W)
    bc:SetHeight(1)
    body:SetScrollChild(bc)

    -- =============================================
    -- HEADER: Portrait + Eyebrow/H1/Subtitle + Score
    -- =============================================
    local portrait = CreateFrame("PlayerModel", nil, bc)
    portrait:SetSize(86, 86)
    portrait:SetPoint("TOPLEFT", bc, "TOPLEFT", 20, -18)
    portrait:SetUnit("player")
    SetSolidBg(portrait, C.surface1[1], C.surface1[2], C.surface1[3], 1.0)
    DrawBorder(portrait, C.border[1], C.border[2], C.border[3], C.border[4], 1)

    local eyebrow = bc:CreateFontString(nil, "OVERLAY")
    eyebrow:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    eyebrow:SetPoint("TOPLEFT", portrait, "TOPRIGHT", 16, -4)
    if scan.profileKey then
        local styleHint = scan.tankStyle
            and (" · " .. (scan.tankStyle == "OFF" and "Offensiv" or "Defensiv")) or ""
        eyebrow:SetText(WeintCodex.ColorText("textFaint", string.upper((scan.specDisplay or scan.profileKey) .. styleHint)))
    else
        eyebrow:SetText(WeintCodex.ColorText("warning", "KEIN SPEC-PROFIL GEFUNDEN"))
    end

    local h1 = bc:CreateFontString(nil, "OVERLAY")
    h1:SetFont("Fonts\\MORPHEUS.TTF", 21, "")
    h1:SetPoint("TOPLEFT", eyebrow, "BOTTOMLEFT", 0, -6)
    h1:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
    h1:SetText("Ausrüstungs-Check")

    local nIssues = 0
    for _, is in ipairs(scan.issues) do
        if is.prio <= 3 then nIssues = nIssues + 1 end
    end

    local sub = bc:CreateFontString(nil, "OVERLAY")
    sub:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    sub:SetPoint("TOPLEFT", h1, "BOTTOMLEFT", 0, -6)
    sub:SetPoint("RIGHT", bc, "RIGHT", -20, 0)
    sub:SetJustifyH("LEFT")
    if score.checks == 0 then
        sub:SetText(WeintCodex.ColorText("warning", "Keine Prüfdaten — Charakter einloggen / Spec-Profil prüfen."))
    elseif nIssues == 0 then
        sub:SetText(WeintCodex.ColorText("success", "Alles versorgt · Verzauberungen, Sockel und Caps sind sauber."))
    else
        sub:SetText(WeintCodex.ColorText("warning",
            nIssues .. " Problem" .. (nIssues == 1 and "" or "e") .. " gefunden · Details unter Handlungsbedarf."))
    end

    local gradeCol
    if score.grade == "S" or score.grade == "A" then gradeCol = C.green
    elseif score.grade == "B" or score.grade == "C" then gradeCol = C.gold
    else gradeCol = C.red end
    if score.checks == 0 then gradeCol = C.textDim end

    local scoreNum = bc:CreateFontString(nil, "OVERLAY")
    scoreNum:SetFont("Fonts\\FRIZQT__.TTF", 26, "OUTLINE")
    scoreNum:SetPoint("TOPRIGHT", bc, "TOPRIGHT", -56, -22)
    scoreNum:SetJustifyH("RIGHT")
    scoreNum:SetTextColor(gradeCol[1], gradeCol[2], gradeCol[3])
    scoreNum:SetText(score.checks > 0 and (score.total .. " / 100") or "—")

    local gradeBadge = CreateFrame("Frame", nil, bc)
    gradeBadge:SetSize(28, 24)
    gradeBadge:SetPoint("LEFT", scoreNum, "RIGHT", 10, 1)
    SetSolidBg(gradeBadge, gradeCol[1] * 0.12, gradeCol[2] * 0.12, gradeCol[3] * 0.12, 1.0)
    DrawBorder(gradeBadge, gradeCol[1], gradeCol[2], gradeCol[3], 0.80, 1)
    local gradeLbl = gradeBadge:CreateFontString(nil, "OVERLAY")
    gradeLbl:SetAllPoints(gradeBadge)
    gradeLbl:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    gradeLbl:SetJustifyH("CENTER")
    gradeLbl:SetJustifyV("MIDDLE")
    gradeLbl:SetTextColor(gradeCol[1], gradeCol[2], gradeCol[3])
    gradeLbl:SetText(score.checks > 0 and score.grade or "?")

    local headerDiv = bc:CreateTexture(nil, "OVERLAY")
    headerDiv:SetHeight(1)
    headerDiv:SetPoint("TOPLEFT",  bc, "TOPLEFT",  20, -118)
    headerDiv:SetPoint("TOPRIGHT", bc, "TOPRIGHT", -20, -118)
    headerDiv:SetColorTexture(C.border[1], C.border[2], C.border[3], C.border[4])

    -- =============================================
    -- AUSRÜSTUNGS-STATUS (Karten-Raster mit Fortschrittsbalken)
    -- =============================================
    local gridLabel = bc:CreateFontString(nil, "OVERLAY")
    gridLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    gridLabel:SetPoint("TOPLEFT", bc, "TOPLEFT", 20, -134)
    gridLabel:SetText(WeintCodex.ColorText("textFaint", "AUSRÜSTUNGS-STATUS"))

    local cardDefs = {
        { kind = "counts", label = "Verzauberungen",  counts = scan.enchants.counts, onClick = ShowEnchants },
        { kind = "counts", label = "Sockel & Steine",  counts = scan.gems.counts,     onClick = ShowGems },
    }
    for _, cs in ipairs(scan.caps) do
        cardDefs[#cardDefs + 1] = { kind = "cap", cap = cs, onClick = ShowWerteverteilung }
    end

    local GRID_TOP, GRID_H, GRID_GAP = -154, 92, 10
    local colW = (UEBERSICHT_W - 40 - GRID_GAP * (#cardDefs - 1)) / #cardDefs

    for i, def in ipairs(cardDefs) do
        local card = CreateFrame("Button", nil, bc)
        card:SetSize(colW, GRID_H)
        card:SetPoint("TOPLEFT", bc, "TOPLEFT", 20 + (i - 1) * (colW + GRID_GAP), GRID_TOP)
        SetSolidBg(card, C.surface2[1], C.surface2[2], C.surface2[3], 1.0)
        DrawBorder(card, C.border[1], C.border[2], C.border[3], C.border[4], 1)

        local lbl = card:CreateFontString(nil, "OVERLAY")
        lbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        lbl:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -10)
        lbl:SetPoint("RIGHT", card, "RIGHT", -10, 0)
        lbl:SetJustifyH("LEFT")

        local mainCol, mainText, subText, pct
        if def.kind == "counts" then
            local counts = def.counts
            local filled = counts.total - counts.missing
            pct = (counts.total > 0) and (filled / counts.total) or 0
            local qual = (filled > 0) and math.floor(counts.points / filled + 0.5) or 0
            if qual > 100 then qual = 100 end
            if counts.total == 0 then mainCol = C.textDim
            elseif counts.missing == 0 then mainCol = (counts.overcap > 0) and PURPLE or C.green
            else mainCol = (pct >= 0.75) and C.gold or C.red end
            lbl:SetText(WeintCodex.ColorText("textFaint", string.upper(def.label)))
            mainText = filled .. " / " .. counts.total
            subText  = "Qualität " .. qual .. "%"
        else
            local cs = def.cap
            if cs.overPct > 0.25 then mainCol = PURPLE
            elseif cs.overPct < -0.3 then mainCol = C.red
            else mainCol = C.green end
            pct = (cs.capPct > 0) and math.max(0, math.min(1, cs.current / cs.capPct)) or 0
            lbl:SetText(WeintCodex.ColorText("textFaint", string.upper(cs.label)))
            mainText = string.format("%.1f%%", cs.current)
            if cs.overPct > 0.25 then subText = string.format("Cap %.1f%% · über", cs.capPct)
            elseif cs.overPct < -0.3 then subText = string.format("Cap %.1f%% · fehlt", cs.capPct)
            else subText = string.format("Cap %.1f%% · optimal", cs.capPct) end
        end

        local num = card:CreateFontString(nil, "OVERLAY")
        num:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
        num:SetPoint("TOPLEFT", lbl, "BOTTOMLEFT", 0, -8)
        num:SetTextColor(mainCol[1], mainCol[2], mainCol[3])
        num:SetText(mainText)

        local subLbl = card:CreateFontString(nil, "OVERLAY")
        subLbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        subLbl:SetPoint("TOPLEFT", num, "BOTTOMLEFT", 0, -4)
        subLbl:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
        subLbl:SetText(subText)

        local track = card:CreateTexture(nil, "OVERLAY")
        track:SetHeight(3)
        track:SetPoint("BOTTOMLEFT",  card, "BOTTOMLEFT",  10, 10)
        track:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -10, 10)
        track:SetColorTexture(C.surface3[1], C.surface3[2], C.surface3[3], 1.0)

        if pct > 0.01 then
            local fill = card:CreateTexture(nil, "OVERLAY")
            fill:SetHeight(3)
            fill:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 10, 10)
            fill:SetWidth(math.max(1, (colW - 20) * math.min(pct, 1)))
            fill:SetColorTexture(mainCol[1], mainCol[2], mainCol[3], 1.0)
        end

        card:SetScript("OnEnter", function(self) SetSolidBg(self, C.surface3[1], C.surface3[2], C.surface3[3], 1.0) end)
        card:SetScript("OnLeave", function(self) SetSolidBg(self, C.surface2[1], C.surface2[2], C.surface2[3], 1.0) end)
        if def.onClick then card:SetScript("OnClick", def.onClick) end
    end

    -- =============================================
    -- HANDLUNGSBEDARF · NACH PRIORITÄT
    -- =============================================
    local hbY = GRID_TOP - GRID_H - 26

    local hbLabel = bc:CreateFontString(nil, "OVERLAY")
    hbLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    hbLabel:SetPoint("TOPLEFT", bc, "TOPLEFT", 20, hbY)
    hbLabel:SetText(WeintCodex.ColorText("textFaint", "HANDLUNGSBEDARF · NACH PRIORITÄT"))

    local rowY = hbY - 20
    if score.checks == 0 then
        local none = bc:CreateFontString(nil, "OVERLAY")
        none:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        none:SetPoint("TOPLEFT", bc, "TOPLEFT", 20, rowY)
        none:SetText(WeintCodex.ColorText("textFaint", "Keine Prüfdaten vorhanden."))
        rowY = rowY - 26
    elseif #scan.issues == 0 then
        local ok = bc:CreateFontString(nil, "OVERLAY")
        ok:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        ok:SetPoint("TOPLEFT", bc, "TOPLEFT", 20, rowY)
        ok:SetText(WeintCodex.ColorText("success", "Alles top — keine offenen Punkte!"))
        rowY = rowY - 26
    else
        for i, issue in ipairs(scan.issues) do
            local row = CreateFrame("Frame", nil, bc)
            row:SetHeight(34)
            row:SetPoint("TOPLEFT",  bc, "TOPLEFT",  20, rowY)
            row:SetPoint("TOPRIGHT", bc, "TOPRIGHT", -20, rowY)
            SetSolidBg(row, C.bgCard[1], C.bgCard[2], C.bgCard[3], 1.0)
            DrawBorder(row, C.border[1], C.border[2], C.border[3], C.border[4], 1)

            local info = STATUS[issue.status] or STATUS.neutral
            local badge = CreateFrame("Frame", nil, row)
            badge:SetSize(22, 22)
            badge:SetPoint("LEFT", row, "LEFT", 6, 0)
            SetSolidBg(badge, info.color[1] * 0.20, info.color[2] * 0.20, info.color[3] * 0.20, 1.0)

            local badgeLbl = badge:CreateFontString(nil, "OVERLAY")
            badgeLbl:SetAllPoints(badge)
            badgeLbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
            badgeLbl:SetJustifyH("CENTER")
            badgeLbl:SetJustifyV("MIDDLE")
            badgeLbl:SetTextColor(info.color[1], info.color[2], info.color[3])
            badgeLbl:SetText(tostring(i))

            local txt = row:CreateFontString(nil, "OVERLAY")
            txt:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
            txt:SetPoint("LEFT",  badge, "RIGHT", 12, 0)
            txt:SetPoint("RIGHT", row, "RIGHT", -10, 0)
            txt:SetJustifyH("LEFT")
            txt:SetWordWrap(false)
            txt:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
            txt:SetText(issue.text or "")

            rowY = rowY - 38
        end
    end

    -- =============================================
    -- WERTE-SUMMEN DER AUSRÜSTUNG
    -- =============================================
    local wsY = rowY - 18
    local wsLabel = bc:CreateFontString(nil, "OVERLAY")
    wsLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    wsLabel:SetPoint("TOPLEFT", bc, "TOPLEFT", 20, wsY)
    wsLabel:SetText(WeintCodex.ColorText("textFaint", "WERTE-SUMMEN DER AUSRÜSTUNG"))

    local wsTop = wsY - 20
    local totals = CollectEquippedStats()
    local statEntries = {}
    for _, key in ipairs(STAT_ORDER) do
        local value = totals[key]
        if value and value > 0 then
            statEntries[#statEntries + 1] = { label = STAT_LABELS[key], value = value }
        end
    end

    if #statEntries == 0 then
        local none = bc:CreateFontString(nil, "OVERLAY")
        none:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        none:SetPoint("TOPLEFT", bc, "TOPLEFT", 20, wsTop)
        none:SetText(WeintCodex.ColorText("textFaint", "Keine Werte ermittelt (Charakter einloggen / Items anlegen)."))
        rowY = wsTop - 26
    else
        local WS_COLS, WS_GAP, WS_ROW_H = 4, 10, 50
        local wsColW = (UEBERSICHT_W - 40 - WS_GAP * (WS_COLS - 1)) / WS_COLS

        for i, entry in ipairs(statEntries) do
            local col = (i - 1) % WS_COLS
            local row = math.floor((i - 1) / WS_COLS)
            local box = CreateFrame("Frame", nil, bc)
            box:SetSize(wsColW, WS_ROW_H)
            box:SetPoint("TOPLEFT", bc, "TOPLEFT", 20 + col * (wsColW + WS_GAP), wsTop - row * (WS_ROW_H + WS_GAP))
            SetSolidBg(box, C.bgCard[1], C.bgCard[2], C.bgCard[3], 1.0)
            DrawBorder(box, C.border[1], C.border[2], C.border[3], C.border[4], 1)

            local lbl2 = box:CreateFontString(nil, "OVERLAY")
            lbl2:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
            lbl2:SetPoint("TOPLEFT", box, "TOPLEFT", 10, -8)
            lbl2:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
            lbl2:SetText(entry.label)

            local val = box:CreateFontString(nil, "OVERLAY")
            val:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
            val:SetPoint("TOPLEFT", lbl2, "BOTTOMLEFT", 0, -4)
            val:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
            val:SetText("+" .. entry.value)
        end

        local wsRows = math.ceil(#statEntries / WS_COLS)
        rowY = wsTop - wsRows * (WS_ROW_H + WS_GAP)
    end

    local foot = bc:CreateFontString(nil, "OVERLAY")
    foot:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    foot:SetPoint("TOPLEFT", bc, "TOPLEFT", 20, rowY - 8)
    foot:SetText(WeintCodex.ColorText("textGhost", "Karten anklicken für Details. Scan läuft bei Itemwechsel automatisch."))

    bc:SetHeight(math.abs(rowY) + 40)

    local combined = {
        total   = scan.enchants.counts.total   + scan.gems.counts.total,
        missing = scan.enchants.counts.missing + scan.gems.counts.missing,
        optimal = scan.enchants.counts.optimal + scan.gems.counts.optimal,
        ok      = scan.enchants.counts.ok      + scan.gems.counts.ok,
        overcap = scan.enchants.counts.overcap + scan.gems.counts.overcap,
        wrong   = scan.enchants.counts.wrong   + scan.gems.counts.wrong,
        points  = scan.enchants.counts.points  + scan.gems.counts.points,
    }
    ShowScoreInspector(combined, {
        { type = "button", label = "Verzauberungen", onClick = ShowEnchants },
        { type = "button", label = "Sockel & Steine", onClick = ShowGems },
    })

    uebersichtFrame:Show()
end

--------------------------------------------------
-- SEITE: WERTEVERTEILUNG (Stats + Caps)
-- (STAT_LABELS/STAT_ORDER/CollectEquippedStats stehen weiter oben vor
-- SEITE: ÜBERSICHT, da beide Seiten sie nutzen)
--------------------------------------------------

local werteFrame = nil

function ShowWerteverteilung()
    activeCharakterView = "werte"
    local cp = GetContentPanel()
    if not cp then return end
    for _, child in pairs({ cp:GetChildren() }) do child:Hide() end

    if werteFrame then werteFrame:Hide(); werteFrame = nil end
    werteFrame = CreateFrame("Frame", nil, cp)
    werteFrame:SetAllPoints(cp)

    local scan = ScanCharacter()
    DrawPageHeader(werteFrame, "Werteverteilung & Caps", scan, ShowWerteverteilung)

    local divider = werteFrame:CreateTexture(nil, "OVERLAY")
    divider:SetPoint("TOPLEFT",  werteFrame, "TOPLEFT",  16, -52)
    divider:SetPoint("TOPRIGHT", werteFrame, "TOPRIGHT", -16, -52)
    divider:SetHeight(1)
    divider:SetColorTexture(C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.40)

    local yOff = -66

    -- =============================================
    -- CAPS
    -- =============================================
    local capHdr = werteFrame:CreateFontString(nil, "OVERLAY")
    capHdr:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    capHdr:SetPoint("TOPLEFT", werteFrame, "TOPLEFT", 16, yOff)
    capHdr:SetText("|cff6B6259— SEKUNDÄRSTAT-CAPS (live vom Charakterbogen) —|r")
    yOff = yOff - 20

    if #scan.caps == 0 then
        local none = werteFrame:CreateFontString(nil, "OVERLAY")
        none:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        none:SetPoint("TOPLEFT", werteFrame, "TOPLEFT", 16, yOff)
        none:SetText(scan.profile
            and "|cff6B6259Für diese Spec gibt es keine Pflicht-Caps (Heiler).|r"
            or  "|cffff9900Kein Spec-Profil — Caps können nicht geprüft werden.|r")
        yOff = yOff - 24
    else
        for _, cs in ipairs(scan.caps) do
            yOff = yOff - DrawCapBar(werteFrame, 16, yOff, 420, cs)
            if cs.note then
                local note = werteFrame:CreateFontString(nil, "OVERLAY")
                note:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
                note:SetPoint("TOPLEFT", werteFrame, "TOPLEFT", 16, yOff)
                note:SetText("|cff6B6259" .. cs.note .. "|r")
                yOff = yOff - 14
            end
            if cs.overPct > 0.25 and #cs.wasted > 0 then
                for _, w in ipairs(cs.wasted) do
                    local src = werteFrame:CreateFontString(nil, "OVERLAY")
                    src:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
                    src:SetPoint("TOPLEFT", werteFrame, "TOPLEFT", 26, yOff)
                    local nm
                    if w.art == "Stein" then
                        nm = GetGemDisplayName(w.row.gemId)
                    else
                        nm = GetEnchantDisplayName(w.row.enchId)
                    end
                    src:SetText(string.format("|cffcc88ff> %s: %s (%s, +%d) austauschen|r",
                        w.row.slotName or "?", nm or "?", w.art, w.value))
                    yOff = yOff - 13
                end
            end
            yOff = yOff - 4
        end
    end

    yOff = yOff - 10

    -- =============================================
    -- STAT-SUMMEN
    -- =============================================
    local hdr = werteFrame:CreateFontString(nil, "OVERLAY")
    hdr:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    hdr:SetPoint("TOPLEFT", werteFrame, "TOPLEFT", 16, yOff)
    hdr:SetText("|cff6B6259— WERTE-SUMMEN DER AUSRÜSTUNG —|r")
    yOff = yOff - 22

    local totals = CollectEquippedStats()
    local anyStat = false
    for _, key in ipairs(STAT_ORDER) do
        local value = totals[key]
        if value and value > 0 then
            anyStat = true
            local row = CreateFrame("Frame", nil, werteFrame)
            row:SetSize(420, 20)
            row:SetPoint("TOPLEFT", werteFrame, "TOPLEFT", 16, yOff)
            SetSolidBg(row, C.surface2[1], C.surface2[2], C.surface2[3], 0.55)

            local lbl = row:CreateFontString(nil, "OVERLAY")
            lbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
            lbl:SetPoint("LEFT", row, "LEFT", 10, 0)
            lbl:SetText(STAT_LABELS[key])
            lbl:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])

            local val = row:CreateFontString(nil, "OVERLAY")
            val:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
            val:SetPoint("RIGHT", row, "RIGHT", -10, 0)
            val:SetText("|cffC8763A+" .. value .. "|r")

            yOff = yOff - 22
        end
    end

    if not anyStat then
        local none = werteFrame:CreateFontString(nil, "OVERLAY")
        none:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        none:SetPoint("TOPLEFT", werteFrame, "TOPLEFT", 16, yOff)
        none:SetText("|cffaaaaaaKeine Werte ermittelt (Charakter einloggen / Items anlegen).|r")
    end

    local hint = werteFrame:CreateFontString(nil, "OVERLAY")
    hint:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    hint:SetPoint("BOTTOMLEFT", werteFrame, "BOTTOMLEFT", 16, 8)
    hint:SetText("|cff4A423ACap-Werte kommen live vom Charakterbogen (inkl. Rassenboni & Buffs). Summen = reine Item-Stats.|r")

    local capRows = {}
    for _, cs in ipairs(scan.caps) do
        local vc = "success"
        if cs.overPct > 0.25 then vc = "violet"
        elseif cs.overPct < -0.3 then vc = "danger" end
        capRows[#capRows + 1] = {
            label = cs.label,
            value = string.format("%.1f%% / %.1f%%", cs.current, cs.capPct),
            valueColor = vc,
        }
    end
    if #capRows == 0 then
        capRows[1] = { label = "Keine Pflicht-Caps für diese Spec", valueColor = "textFaint" }
    end
    ShowScoreInspector(nil, {
        { type = "header", text = "Sekundärstat-Caps" },
        { type = "rows", rows = capRows },
        { type = "divider" },
        { type = "button", label = "Zur Priorisierung", onClick = ShowPriorisierung },
    })

    werteFrame:Show()
end

--------------------------------------------------
-- SEITE: PRIORISIERUNG (eigene Stat-Gewichtung)
-- Spieler stellen hier ihre eigenen Gewichte ein;
-- die Stein-Bewertung rechnet dann mit diesen
-- Prioritäten statt mit den Profil-Standards.
--------------------------------------------------

local WEIGHT_STATS = {
    { key = "strength",  label = "Stärke" },
    { key = "agility",   label = "Beweglichkeit" },
    { key = "intellect", label = "Intelligenz" },
    { key = "stamina",   label = "Ausdauer" },
    { key = "spirit",    label = "Willenskraft" },
    { key = "hit",       label = "Trefferwertung" },
    { key = "expertise", label = "Waffenkunde" },
    { key = "crit",      label = "Kritische Trefferwertung" },
    { key = "haste",     label = "Tempowertung" },
    { key = "mastery",   label = "Meisterschaftswertung" },
    { key = "dodge",     label = "Ausweichwertung" },
    { key = "parry",     label = "Parierwertung" },
}

local prioFrame = nil

function ShowPriorisierung()
    activeCharakterView = "prio"
    local cp = GetContentPanel()
    if not cp then return end
    for _, child in pairs({ cp:GetChildren() }) do child:Hide() end

    if prioFrame then prioFrame:Hide(); prioFrame = nil end
    prioFrame = CreateFrame("Frame", nil, cp)
    prioFrame:SetAllPoints(cp)
    prioFrame:Show()

    local profile, profileKey, tankStyle, specDisplay = GetCurrentSpecProfile()
    DrawPageHeader(prioFrame, "Priorisierung (eigene Gewichtung)",
        { profile = profile, profileKey = profileKey, tankStyle = tankStyle, specDisplay = specDisplay },
        ShowPriorisierung)

    local effKey = GetEffectiveProfileKey(profileKey, tankStyle)
    local baseProfile = effKey and WeintCodex_SpecProfiles
                        and WeintCodex_SpecProfiles[effKey]

    if not baseProfile then
        local warn = prioFrame:CreateFontString(nil, "OVERLAY")
        warn:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        warn:SetPoint("TOPLEFT", prioFrame, "TOPLEFT", 16, -70)
        warn:SetText("|cffff9900Kein Spec-Profil gefunden — bitte einloggen bzw. Spec wählen.|r")
        return
    end

    WeintCodex.SavedData = WeintCodex.SavedData or {}
    local sd = WeintCodex.SavedData
    sd.customWeights = sd.customWeights or {}
    local entry    = sd.customWeights[effKey]
    local defaults = baseProfile.statWeights or {}
    local current  = (entry and entry.weights) or {}

    local desc = prioFrame:CreateFontString(nil, "OVERLAY")
    desc:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    desc:SetPoint("TOPLEFT", prioFrame, "TOPLEFT", 16, -52)
    desc:SetWidth(math.max((cp:GetWidth() or 660) - 32, 400))
    desc:SetJustifyH("LEFT")
    desc:SetText("|cff6B6259Gewichte 0-999: je höher, desto wichtiger ist der Wert für DICH (0 = egal). "
        .. "Wirkt auf die Stein-Bewertung (Qualitäts-%, OK/Falsch) und die Empfehlungsauswahl bei Cap-Überschuss. "
        .. "Empfehlungslisten der Spec und Treffer-/Waffenkunde-Caps bleiben unverändert.|r")

    -- Aktiv-Schalter
    local cb = CreateFrame("CheckButton", nil, prioFrame, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    cb:SetPoint("TOPLEFT", prioFrame, "TOPLEFT", 12, -84)
    cb:SetChecked(entry and entry.enabled and true or false)

    local cbLbl = prioFrame:CreateFontString(nil, "OVERLAY")
    cbLbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    cbLbl:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    cbLbl:SetText("|cffddddffEigene Gewichtung verwenden|r |cff6B6259(für " .. (specDisplay or profileKey) .. ")|r")

    -- Eingabefelder
    local boxes = {}
    local yOff = -116

    for _, st in ipairs(WEIGHT_STATS) do
        local row = CreateFrame("Frame", nil, prioFrame)
        row:SetSize(430, 22)
        row:SetPoint("TOPLEFT", prioFrame, "TOPLEFT", 16, yOff)
        SetSolidBg(row, C.surface2[1], C.surface2[2], C.surface2[3], 0.55)

        local lbl = row:CreateFontString(nil, "OVERLAY")
        lbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        lbl:SetPoint("LEFT", row, "LEFT", 10, 0)
        lbl:SetText(st.label)
        lbl:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])

        local def = row:CreateFontString(nil, "OVERLAY")
        def:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        def:SetPoint("RIGHT", row, "RIGHT", -70, 0)
        def:SetText("|cff6B6259Standard: " .. (defaults[st.key] or 0) .. "|r")

        local eb = CreateFrame("EditBox", nil, row)
        eb:SetSize(48, 18)
        eb:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        eb:SetAutoFocus(false)
        eb:SetNumeric(true)
        eb:SetMaxLetters(3)
        eb:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        eb:SetJustifyH("CENTER")
        eb:SetTextInsets(4, 4, 0, 0)
        SetSolidBg(eb, C.surface2[1], C.surface2[2], C.surface2[3], 0.95)
        DrawBorder(eb, C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.60, 1)
        eb:SetText(tostring(current[st.key] or defaults[st.key] or 0))
        eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        eb:SetScript("OnEnterPressed",  function(self) self:ClearFocus() end)

        boxes[st.key] = eb
        yOff = yOff - 24
    end

    -- Speichern / Zurücksetzen
    local saveBtn = MakeBtn(prioFrame, "Speichern & Anwenden", 160, 24, function()
        local w = {}
        for key, box in pairs(boxes) do
            local v = tonumber(box:GetText()) or 0
            if v < 0 then v = 0 end
            if v > 999 then v = 999 end
            if v > 0 then w[key] = v end
        end
        sd.customWeights[effKey] = {
            enabled = cb:GetChecked() and true or false,
            weights = w,
        }
        print("|cffC8763A[WeintCodex]|r Gewichtung für " .. (specDisplay or profileKey) .. " gespeichert"
            .. (cb:GetChecked() and " und aktiviert." or " (derzeit deaktiviert)."))
        ShowPriorisierung()
    end)
    saveBtn:SetPoint("TOPLEFT", prioFrame, "TOPLEFT", 16, yOff - 8)

    local resetBtn = MakeBtn(prioFrame, "Auf Standard zurücksetzen", 180, 24, function()
        sd.customWeights[effKey] = nil
        print("|cffC8763A[WeintCodex]|r Gewichtung für " .. (specDisplay or profileKey) .. " auf Standard zurückgesetzt.")
        ShowPriorisierung()
    end)
    resetBtn:SetPoint("TOPLEFT", prioFrame, "TOPLEFT", 186, yOff - 8)

    local hint = prioFrame:CreateFontString(nil, "OVERLAY")
    hint:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    hint:SetPoint("BOTTOMLEFT", prioFrame, "BOTTOMLEFT", 16, 6)
    hint:SetText("|cff4A423AGilt pro Spec (Tanks: getrennt für Offensiv/Defensiv). Wird pro Account gespeichert.|r")

    ShowScoreInspector(nil, {
        { type = "header", text = "Eigene Gewichtung" },
        { type = "rows", rows = {
            { label = "Status", value = (entry and entry.enabled) and "aktiv" or "inaktiv",
              valueColor = (entry and entry.enabled) and "success" or "textDim" },
            { label = "Spec", value = specDisplay or profileKey or "—" },
        }},
        { type = "divider" },
        { type = "button", label = "Zur Werteverteilung", onClick = ShowWerteverteilung },
    })
end

--------------------------------------------------
-- TWINKVERWALTUNG – Gilden-Scan & Export
--------------------------------------------------

local twinkFrame = nil
local twinkRows  = {}
-- twinkScanBtn/twinkExportBtn sind bereits weiter oben deklariert
-- (siehe MakeRefreshButton), damit sich beide Button-Paare gegenseitig
-- ausblenden koennen.

local function GetSavedTwinkSelection()
    WeintCodex.SavedData = WeintCodex.SavedData or {}
    WeintCodex.SavedData.twinks = WeintCodex.SavedData.twinks or {}
    return WeintCodex.SavedData.twinks
end

local function BuildTwinkExportString()
    local saved = GetSavedTwinkSelection()
    local parts = {}
    for name, data in pairs(saved) do
        if data.selected then
            parts[#parts + 1] = string.format("%s|%s|%s|%s",
                name,
                data.class or "",
                data.level or "0",
                data.note or "")
        end
    end
    table.sort(parts)
    local dateStr = date("%Y-%m-%d")
    return "WCEXPORT:TWINK:" .. dateStr .. ":" .. table.concat(parts, ",")
end

function ShowTwinkverwaltung()
    activeCharakterView = "twinks"
    local cp = GetContentPanel()
    if not cp then return end
    for _, child in pairs({ cp:GetChildren() }) do child:Hide() end

    if twinkFrame then twinkFrame:Hide(); twinkFrame = nil end
    twinkRows = {}

    twinkFrame = CreateFrame("Frame", nil, cp)
    twinkFrame:SetAllPoints(cp)

    local title = twinkFrame:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\MORPHEUS.TTF", 17, "")
    title:SetPoint("TOPLEFT", twinkFrame, "TOPLEFT", 16, -14)
    title:SetText("|cffC8763ATwinkverwaltung|r")

    local sub = twinkFrame:CreateFontString(nil, "OVERLAY")
    sub:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    sub:SetWidth(640)
    sub:SetJustifyH("LEFT")
    sub:SetText("|cff6B6259Gildenmitglieder scannen und eigene Twinks auswählen. Export für den WeintCodex Discord-Bot.|r")

    WeintCodex.SetBreadcrumb("Charakter", "Twinkverwaltung")

    if refreshBtn then refreshBtn:Hide() end

    if not twinkScanBtn then
        twinkScanBtn = WeintCodex.CreateCard(WeintCodex.TitleBarActions, { width = 106, height = 30, buttonStyle = true })
        twinkScanBtn:SetPoint("TOPRIGHT", WeintCodex.TitleBarActions, "TOPRIGHT", -108, -11)
        local l1 = twinkScanBtn:CreateFontString(nil, "OVERLAY")
        l1:SetAllPoints(twinkScanBtn)
        l1:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        l1:SetJustifyH("CENTER")
        l1:SetText("Gilde scannen")
        l1:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
        twinkScanBtn:SetScript("OnEnter", function(self) self:SetSurface("surface3") end)
        twinkScanBtn:SetScript("OnLeave", function(self) self:SetSurface("surface2") end)

        twinkExportBtn = WeintCodex.CreateCard(WeintCodex.TitleBarActions, { width = 96, height = 30, buttonStyle = true })
        twinkExportBtn:SetPoint("TOPRIGHT", WeintCodex.TitleBarActions, "TOPRIGHT", 0, -11)
        local l2 = twinkExportBtn:CreateFontString(nil, "OVERLAY")
        l2:SetAllPoints(twinkExportBtn)
        l2:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        l2:SetJustifyH("CENTER")
        l2:SetText("Export")
        l2:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
        twinkExportBtn:SetScript("OnEnter", function(self) self:SetSurface("surface3") end)
        twinkExportBtn:SetScript("OnLeave", function(self) self:SetSurface("surface2") end)
        twinkExportBtn:SetScript("OnClick", function()
            local exportStr = BuildTwinkExportString()
            if WeintCodex.ShowExportDialog then
                WeintCodex.ShowExportDialog("Twink-Export", exportStr)
            end
        end)
    end
    twinkScanBtn:Show()
    twinkExportBtn:Show()

    local sf, inner = CreateScrollArea(twinkFrame, 14, -52, 20, 400)
    sf:ClearAllPoints()
    sf:SetPoint("TOPLEFT",     twinkFrame, "TOPLEFT",     14, -52)
    sf:SetPoint("BOTTOMRIGHT", twinkFrame, "BOTTOMRIGHT", -26, 36)
    inner:SetWidth(sf:GetWidth() - 22)

    local saved = GetSavedTwinkSelection()
    local playerName = UnitName("player")

    local function DrawRoster()
        for _, child in pairs({ inner:GetChildren() }) do
            child:Hide()
            child:SetParent(nil)
        end
        twinkRows = {}

        if not IsInGuild() then
            local msg = inner:CreateFontString(nil, "OVERLAY")
            msg:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
            msg:SetPoint("TOPLEFT", inner, "TOPLEFT", 8, -8)
            msg:SetText("|cffff9900Du bist in keiner Gilde — bitte einer Gilde beitreten.|r")
            twinkRows[1] = msg
            inner:SetHeight(40)
            ShowScoreInspector(nil, {
                { type = "header", text = "Twinkverwaltung" },
                { type = "rows", rows = { { label = "Status", value = "keine Gilde", valueColor = "textFaint" } } },
            })
            return
        end

        if GuildRoster then
            GuildRoster()
        elseif C_GuildInfo and C_GuildInfo.GuildRoster then
            C_GuildInfo.GuildRoster()
        end
        local numMembers = GetNumGuildMembers()
        title:SetText(string.format(
            "|cffC8763ATwinkverwaltung|r |cff888888(%d Mitglieder gefunden)|r",
            numMembers or 0))

        local yOff = 0
        local count = 0

        for i = 1, numMembers do
            local name, _, _, level, class, _, _, _, online, _, classFileName = GetGuildRosterInfo(i)
            if name then
                local shortName = name:match("([^%-]+)") or name
                count = count + 1

                local row = CreateFrame("Frame", nil, inner)
                row:SetSize(inner:GetWidth() - 4, 24)
                row:SetPoint("TOPLEFT", inner, "TOPLEFT", 2, yOff)
                SetSolidBg(row, C.surface2[1], C.surface2[2], C.surface2[3], count % 2 == 0 and 0.45 or 0.30)

                local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
                cb:SetSize(22, 22)
                cb:SetPoint("LEFT", row, "LEFT", 4, 0)
                local entry = saved[shortName] or {}
                cb:SetChecked(entry.selected or (shortName == playerName))
                cb:SetScript("OnClick", function(self)
                    saved[shortName] = saved[shortName] or {
                        class = classFileName or class or "",
                        level = tostring(level or 0),
                    }
                    saved[shortName].selected = self:GetChecked()
                end)

                local nameLbl = row:CreateFontString(nil, "OVERLAY")
                nameLbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
                nameLbl:SetPoint("LEFT", row, "LEFT", 30, 0)
                nameLbl:SetWidth(140)
                nameLbl:SetJustifyH("LEFT")
                nameLbl:SetText(shortName .. (shortName == playerName and " |cffC8763A(Du)|r" or ""))
                nameLbl:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])

                local classLbl = row:CreateFontString(nil, "OVERLAY")
                classLbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
                classLbl:SetPoint("LEFT", row, "LEFT", 180, 0)
                classLbl:SetWidth(120)
                classLbl:SetJustifyH("LEFT")
                classLbl:SetText(class or "—")
                classLbl:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])

                local lvlLbl = row:CreateFontString(nil, "OVERLAY")
                lvlLbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
                lvlLbl:SetPoint("LEFT", row, "LEFT", 300, 0)
                lvlLbl:SetText("Stufe " .. (level or "?"))
                lvlLbl:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])

                local onlineLbl = row:CreateFontString(nil, "OVERLAY")
                onlineLbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
                onlineLbl:SetPoint("RIGHT", row, "RIGHT", -8, 0)
                onlineLbl:SetText(online and "|cff22C55EOnline|r" or "|cff666666Offline|r")

                if not saved[shortName] then
                    saved[shortName] = {
                        selected = (shortName == playerName),
                        class    = classFileName or class or "",
                        level    = tostring(level or 0),
                    }
                else
                    saved[shortName].class = classFileName or class or saved[shortName].class
                    saved[shortName].level = tostring(level or saved[shortName].level)
                end

                twinkRows[#twinkRows + 1] = row
                yOff = yOff - 26
            end
        end

        inner:SetHeight(math.max(40, -yOff + 10))

        local selectedCount = 0
        for _, entry in pairs(saved) do
            if entry.selected then selectedCount = selectedCount + 1 end
        end
        ShowScoreInspector(nil, {
            { type = "header", text = "Twinkverwaltung" },
            { type = "rows", rows = {
                { label = "Gildenmitglieder", value = tostring(numMembers or 0) },
                { label = "Ausgewählt",       value = tostring(selectedCount), valueColor = "purple" },
            }},
            { type = "divider" },
            { type = "button", style = "primary", label = "Export", onClick = function()
                local exportStr = BuildTwinkExportString()
                if WeintCodex.ShowExportDialog then
                    WeintCodex.ShowExportDialog("Twink-Export", exportStr)
                end
            end },
        })
    end

    twinkScanBtn:SetScript("OnClick", DrawRoster)

    local foot = twinkFrame:CreateFontString(nil, "OVERLAY")
    foot:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    foot:SetPoint("BOTTOMLEFT", twinkFrame, "BOTTOMLEFT", 16, 8)
    foot:SetText("|cff4A423AFormat: WCEXPORT:TWINK:DATUM:Name|KLASSE|STUFE|NOTIZ,...|r")

    DrawRoster()
    twinkFrame:Show()
end

--------------------------------------------------
-- CHARAKTER.SHOW – Sidebar aufbauen
--------------------------------------------------

function WeintCodex.Charakter.Show()
    activeCharakterView = nil
    WeintCodex.Navigation.BuildSidebar("CHARAKTER", {
        { label = "Übersicht",       onClick = ShowUebersicht },
        { isGroup = true, label = "— AUSRÜSTUNG —" },
        { label = "Verzauberungen",  onClick = ShowEnchants,  indent = true },
        { label = "Sockel",          onClick = ShowGems,      indent = true },
        { isGroup = true, label = "— ANALYSE —" },
        { label = "Werteverteilung", onClick = ShowWerteverteilung },
        { label = "Priorisierung",   onClick = ShowPriorisierung },
        { isGroup = true, label = "— VERWALTUNG —" },
        { label = "Twinkverwaltung", onClick = ShowTwinkverwaltung },
    })
    WeintCodex.Navigation.ActivateFirst()
end
