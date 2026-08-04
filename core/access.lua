--------------------------------------------------
-- WeintCodex :: Zugriffsprofile & Freigaben
--------------------------------------------------
-- WICHTIG, damit niemand das hier fuer mehr haelt als es ist:
-- WeintCodex_SavedData ist eine editierbare Lua-Datei auf dem Rechner des
-- Spielers. Jeder kann dort features["materials.view"] = true setzen. Dieses
-- System ist DATENHYGIENE UND UX, KEINE SICHERHEITSGRENZE. Seine Aufgabe ist:
--   a) die Companion eines Extern-Raiders vermischt nie zwei Gilden,
--   b) niemand sieht eine UI voller Zahlen, die ihn nichts angehen,
--   c) von einem nicht berechtigten Client geht nichts Gildeninternes hinaus.
--
-- Erzwingen koennte das nur der Discord-Bot, indem er eine Nutzlast fuer eine
-- Rolle ohne Berechtigung gar nicht erst ausliefert. Solange er das nicht tut,
-- ist die Wirkung genau die oben genannte und keine weitere: die
-- Community-Bindung verhindert das Vermischen zweier Gilden, die Freigaben
-- halten die Oberflaeche ehrlich. Vertraulichkeit leistet das nicht.
--
-- Die Zuordnung Discord-Rolle -> Freigaben liegt in WeintCompanion. Sie ist
-- damit ebenfalls eine Datei auf dem Rechner des Spielers - dieselbe
-- Einschraenkung wie oben, aus demselben Grund.
--------------------------------------------------
-- Vertrag Companion -> Addon: Inbox-Nachrichtentyp "access_profile"
-- (siehe modules/companion.lua, dort stehen die uebrigen Nutzlasten).
-- Braucht WeintCompanion ab 1.4.0 - erst diese Version fragt die
-- Discord-Rolle ab und stellt das Profil zu.
--
--   access_profile { community = { id = "<Discord-Guild-ID>", name = "<Name>" },
--                    identity  = { discordId, discordName },
--                    tier      = "gast"|"extern"|"mitglied"|"offizier",
--                    tierLabel = "Raidgast",           -- Anzeigetext, frei
--                    roles     = { "Raidgast", ... },  -- nur Anzeige/Support
--                    features  = { ["raids.view"] = true, ... },
--                    issuedAt  = <unix>,
--                    expiresAt = <unix>|0,             -- 0/nil = laeuft nie ab
--                    companionVersion = "1.4.0",
--                    notice    = "" }                  -- optional, Sperrseite
--
-- community.id ist ein STRING. Discord-Snowflakes als Lua-5.1-Zahl werden zu
-- "1.23456789012346e+18" und wuerden gegen den Dezimalstring der Companion
-- nie gleich vergleichen - jede Nachricht waere damit "fremd".
--
-- Bindung: Das Addon bindet sich beim ersten Profil an GENAU EINE Community.
-- Nachrichten und Import-Strings einer anderen Community werden abgewiesen,
-- nicht zusammengefuehrt (genau das ist der Zweck). Ein Wechsel geht nur
-- ueber /wc access reset und loescht dabei die gildeninternen Daten.
--
-- Ohne Profil verhaelt sich das Addon wie vor 1.2.0.0: alles offen. Gating
-- greift erst, wenn eine Companion ein Profil geliefert hat.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.Access = {}

local C = WeintCodex.Colors

--------------------------------------------------
-- Freigaben
--------------------------------------------------
-- Die Bot-Liste (profile.features) gewinnt immer. TIER_FEATURES ist nur der
-- Rueckfall fuer Keys, die der Bot (noch) nicht mitschickt - dadurch braucht
-- eine neue Discord-Rolle kein Addon-Release.
--
-- ACHTUNG bei Aenderungen: calendar.view impliziert Roster-Sichtbarkeit, denn
-- modules/calendar.lua liest die Anmeldungen fuer die Einladungsvorschau. Die
-- Matrix darf calendar.view deshalb nie ohne raids.view gewaehren.
--------------------------------------------------

local TIER_ORDER = { "gast", "extern", "mitglied", "offizier" }

