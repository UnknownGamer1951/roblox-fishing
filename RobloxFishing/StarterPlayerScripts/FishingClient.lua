-- ============================================================
-- FishingClient.lua
-- Location in Studio: StarterPlayer > StarterPlayerScripts > FishingClient (LocalScript)
--
-- This script runs on each player's computer.
-- It handles:
--   - Detecting when the player clicks to cast
--   - Sending cast/reel events to the server
--   - Receiving events from the server and updating the UI
-- ============================================================

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("FishingRemotes"))

local localPlayer = Players.LocalPlayer
local camera      = workspace.CurrentCamera

-- -------------------------------------------------------
-- State
-- -------------------------------------------------------
local isFishing  = false   -- true while line is in the water
local isBiting   = false   -- true during the reel-in window

-- -------------------------------------------------------
-- Helper: Get the point in the world the player is looking at
-- Used to decide where the bobber lands.
-- -------------------------------------------------------
local function getCastTarget()
    -- Cast a ray from the center of the screen forward 30 studs
    local screenCenter = Vector2.new(
        camera.ViewportSize.X / 2,
        camera.ViewportSize.Y / 2
    )
    local unitRay = camera:ScreenPointToRay(screenCenter.X, screenCenter.Y)

    -- Extend the ray 30 studs in the look direction
    local target = unitRay.Origin + unitRay.Direction * 30

    return target
end

-- -------------------------------------------------------
-- Handle mouse / touch click
-- -------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- Ignore input that the game UI already consumed (e.g. chat box)
    if gameProcessed then return end

    local isClick = input.UserInputType == Enum.UserInputType.MouseButton1
                 or input.UserInputType == Enum.UserInputType.Touch

    if not isClick then return end

    if not isFishing then
        -- ---- CAST ----
        local castTarget = getCastTarget()
        isFishing = true
        isBiting  = false

        -- Notify the server
        Remotes.CastLine:FireServer(castTarget)

        -- Update the UI
        local gui = localPlayer.PlayerGui:FindFirstChild("FishingGui")
        if gui then
            gui.StatusLabel.Text = "Line in water... wait for a bite!"
            gui.ActionButton.Text = "Reel In"
            gui.ActionButton.Visible = false
        end

    elseif isBiting then
        -- ---- REEL IN (during bite window) ----
        isBiting  = false
        isFishing = false
        Remotes.ReelIn:FireServer()

    else
        -- ---- REEL IN EARLY (cancel) ----
        isFishing = false
        Remotes.ReelIn:FireServer()

        local gui = localPlayer.PlayerGui:FindFirstChild("FishingGui")
        if gui then
            gui.StatusLabel.Text = "Press [Click] to cast your line."
            gui.ActionButton.Visible = false
        end
    end
end)

-- -------------------------------------------------------
-- Server -> Client: Bobber landed somewhere
-- -------------------------------------------------------
Remotes.BobberLanded.OnClientEvent:Connect(function(position)
    -- In a full game you would animate the fishing line here.
    -- For now we just print the location for debugging.
    print("[FishingClient] Bobber landed at", position)
end)

-- -------------------------------------------------------
-- Server -> Client: Fish is biting!
-- -------------------------------------------------------
Remotes.FishBiting.OnClientEvent:Connect(function(rarity)
    isBiting = true

    local gui = localPlayer.PlayerGui:FindFirstChild("FishingGui")
    if gui then
        gui.StatusLabel.Text = "A fish is biting! CLICK NOW!"
        gui.ActionButton.Text = "REEL IN!"
        gui.ActionButton.Visible = true

        -- Flash the button to alert the player
        task.spawn(function()
            for _ = 1, 6 do
                gui.ActionButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
                task.wait(0.15)
                gui.ActionButton.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
                task.wait(0.15)
            end
        end)
    end

    -- Play a sound if one is set up (optional)
    -- local sound = workspace:FindFirstChild("BiteSound")
    -- if sound then sound:Play() end
end)

-- -------------------------------------------------------
-- Server -> Client: Fish caught successfully
-- -------------------------------------------------------
Remotes.FishCaught.OnClientEvent:Connect(function(fishInfo)
    isFishing = false
    isBiting  = false

    local gui = localPlayer.PlayerGui:FindFirstChild("FishingGui")
    if gui then
        gui.StatusLabel.Text = string.format(
            "Caught a %s %s (%d cm)!",
            fishInfo.rarity, fishInfo.name, fishInfo.size
        )
        gui.ActionButton.Visible = false
        gui.ActionButton.BackgroundColor3 = Color3.fromRGB(255, 200, 0)

        -- Show the catch popup panel
        local popup = gui:FindFirstChild("CatchPopup")
        if popup then
            popup.FishNameLabel.Text   = fishInfo.name
            popup.FishRarityLabel.Text = fishInfo.rarity
            popup.FishSizeLabel.Text   = fishInfo.size .. " cm"
            popup.Visible = true

            -- Hide the popup after 4 seconds
            task.delay(4, function()
                if popup then
                    popup.Visible = false
                end
            end)
        end

        -- Reset prompt after a moment
        task.delay(4, function()
            if gui and gui.StatusLabel then
                gui.StatusLabel.Text = "Press [Click] to cast your line."
            end
        end)
    end
end)

-- -------------------------------------------------------
-- Server -> Client: Player missed the bite window
-- -------------------------------------------------------
Remotes.FishMissed.OnClientEvent:Connect(function()
    isFishing = false
    isBiting  = false

    local gui = localPlayer.PlayerGui:FindFirstChild("FishingGui")
    if gui then
        gui.StatusLabel.Text = "You missed it! Cast again."
        gui.ActionButton.Visible = false
        gui.ActionButton.BackgroundColor3 = Color3.fromRGB(255, 200, 0)

        task.delay(2, function()
            if gui and gui.StatusLabel then
                gui.StatusLabel.Text = "Press [Click] to cast your line."
            end
        end)
    end
end)

print("[FishingClient] Loaded!")
