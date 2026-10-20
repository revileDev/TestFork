--[[
    AtomWare Giant Script Hub (407+ Games) - Core Orchestrator Module
    Auto-detects game by PlaceId, verifies auth key, runs loadstring,
    mounts persistent watermark and draggable search/gamehop widget.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local function getGuiParent()
    local success, target = pcall(function()
        return CoreGui
    end)
    if success and target then
        return target
    end
    return PlayerGui
end

local function runAtomwareHub(GamesDatabase, Notification, Telemetry, AuthPrompt, SearchWidget, Watermark)
    -- Guard against duplicate executions
    if _G.AtomwareHubLoaded == true then
        if Notification then
            Notification:Show("AtomWare Active", "AtomWare is already running! Use the 🔍 icon.", 3, "Info")
        end
        return
    end
    _G.AtomwareHubLoaded = true

    -- Initialize Watermark & Floating Search Widget immediately
    Watermark:Init()
    SearchWidget:Init(GamesDatabase, Notification, AuthPrompt, Telemetry)

    -- Auto-detect Current Game
    local currentPlaceId = game.PlaceId
    local matchedGame = GamesDatabase:GetByPlaceId(currentPlaceId)

    if matchedGame then
        Notification:Show("Game Detected", "Supported game found: " .. matchedGame.Name, 4, "Info")

        -- Prompt Key Authentication before executing loadstring
        AuthPrompt:Prompt(matchedGame.Name, matchedGame.PlaceId, Notification, Telemetry, function()
            Notification:Show("Executing Script", "Launching " .. matchedGame.Name .. " (" .. (matchedGame.Title or "Default") .. ")...", 3, "Success")

            -- Safely execute the game loadstring
            task.spawn(function()
                local loadFunc, compileErr = loadstring(matchedGame.Loadstring)
                if not loadFunc then
                    Notification:Show("Compile Error", "Failed to compile: " .. tostring(compileErr), 5, "Error")
                    return
                end

                local ok, runErr = pcall(loadFunc)
                if not ok then
                    Notification:Show("Runtime Error", "Error executing: " .. tostring(runErr), 5, "Error")
                end
            end)
        end)
    else
        -- Game is not in the 407+ supported list
        Notification:Show(
            "Unsupported Game",
            "The game you are in (Place ID: " .. tostring(currentPlaceId) .. ") is not yet supported by AtomWare.",
            7,
            "Warning"
        )

        -- Display an informative notice modal with quick access to search
        local parent = getGuiParent()
        local noticeGui = Instance.new("ScreenGui")
        noticeGui.Name = "Atomware_UnsupportedNotice"
        noticeGui.ResetOnSpawn = false
        noticeGui.DisplayOrder = 940
        noticeGui.Parent = parent

        local modal = Instance.new("Frame")
        modal.Name = "NoticeModal"
        modal.AnchorPoint = Vector2.new(0.5, 0.5)
        modal.Position = UDim2.new(0.5, 0, 0.5, 0)
        modal.Size = UDim2.new(0, 420, 0, 220)
        modal.BackgroundColor3 = Color3.fromRGB(20, 22, 32)
        modal.BorderSizePixel = 0
        modal.Parent = noticeGui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = modal

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(240, 160, 40)
        stroke.Thickness = 1.5
        stroke.Parent = modal

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -32, 0, 30)
        title.Position = UDim2.new(0, 16, 0, 16)
        title.BackgroundTransparency = 1
        title.Text = "⚠️ Game Not Supported Yet"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 18
        title.TextXAlignment = Enum.TextXAlignment.Center
        title.Parent = modal

        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(1, -32, 0, 60)
        desc.Position = UDim2.new(0, 16, 0, 52)
        desc.BackgroundTransparency = 1
        desc.Text = "The game you are in (Place ID: " .. tostring(currentPlaceId) .. ") is not yet supported by AtomWare.\n\nUse the floating 🔍 button on your screen to explore 407+ supported games and hop to them!"
        desc.TextColor3 = Color3.fromRGB(170, 175, 195)
        desc.Font = Enum.Font.Gotham
        desc.TextSize = 13
        desc.TextWrapped = true
        desc.Parent = modal

        local dismissBtn = Instance.new("TextButton")
        dismissBtn.Size = UDim2.new(1, -32, 0, 40)
        dismissBtn.Position = UDim2.new(0, 16, 1, -56)
        dismissBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
        dismissBtn.Text = "Got it (Keep 🔍 Search Active)"
        dismissBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        dismissBtn.Font = Enum.Font.GothamBold
        dismissBtn.TextSize = 13
        dismissBtn.AutoButtonColor = false
        dismissBtn.Parent = modal

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = dismissBtn

        dismissBtn.MouseButton1Click:Connect(function()
            noticeGui:Destroy()
        end)
    end
end

return runAtomwareHub
