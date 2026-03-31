-- ============================================================
-- FishData.lua  (ModuleScript in ReplicatedStorage)
-- Fish table, random-pick, bell-curve size roll, sell value.
--
-- Fish fields:
--   name      - display name
--   rarity    - "Common" | "Uncommon" | "Rare" | "Legendary"
--   weight    - weighted-random pick chance (higher = more common)
--   minSize   - smallest possible size in cm
--   maxSize   - largest possible size in cm
--   color     - BrickColor name used for bobber tint
--   baseValue - base coin sell price (before size bonus)
--   baitTag   - optional tag matched by bait type ("nocturnal", "predator", "common")
-- ============================================================

local FishData = {}

FishData.Fish = {
	-- ── Common ────────────────────────────────────────────────
	{
		name      = "Bluegill",
		rarity    = "Common",
		weight    = 50,
		minSize   = 10,
		maxSize   = 25,
		color     = "Bright blue",
		baseValue = 4,
		baitTag   = "common",
		spawnTime = "day",    -- active during daytime
	},
	{
		name      = "Catfish",
		rarity    = "Common",
		weight    = 40,
		minSize   = 20,
		maxSize   = 60,
		color     = "Dark grey",
		baseValue = 6,
		baitTag   = "nocturnal",
		spawnTime = "night",  -- nocturnal feeder
	},
	{
		name      = "Perch",
		rarity    = "Common",
		weight    = 35,
		minSize   = 12,
		maxSize   = 30,
		color     = "Bright orange",
		baseValue = 5,
		baitTag   = "common",
		spawnTime = "day",
	},

	-- ── Uncommon ──────────────────────────────────────────────
	{
		name      = "Bass",
		rarity    = "Uncommon",
		weight    = 25,
		minSize   = 25,
		maxSize   = 55,
		color     = "Olive",
		baseValue = 14,
		baitTag   = "predator",
		spawnTime = "both",
	},
	{
		name      = "Trout",
		rarity    = "Uncommon",
		weight    = 20,
		minSize   = 20,
		maxSize   = 50,
		color     = "Medium green",
		baseValue = 12,
		baitTag   = nil,
		spawnTime = "day",
	},
	{
		name      = "Carp",
		rarity    = "Uncommon",
		weight    = 18,
		minSize   = 30,
		maxSize   = 65,
		color     = "Sand yellow",
		baseValue = 13,
		baitTag   = "common",
		spawnTime = "both",
	},

	-- ── Rare ──────────────────────────────────────────────────
	{
		name      = "Pike",
		rarity    = "Rare",
		weight    = 8,
		minSize   = 40,
		maxSize   = 90,
		color     = "Dark green",
		baseValue = 40,
		baitTag   = "predator",
		spawnTime = "day",
	},
	{
		name      = "Golden Koi",
		rarity    = "Rare",
		weight    = 5,
		minSize   = 30,
		maxSize   = 70,
		color     = "Bright yellow",
		baseValue = 55,
		baitTag   = nil,
		spawnTime = "day",
	},
	{
		name      = "Shadow Carp",
		rarity    = "Rare",
		weight    = 6,
		minSize   = 35,
		maxSize   = 75,
		color     = "Dark indigo",
		baseValue = 48,
		baitTag   = "nocturnal",
		spawnTime = "night",
	},
	{
		name      = "Lanternfish",
		rarity    = "Rare",
		weight    = 5,
		minSize   = 15,
		maxSize   = 40,
		color     = "Cyan",
		baseValue = 52,
		baitTag   = "nocturnal",
		spawnTime = "night",
	},
	{
		name      = "River Dart",
		rarity    = "Rare",
		weight    = 6,
		minSize   = 20,
		maxSize   = 55,
		color     = "Silver",
		baseValue = 45,
		baitTag   = "predator",
		spawnTime = "both",
	},

	-- ── Legendary ─────────────────────────────────────────────
	{
		name      = "Moonfish",
		rarity    = "Legendary",
		weight    = 1,
		minSize   = 60,
		maxSize   = 120,
		color     = "White",
		baseValue = 130,
		baitTag   = "nocturnal",
		spawnTime = "night",
		hint      = "Fish at night using nocturnal bait near a glowing hotspot.",
	},
	{
		name      = "Void Eel",
		rarity    = "Legendary",
		weight    = 1,
		minSize   = 80,
		maxSize   = 150,
		color     = "Black",
		baseValue = 160,
		baitTag   = "nocturnal",
		spawnTime = "night",
		hint      = "Emerges only at night in the deepest waters. Use nocturnal bait.",
	},
}

-- ── Weighted random pick (used by server as fallback) ──────
function FishData.PickRandomFish()
	local totalWeight = 0
	for _, fish in ipairs(FishData.Fish) do
		totalWeight = totalWeight + fish.weight
	end
	local roll = math.random(1, totalWeight)
	local cum  = 0
	for _, fish in ipairs(FishData.Fish) do
		cum = cum + fish.weight
		if roll <= cum then return fish end
	end
	return FishData.Fish[1]
end

-- ── Bell-curve size roll ────────────────────────────────────
-- Returns a size drawn from a normal distribution centred on
-- the fish's midpoint. Clamped to [minSize, maxSize].
function FishData.RollSize(fish)
	-- Box-Muller transform → standard normal z
	local u1 = math.max(1e-9, math.random())   -- avoid log(0)
	local u2 = math.random()
	local z  = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
	-- Scale: ±3σ spans the full range (99.7% of samples stay inside)
	local mean   = (fish.minSize + fish.maxSize) / 2
	local stdDev = (fish.maxSize - fish.minSize) / 6
	local size   = math.round(mean + z * stdDev)
	return math.clamp(size, fish.minSize, fish.maxSize)
end

-- ── U-shaped sell value ─────────────────────────────────────
-- Both very small AND very large catches sell for more.
-- Legendary/Rare caps the bonus so they don't get overpowered.
function FishData.SellValue(fish, size)
	local mean      = (fish.minSize + fish.maxSize) / 2
	local halfRange = (fish.maxSize - fish.minSize) / 2
	-- Normalised deviation: 0 at mean, 1 at extremes
	local deviation = halfRange > 0 and math.abs(size - mean) / halfRange or 0

	-- Max bonus % depends on rarity (rarer = smaller bonus cap)
	local maxBonus
	if     fish.rarity == "Legendary" then maxBonus = 0.18
	elseif fish.rarity == "Rare"      then maxBonus = 0.30
	elseif fish.rarity == "Uncommon"  then maxBonus = 0.40
	else                                   maxBonus = 0.50
	end

	-- Power curve: deviation^1.5 keeps the middle flat and extremes rewarded
	local bonus = deviation ^ 1.5 * maxBonus
	return math.max(1, math.floor(fish.baseValue * (1 + bonus)))
end

return FishData
