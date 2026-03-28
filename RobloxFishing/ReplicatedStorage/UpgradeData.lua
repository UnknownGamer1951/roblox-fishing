-- ============================================================
-- UpgradeData.lua  (ModuleScript in ReplicatedStorage)
-- "Bait" upgrade replaced with "Reel" upgrade.
--
-- Reel:  reduces base fishing wait time + slight rarity boost
-- Hook:  slows fish movement in the minigame
-- Rod:   increases catch-bar height in the minigame
-- ============================================================

return {
	-- ── Reel: reduces wait time before a bite ─────────────────
	-- waitMult: multiplied against base wait range (lower = faster)
	-- rarityBonus: stacks on top of bait rarity bonus
	Reel = {
		{ name = "Old Spool",     cost = 0,    starCost = 0,  waitMult = 1.00, rarityBonus = 0.00 },
		{ name = "Steel Reel",    cost = 120,  starCost = 0,  waitMult = 0.80, rarityBonus = 0.03 },
		{ name = "Carbon Reel",   cost = 380,  starCost = 5,  waitMult = 0.60, rarityBonus = 0.07 },
		{ name = "Master Reel",   cost = 950,  starCost = 15, waitMult = 0.40, rarityBonus = 0.12 },
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
