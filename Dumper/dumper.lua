--[[
    ============================================================================
    RIVALS SKIN CHANGER & 3D WEAPON CATALOG (STANDALONE MODULE)
    ============================================================================
    Target Experience: Rivals (Roblox PlaceId: 17625359962)
    Execution Mode: Modular Singleton with High-Performance Glassmorphism GUI

    Core Enhancements:
      1. Strict Weapon Filtering: Every weapon strictly displays ONLY its own skins.
         Embedded static lookup catalog covers all 50 weapons and 422 skins with real thumbnails.
      2. Local-Only Player Isolation:
         - ClientViewModel.GetWrap metamethod hook strictly verifies fighter.IsLocalPlayer.
         - Spectating guard prevents applying local overrides onto spectated players.
         - Other players in 3rd/1st person remain 100% untouched.
      3. Shot Validation & Raycast Collision Protection:
         - All cloned ViewModels have CanQuery, CanCollide, CanTouch explicitly disabled (false).
         - Prevents camera raycasts from colliding with local weapon models.
         - Weapon inventory spoofing made optional with clear hit-registration warnings.
      4. Persistent Per-Weapon Memory: Saves selected skin and wrap per weapon; turns emerald green.
      5. Interactive 3D Weapon Preview (ViewportFrame) with real-time 360 orbital camera.
      6. Modern Glassmorphism GUI (980x620) with Top Gun Selector, Draggable Header, and Hotkeys.
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
-- STATIC CATALOG DATA (STRICT WEAPON-TO-SKIN MAPPING)
-- ============================================================================
local STATIC_SKIN_CATALOG = {
    ["Assault Rifle"] = {
        { Name = "10B Visits", Rarity = "Unique", Image = "rbxassetid://122165086598560" },
        { Name = "Phoenix Rifle", Rarity = "Common", Image = "rbxassetid://140228738718621" },
        { Name = "Glorious Assault Rifle", Rarity = "Common", Image = "rbxassetid://130669996688265" },
        { Name = "AK-47", Rarity = "Rare", Image = "rbxassetid://17691132793" },
        { Name = "Boneclaw Rifle", Rarity = "Rare", Image = "rbxassetid://100015754284323" },
        { Name = "Pearl Rifle", Rarity = "Rare", Image = "rbxassetid://135277426561503" },
        { Name = "Augmented Rifle", Rarity = "Legendary", Image = "rbxassetid://18770192853" },
        { Name = "Gingerbread Augmented Rifle", Rarity = "Legendary", Image = "rbxassetid://85584922619813" },
        { Name = "Drum Gun", Rarity = "Legendary", Image = "rbxassetid://111251887761435" },
        { Name = "AKEY-47", Rarity = "Mythical", Image = "rbxassetid://80017496220683" },
    },
    ["Battle Axe"] = {
        { Name = "Nordic Axe", Rarity = "Common", Image = "" },
        { Name = "Ban Axe", Rarity = "Common", Image = "" },
        { Name = "Glorious Battle Axe", Rarity = "Common", Image = "" },
        { Name = "Cerulean Axe", Rarity = "Rare", Image = "" },
        { Name = "Tiki Axe", Rarity = "Rare", Image = "" },
        { Name = "The Shred", Rarity = "Legendary", Image = "" },
        { Name = "Mimic Axe", Rarity = "Legendary", Image = "" },
        { Name = "Balloon Axe", Rarity = "Legendary", Image = "" },
        { Name = "Street Sign", Rarity = "Legendary", Image = "" },
        { Name = "Keyttle Axe", Rarity = "Mythical", Image = "" },
    },
    ["Bow"] = {
        { Name = "Compound Bow", Rarity = "Common", Image = "" },
        { Name = "Glorious Bow", Rarity = "Common", Image = "" },
        { Name = "Raven Bow", Rarity = "Rare", Image = "" },
        { Name = "Bat Bow", Rarity = "Rare", Image = "" },
        { Name = "Frostbite Bow", Rarity = "Rare", Image = "" },
        { Name = "Dream Bow", Rarity = "Rare", Image = "" },
        { Name = "Palm Bow", Rarity = "Rare", Image = "" },
        { Name = "Balloon Bow", Rarity = "Legendary", Image = "" },
        { Name = "Beloved Bow", Rarity = "Legendary", Image = "" },
        { Name = "Key Bow", Rarity = "Mythical", Image = "rbxassetid://122525140091212" },
    },
    ["Burst Rifle"] = {
        { Name = "Spectral Burst", Rarity = "Common", Image = "rbxassetid://135012309412679" },
        { Name = "Pine Burst", Rarity = "Common", Image = "rbxassetid://132753732294083" },
        { Name = "Glorious Burst Rifle", Rarity = "Common", Image = "rbxassetid://78517330608597" },
        { Name = "Aqua Burst", Rarity = "Rare", Image = "rbxassetid://18837670807" },
        { Name = "Electro Rifle", Rarity = "Legendary", Image = "rbxassetid://132227459821018" },
        { Name = "Pixel Burst", Rarity = "Legendary", Image = "rbxassetid://102648809593259" },
        { Name = "Bullpup Burst", Rarity = "Legendary", Image = "rbxassetid://74974560606812" },
        { Name = "Sand Bullpup Burst", Rarity = "Legendary", Image = "rbxassetid://130731663986683" },
        { Name = "Keyst Rifle", Rarity = "Mythical", Image = "rbxassetid://78377522426003" },
    },
    ["Chainsaw"] = {
        { Name = "Glorious Chainsaw", Rarity = "Common", Image = "" },
        { Name = "Sharksaw", Rarity = "Common", Image = "" },
        { Name = "Blobsaw", Rarity = "Rare", Image = "" },
        { Name = "Handsaws", Rarity = "Legendary", Image = "rbxassetid://18766864583" },
        { Name = "Buzzsaw", Rarity = "Legendary", Image = "rbxassetid://74057448201836" },
        { Name = "Festive Buzzsaw", Rarity = "Legendary", Image = "rbxassetid://80811854818775" },
        { Name = "Mega Drill", Rarity = "Legendary", Image = "rbxassetid://76663867023998" },
    },
    ["Crossbow"] = {
        { Name = "Glorious Crossbow", Rarity = "Common", Image = "rbxassetid://70875146419725" },
        { Name = "Crossbone", Rarity = "Common", Image = "rbxassetid://103469183638638" },
        { Name = "Campfire Crossbow", Rarity = "Common", Image = "rbxassetid://76911697867059" },
        { Name = "Frostbite Crossbow", Rarity = "Rare", Image = "rbxassetid://101536997945363" },
        { Name = "Harpoon Crossbow", Rarity = "Rare", Image = "rbxassetid://107460405492001" },
        { Name = "Violin Crossbow", Rarity = "Rare", Image = "rbxassetid://74401302514014" },
        { Name = "Pixel Crossbow", Rarity = "Legendary", Image = "rbxassetid://115931961841903" },
        { Name = "Arch Crossbow", Rarity = "Mythical", Image = "rbxassetid://94981733362451" },
    },
    ["Daggers"] = {
        { Name = "Paper Planes", Rarity = "Common", Image = "rbxassetid://84003122595879" },
        { Name = "Shurikens", Rarity = "Common", Image = "rbxassetid://135574097643275" },
        { Name = "Glorious Daggers", Rarity = "Common", Image = "rbxassetid://76023189104485" },
        { Name = "Starfish", Rarity = "Common", Image = "rbxassetid://114567820096083" },
        { Name = "Aces", Rarity = "Rare", Image = "rbxassetid://139089881483398" },
        { Name = "Cookies", Rarity = "Rare", Image = "rbxassetid://114482325531769" },
        { Name = "Bat Daggers", Rarity = "Rare", Image = "rbxassetid://92001964015225" },
        { Name = "Broken Hearts", Rarity = "Legendary", Image = "rbxassetid://74156924296351" },
        { Name = "Toaster", Rarity = "Legendary", Image = "rbxassetid://103344379002564" },
        { Name = "Crystal Daggers", Rarity = "Mythical", Image = "rbxassetid://126221748659600" },
        { Name = "Keynais", Rarity = "Mythical", Image = "rbxassetid://84562761142610" },
    },
    ["Distortion"] = {
        { Name = "Glorious Distortion", Rarity = "Common", Image = "rbxassetid://134722661973710" },
        { Name = "Cyber Distortion", Rarity = "Common", Image = "rbxassetid://88995062151276" },
        { Name = "Electropunk Distortion", Rarity = "Rare", Image = "rbxassetid://109544539643046" },
        { Name = "Plasma Distortion", Rarity = "Rare", Image = "rbxassetid://126813935337091" },
        { Name = "Magma Distortion", Rarity = "Rare", Image = "rbxassetid://81103807698156" },
        { Name = "Sleighstortion", Rarity = "Rare", Image = "rbxassetid://111242141481650" },
        { Name = "Bubble Distortion", Rarity = "Rare", Image = "rbxassetid://73319804282513" },
        { Name = "Experiment D15", Rarity = "Legendary", Image = "rbxassetid://103446773933340" },
    },
    ["Energy Pistols"] = {
        { Name = "Glorious Energy Pistols", Rarity = "Common", Image = "rbxassetid://114418789647547" },
        { Name = "Hacker Pistols", Rarity = "Rare", Image = "rbxassetid://140621407555872" },
        { Name = "Apex Pistols", Rarity = "Rare", Image = "rbxassetid://136156057859453" },
        { Name = "New Year Energy Pistols", Rarity = "Rare", Image = "rbxassetid://126589959779039" },
        { Name = "Hydro Pistols", Rarity = "Rare", Image = "rbxassetid://115281889984097" },
        { Name = "Sol Pistols", Rarity = "Rare", Image = "rbxassetid://115012735954576" },
        { Name = "Void Pistols", Rarity = "Legendary", Image = "rbxassetid://111278471262300" },
        { Name = "Soul Pistols", Rarity = "Legendary", Image = "rbxassetid://72213738067158" },
        { Name = "Hyperlaser Guns", Rarity = "Legendary", Image = "rbxassetid://106947526362970" },
        { Name = "Enerkey Pistols", Rarity = "Mythical", Image = "rbxassetid://116755982646605" },
    },
    ["Energy Rifle"] = {
        { Name = "Glorious Energy Rifle", Rarity = "Common", Image = "rbxassetid://72632815443247" },
        { Name = "Hacker Rifle", Rarity = "Rare", Image = "rbxassetid://122816271917525" },
        { Name = "Apex Rifle", Rarity = "Rare", Image = "rbxassetid://88144772234151" },
        { Name = "New Year Energy Rifle", Rarity = "Rare", Image = "rbxassetid://111446782522703" },
        { Name = "Hydro Rifle", Rarity = "Rare", Image = "rbxassetid://73690448730060" },
        { Name = "Sol Rifle", Rarity = "Rare", Image = "rbxassetid://96272849525291" },
        { Name = "Void Rifle", Rarity = "Legendary", Image = "rbxassetid://95985016411441" },
        { Name = "Soul Rifle", Rarity = "Legendary", Image = "rbxassetid://129351366788323" },
        { Name = "Enerkey Rifle", Rarity = "Mythical", Image = "rbxassetid://104929541135510" },
    },
    ["Exogun"] = {
        { Name = "Midnight Festive Exogun", Rarity = "Common", Image = "rbxassetid://127612442529810" },
        { Name = "Glorious Exogun", Rarity = "Common", Image = "rbxassetid://129125201034206" },
        { Name = "Wondergun", Rarity = "Rare", Image = "rbxassetid://17672060360" },
        { Name = "Ray Gun", Rarity = "Rare", Image = "rbxassetid://18766861454" },
        { Name = "Exogourd", Rarity = "Rare", Image = "rbxassetid://137140750597688" },
        { Name = "Pearl Exogun", Rarity = "Rare", Image = "rbxassetid://77698515863000" },
        { Name = "Singularity", Rarity = "Legendary", Image = "rbxassetid://17676876756" },
        { Name = "Repulsor", Rarity = "Legendary", Image = "rbxassetid://109263387714628" },
    },
    ["Fists"] = {
        { Name = "Brass Knuckles", Rarity = "Common", Image = "" },
        { Name = "Pumpkin Claws", Rarity = "Common", Image = "" },
        { Name = "Festive Fists", Rarity = "Common", Image = "" },
        { Name = "Glorious Fists", Rarity = "Common", Image = "" },
        { Name = "Spy Gloves", Rarity = "Common", Image = "" },
        { Name = "Boxing Gloves", Rarity = "Rare", Image = "rbxassetid://17672060486" },
        { Name = "Fists of Hurt", Rarity = "Rare", Image = "rbxassetid://140103672289959" },
        { Name = "Fist", Rarity = "Legendary", Image = "rbxassetid://109585706680035" },
        { Name = "Pirate Hook", Rarity = "Legendary", Image = "rbxassetid://116717593932616" },
        { Name = "Crab Claws", Rarity = "Legendary", Image = "" },
    },
    ["Flamethrower"] = {
        { Name = "Lamethrower", Rarity = "Common", Image = "rbxassetid://18766862822" },
        { Name = "Glorious Flamethrower", Rarity = "Common", Image = "rbxassetid://71676635953177" },
        { Name = "Jack O\'Thrower", Rarity = "Rare", Image = "rbxassetid://140280020818514" },
        { Name = "Snowblower", Rarity = "Rare", Image = "rbxassetid://128743586418880" },
        { Name = "Glitterthrower", Rarity = "Rare", Image = "rbxassetid://88920581735649" },
        { Name = "Bubblethrower", Rarity = "Rare", Image = "rbxassetid://76812523297712" },
        { Name = "Pixel Flamethrower", Rarity = "Legendary", Image = "rbxassetid://17771752104" },
        { Name = "Rainbowthrower", Rarity = "Legendary", Image = "rbxassetid://102070206928252" },
        { Name = "Extinguisher", Rarity = "Legendary", Image = "" },
        { Name = "Keythrower", Rarity = "Mythical", Image = "" },
    },
    ["Flare Gun"] = {
        { Name = "Wrapped Flare Gun", Rarity = "Common", Image = "rbxassetid://135638020129378" },
        { Name = "Glorious Flare Gun", Rarity = "Common", Image = "rbxassetid://115324763672074" },
        { Name = "Dynamite Gun", Rarity = "Rare", Image = "rbxassetid://18766865384" },
        { Name = "Firework Gun", Rarity = "Legendary", Image = "rbxassetid://17691132917" },
        { Name = "Vexed Flare Gun", Rarity = "Legendary", Image = "rbxassetid://116287930550049" },
        { Name = "Banana Flare", Rarity = "Legendary", Image = "rbxassetid://123589213761955" },
        { Name = "Pocket Volcano", Rarity = "Legendary", Image = "rbxassetid://133260045254190" },
    },
    ["Flashbang"] = {
        { Name = "Skullbang", Rarity = "Common", Image = "rbxassetid://73796957224972" },
        { Name = "Lightbulb", Rarity = "Common", Image = "rbxassetid://125489177573287" },
        { Name = "Glorious Flashbang", Rarity = "Common", Image = "rbxassetid://96760506528185" },
        { Name = "Shining Star", Rarity = "Rare", Image = "rbxassetid://108392227354212" },
        { Name = "Disco Ball", Rarity = "Legendary", Image = "rbxassetid://17672061796" },
        { Name = "Camera", Rarity = "Legendary", Image = "rbxassetid://18766865640" },
        { Name = "Pixel Flashbang", Rarity = "Legendary", Image = "rbxassetid://132815625474597" },
        { Name = "Sol", Rarity = "Legendary", Image = "rbxassetid://124026864365877" },
    },
    ["Freeze Ray"] = {
        { Name = "Wrapped Freeze Ray", Rarity = "Common", Image = "" },
        { Name = "Glorious Freeze Ray", Rarity = "Common", Image = "" },
        { Name = "Bubble Ray", Rarity = "Rare", Image = "" },
        { Name = "Gum Ray", Rarity = "Rare", Image = "" },
        { Name = "Temporal Ray", Rarity = "Legendary", Image = "" },
        { Name = "Spider Ray", Rarity = "Legendary", Image = "" },
        { Name = "Cooler", Rarity = "Legendary", Image = "" },
    },
    ["Grappler"] = {
        { Name = "Glorious Grappler", Rarity = "Common", Image = "rbxassetid://113576961532090" },
        { Name = "Lifeguard Grappler", Rarity = "Common", Image = "rbxassetid://91214316625102" },
        { Name = "Lasso", Rarity = "Legendary", Image = "rbxassetid://77061966583531" },
        { Name = "Arcade Claw", Rarity = "Legendary", Image = "rbxassetid://81529455948004" },
        { Name = "Genie Lamp", Rarity = "Legendary", Image = "rbxassetid://118514051859760" },
        { Name = "Fishing Rod", Rarity = "Legendary", Image = "rbxassetid://86648406311812" },
    },
    ["Grenade"] = {
        { Name = "Dynamite", Rarity = "Common", Image = "rbxassetid://119066463640901" },
        { Name = "Glorious Grenade", Rarity = "Common", Image = "rbxassetid://103034870490455" },
        { Name = "Frozen Grenade", Rarity = "Common", Image = "rbxassetid://96120996159611" },
        { Name = "Water Balloon", Rarity = "Rare", Image = "rbxassetid://18766859819" },
        { Name = "Jingle Grenade", Rarity = "Rare", Image = "rbxassetid://97646859596860" },
        { Name = "Whoopee Cushion", Rarity = "Legendary", Image = "rbxassetid://17672062933" },
        { Name = "Soul Grenade", Rarity = "Legendary", Image = "rbxassetid://85903097459179" },
        { Name = "Cuddle Bomb", Rarity = "Legendary", Image = "rbxassetid://116801887274189" },
        { Name = "Fizz Bomb", Rarity = "Legendary", Image = "rbxassetid://123256093694497" },
        { Name = "Keynade", Rarity = "Mythical", Image = "rbxassetid://102785971311114" },
    },
    ["Grenade Launcher"] = {
        { Name = "Glorious Grenade Launcher", Rarity = "Common", Image = "rbxassetid://134130354519919" },
        { Name = "Uranium Launcher", Rarity = "Rare", Image = "rbxassetid://18766860114" },
        { Name = "Snowball Launcher", Rarity = "Rare", Image = "rbxassetid://112349955391111" },
        { Name = "Gearnade Launcher", Rarity = "Rare", Image = "rbxassetid://133756750612042" },
        { Name = "Coconut Launcher", Rarity = "Rare", Image = "rbxassetid://77621998397460" },
        { Name = "Swashbuckler", Rarity = "Legendary", Image = "rbxassetid://17821233828" },
        { Name = "Skull Launcher", Rarity = "Legendary", Image = "rbxassetid://103257281022910" },
        { Name = "Balloon Launcher", Rarity = "Legendary", Image = "rbxassetid://137862701599991" },
    },
    ["Gunblade"] = {
        { Name = "Elf\'s Gunblade", Rarity = "Common", Image = "rbxassetid://114103306647123" },
        { Name = "Crude Gunblade", Rarity = "Common", Image = "rbxassetid://126996645502136" },
        { Name = "Glorious Gunblade", Rarity = "Common", Image = "rbxassetid://88003799126136" },
        { Name = "Boneblade", Rarity = "Common", Image = "rbxassetid://126327381608481" },
        { Name = "Sharkbite", Rarity = "Common", Image = "rbxassetid://85479471132931" },
        { Name = "Hyper Gunblade", Rarity = "Legendary", Image = "rbxassetid://134415898983004" },
        { Name = "Gunsaw", Rarity = "Legendary", Image = "rbxassetid://102700915422689" },
        { Name = "Keyblade", Rarity = "Mythical", Image = "" },
    },
    ["Handgun"] = {
        { Name = "Pumpkin Handgun", Rarity = "Common", Image = "rbxassetid://88495685924653" },
        { Name = "Gumball Handgun", Rarity = "Common", Image = "rbxassetid://106890990556815" },
        { Name = "Glorious Handgun", Rarity = "Common", Image = "rbxassetid://85129427786041" },
        { Name = "Warp Handgun", Rarity = "Common", Image = "rbxassetid://102974911528828" },
        { Name = "Towerstone Handgun", Rarity = "Common", Image = "rbxassetid://88654252790032" },
        { Name = "Blaster", Rarity = "Rare", Image = "rbxassetid://17821234554" },
        { Name = "Gingerbread Handgun", Rarity = "Rare", Image = "rbxassetid://95881238590412" },
        { Name = "Sandgun", Rarity = "Rare", Image = "rbxassetid://111746039012812" },
        { Name = "Hand Gun", Rarity = "Legendary", Image = "rbxassetid://18837670624" },
        { Name = "Pixel Handgun", Rarity = "Legendary", Image = "rbxassetid://82199841278177" },
        { Name = "Stealth Handgun", Rarity = "Unobtainable", Image = "rbxassetid://124919185835138" },
    },
    ["Jump Pad"] = {
        { Name = "Trampoline", Rarity = "Common", Image = "" },
        { Name = "Glorious Jump Pad", Rarity = "Common", Image = "" },
        { Name = "Spider Web", Rarity = "Common", Image = "" },
        { Name = "Flamingo Floatie", Rarity = "Common", Image = "" },
        { Name = "Bounce House", Rarity = "Rare", Image = "" },
        { Name = "Shady Chicken Sandwich", Rarity = "Rare", Image = "" },
        { Name = "Jolly Man", Rarity = "Rare", Image = "" },
    },
    ["Katana"] = {
        { Name = "Glorious Katana", Rarity = "Common", Image = "rbxassetid://75588958786035" },
        { Name = "Swordfish", Rarity = "Common", Image = "rbxassetid://105748422389590" },
        { Name = "Lightning Bolt", Rarity = "Rare", Image = "rbxassetid://18768968241" },
        { Name = "Evil Trident", Rarity = "Rare", Image = "rbxassetid://101234805269080" },
        { Name = "New Year Katana", Rarity = "Rare", Image = "rbxassetid://102866488046710" },
        { Name = "Stellar Katana", Rarity = "Rare", Image = "rbxassetid://72617738655198" },
        { Name = "Saber", Rarity = "Legendary", Image = "rbxassetid://17672062341" },
        { Name = "Pixel Katana", Rarity = "Legendary", Image = "rbxassetid://127922483074145" },
        { Name = "Linked Sword", Rarity = "Legendary", Image = "rbxassetid://83575725004177" },
        { Name = "Cutlass", Rarity = "Legendary", Image = "rbxassetid://77773371747122" },
        { Name = "Keytana", Rarity = "Mythical", Image = "rbxassetid://118899310989170" },
        { Name = "Crystal Katana", Rarity = "Mythical", Image = "rbxassetid://88872493010693" },
        { Name = "Riptide Katana", Rarity = "Mythical", Image = "rbxassetid://136245206320139" },
        { Name = "Arch Katana", Rarity = "Mythical", Image = "rbxassetid://94679283541658" },
    },
    ["Knife"] = {
        { Name = "Chancla", Rarity = "Common", Image = "" },
        { Name = "Machete", Rarity = "Common", Image = "" },
        { Name = "Glorious Knife", Rarity = "Common", Image = "" },
        { Name = "Birthday Candle", Rarity = "Common", Image = "" },
        { Name = "Shark Tooth", Rarity = "Common", Image = "" },
        { Name = "Karambit", Rarity = "Legendary", Image = "" },
        { Name = "Candy Cane", Rarity = "Legendary", Image = "" },
        { Name = "Balisong", Rarity = "Legendary", Image = "rbxassetid://93303458333011" },
        { Name = "Caladbolg", Rarity = "Legendary", Image = "rbxassetid://101180142582964" },
        { Name = "Pencil", Rarity = "Legendary", Image = "" },
        { Name = "Keyrambit", Rarity = "Mythical", Image = "" },
        { Name = "Keylisong", Rarity = "Mythical", Image = "rbxassetid://100084654831857" },
        { Name = "Trophy Knife", Rarity = "Genuine", Image = "" },
        { Name = "Armature.001", Rarity = "Genuine", Image = "rbxassetid://104026327618871" },
    },
    ["MISSING_WEAPON"] = {
        { Name = "MISSING_SKIN", Rarity = "Unobtainable", Image = "rbxassetid://124519084257039" },
    },
    ["Maul"] = {
        { Name = "Glorious Maul", Rarity = "Common", Image = "" },
        { Name = "Ice Maul", Rarity = "Common", Image = "" },
        { Name = "Giant Popsicle", Rarity = "Common", Image = "" },
        { Name = "Excalibur", Rarity = "Common", Image = "" },
        { Name = "Sleigh Maul", Rarity = "Rare", Image = "" },
        { Name = "Starforge Maul", Rarity = "Rare", Image = "" },
        { Name = "Clown Hammer", Rarity = "Rare", Image = "" },
        { Name = "Ban Hammer", Rarity = "Legendary", Image = "" },
    },
    ["Medkit"] = {
        { Name = "Glorious Medkit", Rarity = "Common", Image = "" },
        { Name = "Briefcase", Rarity = "Rare", Image = "" },
        { Name = "Sandwich", Rarity = "Legendary", Image = "" },
        { Name = "Laptop", Rarity = "Legendary", Image = "" },
        { Name = "Bucket of Candy", Rarity = "Legendary", Image = "" },
        { Name = "Milk & Cookies", Rarity = "Legendary", Image = "" },
        { Name = "Medkitty", Rarity = "Legendary", Image = "rbxassetid://125732280509514" },
        { Name = "Box of Chocolates", Rarity = "Legendary", Image = "" },
        { Name = "Ice Cream", Rarity = "Legendary", Image = "" },
    },
    ["Minigun"] = {
        { Name = "Pumpkin Minigun", Rarity = "Common", Image = "rbxassetid://77388785880854" },
        { Name = "Wrapped Minigun", Rarity = "Common", Image = "rbxassetid://127077702465909" },
        { Name = "Glorious Minigun", Rarity = "Common", Image = "rbxassetid://84246894288637" },
        { Name = "Shark Minigun", Rarity = "Rare", Image = "rbxassetid://89295703576175" },
        { Name = "Lasergun 3000", Rarity = "Legendary", Image = "rbxassetid://103437974285778" },
        { Name = "Pixel Minigun", Rarity = "Legendary", Image = "rbxassetid://18766861798" },
        { Name = "Fighter Jet", Rarity = "Legendary", Image = "rbxassetid://70780739230558" },
    },
    ["Molotov"] = {
        { Name = "Coffee", Rarity = "Common", Image = "rbxassetid://17672061538" },
        { Name = "Torch", Rarity = "Common", Image = "rbxassetid://115586189235552" },
        { Name = "Glorious Molotov", Rarity = "Common", Image = "rbxassetid://108930340066987" },
        { Name = "Campfire Stick", Rarity = "Common", Image = "rbxassetid://83823494489693" },
        { Name = "Lava Lamp", Rarity = "Rare", Image = "rbxassetid://79616583726432" },
        { Name = "Vexed Candle", Rarity = "Legendary", Image = "rbxassetid://78128648928195" },
        { Name = "Hot Coals", Rarity = "Legendary", Image = "rbxassetid://110423024723304" },
        { Name = "Ship In A Bottle", Rarity = "Legendary", Image = "rbxassetid://125699268308415" },
        { Name = "Arch Molotov", Rarity = "Mythical", Image = "rbxassetid://96589300342777" },
    },
    ["Paintball Gun"] = {
        { Name = "Ketchup Gun", Rarity = "Common", Image = "rbxassetid://76083615050939" },
        { Name = "Glorious Paintball Gun", Rarity = "Common", Image = "rbxassetid://86297318955856" },
        { Name = "Lemonade Gun", Rarity = "Common", Image = "rbxassetid://119390099120478" },
        { Name = "Slime Gun", Rarity = "Rare", Image = "rbxassetid://17672062472" },
        { Name = "Brain Gun", Rarity = "Rare", Image = "rbxassetid://85970592668118" },
        { Name = "Snowball Gun", Rarity = "Rare", Image = "rbxassetid://113685354916533" },
        { Name = "Boba Gun", Rarity = "Legendary", Image = "rbxassetid://18768830660" },
        { Name = "Paintballoon Gun", Rarity = "Legendary", Image = "rbxassetid://100129918948246" },
    },
    ["Permafrost"] = {
        { Name = "Glorious Permafrost", Rarity = "Common", Image = "rbxassetid://119977291442329" },
        { Name = "Ice Permafrost", Rarity = "Common", Image = "rbxassetid://83722160119335" },
        { Name = "Snowman Permafrost", Rarity = "Common", Image = "rbxassetid://100890626643184" },
        { Name = "Permasand", Rarity = "Rare", Image = "rbxassetid://108398272946629" },
        { Name = "Permafrost.rbxm", Rarity = "Rare", Image = "rbxassetid://77732280270853" },
        { Name = "Starforge Permafrost", Rarity = "Rare", Image = "rbxassetid://105290041968367" },
        { Name = "Temporal Permafrost", Rarity = "Legendary", Image = "rbxassetid://124975247676715" },
    },
    ["RPG"] = {
        { Name = "Pencil Launcher", Rarity = "Common", Image = "rbxassetid://106934516693548" },
        { Name = "Glorious RPG", Rarity = "Common", Image = "rbxassetid://130506879885802" },
        { Name = "Squid Launcher", Rarity = "Rare", Image = "rbxassetid://130764310743404" },
        { Name = "Sundae Launcher", Rarity = "Rare", Image = "rbxassetid://70578055340962" },
        { Name = "Nuke Launcher", Rarity = "Legendary", Image = "rbxassetid://17672061995" },
        { Name = "Spaceship Launcher", Rarity = "Legendary", Image = "rbxassetid://18766860860" },
        { Name = "Pumpkin Launcher", Rarity = "Legendary", Image = "rbxassetid://94648176067808" },
        { Name = "Firework Launcher", Rarity = "Legendary", Image = "rbxassetid://75233372670156" },
        { Name = "Rocket Launcher", Rarity = "Legendary", Image = "rbxassetid://116931956715309" },
        { Name = "Cupcake Launcher", Rarity = "Legendary", Image = "rbxassetid://100541838356180" },
        { Name = "RPKEY", Rarity = "Mythical", Image = "rbxassetid://108438721125410" },
    },
    ["Revolver"] = {
        { Name = "Glorious Revolver", Rarity = "Common", Image = "rbxassetid://118135542031794" },
        { Name = "Desert Eagle", Rarity = "Rare", Image = "rbxassetid://17821234372" },
        { Name = "Boneclaw Revolver", Rarity = "Rare", Image = "rbxassetid://119174697609264" },
        { Name = "Sheriff", Rarity = "Legendary", Image = "rbxassetid://18770192507" },
        { Name = "Peppermint Sheriff", Rarity = "Legendary", Image = "rbxassetid://95859403750768" },
        { Name = "Peppergun", Rarity = "Legendary", Image = "rbxassetid://124178691056979" },
        { Name = "Cruise Revolver", Rarity = "Legendary", Image = "rbxassetid://72223124823807" },
        { Name = "Keyvolver", Rarity = "Mythical", Image = "rbxassetid://87974031410344" },
    },
    ["Riot Shield"] = {
        { Name = "Door", Rarity = "Common", Image = "" },
        { Name = "Sled", Rarity = "Common", Image = "" },
        { Name = "Glorious Riot Shield", Rarity = "Common", Image = "" },
        { Name = "Tombstone Shield", Rarity = "Common", Image = "" },
        { Name = "Broken Surfboard", Rarity = "Common", Image = "" },
        { Name = "Energy Shield", Rarity = "Rare", Image = "" },
        { Name = "Masterpiece", Rarity = "Rare", Image = "" },
    },
    ["Satchel"] = {
        { Name = "Suspicious Gift", Rarity = "Common", Image = "" },
        { Name = "Notebook Satchel", Rarity = "Common", Image = "" },
        { Name = "Bag o\' Money", Rarity = "Common", Image = "" },
        { Name = "Glorious Satchel", Rarity = "Common", Image = "" },
        { Name = "Lifeguard Satchel", Rarity = "Common", Image = "" },
        { Name = "Advanced Satchel", Rarity = "Rare", Image = "" },
        { Name = "Potion Satchel", Rarity = "Rare", Image = "" },
        { Name = "Pizza Box", Rarity = "Legendary", Image = "" },
    },
    ["Scythe"] = {
        { Name = "Glorious Scythe", Rarity = "Common", Image = "" },
        { Name = "Plastic Flamingo", Rarity = "Common", Image = "" },
        { Name = "Scythe of Death", Rarity = "Rare", Image = "" },
        { Name = "Anchor", Rarity = "Rare", Image = "" },
        { Name = "Bat Scythe", Rarity = "Rare", Image = "" },
        { Name = "Cryo Scythe", Rarity = "Rare", Image = "" },
        { Name = "Sakura Scythe", Rarity = "Rare", Image = "" },
        { Name = "Palm Scythe", Rarity = "Legendary", Image = "rbxassetid://97379805071194" },
        { Name = "Keythe", Rarity = "Mythical", Image = "" },
        { Name = "Crystal Scythe", Rarity = "Mythical", Image = "rbxassetid://73971549402646" },
        { Name = "Bug Net", Rarity = "Genuine", Image = "" },
    },
    ["Shorty"] = {
        { Name = "Too Shorty", Rarity = "Common", Image = "rbxassetid://18129531276" },
        { Name = "Not So Shorty", Rarity = "Common", Image = "rbxassetid://17672062572" },
        { Name = "Lovely Shorty", Rarity = "Common", Image = "rbxassetid://18766862000" },
        { Name = "Wrapped Shorty", Rarity = "Common", Image = "rbxassetid://136522183669611" },
        { Name = "Glorious Shorty", Rarity = "Common", Image = "rbxassetid://105834197552222" },
        { Name = "Demon Shorty", Rarity = "Rare", Image = "rbxassetid://116443498278384" },
        { Name = "Bubble Shorty", Rarity = "Rare", Image = "rbxassetid://111294137896866" },
        { Name = "Balloon Shorty", Rarity = "Legendary", Image = "rbxassetid://75590262133322" },
        { Name = "Cannon Shorty", Rarity = "Legendary", Image = "rbxassetid://137616738436928" },
    },
    ["Shotgun"] = {
        { Name = "Wrapped Shotgun", Rarity = "Common", Image = "rbxassetid://74894345245237" },
        { Name = "Cactus Shotgun", Rarity = "Common", Image = "rbxassetid://131606483507460" },
        { Name = "Glorious Shotgun", Rarity = "Common", Image = "rbxassetid://71704618059601" },
        { Name = "Broomstick", Rarity = "Rare", Image = "rbxassetid://118061559757082" },
        { Name = "Balloon Shotgun", Rarity = "Legendary", Image = "rbxassetid://17821234823" },
        { Name = "Hyper Shotgun", Rarity = "Legendary", Image = "rbxassetid://18768968419" },
        { Name = "Shark Shotgun", Rarity = "Legendary", Image = "rbxassetid://116415689080224" },
        { Name = "Shotkey", Rarity = "Mythical", Image = "rbxassetid://93004214983981" },
    },
    ["Slingshot"] = {
        { Name = "Goalpost", Rarity = "Common", Image = "rbxassetid://17672063165" },
        { Name = "Stick", Rarity = "Common", Image = "rbxassetid://17672063048" },
        { Name = "Glorious Slingshot", Rarity = "Common", Image = "rbxassetid://101195664167288" },
        { Name = "Palmshot", Rarity = "Common", Image = "rbxassetid://109640024736812" },
        { Name = "Boneshot", Rarity = "Rare", Image = "rbxassetid://86606957688341" },
        { Name = "Reindeer Slingshot", Rarity = "Rare", Image = "rbxassetid://121612921203624" },
        { Name = "Harp", Rarity = "Legendary", Image = "rbxassetid://80850043664453" },
        { Name = "Lucky Horseshoe", Rarity = "Legendary", Image = "rbxassetid://131242126669282" },
        { Name = "Keyshot", Rarity = "Mythical", Image = "rbxassetid://74006265601388" },
    },
    ["Smoke Grenade"] = {
        { Name = "Balance", Rarity = "Common", Image = "rbxassetid://18766866168" },
        { Name = "Glorious Smoke Grenade", Rarity = "Common", Image = "rbxassetid://139714146508398" },
        { Name = "Beach Ball", Rarity = "Common", Image = "rbxassetid://98068366944697" },
        { Name = "Snowglobe", Rarity = "Rare", Image = "rbxassetid://119390465944051" },
        { Name = "Hourglass", Rarity = "Rare", Image = "rbxassetid://108311418974073" },
        { Name = "Emoji Cloud", Rarity = "Legendary", Image = "rbxassetid://17821234077" },
        { Name = "Eyeball", Rarity = "Legendary", Image = "rbxassetid://135911399763146" },
    },
    ["Sniper"] = {
        { Name = "Eyething Sniper", Rarity = "Common", Image = "rbxassetid://103915302076013" },
        { Name = "Glorious Sniper", Rarity = "Common", Image = "rbxassetid://118012090175286" },
        { Name = "Campfire Sniper", Rarity = "Common", Image = "rbxassetid://127790438907599" },
        { Name = "Gingerbread Sniper", Rarity = "Rare", Image = "rbxassetid://99943841952995" },
        { Name = "Pixel Sniper", Rarity = "Legendary", Image = "rbxassetid://17676081196" },
        { Name = "Hyper Sniper", Rarity = "Legendary", Image = "rbxassetid://18766864081" },
        { Name = "Event Horizon", Rarity = "Legendary", Image = "rbxassetid://80749667426815" },
        { Name = "Kraken Sniper", Rarity = "Legendary", Image = "rbxassetid://95011666797584" },
        { Name = "Light Fifty", Rarity = "Legendary", Image = "rbxassetid://138029440298487" },
        { Name = "Keyper", Rarity = "Mythical", Image = "rbxassetid://85472935605264" },
    },
    ["Spear"] = {
        { Name = "Glorious Spear", Rarity = "Common", Image = "rbxassetid://98259628954838" },
        { Name = "Giant Pencil", Rarity = "Common", Image = "rbxassetid://107812045486260" },
        { Name = "Studio Light", Rarity = "Common", Image = "rbxassetid://70443632958263" },
        { Name = "Chark Kebab", Rarity = "Common", Image = "rbxassetid://74005839754537" },
        { Name = "Fork", Rarity = "Common", Image = "rbxassetid://105821360943308" },
        { Name = "Plunger", Rarity = "Rare", Image = "rbxassetid://82393330699241" },
        { Name = "Thunderpike", Rarity = "Rare", Image = "rbxassetid://137630900832105" },
    },
    ["Spray"] = {
        { Name = "Lovely Spray", Rarity = "Common", Image = "rbxassetid://131203015026683" },
        { Name = "Pine Spray", Rarity = "Common", Image = "rbxassetid://128285758736343" },
        { Name = "Nail Gun", Rarity = "Common", Image = "rbxassetid://110577809934251" },
        { Name = "Glorious Spray", Rarity = "Common", Image = "rbxassetid://138246745001490" },
        { Name = "Boneclaw Spray", Rarity = "Rare", Image = "rbxassetid://114078818081911" },
        { Name = "Spray Bottle", Rarity = "Legendary", Image = "rbxassetid://137955019285700" },
        { Name = "Campfire Spray", Rarity = "Legendary", Image = "rbxassetid://129294699009828" },
        { Name = "Key Spray", Rarity = "Mythical", Image = "rbxassetid://94061940442700" },
    },
    ["Subspace Tripmine"] = {
        { Name = "Trick or Treat", Rarity = "Common", Image = "" },
        { Name = "DIY Tripmine", Rarity = "Common", Image = "" },
        { Name = "Glorious Subspace Tripmine", Rarity = "Common", Image = "" },
        { Name = "Spring", Rarity = "Rare", Image = "" },
        { Name = "Don\'t Press", Rarity = "Legendary", Image = "" },
        { Name = "Dev-in-the-Box", Rarity = "Legendary", Image = "" },
        { Name = "Pot o\' Keys", Rarity = "Legendary", Image = "" },
        { Name = "Hazard Sign", Rarity = "Legendary", Image = "" },
    },
    ["Trowel"] = {
        { Name = "Glorious Trowel", Rarity = "Common", Image = "rbxassetid://100888500368219" },
        { Name = "Plastic Shovel", Rarity = "Rare", Image = "rbxassetid://17672062201" },
        { Name = "Garden Shovel", Rarity = "Rare", Image = "rbxassetid://18766864873" },
        { Name = "Pumpkin Carver", Rarity = "Rare", Image = "rbxassetid://78827307308671" },
        { Name = "Snow Shovel", Rarity = "Rare", Image = "rbxassetid://78271338778848" },
        { Name = "Paintbrush", Rarity = "Rare", Image = "rbxassetid://84687920829755" },
        { Name = "Scooper", Rarity = "Rare", Image = "rbxassetid://100816728062854" },
    },
    ["Uzi"] = {
        { Name = "Pine Uzi", Rarity = "Common", Image = "rbxassetid://82545206964916" },
        { Name = "Glorious Uzi", Rarity = "Common", Image = "rbxassetid://120045334159124" },
        { Name = "Ducky Uzi", Rarity = "Common", Image = "rbxassetid://133780419950894" },
        { Name = "Water Uzi", Rarity = "Rare", Image = "rbxassetid://17821233590" },
        { Name = "Demon Uzi", Rarity = "Rare", Image = "rbxassetid://132973040482576" },
        { Name = "Electro Uzi", Rarity = "Legendary", Image = "rbxassetid://96806694653207" },
        { Name = "Money Gun", Rarity = "Legendary", Image = "rbxassetid://100705725115757" },
        { Name = "Keyzi", Rarity = "Mythical", Image = "rbxassetid://100392703246534" },
        { Name = "Arch Uzi", Rarity = "Mythical", Image = "rbxassetid://139852585731073" },
    },
    ["War Horn"] = {
        { Name = "Mammoth Horn", Rarity = "Common", Image = "" },
        { Name = "Megaphone", Rarity = "Common", Image = "" },
        { Name = "Glorious War Horn", Rarity = "Common", Image = "" },
        { Name = "Trumpet", Rarity = "Rare", Image = "" },
        { Name = "Air Horn", Rarity = "Rare", Image = "" },
        { Name = "Boneclaw Horn", Rarity = "Rare", Image = "" },
        { Name = "Lifeguard Whistle", Rarity = "Legendary", Image = "" },
    },
    ["Warper"] = {
        { Name = "Glorious Warper", Rarity = "Common", Image = "rbxassetid://95823647035211" },
        { Name = "Electropunk Warper", Rarity = "Rare", Image = "rbxassetid://75386728379756" },
        { Name = "Glitter Warper", Rarity = "Rare", Image = "rbxassetid://94607497565715" },
        { Name = "Frost Warper", Rarity = "Rare", Image = "rbxassetid://70539216094396" },
        { Name = "Bubbler", Rarity = "Rare", Image = "rbxassetid://106002684466857" },
        { Name = "Experiment W4", Rarity = "Legendary", Image = "rbxassetid://126884960764998" },
        { Name = "Hotel Bell", Rarity = "Legendary", Image = "rbxassetid://117742703173821" },
        { Name = "Arcane Warper", Rarity = "Legendary", Image = "rbxassetid://83632373572638" },
    },
    ["Warpstone"] = {
        { Name = "Glorious Warpstone", Rarity = "Common", Image = "rbxassetid://137583560042806" },
        { Name = "Warpbone", Rarity = "Common", Image = "rbxassetid://96452209607150" },
        { Name = "Cyber Warpstone", Rarity = "Common", Image = "rbxassetid://133002984228937" },
        { Name = "Unstable Warpstone", Rarity = "Rare", Image = "rbxassetid://110083777654388" },
        { Name = "Electropunk Warpstone", Rarity = "Rare", Image = "rbxassetid://75299042976369" },
        { Name = "Warp Juice", Rarity = "Rare", Image = "rbxassetid://74381576761026" },
        { Name = "Teleport Disc", Rarity = "Legendary", Image = "rbxassetid://104608154111107" },
        { Name = "Warpstar", Rarity = "Legendary", Image = "rbxassetid://102652397897598" },
        { Name = "Warpeye", Rarity = "Mythical", Image = "rbxassetid://127023603234857" },
    },
    ["Wildcat"] = {
        { Name = "Glorious Wildcat", Rarity = "Common", Image = "rbxassetid://115657943825380" },
        { Name = "Plasma Wildcat", Rarity = "Rare", Image = "rbxassetid://88584176541333" },
    },
}

-- Default weapons list with exact game names
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
    { Name = "Gunblade", Class = "Primary", Image = "rbxassetid://18223601855" },
    { Name = "Distortion", Class = "Primary", Image = "rbxassetid://18223601855" },
    { Name = "Permafrost", Class = "Primary", Image = "rbxassetid://18223601855" },
    { Name = "Wildcat", Class = "Primary", Image = "rbxassetid://18223601855" },
    { Name = "Handgun", Class = "Secondary", Image = "rbxassetid://17160800994" },
    { Name = "Revolver", Class = "Secondary", Image = "rbxassetid://17160800880" },
    { Name = "Uzi", Class = "Secondary", Image = "rbxassetid://17160800624" },
    { Name = "Flare Gun", Class = "Secondary", Image = "rbxassetid://17160801264" },
    { Name = "Shorty", Class = "Secondary", Image = "rbxassetid://17160801380" },
    { Name = "Freeze Ray", Class = "Secondary", Image = "rbxassetid://18223601855" },
    { Name = "Energy Pistols", Class = "Secondary", Image = "rbxassetid://18223601855" },
    { Name = "Exogun", Class = "Secondary", Image = "rbxassetid://18223601855" },
    { Name = "Slingshot", Class = "Secondary", Image = "rbxassetid://18223601855" },
    { Name = "Spray", Class = "Secondary", Image = "rbxassetid://18223601855" },
    { Name = "Daggers", Class = "Secondary", Image = "rbxassetid://18223601855" },
    { Name = "Katana", Class = "Melee", Image = "rbxassetid://17160801158" },
    { Name = "Knife", Class = "Melee", Image = "rbxassetid://17160801041" },
    { Name = "Fists", Class = "Melee", Image = "rbxassetid://17672060486" },
    { Name = "Scythe", Class = "Melee", Image = "rbxassetid://18223601855" },
    { Name = "Battle Axe", Class = "Melee", Image = "rbxassetid://18223601855" },
    { Name = "Chainsaw", Class = "Melee", Image = "rbxassetid://18223601855" },
    { Name = "Maul", Class = "Melee", Image = "rbxassetid://18223601855" },
    { Name = "Spear", Class = "Melee", Image = "rbxassetid://18223601855" },
    { Name = "Trowel", Class = "Melee", Image = "rbxassetid://18223601855" },
    { Name = "Riot Shield", Class = "Melee", Image = "rbxassetid://18223601855" },
    { Name = "Grenade", Class = "Utility", Image = "rbxassetid://17160801411" },
    { Name = "Flashbang", Class = "Utility", Image = "rbxassetid://17160801529" },
    { Name = "Smoke Grenade", Class = "Utility", Image = "rbxassetid://17160799767" },
    { Name = "Molotov", Class = "Utility", Image = "rbxassetid://109264750627289" },
    { Name = "Medkit", Class = "Utility", Image = "rbxassetid://17160800366" },
    { Name = "Subspace Tripmine", Class = "Utility", Image = "rbxassetid://17160799418" },
    { Name = "Jump Pad", Class = "Utility", Image = "rbxassetid://18223601855" },
    { Name = "War Horn", Class = "Utility", Image = "rbxassetid://18223601855" },
    { Name = "Satchel", Class = "Utility", Image = "rbxassetid://18223601855" },
    { Name = "Warper", Class = "Utility", Image = "rbxassetid://18223601855" },
    { Name = "Warpstone", Class = "Utility", Image = "rbxassetid://18223601855" },
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

-- Normalizes weapon name aliases (e.g. Pistol -> Handgun)
local function normalizeWeaponName(name)
    if not name then return "" end
    if name == "Pistol" or name == "Hand Gun" then return "Handgun" end
    return name
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
    unlockWeapons = false, -- Disabled by default to prevent server-side shot drops
    invertPalette = false,
    saved = {},
}

local function getGunConfig(gunName)
    local g = normalizeWeaponName(gunName)
    if not State.saved[g] then
        State.saved[g] = {
            Skin = "Default",
            Wrap = "None",
            Inverted = false,
        }
    end
    return State.saved[g]
end

-- ============================================================================
-- CATALOG INGESTION (STRICT WEAPON-SPECIFIC FILTERING)
-- ============================================================================
local function getWeaponsList()
    local list = {}
    local seen = {}

    pcall(function()
        local Modules = ReplicatedStorage:FindFirstChild("Modules")
        local ItemLibModule = Modules and Modules:FindFirstChild("ItemLibrary")
        if ItemLibModule then
            local ItemLibrary = require(ItemLibModule)
            if ItemLibrary and ItemLibrary.ItemOrder then
                for _, weaponName in ipairs(ItemLibrary.ItemOrder) do
                    local normName = normalizeWeaponName(weaponName)
                    local itemInfo = ItemLibrary.Items and ItemLibrary.Items[weaponName]
                    local vmInfo = ItemLibrary.ViewModels and ItemLibrary.ViewModels[weaponName]
                    if itemInfo and not seen[normName] then
                        seen[normName] = true
                        table.insert(list, {
                            Name = normName,
                            Class = itemInfo.Class or "Weapon",
                            Image = (vmInfo and (vmInfo.ImageCentered or vmInfo.Image)) or (itemInfo and itemInfo.Image) or "",
                        })
                    end
                end
            end
        end
    end)

    if #list == 0 then
        for _, w in ipairs(DEFAULT_WEAPONS) do
            local normName = normalizeWeaponName(w.Name)
            if not seen[normName] then
                seen[normName] = true
                table.insert(list, {
                    Name = normName,
                    Class = w.Class,
                    Image = w.Image,
                })
            end
        end
    end

    return list
end

-- Strictly returns ONLY skins that belong to `weaponName`
local function getSkinsForWeapon(weaponName)
    local targetGun = normalizeWeaponName(weaponName)
    local skins = {}

    -- Always add "Default" stock gun mesh option first
    table.insert(skins, {
        Name = "Default",
        Rarity = "Common",
        Image = "",
        IsDefault = true,
    })

    local seen = { ["Default"] = true }

    -- 1. Check embedded static catalog for guaranteed weapon-to-skin parity
    if STATIC_SKIN_CATALOG[targetGun] then
        for _, s in ipairs(STATIC_SKIN_CATALOG[targetGun]) do
            if not seen[s.Name] then
                seen[s.Name] = true
                table.insert(skins, {
                    Name = s.Name,
                    Rarity = s.Rarity or "Common",
                    Image = s.Image or "",
                    Description = "",
                })
            end
        end
    end

    -- 2. Dynamically ingest any new skins from CosmeticLibrary matching strictly data.ItemName
    pcall(function()
        local Modules = ReplicatedStorage:FindFirstChild("Modules")
        local CosModule = Modules and Modules:FindFirstChild("CosmeticLibrary")
        local ItemLibModule = Modules and Modules:FindFirstChild("ItemLibrary")
        local ItemLibrary = ItemLibModule and require(ItemLibModule)
        if CosModule then
            local CosmeticLibrary = require(CosModule)
            if CosmeticLibrary and CosmeticLibrary.Cosmetics then
                for name, data in pairs(CosmeticLibrary.Cosmetics) do
                    -- STRICT FILTER: Only skins whose ItemName equals targetGun
                    if data.Type == "Skin" and normalizeWeaponName(data.ItemName) == targetGun and not seen[name] then
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
            if ItemLibrary and ItemLibrary.ViewModels and ItemLibrary.ViewModels[targetGun] then
                skins[1].Image = ItemLibrary.ViewModels[targetGun].ImageCentered or ItemLibrary.ViewModels[targetGun].Image or ""
            end
        end
    end)

    return skins
end

local function getWrapsList()
    local wraps = {}
    table.insert(wraps, {
        Name = "None",
        Rarity = "Common",
        P = Color3.fromRGB(60, 65, 80),
        S = Color3.fromRGB(30, 35, 45),
        Mat = "Default",
    })

    local seen = { ["None"] = true }

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
-- METAMETHOD HOOKS & LOCAL PLAYER ISOLATION
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
                -- STRICT LOCAL PLAYER ISOLATION:
                -- Check if this viewmodel belongs to our local player
                local clientItem = self.ClientItem
                local fighter = clientItem and clientItem.ClientFighter
                local isLocal = fighter and (fighter.IsLocalPlayer == true or fighter.Player == LocalPlayer)
                if not isLocal then
                    -- Do not modify other players!
                    return oldGetWrap(self)
                end

                local weaponName = normalizeWeaponName((clientItem and clientItem.Name) or self.Name)
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

-- ============================================================================
-- LIVE APPLICATION ENGINE (LOCAL ONLY + RAYCAST COLLISION SAFE)
-- ============================================================================
function SkinChanger.applySkinLive(targetGun)
    local gun = normalizeWeaponName(targetGun or State.selectedGun)
    local cfg = getGunConfig(gun)
    local selectedSkin = cfg.Skin
    local selectedWrap = cfg.Wrap
    local inverted = cfg.Inverted or State.invertPalette

    -- 1. Apply through FighterController.LocalFighter items strictly for LocalPlayer
    pcall(function()
        local scripts = LocalPlayer:FindFirstChild("PlayerScripts")
        local controllers = scripts and scripts:FindFirstChild("Controllers")
        local fc = controllers and controllers:FindFirstChild("FighterController")
        if not fc then return end
        local FighterController = require(fc)
        local fighter = FighterController.LocalFighter or (typeof(FighterController.GetFighter) == "function" and FighterController:GetFighter(LocalPlayer))

        -- STRICT LOCAL PLAYER & SPECTATE CHECK:
        if not fighter then return end
        if fighter.Player and fighter.Player ~= LocalPlayer then return end
        if fighter:Get("IsSpectating") then return end

        if fighter.Items then
            for _, item in pairs(fighter.Items) do
                local itemName = normalizeWeaponName(item.Name)
                if itemName == gun or not targetGun then
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

                                    -- CRUCIAL SHOT VALIDATION PROTECTION:
                                    -- Disable CanCollide, CanTouch, and CanQuery so the weapon mesh
                                    -- does not block camera raycasts or bullet hitboxes!
                                    for _, part in pairs(clone:GetDescendants()) do
                                        if part:IsA("BasePart") then
                                            part.CanCollide = false
                                            part.CanTouch = false
                                            part.CanQuery = false
                                            part.Massless = true
                                            part.CastShadow = false
                                        end
                                    end

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
                    -- Ensure query protection on first person parts
                    for _, part in pairs(model:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanQuery = false
                        end
                    end
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

local function updatePreviewModel()
    if not UI.viewportFrame then return end

    if UI.previewModel then
        UI.previewModel:Destroy()
        UI.previewModel = nil
    end

    local gun = normalizeWeaponName(State.selectedGun)
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

            local cf, sz = clone:GetBoundingBox()
            State.orbitDistance = math.clamp(sz.Magnitude * 1.35, 2.5, 7.5)

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

local function refreshGunSelectorHighlights()
    local cur = normalizeWeaponName(State.selectedGun)
    for gunName, card in pairs(UI.gunCards) do
        local isSelected = (gunName == cur)
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

local function renderCatalogGrid()
    clearGrid()
    if not UI.gridScroll then return end

    local gun = normalizeWeaponName(State.selectedGun)
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

                -- Thumbnail Image Label (Real 3D render image model)
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

                -- Status Badge
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

                -- Click Handler
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
        local panel = Instance.new("Frame")
        panel.Size = UDim2.new(1, -16, 0, 390)
        panel.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
        panel.Parent = UI.gridScroll

        local pCorner = Instance.new("UICorner")
        pCorner.CornerRadius = UDim.new(0, 10)
        pCorner.Parent = panel

        local pStroke = Instance.new("UIStroke")
        pStroke.Color = Color3.fromRGB(45, 52, 70)
        pStroke.Parent = panel

        local pTitle = Instance.new("TextLabel")
        pTitle.Size = UDim2.new(1, -24, 0, 26)
        pTitle.Position = UDim2.new(0, 16, 0, 12)
        pTitle.BackgroundTransparency = 1
        pTitle.Font = Enum.Font.GothamBold
        pTitle.Text = "COSMETIC & WEAPON SPOOFER SETTINGS"
        pTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
        pTitle.TextSize = 13
        pTitle.TextXAlignment = Enum.TextXAlignment.Left
        pTitle.Parent = panel

        local function makeToggle(label, subtitle, initialVal, yPos, callback)
            local tRow = Instance.new("Frame")
            tRow.Size = UDim2.new(1, -32, 0, 52)
            tRow.Position = UDim2.new(0, 16, 0, yPos)
            tRow.BackgroundColor3 = Color3.fromRGB(26, 31, 44)
            tRow.Parent = panel

            local rCorner = Instance.new("UICorner")
            rCorner.CornerRadius = UDim.new(0, 6)
            rCorner.Parent = tRow

            local rLabel = Instance.new("TextLabel")
            rLabel.Size = UDim2.new(0.72, 0, 0, 20)
            rLabel.Position = UDim2.new(0, 14, 0, 8)
            rLabel.BackgroundTransparency = 1
            rLabel.Font = Enum.Font.GothamMedium
            rLabel.Text = label
            rLabel.TextColor3 = Color3.fromRGB(220, 230, 245)
            rLabel.TextSize = 11
            rLabel.TextXAlignment = Enum.TextXAlignment.Left
            rLabel.Parent = tRow

            local rSub = Instance.new("TextLabel")
            rSub.Size = UDim2.new(0.72, 0, 0, 16)
            rSub.Position = UDim2.new(0, 14, 0, 28)
            rSub.BackgroundTransparency = 1
            rSub.Font = Enum.Font.Gotham
            rSub.Text = subtitle or ""
            rSub.TextColor3 = Color3.fromRGB(120, 135, 160)
            rSub.TextSize = 9
            rSub.TextXAlignment = Enum.TextXAlignment.Left
            rSub.Parent = tRow

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

        makeToggle("Unlock All Cosmetics", "Allows selecting all wraps, charms, titles in menus", State.unlockAll, 44, function(v)
            State.unlockAll = v
            hookCosmeticLibrary()
        end)

        makeToggle("Unlock All Weapons (Caution)", "Visual only; unowned weapons will drop server shot validation", State.unlockWeapons, 104, function(v)
            State.unlockWeapons = v
            hookCosmeticLibrary()
        end)

        makeToggle("Invert Wrap Palette", "Swaps WrapGroup 1 and 2 for reverse pattern styles", State.invertPalette, 164, function(v)
            State.invertPalette = v
            SkinChanger.applySkinLive(gun)
            updatePreviewModel()
        end)

        local resetGunBtn = Instance.new("TextButton")
        resetGunBtn.Size = UDim2.new(0.48, 0, 0, 42)
        resetGunBtn.Position = UDim2.new(0, 16, 0, 235)
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
        resetAllBtn.Position = UDim2.new(0.52, -8, 0, 235)
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

    makeHeaderPill("ModeSkins", "🎭 SKINS", 0, 85, function()
        State.mode = "Skins"
        renderCatalogGrid()
    end)

    makeHeaderPill("ModeWraps", "🎨 WRAPS", 95, 85, function()
        State.mode = "Wraps"
        renderCatalogGrid()
    end)

    makeHeaderPill("ModeUnlock", "🔓 UNLOCK ALL", 190, 105, function()
        State.mode = "UnlockAll"
        renderCatalogGrid()
    end)

    makeHeaderPill("LiveApply", "✨ APPLY NOW", 305, 95, function()
        SkinChanger.applySkinLive(State.selectedGun)
        updatePreviewModel()
    end)

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

    -- Top Gun Selector Strip (Horizontal Scrolling)
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

    -- Body Area: Viewport (Left) + Catalog Grid (Right)
    local bodyFrame = Instance.new("Frame")
    bodyFrame.Name = "BodyFrame"
    bodyFrame.Size = UDim2.new(1, -24, 1, -150)
    bodyFrame.Position = UDim2.new(0, 12, 0, 144)
    bodyFrame.BackgroundTransparency = 1
    bodyFrame.Parent = mainFrame

    -- Left: 3D ViewportFrame
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

    -- Right: Search, Filters & Catalog Grid
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

    -- Minimized Floating Pill
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

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.F4 then
            SkinChanger.toggle()
        end
    end)

    updatePreviewModel()
    renderCatalogGrid()
end

-- ============================================================================
-- WINDOW CONTROLS & API
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

function SkinChanger.start()
    hookClientViewModel()
    hookCosmeticLibrary()
    SkinChanger.createGui()
end

if not getgenv then
    task.spawn(SkinChanger.start)
else
    getgenv().RivalsSkinChanger = SkinChanger
    task.spawn(SkinChanger.start)
end

return SkinChanger
