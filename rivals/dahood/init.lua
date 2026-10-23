--[[
    Atomware DaHood - init.lua
    Universal Master Initializer for Atomware DaHood
    Connected to TestFork Repository (https://github.com/revileDev/TestFork)
    Automatically detects platform (Mobile Touch vs Desktop PC) and loads dedicated UI + Features Backend.
]]

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- Game Verification Guard (Da Hood Place ID: 2788229376)
local SUPPORTED_PLACE_ID = 2788229376

local function checkGameSupported()
    if game.PlaceId == SUPPORTED_PLACE_ID or tostring(game.PlaceId) == "2788229376" then
        return true
    end

    -- 1. Native StarterGui Notification
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Atomware DaHood",
            Text = "this game is not supported",
            Duration = 6,
        })
    end)

    -- 2. Fallback On-Screen Toast (Reliable on all PC and Mobile executors)
    pcall(function()
        local gethui = gethui or function() return nil end
        local parent = gethui() or game:GetService("CoreGui") or (Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui"))
        if parent then
            local oldToast = parent:FindFirstChild("Atomware_UnsupportedGame")
            if oldToast then oldToast:Destroy() end

            local sg = Instance.new("ScreenGui")
            sg.Name = "Atomware_UnsupportedGame"
            sg.ResetOnSpawn = false
            sg.DisplayOrder = 9999
            sg.Parent = parent

            local banner = Instance.new("Frame")
            banner.AnchorPoint = Vector2.new(0.5, 0)
            banner.Position = UDim2.new(0.5, 0, 0, 24)
            banner.Size = UDim2.fromOffset(320, 52)
            banner.BackgroundColor3 = Color3.fromRGB(18, 12, 28)
            banner.BorderSizePixel = 0
            banner.Parent = sg

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 10)
            corner.Parent = banner

            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(255, 75, 125)
            stroke.Thickness = 1.5
            stroke.Parent = banner

            local title = Instance.new("TextLabel")
            title.Size = UDim2.new(1, -24, 0, 20)
            title.Position = UDim2.fromOffset(12, 6)
            title.BackgroundTransparency = 1
            title.Text = "ATOMWARE"
            title.TextColor3 = Color3.fromRGB(205, 104, 255)
            title.TextSize = 11
            title.Font = Enum.Font.GothamBold
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.Parent = banner

            local desc = Instance.new("TextLabel")
            desc.Size = UDim2.new(1, -24, 0, 20)
            desc.Position = UDim2.fromOffset(12, 24)
            desc.BackgroundTransparency = 1
            desc.Text = "this game is not supported"
            desc.TextColor3 = Color3.fromRGB(255, 241, 255)
            desc.TextSize = 13
            desc.Font = Enum.Font.GothamBold
            desc.TextXAlignment = Enum.TextXAlignment.Left
            desc.Parent = banner

            task.delay(6, function()
                if sg and sg.Parent then sg:Destroy() end
            end)
        end
    end)

    warn("[Atomware DaHood] this game is not supported (Current PlaceId: " .. tostring(game.PlaceId) .. ", Required: " .. tostring(SUPPORTED_PLACE_ID) .. ")")
    return false
end

if not checkGameSupported() then
    return
end

