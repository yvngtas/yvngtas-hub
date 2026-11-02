-- ==============================================================================
-- YVNGTAS HUB | TSB HALLOWEEN
-- High-Performance Professional Dark Edition (Orange Theme)
-- Complete English translation, No emojis, Professional typography
-- Clean, modern UI layout: Dashboard Utilities, Teleports, Visuals ESP
-- Features: Instant Door (0s hold), No Knock Anim & Move Free, Candy Vacuum Magnet,
--           Live Doors Direct TP, Multi-Target ESP with Chams & Name Toggle
-- ==============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Clean up any previous instance
if _G.TSBHalloweenESP and type(_G.TSBHalloweenESP.Destroy) == "function" then
	pcall(_G.TSBHalloweenESP.Destroy)
end

local State = {
	HalloweenBaby = true,
	HalloweenDoors = true,
	TrashCans = true,
	TrashMonster = true,
	HalloweenZombies = false,
	PlayerESP = true,
	ShowDistance = true,
	ShowNames = true, -- Toggle text labels on/off; when off, leaves only colors around parts
	ShowHighlight = true, -- Colors around parts (Chams)
	HideBrokenCans = true,
	MaxDistance = 2500,
	TextScale = 1,
	ActiveTab = "Dashboard", -- "Dashboard", "Teleports", "Visuals", "Settings"
	InstantDoor = true,
	CandyMagnet = true,
	AutoSweep = true,
	BabyHp1 = false,
	Running = true,
}

local Connections = {}
local TrackedObjects = {}
local CycleDoorIndex = 0
local CycleCanIndex = 0

-- Resolve safe GUI parent
local function getGuiParent()
	local ok, hui = pcall(function()
		return gethui and gethui()
	end)
	if ok and hui then
		return hui
	end
	local okCore, _ = pcall(function()
		return CoreGui.Name
	end)
	if okCore then
		return CoreGui
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local GuiParent = getGuiParent()

-- ESP Visuals Container Folders
local EspFolder = Instance.new("Folder")
EspFolder.Name = "YvngTasHub_ESP_Container"
EspFolder.Parent = GuiParent

-- Dedicated 3D Highlight Container in Workspace for 100% reliable rendering
local HighlightFolder = workspace:FindFirstChild("YvngTasHub_Highlights")
if not HighlightFolder then
	HighlightFolder = Instance.new("Folder")
	HighlightFolder.Name = "YvngTasHub_Highlights"
	HighlightFolder.Parent = workspace
end

-- Palette (Sleek Dark Obsidian + Electric Orange)
local THEME = {
	WindowBg = Color3.fromRGB(15, 16, 20),
	SidebarBg = Color3.fromRGB(11, 12, 15),
	CardBg = Color3.fromRGB(22, 24, 30),
	CardHover = Color3.fromRGB(28, 30, 38),
	RowBg = Color3.fromRGB(19, 21, 26),
	Divider = Color3.fromRGB(30, 33, 42),
	Stroke = Color3.fromRGB(38, 41, 52),
	StrokeAccent = Color3.fromRGB(255, 112, 26),
	TextPrimary = Color3.fromRGB(245, 247, 252),
	TextSecondary = Color3.fromRGB(138, 144, 158),
	TextMuted = Color3.fromRGB(85, 91, 105),
	Accent = Color3.fromRGB(255, 112, 26),
	AccentHover = Color3.fromRGB(255, 130, 45),
	AccentSoft = Color3.fromRGB(42, 24, 15),
	AccentText = Color3.fromRGB(255, 125, 35),
	ToggleOff = Color3.fromRGB(45, 48, 60),
	StatusGreen = Color3.fromRGB(60, 215, 120),
	StatusOrange = Color3.fromRGB(255, 120, 30),
	StatusPurple = Color3.fromRGB(160, 115, 210),
	StatusRed = Color3.fromRGB(255, 65, 75),
}

local ESP_COLORS = {
	Baby = Color3.fromRGB(255, 185, 35),
	DoorReady = Color3.fromRGB(255, 112, 26),
	DoorBusy = Color3.fromRGB(165, 120, 200),
	TrashCan = Color3.fromRGB(40, 215, 160),
	TrashOccupied = Color3.fromRGB(255, 65, 75),
	TrashBroken = Color3.fromRGB(120, 125, 135),
	TrashMonster = Color3.fromRGB(255, 55, 85),
	Zombie = Color3.fromRGB(105, 235, 95),
	Player = Color3.fromRGB(35, 195, 255),
}

-- ==============================================================================
-- TELEPORT ENGINE
-- ==============================================================================

local function teleportToPosition(targetPos, lookPos)
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	hrp.AssemblyLinearVelocity = Vector3.zero
	if lookPos then
		hrp.CFrame = CFrame.lookAt(targetPos, lookPos)
	else
		hrp.CFrame = CFrame.new(targetPos)
	end
	return true
end

-- Halloween Baby (Penyta / Pinata) Resolver
local function getBabyModel()
	local live = workspace:FindFirstChild("Live")
	if live then
		for _, m in ipairs(live:GetChildren()) do
			if m:IsA("Model") and not Players:GetPlayerFromCharacter(m) then
				local nameLower = m.Name:lower()
				local isBaby = (m.Name == "Penyta") or (nameLower:find("penyta") ~= nil) or (nameLower:find("baby") ~= nil) or (m:GetAttribute("Pinata") == true and m.Name ~= "TrashGuy")
				if isBaby then
					local hum = m:FindFirstChildOfClass("Humanoid")
					local pinataHp = tonumber(m:GetAttribute("PinataHP"))
					local alive = (hum and hum.Health > 0) or (pinataHp == nil or pinataHp > 0)
					if alive then
						return m, hum
					end
				end
			end
		end
	end
	for _, m in ipairs(workspace:GetChildren()) do
		if m:IsA("Model") and not Players:GetPlayerFromCharacter(m) then
			local nameLower = m.Name:lower()
			local isBaby = (m.Name == "Penyta") or (nameLower:find("penyta") ~= nil) or (nameLower:find("baby") ~= nil) or (m:GetAttribute("Pinata") == true and m.Name ~= "TrashGuy")
			if isBaby then
				local hum = m:FindFirstChildOfClass("Humanoid")
				local pinataHp = tonumber(m:GetAttribute("PinataHP"))
				local alive = (hum and hum.Health > 0) or (pinataHp == nil or pinataHp > 0)
				if alive then
					return m, hum
				end
			end
		end
	end
	return nil, nil
end

local function setBabyHpToOne()
	local babyModel, hum = getBabyModel()
	if babyModel then
		pcall(function()
			if hum then hum.Health = 1 end
			babyModel:SetAttribute("PinataHP", 1)
		end)
		return true
	end
	return false
end

-- Teleport to Halloween Baby (Penyta)
local function teleportToBaby()
	local babyModel = getBabyModel()
	if babyModel then
		local root = babyModel:FindFirstChild("HumanoidRootPart")
			or babyModel.PrimaryPart
			or babyModel:FindFirstChildWhichIsA("BasePart", true)
		if root then
			local dest = root.Position + Vector3.new(0, 1.5, 4)
			return teleportToPosition(dest, root.Position)
		end
	end
	return false
end

-- Teleport to Candy Merchant (Shopkeeper in workspace.Cart)
local function teleportToMerchant()
	local cart = workspace:FindFirstChild("Cart")
	local sk = cart and cart:FindFirstChild("Shopkeeper")
	local skHrp = sk and sk:FindFirstChild("HumanoidRootPart")
	local sz = cart and cart:FindFirstChild("ShopZone")

	if skHrp then
		local flatLook = skHrp.CFrame.LookVector * Vector3.new(1, 0, 1)
		local outDir = flatLook.Magnitude > 0.01 and flatLook.Unit or Vector3.new(-1, 0, 0)
		local dest = skHrp.Position + outDir * 5
		return teleportToPosition(dest, Vector3.new(skHrp.Position.X, dest.Y, skHrp.Position.Z))
	elseif sz and sz:IsA("BasePart") then
		return teleportToPosition(sz.Position + Vector3.new(0, 2, 0))
	end
	return false
end

-- Get Sorted Doors
local function getSortedDoors(onlyReady)
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local myPos = hrp and hrp.Position
		or (workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position)
		or Vector3.zero

	local list = {}
	local folder = workspace:FindFirstChild("HalloweenDoorTrees")
	if not folder then return list end

	for idx, doorTree in ipairs(folder:GetChildren()) do
		if doorTree:IsA("Model") then
			local frame = doorTree:FindFirstChild("Frame", true)
				or doorTree:FindFirstChild("Backing", true)
				or doorTree:FindFirstChildWhichIsA("BasePart", true)
			if frame then
				local prompt = doorTree:FindFirstChild("TrickOrTreat", true)
				local isReady = not prompt or (prompt:GetAttribute("Open") ~= false)
				if not onlyReady or isReady then
					local dist = math.floor((frame.Position - myPos).Magnitude + 0.5)
					table.insert(list, {
						Model = doorTree,
						Index = idx,
						Ready = isReady,
						Distance = dist,
					})
				end
			end
		end
	end

	table.sort(list, function(a, b)
		if a.Ready ~= b.Ready then return a.Ready end
		return a.Distance < b.Distance
	end)
	return list
end

-- Get Sorted Trash Cans
local function getSortedTrashCans(onlyIntact)
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local myPos = hrp and hrp.Position
		or (workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position)
		or Vector3.zero

	local list = {}
	local map = workspace:FindFirstChild("Map")
	local trashFolder = map and map:FindFirstChild("Trash")
	if not trashFolder then return list end

	for idx, can in ipairs(trashFolder:GetChildren()) do
		if can:IsA("Model") then
			local part = can:FindFirstChild("Trashcan") or can:FindFirstChildWhichIsA("BasePart", true)
			if part then
				local broken = (can:GetAttribute("Broken") == true)
					or (part.Transparency >= 0.5)
					or (not part.CanCollide)
				if not onlyIntact or not broken then
					local dist = math.floor((part.Position - myPos).Magnitude + 0.5)
					table.insert(list, {
						Model = can,
						Part = part,
						Index = idx,
						Broken = broken,
						Distance = dist,
					})
				end
			end
		end
	end

	table.sort(list, function(a, b)
		if a.Broken ~= b.Broken then return not a.Broken end
		return a.Distance < b.Distance
	end)
	return list
