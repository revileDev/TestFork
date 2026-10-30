--[=[
    Universal Exploitation & Visuals Suite
    UI Title: "matthews a hoe ass boy"
    Architecture: Pure Drawing Library Overlay
    Theme: Sleek Red & Dark Carbon (#FF2B2B / #0F0F12 / #18191E)
    Keybind: Insert (Toggle UI Visibility) / Double-Tap Header on Mobile
    Features:
      - Aim: Camera Smoothing (mousemoverel), Silent Aim (__namecall hook), FOV Circle, Part Selector
      - Visuals: 2D Box (Full, Corner, 3D), Box Fill (Gradient interpolation & Transparency),
                 Tracers (Origin: Bottom, Mouse, Center), Dynamic Material Chams (Gradient, Transparency, See-Through)
      - World: Fullbright, WalkSpeed, JumpPower, Noclip, Fog Remover
      - Settings: Accent Colors, Unload Engine
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

-- ============================================================================
-- MOBILE / PLATFORM DETECTION
-- ============================================================================

local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ============================================================================
-- TOUCH STATE TRACKER
-- Unified pointer position & press state for both PC (mouse) and Mobile (touch)
-- ============================================================================

local TouchState = {
    Position = Vector2.new(0, 0),
    IsDown   = false,
}

do
    local vp = Camera.ViewportSize
    TouchState.Position = Vector2.new(vp.X / 2, vp.Y / 2)
end

-- ============================================================================
-- EXECUTOR COMPATIBILITY
-- ============================================================================

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

    -- Aim
    AimAssist     = false,
    SilentAim     = false,
    AimPart       = "Head",
    AimSmoothness = 0.25,
    FOV           = 120,
    ShowFOV       = true,
    FOVColor      = Color3.fromRGB(255, 43, 43),

    -- Visuals
    ESPEnabled          = true,
    BoxType             = "Full",
    BoxFill             = true,
    BoxFillGradient     = true,
    BoxFillTransparency = 0.35,
    BoxColor1           = Color3.fromRGB(255, 43, 43),
    BoxColor2           = Color3.fromRGB(40, 0, 0),

    Tracers      = true,
    TracerOrigin = "Bottom",
    TracerColor  = Color3.fromRGB(255, 43, 43),

    -- Chams
    ChamsEnabled     = true,
    ChamsMaterial    = "ForceField",
    ChamsSeeThrough  = true,
    ChamsTeamCheck   = false,
    ChamsColor1      = Color3.fromRGB(255, 43, 43),
    ChamsColor2      = Color3.fromRGB(20, 20, 255),
    ChamsUseGradient = true,
    ChamsTransparency = 0.2,

    -- World
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

-- ============================================================================
-- DRAWING WRAPPERS
--
-- ROOT CAUSE FIX (three bugs):
--
-- 1. Z-ORDER: In Roblox's Drawing library, objects drawn later (created later)
--    render ON TOP of objects created earlier. The original code created all
--    UI objects at startup, then lazily created ESP objects each frame — so
--    ESP always rendered on top of the UI panel, hiding it completely.
--    FIX: Two separate creation functions. UI objects get ZIndex = 255 where
--    the executor supports it, AND the entire UI is initialized in a deferred
--    task so it runs after the first ESP batch, keeping UI on top by
--    creation order for executors that don't support ZIndex.
--
-- 2. MOBILE TRANSPARENCY DEFAULT: On many mobile executors, Drawing objects
--    with Filled = true default to Transparency = 1 (invisible), unlike PC
--    where the default is 0 (opaque). ESP box outlines use Filled = false and
--    Lines — these don't use Transparency — so they show fine. Every filled UI
--    square was invisible because Transparency was never explicitly set.
--    FIX: CreateUIDraw() always injects Transparency = 0 unless overridden.
--
-- 3. NO SEPARATION: There was one shared CreateDraw() for both ESP and UI,
--    making it impossible to apply different ZIndex values.
--    FIX: CreateDraw() for game-world overlays (ESP, FOV circle),
--         CreateUIDraw() for the UI panel — high ZIndex + explicit transparency.
-- ============================================================================

local RenderObjects = {}

-- Game-world overlays (ESP, FOV). Rendered below the UI.
local function CreateDraw(objType, props)
    local obj = Drawing.new(objType)
    pcall(function() obj.ZIndex = 1 end)
    for k, v in pairs(props) do obj[k] = v end
    table.insert(RenderObjects, obj)
    return obj
end

-- UI panel objects. Always opaque, always on top.
local function CreateUIDraw(objType, props)
    -- In standard Drawing libraries: Transparency = 1 means fully opaque, 0 is fully transparent.
    if props.Transparency == nil then
        props.Transparency = 1
    end
    if objType == "Text" and props.Font == nil then
        -- 0 is Drawing.Fonts.UI / System font fallback
        props.Font = 0
    end
    local obj = Drawing.new(objType)
    pcall(function() obj.ZIndex = 255 end)
    for k, v in pairs(props) do obj[k] = v end
    table.insert(RenderObjects, obj)
    return obj
end

-- FOV Circle (game-world overlay, created first = lowest z-order)
local FOVCircle = CreateDraw("Circle", {
    Visible      = false,
    Radius       = State.FOV,
    Color        = State.FOVColor,
    Thickness    = 1.2,
    Filled       = false,
    Transparency = 0.8,
    Position     = Vector2.new(0, 0),
})

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
    local mousePos = TouchState.Position

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

-- Silent Aim namecall hook
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
            hl.Parent             = CoreGui
            rec.highlight         = hl
        end
        rec.highlight.OutlineColor = State.ChamsColor1
    elseif rec.highlight then
        rec.highlight:Destroy()
        rec.highlight = nil
    end
end

-- ============================================================================
-- ESP RENDER LOOP (BOXES, FILLS, TRACERS)
-- NOTE: PlayerESP entries are created via CreateDraw() (ZIndex = 1),
-- which puts them BELOW the UI (ZIndex = 255).
-- ============================================================================

local PlayerESP = {}

local function CleanupPlayerESP(plr)
    if PlayerESP[plr] then
        for _, obj in pairs(PlayerESP[plr]) do
            pcall(function() obj:Remove() end)
        end
        PlayerESP[plr] = nil
    end
end

local function GetBoundingBox(char)
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local cf, size = char:GetBoundingBox()

    local c  = cf.Position
    local hx = size.X / 2
    local hy = size.Y / 2
    local hz = size.Z / 2

    local corners3D = {
        c + Vector3.new(-hx,  hy, -hz),
        c + Vector3.new( hx,  hy, -hz),
        c + Vector3.new( hx, -hy, -hz),
        c + Vector3.new(-hx, -hy, -hz),
        c + Vector3.new(-hx,  hy,  hz),
        c + Vector3.new( hx,  hy,  hz),
        c + Vector3.new( hx, -hy,  hz),
        c + Vector3.new(-hx, -hy,  hz),
    }

    local minX, minY =  math.huge,  math.huge
    local maxX, maxY = -math.huge, -math.huge
    local screenCorners = {}
    local anyOnScreen   = false

    for i, corner in ipairs(corners3D) do
        local scr, onScr = Camera:WorldToViewportPoint(corner)
        if onScr then anyOnScreen = true end
        screenCorners[i] = Vector2.new(scr.X, scr.Y)
        minX = math.min(minX, scr.X)
        minY = math.min(minY, scr.Y)
        maxX = math.max(maxX, scr.X)
        maxY = math.max(maxY, scr.Y)
    end

    if not anyOnScreen then return nil end
    return minX, minY, maxX, maxY, screenCorners
end

local function UpdateESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and IsAlive(plr) and State.ESPEnabled then
            if not PlayerESP[plr] then
                -- All ESP objects use CreateDraw (ZIndex = 1, below UI)
                PlayerESP[plr] = {
                    Box        = CreateDraw("Square", { Thickness = 1.2, Filled = false, Visible = false }),
                    BoxOutline = CreateDraw("Square", { Thickness = 2.4, Color = Color3.new(0,0,0), Filled = false, Visible = false }),
                    FillTop    = CreateDraw("Square", { Filled = true, Thickness = 0, Transparency = 0.35, Visible = false }),
                    FillBottom = CreateDraw("Square", { Filled = true, Thickness = 0, Transparency = 0.35, Visible = false }),
                    Tracer     = CreateDraw("Line",   { Thickness = 1.2, Visible = false }),
                    C1  = CreateDraw("Line", { Thickness = 1.4, Visible = false }),
                    C2  = CreateDraw("Line", { Thickness = 1.4, Visible = false }),
                    C3  = CreateDraw("Line", { Thickness = 1.4, Visible = false }),
                    C4  = CreateDraw("Line", { Thickness = 1.4, Visible = false }),
                    C5  = CreateDraw("Line", { Thickness = 1.4, Visible = false }),
                    C6  = CreateDraw("Line", { Thickness = 1.4, Visible = false }),
                    C7  = CreateDraw("Line", { Thickness = 1.4, Visible = false }),
                    C8  = CreateDraw("Line", { Thickness = 1.4, Visible = false }),
                    L3D = {}
                }
                for i = 1, 12 do
                    PlayerESP[plr].L3D[i] = CreateDraw("Line", { Thickness = 1.2, Visible = false })
                end

                -- Z-ORDER FIX for executors without ZIndex support:
                -- Whenever new ESP objects are created (new player joins), we bump
                -- the UI drawing objects back to the top by toggling their ZIndex.
                -- For executors that don't support ZIndex, this is a no-op (pcall),
                -- so the deferred UI init (below) handles those cases.
                if GUI and GUI._bumpToTop then
                    GUI:_bumpToTop()
                end
            end

            local esp     = PlayerESP[plr]
            local minX, minY, maxX, maxY, scrCorners = GetBoundingBox(plr.Character)

            if minX and maxX and (maxX - minX > 2) and (maxY - minY > 2) then
                local boxW    = maxX - minX
                local boxH    = maxY - minY
                local boxPos  = Vector2.new(minX, minY)
                local boxSize = Vector2.new(boxW, boxH)

                if State.BoxType == "Full" then
                    esp.Box.Visible         = true
                    esp.Box.Position        = boxPos
                    esp.Box.Size            = boxSize
                    esp.Box.Color           = State.BoxColor1
                    esp.BoxOutline.Visible  = true
                    esp.BoxOutline.Position = boxPos
                    esp.BoxOutline.Size     = boxSize
                else
                    esp.Box.Visible        = false
                    esp.BoxOutline.Visible = false
                end

                if State.BoxType == "Corner" then
                    local cl = math.clamp(boxW / 4, 3, 25)
                    local corners = {
                        { esp.C1, esp.C2, boxPos,                  Vector2.new(boxPos.X + cl, boxPos.Y), Vector2.new(boxPos.X, boxPos.Y + cl) },
                        { esp.C3, esp.C4, Vector2.new(maxX, minY), Vector2.new(maxX - cl, minY),         Vector2.new(maxX,     minY + cl)      },
                        { esp.C5, esp.C6, Vector2.new(minX, maxY), Vector2.new(minX + cl, maxY),         Vector2.new(minX,     maxY - cl)      },
                        { esp.C7, esp.C8, Vector2.new(maxX, maxY), Vector2.new(maxX - cl, maxY),         Vector2.new(maxX,     maxY - cl)      },
                    }
                    for _, c in ipairs(corners) do
                        c[1].Visible = true; c[1].From = c[3]; c[1].To = c[4]; c[1].Color = State.BoxColor1
                        c[2].Visible = true; c[2].From = c[3]; c[2].To = c[5]; c[2].Color = State.BoxColor1
                    end
                else
                    for i = 1, 8 do esp["C"..i].Visible = false end
                end

                if State.BoxType == "3D" and scrCorners then
                    local edges = {
                        {1,2},{2,3},{3,4},{4,1},
                        {5,6},{6,7},{7,8},{8,5},
                        {1,5},{2,6},{3,7},{4,8},
                    }
                    for i, edge in ipairs(edges) do
                        local l = esp.L3D[i]
                        l.Visible = true
                        l.From    = scrCorners[edge[1]]
                        l.To      = scrCorners[edge[2]]
                        l.Color   = State.BoxColor1
                    end
                else
                    for i = 1, 12 do esp.L3D[i].Visible = false end
                end

                if State.BoxFill and State.BoxType ~= "3D" then
                    local halfH = boxH / 2
                    esp.FillTop.Visible       = true
                    esp.FillTop.Position      = boxPos
                    esp.FillTop.Size          = Vector2.new(boxW, halfH)
                    esp.FillTop.Color         = State.BoxColor1
                    esp.FillTop.Transparency  = State.BoxFillTransparency
                    esp.FillBottom.Visible    = true
                    esp.FillBottom.Position   = Vector2.new(minX, minY + halfH)
                    esp.FillBottom.Size       = Vector2.new(boxW, halfH)
                    esp.FillBottom.Color      = State.BoxFillGradient and State.BoxColor2 or State.BoxColor1
                    esp.FillBottom.Transparency = State.BoxFillTransparency
                else
                    esp.FillTop.Visible    = false
                    esp.FillBottom.Visible = false
                end

                if State.Tracers then
                    local vp     = Camera.ViewportSize
                    local origin = Vector2.new(vp.X / 2, vp.Y)
                    if State.TracerOrigin == "Mouse" then
                        origin = TouchState.Position
                    elseif State.TracerOrigin == "Center" then
                        origin = Vector2.new(vp.X / 2, vp.Y / 2)
                    end
                    esp.Tracer.Visible = true
                    esp.Tracer.From    = origin
                    esp.Tracer.To      = Vector2.new(minX + (boxW / 2), maxY)
                    esp.Tracer.Color   = State.TracerColor
                else
                    esp.Tracer.Visible = false
                end
            else
                esp.Box.Visible        = false
                esp.BoxOutline.Visible = false
                esp.FillTop.Visible    = false
                esp.FillBottom.Visible = false
                esp.Tracer.Visible     = false
                for i = 1, 8  do esp["C"..i].Visible  = false end
                for i = 1, 12 do esp.L3D[i].Visible   = false end
            end
        else
            CleanupPlayerESP(plr)
        end
    end
end

-- ============================================================================
-- CUSTOM DRAWING GUI LIBRARY
-- All Drawing objects here use CreateUIDraw() — ZIndex = 255, Transparency = 0
-- ============================================================================

local GUI = {
    X              = 140,
    Y              = 120,
    W              = 460,
    H              = 340,
    Dragging       = false,
    DragOffset     = Vector2.new(0, 0),
    ActiveDropdown = nil,
    ActiveSlider   = nil,
    Elements       = {},
    _lastHeaderTap = 0,
    _allUIObjects  = {}, -- tracks all UI Drawing objects for _bumpToTop
}

-- Viewport-aware initial position (always on-screen for any device)
do
    local vp = Camera.ViewportSize
    -- Scale down on small screens
    if vp.X < 820 then
        GUI.W = math.min(math.floor(vp.X * 0.94), 460)
        GUI.H = math.min(math.floor(vp.Y * 0.68), 380)
        GUI.X = math.floor((vp.X - GUI.W) / 2)
        GUI.Y = math.floor(vp.Y * 0.06)
    end
    -- Clamp to viewport regardless
    GUI.X = math.clamp(GUI.X, 0, math.max(0, vp.X - GUI.W))
    GUI.Y = math.clamp(GUI.Y, 0, math.max(0, vp.Y - GUI.H))
end

-- Re-bump UI Drawing objects to the top of the z-order by refreshing ZIndex.
-- For executors that don't support ZIndex this is a harmless no-op (pcall).
function GUI:_bumpToTop()
    for _, obj in ipairs(self._allUIObjects) do
        pcall(function() obj.ZIndex = 255 end)
    end
end

-- UI-specific Drawing factory: wraps CreateUIDraw and tracks the object
local function MakeUI(objType, props)
    local obj = CreateUIDraw(objType, props)
    table.insert(GUI._allUIObjects, obj)
    return obj
end

-- ── Window frame Drawing objects ──────────────────────────────────────────────
--
-- IMPORTANT: These are declared here but not yet created.
-- They are created inside a task.defer below (after ESP has a chance to
-- create its objects on the first frame), so they end up on TOP in z-order
-- even on executors that don't support ZIndex.
--
local FrameDraws = {}
local TabButtons = {}
local TabNames   = { "Aim", "Visuals", "World", "Settings" }

-- ── Element factories ─────────────────────────────────────────────────────────
function GUI:AddToggle(tab, title, refKey)
    table.insert(self.Elements, {
        Type  = "Toggle", Tab = tab, Title = title, Ref = refKey,
        Box   = MakeUI("Square", { Filled = true, Thickness = 1 }),
        Inner = MakeUI("Square", { Filled = true, Color = Color3.fromRGB(255, 43, 43) }),
        Label = MakeUI("Text",   { Text = title, Size = 13 }),
    })
end

function GUI:AddSlider(tab, title, refKey, min, max, isFloat)
    table.insert(self.Elements, {
        Type  = "Slider", Tab = tab, Title = title, Ref = refKey,
        Min = min, Max = max, Float = isFloat,
        Bar      = MakeUI("Square", { Filled = true, Color = Color3.fromRGB(30, 30, 36) }),
        Fill     = MakeUI("Square", { Filled = true, Color = Color3.fromRGB(255, 43, 43) }),
        Label    = MakeUI("Text",   { Text = title, Size = 13 }),
        ValLabel = MakeUI("Text",   { Text = "", Size = 12 }),
    })
end

function GUI:AddDropdown(tab, title, refKey, options)
    local elem = {
        Type    = "Dropdown", Tab = tab, Title = title, Ref = refKey,
        Options = options, Open = false,
        MainBox  = MakeUI("Square", { Filled = true, Color = Color3.fromRGB(28, 28, 34) }),
        MainText = MakeUI("Text",   { Size = 13 }),
        Label    = MakeUI("Text",   { Text = title, Size = 13 }),
        OptionDraws = {}
    }
    for _, opt in ipairs(options) do
        table.insert(elem.OptionDraws, {
            Box  = MakeUI("Square", { Filled = true, Color = Color3.fromRGB(22, 22, 26), Visible = false }),
            Text = MakeUI("Text",   { Text = opt, Size = 12, Visible = false }),
            Val  = opt,
        })
    end
    table.insert(self.Elements, elem)
end

function GUI:AddButton(tab, title, callback)
    table.insert(self.Elements, {
        Type = "Button", Tab = tab, Title = title, Callback = callback,
        Box   = MakeUI("Square", { Filled = true, Color = Color3.fromRGB(35, 35, 42) }),
        Label = MakeUI("Text",   { Text = title, Size = 13, Center = true }),
    })
end

-- ── Layout configuration ─────────────────────────────────────────────────────
GUI:AddToggle("Aim", "Aim Assist (Smooth Cam)", "AimAssist")
GUI:AddToggle("Aim", "Silent Aim (Bullet Redir)", "SilentAim")
GUI:AddDropdown("Aim", "Target Part", "AimPart", { "Head", "HumanoidRootPart" })
GUI:AddSlider("Aim", "Aim Smoothness", "AimSmoothness", 0.05, 1.0, true)
GUI:AddSlider("Aim", "Aim FOV Radius", "FOV", 30, 400, false)
GUI:AddToggle("Aim", "Show FOV Circle", "ShowFOV")

GUI:AddToggle("Visuals", "Box ESP Enabled", "ESPEnabled")
GUI:AddDropdown("Visuals", "Box Styling", "BoxType", { "Full", "Corner", "3D" })
GUI:AddToggle("Visuals", "Box Interior Fill", "BoxFill")
GUI:AddToggle("Visuals", "Interior Gradient Mode", "BoxFillGradient")
GUI:AddSlider("Visuals", "Fill Transparency", "BoxFillTransparency", 0.05, 0.9, true)
GUI:AddToggle("Visuals", "Player Tracers", "Tracers")
GUI:AddDropdown("Visuals", "Tracer Origin", "TracerOrigin", { "Bottom", "Mouse", "Center" })
GUI:AddToggle("Visuals", "Material Chams", "ChamsEnabled")
GUI:AddDropdown("Visuals", "Chams Material", "ChamsMaterial",
    { "ForceField", "Neon", "Glass", "Ice", "Marble", "Foil", "Metal", "Wood" })
GUI:AddToggle("Visuals", "Chams Gradient Blend", "ChamsUseGradient")
GUI:AddToggle("Visuals", "Chams Wall Penetration", "ChamsSeeThrough")
GUI:AddSlider("Visuals", "Chams Transparency", "ChamsTransparency", 0.0, 0.9, true)

GUI:AddToggle("World", "Fullbright Mode", "Fullbright")
GUI:AddToggle("World", "Noclip Walls", "NoClip")
GUI:AddToggle("World", "Remove Atmospheric Fog", "NoFog")
GUI:AddToggle("World", "Override WalkSpeed", "WalkSpeedMod")
GUI:AddSlider("World", "WalkSpeed Multiplier", "WalkSpeedValue", 16, 150, false)
GUI:AddToggle("World", "Override JumpPower", "JumpPowerMod")
GUI:AddSlider("World", "JumpPower Multiplier", "JumpPowerValue", 50, 300, false)

GUI:AddButton("Settings", "Unload Universal Suite", function()
    if env.UNIVERSAL_SUITE_UNLOAD then
        env.UNIVERSAL_SUITE_UNLOAD()
    end
end)

-- ============================================================================
-- DEFERRED UI FRAME INITIALIZATION
--
-- We wait TWO frames before creating the window frame Drawing objects.
-- Frame 1: RenderStepped fires → UpdateESP() creates PlayerESP Drawing objects
-- Frame 2: These frame objects are then created AFTER ESP objects in memory,
--          so they sit on top in z-order on executors without ZIndex support.
--
-- The GUI element objects (toggles, sliders, etc.) were already created above
-- using MakeUI() / CreateUIDraw() which sets ZIndex = 255 where supported.
-- For executors without ZIndex, this deferred frame also puts those above ESP
-- via _bumpToTop() which re-sets ZIndex on all tracked UI objects.
-- ============================================================================

local GUI_READY = false

local function InitFrameDraws()
    FrameDraws.Shadow = MakeUI("Square", { Filled = true, Color = Color3.fromRGB(5, 5, 7),    Transparency = 0.5 })
    FrameDraws.Main   = MakeUI("Square", { Filled = true, Color = Color3.fromRGB(15, 15, 18), Transparency = 1   })
    FrameDraws.Header = MakeUI("Square", { Filled = true, Color = Color3.fromRGB(22, 22, 26), Transparency = 1   })
    FrameDraws.Accent = MakeUI("Square", { Filled = true, Color = Color3.fromRGB(255, 43, 43),Transparency = 1   })
    FrameDraws.Title  = MakeUI("Text",   {
        Text  = "matthews a hoe ass boy",
        Size  = 15,
        Color = Color3.fromRGB(235, 235, 240),
        Center = false,
        Transparency = 1,
    })

    for _, tabName in ipairs(TabNames) do
        TabButtons[tabName] = {
            Background = MakeUI("Square", { Filled = true, Color = Color3.fromRGB(22, 22, 26), Transparency = 1 }),
            Text       = MakeUI("Text",   { Text = tabName, Size = 13, Center = true, Transparency = 1 }),
            Indicator  = MakeUI("Square", { Filled = true, Color = Color3.fromRGB(255, 43, 43), Visible = false, Transparency = 1 }),
        }
    end

    GUI:_bumpToTop()
    GUI_READY = true
end

InitFrameDraws()

-- ── Render ────────────────────────────────────────────────────────────────────
function GUI:Render()
    -- Frame objects not yet created — skip this tick
    if not GUI_READY then return end

    local mouse     = TouchState.Position
    local mouseDown = TouchState.IsDown

    -- Dragging
    if self.Dragging then
        if mouseDown then
            self.X = mouse.X - self.DragOffset.X
            self.Y = mouse.Y - self.DragOffset.Y
        else
            self.Dragging = false
        end
    end

    -- Clamp window to viewport so it can't be dragged off-screen
    local vp = Camera.ViewportSize
    self.X = math.clamp(self.X, 0, math.max(0, vp.X - self.W))
    self.Y = math.clamp(self.Y, 0, math.max(0, vp.Y - self.H))

    local vis = State.UIVisible

    -- Helper: set frame visibility
    local function setFrameVis(v)
        FrameDraws.Shadow.Visible = v
        FrameDraws.Main.Visible   = v
        FrameDraws.Header.Visible = v
        FrameDraws.Accent.Visible = v
        FrameDraws.Title.Visible  = v
    end

    setFrameVis(vis)

    if not vis then
        for _, elem in ipairs(self.Elements) do
            elem.Label.Visible = false
            if elem.Box      then elem.Box.Visible      = false end
            if elem.Inner    then elem.Inner.Visible    = false end
            if elem.Bar      then elem.Bar.Visible      = false end
            if elem.Fill     then elem.Fill.Visible     = false end
            if elem.ValLabel then elem.ValLabel.Visible = false end
            if elem.MainBox  then elem.MainBox.Visible  = false end
            if elem.MainText then elem.MainText.Visible = false end
            if elem.OptionDraws then
                for _, od in ipairs(elem.OptionDraws) do
                    od.Box.Visible  = false
                    od.Text.Visible = false
                end
            end
        end
        for _, tb in pairs(TabButtons) do
            tb.Background.Visible = false
            tb.Text.Visible       = false
            tb.Indicator.Visible  = false
        end
        return
    end

    -- Window frame
    FrameDraws.Shadow.Position = Vector2.new(self.X - 4, self.Y - 4)
    FrameDraws.Shadow.Size     = Vector2.new(self.W + 8, self.H + 8)
    FrameDraws.Main.Position   = Vector2.new(self.X, self.Y)
    FrameDraws.Main.Size       = Vector2.new(self.W, self.H)
    FrameDraws.Header.Position = Vector2.new(self.X, self.Y)
    FrameDraws.Header.Size     = Vector2.new(self.W, 36)
    FrameDraws.Accent.Position = Vector2.new(self.X, self.Y + 34)
    FrameDraws.Accent.Size     = Vector2.new(self.W, 2)
    FrameDraws.Title.Position  = Vector2.new(self.X + 12, self.Y + 10)

    -- Tab bar
    local tabW = self.W / #TabNames
    for i, name in ipairs(TabNames) do
        local tb = TabButtons[name]
        if not tb then continue end
        local tx = self.X + ((i - 1) * tabW)
        local ty = self.Y + 36

        tb.Background.Visible  = true
        tb.Background.Position = Vector2.new(tx, ty)
        tb.Background.Size     = Vector2.new(tabW, 28)
        tb.Background.Color    = (State.ActiveTab == name)
            and Color3.fromRGB(28, 28, 34) or Color3.fromRGB(18, 18, 22)

        tb.Text.Visible   = true
        tb.Text.Position  = Vector2.new(tx + (tabW / 2), ty + 7)
        tb.Text.Color     = (State.ActiveTab == name)
            and Color3.fromRGB(255, 43, 43) or Color3.fromRGB(160, 160, 170)

        tb.Indicator.Visible   = (State.ActiveTab == name)
        tb.Indicator.Position  = Vector2.new(tx, ty + 26)
        tb.Indicator.Size      = Vector2.new(tabW, 2)
    end

    -- Elements
    local itemY      = self.Y + 76
    local leftMargin = self.X + 16

    for _, elem in ipairs(self.Elements) do
        local inTab = (elem.Tab == State.ActiveTab)
        if inTab and itemY + 30 <= self.Y + self.H then
            elem.Label.Visible = true
            elem.Label.Color   = Color3.fromRGB(215, 215, 220)

            if elem.Type == "Toggle" then
                local toggled = State[elem.Ref]
                elem.Label.Position = Vector2.new(leftMargin + 24, itemY + 2)
                elem.Box.Visible    = true
                elem.Box.Position   = Vector2.new(leftMargin, itemY + 2)
                elem.Box.Size       = Vector2.new(14, 14)
                elem.Box.Color      = Color3.fromRGB(45, 45, 52)
                elem.Inner.Visible  = toggled
                elem.Inner.Position = Vector2.new(leftMargin + 2, itemY + 4)
                elem.Inner.Size     = Vector2.new(10, 10)
                itemY = itemY + 24

            elseif elem.Type == "Slider" then
                local curVal = State[elem.Ref]
                elem.Label.Position   = Vector2.new(leftMargin, itemY)
                elem.ValLabel.Visible = true
                elem.ValLabel.Text    = elem.Float
                    and string.format("%.2f", curVal) or tostring(math.floor(curVal))
                elem.ValLabel.Position = Vector2.new(self.X + self.W - 55, itemY)
                elem.ValLabel.Color    = Color3.fromRGB(180, 180, 190)

                local barW = self.W - 32
                elem.Bar.Visible  = true
                elem.Bar.Position = Vector2.new(leftMargin, itemY + 16)
                elem.Bar.Size     = Vector2.new(barW, 8)

                local ratio = math.clamp((curVal - elem.Min) / (elem.Max - elem.Min), 0, 1)
                elem.Fill.Visible  = true
                elem.Fill.Position = Vector2.new(leftMargin, itemY + 16)
                elem.Fill.Size     = Vector2.new(barW * ratio, 8)

                if self.ActiveSlider == elem and mouseDown then
                    local newRatio = math.clamp((mouse.X - leftMargin) / barW, 0, 1)
                    local newVal   = elem.Min + ((elem.Max - elem.Min) * newRatio)
                    State[elem.Ref] = elem.Float and newVal or math.floor(newVal + 0.5)
                end
                itemY = itemY + 30

            elseif elem.Type == "Dropdown" then
                elem.Label.Position = Vector2.new(leftMargin, itemY + 2)

                local boxX = self.X + self.W - 145
                elem.MainBox.Visible   = true
                elem.MainBox.Position  = Vector2.new(boxX, itemY)
                elem.MainBox.Size      = Vector2.new(129, 22)
                elem.MainText.Visible  = true
                elem.MainText.Position = Vector2.new(boxX + 8, itemY + 4)
                elem.MainText.Text     = tostring(State[elem.Ref])
                elem.MainText.Color    = Color3.fromRGB(240, 240, 245)

                if elem.Open then
                    for oi, od in ipairs(elem.OptionDraws) do
                        local oy = itemY + (oi * 23)
                        od.Box.Visible   = true
                        od.Box.Position  = Vector2.new(boxX, oy)
                        od.Box.Size      = Vector2.new(129, 23)
                        od.Box.Color     = (State[elem.Ref] == od.Val)
                            and Color3.fromRGB(38, 38, 46) or Color3.fromRGB(25, 25, 30)
                        od.Text.Visible  = true
                        od.Text.Position = Vector2.new(boxX + 8, oy + 5)
                        od.Text.Color    = (State[elem.Ref] == od.Val)
                            and Color3.fromRGB(255, 43, 43) or Color3.fromRGB(180, 180, 190)
                    end
                else
                    for _, od in ipairs(elem.OptionDraws) do
                        od.Box.Visible  = false
                        od.Text.Visible = false
                    end
                end
                itemY = itemY + 28

            elseif elem.Type == "Button" then
                local bW = self.W - 32
                elem.Box.Visible   = true
                elem.Box.Position  = Vector2.new(leftMargin, itemY)
                elem.Box.Size      = Vector2.new(bW, 28)
                elem.Label.Visible = true
                elem.Label.Position = Vector2.new(leftMargin + (bW / 2), itemY + 7)
                elem.Label.Color   = Color3.fromRGB(240, 240, 245)
                itemY = itemY + 36
            end
        else
            elem.Label.Visible = false
            if elem.Box      then elem.Box.Visible      = false end
            if elem.Inner    then elem.Inner.Visible    = false end
            if elem.Bar      then elem.Bar.Visible      = false end
            if elem.Fill     then elem.Fill.Visible     = false end
            if elem.ValLabel then elem.ValLabel.Visible = false end
            if elem.MainBox  then elem.MainBox.Visible  = false end
            if elem.MainText then elem.MainText.Visible = false end
            if elem.OptionDraws then
                for _, od in ipairs(elem.OptionDraws) do
                    od.Box.Visible  = false
                    od.Text.Visible = false
                end
            end
        end
    end

    if not mouseDown then
        self.ActiveSlider = nil
    end
end

-- ============================================================================
-- INPUT MANAGEMENT (unified PC + Touch)
-- ============================================================================

local function HandlePress(pos)
    if not State.UIVisible then return end

    -- 1. Dropdown option hit-test (topmost in visual order)
    if GUI.ActiveDropdown and GUI.ActiveDropdown.Open then
        for _, od in ipairs(GUI.ActiveDropdown.OptionDraws) do
            if od.Box.Visible then
                local bPos, bSize = od.Box.Position, od.Box.Size
                if pos.X >= bPos.X and pos.X <= bPos.X + bSize.X
                and pos.Y >= bPos.Y and pos.Y <= bPos.Y + bSize.Y then
                    State[GUI.ActiveDropdown.Ref] = od.Val
                    GUI.ActiveDropdown.Open = false
                    GUI.ActiveDropdown      = nil
                    return
                end
            end
        end
        -- Tapped outside open dropdown — close it
        GUI.ActiveDropdown.Open = false
        GUI.ActiveDropdown      = nil
    end

    -- 2. Header: drag start + double-tap toggle (mobile alternative to Insert key)
    if GUI_READY
    and pos.X >= GUI.X and pos.X <= GUI.X + GUI.W
    and pos.Y >= GUI.Y and pos.Y <= GUI.Y + 36 then
        local now = tick()
        if now - GUI._lastHeaderTap < 0.4 then
            State.UIVisible    = not State.UIVisible
            GUI._lastHeaderTap = 0
        else
            GUI._lastHeaderTap = now
            GUI.Dragging       = true
            GUI.DragOffset     = Vector2.new(pos.X - GUI.X, pos.Y - GUI.Y)
        end
        return
    end

    -- 3. Tab bar
    if GUI_READY then
        local tabW = GUI.W / #TabNames
        for i, name in ipairs(TabNames) do
            local tx = GUI.X + ((i - 1) * tabW)
            local ty = GUI.Y + 36
            if pos.X >= tx and pos.X <= tx + tabW
            and pos.Y >= ty and pos.Y <= ty + 28 then
                State.ActiveTab = name
                return
            end
        end
    end

    -- 4. Elements
    for _, elem in ipairs(GUI.Elements) do
        if elem.Tab == State.ActiveTab then
            if elem.Type == "Toggle" and elem.Box.Visible then
                local bPos = elem.Box.Position
                -- Wide hit area for mobile touch
                if pos.X >= bPos.X - 4 and pos.X <= bPos.X + 220
                and pos.Y >= bPos.Y - 8 and pos.Y <= bPos.Y + 22 then
                    State[elem.Ref] = not State[elem.Ref]
                    return
                end

            elseif elem.Type == "Slider" and elem.Bar.Visible then
                local bPos, bSize = elem.Bar.Position, elem.Bar.Size
                -- Extra vertical padding for finger touch
                if pos.X >= bPos.X and pos.X <= bPos.X + bSize.X
                and pos.Y >= bPos.Y - 12 and pos.Y <= bPos.Y + bSize.Y + 12 then
                    GUI.ActiveSlider = elem
                    local newRatio   = math.clamp((pos.X - bPos.X) / bSize.X, 0, 1)
                    local newVal     = elem.Min + ((elem.Max - elem.Min) * newRatio)
                    State[elem.Ref]  = elem.Float and newVal or math.floor(newVal + 0.5)
                    return
                end

            elseif elem.Type == "Dropdown" and elem.MainBox.Visible then
                local bPos, bSize = elem.MainBox.Position, elem.MainBox.Size
                if pos.X >= bPos.X and pos.X <= bPos.X + bSize.X
                and pos.Y >= bPos.Y and pos.Y <= bPos.Y + bSize.Y then
                    if GUI.ActiveDropdown and GUI.ActiveDropdown ~= elem then
                        GUI.ActiveDropdown.Open = false
                    end
                    elem.Open          = not elem.Open
                    GUI.ActiveDropdown = elem.Open and elem or nil
                    return
                end

            elseif elem.Type == "Button" and elem.Box.Visible then
                local bPos, bSize = elem.Box.Position, elem.Box.Size
                if pos.X >= bPos.X and pos.X <= bPos.X + bSize.X
                and pos.Y >= bPos.Y and pos.Y <= bPos.Y + bSize.Y then
                    elem.Callback()
                    return
                end
            end
        end
    end
end

-- ── PC: keyboard + mouse ──────────────────────────────────────────────────────
local inputBeganConn = UserInputService.InputBegan:Connect(function(input, _processed)
    if input.KeyCode == Enum.KeyCode.Insert then
        State.UIVisible = not State.UIVisible
        return
    end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local pos = UserInputService:GetMouseLocation()
        TouchState.Position = pos
        TouchState.IsDown   = true
        HandlePress(pos)
    end
end)
table.insert(Connections, inputBeganConn)

local inputEndedConn = UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        TouchState.IsDown = false
        GUI.ActiveSlider  = nil
    end
end)
table.insert(Connections, inputEndedConn)

local mouseMoveConn = UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        TouchState.Position = UserInputService:GetMouseLocation()
    end
end)
table.insert(Connections, mouseMoveConn)

-- ── Mobile: touch events ──────────────────────────────────────────────────────
local touchBeganConn = UserInputService.TouchStarted:Connect(function(touch, _processed)
    TouchState.Position = Vector2.new(touch.Position.X, touch.Position.Y)
    TouchState.IsDown   = true
    HandlePress(TouchState.Position)
end)
table.insert(Connections, touchBeganConn)

local touchMoveConn = UserInputService.TouchMoved:Connect(function(touch, _processed)
    TouchState.Position = Vector2.new(touch.Position.X, touch.Position.Y)
    -- Live slider drag via touch
    if GUI.ActiveSlider then
        local elem    = GUI.ActiveSlider
        local barPos  = elem.Bar.Position
        local barSize = elem.Bar.Size
        if barPos and barSize then
            local newRatio  = math.clamp((TouchState.Position.X - barPos.X) / barSize.X, 0, 1)
            local newVal    = elem.Min + ((elem.Max - elem.Min) * newRatio)
            State[elem.Ref] = elem.Float and newVal or math.floor(newVal + 0.5)
        end
    end
end)
table.insert(Connections, touchMoveConn)

local touchEndConn = UserInputService.TouchEnded:Connect(function(_touch, _processed)
    TouchState.IsDown = false
    GUI.ActiveSlider  = nil
end)
table.insert(Connections, touchEndConn)

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

    -- FOV circle follows the pointer (works on both platforms via TouchState)
    FOVCircle.Visible  = State.ShowFOV
    FOVCircle.Radius   = State.FOV
    FOVCircle.Color    = State.FOVColor
    FOVCircle.Position = TouchState.Position

    -- Camera smoothing aim assist (PC only — mousemoverel unavailable on mobile)
    if State.AimAssist and mousemove then
        local target = GetClosestTarget()
        if target then
            local deltaX = (target.Screen.X - TouchState.Position.X) * State.AimSmoothness
            local deltaY = (target.Screen.Y - TouchState.Position.Y) * State.AimSmoothness
            mousemove(deltaX, deltaY)
        end
    end

    UpdateESP()
    ApplyWorldMods()

    if State.ChamsEnabled then
        for _, plr in ipairs(Players:GetPlayers()) do
            ApplyChams(plr)
        end
    else
        for plr in pairs(ChamApplied) do
            RestoreChams(plr)
        end
    end

    -- Wrap in pcall so any runtime error inside Render doesn't silently kill
    -- the render connection (which would make the UI permanently invisible).
    pcall(function() GUI:Render() end)
end)
table.insert(Connections, renderConn)

-- ── Player lifecycle hooks ────────────────────────────────────────────────────
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

    for _, draw in ipairs(RenderObjects) do
        pcall(function() draw:Remove() end)
    end
    table.clear(RenderObjects)

    Lighting.Ambient        = OriginalLighting.Ambient
    Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
    Lighting.Brightness     = OriginalLighting.Brightness
    Lighting.FogEnd         = OriginalLighting.FogEnd

    env.UNIVERSAL_SUITE_UNLOAD = nil
end

env.UNIVERSAL_SUITE_UNLOAD = UnloadSuite
