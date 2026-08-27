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

-- Werteabgleich (modules/stat_match.lua, lädt davor). Beantwortet "welche
-- Werte bringt das, was da draufliegt" und vergleicht sie mit den
-- Empfehlungen — der Rettungsanker, wenn ID und Name aus data/enchants.lua
-- nicht taugen. Siehe Kopfkommentar dort.
local SM = WeintCodex.StatMatch

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
    DrawBorder(btn, C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1.0, 1)
    local lbl = btn:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(WeintCodex.Fonts.sans, 10, "")
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

-- Siehe core/ui.lua — dort liegt die gemeinsame Fassung, die auch
-- modules/weinttv.lua und modules/academy.lua nutzen.
local CreateScrollArea = WeintCodex.CreateScrollArea

--------------------------------------------------
-- STATUS-DEFINITIONEN (5-Zustands-System)
--------------------------------------------------

local PURPLE = C.violet

-- `color` ist der Flaechen-/Symbolton, `bright` derselbe Ton als Text auf
-- schwarzem Grund. Der Entwurf trennt das durchgaengig: eine Fuellung mit 13 %
-- Deckung vertraegt den satten Wert, eine Beschriftung daneben nicht.
local STATUS = {
    optimal = { icon = "Interface\\RaidFrame\\ReadyCheck-Ready",       size = 16, label = "Optimal",  color = C.green,  bright = C.successBright },
    ok      = { icon = "Interface\\DialogFrame\\UI-Dialog-Icon-Alert", size = 18, label = "OK",       color = C.gold,   bright = C.accentBright },
    wrong   = { icon = "Interface\\DialogFrame\\UI-Dialog-Icon-Alert", size = 18, label = "Falsch",   color = C.red,    bright = C.dangerBright,  tint = { 1.0, 0.45, 0.35 } },
    overcap = { icon = "Interface\\DialogFrame\\UI-Dialog-Icon-Alert", size = 18, label = "Über Cap", color = PURPLE,   bright = C.violetBright,  tint = { 0.75, 0.50, 1.0 } },
    missing = { icon = "Interface\\RaidFrame\\ReadyCheck-NotReady",    size = 16, label = "Fehlt",    color = C.red,    bright = C.dangerBright },
    neutral = { icon = "Interface\\Buttons\\UI-MinusButton-UP",        size = 14, label = "—",        color = C.textDim, bright = C.textMuted },
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

-- Item-ID für die Nachlieferung vormerken (GET_ITEM_INFO_RECEIVED, s.u.),
-- damit ein noch ungecachtes Item nicht dauerhaft aus der Wertung fällt.
-- Steht bewusst hier oben bei der Liste, die sie füllt: seit 2.5.0.0 merkt
-- auch ScanItemSockets vor, und die läuft weit vor dem Verzauberungsteil.
local function NotePendingItemInfo(link)
    local itemId = link and tonumber(link:match("item:(%d+):"))
    if itemId then pendingItemInfoIds[itemId] = true end
end

-- Einmal pro Session auf einen Konflikt zwischen Item-Tooltip und
-- data/enchants.lua hinweisen (siehe ResolveEnchant) - der Dump liefert
-- die Daten, mit denen sich die betroffene ID korrigieren lässt.
local enchantMismatchHinted = false

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
-- Verzauberung direkt vom Item-Tooltip lesen.
-- Der Client ist die einzige verlässliche Quelle für
-- das, was tatsächlich auf dem Item liegt — unsere
-- ID-Tabelle in data/enchants.lua kann falsch sein.
-- (Der eigentliche Scan steht weiter unten bei
--  ScanEquippedEnchant, er braucht ParseStatText.)
--------------------------------------------------

local ENCHANT_LINE_PATTERN
do
    -- ENCHANTED_TOOLTIP_LINE = "Verzaubert: %s" (dt. Client)
    local raw = _G.ENCHANTED_TOOLTIP_LINE or "Verzaubert: %s"
    ENCHANT_LINE_PATTERN = "^" .. raw:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
                                    :gsub("%%%%s", "(.+)")
end

-- Wird bei HasEnchanting() weiter unten befüllt; hier vorwärts deklariert,
-- damit ClearCharakterCache den Beruf mit zurücksetzen kann.
local enchantingKnown = nil

local function ClearCharakterCache()
    WeintCodex._enchantDbNameCache = {}
    WeintCodex._enchantTooltipCache = {}
    enchantingKnown = nil
    -- Der Werteabgleich hält seine eigenen Caches (Stein-/Verzauberungs-
    -- Stats vom Client). Bleiben sie stehen, bewertet der nächste Scan mit
    -- den Werten von vorhin — dieselbe Falle wie bei den Tooltip-Namen.
    SM.ClearCache()
end

--------------------------------------------------
-- AUSRÜSTUNGSSLOTS
-- MoP hat keinen Fernkampf-Slot mehr (Slot 18 entfällt);
-- Zielfernrohre sitzen auf der Waffe in Slot 16.
--------------------------------------------------

-- enchSlot          fester Verzauberungs-Topf (Schlüssel in
--                   spec_profiles.bestEnchants / enchants.lua)
-- enchSlotDynamisch der Topf hängt vom angelegten Gegenstand ab
--                   (Nebenhand: Waffe vs. Schild/Beihand)
-- nurVerzauberer    zählt nur mit, wenn Verzauberkunst geskillt ist
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
    { id = 11, name = "Finger 1",    enchSlot = "Ring", nurVerzauberer = true },
    { id = 12, name = "Finger 2",    enchSlot = "Ring", nurVerzauberer = true },
    { id = 13, name = "Schmuck 1" },
    { id = 14, name = "Schmuck 2" },
    { id = 15, name = "Umhang",      enchSlot = "Umhang" },
    { id = 16, name = "Haupthand",   enchSlot = "Waffe" },
    { id = 17, name = "Nebenhand",   enchSlotDynamisch = true },
}

-- SOCKELPLÄTZE: Beschriftung kommt vom CLIENT, nicht von uns.
--
-- Diese Farben bezeichnen den SOCKELPLATZ im Item, nicht die Farbe des
-- eingesetzten Steins — ein andersfarbiger Stein (z.B. Lila in Blau) kann
-- trotzdem optimal sein.
--
-- Die Beschriftungen standen bis 2.5.0.0 hier auf Deutsch fest verdrahtet.
-- Der Client hält sie selbst (`EMPTY_SOCKET_*`), und seit 2.5.0.0 hängt an
-- genau diesen Konstanten auch die ERKENNUNG der Sockelfolge im Tooltip
-- (siehe ScanItemSockets) — eine zweite, handgepflegte Fassung wäre die
-- Doppelpflege, an der die Verzauberungserkennung schon einmal gescheitert
-- ist. Unsere Texte bleiben nur als Rückfall, falls eine Konstante fehlt.
local SOCKET_COLOR_GLOBAL = {
    meta      = "EMPTY_SOCKET_META",
    rot       = "EMPTY_SOCKET_RED",
    gelb      = "EMPTY_SOCKET_YELLOW",
    blau      = "EMPTY_SOCKET_BLUE",
    prismatic = "EMPTY_SOCKET_PRISMATIC",
    zahnrad   = "EMPTY_SOCKET_COGWHEEL",
    hydraulik = "EMPTY_SOCKET_HYDRAULIC",
    einfach   = "EMPTY_SOCKET_NO_COLOR",
}

local SOCKET_COLOR_FALLBACK = {
    meta      = "Meta-Sockel",
    rot       = "Roter Sockel",
    gelb      = "Gelber Sockel",
    blau      = "Blauer Sockel",
    orange    = "Oranger Sockel",
    lila      = "Lila Sockel",
    ["grün"]  = "Grüner Sockel",
    prismatic = "Prisma-Sockel",
    zahnrad   = "Zahnradsockel",
    hydraulik = "Hydraulischer Sockel",
    einfach   = "Einfacher Sockel",
}

local SOCKET_COLOR_LABEL = setmetatable({}, {
    __index = function(_, color)
        local g = color and SOCKET_COLOR_GLOBAL[color]
        local fromClient = g and _G[g]
        if type(fromClient) == "string" and fromClient ~= "" then
            return fromClient
        end
        return SOCKET_COLOR_FALLBACK[color]
    end,
})

