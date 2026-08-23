--------------------------------------------------
-- WeintCodex :: WeakAuras
--------------------------------------------------
-- Die Seite kennt ZWEI Quellen und zeigt sie in einer Liste:
--
--   1. data/weakauras/*.lua  - die mitgelieferten Auren. Sie stecken
--      im Addon-ZIP und aendern sich nur mit einer neuen Version.
--   2. SavedData.weakAuraLibrary - was die Companion zugestellt hat
--      (Nachricht "weakaura_library", siehe modules/companion.lua und
--      docs/weakaura-bridge.md drueben). Damit laesst sich eine Aura
--      am Schreibtisch eintragen, ohne dass jemand ein Addon-Release
--      bauen muss.
--
-- Die zweite Quelle hat seit 2.2.0.0 zwei Reichweiten, und die Zeile
-- sagt welche: eine Aura vom eigenen Schreibtisch ("Companion") oder
-- eine, die jemand ueber den Discord-Bot fuer die ganze Gilde
-- freigegeben hat ("Gilde"). Getragen wird das vom Feld `scope`;
-- fehlt es, gilt "vom eigenen Schreibtisch" - eine aeltere Companion
-- schickt es nicht, und ohne diese Annahme truege nach einem Update
-- schlagartig jede Aura die falsche Herkunft.
--
-- **Die zugestellte Aura gewinnt bei gleicher ID.** Genau das ist der
-- Weg, eine schon vorhandene Aura zu aktualisieren: die Companion
-- kennt die IDs der mitgelieferten Auren, weil das Addon sie ihr
-- meldet (ReportWeakAuraCatalog), und schickt unter derselben ID eine
-- neuere Fassung. Ohne diese Regel gaebe es die Aura zweimal in der
-- Liste, und niemand wuesste, welche der beiden die aktuelle ist.
--
-- Gelesen wird die Zustellung beim Login bzw. nach /reload - WoW
-- liest SavedVariables zur Laufzeit nicht erneut. Eine in der
-- Companion eingetragene Aura ist deshalb nach dem naechsten
-- /reload da, nicht sofort.
--
-- Seit 2.4.0.0 sagt jede Zeile ausserdem, ob die Aura in WeakAuras
-- schon vorhanden ist (gruener Haken links). Beantwortet wird das an
-- WeakAuras selbst, nicht an unserer Klickhistorie - Einzelheiten
-- unter "Ist die Aura installiert?" weiter unten.
--------------------------------------------------

WeintCodex.WeakAuras = {}

local C = WeintCodex.Colors

-- Die drei Rubriken der Seitenspalte. Die Companion bietet genau
-- dieselben drei an; eine Aura mit einer anderen Rubrik landet
-- trotzdem in der Liste (siehe NormalizeCategory) - unsichtbar waere
-- der schlechtere Ausgang.
local CATEGORIES = { "class", "raid", "utility" }

local DEFAULT_CATEGORY = "utility"

local CATEGORY_LABEL = {
    class   = "Klassenauren",
    raid    = "Raidauren",
    utility = "Utility-Auren",
}

local function NormalizeCategory(value)

    value = tostring(value or ""):lower()

    if CATEGORY_LABEL[value] then return value end

    return DEFAULT_CATEGORY

end

--------------------------------------------------
-- Zugestellte Auren
--------------------------------------------------

-- Die Ablage der Companion-Zustellung. Immer eine Tabelle, damit
-- Aufrufer nicht auf nil pruefen muessen.
function WeintCodex.WeakAuras.Library()

    WeintCodex.SavedData = WeintCodex.SavedData or {}

    WeintCodex.SavedData.weakAuraLibrary =
        WeintCodex.SavedData.weakAuraLibrary or {}

    local library = WeintCodex.SavedData.weakAuraLibrary

    library.auras = library.auras or {}

    return library

end

-- Eine zugestellte Zeile ist nur brauchbar, wenn sie eine ID, einen
-- Namen und eine Zeichenkette traegt. Alles andere darf fehlen: ohne
-- Beschreibung ist die Zeile karg, ohne Importstring ist sie eine
-- Schaltflaeche, die nichts tut.
local function UsableDelivered(entry)

    if type(entry) ~= "table" then return false end

    local id     = entry.id
    local name   = entry.name
    local import = entry.string

    return type(id)     == "string" and id     ~= ""
       and type(name)   == "string" and name   ~= ""
       and type(import) == "string" and import ~= ""

end

--------------------------------------------------
-- Beide Quellen zu einer Liste
--------------------------------------------------
-- Rueckgabe: { [id] = { id, name, category, description, version,
--                       author, icon, string, waIds, origin } }
--
-- `origin` ist "addon" oder "companion" und wird sowohl in der Zeile
-- angezeigt als auch an die Companion zurueckgemeldet - sie soll
-- unterscheiden koennen, was sie selbst geschickt hat und was mit dem
-- Addon kam.
--------------------------------------------------

function WeintCodex.WeakAuras.Entries()

    local merged = {}

    for id, aura in pairs(WeintCodex.WeakAuraData or {}) do

        if type(aura) == "table" and aura.string then

            merged[id] = {
                id          = id,
                name        = aura.name or id,
                category    = NormalizeCategory(aura.category),
                description = aura.description or "",
                version     = aura.version or "?",
                author      = aura.author or "",
                icon        = aura.icon,
                string      = aura.string,
                sortOrder   = aura.sortOrder,
                waIds       = aura.waIds,
                origin      = "addon",
            }

        end

    end

    for _, entry in ipairs(WeintCodex.WeakAuras.Library().auras) do

        if UsableDelivered(entry) then

            local existing = merged[entry.id]

            merged[entry.id] = {
                id          = entry.id,
                name        = entry.name,
                category    = NormalizeCategory(
                    entry.category or (existing and existing.category)
                ),
                description = entry.description or "",
                version     = entry.version or "1.0",
                author      = entry.author or "",
                -- Ohne eigenes Symbol das der ersetzten Aura: eine
                -- aktualisierte Zeile soll nicht ploetzlich anders
                -- aussehen als die, die sie ersetzt.
                icon        = entry.icon or (existing and existing.icon),
                string      = entry.string,
                sortOrder   = entry.sortOrder or (existing and existing.sortOrder),
                -- Wie beim Symbol: schickt die Companion keine eigene
                -- Namensliste mit, gilt die der ersetzten Aura. Eine
                -- aktualisierte Fassung traegt dieselben Anzeigen wie
                -- die, die sie ersetzt - sonst verloere die Zeile beim
                -- Aktualisieren ihren Haken.
                waIds       = entry.waIds or (existing and existing.waIds),
                origin      = entry.scope == "guild" and "guild" or "companion",
                replaced    = existing ~= nil,
            }

        end

    end

    return merged

end

-- Die Eintraege einer Rubrik, fertig sortiert.
function WeintCodex.WeakAuras.EntriesFor(category)

    category = NormalizeCategory(category)

    local entries = {}

    for _, entry in pairs(WeintCodex.WeakAuras.Entries()) do

        if entry.category == category then
            entries[#entries + 1] = entry
        end

    end

    table.sort(entries, function(a, b)

        if (a.sortOrder or 999) == (b.sortOrder or 999) then
            return a.name < b.name
        end

        return (a.sortOrder or 999) < (b.sortOrder or 999)

    end)

    return entries

end

--------------------------------------------------
-- Was das Addon kennt (fuer die Companion)
--------------------------------------------------
-- Die Companion kann die mitgelieferten Auren nicht sehen - sie
-- stecken in Lua-Dateien im Addon-Ordner. Ohne diese Meldung koennte
-- ihre Seite nur die Auren anbieten, die sie selbst angelegt hat, und
-- "eine vorhandene aktualisieren" waere auf genau die beschraenkt.
-- Der Importstring ist bewusst NICHT dabei: er waere das Vielfache
-- der uebrigen Nutzlast, und zum Auflisten und Ersetzen braucht ihn
-- niemand.
--------------------------------------------------

function WeintCodex.WeakAuras.Catalog()

    local catalog = {}

    for _, entry in pairs(WeintCodex.WeakAuras.Entries()) do

        catalog[#catalog + 1] = {
            id       = entry.id,
            name     = entry.name,
            category = entry.category,
            version  = entry.version,
            origin   = entry.origin,
        }

    end

    table.sort(catalog, function(a, b) return a.id < b.id end)

    return catalog

end

--------------------------------------------------
-- Ist die Aura installiert?
--------------------------------------------------
-- Die Zeile soll auf einen Blick sagen, was schon da ist. Beantwortet
-- wird das ausschliesslich an WeakAuras selbst - "ich habe hier mal
-- geklickt" ist keine Installation, der Import kann abgebrochen und
-- die Aura spaeter geloescht worden sein.
--
-- Gebraucht wird dafuer der Name, unter dem WeakAuras die Aura fuehrt,
-- und der steht im Importstring, nicht in unserer `name`-Spalte (die
-- mitgelieferten Pakete heissen "Fojji - Warrior UI [MoP]", die Zeile
-- heisst "Krieger"). Zwei Quellen, in dieser Reihenfolge:
--
--   1. `waIds` des Eintrags - fuer die mitgelieferten Auren aus dem
--      Importstring gezogen und in data/weakauras/*.lua hinterlegt
--      (siehe den Kopf von data/weakauras/init.lua). Das ist die
--      genaue Antwort und gilt auch fuer eine Aura, die jemand
--      ueber Wago installiert hat, ohne diese Seite je zu oeffnen.
--   2. Was der letzte Import ueber diese Seite tatsaechlich angelegt
--      hat (Differenz der Anzeigenliste vor/nach dem Klick). Das ist
--      der Weg fuer zugestellte Auren, deren Namen wir nicht kennen
--      koennen, weil sie erst am Schreibtisch entstanden sind.
--
-- Der Unterschied traegt bis in die Bewertung: die kuratierte Liste
-- aus (1) enthaelt nur Wurzeleintraege, da muessen alle da sein. Die
-- beobachtete Liste aus (2) enthaelt auch jede Unteraura des Pakets -
-- wer davon eine wegwirft, hat die Aura trotzdem installiert, deshalb
-- genuegt dort eine.
--
-- Ist WeakAuras gar nicht geladen, sagt die Zeile NICHTS. "Nicht
-- installiert" waere dann eine Aussage ueber unser Unwissen.
--------------------------------------------------

-- Wie lange ein unbestaetigter Import auf seine Anzeigen wartet. Der
-- Importdialog von WeakAuras laesst sich beliebig lange offen liegen
-- lassen; irgendwann war es aber ein Abbruch, und ein ewig offener
-- Vermerk wuerde die naechste fremde Aura faelschlich einsammeln.
local PENDING_TTL = 3600

local function Store()

    WeintCodex.SavedData = WeintCodex.SavedData or {}

    local sd = WeintCodex.SavedData

    sd.weakAuraInstalls = sd.weakAuraInstalls or {}
    sd.weakAuraPending  = sd.weakAuraPending  or {}

    return sd

end

-- WeakAuras kann fehlen (nicht installiert, deaktiviert) - dann gibt es
-- hier nichts zu melden.
local function WeakAurasReady()

    if _G.WeakAuras and type(_G.WeakAuras.GetData) == "function" then
        return true
    end

    local saved = _G.WeakAurasSaved

    return type(saved) == "table" and type(saved.displays) == "table"

end

local function DisplayExists(name)

    if type(name) ~= "string" or name == "" then return false end

    if _G.WeakAuras and type(_G.WeakAuras.GetData) == "function" then
        local ok, data = pcall(_G.WeakAuras.GetData, name)
        if ok then return data ~= nil end
    end

    local saved = _G.WeakAurasSaved

    if type(saved) == "table" and type(saved.displays) == "table" then
        return saved.displays[name] ~= nil
    end

    return false

end

-- Alle Anzeigen, die WeakAuras gerade fuehrt. Nur ueber die
-- SavedVariables zu bekommen - eine oeffentliche Aufzaehlfunktion gibt
-- es nicht, und GetData beantwortet nur die Frage nach einem Namen.
local function DisplayNames()

    local out = {}

    local saved = _G.WeakAurasSaved

    if type(saved) == "table" and type(saved.displays) == "table" then
        for name in pairs(saved.displays) do
            if type(name) == "string" then out[name] = true end
        end
    end

    return out

end

-- Vor dem Import merken, was schon da war. Ohne diesen Schnappschuss
-- ist hinterher nicht zu sagen, welche der 200 Anzeigen aus diesem
-- Klick stammen.
local function NotePendingInstall(entry)

    if not WeakAurasReady() then return end

    local sd = Store()

    sd.weakAuraPending[entry.id] = {
        version = entry.version,
        at      = time(),
        before  = DisplayNames(),
    }

end

-- Offene Vermerke gegen den aktuellen Stand aufloesen. Laeuft bei jedem
-- Aufbau der Seite: WeintCodex schliesst sich nach dem Klick selbst, der
-- Nutzer bestaetigt den Importdialog und ist beim naechsten Blick auf
-- diese Seite genau hier wieder - ein Zeitgeber waere dafuer nur ein
-- schlechter geratener Zeitpunkt.
local function ReconcilePending()

    if not WeakAurasReady() then return end

    local sd      = Store()
    local pending = sd.weakAuraPending

    local waiting = {}

    for id, note in pairs(pending) do
        if type(note) == "table" then
            waiting[#waiting + 1] = { id = id, note = note }
        else
            pending[id] = nil
        end
    end

    if #waiting == 0 then return end

    -- Aelteste zuerst: liegen zwei Importe offen, gehoert eine neue
    -- Anzeige dem frueheren Klick, und der spaetere darf sie nicht ein
    -- zweites Mal fuer sich verbuchen (deshalb unten das Nachtragen in
    -- dessen `before`).
    table.sort(waiting, function(a, b)
        return (a.note.at or 0) < (b.note.at or 0)
    end)

    local now     = time()
    local current = DisplayNames()

    for index, item in ipairs(waiting) do

        local note  = item.note
        local fresh = {}

        for name in pairs(current) do
            if not (note.before and note.before[name]) then
                fresh[#fresh + 1] = name
            end
        end

        if #fresh > 0 then

            sd.weakAuraInstalls[item.id] = {
                version = note.version,
                at      = now,
                names   = fresh,
            }

            pending[item.id] = nil

            for later = index + 1, #waiting do
                local other = waiting[later].note
                other.before = other.before or {}
                for _, name in ipairs(fresh) do other.before[name] = true end
            end

        elseif type(note.at) ~= "number" or (now - note.at) > PENDING_TTL then

            pending[item.id] = nil

        end

    end

end

-- { namen }, curated - curated sagt, ob die Liste aus waIds stammt
-- (Wurzeleintraege, alle muessen da sein) oder beobachtet ist (auch
-- Unterauren, eine genuegt).
local function KnownNames(entry)

    if type(entry.waIds) == "table" and #entry.waIds > 0 then
        return entry.waIds, true
    end

    local record = Store().weakAuraInstalls[entry.id]

    if type(record) == "table" and type(record.names) == "table"
       and #record.names > 0 then
        return record.names, false
    end

    return nil, false

end

--------------------------------------------------
-- Zustand einer Zeile
--------------------------------------------------
-- Rueckgabe: state, found, total, installedVersion
--   state = nil          WeakAuras fehlt oder wir kennen die Namen nicht
--           "missing"    keine der Anzeigen ist da
--           "partial"    ein Teil ist da
--           "installed"  vollstaendig da
--
-- `installedVersion` ist die Fassung, die beim Import ueber diese Seite
-- vermerkt wurde. Sie fehlt, wenn die Aura anderswo installiert wurde -
-- dann steht in der Zeile nur der Haken und keine Versionsaussage,
-- statt eine zu erfinden.
--------------------------------------------------

function WeintCodex.WeakAuras.InstallState(entry)

    if type(entry) ~= "table" then return nil end
    if not WeakAurasReady() then return nil end

    local names, curated = KnownNames(entry)

    if not names then return nil end

    local found = 0

    for _, name in ipairs(names) do
        if DisplayExists(name) then found = found + 1 end
    end

    local record          = Store().weakAuraInstalls[entry.id]
    local installedVersion = type(record) == "table" and record.version or nil

    if found == 0 then
        return "missing", 0, #names, nil
    end

    if curated and found < #names then
        return "partial", found, #names, installedVersion
    end

    return "installed", found, #names, installedVersion

end

--------------------------------------------------
-- Hilfsfunktion
--------------------------------------------------

local function ClearContent()

    local cp = WeintCodex.ContentPanel
    if not cp then return end

    for _, child in pairs({ cp:GetChildren() }) do
        child:Hide()
    end

end

-- Welche Rubrik zuletzt gezeichnet wurde. Refresh() braucht sie, um
-- nach einer Zustellung dieselbe Seite neu aufzubauen statt zurueck
-- auf die erste zu springen.
local currentCategory = "class"

--------------------------------------------------
-- Kategorie anzeigen
--------------------------------------------------

function WeintCodex.WeakAuras.ShowCategory(category)

    category = NormalizeCategory(category)

    currentCategory = category

    -- Offene Importvermerke aufloesen, BEVOR die Zeilen entstehen: der
    -- Nutzer kommt genau hier wieder her, nachdem er den Importdialog
    -- von WeakAuras bestaetigt hat.
    ReconcilePending()

    ClearContent()

    local cp = WeintCodex.ContentPanel
    if not cp then return end

    local scroll = CreateFrame("ScrollFrame", nil, cp, "UIPanelScrollFrameTemplate")
    scroll:SetAllPoints(cp)

    local container = CreateFrame("Frame", nil, scroll)
    container:SetSize(860, 1)

    scroll:SetScrollChild(container)

    --------------------------------------------------
    -- Ueberschrift
    --------------------------------------------------

    local categoryLabel = CATEGORY_LABEL[category]

    local title = container:CreateFontString(nil, "OVERLAY")
    title:SetFont(WeintCodex.Fonts.sansBold, 22, "")
    title:SetPoint("TOPLEFT", 15, -10)
    title:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
    title:SetText(categoryLabel)

    local descriptionText = ""

    if category == "class" then
        descriptionText = "Hier findest du die vollständigen Klassenauren für alle Spezialisierungen. Mit einem Klick auf |cffD4A24AInstallieren|r wird die Aura automatisch an WeakAuras übergeben."
    elseif category == "raid" then
        descriptionText = "Hier findest du Raid-Auren und Boss-Pakete. Installiere die gewünschten Pakete direkt mit einem Klick."
    else
        descriptionText = "Hier findest du allgemeine Utility-Auren, die unabhängig von Klasse oder Raid genutzt werden können."
    end

    WeintCodex.SetBreadcrumb("WeakAuras", categoryLabel)

    local description = container:CreateFontString(nil, "OVERLAY")
    description:SetFont(WeintCodex.Fonts.sans, 11, "")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    description:SetWidth(860)
    description:SetJustifyH("LEFT")
    description:SetText(descriptionText)

    --------------------------------------------------
    -- Trennlinie
    --------------------------------------------------

    local line = container:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -12)
    line:SetPoint("TOPRIGHT", container, "TOPRIGHT", -20, -12)
    line:SetColorTexture(C.border[1], C.border[2], C.border[3], C.border[4])

    --------------------------------------------------
    -- Tabellenueberschrift
    --------------------------------------------------

    local header = CreateFrame("Frame", nil, container)
    header:SetSize(850, 24)
    header:SetPoint("TOPLEFT", line, "BOTTOMLEFT", 0, -8)

    local hName = header:CreateFontString(nil, "OVERLAY")
    hName:SetFont(WeintCodex.Fonts.sans, 11, "")
    -- 56 statt 42: links davor sitzt jetzt die Statusspalte (Haken).
    hName:SetPoint("LEFT", 56, 0)
    hName:SetWidth(128)
    hName:SetJustifyH("LEFT")

    local firstColumn = "Aura"

    if category == "class" then
        firstColumn = "Klasse"
    elseif category == "raid" then
        firstColumn = "Raidpaket"
    end

    hName:SetText(firstColumn)

    local hDesc = header:CreateFontString(nil, "OVERLAY")
    hDesc:SetFont(WeintCodex.Fonts.sans, 11, "")
    hDesc:SetPoint("LEFT", hName, "RIGHT", 10, 0)
    hDesc:SetWidth(380)
    hDesc:SetJustifyH("LEFT")
    hDesc:SetText("Beschreibung")

    local hVersion = header:CreateFontString(nil, "OVERLAY")
    hVersion:SetFont(WeintCodex.Fonts.sans, 11, "")
    hVersion:SetPoint("LEFT", hDesc, "RIGHT", 10, 0)
    hVersion:SetWidth(70)
    hVersion:SetText("Version")

    local hAction = header:CreateFontString(nil, "OVERLAY")
    hAction:SetFont(WeintCodex.Fonts.sans, 11, "")
    hAction:SetPoint("LEFT", hVersion, "RIGHT", 25, 0)
    hAction:SetText("Aktion")

    --------------------------------------------------
    -- Auren sammeln
    --------------------------------------------------

    local entries = WeintCodex.WeakAuras.EntriesFor(category)

    local delivered, shared = 0, 0
    local installed, known  = 0, 0

    for _, entry in ipairs(entries) do
        if entry.origin == "companion" then
            delivered = delivered + 1
        elseif entry.origin == "guild" then
            shared = shared + 1
        end

        -- Nur zaehlen, was ueberhaupt beantwortbar ist: `known` ist die
        -- Menge der Zeilen, zu denen wir Anzeigennamen haben. "3 von 5"
        -- ueber alle Zeilen zu behaupten hiesse, die uebrigen als nicht
        -- installiert zu zaehlen, obwohl wir sie nur nicht kennen.
        local rowState = WeintCodex.WeakAuras.InstallState(entry)

        if rowState then
            known = known + 1
            if rowState == "installed" then installed = installed + 1 end
        end
    end

    --------------------------------------------------
    -- Zeilen erzeugen
    --------------------------------------------------

    local yOffset = -95

    for _, aura in ipairs(entries) do

        local row = CreateFrame("Frame", nil, container)
        row:SetSize(850, 40)
        row:SetPoint("TOPLEFT", 10, yOffset)

        --------------------------------------------------
        -- Hintergrund
        --------------------------------------------------

        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(C.bgCard[1], C.bgCard[2], C.bgCard[3], 0.35)

        --------------------------------------------------
        -- Statusspalte: installiert?
        --------------------------------------------------
        -- Ganz links, wie die Statusspalte der Charakterseiten. Sie
        -- bleibt leer, solange wir nichts wissen (WeakAuras nicht
        -- geladen, Namen unbekannt) - ein rotes Kreuz waere dort eine
        -- Behauptung ueber die Aura, nicht ueber unser Wissen.
        --------------------------------------------------

        local state, found, total, installedVersion =
            WeintCodex.WeakAuras.InstallState(aura)

        if state == "installed" or state == "partial" then

            local mark = row:CreateTexture(nil, "OVERLAY")
            mark:SetSize(16, 16)
            mark:SetPoint("LEFT", row, "LEFT", 4, 0)

            if state == "installed" then
                mark:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
            else
                mark:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-Alert")
                mark:SetSize(18, 18)
            end

            local hit = CreateFrame("Frame", nil, row)
            hit:SetAllPoints(mark)
            hit:EnableMouse(true)
            hit:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                if state == "installed" then
                    GameTooltip:AddLine("In WeakAuras vorhanden")
                else
                    GameTooltip:AddLine("Teilweise vorhanden: "
                        .. found .. " von " .. total)
                end
                if installedVersion and installedVersion ~= aura.version then
                    GameTooltip:AddLine("Installiert als v" .. installedVersion
                        .. ", angeboten wird v" .. aura.version,
                        0.83, 0.64, 0.29, true)
                end
                GameTooltip:Show()
            end)
            hit:SetScript("OnLeave", function() GameTooltip:Hide() end)

        end

        --------------------------------------------------
        -- Icon
        --------------------------------------------------

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(24, 24)
        icon:SetPoint("LEFT", 22, 0)

        if aura.icon then
            icon:SetTexture(aura.icon)
        end

        --------------------------------------------------
        -- Name, darunter die Herkunft
        --------------------------------------------------
        -- Die Herkunftszeile ist kein Schmuck: eine ueber die
        -- Companion nachgetragene Aura sah bisher genau aus wie eine
        -- mitgelieferte, und wer den Import nicht selbst eingetragen
        -- hat, konnte nicht wissen, wen er zu fragen hat, wenn sie
        -- nicht stimmt.
        --------------------------------------------------

        local name = row:CreateFontString(nil, "OVERLAY")
        name:SetFont(WeintCodex.Fonts.sans, 12, "")
        name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -1)
        name:SetWidth(128)
        name:SetJustifyH("LEFT")
        name:SetText(aura.name)

        local origin = row:CreateFontString(nil, "OVERLAY")
        origin:SetFont(WeintCodex.Fonts.sans, 10, "")
        origin:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -2)
        origin:SetWidth(128)
        origin:SetJustifyH("LEFT")
        origin:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])

        if aura.origin == "companion" or aura.origin == "guild" then

            -- "Gilde" heisst: jemand hat sie fuer alle freigegeben und
            -- ist dafuer ansprechbar. "Companion" heisst: sie steht
            -- nur auf diesem Rechner. Der Unterschied ist der, den man
            -- braucht, wenn die Aura nicht stimmt.
            local source = aura.origin == "guild" and "Gilde" or "Companion"

            local label = source

            if aura.replaced then
                label = source .. " · ersetzt"
            end

            if aura.author ~= "" then
                label = source .. " · " .. aura.author
            end

            origin:SetText(WeintCodex.Truncate(label, 22))

            if aura.origin == "guild" then
                origin:SetTextColor(C.green[1], C.green[2], C.green[3])
            else
                origin:SetTextColor(C.blue[1], C.blue[2], C.blue[3])
            end

        else

            origin:SetText("WeintCodex")

        end

        --------------------------------------------------
        -- Beschreibung
        --------------------------------------------------

        local desc = row:CreateFontString(nil, "OVERLAY")
        desc:SetFont(WeintCodex.Fonts.sans, 11, "")
        desc:SetPoint("LEFT", row, "LEFT", 191, 0)
        desc:SetWidth(380)
        desc:SetJustifyH("LEFT")
        desc:SetText(aura.description)

        --------------------------------------------------
        -- Version
        --------------------------------------------------

        local version = row:CreateFontString(nil, "OVERLAY")
        version:SetFont(WeintCodex.Fonts.sans, 11, "")
        version:SetPoint("LEFT", desc, "RIGHT", 10, 0)
        version:SetWidth(70)
        version:SetText("v" .. aura.version)

        --------------------------------------------------
        -- WeintCodex Installieren Button
        --------------------------------------------------

        local btn = CreateFrame("Button", nil, row)
        btn:SetSize(130, 24)
        btn:SetPoint("LEFT", version, "RIGHT", 15, 0)

        -- Hintergrund
        local btnBg = btn:CreateTexture(nil, "BACKGROUND")
        btnBg:SetAllPoints()
        btnBg:SetColorTexture(
            C.purple[1], C.purple[2], C.purple[3],
            0.08
        )

        -- Akzentstreifen links
        local accent = btn:CreateTexture(nil, "ARTWORK")
        accent:SetPoint("LEFT")
        accent:SetSize(3, 24)
        accent:SetColorTexture(
            C.purple[1], C.purple[2], C.purple[3],
            0.5
        )

        -- Rahmen
        local borderTop = btn:CreateTexture(nil, "BORDER")
        borderTop:SetPoint("TOPLEFT")
        borderTop:SetPoint("TOPRIGHT")
        borderTop:SetHeight(1)
        borderTop:SetColorTexture(C.purple[1], C.purple[2], C.purple[3], 0.25)

        local borderBottom = btn:CreateTexture(nil, "BORDER")
        borderBottom:SetPoint("BOTTOMLEFT")
        borderBottom:SetPoint("BOTTOMRIGHT")
        borderBottom:SetHeight(1)
        borderBottom:SetColorTexture(C.purple[1], C.purple[2], C.purple[3], 0.25)

        -- Text
        --
        -- Die Beschriftung sagt, was der Klick bewirkt. "Installieren"
        -- auf einer Aura, die schon laeuft, war die Frage, mit der die
        -- Rueckmeldung anfing; "Aktualisieren" steht nur da, wo wir die
        -- installierte Fassung wirklich kennen (Vermerk aus einem
        -- frueheren Import ueber diese Seite).
        local actionLabel = "Installieren"

        if state == "installed" or state == "partial" then
            if installedVersion and installedVersion ~= aura.version then
                actionLabel = "Aktualisieren"
            else
                actionLabel = "Neu importieren"
            end
        end

        local txt = btn:CreateFontString(nil, "OVERLAY")
        txt:SetFont(WeintCodex.Fonts.sans, 11, "")
        txt:SetPoint("CENTER")
        txt:SetText(actionLabel)

        --------------------------------------------------
        -- Hover
        --------------------------------------------------

        btn:SetScript("OnEnter", function()

            btnBg:SetColorTexture(
                C.purple[1], C.purple[2], C.purple[3],
                0.20
            )

            accent:SetColorTexture(
                C.purple[1], C.purple[2], C.purple[3],
                1
            )

            txt:SetTextColor(
                1.0,
                1.0,
                1.0
            )

        end)

        btn:SetScript("OnLeave", function()

            btnBg:SetColorTexture(
                C.purple[1], C.purple[2], C.purple[3],
                0.08
            )

            accent:SetColorTexture(
                C.purple[1], C.purple[2], C.purple[3],
                0.5
            )

            txt:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])

        end)

        --------------------------------------------------
        -- Klick
        --------------------------------------------------

        btn:SetScript("OnClick", function()

            -- Vor dem Import festhalten, was WeakAuras schon fuehrt -
            -- sonst ist hinterher nicht zu erkennen, welche Anzeigen
            -- aus diesem Klick stammen (siehe ReconcilePending).
            NotePendingInstall(aura)

            if WeakAuras and WeakAuras.Import then
                WeakAuras.Import(aura.string)
            end

            C_Timer.After(0.05, function()

                if WeintCodex.MainFrame then
                    WeintCodex.MainFrame:Hide()
                end

            end)

        end)

        --------------------------------------------------

        yOffset = yOffset - 45

    end

    --------------------------------------------------
    -- Leere Rubrik
    --------------------------------------------------
    -- Bis 2.1.0.0 konnte das nicht vorkommen, weil jede Rubrik
    -- mitgelieferte Auren hatte. Sobald die Companion mitspielt, kann
    -- sie es: eine leere Flaeche unter drei Spaltenkoepfen sieht
    -- aus wie ein Fehler.
    --------------------------------------------------

    if #entries == 0 then

        local empty = container:CreateFontString(nil, "OVERLAY")
        empty:SetFont(WeintCodex.Fonts.sans, 12, "")
        empty:SetPoint("TOPLEFT", 15, yOffset - 10)
        empty:SetWidth(600)
        empty:SetJustifyH("LEFT")
        empty:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
        empty:SetText("Für diese Rubrik ist noch keine Aura hinterlegt. In der WeintCompanion lässt sich eine eintragen - sie erscheint hier nach dem nächsten /reload.")

        yOffset = yOffset - 60

    end

    --------------------------------------------------
    -- Scrollhoehe anpassen
    --------------------------------------------------

    local height = math.abs(yOffset) + 40
    container:SetHeight(height)

    container:Show()

    local waInstalled = (WeakAuras ~= nil)

    local rows = {
        { label = "Einträge",  value = tostring(#entries) },
        { label = "WeakAuras", value = waInstalled and "erkannt" or "nicht gefunden",
          valueColor = waInstalled and "success" or "danger" },
    }

    -- Die Zahl steht nur da, wenn es etwas zu zaehlen gibt: eine
    -- dauerhafte "0 aus der Companion" waere ein Hinweis auf eine
    -- Funktion, nach der niemand gefragt hat.
    if delivered > 0 then
        rows[#rows + 1] = {
            label = "aus der Companion",
            value = tostring(delivered),
            valueColor = "info",
        }
    end

    if shared > 0 then
        rows[#rows + 1] = {
            label = "aus der Gilde",
            value = tostring(shared),
            valueColor = "success",
        }
    end

    if known > 0 then
        rows[#rows + 1] = {
            label = "installiert",
            value = installed .. " / " .. known,
            valueColor = (installed >= known) and "success" or "warning",
        }
    end

    WeintCodex.Navigation.SetInspector({
        { type = "header", text = categoryLabel },
        { type = "rows", rows = rows },
        { type = "divider" },
        { type = "card", lines = {
            "Ein Klick auf 'Installieren' übergibt die Aura direkt",
            "an WeakAuras und schließt WeintCodex danach.",
            "",
            "Der grüne Haken links steht an jeder Aura, die",
            "WeakAuras bereits führt.",
        }},
    })

end

--------------------------------------------------
-- Nach einer Zustellung neu zeichnen
--------------------------------------------------
-- Aufgerufen aus modules/companion.lua, wenn die Inbox eine neue
-- Bibliothek gebracht hat. Beim Login ist die Seite noch gar nicht
-- gezeichnet - dann gibt es nichts zu tun, die naechste Anzeige liest
-- den neuen Stand ohnehin.
--------------------------------------------------

function WeintCodex.WeakAuras.Refresh()

    if not WeintCodex.MainFrame or not WeintCodex.MainFrame:IsShown() then
        return
    end

    if WeintCodex.Navigation
        and WeintCodex.Navigation.CurrentTab
        and WeintCodex.Navigation.CurrentTab() ~= "weakauras" then
        return
    end

    WeintCodex.WeakAuras.ShowCategory(currentCategory)

end

--------------------------------------------------
-- Hauptansicht
--------------------------------------------------

function WeintCodex.WeakAuras.Show()

    local items = {}

    for _, category in ipairs(CATEGORIES) do

        items[#items + 1] = {
            label = CATEGORY_LABEL[category],
            onClick = function()
                WeintCodex.WeakAuras.ShowCategory(category)
            end
        }

    end

    WeintCodex.Navigation.BuildSidebar(
        "WeakAuras",
        items
    )

    WeintCodex.WeakAuras.ShowCategory("class")

end
