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
