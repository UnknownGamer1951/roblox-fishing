-- ============================================================
-- AchievementData.lua  (ModuleScript in ReplicatedStorage)
-- Defines every achievement in the game.
--
-- Fields per achievement:
--   id      : unique string key (stored in PlayerData)
--   name    : display name
--   icon    : emoji shown in the journal
--   desc    : one-line description
--   statKey : key inside PlayerData.achievementStats to check
--   goal    : target value to reach
-- ============================================================

return {
	-- ── Catch milestones ──────────────────────────────────────
	{ id="first_catch",    name="First Cast",        icon="🎣", desc="Catch your very first fish",            statKey="totalCaught",    goal=1   },
	{ id="fish_10",        name="Getting Hooked",    icon="🐟", desc="Catch 10 fish",                         statKey="totalCaught",    goal=10  },
	{ id="fish_50",        name="Dedicated Angler",  icon="🐠", desc="Catch 50 fish",                         statKey="totalCaught",    goal=50  },
	{ id="fish_100",       name="Master Fisher",     icon="🏅", desc="Catch 100 fish",                        statKey="totalCaught",    goal=100 },

	-- ── Rarity achievements ───────────────────────────────────
	{ id="uncommon_5",     name="Uncommon Grounds",  icon="🟢", desc="Catch 5 Uncommon fish",                 statKey="uncommonCaught", goal=5   },
	{ id="rare_1",         name="Rare Find",         icon="🔵", desc="Catch your first Rare fish",            statKey="rareCaught",     goal=1   },
	{ id="rare_5",         name="Rare Collector",    icon="💎", desc="Catch 5 Rare fish",                     statKey="rareCaught",     goal=5   },
	{ id="legendary_1",    name="Legend!",           icon="⭐", desc="Catch your first Legendary fish",       statKey="legendaryCaught",goal=1   },
	{ id="legendary_3",    name="Living Legend",     icon="🌟", desc="Catch 3 Legendary fish",                statKey="legendaryCaught",goal=3   },

	-- ── Size / species achievements ───────────────────────────
	{ id="big_catch",      name="The Big One",       icon="📏", desc="Catch a fish 100 cm or longer",         statKey="biggestCatch",   goal=100 },
	{ id="all_species",    name="Collector",         icon="📖", desc="Catch all 8 different species",         statKey="speciesCaught",  goal=8   },

	-- ── Coins ─────────────────────────────────────────────────
	{ id="coins_100",      name="Pocket Change",     icon="🪙", desc="Earn 100 coins lifetime",               statKey="coinsEarned",    goal=100  },
	{ id="coins_500",      name="Coin Hoarder",      icon="💰", desc="Earn 500 coins lifetime",               statKey="coinsEarned",    goal=500  },
	{ id="coins_2000",     name="Fish Tycoon",       icon="🤑", desc="Earn 2,000 coins lifetime",             statKey="coinsEarned",    goal=2000 },

	-- ── Upgrades ──────────────────────────────────────────────
	{ id="bait_2",         name="Better Bait",       icon="🪱", desc="Buy your first Bait upgrade",           statKey="baitLevel",      goal=2   },
	{ id="hook_2",         name="Sharp Hook",        icon="🪝", desc="Buy your first Hook upgrade",           statKey="hookLevel",      goal=2   },
	{ id="rod_2",          name="New Rod",           icon="🎣", desc="Buy your first Rod upgrade",            statKey="rodLevel",       goal=2   },
	{ id="all_max",        name="Full Loadout",      icon="🔱", desc="Max out all three upgrades to level 4", statKey="allMaxed",       goal=1   },

	-- ── Tournament trophies ───────────────────────────────────
	{ id="trophy_bronze",  name="Bronze Angler",     icon="🥉", desc="Earn a Bronze tournament trophy",       statKey="trophyLevel",    goal=1   },
	{ id="trophy_silver",  name="Silver Angler",     icon="🥈", desc="Earn a Silver tournament trophy",       statKey="trophyLevel",    goal=2   },
	{ id="trophy_gold",    name="Golden Fisher",     icon="🥇", desc="Earn a Gold tournament trophy",         statKey="trophyLevel",    goal=3   },
}
