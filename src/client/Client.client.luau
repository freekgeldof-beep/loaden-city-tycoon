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

remotes:WaitForChild("State").OnClientEvent:Connect(function(newState)
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
			ok, msg = remotes:WaitForChild("Buy"):InvokeServer(Config.SnapParcel(p.X), Config.SnapParcel(p.Z))
		elseif mode == "build" and selected then
			ok, msg = remotes:WaitForChild("Place"):InvokeServer(selected.id, p)
		elseif mode == "demolish" then
			ok, msg = remotes:WaitForChild("Demolish"):InvokeServer(p)
		end
		if msg then
			showToast(msg, ok)
		end
	end
end)
