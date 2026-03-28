-- ============================================================
-- FishingServer.lua
-- Location in Studio: ServerScriptService > FishingServer (Script)
--
-- This is the "brain" of the fishing system.
-- It runs on Roblox's servers, NOT on each player's screen.
-- It decides when fish bite, which fish was caught, etc.
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Load our shared modules
local FishData    = require(ReplicatedStorage:WaitForChild("FishData"))
local Remotes     = require(ReplicatedStorage:WaitForChild("FishingRemotes"))

-- -------------------------------------------------------
-- Per-player state table.
-- Tracks whether each player is currently fishing.
-- -------------------------------------------------------
local playerState = {}
-- playerState[player] looks like:
-- {
--     isFishing   = true/false,
--     biting      = true/false,
--     currentFish = <fish data table or nil>,
--     bobberPart  = <BasePart or nil>,    -- the physical bobber in the world
-- }

-- -------------------------------------------------------
-- Utility: Check whether a position is on or near a water part.
-- Water parts must be named "Water".
-- -------------------------------------------------------
local function isNearWater(position)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "Water" then
            -- Build an AABB check with a small tolerance (2 studs)
            local halfSize = obj.Size / 2 + Vector3.new(2, 4, 2)
            local local_pos = obj.CFrame:PointToObjectSpace(position)
            if math.abs(local_pos.X) <= halfSize.X
            and math.abs(local_pos.Y) <= halfSize.Y
            and math.abs(local_pos.Z) <= halfSize.Z then
                return true
            end
        end
    end
    return false
end

-- -------------------------------------------------------
-- Utility: Create a simple bobber part in the world
-- -------------------------------------------------------
local function spawnBobber(position)
    local part = Instance.new("Part")
    part.Name      = "Bobber"
    part.Size      = Vector3.new(0.5, 0.5, 0.5)
    part.Shape     = Enum.PartType.Ball
    part.BrickColor = BrickColor.new("Bright red")
    part.Material  = Enum.Material.SmoothPlastic
    part.Anchored  = true
    part.CanCollide = false
    part.CastShadow = false
    part.Position  = position
    part.Parent    = workspace
    return part
end

-- -------------------------------------------------------
-- Utility: Remove the bobber from the world
-- -------------------------------------------------------
local function removeBobber(state)
    if state.bobberPart then
        state.bobberPart:Destroy()
        state.bobberPart = nil
    end
end

-- -------------------------------------------------------
-- Utility: Reset a player's fishing state to idle
-- -------------------------------------------------------
local function resetState(player)
    local state = playerState[player]
    if state then
        removeBobber(state)
        state.isFishing    = false
        state.biting       = false
        state.currentFish  = nil
    end
end

-- -------------------------------------------------------
-- Main fishing loop (runs in a separate thread per cast)
-- -------------------------------------------------------
local function runFishingLoop(player)
    local state = playerState[player]
    if not state then return end

    -- Wait a random time before a fish starts nibbling (3 to 12 seconds)
    local waitTime = math.random(3, 12)
    task.wait(waitTime)

    -- Make sure the player is still fishing (they didn't leave, etc.)
    if not state.isFishing then return end

    -- Pick which fish will bite
    local fish = FishData.PickRandomFish()
    state.currentFish = fish
    state.biting      = true

    -- Tell the player a fish is biting!
    Remotes.FishBiting:FireClient(player, fish.rarity)

    -- The player has a short window to click "Reel In"
    -- Window length depends on rarity (harder fish = shorter window)
    local windowSeconds = 4
    if fish.rarity == "Uncommon"  then windowSeconds = 3 end
    if fish.rarity == "Rare"      then windowSeconds = 2.5 end
    if fish.rarity == "Legendary" then windowSeconds = 2 end

    task.wait(windowSeconds)

    -- If biting is still true, the player missed the window
    if state.biting then
        state.biting      = false
        state.currentFish = nil
        state.isFishing   = false
        removeBobber(state)
        Remotes.FishMissed:FireClient(player)
    end
end

-- -------------------------------------------------------
-- Handle: Player casts their line
-- -------------------------------------------------------
Remotes.CastLine.OnServerEvent:Connect(function(player, castDirection)
    local state = playerState[player]
    if not state then return end

    -- Don't allow casting while already fishing
    if state.isFishing then return end

    state.isFishing   = true
    state.biting      = false
    state.currentFish = nil

    -- Find a landing spot for the bobber.
    -- castDirection is a Vector3 sent from the client (a point in the world).
    -- We drop the bobber right at that point, slightly above ground.
    local landPos = castDirection + Vector3.new(0, 0.3, 0)

    -- Server-side water validation: reject casts that don't land on water
    if not isNearWater(landPos) then
        state.isFishing = false
        return
    end

    -- Spawn the bobber visually
    removeBobber(state)
    state.bobberPart = spawnBobber(landPos)

    -- Tell the client where the bobber landed so they can animate the line
    Remotes.BobberLanded:FireClient(player, landPos)

    -- Start the fish waiting loop in a separate thread
    task.spawn(runFishingLoop, player)
end)

-- -------------------------------------------------------
-- Handle: Player clicks to reel in
-- -------------------------------------------------------
Remotes.ReelIn.OnServerEvent:Connect(function(player)
    local state = playerState[player]
    if not state then return end

    if state.biting and state.currentFish then
        -- SUCCESS: player clicked in time
        local fish = state.currentFish

        -- Pick a random size for this catch
        local size = math.random(fish.minSize, fish.maxSize)

        -- Save to inventory (see InventoryServer.lua)
        local inventoryModule = require(game.ServerScriptService:WaitForChild("InventoryServer"))
        inventoryModule.AddFish(player, fish.name, size, fish.rarity)

        -- Tell the client what they caught
        Remotes.FishCaught:FireClient(player, {
            name   = fish.name,
            size   = size,
            rarity = fish.rarity,
            color  = fish.color,
        })

        resetState(player)
    else
        -- Clicked too early or when nothing was biting
        -- Just allow them to reel in and reset
        resetState(player)
    end
end)

-- -------------------------------------------------------
-- Set up state when a player joins
-- -------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
    playerState[player] = {
        isFishing   = false,
        biting      = false,
        currentFish = nil,
        bobberPart  = nil,
    }
end)

-- -------------------------------------------------------
-- Clean up when a player leaves
-- -------------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
    local state = playerState[player]
    if state then
        removeBobber(state)
    end
    playerState[player] = nil
end)

print("[FishingServer] Loaded and ready!")
