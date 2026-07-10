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
    SetSolidBg(btn, 0.12, 0.08, 0.22, 0.92)
    DrawBorder(btn, 0.42, 0.25, 0.72, 0.70, 1)
    local lbl = btn:CreateFontString(nil, "OVERLAY")
    lbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    lbl:SetAllPoints(btn)
    lbl:SetJustifyH("CENTER")
    lbl:SetJustifyV("MIDDLE")
    lbl:SetText(label)
    lbl:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
    btn:SetScript("OnEnter", function(self) SetSolidBg(self, 0.20, 0.14, 0.35, 0.98) end)
    btn:SetScript("OnLeave", function(self) SetSolidBg(self, 0.12, 0.08, 0.22, 0.92) end)
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

local PURPLE = { 0.72, 0.45, 0.98, 1.0 }

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

WeintCodex._enchantNameCache = WeintCodex._enchantNameCache or {}

local function GetEnchantDisplayName(enchantId)
    if not enchantId then return nil end
    if WeintCodex._enchantNameCache[enchantId] then
        return WeintCodex._enchantNameCache[enchantId]
    end
    local db = WeintCodex_Enchants and WeintCodex_Enchants[enchantId]
    if db and db.name then
        WeintCodex._enchantNameCache[enchantId] = db.name
        return db.name
    end
    scanTip:ClearLines()
    scanTip:SetHyperlink("enchant:" .. enchantId)
    if scanTip:NumLines() >= 1 then
        local line = _G["WeintCodexScanTipTextLeft1"]
        local name = line and line:GetText()
        if name and name ~= "" then
            WeintCodex._enchantNameCache[enchantId] = name
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

local function GetEquippedEnchantText(slotId, enchantId)
    if not enchantId then return nil end
    if WeintCodex._enchantNameCache[enchantId] then
        return WeintCodex._enchantNameCache[enchantId]
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
                WeintCodex._enchantNameCache[enchantId] = name
                return name
            end
        end
    end
    return nil
end

local function ClearCharakterCache()
    WeintCodex._enchantNameCache = {}
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

