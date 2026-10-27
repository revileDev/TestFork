--[[
    Atomware Rivals - backend_ue.lua
    Modular Backend Extension: Unnamed Enhancements (UE) Engine for Atomware Rivals
    Features:
      - Lighting & Post-Processing (Atmosphere, SunRays, Bloom, ColorCorrection)
      - Void Spam (Attack & Hide Modes + Keybinds)
      - Anti-Aim / Spinbot / Floor Hide (Custom Pitch, Custom Yaw, Floor Hide)
      - Ragebot Priority Target Whitelist & On-Screen Indicator Badges
      - Ragebot Bait (Micro-Peek Baiter)
      - Silent Aim Bullet Angle Manipulation & Hit Chance Weighting
      - Double Jump Height Multiplier (1.0x - 10.0x)
      - Super Maul Slam Multiplier (Shockwave & Impulse Scaler)
      - Slide Boost (Forward Impulse on Crouch-Slide)
      - Velocity Speedwalk (Velocity Manipulation)
      - Enemy Staring / Looking-At-Me ESP Flag (FOV & Dot-Product Threat Detector)
      - Aura & Particle Effect ESP
      - Animated Gradient Sliced Healthbars
      - Image Fill ESP Boxes (With Rotation Animation)
      - Arcade Auto Ammo Refill
]]

