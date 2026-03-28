-- ============================================================
-- InventoryServer.lua  (ModuleScript in ServerScriptService)
-- In-memory fish inventory. FishingServer seeds it from
-- PlayerData on join and updates it on every catch.
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes           = require(ReplicatedStorage:WaitForChild("FishingRemotes"))

local InventoryServer = {}
local inventories     = {}  -- [player] = { {name,size,rarity,time}, ... }

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

-- Called on each successful catch
function InventoryServer.AddFish(player, name, size, rarity)
	local inv = inventories[player]
	if not inv then return end
	table.insert(inv, { name=name, size=size, rarity=rarity, time=os.time() })
	print(("[InventoryServer] %s caught a %s (%s, %dcm)"):format(player.Name, name, rarity, size))
end

-- Returns the full list for a player
function InventoryServer.GetInventory(player)
	return inventories[player] or {}
end

-- Client asks for inventory list
Remotes.GetInventory.OnServerInvoke = function(player)
	return InventoryServer.GetInventory(player)
end

-- Create empty table on join (FishingServer.initPlayer will seed it)
Players.PlayerAdded:Connect(function(player)
	inventories[player] = {}
end)

Players.PlayerRemoving:Connect(function(player)
	inventories[player] = nil
end)

print("[InventoryServer] Loaded and ready!")
return InventoryServer
