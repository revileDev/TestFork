--[[
    Atomware Rivals - emu.lua
    Automated Anticheat Challenge Emulator & Real-time Debugging Engine
    Emulates and detaches ReplicatedFirst.LocalScript3 challenge callback,
    maintains MaterialService heartbeat, cancels background MiscellaneousController watchdogs,
    and renders a live real-time debug UI for tracking challenge packets, latency, and status.
    Runs seamlessly in both Full and Lite mode on desktop and mobile.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local MaterialService = game:GetService("MaterialService")

local Emulator = {}

local UNIVERSE_ID = 6035872082
local CALLBACK_TIMEOUT = 10
local MATERIAL_INTERVAL = 4
local LOG_LEVELS = { DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4 }

local state = {
    started = false,
    active = false,
    startedAt = nil,
    challenge = nil :: RemoteEvent?,
    native = nil :: any,
    originalScript = nil :: LocalScript?,
    relayConnection = nil :: RBXScriptConnection?,
    heartbeatRunning = false,
    namecallHooked = false,
    previousNamecall = nil :: any,
    inbound = 0,
    invoked = 0,
    responses = 0,
    malformed = 0,
    errors = 0,
    materialSent = 0,
    materialErrors = 0,
    miscFound = 0,
    miscCancelled = 0,
    miscFailed = 0,
    lastError = nil :: string?,
    lastChallengeAt = nil :: number?,
    lastResponseAt = nil :: number?,
    lastLatency = -1,
    logLevel = LOG_LEVELS.DEBUG,
    logs = {} :: { { timestamp: string, level: string, event: string, message: string } },
    logListeners = {} :: { (any) -> () },
    debugUI = nil :: any,
}

local function resolveGuiParent(): Instance?
    local ok, res = pcall(function()
        local get_hui = (gethui and gethui) or (type(debug) == "table" and (debug :: any).gethui)
        return (get_hui and get_hui()) or game:GetService("CoreGui") or (Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui"))
    end)
    return if ok then res else nil
end

local function traceback(problem: any): string
    return debug.traceback(tostring(problem), 2)
end

local function capture(callback: (...any) -> ...any, ...: any): any?
    local ok, result = xpcall(callback, traceback, ...)
    return if ok then nil else result
end

local function log(level: string, event: string, message: string)
    local numLevel = LOG_LEVELS[level] or 1
    local nowFormatted = os.date("%H:%M:%S")
    local entry = {
        timestamp = nowFormatted,
        level = level,
        event = event,
        message = tostring(message),
    }

    table.insert(state.logs, entry)
    if #state.logs > 150 then
        table.remove(state.logs, 1)
    end

    for _, listener in ipairs(state.logListeners) do
        pcall(listener, entry)
    end

    if numLevel >= state.logLevel then
        local line = string.format("[Emulator][%s][%s] %s", level, event, message)
        if level == "WARN" then
            warn(line)
        elseif level == "ERROR" then
            warn("[!] " .. line)
        else
            print(line)
        end
    end
end

local function sourceMatches(callback: any, needle: string): boolean
    local ok, source = pcall(debug.info, callback, "s")
    return ok and type(source) == "string"
        and source:gsub("%s+", ""):find(needle, 1, true) ~= nil
end

local function getRemoteEvents(container: Instance): { RemoteEvent }
    if type((container :: any).QueryDescendants) == "function" then
        local ok, res = pcall((container :: any).QueryDescendants, container, "RemoteEvent")
        if ok and type(res) == "table" then return res end
    end
    local list: { RemoteEvent } = {}
    for _, item in ipairs(container:GetDescendants()) do
        if item:IsA("RemoteEvent") then
            table.insert(list, item)
        end
    end
    return list
end

local function findChallenge(remotes: Instance): (RemoteEvent?, any)
    local deadline = os.clock() + CALLBACK_TIMEOUT
    repeat
        local challenge: RemoteEvent? = nil
        local native: any = nil
        local get_conns = getconnections or (type(debug) == "table" and (debug :: any).getconnections)
        
        for _, candidate in ipairs(getRemoteEvents(remotes)) do
            if type(get_conns) == "function" then
                local okConns, conns = pcall(get_conns, candidate.OnClientEvent)
                if okConns and type(conns) == "table" then
                    for _, connection in ipairs(conns) do
                        local callback = connection.Function
                        if type(callback) == "function"
                            and sourceMatches(callback, "ReplicatedFirst.LocalScript3") then
                            challenge = candidate
                            native = connection
                            break
                        end
                    end
                end
            end
            if native then break end
        end

        if challenge and native then
            return challenge, native
        end
        task.wait(0.2)
    until os.clock() >= deadline
    return nil, nil
end

local function observeResponses(challenge: RemoteEvent)
    if state.namecallHooked then return end
    local hook_meta = hookmetamethod or (type(debug) == "table" and (debug :: any).hookmetamethod)
    local new_cclosure = newcclosure or function(f) return f end
    local get_namecall = getnamecallmethod or function() return "" end
    if type(hook_meta) ~= "function" then
        log("WARN", "HOOK_METAMETHOD", "hookmetamethod unavailable; response latency observation disabled")
        return
    end

    local previousNamecall: any
    previousNamecall = hook_meta(game, "__namecall", new_cclosure(function(self, ...)
        if state.active and self == challenge and get_namecall() == "FireServer" then
            local args = table.pack(...)
            local packet, validation = args[1], args[3]
            if args.n == 5 and type(packet) == "table"
                and type(packet[#packet]) == "table"
                and type(validation) == "table" and #validation == 3 then
                state.responses += 1
                state.lastResponseAt = os.clock()
                local latency = state.lastChallengeAt
                    and math.floor((state.lastResponseAt - state.lastChallengeAt) * 1000 + 0.5)
                    or -1
                state.lastLatency = latency
                log("DEBUG", "CHALLENGE_RESPONSE", string.format(
                    "count=%d latency=%dms packetItems=%d",
                    state.responses, latency, #packet
                ))
            else
                state.malformed += 1
                if state.malformed <= 3 or state.malformed % 10 == 0 then
                    log("WARN", "CHALLENGE_SHAPE", string.format(
                        "unexpected response shape; count=%d (args=%d)", state.malformed, args.n
                    ))
                end
            end
        end
        return previousNamecall(self, ...)
    end))

    state.namecallHooked = true
    state.previousNamecall = previousNamecall
end

local function attachRelay(challenge: RemoteEvent, native: any): boolean
    local solve = native.Function
    if type(solve) ~= "function" then
        log("ERROR", "ATTACH_RELAY", "native connection does not have a callable callback function")
        return false
    end

    if state.relayConnection then
        pcall(function() state.relayConnection:Disconnect() end)
        state.relayConnection = nil
    end

    local relay: RBXScriptConnection
    relay = challenge.OnClientEvent:Connect(function(...)
        state.inbound += 1
        state.lastChallengeAt = os.clock()
        log("DEBUG", "CHALLENGE_INBOUND", string.format("Received challenge #%d from server", state.inbound))

        local args = table.pack(...)
        local failure = capture(function()
            solve(table.unpack(args, 1, args.n))
        end)

        if failure then
            state.errors += 1
            state.lastError = tostring(failure)
            log("ERROR", "CHALLENGE_CALLBACK", tostring(failure))
            state.active = false
            pcall(function() relay:Disconnect() end)
            if type(native.Enable) == "function" then pcall(native.Enable, native) end
            pcall(function() native.Enabled = true end)
            if state.originalScript then
                pcall(function() state.originalScript.Enabled = true end)
            end
            log("WARN", "RELAY_FALLBACK", "native connection restored after callback failure")
        else
            state.invoked += 1
            log("DEBUG", "CHALLENGE_SOLVED", string.format("Challenge #%d successfully solved by relay", state.inbound))
        end
    end)
    state.relayConnection = relay

    if type(native.Disable) == "function" then pcall(native.Disable, native) end
    pcall(function() native.Enabled = false end)
    if state.originalScript then
        pcall(function() state.originalScript.Enabled = false end)
    end
    state.active = true
    log("INFO", "RELAY_ATTACHED", "Challenge relay active; LocalScript3 detached & isolated")
    return true
end

local function startMaterialHeartbeat(materialRemote: RemoteEvent)
    if state.heartbeatRunning then return end
    state.heartbeatRunning = true
    task.spawn(function()
        while state.active and state.started do
            local failure = capture(function()
                materialRemote:FireServer("", nil, nil)
            end)
            if failure then
                state.materialErrors += 1
                state.lastError = tostring(failure)
                if state.materialErrors <= 3 or state.materialErrors % 10 == 0 then
                    log("ERROR", "MATERIAL_SEND", tostring(failure))
                end
            else
                state.materialSent += 1
            end
            task.wait(MATERIAL_INTERVAL)
        end
        state.heartbeatRunning = false
    end)
end

local function belongsToMisc(thread: thread): boolean
    for level = 1, 24 do
        local ok, source = pcall(debug.info, thread, level, "s")
        if not ok or not source then break end
        if type(source) == "string"
            and source:gsub("%s+", ""):find("MiscellaneousController", 1, true) then
            return true
        end
    end
    return false
end

local function cancelMiscThreads()
    local get_gc = getgc or (type(debug) == "table" and (debug :: any).getgc)
    if type(get_gc) ~= "function" then
        log("WARN", "MISC_TASKS", "getgc unavailable; skipping misc thread cancellation")
        return
    end

    local targets: { thread } = {}
    local okGc, objects = pcall(get_gc, true)
    if not okGc or type(objects) ~= "table" then
        okGc, objects = pcall(get_gc)
    end

    if okGc and type(objects) == "table" then
        for _, thread in ipairs(objects) do
            if type(thread) == "thread" and coroutine.status(thread) == "suspended"
                and belongsToMisc(thread) then
                table.insert(targets, thread)
            end
        end
    end

    state.miscFound = #targets
    for _, thread in ipairs(targets) do
        local ok = pcall(task.cancel, thread)
        if not ok then ok = pcall(coroutine.close, thread) end
        if ok then
            state.miscCancelled += 1
        else
            state.miscFailed += 1
        end
    end

    log("INFO", "MISC_TASKS", string.format(
        "Scanned GC: found=%d cancelled=%d failed=%d",
        state.miscFound, state.miscCancelled, state.miscFailed
    ))
end

-- =========================================================================
-- Real-time Debug UI
-- =========================================================================
local function createDebugUI()
    if state.debugUI and state.debugUI.screen and state.debugUI.screen.Parent then
        return state.debugUI
    end

    local parent = resolveGuiParent()
    if not parent then return nil end

    pcall(function()
        local prior = parent:FindFirstChild("Atomware_EmulatorDebugUI")
        if prior then prior:Destroy() end
    end)

    local screen = Instance.new("ScreenGui")
    screen.Name = "Atomware_EmulatorDebugUI"
    screen.ResetOnSpawn = false
    screen.DisplayOrder = 10001
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local accentColor = Color3.fromRGB(157, 48, 255)
    local bgMain = Color3.fromRGB(14, 11, 22)
    local cardBg = Color3.fromRGB(22, 18, 34)

    -- Floating Compact Mini-Pill (When minimized)
    local miniPill = Instance.new("TextButton")
    miniPill.Name = "MiniPill"
    miniPill.Size = UDim2.fromOffset(260, 32)
    miniPill.Position = UDim2.new(0, 24, 0, 80)
    miniPill.BackgroundColor3 = bgMain
    miniPill.BackgroundTransparency = 0.1
    miniPill.Text = ""
    miniPill.AutoButtonColor = false
    miniPill.Visible = false
    miniPill.Active = true
    miniPill.Parent = screen

    local pillCorner = Instance.new("UICorner")
    pillCorner.CornerRadius = UDim.new(0, 16)
    pillCorner.Parent = miniPill

    local pillStroke = Instance.new("UIStroke")
    pillStroke.Color = accentColor
    pillStroke.Thickness = 1.2
    pillStroke.Parent = miniPill

    local pillLabel = Instance.new("TextLabel")
    pillLabel.Size = UDim2.new(1, -16, 1, 0)
    pillLabel.Position = UDim2.fromOffset(10, 0)
    pillLabel.BackgroundTransparency = 1
    pillLabel.Font = Enum.Font.GothamBold
    pillLabel.TextSize = 11
    pillLabel.TextColor3 = Color3.fromRGB(240, 230, 255)
    pillLabel.TextXAlignment = Enum.TextXAlignment.Left
    pillLabel.Text = "🛡️ EMU: ACTIVE | In: 0 | --"
    pillLabel.Parent = miniPill

    -- Main Window Panel
    local panel = Instance.new("Frame")
    panel.Name = "DebugPanel"
    panel.Size = UDim2.fromOffset(480, 360)
    panel.Position = UDim2.new(0, 24, 0, 80)
    panel.BackgroundColor3 = bgMain
    panel.BackgroundTransparency = 0.05
    panel.BorderSizePixel = 0
    panel.Active = true
    panel.Parent = screen

    local pCorner = Instance.new("UICorner")
    pCorner.CornerRadius = UDim.new(0, 10)
    pCorner.Parent = panel

    local pStroke = Instance.new("UIStroke")
    pStroke.Color = Color3.fromRGB(48, 38, 70)
    pStroke.Thickness = 1.2
    pStroke.Parent = panel

    -- Top Accent Line
    local topAccent = Instance.new("Frame")
    topAccent.Name = "TopAccent"
    topAccent.Size = UDim2.new(1, 0, 0, 2)
    topAccent.BackgroundColor3 = accentColor
    topAccent.BorderSizePixel = 0
    topAccent.Parent = panel

    local taCorner = Instance.new("UICorner")
    taCorner.CornerRadius = UDim.new(0, 2)
    taCorner.Parent = topAccent

    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 38)
    header.BackgroundTransparency = 1
    header.Parent = panel

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Position = UDim2.fromOffset(12, 0)
    titleLbl.Size = UDim2.new(0, 230, 1, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 12
    titleLbl.TextColor3 = Color3.fromRGB(245, 240, 255)
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Text = "🛡️ ATOMWARE // EMULATOR DEBUGGER"
    titleLbl.Parent = header

    -- Status Badge Pill in Header
    local statusBadge = Instance.new("Frame")
    statusBadge.Name = "StatusBadge"
    statusBadge.Size = UDim2.fromOffset(74, 20)
    statusBadge.Position = UDim2.new(0, 245, 0.5, -10)
    statusBadge.BackgroundColor3 = Color3.fromRGB(15, 35, 20)
    statusBadge.BorderSizePixel = 0
    statusBadge.Parent = header

    local sbCorner = Instance.new("UICorner")
    sbCorner.CornerRadius = UDim.new(0, 4)
    sbCorner.Parent = statusBadge

    local sbStroke = Instance.new("UIStroke")
    sbStroke.Color = Color3.fromRGB(60, 200, 100)
    sbStroke.Thickness = 1
    sbStroke.Parent = statusBadge

    local statusText = Instance.new("TextLabel")
    statusText.Size = UDim2.new(1, 0, 1, 0)
    statusText.BackgroundTransparency = 1
    statusText.Font = Enum.Font.GothamBold
    statusText.TextSize = 10
    statusText.TextColor3 = Color3.fromRGB(80, 250, 120)
    statusText.Text = "● ACTIVE"
    statusText.Parent = statusBadge

    -- Minimize Button
    local minBtn = Instance.new("TextButton")
    minBtn.Name = "MinBtn"
    minBtn.Size = UDim2.fromOffset(26, 24)
    minBtn.Position = UDim2.new(1, -64, 0.5, -12)
    minBtn.BackgroundColor3 = Color3.fromRGB(24, 20, 36)
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 13
    minBtn.TextColor3 = Color3.fromRGB(210, 200, 230)
    minBtn.Text = "—"
    minBtn.AutoButtonColor = false
    minBtn.Parent = header

    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(0, 5)
    minCorner.Parent = minBtn

    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.fromOffset(26, 24)
    closeBtn.Position = UDim2.new(1, -34, 0.5, -12)
    closeBtn.BackgroundColor3 = Color3.fromRGB(36, 18, 26)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 13
    closeBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
    closeBtn.Text = "✕"
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = header

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 5)
    closeCorner.Parent = closeBtn

    -- Metrics Cards Container (Row of 3 cards)
    local cardsRow = Instance.new("Frame")
    cardsRow.Name = "CardsRow"
    cardsRow.Position = UDim2.fromOffset(12, 42)
    cardsRow.Size = UDim2.new(1, -24, 0, 74)
    cardsRow.BackgroundTransparency = 1
    cardsRow.Parent = panel

    local function createMetricCard(name: string, posOffset: number, title: string)
        local card = Instance.new("Frame")
        card.Name = name
        card.Size = UDim2.new(0.32, 0, 1, 0)
        card.Position = UDim2.new(posOffset, 0, 0, 0)
        card.BackgroundColor3 = cardBg
        card.BorderSizePixel = 0
        card.Parent = cardsRow

        local cCorner = Instance.new("UICorner")
        cCorner.CornerRadius = UDim.new(0, 8)
        cCorner.Parent = card

        local cStroke = Instance.new("UIStroke")
        cStroke.Color = Color3.fromRGB(36, 28, 52)
        cStroke.Thickness = 1
        cStroke.Parent = card

        local cTitle = Instance.new("TextLabel")
        cTitle.Size = UDim2.new(1, -12, 0, 18)
        cTitle.Position = UDim2.fromOffset(8, 6)
        cTitle.BackgroundTransparency = 1
        cTitle.Font = Enum.Font.GothamBold
        cTitle.TextSize = 10
        cTitle.TextColor3 = Color3.fromRGB(180, 160, 210)
        cTitle.TextXAlignment = Enum.TextXAlignment.Left
        cTitle.Text = title
        cTitle.Parent = card

        local val1 = Instance.new("TextLabel")
        val1.Name = "Val1"
        val1.Size = UDim2.new(1, -12, 0, 16)
        val1.Position = UDim2.fromOffset(8, 26)
        val1.BackgroundTransparency = 1
        val1.Font = Enum.Font.GothamMedium
        val1.TextSize = 10
        val1.TextColor3 = Color3.fromRGB(240, 235, 255)
        val1.TextXAlignment = Enum.TextXAlignment.Left
        val1.Text = "--"
        val1.Parent = card

        local val2 = Instance.new("TextLabel")
        val2.Name = "Val2"
        val2.Size = UDim2.new(1, -12, 0, 16)
        val2.Position = UDim2.fromOffset(8, 44)
        val2.BackgroundTransparency = 1
        val2.Font = Enum.Font.GothamMedium
        val2.TextSize = 10
        val2.TextColor3 = Color3.fromRGB(210, 200, 230)
        val2.TextXAlignment = Enum.TextXAlignment.Left
        val2.Text = "--"
        val2.Parent = card

        return card, val1, val2
    end

    local _card1, card1Val1, card1Val2 = createMetricCard("Card1", 0, "CHALLENGE TRAFFIC")
    local _card2, card2Val1, card2Val2 = createMetricCard("Card2", 0.34, "HEARTBEAT & WATCHDOG")
    local _card3, card3Val1, card3Val2 = createMetricCard("Card3", 0.68, "ENVIRONMENT")

    -- Real-time Logs Console Header
    local logHeader = Instance.new("Frame")
    logHeader.Name = "LogHeader"
    logHeader.Position = UDim2.fromOffset(12, 122)
    logHeader.Size = UDim2.new(1, -24, 0, 24)
    logHeader.BackgroundTransparency = 1
    logHeader.Parent = panel

    local logTitle = Instance.new("TextLabel")
    logTitle.Size = UDim2.new(0, 180, 1, 0)
    logTitle.BackgroundTransparency = 1
    logTitle.Font = Enum.Font.GothamBold
    logTitle.TextSize = 10
    logTitle.TextColor3 = Color3.fromRGB(190, 170, 220)
    logTitle.TextXAlignment = Enum.TextXAlignment.Left
    logTitle.Text = "REALTIME EVENT LOG STREAM"
    logTitle.Parent = logHeader

    local autoScroll = true
    local scrollToggleBtn = Instance.new("TextButton")
    scrollToggleBtn.Name = "AutoScrollBtn"
    scrollToggleBtn.Size = UDim2.fromOffset(90, 20)
    scrollToggleBtn.Position = UDim2.new(1, -150, 0, 2)
    scrollToggleBtn.BackgroundColor3 = Color3.fromRGB(22, 18, 34)
    scrollToggleBtn.Font = Enum.Font.GothamBold
    scrollToggleBtn.TextSize = 9
    scrollToggleBtn.TextColor3 = Color3.fromRGB(120, 255, 160)
    scrollToggleBtn.Text = "Scroll: ON"
    scrollToggleBtn.AutoButtonColor = false
    scrollToggleBtn.Parent = logHeader

    local stCorner = Instance.new("UICorner")
    stCorner.CornerRadius = UDim.new(0, 4)
    stCorner.Parent = scrollToggleBtn

    local clearBtn = Instance.new("TextButton")
    clearBtn.Name = "ClearBtn"
    clearBtn.Size = UDim2.fromOffset(50, 20)
    clearBtn.Position = UDim2.new(1, -54, 0, 2)
    clearBtn.BackgroundColor3 = Color3.fromRGB(22, 18, 34)
    clearBtn.Font = Enum.Font.GothamBold
    clearBtn.TextSize = 9
    clearBtn.TextColor3 = Color3.fromRGB(200, 190, 220)
    clearBtn.Text = "Clear"
    clearBtn.AutoButtonColor = false
    clearBtn.Parent = logHeader

    local clCorner = Instance.new("UICorner")
    clCorner.CornerRadius = UDim.new(0, 4)
    clCorner.Parent = clearBtn

    -- Scrolling Logs List
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "LogStream"
    scrollFrame.Position = UDim2.fromOffset(12, 150)
    scrollFrame.Size = UDim2.new(1, -24, 1, -162)
    scrollFrame.BackgroundColor3 = Color3.fromRGB(9, 7, 15)
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageColor3 = accentColor
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollFrame.Parent = panel

    local sfCorner = Instance.new("UICorner")
    sfCorner.CornerRadius = UDim.new(0, 6)
    sfCorner.Parent = scrollFrame

    local sfStroke = Instance.new("UIStroke")
    sfStroke.Color = Color3.fromRGB(30, 24, 44)
    sfStroke.Thickness = 1
    sfStroke.Parent = scrollFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 3)
    listLayout.Parent = scrollFrame

    local sfPadding = Instance.new("UIPadding")
    sfPadding.PaddingTop = UDim.new(0, 6)
    sfPadding.PaddingBottom = UDim.new(0, 6)
    sfPadding.PaddingLeft = UDim.new(0, 8)
    sfPadding.PaddingRight = UDim.new(0, 8)
    sfPadding.Parent = scrollFrame

    -- Append Log Entry to ScrollingFrame
    local logCounter = 0
    local function appendLogItem(entry: { timestamp: string, level: string, event: string, message: string })
        logCounter += 1
        local row = Instance.new("Frame")
        row.Name = "Row_" .. logCounter
        row.Size = UDim2.new(1, 0, 0, 18)
        row.BackgroundTransparency = 1
        row.LayoutOrder = logCounter
        row.Parent = scrollFrame

        local col = Color3.fromRGB(180, 180, 195)
        if entry.level == "DEBUG" then
            col = Color3.fromRGB(100, 210, 255)
        elseif entry.level == "INFO" then
            col = Color3.fromRGB(195, 125, 255)
        elseif entry.level == "WARN" then
            col = Color3.fromRGB(255, 190, 70)
        elseif entry.level == "ERROR" then
            col = Color3.fromRGB(255, 80, 90)
        end

        local text = string.format("[%s] [%s] [%s] %s", entry.timestamp, entry.level, entry.event, entry.message)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.Code
        lbl.TextSize = 10
        lbl.TextColor3 = col
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        lbl.Text = text
        lbl.Parent = row

        if autoScroll then
            scrollFrame.CanvasPosition = Vector2.new(0, 999999)
        end
    end

    for _, existing in ipairs(state.logs) do
        appendLogItem(existing)
    end

    table.insert(state.logListeners, appendLogItem)

    -- Button Interactions
    scrollToggleBtn.MouseButton1Click:Connect(function()
        autoScroll = not autoScroll
        scrollToggleBtn.Text = if autoScroll then "Scroll: ON" else "Scroll: OFF"
        scrollToggleBtn.TextColor3 = if autoScroll then Color3.fromRGB(120, 255, 160) else Color3.fromRGB(255, 140, 140)
    end)

    clearBtn.MouseButton1Click:Connect(function()
        for _, child in ipairs(scrollFrame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
    end)

    minBtn.MouseButton1Click:Connect(function()
        panel.Visible = false
        miniPill.Visible = true
    end)

    miniPill.MouseButton1Click:Connect(function()
        miniPill.Visible = false
        panel.Visible = true
    end)

    closeBtn.MouseButton1Click:Connect(function()
        panel.Visible = false
        miniPill.Visible = false
    end)

    -- Window Dragging (Desktop Mouse & Mobile Touch)
    local function makeDraggable(dragHandle: GuiObject, dragTarget: GuiObject)
        local dragging = false
        local dragStart: Vector2? = nil
        local startPos: UDim2? = nil

        dragHandle.InputBegan:Connect(function(input: InputObject)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = UserInputService:GetMouseLocation()
                startPos = dragTarget.Position
            end
        end)

        UserInputService.InputChanged:Connect(function(input: InputObject)
            if not dragging or not dragStart or not startPos then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                local cur = UserInputService:GetMouseLocation()
                local delta = cur - dragStart
                dragTarget.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end)

        UserInputService.InputEnded:Connect(function(input: InputObject)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
    end

    makeDraggable(header, panel)
    makeDraggable(miniPill, miniPill)

    -- Live Metrics Refresh Loop (Throttled to 0.15s)
    local uiLoopRunning = true
    task.spawn(function()
        while uiLoopRunning and screen and screen.Parent do
            local now = os.clock()
            local uptime = state.startedAt and math.floor(now - state.startedAt) or 0
            local hrs = math.floor(uptime / 3600)
            local mins = math.floor((uptime % 3600) / 60)
            local secs = uptime % 60
            local uptimeStr = string.format("%02d:%02d:%02d", hrs, mins, secs)

            if state.active then
                statusBadge.BackgroundColor3 = Color3.fromRGB(15, 38, 22)
                sbStroke.Color = Color3.fromRGB(60, 200, 100)
                statusText.TextColor3 = Color3.fromRGB(80, 250, 120)
                statusText.Text = "● ACTIVE"
            else
                statusBadge.BackgroundColor3 = Color3.fromRGB(38, 16, 20)
                sbStroke.Color = Color3.fromRGB(220, 70, 80)
                statusText.TextColor3 = Color3.fromRGB(255, 90, 100)
                statusText.Text = "● INACTIVE"
            end

            local latStr = if state.lastLatency >= 0 then tostring(state.lastLatency) .. " ms" else "--"
            card1Val1.Text = string.format("In: %d | Solved: %d", state.inbound, state.invoked)
            card1Val2.Text = string.format("Sent: %d | Latency: %s", state.responses, latStr)

            card2Val1.Text = string.format("Material Sent: %d", state.materialSent)
            card2Val2.Text = string.format("Misc Closed: %d | Err: %d", state.miscCancelled, state.errors)

            local remName = state.challenge and state.challenge.Name or "Scanning..."
            card3Val1.Text = string.format("Remote: %s", remName)
            card3Val2.Text = string.format("Uptime: %s", uptimeStr)

            pillLabel.Text = string.format(
                "🛡️ EMU: %s | In: %d | %s",
                if state.active then "ACTIVE" else "IDLE",
                state.inbound,
                latStr
            )

            task.wait(0.2)
        end
    end)

    screen.Parent = parent

    state.debugUI = {
        screen = screen,
        panel = panel,
        miniPill = miniPill,
        destroy = function()
            uiLoopRunning = false
            pcall(function() screen:Destroy() end)
            state.debugUI = nil
        end,
    }

    return state.debugUI
end

-- =========================================================================
-- Public Emulator API
-- =========================================================================
function Emulator.setLogLevel(level: string)
    assert(LOG_LEVELS[level], "invalid log level")
    state.logLevel = LOG_LEVELS[level]
end

function Emulator.status()
    local now = os.clock()
    return {
        started = state.started,
        active = state.active,
        uptime = state.startedAt and now - state.startedAt or nil,
        remote = state.challenge and state.challenge:GetFullName() or nil,
        originalScriptEnabled = if state.originalScript then state.originalScript.Enabled else nil,
        originalConnectionEnabled = if state.native then state.native.Enabled else nil,
        inbound = state.inbound,
        invoked = state.invoked,
        responses = state.responses,
        malformed = state.malformed,
        errors = state.errors,
        materialSent = state.materialSent,
        materialErrors = state.materialErrors,
        miscFound = state.miscFound,
        miscCancelled = state.miscCancelled,
        miscFailed = state.miscFailed,
        lastError = state.lastError,
        lastLatency = state.lastLatency,
        challengeAge = state.lastChallengeAt and now - state.lastChallengeAt or nil,
        responseAge = state.lastResponseAt and now - state.lastResponseAt or nil,
    }
end

function Emulator.toggleUi(visible: boolean?)
    if not state.debugUI then
        createDebugUI()
        return
    end
    if visible ~= nil then
        state.debugUI.panel.Visible = visible
        if visible then state.debugUI.miniPill.Visible = false end
    else
        local cur = state.debugUI.panel.Visible or state.debugUI.miniPill.Visible
        state.debugUI.panel.Visible = not cur
        state.debugUI.miniPill.Visible = false
    end
end

function Emulator.stop()
    state.active = false
    state.started = false
    if state.relayConnection then
        pcall(function() state.relayConnection:Disconnect() end)
        state.relayConnection = nil
    end
    if state.native then
        if type(state.native.Enable) == "function" then pcall(state.native.Enable, state.native) end
        pcall(function() state.native.Enabled = true end)
    end
    if state.originalScript then
        pcall(function() state.originalScript.Enabled = true end)
    end
    if state.debugUI then
        pcall(state.debugUI.destroy)
    end
    log("INFO", "STOPPED", "Emulator stopped & original challenge state restored")
end

function Emulator.start()
    if state.started then return Emulator end

    log("INFO", "STARTUP", "Initializing Atomware Rivals Challenge Emulator...")

    -- Verification guards
    if game.GameId ~= UNIVERSE_ID and game.PlaceId ~= 17625359962 and tostring(game.PlaceId) ~= "17625359962" then
        log("WARN", "GAME_GUARD", "RIVALS universe expected (GameId: 6035872082); proceeding cautiously")
    end

    local get_conns = getconnections or (type(debug) == "table" and (debug :: any).getconnections)
    if type(get_conns) ~= "function" then
        log("ERROR", "API_MISSING", "getconnections unavailable in this executor")
        return Emulator
    end

    local hook_meta = hookmetamethod or (type(debug) == "table" and (debug :: any).hookmetamethod)
    if type(hook_meta) ~= "function" then
        log("WARN", "API_MISSING", "hookmetamethod unavailable; continuing without namecall inspection")
    end

    local originalScript = ReplicatedFirst:WaitForChild("LocalScript3", 6)
    if not originalScript then
        log("WARN", "SCRIPT_MISSING", "ReplicatedFirst.LocalScript3 not found yet; retrying in background")
        task.spawn(function()
            local s = ReplicatedFirst:WaitForChild("LocalScript3", 20)
            if s and not state.started then
                Emulator.start()
            end
        end)
        return Emulator
    end

    if not originalScript.Enabled then
        originalScript.Enabled = true
    end

    local remotes = ReplicatedStorage:WaitForChild("Remotes", 8)
    if not remotes then
        log("ERROR", "REMOTES_MISSING", "ReplicatedStorage.Remotes missing")
        return Emulator
    end

    local materialRemote = MaterialService:WaitForChild("RemoteEvent", 6) or MaterialService:FindFirstChildOfClass("RemoteEvent")

    local challenge, native = findChallenge(remotes)
    if not challenge or not native then
        log("WARN", "CHALLENGE_SCAN", "LocalScript3 challenge callback not yet bound; retrying in background")
        task.spawn(function()
            for _ = 1, 30 do
                task.wait(1)
                if state.started then return end
                local c, n = findChallenge(remotes)
                if c and n then
                    state.challenge = c
                    state.native = n
                    observeResponses(c)
                    attachRelay(c, n)
                    if materialRemote then startMaterialHeartbeat(materialRemote) end
                    cancelMiscThreads()
                    state.started = true
                    state.startedAt = os.clock()
                    log("INFO", "STARTED", "Emulator started (delayed hook)")
                    createDebugUI()
                    return
                end
            end
            log("ERROR", "CHALLENGE_TIMEOUT", "LocalScript3 challenge callback missing after extended scan")
        end)
        createDebugUI()
        return Emulator
    end

    if type(native.Enable) == "function" then pcall(native.Enable, native) end
    pcall(function() native.Enabled = true end)

    state.originalScript = originalScript :: LocalScript
    state.challenge = challenge
    state.native = native

    observeResponses(challenge)
    attachRelay(challenge, native)
    if materialRemote then
        startMaterialHeartbeat(materialRemote)
    else
        log("WARN", "MATERIAL_REMOTE", "MaterialService.RemoteEvent not found; heartbeat disabled")
    end
    cancelMiscThreads()

    state.started = true
    state.startedAt = os.clock()
    log("INFO", "STARTED", "Atomware Rivals Challenge Emulator fully online")

    -- Launch Real-time Debug UI
    createDebugUI()

    return Emulator
end

-- Keybind listener to toggle debug UI anytime (F4 key)
pcall(function()
    UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
        if not processed and input.KeyCode == Enum.KeyCode.F4 then
            Emulator.toggleUi()
        end
    end)
end)

-- Register in global environment for developer/user access
_G.AtomwareEmulator = Emulator
_G.AtomwareEmuToggleUi = Emulator.toggleUi

-- Automatically start on load
Emulator.start()

return Emulator
