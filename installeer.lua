-- LOADEN CITY TYCOON - installer
-- Plak dit hele bestand in de Command Bar van Roblox Studio (View > Command Bar) en druk op Enter.

local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

local function put(class, name, parent, source)
	local old = parent:FindFirstChild(name)
	if old then old:Destroy() end
	local inst = Instance.new(class)
	inst.Name = name
	inst.Source = source
	inst.Parent = parent
	return inst
end

local shared = RS:FindFirstChild("Shared") or Instance.new("Folder")
shared.Name = "Shared"
shared.Parent = RS

put("ModuleScript", "Config", shared, [==[
-- Gedeelde instellingen: gebouwen, stadsniveaus en grondgebied.
-- Alles wat je wilt balanceren staat hier.

local Config = {}

Config.CellSize = 8 -- studs per rastervakje
Config.StartLand = 48 -- beginperceel (6x6 vakjes)
Config.MaxLand = 240
Config.LandStep = 16
Config.StartCoins = 100
Config.PlotSpacing = 400 -- afstand tussen spelers in de wereld

-- Stadsniveau hangt af van het aantal inwoners.
Config.Tiers = {
	{ name = "Gehucht", pop = 0 },
	{ name = "Dorp", pop = 20 },
	{ name = "Stad", pop = 100 },
	{ name = "Grote stad", pop = 400 },
	{ name = "Metropool", pop = 1500 },
}

-- tier = vanaf welk stadsniveau het gebouw te koop is.
-- cells = footprint in rastervakjes, height = hoogte in studs.
Config.Buildings = {
	{ id = "House", name = "Huisje", cost = 50, income = 1, pop = 4, cells = { 1, 1 }, height = 6, color = Color3.fromRGB(252, 228, 150), roof = Color3.fromRGB(205, 95, 65), tier = 1 },
	{ id = "Park", name = "Parkje", cost = 80, income = 1, pop = 0, cells = { 2, 2 }, height = 1, color = Color3.fromRGB(110, 200, 90), tier = 1 },
	{ id = "Shop", name = "Donutwinkel", cost = 250, income = 6, pop = 2, cells = { 1, 1 }, height = 9, color = Color3.fromRGB(255, 150, 190), roof = Color3.fromRGB(255, 235, 200), tier = 2 },
	{ id = "Apartment", name = "Flat", cost = 900, income = 20, pop = 40, cells = { 2, 2 }, height = 24, color = Color3.fromRGB(214, 160, 110), roof = Color3.fromRGB(120, 120, 130), tier = 3 },
	{ id = "Factory", name = "Kerncentrale", cost = 2500, income = 70, pop = 10, cells = { 3, 2 }, height = 14, color = Color3.fromRGB(160, 180, 160), roof = Color3.fromRGB(90, 90, 100), tier = 4 },
	{ id = "Office", name = "Kantoor", cost = 6000, income = 180, pop = 60, cells = { 2, 2 }, height = 45, color = Color3.fromRGB(120, 170, 225), roof = Color3.fromRGB(80, 80, 100), tier = 4 },
	{ id = "Skyscraper", name = "Wolkenkrabber", cost = 25000, income = 800, pop = 200, cells = { 2, 2 }, height = 90, color = Color3.fromRGB(245, 205, 80), roof = Color3.fromRGB(80, 80, 100), tier = 5 },
}

Config.ById = {}
for _, def in Config.Buildings do
	Config.ById[def.id] = def
end

function Config.GetTier(pop: number): number
	local tier = 1
	for i, t in Config.Tiers do
		if pop >= t.pop then
			tier = i
		end
	end
	return tier
end

-- Kosten om het perceel een stap groter te maken. nil = maximaal.
function Config.ExpandCost(land: number): number?
	if land >= Config.MaxLand then
		return nil
	end
	local steps = (land - Config.StartLand) / Config.LandStep
	return math.floor(200 * 2.2 ^ steps)
end

-- Rekent een positie (relatief aan het perceel) om naar het linkerbovenvakje
-- van een gebouw, zodat het gebouw rond de muis gecentreerd wordt.
function Config.SnapCell(def, relX: number, relZ: number): (number, number)
	local fx, fz = def.cells[1], def.cells[2]
	local gx = math.floor(relX / Config.CellSize - fx / 2 + 0.5)
	local gz = math.floor(relZ / Config.CellSize - fz / 2 + 0.5)
	return gx, gz
end

-- Past de footprint binnen het perceel?
function Config.InBounds(def, gx: number, gz: number, land: number): boolean
	local n = land / Config.CellSize
	local lo, hi = -n / 2, n / 2 - 1
	return gx >= lo and gz >= lo and gx + def.cells[1] - 1 <= hi and gz + def.cells[2] - 1 <= hi
end

return Config

]==])