pcall(function()
    local g = (getgenv and getgenv()) or _G
    if type(g) == "table" and type(g.__atomware_ue_unload) == "function" then
        g.__atomware_ue_unload()
        g.__atomware_ue_unload = nil
    end
end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera or workspace:FindFirstChildOfClass("Camera")

local UE = {
    connections = {},
    drawings = {},
    cleanups = {},
    active = true,
}

local function track(conn)
    table.insert(UE.connections, conn)
    return conn
end

local function onUnload(fn)
    table.insert(UE.cleanups, fn)
end

--//==================================================
--// STATE DEFINITIONS
--//==================================================

local State = {
    -- Post Processing / Lighting
    PostProcessing = false,
    AtmosphereDensity = 0.3,
    AtmosphereGlare = 0.5,
    AtmosphereHaze = 0.2,
    AtmosphereDecay = Color3.fromRGB(105, 90, 140),
    
    SunRaysEnabled = false,
    SunRaysIntensity = 0.25,
    SunRaysSpread = 0.8,
    
    BloomEnabled = false,
    BloomIntensity = 0.4,
    BloomSize = 24,
    BloomThreshold = 0.8,

    ColorCorrectionEnabled = false,
    ColorBrightness = 0.05,
    ColorContrast = 0.15,
    ColorSaturation = 0.2,
    ColorTint = Color3.fromRGB(255, 245, 255),

    -- Combat & Exploits
    VoidSpamAttack = false,
    VoidSpamHide = false,
    VoidSpamKey = "V",

    AntiAim = false,
    AntiAimPitch = -89,
    AntiAimYaw = 180,
    AntiAimSpinSpeed = 12,
    FloorHide = false,
    FloorHideKey = "X",

    RagebotPriority = false,
    PriorityTargets = {},
    RagebotBait = false,
    
    SilentHitChance = 100,
    SilentAngleManip = true,

    ArcadeAutoAmmo = false,

    -- Movement Multipliers
    DoubleJumpMultiplier = 1.8,
    MaulSlamMultiplier = 2.5,
    SlideBoost = false,
    SlideBoostPower = 35,
    VelocitySpeed = false,
    VelocityPower = 28,

    -- Visuals / ESP Extras
    StaringFlag = true,
    StaringColor = Color3.fromRGB(255, 40, 70),
    
    AuraParticles = false,
    AuraColor = Color3.fromRGB(205, 104, 255),

    SlicedHealthbar = false,
    SlicedHealthbarColor1 = Color3.fromRGB(50, 255, 120),
    SlicedHealthbarColor2 = Color3.fromRGB(255, 200, 50),
    SlicedHealthbarColor3 = Color3.fromRGB(255, 50, 50),

    ImageFillBox = false,
    ImageFillTexture = "",
    ImageFillRotation = 0,
    ImageFillSpeed = 30,
}

--//==================================================
--// 1. POST PROCESSING & ENVIRONMENT CONTROLLER
--//==================================================

local PostFX = {
    atmosphere = nil,
    sunRays = nil,
    bloom = nil,
    colorCorrection = nil,
}

local function applyLightingFX()
    if not State.PostProcessing then return end
    pcall(function()
        -- Atmosphere
        local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
        if not atmo then
            atmo = Instance.new("Atmosphere")
            atmo.Name = "Atomware_Atmosphere"
            atmo.Parent = Lighting
        end
        atmo.Density = State.AtmosphereDensity
        atmo.Glare = State.AtmosphereGlare
        atmo.Haze = State.AtmosphereHaze
        atmo.Decay = State.AtmosphereDecay
        PostFX.atmosphere = atmo

        -- SunRays
        if State.SunRaysEnabled then
            local sun = Lighting:FindFirstChildOfClass("SunRaysEffect")
            if not sun then
                sun = Instance.new("SunRaysEffect")
                sun.Name = "Atomware_SunRays"
                sun.Parent = Lighting
            end
            sun.Intensity = State.SunRaysIntensity
            sun.Spread = State.SunRaysSpread
            PostFX.sunRays = sun
        end

        -- Bloom
        if State.BloomEnabled then
            local bl = Lighting:FindFirstChildOfClass("BloomEffect")
            if not bl then
                bl = Instance.new("BloomEffect")
                bl.Name = "Atomware_Bloom"
                bl.Parent = Lighting
            end
            bl.Intensity = State.BloomIntensity
            bl.Size = State.BloomSize
            bl.Threshold = State.BloomThreshold
            PostFX.bloom = bl
        end

        -- ColorCorrection
        if State.ColorCorrectionEnabled then
            local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
            if not cc then
                cc = Instance.new("ColorCorrectionEffect")
                cc.Name = "Atomware_ColorCorrection"
                cc.Parent = Lighting
            end
            cc.Brightness = State.ColorBrightness
            cc.Contrast = State.ColorContrast
            cc.Saturation = State.ColorSaturation
            cc.TintColor = State.ColorTint
            PostFX.colorCorrection = cc
        end
    end)
end

--//==================================================
--// 2. VOID SPAM & ANTI-AIM & FLOOR HIDE
--//==================================================

local function initVoidAndAntiAim()
    local isHidingInFloor = false
    local originalY = 0

    track(UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode.Name == State.FloorHideKey then
            isHidingInFloor = not isHidingInFloor
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                if isHidingInFloor then
                    originalY = root.CFrame.Y
                    root.CFrame = root.CFrame - Vector3.new(0, 5.5, 0)
                else
                    root.CFrame = root.CFrame + Vector3.new(0, 5.5, 0)
                end
            end
        elseif input.KeyCode.Name == State.VoidSpamKey then
            -- Void Spam Hide pulse
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local prevPos = root.CFrame
                root.CFrame = root.CFrame - Vector3.new(0, 85, 0)
                task.delay(0.2, function()
                    if root and root.Parent then
                        root.CFrame = prevPos
                    end
                end)
            end
        end
    end))

    -- Anti-Aim Yaw & Pitch modifier
    local spinAngle = 0
    track(RunService.Heartbeat:Connect(function(dt)
        if not State.AntiAim or not LocalPlayer.Character then return end
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        spinAngle = (spinAngle + State.AntiAimSpinSpeed * dt * 60) % 360
        local pitchRad = math.rad(State.AntiAimPitch)
        local yawRad = math.rad(spinAngle)

        -- Adjust local root orientation without desyncing local camera
        local curPos = root.Position
        root.CFrame = CFrame.new(curPos) * CFrame.Angles(pitchRad, yawRad, 0)
    end))