end

-- Teleport to Door
local function teleportToDoor(doorTarget)
	local doorModel = doorTarget
	if typeof(doorTarget) == "number" then
		local sorted = getSortedDoors(true)
		local item = sorted[doorTarget] or sorted[1]
		doorModel = item and item.Model
	end
	if not doorModel or not doorModel.Parent then return false end
	local frame = doorModel:FindFirstChild("Frame", true)
		or doorModel:FindFirstChild("Backing", true)
		or doorModel:FindFirstChildWhichIsA("BasePart", true)
	if not frame then return false end

	local flatOut = (-frame.CFrame.RightVector) * Vector3.new(1, 0, 1)
	local outDir = flatOut.Magnitude > 0.01 and flatOut.Unit or Vector3.new(0, 0, 1)
	local dest = frame.Position + outDir * 4.5
	local lookPos = Vector3.new(frame.Position.X, dest.Y, frame.Position.Z)
	return teleportToPosition(dest, lookPos)
end

-- Teleport to Trash Can
local function teleportToTrashCan(canTarget)
	local canModel = canTarget
	if typeof(canTarget) == "number" then
		local sorted = getSortedTrashCans(true)
		local item = sorted[canTarget] or sorted[1]
		canModel = item and item.Model
	end
	if not canModel or not canModel.Parent then return false end
	local part = canModel:FindFirstChild("Trashcan") or canModel:FindFirstChildWhichIsA("BasePart", true)
	if not part then return false end

	local dest = part.Position + Vector3.new(0, 1.5, 3.5)
	return teleportToPosition(dest, part.Position)
end

-- ==============================================================================
-- INSTANT DOOR & MOVE FREE WHILE KNOCKING ENGINE
-- ==============================================================================

local function applyDoorHoldDuration()
	local folder = workspace:FindFirstChild("HalloweenDoorTrees")
	if not folder then return end
	local duration = State.InstantDoor and 0 or 3.5
	for _, doorTree in ipairs(folder:GetChildren()) do
		local prompt = doorTree:FindFirstChild("TrickOrTreat", true)
		if prompt then
			pcall(function()
				prompt.HoldDuration = duration
			end)
		end
	end
end

-- Instant Door Interaction hook
table.insert(Connections, ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, player)
	if player == LocalPlayer and prompt.Name == "TrickOrTreat" then
		if State.InstantDoor then
			pcall(function()
				prompt.HoldDuration = 0
				if type(fireproximityprompt) == "function" then
					fireproximityprompt(prompt, 0)
				end
			end)
		end
	end
end))

table.insert(Connections, ProximityPromptService.PromptShown:Connect(function(prompt)
	if State.InstantDoor and prompt.Name == "TrickOrTreat" then
		pcall(function()
			prompt.HoldDuration = 0
		end)
	end
end))

-- ==============================================================================
-- CANDY VACUUM MAGNET ENGINE (True Smooth Suction & Instant Auto-Collect)
-- ==============================================================================

local function getCandyPosition(c)
	local rest = c:GetAttribute("Rest")
	if typeof(rest) == "CFrame" then
		return rest.Position
	elseif type(rest) == "string" then
		local p = string.split(rest, ",")
		if #p >= 3 then
			local x = tonumber(p[1])
			local y = tonumber(p[2])
			local z = tonumber(p[3])
			if x and y and z then
				return Vector3.new(x, y, z)
			end
		end
	end
	return nil
end

local function getNearbyCandies(maxDist)
	maxDist = maxDist or 200
	local res = {}
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local myPos = hrp and hrp.Position or Vector3.zero

	local hc = workspace:FindFirstChild("HalloweenCandy")
	if hc then
		local now = workspace:GetServerTimeNow()
		for _, c in ipairs(hc:GetChildren()) do
			local expire = c:GetAttribute("Expire")
			if not expire or expire > now then
				local cPos = getCandyPosition(c)
				if cPos and (cPos - myPos).Magnitude <= maxDist then
					table.insert(res, c)
				end
			end
		end
	end
	return res
end

-- Continuous visual vacuum stream: smoothly suctions candies towards the player in real time
table.insert(Connections, RunService.RenderStepped:Connect(function(dt)
	if not State.CandyMagnet or not State.Running then return end

	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local myPos = hrp.Position
	local targetPos = myPos + Vector3.new(0, 1.2, 0)
	local cv = workspace:FindFirstChild("CandyVisuals")
	if not cv then return end

	local pullSpeed = math.clamp(dt * 20, 0.20, 0.85)

	for _, p in ipairs(cv:GetChildren()) do
		if p:IsA("BasePart") and p.Position.Y > -500 then
			local dist = (p.Position - myPos).Magnitude
			if dist <= 140 and dist > 0.8 then
				p.CFrame = p.CFrame:Lerp(CFrame.new(targetPos), pullSpeed)
			end
		end
	end
end))

-- ==============================================================================
-- CANDY SWEEP ENGINE (Option 1: Quick Sweep through candy drop zones)
-- ==============================================================================

local isSweeping = false
local function sweepCandies()
	if isSweeping or not State.Running then return false end
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then return false end
	if char:GetAttribute("Ragdoll") == true or char:GetAttribute("Freeze") == true then return false end

	local hc = workspace:FindFirstChild("HalloweenCandy")
	if not hc then return false end

	local candies = hc:GetChildren()
	if #candies == 0 then return false end

	local myPos = hrp.Position
	local now = workspace:GetServerTimeNow()
	local targets = {}
	for _, c in ipairs(candies) do
		local expire = c:GetAttribute("Expire")
		if not expire or expire > now then
			local cPos = getCandyPosition(c)
			if cPos then
				local dist = (cPos - myPos).Magnitude
				if dist <= 120 then
					table.insert(targets, { candy = c, pos = cPos, dist = dist })
				end
			end
		end
	end

	if #targets == 0 then return false end

	table.sort(targets, function(a, b) return a.dist < b.dist end)

	isSweeping = true
	local origCF = hrp.CFrame
	local origVel = hrp.AssemblyLinearVelocity

	for _, t in ipairs(targets) do
		if t.candy.Parent == hc and hum.Health > 0 and State.Running then
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.CFrame = CFrame.new(t.pos + Vector3.new(0, 0.4, 0), origCF.Position + origCF.LookVector)
			task.wait(0.025)
		end
	end

	if hrp and hrp.Parent and hum.Health > 0 then
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.CFrame = origCF
	end
	isSweeping = false
	return true
end

-- Auto-sweep background task
task.spawn(function()
	while State.Running do
		if State.AutoSweep and not isSweeping then
			local hc = workspace:FindFirstChild("HalloweenCandy")
			if hc and #hc:GetChildren() > 0 then
				local char = LocalPlayer.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp then
					local myPos = hrp.Position
					local hasNearby = false
					for _, c in ipairs(hc:GetChildren()) do
						local cPos = getCandyPosition(c)
						if cPos and (cPos - myPos).Magnitude <= 50 then
							hasNearby = true
							break
						end
					end
					if hasNearby then
						pcall(sweepCandies)
					end
				end
			end
		end
		task.wait(0.4)
	end
end)

-- Background monitor for Baby Halloween HP enforcement
task.spawn(function()
	while State.Running do
		if State.BabyHp1 then
			pcall(function()
				local babyModel, hum = getBabyModel()
				if babyModel then
					if hum and hum.Health > 1 then
						hum.Health = 1
					end
					local pinataHp = tonumber(babyModel:GetAttribute("PinataHP"))
					if pinataHp and pinataHp > 1 then
						babyModel:SetAttribute("PinataHP", 1)
					end
				end
			end)
		end
		task.wait(0.25)
	end
end)

-- ==============================================================================
-- GUI CONSTRUCTION (Unified Master Window)
-- ==============================================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "YvngTasHub_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = GuiParent

local WINDOW_WIDTH = 740
local WINDOW_HEIGHT = 440

local MainWindow = Instance.new("Frame")
MainWindow.Name = "MainWindow"
MainWindow.Size = UDim2.fromOffset(WINDOW_WIDTH, WINDOW_HEIGHT)
MainWindow.Position = UDim2.new(0.5, -WINDOW_WIDTH / 2, 0.5, -WINDOW_HEIGHT / 2)
MainWindow.BackgroundColor3 = THEME.WindowBg
MainWindow.BackgroundTransparency = 0.22
MainWindow.BorderSizePixel = 0
MainWindow.Active = true
MainWindow.ClipsDescendants = true
MainWindow.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainWindow

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(255, 255, 255)
MainStroke.Thickness = 1
MainStroke.Transparency = 0.85
MainStroke.Parent = MainWindow

local MainGrad = Instance.new("UIGradient")
MainGrad.Rotation = 90
MainGrad.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(215, 220, 235))
MainGrad.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(1, 0.15),
})
MainGrad.Parent = MainWindow

-- ==============================================================================
-- SIDEBAR (Width: 175px)
-- ==============================================================================

local SIDEBAR_WIDTH = 175

local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, SIDEBAR_WIDTH, 1, 0)
Sidebar.Position = UDim2.fromOffset(0, 0)
Sidebar.BackgroundColor3 = THEME.SidebarBg
Sidebar.BackgroundTransparency = 0.32
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainWindow

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 10)
SidebarCorner.Parent = Sidebar

local SidebarRightFix = Instance.new("Frame")
SidebarRightFix.Size = UDim2.new(0, 14, 1, 0)
SidebarRightFix.Position = UDim2.new(1, -14, 0, 0)
SidebarRightFix.BackgroundColor3 = THEME.SidebarBg
SidebarRightFix.BackgroundTransparency = 0.32
SidebarRightFix.BorderSizePixel = 0
SidebarRightFix.Parent = Sidebar

