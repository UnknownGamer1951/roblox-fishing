-- ============================================================
-- FishingGui.lua  (LocalScript inside StarterGui > FishingGui)
-- Builds ALL fishing UI: status, minigame, tourney, shop
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes           = require(ReplicatedStorage:WaitForChild("FishingRemotes"))
local UpgradeData       = require(ReplicatedStorage:WaitForChild("UpgradeData"))

local localPlayer = Players.LocalPlayer
local screenGui   = script.Parent

-- ============================================================
-- STATUS BAR
-- ============================================================
local statusFrame = Instance.new("Frame")
statusFrame.Name                   = "StatusFrame"
statusFrame.Size                   = UDim2.new(0, 440, 0, 52)
statusFrame.Position               = UDim2.new(0.5, -220, 0, 18)
statusFrame.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
statusFrame.BackgroundTransparency = 0.4
statusFrame.BorderSizePixel        = 0
statusFrame.Parent                 = screenGui
Instance.new("UICorner", statusFrame).CornerRadius = UDim.new(0, 10)

local statusLabel = Instance.new("TextLabel")
statusLabel.Name                   = "StatusLabel"
statusLabel.Size                   = UDim2.new(1, -16, 1, 0)
statusLabel.Position               = UDim2.new(0, 8, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text                   = "Walk up to water and press [E] to fish."
statusLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
statusLabel.TextScaled             = true
statusLabel.Font                   = Enum.Font.GothamBold
statusLabel.Parent                 = statusFrame

-- ============================================================
-- COINS DISPLAY (top-left)
-- ============================================================
local coinsFrame = Instance.new("Frame")
coinsFrame.Name                   = "CoinsFrame"
coinsFrame.Size                   = UDim2.new(0, 160, 0, 44)
coinsFrame.Position               = UDim2.new(0, 18, 0, 18)
coinsFrame.BackgroundColor3       = Color3.fromRGB(30, 20, 0)
coinsFrame.BackgroundTransparency = 0.25
coinsFrame.BorderSizePixel        = 0
coinsFrame.Parent                 = screenGui
Instance.new("UICorner", coinsFrame).CornerRadius = UDim.new(0, 10)

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Name                   = "CoinsLabel"
coinsLabel.Size                   = UDim2.new(1, -8, 1, 0)
coinsLabel.Position               = UDim2.new(0, 4, 0, 0)
coinsLabel.BackgroundTransparency = 1
coinsLabel.Text                   = "🪙 0"
coinsLabel.TextColor3             = Color3.fromRGB(255, 220, 60)
coinsLabel.TextScaled             = true
coinsLabel.Font                   = Enum.Font.GothamBold
coinsLabel.TextXAlignment         = Enum.TextXAlignment.Left
coinsLabel.Parent                 = coinsFrame

-- ============================================================
-- ACTION BUTTON (hidden — kept for legacy / mobile fallback)
-- ============================================================
local actionButton = Instance.new("TextButton")
actionButton.Name             = "ActionButton"
actionButton.Size             = UDim2.new(0, 200, 0, 60)
actionButton.Position         = UDim2.new(0.5, -100, 1, -100)
actionButton.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
actionButton.BorderSizePixel  = 0
actionButton.Text             = "Reel In"
actionButton.TextColor3       = Color3.fromRGB(0, 0, 0)
actionButton.TextScaled       = true
actionButton.Font             = Enum.Font.GothamBold
actionButton.Visible          = false
actionButton.Parent           = screenGui
Instance.new("UICorner", actionButton).CornerRadius = UDim.new(0, 12)
actionButton.Activated:Connect(function() Remotes.ReelIn:FireServer() end)

-- ============================================================
-- CATCH POPUP
-- ============================================================
local catchPopup = Instance.new("Frame")
catchPopup.Name                   = "CatchPopup"
catchPopup.Size                   = UDim2.new(0, 320, 0, 200)
catchPopup.Position               = UDim2.new(0.5, -160, 0.5, -100)
catchPopup.BackgroundColor3       = Color3.fromRGB(20, 20, 40)
catchPopup.BackgroundTransparency = 0.1
catchPopup.BorderSizePixel        = 0
catchPopup.Visible                = false
catchPopup.Parent                 = screenGui
Instance.new("UICorner", catchPopup).CornerRadius = UDim.new(0, 16)

local function makeCatchRow(name, text, yFrac, color, font)
	local lbl = Instance.new("TextLabel")
	lbl.Name = name; lbl.Size = UDim2.new(1,0,0.25,0); lbl.Position = UDim2.new(0,0,yFrac,0)
	lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.TextColor3 = color
	lbl.TextScaled = true; lbl.Font = font; lbl.Parent = catchPopup
end
makeCatchRow("CaughtHeader",   "You caught a fish! 🎣", 0,    Color3.fromRGB(255,220,60),  Enum.Font.GothamBold)
makeCatchRow("FishNameLabel",  "",                       0.25, Color3.fromRGB(255,255,255), Enum.Font.GothamBold)
makeCatchRow("FishRarityLabel","",                       0.50, Color3.fromRGB(180,220,255), Enum.Font.Gotham)
makeCatchRow("FishSizeLabel",  "",                       0.75, Color3.fromRGB(200,200,200), Enum.Font.Gotham)

-- ============================================================
-- INVENTORY
-- ============================================================
local invButton = Instance.new("TextButton")
invButton.Name             = "InventoryButton"
invButton.Size             = UDim2.new(0, 130, 0, 46)
invButton.Position         = UDim2.new(0, 18, 1, -68)
invButton.BackgroundColor3 = Color3.fromRGB(40, 80, 160)
invButton.BorderSizePixel  = 0
invButton.Text             = "🐟 My Fish"
invButton.TextColor3       = Color3.fromRGB(255, 255, 255)
invButton.TextScaled       = true
invButton.Font             = Enum.Font.GothamBold
invButton.Parent           = screenGui
Instance.new("UICorner", invButton).CornerRadius = UDim.new(0, 10)

local invPanel = Instance.new("ScrollingFrame")
invPanel.Name                = "InventoryPanel"
invPanel.Size                = UDim2.new(0, 320, 0, 400)
invPanel.Position            = UDim2.new(0, 18, 1, -476)
invPanel.BackgroundColor3    = Color3.fromRGB(15, 15, 30)
invPanel.BackgroundTransparency = 0.1
invPanel.BorderSizePixel     = 0
invPanel.Visible             = false
invPanel.CanvasSize          = UDim2.new(0, 0, 0, 0)
invPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
invPanel.ScrollBarThickness  = 6
invPanel.Parent              = screenGui
Instance.new("UICorner", invPanel).CornerRadius = UDim.new(0, 12)

local invLayout = Instance.new("UIListLayout")
invLayout.Padding   = UDim.new(0, 4)
invLayout.SortOrder = Enum.SortOrder.LayoutOrder
invLayout.Parent    = invPanel

local invTitle = Instance.new("TextLabel")
invTitle.Size               = UDim2.new(1, 0, 0, 36)
invTitle.BackgroundTransparency = 1
invTitle.Text               = "Your Catch Log"
invTitle.TextColor3         = Color3.fromRGB(255, 220, 60)
invTitle.TextScaled         = true
invTitle.Font               = Enum.Font.GothamBold
invTitle.LayoutOrder        = 0
invTitle.Parent             = invPanel

local rarityColors = {
	Common    = Color3.fromRGB(200,200,200),
	Uncommon  = Color3.fromRGB(100,220,100),
	Rare      = Color3.fromRGB(80,140,255),
	Legendary = Color3.fromRGB(255,180,0),
}

invButton.Activated:Connect(function()
	invPanel.Visible = not invPanel.Visible
	if not invPanel.Visible then return end
	local inv = Remotes.GetInventory:InvokeServer()
	for _, c in ipairs(invPanel:GetChildren()) do
		if (c:IsA("TextLabel") or c:IsA("Frame")) and c ~= invTitle then c:Destroy() end
	end
	if #inv == 0 then
		local e = Instance.new("TextLabel")
		e.Size = UDim2.new(1,-10,0,30); e.BackgroundTransparency = 1
		e.Text = "No fish yet — go cast!"; e.TextColor3 = Color3.fromRGB(180,180,180)
		e.TextScaled = true; e.Font = Enum.Font.Gotham; e.LayoutOrder = 1; e.Parent = invPanel
	else
		for i, entry in ipairs(inv) do
			local row = Instance.new("TextLabel")
			row.Size = UDim2.new(1,-10,0,28); row.BackgroundTransparency = 1
			row.Text = string.format("%d. %s (%s) — %d cm", i, entry.name, entry.rarity, entry.size)
			row.TextColor3 = rarityColors[entry.rarity] or Color3.new(1,1,1)
			row.TextScaled = true; row.Font = Enum.Font.Gotham
			row.TextXAlignment = Enum.TextXAlignment.Left
			row.LayoutOrder = i + 1; row.Parent = invPanel
		end
	end
end)

-- ============================================================
-- SHOP BUTTON (bottom-left, next to inventory)
-- ============================================================
local shopButton = Instance.new("TextButton")
shopButton.Name             = "ShopButton"
shopButton.Size             = UDim2.new(0, 130, 0, 46)
shopButton.Position         = UDim2.new(0, 158, 1, -68)
shopButton.BackgroundColor3 = Color3.fromRGB(120, 60, 20)
shopButton.BorderSizePixel  = 0
shopButton.Text             = "🏪 Shop"
shopButton.TextColor3       = Color3.fromRGB(255, 255, 255)
shopButton.TextScaled       = true
shopButton.Font             = Enum.Font.GothamBold
shopButton.Parent           = screenGui
Instance.new("UICorner", shopButton).CornerRadius = UDim.new(0, 10)

-- ============================================================
-- SHOP PANEL
-- ============================================================
local shopPanel = Instance.new("Frame")
shopPanel.Name                   = "ShopPanel"
shopPanel.Size                   = UDim2.new(0, 360, 0, 460)
shopPanel.Position               = UDim2.new(0, 18, 1, -542)
shopPanel.BackgroundColor3       = Color3.fromRGB(18, 12, 6)
shopPanel.BackgroundTransparency = 0.05
shopPanel.BorderSizePixel        = 0
shopPanel.Visible                = false
shopPanel.Parent                 = screenGui
Instance.new("UICorner", shopPanel).CornerRadius = UDim.new(0, 14)

local shopTitle = Instance.new("TextLabel")
shopTitle.Size               = UDim2.new(1, 0, 0, 46)
shopTitle.Position           = UDim2.new(0, 0, 0, 0)
shopTitle.BackgroundTransparency = 1
shopTitle.Text               = "🏪 Upgrade Shop"
shopTitle.TextColor3         = Color3.fromRGB(255, 220, 60)
shopTitle.TextScaled         = true
shopTitle.Font               = Enum.Font.GothamBold
shopTitle.Parent             = shopPanel

local shopCoinsLabel = Instance.new("TextLabel")
shopCoinsLabel.Name              = "ShopCoinsLabel"
shopCoinsLabel.Size              = UDim2.new(1, -20, 0, 28)
shopCoinsLabel.Position          = UDim2.new(0, 10, 0, 46)
shopCoinsLabel.BackgroundTransparency = 1
shopCoinsLabel.Text              = "🪙 0 coins"
shopCoinsLabel.TextColor3        = Color3.fromRGB(255, 210, 60)
shopCoinsLabel.TextScaled        = true
shopCoinsLabel.Font              = Enum.Font.Gotham
shopCoinsLabel.TextXAlignment    = Enum.TextXAlignment.Left
shopCoinsLabel.Parent            = shopPanel

-- Each upgrade card: yOffset in the panel
local UPGRADE_DEFS = {
	{ type = "Bait", label = "🪱 Bait",  desc = "Better luck for rarer fish",    yOff = 82  },
	{ type = "Hook", label = "🪝 Hook",  desc = "Slows the fish in minigame",     yOff = 212 },
	{ type = "Rod",  label = "🎣 Rod",   desc = "Bigger catch bar in minigame",   yOff = 342 },
}

-- Holds refs to buy buttons so we can update them
local buyButtons = {}

local function makeUpgradeCard(def)
	local card = Instance.new("Frame")
	card.Name             = def.type .. "Card"
	card.Size             = UDim2.new(1, -20, 0, 118)
	card.Position         = UDim2.new(0, 10, 0, def.yOff)
	card.BackgroundColor3 = Color3.fromRGB(30, 20, 10)
	card.BackgroundTransparency = 0.3
	card.BorderSizePixel  = 0
	card.Parent           = shopPanel
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

	-- Category label
	local catLabel = Instance.new("TextLabel")
	catLabel.Name  = "CatLabel"
	catLabel.Size  = UDim2.new(1, -10, 0, 28)
	catLabel.Position = UDim2.new(0, 8, 0, 4)
	catLabel.BackgroundTransparency = 1
	catLabel.Text  = def.label .. "  —  " .. def.desc
	catLabel.TextColor3 = Color3.fromRGB(255, 230, 140)
	catLabel.TextScaled = true
	catLabel.Font  = Enum.Font.GothamBold
	catLabel.TextXAlignment = Enum.TextXAlignment.Left
	catLabel.Parent = card

	-- Current tier display
	local curLabel = Instance.new("TextLabel")
	curLabel.Name  = "CurrentLabel"
	curLabel.Size  = UDim2.new(0.55, -8, 0, 26)
	curLabel.Position = UDim2.new(0, 8, 0, 36)
	curLabel.BackgroundTransparency = 1
	curLabel.Text  = "Current: —"
	curLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
	curLabel.TextScaled = true
	curLabel.Font  = Enum.Font.Gotham
	curLabel.TextXAlignment = Enum.TextXAlignment.Left
	curLabel.Parent = card

	-- Next tier label
	local nextLabel = Instance.new("TextLabel")
	nextLabel.Name  = "NextLabel"
	nextLabel.Size  = UDim2.new(1, -16, 0, 24)
	nextLabel.Position = UDim2.new(0, 8, 0, 66)
	nextLabel.BackgroundTransparency = 1
	nextLabel.Text  = "Next: —"
	nextLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
	nextLabel.TextScaled = true
	nextLabel.Font  = Enum.Font.Gotham
	nextLabel.TextXAlignment = Enum.TextXAlignment.Left
	nextLabel.Parent = card

	-- Buy button
	local buyBtn = Instance.new("TextButton")
	buyBtn.Name             = "BuyBtn"
	buyBtn.Size             = UDim2.new(0, 110, 0, 30)
	buyBtn.Position         = UDim2.new(1, -118, 0, 32)
	buyBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 60)
	buyBtn.BorderSizePixel  = 0
	buyBtn.Text             = "Upgrade"
	buyBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
	buyBtn.TextScaled       = true
	buyBtn.Font             = Enum.Font.GothamBold
	buyBtn.Parent           = card
	Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 8)

	buyButtons[def.type] = { btn = buyBtn, curLabel = curLabel, nextLabel = nextLabel }

	buyBtn.Activated:Connect(function()
		local upgrades = Remotes.GetUpgrades:InvokeServer()
		local levelKey = def.type:lower() .. "Level"
		local currentLvl = upgrades[levelKey] or 1
		local targetLvl  = currentLvl + 1
		local ok, result, newCoins = Remotes.BuyUpgrade:InvokeServer(def.type, targetLvl)
		if ok then
			coinsLabel.Text     = "🪙 " .. (newCoins or 0)
			shopCoinsLabel.Text = "🪙 " .. (newCoins or 0) .. " coins"
			refreshShop()  -- re-draw after purchase
		else
			-- Flash button red to indicate failure
			buyBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
			task.delay(0.8, function() buyBtn.BackgroundColor3 = Color3.fromRGB(60,160,60) end)
			-- Show error briefly in next label
			local prevText = nextLabel.Text
			nextLabel.Text = "✗ " .. tostring(result)
			task.delay(2, function() nextLabel.Text = prevText end)
		end
	end)

	return card
