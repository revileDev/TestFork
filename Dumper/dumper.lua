--[[
    ============================================================================
    RIVALS SKIN CHANGER & 3D WEAPON CATALOG (STANDALONE MODULE)
    ============================================================================
    Target Experience: Rivals (Roblox PlaceId: 17625359962)
    Execution Mode: Modular Singleton with High-Performance Glassmorphism GUI

    Features:
      1. Top Gun Selector Bar: Horizontal scrollable strip of all weapons with real thumbnails.
      2. 3D Weapon Model Preview: Real-time 360 orbital camera rendering cloned meshes in ViewportFrame.
      3. Dual Cosmetic Mode:
         - [SKINS]: Weapon-specific 3D model variants with real thumbnails (ItemLibrary.ViewModels).
         - [WRAPS]: Universal texture/palette wraps with dual-color swatches and material mapping.
      4. Persistent Per-Weapon Memory: Saves selected skin and wrap per weapon; turns emerald green.
      5. Instant Live Application:
         - Metamethod hooks on ClientViewModel.GetWrap and ClientViewModel.new.
         - Direct live update on FighterController.LocalFighter and workspace.ViewModels.FirstPerson.
      6. Dedicated Unlock All & Spoofer Section:
         - Unlock All Cosmetics (CosmeticLibrary.OwnsCosmetic proxy).
         - Unlock All Weapons (PlayerDataController:GetUnlockedWeapons spoofer).
         - Invert Wrap Palette option.
      7. Modern Glassmorphism GUI (980x620) with Draggable Header, Minimized Widget, and RightControl Hotkey.
    ============================================================================
--]]

local SkinChanger = {}
SkinChanger.__index = SkinChanger

-- Safe Environment API wrappers
local env_hookmetamethod = (typeof(hookmetamethod) == "function" and hookmetamethod) or nil
local env_hookfunction   = (typeof(hookfunction) == "function" and hookfunction) or nil
local env_getrawmetatable = (typeof(getrawmetatable) == "function" and getrawmetatable) or debug.getmetatable
local env_setreadonly     = (typeof(setreadonly) == "function" and setreadonly) or nil
local env_make_writeable  = (typeof(make_writeable) == "function" and make_writeable) or nil
local env_gethui          = (typeof(gethui) == "function" and gethui) or nil
local env_protect_gui     = (typeof(syn) == "table" and typeof(syn.protect_gui) == "function" and syn.protect_gui) or nil

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local CoreGui           = game:GetService("CoreGui")
local HttpService       = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- Target Parent for GUI
local function getGuiContainer()
    if env_gethui then
        local ok, hui = pcall(env_gethui)
        if ok and hui then return hui end
    end
    local okCore, cg = pcall(function() return CoreGui end)
    if okCore and cg then return cg end
    return LocalPlayer:WaitForChild("PlayerGui", 5) or CoreGui
end

-- ============================================================================
-- STATE & DATA STORE
-- ============================================================================
local State = {
    selectedGun = "Assault Rifle",
    mode = "Skins", -- "Skins" | "Wraps" | "UnlockAll"
    searchQuery = "",
    rarityFilter = "All",
    orbitPaused = false,
    orbitAngle = 0,
    orbitDistance = 4.2,
    uiVisible = true,
    minimized = false,
    unlockAll = true,
    unlockWeapons = true,
    invertPalette = false,
    -- Persistent configuration per weapon: [gunName] = { Skin = "...", Wrap = "...", Inverted = false }
    saved = {},
}

-- Default fallback weapons list
local DEFAULT_WEAPONS = {
    { Name = "Assault Rifle", Class = "Primary", Image = "rbxassetid://17160799881" },
    { Name = "Sniper", Class = "Primary", Image = "rbxassetid://17160799638" },
    { Name = "Shotgun", Class = "Primary", Image = "rbxassetid://17160799513" },
    { Name = "Burst Rifle", Class = "Primary", Image = "rbxassetid://17160800007" },
    { Name = "Minigun", Class = "Primary", Image = "rbxassetid://17160800747" },
    { Name = "Bow", Class = "Primary", Image = "rbxassetid://18223601855" },
    { Name = "Crossbow", Class = "Primary", Image = "rbxassetid://18223601855" },
    { Name = "Energy Rifle", Class = "Primary", Image = "rbxassetid://18223601855" },
    { Name = "Paintball Gun", Class = "Primary", Image = "rbxassetid://18223601855" },
    { Name = "RPG", Class = "Primary", Image = "rbxassetid://18223601855" },
    { Name = "Flamethrower", Class = "Primary", Image = "rbxassetid://89455038280473" },
    { Name = "Pistol", Class = "Secondary", Image = "rbxassetid://17160800994" },
    { Name = "Revolver", Class = "Secondary", Image = "rbxassetid://17160800880" },
    { Name = "Uzi", Class = "Secondary", Image = "rbxassetid://17160800624" },
    { Name = "Flare Gun", Class = "Secondary", Image = "rbxassetid://17160801264" },
    { Name = "Shorty", Class = "Secondary", Image = "rbxassetid://17160801380" },
    { Name = "Freeze Ray", Class = "Secondary", Image = "rbxassetid://18223601855" },
    { Name = "Energy Pistols", Class = "Secondary", Image = "rbxassetid://18223601855" },
    { Name = "Katana", Class = "Melee", Image = "rbxassetid://17160801158" },
    { Name = "Knife", Class = "Melee", Image = "rbxassetid://17160801041" },
    { Name = "Fists", Class = "Melee", Image = "rbxassetid://17672060486" },
    { Name = "Scythe", Class = "Melee", Image = "rbxassetid://18223601855" },
    { Name = "Battle Axe", Class = "Melee", Image = "rbxassetid://18223601855" },
    { Name = "Chainsaw", Class = "Melee", Image = "rbxassetid://18223601855" },
    { Name = "Daggers", Class = "Melee", Image = "rbxassetid://18223601855" },
    { Name = "Grenade", Class = "Utility", Image = "rbxassetid://17160801411" },
    { Name = "Flashbang", Class = "Utility", Image = "rbxassetid://17160801529" },
    { Name = "Smoke Grenade", Class = "Utility", Image = "rbxassetid://17160799767" },
    { Name = "Molotov", Class = "Utility", Image = "rbxassetid://109264750627289" },
    { Name = "Medkit", Class = "Utility", Image = "rbxassetid://17160800366" },
    { Name = "Subspace Tripmine", Class = "Utility", Image = "rbxassetid://17160799418" },
    { Name = "Jump Pad", Class = "Utility", Image = "rbxassetid://18223601855" },
}