local SidebarBorder = Instance.new("Frame")
SidebarBorder.Size = UDim2.new(0, 1, 1, 0)
SidebarBorder.Position = UDim2.new(1, -1, 0, 0)
SidebarBorder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SidebarBorder.BackgroundTransparency = 0.90
SidebarBorder.BorderSizePixel = 0
SidebarBorder.Parent = Sidebar

-- Brand Title & Subtitle
local BrandHeader = Instance.new("Frame")
BrandHeader.Name = "BrandHeader"
BrandHeader.Size = UDim2.new(1, 0, 0, 64)
BrandHeader.BackgroundTransparency = 1
BrandHeader.Parent = Sidebar

local BrandTitle = Instance.new("TextLabel")
BrandTitle.Size = UDim2.new(1, -28, 0, 22)
BrandTitle.Position = UDim2.fromOffset(18, 14)
BrandTitle.BackgroundTransparency = 1
BrandTitle.Text = "YVNGTAS HUB"
BrandTitle.TextColor3 = THEME.TextPrimary
BrandTitle.Font = Enum.Font.GothamBlack
BrandTitle.TextSize = 15
BrandTitle.TextXAlignment = Enum.TextXAlignment.Left
BrandTitle.Parent = BrandHeader

local BrandSub = Instance.new("TextLabel")
BrandSub.Size = UDim2.new(1, -28, 0, 14)
BrandSub.Position = UDim2.fromOffset(18, 36)
BrandSub.BackgroundTransparency = 1
BrandSub.Text = "TSB HALLOWEEN"
BrandSub.TextColor3 = THEME.Accent
BrandSub.Font = Enum.Font.GothamBold
BrandSub.TextSize = 9
BrandSub.TextXAlignment = Enum.TextXAlignment.Left
BrandSub.Parent = BrandHeader

local BrandDivider = Instance.new("Frame")
BrandDivider.Size = UDim2.new(1, -24, 0, 1)
BrandDivider.Position = UDim2.fromOffset(12, 63)
BrandDivider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
BrandDivider.BackgroundTransparency = 0.90
BrandDivider.BorderSizePixel = 0
BrandDivider.Parent = BrandHeader

-- Navigation Menu List
local NavList = Instance.new("Frame")
NavList.Name = "NavList"
NavList.Size = UDim2.new(1, -16, 1, -132)
NavList.Position = UDim2.fromOffset(8, 72)
NavList.BackgroundTransparency = 1
NavList.Parent = Sidebar

local NavLayout = Instance.new("UIListLayout")
NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
NavLayout.Padding = UDim.new(0, 4)
NavLayout.Parent = NavList

local function createSectionTag(order, labelText)
	local tag = Instance.new("TextLabel")
	tag.LayoutOrder = order
	tag.Size = UDim2.new(1, -12, 0, 18)
	tag.Position = UDim2.fromOffset(8, 0)
	tag.BackgroundTransparency = 1
	tag.Text = "  " .. string.upper(labelText)
	tag.TextColor3 = THEME.TextMuted
	tag.Font = Enum.Font.GothamBold
	tag.TextSize = 9
	tag.TextXAlignment = Enum.TextXAlignment.Left
	tag.Parent = NavList
end

local SOLAR_ICONS = {
	Dashboard = {
		fileName = "solar_dashboard.png",
		url = "https://images.weserv.nl/?url=https://api.iconify.design/solar/widget-2-bold.svg?color=%2523ffffff&w=64&h=64&output=png",
		glyph = "◈"
	},
	Teleports = {
		fileName = "solar_teleports.png",
		url = "https://images.weserv.nl/?url=https://api.iconify.design/solar/map-point-wave-bold.svg?color=%2523ffffff&w=64&h=64&output=png",
		glyph = "⌖"
	},
	Visuals = {
		fileName = "solar_visuals.png",
		url = "https://images.weserv.nl/?url=https://api.iconify.design/solar/eye-bold.svg?color=%2523ffffff&w=64&h=64&output=png",
		glyph = "👁"
	},
	Settings = {
		fileName = "solar_settings.png",
		url = "https://images.weserv.nl/?url=https://api.iconify.design/solar/settings-bold.svg?color=%2523ffffff&w=64&h=64&output=png",
		glyph = "⚙"
	}
}

local function getSolarAsset(info)
	local isf = isfile or (syn and syn.isfile)
	local wrf = writefile or (syn and syn.writefile)
	local getasset = getsynasset or getcustomasset
	if not getasset then return nil end

	if isf and isf(info.fileName) then
		local ok, res = pcall(getasset, info.fileName)
		if ok and res and res ~= "" then return res end
	end

	local req = (syn and syn.request) or (http and http.request) or http_request or request
	if req and wrf then
		pcall(function()
			local resp = req({ Url = info.url, Method = "GET" })
			if resp and (resp.StatusCode == 200 or resp.Status == 200) and resp.Body and #resp.Body > 100 then
				wrf(info.fileName, resp.Body)
			end
		end)
	elseif game.HttpGet and wrf then
		pcall(function()
			local body = game:HttpGet(info.url)
			if body and #body > 100 then
				wrf(info.fileName, body)
			end
		end)
	end

	if isf and isf(info.fileName) then
		local ok, res = pcall(getasset, info.fileName)
		if ok and res and res ~= "" then return res end
	end

	return nil
end

local NavTabs = {}
local SwitchTab = function() end

local function createNavTabBtn(order, tabKey, labelText, fallbackGlyph)
	local btn = Instance.new("TextButton")
	btn.LayoutOrder = order
	btn.Size = UDim2.new(1, 0, 0, 32)
	btn.AutoButtonColor = false
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.Parent = NavList

	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 6)
	bc.Parent = btn

	local pill = Instance.new("Frame")
	pill.Size = UDim2.new(0, 3, 0, 16)
	pill.Position = UDim2.new(0, 2, 0.5, -8)
	pill.BackgroundColor3 = THEME.Accent
	pill.BorderSizePixel = 0
	pill.Visible = false
	pill.Parent = btn

	local pillCorner = Instance.new("UICorner")
	pillCorner.CornerRadius = UDim.new(1, 0)
	pillCorner.Parent = pill

	local iconAsset = getSolarAsset(SOLAR_ICONS[tabKey])
	local iconImg, iconTxt

	if iconAsset then
		iconImg = Instance.new("ImageLabel")
		iconImg.Size = UDim2.fromOffset(16, 16)
		iconImg.Position = UDim2.new(0, 11, 0.5, -8)
		iconImg.BackgroundTransparency = 1
		iconImg.Image = iconAsset
		iconImg.ImageColor3 = THEME.TextMuted
		iconImg.Parent = btn
	else
		iconTxt = Instance.new("TextLabel")
		iconTxt.Size = UDim2.fromOffset(18, 18)
		iconTxt.Position = UDim2.new(0, 10, 0.5, -9)
		iconTxt.BackgroundTransparency = 1
		iconTxt.Text = fallbackGlyph or "◈"
		iconTxt.Font = Enum.Font.GothamBold
		iconTxt.TextSize = 11
		iconTxt.TextColor3 = THEME.TextMuted
		iconTxt.Parent = btn
	end

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1, -40, 1, 0)
	txt.Position = UDim2.fromOffset(34, 0)
	txt.BackgroundTransparency = 1
	txt.Text = labelText
	txt.Font = Enum.Font.GothamSemibold
	txt.TextSize = 12
	txt.TextXAlignment = Enum.TextXAlignment.Left
	txt.Parent = btn

	btn.MouseEnter:Connect(function()
		if State.ActiveTab ~= tabKey then
			btn.BackgroundTransparency = 0.55
			btn.BackgroundColor3 = THEME.CardBg
		end
	end)
	btn.MouseLeave:Connect(function()
		if State.ActiveTab ~= tabKey then
			btn.BackgroundTransparency = 1
		end
	end)

	local tabItem = { Button = btn, IconImg = iconImg, IconTxt = iconTxt, Text = txt, Pill = pill, Key = tabKey }
	table.insert(NavTabs, tabItem)

	btn.MouseButton1Click:Connect(function()
		SwitchTab(tabKey)
	end)
end

createSectionTag(1, "CORE")
createNavTabBtn(2, "Dashboard", "Dashboard", "◈")
createNavTabBtn(3, "Teleports", "Teleports", "⌖")
createNavTabBtn(4, "Visuals", "Visuals ESP", "👁")
createNavTabBtn(5, "Settings", "Settings", "⚙")

-- User Profile Box
local UserBox = Instance.new("Frame")
UserBox.Name = "UserBox"
UserBox.Size = UDim2.new(1, -16, 0, 48)
UserBox.Position = UDim2.new(0, 8, 1, -56)
UserBox.BackgroundColor3 = THEME.CardBg
UserBox.BackgroundTransparency = 0.35
UserBox.BorderSizePixel = 0
UserBox.Parent = Sidebar

local UserBoxCorner = Instance.new("UICorner")
UserBoxCorner.CornerRadius = UDim.new(0, 8)
UserBoxCorner.Parent = UserBox

local UserBoxStroke = Instance.new("UIStroke")
UserBoxStroke.Color = Color3.fromRGB(255, 255, 255)
UserBoxStroke.Thickness = 1
UserBoxStroke.Transparency = 0.88
UserBoxStroke.Parent = UserBox

local Avatar = Instance.new("ImageLabel")
Avatar.Size = UDim2.fromOffset(30, 30)
Avatar.Position = UDim2.new(0, 9, 0.5, -15)
Avatar.BackgroundColor3 = THEME.CardBg
Avatar.BorderSizePixel = 0
Avatar.Parent = UserBox

task.spawn(function()
	pcall(function()
		local content = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		Avatar.Image = content
	end)
end)

local AvatarCorner = Instance.new("UICorner")
AvatarCorner.CornerRadius = UDim.new(1, 0)
AvatarCorner.Parent = Avatar

local UserLabel = Instance.new("TextLabel")
UserLabel.Size = UDim2.new(1, -50, 0, 14)
UserLabel.Position = UDim2.fromOffset(46, 9)
UserLabel.BackgroundTransparency = 1
UserLabel.Text = LocalPlayer.Name
UserLabel.TextColor3 = THEME.TextPrimary
UserLabel.Font = Enum.Font.GothamBold
UserLabel.TextSize = 11
UserLabel.TextXAlignment = Enum.TextXAlignment.Left
UserLabel.TextTruncate = Enum.TextTruncate.AtEnd
UserLabel.Parent = UserBox

