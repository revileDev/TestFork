--[=[
    Universal Exploitation & Visuals Suite
    UI Title: "matthews a hoe ass boy"
    Architecture: 100% Pure Native Roblox Instances (ScreenGui & BillboardGui)
    Theme: Sleek Red & Dark Carbon (#FF2B2B / #0F0F12 / #18191E)
    Compatibility: Delta Mobile, Arceus X, Codex, PC (No Drawing Library Needed!)
]=]

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Parent resolver for executors (gethui / CoreGui / PlayerGui)
local function GetUIParent()
    if typeof(gethui) == "function" then
        local success, res = pcall(gethui)
        if success and res then return res end
    end
    local success, _ = pcall(function() return CoreGui.Name end)
    if success then return CoreGui end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- Cleanup existing instances if running
local env = (typeof(getgenv) == "function" and getgenv()) or _G
if type(env) == "table" and type(env.UNIVERSAL_SUITE_UNLOAD) == "function" then
    pcall(env.UNIVERSAL_SUITE_UNLOAD)
end

local mousemove   = (typeof(mousemoverel)      == "function" and mousemoverel)      or nil
local hookMeta    = (typeof(hookmetamethod)    == "function" and hookmetamethod)    or nil
local getNamecall = (typeof(getnamecallmethod) == "function" and getnamecallmethod) or nil
local checkCaller = (typeof(checkcaller)       == "function" and checkcaller)       or function() return false end
local newClosure  = (typeof(newcclosure)       == "function" and newcclosure)       or function(f) return f end

-- ============================================================================
-- STATE MANAGEMENT
-- ============================================================================

local State = {
    Running   = true,
    UIVisible = true,
    ActiveTab = "Aim",

    -- Aim Settings
    AimAssist     = false,
    SilentAim     = false,
    AimPart       = "Head",
    AimSmoothness = 0.25,
    FOV           = 120,
    ShowFOV       = true,
    FOVColor      = Color3.fromRGB(255, 43, 43),

    -- Visuals Settings
    ESPEnabled          = true,
    BoxType             = "Full", -- "Full", "Corner"
    BoxFill             = true,
    BoxFillTransparency = 0.65,
    BoxColor1           = Color3.fromRGB(255, 43, 43),

    Tracers      = true,
    TracerOrigin = "Bottom", -- "Bottom", "Mouse", "Center"
    TracerColor  = Color3.fromRGB(255, 43, 43),

    -- Material Chams Settings
    ChamsEnabled     = true,
    ChamsMaterial    = "ForceField",
    ChamsSeeThrough  = true,
    ChamsTeamCheck   = false,
    ChamsColor1      = Color3.fromRGB(255, 43, 43),
    ChamsColor2      = Color3.fromRGB(20, 20, 255),
    ChamsUseGradient = true,
    ChamsTransparency = 0.2,

    -- World Settings
    Fullbright     = false,
    NoClip         = false,
    NoFog          = false,
    WalkSpeedMod   = false,
    WalkSpeedValue = 16,
    JumpPowerMod   = false,
    JumpPowerValue = 50,
}

local ChamsMaterials = {
    ["ForceField"] = { material = Enum.Material.ForceField,   reflectance = 0,   tint = true  },
    ["Neon"]       = { material = Enum.Material.Neon,         reflectance = 0,   tint = true  },
    ["Glass"]      = { material = Enum.Material.Glass,        reflectance = 0.3, tint = true  },
    ["Marble"]     = { material = Enum.Material.Marble,       reflectance = 0,   tint = false },
    ["Foil"]       = { material = Enum.Material.Foil,         reflectance = 0.4, tint = false },
    ["Metal"]      = { material = Enum.Material.DiamondPlate, reflectance = 0.5, tint = false },
    ["Wood"]       = { material = Enum.Material.WoodPlanks,   reflectance = 0,   tint = false },
    ["Ice"]        = { material = Enum.Material.Ice,          reflectance = 0.2, tint = true  },
}

local ChamApplied = {}
local Connections  = {}
local OriginalLighting = {
    Ambient        = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness     = Lighting.Brightness,
    FogEnd         = Lighting.FogEnd,
}

local PointerPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

-- ============================================================================
-- ROOT GUI CONTAINER
-- ============================================================================

local SuiteGui = Instance.new("ScreenGui")
SuiteGui.Name = "UniversalSuiteGui"
SuiteGui.ResetOnSpawn = false
SuiteGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SuiteGui.DisplayOrder = 999
SuiteGui.Parent = GetUIParent()

-- Tracer & Visuals Overlay Layer (Renders under the UI Window)
local OverlayLayer = Instance.new("Frame")
OverlayLayer.Name = "OverlayLayer"
OverlayLayer.Size = UDim2.new(1, 0, 1, 0)
OverlayLayer.BackgroundTransparency = 1
OverlayLayer.ZIndex = 1
OverlayLayer.Parent = SuiteGui

-- ============================================================================
-- NATIVE FOV CIRCLE (100% Reliable GUI on Delta)
-- ============================================================================

local FOVFrame = Instance.new("Frame")
FOVFrame.Name = "FOVFrame"
FOVFrame.AnchorPoint = Vector2.new(0.5, 0.5)
FOVFrame.BackgroundTransparency = 1
FOVFrame.Visible = State.ShowFOV
FOVFrame.ZIndex = 2
FOVFrame.Parent = OverlayLayer

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVFrame

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Thickness = 1.5
FOVStroke.Color = State.FOVColor
FOVStroke.Transparency = 0.2
FOVStroke.Parent = FOVFrame

local function UpdateFOV()
    FOVFrame.Visible = State.ShowFOV
    FOVFrame.Size = UDim2.new(0, State.FOV * 2, 0, State.FOV * 2)
    FOVFrame.Position = UDim2.new(0, PointerPos.X, 0, PointerPos.Y)
    FOVStroke.Color = State.FOVColor
end

-- ============================================================================
-- AIM ENGINE & TARGETING
-- ============================================================================

local function IsAlive(plr)
    if not plr or not plr.Character then return false end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function GetClosestTarget()
    local closest, shortestDist = nil, State.FOV
    local mousePos = PointerPos

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and IsAlive(plr) then
            local targetPart = plr.Character:FindFirstChild(State.AimPart)
                            or plr.Character:FindFirstChild("HumanoidRootPart")
            if targetPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closest = {
                            Player = plr,
                            Part   = targetPart,
                            Screen = Vector2.new(screenPos.X, screenPos.Y),
                        }
                    end
                end
            end
        end
    end
    return closest
end

-- Silent Aim hook
if hookMeta and getNamecall then
    local origNamecall
    origNamecall = hookMeta(game, "__namecall", newClosure(function(self, ...)
        local method = getNamecall()
        if State.Running and State.SilentAim and not checkCaller() then
            if method == "FireServer" or method == "InvokeServer" then
                local target = GetClosestTarget()
                if target then
                    local args = { ... }
                    for i, arg in ipairs(args) do
                        if typeof(arg) == "Vector3" then
                            args[i] = target.Part.Position
                        elseif typeof(arg) == "CFrame" then
                            args[i] = CFrame.new(arg.Position, target.Part.Position)
                        end
                    end
                    return origNamecall(self, table.unpack(args))
                end
            end
        end
        return origNamecall(self, ...)
    end))
end

-- ============================================================================
-- NATIVE ESP ENGINE (BILLBOARDGUI + 2D SCREEN TRACERS)
-- ============================================================================

local PlayerESP = {}

local function CleanupPlayerESP(plr)
    if PlayerESP[plr] then
        if PlayerESP[plr].Billboard then
            pcall(function() PlayerESP[plr].Billboard:Destroy() end)
        end
        if PlayerESP[plr].TracerLine then
            pcall(function() PlayerESP[plr].TracerLine:Destroy() end)
        end
        PlayerESP[plr] = nil
    end
end

local function CreateNativeESP(plr)
    local char = plr.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- 1. Native 3D Billboard ESP Box (Renders automatically in 3D world, 0 lag)
    local bb = Instance.new("BillboardGui")
    bb.Name = "ESP_Box"
    bb.Adornee = root
    bb.Size = UDim2.new(4.5, 0, 6, 0)
    bb.AlwaysOnTop = true
    bb.ResetOnSpawn = false
    bb.Parent = SuiteGui

    local boxFrame = Instance.new("Frame")
    boxFrame.Name = "BoxFrame"
    boxFrame.Size = UDim2.new(1, 0, 1, 0)
    boxFrame.BackgroundColor3 = State.BoxColor1
    boxFrame.BackgroundTransparency = State.BoxFill and State.BoxFillTransparency or 1
    boxFrame.BorderSizePixel = 0
    boxFrame.Parent = bb

    local stroke = Instance.new("UIStroke")
    stroke.Name = "BoxStroke"
    stroke.Color = State.BoxColor1
    stroke.Thickness = 1.5
    stroke.Parent = boxFrame

    -- Name Tag above ESP Box
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0, 14)
    nameLabel.Position = UDim2.new(0, 0, 0, -18)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = plr.DisplayName
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 11
    nameLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
    nameLabel.Parent = boxFrame

    local nameStroke = Instance.new("UIStroke")
    nameStroke.Color = Color3.fromRGB(0, 0, 0)
    nameStroke.Thickness = 1
    nameStroke.Parent = nameLabel

    -- 2. Native Screen Tracer Line
    local tracerLine = Instance.new("Frame")
    tracerLine.Name = "Tracer_" .. plr.Name
    tracerLine.AnchorPoint = Vector2.new(0, 0.5)
    tracerLine.BackgroundColor3 = State.TracerColor
    tracerLine.BorderSizePixel = 0
    tracerLine.ZIndex = 1
    tracerLine.Visible = false
    tracerLine.Parent = OverlayLayer

    PlayerESP[plr] = {
        Billboard = bb,
        BoxFrame = boxFrame,
        BoxStroke = stroke,
        NameLabel = nameLabel,
        TracerLine = tracerLine,
    }
