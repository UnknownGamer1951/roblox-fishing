-- ============================================================
-- TournamentServer.lua  (Script in ServerScriptService)
-- Server-wide automatic tournament system.
--
-- Schedule:  [WAIT_MINUTES] wait  →  [DURATION_MINUTES] active
--            repeats forever
--
-- During tournament all players compete on a shared leaderboard.
-- At the end:  Top 1   → Gold
--              Top 2-3 → Silver
--              Top 4-8 (or rest who caught ≥1) → Bronze
--
-- Players can also buy an "early start" with Robux (1 gamepass).
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local ServerScriptService = game:GetService("ServerScriptService")

local Remotes    = require(ReplicatedStorage:WaitForChild("FishingRemotes"))
local PlayerData = require(ServerScriptService:WaitForChild("PlayerData"))

-- ── Config ─────────────────────────────────────────────────────
local WAIT_MINUTES     = 20        -- time between tournaments
local DURATION_MINUTES = 5         -- how long each tournament lasts
local EARLY_START_PRODUCT_ID = 0   -- set to your Developer Product ID; 0 = disabled

-- Trophy thresholds (fish caught during the tournament round)
local GOLD_TOP_N   = 1   -- 1st place
local SILVER_TOP_N = 3   -- 2nd–3rd place
-- Everyone else who caught ≥1 fish gets Bronze

-- ── State ──────────────────────────────────────────────────────
local TournamentServer = {}
local isActive         = false
local leaderboard      = {}   -- [player] = fishCaught
local secondsUntilNext = WAIT_MINUTES * 60

-- ── Public API (FishingServer reads these) ─────────────────────
function TournamentServer.IsActive()
	return isActive
end

function TournamentServer.RecordCatch(player)
	if not isActive then return end
	leaderboard[player] = (leaderboard[player] or 0) + 1
	-- Broadcast updated leaderboard to all
	local lb = TournamentServer.GetLeaderboardData()
	Remotes.TournamentPoints:FireAllClients(leaderboard[player] or 0, lb)
end

function TournamentServer.GetLeaderboardData()
	-- Sort players by fish caught descending
	local entries = {}
	for player, count in pairs(leaderboard) do
		if player and player.Parent then
			table.insert(entries, { name = player.Name, count = count, player = player })
		end
	end
	table.sort(entries, function(a, b) return a.count > b.count end)
	return entries
end

-- ── Countdown broadcast (fires every second to all clients) ────
local function broadcastCountdown()
	Remotes.TournamentCountdown:FireAllClients(secondsUntilNext, isActive)
end

-- ── Award trophies at end ──────────────────────────────────────
local function awardTrophies(entries)
	for rank, entry in ipairs(entries) do
		local player    = entry.player
		local trophyNum = 0
		local trophyStr = "none"

		if rank <= GOLD_TOP_N then
			trophyNum = 3
			trophyStr = "Gold"
		elseif rank <= SILVER_TOP_N then
			trophyNum = 2
			trophyStr = "Silver"
		elseif entry.count >= 1 then
			trophyNum = 1
			trophyStr = "Bronze"
		end

		if trophyNum > 0 and player and player.Parent then
			local data = PlayerData.Get(player)
			if data and trophyNum > (data.achievementStats.trophyLevel or 0) then
				data.achievementStats.trophyLevel = trophyNum
			end
		end

		print(("[TournamentServer] Rank %d: %s — %d fish — %s"):format(
			rank, entry.name, entry.count, trophyStr))
	end
end

-- ── End tournament ─────────────────────────────────────────────
local function endTournament()
	isActive = false
	local entries = TournamentServer.GetLeaderboardData()
	awardTrophies(entries)

	-- Build per-player result and fire TournamentEnd to each
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
				rank       = rank,
				fishCaught = entry.count,
				trophy     = trophyStr,
				leaderboard = entries,   -- full sorted list for display
			})
		end
	end

	-- Fire to players who didn't catch anything
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

	leaderboard = {}
	secondsUntilNext = WAIT_MINUTES * 60
	print("[TournamentServer] Tournament ended.")
end

-- ── Start tournament ───────────────────────────────────────────
local function startTournament()
	if isActive then return end
	isActive   = true
	leaderboard = {}

	local duration = DURATION_MINUTES * 60
	Remotes.TournamentStart:FireAllClients(duration)
	print("[TournamentServer] Tournament started! Duration:", duration, "s")

	task.delay(duration, endTournament)
end

-- ── Main countdown loop ────────────────────────────────────────
task.spawn(function()
	-- Initial delay so server fully loads
	task.wait(5)

	while true do
		if not isActive then
			secondsUntilNext -= 1
			if secondsUntilNext <= 0 then
				startTournament()
			end
		else
			-- During active tournament count down the active phase
			-- (TournamentStart fires with duration; clients handle their own countdown)
			secondsUntilNext = 0
		end
		broadcastCountdown()
		task.wait(1)
	end
end)

-- ── Robux early-start (Developer Product purchase) ─────────────
if EARLY_START_PRODUCT_ID ~= 0 then
	MarketplaceService.ProcessReceipt = function(info)
		if info.ProductId == EARLY_START_PRODUCT_ID then
			local player = Players:GetPlayerByUserId(info.PlayerId)
			if player then
				print(("[TournamentServer] %s bought early tournament start"):format(player.Name))
				if not isActive then
					secondsUntilNext = 0   -- trigger on next tick
				end
			end
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

-- Client fires BuyTournament as a free "vote early" alternative (no Robux)
-- (disabled in production; useful for testing)
Remotes.BuyTournament.OnServerEvent:Connect(function(_player)
	-- No-op in live; for Studio testing force-start
	local RunService = game:GetService("RunService")
	if RunService:IsStudio() then
		if not isActive then
			secondsUntilNext = 0
			print("[TournamentServer] Studio force-start triggered")
		end
	end
end)

print("[TournamentServer] Loaded — next tournament in", WAIT_MINUTES, "min.")
return TournamentServer
