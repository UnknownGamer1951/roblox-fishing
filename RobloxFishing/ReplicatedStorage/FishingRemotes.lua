-- ============================================================
-- FishingRemotes.lua
-- Location in Studio: ReplicatedStorage > FishingRemotes (ModuleScript)
--
-- Creates the RemoteEvents and RemoteFunctions that let the
-- client (player's screen) talk to the server (Roblox backend).
-- Both sides require() this module to get the same objects.
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

-- Helper: get or create a RemoteEvent inside ReplicatedStorage
local function getOrCreate(className, name)
    local existing = ReplicatedStorage:FindFirstChild(name)
    if existing then
        return existing
    end
    local obj = Instance.new(className)
    obj.Name = name
    obj.Parent = ReplicatedStorage
    return obj
end

-- Player tells the server they want to cast their line
Remotes.CastLine    = getOrCreate("RemoteEvent",    "CastLine")

-- Server tells the player their bobber is at a position
Remotes.BobberLanded = getOrCreate("RemoteEvent",   "BobberLanded")

-- Server fires this when a fish is nibbling (time to click!)
Remotes.FishBiting  = getOrCreate("RemoteEvent",    "FishBiting")

-- Player tells server they clicked to reel in
Remotes.ReelIn      = getOrCreate("RemoteEvent",    "ReelIn")

-- Server fires this with the caught fish data
Remotes.FishCaught  = getOrCreate("RemoteEvent",    "FishCaught")

-- Server fires this when the player missed (clicked too late / too early)
Remotes.FishMissed  = getOrCreate("RemoteEvent",    "FishMissed")

-- Client asks server for the player's inventory list
Remotes.GetInventory = getOrCreate("RemoteFunction", "GetInventory")

return Remotes
