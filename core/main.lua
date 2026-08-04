WeintCodex = WeintCodex or {}
WeintCodex.Version = "1.3.0.0"

SLASH_WEINTCODEX1 = "/wc"
SLASH_WEINTCODEX2 = "/weintcodex"

SlashCmdList["WEINTCODEX"] = function(msg)
    local cmd = msg and msg:lower() or ""

    -- Erstes Wort plus Rest: die Befehle unten vergleichen weiterhin exakt,
    -- nur "access" braucht ein Argument (siehe core/access.lua).
    local verb, rest = cmd:match("^(%S+)%s*(.-)$")
    verb = verb or ""
    rest = rest or ""

    -- Zugriffsprofil anzeigen / Verknuepfung aufheben
    if verb == "access" or verb == "zugriff" then
        if not WeintCodex.Access then return end
        if rest == "reset" then
            WeintCodex.Access.Reset(false)
        elseif rest == "reset bestaetigen" or rest == "reset bestätigen" then
            WeintCodex.Access.Reset(true)
        else
            WeintCodex.Access.Print()
        end
        return
    end

    if cmd == "import" then
        if WeintCodex.Sync and WeintCodex.Sync.ShowImportDialog then
            WeintCodex.Sync.ShowImportDialog()
        end
        return
    end

    -- Verzauberungs-/Sockel-Dump zur Datenpflege (IDs + Client-Namen)
    if cmd == "vz" or cmd == "dump" then
        if WeintCodex.Charakter and WeintCodex.Charakter.DumpEnchants then
            WeintCodex.Charakter.DumpEnchants()
        end
        return
    end

    -- Addon-Tour manuell erneut aufrufen (z.B. zum Testen)
    if cmd == "tour" then
        if WeintCodex.Onboarding and WeintCodex.Onboarding.ShowTour then
            WeintCodex.Onboarding.ShowTour()
        end
        return
    end

    -- Rotationstrainer: Puppen-Prioritätenliste manuell oeffnen/schliessen
    -- (siehe modules/rotationtrainer.lua) - Fallback fuer Ziele, die nicht
    -- automatisch als Trainingspuppe erkannt werden.
    if verb == "training" or verb == "trainer" then
        if not WeintCodex.RotationTrainer then return end
        if rest == "stop" then
            WeintCodex.RotationTrainer.StopManual()
        else
            WeintCodex.RotationTrainer.Toggle()
        end
        return
    end

    if WeintCodex.MainFrame:IsShown() then
        WeintCodex.MainFrame:Hide()
    else
        if WeintCodex.ResetToHome then
            WeintCodex.ResetToHome()
        end
        WeintCodex.MainFrame:Show()
    end
end

