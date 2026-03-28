-- ============================================================
-- UpgradeData.lua  (ModuleScript in ReplicatedStorage)
-- Upgrade tier definitions. Tiers 3-4 of premium upgrades
-- require both coins AND stars (starCost field).
-- ============================================================

return {
	-- ── Bait: shifts fish pick weights toward rarer fish ──────
	-- rarityBonus drives the multipliers in pickFishWithBonus()
	Bait = {
		{ name = "Basic Bait",    cost = 0,    starCost = 0, rarityBonus = 0.00 },
		{ name = "Good Bait",     cost = 100,  starCost = 0, rarityBonus = 0.15 },
		{ name = "Great Bait",    cost = 350,  starCost = 5, rarityBonus = 0.30 },
		{ name = "Master Bait",   cost = 900,  starCost = 15, rarityBonus = 0.50 },
	},

	-- ── Hook: multiplies fish acceleration in minigame ────────
	Hook = {
		{ name = "Rusty Hook",    cost = 0,    starCost = 0,  fishSpeedMult = 1.00 },
		{ name = "Steel Hook",    cost = 150,  starCost = 0,  fishSpeedMult = 0.80 },
		{ name = "Gold Hook",     cost = 450,  starCost = 5,  fishSpeedMult = 0.60 },
		{ name = "Diamond Hook",  cost = 1000, starCost = 20, fishSpeedMult = 0.35 },
	},

	-- ── Rod: adds to the catch bar height in minigame ─────────
	Rod = {
		{ name = "Wooden Rod",    cost = 0,    starCost = 0,  barBonus = 0.00 },
		{ name = "Fiberglass",    cost = 200,  starCost = 0,  barBonus = 0.06 },
		{ name = "Carbon Rod",    cost = 550,  starCost = 8,  barBonus = 0.12 },
		{ name = "Legend Rod",    cost = 1400, starCost = 25, barBonus = 0.22 },
	},
}