end

for _, def in ipairs(UPGRADE_DEFS) do
	makeUpgradeCard(def)
end

-- Refresh shop display with current levels/coins
function refreshShop()
	local upgrades = Remotes.GetUpgrades:InvokeServer()
	coinsLabel.Text     = "🪙 " .. (upgrades.coins or 0)
	shopCoinsLabel.Text = "🪙 " .. (upgrades.coins or 0) .. " coins"

	local levelKeys = { Bait = "baitLevel", Hook = "hookLevel", Rod = "rodLevel" }
	for upgradeType, refs in pairs(buyButtons) do
		local levelKey = levelKeys[upgradeType]
		local tiers    = UpgradeData[upgradeType]
		local curLvl   = upgrades[levelKey] or 1
		local curTier  = tiers[curLvl]
		local nextTier = tiers[curLvl + 1]

		refs.curLabel.Text = "Current: " .. (curTier and curTier.name or "?")

		if nextTier then
			refs.nextLabel.Text         = "Next: " .. nextTier.name .. " (🪙 " .. nextTier.cost .. ")"
			refs.btn.Visible            = true
			refs.btn.Text               = "Upgrade"
			refs.btn.BackgroundColor3   = (upgrades.coins or 0) >= nextTier.cost
				and Color3.fromRGB(60, 160, 60)
				or  Color3.fromRGB(100, 100, 100)
		else
			refs.nextLabel.Text       = "✨ MAX LEVEL"
			refs.btn.Visible          = false
		end
	end