end

local function UpdateESP()
    local vp = Camera.ViewportSize
    local origin = Vector2.new(vp.X / 2, vp.Y)
    if State.TracerOrigin == "Mouse" then
        origin = PointerPos
    elseif State.TracerOrigin == "Center" then
        origin = Vector2.new(vp.X / 2, vp.Y / 2)
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and IsAlive(plr) and State.ESPEnabled then
            if not PlayerESP[plr] or not PlayerESP[plr].Billboard.Parent then
                CreateNativeESP(plr)
            end

            local esp = PlayerESP[plr]
            if esp and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local root = plr.Character.HumanoidRootPart
                local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)

                -- Update Box Appearance
                esp.Billboard.Enabled = onScreen
                esp.BoxStroke.Color = State.BoxColor1
                esp.BoxFrame.BackgroundColor3 = State.BoxColor1
                esp.BoxFrame.BackgroundTransparency = State.BoxFill and State.BoxFillTransparency or 1

                -- Update Tracers (Math-based rotated GUI line)
                if State.Tracers and onScreen then
                    local target = Vector2.new(screenPos.X, screenPos.Y)
                    local dist = (target - origin).Magnitude
                    local angle = math.deg(math.atan2(target.Y - origin.Y, target.X - origin.X))

                    esp.TracerLine.Visible = true
                    esp.TracerLine.Size = UDim2.new(0, dist, 0, 1.5)
                    esp.TracerLine.Position = UDim2.new(0, origin.X, 0, origin.Y)
                    esp.TracerLine.Rotation = angle
                    esp.TracerLine.BackgroundColor3 = State.TracerColor
                else
                    esp.TracerLine.Visible = false
                end
            end
        else
            CleanupPlayerESP(plr)
        end
    end
