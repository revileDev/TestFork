--[[
    =============================================================================
    ATOMWARE RIVALS // FULL DEFENSIVE EMULATOR, INTEGRITY ENGINE & 3D SKIN CATALOG
    =============================================================================
    Architecture:
      • Module-based Singleton (Emulator.lua / emu.txt)
      • Challenge Callback Relaying & Sandboxed Resolution (LocalScript3)
      • MaterialService Pulse Heartbeat Engine (Anti-Idle / Token Keepalive)
      • Deep ItemLibrary.Items Hookfunction Call-Stack Trap Neutralizer
      • MiscellaneousController Watchdog Thread Purger
      • OutOfBoundsMachine Kill Boundary Suppressor
      • EnvironmentID & Multi-Tenancy Spatial Partition Telemetry (3000+ Arenas)
      • Staff / Testing Permissions Spoofer (PermissionsLibrary)
      • Full 3D Interactive Weapon Skin Catalog & Real-Time Viewmodel Injector
      • Live 3D ViewportFrame Weapon Preview with Dynamic Shading & Orbit Camera
    =============================================================================
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local MaterialService = game:GetService("MaterialService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end

-- =============================================================================
-- EXECUTOR COMPATIBILITY & SHIM LAYER
-- =============================================================================
local env = (typeof(getgenv) == "function" and getgenv()) or _G
local get_conns = getconnections or (type(debug) == "table" and (debug :: any).getconnections)
local hook_meta = hookmetamethod or (type(debug) == "table" and (debug :: any).hookmetamethod)
local set_raw_mt = setrawmetatable or (type(debug) == "table" and (debug :: any).setmetatable) or setmetatable
local get_gc = getgc or (type(debug) == "table" and (debug :: any).getgc)
local new_cclosure = newcclosure or function(f) return f end
local get_namecall = getnamecallmethod or function() return "" end
local protect_gui = (typeof(syn) == "table" and syn.protect_gui) or (typeof(protectgui) == "function" and protectgui)

if type(env.ATOMWARE_EMU_UNLOAD) == "function" then
    pcall(env.ATOMWARE_EMU_UNLOAD)
end

-- =============================================================================
-- CONFIGURATION & WEAPON CATALOG DATA
-- =============================================================================
local UNIVERSE_ID = 6035872082
local CALLBACK_TIMEOUT = 12
local MATERIAL_INTERVAL = 4
local MAX_CONSOLE_LOGS = 250
local TOGGLE_KEY = Enum.KeyCode.RightControl

local WEAPON_CATEGORIES = {
    Primary = {
        "Assault Rifle",
        "Sniper",
        "Shotgun",
        "Burst Rifle",
        "Minigun",
        "Energy Rifle",
        "Paintball Gun",
        "Exogun",
    },
    Secondary = {
        "Handgun",
        "Shorty",
        "Uzi",
        "BaseRevolver",
        "Energy Pistols",
        "BaseFlareGun",
    },
    Melee = {
        "Katana",
        "Knife",
        "Battle Axe",
        "Maul",
        "Gunblade",
        "Fists",
    },
    Utility = {
        "Grenade",
        "Flashbang",
        "Molotov",
        "Riot Shield",
        "Medkit",
    },
}

-- Curated high-fidelity catalog of wraps with exact metadata and primary/secondary colors
local CATALOG_WRAPS = {
    { Name = "Dark Matter", Rarity = "Mastery", Category = "MASTERY", Primary = Color3.fromRGB(18, 12, 28), Secondary = Color3.fromRGB(170, 75, 255) },
    { Name = "Diamond", Rarity = "Mastery", Category = "MASTERY", Primary = Color3.fromRGB(150, 225, 255), Secondary = Color3.fromRGB(220, 245, 255) },
    { Name = "Liquid Gold", Rarity = "Mastery", Category = "MASTERY", Primary = Color3.fromRGB(255, 205, 50), Secondary = Color3.fromRGB(180, 130, 20) },
    { Name = "Gold", Rarity = "Mastery", Category = "MASTERY", Primary = Color3.fromRGB(240, 190, 40), Secondary = Color3.fromRGB(120, 95, 20) },
    { Name = "Glacier", Rarity = "Unique", Category = "UNIQUE", Primary = Color3.fromRGB(175, 221, 255), Secondary = Color3.fromRGB(231, 231, 236) },
    { Name = "Danger", Rarity = "Unique", Category = "UNIQUE", Primary = Color3.fromRGB(168, 0, 0), Secondary = Color3.fromRGB(20, 20, 20) },
    { Name = "1B Visits", Rarity = "Unique", Category = "UNIQUE", Primary = Color3.fromRGB(48, 38, 0), Secondary = Color3.fromRGB(127, 100, 0) },
    { Name = "Community", Rarity = "Unique", Category = "UNIQUE", Primary = Color3.fromRGB(124, 17, 255), Secondary = Color3.fromRGB(255, 213, 0) },
    { Name = "Vexed", Rarity = "Unique", Category = "UNIQUE", Primary = Color3.fromRGB(30, 15, 45), Secondary = Color3.fromRGB(185, 40, 255) },
    { Name = "Brimstone", Rarity = "Unique", Category = "UNIQUE", Primary = Color3.fromRGB(25, 25, 25), Secondary = Color3.fromRGB(255, 65, 30) },
    { Name = "Glamour", Rarity = "Unique", Category = "UNIQUE", Primary = Color3.fromRGB(86, 36, 36), Secondary = Color3.fromRGB(255, 215, 120) },
    { Name = "Sensite", Rarity = "Unique", Category = "UNIQUE", Primary = Color3.fromRGB(255, 180, 30), Secondary = Color3.fromRGB(40, 40, 40) },
    { Name = "Nosnite", Rarity = "Unique", Category = "UNIQUE", Primary = Color3.fromRGB(180, 128, 255), Secondary = Color3.fromRGB(25, 20, 35) },
    { Name = "Shadore", Rarity = "Unique", Category = "UNIQUE", Primary = Color3.fromRGB(203, 51, 51), Secondary = Color3.fromRGB(35, 35, 35) },
    { Name = "Brianore", Rarity = "Unique", Category = "UNIQUE", Primary = Color3.fromRGB(101, 255, 93), Secondary = Color3.fromRGB(20, 40, 20) },
    { Name = "Cream", Rarity = "Unique", Category = "UNIQUE", Primary = Color3.fromRGB(255, 209, 157), Secondary = Color3.fromRGB(62, 55, 48) },
    { Name = "Pine", Rarity = "Unique", Category = "UNIQUE", Primary = Color3.fromRGB(58, 115, 55), Secondary = Color3.fromRGB(110, 75, 45) },
    { Name = "Beggar", Rarity = "Unique", Category = "UNIQUE", Primary = Color3.fromRGB(255, 176, 0), Secondary = Color3.fromRGB(50, 45, 30) },
    { Name = "Snowy Night", Rarity = "Rare", Category = "UNIQUE", Primary = Color3.fromRGB(20, 25, 45), Secondary = Color3.fromRGB(220, 235, 255) },
    { Name = "Red", Rarity = "Solid", Category = "SOLID", Primary = Color3.fromRGB(220, 35, 35), Secondary = Color3.fromRGB(40, 40, 40) },
    { Name = "Orange", Rarity = "Solid", Category = "SOLID", Primary = Color3.fromRGB(245, 130, 25), Secondary = Color3.fromRGB(40, 40, 40) },
    { Name = "Yellow", Rarity = "Solid", Category = "SOLID", Primary = Color3.fromRGB(245, 220, 30), Secondary = Color3.fromRGB(40, 40, 40) },
    { Name = "Green", Rarity = "Solid", Category = "SOLID", Primary = Color3.fromRGB(45, 200, 75), Secondary = Color3.fromRGB(40, 40, 40) },
    { Name = "Blue", Rarity = "Solid", Category = "SOLID", Primary = Color3.fromRGB(35, 125, 245), Secondary = Color3.fromRGB(40, 40, 40) },
    { Name = "Purple", Rarity = "Solid", Category = "SOLID", Primary = Color3.fromRGB(160, 45, 240), Secondary = Color3.fromRGB(40, 40, 40) },
    { Name = "Pink", Rarity = "Solid", Category = "SOLID", Primary = Color3.fromRGB(255, 105, 180), Secondary = Color3.fromRGB(40, 40, 40) },
    { Name = "Teal", Rarity = "Solid", Category = "SOLID", Primary = Color3.fromRGB(0, 180, 180), Secondary = Color3.fromRGB(40, 40, 40) },
    { Name = "Navy", Rarity = "Solid", Category = "SOLID", Primary = Color3.fromRGB(15, 30, 75), Secondary = Color3.fromRGB(40, 40, 40) },
    { Name = "Highlighter", Rarity = "Solid", Category = "SOLID", Primary = Color3.fromRGB(225, 255, 0), Secondary = Color3.fromRGB(30, 30, 30) },
    { Name = "Blush", Rarity = "Solid", Category = "SOLID", Primary = Color3.fromRGB(235, 160, 175), Secondary = Color3.fromRGB(40, 40, 40) },
}

local THEME = {
    Bg = Color3.fromRGB(13, 16, 24),
    Header = Color3.fromRGB(18, 23, 34),
    Sidebar = Color3.fromRGB(15, 19, 29),
    Border = Color3.fromRGB(32, 40, 60),
    CardBg = Color3.fromRGB(20, 26, 38),
    CardHover = Color3.fromRGB(26, 34, 50),
    ConsoleBg = Color3.fromRGB(9, 11, 17),
    
    TextPrimary = Color3.fromRGB(240, 245, 255),
    TextSecondary = Color3.fromRGB(165, 178, 202),
    TextMuted = Color3.fromRGB(105, 118, 142),
    
    AccentCyan = Color3.fromRGB(0, 210, 255),
    AccentGreen = Color3.fromRGB(50, 225, 130),
    AccentOrange = Color3.fromRGB(255, 170, 40),
    AccentRed = Color3.fromRGB(245, 75, 90),
    AccentPurple = Color3.fromRGB(170, 95, 255),
}

-- =============================================================================
-- EMULATOR STATE
-- =============================================================================
local Emulator = {}
local State = {
    started = false,
    active = false,
    startedAt = nil :: number?,
    
    challenge = nil :: RemoteEvent?,
    native = nil :: any,
    originalScript = nil :: LocalScript?,
    relayConnection = nil :: RBXScriptConnection?,
    heartbeatRunning = false,
    namecallHooked = false,
    previousNamecall = nil :: any,
    
    inbound = 0,
    invoked = 0,
    responses = 0,
    malformed = 0,
    errors = 0,
    lastLatency = -1,
    latencyHistory = {},
    lastChallengeAt = nil :: number?,
    lastResponseAt = nil :: number?,
    lastError = nil :: string?,
    
    materialRemote = nil :: RemoteEvent?,
    materialSent = 0,
    materialErrors = 0,
    lastMaterialAt = nil :: number?,
    
    itemLibraryDisarmed = false,
    outOfBoundsNeutralized = false,
    miscCancelled = 0,
    miscFound = 0,
    staffSpooferActive = false,
    currentEnvironmentID = 0,
    
    skinChanger = {
        enabled = false,
        selectedCategory = "Primary",
        selectedWeapon = "Assault Rifle",
        selectedWrap = "Dark Matter",
        inverted = false,
        unlockAllCosmetics = false,
        catalogFilter = "ALL",
        searchQuery = "",
        viewModelHooked = false,
    },
    
    logs = {},
    uiVisible = true,
    autoScroll = true,
    activeTab = "Console", -- "Console" | "Metrics" | "Skins" | "Controls"
    activeFilter = "ALL",  -- "ALL" | "CHALLENGE" | "HEARTBEAT" | "TRAP" | "SKINS" | "WARN"
}

local EventSignal = {}
EventSignal.__index = EventSignal
function EventSignal.new()
    return setmetatable({ _listeners = {} }, EventSignal)
end
function EventSignal:Connect(fn)
    table.insert(self._listeners, fn)
    return {
        Disconnect = function()
            local idx = table.find(self._listeners, fn)
            if idx then table.remove(self._listeners, idx) end
        end
    }
end
function EventSignal:Fire(...)
    for _, fn in ipairs(self._listeners) do
        task.spawn(fn, ...)
    end
end

local OnLogAdded = EventSignal.new()
local OnStateChanged = EventSignal.new()
local OnSkinChanged = EventSignal.new()

-- =============================================================================
-- LOGGING SUBSYSTEM
-- =============================================================================
local function formatTimestamp(t: number?): string
    local now = os.date("*t", t or os.time())
    return string.format("%02d:%02d:%02d", now.hour, now.min, now.sec)
end

function Emulator.log(level: string, tag: string, message: string)
    local entry = {
        time = os.clock(),
        timestamp = formatTimestamp(),
        level = level,
        tag = tag,
        message = message,
    }
    
    table.insert(State.logs, entry)
    if #State.logs > MAX_CONSOLE_LOGS then
        table.remove(State.logs, 1)
    end
    
    local line = string.format("[Atomware][%s][%s] %s", level, tag, message)
    if level == "WARN" then
        warn(line)
    elseif level == "ERROR" then
        warn("🛑 " .. line)
    else
        print(line)
    end
    
    OnLogAdded:Fire(entry)
end

-- =============================================================================
-- SKIN CHANGER & 3D VIEWMODEL HOOKS
-- =============================================================================

local function hookClientViewModel(): boolean
    local ok, ClientViewModel = pcall(function()
        local scripts = LocalPlayer:WaitForChild("PlayerScripts", 10)
        local modules = scripts:WaitForChild("Modules", 10)
        local crClasses = modules:WaitForChild("ClientReplicatedClasses", 10)
        local cFighter = crClasses:WaitForChild("ClientFighter", 10)
        local cItem = cFighter:WaitForChild("ClientItem", 10)
        return require(cItem:WaitForChild("ClientViewModel", 10))
    end)

    if ok and type(ClientViewModel) == "table" and type(ClientViewModel.GetWrap) == "function" then
        if not ClientViewModel._origGetWrap then
            ClientViewModel._origGetWrap = ClientViewModel.GetWrap
            ClientViewModel.GetWrap = function(self)
                if State.skinChanger.enabled and State.skinChanger.selectedWrap ~= "" then
                    return {
                        Name = State.skinChanger.selectedWrap,
                        Inverted = State.skinChanger.inverted,
                    }
                end
                return ClientViewModel._origGetWrap(self)
            end
            State.skinChanger.viewModelHooked = true
            Emulator.log("SKINS", "HOOK", "Hooked ClientViewModel.GetWrap; custom wrap pipeline active")
            return true
        end
    end
    return false
end

function Emulator.toggleUnlockAllCosmetics(enable: boolean): boolean
    local ok = pcall(function()
        local modules = ReplicatedStorage:WaitForChild("Modules", 8)
        if not modules then return end
        local CosmeticLibrary = require(modules:WaitForChild("CosmeticLibrary", 8))
        if CosmeticLibrary and type(CosmeticLibrary) == "table" then
            if enable then
                if not CosmeticLibrary._origOwnsCosmetic then
                    CosmeticLibrary._origOwnsCosmetic = CosmeticLibrary.OwnsCosmetic
                    CosmeticLibrary._origOwnsNormally = CosmeticLibrary.OwnsCosmeticNormally
                    CosmeticLibrary._origOwnsUniversally = CosmeticLibrary.OwnsCosmeticUniversally
                    CosmeticLibrary._origOwnsForWeapon = CosmeticLibrary.OwnsCosmeticForWeapon
                    CosmeticLibrary._origOwnsForSomething = CosmeticLibrary.OwnsCosmeticForSomething
                end

                CosmeticLibrary.OwnsCosmetic = function() return true end
                CosmeticLibrary.OwnsCosmeticNormally = function() return true end
                CosmeticLibrary.OwnsCosmeticUniversally = function() return true end
                CosmeticLibrary.OwnsCosmeticForWeapon = function() return true end
                CosmeticLibrary.OwnsCosmeticForSomething = function() return true end

                State.skinChanger.unlockAllCosmetics = true
                Emulator.log("SKINS", "UNLOCK", "All cosmetics (wraps, charms, skins) unlocked in UI")
            elseif CosmeticLibrary._origOwnsCosmetic then
                CosmeticLibrary.OwnsCosmetic = CosmeticLibrary._origOwnsCosmetic
                CosmeticLibrary.OwnsCosmeticNormally = CosmeticLibrary._origOwnsNormally
                CosmeticLibrary.OwnsCosmeticUniversally = CosmeticLibrary._origOwnsUniversally
                CosmeticLibrary.OwnsCosmeticForWeapon = CosmeticLibrary._origOwnsForWeapon
                CosmeticLibrary.OwnsCosmeticForSomething = CosmeticLibrary._origOwnsForSomething

                State.skinChanger.unlockAllCosmetics = false
                Emulator.log("SKINS", "UNLOCK", "Cosmetic ownership restored to default")
            end
        end
    end)
    OnStateChanged:Fire()
    return ok
end

function Emulator.applySkinNow()
    pcall(function()
        local scripts = LocalPlayer:FindFirstChild("PlayerScripts")
        local controllers = scripts and scripts:FindFirstChild("Controllers")
        local FighterController = controllers and require(controllers:FindFirstChild("FighterController"))
        if FighterController then
            for _, fighter in pairs(FighterController.Fighters or {}) do
                if fighter.IsLocalPlayer then
                    for _, item in pairs(fighter.Items or {}) do
                        if item.ViewModel and type(item.ViewModel._UpdateWrap) == "function" then
                            item.ViewModel:_UpdateWrap()
                        end
                    end
                end
            end
        end
    end)
    Emulator.log("SKINS", "APPLY", string.format("Applied '%s' (Inverted: %s) to %s", State.skinChanger.selectedWrap, tostring(State.skinChanger.inverted), State.skinChanger.selectedWeapon))
    OnStateChanged:Fire()
    OnSkinChanged:Fire()
end

function Emulator.setWrap(wrapName: string, inverted: boolean?)
    State.skinChanger.selectedWrap = wrapName
    if inverted ~= nil then
        State.skinChanger.inverted = inverted
    end
    if State.skinChanger.enabled then
        Emulator.applySkinNow()
    else
        OnSkinChanged:Fire()
    end
end

function Emulator.setWeapon(weaponName: string)
    State.skinChanger.selectedWeapon = weaponName
    OnSkinChanged:Fire()
end

-- =============================================================================
-- CORE OVERHAULED HOOKS & DISARMERS
-- =============================================================================

local function getRemoteEvents(container: Instance): { RemoteEvent }
    local list: { RemoteEvent } = {}
    for _, item in ipairs(container:GetDescendants()) do
        if item:IsA("RemoteEvent") then
            table.insert(list, item)
        end
    end
    return list
end

local function sourceMatches(callback: any, needle: string): boolean
    local ok, source = pcall(debug.info, callback, "s")
    return ok and type(source) == "string" and source:gsub("%s+", ""):find(needle, 1, true) ~= nil
end

local function findChallenge(remotes: Instance): (RemoteEvent?, any)
    local deadline = os.clock() + CALLBACK_TIMEOUT
    repeat
        local challenge: RemoteEvent? = nil
        local native: any = nil

        if type(get_conns) == "function" then
            for _, candidate in ipairs(getRemoteEvents(remotes)) do
                local okConns, conns = pcall(get_conns, candidate.OnClientEvent)
                if okConns and type(conns) == "table" then
                    for _, connection in ipairs(conns) do
                        local callback = connection.Function
                        if type(callback) == "function" and sourceMatches(callback, "LocalScript3") then
                            challenge = candidate
                            native = connection
                            break
                        end
                    end
                end
                if native then break end
            end
        end

        if challenge and native then
            return challenge, native
        end
        task.wait(0.2)
    until os.clock() >= deadline
    return nil, nil
end

function Emulator.disarmItemLibraryTrap(): boolean
    local ok, result = pcall(function()
        local modules = ReplicatedStorage:WaitForChild("Modules", 8)
        if not modules then return false end
        
        local ItemLibrary = require(modules:WaitForChild("ItemLibrary", 8))
        if not ItemLibrary or type(ItemLibrary) ~= "table" or type(ItemLibrary.Items) ~= "table" then
            return false
        end

        local cleanMt = {
            __index = function(t, k)
                return rawget(t, k)
            end,
            __newindex = function(t, k, v)
                rawset(t, k, v)
            end,
        }

        local replaced = false
        if type(set_raw_mt) == "function" then
            replaced = pcall(set_raw_mt, ItemLibrary.Items, cleanMt)
        end

        if not replaced then
            local cleanItems = {}
            for k, v in pairs(ItemLibrary.Items) do
                rawset(cleanItems, k, v)
            end
            ItemLibrary.Items = setmetatable(cleanItems, cleanMt)
            replaced = true
        end

        return replaced
    end)

    if ok and result then
        State.itemLibraryDisarmed = true
        Emulator.log("TRAP", "ITEM_LIBRARY", "Disarmed ItemLibrary.Items 8-level getfenv hookfunction hang trap")
        OnStateChanged:Fire()
        return true
    else
        Emulator.log("WARN", "ITEM_LIBRARY", "ItemLibrary trap disarm deferred or unavailable")
        return false
    end
end

function Emulator.neutralizeOutOfBounds(): boolean
    local ok = pcall(function()
        local modules = ReplicatedStorage:WaitForChild("Modules", 8)
        if not modules then return end
        local OOB = require(modules:WaitForChild("OutOfBoundsMachine", 8))
        if OOB and type(OOB) == "table" then
            if type(OOB.IsOutOfBounds) == "function" then
                OOB.IsOutOfBounds = function() return false end
            end
            if type(OOB._CheckKill) == "function" then
                OOB._CheckKill = function() return false end
            end
            State.outOfBoundsNeutralized = true
            Emulator.log("TRAP", "OUT_OF_BOUNDS", "Neutralized OutOfBounds kill triggers (arena safe)")
            OnStateChanged:Fire()
        end
    end)
    return ok
end

local function purgeMiscWatchdogs()
    if type(get_gc) ~= "function" then
        Emulator.log("WARN", "WATCHDOG", "getgc unavailable; skipping watchdog thread cancellation")
        return
    end

    local okGc, objects = pcall(get_gc, true)
    if not okGc or type(objects) ~= "table" then
        okGc, objects = pcall(get_gc)
    end
    if not okGc or type(objects) ~= "table" then return end

    local targets: { thread } = {}
    for _, item in ipairs(objects) do
        if type(item) == "thread" and coroutine.status(item) == "suspended" then
            for level = 1, 24 do
                local ok, src = pcall(debug.info, item, level, "s")
                if not ok or not src then break end
                if type(src) == "string" and src:find("MiscellaneousController", 1, true) then
                    table.insert(targets, item)
                    break
                end
            end
        end
    end

    State.miscFound = #targets
    local cancelled = 0
    for _, th in ipairs(targets) do
        local ok = pcall(task.cancel, th)
        if not ok then ok = pcall(coroutine.close, th) end
        if ok then cancelled += 1 end
    end

    State.miscCancelled += cancelled
    if cancelled > 0 then
        Emulator.log("TRAP", "WATCHDOG", string.format("Purged %d MiscellaneousController background watchdog threads", cancelled))
        OnStateChanged:Fire()
    end
end

function Emulator.applyStaffPermSpoofer(enable: boolean): boolean
    local ok = pcall(function()
        local modules = ReplicatedStorage:WaitForChild("Modules", 8)
        if not modules then return end
        local PermissionsLibrary = require(modules:WaitForChild("PermissionsLibrary", 8))
        local CONSTANTS = require(modules:WaitForChild("CONSTANTS", 8))

        if PermissionsLibrary and type(PermissionsLibrary) == "table" then
            if enable then
                PermissionsLibrary.ALWAYS_AUTHORIZED_TO_USE_COMMANDS = true
                PermissionsLibrary.ALWAYS_HAS_PERMISSION = true
                if not PermissionsLibrary._origIsAdmin then
                    PermissionsLibrary._origIsAdmin = PermissionsLibrary.IsAdministrator
                    PermissionsLibrary._origHasPerm = PermissionsLibrary.HasPermission
                    PermissionsLibrary._origCanView = PermissionsLibrary.CanViewPermissionsPage
                    PermissionsLibrary._origCanManage = PermissionsLibrary.CanManageRole
                end

                PermissionsLibrary.IsAdministrator = function() return true end
                PermissionsLibrary.HasPermission = function() return true end
                PermissionsLibrary.CanViewPermissionsPage = function() return true end
                PermissionsLibrary.CanManageRole = function() return true end
                State.staffSpooferActive = true
                Emulator.log("INFO", "SPOOFER", "Enabled Staff / Developer admin permissions emulation")
            elseif PermissionsLibrary._origIsAdmin then
                PermissionsLibrary.IsAdministrator = PermissionsLibrary._origIsAdmin
                PermissionsLibrary.HasPermission = PermissionsLibrary._origHasPerm
                PermissionsLibrary.CanViewPermissionsPage = PermissionsLibrary._origCanView
                PermissionsLibrary.CanManageRole = PermissionsLibrary._origCanManage
                PermissionsLibrary.ALWAYS_AUTHORIZED_TO_USE_COMMANDS = false
                PermissionsLibrary.ALWAYS_HAS_PERMISSION = false
                State.staffSpooferActive = false
                Emulator.log("INFO", "SPOOFER", "Reverted Staff permissions emulation to default")
            end
        end

        if CONSTANTS and type(CONSTANTS) == "table" then
            CONSTANTS.IS_STUDIO = enable
            CONSTANTS.IS_TESTING_SERVER = enable
        end
    end)
    OnStateChanged:Fire()
    return ok
end

local function startMaterialHeartbeat(materialRemote: RemoteEvent)
    if State.heartbeatRunning then return end
    State.heartbeatRunning = true
    State.materialRemote = materialRemote

    task.spawn(function()
        while State.active and State.started do
            local pulseStart = os.clock()
            local ok, err = pcall(function()
                materialRemote:FireServer("", nil, nil)
            end)

            if ok then
                State.materialSent += 1
                State.lastMaterialAt = pulseStart
                if State.materialSent == 1 or State.materialSent % 15 == 0 then
                    Emulator.log("HEARTBEAT", "MATERIAL", string.format("Pulse #%d verified & acknowledged", State.materialSent))
                end
            else
                State.materialErrors += 1
                State.lastError = tostring(err)
                Emulator.log("WARN", "MATERIAL", string.format("Pulse failed: %s", tostring(err)))
            end

            OnStateChanged:Fire()
            task.wait(MATERIAL_INTERVAL)
        end
        State.heartbeatRunning = false
    end)
end

local function observeResponses(challenge: RemoteEvent)
    if State.namecallHooked or type(hook_meta) ~= "function" then return end

    local previousNamecall: any
    previousNamecall = hook_meta(game, "__namecall", new_cclosure(function(self, ...)
        if State.active and self == challenge and get_namecall() == "FireServer" then
            local args = table.pack(...)
            local packet = args[1]
            if args.n >= 3 and type(packet) == "table" then
                State.responses += 1
                State.lastResponseAt = os.clock()
                local latency = State.lastChallengeAt
                    and math.floor((State.lastResponseAt - State.lastChallengeAt) * 1000 + 0.5)
                    or -1
                State.lastLatency = latency
                table.insert(State.latencyHistory, latency)
                if #State.latencyHistory > 30 then
                    table.remove(State.latencyHistory, 1)
                end
                Emulator.log("CHALLENGE", "OUTBOUND", string.format("Packet #%d dispatched (Latency: %d ms)", State.responses, latency))
                OnStateChanged:Fire()
            else
                State.malformed += 1
                Emulator.log("WARN", "OUTBOUND", string.format("Unusual challenge response shape; args=%d", args.n))
            end
        end
        return previousNamecall(self, ...)
    end))

    State.namecallHooked = true
    State.previousNamecall = previousNamecall
end

local function attachRelay(challenge: RemoteEvent, native: any): boolean
    local solve = native.Function
    if type(solve) ~= "function" then
        Emulator.log("ERROR", "RELAY", "Native connection callback is not callable")
        return false
    end

    if State.relayConnection then
        pcall(function() State.relayConnection:Disconnect() end)
        State.relayConnection = nil
    end

    local relay: RBXScriptConnection
    relay = challenge.OnClientEvent:Connect(function(...)
        State.inbound += 1
        State.lastChallengeAt = os.clock()
        Emulator.log("CHALLENGE", "INBOUND", string.format("Challenge #%d received from server", State.inbound))

        local args = table.pack(...)
        local ok, err = pcall(function()
            solve(table.unpack(args, 1, args.n))
        end)

        if ok then
            State.invoked += 1
            Emulator.log("CHALLENGE", "SOLVED", string.format("Challenge #%d solved successfully", State.invoked))
        else
            State.errors += 1
            State.lastError = tostring(err)
            Emulator.log("ERROR", "CHALLENGE", string.format("Callback error: %s", tostring(err)))
            State.active = false
            pcall(function() relay:Disconnect() end)
            if type(native.Enable) == "function" then pcall(native.Enable, native) end
            pcall(function() native.Enabled = true end)
            if State.originalScript then pcall(function() State.originalScript.Enabled = true end) end
            Emulator.log("WARN", "FALLBACK", "Restored native challenge callback following error")
        end
        OnStateChanged:Fire()
    end)

    State.relayConnection = relay

    if type(native.Disable) == "function" then pcall(native.Disable, native) end
    pcall(function() native.Enabled = false end)
    if State.originalScript then pcall(function() State.originalScript.Enabled = false end) end
    State.active = true

    Emulator.log("INFO", "RELAY", "Attached sandboxed relay to challenge RemoteEvent; native connection detached")
    return true
end

local function monitorEnvironment()
    task.spawn(function()
        while State.started do
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    local envAttr = char:GetAttribute("EnvironmentID")
                    if envAttr and envAttr ~= State.currentEnvironmentID then
                        State.currentEnvironmentID = envAttr
                        Emulator.log("INFO", "ENV", string.format("Environment partition shifted -> %d", envAttr))
                        OnStateChanged:Fire()
                    end
                end
            end)
            task.wait(2)
        end
    end)
end

-- =============================================================================
-- USER INTERFACE SUBSYSTEM (RICH CONSOLE, 3D CATALOG & DIAGNOSTICS)
-- =============================================================================
local UI = {
    ScreenGui = nil,
    MainFrame = nil,
    ConsoleContainer = nil,
    MetricsContainer = nil,
    SkinsContainer = nil,
    ControlsContainer = nil,
    LogScroller = nil,
    StatusBadge = nil,
    LatencyPill = nil,
    PillWidget = nil,
    
    Viewport = nil,
    ViewportCamera = nil,
    PreviewModel = nil,
    PreviewGunLabel = nil,
    PreviewSkinLabel = nil,
    CatalogScroller = nil,
}

local function buildUI()
    local function getGuiParent(): Instance
        local get_hui = gethui or (type(debug) == "table" and (debug :: any).gethui)
        if type(get_hui) == "function" then
            local ok, hui = pcall(get_hui)
            if ok and hui then return hui end
        end
        return CoreGui:FindFirstChild("RobloxGui") or CoreGui
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AtomwareEmulatorUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    if typeof(protect_gui) == "function" then
        pcall(protect_gui, ScreenGui)
    end
    ScreenGui.Parent = getGuiParent()
    UI.ScreenGui = ScreenGui

    local function corner(inst: Instance, r: number?): UICorner
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, r or 6)
        c.Parent = inst
        return c
    end

    local function stroke(inst: Instance, color: Color3?, thickness: number?): UIStroke
        local s = Instance.new("UIStroke")
        s.Color = color or THEME.Border
        s.Thickness = thickness or 1
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        s.Parent = inst
        return s
    end

    -- -------------------------------------------------------------------------
    -- Main Window
    -- -------------------------------------------------------------------------
    local Main = Instance.new("Frame")
    Main.Name = "MainFrame"
    Main.Size = UDim2.new(0, 760, 0, 460)
    Main.Position = UDim2.new(0.5, -380, 0.5, -230)
    Main.BackgroundColor3 = THEME.Bg
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = true
    Main.Parent = ScreenGui
    corner(Main, 8)
    stroke(Main, THEME.Border, 1)
    UI.MainFrame = Main

    -- -------------------------------------------------------------------------
    -- Header Bar
    -- -------------------------------------------------------------------------
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 46)
    Header.BackgroundColor3 = THEME.Header
    Header.BorderSizePixel = 0
    Header.Parent = Main
    corner(Header, 8)
    stroke(Header, THEME.Border, 1)

    local dragging = false
    local dragStart, startPos
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local Title = Instance.new("TextLabel")
    Title.Text = "ATOMWARE // RIVALS EMULATOR"
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 13
    Title.TextColor3 = THEME.TextPrimary
    Title.Position = UDim2.new(0, 16, 0, 14)
    Title.Size = UDim2.new(0, 240, 0, 18)
    Title.BackgroundTransparency = 1
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Header

    local StatusBadge = Instance.new("TextLabel")
    StatusBadge.Name = "StatusBadge"
    StatusBadge.Text = "● ACTIVE"
    StatusBadge.Font = Enum.Font.GothamBold
    StatusBadge.TextSize = 10
    StatusBadge.TextColor3 = THEME.AccentGreen
    StatusBadge.BackgroundColor3 = Color3.fromRGB(15, 35, 25)
    StatusBadge.Position = UDim2.new(0, 265, 0, 13)
    StatusBadge.Size = UDim2.new(0, 74, 0, 20)
    StatusBadge.Parent = Header
    corner(StatusBadge, 4)
    stroke(StatusBadge, Color3.fromRGB(30, 80, 50), 1)
    UI.StatusBadge = StatusBadge

    local LatencyPill = Instance.new("TextLabel")
    LatencyPill.Name = "LatencyPill"
    LatencyPill.Text = "LATENCY: -- ms"
    LatencyPill.Font = Enum.Font.Gotham
    LatencyPill.TextSize = 10
    LatencyPill.TextColor3 = THEME.TextSecondary
    LatencyPill.BackgroundColor3 = THEME.CardBg
    LatencyPill.Position = UDim2.new(0, 348, 0, 13)
    LatencyPill.Size = UDim2.new(0, 105, 0, 20)
    LatencyPill.Parent = Header
    corner(LatencyPill, 4)
    stroke(LatencyPill, THEME.Border, 1)
    UI.LatencyPill = LatencyPill

    local MinBtn = Instance.new("TextButton")
    MinBtn.Text = "—"
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.TextSize = 13
    MinBtn.TextColor3 = THEME.TextSecondary
    MinBtn.BackgroundColor3 = THEME.CardBg
    MinBtn.Position = UDim2.new(1, -74, 0, 11)
    MinBtn.Size = UDim2.new(0, 28, 0, 24)
    MinBtn.Parent = Header
    corner(MinBtn, 4)
    stroke(MinBtn, THEME.Border, 1)

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Text = "✕"
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 11
    CloseBtn.TextColor3 = THEME.AccentRed
    CloseBtn.BackgroundColor3 = Color3.fromRGB(35, 18, 24)
    CloseBtn.Position = UDim2.new(1, -38, 0, 11)
    CloseBtn.Size = UDim2.new(0, 28, 0, 24)
    CloseBtn.Parent = Header
    corner(CloseBtn, 4)
    stroke(CloseBtn, Color3.fromRGB(70, 25, 35), 1)

    -- -------------------------------------------------------------------------
    -- Tab Selector Bar
    -- -------------------------------------------------------------------------
    local TabBar = Instance.new("Frame")
    TabBar.Name = "TabBar"
    TabBar.Size = UDim2.new(1, 0, 0, 36)
    TabBar.Position = UDim2.new(0, 0, 0, 46)
    TabBar.BackgroundColor3 = THEME.Sidebar
    TabBar.BorderSizePixel = 0
    TabBar.Parent = Main

    local function createTabButton(text: string, pos: number, id: string): TextButton
        local btn = Instance.new("TextButton")
        btn.Text = text
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.TextColor3 = (State.activeTab == id) and THEME.AccentCyan or THEME.TextMuted
        btn.BackgroundColor3 = (State.activeTab == id) and THEME.CardBg or Color3.fromRGB(0, 0, 0)
        btn.BackgroundTransparency = (State.activeTab == id) and 0 or 1
        btn.Position = UDim2.new(0, 16 + (pos * 105), 0, 6)
        btn.Size = UDim2.new(0, 96, 0, 24)
        btn.Parent = TabBar
        corner(btn, 4)
        if State.activeTab == id then stroke(btn, THEME.Border, 1) end
        return btn
    end

    local TabConsole = createTabButton("CONSOLE", 0, "Console")
    local TabMetrics = createTabButton("METRICS", 1, "Metrics")
    local TabSkins = createTabButton("SKIN CATALOG", 2, "Skins")
    local TabControls = createTabButton("CONTROLS", 3, "Controls")

    -- -------------------------------------------------------------------------
    -- Body Content Containers
    -- -------------------------------------------------------------------------
    local Body = Instance.new("Frame")
    Body.Name = "Body"
    Body.Size = UDim2.new(1, -24, 1, -94)
    Body.Position = UDim2.new(0, 12, 0, 88)
    Body.BackgroundTransparency = 1
    Body.Parent = Main

    -- 1. CONSOLE TAB
    local ConsoleFrame = Instance.new("Frame")
    ConsoleFrame.Name = "ConsoleFrame"
    ConsoleFrame.Size = UDim2.new(1, 0, 1, 0)
    ConsoleFrame.BackgroundTransparency = 1
    ConsoleFrame.Parent = Body
    UI.ConsoleContainer = ConsoleFrame

    local Toolbar = Instance.new("Frame")
    Toolbar.Size = UDim2.new(1, 0, 0, 28)
    Toolbar.BackgroundTransparency = 1
    Toolbar.Parent = ConsoleFrame

    local function createFilterPill(name: string, filterId: string, xPos: number): TextButton
        local pill = Instance.new("TextButton")
        pill.Text = name
        pill.Font = Enum.Font.Gotham
        pill.TextSize = 10
        pill.TextColor3 = (State.activeFilter == filterId) and THEME.AccentCyan or THEME.TextMuted
        pill.BackgroundColor3 = (State.activeFilter == filterId) and THEME.CardBg or THEME.Bg
        pill.Position = UDim2.new(0, xPos, 0, 2)
        pill.Size = UDim2.new(0, 64, 0, 22)
        pill.Parent = Toolbar
        corner(pill, 4)
        stroke(pill, THEME.Border, 1)

        pill.MouseButton1Click:Connect(function()
            State.activeFilter = filterId
            for _, child in ipairs(Toolbar:GetChildren()) do
                if child:IsA("TextButton") and child.Name:find("Filter_") then
                    local isThis = (child == pill)
                    child.TextColor3 = isThis and THEME.AccentCyan or THEME.TextMuted
                    child.BackgroundColor3 = isThis and THEME.CardBg or THEME.Bg
                end
            end
            Emulator.refreshConsoleLogs()
        end)
        pill.Name = "Filter_" .. filterId
        return pill
    end

    createFilterPill("ALL", "ALL", 0)
    createFilterPill("CHALLENGES", "CHALLENGE", 68)
    createFilterPill("HEARTBEAT", "HEARTBEAT", 136)
    createFilterPill("SKINS", "SKINS", 204)
    createFilterPill("TRAPS", "TRAP", 272)
    createFilterPill("WARNINGS", "WARN", 340)

    local ClearBtn = Instance.new("TextButton")
    ClearBtn.Text = "CLEAR"
    ClearBtn.Font = Enum.Font.GothamBold
    ClearBtn.TextSize = 10
    ClearBtn.TextColor3 = THEME.TextSecondary
    ClearBtn.BackgroundColor3 = THEME.CardBg
    ClearBtn.Position = UDim2.new(1, -64, 0, 2)
    ClearBtn.Size = UDim2.new(0, 60, 0, 22)
    ClearBtn.Parent = Toolbar
    corner(ClearBtn, 4)
    stroke(ClearBtn, THEME.Border, 1)
    ClearBtn.MouseButton1Click:Connect(function()
        table.clear(State.logs)
        Emulator.refreshConsoleLogs()
    end)

    local AutoScrollBtn = Instance.new("TextButton")
    AutoScrollBtn.Text = "AUTO-SCROLL: ON"
    AutoScrollBtn.Font = Enum.Font.Gotham
    AutoScrollBtn.TextSize = 9
    AutoScrollBtn.TextColor3 = THEME.AccentGreen
    AutoScrollBtn.BackgroundColor3 = THEME.CardBg
    AutoScrollBtn.Position = UDim2.new(1, -172, 0, 2)
    AutoScrollBtn.Size = UDim2.new(0, 102, 0, 22)
    AutoScrollBtn.Parent = Toolbar
    corner(AutoScrollBtn, 4)
    stroke(AutoScrollBtn, THEME.Border, 1)
    AutoScrollBtn.MouseButton1Click:Connect(function()
        State.autoScroll = not State.autoScroll
        AutoScrollBtn.Text = "AUTO-SCROLL: " .. (State.autoScroll and "ON" or "OFF")
        AutoScrollBtn.TextColor3 = State.autoScroll and THEME.AccentGreen or THEME.TextMuted
    end)

    local Scroller = Instance.new("ScrollingFrame")
    Scroller.Name = "LogScroller"
    Scroller.Size = UDim2.new(1, 0, 1, -34)
    Scroller.Position = UDim2.new(0, 0, 0, 34)
    Scroller.BackgroundColor3 = THEME.ConsoleBg
    Scroller.BorderSizePixel = 0
    Scroller.ScrollBarThickness = 4
    Scroller.ScrollBarImageColor3 = THEME.Border
    Scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
    Scroller.Parent = ConsoleFrame
    corner(Scroller, 6)
    stroke(Scroller, THEME.Border, 1)
    UI.LogScroller = Scroller

    local LogLayout = Instance.new("UIListLayout")
    LogLayout.Padding = UDim.new(0, 2)
    LogLayout.SortOrder = Enum.SortOrder.LayoutOrder
    LogLayout.Parent = Scroller

    local LogPadding = Instance.new("UIPadding")
    LogPadding.PaddingLeft = UDim.new(0, 8)
    LogPadding.PaddingRight = UDim.new(0, 8)
    LogPadding.PaddingTop = UDim.new(0, 6)
    LogPadding.PaddingBottom = UDim.new(0, 6)
    LogPadding.Parent = Scroller

    -- 2. METRICS TAB
    local MetricsFrame = Instance.new("Frame")
    MetricsFrame.Name = "MetricsFrame"
    MetricsFrame.Size = UDim2.new(1, 0, 1, 0)
    MetricsFrame.BackgroundTransparency = 1
    MetricsFrame.Visible = false
    MetricsFrame.Parent = Body
    UI.MetricsContainer = MetricsFrame

    local MetricsGrid = Instance.new("UIGridLayout")
    MetricsGrid.CellSize = UDim2.new(0, 230, 0, 100)
    MetricsGrid.CellPadding = UDim2.new(0, 12, 0, 12)
    MetricsGrid.SortOrder = Enum.SortOrder.LayoutOrder
    MetricsGrid.Parent = MetricsFrame

    local function createMetricCard(name: string, value: string, sub: string, color: Color3?): Frame
        local card = Instance.new("Frame")
        card.BackgroundColor3 = THEME.CardBg
        corner(card, 6)
        stroke(card, THEME.Border, 1)

        local title = Instance.new("TextLabel")
        title.Text = name:upper()
        title.Font = Enum.Font.GothamBold
        title.TextSize = 10
        title.TextColor3 = THEME.TextMuted
        title.Position = UDim2.new(0, 12, 0, 10)
        title.Size = UDim2.new(1, -24, 0, 14)
        title.BackgroundTransparency = 1
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = card

        local val = Instance.new("TextLabel")
        val.Name = "ValueLabel"
        val.Text = value
        val.Font = Enum.Font.GothamBold
        val.TextSize = 20
        val.TextColor3 = color or THEME.TextPrimary
        val.Position = UDim2.new(0, 12, 0, 28)
        val.Size = UDim2.new(1, -24, 0, 28)
        val.BackgroundTransparency = 1
        val.TextXAlignment = Enum.TextXAlignment.Left
        val.Parent = card

        local desc = Instance.new("TextLabel")
        desc.Name = "SubLabel"
        desc.Text = sub
        desc.Font = Enum.Font.Gotham
        desc.TextSize = 10
        desc.TextColor3 = THEME.TextSecondary
        desc.Position = UDim2.new(0, 12, 0, 64)
        desc.Size = UDim2.new(1, -24, 0, 16)
        desc.BackgroundTransparency = 1
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.Parent = card

        return card
    end

    local CardChallenges = createMetricCard("Challenges Solved", "0", "Inbound: 0 | Errors: 0", THEME.AccentCyan)
    CardChallenges.Name = "Card_Challenges"
    CardChallenges.Parent = MetricsFrame

    local CardHeartbeat = createMetricCard("Material Heartbeat", "0 Pulses", "Interval: 4s | Errors: 0", THEME.AccentGreen)
    CardHeartbeat.Name = "Card_Heartbeat"
    CardHeartbeat.Parent = MetricsFrame

    local CardEnvironment = createMetricCard("Environment Partition", "0 (LOBBY)", "Duel/Range Multi-Tenancy", THEME.AccentPurple)
    CardEnvironment.Name = "Card_Environment"
    CardEnvironment.Parent = MetricsFrame

    local CardItemTrap = createMetricCard("ItemLibrary Trap", "DISARMED", "8-Level getfenv hook disarmed", THEME.AccentOrange)
    CardItemTrap.Name = "Card_ItemTrap"
    CardItemTrap.Parent = MetricsFrame

    local CardOOB = createMetricCard("OutOfBounds State", "NEUTRALIZED", "Anti-Kill boundary active", THEME.AccentCyan)
    CardOOB.Name = "Card_OOB"
    CardOOB.Parent = MetricsFrame

    local CardWatchdogs = createMetricCard("Watchdogs Neutralized", "0 Threads", "MiscController threads purged", THEME.AccentGreen)
    CardWatchdogs.Name = "Card_Watchdogs"
    CardWatchdogs.Parent = MetricsFrame

    -- 3. SKINS & 3D WEAPON CATALOG TAB
    local SkinsFrame = Instance.new("Frame")
    SkinsFrame.Name = "SkinsFrame"
    SkinsFrame.Size = UDim2.new(1, 0, 1, 0)
    SkinsFrame.BackgroundTransparency = 1
    SkinsFrame.Visible = false
    SkinsFrame.Parent = Body
    UI.SkinsContainer = SkinsFrame

    -- Left Pane: 3D Gun Preview & Weapon Selector
    local SkinLeft = Instance.new("Frame")
    SkinLeft.Size = UDim2.new(0, 275, 1, 0)
    SkinLeft.BackgroundColor3 = THEME.CardBg
    SkinLeft.Parent = SkinsFrame
    corner(SkinLeft, 6)
    stroke(SkinLeft, THEME.Border, 1)

    -- 3D ViewportFrame Card
    local PreviewCard = Instance.new("Frame")
    PreviewCard.Size = UDim2.new(1, -20, 0, 160)
    PreviewCard.Position = UDim2.new(0, 10, 0, 10)
    PreviewCard.BackgroundColor3 = THEME.ConsoleBg
    PreviewCard.Parent = SkinLeft
    corner(PreviewCard, 6)
    stroke(PreviewCard, THEME.Border, 1)

    local Viewport = Instance.new("ViewportFrame")
    Viewport.Size = UDim2.new(1, 0, 1, 0)
    Viewport.BackgroundTransparency = 1
    Viewport.Parent = PreviewCard
    UI.Viewport = Viewport

    local ViewportCam = Instance.new("Camera")
    ViewportCam.FieldOfView = 28
    Viewport.CurrentCamera = ViewportCam
    ViewportCam.Parent = Viewport
    UI.ViewportCamera = ViewportCam

    local PreviewGunLabel = Instance.new("TextLabel")
    PreviewGunLabel.Text = State.skinChanger.selectedWeapon:upper()
    PreviewGunLabel.Font = Enum.Font.GothamBold
    PreviewGunLabel.TextSize = 10
    PreviewGunLabel.TextColor3 = THEME.TextPrimary
    PreviewGunLabel.Position = UDim2.new(0, 8, 0, 8)
    PreviewGunLabel.Size = UDim2.new(1, -16, 0, 14)
    PreviewGunLabel.BackgroundTransparency = 1
    PreviewGunLabel.TextXAlignment = Enum.TextXAlignment.Left
    PreviewGunLabel.Parent = PreviewCard
    UI.PreviewGunLabel = PreviewGunLabel

    local PreviewSkinLabel = Instance.new("TextLabel")
    PreviewSkinLabel.Text = "WRAP: " .. State.skinChanger.selectedWrap:upper()
    PreviewSkinLabel.Font = Enum.Font.Gotham
    PreviewSkinLabel.TextSize = 9
    PreviewSkinLabel.TextColor3 = THEME.AccentCyan
    PreviewSkinLabel.Position = UDim2.new(0, 8, 0, 24)
    PreviewSkinLabel.Size = UDim2.new(1, -16, 0, 14)
    PreviewSkinLabel.BackgroundTransparency = 1
    PreviewSkinLabel.TextXAlignment = Enum.TextXAlignment.Left
    PreviewSkinLabel.Parent = PreviewCard
    UI.PreviewSkinLabel = PreviewSkinLabel

    -- Weapon Category Switcher
    local CatBar = Instance.new("Frame")
    CatBar.Size = UDim2.new(1, -20, 0, 24)
    CatBar.Position = UDim2.new(0, 10, 0, 178)
    CatBar.BackgroundTransparency = 1
    CatBar.Parent = SkinLeft

    local catButtons = {}
    local function createCategoryTab(name: string, pos: number)
        local btn = Instance.new("TextButton")
        btn.Text = name:upper()
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 9
        btn.TextColor3 = (State.skinChanger.selectedCategory == name) and THEME.AccentCyan or THEME.TextMuted
        btn.BackgroundColor3 = (State.skinChanger.selectedCategory == name) and THEME.CardHover or THEME.Bg
        btn.Position = UDim2.new(0, pos * 64, 0, 0)
        btn.Size = UDim2.new(0, 60, 1, 0)
        btn.Parent = CatBar
        corner(btn, 4)
        stroke(btn, THEME.Border, 1)

        btn.MouseButton1Click:Connect(function()
            State.skinChanger.selectedCategory = name
            local firstWep = WEAPON_CATEGORIES[name][1]
            if firstWep then
                Emulator.setWeapon(firstWep)
            end
            for catName, b in pairs(catButtons) do
                local isCur = (catName == name)
                b.TextColor3 = isCur and THEME.AccentCyan or THEME.TextMuted
                b.BackgroundColor3 = isCur and THEME.CardHover or THEME.Bg
            end
            Emulator.refreshWeaponList()
        end)
        catButtons[name] = btn
    end

    createCategoryTab("Primary", 0)
    createCategoryTab("Secondary", 1)
    createCategoryTab("Melee", 2)
    createCategoryTab("Utility", 3)

    -- Weapon List Scroller
    local WepScroller = Instance.new("ScrollingFrame")
    WepScroller.Name = "WeaponScroller"
    WepScroller.Size = UDim2.new(1, -20, 0, 68)
    WepScroller.Position = UDim2.new(0, 10, 0, 208)
    WepScroller.BackgroundColor3 = THEME.ConsoleBg
    WepScroller.BorderSizePixel = 0
    WepScroller.ScrollBarThickness = 3
    WepScroller.ScrollBarImageColor3 = THEME.Border
    WepScroller.Parent = SkinLeft
    corner(WepScroller, 4)
    stroke(WepScroller, THEME.Border, 1)

    local WepLayout = Instance.new("UIListLayout")
    WepLayout.Padding = UDim.new(0, 2)
    WepLayout.SortOrder = Enum.SortOrder.LayoutOrder
    WepLayout.Parent = WepScroller

    function Emulator.refreshWeaponList()
        for _, child in ipairs(WepScroller:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        local currentList = WEAPON_CATEGORIES[State.skinChanger.selectedCategory] or {}
        for _, wepName in ipairs(currentList) do
            local b = Instance.new("TextButton")
            b.Text = "  " .. wepName
            b.Font = Enum.Font.Gotham
            b.TextSize = 10
            b.TextColor3 = (State.skinChanger.selectedWeapon == wepName) and THEME.AccentGreen or THEME.TextSecondary
            b.BackgroundColor3 = (State.skinChanger.selectedWeapon == wepName) and THEME.CardHover or THEME.ConsoleBg
            b.Size = UDim2.new(1, 0, 0, 20)
            b.TextXAlignment = Enum.TextXAlignment.Left
            b.Parent = WepScroller

            b.MouseButton1Click:Connect(function()
                Emulator.setWeapon(wepName)
                for _, other in ipairs(WepScroller:GetChildren()) do
                    if other:IsA("TextButton") then
                        local isSel = (other.Text:gsub("%s+", "") == wepName:gsub("%s+", ""))
                        other.TextColor3 = isSel and THEME.AccentGreen or THEME.TextSecondary
                        other.BackgroundColor3 = isSel and THEME.CardHover or THEME.ConsoleBg
                    end
                end
            end)
        end
        WepScroller.CanvasSize = UDim2.new(0, 0, 0, #currentList * 22)
    end
    Emulator.refreshWeaponList()

    -- Skin Changer Toggles
    local ToggleSkinBtn = Instance.new("TextButton")
    ToggleSkinBtn.Text = "SKIN CHANGER: " .. (State.skinChanger.enabled and "ON" or "OFF")
    ToggleSkinBtn.Font = Enum.Font.GothamBold
    ToggleSkinBtn.TextSize = 10
    ToggleSkinBtn.TextColor3 = State.skinChanger.enabled and THEME.AccentGreen or THEME.TextMuted
    ToggleSkinBtn.BackgroundColor3 = THEME.CardHover
    ToggleSkinBtn.Position = UDim2.new(0, 10, 0, 284)
    ToggleSkinBtn.Size = UDim2.new(1, -20, 0, 24)
    ToggleSkinBtn.Parent = SkinLeft
    corner(ToggleSkinBtn, 4)
    stroke(ToggleSkinBtn, THEME.Border, 1)

    ToggleSkinBtn.MouseButton1Click:Connect(function()
        State.skinChanger.enabled = not State.skinChanger.enabled
        ToggleSkinBtn.Text = "SKIN CHANGER: " .. (State.skinChanger.enabled and "ON" or "OFF")
        ToggleSkinBtn.TextColor3 = State.skinChanger.enabled and THEME.AccentGreen or THEME.TextMuted
        if State.skinChanger.enabled then
            hookClientViewModel()
            Emulator.applySkinNow()
        end
    end)

    local ToggleInvertBtn = Instance.new("TextButton")
    ToggleInvertBtn.Text = "INVERT COLORS: " .. (State.skinChanger.inverted and "ON" or "OFF")
    ToggleInvertBtn.Font = Enum.Font.Gotham
    ToggleInvertBtn.TextSize = 9
    ToggleInvertBtn.TextColor3 = State.skinChanger.inverted and THEME.AccentOrange or THEME.TextSecondary
    ToggleInvertBtn.BackgroundColor3 = THEME.CardHover
    ToggleInvertBtn.Position = UDim2.new(0, 10, 0, 314)
    ToggleInvertBtn.Size = UDim2.new(1, -20, 0, 22)
    ToggleInvertBtn.Parent = SkinLeft
    corner(ToggleInvertBtn, 4)
    stroke(ToggleInvertBtn, THEME.Border, 1)

    ToggleInvertBtn.MouseButton1Click:Connect(function()
        State.skinChanger.inverted = not State.skinChanger.inverted
        ToggleInvertBtn.Text = "INVERT COLORS: " .. (State.skinChanger.inverted and "ON" or "OFF")
        ToggleInvertBtn.TextColor3 = State.skinChanger.inverted and THEME.AccentOrange or THEME.TextSecondary
        Emulator.render3DPreview()
        if State.skinChanger.enabled then
            Emulator.applySkinNow()
        end
    end)

    local ApplyNowBtn = Instance.new("TextButton")
    ApplyNowBtn.Text = "✦ EQUIP TO LIVE VIEWMODEL"
    ApplyNowBtn.Font = Enum.Font.GothamBold
    ApplyNowBtn.TextSize = 10
    ApplyNowBtn.TextColor3 = THEME.AccentCyan
    ApplyNowBtn.BackgroundColor3 = Color3.fromRGB(15, 40, 55)
    ApplyNowBtn.Position = UDim2.new(0, 10, 1, -32)
    ApplyNowBtn.Size = UDim2.new(1, -20, 0, 26)
    ApplyNowBtn.Parent = SkinLeft
    corner(ApplyNowBtn, 4)
    stroke(ApplyNowBtn, Color3.fromRGB(30, 80, 110), 1)

    ApplyNowBtn.MouseButton1Click:Connect(function()
        hookClientViewModel()
        State.skinChanger.enabled = true
        ToggleSkinBtn.Text = "SKIN CHANGER: ON"
        ToggleSkinBtn.TextColor3 = THEME.AccentGreen
        Emulator.applySkinNow()
    end)

    -- Right Pane: Visual Skin Catalog Grid
    local SkinRight = Instance.new("Frame")
    SkinRight.Size = UDim2.new(1, -287, 1, 0)
    SkinRight.Position = UDim2.new(0, 287, 0, 0)
    SkinRight.BackgroundColor3 = THEME.CardBg
    SkinRight.Parent = SkinsFrame
    corner(SkinRight, 6)
    stroke(SkinRight, THEME.Border, 1)

    -- Search Bar
    local SearchBox = Instance.new("TextBox")
    SearchBox.PlaceholderText = "Search 380+ skins and wraps..."
    SearchBox.Text = ""
    SearchBox.Font = Enum.Font.RobotoMono
    SearchBox.TextSize = 10
    SearchBox.TextColor3 = THEME.TextPrimary
    SearchBox.PlaceholderColor3 = THEME.TextMuted
    SearchBox.BackgroundColor3 = THEME.ConsoleBg
    SearchBox.Position = UDim2.new(0, 12, 0, 10)
    SearchBox.Size = UDim2.new(1, -24, 0, 24)
    SearchBox.ClearTextOnFocus = false
    SearchBox.Parent = SkinRight
    corner(SearchBox, 4)
    stroke(SearchBox, THEME.Border, 1)

    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        State.skinChanger.searchQuery = SearchBox.Text:lower()
        Emulator.refreshSkinCatalog()
    end)

    -- Catalog Filter Pills
    local CatFilterBar = Instance.new("Frame")
    CatFilterBar.Size = UDim2.new(1, -24, 0, 20)
    CatFilterBar.Position = UDim2.new(0, 12, 0, 40)
    CatFilterBar.BackgroundTransparency = 1
    CatFilterBar.Parent = SkinRight

    local filterButtons = {}
    local function createCatalogFilterPill(title: string, catId: string, xPos: number)
        local btn = Instance.new("TextButton")
        btn.Text = title
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 9
        btn.TextColor3 = (State.skinChanger.catalogFilter == catId) and THEME.AccentCyan or THEME.TextMuted
        btn.BackgroundColor3 = (State.skinChanger.catalogFilter == catId) and THEME.CardHover or THEME.Bg
        btn.Position = UDim2.new(0, xPos, 0, 0)
        btn.Size = UDim2.new(0, 75, 1, 0)
        btn.Parent = CatFilterBar
        corner(btn, 4)
        stroke(btn, THEME.Border, 1)

        btn.MouseButton1Click:Connect(function()
            State.skinChanger.catalogFilter = catId
            for fId, b in pairs(filterButtons) do
                local isSel = (fId == catId)
                b.TextColor3 = isSel and THEME.AccentCyan or THEME.TextMuted
                b.BackgroundColor3 = isSel and THEME.CardHover or THEME.Bg
            end
            Emulator.refreshSkinCatalog()
        end)
        filterButtons[catId] = btn
    end

    createCatalogFilterPill("ALL WRAPS", "ALL", 0)
    createCatalogFilterPill("UNIQUE", "UNIQUE", 82)
    createCatalogFilterPill("MASTERY", "MASTERY", 164)
    createCatalogFilterPill("SOLID", "SOLID", 246)

    -- Catalog Scroller
    local CatalogScroller = Instance.new("ScrollingFrame")
    CatalogScroller.Name = "CatalogScroller"
    CatalogScroller.Size = UDim2.new(1, -24, 1, -72)
    CatalogScroller.Position = UDim2.new(0, 12, 0, 66)
    CatalogScroller.BackgroundTransparency = 1
    CatalogScroller.BorderSizePixel = 0
    CatalogScroller.ScrollBarThickness = 4
    CatalogScroller.ScrollBarImageColor3 = THEME.Border
    CatalogScroller.Parent = SkinRight
    UI.CatalogScroller = CatalogScroller

    local CatalogGrid = Instance.new("UIGridLayout")
    CatalogGrid.CellSize = UDim2.new(0, 132, 0, 68)
    CatalogGrid.CellPadding = UDim2.new(0, 8, 0, 8)
    CatalogGrid.SortOrder = Enum.SortOrder.LayoutOrder
    CatalogGrid.Parent = CatalogScroller

    function Emulator.refreshSkinCatalog()
        if not UI.CatalogScroller then return end
        for _, child in ipairs(UI.CatalogScroller:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end

        local count = 0
        for _, wrap in ipairs(CATALOG_WRAPS) do
            local passFilter = (State.skinChanger.catalogFilter == "ALL" or wrap.Category == State.skinChanger.catalogFilter)
            local passSearch = (State.skinChanger.searchQuery == "" or wrap.Name:lower():find(State.skinChanger.searchQuery, 1, true) ~= nil)

            if passFilter and passSearch then
                count += 1
                local card = Instance.new("Frame")
                card.BackgroundColor3 = (State.skinChanger.selectedWrap == wrap.Name) and THEME.CardHover or THEME.ConsoleBg
                corner(card, 6)
                stroke(card, (State.skinChanger.selectedWrap == wrap.Name) and THEME.AccentCyan or THEME.Border, 1)

                -- Visual Dual-Color Swatch
                local Swatch = Instance.new("Frame")
                Swatch.Size = UDim2.new(1, -12, 0, 20)
                Swatch.Position = UDim2.new(0, 6, 0, 6)
                Swatch.BackgroundColor3 = wrap.Primary
                Swatch.Parent = card
                corner(Swatch, 4)

                local SecondarySwatch = Instance.new("Frame")
                SecondarySwatch.Size = UDim2.new(0.5, 0, 1, 0)
                SecondarySwatch.Position = UDim2.new(0.5, 0, 0, 0)
                SecondarySwatch.BackgroundColor3 = wrap.Secondary
                SecondarySwatch.BorderSizePixel = 0
                SecondarySwatch.Parent = Swatch
                corner(SecondarySwatch, 4)

                -- Wrap Name
                local nameLbl = Instance.new("TextLabel")
                nameLbl.Text = wrap.Name
                nameLbl.Font = Enum.Font.GothamBold
                nameLbl.TextSize = 10
                nameLbl.TextColor3 = (State.skinChanger.selectedWrap == wrap.Name) and THEME.AccentCyan or THEME.TextPrimary
                nameLbl.Position = UDim2.new(0, 6, 0, 30)
                nameLbl.Size = UDim2.new(1, -12, 0, 16)
                nameLbl.BackgroundTransparency = 1
                nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
                nameLbl.Parent = card

                -- Rarity Badge
                local rarityLbl = Instance.new("TextLabel")
                rarityLbl.Text = wrap.Rarity:upper()
                rarityLbl.Font = Enum.Font.Gotham
                rarityLbl.TextSize = 8
                local rCol = THEME.TextMuted
                if wrap.Rarity == "Mastery" then rCol = THEME.AccentOrange
                elseif wrap.Rarity == "Unique" then rCol = THEME.AccentPurple end
                rarityLbl.TextColor3 = rCol
                rarityLbl.Position = UDim2.new(0, 6, 0, 48)
                rarityLbl.Size = UDim2.new(1, -12, 0, 12)
                rarityLbl.BackgroundTransparency = 1
                rarityLbl.TextXAlignment = Enum.TextXAlignment.Left
                rarityLbl.Parent = card

                local hitBtn = Instance.new("TextButton")
                hitBtn.Size = UDim2.new(1, 0, 1, 0)
                hitBtn.BackgroundTransparency = 1
                hitBtn.Text = ""
                hitBtn.Parent = card

                hitBtn.MouseButton1Click:Connect(function()
                    Emulator.setWrap(wrap.Name)
                    Emulator.render3DPreview()
                    Emulator.refreshSkinCatalog()
                end)

                card.Parent = UI.CatalogScroller
            end
        end

        local rows = math.ceil(count / 3)
        CatalogScroller.CanvasSize = UDim2.new(0, 0, 0, rows * 76 + 10)
    end
    Emulator.refreshSkinCatalog()

    -- 3D Viewport Render Loop (Orbit Camera & Shading)
    local orbitAngle = 0
    RunService.RenderStepped:Connect(function(dt)
        if UI.ViewportCamera and UI.SkinsContainer and UI.SkinsContainer.Visible then
            orbitAngle += dt * 0.75
            local radius = 3.6
            local x = math.sin(orbitAngle) * radius
            local z = math.cos(orbitAngle) * radius
            UI.ViewportCamera.CFrame = CFrame.new(Vector3.new(x, 0.6, z), Vector3.new(0, 0, 0))
        end
    end)

    function Emulator.render3DPreview()
        if not UI.Viewport then return end
        for _, child in ipairs(UI.Viewport:GetChildren()) do
            if child:IsA("Model") or child:IsA("BasePart") then
                child:Destroy()
            end
        end

        if UI.PreviewGunLabel then
            UI.PreviewGunLabel.Text = State.skinChanger.selectedWeapon:upper()
        end
        if UI.PreviewSkinLabel then
            UI.PreviewSkinLabel.Text = "WRAP: " .. State.skinChanger.selectedWrap:upper()
        end

        pcall(function()
            local WrapController = require(LocalPlayer.PlayerScripts.Controllers.WrapController)
            local ViewModelsAsset = LocalPlayer.PlayerScripts.Assets:FindFirstChild("ViewModels")
            local rawModel = ViewModelsAsset and ViewModelsAsset:FindFirstChild(State.skinChanger.selectedWeapon, true)

            if rawModel and rawModel:IsA("Model") then
                local preview = rawModel:Clone()
                preview:PivotTo(CFrame.identity)
                preview.Parent = UI.Viewport
                local wrapProps = WrapController:RecordOriginalWrapProperties(preview)
                WrapController:ApplyWrap(wrapProps, {
                    Name = State.skinChanger.selectedWrap,
                    Inverted = State.skinChanger.inverted,
                })
            else
                local fallback = Instance.new("Model")
                local body = Instance.new("Part")
                body.Name = "Body"
                body.Size = Vector3.new(2.8, 0.6, 0.3)
                body.Position = Vector3.new(0, 0, 0)
                body.Anchored = true
                body:AddTag("Wrappable")
                body:SetAttribute("WrapGroup", 1)
                body.Parent = fallback

                local barrel = Instance.new("Part")
                barrel.Name = "Barrel"
                barrel.Size = Vector3.new(1.4, 0.3, 0.25)
                barrel.Position = Vector3.new(1.8, 0.1, 0)
                barrel.Anchored = true
                barrel:AddTag("Wrappable")
                barrel:SetAttribute("WrapGroup", 2)
                barrel.Parent = fallback

                local grip = Instance.new("Part")
                grip.Name = "Grip"
                grip.Size = Vector3.new(0.4, 1.0, 0.28)
                grip.Position = Vector3.new(-0.6, -0.6, 0)
                grip.Orientation = Vector3.new(0, 0, -18)
                grip.Anchored = true
                grip:AddTag("Wrappable")
                grip:SetAttribute("WrapGroup", 1)
                grip.Parent = fallback

                fallback.PrimaryPart = body
                fallback.Parent = UI.Viewport
                fallback:PivotTo(CFrame.identity)

                local wrapProps = WrapController:RecordOriginalWrapProperties(fallback)
                WrapController:ApplyWrap(wrapProps, {
                    Name = State.skinChanger.selectedWrap,
                    Inverted = State.skinChanger.inverted,
                })
            end
        end)
    end
    Emulator.render3DPreview()

    -- 4. CONTROLS TAB
    local ControlsFrame = Instance.new("Frame")
    ControlsFrame.Name = "ControlsFrame"
    ControlsFrame.Size = UDim2.new(1, 0, 1, 0)
    ControlsFrame.BackgroundTransparency = 1
    ControlsFrame.Visible = false
    ControlsFrame.Parent = Body
    UI.ControlsContainer = ControlsFrame

    local ControlsLayout = Instance.new("UIListLayout")
    ControlsLayout.Padding = UDim.new(0, 10)
    ControlsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ControlsLayout.Parent = ControlsFrame

    local function createActionButton(title: string, descText: string, btnText: string, color: Color3?, callback: () -> ()): Frame
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 50)
        row.BackgroundColor3 = THEME.CardBg
        corner(row, 6)
        stroke(row, THEME.Border, 1)

        local t = Instance.new("TextLabel")
        t.Text = title
        t.Font = Enum.Font.GothamBold
        t.TextSize = 12
        t.TextColor3 = THEME.TextPrimary
        t.Position = UDim2.new(0, 14, 0, 8)
        t.Size = UDim2.new(1, -160, 0, 16)
        t.BackgroundTransparency = 1
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.Parent = row

        local d = Instance.new("TextLabel")
        d.Text = descText
        d.Font = Enum.Font.Gotham
        d.TextSize = 10
        d.TextColor3 = THEME.TextMuted
        d.Position = UDim2.new(0, 14, 0, 26)
        d.Size = UDim2.new(1, -160, 0, 16)
        d.BackgroundTransparency = 1
        d.TextXAlignment = Enum.TextXAlignment.Left
        d.Parent = row

        local btn = Instance.new("TextButton")
        btn.Text = btnText
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.TextColor3 = color or THEME.TextPrimary
        btn.BackgroundColor3 = THEME.CardHover
        btn.Position = UDim2.new(1, -135, 0, 11)
        btn.Size = UDim2.new(0, 120, 0, 28)
        btn.Parent = row
        corner(btn, 4)
        stroke(btn, THEME.Border, 1)

        btn.MouseButton1Click:Connect(callback)
        return row
    end

    createActionButton("Re-Scan Challenges", "Scans Remotes for LocalScript3 challenge event", "TRIGGER SCAN", THEME.AccentCyan, function()
        Emulator.log("INFO", "SCAN", "Manual challenge re-scan dispatched...")
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local c, n = findChallenge(remotes)
            if c and n then
                attachRelay(c, n)
                Emulator.log("INFO", "SCAN", "Challenge remote hooked successfully")
            else
                Emulator.log("WARN", "SCAN", "Challenge remote not currently exposed")
            end
        end
    end).Parent = ControlsFrame

    createActionButton("Force Material Pulse", "Sends an immediate heartbeat packet to MaterialService", "SEND PULSE", THEME.AccentGreen, function()
        if State.materialRemote then
            pcall(function() State.materialRemote:FireServer("", nil, nil) end)
            State.materialSent += 1
            Emulator.log("HEARTBEAT", "MANUAL", "Manual heartbeat pulse sent")
            OnStateChanged:Fire()
        end
    end).Parent = ControlsFrame

    createActionButton("Staff Permissions Spoofer", "Toggles local administrator privileges in PermissionsLibrary", "TOGGLE SPOOFER", THEME.AccentOrange, function()
        Emulator.applyStaffPermSpoofer(not State.staffSpooferActive)
    end).Parent = ControlsFrame

    createActionButton("Re-Neutralize Traps", "Re-disarms ItemLibrary freeze trap & OutOfBounds triggers", "DISARM ALL", THEME.AccentPurple, function()
        Emulator.disarmItemLibraryTrap()
        Emulator.neutralizeOutOfBounds()
        purgeMiscWatchdogs()
    end).Parent = ControlsFrame

    createActionButton("Full Emulator Unload", "Detaches all hooks, restores original connections & destroys UI", "UNLOAD", THEME.AccentRed, function()
        Emulator.unload()
    end).Parent = ControlsFrame

    -- Tab switching logic
    local function switchTab(id: string)
        State.activeTab = id
        ConsoleFrame.Visible = (id == "Console")
        MetricsFrame.Visible = (id == "Metrics")
        SkinsFrame.Visible = (id == "Skins")
        ControlsFrame.Visible = (id == "Controls")

        for _, btn in ipairs({ TabConsole, TabMetrics, TabSkins, TabControls }) do
            local isCurrent = (btn.Text:upper() == id:upper() or (id == "Skins" and btn.Text:find("CATALOG")))
            btn.TextColor3 = isCurrent and THEME.AccentCyan or THEME.TextMuted
            btn.BackgroundColor3 = isCurrent and THEME.CardBg or Color3.fromRGB(0, 0, 0)
            btn.BackgroundTransparency = isCurrent and 0 or 1
            local existingStroke = btn:FindFirstChildOfClass("UIStroke")
            if isCurrent and not existingStroke then
                stroke(btn, THEME.Border, 1)
            elseif not isCurrent and existingStroke then
                existingStroke:Destroy()
            end
        end
        if id == "Skins" then
            Emulator.render3DPreview()
        end
    end

    TabConsole.MouseButton1Click:Connect(function() switchTab("Console") end)
    TabMetrics.MouseButton1Click:Connect(function() switchTab("Metrics") end)
    TabSkins.MouseButton1Click:Connect(function() switchTab("Skins") end)
    TabControls.MouseButton1Click:Connect(function() switchTab("Controls") end)

    -- -------------------------------------------------------------------------
    -- Floating Minimized Pill Widget
    -- -------------------------------------------------------------------------
    local Pill = Instance.new("TextButton")
    Pill.Name = "EmulatorPill"
    Pill.Size = UDim2.new(0, 180, 0, 32)
    Pill.Position = UDim2.new(0, 20, 0, 20)
    Pill.BackgroundColor3 = THEME.Bg
    Pill.Text = "● ATOMWARE EMULATOR"
    Pill.Font = Enum.Font.GothamBold
    Pill.TextSize = 11
    Pill.TextColor3 = THEME.AccentCyan
    Pill.Visible = false
    Pill.Parent = ScreenGui
    corner(Pill, 16)
    stroke(Pill, THEME.AccentCyan, 1)
    UI.PillWidget = Pill

    local function setWindowMinimized(minimized: boolean)
        Main.Visible = not minimized
        Pill.Visible = minimized
    end

    MinBtn.MouseButton1Click:Connect(function() setWindowMinimized(true) end)
    Pill.MouseButton1Click:Connect(function() setWindowMinimized(false) end)
    CloseBtn.MouseButton1Click:Connect(function() Emulator.unload() end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == TOGGLE_KEY then
            Main.Visible = not Main.Visible
            if Pill.Visible then Pill.Visible = false end
        end
    end)
end

function Emulator.refreshConsoleLogs()
    if not UI.LogScroller then return end
    for _, child in ipairs(UI.LogScroller:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    for _, entry in ipairs(State.logs) do
        if State.activeFilter == "ALL" or entry.level == State.activeFilter or (State.activeFilter == "WARN" and (entry.level == "WARN" or entry.level == "ERROR")) then
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 18)
            row.BackgroundTransparency = 1

            local timeLbl = Instance.new("TextLabel")
            timeLbl.Text = entry.timestamp
            timeLbl.Font = Enum.Font.RobotoMono
            timeLbl.TextSize = 10
            timeLbl.TextColor3 = THEME.TextMuted
            timeLbl.Size = UDim2.new(0, 60, 1, 0)
            timeLbl.BackgroundTransparency = 1
            timeLbl.TextXAlignment = Enum.TextXAlignment.Left
            timeLbl.Parent = row

            local badge = Instance.new("TextLabel")
            badge.Text = "[" .. entry.level .. "]"
            badge.Font = Enum.Font.GothamBold
            badge.TextSize = 9
            local bCol = THEME.TextSecondary
            if entry.level == "CHALLENGE" then bCol = THEME.AccentCyan
            elseif entry.level == "HEARTBEAT" then bCol = THEME.AccentGreen
            elseif entry.level == "SKINS" then bCol = THEME.AccentPurple
            elseif entry.level == "TRAP" then bCol = THEME.AccentOrange
            elseif entry.level == "WARN" then bCol = THEME.AccentOrange
            elseif entry.level == "ERROR" then bCol = THEME.AccentRed end
            badge.TextColor3 = bCol
            badge.Position = UDim2.new(0, 65, 0, 0)
            badge.Size = UDim2.new(0, 85, 1, 0)
            badge.BackgroundTransparency = 1
            badge.TextXAlignment = Enum.TextXAlignment.Left
            badge.Parent = row

            local msg = Instance.new("TextLabel")
            msg.Text = entry.message
            msg.Font = Enum.Font.Gotham
            msg.TextSize = 10
            msg.TextColor3 = (entry.level == "ERROR") and THEME.AccentRed or THEME.TextPrimary
            msg.Position = UDim2.new(0, 155, 0, 0)
            msg.Size = UDim2.new(1, -160, 1, 0)
            msg.BackgroundTransparency = 1
            msg.TextXAlignment = Enum.TextXAlignment.Left
            msg.TextTruncate = Enum.TextTruncate.AtEnd
            msg.Parent = row

            row.Parent = UI.LogScroller
        end
    end

    if State.autoScroll and UI.LogScroller then
        UI.LogScroller.CanvasPosition = Vector2.new(0, 999999)
    end
end

OnLogAdded:Connect(function(entry)
    if not UI.LogScroller then return end
    if State.activeFilter == "ALL" or entry.level == State.activeFilter or (State.activeFilter == "WARN" and (entry.level == "WARN" or entry.level == "ERROR")) then
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 18)
        row.BackgroundTransparency = 1

        local timeLbl = Instance.new("TextLabel")
        timeLbl.Text = entry.timestamp
        timeLbl.Font = Enum.Font.RobotoMono
        timeLbl.TextSize = 10
        timeLbl.TextColor3 = THEME.TextMuted
        timeLbl.Size = UDim2.new(0, 60, 1, 0)
        timeLbl.BackgroundTransparency = 1
        timeLbl.TextXAlignment = Enum.TextXAlignment.Left
        timeLbl.Parent = row

        local badge = Instance.new("TextLabel")
        badge.Text = "[" .. entry.level .. "]"
        badge.Font = Enum.Font.GothamBold
        badge.TextSize = 9
        local bCol = THEME.TextSecondary
        if entry.level == "CHALLENGE" then bCol = THEME.AccentCyan
        elseif entry.level == "HEARTBEAT" then bCol = THEME.AccentGreen
        elseif entry.level == "SKINS" then bCol = THEME.AccentPurple
        elseif entry.level == "TRAP" then bCol = THEME.AccentOrange
        elseif entry.level == "WARN" then bCol = THEME.AccentOrange
        elseif entry.level == "ERROR" then bCol = THEME.AccentRed end
        badge.TextColor3 = bCol
        badge.Position = UDim2.new(0, 65, 0, 0)
        badge.Size = UDim2.new(0, 85, 1, 0)
        badge.BackgroundTransparency = 1
        badge.TextXAlignment = Enum.TextXAlignment.Left
        badge.Parent = row

        local msg = Instance.new("TextLabel")
        msg.Text = entry.message
        msg.Font = Enum.Font.Gotham
        msg.TextSize = 10
        msg.TextColor3 = (entry.level == "ERROR") and THEME.AccentRed or THEME.TextPrimary
        msg.Position = UDim2.new(0, 155, 0, 0)
        msg.Size = UDim2.new(1, -160, 1, 0)
        msg.BackgroundTransparency = 1
        msg.TextXAlignment = Enum.TextXAlignment.Left
        msg.TextTruncate = Enum.TextTruncate.AtEnd
        msg.Parent = row

        row.Parent = UI.LogScroller

        if State.autoScroll then
            UI.LogScroller.CanvasPosition = Vector2.new(0, 999999)
        end
    end
end)

