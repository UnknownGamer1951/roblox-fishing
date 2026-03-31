-- ============================================================
-- FishingGui.lua  (LocalScript inside StarterGui > FishingGui)
-- Builds ALL fishing UI: status, minigame, tourney, shop
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local Remotes           = require(ReplicatedStorage:WaitForChild("FishingRemotes"))
local UpgradeData       = require(ReplicatedStorage:WaitForChild("UpgradeData"))
local AchievementData   = require(ReplicatedStorage:WaitForChild("AchievementData"))
local BaitData          = require(ReplicatedStorage:WaitForChild("BaitData"))
local FishData          = require(ReplicatedStorage:WaitForChild("FishData"))

local hotspotPositions = {}
local HOTSPOT_RADIUS   = 20

local localPlayer = Players.LocalPlayer
local screenGui   = script.Parent

-- ============================================================
-- STATUS BAR
-- ============================================================
local statusFrame = Instance.new("Frame")
statusFrame.Name                   = "StatusFrame"
statusFrame.Size                   = UDim2.new(0, 440, 0, 52)
statusFrame.Position               = UDim2.new(0.5, -220, 0, 60)
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
statusLabel.RichText               = true
statusLabel.Parent                 = statusFrame

-- Tracked currency values (updated by server events, used for display sync)
local trackedCoins = 0
local trackedStars = 0

-- Forward-declared panel references (used in closures before panels are built)
local shopPanel
local journalPanel

-- Caught fish set: name → true; loaded on join, updated on catch
local caughtFishSet = {}

-- ============================================================
-- COINS DISPLAY (top-left)
-- ============================================================
local coinsFrame = Instance.new("Frame")
coinsFrame.Name                   = "CoinsFrame"
coinsFrame.Size                   = UDim2.new(0, 150, 0, 44)
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
-- STARS DISPLAY (top-left, below coins)
-- ============================================================
local starsFrame = Instance.new("Frame")
starsFrame.Name                   = "StarsFrame"
starsFrame.Size                   = UDim2.new(0, 150, 0, 44)
starsFrame.Position               = UDim2.new(0, 18, 0, 68)
starsFrame.BackgroundColor3       = Color3.fromRGB(20, 0, 40)
starsFrame.BackgroundTransparency = 0.25
starsFrame.BorderSizePixel        = 0
starsFrame.Parent                 = screenGui
Instance.new("UICorner", starsFrame).CornerRadius = UDim.new(0, 10)

local starsLabel = Instance.new("TextLabel")
starsLabel.Name                   = "StarsLabel"
starsLabel.Size                   = UDim2.new(1, -8, 1, 0)
starsLabel.Position               = UDim2.new(0, 4, 0, 0)
starsLabel.BackgroundTransparency = 1
starsLabel.Text                   = "⭐ 0"
starsLabel.TextColor3             = Color3.fromRGB(200, 160, 255)
starsLabel.TextScaled             = true
starsLabel.Font                   = Enum.Font.GothamBold
starsLabel.TextXAlignment         = Enum.TextXAlignment.Left
starsLabel.Parent                 = starsFrame

-- ============================================================
-- HOTSPOT ZONE NOTIFICATION
-- ============================================================
local hotspotFrame = Instance.new("Frame")
hotspotFrame.Name                   = "HotspotFrame"
hotspotFrame.Size                   = UDim2.new(0, 170, 0, 46)
hotspotFrame.Position               = UDim2.new(0, 18, 0, 130)
hotspotFrame.BackgroundColor3       = Color3.fromRGB(0, 60, 100)
hotspotFrame.BackgroundTransparency = 0.2
hotspotFrame.BorderSizePixel        = 0
hotspotFrame.Visible                = false
hotspotFrame.ZIndex                 = 3
hotspotFrame.Parent                 = screenGui
Instance.new("UICorner", hotspotFrame).CornerRadius = UDim.new(0, 10)
local hotspotLabel = Instance.new("TextLabel")
hotspotLabel.Size                   = UDim2.new(1, -8, 1, 0)
hotspotLabel.Position               = UDim2.new(0, 4, 0, 0)
hotspotLabel.BackgroundTransparency = 1
hotspotLabel.Text                   = "** Hotspot Zone"
hotspotLabel.TextColor3             = Color3.fromRGB(100, 220, 255)
hotspotLabel.TextScaled             = true
hotspotLabel.Font                   = Enum.Font.GothamBold
hotspotLabel.ZIndex                 = 3
hotspotLabel.Parent                 = hotspotFrame

RunService.Heartbeat:Connect(function()
	local char = localPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or #hotspotPositions == 0 then hotspotFrame.Visible = false; return end
	local pos = root.Position
	local inside = false
	for _, hPos in ipairs(hotspotPositions) do
		if (pos - hPos).Magnitude <= HOTSPOT_RADIUS then inside = true; break end
	end
	hotspotFrame.Visible = inside
end)

Remotes.HotspotList.OnClientEvent:Connect(function(positions)
	hotspotPositions = positions or {}
end)
task.delay(8, function()
	if #hotspotPositions == 0 then
		warn("[FishingGui] No hotspot positions received yet")
	end
end)

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
invButton.Text             = "My Fish"
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

-- X close button overlaid on top-right of invPanel
-- (invPanel is a ScrollingFrame so the button lives in screenGui)
local invCloseBtn = Instance.new("TextButton")
invCloseBtn.Name             = "InvCloseBtn"
invCloseBtn.Size             = UDim2.new(0, 32, 0, 32)
-- Matches invPanel top-right: x=18+320-36=302, y=1-476+4=top-4
invCloseBtn.Position         = UDim2.new(0, 302, 1, -476)
invCloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
invCloseBtn.BorderSizePixel  = 0
invCloseBtn.Text             = "✕"
invCloseBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
invCloseBtn.TextScaled       = true
invCloseBtn.Font             = Enum.Font.GothamBold
invCloseBtn.ZIndex           = 5
invCloseBtn.Visible          = false
invCloseBtn.Parent           = screenGui
Instance.new("UICorner", invCloseBtn).CornerRadius = UDim.new(0, 8)
invCloseBtn.Activated:Connect(function()
	invPanel.Visible    = false
	invCloseBtn.Visible = false
end)

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
	invCloseBtn.Visible = invPanel.Visible
	if shopPanel   then shopPanel.Visible   = false end
	if journalPanel then journalPanel.Visible = false end
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
-- SHOP BUTTON (bottom-left)
-- ============================================================
local shopButton = Instance.new("TextButton")
shopButton.Name             = "ShopButton"
shopButton.Size             = UDim2.new(0, 130, 0, 46)
shopButton.Position         = UDim2.new(0, 158, 1, -68)
shopButton.BackgroundColor3 = Color3.fromRGB(120, 60, 20)
shopButton.BorderSizePixel  = 0
shopButton.Text             = "Shop"
shopButton.TextColor3       = Color3.fromRGB(255, 255, 255)
shopButton.TextScaled       = true
shopButton.Font             = Enum.Font.GothamBold
shopButton.Visible          = false
shopButton.Parent           = screenGui
Instance.new("UICorner", shopButton).CornerRadius = UDim.new(0, 10)

-- ============================================================
-- SHOP PANEL  (Upgrades | Bait | Sell tabs)
-- ============================================================
shopPanel = Instance.new("Frame")
shopPanel.Name                   = "ShopPanel"
shopPanel.Size                   = UDim2.new(0, 380, 0, 540)
shopPanel.Position               = UDim2.new(0, 18, 1, -558)
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
shopTitle.Text               = "Shop"
shopTitle.TextColor3         = Color3.fromRGB(255, 220, 60)
shopTitle.TextScaled         = true
shopTitle.Font               = Enum.Font.GothamBold
shopTitle.Parent             = shopPanel

local shopCloseBtn = Instance.new("TextButton")
shopCloseBtn.Size             = UDim2.new(0, 36, 0, 36)
shopCloseBtn.Position         = UDim2.new(1, -44, 0, 5)
shopCloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
shopCloseBtn.BorderSizePixel  = 0
shopCloseBtn.Text             = "✕"
shopCloseBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
shopCloseBtn.TextScaled       = true
shopCloseBtn.Font             = Enum.Font.GothamBold
shopCloseBtn.Parent           = shopPanel
Instance.new("UICorner", shopCloseBtn).CornerRadius = UDim.new(0, 8)
shopCloseBtn.Activated:Connect(function() shopPanel.Visible = false end)

local shopCoinsLabel = Instance.new("TextLabel")
shopCoinsLabel.Name              = "ShopCoinsLabel"
shopCoinsLabel.Size              = UDim2.new(1, -20, 0, 28)
shopCoinsLabel.Position          = UDim2.new(0, 10, 0, 46)
shopCoinsLabel.BackgroundTransparency = 1
shopCoinsLabel.Text              = "0 coins  0 stars"
shopCoinsLabel.TextColor3        = Color3.fromRGB(255, 210, 60)
shopCoinsLabel.TextScaled        = true
shopCoinsLabel.Font              = Enum.Font.Gotham
shopCoinsLabel.TextXAlignment    = Enum.TextXAlignment.Left
shopCoinsLabel.Parent            = shopPanel

-- Tab buttons
local TAB_ACTIVE_COLOR   = Color3.fromRGB(50, 140, 50)
local TAB_INACTIVE_COLOR = Color3.fromRGB(35, 35, 35)
local tabW = math.floor((380 - 20) / 3)

local function makeShopTab(label, xPos)
	local btn = Instance.new("TextButton")
	btn.Size             = UDim2.new(0, tabW - 4, 0, 32)
	btn.Position         = UDim2.new(0, xPos, 0, 76)
	btn.BackgroundColor3 = TAB_INACTIVE_COLOR
	btn.BorderSizePixel  = 0
	btn.Text             = label
	btn.TextColor3       = Color3.fromRGB(180, 180, 180)
	btn.TextScaled       = true
	btn.Font             = Enum.Font.GothamBold
	btn.Parent           = shopPanel
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	return btn
end

local upgradesTabBtn = makeShopTab("Upgrades", 10)
local baitTabBtn     = makeShopTab("Bait",     10 + tabW)
local sellTabBtn     = makeShopTab("Sell",     10 + tabW * 2)

local PANE_Y = 112
local PANE_H = 540 - PANE_Y - 8

