--------------------------------------------------
-- WeintCodex :: Mitreden — ja oder nein? (seit 2.7.2.0)
--------------------------------------------------
-- WeintCodex meldet sich von selbst: der Ausruestungs-Alarm springt ins
-- Bild, der Rotationshelfer geht an der Puppe auf, das Umschmieder-Fenster
-- oeffnet sich beim Umschmieder, und am Auktionshaus steht die
-- Einkaufsliste. Auf dem Charakter, den man spielt, ist das genau der
-- Sinn. Auf einem Zweitcharakter ist es Laerm.
--
-- DIE FRAGE WIRD GESTELLT, NICHT GERATEN.
--
-- Ob ein Charakter ein Twink ist, kann das Addon nicht wissen — und jede
-- Regel, die es zu erraten versucht (der mit der niedrigsten Stufe? der
-- zuletzt erstellte? der ohne Berufe?), liegt irgendwann daneben und
-- schaltet ausgerechnet dort ab, wo man mitreden lassen wollte. Also wird
-- einmal gefragt und die Antwort behalten.
--
-- GEFRAGT WIRD ERST AB EINER GEGENSTANDSSTUFE.
--
-- Vorher hat die Frage keinen Anlass: wer sich gerade hochspielt, tauscht
-- jede Stunde etwas und braucht keine Auskunft ueber Sockelboni. Die
-- Schwelle steht in den Einstellungen und ist ab Werk 520 — die Stufe, ab
-- der ein Charakter im Schlachtzug mitgeht und die Auskunft anfaengt, sich
-- zu lohnen.
--
-- WAS "NEIN" HEISST, STEHT IN DER FRAGE.
--
-- Nicht "das Addon ist aus" — `/wc` oeffnet es weiterhin vollstaendig, und
-- alles, was man selbst aufruft, funktioniert unveraendert. Nein heisst:
-- WeintCodex faengt auf diesem Charakter kein Gespraech an. Eine Frage,
-- deren Antwort man nur durch Ausprobieren erfaehrt, ist keine.
--
-- Und die Antwort ist umkehrbar: Einstellungen -> Fenster & Ansicht.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.OptIn = {}

local OI = WeintCodex.OptIn

local DEFAULT_ILVL = 520

--------------------------------------------------
-- Speicher
--------------------------------------------------
-- Je Charakter, denn genau darum geht es. Der Schluessel kommt aus
-- core/names.lua, damit "ich" hier dasselbe heisst wie ueberall sonst im
-- Addon (siehe dort: ein fehlender Realm ist ein Platzhalter, kein
-- Widerspruch).
--------------------------------------------------

local function Store()
    WeintCodex.SavedData = WeintCodex.SavedData or {}
    local sd = WeintCodex.SavedData
    sd.optIn = sd.optIn or {}
    if sd.optIn.minIlvl == nil then sd.optIn.minIlvl = DEFAULT_ILVL end
    sd.optIn.chars = sd.optIn.chars or {}
    return sd.optIn
end

local function Me()
    if WeintCodex.Names and WeintCodex.Names.Me then
        local me = WeintCodex.Names.Me()
        if me and me ~= "" then return me end
    end
    -- Vor PLAYER_LOGIN kennt der Client den Namen noch nicht. Dann wird
    -- NICHTS angelegt und nichts gelesen, statt einen namenlosen Topf zu
    -- fuellen (dieselbe Regel wie beim Encounter-Fortschritt).
    local name = UnitName and UnitName("player")
    if name and name ~= "" and name ~= UNKNOWNOBJECT then return name end
    return nil
end

--------------------------------------------------
-- Die eine Frage, die alle anderen Module stellen
--
-- IM ZWEIFEL JA. Ohne Antwort, ohne Namen, ohne alles verhaelt sich das
-- Addon wie vor 2.7.2.0 — dieselbe Zurueckhaltung wie bei `Can()` in
-- core/access.lua: ein Client, der nie gefragt wurde, wird nicht
-- stillgelegt.
--------------------------------------------------

function OI.Active()
    local me = Me()
    if not me then return true end
    local answer = Store().chars[me]
    if answer == false then return false end
    return true
end

function OI.Answered()
    local me = Me()
    return me ~= nil and Store().chars[me] ~= nil
end

function OI.SetActive(on)
    local me = Me()
    if not me then return end
    Store().chars[me] = on and true or false
    if WeintCodex.Settings and WeintCodex.Settings.Refresh then
        WeintCodex.Settings.Refresh()
    end
end

function OI.MinIlvl()
    return Store().minIlvl or DEFAULT_ILVL
end

function OI.SetMinIlvl(value)
    value = tonumber(value)
    if not value then return end
    if value < 1   then value = 1   end
    if value > 999 then value = 999 end
    Store().minIlvl = math.floor(value)
end

-- Fuer die Einstellungsseite: den Namen, um den es geht.
function OI.CharacterName()
    return Me()
end

--------------------------------------------------
-- Die Einblendung
--------------------------------------------------
-- Eckig, aus demselben Grund wie der Ausruestungs-Alarm: die Eckmasken aus
-- core/ui.lua brauchen die Farbe des Untergrunds, und dahinter liegt hier
-- die Spielwelt.
--------------------------------------------------

