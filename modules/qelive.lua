--------------------------------------------------
-- WeintCodex :: QE Live — der Weg fuer Heiler
--------------------------------------------------
-- Seit 2.9.0.0 bringt *Charakter -> Simmen* die eigene Ausruestung zu
-- wowsims. Fuer Heiler ist das die falsche Adresse: geplant wird dort
-- questionablyepic.com/live, und zwar von allen. Diese Datei ist der
-- Heiler-Zweig derselben Seite.
--
-- WAS SIE TUT UND WAS NICHT.
--
-- Sie erzeugt den Importtext, den QE Live entgegennimmt, und sie bietet
-- QE Lives Vorgabegewichte als Vorschlag an. Sie ZERLEGT nichts, was von
-- dort kommt — es kommt nichts von dort, siehe data/qelive.lua.
--
-- SIE SCHREIBT EIN FREMDES FORMAT, ALSO MUSS SIE LAUT SCHEITERN.
--
-- In modules/statweights.lua steht "kein fremdes Addon", und das gilt
-- unveraendert: dort geht es ums LESEN einer fremden Ausgabe. Hier wird
-- geschrieben, und die einzige Entsprechung im Haus ist
-- core/wowsims_link.py drueben — mit derselben Auflage. Ein Importtext,
-- der falsch ankommt, faellt nirgends auf: QE Live nimmt ihn an, zeigt
-- eine Ausruestung, und nur wer nachzaehlt, sieht, dass drei Teile
-- fehlen.
--
-- Deshalb zwei Sicherungen:
--
--   * HEADER_LINES steht als benannte Zahl da, nicht als Zufall des
--     Textbausteins. QE Live ueberspringt die ersten acht Zeilen fest
--     (`for (var i = 8; ...)` in ClassicImportEngine.js) und beginnt
--     erst danach, nach `id=` zu suchen. Eine Zeile ZU WENIG im Kopf,
--     und der erste Gegenstand ist weg — ohne jede Fehlermeldung.
--   * QE.ReadBack liest den fertigen Text mit GENAU DERSELBEN Regel
--     zurueck, die QE Live anwendet — eigener Weg hin, eigener Weg
--     zurueck. Ein Erzeuger, der sich selbst bestaetigt, beweist nichts;
--     der Testlauf stellt beide gegeneinander, und QE.Export prueft die
--     Zahl der zurueckgelesenen Gegenstaende, bevor der Text herausgeht.
--
-- DIE AUSRUESTUNG WIRD NICHT NEU GERECHNET.
--
-- Die Aufwertungsstufe kommt aus modules/reforge_engine.lua
-- (`RE.UpgradeLevel`), die Link-Felder aus `RE.LinkParts`. Eine zweite
-- Fassung davon waere genau die Doppelung, an der die Sockelbewertung
-- ueber fuenf Releases gescheitert ist — und die Aufwertungsstufe ist
-- der Wert, an dem ein Teil um gut 16 % danebenliegt, wenn man ihn
-- ueberschlaegt.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.QELive = {}

local QE = WeintCodex.QELive

--------------------------------------------------
-- Das Format, so wie QE Live es liest
--------------------------------------------------
--
-- Der Text ist der eines SimC-Exports, und QE Live liest davon nur, was
-- es braucht: ab Zeile neun jede Zeile, in der `id=` vorkommt, zerlegt
-- an Kommas. Das erste Feld einer Zeile wird uebersprungen (dort steht
-- in SimC der Slotname) — welchen Platz ein Gegenstand einnimmt,
-- entscheidet drueben die eigene Datenbank anhand der Nummer.
--
-- Ein Gegenstand, dessen Zeile ein `#` enthaelt, gilt drueben als NICHT
-- angelegt. Unsere Kopfzeile traegt eines, steht aber vor Zeile neun.
--------------------------------------------------

QE.HEADER_LINES = 8