-- Executor Environment Pre-flight Verification Guard
local function checkExecutorSupported()
    local missingApis = {}

    -- 1. Hooking APIs (Required for emulation and game function hooks)
    local hasHooking = type(hookmetamethod) == "function"
        or type(hookfunction) == "function"
        or (type(debug) == "table" and type((debug :: any).hookmetamethod) == "function")
        or (type(debug) == "table" and type((debug :: any).hookfunction) == "function")
        or type(replaceclosure) == "function"
    if not hasHooking then
        table.insert(missingApis, "hookmetamethod / hookfunction")
    end

    -- 2. Connections API (Required by anticheat emulator to intercept RenderStepped challenges)
    local hasConnections = type(getconnections) == "function"
        or (type(debug) == "table" and type((debug :: any).getconnections) == "function")
    if not hasConnections then
        table.insert(missingApis, "getconnections")
    end

    -- 3. File System APIs (Required for profile configs, autoload, and assets)
    local hasFs = type(readfile) == "function" and type(writefile) == "function"
    if not hasFs then
        table.insert(missingApis, "readfile / writefile")
    end

    -- 4. Environment Closure Support
    local hasClosure = type(newcclosure) == "function"
    if not hasClosure then
        table.insert(missingApis, "newcclosure")
    end

    if #missingApis == 0 then
        return true
    end

    local execName = "Unknown"
    pcall(function()
        if type(identifyexecutor) == "function" then
            execName = tostring(identifyexecutor())
        elseif type(getexecutorname) == "function" then
            execName = tostring(getexecutorname())
        end
    end)

    local missingList = table.concat(missingApis, ", ")

    -- 1. Native StarterGui Notification
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Atomware DaHood",
            Text = "Executor not supported (" .. execName .. ")",
            Duration = 8,
        })
    end)

    -- 2. Fallback On-Screen Toast Modal
    pcall(function()
        local gethui = gethui or function() return nil end
        local parent = gethui() or game:GetService("CoreGui") or (Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui"))
        if parent then
            local oldToast = parent:FindFirstChild("Atomware_UnsupportedExecutor")
            if oldToast then oldToast:Destroy() end

            local sg = Instance.new("ScreenGui")
            sg.Name = "Atomware_UnsupportedExecutor"
            sg.ResetOnSpawn = false
            sg.DisplayOrder = 9999
            sg.Parent = parent

            local banner = Instance.new("Frame")
            banner.AnchorPoint = Vector2.new(0.5, 0)
            banner.Position = UDim2.new(0.5, 0, 0, 24)
            banner.Size = UDim2.fromOffset(360, 68)
            banner.BackgroundColor3 = Color3.fromRGB(18, 12, 28)
            banner.BorderSizePixel = 0
            banner.Parent = sg

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 10)
            corner.Parent = banner

            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(255, 75, 125)
            stroke.Thickness = 1.5
            stroke.Parent = banner

            local title = Instance.new("TextLabel")
            title.Size = UDim2.new(1, -24, 0, 20)
            title.Position = UDim2.fromOffset(12, 6)
            title.BackgroundTransparency = 1
            title.Text = "ATOMWARE · UNSUPPORTED EXECUTOR"
            title.TextColor3 = Color3.fromRGB(255, 100, 140)
            title.TextSize = 11
            title.Font = Enum.Font.GothamBold
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.Parent = banner

            local desc = Instance.new("TextLabel")
            desc.Size = UDim2.new(1, -24, 0, 36)
            desc.Position = UDim2.fromOffset(12, 24)
            desc.BackgroundTransparency = 1
            desc.Text = "Your executor (" .. execName .. ") is missing required APIs: " .. missingList .. ". Startup halted to prevent crashes."
            desc.TextColor3 = Color3.fromRGB(255, 241, 255)
            desc.TextSize = 10
            desc.Font = Enum.Font.GothamMedium
            desc.TextWrapped = true
            desc.TextXAlignment = Enum.TextXAlignment.Left
            desc.TextYAlignment = Enum.TextYAlignment.Top
            desc.Parent = banner

            task.delay(8, function()
                if sg and sg.Parent then sg:Destroy() end
            end)
        end
    end)

    warn("[Atomware DaHood] Unsupported executor detected: " .. execName .. ". Missing required APIs: " .. missingList .. ". Aborting startup.")
    return false
end

if not checkExecutorSupported() then
    return
end

-- If the initializer is run again, unload the previous UI/backend first.
if _G.AtomwareUnload and (_G.AtomwareUILoaded or _G.AtomwareFeaturesLoaded) then
    pcall(_G.AtomwareUnload)
end
_G.AtomwareUILoaded = nil
_G.AtomwareFeaturesLoaded = nil
_G.AtomwareWindow = nil
_G.AtomwareEvents = nil
_G.OnToggle = nil
_G.OnSlider = nil
_G.OnDropdown = nil
_G.OnColorPicker = nil
_G.OnKeybind = nil

-- Platform Detection
local IS_MOBILE = UserInputService.TouchEnabled
local targetUIFile = IS_MOBILE and "mobile_ui.lua" or "main_ui.lua"

