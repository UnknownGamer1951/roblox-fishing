-- ============================================================
-- HotspotServer.lua  (Script in ServerScriptService)
-- Spawns glowing hotspot discs on/near water surfaces.
-- Hotspots are lighter-colored with sparkle ParticleEmitters.
-- Registers their positions with FishingServer so it uses
-- a faster cast wait time (1-4s instead of 4-12s).
-- ============================================================

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")

-- Wait for FishingServer module (it returns itself)
local FishingServer
task.spawn(function()
	local ok, mod = pcall(function()
		return require(ServerScriptService:WaitForChild("FishingServer", 10))
	end)
	if ok and mod then
		FishingServer = mod
		print("[HotspotServer] Linked to FishingServer")
	else
		warn("[HotspotServer] Could not link FishingServer:", mod)
	end
end)

-- ── Config ─────────────────────────────────────────────────────
local HOTSPOT_COUNT     = 4      -- how many hotspots to try spawning
local HOTSPOT_RADIUS    = 3      -- disc size (studs, visual only)
local SCATTER_RANGE     = 14     -- how far from water edge to scatter
local HOTSPOT_Y_OFFSET  = 0.15   -- slightly above water surface

-- ── Helpers ────────────────────────────────────────────────────
local function isWaterPart(part)
	if not part:IsA("BasePart") then return false end
	if part.Material == Enum.Material.Water then return true end
	local n = part.Name:lower()
	return n:find("water") ~= nil
end

local function collectWaterParts()
	local parts = {}
	for _, obj in ipairs(workspace:GetDescendants()) do
		if isWaterPart(obj) then
			table.insert(parts, obj)
		end
	end
	return parts
end

-- ── Sparkle emitter ────────────────────────────────────────────
local function addSparkles(parent)
	-- Neon glow disc
	local glow = Instance.new("Part")
	glow.Name             = "HotspotGlow"
	glow.Size             = Vector3.new(HOTSPOT_RADIUS * 2, 0.1, HOTSPOT_RADIUS * 2)
	glow.Shape            = Enum.PartType.Cylinder
	glow.Anchored         = true
	glow.CanCollide       = false
	glow.CastShadow       = false
	glow.Material         = Enum.Material.Neon
	glow.BrickColor       = BrickColor.new("Cyan")
	glow.Transparency     = 0.55
	glow.Orientation      = Vector3.new(0, 0, 90)   -- lay flat
	glow.Position         = parent.Position
	glow.Parent           = workspace

	-- Particle emitter (sparkles rising from water)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture            = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Rate               = 8
	pe.Lifetime           = NumberRange.new(1.5, 2.5)
	pe.Speed              = NumberRange.new(2, 5)
	pe.SpreadAngle        = Vector2.new(30, 30)
	pe.LightEmission      = 1
	pe.LightInfluence     = 0
	pe.Size               = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.5, 0.3),
		NumberSequenceKeypoint.new(1, 0),
	})
	pe.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 220, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	})
	pe.Parent             = glow

	-- Proximity label (BillboardGui)
	local bb = Instance.new("BillboardGui")
	bb.Size         = UDim2.new(0, 110, 0, 36)
	bb.StudsOffset  = Vector3.new(0, 2.5, 0)
	bb.AlwaysOnTop  = false
	bb.Parent       = glow
	local lbl = Instance.new("TextLabel", bb)
	lbl.Size             = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundColor3 = Color3.fromRGB(0, 40, 60)
	lbl.BackgroundTransparency = 0.35
	lbl.Text             = "⚡ Hotspot"
	lbl.TextColor3       = Color3.fromRGB(100, 220, 255)
	lbl.TextScaled       = true
	lbl.Font             = Enum.Font.GothamBold
	Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 8)

	return glow
end

-- ── Spawn hotspots after workspace settles ─────────────────────
task.delay(4, function()
	local waterParts = collectWaterParts()
	if #waterParts == 0 then
		warn("[HotspotServer] No water parts found — no hotspots spawned.")
		return
	end

	local spawned = 0
	local attempts = 0

	while spawned < HOTSPOT_COUNT and attempts < HOTSPOT_COUNT * 6 do
		attempts += 1
		-- Pick a random water part
		local wp = waterParts[math.random(1, #waterParts)]
		local wx = wp.Position.X + math.random(-1, 1) * wp.Size.X / 2
		local wz = wp.Position.Z + math.random(-1, 1) * wp.Size.Z / 2

		-- Scatter slightly from water edge so player can stand nearby
		local offsetX = (math.random() - 0.5) * 2 * SCATTER_RANGE
		local offsetZ = (math.random() - 0.5) * 2 * SCATTER_RANGE

		local hotspotPos = Vector3.new(
			wx + offsetX,
			wp.Position.Y + wp.Size.Y / 2 + HOTSPOT_Y_OFFSET,
			wz + offsetZ
		)

		-- Build a small invisible anchor part
		local anchor = Instance.new("Part")
		anchor.Name         = "FishingHotspot"
		anchor.Size         = Vector3.new(0.1, 0.1, 0.1)
		anchor.Anchored     = true
		anchor.CanCollide   = false
		anchor.Transparency = 1
		anchor.Position     = hotspotPos
		anchor.Parent       = workspace

		addSparkles(anchor)

		-- Register with FishingServer
		if FishingServer then
			FishingServer.RegisterHotspot(hotspotPos)
		end

		spawned += 1
		print(("[HotspotServer] Spawned hotspot %d at %s"):format(spawned, tostring(hotspotPos)))
	end

	print(("[HotspotServer] Done — %d hotspot(s) placed."):format(spawned))
end)
