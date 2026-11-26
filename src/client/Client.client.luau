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
