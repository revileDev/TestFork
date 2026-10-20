--[[
    AtomWare Persistent Watermark & Real-Time FPS Monitor
    Anchored to bottom-right of viewport, cross-platform (PC & Mobile)
    Live dynamic FPS counter with subtle modern glow
]]

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Watermark = {}
local watermarkGui = nil

local function getGuiParent()
    local success, target = pcall(function()
        return CoreGui
    end)
    if success and target then
        return target
    end
    return PlayerGui
end

local function makeDraggable(frame)
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

function Watermark:Init()
    local parent = getGuiParent()
    local old = parent:FindFirstChild("Atomware_Watermark")
    if old then
        old:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "Atomware_Watermark"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 900
    screenGui.Parent = parent
    watermarkGui = screenGui

    local pill = Instance.new("Frame")
    pill.Name = "WatermarkPill"
    pill.AnchorPoint = Vector2.new(1, 1)
    pill.Position = UDim2.new(1, -16, 1, -16)
    pill.Size = UDim2.new(0, 230, 0, 32)
    pill.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
    pill.BorderSizePixel = 0
    pill.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = pill

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(50, 55, 80)
    stroke.Thickness = 1
    stroke.Parent = pill

    -- Status dot
    local statusDot = Instance.new("Frame")
    statusDot.Name = "StatusDot"
    statusDot.Size = UDim2.new(0, 8, 0, 8)
    statusDot.Position = UDim2.new(0, 10, 0.5, -4)
    statusDot.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
    statusDot.BorderSizePixel = 0
    statusDot.Parent = pill

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(0, 4)
    dotCorner.Parent = statusDot

    -- Main Text
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Text"
    textLabel.Size = UDim2.new(1, -26, 1, 0)
    textLabel.Position = UDim2.new(0, 24, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "ATOMWARE | HUB | FPS: --"
    textLabel.TextColor3 = Color3.fromRGB(230, 230, 240)
    textLabel.Font = Enum.Font.GothamSemibold
    textLabel.TextSize = 12
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = pill

    makeDraggable(pill)

    -- Real-time FPS Calculation (rolling average over frames)
    local lastTime = tick()
    local frameCount = 0
    local fps = 60

    RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        local currentTime = tick()
        local delta = currentTime - lastTime

        if delta >= 0.5 then
            fps = math.floor(frameCount / delta)
            frameCount = 0
            lastTime = currentTime

            textLabel.Text = string.format("ATOMWARE | HUB | FPS: %d", fps)

            if fps >= 50 then
                statusDot.BackgroundColor3 = Color3.fromRGB(67, 181, 129) -- Emerald Green
            elseif fps >= 30 then
                statusDot.BackgroundColor3 = Color3.fromRGB(250, 166, 26) -- Amber Yellow
            else
                statusDot.BackgroundColor3 = Color3.fromRGB(240, 71, 71)  -- Coral Red
            end
        end
    end)

    return Watermark
end

return Watermark
