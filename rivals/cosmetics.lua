--[[
    Atomware Rivals - cosmetics.lua
    Complete Cosmetics API subsystem for Rivals (Weapon Skins, Wraps, Charms, Finishers, Rank Spoofing).
    Fully rebranded and optimized for Atomware Hub.
]]

pcall(function()
	local g = (getgenv and getgenv()) or _G
	if type(g) == "table" and type(g.__atomware_rivals_unload) == "function" then
		g.__atomware_rivals_unload()
		g.__atomware_rivals_unload = nil
	end
end)

local rawGetgenv: any
local rawGetfenv: any
local rawLoadstring: any
local rawShared: any
local rawReadfile: any
local rawWritefile: any
local rawGethui: any
local rawIsfolder: any
local rawMakefolder: any
local rawListfiles: any
local rawDelfile: any
local rawCloneref: any
local rawClonereference: any
do
	pcall(function()
		rawGetgenv = getgenv
		rawGetfenv = getfenv
		rawLoadstring = loadstring or load
		rawShared = shared
		rawReadfile = readfile
		rawWritefile = writefile
		rawGethui = gethui
		rawIsfolder = isfolder
		rawMakefolder = makefolder
		rawListfiles = listfiles
		rawDelfile = delfile
		rawCloneref = cloneref
		rawClonereference = clonereference
	end)
	if typeof(rawGetgenv) == "function" then
		pcall(function()
			local env = rawGetgenv()
			if type(env) == "table" then
				rawReadfile = rawReadfile or env.readfile
				rawWritefile = rawWritefile or env.writefile
				rawLoadstring = rawLoadstring or env.loadstring or env.load
				rawGethui = rawGethui or env.gethui
				rawIsfolder = rawIsfolder or env.isfolder
				rawMakefolder = rawMakefolder or env.makefolder
				rawListfiles = rawListfiles or env.listfiles
				rawDelfile = rawDelfile or env.delfile
				rawCloneref = rawCloneref or env.cloneref
				rawClonereference = rawClonereference or env.clonereference
				rawGetfenv = rawGetfenv or env.getfenv
				rawShared = rawShared or env.shared
			end
		end)
	end
	local g = _G :: { [string]: any }
	rawReadfile = rawReadfile or g.readfile
	rawWritefile = rawWritefile or g.writefile
	rawLoadstring = rawLoadstring or g.loadstring or g.load
	rawGethui = rawGethui or g.gethui
	rawGetgenv = rawGetgenv or g.getgenv
	rawIsfolder = rawIsfolder or g.isfolder
	rawMakefolder = rawMakefolder or g.makefolder
	rawListfiles = rawListfiles or g.listfiles
	rawDelfile = rawDelfile or g.delfile
	rawCloneref = rawCloneref or g.cloneref
	rawClonereference = rawClonereference or g.clonereference
end

local function execApi(name: string): any
	local cached: any = nil
	if name == "readfile" then
		cached = rawReadfile
	elseif name == "writefile" then
		cached = rawWritefile
	elseif name == "loadstring" or name == "load" then
		cached = rawLoadstring
	elseif name == "gethui" then
		cached = rawGethui
	elseif name == "getgenv" then
		cached = rawGetgenv
	elseif name == "isfolder" then
		cached = rawIsfolder
	elseif name == "makefolder" then
		cached = rawMakefolder
	elseif name == "listfiles" then
		cached = rawListfiles
	elseif name == "delfile" then
		cached = rawDelfile
	elseif name == "cloneref" then
		cached = rawCloneref
	elseif name == "clonereference" then
		cached = rawClonereference
	end
	if cached ~= nil then
		return cached
	end

	local g = _G :: { [string]: any }
	if g[name] ~= nil then
		return g[name]
	end
	if typeof(rawGetgenv) == "function" then
		local ok, env = pcall(rawGetgenv)
		if ok and type(env) == "table" and (env :: any)[name] ~= nil then
			local value = (env :: any)[name]
			if name == "readfile" then
				rawReadfile = value
			elseif name == "writefile" then
				rawWritefile = value
			elseif name == "loadstring" or name == "load" then
				rawLoadstring = value
			elseif name == "gethui" then
				rawGethui = value
			elseif name == "isfolder" then
				rawIsfolder = value
			elseif name == "makefolder" then
				rawMakefolder = value
			elseif name == "listfiles" then
				rawListfiles = value
			elseif name == "delfile" then
				rawDelfile = value
			elseif name == "cloneref" then
				rawCloneref = value
			elseif name == "clonereference" then
				rawClonereference = value
			end
			return value
		end
	end
	if typeof(rawGetfenv) == "function" then
		local ok, env = pcall(rawGetfenv, 0)
		if ok and type(env) == "table" and (env :: any)[name] ~= nil then
			return (env :: any)[name]
		end
	end
	if type(rawShared) == "table" and (rawShared :: any)[name] ~= nil then
		return (rawShared :: any)[name]
	end
	return nil
end

local function hasFsApi(name: string): boolean
	return typeof(execApi(name)) == "function"
end

local function fsReadfile(path: string): string
	local fn = execApi("readfile")
	assert(typeof(fn) == "function", "readfile unavailable")
	return (fn :: (string) -> string)(path)
end

local function fsWritefile(path: string, contents: string)
	local fn = execApi("writefile")
	assert(typeof(fn) == "function", "writefile unavailable")
	;(fn :: (string, string) -> ())(path, contents)
end

local function fsGethui(): Instance?
	local fn = execApi("gethui")
	if typeof(fn) ~= "function" then
		return nil
	end
	local ok, result = pcall(fn :: () -> Instance)
	if ok and typeof(result) == "Instance" then
		return result
	end
	return nil
end

local function fsGetgenv(): { [string]: any }?
	local fn = execApi("getgenv")
	if typeof(fn) ~= "function" then
		return nil
	end
	local ok, result = pcall(fn :: () -> { [string]: any })
	if ok and type(result) == "table" then
		return result
	end
	return nil
end

local function fsIsfolder(path: string): boolean
	local fn = execApi("isfolder")
	if typeof(fn) ~= "function" then
		return false
	end
	local ok, result = pcall(fn :: (string) -> boolean, path)
	return ok and result == true
end

local function fsMakefolder(path: string)
	local fn = execApi("makefolder")
	assert(typeof(fn) == "function", "makefolder unavailable")
	;(fn :: (string) -> ())(path)
end

local function fsListfiles(path: string): { string }
	local fn = execApi("listfiles")
	if typeof(fn) ~= "function" then
		return {}
	end
	local ok, result = pcall(fn :: (string) -> { string }, path)
	if ok and type(result) == "table" then
		return result
	end
	return {}
end

local function fsDelfile(path: string): boolean
	local fn = execApi("delfile")
	if typeof(fn) ~= "function" then
		return false
	end
	local ok = pcall(fn :: (string) -> (), path)
	return ok
end

local cloneRef = (execApi("cloneref") or execApi("clonereference") or function(object: any): any
	return object
end) :: <T>(T) -> T

local Game = cloneRef(game)

local function getService(className: string): any
	return cloneRef(Game:GetService(className))
end

local GAME_IDENTITY = 2
local fsSetIdentity = execApi("setthreadidentity") or execApi("set_thread_identity") or execApi("setidentity")
local fsGetIdentity = execApi("getthreadidentity") or execApi("get_thread_identity") or execApi("getidentity")
if typeof(fsSetIdentity) ~= "function" or typeof(fsGetIdentity) ~= "function" then
	fsSetIdentity = nil
	fsGetIdentity = nil
end

local function currentIdentity(): number?
	if not fsGetIdentity then
		return nil
	end
	local ok, id = pcall(fsGetIdentity)
	return if ok and type(id) == "number" then id else nil
end

local function isElevatedThread(): boolean
	local id = currentIdentity()
	return id ~= nil and id > GAME_IDENTITY
end

local function callAsGame(fn: any, ...: any): (boolean, ...any)
	local prev = currentIdentity()
	if prev == nil or prev <= GAME_IDENTITY then
		return pcall(fn, ...)
	end
	pcall(fsSetIdentity, GAME_IDENTITY)
	local res = table.pack(pcall(fn, ...))
	pcall(fsSetIdentity, prev)
	return table.unpack(res, 1, res.n)
end

local robloxRequire = require
local function gameRequire(mod: any): any
	local getrenv = execApi("getrenv")
	if typeof(getrenv) == "function" then
		local okEnv, renv = pcall(getrenv)
		if okEnv and type(renv) == "table" and typeof((renv :: any).require) == "function" then
			local ok, result = callAsGame((renv :: any).require, mod)
			if ok then
				return result
			end
		end
	end
	return robloxRequire(mod)
end

local function require(mod: any): any
	if typeof(mod) == "Instance" then
		local ok, result = pcall(gameRequire, mod)
		if ok then
			return result
		end
		ok, result = pcall(robloxRequire, mod)
		if ok then
			return result
		end
		error(result)
	end
	return robloxRequire(mod)
end

local SESSION = { alive = true, guis = {} :: { Instance } }

local function hookGameMethod(targetFn: any, wrap: any): any?
	if type(targetFn) ~= "function" then
		return nil
	end
	local hookfunction = execApi("hookfunction")
	local newcclosure = execApi("newcclosure") or function(fn: any): any
		return fn
	end
	if typeof(hookfunction) ~= "function" then
		return nil
	end
	local old: any = nil
	local ok = pcall(function()
		old = hookfunction(
			targetFn,
			newcclosure(function(...)
				if not SESSION.alive then
					return old(...)
				end
				return wrap(old, ...)
			end)
		)
	end)
	if ok and type(old) == "function" then
		return old
	end
	return nil
end

local function installSignalGuard()
	local genv = execApi("getgenv")
	local env = if typeof(genv) == "function" then genv() else nil
	if type(env) == "table" and env.__sonataSignalGuard then
		return
	end
	local okMod, Signal = pcall(function()
		local rep = getService("ReplicatedStorage")
		local modFolder = rep:FindFirstChild("Modules")
		if modFolder then
			local sigMod = modFolder:FindFirstChild("Signal")
			if sigMod then return require(sigMod) end
		end
		return nil
	end)
	if not okMod or type(Signal) ~= "table" or type(Signal.new) ~= "function" then
		return
	end
	local okClass, class = pcall(function()
		return getmetatable(Signal.new())
	end)
	if not okClass or type(class) ~= "table" then
		return
	end
	local fire = rawget(class, "Fire")
	local fireDeferred = rawget(class, "FireDeferred")

	local getupvalues = (type(debug) == "table" and (debug :: any).getupvalues) or execApi("getupvalues")
	local setupvalue = (type(debug) == "table" and (debug :: any).setupvalue) or execApi("setupvalue")
	if type(fire) == "function" and typeof(getupvalues) == "function" and typeof(setupvalue) == "function" then
		pcall(function()
			for index, value in getupvalues(fire) do
				if type(value) == "thread" then
					setupvalue(fire, index, nil)
				end
			end
		end)
	end

	if not fsSetIdentity then
		return
	end
	local function guard(old: any, self: any, ...: any)
		if isElevatedThread() then
			callAsGame(old, self, ...)
			return
		end
		return old(self, ...)
	end
	local hooked = false
	if type(fire) == "function" and hookGameMethod(fire, guard) then
		hooked = true
	end
	if type(fireDeferred) == "function" then
		hookGameMethod(fireDeferred, guard)
	end
	if hooked and type(env) == "table" then
		env.__sonataSignalGuard = true
	end