local StatusSub = Instance.new("TextLabel")
StatusSub.Size = UDim2.new(1, -50, 0, 12)
StatusSub.Position = UDim2.fromOffset(46, 24)
StatusSub.BackgroundTransparency = 1
StatusSub.Text = "ACTIVE • LIFETIME"
StatusSub.TextColor3 = THEME.Accent
StatusSub.Font = Enum.Font.GothamBold
StatusSub.TextSize = 9
StatusSub.TextXAlignment = Enum.TextXAlignment.Left
StatusSub.Parent = UserBox

task.spawn(function()
	local ok, img = pcall(function()
		return Players:GetUserThumbnailAsync(
			LocalPlayer.UserId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size100x100
		)
	end)
	if ok and img then
		Avatar.Image = img
	end
end)

-- ==============================================================================
-- RIGHT CONTENT AREA
-- ==============================================================================

local RightArea = Instance.new("Frame")
RightArea.Name = "RightArea"
RightArea.Size = UDim2.new(1, -SIDEBAR_WIDTH, 1, 0)
RightArea.Position = UDim2.fromOffset(SIDEBAR_WIDTH, 0)
RightArea.BackgroundTransparency = 1
RightArea.Parent = MainWindow

-- Top Header Toolbar
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 52)
TopBar.BackgroundTransparency = 1
TopBar.Parent = RightArea

local TopDivider = Instance.new("Frame")
TopDivider.Size = UDim2.new(1, -28, 0, 1)
TopDivider.Position = UDim2.fromOffset(14, 51)
TopDivider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TopDivider.BackgroundTransparency = 0.90
TopDivider.BorderSizePixel = 0
TopDivider.Parent = TopBar

-- Active Tab Indicator Badge
local TabBadge = Instance.new("Frame")
TabBadge.Size = UDim2.fromOffset(116, 28)
TabBadge.Position = UDim2.fromOffset(14, 12)
TabBadge.BackgroundColor3 = THEME.CardBg
TabBadge.BackgroundTransparency = 0.35
TabBadge.BorderSizePixel = 0
TabBadge.Parent = TopBar

local TabBadgeCorner = Instance.new("UICorner")
TabBadgeCorner.CornerRadius = UDim.new(0, 6)
TabBadgeCorner.Parent = TabBadge

local TabBadgeStroke = Instance.new("UIStroke")
TabBadgeStroke.Color = Color3.fromRGB(255, 255, 255)
TabBadgeStroke.Thickness = 1
TabBadgeStroke.Transparency = 0.88
TabBadgeStroke.Parent = TabBadge

local TabBadgeText = Instance.new("TextLabel")
TabBadgeText.Size = UDim2.fromScale(1, 1)
TabBadgeText.BackgroundTransparency = 1
TabBadgeText.Text = "DASHBOARD"
TabBadgeText.TextColor3 = THEME.TextPrimary
TabBadgeText.Font = Enum.Font.GothamBold
TabBadgeText.TextSize = 10
TabBadgeText.Parent = TabBadge

-- Live Counts Status Pill
local StatusPill = Instance.new("Frame")
StatusPill.Size = UDim2.fromOffset(260, 28)
StatusPill.Position = UDim2.fromOffset(138, 12)
StatusPill.BackgroundColor3 = THEME.CardBg
StatusPill.BackgroundTransparency = 0.35
StatusPill.BorderSizePixel = 0
StatusPill.Parent = TopBar

local StatusPillCorner = Instance.new("UICorner")
StatusPillCorner.CornerRadius = UDim.new(0, 6)
StatusPillCorner.Parent = StatusPill

local StatusPillStroke = Instance.new("UIStroke")
StatusPillStroke.Color = Color3.fromRGB(255, 255, 255)
StatusPillStroke.Thickness = 1
StatusPillStroke.Transparency = 0.88
StatusPillStroke.Parent = StatusPill

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.fromScale(1, 1)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "PLR: 0  |  BABY: 0  |  DOORS: 0  |  CANS: 0"
StatusLabel.TextColor3 = THEME.Accent
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.TextSize = 10
StatusLabel.Parent = StatusPill

-- Top-Right Controls (Minimize / Close)
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Size = UDim2.fromOffset(28, 28)
MinimizeBtn.Position = UDim2.new(1, -74, 0, 12)
MinimizeBtn.BackgroundColor3 = THEME.CardBg
MinimizeBtn.BackgroundTransparency = 0.35
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Text = "—"
MinimizeBtn.TextColor3 = THEME.TextSecondary
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 12
MinimizeBtn.Parent = TopBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinimizeBtn

local MinStroke = Instance.new("UIStroke")
MinStroke.Color = Color3.fromRGB(255, 255, 255)
MinStroke.Thickness = 1
MinStroke.Transparency = 0.88
MinStroke.Parent = MinimizeBtn

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.fromOffset(28, 28)
CloseBtn.Position = UDim2.new(1, -40, 0, 12)
CloseBtn.BackgroundColor3 = THEME.Accent
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.Parent = TopBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

-- ==============================================================================
-- TAB PAGES CONTAINER
-- ==============================================================================

local PagesArea = Instance.new("Frame")
PagesArea.Name = "PagesArea"
PagesArea.Size = UDim2.new(1, -28, 1, -66)
PagesArea.Position = UDim2.fromOffset(14, 58)
PagesArea.BackgroundTransparency = 1
PagesArea.Parent = RightArea

-- Helper to create card group container
local function createGroupCard(parentContainer, order, headerTitle)
	local wrap = Instance.new("Frame")
	wrap.LayoutOrder = order
	wrap.Size = UDim2.new(1, 0, 0, 0)
	wrap.AutomaticSize = Enum.AutomaticSize.Y
	wrap.BackgroundTransparency = 1
	wrap.Parent = parentContainer

	local marker = Instance.new("Frame")
	marker.Size = UDim2.fromOffset(3, 11)
	marker.Position = UDim2.fromOffset(2, 4)
	marker.BackgroundColor3 = THEME.Accent
	marker.BorderSizePixel = 0
	marker.Parent = wrap

	local mc = Instance.new("UICorner")
	mc.CornerRadius = UDim.new(1, 0)
	mc.Parent = marker

	local hdr = Instance.new("TextLabel")
	hdr.Size = UDim2.new(1, -14, 0, 18)
	hdr.Position = UDim2.fromOffset(10, 0)
	hdr.BackgroundTransparency = 1
	hdr.Text = string.upper(headerTitle)
	hdr.TextColor3 = THEME.TextSecondary
	hdr.Font = Enum.Font.GothamBold
	hdr.TextSize = 11
	hdr.TextXAlignment = Enum.TextXAlignment.Left
	hdr.Parent = wrap

	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 0)
	card.Position = UDim2.fromOffset(0, 20)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundColor3 = THEME.CardBg
	card.BackgroundTransparency = 0.35
	card.BorderSizePixel = 0
	card.Parent = wrap

	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 8)
	cc.Parent = card

	local cs = Instance.new("UIStroke")
	cs.Color = Color3.fromRGB(255, 255, 255)
	cs.Thickness = 1
	cs.Transparency = 0.88
	cs.Parent = card

	local cg = Instance.new("UIGradient")
	cg.Rotation = 90
	cg.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(215, 220, 235))
	cg.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 0.12),
	})
	cg.Parent = card

	local cl = Instance.new("UIListLayout")
	cl.SortOrder = Enum.SortOrder.LayoutOrder
	cl.Padding = UDim.new(0, 0)
	cl.Parent = card

	return card, wrap
end

-- Helper to add Toggle Switch Row
local ToggleUpdaters = {}

local function addToggleRow(card, order, titleStr, stateKey, colorTag, isLast)
	local row = Instance.new("TextButton")
	row.LayoutOrder = order
	row.Size = UDim2.new(1, 0, 0, 32)
	row.BackgroundTransparency = 1
	row.AutoButtonColor = false
	row.Text = ""
	row.Parent = card

	row.MouseEnter:Connect(function()
		row.BackgroundTransparency = 0.5
		row.BackgroundColor3 = THEME.RowBg
	end)
	row.MouseLeave:Connect(function()
		row.BackgroundTransparency = 1
	end)

	if colorTag then
		local tag = Instance.new("Frame")
		tag.Size = UDim2.fromOffset(8, 8)
		tag.Position = UDim2.new(0, 12, 0.5, -4)
		tag.BackgroundColor3 = colorTag
		tag.BorderSizePixel = 0
		tag.Parent = row

		local tc = Instance.new("UICorner")
		tc.CornerRadius = UDim.new(1, 0)
		tc.Parent = tag
	end

	local lbl = Instance.new("TextLabel")
	local offsetLeft = colorTag and 26 or 12
	lbl.Size = UDim2.new(1, -(offsetLeft + 42), 1, 0)
	lbl.Position = UDim2.fromOffset(offsetLeft, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = titleStr
	lbl.TextColor3 = THEME.TextPrimary
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 11
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local pill = Instance.new("Frame")
	pill.Size = UDim2.fromOffset(30, 16)
	pill.Position = UDim2.new(1, -40, 0.5, -8)
	pill.BorderSizePixel = 0
	pill.Parent = row

	local pc = Instance.new("UICorner")
	pc.CornerRadius = UDim.new(1, 0)
	pc.Parent = pill

	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(12, 12)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.Parent = pill

	local kc = Instance.new("UICorner")
	kc.CornerRadius = UDim.new(1, 0)
	kc.Parent = knob

	if not isLast then
		local div = Instance.new("Frame")
		div.Size = UDim2.new(1, -24, 0, 1)
		div.Position = UDim2.new(0, 12, 1, -1)
		div.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		div.BackgroundTransparency = 0.93
		div.BorderSizePixel = 0
		div.Parent = row
	end

	local function refresh()
		local on = State[stateKey]
		pill.BackgroundColor3 = on and THEME.Accent or THEME.ToggleOff
		TweenService:Create(knob, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = on and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
		}):Play()
	end

	table.insert(ToggleUpdaters, refresh)
	refresh()

	row.MouseButton1Click:Connect(function()
		State[stateKey] = not State[stateKey]
		if stateKey == "InstantDoor" then
			applyDoorHoldDuration()
		end
		for _, fn in ipairs(ToggleUpdaters) do
			pcall(fn)
		end
	end)
