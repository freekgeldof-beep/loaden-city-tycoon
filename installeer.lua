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
Config.ParcelCells = 6 -- een stuk land is 6x6 vakjes
Config.ParcelSize = 48 -- = ParcelCells * CellSize
Config.StartCoins = 100
Config.ParcelSpacing = 16 -- afstand tussen startplekken van spelers, in stukken land

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
	{ id = "Kiosk", name = "Kiosk", cost = 120, income = 3, pop = 0, cells = { 1, 1 }, height = 5, color = Color3.fromRGB(255, 170, 60), roof = Color3.fromRGB(230, 80, 80), tier = 1 },
	{ id = "Shop", name = "Donutwinkel", cost = 250, income = 6, pop = 2, cells = { 1, 1 }, height = 9, color = Color3.fromRGB(255, 150, 190), roof = Color3.fromRGB(255, 235, 200), tier = 2 },
	{ id = "Bar", name = "Kroeg", cost = 400, income = 10, pop = 0, cells = { 2, 1 }, height = 8, color = Color3.fromRGB(150, 100, 70), roof = Color3.fromRGB(80, 50, 40), tier = 2 },
	{ id = "Church", name = "Kerkje", cost = 500, income = 8, pop = 6, cells = { 2, 2 }, height = 10, color = Color3.fromRGB(235, 235, 225), roof = Color3.fromRGB(150, 80, 70), tier = 2 },
	{ id = "Supermarket", name = "Supermarkt", cost = 650, income = 16, pop = 4, cells = { 3, 2 }, height = 8, color = Color3.fromRGB(120, 200, 140), roof = Color3.fromRGB(90, 90, 100), tier = 2 },
	{ id = "Apartment", name = "Flat", cost = 900, income = 20, pop = 40, cells = { 2, 2 }, height = 24, color = Color3.fromRGB(214, 160, 110), roof = Color3.fromRGB(120, 120, 130), tier = 3 },
	{ id = "School", name = "School", cost = 1400, income = 30, pop = 20, cells = { 3, 2 }, height = 10, color = Color3.fromRGB(230, 190, 110), roof = Color3.fromRGB(160, 70, 60), tier = 3 },
	{ id = "Firestation", name = "Brandweerkazerne", cost = 1500, income = 25, pop = 10, cells = { 2, 2 }, height = 10, color = Color3.fromRGB(220, 70, 60), roof = Color3.fromRGB(90, 90, 100), tier = 3 },
	{ id = "Cinema", name = "Bioscoop", cost = 1800, income = 45, pop = 0, cells = { 2, 2 }, height = 12, color = Color3.fromRGB(120, 90, 170), roof = Color3.fromRGB(70, 60, 90), tier = 3 },
	{ id = "CityHall", name = "Stadhuis", cost = 3000, income = 55, pop = 20, cells = { 3, 2 }, height = 14, color = Color3.fromRGB(235, 225, 205), roof = Color3.fromRGB(120, 110, 100), tier = 3 },
	{ id = "Factory", name = "Kerncentrale", cost = 2500, income = 70, pop = 10, cells = { 3, 2 }, height = 14, color = Color3.fromRGB(160, 180, 160), roof = Color3.fromRGB(90, 90, 100), tier = 4 },
	{ id = "Hospital", name = "Ziekenhuis", cost = 5000, income = 130, pop = 80, cells = { 3, 3 }, height = 20, color = Color3.fromRGB(245, 245, 250), roof = Color3.fromRGB(150, 150, 160), tier = 4 },
	{ id = "Office", name = "Kantoor", cost = 6000, income = 180, pop = 60, cells = { 2, 2 }, height = 45, color = Color3.fromRGB(120, 170, 225), roof = Color3.fromRGB(80, 80, 100), tier = 4 },
	{ id = "Hotel", name = "Hotel", cost = 7500, income = 200, pop = 100, cells = { 2, 2 }, height = 36, color = Color3.fromRGB(230, 170, 120), roof = Color3.fromRGB(90, 60, 60), tier = 4 },
	{ id = "Stadium", name = "Stadion", cost = 9000, income = 260, pop = 0, cells = { 4, 4 }, height = 12, color = Color3.fromRGB(190, 190, 200), tier = 4 },
	{ id = "Skyscraper", name = "Wolkenkrabber", cost = 25000, income = 800, pop = 200, cells = { 2, 2 }, height = 90, color = Color3.fromRGB(245, 205, 80), roof = Color3.fromRGB(80, 80, 100), tier = 5 },
	{ id = "Radio", name = "Zendmast", cost = 30000, income = 900, pop = 0, cells = { 1, 1 }, height = 120, color = Color3.fromRGB(235, 235, 235), tier = 5 },
	{ id = "Funfair", name = "Pretpark", cost = 40000, income = 1400, pop = 0, cells = { 4, 4 }, height = 2, color = Color3.fromRGB(110, 200, 90), tier = 5 },
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