local SOCKET_COLOR_LABEL = {
    meta      = "Meta",
    rot       = "Rot",
    gelb      = "Gelb",
    blau      = "Blau",
    orange    = "Orange",
    lila      = "Lila",
    ["grün"]  = "Grün",
    prismatic = "Prismatisch",
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
-- AKTIVES SPEC-PROFIL ERMITTELN
-- Gibt zurück: profile, profileKey, tankStyle
--------------------------------------------------

local function GetCurrentSpecProfile()
    local _, className = UnitClass("player")
    if not className then return nil, nil, nil end

    local specIndex
    if GetSpecialization then
        local ok, idx = pcall(GetSpecialization)
        if ok then specIndex = idx end
    end
    if not specIndex and GetPrimaryTalentTree then
        local ok, idx = pcall(GetPrimaryTalentTree)
        if ok then specIndex = idx end
    end
    if not specIndex then return nil, nil, nil end

    local specs = SPEC_MAP[className]
    local specName = specs and specs[specIndex]
    if not specName then return nil, nil, nil end

    local profileKey = className .. "_" .. specName

    if TANK_SPECS[profileKey] then
        local style = GetTankStyle(profileKey)
        if style == "OFF" then
            local offProfile = WeintCodex_SpecProfiles
                and WeintCodex_SpecProfiles[profileKey .. "_OFFENSIVE"]
            if offProfile then
                return offProfile, profileKey, "OFF"
            end
        end
        local defProfile = WeintCodex_SpecProfiles and WeintCodex_SpecProfiles[profileKey]
        return defProfile, profileKey, "DEF"
    end

    local profile = WeintCodex_SpecProfiles and WeintCodex_SpecProfiles[profileKey]
    return profile, profileKey, nil
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
local function PickGemRecommendation(socketColor, profile, overStats)
    if not profile or not profile.bestGems then return nil end
    local list = profile.bestGems[socketColor] or profile.bestGems.prismatic
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
local function EvaluateGem(gemId, socketColor, profile)
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

local function EvaluateEnchant(enchId, slotKey, profile)
    local bestList = profile and profile.bestEnchants
                     and profile.bestEnchants[slotKey]
    if not bestList then
        return "neutral", nil
    end
    if not enchId then return "missing", bestList end
    if IsInList(enchId, bestList) then return "optimal", bestList end
    return "ok", bestList
end

--------------------------------------------------
-- SCAN-ENGINE
-- Ein Durchlauf liefert alle Daten für alle Seiten.
--------------------------------------------------

local function ScanCharacter()
    local profile, profileKey, tankStyle = GetCurrentSpecProfile()
    local capStates = BuildCapStates(profile)

    local scan = {
        profile    = profile,
        profileKey = profileKey,
        tankStyle  = tankStyle,
        caps       = capStates,
        enchants   = { rows = {} },
        gems       = { rows = {} },
        issues     = {},
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
                    -- Offiziellen deutschen Namen vom Tooltip in den
                    -- Cache legen (überschreibt DB-Namen)
                    GetEquippedEnchantText(slotDef.id, enchId)
                    local status, bestList = EvaluateEnchant(enchId, slotDef.enchSlot, profile)
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
            for _, socket in ipairs(sockets) do
                local status, qualityPct, unknown =
                    EvaluateGem(socket.gemId, socket.color, profile)
                scan.gems.rows[#scan.gems.rows + 1] = {
                    slotId     = slotDef.id,
                    slotName   = slotDef.name,
                    itemName   = itemName,
                    socket     = socket,
                    gemId      = socket.gemId,
                    status     = status,
                    qualityPct = qualityPct,
                    unknown    = unknown,
                }
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

    -- Empfehlungen für Sockel-Reihen setzen (Overcap-bereinigt)
    for _, row in ipairs(scan.gems.rows) do
        row.recId = PickGemRecommendation(row.socket.color, profile,
            next(overStats) and overStats or nil)
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
            local rec = row.recId and GetEnchantDisplayName(row.recId)
            issues[#issues + 1] = { prio = 1, status = "missing",
                text = row.slotName .. ": Verzauberung fehlt"
                    .. (rec and (" — Empfehlung: " .. rec) or "") }
        end
    end

    for _, row in ipairs(scan.gems.rows) do
        if row.status == "missing" then
            local rec = row.recId and GetGemDisplayName(row.recId)
            local was = row.socket.buckle and "Gürtelschnalle fehlt oder Sockel leer"
                        or ("Leerer Sockel (" ..
                            (SOCKET_COLOR_LABEL[row.socket.color] or "?") .. ")")
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
                    .. (rec and (" → " .. rec) or "") }
        end
    end

    for _, row in ipairs(scan.enchants.rows) do
        if row.status == "ok" then
            local rec = row.recId and GetEnchantDisplayName(row.recId)
            issues[#issues + 1] = { prio = 4, status = "ok",
                text = row.slotName .. ": Verzauberung nicht ideal"
                    .. (rec and (" → " .. rec) or "") }
        end
    end
    for _, row in ipairs(scan.gems.rows) do
        if row.status == "ok" and not row.unknown then
            local rec = row.recId and GetGemDisplayName(row.recId)
            issues[#issues + 1] = { prio = 4, status = "ok",
                text = row.slotName .. ": Stein nicht ideal — "
                    .. (GetGemDisplayName(row.gemId) or "?")
                    .. (rec and (" → " .. rec) or "") }
        end
    end

    table.sort(issues, function(a, b) return a.prio < b.prio end)

    return scan
end

-- Für andere Module (z.B. Companion-Export) verfügbar machen
WeintCodex.Charakter.Scan = ScanCharacter

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
local ShowUebersicht, ShowEnchants, ShowGems, ShowWerteverteilung, ShowTwinkverwaltung

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

local function MakeRefreshButton(parent, onRefresh)
    local btn, lbl = MakeBtn(parent, "Aktualisieren", 118, 24, function()
        ClearCharakterCache()
        if onRefresh then onRefresh() end
    end)
    btn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -16, -12)
    lbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    return btn
end

--------------------------------------------------
-- GEMEINSAME UI-BAUSTEINE
--------------------------------------------------