end

-- Helper to add Action Button Row
local function addActionRow(card, order, titleStr, buttonLabel, onClick, isLast)
	local row = Instance.new("TextButton")
	row.LayoutOrder = order
	row.Size = UDim2.new(1, 0, 0, 32)
	row.BackgroundTransparency = 1
	row.AutoButtonColor = false
	row.Text = ""
	row.Parent = card

	row.MouseEnter:Connect(function()
		row.BackgroundTransparency = 0.5
		row.BackgroundColor3 = THEME.RowBg
	end)
	row.MouseLeave:Connect(function()
		row.BackgroundTransparency = 1
	end)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -92, 1, 0)
	lbl.Position = UDim2.fromOffset(12, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = titleStr
	lbl.TextColor3 = THEME.TextPrimary
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 11
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(74, 20)
	btn.Position = UDim2.new(1, -84, 0.5, -10)
	btn.BackgroundColor3 = THEME.Accent
	btn.BorderSizePixel = 0
	btn.Text = buttonLabel
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 10
	btn.Parent = row

	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 5)
	bc.Parent = btn

	btn.MouseEnter:Connect(function()
		btn.BackgroundColor3 = THEME.AccentHover
	end)
	btn.MouseLeave:Connect(function()
		btn.BackgroundColor3 = THEME.Accent
	end)

	if not isLast then
		local div = Instance.new("Frame")
		div.Size = UDim2.new(1, -24, 0, 1)
		div.Position = UDim2.new(0, 12, 1, -1)
		div.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		div.BackgroundTransparency = 0.93
		div.BorderSizePixel = 0
		div.Parent = row
	end

	local function fire()
		pcall(onClick)
	end

	btn.MouseButton1Click:Connect(fire)
	row.MouseButton1Click:Connect(fire)
	return btn, lbl, row
end

