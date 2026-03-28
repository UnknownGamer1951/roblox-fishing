-- ============================================================
-- FishingServer.lua
-- Location in Studio: ServerScriptService > FishingServer (Script)
--
-- Automatically adds a "Press E to Fish" ProximityPrompt to any
-- water part in the workspace (detected by material or name).
-- When triggered, starts the fishing loop for that player.
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishData = require(ReplicatedStorage:WaitForChild("FishData"))
local Remotes  = require(ReplicatedStorage:WaitForChild("FishingRemotes"))

-- -------------------------------------------------------
-- Per-player fishing state
-- -------------------------------------------------------
local playerState = {}

-- -------------------------------------------------------
-- Utility: is this part a water part?
-- Matches Water material OR name containing "water"
-- -------------------------------------------------------
local function isWaterPart(part)
    if not part:IsA("BasePart") then return false end
    if part.Material == Enum.Material.Water then return true end
    local name = part.Name:lower()
    if name:find("water") then return true end
    if part.Parent and part.Parent.Name:lower():find("water") then return true end
    return false
end

-- -------------------------------------------------------
-- Utility: bobber sphere
-- -------------------------------------------------------
local function spawnBobber(position)
    local part = Instance.new("Part")
    part.Name        = "Bobber"
    part.Size        = Vector3.new(0.5, 0.5, 0.5)
    part.Shape       = Enum.PartType.Ball
    part.BrickColor  = BrickColor.new("Bright red")
    part.Material    = Enum.Material.SmoothPlastic
    part.Anchored    = true
    part.CanCollide  = false
    part.CastShadow  = false
    part.Position    = position
    part.Parent      = workspace
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

-- -------------------------------------------------------
-- Main fishing loop
-- -------------------------------------------------------
local function runFishingLoop(player)
    local state = playerState[player]
    if not state then return end

    local waitTime = math.random(3, 12)
    task.wait(waitTime)

    if not state.isFishing then return end

    local fish = FishData.PickRandomFish()
    state.currentFish = fish
    state.biting      = true

    Remotes.FishBiting:FireClient(player, fish.rarity)

    local windowSeconds = 4
    if fish.rarity == "Uncommon"  then windowSeconds = 3   end
    if fish.rarity == "Rare"      then windowSeconds = 2.5 end
    if fish.rarity == "Legendary" then windowSeconds = 2   end

    task.wait(windowSeconds)

    if state.biting then
        state.biting      = false
        state.currentFish = nil
        state.isFishing   = false
        removeBobber(state)
        Remotes.FishMissed:FireClient(player)
    end
end

-- -------------------------------------------------------
-- Start fishing for a player at a given water part
-- -------------------------------------------------------
local function startFishing(player, waterPart)
    local state = playerState[player]
    if not state or state.isFishing then return end

    state.isFishing   = true
    state.biting      = false
    state.currentFish = nil

    -- Place the bobber on the water surface near the player
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

-- -------------------------------------------------------
-- Add a ProximityPrompt to a water part
-- -------------------------------------------------------
local function addPromptToWaterPart(part)
    if not isWaterPart(part) then return end
    if part:FindFirstChildOfClass("ProximityPrompt") then return end -- already has one

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText            = "Fish"
    prompt.ObjectText            = "Water"
    prompt.KeyboardKeyCode       = Enum.KeyCode.E
    prompt.HoldDuration          = 0
    prompt.MaxActivationDistance = 20
    prompt.Parent                = part

    print("[FishingServer] Added fishing prompt to:", part.Name, "| Material:", part.Material, "| Parent:", part.Parent and part.Parent.Name)

    prompt.Triggered:Connect(function(player)
        print("[FishingServer] Prompt triggered by", player.Name)
        startFishing(player, part)
    end)
end

-- -------------------------------------------------------
-- Scan workspace for water parts and add prompts
-- Runs once on load, then watches for new parts
-- -------------------------------------------------------
local function setupWaterPrompts()
    local count = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            addPromptToWaterPart(obj)
            if obj:FindFirstChildOfClass("ProximityPrompt") then count += 1 end
        end
    end
    print("[FishingServer] Water scan complete. Prompts on", count, "part(s).")
end

workspace.DescendantAdded:Connect(function(obj)
    addPromptToWaterPart(obj)
end)

-- Run immediately and again after a delay to catch all parts
setupWaterPrompts()
task.delay(3, setupWaterPrompts)

-- -------------------------------------------------------
-- Handle: Player clicks to reel in (fired by client)
-- -------------------------------------------------------
Remotes.ReelIn.OnServerEvent:Connect(function(player)
    local state = playerState[player]
    if not state then return end

    if state.biting and state.currentFish then
        local fish = state.currentFish
        local size = math.random(fish.minSize, fish.maxSize)

        local inventoryModule = require(game.ServerScriptService:WaitForChild("InventoryServer"))
        inventoryModule.AddFish(player, fish.name, size, fish.rarity)

        Remotes.FishCaught:FireClient(player, {
            name   = fish.name,
            size   = size,
            rarity = fish.rarity,
            color  = fish.color,
        })

        resetState(player)
    else
        resetState(player)
    end
end)

-- -------------------------------------------------------
-- Player lifecycle
-- -------------------------------------------------------
local function initPlayer(player)
    playerState[player] = {
        isFishing   = false,
        biting      = false,
        currentFish = nil,
        bobberPart  = nil,
    }
end

-- Handle players who joined before this script loaded (Studio solo playtest)
for _, player in ipairs(Players:GetPlayers()) do
    initPlayer(player)
end

Players.PlayerAdded:Connect(initPlayer)

Players.PlayerRemoving:Connect(function(player)
    local state = playerState[player]
    if state then removeBobber(state) end
    playerState[player] = nil
end)

print("[FishingServer] Loaded and ready!")
