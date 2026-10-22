--[[
    Atomware Rivals - emu.lua
    Automated Anticheat Challenge Emulator Engine (Headless Background Service)
    Emulates and detaches ReplicatedFirst.LocalScript3 challenge callback,
    maintains MaterialService heartbeat, and cancels background MiscellaneousController watchdogs.
    Runs silently and seamlessly in the background across both Full and Lite modes on desktop and mobile.
]]

local Players = game:GetService("Players")
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
    startedAt = nil :: number?,
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
    logLevel = LOG_LEVELS.WARN,
    firstChallengeLogged = false,
}

local function traceback(problem: any): string
    return debug.traceback(tostring(problem), 2)
end

local function capture(callback: (...any) -> ...any, ...: any): any?
    local ok, result = xpcall(callback, traceback, ...)
    return if ok then nil else result
end

local function log(level: string, event: string, message: string)
    local numLevel = LOG_LEVELS[level] or 1
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
            if not state.firstChallengeLogged then
                state.firstChallengeLogged = true
                print("[Atomware Emulator] Challenges verified & actively being solved in background")
            end
        end
    end)
    state.relayConnection = relay

    if type(native.Disable) == "function" then pcall(native.Disable, native) end
    pcall(function() native.Enabled = false end)
    if state.originalScript then
        pcall(function() state.originalScript.Enabled = false end)
    end
    state.active = true

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
    log("INFO", "STOPPED", "Emulator stopped & original challenge state restored")
end

function Emulator.start()
    if state.started then return Emulator end



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
                    print("[Atomware Emulator] Initialized & active — challenges are being solved")
                    return
                end
            end
            log("ERROR", "CHALLENGE_TIMEOUT", "LocalScript3 challenge callback missing after extended scan")
        end)
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
    print("[Atomware Emulator] Initialized & active — challenges are being solved")

    return Emulator
end

-- Register in global environment
_G.AtomwareEmulator = Emulator

-- Automatically start on load
Emulator.start()

return Emulator
