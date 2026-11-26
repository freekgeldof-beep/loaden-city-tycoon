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
	{ name = "Wereldstad", pop = 5000 },
	{ name = "Megastad", pop = 20000 },
	{ name = "Utopia", pop = 80000 },
}

-- tier = vanaf welk stadsniveau het gebouw te koop is.
-- cells = footprint in rastervakjes, height = hoogte in studs.
Config.Categories = { "Wonen", "Winkels", "Eten", "Publiek", "Vrije tijd", "Industrie", "Kantoor" }

-- 40 gebouwtypes x 25 uitvoeringen = 1000 gebouwen.
-- { key, naam, categorie, cellen, hoogte, kosten, inkomen, inwoners, niveau, kleur, dak }
local ARCHETYPES = {
	{ "House", "Huisje", 1, { 1, 1 }, 6, 50, 1, 4, 1, { 252, 228, 150 }, { 205, 95, 65 } },
	{ "Bungalow", "Bungalow", 1, { 1, 1 }, 5, 90, 2, 6, 1, { 200, 230, 200 }, { 150, 90, 70 } },
	{ "Villa", "Villa", 1, { 2, 2 }, 9, 400, 7, 10, 2, { 255, 235, 205 }, { 170, 70, 60 } },
	{ "Townhouse", "Rijtjeshuis", 1, { 3, 1 }, 9, 300, 6, 12, 2, { 225, 150, 120 }, { 110, 70, 60 } },
	{ "Apartment", "Flat", 1, { 2, 2 }, 24, 900, 20, 40, 3, { 214, 160, 110 }, { 120, 120, 130 } },
	{ "Tower", "Woontoren", 1, { 2, 2 }, 50, 4000, 90, 160, 4, { 170, 190, 215 }, { 90, 90, 110 } },
	{ "Kiosk", "Kiosk", 2, { 1, 1 }, 5, 120, 3, 0, 1, { 255, 170, 60 }, { 230, 80, 80 } },
	{ "Bakery", "Bakkerij", 2, { 1, 1 }, 7, 180, 4, 1, 1, { 240, 200, 150 }, { 160, 90, 60 } },
	{ "Shop", "Donutwinkel", 2, { 1, 1 }, 9, 250, 6, 2, 2, { 255, 150, 190 }, { 255, 235, 200 } },
	{ "Supermarket", "Supermarkt", 2, { 3, 2 }, 8, 650, 16, 4, 2, { 120, 200, 140 }, { 90, 90, 100 } },
	{ "Market", "Markt", 2, { 3, 2 }, 4, 700, 20, 0, 2, { 230, 190, 120 }, { 200, 70, 70 } },
	{ "Mall", "Winkelcentrum", 2, { 4, 3 }, 14, 3500, 80, 10, 4, { 220, 220, 235 }, { 100, 100, 120 } },
	{ "Cafe", "Café", 3, { 1, 1 }, 7, 220, 6, 0, 1, { 235, 200, 160 }, { 120, 80, 60 } },
	{ "Bar", "Kroeg", 3, { 2, 1 }, 8, 400, 10, 0, 2, { 150, 100, 70 }, { 80, 50, 40 } },
	{ "Restaurant", "Restaurant", 3, { 2, 1 }, 9, 600, 16, 0, 2, { 235, 170, 150 }, { 90, 60, 60 } },
	{ "FastFood", "Snackbar", 3, { 2, 2 }, 8, 1100, 32, 0, 3, { 255, 210, 60 }, { 210, 50, 50 } },
	{ "Church", "Kerkje", 4, { 2, 2 }, 10, 500, 8, 6, 2, { 235, 235, 225 }, { 150, 80, 70 } },
	{ "School", "School", 4, { 3, 2 }, 10, 1400, 30, 20, 3, { 230, 190, 110 }, { 160, 70, 60 } },
	{ "Library", "Bibliotheek", 4, { 2, 2 }, 12, 1600, 34, 6, 3, { 225, 215, 200 }, { 110, 100, 95 } },
	{ "Firestation", "Brandweerkazerne", 4, { 2, 2 }, 10, 1500, 25, 10, 3, { 220, 70, 60 }, { 90, 90, 100 } },
	{ "Police", "Politiebureau", 4, { 2, 2 }, 11, 1500, 26, 10, 3, { 90, 120, 190 }, { 60, 70, 100 } },
	{ "CityHall", "Stadhuis", 4, { 3, 2 }, 14, 3000, 55, 20, 3, { 235, 225, 205 }, { 120, 110, 100 } },
	{ "Hospital", "Ziekenhuis", 4, { 3, 3 }, 20, 5000, 130, 80, 4, { 245, 245, 250 }, { 150, 150, 160 } },
	{ "Museum", "Museum", 4, { 3, 2 }, 13, 4200, 100, 10, 4, { 235, 225, 205 }, { 130, 120, 110 } },
	{ "Park", "Parkje", 5, { 2, 2 }, 1, 80, 1, 0, 1, { 110, 200, 90 }, nil },
	{ "Gym", "Sportschool", 5, { 2, 2 }, 9, 1300, 30, 0, 3, { 150, 150, 160 }, { 80, 80, 90 } },
	{ "Pool", "Zwembad", 5, { 3, 2 }, 2, 1700, 40, 0, 3, { 90, 170, 230 }, nil },
	{ "Cinema", "Bioscoop", 5, { 2, 2 }, 12, 1800, 45, 0, 3, { 120, 90, 170 }, { 70, 60, 90 } },
	{ "Theater", "Theater", 5, { 3, 2 }, 14, 2800, 70, 0, 3, { 150, 50, 70 }, { 70, 40, 50 } },
	{ "Stadium", "Stadion", 5, { 4, 4 }, 12, 9000, 260, 0, 4, { 190, 190, 200 }, nil },
	{ "Funfair", "Pretpark", 5, { 4, 4 }, 2, 40000, 1400, 0, 5, { 110, 200, 90 }, nil },
	{ "Farm", "Boerderij", 6, { 3, 2 }, 8, 700, 14, 2, 2, { 200, 60, 50 }, { 110, 80, 60 } },
	{ "Warehouse", "Magazijn", 6, { 3, 2 }, 9, 1200, 28, 0, 3, { 170, 150, 120 }, { 110, 110, 115 } },
	{ "Recycling", "Recyclingstation", 6, { 2, 2 }, 7, 1000, 22, 0, 3, { 110, 190, 120 }, { 70, 100, 80 } },
	{ "Factory", "Kerncentrale", 6, { 3, 2 }, 14, 2500, 70, 10, 4, { 160, 180, 160 }, { 90, 90, 100 } },
	{ "Bank", "Bank", 7, { 2, 2 }, 16, 3500, 90, 0, 4, { 220, 210, 170 }, { 110, 100, 70 } },
	{ "Office", "Kantoor", 7, { 2, 2 }, 45, 6000, 180, 60, 4, { 120, 170, 225 }, { 80, 80, 100 } },
	{ "Hotel", "Hotel", 7, { 2, 2 }, 36, 7500, 200, 100, 4, { 230, 170, 120 }, { 90, 60, 60 } },
	{ "Skyscraper", "Wolkenkrabber", 7, { 2, 2 }, 90, 25000, 800, 200, 5, { 245, 205, 80 }, { 80, 80, 100 } },
	{ "Radio", "Zendmast", 7, { 1, 1 }, 120, 30000, 900, 0, 5, { 235, 235, 235 }, nil },
}