end

-- Open/close shop
local function openShop()
	invPanel.Visible = false  -- close inventory if open
	shopPanel.Visible = not shopPanel.Visible
	if shopPanel.Visible then
		refreshShop()
	end
end

shopButton.Activated:Connect(openShop)

-- Also open when the NPC ProximityPrompt fires
Remotes.OpenShop.OnClientEvent:Connect(function()
	shopPanel.Visible = true
	refreshShop()
end)

-- ============================================================
-- MINIGAME PANEL (right side, shown on fish bite)
-- ============================================================
local mgPanel = Instance.new("Frame")
mgPanel.Name             = "MinigamePanel"
mgPanel.Size             = UDim2.new(0, 200, 0, 375)
mgPanel.Position         = UDim2.new(1, -222, 0.5, -187)
mgPanel.BackgroundColor3 = Color3.fromRGB(8, 18, 38)
mgPanel.BackgroundTransparency = 0.12
mgPanel.BorderSizePixel  = 0
mgPanel.Visible          = false
mgPanel.Parent           = screenGui
Instance.new("UICorner", mgPanel).CornerRadius = UDim.new(0, 14)

local mgTitle = Instance.new("TextLabel")
mgTitle.Size     = UDim2.new(1, 0, 0, 34)
mgTitle.Position = UDim2.new(0, 0, 0, 5)
mgTitle.BackgroundTransparency = 1
mgTitle.Text     = "🎣 REEL IT IN!"
mgTitle.TextColor3 = Color3.fromRGB(255, 220, 60)
mgTitle.TextScaled = true
mgTitle.Font     = Enum.Font.GothamBold
mgTitle.Parent   = mgPanel

