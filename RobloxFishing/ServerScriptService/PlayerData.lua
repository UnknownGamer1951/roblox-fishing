-- ============================================================
-- PlayerData.lua  (ModuleScript in ServerScriptService)
-- DataStore-backed persistence for per-player progress.
-- Saves: coins, upgrade levels (bait/hook/rod), fish inventory.
-- ============================================================

local DataStoreService = game:GetService("DataStoreService")

local store = DataStoreService:GetDataStore("RoFish_v1")

local PlayerData = {}
local cache      = {}  -- [player] = live data table

local DEFAULT = {
	coins     = 0,
	baitLevel = 1,
	hookLevel = 1,
	rodLevel  = 1,
	inventory = {},
}

local function deepCopy(t)
	local copy = {}
	for k, v in pairs(t) do
		copy[k] = type(v) == "table" and deepCopy(v) or v
	end
	return copy
end

-- Load from DataStore (or defaults for a new player)
function PlayerData.Load(player)
	local key = "player_" .. player.UserId
	local ok, data = pcall(function() return store:GetAsync(key) end)
	if ok and type(data) == "table" then
		local merged = deepCopy(DEFAULT)
		for k, v in pairs(data) do merged[k] = v end
		cache[player] = merged
	else
		if not ok then warn("[PlayerData] Load error for", player.Name, ":", data) end
		cache[player] = deepCopy(DEFAULT)
	end
	local d = cache[player]
	print(("[PlayerData] Loaded %s | Coins:%d Bait:%d Hook:%d Rod:%d Fish:%d"):format(
		player.Name, d.coins, d.baitLevel, d.hookLevel, d.rodLevel, #d.inventory))
	return cache[player]
end

-- Save to DataStore
function PlayerData.Save(player)
	local data = cache[player]
	if not data then return end
	local key = "player_" .. player.UserId
	local ok, err = pcall(function() store:SetAsync(key, data) end)
	if ok then
		print("[PlayerData] Saved for", player.Name)
	else
		warn("[PlayerData] Save failed for", player.Name, ":", err)
	end
end

-- Get live data table (nil if not loaded)
function PlayerData.Get(player)
	return cache[player]
end

-- Save + evict from cache (call on PlayerRemoving)
function PlayerData.Unload(player)
	PlayerData.Save(player)
	cache[player] = nil
end

-- Auto-save every 60 s for all cached players
task.spawn(function()
	while true do
		task.wait(60)
		for player in pairs(cache) do
			if player and player.Parent then
				PlayerData.Save(player)
			end
		end
	end
end)

return PlayerData