-- { muurkleur, dakkleur }
local PALETTES = {
	{ { 252, 228, 150 }, { 205, 95, 65 } },
	{ { 255, 170, 170 }, { 150, 60, 70 } },
	{ { 170, 220, 255 }, { 70, 100, 160 } },
	{ { 200, 235, 170 }, { 90, 130, 80 } },
	{ { 255, 200, 120 }, { 160, 100, 50 } },
	{ { 220, 190, 240 }, { 110, 80, 150 } },
	{ { 255, 235, 200 }, { 190, 90, 60 } },
	{ { 150, 210, 200 }, { 60, 110, 110 } },
	{ { 245, 150, 110 }, { 120, 60, 50 } },
	{ { 235, 235, 150 }, { 150, 150, 60 } },
	{ { 190, 200, 240 }, { 80, 90, 150 } },
	{ { 255, 190, 210 }, { 170, 70, 110 } },
	{ { 210, 170, 130 }, { 100, 70, 55 } },
	{ { 170, 230, 210 }, { 70, 130, 110 } },
	{ { 250, 210, 90 }, { 140, 100, 30 } },
	{ { 200, 200, 215 }, { 95, 95, 115 } },
	{ { 240, 120, 100 }, { 110, 40, 40 } },
	{ { 140, 190, 235 }, { 50, 80, 130 } },
	{ { 225, 245, 190 }, { 110, 150, 70 } },
	{ { 255, 215, 230 }, { 200, 100, 140 } },
	{ { 245, 225, 175 }, { 130, 95, 70 } },
	{ { 190, 160, 220 }, { 80, 60, 120 } },
	{ { 255, 150, 60 }, { 120, 70, 30 } },
	{ { 210, 235, 245 }, { 90, 130, 160 } },
}

local ADJECTIVES = {
	"Klassiek", "Gezellig", "Modern", "Zonnig", "Retro", "Chique", "Knus", "Fleurig", "Strak", "Landelijk",
	"Stads", "Luxe", "Oud", "Nieuw", "Groot", "Compact", "Trots", "Vrolijk", "Statig", "Speels",
	"Elegant", "Robuust", "Koninklijk", "Futuristisch", "Legendarisch",
}
Config.Variants = #ADJECTIVES

local FLAT = { Park = true, Pool = true, Funfair = true }

local function rgb(c)
	return Color3.fromRGB(c[1], c[2], c[3])
end

