--------------------------------------------------
-- WeintCodex :: BiS-Logik
--
-- Beantwortet für einen Boss die Frage "droppt hier ein BiS-Item für
-- meine Spec, und habe ich es schon?". Reine Logik, kein UI-Code - die
-- Darstellung übernimmt der itemlist-Block des Inspectors
-- (core/navigation.lua), befüllt von modules/bossguides.lua.
--
-- Datengrundlage: data/bis.lua (WeintCodex_BiS, nach Spec sortiert).
-- Da die Anzeige nach BOSS fragt, die Daten aber nach SPEC gepflegt
-- werden, wird beim ersten Zugriff einmalig ein Boss-Index aufgebaut.
--
-- "Habe ich es schon" prüft bewusst NUR die angelegte Ausrüstung -
-- nicht Taschen oder Bank. Ein Item im Beutel heißt nicht, dass man
-- nicht mehr würfeln muss.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.BiS = {}

--------------------------------------------------
-- SLOT -> INVENTARSLOTS
--
-- Abgeleitet aus EQUIP_SLOTS in modules/charakter.lua, aber mit
-- zusammengefassten Doppelslots: eine BiS-Liste sagt "dieser Ring",
-- nicht "Ringplatz 1". MoP hat keinen Fernkampfslot mehr (18),
-- Hemd (4) und Wappenrock (19) sind für BiS irrelevant.
--------------------------------------------------

local SLOT_INVENTORY = {
    ["Kopf"]        = { 1 },
    ["Hals"]        = { 2 },
    ["Schultern"]   = { 3 },
    ["Brust"]       = { 5 },
    ["Taille"]      = { 6 },
    ["Beine"]       = { 7 },
    ["Füße"]        = { 8 },
    ["Handgelenke"] = { 9 },
    ["Hände"]       = { 10 },
    ["Finger"]      = { 11, 12 },
    ["Schmuck"]     = { 13, 14 },
    ["Umhang"]      = { 15 },
    ["Haupthand"]   = { 16 },
    ["Nebenhand"]   = { 17 },
}

-- Sortierrang je Slot, damit die Liste immer in derselben Reihenfolge
-- steht (von oben nach unten wie im Charakterfenster).
local SLOT_RANK = {}
for rank, slotName in ipairs(WeintCodex_BiSSlots or {}) do
    SLOT_RANK[slotName] = rank
end

-- Reihenfolge der Zustände in der Liste: was noch offen ist, steht oben.
local STATE_RANK = {
    open    = 1,
    variant = 2,
    have    = 3,
}

--------------------------------------------------
-- BOSS-INDEX
--
-- bossIndex[bossName][specKey] = { entry, entry, ... }
-- Wird einmal aufgebaut und gecacht; WeintCodex_BiS ist statisch.
--------------------------------------------------

local bossIndex = nil

local function BuildBossIndex()
    local index = {}

    for specKey, entries in pairs(WeintCodex_BiS or {}) do

        if type(entries) == "table" then

            for _, entry in ipairs(entries) do

                -- boss darf ein einzelner Name oder eine Liste sein
                local bossList = entry.boss
                if type(bossList) == "string" then bossList = { bossList } end

                if type(bossList) == "table" then
                    for _, bossName in ipairs(bossList) do
                        index[bossName] = index[bossName] or {}
                        index[bossName][specKey] = index[bossName][specKey] or {}
                        table.insert(index[bossName][specKey], entry)
                    end
                end

            end

        end

    end

    return index
end

local function GetBossIndex()
    if not bossIndex then
        bossIndex = BuildBossIndex()
    end
    return bossIndex
end

--------------------------------------------------
-- ANGELEGTE AUSRÜSTUNG
--
-- Liefert { [itemID] = true } über alle Ausrüstungsslots. Wird pro
-- Aufruf einmal gebaut, nicht pro Item.
--------------------------------------------------

local function GetEquippedItemId(slotId)
    if GetInventoryItemID then
        local ok, itemId = pcall(GetInventoryItemID, "player", slotId)
        if ok and itemId then return itemId end
    end

    -- Fallback über den Item-Link (gleiches Muster wie in
    -- charakter.lua und materials.lua)
    local link = GetInventoryItemLink and GetInventoryItemLink("player", slotId)
    if link then
        return tonumber(link:match("item:(%d+)"))
    end

    return nil
