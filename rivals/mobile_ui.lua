--[[
    Atomware Rivals - mobile_ui.lua (Full Mobile Rewrite)
    Ultra-Polished Mobile Touch UI Framework for Atomware Rivals
    Features:
      - Draggable Floating Toggle Pill with Attached Lock Button
      - Fixed Non-Scrolling Header with Atomware Cyberpunk Branding
      - Horizontal Swipeable Tab Navigation Bar
      - Contained Two-Column Responsive Cards (No more endless dropdown stacking)
      - Contained ScrollList Widgets for Weapons, Skins, Skyboxes, and Sounds (Searchable, Contained Viewport)
      - Contained Dropdowns, Touch-Sized Toggles, Interactive Sliders, Color Chips, and Keybinds
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local function trackConnection(connection)
    if _G.AtomwareConfig then return _G.AtomwareConfig:TrackConnection(connection) end
    return connection
end

--//==================================================
--// GLOBAL EVENT BINDING SYSTEM
--//==================================================

_G.AtomwareEvents = _G.AtomwareEvents or {}
_G.AtomwarePendingEvents = {}

local function registerAtomwareEvent(name, callback)
    _G.AtomwareEvents[name] = callback
    local pending = _G.AtomwarePendingEvents[name]
    if pending then
        _G.AtomwarePendingEvents[name] = nil
        task.spawn(function()
            local ok, err = pcall(callback, table.unpack(pending, 1, pending.n))
            if not ok then warn("[Atomware Mobile] event '" .. name .. "' failed: " .. tostring(err)) end
        end)
    end
end

_G.OnToggle = function(name, callback) registerAtomwareEvent(name, callback) end
_G.OnSlider = function(name, callback) registerAtomwareEvent(name, callback) end
_G.OnDropdown = function(name, callback) registerAtomwareEvent(name, callback) end
_G.OnColorPicker = function(name, callback) registerAtomwareEvent(name, callback) end
_G.OnKeybind = function(name, callback) registerAtomwareEvent(name, callback) end

_G.FireEvent = function(name, ...)
    if _G.AtomwareConfig and select("#", ...) == 1 then
        _G.AtomwareConfig:Store(name, (...))
    end
    local callback = _G.AtomwareEvents[name]
    if callback then
        local args = { ... }
        local count = select("#", ...)
        task.spawn(function()
            local ok, err = pcall(callback, table.unpack(args, 1, count))
            if not ok then warn("[Atomware Mobile] event '" .. name .. "' failed: " .. tostring(err)) end
        end)
        return
    end
    local args = { ... }
    args.n = select("#", ...)
    _G.AtomwarePendingEvents[name] = args
end

local function bindSetting(name, default, apply, validate)
    if _G.AtomwareConfig then return _G.AtomwareConfig:Register(name, default, apply, validate) end
    return default
end

--//==================================================
--// THEME & STYLING
--//==================================================

local THEME = {
    Background      = Color3.fromRGB(8, 6, 15),
    Header          = Color3.fromRGB(13, 9, 24),
    TabBar          = Color3.fromRGB(11, 8, 20),
    Card            = Color3.fromRGB(16, 11, 30),
    CardAlt         = Color3.fromRGB(24, 16, 44),
    CardHover       = Color3.fromRGB(32, 20, 56),

    Border          = Color3.fromRGB(105, 45, 195),
    BorderDim       = Color3.fromRGB(55, 30, 95),
    Accent          = Color3.fromRGB(157, 48, 255),
    AccentBright    = Color3.fromRGB(205, 104, 255),
    AccentDark      = Color3.fromRGB(80, 26, 142),

    Text            = Color3.fromRGB(245, 241, 255),
    TextMuted       = Color3.fromRGB(170, 155, 205),
    TextDim         = Color3.fromRGB(110, 95, 140),

    Green           = Color3.fromRGB(42, 255, 157),
    Red             = Color3.fromRGB(255, 75, 125),
}

local FONT = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

local function tween(inst, info, props)
    local t = TweenService:Create(inst, info, props)
    t:Play()
    return t
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or THEME.BorderDim
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function padding(parent, top, bottom, left, right)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, top or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.PaddingLeft = UDim.new(0, left or 0)
    p.PaddingRight = UDim.new(0, right or 0)
    p.Parent = parent
    return p
end

--//==================================================
--// SCREENGUI & MAIN CONTAINERS
--//==================================================

local function getGuiParent()
    if typeof(gethui) == "function" then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    local playerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
    return playerGui or CoreGui
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AtomwareMobileRivalsUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 100
ScreenGui.Parent = getGuiParent()

if _G.AtomwareConfig then _G.AtomwareConfig:AttachUI(ScreenGui, "Mobile Touch") end

local UIVisible = true
local isUILocked = false
local activeDropdownCloser = nil

--//==================================================
--// DRAGGABLE MOBILE TOGGLE CONTAINER WITH LOCK BUTTON
--//==================================================

local ToggleContainer = Instance.new("Frame")
ToggleContainer.Name = "AtomwareMobileToggleContainer"
ToggleContainer.Size = UDim2.fromOffset(124, 48)
ToggleContainer.Position = UDim2.new(1, -136, 0.28, 0)
ToggleContainer.BackgroundTransparency = 1
ToggleContainer.BorderSizePixel = 0
ToggleContainer.ZIndex = 200
ToggleContainer.Parent = ScreenGui

local isDraggingToggle = false
local toggleDragStart = nil
local toggleStartPos = nil
local toggleHasDragged = false
local toggleDragInput = nil

local function updateToggleDrag(input)
    if not isDraggingToggle or isUILocked then return end
    local delta = input.Position - toggleDragStart
    if delta.Magnitude > 6 then
        toggleHasDragged = true
    end
    local camera = workspace.CurrentCamera
    local vp = camera and camera.ViewportSize or Vector2.new(800, 600)
    local maxX = math.max(0, vp.X - ToggleContainer.AbsoluteSize.X)
    local maxY = math.max(0, vp.Y - ToggleContainer.AbsoluteSize.Y)
    local newX = math.clamp(toggleStartPos.X.Offset + delta.X, 0, maxX)
    local newY = math.clamp(toggleStartPos.Y.Offset + delta.Y, 0, maxY)
    ToggleContainer.Position = UDim2.fromOffset(newX, newY)
end

-- Floating Button (48x48)
local MobileToggleBtn = Instance.new("TextButton")
MobileToggleBtn.Name = "MobileToggle"
MobileToggleBtn.Size = UDim2.fromOffset(48, 48)
MobileToggleBtn.Position = UDim2.fromOffset(0, 0)
MobileToggleBtn.BackgroundColor3 = THEME.Header
MobileToggleBtn.Text = "AW"
MobileToggleBtn.TextColor3 = THEME.AccentBright
MobileToggleBtn.TextSize = 16
MobileToggleBtn.Font = FONT_BOLD
MobileToggleBtn.AutoButtonColor = false
MobileToggleBtn.ZIndex = 201
MobileToggleBtn.Parent = ToggleContainer
corner(MobileToggleBtn, 24)
local toggleStroke = stroke(MobileToggleBtn, THEME.Accent, 1.5)

-- Attached Lock Button
local ToggleLockBtn = Instance.new("TextButton")
ToggleLockBtn.Name = "MobileToggleLock"
ToggleLockBtn.Size = UDim2.fromOffset(64, 34)
ToggleLockBtn.Position = UDim2.fromOffset(54, 7)
ToggleLockBtn.BackgroundColor3 = THEME.Header
ToggleLockBtn.Text = "Lock"
ToggleLockBtn.TextColor3 = THEME.TextMuted
ToggleLockBtn.TextSize = 11
ToggleLockBtn.Font = FONT_BOLD
ToggleLockBtn.AutoButtonColor = false
ToggleLockBtn.ZIndex = 201
ToggleLockBtn.Parent = ToggleContainer
corner(ToggleLockBtn, 8)
local lockStroke = stroke(ToggleLockBtn, THEME.BorderDim, 1)

local function onToggleDragInputBegan(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        if not isUILocked then
            isDraggingToggle = true
            toggleHasDragged = false
            toggleDragStart = input.Position
            toggleStartPos = ToggleContainer.Position
            toggleDragInput = input
        end
    end
end

trackConnection(MobileToggleBtn.InputBegan:Connect(onToggleDragInputBegan))
trackConnection(ToggleContainer.InputBegan:Connect(onToggleDragInputBegan))

trackConnection(UserInputService.InputChanged:Connect(function(input)
    if isDraggingToggle and (input == toggleDragInput or input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        updateToggleDrag(input)
    end
end))

trackConnection(UserInputService.InputEnded:Connect(function(input)
    if input == toggleDragInput or input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDraggingToggle = false
        toggleDragInput = nil
    end
end))

--//==================================================
--// MAIN WINDOW (RESPONSIVE CONTAINED FRAME)
--//==================================================

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.fromScale(0.5, 0.5)
MainFrame.Size = UDim2.new(0.96, 0, 0.90, 0)
MainFrame.BackgroundColor3 = THEME.Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
corner(MainFrame, 12)
stroke(MainFrame, THEME.Border, 1.5)

local function setUIVisible(visible)
    UIVisible = visible
    MainFrame.Visible = UIVisible
    if UIVisible then
        MainFrame.Size = UDim2.new(0.96, 0, 0.90, 0)
    end
end

trackConnection(MobileToggleBtn.MouseButton1Click:Connect(function()
    if toggleHasDragged then
        toggleHasDragged = false
        return
    end
    if isUILocked then
        if _G.AtomwareConfig and _G.AtomwareConfig.Notify then
            _G.AtomwareConfig:Notify("UI is Locked! Press 'Lock' to unlock.", 2)
        end
        return
    end
    setUIVisible(not UIVisible)
end))

trackConnection(ToggleLockBtn.MouseButton1Click:Connect(function()
    isUILocked = not isUILocked
    if isUILocked then
        ToggleLockBtn.Text = "Locked"
        ToggleLockBtn.TextColor3 = THEME.Red
        ToggleLockBtn.BackgroundColor3 = Color3.fromRGB(50, 16, 26)
        lockStroke.Color = THEME.Red
        MobileToggleBtn.BackgroundTransparency = 0.4
        toggleStroke.Color = THEME.BorderDim
        if _G.AtomwareConfig and _G.AtomwareConfig.Notify then
            _G.AtomwareConfig:Notify("UI Toggle Locked in place", 2)
        end
    else
        ToggleLockBtn.Text = "Lock"
        ToggleLockBtn.TextColor3 = THEME.TextMuted
        ToggleLockBtn.BackgroundColor3 = THEME.Header
        lockStroke.Color = THEME.BorderDim
        MobileToggleBtn.BackgroundTransparency = 0
        toggleStroke.Color = THEME.Accent
        if _G.AtomwareConfig and _G.AtomwareConfig.Notify then
            _G.AtomwareConfig:Notify("UI Toggle Unlocked", 2)
        end
    end
end))

-- Fixed Header
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 44)
Header.BackgroundColor3 = THEME.Header
Header.BorderSizePixel = 0
Header.Parent = MainFrame
stroke(Header, THEME.BorderDim, 1)

local HeaderAccent = Instance.new("Frame")
HeaderAccent.Size = UDim2.fromOffset(4, 22)
HeaderAccent.Position = UDim2.fromOffset(12, 11)
HeaderAccent.BackgroundColor3 = THEME.Accent
HeaderAccent.BorderSizePixel = 0
HeaderAccent.Parent = Header
corner(HeaderAccent, 2)

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Text = "ATOMWARE  <font color=\"#cd68ff\">RIVALS</font>"
Title.RichText = true
Title.Size = UDim2.new(0.6, 0, 1, 0)
Title.Position = UDim2.fromOffset(24, 0)
Title.TextSize = 15
Title.TextColor3 = THEME.Text
Title.Font = FONT_BOLD
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.fromOffset(32, 28)
CloseBtn.Position = UDim2.new(1, -40, 0, 8)
CloseBtn.BackgroundColor3 = THEME.Card
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = THEME.Red
CloseBtn.TextSize = 13
CloseBtn.Font = FONT_BOLD
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = Header
corner(CloseBtn, 6)
stroke(CloseBtn, THEME.BorderDim, 1)
trackConnection(CloseBtn.MouseButton1Click:Connect(function() setUIVisible(false) end))

-- Horizontal Scrolling Tab Navigation Bar (Locked under Header)
local TabBar = Instance.new("ScrollingFrame")
TabBar.Name = "TabBar"
TabBar.Size = UDim2.new(1, 0, 0, 40)
TabBar.Position = UDim2.fromOffset(0, 44)
TabBar.BackgroundColor3 = THEME.TabBar
TabBar.BorderSizePixel = 0
TabBar.ScrollBarThickness = 0
TabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
TabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
TabBar.Parent = MainFrame
padding(TabBar, 6, 6, 8, 8)

local TabListLayout = Instance.new("UIListLayout")
TabListLayout.FillDirection = Enum.FillDirection.Horizontal
TabListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabListLayout.Padding = UDim.new(0, 6)
TabListLayout.Parent = TabBar

-- Content Viewport (Scrollable container for pages)
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.BackgroundTransparency = 1
ContentArea.Position = UDim2.fromOffset(0, 86)
ContentArea.Size = UDim2.new(1, 0, 1, -86)
ContentArea.Parent = MainFrame

local TAB_ORDER = {
    ["Visuals"]   = 1,
    ["Legit"]     = 2,
    ["Rage"]      = 3,
    ["Movement"]  = 4,
    ["World"]     = 5,
    ["Cosmetics"] = 6,
    ["Misc"]      = 7,
    ["Extras"]    = 8,
    ["Settings"]  = 9,
}

local Pages = {}
local PageColumns = {}
local TabButtons = {}
local CurrentPageName = "Visuals"
local responsiveLayouts = {}

local function updateResponsiveLayouts()
    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(800, 600)
    local isNarrow = vp.X < 560
    for _, item in ipairs(responsiveLayouts) do
        if isNarrow then
            item.left.Size = UDim2.new(1, 0, 0, 0)
            item.right.Size = UDim2.new(1, 0, 0, 0)
            item.layout.FillDirection = Enum.FillDirection.Vertical
        else
            item.left.Size = UDim2.new(0.5, -4, 0, 0)
            item.right.Size = UDim2.new(0.5, -4, 0, 0)
            item.layout.FillDirection = Enum.FillDirection.Horizontal
        end
    end
end

if workspace.CurrentCamera then
    trackConnection(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveLayouts))
end

local function switchPage(name)
    CurrentPageName = name
    for pName, pFrame in pairs(Pages) do
        pFrame.Visible = (pName == name)
    end
    for pName, btn in pairs(TabButtons) do
        local active = (pName == name)
        tween(btn, TweenInfo.new(0.14), {
            BackgroundColor3 = active and THEME.AccentDark or THEME.Card,
            TextColor3 = active and THEME.AccentBright or THEME.TextMuted,
        })
    end
end

-- Two-Column Responsive Page Creator
local function getOrCreatePage(name)
    if Pages[name] then return Pages[name] end

    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.Size = UDim2.new(1, 0, 1, 0)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = THEME.Accent
    page.Visible = (name == CurrentPageName)
    page.Parent = ContentArea
    padding(page, 8, 12, 8, 8)

    -- Two-Column Horizontal Container
    local colContainer = Instance.new("Frame")
    colContainer.Name = "ColContainer"
    colContainer.BackgroundTransparency = 1
    colContainer.Size = UDim2.new(1, 0, 0, 0)
    colContainer.AutomaticSize = Enum.AutomaticSize.Y
    colContainer.Parent = page

    local hList = Instance.new("UIListLayout")
    hList.FillDirection = Enum.FillDirection.Horizontal
    hList.VerticalAlignment = Enum.VerticalAlignment.Top
    hList.Padding = UDim.new(0, 8)
    hList.Parent = colContainer

    local leftCol = Instance.new("Frame")
    leftCol.Name = "LeftColumn"
    leftCol.BackgroundTransparency = 1
    leftCol.Size = UDim2.new(0.5, -4, 0, 0)
    leftCol.AutomaticSize = Enum.AutomaticSize.Y
    leftCol.Parent = colContainer

    local leftList = Instance.new("UIListLayout")
    leftList.Padding = UDim.new(0, 8)
    leftList.SortOrder = Enum.SortOrder.LayoutOrder
    leftList.Parent = leftCol

    local rightCol = Instance.new("Frame")
    rightCol.Name = "RightColumn"
    rightCol.BackgroundTransparency = 1
    rightCol.Size = UDim2.new(0.5, -4, 0, 0)
    rightCol.AutomaticSize = Enum.AutomaticSize.Y
    rightCol.Parent = colContainer

    local rightList = Instance.new("UIListLayout")
    rightList.Padding = UDim.new(0, 8)
    rightList.SortOrder = Enum.SortOrder.LayoutOrder
    rightList.Parent = rightCol

    table.insert(responsiveLayouts, { layout = hList, left = leftCol, right = rightCol })
    updateResponsiveLayouts()
    PageColumns[page] = { Columns = { leftCol, rightCol }, Counts = { 0, 0 } }
    Pages[name] = page
    return page
end

local function normalizeTabName(name)
    local lower = string.lower(name)
    if lower == "legit" then return "Legit", "🎯" end
    if lower == "rage" then return "Rage", "⚡" end
    if lower == "visuals" then return "Visuals", "👁️" end
    if lower == "move" or lower == "movement" then return "Movement", "🏃" end
    if lower == "world" then return "World", "🌍" end
    if lower == "items" or lower == "cosmetics" then return "Cosmetics", "🎨" end
    if lower == "misc" then return "Misc", "🛠️" end
    if lower == "extras" then return "Extras", "📁" end
    if lower == "configs" or lower == "settings" then return "Settings", "⚙️" end
    return name:sub(1,1):upper() .. name:sub(2), "•"
end

--//==================================================
--// CONTAINED CARD BUILDER
--//==================================================

local function createMobileCard(page, title, side)
    local pageLayout = PageColumns[page]
    local cardParent = page
    if pageLayout then
        local colIdx = 1
        if side == 2 or side == "right" then
            colIdx = 2
        elseif side == 1 or side == "left" then
            colIdx = 1
        else
            colIdx = pageLayout.Counts[1] <= pageLayout.Counts[2] and 1 or 2
        end
        pageLayout.Counts[colIdx] = pageLayout.Counts[colIdx] + 1
        cardParent = pageLayout.Columns[colIdx]
    end

    local card = Instance.new("Frame")
    card.Name = title .. "Card"
    card.BackgroundColor3 = THEME.Card
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.Parent = cardParent
    corner(card, 10)
    stroke(card, THEME.BorderDim, 1)
    padding(card, 8, 8, 8, 8)

    local cardLayout = Instance.new("UIListLayout")
    cardLayout.Padding = UDim.new(0, 6)
    cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
    cardLayout.Parent = card

    -- Card Header
    local head = Instance.new("Frame")
    head.Name = "Header"
    head.Size = UDim2.new(1, 0, 0, 20)
    head.BackgroundTransparency = 1
    head.Parent = card

    local pill = Instance.new("Frame")
    pill.Size = UDim2.fromOffset(3, 14)
    pill.Position = UDim2.fromOffset(0, 3)
    pill.BackgroundColor3 = THEME.Accent
    pill.BorderSizePixel = 0
    pill.Parent = head
    corner(pill, 2)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 1, 0)
    lbl.Position = UDim2.fromOffset(8, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = title
    lbl.TextSize = 11
    lbl.TextColor3 = THEME.Text
    lbl.Font = FONT_BOLD
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextTruncate = Enum.TextTruncate.AtEnd
    lbl.Parent = head

    local sep = Instance.new("Frame")
    sep.Size = UDim2.new(1, 0, 0, 1)
    sep.BackgroundColor3 = THEME.BorderDim
    sep.BorderSizePixel = 0
    sep.Parent = card

    local body = Instance.new("Frame")
    body.Name = "Body"
    body.BackgroundTransparency = 1
    body.Size = UDim2.new(1, 0, 0, 0)
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.Parent = card

    local bodyLayout = Instance.new("UIListLayout")
    bodyLayout.Padding = UDim.new(0, 6)
    bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    bodyLayout.Parent = body

    return card, body
end

--//==================================================
--// SECTION WIDGET SYSTEM (CONTAINED WIDGETS)
--//==================================================

local function wrapMobileSection(card, body, title)
    local section = {
        card = card,
        body = body,
        text = title,
        options = {},
    }

    -- 1. Contained Toggle
    function section:AddToggle(data)
        local text = data.text or ""
        local state = data.state == true
        local callback = data.callback

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 30)
        row.BackgroundTransparency = 1
        row.Parent = body

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -78, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextSize = 11
        lbl.TextColor3 = state and THEME.Text or THEME.TextMuted
        lbl.Font = FONT
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        lbl.Parent = row

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromOffset(40, 20)
        btn.Position = UDim2.new(1, -42, 0.5, -10)
        btn.BackgroundColor3 = state and THEME.Accent or THEME.CardAlt
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = row
        corner(btn, 10)
        stroke(btn, state and THEME.AccentBright or THEME.BorderDim, 1)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.fromOffset(14, 14)
        knob.Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.fromOffset(3, 3)
        knob.BackgroundColor3 = THEME.Text
        knob.Parent = btn
        corner(knob, 7)

        local toggleObj = { enabled = true }

        local function setState(val, skipCallback)
            local newVal = (val == true)
            if state == newVal and skipCallback then
                return
            end
            state = newVal
            lbl.TextColor3 = state and THEME.Text or THEME.TextMuted
            if skipCallback then
                btn.BackgroundColor3 = state and THEME.Accent or THEME.CardAlt
                knob.Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.fromOffset(3, 3)
            else
                tween(btn, TweenInfo.new(0.12), { BackgroundColor3 = state and THEME.Accent or THEME.CardAlt })
                tween(knob, TweenInfo.new(0.12), { Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.fromOffset(3, 3) })
                if callback then pcall(callback, state) end
            end
        end

        trackConnection(btn.MouseButton1Click:Connect(function()
            setState(not state)
        end))

        function toggleObj:SetState(val, skipCallback)
            setState(val, skipCallback)
        end

        function toggleObj:AddColor(spec)
            local col = spec.color or Color3.fromRGB(255, 255, 255)
            local cb = spec.callback

            local chip = Instance.new("TextButton")
            chip.Size = UDim2.fromOffset(18, 18)
            chip.Position = UDim2.new(1, -66, 0.5, -9)
            chip.BackgroundColor3 = col
            chip.Text = ""
            chip.AutoButtonColor = false
            chip.Parent = row
            corner(chip, 4)
            stroke(chip, THEME.BorderDim, 1)

            local chipObj = {}
            function chipObj:SetColor(newColor, skipCb)
                if col == newColor and skipCb then return end
                col = newColor
                chip.BackgroundColor3 = col
                if not skipCb and cb then pcall(cb, col) end
            end

            trackConnection(chip.MouseButton1Click:Connect(function()
                local PALETTE = {
                    Color3.fromRGB(255, 255, 255),
                    Color3.fromRGB(205, 104, 255),
                    Color3.fromRGB(157, 48, 255),
                    Color3.fromRGB(0, 220, 255),
                    Color3.fromRGB(42, 255, 157),
                    Color3.fromRGB(255, 75, 125),
                    Color3.fromRGB(255, 215, 0),
                }
                local nextIdx = 1
                for idx, c in ipairs(PALETTE) do
                    if (c.R - col.R)^2 + (c.G - col.G)^2 + (c.B - col.B)^2 < 0.05 then
                        nextIdx = (idx % #PALETTE) + 1
                        break
                    end
                end
                chipObj:SetColor(PALETTE[nextIdx])
            end))

            return chipObj
        end

        table.insert(section.options, { row = row, obj = toggleObj })
        return toggleObj
    end

    -- 2. Contained Slider
    function section:AddSlider(data)
        local text = data.text or ""
        local min = data.min or 0
        local max = data.max or 100
        local inc = data.increment or 1
        local val = math.clamp(data.value or min, min, max)
        local suffix = data.suffix or ""
        local callback = data.callback

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 40)
        row.BackgroundTransparency = 1
        row.Parent = body

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.65, 0, 0, 15)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextSize = 10
        lbl.TextColor3 = THEME.TextMuted
        lbl.Font = FONT
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        lbl.Parent = row

        local valLbl = Instance.new("TextLabel")
        valLbl.Size = UDim2.new(0.35, 0, 0, 15)
        valLbl.Position = UDim2.new(0.65, 0, 0, 0)
        valLbl.BackgroundTransparency = 1
        valLbl.Text = tostring(val) .. suffix
        valLbl.TextSize = 10
        valLbl.TextColor3 = THEME.AccentBright
        valLbl.Font = FONT_BOLD
        valLbl.TextXAlignment = Enum.TextXAlignment.Right
        valLbl.Parent = row

        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, 0, 0, 8)
        track.Position = UDim2.fromOffset(0, 22)
        track.BackgroundColor3 = THEME.CardAlt
        track.Parent = row
        corner(track, 4)
        stroke(track, THEME.BorderDim, 1)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = THEME.Accent
        fill.BorderSizePixel = 0
        fill.Parent = track
        corner(fill, 4)

        local sliderObj = { enabled = true }

        local function setValue(newVal, skipCallback)
            local targetVal = math.clamp(math.floor(newVal / inc + 0.5) * inc, min, max)
            if val == targetVal and skipCallback then return end
            val = targetVal
            local pct = (val - min) / (max - min)
            fill.Size = UDim2.new(pct, 0, 1, 0)
            valLbl.Text = tostring(val) .. suffix
            if not skipCallback and callback then pcall(callback, val) end
        end

        local dragging = false
        local function update(inputPos)
            local relX = math.clamp((inputPos.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            setValue(min + (relX * (max - min)))
        end

        trackConnection(row.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                update(input.Position)
            end
        end))

        trackConnection(UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
                update(input.Position)
            end
        end))

        trackConnection(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end))

        function sliderObj:SetValue(newVal, skipCallback)
            setValue(newVal, skipCallback)
        end

        table.insert(section.options, { row = row, obj = sliderObj })
        return sliderObj
    end

    -- 3. Contained Dropdown (Accordion Expanding Container - Never Overlaps)
    function section:AddList(data)
        local text = data.text or ""
        local values = data.values or {}
        local multi = data.multi == true
        local selected = data.selected or (multi and {} or values[1])
        local callback = data.callback

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 44)
        row.BackgroundTransparency = 1
        row.ClipsDescendants = true
        row.Parent = body

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 14)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextSize = 10
        lbl.TextColor3 = THEME.TextMuted
        lbl.Font = FONT
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        lbl.Parent = row

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 24)
        btn.Position = UDim2.fromOffset(0, 18)
        btn.BackgroundColor3 = THEME.CardAlt
        btn.Text = "  " .. (multi and (type(selected) == "table" and table.concat(selected, ", ") or "None") or tostring(selected or "None"))
        btn.TextColor3 = THEME.Text
        btn.TextSize = 10
        btn.Font = FONT
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.TextTruncate = Enum.TextTruncate.AtEnd
        btn.AutoButtonColor = false
        btn.Parent = row
        corner(btn, 5)
        stroke(btn, THEME.BorderDim, 1)

        local arrow = Instance.new("TextLabel")
        arrow.Size = UDim2.fromOffset(20, 24)
        arrow.Position = UDim2.new(1, -20, 0, 0)
        arrow.BackgroundTransparency = 1
        arrow.Text = "▼"
        arrow.TextColor3 = THEME.AccentBright
        arrow.TextSize = 9
        arrow.Parent = btn

        local dropFrame = Instance.new("Frame")
        dropFrame.Size = UDim2.new(1, 0, 0, 100)
        dropFrame.Position = UDim2.fromOffset(0, 44)
        dropFrame.BackgroundColor3 = THEME.Header
        dropFrame.Visible = false
        dropFrame.Parent = row
        corner(dropFrame, 6)
        stroke(dropFrame, THEME.Accent, 1)

        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1, -4, 1, -4)
        scroll.Position = UDim2.fromOffset(2, 2)
        scroll.BackgroundTransparency = 1
        scroll.ScrollBarThickness = 2
        scroll.ScrollBarImageColor3 = THEME.Accent
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.Parent = dropFrame

        local listLayout = Instance.new("UIListLayout")
        listLayout.Padding = UDim.new(0, 2)
        listLayout.Parent = scroll

        local open = false
        local listObj = { enabled = true, values = values }

        local function refreshText()
            if multi then
                local selList = type(selected) == "table" and selected or {}
                btn.Text = "  " .. (#selList > 0 and table.concat(selList, ", ") or "None")
            else
                btn.Text = "  " .. tostring(selected or "None")
            end
        end

        local function closeDropdown()
            if not open then return end
            open = false
            dropFrame.Visible = false
            row.Size = UDim2.new(1, 0, 0, 44)
            arrow.Text = "▼"
            if activeDropdownCloser == closeDropdown then
                activeDropdownCloser = nil
            end
        end

        local function rebuildOptions()
            if not open then return end
            for _, child in ipairs(scroll:GetChildren()) do
                if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
            end
            local count = #values
            local dropHeight = math.clamp(count * 24 + 6, 28, 120)
            dropFrame.Size = UDim2.new(1, 0, 0, dropHeight)
            row.Size = UDim2.new(1, 0, 0, 44 + dropHeight + 4)

            if count == 0 then
                local emptyLbl = Instance.new("TextLabel")
                emptyLbl.Size = UDim2.new(1, 0, 0, 22)
                emptyLbl.BackgroundTransparency = 1
                emptyLbl.Text = "No items available"
                emptyLbl.TextColor3 = THEME.TextDim
                emptyLbl.TextSize = 10
                emptyLbl.Font = FONT
                emptyLbl.Parent = scroll
                return
            end

            for _, opt in ipairs(values) do
                local optBtn = Instance.new("TextButton")
                optBtn.Size = UDim2.new(1, 0, 0, 22)
                optBtn.BackgroundColor3 = THEME.Card
                optBtn.Text = "  " .. tostring(opt)
                optBtn.TextColor3 = (multi and type(selected) == "table" and table.find(selected, opt)) and THEME.AccentBright or ((opt == selected) and THEME.AccentBright or THEME.TextMuted)
                optBtn.TextSize = 10
                optBtn.Font = FONT
                optBtn.TextXAlignment = Enum.TextXAlignment.Left
                optBtn.AutoButtonColor = false
                optBtn.Parent = scroll
                corner(optBtn, 3)

                optBtn.MouseButton1Click:Connect(function()
                    if multi then
                        selected = type(selected) == "table" and selected or {}
                        local f = table.find(selected, opt)
                        if f then table.remove(selected, f) else table.insert(selected, opt) end
                        optBtn.TextColor3 = table.find(selected, opt) and THEME.AccentBright or THEME.TextMuted
                        refreshText()
                        if callback then pcall(callback, selected) end
                    else
                        selected = opt
                        refreshText()
                        closeDropdown()
                        if callback then pcall(callback, selected) end
                    end
                end)
            end
        end

        trackConnection(btn.MouseButton1Click:Connect(function()
            if open then
                closeDropdown()
            else
                if activeDropdownCloser and activeDropdownCloser ~= closeDropdown then
                    activeDropdownCloser()
                end
                open = true
                activeDropdownCloser = closeDropdown
                arrow.Text = "▲"
                dropFrame.Visible = true
                rebuildOptions()
            end
        end))

        function listObj:Select(val, skipCallback)
            selected = val
            refreshText()
            if open then rebuildOptions() end
            if not skipCallback and callback then pcall(callback, selected) end
        end

        function listObj:ClearValues()
            values = {}
            listObj.values = values
            if open then rebuildOptions() end
        end

        function listObj:AddValue(val)
            table.insert(values, val)
            if open then rebuildOptions() end
        end

        function listObj:SetValues(newVals)
            values = newVals or {}
            listObj.values = values
            if open then rebuildOptions() end
        end

        function listObj:SetText(newTxt)
            lbl.Text = newTxt
        end

        table.insert(section.options, { row = row, obj = listObj })
        return listObj
    end

    -- 4. Contained ScrollList Widget (Searchable Contained List Box - Used for Weapons, Skins, Skyboxes, Sounds)
    function section:AddScrollList(data)
        local text = data.text or ""
        local values = data.values or {}
        local selected = tostring(data.selected or "")
        local callback = data.callback

        local container = Instance.new("Frame")
        container.Name = "ScrollListContainer"
        container.Size = UDim2.new(1, 0, 0, 150)
        container.BackgroundColor3 = THEME.CardAlt
        container.BorderSizePixel = 0
        container.Parent = body
        corner(container, 8)
        stroke(container, THEME.BorderDim, 1)
        padding(container, 6, 6, 6, 6)

        local containerLayout = Instance.new("UIListLayout")
        containerLayout.Padding = UDim.new(0, 4)
        containerLayout.SortOrder = Enum.SortOrder.LayoutOrder
        containerLayout.Parent = container

        -- Search & Title Row
        local topRow = Instance.new("Frame")
        topRow.Size = UDim2.new(1, 0, 0, 22)
        topRow.BackgroundTransparency = 1
        topRow.LayoutOrder = 1
        topRow.Parent = container

        local titleLbl = Instance.new("TextLabel")
        titleLbl.Size = UDim2.new(0.45, 0, 1, 0)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = text ~= "" and text or "Item Selector"
        titleLbl.TextSize = 10
        titleLbl.TextColor3 = THEME.TextMuted
        titleLbl.Font = FONT_BOLD
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
        titleLbl.Parent = topRow

        local searchBox = Instance.new("TextBox")
        searchBox.Size = UDim2.new(0.55, 0, 1, 0)
        searchBox.Position = UDim2.new(0.45, 0, 0, 0)
        searchBox.BackgroundColor3 = THEME.Card
        searchBox.Text = ""
        searchBox.PlaceholderText = "Search..."
        searchBox.PlaceholderColor3 = THEME.TextDim
        searchBox.TextColor3 = THEME.Text
        searchBox.TextSize = 10
        searchBox.Font = FONT
        searchBox.TextXAlignment = Enum.TextXAlignment.Left
        searchBox.ClearTextOnFocus = false
        searchBox.Parent = topRow
        corner(searchBox, 4)
        stroke(searchBox, THEME.BorderDim, 1)
        padding(searchBox, 0, 0, 6, 6)

        -- Scrollable Item Viewport
        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Size = UDim2.new(1, 0, 1, -26)
        scrollFrame.BackgroundTransparency = 1
        scrollFrame.ScrollBarThickness = 2
        scrollFrame.ScrollBarImageColor3 = THEME.Accent
        scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scrollFrame.LayoutOrder = 2
        scrollFrame.Parent = container

        local scrollLayout = Instance.new("UIListLayout")
        scrollLayout.Padding = UDim.new(0, 2)
        scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
        scrollLayout.Parent = scrollFrame

        local scrollListObj = { enabled = true, values = values }

        local renderPending = false
        local function renderItems()
            renderPending = false
            local query = string.lower(searchBox.Text)
            for _, child in ipairs(scrollFrame:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end

            for _, val in ipairs(values) do
                local valStr = tostring(val)
                if query == "" or string.find(string.lower(valStr), query, 1, true) then
                    local isSel = (valStr == selected)
                    local itemBtn = Instance.new("TextButton")
                    itemBtn.Size = UDim2.new(1, 0, 0, 22)
                    itemBtn.BackgroundColor3 = isSel and THEME.AccentDark or THEME.Card
                    itemBtn.Text = "  " .. valStr
                    itemBtn.TextColor3 = isSel and THEME.AccentBright or THEME.TextMuted
                    itemBtn.TextSize = 10
                    itemBtn.Font = isSel and FONT_BOLD or FONT
                    itemBtn.TextXAlignment = Enum.TextXAlignment.Left
                    itemBtn.TextTruncate = Enum.TextTruncate.AtEnd
                    itemBtn.AutoButtonColor = false
                    itemBtn.Parent = scrollFrame
                    corner(itemBtn, 4)
                    if isSel then stroke(itemBtn, THEME.Accent, 1) end

                    itemBtn.MouseButton1Click:Connect(function()
                        selected = valStr
                        renderItems()
                        if callback then pcall(callback, valStr) end
                    end)
                end
            end
        end

        local function scheduleRender()
            if renderPending then return end
            renderPending = true
            task.defer(renderItems)
        end

        trackConnection(searchBox:GetPropertyChangedSignal("Text"):Connect(scheduleRender))
        scheduleRender()

        function scrollListObj:Select(val, skipCallback)
            selected = tostring(val or "")
            scheduleRender()
            if not skipCallback and callback then pcall(callback, selected) end
        end

        function scrollListObj:ClearValues()
            values = {}
            scrollListObj.values = values
            scheduleRender()
        end

        function scrollListObj:AddValue(val)
            table.insert(values, val)
            scheduleRender()
        end

        function scrollListObj:SetValues(newVals)
            values = newVals or {}
            scrollListObj.values = values
            scheduleRender()
        end

        function scrollListObj:SetText(newTxt)
            titleLbl.Text = newTxt
        end

        table.insert(section.options, { row = container, obj = scrollListObj })
        return scrollListObj
    end

    -- 5. Contained Keybind
    function section:AddBind(data)
        local text = data.text or ""
        local bind = data.bind or "None"
        local keycallback = data.keycallback
        local bindName = typeof(bind) == "EnumItem" and bind.Name or tostring(bind)

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 28)
        row.BackgroundTransparency = 1
        row.Parent = body

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -70, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextSize = 11
        lbl.TextColor3 = THEME.TextMuted
        lbl.Font = FONT
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        lbl.Parent = row

        local badge = Instance.new("TextButton")
        badge.Size = UDim2.fromOffset(64, 22)
        badge.Position = UDim2.new(1, -64, 0.5, -11)
        badge.BackgroundColor3 = THEME.CardAlt
        badge.Text = "[" .. bindName .. "]"
        badge.TextColor3 = THEME.AccentBright
        badge.TextSize = 10
        badge.Font = FONT_BOLD
        badge.AutoButtonColor = false
        badge.Parent = row
        corner(badge, 4)
        stroke(badge, THEME.BorderDim, 1)

        local waitingForInput = false
        local listenConn = nil
        local timerThread = nil

        local function cleanupListening()
            if listenConn then
                listenConn:Disconnect()
                listenConn = nil
            end
            if timerThread then
                task.cancel(timerThread)
                timerThread = nil
            end
            waitingForInput = false
        end

        local function updateBadgeVisual()
            local display = tostring(bindName or "None")
            if display == "Always" or display == "ALWAYS" then
                badge.Text = "[Always]"
                badge.TextColor3 = THEME.AccentBright
            elseif display == "None" or display == "NONE" or display == "" then
                badge.Text = "[None]"
                badge.TextColor3 = THEME.TextMuted
            else
                badge.Text = "[" .. display .. "]"
                badge.TextColor3 = THEME.AccentBright
            end
        end
        updateBadgeVisual()

        badge.MouseButton1Click:Connect(function()
            if waitingForInput then
                cleanupListening()
                if bindName == "Always" then
                    bindName = "None"
                else
                    bindName = "Always"
                end
                updateBadgeVisual()
                local cbVal = (bindName == "Always") and "Always" or "None"
                if keycallback then
                    pcall(keycallback, cbVal)
                end
                return
            end

            waitingForInput = true
            badge.Text = "[...]"
            badge.TextColor3 = THEME.TextLight

            listenConn = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    local kc = input.KeyCode
                    cleanupListening()
                    if kc == Enum.KeyCode.Escape or kc == Enum.KeyCode.Backspace then
                        bindName = "None"
                        updateBadgeVisual()
                        if keycallback then pcall(keycallback, "None") end
                    else
                        bindName = kc.Name
                        updateBadgeVisual()
                        if keycallback then pcall(keycallback, kc) end
                    end
                elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    cleanupListening()
                    if bindName == "Always" then
                        bindName = "None"
                    else
                        bindName = "Always"
                    end
                    updateBadgeVisual()
                    local cbVal = (bindName == "Always") and "Always" or "None"
                    if keycallback then
                        pcall(keycallback, cbVal)
                    end
                end
            end)

            timerThread = task.delay(3.5, function()
                if waitingForInput then
                    cleanupListening()
                    updateBadgeVisual()
                end
            end)
        end)

        local bindObj = { enabled = true }
        function bindObj:SetBind(newBind)
            bind = newBind
            bindName = typeof(bind) == "EnumItem" and bind.Name or tostring(bind)
            updateBadgeVisual()
        end

        table.insert(section.options, { row = row, obj = bindObj })
        return bindObj
    end

    -- 6. Contained ColorPicker
    function section:AddColor(data)
        local text = data.text or ""
        local color = data.color or Color3.fromRGB(205, 104, 255)
        local callback = data.callback

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 28)
        row.BackgroundTransparency = 1
        row.Parent = body

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -50, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextSize = 11
        lbl.TextColor3 = THEME.TextMuted
        lbl.Font = FONT
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        lbl.Parent = row

        local chip = Instance.new("TextButton")
        chip.Size = UDim2.fromOffset(36, 18)
        chip.Position = UDim2.new(1, -38, 0.5, -9)
        chip.BackgroundColor3 = color
        chip.Text = ""
        chip.AutoButtonColor = false
        chip.Parent = row
        corner(chip, 4)
        stroke(chip, THEME.BorderDim, 1)

        local colorObj = { enabled = true }
        function colorObj:SetColor(newColor, skipCb)
            if color == newColor and skipCb then return end
            color = newColor
            chip.BackgroundColor3 = color
            if not skipCb and callback then pcall(callback, color) end
        end

        trackConnection(chip.MouseButton1Click:Connect(function()
            local PALETTE = {
                Color3.fromRGB(255, 255, 255),
                Color3.fromRGB(205, 104, 255),
                Color3.fromRGB(157, 48, 255),
                Color3.fromRGB(0, 220, 255),
                Color3.fromRGB(42, 255, 157),
                Color3.fromRGB(255, 75, 125),
                Color3.fromRGB(255, 215, 0),
            }
            local nextIdx = 1
            for idx, c in ipairs(PALETTE) do
                if (c.R - color.R)^2 + (c.G - color.G)^2 + (c.B - color.B)^2 < 0.05 then
                    nextIdx = (idx % #PALETTE) + 1
                    break
                end
            end
            colorObj:SetColor(PALETTE[nextIdx])
        end))

        table.insert(section.options, { row = row, obj = colorObj })
        return colorObj
    end

    -- 7. Contained Button & Chained Button Rows
    function section:AddButton(data)
        local text = data.text or "Button"
        local confirm = data.confirm == true
        local callback = data.callback

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 28)
        row.BackgroundTransparency = 1
        row.Parent = body

        local rowLayout = Instance.new("UIListLayout")
        rowLayout.FillDirection = Enum.FillDirection.Horizontal
        rowLayout.Padding = UDim.new(0, 4)
        rowLayout.Parent = row

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundColor3 = THEME.CardAlt
        btn.Text = text
        btn.TextColor3 = THEME.Text
        btn.TextSize = 10
        btn.Font = FONT_BOLD
        btn.AutoButtonColor = false
        btn.Parent = row
        corner(btn, 5)
        stroke(btn, THEME.BorderDim, 1)

        local btnObj = { enabled = true, count = 1, buttons = { btn } }

        local clickedOnce = false
        trackConnection(btn.MouseButton1Click:Connect(function()
            if confirm and not clickedOnce then
                clickedOnce = true
                btn.Text = "Confirm?"
                btn.TextColor3 = THEME.Red
                task.delay(3, function()
                    clickedOnce = false
                    btn.Text = text
                    btn.TextColor3 = THEME.Text
                end)
                return
            end
            clickedOnce = false
            btn.Text = text
            btn.TextColor3 = THEME.Text
            if callback then pcall(callback) end
        end))

        function btnObj:AddButton(subData)
            btnObj.count = btnObj.count + 1
            local count = btnObj.count
            for _, b in ipairs(btnObj.buttons) do
                b.Size = UDim2.new(1 / count, -((count - 1) * 4) / count, 1, 0)
            end

            local subBtn = Instance.new("TextButton")
            subBtn.Size = UDim2.new(1 / count, -((count - 1) * 4) / count, 1, 0)
            subBtn.BackgroundColor3 = THEME.CardAlt
            subBtn.Text = subData.text or "Button"
            subBtn.TextColor3 = THEME.Text
            subBtn.TextSize = 10
            subBtn.Font = FONT_BOLD
            subBtn.AutoButtonColor = false
            subBtn.Parent = row
            corner(subBtn, 5)
            stroke(subBtn, THEME.BorderDim, 1)
            table.insert(btnObj.buttons, subBtn)

            trackConnection(subBtn.MouseButton1Click:Connect(function()
                if subData.callback then pcall(subData.callback) end
            end))
            return btnObj
        end

        table.insert(section.options, { row = row, obj = btnObj })
        return btnObj
    end

    -- 8. Contained Text Box
    function section:AddBox(data)
        local text = data.text or ""
        local input = data.input or ""
        local callback = data.callback

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 44)
        row.BackgroundTransparency = 1
        row.Parent = body

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 14)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextSize = 10
        lbl.TextColor3 = THEME.TextMuted
        lbl.Font = FONT
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        lbl.Parent = row

        local box = Instance.new("TextBox")
        box.Size = UDim2.new(1, 0, 0, 24)
        box.Position = UDim2.fromOffset(0, 18)
        box.BackgroundColor3 = THEME.CardAlt
        box.Text = tostring(input)
        box.PlaceholderText = "Type here..."
        box.TextColor3 = THEME.Text
        box.PlaceholderColor3 = THEME.TextDim
        box.TextSize = 10
        box.Font = FONT
        box.TextXAlignment = Enum.TextXAlignment.Left
        box.ClearTextOnFocus = false
        box.Parent = row
        corner(box, 5)
        stroke(box, THEME.BorderDim, 1)
        padding(box, 0, 0, 6, 6)

        local boxObj = { enabled = true }
        trackConnection(box.FocusLost:Connect(function()
            if callback then pcall(callback, box.Text) end
        end))

        function boxObj:SetInput(val, skipCallback)
            box.Text = tostring(val or "")
            if not skipCallback and callback then pcall(callback, box.Text) end
        end

        table.insert(section.options, { row = row, obj = boxObj })
        return boxObj
    end

    -- 9. Text & Separator
    function section:AddText(data)
        local row = Instance.new("TextLabel")
        row.Size = UDim2.new(1, 0, 0, 18)
        row.BackgroundTransparency = 1
        row.Text = data.text or ""
        row.TextColor3 = THEME.TextDim
        row.TextSize = 10
        row.Font = FONT
        row.TextXAlignment = Enum.TextXAlignment.Left
        row.Parent = body
        return row
    end

    function section:AddSeparator(data)
        local sep = Instance.new("Frame")
        sep.Size = UDim2.new(1, 0, 0, 1)
        sep.BackgroundColor3 = THEME.BorderDim
        sep.BorderSizePixel = 0
        sep.Parent = body
        return sep
    end

    function section:UpdateOptions()
        for _, opt in ipairs(section.options) do
            if opt.obj and opt.obj.enabled ~= nil then
                opt.row.Visible = opt.obj.enabled
            end
        end
    end

    return section
