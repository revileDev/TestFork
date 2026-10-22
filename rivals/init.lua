--[[
    Atomware Rivals - init.lua
    Universal Master Initializer for Atomware Rivals
    Connected to TestFork Repository (https://github.com/revileDev/TestFork)
    Automatically detects platform (Mobile Touch vs Desktop PC) and loads dedicated UI + Features Backend.
]]

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- Game Verification Guard (Rivals Place ID: 17625359962)
local SUPPORTED_PLACE_ID = 17625359962

local function checkGameSupported()
    if game.PlaceId == SUPPORTED_PLACE_ID or tostring(game.PlaceId) == "17625359962" or game.GameId == 6035872082 then
        return true
    end

    -- 1. Native StarterGui Notification
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Atomware Rivals",
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

    warn("[Atomware] this game is not supported (Current PlaceId: " .. tostring(game.PlaceId) .. ", Required: " .. tostring(SUPPORTED_PLACE_ID) .. ")")
    return false
end

if not checkGameSupported() then
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

-- Platform Detection & Low-End Device Advisory Middleware
local IS_MOBILE = UserInputService.TouchEnabled
local isLiteMode = false
local targetUIFile = "main_ui.lua"

if IS_MOBILE then
    local CONFIG_FOLDER = "Atomware"
    local PREF_FILE = CONFIG_FOLDER .. "/lite_mode_preference.json"
    local hasFs = type(readfile) == "function" and type(writefile) == "function"
    
    local savedPref = nil
    if hasFs then
        pcall(function()
            if readfile(PREF_FILE) then
                local data = tostring(readfile(PREF_FILE)):lower()
                if data:find("lite") then savedPref = "lite"
                elseif data:find("full") then savedPref = "full"
                end
            end
        end)
    end
    
    if _G.AtomwareForceLite == true or savedPref == "lite" then
        isLiteMode = true
        targetUIFile = "mobile_lite.lua"
    elseif _G.AtomwareForceFull == true or savedPref == "full" then
        isLiteMode = false
        targetUIFile = "mobile_ui.lua"
    else
        -- Hardware & Telemetry Evaluation for Lower-End Devices (3GB RAM or less)
        local isLowEnd = false
        pcall(function()
            local Stats = game:GetService("Stats")
            local totalMem = Stats and Stats:GetTotalMemoryUsageMb() or 0
            local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.zero
            if totalMem < 550 or totalMem > 1150 or (vp.X > 0 and (vp.X <= 1024 or vp.Y <= 768)) then
                isLowEnd = true
            end
        end)
        
        -- Modal Advisory UI
        local function showAdvisoryModal(): string
            local gethui = gethui or function() return nil end
            local parent = gethui() or game:GetService("CoreGui") or (Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui"))
            if not parent then return "mobile_lite.lua" end
            
            local oldPrompt = parent:FindFirstChild("Atomware_DeviceAdvisory")
            if oldPrompt then pcall(function() oldPrompt:Destroy() end) end
            
            local sg = Instance.new("ScreenGui")
            sg.Name = "Atomware_DeviceAdvisory"
            sg.ResetOnSpawn = false
            sg.DisplayOrder = 999999
            sg.Parent = parent
            
            -- Dark blurred backdrop
            local backdrop = Instance.new("TextButton")
            backdrop.Size = UDim2.fromScale(1, 1)
            backdrop.BackgroundColor3 = Color3.fromRGB(4, 3, 8)
            backdrop.BackgroundTransparency = 0.35
            backdrop.Text = ""
            backdrop.AutoButtonColor = false
            backdrop.Parent = sg
            
            -- Modal Card
            local card = Instance.new("Frame")
            card.AnchorPoint = Vector2.new(0.5, 0.5)
            card.Position = UDim2.fromScale(0.5, 0.5)
            card.Size = UDim2.fromOffset(360, 240)
            card.BackgroundColor3 = Color3.fromRGB(12, 8, 22)
            card.BorderSizePixel = 0
            card.Parent = sg
            
            local cardCorner = Instance.new("UICorner")
            cardCorner.CornerRadius = UDim.new(0, 12)
            cardCorner.Parent = card
            
            local cardStroke = Instance.new("UIStroke")
            cardStroke.Color = Color3.fromRGB(157, 48, 255)
            cardStroke.Thickness = 1.5
            cardStroke.Parent = card
            
            -- Header
            local header = Instance.new("Frame")
            header.Size = UDim2.new(1, 0, 0, 42)
            header.BackgroundColor3 = Color3.fromRGB(18, 12, 32)
            header.BorderSizePixel = 0
            header.Parent = card
            
            local hCorner = Instance.new("UICorner")
            hCorner.CornerRadius = UDim.new(0, 12)
            hCorner.Parent = header
            
            local titleLbl = Instance.new("TextLabel")
            titleLbl.Size = UDim2.new(1, -24, 1, 0)
            titleLbl.Position = UDim2.fromOffset(14, 0)
            titleLbl.BackgroundTransparency = 1
            titleLbl.Text = "ATOMWARE SYSTEM ADVISORY"
            titleLbl.TextColor3 = Color3.fromRGB(205, 104, 255)
            titleLbl.TextSize = 12
            titleLbl.Font = Enum.Font.GothamBold
            titleLbl.TextXAlignment = Enum.TextXAlignment.Left
            titleLbl.Parent = header
            
            -- Body Description
            local desc = Instance.new("TextLabel")
            desc.Size = UDim2.new(1, -28, 0, 56)
            desc.Position = UDim2.fromOffset(14, 50)
            desc.BackgroundTransparency = 1
            desc.Text = "We detected you are on a lower-end device (3GB RAM or less). We suggest Lite Mode for best performance, smoother frame rates, and zero crashes."
            desc.TextColor3 = Color3.fromRGB(235, 225, 250)
            desc.TextSize = 11
            desc.Font = Enum.Font.GothamMedium
            desc.TextWrapped = true
            desc.TextXAlignment = Enum.TextXAlignment.Left
            desc.TextYAlignment = Enum.TextYAlignment.Top
            desc.Parent = card
            
            -- Button 1: Enable Lite Mode (Recommended) with animated countdown
            local liteBtn = Instance.new("TextButton")
            liteBtn.Size = UDim2.new(1, -28, 0, 36)
            liteBtn.Position = UDim2.fromOffset(14, 114)
            liteBtn.BackgroundColor3 = Color3.fromRGB(105, 35, 185)
            liteBtn.Text = "Enable Lite Mode (Recommended) (6s)"
            liteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            liteBtn.TextSize = 12
            liteBtn.Font = Enum.Font.GothamBold
            liteBtn.AutoButtonColor = false
            liteBtn.Parent = card
            
            local bCorner = Instance.new("UICorner")
            bCorner.CornerRadius = UDim.new(0, 8)
            bCorner.Parent = liteBtn
            
            local bStroke = Instance.new("UIStroke")
            bStroke.Color = Color3.fromRGB(205, 104, 255)
            bStroke.Thickness = 1.2
            bStroke.Parent = liteBtn
            
            -- Button 2: Continue with Full Version
            local fullBtn = Instance.new("TextButton")
            fullBtn.Size = UDim2.new(1, -28, 0, 32)
            fullBtn.Position = UDim2.fromOffset(14, 158)
            fullBtn.BackgroundColor3 = Color3.fromRGB(24, 16, 40)
            fullBtn.Text = "Continue with Full Version"
            fullBtn.TextColor3 = Color3.fromRGB(170, 155, 205)
            fullBtn.TextSize = 11
            fullBtn.Font = Enum.Font.GothamMedium
            fullBtn.AutoButtonColor = false
            fullBtn.Parent = card
            
            local fCorner = Instance.new("UICorner")
            fCorner.CornerRadius = UDim.new(0, 8)
            fCorner.Parent = fullBtn
            
            -- Checkbox: Remember Choice
            local rememberChoice = true
            local remBtn = Instance.new("TextButton")
            remBtn.Size = UDim2.new(1, -28, 0, 20)
            remBtn.Position = UDim2.fromOffset(14, 200)
            remBtn.BackgroundTransparency = 1
            remBtn.Text = "[✓] Remember my choice for future sessions"
            remBtn.TextColor3 = Color3.fromRGB(180, 160, 220)
            remBtn.TextSize = 10
            remBtn.Font = Enum.Font.GothamMedium
            remBtn.TextXAlignment = Enum.TextXAlignment.Left
            remBtn.Parent = card
            
            remBtn.MouseButton1Click:Connect(function()
                rememberChoice = not rememberChoice
                remBtn.Text = (rememberChoice and "[✓] " or "[ ] ") .. "Remember my choice for future sessions"
                remBtn.TextColor3 = rememberChoice and Color3.fromRGB(205, 104, 255) or Color3.fromRGB(120, 110, 150)
            end)
            
            local decision = nil
            liteBtn.MouseButton1Click:Connect(function() decision = "mobile_lite.lua" end)
            fullBtn.MouseButton1Click:Connect(function() decision = "mobile_ui.lua" end)
            
            -- 6s Auto Selection Thread
            task.spawn(function()
                for i = 6, 1, -1 do
                    if decision ~= nil or not sg.Parent then break end
                    liteBtn.Text = "Enable Lite Mode (Recommended) (" .. tostring(i) .. "s)"
                    task.wait(1)
                end
                if decision == nil then
                    decision = "mobile_lite.lua"
                end
            end)
            
            while decision == nil do
                task.wait(0.05)
            end
            
            if rememberChoice and hasFs then
                pcall(function()
                    local isF = type(isfolder) == "function" and isfolder
                    local makeF = type(makefolder) == "function" and makefolder
                    if makeF and isF and not isF(CONFIG_FOLDER) then makeF(CONFIG_FOLDER) end
                    writefile(PREF_FILE, decision == "mobile_lite.lua" and "lite" or "full")
                end)
            end
            
            pcall(function() sg:Destroy() end)
            return decision
        end
        
        targetUIFile = showAdvisoryModal()
        isLiteMode = (targetUIFile == "mobile_lite.lua")
    end
end

-- =========================================================================
-- Hybrid Secure Module Loader
-- 1. Direct TestFork GitHub loader with dynamic cache-busting
-- 2. In-Memory Virtual File System (Fallback)
-- 3. Virtual require hook
-- =========================================================================
local function loadModule(path)
    local cleanName = path:gsub("%.lua$", "")

    -- 1. TestFork GitHub Repository (Primary direct source with live cache-busting)
    local TESTFORK_URL = "https://raw.githubusercontent.com/revileDev/TestFork/main/rivals/"
    local cacheBuster = tostring(os.time()) .. "_" .. tostring(math.random(100000, 999999))
    local okTest, testSource = pcall(function()
        return game:HttpGet(TESTFORK_URL .. path .. "?v=" .. cacheBuster)
    end)
    if okTest and testSource and #testSource > 0 and not testSource:find("404: Not Found") and not testSource:find("<!DOCTYPE") then
        local compileOk, chunk, compileErr = pcall(loadstring, testSource)
        if compileOk and chunk then
            local runOk, runErr = pcall(chunk)
            if runOk then return true end
            warn("[Atomware Rivals] Error running module from TestFork (" .. path .. "):", runErr)
        else
            warn("[Atomware Rivals] Error compiling module from TestFork (" .. path .. "):", compileErr)
        end
    end

    -- 2. In-Memory Virtual File System (Fallback)
    if type(__VFS_MODULES) == "table" then
        local loader = __VFS_MODULES[path] or __VFS_MODULES[cleanName]
        if loader then
            local ok, err = pcall(loader)
            if ok then return true end
            warn("[Atomware Rivals] Failed to execute in-memory module " .. path .. ":", err)
        end
    end

    -- 3. Virtual require hook
    if type(require) == "function" then
        local ok, res = pcall(require, cleanName)
        if ok and res ~= nil then
            return true
        end
    end

    warn("[Atomware Rivals] Could not load module: " .. path)
    return false
end

-- 1. Load Cleanup Manager & Shared Configuration
if not loadModule("cleanup.lua") then
    warn("[Atomware Rivals] cleanup manager could not be loaded; startup aborted.")
    return
end
if not loadModule("config.lua") then
    warn("[Atomware Rivals] shared configuration could not be loaded; startup aborted.")
    return
end

_G.AtomwareUnload = function()
    local player = Players.LocalPlayer
    local playerGui = player and player:FindFirstChild("PlayerGui")
    local cg = game:GetService("CoreGui")
    local gui = playerGui and (playerGui:FindFirstChild("AtomwareRivalsUI") or playerGui:FindFirstChild("AtomwareMobileRivalsUI"))
    if _G.AtomwareConfig then
        _G.AtomwareConfig:Unload(gui)
    elseif gui then
        gui:Destroy()
    end
    pcall(function()
        local cw = (playerGui and playerGui:FindFirstChild("Atomware_ChatroomWidget")) or (cg and cg:FindFirstChild("Atomware_ChatroomWidget"))
        if cw then cw:Destroy() end
        local sw = (playerGui and playerGui:FindFirstChild("Atomware_SearchWidget")) or (cg and cg:FindFirstChild("Atomware_SearchWidget"))
        if sw then sw:Destroy() end
    end)
    _G.AtomwareChatroomLoaded = nil
    _G.AtomwareUILoaded = nil
    _G.AtomwareFeaturesLoaded = nil
    _G.AtomwareWindow = nil
    _G.AtomwareEvents = nil
    _G.OnToggle = nil
end

-- 2. Load Cosmetics Subsystem (Omitted in Lite Mode to minimize memory usage)
if not isLiteMode then
    if not loadModule("cosmetics.lua") then
        warn("[Atomware Rivals] cosmetics subsystem could not be loaded; continuing.")
    end
end

-- 3. Load Platform UI (mobile_ui.lua vs main_ui.lua)
if not loadModule(targetUIFile) then
    if _G.AtomwareUnload then pcall(_G.AtomwareUnload) end
    return
end

-- 4. Wait for UI hooks to initialize (timeout after 15 s)
local uiWaitCount = 0
repeat
    task.wait()
    uiWaitCount = uiWaitCount + 1
    if uiWaitCount > 900 then
        warn("[Atomware Rivals] UI failed to initialise after 15s — aborting.")
        if _G.AtomwareUnload then pcall(_G.AtomwareUnload) end
        return
    end
until _G.AtomwareUILoaded and _G.AtomwareWindow

-- 5. Load Features Backend Engine
if not loadModule("features.lua") then
    warn("[Atomware Rivals] features backend could not be loaded; cleaning up startup.")
    if _G.AtomwareUnload then pcall(_G.AtomwareUnload) end
    return
end

-- 6. Verify everything is online (timeout after 15 s)
local verifyCount = 0
repeat
    task.wait()
    verifyCount = verifyCount + 1
    if verifyCount > 900 then
        warn("[Atomware Rivals] Features failed to mark loaded after 15s — check features.lua for errors.")
        break
    end
until _G.AtomwareUILoaded and _G.AtomwareFeaturesLoaded

-- 7. Confirmation Toast & Print
local modeTag = if isLiteMode then "Mobile Lite" elseif IS_MOBILE then "Mobile" else "PC"
if _G.AtomwareConfig and _G.AtomwareConfig.Notify then
    _G.AtomwareConfig:Notify("Atomware Rivals Loaded (" .. modeTag .. ")", 4)
end
print("[Atomware Rivals] Fully Initialized on " .. modeTag .. "!")

-- 8. Load Atomware Chatroom Widget
task.spawn(function()
    pcall(function()
        loadModule("chatroom_widget.lua")
    end)
end)