Config.Buildings = {}
Config.ById = {}
for a, row in ARCHETYPES do
	local key, name, cat, cells, height, cost, income, pop, tier, body, roof = table.unpack(row)
	for v = 0, Config.Variants - 1 do
		local pal = PALETTES[(v * 5 + a * 3) % #PALETTES + 1]
		local def = {
			id = string.format("A%d_%d", a, v),
			arch = key,
			variant = v,
			name = name .. " " .. ADJECTIVES[v + 1],
			cat = cat,
			cells = cells,
			height = FLAT[key] and height or math.floor(height * (1 + 0.045 * v) + 0.5),
			cost = math.floor(cost * 1.13 ^ v + 0.5),
			income = math.max(income == 0 and 0 or 1, math.floor(income * 1.12 ^ v + 0.5)),
			pop = math.floor(pop * 1.1 ^ v + 0.5),
			tier = math.min(#Config.Tiers, tier + v // 6),
			color = v == 0 and rgb(body) or rgb(pal[1]),
			roof = roof and (v == 0 and rgb(roof) or rgb(pal[2])) or nil,
		}
		table.insert(Config.Buildings, def)
		Config.ById[def.id] = def
		if v == 0 then
			Config.ById[key] = def -- korte alias voor oude opslag
		end
	end
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

local demolishFn = Instance.new("RemoteFunction")
demolishFn.Name = "Demolish"
demolishFn.Parent = remotes

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
	list: { any }, -- gebouwen: { id, gx, gz, def, model }
	occ: { [string]: any }, -- vakje -> gebouw
	cur: Instance,
	lastAct: number,
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
	part.Parent = s.cur
	return part
end

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local GOLD = rgb(240, 200, 70)
local GREY = rgb(190, 190, 195)

local function buildModel(s: State, def, gx: number, gz: number)
	local cs = Config.CellSize
	local w, d, h = def.cells[1] * cs - 0.6, def.cells[2] * cs - 0.6, def.height
	local c = Vector3.new((gx + def.cells[1] / 2) * cs, 0.2, (gz + def.cells[2] / 2) * cs)
	local id, v = def.arch, def.variant

	local function at(x: number, y: number, z: number): Vector3
		return c + Vector3.new(x, y, z)
	end
	-- P(naam, breedte, hoogte, diepte, x, y, z, kleur, materiaal, vorm)
	local function P(name, sx, sy, sz, x, y, z, color, material, shape): Part
		return add(s, name, Vector3.new(sx, sy, sz), at(x, y, z), color, material, shape)
	end
	local function upright(part: Part)
		part.Orientation = Vector3.new(0, 0, 90) -- cilinder rechtop
	end

	-- Gebouwen met een eigen vorm
	if id == "Stadium" then
		upright(P(id, h, w, d, 0, h / 2, 0, def.color, nil, Enum.PartType.Cylinder))
		upright(P("Veld", 0.4, w * 0.7, d * 0.7, 0, h + 0.2, 0, rgb(90, 190, 80), Enum.Material.Grass, Enum.PartType.Cylinder))
		for _, q in { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } } do
			P("Mast", 1, 12, 1, q[1] * w * 0.4, h + 6, q[2] * d * 0.4, rgb(120, 120, 130))
			P("Lamp", 3, 1, 3, q[1] * w * 0.4, h + 12.5, q[2] * d * 0.4, rgb(255, 250, 200), Enum.Material.Neon)
		end
		return
	elseif id == "Radio" then
		for i = 0, 5 do
			local t = 3 - i * 0.3
			P("Mast", t, h / 6, t, 0, h / 12 + i * h / 6, 0, i % 2 == 0 and rgb(220, 60, 60) or rgb(240, 240, 240))
		end
		P("Lamp", 2, 2, 2, 0, h + 1, 0, rgb(255, 80, 80), Enum.Material.Neon, Enum.PartType.Ball)
		return
	elseif id == "Funfair" then
		P("Grond", w, h, d, 0, h / 2, 0, def.color, Enum.Material.Grass)
		P("Rad", 1, 26, 26, 0, 15, 0, rgb(235, 80, 80), nil, Enum.PartType.Cylinder)
		P("RadBinnen", 1.2, 22, 22, 0, 15, 0, rgb(255, 250, 235), nil, Enum.PartType.Cylinder)
		P("Poot", 2, 15, 2, 0, 7.5, -3, rgb(120, 120, 130))
		P("Poot", 2, 15, 2, 0, 7.5, 3, rgb(120, 120, 130))
		P("Kraam", 8, 6, 8, -w / 2 + 6, 4, d / 2 - 6, rgb(255, 150, 190))
		P("Kraam", 8, 6, 8, w / 2 - 6, 4, d / 2 - 6, rgb(255, 215, 60))
		return
	end

	P(id, w, h, d, 0, h / 2, 0, def.color, (id == "Park") and Enum.Material.Grass or nil)
	local top = h
	if def.roof then
		P("Dak", w + 1, 0.8, d + 1, 0, top + 0.4, 0, def.roof)
	end

	-- Ramen als banden (weinig parts, goedkoop voor de server)
	if h >= 20 then
		for y = 6, h - 6, 8 do
			for _, side in { -1, 1 } do
				P("Ramen", w - 4, 3, 0.3, 0, y, side * (d / 2 + 0.1), rgb(255, 240, 150), Enum.Material.Neon)
			end
		end
	end

	-- Herkenningspunten per type
	if id == "House" then
		P("Deur", 1.6, 3, 0.3, 0, 1.5, -d / 2 - 0.1, rgb(120, 80, 50))
	elseif id == "Bungalow" then
		P("Schoorsteen", 1.6, 4, 1.6, w / 4, top + 2.8, 0, rgb(130, 90, 80))
	elseif id == "Villa" then
		P("Garage", w * 0.4, 5, 4, -w / 4, 2.5, -d / 2 - 2, def.color:Lerp(rgb(0, 0, 0), 0.12))
		P("Deur", 2, 4, 0.3, w / 4, 2, -d / 2 - 0.1, rgb(120, 80, 50))
	elseif id == "Townhouse" then
		local cols = { rgb(240, 150, 150), rgb(150, 200, 240), rgb(240, 220, 130) }
		for i = -1, 1 do
			P("Gevel", w / 3 - 0.6, h * 0.9, 0.4, i * w / 3, h * 0.45, -d / 2 - 0.2, cols[i + 2])
		end
	elseif id == "Apartment" then
		for y = 6, h - 6, 6 do
			P("Balkon", w * 0.8, 0.5, 1.5, 0, y, -d / 2 - 0.75, rgb(90, 90, 100))
		end
	elseif id == "Tower" then
		P("Antenne", 0.6, 14, 0.6, 0, top + 7, 0, GREY)
	elseif id == "Factory" then
		for _, dx in { -w / 4, w / 4 } do
			upright(P("Koeltoren", 22, 7, 7, dx, top + 11.8, 0, rgb(185, 195, 185), nil, Enum.PartType.Cylinder))
		end
	elseif id == "Shop" then
		upright(P("Donut", 2, 6, 6, 0, top + 3.5, 0, rgb(235, 150, 190), nil, Enum.PartType.Cylinder))
	elseif id == "Park" then
		for _, q in { { -8, -8 }, { 9, 6 }, { -3, 10 } } do
			P("Stam", 1, 5, 1, q[1], 2.5, q[2], rgb(120, 82, 48))
			P("Kruin", 6, 6, 6, q[1], 7, q[2], rgb(60, 154, 60), nil, Enum.PartType.Ball)
		end
	elseif id == "Kiosk" or id == "Bakery" then
		P("Luifel", w + 2, 0.6, 3, 0, h - 1, -d / 2 - 1.5, rgb(235, 235, 235))
		P("Luifel", w / 3, 0.65, 3.1, -w / 3, h - 1, -d / 2 - 1.5, rgb(230, 80, 80))
		P("Luifel", w / 3, 0.65, 3.1, w / 3, h - 1, -d / 2 - 1.5, rgb(230, 80, 80))
		if id == "Bakery" then
			P("Schoorsteen", 1.6, 4, 1.6, w / 4, top + 2.8, d / 4, rgb(130, 90, 80))
		end
	elseif id == "Market" then
		for i = -1, 1 do
			P("Kraam", 6, 3, 4, i * w * 0.3, 1.5, -d * 0.1, rgb(150, 105, 70))
			P("Luifel", 7, 0.5, 5, i * w * 0.3, 5, -d * 0.1, i == 0 and rgb(230, 70, 70) or rgb(70, 170, 90))
		end
	elseif id == "Mall" then
		P("Bord", w * 0.5, 4, 1, 0, h + 2.5, -d / 2, rgb(255, 120, 60), Enum.Material.Neon)
		P("Glas", w * 0.8, 6, 0.3, 0, 4, -d / 2 - 0.1, rgb(190, 230, 250), Enum.Material.Glass)
	elseif id == "Cafe" then
		for _, sx in { -1, 1 } do
			P("Paal", 0.4, 5, 0.4, sx * w * 0.3, 2.5, -d / 2 - 3, GREY)
			P("Parasol", 4, 0.5, 4, sx * w * 0.3, 5.2, -d / 2 - 3, rgb(230, 70, 70))
		end
	elseif id == "Bar" then
		P("Bord", 6, 2.5, 0.6, 0, h - 1.5, -d / 2 - 0.3, rgb(255, 230, 80), Enum.Material.Neon)
		P("Deur", 2, 4, 0.4, 0, 2, -d / 2 - 0.2, rgb(70, 40, 30))
	elseif id == "Restaurant" then
		P("Bord", 5, 2, 0.5, 0, h - 1.5, -d / 2 - 0.3, rgb(255, 230, 80), Enum.Material.Neon)
		P("Terras", w * 0.8, 0.3, 4, 0, 0.3, -d / 2 - 2.5, rgb(150, 105, 70))
	elseif id == "FastFood" then
		P("Paal", 1, 14, 1, w / 2 + 2, 7, -d / 2, GREY)
		P("Bord", 6, 6, 1, w / 2 + 2, 15, -d / 2, rgb(255, 210, 0), Enum.Material.Neon)
	elseif id == "Church" then
		P("Toren", 4, 10, 4, 0, top + 5, 0, def.color)
		P("Spits", 3, 5, 3, 0, top + 12.5, 0, def.roof, nil, Enum.PartType.Wedge)
		P("Kruis", 0.6, 4, 0.6, 0, top + 17, 0, GOLD)
		P("Kruis", 2.4, 0.6, 0.6, 0, top + 17.5, 0, GOLD)
	elseif id == "Supermarket" then
		P("Bord", w * 0.55, 3, 0.6, 0, h - 2, -d / 2 - 0.3, rgb(230, 60, 60))
		P("Ruit", w * 0.6, 3.5, 0.3, 0, 3.2, -d / 2 - 0.1, rgb(190, 230, 250), Enum.Material.Glass)
	elseif id == "School" then
		P("Vlaggenstok", 0.5, 12, 0.5, w / 2 - 3, top + 6, 0, GREY)
		P("Vlag", 4, 2.5, 0.2, w / 2 - 5, top + 11, 0, rgb(235, 70, 70))
		P("Klok", 4, 4, 0.4, 0, h - 3, -d / 2 - 0.2, rgb(255, 250, 235), Enum.Material.Neon)
	elseif id == "Library" or id == "Museum" or id == "Bank" then
		P("Trap", w * 0.7, 1, 3, 0, 0.5, -d / 2 - 1.5, rgb(215, 215, 220))
		for i = -2, 2 do
			P("Zuil", 1.2, h - 2, 1.2, i * w * 0.18, (h - 2) / 2 + 1, -d / 2 - 1.2, rgb(250, 245, 235))
		end
		if id == "Bank" then
			P("Bord", w * 0.6, 2, 0.5, 0, h + 1.5, -d / 2, GOLD, Enum.Material.Neon)
		end
	elseif id == "Firestation" then
		P("Toren", 5, h + 10, 5, w / 2 - 3, (h + 10) / 2, d / 2 - 3, rgb(200, 55, 50))
		P("Torendak", 6, 0.8, 6, w / 2 - 3, h + 10.4, d / 2 - 3, def.roof)
		P("Poort", 7, 6, 0.4, -3, 3, -d / 2 - 0.2, rgb(245, 245, 245))
	elseif id == "Police" then
		P("Streep", w + 0.2, 2, d + 0.2, 0, h * 0.45, 0, rgb(40, 60, 150))
		P("Zwaailicht", 2, 1.2, 2, 0, top + 1.4, 0, rgb(60, 120, 255), Enum.Material.Neon)
	elseif id == "CityHall" then
		P("Klokkentoren", 6, 14, 6, 0, top + 7.5, 0, def.color)
		P("Klok", 3.4, 3.4, 0.4, 0, top + 10, -3.2, rgb(255, 250, 235), Enum.Material.Neon)
		P("Spits", 6, 4, 6, 0, top + 16.5, 0, def.roof, nil, Enum.PartType.Wedge)
		for i = -2, 2 do
			P("Zuil", 1.2, h - 2, 1.2, i * 4.5, (h - 2) / 2, -d / 2 - 1.2, rgb(250, 245, 235))
		end
	elseif id == "Hospital" then
		P("Kruis", 8, 2.4, 0.5, 0, h - 5, -d / 2 - 0.3, rgb(230, 40, 40), Enum.Material.Neon)
		P("Kruis", 2.4, 8, 0.5, 0, h - 5, -d / 2 - 0.3, rgb(230, 40, 40), Enum.Material.Neon)
		P("Landingsplek", 10, 0.3, 10, 0, top + 1, 0, rgb(220, 220, 225))
	elseif id == "Cinema" then
		P("Reclame", w * 0.7, 4, 1, 0, top + 3, -d / 2 + 2, rgb(255, 80, 200), Enum.Material.Neon)
		P("Luifel", w * 0.7, 0.6, 3, 0, 5, -d / 2 - 1.5, rgb(80, 40, 120))
	elseif id == "Theater" then
		P("Marquee", w * 0.6, 3, 1.2, 0, 5, -d / 2 - 0.8, rgb(255, 230, 100), Enum.Material.Neon)
		P("Bord", w * 0.5, 3, 0.6, 0, h + 2, -d / 2 + 1, rgb(200, 40, 60), Enum.Material.Neon)
	elseif id == "Pool" then
		P("Water", w - 3, 0.4, d - 3, 0, h + 0.2, 0, rgb(70, 160, 240), Enum.Material.Glass)
		P("Duikplank", 1.5, 0.3, 6, w / 2 - 4, h + 1.5, 0, rgb(245, 245, 245))
	elseif id == "Gym" then
		P("Bord", w * 0.5, 2.5, 0.5, 0, h - 1.8, -d / 2 - 0.3, rgb(255, 120, 60), Enum.Material.Neon)
	elseif id == "Warehouse" then
		for i = -1, 1 do
			P("Deur", 5, 6, 0.3, i * w * 0.28, 3, -d / 2 - 0.1, rgb(150, 150, 160))
		end
	elseif id == "Farm" then
		upright(P("Silo", 14, 5, 5, w / 2 - 4, 7, d / 2 - 4, GREY, nil, Enum.PartType.Cylinder))
		P("Schuur", w * 0.5, 2, d + 1, -w / 4, top + 1, 0, rgb(120, 40, 35))
	elseif id == "Recycling" then
		local bins = { rgb(70, 170, 90), rgb(70, 120, 210), rgb(240, 200, 60) }
		for i = -1, 1 do
			P("Bak", 3, 2.5, 3, i * 5, 1.3, -d / 2 - 2.5, bins[i + 2])
		end
	elseif id == "Hotel" then
		P("Bord", 10, 3, 1, 0, top + 2.5, 0, rgb(255, 215, 60), Enum.Material.Neon)
		P("Luifel", w * 0.6, 0.6, 4, 0, 5, -d / 2 - 2, rgb(150, 40, 40))
	elseif id == "Skyscraper" or id == "Office" then
		P("Antenne", 0.8, 16, 0.8, 0, top + 8, 0, GREY)
	end

	-- Variatie per uitvoering: dezelfde soort ziet er per variant net anders uit
	local k = v % 5
	if k == 1 then
		P("Schoorsteen", 2, 4, 2, w / 4, top + 2.8, d / 4, rgb(130, 90, 80))
	elseif k == 2 then
		P("Airco", 4, 2, 4, -w / 4, top + 1.8, 0, rgb(200, 200, 205))
	elseif k == 3 then
		P("Luifel", w * 0.6, 0.6, 2.5, 0, 4.5, -d / 2 - 1.25, def.roof or rgb(200, 70, 70))
	elseif k == 4 then
		P("Antenne", 0.5, 8, 0.5, w / 4, top + 4.8, -d / 4, GREY)
	end
	if v >= 12 then
		P("Sierrand", w + 1.4, 0.5, d + 1.4, 0, h * 0.55, 0, GOLD)
	end
	if v >= 20 then
		P("Ster", 3, 3, 3, 0, top + 20, 0, GOLD, Enum.Material.Neon, Enum.PartType.Ball)
	end
end

local function addBuilding(s: State, def, gx: number, gz: number)
	local model = Instance.new("Model")
	model.Name = def.name
	model.Parent = s.folder
	s.cur = model
	buildModel(s, def, gx, gz)
	s.cur = s.folder

	local rec = { id = def.id, gx = gx, gz = gz, def = def, model = model }
	for x = gx, gx + def.cells[1] - 1 do
		for z = gz, gz + def.cells[2] - 1 do
			s.occ[key(x, z)] = rec
		end
	end
	s.income += def.income
	s.pop += def.pop
	table.insert(s.list, rec)
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
	local buildingList = {}
	for _, rec in s.list do
		table.insert(buildingList, { id = rec.id, gx = rec.gx, gz = rec.gz })
	end
	local data = { coins = s.coins, parcels = parcelList, buildings = buildingList }
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
		list = {},
		occ = {},
		cur = folder,
		lastAct = 0,
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
local function throttled(s: State): boolean
	local now = os.clock()
	if now - s.lastAct < 0.15 then
		return true
	end
	s.lastAct = now
	return false
end

placeFn.OnServerInvoke = function(player, id, worldPos)
	local s = states[player]
	if not s or typeof(id) ~= "string" or typeof(worldPos) ~= "Vector3" then
		return false, "Ongeldig verzoek"
	end
	if throttled(s) then
		return false, "Rustig aan"
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

demolishFn.OnServerInvoke = function(player, worldPos)
	local s = states[player]
	if not s or typeof(worldPos) ~= "Vector3" then
		return false, "Ongeldig verzoek"
	end
	if throttled(s) then
		return false, "Rustig aan"
	end
	local cs = Config.CellSize
	local rec = s.occ[key(math.floor(worldPos.X / cs), math.floor(worldPos.Z / cs))]
	if not rec then
		return false, "Hier staat niets"
	end
	local def = rec.def
	for x = rec.gx, rec.gx + def.cells[1] - 1 do
		for z = rec.gz, rec.gz + def.cells[2] - 1 do
			s.occ[key(x, z)] = nil
		end
	end
	s.income -= def.income
	s.pop -= def.pop
	local refund = math.floor(def.cost * 0.5)
	s.coins += refund
	rec.model:Destroy()
	table.remove(s.list, table.find(s.list, rec))
	push(player, s)
	return true, def.name .. " gesloopt (+" .. refund .. ")"
end

buyFn.OnServerInvoke = function(player, px, pz)
	local s = states[player]
	if not s or not isInt(px) or not isInt(pz) then
		return false, "Ongeldig verzoek"
	end
	if throttled(s) then
		return false, "Rustig aan"
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
			s.coins += s.income
			push(player, s) -- ook zonder inkomen: zo krijgt een nieuwe client altijd zijn status
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
-- Client: HUD, bouwmenu met categorieen, land kopen, slopen en plaatsen.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("CityRemotes")
local parcels = workspace:WaitForChild("Parcels")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local INK = Color3.fromRGB(40, 40, 90)
local YELLOW = Color3.fromRGB(255, 217, 15)

local state = nil
local mode: string? = nil -- nil | "build" | "land" | "demolish"
local selected = nil
local ghost: Part? = nil
local buttons = {} -- knoppen van de getoonde categorie
local activeCat = 1

local function fmt(n: number): string
	if n >= 1e9 then
		return string.format("%.1fB", n / 1e9)
	elseif n >= 1e6 then
		return string.format("%.1fM", n / 1e6)
	elseif n >= 1e4 then
		return string.format("%.1fK", n / 1e3)
	end
	return tostring(math.floor(n))
end

-- UI -----------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "StadUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function label(parent, size, pos, textSize)
	local l = Instance.new("TextLabel")
	l.Size = size
	l.Position = pos
	l.BackgroundTransparency = 1
	l.TextColor3 = INK
	l.Font = Enum.Font.FredokaOne
	l.TextSize = textSize
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

local function style(frame: GuiObject, radius: number)
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, radius)
	local stroke = Instance.new("UIStroke", frame)
	stroke.Thickness = 3
	stroke.Color = INK
