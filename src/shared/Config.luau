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
