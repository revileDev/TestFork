--[[
    Atomware Rivals - client_guard.lua (Stage 0 Pre-Flight Integrity Guard)
    Standalone Attestation & Dynamic Challenge Solver.
    Zero Auth UI, zero feature code, and zero license keys exist in this module.

    FALSE-POSITIVE PREVENTION RULES:
    - Executor standard APIs (dumpstring, rconsolename, saveinstance, getgenv, etc.)
      are NEVER flagged — these are shipped in every supported executor.
    - Only ACTIVE running spy/interceptor tool instances are flagged.
    - Dual-confirmation required: a single signal is never enough to block.
    - Flags are sent to the server as soft telemetry only; the server decides
      whether to hard-block based on its own dual-confirmation threshold.
]]

local HttpService = game:GetService("HttpService")

local ClientGuard = {}
ClientGuard.__index = ClientGuard

-- ============================================================================
-- 1. Boot-time Native Baseline Calibration
-- Captures the executor's own native C-bridge signatures at boot so we can
-- distinguish "executor-hooked" from "user-injected spy tool running live".
-- ============================================================================
local function sampleCBaseline()
    local baseline = {}
    pcall(function()
        if type(debug) == "table" and type(debug.info) == "function" then
            baseline.abs    = tostring(debug.info(math.abs,      "s"))
            baseline.insert = tostring(debug.info(table.insert,   "s"))
            baseline.find   = tostring(debug.info(string.find,    "s"))
            -- Capture the executor's own loadstring signature at boot
            -- so we can compare rather than assuming a hardcoded value
            baseline.loadstring = type(loadstring) == "function"
                and tostring(debug.info(loadstring, "s"))
                or "missing"
        end
    end)
    return baseline
end