-- Fallback wrap preset catalog
local FALLBACK_WRAPS = {
    { Name = "Community", Rarity = "Special", P = Color3.fromRGB(80, 200, 255), S = Color3.fromRGB(255, 255, 255), Mat = "Neon" },
    { Name = "Glacier", Rarity = "Rare", P = Color3.fromRGB(180, 230, 255), S = Color3.fromRGB(240, 250, 255), Mat = "Glass" },
    { Name = "Gold", Rarity = "Legendary", P = Color3.fromRGB(255, 215, 0), S = Color3.fromRGB(218, 165, 32), Mat = "Metal" },
    { Name = "Obsidian", Rarity = "Legendary", P = Color3.fromRGB(30, 30, 36), S = Color3.fromRGB(155, 89, 182), Mat = "SmoothPlastic" },
    { Name = "Brimstone", Rarity = "Epic", P = Color3.fromRGB(230, 75, 40), S = Color3.fromRGB(25, 25, 25), Mat = "Neon" },
    { Name = "Galaxy", Rarity = "Legendary", P = Color3.fromRGB(45, 15, 75), S = Color3.fromRGB(142, 68, 173), Mat = "ForceField" },
    { Name = "Sensite", Rarity = "Rare", P = Color3.fromRGB(46, 204, 113), S = Color3.fromRGB(52, 73, 94), Mat = "SmoothPlastic" },
    { Name = "Danger", Rarity = "Rare", P = Color3.fromRGB(231, 76, 60), S = Color3.fromRGB(241, 196, 15), Mat = "SmoothPlastic" },
    { Name = "Pine", Rarity = "Common", P = Color3.fromRGB(46, 117, 89), S = Color3.fromRGB(92, 64, 51), Mat = "Wood" },
    { Name = "1B Visits", Rarity = "Special", P = Color3.fromRGB(255, 105, 180), S = Color3.fromRGB(255, 255, 255), Mat = "Neon" },
    { Name = "Nosnite", Rarity = "Epic", P = Color3.fromRGB(52, 152, 219), S = Color3.fromRGB(44, 62, 80), Mat = "Metal" },
    { Name = "Glamour", Rarity = "Epic", P = Color3.fromRGB(255, 182, 193), S = Color3.fromRGB(255, 228, 225), Mat = "Glass" },
    { Name = "Cream", Rarity = "Common", P = Color3.fromRGB(255, 253, 208), S = Color3.fromRGB(245, 245, 220), Mat = "SmoothPlastic" },
    { Name = "Silver", Rarity = "Rare", P = Color3.fromRGB(192, 192, 192), S = Color3.fromRGB(220, 220, 220), Mat = "Metal" },
    { Name = "Bronze", Rarity = "Common", P = Color3.fromRGB(205, 127, 50), S = Color3.fromRGB(139, 69, 19), Mat = "Metal" },
    { Name = "Crimson", Rarity = "Rare", P = Color3.fromRGB(180, 20, 30), S = Color3.fromRGB(20, 20, 20), Mat = "Neon" },
    { Name = "Emerald", Rarity = "Epic", P = Color3.fromRGB(46, 204, 113), S = Color3.fromRGB(39, 174, 96), Mat = "Glass" },
    { Name = "Amethyst", Rarity = "Epic", P = Color3.fromRGB(155, 89, 182), S = Color3.fromRGB(142, 68, 173), Mat = "Glass" },
    { Name = "Cyberpunk", Rarity = "Legendary", P = Color3.fromRGB(255, 0, 128), S = Color3.fromRGB(0, 255, 255), Mat = "Neon" },
    { Name = "Matrix", Rarity = "Legendary", P = Color3.fromRGB(0, 255, 65), S = Color3.fromRGB(10, 20, 10), Mat = "Neon" },
    { Name = "Carbon Fiber", Rarity = "Rare", P = Color3.fromRGB(40, 40, 40), S = Color3.fromRGB(20, 20, 20), Mat = "DiamondPlate" },
    { Name = "Vaporwave", Rarity = "Epic", P = Color3.fromRGB(255, 113, 206), S = Color3.fromRGB(1, 205, 254), Mat = "Neon" },
    { Name = "Electric Blue", Rarity = "Rare", P = Color3.fromRGB(0, 102, 255), S = Color3.fromRGB(255, 255, 255), Mat = "Neon" },
    { Name = "Toxic Hazard", Rarity = "Rare", P = Color3.fromRGB(173, 255, 47), S = Color3.fromRGB(30, 30, 30), Mat = "Neon" },
}

local RARITY_COLORS = {
    Common = Color3.fromRGB(160, 170, 185),
    Rare = Color3.fromRGB(52, 152, 219),
    Epic = Color3.fromRGB(155, 89, 182),
    Legendary = Color3.fromRGB(241, 196, 15),
    Special = Color3.fromRGB(231, 76, 60),
    Mythic = Color3.fromRGB(255, 45, 120),
    Unique = Color3.fromRGB(255, 140, 0),
}

-- Ensure gun state table exists
local function getGunConfig(gunName)
    if not State.saved[gunName] then
        State.saved[gunName] = {
            Skin = "Default",
            Wrap = "None",
            Inverted = false,
        }
    end
    return State.saved[gunName]
end

-- ============================================================================
-- DYNAMIC INGESTION ENGINE
-- ============================================================================
local function getWeaponsList()
    local list = {}
    local seen = {}

    -- Try reading dynamically from ItemLibrary
    pcall(function()
        local Modules = ReplicatedStorage:FindFirstChild("Modules")
        local ItemLibModule = Modules and Modules:FindFirstChild("ItemLibrary")
        if ItemLibModule then
            local ItemLibrary = require(ItemLibModule)
            if ItemLibrary and ItemLibrary.ItemOrder then
                for _, weaponName in ipairs(ItemLibrary.ItemOrder) do
                    local itemInfo = ItemLibrary.Items and ItemLibrary.Items[weaponName]
                    local vmInfo = ItemLibrary.ViewModels and ItemLibrary.ViewModels[weaponName]
                    if itemInfo and not seen[weaponName] then
                        seen[weaponName] = true
                        table.insert(list, {
                            Name = weaponName,
                            Class = itemInfo.Class or "Weapon",
                            Image = (vmInfo and (vmInfo.ImageCentered or vmInfo.Image)) or (itemInfo and itemInfo.Image) or "",
                        })
                    end
                end
            end
        end
    end)

    if #list == 0 then
        -- Fallback to curated table
        for _, w in ipairs(DEFAULT_WEAPONS) do
            if not seen[w.Name] then
                seen[w.Name] = true
                table.insert(list, w)
            end
        end
    end

    return list
end

local function getSkinsForWeapon(weaponName)
    local skins = {}
    -- Always offer "Default" base weapon model as first option
    table.insert(skins, {
        Name = "Default",
        Rarity = "Common",
        Image = "",
        IsDefault = true,
    })

    local seen = { ["Default"] = true }

    -- Dynamic ingestion from CosmeticLibrary
    pcall(function()
        local Modules = ReplicatedStorage:FindFirstChild("Modules")
        local CosModule = Modules and Modules:FindFirstChild("CosmeticLibrary")
        local ItemLibModule = Modules and Modules:FindFirstChild("ItemLibrary")
        local ItemLibrary = ItemLibModule and require(ItemLibModule)
        if CosModule then
            local CosmeticLibrary = require(CosModule)
            if CosmeticLibrary and CosmeticLibrary.Cosmetics then
                for name, data in pairs(CosmeticLibrary.Cosmetics) do
                    if data.Type == "Skin" and data.ItemName == weaponName and not seen[name] then
                        seen[name] = true
                        local img = data.Image or ""
                        if (not img or img == "") and ItemLibrary and ItemLibrary.ViewModels and ItemLibrary.ViewModels[name] then
                            img = ItemLibrary.ViewModels[name].Image or ItemLibrary.ViewModels[name].ImageHighResolution or ""
                        end
                        table.insert(skins, {
                            Name = name,
                            Rarity = data.Rarity or "Common",
                            Image = img,
                            Description = data.Description or "",
                        })
                    end
                end
            end
        end
    end)

    -- If default weapon image is known, populate "Default" card image
    pcall(function()
        local Modules = ReplicatedStorage:FindFirstChild("Modules")
        local ItemLibModule = Modules and Modules:FindFirstChild("ItemLibrary")
        if ItemLibModule then
            local ItemLibrary = require(ItemLibModule)
            if ItemLibrary and ItemLibrary.ViewModels and ItemLibrary.ViewModels[weaponName] then
                skins[1].Image = ItemLibrary.ViewModels[weaponName].ImageCentered or ItemLibrary.ViewModels[weaponName].Image or ""
            end
        end
    end)

    return skins
end

local function getWrapsList()
    local wraps = {}
    -- First option: "None"
    table.insert(wraps, {
        Name = "None",
        Rarity = "Common",
        P = Color3.fromRGB(60, 65, 80),
        S = Color3.fromRGB(30, 35, 45),
        Mat = "Default",
    })

    local seen = { ["None"] = true }

    -- Dynamic ingestion from CosmeticLibrary
    pcall(function()
        local Modules = ReplicatedStorage:FindFirstChild("Modules")
        local CosModule = Modules and Modules:FindFirstChild("CosmeticLibrary")
        if CosModule then
            local CosmeticLibrary = require(CosModule)
            if CosmeticLibrary and CosmeticLibrary.Cosmetics then
                for name, data in pairs(CosmeticLibrary.Cosmetics) do
                    if data.Type == "Wrap" and not seen[name] then
                        seen[name] = true
                        local wg = data.WrapGroups or {}
                        local pCol = (wg[1] and wg[1].Color) or Color3.fromRGB(150, 150, 150)
                        local sCol = (wg[2] and wg[2].Color) or (wg[1] and wg[1].Color) or Color3.fromRGB(80, 80, 80)
                        local matName = (wg[1] and wg[1].Material and tostring(wg[1].Material.Name)) or "SmoothPlastic"
                        table.insert(wraps, {
                            Name = name,
                            Rarity = data.Rarity or "Common",
                            P = pCol,
                            S = sCol,
                            Mat = matName,
                        })
                    end
                end
            end
        end
    end)

    if #wraps <= 1 then
        for _, w in ipairs(FALLBACK_WRAPS) do
            if not seen[w.Name] then
                seen[w.Name] = true
                table.insert(wraps, w)
            end
        end
    end

    return wraps
