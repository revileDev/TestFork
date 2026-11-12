-- BloxStrike - Pro Visual & Utility Suite (5-Tab Brisk UI Edition)
-- Target Game: [ZOMBIES!] BloxStrike (PlaceId: 114234929420007)
-- High-Performance Event-Cached Visuals, Material Chams, PVS-Aware ESP, Mobile/PC Auto-Bhop

if _G.__BloxStrikeSuiteCleanup then
  pcall(_G.__BloxStrikeSuiteCleanup)
  _G.__BloxStrikeSuiteCleanup = nil
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera
local GuiHost = (typeof(gethui) == "function" and gethui()) or CoreGui or PlayerGui

-- Running game code can silently strip this thread's capabilities (Delta): afterwards touching our own
-- gethui() GUI throws "lacking capability Plugin". Re-apply identity 8 after EVERY call into game code.
local function restoreIdentity()
  if typeof(setthreadidentity) == "function" then
    pcall(setthreadidentity, 8)
  end
end

local function safeRequire(inst)
  if not inst then return nil end
  local ok, mod = pcall(require, inst)
  restoreIdentity()
  return ok and mod or nil
end

-- Returns (ok, results...) exactly like pcall. NOTE: in an `a and b and callRestored()` expression only the
-- FIRST value (ok) survives - always destructure: `local ok, val = callRestored(...)`.
local function callRestored(fn, ...)
  if type(fn) ~= "function" then return false end
  local res = table.pack(pcall(fn, ...))
  restoreIdentity()
  return table.unpack(res, 1, res.n)
end

local CommonFolder = ReplicatedStorage:FindFirstChild("Components") and ReplicatedStorage.Components:FindFirstChild("Common")
local ControllersFolder = ReplicatedStorage:FindFirstChild("Controllers")
local MV2Folder = ReplicatedStorage:FindFirstChild("MovementV2")
local SecurityFolder = ReplicatedStorage:FindFirstChild("Database") and ReplicatedStorage.Database:FindFirstChild("Security")

local FlashEffect = safeRequire(CommonFolder and CommonFolder:FindFirstChild("VFXLibary") and CommonFolder.VFXLibary:FindFirstChild("FlashEffect"))
local CameraController = safeRequire(ControllersFolder and ControllersFolder:FindFirstChild("CameraController"))
local LocalCharacterMod = safeRequire(ControllersFolder and ControllersFolder:FindFirstChild("CharacterController") and ControllersFolder.CharacterController:FindFirstChild("LocalCharacter"))
local RuntimeKinematics = safeRequire(MV2Folder and MV2Folder:FindFirstChild("RuntimeKinematics"))
local MV2Config = safeRequire(MV2Folder and MV2Folder:FindFirstChild("Simulation") and MV2Folder.Simulation:FindFirstChild("Config"))
local Remotes = safeRequire(SecurityFolder and SecurityFolder:FindFirstChild("Remotes"))
local HAMMER_UNIT_TO_STUD = (MV2Config and MV2Config.Default and MV2Config.Default.HammerUnitToStud) or 0.075

-- BloxStrike R15-like skeleton joint pairs
local SKELETON_JOINTS = {
  { "Head", "UpperTorso" },
  { "UpperTorso", "LowerTorso" },
  { "UpperTorso", "LeftUpperArm" },
  { "LeftUpperArm", "LeftLowerArm" },
  { "LeftLowerArm", "LeftHand" },
  { "UpperTorso", "RightUpperArm" },
  { "RightUpperArm", "RightLowerArm" },
  { "RightLowerArm", "RightHand" },
  { "LowerTorso", "LeftUpperLeg" },
  { "LeftUpperLeg", "LeftLowerLeg" },
  { "LeftLowerLeg", "LeftFoot" },
  { "LowerTorso", "RightUpperLeg" },
  { "RightUpperLeg", "RightLowerLeg" },
  { "RightLowerLeg", "RightFoot" },
}

-- Snapshot original Lighting & Camera properties for clean restore
local origAtmos = Lighting:FindFirstChildOfClass("Atmosphere")
local OriginalLighting = {
  Brightness = Lighting.Brightness,
  ClockTime = Lighting.ClockTime,
  GlobalShadows = Lighting.GlobalShadows,
  Ambient = Lighting.Ambient,
  OutdoorAmbient = Lighting.OutdoorAmbient,
  FogStart = Lighting.FogStart,
  FogEnd = Lighting.FogEnd,
  AtmosDensity = origAtmos and origAtmos.Density or nil,
  AtmosHaze = origAtmos and origAtmos.Haze or nil,
}
local OriginalFOV = Camera and Camera.FieldOfView or 70
local OriginalCameraMode = LocalPlayer.CameraMode
local OriginalMinZoom = LocalPlayer.CameraMinZoomDistance
local OriginalMaxZoom = LocalPlayer.CameraMaxZoomDistance

-- Brisk 14-Color Palette
local ColorPalette = {
  Green    = Color3.fromRGB(0, 230, 118),
  Cyan     = Color3.fromRGB(0, 229, 255),
  Red      = Color3.fromRGB(255, 60, 60),
  Orange   = Color3.fromRGB(255, 130, 0),
  Purple   = Color3.fromRGB(190, 80, 255),
  Gold     = Color3.fromRGB(255, 215, 0),
  White    = Color3.fromRGB(255, 255, 255),
  Yellow   = Color3.fromRGB(255, 235, 59),
  Pink     = Color3.fromRGB(255, 105, 180),
  Blue     = Color3.fromRGB(60, 140, 255),
  Lime     = Color3.fromRGB(160, 255, 50),
  Crimson  = Color3.fromRGB(200, 20, 40),
  Magenta  = Color3.fromRGB(255, 0, 220),
  Teal     = Color3.fromRGB(0, 180, 160),
}
local ColorNames = { "Green", "Cyan", "Red", "Orange", "Purple", "Gold", "White", "Yellow", "Pink", "Blue", "Lime", "Crimson", "Magenta", "Teal" }

-- UI THEME: identical palette/fonts to the Skin Changer ("unbranded") UI so everything looks like one product.
local T = {
  BG         = Color3.fromRGB(24, 24, 27),
  SIDE       = Color3.fromRGB(18, 18, 20),
  CARD       = Color3.fromRGB(30, 30, 34),
  CARD_ALT   = Color3.fromRGB(36, 36, 42),
  INPUT      = Color3.fromRGB(14, 14, 16),
  BORDER     = Color3.fromRGB(44, 44, 50),
  BORDER_HI  = Color3.fromRGB(65, 65, 75),
  TEXT       = Color3.fromRGB(245, 245, 247),
  TEXT_DIM   = Color3.fromRGB(140, 140, 150),
  ACCENT     = Color3.fromRGB(220, 220, 225),
  ACCENT_DIM = Color3.fromRGB(40, 40, 48),
  GREEN      = Color3.fromRGB(34, 170, 96),
  GOLD       = Color3.fromRGB(230, 185, 80),
  RED        = Color3.fromRGB(235, 75, 75),
  PINK       = Color3.fromRGB(215, 80, 150),
  FONT       = Enum.Font.SourceSansBold,
  FONT_REG   = Enum.Font.SourceSans,
}

local MaterialNames = { "HighlightOnly", "Wireframe", "ForceField", "Neon", "Glass", "SmoothPlastic" }
local MatEnums = {
  HighlightOnly = "HighlightOnly",
  Wireframe     = "Wireframe",
  ForceField    = Enum.Material.ForceField,
  Neon          = Enum.Material.Neon,
  Glass         = Enum.Material.Glass,
  SmoothPlastic = Enum.Material.SmoothPlastic,
}

-- All active visual/gameplay toggles start OFF by default!
local Config = {
  -- ESP Tab
  ESPEnabled = false,
  TeamCheck = true,
  ShowBots = true,
  ShowCulled = true, -- Show out-of-range (server-culled) players: last seen / heard / shot position, or spawn during buy period
  GhostMaxAge = 30,  -- seconds a ghost stays on screen after its last real sighting / sound / shot
  BoxESP = false,
  BoxType = "Corner", -- "Corner" | "Full"
  BoxColor = ColorPalette.Red,
  TeamBoxColor = ColorPalette.Cyan,
  CulledColor = ColorPalette.Gold,
  NameESP = false,
  NameColor = ColorPalette.White,
  HealthBar = false,
  DistanceESP = false,
  WeaponESP = false,
  HeadDot = false,
  HeadDotColor = ColorPalette.Red,
  SkeletonESP = false,
  SkeletonColor = ColorPalette.White,
  Tracers = false,
  TracerOrigin = "Bottom", -- "Bottom" | "Center" | "Top"
  TracerColor = ColorPalette.Red,
  OffscreenArrows = false,
  PlayerMaxDist = 1000,

  -- Sound / Gunfire ESP (replicates across PVS walls!)
  SoundESP = false,
  SoundColor = ColorPalette.Orange,
  SoundMaxAge = 2.5,

  -- 2D Radar
  RadarEnabled = false,
  RadarRange = 200,
  RadarSize = 150,
  RadarBlipColor = ColorPalette.Red,

  -- Zombies (Survival)
  ZombieESP = false,
  ZombieBoxes = false,
  ZombieNames = false,
  ZombieColor = ColorPalette.Green,
  ZombieMaxDist = 600,

  -- Chams Tab (Material + Highlight)
  EnemyChams = false,
  EnemyMaterial = "Neon",
  EnemyAlwaysOnTop = true,
  EnemyChamColor = ColorPalette.Red,
  ChamFillTrans = 0.55,
  StripChamTextures = true, -- remove skin textures (SurfaceAppearance etc.) while a material cham is on, so ONLY the cham shows
  ZombieChams = false,
  ZombieMaterial = "Neon",
  ZombieChamColor = ColorPalette.Green,
  LocalChams = false,
  LocalMaterial = "ForceField",
  LocalChamColor = ColorPalette.Cyan,
  WeaponChams = false,
  WeaponMaterial = "ForceField",
  WeaponChamColor = ColorPalette.Gold,

  -- World & HUD Tab
  BombESP = false,
  BombColor = ColorPalette.Orange,
  BombTimerHUD = false,
  WeaponDropESP = false,
  WeaponDropColor = ColorPalette.White,
  BuyStationESP = false,
  BuyStationColor = ColorPalette.Cyan,
  VelocityHUD = false,
  SpectatorHUD = false,
  RadarAlwaysOn = false,

  -- Visuals Tab
  NoFlash = false,
  NoSmoke = false,
  NoScopeOverlay = false,
  NoFog = false,
  NoShadows = false,
  Fullbright = false,
  TimePreset = "Default",
  FOVEnabled = false,
  CustomFOV = 90,
  AspectEnabled = false,
  AspectRatio = 1.0,
  ThirdPerson = false,
  ThirdPersonDist = 10,
  CrosshairEnabled = false,
  CrosshairStyle = "Cross",
  CrosshairColor = ColorPalette.Green,
  CrosshairSize = 8,
  CrosshairGap = 4,

  -- Utilities Tab
  AutoBhop = false,
  ShowTogglePill = true,

  -- Combat Tab (all active combat toggles start OFF by default)
  AimbotEnabled = false,
  AimbotMode = "Hold Aim (any)",
  AimbotHitbox = "Head",
  AimbotFOV = 120,
  AimbotShowFOV = false,
  AimbotFOVColor = ColorPalette.Cyan,
  AimbotSmooth = 4,
  AimbotSticky = true,
  AimbotTeamCheck = true,
  AimbotBots = true,
  AimbotZombies = false,
  AimbotVisCheck = true,
  AimbotSmokeCheck = true,

  SilentAimEnabled = false,
  SilentHitbox = "Head",
  SilentAimFOV = 120,
  SilentShowFOV = false,
  SilentHitchance = 100,
  SilentVisCheck = true,
  SilentSmokeCheck = true,

  WallbangMode = "Off", -- "Off" | "Penetrable" | "Full (All Walls)"

  TriggerbotEnabled = false,
  TriggerMode = "Always",
  TriggerHeadOnly = false,
  TriggerDelayMs = 25,
  TriggerBurstMode = false,
  TriggerIgnoreSmoke = false,
  TriggerIgnoreFlash = false,

  RecoilControlPct = 0,
  NoCameraKick = false,
  SpreadReductionPct = 0,
  AutoReload = false,
  AutoPistol = false,

  TargetHUD = false,
  HitMarker = false,
  HitSound = false,
}

local Connections = {}
local Unloaded = false

local function trackConn(c)
  if c then table.insert(Connections, c) end
  return c
end

-- ============================================================================
-- CACHED ENTITY & RIG RESOLVERS (Zero Repeated Tree Scans)
-- ============================================================================
local CachedParticipants = {}
local ParticipantsDirty = true

local function markParticipantsDirty()
  ParticipantsDirty = true
end

trackConn(Players.PlayerAdded:Connect(markParticipantsDirty))
trackConn(Players.PlayerRemoving:Connect(markParticipantsDirty))
local CombatantsFolder = ReplicatedStorage:FindFirstChild("Combatants")
if CombatantsFolder then
  trackConn(CombatantsFolder.ChildAdded:Connect(markParticipantsDirty))
  trackConn(CombatantsFolder.ChildRemoved:Connect(markParticipantsDirty))
end
trackConn(ReplicatedStorage.ChildAdded:Connect(function(c)
  if c.Name == "Combatants" then
    CombatantsFolder = c
    markParticipantsDirty()
    trackConn(c.ChildAdded:Connect(markParticipantsDirty))
    trackConn(c.ChildRemoved:Connect(markParticipantsDirty))
  end
end))

local function getParticipants()
  if not CombatantsFolder or CombatantsFolder.Parent ~= ReplicatedStorage then
    local f = ReplicatedStorage:FindFirstChild("Combatants")
    if f ~= CombatantsFolder then
      CombatantsFolder = f
      ParticipantsDirty = true
    end
  end
  if ParticipantsDirty then
    table.clear(CachedParticipants)
    for _, p in ipairs(Players:GetPlayers()) do
      table.insert(CachedParticipants, p)
    end
    if CombatantsFolder and CombatantsFolder.Parent then
      for _, b in ipairs(CombatantsFolder:GetChildren()) do
        if b:IsA("Folder") then table.insert(CachedParticipants, b) end
      end
    end
    ParticipantsDirty = false
  end
  return CachedParticipants
end

-- JSON Attribute Cache
local JsonCache = setmetatable({}, { __mode = "k" })
local function decodeAttrTable(inst, attrName)
  local raw = inst and inst:GetAttribute(attrName)
  if type(raw) ~= "string" or raw == "" then return nil end
  local cache = JsonCache[inst]
  if not cache then cache = {}; JsonCache[inst] = cache end
  local hit = cache[attrName]
  if hit and hit.raw == raw then return hit.val end
  local ok, dec = pcall(HttpService.JSONDecode, HttpService, raw)
  local val = (ok and type(dec) == "table") and dec or nil
  cache[attrName] = { raw = raw, val = val }
  return val
end

local function getParticipantWeaponName(p, char)
  local eq = decodeAttrTable(p, "CurrentEquipped") or (char and decodeAttrTable(char, "CurrentEquipped"))
  if eq and type(eq.Name) == "string" and eq.Name ~= "" then return eq.Name end
  local wn = p:GetAttribute("WeaponName") or (char and char:GetAttribute("WeaponName"))
  return (type(wn) == "string" and wn ~= "") and wn or nil
end

local function getParticipantArmor(p, char)
  local arm = decodeAttrTable(p, "Armor") or (char and decodeAttrTable(char, "Armor"))
  if arm and type(arm.Health) == "number" then return math.floor(arm.Health + 0.5) end
  return 0
end

local function getParticipantDisplayName(p)
  if p:IsA("Player") then return p.Name end
  local dn = p:GetAttribute("DisplayName")
  return (type(dn) == "string" and dn ~= "") and dn or p.Name
end

local function isEnemyParticipant(p)
  if p == LocalPlayer then return false end
  if Workspace:GetAttribute("Gamemode") == "Deathmatch" then return true end
  local tTeam = p:GetAttribute("Team") or (p:IsA("Player") and p.Team and p.Team.Name) or nil
  if tTeam ~= "Terrorists" and tTeam ~= "Counter-Terrorists" then return false end
  local myTeam = LocalPlayer:GetAttribute("Team") or (LocalPlayer.Team and LocalPlayer.Team.Name) or nil
  if myTeam == nil then return true end
  return tTeam ~= myTeam
end

local function isParticipantAlive(p, char)
  -- Always trust authoritative Player / Combatants folder attributes first
  -- (retired/culled Character shells in _PVS_CulledCharacters can keep Dead=true from previous round)
  if p:GetAttribute("IsSpectating") == true then return false end
  if p:GetAttribute("Dead") == true then return false end
  local hp = p:GetAttribute("Health")
  if type(hp) == "number" and hp <= 0 then return false end
  local hasAuthoritative = (p:GetAttribute("Dead") ~= nil) or (type(hp) == "number")
  if not hasAuthoritative and char then
    if char:GetAttribute("Dead") == true then return false end
    local mhp = char:GetAttribute("Health")
    if type(mhp) == "number" and mhp <= 0 then return false end
  end
  return true
end

local CharactersFolder = Workspace:FindFirstChild("Characters")
local CulledFolder = ReplicatedStorage:FindFirstChild("_PVS_CulledCharacters")

local function getCharactersFolder()
  if not CharactersFolder or CharactersFolder.Parent ~= Workspace then
    CharactersFolder = Workspace:FindFirstChild("Characters")
  end
  return CharactersFolder
end

local function getCulledFolder()
  if not CulledFolder or CulledFolder.Parent ~= ReplicatedStorage then
    CulledFolder = ReplicatedStorage:FindFirstChild("_PVS_CulledCharacters")
  end
  return CulledFolder
end

local LastKnownParticipantPos = setmetatable({}, { __mode = "k" })

local function resolveParticipantCharacter(p)
  local lookup = getParticipantDisplayName(p)
  local cf = getCharactersFolder()
  if cf then
    local m = cf:FindFirstChild(lookup)
    if m and m:IsA("Model") then return m, false end
  end
  local cuf = getCulledFolder()
  if cuf then
    local m = cuf:FindFirstChild(lookup)
    if m and m:IsA("Model") then return m, true end
  end
  if p:IsA("Player") and p.Character then
    local isC = (cuf and p.Character:IsDescendantOf(cuf)) or false
    return p.Character, isC
  end
  return nil, false
end

local function getLocalCharacter()
  local cf = getCharactersFolder()
  return (cf and cf:FindFirstChild(LocalPlayer.Name)) or LocalPlayer.Character
end

-- Per-Character Rig Part Cache (auto-upgrades if limbs finish parenting after initial resolve)
local RigPartCache = setmetatable({}, { __mode = "k" })
local function getRigInfo(char)
  local info = RigPartCache[char]
  if info and info.Root and info.Root.Parent == char and info.BoneCount >= #SKELETON_JOINTS then
    return info
  end
  if info and info.Root and info.Root.Parent == char and (os.clock() - (info.BuiltAt or 0) < 0.35) then
    return info
  end
  local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChild("UpperTorso") or char:FindFirstChildWhichIsA("BasePart")
  local head = char:FindFirstChild("Head")
  local bones = {}
  local boneCount = 0
  for i, pair in ipairs(SKELETON_JOINTS) do
    local a = char:FindFirstChild(pair[1])
    local b = char:FindFirstChild(pair[2])
    if a and b and a:IsA("BasePart") and b:IsA("BasePart") then
      bones[i] = { a, b }
      boneCount = boneCount + 1
    end
  end
  info = { Root = root, Head = head, Bones = bones, BoneCount = boneCount, BuiltAt = os.clock() }
  RigPartCache[char] = info
  return info
end

-- ============================================================================
-- SCREENGUI CONTAINERS & DRAWING HELPERS
-- ============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BloxStrikeVisualSuite"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999999
ScreenGui.Parent = GuiHost

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "ESPDrawings"
ESPFolder.Parent = ScreenGui

local ChamsFolder = nil
local function getChamsFolder()
  local cam = Workspace.CurrentCamera
  if not cam then return nil end
  if ChamsFolder and ChamsFolder.Parent == cam then return ChamsFolder end
  local f = cam:FindFirstChild("BloxStrikeChams")
  if not f then
    f = Instance.new("Folder")
    f.Name = "BloxStrikeChams"
    f.Parent = cam
  end
  ChamsFolder = f
  return f
end
getChamsFolder()

local function draw2DLine(frame, p1, p2, color, thickness)
  local dx = p2.X - p1.X
  local dy = p2.Y - p1.Y
  local len = math.sqrt(dx * dx + dy * dy)
  if len < 1 then
    frame.Visible = false
    return
  end
  frame.Size = UDim2.fromOffset(len, thickness or 1.4)
  frame.Position = UDim2.fromOffset((p1.X + p2.X) * 0.5, (p1.Y + p2.Y) * 0.5)
  frame.Rotation = math.deg(math.atan2(dy, dx))
  frame.BackgroundColor3 = color
  frame.Visible = true
end

-- scaleObj (optional UIScale): drag deltas are divided by it so a scaled window follows the cursor 1:1.
-- Returns a state table; state.Moved is the largest distance of the last drag (use it to ignore a click that ended a drag).
local function makeDraggable(topbar, target, scaleObj)
  local state = { Moved = 0 }
  local dragging, dragStart, startPos = false, nil, nil
  trackConn(topbar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
      dragging = true
      state.Moved = 0
      dragStart = inp.Position
      startPos = target.Position
    end
  end))
  trackConn(UserInputService.InputChanged:Connect(function(inp)
    if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
      local d = inp.Position - dragStart
      state.Moved = math.max(state.Moved, math.abs(d.X) + math.abs(d.Y))
      local s = (scaleObj and scaleObj.Scale > 0) and scaleObj.Scale or 1
      target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X / s, startPos.Y.Scale, startPos.Y.Offset + d.Y / s)
    end
  end))
  trackConn(UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
      dragging = false
    end
  end))
  return state
end

-- ============================================================================
-- CACHED MATERIAL & HIGHLIGHT CHAMS SYSTEM (Zero Per-Frame Mutations)
-- ============================================================================
local IgnoredChamPartNames = {
  HumanoidRootPart = true, CameraPart = true, Hitbox = true, RootPart = true, Insert = true,
  MuzzlePart = true, MuzzlePartL = true, MuzzlePartR = true, Camera = true,
  Trigger_Part = true, Barrel_Part = true, Slide_Part = true, Handle_Part = true,
  Magazine_Part = true, EmptyShell_Part = true, SlideRelease_Part = true, Pistol = true,
}

local ChamsHighlights = {}   -- [model] = Highlight
local WireframeBoxes  = {}   -- [part] = SelectionBox
local OriginalPartProps = {} -- [part] = { Material, Color }
local ModelVisibleParts = {} -- [model] = { BasePart, ... }
local ModelAppliedState = {} -- [model] = { key = string }

local function isChamVisiblePart(part)
  if not part or not part:IsA("BasePart") then return false end
  if IgnoredChamPartNames[part.Name] then return false end
  if OriginalPartProps[part] then return true end
  return part.Transparency < 0.99
end

local function getModelChamParts(model)
  local cached = ModelVisibleParts[model]
  if cached then return cached end
  local parts = {}
  for _, d in ipairs(model:GetDescendants()) do
    if isChamVisiblePart(d) then table.insert(parts, d) end
  end
  ModelVisibleParts[model] = parts
  return parts
end

-- Skin textures (SurfaceAppearance / MeshPart.TextureID / decals) override Material + Color, so a material cham on a
-- skinned part never shows. While chams are on they are stashed on the part's record and put back exactly on restore.
local function setPartTextures(part, rec, strip)
  if strip then
    if rec.Stripped then return end
    rec.Stripped = true
    local sa = part:FindFirstChildOfClass("SurfaceAppearance")
    if sa then rec.SA = sa; sa.Parent = nil end
    if part:IsA("MeshPart") and part.TextureID ~= "" then rec.TextureID = part.TextureID; part.TextureID = "" end
    for _, c in ipairs(part:GetChildren()) do
      if c:IsA("Decal") or c:IsA("Texture") then
        rec.Decals = rec.Decals or {}
        table.insert(rec.Decals, { c, c.Transparency })
        c.Transparency = 1
      end
    end
  elseif rec.Stripped then
    rec.Stripped = false
    if rec.SA and part.Parent then rec.SA.Parent = part end
    rec.SA = nil
    if rec.TextureID and part:IsA("MeshPart") then part.TextureID = rec.TextureID end
    rec.TextureID = nil
    for _, d in ipairs(rec.Decals or {}) do
      if d[1] and d[1].Parent then d[1].Transparency = d[2] end
    end
    rec.Decals = nil
  end
end

local function restoreSinglePartProps(part)
  local props = OriginalPartProps[part]
  if props then
    if part and part.Parent then
      part.Material = props.Material
      part.Color = props.Color
    end
    pcall(setPartTextures, part, props, false)
    OriginalPartProps[part] = nil
  end
  local sb = WireframeBoxes[part]
  if sb then
    pcall(function() sb:Destroy() end)
    WireframeBoxes[part] = nil
  end
end

local function clearModelChams(model)
  ModelAppliedState[model] = nil
  local hl = ChamsHighlights[model]
  if hl then
    pcall(function() hl:Destroy() end)
    ChamsHighlights[model] = nil
  end
  local parts = ModelVisibleParts[model]
  if parts then
    for _, part in ipairs(parts) do
      restoreSinglePartProps(part)
    end
  elseif model and model.Parent then
    for _, d in ipairs(model:GetDescendants()) do
      if d:IsA("BasePart") then restoreSinglePartProps(d) end
    end
  end
  ModelVisibleParts[model] = nil
end

local function applyModelChams(model, matStyle, color, alwaysOnTop, fillTrans, allowHighlight, stripTextures)
  if not model or not model.Parent or not model:IsDescendantOf(Workspace) then
    clearModelChams(model)
    return
  end
  if allowHighlight == nil then allowHighlight = true end
  stripTextures = stripTextures and true or false

  local styleKey = string.format("%s|%d,%d,%d|%s|%.2f|%s|%s",
    tostring(matStyle),
    math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255),
    tostring(alwaysOnTop), fillTrans or 0.55, tostring(allowHighlight), tostring(stripTextures))

  -- PERF: GetDescendants() allocates a table; doing it per model per frame was the single biggest cost of chams.
  -- The style key is checked every frame, the descendant count only every 0.5s per model.
  local nowT = os.clock()
  local prev = ModelAppliedState[model]
  local descCount = prev and prev.descCount or 0
  if not prev or (nowT - (prev.checkedAt or 0)) >= 0.5 then
    descCount = #model:GetDescendants()
  end
  if prev and prev.key == styleKey and prev.descCount == descCount then
    if (nowT - (prev.checkedAt or 0)) >= 0.5 then prev.checkedAt = nowT end
    -- Ensure Highlight stays valid without redundant property writes
    if matStyle == "HighlightOnly" and allowHighlight and ChamsHighlights[model] and ChamsHighlights[model].Parent then
      return
    elseif matStyle ~= "HighlightOnly" then
      return
    end
  elseif prev and prev.descCount ~= descCount then
    ModelVisibleParts[model] = nil
  end

  -- Clear prior style cleanly before switching style modes
  if prev and prev.matStyle ~= matStyle then
    local hl = ChamsHighlights[model]
    if hl then hl.Enabled = false end
    for _, part in ipairs(getModelChamParts(model)) do
      restoreSinglePartProps(part)
    end
  end

  ModelAppliedState[model] = { key = styleKey, matStyle = matStyle, descCount = descCount, checkedAt = nowT }

  if matStyle == "HighlightOnly" then
    if not allowHighlight then return end
    local chamsParent = getChamsFolder()
    if not chamsParent then return end
    local hl = ChamsHighlights[model]
    if not hl or not hl.Parent then
      hl = Instance.new("Highlight")
      hl.Name = "Cham_" .. model.Name
      hl.Parent = chamsParent
      ChamsHighlights[model] = hl
    end
    hl.Adornee = model
    hl.DepthMode = alwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    hl.FillColor = color
    hl.OutlineColor = Color3.new(1, 1, 1)
    hl.FillTransparency = fillTrans or 0.55
    hl.OutlineTransparency = 0.1
    hl.Enabled = true
  elseif matStyle == "Wireframe" then
    for _, part in ipairs(getModelChamParts(model)) do
      local sb = WireframeBoxes[part]
      if not sb or not sb.Parent then
        sb = Instance.new("SelectionBox")
        sb.Name = "BSWire"
        sb.Adornee = part
        sb.SurfaceTransparency = 1
        sb.Transparency = 0
        sb.LineThickness = 0.035
        sb.Parent = part
        WireframeBoxes[part] = sb
      end
      sb.Color3 = color
      sb.Visible = true
    end
  else
    -- Material Cham (Neon, ForceField, Glass, SmoothPlastic) + subtle outline Highlight if AlwaysOnTop
    local matEnum = MatEnums[matStyle] or Enum.Material.Neon
    for _, part in ipairs(getModelChamParts(model)) do
      local rec = OriginalPartProps[part]
      if not rec then
        rec = { Material = part.Material, Color = part.Color }
        OriginalPartProps[part] = rec
      end
      setPartTextures(part, rec, stripTextures)   -- remove skin textures (or put them back if the option was turned off)
      part.Material = matEnum
      part.Color = color
    end
    if alwaysOnTop and allowHighlight then
      local chamsParent = getChamsFolder()
      if chamsParent then
        local hl = ChamsHighlights[model]
        if not hl or not hl.Parent then
          hl = Instance.new("Highlight")
          hl.Name = "Cham_" .. model.Name
          hl.Parent = chamsParent
          ChamsHighlights[model] = hl
        end
        hl.Adornee = model
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.FillColor = color
        hl.OutlineColor = color
        hl.FillTransparency = 0.72
        hl.OutlineTransparency = 0.15
        hl.Enabled = true
      end
    elseif ChamsHighlights[model] then
      ChamsHighlights[model].Enabled = false
    end
  end
end

local function clearAllChams()
  local keys = {}
  for m, _ in pairs(ModelAppliedState) do table.insert(keys, m) end
  for m, _ in pairs(ChamsHighlights) do table.insert(keys, m) end
  for _, m in ipairs(keys) do clearModelChams(m) end
  for part, _ in pairs(OriginalPartProps) do restoreSinglePartProps(part) end
  for part, _ in pairs(WireframeBoxes) do restoreSinglePartProps(part) end
  table.clear(ModelVisibleParts)
  table.clear(ModelAppliedState)
end

-- Periodic garbage sweep (every 1s) cleans destroyed models & dead Highlights/SelectionBoxes
local function pruneStaleChams()
  for model, _ in pairs(ModelAppliedState) do
    if not model or not model.Parent or not model:IsDescendantOf(Workspace) or model:GetAttribute("Dead") == true then
      clearModelChams(model)
    end
  end
  for part, _ in pairs(OriginalPartProps) do
    if not part or not part.Parent then
      OriginalPartProps[part] = nil
    end
  end
  for part, sb in pairs(WireframeBoxes) do
    if not part or not part.Parent then
      if sb then pcall(function() sb:Destroy() end) end
      WireframeBoxes[part] = nil
    end
  end
end

-- ============================================================================
-- NATIVE SCREENGUI ESP POOLS (Players, Zombies, World, Radar, Arrows)
-- ============================================================================
local PlayerESPObjects = {}
local ZombieESPObjects = {}
local WorldESPObjects  = {}
local RadarBlips       = {}
local MAX_SOUND_PINGS  = 16
local SoundPings       = {}
local SoundESPObjects  = {}
local SoundESPUnsub    = nil

local function createPlayerESPEntry(p)
  local box = Instance.new("Frame")
  box.Name = "Box_" .. p.Name
  box.BackgroundTransparency = 1
  box.BorderSizePixel = 0
  box.Visible = false
  box.Parent = ESPFolder

  local boxStroke = Instance.new("UIStroke")
  boxStroke.Thickness = 1.3
  boxStroke.Color = Config.BoxColor
  boxStroke.Parent = box

  local corners = {}
  for i = 1, 8 do
    local cf = Instance.new("Frame")
    cf.BorderSizePixel = 0
    cf.BackgroundColor3 = Config.BoxColor
    cf.Visible = false
    cf.Parent = box
    corners[i] = cf
  end

  local hpBg = Instance.new("Frame")
  hpBg.Size = UDim2.new(0, 3, 1, 0)
  hpBg.Position = UDim2.fromOffset(-6, 0)
  hpBg.BackgroundColor3 = T.INPUT
  hpBg.BorderSizePixel = 0
  hpBg.Visible = false
  hpBg.Parent = box

  local hpFill = Instance.new("Frame")
  hpFill.Size = UDim2.fromScale(1, 1)
  hpFill.BorderSizePixel = 0
  hpFill.BackgroundColor3 = Color3.fromRGB(0, 230, 118)
  hpFill.Parent = hpBg

  local nameLbl = Instance.new("TextLabel")
  nameLbl.AnchorPoint = Vector2.new(0.5, 1)
  nameLbl.Position = UDim2.new(0.5, 0, 0, -2)
  nameLbl.Size = UDim2.new(1, 90, 0, 14)
  nameLbl.BackgroundTransparency = 1
  nameLbl.Font = T.FONT
  nameLbl.TextSize = 13
  nameLbl.TextColor3 = Config.NameColor
  nameLbl.TextStrokeTransparency = 0.35
  nameLbl.TextStrokeColor3 = Color3.new(0, 0, 0)
  nameLbl.Visible = false
  nameLbl.Parent = box

  local btmLbl = Instance.new("TextLabel")
  btmLbl.AnchorPoint = Vector2.new(0.5, 0)
  btmLbl.Position = UDim2.new(0.5, 0, 1, 2)
  btmLbl.Size = UDim2.new(1, 100, 0, 13)
  btmLbl.BackgroundTransparency = 1
  btmLbl.Font = T.FONT
  btmLbl.TextSize = 12
  btmLbl.TextColor3 = T.TEXT
  btmLbl.TextStrokeTransparency = 0.35
  btmLbl.TextStrokeColor3 = Color3.new(0, 0, 0)
  btmLbl.Visible = false
  btmLbl.Parent = box

  local headDot = Instance.new("Frame")
  headDot.AnchorPoint = Vector2.new(0.5, 0.5)
  headDot.Size = UDim2.fromOffset(5, 5)
  headDot.BorderSizePixel = 0
  headDot.BackgroundColor3 = Config.HeadDotColor
  headDot.Visible = false
  headDot.Parent = ESPFolder
  Instance.new("UICorner", headDot).CornerRadius = UDim.new(1, 0)
  local hdStroke = Instance.new("UIStroke", headDot)
  hdStroke.Color = Color3.new(0, 0, 0)
  hdStroke.Thickness = 1

  local tracer = Instance.new("Frame")
  tracer.AnchorPoint = Vector2.new(0.5, 0.5)
  tracer.BorderSizePixel = 0
  tracer.Visible = false
  tracer.Parent = ESPFolder

  local arrow = Instance.new("TextLabel")
  arrow.AnchorPoint = Vector2.new(0.5, 0.5)
  arrow.Size = UDim2.fromOffset(18, 18)
  arrow.BackgroundTransparency = 1
  arrow.Font = T.FONT
  arrow.TextSize = 18
  arrow.Text = "^"
  arrow.TextStrokeTransparency = 0.25
  arrow.TextStrokeColor3 = Color3.new(0, 0, 0)
  arrow.Visible = false
  arrow.Parent = ESPFolder

  local bones = {}
  for i = 1, #SKELETON_JOINTS do
    local b = Instance.new("Frame")
    b.AnchorPoint = Vector2.new(0.5, 0.5)
    b.BorderSizePixel = 0
    b.BackgroundColor3 = Config.SkeletonColor
    b.Visible = false
    b.Parent = ESPFolder
    bones[i] = b
  end

  local obj = {
    Box = box, BoxStroke = boxStroke, Corners = corners,
    HpBg = hpBg, HpFill = hpFill, NameTag = nameLbl, BottomTag = btmLbl,
    HeadDot = headDot, Tracer = tracer, Arrow = arrow, Bones = bones,
    VisibleNow = false,
  }
  PlayerESPObjects[p] = obj
  return obj
end

local function hidePlayerESPEntry(e)
  if not e.VisibleNow then return end
  e.VisibleNow = false
  e.Box.Visible = false
  e.HeadDot.Visible = false
  e.Tracer.Visible = false
  e.Arrow.Visible = false
  for _, b in ipairs(e.Bones) do b.Visible = false end
end

local function destroyPlayerESPEntry(p)
  local e = PlayerESPObjects[p]
  if e then
    pcall(function() e.Box:Destroy() end)
    pcall(function() e.HeadDot:Destroy() end)
    pcall(function() e.Tracer:Destroy() end)
    pcall(function() e.Arrow:Destroy() end)
    for _, b in ipairs(e.Bones) do pcall(function() b:Destroy() end) end
    PlayerESPObjects[p] = nil
  end
  if RadarBlips[p] then
    pcall(function() RadarBlips[p]:Destroy() end)
    RadarBlips[p] = nil
  end
end

local function hideAllPlayerESP()
  for p, e in pairs(PlayerESPObjects) do
    if p.Parent == nil then
      destroyPlayerESPEntry(p)
    else
      hidePlayerESPEntry(e)
    end
  end
end

local function createZombieESPEntry(z)
  local box = Instance.new("Frame")
  box.BackgroundTransparency = 1
  box.BorderSizePixel = 0
  box.Visible = false
  box.Parent = ESPFolder
  local st = Instance.new("UIStroke", box)
  st.Color = Config.ZombieColor
  st.Thickness = 1.2
  local lbl = Instance.new("TextLabel")
  lbl.AnchorPoint = Vector2.new(0.5, 1)
  lbl.Position = UDim2.new(0.5, 0, 0, -2)
  lbl.Size = UDim2.new(1, 80, 0, 16)
  lbl.BackgroundTransparency = 1
  lbl.Font = T.FONT
  lbl.TextSize = 13
  lbl.TextColor3 = Config.ZombieColor
  lbl.TextStrokeTransparency = 0.35
  lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
  lbl.Visible = false
  lbl.Parent = box
  local e = { Box = box, Stroke = st, Label = lbl }
  ZombieESPObjects[z] = e
  return e
end

local function destroyZombieESPEntry(z)
  local e = ZombieESPObjects[z]
  if e then
    pcall(function() e.Box:Destroy() end)
    ZombieESPObjects[z] = nil
  end
end

local function createWorldESPEntry(inst)
  local holder = Instance.new("Frame")
  holder.Size = UDim2.fromOffset(10, 10)
  holder.AnchorPoint = Vector2.new(0.5, 0.5)
  holder.BackgroundTransparency = 1
  holder.Visible = false
  holder.Parent = ESPFolder
  local dot = Instance.new("Frame", holder)
  dot.Size = UDim2.fromOffset(6, 6); dot.AnchorPoint = Vector2.new(0.5, 0.5); dot.Position = UDim2.fromScale(0.5, 0.5); dot.BorderSizePixel = 0
  Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
  local lbl = Instance.new("TextLabel", holder)
  lbl.AnchorPoint = Vector2.new(0.5, 0); lbl.Position = UDim2.new(0.5, 0, 1, 2); lbl.Size = UDim2.fromOffset(140, 16)
  lbl.BackgroundTransparency = 1; lbl.Font = T.FONT; lbl.TextSize = 13
  lbl.TextStrokeTransparency = 0.35; lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
  local e = { Holder = holder, Dot = dot, Label = lbl }
  WorldESPObjects[inst] = e
  return e
end

local function destroyWorldESPEntry(inst)
  local e = WorldESPObjects[inst]
  if e then
    pcall(function() e.Holder:Destroy() end)
    WorldESPObjects[inst] = nil
  end
end

local function getOrCreateSoundESPEntry(idx)
  local e = SoundESPObjects[idx]
  if e then return e end
  local holder = Instance.new("Frame")
  holder.Name = "SoundPing_" .. idx
  holder.Size = UDim2.fromOffset(14, 14)
  holder.AnchorPoint = Vector2.new(0.5, 0.5)
  holder.BackgroundTransparency = 1
  holder.Visible = false
  holder.Parent = ESPFolder

  local ring = Instance.new("Frame", holder)
  ring.Size = UDim2.fromScale(1, 1)
  ring.AnchorPoint = Vector2.new(0.5, 0.5)
  ring.Position = UDim2.fromScale(0.5, 0.5)
  ring.BackgroundTransparency = 1
  Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
  local ringStroke = Instance.new("UIStroke", ring)
  ringStroke.Thickness = 1.4
  ringStroke.Color = Config.SoundColor

  local dot = Instance.new("Frame", holder)
  dot.Size = UDim2.fromOffset(5, 5)
  dot.AnchorPoint = Vector2.new(0.5, 0.5)
  dot.Position = UDim2.fromScale(0.5, 0.5)
  dot.BorderSizePixel = 0
  dot.BackgroundColor3 = Config.SoundColor
  Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

  local lbl = Instance.new("TextLabel", holder)
  lbl.AnchorPoint = Vector2.new(0.5, 0)
  lbl.Position = UDim2.new(0.5, 0, 1, 2)
  lbl.Size = UDim2.fromOffset(160, 16)
  lbl.BackgroundTransparency = 1
  lbl.Font = T.FONT
  lbl.TextSize = 13
  lbl.TextColor3 = Config.SoundColor
  lbl.TextStrokeTransparency = 0.35
  lbl.TextStrokeColor3 = Color3.new(0, 0, 0)

  e = { Holder = holder, RingStroke = ringStroke, Dot = dot, Label = lbl, Shown = false }
  SoundESPObjects[idx] = e
  return e
end

local function hideAllSoundESP()
  for _, e in pairs(SoundESPObjects) do
    if e.Shown then
      e.Shown = false
      e.Holder.Visible = false
    end
  end
end

local function isNearFriendlyCharacter(pos, radius)
  local myChar = getLocalCharacter()
  if myChar then
    local mr = myChar:FindFirstChild("HumanoidRootPart") or myChar.PrimaryPart
    if mr and (mr.Position - pos).Magnitude <= radius then return true end
  end
  for _, p in ipairs(getParticipants()) do
    if p ~= LocalPlayer and not isEnemyParticipant(p) then
      local c = resolveParticipantCharacter(p)
      if c and isParticipantAlive(p, c) then
        local r = c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart
        if r and (r.Position - pos).Magnitude <= radius then return true end
      end
    end
  end
  return false
end

local function formatSoundTag(cls, sname)
  if sname == "Shoot" or sname == "Fire" then
    return "SHOT: " .. cls
  elseif cls == "FloorSounds" or cls == "MovementSounds" or string.find(sname, "Foot", 1, true) or string.find(sname, "Land", 1, true) then
    return "STEP"
  elseif sname ~= "" and cls ~= "Sound" then
    return cls .. " " .. sname
  end
  return (sname ~= "" and sname) or cls
end

-- Pure-Lua Sound + Tracer acoustic tracker (updates behind-wall enemy boxes live on steps/shots)
if Remotes and Remotes.Sound and Remotes.Sound.ReplicateSound and type(Remotes.Sound.ReplicateSound.Listen) == "function" then
  local SCOPED_WEAPONS = { ["AWP"] = true, ["SSG 08"] = true, ["SCAR-20"] = true, ["G3SG1"] = true, ["AUG"] = true, ["SG 553"] = true }
  local NON_WEAPON_CLASSES = { FloorSounds = true, MovementSounds = true, Character = true, Sound = true, Bomb = true, Other = true, Molotov = true, ["HE Grenade"] = true, Flashbang = true, ["Smoke Grenade"] = true, Decoy = true, Incendiary = true }

  local function attributeBehindWallPos(pos, weaponHint, soundName)
    if typeof(pos) ~= "Vector3" or pos.Y < -400 then return end
    if isNearFriendlyCharacter(pos, 14) then return end
    local now = os.clock()
    local teamHint = (weaponHint == "Terrorists" or weaponHint == "Counter-Terrorists") and weaponHint or nil
    local scopeHint = (soundName == "Toggle Scope")
    local isWeaponHint = type(weaponHint) == "string" and weaponHint ~= "" and not NON_WEAPON_CLASSES[weaponHint] and not teamHint

    local bestP, bestDist = nil, math.huge
    local weaponMatches = {}
    local candidates = {}

    for _, p in ipairs(getParticipants()) do
      if p ~= LocalPlayer and isEnemyParticipant(p) then
        if teamHint and p:GetAttribute("Team") ~= teamHint then continue end
        local c, culled = resolveParticipantCharacter(p)
        if isParticipantAlive(p, c) and (culled or not c) then
          local gen = p:GetAttribute("CharacterGeneration") or p:GetAttribute("Generation")
          local refPos = nil
          local lk = LastKnownParticipantPos[p]
          if lk and (gen == nil or lk.gen == gen) then
            refPos = lk.pos
          elseif c then
            local cr = c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart
            if cr and cr.Position.Y > -400 then refPos = cr.Position end
          end
          if not refPos then
            local sp = p:GetAttribute("PresentationSpawnPosition")
            if typeof(sp) == "Vector3" and sp.Y > -400 then refPos = sp end
          end

          table.insert(candidates, { p = p, refPos = refPos, lk = lk, gen = gen })

          if isWeaponHint or scopeHint then
            local w = getParticipantWeaponName(p, c)
            if (isWeaponHint and w == weaponHint) or (scopeHint and w and SCOPED_WEAPONS[w]) then
              table.insert(weaponMatches, { p = p, refPos = refPos, gen = gen })
            end
          end

          if refPos then
            local d = (refPos - pos).Magnitude
            -- Reachability: a player can only have moved ~22 studs/s since we last knew where they were, so a sound
            -- 150 studs away from someone seen 1s ago cannot be theirs. (Before: a flat 85-stud radius for everyone,
            -- which mis-assigned footsteps and made ghost boxes jump between players.)
            local reach = 85
            if lk and lk.time and (gen == nil or lk.gen == gen) then
              reach = math.clamp(22 * (now - lk.time) + 12, 18, 220)
            end
            if d <= reach and d < bestDist then
              bestDist = d
              bestP = p
            end
          end
        end
      end
    end

    local chosen = bestP
    if not chosen and #weaponMatches == 1 then
      chosen = weaponMatches[1].p
    elseif (isWeaponHint or scopeHint) and #weaponMatches > 0 then
      local wBest, wBestD = nil, 220
      for _, m in ipairs(weaponMatches) do
        if m.refPos then
          local d = (m.refPos - pos).Magnitude
          if d < wBestD then wBestD = d; wBest = m.p end
        end
      end
      if not wBest then
        for _, m in ipairs(weaponMatches) do
          if not m.refPos then wBest = m.p; break end
        end
      end
      if wBest then chosen = wBest end
    end

    -- Catch-up fallback for mid-round ESP activation or blind bots that have never entered PVS
    if not chosen and #candidates > 0 then
      local staleBest, staleBestD = nil, 280
      for _, cnd in ipairs(candidates) do
        local isStale = (not cnd.lk) or (not cnd.lk.isAudio) or (now - (cnd.lk.time or 0) > 2.5)
        if isStale then
          if cnd.refPos then
            local d = (cnd.refPos - pos).Magnitude
            if d < staleBestD then staleBestD = d; staleBest = cnd.p end
          elseif not staleBest then
            staleBest = cnd.p
          end
        end
      end
      if staleBest then chosen = staleBest end
    end

    if chosen then
      local gen = chosen:GetAttribute("CharacterGeneration") or chosen:GetAttribute("Generation")
      LastKnownParticipantPos[chosen] = { pos = pos, headPos = nil, gen = gen, isAudio = true, time = now, source = "SOUND" }
    end
  end

  -- ===== Exact shooter positions: muzzle flash (WHO fired) + tracer (WHERE from) =====
  -- The server still replicates both events for culled players. Neither is enough alone (the flash has a UserId but no
  -- position; the tracer has an Origin but no owner) - paired within a short window they give an exact, correctly
  -- attributed position straight through walls. Measured offsets: tracer Origin = root + 1.86 studs up / head + 0.51.
  local PAIR_WINDOW = 0.35
  local ROOT_BELOW_ORIGIN, HEAD_BELOW_ORIGIN = Vector3.new(0, 1.86, 0), Vector3.new(0, 0.51, 0)
  local PendingFlashes, PendingTracers = {}, {}

  local function participantByUserId(uid)
    if type(uid) ~= "number" then return nil end
    for _, p in ipairs(getParticipants()) do
      if p:IsA("Player") then
        if p.UserId == uid then return p end
      elseif p:GetAttribute("UserId") == uid then
        return p
      end
    end
    return nil
  end

  local function recordShot(p, origin)
    local gen = p:GetAttribute("CharacterGeneration") or p:GetAttribute("Generation")
    LastKnownParticipantPos[p] = {
      pos = origin - ROOT_BELOW_ORIGIN, headPos = origin - HEAD_BELOW_ORIGIN,
      gen = gen, isAudio = true, time = os.clock(), source = "SHOT",
    }
  end

  local function prunePending(list, now)
    for i = #list, 1, -1 do
      if now - list[i].t > PAIR_WINDOW then table.remove(list, i) end
    end
  end

  local function onMuzzleFlash(data)
    local p = participantByUserId(data.UserId)
    if not p or p == LocalPlayer or not isEnemyParticipant(p) then return end
    local now = os.clock()
    prunePending(PendingTracers, now)
    local tr = table.remove(PendingTracers, #PendingTracers)   -- newest unmatched tracer
    if tr then
      recordShot(p, tr.origin)
    else
      table.insert(PendingFlashes, { p = p, t = now })
    end
  end

  local function onTracer(origin)
    if isNearFriendlyCharacter(origin - ROOT_BELOW_ORIGIN, 14) then return end   -- our own / a teammate's shot
    local now = os.clock()
    prunePending(PendingFlashes, now)
    local f = table.remove(PendingFlashes, #PendingFlashes)
    if f then
      recordShot(f.p, origin)
      return
    end
    -- no flash yet: wait one window for it, then fall back to the proximity heuristic
    local rec = { origin = origin, t = now }
    table.insert(PendingTracers, rec)
    task.delay(PAIR_WINDOW + 0.05, function()
      local idx = table.find(PendingTracers, rec)
      if idx then
        table.remove(PendingTracers, idx)
        if not Unloaded then attributeBehindWallPos(origin - ROOT_BELOW_ORIGIN, nil) end
      end
    end)
  end

  local okSub, unsub = pcall(Remotes.Sound.ReplicateSound.Listen, function(data)
    if Unloaded or (not Config.ESPEnabled and not Config.RadarEnabled and not Config.EnemyChams) then return end
    if type(data) ~= "table" then return end

    local cls = type(data.Class) == "string" and data.Class or "Sound"
    local sname = type(data.Name) == "string" and data.Name or ""
    local pos = typeof(data.Position) == "Vector3" and data.Position or nil
    local matchedDirect = false

    if data.Parent and typeof(data.Parent) == "Instance" then
      local mdl = data.Parent:FindFirstAncestorOfClass("Model") or (data.Parent:IsA("Model") and data.Parent)
      if mdl then
        local mPos = mdl:GetPivot().Position
        if mPos.Y > -400 then
          for _, p in ipairs(getParticipants()) do
            if p ~= LocalPlayer and getParticipantDisplayName(p) == mdl.Name then
              local gen = p:GetAttribute("CharacterGeneration") or p:GetAttribute("Generation")
              LastKnownParticipantPos[p] = { pos = pos or mPos, headPos = nil, gen = gen, isAudio = true, time = os.clock() }
              matchedDirect = true
              break
            end
          end
        end
        if not pos and mPos.Y > -400 then pos = mPos end
      end
    end

    if typeof(pos) == "Vector3" and not matchedDirect then
      attributeBehindWallPos(pos, cls, sname)
    end

    if not Config.SoundESP or typeof(pos) ~= "Vector3" then return end
    if isNearFriendlyCharacter(pos, 14) then return end

    local tag = formatSoundTag(cls, sname)
    local now = os.clock()

    for i = #SoundPings, 1, -1 do
      if now - SoundPings[i].time > Config.SoundMaxAge then
        table.remove(SoundPings, i)
      end
    end

    for _, ping in ipairs(SoundPings) do
      if (ping.pos - pos).Magnitude <= 12 then
        ping.pos = pos
        ping.time = now
        if string.sub(tag, 1, 5) == "SHOT:" or string.sub(ping.label, 1, 5) ~= "SHOT:" then
          ping.label = tag
        end
        return
      end
    end

    if #SoundPings >= MAX_SOUND_PINGS then
      table.remove(SoundPings, 1)
    end
    table.insert(SoundPings, { pos = pos, label = tag, time = now })
  end)

  local ESP_ACTIVE = function() return Config.ESPEnabled or Config.RadarEnabled or Config.EnemyChams end
  local extraUnsubs = {}

  if Remotes.VFX and Remotes.VFX.CreateTracer and type(Remotes.VFX.CreateTracer.Listen) == "function" then
    local okTr, unsubTr = pcall(Remotes.VFX.CreateTracer.Listen, function(data)
      if Unloaded or not ESP_ACTIVE() or type(data) ~= "table" then return end
      if typeof(data.Origin) == "Vector3" then onTracer(data.Origin) end
    end)
    if okTr and type(unsubTr) == "function" then table.insert(extraUnsubs, unsubTr) end
  end

  if Remotes.VFX and Remotes.VFX.CreateCharacterMuzzleFlash and type(Remotes.VFX.CreateCharacterMuzzleFlash.Listen) == "function" then
    local okFl, unsubFl = pcall(Remotes.VFX.CreateCharacterMuzzleFlash.Listen, function(data)
      if Unloaded or not ESP_ACTIVE() or type(data) ~= "table" then return end
      onMuzzleFlash(data)
    end)
    if okFl and type(unsubFl) == "function" then table.insert(extraUnsubs, unsubFl) end
  end

  if okSub and type(unsub) == "function" then table.insert(extraUnsubs, unsub) end
  if #extraUnsubs > 0 then
    SoundESPUnsub = function()
      for _, u in ipairs(extraUnsubs) do pcall(u) end
    end
  end
end

-- ============================================================================
-- RADAR, TELEMETRY HUD & CUSTOM CROSSHAIR
-- ============================================================================
local RadarFrame = Instance.new("Frame", ScreenGui)
RadarFrame.Name = "TacticalRadar"
RadarFrame.Size = UDim2.fromOffset(Config.RadarSize, Config.RadarSize)
RadarFrame.Position = UDim2.new(1, -170, 0, 70)
RadarFrame.BackgroundColor3 = T.SIDE
RadarFrame.BackgroundTransparency = 0.2
RadarFrame.BorderSizePixel = 0
RadarFrame.Visible = false
Instance.new("UICorner", RadarFrame).CornerRadius = UDim.new(1, 0)
local radStroke = Instance.new("UIStroke", RadarFrame); radStroke.Color = T.BORDER_HI; radStroke.Thickness = 1.2
local radH = Instance.new("Frame", RadarFrame); radH.Size = UDim2.new(1, -10, 0, 1); radH.Position = UDim2.new(0, 5, 0.5, 0); radH.BackgroundColor3 = T.BORDER; radH.BorderSizePixel = 0
local radV = Instance.new("Frame", RadarFrame); radV.Size = UDim2.new(0, 1, 1, -10); radV.Position = UDim2.new(0.5, 0, 0, 5); radV.BackgroundColor3 = T.BORDER; radV.BorderSizePixel = 0
local radDot = Instance.new("Frame", RadarFrame); radDot.Size = UDim2.fromOffset(5, 5); radDot.Position = UDim2.new(0.5, -2, 0.5, -2); radDot.BackgroundColor3 = T.TEXT; radDot.BorderSizePixel = 0
Instance.new("UICorner", radDot).CornerRadius = UDim.new(1, 0)
local RadarRangeLbl = Instance.new("TextLabel", RadarFrame)
RadarRangeLbl.Size = UDim2.fromOffset(60, 14); RadarRangeLbl.Position = UDim2.new(0.5, -30, 1, -16)
RadarRangeLbl.BackgroundTransparency = 1; RadarRangeLbl.Font = T.FONT; RadarRangeLbl.TextSize = 11
RadarRangeLbl.TextColor3 = T.TEXT_DIM; RadarRangeLbl.Text = Config.RadarRange .. "M"
makeDraggable(RadarFrame, RadarFrame)

local function getOrCreateRadarBlip(p)
  local blip = RadarBlips[p]
  if not blip then
    local f = Instance.new("Frame", RadarFrame)
    f.Size = UDim2.fromOffset(5, 5); f.AnchorPoint = Vector2.new(0.5, 0.5); f.BorderSizePixel = 0; f.Visible = false
    Instance.new("UICorner", f).CornerRadius = UDim.new(1, 0)
    RadarBlips[p] = f; blip = f
  end
  return blip
end

local TelemetryBar = Instance.new("Frame", ScreenGui)
TelemetryBar.Name = "TelemetryHUD"
TelemetryBar.AnchorPoint = Vector2.new(0.5, 1); TelemetryBar.Position = UDim2.new(0.5, 0, 1, -24); TelemetryBar.Size = UDim2.fromOffset(300, 30)
TelemetryBar.BackgroundColor3 = T.SIDE; TelemetryBar.BackgroundTransparency = 0.12; TelemetryBar.BorderSizePixel = 0; TelemetryBar.Visible = false
Instance.new("UICorner", TelemetryBar).CornerRadius = UDim.new(0, 5)
local teleStroke = Instance.new("UIStroke", TelemetryBar); teleStroke.Color = T.BORDER_HI; teleStroke.Thickness = 1
local teleAccent = Instance.new("Frame", TelemetryBar); teleAccent.Size = UDim2.new(1, 0, 0, 2); teleAccent.BackgroundColor3 = T.ACCENT; teleAccent.BorderSizePixel = 0
local TelemetryText = Instance.new("TextLabel", TelemetryBar); TelemetryText.Size = UDim2.fromScale(1, 1); TelemetryText.BackgroundTransparency = 1; TelemetryText.Font = T.FONT; TelemetryText.TextSize = 15; TelemetryText.TextColor3 = T.TEXT; TelemetryText.Text = ""
makeDraggable(TelemetryBar, TelemetryBar)

local CrosshairCenter = Instance.new("Frame", ScreenGui)
CrosshairCenter.Name = "CustomCrosshair"; CrosshairCenter.Size = UDim2.fromOffset(2, 2); CrosshairCenter.Position = UDim2.new(0.5, -1, 0.5, -1); CrosshairCenter.BackgroundTransparency = 1; CrosshairCenter.Visible = false
local CH_Dot    = Instance.new("Frame", CrosshairCenter); CH_Dot.Size = UDim2.fromOffset(3, 3); CH_Dot.Position = UDim2.fromOffset(-0.5, -0.5); CH_Dot.BorderSizePixel = 0; Instance.new("UICorner", CH_Dot).CornerRadius = UDim.new(1, 0)
local CH_Top    = Instance.new("Frame", CrosshairCenter); CH_Top.BorderSizePixel = 0
local CH_Bottom = Instance.new("Frame", CrosshairCenter); CH_Bottom.BorderSizePixel = 0
local CH_Left   = Instance.new("Frame", CrosshairCenter); CH_Left.BorderSizePixel = 0
local CH_Right  = Instance.new("Frame", CrosshairCenter); CH_Right.BorderSizePixel = 0

local function syncCrosshairVisuals()
  if not Config.CrosshairEnabled then
    CrosshairCenter.Visible = false
    return
  end
  CrosshairCenter.Visible = true
  local col = Config.CrosshairColor
  CH_Dot.BackgroundColor3 = col
  if Config.CrosshairStyle == "Dot" then
    CH_Dot.Visible = true; CH_Top.Visible = false; CH_Bottom.Visible = false; CH_Left.Visible = false; CH_Right.Visible = false
  else
    CH_Dot.Visible = true
    local sz, g = Config.CrosshairSize, Config.CrosshairGap
    CH_Top.BackgroundColor3 = col; CH_Bottom.BackgroundColor3 = col; CH_Left.BackgroundColor3 = col; CH_Right.BackgroundColor3 = col
    CH_Top.Size = UDim2.fromOffset(1, sz); CH_Top.Position = UDim2.fromOffset(0, -g - sz); CH_Top.Visible = true
    CH_Bottom.Size = UDim2.fromOffset(1, sz); CH_Bottom.Position = UDim2.fromOffset(0, g); CH_Bottom.Visible = true
    CH_Left.Size = UDim2.fromOffset(sz, 1); CH_Left.Position = UDim2.fromOffset(-g - sz, 0); CH_Left.Visible = true
    CH_Right.Size = UDim2.fromOffset(sz, 1); CH_Right.Position = UDim2.fromOffset(g, 0); CH_Right.Visible = true
  end
end

-- ============================================================================
-- EVENT-DRIVEN WORLD TAG CACHE & NO-SMOKE / NO-FLASH / LIGHTING
-- ============================================================================
local TrackedWorldItems = {}
local BombPlantedAt = nil

local function refreshWorldTagCache()
  if not (Config.ESPEnabled and (Config.BombESP or Config.WeaponDropESP or Config.BuyStationESP)) and not Config.BombTimerHUD then
    return
  end
  table.clear(TrackedWorldItems)
  local foundBomb = false
  for _, inst in ipairs(CollectionService:GetTagged("Bomb")) do
    if inst:IsDescendantOf(Workspace) then
      TrackedWorldItems[inst] = { Kind = "Bomb", Label = "[C4 BOMB]" }
      foundBomb = true
    end
  end
  if foundBomb and not BombPlantedAt then
    BombPlantedAt = os.clock()
  elseif not foundBomb then
    BombPlantedAt = nil
  end

  if Config.WeaponDropESP then
    for _, tag in ipairs({ "DroppedWeapon", "WeaponDropped" }) do
      for _, inst in ipairs(CollectionService:GetTagged(tag)) do
        if inst:IsDescendantOf(Workspace) then
          local wName = inst:GetAttribute("Weapon") or inst:GetAttribute("WeaponName") or inst.Name
          TrackedWorldItems[inst] = { Kind = "Weapon", Label = tostring(wName) }
        end
      end
    end
    local debris = Workspace:FindFirstChild("Debris")
    if debris then
      for _, d in ipairs(debris:GetChildren()) do
        if d:IsA("Model") and not TrackedWorldItems[d] and (d:GetAttribute("WeaponName") or d:GetAttribute("Weapon")) then
          TrackedWorldItems[d] = { Kind = "Weapon", Label = tostring(d:GetAttribute("WeaponName") or d:GetAttribute("Weapon")) }
        end
      end
    end
  end
  if Config.BuyStationESP then
    for _, tag in ipairs({ "BuyStation", "BuyStationRing" }) do
      for _, inst in ipairs(CollectionService:GetTagged(tag)) do
        if inst:IsDescendantOf(Workspace) and not TrackedWorldItems[inst] then
          TrackedWorldItems[inst] = { Kind = "BuyStation", Label = "[BUY STATION]" }
        end
      end
    end
  end
end

local function applySmokeInstance(d, hide)
  if d:IsA("ParticleEmitter") then
    if hide then
      if d:GetAttribute("_OrigEnabled") == nil then d:SetAttribute("_OrigEnabled", d.Enabled) end
      d.Enabled = false; d:Clear()
    else
      local o = d:GetAttribute("_OrigEnabled")
      if o ~= nil then d.Enabled = o; d:SetAttribute("_OrigEnabled", nil) end
    end
  elseif d:IsA("BasePart") then
    if hide then
      if d:GetAttribute("_OrigTrans") == nil then d:SetAttribute("_OrigTrans", d.Transparency) end
      if d.Transparency ~= 1 then d.Transparency = 1 end
    else
      local o = d:GetAttribute("_OrigTrans")
      if o ~= nil then d.Transparency = o; d:SetAttribute("_OrigTrans", nil) end
    end
  end
end

local function applySmokeFolderState(folder, hide)
  for _, d in ipairs(folder:GetDescendants()) do
    applySmokeInstance(d, hide)
  end
end

-- Event-driven smoke suppression (runs only on toggle change or Debris.ChildAdded)
local function enforceNoSmokeAll()
  local debris = Workspace:FindFirstChild("Debris")
  if not debris then return end
  for _, c in ipairs(debris:GetChildren()) do
    if string.sub(c.Name, 1, 11) == "VoxelSmoke_" then
      applySmokeFolderState(c, Config.NoSmoke)
    end
  end
end

local function enforceNoFlash()
  if not Config.NoFlash then return end
  if FlashEffect and FlashEffect.IsFlashed and FlashEffect.CancelFlash then
    local ok, flashed = callRestored(FlashEffect.IsFlashed)
    if ok and flashed then callRestored(FlashEffect.CancelFlash) end
  end
  local fg = PlayerGui:FindFirstChild("FlashbangEffect")
  if fg and fg.Enabled then fg.Enabled = false end
  local fs = PlayerGui:FindFirstChild("FlashScreenshot")
  if fs and fs.Enabled then fs.Enabled = false end
  local fcc = Lighting:FindFirstChild("FlashbangColorCorrection")
  if fcc and fcc:IsA("ColorCorrectionEffect") and fcc.Enabled then fcc.Enabled = false end
end

local function enforceScopeOverlay()
  local mg = PlayerGui:FindFirstChild("MainGui")
  local middle = mg and mg:FindFirstChild("Gameplay") and mg.Gameplay:FindFirstChild("Middle")
  local scope = middle and middle:FindFirstChild("SniperScope")
  if not scope then return end
  for _, c in ipairs(scope:GetChildren()) do
    if c:IsA("GuiObject") then
      if Config.NoScopeOverlay then
        if c:GetAttribute("_OrigImgT") == nil and (c:IsA("ImageLabel") or c:IsA("ImageButton")) then
          c:SetAttribute("_OrigImgT", c.ImageTransparency)
        end
        if c:GetAttribute("_OrigBgT") == nil then c:SetAttribute("_OrigBgT", c.BackgroundTransparency) end
        if c:IsA("ImageLabel") or c:IsA("ImageButton") then c.ImageTransparency = 1 end
        c.BackgroundTransparency = 1
      else
        local oi = c:GetAttribute("_OrigImgT")
        if oi ~= nil and (c:IsA("ImageLabel") or c:IsA("ImageButton")) then
          c.ImageTransparency = oi; c:SetAttribute("_OrigImgT", nil)
        end
        local ob = c:GetAttribute("_OrigBgT")
        if ob ~= nil then c.BackgroundTransparency = ob; c:SetAttribute("_OrigBgT", nil) end
      end
    end
  end
end

local TimeValues = { Dawn = 6.2, Noon = 12.5, Sunset = 18.2, Night = 1.0 }

-- Each lighting feature saves the CURRENT value the moment it is switched on and restores exactly that when it is
-- switched off. (Before, every toggle wrote back a snapshot taken at script start - which clobbered whatever the game
-- had changed since, e.g. round/map lighting - and a time-of-day reset every time ANY lighting toggle was touched.)
-- While a feature is active it is re-enforced from the slow tick, because the game rewrites Lighting between rounds.
local LightSaved = {}
local function setIfDiff(inst, prop, val)
  if inst[prop] ~= val then inst[prop] = val end
end
local function lightFeature(name, active, save, apply, restore)
  if active then
    if not LightSaved[name] then LightSaved[name] = save() end
    apply()
  elseif LightSaved[name] then
    restore(LightSaved[name])
    LightSaved[name] = nil
  end
end

local function lightingFeaturesActive()
  return Config.NoFog or Config.NoShadows or Config.Fullbright or (TimeValues[Config.TimePreset] ~= nil)
end

local function applyLightingState()
  local atmos = Lighting:FindFirstChildOfClass("Atmosphere")
  lightFeature("Fog", Config.NoFog,
    function() return { Start = Lighting.FogStart, End = Lighting.FogEnd, Density = atmos and atmos.Density, Haze = atmos and atmos.Haze } end,
    function()
      setIfDiff(Lighting, "FogEnd", 1e6); setIfDiff(Lighting, "FogStart", 1e6)
      if atmos then setIfDiff(atmos, "Density", 0); setIfDiff(atmos, "Haze", 0) end
    end,
    function(s)
      Lighting.FogStart = s.Start; Lighting.FogEnd = s.End
      local a = Lighting:FindFirstChildOfClass("Atmosphere")
      if a and s.Density ~= nil then a.Density = s.Density; a.Haze = s.Haze or 0 end
    end)
  lightFeature("Shadows", Config.NoShadows,
    function() return { GlobalShadows = Lighting.GlobalShadows } end,
    function() setIfDiff(Lighting, "GlobalShadows", false) end,
    function(s) Lighting.GlobalShadows = s.GlobalShadows end)
  lightFeature("Fullbright", Config.Fullbright,
    function() return { Brightness = Lighting.Brightness, Ambient = Lighting.Ambient, Outdoor = Lighting.OutdoorAmbient } end,
    function()
      setIfDiff(Lighting, "Brightness", 2.6)
      setIfDiff(Lighting, "Ambient", Color3.fromRGB(205, 205, 205))
      setIfDiff(Lighting, "OutdoorAmbient", Color3.fromRGB(215, 215, 215))
    end,
    function(s) Lighting.Brightness = s.Brightness; Lighting.Ambient = s.Ambient; Lighting.OutdoorAmbient = s.Outdoor end)
  lightFeature("Time", TimeValues[Config.TimePreset] ~= nil,
    function() return { ClockTime = Lighting.ClockTime } end,
    function() setIfDiff(Lighting, "ClockTime", TimeValues[Config.TimePreset]) end,
    function(s) Lighting.ClockTime = s.ClockTime end)
end

-- ============================================================================
-- FIXED THIRD PERSON MODE (Ray-Clipped Offset + Cached LTM/Viewmodel Restore)
-- ============================================================================
local OriginalVMPartProps = {}
local OriginalCharPartLTM = {}
local TPParts = { VM = {}, Body = {}, BuiltAt = 0, Char = nil }   -- cached part lists for third person (see stepThirdPersonVisuals)
local WasThirdPerson = false

local function restoreVMAndCharParts()
  TPParts.BuiltAt = 0
  table.clear(TPParts.VM); table.clear(TPParts.Body); TPParts.Char = nil
  for part, props in pairs(OriginalVMPartProps) do
    if part and part.Parent then
      part.Transparency = props.Transparency
      part.LocalTransparencyModifier = props.LTM
    end
  end
  table.clear(OriginalVMPartProps)

  for part, _ in pairs(OriginalCharPartLTM) do
    if part and part.Parent then
      part.LocalTransparencyModifier = 1
    end
  end
  table.clear(OriginalCharPartLTM)

  local myChar = getLocalCharacter()
  if myChar then
    for _, d in ipairs(myChar:GetDescendants()) do
      if d:IsA("BasePart") then d.LocalTransparencyModifier = 1 end
    end
  end
end

local function updateThirdPersonState(enabled)
  if not enabled then
    restoreVMAndCharParts()
    if CameraController and CameraController.setPerspective then
      callRestored(CameraController.setPerspective, true, false)
    end
    LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
    LocalPlayer.CameraMinZoomDistance = 0.5
    LocalPlayer.CameraMaxZoomDistance = 0.5
    WasThirdPerson = false
  end
end

local tpRayParams = RaycastParams.new()
tpRayParams.FilterType = Enum.RaycastFilterType.Exclude
tpRayParams.IgnoreWater = true

local function stepThirdPersonVisuals(cam)
  local isAlive = LocalPlayer:GetAttribute("Dead") ~= true
  local isSpec = LocalPlayer:GetAttribute("IsSpectating") == true
  local isScoped = LocalPlayer:GetAttribute("IsSniperScoped") == true or (tonumber(LocalPlayer:GetAttribute("ScopeIncrement")) or 0) > 0
  local active = Config.ThirdPerson and isAlive and not isSpec and not isScoped

  if active then
    WasThirdPerson = true
    local myChar = getLocalCharacter()
    local baseCF = cam.CFrame
    local dist = Config.ThirdPersonDist
    tpRayParams.FilterDescendantsInstances = { myChar, cam }
    local hit = Workspace:Raycast(baseCF.Position, -baseCF.LookVector * dist, tpRayParams)
    local finalDist = hit and math.max(1.2, (hit.Position - baseCF.Position).Magnitude - 0.6) or dist
    cam.CFrame = baseCF * CFrame.new(0, 0.5, finalDist)

    -- PERF: the part lists are cached and rebuilt every 0.4s (new viewmodels / respawns are picked up quickly);
    -- the per-frame work is just writing two properties. Before, GetDescendants() ran on the character and every
    -- viewmodel EVERY frame, which allocated large tables 60x per second.
    local nowTP = os.clock()
    if (nowTP - TPParts.BuiltAt) > 0.4 or TPParts.Char ~= myChar then
      table.clear(TPParts.VM); table.clear(TPParts.Body)
      for _, child in ipairs(cam:GetChildren()) do
        if child:IsA("Model") and child.Name ~= "ViewmodelStash" then
          for _, d in ipairs(child:GetDescendants()) do
            if d:IsA("BasePart") then table.insert(TPParts.VM, d) end
          end
        end
      end
      if myChar then
        for _, d in ipairs(myChar:GetDescendants()) do
          if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Name ~= "CameraPart" and d.Name ~= "Hitbox" and d.Name ~= "RootPart" and d.Name ~= "Insert" then
            table.insert(TPParts.Body, d)
          end
        end
      end
      TPParts.Char = myChar
      TPParts.BuiltAt = nowTP
    end
    for _, d in ipairs(TPParts.VM) do
      if d.Parent then
        if not OriginalVMPartProps[d] then
          OriginalVMPartProps[d] = { Transparency = d.Transparency, LTM = d.LocalTransparencyModifier }
        end
        if d.Transparency ~= 1 then d.Transparency = 1 end
        d.LocalTransparencyModifier = 1
      end
    end
    for _, d in ipairs(TPParts.Body) do
      if d.Parent then
        if OriginalCharPartLTM[d] == nil then
          OriginalCharPartLTM[d] = d.LocalTransparencyModifier
        end
        d.LocalTransparencyModifier = 0
      end
    end
  elseif WasThirdPerson then
    updateThirdPersonState(false)
  end
end

-- ============================================================================
-- INPUT LAYER + AUTO BUNNY HOP
-- Mouse/keyboard, GAMEPAD (triggers / bumpers / face buttons) and the game's on-screen TOUCH buttons all count as
-- "fire", "aim" and "jump". This device has no mouse or keyboard (touch + gamepad only), so everything that used
-- IsMouseButtonPressed / key checks (auto pistol, aimbot "Hold RMB", triggerbot modes) could never trigger.
-- ============================================================================
local MobileJumpHeld = false
local MobileHeld = { Fire = false, Aim = false }
local HookedMobileBtns = setmetatable({}, { __mode = "k" })
local InputX = {}

-- analog triggers report through the gamepad state (Position.Z), digital buttons through IsGamepadButtonDown
function InputX.padDown(code)
  for _, pad in ipairs(UserInputService:GetConnectedGamepads()) do
    if code == Enum.KeyCode.ButtonL2 or code == Enum.KeyCode.ButtonR2 then
      local okS, states = pcall(UserInputService.GetGamepadState, UserInputService, pad)
      if okS and type(states) == "table" then
        for _, st in ipairs(states) do
          if st.KeyCode == code and st.Position.Z > 0.35 then return true end
        end
      end
    end
    local okB, down = pcall(UserInputService.IsGamepadButtonDown, UserInputService, pad, code)
    if okB and down then return true end
  end
  return false
end
function InputX.fire()
  return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    or InputX.padDown(Enum.KeyCode.ButtonR2) or MobileHeld.Fire
end
function InputX.aim()
  return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    or InputX.padDown(Enum.KeyCode.ButtonL2) or MobileHeld.Aim
end
function InputX.jump()
  return UserInputService:IsKeyDown(Enum.KeyCode.Space) or InputX.padDown(Enum.KeyCode.ButtonA) or MobileJumpHeld
end

-- ---- Controller style: which button NAMES to show (Xbox vs PlayStation) ----
-- Roblox keycodes are Xbox-layout (ButtonX = Xbox X = PlayStation Square, ButtonL1 = LB = L1 ...). The labels used to be
-- PlayStation-style (L1/R1/L2/R2/L3/R3) for everyone, which looked like the suite had detected a DualSense.
-- Neither Roblox nor the executor exposes the controller MODEL, so detection combines every signal available and the
-- result can be overridden from the UI (the override is remembered in a small file).
InputX.PadNames = {
  Xbox = { ButtonL1 = "LB", ButtonR1 = "RB", ButtonL2 = "LT", ButtonR2 = "RT", ButtonL3 = "LS", ButtonR3 = "RS",
    ButtonA = "A", ButtonB = "B", ButtonX = "X", ButtonY = "Y", ButtonSelect = "VIEW", ButtonStart = "MENU" },
  PlayStation = { ButtonL1 = "L1", ButtonR1 = "R1", ButtonL2 = "L2", ButtonR2 = "R2", ButtonL3 = "L3", ButtonR3 = "R3",
    ButtonA = "CROSS", ButtonB = "CIRCLE", ButtonX = "SQUARE", ButtonY = "TRIANGLE", ButtonSelect = "SHARE", ButtonStart = "OPTIONS" },
}
InputX.StyleSetting = "Auto"          -- Auto | Xbox | PlayStation
InputX.Detected, InputX.DetectedWhy = "Xbox", "default"
InputX.StyleListeners = {}
InputX.StyleFile = "BloxStrikeSuite_PadStyle.txt"

function InputX.detect()
  -- 1) trigger rumble motors exist only on Xbox One / Series pads (not on DualSense through Roblox)
  local okH, trig = pcall(function()
    return game:GetService("HapticService"):IsMotorSupported(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.LeftTrigger)
  end)
  if okH and trig then return "Xbox", "trigger rumble motors (Xbox One/Series only)" end
  -- 2) the engine's own glyph set. It always answers "Xbox" while TOUCH is the active input, so it only counts as a
  --    real signal while a gamepad is the active input.
  if UserInputService:GetLastInputType().Name:find("Gamepad") then
    local okI, img = pcall(UserInputService.GetImageForKeyCode, UserInputService, Enum.KeyCode.ButtonA)
    img = okI and string.lower(tostring(img)) or ""
    if img:find("playstation") or img:find("dualsense") or img:find("dualshock") or img:find("ps4") or img:find("ps5") then
      return "PlayStation", "engine glyph set while the pad is active"
    end
    if img:find("xbox") then return "Xbox", "engine glyph set while the pad is active" end
  end
  return "Xbox", "no signal yet (Roblox exposes no controller model) - use CONTROLLER STYLE to override"
end

function InputX.padStyle()
  if InputX.StyleSetting == "Xbox" or InputX.StyleSetting == "PlayStation" then return InputX.StyleSetting end
  return InputX.Detected
end
function InputX.padName(code)
  local n = typeof(code) == "EnumItem" and code.Name or tostring(code)
  return (InputX.PadNames[InputX.padStyle()] or InputX.PadNames.Xbox)[n] or n
end
function InputX.refreshStyle()
  local before = InputX.padStyle()
  InputX.Detected, InputX.DetectedWhy = InputX.detect()
  if InputX.padStyle() ~= before then
    for _, fn in ipairs(InputX.StyleListeners) do pcall(fn) end
  end
end
function InputX.setStyle(setting)
  InputX.StyleSetting = setting
  if type(writefile) == "function" then pcall(writefile, InputX.StyleFile, setting) end
  for _, fn in ipairs(InputX.StyleListeners) do pcall(fn) end
end
do
  if type(readfile) == "function" and type(isfile) == "function" then
    local okE, exists = pcall(isfile, InputX.StyleFile)
    if okE and exists then
      local okR, saved = pcall(readfile, InputX.StyleFile)
      saved = okR and tostring(saved):gsub("%s", "") or ""
      if saved == "Xbox" or saved == "PlayStation" or saved == "Auto" then InputX.StyleSetting = saved end
    end
  end
  InputX.Detected, InputX.DetectedWhy = InputX.detect()
  trackConn(UserInputService.GamepadConnected:Connect(function() InputX.refreshStyle() end))
  trackConn(UserInputService.GamepadDisconnected:Connect(function() InputX.refreshStyle() end))
  trackConn(UserInputService.LastInputTypeChanged:Connect(function() InputX.refreshStyle() end))
end

local function hookHeldButton(btn, setHeld)
  if not btn or HookedMobileBtns[btn] or not btn:IsA("GuiObject") then return end
  HookedMobileBtns[btn] = true
  trackConn(btn.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
      setHeld(true)
      local chConn
      chConn = inp.Changed:Connect(function()
        if inp.UserInputState == Enum.UserInputState.End or inp.UserInputState == Enum.UserInputState.Cancel then
          setHeld(false)
          if chConn then chConn:Disconnect() end
        end
      end)
      trackConn(chConn)
    end
  end))
  trackConn(btn.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
      setHeld(false)
    end
  end))
end

-- MobileControlsGui.MobileButtons: Jump / Shoot / AlternativeAction (aim) - the buttons the game draws for touch players
local function bindMobileButtons()
  local mcg = PlayerGui:FindFirstChild("MobileControlsGui")
  if not mcg then return end
  local setters = {
    Jump = function(v) MobileJumpHeld = v end,
    Shoot = function(v) MobileHeld.Fire = v end,
    AlternativeAction = function(v) MobileHeld.Aim = v end,
  }
  for name, setter in pairs(setters) do
    hookHeldButton(mcg:FindFirstChild(name, true), setter)
  end
  trackConn(mcg.DescendantAdded:Connect(function(d)
    local s = setters[d.Name]
    if s then hookHeldButton(d, s) end
  end))
end
bindMobileButtons()
trackConn(PlayerGui.ChildAdded:Connect(function(c)
  if c.Name == "MobileControlsGui" then task.defer(bindMobileButtons) end
end))

local BhopWasAirborne = false
local BhopLastLandJumpAt = 0
local function updateAutoBhop()
  if not Config.AutoBhop or not LocalCharacterMod or not RuntimeKinematics then return end
  if Workspace:GetAttribute("GameState") == "Buy Period" then return end
  if LocalPlayer:GetAttribute("Dead") == true then return end

  local jumpHeld = InputX.jump()
  local char = getLocalCharacter()
  if not char then return end

  if not jumpHeld then
    if BhopWasAirborne then
      BhopWasAirborne = false
      BhopLastLandJumpAt = 0
      callRestored(LocalCharacterMod.jump, false)
    end
    return
  end

  local okG, onGround = callRestored(RuntimeKinematics.isOnGround, char)
  if not okG then return end

  if not onGround then
    BhopWasAirborne = true
    BhopLastLandJumpAt = 0
    callRestored(LocalCharacterMod.jump, false)
  else
    local now = os.clock()
    if BhopWasAirborne or (now - BhopLastLandJumpAt >= 0.12) then
      BhopWasAirborne = false
      BhopLastLandJumpAt = now
      callRestored(LocalCharacterMod.jump, nil)
      callRestored(LocalCharacterMod.jump, true)
    end
  end
end

-- ============================================================================
-- FX MODULES: bullet tracers / grenade visualizer / graphics (lighting, weather, foliage sway, FPS boost)
-- Each module lives in its own function scope: the main chunk is at Luau's 200-local limit.
-- ============================================================================
local FX = { Unload = {} }

-- ----------------------------------------------------------------------------
-- BULLET TRACERS  (moved here from the skin changer; hooks the game's real shot + tracer events)
--   * other players: Remotes.VFX.CreateTracer {Origin, Target}
--   * your own shots: the BulletMod._performRaycast hook in the combat engine calls FX.Tracers.onLocalShot
-- ----------------------------------------------------------------------------
;(function()
  Config.TracersEnabled = false
  Config.TracerScope = "All"            -- All | Mine | Others
  Config.TracerStyle = "Laser"
  Config.TracerColorName = "Cyan"       -- any palette colour | Rainbow
  Config.TracerWidth = 0.14
  Config.TracerLife = 0.6
  Config.TracerImpact = true

  local Terrain = Workspace.Terrain
  local Folder = Instance.new("Folder")
  Folder.Name = "BloxStrikeTracers"
  Folder.Parent = Workspace

  local TEX = {
    smoke = "rbxasset://textures/particles/smoke_main.dds", sparkle = "rbxasset://textures/particles/sparkles_main.dds",
    fire = "rbxasset://textures/particles/fire_main.dds", spark = "rbxasset://textures/particles/fire_sparks_main.dds",
  }
  local rnd = math.random
  local WHITE, BLACK = Color3.new(1, 1, 1), Color3.new(0, 0, 0)
  local Active, STYLES, totalBeams = {}, {}, 0

  local function att(pos)
    local a = Instance.new("Attachment")
    a.Parent = Terrain
    a.WorldPosition = pos
    return a
  end
  local function beam(a0, a1, color, w0, w1, trans)
    local b = Instance.new("Beam")
    b.Attachment0 = a0; b.Attachment1 = a1
    b.Color = typeof(color) == "ColorSequence" and color or ColorSequence.new(color)
    b.Width0 = w0; b.Width1 = w1 or w0
    b.LightEmission = 1; b.LightInfluence = 0; b.FaceCamera = true; b.Segments = 1
    b.Transparency = NumberSequence.new(trans or 0)
    b.Parent = Folder
    return b
  end
  local function newPart(size)
    local p = Instance.new("Part")
    p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
    p.Size = size
    p.Parent = Folder
    return p
  end
  local function neonBall(pos, size, color)
    local p = newPart(Vector3.new(size, size, size))
    p.Material = Enum.Material.Neon; p.Shape = Enum.PartType.Ball; p.Color = color; p.Position = pos
    return p
  end
  -- invisible bar laid along the shot: emitters parented to it fill the whole length of the tracer
  local function emitterBar(a, b, thickness)
    local p = newPart(Vector3.new(thickness, thickness, math.max((b - a).Magnitude, 0.5)))
    p.Transparency = 1
    p.CFrame = CFrame.lookAt((a + b) / 2, b)
    return p
  end
  local function emitter(parent, tex, color, size, life, rate, speed, spread, emission)
    local e = Instance.new("ParticleEmitter")
    e.Texture = TEX[tex]; e.Color = color; e.Size = size
    e.Lifetime = NumberRange.new(life[1], life[2]); e.Rate = rate
    e.Speed = NumberRange.new(speed[1], speed[2]); e.SpreadAngle = Vector2.new(spread, spread)
    e.LightEmission = emission; e.LightInfluence = 0
    e.Rotation = NumberRange.new(0, 360); e.RotSpeed = NumberRange.new(-90, 90)
    e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
    e.Parent = parent
    return e
  end
  local function seq(keys)   -- ColorSequence from evenly spaced colours
    local n = #keys
    local kps = {}
    for i, c in ipairs(keys) do kps[i] = ColorSequenceKeypoint.new(n == 1 and 0 or (i - 1) / (n - 1), c) end
    if n == 1 then kps[2] = ColorSequenceKeypoint.new(1, keys[1]) end
    return ColorSequence.new(kps)
  end
  local function rainbowSeq(offset)
    local kps = {}
    for i = 0, 5 do kps[#kps + 1] = ColorSequenceKeypoint.new(i / 5, Color3.fromHSV((offset + i / 5 * 0.85) % 1, 0.85, 1)) end
    return ColorSequence.new(kps)
  end
  local function basis(a, b)
    local dir = (b - a).Unit
    local right = dir:Cross(Vector3.yAxis)
    if right.Magnitude < 0.05 then right = dir:Cross(Vector3.xAxis) end
    right = right.Unit
    return dir, right, right:Cross(dir)
  end

  -- ---------------------------------------------------------------- styles
  -- each style: (a, b, color, width, life) -> entry { objs, beams = {{beam, baseTransparency}}, update?(alpha, now), cost }
  STYLES["Laser"] = function(a, b, col, w)
    local a0, a1 = att(a), att(b)
    local core = beam(a0, a1, WHITE:Lerp(col, 0.4), w * 0.5)
    local glow = beam(a0, a1, col, w * 2.4, nil, 0.55)
    return { objs = { a0, a1, core, glow }, beams = { { core, 0 }, { glow, 0.55 } }, cost = 2 }
  end

  STYLES["Needle"] = function(a, b, col, w)
    local a0, a1 = att(a), att(b)
    local core = beam(a0, a1, WHITE:Lerp(col, 0.25), w * 0.28)
    return { objs = { a0, a1, core }, beams = { { core, 0 } }, cost = 1 }
  end

  local function bolts(a, b, col, w, count, ampBase)
    local len = (b - a).Magnitude
    local segs = math.clamp(math.floor(len / 6), 6, count > 1 and 12 or 18)
    local dir, right, up = basis(a, b)
    local e = { objs = {}, beams = {}, cost = 0 }
    local all = {}
    for k = 1, count do
      local bolt = { atts = {}, amp = ampBase + (k - 1) * 0.55 }
      for i = 0, segs do
        local at = att(a)
        bolt.atts[i] = at
        e.objs[#e.objs + 1] = at
      end
      for i = 0, segs - 1 do
        local core = beam(bolt.atts[i], bolt.atts[i + 1], WHITE:Lerp(col, 0.3), w * 0.45)
        local glow = beam(bolt.atts[i], bolt.atts[i + 1], col, w * 1.8, nil, 0.6)
        e.objs[#e.objs + 1] = core; e.objs[#e.objs + 1] = glow
        e.beams[#e.beams + 1] = { core, 0 }; e.beams[#e.beams + 1] = { glow, 0.6 }
        e.cost += 2
      end
      all[k] = bolt
    end
    local function jitter()
      for _, bolt in ipairs(all) do
        for i = 0, segs do
          local t = i / segs
          local p = a + dir * (len * t)
          if i > 0 and i < segs then
            local f = bolt.amp * math.sin(t * math.pi) * math.min(1, len / 45 + 0.4)
            p = p + right * ((rnd() - 0.5) * 2 * f) + up * ((rnd() - 0.5) * 2 * f)
          end
          bolt.atts[i].WorldPosition = p
        end
      end
    end
    jitter()
    local last = 0
    e.update = function(_, now)
      if now - last > 0.045 then last = now; jitter() end
    end
    return e
  end
  STYLES["Lightning"] = function(a, b, col, w) return bolts(a, b, col, w, 1, 1.2) end
  STYLES["Tesla"] = function(a, b, col, w) return bolts(a, b, col, w, 2, 1.0) end

  local function headWithTrail(a, b, col, size, trailLife, travelDiv, sparkles)
    local head = neonBall(a, size, col)
    local t0, t1 = Instance.new("Attachment"), Instance.new("Attachment")
    t0.Position = Vector3.new(0, size * 0.32, 0); t1.Position = Vector3.new(0, -size * 0.32, 0)
    t0.Parent = head; t1.Parent = head
    local tr = Instance.new("Trail")
    tr.Attachment0 = t0; tr.Attachment1 = t1; tr.Lifetime = trailLife
    tr.Color = ColorSequence.new(col, col:Lerp(BLACK, 0.65)); tr.LightEmission = 1
    tr.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
    tr.MinLength = 0.05; tr.Parent = head
    if sparkles then
      emitter(head, "sparkle", ColorSequence.new(col), NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) }), { 0.25, 0.5 }, 70, { 1, 3 }, 180, 1)
    end
    local travel = math.clamp((b - a).Magnitude / travelDiv, 0.06, 0.45)
    local e = { objs = { head }, beams = {}, cost = 2 }
    e.update = function(_, now)
      local k = math.min(1, (now - e.t0) / travel)
      head.Position = a:Lerp(b, k)
      if k >= 1 then head.Transparency = 1; tr.Enabled = false end
    end
    return e
  end
  STYLES["Plasma Bolt"] = function(a, b, col, w)
    local e = headWithTrail(a, b, col, math.max(0.55, w * 4.5), 0.3, 320, false)
    local a0, a1 = att(a), att(b)
    local faint = beam(a0, a1, col, w * 0.3, nil, 0.7)
    e.objs[#e.objs + 1] = a0; e.objs[#e.objs + 1] = a1; e.objs[#e.objs + 1] = faint
    e.beams[#e.beams + 1] = { faint, 0.7 }
    return e
  end
  STYLES["Comet"] = function(a, b, col, w)
    return headWithTrail(a, b, col, math.max(0.3, w * 2.2), 0.55, 420, true)
  end

  STYLES["Rainbow"] = function(a, b, _, w)
    local a0, a1 = att(a), att(b)
    local bm = beam(a0, a1, rainbowSeq(0), w * 1.2)
    local e = { objs = { a0, a1, bm }, beams = { { bm, 0 } }, cost = 1 }
    e.update = function(_, now) bm.Color = rainbowSeq(now * 0.8) end
    return e
  end

  STYLES["DNA Helix"] = function(a, b, col, w)
    local len = (b - a).Magnitude
    local dir, right, up = basis(a, b)
    local n = math.clamp(math.floor(len / 1.8), 12, 40)
    local strands, e = { {}, {} }, { objs = {}, beams = {}, cost = 0 }
    local cols = { col, col:Lerp(WHITE, 0.55) }
    for s = 1, 2 do
      for i = 0, n do local at = att(a); strands[s][i] = at; e.objs[#e.objs + 1] = at end
      for i = 0, n - 1 do
        local bm = beam(strands[s][i], strands[s][i + 1], cols[s], w * 0.9)
        e.objs[#e.objs + 1] = bm; e.beams[#e.beams + 1] = { bm, 0 }; e.cost += 1
      end
    end
    for i = 2, n - 2, 4 do   -- rungs
      local bm = beam(strands[1][i], strands[2][i], WHITE, w * 0.32, nil, 0.45)
      e.objs[#e.objs + 1] = bm; e.beams[#e.beams + 1] = { bm, 0.45 }; e.cost += 1
    end
    local function place(phase)
      for s = 1, 2 do
        for i = 0, n do
          local t = i / n
          local ang = t * len * 0.9 + phase + (s - 1) * math.pi
          local ease = math.min(1, i / 3, (n - i) / 3)
          strands[s][i].WorldPosition = a + dir * (len * t) + (right * math.cos(ang) + up * math.sin(ang)) * 0.5 * ease
        end
      end
    end
    place(0)
    e.update = function(_, now) place(now * 9) end
    return e
  end

  STYLES["Pulse Rings"] = function(a, b, col, w, life)
    local len = (b - a).Magnitude
    local dir = (b - a).Unit
    local count = math.clamp(math.floor(len / 5), 4, 22)
    local e = { objs = {}, beams = {}, cost = count // 3 + 1 }
    local rings = {}
    for i = 1, count do
      local p = newPart(Vector3.new(0.06, 1, 1))
      p.Shape = Enum.PartType.Cylinder; p.Material = Enum.Material.Neon; p.Color = col; p.Transparency = 1
      local pos = a + dir * (len * i / (count + 1))
      p.CFrame = CFrame.lookAt(pos, pos + dir) * CFrame.Angles(0, math.rad(90), 0)   -- cylinder axis (X) along the shot
      e.objs[#e.objs + 1] = p
      rings[i] = { part = p, delay = i * 0.012 }
    end
    e.update = function(_, now)
      for _, r in ipairs(rings) do
        local la = math.clamp((now - e.t0 - r.delay) / (life * 0.85), 0, 1)
        if la <= 0 or la >= 1 then
          r.part.Transparency = 1
        else
          local d = 0.6 + la * 2.6 * math.max(w * 5, 0.8)
          r.part.Size = Vector3.new(0.06, d, d)
          r.part.Transparency = la
        end
      end
    end
    return e
  end

  local function barStyle(a, b, beamCol, w, emitters, stopAfter)
    local len = (b - a).Magnitude
    local bar = emitterBar(a, b, 0.35)
    local rate = math.clamp(len * 5, 70, 520)
    local ems = {}
    for _, spec in ipairs(emitters) do
      ems[#ems + 1] = emitter(bar, spec.tex, spec.color, spec.size, spec.life, rate * spec.k, spec.speed, spec.spread, spec.emission)
    end
    local a0, a1 = att(a), att(b)
    local bm = beam(a0, a1, beamCol, w * 0.8, nil, 0.3)
    local e = { objs = { bar, a0, a1, bm }, beams = { { bm, 0.3 } }, cost = 2 }
    e.update = function(alpha)
      if alpha > stopAfter then for _, em in ipairs(ems) do em.Enabled = false end end
    end
    return e
  end
  local function ramp(a0, a1) return NumberSequence.new({ NumberSequenceKeypoint.new(0, a0), NumberSequenceKeypoint.new(1, a1) }) end
  STYLES["Fire Streak"] = function(a, b, _, w)
    return barStyle(a, b, Color3.fromRGB(255, 140, 30), w, {
      { tex = "fire", color = seq({ Color3.fromRGB(255, 235, 110), Color3.fromRGB(255, 100, 0), Color3.fromRGB(90, 0, 0) }), size = ramp(0.7, 0.1), life = { 0.3, 0.6 }, k = 1, speed = { 0.5, 1.5 }, spread = 25, emission = 1 },
      { tex = "spark", color = seq({ Color3.fromRGB(255, 220, 120), Color3.fromRGB(255, 80, 10) }), size = ramp(0.14, 0), life = { 0.4, 0.9 }, k = 0.4, speed = { 1.5, 4 }, spread = 70, emission = 1 },
    }, 0.3)
  end
  STYLES["Frost Streak"] = function(a, b, _, w)
    return barStyle(a, b, Color3.fromRGB(160, 220, 255), w, {
      { tex = "smoke", color = seq({ Color3.fromRGB(235, 248, 255), Color3.fromRGB(150, 205, 255) }), size = ramp(0.5, 1.5), life = { 0.5, 1 }, k = 0.6, speed = { 0.2, 0.8 }, spread = 30, emission = 0.4 },
      { tex = "sparkle", color = seq({ WHITE, Color3.fromRGB(170, 225, 255) }), size = ramp(0.2, 0), life = { 0.5, 1.1 }, k = 0.6, speed = { 0.3, 1.2 }, spread = 180, emission = 1 },
    }, 0.3)
  end
  STYLES["Void Ray"] = function(a, b, _, w)
    local e = barStyle(a, b, Color3.fromRGB(150, 50, 255), w * 1.2, {
      { tex = "smoke", color = seq({ Color3.fromRGB(100, 20, 180), Color3.fromRGB(20, 0, 40) }), size = ramp(0.6, 1.4), life = { 0.5, 1 }, k = 0.6, speed = { 0.2, 0.9 }, spread = 40, emission = 0 },
      { tex = "sparkle", color = seq({ Color3.fromRGB(210, 140, 255), Color3.fromRGB(110, 40, 200) }), size = ramp(0.2, 0), life = { 0.4, 0.9 }, k = 0.5, speed = { 0.5, 2 }, spread = 180, emission = 1 },
    }, 0.3)
    return e
  end
  STYLES["Golden Sparks"] = function(a, b, _, w)
    return barStyle(a, b, Color3.fromRGB(255, 215, 90), w, {
      { tex = "sparkle", color = seq({ Color3.fromRGB(255, 250, 200), Color3.fromRGB(255, 200, 60) }), size = ramp(0.3, 0), life = { 0.5, 1.1 }, k = 0.9, speed = { 0.4, 1.6 }, spread = 120, emission = 1 },
    }, 0.35)
  end

  STYLES["Glitch"] = function(a, b, col, w)
    local len = (b - a).Magnitude
    local dir, right, up = basis(a, b)
    local n = 12
    local at, e = {}, { objs = {}, beams = {}, cost = n }
    for i = 0, n do at[i] = att(a); e.objs[#e.objs + 1] = at[i] end
    local bms = {}
    for i = 0, n - 1 do
      bms[i] = beam(at[i], at[i + 1], col, w * 0.7)
      e.objs[#e.objs + 1] = bms[i]; e.beams[#e.beams + 1] = { bms[i], 0 }
    end
    local palette = { col, Color3.fromRGB(255, 0, 200), Color3.fromRGB(0, 255, 230), WHITE }
    e.update = function()
      for i = 0, n do
        local t = i / n
        local p = a + dir * (len * t)
        if i > 0 and i < n then
          local big = rnd() < 0.18 and 2.2 or 0.35
          p = p + right * ((rnd() - 0.5) * 2 * big) + up * ((rnd() - 0.5) * 2 * big)
        end
        at[i].WorldPosition = p
      end
      for i = 0, n - 1 do bms[i].Color = ColorSequence.new(palette[rnd(1, #palette)]) end
    end
    return e
  end

  FX.TracerStyles = { "Laser", "Needle", "Lightning", "Tesla", "Plasma Bolt", "Comet", "Rainbow", "DNA Helix", "Pulse Rings", "Fire Streak", "Frost Streak", "Void Ray", "Golden Sparks", "Glitch" }

  -- ---------------------------------------------------------------- runtime
  local function destroyEntry(e)
    totalBeams -= (e.cost or 0)
    for _, o in ipairs(e.objs) do pcall(function() o:Destroy() end) end
  end

  local function register(e)
    e.t0 = os.clock()
    e.cost = e.cost or 1
    totalBeams += e.cost
    table.insert(Active, e)
    -- hard budget so a minigun with a heavy style can never tank the frame rate
    while (#Active > 30 or totalBeams > 420) and #Active > 1 do
      destroyEntry(table.remove(Active, 1))
    end
  end

  local function pickColor()
    local n = Config.TracerColorName
    if n == "Rainbow" then return Color3.fromHSV((os.clock() * 0.6) % 1, 0.85, 1) end
    return ColorPalette[n] or ColorPalette.Cyan
  end

  local function impact(pos, col)
    local p = newPart(Vector3.new(0.2, 0.2, 0.2))
    p.Transparency = 1; p.Position = pos
    local e = emitter(p, "sparkle", ColorSequence.new(col), ramp(0.45, 0), { 0.25, 0.6 }, 0, { 3, 9 }, 180, 1)
    e:Emit(12)
    local flash = neonBall(pos, 0.7, col)
    task.delay(0.12, function() pcall(function() flash:Destroy() end) end)
    task.delay(1, function() pcall(function() p:Destroy() end) end)
  end

  local lastLocalAt = 0
  local function spawnTracer(a, b, mine)
    if not Config.TracersEnabled or Unloaded then return end
    local scope = Config.TracerScope
    if (scope == "Mine" and not mine) or (scope == "Others" and mine) then return end
    if (b - a).Magnitude < 2 then return end
    local style = STYLES[Config.TracerStyle] or STYLES["Laser"]
    local col = pickColor()
    local life = Config.TracerLife
    local ok, e = pcall(style, a, b, col, Config.TracerWidth, life)
    if not ok or not e then
      warn("[BloxStrikeSuite] tracer style failed: " .. tostring(e))
      return
    end
    e.life = life
    register(e)
    if Config.TracerImpact then pcall(impact, b, col) end
  end

  local function muzzlePosition()
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    for _, ch in ipairs(cam:GetChildren()) do
      if ch:IsA("Model") and ch.Name ~= "ViewmodelStash" then
        local w = ch:FindFirstChild("Weapon")
        local m = w and w:FindFirstChild("MuzzlePart", true)
        if m and m:IsA("BasePart") then return m.Position end
      end
    end
    return cam.CFrame.Position + cam.CFrame.LookVector * 1.2 + cam.CFrame.RightVector * 0.35 - cam.CFrame.UpVector * 0.3
  end

  local Tracers = {}
  function Tracers.spawn(a, b, mine) spawnTracer(a, b, mine) end
  -- res = what the game's Bullet:_performRaycast returned: { Origin, Direction, Hits?, Distance? }
  function Tracers.onLocalShot(res)
    if not Config.TracersEnabled or type(res) ~= "table" or typeof(res.Origin) ~= "Vector3" or typeof(res.Direction) ~= "Vector3" then return end
    local dir = res.Direction.Magnitude > 0 and res.Direction.Unit or nil
    if not dir then return end
    local target
    if type(res.Hits) == "table" and res.Hits[1] and typeof(res.Hits[1].Position) == "Vector3" then
      target = res.Hits[1].Position
    else
      target = res.Origin + dir * math.min(tonumber(res.Distance) or 300, 400)
    end
    lastLocalAt = os.clock()
    spawnTracer(muzzlePosition() or res.Origin, target, true)
  end
  FX.Tracers = Tracers

  -- other players' shots
  local unsub
  if Remotes and Remotes.VFX and Remotes.VFX.CreateTracer and type(Remotes.VFX.CreateTracer.Listen) == "function" then
    local ok, un = pcall(Remotes.VFX.CreateTracer.Listen, function(data)
      if Unloaded or not Config.TracersEnabled or type(data) ~= "table" then return end
      if typeof(data.Origin) ~= "Vector3" then return end
      local cam = Workspace.CurrentCamera
      local nearMe = cam and (data.Origin - cam.CFrame.Position).Magnitude < 6
      -- if our own shot already drew a tracer a moment ago, don't draw the server echo a second time
      if nearMe and os.clock() - lastLocalAt < 0.4 then return end
      local target = typeof(data.Target) == "Vector3" and data.Target
        or (data.Origin + (typeof(data.Direction) == "Vector3" and data.Direction.Unit or Vector3.zero) * math.min(tonumber(data.Distance) or 200, 400))
      spawnTracer(data.Origin, target, nearMe == true)
    end)
    if ok and type(un) == "function" then unsub = un end
  end

  local conn = RunService.RenderStepped:Connect(function()
    local now = os.clock()
    for i = #Active, 1, -1 do
      local e = Active[i]
      local alpha = (now - e.t0) / e.life
      if alpha >= 1 then
        destroyEntry(e)
        table.remove(Active, i)
      else
        if e.update then pcall(e.update, alpha, now) end
        local fade = alpha * alpha
        for _, bt in ipairs(e.beams or {}) do
          bt[1].Transparency = NumberSequence.new(bt[2] + (1 - bt[2]) * fade)
        end
      end
    end
  end)

  table.insert(FX.Unload, function()
    conn:Disconnect()
    if unsub then pcall(unsub) end
    for _, e in ipairs(Active) do pcall(destroyEntry, e) end
    table.clear(Active)
    pcall(function() Folder:Destroy() end)
    FX.Tracers = nil
  end)
end)()


-- ----------------------------------------------------------------------------
-- WORLD FX: gradient chams, on-hit ghost chams, kill effects, damage numbers, impact effects, sound ripples,
-- crosshair ring, night vision / thermal, sun position and lightning storm.
-- Everything is built from Parts / Highlights / ParticleEmitters (textures that are known to load on this device) and is
-- removed again on unload. Events used (all verified live):
--   Remotes.UI.UIPlayerKilled  {Victim, Killer, DeathPosition, Headshot, Wallbang, Weapon}
--   Remotes.VFX.CreateImpact   {AttackerUserId, Position, Instance, Material, Exit, WasHelmetHeadshot, IsWallbang}
--   Remotes.Sound.ReplicateSound {Position, Class, Name}
-- ----------------------------------------------------------------------------
;(function()
  Config.ChamGradient = "Off"; Config.ChamGradAnim = "Flow Up"; Config.ChamGradSpeed = "Normal"
  Config.HitGhosts = false; Config.GhostStyle = "Sunset"; Config.GhostMaterial = "Neon"; Config.GhostLife = 0.8
  Config.GhostWalls = true; Config.GhostOrb = true
  Config.KillFX = "Off"; Config.KillFXWho = "Mine"; Config.KillFXHeadOnly = false; Config.KillBanner = false; Config.KillFlash = false
  Config.DamageNumbers = false; Config.ImpactFX = "Off"
  Config.CrossRing = false; Config.CrossOnTarget = false
  Config.VisionMode = "Off"; Config.SoundRipples = false; Config.RippleScope = "All"
  Config.SunClock = "Default"; Config.Storm = false; Config.StormFreq = "Normal"

  local C3 = Color3.fromRGB
  local WHITE = Color3.new(1, 1, 1)
  local PAL = { C3(255, 80, 80), C3(255, 170, 40), C3(255, 235, 70), C3(90, 235, 110), C3(70, 190, 255), C3(190, 110, 255), C3(255, 110, 200) }
  local TEX_SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
  local TEX_SPARK = "rbxasset://textures/particles/fire_sparks_main.dds"
  local TEX_SMOKE = "rbxasset://textures/particles/smoke_main.dds"

  -- ---------------------------------------------------------------- gradients
  local GRADS = {
    Sunset = { C3(255, 60, 100), C3(255, 150, 50), C3(255, 225, 110) },
    Ocean = { C3(0, 60, 200), C3(0, 190, 255), C3(150, 255, 240) },
    Toxic = { C3(20, 120, 30), C3(30, 210, 0), C3(200, 255, 0) },
    Fire = { C3(140, 0, 0), C3(255, 70, 0), C3(255, 225, 60) },
    Ice = { C3(80, 140, 255), C3(190, 240, 255), C3(255, 255, 255) },
    Candy = { C3(255, 80, 200), C3(120, 120, 255), C3(80, 255, 230) },
    Galaxy = { C3(60, 0, 140), C3(180, 40, 255), C3(40, 120, 255) },
    Gold = { C3(170, 110, 10), C3(255, 200, 40), C3(255, 245, 170) },
  }
  local GRAD_NAMES = { "Sunset", "Ocean", "Toxic", "Fire", "Ice", "Candy", "Galaxy", "Gold", "Rainbow", "Chams Color" }
  local function gradColor(name, t, base)
    t = math.clamp(t, 0, 1)
    if name == "Rainbow" then return Color3.fromHSV(t * 0.92, 0.85, 1) end
    if name == "Chams Color" then return (base or C3(255, 60, 60)):Lerp(WHITE, t) end
    local list = GRADS[name]
    if not list then return base or WHITE end
    local n = #list
    local x = t * (n - 1)
    local i = math.floor(x)
    if i >= n - 1 then return list[n] end
    return list[i + 1]:Lerp(list[i + 2], x - i)
  end
  -- cyclic (ping-pong) sampling, used by animated gradients
  local function gradLoop(name, t, base)
    t = t % 1
    if name == "Rainbow" then return Color3.fromHSV(t, 0.85, 1) end
    return gradColor(name, t < 0.5 and t * 2 or (1 - t) * 2, base)
  end

  -- ---------------------------------------------------------------- scene helpers
  local Folder = Instance.new("Folder")
  Folder.Name = "BS_FX"
  Folder.Parent = Workspace
  local Active = {}

  local function newBox(name)
    local b = Instance.new("Folder")
    b.Name = name or "fx"
    b.Parent = Folder
    return b
  end
  local function run(box, fn)
    if #Active > 60 then
      local old = table.remove(Active, 1)
      pcall(function() old.box:Destroy() end)
    end
    Active[#Active + 1] = { box = box, fn = fn, born = os.clock() }
  end
  local function mkPart(parent, size, color, shape, material, transp)
    local p = Instance.new("Part")
    p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
    p.Size = size; p.Color = color or WHITE; p.Material = material or Enum.Material.Neon; p.Transparency = transp or 0
    if shape then p.Shape = shape end
    p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
  end
  local function rnd(a, b) return a + math.random() * (b - a) end
  local function kp(t, v) return NumberSequenceKeypoint.new(t, v) end

  local function burst(parent, pos, tex, color, count, smin, smax, life, sizeA, sizeB, accel)
    local p = mkPart(parent, Vector3.new(0.2, 0.2, 0.2), WHITE, nil, nil, 1)
    p.Position = pos
    local e = Instance.new("ParticleEmitter")
    e.Texture = tex; e.Rate = 0
    e.Lifetime = NumberRange.new(life * 0.6, life)
    e.Speed = NumberRange.new(smin, smax)
    e.SpreadAngle = Vector2.new(180, 180)
    e.Size = NumberSequence.new(sizeA, sizeB)
    e.Color = type(color) == "userdata" and typeof(color) == "ColorSequence" and color or ColorSequence.new(color)
    e.LightEmission = 1
    e.Transparency = NumberSequence.new({ kp(0, 0), kp(0.7, 0.25), kp(1, 1) })
    e.Acceleration = accel or Vector3.new(0, -20, 0)
    e.Rotation = NumberRange.new(0, 360)
    e.Parent = p
    e:Emit(count)
    return p
  end

  local GroundParams = RaycastParams.new()
  GroundParams.FilterType = Enum.RaycastFilterType.Exclude
  GroundParams.RespectCanCollide = false
  local function refreshGroundParams()
    local ex = { Folder }
    local chars = Workspace:FindFirstChild("Characters")
    if chars then ex[#ex + 1] = chars end
    local deb = Workspace:FindFirstChild("Debris")
    if deb then ex[#ex + 1] = deb end
    if Workspace.CurrentCamera then ex[#ex + 1] = Workspace.CurrentCamera end
    GroundParams.FilterDescendantsInstances = ex
  end
  refreshGroundParams()
  local function groundAt(pos)
    local r = Workspace:Raycast(pos + Vector3.new(0, 3, 0), Vector3.new(0, -16, 0), GroundParams)
    if r then return r.Position + Vector3.new(0, 0.12, 0), r.Normal end
    return pos - Vector3.new(0, 2.7, 0), Vector3.new(0, 1, 0)
  end

  -- ---------------------------------------------------------------- screen flash (own ColorCorrection)
  local Flash = Instance.new("ColorCorrectionEffect")
  Flash.Name = "BS_Flash"; Flash.Enabled = false; Flash.Parent = Lighting
  local flashAmt, flashTint = 0, WHITE
  local function flash(amount, tint)
    flashAmt = math.max(flashAmt, amount)
    flashTint = tint or WHITE
  end

  -- ---------------------------------------------------------------- flat ring on a surface (SurfaceGui circle)
  local function ringFx(pos, color, maxSize, life, thick, normal)
    local box = newBox("ring")
    local p = mkPart(box, Vector3.new(1, 0.05, 1), WHITE, nil, Enum.Material.SmoothPlastic, 1)
    if normal and normal.Magnitude > 0.1 and normal.Unit.Y < 0.97 then
      p.CFrame = CFrame.lookAt(pos, pos + normal.Unit) * CFrame.Angles(-math.pi / 2, 0, 0)
    else
      p.CFrame = CFrame.new(pos)
    end
    local base = p.CFrame
    local sg = Instance.new("SurfaceGui")
    sg.Face = Enum.NormalId.Top; sg.AlwaysOnTop = true; sg.LightInfluence = 0
    sg.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize; sg.CanvasSize = Vector2.new(256, 256)
    sg.Parent = p
    local f = Instance.new("Frame")
    f.Size = UDim2.fromScale(1, 1); f.BackgroundTransparency = 1; f.BorderSizePixel = 0; f.Parent = sg
    Instance.new("UICorner", f).CornerRadius = UDim.new(1, 0)
    local st = Instance.new("UIStroke")
    st.Color = color; st.Thickness = thick or 8; st.Parent = f
    run(box, function(_, age)
      local t = age / life
      local s = maxSize * (1 - (1 - t) ^ 3)
      p.Size = Vector3.new(math.max(s, 0.1), 0.05, math.max(s, 0.1))
      p.CFrame = base
      st.Transparency = t
      st.Thickness = (thick or 8) * (1 - t * 0.6)
      return t < 1
    end)
  end

  -- ---------------------------------------------------------------- KILL EFFECTS
  local function fxBalloons(pos, head)
    local box = newBox("balloons")
    local items = {}
    local LIFE = 4.6
    for i = 1, 9 do
      local col = PAL[(i - 1) % #PAL + 1]
      local b = mkPart(box, Vector3.new(1.8, 1.8, 1.8), col, Enum.PartType.Ball, Enum.Material.SmoothPlastic)
      b.Reflectance = 0.12
      local s = mkPart(box, Vector3.new(0.05, 0.05, 1), WHITE, nil, Enum.Material.SmoothPlastic)
      items[i] = { b = b, s = s, ang = rnd(0, 6.28), rad = rnd(0.4, 1.9), speed = rnd(3.5, 6.5), delay = rnd(0, 0.4), sf = rnd(1, 2.2) }
    end
    run(box, function(_, age)
      for _, it in ipairs(items) do
        local a = math.max(0, age - it.delay)
        local sway = math.sin(a * it.sf + it.ang)
        local p = pos + Vector3.new(math.cos(it.ang) * it.rad + sway * 0.7, 1.2 + it.speed * a, math.sin(it.ang) * it.rad + sway * 0.4)
        it.b.Position = p
        local top = p - Vector3.new(0, 0.9, 0)
        local bot = top - Vector3.new(sway * 0.5, 3.2, 0)
        it.s.CFrame = CFrame.lookAt((top + bot) / 2, top)
        it.s.Size = Vector3.new(0.05, 0.05, (top - bot).Magnitude)
        local fade = math.clamp(age - (LIFE - 1), 0, 1)
        it.b.Transparency = fade; it.s.Transparency = fade
      end
      return age < LIFE
    end)
  end

  local function fxLightning(pos, head, height)
    local box = newBox("lightning")
    local col = head and C3(255, 225, 110) or C3(185, 215, 255)
    local top = pos + Vector3.new(rnd(-8, 8), height or 130, rnd(-8, 8))
    local pts = { top }
    local N = 18
    for i = 1, N - 1 do
      local t = i / N
      local amp = (1 - t) * 6 + 0.5
      pts[#pts + 1] = top:Lerp(pos, t) + Vector3.new(rnd(-amp, amp), 0, rnd(-amp, amp))
    end
    pts[#pts + 1] = pos
    local segs = {}
    for i = 1, #pts - 1 do
      local a, b = pts[i], pts[i + 1]
      local len = (b - a).Magnitude
      local cf = CFrame.lookAt((a + b) / 2, b)
      local core = mkPart(box, Vector3.new(0.4, 0.4, len), WHITE); core.CFrame = cf
      local glow = mkPart(box, Vector3.new(1.6, 1.6, len), col, nil, nil, 0.6); glow.CFrame = cf
      segs[i] = { core, glow }
    end
    local lp = mkPart(box, Vector3.new(0.2, 0.2, 0.2), WHITE, nil, nil, 1)
    lp.Position = pos + Vector3.new(0, 3, 0)
    local light = Instance.new("PointLight")
    light.Color = col; light.Range = 55; light.Brightness = 8; light.Parent = lp
    burst(box, pos + Vector3.new(0, 0.5, 0), TEX_SPARK, col, 26, 18, 40, 0.8, 1.4, 0.2, Vector3.new(0, -35, 0))
    ringFx(pos, col, 22, 0.55, 10)
    run(box, function(_, age)
      local tr
      if age < 0.09 then tr = 0 elseif age < 0.14 then tr = 1 elseif age < 0.3 then tr = 0.1 else tr = math.min(1, (age - 0.3) / 0.3) end
      for _, s in ipairs(segs) do
        s[1].Transparency = tr
        s[2].Transparency = tr >= 1 and 1 or math.max(0.6, tr)
      end
      light.Brightness = (1 - tr) * 8
      return age < 1.1
    end)
  end

  local function fxConfetti(pos, head)
    local box = newBox("confetti")
    local bits = {}
    for i = 1, 44 do
      local p = mkPart(box, Vector3.new(0.3, 0.05, 0.2), PAL[math.random(1, #PAL)])
      local ang = rnd(0, 6.28)
      local sp = rnd(8, 20)
      bits[i] = { p = p, pos = pos + Vector3.new(0, 1.5, 0), vel = Vector3.new(math.cos(ang) * sp, rnd(14, 30), math.sin(ang) * sp), spin = Vector3.new(rnd(-9, 9), rnd(-9, 9), rnd(-9, 9)), rot = Vector3.zero }
    end
    run(box, function(dt, age)
      for _, b in ipairs(bits) do
        b.vel = Vector3.new(b.vel.X * (1 - dt * 0.9), math.max(b.vel.Y - 26 * dt, -4), b.vel.Z * (1 - dt * 0.9))
        b.pos += b.vel * dt
        b.rot += b.spin * dt
        b.p.CFrame = CFrame.new(b.pos) * CFrame.Angles(b.rot.X, b.rot.Y, b.rot.Z)
        b.p.Transparency = math.clamp(age - 2.2, 0, 1) / 0.8
      end
      return age < 3.0
    end)
  end

  local function fxFireworks(pos, head)
    local box = newBox("firework")
    local rocket = mkPart(box, Vector3.new(0.7, 0.7, 0.7), C3(255, 240, 180), Enum.PartType.Ball)
    local trail = Instance.new("ParticleEmitter")
    trail.Texture = TEX_SPARKLE; trail.Rate = 70; trail.Lifetime = NumberRange.new(0.5, 0.8)
    trail.Speed = NumberRange.new(1, 4); trail.Size = NumberSequence.new(1.1, 0)
    trail.Color = ColorSequence.new(C3(255, 200, 90)); trail.LightEmission = 1
    trail.Transparency = NumberSequence.new({ kp(0, 0), kp(1, 1) })
    trail.Parent = rocket
    local colA, colB = PAL[math.random(1, #PAL)], PAL[math.random(1, #PAL)]
    local burstDone = false
    local light
    run(box, function(_, age)
      if age < 0.8 then
        local t = age / 0.8
        rocket.Position = pos + Vector3.new(math.sin(age * 9) * 0.5, 55 * (1 - (1 - t) ^ 2), 0)
      elseif not burstDone then
        burstDone = true
        local apex = pos + Vector3.new(0, 55, 0)
        rocket.Transparency = 1; trail.Enabled = false
        burst(box, apex, TEX_SPARKLE, ColorSequence.new(colA, colB), 70, 22, 46, 1.5, 2.2, 0.3, Vector3.new(0, -14, 0))
        burst(box, apex, TEX_SPARK, colB, 30, 12, 26, 1.2, 1.6, 0.2, Vector3.new(0, -18, 0))
        local lp = mkPart(box, Vector3.new(0.2, 0.2, 0.2), WHITE, nil, nil, 1)
        lp.Position = apex
        light = Instance.new("PointLight"); light.Color = colA; light.Range = 90; light.Brightness = 6; light.Parent = lp
      end
      if light then light.Brightness = math.max(0, 6 - (age - 0.8) * 5) end
      return age < 2.6
    end)
  end

  local function fxSoul(pos, head)
    local box = newBox("soul")
    local col = head and C3(255, 220, 130) or C3(170, 230, 255)
    local orb = mkPart(box, Vector3.new(2.2, 2.2, 2.2), col, Enum.PartType.Ball, nil, 0.35)
    local emit = Instance.new("ParticleEmitter")
    emit.Texture = TEX_SMOKE; emit.Rate = 40; emit.Lifetime = NumberRange.new(0.9, 1.4)
    emit.Speed = NumberRange.new(0.5, 2); emit.Size = NumberSequence.new(2.2, 0.2)
    emit.Color = ColorSequence.new(col); emit.LightEmission = 1
    emit.Transparency = NumberSequence.new({ kp(0, 0.35), kp(1, 1) })
    emit.Parent = orb
    local sparks = Instance.new("ParticleEmitter")
    sparks.Texture = TEX_SPARKLE; sparks.Rate = 25; sparks.Lifetime = NumberRange.new(0.8, 1.4)
    sparks.Speed = NumberRange.new(1, 3); sparks.Size = NumberSequence.new(0.9, 0)
    sparks.Color = ColorSequence.new(WHITE); sparks.LightEmission = 1
    sparks.Transparency = NumberSequence.new({ kp(0, 0), kp(1, 1) })
    sparks.Parent = orb
    local orbit = {}
    for i = 1, 2 do orbit[i] = mkPart(box, Vector3.new(0.7, 0.7, 0.7), col, Enum.PartType.Ball, nil, 0.3) end
    local LIFE = 3.4
    run(box, function(_, age)
      local h = 1.5 + 8.5 * age
      local c = pos + Vector3.new(math.sin(age * 1.8) * 1.2, h, math.cos(age * 1.5) * 0.8)
      orb.Position = c
      local fade = math.clamp(age - (LIFE - 1), 0, 1)
      orb.Transparency = 0.35 + 0.65 * fade
      emit.Rate = 40 * (1 - fade); sparks.Rate = 25 * (1 - fade)
      for i, o in ipairs(orbit) do
        local a = age * 4 + i * math.pi
        o.Position = c + Vector3.new(math.cos(a) * 1.8, math.sin(age * 3 + i) * 0.4, math.sin(a) * 1.8)
        o.Transparency = 0.3 + 0.7 * fade
      end
      return age < LIFE
    end)
  end

  local function fxShockwave(pos, head, normal)
    local col = head and C3(255, 210, 90) or C3(120, 200, 255)
    ringFx(pos, col, 34, 0.7, 12, normal)
    task.delay(0.12, function() if not Unloaded then ringFx(pos, WHITE, 26, 0.6, 8, normal) end end)
    task.delay(0.24, function() if not Unloaded then ringFx(pos, col, 18, 0.55, 6, normal) end end)
    local box = newBox("shock")
    burst(box, pos + Vector3.new(0, 0.6, 0), TEX_SMOKE, C3(210, 215, 225), 18, 14, 26, 1.0, 3, 6, Vector3.new(0, -2, 0))
    run(box, function(_, age) return age < 1.4 end)
  end

  local function fxGoldRain(pos, head)
    local box = newBox("gold")
    local gy = pos.Y
    local coins = {}
    for i = 1, 34 do
      local p = mkPart(box, Vector3.new(0.12, 0.95, 0.95), C3(255, 205, 40), Enum.PartType.Cylinder, Enum.Material.Metal)
      p.Reflectance = 0.2
      coins[i] = { p = p, x = pos.X + rnd(-4.5, 4.5), z = pos.Z + rnd(-4.5, 4.5), y = gy + rnd(14, 34), v = 0, delay = rnd(0, 0.7), rot = rnd(0, 6), spin = rnd(5, 12), landed = nil }
    end
    run(box, function(dt, age)
      for _, c in ipairs(coins) do
        if age >= c.delay then
          if not c.landed then
            c.v = c.v + 38 * dt
            c.y = c.y - c.v * dt
            if c.y <= gy + 0.1 then c.y = gy + 0.1; c.landed = age; burst(box, Vector3.new(c.x, c.y + 0.2, c.z), TEX_SPARKLE, C3(255, 220, 90), 2, 3, 7, 0.5, 0.9, 0.1, Vector3.new(0, -8, 0)) end
          end
          c.rot += c.spin * dt * (c.landed and 0.15 or 1)
          if c.landed then c.p.CFrame = CFrame.new(c.x, c.y, c.z) * CFrame.Angles(0, 0, math.pi / 2) * CFrame.Angles(c.rot * 0.1, 0, 0)
          else c.p.CFrame = CFrame.new(c.x, c.y, c.z) * CFrame.Angles(c.rot, c.rot * 0.6, 0) end
          if c.landed then c.p.Transparency = math.clamp((age - c.landed - 0.9) / 0.6, 0, 1) end
        else
          c.p.CFrame = CFrame.new(c.x, -5000, c.z)
        end
      end
      return age < 3.8
    end)
  end

  local function fxPillar(pos, head)
    local box = newBox("pillar")
    local col = head and C3(255, 220, 120) or C3(170, 230, 255)
    local beam = mkPart(box, Vector3.new(3, 70, 3), col, Enum.PartType.Cylinder, nil, 0.4)
    local core = mkPart(box, Vector3.new(1, 70, 1), WHITE, Enum.PartType.Cylinder, nil, 0.2)
    local emit = Instance.new("ParticleEmitter")
    emit.Texture = TEX_SPARKLE; emit.Rate = 45; emit.Lifetime = NumberRange.new(1.2, 2)
    emit.Speed = NumberRange.new(6, 12); emit.EmissionDirection = Enum.NormalId.Top
    emit.SpreadAngle = Vector2.new(6, 6); emit.Size = NumberSequence.new(1.1, 0)
    emit.Color = ColorSequence.new(col); emit.LightEmission = 1
    emit.Transparency = NumberSequence.new({ kp(0, 0), kp(1, 1) })
    emit.Parent = beam
    ringFx(pos, col, 16, 0.8, 8)
    run(box, function(_, age)
      local t = age / 1.7
      local w = 3.2 * (1 - t * 0.85)
      local cf = CFrame.new(pos + Vector3.new(0, 35, 0)) * CFrame.Angles(0, 0, math.pi / 2)
      beam.CFrame = cf; core.CFrame = cf
      beam.Size = Vector3.new(70, w, w); core.Size = Vector3.new(70, w * 0.35, w * 0.35)
      beam.Transparency = 0.35 + 0.65 * t; core.Transparency = 0.2 + 0.8 * t
      emit.Rate = 45 * (1 - t)
      return t < 1
    end)
  end

  local KILL_FX = {
    ["Balloons"] = fxBalloons, ["Lightning Strike"] = fxLightning, ["Confetti"] = fxConfetti, ["Fireworks"] = fxFireworks,
    ["Soul Rise"] = fxSoul, ["Shockwave"] = fxShockwave, ["Gold Rain"] = fxGoldRain, ["Light Pillar"] = fxPillar,
  }
  local KILL_NAMES = { "Balloons", "Lightning Strike", "Confetti", "Fireworks", "Soul Rise", "Shockwave", "Gold Rain", "Light Pillar" }

  local function playKill(kind, deathPos, head)
    if kind == "Random" then kind = KILL_NAMES[math.random(1, #KILL_NAMES)] end
    local fn = KILL_FX[kind]
    if not fn then return end
    local g, n = groundAt(deathPos)
    local body = Vector3.new(deathPos.X, g.Y, deathPos.Z)
    fn(kind == "Shockwave" and (g) or body, head, n)
  end

  -- ---------------------------------------------------------------- HIT HELPERS
  local function participantMap()
    local m = {}
    for _, p in ipairs(getParticipants()) do
      if p ~= LocalPlayer then m[getParticipantDisplayName(p)] = p end
    end
    return m
  end
  -- Walks up from a hit part to the character model; returns model, participant (participant is nil for zombies)
  local function victimFromInstance(inst, pos)
    local names = participantMap()
    local m, top = inst, nil
    while m and m ~= Workspace do
      if m:IsA("Model") then
        top = m
        if names[m.Name] then return m, names[m.Name] end
      end
      m = m.Parent
    end
    if pos then
      local best, bestD, bestP
      for name, p in pairs(names) do
        local char = resolveParticipantCharacter(p)
        local rp = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
        if rp then
          local d = (rp.Position - pos).Magnitude
          if d < 7 and (not bestD or d < bestD) then best, bestD, bestP = char, d, p end
        end
      end
      if best then return best, bestP end
    end
    return nil, nil
  end

  -- ---------------------------------------------------------------- ON-HIT GHOST CHAMS
  local ghostList, ghostHL, lastGhost = {}, 0, {}
  local function makeGhost(model)
    local style = Config.GhostStyle
    local life = Config.GhostLife
    local mat = Config.GhostMaterial == "ForceField" and Enum.Material.ForceField or (Config.GhostMaterial == "Glass" and Enum.Material.Glass or Enum.Material.Neon)
    local box = newBox("ghost")
    local gm = Instance.new("Model")
    gm.Parent = box
    local pieces = {}
    local pivotY = model:GetPivot().Position.Y
    for _, d in ipairs(model:GetDescendants()) do
      if #pieces >= 48 then break end
      if d:IsA("BasePart") and d.Transparency < 0.95 and not IgnoredChamPartNames[d.Name] and d.Size.Magnitude > 0.25 then
        local c
        local okC, cl = pcall(function() return d:Clone() end)
        if okC and cl then c = cl end
        if not c then c = Instance.new("Part"); c.Size = d.Size end
        for _, ch in ipairs(c:GetChildren()) do
          if not ch:IsA("DataModelMesh") then ch:Destroy() end
        end
        if c:IsA("MeshPart") then pcall(function() c.TextureID = "" end) end
        c.Anchored = true; c.CanCollide = false; c.CanQuery = false; c.CanTouch = false; c.CastShadow = false; c.Massless = true
        c.Material = mat; c.Reflectance = 0
        c.CFrame = d.CFrame
        c.Color = gradColor(style, (d.Position.Y - (pivotY - 3)) / 6.2, Config.EnemyChamColor)
        c.Transparency = 0.3
        c.Parent = gm
        pieces[#pieces + 1] = c
      end
    end
    if #pieces == 0 then box:Destroy() return end
    local hl
    if Config.GhostWalls and ghostHL < 5 then
      hl = Instance.new("Highlight")
      hl.Adornee = gm; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
      hl.FillColor = gradColor(style, 0.5, Config.EnemyChamColor); hl.OutlineColor = WHITE
      hl.FillTransparency = 0.45; hl.OutlineTransparency = 0.15
      hl.Parent = box
      ghostHL += 1
      box.Destroying:Connect(function() ghostHL -= 1 end)
    end
    table.insert(ghostList, box)
    if #ghostList > 14 then pcall(function() table.remove(ghostList, 1):Destroy() end) end
    run(box, function(_, age)
      local t = math.clamp(age / life, 0, 1)
      local tr = 0.3 + 0.7 * t ^ 1.4
      for _, c in ipairs(pieces) do c.Transparency = tr end
      if hl then hl.FillTransparency = 0.45 + 0.55 * t; hl.OutlineTransparency = 0.15 + 0.85 * t end
      return t < 1
    end)
  end

  local function hitOrb(pos, headshot)
    local box = newBox("orb")
    local col = headshot and C3(255, 215, 60) or C3(255, 255, 255)
    local o = mkPart(box, Vector3.new(0.6, 0.6, 0.6), col, Enum.PartType.Ball)
    o.Position = pos
    run(box, function(_, age)
      local t = age / 0.4
      local s = 0.6 + 1.6 * t
      o.Size = Vector3.new(s, s, s); o.Transparency = t
      return t < 1
    end)
  end

  -- ---------------------------------------------------------------- DAMAGE NUMBERS
  local HealthCache, Watches = {}, {}
  local function damageNumber(pos, amount, head, killed)
    local box = newBox("dmg")
    local p = mkPart(box, Vector3.new(0.2, 0.2, 0.2), WHITE, nil, nil, 1)
    local start = pos + Vector3.new(rnd(-0.6, 0.6), 1, rnd(-0.6, 0.6))
    p.Position = start
    local bg = Instance.new("BillboardGui")
    bg.AlwaysOnTop = true; bg.Size = UDim2.fromOffset(140, 44); bg.LightInfluence = 0; bg.Parent = p
    local l = Instance.new("TextLabel")
    l.Size = UDim2.fromScale(1, 1); l.BackgroundTransparency = 1; l.Font = T.FONT; l.TextSize = head and 30 or 24
    l.Text = string.format("-%d", math.floor(amount + 0.5))
    l.TextColor3 = killed and C3(255, 70, 70) or (head and C3(255, 210, 60) or WHITE)
    l.TextStrokeTransparency = 0.25; l.TextStrokeColor3 = Color3.new(0, 0, 0)
    l.Parent = bg
    run(box, function(_, age)
      local t = age / 0.9
      p.Position = start + Vector3.new(0, 3.2 * (1 - (1 - t) ^ 2), 0)
      l.TextTransparency = t ^ 2; l.TextStrokeTransparency = 0.25 + 0.75 * t ^ 2
      return t < 1
    end)
  end

  -- ---------------------------------------------------------------- IMPACT EFFECTS (non-flesh hits)
  local function impactFx(pos, normal)
    local kind = Config.ImpactFX
    if kind == "Off" then return end
    local box = newBox("impact")
    local n = (typeof(normal) == "Vector3" and normal.Magnitude > 0.1) and normal.Unit or Vector3.new(0, 1, 0)
    if kind == "Sparks" then
      burst(box, pos + n * 0.1, TEX_SPARK, C3(255, 170, 60), 12, 14, 30, 0.45, 0.9, 0.05, Vector3.new(0, -30, 0))
    elseif kind == "Stars" then
      burst(box, pos + n * 0.1, TEX_SPARKLE, C3(255, 245, 190), 9, 8, 18, 0.7, 1.6, 0.2, Vector3.new(0, -6, 0))
    elseif kind == "Rainbow Pop" then
      local seq = ColorSequence.new({ ColorSequenceKeypoint.new(0, C3(255, 70, 70)), ColorSequenceKeypoint.new(0.33, C3(255, 230, 60)), ColorSequenceKeypoint.new(0.66, C3(70, 230, 255)), ColorSequenceKeypoint.new(1, C3(200, 90, 255)) })
      burst(box, pos + n * 0.1, TEX_SPARKLE, seq, 14, 10, 24, 0.7, 1.4, 0.1, Vector3.new(0, -10, 0))
    elseif kind == "Ring" then
      ringFx(pos + n * 0.06, C3(255, 255, 255), 3.4, 0.4, 8, n)
    end
    run(box, function(_, age) return age < 1.0 end)
  end

  -- ---------------------------------------------------------------- KILL BANNER
  local Banner = Instance.new("TextLabel")
  Banner.Name = "KillBanner"; Banner.BackgroundTransparency = 1; Banner.Visible = false
  Banner.AnchorPoint = Vector2.new(0.5, 0.5); Banner.Position = UDim2.fromScale(0.5, 0.74)
  Banner.Size = UDim2.fromOffset(420, 40); Banner.Font = T.FONT; Banner.TextSize = 26
  Banner.TextStrokeTransparency = 0.2; Banner.TextStrokeColor3 = Color3.new(0, 0, 0)
  Banner.ZIndex = 50; Banner.Parent = ScreenGui
  local bannerAt, lastKillAt, combo = 0, 0, 0

  local function onKill(d)
    if type(d) ~= "table" then return end
    local mine = tonumber(d.Killer) == LocalPlayer.UserId
    local head = d.Headshot == true
    local pos = typeof(d.DeathPosition) == "Vector3" and d.DeathPosition or nil
    if mine then
      local now = os.clock()
      combo = (now - lastKillAt < 6) and combo + 1 or 1
      lastKillAt = now
      if Config.KillFlash then flash(head and 0.5 or 0.35, head and C3(255, 215, 90) or WHITE) end
      if Config.KillBanner then
        Banner.Text = string.format("%s%s%s", head and "HEADSHOT  ·  " or "ELIMINATED  ·  ", string.upper(tostring(d.Weapon or "")), combo > 1 and ("  ·  x" .. combo) or "")
        Banner.TextColor3 = head and C3(255, 210, 60) or WHITE
        Banner.Visible = true
        bannerAt = now
      end
    end
    if pos and Config.KillFX ~= "Off" and (mine or Config.KillFXWho == "Everyone") and (not Config.KillFXHeadOnly or head) then
      playKill(Config.KillFX, pos, head)
    end
  end

  local function onImpact(d)
    if type(d) ~= "table" or tostring(d.AttackerUserId) ~= tostring(LocalPlayer.UserId) or d.Exit then return end
    local pos = typeof(d.Position) == "Vector3" and d.Position or nil
    if not pos then return end
    local flesh = d.Material == "Blood Splatter" or d.WasHelmetHeadshot == true
    if not flesh then
      if not d.IsWallbang then impactFx(pos, d.Normal) end
      return
    end
    if not (Config.HitGhosts or Config.DamageNumbers or Config.GhostOrb) then return end
    -- the payload names the victim (VictimUserId; bots have negative ids stored in their UserId attribute)
    local model, p
    local vid = tonumber(d.VictimUserId)
    if vid then
      for _, q in ipairs(getParticipants()) do
        local pid = q:IsA("Player") and q.UserId or q:GetAttribute("UserId")
        if tonumber(pid) == vid then
          p = q
          model = resolveParticipantCharacter(q)
          break
        end
      end
    end
    if not model then model, p = victimFromInstance(typeof(d.Instance) == "Instance" and d.Instance or nil, pos) end
    if Config.HitGhosts and Config.GhostOrb then hitOrb(pos, d.WasHelmetHeadshot) end
    if model and Config.HitGhosts then
      local now = os.clock()
      if now - (lastGhost[model] or 0) > 0.1 then
        lastGhost[model] = now
        local ok, err = pcall(makeGhost, model)
        if not ok then warn("[BloxStrikeSuite] hit ghost: " .. tostring(err)) end
      end
    end
    if Config.DamageNumbers and p then
      local cur = p:GetAttribute("Health")
      Watches[#Watches + 1] = { p = p, prev = HealthCache[p] or cur, pos = pos, head = d.WasHelmetHeadshot == true, t = os.clock() }
    end
  end

  -- ---------------------------------------------------------------- SOUND RIPPLES
  local function nearTeammate(pos)
    local mc = getLocalCharacter()
    local mr = mc and (mc:FindFirstChild("HumanoidRootPart") or mc.PrimaryPart)
    if mr and (mr.Position - pos).Magnitude < 7 then return true end
    for _, p in ipairs(getParticipants()) do
      if p ~= LocalPlayer and not isEnemyParticipant(p) then
        local char = resolveParticipantCharacter(p)
        local rp = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
        if rp and (rp.Position - pos).Magnitude < 8 then return true end
      end
    end
    return false
  end
  local lastRipple = 0
  local function onSound(d)
    if not Config.SoundRipples or type(d) ~= "table" or typeof(d.Position) ~= "Vector3" then return end
    local now = os.clock()
    if now - lastRipple < 0.06 then return end
    local cls = tostring(d.Class or "")
    local foot = cls == "FloorSounds" or cls == "MovementSounds"
    if Config.RippleScope == "Footsteps" and not foot then return end
    if cls == "Sound" or cls == "Other" then return end
    if nearTeammate(d.Position) then return end
    lastRipple = now
    local g = groundAt(d.Position)
    if foot then ringFx(g, C3(110, 220, 255), 9, 0.9, 6)
    elseif string.find(string.lower(cls), "bomb", 1, true) then ringFx(g, C3(255, 70, 70), 26, 1.4, 10)
    else ringFx(g, C3(255, 160, 50), 16, 1.2, 8) end
  end

  -- ---------------------------------------------------------------- listeners
  local unsubs = {}
  local function listen(remote, fn)
    if remote and type(remote.Listen) == "function" then
      local ok, un = pcall(remote.Listen, function(data)
        if Unloaded then return end
        local o, e = pcall(fn, data)
        if not o then warn("[BloxStrikeSuite] world fx: " .. tostring(e)) end
      end)
      if ok and type(un) == "function" then unsubs[#unsubs + 1] = un end
    end
  end
  listen(Remotes and Remotes.UI and Remotes.UI.UIPlayerKilled, onKill)
  listen(Remotes and Remotes.VFX and Remotes.VFX.CreateImpact, onImpact)
  listen(Remotes and Remotes.Sound and Remotes.Sound.ReplicateSound, onSound)

  -- ---------------------------------------------------------------- crosshair ring
  local Ring = Instance.new("Frame")
  Ring.Name = "CrossRing"; Ring.AnchorPoint = Vector2.new(0.5, 0.5); Ring.Position = UDim2.new(0.5, 0, 0.5, 0)
  Ring.Size = UDim2.fromOffset(34, 34); Ring.BackgroundTransparency = 1; Ring.Visible = false; Ring.Parent = ScreenGui
  Instance.new("UICorner", Ring).CornerRadius = UDim.new(1, 0)
  local RingStroke = Instance.new("UIStroke")
  RingStroke.Thickness = 1.6; RingStroke.Parent = Ring
  local ringSize, onTarget, lastTargetCheck = 34, false, 0

  local TargetParams = RaycastParams.new()
  TargetParams.FilterType = Enum.RaycastFilterType.Exclude
  TargetParams.RespectCanCollide = false
  local function checkTarget(cam)
    local ex = { Folder }
    local mc = getLocalCharacter()
    if mc then ex[#ex + 1] = mc end
    TargetParams.FilterDescendantsInstances = ex
    local r = Workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 600, TargetParams)
    if not (r and r.Instance) then return false end
    local m = r.Instance
    local names = participantMap()
    while m and m ~= Workspace do
      if m:IsA("Model") and names[m.Name] then return isEnemyParticipant(names[m.Name]) end
      m = m.Parent
    end
    return false
  end

  -- ---------------------------------------------------------------- vision modes (night vision / thermal)
  local Vision = Instance.new("ColorCorrectionEffect")
  Vision.Name = "BS_Vision"; Vision.Enabled = false; Vision.Parent = Lighting
  local thermal = {}   -- [model] = Highlight
  local function clearThermal()
    for m, h in pairs(thermal) do pcall(function() h:Destroy() end); thermal[m] = nil end
  end
  local function visionStep(now)
    local mode = Config.VisionMode
    if mode == "Off" then
      if Vision.Enabled then Vision.Enabled = false end
      if next(thermal) then clearThermal() end
      return
    end
    Vision.Enabled = true
    if mode == "Night Vision" then
      Vision.TintColor = C3(130, 255, 140); Vision.Brightness = 0.14; Vision.Contrast = 0.3; Vision.Saturation = -0.55
      if next(thermal) then clearThermal() end
    else
      Vision.TintColor = C3(255, 205, 170); Vision.Brightness = -0.04; Vision.Contrast = 0.45; Vision.Saturation = -1
      local seen = {}
      for _, p in ipairs(getParticipants()) do
        if p ~= LocalPlayer and isEnemyParticipant(p) then
          local char = resolveParticipantCharacter(p)
          if char and char.Parent and isParticipantAlive(p, char) then
            seen[char] = true
            if not thermal[char] then
              local h = Instance.new("Highlight")
              h.Adornee = char; h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
              h.FillColor = C3(255, 245, 190); h.OutlineColor = C3(255, 110, 20)
              h.FillTransparency = 0.1; h.OutlineTransparency = 0
              h.Parent = Folder
              thermal[char] = h
            end
          end
        end
      end
      for m, h in pairs(thermal) do
        if not seen[m] then pcall(function() h:Destroy() end); thermal[m] = nil end
      end
    end
  end

  -- ---------------------------------------------------------------- sun position + storm
  local origClock = nil
  local nextBolt = os.clock() + 6
  local function stormBolt()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local yaw = rnd(0, 6.28)
    local dist = rnd(140, 320)
    local base = cam.CFrame.Position + Vector3.new(math.cos(yaw) * dist, 0, math.sin(yaw) * dist)
    local r = Workspace:Raycast(base + Vector3.new(0, 400, 0), Vector3.new(0, -900, 0), GroundParams)
    local gpos = r and r.Position or (base - Vector3.new(0, 8, 0))
    fxLightning(gpos, false, 260)
    flash(0.5, C3(220, 235, 255))
    task.delay(0.2, function() if not Unloaded then flash(0.3, C3(220, 235, 255)) end end)
  end

  -- ---------------------------------------------------------------- GRADIENT CHAMS painter
  local function paintStep(now)
    local name = Config.ChamGradient
    if name == "Off" or not name then return end
    local anim = Config.ChamGradAnim
    local spd = ({ Slow = 0.12, Normal = 0.25, Fast = 0.55 })[Config.ChamGradSpeed] or 0.25
    local phase = now * spd
    local shift = anim == "Flow Down" and phase or -phase
    local cam = Workspace.CurrentCamera
    for model, st in pairs(ModelAppliedState) do
      if model and model.Parent and st.matStyle ~= "Wireframe" then
        local base = Config.EnemyChamColor
        local mid = anim == "Static" and gradColor(name, 0.5, base) or gradLoop(name, phase, base)
        if st.matStyle ~= "HighlightOnly" then
          local parts = ModelVisibleParts[model]
          if parts then
            local inCam = cam and model.Parent == cam
            local n = #parts
            local baseY = (not inCam) and (model:GetPivot().Position.Y - 3) or 0
            for i, part in ipairs(parts) do
              if part.Parent then
                local t = inCam and ((i - 1) / math.max(1, n - 1)) or ((part.Position.Y - baseY) / 6.2)
                local col
                if anim == "Static" then col = gradColor(name, t, base)
                elseif anim == "Pulse" then col = mid
                else col = gradLoop(name, t + shift, base) end
                part.Color = col
              end
            end
          end
        end
        local hl = ChamsHighlights[model]
        if hl and hl.Parent then
          hl.FillColor = mid
          hl.OutlineColor = anim == "Static" and gradColor(name, 1, base) or gradLoop(name, phase + 0.5, base)
        end
      end
    end
  end
  local function refreshChams()
    for _, st in pairs(ModelAppliedState) do st.key = "" end   -- force the normal chams code to re-apply the plain colour
  end

  -- ---------------------------------------------------------------- main loop
  local lastPaint, lastPoll = 0, 0
  local conn = RunService.RenderStepped:Connect(function(dt)
    if Unloaded then return end
    local now = os.clock()
    -- active effects
    local i = 1
    while i <= #Active do
      local e = Active[i]
      local ok, keep = pcall(e.fn, dt, now - e.born)
      if ok and keep then i += 1
      else
        if not ok then warn("[BloxStrikeSuite] fx: " .. tostring(keep)) end
        pcall(function() e.box:Destroy() end)
        table.remove(Active, i)
      end
    end
    -- screen flash
    if flashAmt > 0.01 then
      flashAmt = flashAmt * math.exp(-dt * 7)
      Flash.Enabled = true; Flash.Brightness = flashAmt; Flash.TintColor = Color3.new(1, 1, 1):Lerp(flashTint, 0.35)
    elseif Flash.Enabled then
      flashAmt = 0; Flash.Enabled = false
    end
    -- kill banner
    if Banner.Visible then
      local a = now - bannerAt
      if a > 1.8 then Banner.Visible = false
      else
        local t = math.clamp((a - 1.2) / 0.6, 0, 1)
        Banner.TextTransparency = t; Banner.TextStrokeTransparency = 0.2 + 0.8 * t
        Banner.Position = UDim2.fromScale(0.5, 0.74 - 0.02 * math.min(a * 4, 1))
      end
    end
    -- gradient chams (30 Hz)
    if now - lastPaint > 0.033 then lastPaint = now; paintStep(now) end
    -- health watch for damage numbers (20 Hz)
    if now - lastPoll > 0.05 then
      lastPoll = now
      if Config.DamageNumbers then
        for _, p in ipairs(getParticipants()) do
          if p ~= LocalPlayer then
            local h = p:GetAttribute("Health")
            if type(h) == "number" then HealthCache[p] = h end
          end
        end
        for wi = #Watches, 1, -1 do
          local w = Watches[wi]
          local cur = w.p:GetAttribute("Health")
          if type(cur) == "number" and type(w.prev) == "number" and cur < w.prev then
            damageNumber(w.pos, w.prev - cur, w.head, cur <= 0)
            table.remove(Watches, wi)
          elseif now - w.t > 0.6 then
            table.remove(Watches, wi)
          end
        end
      elseif #Watches > 0 then
        table.clear(Watches)
      end
      visionStep(now)
    end
    -- sun position
    if Config.SunClock ~= "Default" then
      local h = tonumber(string.match(Config.SunClock, "^(%d+)"))
      if h then
        if origClock == nil then origClock = Lighting.ClockTime end
        if Lighting.ClockTime ~= h then Lighting.ClockTime = h end
      end
    elseif origClock ~= nil then
      Lighting.ClockTime = origClock
      origClock = nil
    end
    -- storm
    if Config.Storm and now >= nextBolt then
      local gap = ({ Rare = { 14, 26 }, Normal = { 6, 14 }, Violent = { 2, 6 } })[Config.StormFreq] or { 6, 14 }
      nextBolt = now + rnd(gap[1], gap[2])
      pcall(stormBolt)
    end
    -- crosshair ring + red-on-target
    local cam = Workspace.CurrentCamera
    if cam and (Config.CrossRing or Config.CrossOnTarget) then
      if now - lastTargetCheck > 0.066 then
        lastTargetCheck = now
        local was = onTarget
        onTarget = Config.CrossOnTarget and checkTarget(cam) or false
        if onTarget ~= was and not onTarget then syncCrosshairVisuals() end
        if onTarget and Config.CrosshairEnabled then
          local red = C3(255, 60, 60)
          CH_Dot.BackgroundColor3 = red; CH_Top.BackgroundColor3 = red; CH_Bottom.BackgroundColor3 = red
          CH_Left.BackgroundColor3 = red; CH_Right.BackgroundColor3 = red
        end
      end
    elseif onTarget then
      onTarget = false
      syncCrosshairVisuals()
    end
    if Config.CrossRing then
      local mc = getLocalCharacter()
      local rp = mc and (mc:FindFirstChild("HumanoidRootPart") or mc.PrimaryPart)
      local speed = rp and Vector3.new(rp.AssemblyLinearVelocity.X, 0, rp.AssemblyLinearVelocity.Z).Magnitude or 0
      local target = math.clamp(30 + speed * 0.9, 30, 78)
      ringSize += (target - ringSize) * math.min(1, dt * 12)
      Ring.Size = UDim2.fromOffset(ringSize, ringSize)
      RingStroke.Color = onTarget and C3(255, 60, 60) or Config.CrosshairColor
      Ring.Visible = true
    elseif Ring.Visible then
      Ring.Visible = false
    end
  end)

  FX.World = {
    GradNames = GRAD_NAMES, KillNames = KILL_NAMES,
    playKill = playKill, refreshChams = refreshChams, gradColor = gradColor, makeGhost = makeGhost,
    damageNumber = damageNumber, impactFx = impactFx, onKill = onKill, onImpact = onImpact, onSound = onSound,
    ringFx = ringFx, flash = flash, Active = Active, Folder = Folder,
    preview = function(kind)
      local cam = Workspace.CurrentCamera
      if not cam then return end
      local f = cam.CFrame.LookVector
      local pos = cam.CFrame.Position + Vector3.new(f.X, 0, f.Z).Unit * 14
      local g = groundAt(pos)
      playKill(kind or Config.KillFX, g + Vector3.new(0, 2.7, 0), math.random() < 0.3)
    end,
  }

  table.insert(FX.Unload, function()
    conn:Disconnect()
    for _, un in ipairs(unsubs) do pcall(un) end
    if origClock ~= nil then pcall(function() Lighting.ClockTime = origClock end) end
    clearThermal()
    for _, inst in ipairs({ Flash, Vision, Banner, Ring, Folder }) do pcall(function() inst:Destroy() end) end
    pcall(refreshChams)
    pcall(syncCrosshairVisuals)
    table.clear(Active)
    FX.World = nil
  end)
end)()

-- ----------------------------------------------------------------------------
-- GRAPHICS: colour grading, bloom / sun rays / depth of field / vignette / motion blur, atmosphere + sky + clouds +
-- water, weather particles, foliage sway (palm fronds, ferns, vines) and an FPS-boost preset.
-- Everything is reversible: original values are remembered the moment a feature is first used and restored exactly
-- when it is turned off / the script unloads. Our own post effects are separate "BS_*" instances, so the game's own
-- Bloom / ColorCorrection / SunRays are never edited (the FPS boost only toggles them and restores them).
-- ----------------------------------------------------------------------------
;(function()
  local DEF = {
    GfxBrightness = "0.00", GfxContrast = "0.00", GfxSaturation = "0.00", GfxTint = "None", GfxExposure = "0.0",
    GfxBloom = "Off", GfxSunRays = "Off", GfxDOF = "Off", GfxVignette = "Off", GfxMotionBlur = "Off",
    GfxFog = "Default", GfxHaze = "Default", GfxAtmoTint = "None", GfxGlare = "Default",
    GfxClouds = "Default", GfxCloudDensity = "Default", GfxStars = "Default", GfxSunSize = "Default", GfxSunTint = "None",
    GfxWaves = "Default", GfxWaterSpeed = "Default", GfxWaterTint = "None", GfxWaterClarity = "Default",
    GfxWeather = "None", GfxWeatherAmount = "Medium", GfxReflections = "Default", GfxShadowSoft = "Default",
    TreeSway = false, TreeSwayStrength = "Normal", TreeSwaySpeed = "Normal", TreeSwayRange = "150",
    FPSBoost = "Off", FPSCap = "Default", FPSCounter = false,
  }
  for k, v in pairs(DEF) do if Config[k] == nil then Config[k] = v end end

  local Terrain = Workspace.Terrain
  local WHITE, BLACK = Color3.new(1, 1, 1), Color3.new(0, 0, 0)
  local function num(s, d) return tonumber(s) or d end
  local function tintOf(name) return ColorPalette[name] end

  local Gfx = {}
  local Boost = { level = 0 }

  -- ---------------------------------------------------------------- generic "remember the original" helpers
  local Held = {}   -- [instance] = { [property] = original value }
  local function hold(inst, prop, value)
    if not inst then return end
    local h = Held[inst]
    if not h then h = {}; Held[inst] = h end
    if h[prop] == nil then
      local ok, cur = pcall(function() return inst[prop] end)
      if not ok then return end
      h[prop] = cur
    end
    pcall(function() if inst[prop] ~= value then inst[prop] = value end end)
  end
  local function release(inst, prop)
    local h = inst and Held[inst]
    if h and h[prop] ~= nil then
      local orig = h[prop]
      h[prop] = nil
      pcall(function() inst[prop] = orig end)
    end
  end
  local function want(inst, prop, value)   -- value == nil  ->  put the original back
    if value == nil then release(inst, prop) else hold(inst, prop, value) end
  end
  local function releaseAll()
    for inst, props in pairs(Held) do
      for prop, orig in pairs(props) do pcall(function() inst[prop] = orig end) end
    end
    table.clear(Held)
  end

  -- our own post effects
  local Objs = {}
  local function eff(class, name)
    local o = Objs[name]
    if o and o.Parent then return o end
    o = Instance.new(class)
    o.Name = name
    o.Parent = Lighting
    Objs[name] = o
    return o
  end
  local function drop(name)
    local o = Objs[name]
    if o then pcall(function() o:Destroy() end); Objs[name] = nil end
  end

  -- ---------------------------------------------------------------- option tables (strings shown in the UI)
  Gfx.Options = {
    Brightness = { "-0.20", "-0.10", "-0.05", "0.00", "+0.05", "+0.10", "+0.20" },
    Contrast = { "-0.30", "-0.15", "0.00", "+0.10", "+0.20", "+0.35", "+0.50" },
    Saturation = { "-1.00", "-0.50", "-0.25", "0.00", "+0.25", "+0.50", "+1.00" },
    Exposure = { "-1.0", "-0.5", "0.0", "+0.5", "+1.0", "+2.0" },
    Bloom = { "Off", "Soft", "Medium", "Strong", "Dreamy" },
    SunRays = { "Off", "Soft", "Medium", "Strong" },
    DOF = { "Off", "Subtle", "Cinematic", "Strong" },
    Vignette = { "Off", "Light", "Medium", "Heavy" },
    MotionBlur = { "Off", "Low", "Medium", "High" },
    Fog = { "Default", "None", "Light", "Medium", "Heavy", "Thick" },
    Haze = { "Default", "0", "1", "2", "4", "7" },
    Glare = { "Default", "0", "1", "2", "4" },
    Clouds = { "Default", "None", "Light", "Medium", "Overcast" },
    CloudDensity = { "Default", "Thin", "Normal", "Thick" },
    Stars = { "Default", "0", "1000", "3000", "5000" },
    SunSize = { "Default", "Small", "Large", "Huge" },
    Waves = { "Default", "Calm", "Rough", "Stormy" },
    WaterSpeed = { "Default", "Slow", "Fast", "Frenzy" },
    WaterClarity = { "Default", "Clear", "Murky" },
    Weather = { "None", "Rain", "Snow", "Dust", "Fireflies", "Embers", "Leaves" },
    WeatherAmount = { "Light", "Medium", "Heavy" },
    Reflections = { "Default", "0.0", "0.25", "0.5", "0.75", "1.0" },   -- Roblox clamps EnvironmentSpecularScale to 0..1
    ShadowSoft = { "Default", "Sharp", "Soft", "Blurry" },
    SwayStrength = { "Gentle", "Normal", "Strong", "Storm" },
    SwaySpeed = { "Slow", "Normal", "Fast" },
    SwayRange = { "80", "150", "250", "400" },
    FPSBoost = { "Off", "Light", "Medium", "Max" },
    FPSCap = { "Default", "30", "60", "90", "120", "144", "Unlimited" },
  }
  local BLOOM = { Soft = { 0.4, 24, 1.0 }, Medium = { 0.9, 32, 0.9 }, Strong = { 1.6, 40, 0.8 }, Dreamy = { 2.2, 56, 0.6 } }
  local RAYS = { Soft = { 0.08, 0.6 }, Medium = { 0.22, 0.8 }, Strong = { 0.5, 1.0 } }
  local DOFS = { Subtle = { 0.2, 90, 45 }, Cinematic = { 0.35, 55, 28 }, Strong = { 0.6, 35, 16 } }
  local FOG = { None = 0, Light = 0.15, Medium = 0.35, Heavy = 0.6, Thick = 0.85 }
  local CLOUD_COVER = { None = 0, Light = 0.25, Medium = 0.55, Overcast = 0.9 }
  local CLOUD_DENS = { Thin = 0.15, Normal = 0.45, Thick = 0.85 }
  local SUN_SIZE = { Small = 10, Large = 38, Huge = 62 }
  local WAVES = { Calm = 0.05, Rough = 0.45, Stormy = 0.9 }
  local WSPEED = { Slow = 4, Fast = 18, Frenzy = 32 }
  local SOFT = { Sharp = 0, Soft = 0.5, Blurry = 1 }
  local VIGN = { Light = 0.72, Medium = 0.5, Heavy = 0.28 }   -- start transparency of the edge gradient
  local MBLUR = { Low = 8, Medium = 16, High = 26 }

  -- ---------------------------------------------------------------- colour grading, glow, rays, depth of field
  local function applyPostFX()
    local blocked = Boost.level >= 1   -- the FPS boost owns post-processing while it is on
    local b, c, s = num(Config.GfxBrightness, 0), num(Config.GfxContrast, 0), num(Config.GfxSaturation, 0)
    local tint = tintOf(Config.GfxTint)
    if blocked or (b == 0 and c == 0 and s == 0 and not tint) then
      drop("BS_Color")
    else
      local cc = eff("ColorCorrectionEffect", "BS_Color")
      cc.Brightness = b; cc.Contrast = c; cc.Saturation = s
      cc.TintColor = tint and tint:Lerp(WHITE, 0.55) or WHITE
    end

    local bl = BLOOM[Config.GfxBloom]
    if blocked or not bl then drop("BS_Bloom") else
      local e = eff("BloomEffect", "BS_Bloom")
      e.Intensity = bl[1]; e.Size = bl[2]; e.Threshold = bl[3]
    end

    local ry = RAYS[Config.GfxSunRays]
    if blocked or not ry then drop("BS_Rays") else
      local e = eff("SunRaysEffect", "BS_Rays")
      e.Intensity = ry[1]; e.Spread = ry[2]
    end

    local dof = DOFS[Config.GfxDOF]
    if blocked or not dof then drop("BS_DOF") else
      local e = eff("DepthOfFieldEffect", "BS_DOF")
      e.FarIntensity = dof[1]; e.FocusDistance = dof[2]; e.InFocusRadius = dof[3]; e.NearIntensity = 0
    end
  end

  -- ---------------------------------------------------------------- atmosphere / sky / clouds / water / lighting props
  local function applyWorld()
    local atmos = Lighting:FindFirstChildOfClass("Atmosphere")
    local sky = Lighting:FindFirstChildOfClass("Sky")
    local clouds = Terrain:FindFirstChildOfClass("Clouds")
    local blocked = Boost.level >= 2

    if atmos then
      local fog = (not blocked and not Config.NoFog) and FOG[Config.GfxFog] or nil
      want(atmos, "Density", fog)
      local haze = (not blocked) and (Config.GfxHaze ~= "Default") and num(Config.GfxHaze, 0) or nil
      if Config.NoFog then haze = nil end
      want(atmos, "Haze", haze)
      want(atmos, "Glare", (not blocked and Config.GfxGlare ~= "Default") and num(Config.GfxGlare, 0) or nil)
      local at = tintOf(Config.GfxAtmoTint)
      want(atmos, "Color", at and at:Lerp(WHITE, 0.35) or nil)
      want(atmos, "Decay", at and at:Lerp(BLACK, 0.45) or nil)
    end
    if sky then
      want(sky, "StarCount", (Config.GfxStars ~= "Default") and num(Config.GfxStars, 3000) or nil)
      want(sky, "SunAngularSize", SUN_SIZE[Config.GfxSunSize])
      want(sky, "MoonAngularSize", SUN_SIZE[Config.GfxSunSize])
    end
    if clouds then
      local cover = CLOUD_COVER[Config.GfxClouds]
      want(clouds, "Cover", cover)
      want(clouds, "Density", CLOUD_DENS[Config.GfxCloudDensity])
      local cloudsOn = nil                       -- NOTE: `x and false or nil` can never give false in Lua, so spell it out
      if Boost.level >= 3 then cloudsOn = false end
      want(clouds, "Enabled", cloudsOn)
    end
    -- terrain water
    want(Terrain, "WaterWaveSize", (Boost.level >= 3) and 0 or WAVES[Config.GfxWaves])
    want(Terrain, "WaterWaveSpeed", WSPEED[Config.GfxWaterSpeed])
    local wt = tintOf(Config.GfxWaterTint)
    want(Terrain, "WaterColor", wt)
    want(Terrain, "WaterTransparency", Config.GfxWaterClarity == "Clear" and 0.85 or (Config.GfxWaterClarity == "Murky" and 0.12 or nil))
    -- lighting
    local ex = num(Config.GfxExposure, 0)
    want(Lighting, "ExposureCompensation", ex ~= 0 and ex or nil)
    want(Lighting, "EnvironmentSpecularScale", (Boost.level >= 3) and 0 or ((Config.GfxReflections ~= "Default") and num(Config.GfxReflections, 1) or nil))
    want(Lighting, "ShadowSoftness", SOFT[Config.GfxShadowSoft])
    local st = tintOf(Config.GfxSunTint)
    want(Lighting, "ColorShift_Top", st)
  end

  -- ---------------------------------------------------------------- vignette (4 edge gradients, no assets needed)
  local Vig = { root = nil }
  local function applyVignette()
    local a = (Boost.level < 1) and VIGN[Config.GfxVignette] or nil
    if not a then
      if Vig.root then Vig.root.Visible = false end
      return
    end
    if not Vig.root then
      local root = Instance.new("Frame")
      root.Name = "BS_Vignette"; root.BackgroundTransparency = 1; root.Size = UDim2.fromScale(1, 1)
      root.Active = false; root.ZIndex = -10; root.Parent = ScreenGui   -- below the menu and the ESP
      local function edge(pos, size, rot)
        local f = Instance.new("Frame")
        f.BackgroundColor3 = BLACK; f.BorderSizePixel = 0; f.Position = pos; f.Size = size; f.Active = false; f.Parent = root
        local g = Instance.new("UIGradient"); g.Rotation = rot; g.Parent = f
        return g
      end
      Vig.g = {
        edge(UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.32), 90), edge(UDim2.fromScale(0, 0.68), UDim2.fromScale(1, 0.32), 270),
        edge(UDim2.fromScale(0, 0), UDim2.fromScale(0.22, 1), 0), edge(UDim2.fromScale(0.78, 0), UDim2.fromScale(0.22, 1), 180),
      }
      Vig.root = root
    end
    Vig.root.Visible = true
    for _, g in ipairs(Vig.g) do
      g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(1, 1) })
    end
  end

  -- ---------------------------------------------------------------- weather particles around the camera
  -- RAIN is drawn as real thin neon streaks (not a particle emitter): the emitter version was invisible on this device
  -- (snow worked, rain did not) and particle sprites can't be tuned without seeing the screen. Streaks always render,
  -- move together in ONE Workspace:BulkMoveTo call per frame, and lean along the wind.
  local Rain = { folder = nil, parts = {}, drops = {}, cfs = {}, key = nil }
  local function clearRain()
    if Rain.folder then pcall(function() Rain.folder:Destroy() end) end
    Rain.folder, Rain.key = nil, nil
    table.clear(Rain.parts); table.clear(Rain.drops); table.clear(Rain.cfs)
  end
  local function buildRain(mul)
    clearRain()
    local folder = Instance.new("Folder")
    folder.Name = "BS_Rain"
    folder.Parent = Workspace
    Rain.folder = folder
    for i = 1, math.floor(240 * mul) do
      local p = Instance.new("Part")
      p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
      p.Material = Enum.Material.Neon; p.Color = Color3.fromRGB(185, 210, 255); p.Transparency = 0.45
      p.Size = Vector3.new(0.05, 1.8, 0.05)
      p.Parent = folder
      Rain.parts[i] = p
      Rain.drops[i] = { x = (math.random() - 0.5) * 70, z = (math.random() - 0.5) * 70, y = math.random() * 40 - 12, speed = 48 + math.random() * 22 }
      Rain.cfs[i] = CFrame.new()
    end
  end
  local function stepRain(cam, dt)
    if not Rain.folder then return end
    local pos = cam.CFrame.Position
    local tilt = CFrame.Angles(0, 0, math.rad(9))   -- streaks lean ~9 degrees; the x offset below follows the same slope
    for i, d in ipairs(Rain.drops) do
      d.y -= d.speed * dt
      if d.y < -14 then
        d.y = 24 + math.random() * 14
        d.x = (math.random() - 0.5) * 70; d.z = (math.random() - 0.5) * 70
      end
      Rain.cfs[i] = CFrame.new(pos.X + d.x - d.y * 0.16, pos.Y + d.y, pos.Z + d.z) * tilt
    end
    Workspace:BulkMoveTo(Rain.parts, Rain.cfs, Enum.BulkMoveMode.FireCFrameChanged)
  end

  local Weather = { part = nil, key = nil, emitters = {} }
  local function clearWeather()
    for _, e in ipairs(Weather.emitters) do pcall(function() e:Destroy() end) end
    table.clear(Weather.emitters)
    if Weather.part then pcall(function() Weather.part:Destroy() end); Weather.part = nil end
    Weather.key = nil
  end
  local function applyWeather()
    local kind = Config.GfxWeather
    if kind == "None" or Boost.level >= 3 then clearWeather(); clearRain() return end
    local amountMul = Config.GfxWeatherAmount == "Light" and 0.5 or (Config.GfxWeatherAmount == "Heavy" and 2 or 1)
    if kind == "Rain" then
      clearWeather()
      local rkey = "Rain|" .. amountMul
      if Rain.key ~= rkey or not (Rain.folder and Rain.folder.Parent) then
        buildRain(amountMul)
        Rain.key = rkey
      end
      return
    end
    clearRain()
    local key = kind .. "|" .. amountMul
    if Weather.key == key and Weather.part and Weather.part.Parent then return end
    clearWeather()
    Weather.key = key
    local volume = (kind == "Dust" or kind == "Fireflies")
    local p = Instance.new("Part")
    p.Name = "BS_Weather"; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
    p.Transparency = 1
    p.Size = volume and Vector3.new(46, 18, 46) or Vector3.new(90, 1, 90)
    p.Parent = Workspace
    Weather.part = p
    local function em(tex, color, size, life, rate, speed, spread, accel, emission, trans, orient)
      local e = Instance.new("ParticleEmitter")
      e.Texture = tex; e.Color = color; e.Size = size
      e.Lifetime = NumberRange.new(life[1], life[2]); e.Rate = rate * amountMul
      e.Speed = NumberRange.new(speed[1], speed[2]); e.SpreadAngle = Vector2.new(spread, spread)
      e.Acceleration = accel; e.LightEmission = emission; e.LightInfluence = 0.2
      e.Rotation = NumberRange.new(0, 360); e.RotSpeed = NumberRange.new(-60, 60)
      e.Transparency = trans
      e.EmissionDirection = volume and Enum.NormalId.Top or Enum.NormalId.Bottom
      if orient then e.Orientation = orient end
      e.Parent = p
      Weather.emitters[#Weather.emitters + 1] = e
    end
    local smoke, sparkle, spark = "rbxasset://textures/particles/smoke_main.dds", "rbxasset://textures/particles/sparkles_main.dds", "rbxasset://textures/particles/fire_sparks_main.dds"
    local function ns(a, b) return NumberSequence.new({ NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(1, b) }) end
    local function cs(c) return ColorSequence.new(c) end
    if kind == "Snow" then
      em(smoke, cs(WHITE), ns(0.22, 0.2), { 6, 9 }, 260, { 2, 4 }, 25, Vector3.new(-1.5, -1, 0.6), 0.3, ns(0.15, 0.4))
    elseif kind == "Dust" then
      em(smoke, cs(Color3.fromRGB(235, 225, 205)), ns(0.07, 0.07), { 5, 8 }, 55, { 0.1, 0.5 }, 180, Vector3.new(0.1, 0.05, 0), 0.4, ns(0.45, 0.8))
    elseif kind == "Fireflies" then
      em(sparkle, cs(Color3.fromRGB(200, 255, 110)), ns(0.35, 0.1), { 4, 7 }, 12, { 0.3, 1 }, 180, Vector3.new(0, 0.15, 0), 1, NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.1), NumberSequenceKeypoint.new(0.7, 0.3), NumberSequenceKeypoint.new(1, 1) }))
    elseif kind == "Embers" then
      em(spark, cs(Color3.fromRGB(255, 150, 50)), ns(0.28, 0), { 4, 7 }, 110, { 1, 3 }, 40, Vector3.new(-2, 3.5, 0), 1, ns(0.1, 0.9), Enum.ParticleOrientation.FacingCamera)
    elseif kind == "Leaves" then
      em(smoke, cs(Color3.fromRGB(150, 120, 55)), ns(0.35, 0.3), { 6, 9 }, 70, { 1, 3 }, 35, Vector3.new(-3, -2.2, 1), 0, ns(0.2, 0.5))
    end
  end

  -- ---------------------------------------------------------------- motion blur (camera-speed driven BlurEffect)
  local MB = { last = nil, size = 0 }
  local function stepMotionBlur(cam, dt)
    local level = (Boost.level < 1) and MBLUR[Config.GfxMotionBlur] or nil
    if not level then
      if Objs["BS_MotionBlur"] then drop("BS_MotionBlur") end
      MB.last, MB.size = nil, 0
      return
    end
    local look = cam.CFrame.LookVector
    local ang = MB.last and (math.acos(math.clamp(look:Dot(MB.last), -1, 1)) / math.max(dt, 1e-3)) or 0
    MB.last = look
    local target = math.clamp((ang - 0.7) * 5, 0, level)     -- ignore tiny drifts, saturate on fast turns
    MB.size += (target - MB.size) * math.min(1, dt * 14)
    if MB.size > 0.4 then
      local b = eff("BlurEffect", "BS_MotionBlur")
      b.Size = MB.size
    elseif Objs["BS_MotionBlur"] then
      drop("BS_MotionBlur")
    end
  end

  -- ---------------------------------------------------------------- foliage sway
  local Sway = { recs = {}, built = false, acc = 0, active = false }
  local function collectFoliage()
    table.clear(Sway.recs)
    local map = Workspace:FindFirstChild("Map")
    local geo = map and (map:FindFirstChild("Geometry") or map)
    if not geo then return end
    local crowns = {}
    for _, d in ipairs(geo:GetDescendants()) do
      if d:IsA("BasePart") and not d.CanCollide then
        local model = d:FindFirstAncestorOfClass("Model")
        local mname = model and model.Name:lower() or ""
        local nm = d.Name:lower()
        local kind
        if mname:find("palm") and not d.CanQuery then
          kind = "frond"                       -- palm leaves: non-collidable AND non-queryable -> 100% safe to animate
        elseif nm:find("vine") or mname:find("vine") then
          kind = "vine"
        elseif nm:find("fern") or nm:find("bush") or nm:find("leaf") or nm:find("foliage") or mname:find("fern") or mname:find("bush") then
          kind = "bush"
        end
        if kind then
          local rec = {
            part = d, cf = d.CFrame, kind = kind, model = model, moved = false,
            phase = ((d.Position.X * 0.131 + d.Position.Z * 0.173) % (2 * math.pi)),
          }
          Sway.recs[#Sway.recs + 1] = rec
          if kind == "frond" and model then
            local c = crowns[model]
            if not c then c = { sum = Vector3.zero, n = 0 }; crowns[model] = c end
            c.sum += d.Position; c.n += 1
          end
        end
      end
    end
    for _, r in ipairs(Sway.recs) do
      local up = r.cf.UpVector
      if r.kind == "frond" and r.model and crowns[r.model] then
        local c = crowns[r.model]
        r.pivot = c.sum / c.n                                   -- the whole crown tilts around its centre
      elseif r.kind == "vine" then
        r.pivot = r.cf.Position + Vector3.new(0, r.part.Size.Y * 0.5, 0)   -- hangs from the top
      else
        r.pivot = r.cf.Position - up * (r.part.Size.Y * 0.5)    -- bushes / ferns bend from the base
      end
    end
    Sway.built = true
  end
  local function restoreFoliage()
    for _, r in ipairs(Sway.recs) do
      if r.moved and r.part.Parent then r.part.CFrame = r.cf end
      r.moved = false
    end
  end
  local function stepSway(cam, dt)
    if not Config.TreeSway or Boost.level >= 3 then
      if Sway.active then restoreFoliage(); Sway.active = false end
      return
    end
    Sway.acc += dt
    if Sway.acc < 1 / 30 then return end
    Sway.acc = 0
    if not Sway.built then collectFoliage() end
    Sway.active = true
    local strength = ({ Gentle = 0.5, Normal = 1, Strong = 1.8, Storm = 3 })[Config.TreeSwayStrength] or 1
    local speed = ({ Slow = 0.6, Normal = 1, Fast = 1.7 })[Config.TreeSwaySpeed] or 1
    local range = num(Config.TreeSwayRange, 150)
    local camPos = cam.CFrame.Position
    local t = os.clock() * speed
    local wind = Workspace.GlobalWind
    wind = Vector3.new(wind.X, 0, wind.Z)
    if wind.Magnitude < 0.5 then wind = Vector3.new(1, 0, 0.35) end
    wind = wind.Unit
    local axis = Vector3.yAxis:Cross(wind).Unit            -- tilting around this axis leans the foliage along the wind
    local gust = math.sin(t * 0.37) * 0.5 + 0.5            -- slow global gusts 0..1
    for _, r in ipairs(Sway.recs) do
      local part = r.part
      if part.Parent then
        if (r.cf.Position - camPos).Magnitude <= range then
          local base = math.sin(t * 1.3 + r.phase) * 0.55 + math.sin(t * 0.71 + r.phase * 1.7) * 0.45
          local amp = (r.kind == "frond" and 3.4 or (r.kind == "vine" and 2.6 or 1.5)) * strength * (0.6 + 0.8 * gust)
          local cf = CFrame.new(r.pivot) * CFrame.fromAxisAngle(axis, math.rad(amp * base)) * CFrame.new(-r.pivot) * r.cf
          if r.kind == "frond" then
            cf = cf * CFrame.Angles(math.rad(1.4 * strength * math.sin(t * 4.1 + r.phase * 3)), 0, math.rad(1.2 * strength * math.sin(t * 3.3 + r.phase * 2)))
          end
          part.CFrame = cf
          r.moved = true
        elseif r.moved then
          part.CFrame = r.cf
          r.moved = false
        end
      end
    end
  end

  -- ---------------------------------------------------------------- FPS boost presets (fully reversible)
  local Saved = { effects = {}, mesh = {}, emit = {}, sa = {}, decals = {}, count = 0 }
  local function boostRestore()
    for inst, was in pairs(Saved.effects) do pcall(function() inst.Enabled = was end) end
    for inst, was in pairs(Saved.mesh) do pcall(function() inst.RenderFidelity = was end) end
    for inst, was in pairs(Saved.emit) do pcall(function() inst.Enabled = was end) end
    for inst, parent in pairs(Saved.sa) do pcall(function() if parent.Parent then inst.Parent = parent end end) end
    for inst, was in pairs(Saved.decals) do pcall(function() inst.Transparency = was end) end
    Saved.effects, Saved.mesh, Saved.emit, Saved.sa, Saved.decals = {}, {}, {}, {}, {}
    if Saved.quality then pcall(function() settings().Rendering.QualityLevel = Saved.quality end); Saved.quality = nil end
    Saved.count = 0
  end

  local function boostApply(level)
    boostRestore()
    Boost.level = level
    if level <= 0 then return end
    local n = 0
    -- 1) the game's own post effects (Bloom / SunRays / DepthOfField / extra blur). Level 3 also drops ColorCorrection.
    for _, c in ipairs(Lighting:GetChildren()) do
      if c:IsA("PostEffect") and not string.find(c.Name, "^BS_") and c.Name ~= "Menu" then
        local drops = c:IsA("BloomEffect") or c:IsA("SunRaysEffect") or c:IsA("DepthOfFieldEffect") or c:IsA("BlurEffect")
          or (level >= 3 and c:IsA("ColorCorrectionEffect"))
        if drops and c.Enabled then Saved.effects[c] = true; c.Enabled = false; n += 1 end
      end
    end
    -- 2) rendering quality
    pcall(function()
      local r = settings().Rendering
      Saved.quality = r.QualityLevel
      local target = (level == 1 and 5) or (level == 2 and 3 or 1)
      if r.QualityLevel.Value == 0 or r.QualityLevel.Value > target then r.QualityLevel = Enum.QualityLevel:FromValue(target) end
    end)
    -- 3) Medium+: shadows off (the biggest single win with Future lighting) + decorative map particles off.
    --    (MeshPart.RenderFidelity is NOT used: the map meshes refuse runtime changes - every write only logs
    --    "Cannot change SolidModel RenderFidelity during Run-Time" and does nothing.)
    if level >= 2 then
      if not Config.NoShadows then hold(Lighting, "GlobalShadows", false) end
      local map = Workspace:FindFirstChild("Map")
      for _, d in ipairs(map and map:GetDescendants() or {}) do
        if (d:IsA("ParticleEmitter") or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles")) and d.Enabled then
          Saved.emit[d] = true; d.Enabled = false; n += 1
        end
      end
    end
    -- 4) Max: strip PBR surface maps + decals from the static map (looks flatter, big GPU saving)
    if level >= 3 then
      local map = Workspace:FindFirstChild("Map")
      for _, d in ipairs(map and map:GetDescendants() or {}) do
        if d:IsA("SurfaceAppearance") then
          Saved.sa[d] = d.Parent; d.Parent = nil; n += 1
        elseif (d:IsA("Decal") or d:IsA("Texture")) and d.Transparency < 1 then
          Saved.decals[d] = d.Transparency; d.Transparency = 1; n += 1
        end
      end
    end
    Saved.count = n
  end

  function Gfx.setFPSBoost(name)
    local level = ({ Off = 0, Light = 1, Medium = 2, Max = 3 })[name] or 0
    if level < 2 then release(Lighting, "GlobalShadows") end
    boostApply(level)
    Gfx.refresh()
    return Saved.count
  end

  -- FPS cap through the executor (restored on unload)
  local OrigCap
  function Gfx.setFPSCap(name)
    if type(setfpscap) ~= "function" then return false end
    if OrigCap == nil and type(getfpscap) == "function" then pcall(function() OrigCap = getfpscap() end) end
    local v = (name == "Unlimited") and 0 or tonumber(name)
    if name == "Default" then v = OrigCap or 60 end
    if v then pcall(setfpscap, v) end
    return true
  end

  -- ---------------------------------------------------------------- FPS meter + driver
  local fpsEMA = 60
  function Gfx.getFPS() return math.floor(fpsEMA + 0.5) end

  function Gfx.refresh()
    applyPostFX()
    applyWorld()
    applyVignette()
    applyWeather()
    if not Config.TreeSway and Sway.active then restoreFoliage(); Sway.active = false end
  end

  local acc = 0
  local conn = RunService.RenderStepped:Connect(function(dt)
    if Unloaded then return end
    fpsEMA += ((1 / math.max(dt, 1e-4)) - fpsEMA) * math.min(1, dt * 1.5)
    local cam = Workspace.CurrentCamera
    if not cam then return end
    stepMotionBlur(cam, dt)
    stepSway(cam, dt)
    stepRain(cam, dt)
    if Weather.part then
      Weather.part.CFrame = CFrame.new(cam.CFrame.Position + ((Config.GfxWeather == "Dust" or Config.GfxWeather == "Fireflies") and Vector3.zero or Vector3.new(0, 22, 0)))
    end
    -- the game rewrites lighting between rounds: re-assert every half second
    acc += dt
    if acc >= 0.5 then
      acc = 0
      applyPostFX()
      applyWorld()
    end
  end)

  FX.Gfx = Gfx
  table.insert(FX.Unload, function()
    conn:Disconnect()
    restoreFoliage()
    clearWeather()
    clearRain()
    boostRestore()
    for name in pairs(Objs) do drop(name) end
    releaseAll()
    if Vig.root then pcall(function() Vig.root:Destroy() end) end
    if OrigCap ~= nil and type(setfpscap) == "function" then pcall(setfpscap, OrigCap) end
    Boost.level = 0
    FX.Gfx = nil
  end)
end)()

-- ============================================================================
-- MAIN MENU UI  (same palette / fonts / shapes as the Skin Changer "unbranded" UI)
-- ============================================================================
-- The main chunk is at Luau's 200-local limit, so the whole menu is built inside its own function scope.
-- Only what the rest of the script (render loop / combat / unload) needs is declared out here.
local Menu, updateMenuScale, cleanup, CAM_STEP_NAME
local GameRadarRef, GameRadarOrig = nil, nil   -- the game's own radar GUI (for FORCE RADAR VISIBLE)
;(function()
local TweenService = game:GetService("TweenService")
local WIN_W, WIN_H = 800, 480
local HEADER_H, TOOLBAR_H, FOOTER_H = 40, 34, 24

local function uiCorner(parent, r)
  local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 4); c.Parent = parent; return c
end
local function uiStroke(parent, col, thick)
  local s = Instance.new("UIStroke"); s.Color = col or T.BORDER; s.Thickness = thick or 1
  s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = parent; return s
end
local function uiGradient(parent, c1, c2, rot)
  local g = Instance.new("UIGradient"); g.Color = ColorSequence.new(c1, c2); g.Rotation = rot or 90; g.Parent = parent; return g
end
local function uiFrame(parent, size, pos, color, name)
  local f = Instance.new("Frame"); f.BorderSizePixel = 0; f.Size = size; f.Position = pos or UDim2.fromOffset(0, 0)
  if color then f.BackgroundColor3 = color else f.BackgroundTransparency = 1 end
  if name then f.Name = name end
  f.Parent = parent
  return f
end
local function uiLabel(parent, text, textSize, color, pos, size, xAlign)
  local l = Instance.new("TextLabel"); l.BackgroundTransparency = 1; l.Font = T.FONT; l.Text = text; l.TextSize = textSize
  l.TextColor3 = color or T.TEXT; l.TextXAlignment = xAlign or Enum.TextXAlignment.Left
  l.TextTruncate = Enum.TextTruncate.AtEnd
  l.Position = pos or UDim2.fromOffset(0, 0); l.Size = size or UDim2.fromScale(1, 1); l.Parent = parent
  return l
end
local function uiButton(parent, text, size, pos, bg, border, textColor, textSize)
  local b = Instance.new("TextButton"); b.AutoButtonColor = false; b.BorderSizePixel = 0; b.Font = T.FONT
  b.Text = text; b.TextSize = textSize or 12; b.TextColor3 = textColor or T.TEXT; b.BackgroundColor3 = bg or T.CARD_ALT
  b.Size = size; b.Position = pos or UDim2.fromOffset(0, 0); b.Parent = parent
  uiCorner(b, 4)
  if border then uiStroke(b, border, 1) end
  return b
end

-- ---------------------------------------------------------------------------
-- Window
-- ---------------------------------------------------------------------------
Menu = Instance.new("Frame")
Menu.Name = "MainMenu"
Menu.Size = UDim2.fromOffset(WIN_W, WIN_H)
Menu.Position = UDim2.new(0.5, -WIN_W / 2, 0.5, -WIN_H / 2)
Menu.BackgroundColor3 = T.BG
Menu.BorderSizePixel = 0
Menu.ClipsDescendants = true
Menu.Parent = ScreenGui
uiCorner(Menu, 6)
uiStroke(Menu, T.BORDER, 1)
uiGradient(Menu, Color3.fromRGB(32, 32, 36), Color3.fromRGB(20, 20, 24), 45)

local MenuScale = Instance.new("UIScale")
MenuScale.Parent = Menu
function updateMenuScale()
  local cam = Workspace.CurrentCamera
  if not cam then return end
  local vp = cam.ViewportSize
  if vp.X > 0 and vp.Y > 0 then
    local s = math.max(0.5, math.min(1, (vp.X - 16) / WIN_W, (vp.Y - 16) / WIN_H))
    if math.abs(MenuScale.Scale - s) > 0.001 then MenuScale.Scale = s end
  end
end
updateMenuScale()

-- Header (brand + tabs + quick links)
local Header = uiFrame(Menu, UDim2.new(1, 0, 0, HEADER_H), nil, T.SIDE, "Header")
uiGradient(Header, Color3.fromRGB(28, 28, 32), Color3.fromRGB(18, 18, 22), 90)
uiFrame(Header, UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 1, -1), T.BORDER)
makeDraggable(Header, Menu, MenuScale)
uiLabel(Header, "BLOXSTRIKE", 16, T.TEXT, UDim2.fromOffset(14, 0), UDim2.fromOffset(92, HEADER_H))

local Tabs = { "COMBAT", "ESP", "CHAMS", "WORLD", "VISUALS", "GRAPHICS", "UTILITIES" }
local TabButtons, TabPages, TabCols = {}, {}, {}
local ActiveTab = Tabs[1]

local tabHolder = uiFrame(Header, UDim2.fromOffset(528, HEADER_H), UDim2.fromOffset(106, 0))
do
  local l = Instance.new("UIListLayout")
  l.FillDirection = Enum.FillDirection.Horizontal; l.Padding = UDim.new(0, 4)
  l.VerticalAlignment = Enum.VerticalAlignment.Center; l.SortOrder = Enum.SortOrder.LayoutOrder
  l.Parent = tabHolder
end

local HdrSkins = uiButton(Header, "SKINS", UDim2.fromOffset(54, 24), UDim2.new(1, -(8 + 26 + 4 + 54 + 4 + 54), 0.5, -12), T.CARD_ALT, T.BORDER_HI, T.TEXT, 12)
local HdrCases = uiButton(Header, "CASES", UDim2.fromOffset(54, 24), UDim2.new(1, -(8 + 26 + 4 + 54), 0.5, -12), T.CARD_ALT, T.GOLD, T.GOLD, 12)
local CloseBtn = uiButton(Header, "X", UDim2.fromOffset(26, 24), UDim2.new(1, -(8 + 26), 0.5, -12), T.CARD_ALT, T.BORDER, T.TEXT_DIM, 12)
trackConn(CloseBtn.Activated:Connect(function() Menu.Visible = false end))

-- Toolbar (search + settings buttons)
local Toolbar = uiFrame(Menu, UDim2.new(1, 0, 0, TOOLBAR_H), UDim2.fromOffset(0, HEADER_H))
local SearchBox = Instance.new("TextBox")
SearchBox.BackgroundColor3 = T.INPUT; SearchBox.BorderSizePixel = 0; SearchBox.Font = T.FONT
SearchBox.PlaceholderText = "Search features...  (box, fov, aimbot, smoke)"; SearchBox.PlaceholderColor3 = T.TEXT_DIM
SearchBox.Text = ""; SearchBox.TextColor3 = T.TEXT; SearchBox.TextSize = 13; SearchBox.ClearTextOnFocus = false
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.Size = UDim2.new(1, -(8 + 8 + 3 * 62 + 2 * 6 + 8), 0, 24); SearchBox.Position = UDim2.fromOffset(8, 5)
SearchBox.Parent = Toolbar
uiCorner(SearchBox, 4); uiStroke(SearchBox, T.BORDER_HI, 1)
do
  local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0, 8); p.Parent = SearchBox
end
local BtnSave = uiButton(Toolbar, "SAVE", UDim2.fromOffset(62, 24), UDim2.new(1, -(8 + 3 * 62 + 2 * 6), 0, 5), T.ACCENT_DIM, T.ACCENT, T.ACCENT, 12)
local BtnLoad = uiButton(Toolbar, "LOAD", UDim2.fromOffset(62, 24), UDim2.new(1, -(8 + 2 * 62 + 6), 0, 5), T.CARD_ALT, T.GOLD, T.GOLD, 12)
local BtnReset = uiButton(Toolbar, "RESET", UDim2.fromOffset(62, 24), UDim2.new(1, -(8 + 62), 0, 5), T.CARD_ALT, T.RED, T.RED, 12)

-- Footer (status)
local Footer = uiFrame(Menu, UDim2.new(1, 0, 0, FOOTER_H), UDim2.new(0, 0, 1, -FOOTER_H), T.SIDE)
uiFrame(Footer, UDim2.new(1, 0, 0, 1), nil, T.BORDER)
local StatusLbl = uiLabel(Footer, "READY", 12, T.TEXT_DIM, UDim2.fromOffset(12, 0), UDim2.new(0.55, 0, 1, 0))
local HintLbl = uiLabel(Footer, "", 11, T.TEXT_DIM, UDim2.new(0.5, 0, 0, 0), UDim2.new(0.5, -12, 1, 0), Enum.TextXAlignment.Right)
-- the hint follows the input devices: controller button names (Xbox / PlayStation) when a pad is connected
function InputX.RefreshHint()
  if #UserInputService:GetConnectedGamepads() > 0 then
    local bind = Config.PadMenuBind or "Select"
    local menuKey = (bind == "L3+R3") and (InputX.padName(Enum.KeyCode.ButtonL3) .. "+" .. InputX.padName(Enum.KeyCode.ButtonR3))
      or (bind == "Disabled" and "PILL" or InputX.padName(Enum.KeyCode.ButtonSelect))
    HintLbl.Text = string.format("%s: MENU   ·   %s / %s: TABS   ·   OR TAP THE PILL", menuKey,
      InputX.padName(Enum.KeyCode.ButtonL1), InputX.padName(Enum.KeyCode.ButtonR1))
  else
    HintLbl.Text = "RSHIFT / INSERT: MENU   ·   V: THIRD PERSON"
  end
end
table.insert(InputX.StyleListeners, InputX.RefreshHint)
trackConn(UserInputService.GamepadConnected:Connect(InputX.RefreshHint))
trackConn(UserInputService.GamepadDisconnected:Connect(InputX.RefreshHint))
InputX.RefreshHint()

-- Floating launcher pill (draggable; a drag does NOT toggle the menu)
local Pill = Instance.new("TextButton")
Pill.Name = "TogglePill"; Pill.Text = "BLOXSTRIKE"; Pill.Font = T.FONT; Pill.TextSize = 12; Pill.TextColor3 = T.TEXT
Pill.AutoButtonColor = false; Pill.BorderSizePixel = 0
Pill.Size = UDim2.fromOffset(104, 30); Pill.Position = UDim2.new(0, 16, 0.5, -15)
Pill.BackgroundColor3 = Color3.fromRGB(24, 24, 28); Pill.Parent = ScreenGui
uiCorner(Pill, 4); uiStroke(Pill, T.BORDER_HI, 1)
uiGradient(Pill, Color3.fromRGB(38, 38, 44), Color3.fromRGB(20, 20, 24), 90)
local pillDrag = makeDraggable(Pill, Pill)
trackConn(Pill.Activated:Connect(function()
  if pillDrag.Moved > 6 then return end
  Menu.Visible = not Menu.Visible
end))

-- ---------------------------------------------------------------------------
-- Pages / columns
-- ---------------------------------------------------------------------------
local pagesHolder = uiFrame(Menu, UDim2.new(1, 0, 1, -(HEADER_H + TOOLBAR_H + FOOTER_H)), UDim2.fromOffset(0, HEADER_H + TOOLBAR_H))

local function makeCol(page, isRight)
  local col = Instance.new("ScrollingFrame")
  col.Size = UDim2.new(0.5, -12, 1, -8)
  col.Position = isRight and UDim2.new(0.5, 4, 0, 4) or UDim2.fromOffset(8, 4)
  col.BackgroundTransparency = 1; col.BorderSizePixel = 0
  col.ScrollBarThickness = 3; col.ScrollBarImageColor3 = T.BORDER_HI
  col.AutomaticCanvasSize = Enum.AutomaticSize.Y; col.CanvasSize = UDim2.new(0, 0, 0, 0)
  col.ScrollingDirection = Enum.ScrollingDirection.Y
  col.Parent = page
  local layout = Instance.new("UIListLayout")
  layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Padding = UDim.new(0, 5); layout.Parent = col
  return col
end

for i, tabName in ipairs(Tabs) do
  local page = uiFrame(pagesHolder, UDim2.fromScale(1, 1), nil, nil, "Page_" .. tabName)
  page.Visible = (i == 1)
  TabPages[tabName] = page
  TabCols[tabName] = { Left = makeCol(page, false), Right = makeCol(page, true) }

  local tBtn = uiButton(tabHolder, tabName, UDim2.fromOffset(72, 26), nil,
    (i == 1) and T.CARD_ALT or T.SIDE, (i == 1) and T.ACCENT or T.BORDER, (i == 1) and T.TEXT or T.TEXT_DIM, 12)
  tBtn.Name = "Tab_" .. tabName
  tBtn.LayoutOrder = i
  TabButtons[tabName] = tBtn
end

local function switchTab(targetTab)
  if not TabPages[targetTab] then return end
  ActiveTab = targetTab
  for name, page in pairs(TabPages) do page.Visible = (name == targetTab) end
  for name, b in pairs(TabButtons) do
    local on = (name == targetTab)
    b.BackgroundColor3 = on and T.CARD_ALT or T.SIDE
    b.TextColor3 = on and T.TEXT or T.TEXT_DIM
    local st = b:FindFirstChildOfClass("UIStroke"); if st then st.Color = on and T.ACCENT or T.BORDER end
  end
end
for name, b in pairs(TabButtons) do
  trackConn(b.Activated:Connect(function() switchTab(name) end))
end

-- ---------------------------------------------------------------------------
-- Status bar + control registry (used by search, SAVE / LOAD / RESET and the "features on" counter)
-- ---------------------------------------------------------------------------
local Controls = {}          -- [id] = { Kind, Get, Set, Default, Counts }
local ColItems = {}          -- [column] = { { Frame, Section, Text }, ... }
local ColTab = {}            -- [column] = tab name
local ColCounter = {}        -- [column] = next LayoutOrder
local StatusHoldUntil = 0
local SettingsAutoload = false

local function refreshActiveCount()
  if os.clock() < StatusHoldUntil then return end
  local n = 0
  for _, c in pairs(Controls) do
    -- only count features the USER switched on (options that are ON by default, e.g. Team Check, are not "features")
    if c.Kind == "toggle" and c.Counts and c.Get() and not c.Default then n = n + 1 end
  end
  StatusLbl.Text = string.format("READY  ·  %d FEATURE%s ON", n, n == 1 and "" or "S")
  StatusLbl.TextColor3 = (n > 0) and T.TEXT or T.TEXT_DIM
end

local function setStatus(msg, col, hold)
  hold = hold or 2.6
  StatusHoldUntil = os.clock() + hold
  StatusLbl.Text = msg
  StatusLbl.TextColor3 = col or T.ACCENT
  task.delay(hold + 0.05, function()
    if not Unloaded then refreshActiveCount() end
  end)
end

local function registerControl(col, labelText, ctrl)
  local base = (ColTab[col] or "?") .. ":" .. labelText
  local id, n = base, 1
  while Controls[id] do n = n + 1; id = base .. " #" .. n end
  ctrl.Id = id
  Controls[id] = ctrl
end

local function nextOrder(col)
  ColCounter[col] = (ColCounter[col] or 0) + 1
  return ColCounter[col]
end

local function registerItem(col, frame, isSection, text)
  frame.LayoutOrder = nextOrder(col)
  ColItems[col] = ColItems[col] or {}
  table.insert(ColItems[col], { Frame = frame, Section = isSection, Text = string.lower(text or "") })
end

for tabName, cols in pairs(TabCols) do
  ColTab[cols.Left] = tabName
  ColTab[cols.Right] = tabName
end

-- ---------------------------------------------------------------------------
-- Widgets (same signatures as before: addSection / addToggle / addCycle / addAction)
-- ---------------------------------------------------------------------------
local ROW_H = 30

local function makeRow(col, labelText)
  local row = Instance.new("Frame")
  row.Size = UDim2.new(1, -4, 0, ROW_H); row.BackgroundColor3 = T.CARD; row.BorderSizePixel = 0; row.Parent = col
  uiCorner(row, 4); uiStroke(row, T.BORDER, 1)
  local lbl = uiLabel(row, labelText, 13, T.TEXT, UDim2.fromOffset(10, 0), UDim2.new(1, -20, 1, 0))
  return row, lbl
end

local function addSection(col, titleText)
  local sec = Instance.new("Frame")
  sec.Size = UDim2.new(1, -4, 0, 24); sec.BackgroundTransparency = 1; sec.BorderSizePixel = 0; sec.Parent = col
  uiLabel(sec, string.upper(titleText), 11, T.TEXT_DIM, UDim2.fromOffset(2, 4), UDim2.new(1, -4, 0, 16))
  uiFrame(sec, UDim2.new(1, -4, 0, 1), UDim2.new(0, 2, 1, -2), T.BORDER)
  registerItem(col, sec, true, titleText)
  return sec
end

local TOGGLE_TI = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function addToggle(col, labelText, defaultState, callback, opts)
  opts = opts or {}
  local row, lbl = makeRow(col, labelText)
  lbl.Size = UDim2.new(1, -66, 1, 0)
  local state = defaultState and true or false

  local trackF = uiFrame(row, UDim2.fromOffset(34, 18), UDim2.new(1, -44, 0.5, -9), state and T.GREEN or T.INPUT)
  uiCorner(trackF, 9)
  local trackStroke = uiStroke(trackF, state and T.GREEN or T.BORDER_HI, 1)
  local knob = uiFrame(trackF, UDim2.fromOffset(12, 12), state and UDim2.fromOffset(19, 3) or UDim2.fromOffset(3, 3), Color3.fromRGB(245, 245, 247))
  uiCorner(knob, 6)

  local function paint()
    TweenService:Create(knob, TOGGLE_TI, { Position = state and UDim2.fromOffset(19, 3) or UDim2.fromOffset(3, 3) }):Play()
    TweenService:Create(trackF, TOGGLE_TI, { BackgroundColor3 = state and T.GREEN or T.INPUT }):Play()
    trackStroke.Color = state and T.GREEN or T.BORDER_HI
  end

  local hit = Instance.new("TextButton")
  hit.Name = "Hit"; hit.BackgroundTransparency = 1; hit.Text = ""; hit.Size = UDim2.fromScale(1, 1); hit.ZIndex = 5; hit.Parent = row
  trackConn(hit.MouseEnter:Connect(function() row.BackgroundColor3 = T.CARD_ALT end))
  trackConn(hit.MouseLeave:Connect(function() row.BackgroundColor3 = T.CARD end))

  local ctrl = { Kind = "toggle", Counts = not opts.NoCount, Default = state }
  function ctrl.Get() return state end
  function ctrl.SetVisual(s)
    state = s and true or false
    paint()
    refreshActiveCount()
  end
  function ctrl.Set(s)
    ctrl.SetVisual(s)
    local ok, err = pcall(callback, state)
    if not ok then warn("[BloxStrikeSuite] toggle '" .. labelText .. "' failed: " .. tostring(err)) end
  end
  trackConn(hit.Activated:Connect(function() ctrl.Set(not state) end))

  registerItem(col, row, false, labelText)
  registerControl(col, labelText, ctrl)
  return row, ctrl.SetVisual
end

-- displayFn (optional): maps a stored option value to the text shown. Stored values never change (saved settings keep
-- working) while the label can follow e.g. the controller style (LT vs L2).
local function addCycle(col, labelText, options, defaultIndex, callback, isColor, displayFn)
  local row, lbl = makeRow(col, labelText)
  lbl.Size = UDim2.new(1, -168, 1, 0)

  local idx = 1
  if type(defaultIndex) == "string" then
    for i, o in ipairs(options) do if o == defaultIndex then idx = i; break end end
  else
    idx = math.clamp(defaultIndex or 1, 1, #options)
  end

  local area = uiFrame(row, UDim2.fromOffset(152, 22), UDim2.new(1, -158, 0.5, -11))
  local prevBtn = uiButton(area, "<", UDim2.fromOffset(22, 22), UDim2.fromOffset(0, 0), T.CARD_ALT, T.BORDER, T.TEXT_DIM, 13)
  local nextBtn = uiButton(area, ">", UDim2.fromOffset(22, 22), UDim2.fromOffset(130, 0), T.CARD_ALT, T.BORDER, T.TEXT_DIM, 13)
  local valBox = uiFrame(area, UDim2.fromOffset(102, 22), UDim2.fromOffset(25, 0), T.INPUT)
  uiCorner(valBox, 4); uiStroke(valBox, T.BORDER, 1)
  local swatch
  if isColor then
    swatch = uiFrame(valBox, UDim2.fromOffset(10, 10), UDim2.new(0, 7, 0.5, -5), ColorPalette[options[idx]] or Color3.new(1, 1, 1))
    uiCorner(swatch, 3)
  end
  local valLbl = uiLabel(valBox, displayFn and displayFn(options[idx]) or tostring(options[idx]), 12, T.ACCENT,
    UDim2.fromOffset(isColor and 20 or 4, 0), UDim2.new(1, isColor and -24 or -8, 1, 0), isColor and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center)

  local ctrl = { Kind = "cycle", Default = options[idx] }
  local function show()
    local v = options[idx]
    valLbl.Text = displayFn and displayFn(v) or tostring(v)
    if swatch and ColorPalette[v] then swatch.BackgroundColor3 = ColorPalette[v] end
  end
  local function step(delta)
    idx = ((idx - 1 + delta) % #options) + 1
    show()
    local ok, err = pcall(callback, options[idx], idx)
    if not ok then warn("[BloxStrikeSuite] option '" .. labelText .. "' failed: " .. tostring(err)) end
  end
  function ctrl.Get() return options[idx] end
  function ctrl.Set(v)
    for i, o in ipairs(options) do
      if o == v then
        if i ~= idx then idx = i; show(); pcall(callback, options[idx], idx) end
        return
      end
    end
  end
  trackConn(prevBtn.Activated:Connect(function() step(-1) end))
  trackConn(nextBtn.Activated:Connect(function() step(1) end))
  for _, b in ipairs({ prevBtn, nextBtn }) do
    trackConn(b.MouseEnter:Connect(function() b.BackgroundColor3 = T.BORDER end))
    trackConn(b.MouseLeave:Connect(function() b.BackgroundColor3 = T.CARD_ALT end))
  end

  if displayFn then table.insert(InputX.StyleListeners, show) end   -- relabel when the controller style changes
  registerItem(col, row, false, labelText)
  registerControl(col, labelText, ctrl)
  return row
end

-- Legacy accent colours passed by callers are mapped onto the theme (keeps the UI monochrome + 3 signal colours)
local function themeAccent(c)
  if typeof(c) ~= "Color3" then return T.ACCENT end
  if c == T.RED or c == T.GOLD or c == T.GREEN or c == T.ACCENT then return c end
  if c.R > 0.85 and c.G < 0.4 then return T.RED end                               -- legacy red
  if c.R > 0.85 and c.G > 0.6 and c.B < 0.45 then return T.GOLD end              -- legacy gold
  return T.ACCENT                                                                   -- everything else: neutral
end

local function addAction(col, labelText, btnText, btnColor, callback)
  local row, lbl = makeRow(col, labelText)
  lbl.Size = UDim2.new(1, -124, 1, 0)
  local accent = themeAccent(btnColor)
  local btn = uiButton(row, string.upper(btnText), UDim2.fromOffset(100, 22), UDim2.new(1, -108, 0.5, -11), T.CARD_ALT, accent, accent, 12)
  trackConn(btn.MouseEnter:Connect(function() btn.BackgroundColor3 = T.BORDER end))
  trackConn(btn.MouseLeave:Connect(function() btn.BackgroundColor3 = T.CARD_ALT end))
  trackConn(btn.Activated:Connect(function()
    task.spawn(function()
      local ok, err = pcall(callback)
      if not ok then warn("[BloxStrikeSuite] action '" .. labelText .. "' failed: " .. tostring(err)) end
    end)
  end))
  registerItem(col, row, false, labelText)
  return row
end

-- Controller-aware labels for the bind dropdowns (stored values stay "Pad: L2" etc.; only the shown text changes)
local PAD_VALUE_CODES = {
  ["Pad: L2"] = Enum.KeyCode.ButtonL2, ["Pad: R2"] = Enum.KeyCode.ButtonR2, ["Pad: L1"] = Enum.KeyCode.ButtonL1,
  ["Pad: R1"] = Enum.KeyCode.ButtonR1, ["Pad: X"] = Enum.KeyCode.ButtonX, ["Pad: Y"] = Enum.KeyCode.ButtonY,
  ["Pad: B"] = Enum.KeyCode.ButtonB, ["Pad: L3"] = Enum.KeyCode.ButtonL3, ["Pad: R3"] = Enum.KeyCode.ButtonR3,
}
local function padDisplay(v)
  local code = PAD_VALUE_CODES[v]
  if code then return "Pad: " .. InputX.padName(code) end
  if v == "Select" then return InputX.padName(Enum.KeyCode.ButtonSelect) end
  if v == "L3+R3" then return InputX.padName(Enum.KeyCode.ButtonL3) .. "+" .. InputX.padName(Enum.KeyCode.ButtonR3) end
  return v
end

-- ---------------------------------------------------------------------------
-- Search (filters rows live; hides empty sections; jumps to a tab that has matches)
-- ---------------------------------------------------------------------------
local function applySearch(query)
  local q = string.lower(query or "")
  q = (string.gsub(q, "^%s+", ""))
  q = (string.gsub(q, "%s+$", ""))
  local perTab = {}
  for tabName, cols in pairs(TabCols) do
    perTab[tabName] = 0
    for _, col in ipairs({ cols.Left, cols.Right }) do
      local items = ColItems[col] or {}
      local curSection, secMatches = nil, false
      local function closeSection()
        if curSection then curSection.Frame.Visible = (q == "") or secMatches end
      end
      for _, it in ipairs(items) do
        if it.Section then
          closeSection()
          curSection, secMatches = it, false
        else
          local match = (q == "") or (string.find(it.Text, q, 1, true) ~= nil)
          it.Frame.Visible = match
          if match then
            secMatches = true
            perTab[tabName] = perTab[tabName] + 1
          end
        end
      end
      closeSection()
    end
  end
  if q ~= "" and (perTab[ActiveTab] or 0) == 0 then
    for _, name in ipairs(Tabs) do
      if (perTab[name] or 0) > 0 then switchTab(name); break end
    end
  end
end
trackConn(SearchBox:GetPropertyChangedSignal("Text"):Connect(function() applySearch(SearchBox.Text) end))

-- ---------------------------------------------------------------------------
-- Settings (SAVE / LOAD / RESET).  Stores each control's visible value, not raw Config, so it survives future refactors.
-- ---------------------------------------------------------------------------
local SETTINGS_FILE = "BloxStrikeSuite_Settings.json"

local function saveSettings()
  if type(writefile) ~= "function" then
    setStatus("SAVE FAILED: executor has no writefile", T.RED)
    return false
  end
  local values = {}
  for id, c in pairs(Controls) do values[id] = c.Get() end
  local ok, err = pcall(function()
    writefile(SETTINGS_FILE, HttpService:JSONEncode({ Version = 1, Autoload = SettingsAutoload, Values = values }))
  end)
  if ok then
    setStatus("SETTINGS SAVED", T.GREEN)
  else
    warn("[BloxStrikeSuite] save failed:", err)
    setStatus("SAVE FAILED: " .. tostring(err), T.RED, 4)
  end
  return ok
end

local function readSettingsFile()
  if type(readfile) ~= "function" or type(isfile) ~= "function" then return nil end
  local okExists, exists = pcall(isfile, SETTINGS_FILE)
  if not (okExists and exists) then return nil end
  local okR, content = pcall(readfile, SETTINGS_FILE)
  if not (okR and type(content) == "string" and content ~= "") then return nil end
  local okD, data = pcall(function() return HttpService:JSONDecode(content) end)
  if okD and type(data) == "table" and type(data.Values) == "table" then return data end
  return nil
end

local function loadSettings(silent)
  local data = readSettingsFile()
  if not data then
    if not silent then setStatus("NO SAVED SETTINGS FOUND", T.TEXT_DIM) end
    return false
  end
  local n = 0
  for id, val in pairs(data.Values) do
    local c = Controls[id]
    if c and c.Get() ~= val then
      c.Set(val)
      n = n + 1
    end
  end
  if not silent then setStatus(("SETTINGS LOADED (%d CHANGED)"):format(n), T.GOLD) end
  refreshActiveCount()
  return true
end

local function resetSettings()
  local n = 0
  for _, c in pairs(Controls) do
    if c.Get() ~= c.Default then c.Set(c.Default); n = n + 1 end
  end
  setStatus(("RESET TO DEFAULTS (%d CHANGED)"):format(n), T.RED)
  refreshActiveCount()
end

trackConn(BtnSave.Activated:Connect(saveSettings))
trackConn(BtnLoad.Activated:Connect(function() loadSettings(false) end))
trackConn(BtnReset.Activated:Connect(resetSettings))

-- Open the Skin Changer / Case windows no matter which skin changer is loaded (standalone "unbranded" or the merged one below)
local function openSkinStudio(tab)
  local ub = _G.__Unbranded
  if ub and ub.ToggleUI then
    if ub.IsVisible and ub.GetTab and ub.IsVisible() and ub.GetTab() == tab then
      ub.ToggleUI(false)
    else
      if ub.SwitchTab then ub.SwitchTab(tab) end
      ub.ToggleUI(true)
    end
    return true
  end
  local sc = _G.__BloxStrikeSkinChanger
  if sc then
    if tab == "CASES" and sc.ToggleCasesUI then sc.ToggleCasesUI(); return true end
    if tab ~= "CASES" and sc.ToggleSkinsUI then sc.ToggleSkinsUI(); return true end
  end
  setStatus("SKIN CHANGER NOT LOADED", T.GOLD)
  return false
end
trackConn(HdrSkins.Activated:Connect(function() openSkinStudio("SKINS") end))
trackConn(HdrCases.Activated:Connect(function() openSkinStudio("CASES") end))

-- ============================================================================
-- POPULATE ALL 6 TABS
-- ============================================================================
;(function()
  local cmbL, cmbR = TabCols["COMBAT"].Left, TabCols["COMBAT"].Right
  addSection(cmbL, "AIMBOT (CAMERA ASSIST)")
  addToggle(cmbL, "ENABLE AIMBOT", Config.AimbotEnabled, function(v) Config.AimbotEnabled = v end)
  addCycle(cmbL, "AIMBOT BIND", { "Hold Aim (any)", "Hold Fire (any)", "Always", "Pad: L2", "Pad: R2", "Pad: L1", "Pad: R1", "Pad: X", "Pad: B", "Pad: L3", "Pad: R3", "Hold RMB", "Hold LMB", "Key: Alt", "Key: E" }, 1, function(v) Config.AimbotMode = v end, false, padDisplay)
  addCycle(cmbL, "AIMBOT HITBOX", { "Head", "Chest", "Nearest", "Head->Chest" }, 1, function(v) Config.AimbotHitbox = v end)
  addCycle(cmbL, "AIMBOT FOV", { "45px", "80px", "120px", "160px", "220px", "320px" }, 3, function(v)
    Config.AimbotFOV = tonumber(v:match("%d+")) or 120
  end)
  addToggle(cmbL, "SHOW AIMBOT FOV", Config.AimbotShowFOV, function(v) Config.AimbotShowFOV = v end)
  addCycle(cmbL, "FOV CIRCLE COLOR", ColorNames, 2, function(n) Config.AimbotFOVColor = ColorPalette[n] end, true)
  addCycle(cmbL, "SMOOTHING", { "1 (Snap)", "2", "4", "6", "9", "12" }, 3, function(v)
    Config.AimbotSmooth = tonumber(v:match("%d+")) or 4
  end)
  addToggle(cmbL, "STICKY TARGET", Config.AimbotSticky, function(v) Config.AimbotSticky = v end)
  addToggle(cmbL, "TEAM CHECK", Config.AimbotTeamCheck, function(v) Config.AimbotTeamCheck = v end)
  addToggle(cmbL, "TARGET AI BOTS", Config.AimbotBots, function(v) Config.AimbotBots = v end)
  addToggle(cmbL, "TARGET ZOMBIES", Config.AimbotZombies, function(v) Config.AimbotZombies = v end)
  addToggle(cmbL, "VISIBILITY CHECK", Config.AimbotVisCheck, function(v) Config.AimbotVisCheck = v end)
  addToggle(cmbL, "SMOKE CHECK", Config.AimbotSmokeCheck, function(v) Config.AimbotSmokeCheck = v end)

  addSection(cmbL, "TARGET FEEDBACK & HUD")
  addToggle(cmbL, "TARGET LOCK HUD", Config.TargetHUD, function(v) Config.TargetHUD = v end)
  addToggle(cmbL, "HITMARKER CROSSHAIR", Config.HitMarker, function(v) Config.HitMarker = v end)
  addToggle(cmbL, "HITSOUND (VALIDATED)", Config.HitSound, function(v) Config.HitSound = v end)

  addSection(cmbR, "SILENT AIM (BULLET HOOK)")
  addToggle(cmbR, "ENABLE SILENT AIM", Config.SilentAimEnabled, function(v) Config.SilentAimEnabled = v end)
  addCycle(cmbR, "SILENT HITBOX", { "Head", "Chest", "Random" }, 1, function(v) Config.SilentHitbox = v end)
  addCycle(cmbR, "SILENT FOV", { "45px", "90px", "120px", "220px", "360px" }, 3, function(v)
    Config.SilentAimFOV = tonumber(v:match("%d+")) or 120
  end)
  addToggle(cmbR, "SHOW SILENT FOV", Config.SilentShowFOV, function(v) Config.SilentShowFOV = v end)
  addCycle(cmbR, "SILENT HITCHANCE", { "100%", "85%", "70%", "50%" }, 1, function(v)
    Config.SilentHitchance = tonumber(v:match("%d+")) or 100
  end)
  addToggle(cmbR, "SILENT VIS CHECK", Config.SilentVisCheck, function(v) Config.SilentVisCheck = v end)
  addToggle(cmbR, "SILENT SMOKE CHECK", Config.SilentSmokeCheck, function(v) Config.SilentSmokeCheck = v end)

  addSection(cmbR, "WALLBANG (PENETRATION)")
  addCycle(cmbR, "WALLBANG MODE", { "Off", "Penetrable", "Full (All Walls)" }, 1, function(v) Config.WallbangMode = v end)

  addSection(cmbR, "TRIGGERBOT (AUTO SHOOT)")
  addToggle(cmbR, "ENABLE TRIGGERBOT", Config.TriggerbotEnabled, function(v) Config.TriggerbotEnabled = v end)
  addCycle(cmbR, "TRIGGER BIND", { "Always", "Hold Aim (any)", "Pad: L2", "Pad: L1", "Pad: R1", "Pad: X", "Pad: B", "Hold RMB", "Hold Alt", "Hold E" }, 1, function(v) Config.TriggerMode = v end, false, padDisplay)
  addToggle(cmbR, "TRIGGER HEAD ONLY", Config.TriggerHeadOnly, function(v) Config.TriggerHeadOnly = v end)
  addCycle(cmbR, "REACTION DELAY", { "0ms", "25ms", "60ms", "110ms" }, 2, function(v)
    Config.TriggerDelayMs = tonumber(v:match("%d+")) or 25
  end)
  addToggle(cmbR, "WAIT SPREAD SETTLE", Config.TriggerBurstMode, function(v) Config.TriggerBurstMode = v end)
  addToggle(cmbR, "IGNORE SMOKE", Config.TriggerIgnoreSmoke, function(v) Config.TriggerIgnoreSmoke = v end)
  addToggle(cmbR, "IGNORE FLASH", Config.TriggerIgnoreFlash, function(v) Config.TriggerIgnoreFlash = v end)

  addSection(cmbR, "WEAPON & RECOIL CONTROL")
  addCycle(cmbR, "RECOIL CONTROL (RCS)", { "0%", "50%", "75%", "100%" }, 1, function(v)
    Config.RecoilControlPct = tonumber(v:match("%d+")) or 0
  end)
  addToggle(cmbR, "NO CAMERA KICK", Config.NoCameraKick, function(v) Config.NoCameraKick = v end)
  addCycle(cmbR, "SPREAD REDUCTION", { "0%", "50%", "75%", "100%" }, 1, function(v)
    Config.SpreadReductionPct = tonumber(v:match("%d+")) or 0
  end)
  addToggle(cmbR, "AUTO RELOAD EMPTY", Config.AutoReload, function(v) Config.AutoReload = v end)
  addToggle(cmbR, "AUTO PISTOL (HOLD)", Config.AutoPistol, function(v) Config.AutoPistol = v end)
end)()

local espL, espR = TabCols["ESP"].Left, TabCols["ESP"].Right
addSection(espL, "PLAYER BOX & TAGS")
addToggle(espL, "MASTER ESP", Config.ESPEnabled, function(v)
  Config.ESPEnabled = v
  if not v then
    hideAllPlayerESP()
    table.clear(SoundPings)
    hideAllSoundESP()
  end
end)
addToggle(espL, "TEAM CHECK (ENEMIES)", Config.TeamCheck, function(v) Config.TeamCheck = v end)
addToggle(espL, "SHOW AI BOTS", Config.ShowBots, function(v) Config.ShowBots = v end)
addToggle(espL, "SHOW OUT-OF-RANGE PLAYERS", Config.ShowCulled, function(v) Config.ShowCulled = v end)
addCycle(espL, "GHOST LIFETIME", { "10s", "20s", "30s", "60s" }, "30s", function(v) Config.GhostMaxAge = tonumber(v:match("%d+")) or 30 end)
addToggle(espL, "BOX ESP", Config.BoxESP, function(v) Config.BoxESP = v end)
addCycle(espL, "BOX STYLE", { "Corner", "Full" }, 1, function(v) Config.BoxType = v end)
addCycle(espL, "ENEMY BOX COLOR", ColorNames, 3, function(n) Config.BoxColor = ColorPalette[n] end, true)
addCycle(espL, "GHOST COLOR", ColorNames, 6, function(n) Config.CulledColor = ColorPalette[n] end, true)
addCycle(espL, "TEAM BOX COLOR", ColorNames, 2, function(n) Config.TeamBoxColor = ColorPalette[n] end, true)
addToggle(espL, "NAME TAG", Config.NameESP, function(v) Config.NameESP = v end)
addCycle(espL, "NAME COLOR", ColorNames, 7, function(n) Config.NameColor = ColorPalette[n] end, true)
addToggle(espL, "HEALTH BAR", Config.HealthBar, function(v) Config.HealthBar = v end)
addToggle(espL, "DISTANCE TAG", Config.DistanceESP, function(v) Config.DistanceESP = v end)
addToggle(espL, "WEAPON & ARMOR", Config.WeaponESP, function(v) Config.WeaponESP = v end)
addToggle(espL, "HEAD DOT", Config.HeadDot, function(v) Config.HeadDot = v end)
addCycle(espL, "HEAD DOT COLOR", ColorNames, 3, function(n) Config.HeadDotColor = ColorPalette[n] end, true)

addSection(espL, "SOUND / STEP ESP (THRU PVS)")
addToggle(espL, "SOUND / STEP ESP", Config.SoundESP, function(v)
  Config.SoundESP = v
  if not v then
    table.clear(SoundPings)
    hideAllSoundESP()
  end
end)
addCycle(espL, "SOUND PING COLOR", ColorNames, 4, function(n) Config.SoundColor = ColorPalette[n] end, true)
addCycle(espL, "SOUND DURATION", { "1.5s", "2.5s", "4.0s", "6.0s" }, 2, function(v)
  Config.SoundMaxAge = tonumber(v:match("[%d%.]+")) or 2.5
end)

addSection(espR, "SKELETON, TRACERS & ARROWS")
addToggle(espR, "SKELETON ESP", Config.SkeletonESP, function(v) Config.SkeletonESP = v end)
addCycle(espR, "SKELETON COLOR", ColorNames, 7, function(n) Config.SkeletonColor = ColorPalette[n] end, true)
addToggle(espR, "SNAPLINES / TRACERS", Config.Tracers, function(v) Config.Tracers = v end)
addCycle(espR, "TRACER ORIGIN", { "Bottom", "Center", "Top" }, 1, function(v) Config.TracerOrigin = v end)
addCycle(espR, "TRACER COLOR", ColorNames, 3, function(n) Config.TracerColor = ColorPalette[n] end, true)
addToggle(espR, "OFFSCREEN ARROWS", Config.OffscreenArrows, function(v) Config.OffscreenArrows = v end)
addCycle(espR, "MAX DISTANCE", { "400m", "800m", "1000m", "1500m" }, 3, function(v) Config.PlayerMaxDist = tonumber(v:match("%d+")) or 1000 end)

addSection(espR, "ZOMBIES / HORDE (SURVIVAL)")
addToggle(espR, "ZOMBIE ESP", Config.ZombieESP, function(v) Config.ZombieESP = v end)
addToggle(espR, "ZOMBIE BOXES", Config.ZombieBoxes, function(v) Config.ZombieBoxes = v end)
addToggle(espR, "ZOMBIE LABELS", Config.ZombieNames, function(v) Config.ZombieNames = v end)
addCycle(espR, "ZOMBIE COLOR", ColorNames, 1, function(n) Config.ZombieColor = ColorPalette[n] end, true)
addCycle(espR, "ZOMBIE MAX DIST", { "250m", "400m", "600m", "1000m" }, 3, function(v) Config.ZombieMaxDist = tonumber(v:match("%d+")) or 600 end)

addSection(espR, "2D TACTICAL RADAR")
addToggle(espR, "RADAR ENABLED", Config.RadarEnabled, function(v) Config.RadarEnabled = v; RadarFrame.Visible = v end)
addCycle(espR, "RADAR RANGE", { "100m", "200m", "300m", "500m" }, 2, function(v)
  local n = tonumber(v:match("%d+")) or 200; Config.RadarRange = n; RadarRangeLbl.Text = n .. "M"
end)
addCycle(espR, "RADAR SIZE", { "130px", "150px", "180px" }, 2, function(v)
  local s = tonumber(v:match("%d+")) or 150; Config.RadarSize = s; RadarFrame.Size = UDim2.fromOffset(s, s)
end)
addCycle(espR, "BLIP COLOR", ColorNames, 3, function(n) Config.RadarBlipColor = ColorPalette[n] end, true)

-- TAB 2: CHAMS (MATERIAL + HIGHLIGHT)
local chL, chR = TabCols["CHAMS"].Left, TabCols["CHAMS"].Right
addSection(chL, "ENEMY MATERIAL CHAMS")
addToggle(chL, "ENEMY CHAMS", Config.EnemyChams, function(v) Config.EnemyChams = v; if not v then clearAllChams() end end)
addCycle(chL, "ENEMY MATERIAL", MaterialNames, 4, function(v) Config.EnemyMaterial = v end)
addCycle(chL, "ENEMY CHAM COLOR", ColorNames, 3, function(n) Config.EnemyChamColor = ColorPalette[n] end, true)
addToggle(chL, "ALWAYS ON TOP", Config.EnemyAlwaysOnTop, function(v) Config.EnemyAlwaysOnTop = v end)
addCycle(chL, "FILL OPACITY", { "0.35", "0.55", "0.75", "0.90" }, 2, function(v) Config.ChamFillTrans = tonumber(v) or 0.55 end)
addToggle(chL, "STRIP SKIN TEXTURES", Config.StripChamTextures, function(v) Config.StripChamTextures = v end, { NoCount = true })

addSection(chL, "ZOMBIE MATERIAL CHAMS")
addToggle(chL, "ZOMBIE CHAMS", Config.ZombieChams, function(v) Config.ZombieChams = v; if not v then clearAllChams() end end)
addCycle(chL, "ZOMBIE MATERIAL", MaterialNames, 4, function(v) Config.ZombieMaterial = v end)
addCycle(chL, "ZOMBIE CHAM COLOR", ColorNames, 1, function(n) Config.ZombieChamColor = ColorPalette[n] end, true)

addSection(chR, "LOCAL CHARACTER CHAMS")
addToggle(chR, "LOCAL CHAMS", Config.LocalChams, function(v)
  Config.LocalChams = v
  local mc = getLocalCharacter()
  if not v and mc then clearModelChams(mc) end
end)
addCycle(chR, "LOCAL MATERIAL", MaterialNames, 3, function(v) Config.LocalMaterial = v end)
addCycle(chR, "LOCAL CHAM COLOR", ColorNames, 2, function(n) Config.LocalChamColor = ColorPalette[n] end, true)

addSection(chR, "VIEWMODEL WEAPON CHAMS")
addToggle(chR, "WEAPON VIEWMODEL CHAMS", Config.WeaponChams, function(v)
  Config.WeaponChams = v
  if not v and Workspace.CurrentCamera then
    for _, ch in ipairs(Workspace.CurrentCamera:GetChildren()) do
      if ch:IsA("Model") and ch.Name ~= "ViewmodelStash" then clearModelChams(ch) end
    end
  end
end)
addCycle(chR, "WEAPON MATERIAL", MaterialNames, 3, function(v) Config.WeaponMaterial = v end)
addCycle(chR, "WEAPON CHAM COLOR", ColorNames, 6, function(n) Config.WeaponChamColor = ColorPalette[n] end, true)

-- TAB 3: WORLD & HUD
local wrL, wrR = TabCols["WORLD"].Left, TabCols["WORLD"].Right
addSection(wrL, "BOMB & WEAPON DROPS")
addToggle(wrL, "C4 BOMB ESP", Config.BombESP, function(v) Config.BombESP = v; if v then refreshWorldTagCache() end end)
addCycle(wrL, "C4 BOMB COLOR", ColorNames, 4, function(n) Config.BombColor = ColorPalette[n] end, true)
addToggle(wrL, "DROPPED WEAPONS ESP", Config.WeaponDropESP, function(v) Config.WeaponDropESP = v; if v then refreshWorldTagCache() end end)
addCycle(wrL, "WEAPON DROP COLOR", ColorNames, 7, function(n) Config.WeaponDropColor = ColorPalette[n] end, true)
addToggle(wrL, "BUY STATIONS ESP", Config.BuyStationESP, function(v) Config.BuyStationESP = v; if v then refreshWorldTagCache() end end)
addCycle(wrL, "BUY STATION COLOR", ColorNames, 2, function(n) Config.BuyStationColor = ColorPalette[n] end, true)

addSection(wrR, "TELEMETRY & GAME HUD")
addToggle(wrR, "SPEEDOMETER HUD", Config.VelocityHUD, function(v) Config.VelocityHUD = v end)
addToggle(wrR, "SPECTATOR COUNT HUD", Config.SpectatorHUD, function(v) Config.SpectatorHUD = v end)
addToggle(wrR, "C4 TIMER HUD", Config.BombTimerHUD, function(v) Config.BombTimerHUD = v end)
addToggle(wrR, "FORCE RADAR VISIBLE", Config.RadarAlwaysOn, function(v) Config.RadarAlwaysOn = v end)

-- TAB 4: VISUALS
local vsL, vsR = TabCols["VISUALS"].Left, TabCols["VISUALS"].Right
addSection(vsL, "CLEAR VISION & LIGHTING")
addToggle(vsL, "NO FLASHBANG", Config.NoFlash, function(v) Config.NoFlash = v; if v then enforceNoFlash() end end)
addToggle(vsL, "NO SMOKE VOXELS", Config.NoSmoke, function(v) Config.NoSmoke = v; enforceNoSmokeAll() end)
addToggle(vsL, "NO SCOPE VIGNETTE", Config.NoScopeOverlay, function(v) Config.NoScopeOverlay = v; enforceScopeOverlay() end)
addToggle(vsL, "NO FOG / HAZE", Config.NoFog, function(v) Config.NoFog = v; applyLightingState() end)
addToggle(vsL, "NO SHADOWS", Config.NoShadows, function(v) Config.NoShadows = v; applyLightingState() end)
addToggle(vsL, "FULLBRIGHT", Config.Fullbright, function(v) Config.Fullbright = v; applyLightingState() end)
addCycle(vsL, "TIME OF DAY", { "Default", "Dawn", "Noon", "Sunset", "Night" }, 1, function(v) Config.TimePreset = v; applyLightingState() end)

addSection(vsR, "CAMERA & CROSSHAIR")
addToggle(vsR, "CUSTOM FOV (YIELD SCOPE)", Config.FOVEnabled, function(v)
  Config.FOVEnabled = v
  if not v and Workspace.CurrentCamera then Workspace.CurrentCamera.FieldOfView = OriginalFOV end
end)
addCycle(vsR, "FOV VALUE", { "70", "80", "90", "100", "110", "120" }, 3, function(v) Config.CustomFOV = tonumber(v) or 90 end)
addToggle(vsR, "ASPECT RATIO STRETCH", Config.AspectEnabled, function(v)
  Config.AspectEnabled = v
  if CameraController and CameraController.SetAspectRatio then
    callRestored(CameraController.SetAspectRatio, v and Config.AspectRatio or 1.0)
  end
end)
addCycle(vsR, "ASPECT VALUE", { "0.65", "0.75", "0.85", "1.00" }, 4, function(v)
  Config.AspectRatio = tonumber(v) or 1.0
  if Config.AspectEnabled and CameraController and CameraController.SetAspectRatio then
    callRestored(CameraController.SetAspectRatio, Config.AspectRatio)
  end
end)
local _, setThirdPersonUI = addToggle(vsR, "THIRD PERSON [KEY: V]", Config.ThirdPerson, function(v)
  Config.ThirdPerson = v; updateThirdPersonState(v)
end)
addCycle(vsR, "3RD PERSON DIST", { "6", "8", "10", "14", "18" }, 3, function(v) Config.ThirdPersonDist = tonumber(v) or 10 end)
addToggle(vsR, "CUSTOM CROSSHAIR", Config.CrosshairEnabled, function(v) Config.CrosshairEnabled = v; syncCrosshairVisuals() end)
addCycle(vsR, "CROSSHAIR STYLE", { "Cross", "Dot" }, 1, function(v) Config.CrosshairStyle = v; syncCrosshairVisuals() end)
addCycle(vsR, "CROSSHAIR COLOR", ColorNames, 1, function(n) Config.CrosshairColor = ColorPalette[n]; syncCrosshairVisuals() end, true)
addCycle(vsR, "CROSSHAIR SIZE", { "5px", "8px", "12px", "16px" }, 2, function(v) Config.CrosshairSize = tonumber(v:match("%d+")) or 8; syncCrosshairVisuals() end)
addCycle(vsR, "CROSSHAIR GAP", { "2px", "4px", "6px", "10px" }, 2, function(v) Config.CrosshairGap = tonumber(v:match("%d+")) or 4; syncCrosshairVisuals() end)

-- TAB 5: UTILITIES
local utL, utR = TabCols["UTILITIES"].Left, TabCols["UTILITIES"].Right
addSection(utL, "MOVEMENT & ACTIONS")
addToggle(utL, "AUTO BUNNY HOP (HOLD)", Config.AutoBhop, function(v)
  Config.AutoBhop = v
  if not v and LocalCharacterMod then callRestored(LocalCharacterMod.jump, false) end
end)
addAction(utL, "THIRD PERSON QUICK", "TOGGLE", Color3.fromRGB(0, 229, 255), function()
  Config.ThirdPerson = not Config.ThirdPerson
  setThirdPersonUI(Config.ThirdPerson)
  updateThirdPersonState(Config.ThirdPerson)
end)
addAction(utL, "CLEAR ACTIVE FLASH", "CLEAR", Color3.fromRGB(0, 230, 118), function()
  if FlashEffect and FlashEffect.CancelFlash then callRestored(FlashEffect.CancelFlash) end
end)

-- ===== NEW CONTROLS: bullet tracers (VISUALS) · grenades + FPS HUD (WORLD) · controller · GRAPHICS tab =====
do
  -- ---- BULLET TRACERS (moved here from the skin changer) ----
  local trL = TabCols["VISUALS"].Left
  addSection(trL, "BULLET TRACERS")
  addToggle(trL, "BULLET TRACERS", Config.TracersEnabled, function(v) Config.TracersEnabled = v end)
  addCycle(trL, "TRACER STYLE", FX.TracerStyles or { "Laser" }, Config.TracerStyle, function(v) Config.TracerStyle = v end)
  local tracerColors = table.clone(ColorNames)
  table.insert(tracerColors, "Rainbow")
  addCycle(trL, "TRACER COLOR", tracerColors, Config.TracerColorName, function(v) Config.TracerColorName = v end, true)
  addCycle(trL, "TRACER WHO", { "All", "Mine", "Others" }, Config.TracerScope, function(v) Config.TracerScope = v end)
  addCycle(trL, "TRACER WIDTH", { "Thin", "Normal", "Thick", "Huge" }, "Normal", function(v)
    Config.TracerWidth = ({ Thin = 0.07, Normal = 0.14, Thick = 0.26, Huge = 0.45 })[v] or 0.14
  end)
  addCycle(trL, "TRACER LIFETIME", { "0.3s", "0.6s", "1.0s", "2.0s" }, "0.6s", function(v)
    Config.TracerLife = tonumber(v:match("[%d%.]+")) or 0.6
  end)
  addToggle(trL, "TRACER IMPACT SPARKS", Config.TracerImpact, function(v) Config.TracerImpact = v end, { NoCount = true })
  addAction(trL, "PREVIEW TRACER (FIRES ONE)", "FIRE", T.ACCENT, function()
    local cam = Workspace.CurrentCamera
    if not (cam and FX.Tracers) then return end
    local look = cam.CFrame.LookVector
    local a = cam.CFrame.Position + cam.CFrame.RightVector * 0.45 + look * 1.5 - cam.CFrame.UpVector * 0.35
    local was, scope = Config.TracersEnabled, Config.TracerScope
    Config.TracersEnabled = true; Config.TracerScope = "All"
    FX.Tracers.spawn(a, cam.CFrame.Position + look * 80, true)
    Config.TracersEnabled = was; Config.TracerScope = scope
  end)

  -- ---- GRENADES & HUD (WORLD tab) ----
  local wrR2 = TabCols["WORLD"].Right
  addSection(wrR2, "PERFORMANCE HUD")
  addToggle(wrR2, "FPS COUNTER (IN HUD BAR)", Config.FPSCounter, function(v) Config.FPSCounter = v end)

  -- ---- WORLD FX (sound ripples, sun, storm) ----
  addSection(wrR2, "SOUND RIPPLES")
  addToggle(wrR2, "SOUND RIPPLES (RINGS WHERE NOISE IS)", Config.SoundRipples, function(v) Config.SoundRipples = v end)
  addCycle(wrR2, "RIPPLE SOUNDS", { "All", "Footsteps" }, Config.RippleScope, function(v) Config.RippleScope = v end)
  addSection(wrR2, "SKY & STORM")
  local clockOpts = { "Default" }
  for h = 0, 22, 2 do clockOpts[#clockOpts + 1] = string.format("%02d:00", h) end
  addCycle(wrR2, "SUN POSITION", clockOpts, Config.SunClock, function(v) Config.SunClock = v end)
  addToggle(wrR2, "LIGHTNING STORM", Config.Storm, function(v) Config.Storm = v end)
  addCycle(wrR2, "STORM FREQUENCY", { "Rare", "Normal", "Violent" }, Config.StormFreq, function(v) Config.StormFreq = v end)

  -- ---- GRADIENT CHAMS + ON-HIT GHOSTS (CHAMS tab) ----
  local gradNames = FX.World and FX.World.GradNames or { "Sunset", "Ocean" }
  local gradOpts = { "Off" }
  for _, n in ipairs(gradNames) do gradOpts[#gradOpts + 1] = n end
  addSection(chR, "GRADIENT CHAMS")
  addCycle(chR, "CHAM GRADIENT", gradOpts, Config.ChamGradient, function(v)
    Config.ChamGradient = v
    if FX.World then FX.World.refreshChams() end
  end)
  addCycle(chR, "GRADIENT ANIMATION", { "Flow Up", "Flow Down", "Pulse", "Static" }, Config.ChamGradAnim, function(v) Config.ChamGradAnim = v end)
  addCycle(chR, "GRADIENT SPEED", { "Slow", "Normal", "Fast" }, Config.ChamGradSpeed, function(v) Config.ChamGradSpeed = v end)
  addSection(chR, "ON-HIT GHOST CHAMS")
  addToggle(chR, "HIT GHOSTS (FLASH WHERE YOU HIT)", Config.HitGhosts, function(v) Config.HitGhosts = v end)
  addCycle(chR, "GHOST COLORS", gradNames, Config.GhostStyle, function(v) Config.GhostStyle = v end)
  addCycle(chR, "GHOST MATERIAL", { "Neon", "ForceField", "Glass" }, Config.GhostMaterial, function(v) Config.GhostMaterial = v end)
  addCycle(chR, "GHOST LIFETIME", { "0.4s", "0.8s", "1.5s", "3.0s" }, "0.8s", function(v) Config.GhostLife = tonumber(v:match("[%d%.]+")) or 0.8 end)
  addToggle(chR, "GHOST THROUGH WALLS", Config.GhostWalls, function(v) Config.GhostWalls = v end, { NoCount = true })
  addToggle(chR, "HIT POINT FLASH", Config.GhostOrb, function(v) Config.GhostOrb = v end, { NoCount = true })
  addAction(chR, "PREVIEW GHOST (NEAREST PLAYER)", "PLAY", T.ACCENT, function()
    if not FX.World then return end
    local target
    local cam = Workspace.CurrentCamera
    local bestD
    for _, p in ipairs(getParticipants()) do
      if p ~= LocalPlayer then
        local ch = resolveParticipantCharacter(p)
        local rp = ch and (ch:FindFirstChild("HumanoidRootPart") or ch.PrimaryPart)
        if rp and cam then
          local d = (rp.Position - cam.CFrame.Position).Magnitude
          if not bestD or d < bestD then bestD, target = d, ch end
        end
      end
    end
    FX.World.makeGhost(target or getLocalCharacter())
  end)

  -- ---- KILL EFFECTS, HIT FEEDBACK, CROSSHAIR EXTRAS, VISION (VISUALS tab) ----
  local killOpts = { "Off" }
  for _, n in ipairs(FX.World and FX.World.KillNames or {}) do killOpts[#killOpts + 1] = n end
  killOpts[#killOpts + 1] = "Random"
  addSection(vsL, "KILL EFFECTS")
  addCycle(vsL, "KILL EFFECT", killOpts, Config.KillFX, function(v) Config.KillFX = v end)
  addCycle(vsL, "KILL EFFECT WHO", { "Mine", "Everyone" }, Config.KillFXWho, function(v) Config.KillFXWho = v end)
  addToggle(vsL, "HEADSHOT KILLS ONLY", Config.KillFXHeadOnly, function(v) Config.KillFXHeadOnly = v end, { NoCount = true })
  addToggle(vsL, "KILL BANNER (HEADSHOT / COMBO)", Config.KillBanner, function(v) Config.KillBanner = v end)
  addToggle(vsL, "KILL SCREEN FLASH", Config.KillFlash, function(v) Config.KillFlash = v end)
  addAction(vsL, "PREVIEW KILL EFFECT", "PLAY", T.ACCENT, function()
    if FX.World then FX.World.preview(Config.KillFX == "Off" and "Random" or Config.KillFX) end
  end)
  addSection(vsL, "HIT FEEDBACK")
  addToggle(vsL, "DAMAGE NUMBERS", Config.DamageNumbers, function(v) Config.DamageNumbers = v end)
  addCycle(vsL, "BULLET IMPACT EFFECT", { "Off", "Sparks", "Stars", "Rainbow Pop", "Ring" }, Config.ImpactFX, function(v) Config.ImpactFX = v end)
  addSection(vsR, "CROSSHAIR EXTRAS")
  addToggle(vsR, "SPREAD RING (GROWS WHEN MOVING)", Config.CrossRing, function(v) Config.CrossRing = v end)
  addToggle(vsR, "TURNS RED ON ENEMY", Config.CrossOnTarget, function(v) Config.CrossOnTarget = v end)
  addSection(vsR, "VISION MODES")
  addCycle(vsR, "VISION MODE", { "Off", "Night Vision", "Thermal" }, Config.VisionMode, function(v) Config.VisionMode = v end)

  -- ---- CONTROLLER (UTILITIES tab) ----
  local utL2 = TabCols["UTILITIES"].Left
  addSection(utL2, "CONTROLLER & TOUCH")
  addCycle(utL2, "MENU BIND (GAMEPAD)", { "Select", "L3+R3", "Disabled" }, "Select", function(v)
    Config.PadMenuBind = v
    InputX.RefreshHint()
  end, false, padDisplay)
  -- Auto = every signal Roblox gives us; Xbox / PlayStation = your choice, remembered across reloads
  addCycle(utL2, "CONTROLLER STYLE", { "Auto", "Xbox", "PlayStation" }, InputX.StyleSetting, function(v)
    InputX.setStyle(v)
    setStatus(string.format("CONTROLLER STYLE: %s  ->  SHOWING %s BUTTONS", string.upper(v), string.upper(InputX.padStyle())), T.GREEN, 4)
  end)
  addAction(utL2, "GAMEPAD STATUS", "CHECK", T.ACCENT, function()
    InputX.refreshStyle()
    local pads = UserInputService:GetConnectedGamepads()
    local mobile = (PlayerGui:FindFirstChild("MobileControlsGui") ~= nil)
    setStatus(string.format("GAMEPADS: %d  ·  SHOWING: %s (%s)  ·  TOUCH BUTTONS: %s", #pads, string.upper(InputX.padStyle()),
      InputX.StyleSetting == "Auto" and ("AUTO: " .. InputX.DetectedWhy) or "YOUR CHOICE", mobile and "FOUND" or "NONE"), T.ACCENT, 7)
  end)

  -- ---- GRAPHICS tab ----
  local gL, gR = TabCols["GRAPHICS"].Left, TabCols["GRAPHICS"].Right
  local G = FX.Gfx
  local O = G and G.Options or {}
  local function gfx(key)
    return function(v)
      Config[key] = v
      if FX.Gfx then FX.Gfx.refresh() end
    end
  end
  local withNone = function() local t = { "None" } for _, n in ipairs(ColorNames) do t[#t + 1] = n end return t end

  addSection(gL, "AMBIANCE PRESETS")
  local PRESET_NAMES = { "Default", "Cinematic", "Vibrant", "Noir", "Warm Sunset", "Cold Steel", "Cyberpunk", "Dreamy", "Horror" }
  local PRESETS = {
    ["Cinematic"] = { BRIGHTNESS = "-0.05", CONTRAST = "+0.20", SATURATION = "-0.25", BLOOM = "Soft", ["SUN RAYS"] = "Soft", ["DEPTH OF FIELD"] = "Subtle", VIGNETTE = "Medium", ["SUN TINT"] = "Orange" },
    ["Vibrant"] = { BRIGHTNESS = "+0.05", CONTRAST = "+0.10", SATURATION = "+0.50", BLOOM = "Soft", ["SUN RAYS"] = "Soft" },
    ["Noir"] = { BRIGHTNESS = "-0.05", CONTRAST = "+0.35", SATURATION = "-1.00", VIGNETTE = "Heavy" },
    ["Warm Sunset"] = { SATURATION = "+0.25", ["COLOR TINT"] = "Orange", BLOOM = "Medium", ["SUN RAYS"] = "Medium", ["SUN TINT"] = "Orange", VIGNETTE = "Light", HAZE = "1", ["ATMOSPHERE TINT"] = "Orange" },
    ["Cold Steel"] = { CONTRAST = "+0.15", SATURATION = "-0.25", ["COLOR TINT"] = "Cyan", BLOOM = "Soft", ["SUN TINT"] = "Cyan", HAZE = "1", ["ATMOSPHERE TINT"] = "Blue" },
    ["Cyberpunk"] = { CONTRAST = "+0.20", SATURATION = "+0.50", ["COLOR TINT"] = "Magenta", BLOOM = "Strong", VIGNETTE = "Medium", ["SUN TINT"] = "Purple", HAZE = "2", ["ATMOSPHERE TINT"] = "Magenta" },
    ["Dreamy"] = { BRIGHTNESS = "+0.05", SATURATION = "+0.25", BLOOM = "Dreamy", ["SUN RAYS"] = "Medium", ["DEPTH OF FIELD"] = "Subtle", HAZE = "1" },
    ["Horror"] = { BRIGHTNESS = "-0.10", CONTRAST = "+0.20", SATURATION = "-0.50", ["COLOR TINT"] = "Green", VIGNETTE = "Heavy", FOG = "Medium", HAZE = "2", ["ATMOSPHERE TINT"] = "Green" },
  }
  local PRESET_LABELS = { "BRIGHTNESS", "CONTRAST", "SATURATION", "COLOR TINT", "EXPOSURE", "BLOOM", "SUN RAYS", "DEPTH OF FIELD", "VIGNETTE",
    "SUN TINT", "FOG", "HAZE", "ATMOSPHERE TINT", "GLARE" }
  addCycle(gL, "AMBIANCE PRESET", PRESET_NAMES, "Default", function(name)
    local set = PRESETS[name] or {}
    -- start from defaults for everything a preset can touch, then apply the preset's values
    for _, label in ipairs(PRESET_LABELS) do
      local c = Controls["GRAPHICS:" .. label]
      if c then c.Set(set[label] or c.Default) end
    end
  end)

  addSection(gL, "COLOR GRADING")
  addCycle(gL, "BRIGHTNESS", O.Brightness or { "0.00" }, Config.GfxBrightness, gfx("GfxBrightness"))
  addCycle(gL, "CONTRAST", O.Contrast or { "0.00" }, Config.GfxContrast, gfx("GfxContrast"))
  addCycle(gL, "SATURATION", O.Saturation or { "0.00" }, Config.GfxSaturation, gfx("GfxSaturation"))
  addCycle(gL, "COLOR TINT", withNone(), Config.GfxTint, gfx("GfxTint"), true)
  addCycle(gL, "EXPOSURE", O.Exposure or { "0.0" }, Config.GfxExposure, gfx("GfxExposure"))

  addSection(gL, "GLOW, RAYS & DEPTH")
  addCycle(gL, "BLOOM", O.Bloom or { "Off" }, Config.GfxBloom, gfx("GfxBloom"))
  addCycle(gL, "SUN RAYS", O.SunRays or { "Off" }, Config.GfxSunRays, gfx("GfxSunRays"))
  addCycle(gL, "DEPTH OF FIELD", O.DOF or { "Off" }, Config.GfxDOF, gfx("GfxDOF"))
  addCycle(gL, "VIGNETTE", O.Vignette or { "Off" }, Config.GfxVignette, gfx("GfxVignette"))
  addCycle(gL, "SUN TINT", withNone(), Config.GfxSunTint, gfx("GfxSunTint"), true)
  addCycle(gL, "REFLECTIONS", O.Reflections or { "Default" }, Config.GfxReflections, gfx("GfxReflections"))
  addCycle(gL, "SHADOW SOFTNESS", O.ShadowSoft or { "Default" }, Config.GfxShadowSoft, gfx("GfxShadowSoft"))

  addSection(gR, "ATMOSPHERE & SKY")
  addCycle(gR, "FOG", O.Fog or { "Default" }, Config.GfxFog, gfx("GfxFog"))
  addCycle(gR, "HAZE", O.Haze or { "Default" }, Config.GfxHaze, gfx("GfxHaze"))
  addCycle(gR, "ATMOSPHERE TINT", withNone(), Config.GfxAtmoTint, gfx("GfxAtmoTint"), true)
  addCycle(gR, "GLARE", O.Glare or { "Default" }, Config.GfxGlare, gfx("GfxGlare"))
  addCycle(gR, "CLOUDS", O.Clouds or { "Default" }, Config.GfxClouds, gfx("GfxClouds"))
  addCycle(gR, "CLOUD DENSITY", O.CloudDensity or { "Default" }, Config.GfxCloudDensity, gfx("GfxCloudDensity"))
  addCycle(gR, "STARS", O.Stars or { "Default" }, Config.GfxStars, gfx("GfxStars"))
  addCycle(gR, "SUN SIZE", O.SunSize or { "Default" }, Config.GfxSunSize, gfx("GfxSunSize"))

  addSection(gR, "WATER & TERRAIN")
  addCycle(gR, "WATER WAVES", O.Waves or { "Default" }, Config.GfxWaves, gfx("GfxWaves"))
  addCycle(gR, "WATER SPEED", O.WaterSpeed or { "Default" }, Config.GfxWaterSpeed, gfx("GfxWaterSpeed"))
  addCycle(gR, "WATER TINT", withNone(), Config.GfxWaterTint, gfx("GfxWaterTint"), true)
  addCycle(gR, "WATER CLARITY", O.WaterClarity or { "Default" }, Config.GfxWaterClarity, gfx("GfxWaterClarity"))

  addSection(gR, "WEATHER & MOTION")
  addCycle(gR, "WEATHER", O.Weather or { "None" }, Config.GfxWeather, gfx("GfxWeather"))
  addCycle(gR, "WEATHER AMOUNT", O.WeatherAmount or { "Medium" }, Config.GfxWeatherAmount, gfx("GfxWeatherAmount"))
  addCycle(gR, "MOTION BLUR", O.MotionBlur or { "Off" }, Config.GfxMotionBlur, gfx("GfxMotionBlur"))

  addSection(gR, "FOLIAGE")
  addToggle(gR, "TREE SWAY (PALMS, FERNS, VINES)", Config.TreeSway, gfx("TreeSway"))
  addCycle(gR, "SWAY STRENGTH", O.SwayStrength or { "Normal" }, Config.TreeSwayStrength, gfx("TreeSwayStrength"))
  addCycle(gR, "SWAY SPEED", O.SwaySpeed or { "Normal" }, Config.TreeSwaySpeed, gfx("TreeSwaySpeed"))
  addCycle(gR, "SWAY RANGE", O.SwayRange or { "150" }, Config.TreeSwayRange, gfx("TreeSwayRange"))

  addSection(gR, "PERFORMANCE")
  addCycle(gR, "FPS BOOST", O.FPSBoost or { "Off" }, Config.FPSBoost, function(v)
    Config.FPSBoost = v
    if not FX.Gfx then return end
    local before = FX.Gfx.getFPS()
    local n = FX.Gfx.setFPSBoost(v)
    setStatus(v == "Off" and "FPS BOOST OFF: EVERYTHING RESTORED" or string.format("FPS BOOST %s: %d ITEMS OPTIMISED", string.upper(v), n), T.GREEN, 4)
    task.delay(4.2, function()
      if not Unloaded and FX.Gfx then setStatus(string.format("FPS: %d -> %d", before, FX.Gfx.getFPS()), T.ACCENT, 6) end
    end)
  end)
  addCycle(gR, "FPS CAP", O.FPSCap or { "Default" }, Config.FPSCap, function(v)
    Config.FPSCap = v
    if FX.Gfx and not FX.Gfx.setFPSCap(v) then setStatus("THIS EXECUTOR HAS NO setfpscap", T.GOLD) end
  end)
end

-- UTILITIES: settings
addSection(utL, "SETTINGS")
addToggle(utL, "AUTOLOAD SAVED SETTINGS", false, function(v) SettingsAutoload = v end, { NoCount = true })
addAction(utL, "SAVE SETTINGS", "SAVE", T.ACCENT, saveSettings)
addAction(utL, "LOAD SETTINGS", "LOAD", T.GOLD, function() loadSettings(false) end)
addAction(utL, "RESET TO DEFAULTS", "RESET", T.RED, resetSettings)

-- ---- Controller support for the menu ----
-- SELECT (or L3+R3) toggles the menu, L1 / R1 switch tabs, the d-pad / left stick moves the selection (Roblox's
-- built-in gamepad GUI navigation), A presses. The selection is parked on the active tab when the menu opens and
-- released when it closes, so the game's own gamepad controls are not fought over.
local GuiService = game:GetService("GuiService")
Config.PadMenuBind = "Select"
local function setMenuVisible(v)
  Menu.Visible = v
  if v then
    if UserInputService:GetLastInputType() == Enum.UserInputType.Gamepad1 or #UserInputService:GetConnectedGamepads() > 0 then
      pcall(function() GuiService.SelectedObject = TabButtons[ActiveTab] end)
    end
  else
    pcall(function() GuiService.SelectedObject = nil end)
  end
end

trackConn(UserInputService.InputBegan:Connect(function(inp, gpe)
  if Unloaded then return end
  -- gamepad buttons are handled even if the game "processed" them (it binds most of them to gameplay)
  if inp.UserInputType == Enum.UserInputType.Gamepad1 or inp.UserInputType == Enum.UserInputType.Gamepad2 then
    local bind = Config.PadMenuBind
    if bind == "Select" and inp.KeyCode == Enum.KeyCode.ButtonSelect then
      setMenuVisible(not Menu.Visible)
    elseif bind == "L3+R3" and (inp.KeyCode == Enum.KeyCode.ButtonL3 or inp.KeyCode == Enum.KeyCode.ButtonR3)
      and InputX.padDown(Enum.KeyCode.ButtonL3) and InputX.padDown(Enum.KeyCode.ButtonR3) then
      setMenuVisible(not Menu.Visible)
    elseif Menu.Visible and (inp.KeyCode == Enum.KeyCode.ButtonL1 or inp.KeyCode == Enum.KeyCode.ButtonR1) then
      local idx = table.find(Tabs, ActiveTab) or 1
      idx = ((idx - 1 + (inp.KeyCode == Enum.KeyCode.ButtonR1 and 1 or -1)) % #Tabs) + 1
      switchTab(Tabs[idx])
      pcall(function() GuiService.SelectedObject = TabButtons[Tabs[idx]] end)
    end
    return
  end
  if gpe then return end
  if inp.KeyCode == Enum.KeyCode.RightShift or inp.KeyCode == Enum.KeyCode.Insert then
    setMenuVisible(not Menu.Visible)
  elseif inp.KeyCode == Enum.KeyCode.V then
    Config.ThirdPerson = not Config.ThirdPerson
    setThirdPersonUI(Config.ThirdPerson)
    updateThirdPersonState(Config.ThirdPerson)
  end
end))

-- ============================================================================
-- CLEANUP / UNLOAD
-- ============================================================================
CAM_STEP_NAME = "BloxStrikeSuite_CameraStep"
local SuiteApi = nil

function cleanup()
  if Unloaded then return end
  Unloaded = true
  pcall(function() RunService:UnbindFromRenderStep(CAM_STEP_NAME) end)
  for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
  table.clear(Connections)
  -- FX modules (tracers, grenade visualizer, graphics / weather / foliage sway / FPS boost): each puts everything back
  for _, fn in ipairs(FX.Unload) do pcall(fn) end
  table.clear(FX.Unload)

  for p, _ in pairs(PlayerESPObjects) do destroyPlayerESPEntry(p) end
  for z, _ in pairs(ZombieESPObjects) do destroyZombieESPEntry(z) end
  for w, _ in pairs(WorldESPObjects) do destroyWorldESPEntry(w) end
  if SoundESPUnsub then pcall(SoundESPUnsub); SoundESPUnsub = nil end
  table.clear(SoundPings)
  for _, e in pairs(SoundESPObjects) do pcall(function() e.Holder:Destroy() end) end
  table.clear(SoundESPObjects)
  clearAllChams()

  -- put every world / camera change back exactly as we found it
  Config.NoFog = false; Config.NoShadows = false; Config.Fullbright = false; Config.TimePreset = "Default"
  Config.NoSmoke = false; Config.NoScopeOverlay = false; Config.ThirdPerson = false; Config.AutoBhop = false
  pcall(applyLightingState)
  pcall(enforceNoSmokeAll)
  pcall(enforceScopeOverlay)
  pcall(updateThirdPersonState, false)
  if GameRadarRef and GameRadarRef.Parent and GameRadarOrig ~= nil then pcall(function() GameRadarRef.Visible = GameRadarOrig end) end
  if LocalCharacterMod then callRestored(LocalCharacterMod.jump, false) end
  if Workspace.CurrentCamera then Workspace.CurrentCamera.FieldOfView = OriginalFOV end
  LocalPlayer.CameraMode = OriginalCameraMode
  LocalPlayer.CameraMinZoomDistance = OriginalMinZoom
  LocalPlayer.CameraMaxZoomDistance = OriginalMaxZoom
  if CameraController and CameraController.SetAspectRatio then callRestored(CameraController.SetAspectRatio, 1.0) end
  if ChamsFolder then pcall(function() ChamsFolder:Destroy() end) end
  if _G.__BloxStrikeCombatCleanup then
    pcall(_G.__BloxStrikeCombatCleanup)
    _G.__BloxStrikeCombatCleanup = nil
  end
  pcall(function() ScreenGui:Destroy() end)
  -- Only tear down the skin changer THIS script created (the merged one). A standalone skin changer the user loaded
  -- separately is none of our business and must survive an unload.
  if _G.__BloxStrikeMergedSkinCleanup then
    pcall(_G.__BloxStrikeMergedSkinCleanup)
    _G.__BloxStrikeMergedSkinCleanup = nil
  end
  if _G.__BloxStrikeSuite == SuiteApi then _G.__BloxStrikeSuite = nil end
end

addSection(utR, "SKINS & CASES")
addAction(utR, "SKIN CHANGER STUDIO", "OPEN", T.ACCENT, function() openSkinStudio("SKINS") end)
addAction(utR, "CASE GATHERER & OPENER", "OPEN", T.GOLD, function() openSkinStudio("CASES") end)
addToggle(utR, "SHOW SKIN / CASE DOCK", false, function(v)
  local sc = _G.__BloxStrikeSkinChanger
  if sc and sc.SetDockVisible then sc.SetDockVisible(v) end
end, { NoCount = true })

addSection(utR, "INTERFACE & LIFECYCLE")
addToggle(utR, "SHOW LAUNCHER PILL", Config.ShowTogglePill, function(v) Config.ShowTogglePill = v; Pill.Visible = v end, { NoCount = true })
addAction(utR, "UNLOAD SCRIPT CLEANLY", "UNLOAD", T.RED, cleanup)

-- Test / debug handle (also handy from other scripts)
SuiteApi = {
  Config = Config, Controls = Controls, Menu = Menu, Pill = Pill, SearchBox = SearchBox,
  SwitchTab = switchTab, Search = applySearch, Save = saveSettings, Load = loadSettings, Reset = resetSettings,
  OpenSkinStudio = openSkinStudio, SettingsFile = SETTINGS_FILE,
  Ghosts = LastKnownParticipantPos,   -- [participant] = { pos, headPos, time, source = SHOT | SOUND | nil(seen) }
  FX = FX,                            -- tracers / grenade visualizer / graphics modules (for tests)
  InputX = InputX,
}
_G.__BloxStrikeSuite = SuiteApi

-- Apply saved settings on start ONLY if the user opted in (otherwise every feature starts OFF, as before)
do
  local saved = readSettingsFile()
  if saved and saved.Autoload == true then
    SettingsAutoload = true
    loadSettings(true)
  end
end
refreshActiveCount()
end)()

-- ============================================================================
-- RENDER PIPELINE (High-Performance, Early-Exit When Disabled)
-- ============================================================================
RunService:BindToRenderStep(CAM_STEP_NAME, Enum.RenderPriority.Camera.Value + 5, function()
  if Unloaded then return end
  local cam = Workspace.CurrentCamera
  if not cam then return end
  if Config.FOVEnabled then
    local isScoped = LocalPlayer:GetAttribute("IsSniperScoped") == true or (tonumber(LocalPlayer:GetAttribute("ScopeIncrement")) or 0) > 0
    if not isScoped then cam.FieldOfView = Config.CustomFOV end
  end
  if Config.ThirdPerson or WasThirdPerson then
    stepThirdPersonVisuals(cam)
  end
end)

local LastSlowTick = 0
local LastTeleTick = 0
local LastPruneTick = 0
local AnyZombiesShown = false
local AnyWorldShown = false
local AnySoundShown = false

-- ----------------------------------------------------------------------------
-- Ghost positions for players the server stopped replicating (PVS culling).
-- The rig in _PVS_CulledCharacters is a FROZEN SHELL parked at the spawn point, so it is never used for drawing.
-- A ghost comes from the freshest REAL information we have, in this order:
--   SHOT  = exact position from a muzzle-flash + tracer pair      HEARD = footstep / sound attributed to the player
--   SEEN  = last position while the player was still replicated   SPAWN = spawn point, ONLY during buy period (+8s)
-- Anything older than Config.GhostMaxAge is dropped instead of showing a box where the player no longer is.
-- ----------------------------------------------------------------------------
local LastGameState, BuyEndedAt = nil, -1e9

local function spawnFallbackActive(now)
  return Workspace:GetAttribute("GameState") == "Buy Period" or (now - BuyEndedAt) < 8
end

local function resolveGhost(p, gen, now, spawnPos)
  local lk = LastKnownParticipantPos[p]
  if lk and (gen == nil or lk.gen == gen) then
    local age = now - (lk.time or now)
    if age <= Config.GhostMaxAge then
      local kind = (lk.source == "SHOT") and "SHOT" or (lk.isAudio and "HEARD" or "SEEN")
      return lk.pos, lk.headPos, { Kind = kind, Age = age }
    end
  end
  if typeof(spawnPos) == "Vector3" and spawnPos.Y > -400 and spawnFallbackActive(now) then
    return spawnPos, nil, { Kind = "SPAWN", Age = 0 }
  end
  return nil, nil, nil
end

local function computeBoxRect(cam, headPos, rootPos)
  local topWorld = headPos and (headPos + Vector3.new(0, 0.75, 0)) or (rootPos + Vector3.new(0, 2.95, 0))
  local botWorld = rootPos - Vector3.new(0, 2.95, 0)
  local tvp, tOn = cam:WorldToViewportPoint(topWorld)
  local bvp, bOn = cam:WorldToViewportPoint(botWorld)
  local rvp, rOn = cam:WorldToViewportPoint(rootPos)
  if (not tOn and not bOn and not rOn) or rvp.Z <= 0.1 then
    return nil
  end
  local h = math.max(math.abs(bvp.Y - tvp.Y), 10)
  local w = h * 0.62
  local topY = math.min(tvp.Y, bvp.Y)
  return { X = rvp.X - w * 0.5, Y = topY, W = w, H = h, CX = rvp.X, CY = topY + h * 0.5 }
end

trackConn(RunService.RenderStepped:Connect(function()
  if Unloaded then return end
  local cam = Workspace.CurrentCamera
  if not cam then return end

  local now = os.clock()
  if now - LastSlowTick >= 0.4 then
    LastSlowTick = now
    ParticipantsDirty = true
    updateMenuScale()
    refreshWorldTagCache()
    do -- remember when the buy period ended (spawn positions are only trustworthy until players start moving)
      local gs = Workspace:GetAttribute("GameState")
      if LastGameState == "Buy Period" and gs ~= "Buy Period" then BuyEndedAt = now end
      LastGameState = gs
    end
    if Config.NoScopeOverlay then enforceScopeOverlay() end
    if lightingFeaturesActive() then applyLightingState() end
    if Config.NoSmoke then enforceNoSmokeAll() end
    if Config.RadarAlwaysOn then
      local mg = PlayerGui:FindFirstChild("MainGui")
      local radar = mg and mg:FindFirstChild("Gameplay") and mg.Gameplay:FindFirstChild("Top") and mg.Gameplay.Top:FindFirstChild("Radar")
      if radar and radar:IsA("GuiObject") then
        if GameRadarRef ~= radar then GameRadarRef = radar; GameRadarOrig = radar.Visible end
        if not radar.Visible then radar.Visible = true end
      end
    elseif GameRadarRef then
      -- feature switched off: give the game's own radar back exactly as it was
      if GameRadarRef.Parent and GameRadarOrig ~= nil then GameRadarRef.Visible = GameRadarOrig end
      GameRadarRef, GameRadarOrig = nil, nil
    end
  end

  if now - LastPruneTick >= 1.2 then
    LastPruneTick = now
    pruneStaleChams()
  end

  if Config.NoFlash then enforceNoFlash() end
  if Config.AutoBhop then updateAutoBhop() end

  local vp = cam.ViewportSize
  local camCF = cam.CFrame
  local camPos = camCF.Position
  local myChar = getLocalCharacter()

  -- 1. PLAYERS & BOTS (ESP, Radar, Enemy Material Chams) - Only scans when enabled!
  local needPlayerLoop = Config.ESPEnabled or Config.EnemyChams or Config.RadarEnabled
  if needPlayerLoop then
    local camYaw = Config.RadarEnabled and math.atan2(-camCF.LookVector.X, -camCF.LookVector.Z) or 0
    local activeParticipants = {}
    local activeBlips = {}
    local drawOverlay = Config.ESPEnabled and (Config.BoxESP or Config.NameESP or Config.HealthBar or Config.WeaponESP or Config.DistanceESP or Config.HeadDot or Config.SkeletonESP or Config.Tracers or Config.OffscreenArrows)

    for _, p in ipairs(getParticipants()) do
      if p == LocalPlayer then continue end
      local isBot = not p:IsA("Player")
      if isBot and not Config.ShowBots then continue end

      local enemy = isEnemyParticipant(p)
      if Config.TeamCheck and not enemy then continue end

      local char, isCulled = resolveParticipantCharacter(p)
      if not isParticipantAlive(p, char) then
        if char and ModelAppliedState[char] then clearModelChams(char) end
        LastKnownParticipantPos[p] = nil
        continue
      end

      -- Enemy Material Chams (runs on live Workspace characters even if BoxESP is OFF)
      if char and Config.EnemyChams and enemy and not isCulled then
        applyModelChams(char, Config.EnemyMaterial, Config.EnemyChamColor, Config.EnemyAlwaysOnTop, Config.ChamFillTrans, true, Config.StripChamTextures)
      elseif char and ModelAppliedState[char] and (not Config.EnemyChams or not enemy or isCulled) then
        clearModelChams(char)
      end

      if isCulled and not Config.ShowCulled then continue end

      local rig = char and getRigInfo(char) or nil
      local root = rig and rig.Root
      local rootPos = (root and root.Parent and root.Position) or nil
      local headPos = (rig and rig.Head and rig.Head.Parent and rig.Head.Position) or nil
      local gen = p:GetAttribute("CharacterGeneration") or p:GetAttribute("Generation")
      local charGen = char and (char:GetAttribute("CharacterGeneration") or char:GetAttribute("Generation"))
      local spawnPos = p:GetAttribute("PresentationSpawnPosition")

      -- Reject uninitialized (0, -1000, 0) rigs
      if rootPos and rootPos.Y < -400 then
        rootPos = nil
        headPos = nil
      end

      local ghost = nil
      if char and not isCulled and rootPos then
        -- Live, replicated player: real position every frame (also remembered for when they get culled)
        LastKnownParticipantPos[p] = { pos = rootPos, headPos = headPos, gen = gen, isAudio = false, time = now }
      else
        -- Server-culled player. BUG FIX: the culled rig is a frozen shell at the spawn point; it used to be drawn
        -- whenever the last sighting was not an audio event, so boxes sat at spawn and never moved. Ghosts now come
        -- ONLY from real data (see resolveGhost).
        if not isCulled then
          if not Config.ShowCulled then continue end
          isCulled = true
        end
        rootPos, headPos, ghost = resolveGhost(p, gen, now, spawnPos)
      end

      if not rootPos then continue end

      local dist = (rootPos - camPos).Magnitude
      if dist < 3.2 or dist > Config.PlayerMaxDist then continue end

      if Config.RadarEnabled then
        local blip = getOrCreateRadarBlip(p)
        local rel = rootPos - camPos
        if rel.Magnitude <= Config.RadarRange then
          local rotX = rel.X * math.cos(camYaw) - rel.Z * math.sin(camYaw)
          local rotY = rel.X * math.sin(camYaw) + rel.Z * math.cos(camYaw)
          local rad = (Config.RadarSize * 0.5) - 8
          blip.Position = UDim2.new(0.5, (rotX / Config.RadarRange) * rad, 0.5, (rotY / Config.RadarRange) * rad)
          blip.BackgroundColor3 = isCulled and Config.CulledColor or Config.RadarBlipColor
          blip.Visible = true
          activeBlips[p] = true
        else
          blip.Visible = false
        end
      end

      if not drawOverlay then continue end
      activeParticipants[p] = true
      local esp = PlayerESPObjects[p] or createPlayerESPEntry(p)

      local col = isCulled and Config.CulledColor or (enemy and Config.BoxColor or Config.TeamBoxColor)
      if ghost and ghost.Kind ~= "SPAWN" then
        -- fade a ghost toward grey as it gets older so stale information is visibly less trustworthy
        col = col:Lerp(Color3.fromRGB(95, 95, 100), math.clamp(ghost.Age / math.max(Config.GhostMaxAge, 1), 0, 0.8))
      end
      local rect = computeBoxRect(cam, headPos, rootPos)
      if not rect then
        hidePlayerESPEntry(esp)
        if Config.OffscreenArrows and enemy then
          local rel = camCF:PointToObjectSpace(rootPos)
          local ang = math.atan2(rel.Y, rel.X)
          local dir = Vector2.new(math.cos(ang), -math.sin(ang))
          if dir.Magnitude > 0 then dir = dir.Unit end
          local radius = math.min(vp.X, vp.Y) * 0.41
          local tip = vp * 0.5 + dir * radius
          esp.Arrow.Position = UDim2.fromOffset(tip.X, tip.Y)
          esp.Arrow.Rotation = math.deg(math.atan2(dir.Y, dir.X)) + 90
          esp.Arrow.TextColor3 = col
          esp.Arrow.Visible = true
          esp.VisibleNow = true
        end
        continue
      end

      esp.VisibleNow = true
      esp.Arrow.Visible = false
      esp.Box.Visible = Config.BoxESP or Config.NameESP or Config.HealthBar or Config.WeaponESP or Config.DistanceESP
      esp.Box.Size = UDim2.fromOffset(rect.W, rect.H)
      esp.Box.Position = UDim2.fromOffset(rect.X, rect.Y)

      if Config.BoxESP then
        esp.BoxStroke.Color = col
        if Config.BoxType == "Corner" then
          esp.BoxStroke.Enabled = false
          local armX = math.clamp(rect.W * 0.28, 4, 14)
          local armY = math.clamp(rect.H * 0.22, 4, 14)
          local c = esp.Corners
          c[1].Size = UDim2.fromOffset(armX, 1.5); c[1].Position = UDim2.fromOffset(0, 0)
          c[2].Size = UDim2.fromOffset(1.5, armY); c[2].Position = UDim2.fromOffset(0, 0)
          c[3].Size = UDim2.fromOffset(armX, 1.5); c[3].Position = UDim2.fromOffset(rect.W - armX, 0)
          c[4].Size = UDim2.fromOffset(1.5, armY); c[4].Position = UDim2.fromOffset(rect.W - 1.5, 0)
          c[5].Size = UDim2.fromOffset(armX, 1.5); c[5].Position = UDim2.fromOffset(0, rect.H - 1.5)
          c[6].Size = UDim2.fromOffset(1.5, armY); c[6].Position = UDim2.fromOffset(0, rect.H - armY)
          c[7].Size = UDim2.fromOffset(armX, 1.5); c[7].Position = UDim2.fromOffset(rect.W - armX, rect.H - 1.5)
          c[8].Size = UDim2.fromOffset(1.5, armY); c[8].Position = UDim2.fromOffset(rect.W - 1.5, rect.H - armY)
          for _, cf in ipairs(c) do cf.BackgroundColor3 = col; cf.Visible = true end
        else
          esp.BoxStroke.Enabled = true
          for _, cf in ipairs(esp.Corners) do cf.Visible = false end
        end
      else
        esp.BoxStroke.Enabled = false
        for _, cf in ipairs(esp.Corners) do cf.Visible = false end
      end

      local hp = tonumber(p:GetAttribute("Health")) or (char and tonumber(char:GetAttribute("Health"))) or 100
      local maxHp = tonumber(p:GetAttribute("MaxHealth")) or (char and tonumber(char:GetAttribute("MaxHealth"))) or 100
      local hpFrac = math.clamp(maxHp > 0 and (hp / maxHp) or 1, 0, 1)
      if Config.HealthBar then
        esp.HpBg.Visible = true
        esp.HpFill.Size = UDim2.new(1, 0, hpFrac, 0)
        esp.HpFill.Position = UDim2.new(0, 0, 1 - hpFrac, 0)
        esp.HpFill.BackgroundColor3 = Color3.fromHSV(hpFrac * 0.33, 0.9, 0.95)
      else
        esp.HpBg.Visible = false
      end

      if Config.NameESP then
        local disp = p:IsA("Player") and p.DisplayName or getParticipantDisplayName(p)
        local tag = (isBot and "[BOT] " or "") .. disp
        if isCulled then
          if ghost and ghost.Kind ~= "SPAWN" then
            tag ..= string.format(" [%s %ds]", ghost.Kind, math.floor(ghost.Age + 0.5))
          elseif ghost then
            tag ..= " [SPAWN]"
          else
            tag ..= " [PVS]"
          end
        end
        if p:GetAttribute("HasDefuseKit") == true then tag ..= " [KIT]" end
        esp.NameTag.Text = tag
        esp.NameTag.TextColor3 = Config.NameColor
        esp.NameTag.Visible = true
      else
        esp.NameTag.Visible = false
      end

      local btm = {}
      if Config.WeaponESP then
        local wep = getParticipantWeaponName(p, char)
        if wep then table.insert(btm, wep) end
        local arm = getParticipantArmor(p, char)
        table.insert(btm, arm > 0 and string.format("%dHP %dAP", math.floor(hp + 0.5), arm) or string.format("%dHP", math.floor(hp + 0.5)))
      end
      if Config.DistanceESP then
        table.insert(btm, string.format("%dm", math.floor(dist + 0.5)))
      end
      if #btm > 0 then
        esp.BottomTag.Text = table.concat(btm, " | ")
        esp.BottomTag.Visible = true
      else
        esp.BottomTag.Visible = false
      end

      if Config.HeadDot and headPos then
        local hvp, hon = cam:WorldToViewportPoint(headPos)
        if hon and hvp.Z > 0 then
          local sz = math.clamp(rect.W * 0.16, 4, 9)
          esp.HeadDot.Size = UDim2.fromOffset(sz, sz)
          esp.HeadDot.Position = UDim2.fromOffset(hvp.X, hvp.Y)
          esp.HeadDot.BackgroundColor3 = Config.HeadDotColor
          esp.HeadDot.Visible = true
        else
          esp.HeadDot.Visible = false
        end
      else
        esp.HeadDot.Visible = false
      end

      if Config.SkeletonESP and rig then
        for i = 1, #SKELETON_JOINTS do
          local pair = rig.Bones[i]
          if pair and pair[1].Parent and pair[2].Parent then
            local avp, aOn = cam:WorldToViewportPoint(pair[1].Position)
            local bvp, bOn = cam:WorldToViewportPoint(pair[2].Position)
            if aOn and bOn and avp.Z > 0 and bvp.Z > 0 then
              draw2DLine(esp.Bones[i], Vector2.new(avp.X, avp.Y), Vector2.new(bvp.X, bvp.Y), Config.SkeletonColor, 1.3)
            else
              esp.Bones[i].Visible = false
            end
          else
            esp.Bones[i].Visible = false
          end
        end
      else
        for _, b in ipairs(esp.Bones) do if b.Visible then b.Visible = false end end
      end

      if Config.Tracers then
        local oy = Config.TracerOrigin == "Top" and 0 or (Config.TracerOrigin == "Center" and vp.Y * 0.5 or vp.Y)
        draw2DLine(esp.Tracer, Vector2.new(vp.X * 0.5, oy), Vector2.new(rect.CX, rect.Y + rect.H), Config.TracerColor, 1.1)
      else
        esp.Tracer.Visible = false
      end
    end

    for p, entry in pairs(PlayerESPObjects) do
      if not activeParticipants[p] then
        if p.Parent == nil then destroyPlayerESPEntry(p) else hidePlayerESPEntry(entry) end
      end
    end
    -- Hide radar blips of everyone not drawn this frame (dead / culled / out of range / filtered).
    -- Before, those blips stayed frozen on the radar at their last position.
    for p, blip in pairs(RadarBlips) do
      if not activeBlips[p] then
        if p.Parent == nil then
          pcall(function() blip:Destroy() end)
          RadarBlips[p] = nil
        else
          blip.Visible = false
        end
      end
    end
  else
    hideAllPlayerESP()
    for _, blip in pairs(RadarBlips) do blip.Visible = false end
  end

  -- 2. LOCAL & WEAPON MATERIAL CHAMS
  if Config.LocalChams and myChar then
    applyModelChams(myChar, Config.LocalMaterial, Config.LocalChamColor, false, Config.ChamFillTrans, true, Config.StripChamTextures)
  end
  if Config.WeaponChams and not Config.ThirdPerson then
    for _, camChild in ipairs(cam:GetChildren()) do
      if camChild:IsA("Model") and camChild.Name ~= "ViewmodelStash" then
        applyModelChams(camChild, Config.WeaponMaterial, Config.WeaponChamColor, false, 0.55, true, Config.StripChamTextures)
      end
    end
  end

  -- 3. ZOMBIES / HORDE ESP + MATERIAL CHAMS
  if (Config.ESPEnabled and Config.ZombieESP) or Config.ZombieChams then
    local hordeFolder = Workspace:FindFirstChild("Horde")
    local shellsFolder = Workspace:FindFirstChild("HordeShells")
    local src = hordeFolder or shellsFolder
    local activeZ = {}
    local zHlCount = 0
    if src then
      for _, z in ipairs(src:GetChildren()) do
        if z:GetAttribute("Dead") == true then
          if ModelAppliedState[z] then clearModelChams(z) end
          continue
        end
        local rig = getRigInfo(z)
        local root = rig.Root or z:FindFirstChild("Torso")
        if not root then continue end
        local dist = (root.Position - camPos).Magnitude
        if dist > Config.ZombieMaxDist then continue end
        activeZ[z] = true

        if Config.ZombieChams then
          local vis = (shellsFolder and shellsFolder:FindFirstChild(z.Name)) or z
          local allowHl = (zHlCount < 8)
          if allowHl and Config.EnemyAlwaysOnTop then zHlCount = zHlCount + 1 end
          applyModelChams(vis, Config.ZombieMaterial, Config.ZombieChamColor, Config.EnemyAlwaysOnTop, 0.65, allowHl, Config.StripChamTextures)
        end

        if Config.ESPEnabled and Config.ZombieESP then
          local ze = ZombieESPObjects[z] or createZombieESPEntry(z)
          local rect = computeBoxRect(cam, (rig.Head and rig.Head.Parent) and rig.Head.Position or nil, root.Position)
          if rect then
            ze.Box.Visible = true
            ze.Box.Size = UDim2.fromOffset(rect.W, rect.H)
            ze.Box.Position = UDim2.fromOffset(rect.X, rect.Y)
            ze.Stroke.Color = Config.ZombieColor
            ze.Stroke.Enabled = Config.ZombieBoxes
            if Config.ZombieNames then
              local zType = z:GetAttribute("Archetype") or "Zombie"
              local zHp = z:GetAttribute("Health")
              ze.Label.Text = zHp and string.format("%s %dHP [%dm]", tostring(zType), math.floor(zHp), math.floor(dist + 0.5))
                or string.format("%s [%dm]", tostring(zType), math.floor(dist + 0.5))
              ze.Label.TextColor3 = Config.ZombieColor
              ze.Label.Visible = true
            else
              ze.Label.Visible = false
            end
          else
            ze.Box.Visible = false
          end
          AnyZombiesShown = true
        end
      end
    end
    for z, entry in pairs(ZombieESPObjects) do
      if not activeZ[z] then
        if z.Parent == nil then destroyZombieESPEntry(z) else entry.Box.Visible = false end
      end
    end
  elseif AnyZombiesShown then
    AnyZombiesShown = false
    for z, entry in pairs(ZombieESPObjects) do
      if z.Parent == nil then destroyZombieESPEntry(z) else entry.Box.Visible = false end
    end
  end

  -- 4. WORLD ESP (Bomb / Weapons / Buy Stations)
  if Config.ESPEnabled and (Config.BombESP or Config.WeaponDropESP or Config.BuyStationESP) then
    local activeW = {}
    for inst, meta in pairs(TrackedWorldItems) do
      local show = (meta.Kind == "Bomb" and Config.BombESP)
        or (meta.Kind == "Weapon" and Config.WeaponDropESP)
        or (meta.Kind == "BuyStation" and Config.BuyStationESP)
      if not show or not inst.Parent then continue end
      local pos = inst:IsA("BasePart") and inst.Position or (inst:IsA("Model") and inst:GetPivot().Position)
      if not pos then continue end
      local dist = (pos - camPos).Magnitude
      if meta.Kind == "Weapon" and dist > 220 then continue end
      local p2d, on = cam:WorldToViewportPoint(pos)
      if not on or p2d.Z <= 0 then continue end

      activeW[inst] = true
      local we = WorldESPObjects[inst] or createWorldESPEntry(inst)
      local col = meta.Kind == "Bomb" and Config.BombColor
        or (meta.Kind == "BuyStation" and Config.BuyStationColor or Config.WeaponDropColor)
      we.Holder.Position = UDim2.fromOffset(p2d.X, p2d.Y)
      we.Dot.BackgroundColor3 = col
      we.Label.Text = string.format("%s [%dm]", meta.Label, math.floor(dist + 0.5))
      we.Label.TextColor3 = col
      we.Holder.Visible = true
      AnyWorldShown = true
    end
    for inst, entry in pairs(WorldESPObjects) do
      if not activeW[inst] then
        if inst.Parent == nil then destroyWorldESPEntry(inst) else entry.Holder.Visible = false end
      end
    end
  elseif AnyWorldShown then
    AnyWorldShown = false
    for inst, entry in pairs(WorldESPObjects) do
      if inst.Parent == nil then destroyWorldESPEntry(inst) else entry.Holder.Visible = false end
    end
  end

  -- 4B. SOUND / STEP ESP (Cross-Map Gunfire & Footsteps Thru Server PVS Culling)
  if Config.ESPEnabled and Config.SoundESP then
    for i = #SoundPings, 1, -1 do
      if now - SoundPings[i].time > Config.SoundMaxAge then
        table.remove(SoundPings, i)
      end
    end
    local usedCount = 0
    for _, ping in ipairs(SoundPings) do
      local dist = (ping.pos - camPos).Magnitude
      if dist <= Config.PlayerMaxDist then
        local p2d, on = cam:WorldToViewportPoint(ping.pos)
        if on and p2d.Z > 0 and usedCount < MAX_SOUND_PINGS then
          usedCount = usedCount + 1
          local se = getOrCreateSoundESPEntry(usedCount)
          local alpha = math.clamp(1 - ((now - ping.time) / math.max(Config.SoundMaxAge, 0.2)), 0.15, 1)
          local trans = 1 - alpha
          se.Holder.Position = UDim2.fromOffset(p2d.X, p2d.Y)
          se.RingStroke.Color = Config.SoundColor
          se.RingStroke.Transparency = trans
          se.Dot.BackgroundColor3 = Config.SoundColor
          se.Dot.BackgroundTransparency = trans
          se.Label.Text = string.format("[%s] %dm", ping.label, math.floor(dist + 0.5))
          se.Label.TextColor3 = Config.SoundColor
          se.Label.TextTransparency = trans
          se.Label.TextStrokeTransparency = math.clamp(0.35 + trans * 0.65, 0.35, 1)
          se.Holder.Visible = true
          se.Shown = true
        end
      end
    end
    for idx, se in pairs(SoundESPObjects) do
      if idx > usedCount and se.Shown then
        se.Shown = false
        se.Holder.Visible = false
      end
    end
    AnySoundShown = (usedCount > 0)
  elseif AnySoundShown then
    AnySoundShown = false
    table.clear(SoundPings)
    hideAllSoundESP()
  end

  -- 5. TELEMETRY BAR (20Hz update, zero work when all 3 toggles are OFF)
  if Config.VelocityHUD or Config.SpectatorHUD or Config.BombTimerHUD or Config.FPSCounter then
    if now - LastTeleTick >= 0.05 then
      LastTeleTick = now
      local segs = {}
      if Config.FPSCounter and FX.Gfx then
        table.insert(segs, string.format("%d FPS", FX.Gfx.getFPS()))
      end
      if Config.VelocityHUD then
        local speed = 0
        local onG = true
        if myChar and RuntimeKinematics then
          local pp = myChar:FindFirstChild("HumanoidRootPart") or myChar.PrimaryPart
          local okV, vel = callRestored(RuntimeKinematics.getVelocity, myChar, pp)
          if okV and typeof(vel) == "Vector3" then speed = Vector3.new(vel.X, 0, vel.Z).Magnitude end
          local okG, g = callRestored(RuntimeKinematics.isOnGround, myChar)
          if okG then onG = g end
        end
        local hammer = math.floor(speed / HAMMER_UNIT_TO_STUD + 0.5)
        table.insert(segs, string.format("%d u/s (%.1f) %s", hammer, speed, onG and "GND" or "AIR"))
      end
      if Config.SpectatorHUD then
        table.insert(segs, string.format("SPEC:%d", tonumber(LocalPlayer:GetAttribute("Spectators")) or 0))
      end
      if Config.BombTimerHUD and BombPlantedAt then
        local left = math.max(0, 40 - (os.clock() - BombPlantedAt))
        local need = LocalPlayer:GetAttribute("HasDefuseKit") == true and 5 or 10
        table.insert(segs, string.format("C4:%.1fs%s", left, left >= need and "" or "!"))
      end
      local text = table.concat(segs, " | ")
      if TelemetryText.Text ~= text then TelemetryText.Text = text end
      TelemetryBar.Visible = (#segs > 0)
    end
  elseif TelemetryBar.Visible then
    TelemetryBar.Visible = false
  end
end))

-- Event-driven smoke suppression on Workspace.Debris.
-- Smoke voxels/emitters keep being ADDED to the VoxelSmoke_ folder while the smoke expands, so every new
-- descendant is hidden too (before, only what existed at spawn time was hidden and the smoke "filled in" visibly).
local HookedSmokeFolders = setmetatable({}, { __mode = "k" })
local function hookSmokeFolder(c)
  if HookedSmokeFolders[c] then return end
  HookedSmokeFolders[c] = true
  trackConn(c.DescendantAdded:Connect(function(d)
    if Unloaded or not Config.NoSmoke then return end
    task.defer(function()
      if d.Parent and Config.NoSmoke then applySmokeInstance(d, true) end
    end)
  end))
  if Config.NoSmoke then
    task.defer(function()
      if c.Parent and Config.NoSmoke then applySmokeFolderState(c, true) end
    end)
  end
end

local function hookDebris(folder)
  trackConn(folder.ChildAdded:Connect(function(c)
    if not Unloaded and string.sub(c.Name, 1, 11) == "VoxelSmoke_" then hookSmokeFolder(c) end
  end))
  for _, c in ipairs(folder:GetChildren()) do
    if string.sub(c.Name, 1, 11) == "VoxelSmoke_" then hookSmokeFolder(c) end
  end
end

local DebrisFolder = Workspace:FindFirstChild("Debris")
if DebrisFolder then hookDebris(DebrisFolder) end
-- Debris can be (re)created by the game after we loaded
trackConn(Workspace.ChildAdded:Connect(function(c)
  if not Unloaded and c.Name == "Debris" then hookDebris(c) end
end))

-- ============================================================================
-- COMBAT ENGINE (Aimbot, Silent Aim, Wallbang, Triggerbot, RCS/NoSpread, HUD)
-- ============================================================================
;(function()
  local SoundService = game:GetService("SoundService")
  local InventoryController = safeRequire(ControllersFolder and ControllersFolder:FindFirstChild("InventoryController"))
  local BulletsParent = ReplicatedStorage:FindFirstChild("Components") and ReplicatedStorage.Components:FindFirstChild("Weapon")
  local BulletMod = safeRequire(BulletsParent and BulletsParent:FindFirstChild("Classes") and BulletsParent.Classes:FindFirstChild("Bullet"))
  local SoundClass = safeRequire(ReplicatedStorage:FindFirstChild("Classes") and ReplicatedStorage.Classes:FindFirstChild("Sound"))

  local AIM_STEP_NAME = "BloxStrikeSuite_CombatAim"
  local combatConns = {}
  local function trackCombat(c)
    if c then table.insert(combatConns, c) end
    return c
  end

  local MAT_PEN = {
    [Enum.Material.Plastic] = 10,
    [Enum.Material.SmoothPlastic] = 10,
    [Enum.Material.Wood] = 10,
    [Enum.Material.WoodPlanks] = 10,
    [Enum.Material.Cardboard] = 10,
    [Enum.Material.Glass] = 25,
    [Enum.Material.Fabric] = 25,
  }

  local function isPartIgnoredForTrace(part)
    if not part or not part:IsA("BasePart") then return true end
    if part.Name == "CollisionCapsule" or part.Name == "HumanoidRootPart" then return true end
    if part:FindFirstAncestorWhichIsA("Accessory") ~= nil or part:HasTag("CharacterAccessory") then return true end
    if not part.CanCollide and part.Transparency >= 0.98 then return true end
    return false
  end

  local function rayIntersectsAABB(ro, rd, bMin, bMax, maxDist)
    local tmin, tmax = 0, maxDist
    for _, axis in ipairs({ "X", "Y", "Z" }) do
      local o, d, mn, mx = ro[axis], rd[axis], bMin[axis], bMax[axis]
      if math.abs(d) < 0.0001 then
        if o < mn or o > mx then return false end
      else
        local inv = 1 / d
        local t1 = (mn - o) * inv
        local t2 = (mx - o) * inv
        if t1 > t2 then t1, t2 = t2, t1 end
        if t1 > tmin then tmin = t1 end
        if t2 < tmax then tmax = t2 end
        if tmax < tmin then return false end
      end
    end
    return tmin <= tmax and tmin >= 0 and tmin <= maxDist
  end

  local function isRayBlockedBySmoke(p1, p2)
    local debris = Workspace:FindFirstChild("Debris")
    if not debris then return false end
    local delta = p2 - p1
    local dist = delta.Magnitude
    if dist < 0.1 then return false end
    local dir = delta / dist
    for _, folder in ipairs(debris:GetChildren()) do
      if folder:IsA("Folder") and string.sub(folder.Name, 1, 11) == "VoxelSmoke_" then
        for _, vox in ipairs(folder:GetChildren()) do
          if vox:IsA("BasePart") and vox.Name == "SmokeVoxel" then
            local half = vox.Size * 0.5
            local vp = vox.Position
            if rayIntersectsAABB(p1, dir, vp - half, vp + half, dist) then
              return true
            end
          end
        end
      end
    end
    return false
  end

  local function buildBaseExcludeList()
    local excl = {}
    local mc = getLocalCharacter()
    if mc then table.insert(excl, mc) end
    if Workspace.CurrentCamera then table.insert(excl, Workspace.CurrentCamera) end
    local mp = Workspace:FindFirstChild("Map")
    local bar = mp and mp:FindFirstChild("Barriers")
    if bar then table.insert(excl, bar) end
    local deb = Workspace:FindFirstChild("Debris")
    if deb then table.insert(excl, deb) end
    return excl
  end

  -- Wallbang-aware LOS check (supports Off, Penetrable surfaces/doors, or Full All Walls)
  local function canHitTarget(origin, targetPos, targetModel, checkVis, checkSmoke, weaponPen)
    if checkSmoke and isRayBlockedBySmoke(origin, targetPos) then
      return false, false
    end
    if Config.WallbangMode == "Full (All Walls)" then
      return true, true
    end
    if not checkVis then
      return true, false
    end

    local excl = buildBaseExcludeList()
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.CollisionGroup = "Bullet"
    rp.FilterDescendantsInstances = excl

    local penDepths = {}
    local cur = origin
    local maxBudget = weaponPen or 0.65
    local penetrated = false

    for _ = 1, 8 do
      local rem = targetPos - cur
      local remDist = rem.Magnitude
      if remDist < 0.35 then
        return true, penetrated
      end
      local hit = Workspace:Raycast(cur, rem, rp)
      if not hit then
        return true, penetrated
      end
      local inst = hit.Instance
      if targetModel and (inst == targetModel or inst:IsDescendantOf(targetModel)) then
        return true, penetrated
      end
      if isPartIgnoredForTrace(inst) then
        table.insert(excl, inst)
        rp.FilterDescendantsInstances = excl
        continue
      end
      if Config.WallbangMode ~= "Penetrable" then
        return false, false
      end

      -- Measure wall thickness via reverse raycast on the single hit part
      local dir = rem / remDist
      local inc = RaycastParams.new()
      inc.FilterType = Enum.RaycastFilterType.Include
      inc.CollisionGroup = "Bullet"
      inc.FilterDescendantsInstances = { inst }
      local backStart = hit.Position + dir * 250
      local exitHit = Workspace:Raycast(backStart, hit.Position - backStart, inc)
      if not exitHit then
        return false, false
      end
      local thickness = (hit.Position - exitHit.Position).Magnitude
      local mat = (inst.Parent and inst.Parent:HasTag("BreakableDoor")) and Enum.Material.Metal or inst.Material
      local matAllow = (inst:HasTag("BreakableGlass") or (inst.Parent and inst.Parent:HasTag("BreakableGlass"))) and 25 or (MAT_PEN[mat] or 0)
      penDepths[mat] = (penDepths[mat] or 0) + thickness
      if penDepths[mat] > matAllow + maxBudget then
        return false, false
      end

      penetrated = true
      table.insert(excl, inst)
      rp.FilterDescendantsInstances = excl
      cur = exitHit.Position + dir * 0.05
    end
    return false, false
  end

  local function traceBulletHitsForSilent(origin, dir, range, weaponPen)
    local excl = buildBaseExcludeList()
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.CollisionGroup = "Bullet"
    rp.FilterDescendantsInstances = excl

    local penDepths = {}
    local hits = {}
    local cur = origin
    local maxRange = range or 1000
    local firstDist = maxRange

    for step = 1, 12 do
      local rem = maxRange - (cur - origin):Dot(dir)
      if rem <= 0.1 then break end
      local h = Workspace:Raycast(cur, dir * rem, rp)
      if not h then break end
      local inst = h.Instance
      if isPartIgnoredForTrace(inst) then
        table.insert(excl, inst)
        rp.FilterDescendantsInstances = excl
      else
        if step == 1 then firstDist = (h.Position - origin).Magnitude end
        local mat = (inst.Parent and inst.Parent:HasTag("BreakableDoor")) and Enum.Material.Metal or inst.Material
        table.insert(hits, {
          Position = h.Position,
          Instance = inst,
          Material = mat.Name,
          Normal = h.Normal or Vector3.zero,
          Exit = false,
        })
        table.insert(excl, inst)
        rp.FilterDescendantsInstances = excl

        if Config.WallbangMode == "Full (All Walls)" then
          -- Continue ray through wall geometry visually until character/limit
          local inc = RaycastParams.new()
          inc.FilterType = Enum.RaycastFilterType.Include
          inc.CollisionGroup = "Bullet"
          inc.FilterDescendantsInstances = { inst }
          local backStart = h.Position + dir * 250
          local ex = Workspace:Raycast(backStart, h.Position - backStart, inc)
          if ex then
            table.insert(hits, {
              Position = ex.Position,
              Instance = inst,
              Material = mat.Name,
              Normal = ex.Normal or Vector3.zero,
              Exit = true,
            })
            cur = ex.Position + dir * 0.05
          else
            break
          end
        else
          local inc = RaycastParams.new()
          inc.FilterType = Enum.RaycastFilterType.Include
          inc.CollisionGroup = "Bullet"
          inc.FilterDescendantsInstances = { inst }
          local backStart = h.Position + dir * 250
          local ex = Workspace:Raycast(backStart, h.Position - backStart, inc)
          if not ex then break end
          local thickness = (h.Position - ex.Position).Magnitude
          local matAllow = (inst:HasTag("BreakableGlass") or (inst.Parent and inst.Parent:HasTag("BreakableGlass"))) and 25 or (MAT_PEN[mat] or 0)
          penDepths[mat] = (penDepths[mat] or 0) + thickness
          if penDepths[mat] > matAllow + (weaponPen or 0.65) then
            break
          end
          table.insert(hits, {
            Position = ex.Position,
            Instance = inst,
            Material = mat.Name,
            Normal = ex.Normal or Vector3.zero,
            Exit = true,
          })
          cur = ex.Position + dir * 0.05
        end
      end
    end
    return hits, firstDist
  end

  local function getBonePart(char, boneMode, cam, center2D)
    if not char then return nil end
    local head = char:FindFirstChild("Head")
    local chest = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
    if boneMode == "Head" then
      return (head and head:IsA("BasePart")) and head or chest
    elseif boneMode == "Chest" then
      return (chest and chest:IsA("BasePart")) and chest or head
    elseif boneMode == "Random" then
      if head and chest then
        return (math.random(1, 100) <= 65) and head or chest
      end
      return head or chest
    elseif boneMode == "Nearest" then
      local bestPart, bestPx = nil, math.huge
      for _, bn in ipairs({ "Head", "UpperTorso", "Torso", "HumanoidRootPart", "LowerTorso" }) do
        local bp = char:FindFirstChild(bn)
        if bp and bp:IsA("BasePart") then
          local vp2, on = cam:WorldToViewportPoint(bp.Position)
          if on and vp2.Z > 0 then
            local d = (Vector2.new(vp2.X, vp2.Y) - center2D).Magnitude
            if d < bestPx then bestPx = d; bestPart = bp end
          end
        end
      end
      return bestPart or head or chest
    end
    return head or chest
  end

  local StickyTarget = nil
  local function getEquippedWeapon()
    if not InventoryController or type(InventoryController.peekCurrentEquippedForMovement) ~= "function" then
      return nil
    end
    local ok, eq = pcall(InventoryController.peekCurrentEquippedForMovement)
    if ok and type(eq) == "table" and not eq.IsDestroyed and eq.IsEquipped and eq.Properties and eq.Properties.Class == "Weapon" then
      return eq
    end
    return nil
  end

  local function selectCombatTarget(cam, fovPx, hitMode, visCheck, smokeCheck, teamCheck, useBots, useZombies, allowSticky)
    local vp = cam.ViewportSize
    local center = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
    local camPos = cam.CFrame.Position
    local eq = getEquippedWeapon()
    local weaponPen = (eq and eq.Properties and eq.Properties.Penetration) or 0.65
    local maxRange = (eq and eq.Properties and eq.Properties.Range) or 1000
    local now = os.clock()

    local best = nil
    local bestScore = math.huge

    local function considerCandidate(entity, model, pos, name, hp, weapon, isCulled)
      if not pos or pos.Y < -400 then return end
      local dist3D = (pos - camPos).Magnitude
      if dist3D < 1.5 or dist3D > maxRange then return end
      local sp, onScr = cam:WorldToViewportPoint(pos)
      if not onScr or sp.Z <= 0.1 then return end
      local pxDist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
      if pxDist > fovPx then return end

      local okHit, isWb = canHitTarget(camPos, pos, model, visCheck, smokeCheck, weaponPen)
      if not okHit then return end

      local score = pxDist
      if allowSticky and StickyTarget and StickyTarget == entity then
        score = score * 0.68
      end
      if score < bestScore then
        bestScore = score
        best = {
          entity = entity,
          model = model,
          pos = pos,
          screenPos = Vector2.new(sp.X, sp.Y),
          dist = dist3D,
          hp = hp,
          name = name,
          weapon = weapon,
          isWallbang = isWb or isCulled,
        }
      end
    end

    for _, p in ipairs(getParticipants()) do
      if p == LocalPlayer then continue end
      local isBot = not p:IsA("Player")
      if isBot and not useBots then continue end
      if teamCheck and not isEnemyParticipant(p) then continue end
      local char, isCulled = resolveParticipantCharacter(p)
      if not isParticipantAlive(p, char) then continue end

      local hp = tonumber(p:GetAttribute("Health")) or (char and tonumber(char:GetAttribute("Health"))) or 100
      local dname = getParticipantDisplayName(p)
      local wep = getParticipantWeaponName(p, char) or ""

      if char and not isCulled then
        local part = nil
        if hitMode == "Head->Chest" then
          local head = char:FindFirstChild("Head")
          if head and head:IsA("BasePart") and canHitTarget(camPos, head.Position, char, visCheck, smokeCheck, weaponPen) then
            part = head
          else
            part = getBonePart(char, "Chest", cam, center)
          end
        else
          part = getBonePart(char, hitMode, cam, center)
        end
        if part then
          considerCandidate(p, char, part.Position, dname, hp, wep, false)
        end
      elseif Config.WallbangMode == "Full (All Walls)" then
        local lk = LastKnownParticipantPos[p]
        if lk and lk.pos and (now - (lk.time or 0) <= 1.2) then
          local adjY = (hitMode == "Chest") and 0.4 or 1.45
          considerCandidate(p, char, lk.pos + Vector3.new(0, adjY, 0), dname, hp, wep, true)
        end
      end
    end

    if useZombies then
      local horde = Workspace:FindFirstChild("Horde") or Workspace:FindFirstChild("HordeShells")
      if horde then
        for _, z in ipairs(horde:GetChildren()) do
          if z:GetAttribute("Dead") == true then continue end
          local rig = getRigInfo(z)
          local bone = getBonePart(z, (hitMode == "Head->Chest" and "Head" or hitMode), cam, center) or rig.Root
          if bone then
            local zhp = tonumber(z:GetAttribute("Health")) or 100
            considerCandidate(z, z, bone.Position, tostring(z:GetAttribute("Archetype") or "Zombie"), zhp, "Horde", false)
          end
        end
      end
    end

    return best
  end

  local PAD_MODE_CODES = {
    ["Pad: L2"] = Enum.KeyCode.ButtonL2, ["Pad: R2"] = Enum.KeyCode.ButtonR2,
    ["Pad: L1"] = Enum.KeyCode.ButtonL1, ["Pad: R1"] = Enum.KeyCode.ButtonR1,
    ["Pad: X"] = Enum.KeyCode.ButtonX, ["Pad: Y"] = Enum.KeyCode.ButtonY, ["Pad: B"] = Enum.KeyCode.ButtonB,
    ["Pad: L3"] = Enum.KeyCode.ButtonL3, ["Pad: R3"] = Enum.KeyCode.ButtonR3,
  }

  local function isInputModeHeld(mode)
    if mode == "Always" then return true end
    -- "Hold Aim / Hold Fire (any)" = mouse button OR gamepad trigger OR the on-screen touch button.
    -- The old "Hold RMB / Hold LMB" entries keep working (saved settings) and now include the other devices too.
    if mode == "Hold Aim (any)" or mode == "Hold RMB" then return InputX.aim() end
    if mode == "Hold Fire (any)" or mode == "Hold LMB" then return InputX.fire() end
    local padCode = PAD_MODE_CODES[mode]
    if padCode then return InputX.padDown(padCode) end
    -- "Key: X" is used by the aimbot dropdown, "Hold X" by the triggerbot dropdown - accept both spellings
    if mode == "Key: Alt" or mode == "Hold Alt" then return UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt) end
    if mode == "Key: E" or mode == "Hold E" then return UserInputService:IsKeyDown(Enum.KeyCode.E) end
    return false
  end

  -- Combat Screen Overlays (FOV rings, Target Lock HUD, Hitmarker Crosshair, HitSound)
  local AimRing = Instance.new("Frame", ScreenGui)
  AimRing.Name = "CombatAimFOV"; AimRing.AnchorPoint = Vector2.new(0.5, 0.5)
  AimRing.BackgroundTransparency = 1; AimRing.Visible = false; AimRing.ZIndex = 40
  Instance.new("UICorner", AimRing).CornerRadius = UDim.new(1, 0)
  local AimRingStroke = Instance.new("UIStroke", AimRing)
  AimRingStroke.Thickness = 1.3; AimRingStroke.Transparency = 0.25

  local SilentRing = Instance.new("Frame", ScreenGui)
  SilentRing.Name = "CombatSilentFOV"; SilentRing.AnchorPoint = Vector2.new(0.5, 0.5)
  SilentRing.BackgroundTransparency = 1; SilentRing.Visible = false; SilentRing.ZIndex = 39
  Instance.new("UICorner", SilentRing).CornerRadius = UDim.new(1, 0)
  local SilentRingStroke = Instance.new("UIStroke", SilentRing)
  SilentRingStroke.Thickness = 1.1; SilentRingStroke.Color = Color3.fromRGB(255, 160, 40); SilentRingStroke.Transparency = 0.35

  local TargetCard = Instance.new("Frame", ScreenGui)
  TargetCard.Name = "CombatTargetHUD"; TargetCard.AnchorPoint = Vector2.new(0.5, 0)
  TargetCard.Size = UDim2.fromOffset(260, 26); TargetCard.BackgroundColor3 = T.SIDE
  TargetCard.BackgroundTransparency = 0.15; TargetCard.BorderSizePixel = 0; TargetCard.Visible = false; TargetCard.ZIndex = 42
  Instance.new("UICorner", TargetCard).CornerRadius = UDim.new(0, 5)
  local TargetCardStroke = Instance.new("UIStroke", TargetCard)
  TargetCardStroke.Color = T.GREEN; TargetCardStroke.Thickness = 1
  local TargetCardLbl = Instance.new("TextLabel", TargetCard)
  TargetCardLbl.Size = UDim2.fromScale(1, 1); TargetCardLbl.BackgroundTransparency = 1
  TargetCardLbl.Font = T.FONT; TargetCardLbl.TextSize = 14
  TargetCardLbl.TextColor3 = T.TEXT; TargetCardLbl.ZIndex = 43

  local HitCross = Instance.new("Frame", ScreenGui)
  HitCross.Name = "CombatHitMarker"; HitCross.AnchorPoint = Vector2.new(0.5, 0.5)
  HitCross.Size = UDim2.fromOffset(24, 24); HitCross.BackgroundTransparency = 1
  HitCross.Visible = false; HitCross.ZIndex = 45
  local hitTicks = {}
  local tickSpecs = {
    { pos = UDim2.new(0.5, -6, 0.5, -6), rot = -45 },
    { pos = UDim2.new(0.5, 6, 0.5, -6), rot = 45 },
    { pos = UDim2.new(0.5, -6, 0.5, 6), rot = 45 },
    { pos = UDim2.new(0.5, 6, 0.5, 6), rot = -45 },
  }
  for _, spec in ipairs(tickSpecs) do
    local t = Instance.new("Frame", HitCross)
    t.AnchorPoint = Vector2.new(0.5, 0.5); t.Size = UDim2.fromOffset(2, 7)
    t.Position = spec.pos; t.Rotation = spec.rot
    t.BorderSizePixel = 0; t.BackgroundColor3 = Color3.new(1, 1, 1); t.ZIndex = 46
    table.insert(hitTicks, t)
  end

  local HitSoundInst = Instance.new("Sound", ScreenGui)
  HitSoundInst.Name = "CombatHitSound"; HitSoundInst.SoundId = "rbxassetid://4817809188"; HitSoundInst.Volume = 0.65

  local hitFlashUntil = 0
  local hitFlashColor = Color3.new(1, 1, 1)

  local function triggerHitFeedback(col)
    if Config.HitMarker then
      hitFlashColor = col or Color3.new(1, 1, 1)
      hitFlashUntil = os.clock() + 0.22
      for _, t in ipairs(hitTicks) do t.BackgroundColor3 = hitFlashColor; t.BackgroundTransparency = 0 end
      HitCross.Visible = true
    end
    if Config.HitSound then
      local played = false
      if HitSoundInst.IsLoaded then
        played = pcall(function() SoundService:PlayLocalSound(HitSoundInst) end)
      end
      if not played and SoundClass then
        pcall(function()
          SoundClass.new("Other"):play({ Parent = PlayerGui, Name = "Toggle Scope" })
        end)
      end
    end
  end

  if Remotes and Remotes.VFX and Remotes.VFX.CreateImpact and type(Remotes.VFX.CreateImpact.Listen) == "function" then
    local okImp, unImp = pcall(Remotes.VFX.CreateImpact.Listen, function(data)
      if Unloaded or (not Config.HitMarker and not Config.HitSound) or type(data) ~= "table" then return end
      if tostring(data.AttackerUserId) == tostring(LocalPlayer.UserId) and not data.Exit then
        if data.Material == "Blood Splatter" or data.WasHelmetHeadshot or data.IsWallbang then
          local c = data.WasHelmetHeadshot and Color3.fromRGB(255, 65, 65) or (data.IsWallbang and Color3.fromRGB(255, 200, 40) or Color3.new(1, 1, 1))
          triggerHitFeedback(c)
        end
      end
    end)
    if okImp and type(unImp) == "function" then
      trackCombat({ Disconnect = function() pcall(unImp) end })
    end
  end
  if Remotes and Remotes.UI and Remotes.UI.UIPlayerKilled and type(Remotes.UI.UIPlayerKilled.Listen) == "function" then
    local okKill, unKill = pcall(Remotes.UI.UIPlayerKilled.Listen, function(data)
      if Unloaded or (not Config.HitMarker and not Config.HitSound) or type(data) ~= "table" then return end
      if data.Killer == LocalPlayer.Name or data.KillerUserId == LocalPlayer.UserId then
        triggerHitFeedback(Color3.fromRGB(255, 215, 0))
      end
    end)
    if okKill and type(unKill) == "function" then
      trackCombat({ Disconnect = function() pcall(unKill) end })
    end
  end

  -- Safe CameraController & Bullet Hooks (zero Weapon.Properties mutation!)
  local origSetWeaponRecoil = CameraController and CameraController.setWeaponRecoil
  local origWeaponKick = CameraController and CameraController.weaponKick
  local origGetTrueSpread = BulletMod and BulletMod.getTrueSpread
  local origPerformRaycast = BulletMod and BulletMod._performRaycast

  if CameraController and type(origSetWeaponRecoil) == "function" then
    CameraController.setWeaponRecoil = function(tbl, camScale, ...)
      if not Unloaded and Config.RecoilControlPct > 0 and type(tbl) == "table" and typeof(tbl.Value) == "Vector3" then
        local mult = math.clamp(1 - Config.RecoilControlPct * 0.01, 0, 1)
        tbl = { Value = tbl.Value * mult, Damper = tbl.Damper, Speed = tbl.Speed }
        if type(camScale) == "number" then camScale = camScale * mult end
      end
      return origSetWeaponRecoil(tbl, camScale, ...)
    end
  end

  if CameraController and type(origWeaponKick) == "function" then
    CameraController.weaponKick = function(a, b, ...)
      if not Unloaded and Config.NoCameraKick then
        if type(a) == "table" and typeof(a.Value) == "Vector3" then
          a = { Value = Vector3.zero, Damper = a.Damper, Speed = a.Speed }
        end
        if type(b) == "table" and typeof(b.Value) == "Vector3" then
          b = { Value = Vector3.zero, Damper = b.Damper, Speed = b.Speed }
        end
      end
      return origWeaponKick(a, b, ...)
    end
  end

  if BulletMod and type(origGetTrueSpread) == "function" then
    BulletMod.getTrueSpread = function(self, ...)
      local sp = origGetTrueSpread(self, ...)
      if not Unloaded and Config.SpreadReductionPct > 0 and type(sp) == "number" then
        sp = sp * math.clamp(1 - Config.SpreadReductionPct * 0.01, 0, 1)
      end
      return sp
    end
  end

  if BulletMod and type(origPerformRaycast) == "function" then
    BulletMod._performRaycast = function(self, spreadVal, ...)
      if not Unloaded and Config.SpreadReductionPct > 0 and type(spreadVal) == "number" then
        spreadVal = spreadVal * math.clamp(1 - Config.SpreadReductionPct * 0.01, 0, 1)
      end
      local res = origPerformRaycast(self, spreadVal, ...)
      if not Unloaded and Config.SilentAimEnabled and type(res) == "table" and typeof(res.Origin) == "Vector3" then
        if math.random(1, 100) <= Config.SilentHitchance then
          local cam = Workspace.CurrentCamera
          local tgt = cam and selectCombatTarget(
            cam, Config.SilentAimFOV, Config.SilentHitbox,
            Config.SilentVisCheck, Config.SilentSmokeCheck,
            Config.AimbotTeamCheck, Config.AimbotBots, Config.AimbotZombies, false
          )
          if tgt and tgt.pos then
            local delta = tgt.pos - res.Origin
            if delta.Magnitude > 0.25 then
              local newDir = delta.Unit
              res.Direction = newDir
              local wPen = (self and self.Properties and self.Properties.Penetration) or 0.65
              local wRange = (self and self.Properties and self.Properties.Range) or 1000
              local newHits, newDist = traceBulletHitsForSilent(res.Origin, newDir, wRange, wPen)
              res.Hits = newHits
              res.Distance = newDist
            end
          end
        end
      end
      -- Bullet tracers for YOUR shots (other players' shots arrive through Remotes.VFX.CreateTracer in the FX module)
      if FX.Tracers and not Unloaded and Config.TracersEnabled then
        local okT, errT = pcall(FX.Tracers.onLocalShot, res)
        if not okT then warn("[BloxStrikeSuite] tracer hook: " .. tostring(errT)) end
      end
      return res
    end
  end

  -- Camera Aimbot Step (runs right BEFORE CameraController.UpdateCamera at Camera.Value + 1)
  local currentHudTarget = nil
  RunService:BindToRenderStep(AIM_STEP_NAME, Enum.RenderPriority.Camera.Value, function(dt)
    if Unloaded or not Config.AimbotEnabled then StickyTarget = nil; return end
    if Menu.Visible or UserInputService:GetFocusedTextBox() ~= nil then return end
    if LocalPlayer:GetAttribute("Dead") == true or LocalPlayer:GetAttribute("IsSpectating") == true then
      StickyTarget = nil
      return
    end
    if Workspace:GetAttribute("GameState") == "Buy Period" then return end
    if not isInputModeHeld(Config.AimbotMode) then
      StickyTarget = nil
      return
    end

    local cam = Workspace.CurrentCamera
    if not cam then return end
    local tgt = selectCombatTarget(
      cam, Config.AimbotFOV, Config.AimbotHitbox,
      Config.AimbotVisCheck, Config.AimbotSmokeCheck,
      Config.AimbotTeamCheck, Config.AimbotBots, Config.AimbotZombies, Config.AimbotSticky
    )
    if not tgt then
      StickyTarget = nil
      currentHudTarget = nil
      return
    end

    StickyTarget = Config.AimbotSticky and tgt.entity or nil
    currentHudTarget = tgt

    local camPos = cam.CFrame.Position
    if (tgt.pos - camPos).Magnitude < 0.25 then return end
    local goalRot = CFrame.lookAt(camPos, tgt.pos).Rotation
    if Config.AimbotSmooth <= 1 then
      cam.CFrame = CFrame.new(camPos) * goalRot
    else
      local alpha = math.clamp((dt or 0.016) * (24 / Config.AimbotSmooth), 0.04, 1)
      cam.CFrame = CFrame.new(camPos) * cam.CFrame.Rotation:Lerp(goalRot, alpha)
    end
  end)

  -- Triggerbot, Auto Reload, Auto Pistol & Combat UI Overlays
  local triggerHoverStart = nil
  local lastTriggerShot = 0
  local lastAutoPistolShot = 0
  local lastAutoReloadTry = 0

  trackCombat(RunService.RenderStepped:Connect(function()
    if Unloaded then return end
    local cam = Workspace.CurrentCamera
    local now = os.clock()

    if cam then
      local vp = cam.ViewportSize
      local cx, cy = vp.X * 0.5, vp.Y * 0.5

      if Config.AimbotEnabled and Config.AimbotShowFOV then
        AimRing.Size = UDim2.fromOffset(Config.AimbotFOV * 2, Config.AimbotFOV * 2)
        AimRing.Position = UDim2.fromOffset(cx, cy)
        AimRingStroke.Color = Config.AimbotFOVColor
        AimRing.Visible = true
      elseif AimRing.Visible then
        AimRing.Visible = false
      end

      if Config.SilentAimEnabled and Config.SilentShowFOV then
        SilentRing.Size = UDim2.fromOffset(Config.SilentAimFOV * 2, Config.SilentAimFOV * 2)
        SilentRing.Position = UDim2.fromOffset(cx, cy)
        SilentRing.Visible = true
      elseif SilentRing.Visible then
        SilentRing.Visible = false
      end

      if Config.HitMarker and HitCross.Visible then
        HitCross.Position = UDim2.fromOffset(cx, cy)
        local rem = hitFlashUntil - now
        if rem <= 0 then
          HitCross.Visible = false
        else
          local tr = math.clamp(1 - (rem / 0.22), 0, 1)
          for _, t in ipairs(hitTicks) do t.BackgroundTransparency = tr end
        end
      elseif HitCross.Visible then
        HitCross.Visible = false
      end

      if Config.TargetHUD then
        local hudTgt = currentHudTarget
        if not hudTgt and Config.SilentAimEnabled then
          hudTgt = selectCombatTarget(
            cam, Config.SilentAimFOV, Config.SilentHitbox,
            Config.SilentVisCheck, Config.SilentSmokeCheck,
            Config.AimbotTeamCheck, Config.AimbotBots, Config.AimbotZombies, false
          )
        elseif not hudTgt and Config.AimbotEnabled then
          hudTgt = selectCombatTarget(
            cam, Config.AimbotFOV, Config.AimbotHitbox,
            Config.AimbotVisCheck, Config.AimbotSmokeCheck,
            Config.AimbotTeamCheck, Config.AimbotBots, Config.AimbotZombies, false
          )
        end
        if hudTgt then
          TargetCard.Position = UDim2.fromOffset(cx, cy + 36)
          local wbTxt = hudTgt.isWallbang and " [WB]" or ""
          local wepTxt = hudTgt.weapon ~= "" and (" | " .. hudTgt.weapon) or ""
          TargetCardLbl.Text = string.format("%s | %dHP | %dm%s%s", tostring(hudTgt.name), math.floor(hudTgt.hp or 100), math.floor(hudTgt.dist + 0.5), wepTxt, wbTxt)
          TargetCardStroke.Color = hudTgt.isWallbang and T.GOLD or T.GREEN
          TargetCard.Visible = true
        else
          TargetCard.Visible = false
        end
        currentHudTarget = nil
      elseif TargetCard.Visible then
        TargetCard.Visible = false
      end

      -- Gameplay automation (only while alive and outside Buy Period / menus)
      if not Menu.Visible and UserInputService:GetFocusedTextBox() == nil
        and LocalPlayer:GetAttribute("Dead") ~= true
        and LocalPlayer:GetAttribute("IsSpectating") ~= true
        and Workspace:GetAttribute("GameState") ~= "Buy Period"
      then
        local eq = getEquippedWeapon()
        if eq then
          -- Auto Reload when magazine hits 0 and reserve ammo remains
          if Config.AutoReload and (tonumber(eq.Rounds) or 0) <= 0 and (tonumber(eq.Capacity) or 0) > 0
            and not eq.IsReloading and not eq.IsShooting and not eq.IsAdjustingSuppressor
            and (now - lastAutoReloadTry >= 0.35)
          then
            lastAutoReloadTry = now
            task.spawn(function() pcall(function() eq:reload() end) end)
          end

          -- Auto Pistol (semi-auto rapid fire while holding LMB)
          if Config.AutoPistol and eq.Properties and not eq.Properties.Automatic
            and eq.Properties.ShootingOptions ~= "Revolver"
            and InputX.fire()   -- mouse, gamepad R2 or the touch Shoot button (was mouse-only -> never fired here)
            and (tonumber(eq.Rounds) or 0) > 0
            and not eq.IsShooting and not eq.IsReloading and not eq.IsAdjustingSuppressor
            and (now - lastAutoPistolShot >= 0.04)
          then
            lastAutoPistolShot = now
            task.spawn(function() pcall(function() eq:shoot() end) end)
          end

          -- Triggerbot (supports Head Only, Reaction Delay, Spread Settle, Wallbang penetration)
          if Config.TriggerbotEnabled and isInputModeHeld(Config.TriggerMode)
            and (tonumber(eq.Rounds) or 0) > 0
            and not eq.IsShooting and not eq.IsReloading and not eq.IsAdjustingSuppressor
          then
            -- BUG FIX: `a and b and callRestored(f)` only keeps callRestored's FIRST return (ok = true), so the
            -- triggerbot believed you were ALWAYS flashed and never fired. Destructure (ok, value) properly.
            local flashBlocked = false
            if not Config.TriggerIgnoreFlash and FlashEffect and FlashEffect.IsFlashed then
              local okF, isFl = callRestored(FlashEffect.IsFlashed)
              flashBlocked = (okF and isFl) and true or false
            end
            if not flashBlocked then
              local ray = cam:ViewportPointToRay(cx, cy)
              local range = (eq.Properties and eq.Properties.Range) or 500
              local wPen = (eq.Properties and eq.Properties.Penetration) or 0.65
              local excl = buildBaseExcludeList()
              local rp = RaycastParams.new()
              rp.FilterType = Enum.RaycastFilterType.Exclude
              rp.CollisionGroup = "Bullet"
              rp.FilterDescendantsInstances = excl

              local hitValid = false
              local cur = ray.Origin
              local penDepths = {}
              local endPt = ray.Origin + ray.Direction * range

              for _ = 1, 6 do
                local rem = endPt - cur
                if rem.Magnitude < 0.25 then break end
                local h = Workspace:Raycast(cur, rem, rp)
                if not h then break end
                local inst = h.Instance
                if isPartIgnoredForTrace(inst) then
                  table.insert(excl, inst); rp.FilterDescendantsInstances = excl
                  continue
                end
                local mdl = inst:FindFirstAncestorOfClass("Model")
                local matchedEnemy = false
                if mdl then
                  local owner = Players:GetPlayerFromCharacter(mdl)
                  if owner and owner ~= LocalPlayer then
                    if (not Config.AimbotTeamCheck or isEnemyParticipant(owner)) and isParticipantAlive(owner, mdl) then
                      matchedEnemy = true
                    end
                  elseif Config.AimbotBots and mdl:GetAttribute("Bot") == true and mdl:GetAttribute("Dead") ~= true then
                    local tTeam = mdl:GetAttribute("Team")
                    local myTeam = LocalPlayer:GetAttribute("Team")
                    if (not Config.AimbotTeamCheck) or Workspace:GetAttribute("Gamemode") == "Deathmatch" or (tTeam ~= myTeam and tTeam ~= nil) then
                      matchedEnemy = true
                    end
                  elseif Config.AimbotZombies and mdl:GetAttribute("Dead") ~= true and (mdl.Parent and (mdl.Parent.Name == "Horde" or mdl.Parent.Name == "HordeShells")) then
                    matchedEnemy = true
                  end
                end

                if matchedEnemy then
                  if (not Config.TriggerHeadOnly or inst.Name == "Head")
                    and (Config.TriggerIgnoreSmoke or not isRayBlockedBySmoke(ray.Origin, h.Position))
                  then
                    hitValid = true
                  end
                  break
                end

                if Config.WallbangMode == "Off" then break end
                local inc = RaycastParams.new()
                inc.FilterType = Enum.RaycastFilterType.Include
                inc.CollisionGroup = "Bullet"
                inc.FilterDescendantsInstances = { inst }
                local backStart = h.Position + ray.Direction * 250
                local ex = Workspace:Raycast(backStart, h.Position - backStart, inc)
                if not ex then break end
                if Config.WallbangMode == "Penetrable" then
                  local thk = (h.Position - ex.Position).Magnitude
                  local mat = (inst.Parent and inst.Parent:HasTag("BreakableDoor")) and Enum.Material.Metal or inst.Material
                  local allow = (inst:HasTag("BreakableGlass") or (inst.Parent and inst.Parent:HasTag("BreakableGlass"))) and 25 or (MAT_PEN[mat] or 0)
                  penDepths[mat] = (penDepths[mat] or 0) + thk
                  if penDepths[mat] > allow + wPen then break end
                end
                table.insert(excl, inst); rp.FilterDescendantsInstances = excl
                cur = ex.Position + ray.Direction * 0.05
              end

              if hitValid then
                if not triggerHoverStart then triggerHoverStart = now end
                if (now - triggerHoverStart) >= (Config.TriggerDelayMs * 0.001) then
                  local spreadOK = true
                  if Config.TriggerBurstMode and eq.Bullet and eq.Properties and eq.Properties.Spread and eq.Properties.Spread.Range then
                    local okSp, spVal = pcall(function() return eq:getBaseSpread() end)
                    local r = eq.Properties.Spread.Range
                    if okSp and type(spVal) == "number" then
                      spreadOK = spVal <= (r.Min + (r.Max - r.Min) * 0.28)
                    end
                  end
                  if spreadOK and (now - lastTriggerShot >= 0.045) then
                    lastTriggerShot = now
                    task.spawn(function()
                      pcall(function()
                        if eq.Properties.ShootingOptions == "Revolver" then
                          eq:shoot("Secondary")
                        else
                          eq:shoot()
                        end
                      end)
                    end)
                  end
                end
              else
                triggerHoverStart = nil
              end
            else
              triggerHoverStart = nil
            end
          else
            triggerHoverStart = nil
          end
        end
      end
    end
  end))

  _G.__BloxStrikeCombatCleanup = function()
    pcall(function() RunService:UnbindFromRenderStep(AIM_STEP_NAME) end)
    for _, c in ipairs(combatConns) do pcall(function() c:Disconnect() end) end
    table.clear(combatConns)
    if CameraController then
      if origSetWeaponRecoil then CameraController.setWeaponRecoil = origSetWeaponRecoil end
      if origWeaponKick then CameraController.weaponKick = origWeaponKick end
    end
    if BulletMod then
      if origGetTrueSpread then BulletMod.getTrueSpread = origGetTrueSpread end
      if origPerformRaycast then BulletMod._performRaycast = origPerformRaycast end
    end
    StickyTarget = nil
    pcall(function() HitSoundInst:Destroy() end)
  end
end)()



-- ============================================================================
-- BLOXSTRIKE // MERGED SKIN CHANGER & CASE GATHERER (100% INTACT PORT)
-- ============================================================================
do
local _runMergedSkinSuite = function()
--// BloxStrike Skin Changer & Case Gatherer Studio
--// Separate Companion Script to BloxStrikeSuite.lua
--// Features:
--//   1. Skin Changer Studio UI: All Skins, Knives (w/ model & anim swap), Gloves/Hand Wraps,
--//      Charms (w/ pattern 1-16 & slot 1-4), Zeus, Grenades, Badges, KillTrak, NameTag, Float/Wear
--//   2. Interactive 3D ViewportFrame Studio (Orbit, Zoom, Auto-Spin, Native 3D Scene Inspect)
--//   3. Live In-Match Applier + Client Menu Inventory & Loadout Sync
--//   4. Dedicated Case Gatherer & CS2-Style Case Opener UI (All 40 Cases, Packages, Capsules, Consoles)

-- The standalone Skin Changer ("unbranded", myUiforMygame.lua) is the full version (Workshop + Configs + fixes).
-- When it is loaded, skip this lighter built-in copy: both used the same _G names and destroyed each other,
-- and the suite's SKINS / CASES buttons now talk to whichever one is loaded.
if _G.__Unbranded then return end

if _G.__BloxStrikeSkinChangerCleanup then
    pcall(_G.__BloxStrikeSkinChangerCleanup)
    _G.__BloxStrikeSkinChangerCleanup = nil
end

local okMain, errMain = xpcall(function()
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local HttpService = game:GetService("HttpService")
    local RunService = game:GetService("RunService")
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local CoreGui = game:GetService("CoreGui")

    local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

    local Env = {
        Connections = {},
        IsDestroyed = false,
        GuiHost = nil,
    }

    local function restoreIdentity()
        if type(setthreadidentity) == "function" then
            pcall(setthreadidentity, 8)
        end
    end

    local function callRestored(fn, ...)
        local res = table.pack(pcall(fn, ...))
        restoreIdentity()
        return table.unpack(res, 1, res.n)
    end

    local function track(conn)
        if conn then table.insert(Env.Connections, conn) end
        return conn
    end

    do
        local ok, hui = pcall(function() return gethui and gethui() or nil end)
        Env.GuiHost = (ok and typeof(hui) == "Instance" and hui) or CoreGui
        for _, name in ipairs({ "BloxStrikeSkinChangerGui", "BloxStrikeCaseGatherGui" }) do
            pcall(function()
                local old = Env.GuiHost:FindFirstChild(name)
                if old then old:Destroy() end
            end)
            pcall(function()
                local pg = LocalPlayer:FindFirstChild("PlayerGui")
                local old = pg and pg:FindFirstChild(name)
                if old then old:Destroy() end
            end)
        end
    end

    --// Game Modules (Lazy Safe Require)
    local Modules = {}
    do
        local function safeReq(inst)
            if not inst then return nil end
            local ok, mod = callRestored(require, inst)
            return ok and mod or nil
        end
        local db = ReplicatedStorage:FindFirstChild("Database")
        local libs = db and db:FindFirstChild("Components") and db.Components:FindFirstChild("Libraries")
        local ctrls = ReplicatedStorage:FindFirstChild("Controllers")
        Modules.Skins = safeReq(libs and libs:FindFirstChild("Skins"))
        Modules.Cases = safeReq(libs and libs:FindFirstChild("Cases"))
        Modules.Rarities = safeReq(db and db:FindFirstChild("Custom") and db.Custom:FindFirstChild("GameStats") and db.Custom.GameStats:FindFirstChild("Rarities"))
        Modules.Router = safeReq(db and db:FindFirstChild("Security") and db.Security:FindFirstChild("Router"))
        Modules.InventoryController = safeReq(ctrls and ctrls:FindFirstChild("InventoryController"))
        Modules.DataController = safeReq(ctrls and ctrls:FindFirstChild("DataController"))
    end

    --// Theme & Constants: shared with the main menu (see `T` at the top of the file) = Skin Changer "unbranded" look
    local C = {
        BG         = Color3.fromRGB(24, 24, 27),
        SIDE       = Color3.fromRGB(18, 18, 20),
        CARD       = Color3.fromRGB(30, 30, 34),
        CARD_ALT   = Color3.fromRGB(36, 36, 42),
        INPUT      = Color3.fromRGB(14, 14, 16),
        BORDER     = Color3.fromRGB(44, 44, 50),
        BORDER_HI  = Color3.fromRGB(65, 65, 75),
        ACCENT     = Color3.fromRGB(220, 220, 225),
        ACCENT_DIM = Color3.fromRGB(40, 40, 48),
        GREEN      = Color3.fromRGB(34, 170, 96),
        GOLD       = Color3.fromRGB(230, 185, 80),
        RED        = Color3.fromRGB(235, 75, 75),
        PINK       = Color3.fromRGB(215, 80, 150),
        PURPLE     = Color3.fromRGB(136, 71, 255),
        BLUE       = Color3.fromRGB(75, 106, 255),
        STOCK      = Color3.fromRGB(155, 165, 175),
        TEXT       = Color3.fromRGB(245, 245, 247),
        TEXT_DIM   = Color3.fromRGB(140, 140, 150),
        FONT       = Enum.Font.SourceSansBold,
        RARITY_RANK = { Stock = 0, Blue = 1, Purple = 2, Pink = 3, Red = 4, Special = 5, Forbidden = 6 },
        DEFAULT_RARITY = {
            Stock     = Color3.fromRGB(165, 172, 180),
            Blue      = Color3.fromRGB(75, 106, 255),
            Purple    = Color3.fromRGB(136, 71, 255),
            Pink      = Color3.fromRGB(211, 44, 230),
            Red       = Color3.fromRGB(235, 75, 75),
            Special   = Color3.fromRGB(255, 215, 0),
            Forbidden = Color3.fromRGB(185, 38, 52),
        },
        WEAR_TIERS = {
            { name = "Factory New",    short = "FN", min = 0.00, max = 0.07, sample = 0.015 },
            { name = "Minimal Wear",   short = "MW", min = 0.07, max = 0.15, sample = 0.095 },
            { name = "Field-Tested",   short = "FT", min = 0.15, max = 0.38, sample = 0.210 },
            { name = "Well-Worn",      short = "WW", min = 0.38, max = 0.45, sample = 0.410 },
            { name = "Battle-Scarred", short = "BS", min = 0.45, max = 1.00, sample = 0.650 },
        },
    }

    local Helpers = {}
    function Helpers.getRarityColor(rarity)
        if Modules.Rarities and Modules.Rarities[rarity] and Modules.Rarities[rarity].Color then
            return Modules.Rarities[rarity].Color
        end
        return C.DEFAULT_RARITY[rarity] or C.STOCK
    end

    function Helpers.getWearName(floatVal)
        local f = tonumber(floatVal) or 0
        for _, t in ipairs(C.WEAR_TIERS) do
            if f <= t.max then return t.name, t.short end
        end
        return "Battle-Scarred", "BS"
    end

    function Helpers.cleanSkin(skinName)
        if type(skinName) ~= "string" then return tostring(skinName or "") end
        return (string.gsub(skinName, "_PATTERN_%d+$", ""))
    end

    function Helpers.getThumbAsset(info, floatVal, patternNum)
        if not info then return "" end
        if info.type == "Charm" and type(info.charmImages) == "table" and #info.charmImages > 0 then
            local idx = math.clamp(tonumber(patternNum) or 1, 1, #info.charmImages)
            local entry = info.charmImages[idx] or info.charmImages[1]
            if entry and entry.assetId then return entry.assetId end
        end
        if type(info.wearImages) == "table" and #info.wearImages > 0 then
            local targetWear = Helpers.getWearName(floatVal or 0.05)
            for _, w in ipairs(info.wearImages) do
                if w.wear == targetWear and w.assetId then return w.assetId end
            end
            if info.wearImages[1] and info.wearImages[1].assetId then
                return info.wearImages[1].assetId
            end
        end
        if Modules.Skins and Modules.Skins.GetWearImageForFloat and floatVal then
            local ok, img = callRestored(Modules.Skins.GetWearImageForFloat, info, floatVal)
            if ok and type(img) == "string" and img ~= "" then return img end
        end
        return info.imageAssetId or ""
    end

    --// Index Game Skins & Cases
    local Data = {
        RawSkins = {},
        RawCases = {},
        AllSkinsFlat = {},
        SkinsByWeapon = {},
        WeaponsByGroup = {
            ["ALL"] = {}, ["RIFLES"] = {}, ["PISTOLS"] = {}, ["SMG & HEAVY"] = {},
            ["KNIVES"] = {}, ["GLOVES & WRAPS"] = {}, ["CHARMS"] = {},
            ["ZEUS & NADES"] = {}, ["BADGES"] = {}, ["ACTIVE"] = {},
        },
        Charms = {},
    }

    do
        local okS, parsedS = pcall(function() return HttpService:JSONDecode(ReplicatedStorage:GetAttribute("AvaiableSkins") or "{}") end)
        if okS and type(parsedS) == "table" then Data.RawSkins = parsedS end
        local okC, parsedC = pcall(function() return HttpService:JSONDecode(ReplicatedStorage:GetAttribute("AvaiableCases") or "[]") end)
        if okC and type(parsedC) == "table" then Data.RawCases = parsedC end

        local RIFLES = { ["AK-47"]=true, ["M4A4"]=true, ["M4A1-S"]=true, ["AWP"]=true, ["SSG 08"]=true, ["AUG"]=true, ["SG 553"]=true, ["FAMAS"]=true, ["Galil AR"]=true }
        local PISTOLS = { ["Glock-18"]=true, ["USP-S"]=true, ["Desert Eagle"]=true, ["P250"]=true, ["Five-SeveN"]=true, ["Tec-9"]=true, ["Dual Berettas"]=true, ["R8 Revolver"]=true }
        local SMG_HEAVY = { ["MAC-10"]=true, ["MP9"]=true, ["P90"]=true, ["Nova"]=true, ["XM1014"]=true, ["MAG-7"]=true, ["Sawed-Off"]=true, ["Negev"]=true }
        local EXCLUDED = { Case = true, Package = true, ["Name Plate"] = true, Booth = true, C4 = true }

        local function getGroup(wName, sType)
            if sType == "Melee" then return "KNIVES" end
            if sType == "Glove" then return "GLOVES & WRAPS" end
            if sType == "Charm" then return "CHARMS" end
            if sType == "Badge" then return "BADGES" end
            if sType == "Grenade" or sType == "Zeus x27" then return "ZEUS & NADES" end
            if RIFLES[wName] then return "RIFLES" end
            if PISTOLS[wName] then return "PISTOLS" end
            if SMG_HEAVY[wName] then return "SMG & HEAVY" end
            return "ALL"
        end

        local seen = {}
        for wName, skinMap in pairs(Data.RawSkins) do
            if not EXCLUDED[wName] and type(skinMap) == "table" then
                Data.SkinsByWeapon[wName] = {}
                for skinKey, info in pairs(skinMap) do
                    if type(info) == "table" then
                        local grp = getGroup(wName, info.type or "Weapon")
                        local entry = {
                            weapon = wName,
                            skin = skinKey,
                            displaySkin = Helpers.cleanSkin(skinKey),
                            type = info.type or "Weapon",
                            group = grp,
                            rarity = info.rarity or "Stock",
                            floatRange = info.floatRange or { min = 0, max = 1 },
                            floatChances = info.floatChances or {},
                            wearImages = info.wearImages or {},
                            charmImages = info.charmImages or {},
                            imageAssetId = info.imageAssetId or "",
                            supportsStatTrak = info.supportsStatTrak == true,
                            description = info.description or "",
                            collection = info.collection or "",
                            info = info,
                        }
                        table.insert(Data.AllSkinsFlat, entry)
                        table.insert(Data.SkinsByWeapon[wName], entry)
                        seen[grp] = seen[grp] or {}
                        if not seen[grp][wName] then
                            seen[grp][wName] = true
                            table.insert(Data.WeaponsByGroup[grp], wName)
                        end
                        seen["ALL"] = seen["ALL"] or {}
                        if not seen["ALL"][wName] then
                            seen["ALL"][wName] = true
                            table.insert(Data.WeaponsByGroup["ALL"], wName)
                        end
                    end
                end
                table.sort(Data.SkinsByWeapon[wName], function(a, b)
                    if (a.skin == "Stock") ~= (b.skin == "Stock") then return a.skin == "Stock" end
                    local ra, rb = C.RARITY_RANK[a.rarity] or 0, C.RARITY_RANK[b.rarity] or 0
                    if ra ~= rb then return ra > rb end
                    return a.displaySkin < b.displaySkin
                end)
            end
        end

        table.sort(Data.AllSkinsFlat, function(a, b)
            local ra, rb = C.RARITY_RANK[a.rarity] or 0, C.RARITY_RANK[b.rarity] or 0
            if ra ~= rb then return ra > rb end
            if a.weapon ~= b.weapon then return a.weapon < b.weapon end
            return a.displaySkin < b.displaySkin
        end)
        for _, list in pairs(Data.WeaponsByGroup) do table.sort(list) end
        for _, entry in ipairs(Data.SkinsByWeapon["Charm"] or {}) do
            table.insert(Data.Charms, entry)
        end
        table.sort(Data.Charms, function(a, b)
            return (C.RARITY_RANK[a.rarity] or 0) > (C.RARITY_RANK[b.rarity] or 0)
        end)
    end

    --// Runtime State
    local State = {
        Overrides = { Weapons = {}, Knife = nil, Glove = nil, Badge = nil },
        Enabled = true,
        InjectToGameMenu = true,
        LiveForceApply = true,

        SelectedEntry = Data.AllSkinsFlat[1],
        InspectFloat = 0.015,
        InspectStatTrak = false,
        InspectKills = 1337,
        InspectNameTag = "",
        InspectCharmSkin = "",
        InspectCharmPattern = 1,
        InspectCharmPos = "1",
        AutoSpinPreview = true,

        CaseStash = {},
        UnboxedItems = {},
        QuickOpen = false,
        SyncCasesToMenuInv = true,
        SelectedCase = Data.RawCases[1],
        IsSpinning = false,
    }
    for _, cObj in ipairs(Data.RawCases) do
        State.CaseStash[cObj.caseId or cObj.name] = 0
    end

    --// UI Primitives
    local UI = {}
    function UI.addCorner(p, r)
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 2); c.Parent = p; return c
    end
    function UI.addStroke(p, col, thick, trans)
        local s = Instance.new("UIStroke"); s.Color = col or C.BORDER; s.Thickness = thick or 1
        s.Transparency = trans or 0; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = p; return s
    end
    function UI.frame(parent, props)
        local f = Instance.new("Frame")
        f.BackgroundColor3 = props.Color or C.CARD
        f.BorderSizePixel = 0
        if props.Size then f.Size = props.Size end
        if props.Pos then f.Position = props.Pos end
        if props.Trans ~= nil then f.BackgroundTransparency = props.Trans end
        if props.Z then f.ZIndex = props.Z end
        if props.Name then f.Name = props.Name end
        if props.Clip ~= nil then f.ClipsDescendants = props.Clip end
        f.Parent = parent
        return f
    end
    function UI.label(parent, props)
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Font = props.Font or C.FONT
        l.Text = props.Text or ""
        l.TextSize = props.TextSize or 12
        l.TextColor3 = props.TextColor or C.TEXT
        l.TextXAlignment = props.XAlign or Enum.TextXAlignment.Left
        l.TextYAlignment = props.YAlign or Enum.TextYAlignment.Center
        l.TextWrapped = props.Wrapped or false
        l.TextTruncate = Enum.TextTruncate.AtEnd
        if props.Size then l.Size = props.Size end
        if props.Pos then l.Position = props.Pos end
        if props.Z then l.ZIndex = props.Z end
        l.Parent = parent
        return l
    end
    function UI.button(parent, props)
        local b = Instance.new("TextButton")
        b.AutoButtonColor = false
        b.BackgroundColor3 = props.Color or C.CARD_ALT
        b.BorderSizePixel = 0
        b.Font = props.Font or C.FONT
        b.Text = props.Text or ""
        b.TextSize = props.TextSize or 11
        b.TextColor3 = props.TextColor or C.TEXT
        b.TextTruncate = Enum.TextTruncate.AtEnd
        if props.Size then b.Size = props.Size end
        if props.Pos then b.Position = props.Pos end
        if props.Z then b.ZIndex = props.Z end
        if props.Name then b.Name = props.Name end
        b.Parent = parent
        UI.addStroke(b, props.BorderColor or C.BORDER, 1)
        UI.addCorner(b, props.Radius or 2)
        return b
    end
    function UI.makeDraggable(handle, target)
        local dragging, dragStart, startPos
        track(handle.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                dragging = true; dragStart = inp.Position; startPos = target.Position
                local c
                c = track(inp.Changed:Connect(function()
                    if inp.UserInputState == Enum.UserInputState.End then dragging = false; if c then c:Disconnect() end end
                end))
            end
        end))
        track(UserInputService.InputChanged:Connect(function(inp)
            if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                local d = inp.Position - dragStart
                target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end))
    end
    function UI.computeScale()
        local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
        if vp.X < 750 or vp.Y < 500 then return math.clamp(math.min(vp.X / 880, vp.Y / 560), 0.55, 0.92) end
        if vp.X < 1350 then return 0.85 end
        return 1
    end

    local StatusCallbacks = {}
    local function notifyStatus(msg, col)
        for _, fn in ipairs(StatusCallbacks) do pcall(fn, msg, col) end
    end

    --// =====================================================================
    --// LIVE SKIN APPLIER & CLIENT INVENTORY INJECTOR
    --// =====================================================================
    local Applier = { AppliedSigs = setmetatable({}, { __mode = "k" }) }

    function Applier.makeItemStruct(cfg)
        local isCharm = (cfg.Type == "Charm")
        local pat = tonumber(cfg.Pattern) or (isCharm and 1 or nil)
        if not pat and type(cfg.Skin) == "string" then
            local m = string.match(cfg.Skin, "_PATTERN_(%d+)$")
            if m then pat = tonumber(m) end
        end
        local charmData = false
        if type(cfg.Charm) == "table" and type(cfg.Charm.Skin) == "string" and cfg.Charm.Skin ~= "" then
            charmData = {
                _id = cfg.Charm._id or HttpService:GenerateGUID(false),
                Skin = cfg.Charm.Skin,
                Pattern = tonumber(cfg.Charm.Pattern) or 1,
                Position = tostring(cfg.Charm.Position or "1"),
            }
        end
        return {
            _id = cfg._id or HttpService:GenerateGUID(false),
            Type = cfg.Type or "Weapon",
            Serial = cfg.Serial or math.random(1000, 99999),
            Name = cfg.Name,
            Skin = cfg.Skin,
            Rarity = cfg.Rarity or "Stock",
            Float = tonumber(cfg.Float) or 0.015,
            StatTrack = (cfg.StatTrack ~= nil) and cfg.StatTrack or false,
            IsTradeable = true,
            NameTag = (type(cfg.NameTag) == "string" and cfg.NameTag ~= "") and cfg.NameTag or false,
            Pattern = pat,
            Charm = charmData,
            Stickers = {},
            MetaData = {
                CreatedAt = os.time() * 1000,
                LastTradeAt = 0,
                Origin = cfg.Origin or "SkinChanger",
                OriginalOwner = LocalPlayer.UserId,
                Owner = LocalPlayer.UserId,
                TradeHistory = {},
            },
        }
    end

    function Applier.injectToClientMenu(itemStruct, equipInLoadout)
        if not Modules.DataController or not State.InjectToGameMenu then return end
        callRestored(function()
            local existingInv = Modules.DataController.Get(LocalPlayer, "Inventory")
            if type(existingInv) ~= "table" then return end
            local exists = false
            for _, it in ipairs(existingInv) do
                if it._id == itemStruct._id then exists = true; break end
            end
            if not exists then
                Modules.DataController.ApplyInventoryDelta(LocalPlayer, { itemStruct }, {})
            end
            if not equipInLoadout then return end
            local loadout = Modules.DataController.Get(LocalPlayer, "Loadout")
            if type(loadout) ~= "table" then return end
            for _, teamName in ipairs({ "Terrorists", "Counter-Terrorists" }) do
                local td = loadout[teamName]
                if type(td) == "table" then
                    if itemStruct.Type == "Melee" and td.Equipped then
                        td.Equipped["Equipped Melee"] = itemStruct._id
                    elseif itemStruct.Type == "Glove" and td.Equipped then
                        td.Equipped["Equipped Gloves"] = itemStruct._id
                    elseif itemStruct.Type == "Badge" and td.Equipped then
                        td.Equipped["Equipped Badge"] = itemStruct._id
                    elseif itemStruct.Type == "Zeus x27" and td.Equipped then
                        td.Equipped["Equipped Zeus x27"] = itemStruct._id
                    elseif td.Loadout then
                        for _, catData in pairs(td.Loadout) do
                            if type(catData) == "table" and type(catData.Options) == "table" then
                                for i, optId in ipairs(catData.Options) do
                                    local replaced = false
                                    if string.sub(tostring(optId), 1, #itemStruct.Name + 1) == (itemStruct.Name .. "_") then
                                        catData.Options[i] = itemStruct._id
                                        replaced = true
                                    else
                                        for _, invIt in ipairs(existingInv) do
                                            if invIt._id == optId and invIt.Name == itemStruct.Name then
                                                catData.Options[i] = itemStruct._id
                                                replaced = true
                                                break
                                            end
                                        end
                                    end
                                    if replaced then break end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end

    local function applyGloveAttrs()
        if not State.Enabled or not State.Overrides.Glove then return end
        local g = State.Overrides.Glove
        local payload = HttpService:JSONEncode({ Name = g.Name, Skin = g.Skin, Float = tonumber(g.Float) or 0.05 })
        pcall(function()
            if LocalPlayer:GetAttribute("EquippedGloves") ~= payload then
                LocalPlayer:SetAttribute("EquippedGloves", payload)
            end
        end)
        pcall(function()
            local chars = workspace:FindFirstChild("Characters")
            local char = (chars and chars:FindFirstChild(LocalPlayer.Name)) or LocalPlayer.Character
            if char and char:GetAttribute("EquippedGloves") ~= payload then
                char:SetAttribute("EquippedGloves", payload)
            end
        end)
    end

    local function applyToComp(comp, force)
        if not comp or type(comp) ~= "table" or not State.Enabled then return end
        local ov
        if comp.Type == "Melee" or (comp.Name and (string.find(comp.Name, "Knife") or comp.Name == "Karambit" or comp.Name == "M9 Bayonet" or comp.Name == "LightSaber")) then
            ov = State.Overrides.Knife
        else
            ov = State.Overrides.Weapons[comp.Name]
        end
        local gloveOv = State.Overrides.Glove
        if not ov and not gloveOv then return end

        local sig = (ov and (tostring(ov.Name) .. "|" .. tostring(ov.Skin) .. "|" .. string.format("%.4f", tonumber(ov.Float) or 0) .. "|" .. tostring(ov.StatTrack) .. "|" .. tostring(ov.NameTag) .. "|" .. (type(ov.Charm) == "table" and (ov.Charm.Skin .. "#" .. tostring(ov.Charm.Pattern) .. "@" .. tostring(ov.Charm.Position)) or "")) or "none")
            .. "::" .. (gloveOv and (tostring(gloveOv.Name) .. "|" .. tostring(gloveOv.Skin) .. "|" .. string.format("%.4f", tonumber(gloveOv.Float) or 0)) or "none")
        if not force and Applier.AppliedSigs[comp] == sig then return end
        Applier.AppliedSigs[comp] = sig

        if ov then
            comp.Skin = ov.Skin
            comp.Float = tonumber(ov.Float) or 0.015
            if ov.StatTrack ~= nil then comp.StatTrack = ov.StatTrack end
            if ov.NameTag ~= nil then comp.NameTag = ov.NameTag end
            if ov.Charm ~= nil then comp.Charm = ov.Charm end
        end
        if gloveOv then applyGloveAttrs() end

        local vm = comp.Viewmodel
        if vm and type(vm) == "table" and not vm.IsDestroyed and vm.construct then
            callRestored(function()
                if ov then
                    vm.Skin = ov.Skin
                    vm.Float = tonumber(ov.Float) or 0.015
                    vm.StatTrack = ov.StatTrack ~= nil and ov.StatTrack or false
                    vm.NameTag = ov.NameTag ~= nil and ov.NameTag or false
                    vm.Charm = ov.Charm ~= nil and ov.Charm or false
                    if ov.Type == "Melee" and ov.Name and ov.Name ~= "" then
                        vm.CameraModelWeapon = ov.Name
                    end
                end
                local chars = workspace:FindFirstChild("Characters")
                local char = (chars and chars:FindFirstChild(LocalPlayer.Name)) or LocalPlayer.Character
                vm:construct(char, comp)
            end)
        end
    end

    function Applier.applyAllLive(force)
        if not State.Enabled then return end
        if State.Overrides.Glove then applyGloveAttrs() end
        local ic = Modules.InventoryController
        if ic then
            callRestored(function()
                local inv = ic.getCurrentInventory and ic.getCurrentInventory()
                if type(inv) == "table" then
                    for _, slot in pairs(inv) do
                        if type(slot) == "table" and type(slot._items) == "table" then
                            for _, comp in ipairs(slot._items) do applyToComp(comp, force) end
                        end
                    end
                end
                local peek = ic.peekCurrentEquippedForMovement and ic.peekCurrentEquippedForMovement()
                if peek then applyToComp(peek, force) end
            end)
        end
    end

    function Applier.applySkinConfig(cfg)
        local item = Applier.makeItemStruct(cfg)
        if cfg.Type == "Melee" then
            State.Overrides.Knife = item
        elseif cfg.Type == "Glove" then
            State.Overrides.Glove = item
        elseif cfg.Type == "Badge" then
            State.Overrides.Badge = item
        else
            State.Overrides.Weapons[item.Name] = item
        end
        Applier.injectToClientMenu(item, true)
        Applier.applyAllLive(true)
        if Modules.Router then
            pcall(function() callRestored(Modules.Router.broadcastRouter, "RunInterfaceSound", "UI Notification") end)
        end
        notifyStatus(("APPLIED: %s | %s (%s)"):format(item.Name, Helpers.cleanSkin(item.Skin), select(2, Helpers.getWearName(item.Float))), C.ACCENT)
        return item
    end

    -- Attach Live Watchers
    do
        local cam = workspace.CurrentCamera
        if cam then
            local function hookStash(stash)
                if not stash or stash.Name ~= "ViewmodelStash" then return end
                track(stash.ChildAdded:Connect(function()
                    if State.Enabled and State.LiveForceApply then task.defer(function() Applier.applyAllLive(true) end) end
                end))
            end
            for _, ch in ipairs(cam:GetChildren()) do if ch.Name == "ViewmodelStash" then hookStash(ch) end end
            track(cam.ChildAdded:Connect(function(ch) if ch.Name == "ViewmodelStash" then hookStash(ch) end end))
        end
        local ic = Modules.InventoryController
        if ic and ic.OnInventoryItemEquipped and ic.OnInventoryItemEquipped.Connect then
            callRestored(function()
                track(ic.OnInventoryItemEquipped:Connect(function()
                    if State.Enabled and State.LiveForceApply then task.defer(function() Applier.applyAllLive(true) end) end
                end))
            end)
        end
        track(LocalPlayer.CharacterAdded:Connect(function()
            if State.Enabled and State.LiveForceApply then task.wait(0.25); Applier.applyAllLive(true) end
        end))
        local acc = 0
        track(RunService.Heartbeat:Connect(function(dt)
            if Env.IsDestroyed or not State.Enabled or not State.LiveForceApply then return end
            acc += dt
            if acc < 0.35 then return end
            acc = 0
            Applier.applyAllLive(false)
        end))
    end

    --// =====================================================================
    --// WINDOW 1: SKIN CHANGER STUDIO UI
    --// =====================================================================
    local SkinUI = {
        ActiveGroup = "RIFLES",
        ActiveWeapon = "AK-47",
        ActiveRarity = "ALL",
        SearchQuery = "",
        OrbitYaw = 0.55,
        OrbitPitch = 0.22,
        OrbitDist = 4,
        OrbitCenter = Vector3.zero,
        OrbitDragging = false,
        OrbitLastPos = nil,
        PreviewModel = nil,
        GroupBtns = {},
        RarityBtns = {},
        CharmPosBtns = {},
    }

    do
        local gui = Instance.new("ScreenGui")
        gui.Name = "BloxStrikeSkinChangerGui"
        gui.ResetOnSpawn = false
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.DisplayOrder = 500
        gui.Parent = Env.GuiHost
        SkinUI.Gui = gui

        local sc = Instance.new("UIScale"); sc.Scale = UI.computeScale(); sc.Parent = gui

        -- Optional quick-launch dock. Hidden by default: the main menu header already has SKINS / CASES buttons,
        -- and a second always-on floating widget was just clutter (toggle it in UTILITIES > SHOW SKIN / CASE DOCK).
        local dock = UI.frame(gui, { Name = "PillDock", Color = C.BG, Size = UDim2.fromOffset(232, 32), Pos = UDim2.new(0, 18, 0, 56), Z = 50 })
        UI.addStroke(dock, C.BORDER_HI, 1); UI.addCorner(dock, 5)
        dock.Visible = false
        SkinUI.Dock = dock
        SkinUI.SkinsPill = UI.button(dock, { Name = "SkinsPill", Text = "SKINS", Color = C.ACCENT_DIM, BorderColor = C.ACCENT, TextColor = C.ACCENT, TextSize = 12, Size = UDim2.fromOffset(108, 24), Pos = UDim2.fromOffset(4, 4) })
        SkinUI.CasesPill = UI.button(dock, { Name = "CasesPill", Text = "CASES", Color = C.CARD_ALT, BorderColor = C.GOLD, TextColor = C.GOLD, TextSize = 12, Size = UDim2.fromOffset(112, 24), Pos = UDim2.fromOffset(116, 4) })
        UI.makeDraggable(dock, dock)

        -- Main Window
        local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
        local winPos = (vp.X < 1300) and UDim2.fromOffset(16, 94) or UDim2.new(0.5, -520, 0.5, -270)
        local win = UI.frame(gui, { Name = "SkinChangerWindow", Color = C.BG, Size = UDim2.fromOffset(820, 540), Pos = winPos, Clip = true })
        UI.addStroke(win, C.BORDER, 1); UI.addCorner(win, 6)
        do
            local g = Instance.new("UIGradient"); g.Color = ColorSequence.new(Color3.fromRGB(32, 32, 36), Color3.fromRGB(20, 20, 24)); g.Rotation = 45; g.Parent = win
        end
        SkinUI.Win = win

        local hdr = UI.frame(win, { Name = "Header", Color = C.SIDE, Size = UDim2.new(1, 0, 0, 34) })
        UI.frame(hdr, { Color = C.BORDER, Size = UDim2.new(1, 0, 0, 1), Pos = UDim2.new(0, 0, 1, -1) })
        UI.label(hdr, { Text = "SKIN CHANGER STUDIO", TextColor = C.TEXT, TextSize = 14, Size = UDim2.new(1, -240, 1, 0), Pos = UDim2.fromOffset(14, 0) })
        local stLbl = UI.label(hdr, { Text = ("READY · %d SKINS"):format(#Data.AllSkinsFlat), TextColor = C.TEXT_DIM, TextSize = 10, XAlign = Enum.TextXAlignment.Right, Size = UDim2.fromOffset(220, 34), Pos = UDim2.new(1, -298, 0, 0) })
        table.insert(StatusCallbacks, function(msg, col) stLbl.Text = msg; stLbl.TextColor3 = col or C.ACCENT end)
        SkinUI.OpenCaseQuickBtn = UI.button(hdr, { Text = "CASE GATHERER", Color = C.CARD_ALT, BorderColor = C.GOLD, TextColor = C.GOLD, TextSize = 10, Size = UDim2.fromOffset(96, 22), Pos = UDim2.new(1, -134, 0, 6) })
        SkinUI.CloseBtn = UI.button(hdr, { Text = "X", Color = C.CARD_ALT, BorderColor = C.BORDER_HI, TextColor = C.TEXT_DIM, TextSize = 11, Size = UDim2.fromOffset(26, 22), Pos = UDim2.new(1, -32, 0, 6) })
        UI.makeDraggable(hdr, win)

        -- Left Sidebar
        local side = UI.frame(win, { Color = C.SIDE, Size = UDim2.new(0, 148, 1, -34), Pos = UDim2.fromOffset(0, 34) })
        UI.frame(side, { Color = C.BORDER, Size = UDim2.new(0, 1, 1, 0), Pos = UDim2.new(1, -1, 0, 0) })
        local sScroll = Instance.new("ScrollingFrame")
        sScroll.BackgroundTransparency = 1; sScroll.BorderSizePixel = 0; sScroll.ScrollBarThickness = 3
        sScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; sScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        sScroll.Size = UDim2.new(1, -8, 1, -110); sScroll.Position = UDim2.fromOffset(4, 6); sScroll.Parent = side
        local sl = Instance.new("UIListLayout"); sl.Padding = UDim.new(0, 4); sl.Parent = sScroll
        SkinUI.SideScroll = sScroll

        local sFoot = UI.frame(side, { Color = C.CARD, Size = UDim2.new(1, -8, 0, 96), Pos = UDim2.new(0, 4, 1, -100) })
        UI.addStroke(sFoot, C.BORDER, 1)
        SkinUI.LiveBtn = UI.button(sFoot, { Text = "LIVE APPLY: ON", Color = C.ACCENT_DIM, BorderColor = C.ACCENT, TextColor = C.ACCENT, TextSize = 10, Size = UDim2.new(1, -8, 0, 26), Pos = UDim2.fromOffset(4, 4) })
        SkinUI.SyncBtn = UI.button(sFoot, { Text = "MENU INV SYNC: ON", Color = C.ACCENT_DIM, BorderColor = C.ACCENT, TextColor = C.ACCENT, TextSize = 10, Size = UDim2.new(1, -8, 0, 26), Pos = UDim2.fromOffset(4, 34) })
        SkinUI.ResetBtn = UI.button(sFoot, { Text = "RESET ALL SKINS", Color = C.CARD_ALT, BorderColor = C.RED, TextColor = C.RED, TextSize = 10, Size = UDim2.new(1, -8, 0, 26), Pos = UDim2.fromOffset(4, 64) })

        -- Center Panel
        local center = UI.frame(win, { Color = C.BG, Size = UDim2.new(0, 392, 1, -34), Pos = UDim2.fromOffset(148, 34) })
        UI.frame(center, { Color = C.BORDER, Size = UDim2.new(0, 1, 1, 0), Pos = UDim2.new(1, -1, 0, 0) })

        local search = Instance.new("TextBox")
        search.BackgroundColor3 = C.INPUT; search.BorderSizePixel = 0; search.Font = C.FONT
        search.PlaceholderText = "Search skin or weapon (Fade, Karambit, Wraps)..."
        search.PlaceholderColor3 = C.TEXT_DIM; search.Text = ""; search.TextColor3 = C.TEXT; search.TextSize = 11
        search.ClearTextOnFocus = false; search.Size = UDim2.new(1, -16, 0, 26); search.Position = UDim2.fromOffset(8, 8); search.Parent = center
        UI.addStroke(search, C.BORDER_HI, 1); UI.addCorner(search, 2)
        local sp = Instance.new("UIPadding"); sp.PaddingLeft = UDim.new(0, 8); sp.Parent = search
        SkinUI.SearchBox = search

        local rBar = UI.frame(center, { Trans = 1, Size = UDim2.new(1, -16, 0, 24), Pos = UDim2.fromOffset(8, 38) })
        local rl = Instance.new("UIListLayout"); rl.FillDirection = Enum.FillDirection.Horizontal; rl.Padding = UDim.new(0, 4); rl.Parent = rBar
        SkinUI.RarityBar = rBar

        local wStrip = Instance.new("ScrollingFrame")
        wStrip.BackgroundColor3 = C.SIDE; wStrip.BorderSizePixel = 0; wStrip.ScrollBarThickness = 2
        wStrip.ScrollingDirection = Enum.ScrollingDirection.X; wStrip.AutomaticCanvasSize = Enum.AutomaticSize.X
        wStrip.CanvasSize = UDim2.new(0, 0, 0, 0); wStrip.Size = UDim2.new(1, -16, 0, 30); wStrip.Position = UDim2.fromOffset(8, 66); wStrip.Parent = center
        UI.addStroke(wStrip, C.BORDER, 1)
        local wsl = Instance.new("UIListLayout"); wsl.FillDirection = Enum.FillDirection.Horizontal; wsl.VerticalAlignment = Enum.VerticalAlignment.Center; wsl.Padding = UDim.new(0, 4); wsl.Parent = wStrip
        local wsp = Instance.new("UIPadding"); wsp.PaddingLeft = UDim.new(0, 4); wsp.PaddingRight = UDim.new(0, 4); wsp.Parent = wStrip
        SkinUI.WeaponStrip = wStrip

        local grid = Instance.new("ScrollingFrame")
        grid.BackgroundColor3 = C.INPUT; grid.BorderSizePixel = 0; grid.ScrollBarThickness = 4; grid.ScrollBarImageColor3 = C.ACCENT
        grid.AutomaticCanvasSize = Enum.AutomaticSize.Y; grid.CanvasSize = UDim2.new(0, 0, 0, 0)
        grid.Size = UDim2.new(1, -16, 1, -108); grid.Position = UDim2.fromOffset(8, 100); grid.Parent = center
        UI.addStroke(grid, C.BORDER, 1)
        local gl = Instance.new("UIGridLayout"); gl.CellSize = UDim2.fromOffset(118, 128); gl.CellPadding = UDim2.fromOffset(6, 6); gl.SortOrder = Enum.SortOrder.LayoutOrder; gl.Parent = grid
        local gp = Instance.new("UIPadding"); gp.PaddingLeft = UDim.new(0, 6); gp.PaddingTop = UDim.new(0, 6); gp.PaddingBottom = UDim.new(0, 8); gp.Parent = grid
        SkinUI.Grid = grid

        -- Right Panel
        local right = UI.frame(win, { Color = C.SIDE, Size = UDim2.new(1, -540, 1, -34), Pos = UDim2.fromOffset(540, 34) })
        SkinUI.PreviewTitle = UI.label(right, { Text = "SELECT A SKIN", TextColor = C.TEXT, TextSize = 12, Size = UDim2.new(1, -16, 0, 20), Pos = UDim2.fromOffset(8, 6) })
        SkinUI.PreviewSub = UI.label(right, { Text = "Drag 3D view to rotate · Scroll to zoom", TextColor = C.TEXT_DIM, TextSize = 10, Size = UDim2.new(1, -16, 0, 16), Pos = UDim2.fromOffset(8, 24) })

        local vpBox = UI.frame(right, { Color = Color3.fromRGB(11, 14, 19), Size = UDim2.new(1, -16, 0, 178), Pos = UDim2.fromOffset(8, 42), Clip = true })
        UI.addStroke(vpBox, C.BORDER_HI, 1); UI.addCorner(vpBox, 2)
        SkinUI.ViewportBox = vpBox

        local vpf = Instance.new("ViewportFrame")
        vpf.Size = UDim2.fromScale(1, 1); vpf.BackgroundTransparency = 1
        vpf.Ambient = Color3.fromRGB(180, 190, 210); vpf.LightColor = Color3.fromRGB(255, 250, 242)
        vpf.LightDirection = Vector3.new(-0.5, -0.7, -0.5); vpf.Parent = vpBox
        local wm = Instance.new("WorldModel"); wm.Parent = vpf
        local vCam = Instance.new("Camera"); vCam.FieldOfView = 38; vCam.Parent = vpf; vpf.CurrentCamera = vCam
        SkinUI.World = wm; SkinUI.Cam = vCam

        local fb = Instance.new("ImageLabel"); fb.BackgroundTransparency = 1; fb.ScaleType = Enum.ScaleType.Fit
        fb.Size = UDim2.fromOffset(48, 48); fb.Position = UDim2.new(1, -54, 1, -54); fb.Visible = false; fb.Parent = vpBox
        SkinUI.FallbackImg = fb

        SkinUI.AutoSpinBtn = UI.button(vpBox, { Text = "SPIN: ON", Color = C.CARD_ALT, BorderColor = C.ACCENT, TextColor = C.ACCENT, TextSize = 9, Size = UDim2.fromOffset(58, 18), Pos = UDim2.new(1, -64, 0, 6), Z = 5 })
        SkinUI.StudioInspectBtn = UI.button(vpBox, { Text = "3D SCENE", Color = C.CARD_ALT, BorderColor = C.GOLD, TextColor = C.GOLD, TextSize = 9, Size = UDim2.fromOffset(60, 18), Pos = UDim2.fromOffset(6, 6), Z = 5 })

        local cScroll = Instance.new("ScrollingFrame")
        cScroll.BackgroundTransparency = 1; cScroll.BorderSizePixel = 0; cScroll.ScrollBarThickness = 3
        cScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; cScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        cScroll.Size = UDim2.new(1, -16, 1, -276); cScroll.Position = UDim2.fromOffset(8, 224); cScroll.Parent = right
        local cl = Instance.new("UIListLayout"); cl.Padding = UDim.new(0, 6); cl.Parent = cScroll

        -- Wear block
        local wBlk = UI.frame(cScroll, { Color = C.CARD, Size = UDim2.new(1, -4, 0, 68) })
        UI.addStroke(wBlk, C.BORDER, 1); UI.addCorner(wBlk, 2)
        SkinUI.FloatHeader = UI.label(wBlk, { Text = "FLOAT: 0.0150 (FN)", TextColor = C.ACCENT, TextSize = 10, Size = UDim2.new(1, -12, 0, 16), Pos = UDim2.fromOffset(6, 4) })
        local fBg = UI.frame(wBlk, { Color = C.INPUT, Size = UDim2.new(1, -12, 0, 12), Pos = UDim2.fromOffset(6, 22) })
        UI.addStroke(fBg, C.BORDER_HI, 1)
        SkinUI.FloatBarBg = fBg
        SkinUI.FloatFill = UI.frame(fBg, { Color = C.ACCENT, Size = UDim2.fromScale(0.015, 1) })
        SkinUI.WearBtnRow = UI.frame(wBlk, { Trans = 1, Size = UDim2.new(1, -12, 0, 22), Pos = UDim2.fromOffset(6, 40) })
        local wbl = Instance.new("UIListLayout"); wbl.FillDirection = Enum.FillDirection.Horizontal; wbl.Padding = UDim.new(0, 4); wbl.Parent = SkinUI.WearBtnRow

        -- KillTrak & NameTag block
        local mBlk = UI.frame(cScroll, { Color = C.CARD, Size = UDim2.new(1, -4, 0, 64) })
        UI.addStroke(mBlk, C.BORDER, 1); UI.addCorner(mBlk, 2)
        SkinUI.KillTrakBtn = UI.button(mBlk, { Text = "KILLTRAK: OFF", Color = C.CARD_ALT, BorderColor = C.BORDER_HI, TextColor = C.TEXT_DIM, TextSize = 10, Size = UDim2.fromOffset(118, 24), Pos = UDim2.fromOffset(6, 6) })
        local kInp = Instance.new("TextBox"); kInp.BackgroundColor3 = C.INPUT; kInp.BorderSizePixel = 0; kInp.Font = C.FONT; kInp.Text = "1337"
        kInp.TextColor3 = C.GOLD; kInp.TextSize = 11; kInp.Size = UDim2.new(1, -134, 0, 24); kInp.Position = UDim2.fromOffset(128, 6); kInp.Parent = mBlk
        UI.addStroke(kInp, C.BORDER, 1); UI.addCorner(kInp, 2); SkinUI.KillsInput = kInp
        local ntInp = Instance.new("TextBox"); ntInp.BackgroundColor3 = C.INPUT; ntInp.BorderSizePixel = 0; ntInp.Font = C.FONT; ntInp.Text = ""
        ntInp.PlaceholderText = "Custom NameTag (optional)..."; ntInp.PlaceholderColor3 = C.TEXT_DIM; ntInp.TextColor3 = C.TEXT; ntInp.TextSize = 11
        ntInp.ClearTextOnFocus = false; ntInp.Size = UDim2.new(1, -12, 0, 24); ntInp.Position = UDim2.fromOffset(6, 34); ntInp.Parent = mBlk
        UI.addStroke(ntInp, C.BORDER, 1); UI.addCorner(ntInp, 2)
        local ntp = Instance.new("UIPadding"); ntp.PaddingLeft = UDim.new(0, 6); ntp.Parent = ntInp
        SkinUI.NameTagInput = ntInp

        -- Charm block
        local chBlk = UI.frame(cScroll, { Color = C.CARD, Size = UDim2.new(1, -4, 0, 66) })
        UI.addStroke(chBlk, C.BORDER, 1); UI.addCorner(chBlk, 2)
        SkinUI.CharmLabel = UI.label(chBlk, { Text = "CHARM: NONE", TextColor = C.TEXT_DIM, TextSize = 10, Size = UDim2.new(1, -12, 0, 16), Pos = UDim2.fromOffset(6, 4) })
        SkinUI.CharmCycleBtn = UI.button(chBlk, { Text = "NEXT CHARM", Color = C.CARD_ALT, BorderColor = C.BORDER_HI, TextColor = C.TEXT, TextSize = 10, Size = UDim2.fromOffset(118, 22), Pos = UDim2.fromOffset(6, 22) })
        SkinUI.CharmClearBtn = UI.button(chBlk, { Text = "CLEAR", Color = C.CARD_ALT, BorderColor = C.BORDER, TextColor = C.TEXT_DIM, TextSize = 10, Size = UDim2.fromOffset(58, 22), Pos = UDim2.fromOffset(128, 22) })
        SkinUI.CharmPatBtn = UI.button(chBlk, { Text = "PAT #1", Color = C.CARD_ALT, BorderColor = C.BORDER, TextColor = C.GOLD, TextSize = 10, Size = UDim2.new(1, -196, 0, 22), Pos = UDim2.fromOffset(190, 22) })
        UI.label(chBlk, { Text = "Attach Slot:", TextColor = C.TEXT_DIM, TextSize = 9, Size = UDim2.fromOffset(78, 16), Pos = UDim2.fromOffset(6, 47) })
        for p = 1, 4 do
            SkinUI.CharmPosBtns[p] = UI.button(chBlk, { Text = tostring(p), Color = p == 1 and C.ACCENT_DIM or C.CARD_ALT, BorderColor = p == 1 and C.ACCENT or C.BORDER, TextColor = p == 1 and C.ACCENT or C.TEXT_DIM, TextSize = 9, Size = UDim2.fromOffset(38, 16), Pos = UDim2.fromOffset(88 + (p - 1) * 42, 47) })
        end

        SkinUI.ApplyBtn = UI.button(right, { Text = "APPLY & EQUIP SKIN", Color = C.ACCENT_DIM, BorderColor = C.ACCENT, TextColor = C.ACCENT, TextSize = 12, Size = UDim2.new(1, -16, 0, 34), Pos = UDim2.new(0, 8, 1, -42) })
    end

    --// 3D Viewport Engine
    function SkinUI.clearPreview()
        if SkinUI.PreviewModel then pcall(function() SkinUI.PreviewModel:Destroy() end); SkinUI.PreviewModel = nil end
        for _, ch in ipairs(SkinUI.World:GetChildren()) do pcall(function() ch:Destroy() end) end
    end

    function SkinUI.loadPreviewModel(built, titleText, subText, titleCol, thumbAsset, defaultYaw)
        SkinUI.clearPreview()
        SkinUI.PreviewTitle.Text = titleText or ""
        SkinUI.PreviewTitle.TextColor3 = titleCol or C.TEXT
        SkinUI.PreviewSub.Text = subText or ""

        if built then
            for _, d in ipairs(built:GetDescendants()) do
                if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false end
            end
            built.Parent = SkinUI.World
            SkinUI.PreviewModel = built
            local okBB, cf, sz
            if built:IsA("Model") then okBB, cf, sz = pcall(function() return built:GetBoundingBox() end)
            elseif built:IsA("BasePart") then okBB, cf, sz = true, built.CFrame, built.Size end
            if okBB and sz then
                local maxDim = math.max(sz.X, sz.Y, sz.Z, 0.25)
                if built:IsA("Model") then
                    pcall(function() built:PivotTo(built:GetPivot() - cf.Position) end)
                    local ok2, cf2, sz2 = pcall(function() return built:GetBoundingBox() end)
                    SkinUI.OrbitCenter = ok2 and cf2.Position or Vector3.zero
                    if ok2 then maxDim = math.max(sz2.X, sz2.Y, sz2.Z, 0.25) end
                else
                    built.Position = Vector3.zero
                    SkinUI.OrbitCenter = Vector3.zero
                end
                SkinUI.OrbitDist = math.clamp(maxDim * 1.48, 0.9, 10)
                SkinUI.OrbitYaw = defaultYaw or 1.45
                SkinUI.OrbitPitch = 0.2
            end
        end

        if thumbAsset and thumbAsset ~= "" then
            SkinUI.FallbackImg.Image = thumbAsset
            SkinUI.FallbackImg.Visible = true
        else
            SkinUI.FallbackImg.Visible = false
        end
    end

    function SkinUI.loadPreviewEntry(entry, floatVal, stVal, ntVal, charmTbl)
        if not entry then return end
        local rCol = Helpers.getRarityColor(entry.rarity)
        local wName = Helpers.getWearName(floatVal)
        local built
        if Modules.Skins then
            local ok, mdl = callRestored(function()
                if entry.type == "Glove" and Modules.Skins.GetGloves then
                    return Modules.Skins.GetGloves(entry.weapon, entry.skin, floatVal)
                elseif entry.type == "Charm" and Modules.Skins.GetCharmModel then
                    return Modules.Skins.GetCharmModel(entry.skin, tonumber(State.InspectCharmPattern) or 1)
                elseif entry.type == "Badge" and Modules.Skins.GetBadgeModel then
                    return Modules.Skins.GetBadgeModel(entry.skin)
                elseif Modules.Skins.GetInspectModel then
                    return Modules.Skins.GetInspectModel(entry.weapon, entry.skin, floatVal, stVal or false, ntVal or false, charmTbl or false, {})
                end
                return nil
            end)
            if ok and typeof(mdl) == "Instance" then built = mdl end
        end
        local thumb = Helpers.getThumbAsset(entry.info, floatVal, State.InspectCharmPattern)
        local yaw = (entry.type == "Glove" or entry.type == "Charm") and 0.35 or 1.45
        SkinUI.loadPreviewModel(built, ("%s | %s"):format(entry.weapon, entry.displaySkin), ("%s · %s (%.4f) · %s"):format(entry.rarity, wName, floatVal, entry.type), rCol, thumb, yaw)
    end

    function SkinUI.refreshCustomizer()
        local e = State.SelectedEntry
        local fMin = (e and e.floatRange and e.floatRange.min) or 0
        local fMax = (e and e.floatRange and e.floatRange.max) or 1
        State.InspectFloat = math.clamp(State.InspectFloat, fMin, fMax)
        local _, wShort = Helpers.getWearName(State.InspectFloat)
        SkinUI.FloatHeader.Text = ("FLOAT: %.4f (%s) [%.2f-%.2f]"):format(State.InspectFloat, wShort, fMin, fMax)
        SkinUI.FloatFill.Size = UDim2.fromScale(math.clamp(State.InspectFloat, 0.01, 1), 1)
        SkinUI.KillTrakBtn.Text = State.InspectStatTrak and "KILLTRAK: ON" or "KILLTRAK: OFF"
        SkinUI.KillTrakBtn.BackgroundColor3 = State.InspectStatTrak and C.ACCENT_DIM or C.CARD_ALT
        SkinUI.KillTrakBtn.TextColor3 = State.InspectStatTrak and C.GOLD or C.TEXT_DIM
        if State.InspectCharmSkin ~= "" then
            SkinUI.CharmLabel.Text = ("CHARM: %s (Pat #%d · Slot %s)"):format(State.InspectCharmSkin, State.InspectCharmPattern, State.InspectCharmPos)
            SkinUI.CharmLabel.TextColor3 = C.GOLD
        else
            SkinUI.CharmLabel.Text = "CHARM: NONE (Select Charm or Cycle)"
            SkinUI.CharmLabel.TextColor3 = C.TEXT_DIM
        end
        SkinUI.CharmPatBtn.Text = ("PAT #%d"):format(State.InspectCharmPattern)
        for p = 1, 4 do
            local on = (State.InspectCharmPos == tostring(p))
            SkinUI.CharmPosBtns[p].BackgroundColor3 = on and C.ACCENT_DIM or C.CARD_ALT
            SkinUI.CharmPosBtns[p].TextColor3 = on and C.ACCENT or C.TEXT_DIM
        end
        if e and e.type == "Charm" then SkinUI.ApplyBtn.Text = "EQUIP CHARM FOR ATTACH"
        elseif e and e.type == "Glove" then SkinUI.ApplyBtn.Text = "APPLY GLOVES / WRAPS LIVE"
        elseif e and e.type == "Melee" then SkinUI.ApplyBtn.Text = "APPLY KNIFE & ANIM LIVE"
        elseif e and e.type == "Badge" then SkinUI.ApplyBtn.Text = "EQUIP BADGE LIVE"
        else SkinUI.ApplyBtn.Text = "APPLY & EQUIP SKIN LIVE" end
    end

    function SkinUI.selectEntry(entry)
        State.SelectedEntry = entry
        if entry and entry.floatRange then
            local fMin, fMax = entry.floatRange.min or 0, entry.floatRange.max or 1
            if State.InspectFloat < fMin or State.InspectFloat > fMax then
                State.InspectFloat = math.clamp(fMin + 0.015, fMin, fMax)
            end
        end
        if entry and entry.type == "Charm" then
            State.InspectCharmSkin = entry.skin
            local maxPat = (entry.charmImages and #entry.charmImages > 0) and #entry.charmImages or 1
            State.InspectCharmPattern = math.clamp(State.InspectCharmPattern, 1, maxPat)
        end
        SkinUI.refreshCustomizer()
        local charmPayload = (State.InspectCharmSkin ~= "" and entry and entry.type == "Weapon") and {
            Skin = State.InspectCharmSkin, Pattern = State.InspectCharmPattern, Position = State.InspectCharmPos
        } or false
        local stVal = State.InspectStatTrak and (tonumber(SkinUI.KillsInput.Text) or 1337) or false
        SkinUI.loadPreviewEntry(entry, State.InspectFloat, stVal, State.InspectNameTag, charmPayload)
    end

    function SkinUI.isOverrideActive(entry)
        if not entry then return false end
        if entry.type == "Melee" and State.Overrides.Knife then
            return State.Overrides.Knife.Name == entry.weapon and State.Overrides.Knife.Skin == entry.skin
        elseif entry.type == "Glove" and State.Overrides.Glove then
            return State.Overrides.Glove.Name == entry.weapon and State.Overrides.Glove.Skin == entry.skin
        elseif entry.type == "Badge" and State.Overrides.Badge then
            return State.Overrides.Badge.Skin == entry.skin
        end
        local ov = State.Overrides.Weapons[entry.weapon]
        return ov ~= nil and ov.Skin == entry.skin
    end

    function SkinUI.rebuildWeaponStrip()
        for _, ch in ipairs(SkinUI.WeaponStrip:GetChildren()) do
            if ch:IsA("TextButton") then ch:Destroy() end
        end
        local weapons = Data.WeaponsByGroup[SkinUI.ActiveGroup] or {}
        local allB = UI.button(SkinUI.WeaponStrip, {
            Text = "ALL",
            Color = (SkinUI.ActiveWeapon == "ALL") and C.ACCENT_DIM or C.CARD,
            BorderColor = (SkinUI.ActiveWeapon == "ALL") and C.ACCENT or C.BORDER,
            TextColor = (SkinUI.ActiveWeapon == "ALL") and C.ACCENT or C.TEXT_DIM,
            TextSize = 10,
            Size = UDim2.fromOffset(42, 22),
        })
        track(allB.MouseButton1Click:Connect(function()
            SkinUI.ActiveWeapon = "ALL"; SkinUI.rebuildWeaponStrip(); SkinUI.rebuildGrid()
        end))
        for _, wName in ipairs(weapons) do
            local on = (SkinUI.ActiveWeapon == wName)
            local b = UI.button(SkinUI.WeaponStrip, {
                Text = wName,
                Color = on and C.ACCENT_DIM or C.CARD,
                BorderColor = on and C.ACCENT or C.BORDER,
                TextColor = on and C.ACCENT or C.TEXT,
                TextSize = 10,
                Size = UDim2.fromOffset(math.max(54, #wName * 7 + 14), 22),
            })
            track(b.MouseButton1Click:Connect(function()
                SkinUI.ActiveWeapon = wName; SkinUI.rebuildWeaponStrip(); SkinUI.rebuildGrid()
            end))
        end
    end

    function SkinUI.rebuildGrid()
        for _, ch in ipairs(SkinUI.Grid:GetChildren()) do
            if ch:IsA("Frame") or ch:IsA("TextButton") then ch:Destroy() end
        end
        local q = string.lower(SkinUI.SearchQuery or "")
        local source = {}
        if SkinUI.ActiveGroup == "ACTIVE" then
            local tmp = {}
            if State.Overrides.Knife then table.insert(tmp, State.Overrides.Knife) end
            if State.Overrides.Glove then table.insert(tmp, State.Overrides.Glove) end
            if State.Overrides.Badge then table.insert(tmp, State.Overrides.Badge) end
            for _, ov in pairs(State.Overrides.Weapons) do table.insert(tmp, ov) end
            for _, ov in ipairs(tmp) do
                for _, e in ipairs(Data.SkinsByWeapon[ov.Name] or {}) do
                    if e.skin == ov.Skin then table.insert(source, e); break end
                end
            end
        elseif SkinUI.ActiveWeapon ~= "ALL" and Data.SkinsByWeapon[SkinUI.ActiveWeapon] then
            source = Data.SkinsByWeapon[SkinUI.ActiveWeapon]
        else
            source = Data.AllSkinsFlat
        end

        local shown = 0
        for _, entry in ipairs(source) do
            local mGrp = (SkinUI.ActiveGroup == "ALL" or SkinUI.ActiveGroup == "ACTIVE" or entry.group == SkinUI.ActiveGroup)
            local mRar = (SkinUI.ActiveRarity == "ALL" or entry.rarity == SkinUI.ActiveRarity)
            local mQ = (q == "" or string.find(string.lower(entry.weapon .. " " .. entry.displaySkin), q, 1, true) ~= nil)
            if mGrp and mRar and mQ then
                shown += 1
                if shown > 220 and q == "" and SkinUI.ActiveWeapon == "ALL" then break end
                local rCol = Helpers.getRarityColor(entry.rarity)
                local active = SkinUI.isOverrideActive(entry)
                local card = UI.button(SkinUI.Grid, {
                    Text = "",
                    Color = active and Color3.fromRGB(16, 38, 28) or C.CARD,
                    BorderColor = active and C.GREEN or C.BORDER,
                    Size = UDim2.fromOffset(118, 128),
                })
                UI.frame(card, { Color = rCol, Size = UDim2.new(1, 0, 0, 3) })
                local img = Instance.new("ImageLabel"); img.BackgroundTransparency = 1; img.ScaleType = Enum.ScaleType.Fit
                img.Image = Helpers.getThumbAsset(entry.info, 0.05, 1); img.Size = UDim2.new(1, -12, 0, 68); img.Position = UDim2.fromOffset(6, 8); img.Parent = card
                if active then
                    -- green ACTIVE pill (same as the standalone skin changer)
                    local pill = UI.frame(card, { Color = C.GREEN, Size = UDim2.fromOffset(46, 14), Pos = UDim2.new(1, -50, 0, 6), Z = 4 })
                    UI.addCorner(pill, 3)
                    UI.label(pill, { Text = "ACTIVE", TextColor = Color3.fromRGB(255, 255, 255), TextSize = 9, XAlign = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Z = 5 })
                elseif entry.rarity == "Special" then
                    UI.label(card, { Text = "★", TextColor = C.GOLD, TextSize = 11, Size = UDim2.fromOffset(18, 14), Pos = UDim2.fromOffset(4, 4) })
                end
                UI.label(card, { Text = entry.weapon, TextColor = C.TEXT_DIM, TextSize = 9, Size = UDim2.new(1, -10, 0, 14), Pos = UDim2.fromOffset(5, 80) })
                UI.label(card, { Text = entry.displaySkin, TextColor = rCol, TextSize = 10, Size = UDim2.new(1, -10, 0, 26), Pos = UDim2.fromOffset(5, 95), Wrapped = true })
                track(card.MouseButton1Click:Connect(function() SkinUI.selectEntry(entry) end))
            end
        end
    end

    -- Connect SkinUI Events
    do
        local function updateGroupStyles()
            for grp, btn in pairs(SkinUI.GroupBtns) do
                local on = (grp == SkinUI.ActiveGroup)
                btn.BackgroundColor3 = on and C.ACCENT_DIM or C.CARD
                btn.TextColor3 = on and C.ACCENT or C.TEXT
                local st = btn:FindFirstChildOfClass("UIStroke"); if st then st.Color = on and C.ACCENT or C.BORDER end
            end
        end
        for _, grp in ipairs({ "ALL", "RIFLES", "PISTOLS", "SMG & HEAVY", "KNIVES", "GLOVES & WRAPS", "CHARMS", "ZEUS & NADES", "BADGES", "ACTIVE" }) do
            local b = UI.button(SkinUI.SideScroll, { Text = grp, Color = C.CARD, BorderColor = C.BORDER, TextColor = C.TEXT, TextSize = 10, Size = UDim2.new(1, -4, 0, 26) })
            SkinUI.GroupBtns[grp] = b
            track(b.MouseButton1Click:Connect(function()
                SkinUI.ActiveGroup = grp
                local list = Data.WeaponsByGroup[grp]
                SkinUI.ActiveWeapon = (list and #list > 0 and grp ~= "ALL") and list[1] or "ALL"
                updateGroupStyles(); SkinUI.rebuildWeaponStrip(); SkinUI.rebuildGrid()
            end))
        end
        updateGroupStyles()

        local function updateRarStyles()
            for rar, btn in pairs(SkinUI.RarityBtns) do
                local on = (rar == SkinUI.ActiveRarity)
                local col = (rar == "ALL") and C.ACCENT or Helpers.getRarityColor(rar)
                btn.BackgroundColor3 = on and C.CARD_ALT or C.INPUT
                btn.TextColor3 = on and col or C.TEXT_DIM
                local st = btn:FindFirstChildOfClass("UIStroke"); if st then st.Color = on and col or C.BORDER end
            end
        end
        for _, rar in ipairs({ "ALL", "Special", "Red", "Pink", "Purple", "Blue", "Stock" }) do
            local lbl = rar == "ALL" and "ALL" or (rar == "Special" and "GOLD" or rar:upper():sub(1, 4))
            local b = UI.button(SkinUI.RarityBar, { Text = lbl, Color = C.INPUT, BorderColor = C.BORDER, TextColor = C.TEXT_DIM, TextSize = 9, Size = UDim2.fromOffset(48, 22) })
            SkinUI.RarityBtns[rar] = b
            track(b.MouseButton1Click:Connect(function()
                SkinUI.ActiveRarity = rar; updateRarStyles(); SkinUI.rebuildGrid()
            end))
        end
        updateRarStyles()

        for _, tier in ipairs(C.WEAR_TIERS) do
            local wb = UI.button(SkinUI.WearBtnRow, { Text = tier.short, Color = C.CARD_ALT, BorderColor = C.BORDER, TextColor = C.TEXT, TextSize = 10, Size = UDim2.fromOffset(44, 20) })
            track(wb.MouseButton1Click:Connect(function() State.InspectFloat = tier.sample; SkinUI.selectEntry(State.SelectedEntry) end))
        end

        local draggingFloat = false
        local function updFloatX(absX)
            local rel = math.clamp((absX - SkinUI.FloatBarBg.AbsolutePosition.X) / math.max(SkinUI.FloatBarBg.AbsoluteSize.X, 1), 0, 1)
            local e = State.SelectedEntry
            local fMin, fMax = (e and e.floatRange and e.floatRange.min) or 0, (e and e.floatRange and e.floatRange.max) or 1
            State.InspectFloat = fMin + (fMax - fMin) * rel
            SkinUI.refreshCustomizer()
        end
        track(SkinUI.FloatBarBg.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                draggingFloat = true; updFloatX(inp.Position.X)
                local c; c = track(inp.Changed:Connect(function()
                    if inp.UserInputState == Enum.UserInputState.End then draggingFloat = false; if c then c:Disconnect() end; SkinUI.selectEntry(State.SelectedEntry) end
                end))
            end
        end))
        track(UserInputService.InputChanged:Connect(function(inp)
            if draggingFloat and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then updFloatX(inp.Position.X) end
        end))

        -- 3D Orbit
        track(SkinUI.ViewportBox.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                SkinUI.OrbitDragging = true; SkinUI.OrbitLastPos = inp.Position
                local c; c = track(inp.Changed:Connect(function()
                    if inp.UserInputState == Enum.UserInputState.End then SkinUI.OrbitDragging = false; if c then c:Disconnect() end end
                end))
            end
        end))
        track(UserInputService.InputChanged:Connect(function(inp)
            if SkinUI.OrbitDragging and SkinUI.OrbitLastPos and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                local d = inp.Position - SkinUI.OrbitLastPos; SkinUI.OrbitLastPos = inp.Position
                SkinUI.OrbitYaw -= d.X * 0.012
                SkinUI.OrbitPitch = math.clamp(SkinUI.OrbitPitch + d.Y * 0.01, -1.1, 1.1)
            elseif inp.UserInputType == Enum.UserInputType.MouseWheel and SkinUI.Win.Visible then
                local mp = UserInputService:GetMouseLocation()
                local ap, as = SkinUI.ViewportBox.AbsolutePosition, SkinUI.ViewportBox.AbsoluteSize
                if mp.X >= ap.X and mp.X <= ap.X + as.X and mp.Y >= ap.Y and mp.Y <= ap.Y + as.Y then
                    SkinUI.OrbitDist = math.clamp(SkinUI.OrbitDist - inp.Position.Z * 0.35, 0.8, 16)
                end
            end
        end))
        track(RunService.RenderStepped:Connect(function(dt)
            if Env.IsDestroyed or not SkinUI.Win.Visible then return end
            if State.AutoSpinPreview and not SkinUI.OrbitDragging then SkinUI.OrbitYaw += dt * 0.55 end
            local offset = (CFrame.Angles(0, SkinUI.OrbitYaw, 0) * CFrame.Angles(-SkinUI.OrbitPitch, 0, 0)) * Vector3.new(0, 0, SkinUI.OrbitDist)
            SkinUI.Cam.CFrame = CFrame.lookAt(SkinUI.OrbitCenter + offset, SkinUI.OrbitCenter)
        end))

        track(SkinUI.SearchBox:GetPropertyChangedSignal("Text"):Connect(function() SkinUI.SearchQuery = SkinUI.SearchBox.Text or ""; SkinUI.rebuildGrid() end))
        track(SkinUI.KillTrakBtn.MouseButton1Click:Connect(function() State.InspectStatTrak = not State.InspectStatTrak; SkinUI.selectEntry(State.SelectedEntry) end))
        track(SkinUI.NameTagInput.FocusLost:Connect(function() State.InspectNameTag = SkinUI.NameTagInput.Text or ""; SkinUI.selectEntry(State.SelectedEntry) end))
        track(SkinUI.KillsInput.FocusLost:Connect(function() State.InspectKills = tonumber(SkinUI.KillsInput.Text) or 1337; if State.InspectStatTrak then SkinUI.selectEntry(State.SelectedEntry) end end))

        local chIdx = 0
        track(SkinUI.CharmCycleBtn.MouseButton1Click:Connect(function()
            if #Data.Charms == 0 then return end
            chIdx = (chIdx % #Data.Charms) + 1
            State.InspectCharmSkin = Data.Charms[chIdx].skin
            State.InspectCharmPattern = 1
            SkinUI.selectEntry(State.SelectedEntry)
        end))
        track(SkinUI.CharmClearBtn.MouseButton1Click:Connect(function() State.InspectCharmSkin = ""; SkinUI.selectEntry(State.SelectedEntry) end))
        track(SkinUI.CharmPatBtn.MouseButton1Click:Connect(function()
            local maxPat = 16
            for _, c in ipairs(Data.Charms) do
                if c.skin == State.InspectCharmSkin and type(c.charmImages) == "table" and #c.charmImages > 0 then maxPat = #c.charmImages; break end
            end
            State.InspectCharmPattern = (State.InspectCharmPattern % maxPat) + 1
            SkinUI.selectEntry(State.SelectedEntry)
        end))
        for p = 1, 4 do
            track(SkinUI.CharmPosBtns[p].MouseButton1Click:Connect(function()
                State.InspectCharmPos = tostring(p); SkinUI.selectEntry(State.SelectedEntry)
            end))
        end

        track(SkinUI.AutoSpinBtn.MouseButton1Click:Connect(function()
            State.AutoSpinPreview = not State.AutoSpinPreview
            SkinUI.AutoSpinBtn.Text = State.AutoSpinPreview and "SPIN: ON" or "SPIN: OFF"
            SkinUI.AutoSpinBtn.TextColor3 = State.AutoSpinPreview and C.ACCENT or C.TEXT_DIM
        end))

        track(SkinUI.StudioInspectBtn.MouseButton1Click:Connect(function()
            local e = State.SelectedEntry
            if not e or not Modules.Router then return end
            local stVal = State.InspectStatTrak and (tonumber(SkinUI.KillsInput.Text) or 1337) or false
            local charmPayload = (State.InspectCharmSkin ~= "" and e.type == "Weapon") and {
                Skin = State.InspectCharmSkin, Pattern = State.InspectCharmPattern, Position = State.InspectCharmPos
            } or false
            callRestored(Modules.Router.broadcastRouter, "WeaponInspect",
                e.weapon, e.skin, State.InspectFloat, stVal,
                (State.InspectNameTag ~= "" and State.InspectNameTag or false),
                charmPayload, {}, e.type, (e.type == "Charm" and State.InspectCharmPattern or nil),
                HttpService:GenerateGUID(false), 1337, true
            )
        end))

        track(SkinUI.ApplyBtn.MouseButton1Click:Connect(function()
            local e = State.SelectedEntry
            if not e then return end
            if e.type == "Charm" then
                State.InspectCharmSkin = e.skin
                local applied = false
                local ic = Modules.InventoryController
                if ic then
                    callRestored(function()
                        local peek = ic.peekCurrentEquippedForMovement and ic.peekCurrentEquippedForMovement()
                        if peek and peek.Name then
                            local ex = State.Overrides.Weapons[peek.Name] or { Name = peek.Name, Skin = peek.Skin or "Stock", Float = peek.Float or 0.01, Type = peek.Type or "Weapon" }
                            ex.Charm = { _id = HttpService:GenerateGUID(false), Skin = e.skin, Pattern = State.InspectCharmPattern, Position = State.InspectCharmPos }
                            Applier.applySkinConfig(ex)
                            applied = true
                        end
                    end)
                end
                if not applied then notifyStatus(("CHARM ARMED: %s #%d"):format(e.skin, State.InspectCharmPattern), C.GOLD) end
            else
                local charmPayload = (State.InspectCharmSkin ~= "" and e.type == "Weapon") and {
                    _id = HttpService:GenerateGUID(false), Skin = State.InspectCharmSkin, Pattern = State.InspectCharmPattern, Position = State.InspectCharmPos
                } or false
                Applier.applySkinConfig({
                    Type = e.type, Name = e.weapon, Skin = e.skin, Rarity = e.rarity, Float = State.InspectFloat,
                    StatTrack = (e.type == "Weapon" or e.type == "Melee") and (State.InspectStatTrak and (tonumber(SkinUI.KillsInput.Text) or 1337) or false) or false,
                    NameTag = (State.InspectNameTag ~= "" and State.InspectNameTag or false),
                    Charm = charmPayload,
                    Pattern = tonumber(string.match(e.skin, "_PATTERN_(%d+)$")),
                })
            end
            SkinUI.rebuildGrid()
        end))

        track(SkinUI.LiveBtn.MouseButton1Click:Connect(function()
            State.LiveForceApply = not State.LiveForceApply
            SkinUI.LiveBtn.Text = State.LiveForceApply and "LIVE APPLY: ON" or "LIVE APPLY: OFF"
            SkinUI.LiveBtn.BackgroundColor3 = State.LiveForceApply and C.ACCENT_DIM or C.CARD_ALT
            SkinUI.LiveBtn.TextColor3 = State.LiveForceApply and C.ACCENT or C.TEXT_DIM
        end))
        track(SkinUI.SyncBtn.MouseButton1Click:Connect(function()
            State.InjectToGameMenu = not State.InjectToGameMenu; State.SyncCasesToMenuInv = State.InjectToGameMenu
            SkinUI.SyncBtn.Text = State.InjectToGameMenu and "MENU INV SYNC: ON" or "MENU INV SYNC: OFF"
            SkinUI.SyncBtn.BackgroundColor3 = State.InjectToGameMenu and C.ACCENT_DIM or C.CARD_ALT
            SkinUI.SyncBtn.TextColor3 = State.InjectToGameMenu and C.ACCENT or C.TEXT_DIM
        end))
        track(SkinUI.ResetBtn.MouseButton1Click:Connect(function()
            State.Overrides.Weapons = {}; State.Overrides.Knife = nil; State.Overrides.Glove = nil; State.Overrides.Badge = nil
            table.clear(Applier.AppliedSigs); notifyStatus("ALL OVERRIDES CLEARED", C.RED); SkinUI.rebuildGrid()
        end))
    end

    --// =====================================================================
    --// WINDOW 2: CASE GATHERER & CS2-STYLE CASE OPENER UI
    --// =====================================================================
    local CaseUI = { ActiveFilter = "ALL", ActiveBottomTab = "POOL", FilterBtns = {} }

    do
        local gui = Instance.new("ScreenGui")
        gui.Name = "BloxStrikeCaseGatherGui"
        gui.ResetOnSpawn = false; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.DisplayOrder = 501; gui.Parent = Env.GuiHost
        CaseUI.Gui = gui
        local sc = Instance.new("UIScale"); sc.Scale = UI.computeScale(); sc.Parent = gui

        local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
        local cPos = (vp.X < 1300) and UDim2.fromOffset(math.max(24, vp.X - 756), 94) or UDim2.new(0.5, -160, 0.5, -250)
        local win = UI.frame(gui, { Name = "CaseGatherWindow", Color = C.BG, Size = UDim2.fromOffset(740, 520), Pos = cPos, Clip = true })
        UI.addStroke(win, C.BORDER, 1); UI.addCorner(win, 6)
        do
            local g = Instance.new("UIGradient"); g.Color = ColorSequence.new(Color3.fromRGB(32, 32, 36), Color3.fromRGB(20, 20, 24)); g.Rotation = 45; g.Parent = win
        end
        CaseUI.Win = win

        local hdr = UI.frame(win, { Color = C.SIDE, Size = UDim2.new(1, 0, 0, 34) })
        UI.frame(hdr, { Color = C.BORDER, Size = UDim2.new(1, 0, 0, 1), Pos = UDim2.new(0, 0, 1, -1) })
        UI.label(hdr, { Text = "CASE GATHERER & UNBOXING", TextColor = C.TEXT, TextSize = 14, Size = UDim2.new(1, -220, 1, 0), Pos = UDim2.fromOffset(14, 0) })
        CaseUI.StatusLabel = UI.label(hdr, { Text = ("STASH: 0 CASES · %d AVAILABLE"):format(#Data.RawCases), TextColor = C.TEXT_DIM, TextSize = 10, XAlign = Enum.TextXAlignment.Right, Size = UDim2.fromOffset(260, 34), Pos = UDim2.new(1, -304, 0, 0) })
        CaseUI.CloseBtn = UI.button(hdr, { Text = "X", Color = C.CARD_ALT, BorderColor = C.BORDER_HI, TextColor = C.TEXT_DIM, TextSize = 11, Size = UDim2.fromOffset(26, 22), Pos = UDim2.new(1, -32, 0, 6) })
        UI.makeDraggable(hdr, win)

        local left = UI.frame(win, { Color = C.SIDE, Size = UDim2.new(0, 310, 1, -34), Pos = UDim2.fromOffset(0, 34) })
        UI.frame(left, { Color = C.BORDER, Size = UDim2.new(0, 1, 1, 0), Pos = UDim2.new(1, -1, 0, 0) })
        local cSearch = Instance.new("TextBox"); cSearch.BackgroundColor3 = C.INPUT; cSearch.BorderSizePixel = 0; cSearch.Font = C.FONT
        cSearch.PlaceholderText = "Search case / package / capsule..."; cSearch.PlaceholderColor3 = C.TEXT_DIM; cSearch.Text = ""
        cSearch.TextColor3 = C.TEXT; cSearch.TextSize = 11; cSearch.ClearTextOnFocus = false; cSearch.Size = UDim2.new(1, -16, 0, 24); cSearch.Position = UDim2.fromOffset(8, 8); cSearch.Parent = left
        UI.addStroke(cSearch, C.BORDER_HI, 1); UI.addCorner(cSearch, 2)
        local cp = Instance.new("UIPadding"); cp.PaddingLeft = UDim.new(0, 6); cp.Parent = cSearch
        CaseUI.SearchBox = cSearch

        local ctBar = UI.frame(left, { Trans = 1, Size = UDim2.new(1, -16, 0, 22), Pos = UDim2.fromOffset(8, 36) })
        local ctl = Instance.new("UIListLayout"); ctl.FillDirection = Enum.FillDirection.Horizontal; ctl.Padding = UDim.new(0, 4); ctl.Parent = ctBar
        CaseUI.TypeBar = ctBar

        local gbBar = UI.frame(left, { Trans = 1, Size = UDim2.new(1, -16, 0, 24), Pos = UDim2.fromOffset(8, 62) })
        CaseUI.Add5AllBtn = UI.button(gbBar, { Text = "+5 ALL CASES", Color = C.ACCENT_DIM, BorderColor = C.ACCENT, TextColor = C.ACCENT, TextSize = 9, Size = UDim2.fromOffset(92, 22), Pos = UDim2.fromOffset(0, 0) })
        CaseUI.Add25AllBtn = UI.button(gbBar, { Text = "+25 ALL", Color = C.CARD_ALT, BorderColor = C.GOLD, TextColor = C.GOLD, TextSize = 9, Size = UDim2.fromOffset(70, 22), Pos = UDim2.fromOffset(96, 0) })
        CaseUI.ClearStashBtn = UI.button(gbBar, { Text = "CLEAR STASH", Color = C.CARD_ALT, BorderColor = C.RED, TextColor = C.RED, TextSize = 9, Size = UDim2.fromOffset(84, 22), Pos = UDim2.fromOffset(170, 0) })

        local catScroll = Instance.new("ScrollingFrame"); catScroll.BackgroundColor3 = C.INPUT; catScroll.BorderSizePixel = 0
        catScroll.ScrollBarThickness = 4; catScroll.ScrollBarImageColor3 = C.GOLD; catScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; catScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        catScroll.Size = UDim2.new(1, -16, 1, -98); catScroll.Position = UDim2.fromOffset(8, 90); catScroll.Parent = left; UI.addStroke(catScroll, C.BORDER, 1)
        local ccl = Instance.new("UIListLayout"); ccl.Padding = UDim.new(0, 5); ccl.Parent = catScroll
        local ccp = Instance.new("UIPadding"); ccp.PaddingLeft = UDim.new(0, 5); ccp.PaddingRight = UDim.new(0, 5); ccp.PaddingTop = UDim.new(0, 5); ccp.Parent = catScroll
        CaseUI.CatalogScroll = catScroll

        local right = UI.frame(win, { Color = C.BG, Size = UDim2.new(1, -310, 1, -34), Pos = UDim2.fromOffset(310, 34) })
        local selHdr = UI.frame(right, { Color = C.CARD, Size = UDim2.new(1, -16, 0, 62), Pos = UDim2.fromOffset(8, 8) })
        UI.addStroke(selHdr, C.BORDER_HI, 1); UI.addCorner(selHdr, 2)
        local sImg = Instance.new("ImageLabel"); sImg.BackgroundTransparency = 1; sImg.ScaleType = Enum.ScaleType.Fit
        sImg.Size = UDim2.fromOffset(50, 50); sImg.Position = UDim2.fromOffset(6, 6); sImg.Parent = selHdr
        CaseUI.SelImg = sImg
        CaseUI.SelTitle = UI.label(selHdr, { Text = "WINTER 2025", TextColor = C.GOLD, TextSize = 13, Size = UDim2.new(1, -180, 0, 20), Pos = UDim2.fromOffset(64, 6) })
        CaseUI.SelOdds = UI.label(selHdr, { Text = "Odds loading...", TextColor = C.TEXT_DIM, TextSize = 9, Size = UDim2.new(1, -72, 0, 28), Pos = UDim2.fromOffset(64, 28), Wrapped = true })
        CaseUI.SelStashBadge = UI.label(selHdr, { Text = "STASH: 0", TextColor = C.ACCENT, TextSize = 11, XAlign = Enum.TextXAlignment.Right, Size = UDim2.fromOffset(100, 20), Pos = UDim2.new(1, -108, 0, 6) })

        local rBox = UI.frame(right, { Name = "RollerBox", Color = C.INPUT, Size = UDim2.new(1, -16, 0, 96), Pos = UDim2.fromOffset(8, 76), Clip = true })
        UI.addStroke(rBox, C.GOLD, 1, 0.45); UI.addCorner(rBox, 2)
        CaseUI.RollerBox = rBox
        CaseUI.RollerStrip = UI.frame(rBox, { Trans = 1, Size = UDim2.new(0, 7000, 1, -12), Pos = UDim2.fromOffset(0, 6) })
        UI.frame(rBox, { Color = C.GOLD, Size = UDim2.new(0, 2, 1, 0), Pos = UDim2.new(0.5, -1, 0, 0), Z = 10 })

        local rbBar = UI.frame(right, { Trans = 1, Size = UDim2.new(1, -16, 0, 30), Pos = UDim2.fromOffset(8, 178) })
        CaseUI.Open1Btn = UI.button(rbBar, { Text = "OPEN CASE (1x)", Color = C.ACCENT_DIM, BorderColor = C.ACCENT, TextColor = C.ACCENT, TextSize = 11, Size = UDim2.fromOffset(124, 28), Pos = UDim2.fromOffset(0, 1) })
        CaseUI.Open5Btn = UI.button(rbBar, { Text = "MULTI (5x)", Color = C.CARD_ALT, BorderColor = C.GOLD, TextColor = C.GOLD, TextSize = 10, Size = UDim2.fromOffset(92, 28), Pos = UDim2.fromOffset(128, 1) })
        CaseUI.QuickBtn = UI.button(rbBar, { Text = "QUICK: OFF", Color = C.CARD_ALT, BorderColor = C.BORDER_HI, TextColor = C.TEXT_DIM, TextSize = 10, Size = UDim2.fromOffset(88, 28), Pos = UDim2.fromOffset(224, 1) })
        CaseUI.View3DBtn = UI.button(rbBar, { Text = "3D CASE", Color = C.CARD_ALT, BorderColor = C.GOLD, TextColor = C.GOLD, TextSize = 10, Size = UDim2.fromOffset(96, 28), Pos = UDim2.fromOffset(316, 1) })

        local stBar = UI.frame(right, { Trans = 1, Size = UDim2.new(1, -16, 0, 22), Pos = UDim2.fromOffset(8, 214) })
        CaseUI.TabPoolBtn = UI.button(stBar, { Text = "CASE CONTENTS & ODDS", Color = C.ACCENT_DIM, BorderColor = C.ACCENT, TextColor = C.ACCENT, TextSize = 10, Size = UDim2.fromOffset(172, 22), Pos = UDim2.fromOffset(0, 0) })
        CaseUI.TabWonBtn = UI.button(stBar, { Text = "UNBOXED STASH (0)", Color = C.CARD_ALT, BorderColor = C.BORDER, TextColor = C.TEXT_DIM, TextSize = 10, Size = UDim2.fromOffset(162, 22), Pos = UDim2.fromOffset(178, 0) })

        local bScroll = Instance.new("ScrollingFrame"); bScroll.BackgroundColor3 = C.INPUT; bScroll.BorderSizePixel = 0
        bScroll.ScrollBarThickness = 4; bScroll.ScrollBarImageColor3 = C.GOLD; bScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; bScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        bScroll.Size = UDim2.new(1, -16, 1, -248); bScroll.Position = UDim2.fromOffset(8, 240); bScroll.Parent = right; UI.addStroke(bScroll, C.BORDER, 1)
        local cbl = Instance.new("UIListLayout"); cbl.Padding = UDim.new(0, 4); cbl.Parent = bScroll
        local cbp = Instance.new("UIPadding"); cbp.PaddingLeft = UDim.new(0, 6); cbp.PaddingRight = UDim.new(0, 6); cbp.PaddingTop = UDim.new(0, 6); cbp.Parent = bScroll
        CaseUI.BottomScroll = bScroll
    end

    -- Weighted RNG Helpers
    local function pickWeighted(entries)
        if not entries or #entries == 0 then return nil end
        local total = 0
        for _, it in ipairs(entries) do total += math.max(tonumber(it.weight) or 1, 0) end
        if total <= 0 then return entries[math.random(1, #entries)] end
        local r, acc = math.random() * total, 0
        for _, it in ipairs(entries) do
            acc += math.max(tonumber(it.weight) or 1, 0)
            if r <= acc then return it end
        end
        return entries[#entries]
    end

    local function rollFloat(skinInfo)
        local minF = (skinInfo and skinInfo.floatRange and skinInfo.floatRange.min) or 0
        local maxF = (skinInfo and skinInfo.floatRange and skinInfo.floatRange.max) or 1
        local fChances = skinInfo and skinInfo.floatChances
        if type(fChances) == "table" and #fChances > 0 then
            local tot = 0
            for _, fc in ipairs(fChances) do tot += (fc.chance or 0) end
            if tot > 0 then
                local r, acc, chosen = math.random() * tot, 0, fChances[1].wear
                for _, fc in ipairs(fChances) do
                    acc += (fc.chance or 0)
                    if r <= acc then chosen = fc.wear; break end
                end
                for _, wt in ipairs(C.WEAR_TIERS) do
                    if wt.name == chosen then
                        local lo, hi = math.max(minF, wt.min), math.min(maxF, wt.max)
                        if hi < lo then hi = lo end
                        return lo + math.random() * (hi - lo)
                    end
                end
            end
        end
        return minF + math.random() * math.max(maxF - minF, 0.001)
    end

    local function rollCaseDrop(caseObj)
        local spChance = tonumber(caseObj.specialChance) or 0
        local hasSp = type(caseObj.specialContents) == "table" and #caseObj.specialContents > 0
        local picked
        if hasSp and spChance > 0 and (math.random() * 100) <= spChance then
            picked = pickWeighted(caseObj.specialContents)
        end
        if not picked then
            local byRar = {}
            for _, c in ipairs(caseObj.contents or {}) do
                local r = c.rarity or "Blue"; byRar[r] = byRar[r] or {}; table.insert(byRar[r], c)
            end
            local pool = {}
            for _, rc in ipairs(caseObj.rarityChances or {}) do
                if byRar[rc.rarity] and #byRar[rc.rarity] > 0 then table.insert(pool, { rarity = rc.rarity, chance = rc.chance }) end
            end
            local chosenRar
            if #pool > 0 then
                local tot = 0; for _, rp in ipairs(pool) do tot += rp.chance end
                local r, acc = math.random() * tot, 0
                for _, rp in ipairs(pool) do acc += rp.chance; if r <= acc then chosenRar = rp.rarity; break end end
            end
            picked = (chosenRar and byRar[chosenRar]) and pickWeighted(byRar[chosenRar]) or pickWeighted(caseObj.contents)
        end
        if not picked then return nil end

        local sk = picked.skin or {}
        local wName, sName, iType = sk.weaponName or "AK-47", sk.skinName or "Stock", sk.type or "Weapon"
        local sInfo = Data.RawSkins[wName] and Data.RawSkins[wName][sName]
        local statTrack = false
        if sInfo and sInfo.supportsStatTrak and (math.random() * 100) <= (tonumber(sInfo.statTrakChance) or 10) then statTrack = 0 end
        local pat
        if iType == "Charm" and sInfo and type(sInfo.charmImages) == "table" and #sInfo.charmImages > 0 then
            pat = math.random(1, #sInfo.charmImages)
        elseif type(sName) == "string" then
            pat = tonumber(string.match(sName, "_PATTERN_(%d+)$"))
        end
        return {
            poolEntry = picked,
            info = sInfo,
            isSpecial = picked.isSpecial == true or picked.rarity == "Special",
            item = Applier.makeItemStruct({
                Type = iType, Name = wName, Skin = sName, Rarity = picked.rarity or (sInfo and sInfo.rarity) or "Blue",
                Float = rollFloat(sInfo), StatTrack = statTrack, Pattern = pat, Origin = "Unboxed (" .. (caseObj.name or "Case") .. ")",
            }),
        }
    end

    function CaseUI.updateHeaders()
        local tot = 0; for _, v in pairs(State.CaseStash) do tot += v end
        CaseUI.StatusLabel.Text = ("STASH: %d CASES · %d AVAILABLE"):format(tot, #Data.RawCases)
        CaseUI.TabWonBtn.Text = ("UNBOXED STASH (%d)"):format(#State.UnboxedItems)
        if State.SelectedCase then
            CaseUI.SelStashBadge.Text = ("STASH: %d"):format(State.CaseStash[State.SelectedCase.caseId or State.SelectedCase.name] or 0)
        end
    end

    function CaseUI.addCases(caseObj, qty)
        local cid = caseObj.caseId or caseObj.name
        State.CaseStash[cid] = (State.CaseStash[cid] or 0) + qty
        if State.SyncCasesToMenuInv and Modules.DataController then
            local batch = {}
            local bType = caseObj.caseType or "Case"
            for _ = 1, math.min(qty, 25) do
                table.insert(batch, Applier.makeItemStruct({
                    Type = bType, Name = bType, Skin = caseObj.name, Rarity = caseObj.caseRarity or "Red", Float = 0, Origin = "CaseGatherer",
                }))
            end
            callRestored(function() Modules.DataController.ApplyInventoryDelta(LocalPlayer, batch, {}) end)
        end
        CaseUI.updateHeaders()
    end

    function CaseUI.rebuildBottom()
        for _, ch in ipairs(CaseUI.BottomScroll:GetChildren()) do if ch:IsA("Frame") then ch:Destroy() end end
        local onPool = (CaseUI.ActiveBottomTab == "POOL")
        CaseUI.TabPoolBtn.BackgroundColor3 = onPool and C.ACCENT_DIM or C.CARD_ALT
        CaseUI.TabPoolBtn.TextColor3 = onPool and C.ACCENT or C.TEXT_DIM
        CaseUI.TabWonBtn.BackgroundColor3 = (not onPool) and C.ACCENT_DIM or C.CARD_ALT
        CaseUI.TabWonBtn.TextColor3 = (not onPool) and C.GOLD or C.TEXT_DIM

        if onPool then
            local cObj = State.SelectedCase; if not cObj then return end
            local pool = {}
            for _, sp in ipairs(cObj.specialContents or {}) do table.insert(pool, sp) end
            for _, ct in ipairs(cObj.contents or {}) do table.insert(pool, ct) end
            table.sort(pool, function(a, b) return (C.RARITY_RANK[a.rarity] or 0) > (C.RARITY_RANK[b.rarity] or 0) end)
            for _, it in ipairs(pool) do
                local sk = it.skin or {}; local wName, sName = sk.weaponName or "?", sk.skinName or "?"
                local rCol = Helpers.getRarityColor(it.rarity or "Blue")
                local sInfo = Data.RawSkins[wName] and Data.RawSkins[wName][sName]
                local row = UI.frame(CaseUI.BottomScroll, { Color = C.CARD, Size = UDim2.new(1, -4, 0, 44) })
                UI.addStroke(row, C.BORDER, 1); UI.addCorner(row, 2); UI.frame(row, { Color = rCol, Size = UDim2.new(0, 3, 1, 0) })
                local img = Instance.new("ImageLabel"); img.BackgroundTransparency = 1; img.ScaleType = Enum.ScaleType.Fit
                img.Image = Helpers.getThumbAsset(sInfo, 0.05, 1); img.Size = UDim2.fromOffset(36, 36); img.Position = UDim2.fromOffset(8, 4); img.Parent = row
                UI.label(row, { Text = ("%s%s | %s"):format(it.isSpecial and "★ " or "", wName, Helpers.cleanSkin(sName)), TextColor = rCol, TextSize = 11, Size = UDim2.new(1, -130, 0, 18), Pos = UDim2.fromOffset(50, 4) })
                UI.label(row, { Text = ("%s · %s"):format(it.rarity or "?", sk.type or "Weapon"), TextColor = C.TEXT_DIM, TextSize = 9, Size = UDim2.new(1, -130, 0, 14), Pos = UDim2.fromOffset(50, 24) })
                local pb = UI.button(row, { Text = "3D VIEW", Color = C.CARD_ALT, BorderColor = C.BORDER_HI, TextColor = C.TEXT, TextSize = 9, Size = UDim2.fromOffset(66, 24), Pos = UDim2.new(1, -72, 0, 10) })
                track(pb.MouseButton1Click:Connect(function()
                    for _, e in ipairs(Data.SkinsByWeapon[wName] or {}) do
                        if e.skin == sName then SkinUI.Win.Visible = true; SkinUI.selectEntry(e); break end
                    end
                end))
            end
        else
            for i = #State.UnboxedItems, 1, -1 do
                local it = State.UnboxedItems[i]
                local rCol = Helpers.getRarityColor(it.Rarity)
                local sInfo = Data.RawSkins[it.Name] and Data.RawSkins[it.Name][it.Skin]
                local _, wShort = Helpers.getWearName(it.Float)
                local row = UI.frame(CaseUI.BottomScroll, { Color = C.CARD, Size = UDim2.new(1, -4, 0, 48) })
                UI.addStroke(row, rCol, 1, 0.45); UI.addCorner(row, 2); UI.frame(row, { Color = rCol, Size = UDim2.new(0, 3, 1, 0) })
                local img = Instance.new("ImageLabel"); img.BackgroundTransparency = 1; img.ScaleType = Enum.ScaleType.Fit
                img.Image = Helpers.getThumbAsset(sInfo, it.Float, it.Pattern or 1); img.Size = UDim2.fromOffset(38, 38); img.Position = UDim2.fromOffset(8, 5); img.Parent = row
                UI.label(row, { Text = ("%s%s | %s"):format(it.StatTrack ~= false and "[KT] " or "", it.Name, Helpers.cleanSkin(it.Skin)), TextColor = rCol, TextSize = 11, Size = UDim2.new(1, -190, 0, 18), Pos = UDim2.fromOffset(52, 5) })
                UI.label(row, { Text = ("%s %.4f · #%d · %s"):format(wShort, it.Float, it.Serial or 0, it.MetaData and it.MetaData.Origin or "Unboxed"), TextColor = C.TEXT_DIM, TextSize = 9, Size = UDim2.new(1, -190, 0, 14), Pos = UDim2.fromOffset(52, 26) })
                local pb = UI.button(row, { Text = "3D", Color = C.CARD_ALT, BorderColor = C.BORDER_HI, TextColor = C.TEXT, TextSize = 9, Size = UDim2.fromOffset(34, 24), Pos = UDim2.new(1, -118, 0, 12) })
                local eb = UI.button(row, { Text = "APPLY SKIN", Color = C.ACCENT_DIM, BorderColor = C.ACCENT, TextColor = C.ACCENT, TextSize = 9, Size = UDim2.fromOffset(74, 24), Pos = UDim2.new(1, -80, 0, 12) })
                track(pb.MouseButton1Click:Connect(function()
                    for _, e in ipairs(Data.SkinsByWeapon[it.Name] or {}) do
                        if e.skin == it.Skin then State.InspectFloat = it.Float; State.InspectStatTrak = it.StatTrack ~= false; SkinUI.Win.Visible = true; SkinUI.selectEntry(e); break end
                    end
                end))
                track(eb.MouseButton1Click:Connect(function() Applier.applySkinConfig(it); SkinUI.rebuildGrid() end))
            end
        end
    end

    function CaseUI.refreshSelected()
        local cObj = State.SelectedCase; if not cObj then return end
        CaseUI.SelTitle.Text = string.upper(cObj.name or "CASE")
        CaseUI.SelTitle.TextColor3 = Helpers.getRarityColor(cObj.caseRarity or "Special")
        CaseUI.SelImg.Image = cObj.imageAssetId or ""
        local parts = {}
        for _, rc in ipairs(cObj.rarityChances or {}) do table.insert(parts, ("%s %.1f%%"):format(rc.rarity, rc.chance)) end
        if tonumber(cObj.specialChance) and tonumber(cObj.specialChance) > 0 then table.insert(parts, ("★ %.2f%%"):format(cObj.specialChance)) end
        CaseUI.SelOdds.Text = (#parts > 0) and table.concat(parts, " · ") or (cObj.description or "Drop Package")
        CaseUI.updateHeaders()
        if CaseUI.ActiveBottomTab == "POOL" then CaseUI.rebuildBottom() end
    end

    function CaseUI.rebuildCatalog()
        for _, ch in ipairs(CaseUI.CatalogScroll:GetChildren()) do if ch:IsA("Frame") then ch:Destroy() end end
        local q = string.lower(CaseUI.SearchBox.Text or "")
        for _, cObj in ipairs(Data.RawCases) do
            local cType = cObj.caseType or "Case"
            local mType = (CaseUI.ActiveFilter == "ALL") or (CaseUI.ActiveFilter == cType) or (CaseUI.ActiveFilter == "Capsule/Console" and cType ~= "Case" and cType ~= "Package")
            local mQ = (q == "" or string.find(string.lower(cObj.name .. " " .. cType), q, 1, true) ~= nil)
            if mType and mQ then
                local cid = cObj.caseId or cObj.name
                local count = State.CaseStash[cid] or 0
                local rCol = Helpers.getRarityColor(cObj.caseRarity or "Red")
                local isSel = (State.SelectedCase == cObj)
                local row = UI.frame(CaseUI.CatalogScroll, { Color = isSel and C.CARD_ALT or C.CARD, Size = UDim2.new(1, -6, 0, 56) })
                UI.addStroke(row, isSel and C.GOLD or C.BORDER, 1); UI.addCorner(row, 2); UI.frame(row, { Color = rCol, Size = UDim2.new(0, 3, 1, 0) })
                local img = Instance.new("ImageLabel"); img.BackgroundTransparency = 1; img.ScaleType = Enum.ScaleType.Fit
                img.Image = cObj.imageAssetId or ""; img.Size = UDim2.fromOffset(40, 40); img.Position = UDim2.fromOffset(8, 8); img.Parent = row
                local sb = Instance.new("TextButton"); sb.BackgroundTransparency = 1; sb.Text = ""; sb.Size = UDim2.new(1, -134, 1, 0); sb.Position = UDim2.fromOffset(4, 0); sb.Parent = row
                track(sb.MouseButton1Click:Connect(function() State.SelectedCase = cObj; CaseUI.refreshSelected(); CaseUI.rebuildCatalog() end))
                UI.label(row, { Text = cObj.name, TextColor = isSel and C.GOLD or C.TEXT, TextSize = 11, Size = UDim2.new(1, -184, 0, 18), Pos = UDim2.fromOffset(52, 6) })
                UI.label(row, { Text = ("%s · %d items · %d★ · Stash:%d"):format(cType, cObj.contents and #cObj.contents or 0, cObj.specialContents and #cObj.specialContents or 0, count), TextColor = count > 0 and C.ACCENT or C.TEXT_DIM, TextSize = 9, Size = UDim2.new(1, -184, 0, 16), Pos = UDim2.fromOffset(52, 28) })
                local a1 = UI.button(row, { Text = "+1", Color = C.CARD_ALT, BorderColor = C.ACCENT, TextColor = C.ACCENT, TextSize = 9, Size = UDim2.fromOffset(32, 24), Pos = UDim2.new(1, -110, 0, 16) })
                local a5 = UI.button(row, { Text = "+5", Color = C.CARD_ALT, BorderColor = C.GOLD, TextColor = C.GOLD, TextSize = 9, Size = UDim2.fromOffset(32, 24), Pos = UDim2.new(1, -74, 0, 16) })
                local a25 = UI.button(row, { Text = "+25", Color = C.CARD_ALT, BorderColor = C.BORDER_HI, TextColor = C.TEXT, TextSize = 9, Size = UDim2.fromOffset(34, 24), Pos = UDim2.new(1, -38, 0, 16) })
                track(a1.MouseButton1Click:Connect(function() CaseUI.addCases(cObj, 1); State.SelectedCase = cObj; CaseUI.rebuildCatalog(); CaseUI.refreshSelected() end))
                track(a5.MouseButton1Click:Connect(function() CaseUI.addCases(cObj, 5); State.SelectedCase = cObj; CaseUI.rebuildCatalog(); CaseUI.refreshSelected() end))
                track(a25.MouseButton1Click:Connect(function() CaseUI.addCases(cObj, 25); State.SelectedCase = cObj; CaseUI.rebuildCatalog(); CaseUI.refreshSelected() end))
            end
        end
    end

    local TILE_W, TILE_GAP = 86, 6
    local function mkRollerTile(xOff, drop, hideSpec)
        local rCol = Helpers.getRarityColor(drop.item.Rarity)
        local tile = UI.frame(CaseUI.RollerStrip, { Color = C.CARD, Size = UDim2.fromOffset(TILE_W, 80), Pos = UDim2.fromOffset(xOff, 2) })
        UI.addStroke(tile, rCol, 1, 0.25); UI.addCorner(tile, 2); UI.frame(tile, { Color = rCol, Size = UDim2.new(1, 0, 0, 3) })
        if drop.isSpecial and hideSpec then
            UI.label(tile, { Text = "★", TextColor = C.GOLD, TextSize = 26, XAlign = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 46), Pos = UDim2.fromOffset(0, 6) })
            UI.label(tile, { Text = "SPECIAL", TextColor = C.GOLD, TextSize = 9, XAlign = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 16), Pos = UDim2.fromOffset(0, 56) })
        else
            local img = Instance.new("ImageLabel"); img.BackgroundTransparency = 1; img.ScaleType = Enum.ScaleType.Fit
            img.Image = Helpers.getThumbAsset(drop.info, drop.item.Float, drop.item.Pattern or 1)
            img.Size = UDim2.fromOffset(52, 46); img.Position = UDim2.fromOffset(17, 6); img.Parent = tile
            UI.label(tile, { Text = Helpers.cleanSkin(drop.item.Skin), TextColor = rCol, TextSize = 9, XAlign = Enum.TextXAlignment.Center, Size = UDim2.new(1, -6, 0, 18), Pos = UDim2.fromOffset(3, 56) })
        end
        return tile
    end

    local function playDropSound(rar)
        if not Modules.Router then return end
        local sn = (rar == "Special" or rar == "Forbidden") and "Drop Gold" or (rar == "Red" and "Drop Red") or (rar == "Pink" and "Drop Pink") or (rar == "Purple" and "Drop Purple") or "Drop Blue"
        pcall(function() callRestored(Modules.Router.broadcastRouter, "RunStoreSound", sn) end)
    end

    function CaseUI.openCase(count, forceQuick)
        local cObj = State.SelectedCase; if not cObj or State.IsSpinning then return end
        local cid = cObj.caseId or cObj.name
        if (State.CaseStash[cid] or 0) < count then CaseUI.addCases(cObj, count - (State.CaseStash[cid] or 0)) end
        State.CaseStash[cid] = math.max(0, (State.CaseStash[cid] or 0) - count)

        local function commitDrop(d)
            table.insert(State.UnboxedItems, d.item)
            if State.SyncCasesToMenuInv then Applier.injectToClientMenu(d.item, false) end
        end

        if forceQuick or State.QuickOpen or count > 1 then
            local last
            for _ = 1, count do
                local d = rollCaseDrop(cObj)
                if d then commitDrop(d); last = d end
            end
            if last then
                for _, ch in ipairs(CaseUI.RollerStrip:GetChildren()) do ch:Destroy() end
                CaseUI.RollerStrip.Position = UDim2.fromOffset(math.max(CaseUI.RollerBox.AbsoluteSize.X * 0.5 - TILE_W * 0.5, 100), 6)
                mkRollerTile(0, last, false)
                playDropSound(last.item.Rarity)
                notifyStatus(("UNBOXED %dx! LAST: %s | %s"):format(count, last.item.Name, Helpers.cleanSkin(last.item.Skin)), Helpers.getRarityColor(last.item.Rarity))
            end
            CaseUI.ActiveBottomTab = "WON"; CaseUI.updateHeaders(); CaseUI.rebuildCatalog(); CaseUI.rebuildBottom()
            return
        end

        local winner = rollCaseDrop(cObj); if not winner then return end
        State.IsSpinning = true; CaseUI.Open1Btn.Text = "OPENING..."
        for _, ch in ipairs(CaseUI.RollerStrip:GetChildren()) do ch:Destroy() end
        CaseUI.RollerStrip.Position = UDim2.fromOffset(0, 6)

        local WIN_SLOT, TOTAL_SLOTS, winTile = 52, 62, nil
        for i = 1, TOTAL_SLOTS do
            local x = (i - 1) * (TILE_W + TILE_GAP)
            if i == WIN_SLOT then winTile = mkRollerTile(x, winner, winner.isSpecial)
            else local dec = rollCaseDrop(cObj); if dec then mkRollerTile(x, dec, dec.isSpecial) end end
        end
        if Modules.Router then pcall(function() callRestored(Modules.Router.broadcastRouter, "RunStoreSound", "Case Opening") end) end

        local viewW = math.max(CaseUI.RollerBox.AbsoluteSize.X, 400)
        local targetX = -((WIN_SLOT - 1) * (TILE_W + TILE_GAP) + TILE_W * 0.5 + math.random(-24, 24)) + viewW * 0.5
        local tw = TweenService:Create(CaseUI.RollerStrip, TweenInfo.new(3.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.fromOffset(targetX, 6) })
        tw:Play()
        tw.Completed:Once(function()
            if Env.IsDestroyed then return end
            if winner.isSpecial and winTile then winTile:Destroy(); mkRollerTile((WIN_SLOT - 1) * (TILE_W + TILE_GAP), winner, false) end
            commitDrop(winner); playDropSound(winner.item.Rarity)
            notifyStatus(("UNBOXED: %s | %s (%.4f)"):format(winner.item.Name, Helpers.cleanSkin(winner.item.Skin), winner.item.Float), Helpers.getRarityColor(winner.item.Rarity))
            State.IsSpinning = false; CaseUI.Open1Btn.Text = "OPEN CASE (1x)"
            CaseUI.ActiveBottomTab = "WON"; CaseUI.updateHeaders(); CaseUI.rebuildCatalog(); CaseUI.rebuildBottom()
        end)
    end

    -- Connect CaseUI Events
    do
        for _, ct in ipairs({ "ALL", "Case", "Package", "Capsule/Console" }) do
            local b = UI.button(CaseUI.TypeBar, { Text = ct == "Capsule/Console" and "OTHER" or ct:upper(), Color = (ct == CaseUI.ActiveFilter) and C.ACCENT_DIM or C.INPUT, BorderColor = (ct == CaseUI.ActiveFilter) and C.ACCENT or C.BORDER, TextColor = (ct == CaseUI.ActiveFilter) and C.ACCENT or C.TEXT_DIM, TextSize = 9, Size = UDim2.fromOffset(68, 20) })
            CaseUI.FilterBtns[ct] = b
            track(b.MouseButton1Click:Connect(function()
                CaseUI.ActiveFilter = ct
                for k, fb in pairs(CaseUI.FilterBtns) do
                    local on = (k == CaseUI.ActiveFilter)
                    fb.BackgroundColor3 = on and C.ACCENT_DIM or C.INPUT; fb.TextColor3 = on and C.ACCENT or C.TEXT_DIM
                    local st = fb:FindFirstChildOfClass("UIStroke"); if st then st.Color = on and C.ACCENT or C.BORDER end
                end
                CaseUI.rebuildCatalog()
            end))
        end

        track(CaseUI.Open1Btn.MouseButton1Click:Connect(function() CaseUI.openCase(1, false) end))
        track(CaseUI.Open5Btn.MouseButton1Click:Connect(function() CaseUI.openCase(5, true) end))
        track(CaseUI.QuickBtn.MouseButton1Click:Connect(function()
            State.QuickOpen = not State.QuickOpen
            CaseUI.QuickBtn.Text = State.QuickOpen and "QUICK: ON" or "QUICK: OFF"
            CaseUI.QuickBtn.BackgroundColor3 = State.QuickOpen and C.ACCENT_DIM or C.CARD_ALT
            CaseUI.QuickBtn.TextColor3 = State.QuickOpen and C.ACCENT or C.TEXT_DIM
        end))
        track(CaseUI.View3DBtn.MouseButton1Click:Connect(function()
            local cObj = State.SelectedCase; if not cObj then return end
            local assets = ReplicatedStorage:FindFirstChild("Assets")
            local mdlFolder = assets and (assets:FindFirstChild("CaseModels") or assets:FindFirstChild("ConsoleModels"))
            local tmpl = (assets and assets:FindFirstChild("CaseModels") and assets.CaseModels:FindFirstChild(cObj.name))
                or (assets and assets:FindFirstChild("ConsoleModels") and assets.ConsoleModels:FindFirstChild(cObj.name))
                or (mdlFolder and mdlFolder:FindFirstChild("Winter 2025"))
            if tmpl then
                SkinUI.Win.Visible = true
                SkinUI.loadPreviewModel(tmpl:Clone(), cObj.name, ("%s · %d items"):format(cObj.caseType or "Case", cObj.contents and #cObj.contents or 0), Helpers.getRarityColor(cObj.caseRarity or "Special"), cObj.imageAssetId, 0.65)
            end
        end))
        track(CaseUI.Add5AllBtn.MouseButton1Click:Connect(function()
            for _, cObj in ipairs(Data.RawCases) do CaseUI.addCases(cObj, 5) end
            CaseUI.rebuildCatalog(); CaseUI.refreshSelected(); notifyStatus(("GATHERED +5 OF ALL %d CASES!"):format(#Data.RawCases), C.ACCENT)
        end))
        track(CaseUI.Add25AllBtn.MouseButton1Click:Connect(function()
            for _, cObj in ipairs(Data.RawCases) do CaseUI.addCases(cObj, 25) end
            CaseUI.rebuildCatalog(); CaseUI.refreshSelected(); notifyStatus(("GATHERED +25 OF ALL %d CASES!"):format(#Data.RawCases), C.GOLD)
        end))
        track(CaseUI.ClearStashBtn.MouseButton1Click:Connect(function()
            for k in pairs(State.CaseStash) do State.CaseStash[k] = 0 end
            CaseUI.updateHeaders(); CaseUI.rebuildCatalog()
        end))
        track(CaseUI.SearchBox:GetPropertyChangedSignal("Text"):Connect(CaseUI.rebuildCatalog))
        track(CaseUI.TabPoolBtn.MouseButton1Click:Connect(function() CaseUI.ActiveBottomTab = "POOL"; CaseUI.rebuildBottom() end))
        track(CaseUI.TabWonBtn.MouseButton1Click:Connect(function() CaseUI.ActiveBottomTab = "WON"; CaseUI.rebuildBottom() end))
    end

    -- Window Toggle Sync
    local function syncWindowToggles()
        SkinUI.SkinsPill.BackgroundColor3 = SkinUI.Win.Visible and C.ACCENT_DIM or C.CARD_ALT
        SkinUI.SkinsPill.TextColor3 = SkinUI.Win.Visible and C.ACCENT or C.TEXT_DIM
        SkinUI.CasesPill.BackgroundColor3 = CaseUI.Win.Visible and Color3.fromRGB(52, 42, 10) or C.CARD_ALT
        SkinUI.CasesPill.TextColor3 = CaseUI.Win.Visible and C.GOLD or C.TEXT_DIM
    end
    track(SkinUI.SkinsPill.MouseButton1Click:Connect(function() SkinUI.Win.Visible = not SkinUI.Win.Visible; syncWindowToggles() end))
    track(SkinUI.CasesPill.MouseButton1Click:Connect(function() CaseUI.Win.Visible = not CaseUI.Win.Visible; syncWindowToggles() end))
    track(SkinUI.OpenCaseQuickBtn.MouseButton1Click:Connect(function() CaseUI.Win.Visible = true; syncWindowToggles() end))
    track(SkinUI.CloseBtn.MouseButton1Click:Connect(function() SkinUI.Win.Visible = false; syncWindowToggles() end))
    track(CaseUI.CloseBtn.MouseButton1Click:Connect(function() CaseUI.Win.Visible = false; syncWindowToggles() end))

    -- Initial Populate (deferred across frames so startup never freezes main thread)
    SkinUI.Win.Visible = false
    CaseUI.Win.Visible = false
    syncWindowToggles()

    task.spawn(function()
        task.wait()
        if Env.IsDestroyed then return end
        SkinUI.rebuildWeaponStrip()
        task.wait()
        if Env.IsDestroyed then return end
        SkinUI.rebuildGrid()
        task.wait()
        if Env.IsDestroyed then return end
        if Data.SkinsByWeapon["AK-47"] and Data.SkinsByWeapon["AK-47"][2] then
            SkinUI.selectEntry(Data.SkinsByWeapon["AK-47"][2])
        elseif Data.AllSkinsFlat[1] then
            SkinUI.selectEntry(Data.AllSkinsFlat[1])
        end
        task.wait()
        if Env.IsDestroyed then return end
        CaseUI.rebuildCatalog()
        CaseUI.refreshSelected()
    end)

    -- BUG FIX: `(v == nil) and not Visible or v` evaluates to `nil` when the window is already visible
    -- (`true and false or nil`), and assigning nil to Visible throws - so these buttons could open a window
    -- but never close it again. Resolve the target value explicitly.
    local function setVisible(win, v)
        if v == nil then v = not win.Visible end
        win.Visible = v and true or false
        syncWindowToggles()
    end

    local MergedApi = {
        State = State,
        SkinCount = #Data.AllSkinsFlat,
        CaseCount = #Data.RawCases,
        SelectEntry = SkinUI.selectEntry,
        ApplySkin = Applier.applySkinConfig,
        AddCases = CaseUI.addCases,
        OpenCase = CaseUI.openCase,
        ToggleSkinsUI = function(v) setVisible(SkinUI.Win, v) end,
        ToggleCasesUI = function(v) setVisible(CaseUI.Win, v) end,
        SetDockVisible = function(v) if SkinUI.Dock then SkinUI.Dock.Visible = v and true or false end end,
        GetPreviewWorld = function() return SkinUI.World end,
    }
    _G.__BloxStrikeSkinChanger = MergedApi

    local function mergedCleanup()
        Env.IsDestroyed = true
        for _, c in ipairs(Env.Connections) do pcall(function() c:Disconnect() end) end
        table.clear(Env.Connections)
        SkinUI.clearPreview()
        pcall(function() SkinUI.Gui:Destroy() end)
        pcall(function() CaseUI.Gui:Destroy() end)
        -- only clear the shared globals if they still point at US (a standalone skin changer may have replaced them)
        if _G.__BloxStrikeSkinChanger == MergedApi then _G.__BloxStrikeSkinChanger = nil end
        if _G.__BloxStrikeSkinChangerCleanup == mergedCleanup then _G.__BloxStrikeSkinChangerCleanup = nil end
        if _G.__BloxStrikeMergedSkinCleanup == mergedCleanup then _G.__BloxStrikeMergedSkinCleanup = nil end
    end
    _G.__BloxStrikeSkinChangerCleanup = mergedCleanup   -- lets a standalone skin changer replace us cleanly
    _G.__BloxStrikeMergedSkinCleanup = mergedCleanup    -- used by the suite's own unload (never touches a standalone one)
end, debug.traceback)

if not okMain then
    warn("[BloxStrikeSkinChanger ERROR]", errMain)
end

end
_runMergedSkinSuite()
end

_G.__BloxStrikeSuiteCleanup = cleanup