end

--//==================================================
--// ATOMWARE MOBILE WINDOW OBJECT
--//==================================================

local AtomwareMobileWindow = {
    tabs = {},
    open = true,
    uiDragging = false,
    ScreenGui = ScreenGui,
    MainFrame = MainFrame,
}

function AtomwareMobileWindow:init() return true end
function AtomwareMobileWindow:NewWindow(spec) return self end

function AtomwareMobileWindow:SelectTab(name)
    local displayName = normalizeTabName(name)
    switchPage(displayName)
end

function AtomwareMobileWindow:SwitchPage(name)
    self:SelectTab(name)
end

function AtomwareMobileWindow:AddTab(rawName, order)
    local displayName, icon = normalizeTabName(rawName)
    local existing = self.tabs[rawName] or self.tabs[displayName]
    if existing then return existing end

    local page = getOrCreatePage(displayName)

    -- Create Tab Button in Top Scrollable Tab Bar
    local btn = Instance.new("TextButton")
    btn.Name = displayName .. "Tab"
    btn.Size = UDim2.fromOffset(88, 28)
    btn.LayoutOrder = TAB_ORDER[displayName] or 99
    btn.BackgroundColor3 = (displayName == CurrentPageName) and THEME.AccentDark or THEME.Card
    btn.Text = icon .. " " .. displayName
    btn.TextColor3 = (displayName == CurrentPageName) and THEME.AccentBright or THEME.TextMuted
    btn.TextSize = 11
    btn.Font = FONT_BOLD
    btn.AutoButtonColor = false
    btn.Parent = TabBar
    corner(btn, 6)
    stroke(btn, THEME.BorderDim, 1)

    TabButtons[displayName] = btn
    trackConnection(btn.MouseButton1Click:Connect(function()
        switchPage(displayName)
    end))

    local tabObj = {
        name = displayName,
        page = page,
        sections = {},
    }

    function tabObj:AddSection(text, side, order)
        local card, body = createMobileCard(page, text, side)
        local section = wrapMobileSection(card, body, text)
        table.insert(tabObj.sections, section)
        return section
    end

    function tabObj:AddSubTabs(subNames) end

    function tabObj:UpdateSections()
        for _, sec in ipairs(tabObj.sections) do
            sec:UpdateOptions()
        end
    end

    self.tabs[rawName] = tabObj
    self.tabs[displayName] = tabObj
    return tabObj
end

function AtomwareMobileWindow:UpdateTabs()
    switchPage("Visuals")
end

function AtomwareMobileWindow:SetOpen(visible)
    setUIVisible(visible)
end

function AtomwareMobileWindow:CreateSettingsTab(menu)
    return self:AddTab("settings", 999)
end

_G.AtomwareWindow = AtomwareMobileWindow
_G.AtomwareUILoaded = true

return AtomwareMobileWindow
