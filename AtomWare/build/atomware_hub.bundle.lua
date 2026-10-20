--[[
======================================================================
     ATOMWARE UNIVERSAL GAME HUB (407+ ROBLOX GAMES SUPPORTED)
======================================================================
  * Key: THEBESTFIXED
  * Discord: https://discord.gg/AeCYnnQmq5
  * Compiled At: 2026-10-20 07:08:58 UTC
  * Features:
    - Auto Game Detection (407+ Place IDs)
    - Key Auth Prompt Modal with Discord Clipboard Integration
    - Discord Telemetry & Execution Audit Logger
    - Floating Draggable 🔍 Search & Gamehop Engine
    - Bottom-Right Live Watermark & Real-Time FPS Monitor
    - Cross-Platform UI (PC & Mobile Touch Responsive)
======================================================================
]]


do
    -- [MODULE 1: Games Database]
    local GamesDatabase = (function()
        --[[
            AtomWare Universal Script Hub - Games Database
            Compiled: 407 Supported Roblox Games
            Generated automatically by compile_hub_data.py
        --]]

        local GamesDatabase = {}
        GamesDatabase.ByPlaceId = {}
        GamesDatabase.List = {}

        local function addGame(placeId, name, title, loadstring)
            local entry = {
                PlaceId = placeId,
                Name = name,
                Title = title,
                Loadstring = loadstring
            }
            GamesDatabase.ByPlaceId[placeId] = entry
            table.insert(GamesDatabase.List, entry)
        end

        addGame(14608970270, "(ANNIVERSARY) Outcome Memories v0.2", "Sonic Old Camera restored", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/(ANNIVERSARY)-Outcome-Memories-v0.2-Sonic-Old-Camera-restored-229487\"))()")
        addGame(71704434889758, "(UPDATE) Drive A Kukirin!", "OS/OLENSOURCE AUTO TP PUMPKIN", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/UPDATE-Drive-A-Kukirin-OSOLENSOURCE-AUTO-TP-PUMPKIN-232154\"))()")
        addGame(120297898552393, "+1 Clone Evolution", "Auto Farm Wins", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/+1-Clone-Evolution-Auto-Farm-Wins-228980\"))()")
        addGame(100753254401525, "+1 DMG FPS", "Auto Farm Auto Rebirth Auto Win Keyless +1 DMG FPS", "loadstring(game:HttpGet(\"https://rscripts.net/raw/auto-farm-auto-rebirth-auto-win-keyless-1-dmg-fps_1790602104577_OORY3vexxh.txt\"))()")
        addGame(115564147666832, "+1 Football for Brainrots", "greatest script ever (it aint)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/1-Football-for-Brainrots-greatest-script-ever-it-aint-232155\"))()")
        addGame(74193805629461, "+1 Mine Per Click ⛏️", "Auto clicker, Auto rebirth, Auto Sell and More!!", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/1-Mine-Per-Click-Auto-clicker-Auto-rebirth-Auto-Sell-and-More-232334\"))()")
        addGame(83569851223739, "+1 Speed Evolve 🦊", "[KEYLESS] AUTO WIN AUTO EVOLVE SPEED AND FLY AUTO BUY", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/1-Speed-Evolve-KEYLESS-AUTO-WIN-AUTO-EVOLVE-SPEED-AND-FLY-AUTO-BUY-231998\"))()")
        addGame(114688126725619, "+1 Speed Plane Escape", "Ka-lel", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/+1-Speed-Plane-Escape-Ka-lel-229181\"))()")
        addGame(111543903102439, "+1 Stone Skipping", "[ KEYLESS ] +1 Stone Skipping SCRIPT", "loadstring(game:HttpGet(\"https://rscripts.net/raw/keyless-1-stone-skipping-script_1790297691241_vqbVVHeOPP.txt\"))()")
        addGame(134436671430963, "+1 Web Escape 🕸️", "Keyless | Auto Web | Auto Win | Auto Rebirth | More...", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/+1-Web-Escape-Keyless-or-Auto-Web-or-Auto-Win-or-Auto-Rebirth-or-More...-230829\"))()")
        addGame(84332574190497, "+1 Wings for Brainrots", "Auto steal", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/+1-Wings-for-Brainrots-Auto-steal-230475\"))()")
        addGame(121780816998126, "100 Days on Chunk", "Ore esp (comment on the website for bugs) keyless", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/100-Days-on-Chunk-Ore-esp-(comment-on-the-website-for-bugs)-keyless-229881\"))()")
        addGame(79546208627805, "99 Nights in the Forest 🔦", "NO KEY | God Mode | Auto Stronghold | Kill Player", "loadstring(game:HttpGet(\"https://rscripts.net/raw/no-key-or-god-mode-or-auto-stronghold-or-kill-player_1791449798449_lCLoelZBCC.txt\"))()")
        addGame(127403135954624, "[ Godzilla Ultima ] Kaiju Alpha", "Best OP Kill Aura Auto Attack Teleport Vote Kick Anti AFK", "loadstring(game:HttpGet(\"https://rscripts.net/raw/best-op-kill-aura-auto-attack-teleport-vote-kick-anti-afk_1790318726560_Qcrn5TNKTc.txt\"))()")
        addGame(117949143041402, "[ 🏆UPD0.5 ] Anime Mysterious", "[Keyless] bobcat", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/UPD05-Anime-Mysterious-Keyless-bobcat-232151\"))()")
        addGame(12144402492, "[0.25.3] Deadline", "Opensource  ESP (ALL PLAYERS AND BODYS)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/0.25.3-Deadline-Opensource-ESP-(ALL-PLAYERS-AND-BODYS)-231472\"))()")
        addGame(11717233041, "[1.5X COINS + OCT 8 CHAR] TBSOBR", "Spamton Mines Ore Teleporter", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/15X-COINS-OCT-8-CHAR-TBSOBR-Spamton-Mines-Ore-Teleporter-232168\"))()")
        addGame(7772810845, "[2X POINTS] The Presentation Experience", "[AUTO HOMEWORK] TPE", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/2X-POINTS-The-Presentation-Experience-AUTO-HOMEWORK-TPE-231217\"))()")
        addGame(113217312262185, "[2X💰] SCP retroBreach", "Silent Aim Open Source", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/2X-SCP-retroBreach-Silent-Aim-Open-Source-230166\"))()")
        addGame(7655745946, "[2x💸] Dunking Simulator", "KEYLESS | Get all items, inf money and more | Besto", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/2x-Dunking-Simulator-KEYLESS-or-Get-all-items-inf-money-and-more-or-Besto-231177\"))()")
        addGame(107838858975205, "[9 DAYS] DOORS HARDCORE 👁️", "Ai slop (1) Doors auto open", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/9-DAYS-DOORS-HARDCORE-Ai-slop-(1)-Doors-auto-open-230761\"))()")
        addGame(113371877732022, "[After life] Hole🕳️", "script for game:", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Hole-script-231859\"))()")
        addGame(100293509865504, "[Boss🔥] Catch 1 Billion Ducks", "Kill Aura, Kill all Ducks", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Boss-Catch-1-Billion-Ducks-Kill-Aura-Kill-all-Ducks-232045\"))()")
        addGame(116637001962797, "[CHAPTERS] Manage A Country", "OP Script | easy Leaderboard", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/CHAPTERS-Manage-A-Country-OP-Script-or-easy-Leaderboard-232125\"))()")
        addGame(90906407195271, "[EVENT🎃] Racket Rivals", "Hitbox Expander", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/EVENT-Racket-Rivals-Hitbox-Expander-232133\"))()")
        addGame(81776958028454, "[FA] Galax Roleplay", "Galaxy rp horloge", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/FA-Galax-Roleplay-Galaxy-rp-horloge-229498\"))()")
        addGame(2418863943, "[FORMULA] Roanoke, VA Driving RP", "Autumn AutoFarm", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/FORMULA-Roanoke-VA-Driving-RP-Autumn-AutoFarm-229187\"))()")
        addGame(90568084448279, "[FPS] One Tap", "YGHT V1 beta [FPS] UM TOQUE", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/FPS-One-Tap-YGHT-V1-beta-FPS-UM-TOQUE-232155\"))()")
        addGame(76417404076212, "[FPS🗡️] SHARD", "Silent Aim & Anticheat Disabler", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/FPS-SHARD-Silent-Aim-and-Anticheat-Disabler-229051\"))()")
        addGame(93938699582360, "[Free Avatar] MOUNT SALFARA", "Auto farm fish Secret Rod", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Free-Avatar-MOUNT-SALFARA-Auto-farm-fish-Secret-Rod-230359\"))()")
        addGame(17455699549, "[FREE KJ] Mystic Battleground", "Muha no coldown dash", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/FREE-KJ-Mystic-Battleground-Muha-no-coldown-dash-229756\"))()")
        addGame(99881445915767, "[HALLOWEEN] TECHY", "no recoil + no spread + auto bhop", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/HALLOWEEN-TECHY-no-recoil-+-no-spread-+-auto-bhop-230472\"))()")
        addGame(10253248401, "[HALLOWEEN🎃] Elemental Powers Tycoon", "Elemental", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Elemental-Powers-Tycoon-Elemental-229508\"))()")
        addGame(8540168650, "[HUGE UPDATE] Stand Upright: Rebooted", "Item Farm Keyless", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/HUGE-UPDATE-Stand-Upright:-Rebooted-Item-Farm-Keyless-231394\"))()")
        addGame(72712036210947, "[INVITES] Fix It Up!", "Fix It Up | Auto Farm, Auto Repair, Car ESP | Mobile Support", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/INVITES-Fix-It-Up!-Fix-It-Up-or-Auto-Farm-Auto-Repair-Car-ESP-or-Mobile-Support-229154\"))()")
        addGame(4639625707, "[KF-41] War Tycoon", "Facility", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/KF-41-War-Tycoon-Facility-232076\"))()")
        addGame(6804602922, "[MAP!] Boxing Beta! 🥊", "Lucid.xyz", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/MAP-Boxing-Beta-Lucidxyz-232031\"))()")
        addGame(18281776841, "[NEW CARS] 🌴 Highway Showdown", "| V2 | No Key | Car Search | Vehicle GUI", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/NEW-CARS-Highway-Showdown-AUTO-FARM-SELECT-ANY-CAR-FREE-KEYLESS-228957\"))()")
        addGame(97377008543826, "[NEW] Anime Levels", "[NEW]  BEST FREE KEYLES SCRIPT OP", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/NEW-Anime-Levels-NEW-BEST-FREE-KEYLES-SCRIPT-OP-231279\"))()")
        addGame(81403703556465, "[NEW] Bahay Kubo Garden 🌱", "[Keyless] bobcat", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/NEW-Bahay-Kubo-Garden-Keyless-bobcat-230915\"))()")
        addGame(127882277277478, "[NEW] FIXATION", "Esp / tp to obj    (AI maded)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/NEW-FIXATION-Esp-tp-to-obj-(AI-made)-229056\"))()")
        addGame(72858262610964, "[NEW] Tap Simulator: Reborn", "[ KEYLESS ] Tap Simulator: Reborn Script", "loadstring(game:HttpGet(\"https://rscripts.net/raw/keyless-tap-simulator-reborn-script_1791605092488_hbSBYoCwr5.txt\"))()")
        addGame(74023858073178, "[NEW❗] Bike For Egg!", "Auto farm keyless and more feature", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/NEW-Bike-For-Egg-Auto-farm-keyless-and-more-feature-232219\"))()")
        addGame(118041109999946, "[PLAYTEST] CNSD : Reborn", "Free product (instructions on the description)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/PLAYTEST-CNSD-:-Reborn-Free-product-(instructions-on-the-description)-230459\"))()")
        addGame(122287678911982, "[PUBLIC TEST!] Vampire life", "Instant kill auto farm", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/PUBLIC-TEST!-Vampire-life-Instant-kill-auto-farm-230339\"))()")
        addGame(109397169461300, "[RANKED] SNIPER DUELS", "Vyrox KEYLESS", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/SNIPER-DUELS-Vyrox-KEYLESS-230945\"))()")
        addGame(131558436575033, "[REALISTIC] SevenM Hood Testing", "AIMBOT+ESP", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/REALISTIC-SevenM-Hood-Testing-AIMBOT+ESP-229191\"))()")
        addGame(124032631078772, "[RELEASE] Poly Loot⚔️", "Candy Corn Auto Farm :)", "loadstring(game:HttpGet(\"https://rscripts.net/raw/candy-corn-auto-farm_1791916868599_FSoAb3Ptlb.txt\"))()")
        addGame(139780970631001, "[RELEASE] Prehistoric Farm", "[ KEYLESS ] Prehistoric Farm", "loadstring(game:HttpGet(\"https://rscripts.net/raw/keyless-prehistoric-farm_1791370623252_h5jZv8TFYD.txt\"))()")
        addGame(10714365287, "[REVAMP] Anime Racing Clicker", "Open Source", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/REVAMP-Anime-Racing-Clicker-Open-Source-232162\"))()")
        addGame(15002061926, "[RNG AURA] Death Ball", "[Free[Beta][Goha]", "loadstring(game:HttpGet(\"https://rscripts.net/raw/freebetagoha_1791234685775_e8SI71EWrN.txt\"))()")
        addGame(12593620250, "[RSBK] Ride Storm", "[LITEDIRT]", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/SUSPENSION-Ride-Storm-AUTO-TELEPORT-or-AUTO-JOB-KEYLESS-230065\"))()")
        addGame(2338325648, "[S14🎉] NFL Universe Football", "NFL Universe Football🏈 [KEYLESS + BALL MAGNET + AUTO QB 🔥]", "loadstring(game:HttpGet(\"https://rscripts.net/raw/nfl-universe-football-keyless-ball-magnet-auto-qb_1789867079169_M5UPC85zvm.txt\"))()")
        addGame(128662368175518, "[SANDEVISTAN COUNTER] DUMMY COUNTER YOUR FRIENDS", "Auto-farm for DCYF", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/SANDEVISTAN-COUNTER-DUMMY-COUNTER-YOUR-FRIENDS-Auto-farm-for-DCYF-231866\"))()")
        addGame(15269951959, "[SHINJI] Legends Battlegrounds", "inf m1", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/SHINJI-Legends-Battlegrounds-inf-m1-232227\"))()")
        addGame(94152549783289, "[SKM!] The Urban Line: FreeDrive", "INFINITE MONEY & XP [OP]", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/SKM!-The-Urban-Line:-FreeDrive-INFINITE-MONEY-and-XP-OP-228851\"))()")
        addGame(9391468976, "[SKY ASSASSIN] Jujutsu Shenanigans", "Nexus keyless script", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/SKY-ASSASSIN-Jujutsu-Shenanigans-Nexus-keyless-script-232015\"))()")
        addGame(129305872972839, "[SPOOKY MONTH] Forsaken Combat Fighting", "Focus v2 (READ DESC)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/SPOOKY-MONTH-Forsaken-Combat-Fighting-Focus-v2-READ-DESC-231978\"))()")
        addGame(87204735676240, "[STICKERS!] Kontra", "Silent aim | Wallbang | ESP", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/STICKERS-Kontra-Silent-aim-or-Wallbang-or-ESP-232468\"))()")
        addGame(1828, "[TITLE UNAVAILABLE]", "120 fps", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/TITLE-UNAVAILABLE-120-fps-229097\"))()")
        addGame(127719392433046, "[TRIDENT] Mortalia [BETA]", "keyless killaura", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/TRIDENT-Mortalia-BETA-keyless-killaura-232128\"))()")
        addGame(17431446039, "[TSID] Simulator Truk Indonesia", "AUTO FARM New Truk, Auto Buy Truck", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/TSID-Simulator-Truk-Indonesia-AUTO-FARM-230783\"))()")
        addGame(3231515867, "[TÜRK] Turkish Army War Simulator 💂", "TA 1.9 Script Cheat", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/TURK-Turkish-Army-War-Simulator-TA-1.9-Script-Cheat-230586\"))()")
        addGame(123974602339071, "[UP] Just a baseplate.", "Uhhhhhh reanimate big rig by me (read des)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/UP-Just-a-baseplate-Uhhhhhh-reanimate-big-rig-by-me-232243\"))()")
        addGame(78453398695059, "[UPD 2.1 🎃] THRESHOLD", "script  2.1,", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/UPD-21-THRESHOLD-script-21-232321\"))()")
        addGame(129216769649527, "[UPD 4 🔥] Beat the Anime Boss!", "Auto Farm, Unit Ranking & Infinity Castle | Free, No Key", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/TRADE-Beat-the-Anime-Boss!-Auto-Farm-Unit-Ranking-and-Infinity-Castle-or-Free-No-Key-229161\"))()")
        addGame(18687417158, "[UPD 🤖] Forsaken", "Best keyless auto backstab", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/UPD-Forsaken-Best-keyless-auto-backstab-232368\"))()")
        addGame(116921506811323, "[UPD] 8 Ball Duels", "AIM ASSIST FOR", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/NEW-8-Ball-Duels-AIM-ASSIST-FOR-231228\"))()")
        addGame(101272402522756, "[UPD] BBQ Battles 🍢", "| KILL AURA, AUTO FARM STAR & AUTO FARM (100% FR", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/UPD-BBQ-Battles-or-KILL-AURA-AUTO-FARM-STAR-and-AUTO-FARM-(100percent-FR-230693\"))()")
        addGame(70435795041539, "[UPD] Junk Mechanics", "[keyless] full auto farm", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/UPD-Junk-Mechanics-keyless-full-auto-farm-231995\"))()")
        addGame(107717448640907, "[UPD] Nights of Eternity 🍕", "Esp/Inf Stamina/Generator Auto", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/UPD-Nights-of-Eternity-EspInf-StaminaGenerator-Auto-232208\"))()")
        addGame(90945110834775, "[UPD] POINT BLOX", "Aimbot Smooth Aim God Mode Keyless Point Blox", "loadstring(game:HttpGet(\"https://rscripts.net/raw/aimbot-smooth-aim-god-mode-keyless-point-blox_1790602276177_5hQvyfP6uD.txt\"))()")
        addGame(73956553001240, "[UPD] Volleyball Legends", "FREE ROLL BACK GET ANY STYLE YOU WANT", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/UPD-Volleyball-Legends-FREE-ROLL-BACK-GET-ANY-STYLE-YOU-WANT-232153\"))()")
        addGame(118805555015549, "[UPD]+1 Loot To Forge", "INSTANT KILL | GOD MODE | AUTO FARMS | AUTO ORES | AUTO ALL", "loadstring(game:HttpGet(\"https://rscripts.net/raw/instant-kill-or-god-mode-or-auto-farms-or-auto-ores-or-auto-all_1790350160263_kJqeeNXh80.txt\"))()")
        addGame(139536504610209, "[UPD]🛠️Build and Kill Verity", "auto start waves for afk", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/UPDBuild-and-Kill-Verity-auto-start-waves-for-afk-232063\"))()")
        addGame(74968636725538, "[UPDATE 2!] Kick an Uma", "fckCM", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/UPDATE-2!-Kick-an-Uma-*CM-230402\"))()")
        addGame(10260193230, "[UPDATE 4] Meme Sea", "Script  minh kha hup", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/UPDATE-4-Meme-Sea-Script-minh-kha-hup-231731\"))()")
        addGame(301549746, "[UPDATE!] Counter Blox", "Zenith", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/UPDATE-Counter-Blox-Zenith-232357\"))()")
        addGame(127608230264974, "[UPDATE] La Peace Obby", "Auto Finish To The End", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/UPDATE-La-Peace-Obby-Auto-Finish-To-The-End-229105\"))()")
        addGame(109329896664198, "[UPDATE] Shigaku", "open source auto-gym script", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/UPDATE-Shigaku-open-source-auto-gym-script-231187\"))()")
        addGame(101880234193261, "[UPDATE] Turbo Soccer : Beta 1.0", "TURP", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/UPDATE-Turbo-Soccer-:-Beta-1.0-TURP-231762\"))()")
        addGame(6403373529, "[UPDATE👁️] Slap Battles👏", "Sapple farm (upgraded)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/UPDATE-Slap-Battles-Sapple-farm-upgraded-232381\"))()")
        addGame(90198315559220, "[UTTVM]Titans ultra boss rush", "DeHaDop TUBR keyless", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/UTTVMTitans-ultra-boss-rush-DeHaDop-TUBR-keyless-229210\"))()")
        addGame(97655748236852, "[v5.5] hus from clark", "God Mode", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/v5.5-hus-from-clark-God-Mode-229963\"))()")
        addGame(110269326783786, "[WELL REWORK+SW] Stalker Sandbox", "admin keyless", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/WELL-REWORK+SW-Stalker-Sandbox-Script-admin-keyless-231480\"))()")
        addGame(90086669327265, "[X2] +1 Cut Grass Adventure", "SAVX OP auto farm, auto rebirth and more! Keyless", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/X2-+1-Cut-Grass-Adventure-SAVX-OP-auto-farm-auto-rebirth-and-more!-Keyless-231001\"))()")
        addGame(71242901165556, "[YARA YARA] Phonk Clicker 🎶", "Music Changer (Forcer)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/YARA-YARA-Phonk-Clicker-Music-Changer-(Forcer)-229436\"))()")
        addGame(114234929420007, "[ZOMBIES!] BloxStrike", "[KEYLESS] UNLOCK ALL", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/NEW-MAP-BloxStrike-KEYLESS-UNLOCK-ALL-232027\"))()")
        addGame(72920620366355, "[ZOMBIES] Operation One", "N0IR op1 script", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/SEASON-3-Operation-One-N0IR-op1-script-229061\"))()")
        addGame(132767904294856, "[⚽] Blue Lock Farm", "[ KEYLESS ] Blue Lock Farm SCRIPT", "loadstring(game:HttpGet(\"https://rscripts.net/raw/keyless-blue-lock-farm-script_1790445561371_lL7YGWcpdD.txt\"))()")
        addGame(84757653274750, "[⛩️] +1 Katana Evolution", "Inf Wins nd more", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/+1-Katana-Evolution-Inf-Wins-nd-more-229182\"))()")
        addGame(125927821145949, "[⛰️] Mine a Mountain", "MaM - Auto Collect Ghosts & Pumpkins", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Mine-a-Mountain-MaM-Auto-Collect-Ghosts-and-Pumpkins-232146\"))()")
        addGame(72845937010155, "[✋] Gear Slap Tower", "Cool Gui V1 (OP)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Gear-Slap-Tower-Cool-Gui-V1-(OP)-229736\"))()")
        addGame(133363783004873, "[✨] Collect 1 Million Items", "[ KEYLESS ] Collect 1 Million Items SCRIPT", "loadstring(game:HttpGet(\"https://rscripts.net/raw/keyless-collect-1-million-items-script_1790305899993_5nsI2QTHxR.txt\"))()")
        addGame(98695134949589, "[⭐] +1 Followers Per Click", "Auto Upgrade Auto Win Rebirth Keyless +1 Followers Per Click", "loadstring(game:HttpGet(\"https://rscripts.net/raw/auto-upgrade-auto-win-rebirth-keyless-1-followers-per-click_1790602231147_lMAyf3LERA.txt\"))()")
        addGame(106568491289620, "[将] Shogun's Reign", "Auto Farm, Auto Parry, and more", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Shogun's-Reign-Auto-Farm-Auto-Parry-and-more-230086\"))()")
        addGame(6270290407, "[🌀 UPDATE] VV: ULTIMATUM", "KEYLESS Auto Parry, Boss farm, Auto quests,More", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/UPDATE-VV:-ULTIMATUM-Auto-Parry-Boss-farm-Auto-questsMore-229808\"))()")
        addGame(104469958681645, "[🌸UPD] Steal & Hatch Brainrot Eggs", "Auto steal and more", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/UPD-Steal-and-Hatch-Brainrot-Eggs-Auto-steal-and-more-229805\"))()")
        addGame(185655149, "[🍂] Welcome to Bloxburg", "weretools cracked", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Welcome-to-Bloxburg-weretools-cracked-230389\"))()")
        addGame(113956654824187, "[🍬] Swim For Eggs!", "[ KEYLESS ] Swim For Eggs Script", "loadstring(game:HttpGet(\"https://rscripts.net/raw/keyless-swim-for-eggs-script_1790627743321_j6eWIMktoL.txt\"))()")
        addGame(116497287371701, "[🍲] Karinderya!", "[Keyless] bobcat", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Karinderya!-Keyless-bobcat-230418\"))()")
        addGame(136020512003847, "[🎃 EVENT] San Diego Roleplay", "LuckymensLostAcc", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/GANGS-San-Diego-Roleplay-LuckymensLostAcc-231382\"))()")
        addGame(128836536655551, "[🎃] Alkedion PVP", "Best Silent Aim Instant Hit", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Alkedion-PVP-Best-Silent-Aim-Instant-Hit-230893\"))()")
        addGame(113290951185459, "[🎃] Anime Dice", "KEYLESS | AUTO FARM | AUTO COLLECT,AUTO BUY ,AUTO UPGRADE...", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/UPD-8-Anime-Dice-KEYLESS-or-AUTO-FARM-or-AUTO-COLLECTAUTO-BUY-AUTO-UPGRADE-232002\"))()")
        addGame(132352755769957, "[🎃] Asylum Life 🔊", "ROBLOX  OP SCRIPT GUI (KEYLESS & FREE)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/UPD-Asylum-Life-ROBLOX-OP-SCRIPT-GUI-(KEYLESS-and-FREE)-231039\"))()")
        addGame(91034536684382, "[🎃] Destroy a Vault", "[KEYLESS]Auto Vault, Auto Level, Auto Gold, Auto Buy", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Destroy-a-Vault-KEYLESSAuto-Vault-Auto-Level-Auto-Gold-Auto-Buy-232260\"))()")
        addGame(83038462357724, "[🎃] Dig & Clean 🧼", "[OP] Dig And Clean | Auto Clean", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Dig-and-Clean-OP-Dig-And-Clean-or-Auto-Clean-230753\"))()")
        addGame(119355263204054, "[🎃] Keyboard Wars", "Auto Word Farm", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Keyboard-Wars-Auto-Word-Farm-232162\"))()")
        addGame(122840796290491, "[🎃] Kukirin Life [Testing]", "Autofarm pizza", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Kukirin-Life-Testing-Autofarm-pizza-232075\"))()")
        addGame(120851538706364, "[🎃] Murder Duels", "[KEYLESS] Silent Aim and Enemies ESP", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Murder-Duels-KEYLESS-Silent-Aim-and-Enemies-ESP-228958\"))()")
        addGame(2961583129, "[🎃] Pass the Bomb!", "Auto Pass, Auto Avoid, Etc", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Pass-the-Bomb!-Auto-Pass-Auto-Steal-Etc-231615\"))()")
        addGame(16331682055, "[🎃] Poke Haven 🔊 18+", "PokeJam Suite V7", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Poke-Haven-18-PokeJam-Suite-V7-232157\"))()")
        addGame(10697845123, "[🎃] silly sword game", "Silly cheat menu deobfuscated, open sourced and removed key", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/silly-sword-game-Silly-cheat-menu-deobfuscated-open-sourced-and-removed-key-231491\"))()")
        addGame(16447934574, "[🎃] Soccer: Touch Football", "isane kzxl reach can reach low ms ppl", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Soccer:-Touch-Football-isane-kzxl-reach-can-reach-low-ms-ppl-231758\"))()")
        addGame(131113151337381, "[🎃] Steal a Mimiche", "Script for  by tik tok:gde_ja_rbx", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Steal-a-Mimiche-Script-for-231833\"))()")
        addGame(71600459831333, "[🎃] Street Life Remastered", "KEYLESS] OP SILENT AIM ESP AUTO BUY AUTO FARM MORE...", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Street-Life-Remastered-KEYLESS-OP-SILENT-AIM-ESP-AUTO-BUY-AUTO-FARM-MORE-232267\"))()")
        addGame(139020444733179, "[🎃] Survive Deep in the Woods", "Auto farm | Speed | Noclip | Fullbright | Fly", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Survive-Deep-in-the-Woods-Auto-farm-or-Speed-or-Noclip-or-Fullbright-or-Fly-232222\"))()")
        addGame(125503525638054, "[🎃] The Veil", "Free Script | SPOOKY HALLOWEEN EDITION", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/The-Veil-Free-Script-or-SPOOKY-HALLOWEEN-EDITION-232258\"))()")
        addGame(14259168147, "[🎃]🏀Basketball Legends🏀", "Unicheat Project:", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/UPDBasketball-Legends-Unicheat-Project:-230618\"))()")
        addGame(122446657157717, "[🎃Battlepass] Sniper Arena", "Aimbot + Esp + Misc", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/NEW-SNIPER-Sniper-Arena-Aimbot-+-Esp-+-Misc-231418\"))()")
        addGame(135856908115931, "[🎃DUELS] Murderers VS Sheriffs", "Nova | Kill All, Silent Aim, Infinite Knife, Auto Shoot, ESP", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/DUELS-Murderers-VS-Sheriffs-Nova-or-Kill-All-Silent-Aim-Infinite-Knife-Auto-Shoot-ESP-231832\"))()")
        addGame(124216119978534, "[🎃EVENT] Ride A Pet", "Minhkha hup ride a egg", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Ride-A-Pet-Minhkha-hup-ride-a-egg-229411\"))()")
        addGame(9872472334, "[🎃HLWN] Evade", "joevan shader - lite", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/HLWN-Evade-joevan-shader-lite-232498\"))()")
        addGame(79018172095137, "[🎉CLANS] Click A Cookie!", "CookieKrumb", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/CLANS-Click-A-Cookie-Cookie-232373\"))()")
        addGame(14772802900, "[🎥REPLAY] Jailbird", "Silent aim - ESP - Guns mod [KEYLESS]", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/REPLAY-Jailbird-Silent-aim-ESP-Guns-mod-KEYLESS-228948\"))()")
        addGame(131683977882464, "[🎧] GUESS THE SONG! 0.5s", "Auto guess song | Show correct answer [NO KEY]", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/GUESS-THE-SONG!-0.5s-Auto-guess-song-or-Show-correct-answer-NO-KEY-231523\"))()")
        addGame(71274660353135, "[🎨] Hide In Paintings", "Peakx |", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Hide-In-Paintings-Peak-x-or-230400\"))()")
        addGame(97572766830918, "[🎨] Hide In Pixels", "Source esp", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Hide-In-Pixels--232447\"))()")
        addGame(109792243252518, "[🏆] Endless Tower Defense", "ETDFarm", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Endless-Tower-Defense-ETDFarm-231582\"))()")
        addGame(111600158364583, "[🏖️x2] One Shot", "Best Kill Aura and more (KEYLESS)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/x2-One-Shot-Best-Kill-Aura-and-more-(KEYLESS)-229603\"))()")
        addGame(128931272139211, "[🏗️] Claw Fishing", "Speed Script", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Claw-Fishing-Speed-Script-230155\"))()")
        addGame(82524183928567, "[🐐] Build A Soccer Squad!", "Free gamepass (read description)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Build-A-Soccer-Squad!-Free-gamepass-(read-description)-230850\"))()")
        addGame(104761395312874, "[🐲Goku & Castorice🟣] Lineage Piece", "(Demo Free No key 100%)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Goku-and-Castorice-Lineage-Piece-(Demo-Free-No-key-100percent)-230655\"))()")
        addGame(102837194624695, "[👮] Tactical: Swat Simulator", "Chlorine [ Keyless ]", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Tactical:-Swat-Simulator-Chlorine-Keyless-231421\"))()")
        addGame(106383201135975, "[💎 CRYSTAL] Jump To Steal An Egg", "Auto steal", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/CRYSTAL-Jump-To-Steal-An-Egg-Auto-steal-230494\"))()")
        addGame(85050171250159, "[💩] Poop a Big Poop 🧻", "Open Source", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Poop-a-Big-Poop-Open-Source-230815\"))()")
        addGame(17516596118, "[🔥NEW MYTHIC] Hypershot", "ESP, Aimbot, Silent Aim & Triggerbot | Free, No Key", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/NEW-MYTHIC-Hypershot-ESP-Aimbot-Silent-Aim-and-Triggerbot-or-Free-No-Key-228899\"))()")
        addGame(126042865144779, "[🔥NEW SNIPER] Sniper Arena", "Silent Aim", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/NEW-SNIPER-Sniper-Arena-Silent-Aim-231674\"))()")
        addGame(7446466648, "[🔥UPDATE 14] Dragon Ball: Legendary Forces", "AFTER HOURS SCRIPT FREE", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/UPDATE-14-Dragon-Ball:-Legendary-Forces-AFTER-HOURS-SCRIPT-FREE-228918\"))()")
        addGame(2534724415, "[🗺️] Emergency Response: Liberty County", "JewHack.org (BACK)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Emergency-Response:-Liberty-County-JewHac.org-(KEYLESS)-229347\"))()")
        addGame(1730877806, "[😀HALLOWEEN PT 2] Grand Piece Online", "FREE KEYLESS CANDY DUPE AUTO FARM & AFKABLE OVERNIGHT UNDTEC", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/HALLOWEEN-PT-1-Grand-Piece-Online-FREE-KEYLESS-CANDY-DUPE-AUTO-FARM-and-AFKABLE-OVERNIGHT-UNDTEC-231219\"))()")
        addGame(82983707799188, "[🚨LIMITED] WEAPON DUELS [Murderers vs Sheriffs]", "[LIMITED]  [Murderers vs Sheriffs]", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/LIMITED-WEAPON-DUELS-Murderers-vs-Sheriffs-LIMITED-Murderers-vs-Sheriffs-232416\"))()")
        addGame(134719268825886, "[🚨NEW] Clicker Simulator! ⚡", "All in One Script (KEYLESS)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/NEW-Clicker-Simulator!-All-in-One-Script-(KEYLESS)-229200\"))()")
        addGame(79393329652220, "[🧤] Defusal", "rage script", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Defusal-rage-script-231116\"))()")
        addGame(129714054840627, "[🧪BETA] Asesinos VS Sheriffs", "Auto KILL OP", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/BETA-Asesinos-VS-Sheriffs-Auto-KILL-OP-231403\"))()")
        addGame(2686500207, "A Bizarre Day [3.5 + WEATHER REPORT]", "ESP ITEMS KEYLESS", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/A-Bizarre-Day-3.5-+-WEATHER-REPORT-ESP-ITEMS-KEYLESS-231356\"))()")
        addGame(96775630583143, "A Broken Dream", "activate all computers", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/A-Broken-Dream-activate-all-computers-232469\"))()")
        addGame(9679014784, "Afghanistan", "ESP Script (PC Only)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Afghanistan-ESP-Script-(PC-Only)-231284\"))()")
        addGame(124848984306038, "Airport Tycoon 2!", "Inf money (sorta)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Airport-Tycoon-2!-Inf-money-(sorta)-230379\"))()")
        addGame(10290376430, "An Infinite Highway", "ANY GEARS!!!", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/An-Infinite-Highway-ANY-GEARS-231987\"))()")
        addGame(109928390521457, "Anime Breaker [🏰TOWER]", "[CRAFT] | Auto Farm, Auto Walls, Auto Spins.", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Anime-Breaker-GRIMOIRES-CRAFT-or-Auto-Farm-Auto-Walls-Auto-Spins.-231215\"))()")
        addGame(114574503491412, "Anime Zero [CHAMBER] 🔒", "[ KEYLESS ]  Anime Zero Script", "loadstring(game:HttpGet(\"https://rscripts.net/raw/keyless-anime-zero-script_1790815897407_ceRY5RcrwL.txt\"))()")
        addGame(6788434697, "AniPhobia", "open source \"okay\" script", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/AniPhobia-open-source-\"okay\"-script-229886\"))()")
        addGame(116666795477778, "Antpocalypse", "Ants | SomeCheats", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Antpocalypse-or-SomeCheats-231300\"))()")
        addGame(108144748716019, "Any Roblox Game!", "vehicle fly + vehicle boost + vehicle noclip", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Any-Roblox-Game!-vehicle-fly-+-vehicle-boost-228970\"))()")
        addGame(286090429, "Arsenal", "Silent Aim  Updated", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Arsenal-Silent-Aim-Updated-229802\"))()")
        addGame(9273658706, "Backrooms", "OP SCRIPT KEYLESS | Besto", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Backrooms-OP-SCRIPT-KEYLESS-or-Besto-229781\"))()")
        addGame(1242235469, "ball and axe", "spawn blocks", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/ball-and-axe-spawn-blocks-229431\"))()")
        addGame(121461214257813, "Be an SCP or Guard [SCP-682]", "Spooky Scripts", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Be-an-SCP-or-Guard-SCP-682-Spooky-Scripts-232170\"))()")
        addGame(14713532223, "Beat The Robloxian!", "good ai version of destroy thy npcs", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Beat-The-Robloxian!-good-ai-version-of-destroy-thy-npcs-231049\"))()")
        addGame(113909829646571, "Become a Deep Sea Explorer", "Scripts", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Become-a-Deep-Sea-Explorer-Scripts-230600\"))()")
        addGame(6872265039, "BedWars [UPDATE]", "NewVape Fixed", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/BedWars-RERELEASE-NewVape-Fixed-231790\"))()")
        addGame(14449145868, "Bewitched", "BW Script", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Bewitched-Script-230055\"))()")
        addGame(5315046213, "bhop", "Strafe hud", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/bhop-Strafe-hud-229752\"))()")
        addGame(138332904385564, "BikeStars💫 (Mega Update🔥)", "BikeStars", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/BikeStars-Mega-Update-BikeStars-232460\"))()")
        addGame(2916899287, "Blackhawk Rescue Mission 5", "Ragebot,SilentAIm ,Autofarm(betaonly,RapidFire,ESP - Allison", "loadstring(game:HttpGet(\"https://rscripts.net/raw/ragebotsilentaim-autofarmbetaonlyrapidfireesp-allison_1792351249945_RK0i0PuOvW.txt\"))()")
        addGame(6137321701, "Blair", "Hypnosis | Smart Ghost Guesser, ESP & Utilities", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Blair-Hypnosis-or-Smart-Ghost-Guesser-ESP-and-Utilities-230654\"))()")
        addGame(13955927965, "Blood Zone 🎃", "Silent Aim Open Source", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Blood-Zone-Silent-Aim-Open-Source-231407\"))()")
        addGame(2753915549, "Blox Fruits", "Zero Point Auto Level, Kill Aura, XENO SUPPORT", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Blox-Fruits-Zero-Point-Auto-Level-Kill-Aura-Mob-Magnet-and-More-BETA-232179\"))()")
        addGame(118675786171302, "Blox League", "Ball Tracer Trajectory", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Blox-League-Ball-Tracer-Trajectory-230703\"))()")
        addGame(114326934417838, "Break and Steal an Egg", "Best Script Autofarm, Auto Break, Auto Steal, Keyless & More", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Break-and-Steal-an-Egg-Best-Script-Autofarm-Auto-Break-Auto-Steal-Keyless-and-More-232332\"))()")
        addGame(2551991523, "Broken Bones IV", "ReJoin Farm!", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Broken-Bones-IV-ReJoin-Farm!-229036\"))()")
        addGame(4924922222, "Brookhaven 🏡RP", "MUST BYPASSER BY N0T_Z0RO100", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Brookhaven-RP-MUST-V4-BYPASSER-BY-N0TZ0RO100-232472\"))()")
        addGame(80267208845734, "Budget Battlegrounds", "Project Yang Kill Farm", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Budget-Battlegrounds-Project-Yang-Kill-Farm-230835\"))()")
        addGame(100971017807798, "bug fixes", "Jonlib Script", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/bug-fixes-Jonlib-Script-229173\"))()")
        addGame(537413528, "Build A Boat For Treasure", "KEYLESS | Auto Gold Farm | Walk on Water | Walk Speed | More", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Build-A-Boat-For-Treasure-KEYLESS-or-Auto-Gold-Farm-or-Walk-on-Water-or-Walk-Speed-or-More-231634\"))()")
        addGame(78490532994307, "Build An Ant Empire", "[keyless] auto buy, auto upgrade, auto event", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Build-An-Ant-Empire-keyless-auto-buy-auto-upgrade-auto-event-232200\"))()")
        addGame(105011592530400, "Build and Kill Zombies", "Auto Drive, Auto Roll, Auto Build and Skills | No Key", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Build-and-Kill-Zombies-Auto-Drive-Auto-Roll-Auto-Build-and-Skills-or-No-Key-230577\"))()")
        addGame(123720558354386, "Build the Pyramid!", "(opensrc)  Auto farm with no walking, multi-place, more", "loadstring(game:HttpGet(\"https://rscripts.net/raw/opensrc-auto-farm-with-no-walking-multi-place-more_1790985145991_wJOesDcCUl.txt\"))()")
        addGame(11005222274, "Build to Survive the Robots", "zombware", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Build-to-Survive-the-Robots-anoware-231857\"))()")
        addGame(1554960397, "Car Dealership Tycoon  [🎃]", "Brzzz_HooK | Auto Farm | Halloween 2026", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Car-Dealership-Tycoon-BrzzzHooK-or-Auto-Farm-or-Halloween-2026-232494\"))()")
        addGame(130906410042392, "Cat Battles 🐾", "[keyless] OP SCRIPT", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Cat-Battles-keyless-OP-SCRIPT-232474\"))()")
        addGame(118535152903705, "CAT DEFENSE [Alpha]", "scripty yeyeye", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/CAT-DEFENSE-Alpha-scripty-yeyeye-231748\"))()")
        addGame(138342176561665, "Cat in the Hat Escape", "Unlock all cat skins 4 free", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Cat-in-the-Hat-Escape-Unlock-all-skins-4-free-229380\"))()")
        addGame(7041939546, "Catalog Avatar Creator", "Copy Catalog Asset ID", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Catalog-Avatar-Creator-Copy-Catalog-Asset-ID-232493\"))()")
        addGame(6686932749, "Ceratosaurus | Prehistoria!", "Pr-historia melhor script", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Ceratosaurus-or-Prehistoria!-Pr-historia-melhor-script-231226\"))()")
        addGame(10941514720, "Chaos Jenga", "Auto Farm, Ram & Ghost Floor", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Chaos-Jenga-auto-farm-232216\"))()")
        addGame(109680150977787, "Chaotic Battlegrounds", "Mod Menu", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Chaotic-Battlegrounds-Mod-Menu-230374\"))()")
        addGame(137233438285284, "Chicken Farm 🐣", "| OP | Keyless auto farm, auto upgrade e.t.c", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Chicken-Farm-or-OP-or-Keyless-auto-farm-auto-upgrade-e.t.c-230328\"))()")
        addGame(103363457515322, "Chop A Forest", "[ KEYLESS ] Chop a Forest Script", "loadstring(game:HttpGet(\"https://rscripts.net/raw/keyless-chop-a-forest-script_1792096937191_a8jlakBv9k.txt\"))()")
        addGame(130793019, "Classic Sonic Simulator V13.2", "CSS UnLocker", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Classic-Sonic-Simulator-V132-CSS-UnLocker-232355\"))()")
        addGame(85738654635245, "Climb For Animals Eggs🥚", "[KEYLESS] OP AUTO FARM AUTO UPGRADE AUTO HATCH AUTO PLACE", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Climb-For-Animals-Eggs-KEYLESS-OP-AUTO-FARM-AUTO-UPGRADE-AUTO-HATCH-AUTO-PLACE-232159\"))()")
        addGame(93934100402512, "Clover Time [BETA RELEASE]", "[ KEYLESS ] Clover Time Script", "loadstring(game:HttpGet(\"https://rscripts.net/raw/keyless-clover-time-script_1790925585004_VK9zNny4rt.txt\"))()")
        addGame(13687899540, "Cold War", "Allison.rip Cold War - Silent Aim - Esp - Car Killer -Keyles", "loadstring(game:HttpGet(\"https://rscripts.net/raw/allisonrip-cold-war-silent-aim-esp-car-killer-keyles_1792270704596_X2R2q0HpnF.txt\"))()")
        addGame(91004304309345, "Collect All Eggs", "Best Autofarm", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Collect-All-Eggs-Best-Autofarm-230429\"))()")
        addGame(12781347095, "Color Hide and Seek", "Auto win RANOYSD", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Color-Hide-and-Seek-Auto-win-RANOYSD-231048\"))()")
        addGame(101770480176177, "Command An Army", "[⚔️ BEST KEYLESS] Command An Army - AUTO FARM & KILL AURA &", "loadstring(game:HttpGet(\"https://rscripts.net/raw/best-keyless-command-an-army-auto-farm-and-kill-aura-and_1790962704683_lawUe2VK4p.txt\"))()")
        addGame(1818, "Crossroads", "save script delta executor", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Crossroads-save-script-delta-executor-228961\"))()")
        addGame(16893875714, "Crossroads Without Cooldown", "crash server (with 4 tool)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Crossroads-Without-Cooldown-crash-server-(with-4-tool)-228886\"))()")
        addGame(116495829188952, "Dead Rails", "[NO KEY] *NEW 2026* BEST  Script", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Dead-Rails-NO-KEY-NEW-2026-BEST-Script-232173\"))()")
        addGame(13438553315, "Decaying Winter", "Teddy's V0.1 | Open-source", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Decaying-Winter-Teddy's-V1-230593\"))()")
        addGame(102053304052438, "DELTARUNE Fight [UPDATE]", "| SW", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/DELTARUNE-Fight-UPDATE-or-Pink-230406\"))()")
        addGame(12880465992, "Deltarune: Connected", "Fixed Free client Morphs Gui for", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Deltarune:-Connected-Free-client-Morphs-Gui-for-228910\"))()")
        addGame(6878438976, "Developer Inc. 🤵", "Deobfuscated \"149$/sec farm\"", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Developer-Inc.-Deobfuscated-\"149dollarsec-farm\"-231719\"))()")
        addGame(121831322352666, "Dig For Eggs", "Best Auto Dig, Auto Farm Secret Eggs + KEYLESS", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Dig-For-Eggs-Best-Auto-Dig-Auto-Farm-Secret-Eggs-+-KEYLESS-230507\"))()")
        addGame(13924946576, "dingus", "NPC ESP [Matcha External]", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/dingus-Matcha-NPC-ESP-231145\"))()")
        addGame(94009908234110, "dogs🎃", "le rouge  script", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/dogs-le-rouge-script-232031\"))()")
        addGame(121165298854655, "DON'T LET HIM IN [NEW MONSTER]", "Alo's Script -  (Keyless)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/DONT-LET-HIM-IN-NEW-MONSTER-Made-by-alos-232172\"))()")
        addGame(6516141723, "DOORS 👁️", "New Best Doors Script", "loadstring(game:HttpGet(\"https://rscripts.net/raw/new-best-doors-script_1789986234734_bq0n2FUj6t.txt\"))()")
        addGame(2499981932, "Dragon Blox GT", "Auto train (PC Only)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Dragon-Blox-GT-Auto-train-(PC-Only)-230957\"))()")
        addGame(3351674303, "Driving Empire [✨RAM DEBUT✨ ]", "YANZ Best OP", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Driving-Empire-RIVIAN-DEBUT-YANZ-Best-OP-230590\"))()")
        addGame(16480898254, "Eat the World", "NO KEY AUTO FARM MAGNET MONEYS AUTO REWARDS OPEN SOURCE", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Eat-the-World-NO-KEY-AUTO-FARM-MAGNET-MONEYS-AUTO-REWARDS-OPEN-SOURCE-231916\"))()")
        addGame(7711635737, "Emergency Hamburg", "SorinScripts - Jobfarm Script for", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Emergency-Hamburg-SorinScripts-Jobfarm-Script-for-231581\"))()")
        addGame(3678761576, "ENTRENCHED WW1 🥀", "Aimbot ESP Smooth Aim Auto Aim Keyless Entrenched", "loadstring(game:HttpGet(\"https://rscripts.net/raw/aimbot-esp-smooth-aim-auto-aim-keyless-entrenched_1790614219146_2rN3M0dPf8.txt\"))()")
        addGame(119579217517090, "Escape Waves For Lucky Blocks", "Best script by tik tok:Gde_ja_rbx", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Escape-Waves-For-Lucky-Blocks-Best-script-by-tik-tok:Gde_ja_rbx-231393\"))()")
        addGame(116271122728938, "EXCHANGE EXCHANGE - RJ FPS", "aimbotzinho", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/EXCHANGE-EXCHANGE-RJ-FPS-aimbotzinho-230334\"))()")
        addGame(137095720966003, "Film Animals [1-6 Player]", "Not Really OP Script But Good Enough (Keyless)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Film-Animals-1-6-Player-Not-Really-OP-Script-But-Good-Enough-Keyless-232024\"))()")
        addGame(99925503388128, "Fishing Master", "[ KEYLESS ] Fishing Master Script", "loadstring(game:HttpGet(\"https://rscripts.net/raw/keyless-fishing-master-script_1790752393133_NgKwTMKNFf.txt\"))()")
        addGame(893973440, "Flee the Facility", "script", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Flee-the-Facility-script-232177\"))()")
        addGame(18667984660, "Flex Your FPS And Ping!", "fps cap script", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Flex-Your-FPS-And-Ping!-fps-cap-script-231247\"))()")
        addGame(18695865484, "Flex Your Ping And FPS!", "FPS Spoofer", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Flex-Your-Ping-And-FPS-FPS-Spoofer-232012\"))()")
        addGame(6961824067, "Fling Things and People", "Resonance V2.9", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Fling-Things-and-People-Resonance-V29-232404\"))()")
        addGame(738339342, "Flood Escape 2 🌊", "[KEYLESS] Auto FE2", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Flood-Escape-2-KEYLESS-Auto-FE2-230140\"))()")
        addGame(99001115434148, "Fluxo PVP [MATCHMAKING]", "Aimbot Open Source", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Fluxo-PVP-MATCHMAKING-AimbotOpen-Source-229155\"))()")
        addGame(82866880824588, "Football Fusion 3", "[KEYLESS + BALL MAGNET + AUTO QB ]", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Football-Fusion-3-KEYLESS-+-BALL-MAGNET-+-AUTO-QB-230267\"))()")
        addGame(117020342702668, "Foresters 🌳 [RELEASE]", "[KEYLESS]  - Auto Everything", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Foresters-RELEASE-KEYLESS-Auto-Everything-232299\"))()")
        addGame(70386316385228, "FORTBLOX ⭐", "AIM + ESP", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/FORTBLOX-AIM-+-ESP-230973\"))()")
        addGame(93091759101123, "FPS🔥AirDrop Arena [S4]🔥", "Silent Aim", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/FPSAirDrop-Arena-S4-Silent-Aim-229165\"))()")
        addGame(100661692738190, "FPV Drone Battlefield", "Wall Bang + ESP (KEYLESS & OPENSOURCE)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/FPV-Drone-Battlefield-Wall-Bang-+-ESP-(KEYLESS-and-OPENSOURCE)-229586\"))()")
        addGame(4845347966, "Frogge", "Auto revive", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Frogge-Auto-232285\"))()")
        addGame(5310443220, "GOD TYCOON", "AutoCollect & AutoClick", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/GOD-TYCOON-AutoCollect-and-AutoClick-232104\"))()")
        addGame(18335956021, "Grand Blue [Early Access]", "UI Based - Working - No KeySystem", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Grand-Blue-Early-Access-Fully-Working-No-Key-230301\"))()")
        addGame(891852901, "Greenville RP (⭐AUDI + SHELBY RELATED + RACES!)", "Spark Autofarm", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Greenville-RP-(AUDI-+-SHELBY-RELATED-+-RACES!)-Spark-Autofarm-231713\"))()")
        addGame(97506470800237, "Guess the Anime Color", "Autofarm money keyless best", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Guess-the-Anime-Color-Autofarm-money-keyless-best-231915\"))()")
        addGame(106683702021527, "Guess the Slapper", "Sp1ng Script", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Guess-the-Slapper-Sp1ng-Script-232016\"))()")
        addGame(109294084812367, "GUI Creator [  not available ]", "convert Require (not script just ui)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/GUI-Creator-not-available-convert-Require-(not-script-just-ui)-228871\"))()")
        addGame(128715403389835, "Hamster Village🐹", "Best script", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Hamster-Village-HamsterVillage-231157\"))()")
        addGame(108180124695820, "Highway Drifting: Hajwala", "auto farm cash", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Highway-Drifting:-Hajwala-auto-farm-cash-229558\"))()")
        addGame(77463332823746, "Hood Rivals", "Silent Aim Opensource", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Hood-Rivals-Silent-Aim-Opensource-228843\"))()")
        addGame(99523974184597, "HotDog Canyon 🌭  (Obby king)👑", "Spawn Blackhole", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/HotDog-Canyon-(Obby-king)-Spawn-Blackhole-231629\"))()")
        addGame(109677451663339, "HOUR 12 🕛 [ANOMALY]", "Anomaly Detector", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/HOUR-12-ANOMALY-Anomaly-Detector-228857\"))()")
        addGame(91445552037955, "HUSH [Zombie Extraction]", "Silent Aim FLY ESP Lootables Zombies Players", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/HUSH-Zombie-Extraction-Silent-Aim-FLY-ESP-Lootables-Zombies-Players-232137\"))()")
        addGame(107535308163741, "Huss Valley", "Huss Valley | KEYLESS Auto Dodge + Cooldown Slider", "loadstring(game:HttpGet(\"https://rscripts.net/raw/huss-valley-or-keyless-auto-dodge-cooldown-slider_1791627725431_7FDRqBDx5p.txt\"))()")
        addGame(73897506680154, "Idle Mafia Game", "AUTOMATION, MARKET SNIPER, AUTO LIST, ETC KEYLESS", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Idle-Mafia-Game-script-keyless-new-230614\"))()")
        addGame(126987974021910, "Illegal Soccer", "BEST KEYLESS ⚽ Illegal Soccer [AUTO PLAY + AUTO SHOOT 🔥]", "loadstring(game:HttpGet(\"https://rscripts.net/raw/best-keyless-illegal-soccer-auto-play-auto-shoot_1790905497218_5PhK7lfvq0.txt\"))()")
        addGame(16993432698, "Impossible Squid Game Glass Bridge 2", "Esp bridge, god mode", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Impossible-Squid-Game-Glass-Bridge-2-Esp-bridge-god-mode-231203\"))()")
        addGame(9192423027, "Industrialist", "OP AI Helper Bot (Keyless/OpenSource)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Industrialist-OP-AI-Helper-Bot-(KeylessOpenSource)-229071\"))()")
        addGame(88241416576753, "INTRUDERS 👁", "Highlight the Monster", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/INTRUDERS-Highlight-the-Monster-231757\"))()")
        addGame(12805830692, "IQ Obby", "Scripy", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/IQ-Obby-Scripy-230032\"))()")
        addGame(606849621, "Jailbreak", "Codecoat", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Jailbreak-Codecoat-230496\"))()")
        addGame(99595206014058, "Jump To Steal Phonks", "- farm", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Jump-To-Steal-Phonks-farm-232282\"))()")
        addGame(621129760, "KAT", "Kitty.lol", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/KAT-.lol-228887\"))()")
        addGame(79548014923991, "KAZAKH TOWER 🌟 [💙💛ҚАЗАҚША💛💙] 🇰🇿", "Chat Spammer", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/KAZAKH-TOWER-KHAZAKHShA-Chat-Spammer-230668\"))()")
        addGame(292628125, "Keystone", "auto collect Pumpkins", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Keystone-auto-collect-Pumpkins-231033\"))()")
        addGame(138315746921381, "KJ game (Remake) [FREE SHINJI]", "Reset colldowns imhate_frends user yall", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/KJ-game-(Remake)-FREE-SHINJI-Reset-colldowns-231732\"))()")
        addGame(112731528776884, "KNIFE DUELS", "Keyless Mobile Support FemHook By panda22", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/KNIFE-DUELS-Keyless-Mobile-Support-FemHook-By-panda22-230031\"))()")
        addGame(14747334292, "Kohls Admin House X", "KohlsNoob", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Kohls-Admin-House-X-KohlsNoob-229251\"))()")
        addGame(85967844112283, "Last Stop [Beta]", "Auto Farm Ocean Token", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Last-Stop-Beta-Auto-Farm-Ocean-Token-229347\"))()")
        addGame(3101667897, "Legends Of Speed ⚡", "VOID STAR v2.6.1  L.O.S", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Legends-Of-Speed-VOID-STAR-v2.5.0-S.O.L-229110\"))()")
        addGame(15278322858, "Lexington & Concord", "Silent aim keyless & upd", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Lexington-and-Concord-Silent-aim-keyless-230344\"))()")
        addGame(72659788689464, "Life in Prison", "keyless aimbot script (Fixed)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Life-in-Prison-keyless-aimbot-script-228896\"))()")
        addGame(109530157755211, "Lift a Cube", "LaCube | Auto Train&Cube", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Lift-a-Cube-LaCube-or-Auto-TrainandCube-229877\"))()")
        addGame(6737970321, "Livetopia 🏡 RP", "RX SPAMMER S19", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Livetopia-RP-RX-SPAMMER-S19-229044\"))()")
        addGame(79148536770575, "Ludo Arena! 🎲 [2-4 Players]", "AUTO PLAY", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Ludo-Arena-2-4-Players-LUDO-AUTO-PLAY-232024\"))()")
        addGame(106251887264209, "Math Glass Bridge 🧠", "Show Path", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Math-Glass-Bridge-Show-Path-228969\"))()")
        addGame(16518256559, "Mega Obby Fun", "peppa pig gui", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Mega-Obby-Fun-peppa-pig-gui-232236\"))()")
        addGame(15546218972, "MIC UP 🔊 18+", "N0IR", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/MIC-UP-18+-N0IR-231534\"))()")
        addGame(8112577171, "Misi's Playground", "MSPlayground | Admin Panel FE", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Misi's-Playground-MSPlayground-or-Admin-Panel-FE-228892\"))()")
        addGame(93017634738276, "MMV", "forge", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/MMV-forge-231009\"))()")
        addGame(122702016864571, "Murder Infinite", "Mod Menu (Good)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Murder-Infinite-Mod-Menu-(Good)-231410\"))()")
        addGame(189707, "Natural Disaster Survival", "Reyzn X | New Version super OP", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Natural-Disaster-Survival-HzReyzn-Hub-or-Last-Update-229523\"))()")
        addGame(10118559731, "nico's nextbots 🌸", "Nicos Menu V2", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/nico's-nextbots-Nicos-Menu-V2-230904\"))()")
        addGame(21532277, "Notoriety: A PAYDAY® Experience", "KEYLESS Allison-Notoriety Silent Aim, Item Spawner, NPC ESP", "loadstring(game:HttpGet(\"https://rscripts.net/raw/keyless-allison-notoriety-silent-aim-item-spawner-npc-esp_1792270778188_8Ilir7pevr.txt\"))()")
        addGame(14753017334, "obby for free owner admin", "Lazy Script V4 | Better Ver", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/obby-for-free-owner-admin-Lazy-Script-V2-or-Rayfield-228994\"))()")
        addGame(140322231839637, "ONE TAP PISTOLS [UPDATE]", "BEST  Script OPEN SOURCE", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/ONE-TAP-PISTOLS-UPDATE-BEST-Script-OPEN-SOURCE-231122\"))()")
        addGame(18382602608, "Our Execution [V7.8a.0: Medical Aid & More]", "Menu Gui", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Our-Execution-V7.8a.0:-Medical-Aid-and-More-Menu-Gui-230837\"))()")
        addGame(122700472919801, "PANTSIR", "Auto", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/PANTSIR-Auto-230008\"))()")
        addGame(128718867767713, "Parkour Pandemic [UPDATE 2!]", "script (not made by me)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Parkour-Pandemic-UPDATE-2!-script-(not-made-by-me)-231316\"))()")
        addGame(116701845804918, "Peel THE Potato", "[ KEYLESS ] Peel THE Potato Script", "loadstring(game:HttpGet(\"https://rscripts.net/raw/keyless-peel-the-potato-script_1791344601561_HBr4qffX1r.txt\"))()")
        addGame(118845698633260, "Pet Store Tycoon", "[KEYLESS]Anti-AFK, Hide Menu, Store", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Pet-Store-Tycoon-KEYLESSAnti-AFK-Hide-Menu-Store-232117\"))()")
        addGame(86559789336379, "Phonk Admin Tower 🎵 [8 ROBUX]", "SFLY TP WIN", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Phonk-Admin-Tower-8-ROBUX-SFLY-TP-WIN-228995\"))()")
        addGame(101999883467300, "Piano Rhythm Tiles", "[KEYLESS] NICE FEATURES", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Piano-Rhythm-Tiles-KEYLESS-NICE-FEATURES-232142\"))()")
        addGame(4623386862, "Piggy [MR. STITCHY]", "Simple Control  (OpenSourse)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Piggy-SEASON-9-FRIGHT-NIGHT-Simple-Control-(OpenSourse)-231199\"))()")
        addGame(18172550962, "Pixel Blade [Early Access]", "[ KEYLESS ] Pixel Blade Script", "loadstring(game:HttpGet(\"https://rscripts.net/raw/keyless-pixel-blade-script_1791562365744_gMUqbOiynJ.txt\"))()")
        addGame(138110382920220, "Pixel Conquest", "PIXEL CONQUEST SCRIPT OP AUTO", "loadstring(game:HttpGet(\"https://rscripts.net/raw/pixel-conquest-script-op-auto_1791694107354_5jBN6SBJr5.txt\"))()")
        addGame(126256942507957, "Pixel Lineage [HALLOWEEN]", "[ KEYLESS ] Pixel Lineage Script", "loadstring(game:HttpGet(\"https://rscripts.net/raw/keyless-pixel-lineage-script_1791609363890_uk58S8QmYt.txt\"))()")
        addGame(12411473842, "Pressure", "stuff", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Pressure-stuff-230718\"))()")
        addGame(155615604, "Prison Life", "NightFall", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Prison-Life-NightFall-232019\"))()")
        addGame(9093954913, "Project slayer 2 👺", "[Major Fix] AutoFarm, Auto Boss, Keyless , Undetected & More", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Project-slayer-2-Best-Script-AutoFarm-Auto-Boss-Keyless-and-More-228870\"))()")
        addGame(121903154323395, "PURSUITCORE", "Custom Ability: Speed Boost!", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/PURSUITCORE-Custom-Ability-Speed-Boost-232167\"))()")
        addGame(17783560582, "Pyro Playground 💥 [UPDATE]", "Pyro Panel For", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Pyro-Playground-UPDATE-Pyro-Panel-For-228971\"))()")
        addGame(6165420832, "Ragdoll Engine", "obunga jumpscare", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Ragdoll-Engine-obunga-jumpscare-228854\"))()")
        addGame(123554411050796, "Random Tool but bad", "RTools | Tool Manager FE", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Random-Tool-but-bad-RTools-or-Tool-Manager-FE-229027\"))()")
        addGame(131652231424227, "Ride a Dino", "by ASH", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Ride-a-Dino-by-ASH-232346\"))()")
        addGame(104050046639813, "Ride A Fish 🐟", "KZBR TOOLS | AUTU FARM", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Ride-A-Fish-KZBR-TOOLS-or-AUTU-FARM-232197\"))()")
        addGame(113745337705295, "Riot City 🚨 Prison Escape", "Riot City slient aim", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Riot-City-Prison-Escape-Riot-City-slient-aim-231267\"))()")
        addGame(17625359962, "RIVALS [❄️FREEZE RAY❄️]", "[OPENSOURCE] Unnamed | Silent Aim, Triggerbot, ESP, etc", "loadstring(game:HttpGet(\"https://rscripts.net/raw/opensource-unnamed-or-silent-aim-triggerbot-esp-etc_1791816900897_HuswLNg4GD.txt\"))()")
        addGame(15281176914, "RNG Fights", "kaiser rng", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/RNG-Fights-kaiser-rng-231406\"))()")
        addGame(10851599, "Roblox Talent Show ☀️", "Fcker", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Roblox-Talent-Show-Fcker-230493\"))()")
        addGame(294790062, "Roblox Titanic", "Infinite Health Open Source", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Roblox-Titanic-Infinite-Health-Open-Source-230200\"))()")
        addGame(139717576471404, "RoChess!", "WHITELOTUS | AUTOPLAY AUTOASSIST & MANY MORE", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/RoChess-WHITELOTUS-or-AUTOPLAY-AUTOASSIST-and-MANY-MORE-232269\"))()")
        addGame(90920025162454, "Roll a Fisherman 🎣", "[KEYLESS] Auto Rebirth, Auto Collect, Wheel Spin, Anti AFK", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/SEALS-Roll-a-Fisherman-KEYLESS-Auto-Rebirth-Auto-Collect-Wheel-Spin-Anti-AFK-230270\"))()")
        addGame(73904017172892, "Roll in a Cart", "Auto-Farm , Inf money and teleport to checkpoints", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Roll-in-a-Cart-Auto-Farm-Inf-money-and-teleport-to-checkpoints-229193\"))()")
        addGame(15363062864, "ROOMS: REVISITED 📦", "ROOMS REVISITED SCRIPT", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/ROOMS:-REVISITED-script-(Read-the-description!!)-231524\"))()")
        addGame(118418618261207, "RUNAWAYS [beta]", "super op basic  script", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/RUNAWAYS-beta-super-op-basic-script-229317\"))()")
        addGame(7253149844, "SCP Games and SCP Monsters", "Control The Scps/Npcs", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/SCP-Games-and-SCP-Monsters-Control-The-ScpsNpcs-231835\"))()")
        addGame(5041144419, "SCP: Roleplay", "OVERDOSE.GG - NO KEY", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/SCP:-Roleplay-OVERDOSE.GG-NO-KEY-230188\"))()")
        addGame(76427445314955, "Scream City 2 🎃", "DH  (FREE SCRIPT)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Vice-City-2-DH-(FREE-SCRIPT)-230422\"))()")
        addGame(97927337336367, "SCROOMS 🍄", "[ KEYLESS ] SCROOMS Script", "loadstring(game:HttpGet(\"https://rscripts.net/raw/keyless-scrooms-script_1791654716697_KjfbtT5vh1.txt\"))()")
        addGame(16039690331, "Secret Killer", "Asesino Secreto GUI", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Secret-Killer-Asesino-Secreto-GUI-231031\"))()")
        addGame(18336470541, "Seeker vs Hider", "Lasion (keyless & free)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Seeker-vs-Hider-Lasion-(keyless-and-free)-229030\"))()")
        addGame(79268393072444, "Sell Lemons 🍋", "Lemon Collector", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/W2-Sell-Lemons-Lemon-Collector-230289\"))()")
        addGame(4616652839, "Shindo Life [250]", "Silent Aim  mobile", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Shindo-Life-250-Silent-Aim-mobile-230442\"))()")
        addGame(101590266647094, "Shoot and Eat RETROs", "auto shoot everyone", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Shoot-and-Eat-RETROs-auto-shoot-everyone-231280\"))()")
        addGame(79226825467411, "Shuffle an Egg", "[KEYLESS] Auto Play, Cup ESP, Auto Upgrade", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Shuffle-an-Egg-KEYLESS-Auto-Play-Cup-ESP-Auto-Upgrade-230868\"))()")
        addGame(114226238552788, "Sky Fighters", "Op keyless auto qte fly speed jump more", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Sky-Fighters-Op-keyless-auto-qte-fly-speed-jump-more-230830\"))()")
        addGame(111695898741609, "Slap Laser Obby", "Wins auto farm", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Slap-Laser-Obby-Wins-auto-farm-231167\"))()")
        addGame(16205713724, "Slayers 2", "[ KEYLESS ] Slayers 2 SCRIPT", "loadstring(game:HttpGet(\"https://rscripts.net/raw/keyless-slayers-2-script_1789996373900_tGjurpxbf2.txt\"))()")
        addGame(15532962292, "Sol's RNG [ Eon 1-29 ]", "KEYLESS SCRIPT OP", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Sols-RNG-Eon-1-29-My-script-232194\"))()")
        addGame(10179538382, "South Bronx: The Trenches❗", "aurore script", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/South-Bronx:-The-Trenches-aurore-script-229013\"))()")
        addGame(14826163936, "Space Pioneers [ALPHA 10]", "Inf Resources (  )", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Space-Pioneers-ALPHA-10-Inf-Resources-232068\"))()")
        addGame(104151188892520, "Spelling Glass Bridge 🔊", "script", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Spelling-Glass-Bridge-unlimited-money!!-228872\"))()")
        addGame(17664585395, "Spelling Race", "Auto Type Set Time Double Gems Keyless Spelling Race", "loadstring(game:HttpGet(\"https://rscripts.net/raw/auto-type-set-time-double-gems-keyless-spelling-race_1790602490249_5MnF5iqiHJ.txt\"))()")
        addGame(97528307481736, "Split Sea For Brainrots", "Duper And Auto collecter", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Split-Sea-For-Brainrots-Duper-And-Auto-collecter-229527\"))()")
        addGame(76503495566299, "Steal a Chicken", "Auto Farm, Teleport, Any Many more! | No Key!", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Steal-a-Chicken-or-No-Key-230131\"))()")
        addGame(86754403332185, "Steal a Clown", "Bless - Insta Steal", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Steal-a-Clown-Bless-or-229062\"))()")
        addGame(129039408367330, "Steal a Soccer Player", "PATTI DEV", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Steal-a-Soccer-Player-PATTI-DEV-232485\"))()")
        addGame(76377501906469, "Steal an Anime Egg!", "KZBR TOOLS | AUTO +", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/UPD-2-Steal-an-Anime-Egg!-KZBR-TOOLS-or-AUTO-+-229206\"))()")
        addGame(107778070777162, "Steal an Egg", "[Halloween][v1.6.0][Goha]", "loadstring(game:HttpGet(\"https://rscripts.net/raw/halloweenv160goha_1792337160909_XTFTPrpJ3n.txt\"))()")
        addGame(75561437976025, "Steal and Escape Police! 🚓", "Peakx |", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Steal-and-Escape-Police-Peakx-or-231978\"))()")
        addGame(126344057129519, "Steal and Ride", "[ KEYLESS ] Steal and Ride Script", "loadstring(game:HttpGet(\"https://rscripts.net/raw/keyless-steal-and-ride-script_1791613963943_9e5qdsZt9I.txt\"))()")
        addGame(82081400078378, "Steal ASMR!", "NEW AUTO STEAL METHOD", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Steal-ASMR-NEW-AUTO-STEAL-METHOD-231939\"))()")
        addGame(119925538689885, "Steal Or Die [UPDATE!]", "Best  Script", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Steal-Or-Die-UPDATE-best-script-232221\"))()")
        addGame(696347899, "Stepford County Railway 🚉", "Auto Farm, Autopilot, Bypass SPAD, and more", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Stepford-County-Railway-Autopilot-231300\"))()")
        addGame(136372246050123, "STICK BATTLES 🍢", "Kill aura-auto coins-ant afk=FARM COINS E PLAYER AFK", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/STICK-BATTLES-Combate-de-varas-230327\"))()")
        addGame(117246040666343, "Stick Fight: Roblox Edition", "SFight | SomeCheats", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Stick-Fight-Roblox-Edition-SFight-or-SomeCheats-232320\"))()")
        addGame(135889880932940, "Survive 7 Days In Desert 🌵", "7 Days In Desert", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Survive-7-Days-In-Desert-7-Days-In-Desert-232424\"))()")
        addGame(127082754898219, "Survive Lava for Animals", "Instant steal", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Survive-Lava-for-Animals-Instant-steal-231781\"))()")
        addGame(94276320445251, "Terraform", "envsploit", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Terraform-envsploit-231346\"))()")
        addGame(121455614269435, "TGI - FPS Shot Exchange", "ANON HUSH Aimbot", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/TGI-FPS-Shot-Exchange-ANON-HUSH-Aimbot-229042\"))()")
        addGame(10834586502, "The Battle Bricks", "Game-Kid {Carnival Disaster}", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/The-Battle-Bricks-Game-KidStage-Carnival-Disaster-231005\"))()")
        addGame(11137575513, "The Chosen One", "Tachyon Ware OPENSOURCED (AI MADE)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/The-Chosen-One-Tachyon-Ware-OPENSOURCED-(AI-MADE)-231287\"))()")
        addGame(13664698400, "The Classic Soccer", "NEUER TCS V1", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/The-Classic-Soccer-NEUER-TCS-V1-231019\"))()")
        addGame(123516846332753, "The Glass Bridge", "ESP Gl*", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/The-Glass-Bridge-ESP-Gl*-229283\"))()")
        addGame(74205509034203, "The Hunt: Roblox 20", "ZenithUtility | Roblox 20th Event", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/The-Hunt:-Roblox-20-ZenithUtility-or-Roblox-20th-Event-229026\"))()")
        addGame(102871156420149, "The Lost Front", "FemHook", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/The-Lost-Front-FemHook-228860\"))()")
        addGame(6243699076, "The Mimic", "Toolbox for Roblox (BOOK 2 CHAPTER 4) [Keyless]", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/The-Mimic-Toolbox-for-Roblox-Keyless-228860\"))()")
        addGame(2413927524, "The Rake REMASTERED", "Fake \"Infinite Stamina\"", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/The-Rake-REMASTERED-Rake-\"Infinite-Stamina\"-231822\"))()")
        addGame(124780436553035, "The Staircase [Alpha v1.14]", "SCP Immunity, Auto Descend, ESP, Fullbright, & More", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/The-Staircase-Alpha-v1.14-SCP-Immunity-Auto-Descend-ESP-Fullbright-and-More-230591\"))()")
        addGame(10449761463, "The Strongest Battlegrounds", "Best keyless tsb script", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/The-Strongest-Battlegrounds-Best-keyless-tsb-script-231002\"))()")
        addGame(17805166690, "The Undead Coming (2026)", "Server Crash [Please read the description]", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/The-Undead-Coming-2026-Server-Crash-Script-232077\"))()")
        addGame(128039018996175, "The Walking Dead Online", "EXTERNAL.VIP BEST *FREE TWD 3 SCRIPT* NOCLIP SILENT AIM", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/The-Walking-Dead-Online-EXTERNALVIP-BEST-FREE-TWD-3-SCRIPT-NOCLIP-SILENT-AIM-232134\"))()")
        addGame(488667523, "Those Who Remain", "[Keyless]   updated V1.5", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Those-Who-Remain-Keyless-updates-V1.5-228844\"))()")
        addGame(90796158856427, "Throw An Egg", "[ KEYLESS ] Throw an Egg Script", "loadstring(game:HttpGet(\"https://rscripts.net/raw/keyless-throw-an-egg-script_1791644330876_SS3EZQHa7X.txt\"))()")
        addGame(100178831086674, "TimeBomb AnkleBreak!", "Nexus time blast", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/TimeBomb-AnkleBreak-Nexus-time-blast-232189\"))()")
        addGame(1962086868, "Tower of Hell", "infinite jump", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Tower-of-Hell-infinite-jump-231383\"))()")
        addGame(12141819334, "Trench Combat 💥", "script overstate1337 combat", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Trench-Combat-script-overstate1337-combat-230608\"))()")
        addGame(6654918151, "Trench War", "LuisBR4", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Trench-War-LuisBR4-229065\"))()")
        addGame(72169370437173, "Tribes 3v3 [RANKED!]", "Safe-SlientAim open-source", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Tribes-3v3-RANKED-Safe-SlientAim-open-source-232472\"))()")
        addGame(103037106396302, "TROLL Hug Tower", "BEST  SCRIPT KEYLESS", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/TROLL-Hug-Tower-BEST-SCRIPT-KEYLESS-229079\"))()")
        addGame(12377995562, "Trollge Incident Fights Reborn", "Combat Bot TIFR (Open Source)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Trollge-Incident-Fights-Reborn-Combat-Bot-TIFR-(Open-Source)-230463\"))()")
        addGame(17122706530, "Tuantu's lobotomization branches", "Lobotomization Project", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Tuantu's-lobotomization-branches-Lobotomization-Project-231598\"))()")
        addGame(6161235818, "Twisted [BETA]", "CataClysm", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Twisted-BETA-CataClysm-228952\"))()")
        addGame(128107871641118, "Type To Kill", "OP KEYLESS", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Type-To-Kill-OP-KEYLESS-230447\"))()")
        addGame(8146731988, "Ultra Power Tycoon", "UPT No key script 2026", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Ultra-Power-Tycoon-UPT-No-key-script-2026-231279\"))()")
        addGame(112050560592995, "Undertale Multiverse Simulator 1.5", "GodMode for ums 1.5", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Undertale-Multiverse-Simulator-1.5-GodMode-for-ums-1.5-229611\"))()")
        addGame(73962871684030, "UNPUBLISHED [PRE-ALPHA]", "BEST SCRIPT OUT FREE KEYLESS SOURCE CODE", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/UNPUBLISHED-PRE-ALPHA-BEST-SCRIPT-OUT-FREE-KEYLESS-SOURCE-CODE-229818\"))()")
        addGame(15784744207, "Valley Prison", "Gun spawner (Free & keyless)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Valley-Prison-Gun-spawner-(Free-and-keyless)-231207\"))()")
        addGame(104526416639079, "Verity's Game", "Verity Giver v2 Op", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Verity's-Game-Verity-Giver-v2-Op-228881\"))()")
        addGame(127117970922739, "voice chat hangout", "Give btools", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/voice-chat-hangout-Give-btools-232408\"))()")
        addGame(5044920251, "Wall Hop Practice", "wallhop2k", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Wall-Hop-Practice-wallhop2k-228848\"))()")
        addGame(99258831560211, "Wega's Super Custom Challenge", "Collect All Ludwigs", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Wega's-Super-Custom-Challenge-Collect-All-Ludwigs-230382\"))()")
        addGame(109129552698918, "WEST WOOD: REMAKE [BETA]", "Script For Game", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/WEST-WOOD:-REMAKE-BETA-Script-For-Game-229063\"))()")
        addGame(109959833715820, "WideOpen [MOTORCYCLE, 2XP WEEKEND, CUSTOMIZATION]", "KEYLESS NOCLIP (read description!)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/WideOpen-MOTORCYCLE-2XP-WEEKEND-CUSTOMIZATION-KEYLESS-NOCLIP-read-description-232169\"))()")
        addGame(12911805647, "Wodac 🦕", "the best ai script for wodec (keyless)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Wodac-the-best-ai-script-for-wodec-(keyless)-229538\"))()")
        addGame(110139475350829, "worm cave", "FuF panel", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/worm-cave-FuF-panel-229111\"))()")
        addGame(116971639977587, "Would You Rather: Brainrot Evolution Tower 🧠", "Keyless Script by rndm", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Would-You-Rather-Brainrot-Evolution-Tower-Script-No-Key-232379\"))()")
        addGame(2809202155, "Your Bizarre Adventure", "Phantom | Auto-farm, Auto-sell, ESP, TP keyless script", "loadstring(game:HttpGet(\"https://rscripts.net/raw/phantom-or-auto-farm-auto-sell-esp-tp-keyless-script_1790795825925_174cR5BH79.txt\"))()")
        addGame(82457571485380, "Zombie Rush Survival 🧟‍♂️", "Silent Aim", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Zombie-Rush-Survival-Silent-Aim-230380\"))()")
        addGame(134208374070897, "{ Pt. 2 } MONOCHROME👁️", "Part 1 | Instant Unlock Code", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Pt.-2-MONOCHROME-Part-1-or-Instant-Unlock-Code-231533\"))()")
        addGame(7205641391, "{MECHANICS} Monday Morning Misery [Beta]", "Autoplayer v1 (500 views = v2)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/MECHANICS-Monday-Morning-Misery-Beta-Autoplayer-v1-229029\"))()")
        addGame(98653121393961, "{🔴LIVE} Start Your Streamer Career!", "OP Script | inf money - Appear in Leaderboard", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/LIVE-Start-Your-Streamer-Career-OP-Script-or-inf-money-Appear-in-Leaderboard-232199\"))()")
        addGame(117235735383048, "العسكرية بلانتوم", "Dragon", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/alaskryh-blantwm-Dragon-230035\"))()")
        addGame(10786591, "شالية عوده | تحديث", "DARKCR7", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/shalyh-awdh-or-thdyth-DARKCR7-230310\"))()")
        addGame(77790193039862, "⚔️ 1.8 Arena", "Hit aura, speed (credits to Ruzgar8323)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/1.8-Arena-Hit-aura-speed-(credits-to-Ruzgar8323)-230664\"))()")
        addGame(14541302663, "⚡BALTHAZAR", "(OP) Reworked", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/BALTHAZAR-(OP)-230751\"))()")
        addGame(9285238704, "⚡Race Clicker", "BEST KEYLESS SCRIPT  AUTO FARM", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Race-Clicker-BEST-KEYLESS-SCRIPT-AUTO-FARM-231305\"))()")
        addGame(8663318501, "✨ F3X Building Tools", "Drawing sleeping  by Goner_66601", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/F3X-Building-Tools-Drawing-sleeping-by-Goner_66601-231522\"))()")
        addGame(5991163185, "❄️ Spray Paint!", "BACKK ! AutoDraw Images ll Mewli", "loadstring(game:HttpGet(\"https://rscripts.net/raw/backk-autodraw-images-ll-mewli_1791823699166_ZHPE4lTTae.txt\"))()")
        addGame(662417684, "❓ LUCKY BLOCKS Battlegrounds", "Khamsha's duck", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/LUCKY-BLOCKS-Battlegrounds-Lucky-block-Script-Ss-229749\"))()")
        addGame(114444846884753, "🌙 Jump Rope to the Moon!", "Auto Jump, Auto Retry, Auto Pick, God Mode, & More", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Jump-Rope-to-the-Moon!-Auto-Jump-Auto-Retry-Auto-Pick-God-Mode-and-More-231586\"))()")
        addGame(13822889, "🌳 Lumber Tycoon 2", "auto farm, tree finder etc. | lumber tycoon 2", "loadstring(game:HttpGet(\"https://rscripts.net/raw/auto-farm-tree-finder-etc-or-lumber-tycoon-2_1791986658937_EiqeUIFl0T.txt\"))()")
        addGame(92637789841354, "🍃 Clean all the Leaves", "Script Op", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Clean-all-the-Leaves-or-Script-230769\"))()")
        addGame(192800, "🍕Work at a Pizza Place", "FE Face Changer", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Work-at-a-Pizza-Place-FE-Face-Changer-230196\"))()")
        addGame(12337261447, "🎃 Studlands", "FREEDOM (Fixed&Updated)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Studlands-FREEDOM-(FixedandUpdated)-231798\"))()")
        addGame(117690288889971, "🎃Fright Fighters", "Infinite stamina", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Fright-Fighters-Infinite-stamina-232016\"))()")
        addGame(3623096087, "🎃Muscle Legends [x2 Weekend]", "Proton Services", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Muscle-Legends-Proton-Services-229188\"))()")
        addGame(16483433878, "🏰 Block Tales [DEMO 5]", "Vape V4 (Blocktales, redliner prison life)", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Block-Tales-DEMO-5-Vape-V4-Blocktales-redliner-prison-life-232013\"))()")
        addGame(128899661081075, "👑THA BRONX 3👑", "WALSCRIPT SRC CODE", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/THA-BRONX-3-walscrpt-Free-version-230279\"))()")
        addGame(116837678487831, "💅 Baddie Bounces", "[ KEYLESS ] Baddie Bounces Script [ PEAK ]", "loadstring(game:HttpGet(\"https://rscripts.net/raw/keyless-baddie-bounces-script-peak_1791649046210_txa0Jt3AI8.txt\"))()")
        addGame(2248408710, "💥 Destruction Simulator", "VOID STAR v1.2.0 D.S", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Destruction-Simulator-VOID-STAR-v1.2.0-D.S-229219\"))()")
        addGame(91514145260129, "📒 Brazilian School [RP]", "Escola Brasileira Free Gamepass", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Brazilian-School-RP-Escola-Brasileira-Free-Gamepass-232136\"))()")
        addGame(8712817601, "🚨BARRY'S PRISON RUN! (OBBY)", "NO KEY MENU RANOYSD PLUS", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/BARRY'S-PRISON-RUN!-(OBBY)-BARRY'S-PRISON-RUN-MENU-RANOYSD-PLUS-230406\"))()")
        addGame(75387700043737, "🛍️ My Avatar!", "[ Open Source ] Avatar Stealer+Saver for ts game too", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/My-Avatar!-Open-Source-Avatar-Stealer+Saver-for-ts-game-too-230165\"))()")
        addGame(8034886758, "🥊Punch Monsters!🥊", "Game destroyer 6000", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Punch-Monsters!-Game-destroyer-6000-231011\"))()")
        addGame(18722757961, "🩸[UPDATE2] RagBlood🩸", "Hitbox script for skids", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/UPDATE2-RagBlood-Hitbox-script-for-skids-231868\"))()")
        addGame(82712304391069, "🪓 Carve Wood! [Fall Update]", "auto carve", "loadstring(game:HttpGet(\"https://scriptblox.com/raw/Carve-Wood!-Fall-Update-auto-carve-231349\"))()")
        --// Helper Methods
        function GamesDatabase:GetAll()
            return self.List
        end

        function GamesDatabase:GetByPlaceId(placeId)
            local id = tonumber(placeId)
            if not id then return nil end
            return self.ByPlaceId[id]
        end

        function GamesDatabase:Search(query, limit)
            limit = limit or 50
            local q = tostring(query or ''):lower():gsub('^%s*(.-)%s*$', '%1')
            local results = {}
            if q == '' then
                for i = 1, math.min(#self.List, limit) do
                    table.insert(results, self.List[i])
                end
                return results
            end

            -- Direct Place ID match priority
            local numQ = tonumber(q)
            if numQ and self.ByPlaceId[numQ] then
                table.insert(results, self.ByPlaceId[numQ])
            end

            -- Name search
            for _, gameData in ipairs(self.List) do
                if #results >= limit then break end
                if gameData.PlaceId ~= numQ then
                    if gameData.Name:lower():find(q, 1, true) or tostring(gameData.PlaceId):find(q, 1, true) then
                        table.insert(results, gameData)
                    end
                end
            end
            return results
        end

        return GamesDatabase
    end)()

    -- [MODULE 2: Toast Notification Engine]
    local Notification = (function()
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
    end)()

    -- [MODULE 3: Discord Telemetry Logger]
    local Telemetry = (function()
        --[[
            AtomWare Telemetry & Webhook Logger Module
            Dispatches authentication events and execution audits to Discord Webhook
        ]]

        local HttpService = game:GetService("HttpService")
        local Players = game:GetService("Players")
        local UserInputService = game:GetService("UserInputService")

        local LocalPlayer = Players.LocalPlayer
        local WEBHOOK_URL = "https://discord.com/api/webhooks/1553009642370506762/PtcqZVm8UU_rDA4_5CY-38B9dRzxDcTFTnI4IXF-cFvn4xAMQrQbf36AeRy48-obyEvp"

        local Telemetry = {}

        -- Safely discover executor HTTP request implementation
        local function getHttpRequestFn()
            if typeof(syn) == "table" and typeof(syn.request) == "function" then
                return syn.request
            end
            if typeof(http_request) == "function" then
                return http_request
            end
            if typeof(request) == "function" then
                return request
            end
            if typeof(http) == "table" and typeof(http.request) == "function" then
                return http.request
            end
            return nil
        end

        local function getExecutorName()
            if typeof(identifyexecutor) == "function" then
                return identifyexecutor()
            end
            if typeof(getexecutorname) == "function" then
                return getexecutorname()
            end
            return "Unknown Executor"
        end

        local function getDeviceType()
            if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
                return "Mobile / Touch"
            elseif UserInputService.KeyboardEnabled then
                return "PC / Desktop"
            elseif UserInputService.GamepadEnabled then
                return "Console / Gamepad"
            end
            return "Desktop"
        end

        function Telemetry:SendAuthLog(gameName, placeId, success, reason)
            task.spawn(function()
                local requestFn = getHttpRequestFn()
                if not requestFn then
                    return
                end

                local statusText = success and "AUTHENTICATED" or "FAILED"
                local statusColor = success and 1096065 or 15682852 -- 0x10B981 (Green) or 0xEF4444 (Red)

                local payload = {
                    username = "AtomWare Hub Telemetry",
                    avatar_url = "https://cdn.discordapp.com/attachments/111111111111111111/atomware_logo.png",
                    embeds = {
                        {
                            title = "⚡ AtomWare Hub — Auth Audit Log",
                            color = statusColor,
                            fields = {
                                {
                                    name = "👤 Player",
                                    value = string.format("**%s** (@%s)\nUserId: `%s`\nAge: `%s` days", 
                                        tostring(LocalPlayer.DisplayName),
                                        tostring(LocalPlayer.Name),
                                        tostring(LocalPlayer.UserId),
                                        tostring(LocalPlayer.AccountAge)
                                    ),
                                    inline = true
                                },
                                {
                                    name = "🎮 Game Target",
                                    value = string.format("**%s**\nPlaceId: `%s`",
                                        tostring(gameName or "Unknown"),
                                        tostring(placeId or game.PlaceId)
                                    ),
                                    inline = true
                                },
                                {
                                    name = "🛡️ Auth Status",
                                    value = string.format("**%s**\n%s", 
                                        statusText, 
                                        tostring(reason or (success and "Key verified" or "Invalid key submitted"))
                                    ),
                                    inline = true
                                },
                                {
                                    name = "💻 Device & Platform",
                                    value = getDeviceType(),
                                    inline = true
                                },
                                {
                                    name = "⚙️ Executor",
                                    value = tostring(getExecutorName()),
                                    inline = true
                                },
                                {
                                    name = "🌐 Job ID",
                                    value = string.format("`%s`", tostring(game.JobId or "SinglePlayer")),
                                    inline = true
                                }
                            },
                            footer = {
                                text = "AtomWare Universal Hub System • " .. os.date("!%Y-%m-%d %H:%M:%S UTC")
                            }
                        }
                    }
                }

                local jsonBody = HttpService:JSONEncode(payload)

                pcall(function()
                    requestFn({
                        Url = WEBHOOK_URL,
                        Method = "POST",
                        Headers = {
                            ["Content-Type"] = "application/json"
                        },
                        Body = jsonBody
                    })
                end)
            end)
        end

        return Telemetry
    end)()

    -- [MODULE 4: Key Authentication Modal]
    local AuthPrompt = (function()
        --[[
            AtomWare Key Authentication Prompt Module
            Presents responsive key entry modal before script execution
            Key: THEBESTFIXED
            Discord: https://discord.gg/AeCYnnQmq5
        ]]

        local CoreGui = game:GetService("CoreGui")
        local Players = game:GetService("Players")
        local TweenService = game:GetService("TweenService")
        local UserInputService = game:GetService("UserInputService")

        local LocalPlayer = Players.LocalPlayer
        local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

        local CORRECT_KEY = "THEBESTFIXED"
        local DISCORD_INVITE = "https://discord.gg/AeCYnnQmq5"

        local AuthPrompt = {}

        local function getGuiParent()
            local success, target = pcall(function()
                return CoreGui
            end)
            if success and target then
                return target
            end
            return PlayerGui
        end

        local function safeCopyClipboard(text)
            local fn = setclipboard or toclipboard or writeclipboard
            if typeof(fn) == "function" then
                pcall(fn, text)
                return true
            end
            if typeof(clipboard) == "table" and typeof(clipboard.set) == "function" then
                pcall(clipboard.set, text)
                return true
            end
            return false
        end

        function AuthPrompt:Prompt(gameName, placeId, notificationModule, telemetryModule, onSuccess)
            -- Check if session already authenticated
            if _G.AtomwareAuthed == true then
                if typeof(onSuccess) == "function" then
                    onSuccess()
                end
                return
            end

            local parent = getGuiParent()
            local old = parent:FindFirstChild("Atomware_AuthPrompt")
            if old then
                old:Destroy()
            end

            local screenGui = Instance.new("ScreenGui")
            screenGui.Name = "Atomware_AuthPrompt"
            screenGui.ResetOnSpawn = false
            screenGui.DisplayOrder = 1000
            screenGui.Parent = parent

            -- Dim backdrop
            local backdrop = Instance.new("Frame")
            backdrop.Name = "Backdrop"
            backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            backdrop.BackgroundTransparency = 0.5
            backdrop.Size = UDim2.new(1, 0, 1, 0)
            backdrop.Parent = screenGui

            -- Modal card
            local card = Instance.new("Frame")
            card.Name = "AuthCard"
            card.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
            card.AnchorPoint = Vector2.new(0.5, 0.5)
            card.Position = UDim2.new(0.5, 0, 0.5, 0)
            card.Size = UDim2.new(0, 360, 0, 250)
            card.ClipsDescendants = true
            card.Parent = screenGui

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 12)
            corner.Parent = card

            local stroke = Instance.new("UIStroke")
            stroke.Name = "CardStroke"
            stroke.Color = Color3.fromRGB(51, 65, 85)
            stroke.Thickness = 1.5
            stroke.Parent = card

            -- Header accent line
            local topBar = Instance.new("Frame")
            topBar.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
            topBar.Size = UDim2.new(1, 0, 0, 3)
            topBar.BorderSizePixel = 0
            topBar.Parent = card

            -- Title
            local titleLbl = Instance.new("TextLabel")
            titleLbl.BackgroundTransparency = 1
            titleLbl.Position = UDim2.new(0, 20, 0, 16)
            titleLbl.Size = UDim2.new(1, -40, 0, 24)
            titleLbl.Font = Enum.Font.GothamBold
            titleLbl.Text = "⚡ AtomWare — Key Required"
            titleLbl.TextColor3 = Color3.fromRGB(248, 250, 252)
            titleLbl.TextSize = 16
            titleLbl.TextXAlignment = Enum.TextXAlignment.Center
            titleLbl.Parent = card

            -- Subtitle
            local subLbl = Instance.new("TextLabel")
            subLbl.BackgroundTransparency = 1
            subLbl.Position = UDim2.new(0, 20, 0, 42)
            subLbl.Size = UDim2.new(1, -40, 0, 32)
            subLbl.Font = Enum.Font.Gotham
            subLbl.Text = string.format("Join our Discord to get the free key for:\n%s", tostring(gameName or "Supported Game"))
            subLbl.TextColor3 = Color3.fromRGB(148, 163, 184)
            subLbl.TextSize = 11
            subLbl.TextWrapped = true
            subLbl.TextXAlignment = Enum.TextXAlignment.Center
            subLbl.Parent = card

            -- Key input box container
            local inputContainer = Instance.new("Frame")
            inputContainer.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
            inputContainer.Position = UDim2.new(0, 24, 0, 84)
            inputContainer.Size = UDim2.new(1, -48, 0, 40)
            inputContainer.Parent = card

            local inputCorner = Instance.new("UICorner")
            inputCorner.CornerRadius = UDim.new(0, 8)
            inputCorner.Parent = inputContainer

            local inputStroke = Instance.new("UIStroke")
            inputStroke.Color = Color3.fromRGB(51, 65, 85)
            inputStroke.Thickness = 1
            inputStroke.Parent = inputContainer

            local textBox = Instance.new("TextBox")
            textBox.BackgroundTransparency = 1
            textBox.Position = UDim2.new(0, 12, 0, 0)
            textBox.Size = UDim2.new(1, -24, 1, 0)
            textBox.Font = Enum.Font.GothamBold
            textBox.PlaceholderText = "Enter key here..."
            textBox.PlaceholderColor3 = Color3.fromRGB(100, 116, 139)
            textBox.Text = ""
            textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
            textBox.TextSize = 13
            textBox.ClearTextOnFocus = false
            textBox.Parent = inputContainer

            -- Verify Button
            local btnVerify = Instance.new("TextButton")
            btnVerify.Name = "BtnVerify"
            btnVerify.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
            btnVerify.Position = UDim2.new(0, 24, 0, 136)
            btnVerify.Size = UDim2.new(1, -48, 0, 40)
            btnVerify.Font = Enum.Font.GothamBold
            btnVerify.Text = "🔓 Verify Key"
            btnVerify.TextColor3 = Color3.fromRGB(255, 255, 255)
            btnVerify.TextSize = 13
            btnVerify.AutoButtonColor = false
            btnVerify.Parent = card

            local vCorner = Instance.new("UICorner")
            vCorner.CornerRadius = UDim.new(0, 8)
            vCorner.Parent = btnVerify

            -- Join Discord Button
            local btnDiscord = Instance.new("TextButton")
            btnDiscord.Name = "BtnDiscord"
            btnDiscord.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
            btnDiscord.Position = UDim2.new(0, 24, 0, 186)
            btnDiscord.Size = UDim2.new(1, -48, 0, 38)
            btnDiscord.Font = Enum.Font.GothamBold
            btnDiscord.Text = "📋 Join Discord (Copy Link)"
            btnDiscord.TextColor3 = Color3.fromRGB(255, 255, 255)
            btnDiscord.TextSize = 12
            btnDiscord.AutoButtonColor = false
            btnDiscord.Parent = card

            local dCorner = Instance.new("UICorner")
            dCorner.CornerRadius = UDim.new(0, 8)
            dCorner.Parent = btnDiscord

            -- Button hover/press animations
            local function setupHover(btn, normalColor, hoverColor)
                btn.MouseEnter:Connect(function()
                    TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = hoverColor }):Play()
                end)
                btn.MouseLeave:Connect(function()
                    TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = normalColor }):Play()
                end)
            end
            setupHover(btnVerify, Color3.fromRGB(16, 185, 129), Color3.fromRGB(5, 150, 105))
            setupHover(btnDiscord, Color3.fromRGB(88, 101, 242), Color3.fromRGB(71, 82, 196))

            -- Copy Discord Logic
            btnDiscord.MouseButton1Click:Connect(function()
                local copied = safeCopyClipboard(DISCORD_INVITE)
                if notificationModule then
                    notificationModule:Show("Discord Copied", "discord.gg/AeCYnnQmq5 copied to clipboard!", 3.5, "Success")
                end
                btnDiscord.Text = "✓ Copied to Clipboard!"
                task.delay(2, function()
                    if btnDiscord and btnDiscord.Parent then
                        btnDiscord.Text = "📋 Join Discord (Copy Link)"
                    end
                end)
            end)

            -- Verification Logic
            local isVerifying = false
            local function verify()
                if isVerifying then return end
                isVerifying = true

                local entered = textBox.Text:gsub("^%s*(.-)%s*$", "%1")
                if entered == CORRECT_KEY then
                    _G.AtomwareAuthed = true

                    if telemetryModule then
                        telemetryModule:SendAuthLog(gameName, placeId, true, "Key THEBESTFIXED validated")
                    end
                    if notificationModule then
                        notificationModule:Show("Auth Success", "Key verified successfully! Loading script...", 2.5, "Success")
                    end

                    btnVerify.Text = "✓ Verified!"
                    btnVerify.BackgroundColor3 = Color3.fromRGB(5, 150, 105)

                    task.delay(0.6, function()
                        if screenGui and screenGui.Parent then
                            screenGui:Destroy()
                        end
                        if typeof(onSuccess) == "function" then
                            onSuccess()
                        end
                    end)
                else
                    if telemetryModule then
                        telemetryModule:SendAuthLog(gameName, placeId, false, "Invalid key entered: '" .. entered .. "'")
                    end
                    if notificationModule then
                        notificationModule:Show("Invalid Key", "Incorrect key! Join Discord to get the free key.", 4.0, "Error")
                    end

                    -- Shake animation on failure
                    stroke.Color = Color3.fromRGB(239, 68, 68)
                    local originalPos = card.Position
                    task.spawn(function()
                        for i = 1, 3 do
                            card.Position = originalPos + UDim2.new(0, 8, 0, 0)
                            task.wait(0.04)
                            card.Position = originalPos - UDim2.new(0, 8, 0, 0)
                            task.wait(0.04)
                        end
                        card.Position = originalPos
                        task.wait(1.5)
                        if stroke and stroke.Parent then
                            stroke.Color = Color3.fromRGB(51, 65, 85)
                        end
                        isVerifying = false
                    end)
                end
            end

            btnVerify.MouseButton1Click:Connect(verify)
            textBox.FocusLost:Connect(function(enterPressed)
                if enterPressed then
                    verify()
                end
            end)

            -- Pop-in tween
            card.Position = UDim2.new(0.5, 0, 0.45, 0)
            card.BackgroundTransparency = 1
            TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.new(0.5, 0, 0.5, 0),
                BackgroundTransparency = 0
            }):Play()
        end

        return AuthPrompt
    end)()

    -- [MODULE 5: Floating Draggable Search & Gamehop Widget]
    local SearchWidget = (function()
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

            -- Floating Icon Button (Clean solid circle, draggable)
            local floatBtn = Instance.new("TextButton")
            floatBtn.Name = "FloatingSearchButton"
            floatBtn.Size = UDim2.new(0, 48, 0, 48)
            floatBtn.Position = UDim2.new(0, 20, 0.45, 0)
            floatBtn.BackgroundColor3 = Color3.fromRGB(28, 30, 40)
            floatBtn.Text = "🔍"
            floatBtn.TextSize = 20
            floatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            floatBtn.Font = Enum.Font.GothamBold
            floatBtn.AutoButtonColor = false
            floatBtn.Parent = screenGui

            local floatCorner = Instance.new("UICorner")
            floatCorner.CornerRadius = UDim.new(1, 0)
            floatCorner.Parent = floatBtn

            local floatStroke = Instance.new("UIStroke")
            floatStroke.Color = Color3.fromRGB(55, 60, 78)
            floatStroke.Thickness = 1.5
            floatStroke.Parent = floatBtn

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

            -- Safe database accessor helpers
            local function fetchAllGames()
                if typeof(gamesDb) == "table" then
                    if typeof(gamesDb.GetAll) == "function" then
                        local ok, res = pcall(function() return gamesDb:GetAll() end)
                        if ok and typeof(res) == "table" then return res end
                    end
                    if typeof(gamesDb.List) == "table" then
                        return gamesDb.List
                    end
                end
                return {}
            end

            local function fetchFilteredGames(query)
                if typeof(gamesDb) == "table" and typeof(gamesDb.Search) == "function" then
                    local ok, res = pcall(function() return gamesDb:Search(query) end)
                    if ok and typeof(res) == "table" then return res end
                end
                return fetchAllGames()
            end

            -- Initial load with all games
            renderResults(fetchAllGames())

            -- Live Search Filter
            searchInput:GetPropertyChangedSignal("Text"):Connect(function()
                local query = searchInput.Text
                clearSearchBtn.Visible = (#query > 0)
                local filtered = fetchFilteredGames(query)
                renderResults(filtered)
            end)

            clearSearchBtn.MouseButton1Click:Connect(function()
                searchInput.Text = ""
                clearSearchBtn.Visible = false
                renderResults(fetchAllGames())
            end)

            return SearchWidget
        end

        return SearchWidget
    end)()

    -- [MODULE 6: Persistent Watermark & Live FPS Counter]
    local Watermark = (function()
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
    end)()

    -- [MODULE 7: Core Orchestrator]
    local runAtomwareHub = (function()
        --[[
            AtomWare Giant Script Hub (407+ Games) - Core Orchestrator Module
            Auto-detects game by PlaceId, verifies auth key, runs loadstring,
            mounts persistent watermark and draggable search/gamehop widget.
        ]]

        local Players = game:GetService("Players")
        local TweenService = game:GetService("TweenService")
        local CoreGui = game:GetService("CoreGui")

        local LocalPlayer = Players.LocalPlayer
        local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

        local function getGuiParent()
            local success, target = pcall(function()
                return CoreGui
            end)
            if success and target then
                return target
            end
            return PlayerGui
        end

        local function runAtomwareHub(GamesDatabase, Notification, Telemetry, AuthPrompt, SearchWidget, Watermark)
            -- Guard against duplicate executions
            if _G.AtomwareHubLoaded == true then
                if Notification then
                    Notification:Show("AtomWare Active", "AtomWare is already running! Use the 🔍 icon.", 3, "Info")
                end
                return
            end
            _G.AtomwareHubLoaded = true

            -- Initialize Watermark & Floating Search Widget immediately
            Watermark:Init()
            SearchWidget:Init(GamesDatabase, Notification, AuthPrompt, Telemetry)

            -- Auto-detect Current Game
            local currentPlaceId = game.PlaceId
            local matchedGame = GamesDatabase:GetByPlaceId(currentPlaceId)

            if matchedGame then
                Notification:Show("Game Detected", "Supported game found: " .. matchedGame.Name, 4, "Info")

                -- Prompt Key Authentication before executing loadstring
                AuthPrompt:Prompt(matchedGame.Name, matchedGame.PlaceId, Notification, Telemetry, function()
                    Notification:Show("Executing Script", "Launching " .. matchedGame.Name .. " (" .. (matchedGame.Title or "Default") .. ")...", 3, "Success")

                    -- Safely execute the game loadstring
                    task.spawn(function()
                        local loadFunc, compileErr = loadstring(matchedGame.Loadstring)
                        if not loadFunc then
                            Notification:Show("Compile Error", "Failed to compile: " .. tostring(compileErr), 5, "Error")
                            return
                        end

                        local ok, runErr = pcall(loadFunc)
                        if not ok then
                            Notification:Show("Runtime Error", "Error executing: " .. tostring(runErr), 5, "Error")
                        end
                    end)
                end)
            else
                -- Game is not in the 407+ supported list
                Notification:Show(
                    "Unsupported Game",
                    "The game you are in (Place ID: " .. tostring(currentPlaceId) .. ") is not yet supported by AtomWare.",
                    7,
                    "Warning"
                )

                -- Display an informative notice modal with quick access to search
                local parent = getGuiParent()
                local noticeGui = Instance.new("ScreenGui")
                noticeGui.Name = "Atomware_UnsupportedNotice"
                noticeGui.ResetOnSpawn = false
                noticeGui.DisplayOrder = 940
                noticeGui.Parent = parent

                local modal = Instance.new("Frame")
                modal.Name = "NoticeModal"
                modal.AnchorPoint = Vector2.new(0.5, 0.5)
                modal.Position = UDim2.new(0.5, 0, 0.5, 0)
                modal.Size = UDim2.new(0, 420, 0, 220)
                modal.BackgroundColor3 = Color3.fromRGB(20, 22, 32)
                modal.BorderSizePixel = 0
                modal.Parent = noticeGui

                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 12)
                corner.Parent = modal

                local stroke = Instance.new("UIStroke")
                stroke.Color = Color3.fromRGB(240, 160, 40)
                stroke.Thickness = 1.5
                stroke.Parent = modal

                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(1, -32, 0, 30)
                title.Position = UDim2.new(0, 16, 0, 16)
                title.BackgroundTransparency = 1
                title.Text = "⚠️ Game Not Supported Yet"
                title.TextColor3 = Color3.fromRGB(255, 255, 255)
                title.Font = Enum.Font.GothamBold
                title.TextSize = 18
                title.TextXAlignment = Enum.TextXAlignment.Center
                title.Parent = modal

                local desc = Instance.new("TextLabel")
                desc.Size = UDim2.new(1, -32, 0, 60)
                desc.Position = UDim2.new(0, 16, 0, 52)
                desc.BackgroundTransparency = 1
                desc.Text = "The game you are in (Place ID: " .. tostring(currentPlaceId) .. ") is not yet supported by AtomWare.\n\nUse the floating 🔍 button on your screen to explore 407+ supported games and hop to them!"
                desc.TextColor3 = Color3.fromRGB(170, 175, 195)
                desc.Font = Enum.Font.Gotham
                desc.TextSize = 13
                desc.TextWrapped = true
                desc.Parent = modal

                local dismissBtn = Instance.new("TextButton")
                dismissBtn.Size = UDim2.new(1, -32, 0, 40)
                dismissBtn.Position = UDim2.new(0, 16, 1, -56)
                dismissBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
                dismissBtn.Text = "Got it (Keep 🔍 Search Active)"
                dismissBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                dismissBtn.Font = Enum.Font.GothamBold
                dismissBtn.TextSize = 13
                dismissBtn.AutoButtonColor = false
                dismissBtn.Parent = modal

                local btnCorner = Instance.new("UICorner")
                btnCorner.CornerRadius = UDim.new(0, 8)
                btnCorner.Parent = dismissBtn

                dismissBtn.MouseButton1Click:Connect(function()
                    noticeGui:Destroy()
                end)
            end
        end

        return runAtomwareHub
    end)()

    -- Initialize and start AtomWare Hub immediately
    runAtomwareHub(GamesDatabase, Notification, Telemetry, AuthPrompt, SearchWidget, Watermark)
end