end

-- ============================================================================
-- LIVE APPLICATION & METAMETHOD HOOKS
-- ============================================================================
local function hookClientViewModel()
    pcall(function()
        local scripts = LocalPlayer:FindFirstChild("PlayerScripts")
        local modules = scripts and scripts:FindFirstChild("Modules")
        local replicatedClasses = modules and modules:FindFirstChild("ClientReplicatedClasses")
        local fighterClass = replicatedClasses and replicatedClasses:FindFirstChild("ClientFighter")
        local itemClass = fighterClass and fighterClass:FindFirstChild("ClientItem")
        local vmClass = itemClass and itemClass:FindFirstChild("ClientViewModel")
        if not vmClass then return end

        local ClientViewModel = require(vmClass)
        if not (ClientViewModel and typeof(ClientViewModel.GetWrap) == "function") then return end

        if env_hookfunction then
            local oldGetWrap
            oldGetWrap = env_hookfunction(ClientViewModel.GetWrap, function(self)
                local weaponName = (self.ClientItem and self.ClientItem.Name) or self.Name
                local cfg = State.saved[weaponName]
                if cfg and cfg.Wrap and cfg.Wrap ~= "" and cfg.Wrap ~= "None" then
                    return {
                        Name = cfg.Wrap,
                        Inverted = (cfg.Inverted == true) or State.invertPalette,
                    }
                end
                return oldGetWrap(self)
            end)
        end
    end)
end

local function hookCosmeticLibrary()
    if not State.unlockAll then return end
    pcall(function()
        local Modules = ReplicatedStorage:FindFirstChild("Modules")
        local CosModule = Modules and Modules:FindFirstChild("CosmeticLibrary")
        if not CosModule then return end
        local CosmeticLibrary = require(CosModule)
        if not CosmeticLibrary then return end

        if env_hookfunction then
            env_hookfunction(CosmeticLibrary.OwnsCosmetic, function() return true end)
            if typeof(CosmeticLibrary.OwnsCosmeticNormally) == "function" then
                env_hookfunction(CosmeticLibrary.OwnsCosmeticNormally, function() return true end)
            end
            if typeof(CosmeticLibrary.OwnsCosmeticUniversally) == "function" then
                env_hookfunction(CosmeticLibrary.OwnsCosmeticUniversally, function() return true end)
            end
            if typeof(CosmeticLibrary.OwnsCosmeticForWeapon) == "function" then
                env_hookfunction(CosmeticLibrary.OwnsCosmeticForWeapon, function() return true end)
            end
        else
            CosmeticLibrary.OwnsCosmetic = function() return true end
            CosmeticLibrary.OwnsCosmeticNormally = function() return true end
            CosmeticLibrary.OwnsCosmeticUniversally = function() return true end
            CosmeticLibrary.OwnsCosmeticForWeapon = function() return true end
        end
    end)

    if State.unlockWeapons then
        pcall(function()
            local scripts = LocalPlayer:FindFirstChild("PlayerScripts")
            local controllers = scripts and scripts:FindFirstChild("Controllers")
            local pdc = controllers and controllers:FindFirstChild("PlayerDataController")
            if pdc then
                local PlayerDataController = require(pdc)
                if PlayerDataController and typeof(PlayerDataController.GetUnlockedWeapons) == "function" then
                    if env_hookfunction then
                        env_hookfunction(PlayerDataController.GetUnlockedWeapons, function()
                            local unlocked = {}
                            for _, w in ipairs(getWeaponsList()) do
                                unlocked[w.Name] = true
                            end
                            return unlocked
                        end)
                    end
                end
            end
        end)
    end
end

-- Force live visual change on active player model
function SkinChanger.applySkinLive(targetGun)
    local gun = targetGun or State.selectedGun
    local cfg = getGunConfig(gun)
    local selectedSkin = cfg.Skin
    local selectedWrap = cfg.Wrap
    local inverted = cfg.Inverted or State.invertPalette

    -- 1. Apply through FighterController.LocalFighter items
    pcall(function()
        local scripts = LocalPlayer:FindFirstChild("PlayerScripts")
        local controllers = scripts and scripts:FindFirstChild("Controllers")
        local fc = controllers and controllers:FindFirstChild("FighterController")
        if not fc then return end
        local FighterController = require(fc)
        local fighter = FighterController.LocalFighter or (typeof(FighterController.GetFighter) == "function" and FighterController:GetFighter(LocalPlayer))
        if fighter and fighter.Items then
            for _, item in pairs(fighter.Items) do
                if item.Name == gun or not targetGun then
                    local vm = item.ViewModel
                    if vm then
                        -- Check if skin model needs to be swapped
                        if selectedSkin and selectedSkin ~= "Default" and selectedSkin ~= "" then
                            pcall(function()
                                local ViewModels3 = scripts.Assets.ViewModels
                                local Modules = ReplicatedStorage:FindFirstChild("Modules")
                                local Utility = Modules and require(Modules:FindFirstChild("Utility"))
                                local newModel = Utility and Utility:LookThrough(ViewModels3, selectedSkin)
                                if not newModel then
                                    newModel = ViewModels3:FindFirstChild(selectedSkin, true)
                                end
                                if newModel and vm.ItemModel then
                                    vm.ItemModel:Destroy()
                                    local clone = newModel:Clone()
                                    clone.Name = "ItemVisual"
                                    clone.Parent = vm.Model
                                    vm.ItemModel = clone
                                    if typeof(vm._Setup) == "function" then
                                        vm:_Setup()
                                    end
                                end
                            end)
                        end
                        -- Trigger wrap update
                        if typeof(vm._UpdateWrap) == "function" then
                            vm:_UpdateWrap()
                        end
                    end
                end
            end
        end
    end)

    -- 2. Apply directly to workspace.ViewModels.FirstPerson models
    pcall(function()
        local fp = workspace:FindFirstChild("ViewModels") and workspace.ViewModels:FindFirstChild("FirstPerson")
        if fp and selectedWrap and selectedWrap ~= "" and selectedWrap ~= "None" then
            local scripts = LocalPlayer:FindFirstChild("PlayerScripts")
            local controllers = scripts and scripts:FindFirstChild("Controllers")
            local wc = controllers and controllers:FindFirstChild("WrapController")
            if wc then
                local WrapController = require(wc)
                for _, model in pairs(fp:GetChildren()) do
                    local orig = WrapController:RecordOriginalWrapProperties(model)
                    WrapController:ApplyWrap(orig, { Name = selectedWrap, Inverted = inverted })
                end
            end
        end
    end)
end

-- ============================================================================
-- GUI GENERATOR & CONTROLLER
-- ============================================================================
local UI = {
    screenGui = nil,
    mainFrame = nil,
    viewportFrame = nil,
    previewCamera = nil,
    previewModel = nil,
    gunCards = {},
    catalogCards = {},
    topGunScroll = nil,
    gridScroll = nil,
    headerStatus = nil,
    activeInfoLabel = nil,
    miniPill = nil,
}

local function clearGrid()
    for _, card in pairs(UI.catalogCards) do
        pcall(function() card:Destroy() end)
    end
    table.clear(UI.catalogCards)
end