-- Helper to add Read-Only Live Info Row
local function addInfoRow(card, order, titleStr, initialValue, isLast)
	local row = Instance.new("Frame")
	row.LayoutOrder = order
	row.Size = UDim2.new(1, 0, 0, 32)
	row.BackgroundTransparency = 1
	row.Parent = card

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -120, 1, 0)
	lbl.Position = UDim2.fromOffset(12, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = titleStr
	lbl.TextColor3 = THEME.TextPrimary
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 12
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local valLbl = Instance.new("TextLabel")
	valLbl.Size = UDim2.fromOffset(104, 20)
	valLbl.Position = UDim2.new(1, -114, 0.5, -10)
	valLbl.BackgroundColor3 = THEME.RowBg
	valLbl.BackgroundTransparency = 0.4
	valLbl.BorderSizePixel = 0
	valLbl.Text = initialValue or "—"
	valLbl.TextColor3 = THEME.Accent
	valLbl.Font = Enum.Font.GothamBold
	valLbl.TextSize = 10
	valLbl.Parent = row

	local vc = Instance.new("UICorner")
	vc.CornerRadius = UDim.new(0, 5)
	vc.Parent = valLbl

	local vs = Instance.new("UIStroke")
	vs.Color = Color3.fromRGB(255, 255, 255)
	vs.Thickness = 1
	vs.Transparency = 0.88
	vs.Parent = valLbl

	if not isLast then
		local div = Instance.new("Frame")
		div.Size = UDim2.new(1, -24, 0, 1)
		div.Position = UDim2.new(0, 12, 1, -1)
		div.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		div.BackgroundTransparency = 0.93
		div.BorderSizePixel = 0
		div.Parent = row
	end

	return valLbl
end

-- ==============================================================================
-- TAB 1: DASHBOARD (Clean 2-Column: Utilities & Live Status Cockpit - NO TELEPORTS)
-- ==============================================================================

local DashboardPage = Instance.new("Frame")
DashboardPage.Name = "DashboardPage"
DashboardPage.Size = UDim2.fromScale(1, 1)
DashboardPage.BackgroundTransparency = 1
DashboardPage.Parent = PagesArea

local DashLeftCol = Instance.new("ScrollingFrame")
DashLeftCol.Size = UDim2.new(0.5, -6, 1, 0)
DashLeftCol.Position = UDim2.fromScale(0, 0)
DashLeftCol.BackgroundTransparency = 1
DashLeftCol.BorderSizePixel = 0
DashLeftCol.ScrollBarThickness = 2
DashLeftCol.ScrollBarImageColor3 = THEME.Accent
DashLeftCol.ScrollBarImageTransparency = 0.5
DashLeftCol.AutomaticCanvasSize = Enum.AutomaticSize.Y
DashLeftCol.CanvasSize = UDim2.fromScale(0, 0)
DashLeftCol.Parent = DashboardPage

local DashLeftLayout = Instance.new("UIListLayout")
DashLeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
DashLeftLayout.Padding = UDim.new(0, 10)
DashLeftLayout.Parent = DashLeftCol

local DashRightCol = Instance.new("ScrollingFrame")
DashRightCol.Size = UDim2.new(0.5, -6, 1, 0)
DashRightCol.Position = UDim2.new(0.5, 6, 0, 0)
DashRightCol.BackgroundTransparency = 1
DashRightCol.BorderSizePixel = 0
DashRightCol.ScrollBarThickness = 2
DashRightCol.ScrollBarImageColor3 = THEME.Accent
DashRightCol.ScrollBarImageTransparency = 0.5
DashRightCol.AutomaticCanvasSize = Enum.AutomaticSize.Y
DashRightCol.CanvasSize = UDim2.fromScale(0, 0)
DashRightCol.Parent = DashboardPage

local DashRightLayout = Instance.new("UIListLayout")
DashRightLayout.SortOrder = Enum.SortOrder.LayoutOrder
DashRightLayout.Padding = UDim.new(0, 10)
DashRightLayout.Parent = DashRightCol

-- Column 1: EVENT UTILITIES & AUTOMATION
local UtilitiesCard = createGroupCard(DashLeftCol, 1, "Event Utilities & Automation")
addToggleRow(UtilitiesCard, 1, "Instant Door (0s Hold)", "InstantDoor", THEME.Accent, false)
addToggleRow(UtilitiesCard, 2, "Candy Magnet (Vacuum) (TESTING)", "CandyMagnet", THEME.Accent, false)
addToggleRow(UtilitiesCard, 3, "Auto Candy Sweep", "AutoSweep", THEME.Accent, false)
addToggleRow(UtilitiesCard, 4, "Baby Halloween HP to 1 (TESTING)", "BabyHp1", THEME.Accent, false)
addToggleRow(UtilitiesCard, 5, "Show ESP Names (Labels)", "ShowNames", THEME.Accent, false)
addActionRow(UtilitiesCard, 6, "Sweep Nearby Candies", "[SWEEP]", sweepCandies, true)

-- Column 2: LIVE EVENT OVERVIEW & STATUS HUD (Dashboard Live Cockpit)
local StatusOverviewCard = createGroupCard(DashRightCol, 1, "Live Event Overview & Status")
local DashCandiesVal = addInfoRow(StatusOverviewCard, 1, "Active Candies (Nearby)", "0 Drops", false)
local DashDoorsVal = addInfoRow(StatusOverviewCard, 2, "Halloween Doors Ready", "0 / 0", false)
local DashBabyVal = addInfoRow(StatusOverviewCard, 3, "Halloween Baby Status", "SEARCHING", false)
local DashCansVal = addInfoRow(StatusOverviewCard, 4, "Intact Trash Cans", "0", false)
local DashDoorStatusVal = addInfoRow(StatusOverviewCard, 5, "Instant Door Bypass", "DEFAULT", false)
addActionRow(StatusOverviewCard, 6, "Manual Candy Sweep", "[SWEEP NOW]", sweepCandies, true)

-- ==============================================================================
-- TAB 2: DEDICATED TELEPORTS PAGE (Boss Targets, World TP & Live Doors TP List)
-- ==============================================================================

local TeleportsPage = Instance.new("Frame")
TeleportsPage.Name = "TeleportsPage"
TeleportsPage.Size = UDim2.fromScale(1, 1)
TeleportsPage.BackgroundTransparency = 1
TeleportsPage.Visible = false
TeleportsPage.Parent = PagesArea

local TpLeftCol = Instance.new("ScrollingFrame")
TpLeftCol.Size = UDim2.new(0.48, -4, 1, 0)
TpLeftCol.Position = UDim2.fromScale(0, 0)
TpLeftCol.BackgroundTransparency = 1
TpLeftCol.BorderSizePixel = 0
TpLeftCol.ScrollBarThickness = 2
TpLeftCol.ScrollBarImageColor3 = THEME.Accent
TpLeftCol.ScrollBarImageTransparency = 0.5
TpLeftCol.AutomaticCanvasSize = Enum.AutomaticSize.Y
TpLeftCol.CanvasSize = UDim2.fromScale(0, 0)
TpLeftCol.Parent = TeleportsPage

local TpLeftLayout = Instance.new("UIListLayout")
TpLeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
TpLeftLayout.Padding = UDim.new(0, 10)
TpLeftLayout.Parent = TpLeftCol

local TpRightCol = Instance.new("Frame")
TpRightCol.Size = UDim2.new(0.52, -4, 1, 0)
TpRightCol.Position = UDim2.new(0.48, 8, 0, 0)
TpRightCol.BackgroundTransparency = 1
TpRightCol.Parent = TeleportsPage

local TpRightLayout = Instance.new("UIListLayout")
TpRightLayout.SortOrder = Enum.SortOrder.LayoutOrder
TpRightLayout.Padding = UDim.new(0, 8)
TpRightLayout.Parent = TpRightCol

-- Column 1: EVENT TARGETS & WORLD TELEPORTS
local BossTpCard = createGroupCard(TpLeftCol, 1, "Event & Boss Targets")
addActionRow(BossTpCard, 1, "Halloween Baby (Penyta)", "[TP BABY]", teleportToBaby, false)
addActionRow(BossTpCard, 2, "Set Baby HP to 1 (TESTING)", "[SET 1 HP]", setBabyHpToOne, false)
addActionRow(BossTpCard, 3, "Candy Merchant (Cart Shop)", "[SHOP TP]", teleportToMerchant, false)
addActionRow(BossTpCard, 4, "Sweep Nearby Candies", "[SWEEP]", sweepCandies, true)

local WorldTpCard = createGroupCard(TpLeftCol, 2, "World Interactive Teleports")
addActionRow(WorldTpCard, 1, "Nearest Ready Halloween Door", "[DOOR TP]", function()
	local doors = getSortedDoors(true)
	if #doors == 0 then doors = getSortedDoors(false) end
	if doors[1] then teleportToDoor(doors[1].Model) end
end, false)
addActionRow(WorldTpCard, 2, "Cycle Next Ready Door", "[NEXT]", function()
	local doors = getSortedDoors(true)
	if #doors == 0 then doors = getSortedDoors(false) end
	if #doors > 0 then
		table.sort(doors, function(a, b) return a.Index < b.Index end)
		CycleDoorIndex = (CycleDoorIndex % #doors) + 1
		teleportToDoor(doors[CycleDoorIndex].Model)
	end
end, false)
addActionRow(WorldTpCard, 3, "Nearest Intact Trash Can", "[CAN TP]", function()
	local cans = getSortedTrashCans(true)
	if #cans == 0 then cans = getSortedTrashCans(false) end
	if cans[1] then teleportToTrashCan(cans[1].Model) end
end, false)
addActionRow(WorldTpCard, 4, "Cycle Next Trash Can", "[NEXT CAN]", function()
	local cans = getSortedTrashCans(true)
	if #cans == 0 then cans = getSortedTrashCans(false) end
	if #cans > 0 then
		CycleCanIndex = (CycleCanIndex % #cans) + 1
		teleportToTrashCan(cans[CycleCanIndex].Model)
	end
end, true)

-- Column 2: LIVE DOORS DIRECT TP (Full Height Clean Scroll)
local DoorsWrap = Instance.new("Frame")
DoorsWrap.LayoutOrder = 1
DoorsWrap.Size = UDim2.new(1, 0, 1, 0)
DoorsWrap.BackgroundTransparency = 1
DoorsWrap.Parent = TpRightCol

local DoorsHdr = Instance.new("TextLabel")
DoorsHdr.Size = UDim2.new(1, 0, 0, 18)
DoorsHdr.Position = UDim2.fromOffset(2, 0)
DoorsHdr.BackgroundTransparency = 1
DoorsHdr.Text = "LIVE DOORS DIRECT TP"
DoorsHdr.TextColor3 = THEME.TextSecondary
DoorsHdr.Font = Enum.Font.GothamBold
DoorsHdr.TextSize = 11
DoorsHdr.TextXAlignment = Enum.TextXAlignment.Left
DoorsHdr.Parent = DoorsWrap

local DoorsBox = Instance.new("Frame")
DoorsBox.Size = UDim2.new(1, 0, 1, -22)
DoorsBox.Position = UDim2.fromOffset(0, 20)
DoorsBox.BackgroundColor3 = THEME.CardBg
DoorsBox.BackgroundTransparency = 0.35
DoorsBox.BorderSizePixel = 0
DoorsBox.ClipsDescendants = true
DoorsBox.Parent = DoorsWrap

local DbCorner = Instance.new("UICorner")
DbCorner.CornerRadius = UDim.new(0, 8)
DbCorner.Parent = DoorsBox

local DbStroke = Instance.new("UIStroke")
DbStroke.Color = Color3.fromRGB(255, 255, 255)
DbStroke.Thickness = 1
DbStroke.Transparency = 0.88
DbStroke.Parent = DoorsBox

local DoorScroll = Instance.new("ScrollingFrame")
DoorScroll.Size = UDim2.new(1, -4, 1, -6)
DoorScroll.Position = UDim2.fromOffset(2, 3)
DoorScroll.BackgroundTransparency = 1
DoorScroll.BorderSizePixel = 0
DoorScroll.ScrollBarThickness = 3
DoorScroll.ScrollBarImageColor3 = THEME.Accent
DoorScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
DoorScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
DoorScroll.Parent = DoorsBox

local DoorScrollLayout = Instance.new("UIListLayout")
DoorScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
DoorScrollLayout.Padding = UDim.new(0, 0)
DoorScrollLayout.Parent = DoorScroll

-- ==============================================================================
-- TAB 3: VISUALS ESP PAGE (Entity & World ESP Toggles + Chams/Names)
-- ==============================================================================

local VisualsPage = Instance.new("ScrollingFrame")
VisualsPage.Name = "VisualsPage"
VisualsPage.Size = UDim2.fromScale(1, 1)
VisualsPage.BackgroundTransparency = 1
VisualsPage.BorderSizePixel = 0
VisualsPage.ScrollBarThickness = 2
VisualsPage.ScrollBarImageColor3 = THEME.Accent
VisualsPage.ScrollBarImageTransparency = 0.5
VisualsPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
VisualsPage.CanvasSize = UDim2.fromScale(0, 0)
VisualsPage.Visible = false
VisualsPage.Parent = PagesArea

local VisualsLayout = Instance.new("UIListLayout")
VisualsLayout.SortOrder = Enum.SortOrder.LayoutOrder
VisualsLayout.Padding = UDim.new(0, 10)
VisualsLayout.Parent = VisualsPage

local VisEntitiesCard = createGroupCard(VisualsPage, 1, "Entity ESP (NPCs & Players)")
addToggleRow(VisEntitiesCard, 1, "Halloween Baby (Penyta)", "HalloweenBaby", ESP_COLORS.Baby, false)
addToggleRow(VisEntitiesCard, 2, "Trash Monster (TrashGuy)", "TrashMonster", ESP_COLORS.TrashMonster, false)
addToggleRow(VisEntitiesCard, 3, "Halloween Zombies (Mob)", "HalloweenZombies", ESP_COLORS.Zombie, false)
addToggleRow(VisEntitiesCard, 4, "Other Players (All Characters)", "PlayerESP", ESP_COLORS.Player, true)

local VisWorldCard = createGroupCard(VisualsPage, 2, "World ESP & Highlights")
addToggleRow(VisWorldCard, 1, "Halloween Door Trees", "HalloweenDoors", ESP_COLORS.DoorReady, false)
addToggleRow(VisWorldCard, 2, "Trash Cans (Hiding Spots)", "TrashCans", ESP_COLORS.TrashCan, false)
addToggleRow(VisWorldCard, 3, "Filter Broken / Empty Cans", "HideBrokenCans", ESP_COLORS.TrashBroken, false)
addToggleRow(VisWorldCard, 4, "Render Distance Tag", "ShowDistance", THEME.Accent, false)
addToggleRow(VisWorldCard, 5, "Show ESP Names (Text Tags)", "ShowNames", THEME.Accent, false)
addToggleRow(VisWorldCard, 6, "3D Outline Colors (Chams)", "ShowHighlight", THEME.Accent, true)

-- ==============================================================================
-- TAB 4: SETTINGS PAGE
-- ==============================================================================

local SettingsPage = Instance.new("ScrollingFrame")
SettingsPage.Name = "SettingsPage"
SettingsPage.Size = UDim2.fromScale(1, 1)
SettingsPage.BackgroundTransparency = 1
SettingsPage.BorderSizePixel = 0
SettingsPage.ScrollBarThickness = 2
SettingsPage.ScrollBarImageColor3 = THEME.Accent
SettingsPage.ScrollBarImageTransparency = 0.5
SettingsPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
SettingsPage.CanvasSize = UDim2.fromScale(0, 0)
SettingsPage.Visible = false
SettingsPage.Parent = PagesArea

local SetLayout = Instance.new("UIListLayout")
SetLayout.SortOrder = Enum.SortOrder.LayoutOrder
SetLayout.Padding = UDim.new(0, 10)
SetLayout.Parent = SettingsPage

local SetCard = createGroupCard(SettingsPage, 1, "ESP & Display Configuration")
local scaleBtn = addActionRow(SetCard, 1, "ESP Text Scale", "SCALE: " .. math.floor(State.TextScale * 100) .. "%", function()
	if State.TextScale == 1 then
		State.TextScale = 1.2
	elseif State.TextScale == 1.2 then
		State.TextScale = 0.85
	else
		State.TextScale = 1
	end
	if scaleBtn then
		scaleBtn.Text = "SCALE: " .. math.floor(State.TextScale * 100) .. "%"
	end
end, false)

local distBtn = addActionRow(SetCard, 2, "Maximum Render Distance", State.MaxDistance .. "m", function()
	if State.MaxDistance == 2500 then
		State.MaxDistance = 1500
	elseif State.MaxDistance == 1500 then
		State.MaxDistance = 500
	else
		State.MaxDistance = 2500
	end
	if distBtn then
		distBtn.Text = State.MaxDistance .. "m"
	end
end, false)

addActionRow(SetCard, 3, "Toggle Keybind", "[RightShift]", function() end, true)

local AutoCard = createGroupCard(SettingsPage, 2, "Event Automation Preferences")
addToggleRow(AutoCard, 1, "Instant Door (0s Hold)", "InstantDoor", THEME.Accent, false)
addToggleRow(AutoCard, 2, "Candy Magnet (Vacuum) (TESTING)", "CandyMagnet", THEME.Accent, false)
addToggleRow(AutoCard, 3, "Auto Candy Sweep", "AutoSweep", THEME.Accent, false)
addToggleRow(AutoCard, 4, "Auto Set Baby HP to 1 (TESTING)", "BabyHp1", THEME.Accent, true)

local SystemCard = createGroupCard(SettingsPage, 3, "Hub System & Lifecycle")
addActionRow(SystemCard, 1, "Hub Version", "v2.5 PRO", function() end, false)
addActionRow(SystemCard, 2, "Unload Hub", "[UNLOAD]", function()
	if _G.TSBHalloweenESP and type(_G.TSBHalloweenESP.Destroy) == "function" then
		_G.TSBHalloweenESP.Destroy()
	end
end, true)

-- Tab Switch Handler
SwitchTab = function(tabKey)
	State.ActiveTab = tabKey
	TabBadgeText.Text = string.upper(tabKey)

	DashboardPage.Visible = (tabKey == "Dashboard")
	TeleportsPage.Visible = (tabKey == "Teleports")
	VisualsPage.Visible = (tabKey == "Visuals")
	SettingsPage.Visible = (tabKey == "Settings")

	for _, t in ipairs(NavTabs) do
		local active = (t.Key == tabKey)
		t.Button.BackgroundColor3 = active and THEME.CardBg or THEME.SidebarBg
		t.Button.BackgroundTransparency = active and 0.25 or 1
		if t.IconImg then
			t.IconImg.ImageColor3 = active and THEME.Accent or THEME.TextMuted
		end
		if t.IconTxt then
			t.IconTxt.TextColor3 = active and THEME.Accent or THEME.TextMuted
		end
		t.Text.TextColor3 = active and THEME.TextPrimary or THEME.TextSecondary
		t.Text.Font = active and Enum.Font.GothamBold or Enum.Font.GothamMedium
		if t.Pill then
			t.Pill.Visible = active
		end
	end
end

SwitchTab("Dashboard")

-- Door Teleport Row Pool
local DoorRows = {}

local function ensureDoorRow(doorModel)
	if DoorRows[doorModel] then return DoorRows[doorModel] end

	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 26)
	row.BackgroundColor3 = THEME.CardBg
	row.BackgroundTransparency = 0.4
	row.BorderSizePixel = 0
	row.Parent = DoorScroll

	local dot = Instance.new("Frame")
	dot.Size = UDim2.fromOffset(6, 6)
	dot.Position = UDim2.new(0, 10, 0.5, -3)
	dot.BackgroundColor3 = THEME.Accent
	dot.BorderSizePixel = 0
	dot.Parent = row

	local dc = Instance.new("UICorner")
	dc.CornerRadius = UDim.new(1, 0)
	dc.Parent = dot

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -76, 1, 0)
	lbl.Position = UDim2.fromOffset(22, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 11
	lbl.TextColor3 = THEME.TextPrimary
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = "Door #1"
	lbl.Parent = row

	local tpBtn = Instance.new("TextButton")
	tpBtn.Size = UDim2.fromOffset(42, 18)
	tpBtn.Position = UDim2.new(1, -48, 0.5, -9)
	tpBtn.BackgroundColor3 = THEME.Accent
	tpBtn.BorderSizePixel = 0
	tpBtn.Font = Enum.Font.GothamBold
	tpBtn.TextSize = 10
	tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	tpBtn.Text = "TP"
	tpBtn.Parent = row

	local tc = Instance.new("UICorner")
	tc.CornerRadius = UDim.new(0, 4)
	tc.Parent = tpBtn

	local div = Instance.new("Frame")
	div.Size = UDim2.new(1, -20, 0, 1)
	div.Position = UDim2.new(0, 10, 1, -1)
	div.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	div.BackgroundTransparency = 0.93
	div.BorderSizePixel = 0
	div.Parent = row

	tpBtn.MouseButton1Click:Connect(function()
		teleportToDoor(doorModel)
	end)

	local item = { Row = row, Dot = dot, Label = lbl, Btn = tpBtn }
	DoorRows[doorModel] = item
	return item
end

-- ==============================================================================
-- DRAG & MINIMIZE SUPPORT
-- ==============================================================================

do
	local dragging = false
	local dragInput, dragStart, startPos

	local function update(input)
		local delta = input.Position - dragStart
		MainWindow.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end

	local function bindDrag(frame)
		frame.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = MainWindow.Position

				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)

		frame.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				dragInput = input
			end
		end)
	end

	bindDrag(BrandHeader)
	bindDrag(TopBar)

	table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end))

	table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
