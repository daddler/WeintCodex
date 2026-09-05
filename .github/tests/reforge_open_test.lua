-- Kopflose Pruefung: geht das Fenster beim Umschmieder auf, und sagt das
-- Addon, warum nicht?
--
-- Gemeldet wurde "wenn man das Umschmieden aktiviert, oeffnet es sich
-- trotzdem nicht, wenn man den Umschmieder anklickt". Zwischen dem Schalter
-- und dem Fenster liegen vier Bedingungen, und bis 2.10.0.0 schwieg jede von
-- ihnen: ein ausgeschalteter Planer, ein abgewaehltes "beim Umschmieder
-- oeffnen", ein "hier nicht von selbst" auf diesem Charakter und ein
-- Ereignis, das der Client gar nicht fuehrt, sahen von aussen gleich aus.
--
-- Geprueft wird deshalb VERHALTEN und nicht eine Textausgabe: fuer jede der
-- vier Bedingungen einmal, dass das Fenster wirklich zubleibt bzw. aufgeht,
-- dass ein Grund genannt wird, und dass ein Client ohne das Ereignis ueber
-- das Fenster des Umschmieders trotzdem hinkommt.
--
-- Lauf:  lua5.1 .github/tests/reforge_open_test.lua .

local ROOT = ... or "."
local say = print          -- der echte, bevor der Lauf ihn einsammelt

--== WoW-Attrappen ==========================================================
local frames = {}
local KNOWN = {}