-- Updates the 3D ViewportFrame preview model
local function updatePreviewModel()
    if not UI.viewportFrame then return end

    if UI.previewModel then
        UI.previewModel:Destroy()
        UI.previewModel = nil
    end

    local gun = State.selectedGun
    local cfg = getGunConfig(gun)
    local skinToLoad = (cfg.Skin and cfg.Skin ~= "Default" and cfg.Skin ~= "") and cfg.Skin or gun

    pcall(function()
        local scripts = LocalPlayer:FindFirstChild("PlayerScripts")
        local ViewModels3 = scripts and scripts.Assets and scripts.Assets:FindFirstChild("ViewModels")
        local targetModel = nil

        if ViewModels3 then
            targetModel = ViewModels3:FindFirstChild(skinToLoad, true)
            if not targetModel and skinToLoad ~= gun then
                targetModel = ViewModels3:FindFirstChild(gun, true)
            end
        end

        if targetModel then
            local clone = targetModel:Clone()
            clone.Parent = UI.viewportFrame
            UI.previewModel = clone

            -- Center and pivot
            local cf, sz = clone:GetBoundingBox()
            State.orbitDistance = math.clamp(sz.Magnitude * 1.35, 2.5, 7.5)

            -- Apply wrap to preview model
            if cfg.Wrap and cfg.Wrap ~= "" and cfg.Wrap ~= "None" then
                local wc = scripts.Controllers:FindFirstChild("WrapController")
                if wc then
                    local WrapController = require(wc)
                    local orig = WrapController:RecordOriginalWrapProperties(clone)
                    WrapController:ApplyWrap(orig, { Name = cfg.Wrap, Inverted = cfg.Inverted or State.invertPalette })
                end
            end
        end
    end)

    if UI.activeInfoLabel then
        UI.activeInfoLabel.Text = string.format("GUN: %s\nSKIN: %s\nWRAP: %s", gun, cfg.Skin or "Default", cfg.Wrap or "None")
    end
    if UI.headerStatus then
        UI.headerStatus.Text = string.format("[%s]  |  Skin: %s  |  Wrap: %s", gun, cfg.Skin or "Default", cfg.Wrap or "None")
    end
end

-- Refresh the top gun selector bar highlighting
local function refreshGunSelectorHighlights()
    for gunName, card in pairs(UI.gunCards) do
        local isSelected = (gunName == State.selectedGun)
        local stroke = card:FindFirstChild("UIStroke")
        local bar = card:FindFirstChild("SelectionBar")
        if stroke then
            stroke.Color = isSelected and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(45, 52, 70)
            stroke.Thickness = isSelected and 2 or 1
        end
        if bar then
            bar.Visible = isSelected
        end
        card.BackgroundColor3 = isSelected and Color3.fromRGB(24, 38, 30) or Color3.fromRGB(20, 24, 34)
    end
end