end

local function BuildEquippedIndex()
    local equipped = {}

    for _, slotIds in pairs(SLOT_INVENTORY) do
        for _, slotId in ipairs(slotIds) do
            local itemId = GetEquippedItemId(slotId)
            if itemId then equipped[itemId] = true end
        end
    end

    return equipped
end

WeintCodex.BiS.GetEquippedIndex = BuildEquippedIndex

--------------------------------------------------
-- ZUSTAND EINES EINTRAGS
--
--   "have"    = genau dieses Item ist angelegt -> nicht mehr würfeln
--   "variant" = eine andere Schwierigkeitsstufe ist angelegt ->
--               man hat das Item im Prinzip, das Upgrade lohnt aber noch
--   "open"    = fehlt komplett
--------------------------------------------------

local function ResolveState(entry, equipped)
    if equipped[entry.id] then
        return "have", entry.id
    end

    if type(entry.variants) == "table" then
        for _, variantId in ipairs(entry.variants) do
            if equipped[variantId] then
                return "variant", variantId
            end
        end
    end

    return "open", nil
end

--------------------------------------------------
-- AKTUELLE SPEC
--
-- charakter.lua exportiert GetProfileKey(); der Fallback greift nur,
-- falls das Charakter-Modul (noch) nicht geladen ist.
--------------------------------------------------

function WeintCodex.BiS.GetSpecKey()
    if WeintCodex.Charakter and WeintCodex.Charakter.GetProfileKey then
        return WeintCodex.Charakter.GetProfileKey()
    end
    return nil
end

--------------------------------------------------
-- ÖFFENTLICHE ABFRAGE
--
-- Rückgabe:
--   entries      Liste von { id, slot, note, state, ownedID }
--                sortiert nach Zustand (offen zuerst), dann Slot
--   hasSpecData  true, wenn für diese Spec überhaupt BiS-Daten
--                gepflegt sind - damit die UI "keine Daten gepflegt"
--                von "hier droppt nichts für dich" unterscheiden kann
--------------------------------------------------

function WeintCodex.BiS.GetForBoss(bossName, specKey)
    if not bossName or not specKey then return {}, false end

    local specEntries = WeintCodex_BiS and WeintCodex_BiS[specKey]
    local hasSpecData = type(specEntries) == "table" and #specEntries > 0

    local forBoss = GetBossIndex()[bossName]
    local raw = forBoss and forBoss[specKey]
    if not raw or #raw == 0 then return {}, hasSpecData end

    local equipped = BuildEquippedIndex()
    local result = {}

    for _, entry in ipairs(raw) do
        local state, ownedId = ResolveState(entry, equipped)
        result[#result + 1] = {
            id      = entry.id,
            slot    = entry.slot,
            note    = entry.note,
            state   = state,
            ownedID = ownedId,
        }
    end

    table.sort(result, function(a, b)
        local sa = STATE_RANK[a.state] or 99
        local sb = STATE_RANK[b.state] or 99
        if sa ~= sb then return sa < sb end

        local ra = SLOT_RANK[a.slot] or 99
        local rb = SLOT_RANK[b.slot] or 99
        if ra ~= rb then return ra < rb end

        return (a.id or 0) < (b.id or 0)
    end)

    return result, hasSpecData
end

--------------------------------------------------
-- AKTUALISIERUNG
--
-- Legt man ein BiS-Item an oder wechselt die Spec, muss die Liste im
-- Bossguide sofort umspringen - ohne /reload. Beide Events werden über
-- pcall registriert, weil ihre Verfügbarkeit zwischen den Classic-
-- Clients schwankt (gleiches Muster wie in modules/loot.lua).
--------------------------------------------------

local watcher = CreateFrame("Frame")

local function TryRegisterEvent(frame, eventName)
    return pcall(frame.RegisterEvent, frame, eventName)
end

TryRegisterEvent(watcher, "PLAYER_EQUIPMENT_CHANGED")
TryRegisterEvent(watcher, "PLAYER_SPECIALIZATION_CHANGED")
TryRegisterEvent(watcher, "ACTIVE_TALENT_GROUP_CHANGED")

watcher:SetScript("OnEvent", function()
    if WeintCodex.BossGuides and WeintCodex.BossGuides.RefreshInspector then
        WeintCodex.BossGuides.RefreshInspector()
    end
end)