local TIER_FEATURES = {

    gast = {},

    extern = {
        ["raids.view"]      = true,
        ["calendar.view"]   = true,
        ["bossguides.tips"] = true,
    },

    mitglied = {
        ["raids.view"]      = true,
        ["calendar.view"]   = true,
        ["bossguides.tips"] = true,
        ["materials.view"]  = true,
        ["materials.scan"]  = true,
        ["weinttv.raid"]    = true,
        ["loot.report"]     = true,
    },

    offizier = {
        ["raids.view"]      = true,
        ["raids.edit"]      = true,
        ["calendar.view"]   = true,
        ["calendar.invite"] = true,
        ["materials.view"]  = true,
        ["materials.scan"]  = true,
        ["bossguides.tips"] = true,
        ["weinttv.raid"]    = true,
        ["loot.report"]     = true,
    },

}

-- Reihenfolge fuer /wc access - alle bekannten Keys, damit die Ausgabe
-- vollstaendig ist und nicht von pairs() abhaengt.
local FEATURE_ORDER = {
    "raids.view", "raids.edit",
    "calendar.view", "calendar.invite",
    "materials.view", "materials.scan",
    "bossguides.tips", "weinttv.raid", "loot.report",
}

WeintCodex.Access.FEATURE_ORDER = FEATURE_ORDER

-- Was ein ABGELAUFENES Profil noch darf: lesen, was schon auf der Platte
-- liegt. Es wegzusperren waere Theater - die Daten sind ja bereits da. Die
-- Zaehne sitzen bei IngestAllowed(): es kommt nichts Neues mehr herein.
local STALE_FEATURES = {
    ["raids.view"]      = true,
    ["calendar.view"]   = true,
    ["materials.view"]  = true,
    ["bossguides.tips"] = true,
}

local GRACE_SECONDS = 14 * 24 * 60 * 60
local SKEW_SECONDS  = 24 * 60 * 60

--------------------------------------------------
-- Texte (ASCII-Transliteration wie in den neueren Modulen)
--------------------------------------------------

local MSG_NO_PROFILE = "Kein Zugriffsprofil vorhanden - alle Bereiche sind offen (Standard)."

local MSG_BOUND   = "Addon mit der Community \"%s\" verknuepft."
local MSG_PROFILE = "Zugriffsprofil aktualisiert: %s - Rang %s."

local MSG_FOREIGN_PROFILE = "Das gelieferte Zugriffsprofil gehoert zu einer anderen Community "
    .. "(\"%s\"). Dieses Addon ist mit \"%s\" verknuepft und wurde nicht umgestellt. "
    .. "Ein Wechsel geht nur ueber /wc access reset."

local MSG_FOREIGN_INBOX = "%d Nachricht(en) einer anderen Community verworfen. Dieses Addon ist "
    .. "mit \"%s\" verknuepft. Ein Wechsel geht nur ueber /wc access reset."

local MSG_UNKNOWN_TIER = "Unbekannter Rang \"%s\" - bitte WeintCompanion und den Discord-Bot "
    .. "aktualisieren. Bis dahin sind nur ausdruecklich freigegebene Bereiche offen."

local MSG_STALE_GRACE = "Dein Zugriffsprofil laeuft ab (seit %d Tag(en) faellig). Starte "
    .. "WeintCompanion, damit es erneuert wird."

local MSG_STALE_EXPIRED = "Zugriffsprofil abgelaufen - gildeninterne Bereiche sind nur noch "
    .. "lesbar, neue Daten werden nicht mehr angenommen. Starte WeintCompanion."

local MSG_CLOCK_SKEW = "Die Systemzeit weicht ab - der Ablauf des Zugriffsprofils wird ignoriert."

WeintCodex.Access.MSG_FOREIGN_IMPORT = "Dieser Import gehoert zu einer anderen Community. "
    .. "Dieses Addon ist mit \"%s\" verknuepft - ein Wechsel geht nur ueber /wc access reset."

WeintCodex.Access.MSG_IMPORT_DENIED = "Fuer diesen Import fehlt die Freigabe deiner "
    .. "Discord-Rolle (%s)."

WeintCodex.Access.MSG_IMPORT_EXPIRED = "Dein Zugriffsprofil ist abgelaufen. Starte "
    .. "WeintCompanion, damit es erneuert wird - danach klappt der Import wieder."

WeintCodex.Access.LOCK_TITLE = "Bereich gesperrt"

