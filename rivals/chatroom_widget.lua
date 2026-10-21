--[[
    AtomWare Global Chatroom & Developer Direct Messages Widget
    - Floating draggable messaging circle (💬) with live unread badge & sound ping
    - Perfectly aligned with search widget on left dock (no overlap)
    - Tab 1: Global Live Chatroom with real Roblox player avatars, usernames, cooldown & timestamps
    - Tab 2: "Contact Your Dev" 1-on-1 direct messaging system with developer reply notifications
    - Real-time cloud sync with atomprotect.vercel.app backend & Supabase
    - Word blacklist enforcement & instant moderation filter
    - Granular settings menu: toggle chatroom, dev tab, chat notifications, dev notifications, or completely disable
]]

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer or (function()
    local p = Players.PlayerAdded:Wait()
    return p
end)()

local API_BASE = "https://atomprotect.vercel.app/api/chatroom"

local ChatroomWidget = {}

local function getGuiParent()
    local success, target = pcall(function()
        local test = Instance.new("Folder")
        test.Parent = CoreGui
        test:Destroy()
        return CoreGui
    end)
    if success and target then
        return target
    end
    local lp = Players.LocalPlayer
    if lp then
        return lp:FindFirstChild("PlayerGui") or lp:WaitForChild("PlayerGui", 5)
    end
    return nil
end

local function safeHttpRequest(url, method, body, headers)
    method = method or "GET"
    headers = headers or { ["Content-Type"] = "application/json" }

    -- 1. Try executor custom request methods
    local reqFn = request or http_request or (syn and syn.request) or (http and http.request)
    if type(reqFn) == "function" then
        local ok, response = pcall(reqFn, {
            Url = url,
            Method = method,
            Headers = headers,
            Body = body
        })
        if ok and response then
            local status = response.StatusCode or response.Status or 200
            local resBody = response.Body or response.body or ""
            return (status >= 200 and status < 300), resBody, status
        end
    end

    -- 2. Fallback to game:HttpGet for GET requests
    if method == "GET" then
        local ok, resBody = pcall(function()
            return game:HttpGet(url)
        end)
        if ok and type(resBody) == "string" then
            return true, resBody, 200
        end
    end

    -- 3. Fallback to game:HttpPost for POST requests
    if method == "POST" and type(body) == "string" then
        local ok, resBody = pcall(function()
            return game:HttpPost(url, body, "application/json")
        end)
        if ok and type(resBody) == "string" then
            return true, resBody, 200
        end
    end

    return false, nil, 0
end

local function formatTimestamp(isoString)
    if not isoString or type(isoString) ~= "string" then
        return os.date("%I:%M %p")
    end
    local hour, min = isoString:match("(%d%d):(%d%d)")
    if hour and min then
        local h = tonumber(hour)
        local ampm = h >= 12 and "PM" or "AM"
        local h12 = h % 12
        if h12 == 0 then h12 = 12 end
        return string.format("%d:%s %s", h12, min, ampm)
    end
    return os.date("%I:%M %p")
end