local function DrawPageHeader(frame, titleText, scan, onRefresh)
    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -14)
    title:SetText("|cff8B5CF6" .. titleText .. "|r")

    MakeRefreshButton(frame, onRefresh)

    local specInfo = frame:CreateFontString(nil, "OVERLAY")
    specInfo:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    specInfo:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    if scan.profileKey then
        local styleHint = scan.tankStyle
            and (" |cff8B5CF6[" .. (scan.tankStyle == "OFF" and "Offensiv" or "Defensiv") .. "]|r")
            or ""
        local profWarn = (not scan.profile) and "  |cffff9900(kein Profil hinterlegt!)|r" or ""
        specInfo:SetText("|cff5B4880Spec: " .. scan.profileKey .. styleHint .. "|r" .. profWarn)
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
    SetSolidBg(bg, 0.05, 0.03, 0.12, 0.80)
    DrawBorder(bg, 0.42, 0.25, 0.72, 0.40, 1)

    local info = bg:CreateFontString(nil, "OVERLAY")
    info:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    info:SetPoint("LEFT", bg, "LEFT", 10, 0)
    info:SetText("|cff8B5CF6Tank-Spielstil:|r |cff5B4880bestimmt Empfehlungen & Bewertung|r")

    local function StyleBtn(label, style, xOff)
        local isActive = (currentStyle == style)
        local btn = CreateFrame("Button", nil, bg)
        btn:SetSize(90, 20)
        btn:SetPoint("RIGHT", bg, "RIGHT", xOff, 0)
        SetSolidBg(btn, isActive and 0.25 or 0.08, isActive and 0.10 or 0.05, isActive and 0.50 or 0.18, 0.95)
        DrawBorder(btn, isActive and 0.60 or 0.28, isActive and 0.28 or 0.14, isActive and 1.00 or 0.45, 0.85, 1)
        local lbl = btn:CreateFontString(nil, "OVERLAY")
        lbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        lbl:SetAllPoints(btn)
        lbl:SetJustifyH("CENTER")
        lbl:SetJustifyV("MIDDLE")
        lbl:SetText(isActive and ("|cffcc88ff" .. label .. "|r") or ("|cff664488" .. label .. "|r"))
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

local function DrawLegend(frame, counts)
    local parts = {}
    local function Add(status, n)
        if n and n > 0 then
            parts[#parts + 1] = StatusColorStr(status)
                .. STATUS[status].label .. ": " .. n .. "|r"
        end
    end
    Add("optimal", counts.optimal)
    Add("ok",      counts.ok)
    Add("overcap", counts.overcap)
    Add("wrong",   counts.wrong)
    Add("missing", counts.missing)
    if #parts == 0 then parts[1] = "|cff5B4880Keine Prüfungen|r" end

    local legend = frame:CreateFontString(nil, "OVERLAY")
    legend:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    legend:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 6)
    legend:SetText(table.concat(parts, "   "))
end

local function DrawScoreFooter(frame, counts)
    if counts.total <= 0 then return end
    local filled  = counts.total - counts.missing
    local vollPct = math.floor((filled / counts.total) * 100)
    local qualPct = (filled > 0) and math.floor(counts.points / filled + 0.5) or 0
    if qualPct > 100 then qualPct = 100 end
    local col = (counts.missing > 0) and "|cffff5555" or "|cff22C55E"
    local score = frame:CreateFontString(nil, "OVERLAY")
    score:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    score:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 6)
    score:SetText(col .. "Vollständig: " .. vollPct .. "%|r  |cff8B5CF6Qualität: " .. qualPct .. "%|r")
end