local upgradesPane = Instance.new("Frame")
upgradesPane.Size             = UDim2.new(1, -20, 0, PANE_H)
upgradesPane.Position         = UDim2.new(0, 10, 0, PANE_Y)
upgradesPane.BackgroundTransparency = 1
upgradesPane.BorderSizePixel  = 0
upgradesPane.Parent           = shopPanel

local baitPane = Instance.new("Frame")
baitPane.Size             = UDim2.new(1, -20, 0, PANE_H)
baitPane.Position         = UDim2.new(0, 10, 0, PANE_Y)
baitPane.BackgroundTransparency = 1
baitPane.BorderSizePixel  = 0
baitPane.Visible          = false
baitPane.Parent           = shopPanel

local sellPane = Instance.new("Frame")
sellPane.Size             = UDim2.new(1, -20, 0, PANE_H)
sellPane.Position         = UDim2.new(0, 10, 0, PANE_Y)
sellPane.BackgroundTransparency = 1
sellPane.BorderSizePixel  = 0
sellPane.Visible          = false
sellPane.Parent           = shopPanel

local sellScroll = Instance.new("ScrollingFrame")
sellScroll.Size                  = UDim2.new(1, 0, 1, 0)
sellScroll.BackgroundTransparency = 1
sellScroll.BorderSizePixel       = 0
sellScroll.CanvasSize            = UDim2.new(0, 0, 0, 0)
sellScroll.AutomaticCanvasSize   = Enum.AutomaticSize.Y
sellScroll.ScrollBarThickness    = 4
sellScroll.ScrollBarImageColor3  = Color3.fromRGB(100, 100, 100)
sellScroll.Parent                = sellPane
local sellLayout = Instance.new("UIListLayout", sellScroll)
sellLayout.Padding   = UDim.new(0, 4)
sellLayout.SortOrder = Enum.SortOrder.LayoutOrder
local sellPadding = Instance.new("UIPadding", sellScroll)
sellPadding.PaddingTop = UDim.new(0, 4)

local activeShopTab = "upgrades"
local refreshBaitPane  -- forward declare
local refreshSellPane  -- forward declare

local function setShopTab(tab)
	activeShopTab            = tab
	upgradesPane.Visible     = (tab == "upgrades")
	baitPane.Visible         = (tab == "bait")
	sellPane.Visible         = (tab == "sell")
	upgradesTabBtn.BackgroundColor3 = tab == "upgrades" and TAB_ACTIVE_COLOR or TAB_INACTIVE_COLOR
	baitTabBtn.BackgroundColor3     = tab == "bait"     and TAB_ACTIVE_COLOR or TAB_INACTIVE_COLOR
	sellTabBtn.BackgroundColor3     = tab == "sell"     and TAB_ACTIVE_COLOR or TAB_INACTIVE_COLOR
	upgradesTabBtn.TextColor3 = tab == "upgrades" and Color3.fromRGB(255,255,255) or Color3.fromRGB(180,180,180)
	baitTabBtn.TextColor3     = tab == "bait"     and Color3.fromRGB(255,255,255) or Color3.fromRGB(180,180,180)
	sellTabBtn.TextColor3     = tab == "sell"     and Color3.fromRGB(255,255,255) or Color3.fromRGB(180,180,180)
	if tab == "sell" then refreshSellPane() end
	if tab == "bait" then refreshBaitPane() end
end

upgradesTabBtn.Activated:Connect(function() setShopTab("upgrades") end)
baitTabBtn.Activated:Connect(function() setShopTab("bait") end)
sellTabBtn.Activated:Connect(function() setShopTab("sell") end)

-- ============================================================
-- UPGRADE CARDS (inside upgradesPane)
-- ============================================================
local UPGRADE_DEFS = {
	{ type = "Reel", label = "Reel",    desc = "Reduces wait time + slight rarity bonus", yOff = 0   },
	{ type = "Hook", label = "Hook",    desc = "Slows the fish in minigame",              yOff = 130 },
	{ type = "Rod",  label = "Rod",     desc = "Bigger catch bar in minigame",            yOff = 260 },
}

local buyButtons = {}

local function makeUpgradeCard(def)
	local card = Instance.new("Frame")
	card.Name             = def.type .. "Card"
	card.Size             = UDim2.new(1, 0, 0, 118)
	card.Position         = UDim2.new(0, 0, 0, def.yOff)
	card.BackgroundColor3 = Color3.fromRGB(30, 20, 10)
	card.BackgroundTransparency = 0.3
	card.BorderSizePixel  = 0
	card.Parent           = upgradesPane
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

	local catLabel = Instance.new("TextLabel")
	catLabel.Size  = UDim2.new(1, -10, 0, 28)
	catLabel.Position = UDim2.new(0, 8, 0, 4)
	catLabel.BackgroundTransparency = 1
	catLabel.Text  = def.label .. "  -  " .. def.desc
	catLabel.TextColor3 = Color3.fromRGB(255, 230, 140)
	catLabel.TextScaled = true
	catLabel.Font  = Enum.Font.GothamBold
	catLabel.TextXAlignment = Enum.TextXAlignment.Left
	catLabel.Parent = card

	local curLabel = Instance.new("TextLabel")
	curLabel.Name  = "CurrentLabel"
	curLabel.Size  = UDim2.new(0.55, -8, 0, 26)
	curLabel.Position = UDim2.new(0, 8, 0, 36)
	curLabel.BackgroundTransparency = 1
	curLabel.Text  = "Current: -"
	curLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
	curLabel.TextScaled = true
	curLabel.Font  = Enum.Font.Gotham
	curLabel.TextXAlignment = Enum.TextXAlignment.Left
	curLabel.Parent = card

	local nextLabel = Instance.new("TextLabel")
	nextLabel.Name  = "NextLabel"
	nextLabel.Size  = UDim2.new(1, -16, 0, 24)
	nextLabel.Position = UDim2.new(0, 8, 0, 62)
	nextLabel.BackgroundTransparency = 1
	nextLabel.Text  = "Next: -"
	nextLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
	nextLabel.TextScaled = true
	nextLabel.Font  = Enum.Font.Gotham
	nextLabel.TextXAlignment = Enum.TextXAlignment.Left
	nextLabel.Parent = card

	local starCostLabel = Instance.new("TextLabel")
	starCostLabel.Name  = "StarCostLabel"
	starCostLabel.Size  = UDim2.new(1, -16, 0, 18)
	starCostLabel.Position = UDim2.new(0, 8, 0, 86)
	starCostLabel.BackgroundTransparency = 1
	starCostLabel.Text  = ""
	starCostLabel.TextColor3 = Color3.fromRGB(200, 160, 255)
	starCostLabel.TextScaled = true
	starCostLabel.Font  = Enum.Font.Gotham
	starCostLabel.TextXAlignment = Enum.TextXAlignment.Left
	starCostLabel.Parent = card

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

	buyButtons[def.type] = { btn = buyBtn, curLabel = curLabel, nextLabel = nextLabel, starCostLabel = starCostLabel }

	buyBtn.Activated:Connect(function()
		local upgrades = Remotes.GetUpgrades:InvokeServer()
		local levelKey = def.type:lower() .. "Level"
		local currentLvl = upgrades[levelKey] or 1
		local targetLvl  = currentLvl + 1
		local ok, result, newCoins, newStars = Remotes.BuyUpgrade:InvokeServer(def.type, targetLvl)
		if ok then
			coinsLabel.Text     = "🪙 " .. (newCoins or 0)
			starsLabel.Text     = "⭐ " .. (newStars or 0)
			shopCoinsLabel.Text = "🪙 " .. (newCoins or 0) .. "  ⭐ " .. (newStars or 0)
			refreshShop()
		else
			buyBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
			task.delay(0.8, function() buyBtn.BackgroundColor3 = Color3.fromRGB(60,160,60) end)
			local prevText = nextLabel.Text
			nextLabel.Text = "X " .. tostring(result)
			task.delay(2, function() nextLabel.Text = prevText end)
		end
	end)

	return card
end

for _, def in ipairs(UPGRADE_DEFS) do
	makeUpgradeCard(def)
end

function refreshShop()
	local upgrades = Remotes.GetUpgrades:InvokeServer()
	local coins    = upgrades.coins or 0
	local stars    = upgrades.stars or 0
	coinsLabel.Text     = "🪙 " .. coins
	starsLabel.Text     = "⭐ " .. stars
	shopCoinsLabel.Text = "🪙 " .. coins .. "  ⭐ " .. stars

	local levelKeys = { Reel = "reelLevel", Hook = "hookLevel", Rod = "rodLevel" }
	for upgradeType, refs in pairs(buyButtons) do
		local levelKey = levelKeys[upgradeType]
		local tiers    = UpgradeData[upgradeType]
		local curLvl   = upgrades[levelKey] or 1
		local curTier  = tiers[curLvl]
		local nextTier = tiers[curLvl + 1]

		refs.curLabel.Text = "Current: " .. (curTier and curTier.name or "?")

		if nextTier then
			local sc = nextTier.starCost or 0
			refs.nextLabel.Text     = "Next: " .. nextTier.name .. " (🪙 " .. nextTier.cost .. ")"
			refs.starCostLabel.Text = sc > 0 and ("  + ⭐ " .. sc .. " stars required") or ""
			refs.btn.Visible        = true
			refs.btn.Text           = "Upgrade"
			local canAfford         = coins >= nextTier.cost and stars >= sc
			refs.btn.BackgroundColor3 = canAfford
				and Color3.fromRGB(60, 160, 60)
				or  Color3.fromRGB(100, 100, 100)
		else
			refs.nextLabel.Text       = "MAX LEVEL"
			refs.starCostLabel.Text   = ""
			refs.btn.Visible          = false
		end
	end
end

local function openShop()
	invPanel.Visible     = false
	journalPanel.Visible = false
	shopPanel.Visible    = not shopPanel.Visible
	if shopPanel.Visible then
		refreshShop()
		setShopTab("upgrades")
	end
end

shopButton.Activated:Connect(openShop)

Remotes.OpenShop.OnClientEvent:Connect(function()
	shopPanel.Visible = true
	refreshShop()
	setShopTab("upgrades")
end)

-- ============================================================
-- BAIT PANE (inside shop)
-- ============================================================
local baitRows = {}

