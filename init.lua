--[[
    init.lua
    Universal Master Initializer for Atomware
    Connected to Atom Protect Gateway (https://atomprotect.vercel.app)
    Automatically detects platform (Mobile vs PC / Controller) and loads dedicated UI + Features Backend
    Place ID restrictions: REMOVED (Universal Execution Enabled)
]]

local UserInputService = game:GetService("UserInputService")

-- If the initializer is run again, unload the previous UI/backend first.
if _G.AtomwareUnload and (_G.AtomwareUILoaded or _G.AtomwareFeaturesLoaded) then
    pcall(_G.AtomwareUnload)
end
_G.AtomwareUILoaded = nil
_G.AtomwareFeaturesLoaded = nil
_G.AtomwareEvents = nil
_G.OnToggle = nil
_G.__VFS_MODULES = nil
if type(getgenv) == "function" and getgenv() then
    getgenv().__VFS_MODULES = nil
    getgenv().__VFS_CACHE = nil
end

-- Platform Detection
-- TouchEnabled alone is the correct signal for mobile/tablet
local IS_MOBILE = UserInputService.TouchEnabled
local targetUIFile = IS_MOBILE and "mobile_ui.lua" or "main_ui.lua"

-- =========================================================================
-- Hybrid Secure Module Loader
-- 1. Direct TestFork GitHub loader with dynamic cache-busting
-- 2. In-Memory Virtual File System (Fallback)
-- 3. Virtual require hook
-- =========================================================================
local function loadModule(path)
    local cleanName = path:gsub("%.lua$", "")

    -- 1. TestFork GitHub Repository (Primary direct source with live cache-busting)
    local TESTFORK_URL = "https://raw.githubusercontent.com/revileDev/TestFork/main/"
    local cacheBuster = tostring(os.time()) .. "_" .. tostring(math.random(100000, 999999))
    local okTest, testSource = pcall(function()
        return game:HttpGet(TESTFORK_URL .. path .. "?v=" .. cacheBuster)
    end)
    if okTest and testSource and #testSource > 0 and not testSource:find("404: Not Found") and not testSource:find("<!DOCTYPE") then
        local compileOk, chunk, compileErr = pcall(loadstring, testSource)
        if compileOk and chunk then
            local runOk, runErr = pcall(chunk)
            if runOk then return true end
            warn("[Atomware] Error running module from TestFork (" .. path .. "):", runErr)
        else
            warn("[Atomware] Error compiling module from TestFork (" .. path .. "):", compileErr)
        end
    end

    -- 2. In-Memory Virtual File System (Atom Protect / Aero Virtual Bundle Fallback)
    if type(__VFS_MODULES) == "table" then
        local loader = __VFS_MODULES[path] or __VFS_MODULES[cleanName]
        if loader then
            local ok, err = pcall(loader)
            if ok then return true end
            warn("[Atomware] Failed to execute in-memory module " .. path .. ":", err)
        end
    end

    -- 3. Virtual require hook
    if type(require) == "function" then
        local ok, res = pcall(require, cleanName)
        if ok and res ~= nil then
            return true
        end
    end

    warn("[Atomware] Could not load module: " .. path)
    return false
end

-- 1. Load Shared Configuration & Cleanup Manager
if not loadModule("config.lua") then
    warn("Atomware: shared configuration could not be loaded; startup aborted.")
    return
end
if not loadModule("cleanup.lua") then
    warn("Atomware: cleanup manager could not be loaded; startup aborted.")
    return
end

_G.AtomwareUnload = function()
    local player = game:GetService("Players").LocalPlayer
    local playerGui = player and player:FindFirstChild("PlayerGui")
    local gui = playerGui and (playerGui:FindFirstChild("AtomwareUI") or playerGui:FindFirstChild("AtomwareMobileUI"))
    if _G.AtomwareConfig then
        _G.AtomwareConfig:Unload(gui)
    elseif gui then
        gui:Destroy()
    end
    _G.AtomwareUILoaded = nil
    _G.AtomwareFeaturesLoaded = nil
    _G.AtomwareEvents = nil
    _G.OnToggle = nil
end

-- Load Platform UI (mobile_ui.lua vs main_ui.lua)
if not loadModule(targetUIFile) then
    if _G.AtomwareUnload then pcall(_G.AtomwareUnload) end
    return
end

-- 2. Wait for UI hooks to initialize (timeout after 15 s)
local uiWaitCount = 0
repeat
    task.wait()
    uiWaitCount = uiWaitCount + 1
    if uiWaitCount > 900 then
        warn("Atomware: UI failed to initialise after 15s — aborting.")
        if _G.AtomwareUnload then pcall(_G.AtomwareUnload) end
        return
    end
until _G.AtomwareUILoaded and _G.AtomwareEvents and _G.OnToggle

-- 3. Load Shared Features Engine
if not loadModule("features.lua") then
    warn("Atomware: feature backend could not be loaded; cleaning up startup.")
    if _G.AtomwareUnload then pcall(_G.AtomwareUnload) end
    return
end

-- 4. Verify everything is online (timeout after 15 s)
local verifyCount = 0
repeat
    task.wait()
    verifyCount = verifyCount + 1
    if verifyCount > 900 then
        warn("Atomware: Features failed to mark loaded after 15s — check features.lua for errors.")
        if _G.AtomwareUnload then pcall(_G.AtomwareUnload) end
        break
    end
until _G.AtomwareUILoaded and _G.AtomwareFeaturesLoaded

-- 5. Confirmation Print
print("[Atomware] Fully Initialized via Atom Protect Gateway")