put("Script", "Main", SSS, [==[
-- Server: wereld, percelen, economie, plaatsen van gebouwen en opslaan.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local Config = require(ReplicatedStorage.Shared.Config)
local store = DataStoreService:GetDataStore("LoadenCityTycoonV1")

-- Remotes -------------------------------------------------------------------
local remotes = Instance.new("Folder")
remotes.Name = "CityRemotes"
remotes.Parent = ReplicatedStorage

local stateEvent = Instance.new("RemoteEvent")
stateEvent.Name = "State"
stateEvent.Parent = remotes

local placeFn = Instance.new("RemoteFunction")
placeFn.Name = "Place"
placeFn.Parent = remotes

local expandFn = Instance.new("RemoteFunction")
expandFn.Name = "Expand"
expandFn.Parent = remotes

-- Wereld ---------------------------------------------------------------------
local ground = Instance.new("Part")
ground.Name = "Ground"
ground.Anchored = true
ground.Size = Vector3.new(12000, 2, 2000)
ground.Position = Vector3.new(5000, -1, 0)
ground.Color = Color3.fromRGB(120, 190, 85)
ground.Material = Enum.Material.Grass
ground.TopSurface = Enum.SurfaceType.Smooth
ground.Parent = workspace

-- Sfeer: zonnige blauwe lucht met witte wolkjes
local Lighting = game:GetService("Lighting")
Lighting.ClockTime = 14
Lighting.Brightness = 3
Lighting.OutdoorAmbient = Color3.fromRGB(170, 170, 190)
local atmosphere = Instance.new("Atmosphere")
atmosphere.Density = 0.15
atmosphere.Color = Color3.fromRGB(150, 200, 255)
atmosphere.Parent = Lighting
local clouds = Instance.new("Clouds")
clouds.Cover = 0.55
clouds.Density = 0.35
clouds.Parent = workspace.Terrain

-- Iedereen is geel
local YELLOW = Color3.fromRGB(255, 217, 15)
local function yellowify(char: Model)
	local bc = char:FindFirstChildOfClass("BodyColors") or Instance.new("BodyColors")
	bc.HeadColor3, bc.TorsoColor3 = YELLOW, YELLOW
	bc.LeftArmColor3, bc.RightArmColor3 = YELLOW, YELLOW
	bc.LeftLegColor3, bc.RightLegColor3 = YELLOW, YELLOW
	bc.Parent = char
end

-- Spelerstatus ---------------------------------------------------------------
type State = {
	coins: number,
	land: number,
	slot: number,
	origin: Vector3,
	buildings: { { id: string, gx: number, gz: number } },
	occ: { [string]: boolean },
	income: number,
	pop: number,
	plot: Part,
	folder: Folder,
	loaded: boolean,
}

local states: { [Player]: State } = {}
local usedSlots: { [number]: boolean } = {}

local function freeSlot(): number
	local i = 0
	while usedSlots[i] do
		i += 1
	end
	usedSlots[i] = true
	return i
end

local function cellKey(gx: number, gz: number): string
	return gx .. "," .. gz
end

local function push(player: Player, s: State)
	stateEvent:FireClient(player, {
		coins = s.coins,
		land = s.land,
		origin = s.origin,
		income = s.income,
		pop = s.pop,
		tier = Config.GetTier(s.pop),
		expandCost = Config.ExpandCost(s.land),
	})
end

local function footprintFree(s: State, def, gx: number, gz: number): boolean
	for x = gx, gx + def.cells[1] - 1 do
		for z = gz, gz + def.cells[2] - 1 do
			if s.occ[cellKey(x, z)] then
				return false
			end
		end
	end
	return true
end

local function newPart(s: State, name: string, size: Vector3, pos: Vector3, color: Color3, material: Enum.Material?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.Position = pos
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = s.folder
	return part
end

local function buildModel(s: State, def, gx: number, gz: number)
	local cs = Config.CellSize
	local w, d, h = def.cells[1] * cs - 0.6, def.cells[2] * cs - 0.6, def.height
	local c = s.origin + Vector3.new((gx + def.cells[1] / 2) * cs, 0.2, (gz + def.cells[2] / 2) * cs)
	local top = c + Vector3.new(0, h, 0)

	newPart(s, def.id, Vector3.new(w, h, d), c + Vector3.new(0, h / 2, 0), def.color,
		def.id == "Park" and Enum.Material.Grass or nil)

	if def.roof then
		newPart(s, "Dak", Vector3.new(w + 1, 0.8, d + 1), top + Vector3.new(0, 0.4, 0), def.roof)
	end

	-- Raampjes voor hogere gebouwen (voorkant naar -Z)
	if h >= 20 then
		for y = 6, h - 6, 8 do
			for x = -w / 2 + 3, w / 2 - 3, 4 do
				newPart(s, "Raam", Vector3.new(2, 3, 0.3), c + Vector3.new(x, y, -d / 2 - 0.1),
					Color3.fromRGB(255, 240, 150), Enum.Material.Neon)
			end
		end
	end

	if def.id == "Factory" then
		-- Twee koeltorens
		for _, dx in { -w / 4, w / 4 } do
			local tower = newPart(s, "Koeltoren", Vector3.new(22, 7, 7), top + Vector3.new(dx, 11.8, 0),
				Color3.fromRGB(185, 195, 185))
			tower.Shape = Enum.PartType.Cylinder
			tower.Orientation = Vector3.new(0, 0, 90)
		end
	elseif def.id == "Shop" then
		-- Reuzendonut op het dak
		local donut = newPart(s, "Donut", Vector3.new(2, 6, 6), top + Vector3.new(0, 3.5, 0),
			Color3.fromRGB(235, 150, 190))
		donut.Shape = Enum.PartType.Cylinder
		donut.Orientation = Vector3.new(0, 0, 90)
	end
end

local function addBuilding(s: State, def, gx: number, gz: number, record: boolean)
	for x = gx, gx + def.cells[1] - 1 do
		for z = gz, gz + def.cells[2] - 1 do
			s.occ[cellKey(x, z)] = true
		end
	end
	s.income += def.income
	s.pop += def.pop
	if record then
		table.insert(s.buildings, { id = def.id, gx = gx, gz = gz })
	end
	buildModel(s, def, gx, gz)
end

local function resizePlot(s: State)
	s.plot.Size = Vector3.new(s.land, 0.4, s.land)
end

-- Laden / opslaan ------------------------------------------------------------
local function save(player: Player)
	local s = states[player]
	if not s or not s.loaded then
		return
	end
	local data = { coins = s.coins, land = s.land, buildings = s.buildings }
	for attempt = 1, 3 do
		local ok = pcall(function()
			store:SetAsync(tostring(player.UserId), data)
		end)
		if ok then
			return
		end
		task.wait(1)
	end
	warn("Opslaan mislukt voor", player.Name)
end

local function setup(player: Player)
	local slot = freeSlot()
	local origin = Vector3.new(slot * Config.PlotSpacing, 0, 0)

	local folder = Instance.new("Folder")
	folder.Name = "Stad_" .. player.Name
	folder.Parent = workspace

	local plot = Instance.new("Part")
	plot.Name = "Perceel"
	plot.Anchored = true
	plot.Color = Color3.fromRGB(175, 225, 120)
	plot.Material = Enum.Material.Grass
	plot.Position = origin + Vector3.new(0, 0.1, 0)
	plot.Parent = folder

	local s: State = {
		coins = Config.StartCoins,
		land = Config.StartLand,
		slot = slot,
		origin = origin,
		buildings = {},
		occ = {},
		income = 0,
		pop = 0,
		plot = plot,
		folder = folder,
		loaded = false,
	}
	states[player] = s
	resizePlot(s)

	-- Opgeslagen voortgang laden
	local ok, data = pcall(function()
		return store:GetAsync(tostring(player.UserId))
	end)
	if ok and typeof(data) == "table" then
		s.coins = tonumber(data.coins) or s.coins
		s.land = math.clamp(tonumber(data.land) or s.land, Config.StartLand, Config.MaxLand)
		resizePlot(s)
		for _, b in data.buildings or {} do
			local def = Config.ById[b.id]
			if def and Config.InBounds(def, b.gx, b.gz, s.land) and footprintFree(s, def, b.gx, b.gz) then
				addBuilding(s, def, b.gx, b.gz, true)
			end
		end
	end
	s.loaded = ok -- bij een DataStore-fout niet overschrijven

	local function spawnAt(char: Model)
		task.wait()
		char:PivotTo(CFrame.new(origin + Vector3.new(0, 6, s.land / 2 + 8)))
	end
	player.CharacterAppearanceLoaded:Connect(yellowify)
	if player.Character then
		yellowify(player.Character)
	end
	player.CharacterAdded:Connect(spawnAt)
	if player.Character then
		spawnAt(player.Character)
	end

	push(player, s)
end

-- Acties ----------------------------------------------------------------------
placeFn.OnServerInvoke = function(player, id, worldPos)
	local s = states[player]
	if not s or typeof(id) ~= "string" or typeof(worldPos) ~= "Vector3" then
		return false, "Ongeldig verzoek"
	end
	local def = Config.ById[id]
	if not def then
		return false, "Onbekend gebouw"
	end
	if Config.GetTier(s.pop) < def.tier then
		return false, "Nog niet ontgrendeld"
	end
	if s.coins < def.cost then
		return false, "Te weinig munten"
	end
	local rel = worldPos - s.origin
	local gx, gz = Config.SnapCell(def, rel.X, rel.Z)
	if not Config.InBounds(def, gx, gz, s.land) then
		return false, "Buiten je perceel"
	end
	if not footprintFree(s, def, gx, gz) then
		return false, "Hier staat al iets"
	end
	s.coins -= def.cost
	addBuilding(s, def, gx, gz, true)
	push(player, s)
	return true, def.name .. " gebouwd!"
end

expandFn.OnServerInvoke = function(player)
	local s = states[player]
	if not s then
		return false, "Ongeldig verzoek"
	end
	local cost = Config.ExpandCost(s.land)
	if not cost then
		return false, "Je perceel is al maximaal"
	end
	if s.coins < cost then
		return false, "Te weinig munten"
	end
	s.coins -= cost
	s.land += Config.LandStep
	resizePlot(s)
	push(player, s)
	return true, "Perceel uitgebreid!"
end

-- Inkomsten --------------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(1)
		for player, s in states do
			if s.income > 0 then
				s.coins += s.income
				push(player, s)
			end
		end
	end
end)

-- Levenscyclus -------------------------------------------------------------------
Players.PlayerAdded:Connect(setup)
for _, p in Players:GetPlayers() do
	task.spawn(setup, p)
end

Players.PlayerRemoving:Connect(function(player)
	save(player)
	local s = states[player]
	if s then
		usedSlots[s.slot] = nil
		s.folder:Destroy()
	end
	states[player] = nil
end)

game:BindToClose(function()
	for player in states do
		task.spawn(save, player)
	end
	task.wait(2)
end)

-- Autosave elke 60 seconden
task.spawn(function()
	while true do
		task.wait(60)
		for player in states do
			task.spawn(save, player)
		end
	end
end)

]==])

