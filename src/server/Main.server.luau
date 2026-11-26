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