--------------------------------------------------
-- SEITE: VERZAUBERUNGEN
--------------------------------------------------

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
        h:SetText("|cff4B3880" .. text .. "|r")
    end
    MakeHeader("STATUS",                 24, 70)
    MakeHeader("SLOT / ITEM",            94, 140)
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
    sf:SetPoint("BOTTOMRIGHT", enchantFrame, "BOTTOMRIGHT", -14, 24)
    inner:SetWidth(sf:GetWidth() - 22)

    local yOff = 0

    for _, row in ipairs(scan.enchants.rows) do
        local info = STATUS[row.status] or STATUS.neutral
        local rowH = 34

        local rf = CreateFrame("Frame", nil, inner)
        rf:SetSize(inner:GetWidth() - 4, rowH)
        rf:SetPoint("TOPLEFT", inner, "TOPLEFT", 2, yOff)
        SetSolidBg(rf, 0.07, 0.05, 0.14, 0.68)

        local stripe = rf:CreateTexture(nil, "BORDER")
        stripe:SetSize(3, rowH)
        stripe:SetPoint("LEFT", rf, "LEFT", 0, 0)
        stripe:SetColorTexture(info.color[1], info.color[2], info.color[3], 0.80)

        AttachStatusIcon(rf, row.status, 10, 0)

        local stLbl = rf:CreateFontString(nil, "OVERLAY")
        stLbl:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
        stLbl:SetPoint("LEFT", rf, "LEFT", 30, 0)
        stLbl:SetWidth(60)
        stLbl:SetJustifyH("LEFT")
        stLbl:SetText(StatusColorStr(row.status) .. info.label .. "|r")

        local slotLbl = rf:CreateFontString(nil, "OVERLAY")
        slotLbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        slotLbl:SetPoint("TOPLEFT", rf, "TOPLEFT", 92, -6)
        slotLbl:SetWidth(140)
        slotLbl:SetJustifyH("LEFT")
        slotLbl:SetText(row.slotName)
        slotLbl:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])

        if row.itemName then
            local itemLbl = rf:CreateFontString(nil, "OVERLAY")
            itemLbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
            itemLbl:SetPoint("BOTTOMLEFT", rf, "BOTTOMLEFT", 92, 5)
            itemLbl:SetWidth(140)
            itemLbl:SetJustifyH("LEFT")
            itemLbl:SetText("|cff3B2D60" .. row.itemName .. "|r")
        end

        local curLbl = rf:CreateFontString(nil, "OVERLAY")
        curLbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        curLbl:SetPoint("LEFT", rf, "LEFT", 238, 0)
        curLbl:SetWidth(232)
        curLbl:SetJustifyH("LEFT")
        if row.status == "missing" then
            curLbl:SetText("|cffff5555— Keine Verzauberung! —|r")
        elseif row.status == "neutral" and not row.enchId then
            curLbl:SetText("|cff5B4880— (keine Empfehlung für diese Spec)|r")
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
            local recLbl = rf:CreateFontString(nil, "OVERLAY")
            recLbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
            recLbl:SetPoint("LEFT", rf, "LEFT", 476, 0)
            recLbl:SetWidth(220)
            recLbl:SetJustifyH("LEFT")
            recLbl:SetText("|cff8B5CF6► " .. (GetEnchantDisplayName(row.recId) or "?") .. "|r")
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
    DrawLegend(enchantFrame, scan.enchants.counts)
    DrawScoreFooter(enchantFrame, scan.enchants.counts)
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
        noteBox:SetText("|cff5B4880" .. scan.profile.gemNote .. "|r")
    end

    local toggleOffset = DrawTankStyleToggle(gemFrame, scan.profileKey, scan.tankStyle, ShowGems)

    local headerY = -52 + toggleOffset
    local function MakeHeader(text, x, w)
        local h = gemFrame:CreateFontString(nil, "OVERLAY")
        h:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        h:SetPoint("TOPLEFT", gemFrame, "TOPLEFT", x, headerY)
        h:SetWidth(w)
        h:SetJustifyH("LEFT")
        h:SetText("|cff4B3880" .. text .. "|r")
    end
    MakeHeader("STATUS",             24, 80)
    MakeHeader("SOCKEL",            108, 120)
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
    sf:SetPoint("BOTTOMRIGHT", gemFrame, "BOTTOMRIGHT", -14, 24)
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
            slotHeader:SetText("|cff8B5CF6" .. row.slotName .. "|r"
                .. (row.itemName and ("  |cff3B2D60" .. row.itemName .. "|r") or ""))
            yOff = yOff - 20
        end

        local info = STATUS[row.status] or STATUS.neutral
        local rowH = 30

        local rf = CreateFrame("Frame", nil, inner)
        rf:SetSize(inner:GetWidth() - 4, rowH)
        rf:SetPoint("TOPLEFT", inner, "TOPLEFT", 2, yOff)
        SetSolidBg(rf, 0.07, 0.05, 0.14, 0.60)

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
            local recLbl = rf:CreateFontString(nil, "OVERLAY")
            recLbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
            recLbl:SetPoint("LEFT", rf, "LEFT", 476, 0)
            recLbl:SetWidth(220)
            recLbl:SetJustifyH("LEFT")
            recLbl:SetText("|cff8B5CF6► " .. (GetGemDisplayName(row.recId) or "?") .. "|r")
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
    DrawLegend(gemFrame, scan.gems.counts)
    DrawScoreFooter(gemFrame, scan.gems.counts)
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
    barBg:SetColorTexture(0.10, 0.07, 0.20, 0.90)

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
-- SEITE: ÜBERSICHT
--------------------------------------------------

local uebersichtFrame = nil

