--[[
    Atomware Rivals - main_ui.lua
    Desktop PC UI Framework for Atomware Rivals
    Features Obsidian Cyberpunk Theme, Responsive Two-Column Cards, Sidebar Navigation,
    and complete UI widget system compatible with all Rivals features.
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
            if not ok then warn("Atomware: event '" .. name .. "' failed: " .. tostring(err)) end
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
            if not ok then warn("Atomware: event '" .. name .. "' failed: " .. tostring(err)) end
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
    Background      = Color3.fromRGB(6, 4, 12),
    Header          = Color3.fromRGB(10, 7, 20),
    Sidebar         = Color3.fromRGB(10, 7, 20),
    Card            = Color3.fromRGB(14, 9, 26),
    CardAlt         = Color3.fromRGB(19, 13, 35),
    CardHover       = Color3.fromRGB(25, 16, 45),

    Border          = Color3.fromRGB(90, 38, 165),
    BorderDim       = Color3.fromRGB(45, 24, 80),
    Accent          = Color3.fromRGB(157, 48, 255),
    AccentBright    = Color3.fromRGB(205, 104, 255),
    AccentDark      = Color3.fromRGB(70, 24, 125),

    Text            = Color3.fromRGB(245, 241, 255),
    TextMuted       = Color3.fromRGB(155, 142, 185),
    TextDim         = Color3.fromRGB(95, 82, 122),

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
--// SCREENGUI & MAIN CONTAINER
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
ScreenGui.Name = "AtomwareRivalsUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 100
ScreenGui.Parent = getGuiParent()

if _G.AtomwareConfig then _G.AtomwareConfig:AttachUI(ScreenGui, "Desktop PC") end

local activeDropdownCloser = nil

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.fromOffset(720, 520)
MainFrame.Position = UDim2.new(0.5, -360, 0.5, -260)
MainFrame.BackgroundColor3 = THEME.Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
corner(MainFrame, 10)
stroke(MainFrame, THEME.Border, 1.5)

-- Header Frame (Draggable)
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 46)
Header.BackgroundColor3 = THEME.Header
Header.BorderSizePixel = 0
Header.Parent = MainFrame
corner(Header, 10)

-- Header separator line
local HeaderSep = Instance.new("Frame")
HeaderSep.Size = UDim2.new(1, 0, 0, 1)
HeaderSep.Position = UDim2.new(0, 0, 1, -1)
HeaderSep.BackgroundColor3 = THEME.BorderDim
HeaderSep.BorderSizePixel = 0
HeaderSep.Parent = Header

-- Logo & Title
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(0, 120, 1, 0)
Title.Position = UDim2.fromOffset(16, 0)
Title.BackgroundTransparency = 1
Title.Text = "ATOMWARE"
Title.TextColor3 = THEME.AccentBright
Title.TextSize = 15
Title.Font = FONT_BOLD
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Badge = Instance.new("TextLabel")
Badge.Name = "Badge"
Badge.Size = UDim2.fromOffset(58, 20)
Badge.Position = UDim2.fromOffset(136, 13)
Badge.BackgroundColor3 = THEME.AccentDark
Badge.Text = "RIVALS"
Badge.TextColor3 = THEME.Text
Badge.TextSize = 10
Badge.Font = FONT_BOLD
Badge.Parent = Header
corner(Badge, 4)
stroke(Badge, THEME.Accent, 1)

-- Online Pulse Dot
local StatusDot = Instance.new("Frame")
StatusDot.Name = "StatusDot"
StatusDot.Size = UDim2.fromOffset(8, 8)
StatusDot.Position = UDim2.fromOffset(204, 19)
StatusDot.BackgroundColor3 = THEME.Green
StatusDot.BorderSizePixel = 0
StatusDot.Parent = Header
corner(StatusDot, 4)

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.fromOffset(28, 28)
CloseBtn.Position = UDim2.new(1, -38, 0.5, -14)
CloseBtn.BackgroundColor3 = THEME.CardAlt
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = THEME.TextMuted
CloseBtn.TextSize = 12
CloseBtn.Font = FONT_BOLD
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = Header
corner(CloseBtn, 6)
stroke(CloseBtn, THEME.BorderDim, 1)

-- Minimize Button
local MinBtn = Instance.new("TextButton")
MinBtn.Name = "MinBtn"
MinBtn.Size = UDim2.fromOffset(28, 28)
MinBtn.Position = UDim2.new(1, -72, 0.5, -14)
MinBtn.BackgroundColor3 = THEME.CardAlt
MinBtn.Text = "—"
MinBtn.TextColor3 = THEME.TextMuted
MinBtn.TextSize = 12
MinBtn.Font = FONT_BOLD
MinBtn.AutoButtonColor = false
MinBtn.Parent = Header
corner(MinBtn, 6)
stroke(MinBtn, THEME.BorderDim, 1)

-- Dragging Logic
local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
trackConnection(Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end))