end
pcall(installSignalGuard)

local Players = getService("Players") :: Players
local UserInputService = getService("UserInputService") :: UserInputService
local RunService = getService("RunService") :: RunService
local ReplicatedStorage = getService("ReplicatedStorage") :: ReplicatedStorage
local Workspace = getService("Workspace") :: Workspace
local HttpService = getService("HttpService") :: HttpService
local MaterialService = getService("MaterialService") :: MaterialService
local SoundService = getService("SoundService") :: SoundService

local WHITE_IMAGE = "rbxasset://textures/ui/GuiImagePlaceholder.png"
local RANKED_CHARM_ELO = 99999
local RANKED_CHARM_LEADERBOARD = 1

local CONFIG_FOLDER = "Atomware/Rivals"

export type CosmeticsApi = {
	ready: boolean,
	skinmap: { [string]: string },
	wrapmap: { [string]: string },
	charmmap: { [string]: string },
	finishermap: { [string]: string },
	charmon: { [string]: boolean },
	finisheron: { [string]: boolean },
	weapons: { string },
	wraps: { string },
	charms: { string },
	finishers: { string },
	install: (self: CosmeticsApi) -> boolean,
	skinsFor: (self: CosmeticsApi, weapon: string) -> { string },
	rarityColor: (self: CosmeticsApi, name: string) -> Color3,
	entryImage: (self: CosmeticsApi, name: string?) -> string?,
	entryTint: (self: CosmeticsApi, name: string?) -> Color3?,
	previewImage: (self: CosmeticsApi, weapon: string, mode: string) -> string?,
	heldWeapon: (self: CosmeticsApi) -> string?,
	apply: (self: CosmeticsApi, weapon: string) -> (),
	applyExtra: (self: CosmeticsApi, weapon: string) -> (),
	setSelection: (self: CosmeticsApi, mode: string, weapon: string, option: string?) -> (),
	restore: (self: CosmeticsApi, config: any) -> (),
	export: (self: CosmeticsApi) -> (any, any, any, any),
	clearAll: (self: CosmeticsApi) -> (),
	randomizeAll: (self: CosmeticsApi) -> (),
}

local RarityFallback = {
	Common = Color3.fromRGB(90, 200, 120),
	Uncommon = Color3.fromRGB(80, 210, 140),
	Rare = Color3.fromRGB(70, 140, 255),
	Legendary = Color3.fromRGB(255, 70, 70),
	Mythical = Color3.fromRGB(190, 80, 255),
	Exotic = Color3.fromRGB(255, 160, 50),
	Unique = Color3.fromRGB(255, 160, 50),
	Contraband = Color3.fromRGB(255, 200, 60),
}

