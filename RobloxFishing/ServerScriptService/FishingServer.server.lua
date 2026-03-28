-- ============================================================
-- FishingServer.lua  (Script in ServerScriptService)
-- Fishing loop, minigame, upgrades, coins, DataStore, achievements
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

-- ── Per-player state ──────────────────────────────────────────
local playerState     = {}
local tournamentState = {}

-- ── Achievement checker ───────────────────────────────────────
local function checkAchievements(player)
	local data = PlayerData.Get(player)
	if not data then return end

	local stats     = data.achievementStats
	local completed = data.completedAchievements

	-- Keep upgrade level mirrors in sync
	stats.baitLevel = data.baitLevel
	stats.hookLevel = data.hookLevel
	stats.rodLevel  = data.rodLevel
	stats.allMaxed  = (data.baitLevel >= 4 and data.hookLevel >= 4 and data.rodLevel >= 4) and 1 or 0

	for _, ach in ipairs(AchievementData) do
		if not completed[ach.id] then
			local progress = stats[ach.statKey] or 0
			if progress >= ach.goal then
				completed[ach.id] = true
				Remotes.AchievementUnlocked:FireClient(player, {
					id   = ach.id,
					name = ach.name,
					icon = ach.icon,
					desc = ach.desc,
				})
				print(("[Achievements] %s unlocked: %s %s"):format(player.Name, ach.icon, ach.name))
			end
		end
	end
end

-- ── Fish picking with bait rarityBonus ────────────────────────
local function pickFishWithBonus(rarityBonus)
	local bonus = rarityBonus or 0
	local pool, total = {}, 0
	for _, fish in ipairs(FishData.Fish) do
		local mult
		if     fish.rarity == "Common"    then mult = math.max(0.1, 1.0 - bonus * 1.5)
		elseif fish.rarity == "Uncommon"  then mult = 1.0 + bonus
		elseif fish.rarity == "Rare"      then mult = 1.0 + bonus * 4
		elseif fish.rarity == "Legendary" then mult = 1.0 + bonus * 10
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

-- ── Bobber helpers ────────────────────────────────────────────
local function spawnBobber(position)
	local part = Instance.new("Part")
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

-- ── Read current upgrade params for a player ─────────────────
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

-- ── Fishing loop ──────────────────────────────────────────────
local function runFishingLoop(player)
	local state = playerState[player]
	if not state then return end

	task.wait(math.random(3, 10))
	if not state.isFishing then return end

	local params = getUpgradeParams(player)
	local fish   = pickFishWithBonus(params.rarityBonus)
	state.currentFish = fish
	state.biting      = true

	Remotes.FishBiting:FireClient(player, fish.rarity, fish.name,
		params.fishSpeedMult, params.barBonus)

	-- Safety timeout
	task.delay(45, function()
		if state.biting then
			state.biting = false
			resetState(player)
			Remotes.FishMissed:FireClient(player)
		end
	end)
end

-- ── Start fishing ─────────────────────────────────────────────
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

-- ── Water detection + ProximityPrompt ────────────────────────
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
	print("[FishingServer] Added prompt to:", part.Name, "| Material:", part.Material)
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

-- ── Award a caught fish ───────────────────────────────────────
local function awardFish(player)
	local state = playerState[player]
	if not state or not state.biting or not state.currentFish then return false end

	local fish = state.currentFish
	local size = math.random(fish.minSize, fish.maxSize)

	-- In-memory inventory
	InventoryServer.AddFish(player, fish.name, size, fish.rarity)

	-- Persistent data
	local data = PlayerData.Get(player)
	if data then
		table.insert(data.inventory, {
			name   = fish.name,
			size   = size,
			rarity = fish.rarity,
			time   = os.time(),
		})

		-- Coins
		local reward = UpgradeData.CoinRewards[fish.rarity] or 5
		data.coins = data.coins + reward
		Remotes.CoinsUpdate:FireClient(player, data.coins)

		-- Achievement stats
		local stats = data.achievementStats
		stats.totalCaught    += 1
		stats.coinsEarned    += reward
		if fish.rarity == "Uncommon"  then stats.uncommonCaught  += 1 end
		if fish.rarity == "Rare"      then stats.rareCaught      += 1 end
		if fish.rarity == "Legendary" then stats.legendaryCaught += 1 end
		if size > stats.biggestCatch  then stats.biggestCatch = size  end
		if not stats.speciesSet[fish.name] then
			stats.speciesSet[fish.name] = true
			stats.speciesCaught += 1
		end

		checkAchievements(player)
		print(("[FishingServer] +%d coins → %s (total: %d)"):format(reward, player.Name, data.coins))
	end

	-- Tournament tracking
	local ts = tournamentState[player]
	if ts and ts.active then
		ts.fishThisRun += 1
		Remotes.TournamentPoints:FireClient(player, ts.fishThisRun, ts.totalPoints)
	end

	Remotes.FishCaught:FireClient(player, {
		name   = fish.name,
		size   = size,
		rarity = fish.rarity,
		color  = fish.color,
	})
	resetState(player)
	return true