-- Die Reihenfolge ist die von QE Live: `bonus_id`, `gem_id` und
-- `enchant_id` werden vor `id` geprueft, sonst schluckt die Suche nach
-- "id=" sie mit. Wir schreiben sie deshalb NACH `id=` — dann ist die
-- Reihenfolge egal und der Text bleibt lesbar. `suffix`, `unique` und
-- `upgradeLevel` tragen kein "id=" und stehen ohnehin frei.

--------------------------------------------------
-- Welche Spec ueberhaupt hierher gehoert
--------------------------------------------------
--
-- Gefragt wird nicht "ist das ein Heiler", sondern "fuehrt QE Live
-- diese Spezialisierung". Das ist die genauere Frage und derselbe
-- Gedanke wie bei `sim_url()` drueben: ein unbekannter Schluessel wird
-- nicht geraten. Dass beide Antworten fuer MoP deckungsgleich sind —
-- QE Live fuehrt genau die sechs Heiler —, ist ein Umstand und keine
-- Regel, auf die man bauen sollte.
--------------------------------------------------

function QE.Entry(profileKey)
    local data = WeintCodex_QELive
    if type(data) ~= "table" or type(data.specs) ~= "table" then return nil end
    if not profileKey or profileKey == "" then return nil end
    return data.specs[tostring(profileKey):upper()]
end

function QE.Url()
    local data = WeintCodex_QELive
    return (type(data) == "table" and data.url) or "https://questionablyepic.com/live/"
end

--------------------------------------------------
-- Die Gewichte auf unsere Skala
--------------------------------------------------
--
-- Gerechnet wird mit SW.Normalize, also mit derselben Rechnung, die
-- eine eingefuegte Sim-Ausgabe durchlaeuft: "groesstes Gewicht = 100".
-- Eine eigene Skalierung daneben liefe irgendwann anders aus, und dann
-- haette derselbe Wert zwei Zahlen.
--
-- Was in `gaps` steht, faellt heraus, bevor skaliert wird. Es faellt
-- damit auch aus dem Vorschlag: das Feld auf *Priorisierung* behaelt
-- den Wert des Spec-Profils, und der Kasten darueber sagt, warum.
--
-- Rueckgabe: weights, gaps, oder nil
--------------------------------------------------

function QE.ScaleWeights(entry)
    if type(entry) ~= "table" or type(entry.weights) ~= "table" then
        return nil
    end

    local gaps = {}
    for _, key in ipairs(entry.gaps or {}) do gaps[key] = true end

    local raw, any = {}, false
    for key, value in pairs(entry.weights) do
        local number = tonumber(value)
        if number and number > 0 and not gaps[key] then
            raw[key] = number
            any = true
        end
    end

    if not any then return nil end

    local SW = WeintCodex.StatWeights
    if not (SW and SW.Normalize) then return nil end

    local scaled = SW.Normalize(raw)
    return scaled, entry.gaps or {}
end

--------------------------------------------------
-- Der Vorschlag
--------------------------------------------------
--
-- Er entsteht beim Zeichnen von *Priorisierung* und nicht beim Login.
-- Das ist Absicht: bei PLAYER_LOGIN ist die Spezialisierung nicht
-- verlaesslich (dieselbe Begruendung wie beim Ausruestungsbericht und
-- beim Ausruestungs-Alarm), und eine Datenquelle, die sich seit Wochen
-- nicht geaendert hat, muss sich niemandem in den Weg stellen. Wer die
-- Seite oeffnet, stellt die Frage ohnehin gerade.
--
-- EIN ZUGESTELLTER SIM-VORSCHLAG GEWINNT.
--
-- Was die Companion liefert, ist zu DIESEM Charakter und zu dieser
-- Ausruestung gerechnet; was hier steht, gilt fuer die Spec und fuer
-- jeden gleich. Liegt also schon etwas an, wird nichts darueber gelegt
-- — sonst verdraengte die schwaechere Auskunft die staerkere, und
-- niemand saehe, dass es je eine gab.
--
-- Die Kennung haengt am INHALT und am Stand der Datei. Damit ist
-- dieselbe Gewichtung derselbe Vorschlag (er kommt nach dem Uebernehmen
-- nicht wieder), und eine geaenderte ein neuer.
--------------------------------------------------