-- Refresh the Catalog Grid (Skins or Wraps)
local function renderCatalogGrid()
    clearGrid()
    if not UI.gridScroll then return end

    local gun = State.selectedGun
    local cfg = getGunConfig(gun)

    if State.mode == "Skins" then
        local skins = getSkinsForWeapon(gun)
        for _, s in ipairs(skins) do
            local searchMatch = (State.searchQuery == "" or string.find(string.lower(s.Name), string.lower(State.searchQuery), 1, true))
            local rarityMatch = (State.rarityFilter == "All" or s.Rarity == State.rarityFilter)
            if searchMatch and rarityMatch then
                local isEquipped = (cfg.Skin == s.Name) or (s.Name == "Default" and (cfg.Skin == nil or cfg.Skin == "Default" or cfg.Skin == ""))

                local card = Instance.new("TextButton")
                card.Name = "Skin_" .. s.Name
                card.Size = UDim2.new(0, 134, 0, 150)
                card.BackgroundColor3 = isEquipped and Color3.fromRGB(20, 48, 32) or Color3.fromRGB(22, 26, 36)
                card.AutoButtonColor = false
                card.Text = ""
                card.Parent = UI.gridScroll

                local cCorner = Instance.new("UICorner")
                cCorner.CornerRadius = UDim.new(0, 8)
                cCorner.Parent = card

                local cStroke = Instance.new("UIStroke")
                cStroke.Color = isEquipped and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(42, 48, 65)
                cStroke.Thickness = isEquipped and 2 or 1
                cStroke.Parent = card

                -- Thumbnail Image Label (Actual 3D render image model)
                local imgLabel = Instance.new("ImageLabel")
                imgLabel.Size = UDim2.new(1, -12, 0, 85)
                imgLabel.Position = UDim2.new(0, 6, 0, 8)
                imgLabel.BackgroundColor3 = Color3.fromRGB(14, 16, 24)
                imgLabel.BackgroundTransparency = 0.3
                imgLabel.ScaleType = Enum.ScaleType.Fit
                imgLabel.Image = (s.Image and s.Image ~= "") and s.Image or "rbxassetid://124519084257039"
                imgLabel.Parent = card

                local imgCorner = Instance.new("UICorner")
                imgCorner.CornerRadius = UDim.new(0, 6)
                imgCorner.Parent = imgLabel

                -- Rarity Badge
                local rColor = RARITY_COLORS[s.Rarity] or Color3.fromRGB(150, 150, 150)
                local rBadge = Instance.new("TextLabel")
                rBadge.Size = UDim2.new(1, -12, 0, 14)
                rBadge.Position = UDim2.new(0, 6, 0, 97)
                rBadge.BackgroundTransparency = 1
                rBadge.Font = Enum.Font.GothamBold
                rBadge.Text = string.upper(s.Rarity)
                rBadge.TextColor3 = rColor
                rBadge.TextSize = 9
                rBadge.TextXAlignment = Enum.TextXAlignment.Left
                rBadge.Parent = card

                -- Skin Name Label
                local nameLabel = Instance.new("TextLabel")
                nameLabel.Size = UDim2.new(1, -12, 0, 18)
                nameLabel.Position = UDim2.new(0, 6, 0, 111)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Font = Enum.Font.GothamMedium
                nameLabel.Text = s.Name
                nameLabel.TextColor3 = isEquipped and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(240, 245, 255)
                nameLabel.TextSize = 11
                nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.Parent = card

                -- Status Badge (Equipped / Select)
                local statusLabel = Instance.new("TextLabel")
                statusLabel.Size = UDim2.new(1, -12, 0, 14)
                statusLabel.Position = UDim2.new(0, 6, 0, 130)
                statusLabel.BackgroundTransparency = 1
                statusLabel.Font = Enum.Font.GothamBold
                statusLabel.Text = isEquipped and "✓ EQUIPPED" or "SELECT"
                statusLabel.TextColor3 = isEquipped and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(100, 110, 130)
                statusLabel.TextSize = 9
                statusLabel.TextXAlignment = Enum.TextXAlignment.Right
                statusLabel.Parent = card

                -- Click Handler: Turn emerald green, save per gun, and apply live
                card.MouseButton1Click:Connect(function()
                    cfg.Skin = s.Name
                    SkinChanger.applySkinLive(gun)
                    updatePreviewModel()
                    renderCatalogGrid()
                end)

                table.insert(UI.catalogCards, card)
            end
        end

    elseif State.mode == "Wraps" then
        local wraps = getWrapsList()
        for _, w in ipairs(wraps) do
            local searchMatch = (State.searchQuery == "" or string.find(string.lower(w.Name), string.lower(State.searchQuery), 1, true))
            local rarityMatch = (State.rarityFilter == "All" or w.Rarity == State.rarityFilter)
            if searchMatch and rarityMatch then
                local isEquipped = (cfg.Wrap == w.Name) or (w.Name == "None" and (cfg.Wrap == nil or cfg.Wrap == "None" or cfg.Wrap == ""))

                local card = Instance.new("TextButton")
                card.Name = "Wrap_" .. w.Name
                card.Size = UDim2.new(0, 134, 0, 150)
                card.BackgroundColor3 = isEquipped and Color3.fromRGB(20, 48, 32) or Color3.fromRGB(22, 26, 36)
                card.AutoButtonColor = false
                card.Text = ""
                card.Parent = UI.gridScroll

                local cCorner = Instance.new("UICorner")
                cCorner.CornerRadius = UDim.new(0, 8)
                cCorner.Parent = card

                local cStroke = Instance.new("UIStroke")
                cStroke.Color = isEquipped and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(42, 48, 65)
                cStroke.Thickness = isEquipped and 2 or 1
                cStroke.Parent = card

                -- Dual Color Swatch Box
                local swatchBox = Instance.new("Frame")
                swatchBox.Size = UDim2.new(1, -12, 0, 85)
                swatchBox.Position = UDim2.new(0, 6, 0, 8)
                swatchBox.BackgroundColor3 = Color3.fromRGB(15, 17, 24)
                swatchBox.ClipsDescendants = true
                swatchBox.Parent = card

                local sCorner = Instance.new("UICorner")
                sCorner.CornerRadius = UDim.new(0, 6)
                sCorner.Parent = swatchBox

                local primarySwatch = Instance.new("Frame")
                primarySwatch.Size = UDim2.new(0.65, 0, 1, 0)
                primarySwatch.Position = UDim2.new(0, 0, 0, 0)
                primarySwatch.BackgroundColor3 = w.P or Color3.fromRGB(80, 80, 80)
                primarySwatch.BorderSizePixel = 0
                primarySwatch.Parent = swatchBox

                local secondarySwatch = Instance.new("Frame")
                secondarySwatch.Size = UDim2.new(0.35, 0, 1, 0)
                secondarySwatch.Position = UDim2.new(0.65, 0, 0, 0)
                secondarySwatch.BackgroundColor3 = w.S or Color3.fromRGB(40, 40, 40)
                secondarySwatch.BorderSizePixel = 0
                secondarySwatch.Parent = swatchBox

                -- Material tag
                local matTag = Instance.new("TextLabel")
                matTag.Size = UDim2.new(1, -8, 0, 16)
                matTag.Position = UDim2.new(0, 4, 1, -20)
                matTag.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                matTag.BackgroundTransparency = 0.5
                matTag.Font = Enum.Font.GothamMedium
                matTag.Text = w.Mat or "Plastic"
                matTag.TextColor3 = Color3.fromRGB(240, 240, 240)
                matTag.TextSize = 8
                matTag.Parent = swatchBox

                local mCorner = Instance.new("UICorner")
                mCorner.CornerRadius = UDim.new(0, 4)
                mCorner.Parent = matTag

                -- Rarity Badge
                local rColor = RARITY_COLORS[w.Rarity] or Color3.fromRGB(150, 150, 150)
                local rBadge = Instance.new("TextLabel")
                rBadge.Size = UDim2.new(1, -12, 0, 14)
                rBadge.Position = UDim2.new(0, 6, 0, 97)
                rBadge.BackgroundTransparency = 1
                rBadge.Font = Enum.Font.GothamBold
                rBadge.Text = string.upper(w.Rarity)
                rBadge.TextColor3 = rColor
                rBadge.TextSize = 9
                rBadge.TextXAlignment = Enum.TextXAlignment.Left
                rBadge.Parent = card

                -- Wrap Name Label
                local nameLabel = Instance.new("TextLabel")
                nameLabel.Size = UDim2.new(1, -12, 0, 18)
                nameLabel.Position = UDim2.new(0, 6, 0, 111)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Font = Enum.Font.GothamMedium
                nameLabel.Text = w.Name
                nameLabel.TextColor3 = isEquipped and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(240, 245, 255)
                nameLabel.TextSize = 11
                nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.Parent = card

                -- Status Badge
                local statusLabel = Instance.new("TextLabel")
                statusLabel.Size = UDim2.new(1, -12, 0, 14)
                statusLabel.Position = UDim2.new(0, 6, 0, 130)
                statusLabel.BackgroundTransparency = 1
                statusLabel.Font = Enum.Font.GothamBold
                statusLabel.Text = isEquipped and "✓ EQUIPPED" or "APPLY"
                statusLabel.TextColor3 = isEquipped and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(100, 110, 130)
                statusLabel.TextSize = 9
                statusLabel.TextXAlignment = Enum.TextXAlignment.Right
                statusLabel.Parent = card

                -- Click Handler
                card.MouseButton1Click:Connect(function()
                    cfg.Wrap = w.Name
                    SkinChanger.applySkinLive(gun)
                    updatePreviewModel()
                    renderCatalogGrid()
                end)

                table.insert(UI.catalogCards, card)
            end
        end

    elseif State.mode == "UnlockAll" then
        -- Dedicated Unlock All & Spoofer Panel inside grid area
        local panel = Instance.new("Frame")
        panel.Size = UDim2.new(1, -16, 0, 360)
        panel.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
        panel.Parent = UI.gridScroll

        local pCorner = Instance.new("UICorner")
        pCorner.CornerRadius = UDim.new(0, 10)
        pCorner.Parent = panel

        local pStroke = Instance.new("UIStroke")
        pStroke.Color = Color3.fromRGB(45, 52, 70)
        pStroke.Parent = panel

        local pTitle = Instance.new("TextLabel")
        pTitle.Size = UDim2.new(1, -24, 0, 30)
        pTitle.Position = UDim2.new(0, 16, 0, 14)
        pTitle.BackgroundTransparency = 1
        pTitle.Font = Enum.Font.GothamBold
        pTitle.Text = "COSMETIC & WEAPON SPOOFER SETTINGS"
        pTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
        pTitle.TextSize = 14
        pTitle.TextXAlignment = Enum.TextXAlignment.Left
        pTitle.Parent = panel

        local function makeToggle(label, initialVal, yPos, callback)
            local tRow = Instance.new("Frame")
            tRow.Size = UDim2.new(1, -32, 0, 48)
            tRow.Position = UDim2.new(0, 16, 0, yPos)
            tRow.BackgroundColor3 = Color3.fromRGB(26, 31, 44)
            tRow.Parent = panel

            local rCorner = Instance.new("UICorner")
            rCorner.CornerRadius = UDim.new(0, 6)
            rCorner.Parent = tRow

            local rLabel = Instance.new("TextLabel")
            rLabel.Size = UDim2.new(0.7, 0, 1, 0)
            rLabel.Position = UDim2.new(0, 14, 0, 0)
            rLabel.BackgroundTransparency = 1
            rLabel.Font = Enum.Font.GothamMedium
            rLabel.Text = label
            rLabel.TextColor3 = Color3.fromRGB(220, 230, 245)
            rLabel.TextSize = 12
            rLabel.TextXAlignment = Enum.TextXAlignment.Left
            rLabel.Parent = tRow

            local tBtn = Instance.new("TextButton")
            tBtn.Size = UDim2.new(0, 90, 0, 30)
            tBtn.Position = UDim2.new(1, -104, 0.5, -15)
            tBtn.BackgroundColor3 = initialVal and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(50, 56, 74)
            tBtn.Font = Enum.Font.GothamBold
            tBtn.Text = initialVal and "ENABLED" or "DISABLED"
            tBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            tBtn.TextSize = 10
            tBtn.Parent = tRow

            local bCorner = Instance.new("UICorner")
            bCorner.CornerRadius = UDim.new(0, 6)
            bCorner.Parent = tBtn

            tBtn.MouseButton1Click:Connect(function()
                local newVal = not (tBtn.Text == "ENABLED")
                tBtn.Text = newVal and "ENABLED" or "DISABLED"
                tBtn.BackgroundColor3 = newVal and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(50, 56, 74)
                callback(newVal)
            end)
        end

        makeToggle("Unlock All Cosmetics (Wraps, Charms, Finishers)", State.unlockAll, 55, function(v)
            State.unlockAll = v
            hookCosmeticLibrary()
        end)

        makeToggle("Unlock All Weapons (Inventory Spoofer)", State.unlockWeapons, 115, function(v)
            State.unlockWeapons = v
            hookCosmeticLibrary()
        end)

        makeToggle("Invert Wrap Palette (Swap Colors 1 & 2)", State.invertPalette, 175, function(v)
            State.invertPalette = v
            SkinChanger.applySkinLive(gun)
            updatePreviewModel()
        end)

        -- Action buttons: Reset current gun, Reset all
        local resetGunBtn = Instance.new("TextButton")
        resetGunBtn.Size = UDim2.new(0.48, 0, 0, 42)
        resetGunBtn.Position = UDim2.new(0, 16, 0, 245)
        resetGunBtn.BackgroundColor3 = Color3.fromRGB(45, 52, 70)
        resetGunBtn.Font = Enum.Font.GothamBold
        resetGunBtn.Text = "RESET THIS WEAPON"
        resetGunBtn.TextColor3 = Color3.fromRGB(240, 245, 255)
        resetGunBtn.TextSize = 11
        resetGunBtn.Parent = panel

        local rgCorner = Instance.new("UICorner")
        rgCorner.CornerRadius = UDim.new(0, 6)
        rgCorner.Parent = resetGunBtn

        resetGunBtn.MouseButton1Click:Connect(function()
            State.saved[gun] = { Skin = "Default", Wrap = "None", Inverted = false }
            SkinChanger.applySkinLive(gun)
            updatePreviewModel()
            renderCatalogGrid()
        end)

        local resetAllBtn = Instance.new("TextButton")
        resetAllBtn.Size = UDim2.new(0.48, 0, 0, 42)
        resetAllBtn.Position = UDim2.new(0.52, -8, 0, 245)
        resetAllBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        resetAllBtn.Font = Enum.Font.GothamBold
        resetAllBtn.Text = "RESET ALL WEAPONS"
        resetAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        resetAllBtn.TextSize = 11
        resetAllBtn.Parent = panel

        local raCorner = Instance.new("UICorner")
        raCorner.CornerRadius = UDim.new(0, 6)
        raCorner.Parent = resetAllBtn

        resetAllBtn.MouseButton1Click:Connect(function()
            table.clear(State.saved)
            SkinChanger.applySkinLive(gun)
            updatePreviewModel()
            renderCatalogGrid()
        end)

        table.insert(UI.catalogCards, panel)
    end
