-- ==========================================================
-- WeintCodex Minimap Button
-- LibDataBroker + LibDBIcon
-- ==========================================================

local LDB = LibStub("LibDataBroker-1.1")
local DBIcon = LibStub("LibDBIcon-1.0")

WeintCodex.Minimap = WeintCodex.Minimap or {}

----------------------------------------------------------
-- SavedVariables
----------------------------------------------------------

local function GetDB()

WeintCodex_SavedData = WeintCodex_SavedData or {}

WeintCodex_SavedData.minimap =
WeintCodex_SavedData.minimap or {
    hide = false,
}

return WeintCodex_SavedData.minimap

end

----------------------------------------------------------
-- Öffnen / Schließen
----------------------------------------------------------

local function ToggleAddon()

if not WeintCodex.MainFrame then
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

                ----------------------------------------------------------
                -- Tooltip-Helfer
                ----------------------------------------------------------

                local function GetBossguideCount()

                if not BossData then
                    return 0
                    end

                    local count = 0

                    for _ in pairs(BossData) do
                        count = count + 1
                        end

                        return count

                        end

                        local function GetCurrentSpec()

                        local _, class = UnitClass("player")

                        local spec = GetSpecialization and GetSpecialization()

                        if not spec then
                            return class or "Unbekannt"
                            end

                            local id, name = GetSpecializationInfo(spec)

                            if name then
                                return string.format("%s (%s)", class, name)
                                end

                                return class or "Unbekannt"

                                end

                                ----------------------------------------------------------
                                -- DataBroker Objekt
                                ----------------------------------------------------------

                                local launcher = LDB:NewDataObject("WeintCodex", {

                                    type = "launcher",

                                    icon = "Interface\\AddOns\\WeintCodex\\media\\button",

                                    label = "WeintCodex",

                                    ------------------------------------------------------
                                    -- Klick
                                    ------------------------------------------------------

                                    OnClick = function(_, button)

                                    if button == "LeftButton" then

                                        ToggleAddon()

                                        elseif button == "RightButton" then

                                            if not WeintCodex.MainFrame:IsShown() then
                                                ToggleAddon()
                                                end

                                                if WeintCodex.Navigation
                                                    and WeintCodex.Navigation.SwitchTo then

                                                    WeintCodex.Navigation.SwitchTo("bossguides")

                                                    end

                                                    end

                                                    end,

                                                    ------------------------------------------------------
                                                    -- Tooltip
                                                    ------------------------------------------------------

                                                    OnTooltipShow = function(tt)

                                                    tt:AddLine("|cffC8763AWeintCodex|r")
                                                    tt:AddLine("|cffFFD100Raid Guide & Intelligence System|r")
                                                    tt:AddLine(" ")

                                                    tt:AddDoubleLine(
                                                        "|cff00ff00Linksklick|r",
                                                        "Addon öffnen / schließen",
                                                        1,1,1,
                                                        .85,.85,.85
                                                    )

                                                    tt:AddDoubleLine(
                                                        "|cffA335EERechtsklick|r",
                                                        "Bossguides öffnen",
                                                        1,1,1,
                                                        .85,.85,.85
                                                    )

                                                    tt:AddLine(" ")

                                                    tt:AddDoubleLine(
                                                        "|cffFFD100Version|r",
                                                        WeintCodex.Version or "?",
                                                        1,1,1,
                                                        .85,.85,.85
                                                    )

                                                    tt:AddDoubleLine(
                                                        "|cffFFD100Bossguides|r",
                                                        tostring(GetBossguideCount()),
                                                                     1,1,1,
                                                                     .85,.85,.85
                                                    )

                                                    tt:AddDoubleLine(
                                                        "|cffFFD100Klasse|r",
                                                        GetCurrentSpec(),
                                                                     1,1,1,
                                                                     .85,.85,.85
                                                    )

                                                    end,

                                })

                                ----------------------------------------------------------
                                -- Registrierung
                                ----------------------------------------------------------

                                local frame = CreateFrame("Frame")

                                frame:RegisterEvent("PLAYER_LOGIN")

                                frame:SetScript("OnEvent", function()

                                DBIcon:Register(
                                    "WeintCodex",
                                    launcher,
                                    GetDB()
                                )

                                end)