function ShowUebersicht()
    activeCharakterView = "uebersicht"
    local cp = GetContentPanel()
    if not cp then return end
    for _, child in pairs({ cp:GetChildren() }) do child:Hide() end

    if uebersichtFrame then uebersichtFrame:Hide(); uebersichtFrame = nil end
    uebersichtFrame = CreateFrame("Frame", nil, cp)
    uebersichtFrame:SetAllPoints(cp)

    MakeRefreshButton(uebersichtFrame, ShowUebersicht)

    local scan  = ScanCharacter()
    local score = scan.score
    local panelW = math.max(cp:GetWidth() or 0, 660)

    -- =============================================
    -- 3D-PORTRAIT + Name + Spec
    -- =============================================
    local portrait = CreateFrame("PlayerModel", nil, uebersichtFrame)
    portrait:SetSize(148, 220)
    portrait:SetPoint("TOPLEFT", uebersichtFrame, "TOPLEFT", 16, -16)
    portrait:SetUnit("player")
    DrawBorder(portrait, 0.42, 0.25, 0.72, 0.60, 2)
    SetSolidBg(portrait, 0.04, 0.02, 0.10, 0.80)

    local nameLbl = uebersichtFrame:CreateFontString(nil, "OVERLAY")
    nameLbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    nameLbl:SetPoint("TOP", portrait, "BOTTOM", 0, -4)
    nameLbl:SetWidth(148)
    nameLbl:SetJustifyH("CENTER")
    nameLbl:SetText(UnitName("player") or "—")
    nameLbl:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])

    local specLbl = uebersichtFrame:CreateFontString(nil, "OVERLAY")
    specLbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    specLbl:SetPoint("TOP", nameLbl, "BOTTOM", 0, -2)
    specLbl:SetWidth(148)
    specLbl:SetJustifyH("CENTER")
    if scan.profileKey then
        local styleHint = scan.tankStyle
            and (" [" .. (scan.tankStyle == "OFF" and "Offensiv" or "Defensiv") .. "]") or ""
        specLbl:SetText("|cff8B5CF6" .. scan.profileKey .. styleHint .. "|r")
    else
        specLbl:SetText("|cffff9900Kein Profil gefunden|r")
    end

    -- =============================================
    -- SCORE-BANNER
    -- =============================================
    local gradeCol
    if score.grade == "S" or score.grade == "A" then gradeCol = C.green
    elseif score.grade == "B" or score.grade == "C" then gradeCol = C.gold
    else gradeCol = C.red end
    if score.checks == 0 then gradeCol = C.textDim end

    local banner = CreateFrame("Frame", nil, uebersichtFrame)
    banner:SetSize(panelW - 192, 64)
    banner:SetPoint("TOPLEFT", uebersichtFrame, "TOPLEFT", 176, -16)
    SetSolidBg(banner, gradeCol[1] * 0.10, gradeCol[2] * 0.10, gradeCol[3] * 0.10, 0.95)
    DrawBorder(banner, gradeCol[1], gradeCol[2], gradeCol[3], 0.80, 2)

    local gradeLbl = banner:CreateFontString(nil, "OVERLAY")
    gradeLbl:SetFont("Fonts\\FRIZQT__.TTF", 34, "OUTLINE")
    gradeLbl:SetPoint("LEFT", banner, "LEFT", 16, 0)
    gradeLbl:SetText(score.checks > 0 and score.grade or "?")
    gradeLbl:SetTextColor(gradeCol[1], gradeCol[2], gradeCol[3])

    local bannerTitle = banner:CreateFontString(nil, "OVERLAY")
    bannerTitle:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    bannerTitle:SetPoint("TOPLEFT", banner, "TOPLEFT", 58, -10)
    bannerTitle:SetText("Gear-Check: "
        .. (score.checks > 0 and (score.total .. " / 100 Punkte") or "keine Daten"))
    bannerTitle:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])

    local nIssues = 0
    for _, is in ipairs(scan.issues) do
        if is.prio <= 3 then nIssues = nIssues + 1 end
    end
    local bannerSub = banner:CreateFontString(nil, "OVERLAY")
    bannerSub:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    bannerSub:SetPoint("TOPLEFT", banner, "TOPLEFT", 58, -32)
    bannerSub:SetWidth(banner:GetWidth() - 70)
    bannerSub:SetJustifyH("LEFT")
    if score.checks == 0 then
        bannerSub:SetText("|cffff9900Keine Prüfdaten — Charakter einloggen / Spec-Profil prüfen.|r")
    elseif nIssues == 0 then
        bannerSub:SetText("|cff22C55EAlles versorgt: Verzauberungen, Sockel und Caps sind sauber!|r")
    else
        bannerSub:SetText(string.format(
            "|cffFFBB22%d Problem%s gefunden — Details unter Handlungsbedarf.|r",
            nIssues, nIssues == 1 and "" or "e"))
    end

    -- =============================================
    -- SCORE-KARTEN (klickbar)
    -- =============================================
    local function MakeCard(label, counts, xOff, w, onClick)
        local filled  = counts.total - counts.missing
        local pct     = (counts.total > 0) and math.floor((filled / counts.total) * 100) or 0
        local qual    = (filled > 0) and math.floor(counts.points / filled + 0.5) or 0
        if qual > 100 then qual = 100 end
        local mainCol
        if counts.total == 0 then
            mainCol = C.textDim
        elseif counts.missing == 0 then
            mainCol = (counts.overcap > 0) and PURPLE or C.green
        else
            mainCol = (pct >= 75) and C.gold or C.red
        end

        local card = CreateFrame("Button", nil, uebersichtFrame)
        card:SetSize(w, 96)
        card:SetPoint("TOPLEFT", uebersichtFrame, "TOPLEFT", xOff, -88)
        SetSolidBg(card, 0.08, 0.05, 0.17, 0.95)
        DrawBorder(card, mainCol[1], mainCol[2], mainCol[3], 0.70, 2)

        local lbl = card:CreateFontString(nil, "OVERLAY")
        lbl:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        lbl:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -10)
        lbl:SetText(label)
        lbl:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])

        local num = card:CreateFontString(nil, "OVERLAY")
        num:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
        num:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -28)
        num:SetText(filled .. " / " .. counts.total)
        num:SetTextColor(mainCol[1], mainCol[2], mainCol[3])

        local qualLbl = card:CreateFontString(nil, "OVERLAY")
        qualLbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        qualLbl:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -54)
        qualLbl:SetText("|cff8B5CF6Qualität: " .. qual .. "%|r")

        local sub = {}
        if counts.missing > 0 then sub[#sub + 1] = "|cffff5555" .. counts.missing .. " fehlen|r" end
        if counts.overcap > 0 then sub[#sub + 1] = "|cffcc88ff" .. counts.overcap .. " über Cap|r" end
        if counts.wrong   > 0 then sub[#sub + 1] = "|cffff8855" .. counts.wrong .. " falsch|r" end
        if #sub > 0 then
            local subLbl = card:CreateFontString(nil, "OVERLAY")
            subLbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
            subLbl:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -68)
            subLbl:SetWidth(w - 20)
            subLbl:SetJustifyH("LEFT")
            subLbl:SetText(table.concat(sub, "  "))
        end

        local hint = card:CreateFontString(nil, "OVERLAY")
        hint:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
        hint:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8, 6)
        hint:SetText("|cff3B2D60→ Details|r")

        card:SetScript("OnEnter", function(self) SetSolidBg(self, 0.12, 0.08, 0.24, 0.98) end)
        card:SetScript("OnLeave", function(self) SetSolidBg(self, 0.08, 0.05, 0.17, 0.95) end)
        if onClick then card:SetScript("OnClick", onClick) end
        return card
    end

    MakeCard("Verzauberungen",  scan.enchants.counts, 176, 200, ShowEnchants)
    MakeCard("Sockel & Steine", scan.gems.counts,     386, 200, ShowGems)

    -- Cap-Karte (rechts): Treffer / Waffenkunde
    local capW = panelW - 612
    if capW > 130 then
        local capCard = CreateFrame("Button", nil, uebersichtFrame)
        capCard:SetSize(capW, 96)
        capCard:SetPoint("TOPLEFT", uebersichtFrame, "TOPLEFT", 596, -88)
        SetSolidBg(capCard, 0.08, 0.05, 0.17, 0.95)
        DrawBorder(capCard, 0.42, 0.25, 0.72, 0.55, 2)
        capCard:SetScript("OnClick", function() ShowWerteverteilung() end)
        capCard:SetScript("OnEnter", function(self) SetSolidBg(self, 0.12, 0.08, 0.24, 0.98) end)
        capCard:SetScript("OnLeave", function(self) SetSolidBg(self, 0.08, 0.05, 0.17, 0.95) end)

        local capTitle = capCard:CreateFontString(nil, "OVERLAY")
        capTitle:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        capTitle:SetPoint("TOPLEFT", capCard, "TOPLEFT", 12, -10)
        capTitle:SetText("Stat-Caps")
        capTitle:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])

        if #scan.caps == 0 then
            local none = capCard:CreateFontString(nil, "OVERLAY")
            none:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
            none:SetPoint("TOPLEFT", capCard, "TOPLEFT", 12, -32)
            none:SetWidth(capW - 24)
            none:SetJustifyH("LEFT")
            none:SetText("|cff5B4880Keine Caps für diese Spec.|r")
        else
            local cy = -28
            for _, cs in ipairs(scan.caps) do
                cy = cy - DrawCapBar(capCard, 12, cy, capW - 24, cs)
            end
        end
    end

    -- =============================================
    -- HANDLUNGSBEDARF
    -- =============================================
    local detY = -196

    local detTitle = uebersichtFrame:CreateFontString(nil, "OVERLAY")
    detTitle:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    detTitle:SetPoint("TOPLEFT", uebersichtFrame, "TOPLEFT", 176, detY)
    detTitle:SetText("|cff4B3880— HANDLUNGSBEDARF (nach Priorität) —|r")

    local divLine = uebersichtFrame:CreateTexture(nil, "OVERLAY")
    divLine:SetPoint("TOPLEFT",  uebersichtFrame, "TOPLEFT",  176, detY - 13)
    divLine:SetPoint("TOPRIGHT", uebersichtFrame, "TOPRIGHT",  -16, detY - 13)
    divLine:SetHeight(1)
    divLine:SetColorTexture(C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.35)

    local sf, inner = CreateScrollArea(uebersichtFrame, 176, detY - 18, 20, 200)
    sf:ClearAllPoints()
    sf:SetPoint("TOPLEFT",     uebersichtFrame, "TOPLEFT",     176, detY - 18)
    sf:SetPoint("BOTTOMRIGHT", uebersichtFrame, "BOTTOMRIGHT", -14, 24)
    inner:SetWidth(sf:GetWidth() - 22)

    local rowY = 0
    if #scan.issues == 0 and score.checks > 0 then
        local ok = inner:CreateFontString(nil, "OVERLAY")
        ok:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        ok:SetPoint("TOPLEFT", inner, "TOPLEFT", 6, -8)
        ok:SetText("|cff22C55EAlles top — keine offenen Punkte!|r")
        rowY = -30
    else
        for _, issue in ipairs(scan.issues) do
            local rf = CreateFrame("Frame", nil, inner)
            rf:SetSize(inner:GetWidth() - 4, 20)
            rf:SetPoint("TOPLEFT", inner, "TOPLEFT", 2, rowY)

            AttachStatusIcon(rf, issue.status, 2, 0)

            local txt = rf:CreateFontString(nil, "OVERLAY")
            txt:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
            txt:SetPoint("LEFT", rf, "LEFT", 24, 0)
            txt:SetWidth(inner:GetWidth() - 34)
            txt:SetJustifyH("LEFT")
            txt:SetWordWrap(false)
            txt:SetText(StatusColorStr(issue.status) .. issue.text .. "|r")

            rowY = rowY - 21
        end
    end
    inner:SetHeight(math.max(20, -rowY + 10))

    local foot = uebersichtFrame:CreateFontString(nil, "OVERLAY")
    foot:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    foot:SetPoint("BOTTOMLEFT", uebersichtFrame, "BOTTOMLEFT", 16, 6)
    foot:SetText("|cff3B2D60Karten anklicken für Details. Scan läuft bei Itemwechsel automatisch.|r")

    uebersichtFrame:Show()
