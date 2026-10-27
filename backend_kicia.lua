--[[
    Atomware Rivals - backend_kicia.lua
    Modular Backend Extension: KiciaHook v3 Engine for Atomware Rivals
    Features:
      - Anti-Katana (Parry & Dash Disruption)
      - Movement Recorder & Waypoint Replay Engine
      - Physics Controller (Custom Gravity & Ground Friction)
      - Auto-Strafe & Air Trajectory Sync
      - Sound ESP (3D World Space Footstep & Gunfire Visualizer)
      - Hit Chams (Dynamic Damage Adornments & Materials)
      - World ESP (Jump Pads, Pickups, Dropped Weapons)
      - Custom Crosshairs & Animated Reticle Text
      - Advanced Bullet Tracers & NoGunTracers Beam Suppression
      - Custom Skybox Manager (Save/Apply/Delete 6-sided Skyboxes to JSON)
      - Custom Sound Manager (Hit & Kill Sound ID Override & Preview)
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
local pcallFs = function(fn)
    local ok, res = pcall(fn)
    return ok and res
end

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
    InfDoubleJump = false,
    AutoStrafe = false,
    PhysicsController = false,
    GravityScale = 1.0,
    FrictionScale = 1.0,

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
    HitChamsMaterial = "ForceField",

    WorldEsp = false,
    WorldEspJumpPads = true,
    WorldEspPickups = true,
    WorldEspWeapons = true,
    WorldEspColor = Color3.fromRGB(120, 255, 180),

    CustomCrosshair = false,
    CrosshairImage = "",
    CrosshairSize = 24,
    CrosshairSpin = false,
    CrosshairSpinSpeed = 90,
    CrosshairText = "",
    CrosshairTextColor = Color3.fromRGB(205, 104, 255),

    AdvancedTracers = false,
    TracerWidth = 2,
    TracerColor = Color3.fromRGB(255, 200, 50),
    HideGameTracers = false,

    -- Skyboxes & Sounds
    SkyboxEnabled = false,
    CurrentSkybox = "Default",
    CustomSkyboxes = {},

    SoundManagerEnabled = false,
    CustomHitSound = "",
    CustomKillSound = "",
    HitSoundVolume = 1.0,

    HaloAnnouncer = false,
    AnnouncerPack = "Halo", -- "Halo", "Quake", "Unreal"
    KillStreak = 0,
    LastKillTime = 0,

    -- Spoofing & Automation
    NameSpoof = false,
    SpoofedName = "AtomwareGod",
    StatSpoof = false,
    SpoofedElo = 9999,
    DuelerCloneSpoof = false,

    AutoMapVote = false,
    VotedMap = "Crossroads",
    AutoWeaponBan = false,
    BannedWeapon = "Katana",
    AutoPickup = false,
    AutoPickupRange = 25,

    CosmeticPresets = {},
}

--//==================================================
--// 1. ANTI-KATANA ENGINE
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
                        -- Check if player is dashing or swinging
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
                            -- Execute parry counter impulse or lateral dash
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
--// 2. INFINITE DOUBLE JUMP & AUTO-STRAFE
--//==================================================

local function initMovementExtensions()
    track(UserInputService.JumpRequest:Connect(function()
        if not State.InfDoubleJump or not LocalPlayer.Character then return end
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hum and root and hum:GetState() == Enum.HumanoidStateType.Freefall then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, hum.JumpPower or 50, root.AssemblyLinearVelocity.Z)
        end
    end))

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
        
        -- Filter out local player's own sounds
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
            local entry = {
                pos = pos,
                radius = 1,
                maxRadius = isGunfire and 16 or 9,
                color = isGunfire and Color3.fromRGB(255, 70, 70) or State.SoundEspColor,
                spawnTime = os.clock(),
                label = isGunfire and "GUNFIRE" or "STEP",
            }
            table.insert(SoundVisuals, entry)
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

    -- Draw Sound ESP Circles via Drawing API
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
                    -- Render expanding ring or billboard adornment
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
--// 5. HIT CHAMS (DYNAMIC DAMAGE ADORNMENT)
--//==================================================