end

-- ============================================================================
-- MATERIAL CHAMS ENGINE
-- ============================================================================

local function RestoreChams(plr)
    local rec = ChamApplied[plr]
    if not rec then return end
    for part, orig in pairs(rec.originals) do
        if part and part.Parent then
            part.Material     = orig.Material
            part.Reflectance  = orig.Reflectance
            part.Color        = orig.Color
            part.Transparency = orig.Transparency
            if orig.TextureID ~= nil and part:IsA("MeshPart") then
                part.TextureID = orig.TextureID
            end
        end
    end
    for inst, parentRef in pairs(rec.hidden) do
        if inst then pcall(function() inst.Parent = parentRef end) end
    end
    if rec.highlight then rec.highlight:Destroy() end
    ChamApplied[plr] = nil
end

local function ApplyChams(plr)
    if plr == LocalPlayer or not IsAlive(plr) then return end
    if State.ChamsTeamCheck and plr.Team == LocalPlayer.Team then
        RestoreChams(plr)
        return
    end

    local char   = plr.Character
    local preset = ChamsMaterials[State.ChamsMaterial] or ChamsMaterials["ForceField"]
    local rec    = ChamApplied[plr]
    if not rec then
        rec = { originals = {}, hidden = {}, highlight = nil }
        ChamApplied[plr] = rec
    end

    local descendants = char:GetDescendants()
    local totalParts  = #descendants

    for idx, inst in ipairs(descendants) do
        if inst:IsA("BasePart") and inst.Name ~= "HumanoidRootPart" then
            if not rec.originals[inst] then
                rec.originals[inst] = {
                    Material     = inst.Material,
                    Reflectance  = inst.Reflectance,
                    Color        = inst.Color,
                    Transparency = inst.Transparency,
                    TextureID    = inst:IsA("MeshPart") and inst.TextureID or nil,
                }
            end
            inst.Material     = preset.material
            inst.Reflectance  = preset.reflectance
            inst.Transparency = State.ChamsTransparency
            if inst:IsA("MeshPart") then inst.TextureID = "" end
            if preset.tint then
                if State.ChamsUseGradient then
                    local alpha = idx / math.max(totalParts, 1)
                    inst.Color = State.ChamsColor1:Lerp(State.ChamsColor2, alpha)
                else
                    inst.Color = State.ChamsColor1
                end
            end
        elseif inst:IsA("Shirt") or inst:IsA("Pants") or inst:IsA("ShirtGraphic")
            or inst:IsA("Decal") or inst:IsA("Texture") or inst:IsA("SurfaceAppearance") then
            if rec.hidden[inst] == nil and inst.Parent then
                rec.hidden[inst] = inst.Parent
                pcall(function() inst.Parent = nil end)
            end
        end
    end

    if State.ChamsSeeThrough then
        if not rec.highlight or not rec.highlight.Parent then
            local hl = Instance.new("Highlight")
            hl.Name               = "MatChamsOverlay"
            hl.FillTransparency   = 1
            hl.OutlineTransparency = 0
            hl.DepthMode          = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Adornee            = char
            hl.Parent             = SuiteGui
            rec.highlight         = hl
        end
        rec.highlight.OutlineColor = State.ChamsColor1
    elseif rec.highlight then
        rec.highlight:Destroy()
        rec.highlight = nil
    end
