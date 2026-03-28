-- ============================================================
-- FishingGui.lua
-- Location in Studio: StarterGui > FishingGui (LocalScript inside a ScreenGui)
--
-- HOW TO SET THIS UP IN STUDIO:
--   1. In StarterGui, insert a ScreenGui named "FishingGui"
--   2. Inside FishingGui, insert a LocalScript named "FishingGui"
--      and paste this code into it.
--   3. This script creates all the UI elements automatically.
--      You do NOT need to add frames or labels by hand.
-- ============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage:WaitForChild("FishingRemotes"))

local localPlayer = Players.LocalPlayer
-- The ScreenGui that contains this script
local screenGui = script.Parent

-- ============================================================
-- BUILD THE UI PROGRAMMATICALLY
-- (So you don't have to drag and drop anything in Studio)
-- ============================================================

-- ---- Status bar at the top ----
local statusFrame = Instance.new("Frame")
statusFrame.Name            = "StatusFrame"
statusFrame.Size            = UDim2.new(0, 400, 0, 50)
statusFrame.Position        = UDim2.new(0.5, -200, 0, 20)
statusFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
statusFrame.BackgroundTransparency = 0.4
statusFrame.BorderSizePixel = 0
statusFrame.Parent          = screenGui

local statusLabel = Instance.new("TextLabel")
statusLabel.Name            = "StatusLabel"
statusLabel.Size            = UDim2.new(1, 0, 1, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text            = "Walk up to water and press [E] to fish."
statusLabel.TextColor3      = Color3.fromRGB(255, 255, 255)
statusLabel.TextScaled      = true
statusLabel.Font             = Enum.Font.GothamBold
statusLabel.Parent          = statusFrame

-- ---- Reel-In button (hidden until a fish bites) ----
local actionButton = Instance.new("TextButton")
actionButton.Name            = "ActionButton"
actionButton.Size            = UDim2.new(0, 200, 0, 60)
actionButton.Position        = UDim2.new(0.5, -100, 1, -100)
actionButton.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
actionButton.BorderSizePixel = 0
actionButton.Text            = "Reel In"
actionButton.TextColor3      = Color3.fromRGB(0, 0, 0)
actionButton.TextScaled      = true
actionButton.Font             = Enum.Font.GothamBold
actionButton.Visible         = false
actionButton.Parent          = screenGui

-- Round corners on the button
local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 12)
uiCorner.Parent = actionButton

-- Button also triggers reel-in (mobile-friendly)
actionButton.Activated:Connect(function()
    -- Mirror the click logic from FishingClient
    local fishingClient = localPlayer.PlayerScripts:FindFirstChild("FishingClient")
    -- We fire the event directly so it works even without FishingClient loaded yet
    Remotes.ReelIn:FireServer()
end)

-- ---- Catch popup panel ----
local catchPopup = Instance.new("Frame")
catchPopup.Name              = "CatchPopup"
catchPopup.Size              = UDim2.new(0, 300, 0, 200)
catchPopup.Position          = UDim2.new(0.5, -150, 0.5, -100)
catchPopup.BackgroundColor3  = Color3.fromRGB(20, 20, 40)
catchPopup.BackgroundTransparency = 0.1
catchPopup.BorderSizePixel   = 0
catchPopup.Visible           = false
catchPopup.Parent            = screenGui

local popupCorner = Instance.new("UICorner")
popupCorner.CornerRadius = UDim.new(0, 16)
popupCorner.Parent = catchPopup

-- "You caught a fish!" header
local caughtHeader = Instance.new("TextLabel")
caughtHeader.Size            = UDim2.new(1, 0, 0.25, 0)
caughtHeader.Position        = UDim2.new(0, 0, 0, 0)
caughtHeader.BackgroundTransparency = 1
caughtHeader.Text            = "You caught a fish!"
caughtHeader.TextColor3      = Color3.fromRGB(255, 220, 60)
caughtHeader.TextScaled      = true
caughtHeader.Font             = Enum.Font.GothamBold
caughtHeader.Parent          = catchPopup

-- Fish name
local fishNameLabel = Instance.new("TextLabel")
fishNameLabel.Name           = "FishNameLabel"
fishNameLabel.Size           = UDim2.new(1, 0, 0.25, 0)
fishNameLabel.Position       = UDim2.new(0, 0, 0.25, 0)
fishNameLabel.BackgroundTransparency = 1
fishNameLabel.Text           = ""
fishNameLabel.TextColor3     = Color3.fromRGB(255, 255, 255)
fishNameLabel.TextScaled     = true
fishNameLabel.Font            = Enum.Font.GothamBold
fishNameLabel.Parent         = catchPopup

-- Rarity
local fishRarityLabel = Instance.new("TextLabel")
fishRarityLabel.Name         = "FishRarityLabel"
fishRarityLabel.Size         = UDim2.new(1, 0, 0.25, 0)
fishRarityLabel.Position     = UDim2.new(0, 0, 0.5, 0)
fishRarityLabel.BackgroundTransparency = 1
fishRarityLabel.Text         = ""
fishRarityLabel.TextColor3   = Color3.fromRGB(180, 220, 255)
fishRarityLabel.TextScaled   = true
fishRarityLabel.Font          = Enum.Font.Gotham
fishRarityLabel.Parent       = catchPopup

-- Size
local fishSizeLabel = Instance.new("TextLabel")
fishSizeLabel.Name           = "FishSizeLabel"
fishSizeLabel.Size           = UDim2.new(1, 0, 0.25, 0)
fishSizeLabel.Position       = UDim2.new(0, 0, 0.75, 0)
fishSizeLabel.BackgroundTransparency = 1
fishSizeLabel.Text           = ""
fishSizeLabel.TextColor3     = Color3.fromRGB(200, 200, 200)
fishSizeLabel.TextScaled     = true
fishSizeLabel.Font            = Enum.Font.Gotham
fishSizeLabel.Parent         = catchPopup

-- ---- Inventory button (bottom left) ----
local invButton = Instance.new("TextButton")
invButton.Name               = "InventoryButton"
invButton.Size               = UDim2.new(0, 140, 0, 50)
invButton.Position           = UDim2.new(0, 20, 1, -70)
invButton.BackgroundColor3   = Color3.fromRGB(40, 80, 160)
invButton.BorderSizePixel    = 0
invButton.Text               = "My Fish"
invButton.TextColor3         = Color3.fromRGB(255, 255, 255)
invButton.TextScaled         = true
invButton.Font                = Enum.Font.GothamBold
invButton.Parent             = screenGui

local invCorner = Instance.new("UICorner")
invCorner.CornerRadius = UDim.new(0, 10)
invCorner.Parent = invButton

-- ---- Inventory panel (hidden by default) ----
local invPanel = Instance.new("ScrollingFrame")
invPanel.Name                = "InventoryPanel"
invPanel.Size                = UDim2.new(0, 320, 0, 400)
invPanel.Position            = UDim2.new(0, 20, 1, -470)
invPanel.BackgroundColor3    = Color3.fromRGB(15, 15, 30)
invPanel.BackgroundTransparency = 0.1
invPanel.BorderSizePixel     = 0
invPanel.Visible             = false
invPanel.CanvasSize          = UDim2.new(0, 0, 0, 0)  -- grows dynamically
invPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
invPanel.ScrollBarThickness  = 6
invPanel.Parent              = screenGui

local invCorner2 = Instance.new("UICorner")
invCorner2.CornerRadius = UDim.new(0, 12)
invCorner2.Parent = invPanel

local invLayout = Instance.new("UIListLayout")
invLayout.Padding           = UDim.new(0, 4)
invLayout.SortOrder         = Enum.SortOrder.LayoutOrder
invLayout.Parent            = invPanel

local invTitle = Instance.new("TextLabel")
invTitle.Size               = UDim2.new(1, 0, 0, 36)
invTitle.BackgroundTransparency = 1
invTitle.Text               = "Your Catch Log"
invTitle.TextColor3         = Color3.fromRGB(255, 220, 60)
invTitle.TextScaled         = true
invTitle.Font                = Enum.Font.GothamBold
invTitle.LayoutOrder        = 0
invTitle.Parent             = invPanel

-- Toggle inventory panel open/closed
invButton.Activated:Connect(function()
    invPanel.Visible = not invPanel.Visible
    if invPanel.Visible then
        -- Fetch inventory from server and refresh the list
        local inv = Remotes.GetInventory:InvokeServer()

        -- Remove old rows (keep only the title label)
        for _, child in ipairs(invPanel:GetChildren()) do
            if child:IsA("TextLabel") and child ~= invTitle then
                child:Destroy()
            end
            if child:IsA("Frame") then
                child:Destroy()
            end
        end

        if #inv == 0 then
            local emptyLabel = Instance.new("TextLabel")
            emptyLabel.Size  = UDim2.new(1, -10, 0, 30)
            emptyLabel.BackgroundTransparency = 1
            emptyLabel.Text  = "No fish yet. Go cast!"
            emptyLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
            emptyLabel.TextScaled = true
            emptyLabel.Font   = Enum.Font.Gotham
            emptyLabel.LayoutOrder = 1
            emptyLabel.Parent = invPanel
        else
            -- Color coding by rarity
            local rarityColors = {
                Common    = Color3.fromRGB(200, 200, 200),
                Uncommon  = Color3.fromRGB(100, 220, 100),
                Rare      = Color3.fromRGB(80, 140, 255),
                Legendary = Color3.fromRGB(255, 180, 0),
            }

            for i, entry in ipairs(inv) do
                local row = Instance.new("TextLabel")
                row.Size  = UDim2.new(1, -10, 0, 28)
                row.BackgroundTransparency = 1
                row.Text  = string.format(
                    "%d. %s (%s) — %d cm",
                    i, entry.name, entry.rarity, entry.size
                )
                row.TextColor3 = rarityColors[entry.rarity] or Color3.new(1,1,1)
                row.TextScaled = true
                row.Font   = Enum.Font.Gotham
                row.TextXAlignment = Enum.TextXAlignment.Left
                row.LayoutOrder = i + 1
                row.Parent = invPanel
            end
        end
    end
end)

print("[FishingGui] UI built and ready!")