refreshBaitPane = function(inv, current)
	for _, r in ipairs(baitRows) do r:Destroy() end
	baitRows = {}
	local baitInv, baitCurrent = inv, current
	if not baitInv then
		local ok, res = pcall(function() return Remotes.GetBaitState:InvokeServer() end)
		if ok and res then baitInv = res.inventory; baitCurrent = res.current end
	end
	if not baitInv then return end
	for i, bait in ipairs(BaitData) do
		local count    = baitInv[bait.id] or 0
		local isActive = (baitCurrent == bait.id)
		local row = Instance.new("Frame")
		row.Size             = UDim2.new(1, 0, 0, 54)
		row.Position         = UDim2.new(0, 0, 0, (i-1) * 58)
		row.BackgroundColor3 = isActive and Color3.fromRGB(20,60,20) or Color3.fromRGB(15,35,15)
		row.BackgroundTransparency = 0.2
		row.BorderSizePixel  = 0
		row.Parent           = baitPane
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
		table.insert(baitRows, row)

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size             = UDim2.new(0.55, 0, 0.5, 0)
		nameLabel.Position         = UDim2.new(0, 8, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text             = bait.name
		nameLabel.TextColor3       = Color3.fromRGB(200, 255, 200)
		nameLabel.TextScaled       = true
		nameLabel.Font             = Enum.Font.GothamBold
		nameLabel.TextXAlignment   = Enum.TextXAlignment.Left
		nameLabel.Parent           = row

		local countLabel = Instance.new("TextLabel")
		countLabel.Size            = UDim2.new(0.45, 0, 0.5, 0)
		countLabel.Position        = UDim2.new(0, 8, 0.5, 0)
		countLabel.BackgroundTransparency = 1
		countLabel.Text            = "x" .. count
		countLabel.TextColor3      = Color3.fromRGB(180, 180, 180)
		countLabel.TextScaled      = true
		countLabel.Font            = Enum.Font.Gotham
		countLabel.TextXAlignment  = Enum.TextXAlignment.Left
		countLabel.Parent          = row

		-- Single action button
		local actionBtn = Instance.new("TextButton")
		actionBtn.Size            = UDim2.new(0, 84, 0, 30)
		actionBtn.Position        = UDim2.new(1, -92, 0.5, -15)
		actionBtn.BorderSizePixel = 0
		actionBtn.TextColor3      = Color3.fromRGB(255, 255, 255)
		actionBtn.TextScaled      = true
		actionBtn.Font            = Enum.Font.GothamBold
		actionBtn.Parent          = row
		Instance.new("UICorner", actionBtn).CornerRadius = UDim.new(0, 6)

		local baitId   = bait.id
		local shopCost = bait.shopCost

		if isActive then
			actionBtn.Text             = "Active"
			actionBtn.BackgroundColor3 = Color3.fromRGB(40, 130, 40)
			actionBtn.AutoButtonColor  = false
		elseif count > 0 then
			actionBtn.Text             = "Equip"
			actionBtn.BackgroundColor3 = Color3.fromRGB(30, 100, 160)
			actionBtn.Activated:Connect(function()
				Remotes.SelectBait:FireServer(baitId)
				task.delay(0.3, function() refreshBaitPane(nil, nil) end)
			end)
		else
			actionBtn.Text             = "Buy " .. shopCost .. "c"
			actionBtn.BackgroundColor3 = Color3.fromRGB(180, 120, 20)
			actionBtn.Activated:Connect(function()
				local ok2, result = pcall(function() return Remotes.BuyBait:InvokeServer(baitId) end)
				if ok2 and result then
					task.delay(0.2, function() refreshBaitPane(nil, nil) end)
				end
			end)
		end
	end
end

Remotes.BaitUpdate.OnClientEvent:Connect(function(inv, current)
	if shopPanel.Visible and activeShopTab == "bait" then
		refreshBaitPane(inv, current)
	end
end)

-- ============================================================
-- SELL PANE (inside shop)
-- ============================================================
local sellRows = {}

local SELL_RARITY_COLORS = {
	Common    = Color3.fromRGB(180,180,180),
	Uncommon  = Color3.fromRGB(100,220,100),
	Rare      = Color3.fromRGB(80,140,255),
	Legendary = Color3.fromRGB(255,180,0),
}

refreshSellPane = function()
	for _, r in ipairs(sellRows) do r:Destroy() end
	sellRows = {}
	local ok, inv = pcall(function() return Remotes.GetInventory:InvokeServer() end)
	if not ok or not inv then return end

	if #inv == 0 then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size             = UDim2.new(1, 0, 0, 40)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text             = "No fish to sell."
		emptyLabel.TextColor3       = Color3.fromRGB(180, 180, 180)
		emptyLabel.TextScaled       = true
		emptyLabel.Font             = Enum.Font.Gotham
		emptyLabel.LayoutOrder      = 1
		emptyLabel.Parent           = sellScroll
		table.insert(sellRows, emptyLabel)
		return
	end

	local sellAllBtn = Instance.new("TextButton")
	sellAllBtn.Size             = UDim2.new(1, 0, 0, 36)
	sellAllBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 20)
	sellAllBtn.BorderSizePixel  = 0
	sellAllBtn.Text             = "Sell All (" .. #inv .. " fish)"
	sellAllBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
	sellAllBtn.TextScaled       = true
	sellAllBtn.Font             = Enum.Font.GothamBold
	sellAllBtn.LayoutOrder      = 0
	sellAllBtn.Parent           = sellScroll
	Instance.new("UICorner", sellAllBtn).CornerRadius = UDim.new(0, 8)
	table.insert(sellRows, sellAllBtn)

	local totalFish = #inv
	sellAllBtn.Activated:Connect(function()
		for _ = 1, totalFish do
			Remotes.SellFish:InvokeServer(1)
		end
		task.delay(0.2, function()
			refreshSellPane()
			refreshShop()
		end)
	end)

	for i, fish in ipairs(inv) do
		local row = Instance.new("Frame")
		row.Size             = UDim2.new(1, 0, 0, 44)
		row.BackgroundColor3 = Color3.fromRGB(20, 30, 20)
		row.BackgroundTransparency = 0.3
		row.BorderSizePixel  = 0
		row.LayoutOrder      = i
		row.Parent           = sellScroll
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
		table.insert(sellRows, row)

		local fishLabel = Instance.new("TextLabel")
		fishLabel.Size            = UDim2.new(1, -90, 1, 0)
		fishLabel.Position        = UDim2.new(0, 8, 0, 0)
		fishLabel.BackgroundTransparency = 1
		fishLabel.Text            = fish.name .. "  " .. string.format("%.1fcm", fish.size)
		fishLabel.TextColor3      = SELL_RARITY_COLORS[fish.rarity] or Color3.fromRGB(200,200,200)
		fishLabel.TextScaled      = true
		fishLabel.Font            = Enum.Font.Gotham
		fishLabel.TextXAlignment  = Enum.TextXAlignment.Left
		fishLabel.Parent          = row

		local sellBtn = Instance.new("TextButton")
		sellBtn.Size             = UDim2.new(0, 72, 0, 28)
		sellBtn.Position         = UDim2.new(1, -80, 0.5, -14)
		sellBtn.BackgroundColor3 = Color3.fromRGB(200, 140, 20)
		sellBtn.BorderSizePixel  = 0
		sellBtn.Text             = "Sell"
		sellBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
		sellBtn.TextScaled       = true
		sellBtn.Font             = Enum.Font.GothamBold
		sellBtn.Parent           = row
		Instance.new("UICorner", sellBtn).CornerRadius = UDim.new(0, 6)

		local idx = i
		sellBtn.Activated:Connect(function()
			local sold, _ = Remotes.SellFish:InvokeServer(idx)
			if sold then
				refreshSellPane()
				refreshShop()
			end
		end)
	end
end


-- MINIGAME PANEL (right side, shown on fish bite)
-- ============================================================
local mgPanel = Instance.new("Frame")
mgPanel.Name             = "MinigamePanel"
mgPanel.Size             = UDim2.new(0, 200, 0, 375)
mgPanel.Position         = UDim2.new(0.5, -100, 0.5, -187)
mgPanel.BackgroundColor3 = Color3.fromRGB(8, 18, 38)
mgPanel.BackgroundTransparency = 0.12
mgPanel.BorderSizePixel  = 0
mgPanel.Visible          = false
mgPanel.Parent           = screenGui
Instance.new("UICorner", mgPanel).CornerRadius = UDim.new(0, 14)

local mgTitle = Instance.new("TextLabel")
mgTitle.Name     = "TitleLabel"
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
-- TOURNAMENT COUNTDOWN (bottom-right — always visible)
-- Shows "Next tourney in X:XX" or "🏆 TOURNAMENT ACTIVE X:XX"
-- ============================================================
local tourneyCountdownFrame = Instance.new("Frame")
tourneyCountdownFrame.Name             = "TourneyCountdown"
tourneyCountdownFrame.Size             = UDim2.new(0, 200, 0, 52)
tourneyCountdownFrame.Position         = UDim2.new(1, -218, 1, -72)
tourneyCountdownFrame.BackgroundColor3 = Color3.fromRGB(20, 10, 40)
tourneyCountdownFrame.BackgroundTransparency = 0.2
tourneyCountdownFrame.BorderSizePixel  = 0
tourneyCountdownFrame.Parent           = screenGui
Instance.new("UICorner", tourneyCountdownFrame).CornerRadius = UDim.new(0, 10)

local countdownLabel = Instance.new("TextLabel")
countdownLabel.Name             = "CountdownLabel"
countdownLabel.Size             = UDim2.new(1, -8, 0.55, 0)
countdownLabel.Position         = UDim2.new(0, 4, 0, 2)
countdownLabel.BackgroundTransparency = 1
countdownLabel.Text             = "🏆 Next tourney: --:--"
countdownLabel.TextColor3       = Color3.fromRGB(255, 220, 60)
countdownLabel.TextScaled       = true
countdownLabel.Font             = Enum.Font.GothamBold
countdownLabel.TextXAlignment   = Enum.TextXAlignment.Left
countdownLabel.Parent           = tourneyCountdownFrame

local countdownSub = Instance.new("TextLabel")
countdownSub.Size             = UDim2.new(1, -8, 0.4, 0)
countdownSub.Position         = UDim2.new(0, 4, 0.58, 0)
countdownSub.BackgroundTransparency = 1
countdownSub.Text             = "server-wide event"
countdownSub.TextColor3       = Color3.fromRGB(160, 140, 200)
countdownSub.TextScaled       = true
countdownSub.Font             = Enum.Font.Gotham
countdownSub.TextXAlignment   = Enum.TextXAlignment.Left
countdownSub.Parent           = tourneyCountdownFrame