end

-- ============================================================================
-- NATIVE ROBLOX MENU WINDOW & CONTROLS
-- ============================================================================

-- Mobile Floating Pill Button
local FloatingPill = Instance.new("TextButton")
FloatingPill.Name = "FloatingPill"
FloatingPill.Size = UDim2.new(0, 48, 0, 48)
FloatingPill.Position = UDim2.new(0, 16, 0.4, 0)
FloatingPill.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
FloatingPill.Text = "⚡"
FloatingPill.TextSize = 22
FloatingPill.TextColor3 = Color3.fromRGB(255, 43, 43)
FloatingPill.Font = Enum.Font.GothamBold
FloatingPill.Active = true
FloatingPill.Draggable = true
FloatingPill.ZIndex = 100
FloatingPill.Parent = SuiteGui

local PillCorner = Instance.new("UICorner")
PillCorner.CornerRadius = UDim.new(0, 12)
PillCorner.Parent = FloatingPill

local PillStroke = Instance.new("UIStroke")
PillStroke.Color = Color3.fromRGB(255, 43, 43)
PillStroke.Thickness = 1.5
PillStroke.Parent = FloatingPill

-- Main Window Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 470, 0, 360)
MainFrame.Position = UDim2.new(0.5, -235, 0.5, -180)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ZIndex = 50
MainFrame.Parent = SuiteGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(45, 45, 52)
MainStroke.Thickness = 1
MainStroke.Parent = MainFrame