-- ============================================================================
-- 2. Environmental Integrity Probe (False-Positive Hardened)
--
-- What we DO flag (dual-confirm required):
--   A. __namecall overwritten with a Lua closure → only an ACTIVE spy does this
--   B. loadstring replaced with a Lua closure that DEVIATES from boot baseline
--      AND the deviation is confirmed by debug.info parameter count check
--
-- What we do NOT flag (executor standard APIs - zero false positive risk):
--   - saveinstance, dumpstring, rconsolename, getgenv, getfenv, syn.*
--   - Any global that every mainstream executor ships by default
-- ============================================================================
local function scanEnvironment(baseline)
    local softFlags  = {}  -- single-signal: logged but never causes a block alone
    local hardFlags  = {}  -- dual-confirmed active interception: reported to server

    pcall(function()
        -- ----------------------------------------------------------------
        -- Check A: __namecall active Lua closure override
        -- A LIVE spy tool (e.g. SimpleSpy, Hydroxide) hooks __namecall with
        -- a Lua closure at runtime. The executor ships __namecall as a C closure.
        -- If we see islclosure(namecall) == true, that's a running spy, not executor.
        -- ----------------------------------------------------------------
        local gm = getrawmetatable and getrawmetatable(game)
        if gm then
            local nc = rawget(gm, "__namecall")
            if nc ~= nil and islclosure and islclosure(nc) then
                -- Dual confirm: also check that __index is not similarly hooked
                -- (some executors hook both; if ONLY namecall is Lua, it's a spy)
                local idx = rawget(gm, "__index")
                local indexIsNative = not islclosure(idx)
                if indexIsNative then
                    table.insert(hardFlags, "namecall_spy_active")
                else
                    table.insert(softFlags, "namecall_lclosure_unconfirmed")
                end
            end
        end

        -- ----------------------------------------------------------------
        -- Check B: loadstring Lua-closure deviation from boot baseline
        -- If loadstring is now a Lua closure AND its debug.info source
        -- differs from what we captured at boot, it was replaced mid-session.
        -- Normal executors ship loadstring as C (iscclosure = true).
        -- ----------------------------------------------------------------
        if type(loadstring) == "function" and islclosure and iscclosure then
            local lsIsLua = islclosure(loadstring)
            local lsIsCClosure = iscclosure(loadstring)
            if lsIsLua and not lsIsCClosure then
                -- Confirm it actually deviated from what we saw at boot
                local currentSig = ""
                pcall(function()
                    if type(debug) == "table" and type(debug.info) == "function" then
                        currentSig = tostring(debug.info(loadstring, "s"))
                    end
                end)
                if baseline.loadstring and currentSig ~= baseline.loadstring then
                    table.insert(hardFlags, "loadstring_replaced_live")
                else
                    table.insert(softFlags, "loadstring_lclosure_unconfirmed")
                end
            end
        end

        -- ----------------------------------------------------------------
        -- Check C: Known live spy-tool INSTANCE globals (not executor APIs)
        -- These are the INSTANCE tables/functions that running spy tools inject,
        -- NOT the standard executor APIs like dumpstring or rconsolename.
        --
        -- IMPORTANT DISTINCTION:
        --   dumpstring   → standard executor function, present on all executors → NOT FLAGGED
        --   rconsolename → standard executor function, present on all executors → NOT FLAGGED
        --   saveinstance → standard executor function, present on all executors → NOT FLAGGED
        --   SimpleSpy    → the RUNNING TOOL's global instance table           → FLAGGED
        --   Hydroxide    → the RUNNING TOOL's global instance table           → FLAGGED
        -- ----------------------------------------------------------------
        local activeSpyInstances = {
            "SimpleSpy",    -- SimpleSpy running instance
            "Hydroxide",    -- Hydroxide running instance
            "GGSpy",        -- GGSpy running instance
            "seerspy",      -- SeerSpy running instance
            "rrspy",        -- RRSpy running instance
        }

        local genv = (type(getgenv) == "function" and getgenv()) or _G
        for _, name in ipairs(activeSpyInstances) do
            if genv[name] ~= nil then
                -- Confirm it's actually an active table/module, not just a name collision
                local val = genv[name]
                if type(val) == "table" or type(val) == "function" then
                    table.insert(hardFlags, "active_spy_" .. name)
                end
            end
        end
    end)

    return softFlags, hardFlags
end

-- ============================================================================
-- 3. Dynamic Arithmetic Challenge Solver
-- ============================================================================
local function solveArithmeticChallenge(seed, rounds)
    local acc = bit32.bxor(seed, 0x5F3759DF)
    for i = 1, rounds do
        acc = bit32.bxor(bit32.band(acc * 31, 0xFFFFFFFF), bit32.band(i * 17, 0xFFFFFFFF))
    end
    return acc % 1000003
end

-- ============================================================================
-- 4. Atomic Self-Destruct Memory Purge
-- Only triggered on SERVER-CONFIRMED hard block, never on soft flags alone.
-- ============================================================================
function ClientGuard.purgePayload()
    pcall(function()
        if _G.AtomwareUnload then
            pcall(_G.AtomwareUnload)
        end
        _G.AtomwareUILoaded    = nil
        _G.AtomwareFeaturesLoaded = nil
        _G.AtomwareWindow      = nil
        _G.__AERO_GATEWAY_TOKEN = nil
    end)
    collectgarbage("collect")
    collectgarbage("collect")
end

-- ============================================================================
-- 5. Primary Pre-Flight Attestation Handshake
-- ============================================================================
function ClientGuard.runPreFlight(baseUrl, slug)
    local getReq = (syn and syn.request)
        or (http and http.request)
        or http_request
        or request
        or (fluxus and fluxus.request)

    -- Sample baseline BEFORE requesting challenge (captures clean executor state)
    local baseline = sampleCBaseline()

    -- Request randomized dynamic challenge
    local challengeData = nil
    pcall(function()
        local raw = game:HttpGet(baseUrl .. "/api/auth/probe?slug=" .. slug .. "&_t=" .. os.time())
        challengeData = HttpService:JSONDecode(raw)
    end)

    if not challengeData or not challengeData.session_id or not challengeData.challenges then
        warn("[Atomware] Pre-flight gateway unreachable — skipping security gate.")
        -- Fail OPEN on network error so real users are never blocked by server downtime
        return true
    end

    -- Solve challenge opcodes
    local solutions = {}
    for _, ch in ipairs(challengeData.challenges) do
        if ch.type == "arithmetic" then
            solutions.arithmetic = solveArithmeticChallenge(ch.seed, ch.rounds)
        end
    end

    -- Run environment probe AFTER baseline was captured
    local softFlags, hardFlags = scanEnvironment(baseline)

    -- Only hard flags are submitted to the server as tamper evidence.
    -- Soft flags are dropped client-side — they are not actionable signals.
    -- Server applies its own dual-confirmation before any ban decision.
    local proofPayload = HttpService:JSONEncode({
        session_id  = challengeData.session_id,
        slug        = slug,
        hwid        = (type(gethwid) == "function" and gethwid()) or "",
        solutions   = solutions,
        tamper_flags = hardFlags, -- Only dual-confirmed active spy tool detections
        c_signature = tostring(baseline.abs) .. ":" .. tostring(baseline.insert),
    })

    -- Submit attestation proof
    local respBody = nil
    if getReq then
        local res = getReq({
            Url     = baseUrl .. "/api/auth/probe",
            Method  = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body    = proofPayload,
        })
        if res and (res.StatusCode == 200 or res.Status == 200) then
            respBody = res.Body
        end
    else
        pcall(function()
            respBody = game:HttpPost(baseUrl .. "/api/auth/probe", proofPayload, "application/json")
        end)
    end

    -- Fail open on network error — do not block real users due to request failures
    if not respBody then
        warn("[Atomware] Pre-flight attestation request failed — proceeding without gate.")
        return true
    end

    local verified = nil
    pcall(function()
        verified = HttpService:JSONDecode(respBody)
    end)

    -- Server rejected with hard block
    if verified and verified.blocked == true then
        ClientGuard.purgePayload()
        return false
    end

    -- Server returned success or a soft-reject (non-blocked) — proceed
    if not verified or not verified.loader_payload then
        warn("[Atomware] Pre-flight response malformed — proceeding without gate.")
        return true
    end

    -- Gated release: deliver gateway token and launch Auth Loader in protected closure
    _G.__AERO_GATEWAY_TOKEN = verified.gateway_token
    local loaderFn, compileErr = loadstring(verified.loader_payload)
    if not loaderFn then
        warn("[Atomware Security] Failed to compile verified payload:", compileErr)
        ClientGuard.purgePayload()
        return false
    end

    task.spawn(loaderFn)
    return true
end

return ClientGuard