-- "Buy early start" button (shown when countdown is long; uses Robux)
local earlyBtn = Instance.new("TextButton")
earlyBtn.Name             = "EarlyStartBtn"
earlyBtn.Size             = UDim2.new(0, 200, 0, 36)
earlyBtn.Position         = UDim2.new(1, -218, 1, -114)
earlyBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
earlyBtn.BorderSizePixel  = 0
earlyBtn.Text             = "⚡ Buy Early Start (R$)"
earlyBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
earlyBtn.TextScaled       = true
earlyBtn.Font             = Enum.Font.GothamBold
earlyBtn.Visible          = false   -- shown only when tourney isn't active
earlyBtn.Parent           = screenGui
Instance.new("UICorner", earlyBtn).CornerRadius = UDim.new(0, 8)
earlyBtn.Activated:Connect(function()
	Remotes.BuyTournament:FireServer()
end)

-- ============================================================
-- TOURNEY HUD (top-right, active during tournament)
-- ============================================================
local tourneyHUD = Instance.new("Frame")
tourneyHUD.Name             = "TourneyHUD"
tourneyHUD.Size             = UDim2.new(0, 210, 0, 130)
tourneyHUD.Position         = UDim2.new(1, -228, 0, 18)
tourneyHUD.BackgroundColor3 = Color3.fromRGB(12, 12, 45)
tourneyHUD.BackgroundTransparency = 0.15
tourneyHUD.BorderSizePixel  = 0
tourneyHUD.Visible          = false
tourneyHUD.Parent           = screenGui
Instance.new("UICorner", tourneyHUD).CornerRadius = UDim.new(0, 10)

local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerLabel"; timerLabel.Size = UDim2.new(1,-10,0,36); timerLabel.Position = UDim2.new(0,5,0,4)
timerLabel.BackgroundTransparency = 1; timerLabel.Text = "⏱ 5:00"
timerLabel.TextColor3 = Color3.fromRGB(255,220,60); timerLabel.TextScaled = true
timerLabel.Font = Enum.Font.GothamBold; timerLabel.Parent = tourneyHUD

local fishCountLabel = Instance.new("TextLabel")
fishCountLabel.Name = "FishCountLabel"; fishCountLabel.Size = UDim2.new(1,-10,0,28); fishCountLabel.Position = UDim2.new(0,5,0,40)
fishCountLabel.BackgroundTransparency = 1; fishCountLabel.Text = "🐟 0 fish caught"
fishCountLabel.TextColor3 = Color3.fromRGB(170,255,170); fishCountLabel.TextScaled = true
fishCountLabel.Font = Enum.Font.Gotham; fishCountLabel.Parent = tourneyHUD

local rankLabel = Instance.new("TextLabel")
rankLabel.Name = "RankLabel"; rankLabel.Size = UDim2.new(1,-10,0,28); rankLabel.Position = UDim2.new(0,5,0,68)
rankLabel.BackgroundTransparency = 1; rankLabel.Text = "Rank: —"
rankLabel.TextColor3 = Color3.fromRGB(255,245,180); rankLabel.TextScaled = true
rankLabel.Font = Enum.Font.Gotham; rankLabel.Parent = tourneyHUD

local starChanceLabel = Instance.new("TextLabel")
starChanceLabel.Name = "StarChanceLabel"; starChanceLabel.Size = UDim2.new(1,-10,0,24); starChanceLabel.Position = UDim2.new(0,5,0,97)
starChanceLabel.BackgroundTransparency = 1; starChanceLabel.Text = "⭐ 1/3 star chance!"
starChanceLabel.TextColor3 = Color3.fromRGB(200,160,255); starChanceLabel.TextScaled = true
starChanceLabel.Font = Enum.Font.Gotham; starChanceLabel.Parent = tourneyHUD

-- ============================================================
-- TOURNEY RESULT POPUP
-- ============================================================
local tourneyResult = Instance.new("Frame")
tourneyResult.Name             = "TourneyResult"
tourneyResult.Size             = UDim2.new(0, 400, 0, 420)
tourneyResult.Position         = UDim2.new(0.5, -200, 0.5, -210)
tourneyResult.BackgroundColor3 = Color3.fromRGB(10, 14, 42)
tourneyResult.BackgroundTransparency = 0.05
tourneyResult.BorderSizePixel  = 0
tourneyResult.Visible          = false
tourneyResult.Parent           = screenGui
Instance.new("UICorner", tourneyResult).CornerRadius = UDim.new(0, 16)

local trResultTitle = Instance.new("TextLabel")
trResultTitle.Size = UDim2.new(1,-20,0,46); trResultTitle.Position = UDim2.new(0,10,0,8)
trResultTitle.BackgroundTransparency=1; trResultTitle.Text="⏰ TOURNAMENT OVER!"
trResultTitle.TextColor3=Color3.fromRGB(255,220,60); trResultTitle.TextScaled=true
trResultTitle.Font=Enum.Font.GothamBold; trResultTitle.Parent=tourneyResult

local trTrophyLabel = Instance.new("TextLabel")
trTrophyLabel.Name="TrophyLabel"; trTrophyLabel.Size=UDim2.new(1,-20,0,48); trTrophyLabel.Position=UDim2.new(0,10,0,56)
trTrophyLabel.BackgroundTransparency=1; trTrophyLabel.Text=""
trTrophyLabel.TextColor3=Color3.fromRGB(255,200,0); trTrophyLabel.TextScaled=true
trTrophyLabel.Font=Enum.Font.GothamBold; trTrophyLabel.Parent=tourneyResult

local trFishLabel = Instance.new("TextLabel")
trFishLabel.Name="FishLabel"; trFishLabel.Size=UDim2.new(1,-20,0,30); trFishLabel.Position=UDim2.new(0,10,0,106)
trFishLabel.BackgroundTransparency=1; trFishLabel.Text=""
trFishLabel.TextColor3=Color3.fromRGB(170,255,170); trFishLabel.TextScaled=true
trFishLabel.Font=Enum.Font.Gotham; trFishLabel.Parent=tourneyResult

-- Leaderboard (scrolling)
local lbScroll = Instance.new("ScrollingFrame")
lbScroll.Name="LeaderboardScroll"; lbScroll.Size=UDim2.new(1,-20,0,180); lbScroll.Position=UDim2.new(0,10,0,142)
lbScroll.BackgroundColor3=Color3.fromRGB(15,15,35); lbScroll.BackgroundTransparency=0.3
lbScroll.BorderSizePixel=0; lbScroll.CanvasSize=UDim2.new(0,0,0,0)
lbScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; lbScroll.ScrollBarThickness=4; lbScroll.Parent=tourneyResult
Instance.new("UICorner",lbScroll).CornerRadius=UDim.new(0,8)
local lbLayout=Instance.new("UIListLayout",lbScroll); lbLayout.Padding=UDim.new(0,2); lbLayout.SortOrder=Enum.SortOrder.LayoutOrder

local trCloseBtn = Instance.new("TextButton")
trCloseBtn.Size=UDim2.new(0.5,0,0,42); trCloseBtn.Position=UDim2.new(0.25,0,0,368)
trCloseBtn.BackgroundColor3=Color3.fromRGB(60,60,80); trCloseBtn.BorderSizePixel=0
trCloseBtn.Text="Close"; trCloseBtn.TextColor3=Color3.fromRGB(200,200,200)
trCloseBtn.TextScaled=true; trCloseBtn.Font=Enum.Font.GothamBold; trCloseBtn.Parent=tourneyResult
Instance.new("UICorner",trCloseBtn).CornerRadius=UDim.new(0,10)
trCloseBtn.Activated:Connect(function() tourneyResult.Visible=false end)

-- ============================================================
-- WEATHER / TIME-OF-DAY INDICATOR (top-centre, below status bar)
-- ============================================================
local Lighting = game:GetService("Lighting")

local weatherFrame = Instance.new("Frame")
weatherFrame.Name                   = "WeatherFrame"
weatherFrame.Size                   = UDim2.new(0, 300, 0, 44)
weatherFrame.Position               = UDim2.new(0.5, -150, 0, 8)
weatherFrame.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
weatherFrame.BackgroundTransparency = 0.45
weatherFrame.BorderSizePixel        = 0
weatherFrame.Parent                 = screenGui
Instance.new("UICorner", weatherFrame).CornerRadius = UDim.new(0, 10)

-- Phase label: "🌤️ Day" or "🌙 Night"
local weatherPhaseLabel = Instance.new("TextLabel")
weatherPhaseLabel.Name                   = "WeatherPhaseLabel"
weatherPhaseLabel.Size                   = UDim2.new(1, -8, 0.5, 0)
weatherPhaseLabel.Position               = UDim2.new(0, 4, 0, 2)
weatherPhaseLabel.BackgroundTransparency = 1
weatherPhaseLabel.TextColor3             = Color3.fromRGB(255, 240, 160)
weatherPhaseLabel.TextScaled             = true
weatherPhaseLabel.Font                   = Enum.Font.GothamBold
weatherPhaseLabel.Text                   = "🌤️ Day"
weatherPhaseLabel.Parent                 = weatherFrame

-- Countdown label: "Night in 8:34" or "🌧️ Rain ×2"
local weatherLabel = Instance.new("TextLabel")
weatherLabel.Name                   = "WeatherLabel"
weatherLabel.Size                   = UDim2.new(1, -8, 0.5, 0)
weatherLabel.Position               = UDim2.new(0, 4, 0.5, 0)
weatherLabel.BackgroundTransparency = 1
weatherLabel.TextColor3             = Color3.fromRGB(200, 200, 220)
weatherLabel.TextScaled             = true
weatherLabel.Font                   = Enum.Font.Gotham
weatherLabel.Text                   = "Night in —"
weatherLabel.Parent                 = weatherFrame

local isRainingClient = false

-- DAY_LENGTH and NIGHT_LENGTH in real seconds (must match DayNightCycle)
-- Full cycle = 20 min = 1200s for 24 clock hours → 1200/24 = 50s per clock hour
local SECONDS_PER_CLOCK_HOUR = (20 * 60) / 24   -- ≈ 50s