end

-- ============================================================================
-- MAIN GUI CREATION
-- ============================================================================
function SkinChanger.createGui()
    if UI.screenGui then
        UI.screenGui:Destroy()
    end

    local parent = getGuiContainer()

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RivalsSkinChanger_" .. HttpService:GenerateGUID(false):sub(1, 8)
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999
    if env_protect_gui then env_protect_gui(screenGui) end
    screenGui.Parent = parent
    UI.screenGui = screenGui

    -- Main Window Frame: 980 x 620
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainWindow"
    mainFrame.Size = UDim2.new(0, 980, 0, 620)
    mainFrame.Position = UDim2.new(0.5, -490, 0.5, -310)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 17, 24)
    mainFrame.ClipsDescendants = true
    mainFrame.Active = true
    mainFrame.Parent = screenGui
    UI.mainFrame = mainFrame

    local mCorner = Instance.new("UICorner")
    mCorner.CornerRadius = UDim.new(0, 10)
    mCorner.Parent = mainFrame

    local mStroke = Instance.new("UIStroke")
    mStroke.Color = Color3.fromRGB(38, 44, 62)
    mStroke.Thickness = 1.5
    mStroke.Parent = mainFrame

    -- Dragging Logic
    local isDragging, dragStart, startPos = false, nil, nil
    local headerBar = Instance.new("Frame")
    headerBar.Name = "HeaderBar"
    headerBar.Size = UDim2.new(1, 0, 0, 52)
    headerBar.BackgroundColor3 = Color3.fromRGB(20, 23, 33)
    headerBar.BorderSizePixel = 0
    headerBar.Parent = mainFrame

    headerBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    isDragging = false
                end
            end)
        end
    end)

    headerBar.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Header Title & Subtitle
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0, 320, 0, 24)
    titleLabel.Position = UDim2.new(0, 16, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = "RIVALS SKIN CHANGER // CLIENT MOD"
    titleLabel.TextColor3 = Color3.fromRGB(245, 248, 255)
    titleLabel.TextSize = 13
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = headerBar

    local headerStatus = Instance.new("TextLabel")
    headerStatus.Size = UDim2.new(0, 400, 0, 16)
    headerStatus.Position = UDim2.new(0, 16, 0, 30)
    headerStatus.BackgroundTransparency = 1
    headerStatus.Font = Enum.Font.GothamMedium
    headerStatus.Text = "[Assault Rifle]  |  Skin: Default  |  Wrap: None"
    headerStatus.TextColor3 = Color3.fromRGB(46, 204, 113)
    headerStatus.TextSize = 10
    headerStatus.TextXAlignment = Enum.TextXAlignment.Left
    headerStatus.Parent = headerBar
    UI.headerStatus = headerStatus

    -- Controls in Header (Mode switchers & Window Buttons)
    local headerControls = Instance.new("Frame")
    headerControls.Size = UDim2.new(0, 480, 1, 0)
    headerControls.Position = UDim2.new(1, -490, 0, 0)
    headerControls.BackgroundTransparency = 1
    headerControls.Parent = headerBar

    local function makeHeaderPill(name, text, xPos, width, onClick)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(0, width, 0, 32)
        btn.Position = UDim2.new(0, xPos, 0.5, -16)
        btn.BackgroundColor3 = Color3.fromRGB(28, 33, 47)
        btn.Font = Enum.Font.GothamBold
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(220, 230, 245)
        btn.TextSize = 11
        btn.Parent = headerControls

        local bCorner = Instance.new("UICorner")
        bCorner.CornerRadius = UDim.new(0, 6)
        bCorner.Parent = btn

        local bStroke = Instance.new("UIStroke")
        bStroke.Color = Color3.fromRGB(45, 52, 70)
        bStroke.Parent = btn

        btn.MouseButton1Click:Connect(onClick)
        return btn
    end

    local skinsBtn = makeHeaderPill("ModeSkins", "🎭 SKINS", 0, 85, function()
        State.mode = "Skins"
        renderCatalogGrid()
    end)

    local wrapsBtn = makeHeaderPill("ModeWraps", "🎨 WRAPS", 95, 85, function()
        State.mode = "Wraps"
        renderCatalogGrid()
    end)

    local unlockBtn = makeHeaderPill("ModeUnlock", "🔓 UNLOCK ALL", 190, 105, function()
        State.mode = "UnlockAll"
        renderCatalogGrid()
    end)

    local liveApplyBtn = makeHeaderPill("LiveApply", "✨ APPLY NOW", 305, 95, function()
        SkinChanger.applySkinLive(State.selectedGun)
        updatePreviewModel()
    end)

    -- Window control buttons (Minimize & Close)
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 28, 0, 28)
    minBtn.Position = UDim2.new(1, -66, 0.5, -14)
    minBtn.BackgroundColor3 = Color3.fromRGB(28, 33, 47)
    minBtn.Font = Enum.Font.GothamBold
    minBtn.Text = "—"
    minBtn.TextColor3 = Color3.fromRGB(200, 210, 230)
    minBtn.TextSize = 13
    minBtn.Parent = headerControls

    local mnCorner = Instance.new("UICorner")
    mnCorner.CornerRadius = UDim.new(0, 6)
    mnCorner.Parent = minBtn

    minBtn.MouseButton1Click:Connect(function()
        SkinChanger.minimize()
    end)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -32, 0.5, -14)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 12
    closeBtn.Parent = headerControls

    local clCorner = Instance.new("UICorner")
    clCorner.CornerRadius = UDim.new(0, 6)
    clCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        SkinChanger.close()
    end)

    -- ========================================================================
    -- TOP GUN SELECTOR STRIP (HORIZONTAL SCROLLING)
    -- ========================================================================
    local gunStripContainer = Instance.new("Frame")
    gunStripContainer.Name = "GunStripContainer"
    gunStripContainer.Size = UDim2.new(1, 0, 0, 84)
    gunStripContainer.Position = UDim2.new(0, 0, 0, 54)
    gunStripContainer.BackgroundColor3 = Color3.fromRGB(17, 20, 29)
    gunStripContainer.BorderSizePixel = 0
    gunStripContainer.Parent = mainFrame

    local topGunScroll = Instance.new("ScrollingFrame")
    topGunScroll.Size = UDim2.new(1, -20, 1, -12)
    topGunScroll.Position = UDim2.new(0, 10, 0, 6)
    topGunScroll.BackgroundTransparency = 1
    topGunScroll.ScrollBarThickness = 4
    topGunScroll.ScrollBarImageColor3 = Color3.fromRGB(50, 60, 85)
    topGunScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    topGunScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
    topGunScroll.ScrollingDirection = Enum.ScrollingDirection.Horizontal
    topGunScroll.Parent = gunStripContainer
    UI.topGunScroll = topGunScroll

    local gunListLayout = Instance.new("UIListLayout")
    gunListLayout.FillDirection = Enum.FillDirection.Horizontal
    gunListLayout.Padding = UDim.new(0, 8)
    gunListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gunListLayout.Parent = topGunScroll

    -- Populate gun selector cards
    local weapons = getWeaponsList()
    for idx, w in ipairs(weapons) do
        local gCard = Instance.new("TextButton")
        gCard.Name = "Gun_" .. w.Name
        gCard.Size = UDim2.new(0, 110, 1, 0)
        gCard.BackgroundColor3 = (w.Name == State.selectedGun) and Color3.fromRGB(24, 38, 30) or Color3.fromRGB(20, 24, 34)
        gCard.AutoButtonColor = false
        gCard.Text = ""
        gCard.LayoutOrder = idx
        gCard.Parent = topGunScroll

        local gcCorner = Instance.new("UICorner")
        gcCorner.CornerRadius = UDim.new(0, 6)
        gcCorner.Parent = gCard

        local gcStroke = Instance.new("UIStroke")
        gcStroke.Color = (w.Name == State.selectedGun) and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(45, 52, 70)
        gcStroke.Thickness = (w.Name == State.selectedGun) and 2 or 1
        gcStroke.Parent = gCard

        local gIcon = Instance.new("ImageLabel")
        gIcon.Size = UDim2.new(1, -8, 0, 40)
        gIcon.Position = UDim2.new(0, 4, 0, 4)
        gIcon.BackgroundTransparency = 1
        gIcon.ScaleType = Enum.ScaleType.Fit
        gIcon.Image = (w.Image and w.Image ~= "") and w.Image or "rbxassetid://124519084257039"
        gIcon.Parent = gCard

        local gName = Instance.new("TextLabel")
        gName.Size = UDim2.new(1, -6, 0, 14)
        gName.Position = UDim2.new(0, 3, 0, 46)
        gName.BackgroundTransparency = 1
        gName.Font = Enum.Font.GothamMedium
        gName.Text = w.Name
        gName.TextColor3 = Color3.fromRGB(240, 245, 255)
        gName.TextSize = 10
        gName.TextTruncate = Enum.TextTruncate.AtEnd
        gName.Parent = gCard

        local gClass = Instance.new("TextLabel")
        gClass.Size = UDim2.new(1, -6, 0, 10)
        gClass.Position = UDim2.new(0, 3, 0, 60)
        gClass.BackgroundTransparency = 1
        gClass.Font = Enum.Font.Gotham
        gClass.Text = string.upper(w.Class)
        gClass.TextColor3 = Color3.fromRGB(120, 135, 160)
        gClass.TextSize = 8
        gClass.Parent = gCard

        local selBar = Instance.new("Frame")
        selBar.Name = "SelectionBar"
        selBar.Size = UDim2.new(1, 0, 0, 3)
        selBar.Position = UDim2.new(0, 0, 1, -3)
        selBar.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        selBar.BorderSizePixel = 0
        selBar.Visible = (w.Name == State.selectedGun)
        selBar.Parent = gCard

        gCard.MouseButton1Click:Connect(function()
            State.selectedGun = w.Name
            refreshGunSelectorHighlights()
            updatePreviewModel()
            renderCatalogGrid()
        end)

        UI.gunCards[w.Name] = gCard
    end

    -- ========================================================================
    -- BODY AREA: 3D PREVIEW (LEFT) + CATALOG GRID (RIGHT)
    -- ========================================================================
    local bodyFrame = Instance.new("Frame")
    bodyFrame.Name = "BodyFrame"
    bodyFrame.Size = UDim2.new(1, -24, 1, -150)
    bodyFrame.Position = UDim2.new(0, 12, 0, 144)
    bodyFrame.BackgroundTransparency = 1
    bodyFrame.Parent = mainFrame

    -- LEFT PANEL: 3D VIEWPORT FRAME
    local leftPanel = Instance.new("Frame")
    leftPanel.Name = "LeftPanel"
    leftPanel.Size = UDim2.new(0, 340, 1, 0)
    leftPanel.Position = UDim2.new(0, 0, 0, 0)
    leftPanel.BackgroundColor3 = Color3.fromRGB(18, 22, 31)
    leftPanel.Parent = bodyFrame

    local lpCorner = Instance.new("UICorner")
    lpCorner.CornerRadius = UDim.new(0, 8)
    lpCorner.Parent = leftPanel

    local lpStroke = Instance.new("UIStroke")
    lpStroke.Color = Color3.fromRGB(38, 44, 62)
    lpStroke.Parent = leftPanel

    -- ViewportFrame
    local viewport = Instance.new("ViewportFrame")
    viewport.Name = "WeaponPreviewViewport"
    viewport.Size = UDim2.new(1, -16, 0, 310)
    viewport.Position = UDim2.new(0, 8, 0, 8)
    viewport.BackgroundColor3 = Color3.fromRGB(11, 13, 19)
    viewport.Ambient = Color3.fromRGB(220, 225, 235)
    viewport.LightColor = Color3.fromRGB(255, 255, 255)
    viewport.LightDirection = Vector3.new(-1, -1.5, -1)
    viewport.Parent = leftPanel
    UI.viewportFrame = viewport

    local vpCorner = Instance.new("UICorner")
    vpCorner.CornerRadius = UDim.new(0, 6)
    vpCorner.Parent = viewport

    local previewCamera = Instance.new("Camera")
    previewCamera.FieldOfView = 50
    previewCamera.Parent = viewport
    viewport.CurrentCamera = previewCamera
    UI.previewCamera = previewCamera

    -- Orbit Render Loop
    RunService.RenderStepped:Connect(function(dt)
        if not State.orbitPaused then
            State.orbitAngle = State.orbitAngle + (dt * 0.9)
        end
        if UI.viewportFrame and UI.previewCamera and UI.previewModel then
            local cf, _ = UI.previewModel:GetBoundingBox()
            local center = cf.Position
            local camPos = center + Vector3.new(
                math.sin(State.orbitAngle) * State.orbitDistance,
                State.orbitDistance * 0.35,
                math.cos(State.orbitAngle) * State.orbitDistance
            )
            UI.previewCamera.CFrame = CFrame.lookAt(camPos, center)
        end
    end)

    -- Left Panel Controls: Info Card & Pause/Resume
    local infoBox = Instance.new("Frame")
    infoBox.Size = UDim2.new(1, -16, 0, 80)
    infoBox.Position = UDim2.new(0, 8, 0, 326)
    infoBox.BackgroundColor3 = Color3.fromRGB(14, 17, 25)
    infoBox.Parent = leftPanel

    local ibCorner = Instance.new("UICorner")
    ibCorner.CornerRadius = UDim.new(0, 6)
    ibCorner.Parent = infoBox

    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, -16, 1, -12)
    infoLabel.Position = UDim2.new(0, 8, 0, 6)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Font = Enum.Font.GothamMedium
    infoLabel.Text = "GUN: Assault Rifle\nSKIN: Default\nWRAP: None"
    infoLabel.TextColor3 = Color3.fromRGB(220, 230, 245)
    infoLabel.TextSize = 11
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.Parent = infoBox
    UI.activeInfoLabel = infoLabel

    local pauseBtn = Instance.new("TextButton")
    pauseBtn.Size = UDim2.new(1, -16, 0, 36)
    pauseBtn.Position = UDim2.new(0, 8, 1, -44)
    pauseBtn.BackgroundColor3 = Color3.fromRGB(28, 33, 47)
    pauseBtn.Font = Enum.Font.GothamBold
    pauseBtn.Text = "⏸ PAUSE 3D ROTATION"
    pauseBtn.TextColor3 = Color3.fromRGB(200, 215, 235)
    pauseBtn.TextSize = 11
    pauseBtn.Parent = leftPanel

    local pbCorner = Instance.new("UICorner")
    pbCorner.CornerRadius = UDim.new(0, 6)
    pbCorner.Parent = pauseBtn

    pauseBtn.MouseButton1Click:Connect(function()
        State.orbitPaused = not State.orbitPaused
        pauseBtn.Text = State.orbitPaused and "▶ RESUME 3D ROTATION" or "⏸ PAUSE 3D ROTATION"
        pauseBtn.TextColor3 = State.orbitPaused and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(200, 215, 235)
    end)

    -- RIGHT PANEL: SEARCH, FILTERS & CATALOG GRID
    local rightPanel = Instance.new("Frame")
    rightPanel.Name = "RightPanel"
    rightPanel.Size = UDim2.new(1, -352, 1, 0)
    rightPanel.Position = UDim2.new(0, 352, 0, 0)
    rightPanel.BackgroundColor3 = Color3.fromRGB(18, 22, 31)
    rightPanel.Parent = bodyFrame

    local rpCorner = Instance.new("UICorner")
    rpCorner.CornerRadius = UDim.new(0, 8)
    rpCorner.Parent = rightPanel

    local rpStroke = Instance.new("UIStroke")
    rpStroke.Color = Color3.fromRGB(38, 44, 62)
    rpStroke.Parent = rightPanel

    -- Search Bar & Filter Header
    local filterBar = Instance.new("Frame")
    filterBar.Size = UDim2.new(1, -16, 0, 36)
    filterBar.Position = UDim2.new(0, 8, 0, 8)
    filterBar.BackgroundColor3 = Color3.fromRGB(13, 16, 23)
    filterBar.Parent = rightPanel

    local fbCorner = Instance.new("UICorner")
    fbCorner.CornerRadius = UDim.new(0, 6)
    fbCorner.Parent = filterBar

    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(0.48, 0, 1, 0)
    searchBox.Position = UDim2.new(0, 10, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.Font = Enum.Font.GothamMedium
    searchBox.PlaceholderText = "Search skins / wraps..."
    searchBox.PlaceholderColor3 = Color3.fromRGB(110, 120, 140)
    searchBox.Text = ""
    searchBox.TextColor3 = Color3.fromRGB(240, 245, 255)
    searchBox.TextSize = 11
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.Parent = filterBar

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        State.searchQuery = searchBox.Text
        renderCatalogGrid()
    end)

    -- Rarity filter pills
    local rarityPillsContainer = Instance.new("Frame")
    rarityPillsContainer.Size = UDim2.new(0.5, 0, 1, 0)
    rarityPillsContainer.Position = UDim2.new(0.5, 0, 0, 0)
    rarityPillsContainer.BackgroundTransparency = 1
    rarityPillsContainer.Parent = filterBar

    local pillList = Instance.new("UIListLayout")
    pillList.FillDirection = Enum.FillDirection.Horizontal
    pillList.HorizontalAlignment = Enum.HorizontalAlignment.Right
    pillList.VerticalAlignment = Enum.VerticalAlignment.Center
    pillList.Padding = UDim.new(0, 4)
    pillList.Parent = rarityPillsContainer

    local filterButtons = {}
    local function makeRarityPill(rName)
        local pBtn = Instance.new("TextButton")
        pBtn.Size = UDim2.new(0, 52, 0, 24)
        pBtn.BackgroundColor3 = (State.rarityFilter == rName) and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(26, 31, 44)
        pBtn.Font = Enum.Font.GothamBold
        pBtn.Text = rName
        pBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        pBtn.TextSize = 9
        pBtn.Parent = rarityPillsContainer

        local pillCorner = Instance.new("UICorner")
        pillCorner.CornerRadius = UDim.new(0, 4)
        pillCorner.Parent = pBtn

        pBtn.MouseButton1Click:Connect(function()
            State.rarityFilter = rName
            for _, btn in pairs(filterButtons) do
                btn.BackgroundColor3 = Color3.fromRGB(26, 31, 44)
            end
            pBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
            renderCatalogGrid()
        end)
        table.insert(filterButtons, pBtn)
    end

    makeRarityPill("All")
    makeRarityPill("Legendary")
    makeRarityPill("Epic")
    makeRarityPill("Rare")
    makeRarityPill("Common")

    -- Catalog Grid ScrollingFrame
    local gridScroll = Instance.new("ScrollingFrame")
    gridScroll.Name = "CatalogGrid"
    gridScroll.Size = UDim2.new(1, -16, 1, -56)
    gridScroll.Position = UDim2.new(0, 8, 0, 50)
    gridScroll.BackgroundTransparency = 1
    gridScroll.ScrollBarThickness = 5
    gridScroll.ScrollBarImageColor3 = Color3.fromRGB(50, 60, 85)
    gridScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    gridScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    gridScroll.Parent = rightPanel
    UI.gridScroll = gridScroll

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 134, 0, 150)
    gridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = gridScroll

    -- ========================================================================
    -- MINIMIZED FLOATING PILL WIDGET
    -- ========================================================================
    local miniPill = Instance.new("TextButton")
    miniPill.Name = "SkinChangerMiniPill"
    miniPill.Size = UDim2.new(0, 150, 0, 36)
    miniPill.Position = UDim2.new(1, -165, 0, 15)
    miniPill.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
    miniPill.Font = Enum.Font.GothamBold
    miniPill.Text = "🎭 SKIN CHANGER"
    miniPill.TextColor3 = Color3.fromRGB(46, 204, 113)
    miniPill.TextSize = 11
    miniPill.Visible = false
    miniPill.Parent = screenGui
    UI.miniPill = miniPill

    local mpCorner = Instance.new("UICorner")
    mpCorner.CornerRadius = UDim.new(0, 18)
    mpCorner.Parent = miniPill

    local mpStroke = Instance.new("UIStroke")
    mpStroke.Color = Color3.fromRGB(46, 204, 113)
    mpStroke.Thickness = 1.5
    mpStroke.Parent = miniPill

    miniPill.MouseButton1Click:Connect(function()
        SkinChanger.restore()
    end)

    -- Toggle Hotkey (RightControl)
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.F4 then
            SkinChanger.toggle()
        end
    end)

    -- Initialize state
    updatePreviewModel()
    renderCatalogGrid()
