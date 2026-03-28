-- ============================================================
-- UpgradeData.lua  (ModuleScript in ReplicatedStorage)
-- Shared upgrade tier definitions used by server AND client
-- ============================================================

return {
	-- Bait: shifts fish pick weights toward rarer fish
	Bait = {
		{ name = "Basic Bait",   cost = 0,    rarityBonus = 0.00 },
		{ name = "Good Bait",    cost = 100,  rarityBonus = 0.10 },
		{ name = "Great Bait",   cost = 300,  rarityBonus = 0.20 },
		{ name = "Master Bait",  cost = 750,  rarityBonus = 0.35 },
	},
	-- Hook: multiplies fish acceleration in minigame (lower = slower fish)
	Hook = {
		{ name = "Rusty Hook",   cost = 0,    fishSpeedMult = 1.00 },
		{ name = "Steel Hook",   cost = 150,  fishSpeedMult = 0.80 },
		{ name = "Gold Hook",    cost = 400,  fishSpeedMult = 0.60 },
		{ name = "Diamond Hook", cost = 900,  fishSpeedMult = 0.40 },
	},
	-- Rod: adds to the catch bar height in minigame
	Rod = {
		{ name = "Wooden Rod",   cost = 0,    barBonus = 0.00 },
		{ name = "Fiberglass",   cost = 200,  barBonus = 0.05 },
		{ name = "Carbon Rod",   cost = 500,  barBonus = 0.10 },
		{ name = "Legend Rod",   cost = 1200, barBonus = 0.18 },
	},
	-- Coins earned per caught fish rarity
	CoinRewards = {
		Common    = 5,
		Uncommon  = 15,
		Rare      = 50,
		Legendary = 150,
	},
}