-- Header Bar
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 38)
Header.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
Header.BorderSizePixel = 0
Header.ZIndex = 51
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 8)
HeaderCorner.Parent = Header

local HeaderTitle = Instance.new("TextLabel")
HeaderTitle.Size = UDim2.new(1, -70, 1, 0)
HeaderTitle.Position = UDim2.new(0, 14, 0, 0)
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.Text = "matthews a hoe ass boy"
HeaderTitle.Font = Enum.Font.GothamBold
HeaderTitle.TextSize = 14
HeaderTitle.TextColor3 = Color3.fromRGB(240, 240, 245)
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
HeaderTitle.ZIndex = 52
HeaderTitle.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -34, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
CloseBtn.Text = "✕"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
CloseBtn.TextColor3 = Color3.fromRGB(255, 60, 60)
CloseBtn.ZIndex = 52
CloseBtn.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

local AccentLine = Instance.new("Frame")
AccentLine.Size = UDim2.new(1, 0, 0, 2)
AccentLine.Position = UDim2.new(0, 0, 0, 38)
AccentLine.BackgroundColor3 = Color3.fromRGB(255, 43, 43)
AccentLine.BorderSizePixel = 0
AccentLine.ZIndex = 53
AccentLine.Parent = MainFrame

-- Tab Navigation
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, 0, 0, 32)
TabBar.Position = UDim2.new(0, 0, 0, 40)
TabBar.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
TabBar.BorderSizePixel = 0
TabBar.ZIndex = 51
TabBar.Parent = MainFrame

local TabNames = { "Aim", "Visuals", "World", "Settings" }
local TabButtons = {}
local TabPages = {}

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -20, 1, -84)
ContentArea.Position = UDim2.new(0, 10, 0, 78)
ContentArea.BackgroundTransparency = 1
ContentArea.ZIndex = 51
ContentArea.Parent = MainFrame

for _, name in ipairs(TabNames) do
    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = Color3.fromRGB(255, 43, 43)
    page.Visible = (name == State.ActiveTab)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.ZIndex = 52
    page.Parent = ContentArea

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 4)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.PaddingLeft = UDim.new(0, 4)
    pad.PaddingRight = UDim.new(0, 6)
    pad.Parent = page

    TabPages[name] = page
end

local function SwitchTab(targetTab)
    State.ActiveTab = targetTab
    for name, page in pairs(TabPages) do
        page.Visible = (name == targetTab)
    end
    for name, btn in pairs(TabButtons) do
        local active = (name == targetTab)
        btn.TextColor3 = active and Color3.fromRGB(255, 43, 43) or Color3.fromRGB(160, 160, 170)
        btn.BackgroundColor3 = active and Color3.fromRGB(28, 28, 34) or Color3.fromRGB(18, 18, 22)
        local ind = btn:FindFirstChild("Indicator")
        if ind then ind.Visible = active end
    end
end

local tabCount = #TabNames
for i, name in ipairs(TabNames) do
    local btn = Instance.new("TextButton")
    btn.Name = name .. "Tab"
    btn.Size = UDim2.new(1 / tabCount, 0, 1, 0)
    btn.Position = UDim2.new((i - 1) / tabCount, 0, 0, 0)
    btn.BackgroundColor3 = (name == State.ActiveTab) and Color3.fromRGB(28, 28, 34) or Color3.fromRGB(18, 18, 22)
    btn.Text = name
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.TextColor3 = (name == State.ActiveTab) and Color3.fromRGB(255, 43, 43) or Color3.fromRGB(160, 160, 170)
    btn.BorderSizePixel = 0
    btn.ZIndex = 52
    btn.Parent = TabBar

    local ind = Instance.new("Frame")
    ind.Name = "Indicator"
    ind.Size = UDim2.new(1, 0, 0, 2)
    ind.Position = UDim2.new(0, 0, 1, -2)
    ind.BackgroundColor3 = Color3.fromRGB(255, 43, 43)
    ind.BorderSizePixel = 0
    ind.Visible = (name == State.ActiveTab)
    ind.ZIndex = 53
    ind.Parent = btn

    btn.MouseButton1Click:Connect(function()
        SwitchTab(name)
    end)
    TabButtons[name] = btn