end

-- ── Minigame handlers ─────────────────────────────────────────
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

-- ── Shop / Upgrades ───────────────────────────────────────────
Remotes.GetUpgrades.OnServerInvoke = function(player)
	local data = PlayerData.Get(player)
	if not data then return { coins=0, baitLevel=1, hookLevel=1, rodLevel=1 } end
	return {
		coins     = data.coins,
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
		return false, ("Need %d coins, have %d"):format(tier.cost, data.coins)
	end

	data.coins     = data.coins - tier.cost
	data[levelKey] = targetLevel
	Remotes.CoinsUpdate:FireClient(player, data.coins)

	checkAchievements(player)
	print(("[FishingServer] %s bought %s L%d (-%d coins, left: %d)"):format(
		player.Name, upgradeType, targetLevel, tier.cost, data.coins))
	return true, targetLevel, data.coins
end

-- ── Achievements ──────────────────────────────────────────────
Remotes.GetAchievements.OnServerInvoke = function(player)
	local data = PlayerData.Get(player)
	if not data then return {}, {} end
	return data.achievementStats, data.completedAchievements
end

-- ── Debug: give coins (Studio only) ──────────────────────────
Remotes.DebugGiveCoins.OnServerEvent:Connect(function(player, amount)
	if not RunService:IsStudio() then return end  -- server-side safety check
	local data = PlayerData.Get(player)
	if not data then return end
	data.coins = data.coins + (amount or 1000)
	Remotes.CoinsUpdate:FireClient(player, data.coins)
	print(("[DEBUG] Gave %d coins to %s (total: %d)"):format(amount or 1000, player.Name, data.coins))
end)

-- ── Tournament ────────────────────────────────────────────────
Remotes.JoinTournament.OnServerEvent:Connect(function(player)
	local ts = tournamentState[player]
	if ts and ts.active then return end
	if not ts then
		tournamentState[player] = { active=false, totalPoints=0, fishThisRun=0 }
		ts = tournamentState[player]
	end
	ts.active      = true
	ts.fishThisRun = 0

	local DURATION = 180
	Remotes.TournamentStart:FireClient(player, DURATION)
	print("[FishingServer] Tournament started for", player.Name)

	task.delay(DURATION, function()
		if not ts.active then return end
		ts.active = false
		local runPoints = ts.fishThisRun
		local bonus     = ts.fishThisRun >= 3
		if bonus then runPoints += 2 end
		ts.totalPoints += runPoints

		local trophy = "none"
		local trophyNum = 0
		if     ts.totalPoints >= 30 then trophy = "🥇 Gold Trophy";   trophyNum = 3
		elseif ts.totalPoints >= 15 then trophy = "🥈 Silver Trophy"; trophyNum = 2
		elseif ts.totalPoints >= 5  then trophy = "🥉 Bronze Trophy"; trophyNum = 1
		end

		-- Update achievement stats for trophy
		local data = PlayerData.Get(player)
		if data and trophyNum > (data.achievementStats.trophyLevel or 0) then
			data.achievementStats.trophyLevel = trophyNum
			checkAchievements(player)
		end

		Remotes.TournamentEnd:FireClient(player, {
			fishCaught  = ts.fishThisRun,
			runPoints   = runPoints,
			totalPoints = ts.totalPoints,
			bonus       = bonus,
			trophy      = trophy,
		})
		print("[FishingServer] Tourney ended for", player.Name,
			"| Fish:", ts.fishThisRun, "| Run pts:", runPoints, "| Total:", ts.totalPoints)
		ts.fishThisRun = 0
	end)
end)

-- ── Player lifecycle ──────────────────────────────────────────
local function initPlayer(player)
	local data = PlayerData.Load(player)
	InventoryServer.LoadInventory(player, data.inventory)

	playerState[player] = {
		isFishing   = false,
		biting      = false,
		currentFish = nil,
		bobberPart  = nil,
	}
	tournamentState[player] = {
		active      = false,
		totalPoints = 0,
		fishThisRun = 0,
	}

	task.delay(2, function()
		if player and player.Parent then
			Remotes.CoinsUpdate:FireClient(player, data.coins)
		end
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	initPlayer(player)
end
Players.PlayerAdded:Connect(initPlayer)

Players.PlayerRemoving:Connect(function(player)
	local state = playerState[player]
	if state then removeBobber(state) end
	PlayerData.Unload(player)
	playerState[player]     = nil
	tournamentState[player] = nil
end)

print("[FishingServer] Loaded and ready!")