trackConnection(UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end))

trackConnection(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end))

-- Toggle UI Visibility Keybind
local MenuOpen = true
local function setMenuVisible(visible)
    MenuOpen = visible
    MainFrame.Visible = MenuOpen
end

trackConnection(CloseBtn.MouseButton1Click:Connect(function()
    setMenuVisible(false)
end))

trackConnection(MinBtn.MouseButton1Click:Connect(function()
    setMenuVisible(false)
end))

trackConnection(UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.End or input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.Insert then
        setMenuVisible(not MenuOpen)
    end
end))

--//==================================================
--// SIDEBAR & TABS NAVIGATION
--//==================================================

local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 160, 1, -46)
Sidebar.Position = UDim2.fromOffset(0, 46)
Sidebar.BackgroundColor3 = THEME.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame
padding(Sidebar, 12, 12, 8, 8)

local SidebarSep = Instance.new("Frame")
SidebarSep.Size = UDim2.new(0, 1, 1, 0)
SidebarSep.Position = UDim2.new(1, -1, 0, 0)
SidebarSep.BackgroundColor3 = THEME.BorderDim
SidebarSep.BorderSizePixel = 0
SidebarSep.Parent = Sidebar

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.Padding = UDim.new(0, 5)
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Parent = Sidebar

-- Content Area
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -164, 1, -50)
ContentArea.Position = UDim2.fromOffset(164, 48)
ContentArea.BackgroundTransparency = 1
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

local function switchPage(name)
    CurrentPageName = name
    for pName, pFrame in pairs(Pages) do
        pFrame.Visible = (pName == name)
    end
    for pName, btn in pairs(TabButtons) do
        local active = (pName == name)
        tween(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = active and THEME.AccentDark or THEME.Card,
            TextColor3 = active and THEME.AccentBright or THEME.TextMuted,
        })
    end
end

local function getOrCreatePage(name)
    if Pages[name] then return Pages[name] end

    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.Size = UDim2.new(1, 0, 1, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = THEME.Accent
    page.Visible = (name == CurrentPageName)
    page.Parent = ContentArea
    padding(page, 8, 12, 8, 8)

    local columns = {}
    for i = 1, 2 do
        local column = Instance.new("Frame")
        column.Name = i == 1 and "LeftColumn" or "RightColumn"
        column.BackgroundTransparency = 1
        column.Position = UDim2.new((i - 1) * 0.5, i == 1 and 0 or 4, 0, 0)
        column.Size = UDim2.new(0.5, -6, 0, 0)
        column.AutomaticSize = Enum.AutomaticSize.Y
        column.Parent = page

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 10)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = column
        columns[i] = column
    end

    PageColumns[page] = { Columns = columns, Counts = { 0, 0 } }
    Pages[name] = page
    return page
end

local TAB_ICONS = {
    legit = "🎯",
    rage = "⚡",
    visuals = "👁️",
    move = "🏃",
    movement = "🏃",
    world = "🌍",
    items = "🎨",
    cosmetics = "🎨",
    misc = "🛠️",
    extras = "📁",
    configs = "⚙️",
    settings = "⚙️",
}

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
    return name:sub(1,1):upper() .. name:sub(2), TAB_ICONS[lower] or "•"
end

--//==================================================
--// WIDGET BUILDERS & CARDS
--//==================================================

local function createCard(page, title, side)
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
    corner(card, 8)
    stroke(card, THEME.BorderDim, 1)
    padding(card, 8, 8, 8, 8)

    local cardLayout = Instance.new("UIListLayout")
    cardLayout.Padding = UDim.new(0, 5)
    cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
    cardLayout.Parent = card

    -- Header
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
    bodyLayout.Padding = UDim.new(0, 5)
    bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    bodyLayout.Parent = body

    return card, body
end

