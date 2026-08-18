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
--                       author, icon, string, origin } }
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
                origin      = "companion",
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
    hName:SetPoint("LEFT", 42, 0)
    hName:SetWidth(140)
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

    local delivered = 0

    for _, entry in ipairs(entries) do
        if entry.origin == "companion" then delivered = delivered + 1 end
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
        -- Icon
        --------------------------------------------------

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(24, 24)
        icon:SetPoint("LEFT", 5, 0)

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
        name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -1)
        name:SetWidth(140)
        name:SetJustifyH("LEFT")
        name:SetText(aura.name)

        local origin = row:CreateFontString(nil, "OVERLAY")
        origin:SetFont(WeintCodex.Fonts.sans, 10, "")
        origin:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -2)
        origin:SetWidth(140)
        origin:SetJustifyH("LEFT")
        origin:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])

        if aura.origin == "companion" then

            local label = aura.replaced and "Companion · ersetzt" or "Companion"

            if aura.author ~= "" then
                label = "Companion · " .. aura.author
            end

            origin:SetText(WeintCodex.Truncate(label, 24))
            origin:SetTextColor(C.blue[1], C.blue[2], C.blue[3])

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
        local txt = btn:CreateFontString(nil, "OVERLAY")
        txt:SetFont(WeintCodex.Fonts.sans, 11, "")
        txt:SetPoint("CENTER")
        txt:SetText("Installieren")

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

    WeintCodex.Navigation.SetInspector({
        { type = "header", text = categoryLabel },
        { type = "rows", rows = rows },
        { type = "divider" },
        { type = "card", lines = {
            "Ein Klick auf 'Installieren' übergibt die Aura direkt",
            "an WeakAuras und schließt WeintCodex danach.",
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
