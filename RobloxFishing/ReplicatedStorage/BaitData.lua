-- ============================================================
-- BaitData.lua  (ModuleScript in ReplicatedStorage)
-- Defines the 5 bait types. Players consume 1 bait per cast.
-- Bait modifies: rarity bonus, wait time speed, fish tag affinity.
-- ============================================================

-- baitTag: fish with this tag in FishData get a 3x weight multiplier
-- speedBonus: fraction 0-1 that reduces wait time (0.3 = 30% faster)
-- rarityBonus: stacks on top of Reel upgrade rarity bonus

return {
	{
		id          = "basic",
		name        = "Basic Worm",
		desc        = "Standard bait. Works on any fish.",
		icon        = "Worm",
		rarityBonus = 0,
		speedBonus  = 0,
		baitTag     = nil,
		shopCost    = 25,   -- coins for 10 uses
		shopAmount  = 10,
		startAmount = 30,
	},
	{
		id          = "dark",
		name        = "Dark Bait",
		desc        = "Lures nocturnal fish. Boosts rare+ chances after dark.",
		icon        = "Moon",
		rarityBonus = 0.12,
		speedBonus  = 0,
		baitTag     = "nocturnal",
		shopCost    = 80,
		shopAmount  = 10,
		startAmount = 0,
	},
	{
		id          = "lure",
		name        = "Shiny Lure",
		desc        = "Attracts predator fish. Bites come faster.",
		icon        = "Star",
		rarityBonus = 0.05,
		speedBonus  = 0.20,
		baitTag     = "predator",
		shopCost    = 60,
		shopAmount  = 10,
		startAmount = 0,
	},
	{
		id          = "bread",
		name        = "Bread Crumb",
		desc        = "Common fish love it. Very fast bites.",
		icon        = "Bread",
		rarityBonus = -0.05,
		speedBonus  = 0.35,
		baitTag     = "common",
		shopCost    = 30,
		shopAmount  = 10,
		startAmount = 0,
	},
	{
		id          = "magic",
		name        = "Magic Bait",
		desc        = "Powerful bait that greatly increases rare and legendary chances.",
		icon        = "Diamond",
		rarityBonus = 0.28,
		speedBonus  = 0,
		baitTag     = nil,
		shopCost    = 220,
		shopAmount  = 5,
		startAmount = 0,
	},
}