local function stubFrame(name)
    local f = { _name = name, _events = {}, _scripts = {}, _shown = false }
    setmetatable(f, { __index = function(_, k)
        return function(self, ...)
            if k == "RegisterEvent" then
                local e = ...
                if not KNOWN[e] then error("unknown event: " .. tostring(e), 2) end
                self._events[e] = true
            elseif k == "UnregisterAllEvents" then self._events = {}
            elseif k == "SetScript" or k == "HookScript" then
                local which, fn = ...
                self._scripts[which] = fn
            elseif k == "Show"    then self._shown = true
            elseif k == "Hide"    then self._shown = false
            elseif k == "IsShown" then return self._shown
            elseif k == "GetText" then return ""
            elseif k == "CreateFontString" or k == "CreateTexture" then return stubFrame()
            elseif k:match("Width$") or k:match("Height$") then return 100 end
            return nil
        end
    end })
    frames[#frames + 1] = f
    return f
end

--== Ein Lauf: Addon frisch laden, Bedingungen setzen, Umschmieder oeffnen ==
--
-- Frisch geladen, weil die Datei ihre Ereignisse beim Laden anmeldet und
-- sich merkt, was sie einmal gesagt hat.
local function run(opts)
    frames = {}
    KNOWN = {
        FORGE_MASTER_OPENED = not opts.clientWithoutEvent,
        FORGE_MASTER_CLOSED = true, FORGE_MASTER_ITEM_CHANGED = true,
        PLAYER_EQUIPMENT_CHANGED = true, PLAYER_SPECIALIZATION_CHANGED = true,
        GET_ITEM_INFO_RECEIVED = true, ADDON_LOADED = true,
    }
    for k in pairs(KNOWN) do if KNOWN[k] == false then KNOWN[k] = nil end end

    local said = {}
    _G.CreateFrame = function(_, name) return stubFrame(name) end
    _G.UIParent = stubFrame("UIParent")
    _G.ReforgingFrame = nil
    _G.GameTooltip = stubFrame("GameTooltip")
    _G.GetCoinTextureString = function() return "1g" end
    _G.C_Timer = { After = function() end }
    _G.GetTime = function() return 100 end
    _G.print = function(t) said[#said + 1] = tostring(t) end

    _G.WeintCodex = { SavedData = { reforge = { options = {} } } }
    local W = _G.WeintCodex
    W.ColorText = function(_, t) return t or "" end
    W.Upper, W.FormatGrouped = function(t) return t end, tostring
    W.Colors = setmetatable({}, { __index = function() return { 1, 1, 1 } end })
    W.Fonts  = setmetatable({}, { __index = function() return "font" end })
    W.SetSolidBg, W.DrawBorder, W.SetBreadcrumb = function() end, function() end, function() end
    W.CreateSegmentedControl = function() return stubFrame("seg") end
    W.CreateScrollArea = function() local f = stubFrame("scroll") return f, stubFrame() end
    W.CreateButton = function() return stubFrame("btn") end
    W.PageHead = function() local f = stubFrame() f.Height, f.Stats = 78, {} return f end
    W.Charakter = { EquipSlots = {}, GetFavor = function() return nil end,
                    Rationale = function() return {} end }
    W.StatMatch = {}
    W.Navigation = { CurrentTab = function() return "charakter" end, SetInspector = function() end }
    W.OptIn = { Active = function() return opts.optIn ~= false end,
                CharacterName = function() return "Twinki-OokOok" end }

    _G.WeintCodex_Reforge = { STATS = {}, SHORT = {}, LABEL = {} }
    local RE = {}
    W.ReforgeEngine = RE
    RE.CAP_SLACK, RE.UNFORGE_INDEX = 40, 0
    RE.Enabled   = function() return opts.enabled ~= false end
    RE.GetOption = function(k) return k == "autoOpen" and (opts.autoOpen ~= false) or false end
    RE.SetOption, RE.Invalidate, RE.OnPlanReady = function() end, function() end, function() end
    RE.GetPlan   = function() return { ok = true, rows = {}, changes = 0, ctx = { weights = {} } } end
    RE.IsLocked, RE.GetManual, RE.CurrentPair =
        function() return false end, function() return nil end, function() return nil end
    RE.Choices, RE.ManualCount = function() return {} end, function() return 0 end
    RE.SetLocked, RE.SetManual, RE.ClearManual = function() end, function() end, function() end
    RE.ForgeIndex, RE.LearnedField = function() return nil end, function() return nil end
    RE.LinkParts, RE.TargetSummary = function() return {} end, function() return {} end

    local ok, err = pcall(dofile, ROOT .. "/modules/reforge.lua")
    if not ok then _G.print = say error(err, 0) end
    local RF = W.Reforge

    -- Den Umschmieder oeffnen — auf dem Weg, den dieser Client hergibt.
    local delivered = false
    if opts.clientWithoutEvent then
        _G.ReforgingFrame = stubFrame("ReforgingFrame")
        for _, f in ipairs(frames) do
            if f._events.ADDON_LOADED and f._scripts.OnEvent then
                f._scripts.OnEvent(f, "ADDON_LOADED", "Blizzard_ReforgingUI")
            end
        end
        local onShow = _G.ReforgingFrame._scripts.OnShow
        if onShow then onShow(_G.ReforgingFrame) delivered = true end
    else
        for _, f in ipairs(frames) do
            if f._events.FORGE_MASTER_OPENED and f._scripts.OnEvent then
                f._scripts.OnEvent(f, "FORGE_MASTER_OPENED")
                delivered = true
            end
        end
    end

    _G.print = say
    local win
    for _, f in ipairs(frames) do
        if f._name == "WeintCodexReforgeWindow" then win = f end
    end
    return {
        delivered = delivered,
        shown     = (win and win._shown) or false,
        block     = RF.OpenBlock(),
        said      = table.concat(said, "\n"),
        RF        = RF,
    }
end

--== Pruefungen =============================================================
local failed = 0
local function check(name, ok, detail)
    say((ok and "  ok    " or "  FEHLT ") .. name .. (detail and ("  — " .. detail) or ""))
    if not ok then failed = failed + 1 end
end

say("Umschmieder-Fenster: geht es auf, und sagt es warum nicht?")

local r = run({})
check("alles an: das Fenster geht auf", r.shown and r.block == nil)

r = run({ enabled = false })
check("Planer aus: bleibt zu, mit Grund",
    (not r.shown) and r.block ~= nil and r.block.key == "off")
check("Planer aus: kein Chat", r.said == "",
    "ein Beta-Werkzeug, das an jedem Umschmieder von sich reden macht,"
    .. " ist der Grund, warum man Addons abschaltet")

r = run({ autoOpen = false })
check("'beim Umschmieder oeffnen' aus: bleibt zu, mit Grund",
    (not r.shown) and r.block ~= nil and r.block.key == "autoOpen")

r = run({ optIn = false })
check("Charakter sagt nein: bleibt zu, mit Grund",
    (not r.shown) and r.block ~= nil and r.block.key == "optIn")
-- DAS IST DER GEMELDETE FALL. Die Frage aus core/optin.lua wird je Charakter
-- gestellt, der Schalter gilt fuers ganze Konto — ein "nein" von vor drei
-- Wochen ueberstimmt also die Aktivierung von eben. Richtig ist das; lautlos
-- war es nicht.
check("Charakter sagt nein: es steht im Chat, mit beiden Auswegen",
    r.said:find("/wc hier", 1, true) ~= nil
    and r.said:find("/wc umschmieden fenster", 1, true) ~= nil)

r = run({ clientWithoutEvent = true })
check("Client ohne FORGE_MASTER_OPENED: Rueckfallweg meldet sich an",
    r.RF.UsesFrameFallback == true and r.delivered)
check("Client ohne FORGE_MASTER_OPENED: das Fenster geht trotzdem auf", r.shown)

r = run({})
check("Client mit dem Ereignis: KEIN zweiter Weg daneben",
    r.RF.UsesFrameFallback == false,
    "sonst ginge das Fenster zweimal auf")

say(failed == 0 and "\nAlles gruen." or ("\n" .. failed .. " Pruefung(en) fehlgeschlagen."))
os.exit(failed == 0 and 0 or 1)
