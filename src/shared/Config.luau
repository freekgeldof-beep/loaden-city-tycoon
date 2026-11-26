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