-- Water zone container
local mgContainer = Instance.new("Frame")
mgContainer.Name             = "Container"
mgContainer.Size             = UDim2.new(0, 100, 0, 295)
mgContainer.Position         = UDim2.new(0, 12, 0, 44)
mgContainer.BackgroundColor3 = Color3.fromRGB(15, 70, 130)
mgContainer.BackgroundTransparency = 0.25
mgContainer.BorderSizePixel  = 0
mgContainer.ClipsDescendants = true
mgContainer.Parent           = mgPanel
Instance.new("UICorner", mgContainer).CornerRadius = UDim.new(0, 8)

local catchBar = Instance.new("Frame")
catchBar.Name             = "CatchBar"
catchBar.Size             = UDim2.new(0.9, 0, 0.32, 0)
catchBar.Position         = UDim2.new(0.05, 0, 0.34, 0)
catchBar.BackgroundColor3 = Color3.fromRGB(60, 210, 80)
catchBar.BackgroundTransparency = 0.25
catchBar.BorderSizePixel  = 0
catchBar.Parent           = mgContainer
Instance.new("UICorner", catchBar).CornerRadius = UDim.new(0, 6)

local fishIcon = Instance.new("Frame")
fishIcon.Name             = "FishIcon"
fishIcon.Size             = UDim2.new(0.8, 0, 0.07, 0)
fishIcon.Position         = UDim2.new(0.1, 0, 0.46, 0)
fishIcon.BackgroundTransparency = 1
fishIcon.BorderSizePixel  = 0
fishIcon.Parent           = mgContainer
local fishEmoji = Instance.new("TextLabel")
fishEmoji.Size             = UDim2.new(1, 0, 1, 0)
fishEmoji.BackgroundTransparency = 1
fishEmoji.Text             = "🐟"
fishEmoji.TextScaled       = true
fishEmoji.Font             = Enum.Font.Gotham
fishEmoji.Parent           = fishIcon

