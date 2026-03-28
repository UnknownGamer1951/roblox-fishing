-- ============================================================
-- InventoryServer.lua
-- Location in Studio: ServerScriptService > InventoryServer (ModuleScript)
--
-- Stores each player's caught fish.
-- FishingServer.lua calls AddFish() when a catch succeeds.
-- The client can call GetInventory remote to read the list.
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes           = require(ReplicatedStorage:WaitForChild("FishingRemotes"))

local InventoryServer = {}

-- inventories[player] = list of caught fish entries
local inventories = {}

-- -------------------------------------------------------
-- AddFish(player, name, size, rarity)
-- Called by FishingServer when the player catches a fish.
-- -------------------------------------------------------
function InventoryServer.AddFish(player, name, size, rarity)
    local inv = inventories[player]
    if not inv then return end

    table.insert(inv, {
        name   = name,
        size   = size,        -- number in cm
        rarity = rarity,
        time   = os.time(),   -- Unix timestamp of the catch
    })

    print(("[InventoryServer] %s caught a %s (%s, %dcm)"):format(
        player.Name, name, rarity, size
    ))
end

-- -------------------------------------------------------
-- GetInventory(player) -> list of fish entries
-- -------------------------------------------------------
function InventoryServer.GetInventory(player)
    return inventories[player] or {}
end

-- -------------------------------------------------------
-- Respond to client requests for inventory data
-- -------------------------------------------------------
Remotes.GetInventory.OnServerInvoke = function(player)
    return InventoryServer.GetInventory(player)
end

-- -------------------------------------------------------
-- Initialize inventory when a player joins
-- -------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
    inventories[player] = {}
end)

-- -------------------------------------------------------
-- Clean up when a player leaves
-- -------------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
    inventories[player] = nil
end)

print("[InventoryServer] Loaded and ready!")

return InventoryServer