local SOCKET_DOT_COLOR = {
    rot       = { 0.90, 0.20, 0.20 },
    gelb      = { 0.95, 0.85, 0.10 },
    blau      = { 0.20, 0.55, 0.95 },
    orange    = { 0.95, 0.55, 0.10 },
    lila      = { 0.65, 0.25, 0.90 },
    ["grün"]  = { 0.20, 0.80, 0.30 },
    meta      = { 0.70, 0.60, 0.90 },
    prismatic = { 0.85, 0.85, 0.85 },
    zahnrad   = { 0.75, 0.65, 0.45 },
    hydraulik = { 0.55, 0.75, 0.80 },
    einfach   = { 0.80, 0.80, 0.80 },
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
--
-- DIE REIHENFOLGE STAND BIS 2.5.0.0 NICHT IM ITEM, SIE WAR ERFUNDEN.
-- `GetItemStats` liefert nur ANZAHLEN je Sockelfarbe (`EMPTY_SOCKET_RED = 1`),
-- niemals die Reihenfolge der Sockel im Gegenstand. Die alte Fassung zaehlte
-- sie in ihrer EIGENEN festen Folge ab (meta -> rot -> gelb -> blau -> prisma)
-- und paarte Stein `gem1` mit dem ersten so entstandenen Sockel. Bei jedem
-- Gegenstand mit zwei verschieden gefaerbten Sockeln konnten Stein und
-- Sockelfarbe damit vertauscht sein - und seit 2.3.0.1 haengt an genau dieser
-- Achse alles: aus welcher Liste die Empfehlung kommt, ob der Stein den Bonus
-- ausloest und was die Bonuszeile darueber behauptet. Das reproduzierte exakt
-- das Symptom, das 2.3.0.1 beheben sollte ("gelber Stein im blauen Sockel als
-- Optimal") - nur diesmal aus einer Quelle, die keine Ausgabe je genannt hat.
--
-- Gefragt wird deshalb der Client: der Tooltip des GRUNDgegenstands
-- ("item:<id>", also ohne Steine, ohne Verzauberung, ohne Aufwertungsgrad)
-- listet alle Sockel LEER und in ihrer echten Reihenfolge. Erkannt werden die
-- Zeilen an den Konstanten des Clients (`EMPTY_SOCKET_*`, siehe
-- SOCKET_COLOR_GLOBAL) und nie an eigenem Text - dieselbe Doktrin wie
-- `ITEM_MOD_*` im Werteabgleich und `ITEM_SPELL_TRIGGER_ONUSE` im
-- Ausruestungs-Alarm. Der Grundgegenstand ist noetig, weil ein besetzter
-- Sockel im Tooltip die Werte seines Steins zeigt statt der Sockelzeile.
--
-- `GetItemStats` bleibt Gegenprobe und Rueckfallweg. Weichen die Zaehlungen
-- ab, gewinnt der Tooltip - er kennt die Reihenfolge, die Zaehlung nicht -
-- und `/wc sockel` schreibt beide Seiten aus.
--
--   Steine JENSEITS der Basis-Sockel = Zusatzsockel
--   (Guertelschnalle / Schmiedekunst). Die stehen nicht am Grundgegenstand
--   und sind ohnehin prismatisch, sie kommen deshalb weiter aus der
--   Differenz.
--   Guertel ohne Zusatzstein => Schnalle fehlt/leer.
--------------------------------------------------

local GetItemStatsCompat = GetItemStats or (C_Item and C_Item.GetItemStats)

-- Zaehlweg (Rueckfall): Anzahlen je Farbe, Reihenfolge unbekannt.
local SOCKET_STAT_ORDER = {
    { stat = "EMPTY_SOCKET_META",      color = "meta" },
    { stat = "EMPTY_SOCKET_RED",       color = "rot" },
    { stat = "EMPTY_SOCKET_YELLOW",    color = "gelb" },
    { stat = "EMPTY_SOCKET_BLUE",      color = "blau" },
    { stat = "EMPTY_SOCKET_PRISMATIC", color = "prismatic" },
    { stat = "EMPTY_SOCKET_COGWHEEL",  color = "zahnrad" },
    { stat = "EMPTY_SOCKET_HYDRAULIC", color = "hydraulik" },
    { stat = "EMPTY_SOCKET_NO_COLOR",  color = "einfach" },
}

-- Zeilentext -> Sockelfarbe, aufgebaut aus den Konstanten des Clients.
-- Erst bei Bedarf, weil die Globals beim Laden der Datei noch nicht
-- zwingend gesetzt sind, und gemerkt, sobald sie es waren.
local socketLineLookup = nil
local function SocketLineLookup()
    if socketLineLookup then return socketLineLookup end
    local map = {}
    for color, globalName in pairs(SOCKET_COLOR_GLOBAL) do
        local text = _G[globalName]
        if type(text) == "string" and text ~= "" then
            map[text] = color
        end
    end
    -- Nur merken, wenn wenigstens zwei Grundfarben da waren; sonst beim
    -- naechsten Aufruf noch einmal nachsehen, statt eine halbe Tabelle
    -- fuer immer festzuhalten.
    if map[_G.EMPTY_SOCKET_RED or false] and map[_G.EMPTY_SOCKET_BLUE or false] then
        socketLineLookup = map
    end
    return map
end

-- Sockelfolge je Grundgegenstand. Die aendert sich nie, der Tooltip-Scan
-- lohnt also genau einmal je Item-ID - die Charakterseite scannt bei jedem
-- Ausruestungswechsel alle 16 Slots neu.
local socketColorCache = {}

local function BaseItemString(link)
    local id = link and (link:match("|Hitem:(%d+):") or link:match("^item:(%d+)"))
    return id and ("item:" .. id) or nil
end

-- Sockelfolge des Grundgegenstands als Liste von Farben, oder nil, wenn der
-- Tooltip (noch) nichts hergab. Rein lesend.
local function SocketColorsFromTooltip(link)
    local base = BaseItemString(link)
    if not base then return nil end

    local cached = socketColorCache[base]
    if cached ~= nil then
        return cached or nil   -- false = schon erfolglos versucht
    end

    local lookup = SocketLineLookup()
    if not next(lookup) then return nil end

    scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTip:ClearLines()
    scanTip:SetHyperlink(base)

    local n = scanTip:NumLines() or 0
    if n < 1 then return nil end   -- Item noch nicht im Cache: nichts merken

    local colors = {}
    for i = 2, n do
        local lineText = _G["WeintCodexScanTipTextLeft" .. i]
        local txt = lineText and lineText:GetText()
        local color = txt and lookup[txt]
        if color then colors[#colors + 1] = color end
    end

    -- Ein Gegenstand ohne Sockel ist ein gueltiges Ergebnis und wird als
    -- solches gemerkt (false), damit er nicht bei jedem Aufbau neu gescannt
    -- wird. Der Tooltip war ja da.
    socketColorCache[base] = (#colors > 0) and colors or false
    return (#colors > 0) and colors or nil
end

-- Rueckgabe: sockets, known, source
--   known  - hatte der Client die Basisdaten ueberhaupt? Ohne sie kennt die
--            Funktion die eingebauten Sockel nicht und meldet nur die
--            eingesetzten Steine. Fuer den eigenen Charakter faellt das kaum
--            auf (der Cache ist warm), beim Gruppencheck fremder Spieler
--            dagegen sehr wohl: "0 Sockel" waere dort eine Aussage ueber
--            unseren Cache, nicht ueber die Ruestung.
--   source - "tooltip" (echte Reihenfolge) | "stats" (nur Anzahlen, die
--            Zuordnung zu den Steinen ist dann geraten) | nil. Fuer
--            /wc sockel; ohne diese Angabe ist Fehler 1 von aussen nicht
--            zu bemerken.
--
-- wantColors == false ueberspringt den Tooltip-Weg. Der Gruppencheck zaehlt
-- nur belegte Sockel und braucht keine Farben; ein Tooltip-Scan ueber 16
-- Slots mal 25 Spieler waere die Zumutung fuer den Client, die sich diese
-- Seite ausdruecklich verboten hat.
local function ScanItemSockets(link, slotId, wantColors)
    local sockets = {}
    if not link then return sockets, false, nil end

    local _, gems = ParseItemLink(link)
    local stats = GetItemStatsCompat and GetItemStatsCompat(link)

    local colors, source
    if wantColors ~= false then
        colors = SocketColorsFromTooltip(link)
        if colors then source = "tooltip" end
    end

    -- Rueckfall: Zaehlung ohne Reihenfolge. Die Farben stimmen dann als
    -- MENGE, ihre Zuordnung zu den einzelnen Steinen ist geraten.
    if not colors and stats then
        colors = {}
        for _, socketInfo in ipairs(SOCKET_STAT_ORDER) do
            local count = stats[socketInfo.stat]
            if count and count > 0 then
                for _ = 1, count do colors[#colors + 1] = socketInfo.color end
            end
        end
        if #colors > 0 then source = "stats" end
    end

    local base = 0
    if colors then
        for _, color in ipairs(colors) do
            base = base + 1
            sockets[base] = {
                color = color,
                gemId = gems[base],
                index = base,
                orderKnown = (source == "tooltip") or nil,
            }
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

    -- Kannte der Client weder den Tooltip noch die Item-Stats, sind die
    -- eingebauten Sockel unbekannt: alle Steine staenden dann als
    -- prismatische "Zusatzsockel" da und wuerden gegen die falsche Liste
    -- gemessen. Vormerken statt schweigend zu urteilen - der
    -- Verzauberungspfad tut das seit jeher (ResolveEnchSlot), der
    -- Sockelpfad bis 2.5.0.0 nicht, und deshalb zeichnete auch nichts die
    -- Seite neu, sobald der Client nachlieferte.
    local known = (stats ~= nil) or (source == "tooltip")
    if not known then
        NotePendingItemInfo(link)
    end

    return sockets, known, source
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
-- Die Tabelle und die drei Parser wohnen seit 2.0.0.3 in
-- modules/stat_match.lua: der Werteabgleich dort braucht exakt dieselbe
-- Zuordnung, und zwei Kopien wären genau die Doppelpflege, an der die
-- Verzauberungserkennung schon einmal gescheitert ist. Hier nur noch die
-- lokalen Namen, damit der Rest der Datei unverändert bleibt.
local MatchStatKeyword = SM.MatchStatKeyword
local ParseStatText    = SM.ParseStatText
local ParseAllStats    = SM.ParseAllStats

-- Steht diese Tooltipzeile in Grün? Wird an zwei Stellen gebraucht: für die
-- Verzauberungserkennung (Weg B weiter unten) und für den Zustand des
-- Sockelbonus gleich hier darunter.
local function IsGreenLine(line)
    if not (line and line.GetTextColor) then return false end
    local ok, r, g, b = pcall(line.GetTextColor, line)
    if not ok or type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then
        return false
    end
    return r < 0.25 and g > 0.75 and b < 0.25
end

-- Gibt zurück: bonus = { stat=<key>, value=<num> } | nil, der rohe
-- Tooltip-Text der Sockelbonus-Zeile (für die Anzeige) und ob der Bonus
-- ANLIEGT.
--
-- DER ZUSTAND WIRD ABGELESEN, NICHT HERGELEITET. Bis 2.5.0.0 schloss
-- SocketBonusActive() aus den Farben der eingesetzten Steine darauf, ob der
-- Bonus greift - eine Herleitung mit drei Unbekannten (unsere Farbtabelle,
-- die Sockelfarbe und deren Reihenfolge, siehe ScanItemSockets), von denen
-- zwei nachweislich danebenlagen. Der Client schreibt die Antwort in
-- derselben Zeile hin, die wir ohnehin lesen: er zeichnet den Sockelbonus
-- GRÜN, wenn er anliegt, und grau, wenn nicht. Das ist die einzige Quelle,
-- die weder von unserer Datenpflege noch von der Übersetzung abhängt.
--
-- nil (statt false) heisst weiterhin "keine Aussage" - es gibt an diesem
-- Gegenstand keine Bonuszeile.
local function ScanSocketBonus(slotId)
    scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTip:ClearLines()
    scanTip:SetInventoryItem("player", slotId)
    local n = scanTip:NumLines() or 0
    for i = 2, n do
        local line = _G["WeintCodexScanTipTextLeft" .. i]
        local txt = line and line:GetText()
        if txt and txt:find(SOCKET_BONUS_PREFIX, 1, true) then
            local active = IsGreenLine(line)
            local stat, value = ParseStatText(txt)
            local clean = txt:gsub("^%s*" .. SOCKET_BONUS_PREFIX .. "%s*", "")
            if stat and value then
                return { stat = stat, value = value }, clean, active
            end
            return nil, clean, active
        end
    end
    return nil, nil, nil
end

--------------------------------------------------
-- ANGELEGTE VERZAUBERUNG IDENTIFIZIEREN
--
-- Der Item-Tooltip ist die Wahrheit, nicht unsere ID-Tabelle. Zwei
-- Erkennungswege, weil der Client die Verzauberung je nach Build als
-- Namenszeile ODER als reine Effektzeile ausgibt:
--
--   A) "Verzaubert: <Name>"  (ENCHANT_LINE_PATTERN)
--   B) erste GRÜNE Zeile, die wie eine Verzauberung aussieht
--      ("+170 Meisterschaftswertung" bzw. ein Proc-Name aus der DB)
--
-- Aus dem gefundenen Text werden Stat + Wert geparst. Widerspricht das
-- dem DB-Eintrag der Verzauberungs-ID, gewinnt der Client: wir suchen
-- den Eintrag desselben Slots, der exakt zu Stat+Wert passt, und rechnen
-- ab da mit dem. Damit zeigt die Liste auch bei falsch zugeordneten IDs
-- die richtige Verzauberung an.
--------------------------------------------------

-- Grüne Zeile plausibilisieren, damit nicht z.B. eine Sockel-/Setbonus-
-- Zeile als Verzauberung durchgeht.
local function LooksLikeEnchantText(text, enchSlot)
    if text:find("^%s*%+%d") then return true end
    if not WeintCodex_Enchants then return false end
    local lower = text:lower()
    for _, db in pairs(WeintCodex_Enchants) do
        if db.name and (not enchSlot or db.slot == enchSlot)
           and lower == db.name:lower() then
            return true
        end
    end
    return false
end

-- Prüft, ob alle gescannten Stats im DB-Eintrag vorhanden sind
-- (Subset-Matching). Der Client zeigt bei mehrteiligen Enchants
-- manchmal nicht alle Stats mit erkanntem Keyword an (z.B. fehlt
-- "kritischer Trefferwert" → "crit" im ParseAllStats-Output, weil
-- der Client die Kurzform nutzt). Deshalb: DB darf MEHR Stats haben
-- als der Scan, solange alle gescannten Stats wertgenau passen.
-- Reine Wertprüfung verhindert, dass ein zufällig passender Schlüssel
-- mit anderem Wert (z.B. strength=180 vs. DB strength=170) als Match gilt.
local function StatsMatch(dbStats, scanned)
    if not (dbStats and scanned) then return false end
    local n = 0
    for key, value in pairs(scanned) do
        if dbStats[key] ~= value then return false end
        n = n + 1
    end
    return n > 0
end

-- EINE WERTZEILE IST KEIN NAME.
--
-- "+894 Meisterschaft" ist der Meisterschaftswert des GEGENSTANDS, nicht
-- die Verzauberung "Meisterschaft" (Handgelenke, ID 4411) — auch wenn der
-- Name unserer Datenbank buchstäblich in der Zeile steht. Genau daran ist
-- 2.0.1.0 ein korrekt mit "+180 Stärke" verzaubertes Paar Armschienen als
-- "Meisterschaft" in der Liste gelandet: der Namensvergleich unten arbeitet
-- bewusst mit Enthaltensein, und vier Einträge der Verzauberungstabelle
-- heißen schlicht wie ein Stat ("Meisterschaft", "Präzision", "Verschwimmen",
-- "Koloss"). Der Treffer stand in RankEnchantCandidate auf Rang 1 und schlug
-- damit die echte Verzauberungszeile zwei Zeilen tiefer.
--
-- Eine Zeile, die mit "+<Zahl>" beginnt, wird deshalb NIE über ihren Text
-- identifiziert, sondern ausschliesslich über ihre Werte (Größenordnung,
-- Slot + Stats). Das ist keine Zusatzprüfung, sondern die Trennlinie
-- zwischen den beiden Erkennungswegen: Weg A liest Namen, Weg B liest
-- Zahlen — und beides zu vermischen war der Fehler.
local function LooksLikeStatValueLine(text)
    return text:find("^%s*%+%s*%d") ~= nil
end

-- Viele Berufs-Verzauberungen zeigt der Client mit einem Kategorie-
-- Präfix an ("Nebenhand - Großes Parieren", "Schild - Großes Parieren"),
-- unsere DB speichert nur den reinen Namen ("Großes Parieren"). Exakter
-- Stringvergleich würde diese sonst identisch bewerteten Verzauberungen
-- als unbekannt/"nicht ideal" melden, obwohl exakt die Empfehlung
-- angelegt ist. Ein Enthaltsein-Check (in beide Richtungen, falls die
-- DB selbst mal ein Präfix trägt) deckt Gleichheit UND Präfix-Fälle ab.
local function EnchantNamesMatch(tooltipName, dbName)
    if not (tooltipName and dbName) then return false end
    if LooksLikeStatValueLine(tooltipName) then return false end
    local a, b = tooltipName:lower(), dbName:lower()
    return a == b or a:find(b, 1, true) ~= nil or b:find(a, 1, true) ~= nil
end

local function FindEnchantByName(enchSlot, name)
    if not (WeintCodex_Enchants and name) then return nil end
    for id, db in pairs(WeintCodex_Enchants) do
        if db.name and EnchantNamesMatch(name, db.name)
           and (not enchSlot or db.slot == enchSlot) then
            return id, db
        end
    end
    return nil
end

-- Sucht den Verzauberungseintrag desselben Slots, der zu den gescannten
-- Stats passt. Mehrdeutig (mehrere Treffer mit unterschiedlichem Namen)
-- => nil, dann lieber nichts korrigieren.
--
-- ZWEI DURCHGÄNGE (seit 2.0.0.3): erst wertgenau (StatsMatch), dann
-- toleranter über SM.SameFamily. Der zweite Durchgang existiert, weil in
-- data/enchants.lua mehrfach ein leicht falscher Zahlenwert stand — die
-- Handgelenks-Stärke etwa jahrelang als 170 statt der tatsächlichen 180.
-- Wertgenau betrachtet war die angelegte Verzauberung damit "unbekannt",
-- obwohl Slot und Stat eindeutig auf genau diesen Eintrag zeigten. Der
-- Toleranzdurchgang erkennt ihn wieder; angezeigt und gerechnet wird
-- danach trotzdem mit den Werten aus dem Tooltip, nicht mit unseren.
local function FindEnchantByStats(enchSlot, scanned)
    if not (WeintCodex_Enchants and enchSlot and scanned) then return nil end

    local function Search(predicate)
        local foundId, foundDb = nil, nil
        for id, db in pairs(WeintCodex_Enchants) do
            if db.slot == enchSlot and db.stats and predicate(db.stats, scanned) then
                if foundDb and (foundDb.name or "") ~= (db.name or "") then
                    return nil
                end
                foundId, foundDb = foundId or id, foundDb or db
            end
        end
        return foundId, foundDb
    end

    local id, db = Search(StatsMatch)
    if db then return id, db end
    return Search(function(dbStats, s) return SM.SameFamily(s, dbStats) end)
end

--------------------------------------------------
-- KANDIDATENBEWERTUNG FÜR WEG B (s.u.)
--
-- Rang 1 ist der sicherste Treffer, Rang 5 die Notlösung, nil = verwerfen.
-- Ohne diese Rangfolge nahm der Scan die ERSTE plausible grüne Zeile, deren
-- Statschlüssel sich mit dem DB-Eintrag überschnitten — und die Primärwerte
-- des Gegenstands selbst ("+1300 Beweglichkeit") tragen dieselben deutschen
-- Langformen wie eine Verzauberung. Auf einem Beweglichkeitsteil mit
-- Beweglichkeits-Verzauberung gewann deshalb die Item-Zeile, und im
-- Charakterfenster stand als "Verzauberung" der Primärwert des Items.
--------------------------------------------------

-- Höchster Statwert, den eine MoP-Verzauberung liefert (Eisenschuppen-
-- beinrüstung, +430 Ausdauer) plus Reserve für Berufs-Exklusivvarianten.
-- Alles darüber ist ein Gegenstandswert, keine Verzauberung.
--
-- Seit 2.0.0.4 ist das die TRAGENDE Unterscheidung und nicht mehr die letzte
-- Notbremse: SM.STAT_KEYWORDS liest jetzt auch die Kurzformen des Clients,
-- also lesen sich Gegenstands- und Verzauberungszeile gleich gut. Was sie
-- trennt, ist ihre Größenordnung — auf Ausrüstung dieser Stufe stehen
-- vierstellige Werte, eine Verzauberung bleibt dreistellig. Damit die
-- Grenze überhaupt greift, muss die Zahl richtig gelesen werden: "+1.201
-- Meisterschaft" sind 1201 und nicht 1 (siehe SM.ParseNumber).
local MAX_ENCHANT_VALUE = 600

-- Umgeschmiedete Werte tragen ihre Herkunft im Text ("+298 Parieren
-- (Umgeschmiedet aus Waffenkunde)"). Das ist immer eine Zeile des
-- Gegenstands und nie eine Verzauberung — und sie liegt mit ihren knapp
-- 300 Punkten mitten im plausiblen Bereich, wäre über die Größenordnung
-- also nicht auszusortieren.
local REFORGE_MARKERS = { "umgeschmiedet", "reforged" }
do
    local global = _G.ITEM_REFORGED
    if type(global) == "string" and global ~= "" then
        REFORGE_MARKERS[#REFORGE_MARKERS + 1] = global:lower()
    end
end

local function IsReforgeLine(text)
    local lower = text:lower()
    for _, marker in ipairs(REFORGE_MARKERS) do
        if lower:find(marker, 1, true) then return true end
    end
    return false
end

local function RankEnchantCandidate(text, scanned, enchSlot, dbStats)
    -- Rang 1: der Text IST der Name einer Verzauberung dieses Slots.
    -- Für Wertzeilen ("+894 Meisterschaft") kann dieser Rang nicht mehr
    -- greifen — EnchantNamesMatch lehnt sie ab, weil ihre Aussage in den
    -- Zahlen steckt und nicht im Stat-Wort (siehe dort). Vorher gewann
    -- der Gegenstandswert genau hier gegen die echte Verzauberung: Rang 1
    -- wird VOR der Größenordnung geprüft, "+894 Meisterschaft" kam also
    -- nie bis zur Grenze von MAX_ENCHANT_VALUE.
    if FindEnchantByName(enchSlot, text) then return 1 end

    -- Rang 4: gar keine Zahl → Proc-/Namenszeile, es gibt nichts zu prüfen.
    --
    -- Eine Zeile MIT Zahl, aus der sich kein Wert lesen liess, ist dagegen
    -- keine Namenszeile, sondern eine Zeile, die wir nicht verstehen — die
    -- gehört verworfen. Bis 2.0.0.3 stand hier
    --     return text:find("%+%d") and nil or 4
    -- und das ergibt in Lua IMMER 4: der mittlere Zweig ist nil, also
    -- greift das `or`. Jede unverstandene Gegenstandszeile wurde damit zum
    -- Kandidaten, und weil bei Gleichstand auf Rang 4 die erste Zeile
    -- gewinnt, war das die oberste — der Gegenstandswert. Das ist der
    -- Grund, aus dem auf den Handschuhen des Fehlerberichts "+1.201
    -- Meisterschaft" als Verzauberung stand, obwohl die empfohlene "+170
    -- Tempo" zwei Zeilen darunter lag: unlesbar waren beide, und die
    -- obere gewann.
    if not scanned then
        if text:find("%d") then return nil end
        return 4
    end

    -- Größenordnung, bevor irgendetwas zugeordnet wird.
    for _, value in pairs(scanned) do
        if value > MAX_ENCHANT_VALUE then return nil end
    end

    -- Rang 2: die Werte identifizieren eine Verzauberung dieses Slots.
    if FindEnchantByStats(enchSlot, scanned) then return 2 end

    -- Rang 3: die Werte überschneiden sich mit dem DB-Eintrag DIESER ID.
    if dbStats then
        for key in pairs(scanned) do
            if dbStats[key] then return 3 end
        end
    end

    -- Rang 5: plausible Größenordnung — mehr wissen wir nicht. Das gilt
    -- allerdings nur, wenn wir zu dieser ID wirklich nichts wissen. Steht
    -- in data/enchants.lua ein Eintrag und passt keine Zeile des Tooltips
    -- dazu, ist nicht die Datenbank falsch, sondern der Scan gescheitert —
    -- dann ist ihr Name die ehrlichere Antwort als eine geratene
    -- Gegenstandszeile.
    if dbStats then return nil end
    return 5
end

-- Liefert { name = <Tooltiptext>, stats = { key = value } | nil } oder nil,
-- wenn im Tooltip keine Verzauberungszeile gefunden wurde.
local function ScanEquippedEnchant(slotId, enchantId, link, enchSlot)
    if not enchantId then return nil end
    local cached = WeintCodex._enchantTooltipCache[enchantId]
    if cached then return cached end

    scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTip:ClearLines()
    scanTip:SetInventoryItem("player", slotId)
    local n = scanTip:NumLines() or 0

    local found = nil

    -- Weg A zuerst über alle Zeilen (eindeutig, hat Vorrang)
    for i = 2, n do
        local line = _G["WeintCodexScanTipTextLeft" .. i]
        local txt  = line and line:GetText()
        if txt then
            local name = txt:match(ENCHANT_LINE_PATTERN)
            if name and name ~= "" then
                found = name
                break
            end
        end
    end

    -- Weg B: die am besten passende grüne, plausible Zeile.
    --
    -- HINTERGRUND: In MoP Classic sind Item-Werte (Trefferwert, Ausweichen,
    -- Parieren, Kritischer Trefferwert …) ebenfalls grüne "+Zahl"-Zeilen.
    -- Sie erscheinen IM TOOLTIP VOR der eigentlichen Verzauberungszeile und
    -- würden ohne weitere Prüfung fälschlicherweise eingelesen.
    --
    -- Bis 2.0.0.3 sortierte sie ein Zufall aus: der Client schreibt die
    -- Werte in Kurzform ("Meisterschaft", "Tempo", "Parieren"), und die
    -- Schlüsselwortliste kannte nur die Langformen — die Zeilen waren also
    -- unlesbar und fielen aus dem Parser. Nur schreibt der Client die
    -- Verzauberung GENAUSO ("+170 Tempo"), womit die richtige Zeile
    -- ebenfalls unlesbar war. Beide standen damit auf demselben Rang, und
    -- der ging an die obere: den Gegenstandswert.
    --
    -- Gelesen werden jetzt beide (SM.STAT_KEYWORDS kennt die Kurzformen),
    -- und unterschieden werden sie an dem, was sie wirklich unterscheidet:
    --   * umgeschmiedete Werte nennen ihre Herkunft im Text,
    --   * Gegenstandswerte dieser Stufe sind vierstellig, Verzauberungen
    --     bleiben unter MAX_ENCHANT_VALUE,
    --   * und was zu einem Eintrag in data/enchants.lua passt, schlägt
    --     ohnehin alles andere (RankEnchantCandidate).
    --
    -- Bei Gleichstand gewinnt für die Ränge 1–4 die ERSTE Zeile (eindeutige
    -- Treffer, Reihenfolge egal), für Rang 5 die LETZTE: die Werte des
    -- Gegenstands stehen im Tooltip oben, die Verzauberung darunter.
    if not found then
        local db      = WeintCodex_Enchants and WeintCodex_Enchants[enchantId]
        local dbStats = db and db.stats
        local bestRank = nil

        for i = 2, n do
            local line = _G["WeintCodexScanTipTextLeft" .. i]
            local txt  = line and line:GetText()
            if txt and txt ~= ""
               and not txt:find(SOCKET_BONUS_PREFIX, 1, true)
               and not IsReforgeLine(txt)
               and IsGreenLine(line)
               and LooksLikeEnchantText(txt, enchSlot) then

                local scanned = ParseAllStats(txt)
                local rank    = RankEnchantCandidate(txt, scanned, enchSlot, dbStats)

                if rank and (not bestRank
                             or rank < bestRank
                             or (rank == bestRank and rank == 5)) then
                    found, bestRank = txt, rank
                end
            end
        end
    end

    if not found then
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

    local info = { name = found, stats = ParseAllStats(found) }
    WeintCodex._enchantTooltipCache[enchantId] = info
    return info
end

-- Welche Werte gelten, wenn Tooltip und Datenbank beide etwas sagen?
-- Grundsatz bleibt: der Tooltip ist die Wahrheit. Er ist aber lückenhaft —
-- bei mehrteiligen Verzauberungen gibt der Client einen Teil in Kurzform
-- aus, die SM.STAT_KEYWORDS nicht kennt. Daher:
--   * Tooltip kennt nur eine ECHTE Teilmenge der DB-Schlüssel
--     -> DB (sie ist vollständiger, der Scan hat etwas verschluckt)
--   * sonst -> Tooltip, auch bei abweichendem Zahlenwert. Genau so ist die
--     170/180-Altlast bei den Handgelenken überhaupt erst sichtbar geworden.
local function PreferredEnchantStats(dbStats, scanned)
    if not scanned then return dbStats end
    if not dbStats  then return scanned end

    local scanIsSubset = true
    for key in pairs(scanned) do
        if not dbStats[key] then scanIsSubset = false; break end
    end
    local scanIsComplete = true
    for key in pairs(dbStats) do
        if not scanned[key] then scanIsComplete = false; break end
    end

    if scanIsSubset and not scanIsComplete then return dbStats end
    return scanned
end

-- Ergebnis:
--   id          effektive Verzauberungs-ID (ggf. korrigiert)
--   name        anzuzeigender Name
--   stats       Stats der Verzauberung (Tooltip bevorzugt)
--   scanned     ausschliesslich die vom Item-Tooltip gelesenen Werte
--               (Grundlage des Werteabgleichs in EvaluateEnchant)
--   mismatch    Tooltip und DB widersprechen sich (Werte oder ID)
--   unknownName der Client nennt die Verzauberung anders als die DB,
--               ohne Werte zum Gegenprüfen — kein Widerspruch, nur eine
--               Lücke in unserer Namenspflege
--   corrected   ID wurde über Slot+Stats ersetzt
--   unverified  kein Live-Scan möglich (Name stammt ungeprüft aus der DB)
local function ResolveEnchant(slotId, enchId, link, enchSlot)
    if not enchId then return nil end

    local scan = ScanEquippedEnchant(slotId, enchId, link, enchSlot)
    local db   = WeintCodex_Enchants and WeintCodex_Enchants[enchId]
    local res  = { id = enchId }

    if not scan then
        res.name       = (db and db.name) or GetEnchantDisplayName(enchId)
        res.stats      = db and db.stats or nil
        res.unverified = true
        return res
    end

    res.tooltipName = scan.name
    local scanned   = scan.stats
    res.scanned     = scanned

    -- 1) DB deckt sich mit dem Tooltip: gleicher Name (der Client gibt je
    --    nach Build den Namen aus) oder exakt gleiche Stats.
    if db then
        local sameName = db.name and EnchantNamesMatch(scan.name, db.name)
        if sameName or (scanned and db.stats and StatsMatch(db.stats, scanned)) then
            res.name  = db.name or scan.name
            res.stats = PreferredEnchantStats(db.stats, scanned)
            return res
        end
    end

    -- 2) Widerspruch oder unbekannte ID: den passenden Eintrag über den
    --    Client-Namen bzw. Slot + Stats suchen.
    local corrId, corrDb = FindEnchantByName(enchSlot, scan.name)
    if not corrDb and scanned then
        corrId, corrDb = FindEnchantByStats(enchSlot, scanned)
    end
    if corrDb then
        res.id        = corrId
        res.name      = corrDb.name
        res.stats     = PreferredEnchantStats(corrDb.stats, scanned)
        res.corrected = (corrId ~= enchId)
        res.mismatch  = (db ~= nil) and res.corrected or false
        return res
    end

    -- 3) Nichts Passendes gefunden: ehrlich den Tooltip-Text zeigen.
    --
    -- WIE LAUT WIR WERDEN, ENTSCHEIDET, WAS DIE ZEILE HERGIBT.
    -- Eine Zeile MIT Werten, zu der kein Eintrag dieses Slots passt,
    -- widerspricht unserer Tabelle tatsächlich — genau dafür ist die
    -- Warnung da (falsch zugeordnete IDs gab es mehrfach: 4412/4415,
    -- 4430/4432). Eine reine NAMENSZEILE ohne Werte widerspricht ihr
    -- dagegen nicht. Sie sagt nur: den Client-Namen dieser ID kennen wir
    -- nicht — und der Name ist das unzuverlässigste Feld von
    -- data/enchants.lua. Er ist von Hand gepflegt, MoP-Verzauberungs-IDs
    -- lassen sich am Client nicht auflösen, und Blizzard hat die deutschen
    -- Namen mitten in der Erweiterung umbenannt (dieselbe Ursache wie bei
    -- den Steinen, siehe Kopf von data/gems.lua).
    --
    -- Daran hing der Fehlalarm "Verzauberungs-ID 4416 (Handgelenke) passt
    -- nicht zur Datenbank": angelegt war die richtige Verzauberung, ihr
    -- Name stand hier nur anders. Eine Warnung, die den Nutzer auf einen
    -- Mangel stösst, den es nicht gibt, ist schlechter als keine.
    res.name = scan.name
    if scanned then
        res.stats    = scanned
        res.mismatch = (db ~= nil)
    else
        -- Ohne gelesene Werte sind die Zahlen der DB das Beste, was wir
        -- haben — der Cap-Abgleich und der Werteabgleich brauchen sie.
        -- Die Zeile sagt selbst dazu, dass der Name ungeprüft ist.
        res.stats       = db and db.stats or nil
        res.unknownName = (db ~= nil)
    end
    return res
end

--------------------------------------------------
-- WAFFEN-/NEBENHAND-ERKENNUNG
--
-- Entscheidend ist nicht die Gegenstandsklasse (ein Schild ist
-- Klasse 4 = Rüstung, keine Waffe), sondern der Anlegeplatz. Nur
-- itemEquipLoc sagt zuverlässig, ob ein Zweihänder angelegt ist und
-- ob die Nebenhand eine Waffe, einen Schild oder einen Beihand-
-- Gegenstand trägt — und davon hängt ab, welcher Verzauberungs-Topf
-- gilt und wie viele Slots überhaupt zählen können.
--
-- In MoP ist die Nebenhand IMMER verzauberbar:
--   Waffe            -> Waffenverzauberungen (Lied des Windes usw.)
--   Schild           -> "Großes Parieren" oder "Mächtige Intelligenz"
--   Beihand-Gegenst. -> "Mächtige Intelligenz"
-- (siehe data/enchants.lua, Block NEBENHAND)
--------------------------------------------------

local EQUIP_LOC_KIND = {
    INVTYPE_WEAPON         = "weapon",
    INVTYPE_WEAPONMAINHAND = "weapon",
    INVTYPE_WEAPONOFFHAND  = "weapon",
    INVTYPE_2HWEAPON       = "weapon",
    INVTYPE_RANGED         = "weapon",
    INVTYPE_RANGEDRIGHT    = "weapon",
    INVTYPE_SHIELD         = "shield",
    INVTYPE_HOLDABLE       = "holdable",
}

-- "weapon" | "shield" | "holdable" | nil (Item-Infos noch nicht im Cache)
local function ClassifyEquipLoc(link)
    if not link then return nil end
    if GetItemInfoInstant then
        local _, _, _, equipLoc = GetItemInfoInstant(link)
        if equipLoc and equipLoc ~= "" then return EQUIP_LOC_KIND[equipLoc] end
    end
    local equipLoc = select(9, GetItemInfo(link))
    if equipLoc and equipLoc ~= "" then return EQUIP_LOC_KIND[equipLoc] end
    -- Weder Instant- noch Voll-Infos verfügbar: nicht raten. Der Aufrufer
    -- behandelt nil als "noch unbekannt" und lässt neu scannen, statt den
    -- Slot still aus der Wertung zu nehmen.
    return nil
end

--------------------------------------------------
-- BELEGT DIE HAUPTWAFFE BEIDE HAENDE?
--
-- Die Frage ist NICHT "ist das ein Zweihänder". Ein Jäger trägt in MoP
-- seine Distanzwaffe in der Haupthand, und der Nebenhand-Slot ist für
-- ihn schlicht nicht benutzbar — der Anlegeplatz eines Bogens heisst
-- aber `INVTYPE_RANGED` und nicht `INVTYPE_2HWEAPON`. Ein reiner
-- Vergleich gegen den Zweihänder meldete deshalb jedem Jäger
-- dauerhaft "Nebenhand: Kein Gegenstand angelegt" — ein Mangel, den er
-- gar nicht beheben kann.
--
-- Der Anlegeplatz allein reicht dafür nicht: `INVTYPE_RANGEDRIGHT`
-- tragen in MoP sowohl Schusswaffen und Armbrüste (belegen beide
-- Hände) als auch Zauberstäbe (tun es nicht — ein Caster mit
-- Zauberstab hat sehr wohl eine Nebenhand). Entschieden wird deshalb
-- über die Waffen-Unterklasse.
--------------------------------------------------

local RANGED_EQUIP_LOC = {
    INVTYPE_RANGED      = true,
    INVTYPE_RANGEDRIGHT = true,
}

-- Bogen (2), Schusswaffe (3), Armbrust (18). Zauberstab ist 19 und
-- steht bewusst nicht hier.
local BOTH_HANDS_SUBCLASS = { [2] = true, [3] = true, [18] = true }

-- Anlegeplatz + Waffen-Unterklasse, aus welcher Quelle auch immer.
local function ItemEquipInfo(link)
    if not link then return nil, nil end
    if GetItemInfoInstant then
        local _, _, _, equipLoc, _, _, subclassId = GetItemInfoInstant(link)
        if equipLoc and equipLoc ~= "" then return equipLoc, subclassId end
    end
    local equipLoc   = select(9,  GetItemInfo(link))
    local subclassId = select(13, GetItemInfo(link))
    if equipLoc and equipLoc ~= "" then return equipLoc, subclassId end
    return nil, nil
end

-- true / false / nil. nil heisst "Item-Infos noch nicht im Cache" — der
-- Aufrufer behauptet dann nichts, statt zu raten.
local function OccupiesBothHands(link)
    local equipLoc, subclassId = ItemEquipInfo(link)
    if not equipLoc then return nil end

    if equipLoc == "INVTYPE_2HWEAPON" then return true end
    if not RANGED_EQUIP_LOC[equipLoc] then return false end

    if type(subclassId) == "number" then
        return BOTH_HANDS_SUBCLASS[subclassId] == true
    end

    -- Unterklasse nicht lesbar: der Jäger ist in MoP der Einzige, der
    -- eine Distanzwaffe in der Haupthand führt, und er hat nie eine
    -- Nebenhand. Für alle anderen bleibt es beim Zauberstab.
    return select(2, UnitClass("player")) == "HUNTER"
end

-- Verzauberungs-Topf für den Nebenhand-Slot.
local OFFHAND_ENCH_SLOT = {
    weapon   = "Waffe",
    shield   = "Nebenhand",
    holdable = "Nebenhand",
}

--------------------------------------------------
-- VERZAUBERKUNST
-- Ringe kann nur verzaubern, wer den Beruf selbst geskillt hat.
-- Ohne Beruf entsteht gar keine Ring-Zeile, sonst hätten
-- Nicht-Verzauberer dauerhaft zwei "fehlende" Verzauberungen.
-- Abgleich über die Skill-Line-ID (333), nicht über den Namen —
-- der Client ist lokalisiert.
--------------------------------------------------

local ENCHANTING_SKILL_LINE = 333

local function HasEnchanting()
    if enchantingKnown ~= nil then return enchantingKnown end
    enchantingKnown = false
    if type(GetProfessions) == "function" and type(GetProfessionInfo) == "function" then
        local prof1, prof2 = GetProfessions()
        for _, index in ipairs({ prof1, prof2 }) do
            if index then
                local skillLine = select(7, GetProfessionInfo(index))
                if skillLine == ENCHANTING_SKILL_LINE then
                    enchantingKnown = true
                    break
                end
            end
        end
    end
    return enchantingKnown
end

-- Effektiver Verzauberungs-Topf eines Slots samt Nebenhand-Art.
-- Rueckgabe: enchSlot ("Waffe"/"Nebenhand"/... oder nil), offhandKind.
-- enchSlot == nil heisst "zaehlt nicht" — entweder weil der Slot gar nicht
-- verzauberbar ist, weil der Beruf fehlt, oder weil die Item-Infos noch
-- nicht im Cache sind (dann wurde die Nachlieferung vorgemerkt).
local function ResolveEnchSlot(slotDef, link)
    if slotDef.nurVerzauberer and not HasEnchanting() then
        return nil, nil
    end
    if not slotDef.enchSlotDynamisch then
        return slotDef.enchSlot, nil
    end

    -- Nebenhand: Waffe, Schild und Beihand-Gegenstand sind in MoP alle
    -- verzauberbar, aber aus unterschiedlichen Toepfen.
    local kind = ClassifyEquipLoc(link)
    if not kind then
        NotePendingItemInfo(link)
        return nil, nil
    end
    return OFFHAND_ENCH_SLOT[kind], kind
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
-- TEMPO-SCHWELLEN: TREPPE, ZIEL UND UMSCHMIEDE-RESERVE
--
-- Treffer und Waffenkunde sind Decken: darueber ist jeder Punkt wertlos,
-- und BuildCapStates rechnet genau damit. Tempo hat keine Decke, sondern
-- eine Treppe (siehe data/breakpoints.lua) — und deshalb konnte das Addon
-- bis 2.6.1.1 gar nicht wissen, wann ein Tempostein nichts mehr bringt.
-- Gemeldet wurde genau das: "es wird immer noch ein Tempostein
-- vorgeschlagen, obwohl man am Cap ist".
--
-- DIE ENTSCHEIDUNG IST NICHT "WELCHE STUFE IST DIE RICHTIGE", SONDERN
-- "IST DIE NAECHSTE UEBERHAUPT ZU ERREICHEN".
--
-- Welche Stufe man anpeilt, haengt an Ausruestungsstand, Raidbuffs und
-- Guide — nichts davon steht in einer Tabelle, die wir pflegen koennten,
-- und eine hineingeschriebene Wunschzahl waere genau die Sorte
-- Handpflege, an der data/enchants.lua schon zweimal gescheitert ist.
-- Was sich dagegen ausrechnen laesst, ist die REICHWEITE: wieviel
-- Wertung durch Umschmieden und durch die Sockel ueberhaupt noch zu
-- bewegen ist. Daraus folgt das Ziel von selbst:
--
--   * Liegt eine Stufe innerhalb der Reichweite, ist die hoechste davon
--     das Ziel — Tempo zaehlt bis dorthin und der Planer darf Tempo
--     empfehlen.
--   * Liegt keine mehr drin, ist die zuletzt erreichte Stufe das Ende.
--     Weiteres Tempo bringt keinen Tick mehr, der Spielraum ist 0, und
--     was darueber liegt, gehoert umgeschmiedet. Das ist der Fall aus
--     dem Fehlerbericht.
--   * Ist noch keine Stufe erreicht UND keine in Reichweite, wird
--     NICHTS behauptet: Tempo bleibt ungecappt wie bisher. Eine Aussage
--     ueber unsere Rechenlage ist keine Aussage ueber die Ausruestung.
--
-- Die Reichweite ist bewusst eine OBERGRENZE (jede Umschmiedung zaehlt
-- mit ihrem groesstmoeglichen Anteil, jeder Sockel mit einem vollen
-- Sekundaerstein). Eine zu grosse Reichweite laesst die Stufe als
-- erreichbar gelten und aendert dann gar nichts — eine zu kleine wuerde
-- Tempo kappen, das noch etwas bringt. Von zwei Irrtuemern ist das der
-- harmlose.
--
-- Und der Spieler behaelt das letzte Wort: das Ziel laesst sich auf der
-- Seite "Werteverteilung & Caps" auf jede Stufe der Treppe setzen oder
-- ganz abschalten. Wer eine Stufe ueber einen Schmuckproc erreicht, weiss
-- mehr als diese Rechnung.
--------------------------------------------------

-- Kampfwertungsindizes des Clients (dieselbe Numerierung wie CR_INDEX oben).
local CR_HASTE_INDEX = { melee = 18, ranged = 19, spell = 20 }
local CR_CRIT_INDEX  = { melee = 9,  ranged = 10, spell = 11 }

-- Nur Rueckfall, falls der Charakterbogen keinen Quotienten hergibt
-- (Stufe 90). Gerechnet wird sonst mit dem, was der Client selbst meldet.
local THRESHOLD_RATING_FALLBACK = { haste = 425, crit = 600, mastery = 600 }

local THRESHOLD_LABEL = {
    haste = { melee = "Tempo (Nahkampf)", ranged = "Tempo (Fernkampf)",
              spell = "Tempo (Zauber)" },
    crit  = { melee = "Kritische Trefferchance", ranged = "Kritische Trefferchance",
              spell = "Kritische Zaubertrefferchance" },
}

-- Ein reiner Sekundaerstein bringt in MoP 320 Wertung. Die Zahl steht hier
-- als Obergrenze fuer "was koennten die Sockel noch beitragen" — nicht als
-- Empfehlung, die trifft weiterhin PlanItem.
local SECONDARY_GEM_RATING = 320

-- Umschmieden verschiebt 40 % EINES Sekundaerwerts eines Gegenstands in
-- einen anderen, den der Gegenstand nicht bereits traegt.
--
-- Die Zahl steht seit 2.7.0.0 in data/reforge.lua, weil der
-- Umschmiede-Planer mit derselben rechnet. Zwei Konstanten fuer dieselbe
-- Zahl waeren genau die Doppelung, aus der Empfehlung und Urteil
-- auseinanderlaufen; der Rueckfall hier gilt nur, falls die Datendatei
-- einmal nicht geladen ist.
local REFORGE_SHARE = (WeintCodex_Reforge and WeintCodex_Reforge.COEFF) or 0.4
local REFORGE_STATS = {
    crit = true, haste = true, mastery = true, hit = true,
    expertise = true, dodge = true, parry = true, spirit = true,
}

local function SafeNum(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, ...)
    if ok and type(value) == "number" then return value end
    return nil
end

-- Der GESAMTWERT laut Charakterbogen, also inklusive Raidbuffs — das ist
-- die Zahl, an der die Ticks haengen. Antwortet der Client nicht, ist das
-- Ergebnis nil und es wird nichts behauptet.
local function LiveTotalPct(stat, typ)
    if stat == "haste" then
        if typ == "spell" then
            return SafeNum(_G.UnitSpellHaste, "player") or SafeNum(_G.GetHaste)
        elseif typ == "ranged" then
            return SafeNum(_G.GetRangedHaste) or SafeNum(_G.GetHaste)
        end
        return SafeNum(_G.GetMeleeHaste) or SafeNum(_G.GetHaste)
    elseif stat == "crit" then
        if typ == "spell" then
            local best
            for school = 2, 7 do
                local v = SafeNum(_G.GetSpellCritChance, school)
                if v and (not best or v > best) then best = v end
            end
            return best
        elseif typ == "ranged" then
            return SafeNum(_G.GetRangedCritChance)
        end
        return SafeNum(_G.GetCritChance)
    end
    return nil
end

-- Anteil, der aus der WERTUNG kommt, und wieviel Wertung ein Prozentpunkt
-- davon kostet.
local function RatingBasis(stat, typ)
    local idx = (stat == "haste") and CR_HASTE_INDEX[typ or "melee"]
             or (stat == "crit")  and CR_CRIT_INDEX[typ or "melee"]
             or nil
    local rating = idx and SafeNum(_G.GetCombatRating, idx) or 0
    local bonus  = idx and SafeNum(_G.GetCombatRatingBonus, idx) or 0
    local perPct = THRESHOLD_RATING_FALLBACK[stat] or RATING_PER_PCT_FALLBACK
    if bonus > 0.05 and rating > 0 then
        perPct = rating / bonus
    end
    return rating, bonus, perPct
end

-- Wieviel Wertung kostet EIN PROZENTPUNKT GESAMTWERT?
--
-- Buffs wirken multiplikativ: mit 5 % Raidtempo macht ein Prozentpunkt aus
-- der Wertung 1,05 Prozentpunkte auf dem Charakterbogen. Wer den Abstand
-- zur naechsten Stufe (ein Gesamtwert!) mit der reinen Wertungsumrechnung
-- multipliziert, verlangt deshalb zu viel Wertung. Der Faktor faellt aus
-- den beiden Zahlen heraus, die der Client ohnehin meldet.
local function BuffFactor(totalPct, ratingPct)
    if not totalPct or not ratingPct then return 1 end
    local f = (1 + totalPct / 100) / (1 + ratingPct / 100)
    if f < 0.5 or f > 2 then return 1 end   -- unplausibel: lieber nicht rechnen
    return f
end

--------------------------------------------------
-- UMSCHMIEDE-RESERVE (Obergrenze)
--
-- Je angelegtem Gegenstand laesst sich 40 % EINES Sekundaerwerts
-- verschieben. Was in `stat` hinein kann, kommt deshalb nur von
-- Gegenstaenden, die `stat` noch NICHT tragen; was heraus kann, nur von
-- denen, die ihn tragen.
--
-- Bewusst eine Obergrenze und als solche beschriftet: die Werte kommen aus
-- GetItemStats, und ob der Client eine bereits umgeschmiedete Verteilung
-- oder die des Grundgegenstands meldet, ist von hier aus nicht zu belegen.
-- Fuer die Frage "ist die naechste Stufe ueberhaupt erreichbar" ist die
-- Obergrenze die richtige Richtung (siehe oben).
--------------------------------------------------

local function ReforgeReserve(stat)
    local gain, drop = 0, 0
    for _, slotDef in ipairs(EQUIP_SLOTS) do
        local link = GetInventoryItemLink("player", slotDef.id)
        local stats = link and SM.ItemStats and SM.ItemStats(link)
        if stats then
            local own = stats[stat]
            if own and own > 0 then
                drop = drop + own * REFORGE_SHARE
            else
                local biggest = 0
                for key, value in pairs(stats) do
                    if REFORGE_STATS[key] and value > biggest then biggest = value end
                end
                gain = gain + biggest * REFORGE_SHARE
            end
        end
    end
    return gain, drop
end

-- Was koennten die Sockel noch beitragen? Auch das eine Obergrenze: jeder
-- Sockel mit einem vollen Sekundaerstein, ohne Ruecksicht darauf, was dort
-- gerade steckt. Gezaehlt wird ueber den billigen Weg (wantColors = false,
-- dieselbe Ueberlegung wie im Gruppencheck) — hier zaehlt die Anzahl,
-- nicht die Farbe.
local function SocketReserve()
    local count = 0
    for _, slotDef in ipairs(EQUIP_SLOTS) do
        local link = GetInventoryItemLink("player", slotDef.id)
        if link then
            local sockets = ScanItemSockets(link, slotDef.id, false)
            count = count + #sockets
        end
    end
    return count * SECONDARY_GEM_RATING, count
end

--------------------------------------------------
-- ZIEL DES SPIELERS (überschreibt die Rechnung)
--   mode = "auto"   die Rechnung oben entscheidet (Vorgabe)
--   mode = "aus"    keine Schwelle, Tempo zaehlt wie bisher unbegrenzt
--   mode = "stufe"  feste Stufe, `pct` ist ihr Prozentwert
--------------------------------------------------

local function StatTargetStore(create)
    local sd = WeintCodex.SavedData
    if not sd then return nil end
    if not sd.statTargets then
        if not create then return nil end
        sd.statTargets = {}
    end
    return sd.statTargets
end

local function StatTargetKey(profileKey, tankStyle)
    return GetEffectiveProfileKey(profileKey, tankStyle)
end

local function GetStatTarget(profileKey, tankStyle, stat)
    local store = StatTargetStore(false)
    local key   = StatTargetKey(profileKey, tankStyle)
    local perSpec = store and key and store[key]
    return perSpec and perSpec[stat] or nil
end

function WeintCodex.Charakter.SetStatTarget(stat, entry)
    local _, profileKey, tankStyle = GetCurrentSpecProfile()
    local key = StatTargetKey(profileKey, tankStyle)
    if not key then return end
    local store = StatTargetStore(true)
    if not store then return end
    store[key] = store[key] or {}
    store[key][stat] = entry
    -- Kein Cache zu leeren: ScanCharacter rechnet bei jedem Aufbau neu,
    -- und die Aufrufer zeichnen die Seite direkt danach.
end

--------------------------------------------------
-- ZUSTAND EINER TEMPO-TREPPE
--
-- Rueckgabe je Eintrag in data/breakpoints.lua eine Tabelle mit denselben
-- Feldnamen wie ein Cap-Zustand (`current`, `capPct`, `overPct`,
-- `overRating`, `underRating`, `label`, `wasted`), damit der Overcap-Pass
-- und die Balken sie ohne Sonderfall lesen — plus dem, was nur eine Treppe
-- hat: `ladder`, `reached`, `nextRung`, `target`, `reforgeGain/Drop`,
-- `socketReserve`, `reach`.
--
-- `capPct == nil` heisst ausdruecklich "kein Ziel": weder gekappt noch
-- erreicht, und dann sagt die Seite genau das.
--------------------------------------------------

local function BuildBreakpointStates(profile, profileKey, tankStyle)
    local states = {}
    if not profile or not profileKey then return states end
    if type(WeintCodex_BreakpointLadder) ~= "function" then return states end

    -- Der Tankstil hat einen eigenen Profilschluessel (…_OFFENSIVE) und darf
    -- eine eigene Treppe haben; ohne einen faellt er auf die Basis-Spec
    -- zurueck, so wie bei der Ausruestung (modules/bis.lua) und anders als
    -- bei der Rotation, wo eine falsche Liste schlechter waere als keine.
    local effKey = GetEffectiveProfileKey(profileKey, tankStyle)
    local bpKey  = (WeintCodex_Breakpoints and effKey
                    and WeintCodex_Breakpoints[effKey]) and effKey or profileKey
    local def = WeintCodex_Breakpoints and WeintCodex_Breakpoints[bpKey]
    if not def then return states end

    local ladder = WeintCodex_BreakpointLadder(bpKey)
    if not ladder or #ladder == 0 then return states end

    local stat, typ = def.stat or "haste", def.typ or "spell"

    local current = LiveTotalPct(stat, typ)
    if not current then
        -- Der Client hat nicht geantwortet. Ohne den Istwert ist jede
        -- Stufenaussage geraten — also keine.
        return states
    end

    local _, ratingPct, perPctRating = RatingBasis(stat, typ)
    local buffFactor = BuffFactor(current, ratingPct)
    local perPct = perPctRating / buffFactor

    local reforgeGain, reforgeDrop = ReforgeReserve(stat)
    local socketReserve, socketCount = SocketReserve()
    local reach = reforgeGain + socketReserve

    -- Erreichte Stufe und naechste Stufe darueber.
    local reached, nextRung
    for _, rung in ipairs(ladder) do
        if rung.pct <= current + 0.001 then
            reached = rung
        elseif not nextRung then
            nextRung = rung
        end
    end

    -- Hoechste Stufe in Reichweite. Bewusst die HOECHSTE und nicht die
    -- naechste: geplant wird die ganze Ausruestung auf einmal, und wer nur
    -- bis zur naechsten Stufe rechnet, hoert nach einem einzigen Stein auf.
    local reachable
    for _, rung in ipairs(ladder) do
        if rung.pct > current and (rung.pct - current) * perPct <= reach then
            reachable = rung
        end
    end

    local target, targetSource = reachable, "auto"

    -- Der Spieler ueberschreibt.
    local own = GetStatTarget(profileKey, tankStyle, stat)
    if own and own.mode == "aus" then
        target, targetSource = nil, "aus"
    elseif own and own.mode == "stufe" and own.pct then
        target, targetSource = nil, "spieler"
        for _, rung in ipairs(ladder) do
            if math.abs(rung.pct - own.pct) < 0.01 then target = rung end
        end
        if not target then
            target = { pct = own.pct, label = own.label or "eigenes Ziel" }
        end
    end

    local state = {
        kind          = "breakpoint",
        stat          = stat,
        typ           = typ,
        label         = (THRESHOLD_LABEL[stat] and THRESHOLD_LABEL[stat][typ])
                        or THRESHOLD_LABEL.haste.spell,
        current       = current,
        perPct        = perPct,
        perPctRating  = perPctRating,
        buffFactor    = buffFactor,
        ratingPct     = ratingPct,
        ladder        = ladder,
        reached       = reached,
        nextRung      = nextRung,
        target        = target,
        targetSource  = targetSource,
        reforgeGain   = reforgeGain,
        reforgeDrop   = reforgeDrop,
        socketReserve = socketReserve,
        socketCount   = socketCount,
        reach         = reach,
        note          = def.note,
        specKey       = bpKey,
        wasted        = {},
    }

    if targetSource == "aus" then
        -- Ausdruecklich abgeschaltet: kein Ziel, kein Spielraum, keine
        -- Aussage. Tempo zaehlt wie vor 2.6.2.0.
        state.capPct      = nil
        state.headroom    = nil
    elseif target and target.pct > current then
        state.capPct      = target.pct
        state.overPct     = current - target.pct
        state.overRating  = 0
        state.underRating = (target.pct - current) * perPct
        state.headroom    = state.underRating
    elseif reached then
        -- Keine Stufe mehr in Reichweite (oder das eigene Ziel liegt
        -- bereits hinter uns): hier ist Schluss.
        state.capPct      = (target and target.pct) or reached.pct
        state.capped      = true
        state.overPct     = current - state.capPct
        state.overRating  = math.max(0, state.overPct * perPct)
        state.underRating = 0
        state.headroom    = 0
    else
        -- Noch keine Stufe erreicht und keine in Reichweite: nichts
        -- behaupten (siehe Kopf dieses Abschnitts).
        state.capPct      = nil
        state.headroom    = nil
        state.outOfReach  = true
    end

    states[#states + 1] = state
    return states
end

--------------------------------------------------
-- WOHIN MIT DEM UEBERSCHUSS?
--
-- Ueber einer Decke oder hinter der letzten erreichbaren Stufe ist
-- Wertung nicht verloren — sie steht am falschen Platz, und Umschmieden
-- ist der Weg, sie zu bewegen. Ein Befund, der das nicht mitsagt, laesst
-- den Spieler mit "verschwendet" allein; genau darum ging der
-- Fehlerbericht ("gerade weil sonst Werte umsonst sind").
--
-- Genommen wird der hoechstgewichtete Sekundaerwert, der NICHT selbst an
-- einer Grenze steht. Ohne Gewichte oder ohne Kandidaten kommt nil
-- zurueck und der Text nennt dann kein Ziel, statt eines zu erfinden.
--------------------------------------------------

local REFORGE_TARGET_LABEL = {
    crit = "kritische Trefferwertung", haste = "Tempo", mastery = "Meisterschaft",
    hit = "Trefferwertung", expertise = "Waffenkunde",
    dodge = "Ausweichen", parry = "Parieren", spirit = "Willenskraft",
}

local REFORGE_STAT_KEYS = {
    crit = true, haste = true, mastery = true, hit = true,
    expertise = true, dodge = true, parry = true, spirit = true,
}

local function StatName(stat)
    return REFORGE_TARGET_LABEL[stat] or stat
end

-- Kurzform fuer Begruendungen. "kritische Trefferwertung (Gewicht 58) ist
-- hier der staerkste Wert" liest sich niemand zu Ende; in einem Fliesstext
-- mitten in der Zeile zaehlt die Laenge. Die Liste steht in
-- data/reforge.lua, weil sie dort ohnehin gebraucht wird.
local function StatShort(stat)
    return (WeintCodex_Reforge and WeintCodex_Reforge.SHORT
            and WeintCodex_Reforge.SHORT[stat])
        or REFORGE_TARGET_LABEL[stat] or stat
end

-- Warum zaehlt dieser Wert nicht mehr? Drei Gruende, drei Texte — ein Text
-- fuer alle drei waere fuer zwei davon falsch.
local function BlockedReason(stat, capInfo)
    local info = capInfo and capInfo[stat]
    if info and info.closedByReforge then
        return "das erledigt das Umschmieden"
    elseif info and info.kind == "breakpoint" then
        return "hinter der Tempo-Schwelle"
    end
    return "Grenze erreicht"
end


-- Vorschlagsreihenfolge einer Verzauberungszeile: die von
-- PreferredEnchantId gewaehlte ID zuerst, danach der Rest der Liste als
-- Rueckfall (eine ID, die der Client nicht aufloesen kann, darf den
-- Vorschlag nicht verschlucken — siehe FirstResolvableName).
local function EnchantRecList(row)
    if not row.recId then return row.bestList end
    if not row.bestList then return { row.recId } end
    local out = { row.recId }
    for _, id in ipairs(row.bestList) do
        if id ~= row.recId then out[#out + 1] = id end
    end
    return out
end

local function BestReforgeTarget(profile, capped, exclude)
    local weights = profile and profile.statWeights
    if not weights then return nil end
    local bestStat, bestWeight
    for stat in pairs(REFORGE_STATS) do
        local w = weights[stat]
        if w and w > 0 and stat ~= exclude and not (capped and capped[stat]) then
            if not bestWeight or w > bestWeight then
                bestStat, bestWeight = stat, w
            end
        end
    end
    if not bestStat then return nil end
    return bestStat, REFORGE_TARGET_LABEL[bestStat] or bestStat
end

--------------------------------------------------
-- BEWERTUNG: Stein / Verzauberung
--
-- ScoreStats (gewichtete Summe ohne Rücksicht auf Caps) ist seit 2.5.0.0
-- durch GemValue weiter unten ersetzt — eine Wertung, die den Cap nicht
-- kennt, war der Grund, warum Empfehlung und Sockelbonus-Entscheidung
-- auseinanderliefen.
--------------------------------------------------

local function IsInList(id, list)
    if not id or not list then return false end
    for _, v in ipairs(list) do
        if v == id then return true end
    end
    return false
end

--------------------------------------------------
-- FARBE DES STEINS vs. FARBE DES SOCKELS
--
-- Zwei verschiedene Fragen, die bis 2.3.0.0 dieselbe Variable benutzten:
--   * Welcher Stein gehört hier hinein?   -> Farbe des SOCKELS
--   * Löst der Stein den Sockelbonus aus? -> Farbe des STEINS
-- Die Bewertung fragte nach der Steinfarbe und verglich einen gelben
-- Kritstein deshalb mit der Empfehlung für GELBE Sockel — in der er an
-- erster Stelle steht. Ergebnis: "Optimal" für einen Stein, der in einem
-- blauen Sockel steckt und dessen Bonus gar nicht auslösen kann.
--------------------------------------------------

-- MoP-Regel: die Mischfarben zählen für BEIDE Grundfarben.
local SOCKET_ACCEPTS = {
    rot  = { rot = true,  orange = true, lila = true },
    gelb = { gelb = true, orange = true, ["grün"] = true },
    blau = { blau = true, lila = true,   ["grün"] = true },
    meta = { meta = true },
}

-- Steine, die jeden Sockel bedienen (Prisma-/Einfachsteine).
local UNIVERSAL_GEM_COLORS = { prismatic = true, einfach = true }

-- Farbe der Unterklasse: Steine sind Gegenstandsklasse 3, und ihre
-- Unterklasse IST die Farbe. Das ist — wie ITEM_MOD_* beim Werteabgleich —
-- die einzige Farbquelle, die weder von unserer Datenpflege noch von der
-- Übersetzung abhängt, und deckt die Steine ab, die in data/gems.lua
-- fehlen (Schlangenaugen, "perfekte" Varianten, Zweit-IDs).
local GEM_SUBCLASS_COLOR = {
    [0] = "rot",  [1] = "blau",   [2] = "gelb", [3] = "lila",
    [4] = "grün", [5] = "orange", [6] = "meta",
    [7] = "einfach", [8] = "prismatic",
    [9] = "hydraulik", [10] = "zahnrad",
}

-- DER CLIENT GEWINNT ÜBER DIE TABELLE — dieselbe Regel, die für
-- Verzauberungen seit 2.0.0.3 gilt (siehe modules/stat_match.lua) und die
-- hier bis 2.5.0.0 umgekehrt stand: gefragt wurde zuerst unsere `color`-
-- Spalte, der Client war nur Rückfall.
--
-- Die Spalte ist Handarbeit an genau der Datei, deren Namen Blizzard mitten
-- in MoP umbenannt hat, und sie ist nachweislich falsch: 76589 ("Perfekter
-- geschickter Alexandrit", +160 Treffer +120 Ausdauer) steht dort als
-- `grün`. Grün ist in MoP gelb+blau, also EIN gelber und EIN blauer Wert —
-- Treffer und Ausdauer sind beide blau. Der Stein stand damit als erste
-- Empfehlung für GELBE Sockel des Schutzkriegers, wo er den Sockelbonus
-- gar nicht auslösen kann.
--
-- Die Unterklasse ist am Client abzulesen, lokalisierungsfrei und driftet
-- nicht. Unsere Tabelle bleibt nur für den kalten Cache stehen.
local function GemColor(gemId)
    if not gemId then return nil end
    local _, _, _, _, _, _, _, _, _, _, _, classId, subclassId = GetItemInfo(gemId)
    if classId == 3 and subclassId then
        local fromClient = GEM_SUBCLASS_COLOR[subclassId]
        if fromClient then return fromClient end
    end
    local db = WeintCodex_Gems and WeintCodex_Gems[gemId]
    if db and db.color then return db.color end
    return nil
end

-- Aktiviert dieser Stein diesen Sockel? Unbekannte Steinfarbe => nil
-- ("weiss ich nicht"), damit die Anzeige das sagen kann, statt einen
-- aktiven oder inaktiven Bonus zu behaupten.
local function GemMatchesSocket(gemColor, socketColor)
    if not socketColor or socketColor == "prismatic" then return true end
    local accepts = SOCKET_ACCEPTS[socketColor]
    if not accepts then return true end
    if not gemColor then return nil end
    if UNIVERSAL_GEM_COLORS[gemColor] then return true end
    return accepts[gemColor] == true
end

--------------------------------------------------
-- WERTUNG EINES STEINS — MIT CAP-SPIELRAUM
--
-- Ersetzt seit 2.5.0.0 ScoreStats + FirstUncappedGem + die binäre Menge
-- `overStats`. Die alte Fassung war eine Klippe: FirstUncappedGem verwarf
-- einen Stein GANZ, sobald er irgendeinen übercappten Stat lieferte. Ein
-- *Stechender Dioptas* (+160 Krit, +160 Treffer) ist am Trefferkap aber
-- immer noch 160 Krit wert — er zählte 0. Zusammen mit der 0,25-%-Schwelle
-- kippte das ganze Item-Urteil an einem Viertelprozentpunkt.
--
-- `headroom` sagt je gecapptem Stat, wie viel Wertung bis zum Cap noch
-- etwas bringt:
--   Key fehlt -> Stat ist ungecappt und zählt voll
--   0         -> am Cap, weitere Punkte sind wertlos
--   N         -> die nächsten N Punkte zählen, der Rest nicht
--
-- Damit muss auch keine Farbliste mehr "bis zum Ende tragen" (der Kopf von
-- data/spec_profiles.lua verlangte das, und 14 von 39 Profilen hielten es
-- nicht ein): ein Trefferstein am Cap ist einfach 0 wert, statt aus der
-- Liste zu fallen und die Sockelbonus-Entscheidung ohne Vergleichswert
-- zurückzulassen.
--------------------------------------------------

local function GemValue(stats, weights, headroom)
    if not stats or not weights then return 0 end
    local score = 0
    for stat, value in pairs(stats) do
        local w = weights[stat] or 0
        if w ~= 0 and value and value > 0 then
            local room = headroom and headroom[stat]
            local counted = (room and value > room) and room or value
            score = score + counted * w
        end
    end
    return score
end

-- Wie viel des Steins läuft in einen gecappten Stat hinein? Der Planer
-- zieht das vom Spielraum ab, damit nicht jeder Sockel denselben Restweg
-- zum Cap für sich verbucht.
local function ConsumeHeadroom(stats, headroom)
    if not (stats and headroom) then return end
    for stat, value in pairs(stats) do
        local room = headroom[stat]
        if room and value and value > 0 then
            headroom[stat] = math.max(0, room - value)
        end
    end
end

--------------------------------------------------
-- WELCHE VERZAUBERUNG SCHLAGEN WIR VOR?
--
-- `bestList` ist eine MENGE vertretbarer Verzauberungen; id1 ist nur die,
-- die auf ein noch unverzaubertes Teil gehoert (Kopf von
-- spec_profiles.lua). Liefert id1 einen Wert, der an einer Grenze steht —
-- Trefferkap erreicht, Tempo-Schwelle erreicht —, dann ist sie als
-- VORSCHLAG die schlechteste der Liste: sie bringt Wertung, die nichts
-- mehr bewirkt. Genau das war die zweite Haelfte des Fehlerberichts, denn
-- eine Verzauberung ist Wertung wie ein Stein.
--
-- Drei Zurueckhaltungen, und jede steht fuer einen Fehlalarm:
--   * Umgereiht wird NUR, wenn id1 komplett ins Leere laeuft (Wert 0).
--     "Etwas weniger wert" ist kein Grund, eine kuratierte Liste
--     umzusortieren — dieselbe Regel wie beim Kandidatentopf der Steine.
--   * Proc-Verzauberungen (Tanzender Stahl, Jadegeist, DK-Runen) haben
--     bewusst keine Werte. Sie werden nie verdraengt und verdraengen nie.
--   * Das URTEIL ueber eine angelegte Verzauberung aendert sich dadurch
--     nicht: was in der Liste steht, bleibt optimal. Nur der Vorschlag
--     wechselt.
--------------------------------------------------

local function PreferredEnchantId(bestList, profile, headroom, capInfo)
    if not bestList or #bestList == 0 then return nil end
    local weights = profile and profile.statWeights
    if not (weights and headroom) then
        return bestList[1], "Erste Wahl deines Spec-Profils."
    end

    local firstStats = SM.EnchantStats and SM.EnchantStats(bestList[1])
    if not firstStats then
        return bestList[1], "Erste Wahl deines Spec-Profils."
    end
    if GemValue(firstStats, weights, headroom) > 0 then
        return bestList[1], "Erste Wahl deines Spec-Profils."
    end

    -- Die erste Wahl laeuft komplett ins Leere. Welcher Wert daran schuld
    -- ist, gehoert in die Begruendung: sonst steht dort eine Verzauberung,
    -- die in keinem Guide als erste genannt wird, und niemand weiss warum.
    local dead
    for stat, value in pairs(firstStats) do
        local room = headroom[stat]
        if room ~= nil and room <= 0 and value and value > 0 then dead = stat; break end
    end

    for i = 2, #bestList do
        local stats = SM.EnchantStats(bestList[i])
        if stats and GemValue(stats, weights, headroom) > 0 then
            return bestList[i], dead and string.format(
                "Statt der ersten Wahl: deren %s zählt hier nicht mehr (%s).",
                StatShort(dead), BlockedReason(dead, capInfo))
                or "Statt der ersten Wahl: die bringt hier keine Wertung mehr."
        end
    end
    return bestList[1]
end


--------------------------------------------------
-- KANDIDATENTOPF JE SPEC
--
-- Bis 2.5.0.0 war `bestGems` acht Listen je Sockelfarbe, und die
-- Empfehlung nahm `bestGems[farbe][1]`. Daran hingen drei Schwächen, die
-- alle dieselbe Wurzel haben — die Farbschlüssel trugen eine Entscheidung,
-- die eigentlich der Steinfarbe zusteht:
--   * `orange`/`lila`/`grün` sind Steinfarben, keine Sockelfarben. MoP-Items
--     haben nur rot/gelb/blau/meta/prisma; die Listen waren unerreichbar
--     und sahen trotzdem autoritativ aus (genau die Form des 2.3.0.1-Bugs).
--   * Die Liste musste "bis zum Ende tragen", sonst stand die
--     Sockelbonus-Entscheidung am Cap ohne Vergleichswert da.
--   * Und ein Juwelier-Schlangenauge in der Liste hob den Bezugswert für
--     ALLE anderen Steine um die Hälfte an (480 statt 320 Krit), sodass ein
--     korrekter Stein von "ok" auf "falsch" fiel — bei jemandem, der den
--     Beruf gar nicht hat.
--
-- Der Topf ist die Vereinigung aller Listen. Welche Steine für DIESEN
-- Sockel in Frage kommen, entscheidet danach die Steinfarbe (Client!) gegen
-- die Sockelfarbe — nicht mehr, unter welchem Schlüssel jemand den Stein
-- eingetragen hat.
--------------------------------------------------

local JEWELCRAFTING_SKILL_LINE = 755

local function HasJewelcrafting()
    if type(WeintCodex_GetProfessionSkills) ~= "function" then return false end
    local skills = WeintCodex_GetProfessionSkills()
    return skills[JEWELCRAFTING_SKILL_LINE] ~= nil
end

-- Wie viele Schlangenaugen erlaubt MoP? Die Zahl steht in
-- data/professions.lua und wird hier gelesen statt ein zweites Mal
-- hingeschrieben.
local function JewelcrafterGemLimit()
    local prof = WeintCodex_ProfessionPerks and WeintCodex_ProfessionPerks[JEWELCRAFTING_SKILL_LINE]
    if not prof or not prof.perks then return 0 end
    for _, perk in ipairs(prof.perks) do
        if perk.kind == "gems" then return perk.count or 0 end
    end
    return 0
end

local gemPoolCache = {}

-- Alle Steine, die das Profil irgendwo empfiehlt — ohne die Meta-Steine,
-- die in keinen farbigen Sockel passen. Reihenfolge der Farbschlüssel bleibt
-- als schwacher Rangfolge-Hinweis erhalten (frühere Einträge gewinnen einen
-- Gleichstand), trägt aber keine Entscheidung mehr.
local function GemPool(profile, profileKey)
    if not (profile and profile.bestGems) then return {} end
    local key = profileKey or tostring(profile)
    local cached = gemPoolCache[key]
    if cached then return cached end

    local pool, seen = {}, {}
    for color, list in pairs(profile.bestGems) do
        if color ~= "meta" then
            for _, id in ipairs(list) do
                if not seen[id] then
                    seen[id] = true
                    pool[#pool + 1] = id
                end
            end
        end
    end
    gemPoolCache[key] = pool
    return pool
end

local function IsJcGem(gemId)
    local db = WeintCodex_Gems and WeintCodex_Gems[gemId]
    return (db and db.jcOnly) == true
end

-- Kandidaten für einen Sockel.
--
-- DER TOPF ERSETZT DIE KURATIERTEN LISTEN NICHT, ER ERGÄNZT SIE — und das
-- ist keine Vorsicht, sondern die Lehre aus einem Gegenbeispiel. Ranked man
-- den ganzen Topf frei nach Wertung, empfiehlt das Addon Jägern einen
-- Kritstein statt eines Beweglichkeitssteins: HUNTER_MARKSMANSHIP wiegt
-- Krit mit 80 gegen Beweglichkeit 100, und 320 Krit (25.600) schlägt damit
-- 160 Beweglichkeit (16.000). Die kuratierte Liste desselben Profils sagt
-- `prismatic = { Feingeschliffener Rubellit }`, also Beweglichkeit. Die
-- Gewichte eines Profils und seine Listen widersprechen sich hier — und
-- CLAUDE.md sagt zu Recht, dass ein Gewicht eine Aussage über das Spiel ist
-- und nicht daran gedreht wird, bis eine Liste passt. Also entscheidet
-- weiterhin die Liste, wo sie etwas sagt.
--
--   IGNORE-Kandidaten: bestGems[Sockelfarbe] + bestGems.prismatic
--                      (genau die Menge, aus der auch bis 2.5.0.0 die
--                       Empfehlung kam — nur ohne die Cap-Klippe)
--   MATCH-Kandidaten:  zusätzlich jeder Stein des Topfes, der die Farbe
--                      DIESES Sockels bedient. Das ist der Ausweg für die
--                      14 Profile, deren `blau` nur aus einem Treffer- oder
--                      Waffenkundestein besteht: am Cap war deren einziger
--                      Kandidat 0 wert, `colorScore` fiel auf 0 und die
--                      Entscheidung erklärte den Sockelbonus pauschal für
--                      wertlos, statt ihn auszurechnen.
local function CandidateList(profile, pool, socketColor, mustMatch)
    local list, seen = {}, {}
    local function add(id)
        if id and not seen[id] then seen[id] = true; list[#list + 1] = id end
    end

    local best = profile.bestGems
    if socketColor and best[socketColor] then
        for _, id in ipairs(best[socketColor]) do add(id) end
    end
    if not mustMatch and best.prismatic then
        for _, id in ipairs(best.prismatic) do add(id) end
    end
    if mustMatch then
        for _, id in ipairs(pool) do
            if GemMatchesSocket(GemColor(id), socketColor) == true then add(id) end
        end
    end
    return list
end

-- Bester Kandidat aus einer Liste.
--   mustMatch  – nur Steine, die den Sockelbonus dieses Sockels auslösen
--   allowJC    – Schlangenaugen zugelassen (Beruf da UND Kontingent frei)
-- Rückgabe: gemId, wert
local function BestCandidate(list, socketColor, mustMatch, allowJC, weights, headroom)
    local bestId, bestValue = nil, -1
    for _, id in ipairs(list) do
        local ok = true
        if not allowJC and IsJcGem(id) then ok = false end
        if ok and mustMatch then
            -- Unbekannte Steinfarbe (nil) zählt hier NICHT als Treffer: wir
            -- empfehlen keinen Stein, von dem wir nicht wissen, ob er den
            -- Bonus auslöst, den wir gerade für lohnend erklären.
            ok = (GemMatchesSocket(GemColor(id), socketColor) == true)
        end
        if ok then
            local value = GemValue(SM.GemStats(id), weights, headroom)
            if value > bestValue then
                bestId, bestValue = id, value
            end
        end
    end
    if not bestId then return nil, 0 end
    return bestId, bestValue
end

local function IsColoredSocket(color)
    return color == "rot" or color == "gelb" or color == "blau"
end

--------------------------------------------------
-- WARUM DIESER STEIN?
--
-- Eine Empfehlung ist das eine, die Begruendung das andere. Wer
-- "Glatter Goldberyll" liest, weiss nicht, ob das an seiner Spec haengt, an
-- einem Kap oder an einem Sockelbonus — und ohne diese Auskunft bleibt ihm
-- nur, es zu glauben oder es zu lassen. Beides ist schlecht: geglaubte
-- Empfehlungen fallen beim ersten Zweifel um, und eine, die man nicht
-- nachvollziehen kann, ist von einer falschen nicht zu unterscheiden.
--
-- DIE BEGRUENDUNG WIRD ABGELESEN, NICHT DAZUERFUNDEN. Jeder Halbsatz hier
-- entspricht einer Verzweigung, die in PlanItem tatsaechlich gefallen ist:
-- welcher Wert die Wertung angefuehrt hat, welcher hoeher gewichtete dabei
-- ausgeschieden ist und warum, und wie die Sockelbonus-Entscheidung
-- ausgegangen ist. Ein Text, der etwas anderes sagt als die Rechnung, waere
-- schlimmer als gar keiner.
--------------------------------------------------

local function ExplainGem(id, socket, room, weights, plan, ctx)
    if socket.color == "meta" then
        return "Meta-Sockel — hier entscheidet der Proc-Effekt, nicht die Wertung."
    end
    if not (id and weights) then return nil end

    local parts = {}
    local stats = SM.GemStats(id)
    room = room or {}

    -- (a) Welcher Wert des Steins fuehrt die Wertung an?
    local lead, leadW = nil, -1
    if stats then
        for stat, value in pairs(stats) do
            local w = weights[stat] or 0
            if value and value > 0 and w > leadW then lead, leadW = stat, w end
        end
    end
    if lead then
        parts[#parts + 1] = string.format("%s (Gewicht %d) ist hier der stärkste Wert",
            StatShort(lead), leadW)
    end

    -- (b) Welcher HOEHER gewichtete Wert ist ausgeschieden — und warum?
    -- Genau das ist die Frage hinter jeder Rueckfrage zur Sockelseite:
    -- "wieso kein Trefferstein, ich bin doch unter dem Cap?"
    -- Ohne Anfuehrer gibt es kein "hoeher gewichtet als": dann steht hier
    -- nichts, statt einen Wert mit Gewicht 0 als ausgeschieden zu melden.
    local blocked, blockedW = nil, leadW
    if lead then
        for stat, w in pairs(weights) do
            if REFORGE_STAT_KEYS[stat] and w > 0 and w > blockedW
               and (room[stat] or 1) <= 0 then
                blocked, blockedW = stat, w
            end
        end
    end
    if blocked then
        parts[#parts + 1] = string.format("%s (%d) zählt hier nicht mehr — %s",
            StatShort(blocked), blockedW, BlockedReason(blocked, ctx and ctx.capInfo))
    end

    -- (c) Die Sockelbonus-Entscheidung, in Worten statt in Zahlen.
    if IsColoredSocket(socket.color) and (plan.bonusText or plan.bonus) then
        if plan.match then
            parts[#parts + 1] = "Farbe passt und hält den Sockelbonus"
        else
            parts[#parts + 1] = "der Sockelbonus wiegt weniger als der stärkere Stein"
        end
    end

    -- (d) Schlangenaugen sind kontingentiert; ohne diesen Hinweis sieht die
    -- Empfehlung fuer jeden ohne Juwelenschleifen nach einem Fehler aus.
    if IsJcGem(id) then
        parts[#parts + 1] = "Schlangenauge — nur mit Juwelenschleifen, begrenzte Zahl"
    end

    if #parts == 0 then return nil end
    return table.concat(parts, " · ")
end

--------------------------------------------------
-- PLANITEM — DIE EINE RECHNUNG JE GEGENSTAND
--
-- Bis 2.5.0.0 beantworteten DREI Funktionen unabhängig voneinander die
-- Frage "welchen Stein würden wir nehmen": EvaluateSocketBonus (für die
-- Bonuszeile), PickGemRecommendation (für die Empfehlungsspalte) und
-- EvaluateGem (für das Urteil, mit einer eigenen Bezugsgrösse). Jede
-- Fehlermeldung seit 2.0.0.3 war eine weitere Klammer, die sie synchron
-- halten sollte — FirstUncappedGem war 2.3.0.1s Versuch davon und deckte
-- EvaluateGems eigene Referenzrechnung bis heute nicht ab. Zwei Zeilen
-- derselben Seite mit "85 %" meinten deshalb nicht dasselbe: einmal
-- gemessen am prismatischen Anker, einmal am besten Stein der Farbliste.
--
-- Jetzt rechnet eine Funktion, und Empfehlung, Steinurteil und Bonuszeile
-- lesen alle aus ihrem Ergebnis. Sie KÖNNEN sich nicht mehr widersprechen.
--
-- Zwei Strategien, die bessere gewinnt:
--   IGNORE  je Sockel der stärkste Kandidat, ohne Farbbedingung
--   MATCH   je farbigem Sockel der stärkste Kandidat, der den Bonus
--           auslöst, plus der Bonus selbst
--
-- Rückgabe (Tabelle):
--   gems[i]      empfohlener Stein für sockets[i]
--   value[i]     dessen Wertung mit dem Spielraum AN DIESER STELLE
--   room[i]      der Spielraum-Schnappschuss dieser Stelle (das Urteil über
--                den angelegten Stein misst mit demselben Massstab)
--   match        bool  – der Plan aktiviert den Sockelbonus
--   total/alt    Wertung beider Strategien (trägt die Begründung)
--   bonus, bonusValue, bonusUnknown
--------------------------------------------------

local function PlanItem(sockets, bonus, bonusText, profile, ctx)
    local plan = {
        gems = {}, value = {}, room = {},
        bonus = bonus, bonusText = bonusText,
        match = false,
    }
    if not (profile and profile.bestGems and profile.statWeights) then
        return plan
    end

    local weights = profile.statWeights
    local pool    = ctx.pool
    local live    = ctx.headroom

    -- Der Bonus zählt nur, soweit er nicht in einen gecappten Stat läuft:
    -- "+180 Treffer" ist am Trefferkap kein Grund, irgendetwas zu opfern.
    local bonusValue = 0
    if bonus then
        bonusValue = GemValue({ [bonus.stat] = bonus.value }, weights, live)
    end
    plan.bonusValue = bonusValue

    -- Eine Bonuszeile, die wir nicht lesen konnten, ist kein Bonus von 0.
    -- Ihn wegzuwerfen, weil wir ihn nicht messen können, wäre die Behauptung
    -- eines Wissens, das nicht da ist — im Zweifel matchen.
    plan.bonusUnknown = (bonusText ~= nil and bonus == nil)

    -- OHNE BONUS GIBT ES NICHTS ZU MATCHEN, und dann darf der Topf auch
    -- nicht mitreden. Die MATCH-Variante zieht farblich passende Steine aus
    -- ALLEN Listen des Profils — das ist der Ausweg, wenn die Farbliste am
    -- Cap nichts mehr hergibt, aber es ist ausdrücklich kein Freibrief, die
    -- kuratierte Empfehlung zu überstimmen. Ohne diese Schranke bekam ein
    -- Jäger auf einem roten Sockel OHNE Sockelbonus den Tödlichen Aragonit
    -- (aus `orange`) statt des Feingeschliffenen Rubellits aus seiner
    -- eigenen `rot`-Liste — mit der Begründung, dass er nach den Gewichten
    -- desselben Profils höher liegt. Genau diesen Konflikt entscheidet in
    -- dieser Datei die Liste, nicht die Wertung (siehe CandidateList).
    local anyColored = false
    for _, socket in ipairs(sockets) do
        if IsColoredSocket(socket.color) then anyColored = true; break end
    end
    local canMatch = anyColored and (bonus ~= nil or plan.bonusUnknown)

    -- Beide Strategien durchrechnen. Der Spielraum wird dabei NICHT
    -- verbraucht — das passiert erst unten für die Gewinnerin, sonst
    -- bezahlte die zweite Variante für die erste.
    local function Run(mustMatch)
        local room  = {}
        for stat, v in pairs(live) do room[stat] = v end
        local picks, values, rooms, total = {}, {}, {}, 0
        for i, socket in ipairs(sockets) do
            local snapshot = {}
            for stat, v in pairs(room) do snapshot[stat] = v end
            rooms[i] = snapshot

            local id, value
            if socket.color == "meta" then
                -- Meta-Sockel stehen ausserhalb: dort entscheiden
                -- Proc-Effekte, die in keiner Zahl stehen.
                id = profile.bestGems.meta and profile.bestGems.meta[1]
                value = id and GemValue(SM.GemStats(id), weights, room) or 0
            else
                local needMatch = mustMatch and IsColoredSocket(socket.color)
                local cands = CandidateList(profile, pool, socket.color, needMatch)
                id, value = BestCandidate(cands, socket.color, needMatch,
                                          ctx.allowJC, weights, room)
                if not id and needMatch then
                    -- Kein farblich passender Kandidat im Topf: dieser Sockel
                    -- kann den Bonus nicht halten, die Strategie scheitert.
                    return nil
                end
            end

            picks[i], values[i] = id, value
            total = total + value
            if id then ConsumeHeadroom(SM.GemStats(id), room) end
        end
        return { gems = picks, value = values, room = rooms, total = total }
    end

    local ignore = Run(false)
    local match  = canMatch and Run(true) or nil

    if match then
        match.total = match.total + bonusValue
        -- Unlesbarer Bonus: im Zweifel matchen (s.o.).
        if plan.bonusUnknown then match.total = math.max(match.total, (ignore and ignore.total or 0)) end
    end

    local winner, loser
    if match and ignore then
        if match.total >= ignore.total then
            winner, loser, plan.match = match, ignore, true
        else
            winner, loser, plan.match = ignore, match, false
        end
    else
        winner, loser = (match or ignore), (match and ignore or nil)
        plan.match = (winner == match)
    end
    if not winner then return plan end

    plan.gems     = winner.gems
    plan.value    = winner.value
    plan.room     = winner.room
    plan.total    = winner.total
    plan.altTotal = loser and loser.total or nil

    -- Die Begruendung entsteht HIER und nicht in der Zeichenfunktion: dort
    -- waere sie eine zweite Herleitung derselben Entscheidung, und genau
    -- daran ist die Sockelbewertung schon einmal auseinandergelaufen.
    plan.why = {}
    for i, socket in ipairs(sockets) do
        plan.why[i] = ExplainGem(plan.gems[i], socket, plan.room[i], weights, plan, ctx)
    end

    -- Erst jetzt den echten Spielraum verbrauchen: das ist der Plan, den wir
    -- empfehlen, und die nächsten Slots sollen mit dem rechnen, was danach
    -- noch übrig ist. Ohne das bekäme jeder Sockel denselben Restweg zum
    -- Cap gutgeschrieben und die Seite empföhle zehn Treffersteine für eine
    -- Lücke, die einer schliesst.
    for _, id in ipairs(plan.gems) do
        if id then ConsumeHeadroom(SM.GemStats(id), live) end
    end
    if plan.match and bonus then
        ConsumeHeadroom({ [bonus.stat] = bonus.value }, live)
    end

    -- Schlangenaugen-Kontingent mitzählen (Grenze gilt charakterweit).
    if ctx.allowJC then
        for _, id in ipairs(plan.gems) do
            if id and IsJcGem(id) then ctx.jcLeft = (ctx.jcLeft or 0) - 1 end
        end
        if (ctx.jcLeft or 0) <= 0 then ctx.allowJC = false end
    end

    return plan
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

--------------------------------------------------
-- URTEIL ÜBER EINEN ANGELEGTEN STEIN
--
-- Gemessen wird gegen den Stein, den PlanItem für GENAU DIESEN Sockel
-- empfiehlt, mit GENAU DEM Spielraum, der an dieser Stelle galt — eine
-- Bezugsgrösse, nicht mehr zwei. Die Schwellen (90 % / 65 %) sind die
-- bisherigen.
--
-- Rückgabe: status, qualityPct, unbekannt, equiv
--------------------------------------------------

--------------------------------------------------
-- Das Urteil ueber den ANGELEGTEN Stein bekommt seit 2.7.0.0 ebenfalls
-- einen Satz dazu. "Nicht ideal (72 %)" beantwortet nicht, was daran fehlt;
-- der Rueckschluss vom Prozentsatz auf den Grund ist genau die Arbeit, die
-- der Spieler nicht leisten kann, weil er die Rechnung nicht sieht.
--------------------------------------------------

local function EvaluateGem(gemId, socket, index, profile, plan, ctx)
    if not gemId then return "missing", nil, false end

    local gemColor = GemColor(gemId)
    local isMeta   = (gemColor == "meta") or (socket.color == "meta")

    -- Legendärer Meta-Stein: rollengerecht => optimal,
    -- andere Rolle => nur Hinweis (nie "falsch")
    local leg = LEGENDARY_META[gemId]
    if leg then
        if not profile or not profile.role or leg[profile.role] then
            return "optimal", 100, false, nil,
                "Legendärer Meta-Stein — besser als jeder kaufbare und passend zu deiner Rolle."
        end
        return "ok", nil, false, nil,
            "Legendärer Meta-Stein, aber für eine andere Rolle gedacht."
    end

    local recId = plan and plan.gems and plan.gems[index]
    if not recId then
        -- Keine Empfehlung für diesen Sockel: nichts behaupten.
        return "ok", nil, true, nil,
            "Für diesen Sockel führt das Spec-Profil keine Empfehlung — deshalb kein Urteil."
    end
    if gemId == recId then
        return "optimal", 100, false, nil, plan.why and plan.why[index] or nil
    end

    -- Der Plan hält den Sockelbonus: ein farblich unpassender Stein kostet
    -- genau den Bonus, den wir gerade für lohnend erklärt haben. So gut
    -- seine Werte auch sind — "Optimal" ist er damit nicht, denn darüber
    -- steht die Zeile "Sockelbonus: … aktiv". Beides muss dasselbe sagen.
    local matches = GemMatchesSocket(gemColor, socket.color)
    local function Rank(status, pct, unknown, equiv, reason)
        if status == "optimal" and plan.match and matches == false then
            return "ok", pct, unknown, equiv,
                "Werte stimmen, aber die Farbe bricht den Sockelbonus, den der Plan hält."
        end
        return status, pct, unknown, equiv, reason
    end

    local myStats = SM.GemStats(gemId)

    -- WERTEABGLEICH VOR WERTUNGSRECHNUNG (seit 2.0.0.3):
    -- Blizzard hat die deutschen Steinnamen mitten in MoP Classic umbenannt
    -- (Zinnoberonyx -> Aragonit, Urdiamant -> Bergkristall, siehe Kopf von
    -- data/gems.lua) und es gibt zu vielen Schliffen wertgleiche Zweit-IDs
    -- (Juwelier-Schlangenaugen, "perfekte" Varianten). Ein Stein, der exakt
    -- dieselben Werte liefert wie die Empfehlung, IST die Empfehlung — auch
    -- wenn seine ID eine andere ist. Nur so wird er nicht zum
    -- Handlungsbedarf erklärt, den es nicht gibt.
    if myStats then
        local verdict, refId, ratio =
            SM.MatchAgainstList(myStats, { recId }, SM.GemStats)
        if SM.IsMatch(verdict) then
            return Rank("optimal", 100, false,
                        { verdict = verdict, refId = refId, ratio = ratio },
                        "Liefert dieselben Werte wie die Empfehlung — eine andere ID, derselbe Stein.")
        end
    end

    local weights = profile and profile.statWeights
    local room    = plan.room and plan.room[index]
    local best    = plan.value and plan.value[index]
    if weights and myStats and best and best > 0 then
        local myScore = GemValue(myStats, weights, room)
        local pct = math.floor((myScore / best) * 100 + 0.5)
        if pct > 100 then pct = 100 end

        -- Woran liegt der Abstand? Meistens an genau einem Wert, der an
        -- einer Grenze steht — und das ist die Auskunft, die weiterhilft,
        -- nicht die Prozentzahl.
        local reason
        local dead, deadValue = nil, 0
        for stat, value in pairs(myStats) do
            local r = room and room[stat]
            if r ~= nil and value and value > 0 and r <= 0 and value > deadValue then
                dead, deadValue = stat, value
            end
        end
        if dead then
            reason = string.format("%s zählt hier nicht mehr (%s) — die Wertung liegt brach.",
                StatShort(dead), BlockedReason(dead, ctx and ctx.capInfo))
        elseif pct < 90 then
            reason = string.format("Bringt %d %% der Wertung des empfohlenen Steins.", pct)
        end

        if pct >= 90 then return Rank("optimal", pct, false, nil, reason) end
        if pct >= 65 then return "ok", pct, false, nil, reason end
        -- Meta-Steine nie als "falsch" werten: ihre Proc-Effekte
        -- (z.B. Mana-Ersparnis, Schadensverringerung) stecken nicht
        -- in den reinen Statwerten.
        if isMeta then
            return "ok", pct, false, nil,
                "Meta-Stein — der Proc-Effekt steht in keiner Wertung, deshalb kein Urteil."
        end
        return "wrong", pct, false, nil, reason
    end

    -- Stein unbekannt oder keine Bewertungsgrundlage
    return "ok", nil, true, nil,
        "Zu diesem Stein liegen keine Werte vor — er wird deshalb nicht bewertet."
end

-- Schulter-Inschriften: Inschriftler tragen die selbst erstellbare
-- "Geheime Inschrift ..." (stärker als die kaufbare "Große Inschrift ...").
-- Deren Enchant-IDs sind nicht hinterlegt — wir erkennen sie über das
-- Schlüsselwort im Tooltip-Namen: gleiche Tierart wie die Empfehlung
-- (z.B. "Ochsenhorn") => optimal.
local INSCRIPTION_KEYWORDS = {
    "tigerzahn", "tigerfang", "kranichschwinge", "ochsenhorn", "tigerklaue",
}

-- Empfehlungsliste für einen Slot. offhandKind ist nur bei der Nebenhand
-- gesetzt und filtert schildgebundene Verzauberungen heraus, wenn dort gar
-- kein Schild steckt (sonst bekäme ein Beihand-Gegenstand "Großes Parieren"
-- empfohlen, was der Client nie erlauben würde).
local function GetBestEnchantList(profile, slotKey, offhandKind)
    local list = profile and profile.bestEnchants and profile.bestEnchants[slotKey]
    if not list then return nil end
    if offhandKind ~= "holdable" then return list end

    local filtered = {}
    for _, id in ipairs(list) do
        local db = WeintCodex_Enchants and WeintCodex_Enchants[id]
        if not (db and db.nurSchild) then
            filtered[#filtered + 1] = id
        end
    end
    if #filtered == 0 then return nil end
    return filtered
end

-- bestList kommt IMMER von GetBestEnchantList — auch nil ist dort ein
-- Ergebnis ("für diesen Gegenstand gibt es in diesem Spec nichts zu
-- empfehlen") und darf nicht still durch die ungefilterte Profilliste
-- ersetzt werden.
--
-- Rückgabe: status, bestList, equiv
--   equiv  { verdict, refId, ratio } — gesetzt, wenn die Einstufung aus dem
--          Werteabgleich stammt (nicht aus ID oder Name). Die Anzeige macht
--          das sichtbar, damit "optimal" nachvollziehbar bleibt.
local function EvaluateEnchant(enchId, slotKey, bestList, tooltipName, scannedStats)
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

        -- Namensgleichheit mit einer Empfehlung => optimal (tolerant
        -- gegenüber Kategorie-Präfixen wie "Nebenhand - ", die der
        -- Client anzeigt, unsere DB aber nicht speichert).
        for _, bid in ipairs(bestList) do
            local db = WeintCodex_Enchants and WeintCodex_Enchants[bid]
            if db and db.name and EnchantNamesMatch(currentName, db.name) then
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

    --------------------------------------------------
    -- DER FALLBACK FÜR DEN FALLBACK: Werteabgleich.
    --
    -- Bis hierher wurde nur gefragt, ob ID oder Name zur Empfehlung passen —
    -- beides Angaben aus data/enchants.lua, beides regelmäßig falsch (die
    -- Datei trägt bis heute verify-Marker, und die Übersetzungen haben sich
    -- seit MoP-Release mehrfach geändert). Wer eine korrekt verzauberte
    -- Rüstung trug, deren ID wir falsch zugeordnet hatten, bekam trotzdem
    -- "nicht ideal" zu lesen. Das ist der Fehler, den es nicht geben darf.
    --
    -- Also die Frage anders stellen: WELCHE WERTE liegen an — und sind das
    -- dieselben, die die Empfehlung bringt? Die Werte stammen aus dem
    -- Item-Tooltip des Spielers (scannedStats), die der Empfehlung aus
    -- SM.EnchantStats (Datenbank oder, falls sie dort fehlen, ebenfalls vom
    -- Client). Decken sie sich, IST die Empfehlung angelegt.
    --
    -- Kein Abgleich über Wertungen: 170 Tempo ist nicht 170 Meisterschaft.
    -- Nur deckungsgleiche Statschlüssel zählen (siehe SM.CompareStats),
    -- sonst würde der Abgleich neue Fehler erzeugen statt alte zu beheben.
    --
    -- Proc-Verzauberungen (Lied des Windes, Jadegeist, DK-Runen) haben
    -- bewusst keine Werte; für sie liefert SM.EnchantStats nil und dieser
    -- Block hält sich komplett heraus.
    --------------------------------------------------
    if not SM.IsEmpty(scannedStats) then
        local verdict, refId, ratio =
            SM.MatchAgainstList(scannedStats, bestList, SM.EnchantStats)
        local equiv = { verdict = verdict, refId = refId, ratio = ratio }

        if SM.IsMatch(verdict) then
            -- "equal": dieselbe Verzauberung unter anderer ID.
            -- "better": die stärkere Stufe (Berufs-Exklusivvariante) —
            -- die als "nicht ideal" zu melden wäre grotesk.
            return "optimal", bestList, equiv
        end
        if verdict == "weaker" then
            -- Dieselbe Verzauberung, aber eine Stufe zu niedrig. Bleibt
            -- "ok" — nur jetzt mit Begründung statt als Rätsel.
            return "ok", bestList, equiv
        end
    end

    return "ok", bestList
end

--------------------------------------------------
-- SCAN-ENGINE
-- Ein Durchlauf liefert alle Daten für alle Seiten.
--------------------------------------------------

--------------------------------------------------
-- NUR DIE GRENZEN, OHNE DEN GANZEN SCAN
--
-- Caps und Tempo-Treppe haengen an Spec-Profil und Charakterbogen, nicht an
-- Steinen und Verzauberungen. Wer nur sie braucht, soll nicht sechzehn
-- Tooltips lesen muessen — und genau das braucht der Umschmiede-Planer
-- (modules/reforge_engine.lua).
--
-- Der Zuschnitt ist ausserdem das, was den Kreis aufloest: der Planer liest
-- die Grenzen, die Sockelplanung liest das Ergebnis des Planers. Riefe der
-- Planer den vollen Scan, riefe der Scan wieder den Planer.
--------------------------------------------------

local function CapContext()
    local profile, profileKey, tankStyle, specDisplay = GetCurrentSpecProfile()
    return {
        profile     = profile,
        profileKey  = profileKey,
        tankStyle   = tankStyle,
        specDisplay = specDisplay,
        caps        = BuildCapStates(profile),
        breakpoints = BuildBreakpointStates(profile, profileKey, tankStyle),
    }
end

local function ScanCharacter()
    local capCtx = CapContext()
    local profile, profileKey, tankStyle, specDisplay =
        capCtx.profile, capCtx.profileKey, capCtx.tankStyle, capCtx.specDisplay
    local capStates        = capCtx.caps
    local breakpointStates = capCtx.breakpoints

    -- CAP-SPIELRAUM FÜR DIE SOCKELEMPFEHLUNG.
    --
    -- Bis 2.5.0.0 stand hier eine binäre Menge `overStats` ("dieser Stat ist
    -- über dem Cap"), und FirstUncappedGem warf jeden Stein weg, der davon
    -- irgendetwas lieferte. Jetzt sagt der Spielraum, wie viel Wertung in
    -- einem gecappten Stat überhaupt noch etwas bringt — ein Hybridstein
    -- behält am Cap seine andere Hälfte, statt ganz zu verschwinden.
    --
    -- Der Spielraum wird beim Planen der Slots VERBRAUCHT (siehe PlanItem).
    -- Ohne das bekäme jeder Sockel denselben Restweg zum Cap gutgeschrieben
    -- und die Seite empföhle zehn Treffersteine für eine Lücke, die einer
    -- schliesst. Die Reihenfolge ist die von EQUIP_SLOTS und damit stabil.
    --
    -- Seit 2.6.2.0 speisen zwei Quellen denselben Spielraum: die Decken
    -- (Treffer/Waffenkunde) und die Tempo-Treppe. Fuer den Planer ist das
    -- dieselbe Frage — wieviel Wertung bringt in diesem Stat ueberhaupt
    -- noch etwas —, und genau deshalb ist es EIN Topf und nicht zwei
    -- Rechnungen nebeneinander (dieselbe Lehre wie bei PlanItem).
    local headroom = {}
    for _, cs in ipairs(capStates) do
        headroom[cs.stat] = math.max(0, cs.underRating or 0)
    end
    for _, bp in ipairs(breakpointStates) do
        -- headroom == nil heisst "keine Aussage": der Stat bleibt dann
        -- ungecappt, statt mit 0 als wertlos zu gelten.
        if bp.headroom ~= nil then
            headroom[bp.stat] = math.max(0, bp.headroom)
        end
    end

    --------------------------------------------------
    -- UND WAS DAS UMSCHMIEDEN OHNEHIN ERLEDIGT (seit 2.7.0.0)
    --
    -- UMSCHMIEDEN KOSTET GOLD, EIN SOCKEL IST EINMALIG.
    --
    -- Ein Sockel laesst sich einmal vergeben; Umschmieden bewegt 40 % eines
    -- Sekundaerwerts je Gegenstand und laesst sich jederzeit zuruecknehmen.
    -- Wer einen Sockel benutzt, um ein Kap zu fuellen, das das Umschmieden
    -- ohnehin fuellt, verschenkt den Sockel — und genau das hat diese Seite
    -- bis hierher getan. Sie rechnete mit dem Abstand zum Kap, den sie
    -- GERADE sah, und empfahl deshalb Treffersteine fuer eine Luecke, die
    -- das Umschmieden umsonst schliesst. Das ist die haeufigste Sorte
    -- falscher Sockelempfehlung.
    --
    -- Der Spielraum ist deshalb nicht mehr "wieviel fehlt bis zum Kap",
    -- sondern "wieviel fehlt NACH dem Umschmieden" — dieselbe Groesse, nur
    -- richtig gemessen. Damit fallen beide Fehler weg: der Trefferstein,
    -- den es nicht braucht, und die Meldung "verschwendet" fuer einen
    -- Ueberschuss, den das Umschmieden gerade wegraeumt.
    --
    -- Die Reihenfolge, die daraus folgt, ist die der Guides: erst
    -- umschmieden, dann sockeln. Sie steht als Hinweis auf der Seite, denn
    -- ohne sie sieht die Empfehlung nach Willkuer aus.
    --
    -- IST DER PLANER AUS ODER RECHNET ER NOCH, AENDERT SICH NICHTS.
    -- CapOutlook() gibt dann nil, und diese Seite rechnet wie vor 2.7.0.0.
    -- Ein halber Plan ist keine Auskunft.
    --------------------------------------------------
    local reforgeOutlook
    if WeintCodex.ReforgeEngine and WeintCodex.ReforgeEngine.CapOutlook then
        reforgeOutlook = WeintCodex.ReforgeEngine.CapOutlook()
    end
    if reforgeOutlook then
        for stat, look in pairs(reforgeOutlook) do
            if headroom[stat] ~= nil then
                headroom[stat] = math.max(0, look.target - look.after)
            end
        end
    end

    -- Der Overcap-Pass weiter unten markiert ANGELEGTE Steine, deren Wertung
    -- ganz verschwendet ist. Das ist die andere Frage (was liegt an?) und
    -- bleibt bei der bisherigen Schwelle.
    local overStats = {}
    for _, cs in ipairs(capStates) do
        if cs.overPct > 0.25 then overStats[cs.stat] = true end
    end

    -- Kopie VOR dem Planen. PlanItem VERBRAUCHT den Spielraum; fuer die
    -- Frage "welcher Stat steht ueberhaupt an einer Grenze" zaehlt aber
    -- der Stand am Anfang, sonst gaelte nach dem letzten Slot jeder Stat
    -- als gecappt.
    local headroomAtStart = {}
    for stat, room in pairs(headroom) do headroomAtStart[stat] = room end

    -- Kandidatentopf und Schlangenaugen-Kontingent gelten für den ganzen
    -- Charakter, nicht je Gegenstand.
    -- Woran steht ein Wert, wenn sein Spielraum 0 ist? Ein Kap, eine
    -- Tempo-Schwelle und "das erledigt das Umschmieden" sind drei
    -- verschiedene Auskuenfte, und nur mit dieser Unterscheidung ergibt die
    -- Begruendung an der Zeile Sinn (siehe ExplainGem).
    local capInfo = {}
    for _, cs in ipairs(capStates) do
        capInfo[cs.stat] = { kind = "cap", label = cs.label }
    end
    for _, bp in ipairs(breakpointStates) do
        if bp.capPct ~= nil then
            capInfo[bp.stat] = { kind = "breakpoint", label = bp.label }
        end
    end
    if reforgeOutlook then
        for stat, look in pairs(reforgeOutlook) do
            capInfo[stat] = capInfo[stat] or { kind = look.kind, label = look.label }
            capInfo[stat].closedByReforge = look.closes
        end
    end

    local planCtx = {
        pool     = GemPool(profile, profileKey),
        headroom = headroom,
        capInfo  = capInfo,
        allowJC  = false,
        jcLeft   = 0,
    }
    if HasJewelcrafting() then
        planCtx.jcLeft  = JewelcrafterGemLimit()
        planCtx.allowJC = planCtx.jcLeft > 0
    end

    local scan = {
        profile     = profile,
        profileKey  = profileKey,
        tankStyle   = tankStyle,
        specDisplay = specDisplay,
        caps        = capStates,
        breakpoints = breakpointStates,
        reforge     = reforgeOutlook,
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
            local enchSlot, offhandKind = ResolveEnchSlot(slotDef, link)
            if enchSlot then
                -- Angelegte Verzauberung über den Item-Tooltip
                -- identifizieren (siehe ResolveEnchant): liefert Name,
                -- Stats und ggf. eine korrigierte ID, falls unsere
                -- Tabelle der ID etwas anderes zuordnet als der Client.
                local res = ResolveEnchant(slotDef.id, enchId, link, enchSlot)
                local effId = (res and res.id) or enchId

                if res and res.mismatch and not enchantMismatchHinted then
                    enchantMismatchHinted = true
                    print(WeintCodex.ColorText("danger", "[WeintCodex]")
                        .. " Verzauberungs-ID " .. tostring(enchId) .. " (" .. slotDef.name
                        .. ") passt nicht zur Datenbank - angezeigt wird der Wert aus dem"
                        .. " Item-Tooltip. Bitte einmal |cffD4A24A/wc vz|r ausführen und die"
                        .. " Ausgabe melden.")
                end
                local status, bestList, equiv = EvaluateEnchant(
                    effId, enchSlot,
                    GetBestEnchantList(profile, enchSlot, offhandKind),
                    res and res.name,
                    res and (res.scanned or res.stats))
                -- Begruendung an der Zeile (seit 2.7.0.0). "Nicht ideal"
                -- ist ein Befund, kein Rat: was daran fehlt, weiss nur die
                -- Rechnung, und der Spieler sieht sie nicht.
                local recId, recReason =
                    PreferredEnchantId(bestList, profile, headroomAtStart, capInfo)
                local enchReason
                if status == "optimal" then
                    local note = equiv and SM.VerdictNote(equiv.verdict)
                    enchReason = note
                        and ("Nicht dieselbe ID, aber " .. note .. " — zählt als optimal.")
                        or "Steht in der Empfehlungsliste deines Spec-Profils."
                elseif status == "neutral" then
                    enchReason = "Für diesen Platz führt dein Spec-Profil keine Empfehlung."
                elseif status == "missing" then
                    enchReason = recReason
                elseif status == "wrong" then
                    enchReason = "Steht nicht in der Empfehlungsliste für diesen Platz."
                end

                scan.enchants.rows[#scan.enchants.rows + 1] = {
                    slotId       = slotDef.id,
                    slotName     = slotDef.name,
                    enchSlot     = enchSlot,
                    offhandKind  = offhandKind,
                    itemName     = itemName,
                    enchId       = enchId,
                    effId        = effId,
                    displayName  = res and res.name,
                    enchStats    = res and res.stats,
                    mismatch     = res and res.mismatch,
                    unknownName  = res and res.unknownName,
                    unverified   = res and res.unverified,
                    status       = status,
                    equiv        = equiv,
                    bestList     = bestList,
                    recId        = recId,
                    recReason    = recReason,
                    reason       = enchReason,
                }
            end

            -- Sockel. Der zweite Rueckgabewert sagt, ob der Client die
            -- Basisdaten des Gegenstands ueberhaupt hatte; ohne sie sind
            -- die eingebauten Sockel unbekannt und uebrig bliebe nur die
            -- geratene Guertelschnalle. Die Charakterseite selbst nimmt
            -- das hin (ihr Cache ist warm, und sie zeigt eine Zeile,
            -- keine Einblendung) - modules/gearalert.lua darf darauf
            -- keinen Alarm stuetzen und liest den Wert je Zeile mit.
            local sockets, socketsKnown, socketSource = ScanItemSockets(link, slotDef.id)
            if #sockets > 0 then
                -- Sockelbonus auslesen (Wert UND Zustand kommen vom Client)
                -- und den Gegenstand einmal durchrechnen. Empfehlung,
                -- Steinurteil und Bonuszeile lesen danach alle aus `plan`.
                local bonus, bonusText, bonusActive = ScanSocketBonus(slotDef.id)
                local plan = PlanItem(sockets, bonus, bonusText, profile, planCtx)
                plan.active = bonusActive

                for socketIndex, socket in ipairs(sockets) do
                    local status, qualityPct, unknown, equiv, reason =
                        EvaluateGem(socket.gemId, socket, socketIndex, profile, plan, planCtx)

                    -- Ohne Basisdaten kennt ScanItemSockets die eingebauten
                    -- Sockel nicht: alle Steine stuenden als prismatische
                    -- "Zusatzsockel" da und wuerden gegen die falsche Liste
                    -- gemessen, ein leerer Guertel meldete eine fehlende
                    -- Schnalle. Das ist eine Aussage ueber unseren Cache,
                    -- nicht ueber die Ruestung - die Zeile wird deshalb
                    -- nicht gewertet (neutral zaehlt in CountRows nicht mit)
                    -- und fuellt sich nach der Nachlieferung von selbst.
                    if not socketsKnown then
                        status, qualityPct, unknown, equiv = "neutral", nil, true, nil
                        reason = "Gegenstandsdaten noch nicht geladen — die Zeile füllt sich von selbst."
                    end
                    scan.gems.rows[#scan.gems.rows + 1] = {
                        slotId     = slotDef.id,
                        slotName   = slotDef.name,
                        itemName   = itemName,
                        socket     = socket,
                        gemId      = socket.gemId,
                        gemStats   = socket.gemId and SM.GemStats(socket.gemId) or nil,
                        status     = status,
                        qualityPct = qualityPct,
                        unknown    = unknown,
                        equiv      = equiv,
                        reason     = reason,
                        recReason  = plan.why and plan.why[socketIndex] or nil,
                        plan       = plan,
                        recId      = plan.gems and plan.gems[socketIndex] or nil,
                        socketsKnown = socketsKnown,
                        socketSource = socketSource,
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
    --
    -- Seit 2.6.2.0 laeuft derselbe Pass auch ueber eine erreichte
    -- Tempo-Treppe, deren naechste Stufe ausser Reichweite ist. Das ist
    -- dieselbe Aussage — diese Wertung bringt nichts mehr —, und sie
    -- zweimal getrennt zu rechnen waere genau die Doppelung, aus der
    -- Empfehlung und Urteil auseinanderlaufen. Was sich unterscheidet, ist
    -- der TEXT: eine Decke ist etwas anderes als eine Treppe, deshalb
    -- traegt die Zeile `capKind` mit.
    --------------------------------------------------

    -- WAS DAS UMSCHMIEDEN WEGRAEUMT, IST NICHT VERSCHWENDET (seit 2.7.0.0).
    -- Ein Trefferstein ueber dem Kap steht nicht falsch IM STEIN, wenn der
    -- Umschmiede-Plan den Ueberschuss ohnehin in einen anderen Wert
    -- verschiebt — dann ist er einfach der Ausgangspunkt jener Rechnung.
    -- Ihn trotzdem als "verschwendet" zu melden, waere ein Handlungsbedarf,
    -- den es nicht gibt: die Sorte Fehlmeldung, wegen der man einer Seite
    -- nicht mehr glaubt.
    -- WIEVIEL LIEGT WIRKLICH BRACH?
    --
    -- Bis 2.7.0.0 war das der Abstand zum Kap, so wie er GERADE dasteht.
    -- Rechnet der Umschmiede-Planer mit, ist es der Rest NACH seinem Plan —
    -- und das ist meistens deutlich weniger oder gar nichts. Ein
    -- Trefferstein ueber dem Kap steht nicht falsch IM STEIN, wenn der Plan
    -- den Ueberschuss ohnehin in einen anderen Wert verschiebt; ihn
    -- trotzdem zu melden, waere ein Handlungsbedarf, den es nicht gibt.
    local function WasteBudget(state)
        local look = reforgeOutlook and reforgeOutlook[state.stat]
        if look then
            local rest = math.max(0, look.over or 0)
            -- Nur, wenn der Plan wirklich etwas daran aendert.
            state.reforgeReduced = rest < (state.overRating or 0) - 1
            return rest
        end
        return state.overRating or 0
    end

    local wasteStates = {}
    local function ConsiderWaste(state)
        local budget = WasteBudget(state)
        if budget < 1 then
            -- Nichts bleibt liegen. War vorher etwas da, hat der Plan es
            -- weggeraeumt — und das gehoert gesagt, sonst verschwindet der
            -- Befund kommentarlos.
            state.reforgeFixes = state.reforgeReduced and true or nil
            return
        end
        state.wasteBudget = budget
        wasteStates[#wasteStates + 1] = state
    end

    for _, cs in ipairs(capStates) do
        if cs.overPct > 0.25 then ConsiderWaste(cs) end
    end
    for _, bp in ipairs(breakpointStates) do
        -- Nur eine ERREICHTE Stufe ohne erreichbare naechste erzeugt
        -- Ueberschuss. Steht das Ziel noch vor uns, ist gar nichts zuviel.
        if bp.capped and (bp.overRating or 0) >= 1 then ConsiderWaste(bp) end
    end

    for _, cs in ipairs(wasteStates) do
        do
            local budget = cs.wasteBudget or cs.overRating
            local cands = {}

            for _, row in ipairs(scan.gems.rows) do
                -- gemStats stammt aus SM.GemStats (Datendatei ODER Client),
                -- damit ein Stein ohne Eintrag in gem_stats.lua nicht still
                -- am Cap-Abgleich vorbeirutscht.
                local st = row.gemStats
                local v = st and st[cs.stat]
                if v and v > 0 and row.status ~= "overcap" then
                    cands[#cands + 1] = { row = row, value = v, art = "Stein" }
                end
            end
            for _, row in ipairs(scan.enchants.rows) do
                -- enchStats stammt aus dem Tooltip bzw. dem korrigierten
                -- DB-Eintrag — sonst würden bei falsch zugeordneten IDs die
                -- Stats einer ganz anderen Verzauberung gegen den Cap laufen.
                local stats = row.enchStats
                if not stats then
                    local db = row.effId and WeintCodex_Enchants
                               and WeintCodex_Enchants[row.effId]
                    stats = db and db.stats
                end
                local v = stats and stats[cs.stat]
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
                    cand.row.capKind = cs.kind or "cap"
                    cand.row.reason  = string.format(
                        "Die %d %s liegen komplett %s — %s.",
                        cand.value, StatShort(cs.stat),
                        (cs.kind == "breakpoint") and "hinter der erreichten Tempo-Schwelle"
                                                  or ("über " .. (cs.label or StatName(cs.stat))),
                        reforgeOutlook and "auch nach dem Umschmiede-Plan bleibt das übrig"
                                       or "Umschmieden verschiebt sie in einen Wert, der zählt")
                    budget = budget - cand.value
                    cs.wasted[#cs.wasted + 1] = cand
                end
            end
        end
    end

    -- Die Empfehlung steht seit 2.5.0.0 schon oben in der Zeile (`plan`).
    -- Sie hier ein zweites Mal auszurechnen war genau die Doppelung, aus
    -- der Empfehlung und Entscheidung auseinanderlaufen konnten.

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
                EnchantRecList(row), GetEnchantDisplayName)
            issues[#issues + 1] = { prio = 1, status = "missing",
                text = row.slotName .. ": Verzauberung fehlt"
                    .. (rec and (" — Empfehlung: " .. rec) or "") }
        end
    end

    -- Leere Nebenhand trotz Einhandwaffe. Bewusst NUR als Hinweis und nicht
    -- als Zeile in scan.enchants.rows: es fehlt ein Gegenstand, keine
    -- Verzauberung — als "missing"-Zeile gezählt würde die Quote lügen.
    --
    -- Gemeldet wird nur, wenn die Haupthandwaffe die Nebenhand
    -- nachweislich frei lässt (siehe OccupiesBothHands). Bei einem noch
    -- ungecachten Gegenstand bleibt der Hinweis aus und der Scan wird
    -- nachgeholt — "kein Gegenstand angelegt" wäre sonst eine Aussage
    -- über unseren Item-Cache.
    do
        local mainLink = GetInventoryItemLink("player", 16)
        local offLink  = GetInventoryItemLink("player", 17)
        if mainLink and not offLink then
            local bothHands = OccupiesBothHands(mainLink)
            if bothHands == nil then
                NotePendingItemInfo(mainLink)
            elseif bothHands == false then
                issues[#issues + 1] = { prio = 1, status = "missing",
                    text = "Nebenhand: Kein Gegenstand angelegt" }
            end
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

    --------------------------------------------------
    -- CAPS UND SCHWELLEN — UND WAS MAN DAGEGEN TUT
    --
    -- Bis 2.6.1.1 endete der Befund ueber einem Cap mit "Umsockeln!". Das
    -- ist nur die halbe Antwort und meistens die teurere: Wertung ueber
    -- einer Grenze steht nicht falsch IM Stein, sie steht im falschen
    -- Stat, und der Weg dorthin heisst Umschmieden. Deshalb nennt jeder
    -- dieser Texte jetzt beides — die Menge, die daneben liegt, und
    -- wohin damit.
    --------------------------------------------------

    -- Welcher Stat steht an einer Grenze? (Stand VOR dem Planen — der
    -- Spielraum wird beim Planen verbraucht, fuer diese Frage zaehlt der
    -- Anfangsstand.)
    local cappedStats = {}
    for stat, room in pairs(headroomAtStart) do
        if room <= 0 then cappedStats[stat] = true end
    end

    -- Umschmiede-Reserve je Stat, einmal je Scan berechnet (jeder Aufruf
    -- liest 16 Gegenstaende).
    local reserveCache = {}
    local function Reserve(stat)
        local cached = reserveCache[stat]
        if not cached then
            local gain, drop = ReforgeReserve(stat)
            cached = { gain = gain, drop = drop }
            reserveCache[stat] = cached
        end
        return cached.gain, cached.drop
    end

    for _, cs in ipairs(capStates) do
        if cs.overPct > 0.25 and #cs.wasted > 0 then
            local totalWaste = 0
            for _, w in ipairs(cs.wasted) do totalWaste = totalWaste + w.value end
            local _, targetLabel = BestReforgeTarget(profile, cappedStats, cs.stat)
            issues[#issues + 1] = { prio = 2, status = "overcap",
                text = string.format(
                    "%s über dem Cap: %.1f%% / %.1f%% — %d Quelle(n), %d Wertung liegen daneben. Umschmieden%s oder umsockeln.",
                    cs.label, cs.current, cs.capPct, #cs.wasted, totalWaste,
                    targetLabel and (" in " .. targetLabel) or "") }
        elseif cs.overPct < -0.3 then
            local gain = Reserve(cs.stat)
            issues[#issues + 1] = { prio = 2, status = "wrong",
                text = string.format(
                    "%s unter dem Cap: %.1f%% / %.1f%% — es fehlen ca. %d Wertung%s. Umschmieden bewegt bis zu ~%d Wertung.",
                    cs.label, cs.current, cs.capPct, math.ceil(cs.underRating),
                    cs.spiritZaehlt and " (Willenskraft zählt mit)" or "",
                    math.floor(gain + 0.5)) }
        end
    end

    --------------------------------------------------
    -- TEMPO-SCHWELLEN
    --
    -- Drei Ausgaenge, und sie raten zu Verschiedenem — deshalb drei Texte
    -- und nicht einer mit Klammern:
    --   * Ziel voraus      -> sammeln, und zwar so viel
    --   * Stufe erreicht,
    --     naechste zu weit -> aufhoeren und den Rest umschmieden
    --   * gar nichts in
    --     Reichweite       -> nichts behaupten (steht nur auf der Seite)
    --------------------------------------------------

    for _, bp in ipairs(breakpointStates) do
        if bp.capped and (bp.overRating or 0) >= 1 then
            local _, targetLabel = BestReforgeTarget(profile, cappedStats, bp.stat)
            -- WARUM hier Schluss ist, sind zwei verschiedene Antworten: die
            -- Rechnung sagt "nicht erreichbar", ein selbst gesetztes Ziel
            -- sagt "so gewollt". Beides in einen Satz zu giessen hiesse,
            -- dem Spieler seine eigene Entscheidung als Unerreichbarkeit zu
            -- verkaufen — und die Zahl daneben widerspraeche ihm sogar.
            local nextText = ""
            if bp.nextRung and bp.targetSource == "spieler" then
                nextText = string.format(
                    " Die nächste (%.1f%%, %s) läge ~%d Wertung höher, dein Ziel steht aber darunter.",
                    bp.nextRung.pct, bp.nextRung.label,
                    math.ceil((bp.nextRung.pct - bp.current) * bp.perPct))
            elseif bp.nextRung then
                nextText = string.format(
                    " Die nächste (%.1f%%, %s) ist ~%d Wertung entfernt und mit Umschmieden und Sockeln (~%d) nicht zu erreichen.",
                    bp.nextRung.pct, bp.nextRung.label,
                    math.ceil((bp.nextRung.pct - bp.current) * bp.perPct),
                    math.floor(bp.reach + 0.5))
            end
            issues[#issues + 1] = { prio = 2, status = "overcap",
                text = string.format(
                    "%s: %.1f%% — Schwelle %s (%.1f%%) erreicht.%s ~%d Wertung bringen keinen Tick mehr — umschmieden%s.",
                    bp.label, bp.current,
                    (bp.reached and bp.reached.label) or "?",
                    bp.capPct or 0, nextText,
                    math.floor((bp.overRating or 0) + 0.5),
                    targetLabel and (" in " .. targetLabel) or "") }
        elseif bp.target and bp.underRating and bp.underRating > 0 then
            local gain = Reserve(bp.stat)
            issues[#issues + 1] = { prio = 3, status = "ok",
                text = string.format(
                    "%s: %.1f%% — bis zur Schwelle %s (%.1f%%) fehlen ~%d Wertung. Umschmieden bewegt bis zu ~%d Wertung.",
                    bp.label, bp.current, bp.target.label or "?", bp.target.pct,
                    math.ceil(bp.underRating), math.floor(gain + 0.5)) }
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
            -- Der Werteabgleich weiss bei "weaker" genau, WAS fehlt: es ist
            -- dieselbe Verzauberung, nur die schwaechere Stufe. Das gehoert
            -- in den Handlungsbedarf, sonst sucht der Spieler den Fehler an
            -- der falschen Stelle.
            local was = (row.equiv and row.equiv.verdict == "weaker")
                and "Verzauberung ist die schwächere Stufe"
                or  "Verzauberung nicht ideal"
            issues[#issues + 1] = { prio = 4, status = "ok",
                text = row.slotName .. ": " .. was
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

    -- Steine, deren Basisdaten der Werteabgleich beim Scan noch nicht vom
    -- Client bekommen hat, in dieselbe Nachlieferungsliste einreihen wie die
    -- Verzauberungen (GET_ITEM_INFO_RECEIVED, siehe itemInfoWatcher). Ohne
    -- das bliebe ein frisch eingesetzter, noch ungecachter Stein bis zum
    -- naechsten manuellen Neuaufbau als "unbekannt" stehen.
    for itemId in pairs(SM.TakePendingItems()) do
        pendingItemInfoIds[itemId] = true
    end

    return scan
end

-- Für andere Module (z.B. Companion-Export) verfügbar machen
WeintCodex.Charakter.Scan = ScanCharacter
WeintCodex.Charakter.CapContext = CapContext

-- Dieselbe Slotliste, die der Scan durchläuft. Exportiert, damit
-- modules/companion.lua für seinen Ausrüstungsbericht nicht eine
-- zweite Liste führen muss - eine Kopie liefe still auseinander,
-- sobald hier ein Slot dazukommt oder wegfällt.
WeintCodex.Charakter.EquipSlots = EQUIP_SLOTS

-- Der Gruppencheck (modules/groupcheck.lua) stellt dieselben zwei Fragen
-- an fremde Ausrüstung - "liegt eine Verzauberung drauf" und "ist der
-- Sockel belegt" - und beantwortet sie ausschließlich aus dem Item-Link.
-- Er bekommt deshalb diese vier Bausteine, statt sie nachzubauen: eine
-- zweite Fassung von ScanItemSockets wäre genau die Doppelpflege, die
-- schon einmal dafür gesorgt hat, dass zwei Stellen dasselbe Item
-- unterschiedlich bewerten. Was er NICHT übernehmen kann, ist die
-- Bewertung selbst (Spec-Profil, Caps, Tooltip) - siehe dort.
WeintCodex.Charakter.ParseItemLink     = ParseItemLink
WeintCodex.Charakter.ScanItemSockets   = ScanItemSockets
WeintCodex.Charakter.ClassifyEquipLoc  = ClassifyEquipLoc
WeintCodex.Charakter.OffhandEnchSlot   = OFFHAND_ENCH_SLOT
WeintCodex.Charakter.SocketColorLabel  = SOCKET_COLOR_LABEL

-- Zwischenspeicher (Verzauberungsnamen, Tooltip-Scans, erkannter Beruf)
-- verwerfen. Wer Scan() aufruft, nachdem sich Ausrüstung, Spec oder Beruf
-- geändert haben, muss vorher hier durch — sonst liefert der Scan die
-- Bewertung von vorhin.
WeintCodex.Charakter.ClearCache = ClearCharakterCache

-- Von Unterseiten aufzurufen, die NICHT aus diesem Modul stammen, aber in
-- derselben Charakter-Sidebar haengen (modules/academy.lua). Ohne das
-- wuerde der Ausruestungs-Watcher weiter unten die zuletzt gezeigte
-- Charakter-Seite ueber die fremde Seite legen, sobald sich etwas an der
-- Ausruestung aendert.
function WeintCodex.Charakter.LeaveView()
    activeCharakterView = nil
end

-- Nur den Profil-Schlüssel (z.B. "PALADIN_RETRIBUTION") plus den
-- lesbaren Spec-Namen. Für Module wie modules/bis.lua, die die Spec
-- brauchen, aber keinen vollen Ausrüstungs-Scan auslösen wollen.
function WeintCodex.Charakter.GetProfileKey()
    local _, profileKey, _, specDisplay = GetCurrentSpecProfile()
    return profileKey, specDisplay
end

--------------------------------------------------
-- /wc vz — DATEN-DUMP FÜR DIE PFLEGE DER DATENBANK
-- Gibt für jedes angelegte Item Verzauberungs-ID +
-- offiziellen Client-Namen sowie alle Stein-IDs aus.
-- Damit lassen sich falsche IDs/Namen in
-- data/enchants.lua zeilengenau korrigieren.
--------------------------------------------------

function WeintCodex.Charakter.DumpEnchants()
    print("|cffD4A24A[WeintCodex]|r Ausrüstungs-Dump (Zeilen bitte kopieren und melden):")
    local any = false
    for _, slotDef in ipairs(EQUIP_SLOTS) do
        local link = GetInventoryItemLink("player", slotDef.id)
        if link then
            local enchId = ParseItemLink(link)
            if enchId then
                any = true
                local scan = ScanEquippedEnchant(slotDef.id, enchId, link,
                                                 (ResolveEnchSlot(slotDef, link)))
                local tt   = scan and scan.name
                local db   = WeintCodex_Enchants and WeintCodex_Enchants[enchId]
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

                -- Gescannte Stats mit ausgeben: damit lässt sich eine falsch
                -- zugeordnete ID auch dann eindeutig korrigieren, wenn der
                -- Client nur die Effektzeile ("+170 ...") liefert.
                local statStr = ""
                local formatted = scan and SM.FormatStats(scan.stats)
                if formatted then
                    statStr = "  |cff4A4A52[" .. formatted .. "]|r"

                    -- Und gleich das Urteil des Werteabgleichs gegen den
                    -- DB-Eintrag derselben ID dazu: "weaker"/"better" heisst
                    -- fast immer, dass der Zahlenwert in data/enchants.lua
                    -- veraltet ist — das ist die Zeile, die korrigiert
                    -- gehoert, und ohne diese Ausgabe faellt sie nicht auf.
                    local dbStats = db and db.stats
                    if dbStats then
                        local verdict = SM.CompareStats(scan.stats, dbStats)
                        if verdict ~= "equal" then
                            statStr = statStr .. "  |cffFFBB22(DB: "
                                .. (SM.FormatStats(dbStats) or "?")
                                .. " -> " .. verdict .. ")|r"
                        end
                    end
                end

                print(string.format("  %s: VZ-ID %d = %s%s%s",
                    slotDef.name, enchId, tt or (db and db.name) or "?", statStr, marker))
            end
            -- Ueber die SOCKEL laufen, nicht nur ueber die Stein-IDs des
            -- Links: welcher Stein in welcher Sockelfarbe steckt, ist die
            -- Frage, an der die Bewertung haengt (ein gelber Stein in einem
            -- blauen Sockel loest den Sockelbonus nicht aus). Von aussen war
            -- das bisher nirgends abzulesen.
            for _, socket in ipairs(ScanItemSockets(link, slotDef.id)) do
                if socket.gemId then
                    any = true
                    -- Quelle mit ausgeben: "client"/"tooltip" heisst, der
                    -- Stein fehlt in data/gem_stats.lua und wurde nur ueber
                    -- den Werteabgleich bewertet — genau die Zeilen, die dort
                    -- nachgetragen gehoeren.
                    local stats, source = SM.GemStats(socket.gemId)
                    local statStr = ""
                    if stats then
                        statStr = "  |cff4A4A52[" .. (SM.FormatStats(stats) or "")
                            .. "]|r"
                        if source ~= "db" then
                            statStr = statStr .. "  |cffff9900(fehlt in gem_stats.lua,"
                                .. " Werte vom Client: " .. tostring(source) .. ")|r"
                        end
                    end

                    local gemColor = GemColor(socket.gemId)
                    local matches  = GemMatchesSocket(gemColor, socket.color)
                    local colorStr = string.format("  |cff4A4A52%s in %s|r",
                        gemColor or "Farbe?", socket.color or "?")
                    if matches == false then
                        colorStr = colorStr .. "  |cffFFBB22(kein Farbtreffer"
                            .. " — Sockelbonus nicht aktiv)|r"
                    elseif matches == nil then
                        colorStr = colorStr .. "  |cffff9900(Steinfarbe unbekannt)|r"
                    end

                    print(string.format("  %s: Stein-ID %d = %s%s%s",
                        slotDef.name, socket.gemId,
                        GetGemDisplayName(socket.gemId) or "?", statStr, colorStr))
                end
            end
        end
    end
    if not any then
        print("  |cffaaaaaaKeine Verzauberungen/Steine gefunden.|r")
    end
    print("  |cff4A4A52Zeilenweise Rohausgabe des Tooltips: /wc vz zeilen|r")
    print("  |cff4A4A52Sockelfolge, Bonus-Zustand und Planrechnung: /wc sockel|r")
end

--------------------------------------------------
-- /wc sockel — WAS WURDE GELESEN, WAS WURDE GERECHNET
--
-- Diese Fehlerklasse war von aussen nicht diagnostizierbar, und das ist
-- der Grund, warum sie ueber fuenf Releases hinweg wiederkam: in KEINER
-- Ausgabe stand, in welcher Reihenfolge die Sockel eines Gegenstands
-- gelesen wurden, woher diese Reihenfolge kam (bis 2.5.0.0 war sie
-- erfunden), ob der Sockelbonus tatsaechlich anliegt, oder mit welchem
-- Cap-Spielraum der Planer gerechnet hat.
--
-- Dieselbe Ueberlegung wie bei /wc vz zeilen und /wc alarm berufe. Bewusst
-- ein eigener Befehl, er fuellt bei voller Ausruestung mehrere Bildschirme.
--------------------------------------------------

local function FormatHeadroom(headroom)
    local parts = {}
    for stat, room in pairs(headroom or {}) do
        parts[#parts + 1] = string.format("%s=%d", stat, math.floor(room + 0.5))
    end
    table.sort(parts)
    return (#parts > 0) and table.concat(parts, ", ") or "keine Caps"
end

function WeintCodex.Charakter.DumpSockets()
    local profile, profileKey, tankStyle = GetCurrentSpecProfile()
    print("|cffD4A24A[WeintCodex]|r Sockel-Diagnose ("
        .. tostring(profileKey or "kein Profil") .. "):")

    if not profile then
        print("  |cffff5555Kein Spec-Profil - es kann nichts geplant werden.|r")
        return
    end

    local capStates = BuildCapStates(profile)
    local headroom = {}
    for _, cs in ipairs(capStates) do
        headroom[cs.stat] = math.max(0, cs.underRating or 0)
        print(string.format("  |cff4A4A52Cap %s: %.2f%% / %.2f%%, Spielraum %d Wertung|r",
            cs.label or cs.stat, cs.current or 0, cs.capPct or 0,
            math.floor(headroom[cs.stat] + 0.5)))
    end

    -- Die Tempo-Treppe speist denselben Topf (siehe ScanCharacter). Sie
    -- hier wegzulassen hiesse, dass die Diagnose mit anderen Zahlen
    -- rechnet als die Seite - genau die Sorte Abweichung, wegen der es
    -- diesen Befehl ueberhaupt gibt.
    for _, bp in ipairs(BuildBreakpointStates(profile, profileKey, tankStyle)) do
        if bp.headroom ~= nil then
            headroom[bp.stat] = math.max(0, bp.headroom)
        end
        print(string.format("  |cff4A4A52Schwelle %s: %.2f%% / %s, Spielraum %s (%s) - /wc tempo zeigt die Treppe|r",
            bp.label or bp.stat, bp.current or 0,
            bp.capPct and string.format("%.2f%%", bp.capPct) or "kein Ziel",
            bp.headroom and string.format("%d Wertung", math.floor(bp.headroom + 0.5))
                         or "ungedeckelt",
            bp.targetSource or "auto"))
    end

    -- UND WAS DAS UMSCHMIEDEN DAVON SCHON ERLEDIGT.
    --
    -- Der Planer verschiebt Wertung, ohne einen Sockel zu kosten; die
    -- Sockelplanung rechnet deshalb seit 2.7.0.0 mit dem Spielraum NACH
    -- seinem Plan (siehe ScanCharacter). Fehlt diese Ausgabe hier, rechnet
    -- die Diagnose mit anderen Zahlen als die Seite - genau die Sorte
    -- Abweichung, wegen der es diesen Befehl ueberhaupt gibt.
    local outlook = WeintCodex.ReforgeEngine and WeintCodex.ReforgeEngine.CapOutlook
                    and WeintCodex.ReforgeEngine.CapOutlook()
    if not outlook then
        print("  |cff4A4A52Umschmiede-Planer: kein fertiger Plan (aus, rechnet noch"
            .. " oder Ausruestung hat sich geaendert) - gerechnet wird ohne ihn.|r")
    else
        for stat, look in pairs(outlook) do
            local before = headroom[stat]
            headroom[stat] = math.max(0, look.target - look.after)
            print(string.format(
                "  |cff22C55EUmschmieden %s: %d -> %d (Ziel %d), Spielraum %s statt %s|r",
                look.label or stat,
                math.floor(look.before + 0.5), math.floor(look.after + 0.5),
                math.floor(look.target + 0.5),
                math.floor(headroom[stat] + 0.5),
                before and tostring(math.floor(before + 0.5)) or "-"))
        end
    end

    local pool = GemPool(profile, profileKey)
    local jc   = HasJewelcrafting()
    print(string.format("  |cff4A4A52Kandidatentopf: %d Steine · Juwelenschleifen: %s|r",
        #pool, jc and ("ja, " .. JewelcrafterGemLimit() .. " Schlangenaugen") or "nein"))

    local ctx = {
        pool = pool, headroom = headroom,
        allowJC = jc and JewelcrafterGemLimit() > 0 or false,
        jcLeft  = jc and JewelcrafterGemLimit() or 0,
    }

    for _, slotDef in ipairs(EQUIP_SLOTS) do
        local link = GetInventoryItemLink("player", slotDef.id)
        if link then
            local sockets, known, source = ScanItemSockets(link, slotDef.id)
            if #sockets > 0 then
                -- Beide Wege nebeneinander: weichen sie ab, gewinnt der
                -- Tooltip - und genau dann will man es wissen.
                local stats = GetItemStatsCompat and GetItemStatsCompat(link)
                local counted = {}
                for _, si in ipairs(SOCKET_STAT_ORDER) do
                    local n = stats and stats[si.stat]
                    if n and n > 0 then
                        counted[#counted + 1] = si.color .. "x" .. n
                    end
                end

                local seq = {}
                for _, s in ipairs(sockets) do
                    seq[#seq + 1] = s.color .. (s.buckle and "(Schnalle)"
                                                 or s.extra and "(Zusatz)" or "")
                end

                print(string.format("|cffD4A24A%s|r  Folge: %s  |cff4A4A52[Quelle: %s]|r",
                    slotDef.name, table.concat(seq, " > "),
                    source == "tooltip" and "Tooltip (echte Reihenfolge)"
                        or source == "stats" and "|cffff9900nur Anzahlen - Zuordnung geraten|r"
                        or "|cffff5555nichts gelesen|r"))
                if #counted > 0 then
                    print("   |cff4A4A52GetItemStats zaehlt: "
                        .. table.concat(counted, ", ") .. "|r")
                end
                if not known then
                    print("   |cffff9900Gegenstandsdaten noch nicht im Cache -"
                        .. " nicht gewertet.|r")
                end

                local bonus, bonusText, active = ScanSocketBonus(slotDef.id)
                if bonusText then
                    print(string.format("   Sockelbonus: %s  |cff4A4A52[gelesen: %s]|r  %s",
                        bonusText,
                        bonus and (bonus.stat .. "=" .. bonus.value)
                              or "|cffff9900nicht lesbar|r",
                        active == true and "|cff22C55EZeile ist gruen -> liegt an|r"
                            or active == false and "|cffFFBB22Zeile ist grau -> liegt nicht an|r"
                            or "|cff888888Farbe unbestimmt|r"))
                end

                local before = FormatHeadroom(ctx.headroom)
                local plan = PlanItem(sockets, bonus, bonusText, profile, ctx)
                print(string.format("   Plan: %s  |cff4A4A52(matchen %s, ignorieren %s; Bonus %s)|r",
                    plan.match and "|cff22C55EFarben matchen|r"
                               or "|cffFFBB22Bonus ignorieren|r",
                    plan.match and string.format("%.0f", plan.total or 0)
                                or string.format("%.0f", plan.altTotal or 0),
                    plan.match and string.format("%.0f", plan.altTotal or 0)
                                or string.format("%.0f", plan.total or 0),
                    string.format("%.0f", plan.bonusValue or 0)))
                print("   |cff4A4A52Spielraum vorher: " .. before
                    .. " · nachher: " .. FormatHeadroom(ctx.headroom) .. "|r")

                for i, socket in ipairs(sockets) do
                    local recId = plan.gems and plan.gems[i]
                    local cur   = socket.gemId
                    print(string.format("     %d) %-16s ist: %-34s soll: %s |cff4A4A52(%.0f)|r",
                        i, SOCKET_COLOR_LABEL[socket.color] or "?",
                        cur and (GetGemDisplayName(cur) .. " ["
                                 .. (GemColor(cur) or "Farbe?") .. "]")
                            or "|cffff5555leer|r",
                        recId and GetGemDisplayName(recId) or "-",
                        plan.value and plan.value[i] or 0))
                end
            end
        end
    end
end


--------------------------------------------------
-- /wc tempo — DIE TREPPE, IHRE HERLEITUNG UND WAS DARAUS FOLGT
--
-- Eigener Befehl aus demselben Grund wie /wc sockel und /wc vz zeilen:
-- "es wird ein Tempostein vorgeschlagen, obwohl ich am Cap bin" sieht von
-- aussen bei einer falschen Laufzeit in data/breakpoints.lua, bei einem
-- Client, der den Istwert nicht meldet, bei einer zu gross geschaetzten
-- Reichweite und bei einem selbst gesetzten Ziel voellig identisch aus.
-- Diese Ausgabe unterscheidet sie.
--
-- Gedruckt wird deshalb JEDE Zwischenzahl: welche Client-Funktion
-- geantwortet hat, wieviel davon aus Wertung kommt, der Buff-Faktor, die
-- Umschmiede-Reserve, und je Stufe ihre Herleitung aus Laufzeit und
-- Tickabstand. Wer eine falsche Zahl in der Datendatei sucht, findet sie
-- hier und nirgends sonst.
--------------------------------------------------

function WeintCodex.Charakter.DumpBreakpoints()
    local profile, profileKey, tankStyle, specDisplay = GetCurrentSpecProfile()
    print("|cffD4A24A[WeintCodex]|r Tempo-Schwellen ("
        .. tostring(specDisplay or profileKey or "kein Profil") .. "):")

    if not profile then
        print("  |cffff5555Kein Spec-Profil - es kann nichts gerechnet werden.|r")
        return
    end

    -- 1) Was der Client hergibt. Auch die Funktionen, die NICHT
    --    antworten, stehen hier: ein fehlender Wert ist eine Auskunft.
    local probes = {
        { "UnitSpellHaste(player)", SafeNum(_G.UnitSpellHaste, "player") },
        { "GetMeleeHaste()",        SafeNum(_G.GetMeleeHaste) },
        { "GetRangedHaste()",       SafeNum(_G.GetRangedHaste) },
        { "GetHaste()",             SafeNum(_G.GetHaste) },
        { "GetCritChance()",        SafeNum(_G.GetCritChance) },
    }
    for _, probe in ipairs(probes) do
        print(string.format("  |cff4A4A52%-24s %s|r", probe[1],
            probe[2] and string.format("%.2f %%", probe[2]) or "|cffff9900keine Antwort|r"))
    end

    local states = BuildBreakpointStates(profile, profileKey, tankStyle)
    if #states == 0 then
        local effKey = GetEffectiveProfileKey(profileKey, tankStyle)
        local hasData = WeintCodex_Breakpoints
            and (WeintCodex_Breakpoints[effKey] or WeintCodex_Breakpoints[profileKey])
        if hasData then
            print("  |cffff9900Fuer diese Spec sind Schwellen hinterlegt, aber es"
                .. " kam kein Zustand zustande - meist, weil der Client den"
                .. " Istwert nicht gemeldet hat (siehe oben).|r")
        else
            print("  |cff4A4A52Fuer diese Spec sind keine Tempo-Schwellen"
                .. " hinterlegt. Tempo zaehlt hier wie jeder andere"
                .. " Sekundaerwert - das ist Absicht, siehe Kopf von"
                .. " data/breakpoints.lua.|r")
        end
        return
    end

    for _, bp in ipairs(states) do
        print(string.format("|cffD4A24A%s|r  ist: %.2f %%  (davon aus Wertung %.2f %%,"
            .. " Buff-Faktor x%.3f)", bp.label, bp.current, bp.ratingPct or 0,
            bp.buffFactor or 1))
        print(string.format("  |cff4A4A52%d Wertung je Prozentpunkt Gesamtwert"
            .. " (%d je Prozentpunkt aus Wertung)|r",
            math.floor(bp.perPct + 0.5), math.floor((bp.perPctRating or 0) + 0.5)))
        print(string.format("  |cff4A4A52Reichweite %d Wertung = Umschmieden bis %d"
            .. " (rein) / %d (raus) + %d Sockel a %d|r",
            math.floor(bp.reach + 0.5), math.floor(bp.reforgeGain + 0.5),
            math.floor(bp.reforgeDrop + 0.5), bp.socketCount or 0,
            SECONDARY_GEM_RATING))

        print(string.format("  Ziel: %s  |cff4A4A52[Quelle: %s]|r  Spielraum: %s",
            bp.target and string.format("%.2f %% (%s)", bp.target.pct,
                                        bp.target.label or "?")
                      or "|cffFFBB22keines|r",
            bp.targetSource == "spieler" and "selbst gesetzt"
                or bp.targetSource == "aus" and "abgeschaltet"
                or "gerechnet",
            bp.headroom and string.format("%d Wertung", math.floor(bp.headroom + 0.5))
                         or "|cff888888ungedeckelt (keine Aussage)|r"))
        if bp.capped then
            print(string.format("  |cffcc88ffGekappt: %d Wertung liegen hinter der"
                .. " Schwelle und bringen keinen Tick mehr.|r",
                math.floor((bp.overRating or 0) + 0.5)))
        end

        print("  |cff4A4A52Treppe (Laufzeit / Tickabstand -> Prozent):|r")
        for _, rung in ipairs(bp.ladder or {}) do
            local e = rung.effect or {}
            local reached = rung.pct <= bp.current + 0.001
            print(string.format("    %s%6.2f %%|r  %-38s |cff4A4A52%g s / %g s,"
                .. " %d. Tick%s|r  %s",
                reached and "|cff22C55E" or "|cff6B6B74", rung.pct,
                rung.label or "?", e.duration or 0, e.tick or 0, rung.ticks or 0,
                e.verify and ", unbestaetigt" or "",
                reached and "|cff22C55Eerreicht|r"
                    or string.format("|cff4A4A52~%d Wertung|r",
                                     math.ceil((rung.pct - bp.current) * bp.perPct))))
        end
    end
end

--------------------------------------------------
-- /wc vz zeilen — ROHAUSGABE DES ITEM-TOOLTIPS
--
-- Zweimal in Folge wurde gemeldet, das Addon halte einen Gegenstandswert
-- fuer die Verzauberung ("+1.201 Meisterschaft" auf Handschuhen, die
-- tatsaechlich "+170 Tempo" tragen). Von aussen war das nicht zu klaeren:
-- welche Zeilen der Client ueberhaupt schreibt, welche davon gruen sind
-- und was der Parser aus ihnen liest, steht in keiner Ausgabe. Genau das
-- ist hier zu sehen — eine Zeile je Tooltipzeile, mit Farbe und
-- gelesenen Werten.
--
-- Bewusst ein eigener Befehl: /wc vz bleibt die kurze Fassung zum Melden,
-- diese hier fuellt bei voller Ausruestung mehrere Bildschirme.
--------------------------------------------------

function WeintCodex.Charakter.DumpEnchantLines()
    print("|cffD4A24A[WeintCodex]|r Tooltip-Zeilen der angelegten Ausrüstung:")
    for _, slotDef in ipairs(EQUIP_SLOTS) do
        local link = GetInventoryItemLink("player", slotDef.id)
        if link then
            local enchId = ParseItemLink(link)
            print(string.format("|cffD4A24A%s|r (VZ-ID %s)",
                slotDef.name, tostring(enchId or "—")))

            scanTip:SetOwner(UIParent, "ANCHOR_NONE")
            scanTip:ClearLines()
            scanTip:SetInventoryItem("player", slotDef.id)

            for i = 1, (scanTip:NumLines() or 0) do
                local line = _G["WeintCodexScanTipTextLeft" .. i]
                local txt  = line and line:GetText()
                if txt and txt ~= "" then
                    local stats  = SM.FormatStats(ParseAllStats(txt))
                    local colour = IsGreenLine(line) and "|cff22C55Egrün|r"
                                                     or  "|cff4A4A52·|r"
                    print(string.format("   %2d %s %s%s", i, colour, txt,
                        stats and ("  |cff4A4A52[" .. stats .. "]|r") or ""))
                end
            end
        end
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
-- Verzauberkunst an-/abgelegt: die Ring-Slots kommen dadurch in die
-- Wertung hinein oder fallen heraus (siehe HasEnchanting).
equipWatcher:RegisterEvent("SKILL_LINES_CHANGED")
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
        refreshLbl:SetFont(WeintCodex.Fonts.sans, 11, "")
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

-- Hoehe, die der Seitenkopf im Layout belegt. Die Unterseiten haengen ihren
-- Inhalt daran statt an einer eigenen Zahl - vorher stand die 52 fuenfmal
-- einzeln im Modul, und der Spielstil-Umschalter setzte bei 44 an und lief
-- damit in die Spec-Zeile hinein.
--
-- 78 = 14 Einzug + Eyebrow 10 + 6 + Titel 20 + 4 + Spec-Zeile 10, jeweils
-- mit der Zeilenhoehe der Schrift (rund das 1,15-fache der Punktzahl), plus
-- etwas Luft. Zu knapp gerechnet legt sich die Spec-Zeile auf die erste
-- Inhaltszeile - im Spiel sieht man das erst, wenn eine Spec einen langen
-- Namen hat.
local HEAD_H     = 78
local TOGGLE_H   = 28
local TOGGLE_GAP = 16

local function DrawPageHeader(frame, titleText, scan, onRefresh)
    MakeRefreshButton(onRefresh)
    WeintCodex.SetBreadcrumb("Charakter", titleText)

    local head = WeintCodex.PageHead(frame, {
        eyebrow = "Charakter",
        title = titleText, titleSize = 20,
        sub = "", subSize = 10,
        x = 16, y = 14, height = HEAD_H - 14,
    })

    local specInfo = head.Sub
    if scan.profileKey then
        local styleHint = scan.tankStyle
            and (" |cffD4A24A[" .. (scan.tankStyle == "OFF" and "Offensiv" or "Defensiv") .. "]|r")
            or ""
        local customHint = (scan.profile and scan.profile.customWeights)
            and "  |cffFFBB22[eigene Gewichtung aktiv]|r" or ""
        local profWarn = (not scan.profile) and "  |cffff9900(kein Profil hinterlegt!)|r" or ""
        specInfo:SetText("|cff4A4A52Spec: " .. (scan.specDisplay or scan.profileKey) .. styleHint .. "|r" .. customHint .. profWarn)
    else
        specInfo:SetText("|cffff9900Spec konnte nicht ermittelt werden — einloggen bzw. Spec wählen!|r")
    end

    return head
end

-- Tank-Spielstil-Umschalter; gibt genutzte Y-Höhe zurück (negativ)
local function DrawTankStyleToggle(parent, profileKey, currentStyle, onSwitch)
    if not profileKey or not TANK_SPECS[profileKey] then return 0 end

    local W = parent:GetWidth() - 32

    local bg = CreateFrame("Frame", nil, parent)
    bg:SetSize(math.max(W, 200), TOGGLE_H)
    bg:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -HEAD_H)
    SetSolidBg(bg, C.headerBg[1], C.headerBg[2], C.headerBg[3], 0.80)
    DrawBorder(bg, C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1.0, 1)

    local info = bg:CreateFontString(nil, "OVERLAY")
    info:SetFont(WeintCodex.Fonts.sans, 10, "")
    info:SetPoint("LEFT", bg, "LEFT", 10, 0)
    info:SetText(WeintCodex.ColorText("textNormal", "Tank-Spielstil:")
        .. " " .. WeintCodex.ColorText("textFaint", "bestimmt Empfehlungen & Bewertung"))

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
        lbl:SetFont(WeintCodex.Fonts.sans, 10, "")
        lbl:SetAllPoints(btn)
        lbl:SetJustifyH("CENTER")
        lbl:SetJustifyV("MIDDLE")
        lbl:SetText(isActive and ("|cffD4A24A" .. label .. "|r") or ("|cff4A4A52" .. label .. "|r"))
        btn:SetScript("OnClick", function()
            SetTankStyle(profileKey, style)
            if onSwitch then onSwitch() end
        end)
        return btn
    end

    StyleBtn("Offensiv", "OFF", -4)
    StyleBtn("Defensiv", "DEF", -98)

    return -(TOGGLE_H + TOGGLE_GAP)
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
    -- Zeichenweise kuerzen, nicht byteweise - sonst bleibt bei einem
    -- Itemnamen mit Umlaut ein halbes UTF-8-Zeichen stehen, das der Client
    -- als leeres Kaestchen zeichnet.
    local len = WeintCodex.Utf8Len(text)
    while len > 1 and fs:GetStringWidth() > maxWidth do
        len  = len - 1
        text = WeintCodex.Utf8Sub(text, 1, len)
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
    local headerY = -HEAD_H + toggleOffset
    local function MakeHeader(text, x, w)
        local h = enchantFrame:CreateFontString(nil, "OVERLAY")
        h:SetFont(WeintCodex.Fonts.sans, 9, "")
        h:SetPoint("TOPLEFT", enchantFrame, "TOPLEFT", x, headerY)
        h:SetWidth(w)
        h:SetJustifyH("LEFT")
        h:SetText("|cff4A4A52" .. text .. "|r")
    end
    MakeHeader("STATUS",                 24, 70)
    MakeHeader("SLOT / GEGENSTAND",      94, 140)
    MakeHeader("AKTUELLE VERZAUBERUNG", 240, 230)
    MakeHeader("EMPFEHLUNG",            478, 220)

    local divider = enchantFrame:CreateTexture(nil, "OVERLAY")
    divider:SetPoint("TOPLEFT",  enchantFrame, "TOPLEFT",  16, headerY - 14)
    divider:SetPoint("TOPRIGHT", enchantFrame, "TOPRIGHT", -16, headerY - 14)
    divider:SetHeight(1)
    divider:SetColorTexture(C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1.0)

    local sf, inner = CreateScrollArea(enchantFrame, 14, headerY - 18, 20, 400)
    sf:ClearAllPoints()
    sf:SetPoint("TOPLEFT",     enchantFrame, "TOPLEFT",     14, headerY - 18)
    sf:SetPoint("BOTTOMRIGHT", enchantFrame, "BOTTOMRIGHT", -26, 24)
    inner:SetWidth(sf:GetWidth() - 22)

    local yOff = 0

    for _, row in ipairs(scan.enchants.rows) do
        local info = STATUS[row.status] or STATUS.neutral

        -- Zweite Zeile mit der Begruendung, dieselbe Ueberlegung wie auf
        -- der Sockelseite: "nicht ideal" ist ein Befund, kein Rat.
        local why = row.reason
        if row.status == "missing" and row.recReason then why = row.recReason end

        local rf = CreateFrame("Frame", nil, inner)
        rf:SetSize(inner:GetWidth() - 4, 40)
        rf:SetPoint("TOPLEFT", inner, "TOPLEFT", 2, yOff)
        SetSolidBg(rf, C.surface2[1], C.surface2[2], C.surface2[3], 0.68)

        -- DIE HOEHE WIRD GEMESSEN, NICHT GESCHAETZT (siehe ShowGems).
        -- Der Text steht deshalb vor den uebrigen Feldern: sie richten sich
        -- an der fertigen Zeilenhoehe aus.
        local rowH = 40
        if why then
            local whyLbl = rf:CreateFontString(nil, "OVERLAY")
            whyLbl:SetFont(WeintCodex.Fonts.sans, 9, "")
            whyLbl:SetPoint("TOPLEFT",  rf, "TOPLEFT",  30, -36)
            whyLbl:SetPoint("TOPRIGHT", rf, "TOPRIGHT", -8, -36)
            whyLbl:SetJustifyH("LEFT")
            whyLbl:SetTextColor(C.textFaint[1], C.textFaint[2], C.textFaint[3])
            whyLbl:SetText(why)
            local ok, h = pcall(whyLbl.GetStringHeight, whyLbl)
            rowH = 40 + math.ceil((ok and type(h) == "number" and h > 0) and h or 11) + 2
            rf:SetHeight(rowH)
        end

        -- Die mittig verankerten Felder sollen dort stehen, wo sie ohne
        -- Begruendung stuenden: der Versatz haelt ihre absolute Lage fest,
        -- unabhaengig davon, wie hoch die Zeile geworden ist.
        local lineY = rowH / 2 - 20

        local stripe = rf:CreateTexture(nil, "BORDER")
        stripe:SetSize(3, rowH)
        stripe:SetPoint("LEFT", rf, "LEFT", 0, 0)
        stripe:SetColorTexture(info.color[1], info.color[2], info.color[3], 0.80)

        AttachStatusIcon(rf, row.status, 10, lineY)

        local stLbl = rf:CreateFontString(nil, "OVERLAY")
        stLbl:SetFont(WeintCodex.Fonts.sans, 9, "")
        stLbl:SetPoint("LEFT", rf, "LEFT", 30, lineY)
        stLbl:SetWidth(60)
        stLbl:SetJustifyH("LEFT")
        stLbl:SetText(StatusColorStr(row.status) .. info.label .. "|r")

        local slotLbl = rf:CreateFontString(nil, "OVERLAY")
        slotLbl:SetFont(WeintCodex.Fonts.sans, 11, "")
        slotLbl:SetPoint("TOPLEFT", rf, "TOPLEFT", 92, -6)
        slotLbl:SetWidth(140)
        slotLbl:SetWordWrap(false)
        slotLbl:SetJustifyH("LEFT")
        slotLbl:SetText(TruncateOneLine(slotLbl, row.slotName, 138))
        slotLbl:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])

        if row.itemName then
            local itemLbl = rf:CreateFontString(nil, "OVERLAY")
            itemLbl:SetFont(WeintCodex.Fonts.sans, 10, "")
            itemLbl:SetPoint("TOPLEFT", rf, "TOPLEFT", 92, -20)
            itemLbl:SetWordWrap(false)
            itemLbl:SetJustifyH("LEFT")
            -- Einzeilig kuerzen statt umbrechen zu lassen, sonst kollidiert
            -- eine 2. Zeile mit dem Slotnamen darueber (siehe TruncateOneLine).
            local shortName = TruncateOneLine(itemLbl, row.itemName, 138)
            itemLbl:SetText("|cff3A3A42" .. shortName .. "|r")
        end

        local curLbl = rf:CreateFontString(nil, "OVERLAY")
        curLbl:SetFont(WeintCodex.Fonts.sans, 11, "")
        curLbl:SetPoint("LEFT", rf, "LEFT", 238, lineY)
        curLbl:SetWidth(232)
        curLbl:SetJustifyH("LEFT")
        if row.status == "missing" then
            curLbl:SetText("|cffff5555— Keine Verzauberung! —|r")
        elseif row.status == "neutral" and not row.enchId then
            curLbl:SetText("|cff4A4A52— (keine Empfehlung für diese Spec)|r")
        else
            -- Was der Client sagt, hat Vorrang vor unserer ID-Tabelle
            -- (siehe ResolveEnchant) — sonst zeigen wir bei falsch
            -- zugeordneten IDs eine andere Verzauberung an als die, die
            -- tatsächlich angelegt ist.
            local n = row.displayName or GetEnchantDisplayName(row.enchId) or "—"
            -- Der Werteabgleich hat entschieden (siehe EvaluateEnchant):
            -- den Grund dazuschreiben, sonst steht bei einer Verzauberung,
            -- die namentlich NICHT die Empfehlung ist, ein unerklaertes
            -- "Optimal" — und der naechste Fehlerbericht kommt bestimmt.
            local note = row.equiv and SM.VerdictNote(row.equiv.verdict)
            if row.status == "overcap" then
                -- Decke und Treppe sind zwei verschiedene Aussagen: ueber
                -- dem Trefferkap ist die Wertung wertlos, hinter der
                -- letzten erreichbaren Tempo-Stufe bringt sie nur keinen
                -- Tick mehr. Ein Text fuer beides waere fuer einen der
                -- beiden Faelle falsch.
                curLbl:SetText(n .. (row.capKind == "breakpoint"
                    and " |cffcc88ff(hinter der Schwelle!)|r"
                    or  " |cffcc88ff(Stat über Cap!)|r"))
            elseif note then
                curLbl:SetText(n .. " |cff4A4A52(" .. note .. ")|r")
            elseif row.unverified then
                -- Item war beim Scan noch nicht im Client-Cache: Name
                -- stammt ungeprüft aus der DB (Neuscan läuft automatisch,
                -- sobald der Client die Itemdaten nachliefert).
                curLbl:SetText(n .. " |cff4A4A52(?)|r")
            elseif row.mismatch then
                curLbl:SetText(n .. " |cffFFBB22(ID " .. tostring(row.enchId)
                    .. " abweichend – /wc vz)|r")
            elseif row.unknownName then
                -- Kein Widerspruch, nur ein Name, den data/enchants.lua so
                -- nicht kennt (siehe ResolveEnchant). Angezeigt wird der
                -- des Clients, gerechnet wird mit den Werten der DB.
                curLbl:SetText(n .. " |cff4A4A52(Name so nicht in der Datenbank)|r")
            else
                curLbl:SetText(n)
            end
            curLbl:SetTextColor(info.color[1], info.color[2], info.color[3])
        end

        if row.recId and row.status ~= "optimal" and row.status ~= "neutral" then
            -- Erste auflösbare Empfehlung wählen, die NICHT namensgleich
            -- mit der bereits angelegten Verzauberung ist. Unauflösbare
            -- IDs ("Unbekannt (ID …)") werden übersprungen.
            local curName = row.displayName or (row.enchId and GetEnchantDisplayName(row.enchId))
            local recName = FirstResolvableName(
                EnchantRecList(row), GetEnchantDisplayName, curName)
            if recName then
                local recLbl = rf:CreateFontString(nil, "OVERLAY")
                recLbl:SetFont(WeintCodex.Fonts.sans, 11, "")
                recLbl:SetPoint("LEFT", rf, "LEFT", 476, lineY)
                recLbl:SetWidth(220)
                recLbl:SetJustifyH("LEFT")
                recLbl:SetText("|cffD4A24A> " .. recName .. "|r")
            end
        end

        yOff = yOff - (rowH + 2)
    end

    if #scan.enchants.rows == 0 then
        local noSlot = inner:CreateFontString(nil, "OVERLAY")
        noSlot:SetFont(WeintCodex.Fonts.sans, 12, "")
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
        noteBox:SetFont(WeintCodex.Fonts.sans, 9, "")
        noteBox:SetPoint("TOPRIGHT", gemFrame, "TOPRIGHT", -140, -14)
        noteBox:SetWidth(300)
        noteBox:SetJustifyH("RIGHT")
        noteBox:SetText("|cff4A4A52" .. scan.profile.gemNote .. "|r")
    end

    local toggleOffset = DrawTankStyleToggle(gemFrame, scan.profileKey, scan.tankStyle, ShowGems)

    local headerY = -HEAD_H + toggleOffset
    local function MakeHeader(text, x, w)
        local h = gemFrame:CreateFontString(nil, "OVERLAY")
        h:SetFont(WeintCodex.Fonts.sans, 9, "")
        h:SetPoint("TOPLEFT", gemFrame, "TOPLEFT", x, headerY)
        h:SetWidth(w)
        h:SetJustifyH("LEFT")
        h:SetText("|cff4A4A52" .. text .. "|r")
    end
    MakeHeader("STATUS",             24, 80)
    MakeHeader("SOCKELPLATZ (FARBE)", 108, 122)
    MakeHeader("EINGESETZTER STEIN", 234, 230)
    MakeHeader("EMPFEHLUNG",         478, 220)

    local divider = gemFrame:CreateTexture(nil, "OVERLAY")
    divider:SetPoint("TOPLEFT",  gemFrame, "TOPLEFT",  16, headerY - 14)
    divider:SetPoint("TOPRIGHT", gemFrame, "TOPRIGHT", -16, headerY - 14)
    divider:SetHeight(1)
    divider:SetColorTexture(C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1.0)

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
            slotHeader:SetFont(WeintCodex.Fonts.sans, 10, "")
            slotHeader:SetPoint("TOPLEFT", inner, "TOPLEFT", 6, yOff - 4)
            slotHeader:SetText(WeintCodex.ColorText("textNormal", row.slotName)
                .. (row.itemName
                    and ("  " .. WeintCodex.ColorText("textGhost", row.itemName)) or ""))
            yOff = yOff - 20

            -- Sockelbonus: ZWEI AUSSAGEN, NICHT EINE.
            --
            -- "genutzt" stand hier bis 2.3.0.1 für unsere EMPFEHLUNG,
            -- formuliert wie eine Tatsache über den Gegenstand. An einem
            -- blauen Sockel mit gelbem Stein behauptete das Fenster damit
            -- einen Bonus, den es nicht gibt ("Sockelbonus: +60 Stärke —
            -- genutzt" über "Blauer Sockel #1: Glatter Goldberyll").
            --
            -- Getrennt sind sie seither, aber der ZUSTAND war bis 2.5.0.0
            -- selbst noch eine Herleitung aus Steinfarben — mit drei
            -- Unbekannten, von denen zwei danebenlagen. Er kommt jetzt aus
            -- der Farbe der Tooltipzeile (plan.active, siehe
            -- ScanSocketBonus): der Client zeichnet den Sockelbonus grün,
            -- wenn er anliegt. nil heisst weiterhin "keine Aussage".
            local plan = row.plan
            if plan and plan.bonusText then
                local verdict
                if plan.match == false then
                    if plan.active == true then
                        verdict = "|cffFFBB22aktiv, lohnt sich aber nicht — der stärkere Stein wiegt mehr|r"
                    elseif plan.active == false then
                        verdict = "|cff22C55Ebewusst ignoriert — der stärkere Stein wiegt mehr|r"
                    else
                        verdict = "|cff22C55Elohnt sich nicht — der stärkere Stein wiegt mehr|r"
                    end
                elseif plan.active == true then
                    verdict = "|cff22C55Eaktiv|r"
                elseif plan.active == false then
                    verdict = "|cffFFBB22lohnt sich, liegt aber nicht an — Steinfarbe passt nicht zum Sockel|r"
                else
                    verdict = "|cff4A4A52lohnt sich — Farben matchen|r"
                end
                -- Eine Bonuszeile, die wir nicht lesen konnten, ist kein
                -- Bonus von 0: das sagen statt es zu verschweigen.
                if plan.bonusUnknown then
                    verdict = verdict .. " |cff888888(Wert nicht lesbar)|r"
                end
                local bonusLine = inner:CreateFontString(nil, "OVERLAY")
                bonusLine:SetFont(WeintCodex.Fonts.sans, 9, "")
                bonusLine:SetPoint("TOPLEFT", inner, "TOPLEFT", 16, yOff - 1)
                bonusLine:SetText("|cff4A4A52Sockelbonus: " .. plan.bonusText
                    .. " — " .. verdict)
                yOff = yOff - 15
            end
        end

        local info = STATUS[row.status] or STATUS.neutral

        -- ZWEITE ZEILE: DIE BEGRUENDUNG.
        --
        -- Sie steht in der Zeile und nicht im Tooltip. Ein Tooltip ist der
        -- Ort fuer Einzelheiten, die man nachschlaegt; die Frage "warum
        -- dieser Stein" hat man dagegen genau dann, wenn man die Zeile
        -- liest — und wer erst darauf zeigen muss, um sie beantwortet zu
        -- bekommen, kommt gar nicht auf die Idee, dass es eine Antwort
        -- gibt. Zwei Begruendungen, weil es zwei Fragen sind: warum diese
        -- Empfehlung, und was ist am angelegten Stein.
        -- Zwei Fragen, zwei Antworten: bei einem Befund steht dort, was
        -- daran ist; sonst, warum die Empfehlung so lautet.
        local why = row.recReason
        if row.reason and (row.status ~= "optimal" or not why) then
            why = row.reason
        end

        local rf = CreateFrame("Frame", nil, inner)
        rf:SetSize(inner:GetWidth() - 4, 30)
        rf:SetPoint("TOPLEFT", inner, "TOPLEFT", 2, yOff)
        SetSolidBg(rf, C.surface2[1], C.surface2[2], C.surface2[3], 0.60)

        -- DIE HOEHE WIRD GEMESSEN, NICHT GESCHAETZT.
        -- Die Begruendung ist ein ganzer Satz und bricht im kleinsten
        -- Fenster um; mit fester Zeilenhoehe laege die naechste Zeile darin
        -- (dieselbe Ueberlegung wie bei CreateToggle in core/ui.lua). Der
        -- Text steht deshalb VOR den uebrigen Feldern, damit die Hoehe der
        -- Zeile schon feststeht, wenn sie sich daran ausrichten.
        local rowH, whyLbl = 30, nil
        if why then
            whyLbl = rf:CreateFontString(nil, "OVERLAY")
            whyLbl:SetFont(WeintCodex.Fonts.sans, 9, "")
            whyLbl:SetPoint("TOPLEFT",  rf, "TOPLEFT",  42, -24)
            whyLbl:SetPoint("TOPRIGHT", rf, "TOPRIGHT", -8, -24)
            whyLbl:SetJustifyH("LEFT")
            whyLbl:SetTextColor(C.textFaint[1], C.textFaint[2], C.textFaint[3])
            whyLbl:SetText(why)
            local ok, h = pcall(whyLbl.GetStringHeight, whyLbl)
            rowH = 28 + math.ceil((ok and type(h) == "number" and h > 0) and h or 11) + 4
            rf:SetHeight(rowH)
        end

        local stripe = rf:CreateTexture(nil, "BORDER")
        stripe:SetSize(3, rowH)
        stripe:SetPoint("LEFT", rf, "LEFT", 0, 0)
        stripe:SetColorTexture(info.color[1], info.color[2], info.color[3], 0.80)

        -- Bei zwei Zeilen rutscht die erste nach oben; ohne Begruendung
        -- bleibt alles, wo es war.
        local lineY = why and (rowH / 2 - 15) or 0

        -- Sockelfarbe als Punkt
        local dc = SOCKET_DOT_COLOR[row.socket.color] or { 0.55, 0.55, 0.55 }
        local dot = rf:CreateTexture(nil, "OVERLAY")
        dot:SetSize(10, 10)
        dot:SetPoint("LEFT", rf, "LEFT", 8, lineY)
        dot:SetColorTexture(dc[1], dc[2], dc[3], 0.90)

        AttachStatusIcon(rf, row.status, 22, lineY)

        local stLbl = rf:CreateFontString(nil, "OVERLAY")
        stLbl:SetFont(WeintCodex.Fonts.sans, 8, "")
        stLbl:SetPoint("LEFT", rf, "LEFT", 42, lineY)
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
            -- Konnte die Reihenfolge nicht am Grundgegenstand abgelesen
            -- werden, stimmen die Farben nur als MENGE und ihre Zuordnung
            -- zu den einzelnen Steinen ist geraten (siehe ScanItemSockets).
            -- Genau das war bis 2.5.0.0 der Normalfall und in keiner
            -- Ausgabe zu sehen.
            if row.socketSource ~= "tooltip" and row.socket.orderKnown == nil then
                sockName = sockName .. " |cff888888(?)|r"
            end
        end
        local lbl = rf:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(WeintCodex.Fonts.sans, 10, "")
        lbl:SetPoint("LEFT", rf, "LEFT", 106, lineY)
        lbl:SetWidth(120)
        lbl:SetJustifyH("LEFT")
        lbl:SetText(sockName)
        lbl:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])

        local curLbl = rf:CreateFontString(nil, "OVERLAY")
        curLbl:SetFont(WeintCodex.Fonts.sans, 10, "")
        curLbl:SetPoint("LEFT", rf, "LEFT", 232, lineY)
        curLbl:SetWidth(232)
        curLbl:SetJustifyH("LEFT")
        if row.socketsKnown == false then
            -- Sagen statt urteilen (siehe ScanCharacter). Die Zeile füllt
            -- sich, sobald der Client die Gegenstandsdaten nachliefert.
            curLbl:SetText("|cff888888Gegenstandsdaten noch nicht geladen …|r")
        elseif row.status == "missing" then
            curLbl:SetText(row.socket.buckle
                and "|cffff5555— Schnalle fehlt / Sockel leer! —|r"
                or  "|cffff5555— Leerer Sockel! —|r")
        else
            local n = GetGemDisplayName(row.gemId) or "?"
            local note = row.equiv and SM.VerdictNote(row.equiv.verdict)
            local suffix = ""
            if row.status == "overcap" then
                suffix = (row.capKind == "breakpoint")
                    and " |cffcc88ff(hinter der Schwelle!)|r"
                    or  " |cffcc88ff(über Cap!)|r"
            elseif note then
                -- Werteabgleich statt ID-Treffer (siehe EvaluateGem)
                suffix = " |cff4A4A52(" .. note .. ")|r"
            elseif row.qualityPct and row.qualityPct < 100 then
                suffix = " |cff888888(" .. row.qualityPct .. "%)|r"
            elseif row.unknown then
                suffix = " |cff888888(unbekannt)|r"
            end
            curLbl:SetText(n .. suffix)
            curLbl:SetTextColor(info.color[1], info.color[2], info.color[3])
        end

        if row.recId and row.status ~= "optimal" and row.socketsKnown ~= false then
            -- Kaputte/unauflösbare Empfehlungs-ID nicht anzeigen und nichts
            -- empfehlen, das namensgleich schon eingesetzt ist.
            local recName = GetGemDisplayName(row.recId)
            local curName = row.gemId and GetGemDisplayName(row.gemId)
            if recName and not recName:find("Unbekannt", 1, true)
               and not (curName and recName:lower() == curName:lower()) then
                local recLbl = rf:CreateFontString(nil, "OVERLAY")
                recLbl:SetFont(WeintCodex.Fonts.sans, 10, "")
                recLbl:SetPoint("LEFT", rf, "LEFT", 476, lineY)
                recLbl:SetWidth(220)
                recLbl:SetJustifyH("LEFT")
                recLbl:SetText("|cffD4A24A> " .. recName .. "|r")
            end
        end

        yOff = yOff - (rowH + 2)
    end

    if #scan.gems.rows == 0 then
        local noSlot = inner:CreateFontString(nil, "OVERLAY")
        noSlot:SetFont(WeintCodex.Fonts.sans, 12, "")
        noSlot:SetPoint("TOPLEFT", inner, "TOPLEFT", 10, -10)
        noSlot:SetText("|cffaaaaaa Keine Sockel gefunden (Charakter einloggen!).|r")
    end

    inner:SetHeight(math.max(20, -yOff + 10))

    -- Der Weg zur anderen Haelfte derselben Frage. Er steht nur da, wenn
    -- der Planer laeuft: ein Knopf zu einer Seite, die es nicht gibt, ist
    -- schlimmer als keiner.
    local gemExtras
    if WeintCodex.ReforgeEngine and WeintCodex.ReforgeEngine.Enabled()
       and WeintCodex.Reforge and WeintCodex.Reforge.ShowPage then
        gemExtras = {
            { type = "header", text = "Umschmieden" },
            { type = "rows", rows = { { label = scan.reforge
                and "Plan wird mitgerechnet" or "Plan noch nicht fertig",
                valueColor = scan.reforge and "green" or "textFaint" } } },
            { type = "button", label = "Zum Umschmieden",
              onClick = WeintCodex.Reforge.ShowPage },
        }
    end
    ShowScoreInspector(scan.gems.counts, gemExtras)

    -- Klarstellung: Farbangaben beziehen sich auf den Sockelplatz
    local colorHint = gemFrame:CreateFontString(nil, "OVERLAY")
    colorHint:SetFont(WeintCodex.Fonts.sans, 9, "")
    colorHint:SetPoint("BOTTOMLEFT", gemFrame, "BOTTOMLEFT", 16, 20)
    colorHint:SetText("|cff4A4A52Farbpunkt & Name = Farbe des SOCKELPLATZES im Item, nicht des Steins. Andersfarbige Steine (z.B. Lila in Blau) können optimal sein.|r")

    -- OHNE DIESEN SATZ SIEHT DIE EMPFEHLUNG NACH WILLKUER AUS.
    --
    -- Rechnet der Umschmiede-Planer mit, faellt jeder Stein weg, dessen
    -- Wert das Umschmieden ohnehin liefert — und dann steht auf einem
    -- Charakter weit unter dem Trefferkap trotzdem "Krit". Das ist richtig
    -- und ohne die Reihenfolge nicht zu verstehen.
    if scan.reforge then
        local order = gemFrame:CreateFontString(nil, "OVERLAY")
        order:SetFont(WeintCodex.Fonts.sans, 9, "")
        order:SetPoint("BOTTOMLEFT", gemFrame, "BOTTOMLEFT", 16, 34)
        order:SetText(WeintCodex.ColorText("gold", "Erst umschmieden, dann sockeln:")
            .. WeintCodex.ColorText("textFaint",
               " diese Empfehlungen rechnen damit, dass der Umschmiede-Plan"
               .. " schon umgesetzt ist. Umschmieden kostet Gold, ein Sockel"
               .. " ist einmalig — was das Umschmieden füllt, muss kein Stein füllen."))
    end
end

--------------------------------------------------
-- CAP-BALKEN (für Übersicht & Werteverteilung)
-- Gibt genutzte Höhe zurück.
--------------------------------------------------

local function DrawCapBar(parent, x, y, w, cs)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont(WeintCodex.Fonts.sans, 9, "")
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

    -- Der Detailbereich wird ZUERST gesetzt, erst danach wird gemessen: er
    -- ist seit 2.0.0.0 die rechte Spalte der Seite, ContentPanel schrumpft
    -- also um seine 372 px, sobald er erscheint. Stand der Aufruf wie
    -- vorher am Ende der Funktion, rechnete die ganze Seite mit der
    -- Breite von VOR dem Schrumpfen - und Kennzahlenkarten wie
    -- "Trefferwertung" liefen unter dem Detailbereich ins Nichts.
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

    -- Content nutzt die tatsaechliche Panelbreite statt einer festen Spalte,
    -- damit Kacheln/Grids den verfuegbaren Platz fuellen statt Leerraum
    -- rechts stehen zu lassen (siehe Fensterbreite in core/ui.lua). -26 fuer
    -- die Scrollleiste, die "body" unten rechts abzieht (siehe SetPoint dort) -
    -- sonst ist der Scroll-Child breiter als sein sichtbarer Viewport und der
    -- rechte Rand von Kacheln/Headerzeile wird abgeschnitten.
    local UEBERSICHT_W = math.max(560, cp:GetWidth() - 26)

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
    SetSolidBg(portrait, C.bgPanel[1], C.bgPanel[2], C.bgPanel[3], 1.0)
    DrawBorder(portrait, C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1.0, 1)
    WeintCodex.CutCorners(portrait, 10, "bgDark")

    local eyebrow
    if scan.profileKey then
        local styleHint = scan.tankStyle
            and (" · " .. (scan.tankStyle == "OFF" and "Offensiv" or "Defensiv")) or ""
        eyebrow = WeintCodex.Eyebrow(bc,
            (scan.specDisplay or scan.profileKey) .. styleHint, { size = 10 })
    else
        eyebrow = WeintCodex.Eyebrow(bc, "Kein Spec-Profil gefunden",
            { size = 10, color = "warning" })
    end
    eyebrow:SetPoint("TOPLEFT", portrait, "TOPRIGHT", 16, -4)

    local h1 = WeintCodex.PageTitle(bc, "Ausrüstungs-Check", { size = 26 })
    h1:SetPoint("TOPLEFT", eyebrow, "BOTTOMLEFT", 0, -8)

    -- Zwei verschiedene Aussagen, die bis 2.3.1.0 dieselbe Zahl benutzten:
    -- ein MANGEL ist etwas, das fehlt oder falsch ist (Prio 1-3), ein
    -- HINWEIS ist eine vertretbare Wahl, die nicht die erste der Liste ist
    -- (Prio 4). Gezaehlt wurden nur die Maengel - die Hinweise standen aber
    -- trotzdem in der Liste darunter. Der gemeldete Ausruestungs-Check sagte
    -- deshalb gleichzeitig "Alles versorgt", "nichts offen" und zeigte einen
    -- Punkt unter "Handlungsbedarf". Beide Zahlen werden jetzt gefuehrt und
    -- beide benannt.
    local nIssues, nHints = 0, 0
    for _, is in ipairs(scan.issues) do
        if is.prio <= 3 then nIssues = nIssues + 1
        else                 nHints  = nHints  + 1 end
    end

    local sub = bc:CreateFontString(nil, "OVERLAY")
    sub:SetFont(WeintCodex.Fonts.sans, 11, "")
    sub:SetPoint("TOPLEFT", h1, "BOTTOMLEFT", 0, -8)
    sub:SetPoint("RIGHT", bc, "RIGHT", -20, 0)
    sub:SetJustifyH("LEFT")
    if score.checks == 0 then
        sub:SetText(WeintCodex.ColorText("warning", "Keine Prüfdaten — Charakter einloggen / Spec-Profil prüfen."))
    elseif nIssues == 0 and nHints == 0 then
        sub:SetText(WeintCodex.ColorText("success", "Alles versorgt · Verzauberungen, Sockel und Caps sind sauber."))
    elseif nIssues == 0 then
        sub:SetText(WeintCodex.ColorText("success", "Keine Mängel · ")
            .. WeintCodex.ColorText("textMuted", nHints .. " Hinweis"
                .. (nHints == 1 and "" or "e") .. " zur Feinabstimmung, siehe unten."))
    else
        sub:SetText(WeintCodex.ColorText("warning",
            nIssues .. " Problem" .. (nIssues == 1 and "" or "e") .. " gefunden · Details unter Handlungsbedarf."))
    end

    -- Bewertung rechts im Kopf: helle Tonvariante, weil die Grundfarben als
    -- Flaeche gedacht sind und als grosse Zahl auf Schwarz zu dunkel geraten.
    local gradeTone
    if score.grade == "S" or score.grade == "A" then gradeTone = "successBright"
    elseif score.grade == "B" or score.grade == "C" then gradeTone = "accentBright"
    else gradeTone = "dangerBright" end
    if score.checks == 0 then gradeTone = "textDim" end
    local gradeCol = C[gradeTone]

    -- 44er Notenkachel ganz rechts, davor die Zahl - Reihenfolge wie im Entwurf.
    local gradeBadge = CreateFrame("Frame", nil, bc)
    gradeBadge:SetSize(44, 44)
    gradeBadge:SetPoint("TOPRIGHT", bc, "TOPRIGHT", -20, -26)
    SetSolidBg(gradeBadge, gradeCol[1], gradeCol[2], gradeCol[3], 0.13)
    DrawBorder(gradeBadge, gradeCol[1], gradeCol[2], gradeCol[3], 0.38, 1)
    WeintCodex.CutCorners(gradeBadge, 10, "bgDark")

    local gradeLbl = gradeBadge:CreateFontString(nil, "OVERLAY")
    gradeLbl:SetPoint("CENTER", gradeBadge, "CENTER", 0, 0)
    gradeLbl:SetFont(WeintCodex.Fonts.sansBold, 19, "")
    gradeLbl:SetTextColor(gradeCol[1], gradeCol[2], gradeCol[3])
    gradeLbl:SetText(score.checks > 0 and score.grade or "?")

    local scoreNum = bc:CreateFontString(nil, "OVERLAY")
    scoreNum:SetFont(WeintCodex.Fonts.monoBold, 34, "")
    scoreNum:SetPoint("RIGHT", gradeBadge, "LEFT", -12, -2)
    scoreNum:SetJustifyH("RIGHT")
    scoreNum:SetTextColor(gradeCol[1], gradeCol[2], gradeCol[3])
    scoreNum:SetText(score.checks > 0 and tostring(score.total) or "—")

    -- "/ 100" bewusst kleiner und stumpfer: der Nenner ist Bezug, nicht Wert.
    local scoreMax = bc:CreateFontString(nil, "OVERLAY")
    scoreMax:SetFont(WeintCodex.Fonts.monoBold, 15, "")
    scoreMax:SetPoint("BOTTOMLEFT", scoreNum, "BOTTOMRIGHT", 4, 2)
    scoreMax:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
    scoreMax:SetText(score.checks > 0 and "/ 100" or "")

    local scoreCap = WeintCodex.Eyebrow(bc, "Bewertung", { size = 9, justify = "RIGHT" })
    scoreCap:SetPoint("BOTTOMRIGHT", scoreNum, "TOPRIGHT", 0, 2)

    -- =============================================
    -- AUSRÜSTUNGS-STATUS (Karten-Raster mit Fortschrittsbalken)
    -- =============================================
    -- Der Entwurf setzt die Kennzahlenkarten direkt unter den Kopf; die
    -- frueher vorangestellte Zeile "AUSRÜSTUNGS-STATUS" benennt nur, was die
    -- vier Karten ohnehin beschriften.
    local cardDefs = {
        { kind = "counts", label = "Verzauberungen",  counts = scan.enchants.counts, onClick = ShowEnchants },
        { kind = "counts", label = "Sockel & Steine",  counts = scan.gems.counts,     onClick = ShowGems },
    }
    for _, cs in ipairs(scan.caps) do
        cardDefs[#cardDefs + 1] = { kind = "cap", cap = cs, onClick = ShowWerteverteilung }
    end

    -- Zwei Spalten, nicht eine Reihe: die Beschriftungen sind verschieden
    -- lang, und "TREFFERWERTUNG (NAHKAMPF)" ist als gesperrte Versalie mehr
    -- als doppelt so breit wie "SOCKEL & STEINE". Bei vier Karten
    -- nebeneinander bestimmt die laengste, ob ALLE lesbar sind - in 2.0.0.0
    -- war sie es nicht, die Karte lief rechts aus der Seite. Gepaart stehen
    -- oben die beiden Bestandskarten (Verzauberungen / Sockel) und darunter
    -- die Caps (Trefferwertung / Waffenkunde), was ohnehin die Lesart ist.
    local GRID_TOP, GRID_H, GRID_GAP = -124, 112, 16
    local GRID_COLS = 2
    local gridRows  = math.ceil(#cardDefs / GRID_COLS)
    local colW = (UEBERSICHT_W - 40 - GRID_GAP * (GRID_COLS - 1)) / GRID_COLS

    for i, def in ipairs(cardDefs) do
        local card = WeintCodex.CreateSurface(bc, {
            width = colW, height = GRID_H, tone = "plain",
            radius = 14, backdrop = "bgDark", button = true,
        })
        local gCol = (i - 1) % GRID_COLS
        local gRow = math.floor((i - 1) / GRID_COLS)
        card:SetPoint("TOPLEFT", bc, "TOPLEFT",
            20 + gCol * (colW + GRID_GAP),
            GRID_TOP - gRow * (GRID_H + GRID_GAP))

        local lbl = WeintCodex.Eyebrow(card, "", { size = 10 })
        lbl:SetPoint("TOPLEFT", card, "TOPLEFT", 16, -14)
        lbl:SetPoint("RIGHT", card, "RIGHT", -16, 0)

        local mainCol, mainText, subText, pct
        if def.kind == "counts" then
            local counts = def.counts
            local filled = counts.total - counts.missing
            pct = (counts.total > 0) and (filled / counts.total) or 0
            local qual = (filled > 0) and math.floor(counts.points / filled + 0.5) or 0
            if qual > 100 then qual = 100 end
            if counts.total == 0 then mainCol = C.textDim
            elseif counts.missing == 0 then mainCol = (counts.overcap > 0) and C.violetBright or C.successBright
            else mainCol = (pct >= 0.75) and C.accentBright or C.dangerBright end
            lbl:SetText(WeintCodex.Spaced(WeintCodex.Upper(def.label)))
            mainText = filled .. " / " .. counts.total
            subText  = "Qualität " .. qual .. "%"
        else
            local cs = def.cap
            if cs.overPct > 0.25 then mainCol = C.violetBright
            elseif cs.overPct < -0.3 then mainCol = C.dangerBright
            else mainCol = C.successBright end
            pct = (cs.capPct > 0) and math.max(0, math.min(1, cs.current / cs.capPct)) or 0
            lbl:SetText(WeintCodex.Spaced(WeintCodex.Upper(cs.label)))
            mainText = string.format("%.1f%%", cs.current)
            if cs.overPct > 0.25 then subText = string.format("Cap %.1f%% · über", cs.capPct)
            elseif cs.overPct < -0.3 then subText = string.format("Cap %.1f%% · fehlt", cs.capPct)
            else subText = string.format("Cap %.1f%% · optimal", cs.capPct) end
        end

        local num = card:CreateFontString(nil, "OVERLAY")
        num:SetFont(WeintCodex.Fonts.monoBold, 23, "")
        num:SetPoint("TOPLEFT", lbl, "BOTTOMLEFT", 0, -10)
        num:SetTextColor(mainCol[1], mainCol[2], mainCol[3])
        num:SetText(mainText)

        local subLbl = card:CreateFontString(nil, "OVERLAY")
        subLbl:SetFont(WeintCodex.Fonts.sans, 12, "")
        subLbl:SetPoint("TOPLEFT", num, "BOTTOMLEFT", 0, -4)
        subLbl:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
        subLbl:SetText(subText)

        local track = card:CreateTexture(nil, "OVERLAY")
        track:SetHeight(3)
        track:SetPoint("BOTTOMLEFT",  card, "BOTTOMLEFT",  16, 14)
        track:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -16, 14)
        track:SetColorTexture(C.bgPanel[1], C.bgPanel[2], C.bgPanel[3], 1.0)

        if pct > 0.01 then
            local fill = card:CreateTexture(nil, "OVERLAY")
            fill:SetHeight(3)
            fill:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 16, 14)
            fill:SetWidth(math.max(1, (colW - 32) * math.min(pct, 1)))
            fill:SetColorTexture(mainCol[1], mainCol[2], mainCol[3], 1.0)
        end

        card:SetScript("OnEnter", function(self) self:SetSurface("surface3") end)
        card:SetScript("OnLeave", function(self) self:SetTone("plain") end)
        if def.onClick then card:SetScript("OnClick", def.onClick) end
    end

    -- =============================================
    -- HANDLUNGSBEDARF · NACH PRIORITÄT
    -- =============================================
    -- Der Entwurf stellt beide Bloecke nebeneinander (Raster 1.35fr / 1fr):
    -- links, was zu tun ist, rechts die Summen zum Nachschlagen. Die
    -- Reihenfolge ist die Aussage - Handlungsbedarf zuerst, Zahlen danach.
    local PAIR_TOP  = GRID_TOP - gridRows * GRID_H - (gridRows - 1) * GRID_GAP - 20
    local PAIR_GAP  = 16
    local pairW     = UEBERSICHT_W - 40
    local leftW     = math.floor((pairW - PAIR_GAP) * 0.575)
    local rightW    = pairW - PAIR_GAP - leftW

    local ISSUE_ROW_H, ISSUE_GAP = 52, 8
    local shownIssues = math.min(#scan.issues, 4)
    local leftH = 96 + math.max(1, shownIssues) * (ISSUE_ROW_H + ISSUE_GAP)

    --------------------------------------------------
    -- Links: Handlungsbedarf (Akzentkarte)
    --------------------------------------------------

    local hbCard = WeintCodex.CreateSurface(bc, {
        width = leftW, height = leftH, tone = "accent",
        radius = 14, backdrop = "bgDark",
    })
    hbCard:SetPoint("TOPLEFT", bc, "TOPLEFT", 20, PAIR_TOP)

    local hbTitle = hbCard:CreateFontString(nil, "OVERLAY")
    hbTitle:SetFont(WeintCodex.Fonts.sansSemi, 14, "")
    hbTitle:SetPoint("TOPLEFT", hbCard, "TOPLEFT", 20, -16)
    hbTitle:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])

    -- Ueberschrift und Chip richten sich nach dem, was tatsaechlich in der
    -- Liste steht: "Handlungsbedarf" nur, wenn es Maengel gibt. Stehen dort
    -- ausschliesslich Hinweise, heisst die Karte auch so - eine Karte namens
    -- "Handlungsbedarf" mit dem Vermerk "nichts offen" widerspricht sich.
    local openCount, hintCount = 0, 0
    for _, is in ipairs(scan.issues) do
        if is.prio <= 3 then openCount = openCount + 1
        else                 hintCount = hintCount + 1 end
    end

    hbTitle:SetText(openCount > 0 and "Handlungsbedarf · nach Priorität"
                                   or "Feinabstimmung · nach Priorität")

    local chipText, chipTone, chipTextColor
    if openCount > 0 then
        chipText      = openCount .. " offen"
        chipTone      = "danger"
        chipTextColor = "dangerBright"
    elseif hintCount > 0 then
        chipText      = hintCount .. " Hinweis" .. (hintCount == 1 and "" or "e")
        chipTone      = "gold"
        chipTextColor = "accentBright"
    else
        chipText      = "nichts offen"
        chipTone      = "success"
        chipTextColor = "successBright"
    end

    local hbChip = WeintCodex.Chip(hbCard, {
        text = chipText, tone = chipTone, textColor = chipTextColor,
        backdrop = "accentCardTop", height = 22, size = 9,
    })
    hbChip:SetPoint("TOPRIGHT", hbCard, "TOPRIGHT", -16, -14)

    local rowY = -52
    if score.checks == 0 then
        local none = WeintCodex.Label(hbCard, "Keine Prüfdaten vorhanden.",
            { color = "textMuted", size = 13 })
        none:SetPoint("TOPLEFT", hbCard, "TOPLEFT", 20, rowY)
    elseif #scan.issues == 0 then
        local ok = WeintCodex.Label(hbCard, "Alles versorgt — keine offenen Punkte.",
            { color = "successBright", size = 13 })
        ok:SetPoint("TOPLEFT", hbCard, "TOPLEFT", 20, rowY)
    else
        for i = 1, shownIssues do
            local issue = scan.issues[i]
            local info  = STATUS[issue.status] or STATUS.neutral

            -- Eigene Flaeche je Zeile (Entwurf: #0C0C0F, Radius 10) statt
            -- Rahmen - der Entwurf kennt keine umrandeten Zeilen.
            local row = WeintCodex.CreateSurface(hbCard, {
                height = ISSUE_ROW_H, tone = "flat", surface = "cardBottom",
                radius = 10, backdrop = "accentCardTop",
            })
            row:SetPoint("TOPLEFT",  hbCard, "TOPLEFT",  20, rowY)
            row:SetPoint("TOPRIGHT", hbCard, "TOPRIGHT", -20, rowY)

            local badge = CreateFrame("Frame", nil, row)
            badge:SetSize(22, 22)
            badge:SetPoint("LEFT", row, "LEFT", 12, 0)
            SetSolidBg(badge, info.color[1], info.color[2], info.color[3], 0.20)
            WeintCodex.CutCorners(badge, 6, "cardBottom")

            local badgeLbl = badge:CreateFontString(nil, "OVERLAY")
            badgeLbl:SetPoint("CENTER", badge, "CENTER", 0, 0)
            badgeLbl:SetFont(WeintCodex.Fonts.monoBold, 11, "")
            local bc2 = info.bright or info.color
            badgeLbl:SetTextColor(bc2[1], bc2[2], bc2[3])
            badgeLbl:SetText(tostring(i))

            local tag = row:CreateFontString(nil, "OVERLAY")
            tag:SetFont(WeintCodex.Fonts.monoBold, 10, "")
            tag:SetPoint("RIGHT", row, "RIGHT", -12, 0)
            tag:SetTextColor(bc2[1], bc2[2], bc2[3])
            tag:SetText(WeintCodex.Spaced(WeintCodex.Upper(info.label or "")))

            local txt = row:CreateFontString(nil, "OVERLAY")
            txt:SetFont(WeintCodex.Fonts.sans, 13, "")
            txt:SetPoint("LEFT",  badge, "RIGHT", 12, 0)
            txt:SetPoint("RIGHT", tag, "LEFT", -10, 0)
            txt:SetJustifyH("LEFT")
            txt:SetWordWrap(false)
            txt:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
            txt:SetText(issue.text or "")

            rowY = rowY - ISSUE_ROW_H - ISSUE_GAP
        end
    end

    -- Zwei Wege raus, wie im Entwurf: der wichtigere als Bernstein-Flaeche.
    local hbBtn1 = WeintCodex.CreateButton(hbCard, {
        text = "Verzauberungen öffnen", kind = "primary",
        backdrop = "accentCardBot", onClick = ShowEnchants,
    })

    local hbBtn2 = WeintCodex.CreateButton(hbCard, {
        text = "Sockel öffnen", kind = "secondary",
        backdrop = "accentCardBot", onClick = ShowGems,
    })
    hbBtn2:SetPoint("LEFT", hbBtn1, "RIGHT", 10, 0)

    local hbHint = WeintCodex.Eyebrow(hbCard, "Scan bei Itemwechsel",
        { size = 9, color = "textFaint", justify = "RIGHT" })

    -- Hinweis und Schaltflaechen teilen sich die Fusszeile nur, wenn beide
    -- nebeneinander passen. Beide Breiten stehen erst nach ihrer Beschriftung
    -- fest (CreateButton misst den Text, der gesperrte Eyebrow ist breiter als
    -- er aussieht), deshalb wird hier gerechnet statt geschaetzt: vorher lag
    -- die Zeile fest bei BOTTOMRIGHT und "Sockel öffnen" schob sich ueber
    -- "SCAN BEI ITEMWECHSEL". Passt es nicht, ruecken die Knoepfe eine Zeile
    -- hoch und der Hinweis sitzt darunter.
    local HINT_ROW_H = 20
    local footRoom   = leftW - 40 - (hbBtn1:GetWidth() + 10 + hbBtn2:GetWidth())
    local sideBySide = footRoom >= (hbHint:GetStringWidth() + 16)

    if sideBySide then
        hbBtn1:SetPoint("BOTTOMLEFT", hbCard, "BOTTOMLEFT", 20, 14)
        hbHint:SetPoint("BOTTOMRIGHT", hbCard, "BOTTOMRIGHT", -20, 24)
    else
        hbBtn1:SetPoint("BOTTOMLEFT", hbCard, "BOTTOMLEFT", 20, 14 + HINT_ROW_H)
        hbHint:SetPoint("BOTTOMRIGHT", hbCard, "BOTTOMRIGHT", -20, 14)
    end

    hbCard:SetHeight(math.abs(rowY) + 68 + (sideBySide and 0 or HINT_ROW_H))

    --------------------------------------------------
    -- Rechts: Werte-Summen
    --------------------------------------------------

    local wsCard = WeintCodex.CreateSurface(bc, {
        width = rightW, tone = "plain", radius = 14, backdrop = "bgDark",
    })
    wsCard:SetPoint("TOPLEFT", bc, "TOPLEFT", 20 + leftW + PAIR_GAP, PAIR_TOP)

    local wsTitle = wsCard:CreateFontString(nil, "OVERLAY")
    wsTitle:SetFont(WeintCodex.Fonts.sansSemi, 14, "")
    wsTitle:SetPoint("TOPLEFT", wsCard, "TOPLEFT", 20, -16)
    wsTitle:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
    wsTitle:SetText("Werte-Summen der Ausrüstung")

    local totals = CollectEquippedStats()
    local statEntries = {}
    for _, key in ipairs(STAT_ORDER) do
        local value = totals[key]
        if value and value > 0 then
            statEntries[#statEntries + 1] = { label = STAT_LABELS[key], value = value }
        end
    end

    local wsY = -48
    if #statEntries == 0 then
        local none = WeintCodex.Label(wsCard,
            "Keine Werte ermittelt (Charakter einloggen / Items anlegen).",
            { color = "textMuted", size = 13 })
        none:SetPoint("TOPLEFT",  wsCard, "TOPLEFT",  20, wsY)
        none:SetPoint("RIGHT",    wsCard, "RIGHT",   -20, 0)
        wsY = wsY - 40
    else
        -- Zweispaltig als Beschriftung links / Zahl rechts mit Zeilenlinie -
        -- der Entwurf listet, statt Kaestchen zu setzen.
        local WS_COLS  = 2
        local wsColW   = (rightW - 40 - 20) / WS_COLS
        local WS_ROW_H = 26

        for i, entry in ipairs(statEntries) do
            local col = (i - 1) % WS_COLS
            local rw  = math.floor((i - 1) / WS_COLS)
            local line = CreateFrame("Frame", nil, wsCard)
            line:SetSize(wsColW, WS_ROW_H)
            line:SetPoint("TOPLEFT", wsCard, "TOPLEFT",
                20 + col * (wsColW + 20), wsY - rw * WS_ROW_H)

            local lbl2 = WeintCodex.Label(line, entry.label,
                { color = "textMuted", size = 12 })
            lbl2:SetPoint("LEFT", line, "LEFT", 0, 0)

            local val = line:CreateFontString(nil, "OVERLAY")
            val:SetFont(WeintCodex.Fonts.monoBold, 12, "")
            val:SetPoint("RIGHT", line, "RIGHT", 0, 0)
            val:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
            val:SetText("+" .. WeintCodex.FormatGrouped(entry.value))

            WeintCodex.RowLine(line, -(WS_ROW_H - 1))
        end

        wsY = wsY - math.ceil(#statEntries / WS_COLS) * WS_ROW_H - 12
    end

    local wsFoot = WeintCodex.Label(wsCard,
        "Bewertet wird gegen das Spec-Profil aus spec_profiles.lua — das Addon "
        .. "urteilt, die Companion zeichnet nur.",
        { color = "textDim", size = 12 })
    wsFoot:SetPoint("TOPLEFT",  wsCard, "TOPLEFT",  20, wsY - 4)
    wsFoot:SetPoint("RIGHT",    wsCard, "RIGHT",   -20, 0)
    wsFoot:SetJustifyV("TOP")

    wsCard:SetHeight(math.max(hbCard:GetHeight(), math.abs(wsY) + 56))

    -- Der Scrollbereich richtet sich nach der hoeheren der beiden Karten.
    rowY = PAIR_TOP - math.max(hbCard:GetHeight(), wsCard:GetHeight())

    -- Die frueher hier stehende Fusszeile ("Karten anklicken fuer Details,
    -- Scan laeuft bei Itemwechsel") ist entfallen: beide Aussagen stehen jetzt
    -- dort, wo sie gelten - der Scan-Hinweis in der Akzentkarte, die
    -- Klickbarkeit zeigen die Kennzahlenkarten selbst beim Ueberfahren.
    bc:SetHeight(math.abs(rowY) + 32)

    uebersichtFrame:Show()
end

--------------------------------------------------
-- SEITE: WERTEVERTEILUNG (Stats + Caps)
-- (STAT_LABELS/STAT_ORDER/CollectEquippedStats stehen weiter oben vor
-- SEITE: ÜBERSICHT, da beide Seiten sie nutzen)
--------------------------------------------------

local werteFrame = nil

--------------------------------------------------
-- EINE TEMPO-TREPPE ZEICHNEN
--
-- Die Seite muss drei verschiedene Lagen erklaeren, und sie raten zu
-- Verschiedenem — deshalb steht hier keine Zahl ohne ihren Satz:
--   * Ziel voraus       -> so viel fehlt noch
--   * Stufe erreicht,
--     naechste zu weit  -> so viel liegt daneben, und wohin damit
--   * nichts erreichbar -> ausdruecklich KEINE Aussage
--
-- Und die Treppe selbst steht mit da. Ohne sie waere "Ziel 25,0 %" eine
-- Zahl, die man glauben muss; mit ihr ist sie eine Stufe mit Namen, die
-- man im Zauberbuch nachsehen kann — und die man mit einem Klick gegen
-- eine andere tauscht, denn welche Stufe man anpeilt, weiss der Spieler
-- besser als diese Rechnung.
--
-- Gibt genutzte Hoehe zurueck.
--------------------------------------------------

-- Wieviele Stufen der Treppe werden gezeigt? Die Liste einer DoT-Spec hat
-- bis zu drei Dutzend Sprossen, und die oberen sind mit MoP-Ausruestung
-- nicht zu erreichen. Gezeigt wird das Fenster um den Istwert.
local LADDER_BELOW, LADDER_ABOVE = 2, 4

-- Gemessene statt geschaetzter Texthoehe, mit derselben Absicherung wie in
-- modules/settings.lua: die Saetze brechen um, und ein noch nicht
-- gezeichneter FontString meldet mitunter 0 - mit festen Abstaenden laege
-- die naechste Zeile dann darin.
local function TextHeight(fs, minimum)
    local ok, h = pcall(fs.GetStringHeight, fs)
    if not ok or type(h) ~= "number" or h <= 0 then return minimum end
    return math.max(minimum, math.ceil(h))
end

local function DrawBreakpointSection(parent, x, y, w, bp, onChange)
    local top = y

    local function Line(text, size, indent)
        local fs = parent:CreateFontString(nil, "OVERLAY")
        fs:SetFont(WeintCodex.Fonts.sans, size or 9, "")
        fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x + (indent or 0), y)
        fs:SetWidth(w - (indent or 0))
        fs:SetJustifyH("LEFT")
        fs:SetText(text)
        y = y - (TextHeight(fs, 12) + 4)
        return fs
    end

    -- Kopfzeile: Istwert und Ziel
    local head
    if bp.capPct then
        head = string.format("%s%s|r  |cffddddff%.1f%% / %.1f%%|r  %s",
            StatusColorStr(bp.capped and "overcap" or "optimal"), bp.label,
            bp.current, bp.capPct,
            bp.capped
                and string.format("|cffcc88ff~%d Wertung hinter der Schwelle|r",
                                  math.floor((bp.overRating or 0) + 0.5))
                or  string.format("|cffFFBB22~%d Wertung bis zur Schwelle|r",
                                  math.ceil(bp.underRating or 0)))
    else
        head = string.format("%s%s|r  |cffddddff%.1f%%|r  |cff888888kein Ziel|r",
            StatusColorStr("neutral"), bp.label, bp.current)
    end
    Line(head, 10)

    -- Balken (nur mit Ziel — ohne Ziel gibt es keinen Bezugswert)
    if bp.capPct and bp.capPct > 0 then
        local barBg = parent:CreateTexture(nil, "ARTWORK")
        barBg:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
        barBg:SetSize(w, 7)
        barBg:SetColorTexture(C.surface3[1], C.surface3[2], C.surface3[3], 0.90)

        local frac = bp.current / bp.capPct
        if frac > 1 then frac = 1 elseif frac < 0 then frac = 0 end
        if frac > 0.01 then
            local col = STATUS[bp.capped and "overcap" or "optimal"].color
            local bar = parent:CreateTexture(nil, "OVERLAY")
            bar:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
            bar:SetSize(math.max(2, w * frac), 7)
            bar:SetColorTexture(col[1], col[2], col[3], 0.85)
        end
        y = y - 13
    end

    -- Der Satz zur Lage.
    if bp.targetSource == "aus" then
        Line("|cff888888Schwellen für diese Spec abgeschaltet — Tempo zählt"
            .. " wie jeder andere Wert.|r", 9)
    elseif bp.outOfReach then
        Line("|cff888888Noch keine Stufe erreicht und keine in Reichweite —"
            .. " deshalb wird hier nichts behauptet und Tempo bleibt"
            .. " ungedeckelt.|r", 9)
    elseif bp.capped then
        local why
        if bp.nextRung and bp.targetSource == "spieler" then
            why = string.format(
                "Die nächste (%s, %.1f%%) läge ~%d Wertung höher — dein Ziel"
                .. " steht darunter.",
                bp.nextRung.label, bp.nextRung.pct,
                math.ceil((bp.nextRung.pct - bp.current) * bp.perPct))
        elseif bp.nextRung then
            why = string.format(
                "Die nächste (%s, %.1f%%) ist ~%d Wertung entfernt — mit"
                .. " Umschmieden und Sockeln sind höchstens ~%d zu bewegen.",
                bp.nextRung.label, bp.nextRung.pct,
                math.ceil((bp.nextRung.pct - bp.current) * bp.perPct),
                math.floor(bp.reach + 0.5))
        else
            why = "Darüber gibt es keine Stufe mehr."
        end
        Line(string.format("|cffcc88ffErreicht: %s (%.1f%%)%s. %s|r",
            (bp.reached and bp.reached.label) or "—", bp.capPct or 0,
            (bp.targetSource == "spieler") and " |cff888888(selbst gesetzt)|r" or "",
            why), 9)
        Line("|cffcc88ffWeiteres Tempo bringt keinen Tick mehr. Der Planer"
            .. " schlägt deshalb keine Temposteine mehr vor; was daneben"
            .. " liegt, gehört umgeschmiedet.|r", 9)
    elseif bp.target then
        Line(string.format(
            "|cffFFBB22Ziel: %s (%.1f%%)%s — es fehlen ~%d Wertung.|r",
            bp.target.label or "—", bp.target.pct,
            (bp.targetSource == "spieler") and " |cff888888(selbst gesetzt)|r" or "",
            math.ceil(bp.underRating or 0)), 9)
    end

    -- Woraus die Reichweite besteht. Ausdruecklich als Obergrenze
    -- beschriftet: die Werte kommen aus GetItemStats, und ob der Client
    -- eine bereits umgeschmiedete Verteilung meldet, ist von hier aus
    -- nicht zu belegen.
    Line(string.format(
        "|cff4A4A52Reichweite höchstens ~%d Wertung: Umschmieden bis ~%d"
        .. " (40 %% je Gegenstand) · %d Sockel ~%d · %d Wertung je Prozentpunkt%s.|r",
        math.floor(bp.reach + 0.5), math.floor(bp.reforgeGain + 0.5),
        bp.socketCount or 0, math.floor(bp.socketReserve + 0.5),
        math.floor(bp.perPct + 0.5),
        (bp.buffFactor and bp.buffFactor > 1.001)
            and string.format(" (Buffs ×%.2f eingerechnet)", bp.buffFactor) or ""), 8)

    if bp.note then
        Line("|cff4A4A52" .. bp.note .. "|r", 8)
    end

    -- Die Treppe.
    local ladder = bp.ladder or {}
    local currentIndex = 0
    for i, rung in ipairs(ladder) do
        if rung.pct <= bp.current + 0.001 then currentIndex = i end
    end
    local from = math.max(1, currentIndex - LADDER_BELOW + 1)
    local to   = math.min(#ladder, currentIndex + LADDER_ABOVE)

    y = y - 4
    for i = from, to do
        local rung = ladder[i]
        local reached = rung.pct <= bp.current + 0.001
        local isTarget = bp.target and math.abs(bp.target.pct - rung.pct) < 0.01

        local row = parent:CreateFontString(nil, "OVERLAY")
        row:SetFont(WeintCodex.Fonts.mono or WeintCodex.Fonts.sans, 9, "")
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", x + 8, y)
        row:SetWidth(w - 70)
        row:SetJustifyH("LEFT")
        row:SetText(string.format("%s%s %5.1f %%  %s|r%s",
            isTarget and "|cffD4A24A" or (reached and "|cff22C55E" or "|cff6B6B74"),
            isTarget and "\226\150\184" or (reached and "\226\151\143" or "\226\151\139"),
            rung.pct, rung.label,
            (not reached) and string.format("|cff4A4A52  (~%d Wertung)|r",
                math.ceil((rung.pct - bp.current) * bp.perPct)) or ""))

        if onChange then
            local btn = MakeBtn(parent, isTarget and "Ziel" or "als Ziel", 56, 16, function()
                WeintCodex.Charakter.SetStatTarget(bp.stat,
                    { mode = "stufe", pct = rung.pct, label = rung.label })
                onChange()
            end)
            btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x + w - 60, y + 1)
        end
        y = y - 16
    end

    if to < #ladder then
        Line(string.format("|cff3A3A42… %d weitere Stufen, alle jenseits"
            .. " dessen, was MoP-Ausrüstung hergibt.|r", #ladder - to), 8, 8)
    end

    -- Umschalter: die Rechnung, eine eigene Stufe (oben je Sprosse) oder aus.
    if onChange then
        y = y - 2
        local auto = MakeBtn(parent, "Automatisch", 100, 18, function()
            WeintCodex.Charakter.SetStatTarget(bp.stat, nil)
            onChange()
        end)
        auto:SetPoint("TOPLEFT", parent, "TOPLEFT", x + 8, y)

        local off = MakeBtn(parent, "Schwellen aus", 110, 18, function()
            WeintCodex.Charakter.SetStatTarget(bp.stat, { mode = "aus" })
            onChange()
        end)
        off:SetPoint("TOPLEFT", parent, "TOPLEFT", x + 116, y)
        y = y - 24
    end

    return top - y
end

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
    divider:SetPoint("TOPLEFT",  werteFrame, "TOPLEFT",  16, -HEAD_H)
    divider:SetPoint("TOPRIGHT", werteFrame, "TOPRIGHT", -16, -HEAD_H)
    divider:SetHeight(1)
    divider:SetColorTexture(C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1.0)

    -- BILDLAUF STATT FESTER FLAECHE.
    --
    -- Bis 2.6.1.1 waren es zwei Abschnitte auf einer festen Flaeche, und das
    -- ging gerade so auf. Mit der Tempo-Treppe kommt ein dritter dazu, der
    -- je nach Spec unterschiedlich lang ist — als feste Flaeche liefe er
    -- unten heraus statt abgeschnitten zu werden, und zwar unerreichbar
    -- (dieselbe Falle wie beim Changelog-Popup, siehe core/onboarding.lua).
    -- Die Groesse kommt aus Ankern, nicht aus einer Messung: CreateScrollArea
    -- verlangt Pixelmasse, also wird danach umgehaengt.
    local sf, body = WeintCodex.CreateScrollArea(werteFrame, 16, -(HEAD_H + 14),
        100, 100, true)
    sf:ClearAllPoints()
    sf:SetPoint("TOPLEFT",     werteFrame, "TOPLEFT",  16, -(HEAD_H + 14))
    sf:SetPoint("BOTTOMRIGHT", werteFrame, "BOTTOMRIGHT", -16, 26)
    sf.scrollBarHideable = true
    local BODY_W = 430
    -- Untergrenze, falls OnSizeChanged nicht mehr feuert (der Rahmen hat
    -- seine Groesse aus den Ankern schon, bevor der Handler haengt).
    body:SetWidth(BODY_W + 10)
    sf:SetScript("OnSizeChanged", function(self, w)
        if w and w > 20 then body:SetWidth(w - 10) end
    end)

    local yOff = 0

    -- =============================================
    -- CAPS
    -- =============================================
    local capHdr = body:CreateFontString(nil, "OVERLAY")
    capHdr:SetFont(WeintCodex.Fonts.sans, 10, "")
    capHdr:SetPoint("TOPLEFT", body, "TOPLEFT", 0, yOff)
    capHdr:SetText("|cff4A4A52— SEKUNDÄRSTAT-CAPS (live vom Charakterbogen) —|r")
    yOff = yOff - 20

    if #scan.caps == 0 then
        local none = body:CreateFontString(nil, "OVERLAY")
        none:SetFont(WeintCodex.Fonts.sans, 10, "")
        none:SetPoint("TOPLEFT", body, "TOPLEFT", 0, yOff)
        none:SetText(scan.profile
            and "|cff4A4A52Für diese Spec gibt es keine Pflicht-Caps (Heiler).|r"
            or  "|cffff9900Kein Spec-Profil — Caps können nicht geprüft werden.|r")
        yOff = yOff - 24
    else
        for _, cs in ipairs(scan.caps) do
            yOff = yOff - DrawCapBar(body, 0, yOff, BODY_W, cs)
            if cs.note then
                local note = body:CreateFontString(nil, "OVERLAY")
                note:SetFont(WeintCodex.Fonts.sans, 8, "")
                note:SetPoint("TOPLEFT", body, "TOPLEFT", 0, yOff)
                note:SetText("|cff4A4A52" .. cs.note .. "|r")
                yOff = yOff - 14
            end
            -- Ein Ueberschuss, den der Umschmiede-Plan ohnehin verschiebt,
            -- ist kein Handlungsbedarf. Ihn trotzdem als "verschwendet" zu
            -- melden, ist die Sorte Fehlmeldung, wegen der man einer Seite
            -- nicht mehr glaubt — und der Grund gehoert dazu, sonst
            -- verschwindet der Befund einfach kommentarlos.
            if cs.reforgeFixes then
                local fixed = body:CreateFontString(nil, "OVERLAY")
                fixed:SetFont(WeintCodex.Fonts.sans, 8, "")
                fixed:SetPoint("TOPLEFT", body, "TOPLEFT", 10, yOff)
                fixed:SetWidth(BODY_W - 10)
                fixed:SetJustifyH("LEFT")
                fixed:SetText(WeintCodex.ColorText("green",
                    "> Der Umschmiede-Plan verschiebt den Überschuss bereits —"
                    .. " kein Stein und keine Verzauberung ist deswegen verschwendet."))
                yOff = yOff - 13
            end
            if cs.overPct > 0.25 and #cs.wasted > 0 then
                for _, w in ipairs(cs.wasted) do
                    local src = body:CreateFontString(nil, "OVERLAY")
                    src:SetFont(WeintCodex.Fonts.sans, 8, "")
                    src:SetPoint("TOPLEFT", body, "TOPLEFT", 10, yOff)
                    local nm
                    if w.art == "Stein" then
                        nm = GetGemDisplayName(w.row.gemId)
                    else
                        nm = w.row.displayName or GetEnchantDisplayName(w.row.enchId)
                    end
                    src:SetText(string.format("|cffcc88ff> %s: %s (%s, +%d) umschmieden oder tauschen|r",
                        w.row.slotName or "?", nm or "?", w.art, w.value))
                    yOff = yOff - 13
                end
            end
            yOff = yOff - 4
        end
    end

    yOff = yOff - 10

    -- =============================================
    -- TEMPO-SCHWELLEN
    -- =============================================
    local bpHdr = body:CreateFontString(nil, "OVERLAY")
    bpHdr:SetFont(WeintCodex.Fonts.sans, 10, "")
    bpHdr:SetPoint("TOPLEFT", body, "TOPLEFT", 0, yOff)
    bpHdr:SetText("|cff4A4A52— TEMPO-SCHWELLEN (aus Laufzeit und Tickabstand gerechnet) —|r")
    yOff = yOff - 20

    if #scan.breakpoints == 0 then
        local none = body:CreateFontString(nil, "OVERLAY")
        none:SetFont(WeintCodex.Fonts.sans, 9, "")
        none:SetPoint("TOPLEFT", body, "TOPLEFT", 0, yOff)
        none:SetWidth(BODY_W)
        none:SetJustifyH("LEFT")
        none:SetText("|cff4A4A52Für diese Spec sind keine Tempo-Schwellen"
            .. " hinterlegt — Tempo zählt hier wie jeder andere Sekundärwert."
            .. " Das ist keine Lücke, sondern die Aussage: eine erfundene"
            .. " Schwelle wäre die schlechtere Auskunft (siehe"
            .. " data/breakpoints.lua).|r")
        yOff = yOff - (TextHeight(none, 40) + 10)
    else
        for _, bp in ipairs(scan.breakpoints) do
            yOff = yOff - DrawBreakpointSection(body, 0, yOff, BODY_W, bp,
                                                ShowWerteverteilung)
            yOff = yOff - 6
        end
    end

    yOff = yOff - 6

    -- =============================================
    -- STAT-SUMMEN
    -- =============================================
    local hdr = body:CreateFontString(nil, "OVERLAY")
    hdr:SetFont(WeintCodex.Fonts.sans, 10, "")
    hdr:SetPoint("TOPLEFT", body, "TOPLEFT", 0, yOff)
    hdr:SetText("|cff4A4A52— WERTE-SUMMEN DER AUSRÜSTUNG —|r")
    yOff = yOff - 22

    local totals = CollectEquippedStats()
    local anyStat = false
    for _, key in ipairs(STAT_ORDER) do
        local value = totals[key]
        if value and value > 0 then
            anyStat = true
            local row = CreateFrame("Frame", nil, body)
            row:SetSize(BODY_W, 20)
            row:SetPoint("TOPLEFT", body, "TOPLEFT", 0, yOff)
            SetSolidBg(row, C.surface2[1], C.surface2[2], C.surface2[3], 0.55)

            local lbl = row:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(WeintCodex.Fonts.sans, 10, "")
            lbl:SetPoint("LEFT", row, "LEFT", 10, 0)
            lbl:SetText(STAT_LABELS[key])
            lbl:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])

            local val = row:CreateFontString(nil, "OVERLAY")
            val:SetFont(WeintCodex.Fonts.sans, 10, "")
            val:SetPoint("RIGHT", row, "RIGHT", -10, 0)
            val:SetText("|cffD4A24A+" .. value .. "|r")

            yOff = yOff - 22
        end
    end

    if not anyStat then
        local none = body:CreateFontString(nil, "OVERLAY")
        none:SetFont(WeintCodex.Fonts.sans, 12, "")
        none:SetPoint("TOPLEFT", body, "TOPLEFT", 0, yOff)
        none:SetText("|cffaaaaaaKeine Werte ermittelt (Charakter einloggen / Items anlegen).|r")
        yOff = yOff - 24
    end

    -- Erst Text, dann gemessene Hoehe, dann Hoehe des Bildlaufinhalts —
    -- die Sichtbarkeit der Leiste haengt an der Differenz zur Sichtflaeche.
    body:SetHeight(math.max(10, -yOff + 10))

    local hint = werteFrame:CreateFontString(nil, "OVERLAY")
    hint:SetFont(WeintCodex.Fonts.sans, 9, "")
    hint:SetPoint("BOTTOMLEFT", werteFrame, "BOTTOMLEFT", 16, 8)
    hint:SetText("|cff3A3A42Cap- und Tempowerte kommen live vom Charakterbogen"
        .. " (inkl. Rassenboni & Buffs). Summen = reine Item-Stats.|r")

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
    for _, bp in ipairs(scan.breakpoints) do
        capRows[#capRows + 1] = {
            label = bp.label,
            value = bp.capPct
                and string.format("%.1f%% / %.1f%%", bp.current, bp.capPct)
                or  string.format("%.1f%% · kein Ziel", bp.current),
            valueColor = bp.capped and "violet"
                         or bp.capPct and "warning" or "textFaint",
        }
    end
    if #capRows == 0 then
        capRows[1] = { label = "Keine Pflicht-Caps für diese Spec", valueColor = "textFaint" }
    end
    ShowScoreInspector(nil, {
        { type = "header", text = "Caps & Schwellen" },
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
        warn:SetFont(WeintCodex.Fonts.sans, 12, "")
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
    desc:SetFont(WeintCodex.Fonts.sans, 9, "")
    desc:SetPoint("TOPLEFT",  prioFrame, "TOPLEFT",  16, -HEAD_H)
    -- Rechte Kante verankert statt Breite aus cp:GetWidth() gerechnet: der
    -- Detailbereich erscheint erst am Ende dieser Funktion und nimmt dem
    -- Inhalt dann 372 px weg. Eine zur Bauzeit gemessene Breite laege
    -- danach darunter.
    desc:SetPoint("TOPRIGHT", prioFrame, "TOPRIGHT", -16, -HEAD_H)
    desc:SetJustifyH("LEFT")
    desc:SetText("|cff4A4A52Gewichte 0-999: je höher, desto wichtiger ist der Wert für DICH (0 = egal). "
        .. "Wirkt auf die Stein-Bewertung (Qualitäts-%, OK/Falsch) und die Empfehlungsauswahl bei Cap-Überschuss. "
        .. "Empfehlungslisten der Spec und Treffer-/Waffenkunde-Caps bleiben unverändert.|r")

    -- Aktiv-Schalter
    local cb = CreateFrame("CheckButton", nil, prioFrame, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    cb:SetPoint("TOPLEFT", prioFrame, "TOPLEFT", 12, -84)
    cb:SetChecked(entry and entry.enabled and true or false)

    local cbLbl = prioFrame:CreateFontString(nil, "OVERLAY")
    cbLbl:SetFont(WeintCodex.Fonts.sans, 11, "")
    cbLbl:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    cbLbl:SetText("|cffddddffEigene Gewichtung verwenden|r |cff4A4A52(für " .. (specDisplay or profileKey) .. ")|r")

    -- Eingabefelder
    local boxes = {}
    local yOff = -116

    for _, st in ipairs(WEIGHT_STATS) do
        local row = CreateFrame("Frame", nil, prioFrame)
        row:SetSize(430, 22)
        row:SetPoint("TOPLEFT", prioFrame, "TOPLEFT", 16, yOff)
        SetSolidBg(row, C.surface2[1], C.surface2[2], C.surface2[3], 0.55)

        local lbl = row:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(WeintCodex.Fonts.sans, 10, "")
        lbl:SetPoint("LEFT", row, "LEFT", 10, 0)
        lbl:SetText(st.label)
        lbl:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])

        local def = row:CreateFontString(nil, "OVERLAY")
        def:SetFont(WeintCodex.Fonts.sans, 9, "")
        def:SetPoint("RIGHT", row, "RIGHT", -70, 0)
        def:SetText("|cff4A4A52Standard: " .. (defaults[st.key] or 0) .. "|r")

        local eb = CreateFrame("EditBox", nil, row)
        eb:SetSize(48, 18)
        eb:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        eb:SetAutoFocus(false)
        eb:SetNumeric(true)
        eb:SetMaxLetters(3)
        eb:SetFont(WeintCodex.Fonts.sans, 11, "")
        eb:SetJustifyH("CENTER")
        eb:SetTextInsets(4, 4, 0, 0)
        SetSolidBg(eb, C.surface2[1], C.surface2[2], C.surface2[3], 0.95)
        DrawBorder(eb, C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1.0, 1)
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
        print("|cffD4A24A[WeintCodex]|r Gewichtung für " .. (specDisplay or profileKey) .. " gespeichert"
            .. (cb:GetChecked() and " und aktiviert." or " (derzeit deaktiviert)."))
        ShowPriorisierung()
    end)
    saveBtn:SetPoint("TOPLEFT", prioFrame, "TOPLEFT", 16, yOff - 8)

    local resetBtn = MakeBtn(prioFrame, "Auf Standard zurücksetzen", 180, 24, function()
        sd.customWeights[effKey] = nil
        print("|cffD4A24A[WeintCodex]|r Gewichtung für " .. (specDisplay or profileKey) .. " auf Standard zurückgesetzt.")
        ShowPriorisierung()
    end)
    resetBtn:SetPoint("TOPLEFT", prioFrame, "TOPLEFT", 186, yOff - 8)

    local hint = prioFrame:CreateFontString(nil, "OVERLAY")
    hint:SetFont(WeintCodex.Fonts.sans, 9, "")
    hint:SetPoint("BOTTOMLEFT", prioFrame, "BOTTOMLEFT", 16, 6)
    hint:SetText("|cff3A3A42Gilt pro Spec (Tanks: getrennt für Offensiv/Defensiv). Wird pro Account gespeichert.|r")

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

    WeintCodex.SetBreadcrumb("Charakter", "Twinkverwaltung")

    local twinkHead = WeintCodex.PageHead(twinkFrame, {
        eyebrow = "Charakter",
        title = "Twinkverwaltung", titleSize = 20,
        sub = "Gildenmitglieder scannen und eigene Twinks auswählen. Export für den WeintCodex Discord-Bot.",
        subSize = 10, subColor = "textFaint", subWidth = 640,
        x = 16, y = 14, height = HEAD_H - 14,
    })
    local title = twinkHead.Title

    if refreshBtn then refreshBtn:Hide() end

    if not twinkScanBtn then
        twinkScanBtn = WeintCodex.CreateCard(WeintCodex.TitleBarActions, { width = 106, height = 30, buttonStyle = true })
        twinkScanBtn:SetPoint("TOPRIGHT", WeintCodex.TitleBarActions, "TOPRIGHT", -108, -11)
        local l1 = twinkScanBtn:CreateFontString(nil, "OVERLAY")
        l1:SetAllPoints(twinkScanBtn)
        l1:SetFont(WeintCodex.Fonts.sans, 11, "")
        l1:SetJustifyH("CENTER")
        l1:SetText("Gilde scannen")
        l1:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
        twinkScanBtn:SetScript("OnEnter", function(self) self:SetSurface("surface3") end)
        twinkScanBtn:SetScript("OnLeave", function(self) self:SetSurface("surface2") end)

        twinkExportBtn = WeintCodex.CreateCard(WeintCodex.TitleBarActions, { width = 96, height = 30, buttonStyle = true })
        twinkExportBtn:SetPoint("TOPRIGHT", WeintCodex.TitleBarActions, "TOPRIGHT", 0, -11)
        local l2 = twinkExportBtn:CreateFontString(nil, "OVERLAY")
        l2:SetAllPoints(twinkExportBtn)
        l2:SetFont(WeintCodex.Fonts.sans, 11, "")
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

    local sf, inner = CreateScrollArea(twinkFrame, 14, -HEAD_H, 20, 400)
    sf:ClearAllPoints()
    sf:SetPoint("TOPLEFT",     twinkFrame, "TOPLEFT",     14, -HEAD_H)
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
            msg:SetFont(WeintCodex.Fonts.sans, 12, "")
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
            "Twinkverwaltung %s",
            WeintCodex.ColorText("textFaint",
                "(" .. (numMembers or 0) .. " Mitglieder gefunden)")))

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

                    -- Sofort ans Companion melden statt erst beim naechsten
                    -- PLAYER_LOGIN (siehe core/main.lua): ReportCharacter()
                    -- liest ohnehin die komplette aktuelle Auswahl neu ein,
                    -- ein Aufruf hier verhindert nur, dass eine frisch
                    -- angehakte Auswahl einen ganzen Relog lang unversendet
                    -- in den SavedVariables liegen bleibt.
                    if WeintCodex.Companion and WeintCodex.Companion.ReportCharacter then
                        WeintCodex.Companion.ReportCharacter()
                    end
                end)

                local nameLbl = row:CreateFontString(nil, "OVERLAY")
                nameLbl:SetFont(WeintCodex.Fonts.sans, 10, "")
                nameLbl:SetPoint("LEFT", row, "LEFT", 30, 0)
                nameLbl:SetWidth(140)
                nameLbl:SetJustifyH("LEFT")
                nameLbl:SetText(shortName .. (shortName == playerName and " |cffD4A24A(Du)|r" or ""))
                nameLbl:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])

                local classLbl = row:CreateFontString(nil, "OVERLAY")
                classLbl:SetFont(WeintCodex.Fonts.sans, 10, "")
                classLbl:SetPoint("LEFT", row, "LEFT", 180, 0)
                classLbl:SetWidth(120)
                classLbl:SetJustifyH("LEFT")
                classLbl:SetText(class or "—")
                classLbl:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])

                local lvlLbl = row:CreateFontString(nil, "OVERLAY")
                lvlLbl:SetFont(WeintCodex.Fonts.sans, 10, "")
                lvlLbl:SetPoint("LEFT", row, "LEFT", 300, 0)
                lvlLbl:SetText("Stufe " .. (level or "?"))
                lvlLbl:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])

                local onlineLbl = row:CreateFontString(nil, "OVERLAY")
                onlineLbl:SetFont(WeintCodex.Fonts.sans, 10, "")
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
    foot:SetFont(WeintCodex.Fonts.sans, 9, "")
    foot:SetPoint("BOTTOMLEFT", twinkFrame, "BOTTOMLEFT", 16, 8)
    foot:SetText("|cff3A3A42Format: WCEXPORT:TWINK:DATUM:Name|KLASSE|STUFE|NOTIZ,...|r")

    DrawRoster()
    twinkFrame:Show()
end

--------------------------------------------------
-- CHARAKTER.SHOW – Sidebar aufbauen
--------------------------------------------------

function WeintCodex.Charakter.Show()
    activeCharakterView = nil
    -- Sechs Reiter, flach, in der Reihenfolge des Entwurfs (2a). Die
    -- Zwischenueberschriften (— AUSRÜSTUNG — usw.) gliederten die alte hohe
    -- Spalte; in einer Leiste haben sie keine Entsprechung.
    --
    -- Die drei Academy-Eintraege sind hier raus: die Academy ist seit
    -- 2.0.0.0 ein eigener Navigationspunkt mit eigener Reiterleiste. Sie
    -- hing hier, weil Bewertung und Lektionen zum Charakter gehoeren - das
    -- traegt jetzt die Navigationsgruppe "Charakter", die beide enthaelt.
    local items = {
        { label = "Übersicht",       onClick = ShowUebersicht },
        { label = "Verzauberungen",  onClick = ShowEnchants },
        { label = "Sockel",          onClick = ShowGems },
        { label = "Werteverteilung", onClick = ShowWerteverteilung },
    }

    -- UMSCHMIEDEN STEHT NUR DA, WENN ES EINGESCHALTET IST.
    --
    -- Das Werkzeug ist in Entwicklung und gibt Gold aus; es darf niemandem
    -- passieren, sondern muss unter Einstellungen -> Umschmieden
    -- eingeschaltet werden (siehe modules/reforge_engine.lua). Ein Reiter,
    -- der ausgegraut dasteht, waere die halbe Loesung: er verspricht etwas,
    -- das nicht da ist. Der Eintrag wird bei jedem Aufbau der Seitenleiste
    -- neu entschieden, also ist der Schalter sofort wirksam.
    --
    -- Der Eintrag haengt hier und nicht in der Navigationsspalte: dort ist
    -- kein Platz mehr (die Rechnung steht ueber der tabs-Tabelle in
    -- core/navigation.lua), und die Frage "wohin mit der Wertung" gehoert
    -- ohnehin neben Sockel und Werteverteilung. Gezeichnet wird sie von
    -- modules/reforge.lua; darum ruft jene Seite Charakter.LeaveView() auf.
    if WeintCodex.ReforgeEngine and WeintCodex.ReforgeEngine.Enabled()
       and WeintCodex.Reforge and WeintCodex.Reforge.ShowPage then
        items[#items + 1] = { label = "Umschmieden",
                              onClick = WeintCodex.Reforge.ShowPage }
    end

    items[#items + 1] = { label = "Priorisierung", onClick = ShowPriorisierung }
    items[#items + 1] = { label = "Twinks",        onClick = ShowTwinkverwaltung }

    WeintCodex.Navigation.BuildSidebar("Charakter", items)
    WeintCodex.Navigation.ActivateFirst()
end

-- Direkteinstieg fuer die globale Suche (core/search.lua): baut die normale
-- Charakter-Seite auf und wechselt danach sofort auf die Zielansicht, statt
-- immer bei "Uebersicht" zu landen.
function WeintCodex.Charakter.ShowEnchants()
    WeintCodex.Charakter.Show()
    ShowEnchants()
end

function WeintCodex.Charakter.ShowGems()
    WeintCodex.Charakter.Show()
    ShowGems()
end
