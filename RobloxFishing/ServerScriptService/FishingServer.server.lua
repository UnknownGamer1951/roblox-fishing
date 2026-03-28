-- ============================================================
-- FishingServer.lua  (Script in ServerScriptService)
-- Core fishing loop: water prompts, bobber, minigame bridge,
-- fish award (size-based sell value), star drops, achievements.
-- Tournament fish tracking is handled by TournamentServer.
-- ============================================================

local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService          = game:GetService("RunService")

local FishData        = require(ReplicatedStorage:WaitForChild("FishData"))
local UpgradeData     = require(ReplicatedStorage:WaitForChild("UpgradeData"))
local AchievementData = require(ReplicatedStorage:WaitForChild("AchievementData"))
local Remotes         = require(ReplicatedStorage:WaitForChild("FishingRemotes"))
local InventoryServer = require(ServerScriptService:WaitForChild("InventoryServer"))
local PlayerData      = require(ServerScriptService:WaitForChild("PlayerData"))

-- Filled by TournamentServer at runtime
local TournamentServer = nil
task.delay(3, function()
	local ok, mod = pcall(function()
		return require(ServerScriptService:WaitForChild("TournamentServer", 5))
	end)
	if ok and mod then TournamentServer = mod end
end)

-- ── Per-player fishing state ───────────────────────────────────
local playerState = {}

-- Set of hotspot positions (Vector3) registered by HotspotServer
local hotspotPositions = {}   -- { Vector3, ... }
local HOTSPOT_RADIUS   = 30   -- studs from hotspot centre

-- ── Hotspot API (called by HotspotServer) ─────────────────────
local FishingServer = {}

function FishingServer.RegisterHotspot(pos)
	table.insert(hotspotPositions, pos)
end

-- ── Achievement checker ────────────────────────────────────────
local function checkAchievements(player)
	local data = PlayerData.Get(player)
	if not data then return end
	local stats     = data.achievementStats
	local completed = data.completedAchievements
	stats.baitLevel = data.baitLevel
	stats.hookLevel = data.hookLevel
	stats.rodLevel  = data.rodLevel
	stats.allMaxed  = (data.baitLevel >= 4 and data.hookLevel >= 4 and data.rodLevel >= 4) and 1 or 0
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

-- ── Fish picking with bait bonus ───────────────────────────────
-- rarityBonus 0→0.50 shifts weight toward rarer fish.
-- Master Bait (0.50): Common mult≈0.25, Uncommon×1.5, Rare×3, Legendary×6
local function pickFishWithBonus(rarityBonus)
	local b = rarityBonus or 0
	local pool, total = {}, 0
	for _, fish in ipairs(FishData.Fish) do
		local mult
		if     fish.rarity == "Common"    then mult = math.max(0.05, 1.0 - b * 1.5)
		elseif fish.rarity == "Uncommon"  then mult = 1.0 + b * 1.0
		elseif fish.rarity == "Rare"      then mult = 1.0 + b * 4.0
		elseif fish.rarity == "Legendary" then mult = 1.0 + b * 10.0
		else                                   mult = 1.0
		end
		local w = fish.weight * mult
		table.insert(pool, { fish = fish, w = w })
		total = total + w
	end
	local roll, cum = math.random() * total, 0
	for _, entry in ipairs(pool) do
		cum = cum + entry.w
		if roll <= cum then return entry.fish end
	end
	return FishData.Fish[1]
end

-- ── Bobber helpers ─────────────────────────────────────────────
local function spawnBobber(position)
	local part        = Instance.new("Part")
	part.Name         = "Bobber"
	part.Size         = Vector3.new(0.5, 0.5, 0.5)
	part.Shape        = Enum.PartType.Ball
	part.BrickColor   = BrickColor.new("Bright red")
	part.Material     = Enum.Material.SmoothPlastic
	part.Anchored     = true
	part.CanCollide   = false
	part.CastShadow   = false
	part.Position     = position
	part.Parent       = workspace
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

-- ── Check if player is near a hotspot ─────────────────────────
local function nearHotspot(player)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return false end
	local pos = root.Position
	for _, hPos in ipairs(hotspotPositions) do
		if (pos - hPos).Magnitude <= HOTSPOT_RADIUS then
			return true
		end
	end
	return false
end

-- ── Upgrade params ─────────────────────────────────────────────
local function getUpgradeParams(player)
	local data = PlayerData.Get(player)
	if not data then return { rarityBonus=0, fishSpeedMult=1, barBonus=0 } end
	local bait = UpgradeData.Bait[data.baitLevel] or UpgradeData.Bait[1]
	local hook = UpgradeData.Hook[data.hookLevel] or UpgradeData.Hook[1]
	local rod  = UpgradeData.Rod[data.rodLevel]   or UpgradeData.Rod[1]
	return {
		rarityBonus   = bait.rarityBonus,
		fishSpeedMult = hook.fishSpeedMult,
		barBonus      = rod.barBonus,
	}
end

-- ── Fishing loop ───────────────────────────────────────────────
local function runFishingLoop(player)
	local state = playerState[player]
	if not state then return end

	-- Hotspot = 1-4s wait, normal = 4-12s
	local waitMin, waitMax
	if nearHotspot(player) then
		waitMin, waitMax = 1, 4
	else
		waitMin, waitMax = 4, 12
	end
	task.wait(math.random(waitMin, waitMax))

	if not state.isFishing then return end

	local params = getUpgradeParams(player)
	local fish   = pickFishWithBonus(params.rarityBonus)
	state.currentFish = fish
	state.biting      = true

	Remotes.FishBiting:FireClient(player, fish.rarity, fish.name,
		params.fishSpeedMult, params.barBonus)

	-- Safety timeout (90s) — only fires if minigame is somehow stuck
	task.delay(90, function()
		if state.biting then
			state.biting = false
			resetState(player)
			Remotes.FishMissed:FireClient(player)
		end
	end)