OnStateChanged:Connect(function()
    if not UI.MainFrame then return end
    
    if UI.LatencyPill then
        UI.LatencyPill.Text = string.format("LATENCY: %s ms", State.lastLatency >= 0 and tostring(State.lastLatency) or "--")
    end

    local metrics = UI.MetricsContainer
    if metrics then
        local c1 = metrics:FindFirstChild("Card_Challenges")
        if c1 then
            c1.ValueLabel.Text = tostring(State.invoked)
            c1.SubLabel.Text = string.format("Inbound: %d | Errors: %d", State.inbound, State.errors)
        end

        local c2 = metrics:FindFirstChild("Card_Heartbeat")
        if c2 then
            c2.ValueLabel.Text = string.format("%d Pulses", State.materialSent)
            c2.SubLabel.Text = string.format("Interval: 4s | Errors: %d", State.materialErrors)
        end

        local c3 = metrics:FindFirstChild("Card_Environment")
        if c3 then
            local envType = "LOBBY"
            if State.currentEnvironmentID >= 3000 then envType = "DUEL ARENA"
            elseif State.currentEnvironmentID == 2047 then envType = "RANGE" end
            c3.ValueLabel.Text = string.format("%d (%s)", State.currentEnvironmentID, envType)
        end

        local c4 = metrics:FindFirstChild("Card_ItemTrap")
        if c4 then
            c4.ValueLabel.Text = State.itemLibraryDisarmed and "DISARMED" or "ACTIVE"
            c4.ValueLabel.TextColor3 = State.itemLibraryDisarmed and THEME.AccentGreen or THEME.AccentRed
        end

        local c5 = metrics:FindFirstChild("Card_OOB")
        if c5 then
            c5.ValueLabel.Text = State.outOfBoundsNeutralized and "NEUTRALIZED" or "DEFAULT"
            c5.ValueLabel.TextColor3 = State.outOfBoundsNeutralized and THEME.AccentGreen or THEME.AccentOrange
        end

        local c6 = metrics:FindFirstChild("Card_Watchdogs")
        if c6 then
            c6.ValueLabel.Text = string.format("%d Threads", State.miscCancelled)
            c6.SubLabel.Text = string.format("Found: %d | Purged: %d", State.miscFound, State.miscCancelled)
        end
    end
end)