local function OnEvent(self, event, addonName)

    if event == "PLAYER_LOGIN" then

        -- Meldet den eingeloggten Charakter automatisch ans Companion,
        -- damit der Bot den echten WoW-Namen (statt Discord-Namen)
        -- fürs Kalender-Invite kennt - siehe modules/companion.lua.
        if WeintCodex.Companion and WeintCodex.Companion.ReportCharacter then
            WeintCodex.Companion.ReportCharacter()
        end

        -- Bereits importierte Rosterdaten erneut auflösen - UnitClass/
        -- UnitName sind bei ADDON_LOADED (Zeitpunkt des ursprünglichen
        -- Imports über ProcessInbox) noch nicht zuverlässig verfügbar.
        if WeintCodex.Raids and WeintCodex.Raids.ResolveNames and WeintCodex.SavedData then
            WeintCodex.Raids.ResolveNames(WeintCodex.SavedData.raidWednesday)
            WeintCodex.Raids.ResolveNames(WeintCodex.SavedData.raidThursday)
        end

        -- Datenintegrität prüfen: warnt, falls Spec-Profile eine
        -- Verzauberungs-/Stein-ID referenzieren, die nicht (mehr) in
        -- enchants.lua / gems.lua existiert (Drift-Schutz).
        if WeintCodex_ValidateSpecData then
            WeintCodex_ValidateSpecData()
        end

        -- Dasselbe für die BiS-Listen: warnt, falls ein Eintrag einen
        -- Boss- oder Slot-Namen nutzt, den es nicht gibt (Tippfehler
        -- würden das Item sonst still nirgends anzeigen).
        if WeintCodex_ValidateBiSData then
            WeintCodex_ValidateBiSData()
        end

        -- Dasselbe fuer die Rotationstrainer-Prioritaetenlisten: warnt,
        -- falls ein Eintrag eine Spec referenziert, die es nicht (mehr)
        -- gibt, oder keine always-Filler-Regel besitzt.
        if WeintCodex_ValidateRotationData then
            WeintCodex_ValidateRotationData()
        end

        -- Erststart-Tour bzw. Update-Changelog-Popup (core/onboarding.lua):
        -- zeigt neuen Nutzern eine kurze Feature-Tour, bestehenden Nutzern
        -- nach einem Versionswechsel, was sich geaendert hat.
        if WeintCodex.Onboarding and WeintCodex.Onboarding.Check then
            WeintCodex.Onboarding.Check()
        end

        return
    end

    if addonName ~= "WeintCodex" then return end

        if not WeintCodex_SavedData then
            WeintCodex_SavedData = {
                bossData          = {},
                raidData          = {},
                materialData      = {},
                twinks            = {},
                encounterProgress = {},

                window = {
                    scale  = 1.0,
                    width  = 1500,
                    height = 800,
                },

                minimap = {
                    angle = 225,
                    hide = false,
                },
            }
        end

        WeintCodex_SavedData.window =
            WeintCodex_SavedData.window or { scale = 1.0, width = 1500, height = 800 }
        WeintCodex_SavedData.window.width  = WeintCodex_SavedData.window.width  or 1500
        WeintCodex_SavedData.window.height = WeintCodex_SavedData.window.height or 800

        -- Migration auf das Redesign (Icon-Rail + Inspector-Spalte benötigen
        -- mehr Breite): alte, kleinere gespeicherte Fenstergrößen einmalig anheben.
        if WeintCodex_SavedData.window.width < 1180 then
            WeintCodex_SavedData.window.width = 1500
        end
        if WeintCodex_SavedData.window.height < 780 then
            WeintCodex_SavedData.window.height = 800
        end

        WeintCodex_SavedData.twinks            = WeintCodex_SavedData.twinks or {}
        WeintCodex_SavedData.encounterProgress = WeintCodex_SavedData.encounterProgress or {}
        WeintCodex_SavedData.minimap =
        WeintCodex_SavedData.minimap or {
            angle = 225,
            hide = false,
        }

    WeintCodex.SavedData = WeintCodex_SavedData

    -- Zugriffsprofil bereitstellen, BEVOR die Inbox verarbeitet wird: die
    -- Herkunftsprüfung der Nachrichten hängt daran (siehe core/access.lua).
    if WeintCodex.Access and WeintCodex.Access.Init then
        WeintCodex.Access.Init()
    end

    -- Companion-Inbox verarbeiten (z. B. automatisch abgerufener
    -- Raid-Roster-Export von einem per Discord-Login verknüpften Raidlead)
    if WeintCodex.Companion and WeintCodex.Companion.ProcessInbox then
        WeintCodex.Companion.ProcessInbox()
    end

    -- Sperren aus dem Zugriffsprofil anwenden. Muss nach ProcessInbox laufen
    -- (das Profil kann in genau diesem Login angekommen sein) und vor
    -- ResetToHome, damit das Dashboard nicht einmal mit Zahlen aufblitzt.
    if WeintCodex.Access and WeintCodex.Access.Apply then
        WeintCodex.Access.Apply()
    end

    -- Restore saved window size
    if WeintCodex.ApplySavedWindow then
        WeintCodex.ApplySavedWindow()
    end

    if WeintCodex.ResetToHome then
        WeintCodex.ResetToHome()
    end

    print("|cffC8763A[WeintCodex]|r |cff22C55Ev" .. WeintCodex.Version .. "|r geladen. |cffaaaaaa/wc zum Öffnen.|r")
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", OnEvent)
