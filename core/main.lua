WeintCodex = WeintCodex or {}
WeintCodex.Version = "0.9.9.26"

SLASH_WEINTCODEX1 = "/wc"
SLASH_WEINTCODEX2 = "/weintcodex"

SlashCmdList["WEINTCODEX"] = function(msg)
    local cmd = msg and msg:lower() or ""

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

    -- Companion-Inbox verarbeiten (z. B. automatisch abgerufener
    -- Raid-Roster-Export von einem per Discord-Login verknüpften Raidlead)
    if WeintCodex.Companion and WeintCodex.Companion.ProcessInbox then
        WeintCodex.Companion.ProcessInbox()
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