OnSkinChanged:Connect(function()
    if UI.SkinsContainer and UI.SkinsContainer.Visible then
        Emulator.render3DPreview()
    end
end)

-- =============================================================================
-- PUBLIC API METHODS
-- =============================================================================

function Emulator.status()
    local now = os.clock()
    return {
        started = State.started,
        active = State.active,
        uptime = State.startedAt and (now - State.startedAt) or 0,
        inbound = State.inbound,
        invoked = State.invoked,
        responses = State.responses,
        errors = State.errors,
        materialSent = State.materialSent,
        lastLatency = State.lastLatency,
        environmentID = State.currentEnvironmentID,
        itemLibraryDisarmed = State.itemLibraryDisarmed,
        outOfBoundsNeutralized = State.outOfBoundsNeutralized,
        skinChanger = State.skinChanger,
    }
end

function Emulator.stop()
    State.active = false
    State.started = false
    if State.relayConnection then
        pcall(function() State.relayConnection:Disconnect() end)
        State.relayConnection = nil
    end
    if State.native then
        if type(State.native.Enable) == "function" then pcall(State.native.Enable, State.native) end
        pcall(function() State.native.Enabled = true end)
    end
    if State.originalScript then
        pcall(function() State.originalScript.Enabled = true end)
    end
    if UI.StatusBadge then
        UI.StatusBadge.Text = "● STOPPED"
        UI.StatusBadge.TextColor3 = THEME.TextMuted
    end
    Emulator.log("INFO", "ENGINE", "Emulator stopped; original challenge connections restored")