end

--------------------------------------------------
-- SEITE: WERTEVERTEILUNG (Stats + Caps)
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
    capHdr:SetText("|cff4B3880— SEKUNDÄRSTAT-CAPS (live vom Charakterbogen) —|r")
    yOff = yOff - 20

    if #scan.caps == 0 then
        local none = werteFrame:CreateFontString(nil, "OVERLAY")
        none:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        none:SetPoint("TOPLEFT", werteFrame, "TOPLEFT", 16, yOff)
        none:SetText(scan.profile
            and "|cff5B4880Für diese Spec gibt es keine Pflicht-Caps (Heiler).|r"
            or  "|cffff9900Kein Spec-Profil — Caps können nicht geprüft werden.|r")
        yOff = yOff - 24
    else
        for _, cs in ipairs(scan.caps) do
            yOff = yOff - DrawCapBar(werteFrame, 16, yOff, 420, cs)
            if cs.note then
                local note = werteFrame:CreateFontString(nil, "OVERLAY")
                note:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
                note:SetPoint("TOPLEFT", werteFrame, "TOPLEFT", 16, yOff)
                note:SetText("|cff5B4880" .. cs.note .. "|r")
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
                    src:SetText(string.format("|cffcc88ff→ %s: %s (%s, +%d) austauschen|r",
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
    hdr:SetText("|cff4B3880— WERTE-SUMMEN DER AUSRÜSTUNG —|r")
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
            SetSolidBg(row, 0.07, 0.05, 0.14, 0.55)

            local lbl = row:CreateFontString(nil, "OVERLAY")
            lbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
            lbl:SetPoint("LEFT", row, "LEFT", 10, 0)
            lbl:SetText(STAT_LABELS[key])
            lbl:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])

            local val = row:CreateFontString(nil, "OVERLAY")
            val:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
            val:SetPoint("RIGHT", row, "RIGHT", -10, 0)
            val:SetText("|cff8B5CF6+" .. value .. "|r")

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
    hint:SetText("|cff3B2D60Cap-Werte kommen live vom Charakterbogen (inkl. Rassenboni & Buffs). Summen = reine Item-Stats.|r")

    werteFrame:Show()