local LOCK_REASON = {

    ["raids.view"]      = "Die Raidplanung gehoert zu den gildeninternen Daten.",
    ["raids.edit"]      = "Namenskorrekturen an der Anmeldeliste macht die Raidleitung.",
    ["calendar.view"]   = "Die Gildentermine gehoeren zu den gildeninternen Daten.",
    ["calendar.invite"] = "Ingame-Einladungen fuer den Raid verschickt die Raidleitung.",
    ["materials.view"]  = "Die Gildenbank-Materialien gehoeren zu den gildeninternen Daten.",
    ["materials.scan"]  = "Gildenbank-Scans werden nur fuer die verknuepfte Gilde erfasst "
                       .. "und weitergegeben.",
    ["bossguides.tips"] = "Die vom Bot gelieferten Rollen-Tipps sind gildeninterne "
                       .. "Taktiknotizen. Die allgemeinen Bossguides bleiben offen.",
    ["weinttv.raid"]    = "Auswertungen des ganzen Raids gehoeren zu den gildeninternen "
                       .. "Daten. Deine eigenen Zeilen bleiben sichtbar.",
    ["loot.report"]     = "Loot-Meldungen an den Discord-Bot sind fuer deinen Rang nicht "
                       .. "freigegeben.",

}

WeintCodex.Access.LOCK_CARD = {
    "Was du siehst, haengt an deiner Rolle im",
    "Discord. WeintCompanion fragt sie beim",
    "Start ab und meldet sie ans Addon.",
    "",
    "Soll hier mehr stehen: sprich die",
    "Raidleitung im Discord an.",
}

local TIER_LABEL = {
    gast = "Gast", extern = "Extern", mitglied = "Mitglied", offizier = "Offizier",
}

local TIER_COLOR = {
    gast = "textFaint", extern = "info", mitglied = "success", offizier = "purple",
}

local RESET_CONFIRM = "Verknuepfung mit \"%s\" wirklich aufheben?\n"
    .. "Gildeninterne Daten werden dabei geloescht: Raidanmeldungen, Namenskorrekturen, "
    .. "Materialien, Gildenbank-Zwischenspeicher, vom Bot gelieferte Taktiknotizen und "
    .. "die letzte WeintTV-Auswertung.\n"
    .. "Deine eigenen Daten (Twinks, Fortschritt, Academy, WeakAuras, Notizen) bleiben "
    .. "erhalten.\n"
    .. "Zum Bestaetigen: /wc access reset bestaetigen"

local RESET_DONE = "Verknuepfung aufgehoben. Alle Bereiche sind wieder offen."

local PREFIX = "|cffC8763A[WeintCodex]|r "

local function Say(text)
    print(PREFIX .. text)
end

local function Warn(text)
    print(PREFIX .. WeintCodex.ColorText("warning", text))
end

--------------------------------------------------
-- Ablage
--------------------------------------------------

local function Store()

    WeintCodex.SavedData = WeintCodex.SavedData or {}

    local store = WeintCodex.SavedData.access
    if not store then return nil end

    store.rejections = store.rejections or { count = 0 }
    return store

end

function WeintCodex.Access.Init()

    -- Absichtlich KEIN Anlegen einer leeren Tabelle: "Schluessel fehlt" ist
    -- genau der Zustand "kein Profil = alles offen wie vor 1.2.0.0". Wuerde
    -- hier ein leeres access = {} entstehen, muesste jede Abfrage zwischen
    -- "leer" und "nicht vorhanden" unterscheiden.
    WeintCodex.SavedData = WeintCodex.SavedData or {}

    local store = WeintCodex.SavedData.access
    if store then
        store.rejections = store.rejections or { count = 0 }
    end

end

function WeintCodex.Access.HasProfile()

    local store = Store()
    return (store and store.profile) and true or false

end

function WeintCodex.Access.Profile()

    local store = Store()
    return store and store.profile or nil

end

function WeintCodex.Access.Community()

    local store = Store()
    return store and store.community or nil

end

--------------------------------------------------
-- Rang
--------------------------------------------------

function WeintCodex.Access.Tier()

    local profile = WeintCodex.Access.Profile()
    return profile and profile.tier or nil

end

function WeintCodex.Access.TierLabel()

    local profile = WeintCodex.Access.Profile()
    if not profile then return "—" end

    if profile.tierLabel and profile.tierLabel ~= "" then
        return profile.tierLabel
    end

    return TIER_LABEL[profile.tier or ""] or profile.tier or "—"

end

function WeintCodex.Access.TierColor()

    local profile = WeintCodex.Access.Profile()
    if not profile then return "textFaint" end

    return TIER_COLOR[profile.tier or ""] or "warning"