end

local function panel(parent, size, pos)
	local f = Instance.new("Frame")
	f.Size = size
	f.Position = pos
	f.BackgroundColor3 = YELLOW
	f.BorderSizePixel = 0
	f.Parent = parent
	style(f, 12)
	return f
end

local function button(parent, size, text: string, color: Color3)
	local b = Instance.new("TextButton")
	b.Size = size
	b.BackgroundColor3 = color
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.FredokaOne
	b.TextSize = 14
	b.TextWrapped = true
	b.Text = text
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	return b
end

local top = panel(gui, UDim2.fromOffset(340, 92), UDim2.fromOffset(12, 12))
local coinsLabel = label(top, UDim2.new(1, -20, 0, 32), UDim2.fromOffset(12, 6), 26)
local cityLabel = label(top, UDim2.new(1, -20, 0, 22), UDim2.fromOffset(12, 40), 16)
local incomeLabel = label(top, UDim2.new(1, -20, 0, 22), UDim2.fromOffset(12, 64), 16)
incomeLabel.TextColor3 = Color3.fromRGB(30, 120, 50)

local toast = label(gui, UDim2.fromOffset(460, 30), UDim2.new(0.5, -230, 0, 20), 20)
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

-- Onderpaneel: categorieen + lijst met gebouwen
local bottom = panel(gui, UDim2.new(1, -24, 0, 236), UDim2.new(0, 12, 1, -248))