end

-- Controls
local function AddToggle(tab, title, refKey)
    local page = TabPages[tab]
    if not page then return end

    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    row.BorderSizePixel = 0
    row.AutoButtonColor = false
    row.Text = ""
    row.ZIndex = 53
    row.Parent = page

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = row

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = title
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextColor3 = Color3.fromRGB(220, 220, 225)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 54
    label.Parent = row

    local box = Instance.new("Frame")
    box.Size = UDim2.new(0, 20, 0, 20)
    box.Position = UDim2.new(1, -32, 0.5, -10)
    box.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
    box.BorderSizePixel = 0
    box.ZIndex = 54
    box.Parent = row

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 4)
    boxCorner.Parent = box

    local check = Instance.new("Frame")
    check.Size = UDim2.new(0, 12, 0, 12)
    check.Position = UDim2.new(0.5, -6, 0.5, -6)
    check.BackgroundColor3 = Color3.fromRGB(255, 43, 43)
    check.BorderSizePixel = 0
    check.Visible = State[refKey]
    check.ZIndex = 55
    check.Parent = box

    local checkCorner = Instance.new("UICorner")
    checkCorner.CornerRadius = UDim.new(0, 2)
    checkCorner.Parent = check

    row.MouseButton1Click:Connect(function()
        State[refKey] = not State[refKey]
        check.Visible = State[refKey]
    end)
end

