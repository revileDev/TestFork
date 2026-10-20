--[[
    AtomWare Key Authentication Prompt Module
    Presents responsive key entry modal before script execution
    Key: THEBESTFIXED
    Discord: https://discord.gg/AeCYnnQmq5
]]

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local CORRECT_KEY = "THEBESTFIXED"
local DISCORD_INVITE = "https://discord.gg/AeCYnnQmq5"

local AuthPrompt = {}

local function getGuiParent()
    local success, target = pcall(function()
        return CoreGui
    end)
    if success and target then
        return target
    end
    return PlayerGui
end

local function safeCopyClipboard(text)
    local fn = setclipboard or toclipboard or writeclipboard
    if typeof(fn) == "function" then
        pcall(fn, text)
        return true
    end
    if typeof(clipboard) == "table" and typeof(clipboard.set) == "function" then
        pcall(clipboard.set, text)
        return true
    end
    return false
end

function AuthPrompt:Prompt(gameName, placeId, notificationModule, telemetryModule, onSuccess)
    -- Check if session already authenticated
    if _G.AtomwareAuthed == true then
        if typeof(onSuccess) == "function" then
            onSuccess()
        end
        return
    end

    local parent = getGuiParent()
    local old = parent:FindFirstChild("Atomware_AuthPrompt")
    if old then
        old:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "Atomware_AuthPrompt"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 1000
    screenGui.Parent = parent

    -- Dim backdrop
    local backdrop = Instance.new("Frame")
    backdrop.Name = "Backdrop"
    backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backdrop.BackgroundTransparency = 0.5
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.Parent = screenGui

    -- Modal card
    local card = Instance.new("Frame")
    card.Name = "AuthCard"
    card.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.Position = UDim2.new(0.5, 0, 0.5, 0)
    card.Size = UDim2.new(0, 360, 0, 250)
    card.ClipsDescendants = true
    card.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Name = "CardStroke"
    stroke.Color = Color3.fromRGB(51, 65, 85)
    stroke.Thickness = 1.5
    stroke.Parent = card

    -- Header accent line
    local topBar = Instance.new("Frame")
    topBar.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
    topBar.Size = UDim2.new(1, 0, 0, 3)
    topBar.BorderSizePixel = 0
    topBar.Parent = card

    -- Title
    local titleLbl = Instance.new("TextLabel")
    titleLbl.BackgroundTransparency = 1
    titleLbl.Position = UDim2.new(0, 20, 0, 16)
    titleLbl.Size = UDim2.new(1, -40, 0, 24)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.Text = "⚡ AtomWare — Key Required"
    titleLbl.TextColor3 = Color3.fromRGB(248, 250, 252)
    titleLbl.TextSize = 16
    titleLbl.TextXAlignment = Enum.TextXAlignment.Center
    titleLbl.Parent = card

    -- Subtitle
    local subLbl = Instance.new("TextLabel")
    subLbl.BackgroundTransparency = 1
    subLbl.Position = UDim2.new(0, 20, 0, 42)
    subLbl.Size = UDim2.new(1, -40, 0, 32)
    subLbl.Font = Enum.Font.Gotham
    subLbl.Text = string.format("Join our Discord to get the free key for:\n%s", tostring(gameName or "Supported Game"))
    subLbl.TextColor3 = Color3.fromRGB(148, 163, 184)
    subLbl.TextSize = 11
    subLbl.TextWrapped = true
    subLbl.TextXAlignment = Enum.TextXAlignment.Center
    subLbl.Parent = card

    -- Key input box container
    local inputContainer = Instance.new("Frame")
    inputContainer.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
    inputContainer.Position = UDim2.new(0, 24, 0, 84)
    inputContainer.Size = UDim2.new(1, -48, 0, 40)
    inputContainer.Parent = card

    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 8)
    inputCorner.Parent = inputContainer

    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = Color3.fromRGB(51, 65, 85)
    inputStroke.Thickness = 1
    inputStroke.Parent = inputContainer

    local textBox = Instance.new("TextBox")
    textBox.BackgroundTransparency = 1
    textBox.Position = UDim2.new(0, 12, 0, 0)
    textBox.Size = UDim2.new(1, -24, 1, 0)
    textBox.Font = Enum.Font.GothamBold
    textBox.PlaceholderText = "Enter key here..."
    textBox.PlaceholderColor3 = Color3.fromRGB(100, 116, 139)
    textBox.Text = ""
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.TextSize = 13
    textBox.ClearTextOnFocus = false
    textBox.Parent = inputContainer

    -- Verify Button
    local btnVerify = Instance.new("TextButton")
    btnVerify.Name = "BtnVerify"
    btnVerify.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
    btnVerify.Position = UDim2.new(0, 24, 0, 136)
    btnVerify.Size = UDim2.new(1, -48, 0, 40)
    btnVerify.Font = Enum.Font.GothamBold
    btnVerify.Text = "🔓 Verify Key"
    btnVerify.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnVerify.TextSize = 13
    btnVerify.AutoButtonColor = false
    btnVerify.Parent = card

    local vCorner = Instance.new("UICorner")
    vCorner.CornerRadius = UDim.new(0, 8)
    vCorner.Parent = btnVerify

    -- Join Discord Button
    local btnDiscord = Instance.new("TextButton")
    btnDiscord.Name = "BtnDiscord"
    btnDiscord.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    btnDiscord.Position = UDim2.new(0, 24, 0, 186)
    btnDiscord.Size = UDim2.new(1, -48, 0, 38)
    btnDiscord.Font = Enum.Font.GothamBold
    btnDiscord.Text = "📋 Join Discord (Copy Link)"
    btnDiscord.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnDiscord.TextSize = 12
    btnDiscord.AutoButtonColor = false
    btnDiscord.Parent = card

    local dCorner = Instance.new("UICorner")
    dCorner.CornerRadius = UDim.new(0, 8)
    dCorner.Parent = btnDiscord

    -- Button hover/press animations
    local function setupHover(btn, normalColor, hoverColor)
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = hoverColor }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = normalColor }):Play()
        end)
    end
    setupHover(btnVerify, Color3.fromRGB(16, 185, 129), Color3.fromRGB(5, 150, 105))
    setupHover(btnDiscord, Color3.fromRGB(88, 101, 242), Color3.fromRGB(71, 82, 196))

    -- Copy Discord Logic
    btnDiscord.MouseButton1Click:Connect(function()
        local copied = safeCopyClipboard(DISCORD_INVITE)
        if notificationModule then
            notificationModule:Show("Discord Copied", "discord.gg/AeCYnnQmq5 copied to clipboard!", 3.5, "Success")
        end
        btnDiscord.Text = "✓ Copied to Clipboard!"
        task.delay(2, function()
            if btnDiscord and btnDiscord.Parent then
                btnDiscord.Text = "📋 Join Discord (Copy Link)"
            end
        end)
    end)

    -- Verification Logic
    local isVerifying = false
    local function verify()
        if isVerifying then return end
        isVerifying = true

        local entered = textBox.Text:gsub("^%s*(.-)%s*$", "%1")
        if entered == CORRECT_KEY then
            _G.AtomwareAuthed = true

            if telemetryModule then
                telemetryModule:SendAuthLog(gameName, placeId, true, "Key THEBESTFIXED validated")
            end
            if notificationModule then
                notificationModule:Show("Auth Success", "Key verified successfully! Loading script...", 2.5, "Success")
            end

            btnVerify.Text = "✓ Verified!"
            btnVerify.BackgroundColor3 = Color3.fromRGB(5, 150, 105)

            task.delay(0.6, function()
                if screenGui and screenGui.Parent then
                    screenGui:Destroy()
                end
                if typeof(onSuccess) == "function" then
                    onSuccess()
                end
            end)
        else
            if telemetryModule then
                telemetryModule:SendAuthLog(gameName, placeId, false, "Invalid key entered: '" .. entered .. "'")
            end
            if notificationModule then
                notificationModule:Show("Invalid Key", "Incorrect key! Join Discord to get the free key.", 4.0, "Error")
            end

            -- Shake animation on failure
            stroke.Color = Color3.fromRGB(239, 68, 68)
            local originalPos = card.Position
            task.spawn(function()
                for i = 1, 3 do
                    card.Position = originalPos + UDim2.new(0, 8, 0, 0)
                    task.wait(0.04)
                    card.Position = originalPos - UDim2.new(0, 8, 0, 0)
                    task.wait(0.04)
                end
                card.Position = originalPos
                task.wait(1.5)
                if stroke and stroke.Parent then
                    stroke.Color = Color3.fromRGB(51, 65, 85)
                end
                isVerifying = false
            end)
        end
    end

    btnVerify.MouseButton1Click:Connect(verify)
    textBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            verify()
        end
    end)

    -- Pop-in tween
    card.Position = UDim2.new(0.5, 0, 0.45, 0)
    card.BackgroundTransparency = 1
    TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 0
    }):Play()
end

return AuthPrompt