local tabs = Instance.new("ScrollingFrame")
tabs.Size = UDim2.new(1, -316, 0, 38)
tabs.Position = UDim2.fromOffset(8, 8)
tabs.BackgroundTransparency = 1
tabs.BorderSizePixel = 0
tabs.ScrollingDirection = Enum.ScrollingDirection.X
tabs.AutomaticCanvasSize = Enum.AutomaticSize.X
tabs.CanvasSize = UDim2.new()
tabs.ScrollBarThickness = 0
tabs.Parent = bottom
local tabsLayout = Instance.new("UIListLayout")
tabsLayout.FillDirection = Enum.FillDirection.Horizontal
tabsLayout.Padding = UDim.new(0, 6)
tabsLayout.Parent = tabs

local landButton = button(bottom, UDim2.fromOffset(150, 38), "", Color3.fromRGB(150, 100, 40))
landButton.AnchorPoint = Vector2.new(1, 0)
landButton.Position = UDim2.new(1, -168, 0, 8)
local demoButton = button(bottom, UDim2.fromOffset(150, 38), "Slopen (50% terug)", Color3.fromRGB(190, 70, 60))
demoButton.AnchorPoint = Vector2.new(1, 0)
demoButton.Position = UDim2.new(1, -8, 0, 8)
demoButton.TextSize = 13