put("LocalScript", "Client", SPS, [==[
-- Client: HUD, bouwmenu en plaatsen met een "spookgebouw" onder je muis.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("CityRemotes")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local state = nil
local selected = nil
local ghost: Part? = nil
local buttons = {}

local function fmt(n: number): string
	if n >= 1e6 then
		return string.format("%.1fM", n / 1e6)
	elseif n >= 1e4 then
		return string.format("%.1fK", n / 1e3)
	end
	return tostring(math.floor(n))
end

-- UI ---------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "StadUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function label(parent, size, pos, textSize)
	local l = Instance.new("TextLabel")
	l.Size = size
	l.Position = pos
	l.BackgroundTransparency = 1
	l.TextColor3 = Color3.fromRGB(40, 40, 90)
	l.Font = Enum.Font.FredokaOne
	l.TextSize = textSize
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

local function panel(parent, size, pos)
	local f = Instance.new("Frame")
	f.Size = size
	f.Position = pos
	f.BackgroundColor3 = Color3.fromRGB(255, 217, 15)
	f.BackgroundTransparency = 0
	f.BorderSizePixel = 0
	f.Parent = parent
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)
	local stroke = Instance.new("UIStroke", f)
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(40, 40, 90)
	return f
end

local top = panel(gui, UDim2.fromOffset(330, 92), UDim2.fromOffset(12, 12))
local coinsLabel = label(top, UDim2.new(1, -20, 0, 32), UDim2.fromOffset(12, 6), 26)
local cityLabel = label(top, UDim2.new(1, -20, 0, 22), UDim2.fromOffset(12, 40), 16)
local incomeLabel = label(top, UDim2.new(1, -20, 0, 22), UDim2.fromOffset(12, 64), 16)
incomeLabel.TextColor3 = Color3.fromRGB(30, 120, 50)

local toast = label(gui, UDim2.fromOffset(400, 30), UDim2.new(0.5, -200, 0, 20), 20)
toast.TextXAlignment = Enum.TextXAlignment.Center
toast.TextTransparency = 1
toast.TextStrokeTransparency = 0

local toastToken = 0
local function showToast(text: string, good: boolean)
	toastToken += 1
	local token = toastToken
	toast.Text = text
	toast.TextColor3 = good and Color3.fromRGB(140, 230, 140) or Color3.fromRGB(255, 120, 120)
	toast.TextTransparency = 0
	task.delay(2, function()
		if token == toastToken then
			toast.TextTransparency = 1
		end
	end)
end

local bar = panel(gui, UDim2.new(1, -24, 0, 96), UDim2.new(0, 12, 1, -108))
local list = Instance.new("UIListLayout")
list.FillDirection = Enum.FillDirection.Horizontal
list.Padding = UDim.new(0, 8)
list.VerticalAlignment = Enum.VerticalAlignment.Center
list.Parent = bar
local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, 8)
pad.Parent = bar

local function makeButton(text: string, color: Color3)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(130, 80)
	b.BackgroundColor3 = color
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.FredokaOne
	b.TextSize = 14
	b.TextWrapped = true
	b.Text = text
	b.AutoButtonColor = true
	b.Parent = bar
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	return b
end

-- Spookgebouw --------------------------------------------------------------------
local function clearGhost()
	if ghost then
		ghost:Destroy()
		ghost = nil
	end
	selected = nil
	mouse.TargetFilter = nil
end

local function select(def)
	clearGhost()
	if not def then
		return
	end
	selected = def
	local g = Instance.new("Part")
	g.Anchored = true
	g.CanCollide = false
	g.CanQuery = false
	g.Transparency = 0.5
	g.Material = Enum.Material.Neon
	g.Size = Vector3.new(def.cells[1] * Config.CellSize, def.height, def.cells[2] * Config.CellSize)
	g.Parent = workspace
	ghost = g
	mouse.TargetFilter = g
end

for _, def in Config.Buildings do
	local b = makeButton("", Color3.fromRGB(60, 90, 140))
	b.Activated:Connect(function()
		if state and Config.GetTier(state.pop) >= def.tier then
			select(selected == def and nil or def)
		else
			showToast("Nog niet ontgrendeld: bereik " .. Config.Tiers[def.tier].name, false)
		end
	end)
	buttons[def.id] = b
end

local expandButton = makeButton("", Color3.fromRGB(150, 100, 40))
expandButton.Activated:Connect(function()
	local ok, msg = remotes.Expand:InvokeServer()
	showToast(msg, ok)
end)

local function refreshUI()
	if not state then
		return
	end
	coinsLabel.Text = "💰 " .. fmt(state.coins)
	cityLabel.Text = string.format("%s · %s inwoners", Config.Tiers[state.tier].name, fmt(state.pop))
	incomeLabel.Text = "+" .. fmt(state.income) .. " per seconde"
	for _, def in Config.Buildings do
		local b = buttons[def.id]
		local unlocked = state.tier >= def.tier
		if unlocked then
			b.Text = string.format("%s\n💰 %s\n+%s/s", def.name, fmt(def.cost), fmt(def.income))
			b.BackgroundColor3 = state.coins >= def.cost and Color3.fromRGB(70, 130, 220) or Color3.fromRGB(120, 120, 135)
		else
			b.Text = string.format("%s\n🔒 %s", def.name, Config.Tiers[def.tier].name)
			b.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
		end
	end
	if state.expandCost then
		expandButton.Text = string.format("Land vergroten\n💰 %s", fmt(state.expandCost))
	else
		expandButton.Text = "Land is maximaal"
	end
end

remotes.State.OnClientEvent:Connect(function(newState)
	state = newState
	refreshUI()
end)

-- Plaatsen -------------------------------------------------------------------------
local function snapped(def)
	local rel = mouse.Hit.Position - state.origin
	return Config.SnapCell(def, rel.X, rel.Z)
end

RunService.RenderStepped:Connect(function()
	if not (ghost and selected and state) then
		return
	end
	local def = selected
	local gx, gz = snapped(def)
	local cs = Config.CellSize
	ghost.Position = state.origin + Vector3.new((gx + def.cells[1] / 2) * cs, def.height / 2 + 0.2, (gz + def.cells[2] / 2) * cs)
	local ok = Config.InBounds(def, gx, gz, state.land) and state.coins >= def.cost
	ghost.Color = ok and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(255, 80, 80)
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.X then
		clearGhost()
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 and selected and state then
		local ok, msg = remotes.Place:InvokeServer(selected.id, mouse.Hit.Position)
		showToast(msg, ok)
	end
end)

]==])

local base = workspace:FindFirstChild("Baseplate")
if base then base:Destroy() end

print("Loaden City Tycoon geinstalleerd! Druk op Play.")