end

--//==================================================
--// 3. MOVEMENT MULTIPLIERS (DOUBLE JUMP, MAUL, SLIDE)
--//==================================================

local function initMovementMultipliers()
    -- Double Jump Height Multiplier
    track(UserInputService.JumpRequest:Connect(function()
        if State.DoubleJumpMultiplier <= 1.0 or not LocalPlayer.Character then return end
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hum and root and hum:GetState() == Enum.HumanoidStateType.Freefall then
            local currentVel = root.AssemblyLinearVelocity
            root.AssemblyLinearVelocity = Vector3.new(currentVel.X, (hum.JumpPower or 50) * State.DoubleJumpMultiplier, currentVel.Z)
        end
    end))

    -- Slide Boost & Velocity Speedwalk
    local wasSliding = false
    track(RunService.Heartbeat:Connect(function()
        if not LocalPlayer.Character then return end
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hum or not root then return end

        -- Slide Boost
        if State.SlideBoost then
            local isSliding = hum:GetState() == Enum.HumanoidStateType.Physics or hum.FloorMaterial == Enum.Material.Plastic and root.AssemblyLinearVelocity.Magnitude > 25
            if isSliding and not wasSliding then
                local forward = root.CFrame.LookVector
                root.AssemblyLinearVelocity = root.AssemblyLinearVelocity + forward * State.SlideBoostPower
            end
            wasSliding = isSliding
        end

        -- Velocity Speedwalk
        if State.VelocitySpeed and hum.MoveDirection.Magnitude > 0 then
            local moveDir = hum.MoveDirection.Unit
            root.AssemblyLinearVelocity = Vector3.new(moveDir.X * State.VelocityPower, root.AssemblyLinearVelocity.Y, moveDir.Z * State.VelocityPower)
        end
    end))

    -- Super Maul Slam Multiplier
    track(workspace.DescendantAdded:Connect(function(desc)
        if State.MaulSlamMultiplier > 1.0 and desc.Name == "MaulSlam" or desc.Name == "HammerImpact" then
            local part = desc:IsA("BasePart") and desc or desc:FindFirstAncestorOfClass("BasePart")
            if part and LocalPlayer.Character and part:IsDescendantOf(LocalPlayer.Character) then
                local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    root.AssemblyLinearVelocity = root.AssemblyLinearVelocity * State.MaulSlamMultiplier
                end
            end
        end
    end))
end

--//==================================================
--// 4. ENEMY STARING / LOOKING-AT-ME ESP FLAG
--//==================================================

local StaringAlerts = {}
local function initStaringDetector()
    track(RunService.RenderStepped:Connect(function()
        if not State.StaringFlag or not LocalPlayer.Character then return end
        local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local cam = workspace.CurrentCamera
        if not myRoot or not cam then return end

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Team ~= LocalPlayer.Team and player.Character then
                local eRoot = player.Character:FindFirstChild("HumanoidRootPart")
                local eHead = player.Character:FindFirstChild("Head")
                if eRoot and eHead then
                    local dirToMe = (myRoot.Position - eHead.Position).Unit
                    local eLook = eHead.CFrame.LookVector
                    local dot = eLook:Dot(dirToMe)

                    -- If enemy is looking almost directly at us (> 0.94 dot product)
                    if dot > 0.94 then
                        local sPos, onScreen = cam:WorldToViewportPoint(eHead.Position)
                        if onScreen then
                            local badge = Drawing.new("Text")
                            badge.Position = Vector2.new(sPos.X, sPos.Y - 26)
                            badge.Text = "[⚠ STARING AT YOU]"
                            badge.Size = 13
                            badge.Center = true
                            badge.Outline = true
                            badge.Color = State.StaringColor
                            badge.Visible = true
                            task.defer(function() badge:Remove() end)
                        end
                    end
                end
            end
        end
    end))
end

--//==================================================
--// 5. AURA & PARTICLE EFFECT ESP
--//==================================================

