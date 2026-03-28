-- ============================================================
-- FishData.lua
-- Location in Studio: ReplicatedStorage > FishData (ModuleScript)
--
-- This module holds all the fish types in the game.
-- You can add more fish here later without touching anything else.
-- ============================================================

local FishData = {}

-- Each fish has:
--   name      - display name shown to the player
--   rarity    - "Common", "Uncommon", "Rare", "Legendary"
--   weight    - chance weight (higher = shows up more often)
--   minSize   - smallest possible size in cm
--   maxSize   - biggest possible size in cm
--   color     - BrickColor name for the fish part in the world

FishData.Fish = {
    {
        name    = "Bluegill",
        rarity  = "Common",
        weight  = 50,
        minSize = 10,
        maxSize = 25,
        color   = "Bright blue",
    },
    {
        name    = "Catfish",
        rarity  = "Common",
        weight  = 40,
        minSize = 20,
        maxSize = 60,
        color   = "Dark grey",
    },
    {
        name    = "Bass",
        rarity  = "Uncommon",
        weight  = 25,
        minSize = 25,
        maxSize = 55,
        color   = "Olive",
    },
    {
        name    = "Trout",
        rarity  = "Uncommon",
        weight  = 20,
        minSize = 20,
        maxSize = 50,
        color   = "Medium green",
    },
    {
        name    = "Pike",
        rarity  = "Rare",
        weight  = 8,
        minSize = 40,
        maxSize = 90,
        color   = "Dark green",
    },
    {
        name    = "Golden Koi",
        rarity  = "Rare",
        weight  = 5,
        minSize = 30,
        maxSize = 70,
        color   = "Bright yellow",
    },
    {
        name    = "Moonfish",
        rarity  = "Legendary",
        weight  = 1,
        minSize = 60,
        maxSize = 120,
        color   = "White",
    },
    {
        name    = "Void Eel",
        rarity  = "Legendary",
        weight  = 1,
        minSize = 80,
        maxSize = 150,
        color   = "Black",
    },
}

-- -------------------------------------------------------
-- PickRandomFish()
-- Returns one fish table chosen by weighted random.
-- You don't need to call this yourself; FishingServer does.
-- -------------------------------------------------------
function FishData.PickRandomFish()
    -- Add up all the weights so we know the total pool size
    local totalWeight = 0
    for _, fish in ipairs(FishData.Fish) do
        totalWeight = totalWeight + fish.weight
    end

    -- Roll a random number inside the pool
    local roll = math.random(1, totalWeight)

    -- Walk through the list until we pass the roll point
    local cumulative = 0
    for _, fish in ipairs(FishData.Fish) do
        cumulative = cumulative + fish.weight
        if roll <= cumulative then
            return fish
        end
    end

    -- Fallback: return the first fish (should never happen)
    return FishData.Fish[1]
end

return FishData