local function AddSlider(tab, title, refKey, min, max, isFloat)
    local page = TabPages[tab]
    if not page then return end

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 46)
    card.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    card.BorderSizePixel = 0
    card.ZIndex = 53
    card.Parent = page

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = card

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -90, 0, 20)
    label.Position = UDim2.new(0, 12, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = title
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextColor3 = Color3.fromRGB(220, 220, 225)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 54
    label.Parent = card

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0, 70, 0, 20)
    valLabel.Position = UDim2.new(1, -82, 0, 4)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = isFloat and string.format("%.2f", State[refKey]) or tostring(math.floor(State[refKey]))
    valLabel.Font = Enum.Font.GothamMedium
    valLabel.TextSize = 12
    valLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.ZIndex = 54
    valLabel.Parent = card

    local bar = Instance.new("TextButton")
    bar.Size = UDim2.new(1, -24, 0, 8)
    bar.Position = UDim2.new(0, 12, 0, 28)
    bar.BackgroundColor3 = Color3.fromRGB(36, 36, 44)
    bar.BorderSizePixel = 0
    bar.Text = ""
    bar.AutoButtonColor = false
    bar.ZIndex = 54
    bar.Parent = card

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 4)
    barCorner.Parent = bar

    local fill = Instance.new("Frame")
    local initRatio = math.clamp((State[refKey] - min) / (max - min), 0, 1)
    fill.Size = UDim2.new(initRatio, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 43, 43)
    fill.BorderSizePixel = 0
    fill.ZIndex = 55
    fill.Parent = bar

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = fill

    local sliding = false
    local function UpdateVal(inputX)
        local ratio = math.clamp((inputX - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local newVal = min + ((max - min) * ratio)
        newVal = isFloat and newVal or math.floor(newVal + 0.5)
        State[refKey] = newVal
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        valLabel.Text = isFloat and string.format("%.2f", newVal) or tostring(math.floor(newVal))
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            UpdateVal(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateVal(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)
end

local function AddDropdown(tab, title, refKey, options)
    local page = TabPages[tab]
    if not page then return end

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 38)
    card.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    card.BorderSizePixel = 0
    card.ClipsDescendants = true
    card.ZIndex = 53
    card.Parent = page

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = card

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -160, 0, 38)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = title
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextColor3 = Color3.fromRGB(220, 220, 225)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 54
    label.Parent = card

    local trigger = Instance.new("TextButton")
    trigger.Size = UDim2.new(0, 140, 0, 26)
    trigger.Position = UDim2.new(1, -150, 0, 6)
    trigger.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
    trigger.Text = tostring(State[refKey]) .. " ▼"
    trigger.Font = Enum.Font.GothamMedium
    trigger.TextSize = 12
    trigger.TextColor3 = Color3.fromRGB(240, 240, 245)
    trigger.ZIndex = 54
    trigger.Parent = card

    local trigCorner = Instance.new("UICorner")
    trigCorner.CornerRadius = UDim.new(0, 4)
    trigCorner.Parent = trigger

    local open = false
    local rowH = 26
    local optContainer = Instance.new("Frame")
    optContainer.Size = UDim2.new(0, 140, 0, #options * rowH)
    optContainer.Position = UDim2.new(1, -150, 0, 36)
    optContainer.BackgroundTransparency = 1
    optContainer.ZIndex = 55
    optContainer.Parent = card

    for idx, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, rowH)
        optBtn.Position = UDim2.new(0, 0, 0, (idx - 1) * rowH)
        optBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
        optBtn.Text = opt
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextSize = 12
        optBtn.TextColor3 = (State[refKey] == opt) and Color3.fromRGB(255, 43, 43) or Color3.fromRGB(180, 180, 190)
        optBtn.BorderSizePixel = 0
        optBtn.ZIndex = 56
        optBtn.Parent = optContainer

        optBtn.MouseButton1Click:Connect(function()
            State[refKey] = opt
            trigger.Text = opt .. " ▼"
            open = false
            card.Size = UDim2.new(1, 0, 0, 38)
            for _, b in ipairs(optContainer:GetChildren()) do
                if b:IsA("TextButton") then
                    b.TextColor3 = (b.Text == opt) and Color3.fromRGB(255, 43, 43) or Color3.fromRGB(180, 180, 190)
                end
            end
        end)
    end

    trigger.MouseButton1Click:Connect(function()
        open = not open
        if open then
            card.Size = UDim2.new(1, 0, 0, 38 + (#options * rowH))
        else
            card.Size = UDim2.new(1, 0, 0, 38)
        end
    end)
end

local function AddButton(tab, title, callback)
    local page = TabPages[tab]
    if not page then return end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
    btn.Text = title
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(255, 60, 60)
    btn.BorderSizePixel = 0
    btn.ZIndex = 53
    btn.Parent = page

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        callback()
    end)
end

-- ============================================================================
-- BUILD CONTROLS IN TABS
-- ============================================================================

-- Aim
AddToggle("Aim", "Aim Assist (Smooth Cam)", "AimAssist")
AddToggle("Aim", "Silent Aim (Bullet Redir)", "SilentAim")
AddDropdown("Aim", "Target Part", "AimPart", { "Head", "HumanoidRootPart" })
AddSlider("Aim", "Aim Smoothness", "AimSmoothness", 0.05, 1.0, true)
AddSlider("Aim", "Aim FOV Radius", "FOV", 30, 400, false)
AddToggle("Aim", "Show FOV Circle", "ShowFOV")

-- Visuals
AddToggle("Visuals", "Box ESP Enabled", "ESPEnabled")
AddToggle("Visuals", "Box Interior Fill", "BoxFill")
AddSlider("Visuals", "Fill Transparency", "BoxFillTransparency", 0.1, 0.9, true)
AddToggle("Visuals", "Player Tracers", "Tracers")
AddDropdown("Visuals", "Tracer Origin", "TracerOrigin", { "Bottom", "Mouse", "Center" })
AddToggle("Visuals", "Material Chams", "ChamsEnabled")
AddDropdown("Visuals", "Chams Material", "ChamsMaterial",
    { "ForceField", "Neon", "Glass", "Ice", "Marble", "Foil", "Metal", "Wood" })
AddToggle("Visuals", "Chams Gradient Blend", "ChamsUseGradient")
AddToggle("Visuals", "Chams Wall Penetration", "ChamsSeeThrough")
AddSlider("Visuals", "Chams Transparency", "ChamsTransparency", 0.0, 0.9, true)

-- World
AddToggle("World", "Fullbright Mode", "Fullbright")
AddToggle("World", "Noclip Walls", "NoClip")
AddToggle("World", "Remove Atmospheric Fog", "NoFog")
AddToggle("World", "Override WalkSpeed", "WalkSpeedMod")
AddSlider("World", "WalkSpeed Multiplier", "WalkSpeedValue", 16, 150, false)
AddToggle("World", "Override JumpPower", "JumpPowerMod")
AddSlider("World", "JumpPower Multiplier", "JumpPowerValue", 50, 300, false)

-- Settings
AddButton("Settings", "Unload Universal Suite", function()
    if env.UNIVERSAL_SUITE_UNLOAD then
        env.UNIVERSAL_SUITE_UNLOAD()
    end
end)

-- UI Visibility Controls
local function SetUIVisible(val)
    State.UIVisible = val
    MainFrame.Visible = val
end

FloatingPill.MouseButton1Click:Connect(function()
    SetUIVisible(not State.UIVisible)
end)

CloseBtn.MouseButton1Click:Connect(function()
    SetUIVisible(false)
end)

-- User Pointer & Input
local inputKeyConn = UserInputService.InputBegan:Connect(function(input, processed)
    if input.KeyCode == Enum.KeyCode.Insert then
        SetUIVisible(not State.UIVisible)
    end
    if not processed and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
        PointerPos = Vector2.new(input.Position.X, input.Position.Y)
    end
end)
table.insert(Connections, inputKeyConn)

local inputMoveConn = UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        PointerPos = Vector2.new(input.Position.X, input.Position.Y)
    end
end)
table.insert(Connections, inputMoveConn)

-- ============================================================================
-- WORLD MODIFIER APPLICATION
-- ============================================================================

local function ApplyWorldMods()
    if State.Fullbright then
        Lighting.Ambient        = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.Brightness     = 2
    else
        Lighting.Ambient        = OriginalLighting.Ambient
        Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
        Lighting.Brightness     = OriginalLighting.Brightness
    end

    Lighting.FogEnd = State.NoFog and 9e9 or OriginalLighting.FogEnd

    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            if State.WalkSpeedMod then hum.WalkSpeed = State.WalkSpeedValue end
            if State.JumpPowerMod then hum.JumpPower  = State.JumpPowerValue  end
        end
        if State.NoClip then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end

-- ============================================================================
-- MAIN RENDER PIPELINE
-- ============================================================================

local renderConn = RunService.RenderStepped:Connect(function()
    if not State.Running then return end

    UpdateFOV()
    UpdateESP()
    ApplyWorldMods()

    -- Camera smoothing aim assist (PC)
    if State.AimAssist and mousemove then
        local target = GetClosestTarget()
        if target then
            local deltaX = (target.Screen.X - PointerPos.X) * State.AimSmoothness
            local deltaY = (target.Screen.Y - PointerPos.Y) * State.AimSmoothness
            mousemove(deltaX, deltaY)
        end
    end

    if State.ChamsEnabled then
        for _, plr in ipairs(Players:GetPlayers()) do
            ApplyChams(plr)
        end
    else
        for plr in pairs(ChamApplied) do
            RestoreChams(plr)
        end
    end
end)
table.insert(Connections, renderConn)

-- Player Events
local pAdded = Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.3)
        if State.ChamsEnabled then ApplyChams(plr) end
    end)
end)
local pRemoved = Players.PlayerRemoving:Connect(function(plr)
    CleanupPlayerESP(plr)
    RestoreChams(plr)
end)
table.insert(Connections, pAdded)
table.insert(Connections, pRemoved)

-- ============================================================================
-- UNLOAD LIFECYCLE
-- ============================================================================

local function UnloadSuite()
    State.Running = false

    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(Connections)

    for plr in pairs(ChamApplied) do RestoreChams(plr) end
    for plr in pairs(PlayerESP)   do CleanupPlayerESP(plr) end

    if SuiteGui then
        pcall(function() SuiteGui:Destroy() end)
    end

    Lighting.Ambient        = OriginalLighting.Ambient
    Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
    Lighting.Brightness     = OriginalLighting.Brightness
    Lighting.FogEnd         = OriginalLighting.FogEnd

    env.UNIVERSAL_SUITE_UNLOAD = nil
end

env.UNIVERSAL_SUITE_UNLOAD = UnloadSuite