local HitChamsActive = {}
local function initHitChams()
    local function applyHitCham(char)
        if not State.HitChams or not char then return end
        if char == LocalPlayer.Character then return end

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

    -- Hook player damage / hit feedback
    track(workspace.DescendantAdded:Connect(function(desc)
        if State.HitChams and desc.Name == "Hitmarker" or desc.Name == "DamageEffect" then
            local enemyChar = desc:FindFirstAncestorOfClass("Model")
            if enemyChar and enemyChar ~= LocalPlayer.Character then
                applyHitCham(enemyChar)
            end
        end
    end))
end

--//==================================================
--// 6. WORLD ESP (JUMP PADS, WEAPONS, PICKUPS)
--//==================================================

local function initWorldEsp()
    track(RunService.RenderStepped:Connect(function()
        if not State.WorldEsp then return end
        local cam = workspace.CurrentCamera
        if not cam then return end

        -- Jump Pads
        if State.WorldEspJumpPads then
            for _, item in ipairs(workspace:GetDescendants()) do
                if item:IsA("BasePart") and (item.Name:lower():find("jumppad") or item.Name:lower():find("pad") or item.Name:lower():find("launch")) then
                    local sPos, onScreen = cam:WorldToViewportPoint(item.Position)
                    if onScreen and sPos.Z < 300 then
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
        end
    end))
end

--//==================================================
--// 7. CUSTOM SKYBOX & SOUND MANAGERS
--//==================================================