local holdArea = Instance.new("TextButton")
holdArea.Name             = "HoldArea"
holdArea.Size             = UDim2.new(1, 0, 1, 0)
holdArea.BackgroundTransparency = 1
holdArea.Text             = ""
holdArea.ZIndex           = 10
holdArea.Parent           = mgContainer

-- Progress bar (right of container)
local pgBg = Instance.new("Frame")
pgBg.Name             = "ProgressBg"
pgBg.Size             = UDim2.new(0, 28, 0, 295)
pgBg.Position         = UDim2.new(0, 122, 0, 44)
pgBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
pgBg.BorderSizePixel  = 0
pgBg.ClipsDescendants = true
pgBg.Parent           = mgPanel
Instance.new("UICorner", pgBg).CornerRadius = UDim.new(0, 6)

local pgFill = Instance.new("Frame")
pgFill.Name             = "ProgressFill"
pgFill.Size             = UDim2.new(1, 0, 0.5, 0)
pgFill.Position         = UDim2.new(0, 0, 0.5, 0)
pgFill.BackgroundColor3 = Color3.fromRGB(60, 210, 80)
pgFill.BorderSizePixel  = 0
pgFill.Parent           = pgBg

local holdHint = Instance.new("TextLabel")
holdHint.Size             = UDim2.new(1, -4, 0, 30)
holdHint.Position         = UDim2.new(0, 2, 0, 343)
holdHint.BackgroundTransparency = 1
holdHint.Text             = "HOLD [CLICK] or tap to lift"
holdHint.TextColor3       = Color3.fromRGB(170, 170, 170)
holdHint.TextScaled       = true
holdHint.Font             = Enum.Font.Gotham
holdHint.Parent           = mgPanel