end

-- ── Start fishing ──────────────────────────────────────────────
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

-- ── Water detection + ProximityPrompt ─────────────────────────
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
	print("[FishingServer] Added prompt to:", part.Name)
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

-- ── Award caught fish ──────────────────────────────────────────
local STAR_CHANCE_NORMAL = 1/5   -- 20% normally
local STAR_CHANCE_TOURNEY = 1/3  -- 33% during tournament

local function awardFish(player)
	local state = playerState[player]
	if not state or not state.biting or not state.currentFish then return false end

	local fish = state.currentFish
	local size = math.random(fish.minSize, fish.maxSize)

	InventoryServer.AddFish(player, fish.name, size, fish.rarity)

	local data = PlayerData.Get(player)
	if data then
		table.insert(data.inventory, {
			name   = fish.name,
			size   = size,
			rarity = fish.rarity,
			time   = os.time(),
		})

		-- Coins = size-based sell value
		local coins = FishData.SellValue(fish, size)
		data.coins  = data.coins + coins
		Remotes.CoinsUpdate:FireClient(player, data.coins)

		-- Stars: higher chance during tournament
		local inTourney = TournamentServer and TournamentServer.IsActive()
		local starChance = inTourney and STAR_CHANCE_TOURNEY or STAR_CHANCE_NORMAL
		if math.random() < starChance then
			data.stars = data.stars + 1
			Remotes.StarsUpdate:FireClient(player, data.stars)
			print(("[FishingServer] +1 star -> %s (total: %d)"):format(player.Name, data.stars))
		end

		-- Achievement stats
		local stats = data.achievementStats
		stats.totalCaught    += 1
		stats.coinsEarned    += coins
		if fish.rarity == "Uncommon"  then stats.uncommonCaught  += 1 end
		if fish.rarity == "Rare"      then stats.rareCaught      += 1 end
		if fish.rarity == "Legendary" then stats.legendaryCaught += 1 end
		if size > stats.biggestCatch  then stats.biggestCatch = size  end
		if not stats.speciesSet[fish.name] then
			stats.speciesSet[fish.name] = true
			stats.speciesCaught += 1
		end
		checkAchievements(player)

		print(("[FishingServer] %s caught %s %s (%dcm) +%d coins"):format(
			player.Name, fish.rarity, fish.name, size, coins))
	end

	-- Notify TournamentServer of catch
	if TournamentServer then
		TournamentServer.RecordCatch(player)
	end

	Remotes.FishCaught:FireClient(player, {
		name   = fish.name,
		size   = size,
		rarity = fish.rarity,
		color  = fish.color,
		coins  = FishData.SellValue(fish, size),
	})
	resetState(player)
	return true
end

-- ── Minigame handlers ──────────────────────────────────────────
-- Win/loss comes entirely from the minigame progress bar,
-- not a timer. The 90s safety timeout in runFishingLoop is
-- only there as a stuck-game safeguard.
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

-- ── Shop / Upgrades ────────────────────────────────────────────
Remotes.GetUpgrades.OnServerInvoke = function(player)
	local data = PlayerData.Get(player)
	if not data then return { coins=0, stars=0, baitLevel=1, hookLevel=1, rodLevel=1 } end
	return {
		coins     = data.coins,
		stars     = data.stars,
		baitLevel = data.baitLevel,
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
	print(("[FishingServer] %s bought %s L%d (-%d coins, -%d stars)"):format(
		player.Name, upgradeType, targetLevel, tier.cost, starCost))
	return true, targetLevel, data.coins, data.stars
end

-- ── Achievements ───────────────────────────────────────────────
Remotes.GetAchievements.OnServerInvoke = function(player)
	local data = PlayerData.Get(player)
	if not data then return {}, {} end
	return data.achievementStats, data.completedAchievements
end

-- ── Debug (Studio only) ────────────────────────────────────────
Remotes.DebugGiveCoins.OnServerEvent:Connect(function(player, amount)
	if not RunService:IsStudio() then return end
	local data = PlayerData.Get(player)
	if not data then return end
	data.coins = data.coins + (amount or 1000)
	Remotes.CoinsUpdate:FireClient(player, data.coins)
	print(("[DEBUG] +%d coins -> %s"):format(amount or 1000, player.Name))
end)

Remotes.DebugGiveStars.OnServerEvent:Connect(function(player, amount)
	if not RunService:IsStudio() then return end
	local data = PlayerData.Get(player)
	if not data then return end
	data.stars = data.stars + (amount or 20)
	Remotes.StarsUpdate:FireClient(player, data.stars)
	print(("[DEBUG] +%d stars -> %s"):format(amount or 20, player.Name))
end)

-- ── Player lifecycle ───────────────────────────────────────────
local function initPlayer(player)
	local data = PlayerData.Load(player)
	InventoryServer.LoadInventory(player, data.inventory)
	playerState[player] = {
		isFishing   = false,
		biting      = false,
		currentFish = nil,
		bobberPart  = nil,
	}
	task.delay(2, function()
		if player and player.Parent then
			Remotes.CoinsUpdate:FireClient(player, data.coins)
			Remotes.StarsUpdate:FireClient(player, data.stars)
		end
	end)
end

for _, p in ipairs(Players:GetPlayers()) do initPlayer(p) end
Players.PlayerAdded:Connect(initPlayer)

Players.PlayerRemoving:Connect(function(player)
	local state = playerState[player]
	if state then removeBobber(state) end
	PlayerData.Unload(player)
	playerState[player] = nil
end)

print("[FishingServer] Loaded and ready!")
return FishingServer