local grid = Instance.new("ScrollingFrame")
grid.Size = UDim2.new(1, -16, 1, -60)
grid.Position = UDim2.fromOffset(8, 52)
grid.BackgroundTransparency = 1
grid.BorderSizePixel = 0
grid.ScrollingDirection = Enum.ScrollingDirection.Y
grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
grid.CanvasSize = UDim2.new()
grid.ScrollBarThickness = 8
grid.Parent = bottom
local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.fromOffset(150, 74)
gridLayout.CellPadding = UDim2.fromOffset(8, 8)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = grid

-- Gebouwen per categorie, gesorteerd op niveau en prijs
local byCat = {}
for i = 1, #Config.Categories do
	byCat[i] = {}
end
for _, def in Config.Buildings do
	table.insert(byCat[def.cat], def)
end
for _, list in byCat do
	table.sort(list, function(a, b)
		if a.tier ~= b.tier then
			return a.tier < b.tier
		end
		return a.cost < b.cost
	end)
end

-- Spookvorm onder de muis ---------------------------------------------------------
local function clearGhost()
	if ghost then
		ghost:Destroy()
		ghost = nil
	end
	mode, selected = nil, nil
	mouse.TargetFilter = nil
end

local function makeGhost(size: Vector3)
	local g = Instance.new("Part")
	g.Anchored = true
	g.CanCollide = false
	g.CanQuery = false
	g.Transparency = 0.5
	g.Material = Enum.Material.Neon
	g.Size = size
	g.Parent = workspace
	ghost = g
	mouse.TargetFilter = g
