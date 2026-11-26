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