local function clockTimeToNextPhase()
	local t       = Lighting.ClockTime
	local isNight = (t >= 20 or t < 6)
	local nextBoundary = isNight and 6 or 20
	local hoursUntil
	if t < nextBoundary then
		hoursUntil = nextBoundary - t
	else
		-- wraps: e.g. t=22, next=6 → (6+24) - 22 = 8
		hoursUntil = (nextBoundary + 24) - t
	end
	local secsUntil = math.floor(hoursUntil * SECONDS_PER_CLOCK_HOUR)
	local m = math.floor(secsUntil / 60)
	local s = secsUntil % 60
	local phaseName = isNight and "Day" or "Night"
	return isNight, phaseName, string.format("%d:%02d", m, s)
end

local function updateWeatherLabel()
	local isNight, nextPhaseName, countdown = clockTimeToNextPhase()
	if isRainingClient then
		weatherPhaseLabel.Text       = (isNight and "🌙 Night" or "🌤️ Day") .. "  🌧️ Rain ×2"
		weatherPhaseLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
		weatherLabel.Text            = nextPhaseName .. " in " .. countdown
		weatherLabel.TextColor3      = Color3.fromRGB(140, 190, 240)
	else
		weatherPhaseLabel.Text       = isNight and "🌙 Night" or "🌤️ Day"
		weatherPhaseLabel.TextColor3 = isNight
			and Color3.fromRGB(180, 180, 255)
			or  Color3.fromRGB(255, 240, 160)
		weatherLabel.Text            = nextPhaseName .. " in " .. countdown
		weatherLabel.TextColor3      = Color3.fromRGB(180, 180, 195)
	end
end

-- Update every second so countdown ticks smoothly
task.spawn(function()
	while true do
		updateWeatherLabel()
		task.wait(1)
	end
end)

-- Rain toast (brief notification when rain starts)
local rainToast = Instance.new("Frame")
rainToast.Name                   = "RainToast"
rainToast.Size                   = UDim2.new(0, 300, 0, 52)
rainToast.Position               = UDim2.new(0.5, -150, 0, 120)
rainToast.BackgroundColor3       = Color3.fromRGB(30, 50, 90)
rainToast.BackgroundTransparency = 0.1
rainToast.BorderSizePixel        = 0
rainToast.Visible                = false
rainToast.ZIndex                 = 18
rainToast.Parent                 = screenGui
Instance.new("UICorner", rainToast).CornerRadius = UDim.new(0, 10)

local rainToastLbl = Instance.new("TextLabel")
rainToastLbl.Size               = UDim2.new(1, -12, 1, 0)
rainToastLbl.Position           = UDim2.new(0, 6, 0, 0)
rainToastLbl.BackgroundTransparency = 1
rainToastLbl.Text               = ""
rainToastLbl.TextColor3         = Color3.fromRGB(150, 210, 255)
rainToastLbl.TextScaled         = true
rainToastLbl.Font               = Enum.Font.GothamBold
rainToastLbl.ZIndex             = 19
rainToastLbl.Parent             = rainToast

Remotes.WeatherChange.OnClientEvent:Connect(function(raining)
	isRainingClient = raining
	updateWeatherLabel()
	if raining then
		rainToastLbl.Text    = "🌧️ Rain started!  Fishing speed ×2"
		rainToast.Visible    = true
		task.delay(4, function() rainToast.Visible = false end)
	end
end)

-- ============================================================
-- CURRENCY UPDATES (from server)
-- ============================================================
Remotes.CoinsUpdate.OnClientEvent:Connect(function(coins)
	trackedCoins        = coins
	coinsLabel.Text     = "🪙 " .. coins
	shopCoinsLabel.Text = "🪙 " .. coins .. "  ⭐ " .. trackedStars
end)

Remotes.StarsUpdate.OnClientEvent:Connect(function(stars)
	trackedStars        = stars
	starsLabel.Text     = "⭐ " .. stars
	shopCoinsLabel.Text = "🪙 " .. trackedCoins .. "  ⭐ " .. stars
end)

-- ============================================================
-- TOURNAMENT EVENTS (server-wide)
-- ============================================================
local tourneyActiveTimer = 0

Remotes.TournamentCountdown.OnClientEvent:Connect(function(secondsLeft, isActive)
	if isActive then
		-- Show active HUD, hide early-buy button
		earlyBtn.Visible = false
		local m = math.floor(secondsLeft / 60)
		local s = secondsLeft % 60
		countdownLabel.Text      = string.format("🏆 ACTIVE — %d:%02d left", m, s)
		countdownLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		countdownSub.Text        = "⭐ 1/3 star chance!"
		tourneyHUD.Visible       = true
		-- Update active HUD timer
		timerLabel.Text      = string.format("⏱ %d:%02d", m, s)
		timerLabel.TextColor3 = secondsLeft <= 30 and Color3.fromRGB(255,80,80) or Color3.fromRGB(255,220,60)
	else
		tourneyHUD.Visible   = false
		earlyBtn.Visible     = secondsLeft > 60  -- only show buy button if >1 min until start
		local m = math.floor(secondsLeft / 60)
		local s = secondsLeft % 60
		countdownLabel.Text      = string.format("🏆 Next tourney: %d:%02d", m, s)
		countdownLabel.TextColor3 = Color3.fromRGB(255, 220, 60)
		countdownSub.Text        = "server-wide event • 1/5 star chance"
	end
end)

Remotes.TournamentStart.OnClientEvent:Connect(function(_duration)
	fishCountLabel.Text  = "🐟 0 fish caught"
	rankLabel.Text       = "Rank: —"
	tourneyHUD.Visible   = true
end)

Remotes.TournamentPoints.OnClientEvent:Connect(function(myFish, leaderboardData)
	fishCountLabel.Text = "🐟 " .. myFish .. " fish caught"
	-- Find local player's rank
	if type(leaderboardData) == "table" then
		local localName = game:GetService("Players").LocalPlayer.Name
		for i, entry in ipairs(leaderboardData) do
			if entry.name == localName then
				local medal = i == 1 and "🥇" or (i <= 3 and "🥈" or "🥉")
				rankLabel.Text = medal .. " Rank #" .. i .. " / " .. #leaderboardData
				break
			end
		end
	end
end)

Remotes.TournamentEnd.OnClientEvent:Connect(function(data)
	tourneyHUD.Visible = false
	-- Trophy banner
	local trophyStr = data.trophy or "none"
	local bannerText
	if     trophyStr == "Gold"   then bannerText = "🥇 You placed GOLD!"
	elseif trophyStr == "Silver" then bannerText = "🥈 You placed SILVER!"
	elseif trophyStr == "Bronze" then bannerText = "🥉 You placed BRONZE!"
	else                              bannerText = "Better luck next time!"
	end
	trTrophyLabel.Text = bannerText
	trFishLabel.Text   = "You caught " .. (data.fishCaught or 0) .. " fish"
		.. (data.rank and data.rank > 0 and (" • Rank #" .. data.rank) or "")

	-- Rebuild leaderboard rows
	for _, c in ipairs(lbScroll:GetChildren()) do
		if c:IsA("TextLabel") then c:Destroy() end
	end
	if type(data.leaderboard) == "table" then
		for i, entry in ipairs(data.leaderboard) do
			local medal = i == 1 and "🥇" or (i <= 3 and "🥈" or (entry.count >= 1 and "🥉" or "  "))
			local row = Instance.new("TextLabel")
			row.Size = UDim2.new(1,-8,0,26); row.BackgroundTransparency=1
			row.Text = string.format("%s #%d  %s — %d fish", medal, i, entry.name, entry.count)
			row.TextColor3 = i==1 and Color3.fromRGB(255,220,60)
				or (i<=3 and Color3.fromRGB(200,200,255) or Color3.fromRGB(180,180,180))
			row.TextScaled=true; row.Font=Enum.Font.Gotham
			row.TextXAlignment=Enum.TextXAlignment.Left
			row.LayoutOrder=i; row.Parent=lbScroll
		end
	end
	tourneyResult.Visible = true
end)

-- ============================================================
-- CAUGHT FISH TRACKING (for compendium reveal)
-- ============================================================
-- Load existing caught fish from server on join
task.spawn(function()
	local ok, result = pcall(function() return Remotes.GetCaughtFish:InvokeServer() end)
	if ok and type(result) == "table" then
		for name, _ in pairs(result) do
			caughtFishSet[name] = true
		end
	end
end)

-- FishingClient handles the minigame UI; we also listen here to update caughtFishSet
Remotes.FishCaught.OnClientEvent:Connect(function(info)
	if info and info.name then
		caughtFishSet[info.name] = true
	end
end)

-- ============================================================
-- JOURNAL BUTTON (bottom-left, next to shop)
-- ============================================================
local journalButton = Instance.new("TextButton")
journalButton.Name             = "JournalButton"
journalButton.Size             = UDim2.new(0, 130, 0, 46)
journalButton.Position         = UDim2.new(0, 158, 1, -68)
journalButton.BackgroundColor3 = Color3.fromRGB(60, 40, 100)
journalButton.BorderSizePixel  = 0
journalButton.Text             = "Journal"
journalButton.TextColor3       = Color3.fromRGB(255, 255, 255)
journalButton.TextScaled       = true
journalButton.Font             = Enum.Font.GothamBold
journalButton.Parent           = screenGui
Instance.new("UICorner", journalButton).CornerRadius = UDim.new(0, 10)

-- ============================================================
-- JOURNAL PANEL
-- ============================================================
journalPanel = Instance.new("Frame")
journalPanel.Name                   = "JournalPanel"
journalPanel.Size                   = UDim2.new(0, 460, 0, 530)
journalPanel.Position               = UDim2.new(0, 18, 1, -612)
journalPanel.BackgroundColor3       = Color3.fromRGB(14, 10, 28)
journalPanel.BackgroundTransparency = 0.05
journalPanel.BorderSizePixel        = 0
journalPanel.Visible                = false
journalPanel.Parent                 = screenGui
Instance.new("UICorner", journalPanel).CornerRadius = UDim.new(0, 14)

local journalTitle = Instance.new("TextLabel")
journalTitle.Size               = UDim2.new(1, -50, 0, 46)
journalTitle.Position           = UDim2.new(0, 0, 0, 0)
journalTitle.BackgroundTransparency = 1
journalTitle.Text               = "📓 Quest Journal"
journalTitle.TextColor3         = Color3.fromRGB(200, 170, 255)
journalTitle.TextScaled         = true
journalTitle.Font               = Enum.Font.GothamBold
journalTitle.Parent             = journalPanel

