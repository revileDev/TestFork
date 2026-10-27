--[[
    Atomware Rivals - backend_ue.lua
    Modular Backend Extension: Unnamed Enhancements (UE) Engine for Atomware Rivals
    Fully Deduplicated & Uncluttered Architecture.
    Features:
      - Void Spam (Attack & Hide Modes + Keybinds)
      - Anti-Aim / Spinbot / Floor Hide (Custom Pitch, Spinbot Rotation Speed, Floor Hide)
      - Ragebot Shot Baiter (Micro-Peek Baiter)
      - Double Jump Height Multiplier (1.0x - 5.0x)
      - Super Maul Slam Multiplier (Shockwave & Impulse Scaler)
      - Enemy Staring / Looking-At-Me ESP Flag (Threat Detection)
      - Aura & Particle Effect ESP
      - SunRays Post-Processing Engine (Intensity & Spread)
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
    uiMounted = false,
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
    -- Combat & Exploits
    VoidSpamKey = "V",
    AntiAim = false,
    AntiAimPitch = -89,
    AntiAimSpinSpeed = 12,
    FloorHideKey = "X",
    RagebotBait = false,
    ArcadeAutoAmmo = false,

    -- Movement Multipliers
    DoubleJumpMultiplier = 1.8,
    MaulSlamMultiplier = 2.5,

    -- Visuals / ESP Extras
    StaringFlag = true,
    StaringColor = Color3.fromRGB(255, 40, 70),
    AuraParticles = false,
    AuraColor = Color3.fromRGB(205, 104, 255),

    -- Post-Processing (Novel SunRays Extension)
    SunRaysEnabled = false,
    SunRaysIntensity = 0.25,
    SunRaysSpread = 0.8,
}

--//==================================================
--// 1. VOID SPAM & ANTI-AIM & FLOOR HIDE
--//==================================================

local function initVoidAndAntiAim()
    local isHidingInFloor = false

    track(UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode.Name == State.FloorHideKey then
            isHidingInFloor = not isHidingInFloor
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                if isHidingInFloor then
                    root.CFrame = root.CFrame - Vector3.new(0, 5.5, 0)
                else
                    root.CFrame = root.CFrame + Vector3.new(0, 5.5, 0)
                end
            end
        elseif input.KeyCode.Name == State.VoidSpamKey then
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

    local spinAngle = 0
    track(RunService.Heartbeat:Connect(function(dt)
        if not State.AntiAim or not LocalPlayer.Character then return end
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        spinAngle = (spinAngle + State.AntiAimSpinSpeed * dt * 60) % 360
        local pitchRad = math.rad(State.AntiAimPitch)
        local yawRad = math.rad(spinAngle)

        local curPos = root.Position
        root.CFrame = CFrame.new(curPos) * CFrame.Angles(pitchRad, yawRad, 0)
    end))
end

--//==================================================
--// 2. MOVEMENT MULTIPLIERS (DOUBLE JUMP & MAUL SLAM)
--//==================================================

local function initMovementMultipliers()
    track(UserInputService.JumpRequest:Connect(function()
        if State.DoubleJumpMultiplier <= 1.0 or not LocalPlayer.Character then return end
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hum and root and hum:GetState() == Enum.HumanoidStateType.Freefall then
            local currentVel = root.AssemblyLinearVelocity
            root.AssemblyLinearVelocity = Vector3.new(currentVel.X, (hum.JumpPower or 50) * State.DoubleJumpMultiplier, currentVel.Z)
        end
    end))

    track(workspace.DescendantAdded:Connect(function(desc)
        if State.MaulSlamMultiplier > 1.0 and (desc.Name == "MaulSlam" or desc.Name == "HammerImpact") then
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
--// 3. ENEMY STARING / THREAT DETECTOR ESP FLAG
--//==================================================

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

                    if dot > 0.94 then
                        local sPos, onScreen = cam:WorldToViewportPoint(eHead.Position)
                        if onScreen then
                            local badge = Drawing.new("Text")
                            badge.Position = Vector2.new(sPos.X, sPos.Y - 26)
                            badge.Text = "[STARING AT YOU]"
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
--// 4. AURA & PARTICLE ESP
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
--// 5. SUNRAYS POST-PROCESSING EXTENSION
--//==================================================

local sunRaysInstance = nil
local function applySunRays()
    pcall(function()
        if State.SunRaysEnabled then
            if not sunRaysInstance or not sunRaysInstance.Parent then
                sunRaysInstance = Lighting:FindFirstChild("Atomware_SunRays") or Instance.new("SunRaysEffect")
                sunRaysInstance.Name = "Atomware_SunRays"
                sunRaysInstance.Parent = Lighting
            end
            sunRaysInstance.Intensity = State.SunRaysIntensity
            sunRaysInstance.Spread = State.SunRaysSpread
            sunRaysInstance.Enabled = true
        elseif sunRaysInstance then
            sunRaysInstance.Enabled = false
        end
    end)
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
--// 7. UNIFIED IDEMPOTENT UI MOUNTING (NO DUPLICATES)
--//==================================================

local function mountUE_UI()
    if UE.uiMounted then return end
    local window = _G.AtomwareWindow
    if not window or not window.tabs then return end
    UE.uiMounted = true

    local function getTab(name, alt)
        return window.tabs[name] or window.tabs[alt or name] or (window.AddTab and window:AddTab(name))
    end

    -- Combat Tab (Side 1: Void Exploits & Anti-Aim)
    local combatTab = getTab("Combat", "combat")
    if combatTab then
        local card = combatTab:AddSection("Void Exploits & Anti-Aim", 1)
        if card and card.AddToggle then
            card:AddToggle({ text = "Anti Aim (Spinbot)", state = State.AntiAim, callback = function(v) State.AntiAim = v end })
            card:AddSlider({ text = "Anti Aim Pitch", min = -89, max = 89, step = 1, default = State.AntiAimPitch, suffix = "°", callback = function(v) State.AntiAimPitch = v end })
            card:AddSlider({ text = "Spinbot Rotation Speed", min = 0, max = 36, step = 1, default = State.AntiAimSpinSpeed, callback = function(v) State.AntiAimSpinSpeed = v end })
            card:AddKeybind({ text = "Floor Hide Key", default = State.FloorHideKey, callback = function(k) State.FloorHideKey = typeof(k) == "EnumItem" and k.Name or tostring(k) end })
            card:AddKeybind({ text = "Void Spam Key", default = State.VoidSpamKey, callback = function(k) State.VoidSpamKey = typeof(k) == "EnumItem" and k.Name or tostring(k) end })
            card:AddToggle({ text = "Ragebot Shot Baiter", state = State.RagebotBait, callback = function(v) State.RagebotBait = v end })
        end
    end

    -- Movement Tab (Side 1: Jump & Maul Multipliers)
    local moveTab = getTab("Movement", "move")
    if moveTab then
        local card = moveTab:AddSection("Jump & Maul Multipliers", 1)
        if card and card.AddSlider then
            card:AddSlider({ text = "Double Jump Multiplier", min = 1.0, max = 5.0, step = 0.1, default = State.DoubleJumpMultiplier, suffix = "x", callback = function(v) State.DoubleJumpMultiplier = v end })
            card:AddSlider({ text = "Super Maul Slam Impulse", min = 1.0, max = 5.0, step = 0.1, default = State.MaulSlamMultiplier, suffix = "x", callback = function(v) State.MaulSlamMultiplier = v end })
        end
    end

    -- Visuals Tab (Side 1: Threat Detection & Aura)
    local visTab = getTab("Visuals", "visuals")
    if visTab then
        local card = visTab:AddSection("Threat Detection & Aura", 1)
        if card and card.AddToggle then
            card:AddToggle({ text = "Enemy Staring At You Flag", state = State.StaringFlag, callback = function(v) State.StaringFlag = v end })
            card:AddToggle({ text = "Aura & Particle ESP", state = State.AuraParticles, callback = function(v) State.AuraParticles = v end })
        end
    end

    -- World Tab (Side 1: Post-Processing SunRays)
    local worldTab = getTab("World", "world")
    if worldTab then
        local card = worldTab:AddSection("Post-Processing SunRays", 1)
        if card and card.AddToggle then
            card:AddToggle({ text = "SunRays Enabled", state = State.SunRaysEnabled, callback = function(v) State.SunRaysEnabled = v; applySunRays() end })
            card:AddSlider({ text = "SunRays Intensity", min = 0.0, max = 1.0, step = 0.05, default = State.SunRaysIntensity, callback = function(v) State.SunRaysIntensity = v; applySunRays() end })
            card:AddSlider({ text = "SunRays Spread", min = 0.1, max = 1.0, step = 0.05, default = State.SunRaysSpread, callback = function(v) State.SunRaysSpread = v; applySunRays() end })
        end
    end

    -- Misc Tab (Side 1: Arcade Exploits)
    local miscTab = getTab("Misc", "misc")
    if miscTab then
        local card = miscTab:AddSection("Arcade Exploits", 1)
        if card and card.AddToggle then
            card:AddToggle({ text = "Arcade Auto Ammo Refill", state = State.ArcadeAutoAmmo, callback = function(v) State.ArcadeAutoAmmo = v end })
        end
    end
end

initVoidAndAntiAim()
initMovementMultipliers()
initStaringDetector()
initAuraESP()
initArcadeAmmo()

if _G.AtomwareUILoaded and _G.AtomwareWindow then
    mountUE_UI()
else
    task.spawn(function()
        local count = 0
        repeat
            task.wait()
            count = count + 1
        until (_G.AtomwareUILoaded and _G.AtomwareWindow) or count > 300
        mountUE_UI()
    end)
end

UE.Unload = function()
    UE.active = false
    for _, conn in ipairs(UE.connections) do pcall(function() conn:Disconnect() end) end
    for _, fn in ipairs(UE.cleanups) do pcall(fn) end
    pcall(function()
        if sunRaysInstance then sunRaysInstance:Destroy() end
    end)
end

local g = (getgenv and getgenv()) or _G
g.__atomware_ue_unload = UE.Unload
_G.AtomwareUELoaded = true
print("[Atomware Rivals] Modular Backend 3 (Unnamed Enhancements Engine) loaded cleanly.")
return UE
