-- ============================================================
-- TournamentServer.lua  (ModuleScript in ServerScriptService)
-- NOTE: Must be a ModuleScript (.lua) so FishingServer can require() it.
-- The tournament loop starts automatically when this module is first required.
--
-- Schedule: [WAIT_MINUTES] wait -> [DURATION_MINUTES] active, repeats forever.
-- ============================================================

local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Remotes    = require(ReplicatedStorage:WaitForChild("FishingRemotes"))

-- PlayerData required lazily to avoid circular require
local function getPlayerData(player)
	local SSS = game:GetService("ServerScriptService")
	local ok, pd = pcall(function() return require(SSS:WaitForChild("PlayerData")) end)
	if ok and pd then return pd.Get(player) end
end

-- ── Config ─────────────────────────────────────────────────
local WAIT_MINUTES     = 20
local DURATION_MINUTES = 5
local EARLY_START_PRODUCT_ID = 0   -- 0 = disabled

local GOLD_TOP_N   = 1
local SILVER_TOP_N = 3

-- ── State ──────────────────────────────────────────────────
local TournamentServer = {}
local isActive         = false
local leaderboard      = {}
local secondsUntilNext = WAIT_MINUTES * 60

-- ── Public API ─────────────────────────────────────────────
function TournamentServer.IsActive()
	return isActive
end

function TournamentServer.RecordCatch(player)
	if not isActive then return end
	leaderboard[player] = (leaderboard[player] or 0) + 1
	local lb = TournamentServer.GetLeaderboardData()
	Remotes.TournamentPoints:FireAllClients(leaderboard[player] or 0, lb)
end

function TournamentServer.GetLeaderboardData()
	local entries = {}
	for player, count in pairs(leaderboard) do
		if player and player.Parent then
			table.insert(entries, { name = player.Name, count = count, player = player })
		end
	end
	table.sort(entries, function(a, b) return a.count > b.count end)
	return entries
end

-- ── Internal ───────────────────────────────────────────────
local function broadcastCountdown()
	Remotes.TournamentCountdown:FireAllClients(secondsUntilNext, isActive)
end

local function awardTrophies(entries)
	for rank, entry in ipairs(entries) do
		local player    = entry.player
		local trophyNum = 0
		if rank <= GOLD_TOP_N        then trophyNum = 3
		elseif rank <= SILVER_TOP_N  then trophyNum = 2
		elseif entry.count >= 1      then trophyNum = 1
		end
		if trophyNum > 0 and player and player.Parent then
			local data = getPlayerData(player)
			if data and trophyNum > (data.achievementStats.trophyLevel or 0) then
				data.achievementStats.trophyLevel = trophyNum
			end
		end
	end
end

local function endTournament()
	isActive = false
	local entries = TournamentServer.GetLeaderboardData()
	awardTrophies(entries)

	for rank, entry in ipairs(entries) do
		local player = entry.player
		if player and player.Parent then
			local trophyStr
			if rank <= GOLD_TOP_N        then trophyStr = "Gold"
			elseif rank <= SILVER_TOP_N  then trophyStr = "Silver"
			elseif entry.count >= 1      then trophyStr = "Bronze"
			else                              trophyStr = "none"
			end
			Remotes.TournamentEnd:FireClient(player, {
				rank        = rank,
				fishCaught  = entry.count,
				trophy      = trophyStr,
				bonus       = entry.count >= 3,
				leaderboard = entries,
			})
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if not leaderboard[player] then
			Remotes.TournamentEnd:FireClient(player, {
				rank        = 0,
				fishCaught  = 0,
				trophy      = "none",
				leaderboard = entries,
			})
		end
	end

	leaderboard      = {}
	secondsUntilNext = WAIT_MINUTES * 60
	print("[TournamentServer] Tournament ended.")
end

local function startTournament()
	if isActive then return end
	isActive    = true
	leaderboard = {}
	local duration = DURATION_MINUTES * 60
	-- secondsUntilNext during active phase counts down the active duration
	secondsUntilNext = duration
	Remotes.TournamentStart:FireAllClients(duration)
	print("[TournamentServer] Tournament started! Duration:", duration, "s")
	task.delay(duration, endTournament)
end

-- ── Main countdown loop (starts on require) ────────────────
task.spawn(function()
	task.wait(5)   -- let server fully load
	while true do
		if not isActive then
			secondsUntilNext = math.max(0, secondsUntilNext - 1)
			if secondsUntilNext <= 0 then
				startTournament()
			end
		else
			-- Active phase: count down remaining time
			secondsUntilNext = math.max(0, secondsUntilNext - 1)
		end
		broadcastCountdown()
		task.wait(1)
	end
end)

-- ── Robux early-start ─────────────────────────────────────
if EARLY_START_PRODUCT_ID ~= 0 then
	MarketplaceService.ProcessReceipt = function(info)
		if info.ProductId == EARLY_START_PRODUCT_ID then
			local player = Players:GetPlayerByUserId(info.PlayerId)
			if player and not isActive then secondsUntilNext = 0 end
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

-- Studio force-start via BuyTournament remote
Remotes.BuyTournament.OnServerEvent:Connect(function(_player)
	local RunService = game:GetService("RunService")
	if RunService:IsStudio() and not isActive then
		secondsUntilNext = 0
		print("[TournamentServer] Studio force-start triggered")
	end
end)

print("[TournamentServer] Loaded — next tournament in", WAIT_MINUTES, "min.")
return TournamentServer