local journalCloseBtn = Instance.new("TextButton")
journalCloseBtn.Size             = UDim2.new(0, 36, 0, 36)
journalCloseBtn.Position         = UDim2.new(1, -44, 0, 5)
journalCloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
journalCloseBtn.BorderSizePixel  = 0
journalCloseBtn.Text             = "✕"
journalCloseBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
journalCloseBtn.TextScaled       = true
journalCloseBtn.Font             = Enum.Font.GothamBold
journalCloseBtn.Parent           = journalPanel
Instance.new("UICorner", journalCloseBtn).CornerRadius = UDim.new(0, 8)
journalCloseBtn.Activated:Connect(function() journalPanel.Visible = false end)

-- ── Tab buttons (3 tabs: Achievements | Fish | Guide) ─────────
local TAB_W = UDim2.new(0.333, -6, 0, 36)
local tabAchBtn = Instance.new("TextButton")
tabAchBtn.Name             = "TabAch"
tabAchBtn.Size             = TAB_W
tabAchBtn.Position         = UDim2.new(0,       4, 0, 48)
tabAchBtn.BackgroundColor3 = Color3.fromRGB(80, 50, 140)
tabAchBtn.BorderSizePixel  = 0
tabAchBtn.Text             = "🏆 Ach"
tabAchBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
tabAchBtn.TextScaled       = true
tabAchBtn.Font             = Enum.Font.GothamBold
tabAchBtn.Parent           = journalPanel
Instance.new("UICorner", tabAchBtn).CornerRadius = UDim.new(0, 8)

local tabFishBtn = Instance.new("TextButton")
tabFishBtn.Name             = "TabFish"
tabFishBtn.Size             = TAB_W
tabFishBtn.Position         = UDim2.new(0.333,  1, 0, 48)
tabFishBtn.BackgroundColor3 = Color3.fromRGB(40, 30, 60)
tabFishBtn.BorderSizePixel  = 0
tabFishBtn.Text             = "🐟 Fish"
tabFishBtn.TextColor3       = Color3.fromRGB(200, 200, 200)
tabFishBtn.TextScaled       = true
tabFishBtn.Font             = Enum.Font.Gotham
tabFishBtn.Parent           = journalPanel
Instance.new("UICorner", tabFishBtn).CornerRadius = UDim.new(0, 8)

local tabGuideBtn = Instance.new("TextButton")
tabGuideBtn.Name             = "TabGuide"
tabGuideBtn.Size             = TAB_W
tabGuideBtn.Position         = UDim2.new(0.666, -2, 0, 48)
tabGuideBtn.BackgroundColor3 = Color3.fromRGB(40, 30, 60)
tabGuideBtn.BorderSizePixel  = 0
tabGuideBtn.Text             = "📖 Guide"
tabGuideBtn.TextColor3       = Color3.fromRGB(200, 200, 200)
tabGuideBtn.TextScaled       = true
tabGuideBtn.Font             = Enum.Font.Gotham
tabGuideBtn.Parent           = journalPanel
Instance.new("UICorner", tabGuideBtn).CornerRadius = UDim.new(0, 8)

-- ── Achievements tab (scrolling) ──────────────────────────────
local achFrame = Instance.new("ScrollingFrame")
achFrame.Name                = "AchFrame"
achFrame.Size                = UDim2.new(1, -16, 1, -92)
achFrame.Position            = UDim2.new(0, 8, 0, 90)
achFrame.BackgroundTransparency = 1
achFrame.BorderSizePixel     = 0
achFrame.CanvasSize          = UDim2.new(0, 0, 0, 0)
achFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
achFrame.ScrollBarThickness  = 6
achFrame.Visible             = true
achFrame.Parent              = journalPanel

Instance.new("UIListLayout", achFrame).Padding   = UDim.new(0, 6)

-- ── Guide tab (scrolling) ─────────────────────────────────────
local guideFrame = Instance.new("ScrollingFrame")
guideFrame.Name                = "GuideFrame"
guideFrame.Size                = UDim2.new(1, -16, 1, -92)
guideFrame.Position            = UDim2.new(0, 8, 0, 90)
guideFrame.BackgroundTransparency = 1
guideFrame.BorderSizePixel     = 0
guideFrame.CanvasSize          = UDim2.new(0, 0, 0, 0)
guideFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
guideFrame.ScrollBarThickness  = 6
guideFrame.Visible             = false
guideFrame.Parent              = journalPanel

local guideLayout = Instance.new("UIListLayout")
guideLayout.Padding   = UDim.new(0, 6)
guideLayout.SortOrder = Enum.SortOrder.LayoutOrder
guideLayout.Parent    = guideFrame

local GUIDE_SECTIONS = {
	{ title = "🎣  How to Fish",
	  body  = "Walk up to any water and press [E] to cast your line. Wait for the bobber to bite, then the minigame starts automatically!" },
	{ title = "🎮  Minigame Controls",
	  body  = "Hold [LEFT CLICK] to lift the catch bar up. Release to let it fall. Keep the fish icon (🐟) inside the green bar. Fill the progress meter on the right to win!" },
	{ title = "🌤️🌙  Day & Night",
	  body  = "Some fish only come out during the day, others at night! Watch the time indicator at the top of the screen. Night fish include Catfish, Moonfish, and Void Eel." },
	{ title = "🌧️  Rainy Weather",
	  body  = "When it rains every ~30 minutes, fishing speed doubles for 5 minutes! Look for the 🌧️ Rain × 2 Speed indicator. Great time to grind rare fish!" },
	{ title = "🪱🪝🎣  Upgrades",
	  body  = "Open the Shop NPC or Shop panel. Bait = better rarity luck + spawn affinity. Hook = slower fish in minigame. Rod = bigger green catch bar." },
	{ title = "🏆  Tournament",
	  body  = "Press TOURNEY to start a 3-minute fishing sprint! Catch 3+ fish for a +2 bonus. Earn trophies: 🥉 5 pts, 🥈 15 pts, 🥇 30 pts." },
	{ title = "🪙  Coins & Rewards",
	  body  = "Every fish earns coins — Common: ~5, Uncommon: ~15, Rare: ~50, Legendary: ~150. Very big or very small catches sell for bonus coins!" },
	{ title = "🐟  Fish Compendium",
	  body  = "Check the Fish tab to see every fish in the game. Names are hidden until you catch them. Legendary fish also reveal how to find them once caught!" },
}

for i, sec in ipairs(GUIDE_SECTIONS) do
	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size               = UDim2.new(1, -8, 0, 28)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text               = sec.title
	titleLbl.TextColor3         = Color3.fromRGB(200, 170, 255)
	titleLbl.TextScaled         = true
	titleLbl.Font               = Enum.Font.GothamBold
	titleLbl.TextXAlignment     = Enum.TextXAlignment.Left
	titleLbl.LayoutOrder        = i * 2 - 1
	titleLbl.Parent             = guideFrame

	local bodyLbl = Instance.new("TextLabel")
	bodyLbl.Size                = UDim2.new(1, -8, 0, 56)
	bodyLbl.BackgroundColor3    = Color3.fromRGB(30, 20, 50)
	bodyLbl.BackgroundTransparency = 0.35
	bodyLbl.Text                = sec.body
	bodyLbl.TextColor3          = Color3.fromRGB(210, 210, 220)
	bodyLbl.TextWrapped         = true
	bodyLbl.TextScaled          = false
	bodyLbl.TextSize            = 13
	bodyLbl.Font                = Enum.Font.Gotham
	bodyLbl.TextXAlignment      = Enum.TextXAlignment.Left
	bodyLbl.TextYAlignment      = Enum.TextYAlignment.Top
	bodyLbl.LayoutOrder         = i * 2
	bodyLbl.Parent              = guideFrame
	Instance.new("UICorner", bodyLbl).CornerRadius = UDim.new(0, 6)
	local pad = Instance.new("UIPadding", bodyLbl)
	pad.PaddingLeft   = UDim.new(0, 6)
	pad.PaddingTop    = UDim.new(0, 4)
	pad.PaddingRight  = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 4)
end

local refreshAchievements  -- forward declared; defined below setTab

-- ── Fish Compendium ScrollingFrame ───────────────────────────
local fishFrame = Instance.new("ScrollingFrame")
fishFrame.Name                = "FishFrame"
fishFrame.Size                = UDim2.new(1, -16, 1, -92)
fishFrame.Position            = UDim2.new(0, 8, 0, 90)
fishFrame.BackgroundTransparency = 1
fishFrame.BorderSizePixel     = 0
fishFrame.CanvasSize          = UDim2.new(0, 0, 0, 0)
fishFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
fishFrame.ScrollBarThickness  = 6
fishFrame.Visible             = false
fishFrame.Parent              = journalPanel

Instance.new("UIListLayout", fishFrame).Padding = UDim.new(0, 5)

local RARITY_ORDER = { Common=1, Uncommon=2, Rare=3, Legendary=4 }
local RARITY_COLORS_COMP = {
	Common    = Color3.fromRGB(180,180,180),
	Uncommon  = Color3.fromRGB(80, 210, 80),
	Rare      = Color3.fromRGB(80, 140, 255),
	Legendary = Color3.fromRGB(255, 180, 0),
}
local SPAWN_ICONS = { day="🌤️ Day", night="🌙 Night", both="🌤️/🌙 Both" }