end

local minimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	PagesArea.Visible = not minimized
	NavList.Visible = not minimized
	UserBox.Visible = not minimized
	MainWindow.Size = minimized and UDim2.fromOffset(WINDOW_WIDTH, 52) or UDim2.fromOffset(WINDOW_WIDTH, WINDOW_HEIGHT)
	MinimizeBtn.Text = minimized and "+" or "—"
end)

table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gp)
	if not gp and input.KeyCode == Enum.KeyCode.RightShift then
		ScreenGui.Enabled = not ScreenGui.Enabled
	end
end))

-- ==============================================================================
-- ESP ENGINE (Bracket Tags & 3D Color Chams with Names Toggle)
-- ==============================================================================

local function createEspEntry(rootInstance, objType, adorneePart, highlightTarget)
	if TrackedObjects[rootInstance] then
		return TrackedObjects[rootInstance]
	end

	local bb = Instance.new("BillboardGui")
	bb.Name = "ESP_Billboard"
	bb.Adornee = adorneePart
	bb.AlwaysOnTop = true
	bb.Size = UDim2.fromOffset(250, 36)
	local yOffset = 2.5
	if objType == "Player" then
		yOffset = 3.4
	elseif objType == "Door" then
		yOffset = 3.6
	elseif objType == "TrashCan" then
		yOffset = 1.8
	elseif objType == "Zombie" then
		yOffset = 3.0
	end
	bb.StudsOffset = Vector3.new(0, yOffset, 0)
	bb.Enabled = false
	bb.Parent = EspFolder

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextSize = 11
	textLabel.TextStrokeTransparency = 0.15
	textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.Text = ""
	textLabel.Parent = bb

	local hl = Instance.new("Highlight")
	hl.Name = "ESP_Highlight"
	hl.Adornee = highlightTarget or rootInstance
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.FillTransparency = 0.55
	hl.OutlineTransparency = 0
	hl.Enabled = false
	hl.Parent = HighlightFolder

	local entry = {
		Root = rootInstance,
		Type = objType,
		Adornee = adorneePart,
		Billboard = bb,
		Label = textLabel,
		Highlight = hl,
		LastDist = 99999,
		Priority = 3,
	}
	TrackedObjects[rootInstance] = entry
	return entry
end

local function removeEspEntry(rootInstance)
	local entry = TrackedObjects[rootInstance]
	if entry then
		if entry.Billboard then pcall(function() entry.Billboard:Destroy() end) end
		if entry.Highlight then pcall(function() entry.Highlight:Destroy() end) end
		TrackedObjects[rootInstance] = nil
	end
	local rowItem = DoorRows[rootInstance]
	if rowItem then
		if rowItem.Row then pcall(function() rowItem.Row:Destroy() end) end
		DoorRows[rootInstance] = nil
	end
end

local function scanHalloweenDoors()
	local folder = workspace:FindFirstChild("HalloweenDoorTrees")
	if not folder then return end
	local duration = State.InstantDoor and 0 or 3.5
	for _, doorTree in ipairs(folder:GetChildren()) do
		local prompt = doorTree:FindFirstChild("TrickOrTreat", true)
		if prompt then
			pcall(function() prompt.HoldDuration = duration end)
		end
		if not TrackedObjects[doorTree] and doorTree:IsA("Model") then
			local frame = doorTree:FindFirstChild("Frame", true)
				or doorTree:FindFirstChild("Backing", true)
				or doorTree:FindFirstChildWhichIsA("BasePart", true)
			local doorModel = doorTree:FindFirstChild("DOOR 1 NEW") or doorTree
			if frame then
				createEspEntry(doorTree, "Door", frame, doorModel)
				ensureDoorRow(doorTree)
			end
		end
	end
end

local function scanTrashCans()
	local map = workspace:FindFirstChild("Map")
	local trashFolder = map and map:FindFirstChild("Trash")
	if not trashFolder then return end
	for _, can in ipairs(trashFolder:GetChildren()) do
		if not TrackedObjects[can] and can:IsA("Model") then
			local part = can:FindFirstChild("Trashcan") or can:FindFirstChildWhichIsA("BasePart", true)
			if part then
				createEspEntry(can, "TrashCan", part, can)
			end
		end
	end
end

local function scanLiveNPCs()
	local live = workspace:FindFirstChild("Live")
	if not live then return end
	for _, model in ipairs(live:GetChildren()) do
		if not TrackedObjects[model] and model:IsA("Model") and not Players:GetPlayerFromCharacter(model) then
			local isTrashGuy = (model.Name == "TrashGuy") or (model:GetAttribute("TrashGuy") == true)
			local isBaby = (model.Name == "Penyta") or (model:GetAttribute("Pinata") == true and not isTrashGuy)
			local isZombie = (model.Name == "Halloween Zombie") or (model:GetAttribute("HalloweenZombie") == true)

			if isBaby then
				local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart", true)
				if root then
					createEspEntry(model, "Baby", root, model)
				end
			elseif isTrashGuy then
				local root = model:FindFirstChild("HumanoidRootPart")
					or (model:FindFirstChild("Limbs") and model.Limbs:FindFirstChild("RootPart"))
					or model:FindFirstChildWhichIsA("BasePart", true)
				if root then
					createEspEntry(model, "TrashMonster", root, model)
				end
			elseif isZombie then
				local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart", true)
				if root then
					createEspEntry(model, "Zombie", root, model)
				end
			end
		end
	end
end

local function scanPlayers()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local char = plr.Character
			local hrp = char:FindFirstChild("HumanoidRootPart")
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hrp and hum and hum.Health > 0 and not TrackedObjects[char] then
				createEspEntry(char, "Player", hrp, char)
			end
		end
	end
end

scanHalloweenDoors()
scanTrashCans()
scanLiveNPCs()
scanPlayers()

-- Listen to character respawns for all players
for _, plr in ipairs(Players:GetPlayers()) do
	if plr ~= LocalPlayer then
		table.insert(Connections, plr.CharacterAdded:Connect(function()
			task.wait(0.5)
			scanPlayers()
		end))
	end
end