local function WeightId(entry, weights)
    local SW = WeintCodex.StatWeights
    local order = (SW and SW.ORDER) or {}

    local parts = {}
    for _, key in ipairs(order) do
        if weights[key] then
            parts[#parts + 1] = key .. weights[key]
        end
    end

    local stand = (WeintCodex_QELive and WeintCodex_QELive.stand) or "?"
    return "qelive-" .. stand .. "-" .. table.concat(parts, "-")
end

-- Rueckgabe: der bereitliegende Vorschlag oder nil
function QE.OfferWeights(profileKey)
    local entry = QE.Entry(profileKey)
    if not entry then return nil end

    local SW = WeintCodex.StatWeights
    if not (SW and SW.Offer and SW.Pending) then return nil end

    -- Liegt schon etwas an, bleibt es liegen (siehe oben).
    local standing = SW.Pending(profileKey)
    if standing then return nil end

    local weights, gaps = QE.ScaleWeights(entry)
    if not weights then return nil end

    local ok = SW.Offer({
        id      = WeightId(entry, weights),
        spec    = profileKey,
        weights = weights,
        source  = "qelive",
        created = 0,
    })

    if not ok then return nil end

    -- Was nicht uebernommen wurde, steht in der Datendatei und wird von
    -- der Seite dort gelesen (`QE.Entry`) — nicht am Vorschlag mit
    -- abgelegt. Ein Vermerk in den SavedData ueberdauerte eine Aenderung
    -- der Datendatei und benennte dann eine Luecke, die es nicht mehr
    -- gibt; die Datendatei ist die eine Quelle.
    return SW.Pending(profileKey)
end

--------------------------------------------------
-- Den Importtext bauen
--------------------------------------------------
--
-- Rein, damit der Testlauf ihn ohne Spiel pruefen kann — dieselbe
-- Trennung wie zwischen rotation_engine und rotationtrainer.
--
--   char  = { class = "priest", name = "Njiah", level = 90,
--             race = "nightelf", realm = "OokOok", region = "eu" }
--   items = Liste aus { slot = "head", id = 86881, enchant = 4207,
--                       gems = { 76694, 76700 }, suffix = 0, upgrade = 2 }
--------------------------------------------------

local function CleanToken(value, fallback)
    local text = tostring(value or ""):gsub("[%s,=\"\r\n]+", "")
    if text == "" then return fallback end
    return text:lower()
end

function QE.BuildExport(char, items)
    char  = char  or {}
    items = items or {}

    local class = CleanToken(char.class, "priest")
    local name  = tostring(char.name or "Charakter"):gsub("[\"\r\n,]", "")

    -- GENAU acht Zeilen. Steht eine zu wenig da, faellt drueben der
    -- erste Gegenstand aus der Liste; steht eine zu viel, der letzte
    -- Kopfeintrag mitten in die Ausruestung.
    local header = {
        "# WeintCodex " .. tostring(WeintCodex.Version or "?") .. " -> QE Live",
        class .. "=\"" .. name .. "\"",
        "level=" .. tostring(tonumber(char.level) or 90),
        "race=" .. CleanToken(char.race, "unknown"),
        "region=" .. CleanToken(char.region, "eu"),
        "server=" .. CleanToken(char.realm, "unknown"),
        "role=spell",
        "spec=" .. CleanToken(char.spec, "healer"),
    }

    -- Der Waechter, nicht die Beschriftung: die Zahl oben ist eine
    -- Aussage ueber QE Live, und wenn dieser Textbaustein ihr nicht
    -- mehr entspricht, wird kein Text herausgegeben.
    if #header ~= QE.HEADER_LINES then
        return nil, ("Kopfzeilen: %d statt %d"):format(#header, QE.HEADER_LINES)
    end

    local lines = {}
    for _, line in ipairs(header) do lines[#lines + 1] = line end

    local written = 0

    for _, item in ipairs(items) do
        local id = tonumber(item.id)
        if id and id > 0 then
            -- Das erste Feld wird drueben uebersprungen. Es traegt
            -- deshalb den Slotnamen: fuer QE Live bedeutungslos, fuer
            -- jeden, der den Text ansieht, der Unterschied zwischen
            -- einer Liste und einer Zahlenkolonne.
            local parts = { CleanToken(item.slot, "item") .. "=" }
            parts[#parts + 1] = "id=" .. id

            local ench = tonumber(item.enchant)
            if ench and ench > 0 then
                parts[#parts + 1] = "enchant_id=" .. ench
            end

            local gems = {}
            for _, gem in ipairs(item.gems or {}) do
                local value = tonumber(gem)
                if value and value > 0 then gems[#gems + 1] = tostring(value) end
            end
            if #gems > 0 then
                parts[#parts + 1] = "gem_id=" .. table.concat(gems, "/")
            end

            -- Zufallssuffixe ("des Adlers") stehen im Item-Link mit
            -- negativem Vorzeichen, in QE Lives eigener Tabelle positiv.
            -- Geschrieben wird der Betrag; die Diagnose druckt beides.
            local suffix = tonumber(item.suffix)
            if suffix and suffix ~= 0 then
                parts[#parts + 1] = "suffix=" .. math.abs(suffix)
            end

            local upgrade = tonumber(item.upgrade)
            if upgrade and upgrade > 0 then
                parts[#parts + 1] = "upgradeLevel=" .. math.floor(upgrade)
            end

            lines[#lines + 1] = table.concat(parts, ",")
            written = written + 1
        end
    end

    return table.concat(lines, "\n"), nil, written
end

--------------------------------------------------
-- Und derselbe Text mit QE Lives Regel zurueckgelesen
--------------------------------------------------
--
-- Nachgebaut ist hier ausdruecklich die REGEL DER GEGENSEITE und nicht
-- unsere eigene: ab Zeile neun jede Zeile mit `id=` darin, zerlegt an
-- Kommas, erstes Feld uebersprungen, `bonus_id`/`gem_id`/`enchant_id`
-- vor `id`. Genau deshalb faellt hier auf, was beim Erzeugen niemandem
-- auffiele.
--------------------------------------------------

function QE.ReadBack(text)
    if type(text) ~= "string" then return {} end

    local lines = {}
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        lines[#lines + 1] = line
    end

    local out = {}

    for index = QE.HEADER_LINES + 1, #lines do
        local line = lines[index]
        if line:find("id=", 1, true) and not line:find("#", 1, true) then
            local item = { gems = {} }
            local field = 0

            for piece in (line .. ","):gmatch("([^,]*),") do
                field = field + 1
                if field > 1 then
                    if piece:find("bonus_id=", 1, true) then
                        item.bonus = piece:match("bonus_id=(.+)")
                    elseif piece:find("gem_id=", 1, true) then
                        for gem in (piece:match("gem_id=(.+)") or ""):gmatch("[^/]+") do
                            item.gems[#item.gems + 1] = tonumber(gem)
                        end
                    elseif piece:find("enchant_id=", 1, true) then
                        item.enchant = tonumber(piece:match("enchant_id=(%-?%d+)"))
                    elseif piece:find("id=", 1, true) then
                        item.id = tonumber(piece:match("id=(%-?%d+)"))
                    elseif piece:find("suffix=", 1, true) then
                        item.suffix = tonumber(piece:match("suffix=(%-?%d+)"))
                    elseif piece:find("upgradeLevel=", 1, true) then
                        item.upgrade = tonumber(piece:match("upgradeLevel=(%-?%d+)"))
                    end
                end
            end

            if item.id then out[#out + 1] = item end
        end
    end

    return out
end

--------------------------------------------------
-- Die angelegte Ausruestung einsammeln
--------------------------------------------------
--
-- Gelesen wird der Item-Link (Verzauberung, Steine, Suffix) und die
-- Aufwertungsstufe aus modules/reforge_engine.lua. Ein Slot ohne
-- Grunddaten wird NICHT uebergangen, sondern gemeldet: ein Text, in dem
-- drei Teile fehlen, sieht drueben aus wie ein Charakter ohne diese
-- Teile — und das ist eine Aussage ueber unseren Item-Zwischenspeicher,
-- keine ueber die Ausruestung.
--
-- Rueckgabe: items, fehlend
--------------------------------------------------

-- Die SimC-Namen der Plaetze. Sie sind Beschriftung: welchen Platz ein
-- Gegenstand einnimmt, entscheidet QE Live an seiner Nummer.
local SLOT_NAMES = {
    [1] = "head", [2] = "neck", [3] = "shoulder", [5] = "chest",
    [6] = "waist", [7] = "legs", [8] = "feet", [9] = "wrist",
    [10] = "hands", [11] = "finger1", [12] = "finger2",
    [13] = "trinket1", [14] = "trinket2", [15] = "back",
    [16] = "main_hand", [17] = "off_hand",
}

function QE.Collect()
    local RE = WeintCodex.ReforgeEngine
    local slots = WeintCodex.Charakter and WeintCodex.Charakter.EquipSlots

    if not (slots and RE and RE.LinkParts) then
        return {}, {}
    end

    local items, missing = {}, {}

    for _, slotDef in ipairs(slots) do
        local link = GetInventoryItemLink("player", slotDef.id)
        if link then
            local parts = RE.LinkParts(link)
            local id = parts and parts[1]

            if id and id > 0 then
                local gems = {}
                for g = 1, 4 do
                    local value = parts[2 + g]
                    if value and value > 0 then gems[#gems + 1] = value end
                end

                local upgrade = 0
                if RE.UpgradeLevel then
                    local quality = select(3, GetItemInfo(link))
                    -- Ohne Grunddaten meldet der Client keine
                    -- Gegenstandsstufe, und dann ist die Aufwertung
                    -- unbekannt statt null. Gesagt wird es, gerechnet
                    -- wird nicht.
                    if quality == nil then
                        missing[#missing + 1] = slotDef.name
                    else
                        upgrade = RE.UpgradeLevel(link, id, quality) or 0
                    end
                end

                items[#items + 1] = {
                    slot    = SLOT_NAMES[slotDef.id] or "item",
                    id      = id,
                    enchant = parts[2],
                    gems    = gems,
                    suffix  = parts[7],
                    upgrade = upgrade,
                }
            end
        end
    end

    return items, missing
end

--------------------------------------------------
-- Der fertige Text
--
-- Rueckgabe: text, fehlend, gezaehlt   oder   nil, Grund
--------------------------------------------------

function QE.Export()
    local items, missing = QE.Collect()

    if #items == 0 then
        return nil, "Es ist nichts angelegt, was sich melden liesse."
    end

    local name, realm = UnitName("player")
    local _, class = UnitClass("player")
    local _, race = UnitRace("player")

    local profileKey
    if WeintCodex.Charakter and WeintCodex.Charakter.GetProfileKey then
        profileKey = WeintCodex.Charakter.GetProfileKey()
    end

    local text, problem, written = QE.BuildExport({
        class  = class,
        name   = name,
        level  = UnitLevel("player"),
        race   = race,
        realm  = realm ~= "" and realm or GetRealmName(),
        region = GetCVar and GetCVar("portal") or nil,
        spec   = profileKey,
    }, items)

    if not text then
        return nil, problem or "Der Text liess sich nicht bauen."
    end

    -- Die Gegenprobe mit QE Lives eigener Regel. Kommt dabei etwas
    -- anderes heraus als hineingegangen ist, geht gar nichts hinaus:
    -- ein Text, aus dem drueben zwei Teile fallen, sieht dort aus wie
    -- ein Charakter ohne diese Teile.
    local back = QE.ReadBack(text)
    if #back ~= written then
        return nil, ("Gegenprobe: %d von %d Gegenständen lesbar."):format(
            #back, written)
    end

    return text, missing, written
end

--------------------------------------------------
-- Diagnose
--
-- Aus demselben Grund wie /wc sockel, /wc tempo und /wc simmen pruefen:
-- von aussen sieht "QE Live zeigt nicht meine Ausruestung" bei einem
-- kalten Item-Zwischenspeicher, einer verpassten Aufwertungsstufe, einem
-- Zufallssuffix und einem geaenderten Format drueben voellig gleich aus.
--------------------------------------------------

local function Say(text)
    print(WeintCodex.ColorText("gold", "[WeintCodex]") .. " " .. text)
end

function QE.Diagnose()
    local profileKey
    if WeintCodex.Charakter and WeintCodex.Charakter.GetProfileKey then
        profileKey = WeintCodex.Charakter.GetProfileKey()
    end

    Say("QE Live — Spezialisierung: " .. tostring(profileKey))

    local entry = QE.Entry(profileKey)
    if entry then
        local weights, gaps = QE.ScaleWeights(entry)
        Say("  Gefuehrt als: " .. tostring(entry.label)
            .. (entry.beta and " (drueben Beta)" or ""))
        local parts = {}
        for _, key in ipairs((WeintCodex.StatWeights or {}).ORDER or {}) do
            if weights and weights[key] then
                parts[#parts + 1] = key .. " " .. weights[key]
            end
        end
        Say("  Gewichte (skaliert): " .. table.concat(parts, ", "))
        if gaps and #gaps > 0 then
            Say("  Ohne Zahl drueben: " .. table.concat(gaps, ", "))
        end
    else
        Say("  QE Live fuehrt diese Spezialisierung nicht.")
    end

    local items, missing = QE.Collect()
    Say(("  Angelegt gelesen: %d Gegenstaende, %d ohne Grunddaten")
        :format(#items, #missing))

    for _, item in ipairs(items) do
        Say(("    %s id=%s ench=%s steine=%d suffix=%s auf=%s"):format(
            item.slot, tostring(item.id), tostring(item.enchant),
            #(item.gems or {}), tostring(item.suffix),
            tostring(item.upgrade)))
    end

    local text, problem, written = QE.Export()
    if not text then
        Say("  Text: " .. tostring(problem))
        return
    end

    local back = QE.ReadBack(text)
    Say(("  Text: %d Zeilen, %d Gegenstaende geschrieben, %d zurueckgelesen")
        :format(select(2, text:gsub("\n", "\n")) + 1, written, #back))
    Say("  Kopfzeilen: " .. QE.HEADER_LINES)
end

--------------------------------------------------
-- Der Befehl
--
-- Er landet auf derselben Seite wie /wc simmen — die entscheidet selbst,
-- welchen der beiden Wege sie zeigt. Einen eigenen Namen hat er, weil
-- ihn sucht, wer "QE" kennt und mit "simmen" nichts anfaengt.
--------------------------------------------------

function QE.Command(rest)
    rest = (rest or ""):lower()

    if rest == "pruefen" or rest == "prüfen" or rest == "check" then
        QE.Diagnose()
        return
    end

    if WeintCodex.Navigation and WeintCodex.Navigation.GoToTab then
        WeintCodex.Navigation.GoToTab("charakter")
    end

    if WeintCodex.SimExport and WeintCodex.SimExport.ShowPage then
        WeintCodex.SimExport.ShowPage()
    end
end
