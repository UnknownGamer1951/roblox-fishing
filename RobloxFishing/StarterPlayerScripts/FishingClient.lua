-- ============================================================
-- FishingClient.lua
-- Location in Studio: StarterPlayer > StarterPlayerScripts > FishingClient (LocalScript)
--
-- Handles UI updates and reel-in input.
-- Fishing is now started by walking up to water and pressing E
-- (via a ProximityPrompt added automatically by FishingServer).
-- ============================================================

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes     = require(ReplicatedStorage:WaitForChild("FishingRemotes"))
local localPlayer = Players.LocalPlayer

-- -------------------------------------------------------
-- State
-- -------------------------------------------------------
local isFishing = false
local isBiting  = false

-- -------------------------------------------------------
-- Helper: get the FishingGui safely
-- -------------------------------------------------------
local function getGui()
    return localPlayer.PlayerGui:FindFirstChild("FishingGui")
end

local function setStatus(text)
    local gui = getGui()
    if gui and gui:FindFirstChild("StatusLabel") then
        gui.StatusLabel.Text = text
    end
end

-- -------------------------------------------------------
-- Click / tap to reel in while a fish is biting
-- -------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    local isClick = input.UserInputType == Enum.UserInputType.MouseButton1
                 or input.UserInputType == Enum.UserInputType.Touch

    if not isClick then return end

    if isBiting then
        -- Reel in during the bite window
        isBiting  = false
        isFishing = false
        Remotes.ReelIn:FireServer()

    elseif isFishing then
        -- Cancel early
        isFishing = false
        Remotes.ReelIn:FireServer()
        setStatus("Cancelled. Walk up to water and press E to fish.")
        task.delay(2, function()
            if not isFishing then
                setStatus("Walk up to water and press [E] to fish.")
            end
        end)
    end
end)

-- -------------------------------------------------------
-- Server -> Client: Bobber has landed (fishing has started)
-- -------------------------------------------------------
Remotes.BobberLanded.OnClientEvent:Connect(function(position)
    isFishing = true
    isBiting  = false
    setStatus("Line in water... wait for a bite!")
    local gui = getGui()
    if gui and gui:FindFirstChild("ActionButton") then
        gui.ActionButton.Visible = false
    end
    print("[FishingClient] Bobber landed at", position)
end)

-- -------------------------------------------------------
-- Server -> Client: Fish is biting!
-- -------------------------------------------------------
Remotes.FishBiting.OnClientEvent:Connect(function()
    isBiting = true

    local gui = getGui()
    if gui then
        setStatus("A fish is biting! CLICK NOW!")
        local btn = gui:FindFirstChild("ActionButton")
        if btn then
            btn.Text    = "REEL IN!"
            btn.Visible = true
            task.spawn(function()
                for _ = 1, 6 do
                    btn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
                    task.wait(0.15)
                    btn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
                    task.wait(0.15)
                end
            end)
        end
    end
end)

-- -------------------------------------------------------
-- Server -> Client: Fish caught successfully
-- -------------------------------------------------------
Remotes.FishCaught.OnClientEvent:Connect(function(fishInfo)
    isFishing = false
    isBiting  = false

    local gui = getGui()
    if gui then
        setStatus(string.format("Caught a %s %s (%d cm)!", fishInfo.rarity, fishInfo.name, fishInfo.size))

        local btn = gui:FindFirstChild("ActionButton")
        if btn then
            btn.Visible          = false
            btn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
        end

        local popup = gui:FindFirstChild("CatchPopup")
        if popup then
            popup.FishNameLabel.Text   = fishInfo.name
            popup.FishRarityLabel.Text = fishInfo.rarity
            popup.FishSizeLabel.Text   = fishInfo.size .. " cm"
            popup.Visible = true
            task.delay(4, function() if popup then popup.Visible = false end end)
        end

        task.delay(4, function()
            if not isFishing then
                setStatus("Walk up to water and press [E] to fish.")
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

    local gui = getGui()
    if gui then
        setStatus("You missed it!")
        local btn = gui:FindFirstChild("ActionButton")
        if btn then
            btn.Visible          = false
            btn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
        end
        task.delay(2, function()
            if not isFishing then
                setStatus("Walk up to water and press [E] to fish.")
            end
        end)
    end
end)

-- Set initial status text
task.delay(1, function()
    setStatus("Walk up to water and press [E] to fish.")
end)

print("[FishingClient] Loaded!")