-- ============================================================
-- TOURNEY BUTTON (bottom right)
-- ============================================================
local tourneyBtn = Instance.new("TextButton")
tourneyBtn.Name             = "TourneyButton"
tourneyBtn.Size             = UDim2.new(0, 165, 0, 52)
tourneyBtn.Position         = UDim2.new(1, -185, 1, -72)
tourneyBtn.BackgroundColor3 = Color3.fromRGB(210, 110, 0)
tourneyBtn.BorderSizePixel  = 0
tourneyBtn.Text             = "🏆 TOURNEY"
tourneyBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
tourneyBtn.TextScaled       = true
tourneyBtn.Font             = Enum.Font.GothamBold
tourneyBtn.Parent           = screenGui
Instance.new("UICorner", tourneyBtn).CornerRadius = UDim.new(0, 10)
tourneyBtn.Activated:Connect(function()
	local r = screenGui:FindFirstChild("TourneyResult")
	if r then r.Visible = false end
	Remotes.JoinTournament:FireServer()
end)

-- ============================================================
-- TOURNEY HUD (top right, visible during active run)
-- ============================================================
local tourneyHUD = Instance.new("Frame")
tourneyHUD.Name             = "TourneyHUD"
tourneyHUD.Size             = UDim2.new(0, 190, 0, 100)
tourneyHUD.Position         = UDim2.new(1, -210, 0, 18)
tourneyHUD.BackgroundColor3 = Color3.fromRGB(12, 12, 45)
tourneyHUD.BackgroundTransparency = 0.18
tourneyHUD.BorderSizePixel  = 0
tourneyHUD.Visible          = false
tourneyHUD.Parent           = screenGui
Instance.new("UICorner", tourneyHUD).CornerRadius = UDim.new(0, 10)

local timerLabel = Instance.new("TextLabel")
timerLabel.Name    = "TimerLabel"; timerLabel.Size = UDim2.new(1,-10,0,36); timerLabel.Position = UDim2.new(0,5,0,4)
timerLabel.BackgroundTransparency = 1; timerLabel.Text = "⏱ 3:00"
timerLabel.TextColor3 = Color3.fromRGB(255,220,60); timerLabel.TextScaled = true
timerLabel.Font = Enum.Font.GothamBold; timerLabel.Parent = tourneyHUD

