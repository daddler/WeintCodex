WeintCodex = WeintCodex or {}
WeintCodex.Version = "0.9.5"

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

    if WeintCodex.MainFrame:IsShown() then
        WeintCodex.MainFrame:Hide()
    else
        if WeintCodex.ResetToHome then
            WeintCodex.ResetToHome()
        end
        WeintCodex.MainFrame:Show()
    end
end

local function OnAddonLoaded(self, event, addonName)
    if addonName ~= "WeintCodex" then return end

        if not WeintCodex_SavedData then
            WeintCodex_SavedData = {
                bossData     = {},
                raidData     = {},
                materialData = {},
                twinks       = {},

                window = {
                    scale  = 1.0,
                    width  = 1100,
                    height = 752,
                },

                minimap = {
                    angle = 225,
                    hide = false,
                },
            }
        end

        WeintCodex_SavedData.window =
            WeintCodex_SavedData.window or { scale = 1.0, width = 1100, height = 752 }
        WeintCodex_SavedData.window.width  = WeintCodex_SavedData.window.width  or 1100
        WeintCodex_SavedData.window.height = WeintCodex_SavedData.window.height or 752
        WeintCodex_SavedData.twinks        = WeintCodex_SavedData.twinks or {}
        WeintCodex_SavedData.minimap =
        WeintCodex_SavedData.minimap or {
            angle = 225,
            hide = false,
        }

    WeintCodex.SavedData = WeintCodex_SavedData

    -- Restore saved window size
    if WeintCodex.ApplySavedWindow then
        WeintCodex.ApplySavedWindow()
    end

    if WeintCodex.ResetToHome then
        WeintCodex.ResetToHome()
    end

    print("|cff8B5CF6[WeintCodex]|r |cff22C55Ev" .. WeintCodex.Version .. "|r geladen. |cffaaaaaa/wc zum Öffnen.|r")
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", OnAddonLoaded)