table.insert(Connections, Players.PlayerAdded:Connect(function(plr)
	table.insert(Connections, plr.CharacterAdded:Connect(function()
		task.wait(0.5)
		scanPlayers()
	end))
end))

local lastScan = 0
local function getPlayerPosition()
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then return hrp.Position end
	local cam = workspace.CurrentCamera
	return cam and cam.CFrame.Position or Vector3.zero
end

table.insert(Connections, RunService.RenderStepped:Connect(function()
	if not State.Running then return end

	local now = os.clock()
	if now - lastScan >= 0.5 then
		lastScan = now
		scanHalloweenDoors()
		scanTrashCans()
		scanLiveNPCs()
		scanPlayers()
	end

	local myPos = getPlayerPosition()
	local playerCount, babyCount, doorCount, canCount = 0, 0, 0, 0
	local highlightCandidates = {}
	local doorSortList = {}

	for root, entry in pairs(TrackedObjects) do
		if not root or not root.Parent or not entry.Adornee or not entry.Adornee.Parent then
			removeEspEntry(root)
		else
			local pos = entry.Adornee.Position
			local dist = math.floor((pos - myPos).Magnitude + 0.5)
			entry.LastDist = dist
			local distStr = State.ShowDistance and string.format(" [%dm]", dist) or ""

			local show = false
			local color = Color3.new(1, 1, 1)
			local label = ""
			local priority = 3

			if entry.Type == "Baby" then
				local hp = tonumber(root:GetAttribute("PinataHP"))
				local maxHp = tonumber(root:GetAttribute("PinataMax")) or 200
				local alive = (hp == nil) or (hp > 0)
				if alive then babyCount += 1 end
				if State.HalloweenBaby and alive and dist <= State.MaxDistance then
					show = true
					priority = 1
					color = ESP_COLORS.Baby
					local hpText = hp and string.format(" (%d/%d HP)", math.ceil(hp), maxHp) or ""
					label = "[BABY] Penyta" .. hpText .. distStr
				end

			elseif entry.Type == "TrashMonster" then
				local hp = tonumber(root:GetAttribute("TrashGuyHP"))
				local alive = (hp == nil) or (hp > 0)
				if alive then babyCount += 1 end
				if (State.TrashMonster or State.HalloweenBaby) and alive and dist <= State.MaxDistance then
					show = true
					priority = 1
					color = ESP_COLORS.TrashMonster
					local hpText = hp and string.format(" (%d HP)", math.ceil(hp)) or ""
					label = "[MONSTER] TrashGuy" .. hpText .. distStr
				end

			elseif entry.Type == "Player" then
				local hum = root:FindFirstChildOfClass("Humanoid")
				local plr = Players:GetPlayerFromCharacter(root)
				local alive = hum and (hum.Health > 0)
				if alive then playerCount += 1 end
				if State.PlayerESP and alive and dist <= State.MaxDistance then
					show = true
					priority = 1
					color = ESP_COLORS.Player
					local hpVal = math.ceil(hum.Health)
					local maxHpVal = math.ceil(hum.MaxHealth)
					local nameStr = plr and (plr.DisplayName .. " (@" .. plr.Name .. ")") or root.Name
					label = string.format("[PLAYER] %s (%d/%d HP)%s", nameStr, hpVal, maxHpVal, distStr)
				end

			elseif entry.Type == "Zombie" then
				local hum = root:FindFirstChildOfClass("Humanoid")
				local dead = (root:GetAttribute("KillRegged") == true) or (hum and hum.Health <= 0)
				if State.HalloweenZombies and not dead and dist <= State.MaxDistance then
					show = true
					priority = 1
					color = ESP_COLORS.Zombie
					local hpText = hum and string.format(" (%d HP)", math.ceil(hum.Health)) or ""
					label = "[ZOMBIE] Halloween" .. hpText .. distStr
				end

			elseif entry.Type == "Door" then
				local prompt = root:FindFirstChild("TrickOrTreat", true)
				local isOpen = not prompt or (prompt:GetAttribute("Open") ~= false)
				if isOpen then doorCount += 1 end
				if State.HalloweenDoors and dist <= State.MaxDistance then
					show = true
					priority = 2
					color = isOpen and ESP_COLORS.DoorReady or ESP_COLORS.DoorBusy
					local stateTag = isOpen and " [READY]" or " [BUSY]"
					label = "[DOOR]" .. stateTag .. distStr
				end

				table.insert(doorSortList, {
					Root = root,
					Ready = isOpen,
					Dist = dist,
				})

			elseif entry.Type == "TrashCan" then
				local broken = (root:GetAttribute("Broken") == true)
					or (entry.Adornee.Transparency >= 0.5)
					or (not entry.Adornee.CanCollide)
				local prompt = root:FindFirstChild("HideInCan", true)
				local occupied = prompt and (prompt:GetAttribute("Open") == false)

				if not broken then canCount += 1 end

				if State.TrashCans and dist <= State.MaxDistance and (not broken or not State.HideBrokenCans) then
					show = true
					if broken then
						priority = 4
						color = ESP_COLORS.TrashBroken
						label = "[TRASH: BROKEN]" .. distStr
					elseif occupied then
						priority = 1
						color = ESP_COLORS.TrashOccupied
						label = "[TRASH: OCCUPIED]" .. distStr
					else
						priority = 3
						color = ESP_COLORS.TrashCan
						label = "[TRASH CAN]" .. distStr
					end
				end
			end

			entry.Priority = priority

			-- Name & Color separation: if ShowNames is false, leave only the colors around parts!
			if show then
				if State.ShowNames then
					entry.Billboard.Enabled = true
					entry.Label.TextSize = math.floor(11 * State.TextScale)
					entry.Label.Text = label
					entry.Label.TextColor3 = color
				else
					entry.Billboard.Enabled = false
				end

				if State.ShowHighlight then
					entry.Highlight.FillColor = color
					entry.Highlight.OutlineColor = color
					table.insert(highlightCandidates, entry)
				else
					entry.Highlight.Enabled = false
				end
			else
				entry.Billboard.Enabled = false
				entry.Highlight.Enabled = false
			end
		end
	end

	-- Update Door Rows
	table.sort(doorSortList, function(a, b)
		if a.Ready ~= b.Ready then return a.Ready end
		return a.Dist < b.Dist
	end)

	for orderIdx, info in ipairs(doorSortList) do
		local rowItem = ensureDoorRow(info.Root)
		if rowItem and rowItem.Row then
			rowItem.Row.LayoutOrder = orderIdx
			local tag = info.Ready and "READY" or "BUSY"
			rowItem.Label.Text = string.format("Door #%d [%s] — %dm", orderIdx, tag, info.Dist)
			rowItem.Dot.BackgroundColor3 = info.Ready and THEME.StatusOrange or THEME.StatusPurple
			rowItem.Btn.BackgroundColor3 = info.Ready and THEME.Accent or THEME.ToggleOff
		end
	end

	-- Highlight cap limit (Up to 31 native highlights in Workspace)
	if State.ShowHighlight and #highlightCandidates > 0 then
		table.sort(highlightCandidates, function(a, b)
			if a.Priority ~= b.Priority then return a.Priority < b.Priority end
			return a.LastDist < b.LastDist
		end)
		for i, entry in ipairs(highlightCandidates) do
			if i <= 31 then
				entry.Highlight.Parent = HighlightFolder
				entry.Highlight.Enabled = true
			else
				entry.Highlight.Enabled = false
			end
		end
	end

	StatusLabel.Text = string.format("PLR: %d  |  BABY: %d  |  DOORS: %d  |  CANS: %d", playerCount, babyCount, doorCount, canCount)

	if DashCandiesVal then
		local candies = getNearbyCandies(250)
		DashCandiesVal.Text = string.format("%d Drops", #candies)
		DashCandiesVal.TextColor3 = (#candies > 0) and THEME.StatusGreen or THEME.TextMuted
	end
	if DashDoorsVal then
		local readyCount = 0
		for _, d in ipairs(doorSortList) do
			if d.Ready then readyCount = readyCount + 1 end
		end
		DashDoorsVal.Text = string.format("%d / %d Ready", readyCount, #doorSortList)
		DashDoorsVal.TextColor3 = (readyCount > 0) and THEME.StatusOrange or THEME.TextMuted
	end
	if DashBabyVal then
		local babyModel, hum = getBabyModel()
		if babyModel and hum then
			DashBabyVal.Text = string.format("HP: %d", math.floor(hum.Health))
			DashBabyVal.TextColor3 = THEME.StatusGreen
		elseif babyModel then
			DashBabyVal.Text = "SPAWNED"
			DashBabyVal.TextColor3 = THEME.StatusOrange
		else
			DashBabyVal.Text = "NOT ACTIVE"
			DashBabyVal.TextColor3 = THEME.TextMuted
		end
	end
	if DashCansVal then
		DashCansVal.Text = string.format("%d Available", canCount)
	end
	if DashDoorStatusVal then
		DashDoorStatusVal.Text = State.InstantDoor and "ACTIVE (0s)" or "OFF"
		DashDoorStatusVal.TextColor3 = State.InstantDoor and THEME.Accent or THEME.TextMuted
	end
end))

local function cleanup()
	State.Running = false
	for _, conn in ipairs(Connections) do
		pcall(function() conn:Disconnect() end)
	end
	table.clear(Connections)
	for root in pairs(TrackedObjects) do
		removeEspEntry(root)
	end
	if EspFolder then
		pcall(function() EspFolder:Destroy() end)
	end
	if HighlightFolder then
		pcall(function() HighlightFolder:Destroy() end)
	end
	if ScreenGui then
		pcall(function() ScreenGui:Destroy() end)
	end
end

CloseBtn.MouseButton1Click:Connect(cleanup)

_G.TSBHalloweenESP = {
	Destroy = cleanup,
	State = State,
	TeleportToDoor = teleportToDoor,
	TeleportToBaby = teleportToBaby,
	SetBabyHpToOne = setBabyHpToOne,
	SweepCandies = sweepCandies,
	TeleportToTrashCan = teleportToTrashCan,
	TeleportToMerchant = teleportToMerchant,
}