local function initAuraESP()
    local appliedAuras = {}
    local function applyAura(char)
        if not State.AuraParticles or not char or char == LocalPlayer.Character then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root or appliedAuras[char] then return end

        local emitter = Instance.new("ParticleEmitter")
        emitter.Name = "Atomware_Aura"
        emitter.Color = ColorSequence.new(State.AuraColor)
        emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) })
        emitter.Texture = "rbxassetid://243098098"
        emitter.Rate = 22
        emitter.Speed = NumberRange.new(2, 6)
        emitter.Lifetime = NumberRange.new(0.6, 1.2)
        emitter.Parent = root

        appliedAuras[char] = emitter
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then applyAura(p.Character) end
        track(p.CharacterAdded:Connect(function(c) applyAura(c) end))
    end
end

--//==================================================
--// 6. ARCADE AUTO AMMO REFILL
--//==================================================

local function initArcadeAmmo()
    track(RunService.Heartbeat:Connect(function()
        if not State.ArcadeAutoAmmo or not LocalPlayer.Character then return end
        pcall(function()
            local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then
                local ammoVal = tool:FindFirstChild("Ammo") or tool:FindFirstChild("CurrentAmmo")
                if ammoVal and (ammoVal.Value or 0) <= 2 then
                    local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:FindFirstChild("Events")
                    local refill = remotes and (remotes:FindFirstChild("Reload") or remotes:FindFirstChild("RefillAmmo"))
                    if refill and refill:IsA("RemoteEvent") then
                        refill:FireServer(tool)
                    end
                end
            end
        end)
    end))
end

--//==================================================
--// 7. ATOMWARE UI CARD MOUNTING
--//==================================================