end

--------------------------------------------------
-- Ablaufzustand
--------------------------------------------------
-- Rueckgabe: state, daysOverdue
--   "none"    kein Profil
--   "fresh"   gueltig
--   "grace"   abgelaufen, aber innerhalb der Kulanzfrist - volle Freigaben
--   "expired" darueber hinaus - nur noch lesen, kein Ingest
--   "skew"    Ausstellung liegt in der Zukunft, Ablauf wird ignoriert
--------------------------------------------------

function WeintCodex.Access.IsStale()

    local profile = WeintCodex.Access.Profile()
    if not profile then return "none", 0 end

    local now = time()

    if type(profile.issuedAt) == "number" and profile.issuedAt > now + SKEW_SECONDS then
        return "skew", 0
    end

    local expires = tonumber(profile.expiresAt) or 0
    if expires <= 0 or now <= expires then
        return "fresh", 0
    end

    local overdue = math.floor((now - expires) / 86400)

    if now <= expires + GRACE_SECONDS then
        return "grace", overdue
    end

    return "expired", overdue

end

function WeintCodex.Access.IngestAllowed()

    return WeintCodex.Access.IsStale() ~= "expired"

end

--------------------------------------------------
-- Entscheidung
--------------------------------------------------

local warnedUnknownTier = false

function WeintCodex.Access.Can(featureKey)

    local profile = WeintCodex.Access.Profile()

    -- Kein Profil: Verhalten wie vor 1.2.0.0.
    if not profile then return true end

    if WeintCodex.Access.IsStale() == "expired" and not STALE_FEATURES[featureKey] then
        return false
    end

    -- Die ausdrueckliche Liste des Bots gewinnt. Nur echte Booleans zaehlen -
    -- "true" oder 1 gelten als NICHT gesetzt und fallen auf die Matrix durch,
    -- statt still zu erlauben.
    local explicit = profile.features and profile.features[featureKey]
    if explicit == true  then return true  end
    if explicit == false then return false end

    local matrix = TIER_FEATURES[profile.tier or ""]

    if not matrix then
        -- Unbekannter Rang: nur ausdruecklich Freigegebenes, und einmal laut
        -- sagen. Stilles Erlauben wuerde lecken, stilles Verbieten waere ein
        -- unerklaerlicher Bugreport.
        if not warnedUnknownTier then
            warnedUnknownTier = true
            Warn(string.format(MSG_UNKNOWN_TIER, tostring(profile.tier)))
        end
        return false
    end

    return matrix[featureKey] == true

end

function WeintCodex.Access.Reason(featureKey)

    if WeintCodex.Access.Can(featureKey) then return "" end

    local state = WeintCodex.Access.IsStale()
    if state == "expired" and not STALE_FEATURES[featureKey] then
        return MSG_STALE_EXPIRED
    end

    return LOCK_REASON[featureKey]
        or "Fuer diesen Bereich fehlt die Freigabe deiner Discord-Rolle."

end

--------------------------------------------------
-- Bindung
--------------------------------------------------

local function NormalizeId(id)

    if id == nil then return nil end

    -- Snowflakes muessen als String verglichen werden, siehe Kopfkommentar.
    local text = tostring(id)
    text = text:match("^%s*(.-)%s*$")

    if text == "" then return nil end
    return text

end

WeintCodex.Access.NormalizeId = NormalizeId

-- Fremd = es gibt eine Bindung UND die uebergebene ID weicht davon ab. Ohne
-- Bindung und ohne ID (Alt-Format ohne Community-Angabe) ist nichts fremd.
function WeintCodex.Access.IsForeign(communityId)

    local id = NormalizeId(communityId)
    if not id then return false end

    local community = WeintCodex.Access.Community()
    local boundId = community and NormalizeId(community.id)
    if not boundId then return false end

    return id ~= boundId

end

function WeintCodex.Access.CommunityName()

    local community = WeintCodex.Access.Community()
    if not community then return "—" end

    local name = community.name
    if type(name) == "string" and name ~= "" then return name end

    return NormalizeId(community.id) or "—"

end