end

-- ============================================================================
-- WINDOW VISIBILITY & CONTROLS
-- ============================================================================
function SkinChanger.open()
    State.uiVisible = true
    State.minimized = false
    if UI.mainFrame then UI.mainFrame.Visible = true end
    if UI.miniPill then UI.miniPill.Visible = false end
end

function SkinChanger.close()
    State.uiVisible = false
    if UI.mainFrame then UI.mainFrame.Visible = false end
    if UI.miniPill then UI.miniPill.Visible = false end
end

function SkinChanger.minimize()
    State.minimized = true
    if UI.mainFrame then UI.mainFrame.Visible = false end
    if UI.miniPill then UI.miniPill.Visible = true end
end

function SkinChanger.restore()
    State.minimized = false
    State.uiVisible = true
    if UI.mainFrame then UI.mainFrame.Visible = true end
    if UI.miniPill then UI.miniPill.Visible = false end
end

function SkinChanger.toggle()
    if State.minimized then
        SkinChanger.restore()
    elseif State.uiVisible then
        SkinChanger.minimize()
    else
        SkinChanger.open()
    end
end

-- ============================================================================
-- INITIALIZATION & AUTO-RUN
-- ============================================================================
function SkinChanger.start()
    hookClientViewModel()
    hookCosmeticLibrary()
    SkinChanger.createGui()
end

-- Auto-start when executed as a root script
if not getgenv then
    task.spawn(SkinChanger.start)
else
    getgenv().RivalsSkinChanger = SkinChanger
    task.spawn(SkinChanger.start)
end

return SkinChanger
