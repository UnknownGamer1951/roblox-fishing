-- ============================================================
-- FishData.lua  (ModuleScript in ReplicatedStorage)
-- Each fish has: name, rarity, weight, minSize, maxSize,
--               color, baseValue (coins before size bonus)
-- ============================================================

local FishData = {}

FishData.Fish = {
	{
		name      = "Bluegill",
		rarity    = "Common",
		weight    = 50,
		minSize   = 10,
		maxSize   = 25,
		color     = "Bright blue",
		baseValue = 4,
	},
	{
		name      = "Catfish",
		rarity    = "Common",
		weight    = 40,
		minSize   = 20,
		maxSize   = 60,
		color     = "Dark grey",
		baseValue = 6,
	},
	{
		name      = "Bass",
		rarity    = "Uncommon",
		weight    = 25,
		minSize   = 25,
		maxSize   = 55,
		color     = "Olive",
		baseValue = 14,
	},
	{
		name      = "Trout",
		rarity    = "Uncommon",
		weight    = 20,
		minSize   = 20,
		maxSize   = 50,
		color     = "Medium green",
		baseValue = 12,
	},
	{
		name      = "Pike",
		rarity    = "Rare",
		weight    = 8,
		minSize   = 40,
		maxSize   = 90,
		color     = "Dark green",
		baseValue = 40,
	},
	{
		name      = "Golden Koi",
		rarity    = "Rare",
		weight    = 5,
		minSize   = 30,
		maxSize   = 70,
		color     = "Bright yellow",
		baseValue = 55,
	},
	{
		name      = "Moonfish",
		rarity    = "Legendary",
		weight    = 1,
		minSize   = 60,
		maxSize   = 120,
		color     = "White",
		baseValue = 130,
	},
	{
		name      = "Void Eel",
		rarity    = "Legendary",
		weight    = 1,
		minSize   = 80,
		maxSize   = 150,
		color     = "Black",
		baseValue = 160,
	},
}

-- Weighted random pick (used by server as fallback)
function FishData.PickRandomFish()
	local totalWeight = 0
	for _, fish in ipairs(FishData.Fish) do
		totalWeight = totalWeight + fish.weight
	end
	local roll = math.random(1, totalWeight)
	local cumulative = 0
	for _, fish in ipairs(FishData.Fish) do
		cumulative = cumulative + fish.weight
		if roll <= cumulative then return fish end
	end
	return FishData.Fish[1]
end

-- Coin value: baseValue + size bonus (1 coin per 5 cm above minSize)
function FishData.SellValue(fish, size)
	local sizeBonus = math.floor((size - fish.minSize) / 5)
	return math.max(1, fish.baseValue + sizeBonus)
end

return FishData