-- Prijs van het volgende stuk land, afhankelijk van hoeveel je er al hebt.
function Config.ParcelCost(owned: number): number
	return math.floor(150 * 1.18 ^ (owned - 1))
end

function Config.ParcelName(px: number, pz: number): string
	return "P_" .. px .. "_" .. pz
end

-- Welk stuk land hoort bij een wereldpositie / rastervakje
function Config.SnapParcel(worldCoord: number): number
	return math.floor(worldCoord / Config.ParcelSize)
end

function Config.ParcelOfCell(cell: number): number
	return math.floor(cell / Config.ParcelCells)
end

-- Rekent een wereldpositie om naar het hoekvakje van een gebouw,
-- zodat het gebouw rond de muis gecentreerd wordt.
function Config.SnapCell(def, x: number, z: number): (number, number)
	local fx, fz = def.cells[1], def.cells[2]
	local gx = math.floor(x / Config.CellSize - fx / 2 + 0.5)
	local gz = math.floor(z / Config.CellSize - fz / 2 + 0.5)
	return gx, gz
end

return Config

]==])

put("Script", "Main", SSS, [==[
-- Server: open wereld, land kopen, economie, plaatsen van gebouwen en opslaan.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Lighting = game:GetService("Lighting")

local Config = require(ReplicatedStorage.Shared.Config)
local store = DataStoreService:GetDataStore("LoadenCityTycoonV2")

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

local buyFn = Instance.new("RemoteFunction")
buyFn.Name = "Buy"
buyFn.Parent = remotes

-- Wereld: grote grasvlakte (een Part mag maximaal 2048 studs zijn, dus tegels) --
local parcelsFolder = Instance.new("Folder")
parcelsFolder.Name = "Parcels"
parcelsFolder.Parent = workspace

do
	local TILE = 2048
	for ix = -1, 4 do
		for iz = -1, 2 do
			local tile = Instance.new("Part")
			tile.Name = "Gras"
			tile.Anchored = true
			tile.Size = Vector3.new(TILE, 2, TILE)
			tile.Position = Vector3.new(ix * TILE + TILE / 2, -1, iz * TILE + TILE / 2)
			tile.Color = Color3.fromRGB(120, 190, 85)
			tile.Material = Enum.Material.Grass
			tile.TopSurface = Enum.SurfaceType.Smooth
			tile.Parent = workspace
		end
	end
end

-- Sfeer: zonnige blauwe lucht met witte wolkjes
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
	slot: number,
	home: Vector3,
	parcels: { [string]: Part },
	parcelCount: number,
	buildings: { { id: string, gx: number, gz: number } },
	occ: { [string]: boolean },
	income: number,
	pop: number,
	folder: Folder,
	loaded: boolean,
}

local states: { [Player]: State } = {}
local usedSlots: { [number]: boolean } = {}
local owners: { [string]: Player } = {} -- parcelnaam -> eigenaar

local function key(a: number, b: number): string
	return a .. "," .. b
end

local function isInt(n: any): boolean
	return typeof(n) == "number" and n == math.floor(n) and math.abs(n) < 1000
end

local function claimParcel(player: Player, s: State, px: number, pz: number)
	local name = Config.ParcelName(px, pz)
	local ps = Config.ParcelSize
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = Vector3.new(ps, 0.4, ps)
	part.Position = Vector3.new((px + 0.5) * ps, 0.1, (pz + 0.5) * ps)
	part.Color = Color3.fromRGB(175, 225, 120)
	part.Material = Enum.Material.Grass
	part:SetAttribute("OwnerId", player.UserId)
	part.Parent = parcelsFolder
	owners[name] = player
	s.parcels[key(px, pz)] = part
	s.parcelCount += 1
end

local function ownsParcel(s: State, px: number, pz: number): boolean
	return s.parcels[key(px, pz)] ~= nil
end

local function push(player: Player, s: State)
	stateEvent:FireClient(player, {
		coins = s.coins,
		income = s.income,
		pop = s.pop,
		tier = Config.GetTier(s.pop),
		parcelCount = s.parcelCount,
		parcelCost = Config.ParcelCost(s.parcelCount),
	})
end

local function footprintOk(s: State, def, gx: number, gz: number): (boolean, string?)
	for x = gx, gx + def.cells[1] - 1 do
		for z = gz, gz + def.cells[2] - 1 do
			if not ownsParcel(s, Config.ParcelOfCell(x), Config.ParcelOfCell(z)) then
				return false, "Dat land is niet van jou"
			end
			if s.occ[key(x, z)] then
				return false, "Hier staat al iets"
			end
		end
	end
	return true
end

-- Gebouwen bouwen --------------------------------------------------------------
local function add(s: State, name: string, size: Vector3, pos: Vector3, color: Color3, material: Enum.Material?, shape: Enum.PartType?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.Position = pos
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		part.Shape = shape
	end
	part.Parent = s.folder
	return part
end

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local function buildModel(s: State, def, gx: number, gz: number)
	local cs = Config.CellSize
	local w, d, h = def.cells[1] * cs - 0.6, def.cells[2] * cs - 0.6, def.height
	local c = Vector3.new((gx + def.cells[1] / 2) * cs, 0.2, (gz + def.cells[2] / 2) * cs)
	local id = def.id
	local function at(x: number, y: number, z: number): Vector3
		return c + Vector3.new(x, y, z)
	end

	-- Gebouwen met een eigen vorm
	if id == "Stadium" then
		local body = add(s, id, Vector3.new(h, w, d), at(0, h / 2, 0), def.color, nil, Enum.PartType.Cylinder)
		body.Orientation = Vector3.new(0, 0, 90)
		local field = add(s, "Veld", Vector3.new(0.4, w * 0.7, d * 0.7), at(0, h + 0.2, 0), rgb(90, 190, 80), Enum.Material.Grass, Enum.PartType.Cylinder)
		field.Orientation = Vector3.new(0, 0, 90)
		for _, p in { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } } do
			add(s, "Mast", Vector3.new(1, 12, 1), at(p[1] * w * 0.4, h + 6, p[2] * d * 0.4), rgb(120, 120, 130))
			add(s, "Lamp", Vector3.new(3, 1, 3), at(p[1] * w * 0.4, h + 12.5, p[2] * d * 0.4), rgb(255, 250, 200), Enum.Material.Neon)
		end
		return
	elseif id == "Radio" then
		for i = 0, 5 do
			add(s, "Mast", Vector3.new(3 - i * 0.3, h / 6, 3 - i * 0.3), at(0, h / 12 + i * h / 6, 0), i % 2 == 0 and rgb(220, 60, 60) or rgb(240, 240, 240))
		end
		add(s, "Lamp", Vector3.new(2, 2, 2), at(0, h + 1, 0), rgb(255, 80, 80), Enum.Material.Neon, Enum.PartType.Ball)
		return
	elseif id == "Funfair" then
		add(s, "Grond", Vector3.new(w, h, d), at(0, h / 2, 0), def.color, Enum.Material.Grass)
		local wheel = add(s, "Rad", Vector3.new(1, 26, 26), at(0, 15, 0), rgb(235, 80, 80), nil, Enum.PartType.Cylinder)
		local inner = add(s, "RadBinnen", Vector3.new(1.2, 22, 22), at(0, 15, 0), rgb(255, 250, 235), nil, Enum.PartType.Cylinder)
		wheel.Orientation, inner.Orientation = Vector3.zero, Vector3.zero
		add(s, "Poot", Vector3.new(2, 15, 2), at(0, 7.5, -3), rgb(120, 120, 130))
		add(s, "Poot", Vector3.new(2, 15, 2), at(0, 7.5, 3), rgb(120, 120, 130))
		add(s, "Kraam", Vector3.new(8, 6, 8), at(-w / 2 + 6, 4, d / 2 - 6), rgb(255, 150, 190))
		add(s, "Kraam", Vector3.new(8, 6, 8), at(w / 2 - 6, 4, d / 2 - 6), rgb(255, 215, 60))
		return
	end

	add(s, id, Vector3.new(w, h, d), at(0, h / 2, 0), def.color, id == "Park" and Enum.Material.Grass or nil)
	local top = h

	if def.roof then
		add(s, "Dak", Vector3.new(w + 1, 0.8, d + 1), at(0, top + 0.4, 0), def.roof)
	end

	-- Raampjes voor hogere gebouwen (voor- en achterkant)
	if h >= 20 then
		for y = 6, h - 6, 8 do
			for x = -w / 2 + 3, w / 2 - 3, 4 do
				for _, side in { -1, 1 } do
					add(s, "Raam", Vector3.new(2, 3, 0.3), at(x, y, side * (d / 2 + 0.1)), rgb(255, 240, 150), Enum.Material.Neon)
				end
			end
		end
	end

	-- Herkenningspunten per gebouw
	if id == "Factory" then
		for _, dx in { -w / 4, w / 4 } do
			local tower = add(s, "Koeltoren", Vector3.new(22, 7, 7), at(dx, top + 11.8, 0), rgb(185, 195, 185))
			tower.Shape = Enum.PartType.Cylinder
			tower.Orientation = Vector3.new(0, 0, 90)
		end
	elseif id == "Shop" then
		local donut = add(s, "Donut", Vector3.new(2, 6, 6), at(0, top + 3.5, 0), rgb(235, 150, 190), nil, Enum.PartType.Cylinder)
		donut.Orientation = Vector3.new(0, 0, 90)
	elseif id == "Park" then
		for _, p in { { -8, -8 }, { 9, 6 }, { -3, 10 } } do
			add(s, "Stam", Vector3.new(1, 5, 1), at(p[1], 2.5, p[2]), rgb(120, 82, 48))
			add(s, "Kruin", Vector3.new(6, 6, 6), at(p[1], 7, p[2]), rgb(60, 154, 60), nil, Enum.PartType.Ball)
		end
	elseif id == "Kiosk" then
		add(s, "Luifel", Vector3.new(w + 2, 0.6, 3), at(0, h - 1, -d / 2 - 1.5), rgb(235, 235, 235))
		add(s, "Luifel", Vector3.new(w / 3, 0.65, 3.1), at(-w / 3, h - 1, -d / 2 - 1.5), rgb(230, 80, 80))
		add(s, "Luifel", Vector3.new(w / 3, 0.65, 3.1), at(w / 3, h - 1, -d / 2 - 1.5), rgb(230, 80, 80))
	elseif id == "Bar" then
		add(s, "Bord", Vector3.new(6, 2.5, 0.6), at(0, h - 1.5, -d / 2 - 0.3), rgb(255, 230, 80), Enum.Material.Neon)
		add(s, "Deur", Vector3.new(2, 4, 0.4), at(0, 2, -d / 2 - 0.2), rgb(70, 40, 30))
	elseif id == "Church" then
		add(s, "Toren", Vector3.new(4, 10, 4), at(0, top + 5, 0), def.color)
		add(s, "Spits", Vector3.new(3, 5, 3), at(0, top + 12.5, 0), def.roof, nil, Enum.PartType.Wedge)
		add(s, "Kruis", Vector3.new(0.6, 4, 0.6), at(0, top + 17, 0), rgb(240, 200, 60))
		add(s, "Kruis", Vector3.new(2.4, 0.6, 0.6), at(0, top + 17.5, 0), rgb(240, 200, 60))
	elseif id == "Supermarket" then
		add(s, "Bord", Vector3.new(w * 0.55, 3, 0.6), at(0, h - 2, -d / 2 - 0.3), rgb(230, 60, 60))
		add(s, "Ruit", Vector3.new(w * 0.6, 3.5, 0.3), at(0, 3.2, -d / 2 - 0.1), rgb(190, 230, 250), Enum.Material.Glass)
	elseif id == "School" then
		add(s, "Vlaggenstok", Vector3.new(0.5, 12, 0.5), at(w / 2 - 3, top + 6, 0), rgb(200, 200, 205))
		add(s, "Vlag", Vector3.new(4, 2.5, 0.2), at(w / 2 - 5, top + 11, 0), rgb(235, 70, 70))
		add(s, "Klok", Vector3.new(4, 4, 0.4), at(0, h - 3, -d / 2 - 0.2), rgb(255, 250, 235), Enum.Material.Neon)
	elseif id == "Firestation" then
		add(s, "Toren", Vector3.new(5, h + 10, 5), at(w / 2 - 3, (h + 10) / 2, d / 2 - 3), rgb(200, 55, 50))
		add(s, "Torendak", Vector3.new(6, 0.8, 6), at(w / 2 - 3, h + 10.4, d / 2 - 3), def.roof)
		add(s, "Poort", Vector3.new(7, 6, 0.4), at(-3, 3, -d / 2 - 0.2), rgb(245, 245, 245))
	elseif id == "Cinema" then
		add(s, "Reclame", Vector3.new(w * 0.7, 4, 1), at(0, top + 3, -d / 2 + 2), rgb(255, 80, 200), Enum.Material.Neon)
		add(s, "Luifel", Vector3.new(w * 0.7, 0.6, 3), at(0, 5, -d / 2 - 1.5), rgb(80, 40, 120))
	elseif id == "CityHall" then
		add(s, "Klokkentoren", Vector3.new(6, 14, 6), at(0, top + 7.5, 0), def.color)
		add(s, "Klok", Vector3.new(3.4, 3.4, 0.4), at(0, top + 10, -3.2), rgb(255, 250, 235), Enum.Material.Neon)
		add(s, "Spits", Vector3.new(6, 4, 6), at(0, top + 16.5, 0), def.roof, nil, Enum.PartType.Wedge)
		for i = -2, 2 do
			add(s, "Zuil", Vector3.new(1.2, h - 2, 1.2), at(i * 4.5, (h - 2) / 2, -d / 2 - 1.2), rgb(250, 245, 235))
		end
	elseif id == "Hospital" then
		add(s, "Kruis", Vector3.new(8, 2.4, 0.5), at(0, h - 5, -d / 2 - 0.3), rgb(230, 40, 40), Enum.Material.Neon)
		add(s, "Kruis", Vector3.new(2.4, 8, 0.5), at(0, h - 5, -d / 2 - 0.3), rgb(230, 40, 40), Enum.Material.Neon)
		add(s, "Landingsplek", Vector3.new(10, 0.3, 10), at(0, top + 1, 0), rgb(220, 220, 225))
	elseif id == "Hotel" then
		add(s, "Bord", Vector3.new(10, 3, 1), at(0, top + 2.5, 0), rgb(255, 215, 60), Enum.Material.Neon)
		add(s, "Luifel", Vector3.new(w * 0.6, 0.6, 4), at(0, 5, -d / 2 - 2), rgb(150, 40, 40))
	elseif id == "Skyscraper" then
		add(s, "Antenne", Vector3.new(0.8, 16, 0.8), at(0, top + 8, 0), rgb(200, 200, 205))
	end
end

local function addBuilding(s: State, def, gx: number, gz: number)
	for x = gx, gx + def.cells[1] - 1 do
		for z = gz, gz + def.cells[2] - 1 do
			s.occ[key(x, z)] = true
		end
	end
	s.income += def.income
	s.pop += def.pop
	table.insert(s.buildings, { id = def.id, gx = gx, gz = gz })
	buildModel(s, def, gx, gz)
end

-- Opslaan -----------------------------------------------------------------------
local function save(player: Player)
	local s = states[player]
	if not s or not s.loaded then
		return
	end
	local parcelList = {}
	for _, part in s.parcels do
		table.insert(parcelList, { Config.SnapParcel(part.Position.X), Config.SnapParcel(part.Position.Z) })
	end
	local data = { coins = s.coins, parcels = parcelList, buildings = s.buildings }
	for _ = 1, 3 do
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

-- Spelers laden ---------------------------------------------------------------------
local function slotParcel(slot: number): (number, number)
	return (slot % 8) * Config.ParcelSpacing, math.floor(slot / 8) * Config.ParcelSpacing
end

local function setup(player: Player)
	local folder = Instance.new("Folder")
	folder.Name = "Stad_" .. player.Name
	folder.Parent = workspace

	local s: State = {
		coins = Config.StartCoins,
		slot = -1,
		home = Vector3.zero,
		parcels = {},
		parcelCount = 0,
		buildings = {},
		occ = {},
		income = 0,
		pop = 0,
		folder = folder,
		loaded = false,
	}
	states[player] = s

	-- Opgeslagen voortgang laden
	local ok, data = pcall(function()
		return store:GetAsync(tostring(player.UserId))
	end)
	if ok and typeof(data) == "table" then
		s.coins = tonumber(data.coins) or s.coins
		for _, p in data.parcels or {} do
			local px, pz = p[1], p[2]
			if isInt(px) and isInt(pz) and not owners[Config.ParcelName(px, pz)] then
				claimParcel(player, s, px, pz)
			end
		end
	end

	-- Nieuwe speler (of kwijtgeraakt land): eigen startplek zoeken
	if s.parcelCount == 0 then
		local slot = 0
		while usedSlots[slot] or owners[Config.ParcelName(slotParcel(slot))] do
			slot += 1
		end
		usedSlots[slot] = true
		s.slot = slot
		claimParcel(player, s, slotParcel(slot))
	end

	for _, part in s.parcels do
		s.home = part.Position
		break
	end

	if ok and typeof(data) == "table" then
		for _, b in data.buildings or {} do
			local def = type(b) == "table" and Config.ById[b.id]
			if def and isInt(b.gx) and isInt(b.gz) and footprintOk(s, def, b.gx, b.gz) then
				addBuilding(s, def, b.gx, b.gz)
			end
		end
	end
	s.loaded = ok -- bij een DataStore-fout niet overschrijven

	local function spawnAt(char: Model)
		task.wait()
		char:PivotTo(CFrame.new(s.home + Vector3.new(0, 6, 0)))
	end
	player.CharacterAppearanceLoaded:Connect(yellowify)
	if player.Character then
		yellowify(player.Character)
		spawnAt(player.Character)
	end
	player.CharacterAdded:Connect(spawnAt)

	push(player, s)
end

-- Acties ----------------------------------------------------------------------------
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
	local gx, gz = Config.SnapCell(def, worldPos.X, worldPos.Z)
	local fits, why = footprintOk(s, def, gx, gz)
	if not fits then
		return false, why
	end
	s.coins -= def.cost
	addBuilding(s, def, gx, gz)
	push(player, s)
	return true, def.name .. " gebouwd!"
end

buyFn.OnServerInvoke = function(player, px, pz)
	local s = states[player]
	if not s or not isInt(px) or not isInt(pz) then
		return false, "Ongeldig verzoek"
	end
	if owners[Config.ParcelName(px, pz)] then
		return false, "Dit land is al van iemand"
	end
	if
		not (
			ownsParcel(s, px + 1, pz)
			or ownsParcel(s, px - 1, pz)
			or ownsParcel(s, px, pz + 1)
			or ownsParcel(s, px, pz - 1)
		)
	then
		return false, "Koop land naast je eigen stad"
	end
	local cost = Config.ParcelCost(s.parcelCount)
	if s.coins < cost then
		return false, "Te weinig munten"
	end
	s.coins -= cost
	claimParcel(player, s, px, pz)
	push(player, s)
	return true, "Land gekocht!"
end

-- Inkomsten ---------------------------------------------------------------------------
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

-- Levenscyclus ------------------------------------------------------------------------
Players.PlayerAdded:Connect(setup)
for _, p in Players:GetPlayers() do
	task.spawn(setup, p)
end

Players.PlayerRemoving:Connect(function(player)
	save(player)
	local s = states[player]
	if s then
		if s.slot >= 0 then
			usedSlots[s.slot] = nil
		end
		for _, part in s.parcels do
			owners[part.Name] = nil
			part:Destroy()
		end
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
local landMode = false
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

local bar = Instance.new("ScrollingFrame")
bar.Size = UDim2.new(1, -24, 0, 104)
bar.Position = UDim2.new(0, 12, 1, -116)
bar.BackgroundColor3 = Color3.fromRGB(255, 217, 15)
bar.BorderSizePixel = 0
bar.ScrollingDirection = Enum.ScrollingDirection.X
bar.AutomaticCanvasSize = Enum.AutomaticSize.X
bar.CanvasSize = UDim2.new()
bar.ScrollBarThickness = 6
bar.Parent = gui
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 12)
local barStroke = Instance.new("UIStroke", bar)
barStroke.Thickness = 3
barStroke.Color = Color3.fromRGB(40, 40, 90)
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
	landMode = false
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

local landButton = makeButton("", Color3.fromRGB(150, 100, 40))
local selectLand -- hieronder gedefinieerd
landButton.Activated:Connect(function()
	if landMode then
		clearGhost()
	else
		selectLand()
	end
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
	landButton.Text = string.format("Land kopen\n💰 %s\n(%d stukken)", fmt(state.parcelCost), state.parcelCount)
end

remotes.State.OnClientEvent:Connect(function(newState)
	state = newState
	refreshUI()
end)

-- Plaatsen en land kopen -------------------------------------------------------
local parcels = workspace:WaitForChild("Parcels")

local function parcelPart(px: number, pz: number)
	return parcels:FindFirstChild(Config.ParcelName(px, pz))
end

local function owns(px: number, pz: number): boolean
	local p = parcelPart(px, pz)
	return p ~= nil and p:GetAttribute("OwnerId") == player.UserId
end

local function canBuy(px: number, pz: number): boolean
	if parcelPart(px, pz) then
		return false
	end
	return owns(px + 1, pz) or owns(px - 1, pz) or owns(px, pz + 1) or owns(px, pz - 1)
end

local function footprintOwned(def, gx: number, gz: number): boolean
	for x = gx, gx + def.cells[1] - 1 do
		for z = gz, gz + def.cells[2] - 1 do
			if not owns(Config.ParcelOfCell(x), Config.ParcelOfCell(z)) then
				return false
			end
		end
	end
	return true
end

function selectLand()
	clearGhost()
	landMode = true
	local g = Instance.new("Part")
	g.Anchored = true
	g.CanCollide = false
	g.CanQuery = false
	g.Transparency = 0.5
	g.Material = Enum.Material.Neon
	g.Size = Vector3.new(Config.ParcelSize, 1, Config.ParcelSize)
	g.Parent = workspace
	ghost = g
	mouse.TargetFilter = g
end

RunService.RenderStepped:Connect(function()
	if not (ghost and state) then
		return
	end
	local p = mouse.Hit.Position
	if landMode then
		local px, pz = Config.SnapParcel(p.X), Config.SnapParcel(p.Z)
		ghost.Position = Vector3.new((px + 0.5) * Config.ParcelSize, 0.8, (pz + 0.5) * Config.ParcelSize)
		local ok = canBuy(px, pz) and state.coins >= state.parcelCost
		ghost.Color = ok and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(255, 80, 80)
	elseif selected then
		local def = selected
		local gx, gz = Config.SnapCell(def, p.X, p.Z)
		local cs = Config.CellSize
		ghost.Position = Vector3.new((gx + def.cells[1] / 2) * cs, def.height / 2 + 0.2, (gz + def.cells[2] / 2) * cs)
		local ok = footprintOwned(def, gx, gz) and state.coins >= def.cost
		ghost.Color = ok and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(255, 80, 80)
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.X then
		clearGhost()
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 and state then
		local p = mouse.Hit.Position
		if landMode then
			local ok, msg = remotes.Buy:InvokeServer(Config.SnapParcel(p.X), Config.SnapParcel(p.Z))
			showToast(msg, ok)
		elseif selected then
			local ok, msg = remotes.Place:InvokeServer(selected.id, p)
			showToast(msg, ok)
		end
	end
end)

]==])

local base = workspace:FindFirstChild("Baseplate")
if base then base:Destroy() end

print("Loaden City Tycoon geinstalleerd! Druk op Play.")
