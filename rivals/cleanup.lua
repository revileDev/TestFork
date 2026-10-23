--[[
    Atomware Rivals - cleanup.lua
    Central owner for runtime resources (connections, tasks, drawings, instances, hook restorers).
    Ensures safe, 100% leak-free unloading and reloading.
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Cleanup = {
    Connections = {},
    Tasks = {},
    Drawings = {},
    Instances = {},
    Restorers = {},
    Running = false,
    Ran = false,
}

function Cleanup:TrackConnection(connection)
    if not connection then return connection end
    if self.Running or self.Ran then
        pcall(function() connection:Disconnect() end)
    else
        table.insert(self.Connections, connection)
    end
    return connection
end

function Cleanup:TrackTask(thread)
    if not thread then return thread end
    if self.Running or self.Ran then
        pcall(task.cancel, thread)
    else
        table.insert(self.Tasks, thread)
    end
    return thread
end

function Cleanup:TrackDrawing(drawing)
    if not drawing then return drawing end
    if self.Running or self.Ran then
        pcall(function() drawing.Visible = false; drawing:Remove() end)
    else
        table.insert(self.Drawings, drawing)
    end
    return drawing
end

function Cleanup:TrackInstance(instance)
    if not instance then return instance end
    if self.Running or self.Ran then
        pcall(function() instance:Destroy() end)
    else
        table.insert(self.Instances, instance)
    end
    return instance
end

function Cleanup:TrackRestore(callback)
    if type(callback) ~= "function" then return end
    if self.Running or self.Ran then
        pcall(callback)
    else
        table.insert(self.Restorers, callback)
    end
end

local function disconnectAll(list)
    for _, connection in ipairs(list or {}) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(list or {})
end

local function cancelAll(list)
    for _, thread in ipairs(list or {}) do
        pcall(task.cancel, thread)
    end
    table.clear(list or {})
end

local function runCallbacks(list)
    for index = #(list or {}), 1, -1 do
        pcall(list[index])
    end
    table.clear(list or {})
end

function Cleanup:Run(config)
    if self.Running or self.Ran then return end
    self.Running = true

    -- 1. Stop every producer before restoring or removing its output.
    disconnectAll(self.Connections)
    cancelAll(self.Tasks)
    if config then
        disconnectAll(config.Connections)
        cancelAll(config.Tasks)
    end

    -- 2. Run cleanup callbacks and hook restorers
    if config then runCallbacks(config.Cleanup) end
    runCallbacks(self.Restorers)

    -- 3. Destroy tracked Instances
    for _, instance in ipairs(self.Instances) do
        pcall(function() instance:Destroy() end)
    end
    table.clear(self.Instances)

    -- 4. Destroy tracked Drawings
    for _, drawing in ipairs(self.Drawings) do
        pcall(function()
            drawing.Visible = false
            drawing:Remove()
        end)
    end
    table.clear(self.Drawings)

    self.Ran = true
    self.Running = false
end

-- Full universal teardown
function Cleanup:UnloadAll()
    if self.Running then return end

    -- Invoke features fullUnload if present
    local g = (getgenv and getgenv()) or _G
    if type(g) == "table" and type(g.__atomware_rivals_unload) == "function" then
        pcall(g.__atomware_rivals_unload)
        g.__atomware_rivals_unload = nil
    end

    -- Invoke _G.AtomwareUnload if present
    if type(_G.AtomwareUnload) == "function" then
        pcall(_G.AtomwareUnload)
    end

    -- Execute internal cleanup tracking
    self:Run(_G.AtomwareConfig)

    -- Purge known Guis
    local player = Players.LocalPlayer
    local playerGui = player and player:FindFirstChild("PlayerGui")
    local targets = {
        "AtomwareRivalsUI",
        "AtomwareMobileRivalsUI",
        "Atomware_ChatroomWidget",
        "Atomware_SearchWidget",
        "__sonata_kill_flash",
        "__atomware_mobile_toggle",
    }
    for _, name in ipairs(targets) do
        pcall(function()
            if playerGui then
                local found = playerGui:FindFirstChild(name)
                if found then found:Destroy() end
            end
            local cgFound = CoreGui:FindFirstChild(name)
            if cgFound then cgFound:Destroy() end
        end)
    end

    -- Purge workspace and sound folders
    for _, path in ipairs({
        { SoundService, "atomware_fx_sounds" },
        { SoundService, "atomware_ambience" },
        { Workspace, "atomware_tracers" },
        { Workspace, "atomware_weather" }
    }) do
        pcall(function()
            local inst = path[1]:FindFirstChild(path[2])
            if inst then inst:Destroy() end
        end)
    end

    -- Clear global state
    _G.AtomwareFeaturesLoaded = nil
    _G.AtomwareUILoaded = nil
    _G.AtomwareConfig = nil
    _G.AtomwareWindow = nil
    _G.AtomwareEvents = nil
    _G.OnToggle = nil
    _G.AtomwareChatroomLoaded = nil
    _G.AtomwareUnload = nil

    if type(g) == "table" then
        g.Sonata = nil
        g.__sonataOnshotDealt = nil
        g.__sonataDamageEffectHitV1 = nil
        g.__sonataOnshotHookV1 = nil
        g.__atomware_rivals_unload = nil
    end

    print("[Atomware Rivals] Full unload completed successfully.")
end

_G.AtomwareCleanup = Cleanup
return Cleanup