end

function Emulator.unload()
    Emulator.stop()
    if State.staffSpooferActive then
        Emulator.applyStaffPermSpoofer(false)
    end
    if State.skinChanger.unlockAllCosmetics then
        Emulator.toggleUnlockAllCosmetics(false)
    end
    if UI.ScreenGui then
        UI.ScreenGui:Destroy()
        UI.ScreenGui = nil
    end
    env.ATOMWARE_EMU_UNLOAD = nil
    env.AtomwareEmulator = nil
    _G.AtomwareEmulator = nil
    print("[Atomware] Emulator fully unloaded from client memory")
end

function Emulator.start()
    if State.started then return Emulator end

    buildUI()
    Emulator.log("INFO", "STARTUP", "Atomware Rivals Defensive Emulator initializing...")

    if game.GameId ~= UNIVERSE_ID and game.PlaceId ~= 17625359962 and tostring(game.PlaceId) ~= "17625359962" then
        Emulator.log("WARN", "GAME_GUARD", string.format("RIVALS universe expected (6035872082); current GameId=%s", tostring(game.GameId)))
    end

    if type(get_conns) ~= "function" then
        Emulator.log("WARN", "CAPABILITY", "getconnections unavailable; challenge connection detachment may be limited")
    end
    if type(hook_meta) ~= "function" then
        Emulator.log("WARN", "CAPABILITY", "hookmetamethod unavailable; latency monitoring will run passively")
    end

    local originalScript = ReplicatedFirst:WaitForChild("LocalScript3", 6)
    if originalScript then
        State.originalScript = originalScript :: LocalScript
        if not originalScript.Enabled then originalScript.Enabled = true end
    else
        Emulator.log("WARN", "RESOLVE", "ReplicatedFirst.LocalScript3 not yet loaded; polling in background")
    end

    Emulator.disarmItemLibraryTrap()
    Emulator.neutralizeOutOfBounds()
    purgeMiscWatchdogs()

    local remotes = ReplicatedStorage:WaitForChild("Remotes", 8)
    local materialRemote = MaterialService:WaitForChild("RemoteEvent", 6) or MaterialService:FindFirstChildOfClass("RemoteEvent")

    if remotes then
        local challenge, native = findChallenge(remotes)
        if challenge and native then
            State.challenge = challenge
            State.native = native
            observeResponses(challenge)
            attachRelay(challenge, native)
        else
            Emulator.log("WARN", "RESOLVE", "Challenge callback not yet bound; initiating background resolver")
            task.spawn(function()
                for i = 1, 30 do
                    task.wait(1)
                    if State.started and State.active then return end
                    local c, n = findChallenge(remotes)
                    if c and n then
                        State.challenge = c
                        State.native = n
                        observeResponses(c)
                        attachRelay(c, n)
                        Emulator.log("INFO", "RESOLVE", string.format("Challenge remote resolved on attempt #%d", i))
                        return
                    end
                end
                Emulator.log("ERROR", "TIMEOUT", "Challenge remote callback binding timed out")
            end)
        end
    end

    if materialRemote then
        startMaterialHeartbeat(materialRemote)
    else
        Emulator.log("WARN", "MATERIAL", "MaterialService.RemoteEvent not found; heartbeat disabled")
    end

    monitorEnvironment()

    task.spawn(function()
        task.wait(1)
        hookClientViewModel()
    end)

    State.started = true
    State.startedAt = os.clock()
    OnStateChanged:Fire()
    Emulator.log("INFO", "STARTUP", "Atomware Emulator fully operational & protecting client")
    
    return Emulator
end

env.ATOMWARE_EMU_UNLOAD = Emulator.unload
env.AtomwareEmulator = Emulator
_G.AtomwareEmulator = Emulator

Emulator.start()

return Emulator
