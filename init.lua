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

-- Platform Detection
-- TouchEnabled alone is the correct signal for mobile/tablet
local IS_MOBILE = UserInputService.TouchEnabled
local targetUIFile = IS_MOBILE and "mobile_ui.lua" or "main_ui.lua"

-- =========================================================================
-- Hybrid Secure Module Loader
-- 1. Checks in-memory Virtual File System (__VFS_MODULES from Atom Protect)
-- 2. Checks virtual require() environment
-- 3. Pulls from Atom Protect production server (https://atomprotect.vercel.app)
-- 4. Falls back to raw mirror if network requires
-- =========================================================================
local function loadModule(path)
    local cleanName = path:gsub("%.lua$", "")

    -- 1. In-Memory Virtual File System (Atom Protect / Aero Virtual Bundle)
    if type(__VFS_MODULES) == "table" then
        local loader = __VFS_MODULES[path] or __VFS_MODULES[cleanName]
        if loader then
            local ok, err = pcall(loader)
            if not ok then
                warn("[Atomware] Failed to execute in-memory module " .. path .. ":", err)
                return false
            end
            return true
        end
    end

    -- 2. Virtual require hook
    if type(require) == "function" then
        local ok, res = pcall(require, cleanName)
        if ok and res ~= nil then
            return true
        end
    end

    -- 2.5 TestFork GitHub Mirror (Direct repository testing)
    local TESTFORK_URL = "https://raw.githubusercontent.com/revileDev/TestFork/main/"
    local okTest, testSource = pcall(function()
        return game:HttpGet(TESTFORK_URL .. path .. "?t=" .. tostring(os.time()))
    end)
    if okTest and testSource and #testSource > 0 and not testSource:find("404: Not Found") and not testSource:find("<!DOCTYPE") then
        local compileOk, chunk, compileErr = pcall(loadstring, testSource)
        if compileOk and chunk then
            local runOk, runErr = pcall(chunk)
            if runOk then return true end
            warn("[Atomware] Failed to run module from TestFork: " .. path, runErr)
        end
    end

    -- 3. Production Backend Endpoint (Atom Protect Gateway)
    local SERVER_ENDPOINT = "https://atomprotect.vercel.app/api/loader/radium/"
    local okServer, serverSource = pcall(function()
        return game:HttpGet(SERVER_ENDPOINT .. path)
    end)
    if okServer and serverSource and #serverSource > 0 and not serverSource:find("<!DOCTYPE") and not serverSource:find("404") then
        local compileOk, chunk, compileErr = pcall(loadstring, serverSource)
        if compileOk and chunk then
            local runOk, runErr = pcall(chunk)
            if runOk then return true end
            warn("[Atomware] Failed to run module from Atom Protect server: " .. path, runErr)
        end
    end

    -- 4. Fallback Remote Mirror
    local FALLBACK_URL = "https://raw.githubusercontent.com/redisaac758-art/RadiumCCpaste/main/"
    local okFallback, fallbackSource = pcall(function()
        return game:HttpGet(FALLBACK_URL .. path)
    end)
    if okFallback and fallbackSource and #fallbackSource > 0 then
        local compileOk, chunk, compileErr = pcall(loadstring, fallbackSource)
        if compileOk and chunk then
            local runOk, runErr = pcall(chunk)
            if runOk then return true end
            warn("[Atomware] Failed to run module from mirror: " .. path, runErr)
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
if not _G.AtomwareFeaturesLoaded then
    if not loadModule("features.lua") then
        warn("Atomware: feature backend could not be loaded; cleaning up startup.")
        if _G.AtomwareUnload then pcall(_G.AtomwareUnload) end
        return
    end
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
