--[[
    AtomWare In-Game Toast Notifications Module
    Cross-platform (PC & Mobile) animated notification banner system
]]

local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Notification = {}
local container = nil

local function getGuiParent()
    local success, target = pcall(function()
        return CoreGui
    end)
    if success and target then
        return target
    end
    return PlayerGui
end

local function ensureContainer()
    if container and container.Parent then
        return container
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "Atomware_Notifications"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 999
    screenGui.Parent = getGuiParent()

    local frame = Instance.new("Frame")
    frame.Name = "ToastContainer"
    frame.BackgroundTransparency = 1
    frame.AnchorPoint = Vector2.new(1, 0)
    frame.Position = UDim2.new(1, -16, 0, 16)
    frame.Size = UDim2.new(0, 320, 1, -32)
    frame.Parent = screenGui

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Parent = frame

    container = frame
    return container
end

function Notification:Show(title, message, duration, notifType)
    duration = duration or 3.5
    notifType = notifType or "Info"

    local c = ensureContainer()

    local accentColors = {
        Info = Color3.fromRGB(56, 189, 248),
        Success = Color3.fromRGB(16, 185, 129),
        Warning = Color3.fromRGB(245, 158, 11),
        Error = Color3.fromRGB(239, 68, 68)
    }
    local accentColor = accentColors[notifType] or accentColors.Info

    local toast = Instance.new("Frame")
    toast.Name = "Toast"
    toast.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
    toast.Size = UDim2.new(1, 0, 0, 60)
    toast.Position = UDim2.new(1, 40, 0, 0)
    toast.ClipsDescendants = true
    toast.BackgroundTransparency = 0.1

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = toast

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(51, 65, 85)
    stroke.Thickness = 1
    stroke.Parent = toast

    -- Left accent indicator bar
    local bar = Instance.new("Frame")
    bar.BackgroundColor3 = accentColor
    bar.Size = UDim2.new(0, 4, 1, 0)
    bar.BorderSizePixel = 0
    bar.Parent = toast

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 4)
    barCorner.Parent = bar

    -- Title Label
    local titleLbl = Instance.new("TextLabel")
    titleLbl.BackgroundTransparency = 1
    titleLbl.Position = UDim2.new(0, 14, 0, 6)
    titleLbl.Size = UDim2.new(1, -24, 0, 18)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.Text = tostring(title or "AtomWare")
    titleLbl.TextColor3 = Color3.fromRGB(248, 250, 252)
    titleLbl.TextSize = 13
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = toast

    -- Message Label
    local msgLbl = Instance.new("TextLabel")
    msgLbl.BackgroundTransparency = 1
    msgLbl.Position = UDim2.new(0, 14, 0, 24)
    msgLbl.Size = UDim2.new(1, -24, 0, 30)
    msgLbl.Font = Enum.Font.Gotham
    msgLbl.Text = tostring(message or "")
    msgLbl.TextColor3 = Color3.fromRGB(148, 163, 184)
    msgLbl.TextSize = 11
    msgLbl.TextWrapped = true
    msgLbl.TextXAlignment = Enum.TextXAlignment.Left
    msgLbl.Parent = toast

    toast.Parent = c

    -- Slide in tween
    toast.Position = UDim2.new(1, 300, 0, 0)
    local tweenIn = TweenService:Create(toast, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0)
    })
    tweenIn:Play()

    -- Slide out and destroy
    task.delay(duration, function()
        if toast and toast.Parent then
            local tweenOut = TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 340, 0, 0),
                BackgroundTransparency = 1
            })
            tweenOut:Play()
            tweenOut.Completed:Connect(function()
                toast:Destroy()
            end)
        end
    end)
end

return Notification