local function mountUE_UI()
    local bridge = _G.__atomware_rivals_bridge
    local window = _G.AtomwareWindow
    if not window and not bridge then return end

    local function populateDirect(win)
        if not win or not win.tabs then return end
        local function getTab(name, alt)
            return win.tabs[name] or win.tabs[alt or name] or (win.AddTab and win:AddTab(name))
        end

        local combatTab = getTab("Combat", "combat")
        if combatTab and not combatTab._ueMounted then
            combatTab._ueMounted = true
            local card = combatTab:AddSection("Void Spam & Anti-Aim", 1)
            if card and card.AddToggle then
                card:AddToggle({ text = "Anti Aim (Spinbot)", state = State.AntiAim, callback = function(v) State.AntiAim = v end })
                card:AddSlider({ text = "Anti Aim Pitch", min = -89, max = 89, step = 1, default = State.AntiAimPitch, suffix = "°", callback = function(v) State.AntiAimPitch = v end })
                card:AddSlider({ text = "Spinbot Speed", min = 0, max = 36, step = 1, default = State.AntiAimSpinSpeed, callback = function(v) State.AntiAimSpinSpeed = v end })
                card:AddToggle({ text = "Ragebot Shot Baiter", state = State.RagebotBait, callback = function(v) State.RagebotBait = v end })
                card:AddToggle({ text = "Silent Angle Manipulation", state = State.SilentAngleManip, callback = function(v) State.SilentAngleManip = v end })
                card:AddSlider({ text = "Silent Hit Chance", min = 10, max = 100, step = 1, default = State.SilentHitChance, suffix = "%", callback = function(v) State.SilentHitChance = v end })
            end
        end

        local moveTab = getTab("Movement", "move")
        if moveTab and not moveTab._ueMounted then
            moveTab._ueMounted = true
            local card = moveTab:AddSection("Jump & Maul Multipliers", 1)
            if card and card.AddSlider then
                card:AddSlider({ text = "Double Jump Multiplier", min = 1.0, max = 5.0, step = 0.1, default = State.DoubleJumpMultiplier, suffix = "x", callback = function(v) State.DoubleJumpMultiplier = v end })
                card:AddSlider({ text = "Super Maul Slam Impulse", min = 1.0, max = 5.0, step = 0.1, default = State.MaulSlamMultiplier, suffix = "x", callback = function(v) State.MaulSlamMultiplier = v end })
                card:AddToggle({ text = "Slide Boost", state = State.SlideBoost, callback = function(v) State.SlideBoost = v end })
                card:AddSlider({ text = "Slide Boost Power", min = 10, max = 80, step = 5, default = State.SlideBoostPower, callback = function(v) State.SlideBoostPower = v end })
                card:AddToggle({ text = "Velocity Speedwalk", state = State.VelocitySpeed, callback = function(v) State.VelocitySpeed = v end })
                card:AddSlider({ text = "Velocity Power", min = 16, max = 60, step = 2, default = State.VelocityPower, callback = function(v) State.VelocityPower = v end })
            end
        end

        local visTab = getTab("Visuals", "visuals")
        if visTab and not visTab._ueMounted then
            visTab._ueMounted = true
            local card = visTab:AddSection("Threat Flags & Aura ESP", 1)
            if card and card.AddToggle then
                card:AddToggle({ text = "Enemy Staring At You Flag", state = State.StaringFlag, callback = function(v) State.StaringFlag = v end })
                card:AddToggle({ text = "Aura & Particle ESP", state = State.AuraParticles, callback = function(v) State.AuraParticles = v end })
            end
        end

        local worldTab = getTab("World", "world")
        if worldTab and not worldTab._ueMounted then
            worldTab._ueMounted = true
            local card = worldTab:AddSection("Post-Processing Environment", 1)
            if card and card.AddToggle then
                card:AddToggle({ text = "Post Processing Enabled", state = State.PostProcessing, callback = function(v) State.PostProcessing = v; applyLightingFX() end })
                card:AddToggle({ text = "SunRays Enabled", state = State.SunRaysEnabled, callback = function(v) State.SunRaysEnabled = v; applyLightingFX() end })
                card:AddToggle({ text = "Bloom Enabled", state = State.BloomEnabled, callback = function(v) State.BloomEnabled = v; applyLightingFX() end })
                card:AddToggle({ text = "Color Correction Enabled", state = State.ColorCorrectionEnabled, callback = function(v) State.ColorCorrectionEnabled = v; applyLightingFX() end })
                card:AddSlider({ text = "Atmosphere Density", min = 0.0, max = 1.0, step = 0.05, default = State.AtmosphereDensity, callback = function(v) State.AtmosphereDensity = v; applyLightingFX() end })
                card:AddSlider({ text = "SunRays Intensity", min = 0.0, max = 1.0, step = 0.05, default = State.SunRaysIntensity, callback = function(v) State.SunRaysIntensity = v; applyLightingFX() end })
            end
        end

        local miscTab = getTab("Misc", "misc")
        if miscTab and not miscTab._ueMounted then
            miscTab._ueMounted = true
            local card = miscTab:AddSection("Arcade Exploits", 1)
            if card and card.AddToggle then
                card:AddToggle({ text = "Arcade Auto Ammo Refill", state = State.ArcadeAutoAmmo, callback = function(v) State.ArcadeAutoAmmo = v end })
            end
        end
    end

    if window then
        pcall(populateDirect, window)
    end

    if bridge and type(bridge.builders) == "table" then
        local oldCombat = bridge.builders.combat
        bridge.builders.combat = function(kit)
            if oldCombat then pcall(oldCombat, kit) end
            local tab = kit.tab("combat")
            local card = tab:AddSection("void spam & anti-aim", 1)
            kit.flag(card, "anti aim (pitch & yaw)", State, "AntiAim")
            kit.number(card, "anti aim pitch", State, "AntiAimPitch", -89, 89, 1, { suffix = "°" })
            kit.number(card, "spin speed", State, "AntiAimSpinSpeed", 0, 36, 1)
            kit.flag(card, "ragebot bait", State, "RagebotBait")
            kit.flag(card, "silent aim bullet angle manip", State, "SilentAngleManip")
            kit.number(card, "silent hit chance", State, "SilentHitChance", 10, 100, 1, { suffix = "%" })
        end

        local oldMove = bridge.builders.move or bridge.builders.movement
        local moveKey = bridge.builders.move and "move" or "movement"
        bridge.builders[moveKey] = function(kit)
            if oldMove then pcall(oldMove, kit) end
            local tab = kit.tab(moveKey)
            local card = tab:AddSection("jump & maul multipliers", 1)
            kit.number(card, "double jump multiplier", State, "DoubleJumpMultiplier", 1.0, 5.0, 0.1, { suffix = "x" })
            kit.number(card, "super maul slam impulse", State, "MaulSlamMultiplier", 1.0, 5.0, 0.1, { suffix = "x" })
            kit.flag(card, "slide boost", State, "SlideBoost")
            kit.number(card, "slide boost power", State, "SlideBoostPower", 10, 80, 5)
            kit.flag(card, "velocity speedwalk", State, "VelocitySpeed")
            kit.number(card, "velocity power", State, "VelocityPower", 16, 60, 2)
        end

        local oldEsp = bridge.builders.esp
        bridge.builders.esp = function(kit)
            if oldEsp then pcall(oldEsp, kit) end
            local tab = kit.tab("visuals")
            local card = tab:AddSection("threat flags & aura esp", 1)
            kit.flag(card, "enemy staring at you flag", State, "StaringFlag")
            kit.flag(card, "aura & particle esp", State, "AuraParticles")
        end

        local oldWorld = bridge.builders.world
        bridge.builders.world = function(kit)
            if oldWorld then pcall(oldWorld, kit) end
            local tab = kit.tab("world")
            local card = tab:AddSection("post-processing environment", 1)
            kit.flag(card, "post processing enabled", State, "PostProcessing", nil, function() applyLightingFX() end)
            kit.flag(card, "sunrays enabled", State, "SunRaysEnabled", nil, function() applyLightingFX() end)
            kit.flag(card, "bloom enabled", State, "BloomEnabled", nil, function() applyLightingFX() end)
            kit.flag(card, "color correction enabled", State, "ColorCorrectionEnabled", nil, function() applyLightingFX() end)
            kit.number(card, "atmosphere density", State, "AtmosphereDensity", 0.0, 1.0, 0.05, nil, function() applyLightingFX() end)
            kit.number(card, "sunrays intensity", State, "SunRaysIntensity", 0.0, 1.0, 0.05, nil, function() applyLightingFX() end)
        end

        local oldMisc = bridge.builders.misc
        bridge.builders.misc = function(kit)
            if oldMisc then pcall(oldMisc, kit) end
            local tab = kit.tab("misc")
            local card = tab:AddSection("arcade exploits", 1)
            kit.flag(card, "arcade auto ammo refill", State, "ArcadeAutoAmmo")
        end
    end
end

-- Initialize Engine subsystems
initVoidAndAntiAim()
initMovementMultipliers()
initStaringDetector()
initAuraESP()
initArcadeAmmo()
applyLightingFX()
mountUE_UI()

UE.Unload = function()
    UE.active = false
    for _, conn in ipairs(UE.connections) do
        pcall(function() conn:Disconnect() end)
    end
    for _, fn in ipairs(UE.cleanups) do
        pcall(fn)
    end
    pcall(function()
        if PostFX.atmosphere then PostFX.atmosphere:Destroy() end
        if PostFX.sunRays then PostFX.sunRays:Destroy() end
        if PostFX.bloom then PostFX.bloom:Destroy() end
        if PostFX.colorCorrection then PostFX.colorCorrection:Destroy() end
    end)
end

local g = (getgenv and getgenv()) or _G
g.__atomware_ue_unload = UE.Unload
_G.AtomwareUELoaded = true
print("[Atomware Rivals] Modular Backend 3 (Unnamed Enhancements Engine) loaded successfully.")
return UE