function ChatroomWidget:Init(NotificationModule)
    -- Guard against duplicate mount
    if _G.AtomwareChatroomLoaded == true then return end
    _G.AtomwareChatroomLoaded = true

    local parent = getGuiParent()
    if not parent then return end

    local old = parent:FindFirstChild("Atomware_ChatroomWidget")
    if old then
        old:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "Atomware_ChatroomWidget"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 955
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = parent

    -- Widget State
    local isOpen = false
    local activeTab = "global" -- "global" | "dev"
    local unreadCount = 0
    local isGlobalChatEnabled = true
    local isDevTabEnabled = true
    local isGlobalNotificationsEnabled = true
    local isDevNotificationsEnabled = true
    local isMasterMuted = false
    local clientCooldownSeconds = 5
    local lastSentTime = 0
    local lastGlobalTimestamp = nil
    local lastDevTimestamp = nil
    local isPolling = true

    --------------------------------------------------------------------------
    -- 1. FLOATING CHAT BUTTON (💬 Solid obsidian circle, vertically stacked under search)
    --------------------------------------------------------------------------
    local floatBtn = Instance.new("TextButton")
    floatBtn.Name = "FloatingChatButton"
    floatBtn.Size = UDim2.new(0, 48, 0, 48)
    -- Placed at X: 20px, Y: 45% + 28px (Search button is at X: 20px, Y: 45% - 28px) -> NEVER OVERLAP!
    floatBtn.Position = UDim2.new(0, 20, 0.45, 28)
    floatBtn.BackgroundColor3 = Color3.fromRGB(28, 30, 40)
    floatBtn.BorderSizePixel = 0
    floatBtn.Text = "💬"
    floatBtn.TextSize = 20
    floatBtn.AutoButtonColor = false
    floatBtn.ClipsDescendants = false
    floatBtn.Parent = screenGui

    local floatCorner = Instance.new("UICorner")
    floatCorner.CornerRadius = UDim.new(1, 0)
    floatCorner.Parent = floatBtn

    local floatStroke = Instance.new("UIStroke")
    floatStroke.Color = Color3.fromRGB(50, 55, 75)
    floatStroke.Thickness = 1.5
    floatStroke.Parent = floatBtn

    -- Red Unread Badge
    local unreadBadge = Instance.new("Frame")
    unreadBadge.Name = "UnreadBadge"
    unreadBadge.Size = UDim2.new(0, 18, 0, 18)
    unreadBadge.Position = UDim2.new(1, -12, 0, -4)
    unreadBadge.BackgroundColor3 = Color3.fromRGB(239, 68, 68) -- Bright red
    unreadBadge.BorderSizePixel = 0
    unreadBadge.Visible = false
    unreadBadge.Parent = floatBtn

    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(1, 0)
    badgeCorner.Parent = unreadBadge

    local badgeLabel = Instance.new("TextLabel")
    badgeLabel.BackgroundTransparency = 1
    badgeLabel.Size = UDim2.new(1, 0, 1, 0)
    badgeLabel.Font = Enum.Font.GothamBold
    badgeLabel.Text = "0"
    badgeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    badgeLabel.TextSize = 10
    badgeLabel.Parent = unreadBadge

    local function updateBadge(delta)
        unreadCount = math.max(0, unreadCount + delta)
        if unreadCount > 0 and not isOpen then
            badgeLabel.Text = unreadCount > 99 and "99+" or tostring(unreadCount)
            unreadBadge.Visible = true
        else
            unreadBadge.Visible = false
        end
    end

    --------------------------------------------------------------------------
    -- 2. FLOATING OBSIDIAN MODAL (No background blur/dim)
    --------------------------------------------------------------------------
    local chatModal = Instance.new("Frame")
    chatModal.Name = "ChatModal"
    chatModal.Size = UDim2.new(0, 420, 0, 520)
    chatModal.AnchorPoint = Vector2.new(0.5, 0.5)
    chatModal.Position = UDim2.new(0.5, 0, 0.5, 0)
    chatModal.BackgroundColor3 = Color3.fromRGB(15, 13, 22) -- Deep obsidian
    chatModal.BorderSizePixel = 0
    chatModal.Visible = false
    chatModal.ClipsDescendants = true
    chatModal.Parent = screenGui

    -- Responsiveness on mobile
    local camera = workspace.CurrentCamera
    local function adjustModalSize()
        if camera and camera.ViewportSize.X > 0 then
            local maxX = math.min(camera.ViewportSize.X - 24, 420)
            local maxY = math.min(camera.ViewportSize.Y - 40, 540)
            chatModal.Size = UDim2.new(0, maxX, 0, maxY)
        end
    end
    adjustModalSize()
    if camera then
        camera:GetPropertyChangedSignal("ViewportSize"):Connect(adjustModalSize)
    end

    local modalCorner = Instance.new("UICorner")
    modalCorner.CornerRadius = UDim.new(0, 14)
    modalCorner.Parent = chatModal

    local modalStroke = Instance.new("UIStroke")
    modalStroke.Color = Color3.fromRGB(44, 38, 64)
    modalStroke.Thickness = 1.5
    modalStroke.Parent = chatModal

    -- Header Frame
    local headerFrame = Instance.new("Frame")
    headerFrame.Name = "Header"
    headerFrame.BackgroundColor3 = Color3.fromRGB(20, 17, 30)
    headerFrame.BorderSizePixel = 0
    headerFrame.Size = UDim2.new(1, 0, 0, 48)
    headerFrame.Parent = chatModal

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 14)
    headerCorner.Parent = headerFrame

    -- Live dot
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(0, 16, 0.5, -4)
    dot.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
    dot.BorderSizePixel = 0
    dot.Parent = headerFrame

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = dot

    local headerTitle = Instance.new("TextLabel")
    headerTitle.BackgroundTransparency = 1
    headerTitle.Position = UDim2.new(0, 32, 0, 0)
    headerTitle.Size = UDim2.new(0, 95, 1, 0)
    headerTitle.Font = Enum.Font.GothamBold
    headerTitle.Text = "ATOM CHAT"
    headerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    headerTitle.TextSize = 13
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    headerTitle.Parent = headerFrame

    local headerSub = Instance.new("TextLabel")
    headerSub.BackgroundTransparency = 1
    headerSub.Position = UDim2.new(0, 130, 0, 0)
    headerSub.Size = UDim2.new(0, 140, 1, 0)
    headerSub.Font = Enum.Font.Gotham
    headerSub.Text = "|  Global Hub"
    headerSub.TextColor3 = Color3.fromRGB(156, 150, 175)
    headerSub.TextSize = 12
    headerSub.TextXAlignment = Enum.TextXAlignment.Left
    headerSub.Parent = headerFrame

    -- Settings Button (⚙️)
    local btnSettings = Instance.new("TextButton")
    btnSettings.Name = "BtnSettings"
    btnSettings.BackgroundTransparency = 1
    btnSettings.Position = UDim2.new(1, -72, 0, 8)
    btnSettings.Size = UDim2.new(0, 32, 0, 32)
    btnSettings.Font = Enum.Font.GothamBold
    btnSettings.Text = "⚙️"
    btnSettings.TextSize = 14
    btnSettings.TextColor3 = Color3.fromRGB(180, 185, 205)
    btnSettings.AutoButtonColor = false
    btnSettings.Parent = headerFrame

    -- Close Button (✕)
    local btnClose = Instance.new("TextButton")
    btnClose.Name = "BtnClose"
    btnClose.BackgroundTransparency = 1
    btnClose.Position = UDim2.new(1, -38, 0, 8)
    btnClose.Size = UDim2.new(0, 32, 0, 32)
    btnClose.Font = Enum.Font.GothamBold
    btnClose.Text = "✕"
    btnClose.TextColor3 = Color3.fromRGB(244, 95, 95)
    btnClose.TextSize = 14
    btnClose.AutoButtonColor = false
    btnClose.Parent = headerFrame

    -- Divider
    local headerDivider = Instance.new("Frame")
    headerDivider.BackgroundColor3 = Color3.fromRGB(36, 32, 52)
    headerDivider.BorderSizePixel = 0
    headerDivider.Position = UDim2.new(0, 0, 0, 48)
    headerDivider.Size = UDim2.new(1, 0, 0, 1)
    headerDivider.Parent = chatModal

    --------------------------------------------------------------------------
    -- 3. TABS SWITCHER: [💬 Global Chat] | [📩 Contact Your Dev]
    --------------------------------------------------------------------------
    local tabsFrame = Instance.new("Frame")
    tabsFrame.Name = "TabsFrame"
    tabsFrame.BackgroundColor3 = Color3.fromRGB(22, 19, 32)
    tabsFrame.BorderSizePixel = 0
    tabsFrame.Position = UDim2.new(0, 0, 0, 49)
    tabsFrame.Size = UDim2.new(1, 0, 0, 38)
    tabsFrame.Parent = chatModal

    local tabGlobalBtn = Instance.new("TextButton")
    tabGlobalBtn.Name = "TabGlobal"
    tabGlobalBtn.Size = UDim2.new(0.5, -8, 0, 30)
    tabGlobalBtn.Position = UDim2.new(0, 6, 0.5, -15)
    tabGlobalBtn.BackgroundColor3 = Color3.fromRGB(168, 85, 247) -- Active purple
    tabGlobalBtn.BorderSizePixel = 0
    tabGlobalBtn.Font = Enum.Font.GothamBold
    tabGlobalBtn.Text = "💬  Global Chatroom"
    tabGlobalBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    tabGlobalBtn.TextSize = 11
    tabGlobalBtn.AutoButtonColor = false
    tabGlobalBtn.Parent = tabsFrame

    local tabGlobalCorner = Instance.new("UICorner")
    tabGlobalCorner.CornerRadius = UDim.new(0, 8)
    tabGlobalCorner.Parent = tabGlobalBtn

    local tabDevBtn = Instance.new("TextButton")
    tabDevBtn.Name = "TabDev"
    tabDevBtn.Size = UDim2.new(0.5, -8, 0, 30)
    tabDevBtn.Position = UDim2.new(0.5, 2, 0.5, -15)
    tabDevBtn.BackgroundColor3 = Color3.fromRGB(28, 24, 42)
    tabDevBtn.BorderSizePixel = 0
    tabDevBtn.Font = Enum.Font.GothamBold
    tabDevBtn.Text = "📩  Contact Your Dev"
    tabDevBtn.TextColor3 = Color3.fromRGB(150, 145, 175)
    tabDevBtn.TextSize = 11
    tabDevBtn.AutoButtonColor = false
    tabDevBtn.Parent = tabsFrame

    local tabDevCorner = Instance.new("UICorner")
    tabDevCorner.CornerRadius = UDim.new(0, 8)
    tabDevCorner.Parent = tabDevBtn

    local function refreshTabLayout()
        if not isGlobalChatEnabled and isDevTabEnabled then
            tabGlobalBtn.Visible = false
            tabDevBtn.Visible = true
            tabDevBtn.Position = UDim2.new(0, 12, 0.5, -15)
            tabDevBtn.Size = UDim2.new(1, -24, 0, 30)
        elseif isGlobalChatEnabled and not isDevTabEnabled then
            tabDevBtn.Visible = false
            tabGlobalBtn.Visible = true
            tabGlobalBtn.Position = UDim2.new(0, 12, 0.5, -15)
            tabGlobalBtn.Size = UDim2.new(1, -24, 0, 30)
        else
            tabGlobalBtn.Visible = true
            tabDevBtn.Visible = true
            tabGlobalBtn.Size = UDim2.new(0.5, -8, 0, 30)
            tabGlobalBtn.Position = UDim2.new(0, 6, 0.5, -15)
            tabDevBtn.Size = UDim2.new(0.5, -8, 0, 30)
            tabDevBtn.Position = UDim2.new(0.5, 2, 0.5, -15)
        end
    end

    --------------------------------------------------------------------------
    -- 4. MESSAGES SCROLL CONTAINER
    --------------------------------------------------------------------------
    local messagesFrame = Instance.new("ScrollingFrame")
    messagesFrame.Name = "MessagesFrame"
    messagesFrame.BackgroundTransparency = 1
    messagesFrame.BorderSizePixel = 0
    messagesFrame.Position = UDim2.new(0, 12, 0, 92)
    messagesFrame.Size = UDim2.new(1, -24, 1, -152)
    messagesFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    messagesFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    messagesFrame.ScrollBarThickness = 3
    messagesFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 70, 110)
    messagesFrame.Parent = chatModal

    local messagesLayout = Instance.new("UIListLayout")
    messagesLayout.SortOrder = Enum.SortOrder.LayoutOrder
    messagesLayout.Padding = UDim.new(0, 8)
    messagesLayout.Parent = messagesFrame

    local function scrollToBottom()
        task.defer(function()
            messagesFrame.CanvasPosition = Vector2.new(0, 999999)
        end)
    end

    --------------------------------------------------------------------------
    -- 5. BOTTOM INPUT CONTAINER (Input Box + Send Button)
    --------------------------------------------------------------------------
    local inputContainer = Instance.new("Frame")
    inputContainer.Name = "InputContainer"
    inputContainer.BackgroundColor3 = Color3.fromRGB(24, 21, 36)
    inputContainer.BorderSizePixel = 0
    inputContainer.Position = UDim2.new(0, 12, 1, -50)
    inputContainer.Size = UDim2.new(1, -24, 0, 40)
    inputContainer.Parent = chatModal

    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 8)
    inputCorner.Parent = inputContainer

    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = Color3.fromRGB(44, 38, 64)
    inputStroke.Thickness = 1
    inputStroke.Parent = inputContainer

    local textBox = Instance.new("TextBox")
    textBox.Name = "ChatInput"
    textBox.BackgroundTransparency = 1
    textBox.Position = UDim2.new(0, 12, 0, 0)
    textBox.Size = UDim2.new(1, -80, 1, 0)
    textBox.Font = Enum.Font.Gotham
    textBox.PlaceholderText = "Say something in global chat..."
    textBox.PlaceholderColor3 = Color3.fromRGB(95, 90, 115)
    textBox.Text = ""
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.TextSize = 12
    textBox.ClearTextOnFocus = false
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.Parent = inputContainer

    local btnSend = Instance.new("TextButton")
    btnSend.Name = "BtnSend"
    btnSend.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
    btnSend.BorderSizePixel = 0
    btnSend.Position = UDim2.new(1, -66, 0.5, -14)
    btnSend.Size = UDim2.new(0, 58, 0, 28)
    btnSend.Font = Enum.Font.GothamBold
    btnSend.Text = "SEND"
    btnSend.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnSend.TextSize = 10
    btnSend.AutoButtonColor = false
    btnSend.Parent = inputContainer

    local sendCorner = Instance.new("UICorner")
    sendCorner.CornerRadius = UDim.new(0, 6)
    sendCorner.Parent = btnSend

    -- Warning Banner for Blacklisted words or errors
    local warningBanner = Instance.new("TextLabel")
    warningBanner.Name = "WarningBanner"
    warningBanner.BackgroundColor3 = Color3.fromRGB(185, 28, 28)
    warningBanner.Size = UDim2.new(1, -24, 0, 26)
    warningBanner.Position = UDim2.new(0, 12, 1, -80)
    warningBanner.Font = Enum.Font.GothamBold
    warningBanner.TextColor3 = Color3.fromRGB(255, 255, 255)
    warningBanner.TextSize = 10
    warningBanner.Visible = false
    warningBanner.ZIndex = 5
    warningBanner.Parent = chatModal

    local warnCorner = Instance.new("UICorner")
    warnCorner.CornerRadius = UDim.new(0, 6)
    warnCorner.Parent = warningBanner

    local function showWarning(msg)
        warningBanner.Text = "⚠️ " .. msg
        warningBanner.Visible = true
        task.delay(4, function()
            warningBanner.Visible = false
        end)
    end

    --------------------------------------------------------------------------
    -- 6. SETTINGS MODAL (Preferences & Feature Toggles)
    --------------------------------------------------------------------------
    local settingsModal = Instance.new("Frame")
    settingsModal.Name = "SettingsModal"
    settingsModal.Size = UDim2.new(0, 340, 0, 375)
    settingsModal.AnchorPoint = Vector2.new(0.5, 0.5)
    settingsModal.Position = UDim2.new(0.5, 0, 0.5, 0)
    settingsModal.BackgroundColor3 = Color3.fromRGB(20, 17, 30)
    settingsModal.BorderSizePixel = 0
    settingsModal.Visible = false
    settingsModal.ZIndex = 15
    settingsModal.Parent = chatModal

    local sCorner = Instance.new("UICorner")
    sCorner.CornerRadius = UDim.new(0, 12)
    sCorner.Parent = settingsModal

    local sStroke = Instance.new("UIStroke")
    sStroke.Color = Color3.fromRGB(60, 50, 90)
    sStroke.Thickness = 1.5
    sStroke.Parent = settingsModal

    local sTitle = Instance.new("TextLabel")
    sTitle.BackgroundTransparency = 1
    sTitle.Position = UDim2.new(0, 16, 0, 12)
    sTitle.Size = UDim2.new(1, -32, 0, 22)
    sTitle.Font = Enum.Font.GothamBold
    sTitle.Text = "⚙️ Chatroom Preferences"
    sTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    sTitle.TextSize = 13
    sTitle.TextXAlignment = Enum.TextXAlignment.Left
    sTitle.ZIndex = 16
    sTitle.Parent = settingsModal

    local function createToggleBtn(name, text, yPos, bgColor, txtColor)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(1, -32, 0, 32)
        btn.Position = UDim2.new(0, 16, 0, yPos)
        btn.BackgroundColor3 = bgColor or Color3.fromRGB(28, 25, 42)
        btn.Font = Enum.Font.Gotham
        btn.Text = text
        btn.TextColor3 = txtColor or Color3.fromRGB(210, 210, 230)
        btn.TextSize = 11
        btn.ZIndex = 16
        btn.AutoButtonColor = false
        btn.Parent = settingsModal

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = btn

        return btn
    end

    -- 1. Toggle Global Chat Tab
    local btnToggleGlobalTab = createToggleBtn(
        "ToggleGlobalTab",
        "💬 Global Chat Tab: Enabled",
        42,
        Color3.fromRGB(32, 28, 48),
        Color3.fromRGB(168, 85, 247)
    )

    -- 2. Toggle Contact Dev Tab
    local btnToggleDevTab = createToggleBtn(
        "ToggleDevTab",
        "📩 Contact Dev Tab: Enabled",
        80,
        Color3.fromRGB(32, 28, 48),
        Color3.fromRGB(168, 85, 247)
    )

    -- 3. Toggle Global Notifications
    local btnToggleGlobalNotif = createToggleBtn(
        "ToggleGlobalNotif",
        "🔔 Chatroom Notifications: Enabled",
        118,
        Color3.fromRGB(28, 25, 42)
    )

    -- 4. Toggle Dev Reply Notifications
    local btnToggleDevNotif = createToggleBtn(
        "ToggleDevNotif",
        "👑 Dev Reply Notifications: Enabled",
        156,
        Color3.fromRGB(28, 25, 42)
    )

    -- 5. Master Mute Toggle
    local btnMasterMute = createToggleBtn(
        "MasterMute",
        "🔕 Master Mute (All Pings): OFF",
        194,
        Color3.fromRGB(28, 25, 42)
    )

    -- 6. Completely Disable Widget Button
    local btnDisableChat = createToggleBtn(
        "DisableChat",
        "🚫 Completely Disable Chat Widget",
        232,
        Color3.fromRGB(60, 20, 30),
        Color3.fromRGB(255, 120, 120)
    )
    btnDisableChat.Font = Enum.Font.GothamBold

    -- 7. Clear Messages View
    local btnClearView = createToggleBtn(
        "ClearView",
        "🗑️ Clear In-Game Messages View",
        270,
        Color3.fromRGB(35, 25, 45),
        Color3.fromRGB(220, 180, 240)
    )

    -- Close Settings Button
    local btnCloseSettings = Instance.new("TextButton")
    btnCloseSettings.Size = UDim2.new(1, -32, 0, 32)
    btnCloseSettings.Position = UDim2.new(0, 16, 1, -44)
    btnCloseSettings.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
    btnCloseSettings.Font = Enum.Font.GothamBold
    btnCloseSettings.Text = "Save & Close Preferences"
    btnCloseSettings.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnCloseSettings.TextSize = 11
    btnCloseSettings.ZIndex = 16
    btnCloseSettings.Parent = settingsModal

    local closeSetCorner = Instance.new("UICorner")
    closeSetCorner.CornerRadius = UDim.new(0, 6)
    closeSetCorner.Parent = btnCloseSettings

    -- Button Click Handlers
    btnToggleGlobalTab.MouseButton1Click:Connect(function()
        isGlobalChatEnabled = not isGlobalChatEnabled
        if not isGlobalChatEnabled and not isDevTabEnabled then
            isDevTabEnabled = true
            btnToggleDevTab.Text = "📩 Contact Dev Tab: Enabled"
            btnToggleDevTab.TextColor3 = Color3.fromRGB(168, 85, 247)
        end

        if isGlobalChatEnabled then
            btnToggleGlobalTab.Text = "💬 Global Chat Tab: Enabled"
            btnToggleGlobalTab.TextColor3 = Color3.fromRGB(168, 85, 247)
        else
            btnToggleGlobalTab.Text = "💬 Global Chat Tab: Disabled"
            btnToggleGlobalTab.TextColor3 = Color3.fromRGB(150, 145, 170)
            if activeTab == "global" and isDevTabEnabled then
                tabDevBtn.MouseButton1Click:Fire()
            end
        end
        refreshTabLayout()
    end)

    btnToggleDevTab.MouseButton1Click:Connect(function()
        isDevTabEnabled = not isDevTabEnabled
        if not isDevTabEnabled and not isGlobalChatEnabled then
            isGlobalChatEnabled = true
            btnToggleGlobalTab.Text = "💬 Global Chat Tab: Enabled"
            btnToggleGlobalTab.TextColor3 = Color3.fromRGB(168, 85, 247)
        end

        if isDevTabEnabled then
            btnToggleDevTab.Text = "📩 Contact Dev Tab: Enabled"
            btnToggleDevTab.TextColor3 = Color3.fromRGB(168, 85, 247)
        else
            btnToggleDevTab.Text = "📩 Contact Dev Tab: Disabled"
            btnToggleDevTab.TextColor3 = Color3.fromRGB(150, 145, 170)
            if activeTab == "dev" and isGlobalChatEnabled then
                tabGlobalBtn.MouseButton1Click:Fire()
            end
        end
        refreshTabLayout()
    end)

    btnToggleGlobalNotif.MouseButton1Click:Connect(function()
        isGlobalNotificationsEnabled = not isGlobalNotificationsEnabled
        if isGlobalNotificationsEnabled then
            btnToggleGlobalNotif.Text = "🔔 Chatroom Notifications: Enabled"
            btnToggleGlobalNotif.TextColor3 = Color3.fromRGB(210, 210, 230)
        else
            btnToggleGlobalNotif.Text = "🔕 Chatroom Notifications: Muted"
            btnToggleGlobalNotif.TextColor3 = Color3.fromRGB(150, 145, 170)
        end
    end)

    btnToggleDevNotif.MouseButton1Click:Connect(function()
        isDevNotificationsEnabled = not isDevNotificationsEnabled
        if isDevNotificationsEnabled then
            btnToggleDevNotif.Text = "👑 Dev Reply Notifications: Enabled"
            btnToggleDevNotif.TextColor3 = Color3.fromRGB(210, 210, 230)
        else
            btnToggleDevNotif.Text = "🔕 Dev Reply Notifications: Muted"
            btnToggleDevNotif.TextColor3 = Color3.fromRGB(150, 145, 170)
        end
    end)

    btnMasterMute.MouseButton1Click:Connect(function()
        isMasterMuted = not isMasterMuted
        if isMasterMuted then
            btnMasterMute.Text = "🔕 Master Mute (All Pings): ON"
            btnMasterMute.TextColor3 = Color3.fromRGB(244, 95, 95)
        else
            btnMasterMute.Text = "🔕 Master Mute (All Pings): OFF"
            btnMasterMute.TextColor3 = Color3.fromRGB(210, 210, 230)
        end
    end)

    btnDisableChat.MouseButton1Click:Connect(function()
        isPolling = false
        screenGui:Destroy()
        _G.AtomwareChatroomLoaded = false
        if NotificationModule then
            NotificationModule:Show("Chatroom Disabled", "Chatroom widget has been completely disabled for this session.", 4, "Info")
        end
    end)

    btnClearView.MouseButton1Click:Connect(function()
        clearMessagesView()
        settingsModal.Visible = false
        if NotificationModule then
            NotificationModule:Show("Chat Cleared", "Message history view has been cleared for this session.", 3, "Info")
        end
    end)

    btnCloseSettings.MouseButton1Click:Connect(function()
        settingsModal.Visible = false
    end)

    btnSettings.MouseButton1Click:Connect(function()
        settingsModal.Visible = not settingsModal.Visible
    end)

    --------------------------------------------------------------------------
    -- 7. RENDER CHAT BUBBLE
    --------------------------------------------------------------------------
    local function renderMessageBubble(msgData, isDevThread)
        local row = Instance.new("Frame")
        row.Name = "Msg_" .. tostring(msgData.id or math.random(1000, 9999))
        row.BackgroundTransparency = 1
        row.Size = UDim2.new(1, 0, 0, 0)
        row.AutomaticSize = Enum.AutomaticSize.Y
        row.Parent = messagesFrame

        local isDev = (msgData.is_dev == true) or (msgData.sender_type == "dev")
        local isSelf = (tostring(msgData.user_id) == tostring(LocalPlayer.UserId) and not isDev)

        -- Avatar Image
        local avatarImg = Instance.new("ImageLabel")
        avatarImg.Name = "Avatar"
        avatarImg.Size = UDim2.new(0, 32, 0, 32)
        avatarImg.Position = UDim2.new(0, 0, 0, 2)
        avatarImg.BackgroundColor3 = Color3.fromRGB(28, 25, 40)
        avatarImg.BorderSizePixel = 0
        avatarImg.Parent = row

        local avCorner = Instance.new("UICorner")
        avCorner.CornerRadius = UDim.new(1, 0)
        avCorner.Parent = avatarImg

        -- Set headshot thumbnail
        if isDev then
            avatarImg.Image = "rbxassetid://10849911875" -- Developer Shield Badge Icon
        else
            local uid = tonumber(msgData.user_id) or 1
            avatarImg.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=48&h=48", uid)
        end

        -- Header: Username + Dev Badge + Timestamp
        local infoLine = Instance.new("Frame")
        infoLine.BackgroundTransparency = 1
        infoLine.Position = UDim2.new(0, 40, 0, 0)
        infoLine.Size = UDim2.new(1, -40, 0, 16)
        infoLine.Parent = row

        local userLabel = Instance.new("TextLabel")
        userLabel.BackgroundTransparency = 1
        userLabel.Size = UDim2.new(0, 0, 1, 0)
        userLabel.AutomaticSize = Enum.AutomaticSize.X
        userLabel.Font = Enum.Font.GothamBold

        -- Fix: Dev messages ALWAYS render clearly as "👑 Admin / Dev"
        if isDev then
            userLabel.Text = "👑 Admin / Dev"
            userLabel.TextColor3 = Color3.fromRGB(192, 132, 252)
        else
            userLabel.Text = tostring(msgData.display_name or msgData.username or "Player")
            userLabel.TextColor3 = isSelf and Color3.fromRGB(129, 140, 248) or Color3.fromRGB(240, 240, 250)
        end

        userLabel.TextSize = 11
        userLabel.TextXAlignment = Enum.TextXAlignment.Left
        userLabel.Parent = infoLine

        if isDev then
            local devTag = Instance.new("TextLabel")
            devTag.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
            devTag.Size = UDim2.new(0, 36, 0, 14)
            devTag.Position = UDim2.new(1, 4, 0, 1)
            devTag.Font = Enum.Font.GothamBold
            devTag.Text = "DEV"
            devTag.TextColor3 = Color3.fromRGB(255, 255, 255)
            devTag.TextSize = 8
            devTag.Parent = userLabel

            local tagCorner = Instance.new("UICorner")
            tagCorner.CornerRadius = UDim.new(0, 3)
            tagCorner.Parent = devTag
        end

        local timeLabel = Instance.new("TextLabel")
        timeLabel.BackgroundTransparency = 1
        timeLabel.Position = UDim2.new(1, -65, 0, 0)
        timeLabel.Size = UDim2.new(0, 65, 1, 0)
        timeLabel.Font = Enum.Font.Gotham
        timeLabel.Text = formatTimestamp(msgData.created_at)
        timeLabel.TextColor3 = Color3.fromRGB(115, 110, 135)
        timeLabel.TextSize = 9
        timeLabel.TextXAlignment = Enum.TextXAlignment.Right
        timeLabel.Parent = infoLine

        -- Message Bubble
        local bubble = Instance.new("Frame")
        bubble.Name = "Bubble"
        bubble.Position = UDim2.new(0, 40, 0, 20)
        bubble.Size = UDim2.new(1, -40, 0, 0)
        bubble.AutomaticSize = Enum.AutomaticSize.Y
        bubble.BorderSizePixel = 0

        if isDev then
            bubble.BackgroundColor3 = Color3.fromRGB(38, 24, 58)
        elseif isSelf then
            bubble.BackgroundColor3 = Color3.fromRGB(28, 25, 46)
        else
            bubble.BackgroundColor3 = Color3.fromRGB(22, 19, 32)
        end
        bubble.Parent = row

        local bubbleCorner = Instance.new("UICorner")
        bubbleCorner.CornerRadius = UDim.new(0, 8)
        bubbleCorner.Parent = bubble

        local bubbleStroke = Instance.new("UIStroke")
        bubbleStroke.Color = isDev and Color3.fromRGB(120, 60, 180) or Color3.fromRGB(36, 32, 52)
        bubbleStroke.Thickness = 1
        bubbleStroke.Parent = bubble

        local msgPad = Instance.new("UIPadding")
        msgPad.PaddingTop = UDim.new(0, 8)
        msgPad.PaddingBottom = UDim.new(0, 8)
        msgPad.PaddingLeft = UDim.new(0, 10)
        msgPad.PaddingRight = UDim.new(0, 10)
        msgPad.Parent = bubble

        local msgText = Instance.new("TextLabel")
        msgText.BackgroundTransparency = 1
        msgText.Size = UDim2.new(1, 0, 0, 0)
        msgText.AutomaticSize = Enum.AutomaticSize.Y
        msgText.Font = Enum.Font.Gotham
        msgText.Text = tostring(msgData.message or "")
        msgText.TextColor3 = Color3.fromRGB(235, 235, 245)
        msgText.TextSize = 11
        msgText.TextWrapped = true
        msgText.TextXAlignment = Enum.TextXAlignment.Left
        msgText.Parent = bubble

        local bottomPad = Instance.new("Frame")
        bottomPad.BackgroundTransparency = 1
        bottomPad.Position = UDim2.new(0, 0, 1, 0)
        bottomPad.Size = UDim2.new(1, 0, 0, 8)
        bottomPad.Parent = bubble
    end

    --------------------------------------------------------------------------
    -- 8. LOAD HISTORY & REAL-TIME SYNC (Deduplicated with persistent read tracking)
    --------------------------------------------------------------------------
    -- GUI element rendering caches (cleared on tab switch so bubbles re-render properly)
    local renderedGlobalIds = {}
    local renderedDevIds = {}

    -- Persistent notification and read sets (NEVER CLEARED across session)
    -- notifiedMessageIds: messages that have already triggered a sound/toast/badge alert
    -- readMessageIds: messages that the player has actually seen in-view
    local notifiedMessageIds = {}
    local readMessageIds = {}

    local initialGlobalSyncDone = false
    local initialDevSyncDone = false

    local function clearMessagesView()
        for _, child in ipairs(messagesFrame:GetChildren()) do
            if child:IsA("Frame") and child.Name:sub(1, 4) == "Msg_" then
                child:Destroy()
            end
        end
        table.clear(renderedGlobalIds)
        table.clear(renderedDevIds)
    end

    local function markDevMessagesReadOnServer()
        task.spawn(function()
            pcall(function()
                safeHttpRequest(API_BASE .. "/dms", "PATCH", HttpService:JSONEncode({
                    userId = tostring(LocalPlayer.UserId),
                    reader = "player"
                }))
            end)
        end)
    end

    local function loadGlobalHistory()
        clearMessagesView()
        task.spawn(function()
            local success, body = safeHttpRequest(API_BASE .. "/messages?limit=60", "GET")
            if success and body then
                local ok, parsed = pcall(function()
                    return HttpService:JSONDecode(body)
                end)
                if ok and parsed then
                    if type(parsed.cooldown_seconds) == "number" then
                        clientCooldownSeconds = parsed.cooldown_seconds
                    end
                    if parsed.messages then
                        for _, m in ipairs(parsed.messages) do
                            if m.id then
                                notifiedMessageIds[m.id] = true
                                if isOpen and activeTab == "global" then
                                    readMessageIds[m.id] = true
                                end
                                if not renderedGlobalIds[m.id] then
                                    renderedGlobalIds[m.id] = true
                                    renderMessageBubble(m, false)
                                    lastGlobalTimestamp = m.created_at
                                end
                            end
                        end
                        scrollToBottom()
                    end
                    initialGlobalSyncDone = true
                end
            end
        end)
    end

    local function loadDevHistory()
        clearMessagesView()
        task.spawn(function()
            local url = string.format("%s/dms?userId=%s", API_BASE, tostring(LocalPlayer.UserId))
            local success, body = safeHttpRequest(url, "GET")
            if success and body then
                local ok, parsed = pcall(function()
                    return HttpService:JSONDecode(body)
                end)
                if ok and parsed and parsed.messages then
                    for _, m in ipairs(parsed.messages) do
                        if m.id then
                            notifiedMessageIds[m.id] = true
                            if isOpen and activeTab == "dev" then
                                readMessageIds[m.id] = true
                            end
                            if not renderedDevIds[m.id] then
                                renderedDevIds[m.id] = true
                                renderMessageBubble(m, true)
                                lastDevTimestamp = m.created_at
                            end
                        end
                    end
                    scrollToBottom()
                    initialDevSyncDone = true

                    if isOpen and activeTab == "dev" then
                        markDevMessagesReadOnServer()
                    end
                end
            end
        end)
    end

    -- Tab Switching Logic
    tabGlobalBtn.MouseButton1Click:Connect(function()
        if activeTab == "global" then return end
        activeTab = "global"
        tabGlobalBtn.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
        tabGlobalBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabDevBtn.BackgroundColor3 = Color3.fromRGB(28, 24, 42)
        tabDevBtn.TextColor3 = Color3.fromRGB(150, 145, 175)
        textBox.PlaceholderText = "Say something in global chat..."
        loadGlobalHistory()
    end)

    tabDevBtn.MouseButton1Click:Connect(function()
        if activeTab == "dev" then return end
        activeTab = "dev"
        tabDevBtn.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
        tabDevBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabGlobalBtn.BackgroundColor3 = Color3.fromRGB(28, 24, 42)
        tabGlobalBtn.TextColor3 = Color3.fromRGB(150, 145, 175)
        textBox.PlaceholderText = "Message your developer directly..."
        loadDevHistory()
    end)

    --------------------------------------------------------------------------
    -- 9. SEND MESSAGE HANDLER WITH COOLDOWN COUNTDOWN
    --------------------------------------------------------------------------
    local isSending = false
    local function sendMessage()
        if isSending then return end
        local raw = textBox.Text or ""
        local trimmed = raw:gsub("^%s*(.-)%s*$", "%1")
        if #trimmed == 0 then return end

        -- Client-side cooldown check for global chat
        if activeTab == "global" and clientCooldownSeconds > 0 then
            local elapsed = os.clock() - lastSentTime
            if elapsed < clientCooldownSeconds then
                local remaining = math.ceil(clientCooldownSeconds - elapsed)
                showWarning(string.format("Chat cooldown active! Please wait %d seconds.", remaining))
                return
            end
        end

        isSending = true
        btnSend.Text = "..."
        textBox.Text = ""

        task.spawn(function()
            local payload, targetUrl
            if activeTab == "global" then
                targetUrl = API_BASE .. "/messages"
                payload = HttpService:JSONEncode({
                    userId = tostring(LocalPlayer.UserId),
                    username = LocalPlayer.Name,
                    displayName = LocalPlayer.DisplayName,
                    message = trimmed
                })
            else
                targetUrl = API_BASE .. "/dms"
                payload = HttpService:JSONEncode({
                    userId = tostring(LocalPlayer.UserId),
                    username = LocalPlayer.Name,
                    displayName = LocalPlayer.DisplayName,
                    senderType = "user",
                    message = trimmed
                })
            end

            local success, resBody, statusCode = safeHttpRequest(targetUrl, "POST", payload)
            isSending = false

            if success and resBody then
                local ok, parsed = pcall(function()
                    return HttpService:JSONDecode(resBody)
                end)
                if ok and parsed then
                    if parsed.rateLimited then
                        showWarning(parsed.error or "Chat cooldown active. Please wait.")
                    elseif parsed.blocked then
                        showWarning("Message contains blacklisted words and was blocked.")
                    elseif parsed.message then
                        local m = parsed.message
                        if m.id then
                            notifiedMessageIds[m.id] = true
                            readMessageIds[m.id] = true
                            if activeTab == "dev" then
                                if not renderedDevIds[m.id] then
                                    renderedDevIds[m.id] = true
                                    renderMessageBubble(m, true)
                                    scrollToBottom()
                                end
                            else
                                if not renderedGlobalIds[m.id] then
                                    renderedGlobalIds[m.id] = true
                                    renderMessageBubble(m, false)
                                    scrollToBottom()
                                end
                            end
                        end

                        -- Start cooldown visual countdown on the Send button
                        if activeTab == "global" and clientCooldownSeconds > 0 then
                            lastSentTime = os.clock()
                            task.spawn(function()
                                for c = clientCooldownSeconds, 1, -1 do
                                    if not isSending then
                                        btnSend.Text = string.format("%ds", c)
                                        btnSend.BackgroundColor3 = Color3.fromRGB(50, 45, 65)
                                    end
                                    task.wait(1)
                                end
                                if not isSending then
                                    btnSend.Text = "SEND"
                                    btnSend.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
                                end
                            end)
                        else
                            btnSend.Text = "SEND"
                            btnSend.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
                        end
                    end
                else
                    btnSend.Text = "SEND"
                end
            else
                btnSend.Text = "SEND"
                if statusCode == 429 then
                    showWarning("Chat cooldown active! Please slow down.")
                elseif statusCode == 400 then
                    showWarning("Message blocked by word filter.")
                else
                    showWarning("Failed to send. Server error.")
                end
            end
        end)
    end

    btnSend.MouseButton1Click:Connect(sendMessage)
    textBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            sendMessage()
        end
    end)

    --------------------------------------------------------------------------
    -- 10. BACKGROUND REAL-TIME POLLING LOOP (Every 3.5 seconds)
    --------------------------------------------------------------------------
    task.spawn(function()
        while isPolling and screenGui and screenGui.Parent do
            task.wait(3.5)
            if not isPolling then break end

            -- 1. Poll global messages if enabled
            if isGlobalChatEnabled then
                local url = API_BASE .. "/messages?limit=25"
                if lastGlobalTimestamp then
                    url = url .. "&since=" .. HttpService:UrlEncode(lastGlobalTimestamp)
                end

                local success, body = safeHttpRequest(url, "GET")
                if success and body then
                    local ok, parsed = pcall(function()
                        return HttpService:JSONDecode(body)
                    end)
                    if ok and parsed then
                        if type(parsed.cooldown_seconds) == "number" then
                            clientCooldownSeconds = parsed.cooldown_seconds
                        end

                        if parsed.messages then
                            local newIncoming = 0
                            local isActivelyViewingGlobal = (isOpen and activeTab == "global")

                            for _, m in ipairs(parsed.messages) do
                                if m.id then
                                    if activeTab == "global" and not renderedGlobalIds[m.id] then
                                        renderedGlobalIds[m.id] = true
                                        renderMessageBubble(m, false)
                                        scrollToBottom()
                                    end

                                    lastGlobalTimestamp = m.created_at

                                    local isFromSelf = (tostring(m.user_id) == tostring(LocalPlayer.UserId))
                                    local alreadyNotified = (notifiedMessageIds[m.id] == true)
                                    local alreadyRead = (readMessageIds[m.id] == true)

                                    if not initialGlobalSyncDone then
                                        -- Initial sync: mark as notified without firing alerts for past messages
                                        notifiedMessageIds[m.id] = true
                                        if isActivelyViewingGlobal then
                                            readMessageIds[m.id] = true
                                        end
                                    elseif not isFromSelf and not alreadyNotified and not alreadyRead then
                                        notifiedMessageIds[m.id] = true
                                        if isActivelyViewingGlobal then
                                            readMessageIds[m.id] = true
                                        else
                                            newIncoming = newIncoming + 1
                                        end
                                    end
                                end
                            end

                            initialGlobalSyncDone = true

                            -- Trigger notification ONLY for genuinely new, unread, unnotified incoming messages
                            if newIncoming > 0 and not isActivelyViewingGlobal then
                                updateBadge(newIncoming)
                                if isGlobalNotificationsEnabled and not isMasterMuted and NotificationModule then
                                    pcall(function()
                                        SoundService:PlayLocalSound(Instance.new("Sound", SoundService))
                                    end)
                                    NotificationModule:Show("💬 Chatroom", string.format("%d new message(s) in global chat", newIncoming), 2.5, "Info")
                                end
                            end
                        end
                    end
                end
            end

            -- 2. Poll Developer DMs for this player
            if isDevTabEnabled then
                local dmUrl = string.format("%s/dms?userId=%s", API_BASE, tostring(LocalPlayer.UserId))
                local successDm, bodyDm = safeHttpRequest(dmUrl, "GET")
                if successDm and bodyDm then
                    local okDm, parsedDm = pcall(function()
                        return HttpService:JSONDecode(bodyDm)
                    end)
                    if okDm and parsedDm and parsedDm.messages then
                        local newDevReplies = 0
                        local isActivelyViewingDev = (isOpen and activeTab == "dev")

                        for _, m in ipairs(parsedDm.messages) do
                            if m.id then
                                if activeTab == "dev" and not renderedDevIds[m.id] then
                                    renderedDevIds[m.id] = true
                                    renderMessageBubble(m, true)
                                    scrollToBottom()
                                end

                                lastDevTimestamp = m.created_at

                                local isDevReply = (m.sender_type == "dev")
                                local alreadyNotified = (notifiedMessageIds[m.id] == true)
                                local alreadyRead = (readMessageIds[m.id] == true)

                                if not initialDevSyncDone then
                                    -- Initial sync: mark as notified without firing alerts for past replies
                                    notifiedMessageIds[m.id] = true
                                    if isActivelyViewingDev then
                                        readMessageIds[m.id] = true
                                    end
                                elseif isDevReply and not alreadyNotified and not alreadyRead then
                                    notifiedMessageIds[m.id] = true
                                    if isActivelyViewingDev then
                                        readMessageIds[m.id] = true
                                    else
                                        newDevReplies = newDevReplies + 1
                                    end
                                end
                            end
                        end

                        initialDevSyncDone = true

                        if isActivelyViewingDev and newDevReplies == 0 then
                            markDevMessagesReadOnServer()
                        end

                        -- Trigger notification ONLY for genuinely new, unread developer replies
                        if newDevReplies > 0 and not isActivelyViewingDev then
                            updateBadge(newDevReplies)
                            if isDevNotificationsEnabled and not isMasterMuted and NotificationModule then
                                pcall(function()
                                    SoundService:PlayLocalSound(Instance.new("Sound", SoundService))
                                end)
                                NotificationModule:Show("👑 Developer Reply", "A developer has replied to your message!", 4.5, "Success")
                            end
                        end
                    end
                end
            end
        end
    end)

    --------------------------------------------------------------------------
    -- 11. OPEN / CLOSE & DRAGGING BEHAVIOR
    --------------------------------------------------------------------------
    local function setChatOpen(open)
        isOpen = open
        chatModal.Visible = open
        if open then
            updateBadge(-unreadCount) -- clear unread count on open
            if activeTab == "global" then
                loadGlobalHistory()
            else
                loadDevHistory()
            end
        end
    end

    floatBtn.MouseButton1Click:Connect(function()
        setChatOpen(not isOpen)
    end)
    btnClose.MouseButton1Click:Connect(function()
        setChatOpen(false)
    end)

    -- Draggable Floating Button
    local draggingBtn = false
    local dragStartBtn, startPosBtn
    floatBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingBtn = true
            dragStartBtn = input.Position
            startPosBtn = floatBtn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    draggingBtn = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if draggingBtn and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStartBtn
            floatBtn.Position = UDim2.new(
                startPosBtn.X.Scale,
                startPosBtn.X.Offset + delta.X,
                startPosBtn.Y.Scale,
                startPosBtn.Y.Offset + delta.Y
            )
        end
    end)

    -- Draggable Chat Modal Header
    local draggingModal = false
    local dragStartModal, startPosModal
    headerFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingModal = true
            dragStartModal = input.Position
            startPosModal = chatModal.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    draggingModal = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if draggingModal and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStartModal
            chatModal.Position = UDim2.new(
                startPosModal.X.Scale,
                startPosModal.X.Offset + delta.X,
                startPosModal.Y.Scale,
                startPosModal.Y.Offset + delta.Y
            )
        end
    end)

    return ChatroomWidget
end

pcall(function()
    local notifBridge = {
        Show = function(self, title, message, duration, msgType)
            if _G.AtomwareConfig and _G.AtomwareConfig.Notify then
                _G.AtomwareConfig:Notify(tostring(title) .. ": " .. tostring(message), duration)
            end
        end
    }
    ChatroomWidget:Init(notifBridge)
end)

_G.AtomwareChatroomWidget = ChatroomWidget
return ChatroomWidget