-- =========================================================================
-- Hybrid Secure Module Loader
-- 1. Local filesystem (executor readfile)
-- 2. TestFork GitHub Repository (Primary direct source with live cache-busting)
-- 3. In-Memory Virtual File System (Fallback)
-- 4. Virtual require hook
-- =========================================================================
local function loadModule(path)
    local cleanName = path:gsub("%.lua$", "")

    -- 0. Local Filesystem (Direct executor file fallback)
    if type(readfile) == "function" then
        local okFs, src = pcall(readfile, path)
        if not okFs then okFs, src = pcall(readfile, "rivals/dahood/" .. path) end
        if not okFs then okFs, src = pcall(readfile, "dahood/" .. path) end
        if okFs and type(src) == "string" and #src > 0 then
            local compileOk, chunk = pcall(loadstring, src)
            if compileOk and chunk then
                local runOk, runErr = pcall(chunk)
                if runOk then return true end
                warn("[Atomware DaHood] Error executing local module " .. path .. ":", runErr)
            end
        end
    end

    -- 1. TestFork GitHub Repository (Primary direct source with live cache-busting)
    local TESTFORK_URL = "https://raw.githubusercontent.com/revileDev/TestFork/main/rivals/dahood/"
    local cacheBuster = tostring(os.time()) .. "_" .. tostring(math.random(100000, 999999))
    local okTest, testSource = pcall(function()
        return game:HttpGet(TESTFORK_URL .. path .. "?v=" .. cacheBuster)
    end)
    if okTest and testSource and #testSource > 0 and not testSource:find("404: Not Found") and not testSource:find("<!DOCTYPE") then
        local compileOk, chunk, compileErr = pcall(loadstring, testSource)
        if compileOk and chunk then
            local runOk, runErr = pcall(chunk)
            if runOk then return true end
            warn("[Atomware DaHood] Error running module from TestFork (" .. path .. "):", runErr)
        else
            warn("[Atomware DaHood] Error compiling module from TestFork (" .. path .. "):", compileErr)
        end
    end

    -- 2. In-Memory Virtual File System (Fallback)
    if type(__VFS_MODULES) == "table" then
        local loader = __VFS_MODULES[path] or __VFS_MODULES[cleanName]
        if loader then
            local ok, err = pcall(loader)
            if ok then return true end
            warn("[Atomware DaHood] Failed to execute in-memory module " .. path .. ":", err)
        end
    end

    -- 3. Virtual require hook
    if type(require) == "function" then
        local ok, res = pcall(require, cleanName)
        if ok and res ~= nil then
            return true
        end
    end

    warn("[Atomware DaHood] Could not load module: " .. path)
    return false
end

-- 1. Load Cleanup Manager & Shared Configuration
if not loadModule("cleanup.lua") then
    warn("[Atomware DaHood] cleanup manager could not be loaded; startup aborted.")
    return
end
if not loadModule("config.lua") then
    warn("[Atomware DaHood] shared configuration could not be loaded; startup aborted.")
    return
end

_G.AtomwareUnload = function()
    local player = Players.LocalPlayer
    local playerGui = player and player:FindFirstChild("PlayerGui")
    local cg = game:GetService("CoreGui")
    local gui = playerGui and (playerGui:FindFirstChild("AtomwareDaHoodUI") or playerGui:FindFirstChild("AtomwareMobileDaHoodUI"))
    if not gui then
        -- Also check gethui parent
        pcall(function()
            local h = gethui and gethui()
            if h then
                gui = h:FindFirstChild("AtomwareDaHoodUI") or h:FindFirstChild("AtomwareMobileDaHoodUI")
            end
        end)
    end
    if _G.AtomwareConfig then
        _G.AtomwareConfig:Unload(gui)
    elseif gui then
        gui:Destroy()
    end
    _G.AtomwareUILoaded = nil
    _G.AtomwareFeaturesLoaded = nil
    _G.AtomwareWindow = nil
    _G.AtomwareEvents = nil
    _G.OnToggle = nil
end

-- 2. Load Platform UI (mobile_ui.lua vs main_ui.lua)
if not loadModule(targetUIFile) then
    if _G.AtomwareUnload then pcall(_G.AtomwareUnload) end
    return
end

-- 3. Wait for UI hooks to initialize (timeout after 15 s)
local uiWaitCount = 0
repeat
    task.wait()
    uiWaitCount = uiWaitCount + 1
    if uiWaitCount > 900 then
        warn("[Atomware DaHood] UI failed to initialise after 15s — aborting.")
        if _G.AtomwareUnload then pcall(_G.AtomwareUnload) end
        return
    end
until _G.AtomwareUILoaded and _G.AtomwareWindow

-- 4. Load Features Backend Engine
if not loadModule("features.lua") then
    warn("[Atomware DaHood] features backend could not be loaded; cleaning up startup.")
    if _G.AtomwareUnload then pcall(_G.AtomwareUnload) end
    return
end

-- 5. Verify everything is online (timeout after 15 s)
local verifyCount = 0
repeat
    task.wait()
    verifyCount = verifyCount + 1
    if verifyCount > 900 then
        warn("[Atomware DaHood] Features failed to mark loaded after 15s — check features.lua for errors.")
        break
    end
until _G.AtomwareUILoaded and _G.AtomwareFeaturesLoaded

-- 6. Confirmation Toast & Print
local modeTag = IS_MOBILE and "Mobile" or "PC"
if _G.AtomwareConfig and _G.AtomwareConfig.Notify then
    _G.AtomwareConfig:Notify("Atomware DaHood Loaded (" .. modeTag .. ")", 4)
end
print("[Atomware DaHood] Fully Initialized on " .. modeTag .. "!")
