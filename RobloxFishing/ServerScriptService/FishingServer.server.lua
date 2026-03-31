-- ============================================================
-- FishingServer.lua  (Script in ServerScriptService)
-- Core fishing loop: water prompts, bobber, minigame, fish award.
-- Fish go to inventory only — players sell them at the shop.
-- ============================================================

local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService          = game:GetService("RunService")

local FishData        = require(ReplicatedStorage:WaitForChild("FishData"))
local BaitData        = require(ReplicatedStorage:WaitForChild("BaitData"))
local UpgradeData     = require(ReplicatedStorage:WaitForChild("UpgradeData"))
local AchievementData = require(ReplicatedStorage:WaitForChild("AchievementData"))
local Remotes         = require(ReplicatedStorage:WaitForChild("FishingRemotes"))
local InventoryServer = require(ServerScriptService:WaitForChild("InventoryServer"))
local PlayerData      = require(ServerScriptService:WaitForChild("PlayerData"))

-- TournamentServer is a ModuleScript — require after it loads
local TournamentServer = nil
task.delay(3, function()
	local ok, mod = pcall(function()
		return require(ServerScriptService:WaitForChild("TournamentServer", 10))
	end)
	if ok and mod then
		TournamentServer = mod
		print("[FishingServer] Linked to TournamentServer")
	else
		warn("[FishingServer] Could not link TournamentServer:", mod)
	end
end)

-- WeatherService: loaded lazily to avoid circular require ordering issues
local WeatherService = nil
task.delay(3, function()
	local ok, mod = pcall(function()
		return require(ServerScriptService:WaitForChild("WeatherService", 10))
	end)
	if ok and mod then
		WeatherService = mod
		print("[FishingServer] Linked to WeatherService")
	else
		warn("[FishingServer] Could not link WeatherService:", mod)
	end
end)

-- ── Per-player fishing state ───────────────────────────────
local playerState = {}

-- ── Hotspot positions (registered by HotspotServer) ───────
local hotspotPositions = {}
local HOTSPOT_RADIUS   = 20   -- studs: radius for faster bites + star bonus

local FishingServer = {}

function FishingServer.RegisterHotspot(pos)
	table.insert(hotspotPositions, pos)
end

function FishingServer.GetHotspotPositions()
	return hotspotPositions
end

-- ── Achievement checker ────────────────────────────────────
local function checkAchievements(player)
	local data = PlayerData.Get(player)
	if not data then return end
	local stats     = data.achievementStats
	local completed = data.completedAchievements
	stats.reelLevel = data.reelLevel
	stats.hookLevel = data.hookLevel
	stats.rodLevel  = data.rodLevel
	stats.allMaxed  = (data.reelLevel >= 4 and data.hookLevel >= 4 and data.rodLevel >= 4) and 1 or 0
	for _, ach in ipairs(AchievementData) do
		if not completed[ach.id] then
			if (stats[ach.statKey] or 0) >= ach.goal then
				completed[ach.id] = true
				Remotes.AchievementUnlocked:FireClient(player, {
					id   = ach.id,
					name = ach.name,
					icon = ach.icon,
					desc = ach.desc,
				})
			end
		end
	end
end

-- ── Build bait lookup table ────────────────────────────────
local baitById = {}
for _, b in ipairs(BaitData) do baitById[b.id] = b end

-- ── Time-of-day helper ─────────────────────────────────────
local Lighting = game:GetService("Lighting")
local function isNightTime()
	local t = Lighting.ClockTime
	return t >= 20 or t < 6
end

