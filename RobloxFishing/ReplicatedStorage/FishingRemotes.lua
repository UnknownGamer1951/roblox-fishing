-- ============================================================
-- FishingRemotes.lua  (ModuleScript in ReplicatedStorage)
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

-- ── Core fishing ──────────────────────────────────────────────
Remotes.CastLine     = getOrCreate("RemoteEvent",    "CastLine")
Remotes.BobberLanded = getOrCreate("RemoteEvent",    "BobberLanded")
Remotes.FishBiting   = getOrCreate("RemoteEvent",    "FishBiting")
Remotes.ReelIn       = getOrCreate("RemoteEvent",    "ReelIn")
Remotes.FishCaught   = getOrCreate("RemoteEvent",    "FishCaught")
Remotes.FishMissed   = getOrCreate("RemoteEvent",    "FishMissed")
Remotes.GetInventory = getOrCreate("RemoteFunction", "GetInventory")

-- ── Minigame ──────────────────────────────────────────────────
Remotes.MinigameWon  = getOrCreate("RemoteEvent", "MinigameWon")
Remotes.MinigameLost = getOrCreate("RemoteEvent", "MinigameLost")

-- ── Sell fish ─────────────────────────────────────────────────
-- Client fires SellFish(index) → server removes from inv, adds coins
Remotes.SellFish = getOrCreate("RemoteFunction", "SellFish")

-- ── Bait ──────────────────────────────────────────────────────
-- Server → Client: bait counts changed {id=count, ...}
Remotes.BaitUpdate   = getOrCreate("RemoteEvent",    "BaitUpdate")
-- Client → Server: change active bait type (id string)
Remotes.SelectBait   = getOrCreate("RemoteEvent",    "SelectBait")
-- Client asks for full bait state {inventory={...}, current="basic"}
Remotes.GetBaitState = getOrCreate("RemoteFunction", "GetBaitState")
-- Client buys bait at shop (id string)
Remotes.BuyBait      = getOrCreate("RemoteFunction", "BuyBait")

-- ── Hotspot ───────────────────────────────────────────────────
-- Server → Client: list of hotspot Vector3 positions on join
Remotes.HotspotList  = getOrCreate("RemoteEvent", "HotspotList")

-- ── Tournament (server-wide) ──────────────────────────────────
Remotes.TournamentCountdown = getOrCreate("RemoteEvent", "TournamentCountdown")
Remotes.TournamentStart     = getOrCreate("RemoteEvent", "TournamentStart")
Remotes.TournamentEnd       = getOrCreate("RemoteEvent", "TournamentEnd")
Remotes.TournamentPoints    = getOrCreate("RemoteEvent", "TournamentPoints")
Remotes.BuyTournament       = getOrCreate("RemoteEvent", "BuyTournament")

-- ── Upgrades / Shop ───────────────────────────────────────────
Remotes.BuyUpgrade  = getOrCreate("RemoteFunction", "BuyUpgrade")
Remotes.GetUpgrades = getOrCreate("RemoteFunction", "GetUpgrades")
Remotes.CoinsUpdate = getOrCreate("RemoteEvent",    "CoinsUpdate")
Remotes.StarsUpdate = getOrCreate("RemoteEvent",    "StarsUpdate")
Remotes.OpenShop    = getOrCreate("RemoteEvent",    "OpenShop")

-- ── Achievements ──────────────────────────────────────────────
Remotes.AchievementUnlocked = getOrCreate("RemoteEvent",    "AchievementUnlocked")
Remotes.GetAchievements     = getOrCreate("RemoteFunction", "GetAchievements")

-- ── Weather ───────────────────────────────────────────────────
-- Server → Client: rain started/stopped (bool isRaining)
Remotes.WeatherChange   = getOrCreate("RemoteEvent",    "WeatherChange")
-- Client asks for caught fish names {name=true, ...}
Remotes.GetCaughtFish   = getOrCreate("RemoteFunction", "GetCaughtFish")

-- ── Tutorial ──────────────────────────────────────────────────
-- Server → Client: current step number (0–5); fires on join and on advance
Remotes.TutorialStep      = getOrCreate("RemoteEvent",    "TutorialStep")
-- Server → Client: array of {speaker, text} lines for NPC dialog
Remotes.TutorialNPCDialog = getOrCreate("RemoteEvent",    "TutorialNPCDialog")
-- Client → Server: player successfully sold a fish (hooks into sell buttons)
Remotes.TutorialFishSold  = getOrCreate("RemoteEvent",    "TutorialFishSold")
-- Client → Server: player requests travel to main world (unused if TeleportAsync is server-side)
Remotes.RequestTravel     = getOrCreate("RemoteEvent",    "RequestTravel")

-- ── Debug (Studio only) ───────────────────────────────────────
Remotes.DebugGiveCoins = getOrCreate("RemoteEvent", "DebugGiveCoins")
Remotes.DebugGiveStars = getOrCreate("RemoteEvent", "DebugGiveStars")
Remotes.DebugGiveFish  = getOrCreate("RemoteEvent", "DebugGiveFish")

return Remotes