-- SECTION OBJECT WRAPPER (Compatible with Rivals kit)
local function wrapSection(card, body, title)
    local section = {
        card = card,
        body = body,
        text = title,
        options = {},
    }

    function section:AddToggle(data)
        local text = data.text or ""
        local state = data.state == true
        local callback = data.callback

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 26)
        row.BackgroundTransparency = 1
        row.Parent = body

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -74, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextSize = 11
        lbl.TextColor3 = state and THEME.Text or THEME.TextMuted
        lbl.Font = FONT
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromOffset(36, 18)
        btn.Position = UDim2.new(1, -38, 0.5, -9)
        btn.BackgroundColor3 = state and THEME.Accent or THEME.CardAlt
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = row
        corner(btn, 9)
        stroke(btn, state and THEME.AccentBright or THEME.BorderDim, 1)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.fromOffset(12, 12)
        knob.Position = state and UDim2.new(1, -15, 0.5, -6) or UDim2.fromOffset(3, 3)
        knob.BackgroundColor3 = THEME.Text
        knob.Parent = btn
        corner(knob, 6)

        local toggleObj = { enabled = true }

        local function setState(val, skipCallback)
            local newVal = (val == true)
            if state == newVal and skipCallback then return end
            state = newVal
            lbl.TextColor3 = state and THEME.Text or THEME.TextMuted
            if skipCallback then
                btn.BackgroundColor3 = state and THEME.Accent or THEME.CardAlt
                knob.Position = state and UDim2.new(1, -15, 0.5, -6) or UDim2.fromOffset(3, 3)
            else
                tween(btn, TweenInfo.new(0.12), { BackgroundColor3 = state and THEME.Accent or THEME.CardAlt })
                tween(knob, TweenInfo.new(0.12), { Position = state and UDim2.new(1, -15, 0.5, -6) or UDim2.fromOffset(3, 3) })
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
            chip.Size = UDim2.fromOffset(16, 16)
            chip.Position = UDim2.new(1, -60, 0.5, -8)
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

            -- Simple color cycle or palette popup
            trackConnection(chip.MouseButton1Click:Connect(function()
                -- Quick cycle: White -> Purple -> Cyan -> Green -> Red -> Yellow
                local PALETTE = {
                    Color3.fromRGB(255, 255, 255),
                    Color3.fromRGB(205, 104, 255),
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

    function section:AddSlider(data)
        local text = data.text or ""
        local min = data.min or 0
        local max = data.max or 100
        local inc = data.increment or 1
        local val = math.clamp(data.value or min, min, max)
        local suffix = data.suffix or ""
        local callback = data.callback

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 36)
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
        track.Size = UDim2.new(1, 0, 0, 6)
        track.Position = UDim2.fromOffset(0, 20)
        track.BackgroundColor3 = THEME.CardAlt
        track.Parent = row
        corner(track, 3)
        stroke(track, THEME.BorderDim, 1)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = THEME.Accent
        fill.BorderSizePixel = 0
        fill.Parent = track
        corner(fill, 3)

        local sliderObj = { enabled = true }

        local function setValue(newVal, skipCallback)
            local computedVal = math.clamp(math.floor(newVal / inc + 0.5) * inc, min, max)
            if val == computedVal and skipCallback then return end
            val = computedVal
            local pct = (val - min) / (max - min)
            fill.Size = UDim2.new(pct, 0, 1, 0)
            valLbl.Text = tostring(val) .. suffix
            if not skipCallback and callback then
                pcall(callback, val)
            end
        end

        local dragging = false
        local function update(inputPos)
            local relX = math.clamp((inputPos.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            setValue(min + (relX * (max - min)))
        end

        trackConnection(row.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                update(input.Position)
            end
        end))

        trackConnection(UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                update(input.Position)
            end
        end))

        trackConnection(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end))

        function sliderObj:SetValue(newVal, skipCallback)
            setValue(newVal, skipCallback)
        end

        table.insert(section.options, { row = row, obj = sliderObj })
        return sliderObj
    end

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
        corner(dropFrame, 5)
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
            local dropHeight = math.clamp(count * 22 + 4, 28, 130)
            dropFrame.Size = UDim2.new(1, 0, 0, dropHeight)
            row.Size = UDim2.new(1, 0, 0, 44 + dropHeight + 4)

            if count == 0 then
                local emptyLbl = Instance.new("TextLabel")
                emptyLbl.Size = UDim2.new(1, 0, 0, 20)
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
                optBtn.Size = UDim2.new(1, 0, 0, 20)
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

    function section:AddScrollList(data)
        return section:AddList(data)
    end

    function section:AddBind(data)
        local text = data.text or ""
        local bind = data.bind or "None"
        local keycallback = data.keycallback
        local bindName = typeof(bind) == "EnumItem" and bind.Name or tostring(bind)

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 26)
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
        lbl.Parent = row

        local badge = Instance.new("TextButton")
        badge.Size = UDim2.fromOffset(60, 20)
        badge.Position = UDim2.new(1, -60, 0.5, -10)
        badge.BackgroundColor3 = THEME.CardAlt
        badge.Text = "[" .. bindName .. "]"
        badge.TextColor3 = THEME.AccentBright
        badge.TextSize = 10
        badge.Font = FONT_BOLD
        badge.AutoButtonColor = false
        badge.Parent = row
        corner(badge, 4)
        stroke(badge, THEME.BorderDim, 1)

        local listening = false
        local bindObj = { enabled = true }

        trackConnection(badge.MouseButton1Click:Connect(function()
            listening = true
            badge.Text = "[...]"
            badge.TextColor3 = THEME.Green
        end))

        trackConnection(UserInputService.InputBegan:Connect(function(input, gpe)
            if not listening then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                listening = false
                bind = input.KeyCode
                bindName = bind.Name
                badge.Text = "[" .. bindName .. "]"
                badge.TextColor3 = THEME.AccentBright
                if keycallback then pcall(keycallback, bind) end
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
                listening = false
                bindName = input.UserInputType.Name
                badge.Text = "[" .. bindName .. "]"
                badge.TextColor3 = THEME.AccentBright
                if keycallback then pcall(keycallback, input.UserInputType) end
            end
        end))

        function bindObj:SetBind(newBind)
            bind = newBind
            bindName = typeof(bind) == "EnumItem" and bind.Name or tostring(bind)
            badge.Text = "[" .. bindName .. "]"
        end

        table.insert(section.options, { row = row, obj = bindObj })
        return bindObj
    end

    function section:AddColor(data)
        local text = data.text or ""
        local color = data.color or Color3.fromRGB(205, 104, 255)
        local callback = data.callback

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 26)
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

    function section:AddButton(data)
        local text = data.text or "Button"
        local confirm = data.confirm == true
        local callback = data.callback

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 26)
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
                btn.Text = "Confirm " .. text .. "?"
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
        padding(box, 0, 0, 8, 8)

        local boxObj = { enabled = true }

        trackConnection(box.FocusLost:Connect(function(enter)
            if callback then pcall(callback, box.Text) end
        end))

        function boxObj:SetInput(val, skipCallback)
            box.Text = tostring(val or "")
            if not skipCallback and callback then pcall(callback, box.Text) end
        end

        table.insert(section.options, { row = row, obj = boxObj })
        return boxObj
    end

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
--// ATOMWARE WINDOW OBJECT
--//==================================================