-- ── Fish picker with reel + bait bonuses ──────────────────
-- rarityBonus 0-0.50 shifts weights toward rarer fish.
-- If baitTag set, fish matching the tag get 3x weight.
-- Only fish valid for the current time of day are included.
local function pickFish(rarityBonus, baitTag)
	local b = rarityBonus or 0
	local night = isNightTime()
	local pool, total = {}, 0
	for _, fish in ipairs(FishData.Fish) do
		-- Filter by spawn time
		local spawnTime = fish.spawnTime or "both"
		if spawnTime == "day"   and night then continue end
		if spawnTime == "night" and not night then continue end

		local mult
		if     fish.rarity == "Common"    then mult = math.max(0.05, 1.0 - b * 1.5)
		elseif fish.rarity == "Uncommon"  then mult = 1.0 + b * 1.0
		elseif fish.rarity == "Rare"      then mult = 1.0 + b * 4.0
		elseif fish.rarity == "Legendary" then mult = 1.0 + b * 10.0
		else                                   mult = 1.0
		end
		-- Bait tag affinity: matching fish get 3x this tier
		if baitTag and fish.baitTag == baitTag then
			mult = mult * 3
		end
		local w = fish.weight * mult
		table.insert(pool, { fish = fish, w = w })
		total = total + w
	end
	-- Fallback: all fish (shouldn't happen with "both" entries)
	if total == 0 then
		for _, fish in ipairs(FishData.Fish) do
			table.insert(pool, { fish = fish, w = fish.weight })
			total = total + fish.weight
		end
	end
	local roll, cum = math.random() * total, 0
	for _, entry in ipairs(pool) do
		cum = cum + entry.w
		if roll <= cum then return entry.fish end
	end
	return pool[1] and pool[1].fish or FishData.Fish[1]
end

-- ── Bobber helpers ─────────────────────────────────────────
local function spawnBobber(position)
	local part      = Instance.new("Part")
	part.Name       = "Bobber"
	part.Size       = Vector3.new(0.5, 0.5, 0.5)
	part.Shape      = Enum.PartType.Ball
	part.BrickColor = BrickColor.new("Bright red")
	part.Material   = Enum.Material.SmoothPlastic
	part.Anchored   = true
	part.CanCollide = false
	part.CastShadow = false
	part.Position   = position
	part.Parent     = workspace
	return part
end

local function removeBobber(state)
	if state.bobberPart then
		state.bobberPart:Destroy()
		state.bobberPart = nil
	end
end

local function resetState(player)
	local state = playerState[player]
	if state then
		removeBobber(state)
		state.isFishing   = false
		state.biting      = false
		state.currentFish = nil
	end
end

-- ── Hotspot check ──────────────────────────────────────────
local function nearHotspot(player)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return false end
	local pos = root.Position
	for _, hPos in ipairs(hotspotPositions) do
		if (pos - hPos).Magnitude <= HOTSPOT_RADIUS then return true end
	end
	return false
end

-- ── Upgrade params ─────────────────────────────────────────
local function getUpgradeParams(player)
	local data = PlayerData.Get(player)
	if not data then
		return { rarityBonus=0, fishSpeedMult=1, barBonus=0, waitMult=1, speedBonus=0, baitTag=nil }
	end
	local reel = UpgradeData.Reel[data.reelLevel] or UpgradeData.Reel[1]
	local hook = UpgradeData.Hook[data.hookLevel] or UpgradeData.Hook[1]
	local rod  = UpgradeData.Rod[data.rodLevel]   or UpgradeData.Rod[1]

	-- Bait bonuses stack on top of reel rarity bonus
	local bait    = baitById[data.currentBait] or baitById["basic"]
	local rarityB = (reel.rarityBonus or 0) + (bait.rarityBonus or 0)
	local speedB  = bait.speedBonus or 0

	return {
		rarityBonus   = math.clamp(rarityB, -0.2, 0.8),
		fishSpeedMult = hook.fishSpeedMult,
		barBonus      = rod.barBonus,
		waitMult      = reel.waitMult,
		speedBonus    = speedB,
		baitTag       = bait.baitTag,
		baitId        = data.currentBait,
	}
end

-- ── Consume 1 bait ─────────────────────────────────────────
-- Returns bait params before consuming; switches to basic if empty
local function consumeBait(player)
	local data = PlayerData.Get(player)
	if not data then return end
	local baitId = data.currentBait or "basic"
	local inv    = data.baitInventory
	if inv and (inv[baitId] or 0) > 0 then
		inv[baitId] = inv[baitId] - 1
		if inv[baitId] <= 0 and baitId ~= "basic" then
			-- Ran out of this bait type; fall back to basic
			data.currentBait = "basic"
		end
		-- Broadcast updated counts to client
		Remotes.BaitUpdate:FireClient(player, inv, data.currentBait)
	end
end

-- ── Fishing loop ───────────────────────────────────────────
local BASE_WAIT_MIN = 6    -- seconds (increased from old 3)
local BASE_WAIT_MAX = 18   -- seconds (increased from old 12)

local function runFishingLoop(player)
	local state = playerState[player]
	if not state then return end

	local params = getUpgradeParams(player)

	-- Hotspot = halved wait; reel + bait speed reduce further
	local waitMin = BASE_WAIT_MIN
	local waitMax = BASE_WAIT_MAX
	if nearHotspot(player) then
		waitMin = waitMin / 2
		waitMax = waitMax / 2
	end
	-- Apply reel wait multiplier, bait speed bonus, and rain bonus (x2 speed = x0.5 wait)
	local rainMult  = (WeatherService and WeatherService.IsRaining()) and 0.5 or 1
	local totalMult = params.waitMult * (1 - params.speedBonus) * rainMult
	waitMin = math.max(2, math.floor(waitMin * totalMult))
	waitMax = math.max(3, math.floor(waitMax * totalMult))
	task.wait(math.random(waitMin, waitMax))

	if not state.isFishing then return end

	-- Consume bait
	consumeBait(player)

	local fish = pickFish(params.rarityBonus, params.baitTag)
	state.currentFish = fish
	state.biting      = true

	Remotes.FishBiting:FireClient(player, fish.rarity, fish.name,
		params.fishSpeedMult, params.barBonus)

	-- 600s safety timeout (fish battle has no time pressure; only ends on catch or lose)
	task.delay(600, function()
		if state.biting then
			state.biting = false
			resetState(player)
			Remotes.FishMissed:FireClient(player)
		end
	end)
end

-- ── Start fishing ──────────────────────────────────────────
local function startFishing(player, waterPart)
	local state = playerState[player]
	if not state or state.isFishing then return end

	state.isFishing   = true
	state.biting      = false
	state.currentFish = nil

	local character = player.Character
	local root      = character and character:FindFirstChild("HumanoidRootPart")
	local landPos
	if root then
		landPos = Vector3.new(
			root.Position.X,
			waterPart.Position.Y + waterPart.Size.Y / 2 + 0.3,
			root.Position.Z
		)
	else
		landPos = waterPart.Position + Vector3.new(0, waterPart.Size.Y / 2 + 0.3, 0)
	end

	removeBobber(state)
	state.bobberPart = spawnBobber(landPos)
	Remotes.BobberLanded:FireClient(player, landPos)
	task.spawn(runFishingLoop, player)
end

-- ── Water detection + ProximityPrompt ─────────────────────
local function isWaterPart(part)
	if not part:IsA("BasePart") then return false end
	if part.Material == Enum.Material.Water then return true end
	local n = part.Name:lower()
	if n:find("water") then return true end
	if part.Parent and part.Parent.Name:lower():find("water") then return true end
	return false
end

local function addPromptToWaterPart(part)
	if not isWaterPart(part) then return end
	if part:FindFirstChildOfClass("ProximityPrompt") then return end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText            = "Fish"
	prompt.ObjectText            = "Water"
	prompt.KeyboardKeyCode       = Enum.KeyCode.E
	prompt.HoldDuration          = 0
	prompt.MaxActivationDistance = 20
	prompt.RequiresLineOfSight   = false
	prompt.Parent                = part
	prompt.Triggered:Connect(function(player) startFishing(player, part) end)
end

local function setupWaterPrompts()
	local count = 0
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") then
			addPromptToWaterPart(obj)
			if obj:FindFirstChildOfClass("ProximityPrompt") then count += 1 end
		end
	end
	print("[FishingServer] Water scan done. Prompts on", count, "part(s).")
end

workspace.DescendantAdded:Connect(addPromptToWaterPart)
setupWaterPrompts()
task.delay(3, setupWaterPrompts)

-- ── Award caught fish (no auto-coins — player sells later) ─
local STAR_CHANCE_NORMAL = 1/5
local STAR_CHANCE_TOURNEY = 1/3

local function awardFish(player)
	local state = playerState[player]
	if not state or not state.biting or not state.currentFish then return false end

	local fish = state.currentFish
	-- Bell-curve size roll
	local size = FishData.RollSize(fish)

	-- Add to inventory only (no coins yet)
	InventoryServer.AddFish(player, fish.name, size, fish.rarity)

	local data = PlayerData.Get(player)
	if data then
		-- Keep persistent inventory in sync
		table.insert(data.inventory, { name=fish.name, size=size, rarity=fish.rarity, time=os.time() })

		-- Stars: higher chance during tournament
		local inTourney = TournamentServer and TournamentServer.IsActive()
		local starChance = inTourney and STAR_CHANCE_TOURNEY or STAR_CHANCE_NORMAL
		if math.random() < starChance then
			data.stars = data.stars + 1
			Remotes.StarsUpdate:FireClient(player, data.stars)
		end

		-- Track caught fish names (for compendium reveal)
		if not data.caughtFishNames then data.caughtFishNames = {} end
		data.caughtFishNames[fish.name] = true

		-- Achievement stats
		local stats = data.achievementStats
		stats.totalCaught += 1
		if fish.rarity == "Uncommon"  then stats.uncommonCaught  += 1 end
		if fish.rarity == "Rare"      then stats.rareCaught      += 1 end
		if fish.rarity == "Legendary" then stats.legendaryCaught += 1 end
		if size > stats.biggestCatch  then stats.biggestCatch = size  end
		if not stats.speciesSet[fish.name] then
			stats.speciesSet[fish.name] = true
			stats.speciesCaught += 1
		end
		checkAchievements(player)
	end

	-- Notify TournamentServer
	if TournamentServer then
		TournamentServer.RecordCatch(player)
	end

	Remotes.FishCaught:FireClient(player, {
		name   = fish.name,
		size   = size,
		rarity = fish.rarity,
		color  = fish.color,
		-- No coins field here — player must sell at shop
	})
	resetState(player)
	return true
end

-- ── Minigame result handlers ────────────────────────────────
Remotes.MinigameWon.OnServerEvent:Connect(function(player)
	awardFish(player)
end)

Remotes.MinigameLost.OnServerEvent:Connect(function(player)
	local state = playerState[player]
	if not state then return end
	resetState(player)
	Remotes.FishMissed:FireClient(player)
end)

Remotes.ReelIn.OnServerEvent:Connect(function(player)
	if not awardFish(player) then resetState(player) end
end)

-- ── Shop / Upgrades ────────────────────────────────────────
Remotes.GetUpgrades.OnServerInvoke = function(player)
	local data = PlayerData.Get(player)
	if not data then return { coins=0, stars=0, reelLevel=1, hookLevel=1, rodLevel=1 } end
	return {
		coins     = data.coins,
		stars     = data.stars,
		reelLevel = data.reelLevel,
		hookLevel = data.hookLevel,
		rodLevel  = data.rodLevel,
	}
end

Remotes.BuyUpgrade.OnServerInvoke = function(player, upgradeType, targetLevel)
	local data = PlayerData.Get(player)
	if not data then return false, "No data" end

	local levelKey = upgradeType:lower() .. "Level"
	local tiers    = UpgradeData[upgradeType]
	if not tiers then return false, "Unknown type: " .. tostring(upgradeType) end

	local current = data[levelKey] or 1
	if targetLevel ~= current + 1 then return false, "Buy tiers in order" end
	if targetLevel > #tiers        then return false, "Already maxed" end

	local tier = tiers[targetLevel]
	if data.coins < tier.cost then
		return false, ("Need %d coins (have %d)"):format(tier.cost, data.coins)
	end
	local starCost = tier.starCost or 0
	if data.stars < starCost then
		return false, ("Need %d stars (have %d)"):format(starCost, data.stars)
	end

	data.coins     = data.coins - tier.cost
	data.stars     = data.stars - starCost
	data[levelKey] = targetLevel
	Remotes.CoinsUpdate:FireClient(player, data.coins)
	Remotes.StarsUpdate:FireClient(player, data.stars)
	checkAchievements(player)
	return true, targetLevel, data.coins, data.stars
end

-- ── Bait ──────────────────────────────────────────────────
Remotes.GetBaitState.OnServerInvoke = function(player)
	local data = PlayerData.Get(player)
	if not data then return { inventory={basic=30}, current="basic" } end
	return { inventory = data.baitInventory, current = data.currentBait }
end

Remotes.SelectBait.OnServerEvent:Connect(function(player, baitId)
	local data = PlayerData.Get(player)
	if not data then return end
	if not baitById[baitId] then return end
	if (data.baitInventory[baitId] or 0) <= 0 and baitId ~= "basic" then return end
	data.currentBait = baitId
	Remotes.BaitUpdate:FireClient(player, data.baitInventory, data.currentBait)
end)

Remotes.BuyBait.OnServerInvoke = function(player, baitId)
	local data   = PlayerData.Get(player)
	local baitDef = baitById[baitId]
	if not data or not baitDef then return false, "Unknown bait" end
	if data.coins < baitDef.shopCost then
		return false, ("Need %d coins"):format(baitDef.shopCost)
	end
	data.coins = data.coins - baitDef.shopCost
	data.baitInventory[baitId] = (data.baitInventory[baitId] or 0) + baitDef.shopAmount
	Remotes.CoinsUpdate:FireClient(player, data.coins)
	Remotes.BaitUpdate:FireClient(player, data.baitInventory, data.currentBait)
	return true, data.coins
end

-- ── Caught fish compendium ─────────────────────────────────
Remotes.GetCaughtFish.OnServerInvoke = function(player)
	local data = PlayerData.Get(player)
	if not data then return {} end
	return data.caughtFishNames or {}
end

-- ── Achievements ──────────────────────────────────────────
Remotes.GetAchievements.OnServerInvoke = function(player)
	local data = PlayerData.Get(player)
	if not data then return {}, {} end
	return data.achievementStats, data.completedAchievements
end

-- ── Debug (Studio only) ────────────────────────────────────
Remotes.DebugGiveCoins.OnServerEvent:Connect(function(player, amount)
	if not RunService:IsStudio() then return end
	local data = PlayerData.Get(player)
	if not data then return end
	data.coins = data.coins + (amount or 1000)
	Remotes.CoinsUpdate:FireClient(player, data.coins)
end)

Remotes.DebugGiveStars.OnServerEvent:Connect(function(player, amount)
	if not RunService:IsStudio() then return end
	local data = PlayerData.Get(player)
	if not data then return end
	data.stars = data.stars + (amount or 20)
	Remotes.StarsUpdate:FireClient(player, data.stars)
end)

Remotes.DebugGiveFish.OnServerEvent:Connect(function(player)
	if not RunService:IsStudio() then return end
	local samples = {
		{ name="Salmon",     size=32, rarity="Common"    },
		{ name="Bass",       size=28, rarity="Common"    },
		{ name="Trout",      size=41, rarity="Uncommon"  },
		{ name="Swordfish",  size=89, rarity="Rare"      },
		{ name="Dragon Eel", size=120, rarity="Legendary" },
	}
	for _, f in ipairs(samples) do
		InventoryServer.AddFish(player, f.name, f.size, f.rarity)
		local data = PlayerData.Get(player)
		if data then
			table.insert(data.inventory, { name=f.name, size=f.size, rarity=f.rarity, time=os.time() })
		end
	end
	print("[Debug] Added 5 test fish for", player.Name)
end)

-- ── Player lifecycle ───────────────────────────────────────
local function initPlayer(player)
	local data = PlayerData.Load(player)
	InventoryServer.LoadInventory(player, data.inventory)
	playerState[player] = { isFishing=false, biting=false, currentFish=nil, bobberPart=nil }

	task.delay(2, function()
		if not (player and player.Parent) then return end
		Remotes.CoinsUpdate:FireClient(player, data.coins)
		Remotes.StarsUpdate:FireClient(player, data.stars)
		Remotes.BaitUpdate:FireClient(player, data.baitInventory, data.currentBait)
		-- Send hotspot positions so client can show zone notification
		if #hotspotPositions > 0 then
			Remotes.HotspotList:FireClient(player, hotspotPositions)
		end
	end)
end

for _, p in ipairs(Players:GetPlayers()) do initPlayer(p) end
Players.PlayerAdded:Connect(initPlayer)

Players.PlayerRemoving:Connect(function(player)
	local state = playerState[player]
	if state then removeBobber(state) end
	-- Sync inventory to PlayerData before save
	local data = PlayerData.Get(player)
	if data then data.inventory = InventoryServer.GetInventory(player) end
	PlayerData.Unload(player)
	playerState[player] = nil
end)

print("[FishingServer] Loaded and ready!")
return FishingServer