local function refreshCompendium()
	for _, c in ipairs(fishFrame:GetChildren()) do
		if not c:IsA("UIListLayout") then c:Destroy() end
	end

	-- Sort fish: by rarity then alphabetically
	local sortedFish = {}
	for _, fish in ipairs(FishData.Fish) do table.insert(sortedFish, fish) end
	table.sort(sortedFish, function(a, b)
		local ra, rb = RARITY_ORDER[a.rarity] or 0, RARITY_ORDER[b.rarity] or 0
		if ra ~= rb then return ra < rb end
		return a.name < b.name
	end)

	for order, fish in ipairs(sortedFish) do
		local caught    = caughtFishSet[fish.name] == true
		local isLegend  = fish.rarity == "Legendary"
		local rarColor  = RARITY_COLORS_COMP[fish.rarity] or Color3.fromRGB(200,200,200)

		-- Card height: taller for legendary (hint row visible after catch)
		local cardH = (isLegend and caught) and 82 or 62

		local card = Instance.new("Frame")
		card.Name                = "FishCard_" .. order
		card.Size                = UDim2.new(1, -4, 0, cardH)
		card.BackgroundColor3    = caught
			and Color3.fromRGB(15, 38, 15)
			or  Color3.fromRGB(20, 15, 35)
		card.BackgroundTransparency = 0.2
		card.BorderSizePixel     = 0
		card.LayoutOrder         = order
		card.Parent              = fishFrame
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

		-- Rarity strip (left edge)
		local strip = Instance.new("Frame")
		strip.Size             = UDim2.new(0, 4, 1, 0)
		strip.BackgroundColor3 = rarColor
		strip.BorderSizePixel  = 0
		strip.Parent           = card
		Instance.new("UICorner", strip).CornerRadius = UDim.new(0, 4)

		-- Caught checkmark
		local checkLbl = Instance.new("TextLabel")
		checkLbl.Size               = UDim2.new(0, 24, 0, 24)
		checkLbl.Position           = UDim2.new(1, -28, 0, 4)
		checkLbl.BackgroundTransparency = 1
		checkLbl.Text               = caught and "✅" or ""
		checkLbl.TextScaled         = true
		checkLbl.Font               = Enum.Font.Gotham
		checkLbl.Parent             = card

		-- Fish name (hidden for legendary until caught)
		local showName = caught or not isLegend
		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size               = UDim2.new(0.55, 0, 0, 22)
		nameLbl.Position           = UDim2.new(0, 10, 0, 4)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Text               = showName and fish.name or "???"
		nameLbl.TextColor3         = showName and rarColor or Color3.fromRGB(120,120,120)
		nameLbl.TextScaled         = true
		nameLbl.Font               = Enum.Font.GothamBold
		nameLbl.TextXAlignment     = Enum.TextXAlignment.Left
		nameLbl.Parent             = card

		-- Rarity badge
		local rarLbl = Instance.new("TextLabel")
		rarLbl.Size               = UDim2.new(0.42, 0, 0, 20)
		rarLbl.Position           = UDim2.new(0.55, 0, 0, 6)
		rarLbl.BackgroundTransparency = 1
		rarLbl.Text               = (caught or not isLegend) and fish.rarity or "???"
		rarLbl.TextColor3         = (caught or not isLegend) and rarColor or Color3.fromRGB(100,100,100)
		rarLbl.TextScaled         = true
		rarLbl.Font               = Enum.Font.Gotham
		rarLbl.TextXAlignment     = Enum.TextXAlignment.Right
		rarLbl.Parent             = card

		-- Info row: size range + spawn time (hidden for uncaught legendaries)
		local showInfo = caught or not isLegend
		local spawnIcon = SPAWN_ICONS[fish.spawnTime or "both"] or "🌤️/🌙 Both"
		local infoLbl = Instance.new("TextLabel")
		infoLbl.Size               = UDim2.new(1, -10, 0, 18)
		infoLbl.Position           = UDim2.new(0, 10, 0, 28)
		infoLbl.BackgroundTransparency = 1
		infoLbl.Text               = showInfo
			and (spawnIcon .. "  •  " .. fish.minSize .. "–" .. fish.maxSize .. " cm  •  " .. fish.baseValue .. "🪙 base")
			or  "???"
		infoLbl.TextColor3         = Color3.fromRGB(150, 150, 160)
		infoLbl.TextScaled         = true
		infoLbl.Font               = Enum.Font.Gotham
		infoLbl.TextXAlignment     = Enum.TextXAlignment.Left
		infoLbl.Parent             = card

		-- Hint row (legendary only, shown after catching)
		if isLegend and caught and fish.hint then
			local hintLbl = Instance.new("TextLabel")
			hintLbl.Size               = UDim2.new(1, -10, 0, 30)
			hintLbl.Position           = UDim2.new(0, 10, 0, 48)
			hintLbl.BackgroundTransparency = 1
			hintLbl.Text               = "🔍 " .. fish.hint
			hintLbl.TextColor3         = Color3.fromRGB(255, 200, 80)
			hintLbl.TextScaled         = false
			hintLbl.TextSize           = 11
			hintLbl.TextWrapped        = true
			hintLbl.Font               = Enum.Font.Gotham
			hintLbl.TextXAlignment     = Enum.TextXAlignment.Left
			hintLbl.TextYAlignment     = Enum.TextYAlignment.Top
			hintLbl.Parent             = card
		elseif isLegend and not caught then
			-- Show "???" hint line before catching
			local hintLbl = Instance.new("TextLabel")
			hintLbl.Size               = UDim2.new(1, -10, 0, 18)
			hintLbl.Position           = UDim2.new(0, 10, 0, 44)
			hintLbl.BackgroundTransparency = 1
			hintLbl.Text               = "🔍 ???"
			hintLbl.TextColor3         = Color3.fromRGB(90,90,90)
			hintLbl.TextScaled         = true
			hintLbl.Font               = Enum.Font.Gotham
			hintLbl.TextXAlignment     = Enum.TextXAlignment.Left
			hintLbl.Parent             = card
		end
	end
end

-- ── Tab switching (3 tabs) ────────────────────────────────────
local activeJournalTab = "ach"

local function setTab(tabName)
	activeJournalTab      = tabName
	achFrame.Visible      = (tabName == "ach")
	fishFrame.Visible     = (tabName == "fish")
	guideFrame.Visible    = (tabName == "guide")

	local ACTIVE_COLOR   = Color3.fromRGB(80, 50, 140)
	local INACTIVE_COLOR = Color3.fromRGB(40, 30, 60)
	local ACTIVE_TEXT    = Color3.fromRGB(255, 255, 255)
	local INACTIVE_TEXT  = Color3.fromRGB(200, 200, 200)

	tabAchBtn.BackgroundColor3   = tabName == "ach"   and ACTIVE_COLOR or INACTIVE_COLOR
	tabAchBtn.TextColor3         = tabName == "ach"   and ACTIVE_TEXT  or INACTIVE_TEXT
	tabAchBtn.Font               = tabName == "ach"   and Enum.Font.GothamBold or Enum.Font.Gotham
	tabFishBtn.BackgroundColor3  = tabName == "fish"  and ACTIVE_COLOR or INACTIVE_COLOR
	tabFishBtn.TextColor3        = tabName == "fish"  and ACTIVE_TEXT  or INACTIVE_TEXT
	tabFishBtn.Font              = tabName == "fish"  and Enum.Font.GothamBold or Enum.Font.Gotham
	tabGuideBtn.BackgroundColor3 = tabName == "guide" and ACTIVE_COLOR or INACTIVE_COLOR
	tabGuideBtn.TextColor3       = tabName == "guide" and ACTIVE_TEXT  or INACTIVE_TEXT
	tabGuideBtn.Font             = tabName == "guide" and Enum.Font.GothamBold or Enum.Font.Gotham

	if tabName == "fish"  then refreshCompendium()    end
	if tabName == "ach"   then refreshAchievements()  end
end

tabAchBtn.Activated:Connect(function()   setTab("ach")   end)
tabFishBtn.Activated:Connect(function()  setTab("fish")  end)
tabGuideBtn.Activated:Connect(function() setTab("guide") end)

