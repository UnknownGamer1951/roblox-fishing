-- ============================================================
-- PlayerData.lua  (ModuleScript in ServerScriptService)
-- DataStore-backed persistence per player.
-- ============================================================

local DataStoreService = game:GetService("DataStoreService")
local store = DataStoreService:GetDataStore("RoFish_v2")

local PlayerData = {}
local cache      = {}

local DEFAULT = {
	coins     = 0,
	stars     = 0,
	baitLevel = 1,
	hookLevel = 1,
	rodLevel  = 1,
	inventory = {},
	achievementStats = {
		totalCaught     = 0,
		uncommonCaught  = 0,
		rareCaught      = 0,
		legendaryCaught = 0,
		biggestCatch    = 0,
		speciesCaught   = 0,
		speciesSet      = {},
		coinsEarned     = 0,
		baitLevel       = 1,
		hookLevel       = 1,
		rodLevel        = 1,
		allMaxed        = 0,
		trophyLevel     = 0,
	},
	completedAchievements = {},
}

local function deepCopy(t)
	local copy = {}
	for k, v in pairs(t) do
		copy[k] = type(v) == "table" and deepCopy(v) or v
	end
	return copy
end

function PlayerData.Load(player)
	local key = "player_" .. player.UserId
	local ok, data = pcall(function() return store:GetAsync(key) end)
	if ok and type(data) == "table" then
		local merged = deepCopy(DEFAULT)
		for k, v in pairs(data) do merged[k] = v end
		if not merged.achievementStats then
			merged.achievementStats = deepCopy(DEFAULT.achievementStats)
		end
		if not merged.achievementStats.speciesSet then
			merged.achievementStats.speciesSet = {}
		end
		if not merged.completedAchievements then
			merged.completedAchievements = {}
		end
		if merged.stars == nil then merged.stars = 0 end
		cache[player] = merged
	else
		if not ok then warn("[PlayerData] Load error for", player.Name, ":", data) end
		cache[player] = deepCopy(DEFAULT)
	end
	local d = cache[player]
	print(("[PlayerData] Loaded %s | Coins:%d Stars:%d Bait:%d Hook:%d Rod:%d Fish:%d"):format(
		player.Name, d.coins, d.stars, d.baitLevel, d.hookLevel, d.rodLevel, #d.inventory))
	return cache[player]
end

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

function PlayerData.Get(player)
	return cache[player]
end

function PlayerData.Unload(player)
	PlayerData.Save(player)
	cache[player] = nil
end

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