function WeintCodex.Access.Bind(community)

    local id = NormalizeId(community and community.id)
    if not id then return false, "Community-ID fehlt." end

    WeintCodex.SavedData = WeintCodex.SavedData or {}

    local store = WeintCodex.SavedData.access or {}
    store.community  = { id = id, name = community.name }
    store.boundAt    = store.boundAt or time()
    store.rejections = store.rejections or { count = 0 }

    WeintCodex.SavedData.access = store
    return true

end

-- Gildeninterne Schluessel. Bleiben sie beim Wechsel liegen, vermischen sich
-- genau die Daten, gegen die dieses Modul existiert.
local GUILD_KEYS = {
    "raidWednesday", "raidThursday", "rosterNameOverrides",
    "materialData", "guildBankCache", "bossData", "weinttv",
}

function WeintCodex.Access.Unbind()

    local sd = WeintCodex.SavedData
    if not sd then return end

    for _, key in ipairs(GUILD_KEYS) do
        sd[key] = nil
    end

    -- bossData wird von modules/sync.lua als Tabelle erwartet.
    sd.bossData = {}

    sd.access = nil
    warnedUnknownTier = false

    WeintCodex.Access.Apply()

    if WeintCodex.ResetToHome then
        WeintCodex.ResetToHome()
    end

end

function WeintCodex.Access.NoteRejection(communityId)

    local store = Store()
    if not store then return end

    store.rejections.count = (store.rejections.count or 0) + 1
    store.rejections.lastId = NormalizeId(communityId) or store.rejections.lastId
    store.rejections.lastAt = time()

end

function WeintCodex.Access.RejectionCount()

    local store = Store()
    return store and store.rejections and store.rejections.count or 0

end

WeintCodex.Access.MSG_FOREIGN_INBOX = MSG_FOREIGN_INBOX

--------------------------------------------------
-- Profil uebernehmen (Inbox-Handler, siehe modules/companion.lua)
--------------------------------------------------

local function CopyFeatures(features)

    local copy = {}

    if type(features) == "table" then
        for key, value in pairs(features) do
            if type(key) == "string" and type(value) == "boolean" then
                copy[key] = value
            end
        end
    end

    return copy

end

local function CopyStrings(list)

    local copy = {}

    if type(list) == "table" then
        for _, entry in ipairs(list) do
            if type(entry) == "string" then copy[#copy + 1] = entry end
        end
    end

    return copy

end

function WeintCodex.Access.ApplyProfile(payload)

    if type(payload) ~= "table" then return false, "Nutzlast ist keine Tabelle." end

    local community = payload.community
    if type(community) ~= "table" then return false, "community fehlt." end

    local id = NormalizeId(community.id)
    if not id then return false, "community.id fehlt." end

    -- Bindung schuetzen: ein Profil einer anderen Community bindet NICHT um,
    -- sonst waere die Ein-Scope-Regel wirkungslos.
    if WeintCodex.Access.IsForeign(id) then
        WeintCodex.Access.NoteRejection(id)
        Warn(string.format(MSG_FOREIGN_PROFILE,
            tostring(community.name or id), WeintCodex.Access.CommunityName()))
        return false, "Andere Community."
    end

    local previous = WeintCodex.Access.Profile()
    local issuedAt = tonumber(payload.issuedAt) or 0

    -- Nachrichten ausser der Reihe duerfen nicht heruntersetzen.
    if previous and (tonumber(previous.issuedAt) or 0) > issuedAt then
        return false, "Aelteres Profil."
    end

    local isNewBinding = not WeintCodex.Access.Community()

    local ok, err = WeintCodex.Access.Bind(community)
    if not ok then return false, err end

    local profile = {
        tier      = type(payload.tier) == "string" and payload.tier:lower() or nil,
        tierLabel = type(payload.tierLabel) == "string" and payload.tierLabel or nil,
        roles     = CopyStrings(payload.roles),
        features  = CopyFeatures(payload.features),
        identity  = type(payload.identity) == "table" and payload.identity or nil,
        issuedAt  = issuedAt,
        expiresAt = tonumber(payload.expiresAt) or 0,
        companionVersion = type(payload.companionVersion) == "string"
            and payload.companionVersion or nil,
        notice    = type(payload.notice) == "string" and payload.notice or nil,
        raw       = payload,
    }

    WeintCodex.SavedData.access.profile = profile
    warnedUnknownTier = false

    if isNewBinding then
        Say(string.format(MSG_BOUND, WeintCodex.Access.CommunityName()))
    end

    Say(string.format(MSG_PROFILE,
        WeintCodex.Access.CommunityName(), WeintCodex.Access.TierLabel()))

    WeintCodex.Access.Apply()
    return true

end

--------------------------------------------------
-- Rang-Marke am unteren Rand der Icon-Rail
--------------------------------------------------
-- Absichtlich nicht in die Titelleiste: dort konkurrieren Suchfeld,
-- Breadcrumb und der von den Modulen belegte Aktionsbereich
-- (WeintCodex.TitleBarActions wird bei jedem Tabwechsel geleert).
-- Ohne Profil bleibt die Marke versteckt - ein ungebundener Client sieht
-- pixelgenau aus wie vor 1.2.0.0.
--------------------------------------------------

local badge, badgeLabel = nil, nil

local function EnsureBadge()

    if badge then return badge end
    if not (WeintCodex.IconRail and WeintCodex.CreateCard) then return nil end

    badge = WeintCodex.CreateCard(WeintCodex.IconRail,
        { width = 52, height = 16, surface = "surface2", style = "border" })
    badge:SetPoint("BOTTOM", WeintCodex.IconRail, "BOTTOM", 0, 26)

    badgeLabel = badge:CreateFontString(nil, "OVERLAY")
    badgeLabel:SetAllPoints(badge)
    badgeLabel:SetFont(WeintCodex.Fonts.mono, 8, "")
    badgeLabel:SetJustifyH("CENTER")
    badgeLabel:SetJustifyV("MIDDLE")

    badge:EnableMouse(true)
    badge:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Zugriff: " .. WeintCodex.Access.TierLabel())
        GameTooltip:AddLine(WeintCodex.Access.CommunityName(),
            C.textDim[1], C.textDim[2], C.textDim[3])

        local state, overdue = WeintCodex.Access.IsStale()
        if state == "grace" then
            GameTooltip:AddLine("Profil laeuft ab (" .. overdue .. " Tag(e) faellig)",
                C.warning[1], C.warning[2], C.warning[3])
        elseif state == "expired" then
            GameTooltip:AddLine("Profil abgelaufen",
                C.warning[1], C.warning[2], C.warning[3])
        end

        GameTooltip:AddLine("Details mit /wc access",
            C.textFaint[1], C.textFaint[2], C.textFaint[3])
        GameTooltip:Show()
    end)
    badge:SetScript("OnLeave", function() GameTooltip:Hide() end)

    badge:Hide()
    return badge