end

--------------------------------------------------
-- TWINKVERWALTUNG – Gilden-Scan & Export
--------------------------------------------------

local twinkFrame = nil
local twinkRows  = {}

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
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    title:SetPoint("TOPLEFT", twinkFrame, "TOPLEFT", 16, -14)
    title:SetText("|cff8B5CF6Twinkverwaltung|r")

    local sub = twinkFrame:CreateFontString(nil, "OVERLAY")
    sub:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    sub:SetWidth(640)
    sub:SetJustifyH("LEFT")
    sub:SetText("|cff5B4880Gildenmitglieder scannen und eigene Twinks auswählen. Export für den WeintCodex Discord-Bot.|r")

    local scanBtn, _ = MakeBtn(twinkFrame, "Gilde scannen", 120, 26, nil)
    scanBtn:SetPoint("TOPRIGHT", twinkFrame, "TOPRIGHT", -150, -12)

    local exportBtn, _ = MakeBtn(twinkFrame, "Export", 90, 26, function()
        local exportStr = BuildTwinkExportString()
        if WeintCodex.ShowExportDialog then
            WeintCodex.ShowExportDialog("Twink-Export", exportStr)
        end
    end)
    exportBtn:SetPoint("TOPRIGHT", twinkFrame, "TOPRIGHT", -16, -12)

    local sf, inner = CreateScrollArea(twinkFrame, 14, -72, 20, 400)
    sf:ClearAllPoints()
    sf:SetPoint("TOPLEFT",     twinkFrame, "TOPLEFT",     14, -72)
    sf:SetPoint("BOTTOMRIGHT", twinkFrame, "BOTTOMRIGHT", -14, 36)
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
            return
        end

        if GuildRoster then
            GuildRoster()
        elseif C_GuildInfo and C_GuildInfo.GuildRoster then
            C_GuildInfo.GuildRoster()
        end
        local numMembers = GetNumGuildMembers()
        title:SetText(string.format(
            "|cff8B5CF6Twinkverwaltung|r |cff888888(%d Mitglieder gefunden)|r",
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
                SetSolidBg(row, 0.07, 0.05, 0.14, count % 2 == 0 and 0.45 or 0.30)

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
                nameLbl:SetText(shortName .. (shortName == playerName and " |cff8B5CF6(Du)|r" or ""))
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
    end

    scanBtn:SetScript("OnClick", DrawRoster)

    local foot = twinkFrame:CreateFontString(nil, "OVERLAY")
    foot:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    foot:SetPoint("BOTTOMLEFT", twinkFrame, "BOTTOMLEFT", 16, 8)
    foot:SetText("|cff3B2D60Format: WCEXPORT:TWINK:DATUM:Name|KLASSE|STUFE|NOTIZ,...|r")

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
        { isGroup = true, label = "— VERWALTUNG —" },
        { label = "Twinkverwaltung", onClick = ShowTwinkverwaltung },
    })
    WeintCodex.Navigation.ActivateFirst()
end
