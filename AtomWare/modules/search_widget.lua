--[[
    AtomWare Floating Draggable Search & Gamehop Widget
    Cross-platform (PC & Mobile) interactive game search engine
    Allows searching 407+ games by Place ID or Title, game-hopping, and executing.
]]

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local SearchWidget = {}
local widgetGui = nil

local function getGuiParent()
    local success, target = pcall(function()
        return CoreGui
    end)
    if success and target then
        return target
    end
    return PlayerGui
end

-- Draggable helper with drag-vs-click detection
local function makeDraggable(frame, dragHandle)
    dragHandle = dragHandle or frame
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil
    local totalMove = 0

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            totalMove = 0

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            totalMove = totalMove + math.abs(delta.X) + math.abs(delta.Y)
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    return function()
        return totalMove > 8
    end
end

function SearchWidget:Init(gamesDb, notificationModule, authPromptModule, telemetryModule)
    local parent = getGuiParent()
    local old = parent:FindFirstChild("Atomware_SearchWidget")
    if old then
        old:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "Atomware_SearchWidget"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 950
    screenGui.Parent = parent
    widgetGui = screenGui

    -- Floating Icon Button (Draggable)
    local floatBtn = Instance.new("TextButton")
    floatBtn.Name = "FloatingSearchButton"
    floatBtn.Size = UDim2.new(0, 52, 0, 52)
    floatBtn.Position = UDim2.new(0, 20, 0.45, 0)
    floatBtn.BackgroundColor3 = Color3.fromRGB(24, 26, 38)
    floatBtn.Text = "🔍"
    floatBtn.TextSize = 22
    floatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    floatBtn.Font = Enum.Font.GothamBold
    floatBtn.AutoButtonColor = false
    floatBtn.Parent = screenGui

    local floatCorner = Instance.new("UICorner")
    floatCorner.CornerRadius = UDim.new(0, 26)
    floatCorner.Parent = floatBtn

    local floatStroke = Instance.new("UIStroke")
    floatStroke.Color = Color3.fromRGB(88, 101, 242)
    floatStroke.Thickness = 2
    floatStroke.Parent = floatBtn

    -- Subtle pulse glow shadow
    local floatShadow = Instance.new("ImageLabel")
    floatShadow.Name = "Shadow"
    floatShadow.AnchorPoint = Vector2.new(0.5, 0.5)
    floatShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    floatShadow.Size = UDim2.new(1, 20, 1, 20)
    floatShadow.BackgroundTransparency = 1
    floatShadow.Image = "rbxassetid://1316045217"
    floatShadow.ImageColor3 = Color3.fromRGB(88, 101, 242)
    floatShadow.ImageTransparency = 0.65
    floatShadow.ZIndex = floatBtn.ZIndex - 1
    floatShadow.Parent = floatBtn

    local wasDragged = makeDraggable(floatBtn)

    -- Main Search Modal Window
    local searchModal = Instance.new("Frame")
    searchModal.Name = "SearchModal"
    searchModal.AnchorPoint = Vector2.new(0.5, 0.5)
    searchModal.Position = UDim2.new(0.5, 0, 0.5, 0)
    searchModal.Size = UDim2.new(0, 520, 0, 420)
    searchModal.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
    searchModal.Visible = false
    searchModal.ClipsDescendants = true
    searchModal.Parent = screenGui

    -- Responsiveness on mobile: clamp size to viewport
    local camera = workspace.CurrentCamera
    local function adjustSize()
        if camera and camera.ViewportSize.X > 0 then
            local maxX = math.min(camera.ViewportSize.X - 32, 520)
            local maxY = math.min(camera.ViewportSize.Y - 48, 440)
            searchModal.Size = UDim2.new(0, maxX, 0, maxY)
        end
    end
    adjustSize()
    if camera then
        camera:GetPropertyChangedSignal("ViewportSize"):Connect(adjustSize)
    end

    local modalCorner = Instance.new("UICorner")
    modalCorner.CornerRadius = UDim.new(0, 14)
    modalCorner.Parent = searchModal

    local modalStroke = Instance.new("UIStroke")
    modalStroke.Color = Color3.fromRGB(50, 55, 80)
    modalStroke.Thickness = 1.5
    modalStroke.Parent = searchModal

    -- Header
    local headerFrame = Instance.new("Frame")
    headerFrame.Name = "Header"
    headerFrame.Size = UDim2.new(1, 0, 0, 60)
    headerFrame.BackgroundColor3 = Color3.fromRGB(24, 26, 38)
    headerFrame.BorderSizePixel = 0
    headerFrame.Parent = searchModal

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 14)
    headerCorner.Parent = headerFrame

    -- Fix bottom corners of header
    local headerBottomCover = Instance.new("Frame")
    headerBottomCover.Size = UDim2.new(1, 0, 0, 14)
    headerBottomCover.Position = UDim2.new(0, 0, 1, -14)
    headerBottomCover.BackgroundColor3 = Color3.fromRGB(24, 26, 38)
    headerBottomCover.BorderSizePixel = 0
    headerBottomCover.Parent = headerFrame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -70, 0, 28)
    titleLabel.Position = UDim2.new(0, 18, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🔍 Looking for a script?"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 18
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = headerFrame

    local subLabel = Instance.new("TextLabel")
    subLabel.Size = UDim2.new(1, -70, 0, 20)
    subLabel.Position = UDim2.new(0, 18, 0, 34)
    subLabel.BackgroundTransparency = 1
    subLabel.Text = "Search 407+ supported games by Game Name or Place ID"
    subLabel.TextColor3 = Color3.fromRGB(150, 155, 175)
    subLabel.Font = Enum.Font.Gotham
    subLabel.TextSize = 12
    subLabel.TextXAlignment = Enum.TextXAlignment.Left
    subLabel.Parent = headerFrame

    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 32, 0, 32)
    closeBtn.Position = UDim2.new(1, -44, 0, 14)
    closeBtn.BackgroundColor3 = Color3.fromRGB(35, 38, 54)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = headerFrame

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeBtn

    -- Search Box Container
    local searchBarFrame = Instance.new("Frame")
    searchBarFrame.Name = "SearchBarFrame"
    searchBarFrame.Size = UDim2.new(1, -32, 0, 42)
    searchBarFrame.Position = UDim2.new(0, 16, 0, 72)
    searchBarFrame.BackgroundColor3 = Color3.fromRGB(26, 28, 42)
    searchBarFrame.Parent = searchModal

    local searchBarCorner = Instance.new("UICorner")
    searchBarCorner.CornerRadius = UDim.new(0, 8)
    searchBarCorner.Parent = searchBarFrame

    local searchBarStroke = Instance.new("UIStroke")
    searchBarStroke.Color = Color3.fromRGB(55, 60, 88)
    searchBarStroke.Thickness = 1
    searchBarStroke.Parent = searchBarFrame

    local searchInput = Instance.new("TextBox")
    searchInput.Name = "SearchInput"
    searchInput.Size = UDim2.new(1, -40, 1, 0)
    searchInput.Position = UDim2.new(0, 14, 0, 0)
    searchInput.BackgroundTransparency = 1
    searchInput.PlaceholderText = "Type game name (e.g. Arsenal) or Place ID (e.g. 286090429)..."
    searchInput.PlaceholderColor3 = Color3.fromRGB(110, 115, 135)
    searchInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchInput.Font = Enum.Font.Gotham
    searchInput.TextSize = 13
    searchInput.TextXAlignment = Enum.TextXAlignment.Left
    searchInput.ClearTextOnFocus = false
    searchInput.Parent = searchBarFrame

    local clearSearchBtn = Instance.new("TextButton")
    clearSearchBtn.Name = "ClearSearchBtn"
    clearSearchBtn.Size = UDim2.new(0, 24, 0, 24)
    clearSearchBtn.Position = UDim2.new(1, -30, 0.5, -12)
    clearSearchBtn.BackgroundTransparency = 1
    clearSearchBtn.Text = "✕"
    clearSearchBtn.TextColor3 = Color3.fromRGB(120, 125, 145)
    clearSearchBtn.Font = Enum.Font.GothamBold
    clearSearchBtn.TextSize = 12
    clearSearchBtn.Visible = false
    clearSearchBtn.Parent = searchBarFrame

    -- Results Count Label
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.new(1, -32, 0, 20)
    statsLabel.Position = UDim2.new(0, 18, 0, 118)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Text = "Showing all supported games"
    statsLabel.TextColor3 = Color3.fromRGB(140, 145, 165)
    statsLabel.Font = Enum.Font.Gotham
    statsLabel.TextSize = 11
    statsLabel.TextXAlignment = Enum.TextXAlignment.Left
    statsLabel.Parent = searchModal

    -- Scrolling Results Container
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ResultsList"
    scrollFrame.Size = UDim2.new(1, -32, 1, -150)
    scrollFrame.Position = UDim2.new(0, 16, 0, 140)
    scrollFrame.BackgroundColor3 = Color3.fromRGB(14, 15, 22)
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(88, 101, 242)
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.Parent = searchModal

    local scrollCorner = Instance.new("UICorner")
    scrollCorner.CornerRadius = UDim.new(0, 8)
    scrollCorner.Parent = scrollFrame

    local scrollLayout = Instance.new("UIListLayout")
    scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
    scrollLayout.Padding = UDim.new(0, 8)
    scrollLayout.Parent = scrollFrame

    local scrollPadding = Instance.new("UIPadding")
    scrollPadding.PaddingTop = UDim.new(0, 8)
    scrollPadding.PaddingBottom = UDim.new(0, 8)
    scrollPadding.PaddingLeft = UDim.new(0, 8)
    scrollPadding.PaddingRight = UDim.new(0, 8)
    scrollPadding.Parent = scrollFrame

    -- Toggle Modal Function
    local isOpen = false
    local function setModalOpen(open)
        isOpen = open
        if open then
            searchModal.Visible = true
            searchModal.Position = UDim2.new(0.5, 0, 0.53, 0)
            searchModal.BackgroundTransparency = 0.5
            TweenService:Create(searchModal, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.new(0.5, 0, 0.5, 0),
                BackgroundTransparency = 0
            }):Play()
            searchInput:CaptureFocus()
        else
            local tw = TweenService:Create(searchModal, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, 0, 0.53, 0),
                BackgroundTransparency = 0.5
            })
            tw:Play()
            tw.Completed:Connect(function()
                if not isOpen then
                    searchModal.Visible = false
                end
            end)
        end
    end

    floatBtn.MouseButton1Click:Connect(function()
        if not wasDragged() then
            setModalOpen(not isOpen)
        end
    end)

    closeBtn.MouseButton1Click:Connect(function()
        setModalOpen(false)
    end)

    -- Populate Results List
    local currentCards = {}
    local function renderResults(results)
        for _, card in ipairs(currentCards) do
            card:Destroy()
        end
        table.clear(currentCards)

        local currentPlaceId = game.PlaceId
        statsLabel.Text = string.format("Found %d game(s)", #results)

        local limit = math.min(#results, 100) -- Render up to 100 at a time for buttery smooth FPS
        for i = 1, limit do
            local gameInfo = results[i]
            local isCurrentGame = (gameInfo.PlaceId == currentPlaceId)

            local card = Instance.new("Frame")
            card.Name = "GameCard_" .. tostring(gameInfo.PlaceId)
            card.Size = UDim2.new(1, 0, 0, 72)
            card.BackgroundColor3 = isCurrentGame and Color3.fromRGB(30, 36, 56) or Color3.fromRGB(22, 24, 34)
            card.BorderSizePixel = 0
            card.LayoutOrder = i
            card.Parent = scrollFrame

            local cardCorner = Instance.new("UICorner")
            cardCorner.CornerRadius = UDim.new(0, 8)
            cardCorner.Parent = card

            local cardStroke = Instance.new("UIStroke")
            cardStroke.Color = isCurrentGame and Color3.fromRGB(88, 101, 242) or Color3.fromRGB(40, 43, 60)
            cardStroke.Thickness = isCurrentGame and 1.5 or 1
            cardStroke.Parent = card

            -- Game Name
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -210, 0, 22)
            nameLabel.Position = UDim2.new(0, 12, 0, 8)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = (isCurrentGame and "📍 " or "") .. gameInfo.Name
            nameLabel.TextColor3 = isCurrentGame and Color3.fromRGB(114, 137, 218) or Color3.fromRGB(255, 255, 255)
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 13
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            nameLabel.Parent = card

            -- Script Title / Place ID
            local infoLabel = Instance.new("TextLabel")
            infoLabel.Size = UDim2.new(1, -210, 0, 34)
            infoLabel.Position = UDim2.new(0, 12, 0, 30)
            infoLabel.BackgroundTransparency = 1
            infoLabel.Text = string.format("Place ID: %s\nScript: %s", tostring(gameInfo.PlaceId), gameInfo.Title or "Default Script")
            infoLabel.TextColor3 = Color3.fromRGB(140, 145, 165)
            infoLabel.Font = Enum.Font.Gotham
            infoLabel.TextSize = 11
            infoLabel.TextXAlignment = Enum.TextXAlignment.Left
            infoLabel.TextWrapped = true
            infoLabel.TextTruncate = Enum.TextTruncate.AtEnd
            infoLabel.Parent = card

            -- Action Buttons Container
            local btnContainer = Instance.new("Frame")
            btnContainer.Size = UDim2.new(0, 190, 0, 34)
            btnContainer.Position = UDim2.new(1, -200, 0.5, -17)
            btnContainer.BackgroundTransparency = 1
            btnContainer.Parent = card

            -- Gamehop Button
            local hopBtn = Instance.new("TextButton")
            hopBtn.Name = "HopButton"
            hopBtn.Size = UDim2.new(0, 88, 1, 0)
            hopBtn.Position = UDim2.new(0, 0, 0, 0)
            hopBtn.BackgroundColor3 = Color3.fromRGB(45, 52, 75)
            hopBtn.Text = "🚀 Hop"
            hopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            hopBtn.Font = Enum.Font.GothamBold
            hopBtn.TextSize = 11
            hopBtn.AutoButtonColor = false
            hopBtn.Parent = btnContainer

            local hopCorner = Instance.new("UICorner")
            hopCorner.CornerRadius = UDim.new(0, 6)
            hopCorner.Parent = hopBtn

            hopBtn.MouseButton1Click:Connect(function()
                if notificationModule then
                    notificationModule:Show("Teleporting...", "Hopping to " .. gameInfo.Name .. " (" .. tostring(gameInfo.PlaceId) .. ")", 4, "Info")
                end
                pcall(function()
                    TeleportService:Teleport(gameInfo.PlaceId, LocalPlayer)
                end)
            end)

            -- Execute Button (Conditioned: only executable if in that specific game!)
            local execBtn = Instance.new("TextButton")
            execBtn.Name = "ExecButton"
            execBtn.Size = UDim2.new(0, 94, 1, 0)
            execBtn.Position = UDim2.new(0, 96, 0, 0)
            execBtn.Font = Enum.Font.GothamBold
            execBtn.TextSize = 11
            execBtn.AutoButtonColor = false
            execBtn.Parent = btnContainer

            local execCorner = Instance.new("UICorner")
            execCorner.CornerRadius = UDim.new(0, 6)
            execCorner.Parent = execBtn

            if isCurrentGame then
                execBtn.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
                execBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                execBtn.Text = "▶ Run Script"

                execBtn.MouseButton1Click:Connect(function()
                    setModalOpen(false)
                    if authPromptModule then
                        authPromptModule:Prompt(gameInfo.Name, gameInfo.PlaceId, notificationModule, telemetryModule, function()
                            local loadFunc, compileErr = loadstring(gameInfo.Loadstring)
                            if loadFunc then
                                local ok, runErr = pcall(loadFunc)
                                if ok then
                                    if notificationModule then
                                        notificationModule:Show("AtomWare Active", "Loaded " .. gameInfo.Name .. " script successfully!", 3, "Success")
                                    end
                                else
                                    if notificationModule then
                                        notificationModule:Show("Execution Error", tostring(runErr), 5, "Error")
                                    end
                                end
                            else
                                if notificationModule then
                                    notificationModule:Show("Compile Error", tostring(compileErr), 5, "Error")
                                end
                            end
                        end)
                    end
                end)
            else
                execBtn.BackgroundColor3 = Color3.fromRGB(35, 38, 48)
                execBtn.TextColor3 = Color3.fromRGB(120, 125, 140)
                execBtn.Text = "🔒 Wrong Game"

                execBtn.MouseButton1Click:Connect(function()
                    if notificationModule then
                        notificationModule:Show("Action Blocked", "You must be inside " .. gameInfo.Name .. " to execute this script! Click Hop to join.", 3.5, "Warning")
                    end
                end)
            end

            table.insert(currentCards, card)
        end
    end

    -- Initial load with all games
    local allGames = gamesDb:GetAll()
    renderResults(allGames)

    -- Live Search Filter
    searchInput:GetPropertyChangedSignal("Text"):Connect(function()
        local query = searchInput.Text
        clearSearchBtn.Visible = (#query > 0)
        local filtered = gamesDb:Search(query)
        renderResults(filtered)
    end)

    clearSearchBtn.MouseButton1Click:Connect(function()
        searchInput.Text = ""
        clearSearchBtn.Visible = false
        renderResults(gamesDb:GetAll())
    end)

    return SearchWidget
end

return SearchWidget