local AtomwareWindow = {
    tabs = {},
    open = true,
    uiDragging = false,
    ScreenGui = ScreenGui,
    MainFrame = MainFrame,
}

function AtomwareWindow:init() return true end
function AtomwareWindow:NewWindow(spec) return self end
function AtomwareWindow:SelectTab(name)
    local displayName = normalizeTabName(name)
    switchPage(displayName)
end
function AtomwareWindow:SwitchPage(name)
    self:SelectTab(name)
end

function AtomwareWindow:AddTab(rawName, order)
    local displayName, icon = normalizeTabName(rawName)
    local existing = self.tabs[rawName] or self.tabs[displayName]
    if existing then return existing end

    local page = getOrCreatePage(displayName)

    -- Create Sidebar Tab Button
    local btn = Instance.new("TextButton")
    btn.Name = displayName .. "Tab"
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.LayoutOrder = TAB_ORDER[displayName] or 99
    btn.BackgroundColor3 = (displayName == CurrentPageName) and THEME.AccentDark or THEME.Card
    btn.Text = "  " .. icon .. "  " .. displayName
    btn.TextColor3 = (displayName == CurrentPageName) and THEME.AccentBright or THEME.TextMuted
    btn.TextSize = 11
    btn.Font = FONT_BOLD
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    btn.Parent = Sidebar
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
        local card, body = createCard(page, text, side)
        local section = wrapSection(card, body, text)
        table.insert(tabObj.sections, section)
        return section
    end

    function tabObj:AddSubTabs(subNames)
        -- Subtabs supported via tab sub-sections
    end

    function tabObj:UpdateSections()
        for _, sec in ipairs(tabObj.sections) do
            sec:UpdateOptions()
        end
    end

    self.tabs[rawName] = tabObj
    self.tabs[displayName] = tabObj
    return tabObj
end

function AtomwareWindow:UpdateTabs()
    switchPage("Visuals")
end

function AtomwareWindow:SetOpen(visible)
    setMenuVisible(visible)
end

function AtomwareWindow:CreateSettingsTab(menu)
    return self:AddTab("settings", 999)
end

_G.AtomwareWindow = AtomwareWindow
_G.AtomwareUILoaded = true

return AtomwareWindow