local fishCountLabel = Instance.new("TextLabel")
fishCountLabel.Name = "FishCountLabel"; fishCountLabel.Size = UDim2.new(1,-10,0,28); fishCountLabel.Position = UDim2.new(0,5,0,38)
fishCountLabel.BackgroundTransparency = 1; fishCountLabel.Text = "🐟 0 fish this run"
fishCountLabel.TextColor3 = Color3.fromRGB(170,255,170); fishCountLabel.TextScaled = true
fishCountLabel.Font = Enum.Font.Gotham; fishCountLabel.Parent = tourneyHUD

local pointsLabel = Instance.new("TextLabel")
pointsLabel.Name = "PointsLabel"; pointsLabel.Size = UDim2.new(1,-10,0,28); pointsLabel.Position = UDim2.new(0,5,0,66)
pointsLabel.BackgroundTransparency = 1; pointsLabel.Text = "⭐ 0 pts total"
pointsLabel.TextColor3 = Color3.fromRGB(255,245,180); pointsLabel.TextScaled = true
pointsLabel.Font = Enum.Font.Gotham; pointsLabel.Parent = tourneyHUD

-- ============================================================
-- TOURNEY RESULT POPUP
-- ============================================================
local tourneyResult = Instance.new("Frame")
tourneyResult.Name             = "TourneyResult"
tourneyResult.Size             = UDim2.new(0, 370, 0, 305)
tourneyResult.Position         = UDim2.new(0.5, -185, 0.5, -152)
tourneyResult.BackgroundColor3 = Color3.fromRGB(10, 14, 42)
tourneyResult.BackgroundTransparency = 0.05
tourneyResult.BorderSizePixel  = 0
tourneyResult.Visible          = false
tourneyResult.Parent           = screenGui
Instance.new("UICorner", tourneyResult).CornerRadius = UDim.new(0, 16)

local function trLabel(name, text, yOff, h, color, font)
	local lbl = Instance.new("TextLabel")
	lbl.Name = name; lbl.Size = UDim2.new(1,-20,0,h); lbl.Position = UDim2.new(0,10,0,yOff)
	lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.TextColor3 = color or Color3.new(1,1,1)
	lbl.TextScaled = true; lbl.Font = font or Enum.Font.Gotham; lbl.Parent = tourneyResult
	return lbl
end
trLabel("ResultTitle","⏰ TOURNEY OVER!",                        8,  46, Color3.fromRGB(255,220,60),  Enum.Font.GothamBold)
trLabel("TrophyLabel","",                                        56,  48, Color3.fromRGB(255,200,0),   Enum.Font.GothamBold)
trLabel("FishLabel",  "",                                       106,  34, Color3.fromRGB(170,255,170), Enum.Font.Gotham)
trLabel("BonusLabel", "",                                       142,  30, Color3.fromRGB(255,210,80),  Enum.Font.Gotham)
trLabel("TotalLabel", "",                                       174,  36, Color3.fromRGB(150,210,255), Enum.Font.GothamBold)
trLabel("TrophyHint", "🥉 5 pts  🥈 15 pts  🥇 30 pts",          212,  24, Color3.fromRGB(120,120,120), Enum.Font.Gotham)

local playAgainBtn = Instance.new("TextButton")
playAgainBtn.Name             = "PlayAgainBtn"
playAgainBtn.Size             = UDim2.new(0.6, 0, 0, 46)
playAgainBtn.Position         = UDim2.new(0.2, 0, 0, 248)
playAgainBtn.BackgroundColor3 = Color3.fromRGB(210, 110, 0)
playAgainBtn.BorderSizePixel  = 0
playAgainBtn.Text             = "🎣 Play Again!"
playAgainBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
playAgainBtn.TextScaled       = true
playAgainBtn.Font             = Enum.Font.GothamBold
playAgainBtn.Parent           = tourneyResult
Instance.new("UICorner", playAgainBtn).CornerRadius = UDim.new(0, 10)
playAgainBtn.Activated:Connect(function()
	tourneyResult.Visible = false
	Remotes.JoinTournament:FireServer()
end)

-- ============================================================
-- COINS UPDATE (from server)
-- ============================================================
Remotes.CoinsUpdate.OnClientEvent:Connect(function(coins)
	coinsLabel.Text     = "🪙 " .. coins
	shopCoinsLabel.Text = "🪙 " .. coins .. " coins"
end)

print("[FishingGui] UI built and ready!")