end

function WeintCodex.Access.UpdateBadge()

    if not WeintCodex.Access.HasProfile() then
        if badge then badge:Hide() end
        return
    end

    if not EnsureBadge() then return end

    local state = WeintCodex.Access.IsStale()
    local colorName = (state == "grace" or state == "expired")
        and "warning" or WeintCodex.Access.TierColor()

    local col = C[colorName] or C.textDim
    badgeLabel:SetTextColor(col[1], col[2], col[3])
    badgeLabel:SetText(WeintCodex.Access.TierLabel():upper())

    badge:Show()

end

--------------------------------------------------
-- Anwenden
--------------------------------------------------
-- WeintCodex.Navigation darf hier NICHT in einer Datei-Locale liegen:
-- core/navigation.lua laedt spaeter als diese Datei, die Locale waere fuer
-- immer nil. Zugriff deshalb nur innerhalb der Funktion.
--------------------------------------------------

local staleWarned = false

function WeintCodex.Access.Apply()

    local Nav = WeintCodex.Navigation

    if Nav and Nav.GetTabFeatures and Nav.SetTabLocked then
        for tabId, featureKey in pairs(Nav.GetTabFeatures()) do
            Nav.SetTabLocked(tabId, not WeintCodex.Access.Can(featureKey))
        end
    end

    WeintCodex.Access.UpdateBadge()

    -- Hinweis auf ein alterndes Profil einmal pro Sitzung.
    if not staleWarned then
        local state, overdue = WeintCodex.Access.IsStale()
        if state == "grace" then
            staleWarned = true
            Warn(string.format(MSG_STALE_GRACE, overdue))
        elseif state == "expired" then
            staleWarned = true
            Warn(MSG_STALE_EXPIRED)
        elseif state == "skew" then
            staleWarned = true
            Warn(MSG_CLOCK_SKEW)
        end
    end

    if WeintCodex.MainFrame and WeintCodex.MainFrame:IsShown() and WeintCodex.ResetToHome then
        WeintCodex.ResetToHome()
    end