local frame = nil

local function Build()
    if frame then return frame end

    local C = WeintCodex.Colors
    local F = WeintCodex.Fonts

    frame = CreateFrame("Frame", "WeintCodexOptInFrame", UIParent)
    frame:SetSize(400, 186)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop",  function(self) self:StopMovingOrSizing() end)

    WeintCodex.SetSolidBg(frame, C.bgDark[1], C.bgDark[2], C.bgDark[3], 0.97)
    WeintCodex.DrawBorder(frame, C.gold[1], C.gold[2], C.gold[3], 0.75, 1)

    local eyebrow = frame:CreateFontString(nil, "OVERLAY")
    eyebrow:SetFont(F.mono, 9, "")
    eyebrow:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -16)
    eyebrow:SetTextColor(unpack(C.textFaint))
    eyebrow:SetText(WeintCodex.Spaced and WeintCodex.Spaced("WEINTCODEX") or "WEINTCODEX")

    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetFont(F.serif, 16, "")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -32)
    frame.title:SetPoint("RIGHT",   frame, "RIGHT", -18, 0)
    frame.title:SetJustifyH("LEFT")
    frame.title:SetTextColor(unpack(C.textBright))

    frame.body = frame:CreateFontString(nil, "OVERLAY")
    frame.body:SetFont(F.sans, 11, "")
    frame.body:SetPoint("TOPLEFT",  frame, "TOPLEFT",  18, -58)
    frame.body:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -18, -58)
    frame.body:SetJustifyH("LEFT")
    frame.body:SetSpacing(3)
    frame.body:SetTextColor(unpack(C.textDim))

    frame.yes = WeintCodex.CreateButton(frame, {
        text = "Ja, hier mitreden", kind = "primary", width = 176, height = 30,
        backdrop = "bgDark",
        onClick = function()
            OI.SetActive(true)
            frame:Hide()
            print(WeintCodex.ColorText("gold", "[WeintCodex]")
                .. " Alles klar — hier bleibt alles an."
                .. " |cff4A4A52Änderbar unter Einstellungen → Fenster & Ansicht.|r")
        end,
    })
    frame.yes:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 18, 16)

    frame.no = WeintCodex.CreateButton(frame, {
        text = "Nein, still bleiben", width = 176, height = 30,
        backdrop = "bgDark",
        onClick = function()
            OI.SetActive(false)
            frame:Hide()
            print(WeintCodex.ColorText("gold", "[WeintCodex]")
                .. " Auf diesem Charakter meldet sich WeintCodex nicht mehr von selbst."
                .. " |cffD4A24A/wc|r öffnet es weiterhin ganz normal.")
        end,
    })
    frame.no:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 16)

    frame:Hide()
    return frame
end

function OI.Ask(manual)
    local me = Me()
    if not me then return end

    Build()
    local ilvl = 0
    if GetAverageItemLevel then
        local ok, _, equipped = pcall(GetAverageItemLevel)
        if ok and equipped then ilvl = math.floor(equipped) end
    end

    frame.title:SetText(me .. " — hier mitreden?")
    frame.body:SetText(
        "Dieser Charakter trägt Gegenstandsstufe " .. ilvl .. "."
        .. "\n\nSagst du nein, fängt WeintCodex hier kein Gespräch mehr an:"
        .. " kein Ausrüstungs-Alarm, kein Rotationshelfer an der Puppe, kein"
        .. " Fenster beim Umschmieder, keine Einkaufsliste am Auktionshaus."
        .. "\n\n|cff6B6B74Das Addon selbst bleibt vollständig da — /wc öffnet"
        .. " es wie immer.|r")

    frame:Show()
    if manual then frame:Raise() end
end

--------------------------------------------------
-- Wann gefragt wird
--------------------------------------------------
-- NICHT bei PLAYER_LOGIN: dort ist weder die Spezialisierung noch der
-- Item-Cache verlaesslich, und die Gegenstandsstufe meldet der Client dann
-- oft noch als 0 (dieselbe Begruendung wie beim Ausruestungsbericht in
-- modules/companion.lua und beim Ausruestungs-Alarm).
--
-- Und nur EINMAL je Sitzung nachgesehen, solange die Frage offen ist: wer
-- die Schwelle beim Anlegen eines Teils ueberschreitet, bekommt sie beim
-- naechsten Anmelden — eine Frage mitten im Raid ist keine Verbesserung.
--------------------------------------------------

local ASK_DELAY = 12

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_ENTERING_WORLD")

local asked = false

watcher:SetScript("OnEvent", function()
    if asked then return end
    asked = true
    if not (C_Timer and C_Timer.After) then return end
    C_Timer.After(ASK_DELAY, function()
        if OI.Answered() then return end
        if not GetAverageItemLevel then return end
        local ok, _, equipped = pcall(GetAverageItemLevel)
        -- Ohne Antwort des Clients wird nicht gefragt: eine
        -- Gegenstandsstufe von 0 ist eine Aussage ueber den Ladezustand,
        -- keine ueber den Charakter.
        if not (ok and equipped and equipped > 0) then return end
        if equipped < OI.MinIlvl() then return end
        OI.Ask(false)
    end)
end)