end

local function selectBuilding(def)
	clearGhost()
	mode, selected = "build", def
	makeGhost(Vector3.new(def.cells[1] * Config.CellSize, def.height, def.cells[2] * Config.CellSize))
end

local function selectLand()
	clearGhost()
	mode = "land"
	makeGhost(Vector3.new(Config.ParcelSize, 1, Config.ParcelSize))
end

local function selectDemolish()
	clearGhost()
	mode = "demolish"
	makeGhost(Vector3.new(Config.CellSize, 6, Config.CellSize))
end

landButton.Activated:Connect(function()
	if mode == "land" then
		clearGhost()
	else
		selectLand()
	end
end)
demoButton.Activated:Connect(function()
	if mode == "demolish" then
		clearGhost()
	else
		selectDemolish()
	end
end)

-- Lijst opbouwen ---------------------------------------------------------------------
local function refreshUI()
	if not state then
		return
	end
	coinsLabel.Text = "💰 " .. fmt(state.coins)
	cityLabel.Text = string.format("%s · %s inwoners", Config.Tiers[state.tier].name, fmt(state.pop))
	incomeLabel.Text = "+" .. fmt(state.income) .. " per seconde"
	landButton.Text = string.format("Land kopen\n💰 %s (%d stuks)", fmt(state.parcelCost), state.parcelCount)
	for id, b in buttons do
		local def = Config.ById[id]
		if state.tier >= def.tier then
			b.Text = string.format("%s\n💰 %s · +%s/s", def.name, fmt(def.cost), fmt(def.income))
			b.BackgroundColor3 = state.coins >= def.cost and Color3.fromRGB(70, 130, 220) or Color3.fromRGB(120, 120, 135)
		else
			b.Text = string.format("%s\n🔒 %s", def.name, Config.Tiers[def.tier].name)
			b.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
		end
	end
