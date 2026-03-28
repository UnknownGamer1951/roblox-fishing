-- ============================================================
-- FishingRemotes.lua  (ModuleScript in ReplicatedStorage)
-- Shared remote events/functions for the fishing game
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = {}

local function getOrCreate(className, name)
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing then return existing end
	local obj = Instance.new(className)
	obj.Name   = name
	obj.Parent = ReplicatedStorage
	return obj
end

-- ── Core fishing ─────────────────────────────────────────────
Remotes.CastLine     = getOrCreate("RemoteEvent",    "CastLine")
Remotes.BobberLanded = getOrCreate("RemoteEvent",    "BobberLanded")
Remotes.FishBiting   = getOrCreate("RemoteEvent",    "FishBiting")
Remotes.ReelIn       = getOrCreate("RemoteEvent",    "ReelIn")
Remotes.FishCaught   = getOrCreate("RemoteEvent",    "FishCaught")
Remotes.FishMissed   = getOrCreate("RemoteEvent",    "FishMissed")
Remotes.GetInventory = getOrCreate("RemoteFunction", "GetInventory")

-- ── Minigame ──────────────────────────────────────────────────
Remotes.MinigameWon  = getOrCreate("RemoteEvent",    "MinigameWon")
Remotes.MinigameLost = getOrCreate("RemoteEvent",    "MinigameLost")

-- ── Tournament ────────────────────────────────────────────────
Remotes.TournamentStart  = getOrCreate("RemoteEvent", "TournamentStart")
Remotes.TournamentEnd    = getOrCreate("RemoteEvent", "TournamentEnd")
Remotes.TournamentPoints = getOrCreate("RemoteEvent", "TournamentPoints")
Remotes.JoinTournament   = getOrCreate("RemoteEvent", "JoinTournament")

-- ── Upgrades / Shop ───────────────────────────────────────────
Remotes.BuyUpgrade  = getOrCreate("RemoteFunction", "BuyUpgrade")
Remotes.GetUpgrades = getOrCreate("RemoteFunction", "GetUpgrades")
Remotes.CoinsUpdate = getOrCreate("RemoteEvent",    "CoinsUpdate")
Remotes.OpenShop    = getOrCreate("RemoteEvent",    "OpenShop")

-- ── Achievements ──────────────────────────────────────────────
Remotes.AchievementUnlocked = getOrCreate("RemoteEvent",    "AchievementUnlocked")
Remotes.GetAchievements     = getOrCreate("RemoteFunction", "GetAchievements")

-- ── Debug (Studio only) ───────────────────────────────────────
Remotes.DebugGiveCoins = getOrCreate("RemoteEvent", "DebugGiveCoins")

return Remotes