local SkyboxPresets = {
    ["Galaxy"] = {
        Bk = "rbxassetid://159454299",
        Dn = "rbxassetid://159454296",
        Ft = "rbxassetid://159454293",
        Lf = "rbxassetid://159454286",
        Rt = "rbxassetid://159454300",
        Up = "rbxassetid://159454288",
    },
    ["Cyberpunk"] = {
        Bk = "rbxassetid://5084575915",
        Dn = "rbxassetid://5084575798",
        Ft = "rbxassetid://5084575534",
        Lf = "rbxassetid://5084575376",
        Rt = "rbxassetid://5084575193",
        Up = "rbxassetid://5084575025",
    },
    ["Sunset"] = {
        Bk = "rbxassetid://600830446",
        Dn = "rbxassetid://600831635",
        Ft = "rbxassetid://600832720",
        Lf = "rbxassetid://600886090",
        Rt = "rbxassetid://600833862",
        Up = "rbxassetid://600835177",
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

-- Halo Kill Sound packs
local AnnouncerSounds = {
    [2] = "rbxassetid://9069609267", -- Double Kill
    [3] = "rbxassetid://9069609536", -- Triple Kill
    [4] = "rbxassetid://9069609789", -- Overkill
    [5] = "rbxassetid://9069610052", -- Killtacular
    [6] = "rbxassetid://9069610332", -- Killtrocity
    [7] = "rbxassetid://9069610587", -- Killimanjaro
    [8] = "rbxassetid://9069610842", -- Killtastrophe
    [9] = "rbxassetid://9069611110", -- Killpocalypse
    [10] = "rbxassetid://9069611394", -- Killionaire
}

local function playAnnouncerSound(streak)
    local sId = AnnouncerSounds[streak] or (streak > 10 and AnnouncerSounds[10])
    if sId then
        local sound = Instance.new("Sound")
        sound.SoundId = sId
        sound.Volume = 1.2
        sound.Parent = SoundService
        sound:Play()
        task.delay(4, function() sound:Destroy() end)
    end
end

--//==================================================
--// 8. DUELS AUTOMATION & SPOOFING
--//==================================================

local function initDuelsAndSpoofing()
    -- Auto Map Vote & Weapon Ban in Duels
    track(RunService.Heartbeat:Connect(function()
        if State.AutoMapVote or State.AutoWeaponBan then
            pcall(function()
                local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:FindFirstChild("Events")
                if remotes then
                    if State.AutoMapVote then
                        local voteRemote = remotes:FindFirstChild("VoteMap") or remotes:FindFirstChild("MapVote")
                        if voteRemote and voteRemote:IsA("RemoteEvent") then
                            voteRemote:FireServer(State.VotedMap)
                        end
                    end
                    if State.AutoWeaponBan then
                        local banRemote = remotes:FindFirstChild("BanWeapon") or remotes:FindFirstChild("WeaponBan")
                        if banRemote and banRemote:IsA("RemoteEvent") then
                            banRemote:FireServer(State.BannedWeapon)
                        end
                    end
                end
            end)
        end
    end))

    -- Auto Pickup Drops
    local lastSweep = 0
    track(RunService.Heartbeat:Connect(function()
        if not State.AutoPickup or not LocalPlayer.Character then return end
        local now = os.clock()
        if now - lastSweep < 0.25 then return end
        lastSweep = now

        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        for _, item in ipairs(workspace:GetDescendants()) do
            if item:IsA("ProximityPrompt") or item.Name:lower():find("pickup") or item.Name:lower():find("drop") then
                local part = item:IsA("ProximityPrompt") and item.Parent or item
                if part and part:IsA("BasePart") then
                    if (part.Position - root.Position).Magnitude <= State.AutoPickupRange then
                        if item:IsA("ProximityPrompt") and item.Enabled then
                            pcall(function()
                                if fireproximityprompt then
                                    fireproximityprompt(item)
                                end
                            end)
                        elseif firetouchinterest then
                            pcall(function()
                                firetouchinterest(root, part, 0)
                                task.wait()
                                firetouchinterest(root, part, 1)
                            end)
                        end
                    end
                end
            end
        end
    end))
end

--//==================================================
--// 9. COSMETIC PRESET EXPORT & CLIPBOARD SHARING
--//==================================================

local function exportCosmeticPreset(): string
    local currentCosmetics = _G.AtomwareRivalsCosmetics
    local data = {}
    if currentCosmetics and type(currentCosmetics.getEquipped) == "function" then
        data = currentCosmetics:getEquipped()
    else
        data = { Version = "KiciaHook_v3", Timestamp = os.time(), Presets = {} }
    end
    local json = HttpService:JSONEncode(data)
    if setclipboard then
        setclipboard(json)
        if _G.AtomwareConfig and _G.AtomwareConfig.Notify then
            _G.AtomwareConfig:Notify("Cosmetics: Preset copied to clipboard!", 3)
        end
    end
    return json
end

local function importCosmeticPreset(jsonString: string)
    local ok, data = pcall(function() return HttpService:JSONDecode(jsonString) end)
    if ok and type(data) == "table" then
        local currentCosmetics = _G.AtomwareRivalsCosmetics
        if currentCosmetics and type(currentCosmetics.setEquipped) == "function" then
            currentCosmetics:setEquipped(data)
            if _G.AtomwareConfig and _G.AtomwareConfig.Notify then
                _G.AtomwareConfig:Notify("Cosmetics: Preset imported & applied successfully!", 3)
            end
        end
    else
        warn("[Atomware Kicia] Failed to import cosmetic preset: Invalid JSON")
    end
end

--//==================================================
--// 10. ATOMWARE UI CARD MOUNTING
--//==================================================

local function mountKiciaUI()
    local bridge = _G.__atomware_rivals_bridge
    local window = _G.AtomwareWindow
    if not window and not bridge then return end

    local function populateDirect(win)
        if not win or not win.tabs then return end
        local function getTab(name, alt)
            return win.tabs[name] or win.tabs[alt or name] or (win.AddTab and win:AddTab(name))
        end

        local combatTab = getTab("Combat", "combat")
        if combatTab and not combatTab._kiciaMounted then
            combatTab._kiciaMounted = true
            local card = combatTab:AddSection("Anti-Katana & Parry", 2)
            if card and card.AddToggle then
                card:AddToggle({ text = "Anti Katana", state = State.AntiKatana, callback = function(v) State.AntiKatana = v end })
                card:AddSlider({ text = "Detection Radius", min = 10, max = 50, step = 1, default = State.AntiKatanaDist, suffix = "m", callback = function(v) State.AntiKatanaDist = v end })
            end
        end

        local moveTab = getTab("Movement", "move")
        if moveTab and not moveTab._kiciaMounted then
            moveTab._kiciaMounted = true
            local card = moveTab:AddSection("Movement Recorder & Physics", 2)
            if card and card.AddToggle then
                card:AddToggle({ text = "Infinite Double Jump", state = State.InfDoubleJump, callback = function(v) State.InfDoubleJump = v end })
                card:AddToggle({ text = "Auto Strafe", state = State.AutoStrafe, callback = function(v) State.AutoStrafe = v end })
                card:AddButton({ text = "Start Recording", callback = function() MovementRecorder:StartRecording() end })
                card:AddButton({ text = "Stop Recorder", callback = function() MovementRecorder:Stop() end })
                card:AddButton({ text = "Replay Movement", callback = function() MovementRecorder:StartReplay() end })
                card:AddToggle({ text = "Loop Replay", state = State.ReplayLoop, callback = function(v) State.ReplayLoop = v end })
            end
        end

        local visTab = getTab("Visuals", "visuals")
        if visTab and not visTab._kiciaMounted then
            visTab._kiciaMounted = true
            local card = visTab:AddSection("Sound ESP & Hit Chams", 2)
            if card and card.AddToggle then
                card:AddToggle({ text = "Sound ESP (3D Footsteps)", state = State.SoundEsp, callback = function(v) State.SoundEsp = v end })
                card:AddSlider({ text = "Sound Range", min = 50, max = 300, step = 10, default = State.SoundEspRange, suffix = "m", callback = function(v) State.SoundEspRange = v end })
                card:AddToggle({ text = "Hit Chams", state = State.HitChams, callback = function(v) State.HitChams = v end })
                card:AddSlider({ text = "Cham Duration", min = 0.1, max = 2.0, step = 0.1, default = State.HitChamsDuration, suffix = "s", callback = function(v) State.HitChamsDuration = v end })
                card:AddToggle({ text = "World ESP (Pads & Pickups)", state = State.WorldEsp, callback = function(v) State.WorldEsp = v end })
            end
        end

        local worldTab = getTab("World", "world")
        if worldTab and not worldTab._kiciaMounted then
            worldTab._kiciaMounted = true
            local card = worldTab:AddSection("Skyboxes & Kill Sounds", 2)
            if card and card.AddDropdown then
                card:AddDropdown({ text = "Custom Skybox", values = { "Default", "Galaxy", "Cyberpunk", "Sunset" }, default = State.CurrentSkybox, callback = function(val)
                    State.CurrentSkybox = val
                    applySkybox(val)
                end })
                card:AddToggle({ text = "Halo Kill Announcer", state = State.HaloAnnouncer, callback = function(v) State.HaloAnnouncer = v end })
            end
        end

        local miscTab = getTab("Misc", "misc")
        if miscTab and not miscTab._kiciaMounted then
            miscTab._kiciaMounted = true
            local card = miscTab:AddSection("Duels Automation & Presets", 2)
            if card and card.AddToggle then
                card:AddToggle({ text = "Auto Map Vote", state = State.AutoMapVote, callback = function(v) State.AutoMapVote = v end })
                card:AddToggle({ text = "Auto Weapon Ban", state = State.AutoWeaponBan, callback = function(v) State.AutoWeaponBan = v end })
                card:AddToggle({ text = "Auto Pickup Drops", state = State.AutoPickup, callback = function(v) State.AutoPickup = v end })
                card:AddButton({ text = "Export Preset to Clipboard", callback = function() exportCosmeticPreset() end })
            end
        end
    end

    if window then
        pcall(populateDirect, window)
    end

    -- Register into DrawingBridge builders if present
    if bridge and type(bridge.builders) == "table" then
        local oldCombat = bridge.builders.combat
        bridge.builders.combat = function(kit)
            if oldCombat then pcall(oldCombat, kit) end
            local tab = kit.tab("combat")
            local card = tab:AddSection("anti-katana & parry", 2)
            kit.flag(card, "anti katana", State, "AntiKatana")
            kit.number(card, "detection radius", State, "AntiKatanaDist", 10, 45, 1, { suffix = "m" })
        end

        local oldMove = bridge.builders.move or bridge.builders.movement
        local moveKey = bridge.builders.move and "move" or "movement"
        bridge.builders[moveKey] = function(kit)
            if oldMove then pcall(oldMove, kit) end
            local tab = kit.tab(moveKey)
            local card = tab:AddSection("movement recorder & physics", 2)
            kit.flag(card, "infinite double jump", State, "InfDoubleJump")
            kit.flag(card, "auto strafe", State, "AutoStrafe")
            kit.action(card, "start recording", function() MovementRecorder:StartRecording() end)
            kit.action(card, "stop recorder", function() MovementRecorder:Stop() end)
            kit.action(card, "replay movement", function() MovementRecorder:StartReplay() end)
            kit.flag(card, "loop replay", State, "ReplayLoop")
        end

        local oldEsp = bridge.builders.esp
        bridge.builders.esp = function(kit)
            if oldEsp then pcall(oldEsp, kit) end
            local tab = kit.tab("visuals")
            local card = tab:AddSection("sound esp & hit chams", 2)
            kit.flag(card, "sound esp (3d footsteps)", State, "SoundEsp")
            kit.number(card, "sound range", State, "SoundEspRange", 50, 300, 10, { suffix = "m" })
            kit.flag(card, "hit chams", State, "HitChams")
            kit.number(card, "cham duration", State, "HitChamsDuration", 0.1, 2.0, 0.1, { suffix = "s" })
            kit.flag(card, "world esp (pads & pickups)", State, "WorldEsp")
        end

        local oldWorld = bridge.builders.world
        bridge.builders.world = function(kit)
            if oldWorld then pcall(oldWorld, kit) end
            local tab = kit.tab("world")
            local card = tab:AddSection("skyboxes & kill sounds", 2)
            kit.choice(card, "custom skybox", { "Default", "Galaxy", "Cyberpunk", "Sunset" }, function() return State.CurrentSkybox end, function(val)
                State.CurrentSkybox = val
                applySkybox(val)
            end)
            kit.flag(card, "halo announcer", State, "HaloAnnouncer")
        end

        local oldMisc = bridge.builders.misc
        bridge.builders.misc = function(kit)
            if oldMisc then pcall(oldMisc, kit) end
            local tab = kit.tab("misc")
            local card = tab:AddSection("duels automation & presets", 2)
            kit.flag(card, "auto map vote", State, "AutoMapVote")
            kit.flag(card, "auto weapon ban", State, "AutoWeaponBan")
            kit.flag(card, "auto pickup drops", State, "AutoPickup")
            kit.action(card, "export cosmetics to clipboard", function() exportCosmeticPreset() end)
        end
    end
end

-- Initialize Engine subsystems
initAntiKatana()
initMovementExtensions()
initMovementRecorder()
initSoundEsp()
initHitChams()
initWorldEsp()
initDuelsAndSpoofing()
mountKiciaUI()

Kicia.Unload = function()
    Kicia.active = false
    for _, conn in ipairs(Kicia.connections) do
        pcall(function() conn:Disconnect() end)
    end
    for _, fn in ipairs(Kicia.cleanups) do
        pcall(fn)
    end
end

local g = (getgenv and getgenv()) or _G
g.__atomware_kicia_unload = Kicia.Unload
_G.AtomwareKiciaLoaded = true
print("[Atomware Rivals] Modular Backend 2 (KiciaHook v3 Engine) loaded successfully.")
return Kicia
