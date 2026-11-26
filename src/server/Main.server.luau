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
ground.Color = Color3.fromRGB(96, 140, 80)
ground.Material = Enum.Material.Grass
ground.TopSurface = Enum.SurfaceType.Smooth
ground.Parent = workspace

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

local function buildModel(s: State, def, gx: number, gz: number)
	local cs = Config.CellSize
	local w, d = def.cells[1] * cs - 0.6, def.cells[2] * cs - 0.6
	local part = Instance.new("Part")
	part.Name = def.id
	part.Anchored = true
	part.Size = Vector3.new(w, def.height, d)
	part.Color = def.color
	part.Material = def.id == "Park" and Enum.Material.Grass or Enum.Material.SmoothPlastic
	part.Position = s.origin
		+ Vector3.new((gx + def.cells[1] / 2) * cs, def.height / 2 + 0.2, (gz + def.cells[2] / 2) * cs)
	part.Parent = s.folder
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
	plot.Color = Color3.fromRGB(150, 190, 110)
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