-- ── Rebuild achievement cards ─────────────────────────────────
refreshAchievements = function()
	for _, c in ipairs(achFrame:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end

	local stats, completed = Remotes.GetAchievements:InvokeServer()
	stats     = stats     or {}
	completed = completed or {}

	local doneCount = 0
	for _, ach in ipairs(AchievementData) do
		if completed[ach.id] then doneCount += 1 end
	end

	-- Summary row at top
	local summaryLbl = Instance.new("TextLabel")
	summaryLbl.Size               = UDim2.new(1, -4, 0, 28)
	summaryLbl.BackgroundTransparency = 1
	summaryLbl.Text               = ("✅ %d / %d achievements unlocked"):format(doneCount, #AchievementData)
	summaryLbl.TextColor3         = Color3.fromRGB(180, 255, 180)
	summaryLbl.TextScaled         = true
	summaryLbl.Font               = Enum.Font.Gotham
	summaryLbl.LayoutOrder        = 0
	summaryLbl.Parent             = achFrame

	for i, ach in ipairs(AchievementData) do
		local isDone   = completed[ach.id] == true
		local progress = math.min(stats[ach.statKey] or 0, ach.goal)
		local pct      = progress / ach.goal

		local card = Instance.new("Frame")
		card.Name             = "Ach_" .. ach.id
		card.Size             = UDim2.new(1, -4, 0, 72)
		card.BackgroundColor3 = isDone
			and Color3.fromRGB(15, 45, 15)
			or  Color3.fromRGB(24, 14, 44)
		card.BackgroundTransparency = 0.2
		card.BorderSizePixel  = 0
		card.LayoutOrder      = isDone and (1000 + i) or i
		card.Parent           = achFrame
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

		-- Icon
		local iconLbl = Instance.new("TextLabel")
		iconLbl.Size               = UDim2.new(0, 46, 0, 46)
		iconLbl.Position           = UDim2.new(0, 4, 0.5, -23)
		iconLbl.BackgroundTransparency = 1
		iconLbl.Text               = ach.icon
		iconLbl.TextScaled         = true
		iconLbl.Font               = Enum.Font.Gotham
		iconLbl.Parent             = card

		-- Name
		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size               = UDim2.new(1, -110, 0, 22)
		nameLbl.Position           = UDim2.new(0, 54, 0, 7)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Text               = (isDone and "✅ " or "") .. ach.name
		nameLbl.TextColor3         = isDone
			and Color3.fromRGB(100, 255, 100)
			or  Color3.fromRGB(255, 255, 255)
		nameLbl.TextScaled         = true
		nameLbl.Font               = Enum.Font.GothamBold
		nameLbl.TextXAlignment     = Enum.TextXAlignment.Left
		nameLbl.Parent             = card

		-- Desc
		local descLbl = Instance.new("TextLabel")
		descLbl.Size               = UDim2.new(1, -110, 0, 18)
		descLbl.Position           = UDim2.new(0, 54, 0, 29)
		descLbl.BackgroundTransparency = 1
		descLbl.Text               = ach.desc
		descLbl.TextColor3         = Color3.fromRGB(160, 160, 175)
		descLbl.TextScaled         = true
		descLbl.Font               = Enum.Font.Gotham
		descLbl.TextXAlignment     = Enum.TextXAlignment.Left
		descLbl.Parent             = card

		-- Progress bar bg
		local pbarBg = Instance.new("Frame")
		pbarBg.Size               = UDim2.new(1, -60, 0, 10)
		pbarBg.Position           = UDim2.new(0, 54, 0, 52)
		pbarBg.BackgroundColor3   = Color3.fromRGB(45, 45, 58)
		pbarBg.BorderSizePixel    = 0
		pbarBg.Parent             = card
		Instance.new("UICorner", pbarBg).CornerRadius = UDim.new(0, 4)

		local pbarFill = Instance.new("Frame")
		pbarFill.Size             = UDim2.new(pct, 0, 1, 0)
		pbarFill.BackgroundColor3 = isDone
			and Color3.fromRGB(60, 210, 80)
			or  Color3.fromRGB(100, 140, 255)
		pbarFill.BorderSizePixel  = 0
		pbarFill.Parent           = pbarBg
		Instance.new("UICorner", pbarFill).CornerRadius = UDim.new(0, 4)

		-- Progress text (top-right of card)
		local pctLbl = Instance.new("TextLabel")
		pctLbl.Size               = UDim2.new(0, 52, 0, 20)
		pctLbl.Position           = UDim2.new(1, -54, 0, 7)
		pctLbl.BackgroundTransparency = 1
		pctLbl.Text               = isDone and "DONE" or (progress .. "/" .. ach.goal)
		pctLbl.TextColor3         = isDone
			and Color3.fromRGB(100, 255, 100)
			or  Color3.fromRGB(180, 180, 200)
		pctLbl.TextScaled         = true
		pctLbl.Font               = Enum.Font.Gotham
		pctLbl.TextXAlignment     = Enum.TextXAlignment.Right
		pctLbl.Parent             = card
	end
end

-- Open / close journal
journalButton.Activated:Connect(function()
	invPanel.Visible     = false
	shopPanel.Visible    = false
	journalPanel.Visible = not journalPanel.Visible
	if journalPanel.Visible then
		-- Restore last active tab (defaults to ach on first open)
		if activeJournalTab == "fish" then
			refreshCompendium()
		elseif activeJournalTab == "guide" then
			-- static content; no refresh needed
		else
			refreshAchievements()
		end
	end
end)

-- ACHIEVEMENT UNLOCKED TOAST (slides in from top)
-- ============================================================
local achToast = Instance.new("Frame")
achToast.Name                   = "AchToast"
achToast.Size                   = UDim2.new(0, 330, 0, 72)
achToast.Position               = UDim2.new(0.5, -165, 0, -90)
achToast.BackgroundColor3       = Color3.fromRGB(18, 52, 18)
achToast.BackgroundTransparency = 0.08
achToast.BorderSizePixel        = 0
achToast.Visible                = false
achToast.ZIndex                 = 20
achToast.Parent                 = screenGui
Instance.new("UICorner", achToast).CornerRadius = UDim.new(0, 12)

-- Subtle green left-border strip
local toastStrip = Instance.new("Frame")
toastStrip.Size             = UDim2.new(0, 5, 1, 0)
toastStrip.BackgroundColor3 = Color3.fromRGB(60, 220, 80)
toastStrip.BorderSizePixel  = 0
toastStrip.ZIndex           = 21
toastStrip.Parent           = achToast
Instance.new("UICorner", toastStrip).CornerRadius = UDim.new(0, 4)

local toastHeader = Instance.new("TextLabel")
toastHeader.Size               = UDim2.new(1, -70, 0, 22)
toastHeader.Position           = UDim2.new(0, 60, 0, 8)
toastHeader.BackgroundTransparency = 1
toastHeader.Text               = "Achievement Unlocked!"
toastHeader.TextColor3         = Color3.fromRGB(100, 255, 100)
toastHeader.TextScaled         = true
toastHeader.Font               = Enum.Font.GothamBold
toastHeader.TextXAlignment     = Enum.TextXAlignment.Left
toastHeader.ZIndex             = 21
toastHeader.Parent             = achToast

local toastIconLbl = Instance.new("TextLabel")
toastIconLbl.Size               = UDim2.new(0, 50, 0, 50)
toastIconLbl.Position           = UDim2.new(0, 8, 0.5, -25)
toastIconLbl.BackgroundTransparency = 1
toastIconLbl.Text               = "🏅"
toastIconLbl.TextScaled         = true
toastIconLbl.Font               = Enum.Font.Gotham
toastIconLbl.ZIndex             = 21
toastIconLbl.Parent             = achToast

local toastNameLbl = Instance.new("TextLabel")
toastNameLbl.Name              = "AchName"
toastNameLbl.Size              = UDim2.new(1, -70, 0, 34)
toastNameLbl.Position          = UDim2.new(0, 60, 0, 30)
toastNameLbl.BackgroundTransparency = 1
toastNameLbl.Text              = ""
toastNameLbl.TextColor3        = Color3.fromRGB(230, 230, 240)
toastNameLbl.TextScaled        = true
toastNameLbl.Font              = Enum.Font.Gotham
toastNameLbl.TextXAlignment    = Enum.TextXAlignment.Left
toastNameLbl.ZIndex            = 21
toastNameLbl.Parent            = achToast

local toastShowing = false
local toastQueue   = {}

local function showNextToast()
	if toastShowing or #toastQueue == 0 then return end
	toastShowing = true
	local info = table.remove(toastQueue, 1)

	toastIconLbl.Text = info.icon or "🏅"
	toastNameLbl.Text = (info.name or "") .. "  —  " .. (info.desc or "")
	achToast.Position = UDim2.new(0.5, -165, 0, -90)
	achToast.Visible  = true

	local tweenIn = TweenService:Create(
		achToast,
		TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, -165, 0, 78) }
	)
	tweenIn:Play()

	task.delay(3.8, function()
		local tweenOut = TweenService:Create(
			achToast,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(0.5, -165, 0, -90) }
		)
		tweenOut:Play()
		tweenOut.Completed:Connect(function()
			achToast.Visible = false
			toastShowing     = false
			showNextToast()
		end)
	end)
end

Remotes.AchievementUnlocked.OnClientEvent:Connect(function(info)
	table.insert(toastQueue, info)
	showNextToast()
	-- If journal is open on ach tab, refresh it so the new achievement shows immediately
	if journalPanel.Visible and activeJournalTab == "ach" then refreshAchievements() end
end)

-- ============================================================
-- DEBUG GIVE COINS (Studio only — purple button top-right)
-- ============================================================
if RunService:IsStudio() then
	local debugBtn = Instance.new("TextButton")
	debugBtn.Name             = "DebugCoinsBtn"
	debugBtn.Size             = UDim2.new(0, 165, 0, 38)
	debugBtn.Position         = UDim2.new(1, -183, 0, 70)
	debugBtn.BackgroundColor3 = Color3.fromRGB(110, 0, 170)
	debugBtn.BorderSizePixel  = 0
	debugBtn.Text             = "🟣 DEBUG +1000🪙"
	debugBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
	debugBtn.TextScaled       = true
	debugBtn.Font             = Enum.Font.GothamBold
	debugBtn.Parent           = screenGui
	Instance.new("UICorner", debugBtn).CornerRadius = UDim.new(0, 8)

	debugBtn.Activated:Connect(function()
		Remotes.DebugGiveCoins:FireServer(1000)
		debugBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 40)
		task.delay(0.5, function() debugBtn.BackgroundColor3 = Color3.fromRGB(110, 0, 170) end)
	end)

	local debugStarsBtn = Instance.new("TextButton")
	debugStarsBtn.Name             = "DebugStarsBtn"
	debugStarsBtn.Size             = UDim2.new(0, 165, 0, 38)
	debugStarsBtn.Position         = UDim2.new(1, -183, 0, 114)
	debugStarsBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 140)
	debugStarsBtn.BorderSizePixel  = 0
	debugStarsBtn.Text             = "🟣 DEBUG +20⭐"
	debugStarsBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
	debugStarsBtn.TextScaled       = true
	debugStarsBtn.Font             = Enum.Font.GothamBold
	debugStarsBtn.Parent           = screenGui
	Instance.new("UICorner", debugStarsBtn).CornerRadius = UDim.new(0, 8)
	debugStarsBtn.Activated:Connect(function()
		Remotes.DebugGiveStars:FireServer(20)
		debugStarsBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 40)
		task.delay(0.5, function() debugStarsBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 140) end)
	end)

	local debugFishBtn = Instance.new("TextButton")
	debugFishBtn.Name             = "DebugFishBtn"
	debugFishBtn.Size             = UDim2.new(0, 165, 0, 38)
	debugFishBtn.Position         = UDim2.new(1, -183, 0, 158)
	debugFishBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 140)
	debugFishBtn.BorderSizePixel  = 0
	debugFishBtn.Text             = "🐟 DEBUG +5 FISH"
	debugFishBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
	debugFishBtn.TextScaled       = true
	debugFishBtn.Font             = Enum.Font.GothamBold
	debugFishBtn.Parent           = screenGui
	Instance.new("UICorner", debugFishBtn).CornerRadius = UDim.new(0, 8)
	debugFishBtn.Activated:Connect(function()
		Remotes.DebugGiveFish:FireServer()
		debugFishBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 40)
		task.delay(0.5, function() debugFishBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 140) end)
	end)

	-- Studio: force-start tournament for testing
	local debugTourneyBtn = Instance.new("TextButton")
	debugTourneyBtn.Name             = "DebugTourneyBtn"
	debugTourneyBtn.Size             = UDim2.new(0, 165, 0, 38)
	debugTourneyBtn.Position         = UDim2.new(1, -183, 0, 202)
	debugTourneyBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 0)
	debugTourneyBtn.BorderSizePixel  = 0
	debugTourneyBtn.Text             = "🏆 DEBUG TOURNEY"
	debugTourneyBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
	debugTourneyBtn.TextScaled       = true
	debugTourneyBtn.Font             = Enum.Font.GothamBold
	debugTourneyBtn.Parent           = screenGui
	Instance.new("UICorner", debugTourneyBtn).CornerRadius = UDim.new(0, 8)
	debugTourneyBtn.Activated:Connect(function()
		Remotes.BuyTournament:FireServer()
	end)
end

print("[FishingGui] UI built and ready!")
