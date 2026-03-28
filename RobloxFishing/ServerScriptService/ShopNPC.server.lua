-- ============================================================
-- ShopNPC.lua  (Script in ServerScriptService)
-- Spawns a simple shop-keeper NPC near the water.
-- Players press [E] to open the upgrade shop UI.
-- Move the model in Studio or change SHOP_POSITION to reposition.
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes           = require(ReplicatedStorage:WaitForChild("FishingRemotes"))

-- ── Position of the shop NPC (adjust to fit your map) ────────
local SHOP_POSITION = Vector3.new(10, 5, 15)

-- ── Build the NPC model ───────────────────────────────────────
local model = Instance.new("Model")
model.Name  = "ShopKeeper"

-- Body (torso)
local torso = Instance.new("Part")
torso.Name        = "HumanoidRootPart"
torso.Size        = Vector3.new(2, 2.5, 1)
torso.BrickColor  = BrickColor.new("Bright blue")
torso.Material    = Enum.Material.SmoothPlastic
torso.Anchored    = true
torso.CanCollide  = true
torso.CastShadow  = false
torso.Position    = SHOP_POSITION
torso.Parent      = model

-- Head
local head = Instance.new("Part")
head.Name        = "Head"
head.Size        = Vector3.new(1.4, 1.4, 1.4)
head.Shape       = Enum.PartType.Ball
head.BrickColor  = BrickColor.new("Pastel yellow")
head.Material    = Enum.Material.SmoothPlastic
head.Anchored    = true
head.CanCollide  = false
head.CastShadow  = false
head.Position    = SHOP_POSITION + Vector3.new(0, 2.0, 0)
head.Parent      = model

-- Hat (a flat cylinder)
local hat = Instance.new("Part")
hat.Name        = "Hat"
hat.Size        = Vector3.new(1.8, 0.3, 1.8)
hat.Shape       = Enum.PartType.Cylinder
hat.BrickColor  = BrickColor.new("Reddish brown")
hat.Material    = Enum.Material.SmoothPlastic
hat.Anchored    = true
hat.CanCollide  = false
hat.CastShadow  = false
hat.Position    = SHOP_POSITION + Vector3.new(0, 3.0, 0)
hat.Orientation = Vector3.new(0, 0, 90)
hat.Parent      = model

-- Sign board above NPC
local sign = Instance.new("Part")
sign.Name        = "Sign"
sign.Size        = Vector3.new(3, 1.2, 0.2)
sign.BrickColor  = BrickColor.new("Bright yellow")
sign.Material    = Enum.Material.SmoothPlastic
sign.Anchored    = true
sign.CanCollide  = false
sign.CastShadow  = false
sign.Position    = SHOP_POSITION + Vector3.new(0, 4.5, 0)
sign.Parent      = model

local signGui = Instance.new("SurfaceGui")
signGui.Face   = Enum.NormalId.Front
signGui.Parent = sign

local signLabel = Instance.new("TextLabel")
signLabel.Size             = UDim2.new(1, 0, 1, 0)
signLabel.BackgroundColor3 = Color3.fromRGB(255, 220, 60)
signLabel.BackgroundTransparency = 0
signLabel.Text             = "🏪 SHOP"
signLabel.TextColor3       = Color3.fromRGB(80, 40, 0)
signLabel.TextScaled       = true
signLabel.Font             = Enum.Font.GothamBold
signLabel.Parent           = signGui

-- Billboard GUI floating above head
local billboard = Instance.new("BillboardGui")
billboard.Size         = UDim2.new(0, 130, 0, 50)
billboard.StudsOffset  = Vector3.new(0, 3.2, 0)
billboard.AlwaysOnTop  = false
billboard.Parent       = torso

local bbLabel = Instance.new("TextLabel")
bbLabel.Size             = UDim2.new(1, 0, 1, 0)
bbLabel.BackgroundColor3 = Color3.fromRGB(30, 20, 0)
bbLabel.BackgroundTransparency = 0.3
bbLabel.Text             = "Press [E] to shop"
bbLabel.TextColor3       = Color3.fromRGB(255, 255, 200)
bbLabel.TextScaled       = true
bbLabel.Font             = Enum.Font.GothamBold
bbLabel.Parent           = billboard
Instance.new("UICorner", bbLabel).CornerRadius = UDim.new(0, 8)

-- ProximityPrompt
local prompt = Instance.new("ProximityPrompt")
prompt.ActionText            = "Open Shop"
prompt.ObjectText            = "ShopKeeper"
prompt.KeyboardKeyCode       = Enum.KeyCode.E
prompt.HoldDuration          = 0
prompt.MaxActivationDistance = 12
prompt.RequiresLineOfSight   = false
prompt.Parent                = torso

prompt.Triggered:Connect(function(player)
	Remotes.OpenShop:FireClient(player)
	print("[ShopNPC] Opened shop for", player.Name)
end)

model.PrimaryPart = torso
model.Parent      = workspace

print("[ShopNPC] Shop keeper spawned at", SHOP_POSITION)