local function createCosmetics(): CosmeticsApi
	local api: CosmeticsApi
	local skinmap: { [string]: string } = {}
	local wrapmap: { [string]: string } = {}
	local charmmap: { [string]: string } = {}
	local finishermap: { [string]: string } = {}
	local charmon: { [string]: boolean } = {}
	local finisheron: { [string]: boolean } = {}
	local weapons: { string } = {}
	local wraps: { string } = {}
	local charms: { string } = {}
	local finishers: { string } = {}
	local installing = false

	local items: any = nil
	local cosmetics: any = nil
	local applyFn: ((string) -> ())? = nil
	local applyExtraFn: ((string) -> ())? = nil
	local heldWeaponFn: (() -> string?)? = nil

	local function clientPlayer(): Player?
		return Players.LocalPlayer
	end

	local function playerscripts(): Instance?
		local client = clientPlayer()
		if not client then
			return nil
		end
		local ok, scripts = pcall(function()
			return client:FindFirstChild("PlayerScripts")
		end)
		if ok and typeof(scripts) == "Instance" then
			return scripts
		end
		return nil
	end

	local function entryimage(entry: any): string?
		if type(entry) ~= "table" then
			return nil
		end
		local preferred = {
			"ImageHighResolution",
			"Image",
			"Icon",
			"Thumbnail",
			"DisplayImage",
			"IconImage",
			"ImageId",
			"PreviewImage",
			"RenderImage",
		}
		for _, key in preferred do
			local value = entry[key]
			if type(value) == "string" and value ~= "" and (string.find(value, "rbxasset", 1, true) or string.find(value, "http", 1, true)) then
				return value
			end
		end
		for key, value in entry do
			if type(key) == "string" and type(value) == "string" and value ~= "" and (string.find(value, "rbxasset", 1, true) or string.find(value, "http", 1, true)) then
				local lower = string.lower(key)
				if string.find(lower, "image", 1, true)
					or string.find(lower, "icon", 1, true)
					or string.find(lower, "thumb", 1, true)
					or string.find(lower, "preview", 1, true)
					or string.find(lower, "render", 1, true)
				then
					return value
				end
			end
		end
		return nil
	end

	local constantsImages: { [string]: string }? = nil
	local seasonLibrary: any = nil
	local charmsFolder: Instance? = nil
	local wrapTexturesFolder: Instance? = nil

	local function refreshImageSources()
		if constantsImages and seasonLibrary and charmsFolder and wrapTexturesFolder then
			return
		end
		if not constantsImages then
			pcall(function()
				local constants = require(ReplicatedStorage.Modules.CONSTANTS)
				if type(constants) == "table" and type(constants.COSMETIC_IMAGES) == "table" then
					constantsImages = constants.COSMETIC_IMAGES
				end
			end)
		end
		if not seasonLibrary then
			pcall(function()
				seasonLibrary = require(ReplicatedStorage.Modules.SeasonLibrary)
			end)
		end
		if not charmsFolder or not wrapTexturesFolder then
			local scripts = playerscripts()
			if scripts then
				pcall(function()
					charmsFolder = scripts.Assets:FindFirstChild("Charms")
				end)
				pcall(function()
					wrapTexturesFolder = scripts.Assets:FindFirstChild("WrapTextures")
				end)
			end
		end
	end

	local function isAssetImage(value: any): boolean
		return type(value) == "string"
			and value ~= ""
			and (string.find(value, "rbxasset", 1, true) ~= nil or string.find(value, "http", 1, true) ~= nil)
	end

	local function textureFromInstance(root: Instance?): string?
		if not root then
			return nil
		end
		local found: string? = nil
		pcall(function()
			local attr = root:GetAttribute("Image")
			if isAssetImage(attr) then
				found = attr :: string
				return
			end
			for _, descendant in root:GetDescendants() do
				if descendant:IsA("Decal") or descendant:IsA("Texture") then
					if isAssetImage(descendant.Texture) then
						found = descendant.Texture
						return
					end
				elseif descendant:IsA("MeshPart") and isAssetImage(descendant.TextureID) then
					found = descendant.TextureID
					return
				elseif descendant:IsA("SpecialMesh") and isAssetImage(descendant.TextureId) then
					found = descendant.TextureId
					return
				elseif descendant:IsA("ImageLabel") or descendant:IsA("ImageButton") then
					if isAssetImage(descendant.Image) then
						found = descendant.Image
						return
					end
				elseif descendant.ClassName == "SurfaceAppearance" then
					local colorMap = (descendant :: any).ColorMap
					if isAssetImage(colorMap) then
						found = colorMap
						return
					end
				end
			end
		end)
		return found
	end

	local function materialVariantImage(variantName: string): string?
		local wrapsRoot = MaterialService:FindFirstChild("Wraps")
		if not wrapsRoot then
			return nil
		end
		local variant = wrapsRoot:FindFirstChild(variantName)
		if not (variant and variant:IsA("MaterialVariant")) then
			return nil
		end
		local colorMap = variant.ColorMap
		if isAssetImage(colorMap) then
			return colorMap
		end
		return textureFromInstance(variant)
	end

	local function wrapGroupImage(data: any): string?
		if type(data) ~= "table" or type(data.WrapGroups) ~= "table" then
			return nil
		end
		for _, group in data.WrapGroups do
			if type(group) == "table" and type(group.MaterialVariant) == "string" and group.MaterialVariant ~= "" then
				local fromMaterial = materialVariantImage(group.MaterialVariant)
				if fromMaterial then
					return fromMaterial
				end
				if wrapTexturesFolder then
					local folder = wrapTexturesFolder:FindFirstChild(group.MaterialVariant)
					local fromFolder = textureFromInstance(folder)
					if fromFolder then
						return fromFolder
					end
				end
			end
		end
		return nil
	end

	local function wrapGroupColor(data: any): Color3?
		if type(data) ~= "table" or type(data.WrapGroups) ~= "table" then
			return nil
		end
		for _, group in data.WrapGroups do
			if type(group) == "table" and typeof(group.Color) == "Color3" then
				return group.Color
			end
		end
		return nil
	end

	local function rankImageForElo(elo: number, leaderboardRank: number?): string?
		if type(seasonLibrary) ~= "table" or type(seasonLibrary.RankProfiles) ~= "table" then
			return nil
		end
		local profile = seasonLibrary.RankProfiles.ranks_version1 or seasonLibrary.RankProfiles[next(seasonLibrary.RankProfiles)]
		if type(profile) ~= "table" or type(profile.Ranks) ~= "table" then
			return nil
		end
		local bestName: string? = nil
		local bestElo = -math.huge
		local bestHasBoard = false
		for name, info in profile.Ranks do
			if type(info) == "table" and type(info.RequiredELO) == "number" then
				local requiredRank = info.RequiredELOLeaderboardRanking
				local rankOk = requiredRank == nil or (type(leaderboardRank) == "number" and leaderboardRank <= requiredRank)
				if info.RequiredELO <= elo and rankOk then
					local hasBoard = requiredRank ~= nil
					if info.RequiredELO > bestElo or (info.RequiredELO == bestElo and hasBoard and not bestHasBoard) then
						bestElo = info.RequiredELO
						bestName = name
						bestHasBoard = hasBoard
					end
				end
			end
		end
		if bestName and type(profile.Ranks[bestName]) == "table" then
			local image = profile.Ranks[bestName].Image
			if isAssetImage(image) then
				return image
			end
		end
		return nil
	end

	local RANK_CHARM_SEP = " " .. utf8.char(0x00B7) .. " "

	local function getRankOrder(): { string }
		refreshImageSources()
		local order = {}
		if type(seasonLibrary) == "table" and type(seasonLibrary.RankProfiles) == "table" then
			local profile = seasonLibrary.RankProfiles.ranks_version1
			if type(profile) == "table" and type(profile.RanksOrder) == "table" then
				for _, rankName in profile.RanksOrder do
					if type(rankName) == "string" and rankName ~= "Unranked" then
						table.insert(order, rankName)
					end
				end
			end
		end
		if #order == 0 then
			order = {
				"Bronze 1", "Bronze 2", "Bronze 3",
				"Silver 1", "Silver 2", "Silver 3",
				"Gold 1", "Gold 2", "Gold 3",
				"Platinum 1", "Platinum 2", "Platinum 3",
				"Diamond 1", "Diamond 2", "Diamond 3",
				"Onyx 1", "Onyx 2", "Onyx 3",
				"Nemesis", "Archnemesis",
			}
		end
		return order
	end

	local function parseRankCharm(name: string): (string?, string?)
		if type(name) ~= "string" then
			return nil, nil
		end
		if string.match(name, "^Season %d+$") then
			return nil, nil
		end
		local seasonPrefix = string.match(name, "^(Season %d+)")
		if seasonPrefix then
			local ranks = getRankOrder()
			table.sort(ranks, function(a, b)
				return #a > #b
			end)
			for _, rankName in ranks do
				if string.sub(name, -#rankName) == rankName then
					local before = string.sub(name, 1, #name - #rankName)
					if string.match(before, "^Season %d+%W*$") then
						return seasonPrefix, rankName
					end
				end
			end
		end
		local season, rank = string.match(name, "^Season (%d+)%W+(.+)$")
		if season and rank then
			rank = string.gsub(rank, "^%s+", "")
			rank = string.gsub(rank, "%s+$", "")
			rank = string.gsub(rank, "^[^%w]+", "")
			if rank ~= "" then
				return "Season " .. season, rank
			end
		end
		return nil, nil
	end

	local function rankMeta(rankName: string): (number, number?)
		refreshImageSources()
		if type(seasonLibrary) == "table" and type(seasonLibrary.RankProfiles) == "table" then
			local profile = seasonLibrary.RankProfiles.ranks_version1
			local info = profile and profile.Ranks and profile.Ranks[rankName]
			if type(info) == "table" then
				local elo = if type(info.RequiredELO) == "number" then info.RequiredELO else 0
				local board = if type(info.RequiredELOLeaderboardRanking) == "number"
					then info.RequiredELOLeaderboardRanking
					else nil
				if rankName == "Archnemesis" then
					return math.max(elo, 3600), board or 1
				elseif rankName == "Nemesis" then
					return math.max(elo, 3600), board or 9999
				end
				local order = profile.RanksOrder
				if type(order) == "table" then
					local idx = table.find(order, rankName)
					local nextName = idx and order[idx + 1]
					local nextInfo = nextName and profile.Ranks[nextName]
					if type(nextInfo) == "table" and type(nextInfo.RequiredELO) == "number" and nextInfo.RequiredELO > elo then
						return math.floor((elo + nextInfo.RequiredELO) * 0.5), nil
					end
				end
				return elo + 50, nil
			end
		end
		if rankName == "Archnemesis" then
			return RANKED_CHARM_ELO, RANKED_CHARM_LEADERBOARD
		end
		if rankName == "Nemesis" then
			return 3600, 9999
		end
		return 0, nil
	end

	local function forceSeasonRankOnModel(model: Instance?, rankName: string?, board: number?)
		if typeof(model) ~= "Instance" or type(rankName) ~= "string" or rankName == "" then
			return
		end
		local extra = model:FindFirstChild("Extra")
		if not extra then
			return
		end
		local kept: Instance? = nil
		for _, child in extra:GetChildren() do
			if child.Name == rankName then
				kept = child
			else
				pcall(function()
					child:Destroy()
				end)
			end
		end
		if kept == nil then
			return
		end
		if board ~= nil then
			local text = "#" .. tostring(board)
			for _, descendant in model:GetDescendants() do
				if descendant:HasTag("CharmLeaderboardRank") then
					pcall(function()
						(descendant :: any).Text = text
					end)
				end
			end
		end
	end

	local function applyRankToCharm(charm: any, rankName: string?, elo: number?, board: number?)
		if type(charm) ~= "table" then
			return
		end
		if type(rankName) == "string" and rankName ~= "" then
			forceSeasonRankOnModel(charm.Model, rankName, board)
		end
		if type(seasonLibrary) == "table" and type(seasonLibrary.FormatSeasonRankCharm) == "function" and typeof(charm.Model) == "Instance" then
			local seasonName: string? = nil
			local ver = nil
			if type(charm.Name) == "string" then
				ver = tonumber(string.sub(charm.Name, 8))
			end
			if type(ver) == "number" and type(seasonLibrary.SeasonsByVersion) == "table" then
				local season = seasonLibrary.SeasonsByVersion[ver]
				if type(season) == "table" and type(season.Name) == "string" then
					seasonName = season.Name
				end
			end
			if not seasonName and type(seasonLibrary.CurrentSeason) == "table" then
				seasonName = seasonLibrary.CurrentSeason.Name
			end
			if type(seasonName) == "string" and type(elo) == "number" then
				pcall(function()
					seasonLibrary:FormatSeasonRankCharm(charm.Model, seasonName, elo, board)
				end)
				if type(rankName) == "string" then
					forceSeasonRankOnModel(charm.Model, rankName, board)
				end
			end
		end
	end

	local function rankImageByName(rankName: string): string?
		refreshImageSources()
		if type(seasonLibrary) ~= "table" or type(seasonLibrary.RankProfiles) ~= "table" then
			return nil
		end
		local profile = seasonLibrary.RankProfiles.ranks_version1
		local info = profile and profile.Ranks and profile.Ranks[rankName]
		if type(info) == "table" and isAssetImage(info.Image) then
			return info.Image
		end
		return nil
	end

	local function resolveCosmeticImage(name: string?, data: any): (string?, Color3?)
		if type(name) ~= "string" or name == "" or name == "default" or name == "none" then
			return nil, nil
		end
		refreshImageSources()

		local rankBase, rankName = parseRankCharm(name)
		if rankName then
			local rankImage = rankImageByName(rankName)
			if rankImage then
				return rankImage, nil
			end
			name = rankBase or name
			data = cosmetics and cosmetics.Cosmetics and cosmetics.Cosmetics[name]
		end

		if constantsImages and isAssetImage(constantsImages[name]) then
			return constantsImages[name], nil
		end

		local fromData = entryimage(data)
		if fromData then
			return fromData, nil
		end

		if type(name) == "string" and string.sub(name, 1, 7) == "Season " and tonumber(string.sub(name, 8)) then
			local ranked = rankImageForElo(RANKED_CHARM_ELO, RANKED_CHARM_LEADERBOARD)
			if ranked then
				return ranked, nil
			end
		end

		if charmsFolder then
			local charmModel = charmsFolder:FindFirstChild(name)
			local charmImage = textureFromInstance(charmModel)
			if charmImage then
				return charmImage, nil
			end
		end

		if wrapTexturesFolder then
			local wrapFolder = wrapTexturesFolder:FindFirstChild(name)
				or wrapTexturesFolder:FindFirstChild((string.gsub(name, " ", "_")))
			local wrapImage = textureFromInstance(wrapFolder)
			if wrapImage then
				return wrapImage, nil
			end
		end

		local fromWrapGroup = wrapGroupImage(data)
		if fromWrapGroup then
			return fromWrapGroup, nil
		end

		local tint = wrapGroupColor(data)
		if tint then
			return WHITE_IMAGE, tint
		end

		return nil, nil
	end

	local function cosmetictype(data: any): string
		local kind = type(data) == "table" and (data.Type or data.CosmeticType or data.Slot)
		if type(kind) ~= "string" then
			return ""
		end
		return string.lower(kind)
	end

	local function raritycolor(entry: any): Color3
		local rarityValue = if type(entry) == "table" then (entry.Rarity or entry.RarityName) else nil
		local rarity = if type(rarityValue) == "string" then rarityValue else nil
		local rows = cosmetics and (cosmetics.Rarities or cosmetics.RarityColors)
		local row = if rarity and type(rows) == "table" then rows[rarity] else nil
		if type(row) == "table" then
			if typeof(row.Color) == "Color3" then
				return row.Color
			end
		elseif typeof(row) == "Color3" then
			return row
		end
		if rarity then
			return RarityFallback[rarity] or Color3.fromRGB(220, 220, 220)
		end
		return Color3.fromRGB(220, 220, 220)
	end

	local _indexingInProgress = false
	local _indexingComplete = false
	local skinsByWeapon: { [string]: { string } } = {}
	local imageCache: { [string]: string? } = {}
	local tintCache: { [string]: Color3? } = {}

	local function getWeapons(): { string }
		if #weapons > 0 then
			return weapons
		end
		local seen: { [string]: boolean } = {}
		local function addweapon(name: any)
			if type(name) ~= "string" or name == "" or name == "MISSING_WEAPON" or seen[name] then
				return
			end
			seen[name] = true
			table.insert(weapons, name)
		end
		local itemSource = items and (items.Items or items)
		if type(itemSource) == "table" then
			for key, data in itemSource do
				if type(data) == "table" then
					addweapon(type(data.Name) == "string" and data.Name or (type(key) == "string" and key or nil))
				elseif type(key) == "string" then
					addweapon(key)
				end
			end
		end
		table.sort(weapons)
		return weapons
	end

	local function skinsfor(weapon: string): { string }
		if not weapon or weapon == "" then
			return { "default" }
		end
		local key = string.lower(weapon)
		local cached = skinsByWeapon[key]
		if cached then
			return cached
		end
		local list = { "default" }
		if cosmetics and type(cosmetics.Cosmetics) == "table" then
			local names = {}
			for name, data in cosmetics.Cosmetics do
				local itemName = type(data) == "table" and (data.ItemName or data.Item or data.Weapon)
				if cosmetictype(data) == "skin" and type(itemName) == "string" and string.lower(itemName) == key then
					table.insert(names, name)
				end
			end
			table.sort(names)
			for _, name in names do
				table.insert(list, name)
			end
		end
		skinsByWeapon[key] = list
		skinsByWeapon[weapon] = list
		return list
	end

	local function getWraps(): { string }
		if #wraps > 1 then
			return wraps
		end
		if cosmetics and type(cosmetics.Cosmetics) == "table" then
			local temp = {}
			for name, data in cosmetics.Cosmetics do
				if cosmetictype(data) == "wrap" then
					table.insert(temp, name)
				end
			end
			table.sort(temp)
			table.clear(wraps)
			table.insert(wraps, "default")
			for _, name in temp do
				table.insert(wraps, name)
			end
		end
		if #wraps == 0 then
			wraps[1] = "default"
		end
		return wraps
	end

	local function getCharms(): { string }
		if #charms > 0 and charms[1] ~= "none" then
			return charms
		end
		if cosmetics and type(cosmetics.Cosmetics) == "table" then
			local temp = {}
			for name, data in cosmetics.Cosmetics do
				if cosmetictype(data) == "charm" then
					table.insert(temp, name)
				end
			end
			table.sort(temp)
			local expanded = {}
			local others = {}
			local ranks = getRankOrder()
			for _, name in temp do
				if string.match(name, "^Season %d+$") then
					for _, rankName in ranks do
						table.insert(expanded, name .. RANK_CHARM_SEP .. rankName)
					end
				else
					table.insert(others, name)
				end
			end
			for _, name in others do
				table.insert(expanded, name)
			end
			table.clear(charms)
			for _, name in expanded do
				table.insert(charms, name)
			end
		end
		if #charms == 0 then
			charms[1] = "none"
		end
		return charms
	end

	local function getFinishers(): { string }
		if #finishers > 0 and finishers[1] ~= "none" then
			return finishers
		end
		if cosmetics and type(cosmetics.Cosmetics) == "table" then
			local temp = {}
			for name, data in cosmetics.Cosmetics do
				if cosmetictype(data) == "finisher" then
					table.insert(temp, name)
				end
			end
			table.sort(temp)
			table.clear(finishers)
			for _, name in temp do
				table.insert(finishers, name)
			end
		end
		if #finishers == 0 then
			finishers[1] = "none"
		end
		return finishers
	end

	local function slotdata(name: string): any
		local rankBase, _rank = parseRankCharm(name)
		local lookup = rankBase or name
		local info = cosmetics and cosmetics.Cosmetics and cosmetics.Cosmetics[lookup]
		if type(info) == "table" then
			local copy = table.clone(info)
			copy.Name = lookup
			return copy
		end
		return { Name = lookup }
	end

	local function equippedcosmetic(name: string): any
		local data = slotdata(name)
		local rankBase, rankName = parseRankCharm(name)
		if rankBase and rankName then
			data.Name = rankBase
			local elo, board = rankMeta(rankName)
			data.Metadata = {
				SeasonELO = elo,
				SeasonLeaderboardRank = board,
				SonataRankName = rankName,
			}
			return data
		end
		if type(name) == "string" and string.match(name, "^Season %d+$") then
			data.Name = name
			data.Metadata = {
				SeasonELO = RANKED_CHARM_ELO,
				SeasonLeaderboardRank = RANKED_CHARM_LEADERBOARD,
				SonataRankName = "Archnemesis",
			}
		end
		return data
	end

	local function installskins(): boolean
		local client = clientPlayer()
		local scripts = playerscripts()
		if not client or not scripts then
			return false
		end

		local okItems, loadedItems = pcall(require, ReplicatedStorage.Modules.ItemLibrary)
		local okCosmetics, loadedCosmetics = pcall(require, ReplicatedStorage.Modules.CosmeticLibrary)
		local okUtility, utilityModule = pcall(require, ReplicatedStorage.Modules.Utility)
		local okAnim, animationLibrary = pcall(require, ReplicatedStorage.Modules.AnimationLibrary)
		local okSound, soundLibrary = pcall(require, ReplicatedStorage.Modules.SoundLibrary)
		local okWrap, wrapController = pcall(require, scripts.Controllers.WrapController)
		local okFighter, fighterController = pcall(require, scripts.Controllers.FighterController)
		local okView, viewclass = pcall(require, scripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem.ClientViewModel)
		if not (okItems and okCosmetics and okUtility and okAnim and okSound and okWrap and okFighter and okView) then
			return false
		end

		items = loadedItems
		cosmetics = loadedCosmetics
		refreshImageSources()
		if type(viewclass._UpdateLocalTransparencyModifier) == "function" and not rawget(viewclass, "__sonataTransparencyGuard") then
			rawset(viewclass, "__sonataTransparencyGuard", true)
			viewclass._UpdateLocalTransparencyModifier = function(self: any, part: any)
				if type(self) ~= "table" or part == nil then
					return
				end
				local pending = self._local_transparency_modifier_update
				if type(pending) ~= "table" then
					pending = {}
					self._local_transparency_modifier_update = pending
				end
				pending[part] = true
				task.defer(function()
					if type(self) ~= "table" then
						return
					end
					local updates = self._local_transparency_modifier_update
					if type(updates) ~= "table" or not updates[part] then
						return
					end
					updates[part] = nil
					local buckets = self._local_transparency_modifiers
					local values = type(buckets) == "table" and buckets[part] or nil
					if type(values) ~= "table" then
						return
					end
					local maxT = 0
					for _, value in values do
						if type(value) == "number" and value > maxT then
							maxT = value
						end
					end
					if typeof(part) ~= "Instance" then
						return
					end
					pcall(function()
						(part :: Instance).LocalTransparencyModifier = maxT
						for _, descendant in (part :: Instance):GetDescendants() do
							if descendant:IsA("Texture")
								or descendant:IsA("Beam")
								or descendant:IsA("ParticleEmitter")
								or descendant:IsA("Trail")
								or descendant:IsA("Decal")
							then
								descendant.LocalTransparencyModifier = maxT
							end
						end
					end)
				end)
			end
		end
		if type(viewclass._IsSubmodelBehindHead) == "function" and not rawget(viewclass, "__sonataBehindHeadGuard") then
			rawset(viewclass, "__sonataBehindHeadGuard", true)
			local previousBehind = viewclass._IsSubmodelBehindHead
			viewclass._IsSubmodelBehindHead = function(self: any, submodel: any, rotation: any)
				local map = type(self) == "table" and self._submodel_boundingbox_attachments
				if type(map) ~= "table" or typeof(submodel) ~= "Instance" or type(map[submodel]) ~= "table" then
					return false
				end
				return previousBehind(self, submodel, rotation)
			end
		end
		local viewmodels = scripts.Assets.ViewModels
		local lookup = utilityModule.LookThrough
		local previousWrap = rawget(viewclass, "__sonataOriginalGetWrap") or viewclass.GetWrap
		pcall(function()
			rawset(viewclass, "__sonataOriginalGetWrap", previousWrap)
		end)
		local muzzleFlashes = scripts.Assets.Misc:FindFirstChild("MuzzleFlashes")

		hookGameMethod(wrapController.ApplyWrap, function(previousApply, ...)
			local packed = table.pack(pcall(previousApply, ...))
			if not packed[1] then
				return {}
			end
			local result = packed[2]
			if type(result) ~= "table" then
				return {}
			end
			return result
		end)

		local function safeWrapTable(original: any, name: string?): { [string]: any }
			local copy: { [string]: any }
			if type(original) == "table" then
				copy = table.clone(original)
			else
				copy = {}
			end
			if type(name) == "string" and name ~= "" then
				copy.Name = name
			elseif type(copy.Name) ~= "string" then
				copy.Name = ""
			end
			if type(copy.WrapGroups) ~= "table" then
				copy.WrapGroups = {}
			end
			if type(copy.HideInThirdPerson) ~= "boolean" then
				copy.HideInThirdPerson = false
			end
			return copy
		end

		viewclass.GetWrap = function(self, ...)
			local wrapOk, original = pcall(previousWrap, self, ...)
			if not wrapOk or type(original) ~= "table" then
				original = nil
			elseif type(original.Name) ~= "string"
				or (type(cosmetics) == "table" and type(cosmetics.Cosmetics) == "table" and cosmetics.Cosmetics[original.Name] == nil)
			then
				original = nil
			end
			local weapon = self.ClientItem and self.ClientItem.Name
			local wrap = if type(weapon) == "string" then wrapmap[weapon] else nil
			local info = if type(wrap) == "string" and wrap ~= "" and type(cosmetics) == "table" and type(cosmetics.Cosmetics) == "table"
				then cosmetics.Cosmetics[wrap]
				else nil
			if type(info) ~= "table" then
				return original
			end
			local copy = safeWrapTable(info, wrap)
			if type(info.WrapGroups) == "table" then
				copy.WrapGroups = info.WrapGroups
			end
			return copy
		end

		local function modelFor(name: string): Instance?
			if type(name) ~= "string" or name == "" then
				return nil
			end
			local ok, model = pcall(function()
				return lookup(utilityModule, viewmodels, name)
			end)
			if ok and typeof(model) == "Instance" then
				return model
			end
			ok, model = pcall(function()
				return viewmodels:FindFirstChild(name, true)
			end)
			if ok and typeof(model) == "Instance" then
				return model
			end
			return nil
		end

		local function eachviewmodel(weapon: string, fn: (any) -> ())
			local mine = fighterController.LocalFighter
			if not mine or typeof(mine.Items) ~= "table" then
				return
			end
			for _, item in mine.Items do
				if typeof(item) == "table" and item.Name == weapon then
					local vm = item.ViewModel
					if typeof(vm) == "table" and vm.Model then
						fn(vm)
					end
				end
			end
			pcall(function()
				local equipped = mine.EquippedItem or mine:Get("EquippedItem")
				if typeof(equipped) == "table" and equipped.Name == weapon then
					local vm = equipped.ViewModel
					if typeof(vm) == "table" and vm.Model then
						fn(vm)
					end
				end
			end)
		end

		local function attrCFrame(inst: Instance, name: string, fallback: CFrame): CFrame
			local value = inst:GetAttribute(name)
			if typeof(value) == "CFrame" then
				local cf: CFrame = value :: any
				return cf
			end
			return fallback
		end

		local BOUNDING_CORNERS = {
			Vector3.new(0.5, 0.5, 0.5),
			Vector3.new(-0.5, 0.5, 0.5),
			Vector3.new(-0.5, 0.5, -0.5),
			Vector3.new(0.5, 0.5, -0.5),
			Vector3.new(0.5, -0.5, 0.5),
			Vector3.new(-0.5, -0.5, 0.5),
			Vector3.new(-0.5, -0.5, -0.5),
			Vector3.new(0.5, -0.5, -0.5),
		}

		local function weld(vm: any, itemModel: Instance)
			local rootCandidate = vm.Model.PrimaryPart or vm.Model:FindFirstChild("HumanoidRootPart")
			if typeof(rootCandidate) ~= "Instance" or not (rootCandidate :: Instance):IsA("BasePart") then
				return
			end
			local root = rootCandidate :: BasePart
			itemModel.Name = "ItemVisual"
			itemModel.Parent = vm.Model
			vm.ItemModel = itemModel
			vm._arm_submodels = if typeof(vm._arm_submodels) == "table" then vm._arm_submodels else {}
			table.clear(vm._arm_submodels)
			vm._submodel_boundingbox_attachments = if typeof(vm._submodel_boundingbox_attachments) == "table" then vm._submodel_boundingbox_attachments else {}
			table.clear(vm._submodel_boundingbox_attachments)
			vm._submodels_behind_head_values = if typeof(vm._submodels_behind_head_values) == "table" then vm._submodels_behind_head_values else {}
			table.clear(vm._submodels_behind_head_values)
			vm._animation_context_submodels = if typeof(vm._animation_context_submodels) == "table" then vm._animation_context_submodels else {}
			table.clear(vm._animation_context_submodels)
			local origin: CFrame? = nil
			local children = itemModel:GetChildren()
			for _, child in children do
				if child.Name == "_fake" then
					vm._can_wrap_left_arm = child:FindFirstChild("LeftArmWrapped") ~= nil
					vm._can_wrap_right_arm = child:FindFirstChild("RightArmWrapped") ~= nil
					child:Destroy()
				elseif child:IsA("Model") then
					local primaryCandidate = child:FindFirstChild("Primary")
					if not primaryCandidate or not primaryCandidate:IsA("BasePart") then
						continue
					end
					local primary = primaryCandidate :: BasePart
					child.PrimaryPart = primary
					origin = origin or primary.CFrame
					local arm = child.Name == "_right_arm" and "RightArm" or (child.Name == "_left_arm" and "LeftArm" or nil)
					local limb = if arm then vm.Model:FindFirstChild(arm) else nil
					if arm and limb and limb:IsA("BasePart") then
						local scaleOk, scale = pcall(function()
							return child:GetScale()
						end)
						vm._arm_submodels[child] = {
							OriginalScale = if scaleOk and type(scale) == "number" then scale else 1,
							HideInThirdPerson = child:GetAttribute("HideInThirdPerson") == true,
						}
						child.Parent = limb
						pcall(function()
							child:PivotTo(limb.CFrame)
						end)
						local weldPart = Instance.new("WeldConstraint")
						weldPart.Part0 = limb
						weldPart.Part1 = primary
						weldPart.Parent = primary
					else
						local motor = Instance.new("Motor6D")
						motor.Part0 = root
						motor.Part1 = primary
						motor.Name = 'ItemVisual["' .. child.Name .. '"]'
						local pivot = origin or primary.CFrame
						motor.C0 = attrCFrame(child, "C0", primary.CFrame:ToObjectSpace(pivot):Inverse())
						motor.C1 = attrCFrame(child, "C1", CFrame.identity)
						motor.Parent = root
						primary.Name = child.Name .. "Primary"
						pcall(function()
							child:PivotTo(root.CFrame)
						end)
						vm._submodel_boundingbox_attachments[child] = {}
						local okBox, boxCf, boxSize = pcall(function()
							return child:GetBoundingBox()
						end)
						if okBox and typeof(boxCf) == "CFrame" and typeof(boxSize) == "Vector3" then
							for index, cornerOffset in BOUNDING_CORNERS do
								local attachment = Instance.new("Attachment")
								attachment.Name = "_boundingbox" .. tostring(index)
								attachment.Parent = primary
								attachment.WorldCFrame = boxCf * CFrame.new(boxSize * cornerOffset)
								table.insert(vm._submodel_boundingbox_attachments[child], attachment)
							end
						end
					end
					for _, descendant in child:GetDescendants() do
						if descendant:IsA("BasePart") then
							descendant.CastShadow = false
							descendant.CanCollide = false
							descendant.CanTouch = false
							descendant.CanQuery = false
							descendant.Massless = true
							if descendant ~= primary then
								local weldPart = Instance.new("WeldConstraint")
								weldPart.Part0 = primary
								weldPart.Part1 = descendant
								weldPart.Parent = primary
								descendant.Anchored = false
							end
						end
					end
					primary.Anchored = false
				end
			end
			vm._body_model = itemModel:FindFirstChild("Body")
			vm._aim_position_attachment = vm.Model:FindFirstChild("_aim_position", true)
			vm._aim_lookat_attachment = vm.Model:FindFirstChild("_aim_lookat", true)
			vm._center_attachment = vm.Model:FindFirstChild("_center", true)
			vm._charm_attachment_model = vm.Model:FindFirstChild("_charm_attachment_model", true)
			vm._charm_pivot_attachment = if vm._charm_attachment_model
				then vm._charm_attachment_model:FindFirstChild("_charm_pivot_attachment", true)
				else vm.Model:FindFirstChild("_charm_pivot_attachment", true)
			vm._muzzle_attachments = {}
			for _, descendant in vm.Model:GetDescendants() do
				if descendant.Name == "_muzzle" then
					table.insert(vm._muzzle_attachments, descendant)
					if muzzleFlashes then
						local flash = muzzleFlashes:FindFirstChild(vm.Name)
							or muzzleFlashes:FindFirstChild(vm.ClientItem.Name)
							or muzzleFlashes:FindFirstChild("Default")
						local attachment = flash and flash:FindFirstChild("Attachment")
						if attachment then
							for _, flashChild in attachment:GetChildren() do
								flashChild:Clone().Parent = descendant
							end
						end
					end
				end
			end
			if typeof(vm._local_transparency_modifier_update) == "table" then
				table.clear(vm._local_transparency_modifier_update)
			end
			if typeof(vm._local_transparency_modifiers) == "table" then
				table.clear(vm._local_transparency_modifiers)
			end
			pcall(function()
				vm:_UpdateHiddenArmSubmodels(true)
			end)
		end

		local function clearvisual(vm: any)
			local root = vm.Model.PrimaryPart or vm.Model:FindFirstChild("HumanoidRootPart")
			if root then
				for _, child in root:GetChildren() do
					if child:IsA("Motor6D") and string.sub(child.Name, 1, 10) == "ItemVisual" then
						child:Destroy()
					end
				end
			end
			if typeof(vm._arm_submodels) == "table" then
				for model in vm._arm_submodels do
					if typeof(model) == "Instance" then
						model:Destroy()
					end
				end
				table.clear(vm._arm_submodels)
			end
			if typeof(vm._submodel_boundingbox_attachments) == "table" then
				table.clear(vm._submodel_boundingbox_attachments)
			end
			if typeof(vm._submodels_behind_head_values) == "table" then
				table.clear(vm._submodels_behind_head_values)
			end
			if vm.ItemModel then
				vm.ItemModel:Destroy()
				vm.ItemModel = nil
			end
			if typeof(vm._animation_context_submodels) == "table" then
				table.clear(vm._animation_context_submodels)
			end
			if typeof(vm._local_transparency_modifier_update) == "table" then
				table.clear(vm._local_transparency_modifier_update)
			end
			if typeof(vm._local_transparency_modifiers) == "table" then
				table.clear(vm._local_transparency_modifiers)
			end
		end

		local function loadsounds(vm: any)
			if not vm._preloaded_sounds or not vm.Info or typeof(vm.Info.Animations) ~= "table" then
				return
			end
			for _, key in vm.Info.Animations do
				local sounds = soundLibrary.AnimationSounds[key]
				if sounds then
					pcall(function()
						soundLibrary:PreloadSounds(sounds, vm._preloaded_sounds)
					end)
				end
			end
			local extra = soundLibrary.ViewModelSounds[vm.Name]
			if extra then
				pcall(function()
					soundLibrary:PreloadSounds(extra, vm._preloaded_sounds)
				end)
			end
		end

		local function loadanims(vm: any)
			local animator = vm.Animator
			local controller = vm.Model:FindFirstChild("AnimationController")
			local player = controller and controller:FindFirstChild("Animator")
			if not animator or not player or not vm.Info or typeof(vm.Info.Animations) ~= "table" then
				return
			end
			if typeof(animator._animation_tracks) == "table" then
				for _, track in animator._animation_tracks do
					pcall(function()
						track:Stop(0)
						track:Destroy()
					end)
				end
				table.clear(animator._animation_tracks)
			else
				animator._animation_tracks = {}
			end
			if typeof(animator._animation_keys_lookup) == "table" then
				table.clear(animator._animation_keys_lookup)
			end
			animator._viewmodel_animations = vm.Info.Animations
			animator._play_animations_instantly = vm.Info.PlayAnimationsInstantly
			animator._animations_loaded = true
			for key, animName in vm.Info.Animations do
				local info = animationLibrary.Info[animName]
				if info and info.AnimationID then
					local animation = Instance.new("Animation")
					animation.AnimationId = info.AnimationID
					animation.Parent = vm.Model
					local loadOk, track = pcall(function()
						return player:LoadAnimation(animation)
					end)
					if loadOk and track then
						animator._animation_tracks[key] = track
					end
				end
			end
			pcall(function()
				animator:ChangeEquipAnimation("Equip")
			end)
			pcall(function()
				animator:ChangeIdleAnimation("Idle")
			end)
			pcall(function()
				animator:ChangeSprintAnimation("Sprint")
			end)
			pcall(function()
				animator:PlayIdleAnimation()
			end)
		end

		local function refreshwrap(vm: any)
			if vm._original_wrap_properties then
				pcall(function()
					wrapController:ResetWrap(vm._original_wrap_properties)
				end)
				vm._original_wrap_properties = nil
			end
			pcall(function()
				vm:_UpdateWrap()
			end)
		end

		local shownimage: { [string]: string } = {}
		local imagewatch: { [string]: string } = {}

		local function watchimage(from: string?, to: string?)
			if type(from) == "string" and type(to) == "string" and from ~= to then
				imagewatch[from] = to
			end
		end

		local function paintimages(weapon: string)
			local skinName = skinmap[weapon]
			local skin = skinName and cosmetics.Cosmetics[skinName]
			local item = items.Items[weapon]
			local nextImage = entryimage(skin) or entryimage(item)
			if not nextImage then
				return
			end
			local wanted: { [string]: boolean } = {}
			if shownimage[weapon] then
				wanted[shownimage[weapon]] = true
				watchimage(shownimage[weapon], nextImage)
			end
			local base = entryimage(item)
			if base then
				wanted[base] = true
				watchimage(base, nextImage)
			end
			local wSkins = skinsfor(weapon)
			for _, sName in wSkins do
				local sData = cosmetics and cosmetics.Cosmetics and cosmetics.Cosmetics[sName]
				local img = entryimage(sData)
				if img then
					wanted[img] = true
					watchimage(img, nextImage)
				end
			end
			local gui = client:FindFirstChild("PlayerGui")
			if not gui then
				return
			end
			for _, obj in gui:GetDescendants() do
				if (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) and wanted[obj.Image] then
					obj.Image = nextImage
				elseif obj:IsA("TextLabel") and obj.Text == weapon and obj.Parent then
					for _, child in obj.Parent:GetDescendants() do
						if child:IsA("ImageLabel") or child:IsA("ImageButton") then
							local lower = string.lower(child.Name)
							if string.find(lower, "icon", 1, true)
								or string.find(lower, "image", 1, true)
								or string.find(lower, "thumb", 1, true)
								or string.find(lower, "weapon", 1, true)
							then
								child.Image = nextImage
							end
						end
					end
				end
			end
			shownimage[weapon] = nextImage
		end

		local tracerTemplates: { [string]: { Instance } } = {}

		local function istracer(obj: Instance): boolean
			local classOk, className = pcall(function()
				return obj.ClassName
			end)
			return classOk and (className == "Beam" or className == "Trail" or className == "ParticleEmitter")
		end

		local function copytracer(from: Instance, to: Instance)
			pcall(function()
				if from.ClassName ~= to.ClassName then
					return
				end
				local override: Color3? = nil
				pcall(function()
					local bridge = (_G :: any).__atomware_rivals_bridge
					local fx = type(bridge) == "table" and bridge.ClientFx
					if type(fx) == "table" and fx.tracers == true and typeof(fx.tracerColor) == "Color3" then
						override = fx.tracerColor
					end
				end)
				if from:IsA("Beam") and to:IsA("Beam") then
					to.Color = if override then ColorSequence.new(override) else from.Color
					to.Transparency = from.Transparency
					to.Texture = if override then "" else from.Texture
					to.Width0 = from.Width0
					to.Width1 = from.Width1
					to.LightEmission = from.LightEmission
					to.TextureSpeed = from.TextureSpeed
					to.TextureLength = from.TextureLength
				elseif from:IsA("Trail") and to:IsA("Trail") then
					to.Color = if override then ColorSequence.new(override) else from.Color
					to.Transparency = from.Transparency
					to.Texture = if override then "" else from.Texture
					to.Lifetime = from.Lifetime
					to.LightEmission = from.LightEmission
					to.WidthScale = from.WidthScale
				elseif from:IsA("ParticleEmitter") and to:IsA("ParticleEmitter") then
					to.Color = if override then ColorSequence.new(override) else from.Color
					to.Transparency = from.Transparency
					to.Texture = from.Texture
					to.LightEmission = from.LightEmission
					to.Rate = from.Rate
					to.Lifetime = from.Lifetime
					to.Speed = from.Speed
					to.Size = from.Size
				end
			end)
		end

		local function collecttracers(root: Instance?): { Instance }
			local list = {}
			if not root then
				return list
			end
			local ok, descendants = pcall(function()
				return root:GetDescendants()
			end)
			if not ok then
				return list
			end
			for _, obj in next, descendants do
				if istracer(obj) then
					table.insert(list, obj)
				end
			end
			return list
		end

		local function painttracers(root: Instance?, weapon: string)
			local templates = tracerTemplates[weapon]
			if not templates or not templates[1] or not root then
				return
			end
			for _, obj in next, collecttracers(root) do
				for _, from in next, templates do
					if from.ClassName == obj.ClassName then
						copytracer(from, obj)
						break
					end
				end
			end
		end

		local function heldweapon(): string?
			local mine = fighterController.LocalFighter
			if not mine then
				return nil
			end
			local ok, item = pcall(function()
				return mine.EquippedItem or mine:Get("EquippedItem")
			end)
			if ok and type(item) == "table" and type(item.Name) == "string" then
				return item.Name
			end
			return nil
		end
		heldWeaponFn = heldweapon

		local function applyextra(weapon: string)
			local mine = fighterController.LocalFighter
			if not weapon or not mine or type(mine.Items) ~= "table" then
				return
			end
			local CharmClass
			pcall(function()
				CharmClass = require(scripts.Modules.Charm)
			end)
			local charmFolder = scripts.Modules:FindFirstChild("Charms")

			local function attachcharm(vm: any, data: any)
				if type(vm) ~= "table" or typeof(vm.Model) ~= "Instance" then
					return
				end
				if type(vm.Charm) == "table" and type(vm.Charm.Destroy) == "function" then
					pcall(function()
						vm.Charm:Destroy()
					end)
				end
				vm.Charm = nil
				if not data then
					return
				end
				local pivot = vm._charm_pivot_attachment
				if typeof(pivot) ~= "Instance" or pivot.Parent == nil then
					pivot = vm.Model:FindFirstChild("_charm_pivot_attachment", true)
					vm._charm_pivot_attachment = pivot
				end
				if typeof(pivot) ~= "Instance" or type(CharmClass) ~= "table" then
					return
				end
				local class = CharmClass
				local custom = charmFolder and charmFolder:FindFirstChild(data.Name, true)
				if custom and custom:IsA("ModuleScript") then
					local loadOk, loaded = pcall(require, custom)
					if loadOk and type(loaded) == "table" and type(loaded.new) == "function" then
						class = loaded
					end
				end
				local charmOk, charm = pcall(function()
					return class.new(vm, data, pivot)
				end)
				if charmOk and type(charm) == "table" then
					vm.Charm = charm
					pcall(function()
						charm:SetParent(vm.Model)
					end)
					local meta = type(data) == "table" and data.Metadata
					if type(meta) == "table" then
						applyRankToCharm(charm, meta.SonataRankName, meta.SeasonELO, meta.SeasonLeaderboardRank)
					end
				end
			end

			local function stampCharmRank(vm: any, data: any)
				if type(vm) ~= "table" or type(data) ~= "table" then
					return
				end
				local meta = data.Metadata
				if type(meta) ~= "table" then
					return
				end
				local charmObj = vm.Charm
				if type(charmObj) == "table" then
					applyRankToCharm(charmObj, meta.SonataRankName, meta.SeasonELO, meta.SeasonLeaderboardRank)
				elseif typeof(vm.Model) == "Instance" then
					forceSeasonRankOnModel(vm.Model, meta.SonataRankName, meta.SeasonLeaderboardRank)
				end
			end

			local charmKey = if charmon[weapon] then charmmap[weapon] else nil
			local finisherKey = if finisheron[weapon] then finishermap[weapon] else nil
			local charmData = if charmKey then equippedcosmetic(charmKey) else nil
			local finisherData = if finisherKey then equippedcosmetic(finisherKey) else nil
			for _, item in mine.Items do
				if type(item) == "table" and item.Name == weapon then
					pcall(function()
						if charmData then
							item.Charm = charmData
						end
						if finisherData then
							item.Finisher = finisherData
						end
						local vm = item.ViewModel
						if type(vm) == "table" then
							if type(vm.SetCharm) == "function" then
								vm:SetCharm(charmData)
							else
								attachcharm(vm, charmData)
							end
							stampCharmRank(vm, charmData)
							if charmData and type(charmData.Metadata) == "table" and charmData.Metadata.SonataRankName then
								task.defer(stampCharmRank, vm, charmData)
								task.delay(0.05, stampCharmRank, vm, charmData)
								task.delay(0.2, stampCharmRank, vm, charmData)
							end
							if finisherData then
								vm.Finisher = finisherData
							end
						end
					end)
				end
			end
		end

		local function apply(weapon: string)
			local skin = skinmap[weapon]
			local wrap = wrapmap[weapon]
			eachviewmodel(weapon, function(vm)
				local okApply, _errApply = pcall(function()
					if type(vm) ~= "table" or vm._destroyed or not vm.Model then
						return
					end
					vm._baseName = vm._baseName or vm.Name or weapon
					local target = skin
					if vm._shownSkin ~= target and (target or vm._shownSkin) then
						local cosmeticName = target or vm._baseName
						local source = modelFor(cosmeticName)
						if not source and target then
							source = modelFor(weapon) or modelFor(vm._baseName)
						end
						local info = (items.ViewModels and (items.ViewModels[cosmeticName] or items.ViewModels[weapon] or items.ViewModels[vm._baseName])) or nil
						local root = vm.Model.PrimaryPart or vm.Model:FindFirstChild("HumanoidRootPart") or vm.Model:FindFirstChildWhichIsA("BasePart")
						if source and root then
							if typeof(info) ~= "table" then
								info = {
									RootPartOffset = CFrame.identity,
									Animations = {},
								}
							end
							local model = source:Clone()
							local previousName = vm.Name
							local previousInfo = vm.Info
							local builtOk, _builtErr = pcall(function()
								clearvisual(vm)
								vm.Name = cosmeticName
								local infoCopy = table.clone(info)
								if type(infoCopy.Animations) ~= "table" then
									infoCopy.Animations = {}
								end
								if typeof(infoCopy.RootPartOffset) ~= "CFrame" then
									infoCopy.RootPartOffset = CFrame.identity
								end
								vm.Info = infoCopy
								vm._root_part_offset_inverse = infoCopy.RootPartOffset:Inverse()
								local playerName = "???"
								pcall(function()
									local fighter = vm.ClientItem and vm.ClientItem.ClientFighter
									local player = fighter and fighter.Player
									if player and type(player.Name) == "string" then
										playerName = player.Name
									end
								end)
								local itemName = weapon
								pcall(function()
									if vm.ClientItem and type(vm.ClientItem.Name) == "string" then
										itemName = vm.ClientItem.Name
									end
								end)
								vm.Model.Name = playerName .. " - " .. tostring(itemName) .. " - " .. tostring(cosmeticName)
								weld(vm, model)
								if typeof(vm.ItemModel) ~= "Instance" and model.Parent == nil then
									error("weld produced no ItemModel")
								end
								pcall(loadsounds, vm)
								pcall(loadanims, vm)
							end)
							if builtOk then
								vm._shownSkin = target
								vm._shownWrap = nil
								if target then
									pcall(function()
										tracerTemplates[weapon] = collecttracers(source)
										painttracers(vm.Model, weapon)
									end)
								else
									tracerTemplates[weapon] = nil
								end
							else
								pcall(function()
									model:Destroy()
								end)
								pcall(function()
									vm.Name = previousName
									if type(previousInfo) == "table" then
										vm.Info = previousInfo
									end
								end)
								pcall(function()
									local fallbackName = vm._baseName or weapon
									local fallback = modelFor(fallbackName)
									if fallback and (vm.Model.PrimaryPart or vm.Model:FindFirstChildWhichIsA("BasePart")) then
										clearvisual(vm)
										vm.Name = fallbackName
										local fallbackInfo = (items.ViewModels and items.ViewModels[fallbackName]) or previousInfo
										if typeof(fallbackInfo) == "table" then
											local copy = table.clone(fallbackInfo)
											if type(copy.Animations) ~= "table" then
												copy.Animations = {}
											end
											if typeof(copy.RootPartOffset) ~= "CFrame" then
												copy.RootPartOffset = CFrame.identity
											end
											vm.Info = copy
											vm._root_part_offset_inverse = copy.RootPartOffset:Inverse()
										end
										weld(vm, fallback:Clone())
										pcall(loadsounds, vm)
										pcall(loadanims, vm)
										vm._shownSkin = nil
									end
								end)
								warn("skin said no thanks", weapon, cosmeticName)
							end
						end
					end
					if vm._shownWrap ~= wrap then
						pcall(refreshwrap, vm)
						vm._shownWrap = wrap
					end
				end)
				if not okApply then
					warn("viewmodel had a moment", weapon)
				end
			end)
			if skin then
				pcall(paintimages, weapon)
			end
			pcall(applyextra, weapon)
		end

		local function schedule(weapon: string?)
			if weapon
				and (
					skinmap[weapon]
					or wrapmap[weapon]
					or charmon[weapon]
					or finisheron[weapon]
				)
			then
				task.defer(function()
					apply(weapon)
				end)
			end
		end

		local previousNew = viewclass.new
		viewclass.new = function(...)
			local vm = previousNew(...)
			task.defer(function()
				if type(vm) ~= "table" or vm._destroyed then
					return
				end
				local clientItem = vm.ClientItem
				local weaponName = if type(clientItem) == "table" then clientItem.Name else nil
				if type(weaponName) == "string" then
					schedule(weaponName)
				end
			end)
			return vm
		end

		local mine = fighterController.LocalFighter
		if mine and mine.ItemAdded then
			mine.ItemAdded:Connect(function(item)
				local weaponName = if type(item) == "table" then item.Name else nil
				if type(weaponName) == "string" then
					schedule(weaponName)
				end
			end)
		end

		getWeapons()

		local function grant(copy: any, name: string, weapon: string)
			if type(name) ~= "string" or name == "" then
				return
			end
			local current = copy[name]
			if current == true then
				return
			end
			if type(current) ~= "table" then
				current = {}
				copy[name] = current
			end
			current[weapon] = true
		end

		local function spoofinventory(value: any): any
			if type(value) ~= "table" then
				return value
			end
			local copy = table.clone(value)
			for weapon, name in next, charmmap do
				if charmon[weapon] then
					local rankBase = parseRankCharm(name)
					grant(copy, rankBase or name, weapon)
				end
			end
			for weapon, name in next, finishermap do
				if finisheron[weapon] then
					grant(copy, name, weapon)
				end
			end
			return copy
		end

		local function hookslot(class: any, method: string, map: { [string]: string }, enabled: { [string]: boolean })
			if type(class) ~= "table" or type(class[method]) ~= "function" then
				return
			end
			hookGameMethod(class[method], function(previous, self, ...)
				local ok, original = pcall(previous, self, ...)
				if not ok or type(original) ~= "table" then
					original = nil
				end
				local clientItem = self.ClientItem
				local weaponName = if type(clientItem) == "table" then clientItem.Name else self.Name
				local weapon = if type(weaponName) == "string" then weaponName else nil
				local picked = if weapon and enabled[weapon] then map[weapon] else nil
				if type(picked) ~= "string" then
					return original
				end
				local dataOk, data = pcall(equippedcosmetic, picked)
				if not dataOk or type(data) ~= "table" then
					return original
				end
				return data
			end)
		end

		hookslot(viewclass, "GetCharm", charmmap, charmon)
		hookslot(viewclass, "GetFinisher", finishermap, finisheron)

		pcall(function()
			local charmClass = require(scripts.Modules.Charm)
			if type(charmClass) == "table" and type(charmClass._SetupSeasonRankCharm) == "function" and not charmClass.__sonataRankSetup then
				local hooked = hookGameMethod(charmClass._SetupSeasonRankCharm, function(previousSetup, self, ...)
					local meta = type(self) == "table" and type(self.EquippedData) == "table" and self.EquippedData.Metadata
					local rankName = type(meta) == "table" and meta.SonataRankName or nil
					local elo = type(meta) == "table" and meta.SeasonELO or nil
					local board = type(meta) == "table" and meta.SeasonLeaderboardRank or nil
					if type(rankName) == "string" and rankName ~= "" then
						applyRankToCharm(self, rankName, elo, board)
						task.defer(applyRankToCharm, self, rankName, elo, board)
						task.delay(0.05, applyRankToCharm, self, rankName, elo, board)
						return
					end
					local ver = type(self.Name) == "string" and tonumber(string.sub(self.Name, 8)) or nil
					local seasonOk = type(ver) == "number"
						and type(seasonLibrary) == "table"
						and type(seasonLibrary.SeasonsByVersion) == "table"
						and seasonLibrary.SeasonsByVersion[ver] ~= nil
					if seasonOk then
						local okCall = pcall(previousSetup, self, ...)
						if not okCall and type(elo) == "number" then
							applyRankToCharm(self, nil, elo, board)
						end
						return
					end
					if type(elo) == "number" then
						applyRankToCharm(self, nil, elo, board)
					end
				end)
				if hooked then
					charmClass.__sonataRankSetup = true
				end
			end
		end)

		if type(viewclass.Get) == "function" and not viewclass.__sonataGet then
			local hookedGet = hookGameMethod(viewclass.Get, function(previousGet, self, key, ...)
				local clientItem = self.ClientItem
				local weaponName = if type(clientItem) == "table" then clientItem.Name else self.Name
				local weapon = if type(weaponName) == "string" then weaponName else nil
				if key == "Wrap" then
					local wrap = if weapon then wrapmap[weapon] else nil
					local info = if type(wrap) == "string" and wrap ~= "" and type(cosmetics) == "table" and type(cosmetics.Cosmetics) == "table"
						then cosmetics.Cosmetics[wrap]
						else nil
					if type(info) == "table" then
						local copy = safeWrapTable(info, wrap)
						if type(info.WrapGroups) == "table" then
							copy.WrapGroups = info.WrapGroups
						end
						return copy
					end
					local okWrap, wrapVal = pcall(previousGet, self, key, ...)
					return if okWrap then wrapVal else nil
				end
				if key == "Charm" and weapon and charmon[weapon] then
					local charm = charmmap[weapon]
					if type(charm) == "string" then
						local dataOk, data = pcall(equippedcosmetic, charm)
						if dataOk and type(data) == "table" then
							return data
						end
					end
				end
				if key == "Finisher" and weapon and finisheron[weapon] then
					local finisher = finishermap[weapon]
					if type(finisher) == "string" then
						local dataOk, data = pcall(equippedcosmetic, finisher)
						if dataOk and type(data) == "table" then
							return data
						end
					end
				end
				local ok, value = pcall(previousGet, self, key, ...)
				if not ok then
					return nil
				end
				if key == "Wrap" and type(value) ~= "table" then
					return safeWrapTable(nil, nil)
				end
				return value
			end)
			if hookedGet then
				viewclass.__sonataGet = true
			end
		end
		pcall(function()
			local itemclass = require(scripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem)
			hookslot(itemclass, "GetCharm", charmmap, charmon)
			hookslot(itemclass, "GetFinisher", finishermap, finisheron)
		end)
		pcall(function()
			local dataController = require(scripts.Controllers.PlayerDataController)
			local function installMethodHook(tbl: any, key: string, wrap: any): boolean
				local current = tbl[key]
				if type(current) ~= "function" then
					return false
				end
				local old = hookGameMethod(current, function(previous, ...)
					return wrap(previous, ...)
				end)
				return type(old) == "function"
			end
			if not dataController.__sonataInventory then
				local okInv = installMethodHook(dataController, "Get", function(previousData, self, key, ...)
					local ok, value = pcall(previousData, self, key, ...)
					if not ok then
						return nil
					end
					if key == "CosmeticInventory" then
						return spoofinventory(value)
					end
					return value
				end)
				if okInv then
					dataController.__sonataInventory = true
				end
			end
			if not dataController.__sonataWeapon then
				local okWeapon = installMethodHook(dataController, "GetWeaponData", function(previousWeapon, self, weaponName, ...)
					local ok, data = pcall(previousWeapon, self, weaponName, ...)
					if not ok then
						return nil
					end
					if type(weaponName) ~= "string" or type(data) ~= "table" then
						return data
					end
					local charmName = if charmon[weaponName] then charmmap[weaponName] else nil
					local finisherName = if finisheron[weaponName] then finishermap[weaponName] else nil
					if type(charmName) ~= "string" and type(finisherName) ~= "string" then
						return data
					end
					local copy: { [string]: any } = table.clone(data) :: any
					if type(charmName) == "string" then
						local charmOk, charmData = pcall(equippedcosmetic, charmName)
						if charmOk then
							copy.Charm = charmData
						end
					end
					if type(finisherName) == "string" then
						local finOk, finData = pcall(equippedcosmetic, finisherName)
						if finOk then
							copy.Finisher = finData
						end
					end
					return copy
				end)
				if okWeapon then
					dataController.__sonataWeapon = true
				end
			end
		end)
		pcall(function()
			local entityClass = require(scripts.Modules.ClientReplicatedClasses.ClientEntity)
			if type(entityClass._PlayFinisher) ~= "function" or entityClass.__sonataFinisher then
				return
			end
			local previousFinisher = hookGameMethod(entityClass._PlayFinisher, function(old, self, name, finalHit, eliminator, ...)
				local localFighter = fighterController.LocalFighter
				local equipped = localFighter and localFighter.EquippedItem
				if type(equipped) ~= "table" and localFighter and type(localFighter.Get) == "function" then
					local getOk, item = pcall(function()
						return localFighter:Get("EquippedItem")
					end)
					equipped = getOk and item or equipped
				end
				local weapon = type(equipped) == "table" and equipped.Name
				local picked = weapon and finisheron[weapon] and finishermap[weapon]
				local mineKill = eliminator == client
					or eliminator == client.UserId
					or (typeof(eliminator) == "Instance" and eliminator == client)
					or (type(eliminator) == "table" and (eliminator.Player == client or eliminator.IsLocalPlayer == true))
				if picked and mineKill then
					name = picked
				end
				local ok, a, b, c, d, e, f = (pcall :: any)(old, self, name, finalHit, eliminator, ...)
				if not ok then
					return nil
				end
				return a, b, c, d, e, f
			end)
			if previousFinisher then
				entityClass.__sonataFinisher = true
			end
		end)

		Workspace.DescendantAdded:Connect(function(obj)
			if not istracer(obj) then
				return
			end
			local weapon = heldweapon()
			if not weapon or not tracerTemplates[weapon] then
				return
			end
			for _, from in next, tracerTemplates[weapon] do
				if from.ClassName == obj.ClassName then
					copytracer(from, obj)
					return
				end
			end
		end)

		local gui = client:FindFirstChild("PlayerGui")
		if gui then
			gui.DescendantAdded:Connect(function(obj)
				if not (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) then
					return
				end
				local nextImage = imagewatch[obj.Image]
				if nextImage then
					obj.Image = nextImage
				end
			end)
		end

		applyFn = apply
		applyExtraFn = applyextra
		return true
	end

	api = {
		ready = false,
		skinmap = skinmap,
		wrapmap = wrapmap,
		charmmap = charmmap,
		finishermap = finishermap,
		charmon = charmon,
		finisheron = finisheron,
		weapons = weapons,
		wraps = wraps,
		charms = charms,
		finishers = finishers,
		install = function(self)
			if self.ready or installing then
				return self.ready
			end
			installing = true
			local ok, result = pcall(installskins)
			installing = false
			self.ready = ok and result == true
			return self.ready
		end,
		getWeapons = function(_self)
			return getWeapons()
		end,
		getWraps = function(_self)
			return getWraps()
		end,
		getCharms = function(_self)
			return getCharms()
		end,
		getFinishers = function(_self)
			return getFinishers()
		end,
		skinsFor = function(_self, weapon)
			return skinsfor(weapon)
		end,
		rarityColor = function(_self, name)
			if name == "default" or name == "none" then
				return Color3.fromRGB(180, 180, 180)
			end
			local rankBase = parseRankCharm(name)
			local lookup = rankBase or name
			local data = cosmetics and cosmetics.Cosmetics and cosmetics.Cosmetics[lookup]
			return raritycolor(data)
		end,
		entryImage = function(_self, name)
			if not name or name == "" or name == "default" or name == "none" then
				return nil
			end
			if imageCache[name] ~= nil then
				return imageCache[name]
			end
			local rankBase = parseRankCharm(name)
			local lookup = rankBase or name
			local data = cosmetics and cosmetics.Cosmetics and cosmetics.Cosmetics[lookup]
			local image, tint = resolveCosmeticImage(name, data)
			imageCache[name] = image
			if tint ~= nil then
				tintCache[name] = tint
			end
			return image
		end,
		entryTint = function(_self, name)
			if not name or name == "" or name == "default" or name == "none" then
				return nil
			end
			if tintCache[name] ~= nil then
				return tintCache[name]
			end
			local rankBase = parseRankCharm(name)
			local lookup = rankBase or name
			local data = cosmetics and cosmetics.Cosmetics and cosmetics.Cosmetics[lookup]
			local image, tint = resolveCosmeticImage(name, data)
			if image ~= nil then
				imageCache[name] = image
			end
			tintCache[name] = tint
			return tint
		end,
		previewImage = function(self, weapon, mode)
			if mode == "skins" then
				local skin = skinmap[weapon]
				if skin then
					return self:entryImage(skin)
				end
				return entryimage(items and items.Items and items.Items[weapon])
			elseif mode == "wraps" then
				local wrap = wrapmap[weapon]
				return if wrap then self:entryImage(wrap) else nil
			elseif mode == "charms" then
				local charm = charmmap[weapon]
				return if charm then self:entryImage(charm) else nil
			elseif mode == "finishers" then
				local finisher = finishermap[weapon]
				return if finisher then self:entryImage(finisher) else nil
			end
			return nil
		end,
		heldWeapon = function(_self)
			if heldWeaponFn then
				local ok, result = pcall(heldWeaponFn)
				if ok and type(result) == "string" and result ~= "" then
					return result
				end
			end
			return nil
		end,
		apply = function(_self, weapon)
			if applyFn then
				pcall(applyFn, weapon)
			end
		end,
		applyExtra = function(_self, weapon)
			if applyExtraFn then
				pcall(applyExtraFn, weapon)
			end
		end,
		setSelection = function(self, mode, weapon, option)
			if not weapon or weapon == "" then
				return
			end
			local cleared = option == nil or option == "" or option == "default" or option == "none"
			if mode == "skins" then
				if cleared then
					skinmap[weapon] = nil :: any
				elseif type(option) == "string" then
					skinmap[weapon] = option
				end
				self:apply(weapon)
			elseif mode == "wraps" then
				if cleared then
					wrapmap[weapon] = nil :: any
				elseif type(option) == "string" then
					wrapmap[weapon] = option
				end
				self:apply(weapon)
			elseif mode == "charms" then
				if cleared then
					charmmap[weapon] = nil :: any
					charmon[weapon] = nil :: any
				elseif type(option) == "string" then
					charmmap[weapon] = option
					charmon[weapon] = true
				end
				self:applyExtra(weapon)
			elseif mode == "finishers" then
				if cleared then
					finishermap[weapon] = nil :: any
					finisheron[weapon] = nil :: any
				elseif type(option) == "string" then
					finishermap[weapon] = option
					finisheron[weapon] = true
				end
				self:applyExtra(weapon)
			end
		end,
		restore = function(self, config)
			if type(config) ~= "table" then
				return
			end
			table.clear(skinmap)
			table.clear(wrapmap)
			table.clear(charmmap)
			table.clear(finishermap)
			table.clear(charmon)
			table.clear(finisheron)
			if type(config.skins) == "table" then
				for weapon, skin in next, config.skins do
					if type(weapon) == "string" and type(skin) == "string" and skin ~= "" and skin ~= "default" then
						skinmap[weapon] = skin
					end
				end
			end
			if type(config.wraps) == "table" then
				for weapon, wrap in next, config.wraps do
					if type(weapon) == "string" and type(wrap) == "string" and wrap ~= "" and wrap ~= "default" then
						wrapmap[weapon] = wrap
					end
				end
			end
			if type(config.charms) == "table" then
				for weapon, name in next, config.charms do
					if type(weapon) == "string" and type(name) == "string" and name ~= "" then
						charmmap[weapon] = name
						charmon[weapon] = true
					end
				end
			end
			if type(config.finishers) == "table" then
				for weapon, name in next, config.finishers do
					if type(weapon) == "string" and type(name) == "string" and name ~= "" then
						finishermap[weapon] = name
						finisheron[weapon] = true
					end
				end
			end
			local pending: { [string]: boolean } = {}
			for weapon in next, skinmap do
				pending[weapon] = true
			end
			for weapon in next, wrapmap do
				pending[weapon] = true
			end
			for weapon in next, charmon do
				pending[weapon] = true
			end
			for weapon in next, finisheron do
				pending[weapon] = true
			end
			task.defer(function()
				for weapon in next, pending do
					pcall(function()
						self:apply(weapon)
						if charmon[weapon] or finisheron[weapon] then
							self:applyExtra(weapon)
						end
					end)
				end
			end)
		end,
		export = function(_self)
			local skins = {}
			local wrapsOut = {}
			local charmsOut = {}
			local finishersOut = {}
			for weapon, skin in next, skinmap do
				skins[weapon] = skin
			end
			for weapon, wrap in next, wrapmap do
				wrapsOut[weapon] = wrap
			end
			for weapon, name in next, charmmap do
				if charmon[weapon] then
					charmsOut[weapon] = name
				end
			end
			for weapon, name in next, finishermap do
				if finisheron[weapon] then
					finishersOut[weapon] = name
				end
			end
			return skins, wrapsOut, charmsOut, finishersOut
		end,
		clearAll = function(self)
			local pending: { [string]: boolean } = {}
			for _, map in { skinmap, wrapmap, charmon, finisheron } do
				for weapon in next, map do
					pending[weapon] = true
				end
			end
			table.clear(skinmap)
			table.clear(wrapmap)
			table.clear(charmmap)
			table.clear(finishermap)
			table.clear(charmon)
			table.clear(finisheron)
			for weapon in next, pending do
				pcall(function()
					self:apply(weapon)
					self:applyExtra(weapon)
				end)
			end
		end,
		randomizeAll = function(self)
			local allWeapons = getWeapons()
			local allWraps = getWraps()
			local allCharms = getCharms()
			local allFinishers = getFinishers()
			local rng = Random.new()
			local validCharms: { string } = {}
			for _, name in allCharms do
				if name ~= "none" and name ~= "default" and name ~= "" then
					table.insert(validCharms, name)
				end
			end
			local validFinishers: { string } = {}
			for _, name in allFinishers do
				if name ~= "none" and name ~= "default" and name ~= "" then
					table.insert(validFinishers, name)
				end
			end
			local validWraps: { string } = {}
			for _, name in allWraps do
				if name ~= "default" and name ~= "none" and name ~= "" then
					table.insert(validWraps, name)
				end
			end

			for _, weapon in allWeapons do
				local wSkins = skinsfor(weapon)
				local candidateSkins: { string } = {}
				for _, s in wSkins do
					if s ~= "default" and s ~= "" then
						table.insert(candidateSkins, s)
					end
				end
				if #candidateSkins > 0 then
					skinmap[weapon] = candidateSkins[rng:NextInteger(1, #candidateSkins)]
				else
					skinmap[weapon] = nil :: any
				end

				if #validWraps > 0 then
					wrapmap[weapon] = validWraps[rng:NextInteger(1, #validWraps)]
				else
					wrapmap[weapon] = nil :: any
				end

				if #validCharms > 0 then
					charmmap[weapon] = validCharms[rng:NextInteger(1, #validCharms)]
					charmon[weapon] = true
				else
					charmmap[weapon] = nil :: any
					charmon[weapon] = nil :: any
				end

				if #validFinishers > 0 then
					finishermap[weapon] = validFinishers[rng:NextInteger(1, #validFinishers)]
					finisheron[weapon] = true
				else
					finishermap[weapon] = nil :: any
					finisheron[weapon] = nil :: any
				end

				pcall(function()
					self:apply(weapon)
					self:applyExtra(weapon)
				end)
			end
		end,
	}

	return api
end

local Cosmetics = createCosmetics()
task.defer(function()
	pcall(function()
		if not game:IsLoaded() then
			pcall(function()
				game.Loaded:Wait()
			end)
		end
		Cosmetics:install()
	end)
end)

local function element(className: string, props: { [string]: any }, children: { Instance }?): Instance
	local object = Instance.new(className) :: any
	if className == "ScreenGui" then
		table.insert(SESSION.guis, object)
	end
	if children then
		for _, child in children do
			child.Parent = object
		end
	end
	local parent = props.Parent
	for key, value in props do
		if key ~= "Parent" then
			object[key] = value
		end
	end
	if parent ~= nil then
		object.Parent = parent
	end
	return object
end

local function resolveParent(parent: Instance?): Instance
	if parent then
		return cloneRef(parent)
	end
	local hidden = fsGethui()
	if hidden then
		return cloneRef(hidden)
	end
	local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
	return cloneRef(player:WaitForChild("PlayerGui"))
end


_G.AtomwareRivalsCosmetics = Cosmetics
return Cosmetics