end

--------------------------------------------------
-- /wc access
--------------------------------------------------

local function Stamp(unixTime)

    local value = tonumber(unixTime) or 0
    if value <= 0 then return "unbekannt" end

    return date("%d.%m.%Y %H:%M", value)

end

local function Mark(allowed)

    return WeintCodex.Icon(allowed
        and "Interface\\RaidFrame\\ReadyCheck-Ready"
        or  "Interface\\RaidFrame\\ReadyCheck-NotReady", 12)

end

local function Row(label, value)

    print("  " .. WeintCodex.ColorText("textDim", label) .. "  " .. value)

end

function WeintCodex.Access.Print()

    if not WeintCodex.Access.HasProfile() then
        Say(MSG_NO_PROFILE)
        return
    end

    local profile   = WeintCodex.Access.Profile()
    local community = WeintCodex.Access.Community() or {}

    Say(WeintCodex.ColorText("textBright", "Zugriffsprofil"))

    Row("Community  ", WeintCodex.Access.CommunityName()
        .. WeintCodex.ColorText("textFaint", "  (" .. tostring(community.id) .. ")"))

    Row("Rang       ", WeintCodex.ColorText(WeintCodex.Access.TierColor(),
        WeintCodex.Access.TierLabel())
        .. WeintCodex.ColorText("textFaint", "  (" .. tostring(profile.tier) .. ")"))

    local identity = profile.identity or {}
    local roles = #profile.roles > 0 and table.concat(profile.roles, ", ") or "keine"
    Row("Discord    ", tostring(identity.discordName or "unbekannt")
        .. WeintCodex.ColorText("textFaint", "  Rollen: " .. roles))

    Row("Ausgestellt", Stamp(profile.issuedAt)
        .. WeintCodex.ColorText("textFaint", "  Companion "
            .. tostring(profile.companionVersion or "?")))

    local state, overdue = WeintCodex.Access.IsStale()
    local validity = (tonumber(profile.expiresAt) or 0) <= 0
        and "unbegrenzt" or Stamp(profile.expiresAt)

    local stateText = ({
        fresh   = WeintCodex.ColorText("success", "aktuell"),
        grace   = WeintCodex.ColorText("warning", "laeuft ab, " .. overdue .. " Tag(e) faellig"),
        expired = WeintCodex.ColorText("danger",  "abgelaufen, nur noch lesbar"),
        skew    = WeintCodex.ColorText("warning", "Systemzeit weicht ab"),
    })[state] or state

    Row("Gueltig bis", validity .. "  " .. stateText)

    for _, key in ipairs(FEATURE_ORDER) do
        local allowed = WeintCodex.Access.Can(key)
        print("    " .. Mark(allowed) .. " "
            .. WeintCodex.ColorText(allowed and "textNormal" or "textFaint", key))
    end

    local rejections = WeintCodex.Access.RejectionCount()
    if rejections > 0 then
        local store = Store()
        Row("Verworfen  ", WeintCodex.ColorText("warning",
            rejections .. " Nachricht(en) einer anderen Community")
            .. WeintCodex.ColorText("textFaint", "  letzte: "
                .. tostring(store.rejections.lastId or "?")
                .. ", " .. Stamp(store.rejections.lastAt)))
    end

    Row("Ruecksetzen", WeintCodex.ColorText("textFaint", "/wc access reset"))

end

--------------------------------------------------
-- /wc access reset  (zweistufig)
--------------------------------------------------
-- Bewusst eine Bestaetigung im Chat statt eines Overlays: WeintCodex.Dialog
-- ist kein Bestaetigungsdialog (sein Ja-Button loest ReloadUI aus) und haengt
-- als Kind an WeintCodex.MainFrame, das aus dem Chat heraus erst gezeigt
-- werden muesste. Ein eigenes Overlay waere fuer eine seltene
-- Administrationsaktion zu viel Apparat.
--------------------------------------------------

function WeintCodex.Access.Reset(confirmed)

    if not (WeintCodex.SavedData and WeintCodex.SavedData.access) then
        Say(MSG_NO_PROFILE)
        return
    end

    if not confirmed then
        Say(WeintCodex.ColorText("warning",
            string.format(RESET_CONFIRM, WeintCodex.Access.CommunityName())))
        return
    end

    WeintCodex.Access.Unbind()
    Say(WeintCodex.ColorText("success", RESET_DONE))

end
