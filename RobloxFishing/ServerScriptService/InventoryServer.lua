-- ============================================================
-- InventoryServer.lua  (ModuleScript in ServerScriptService)
-- In-memory fish inventory. FishingServer seeds it on join.
-- Exposes SellFish so players can sell individual fish.
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes           = require(ReplicatedStorage:WaitForChild("FishingRemotes"))
local FishData          = require(ReplicatedStorage:WaitForChild("FishData"))

local InventoryServer = {}
local inventories     = {}   -- [player] = { {name,size,rarity,time}, ... }

-- Called by FishingServer.initPlayer to restore saved fish
function InventoryServer.LoadInventory(player, fishList)
	inventories[player] = {}
	if fishList then
		for _, entry in ipairs(fishList) do
			table.insert(inventories[player], entry)
		end
	end
	print(("[InventoryServer] Seeded %d fish for %s"):format(#inventories[player], player.Name))
end

-- Called on each successful catch (fish go to inventory only, NOT auto-sold)
function InventoryServer.AddFish(player, name, size, rarity)
	local inv = inventories[player]
	if not inv then return end
	table.insert(inv, { name=name, size=size, rarity=rarity, time=os.time() })
end

function InventoryServer.GetInventory(player)
	return inventories[player] or {}
end

-- Remove fish by 1-based index, return the fish entry or nil
function InventoryServer.RemoveFishAt(player, index)
	local inv = inventories[player]
	if not inv then return nil end
	if index < 1 or index > #inv then return nil end
	return table.remove(inv, index)
end

-- Client reads full inventory
Remotes.GetInventory.OnServerInvoke = function(player)
	return InventoryServer.GetInventory(player)
end

-- Client sells a single fish by 1-based index
-- Returns (success, coinsDelta, newTotal) or (false, errorMsg)
Remotes.SellFish.OnServerInvoke = function(player, index)
	local fish = InventoryServer.RemoveFishAt(player, index)
	if not fish then
		return false, "Invalid fish index"
	end

	-- Look up fish definition for sell value
	local fishDef
	for _, def in ipairs(FishData.Fish) do
		if def.name == fish.name then fishDef = def; break end
	end
	local coins = fishDef and FishData.SellValue(fishDef, fish.size) or 1

	-- Update PlayerData
	local ServerScriptService = game:GetService("ServerScriptService")
	local ok, PlayerData = pcall(function()
		return require(ServerScriptService:WaitForChild("PlayerData"))
	end)
	if ok and PlayerData then
		local data = PlayerData.Get(player)
		if data then
			data.coins = data.coins + coins
			data.achievementStats.coinsEarned = data.achievementStats.coinsEarned + coins
			-- Also keep persistent inventory in sync
			data.inventory = InventoryServer.GetInventory(player)
			Remotes.CoinsUpdate:FireClient(player, data.coins)
		end
	end

	print(("[InventoryServer] %s sold %s (%dcm) for %d coins"):format(
		player.Name, fish.name, fish.size, coins))
	return true, coins
end

Players.PlayerAdded:Connect(function(player)
	inventories[player] = {}
end)

Players.PlayerRemoving:Connect(function(player)
	inventories[player] = nil
end)

print("[InventoryServer] Loaded!")
return InventoryServer
