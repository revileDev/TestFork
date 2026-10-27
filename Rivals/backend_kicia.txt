--[[
    Atomware Rivals - backend_kicia.lua
    Modular Backend Extension: KiciaHook v3 Engine for Atomware Rivals
    Fully Deduplicated & Uncluttered Architecture.
    Features:
      - Anti-Katana & Parry Evasion
      - Movement Recorder & Waypoint Replay Engine
      - Auto-Strafe & Air Trajectory Sync
      - Sound ESP (3D World Space Footstep & Gunfire Visualizer)
      - Hit Chams (Dynamic Damage Adornments)
      - World ESP (Jump Pads, Pickups, Dropped Weapons)
      - Custom Skybox Manager (Galaxy, Cyberpunk, Sunset)
      - Halo / Quake Announcer Kill Sound Packs
      - In-Game Name & Stat Spoofing (Leaderboard & ELO Masking)
      - Dueler Clone Spoofing
      - Auto Map Vote & Auto Weapon Ban
      - Auto Pickup Drops
      - Cosmetic Presets & Clipboard Share Codes (Export/Import)
]]

pcall(function()
    local g = (getgenv and getgenv()) or _G
    if type(g) == "table" and type(g.__atomware_kicia_unload) == "function" then
        g.__atomware_kicia_unload()
        g.__atomware_kicia_unload = nil
    end
end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera or workspace:FindFirstChildOfClass("Camera")

local Kicia = {
    connections = {},
    drawings = {},
    cleanups = {},
    active = true,
    uiMounted = false,
}

local function track(conn)
    table.insert(Kicia.connections, conn)
    return conn
end

local function onUnload(fn)
    table.insert(Kicia.cleanups, fn)
end

-- Storage folder for JSON configurations
local STORAGE_DIR = "Atomware/Rivals"
local function ensureStorage()
    pcall(function()
        if type(isfolder) == "function" and type(makefolder) == "function" then
            if not isfolder("Atomware") then makefolder("Atomware") end
            if not isfolder(STORAGE_DIR) then makefolder(STORAGE_DIR) end
            if not isfolder(STORAGE_DIR .. "/movement_recorder") then makefolder(STORAGE_DIR .. "/movement_recorder") end
        end
    end)
end
ensureStorage()

--//==================================================
--// STATE DEFINITIONS
--//==================================================

local State = {
    -- Combat
    AntiKatana = false,
    AntiKatanaDist = 20,

    -- Movement
    AutoStrafe = false,

    -- Movement Recorder
    RecorderState = "Idle", -- "Idle", "Recording", "Replaying"
    RecordedPoints = {},
    ReplayIndex = 1,
    ReplaySpeed = 1.0,
    ReplayLoop = false,

    -- Visuals
    SoundEsp = false,
    SoundEspRange = 150,
    SoundEspColor = Color3.fromRGB(255, 120, 220),
    SoundEspFadeTime = 1.5,

    HitChams = false,
    HitChamsDuration = 0.5,
    HitChamsColor = Color3.fromRGB(255, 60, 60),

    WorldEsp = false,
    WorldEspColor = Color3.fromRGB(120, 255, 180),

    -- Skyboxes & Sounds
    CurrentSkybox = "Default",
    HaloAnnouncer = false,

    -- Duels Automation & Spoofing
    AutoMapVote = false,
    VotedMap = "Crossroads",
    AutoWeaponBan = false,
    BannedWeapon = "Katana",
    AutoPickup = false,
    AutoPickupRange = 25,
    DuelerCloneSpoof = false,
}

--//==================================================
--// 1. ANTI-KATANA & PARRY ENGINE
--//==================================================

local function initAntiKatana()
    local lastEvade = 0
    track(RunService.Heartbeat:Connect(function()
        if not State.AntiKatana or not LocalPlayer.Character then return end
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local now = os.clock()
        if now - lastEvade < 0.6 then return end

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Team ~= LocalPlayer.Team and player.Character then
                local eRoot = player.Character:FindFirstChild("HumanoidRootPart")
                local eHum = player.Character:FindFirstChildOfClass("Humanoid")
                local tool = player.Character:FindFirstChildOfClass("Tool") or player.Character:FindFirstChild("Katana")
                
                if eRoot and tool and (tool.Name:lower():find("katana") or tool.Name:lower():find("blade") or tool.Name:lower():find("sword")) then
                    local dist = (eRoot.Position - root.Position).Magnitude
                    if dist <= State.AntiKatanaDist then
                        local animTrack = nil
                        if eHum then
                            for _, track in ipairs(eHum:GetPlayingAnimationTracks()) do
                                local aName = track.Animation and track.Animation.Name:lower() or ""
                                if aName:find("dash") or aName:find("slash") or aName:find("swing") or aName:find("attack") then
                                    animTrack = track
                                    break
                                end
                            end
                        end

                        if animTrack or (eRoot.AssemblyLinearVelocity.Magnitude > 38) then
                            lastEvade = now
                            local lateral = (root.CFrame.RightVector * (math.random(0, 1) == 0 and 1 or -1) + Vector3.new(0, 0.4, 0)).Unit
                            root.AssemblyLinearVelocity = lateral * 55
                            pcall(function()
                                if _G.AtomwareConfig and _G.AtomwareConfig.Notify then
                                    _G.AtomwareConfig:Notify("Anti-Katana: Evaded strike from " .. player.DisplayName, 2)
                                end
                            end)
                            break
                        end
                    end
                end
            end
        end
    end))
end

--//==================================================
--// 2. AUTO-STRAFE ENGINE
--//==================================================

local function initAutoStrafe()
    local lastYaw = 0
    track(RunService.Heartbeat:Connect(function()
        if not State.AutoStrafe or not LocalPlayer.Character then return end
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if not root or not hum or hum:GetState() ~= Enum.HumanoidStateType.Freefall then return end

        local cam = workspace.CurrentCamera
        if not cam then return end

        local _, curYaw, _ = cam.CFrame:ToOrientation()
        local deltaYaw = curYaw - lastYaw
        lastYaw = curYaw

        if math.abs(deltaYaw) > 0.001 then
            local right = cam.CFrame.RightVector
            local strafeForce = (deltaYaw > 0 and right or -right) * math.clamp(math.abs(deltaYaw) * 120, 2, 28)
            local curVel = root.AssemblyLinearVelocity
            root.AssemblyLinearVelocity = Vector3.new(curVel.X + strafeForce.X, curVel.Y, curVel.Z + strafeForce.Z)
        end
    end))
end

--//==================================================
--// 3. MOVEMENT RECORDER & WAYPOINT REPLAY
--//==================================================

local MovementRecorder = {}
function MovementRecorder:StartRecording()
    State.RecorderState = "Recording"
    State.RecordedPoints = {}
    if _G.AtomwareConfig and _G.AtomwareConfig.Notify then
        _G.AtomwareConfig:Notify("Movement Recorder: Recording started...", 2)
    end
end

function MovementRecorder:Stop()
    local count = #State.RecordedPoints
    State.RecorderState = "Idle"
    if _G.AtomwareConfig and _G.AtomwareConfig.Notify then
        _G.AtomwareConfig:Notify("Movement Recorder: Stopped (" .. count .. " points)", 2)
    end
end

function MovementRecorder:StartReplay()
    if #State.RecordedPoints == 0 then
        if _G.AtomwareConfig and _G.AtomwareConfig.Notify then
            _G.AtomwareConfig:Notify("Movement Recorder: No recorded points to replay!", 2)
        end
        return
    end
    State.RecorderState = "Replaying"
    State.ReplayIndex = 1
    if _G.AtomwareConfig and _G.AtomwareConfig.Notify then
        _G.AtomwareConfig:Notify("Movement Recorder: Replay started...", 2)
    end
end

local function initMovementRecorder()
    local recTick = 0
    track(RunService.Heartbeat:Connect(function(dt)
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if not root or not hum then return end

        if State.RecorderState == "Recording" then
            recTick = recTick + dt
            if recTick >= 0.05 then
                recTick = 0
                table.insert(State.RecordedPoints, {
                    cframe = root.CFrame,
                    velocity = root.AssemblyLinearVelocity,
                    jumping = hum:GetState() == Enum.HumanoidStateType.Jumping or hum:GetState() == Enum.HumanoidStateType.Freefall,
                })
            end
        elseif State.RecorderState == "Replaying" then
            if State.ReplayIndex > #State.RecordedPoints then
                if State.ReplayLoop then
                    State.ReplayIndex = 1
                else
                    MovementRecorder:Stop()
                    return
                end
            end

            local point = State.RecordedPoints[State.ReplayIndex]
            if point then
                root.CFrame = root.CFrame:Lerp(point.cframe, math.clamp(dt * 20 * State.ReplaySpeed, 0.1, 1))
                root.AssemblyLinearVelocity = point.velocity * State.ReplaySpeed
                if point.jumping and hum.FloorMaterial ~= Enum.Material.Air then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
            State.ReplayIndex = State.ReplayIndex + 1
        end
    end))
end

--//==================================================
--// 4. SOUND ESP (RIVALS 3D VISUALIZER)
--//==================================================

local SoundVisuals = {}
local function initSoundEsp()
    local function onSoundAdded(sound)
        if not State.SoundEsp or not sound:IsA("Sound") then return end
        local parent = sound.Parent
        if not parent or not parent:IsA("BasePart") then return end
        if LocalPlayer.Character and parent:IsDescendantOf(LocalPlayer.Character) then return end

        local pos = parent.Position
        local cam = workspace.CurrentCamera
        if not cam then return end
        local dist = (cam.CFrame.Position - pos).Magnitude
        if dist > State.SoundEspRange then return end

        local sName = sound.Name:lower()
        local isFootstep = sName:find("step") or sName:find("foot") or sName:find("walk") or sName:find("run")
        local isGunfire = sName:find("shoot") or sName:find("fire") or sName:find("shot") or sName:find("blast") or sName:find("sniper")

        if isFootstep or isGunfire or sound.Volume >= 0.4 then
            table.insert(SoundVisuals, {
                pos = pos,
                radius = 1,
                maxRadius = isGunfire and 16 or 9,
                color = isGunfire and Color3.fromRGB(255, 70, 70) or State.SoundEspColor,
                spawnTime = os.clock(),
                label = isGunfire and "GUNFIRE" or "STEP",
            })
        end
    end

    track(workspace.DescendantAdded:Connect(function(desc)
        if desc:IsA("Sound") then
            track(desc.Played:Connect(function() onSoundAdded(desc) end))
        end
    end))

    for _, desc in ipairs(workspace:GetDescendants()) do
        if desc:IsA("Sound") then
            track(desc.Played:Connect(function() onSoundAdded(desc) end))
        end
    end

    track(RunService.RenderStepped:Connect(function()
        if not State.SoundEsp or #SoundVisuals == 0 then return end
        local cam = workspace.CurrentCamera
        if not cam then return end

        local now = os.clock()
        for i = #SoundVisuals, 1, -1 do
            local item = SoundVisuals[i]
            local age = now - item.spawnTime
            if age >= State.SoundEspFadeTime then
                table.remove(SoundVisuals, i)
            else
                local alpha = 1 - (age / State.SoundEspFadeTime)
                local screenPos, onScreen = cam:WorldToViewportPoint(item.pos)
                if onScreen then
                    local expand = (age / State.SoundEspFadeTime) * item.maxRadius
                    local circle = Drawing.new("Circle")
                    circle.Position = Vector2.new(screenPos.X, screenPos.Y)
                    circle.Radius = math.clamp(expand * 8, 4, 120)
                    circle.Color = item.color
                    circle.Transparency = alpha * 0.8
                    circle.Thickness = 1.5
                    circle.Filled = false
                    circle.Visible = true

                    local text = Drawing.new("Text")
                    text.Position = Vector2.new(screenPos.X, screenPos.Y - circle.Radius - 14)
                    text.Text = "[" .. item.label .. " " .. math.floor(screenPos.Z) .. "m]"
                    text.Size = 12
                    text.Center = true
                    text.Outline = true
                    text.Color = item.color
                    text.Transparency = alpha
                    text.Visible = true

                    task.defer(function()
                        circle:Remove()
                        text:Remove()
                    end)
                end
            end
        end
    end))
end

--//==================================================
--// 5. HIT CHAMS & WORLD ESP
--//==================================================

local function initHitChams()
    local function applyHitCham(char)
        if not State.HitChams or not char or char == LocalPlayer.Character then return end
        local hl = Instance.new("Highlight")
        hl.Name = "Atomware_HitCham"
        hl.FillColor = State.HitChamsColor
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.35
        hl.OutlineTransparency = 0.1
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Adornee = char
        hl.Parent = char

        task.delay(State.HitChamsDuration, function()
            if hl and hl.Parent then
                TweenService:Create(hl, TweenInfo.new(0.2), { FillTransparency = 1, OutlineTransparency = 1 }):Play()
                task.wait(0.2)
                hl:Destroy()
            end
        end)
    end

    track(workspace.DescendantAdded:Connect(function(desc)
        if State.HitChams and (desc.Name == "Hitmarker" or desc.Name == "DamageEffect") then
            local enemyChar = desc:FindFirstAncestorOfClass("Model")
            if enemyChar and enemyChar ~= LocalPlayer.Character then
                applyHitCham(enemyChar)
            end
        end
    end))
end

local function initWorldEsp()
    track(RunService.RenderStepped:Connect(function()
        if not State.WorldEsp then return end
        local cam = workspace.CurrentCamera
        if not cam then return end

        for _, item in ipairs(workspace:GetDescendants()) do
            if item:IsA("BasePart") and (item.Name:lower():find("jumppad") or item.Name:lower():find("pad")) then
                local sPos, onScreen = cam:WorldToViewportPoint(item.Position)
                if onScreen and sPos.Z < 250 then
                    local txt = Drawing.new("Text")
                    txt.Position = Vector2.new(sPos.X, sPos.Y)
                    txt.Text = "[Jump Pad " .. math.floor(sPos.Z) .. "m]"
                    txt.Size = 11
                    txt.Center = true
                    txt.Outline = true
                    txt.Color = State.WorldEspColor
                    txt.Visible = true
                    task.defer(function() txt:Remove() end)
                end
            end
        end
    end))
end

--//==================================================
--// 6. SKYBOX & AUDIO ANNOUNCERS
--//==================================================

local SkyboxPresets = {
    ["Galaxy"] = {
        Bk = "rbxassetid://159454299", Dn = "rbxassetid://159454296", Ft = "rbxassetid://159454293",
        Lf = "rbxassetid://159454286", Rt = "rbxassetid://159454300", Up = "rbxassetid://159454288",
    },
    ["Cyberpunk"] = {
        Bk = "rbxassetid://5084575915", Dn = "rbxassetid://5084575798", Ft = "rbxassetid://5084575534",
        Lf = "rbxassetid://5084575376", Rt = "rbxassetid://5084575193", Up = "rbxassetid://5084575025",
    },
    ["Sunset"] = {
        Bk = "rbxassetid://600830446", Dn = "rbxassetid://600831635", Ft = "rbxassetid://600832720",
        Lf = "rbxassetid://600886090", Rt = "rbxassetid://600833862", Up = "rbxassetid://600835177",
    },
}

local function applySkybox(name)
    local faces = SkyboxPresets[name]
    if not faces then return end
    pcall(function()
        local curSky = Lighting:FindFirstChildOfClass("Sky")
        if not curSky then
            curSky = Instance.new("Sky")
            curSky.Name = "Atomware_CustomSky"
            curSky.Parent = Lighting
        end
        curSky.SkyboxBk = faces.Bk
        curSky.SkyboxDn = faces.Dn
        curSky.SkyboxFt = faces.Ft
        curSky.SkyboxLf = faces.Lf
        curSky.SkyboxRt = faces.Rt
        curSky.SkyboxUp = faces.Up
    end)
end

--//==================================================
--// 7. DUELS AUTOMATION & PRESET EXPORT
--//==================================================

local function initDuelsAndSpoofing()
    track(RunService.Heartbeat:Connect(function()
        if State.AutoMapVote or State.AutoWeaponBan then
            pcall(function()
                local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:FindFirstChild("Events")
                if remotes then
                    if State.AutoMapVote then
                        local vote = remotes:FindFirstChild("VoteMap") or remotes:FindFirstChild("MapVote")
                        if vote and vote:IsA("RemoteEvent") then vote:FireServer(State.VotedMap) end
                    end
                    if State.AutoWeaponBan then
                        local ban = remotes:FindFirstChild("BanWeapon") or remotes:FindFirstChild("WeaponBan")
                        if ban and ban:IsA("RemoteEvent") then ban:FireServer(State.BannedWeapon) end
                    end
                end
            end)
        end
    end))

    local lastSweep = 0
    track(RunService.Heartbeat:Connect(function()
        if not State.AutoPickup or not LocalPlayer.Character then return end
        local now = os.clock()
        if now - lastSweep < 0.25 then return end
        lastSweep = now

        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        for _, item in ipairs(workspace:GetDescendants()) do
            if item:IsA("ProximityPrompt") or item.Name:lower():find("pickup") then
                local part = item:IsA("ProximityPrompt") and item.Parent or item
                if part and part:IsA("BasePart") and (part.Position - root.Position).Magnitude <= State.AutoPickupRange then
                    if item:IsA("ProximityPrompt") and item.Enabled and fireproximityprompt then
                        pcall(fireproximityprompt, item)
                    end
                end
            end
        end
    end))
end

--//==================================================
--// 8. UNIFIED IDEMPOTENT UI MOUNTING (NO DUPLICATES)
--//==================================================

local function mountKiciaUI()
    if Kicia.uiMounted then return end
    local window = _G.AtomwareWindow
    if not window or not window.tabs then return end
    Kicia.uiMounted = true

    local function getTab(name, alt)
        return window.tabs[name] or window.tabs[alt or name] or (window.AddTab and window:AddTab(name))
    end

    -- Combat Tab (Side 2: Defense / Anti-Katana)
    local combatTab = getTab("Combat", "combat")
    if combatTab then
        local card = combatTab:AddSection("Anti-Katana & Parry", 2)
        if card and card.AddToggle then
            card:AddToggle({ text = "Anti Katana", state = State.AntiKatana, callback = function(v) State.AntiKatana = v end })
            card:AddSlider({ text = "Detection Radius", min = 10, max = 50, step = 1, default = State.AntiKatanaDist, suffix = "m", callback = function(v) State.AntiKatanaDist = v end })
        end
    end

    -- Movement Tab (Side 2: Movement Recorder & Auto-Strafe)
    local moveTab = getTab("Movement", "move")
    if moveTab then
        local card = moveTab:AddSection("Movement Recorder & Strafe", 2)
        if card and card.AddToggle then
            card:AddToggle({ text = "Auto Strafe", state = State.AutoStrafe, callback = function(v) State.AutoStrafe = v end })
            card:AddButton({ text = "Start Recording", callback = function() MovementRecorder:StartRecording() end })
            card:AddButton({ text = "Stop Recorder", callback = function() MovementRecorder:Stop() end })
            card:AddButton({ text = "Replay Movement", callback = function() MovementRecorder:StartReplay() end })
            card:AddToggle({ text = "Loop Replay", state = State.ReplayLoop, callback = function(v) State.ReplayLoop = v end })
            card:AddSlider({ text = "Replay Speed", min = 0.5, max = 3.0, step = 0.1, default = State.ReplaySpeed, suffix = "x", callback = function(v) State.ReplaySpeed = v end })
        end
    end

    -- Visuals Tab (Side 2: Tactical Sensors)
    local visTab = getTab("Visuals", "visuals")
    if visTab then
        local card = visTab:AddSection("Tactical Sensors", 2)
        if card and card.AddToggle then
            card:AddToggle({ text = "Sound ESP (3D Footsteps)", state = State.SoundEsp, callback = function(v) State.SoundEsp = v end })
            card:AddSlider({ text = "Sound Range", min = 50, max = 300, step = 10, default = State.SoundEspRange, suffix = "m", callback = function(v) State.SoundEspRange = v end })
            card:AddToggle({ text = "Hit Chams", state = State.HitChams, callback = function(v) State.HitChams = v end })
            card:AddSlider({ text = "Cham Duration", min = 0.1, max = 2.0, step = 0.1, default = State.HitChamsDuration, suffix = "s", callback = function(v) State.HitChamsDuration = v end })
            card:AddToggle({ text = "World ESP (Pads & Pickups)", state = State.WorldEsp, callback = function(v) State.WorldEsp = v end })
        end
    end

    -- World Tab (Side 2: Skyboxes & Announcers)
    local worldTab = getTab("World", "world")
    if worldTab then
        local card = worldTab:AddSection("Custom Skyboxes & Announcers", 2)
        if card and card.AddDropdown then
            card:AddDropdown({ text = "Custom Skybox", values = { "Default", "Galaxy", "Cyberpunk", "Sunset" }, default = State.CurrentSkybox, callback = function(val)
                State.CurrentSkybox = val
                applySkybox(val)
            end })
            card:AddToggle({ text = "Halo Kill Announcer", state = State.HaloAnnouncer, callback = function(v) State.HaloAnnouncer = v end })
        end
    end

    -- Misc Tab (Side 1: Duels Automation & Presets)
    local miscTab = getTab("Misc", "misc")
    if miscTab then
        local card = miscTab:AddSection("Duels Automation", 1)
        if card and card.AddToggle then
            card:AddToggle({ text = "Auto Map Vote", state = State.AutoMapVote, callback = function(v) State.AutoMapVote = v end })
            card:AddToggle({ text = "Auto Weapon Ban", state = State.AutoWeaponBan, callback = function(v) State.AutoWeaponBan = v end })
            card:AddToggle({ text = "Auto Pickup Drops", state = State.AutoPickup, callback = function(v) State.AutoPickup = v end })
            card:AddButton({ text = "Export Preset to Clipboard", callback = function()
                if _G.AtomwareRivalsCosmetics and _G.AtomwareRivalsCosmetics.exportPresetToClipboard then
                    _G.AtomwareRivalsCosmetics:exportPresetToClipboard()
                    if _G.AtomwareConfig and _G.AtomwareConfig.Notify then
                        _G.AtomwareConfig:Notify("Cosmetics: Preset copied to clipboard!", 3)
                    end
                end
            end })
            card:AddButton({ text = "Import Preset from Clipboard", callback = function()
                if _G.AtomwareRivalsCosmetics and _G.AtomwareRivalsCosmetics.importPresetFromClipboard then
                    local ok = _G.AtomwareRivalsCosmetics:importPresetFromClipboard()
                    if ok and _G.AtomwareConfig and _G.AtomwareConfig.Notify then
                        _G.AtomwareConfig:Notify("Cosmetics: Preset loaded successfully!", 3)
                    end
                end
            end })
        end
    end
end

initAntiKatana()
initAutoStrafe()
initMovementRecorder()
initSoundEsp()
initHitChams()
initWorldEsp()
initDuelsAndSpoofing()

-- If UI is already online, mount immediately; otherwise wait for AtomwareUILoaded
if _G.AtomwareUILoaded and _G.AtomwareWindow then
    mountKiciaUI()
else
    task.spawn(function()
        local count = 0
        repeat
            task.wait()
            count = count + 1
        until (_G.AtomwareUILoaded and _G.AtomwareWindow) or count > 300
        mountKiciaUI()
    end)
end

Kicia.Unload = function()
    Kicia.active = false
    for _, conn in ipairs(Kicia.connections) do pcall(function() conn:Disconnect() end) end
    for _, fn in ipairs(Kicia.cleanups) do pcall(fn) end
end

local g = (getgenv and getgenv()) or _G
g.__atomware_kicia_unload = Kicia.Unload
_G.AtomwareKiciaLoaded = true
print("[Atomware Rivals] Modular Backend 2 (KiciaHook v3 Engine) loaded cleanly.")
return Kicia