end

local tabButtons = {}
local function showCategory(i: number)
	activeCat = i
	for j, tb in tabButtons do
		tb.BackgroundColor3 = j == i and INK or Color3.fromRGB(70, 130, 220)
	end
	for _, child in grid:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	buttons = {}
	for order, def in byCat[i] do
		local b = button(grid, UDim2.new(), "", Color3.fromRGB(70, 130, 220))
		b.LayoutOrder = order
		b.TextSize = 13
		b.Activated:Connect(function()
			if state and state.tier >= def.tier then
				if selected == def then
					clearGhost()
				else
					selectBuilding(def)
				end
			else
				showToast("Nog niet ontgrendeld: bereik " .. Config.Tiers[def.tier].name, false)
			end
		end)
		buttons[def.id] = b
	end
	grid.CanvasPosition = Vector2.zero
	refreshUI()
end

for i, name in Config.Categories do
	local tb = button(tabs, UDim2.fromOffset(110, 36), string.format("%s (%d)", name, #byCat[i]), Color3.fromRGB(70, 130, 220))
	tb.LayoutOrder = i
	tb.Activated:Connect(function()
		showCategory(i)
	end)
	tabButtons[i] = tb
end
showCategory(1)

remotes.State.OnClientEvent:Connect(function(newState)
	state = newState
	refreshUI()
end)

-- Plaatsen, land kopen en slopen ------------------------------------------------------
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

local GREEN = Color3.fromRGB(80, 255, 120)
local RED = Color3.fromRGB(255, 80, 80)

RunService.RenderStepped:Connect(function()
	if not (ghost and state) then
		return
	end
	local p = mouse.Hit.Position
	local cs = Config.CellSize
	if mode == "land" then
		local px, pz = Config.SnapParcel(p.X), Config.SnapParcel(p.Z)
		ghost.Position = Vector3.new((px + 0.5) * Config.ParcelSize, 0.8, (pz + 0.5) * Config.ParcelSize)
		ghost.Color = (canBuy(px, pz) and state.coins >= state.parcelCost) and GREEN or RED
	elseif mode == "build" and selected then
		local def = selected
		local gx, gz = Config.SnapCell(def, p.X, p.Z)
		ghost.Position = Vector3.new((gx + def.cells[1] / 2) * cs, def.height / 2 + 0.2, (gz + def.cells[2] / 2) * cs)
		ghost.Color = (footprintOwned(def, gx, gz) and state.coins >= def.cost) and GREEN or RED
	elseif mode == "demolish" then
		local gx, gz = math.floor(p.X / cs), math.floor(p.Z / cs)
		ghost.Position = Vector3.new((gx + 0.5) * cs, 3.2, (gz + 0.5) * cs)
		ghost.Color = Color3.fromRGB(255, 160, 40)
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not state then
		return
	end
	if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.X then
		clearGhost()
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 and mode then
		local p = mouse.Hit.Position
		local ok, msg
		if mode == "land" then
			ok, msg = remotes.Buy:InvokeServer(Config.SnapParcel(p.X), Config.SnapParcel(p.Z))
		elseif mode == "build" and selected then
			ok, msg = remotes.Place:InvokeServer(selected.id, p)
		elseif mode == "demolish" then
			ok, msg = remotes.Demolish:InvokeServer(p)
		end
		if msg then
			showToast(msg, ok)
		end
	end
end)

]==])

local base = workspace:FindFirstChild("Baseplate")
if base then base:Destroy() end

print("Loaden City Tycoon geinstalleerd! Druk op Play.")
